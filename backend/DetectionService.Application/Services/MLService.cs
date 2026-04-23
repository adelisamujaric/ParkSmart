using Microsoft.Extensions.Configuration;
using System.Text;
using System.Text.Json;

namespace DetectionService.Application.Services
{
    public class MLService
    {
        private readonly HttpClient _httpClient;
        private readonly string _mlServiceUrl;

        public MLService(HttpClient httpClient, IConfiguration configuration)
        {
            _httpClient = httpClient;
            _mlServiceUrl = configuration["MLService:BaseUrl"] ?? "http://localhost:8000";
        }
        //------------------------------------------------------------------------------------------
      
        public async Task<(string? LicensePlate, string? ViolationType)> DetectLicensePlateAsync(string base64Image)
        {
            try
            {
                var payload = new { image = base64Image };
                var json = JsonSerializer.Serialize(payload);
                var content = new StringContent(json, Encoding.UTF8, "application/json");
                var response = await _httpClient.PostAsync($"{_mlServiceUrl}/detect", content);
                if (!response.IsSuccessStatusCode)
                    return (null, null);
                var responseJson = await response.Content.ReadAsStringAsync();
                var result = JsonSerializer.Deserialize<MLDetectionResult>(responseJson);
                return (result?.LicensePlate, result?.ViolationType);
            }
            catch
            {
                return (null, null);
            }
        }
        //------------------------------------------------------------------------------------------

    }

    public class MLDetectionResult
    {
        public string? LicensePlate { get; set; }
        public string? ViolationType { get; set; }
    }
    //------------------------------------------------------------------------------------------

}