namespace ParkingService.Application.DTOs.Responses
{
    public class ViolationConfigResponseDto
    {
        public Guid Id { get; set; }
        public string TypeName { get; set; } = string.Empty;
        public string Description { get; set; } = string.Empty;
        public decimal FineAmount { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime UpdatedAt { get; set; }
    }
}