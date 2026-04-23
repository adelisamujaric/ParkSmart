// WebAPI/Controllers/ParkingTicketController.cs

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
public class ParkingTicketController : ControllerBase
{
    private readonly ParkingTicketService _ticketService;

    public ParkingTicketController(ParkingTicketService ticketService)
    {
        _ticketService = ticketService;
    }
    //------------------------------------------------------------------------------------------------------

    private Guid GetUserId() => Guid.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier)!);
    private string GetUserRole() => User.FindFirstValue(ClaimTypes.Role)!;
    //------------------------------------------------------------------------------------------------------
    [HttpGet("getAll")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> GetAll([FromQuery] int page = 1, [FromQuery] int pageSize = 50)
    {
        var (items, totalCount) = await _ticketService.GetAllAsync(page, pageSize);
        return Ok(new
        {
            Data = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
            TotalPages = (int)Math.Ceiling((double)totalCount / pageSize)
        });
    }
    //------------------------------------------------------------------------------------------------------

    [HttpGet("getMyTicket")]
    public async Task<IActionResult> GetMyTickets([FromQuery] int page = 1, [FromQuery] int pageSize = 10)
    {
        var userId = GetUserId();
        var (items, totalCount) = await _ticketService.GetAllByUserIdAsync(userId, page, pageSize);
        return Ok(new
        {
            Data = items,
            TotalCount = totalCount,
            Page = page,
            PageSize = pageSize,
            TotalPages = (int)Math.Ceiling((double)totalCount / pageSize)
        });
    }
    //------------------------------------------------------------------------------------------------------

    [HttpGet("getById{id}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var userId = GetUserId();
        var role = GetUserRole();
        var ticket = await _ticketService.GetByIdAsync(id, userId, role);
        return Ok(ticket);
    }
    //------------------------------------------------------------------------------------------------------
    [HttpGet("getByPlate")]
    public async Task<IActionResult> GetActiveByPlate([FromQuery] string licensePlate)
    {
        var ticket = await _ticketService.GetActiveByPlateAsync(licensePlate);
        if (ticket == null) return NotFound();
        return Ok(ticket);
    }
    //------------------------------------------------------------------------------------------------------

    [HttpPost("checkin")]
    public async Task<IActionResult> CheckIn([FromBody] CreateParkingTicketDto dto)
    {
        var userId = GetUserId();
        var created = await _ticketService.CheckInAsync(dto, userId);

        var durationMessage = dto.DurationMinutes.HasValue
            ? $"Parking purchased for {FormatDuration(dto.DurationMinutes.Value)}."
            : "Check-in successful.";

        return CreatedAtAction(nameof(GetById), new { id = created.Id }, new
        {
            Message = durationMessage,
            Data = created
        });
    }
    //------------------------------------------------------------------------------------------------------

    [HttpPost("checkout")]
    public async Task<IActionResult> CheckOut([FromQuery] string licensePlate)
    {
        var updated = await _ticketService.CheckOutAsync(licensePlate);
        return Ok(new
        {
            Message = "Check-out successful. Proceed to payment.",
            Data = updated
        });
    }
    //------------------------------------------------------------------------------------------------------

    [HttpPost("{id}/extend")]
    public async Task<IActionResult> Extend(Guid id, [FromQuery] int additionalMinutes)
    {
        var userId = GetUserId();
        var role = GetUserRole();
        var updated = await _ticketService.ExtendAsync(id, additionalMinutes, userId, role);
        return Ok(new
        {
            Message = $"Ticket extended by {FormatDuration(additionalMinutes)} minutes.",
            Data = updated
        });
    }
    //------------------------------------------------------------------------------------------------------

    [HttpPost("{id}/pay")]
    public async Task<IActionResult> Pay(Guid id)
    {
        var userId = GetUserId();
        var role = GetUserRole();
        var updated = await _ticketService.PayAsync(id, userId, role);
        return Ok(new
        {
            Message = "Payment successful.",
            Data = updated
        });
    }
    //------------------------------------------------------------------------------------------------------

    
    private string FormatDuration(int minutes)
    {
        if (minutes < 60)
            return $"{minutes} minutes";

        var hours = minutes / 60;
        var remainingMinutes = minutes % 60;

        if (remainingMinutes == 0)
            return $"{hours}h";

        return $"{hours}h {remainingMinutes}min";
    }

    [HttpGet("active/user")]
    public async Task<IActionResult> GetActiveByUser()
    {
        var userId = GetUserId();
        var tickets = await _ticketService.GetActiveByUserIdAsync(userId);
        return Ok(tickets);
    }

}