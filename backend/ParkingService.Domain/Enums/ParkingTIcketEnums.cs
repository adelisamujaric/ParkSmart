using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ParkingService.Domain.Enums
{
    public enum TicketStatus
    {
        Active = 0,
        PendingPayment = 1,
        Paid = 2,
       // Disputed = 3,
        Closed = 4
    }
}
