using ParkingService.Domain.Enums;
using ParkingService.Domain.Interfaces;
using Shared.Messages;
using Shared.RabbitMQ;

namespace ParkingService.WebAPI.BackgroundServices
{
    public class ReservationExpiryChecker : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<ReservationExpiryChecker> _logger;
        private readonly RabbitMQPublisherSingleton _publisher; 
        private readonly HashSet<Guid> _notifiedReservations = new();

        public ReservationExpiryChecker(
            IServiceProvider serviceProvider,
            ILogger<ReservationExpiryChecker> logger,
            RabbitMQPublisherSingleton publisher) 
        {
            _serviceProvider = serviceProvider;
            _logger = logger;
            _publisher = publisher; 
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await CheckExpiringReservationsAsync();
                    await CheckExpiredReservationsAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "ReservationExpiryChecker unexpected error"); 
                }
                await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
            }
        }

        private async Task CheckExpiringReservationsAsync()
        {
            using var scope = _serviceProvider.CreateScope();
            var reservationRepository = scope.ServiceProvider.GetRequiredService<IParkingReservationRepository>();

            var expiringReservations = await reservationRepository.GetExpiringReservationsAsync(15);
            var newExpiring = expiringReservations
                .Where(r => !_notifiedReservations.Contains(r.Id))
                .ToList();

            if (!newExpiring.Any()) return;

            foreach (var reservation in newExpiring)
            {
                try
                {
                    await _publisher.PublishAsync(RabbitMQConstants.ReservationExpiringQueue, new TicketExpiringMessage
                    {
                        TicketId = reservation.Id,
                        UserId = reservation.UserId,
                        LicensePlate = reservation.LicensePlate,
                        EndTime = reservation.EndTime,
                        MinutesRemaining = 15
                    });
                    _notifiedReservations.Add(reservation.Id);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error publishing expiring reservation notification for reservation {ReservationId}", reservation.Id);
                }
            }
        }

        private async Task CheckExpiredReservationsAsync()
        {
            using var scope = _serviceProvider.CreateScope();
            var reservationRepository = scope.ServiceProvider.GetRequiredService<IParkingReservationRepository>();
            var parkingSpotRepository = scope.ServiceProvider.GetRequiredService<IParkingSpotRepository>();

            var expiredReservations = await reservationRepository.GetExpiredReservationsAsync();
            if (!expiredReservations.Any()) return;

            foreach (var reservation in expiredReservations)
            {
                try
                {
                    reservation.Status = ReservationStatus.Expired;
                    await reservationRepository.UpdateAsync(reservation);
                    await parkingSpotRepository.UpdateStatusAsync(reservation.SpotId, ParkingSpotStatus.Available);

                    await _publisher.PublishAsync(RabbitMQConstants.ReservationExpiredQueue, new ReservationExpiredMessage
                    {
                        ReservationId = reservation.Id,
                        UserId = reservation.UserId,
                        LicensePlate = reservation.LicensePlate,
                        TotalPrice = reservation.TotalPrice,
                        EndTime = reservation.EndTime
                    });
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error processing expired reservation {ReservationId}", reservation.Id);
                }
            }
        }
    }
    
}