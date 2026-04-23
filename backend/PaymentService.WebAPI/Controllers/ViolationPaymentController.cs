using Microsoft.AspNetCore.Mvc;
using PaymentService.Application.DTOs.Requests;
using PaymentService.Application.Services;

[ApiController]
[Route("api/[controller]")]
public class ViolationPaymentController : ControllerBase
{
    private readonly ViolationPaymentService _violationPaymentService;

    public ViolationPaymentController(ViolationPaymentService violationPaymentService)
    {
        _violationPaymentService = violationPaymentService;
    }
    //------------------------------------------------------------------------------------

    [HttpGet("getAll")]
    public async Task<IActionResult> GetAll()
    {
        var payments = await _violationPaymentService.GetAllAsync();
        return Ok(payments);
    }
    //------------------------------------------------------------------------------------

    [HttpGet("getByUserId/{userId}")]
    public async Task<IActionResult> GetByUserId(Guid userId)
    {
        var payments = await _violationPaymentService.GetByUserIdAsync(userId);
        return Ok(payments);
    }
    //------------------------------------------------------------------------------------

    [HttpGet("getById{id}")]
    public async Task<IActionResult> GetById(Guid id)
    {
        var payment = await _violationPaymentService.GetByIdAsync(id);
        return Ok(payment);
    }
    //------------------------------------------------------------------------------------

    [HttpPost("create")]
    public async Task<IActionResult> Create([FromBody] CreateViolationPaymentDto dto)
    {
        var payment = await _violationPaymentService.CreateAsync(dto);
        return CreatedAtAction(nameof(GetById), new { id = payment.Id }, payment);
    }
    //------------------------------------------------------------------------------------

    [HttpPatch("{id}/complete")]
    public async Task<IActionResult> Complete(Guid id)
    {
        var payment = await _violationPaymentService.CompletePaymentAsync(id);
        return Ok(payment);
    }
    //------------------------------------------------------------------------------------

    [HttpPatch("{id}/fail")]
    public async Task<IActionResult> Fail(Guid id)
    {
        var payment = await _violationPaymentService.FailPaymentAsync(id);
        return Ok(payment);
    }
    //------------------------------------------------------------------------------------

    [HttpDelete("delete{id}")]
    public async Task<IActionResult> Delete(Guid id)
    {
        await _violationPaymentService.DeleteAsync(id);
        return NoContent();
    }
    //------------------------------------------------------------------------------------

}