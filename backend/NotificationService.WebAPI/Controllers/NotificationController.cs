using Microsoft.AspNetCore.Mvc;
using NotificationService.Application.DTOs.Requests;
using NotificationService.Application.Services;

[ApiController]
[Route("api/[controller]")]
public class NotificationController : ControllerBase
{
    private readonly NotificationAppService _notificationService;

    public NotificationController(NotificationAppService notificationService)
    {
        _notificationService = notificationService;
    }
    //---------------------------------------------------------------------------------------

    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var notifications = await _notificationService.GetAllAsync();
        return Ok(notifications);
    }
    //---------------------------------------------------------------------------------------

    [HttpGet("user/{userId}")]
    public async Task<IActionResult> GetByUserId(Guid userId)
    {
        var notifications = await _notificationService.GetByUserIdAsync(userId);
        return Ok(notifications);
    }
    //---------------------------------------------------------------------------------------

    [HttpGet("{id}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var notification = await _notificationService.GetByIdAsync(id);
        return Ok(notification);
    }
    //---------------------------------------------------------------------------------------

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] CreateNotificationDto dto)
    {
        var notification = await _notificationService.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = notification.Id }, notification);
    }
    //---------------------------------------------------------------------------------------

    [HttpPatch("{id}/read")]
    public async Task<IActionResult> MarkAsRead(Guid id)
    {
        await _notificationService.MarkAsReadAsync(id);
        return NoContent();
    }
    //---------------------------------------------------------------------------------------

    [HttpDelete("{id}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        await _notificationService.DeleteAsync(id);
        return NoContent();
    }
    //---------------------------------------------------------------------------------------

}