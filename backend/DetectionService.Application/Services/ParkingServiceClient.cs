using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using System.Net.Http;
using System.Text.Json;

namespace DetectionService.Infrastructure.Services
{
    public class ParkingServiceClient
    {
        private readonly HttpClient _httpClient;
        private readonly ILogger<ParkingServiceClient> _logger;
        private readonly IConfiguration _configuration;

        public ParkingServiceClient(HttpClient httpClient, ILogger<ParkingServiceClient> logger, IConfiguration configuration)
        {
            _httpClient = httpClient;
            _logger = logger;
            _configuration = configuration;
        }

        public async Task<string> GetLotNameAsync(Guid lotId)
        {
            try
            {
                var request = new HttpRequestMessage(HttpMethod.Get,
                    $"/parkingLot/ParkingLot/getById{lotId}");
                request.Headers.Add("X-Internal-Key", _configuration["InternalServices:ApiKey"]);
                var response = await _httpClient.SendAsync(request);
                if (!response.IsSuccessStatusCode) return string.Empty;
                var content = await response.Content.ReadAsStringAsync();
                var json = JsonDocument.Parse(content);
                return json.RootElement.GetProperty("name").GetString() ?? string.Empty;
            }
            catch
            {
                return string.Empty;
            }
        }

        public async Task<Guid?> GetUserIdByLicensePlateAsync(string licensePlate)
        {
            try
            {
                var response = await _httpClient.GetAsync($"/api/ParkingTicket/getByPlate?licensePlate={licensePlate}");
                if (!response.IsSuccessStatusCode) return null;
                var content = await response.Content.ReadAsStringAsync();
                var json = JsonDocument.Parse(content);
                return Guid.Parse(json.RootElement.GetProperty("userId").GetString()!);
            }
            catch
            {
                return null;
            }
        }

        public async Task<Guid?> GetViolationConfigIdByTypeNameAsync(string typeName)
        {
            try
            {
                var response = await _httpClient.GetAsync($"/api/ViolationConfig/getAll");
                if (!response.IsSuccessStatusCode) return null;
                var content = await response.Content.ReadAsStringAsync();
                var json = JsonDocument.Parse(content);
                var data = json.RootElement.GetProperty("data");
                foreach (var item in data.EnumerateArray())
                {
                    var name = item.GetProperty("typeName").GetString();
                    if (string.Equals(name, typeName, StringComparison.OrdinalIgnoreCase))
                    {
                        return Guid.Parse(item.GetProperty("id").GetString()!);
                    }
                }
                return null;
            }
            catch
            {
                return null;
            }
        }

        public async Task<Guid?> GetUserIdByLicensePlateFromVehicleAsync(string licensePlate)
        {
            try
            {
                var request = new HttpRequestMessage(HttpMethod.Get,
                    $"http://userservice:8080/api/vehicles/by-license/{licensePlate}");
                request.Headers.Add("X-Internal-Key", _configuration["InternalServices:ApiKey"]);
                var response = await _httpClient.SendAsync(request);
                if (!response.IsSuccessStatusCode) return null;
                var content = await response.Content.ReadAsStringAsync();
                var json = JsonDocument.Parse(content);
                return Guid.Parse(json.RootElement.GetProperty("owner").GetProperty("id").GetString()!);
            }
            catch
            {
                return null;
            }
        }
    }
}