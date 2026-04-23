import 'dart:async';
import 'package:flutter/material.dart';
import '../models/parking_lot.dart';
import '../models/parking_spot.dart';
import '../services/parking_lot_service.dart';

class ParkingZoneScreen extends StatefulWidget {
  const ParkingZoneScreen({super.key});

  @override
  State<ParkingZoneScreen> createState() => _ParkingZoneScreenState();
}

class _ParkingZoneScreenState extends State<ParkingZoneScreen> {
  final _service = ParkingLotService();

  List<ParkingLot> _lots = [];
  ParkingLot? _selectedLot;
  List<ParkingSpot> _spots = [];
  bool _isLoadingLots = true;
  bool _isLoadingSpots = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _loadLots();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadLots() async {
    try {
      final lots = await _service.getAll();
      setState(() {
        _lots = lots;
        _isLoadingLots = false;
      });
      if (lots.isNotEmpty) {
        _selectLot(lots.first);
      }
    } catch (_) {
      setState(() => _isLoadingLots = false);
    }
  }

  void _selectLot(ParkingLot lot) {
    _pollingTimer?.cancel();
    setState(() => _selectedLot = lot);
    _loadSpots();
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) => _loadSpots());
  }

  Future<void> _loadSpots() async {
    if (_selectedLot == null) return;
    setState(() => _isLoadingSpots = true);
    try {
      final spots = await _service.getSpotsByLotId(_selectedLot!.id);
      spots.sort((a, b) => _naturalCompare(a.spotNumber, b.spotNumber));
      setState(() => _spots = spots);
    } catch (_) {}
    finally {
      setState(() => _isLoadingSpots = false);
    }
  }

  int _naturalCompare(String a, String b) {
    final regExp = RegExp(r'(\D+)(\d+)');
    final matchA = regExp.firstMatch(a);
    final matchB = regExp.firstMatch(b);
    if (matchA != null && matchB != null) {
      final letterCompare = matchA.group(1)!.compareTo(matchB.group(1)!);
      if (letterCompare != 0) return letterCompare;
      return int.parse(matchA.group(2)!).compareTo(int.parse(matchB.group(2)!));
    }
    return a.compareTo(b);
  }

  Color _spotColor(int status, int type) {
    if (type == 3) return Colors.grey.shade300;
    switch (status) {
      case 0: return const Color(0xFFA8D5A2);
      case 1: return const Color(0xFFE8A0A0);
      case 2: return const Color(0xFFE8C880);
      case 3: return Colors.grey.shade300;
      default: return Colors.grey.shade300;
    }
  }

  Color _spotTextColor(int status) {
    switch (status) {
      case 0: return const Color(0xFF2E7D32);
      case 1: return const Color(0xFFC62828);
      case 2: return const Color(0xFFE65100);
      case 3: return Colors.grey;
      default: return Colors.grey;
    }
  }

  String _statusLabel(int status) {
    switch (status) {
      case 0: return 'Slobodno';
      case 1: return 'Zauzeto';
      case 2: return 'Rezervisano';
      case 3: return 'Van usluge';
      default: return '–';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingLots) return const Center(child: CircularProgressIndicator());

    final occupied = _spots.where((s) => s.status == 1).length;
    final reserved = _spots.where((s) => s.status == 2).length;
    final available = _spots.where((s) => s.status == 0).length;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gornji red — dropdown + info kartica
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dropdown
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Odaberi zonu:',
                      style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<ParkingLot>(
                        value: _selectedLot,
                        items: _lots.map((lot) => DropdownMenuItem(
                          value: lot,
                          child: Text(lot.name),
                        )).toList(),
                        onChanged: (lot) {
                          if (lot != null) _selectLot(lot);
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Info kartica
              if (_selectedLot != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _InfoRow('Odabrana zona:', _selectedLot!.name),
                      _InfoRow('Broj parking mjesta:', '${_spots.length}'),
                      _InfoRowDot('Broj zauzetih mjesta:', '$occupied',
                          const Color(0xFFE8A0A0), const Color(0xFFC62828)),
                      _InfoRowDot('Broj rezervisanih mjesta:', '$reserved',
                          const Color(0xFFE8C880), const Color(0xFFE65100)),
                      _InfoRowDot('Broj slobodnih mjesta:', '$available',
                          const Color(0xFFA8D5A2), const Color(0xFF2E7D32)),
                    ],
                  ),
                ),

              const SizedBox(width: 24),
              if (_selectedLot != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Detalji zone',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      const SizedBox(height: 12),
                      _InfoRow('Cijena po minuti:',
                          '${_selectedLot!.ratePerMinute.toStringAsFixed(2)} KM'),
                      if (_selectedLot!.reservationRatePerMinute != null)
                        _InfoRow('Cijena rezervacije:',
                            '${_selectedLot!.reservationRatePerMinute!.toStringAsFixed(2)} KM'),
                      _InfoRow('Radno vrijeme:',
                          '${_selectedLot!.openTime.substring(0, 5)} – ${_selectedLot!.closeTime.substring(0, 5)}'),
                      _InfoRow('Status:',
                          _selectedLot!.isActive ? '✅ Aktivna' : '❌ Neaktivna'),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 24),
          // Grid spotova — fiksna visina sa okvirom
          Container(
            height: 500,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade400, width: 1.5),
            ),
            child: _spots.isEmpty
                ? const Center(child: Text('Nema spotova za ovu zonu'))
                : GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 120,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: _spots.length,
              itemBuilder: (context, index) {
                final spot = _spots[index];
                return _SpotCard(
                  spot: spot,
                  color: _spotColor(spot.status, spot.type),
                  textColor: _spotTextColor(spot.status),
                  statusLabel: _statusLabel(spot.status),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          // Legenda ispod okvira
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _LegendDot(const Color(0xFFA8D5A2), 'Slobodno'),
                    const SizedBox(width: 16),
                    _LegendDot(const Color(0xFFE8A0A0), 'Zauzeto'),
                    const SizedBox(width: 16),
                    _LegendDot(const Color(0xFFE8C880), 'Rezervisano'),
                    const SizedBox(width: 16),
                    _LegendDot(Colors.grey, 'Van usluge'),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _LegendBadge('♿', const Color(0xFF1565C0), 'Invalidsko mjesto'),
                    const SizedBox(width: 16),
                    _LegendBadge('R', const Color(0xFF27AE60), 'Rezervabilno mjesto'),
                    const Spacer(),
                    if (_isLoadingSpots)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---- Info row ----
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
        ],
      ),
    );
  }
}

// ---- Info row sa dot indikatorom ----
class _InfoRowDot extends StatelessWidget {
  final String label;
  final String value;
  final Color dotColor;
  final Color textColor;
  const _InfoRowDot(this.label, this.value, this.dotColor, this.textColor);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text('$label ', style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Text(value,
              style: TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: textColor)),
          const SizedBox(width: 6),
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
        ],
      ),
    );
  }
}

// ---- Legenda dot ----
class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot(this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }
}

// ---- Legenda badge ----
class _LegendBadge extends StatelessWidget {
  final String symbol;
  final Color color;
  final String label;
  const _LegendBadge(this.symbol, this.color, this.label);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            symbol,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13, color: Colors.grey)),
      ],
    );
  }
}

// ---- Spot kartica ----
class _SpotCard extends StatelessWidget {
  final ParkingSpot spot;
  final Color color;
  final Color textColor;
  final String statusLabel;

  const _SpotCard({
    required this.spot,
    required this.color,
    required this.textColor,
    required this.statusLabel,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = spot.type == 1;
    final isReservable = spot.isReservable && spot.status == 0;

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        border: isReservable
            ? Border.all(color: const Color(0xFF27AE60), width: 2)
            : Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  spot.spotNumber,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusLabel,
                  style: TextStyle(color: textColor, fontSize: 10),
                  textAlign: TextAlign.center,
                ),
                if (spot.floor != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Sprat ${spot.floor}',
                    style: TextStyle(
                        color: textColor.withOpacity(0.7), fontSize: 9),
                  ),
                ],
              ],
            ),
          ),
          if (isDisabled)
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: const Color(0xFF1565C0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('♿', style: TextStyle(fontSize: 20)),
              ),
            ),
          if (isReservable)
            Positioned(
              top: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFF27AE60),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'R',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}