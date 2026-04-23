using Microsoft.AspNetCore.Mvc;
using PaymentService.Application.DTOs.Requests;
using PaymentService.Application.Services;

[ApiController]
[Route("api/[controller]")]
public class ParkingPaymentController : ControllerBase
{
    private readonly ParkingPaymentService _paymentService;

    public ParkingPaymentController(ParkingPaymentService paymentService)
    {
        _paymentService = paymentService;
    }
    //------------------------------------------------------------------------------------
    [HttpGet("getAll")]
    public async Task<IActionResult> GetAll()
    {
        var payments = await _paymentService.GetAllAsync();
        return Ok(payments);
    }
    //------------------------------------------------------------------------------------

    [HttpGet("getByUserId/{userId}")]
    public async Task<IActionResult> GetByUserId(Guid userId)
    {
        var payments = await _paymentService.GetByUserIdAsync(userId);
        return Ok(payments);
    }
    //------------------------------------------------------------------------------------

    [HttpGet("getById{id}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var payment = await _paymentService.GetByIdAsync(id);
        return Ok(payment);
    }
    //------------------------------------------------------------------------------------

    [HttpPost("create")]
    public async Task<IActionResult> Create([FromBody] CreateParkingPaymentDto dto)
    {
        var payment = await _paymentService.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = payment.Id }, payment);
    }
    //------------------------------------------------------------------------------------

    [HttpPatch("{id}/complete")]
    public async Task<IActionResult> Complete(Guid id)
    {
        var payment = await _paymentService.CompletePaymentAsync(id);
        return Ok(payment);
    }
    //------------------------------------------------------------------------------------

    [HttpPatch("{id}/refund")]
    public async Task<IActionResult> Refund(Guid id)
    {
        var payment = await _paymentService.RefundPaymentAsync(id);
        return Ok(payment);
    }
    //------------------------------------------------------------------------------------

    [HttpPatch("{id}/fail")]
    public async Task<IActionResult> Fail(Guid id)
    {
        var payment = await _paymentService.FailPaymentAsync(id);
        return Ok(payment);
    }
    //------------------------------------------------------------------------------------

    [HttpDelete("delete{id}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        await _paymentService.DeleteAsync(id);
        return NoContent();
    }
    //------------------------------------------------------------------------------------

}