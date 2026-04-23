using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System.Net;
using System.Net.Mail;

public class EmailService
{
    private readonly IConfiguration _configuration;
    private readonly ILogger<EmailService> _logger;

    public EmailService(IConfiguration configuration, ILogger<EmailService> logger)
    {
        _configuration = configuration;
        _logger = logger;
    }

    private SmtpClient CreateSmtpClient()
    {
        return new SmtpClient("smtp.gmail.com")
        {
            Port = 587,
            Credentials = new NetworkCredential(
                _configuration["EmailSettings:From"],
                _configuration["EmailSettings:Password"]
            ),
            EnableSsl = true
        };
    }

    public async Task SendVerificationEmailAsync(string toEmail, string firstName, string token)
    {
        try
        {
            var verificationUrl = $"{_configuration["AppSettings:BaseUrl"]}/api/auth/verify-email?token={token}";

            using var smtpClient = CreateSmtpClient();
            var mailMessage = new MailMessage
            {
                From = new MailAddress(_configuration["EmailSettings:From"]!, "ParkSmart"),
                Subject = "Potvrdite vaš ParkSmart račun",
                Body = $"<p>Pozdrav {firstName},</p><p>Kliknite <a href='{verificationUrl}'>ovdje</a> da potvrdite vaš račun.</p><p>Link vrijedi 24 sata.</p>",
                IsBodyHtml = true
            };
            mailMessage.To.Add(toEmail);
            await smtpClient.SendMailAsync(mailMessage);
            _logger.LogInformation("Verification email sent to {Email}", toEmail);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending verification email to {Email}", toEmail);
            throw;
        }
    }

    
    public async Task SendPasswordResetEmailAsync(string toEmail, string firstName, string token)
    {
        try
        {
            var resetUrl = $"{_configuration["AppSettings:BaseUrl"]}/api/auth/reset-password?token={token}";

            using var smtpClient = CreateSmtpClient();
            var mailMessage = new MailMessage
            {
                From = new MailAddress(_configuration["EmailSettings:From"]!, "ParkSmart"),
                Subject = "Reset lozinke - ParkSmart",
                Body = $@"<p>Pozdrav {firstName},</p>
                         <p>Primili smo zahtjev za reset vaše lozinke.</p>
                         <p>Vaš reset kod je: <strong>{token}</strong></p>
                         <p>Unesite ovaj kod u aplikaciji da resetujete lozinku.</p>
                         <p>Kod vrijedi 1 sat.</p>
                         <p>Ako niste tražili reset lozinke, ignorišite ovaj email.</p>",
                IsBodyHtml = true
            };
            mailMessage.To.Add(toEmail);
            await smtpClient.SendMailAsync(mailMessage);
            _logger.LogInformation("Password reset email sent to {Email}", toEmail);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Error sending password reset email to {Email}", toEmail);
            throw;
        }
    }
}