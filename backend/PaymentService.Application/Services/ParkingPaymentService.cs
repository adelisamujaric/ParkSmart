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
    public class ParkingPaymentService
    {
        private readonly IParkingPaymentRepository _paymentRepository;
        private readonly StripeService _stripeService;
        private readonly ILogger<ParkingPaymentService> _logger;
        private readonly RabbitMQPublisherSingleton _publisher; 

        public ParkingPaymentService(
            IParkingPaymentRepository paymentRepository,
            StripeService stripeService,
            ILogger<ParkingPaymentService> logger,
            RabbitMQPublisherSingleton publisher) 
        {
            _paymentRepository = paymentRepository;
            _stripeService = stripeService;
            _logger = logger;
            _publisher = publisher; 
        }

        public async Task<IEnumerable<ParkingPaymentDto>> GetAllAsync()
        {
            var payments = await _paymentRepository.GetAllAsync();
            return payments.Select(MapToDto);
        }

        public async Task<IEnumerable<ParkingPaymentDto>> GetByUserIdAsync(Guid userId)
        {
            var payments = await _paymentRepository.GetByUserIdAsync(userId);
            return payments.Select(MapToDto);
        }

        public async Task<ParkingPaymentDto> GetByIdAsync(Guid id)
        {
            var payment = await _paymentRepository.GetByIdAsync(id);
            return MapToDto(payment);
        }

        public async Task<ParkingPaymentDto> CreateAsync(CreateParkingPaymentDto dto)
        {
            try
            {
                var paymentIntent = await _stripeService.CreatePaymentIntentAsync(dto.Amount);

                var payment = new ParkingPayment
                {
                    UserId = dto.UserId,
                    TicketId = dto.TicketId,
                    Amount = dto.Amount,
                    Method = dto.Method,
                    StripePaymentIntentId = paymentIntent.Id,
                    StripeClientSecret = paymentIntent.ClientSecret
                };

                var created = await _paymentRepository.CreateAsync(payment);
                _logger.LogInformation("Parking payment created for ticket {TicketId}, amount {Amount}", dto.TicketId, dto.Amount);
                return MapToDto(created);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error creating parking payment for ticket {TicketId}", dto.TicketId);
                throw;
            }
        }

        public async Task<ParkingPaymentDto> CompletePaymentAsync(Guid id)
        {
            try
            {
                var payment = await _paymentRepository.GetByIdAsync(id);
                var paymentIntent = await _stripeService.ConfirmPaymentIntentAsync(payment.StripePaymentIntentId);

                _logger.LogInformation("Payment status for payment {PaymentId}: {Status}", id, paymentIntent.Status);

                if (paymentIntent.Status == "succeeded")
                {
                    payment.Status = PaymentStatus.Paid;
                    payment.CompletedAt = DateTime.UtcNow;

                    await _publisher.PublishAsync(RabbitMQConstants.PaymentCompletedQueue, new PaymentCompletedMessage
                    {
                        TicketId = payment.TicketId,
                        UserId = payment.UserId,
                        Amount = payment.Amount
                    });

                    _logger.LogInformation("Payment completed and published for ticket {TicketId}", payment.TicketId);
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
                _logger.LogError(ex, "Error completing payment {PaymentId}", id);
                throw;
            }
        }

        public async Task<ParkingPaymentDto> RefundPaymentAsync(Guid id)
        {
            try
            {
                var payment = await _paymentRepository.GetByIdAsync(id);

                if (payment.Status != PaymentStatus.Paid)
                    throw new BadRequestException("Only completed payments can be refunded.");

                await _stripeService.RefundPaymentAsync(payment.StripePaymentIntentId);

                payment.Status = PaymentStatus.Refunded;
                var updated = await _paymentRepository.UpdateAsync(payment);
                _logger.LogInformation("Payment {PaymentId} refunded successfully", id);
                return MapToDto(updated);
            }
            catch (Exception ex) when (ex is not BadRequestException)
            {
                _logger.LogError(ex, "Error refunding payment {PaymentId}", id);
                throw;
            }
        }

        public async Task<ParkingPaymentDto> FailPaymentAsync(Guid id)
        {
            try
            {
                var payment = await _paymentRepository.GetByIdAsync(id);
                payment.Status = PaymentStatus.Failed;
                var updated = await _paymentRepository.UpdateAsync(payment);
                _logger.LogInformation("Payment {PaymentId} marked as failed", id);
                return MapToDto(updated);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error failing payment {PaymentId}", id);
                throw;
            }
        }

        public async Task DeleteAsync(Guid id)
        {
            try
            {
                await _paymentRepository.DeleteAsync(id);
                _logger.LogInformation("Payment {PaymentId} deleted", id);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error deleting payment {PaymentId}", id);
                throw;
            }
        }

        private ParkingPaymentDto MapToDto(ParkingPayment p) => new ParkingPaymentDto
        {
            Id = p.Id,
            UserId = p.UserId,
            TicketId = p.TicketId,
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