// WebAPI/Controllers/ViolationController.cs

using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ParkingService.Application;
using ParkingService.Application.DTOs.Requests;
using Shared.Constants;
using System.Security.Claims;

namespace ParkingService.WebAPI.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ViolationController : ControllerBase
{
    private readonly ViolationService _violationService;

    public ViolationController(ViolationService violationService)
    {
        _violationService = violationService;
    }
    
    //--------------------------------------------------------------------------------------------------------------------------

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var violation = await _violationService.GetByIdAsync(id);
        return Ok(violation);
    }
    //--------------------------------------------------------------------------------------------------------------------------

    [HttpGet("by-plate")]
    public async Task<IActionResult> GetByLicensePlate([FromQuery] string licensePlate, [FromQuery] int page = 1, [FromQuery] int pageSize = 10)
    {
        var (items, totalCount) = await _violationService.GetAllByLicensePlateAsync(licensePlate, page, pageSize);
        return Ok(new
        {
            Data = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
            TotalPages = (int)Math.Ceiling((double)totalCount / pageSize)
        });
    }
    //--------------------------------------------------------------------------------------------------------------------------

    [HttpGet("unresolved")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> GetAllUnresolved([FromQuery] int page = 1, [FromQuery] int pageSize = 10)
    {
        var (items, totalCount) = await _violationService.GetAllUnresolvedAsync(page, pageSize);
        return Ok(new
        {
            Data = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
            TotalPages = (int)Math.Ceiling((double)totalCount / pageSize)
        });
    }
    //--------------------------------------------------------------------------------------------------------------------------

    [HttpPost]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> Create([FromBody] CreateParkingViolationDto dto)
    {
        var created = await _violationService.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = created.Id }, new
        {
            Message = "Violation successfully created.",
            Data = created
        });
    }
    //--------------------------------------------------------------------------------------------------------------------------

    [HttpPost("{id}/resolve")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> Resolve(Guid id)
    {
        var updated = await _violationService.ResolveAsync(id);
        return Ok(new
        {
            Message = "Violation successfully resolved.",
            Data = updated
        });
    }
    //--------------------------------------------------------------------------------------------------------------------------
    [HttpGet("user/{userId}")]
    public async Task<IActionResult> GetByUserId(Guid userId)
    {
        var violations = await _violationService.GetAllByUserIdAsync(userId);
        return Ok(violations);
    }
}