import 'package:flutter/material.dart';
import '../../detections/models/drone.dart';
import '../../detections/services/detection_service.dart';
import '../../parking/models/parking_lot.dart';
import '../../parking/services/parking_lot_service.dart';

class DranoviScreen extends StatefulWidget {
  const DranoviScreen({super.key});

  @override
  State<DranoviScreen> createState() => _DranoviScreenState();
}

class _DranoviScreenState extends State<DranoviScreen> {
  final _detectionService = DetectionService();
  List<Drone> _drones = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDrones();
  }

  Future<void> _loadDrones() async {
    setState(() => _isLoading = true);
    try {
      final drones = await _detectionService.getDrones();
      setState(() => _drones = drones);
    } catch (e) {
      setState(() => _drones = []);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active': return const Color(0xFF27AE60);
      case 'charging': return const Color(0xFFF39C12);
      case 'inactive': return const Color(0xFFE74C3C);
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'active': return 'Aktivan';
      case 'charging': return 'Na punjenju';
      case 'inactive': return 'Neaktivan';
      default: return status;
    }
  }

  int get _activeCount => _drones.where((d) => d.status.toLowerCase() == 'active').length;
  int get _chargingCount => _drones.where((d) => d.status.toLowerCase() == 'charging').length;
  int get _inactiveCount => _drones.where((d) => d.status.toLowerCase() == 'inactive').length;

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1A5276);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stat kartice
        Row(
          children: [
            _StatCard(label: 'Aktivni dronovi', value: _activeCount.toString(), color: const Color(0xFF27AE60), icon: Icons.airplanemode_active),
            const SizedBox(width: 16),
            _StatCard(label: 'U punjenju', value: _chargingCount.toString(), color: const Color(0xFFF39C12), icon: Icons.battery_charging_full),
            const SizedBox(width: 16),
            _StatCard(label: 'Neaktivni', value: _inactiveCount.toString(), color: const Color(0xFFE74C3C), icon: Icons.airplanemode_inactive),
          ],
        ),
        const SizedBox(height: 16),
        // Dodaj dron button
        Align(
          alignment: Alignment.centerRight,
          child: ElevatedButton.icon(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => _AddDroneDialog(onDroneAdded: _loadDrones),
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Dodaj dron'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Tabela
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
              children: [
                // Header
                Container(
                  height: 48,
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
                  ),
                  child: Row(
                    children: const [
                      Expanded(child: Center(child: Text('Drone', style: TextStyle(fontWeight: FontWeight.bold)))),
                      Expanded(child: Center(child: Text('Zona', style: TextStyle(fontWeight: FontWeight.bold)))),
                      Expanded(child: Center(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)))),
                      Expanded(child: Center(child: Text('Nivo baterije', style: TextStyle(fontWeight: FontWeight.bold)))),
                      Expanded(child: Center(child: Text('Do punjenja', style: TextStyle(fontWeight: FontWeight.bold)))),
                      Expanded(child: Center(child: Text('Akcija', style: TextStyle(fontWeight: FontWeight.bold)))),
                    ],
                  ),
                ),
                // Rows
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
                      children: _drones.map((drone) {
                        return TableRow(
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
                          ),
                          children: [
                            TableCell(
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: Text('#${drone.number}')),
                              ),
                            ),
                            TableCell(
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: Text(drone.lotName)),
                              ),
                            ),
                            TableCell(
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        width: 10,
                                        height: 10,
                                        decoration: BoxDecoration(
                                          color: _statusColor(drone.status),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(_statusLabel(drone.status)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            TableCell(
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: Text('${drone.batteryLevel}%')),
                              ),
                            ),
                            TableCell(
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: Text(_calculateTimeToCharge(drone.batteryLevel, drone.status))),
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
                                      builder: (context) => _DronePreviewDialog(drone: drone, onStatusChanged: _loadDrones),
                                    );},
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: primaryBlue,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            ),
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _StatCard({required this.label, required this.value, required this.color, required this.icon});


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
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                Text(value, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
//---------------------------------------------------------------------------------------------------------
class _DronePreviewDialog extends StatelessWidget {
  final Drone drone;
  final VoidCallback onStatusChanged;
  final _detectionService = DetectionService();

  _DronePreviewDialog({required this.drone, required this.onStatusChanged});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 600,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Lijevo - info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DRON #${drone.number}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(drone.lotName, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      _InfoRow('Status:', drone.status),
                      const SizedBox(height: 8),
                      _InfoRow('Nivo baterije:', '${drone.batteryLevel}%'),
                      const SizedBox(height: 8),
                      _InfoRow('Vrijeme do punjenja:', _calculateTimeToCharge(drone.batteryLevel, drone.status)),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Desno - real-time pregled
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Real-time Pregled', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          height: 160,
                          color: Colors.grey.shade300,
                          child: const Center(
                            child: Icon(Icons.videocam_off, size: 48, color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          Text('Brzina: '),
                          Text('10 km/h', style: TextStyle(fontWeight: FontWeight.bold)),
                          SizedBox(width: 16),
                          Text('Visina: '),
                          Text('10 m', style: TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Dugmad
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _detectionService.updateDroneStatus(drone.id, 0);
                      Navigator.pop(context);
                      onStatusChanged();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Pošalji u patrolu'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _detectionService.updateDroneStatus(drone.id, 1);
                      Navigator.pop(context);
                      onStatusChanged();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF39C12),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Pošalji na punjenje'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _detectionService.updateDroneStatus(drone.id, 2);
                      Navigator.pop(context);
                      onStatusChanged();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFE74C3C),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Isključi'),
                  ),
                ),TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Back'),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ],
    );
  }
}
//-------------------------------------------------------------------------------------------------
class _AddDroneDialog extends StatefulWidget {
  final VoidCallback onDroneAdded;

  const _AddDroneDialog({required this.onDroneAdded});

  @override
  State<_AddDroneDialog> createState() => _AddDroneDialogState();
}

class _AddDroneDialogState extends State<_AddDroneDialog> {
  final _numberController = TextEditingController();
  final _batteryController = TextEditingController();
  final _detectionService = DetectionService();
  final _parkingLotService = ParkingLotService();
  bool _isLoading = false;
  bool _isLoadingLots = true;
  String? _errorMessage;
  List<ParkingLot> _lots = [];
  ParkingLot? _selectedLot;

  @override
  void initState() {
    super.initState();
    _loadLots();
  }

  Future<void> _loadLots() async {
    try {
      final lots = await _parkingLotService.getAll();
      setState(() => _lots = lots);
    } catch (e) {
      setState(() => _lots = []);
    } finally {
      setState(() => _isLoadingLots = false);
    }
  }

  Future<void> _submit() async {
    if (_numberController.text.isEmpty || _selectedLot == null || _batteryController.text.isEmpty) {
      setState(() => _errorMessage = 'Popunite sva polja.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await _detectionService.createDrone({
        'number': int.parse(_numberController.text),
        'lotId': _selectedLot!.id,
        'batteryLevel': int.parse(_batteryController.text),
      });
      Navigator.pop(context);
      widget.onDroneAdded();
    } catch (e) {
      setState(() => _errorMessage = 'Greška pri dodavanju drona.');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1A5276);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Dodaj dron', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: _numberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Broj drona',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: primaryBlue),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Zona dropdown
            _isLoadingLots
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<ParkingLot>(
              value: _selectedLot,
              hint: const Text('Odaberi zonu'),
              decoration: InputDecoration(
                labelText: 'Zona',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: primaryBlue),
                ),
              ),
              items: _lots.map((lot) => DropdownMenuItem(
                value: lot,
                child: Text(lot.name),
              )).toList(),
              onChanged: (value) => setState(() => _selectedLot = value),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _batteryController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Nivo baterije (%)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: primaryBlue),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (_errorMessage != null)
              Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Dodaj'),
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
    );
  }
}
String _calculateTimeToCharge(int batteryLevel, String status) {
  if (status.toLowerCase() != 'active') return '–';
  final minutes = (batteryLevel / 100 * 120).round();
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:00';
}