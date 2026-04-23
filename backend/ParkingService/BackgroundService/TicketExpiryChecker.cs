using ParkingService.Domain.Interfaces;
using Shared.Messages;
using Shared.RabbitMQ;

namespace ParkingService.WebAPI.BackgroundServices
{
    public class TicketExpiryChecker : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<TicketExpiryChecker> _logger;
        private readonly RabbitMQPublisherSingleton _publisher; 
        private readonly HashSet<Guid> _notifiedTickets = new();

        public TicketExpiryChecker(
            IServiceProvider serviceProvider,
            ILogger<TicketExpiryChecker> logger,
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
                    await CheckExpiringTicketsAsync();
                    await CheckExpiredTicketsAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "TicketExpiryChecker unexpected error"); 
                }
                await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
            }
        }

        private async Task CheckExpiringTicketsAsync()
        {
            using var scope = _serviceProvider.CreateScope();
            var ticketRepository = scope.ServiceProvider.GetRequiredService<IParkingTicketRepository>();
            var expiringTickets = await ticketRepository.GetExpiringTicketsAsync(15);

            var newExpiringTickets = expiringTickets
                .Where(t => !_notifiedTickets.Contains(t.Id))
                .ToList();

            if (!newExpiringTickets.Any()) return;

            foreach (var ticket in newExpiringTickets)
            {
                try
                {
                    await _publisher.PublishAsync(RabbitMQConstants.TicketExpiringQueue, new TicketExpiringMessage
                    {
                        TicketId = ticket.Id,
                        UserId = ticket.UserId,
                        LicensePlate = ticket.LicensePlate,
                        EndTime = ticket.EndTime!.Value,
                        MinutesRemaining = 15
                    });
                    _notifiedTickets.Add(ticket.Id);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error publishing expiring ticket notification for ticket {TicketId}", ticket.Id);
                }
            }
        }


        private async Task CheckExpiredTicketsAsync()
        {
            using var scope = _serviceProvider.CreateScope();
            var ticketRepository = scope.ServiceProvider.GetRequiredService<IParkingTicketRepository>();
            var parkingSpotRepository = scope.ServiceProvider.GetRequiredService<IParkingSpotRepository>();

            var expiredTickets = await ticketRepository.GetExpiredActiveTicketsAsync();
            if (!expiredTickets.Any()) return;

            foreach (var ticket in expiredTickets)
            {
                try
                {
                    var lot = ticket.ParkingSpot?.ParkingLot;
                    var totalMinutes = (decimal)(DateTime.UtcNow - ticket.EntryTime).TotalMinutes;
                    ticket.TotalPrice = totalMinutes * (lot?.RatePerMinute ?? 0);
                    ticket.ExitTime = DateTime.UtcNow;
                    ticket.PaymentDeadline = DateTime.UtcNow.AddHours(24);
                    ticket.Status = Domain.Enums.TicketStatus.PendingPayment;
                    await ticketRepository.UpdateAsync(ticket);

                    if (ticket.SpotId.HasValue)
                        await parkingSpotRepository.UpdateStatusAsync(ticket.SpotId.Value, Domain.Enums.ParkingSpotStatus.Available);

                    await _publisher.PublishAsync(RabbitMQConstants.TicketClosedQueue, new TicketClosedMessage
                    {
                        TicketId = ticket.Id,
                        UserId = ticket.UserId,
                        LicensePlate = ticket.LicensePlate,
                        TotalPrice = ticket.TotalPrice ?? 0,
                        ExitTime = ticket.ExitTime!.Value
                    });

                    await _publisher.PublishAsync(RabbitMQConstants.VehicleExitNotificationQueue, new TicketClosedMessage
                    {
                        TicketId = ticket.Id,
                        UserId = ticket.UserId,
                        LicensePlate = ticket.LicensePlate,
                        TotalPrice = ticket.TotalPrice ?? 0,
                        ExitTime = ticket.ExitTime!.Value
                    });
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error processing expired ticket {TicketId} for plate {Plate}", ticket.Id, ticket.LicensePlate);
                }
            }
        }
    }
}