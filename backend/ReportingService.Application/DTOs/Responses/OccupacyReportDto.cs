using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ReportingService.Application.DTOs.Responses
{
  
        
        public class OccupancyReportDto
        {
            public double AverageOccupancyRate { get; set; }
            public List<OccupancyByHourDto> OccupancyByHour { get; set; } = new();
            public List<OccupancyByLotDto> OccupancyByLot { get; set; } = new();
        }

        public class OccupancyByHourDto
        {
            public int Hour { get; set; }
            public double OccupancyRate { get; set; }
            public int ActiveTickets { get; set; }
        }

        public class OccupancyByLotDto
        {
            public Guid LotId { get; set; }
            public string LotName { get; set; } = string.Empty;
            public int TotalSpots { get; set; }
            public double AverageOccupancyRate { get; set; }
        }
    
}

