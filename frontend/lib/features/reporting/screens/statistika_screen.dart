//import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import '../../detections/models/detection_log.dart';
import '../../detections/services/detection_service.dart';
import '../../parking/models/parking_lot.dart';
import '../../parking/models/parking_ticket.dart';
import '../../parking/services/parking_lot_service.dart';
import '../../reporting/models/occupancy_report.dart';
import '../../reporting/models/revenue_report.dart';
import '../../reporting/models/violations_report.dart';
import '../../reporting/services/reporting_service.dart';
import '../../../core/utils/pdf_helper.dart';

class StatistikaScreen extends StatefulWidget {
  const StatistikaScreen({super.key});

  @override
  State<StatistikaScreen> createState() => _StatistikaScreenState();
}

class _StatistikaScreenState extends State<StatistikaScreen> {
  final _reportingService = ReportingService();
  final _detectionService = DetectionService();

  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to = DateTime.now();

  OccupancyReportDto? _occupancyReport;
  ViolationsReportDto? _violationsReport;
  RevenueReportDto? _revenueReport;
  List<DetectionLog> _logs = [];
  List<ParkingLot> _lots = [];
  List<ParkingTicket> _tickets = [];
  int _occupiedSpots = 0;
  int _totalSpots = 0;

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _loadReports(),
      _loadLogs(),
      _loadSpotStats(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _loadSpotStats() async {
    try {
      final lots = await ParkingLotService().getAll();
      final tickets = await ParkingLotService().getAllTickets();
      final totalSpots = lots.fold<int>(0, (sum, lot) => sum + lot.totalSpots);
      final occupiedSpots = tickets
          .where((t) => t.exitTime == null && t.status.toLowerCase() == 'active')
          .length;
      setState(() {
        _totalSpots = totalSpots;
        _occupiedSpots = occupiedSpots;
      });
    } catch (_) {}
  }

  Future<void> _loadReports() async {
    try {
      final occ = await _reportingService.getOccupancyReport(_from, _to);
      final vio = await _reportingService.getViolationsReport(_from, _to);
      final rev = await _reportingService.getRevenueReport(_from, _to);
      setState(() {
        _occupancyReport = occ;
        _violationsReport = vio;
        _revenueReport = rev;
      });
    } catch (e) {
      print('>>> REPORTING ERROR: $e');
    }
  }

  Future<void> _loadLogs() async {
    try {
      final logs = await _detectionService.getAllLogs();
      setState(() => _logs = logs);
    } catch (e) {
      print('>>> LOGS ERROR: $e');
    }
  }

  Future<void> _pickDateRange() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odaberi period'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today, color: Color(0xFF1A5276)),
              title: const Text('Jedan dan'),
              onTap: () => Navigator.pop(context, 'day'),
            ),
            ListTile(
              leading: const Icon(Icons.date_range, color: Color(0xFF1A5276)),
              title: const Text('Period (Od - Do)'),
              onTap: () => Navigator.pop(context, 'range'),
            ),
          ],
        ),
      ),
    );

    if (choice == null) return;

    if (choice == 'day') {
      final picked = await showDatePicker(
        context: context,
        initialDate: _from,
        firstDate: DateTime(2024),
        lastDate: DateTime.now(),
        builder: (context, child) => Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFF1A5276)),
          ),
          child: child!,
        ),
      );
      if (picked != null) {
        setState(() {
          _from = DateTime(picked.year, picked.month, picked.day, 0, 0, 0);
          _to = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        });
        _loadAll();
      }
    } else {
      DateTime? tempFrom;
      DateTime? tempTo;

      await showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Odaberi period'),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: Color(0xFF1A5276)),
                  title: Text(tempFrom == null
                      ? 'Od: odaberi datum'
                      : 'Od: ${tempFrom!.day}.${tempFrom!.month}.${tempFrom!.year}'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _from,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: Color(0xFF1A5276)),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setDialogState(() => tempFrom = picked);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_today, color: Color(0xFF1A5276)),
                  title: Text(tempTo == null
                      ? 'Do: odaberi datum'
                      : 'Do: ${tempTo!.day}.${tempTo!.month}.${tempTo!.year}'),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _to,
                      firstDate: DateTime(2024),
                      lastDate: DateTime.now(),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: Color(0xFF1A5276)),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) setDialogState(() => tempTo = picked);
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Odustani'),
              ),
              ElevatedButton(
                onPressed: tempFrom != null && tempTo != null
                    ? () {
                  setState(() {
                    _from = tempFrom!;
                    _to = DateTime(tempTo!.year, tempTo!.month,
                        tempTo!.day, 23, 59, 59);
                  });
                  Navigator.pop(context);
                  _loadAll();
                }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A5276),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Primijeni'),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _downloadPdf(String type) async {
    final isDesktop = !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows);
    try {
      final fromStr = _from.toUtc().toIso8601String();
      final toStr = _to.toUtc().toIso8601String();
      final response = await _reportingService.downloadPdf(type, fromStr, toStr);
      openPdfInBrowser(response);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Greška pri preuzimanju PDF-a')),
      );
    }
  }

  // Grupisanje logova po dronu
  List<Map<String, dynamic>> get _droneStats {
    final droneMap = <int, List<DetectionLog>>{};
    for (final log in _logs) {
      if (log.droneNumber != null) {
        droneMap.putIfAbsent(log.droneNumber!, () => []).add(log);
      }
    }
    return droneMap.entries.map((e) {
      final total = e.value.length;
      final confirmed =
          e.value.where((l) => l.status.toLowerCase() == 'confirmed').length;
      final lotName = e.value.first.lotName;
      final rate = total > 0 ? (confirmed / total * 100).round() : 0;
      return {
        'droneNumber': e.key,
        'lotName': lotName,
        'total': total,
        'rate': rate,
      };
    }).toList()
      ..sort((a, b) => (a['droneNumber'] as int).compareTo(b['droneNumber'] as int));
  }

  // Grupisanje logova po kameri
  List<Map<String, dynamic>> get _cameraStats {
    final cameraMap = <String, List<DetectionLog>>{};
    for (final log in _logs) {
      // Samo entry i exit kamere, ne dronovi
      if (log.detectionCameraType.toLowerCase() == 'entry' ||
          log.detectionCameraType.toLowerCase() == 'exit') {
        final key = '${log.lotName}_${log.detectionCameraType}';
        cameraMap.putIfAbsent(key, () => []).add(log);
      }
    }
    return cameraMap.entries.map((e) {
      final lotName = e.value.first.lotName;
      final type = e.value.first.detectionCameraType;
      final typeLabel = type.toLowerCase() == 'entry' ? 'Ulaz' : 'Izlaz';
      final vehicles = e.value
          .where((l) =>
      l.result.toLowerCase() == 'entrygranted' ||
          l.result.toLowerCase() == 'exitgranted')
          .length;
      return {
        'lotName': lotName,
        'type': typeLabel,
        'vehicles': vehicles,
      };
    }).toList()
      ..sort((a, b) => (a['lotName'] as String).compareTo(b['lotName'] as String));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    // Kartice
    final totalViolations = _violationsReport?.totalViolations ?? 0;
    final totalDroneActivity = _logs.where((l) => l.droneNumber != null).length;
    final totalRevenue = _revenueReport?.totalRevenue ?? 0.0;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Naslov + filter + PDF
          Row(
            children: [
              const Text(
                'Statistika i izvještaji sistema',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(width: 16),
              OutlinedButton.icon(
                onPressed: _pickDateRange,
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(
                  _from.year == _to.year &&
                      _from.month == _to.month &&
                      _from.day == _to.day
                      ? '${_from.day}.${_from.month}.${_from.year}'
                      : '${_from.day}.${_from.month}.${_from.year} – ${_to.day}.${_to.month}.${_to.year}',
                ),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const Spacer(),
              // PDF dropdown
              PopupMenuButton<String>(
                onSelected: _downloadPdf,
                itemBuilder: (context) => [
                  const PopupMenuItem(
                      value: 'revenue', child: Text('Revenue PDF')),
                  const PopupMenuItem(
                      value: 'occupancy', child: Text('Occupancy PDF')),
                  const PopupMenuItem(
                      value: 'violations', child: Text('Violations PDF')),
                ],
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A5276),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
                      SizedBox(width: 8),
                      Text('PDF',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold)),
                      SizedBox(width: 4),
                      Icon(Icons.arrow_drop_down, color: Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Stat kartice
          Row(
            children: [

              _StatCard(
                icon: Icons.local_parking,
                iconColor: const Color(0xFF2E86C1),
                label: 'Ukupna parkiranja',
                  value: '$_occupiedSpots / $_totalSpots'
              ),
              const SizedBox(width: 16),


              _StatCard(
                icon: Icons.block,
                iconColor: const Color(0xFFE74C3C),
                label: 'Napropisna parkiranja',
                value: '$totalViolations',
              ),
              const SizedBox(width: 16),
              _StatCard(
                icon: Icons.airplanemode_active,
                iconColor: const Color(0xFF1ABC9C),
                label: 'Aktivnosti dronova',
                value: '$totalDroneActivity',
              ),
              const SizedBox(width: 16),
              _StatCard(
                icon: Icons.attach_money,
                iconColor: const Color(0xFF27AE60),
                label: 'Ukupna naplata',
                value: '${_revenueReport?.totalRevenue.toStringAsFixed(2) ?? '0.00'} KM',
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Grafovi
          const Text('Trendovi i grafikoni',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [


              Expanded(
                child: _ChartCard(
                  title: 'Zauzetost po zonama',
                  child: _occupancyReport != null &&
                      _occupancyReport!.occupancyByLot.isNotEmpty
                      ? _OccupancyByLotChart(data: _occupancyReport!.occupancyByLot)
                      : const Center(child: Text('Nema podataka')),
                ),
              ),


              const SizedBox(width: 16),
              Expanded(
                child: _ChartCard(
                  title: 'Broj prekršaja po tipu',
                  child: _violationsReport != null &&
                      _violationsReport!.violationsByType.isNotEmpty
                      ? _ViolationsChart(
                      data: _violationsReport!.violationsByType)
                      : const Center(child: Text('Nema podataka')),
                ),
              ),
              const SizedBox(width: 16),


              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.attach_money, color: Color(0xFF27AE60)),
                          SizedBox(width: 8),
                          Text('Prihodi',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _from.year == _to.year &&
                            _from.month == _to.month &&
                            _from.day == _to.day
                            ? 'za ${_from.day}.${_from.month}.${_from.year}.'
                            : 'od ${_from.day}.${_from.month}.${_from.year}. do ${_to.day}.${_to.month}.${_to.year}.',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      _RevenueRow(
                        label: 'Prihodi od tiketa:',
                        value: '${_revenueReport?.ticketRevenue.toStringAsFixed(2) ?? '0.00'} KM',
                        bold: false,
                      ),
                      const SizedBox(height: 8),
                      _RevenueRow(
                        label: 'Prihodi od rezervacija:',
                        value: '${_revenueReport?.reservationRevenue.toStringAsFixed(2) ?? '0.00'} KM',
                        bold: false,
                      ),
                      const SizedBox(height: 8),
                      _RevenueRow(
                        label: 'Kazne (ukupno izrečeno):',
                        value: '${_violationsReport?.totalFinesAmount.toStringAsFixed(2) ?? '0.00'} KM',
                        bold: false,
                      ),
                      const SizedBox(height: 8),
                      const Divider(),
                      const SizedBox(height: 8),
                      _RevenueRow(
                        label: 'Ukupno:',
                        value: '${_revenueReport?.totalRevenue.toStringAsFixed(2) ?? '0.00'} KM',
                        bold: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Tabele
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dron performanse
              Expanded(
                child: _TableCard(
                  title: 'Dron performanse',
                  headers: const [
                    'Dron ID', 'Zona', 'Broj inspekcija', 'Potvrđeno'],
                  rows: _droneStats
                      .map((d) => [
                    '#${d['droneNumber']}',
                    d['lotName'] as String,
                    '${d['total']}',
                    '${d['rate']}%',
                  ])
                      .toList(),
                ),
              ),
              const SizedBox(width: 16),
              // Kamera performanse
              Expanded(
                child: _TableCard(
                  title: 'Kamera performanse',
                  headers: const ['Zona', 'Pozicija', 'Evidentirana vozila'],
                  rows: _cameraStats
                      .map((c) => [
                    c['lotName'] as String,
                    c['type'] as String,
                    '${c['vehicles']}',
                  ])
                      .toList(),
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
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;

  const _StatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 12),
          SizedBox(height: 180, child: child),
        ],
      ),
    );
  }
}

// ---- Occupancy chart ----

class _OccupancyByLotChart extends StatelessWidget {
  final List<OccupancyByLotDto> data;
  const _OccupancyByLotChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _OccupancyByLotPainter(data),
      child: Container(),
    );
  }
}

class _OccupancyByLotPainter extends CustomPainter {
  final List<OccupancyByLotDto> data;
  _OccupancyByLotPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final paint = Paint()
      ..color = const Color(0xFF2E86C1)
      ..style = PaintingStyle.fill;

    final maxRate = data
        .map((d) => d.averageOccupancyRate)
        .reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxRate > 0 ? maxRate : 100;
    final barWidth = size.width / (data.length * 2);

    for (int i = 0; i < data.length; i++) {
      final x = i * (barWidth * 2) + barWidth / 2;
      final barHeight = size.height * 0.85 *
          data[i].averageOccupancyRate / effectiveMax;
      final y = size.height * 0.85 - barHeight;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, barHeight),
          const Radius.circular(4),
        ),
        paint,
      );

      // % iznad bara
      final pct = TextPainter(
        text: TextSpan(
          text: '${data[i].averageOccupancyRate.toStringAsFixed(0)}%',
          style: const TextStyle(
              color: Color(0xFF2E86C1), fontSize: 9, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      pct.layout();
      pct.paint(canvas, Offset(x, y - 12));

      // Naziv zone ispod
      final tp = TextPainter(
        text: TextSpan(
          text: data[i].lotName.length > 6
              ? data[i].lotName.substring(0, 6)
              : data[i].lotName,
          style: const TextStyle(color: Colors.grey, fontSize: 9),
        ),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset(x, size.height - 14));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}


// ---- Violations chart ----
class _ViolationsChart extends StatelessWidget {
  final List<ViolationsByTypeDto> data;
  const _ViolationsChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: CustomPaint(
            painter: _ViolationsPainter(data),
            child: Container(),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 12,
          runSpacing: 4,
          children: data.map((d) => Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: const Color(0xFFE74C3C),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${_shortLabel(d.violationType)}: ${d.violationType}',
                style: const TextStyle(fontSize: 9, color: Colors.grey),
              ),
            ],
          )).toList(),
        ),
      ],
    );
  }

  String _shortLabel(String type) {
    final words = type.split(' ').where((w) => w.length > 2).toList();
    if (words.length >= 2) {
      return words.map((w) => w[0].toUpperCase()).take(3).join();
    }
    return type.substring(0, type.length > 3 ? 3 : type.length).toUpperCase();
  }
}

class _ViolationsPainter extends CustomPainter {
  final List<ViolationsByTypeDto> data;
  _ViolationsPainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

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
            const Radius.circular(4)),
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

  String _shortLabel(String type) {
    final words = type.split(' ').where((w) => w.length > 2).toList();
    if (words.length >= 2) {
      return words.map((w) => w[0].toUpperCase()).take(3).join();
    }
    return type.substring(0, type.length > 3 ? 3 : type.length).toUpperCase();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// ---- Revenue chart ----
class _RevenueChart extends StatelessWidget {
  final List<RevenueByDayDto> data;
  const _RevenueChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RevenuePainter(data),
      child: Container(),
    );
  }
}

class _RevenuePainter extends CustomPainter {
  final List<RevenueByDayDto> data;
  _RevenuePainter(this.data);

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;

    final maxRevenue =
    data.map((d) => d.totalRevenue).reduce((a, b) => a > b ? a : b);
    final effectiveMax = maxRevenue > 0 ? maxRevenue : 1;

    final paint = Paint()
      ..color = const Color(0xFF1ABC9C)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final fillPaint = Paint()
      ..color = const Color(0xFF1ABC9C).withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final points = List.generate(data.length, (i) {
      final x = size.width * i / (data.length - 1);
      final y = size.height * 0.85 * (1 - data[i].totalRevenue / effectiveMax);
      return Offset(x, y);
    });

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (var p in points.skip(1)) path.lineTo(p.dx, p.dy);

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, paint);

    final tp = TextPainter(textDirection: TextDirection.ltr);
    for (int i = 0; i < data.length; i += (data.length > 5 ? data.length ~/ 5 : 1)) {
      tp.text = TextSpan(
        text: '${data[i].date.day}.${data[i].date.month}',
        style: const TextStyle(color: Colors.grey, fontSize: 10),
      );
      tp.layout();
      tp.paint(canvas, Offset(size.width * i / (data.length - 1), size.height - 14));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}

// ---- Table kartica ----
class _TableCard extends StatelessWidget {
  final String title;
  final List<String> headers;
  final List<List<String>> rows;

  const _TableCard({
    required this.title,
    required this.headers,
    required this.rows,
  });

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
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          // Header
          Container(
            decoration: const BoxDecoration(
              border: Border(
                  bottom: BorderSide(color: Color(0xFFE0E0E0))),
            ),
            child: Row(
              children: headers
                  .map((h) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(h,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: Colors.grey)),
                ),
              ))
                  .toList(),
            ),
          ),
          // Rows
          if (rows.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                  child: Text('Nema podataka',
                      style: TextStyle(color: Colors.grey))),
            )
          else
            ...rows.map((row) => Container(
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Color(0xFFE0E0E0))),
              ),
              child: Row(
                children: row
                    .map((cell) => Expanded(
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(vertical: 12),
                    child: Text(cell,
                        style: const TextStyle(fontSize: 13)),
                  ),
                ))
                    .toList(),
              ),
            )),
        ],
      ),
    );
  }
}
class _RevenueRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _RevenueRow({
    required this.label,
    required this.value,
    required this.bold,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: bold ? FontWeight.bold : FontWeight.normal,
            color: bold ? const Color(0xFF27AE60) : Colors.black87,
          ),
        ),
      ],
    );
  }
}