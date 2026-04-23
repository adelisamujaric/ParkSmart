using NotificationService.Domain.Entities;
using NotificationService.Domain.Enums;
using NotificationService.Domain.Interfaces;
using NotificationService.Infrastructure.Data;
using Microsoft.EntityFrameworkCore;

public class NotificationRepository : INotificationRepository
{
    private readonly NotificationDbContext _context;

    public NotificationRepository(NotificationDbContext context)
    {
        _context = context;
    }
    //---------------------------------------------------------------------------------------

    public async Task<Notification> GetByIdAsync(Guid id)
    {
        return await _context.Notifications.FindAsync(id)
            ?? throw new KeyNotFoundException($"Notification with ID {id} not found.");
    }
    //---------------------------------------------------------------------------------------

    public async Task<IEnumerable<Notification>> GetByUserIdAsync(Guid userId)
    {
        return await _context.Notifications
            .Where(n => n.UserId == userId)
            .OrderByDescending(n => n.CreatedAt)
            .ToListAsync();
    }
    //---------------------------------------------------------------------------------------

    public async Task<IEnumerable<Notification>> GetAllAsync()
    {
        return await _context.Notifications
            .OrderByDescending(n => n.CreatedAt)
            .ToListAsync();
    }
    //---------------------------------------------------------------------------------------

    public async Task<Notification> CreateAsync(Notification notification)
    {
        notification.Id = Guid.NewGuid();
        notification.CreatedAt = DateTime.UtcNow;
        notification.Status = NotificationStatus.Pending;
        _context.Notifications.Add(notification);
        await _context.SaveChangesAsync();
        return notification;
    }
    //---------------------------------------------------------------------------------------

    public async Task<Notification> UpdateAsync(Notification notification)
    {
        _context.Notifications.Update(notification);
        await _context.SaveChangesAsync();
        return notification;
    }
    //---------------------------------------------------------------------------------------

    public async Task DeleteAsync(Guid id)
    {
        var notification = await GetByIdAsync(id);
        _context.Notifications.Remove(notification);
        await _context.SaveChangesAsync();
    }
    //---------------------------------------------------------------------------------------

}