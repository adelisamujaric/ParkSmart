using Shared.DTOs;
using Shared.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UserService.Modules.Entities;
using UserService.Modules.Interfaces;
using UserService.Services.DTOs.Requests;
using UserService.Services.DTOs.Responses;

namespace UserService.Services.Services
{
    public class VehicleAppService
    {
        private readonly IVehicleRepository _vehicleRepository;
        private readonly IUserRepository _userRepository;

        public VehicleAppService(IVehicleRepository vehicleRepository, IUserRepository userRepository)
        {
            _vehicleRepository = vehicleRepository;
            _userRepository = userRepository;
        }

        //----------------------------------------------------------------------------
        public async Task<VehicleResponse> GetVehicleById(Guid id)
        {
            var vehicle = await _vehicleRepository.GetVehicleById(id);

            if (vehicle == null)
            {
                throw new NotFoundException("Vehicle does not exist");
            }

            if (!vehicle.IsActive)
            {
                throw new BadRequestException("Vehicle is deactivated");
            }

            return MapToVehicleResponse(vehicle);
        }

        //---------------------------------------------------------------------------
        public async Task<PagedResult<VehicleResponse>> GetAllVehicles(int page, int pageSize)
        {
            var totalCount = await _vehicleRepository.GetTotalCount();
            var vehicles = await _vehicleRepository.GetAllVehicles(page, pageSize);

            return new PagedResult<VehicleResponse>
            {
                Items = vehicles.Select(v => MapToVehicleResponse(v)).ToList(),
                CurrentPage = page,
                PageSize = pageSize,
                TotalCount = totalCount,
                TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
            };
        }

        //---------------------------------------------------------------------------
        public async Task<List<VehicleResponse>> GetVehiclesByUserId(Guid userId)
        {
            var vehicles = await _vehicleRepository.GetVehiclesByUserId(userId);
            return vehicles.Select(v => MapToVehicleResponse(v)).ToList();
        }

        //---------------------------------------------------------------------------

        public async Task<VehicleWithOwnerResponse> GetVehicleByLicensePlate(string licensePlate)
        {
            var vehicle = await _vehicleRepository.GetVehicleByLicenceWithOwner(licensePlate);

            if (vehicle == null)
            {
                throw new NotFoundException("Vehicle not found");
            }

            if (!vehicle.IsActive)
            {
                throw new BadRequestException("Vehicle is deactivated");
            }

            return new VehicleWithOwnerResponse
            {
                Vehicle = MapToVehicleResponse(vehicle),
                Owner = new OwnerInfoResponse
                {
                    Id = vehicle.User.Id,
                    FirstName = vehicle.User.FirstName,
                    LastName = vehicle.User.LastName,
                    Email = vehicle.User.Email,
                    PhoneNumber = vehicle.User.PhoneNumber
                }
            };
        }
        
        //---------------------------------------------------------------------------
        public async Task<VehicleResponse> CreateVehicle(string licensePlate, string brand,
                                                 string model, Guid userId)
        {
            // 1. Check if user exists
            var user = await _userRepository.GetUserById(userId);  // ← DODAJ OVO
            if (user == null)
            {
                throw new NotFoundException($"User with ID {userId} does not exist");
            }

            if (!user.IsActive)
            {
                throw new BadRequestException("Cannot add vehicle to deactivated user");
            }

            // 2. Check if license plate exists
            var existingVehicle = await _vehicleRepository.GetVehicleByLicence(licensePlate);
            if (existingVehicle != null)
            {
                throw new BadRequestException("License plate already exists");
            }

            var vehicle = new Vehicle
            {
                Id = Guid.NewGuid(),
                LicensePlate = licensePlate,
                Brand = brand,
                Model = model,
                UserId = userId,
                CreatedAt = DateTime.UtcNow,
                IsActive = true
            };

            var createdVehicle = await _vehicleRepository.CreateVehicle(vehicle);
            return MapToVehicleResponse(createdVehicle);
        }
        //------------------------------------------------------------------------------
        public async Task<VehicleResponse> UpdateVehicle(Guid id, string? licensePlate,
                                                         string? brand, string? model)
        {
            var vehicle = await _vehicleRepository.GetVehicleById(id);

            if (vehicle == null)
            {
                throw new NotFoundException("Vehicle does not exist");
            }

            if (!vehicle.IsActive)
            {
                throw new BadRequestException("Vehicle is deactivated");
            }

            // Update if not null
            if (!string.IsNullOrEmpty(licensePlate))
            {
                // Check if new license plate already exists
                var existingVehicle = await _vehicleRepository.GetVehicleByLicence(licensePlate);
                if (existingVehicle != null && existingVehicle.Id != id)
                {
                    throw new BadRequestException("License plate already exists");
                }
                vehicle.LicensePlate = licensePlate;
            }
            if (!string.IsNullOrEmpty(brand)) vehicle.Brand = brand;
            if (!string.IsNullOrEmpty(model)) vehicle.Model = model;

            var updatedVehicle = await _vehicleRepository.UpdateVehicle(vehicle);
            return MapToVehicleResponse(updatedVehicle);
        }

        //-----------------------------------------------------------------------------
        public async Task<string> DeleteVehicle(Guid id)
        {
            var vehicle = await _vehicleRepository.GetVehicleById(id);

            if (vehicle == null)
            {
                throw new NotFoundException("Vehicle does not exist");
            }

            await _vehicleRepository.DeleteVehicle(id);
            return "Vehicle successfully deleted";
        }

        //-----------------------------------------------------------------------------
        // Helper method
        public VehicleResponse MapToVehicleResponse(Vehicle vehicle)
        {
            return new VehicleResponse
            {
                Id = vehicle.Id,
                LicensePlate = vehicle.LicensePlate,
                Brand = vehicle.Brand,
                Model = vehicle.Model,
                UserId = vehicle.UserId,
                CreatedAt = vehicle.CreatedAt,
                IsActive = vehicle.IsActive
            };
        }
    }
}