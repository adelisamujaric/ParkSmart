using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.DependencyInjection;
using ParkingService.Application;
using ParkingService.Domain.Enums;
using ParkingService.Domain.Interfaces;

namespace ParkingService.WebAPI.BackgroundServices
{
    public class PaymentDeadlineChecker : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly ILogger<PaymentDeadlineChecker> _logger;

        public PaymentDeadlineChecker(IServiceProvider serviceProvider, ILogger<PaymentDeadlineChecker> logger)
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
                    await CheckDeadlines();
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "PaymentDeadlineChecker unexpected error");
                }
                await Task.Delay(TimeSpan.FromMinutes(5), stoppingToken);
            }
        }

        private async Task CheckDeadlines()
        {
            using var scope = _serviceProvider.CreateScope();
            var ticketRepository = scope.ServiceProvider.GetRequiredService<IParkingTicketRepository>();
            var tickets = await ticketRepository.GetOverdueTicketsAsync();

            foreach (var ticket in tickets)
            {
                try
                {
                    ticket.LateFee += 1;
                    ticket.PaymentDeadline = DateTime.UtcNow.AddHours(24);
                    await ticketRepository.UpdateAsync(ticket);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "PaymentDeadlineChecker error processing ticket {TicketId}", ticket.Id);
                }
            }
        }
    }
}