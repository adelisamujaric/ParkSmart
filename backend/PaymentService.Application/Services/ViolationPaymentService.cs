using Microsoft.Extensions.Logging;
using PaymentService.Application.DTOs.Requests;
using PaymentService.Application.DTOs.Responses;
using PaymentService.Domain.Entities;
using PaymentService.Domain.Enums;
using PaymentService.Domain.Interfaces;
using Shared.Messages;
using Shared.RabbitMQ;


namespace PaymentService.Application.Services
{
    public class ViolationPaymentService
    {
        private readonly IViolationPaymentRepository _violationPaymentRepository;
        private readonly StripeService _stripeService;
        private readonly ILogger<ViolationPaymentService> _logger;
        private readonly RabbitMQPublisherSingleton _publisher; 

        public ViolationPaymentService(
            IViolationPaymentRepository violationPaymentRepository,
            StripeService stripeService,
            ILogger<ViolationPaymentService> logger,
            RabbitMQPublisherSingleton publisher)
        {
            _violationPaymentRepository = violationPaymentRepository;
            _stripeService = stripeService;
            _logger = logger;
            _publisher = publisher; 
        }
        //------------------------------------------------------------------------------------

        public async Task<IEnumerable<ViolationPaymentDto>> GetAllAsync()
        {
            var payments = await _violationPaymentRepository.GetAllAsync();
            return payments.Select(MapToDto);
        }
        //------------------------------------------------------------------------------------

        public async Task<IEnumerable<ViolationPaymentDto>> GetByUserIdAsync(Guid userId)
        {
            var payments = await _violationPaymentRepository.GetByUserIdAsync(userId);
            return payments.Select(MapToDto);
        }
        //------------------------------------------------------------------------------------

        public async Task<ViolationPaymentDto> GetByIdAsync(Guid id)
        {
            var payment = await _violationPaymentRepository.GetByIdAsync(id);
            return MapToDto(payment);
        }
        //------------------------------------------------------------------------------------
        public async Task<ViolationPaymentDto> CreateAsync(CreateViolationPaymentDto dto)
        {
            var paymentIntent = await _stripeService.CreatePaymentIntentAsync(dto.Amount);

            var payment = new ViolationPayment
            {
                UserId = dto.UserId,
                ViolationId = dto.ViolationId,
                Amount = dto.Amount,
                StripePaymentIntentId = paymentIntent.Id,
                StripeClientSecret = paymentIntent.ClientSecret
            };

            var created = await _violationPaymentRepository.CreateAsync(payment);
            return MapToDto(created);
        }
        //------------------------------------------------------------------------------------

        public async Task<ViolationPaymentDto> CompletePaymentAsync(Guid id)
        {
            var payment = await _violationPaymentRepository.GetByIdAsync(id);
            var paymentIntent = await _stripeService.ConfirmPaymentIntentAsync(payment.StripePaymentIntentId);

            _logger.LogInformation("Payment status for payment {PaymentId}: {Status}", id, paymentIntent.Status);

            if (paymentIntent.Status == "succeeded")
            {
                payment.Status = ViolationPaymentStatus.Paid;
                payment.PaidAt = DateTime.UtcNow;

                _logger.LogInformation("Publishing violation payment completed for violation {ViolationId}", payment.ViolationId);


                await _publisher.PublishAsync(RabbitMQConstants.ViolationPaymentCompletedQueue, new ViolationPaymentCompletedMessage
                {
                    ViolationId = payment.ViolationId,
                    UserId = payment.UserId,
                    Amount = payment.Amount
                });
                await _publisher.PublishAsync(RabbitMQConstants.ViolationPaymentCompletedNotificationQueue, new ViolationPaymentCompletedMessage
                {
                    ViolationId = payment.ViolationId,
                    UserId = payment.UserId,
                    Amount = payment.Amount
                });


                _logger.LogInformation("Violation payment published successfully for violation {ViolationId}", payment.ViolationId);
            }
            else
            {
                _logger.LogWarning("Payment not succeeded for payment {PaymentId}, status: {Status}", id, paymentIntent.Status);

                payment.Status = ViolationPaymentStatus.Failed;
            }
            var updated = await _violationPaymentRepository.UpdateAsync(payment);
            return MapToDto(updated);
        }
        //------------------------------------------------------------------------------------

        public async Task<ViolationPaymentDto> FailPaymentAsync(Guid id)
        {
            var payment = await _violationPaymentRepository.GetByIdAsync(id);
            payment.Status = ViolationPaymentStatus.Failed;
            var updated = await _violationPaymentRepository.UpdateAsync(payment);
            return MapToDto(updated);
        }

        public async Task DeleteAsync(Guid id)
        {
            await _violationPaymentRepository.DeleteAsync(id);
        }
        //------------------------------------------------------------------------------------

        private ViolationPaymentDto MapToDto(ViolationPayment p) => new ViolationPaymentDto
        {
            Id = p.Id,
            UserId = p.UserId,
            ViolationId = p.ViolationId,
            Amount = p.Amount,
            StripeClientSecret = p.StripeClientSecret,
            StripePaymentIntentId = p.StripePaymentIntentId,
            Status = p.Status,
            CreatedAt=p.CreatedAt,
            PaidAt = p.PaidAt
        };
        //------------------------------------------------------------------------------------

    }
}
