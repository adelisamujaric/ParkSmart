using ReportingService.Domain.Entities;

namespace ReportingService.Domain.Interfaces
{
    public interface IRevenueReportRepository
    {
        Task<List<Ticket>> GetPaidTicketsAsync(DateTime from, DateTime to);
        Task<List<Reservation>> GetCompletedReservationsAsync(DateTime from, DateTime to);
    }
    //-------------------------------------------------------------------------------------

    public interface IOccupancyReportRepository
    {
        Task<List<Ticket>> GetActiveTicketsByHourAsync(DateTime from, DateTime to);
        Task<List<ParkingLot>> GetParkingLotsWithSpotsAsync();
    }
    //-------------------------------------------------------------------------------------

    public interface IViolationsReportRepository
    {
        Task<List<Violation>> GetViolationsAsync(DateTime from, DateTime to);
    }
    //-------------------------------------------------------------------------------------

}