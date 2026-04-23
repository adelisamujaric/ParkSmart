using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using PaymentService.Application.DTOs.Requests;
using PaymentService.Application.DTOs.Responses;
using PaymentService.Domain.Entities;
using PaymentService.Domain.Enums;
using PaymentService.Domain.Interfaces;
using Shared.Exceptions;
using Shared.Messages;
using Shared.RabbitMQ;

namespace PaymentService.Application.Services
{
    public class ReservationPaymentService
    {
        private readonly IReservationPaymentRepository _paymentRepository;
        private readonly StripeService _stripeService;
        private readonly ILogger<ReservationPaymentService> _logger;
        private readonly RabbitMQPublisherSingleton _publisher; 

        public ReservationPaymentService(
            IReservationPaymentRepository paymentRepository,
            StripeService stripeService,
            ILogger<ReservationPaymentService> logger,
            RabbitMQPublisherSingleton publisher) 
        {
            _paymentRepository = paymentRepository;
            _stripeService = stripeService;
            _logger = logger;
            _publisher = publisher; 
        }
        public async Task<IEnumerable<ReservationPaymentDto>> GetAllAsync()
        {
            var payments = await _paymentRepository.GetAllAsync();
            return payments.Select(MapToDto);
        }

        public async Task<IEnumerable<ReservationPaymentDto>> GetByUserIdAsync(Guid userId)
        {
            var payments = await _paymentRepository.GetByUserIdAsync(userId);
            return payments.Select(MapToDto);
        }

        public async Task<ReservationPaymentDto> GetByIdAsync(Guid id)
        {
            var payment = await _paymentRepository.GetByIdAsync(id);
            return MapToDto(payment);
        }

        public async Task<ReservationPaymentDto> CreateAsync(CreateReservationPaymentDto dto)
        {
            try
            {
                var paymentIntent = await _stripeService.CreatePaymentIntentAsync(dto.Amount);
                var payment = new ReservationPayment
                {
                    UserId = dto.UserId,
                    ReservationId = dto.ReservationId,
                    Amount = dto.Amount,
                    Method = dto.Method,
                    StripePaymentIntentId = paymentIntent.Id,
                    StripeClientSecret = paymentIntent.ClientSecret
                };
                var created = await _paymentRepository.CreateAsync(payment);
                _logger.LogInformation("Reservation payment created for reservation {ReservationId}, amount {Amount}", dto.ReservationId, dto.Amount);
                return MapToDto(created);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating reservation payment for reservation {ReservationId}", dto.ReservationId);
                throw;
            }
        }

        public async Task<ReservationPaymentDto> CompletePaymentAsync(Guid id)
        {
            try
            {
                var payment = await _paymentRepository.GetByIdAsync(id);
                var paymentIntent = await _stripeService.ConfirmPaymentIntentAsync(payment.StripePaymentIntentId!);

                _logger.LogInformation("Payment status for payment {PaymentId}: {Status}", id, paymentIntent.Status);

                if (paymentIntent.Status == "succeeded")
                {
                    payment.Status = PaymentStatus.Paid;
                    payment.CompletedAt = DateTime.UtcNow;

                    await _publisher.PublishAsync(RabbitMQConstants.ReservationPaymentCompletedNotificationQueue, new PaymentCompletedMessage
                    {
                        TicketId = payment.ReservationId,
                        UserId = payment.UserId,
                        Amount = payment.Amount
                    });
                    _logger.LogInformation("Reservation payment completed for reservation {ReservationId}", payment.ReservationId);
                }
                else
                {
                    _logger.LogWarning("Payment not succeeded for payment {PaymentId}, status: {Status}", id, paymentIntent.Status);
                    payment.Status = PaymentStatus.Failed;
                }

                var updated = await _paymentRepository.UpdateAsync(payment);
                return MapToDto(updated);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error completing reservation payment {PaymentId}", id);
                throw;
            }
        }

        public async Task<ReservationPaymentDto> RefundPaymentAsync(Guid id)
        {
            try
            {
                var payment = await _paymentRepository.GetByIdAsync(id);
                if (payment.Status != PaymentStatus.Paid)
                    throw new BadRequestException("Only completed payments can be refunded.");

                await _stripeService.RefundPaymentAsync(payment.StripePaymentIntentId!);
                payment.Status = PaymentStatus.Refunded;
                var updated = await _paymentRepository.UpdateAsync(payment);
                _logger.LogInformation("Reservation payment {PaymentId} refunded successfully", id);
                return MapToDto(updated);
            }
            catch (Exception ex) when (ex is not BadRequestException)
            {
                _logger.LogError(ex, "Error refunding reservation payment {PaymentId}", id);
                throw;
            }
        }

        public async Task<ReservationPaymentDto> FailPaymentAsync(Guid id)
        {
            try
            {
                var payment = await _paymentRepository.GetByIdAsync(id);
                payment.Status = PaymentStatus.Failed;
                var updated = await _paymentRepository.UpdateAsync(payment);
                _logger.LogInformation("Reservation payment {PaymentId} marked as failed", id);
                return MapToDto(updated);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error failing reservation payment {PaymentId}", id);
                throw;
            }
        }

        public async Task DeleteAsync(Guid id)
        {
            try
            {
                await _paymentRepository.DeleteAsync(id);
                _logger.LogInformation("Reservation payment {PaymentId} deleted", id);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting reservation payment {PaymentId}", id);
                throw;
            }
        }

        private ReservationPaymentDto MapToDto(ReservationPayment p) => new ReservationPaymentDto
        {
            Id = p.Id,
            UserId = p.UserId,
            ReservationId = p.ReservationId,
            Amount = p.Amount,
            Status = p.Status,
            Method = p.Method,
            StripePaymentIntentId = p.StripePaymentIntentId,
            StripeClientSecret = p.StripeClientSecret,
            CreatedAt = p.CreatedAt,
            CompletedAt = p.CompletedAt
        };
    }
}