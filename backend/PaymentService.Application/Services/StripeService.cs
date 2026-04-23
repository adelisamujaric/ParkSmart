using Stripe;
using Microsoft.Extensions.Configuration;

namespace PaymentService.Application.Services
{
    public class StripeService
    {
        public StripeService(IConfiguration configuration)
        {
            StripeConfiguration.ApiKey = configuration["StripeSettings:SecretKey"];
        }
        //------------------------------------------------------------------------------------

        public async Task<PaymentIntent> CreatePaymentIntentAsync(decimal amount, string currency = "eur")
        {
            var amountInCents = (long)(amount * 100);

            // Stripe minimum je 50 centi
            if (amountInCents < 50) amountInCents = 50;

            var options = new PaymentIntentCreateOptions
            {
                Amount = amountInCents,
                Currency = currency,
                AutomaticPaymentMethods = new PaymentIntentAutomaticPaymentMethodsOptions
                {
                    Enabled = true
                }
            };
            var service = new PaymentIntentService();
            return await service.CreateAsync(options);
        }
        //------------------------------------------------------------------------------------

        public async Task<PaymentIntent> ConfirmPaymentIntentAsync(string paymentIntentId)
        {
            var service = new PaymentIntentService();
            return await service.GetAsync(paymentIntentId);
        }
        //------------------------------------------------------------------------------------

        public async Task<Refund> RefundPaymentAsync(string paymentIntentId)
        {
            var options = new RefundCreateOptions
            {
                PaymentIntent = paymentIntentId
            };

            var service = new RefundService();
            return await service.CreateAsync(options);
        }
        //------------------------------------------------------------------------------------

    }
}