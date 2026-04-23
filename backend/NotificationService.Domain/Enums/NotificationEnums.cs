using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace NotificationService.Domain.Enums;

    public enum NotificationType
    {
        Email,
        InApp,
        Push
    }
    public enum NotificationStatus
    {
        Pending,
        Sent,
        Failed,
        Read
    }


