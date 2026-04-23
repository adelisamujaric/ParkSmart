using DetectionService.Application.DTOs.Requests;
using DetectionService.Application.Services;
using DetectionService.Domain.Enums;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Shared.Constants;

namespace DetectionService.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DroneController : ControllerBase
    {
        private readonly DroneAppService _droneService;

        public DroneController(DroneAppService droneService)
        {
            _droneService = droneService;
        }
        //------------------------------------------------------------------------------------------------

        [HttpGet]
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> GetAll()
        {
            var drones = await _droneService.GetAllAsync();
            return Ok(drones);
        }
        //------------------------------------------------------------------------------------------------

        [HttpGet("{id}")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> GetById(Guid id)
        {
            var drone = await _droneService.GetByIdAsync(id);
            if (drone == null) return NotFound();
            return Ok(drone);
        }
        //------------------------------------------------------------------------------------------------

        [HttpPost]
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> Create([FromBody] CreateDroneDto dto)
        {
            var created = await _droneService.CreateAsync(dto);
            return Ok(new { message = "Drone created.", data = created });
        }
        //------------------------------------------------------------------------------------------------

        [HttpPut("{id}/status")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> UpdateStatus(Guid id, [FromBody] DroneStatus status)
        {
            var updated = await _droneService.UpdateStatusAsync(id, status);
            return Ok(new { message = "Drone status updated.", data = updated });
        }
        //------------------------------------------------------------------------------------------------

        [HttpDelete("{id}")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> Delete(Guid id)
        {
            await _droneService.DeleteAsync(id);
            return Ok(new { message = "Drone deleted." });
        }
        //------------------------------------------------------------------------------------------------

    }
}