namespace ParkingService.Application.DTOs.Requests
{
    public class CreateViolationConfigDto
    {
        public string TypeName { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal FineAmount { get; set; }
    }
}