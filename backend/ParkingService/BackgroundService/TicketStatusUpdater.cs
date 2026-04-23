using ParkingService.Domain.Enums;
using ParkingService.Domain.Interfaces;

namespace ParkingService.WebAPI.BackgroundServices
{
    public class TicketStatusUpdater : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<TicketStatusUpdater> _logger;

        public TicketStatusUpdater(
            IServiceProvider serviceProvider,
            ILogger<TicketStatusUpdater> logger) 
        {
            _serviceProvider = serviceProvider;
            _logger = logger; 
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            while (!stoppingToken.IsCancellationRequested)
            {
                try
                {
                    await UpdateExpiredTicketsAsync();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "TicketStatusUpdater unexpected error"); 
                }
                await Task.Delay(TimeSpan.FromMinutes(1), stoppingToken);
            }
        }

        private async Task UpdateExpiredTicketsAsync()
        {
            using var scope = _serviceProvider.CreateScope();
            var ticketRepository = scope.ServiceProvider.GetRequiredService<IParkingTicketRepository>();
            var expiredTickets = await ticketRepository.GetExpiredActiveTicketsAsync();

            foreach (var ticket in expiredTickets)
            {
                try
                {
                    ticket.Status = TicketStatus.PendingPayment;
                    ticket.ExitTime = ticket.EndTime;
                    ticket.PaymentDeadline = DateTime.UtcNow.AddHours(24);
                    await ticketRepository.UpdateAsync(ticket);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "Error updating expired ticket {TicketId}", ticket.Id); 
                }
            }
        }
    }
}