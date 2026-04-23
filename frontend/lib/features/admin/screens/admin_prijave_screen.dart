import 'package:flutter/material.dart';
import 'dart:async';
import '../../auth/models/vehicle_with_owner.dart';
import '../../auth/services/auth_service.dart';
import '../../detections/models/camera.dart';
import '../../detections/models/detection_log.dart';
import '../../detections/models/drone.dart';
import '../../detections/services/detection_service.dart';
import '../../parking/models/parking_lot.dart';
import '../../parking/models/parking_spot.dart';
import '../../parking/models/parking_ticket.dart';
import '../../parking/models/parking_violation.dart';
import '../../parking/models/violation_config.dart';
import '../../parking/services/parking_lot_service.dart';
import '../../parking/services/violation_config_service.dart';
import '../../profile/models/vehicle_profil.dart';
import '../../profile/services/vehicle_service.dart';

String _violationTypeLabel(String type) {
  switch (type.toLowerCase()) {
    case 'noticket':
    case '0': return 'Bez tiketa';
    case 'expiredreservation':
    case '1': return 'Istekla rezervacija';
    case 'wrongspot':
    case '2': return 'Pogrešno mjesto';
    case 'overstay':
    case '3': return 'Prekoračeno vrijeme';
    case 'overtheline':
    case '4': return 'Preko linije';
    case 'outofbounds':
    case '5': return 'Van zone';
    case 'improperparking':
    case '6': return 'Nepropisno parkiranje';
    case 'disabledspotviolation':
    case '7': return 'Invalidsko mjesto';
    default: return type;
  }
}

class _CountdownWidget extends StatefulWidget {
  final DateTime deadline;
  final double lateFee;
  const _CountdownWidget({required this.deadline, required this.lateFee});

  @override
  State<_CountdownWidget> createState() => _CountdownWidgetState();
}

class _CountdownWidgetState extends State<_CountdownWidget> {
  late Timer _timer;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _remaining = widget.deadline.difference(DateTime.now());
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() => _remaining = widget.deadline.difference(DateTime.now()));
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_remaining.isNegative) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Odbrojavanje...', style: TextStyle(color: Colors.red, fontSize: 11)),
          if (widget.lateFee > 0)
            Text('+${widget.lateFee.toStringAsFixed(2)} KM kazna',
                style: const TextStyle(color: Colors.red, fontSize: 11)),
        ],
      );
    }
    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes % 60;
    final seconds = _remaining.inSeconds % 60;
    return Text(
      '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
      style: const TextStyle(color: Color(0xFFE74C3C), fontWeight: FontWeight.w500),
    );
  }
}

class PrijaveScreen extends StatefulWidget {
  final VoidCallback? onReviewed;
  const PrijaveScreen({super.key, this.onReviewed});

  @override
  State<PrijaveScreen> createState() => _PrijaveScreenState();
}

class _PrijaveScreenState extends State<PrijaveScreen> {
  String? _selectedStatus;
  final _tableFilterController = TextEditingController();
  DateTime? _selectedDate;

  String? _selectedCameraStatus;
  final _cameraFilterController = TextEditingController();
  DateTime? _selectedCameraDate;

  List<ParkingLot> _lots = [];
  String? _selectedLotId;
  String? _selectedCameraLotId;

  List<ViolationConfig> _violationConfigs = [];
  List<Drone> _drones = [];
  List<Camera> _cameras = [];
  List<Vehicle> _vehicles = [];

  final _detectionService = DetectionService();
  List<DetectionLog> _logs = [];
  List<ParkingTicket> _tickets = [];
  bool _isLoading = true;
  bool _isLoadingTickets = false;
  int _selectedTab = 0;

  Timer? _ticketRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadLogs();
    _loadTickets();
    _loadLots();
    _loadViolationConfigs();
    _loadDrones();
    _loadCameras();
    _loadVehicles();

    _ticketRefreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) _loadTickets(silent: true);
    });
  }

  @override
  void dispose() {
    _ticketRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    try {
      final vehicles = await VehicleService().getAllVehicles();
      setState(() => _vehicles = vehicles);
    } catch (_) {}
  }

  Future<void> _loadDrones() async {
    try {
      final drones = await _detectionService.getDrones();
      setState(() => _drones = drones);
    } catch (_) {}
  }

  Future<void> _loadCameras() async {
    try {
      final cameras = await _detectionService.getCameras();
      setState(() => _cameras = cameras);
    } catch (_) {}
  }

  Future<void> _loadViolationConfigs() async {
    try {
      final configs = await ViolationConfigService().getAll();
      setState(() => _violationConfigs = configs);
    } catch (_) {}
  }

  Future<void> _loadLots() async {
    try {
      final lots = await ParkingLotService().getAllAdmin();
      setState(() => _lots = lots);
    } catch (_) {}
  }

  Future<void> _loadLogs() async {
    setState(() => _isLoading = true);
    try {
      final logs = await _detectionService.getAllLogs();
      setState(() => _logs = logs);
      widget.onReviewed?.call();
    } catch (e) {
      if (!mounted) return;
      setState(() => _logs = []);
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadTickets({bool silent = false}) async {
    if (!silent) setState(() => _isLoadingTickets = true);
    try {
      final tickets = await ParkingLotService().getAllTickets();
      if (mounted) setState(() => _tickets = tickets);
    } catch (e) {
      if (!mounted) return;
      if (!silent) setState(() => _tickets = []);
    } finally {
      if (!silent && mounted) setState(() => _isLoadingTickets = false);
    }
  }

  void _showTestDetectionDialog() {
    const primaryBlue = Color(0xFF1A5276);
    final licensePlateController = TextEditingController();
    ParkingLot? selectedLot;
    ViolationConfig? selectedViolationConfig;
    int cameraType = 2;
    int? selectedDroneNumber;
    int? selectedCameraNumber;
    String? selectedLicensePlate;
    String? selectedSpotId;
    List<ParkingSpot> availableSpots = [];
    bool isLoadingSpots = false;

    // Samo aktivne zone
    final activeLots = _lots.where((l) => l.isActive).toList();

    // Aktivni dronovi iz baze
    final droneNumbers = _drones
        .where((d) => d.status.toLowerCase() == 'active')
        .map((d) => d.number)
        .toList()
      ..sort();

    final allPlates = _vehicles // ← OVDJE
        .map((v) => v.licensePlate)
        .toList()
      ..sort();

// Aktivne kamere iz baze
    List<Camera> availableCameras() {
      if (cameraType == 0) {
        return _cameras
            .where((c) =>
        c.status.toLowerCase() == 'active' &&
            c.cameraType.toLowerCase() == 'entry')
            .toList();
      } else {
        return _cameras
            .where((c) =>
        c.status.toLowerCase() == 'active' &&
            c.cameraType.toLowerCase() == 'exit')
            .toList();
      }
    }

    // Tablice sa aktivnim ticketom (trenutno parkirane)
    final activePlates = _tickets
        .where((t) => t.exitTime == null && t.status.toLowerCase() == 'active')
        .map((t) => t.licensePlate)
        .toSet()
        .toList();

    // Tablice bez aktivnog ticketa (slobodne za ulaz)
    final freePlates = allPlates
        .where((p) => !activePlates.contains(p))
        .toList();


    showDialog(
      context: context,
      builder: (context) =>
          StatefulBuilder(
            builder: (context, setDialogState) {
              // Tablice ovisno o tipu kamere
              List<String> availablePlates;
              if (cameraType == 0) {
                // Ulaz — tablice koje NISU trenutno parkirane
                availablePlates = freePlates;
              } else if (cameraType == 1) {
                // Izlaz — tablice koje JESU trenutno parkirane
                availablePlates = activePlates;
              } else {
                // Dron — slobodan unos
                availablePlates = [];
              }

              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                child: Container(
                  width: 500,
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Naslov
                        Row(
                          children: [
                            const Text('Testna prijava',
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text('SAMO ZA TESTIRANJE',
                                  style: TextStyle(
                                      color: Colors.orange,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // 1. Tip uređaja
                        DropdownButtonFormField<int>(
                          value: cameraType,
                          isExpanded: true,
                          decoration: InputDecoration(
                            labelText: 'Tip uređaja',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8)),
                          ),
                          items: const [
                            DropdownMenuItem(value: 0, child: Text(
                                'Kamera — Ulaz')),
                            DropdownMenuItem(value: 1, child: Text(
                                'Kamera — Izlaz')),
                            DropdownMenuItem(value: 2, child: Text('Dron')),
                          ],
                          onChanged: (v) =>
                              setDialogState(() {
                                cameraType = v ?? 2;
                                selectedLicensePlate = null;
                                selectedDroneNumber = null;
                                selectedCameraNumber = null;
                                selectedLot = null;
                                selectedSpotId = null;
                                availableSpots = [];
                                licensePlateController.clear();
                              }),
                        ),
                        const SizedBox(height: 12),

                        // 2. Broj drona ili kamere → automatski popuni zonu
                        if (cameraType == 2) ...[
                          DropdownButtonFormField<Drone>(
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Broj drona',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            items: _drones
                                .where((d) =>
                            d.status.toLowerCase() == 'active')
                                .map((d) =>
                                DropdownMenuItem(
                                  value: d,
                                  child: Text(
                                      'Dron #${d.number} — ${d.lotName} (🔋${d
                                          .batteryLevel}%)'),
                                ))
                                .toList(),
                            onChanged: (d) =>
                                setDialogState(() {
                                  selectedDroneNumber = d?.number;
                                  selectedLot = activeLots.firstWhere(
                                        (l) => l.id == d?.lotId,
                                    orElse: () => activeLots.first,
                                  );
                                }),
                          ),
                        ] else
                          ...[
                            DropdownButtonFormField<Camera>(
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: 'Broj kamere',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              items: availableCameras().map((c) =>
                                  DropdownMenuItem(
                                    value: c,
                                    child: Text(
                                        'Kamera #${c.number} — ${c.lotName}'),
                                  )).toList(),

                              onChanged: (c) async {
                                setDialogState(() {
                                  selectedCameraNumber = c?.number;
                                  selectedLot = activeLots.firstWhere(
                                        (l) => l.id == c?.lotId,
                                    orElse: () => activeLots.first,
                                  );
                                  selectedSpotId = null;
                                  isLoadingSpots = true;
                                });

                                // Učitaj slobodna mjesta za taj lot
                                if (c?.lotId != null) {
                                  final spots = await ParkingLotService().getSpotsByLotId(c!.lotId);
                                  setDialogState(() {
                                    availableSpots = spots.where((s) => s.status == 0).toList();
                                    isLoadingSpots = false;
                                  });
                                }
                              },
                            ),
                          ],
                        const SizedBox(height: 12),

                        // 3. Zona — read-only, automatski popunjena
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 16),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey.shade100,
                          ),
                          child: Text(
                            selectedLot != null ? 'Parking zona: ${selectedLot!
                                .name}' : 'Parking zona: odaberi uređaj',
                            style: TextStyle(
                              color: selectedLot != null
                                  ? Colors.black87
                                  : Colors.grey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),


                        if (cameraType == 0) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                            value: selectedSpotId,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Parking mjesto',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            items: availableSpots.map((spot) => DropdownMenuItem<String>(
                              value: spot.id,
                              child: Text('${spot.spotNumber} — Sprat ${spot.floor ?? 0}'),
                            )).toList(),
                            onChanged: (v) => setDialogState(() => selectedSpotId = v),
                          ),
                          const SizedBox(height: 12),
                        ],

                        // 4. Registarska tablica
                        if (cameraType == 2) ...[
                          DropdownButtonFormField<String>(
                            value: selectedLicensePlate,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Registarska tablica',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            items: allPlates.map((plate) =>
                                DropdownMenuItem(
                                  value: plate,
                                  child: Text(plate),
                                )).toList(),
                            onChanged: (v) =>
                                setDialogState(() {
                                  selectedLicensePlate = v;
                                  if (v != null)
                                    licensePlateController.text = v;
                                }),
                          ),
                        ] else
                          ...[
                            DropdownButtonFormField<String>(
                              value: selectedLicensePlate,
                              isExpanded: true,
                              decoration: InputDecoration(
                                labelText: cameraType == 0
                                    ? 'Registarska tablica (bez aktivnog tiketa)'
                                    : 'Registarska tablica (trenutno parkirana)',
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8)),
                              ),
                              items: availablePlates.map((plate) =>
                                  DropdownMenuItem(
                                    value: plate,
                                    child: Text(plate),
                                  )).toList(),
                              onChanged: (v) =>
                                  setDialogState(() {
                                    selectedLicensePlate = v;
                                    if (v != null)
                                      licensePlateController.text = v;
                                  }),
                            ),
                          ],
                        const SizedBox(height: 12),

                        // 5. Tip prekršaja — samo za dron
                        if (cameraType == 2) ...[
                          DropdownButtonFormField<ViolationConfig>(
                            value: selectedViolationConfig,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: 'Tip prekršaja (opcionalno)',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            items: [
                              const DropdownMenuItem(
                                  value: null, child: Text('Nema prekršaja')),
                              ..._violationConfigs.map((config) =>
                                  DropdownMenuItem(
                                    value: config,
                                    child: Text(
                                      '${config.typeName} — ${config.fineAmount
                                          .toStringAsFixed(2)} KM',
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  )),
                            ],
                            onChanged: (v) =>
                                setDialogState(() =>
                                selectedViolationConfig = v),
                          ),
                          const SizedBox(height: 12),
                        ],
                        const SizedBox(height: 12),

                        // Dugmad
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: () async {
                                  final plate = licensePlateController.text
                                      .trim();
                                  if (selectedLot == null || plate.isEmpty) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Odaberite uređaj i tablicu'),
                                          backgroundColor: Colors.red),
                                    );
                                    return;
                                  }
                                  final messenger = ScaffoldMessenger.of(
                                      context);
                                  try {
                                    await _detectionService.createManualLog({
                                      'lotId': selectedLot!.id,
                                      'cameraType': cameraType,
                                      'licensePlate': plate.toUpperCase(),
                                      'droneNumber': cameraType == 2
                                          ? selectedDroneNumber
                                          : null,
                                      'cameraNumber': cameraType != 2
                                          ? selectedCameraNumber
                                          : null,
                                      'violationConfigId': selectedViolationConfig
                                          ?.id,
                                      'spotId': selectedSpotId,
                                    });

                                    Navigator.pop(context);
                                    _loadLogs();
                                    await Future.delayed(
                                        const Duration(seconds: 1));
                                    await _loadTickets();

                                    messenger.showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Testna prijava kreirana!'),
                                          backgroundColor: Colors.green),
                                    );
                                  } catch (e) {
                                    messenger.showSnackBar(
                                      SnackBar(
                                          content: Text('Greška: $e'),
                                          backgroundColor: Colors.red),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Kreiraj testnu prijavu'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Odustani'),
                            ),
                          ],
                        ),
                      ],

                    ),
                  ),
                ),
              );
            },
          ),
    );
  }

  List<DetectionLog> get _filteredLogs {
    return _logs.where((l) {
      final matchesType = l.detectionCameraType == 'Drone';
      final matchesDate = _selectedDate == null ||
          (l.detectedAt.year == _selectedDate!.year &&
              l.detectedAt.month == _selectedDate!.month &&
              l.detectedAt.day == _selectedDate!.day);
      final matchesStatus = _selectedStatus == null ||
          l.status.toLowerCase() == _selectedStatus!.toLowerCase();
      final matchesLot = _selectedLotId == null ||
          l.lotName == _lots
              .firstWhere((lot) => lot.id == _selectedLotId,
              orElse: () => _lots.first)
              .name;
      return matchesType && matchesLot && matchesDate && matchesStatus;
    }).toList();
  }

  List<ParkingTicket> get _filteredTickets {
    return _tickets.where((t) {
      final isParked = t.exitTime == null && t.status.toLowerCase() == 'active';
      final matchesDate = _selectedCameraDate == null ||
          (t.entryTime.year == _selectedCameraDate!.year &&
              t.entryTime.month == _selectedCameraDate!.month &&
              t.entryTime.day == _selectedCameraDate!.day);
      final matchesStatus = _selectedCameraStatus == null || (() {
        if (_selectedCameraStatus == 'parkiran') return isParked;
        if (_selectedCameraStatus == 'paid')
          return t.status.toLowerCase() == 'paid';
        if (_selectedCameraStatus == 'pendingpayment')
          return t.status.toLowerCase() == 'pendingpayment';
        return true;
      })();
      final matchesLot = _selectedCameraLotId == null ||
          t.lotName == _lots
              .firstWhere((lot) => lot.id == _selectedCameraLotId,
              orElse: () => _lots.first)
              .name;
      return matchesLot && matchesDate && matchesStatus;
    }).toList();
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pendingreview':
        return const Color(0xFF2E86C1);
      case 'confirmed':
        return const Color(0xFF27AE60);
      case 'rejected':
        return const Color(0xFFE74C3C);
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'pendingreview':
        return 'Novo';
      case 'confirmed':
        return 'Odobreno';
      case 'rejected':
        return 'Odbijeno';
      default:
        return status;
    }
  }

  String _resultLabel(String result) {
    switch (result.toLowerCase()) {
      case 'vehiclevalid':
        return 'Vozilo validno';
      case 'violationdetected':
        return 'Prekršaj detektovan';
      case 'unknownvehicle':
        return 'Nepoznato vozilo';
      case 'entrygranted':
        return 'Ulaz odobren';
      case 'exitgranted':
        return 'Izlaz odobren';
      default:
        return result;
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1A5276);
    final screenWidth = MediaQuery
        .of(context)
        .size
        .width;
    final tableWidth = screenWidth - 280;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _TabButton(
              label: 'Dronovi',
              isSelected: _selectedTab == 0,
              onTap: () => setState(() => _selectedTab = 0),
            ),
            const SizedBox(width: 8),
            _TabButton(
              label: 'Kamere',
              isSelected: _selectedTab == 1,
              onTap: () => setState(() => _selectedTab = 1),
            ),
            const Spacer(),
            OutlinedButton.icon(
              onPressed: () => _showTestDetectionDialog(),
              icon: const Icon(Icons.science, size: 16),
              label: const Text('Testna prijava'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _selectedTab == 0
                ? _buildDroneTable(primaryBlue, tableWidth)
                : _CameraTable(
              tickets: _filteredTickets,
              lots: _lots,
              primaryBlue: primaryBlue,
              selectedCameraStatus: _selectedCameraStatus,
              selectedCameraLotId: _selectedCameraLotId,
              selectedCameraDate: _selectedCameraDate,
              onStatusChanged: (v) => setState(() => _selectedCameraStatus = v),
              onLotChanged: (v) => setState(() => _selectedCameraLotId = v),
              onDateChanged: (v) => setState(() => _selectedCameraDate = v),
              onDateCleared: () => setState(() => _selectedCameraDate = null),

          ),
        ),),
      ],
    );
  }

  Widget _buildDroneTable(Color primaryBlue, double tableWidth) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DropdownButton<String?>(
                value: _selectedStatus,
                hint: const Text('Status'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Svi statusi')),
                  DropdownMenuItem(value: 'pendingreview', child: Text('Novo')),
                  DropdownMenuItem(value: 'confirmed', child: Text('Odobreno')),
                  DropdownMenuItem(value: 'rejected', child: Text('Odbijeno')),
                ],
                onChanged: (value) => setState(() => _selectedStatus = value),
                underline: Container(height: 1, color: Colors.grey.shade300),
              ),
              const SizedBox(width: 12),
              DropdownButton<String?>(
                value: _selectedLotId,
                hint: const Text('Zona'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Sve zone')),
                  ..._lots.map((lot) =>
                      DropdownMenuItem(
                        value: lot.id,
                        child: Text(lot.name),
                      )),
                ],
                onChanged: (value) => setState(() => _selectedLotId = value),
                underline: Container(height: 1, color: Colors.grey.shade300),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(_selectedDate == null
                    ? 'Datum'
                    : '${_selectedDate!.day}.${_selectedDate!
                    .month}.${_selectedDate!.year}'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              if (_selectedDate != null) ...[
                const SizedBox(width: 8),
                IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () => setState(() => _selectedDate = null)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0)))),
          child: Row(
            children: const [
              Expanded(child: Center(child: Text(
                  'Status', style: TextStyle(fontWeight: FontWeight.bold)))),
              Expanded(child: Center(child: Text(
                  'Vrijeme', style: TextStyle(fontWeight: FontWeight.bold)))),
              Expanded(child: Center(child: Text(
                  'Zona', style: TextStyle(fontWeight: FontWeight.bold)))),
              Expanded(child: Center(child: Text(
                  'Dron', style: TextStyle(fontWeight: FontWeight.bold)))),
              Expanded(child: Center(child: Text('AI rezultat',
                  style: TextStyle(fontWeight: FontWeight.bold)))),
              Expanded(child: Center(child: Text(
                  'Akcija', style: TextStyle(fontWeight: FontWeight.bold)))),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(),
                1: FlexColumnWidth(),
                2: FlexColumnWidth(),
                3: FlexColumnWidth(),
                4: FlexColumnWidth(),
                5: FlexColumnWidth(),
              },
              children: _filteredLogs.map((log) {
                return TableRow(
                  decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(
                          0xFFE0E0E0)))),
                  children: [
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                                color: _statusColor(log.status),
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(_statusLabel(log.status),
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 12)),
                          ),
                        ),
                      ),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            '${log.detectedAt.hour}:${log.detectedAt.minute
                                .toString().padLeft(2, '0')}\n${log.detectedAt
                                .day}.${log.detectedAt.month}.${log.detectedAt
                                .year}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: Text(log.lotName))),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(log.droneNumber != null
                              ? '#${log.droneNumber}'
                              : log.cameraNumber != null
                              ? '#${log.cameraNumber}'
                              : '–'),
                        ),
                      ),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(log.violationType != null
                              ? _violationTypeLabel(log.violationType!)
                              : _resultLabel(log.result)),
                        ),
                      ),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) =>
                                    _PrijavaPreviewDialog(
                                        log: log, onReviewed: _loadLogs),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryBlue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                            ),
                            child: const Text('Pregled'),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}





class _CameraTable extends StatelessWidget {
  final List<ParkingTicket> tickets;
  final List<ParkingLot> lots;
  final Color primaryBlue;
  final String? selectedCameraStatus;
  final String? selectedCameraLotId;
  final DateTime? selectedCameraDate;
  final ValueChanged<String?> onStatusChanged;
  final ValueChanged<String?> onLotChanged;
  final ValueChanged<DateTime?> onDateChanged;
  final VoidCallback onDateCleared;

  const _CameraTable({
    required this.tickets,
    required this.lots,
    required this.primaryBlue,
    required this.selectedCameraStatus,
    required this.selectedCameraLotId,
    required this.selectedCameraDate,
    required this.onStatusChanged,
    required this.onLotChanged,
    required this.onDateChanged,
    required this.onDateCleared,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              DropdownButton<String?>(
                value: selectedCameraStatus,
                hint: const Text('Status'),
                items: const [
                  DropdownMenuItem(value: null, child: Text('Svi statusi')),
                  DropdownMenuItem(value: 'parkiran', child: Text('Parkiran')),
                  DropdownMenuItem(value: 'paid', child: Text('Plaćeno')),
                  DropdownMenuItem(value: 'pendingpayment', child: Text('Neplaćeno')),
                ],
                onChanged: onStatusChanged,
                underline: Container(height: 1, color: Colors.grey.shade300),
              ),
              const SizedBox(width: 12),
              DropdownButton<String?>(
                value: selectedCameraLotId,
                hint: const Text('Zona'),
                items: [
                  const DropdownMenuItem(value: null, child: Text('Sve zone')),
                  ...lots.map((lot) => DropdownMenuItem(
                    value: lot.id,
                    child: Text(lot.name),
                  )),
                ],
                onChanged: onLotChanged,
                underline: Container(height: 1, color: Colors.grey.shade300),
              ),
              const SizedBox(width: 12),
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2024),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) onDateChanged(picked);
                },
                icon: const Icon(Icons.calendar_today, size: 16),
                label: Text(selectedCameraDate == null
                    ? 'Datum'
                    : '${selectedCameraDate!.day}.${selectedCameraDate!.month}.${selectedCameraDate!.year}'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
              if (selectedCameraDate != null) ...[
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: onDateCleared,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: 48,
          decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0)))),
          child: Row(
            children: const [
              Expanded(child: Center(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)))),
              Expanded(child: Center(child: Text('Zona', style: TextStyle(fontWeight: FontWeight.bold)))),
              Expanded(child: Center(child: Text('Registracija', style: TextStyle(fontWeight: FontWeight.bold)))),
              Expanded(child: Center(child: Text('Vrijeme ulaska', style: TextStyle(fontWeight: FontWeight.bold)))),
              Expanded(child: Center(child: Text('Vrijeme izlaska', style: TextStyle(fontWeight: FontWeight.bold)))),
              Expanded(child: Center(child: Text('Trajanje', style: TextStyle(fontWeight: FontWeight.bold)))),
              Expanded(child: Center(child: Text('Ukupno', style: TextStyle(fontWeight: FontWeight.bold)))),
              Expanded(child: Center(child: Text('Rok za plaćanje', style: TextStyle(fontWeight: FontWeight.bold)))),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            child: Table(
              columnWidths: const {
                0: FlexColumnWidth(),
                1: FlexColumnWidth(),
                2: FlexColumnWidth(),
                3: FlexColumnWidth(),
                4: FlexColumnWidth(),
                5: FlexColumnWidth(),
                6: FlexColumnWidth(),
                7: FlexColumnWidth(),
              },
              children: tickets.map((ticket) {
                final isParked = ticket.exitTime == null;
                final duration = isParked
                    ? DateTime.now().difference(ticket.entryTime)
                    : ticket.exitTime!.difference(ticket.entryTime);
                final hours = duration.inHours;
                final minutes = duration.inMinutes % 60;

                Color statusColor;
                String statusLabel;
                if (isParked) {
                  statusColor = const Color(0xFFF39C12);
                  statusLabel = 'Parkiran';
                } else if (ticket.status.toLowerCase() == 'paid') {
                  statusColor = const Color(0xFF27AE60);
                  statusLabel = 'Plaćeno';
                } else {
                  statusColor = const Color(0xFFE74C3C);
                  statusLabel = 'Neplaćeno';
                }

                return TableRow(
                  decoration: const BoxDecoration(
                      border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0)))),
                  children: [
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                                color: statusColor,
                                borderRadius: BorderRadius.circular(20)),
                            child: Text(statusLabel,
                                style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ),
                      ),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: Text(ticket.lotName))),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(child: Text(ticket.licensePlate))),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            '${ticket.entryTime.hour}:${ticket.entryTime.minute.toString().padLeft(2, '0')}\n${ticket.entryTime.day}.${ticket.entryTime.month}.${ticket.entryTime.year}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            isParked
                                ? '–'
                                : '${ticket.exitTime!.hour}:${ticket.exitTime!.minute.toString().padLeft(2, '0')}\n${ticket.exitTime!.day}.${ticket.exitTime!.month}.${ticket.exitTime!.year}',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                            child: Text(isParked ? 'U toku' : '${hours}h ${minutes}min')),
                      ),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            isParked
                                ? '–'
                                : ticket.totalPrice != null
                                ? '${ticket.totalPrice!.toStringAsFixed(2)} KM'
                                : '–',
                          ),
                        ),
                      ),
                    ),
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: ticket.status.toLowerCase() == 'paid'
                              ? const Text('Plaćeno',
                              style: TextStyle(
                                  color: Color(0xFF27AE60),
                                  fontWeight: FontWeight.bold))
                              : ticket.paymentDeadline != null
                              ? _CountdownWidget(
                              deadline: ticket.paymentDeadline!,
                              lateFee: ticket.lateFee)
                              : const Text('–'),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}





class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({required this.label, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1A5276);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: primaryBlue),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : primaryBlue,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _PrijavaPreviewDialog extends StatefulWidget {
  final DetectionLog log;
  final VoidCallback onReviewed;

  const _PrijavaPreviewDialog({required this.log, required this.onReviewed});

  @override
  State<_PrijavaPreviewDialog> createState() => _PrijavaPreviewDialogState();
}

class _PrijavaPreviewDialogState extends State<_PrijavaPreviewDialog> {
  final _commentController = TextEditingController();
  final _detectionService = DetectionService();
  final _authService = AuthService();
  final _parkingLotService = ParkingLotService();
  ParkingViolation? _violation;
  bool _isLoading = false;
  VehicleWithOwnerResponse? _vehicleOwner;
  bool _isLoadingOwner = true;
  ViolationConfig? _violationConfig;

  @override
  void initState() {
    super.initState();
    _loadOwner();
    _loadViolation();
    _loadViolationConfig();
  }

  Future<void> _loadViolationConfig() async {
    if (widget.log.violationConfigId == null) return;
    try {
      final configs = await ViolationConfigService().getAll();
      final config = configs.firstWhere(
            (c) => c.id == widget.log.violationConfigId,
        orElse: () => configs.first,
      );
      setState(() => _violationConfig = config);
    } catch (_) {}
  }

  Future<void> _loadViolation() async {
    final result = await _parkingLotService.getLatestViolationByPlate(widget.log.licensePlate);
    setState(() => _violation = result);
  }

  Future<void> _loadOwner() async {
    final result = await _authService.getVehicleByLicensePlate(widget.log.licensePlate);
    setState(() {
      _vehicleOwner = result;
      _isLoadingOwner = false;
    });
  }

  Future<void> _review(bool confirmed) async {
    setState(() => _isLoading = true);
    try {
      await _detectionService.reviewDetection(
        widget.log.id,
        confirmed,
        _commentController.text,
      );
      Navigator.pop(context);
      widget.onReviewed();
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  String _resultLabel(String result) {
    switch (result.toLowerCase()) {
      case 'vehiclevalid': return 'Vozilo validno';
      case 'violationdetected': return 'Prekršaj detektovan';
      case 'unknownvehicle': return 'Nepoznato vozilo';
      case 'entrygranted': return 'Ulaz odobren';
      case 'exitgranted': return 'Izlaz odobren';
      default: return result;
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1A5276);
    final log = widget.log;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 750,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Pregled prijave',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context)),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dron #${log.droneNumber ?? '–'}',
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),


                      const Text('Detekcija',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(_violationConfig != null
                          ? _violationConfig!.typeName
                          : _resultLabel(log.result)),
                      if (_violationConfig != null) ...[
                        const SizedBox(height: 4),
                        const Text('Opis prekršaja:',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        Text(_violationConfig!.description),
                        const SizedBox(height: 4),
                        const Text('Iznos kazne:',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                        Text(
                          '${_violationConfig!.fineAmount.toStringAsFixed(2)} KM',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500),
                        ),
                      ],


                      const SizedBox(height: 16),
                      const Text('Zona',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(log.lotName),
                      const SizedBox(height: 8),
                      const Text('Vrijeme',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Text(
                          '${log.detectedAt.hour}:${log.detectedAt.minute.toString().padLeft(2, '0')} | ${log.detectedAt.day}.${log.detectedAt.month}.${log.detectedAt.year}'),
                      const SizedBox(height: 16),
                      const Divider(),
                      const SizedBox(height: 8),
                      const Text('Podaci o vozaču',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, color: Colors.grey)),
                      const SizedBox(height: 8),
                      if (_isLoadingOwner)
                        const CircularProgressIndicator()
                      else if (_vehicleOwner != null) ...[
                        _InfoRow('Registracija:', _vehicleOwner!.vehicle.licensePlate),
                        _InfoRow('Ime i prezime:',
                            '${_vehicleOwner!.owner.firstName} ${_vehicleOwner!.owner.lastName}'),
                        _InfoRow('Email:', _vehicleOwner!.owner.email),
                        if (_vehicleOwner!.owner.phoneNumber != null)
                          _InfoRow('Telefon:', _vehicleOwner!.owner.phoneNumber!),
                      ] else
                        const Text('Vozač nije pronađen',
                            style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: Column(
                    children: [
                      Container(
                        height: 200,
                        decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(8)),
                        child: log.imageUrl != null
                            ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(log.imageUrl!, fit: BoxFit.cover))
                            : const Center(
                            child: Icon(Icons.image_not_supported,
                                size: 48, color: Colors.grey)),
                      ),
                      const SizedBox(height: 16),
                      if (widget.log.status.toLowerCase() == 'pendingreview') ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : () => _review(true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF27AE60),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Potvrdi prekršaj i pošalji obavijest'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _isLoading ? null : () => _review(false),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                            child: const Text('Odbaci'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Dodaj komentar (optional)',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Back')),
                      ),
                    ],
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

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}