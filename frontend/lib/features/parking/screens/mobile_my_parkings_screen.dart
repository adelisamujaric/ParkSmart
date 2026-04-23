import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../models/parking_reservations.dart';
import '../models/parking_ticket.dart';
import '../services/parking_lot_service.dart';

class MyParkingsScreen extends StatefulWidget {
  const MyParkingsScreen({super.key});

  @override
  State<MyParkingsScreen> createState() => _MyParkingsScreenState();
}

class _MyParkingsScreenState extends State<MyParkingsScreen> {
  Timer? _uiTimer;
  Timer? _dataTimer;

  final _service = ParkingLotService();
  List<ParkingTicket> _tickets = [];
  List<ParkingReservation> _reservations = [];
  bool _isLoading = true;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _uiTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    _dataTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) _loadData();
    });
  }

  @override
  void dispose() {
    _uiTimer?.cancel();
    _dataTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final tickets = await _service.getMyTickets();
      final reservations = await _service.getMyReservations();
      setState(() {
        _tickets = tickets;
        _reservations = reservations;
        _isLoading = false;
      });
    } catch (e) {
      print('MY PARKINGS ERROR: $e');
      setState(() => _isLoading = false);
    }
  }

  List<ParkingTicket> get _activeTickets =>
      _tickets.where((t) => t.status == 'active').toList();

  List<ParkingTicket> get _completedTickets =>
      _tickets.where((t) => t.status != 'active').toList();

  List<ParkingReservation> get _activeReservations =>
      _reservations.where((r) => r.status == 0 || r.status == 1).toList();

  List<ParkingReservation> get _completedReservations =>
      _reservations.where((r) => r.status == 2 || r.status == 4).toList();

  int get _allBadge => _activeTickets.length + _activeReservations.length;

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1A5276);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F4),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: const Text('ParkSmart',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        automaticallyImplyLeading: false,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _tabButton('Aktivno', 0, primaryBlue, badge: _allBadge),
                const SizedBox(width: 8),
                _tabButton('Završeno', 1, primaryBlue),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: _buildContent(primaryBlue),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ParkSmartBottomNav(currentIndex: 2),
    );
  }

  Widget _tabButton(String label, int index, Color primaryBlue, {int badge = 0}) {
    final isSelected = _tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _tabIndex = index),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? primaryBlue : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
          if (badge > 0)
            Positioned(
              right: -6,
              top: -6,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildContent(Color primaryBlue) {
    switch (_tabIndex) {
      case 0:
        return _buildActiveList(primaryBlue);
      case 1:
        return _buildCompletedList(primaryBlue);
      default:
        return const SizedBox();
    }
  }

  Widget _buildActiveList(Color primaryBlue) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: primaryBlue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primaryBlue,
              tabs: [
                Tab(text: 'Tiketi (${_activeTickets.length})'),
                Tab(text: 'Rezervacije (${_activeReservations.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _activeTickets.isEmpty
                    ? _emptyState('Nema aktivnih tiketa.')
                    : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _activeTickets
                      .map((t) => _ticketCard(t, primaryBlue))
                      .toList(),
                ),
                _activeReservations.isEmpty
                    ? _emptyState('Nema aktivnih rezervacija.')
                    : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _activeReservations
                      .map((r) => _reservationCard(r, primaryBlue))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedList(Color primaryBlue) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: primaryBlue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primaryBlue,
              tabs: [
                Tab(text: 'Tiketi (${_completedTickets.length})'),
                Tab(text: 'Rezervacije (${_completedReservations.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _completedTickets.isEmpty
                    ? _emptyState('Nema završenih tiketa.')
                    : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _completedTickets
                      .map((t) => _ticketCard(t, primaryBlue))
                      .toList(),
                ),
                _completedReservations.isEmpty
                    ? _emptyState('Nema završenih rezervacija.')
                    : ListView(
                  padding: const EdgeInsets.all(16),
                  children: _completedReservations
                      .map((r) => _reservationCard(r, primaryBlue))
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_car_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _sectionTitle(String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(title,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _ticketCard(ParkingTicket ticket, Color primaryBlue) {
    final isActive = ticket.status == 'active';
    final isExpired = ticket.endTime != null &&
        ticket.endTime!.isBefore(DateTime.now());
    final duration = ticket.exitTime != null
        ? ticket.exitTime!.difference(ticket.entryTime)
        : DateTime.now().difference(ticket.entryTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(ticket.lotName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),


              if (isActive && ticket.endTime != null)
                Text(
                  isExpired ? 'Isteklo' : 'Ističe za: ${_timeRemaining(ticket.endTime!)}',
                  style: TextStyle(
                      color: isExpired ? Colors.red : Colors.orange,
                      fontSize: 12),
                ),


            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.location_on, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(ticket.lotAddress,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.local_parking, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('Mjesto: ${ticket.spotNumber}',
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ]),
          const SizedBox(height: 4),
          Text('Vrijeme ulaska: ${_formatDateTime(ticket.entryTime)}',
              style: const TextStyle(fontSize: 13)),
          if (ticket.exitTime != null)
            Text('Vrijeme izlaska: ${_formatDateTime(ticket.exitTime!)}',
                style: const TextStyle(fontSize: 13)),
          Text('Trajanje: ${duration.inHours}h ${duration.inMinutes % 60}min',
              style: const TextStyle(fontSize: 13)),
          if (ticket.totalPrice != null)
            Text('Cijena: ${ticket.totalPrice!.toStringAsFixed(2)} KM',
                style: const TextStyle(fontSize: 13)),

          if (isActive && !isExpired && ticket.endTime != null) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => _showExtendDialog(ticket),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Produži'),
              ),
            ),
          ],


          if (isActive && isExpired) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/payments'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Plati odmah'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _reservationCard(ParkingReservation reservation, Color primaryBlue) {
    final isExpired = reservation.endTime.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(reservation.lotName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              Text(
                isExpired ? 'Isteklo' : 'Ističe za: ${_timeRemainingReadable(reservation.endTime)}',
                style: TextStyle(
                    color: isExpired ? Colors.red : Colors.orange,
                    fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.location_on, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(reservation.lotAddress,
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
            ),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.local_parking, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('Mjesto: ${reservation.spotNumber}',
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ]),
          const SizedBox(height: 4),
          Row(children: [
            const Icon(Icons.directions_car, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text('Tablica: ${reservation.licensePlate}',
                style: const TextStyle(fontSize: 13, color: Colors.grey)),
          ]),
          const SizedBox(height: 4),
          Text('Vrijedi od: ${_formatDateTime(reservation.startTime)}',
              style: const TextStyle(fontSize: 13)),
          Text('Vrijedi do: ${_formatDateTime(reservation.endTime)}',
              style: const TextStyle(fontSize: 13)),
          Text('Cijena: ${reservation.totalPrice.toStringAsFixed(2)} KM',
              style: const TextStyle(fontSize: 13)),
          if (isExpired) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/payments'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Plati odmah'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _showExtendDialog(ParkingTicket ticket) async {
    const primaryBlue = Color(0xFF1A5276);
    int selectedMinutes = 30;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Produži parking'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Odaberi dodatno vrijeme:',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                ...[15, 30, 60, 120].map((minutes) => RadioListTile<int>(
                  value: minutes,
                  groupValue: selectedMinutes,
                  onChanged: (val) =>
                      setDialogState(() => selectedMinutes = val!),
                  title: Text(minutes < 60
                      ? '$minutes minuta'
                      : '${minutes ~/ 60}h ${minutes % 60 == 0 ? '' : '${minutes % 60}min'}'),
                  activeColor: primaryBlue,
                )),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Odustani'),
              ),
              ElevatedButton(
                onPressed: () async {
                  await _confirmExtend(ticket, selectedMinutes);
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Potvrdi'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmExtend(ParkingTicket ticket, int minutes) async {
    try {
      final dio = DioClient.instance;
      await dio.post(
        '${ApiConstants.parkingServiceBase}/api/ParkingTicket/${ticket.id}/extend',
        queryParameters: {'additionalMinutes': minutes},
      );
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Parking uspješno produžen!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Greška: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  String _formatDateTime(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _timeRemaining(DateTime endTime) {
    final diff = endTime.difference(DateTime.now());
    if (diff.isNegative) return 'Isteklo';
    return '${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}';
  }

  String _timeRemainingReadable(DateTime endTime) {
    final diff = endTime.difference(DateTime.now());
    if (diff.isNegative) return 'Isteklo';
    if (diff.inDays > 0) return '${diff.inDays} dana';
    if (diff.inHours > 0) return '${diff.inHours}h ${diff.inMinutes % 60}min';
    return '${diff.inMinutes}min ${diff.inSeconds % 60}s';
  }
}