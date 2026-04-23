namespace ParkingService.Application.DTOs.Requests
{
    public class UpdateViolationConfigDto
    {
        public string TypeName { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal FineAmount { get; set; }
    }
}