using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Shared.RabbitMQ
{
    public static class RabbitMQConstants

    {
        public const string DetectionUnknownQueue = "detection.unknown";

        //Tickets
        public const string VehicleEntryQueue = "vehicle.entry"; 
        public const string VehicleEntryNotificationQueue = "vehicle.entry.notification";
        public const string VehicleExitQueue = "vehicle.exit";
        public const string VehicleExitNotificationQueue = "vehicle.exit.notification";
        public const string TicketExpiringQueue = "ticket.expiring";
        public const string TicketClosedQueue = "ticket.closed";
        public const string PaymentCompletedQueue = "payment-completed";


        //Violations
        public const string ViolationCreatedQueue = "violation.created";
        public const string ViolationConfirmedQueue = "violation.confirmed";
        public const string ViolationConfirmedNotificationQueue = "violation.confirmed.notification";
        public const string ViolationPaymentCompletedQueue = "violation-payment-completed";
        public const string ViolationPaymentCompletedNotificationQueue = "violation-payment-completed-notification";


        //Reservations
        public const string ReservationExpiredQueue = "reservation.expired";
        public const string ReservationCreatedQueue = "reservation.created";
        public const string ReservationExpiringQueue = "reservation.expiring";
        public const string ReservationPaymentCompletedNotificationQueue = "reservation-payment-completed-notification";
    }
}
