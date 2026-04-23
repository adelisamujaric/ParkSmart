using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using Microsoft.IdentityModel.Tokens;
using Shared.Exceptions;
using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using UserService.Modules.Entities;
using UserService.Modules.Enums;
using UserService.Modules.Interfaces;
using UserService.Services.DTOs.Requests;
using UserService.Services.DTOs.Responses;

namespace UserService.Services.Services
{
    public class AuthService
    {
        private readonly IUserRepository _userRepository;
        private readonly IConfiguration _configuration;
        private readonly EmailService _emailService;
        private readonly ILogger<AuthService> _logger; 

        public AuthService(
            IUserRepository userRepository,
            IConfiguration configuration,
            EmailService emailService,
            ILogger<AuthService> logger) 
        {
            _userRepository = userRepository;
            _configuration = configuration;
            _emailService = emailService;
            _logger = logger; 
        }

        public async Task<AuthResponse> Register(RegisterRequest request)
        {
            try
            {
                var existingUser = await _userRepository.GetUserByEmail(request.Email);
                if (existingUser != null)
                    throw new BadRequestException("Email already exists");

                var passwordHash = BCrypt.Net.BCrypt.HashPassword(request.Password);

                var user = new User
                {
                    Id = Guid.NewGuid(),
                    FirstName = request.FirstName,
                    LastName = request.LastName,
                    Email = request.Email,
                    PasswordHash = passwordHash,
                    Role = UserRoles.User,
                    CreatedAt = DateTime.UtcNow,
                    IsActive = true
                };

                var createdUser = await _userRepository.CreateUser(user);

                var verificationToken = Guid.NewGuid().ToString();
                createdUser.EmailVerificationToken = verificationToken;
                createdUser.EmailVerificationTokenExpiry = DateTime.UtcNow.AddHours(24);
                createdUser.IsEmailVerified = false;
                await _userRepository.UpdateUser(createdUser);

                await _emailService.SendVerificationEmailAsync(createdUser.Email, createdUser.FirstName, verificationToken);

                _logger.LogInformation("User registered successfully: {Email}", request.Email);

                var token = GenerateJwtToken(createdUser);
                return new AuthResponse
                {
                    Token = token,
                    User = MapToUserResponse(createdUser)
                };
            }
            catch (Exception ex) when (ex is not BadRequestException)
            {
                _logger.LogError(ex, "Error registering user {Email}", request.Email);
                throw;
            }
        }

        public async Task<AuthResponse> Login(LoginRequest request)
        {
            try
            {
                var user = await _userRepository.GetUserByEmail(request.Email);
                if (user == null)
                    throw new NotFoundException("Invalid email or password");

                if (!user.IsActive)
                    throw new BadRequestException("Account is deactivated");

                bool isPasswordValid = BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash);
                if (!isPasswordValid)
                {
                    _logger.LogWarning("Failed login attempt for email {Email}", request.Email);
                    throw new UnauthorizedException("Invalid email or password");
                }

                _logger.LogInformation("User logged in successfully: {Email}", request.Email);

                var token = GenerateJwtToken(user);
                return new AuthResponse
                {
                    Token = token,
                    User = MapToUserResponse(user)
                };
            }
            catch (Exception ex) when (ex is not NotFoundException && ex is not BadRequestException && ex is not UnauthorizedException)
            {
                _logger.LogError(ex, "Error during login for {Email}", request.Email);
                throw;
            }
        }

        private string GenerateJwtToken(User user)
        {
            var key = new SymmetricSecurityKey(
                Encoding.UTF8.GetBytes(_configuration["JwtSettings:Key"])
            );
            var credentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
            var claims = new[]
            {
                new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
                new Claim(ClaimTypes.Email, user.Email),
                new Claim(ClaimTypes.Role, user.Role.ToString())
            };
            var token = new JwtSecurityToken(
                claims: claims,
                expires: DateTime.UtcNow.AddDays(1),
                signingCredentials: credentials
            );
            return new JwtSecurityTokenHandler().WriteToken(token);
        }

        public async Task VerifyEmailAsync(string token)
        {
            try
            {
                var user = await _userRepository.GetUserByVerificationToken(token);
                if (user == null)
                    throw new NotFoundException("Invalid token");

                if (user.EmailVerificationTokenExpiry < DateTime.UtcNow)
                    throw new BadRequestException("Token has expired");

                user.IsEmailVerified = true;
                user.EmailVerificationToken = null;
                user.EmailVerificationTokenExpiry = null;
                await _userRepository.UpdateUser(user);

                _logger.LogInformation("Email verified for user {UserId}", user.Id);
            }
            catch (Exception ex) when (ex is not NotFoundException && ex is not BadRequestException)
            {
                _logger.LogError(ex, "Error verifying email token");
                throw;
            }
        }

        public async Task<bool> IsEmailVerifiedAsync(string email)
        {
            var user = await _userRepository.GetUserByEmail(email);
            if (user == null)
                throw new NotFoundException("User not found");

            return user.IsEmailVerified;
        }

        public async Task ForgotPasswordAsync(string email)
        {
            try
            {
                var user = await _userRepository.GetUserByEmail(email);
                if (user == null)
                {
                    // Ne otkrivamo da li email postoji iz sigurnosnih razloga
                    _logger.LogInformation("Password reset requested for non-existent email {Email}", email);
                    return;
                }

                // Generiraj reset token
                var resetToken = Guid.NewGuid().ToString();
                user.PasswordResetToken = resetToken;
                user.PasswordResetTokenExpiry = DateTime.UtcNow.AddHours(1);
                await _userRepository.UpdateUser(user);

                // Pošalji email sa tokenom
                await _emailService.SendPasswordResetEmailAsync(user.Email, user.FirstName, resetToken);

                _logger.LogInformation("Password reset email sent for user {Email}", email);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Error sending password reset email for {Email}", email);
                throw;
            }
        }

        public async Task ResetPasswordAsync(string token, string newPassword)
        {
            try
            {
                var user = await _userRepository.GetUserByResetToken(token);
                if (user == null)
                    throw new NotFoundException("Invalid or expired reset token.");

                if (user.PasswordResetTokenExpiry < DateTime.UtcNow)
                    throw new BadRequestException("Reset token has expired.");

                if (string.IsNullOrWhiteSpace(newPassword) || newPassword.Length < 6)
                    throw new BadRequestException("Password must be at least 6 characters.");

                user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(newPassword);
                user.PasswordResetToken = null;
                user.PasswordResetTokenExpiry = null;
                await _userRepository.UpdateUser(user);

                _logger.LogInformation("Password reset successfully for user {UserId}", user.Id);
            }
            catch (Exception ex) when (ex is not NotFoundException && ex is not BadRequestException)
            {
                _logger.LogError(ex, "Error resetting password for token {Token}", token);
                throw;
            }
        }

        private UserResponse MapToUserResponse(User user)
        {
            return new UserResponse
            {
                Id = user.Id,
                FirstName = user.FirstName,
                LastName = user.LastName,
                Email = user.Email,
                PhoneNumber = user.PhoneNumber,
                Address = user.Address,
                City = user.City,
                PostalCode = user.PostalCode,
                Country = user.Country,
                Role = user.Role,
                CreatedAt = user.CreatedAt,
                IsActive = user.IsActive
            };
        }
    }
}