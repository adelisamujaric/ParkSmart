
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ParkingService.Application;
using ParkingService.Application.DTOs.Requests;
using System.Security.Claims;

namespace ParkingService.WebAPI.Controllers;

[ApiController]
[Route("parkingReservation/[controller]")]
[Authorize]
public class ReservationController : ControllerBase
{
    private readonly ReservationService _reservationService;

    public ReservationController(ReservationService reservationService)
    {
        _reservationService = reservationService;
    }
    //----------------------------------------------------------------------------------------------------------------------

    private Guid GetUserId() => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    private string GetUserRole() => User.FindFirstValue(ClaimTypes.Role)!;
    //----------------------------------------------------------------------------------------------------------------------
    [HttpGet("getMyReservation")]
    public async Task<IActionResult> GetMyReservations([FromQuery] int page = 1, [FromQuery] int pageSize = 10)
    {
        var userId = GetUserId();
        var (items, totalCount) = await _reservationService.GetAllByUserIdAsync(userId, page, pageSize);
        return Ok(new
        {
            Data = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
            TotalPages = (int)Math.Ceiling((double)totalCount / pageSize)
        });
    }
    //----------------------------------------------------------------------------------------------------------------------

    [HttpGet("getById{id}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var userId = GetUserId();
        var role = GetUserRole();
        var reservation = await _reservationService.GetByIdAsync(id, userId, role);
        return Ok(reservation);
    }
    //----------------------------------------------------------------------------------------------------------------------

    [HttpPost("create")]
    public async Task<IActionResult> Create([FromBody] CreateReservationDto dto)
    {
        var userId = GetUserId();
        var created = await _reservationService.CreateAsync(dto, userId);
        return CreatedAtAction(nameof(GetById), new { id = created.Id }, new
        {
            Message = "Reservation successfully created.",
            Data = created
        });
    }
    //----------------------------------------------------------------------------------------------------------------------

    [HttpPost("cancel{id}")]
    public async Task<IActionResult> Cancel(Guid id)
    {
        var userId = GetUserId();
        var role = GetUserRole();
        var cancelled = await _reservationService.CancelAsync(id, userId, role);
        return Ok(new
        {
            Message = "Reservation successfully cancelled.",
            Data = cancelled
        });
    }
    //----------------------------------------------------------------------------------------------------------------------
    [HttpPost("{id}/pay")]
    public async Task<IActionResult> Pay(Guid id)
    {
        var userId = GetUserId();
        var role = GetUserRole();
        var updated = await _reservationService.PayAsync(id, userId, role);
        return Ok(new
        {
            Message = "Payment successful.",
            Data = updated
        });
    }
}