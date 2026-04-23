import 'package:flutter/material.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../models/notification.dart';
import '../services/notification_service.dart';
import '../../../core/storage/token_storage.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _service = NotificationService();
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  int _tabIndex = 0;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = await TokenStorage.getUserId();
      if (userId == null) return;
      final notifications = await _service.getByUserId(userId);
      print('>>> TOTAL NOTIFS: ${notifications.length}');
      for (final n in notifications) {
        print('>>> title: "${n.title}", isRead: ${n.isRead}, status: ${n.status}');
      }
      notifications.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      setState(() {
        _notifications = notifications;
        _isLoading = false;
      });
    } catch (e) {
      print('>>> LOAD ERROR: $e');
      setState(() => _isLoading = false);
    }
  }

  List<NotificationModel> get _unread =>
      _notifications.where((n) => !n.isRead).toList();

  List<NotificationModel> get _read {
    var read = _notifications.where((n) => n.isRead).toList();
    if (_selectedDate != null) {
      read = read.where((n) =>
      n.createdAt.year == _selectedDate!.year &&
          n.createdAt.month == _selectedDate!.month &&
          n.createdAt.day == _selectedDate!.day,
      ).toList();
    }
    return read;
  }

  List<NotificationModel> _filterByPrefix(List<NotificationModel> list, String prefix) =>
      list.where((n) => n.title.startsWith(prefix)).toList();

  IconData _typeIcon(int type) {
    switch (type) {
      case 0: return Icons.info_outline;
      case 1: return Icons.directions_car;
      case 2: return Icons.bookmark;
      case 3: return Icons.warning_amber;
      case 4: return Icons.check_circle;
      default: return Icons.notifications;
    }
  }

  Color _typeColor(int type) {
    switch (type) {
      case 0: return Colors.blue;
      case 1: return Colors.orange;
      case 2: return Colors.purple;
      case 3: return Colors.red;
      case 4: return Colors.green;
      default: return Colors.grey;
    }
  }

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
                _tabButton('Nepročitano', 0, primaryBlue, badge: _unread.length),
                const SizedBox(width: 8),
                _tabButton('Pročitano', 1, primaryBlue),
              ],
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadData,
              child: _tabIndex == 0
                  ? _buildWithSubtabs(_unread, primaryBlue, showDateFilter: false)
                  : _buildWithSubtabs(_read, primaryBlue, showDateFilter: true),
            ),
          ),
        ],
      ),
      bottomNavigationBar: ParkSmartBottomNav(currentIndex: 3),
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

  Widget _buildWithSubtabs(
      List<NotificationModel> items,
      Color primaryBlue, {
        required bool showDateFilter,
      }) {
    final tiketi = _filterByPrefix(items, 'Ticket:');
    final rezervacije = _filterByPrefix(items, 'Rezervacija:');
    final prekrsaji = _filterByPrefix(items, 'Prekršaj:');
    final placanja = _filterByPrefix(items, 'Plaćanje:');

    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          Container(
            color: Colors.white,
            child: Column(
              children: [
                TabBar(
                  labelColor: primaryBlue,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: primaryBlue,
                  isScrollable: true,
                  tabs: [
                    Tab(text: 'Ticketi (${tiketi.length})'),
                    Tab(text: 'Rezervacije (${rezervacije.length})'),
                    Tab(text: 'Prekršaji (${prekrsaji.length})'),
                    Tab(text: 'Plaćanja (${placanja.length})'),
                  ],
                ),
                if (showDateFilter)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
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
                              : '${_selectedDate!.day}.${_selectedDate!.month}.${_selectedDate!.year}'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                        if (_selectedDate != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () => setState(() => _selectedDate = null),
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildList(tiketi, primaryBlue, 'Nema notifikacija o tiketima.'),
                _buildList(rezervacije, primaryBlue, 'Nema notifikacija o rezervacijama.'),
                _buildList(prekrsaji, primaryBlue, 'Nema notifikacija o prekršajima.'),
                _buildList(placanja, primaryBlue, 'Nema notifikacija o plaćanjima.'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<NotificationModel> items, Color primaryBlue, String emptyMessage) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.notifications_off_outlined, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(emptyMessage, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return Scrollbar(
      thumbVisibility: true,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: items.map((n) => _notificationCard(n, primaryBlue)).toList(),
      ),
    );
  }

  Widget _notificationCard(NotificationModel n, Color primaryBlue) {
    return InkWell(


      onTap: () async {
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _typeColor(n.type).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(_typeIcon(n.type), color: _typeColor(n.type), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(n.title, style: const TextStyle(fontSize: 16)),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(n.message, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 12),
                Text(
                  '${n.createdAt.day.toString().padLeft(2, '0')}.${n.createdAt.month.toString().padLeft(2, '0')}.${n.createdAt.year} ${n.createdAt.hour.toString().padLeft(2, '0')}:${n.createdAt.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Zatvori'),
              ),
            ],
          ),
        );
        // Nakon zatvaranja dijaloga
        print('>>> DIALOG CLOSED, isRead: ${n.isRead}, id: ${n.id}');
        if (!n.isRead) {
          try {
            await _service.markAsRead(n.id);
            print('>>> SUCCESS markAsRead');
            await _loadData();
            print('>>> RELOADED');
          } catch (e) {
            print('>>> ERROR markAsRead: $e');
          }
        }



        if (!n.isRead) {
          try {
            await _service.markAsRead(n.id);
            await _loadData();
          } catch (e) {}
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: n.isRead ? Colors.white : const Color(0xFFEAF2FB),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6)
          ],
          border: n.isRead
              ? null
              : Border.all(color: primaryBlue.withOpacity(0.3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _typeColor(n.type).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_typeIcon(n.type), color: _typeColor(n.type), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(n.title,
                      style: TextStyle(
                          fontWeight: n.isRead ? FontWeight.normal : FontWeight.bold,
                          fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(n.message,
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    '${n.createdAt.day.toString().padLeft(2, '0')}.${n.createdAt.month.toString().padLeft(2, '0')}.${n.createdAt.year} ${n.createdAt.hour.toString().padLeft(2, '0')}:${n.createdAt.minute.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            if (!n.isRead)
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Color(0xFF1A5276),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );


  }
}