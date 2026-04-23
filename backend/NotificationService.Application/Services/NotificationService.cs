using NotificationService.Application.DTOs.Requests;
using NotificationService.Application.DTOs.Responses;
using NotificationService.Domain.Entities;
using NotificationService.Domain.Enums;
using NotificationService.Domain.Interfaces;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace NotificationService.Application.Services
{
    public class NotificationAppService
    {
        private readonly INotificationRepository _notificationRepository;


        public NotificationAppService(INotificationRepository notificationRepository)
        {
            _notificationRepository = notificationRepository;
        }
        //---------------------------------------------------------------------------------------

        public async Task<IEnumerable<NotificationDto>> GetAllAsync()
        {
            var notifications = await _notificationRepository.GetAllAsync();
            return notifications.Select(MapToDto);
        }
        //---------------------------------------------------------------------------------------

        public async Task<IEnumerable<NotificationDto>> GetByUserIdAsync(Guid userId)
        {
            var notifications = await _notificationRepository.GetByUserIdAsync(userId);
            return notifications.Select(MapToDto);
        }
        //---------------------------------------------------------------------------------------

        public async Task<NotificationDto> GetByIdAsync(Guid id)
        {
            var notification = await _notificationRepository.GetByIdAsync(id);
            return MapToDto(notification);
        }
        //---------------------------------------------------------------------------------------

        public async Task<NotificationDto> CreateAsync(CreateNotificationDto dto)
        {
            var notification = new Notification
            {
                UserId = dto.UserId,
                Title = dto.Title,
                Message = dto.Message,
                Type = dto.Type
            };

            var created = await _notificationRepository.CreateAsync(notification);
            return MapToDto(created);
        }
        //---------------------------------------------------------------------------------------

        public async Task MarkAsReadAsync(Guid id)
        {
            var notification = await _notificationRepository.GetByIdAsync(id);
            notification.Status = NotificationStatus.Read;
            notification.ReadAt = DateTime.UtcNow;
            await _notificationRepository.UpdateAsync(notification);
        }
        //---------------------------------------------------------------------------------------

        public async Task DeleteAsync(Guid id)
        {
            await _notificationRepository.DeleteAsync(id);
        }
        //---------------------------------------------------------------------------------------

        private NotificationDto MapToDto(Notification n) => new NotificationDto
        {
            Id = n.Id,
            UserId = n.UserId,
            Title = n.Title,
            Message = n.Message,
            Type = n.Type,
            Status = n.Status,
            CreatedAt = n.CreatedAt,
            SentAt = n.SentAt,
            ReadAt = n.ReadAt
        };
    }
}
