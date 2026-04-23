using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using ReportingService.Application.Services;
using Shared.Constants;

namespace ReportingService.WebAPI.Controllers
{
    [ApiController]
    [Route("api/[controller]")]
    [Authorize(Roles = Roles.Admin)]
    public class ReportsController : ControllerBase
    {
        private readonly ReportingService.Application.Services.ReportingAppService _reportingService;
        private readonly PdfReportService _pdfService;
        private readonly ILogger<ReportsController> _logger;

        public ReportsController(
            ReportingAppService reportingService,
            PdfReportService pdfService,
            ILogger<ReportsController> logger)
        {
            _reportingService = reportingService;
            _pdfService = pdfService;
            _logger = logger;
        }

        [HttpGet("revenue")]
        public async Task<IActionResult> GetRevenueReport([FromQuery] DateTime from, [FromQuery] DateTime to)
        {
            try
            {
                _logger.LogInformation("Revenue report requested from {From} to {To}", from, to);
                var report = await _reportingService.GetRevenueReportAsync(from, to);
                return Ok(report);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating revenue report from {From} to {To}", from, to);
                throw;
            }
        }

        [HttpGet("revenue/pdf")]
        public async Task<IActionResult> GetRevenueReportPdf([FromQuery] DateTime from, [FromQuery] DateTime to)
        {
            try
            {
                _logger.LogInformation("Revenue PDF report requested from {From} to {To}", from, to);
                var report = await _reportingService.GetRevenueReportAsync(from, to);
                var pdf = _pdfService.GenerateRevenueReport(report, from, to);
                return File(pdf, "application/pdf", $"revenue-report-{from:yyyyMMdd}-{to:yyyyMMdd}.pdf");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating revenue PDF report from {From} to {To}", from, to);
                throw;
            }
        }

        [HttpGet("occupancy")]
        public async Task<IActionResult> GetOccupancyReport([FromQuery] DateTime from, [FromQuery] DateTime to)
        {
            try
            {
                _logger.LogInformation("Occupancy report requested from {From} to {To}", from, to);
                var report = await _reportingService.GetOccupancyReportAsync(from, to);
                return Ok(report);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating occupancy report from {From} to {To}", from, to);
                throw;
            }
        }

        [HttpGet("occupancy/pdf")]
        public async Task<IActionResult> GetOccupancyReportPdf([FromQuery] DateTime from, [FromQuery] DateTime to)
        {
            try
            {
                _logger.LogInformation("Occupancy PDF report requested from {From} to {To}", from, to);
                var report = await _reportingService.GetOccupancyReportAsync(from, to);
                var pdf = _pdfService.GenerateOccupancyReport(report, from, to);
                return File(pdf, "application/pdf", $"occupancy-report-{from:yyyyMMdd}-{to:yyyyMMdd}.pdf");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating occupancy PDF report from {From} to {To}", from, to);
                throw;
            }
        }

        [HttpGet("violations")]
        public async Task<IActionResult> GetViolationsReport([FromQuery] DateTime from, [FromQuery] DateTime to)
        {
            try
            {
                _logger.LogInformation("Violations report requested from {From} to {To}", from, to);
                var report = await _reportingService.GetViolationsReportAsync(from, to);
                _logger.LogInformation("Violations report generated - total {Total}, by type count {Count}", report.TotalViolations, report.ViolationsByType.Count);
                return Ok(report);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating violations report from {From} to {To}", from, to);
                throw;
            }
        }

        [HttpGet("violations/pdf")]
        public async Task<IActionResult> GetViolationsReportPdf([FromQuery] DateTime from, [FromQuery] DateTime to)
        {
            try
            {
                _logger.LogInformation("Violations PDF report requested from {From} to {To}", from, to);
                var report = await _reportingService.GetViolationsReportAsync(from, to);
                var pdf = _pdfService.GenerateViolationsReport(report, from, to);
                return File(pdf, "application/pdf", $"violations-report-{from:yyyyMMdd}-{to:yyyyMMdd}.pdf");
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error generating violations PDF report from {From} to {To}", from, to);
                throw;
            }
        }
    }
}