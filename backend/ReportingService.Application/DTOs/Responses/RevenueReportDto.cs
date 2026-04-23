using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ReportingService.Application.DTOs.Responses
{
    public class RevenueReportDto
    {
        public decimal TotalRevenue { get; set; }
        public decimal TicketRevenue { get; set; }
        public decimal ReservationRevenue { get; set; }
        public decimal ViolationRevenue { get; set; }

        public List<RevenueByLotDto> RevenueByLot { get; set; } = new();
        public List<RevenueByDayDto> RevenueByDay { get; set; } = new();
    }

    public class RevenueByLotDto
    {
        public Guid LotId { get; set; }
        public string LotName { get; set; } = string.Empty;
        public decimal TotalRevenue { get; set; }
        public decimal TicketRevenue { get; set; }
        public decimal ReservationRevenue { get; set; }
        public decimal ViolationRevenue { get; set; }

    }

    public class RevenueByDayDto
    {
        public DateTime Date { get; set; }
        public decimal TotalRevenue { get; set; }
        public decimal TicketRevenue { get; set; }
        public decimal ReservationRevenue { get; set; }
        public decimal ViolationRevenue { get; set; }

    }
}
