using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using ReportingService.Application.DTOs;
using ReportingService.Application.DTOs.Responses;
using System.Reflection.Metadata;
using Document = QuestPDF.Fluent.Document;

namespace ReportingService.Application.Services
{
    public class PdfReportService
    {
        public byte[] GenerateRevenueReport(RevenueReportDto report, DateTime from, DateTime to)
        {
            QuestPDF.Settings.License = LicenseType.Community;

            return Document.Create(container =>
            {
                container.Page(page =>
                {
                    page.Size(PageSizes.A4);
                    page.Margin(2, Unit.Centimetre);
                    page.DefaultTextStyle(x => x.FontSize(11));

                    page.Header().Column(col =>
                    {
                        col.Item().Text("ParkSmart")
                            .FontSize(20).Bold().FontColor(Colors.Blue.Darken2);
                        col.Item().Text($"Revenue Report: {from:dd.MM.yyyy} - {to:dd.MM.yyyy}")
                            .FontSize(13).FontColor(Colors.Grey.Darken2);
                        col.Item().PaddingTop(5).LineHorizontal(1).LineColor(Colors.Grey.Lighten2);
                    });

                    page.Content().PaddingTop(20).Column(col =>
                    {
                        // Summary
                        col.Item().Background(Colors.Blue.Lighten4).Padding(10).Column(summary =>
                        {
                            summary.Item().Text("Summary").Bold().FontSize(13);
                            summary.Item().Text($"Total Revenue: {report.TotalRevenue:C}");
                            summary.Item().Text($"Ticket Revenue: {report.TicketRevenue:C}");
                            summary.Item().Text($"Reservation Revenue: {report.ReservationRevenue:C}");
                            summary.Item().Text($"Violation Revenue: {report.ViolationRevenue:C}");
                        });

                        col.Item().PaddingTop(20).Text("Revenue by Parking Lot").Bold().FontSize(13);
                        col.Item().PaddingTop(5).Table(table =>
                        {
                            table.ColumnsDefinition(cols =>
                            {
                                cols.RelativeColumn(3);
                                cols.RelativeColumn(2);
                                cols.RelativeColumn(2);
                                cols.RelativeColumn(2);
                                cols.RelativeColumn(2);
                            });

                            table.Header(header =>
                            {
                                header.Cell().Background(Colors.Blue.Darken2)
                                    .Padding(5).Text("Lot Name").FontColor(Colors.White).Bold();
                                header.Cell().Background(Colors.Blue.Darken2)
                                    .Padding(5).Text("Ticket Revenue").FontColor(Colors.White).Bold();
                                header.Cell().Background(Colors.Blue.Darken2)
                                    .Padding(5).Text("Reservation Revenue").FontColor(Colors.White).Bold();
                                header.Cell().Background(Colors.Blue.Darken2)
                                   .Padding(5).Text("Violation Revenue").FontColor(Colors.White).Bold();
                                header.Cell().Background(Colors.Blue.Darken2)
                                    .Padding(5).Text("Total").FontColor(Colors.White).Bold();
                            });

                            foreach (var lot in report.RevenueByLot)
                            {
                                table.Cell().Padding(5).Text(lot.LotName);
                                table.Cell().Padding(5).Text($"{lot.TicketRevenue:C}");
                                table.Cell().Padding(5).Text($"{lot.ReservationRevenue:C}");
                                table.Cell().Padding(5).Text($"{lot.ViolationRevenue:C}");
                                table.Cell().Padding(5).Text($"{lot.TotalRevenue:C}").Bold();
                            }
                        });

                        col.Item().PaddingTop(20).Text("Revenue by Day").Bold().FontSize(13);
                        col.Item().PaddingTop(5).Table(table =>
                        {
                            table.ColumnsDefinition(cols =>
                            {
                                cols.RelativeColumn(2);
                                cols.RelativeColumn(2);
                                cols.RelativeColumn(2);
                                cols.RelativeColumn(2);
                                cols.RelativeColumn(2);
                            });

                            table.Header(header =>
                            {
                                header.Cell().Background(Colors.Blue.Darken2)
                                    .Padding(5).Text("Date").FontColor(Colors.White).Bold();
                                header.Cell().Background(Colors.Blue.Darken2)
                                    .Padding(5).Text("Ticket Revenue").FontColor(Colors.White).Bold();
                                header.Cell().Background(Colors.Blue.Darken2)
                                    .Padding(5).Text("Reservation Revenue").FontColor(Colors.White).Bold();
                                header.Cell().Background(Colors.Blue.Darken2)
                                   .Padding(5).Text("Violations Revenue").FontColor(Colors.White).Bold();
                                header.Cell().Background(Colors.Blue.Darken2)
                                    .Padding(5).Text("Total").FontColor(Colors.White).Bold();
                            });

                            foreach (var day in report.RevenueByDay)
                            {
                                table.Cell().Padding(5).Text(day.Date.ToString("dd.MM.yyyy"));
                                table.Cell().Padding(5).Text($"{day.TicketRevenue:C}");
                                table.Cell().Padding(5).Text($"{day.ReservationRevenue:C}");
                                table.Cell().Padding(5).Text($"{day.ViolationRevenue:C}");
                                table.Cell().Padding(5).Text($"{day.TotalRevenue:C}").Bold();
                            }
                        });
                    });

                    page.Footer().AlignCenter().Text(text =>
                    {
                        text.Span("Generated by ParkSmart | ");
                        text.Span(DateTime.UtcNow.ToString("dd.MM.yyyy HH:mm"));
                    });
                });
            }).GeneratePdf();
        }



        public byte[] GenerateOccupancyReport(OccupancyReportDto report, DateTime from, DateTime to)
        {
            QuestPDF.Settings.License = LicenseType.Community;

            return Document.Create(container =>
            {
                container.Page(page =>
                {
                    page.Size(PageSizes.A4);
                    page.Margin(2, Unit.Centimetre);
                    page.DefaultTextStyle(x => x.FontSize(11));

                    page.Header().Column(col =>
                    {
                        col.Item().Text("ParkSmart")
                            .FontSize(20).Bold().FontColor(Colors.Blue.Darken2);
                        col.Item().Text($"Occupancy Report: {from:dd.MM.yyyy} - {to:dd.MM.yyyy}")
                            .FontSize(13).FontColor(Colors.Grey.Darken2);
                        col.Item().PaddingTop(5).LineHorizontal(1).LineColor(Colors.Grey.Lighten2);
                    });

                    page.Content().PaddingTop(20).Column(col =>
                    {
                        col.Item().Background(Colors.Blue.Lighten4).Padding(10).Column(summary =>
                        {
                            summary.Item().Text("Summary").Bold().FontSize(13);
                            summary.Item().Text($"Average Occupancy Rate: {report.AverageOccupancyRate:F2}%");
                        });

                        col.Item().PaddingTop(20).Text("Occupancy by Hour").Bold().FontSize(13);
                        col.Item().PaddingTop(5).Table(table =>
                        {
                            table.ColumnsDefinition(cols =>
                            {
                                cols.RelativeColumn(2);
                                cols.RelativeColumn(3);
                                cols.RelativeColumn(3);
                            });

                            table.Header(header =>
                            {
                                header.Cell().Background(Colors.Blue.Darken2)
                                    .Padding(5).Text("Hour").FontColor(Colors.White).Bold();
                                header.Cell().Background(Colors.Blue.Darken2)
                                    .Padding(5).Text("Active Tickets").FontColor(Colors.White).Bold();
                                header.Cell().Background(Colors.Blue.Darken2)
                                    .Padding(5).Text("Occupancy Rate").FontColor(Colors.White).Bold();
                            });

                            foreach (var hour in report.OccupancyByHour)
                            {
                                table.Cell().Padding(5).Text($"{hour.Hour:D2}:00");
                                table.Cell().Padding(5).Text(hour.ActiveTickets.ToString());
                                table.Cell().Padding(5).Text($"{hour.OccupancyRate:F2}%");
                            }
                        });

                        col.Item().PaddingTop(20).Text("Occupancy by Lot").Bold().FontSize(13);
                        col.Item().PaddingTop(5).Table(table =>
                        {
                            table.ColumnsDefinition(cols =>
                            {
                                cols.RelativeColumn(3);
                                cols.RelativeColumn(2);
                                cols.RelativeColumn(3);
                            });

                            table.Header(header =>
                            {
                                header.Cell().Background(Colors.Blue.Darken2)
                                    .Padding(5).Text("Lot Name").FontColor(Colors.White).Bold();
                                header.Cell().Background(Colors.Blue.Darken2)
                                    .Padding(5).Text("Total Spots").FontColor(Colors.White).Bold();
                                header.Cell().Background(Colors.Blue.Darken2)
                                    .Padding(5).Text("Avg Occupancy Rate").FontColor(Colors.White).Bold();
                            });

                            foreach (var lot in report.OccupancyByLot)
                            {
                                table.Cell().Padding(5).Text(lot.LotName);
                                table.Cell().Padding(5).Text(lot.TotalSpots.ToString());
                                table.Cell().Padding(5).Text($"{lot.AverageOccupancyRate:F2}%");
                            }
                        });
                    });

                    page.Footer().AlignCenter().Text(text =>
                    {
                        text.Span("Generated by ParkSmart | ");
                        text.Span(DateTime.UtcNow.ToString("dd.MM.yyyy HH:mm"));
                    });
                });
            }).GeneratePdf();
        }

        public byte[] GenerateViolationsReport(ViolationsReportDto report, DateTime from, DateTime to)
        {
            QuestPDF.Settings.License = LicenseType.Community;

            return Document.Create(container =>
            {
                container.Page(page =>
                {
                    page.Size(PageSizes.A4);
                    page.Margin(2, Unit.Centimetre);
                    page.DefaultTextStyle(x => x.FontSize(11));

                    page.Header().Column(col =>
                    {
                        col.Item().Text("ParkSmart")
                            .FontSize(20).Bold().FontColor(Colors.Blue.Darken2);
                        col.Item().Text($"Violations Report: {from:dd.MM.yyyy} - {to:dd.MM.yyyy}")
                            .FontSize(13).FontColor(Colors.Grey.Darken2);
                        col.Item().PaddingTop(5).LineHorizontal(1).LineColor(Colors.Grey.Lighten2);
                    });

                    page.Content().PaddingTop(20).Column(col =>
                    {
                        col.Item().Background(Colors.Blue.Lighten4).Padding(10).Column(summary =>
                        {
                            summary.Item().Text("Summary").Bold().FontSize(13);
                            summary.Item().Text($"Total Violations: {report.TotalViolations}");
                            summary.Item().Text($"Total Fines: {report.TotalFinesAmount:C}");
                            summary.Item().Text($"Collected Fines: {report.CollectedFinesAmount:C}");
                        });

                        col.Item().PaddingTop(20).Text("Violations by Type").Bold().FontSize(13);
                        col.Item().PaddingTop(5).Table(table =>
                        {
                            table.ColumnsDefinition(cols =>
                            {
                                cols.RelativeColumn(3);
                                cols.RelativeColumn(2);
                                cols.RelativeColumn(2);
                            });

                            table.Header(header =>
                            {
                                header.Cell().Background(Colors.Blue.Darken2)
                                    .Padding(5).Text("Violation Type").FontColor(Colors.White).Bold();
                                header.Cell().Background(Colors.Blue.Darken2)
                                    .Padding(5).Text("Count").FontColor(Colors.White).Bold();
                                header.Cell().Background(Colors.Blue.Darken2)
                                    .Padding(5).Text("Total Fines").FontColor(Colors.White).Bold();
                            });

                            foreach (var v in report.ViolationsByType)
                            {
                                table.Cell().Padding(5).Text(v.ViolationType);
                                table.Cell().Padding(5).Text(v.Count.ToString());
                                table.Cell().Padding(5).Text($"{v.TotalFineAmount:C}");
                            }
                        });

                        col.Item().PaddingTop(20).Text("Violations by Day").Bold().FontSize(13);
                        col.Item().PaddingTop(5).Table(table =>
                        {
                            table.ColumnsDefinition(cols =>
                            {
                                cols.RelativeColumn(2);
                                cols.RelativeColumn(2);
                                cols.RelativeColumn(2);
                            });

                            table.Header(header =>
                            {
                                header.Cell().Background(Colors.Blue.Darken2)
                                    .Padding(5).Text("Date").FontColor(Colors.White).Bold();
                                header.Cell().Background(Colors.Blue.Darken2)
                                    .Padding(5).Text("Count").FontColor(Colors.White).Bold();
                                header.Cell().Background(Colors.Blue.Darken2)
                                    .Padding(5).Text("Total Fines").FontColor(Colors.White).Bold();
                            });

                            foreach (var day in report.ViolationsByDay)
                            {
                                table.Cell().Padding(5).Text(day.Date.ToString("dd.MM.yyyy"));
                                table.Cell().Padding(5).Text(day.Count.ToString());
                                table.Cell().Padding(5).Text($"{day.TotalFineAmount:C}");
                            }
                        });
                    });

                    page.Footer().AlignCenter().Text(text =>
                    {
                        text.Span("Generated by ParkSmart | ");
                        text.Span(DateTime.UtcNow.ToString("dd.MM.yyyy HH:mm"));
                    });
                });
            }).GeneratePdf();
        }
    }
}