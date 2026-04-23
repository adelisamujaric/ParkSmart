import 'package:flutter/material.dart';
import 'package:frontend/features/admin/screens/postavke_screen.dart';
import '../../../core/storage/token_storage.dart';
import '../../detections/services/detection_service.dart';
import '../../parking/screens/parking_zone_screen.dart';
import '../../reporting/screens/statistika_screen.dart';
import 'admin_dashboard_content.dart';
import 'admin_prijave_screen.dart';
import 'admin_drone_screen.dart';
import 'admin_camera_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  int _selectedIndex = 0;
  int _pendingCount = 0;
  final _detectionService = DetectionService();

  final List<String> _menuItems = [
    'Dashboard',
    'Prijave',
    'Parking zone',
    'Dronovi',
    'Kamere',
    'Statistika',
    'Postavke',
  ];

  final List<IconData> _menuIcons = [
    Icons.dashboard,
    Icons.report_problem,
    Icons.local_parking,
    Icons.airplanemode_active,
    Icons.videocam,
    Icons.bar_chart,
    Icons.settings,
  ];

  @override
  void initState() {
    super.initState();
    _loadPendingCount();
  }

  Future<void> _loadPendingCount() async {
    try {
      final logs = await _detectionService.getPendingReviews();
      setState(() => _pendingCount = logs.where((l) => l.status.toLowerCase() == 'pendingreview').length);
    } catch (e) {}
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1A5276);

    return Scaffold(
      body: Row(
        children: [
          // Sidebar
          Container(
            width: 220,
            color: primaryBlue,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text(
                    'ParkSmart',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Divider(color: Colors.white24),
                Expanded(
                  child: ListView.builder(
                    itemCount: _menuItems.length,
                    itemBuilder: (context, index) {
                      final isSelected = _selectedIndex == index;
                      return ListTile(
                        leading: Icon(_menuIcons[index], color: Colors.white),
                        title: index == 1
                            ? Row(
                          children: [
                            const Text('Prijave', style: TextStyle(color: Colors.white)),
                            if (_pendingCount > 0) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$_pendingCount',
                                  style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ],
                        )
                            : Text(_menuItems[index], style: const TextStyle(color: Colors.white)),
                        selected: isSelected,
                        selectedTileColor: Colors.white12,
                        onTap: () => setState(() => _selectedIndex = index),
                      );
                    },
                  ),
                ),
                const Divider(color: Colors.white24),
                ListTile(
                  leading: const Icon(Icons.logout, color: Colors.white),
                  title: const Text('Odjava', style: TextStyle(color: Colors.white)),
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/');
                  },
                ),
              ],
            ),
          ),
          // Main content
          Expanded(
            child: Container(
              color: const Color(0xFFF2F3F4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    color: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _menuItems[_selectedIndex],
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),


                        FutureBuilder<String?>(
                          future: TokenStorage.getEmail(),
                          builder: (context, snapshot) {
                            final email = snapshot.data ?? '';
                            return PopupMenuButton<String>(
                              icon: const Icon(Icons.person_outline, size: 32),
                              offset: const Offset(0, 50),
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  enabled: false,
                                  child: Text(email, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                                ),
                                const PopupMenuDivider(),
                                const PopupMenuItem(
                                  value: 'logout',
                                  child: Row(
                                    children: [
                                      Icon(Icons.logout, color: Colors.red, size: 18),
                                      SizedBox(width: 8),
                                      Text('Odjava', style: TextStyle(color: Colors.red)),
                                    ],
                                  ),
                                ),
                              ],
                              onSelected: (value) {
                                if (value == 'logout') {
                                  Navigator.pushReplacementNamed(context, '/');
                                }
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  // Content
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: _buildContent(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    switch (_selectedIndex) {
      case 0:
        return const DashboardContent();
      case 1:
        return PrijaveScreen(onReviewed: _loadPendingCount);
      case 2:
        return const ParkingZoneScreen();
      case 3:
        return const DranoviScreen();
      case 4:
        return const KamereScreen();
      case 5:
        return const StatistikaScreen();
      case 6:
        return const PostavkeScreen();
      default:
        return const SizedBox();
    }
  }
}