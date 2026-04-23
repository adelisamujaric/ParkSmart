using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace ReportingService.Domain.Enums
{
   
        public enum ParkingLotType { Open = 0, Closed = 1 }
        public enum TicketStatus { Active = 0, PendingPayment = 1, Paid = 2, Disputed = 3, Closed = 4 }
        public enum ReservationStatus { Pending = 0, Confirmed = 1, Completed = 2, Cancelled = 3, Expired = 4 }
       
}
