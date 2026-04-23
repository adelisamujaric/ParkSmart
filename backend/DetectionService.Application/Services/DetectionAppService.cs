using DetectionService.Application.DTOs.Requests;
using DetectionService.Application.DTOs.Responses;
using DetectionService.Domain.Entities;
using DetectionService.Domain.Enums;
using DetectionService.Domain.Interfaces;
using DetectionService.Infrastructure.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Shared.Messages;
using Shared.RabbitMQ;

namespace DetectionService.Application.Services
{
    public class DetectionAppService
    {
        private readonly IDetectionLogRepository _repository;
        private readonly MLService _mlService;
        private readonly ParkingServiceClient _parkingServiceClient;
        private readonly ILogger<DetectionAppService> _logger;
        private readonly RabbitMQPublisherSingleton _publisher;

        public DetectionAppService(
            IDetectionLogRepository repository,
            MLService mlService,
            IConfiguration configuration, ParkingServiceClient parkingServiceClient, ILogger<DetectionAppService> logger, RabbitMQPublisherSingleton publisher)
        {
            _repository = repository;
            _mlService = mlService;
            _parkingServiceClient = parkingServiceClient;
            _logger = logger;
            _publisher = publisher; 
        }
        //------------------------------------------------------------------------------------------------------------

        public async Task<AnalyzeImageResponseDto> AnalyzeImageAsync(AnalyzeImageRequestDto request)
        {
            var detection = await _mlService.DetectLicensePlateAsync(request.Image);
            var licensePlate = detection.LicensePlate;
            var violationType = detection.ViolationType;

            var result = DetermineResult(request.CameraType, licensePlate, violationType);
            var status = DetermineStatus(request.CameraType, result);
            var lotName = await _parkingServiceClient.GetLotNameAsync(request.LotId);

            // Dohvati ViolationConfigId ako postoji violationType
            Guid? violationConfigId = null;
            if (!string.IsNullOrEmpty(violationType))
                violationConfigId = await _parkingServiceClient.GetViolationConfigIdByTypeNameAsync(violationType);

            var log = new DetectionLog
            {
                Id = Guid.NewGuid(),
                LotId = request.LotId,
                LotName = lotName,
                SpotId = request.SpotId,
                CameraType = request.CameraType,
                LicensePlate = licensePlate ?? string.Empty,
                Result = result,
                Status = status,
                DetectedAt = DateTime.UtcNow,
                CreatedAt = DateTime.UtcNow,
                ViolationType = violationType,
                ViolationConfigId = violationConfigId,
            };

            await _repository.CreateAsync(log);
            await PublishEventAsync(log);

            return new AnalyzeImageResponseDto
            {
                LogId = log.Id,
                LicensePlate = log.LicensePlate,
                Result = result,
                Status = status,
                Message = GetResultMessage(result),
                DetectedAt = log.DetectedAt
            };
        }
        //------------------------------------------------------------------------------------------------------------

        public async Task<DetectionLogResponseDto> ReviewDetectionAsync(Guid logId, ReviewDetectionRequest request)
        {
            var log = await _repository.GetByIdAsync(logId)
                ?? throw new Exception("Detection log not found.");

            if (log.Status != DetectionStatus.PendingReview)
                throw new Exception("Only pending detections can be reviewed.");

            log.Status = request.Confirmed ? DetectionStatus.Confirmed : DetectionStatus.Rejected;
            log.ReviewNote = request.ReviewNote;
            log.ReviewedAt = DateTime.UtcNow;

            await _repository.UpdateAsync(log);

            // Ako admin potvrdi violation, šalji event
            
            if (request.Confirmed && log.Result == DetectionResult.ViolationDetected)
            {
                _logger.LogInformation("Publishing violation confirmed for log {LogId}, result {Result}", logId, log.Result);

                await PublishViolationConfirmedAsync(log);
            }
            else
            {
                _logger.LogInformation("Not publishing - Confirmed: {Confirmed}, Result: {Result}", request.Confirmed, log.Result);
            }

            return MapToResponse(log);
        }
        //------------------------------------------------------------------------------------------------------------

        public async Task<List<DetectionLogResponseDto>> GetPendingReviewsAsync()
        {
            var logs = await _repository.GetPendingReviewsAsync();
            return logs.Select(MapToResponse).ToList();
        }
        //------------------------------------------------------------------------------------------------------------

        public async Task<List<DetectionLogResponseDto>> GetLogsByLotAsync(Guid lotId)
        {
            var logs = await _repository.GetByLotIdAsync(lotId);
            return logs.Select(MapToResponse).ToList();
        }
        //------------------------------------------------------------------------------------------------------------

        public async Task<List<DetectionLogResponseDto>> GetLogsByLicensePlateAsync(string licensePlate)
        {
            var logs = await _repository.GetByLicensePlateAsync(licensePlate);
            return logs.Select(MapToResponse).ToList();
        }
        //------------------------------------------------------------------------------------------------------------

        private async Task PublishEventAsync(DetectionLog log)
        {
            var queueName = log.Result switch
            {
                DetectionResult.EntryGranted => RabbitMQConstants.VehicleEntryQueue,
                DetectionResult.ExitGranted => RabbitMQConstants.VehicleExitQueue,
                DetectionResult.UnknownVehicle => RabbitMQConstants.DetectionUnknownQueue,
                _ => null
            };

            if (queueName == null)
            {
                _logger.LogWarning("Queue is null for result {Result}", log.Result);
                return;
            }

            _logger.LogInformation("Publishing to queue {Queue} for plate {Plate}", queueName, log.LicensePlate);

            try
            {
                var message = new VehicleDetectedMessage
                {
                    LogId = log.Id,
                    LicensePlate = log.LicensePlate,
                    LotId = log.LotId,
                    SpotId = log.SpotId,
                    DetectionCameraType = log.CameraType.ToString(),
                    Result = log.Result.ToString(),
                    DetectedAt = log.DetectedAt
                };
                await _publisher.PublishAsync(queueName, message); 
                _logger.LogInformation("Published successfully to queue {Queue}", queueName);

                if (log.Result == DetectionResult.EntryGranted)
                    await _publisher.PublishAsync(RabbitMQConstants.VehicleEntryNotificationQueue, message); 
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Publish error for queue {Queue}", queueName);
            }
        }
        //------------------------------------------------------------------------------------------------------------
        private async Task PublishViolationConfirmedAsync(DetectionLog log)
        {
            var userId = await _parkingServiceClient.GetUserIdByLicensePlateFromVehicleAsync(log.LicensePlate);
            _logger.LogInformation("UserId for plate {Plate}: {UserId}", log.LicensePlate, userId);

            // Dohvati ViolationConfigId ako nije već postavljen
            Guid? violationConfigId = log.ViolationConfigId;
            if (violationConfigId == null && !string.IsNullOrEmpty(log.ViolationType))
                violationConfigId = await _parkingServiceClient.GetViolationConfigIdByTypeNameAsync(log.ViolationType);

            
            var message = new ViolationConfirmedMessage
            {
                LogId = log.Id,
                LicensePlate = log.LicensePlate,
                LotId = log.LotId,
                SpotId = log.SpotId,
                UserId = userId,
                ViolationType = log.ViolationType ?? string.Empty,
                ViolationConfigId = violationConfigId ?? Guid.Empty,
                ConfirmedAt = DateTime.UtcNow
            };

            await _publisher.PublishAsync(RabbitMQConstants.ViolationConfirmedQueue, message);
            await _publisher.PublishAsync(RabbitMQConstants.ViolationConfirmedNotificationQueue, message);
           
        }
        //------------------------------------------------------------------------------------------------------------

        // DetermineResult ostaje sa stringom:
        private DetectionResult DetermineResult(DetectionCameraType cameraType, string? licensePlate, string? violationType)
        {
            if (string.IsNullOrEmpty(licensePlate))
                return DetectionResult.UnknownVehicle;

            return cameraType switch
            {
                DetectionCameraType.Entry => DetectionResult.EntryGranted,
                DetectionCameraType.Exit => DetectionResult.ExitGranted,
                DetectionCameraType.Drone => !string.IsNullOrEmpty(violationType)
                    ? DetectionResult.ViolationDetected
                    : DetectionResult.VehicleValid,
                _ => DetectionResult.UnknownVehicle
            };
        }
        //------------------------------------------------------------------------------------------------------------

        private DetectionStatus DetermineStatus(DetectionCameraType cameraType, DetectionResult result)
        {
            if (result == DetectionResult.UnknownVehicle)
                return DetectionStatus.PendingReview;

            if (cameraType == DetectionCameraType.Drone)
                return DetectionStatus.PendingReview;

            return DetectionStatus.AutoProcessed;
        }
        //------------------------------------------------------------------------------------------------------------

        private string GetResultMessage(DetectionResult result)
        {
            return result switch
            {
                DetectionResult.EntryGranted => "Vozilo može ući, ticket kreiran.",
                DetectionResult.ExitGranted => "Vozilo može izaći, ticket zatvoren.",
                DetectionResult.VehicleValid => "Vozilo ima validan ticket.",
                DetectionResult.ViolationDetected => "Prekršaj detektovan, čeka potvrdu admina.",
                DetectionResult.UnknownVehicle => "Tablica nije prepoznata, admin obaviješten.",
                _ => "Nepoznat rezultat."
            };
        }
        //------------------------------------------------------------------------------------------------------------
        public async Task<List<DetectionLogResponseDto>> GetAllLogsAsync()
        {
            var logs = await _repository.GetAllAsync();
            return logs.Select(MapToResponse).ToList();
        }
        //------------------------------------------------------------------------------------------------------------

        public async Task<DetectionLogResponseDto> CreateManualLogAsync(CreateDetectionLogDto request)
        {
            var lotName = await _parkingServiceClient.GetLotNameAsync(request.LotId);
            _logger.LogInformation(">>> LotName result: '{LotName}' for lotId: {LotId}", lotName, request.LotId);
            var result = DetermineResult(request.CameraType, request.LicensePlate,request.ViolationConfigId.HasValue ? "violation" : null);
            var status = DetermineStatus(request.CameraType, result);
            _logger.LogInformation("Manual log created - CameraType {CameraType}, ViolationConfigId {ViolationConfigId}, Result {Result}", request.CameraType, request.ViolationConfigId, result);

            var log = new DetectionLog
            {
                Id = Guid.NewGuid(),
                LotId = request.LotId,
                LotName = lotName,
                SpotId = request.SpotId,
                CameraType = request.CameraType,
                LicensePlate = request.LicensePlate,
                Result = result,
                Status = status,
                DetectedAt = DateTime.UtcNow,
                CreatedAt = DateTime.UtcNow,
                DroneNumber = request.DroneNumber,
                CameraNumber = request.CameraNumber,
                ViolationConfigId = request.ViolationConfigId,
            };

            await _repository.CreateAsync(log);
            await PublishEventAsync(log);
            return MapToResponse(log);
        }
        //------------------------------------------------------------------------------------------------------------

        private DetectionLogResponseDto MapToResponse(DetectionLog log)
        {
            return new DetectionLogResponseDto
            {
                Id = log.Id,
                LotId = log.LotId,
                LotName = log.LotName,
                SpotId = log.SpotId,
                DetectionCameraType = log.CameraType.ToString(),
                LicensePlate = log.LicensePlate,
                Result = log.Result.ToString(),
                Status = log.Status.ToString(),
                ImageUrl = log.ImageUrl,
                ReviewNote = log.ReviewNote,
                ReviewedAt = log.ReviewedAt,
                DetectedAt = log.DetectedAt,
                DroneNumber = log.DroneNumber,
                CameraNumber = log.CameraNumber,
                ViolationType = log.ViolationType,
                ViolationConfigId = log.ViolationConfigId

            };
        }
    }
}