using Microsoft.Extensions.Hosting;
using ParkingService.Application;
using ParkingService.Domain.Enums;
using ParkingService.Domain.Interfaces;
using Shared.Messages;
using Shared.RabbitMQ;

namespace ParkingService.WebAPI.BackgroundServices
{
    public class ParkingEventConsumer : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly IConfiguration _configuration;
        private readonly ILogger<ParkingEventConsumer> _logger; 

        public ParkingEventConsumer(
            IServiceProvider serviceProvider,
            IConfiguration configuration,
            ILogger<ParkingEventConsumer> logger) 
        {
            _serviceProvider = serviceProvider;
            _configuration = configuration;
            _logger = logger; 
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            var host = _configuration["RabbitMQ:Host"] ?? "localhost";
            var consumer = await RabbitMQConsumer.CreateAsync(host);

            await consumer.SubscribeAsync<VehicleDetectedMessage>(
                RabbitMQConstants.VehicleEntryQueue,
                async message =>
                {
                    _logger.LogInformation("Vehicle entry message received for plate {Plate}", message.LicensePlate);
                    try
                    {
                        using var scope = _serviceProvider.CreateScope();
                        var ticketService = scope.ServiceProvider.GetRequiredService<ParkingTicketService>();
                        await ticketService.CheckInFromDetectionAsync(message);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Entry consumer error for plate {Plate}", message.LicensePlate);
                    }
                });

            await consumer.SubscribeAsync<VehicleDetectedMessage>(
                RabbitMQConstants.VehicleExitQueue,
                async message =>
                {
                    _logger.LogInformation("Vehicle exit message received for plate {Plate}", message.LicensePlate);
                    try
                    {
                        using var scope = _serviceProvider.CreateScope();
                        var ticketService = scope.ServiceProvider.GetRequiredService<ParkingTicketService>();
                        await ticketService.CheckOutAsync(message.LicensePlate);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Exit consumer error for plate {Plate}", message.LicensePlate);
                    }
                });

            await consumer.SubscribeAsync<ViolationConfirmedMessage>(
                RabbitMQConstants.ViolationConfirmedQueue,
                async message =>
                {
                    _logger.LogInformation("Violation confirmed for plate {Plate}, SpotId {SpotId}", message.LicensePlate, message.SpotId);
                    using var scope = _serviceProvider.CreateScope();
                    var violationService = scope.ServiceProvider.GetRequiredService<ViolationService>();
                    await violationService.CreateViolationFromDetectionAsync(message);
                });

            await consumer.SubscribeAsync<PaymentCompletedMessage>(
                RabbitMQConstants.PaymentCompletedQueue,
                async message =>
                {
                    using var scope = _serviceProvider.CreateScope();
                    var ticketRepo = scope.ServiceProvider.GetRequiredService<IParkingTicketRepository>();
                    var ticket = await ticketRepo.GetByIdAsync(message.TicketId);
                    if (ticket != null)
                    {
                        ticket.Status = TicketStatus.Paid;
                        await ticketRepo.UpdateAsync(ticket);
                    }
                });

            await consumer.SubscribeAsync<ViolationPaymentCompletedMessage>(
                RabbitMQConstants.ViolationPaymentCompletedQueue,
                async message =>
                {
                    using var scope = _serviceProvider.CreateScope();
                    var violationRepo = scope.ServiceProvider.GetRequiredService<IParkingViolationRepository>();
                    var violation = await violationRepo.GetByIdAsync(message.ViolationId);
                    if (violation != null)
                    {
                        violation.IsResolved = true;
                        await violationRepo.UpdateAsync(violation);
                    }
                });

            await Task.Delay(Timeout.Infinite, stoppingToken);
        }
    }
}