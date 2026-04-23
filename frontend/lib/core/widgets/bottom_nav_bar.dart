import 'dart:async';

import 'package:flutter/material.dart';
import '../../features/parking/models/parking_violation.dart';
import '../../features/parking/services/parking_lot_service.dart';
import '../storage/token_storage.dart';
import '../../features/notifications/services/notification_service.dart';

class ParkSmartBottomNav extends StatefulWidget {
  final int currentIndex;
  const ParkSmartBottomNav({super.key, required this.currentIndex});

  @override
  State<ParkSmartBottomNav> createState() => _ParkSmartBottomNavState();
}

class _ParkSmartBottomNavState extends State<ParkSmartBottomNav> {
  int _unreadCount = 0;
  int _unpaidCount = 0;
  int _activeCount = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadAll();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _loadAll());
  }
  void _loadAll() {
    _loadUnpaidCount();
    _loadActiveCount();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  DateTime? _lastLoad;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final now = DateTime.now();
    if (_lastLoad == null || now.difference(_lastLoad!).inSeconds > 30) {
      _lastLoad = now;
      _loadAll();
    }
  }

  Future<void> _loadUnpaidCount() async {
    try {
      final userId = await TokenStorage.getUserId();
      if (userId == null) return;
      final notifications = await NotificationService().getByUserId(userId);
      final service = ParkingLotService();
      final tickets = await service.getMyTickets();
      final reservations = await service.getMyReservations();
      final violations = await service.getViolationsByUserId(userId);

      setState(() {
        _unreadCount = notifications.where((n) => !n.isRead).length;
        _unpaidCount = tickets.where((t) => t.status == 'pendingpayment').length +
            reservations.where((r) => r.status == 4).length +
            violations.where((v) => !v.isResolved).length;
      });
    } catch (_) {}
  }


  Future<void> _loadActiveCount() async {
    try {
      final service = ParkingLotService();
      final tickets = await service.getMyTickets();
      final reservations = await service.getMyReservations();
      setState(() {
        _activeCount = tickets.where((t) => t.status == 'active').length +
            reservations.where((r) => r.status == 0 || r.status == 1).length;
      });
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1A5276);

    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: primaryBlue,
      unselectedItemColor: Colors.grey,
      currentIndex: widget.currentIndex,
      onTap: (index) {
        if (index == widget.currentIndex) return;
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/home');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/payments');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/my-parkings');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/notifications');
            break;
          case 4:
            Navigator.pushReplacementNamed(context, '/profile');
            break;
        }
      },
      items: [
        const BottomNavigationBarItem(
            icon: Icon(Icons.home), label: 'Početna'),

        BottomNavigationBarItem(
             icon: Badge(
               isLabelVisible: _unpaidCount > 0,
               label: Text('$_unpaidCount'),
               child: const Icon(Icons.payment),
             ),
             label: 'Plaćanja',
           ),

        BottomNavigationBarItem(
          icon: Badge(
            isLabelVisible: _activeCount > 0,
            label: Text('$_activeCount'),
            child: const Icon(Icons.directions_car),
          ),
          label: 'Parkiranja',
        ),

        BottomNavigationBarItem(
          icon: Badge(
            isLabelVisible: _unreadCount > 0,
            label: Text('$_unreadCount'),
            child: const Icon(Icons.notifications),
          ),
          label: 'Notifikacije',
        ),
        const BottomNavigationBarItem(
            icon: Icon(Icons.person), label: 'Profil'),
      ],
    );
  }
}