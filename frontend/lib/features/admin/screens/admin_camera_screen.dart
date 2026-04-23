import 'package:flutter/material.dart';
import '../../detections/models/camera.dart';
import '../../detections/services/detection_service.dart';
import '../../parking/models/parking_lot.dart';
import '../../parking/services/parking_lot_service.dart';

class KamereScreen extends StatefulWidget {
  const KamereScreen({super.key});

  @override
  State<KamereScreen> createState() => _KamereScreenState();
}

class _KamereScreenState extends State<KamereScreen> {
  final _detectionService = DetectionService();
  List<Camera> _cameras = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCameras();
  }

  Future<void> _loadCameras() async {
    setState(() => _isLoading = true);
    try {
      final cameras = await _detectionService.getCameras();
      setState(() => _cameras = cameras);
    } catch (e) {
      setState(() => _cameras = []);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active': return const Color(0xFF27AE60);
      case 'offline': return const Color(0xFFE74C3C);
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status.toLowerCase()) {
      case 'active': return 'Aktivna';
      case 'offline': return 'Offline';
      default: return status;
    }
  }

  String _cameraTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'entry': return 'Ulaz';
      case 'exit': return 'Izlaz';
      case 'drone': return 'Dron';
      default: return type;
    }
  }

  String _positionLabel(String position) {
    switch (position.toLowerCase()) {
      case 'entry': return 'Ulaz';
      case 'exit': return 'Izlaz';
      default: return position;
    }
  }

  int get _activeCount => _cameras.where((c) => c.status.toLowerCase() == 'active').length;
  int get _offlineCount => _cameras.where((c) => c.status.toLowerCase() == 'offline').length;

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1A5276);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Stat kartice + dugme
        Row(
          children: [
            _StatCard(
              label: 'Aktivne kamere',
              value: '${_activeCount}',
              color: const Color(0xFF27AE60),
              icon: Icons.videocam,
            ),
            const SizedBox(width: 16),
            _StatCard(
              label: 'Offline kamere',
              value: '${_offlineCount}',
              color: const Color(0xFFE74C3C),
              icon: Icons.error_outline,
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) => _AddCameraDialog(onCameraAdded: _loadCameras),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Dodaj kameru'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
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
                      Expanded(child: Center(child: Text('Kamera', style: TextStyle(fontWeight: FontWeight.bold)))),
                      Expanded(child: Center(child: Text('Zona', style: TextStyle(fontWeight: FontWeight.bold)))),
                      Expanded(child: Center(child: Text('Pozicija', style: TextStyle(fontWeight: FontWeight.bold)))),
                      Expanded(child: Center(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)))),
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
                      children: _cameras.map((camera) {
                        return TableRow(
                          decoration: const BoxDecoration(
                            border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
                          ),
                          children: [
                            TableCell(
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: Text('#${camera.number}')),
                              ),
                            ),
                            TableCell(
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: Text(camera.lotName)),
                              ),
                            ),
                            TableCell(
                              verticalAlignment: TableCellVerticalAlignment.middle,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: Text(_cameraTypeLabel(camera.cameraType))),
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
                                          color: _statusColor(camera.status),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(_statusLabel(camera.status)),
                                    ],
                                  ),
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
                                        builder: (context) => _CameraPreviewDialog(
                                          camera: camera,
                                          onStatusChanged: _loadCameras,
                                        ),
                                      );
                                    },
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

class _CameraPreviewDialog extends StatelessWidget {
  final Camera camera;
  final VoidCallback onStatusChanged;
  final _detectionService = DetectionService();

  _CameraPreviewDialog({required this.camera, required this.onStatusChanged});

  String _cameraTypeLabel(String type) {
    switch (type.toLowerCase()) {
      case 'entry': return 'Ulaz';
      case 'exit': return 'Izlaz';
      default: return type;
    }
  }

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
                        'KAMERA #${camera.number}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(camera.lotName, style: const TextStyle(color: Colors.grey)),
                      const SizedBox(height: 16),
                      const Text('Status:', style: TextStyle(color: Colors.grey)),
                      Text(
                        camera.status.toLowerCase() == 'active' ? 'Aktivno' : 'Offline',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      const Text('Tip:', style: TextStyle(color: Colors.grey)),
                      Text(
                        _cameraTypeLabel(camera.cameraType),
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
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
                      await _detectionService.updateCameraStatus(camera.id, 0);
                      Navigator.pop(context);
                      onStatusChanged();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF27AE60),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    child: const Text('Uključi'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      await _detectionService.updateCameraStatus(camera.id, 1);
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
                ),
                const SizedBox(width: 12),
                TextButton(
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
class _AddCameraDialog extends StatefulWidget {
  final VoidCallback onCameraAdded;

  const _AddCameraDialog({required this.onCameraAdded});

  @override
  State<_AddCameraDialog> createState() => _AddCameraDialogState();
}

class _AddCameraDialogState extends State<_AddCameraDialog> {
  final _numberController = TextEditingController();
  final _detectionService = DetectionService();
  final _parkingLotService = ParkingLotService();
  bool _isLoading = false;
  bool _isLoadingLots = true;
  String? _errorMessage;
  List<ParkingLot> _lots = [];
  ParkingLot? _selectedLot;
  int _selectedCameraType = 0; // 0 = Entry, 1 = Exit

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
    if (_numberController.text.isEmpty || _selectedLot == null) {
      setState(() => _errorMessage = 'Popunite sva polja.');
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await _detectionService.createCamera({
        'number': int.parse(_numberController.text),
        'lotId': _selectedLot!.id,
        'cameraType': _selectedCameraType,
        'position': _selectedCameraType,
      });
      Navigator.pop(context);
      widget.onCameraAdded();
    } catch (e) {
      setState(() => _errorMessage = 'Greška pri dodavanju kamere.');
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
            const Text('Dodaj kameru', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            TextField(
              controller: _numberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Broj kamere',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: primaryBlue),
                ),
              ),
            ),
            const SizedBox(height: 16),
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
            DropdownButtonFormField<int>(
              value: _selectedCameraType,
              decoration: InputDecoration(
                labelText: 'Tip kamere',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: primaryBlue),
                ),
              ),
              items: const [
                DropdownMenuItem(value: 0, child: Text('Ulaz (Entry)')),
                DropdownMenuItem(value: 1, child: Text('Izlaz (Exit)')),
              ],
              onChanged: (value) => setState(() => _selectedCameraType = value!),
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