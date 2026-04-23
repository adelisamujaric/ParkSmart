using Shared.DTOs;
using Shared.Exceptions;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using UserService.Modules.Entities;
using UserService.Modules.Enums;
using UserService.Modules.Interfaces;
using UserService.Services.DTOs.Responses;
using UserService.Services.DTOs.Requests;

namespace UserService.Services.Services
{
    public class UserAppService
    {
        private readonly IUserRepository _userRepository;

        public UserAppService(IUserRepository userRepository)
        {
            _userRepository = userRepository;
        }

        //----------------------------------------------------------------------------
   
        public async Task<UserResponse> GetUserById(Guid id)
        {
            var user = await _userRepository.GetUserById(id);

            if (user == null)
                throw new NotFoundException("User does not exist");

            if (!user.IsActive)
                throw new BadRequestException("User is deactivated");

            return MapToUserResponse(user);
        }

        //---------------------------------------------------------------------------
        public async Task<PagedResult<UserResponse>> GetAllUsers(int page, int pageSize, bool isAdmin)
        {
            if (!isAdmin)
            {
                throw new AccessDeniedException("Access denied. Only admins can view all users.");
            }

            var totalCount = await _userRepository.GetTotalCount();
            var users = await _userRepository.GetAllUsers(page, pageSize);

            return new PagedResult<UserResponse>
            {
                Items = users.Select(u => MapToUserResponse(u)).ToList(),
                CurrentPage = page,
                PageSize = pageSize,
                TotalCount = totalCount,
                TotalPages = (int)Math.Ceiling(totalCount / (double)pageSize)
            };
        }

        //---------------------------------------------------------------------------
       
        public async Task<UserResponse> UpdateUser(Guid id, string? firstName, string? lastName,
                                                    string? phoneNumber, string? address, string? city,
                                                    string? postalCode, string? country, bool? isDisabled)
        {
            var user = await _userRepository.GetUserById(id);

            if (user == null)
            {
                throw new NotFoundException("User does not exist");
            }

            if (!user.IsActive)
            {
                throw new BadRequestException("User is deactivated");
            }

            // Update if not null
            if (!string.IsNullOrEmpty(firstName)) user.FirstName = firstName;
            if (!string.IsNullOrEmpty(lastName)) user.LastName = lastName;
            if (!string.IsNullOrEmpty(phoneNumber)) user.PhoneNumber = phoneNumber;
            if (!string.IsNullOrEmpty(address)) user.Address = address;
            if (!string.IsNullOrEmpty(city)) user.City = city;
            if (!string.IsNullOrEmpty(postalCode)) user.PostalCode = postalCode;
            if (!string.IsNullOrEmpty(country)) user.Country = country;
            if (isDisabled.HasValue) user.IsDisabled = isDisabled.Value;

            var updatedUser = await _userRepository.UpdateUser(user);
            return MapToUserResponse(updatedUser);
        }

        //-----------------------------------------------------------------------------
        public async Task<string> DeleteUser(Guid id)
        {
            var user = await _userRepository.GetUserById(id);

            if (user == null)
            {
                throw new NotFoundException("User does not exist");
            }

            await _userRepository.DeleteUser(id);
            return "User successfully deleted";
        }

        //-----------------------------------------------------------------------------
        // Helper methode
        private UserResponse MapToUserResponse(User user)
        {
            return new UserResponse
            {
                Id = user.Id,
                FirstName = user.FirstName,
                LastName = user.LastName,
                Email = user.Email,
                PhoneNumber = user.PhoneNumber,
                Address = user.Address,
                City = user.City,
                PostalCode = user.PostalCode,
                Country = user.Country,
                Role = user.Role,
                CreatedAt = user.CreatedAt,
                IsActive = user.IsActive,
                IsDisabled = user.IsDisabled
            };
        }
        //-----------------------------------------------------------------------------


    }
}