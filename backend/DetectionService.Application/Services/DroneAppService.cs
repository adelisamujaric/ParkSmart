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
    public class DroneAppService
    {
        private readonly IDroneRepository _repository;
        private readonly ParkingServiceClient _parkingServiceClient;
        private readonly ILogger<DroneAppService> _logger; 

        public DroneAppService(
            IDroneRepository repository,
            ParkingServiceClient parkingServiceClient,
            ILogger<DroneAppService> logger) 
        {
            _repository = repository;
            _parkingServiceClient = parkingServiceClient;
            _logger = logger; 
        }

        public async Task<List<DroneResponseDto>> GetAllAsync()
        {
            var drones = await _repository.GetAllAsync();
            return drones.Select(MapToResponse).ToList();
        }

        public async Task<DroneResponseDto?> GetByIdAsync(Guid id)
        {
            var drone = await _repository.GetByIdAsync(id)
                ?? throw new NotFoundException($"Drone with ID {id} not found."); 
            return MapToResponse(drone);
        }

        public async Task<DroneResponseDto> CreateAsync(CreateDroneDto dto)
        {
            try
            {
                if (dto.Number <= 0)
                    throw new BadRequestException("Drone number must be greater than 0.");

                if (dto.BatteryLevel < 0 || dto.BatteryLevel > 100)
                    throw new BadRequestException("Battery level must be between 0 and 100.");

                var lotName = await _parkingServiceClient.GetLotNameAsync(dto.LotId);
                var drone = new Drone
                {
                    Id = Guid.NewGuid(),
                    Number = dto.Number,
                    LotId = dto.LotId,
                    LotName = lotName,
                    Status = DroneStatus.Inactive,
                    BatteryLevel = dto.BatteryLevel,
                    TimeToCharge = dto.TimeToCharge,
                    CreatedAt = DateTime.UtcNow
                };
                var created = await _repository.CreateAsync(drone);
                _logger.LogInformation("Drone {Number} created for lot {LotId}", dto.Number, dto.LotId);
                return MapToResponse(created);
            }
            catch (Exception ex) when (ex is not BadRequestException && ex is not NotFoundException)
            {
                _logger.LogError(ex, "Error creating drone for lot {LotId}", dto.LotId);
                throw;
            }
        }

        public async Task<DroneResponseDto> UpdateStatusAsync(Guid id, DroneStatus status)
        {
            try
            {
                var drone = await _repository.GetByIdAsync(id)
                    ?? throw new NotFoundException($"Drone with ID {id} not found.");
                drone.Status = status;
                var updated = await _repository.UpdateAsync(drone);
                _logger.LogInformation("Drone {Id} status updated to {Status}", id, status);
                return MapToResponse(updated);
            }
            catch (Exception ex) when (ex is not NotFoundException)
            {
                _logger.LogError(ex, "Error updating status for drone {Id}", id);
                throw;
            }
        }

        public async Task DeleteAsync(Guid id)
        {
            try
            {
                var drone = await _repository.GetByIdAsync(id)
                    ?? throw new NotFoundException($"Drone with ID {id} not found.");
                await _repository.DeleteAsync(id);
                _logger.LogInformation("Drone {Id} deleted", id);
            }
            catch (Exception ex) when (ex is not NotFoundException)
            {
                _logger.LogError(ex, "Error deleting drone {Id}", id);
                throw;
            }
        }

        private DroneResponseDto MapToResponse(Drone drone) => new()
        {
            Id = drone.Id,
            Number = drone.Number,
            LotId = drone.LotId,
            LotName = drone.LotName,
            Status = drone.Status.ToString(),
            BatteryLevel = drone.BatteryLevel,
            TimeToCharge = drone.TimeToCharge,
            CreatedAt = drone.CreatedAt
        };
    }
}