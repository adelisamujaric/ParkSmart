using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ParkingService.Application;
using ParkingService.Application.DTOs.Requests;
using ParkingService.Application.DTOs.Responses;
using Shared.Constants;

namespace ParkingService.WebAPI.Controllers;

[ApiController]
[Route("parkingLot/[controller]")]
public class ParkingLotController : ControllerBase
{
    private readonly ParkingLotService _parkingLotService;
    private readonly IConfiguration _configuration;


    public ParkingLotController(ParkingLotService parkingLotService, IConfiguration configuration)
    {
        _parkingLotService = parkingLotService;
        _configuration = configuration;
    }

    [HttpGet("getAll")]
    [Authorize] 
    public async Task<IActionResult> GetAll([FromQuery] int page = 1, [FromQuery] int pageSize = 10)
    {
        var (items, totalCount) = await _parkingLotService.GetAllAsync(page, pageSize);
        return Ok(new
        {
            Data = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
            TotalPages = (int)Math.Ceiling((double)totalCount / pageSize)
        });
    }

    // AllowAnonymous je potreban za interne servis-to-servis pozive (ParkingService -> UserService)
    // Endpoint je zaštićen ručnom provjerom X-Internal-Key headera
    [HttpGet("getById{id}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetById(Guid id)
    {
        var isInternal = Request.Headers["X-Internal-Key"] == _configuration["InternalServices:ApiKey"];
        var isAdmin = User.IsInRole(Roles.Admin);

        if (!isInternal && !isAdmin)
            return Forbid();

        var parkingLot = await _parkingLotService.GetByIdAsync(id);
        return Ok(parkingLot);
    }

    [HttpPost("create")]
    [Authorize(Roles = Roles.Admin)] 
    public async Task<IActionResult> Create([FromBody] CreateParkingLotDto dto)
    {
        var created = await _parkingLotService.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.Id }, new { message = "Parking lot created.", data = created });
    }

    [HttpPut("update{id}")]
    [Authorize(Roles = Roles.Admin)] 
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateParkingLotDto dto)
    {
        var updated = await _parkingLotService.UpdateAsync(id, dto);
        return Ok(new { message = "Parking lot updated.", data = updated });
    }

    [HttpDelete("delete{id}")]
    [Authorize(Roles = Roles.Admin)] 
    public async Task<IActionResult> Delete(Guid id)
    {
        await _parkingLotService.DeleteAsync(id);
        return Ok(new { message = "Parking lot deleted." });
    }

    [HttpGet("getAllAdmin")]
    [Authorize(Roles = Roles.Admin)] 
    public async Task<IActionResult> GetAllAdmin([FromQuery] int page = 1, [FromQuery] int pageSize = 100)
    {
        var (items, totalCount) = await _parkingLotService.GetAllIncludingInactiveAsync(page, pageSize);
        return Ok(new
        {
            Data = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
            TotalPages = (int)Math.Ceiling((double)totalCount / pageSize)
        });
    }
}