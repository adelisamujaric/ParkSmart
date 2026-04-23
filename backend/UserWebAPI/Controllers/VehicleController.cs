using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Hosting;
using Shared.Constants;
using Shared.DTOs;
using UserService.Services.DTOs.Requests;
using UserService.Services.DTOs.Responses;
using UserService.Services.Services;

namespace UserService.WebAPI.Controllers
{
    [Route("api/vehicles")]
    [ApiController]
    [Authorize]
    public class VehicleController : ControllerBase
    {
        private readonly VehicleAppService _vehicleService;
        private readonly IConfiguration _configuration;

        public VehicleController(VehicleAppService vehicleService, IConfiguration configuration)
        {
            _vehicleService = vehicleService;
            _configuration = configuration;
        }

        //---------------------------------------------------------------------------
        [Authorize(Roles = Roles.Admin)]
        [HttpGet("{id}")]
        public async Task<ActionResult<VehicleResponse>> GetVehicleById(Guid id)
        {
            var response = await _vehicleService.GetVehicleById(id);
            return Ok(response);
        }

        //---------------------------------------------------------------------------
        [Authorize(Roles = Roles.Admin)]
        [HttpGet("all")]
        public async Task<ActionResult<PagedResult<VehicleResponse>>> GetAllVehicles([FromQuery] int page = 1,[FromQuery] int pageSize = 10)
        {
            var result = await _vehicleService.GetAllVehicles(page, pageSize);
            return Ok(result);
        }

        //---------------------------------------------------------------------------
        [HttpGet("user/{userId}")]
        public async Task<ActionResult<List<VehicleResponse>>> GetVehiclesByUserId(Guid userId)
        {
            var vehicles = await _vehicleService.GetVehiclesByUserId(userId);
            return Ok(vehicles);
        }

        //---------------------------------------------------------------------------
        // AllowAnonymous je potreban za interne servis-to-servis pozive (ParkingService -> UserService)
        // Endpoint je zaštićen ručnom provjerom X-Internal-Key headera
        [AllowAnonymous]
        [HttpGet("by-license/{licensePlate}")]
        public async Task<ActionResult<VehicleWithOwnerResponse>> GetVehicleByLicensePlate(string licensePlate)
        {
            var isInternal = Request.Headers["X-Internal-Key"] == _configuration["InternalServices:ApiKey"];
            var isAdmin = User.IsInRole(Roles.Admin);

            if (!isInternal && !isAdmin)
                return Forbid();

            var response = await _vehicleService.GetVehicleByLicensePlate(licensePlate);
            return Ok(response);
        }
        //---------------------------------------------------------------------------
        [HttpPost("add")]
        public async Task<ActionResult<VehicleResponse>> CreateVehicle([FromBody] CreateVehicleRequest request)
        {
            var response = await _vehicleService.CreateVehicle(
                request.LicensePlate,
                request.Brand,
                request.Model,
                request.UserId
            );
            return CreatedAtAction(nameof(GetVehicleById), new { id = response.Id }, response);
        }

        //---------------------------------------------------------------------------
        [HttpPut("update/{id}")]
        public async Task<ActionResult<VehicleResponse>> UpdateVehicle(Guid id, [FromBody] UpdateVehicleRequest request)
        {
            var response = await _vehicleService.UpdateVehicle(
                id,
                request.LicensePlate,
                request.Brand,
                request.Model
            );
            return Ok(response);
        }

        //---------------------------------------------------------------------------
        [HttpDelete("delete/{id}")]
        public async Task<IActionResult> DeleteVehicle(Guid id)
        {
            await _vehicleService.DeleteVehicle(id);
            return NoContent();
        }
        //---------------------------------------------------------------------------

    }
}
