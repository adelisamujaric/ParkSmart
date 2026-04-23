using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ParkingService.Application;
using ParkingService.Application.DTOs.Responses;
using ParkingService.Application.DTOs.Requests;
using ParkingService.Domain.Enums;
using Shared.Constants;

namespace ParkingService.WebAPI.Controllers;

[ApiController]
[Route("parkingSpot/[controller]")]
public class ParkingSpotController : ControllerBase
{
    private readonly ParkingSpotService _parkingSpotService;

    public ParkingSpotController(ParkingSpotService parkingSpotService)
    {
        _parkingSpotService = parkingSpotService;
    }

    [HttpGet("getLotById/{lotId}")]
    [Authorize]
    public async Task<IActionResult> GetAllByLotId(Guid lotId, [FromQuery] int page = 1, [FromQuery] int pageSize = 10)
    {
        var (items, totalCount) = await _parkingSpotService.GetAllByLotIdAsync(lotId, page, pageSize);
        return Ok(new
        {
            Data = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
            TotalPages = (int)Math.Ceiling((double)totalCount / pageSize)
        });
    }

    [HttpGet("getAvailableByLotId{lotId}")]
    [Authorize]
    public async Task<IActionResult> GetAvailableByLotId(Guid lotId)
    {
        var spots = await _parkingSpotService.GetAvailableByLotIdAsync(lotId);
        return Ok(new
        {
            Data = spots,
            TotalCount = spots.Count
        });
    }

    [HttpGet("getById{id}")]
    [Authorize]
    public async Task<IActionResult> GetById(Guid id)
    {
        var spot = await _parkingSpotService.GetByIdAsync(id);
        return Ok(spot);
    }

    [HttpPost("create")]
    [Authorize(Roles = Roles.Admin)] 
    public async Task<IActionResult> Create([FromBody] CreateParkingSpotDto dto)
    {
        var created = await _parkingSpotService.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.Id }, new
        {
            Message = "Parking spot successfully added.",
            Data = created
        });
    }

    [HttpPut("update{id}")]
    [Authorize(Roles = Roles.Admin)] 
    public async Task<IActionResult> Update(Guid id, [FromBody] UpdateParkingSpotDto dto)
    {
        var updated = await _parkingSpotService.UpdateAsync(id, dto);
        return Ok(new
        {
            Message = "Parking spot successfully updated.",
            Data = updated
        });
    }

    [HttpDelete("delete{id}")]
    [Authorize(Roles = Roles.Admin)] 
    public async Task<IActionResult> Delete(Guid id)
    {
        await _parkingSpotService.DeleteAsync(id);
        return Ok(new { Message = "Parking spot successfully deleted." });
    }
}