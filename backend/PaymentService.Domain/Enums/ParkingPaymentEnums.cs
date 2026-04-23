using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace PaymentService.Domain.Enums
{
   
        public enum PaymentStatus
        {
            Pending,
            Paid,
            Failed,
            Refunded
        }

        public enum PaymentMethod
        {
            CreditCard,
            DebitCard
        }
    
}
