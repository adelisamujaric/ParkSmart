using ParkingService.Application.DTOs.Requests;
using ParkingService.Application.DTOs.Responses;
using ParkingService.Domain.Entities;
using ParkingService.Domain.Interfaces;
using Shared.Exceptions;

namespace ParkingService.Application
{
    public class ViolationConfigService
    {
        private readonly IViolationConfigRepository _configRepository;

        public ViolationConfigService(IViolationConfigRepository configRepository)
        {
            _configRepository = configRepository;
        }

        private ViolationConfigResponseDto MapToResponse(ViolationConfig config) => new ViolationConfigResponseDto
        {
            Id = config.Id,
            TypeName = config.TypeName,
            Description = config.Description,
            FineAmount = config.FineAmount,
            CreatedAt = config.CreatedAt,
            UpdatedAt = config.UpdatedAt
        };

        public async Task<List<ViolationConfigResponseDto>> GetAllAsync()
        {
            var items = await _configRepository.GetAllAsync();
            return items.Select(MapToResponse).ToList();
        }

        public async Task<ViolationConfigResponseDto> GetByIdAsync(Guid id)
        {
            var config = await _configRepository.GetByIdAsync(id);
            if (config == null)
                throw new NotFoundException($"ViolationConfig with ID {id} not found.");
            return MapToResponse(config);
        }

        public async Task<ViolationConfigResponseDto> CreateAsync(CreateViolationConfigDto dto)
        {
            var config = new ViolationConfig
            {
                TypeName = dto.TypeName,
                Description = dto.Description,
                FineAmount = dto.FineAmount
            };
            var created = await _configRepository.CreateAsync(config);
            return MapToResponse(created);
        }

        public async Task<ViolationConfigResponseDto> UpdateAsync(Guid id, UpdateViolationConfigDto dto)
        {
            var config = await _configRepository.GetByIdAsync(id);
            if (config == null)
                throw new NotFoundException($"ViolationConfig with ID {id} not found.");
            config.TypeName = dto.TypeName;
            config.Description = dto.Description;
            config.FineAmount = dto.FineAmount;
            var updated = await _configRepository.UpdateAsync(config);
            return MapToResponse(updated);
        }

        public async Task DeleteAsync(Guid id)
        {
            var config = await _configRepository.GetByIdAsync(id);
            if (config == null)
                throw new NotFoundException($"ViolationConfig with ID {id} not found.");
            await _configRepository.DeleteAsync(id);
        }
    }
}