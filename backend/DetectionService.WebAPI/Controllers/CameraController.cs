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
    public class CameraController : ControllerBase
    {
        private readonly CameraAppService _cameraService;

        public CameraController(CameraAppService cameraService)
        {
            _cameraService = cameraService;
        }
        //------------------------------------------------------------------------------------------------

        [HttpGet]
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> GetAll()
        {
            var cameras = await _cameraService.GetAllAsync();
            return Ok(cameras);
        }
        //------------------------------------------------------------------------------------------------

        [HttpGet("{id}")]
      
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> GetById(Guid id)
        {
            var camera = await _cameraService.GetByIdAsync(id);
            if (camera == null) return NotFound();
            return Ok(camera);
        }
        //------------------------------------------------------------------------------------------------

        [HttpPost]
       
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> Create([FromBody] CreateCameraDto dto)
        {
            var created = await _cameraService.CreateAsync(dto);
            return Ok(new { message = "Camera created.", data = created });
        }
        //------------------------------------------------------------------------------------------------

        [HttpPut("{id}/status")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> UpdateStatus(Guid id, [FromBody] CameraStatus status)
        {
            var updated = await _cameraService.UpdateStatusAsync(id, status);
            return Ok(new { message = "Camera status updated.", data = updated });
        }
        //------------------------------------------------------------------------------------------------

        [HttpDelete("{id}")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> Delete(Guid id)
        {
            await _cameraService.DeleteAsync(id);
            return Ok(new { message = "Camera deleted." });
        }
        //------------------------------------------------------------------------------------------------

    }
}