import 'package:flutter/material.dart';
import '../../detections/services/detection_service.dart';
import '../../parking/services/parking_lot_service.dart';
import '../../reporting/services/reporting_service.dart';
import '../../reporting/models/occupancy_report.dart';
import '../../reporting/models/violations_report.dart';
import '../../reporting/models/revenue_report.dart';

String _shortLabel(String type) {
  final words = type.split(' ').where((w) => w.length > 2).toList();
  if (words.length >= 2) {
    return words.map((w) => w[0].toUpperCase()).take(3).join();
  }
  return type.substring(0, type.length > 3 ? 3 : type.length).toUpperCase();
}


class DashboardContent extends StatefulWidget {
  const DashboardContent({super.key});

  @override
  State<DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends State<DashboardContent> {
  final _detectionService = DetectionService();
  final _parkingLotService = ParkingLotService();
  final _reportingService = ReportingService();

  int _activeDrones = 0;
  int _pendingAlerts = 0;
  int _occupiedSpots = 0;
  int _availableSpots = 0;

  OccupancyReportDto? _occupancyReport;
  ViolationsReportDto? _violationsReport;
  RevenueReportDto? _revenueReport;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = now;

    await Future.wait([
      _loadCardStats(),
      _loadOccupancy(todayStart, todayEnd),
      _loadViolations(todayStart, todayEnd),
      _loadRevenue(todayStart, todayEnd),
    ]);

    setState(() => _isLoading = false);
  }

  Future<void> _loadCardStats() async {
    try {
      final drones = await _detectionService.getDrones();
      final logs = await _detectionService.getAllLogs();
      final lots = await _parkingLotService.getAll();
      final tickets = await _parkingLotService.getAllTickets();

      final totalSpots = lots.fold<int>(0, (sum, lot) => sum + lot.totalSpots);
      final occupiedCount = tickets
          .where((t) => t.exitTime == null && t.status.toLowerCase() == 'active')
          .length;

      setState(() {
        _activeDrones = drones.where((d) => d.status.toLowerCase() == 'active').length;
        _pendingAlerts = logs.where((l) => l.status.toLowerCase() == 'pendingreview').length;
        _occupiedSpots = occupiedCount;
        _availableSpots = totalSpots - occupiedCount;
      });
    } catch (_) {}
  }

  Future<void> _loadOccupancy(DateTime from, DateTime to) async {
    try {
      final report = await _reportingService.getOccupancyReport(from, to);
      setState(() => _occupancyReport = report);
    } catch (_) {}
  }

  Future<void> _loadViolations(DateTime from, DateTime to) async {
    try {
      final report = await _reportingService.getViolationsReport(from, to);
      setState(() => _violationsReport = report);
    } catch (_) {}
  }

  Future<void> _loadRevenue(DateTime from, DateTime to) async {
    try {
      final report = await _reportingService.getRevenueReport(from, to);
      setState(() => _revenueReport = report);
    } catch (_) {}
  }


  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stat kartice
          Row(
            children: [
              _StatCard(
                title: 'Occupied Spaces',
                value: '$_occupiedSpots/${_occupiedSpots + _availableSpots}',
                icon: Icons.directions_car,
                color: const Color(0xFF2E86C1),
              ),
              const SizedBox(width: 16),
              _StatCard(
                title: 'Available Spaces',
                value: '$_availableSpots',
                icon: Icons.local_parking,
                color: const Color(0xFF17A589),
              ),
              const SizedBox(width: 16),
              _StatCard(
                title: 'Active Drones',
                value: '$_activeDrones',
                icon: Icons.airplanemode_active,
                color: const Color(0xFF1ABC9C),
              ),
              const SizedBox(width: 16),
              _StatCard(
                title: 'Active Alerts',
                value: '$_pendingAlerts',
                icon: Icons.warning_amber,
                color: const Color(0xFFE74C3C),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Grafovi
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _ChartCard(
                  title: 'Zauzetost parkinga tokom dana (danas)',
                  child: _occupancyReport != null
                      ? _OccupancyLineChart(report: _occupancyReport!)
                      : const Center(child: Text('Nema podataka')),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  children: [
                    _ChartCard(
                      title: 'Broj prekršaja po tipu (danas)',
                      child: _violationsReport != null
                          ? _ViolationsBarChart(report: _violationsReport!)
                          : const Center(child: Text('Nema podataka')),
                    ),
                    const SizedBox(height: 8),

                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: _violationsReport != null && _violationsReport!.violationsByType.isNotEmpty
                          ? Wrap(
                        spacing: 12,
                        runSpacing: 6,
                        children: _violationsReport!.violationsByType.map((v) {
                          final label = _shortLabel(v.violationType);
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE74C3C).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  label,
                                  style: const TextStyle(
                                    color: Color(0xFFE74C3C),
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(v.violationType,
                                  style: const TextStyle(color: Colors.grey, fontSize: 11)),
                            ],
                          );
                        }).toList(),
                      )
                          : const Text('Nema prekršaja danas',
                          style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ),



                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Dnevna zarada + Smart Insights
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _EarningsCard(report: _revenueReport, violationsReport: _violationsReport, ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _InsightsCard(
                  occupancyReport: _occupancyReport,
                  violationsReport: _violationsReport,
                  activeDrones: _activeDrones,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---- Stat kartica ----
class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 36),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---- Chart kartica ----
class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          SizedBox(height: 200, child: child),
        ],
      ),
    );
  }
}

// ---- Occupancy line chart ----
class _OccupancyLineChart extends StatelessWidget {
  final OccupancyReportDto report;
  const _OccupancyLineChart({required this.report});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OccupancyLinePainter(report.occupancyByHour),
      child: Container(),
    );
  }
}

class _OccupancyLinePainter extends CustomPainter {
  final List<OccupancyByHourDto> data;
  _OccupancyLinePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFF2E86C1)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = const Color(0xFF2E86C1).withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final filtered = data.where((d) => d.hour >= 6 && d.hour <= 22).toList();
    if (filtered.isEmpty) return;

    final maxRate = filtered.map((d) => d.occupancyRate).reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxRate > 0 ? maxRate : 100;

    final points = List.generate(filtered.length, (i) {
      final x = size.width * i / (filtered.length - 1);
      final y = size.height * 0.85 * (1 - filtered[i].occupancyRate / effectiveMax);
      return Offset(x, y);
    });

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var p in points.skip(1)) {
      path.lineTo(p.dx, p.dy);
    }

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < filtered.length; i += 4) {
      textPainter.text = TextSpan(
        text: '${filtered[i].hour}h',
        style: const TextStyle(color: Colors.grey, fontSize: 11),
      );
      textPainter.layout();
      final x = size.width * i / (filtered.length - 1);
      textPainter.paint(canvas, Offset(x, size.height - 16));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---- Violations bar chart ----
class _ViolationsBarChart extends StatelessWidget {
  final ViolationsReportDto report;
  const _ViolationsBarChart({required this.report});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ViolationsBarPainter(report.violationsByType),
      child: Container(),
    );
  }
}

class _ViolationsBarPainter extends CustomPainter {
  final List<ViolationsByTypeDto> data;
  _ViolationsBarPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) {
      final tp = TextPainter(
        text: const TextSpan(
            text: 'Nema prekršaja danas',
            style: TextStyle(color: Colors.grey)),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(size.width / 2 - tp.width / 2, size.height / 2));
      return;
    }

    final paint = Paint()
      ..color = const Color(0xFFE74C3C)
      ..style = PaintingStyle.fill;

    final maxCount = data.map((d) => d.count).reduce((a, b) => a > b ? a : b);
    final barWidth = size.width / (data.length * 2);

    for (int i = 0; i < data.length; i++) {
      final x = i * (barWidth * 2) + barWidth / 2;
      final barHeight =
      maxCount > 0 ? size.height * 0.85 * data[i].count / maxCount : 0.0;
      final y = size.height * 0.85 - barHeight;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(4),
        ),
        paint,
      );

      final countTp = TextPainter(
        text: TextSpan(
          text: '${data[i].count}x',
          style: const TextStyle(
              color: Color(0xFFE74C3C),
              fontSize: 10,
              fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      countTp.layout();
      countTp.paint(canvas, Offset(x, y - 14));



      final label = _shortLabel(data[i].violationType);
      final tp = TextPainter(
        text: TextSpan(
            text: label,
            style: const TextStyle(color: Colors.grey, fontSize: 10)),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(x, size.height - 16));
    }
  }


  int _min(int a, int b) => a < b ? a : b;

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// ---- Dnevna zarada ----
class _EarningsCard extends StatelessWidget {
  final RevenueReportDto? report;
  final ViolationsReportDto? violationsReport;

  const _EarningsCard({this.report, this.violationsReport});

  @override
  Widget build(BuildContext context) {
    final total = report?.totalRevenue ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: Color(0xFF27AE60), width: 4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.attach_money, color: Color(0xFF27AE60)),
              SizedBox(width: 8),
              Text('Dnevna zarada',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          _EarningsRow('Ukupno:', '${total.toStringAsFixed(2)} KM', bold: true),
          _EarningsRow('Tiketi:',
              '${report?.ticketRevenue.toStringAsFixed(2) ?? '0.00'} KM'),
          _EarningsRow('Rezervacije:',
              '${report?.reservationRevenue.toStringAsFixed(2) ?? '0.00'} KM'),
          _EarningsRow('Kazne:',
              '${violationsReport?.totalFinesAmount.toStringAsFixed(2) ?? '0.00'} KM'),
        ],
      ),
    );
  }
}
class _EarningsRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _EarningsRow(this.label, this.value, {this.bold = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              color: bold ? const Color(0xFF27AE60) : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Smart Insights ----
class _InsightsCard extends StatelessWidget {
  final OccupancyReportDto? occupancyReport;
  final ViolationsReportDto? violationsReport;
  final int activeDrones;

  const _InsightsCard({
    this.occupancyReport,
    this.violationsReport,
    required this.activeDrones,
  });

  @override
  Widget build(BuildContext context) {
    String problematicType = '–';
    if (violationsReport != null &&
        violationsReport!.violationsByType.isNotEmpty) {
      final top = violationsReport!.violationsByType
          .reduce((a, b) => a.count > b.count ? a : b);
      problematicType = '${_violationLabel(top.violationType)} (${top.count}x)';
    }

    String peakHour = '–';
    if (occupancyReport != null &&
        occupancyReport!.occupancyByHour.isNotEmpty) {
      final peak = occupancyReport!.occupancyByHour
          .reduce((a, b) => a.occupancyRate > b.occupancyRate ? a : b);
      peakHour =
      '${peak.hour}:00 (${peak.occupancyRate.toStringAsFixed(0)}%)';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Smart Insights',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          _InsightRow(Icons.access_time, 'Najprometniji period:', peakHour),
          const SizedBox(height: 8),
          _InsightRow(Icons.warning_amber, 'Najčešći prekršaj:', problematicType),
          const SizedBox(height: 8),
          _InsightRow(Icons.airplanemode_active, 'Aktivnih dronova:', '$activeDrones'),
          const SizedBox(height: 8),
          _InsightRow(
            Icons.bar_chart,
            'Prosječna zauzetost danas:',
            occupancyReport != null
                ? '${occupancyReport!.averageOccupancyRate.toStringAsFixed(1)}%'
                : '–',
          ),
        ],
      ),
    );
  }

  String _violationLabel(String type) => type;
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InsightRow(this.icon, this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF1A5276)),
        const SizedBox(width: 8),
        Text('$label ',
            style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Flexible(
          child: Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 13)),
        ),
      ],
    );
  }
}

// ---- Legend Item ----
class _LegendItem extends StatelessWidget {
  final String code;
  final String label;

  const _LegendItem(this.code, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: const Color(0xFFE74C3C).withOpacity(0.15),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            code,
            style: const TextStyle(
              color: Color(0xFFE74C3C),
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
      ],
    );
  }
}