import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../../core/storage/token_storage.dart';
import '../../parking/models/parking_ticket.dart';
import '../../parking/models/parking_violation.dart';
import '../../parking/services/parking_lot_service.dart';
import '../services/payment_service.dart';
import '../../parking/models/parking_reservations.dart';

class PaymentsScreen extends StatefulWidget {
  const PaymentsScreen({super.key});

  @override
  State<PaymentsScreen> createState() => _PaymentsScreenState();
}

final _paymentService = PaymentService();

class _PaymentsScreenState extends State<PaymentsScreen> {
  Timer? _timer;
  final _service = ParkingLotService();
  List<ParkingTicket> _unpaidTickets = [];
  List<ParkingTicket> _paidTickets = [];
  List<ParkingViolation> _violations = [];
  List<ParkingReservation> _unpaidReservations = [];
  List<ParkingReservation> _paidReservations = [];
  bool _isLoading = true;
  int _tabIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      setState(() {});
      if (DateTime.now().second == 0) _loadData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final userId = await TokenStorage.getUserId();
      final tickets = await _service.getMyTickets();
      final reservations = await _service.getMyReservations();
      List<ParkingViolation> violations = [];
      if (userId != null) {
        violations = await _service.getViolationsByUserId(userId);
      }
      setState(() {
        _unpaidTickets = tickets.where((t) => t.status == 'pendingpayment').toList();
        _paidTickets = tickets.where((t) => t.status == 'paid' || t.status == 'closed').toList();
        _unpaidReservations = reservations.where((r) => r.status == 4).toList();
        _paidReservations = reservations.where((r) => r.status == 2).toList();
        _violations = violations;
        _isLoading = false;
      });
    } catch (e) {
      print('PAYMENTS ERROR: $e');
      setState(() => _isLoading = false);
    }
  }

  int get _unpaidCount =>
      _unpaidTickets.length +
          _unpaidReservations.length +
          _violations.where((v) => !v.isResolved).length;

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
                _tabButton('Neplaćeno', 0, primaryBlue, badge: _unpaidCount),
                const SizedBox(width: 8),
                _tabButton('Plaćeno', 1, primaryBlue),
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
      bottomNavigationBar: ParkSmartBottomNav(currentIndex: 1),
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
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? primaryBlue : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.w600,
                fontSize: 13,
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
        return _buildUnpaidTabs(primaryBlue);
      case 1:
        return _buildPaidTabs(primaryBlue);
      default:
        return const SizedBox();
    }
  }

  Widget _buildUnpaidTabs(Color primaryBlue) {
    final unpaidViolations = _violations.where((v) => !v.isResolved).toList();
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: primaryBlue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primaryBlue,
              tabs: [
                Tab(text: 'Tiketi (${_unpaidTickets.length})'),
                Tab(text: 'Rezervacije (${_unpaidReservations.length})'),
                Tab(text: 'Prekršaji (${unpaidViolations.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _unpaidTickets.isEmpty
                    ? _emptyState('Nema neplaćenih tiketa.')
                    : Scrollbar(
                  thumbVisibility: true,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: _unpaidTickets
                        .map((t) => _ticketPayCard(t, primaryBlue))
                        .toList(),
                  ),
                ),
                _unpaidReservations.isEmpty
                    ? _emptyState('Nema neplaćenih rezervacija.')
                    : Scrollbar(
                  thumbVisibility: true,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: _unpaidReservations
                        .map((r) => _reservationPayCard(r, primaryBlue))
                        .toList(),
                  ),
                ),
                unpaidViolations.isEmpty
                    ? _emptyState('Nema neplaćenih prekršaja.')
                    : Scrollbar(
                  thumbVisibility: true,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: unpaidViolations
                        .map((v) => _violationCard(v, false, primaryBlue))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaidTabs(Color primaryBlue) {
    final paidViolations = _violations.where((v) => v.isResolved).toList();
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: TabBar(
              labelColor: primaryBlue,
              unselectedLabelColor: Colors.grey,
              indicatorColor: primaryBlue,
              tabs: [
                Tab(text: 'Tiketi (${_paidTickets.length})'),
                Tab(text: 'Rezervacije (${_paidReservations.length})'),
                Tab(text: 'Prekršaji (${paidViolations.length})'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _paidTickets.isEmpty
                    ? _emptyState('Nema plaćenih tiketa.')
                    : Scrollbar(
                  thumbVisibility: true,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _paidTickets.length,
                    itemBuilder: (context, index) =>
                        _ticketPaidCard(_paidTickets[index], primaryBlue),
                  ),
                ),
                _paidReservations.isEmpty
                    ? _emptyState('Nema plaćenih rezervacija.')
                    : Scrollbar(
                  thumbVisibility: true,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: _paidReservations
                        .map((r) => _reservationPaidCard(r, primaryBlue))
                        .toList(),
                  ),
                ),
                paidViolations.isEmpty
                    ? _emptyState('Nema plaćenih prekršaja.')
                    : Scrollbar(
                  thumbVisibility: true,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: paidViolations
                        .map((v) => _violationCard(v, true, primaryBlue))
                        .toList(),
                  ),
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
          const Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey),
          const SizedBox(height: 12),
          Text(message, style: const TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _ticketPayCard(ParkingTicket ticket, Color primaryBlue) {
    final duration = ticket.exitTime != null
        ? ticket.exitTime!.difference(ticket.entryTime)
        : Duration.zero;
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
              const Text('Parking naplata',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              if (ticket.paymentDeadline != null)
                Text('Rok: ${_timeRemaining(ticket.paymentDeadline!)}',
                    style: const TextStyle(color: Colors.red, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 4),
          Text(ticket.lotName,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          _payRow('Mjesto', ticket.spotNumber),
          _payRow('Vrijeme ulaska', _formatTime(ticket.entryTime)),
          if (ticket.exitTime != null)
            _payRow('Vrijeme izlaska', _formatTime(ticket.exitTime!)),
          _payRow('Trajanje',
              '${duration.inHours}h ${duration.inMinutes % 60}min'),
          if (ticket.totalPrice != null)
            _payRow('Cijena', '${ticket.totalPrice!.toStringAsFixed(2)} KM'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(ticket.licensePlate,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, letterSpacing: 1.2)),
              ),
              ElevatedButton(
                onPressed: () => _payTicket(ticket),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Plati'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _ticketPaidCard(ParkingTicket ticket, Color primaryBlue) {
    final duration = ticket.exitTime != null
        ? ticket.exitTime!.difference(ticket.entryTime)
        : Duration.zero;
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Plaćeno',
                    style: TextStyle(color: Colors.green, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _payRow('Mjesto', ticket.spotNumber),
          _payRow('Tablica', ticket.licensePlate),
          _payRow('Vrijeme ulaska', _formatTime(ticket.entryTime)),
          if (ticket.exitTime != null)
            _payRow('Vrijeme izlaska', _formatTime(ticket.exitTime!)),
          _payRow('Trajanje', '${duration.inHours}h ${duration.inMinutes % 60}min'),
          if (ticket.totalPrice != null)
            _payRow('Plaćeno', '${ticket.totalPrice!.toStringAsFixed(2)} KM'),
        ],
      ),
    );
  }

  Widget _reservationPayCard(ParkingReservation reservation, Color primaryBlue) {
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
          const Text('Rezervacija naplata',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 4),
          Text(reservation.lotName,
              style: const TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.location_on, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(reservation.lotAddress,
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ),
          ]),
          const SizedBox(height: 4),
          _payRow('Mjesto', reservation.spotNumber),
          _payRow('Tablica', reservation.licensePlate),
          _payRow('Vrijedi od', _formatDateTime(reservation.startTime)),
          _payRow('Vrijedi do', _formatDateTime(reservation.endTime)),
          _payRow('Cijena', '${reservation.totalPrice.toStringAsFixed(2)} KM'),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(reservation.licensePlate,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, letterSpacing: 1.2)),
              ),
              ElevatedButton(
                onPressed: () => _payReservation(reservation),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Plati'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _reservationPaidCard(ParkingReservation reservation, Color primaryBlue) {
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('Plaćeno',
                    style: TextStyle(color: Colors.green, fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.location_on, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Expanded(
              child: Text(reservation.lotAddress,
                  style: const TextStyle(fontSize: 13, color: Colors.grey)),
            ),
          ]),
          const SizedBox(height: 4),
          _payRow('Mjesto', reservation.spotNumber),
          _payRow('Tablica', reservation.licensePlate),
          _payRow('Vrijedi od', _formatDateTime(reservation.startTime)),
          _payRow('Vrijedi do', _formatDateTime(reservation.endTime)),
          _payRow('Plaćeno', '${reservation.totalPrice.toStringAsFixed(2)} KM'),
        ],
      ),
    );
  }

  Widget _violationCard(ParkingViolation v, bool isPaid, Color primaryBlue) {
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
              const Text('Prekršaj',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPaid ? Colors.green.shade100 : Colors.red.shade100,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isPaid ? 'Plaćeno' : 'Neplaćeno',
                  style: TextStyle(
                      color: isPaid ? Colors.green : Colors.red, fontSize: 12),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _payRow('Tablica', v.licensePlate),
          _payRow('Opis', v.description),
          _payRow('Cijena', '${v.fineAmount.toStringAsFixed(2)} KM'),
          _payRow('Datum', _formatDateTime(v.createdAt)),
          if (!isPaid) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(v.licensePlate,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, letterSpacing: 1.2)),
                ),
                ElevatedButton(
                  onPressed: () => _payViolation(v),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Plati'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _payTicket(ParkingTicket ticket) async {
    try {
      final userId = await TokenStorage.getUserId();
      if (userId == null) return;
      await _paymentService.payTicket(
        userId: userId,
        ticketId: ticket.id,
        amount: ticket.totalPrice ?? 0,
      );

      final Dio dio = DioClient.instance;
      await dio.post(
        '${ApiConstants.parkingServiceBase}/api/ParkingTicket/${ticket.id}/pay',
      );

      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Plaćanje uspješno!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (e.toString().contains('canceled')) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Greška pri plaćanju: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _payReservation(ParkingReservation reservation) async {
    try {
      final userId = await TokenStorage.getUserId();
      if (userId == null) return;

      await _paymentService.payReservation(
        userId: userId,
        reservationId: reservation.id,
        amount: reservation.totalPrice,
      );

      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Rezervacija uspješno plaćena!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (e.toString().contains('canceled')) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Greška pri plaćanju: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _payViolation(ParkingViolation violation) async {
    try {
      final userId = await TokenStorage.getUserId();
      if (userId == null) return;
      await _paymentService.payViolation(
        userId: userId,
        violationId: violation.id,
        amount: violation.fineAmount,
      );
      await _loadData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Prekršaj uspješno plaćen!'),
              backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (e.toString().contains('canceled')) return;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Greška pri plaćanju: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Widget _payRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _formatDateTime(DateTime dt) =>
      '${dt.day.toString().padLeft(2, '0')}.${dt.month.toString().padLeft(2, '0')}.${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String _timeRemaining(DateTime deadline) {
    final diff = deadline.difference(DateTime.now());
    if (diff.isNegative) return 'Isteklo';
    return '${diff.inHours.toString().padLeft(2, '0')}:${(diff.inMinutes % 60).toString().padLeft(2, '0')}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}';
  }
}