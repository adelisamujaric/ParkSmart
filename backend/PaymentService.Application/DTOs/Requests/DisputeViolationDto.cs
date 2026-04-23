using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PaymentService.Application.DTOs.Requests
{
    public class DisputeViolationDto
    {
        public string DisputeReason { get; set; } = string.Empty;
    }
}
