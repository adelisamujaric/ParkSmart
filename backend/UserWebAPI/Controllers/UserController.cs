using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Shared.Constants;
using Shared.DTOs;
using System.Security.Claims;
using UserService.Services.DTOs.Requests;
using UserService.Services.DTOs.Responses;
using UserService.Services.Services;

namespace UserService.WebAPI.Controllers
{
    [Route("api/users")] 
    [ApiController]
    [Authorize]
    public class UserController : ControllerBase
    {
        private readonly UserAppService _userService;

        public UserController(UserAppService userService)
        {
            _userService = userService;
        }

        //---------------------------------------------------------------------------
       
        [HttpGet("{id}")]
        public async Task<ActionResult<UserResponse>> GetUserById(Guid id)
        {
            var currentUserId = Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
            var isAdmin = User.IsInRole(Roles.Admin);

            // Dozvoli ako je admin ILI ako korisnik gleda svoje podatke
            if (!isAdmin && currentUserId != id)
                return Forbid();

            var response = await _userService.GetUserById(id);
            return Ok(response);
        }

        //---------------------------------------------------------------------------
        [HttpGet("all")]  // GET /api/users/all
        public async Task<ActionResult<PagedResult<UserResponse>>> GetAllUsers([FromQuery] int page = 1,[FromQuery] int pageSize = 10)  
        {
            var isAdmin = User.IsInRole(Roles.Admin);
            var result = await _userService.GetAllUsers(page, pageSize, isAdmin);
            return Ok(result);
        }

        //---------------------------------------------------------------------------
       
        [HttpPut("update/{id}")]  // PUT /api/users/update/{id}
        public async Task<ActionResult<UserResponse>> UpdateUser(Guid id, [FromBody] UpdateUserRequest request)
        {
            var response = await _userService.UpdateUser(
                id,
                request.FirstName,
                request.LastName,
                request.PhoneNumber,
                request.Address,
                request.City,
                request.PostalCode,
                request.Country,
                request.IsDisabled
            );
            return Ok(response);
        }

        //---------------------------------------------------------------------------
        [HttpDelete("delete/{id}")]  // DELETE /api/users/delete/{id}
        public async Task<IActionResult> DeleteUser(Guid id)
        {
            await _userService.DeleteUser(id);
            return NoContent();
        }
        //---------------------------------------------------------------------------

    }
}