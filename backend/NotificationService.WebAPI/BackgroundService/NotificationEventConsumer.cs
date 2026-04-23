using NotificationService.Application.DTOs.Requests;
using NotificationService.Application.Services;
using NotificationService.Domain.Enums;
using Shared.Messages;
using Shared.RabbitMQ;

namespace NotificationService.WebAPI.BackgroundServices
{
    public class NotificationEventConsumer : BackgroundService
    {
        private readonly IServiceProvider _serviceProvider;
        private readonly IConfiguration _configuration;
        private readonly ILogger<NotificationEventConsumer> _logger;

        public NotificationEventConsumer(
            IServiceProvider serviceProvider,
            IConfiguration configuration,
            ILogger<NotificationEventConsumer> logger)
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
                RabbitMQConstants.VehicleEntryNotificationQueue,
                async message =>
                {
                    try
                    {
                        using var scope = _serviceProvider.CreateScope();
                        var notificationService = scope.ServiceProvider.GetRequiredService<NotificationAppService>();
                        await notificationService.CreateAsync(new CreateNotificationDto
                        {
                            UserId = message.UserId ?? Guid.Empty,
                            Title = "Ticket: Ulaz",
                            Message = $"Vaše vozilo {message.LicensePlate} je ušlo u parking.",
                            Type = NotificationType.Push
                        });
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Entry notification error for plate {Plate}", message.LicensePlate);
                    }
                });

            await consumer.SubscribeAsync<TicketClosedMessage>(
                RabbitMQConstants.VehicleExitNotificationQueue,
                async message =>
                {
                    try
                    {
                        using var scope = _serviceProvider.CreateScope();
                        var notificationService = scope.ServiceProvider.GetRequiredService<NotificationAppService>();
                        await notificationService.CreateAsync(new CreateNotificationDto
                        {
                            UserId = message.UserId,
                            Title = "Ticket: Izlaz",
                            Message = $"Vaše vozilo {message.LicensePlate} je izašlo. Ukupna cijena: {message.TotalPrice:C}. Platite u roku 24h.",
                            Type = NotificationType.Push
                        });
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Ticket closed notification error for plate {Plate}", message.LicensePlate);
                    }
                });

            await consumer.SubscribeAsync<TicketExpiringMessage>(
                RabbitMQConstants.TicketExpiringQueue,
                async message =>
                {
                    try
                    {
                        using var scope = _serviceProvider.CreateScope();
                        var notificationService = scope.ServiceProvider.GetRequiredService<NotificationAppService>();
                        await notificationService.CreateAsync(new CreateNotificationDto
                        {
                            UserId = message.UserId,
                            Title = "Ticket: Napomena",
                            Message = $"Vaše parkiranje za vozilo {message.LicensePlate} ističe za manje od 15 minuta.",
                            Type = NotificationType.Push
                        });
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Ticket expiring notification error for plate {Plate}", message.LicensePlate);
                    }
                });

            await consumer.SubscribeAsync<PaymentCompletedMessage>(
                RabbitMQConstants.PaymentCompletedQueue,
                async message =>
                {
                    try
                    {
                        using var scope = _serviceProvider.CreateScope();
                        var notificationService = scope.ServiceProvider.GetRequiredService<NotificationAppService>();
                        await notificationService.CreateAsync(new CreateNotificationDto
                        {
                            UserId = message.UserId,
                            Title = "Plaćanje: Ticket uspješno plaćen",
                            Message = $"Plaćanje tiketa je uspješno izvršeno. Iznos: {message.Amount:C}.",
                            Type = NotificationType.Push
                        });
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Payment notification error for user {UserId}", message.UserId);
                    }
                });

            await consumer.SubscribeAsync<ViolationConfirmedMessage>(
                RabbitMQConstants.ViolationConfirmedNotificationQueue,
                async message =>
                {
                    try
                    {
                        using var scope = _serviceProvider.CreateScope();
                        var notificationService = scope.ServiceProvider.GetRequiredService<NotificationAppService>();
                        await notificationService.CreateAsync(new CreateNotificationDto
                        {
                            UserId = message.UserId ?? Guid.Empty,
                            Title = "Prekršaj: Detekcija",
                            Message = $"Prekršaj je evidentiran za vozilo {message.LicensePlate}.",
                            Type = NotificationType.Push
                        });
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Violation confirmed notification error for plate {Plate}", message.LicensePlate);
                    }
                });

            await consumer.SubscribeAsync<ViolationPaymentCompletedMessage>(
                RabbitMQConstants.ViolationPaymentCompletedNotificationQueue,
                async message =>
                {
                    try
                    {
                        using var scope = _serviceProvider.CreateScope();
                        var notificationService = scope.ServiceProvider.GetRequiredService<NotificationAppService>();
                        await notificationService.CreateAsync(new CreateNotificationDto
                        {
                            UserId = message.UserId,
                            Title = "Plaćanje: Prekršaj uspješno plaćen",
                            Message = $"Plaćanje prekršaja je uspješno izvršeno. Iznos: {message.Amount:F2} KM.",
                            Type = NotificationType.Push
                        });
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Violation payment notification error for user {UserId}", message.UserId);
                    }
                });

            await consumer.SubscribeAsync<ReservationExpiredMessage>(
                RabbitMQConstants.ReservationExpiredQueue,
                async message =>
                {
                    try
                    {
                        using var scope = _serviceProvider.CreateScope();
                        var notificationService = scope.ServiceProvider.GetRequiredService<NotificationAppService>();
                        await notificationService.CreateAsync(new CreateNotificationDto
                        {
                            UserId = message.UserId,
                            Title = "Rezervacija: Isteklo",
                            Message = $"Vaša rezervacija za vozilo {message.LicensePlate} je istekla. Ukupna cijena: {message.TotalPrice:F2} KM.",
                            Type = NotificationType.Push
                        });
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Reservation expired notification error for plate {Plate}", message.LicensePlate);
                    }
                });

            await consumer.SubscribeAsync<ReservationCreatedMessage>(
                RabbitMQConstants.ReservationCreatedQueue,
                async message =>
                {
                    try
                    {
                        using var scope = _serviceProvider.CreateScope();
                        var notificationService = scope.ServiceProvider.GetRequiredService<NotificationAppService>();
                        await notificationService.CreateAsync(new CreateNotificationDto
                        {
                            UserId = message.UserId,
                            Title = "Rezervacija: Kreirano",
                            Message = $"Rezervacija za vozilo {message.LicensePlate} u {message.LotName} je potvrđena. Vrijedi od {message.StartTime:dd.MM.yyyy HH:mm} do {message.EndTime:dd.MM.yyyy HH:mm}.",
                            Type = NotificationType.Push
                        });
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Reservation created notification error for plate {Plate}", message.LicensePlate);
                    }
                });

            await consumer.SubscribeAsync<TicketExpiringMessage>(
                RabbitMQConstants.ReservationExpiringQueue,
                async message =>
                {
                    try
                    {
                        using var scope = _serviceProvider.CreateScope();
                        var notificationService = scope.ServiceProvider.GetRequiredService<NotificationAppService>();
                        await notificationService.CreateAsync(new CreateNotificationDto
                        {
                            UserId = message.UserId,
                            Title = "Rezervacija: Ističe",
                            Message = $"Vaša rezervacija za vozilo {message.LicensePlate} ističe za manje od 15 minuta.",
                            Type = NotificationType.Push
                        });
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Reservation expiring notification error for plate {Plate}", message.LicensePlate);
                    }
                });

            await consumer.SubscribeAsync<PaymentCompletedMessage>(
                RabbitMQConstants.ReservationPaymentCompletedNotificationQueue,
                async message =>
                {
                    try
                    {
                        using var scope = _serviceProvider.CreateScope();
                        var notificationService = scope.ServiceProvider.GetRequiredService<NotificationAppService>();
                        await notificationService.CreateAsync(new CreateNotificationDto
                        {
                            UserId = message.UserId,
                            Title = "Plaćanje: Rezervacija uspješno plaćena",
                            Message = $"Plaćanje rezervacije je uspješno izvršeno. Iznos: {message.Amount:F2} KM.",
                            Type = NotificationType.Push
                        });
                    }
                    catch (Exception ex)
                    {
                        _logger.LogError(ex, "Reservation payment notification error for user {UserId}", message.UserId);
                    }
                });

            await Task.Delay(Timeout.Infinite, stoppingToken);
        }
    }
}