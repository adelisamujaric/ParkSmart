using DetectionService.Application.DTOs.Requests;
using DetectionService.Application.DTOs.Responses;
using DetectionService.Domain.Entities;
using DetectionService.Domain.Enums;
using DetectionService.Domain.Interfaces;
using DetectionService.Infrastructure.Services;
using Microsoft.Extensions.Logging;
using Shared.Exceptions;

namespace DetectionService.Application.Services
{
    public class CameraAppService
    {
        private readonly ICameraRepository _repository;
        private readonly ParkingServiceClient _parkingServiceClient;
        private readonly ILogger<CameraAppService> _logger; 

        public CameraAppService(
            ICameraRepository repository,
            ParkingServiceClient parkingServiceClient,
            ILogger<CameraAppService> logger) 
        {
            _repository = repository;
            _parkingServiceClient = parkingServiceClient;
            _logger = logger; 
        }

        public async Task<List<CameraResponseDto>> GetAllAsync()
        {
            var cameras = await _repository.GetAllAsync();
            return cameras.Select(MapToResponse).ToList();
        }

        public async Task<CameraResponseDto?> GetByIdAsync(Guid id)
        {
            var camera = await _repository.GetByIdAsync(id);
            if (camera == null)
                throw new NotFoundException($"Camera with ID {id} not found."); 
            return MapToResponse(camera);
        }

        public async Task<CameraResponseDto> CreateAsync(CreateCameraDto dto)
        {
            try
            {
                if (dto.Number <= 0)
                    throw new BadRequestException("Camera number must be greater than 0.");

                var lotName = await _parkingServiceClient.GetLotNameAsync(dto.LotId);
                var camera = new Camera
                {
                    Id = Guid.NewGuid(),
                    Number = dto.Number,
                    LotId = dto.LotId,
                    LotName = lotName,
                    CameraType = dto.CameraType,
                    Status = CameraStatus.Active,
                    CreatedAt = DateTime.UtcNow
                };
                var created = await _repository.CreateAsync(camera);
                _logger.LogInformation("Camera {Number} created for lot {LotId}", dto.Number, dto.LotId);
                return MapToResponse(created);
            }
            catch (Exception ex) when (ex is not BadRequestException && ex is not NotFoundException)
            {
                _logger.LogError(ex, "Error creating camera for lot {LotId}", dto.LotId);
                throw;
            }
        }

        public async Task<CameraResponseDto> UpdateStatusAsync(Guid id, CameraStatus status)
        {
            try
            {
                var camera = await _repository.GetByIdAsync(id)
                    ?? throw new NotFoundException($"Camera with ID {id} not found."); 
                camera.Status = status;
                var updated = await _repository.UpdateAsync(camera);
                _logger.LogInformation("Camera {Id} status updated to {Status}", id, status);
                return MapToResponse(updated);
            }
            catch (Exception ex) when (ex is not NotFoundException)
            {
                _logger.LogError(ex, "Error updating status for camera {Id}", id);
                throw;
            }
        }

        public async Task DeleteAsync(Guid id)
        {
            try
            {
                var camera = await _repository.GetByIdAsync(id)
                    ?? throw new NotFoundException($"Camera with ID {id} not found.");
                await _repository.DeleteAsync(id);
                _logger.LogInformation("Camera {Id} deleted", id);
            }
            catch (Exception ex) when (ex is not NotFoundException)
            {
                _logger.LogError(ex, "Error deleting camera {Id}", id);
                throw;
            }
        }

        private CameraResponseDto MapToResponse(Camera camera) => new()
        {
            Id = camera.Id,
            Number = camera.Number,
            LotId = camera.LotId,
            LotName = camera.LotName,
            CameraType = camera.CameraType.ToString(),
            Status = camera.Status.ToString(),
            CreatedAt = camera.CreatedAt
        };
    }
}