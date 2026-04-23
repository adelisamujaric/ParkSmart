using DetectionService.Application.DTOs;
using DetectionService.Application.DTOs.Requests;
using DetectionService.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Authorization.Infrastructure;
using Microsoft.AspNetCore.Mvc;
using Shared.Constants;

namespace DetectionService.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    public class DetectionController : ControllerBase
    {
        private readonly DetectionAppService _detectionService;

        public DetectionController(DetectionAppService detectionService)
        {
            _detectionService = detectionService;
        }
        //------------------------------------------------------------------------------------------------------------------

        // This endpoint is intentionally left without authorization.
        // Cameras are hardware devices that cannot authenticate via JWT.
        // In production, this should be secured with an API Key mechanism.
        [HttpPost("analyze")]
        public async Task<IActionResult> AnalyzeImage([FromBody] AnalyzeImageRequestDto request)
        {
            var result = await _detectionService.AnalyzeImageAsync(request);
            return Ok(result);
        }
        //------------------------------------------------------------------------------------------------------------------

        [HttpGet("pending")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> GetPendingReviews()
        {
            var logs = await _detectionService.GetPendingReviewsAsync();
            return Ok(logs);
        }
        //------------------------------------------------------------------------------------------------------------------

        [HttpPut("review/{logId}")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> ReviewDetection(Guid logId, [FromBody] ReviewDetectionRequest request)
        {
            var result = await _detectionService.ReviewDetectionAsync(logId, request);
            return Ok(result);
        }
        //------------------------------------------------------------------------------------------------------------------

        [HttpGet("logs/lot/{lotId}")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> GetLogsByLot(Guid lotId)
        {
            var logs = await _detectionService.GetLogsByLotAsync(lotId);
            return Ok(logs);
        }
        //------------------------------------------------------------------------------------------------------------------

        [HttpGet("logs/plate/{licensePlate}")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> GetLogsByLicensePlate(string licensePlate)
        {
            var logs = await _detectionService.GetLogsByLicensePlateAsync(licensePlate);
            return Ok(logs);
        }
        //------------------------------------------------------------------------------------------------------------------
        [HttpPost("manual")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> CreateManualLog([FromBody] CreateDetectionLogDto request)
        {
            var result = await _detectionService.CreateManualLogAsync(request);
            return Ok(result);
        }
        //------------------------------------------------------------------------------------------------------------------

        [HttpGet("all")]
        [Authorize(Roles = Roles.Admin)]
        public async Task<IActionResult> GetAllLogs()
        {
            var logs = await _detectionService.GetAllLogsAsync();
            return Ok(logs);
        }
    }
}