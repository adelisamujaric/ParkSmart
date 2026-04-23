using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System.Net.Http;
using System.Text.Json;

namespace ParkingService.Infrastructure.Services
{
    public class UserServiceClient
    {
        private readonly HttpClient _httpClient;
        private readonly ILogger<UserServiceClient> _logger;
        private readonly IConfiguration _configuration;


        public UserServiceClient(HttpClient httpClient, ILogger<UserServiceClient> logger, IConfiguration configuration)
        {
            _httpClient = httpClient;
            _logger = logger;
            _configuration = configuration;
        }

        public async Task<Guid?> GetUserIdByLicensePlateAsync(string licensePlate)
        {
            try
            {
                var request = new HttpRequestMessage(HttpMethod.Get, $"/api/vehicles/by-license/{licensePlate}");
                request.Headers.Add("X-Internal-Key", _configuration["InternalServices:ApiKey"]);
                var response = await _httpClient.SendAsync(request);
                if (!response.IsSuccessStatusCode) return null;
                var content = await response.Content.ReadAsStringAsync();
                var json = JsonDocument.Parse(content);
                return Guid.Parse(json.RootElement.GetProperty("owner").GetProperty("id").GetString()!);
            }
            catch (Exception ex)
            {
                _logger.LogError(ex, "Failed to get userId for license plate {LicensePlate}", licensePlate);
                return null;
            }
        }
    }
}