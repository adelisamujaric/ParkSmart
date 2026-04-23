using Microsoft.Extensions.Hosting;
using PaymentService.Application.DTOs.Requests;
using PaymentService.Application.Services;
using Shared.Messages;
using Shared.RabbitMQ;

namespace PaymentService.WebAPI.BackgroundServices
{
    public class PaymentEventConsumer : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly IConfiguration _configuration;
        private readonly ILogger<PaymentEventConsumer> _logger; 

        public PaymentEventConsumer(
            IServiceProvider serviceProvider,
            IConfiguration configuration,
            ILogger<PaymentEventConsumer> logger) 
        {
            _serviceProvider = serviceProvider;
            _configuration = configuration;
            _logger = logger; 
        }

        protected override async Task ExecuteAsync(CancellationToken stoppingToken)
        {
            var host = _configuration["RabbitMQ:Host"] ?? "localhost";
            var consumer = await RabbitMQConsumer.CreateAsync(host);

            await consumer.SubscribeAsync<TicketClosedMessage>(
                RabbitMQConstants.TicketClosedQueue,
                async message =>
                {
                    try
                    {
                        using var scope = _serviceProvider.CreateScope();
                        var paymentService = scope.ServiceProvider.GetRequiredService<ParkingPaymentService>();
                        await paymentService.CreateAsync(new CreateParkingPaymentDto
                        {
                            UserId = message.UserId,
                            TicketId = message.TicketId,
                            Amount = message.TotalPrice,
                            Method = Domain.Enums.PaymentMethod.CreditCard
                        });
                        _logger.LogInformation("Parking payment created for ticket {TicketId}", message.TicketId);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error creating parking payment for ticket {TicketId}", message.TicketId);
                    }
                });

            await consumer.SubscribeAsync<ViolationCreatedMessage>(
                RabbitMQConstants.ViolationCreatedQueue,
                async message =>
                {
                    try
                    {
                        using var scope = _serviceProvider.CreateScope();
                        var paymentService = scope.ServiceProvider.GetRequiredService<ViolationPaymentService>();
                        await paymentService.CreateAsync(new CreateViolationPaymentDto
                        {
                            UserId = message.UserId,
                            ViolationId = message.ViolationId,
                            Amount = message.FineAmount
                        });
                        _logger.LogInformation("Violation payment created for violation {ViolationId}", message.ViolationId);
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Error creating violation payment for violation {ViolationId}", message.ViolationId);
                    }
                });

            await Task.Delay(Timeout.Infinite, stoppingToken);
        }
    }
}