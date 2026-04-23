using ReportingService.Application.DTOs;
using ReportingService.Application.DTOs.Responses;
using ReportingService.Domain.Interfaces;

namespace ReportingService.Application.Services
{
    public class ReportingAppService
    {
        private readonly IRevenueReportRepository _revenueRepo;
        private readonly IOccupancyReportRepository _occupancyRepo;
        private readonly IViolationsReportRepository _violationsRepo;

        public ReportingAppService(
            IRevenueReportRepository revenueRepo,
            IOccupancyReportRepository occupancyRepo,
            IViolationsReportRepository violationsRepo)
        {
            _revenueRepo = revenueRepo;
            _occupancyRepo = occupancyRepo;
            _violationsRepo = violationsRepo;
        }
        //---------------------------------------------------------------------------------------
        public async Task<RevenueReportDto> GetRevenueReportAsync(DateTime from, DateTime to)
        {
            var tickets = await _revenueRepo.GetPaidTicketsAsync(from, to);
            var reservations = await _revenueRepo.GetCompletedReservationsAsync(from, to);
            var violations = await _violationsRepo.GetViolationsAsync(from, to); 

            var ticketRevenue = tickets.Sum(t => t.TotalPrice ?? 0);
            var reservationRevenue = reservations.Sum(r => r.TotalPrice);
            var violationRevenue = violations.Sum(v => v.FineAmount);

            var allLots = await _occupancyRepo.GetParkingLotsWithSpotsAsync(); // ← sve aktivne zone iz baze

            var revenueByLot = allLots.Select(lot => new RevenueByLotDto
            {
                LotId = lot.Id,
                LotName = lot.Name,
                TicketRevenue = tickets
                 .Where(t => t.ParkingSpot.LotId == lot.Id)
                 .Sum(t => t.TotalPrice ?? 0),
                        ReservationRevenue = reservations
                 .Where(r => r.ParkingSpot.LotId == lot.Id)
                 .Sum(r => r.TotalPrice),
                        ViolationRevenue = violations  
                 .Where(v => v.LotId == lot.Id)
                 .Sum(v => v.FineAmount),
                        TotalRevenue = tickets
                 .Where(t => t.ParkingSpot.LotId == lot.Id)
                 .Sum(t => t.TotalPrice ?? 0) +
                 reservations
                 .Where(r => r.ParkingSpot.LotId == lot.Id)
                 .Sum(r => r.TotalPrice) +
                 violations
                 .Where(v => v.LotId == lot.Id)
                 .Sum(v => v.FineAmount)
                    }).ToList();

            var allDates = tickets.Select(t => t.ExitTime!.Value.Date)
                .Union(reservations.Select(r => r.EndTime.Date))
                .Union(violations.Select(v => v.CreatedAt.Date)) 
                .Distinct()
                .OrderBy(d => d)
                .ToList();

            var revenueByDay = allDates.Select(date => new RevenueByDayDto
            {
                Date = date,
                TicketRevenue = tickets
                    .Where(t => t.ExitTime!.Value.Date == date)
                    .Sum(t => t.TotalPrice ?? 0),
                ReservationRevenue = reservations
                    .Where(r => r.EndTime.Date == date)
                    .Sum(r => r.TotalPrice),
                ViolationRevenue = violations  
                    .Where(v => v.CreatedAt.Date == date)
                    .Sum(v => v.FineAmount),
                TotalRevenue = tickets
                    .Where(t => t.ExitTime!.Value.Date == date)
                    .Sum(t => t.TotalPrice ?? 0) +
                    reservations
                    .Where(r => r.EndTime.Date == date)
                    .Sum(r => r.TotalPrice) +
                    violations  
                    .Where(v => v.CreatedAt.Date == date)
                    .Sum(v => v.FineAmount)
            }).ToList();

            return new RevenueReportDto
            {
                TotalRevenue = ticketRevenue + reservationRevenue + violationRevenue, 
                TicketRevenue = ticketRevenue,
                ReservationRevenue = reservationRevenue,
                ViolationRevenue = violationRevenue, 
                RevenueByLot = revenueByLot,
                RevenueByDay = revenueByDay
            };
        }
        //---------------------------------------------------------------------------------------

        public async Task<OccupancyReportDto> GetOccupancyReportAsync(DateTime from, DateTime to)
        {
            var tickets = await _occupancyRepo.GetActiveTicketsByHourAsync(from, to);
            var lots = await _occupancyRepo.GetParkingLotsWithSpotsAsync();

            var totalSpots = lots.Sum(l => l.ParkingSpots.Count);

            var occupancyByHour = Enumerable.Range(0, 24).Select(hour => {
                var activeCount = tickets.Count(t =>
                    t.EntryTime.Hour <= hour &&
                    (t.ExitTime == null || t.ExitTime.Value.Hour >= hour));

                return new OccupancyByHourDto
                {
                    Hour = hour,
                    ActiveTickets = activeCount,
                    OccupancyRate = totalSpots > 0
                        ? Math.Round((double)activeCount / totalSpots * 100, 2)
                        : 0
                };
            }).ToList();

            var occupancyByLot = lots.Select(lot => {
                var lotTickets = tickets.Where(t => t.ParkingSpot.LotId == lot.Id).ToList();
                var spotCount = lot.ParkingSpots.Count;
                var avgOccupancy = spotCount > 0
                    ? Math.Round((double)lotTickets.Count / spotCount * 100, 2)
                    : 0;

                return new OccupancyByLotDto
                {
                    LotId = lot.Id,
                    LotName = lot.Name,
                    TotalSpots = spotCount,
                    AverageOccupancyRate = avgOccupancy
                };
            }).ToList();

            return new OccupancyReportDto
            {
                AverageOccupancyRate = occupancyByHour.Average(h => h.OccupancyRate),
                OccupancyByHour = occupancyByHour,
                OccupancyByLot = occupancyByLot
            };
        }
        //---------------------------------------------------------------------------------------

        public async Task<ViolationsReportDto> GetViolationsReportAsync(DateTime from, DateTime to)
        {
            var violations = await _violationsRepo.GetViolationsAsync(from, to);

            var violationsByType = violations
                .GroupBy(v => v.ViolationConfig!.TypeName)
                .Select(g => new ViolationsByTypeDto
                {
                    ViolationType = g.Key.ToString(),
                    Count = g.Count(),
                    TotalFineAmount = g.Sum(v => v.FineAmount)
                }).ToList();

            var violationsByDay = violations
                .GroupBy(v => v.CreatedAt.Date)
                .OrderBy(g => g.Key)
                .Select(g => new ViolationsByDayDto
                {
                    Date = g.Key,
                    Count = g.Count(),
                    TotalFineAmount = g.Sum(v => v.FineAmount)
                }).ToList();

            return new ViolationsReportDto
            {
                TotalViolations = violations.Count,
                TotalFinesAmount = violations.Sum(v => v.FineAmount),
                CollectedFinesAmount = violations
                    .Where(v => v.IsResolved)
                    .Sum(v => v.FineAmount),
                ViolationsByType = violationsByType,
                ViolationsByDay = violationsByDay
            };
        }
        //---------------------------------------------------------------------------------------

    }
}