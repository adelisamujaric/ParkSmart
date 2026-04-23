using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using UserService.Services.DTOs.Requests;
using UserService.Services.DTOs.Responses;
using UserService.Services.Services;

namespace UserService.WebAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [AllowAnonymous]
    public class AuthController : ControllerBase
    {
        private readonly AuthService _authAppService;

        public AuthController(AuthService authAppService) {
            _authAppService = authAppService;
        }

        //--------------------------------------------------------------

        [HttpPost("register")]
        public async Task<ActionResult<AuthResponse>> Register([FromBody] RegisterRequest request)
        {
            var response = await _authAppService.Register(request);
            return Ok(response);
        }
        //--------------------------------------------------------------

        [HttpPost("login")]
        public async Task<ActionResult<AuthResponse>> Login([FromBody] LoginRequest request)
        {
            var response = await _authAppService.Login(request);
            return Ok(response);
        }
        //--------------------------------------------------------------
        [HttpGet("verify-email")]
        public async Task<IActionResult> VerifyEmail([FromQuery] string token)
        {
            await _authAppService.VerifyEmailAsync(token);
            return Content(@"
        <html>
        <body style='font-family:Arial; text-align:center; margin-top:100px;'>
            <h2 style='color:#1A5276;'>Email uspjesno potvrdjen!</h2>
            <p>Mozete zatvoriti ovu stranicu i prijaviti se u aplikaciju.</p>
        </body>
        </html>", "text/html");
        }
        //--------------------------------------------------------------
        [HttpGet("verify-status")]
        public async Task<IActionResult> CheckVerifyStatus([FromQuery] string email)
        {
            var isVerified = await _authAppService.IsEmailVerifiedAsync(email);
            return Ok(new { isEmailVerified = isVerified });
        }
        //--------------------------------------------------------------
        [HttpPost("forgot-password")]
        public async Task<IActionResult> ForgotPassword([FromBody] ForgotPasswordRequest request)
        {
            await _authAppService.ForgotPasswordAsync(request.Email);
            return Ok(new { message = "Password reset email sent." });
        }

        [HttpPost("reset-password")]
        public async Task<IActionResult> ResetPassword([FromBody] ResetPasswordRequest request)
        {
            await _authAppService.ResetPasswordAsync(request.Token, request.NewPassword);
            return Ok(new { message = "Password successfully reset." });
        }


    }
}
