using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ReportingService.Application.DTOs.Responses
{
    
        public class ViolationsReportDto
        {
            public int TotalViolations { get; set; }
            public decimal TotalFinesAmount { get; set; }
            public decimal CollectedFinesAmount { get; set; }
            public List<ViolationsByTypeDto> ViolationsByType { get; set; } = new();
            public List<ViolationsByDayDto> ViolationsByDay { get; set; } = new();
        }

        public class ViolationsByTypeDto
        {
            public string ViolationType { get; set; } = string.Empty;
            public int Count { get; set; }
            public decimal TotalFineAmount { get; set; }
        }

        public class ViolationsByDayDto
        {
            public DateTime Date { get; set; }
            public int Count { get; set; }
            public decimal TotalFineAmount { get; set; }
        }
    
}
