using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ParkingService.Application;
using ParkingService.Application.DTOs.Requests;
using Shared.Constants;

namespace ParkingService.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class ViolationConfigController : ControllerBase
    {
        private readonly ViolationConfigService _configService;

        public ViolationConfigController(ViolationConfigService configService)
        {
            _configService = configService;
        }

        [HttpGet("getAll")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> GetAll()
        {
            var items = await _configService.GetAllAsync();
            return Ok(new { Data = items });
        }

        [HttpGet("{id}")]
        [Authorize(Roles = Roles.Admin)]

        public async Task<IActionResult> GetById(Guid id)
        {
            var item = await _configService.GetByIdAsync(id);
            return Ok(item);
        }

        [HttpPost("create")]
        [Authorize(Roles = Roles.Admin)] 
        public async Task<IActionResult> Create([FromBody] CreateViolationConfigDto dto)
        {
            var created = await _configService.CreateAsync(dto);
            return Ok(new { Message = "ViolationConfig created.", Data = created });
        }

        [HttpPut("update/{id}")]
        [Authorize(Roles = Roles.Admin)] 
        public async Task<IActionResult> Update(Guid id, [FromBody] UpdateViolationConfigDto dto)
        {
            var updated = await _configService.UpdateAsync(id, dto);
            return Ok(new { Message = "ViolationConfig updated.", Data = updated });
        }

        [HttpDelete("delete/{id}")]
        [Authorize(Roles = Roles.Admin)] 
        public async Task<IActionResult> Delete(Guid id)
        {
            await _configService.DeleteAsync(id);
            return Ok(new { Message = "ViolationConfig deleted." });
        }
    }
}