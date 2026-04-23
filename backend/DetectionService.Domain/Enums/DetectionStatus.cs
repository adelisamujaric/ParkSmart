using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace DetectionService.Domain.Enums
{
    public enum DetectionStatus
    {
        PendingReview = 0,  // čeka admina (samo za Drone)
        Confirmed = 1,      // admin potvrdio
        Rejected = 2,       // admin odbio
        AutoProcessed = 3   // automatski obrađeno (Entry/Exit kamere)
    }
}
