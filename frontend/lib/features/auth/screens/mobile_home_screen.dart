import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../parking/models/parking_lot.dart';
import '../../parking/services/parking_lot_service.dart';
import '../../recommendations/models/recommendation.dart';
import '../../recommendations/services/recommender_service.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/constants/api_constants.dart';
import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _parkingLotService = ParkingLotService();
  final _recommenderService = RecommenderService();

  String? _firstName;
  String? _licensePlate;
  List<ParkingLot> _lots = [];
  Recommendation? _topRecommendation;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final userId = await TokenStorage.getUserId();
      final firstName = await TokenStorage.getFirstName();

      String? plate;
      if (userId != null) {
        try {
          final Dio dio = DioClient.instance;
          final vehicleRes = await dio.get(
            '${ApiConstants.userServiceBase}/api/vehicles/user/$userId',
          );
          final vehicles = vehicleRes.data as List;
          if (vehicles.isNotEmpty) {
            plate = vehicles.first['licensePlate'];
            await TokenStorage.saveLicensePlate(plate!);
          }
        } catch (_) {}
      }

      final lots = await _parkingLotService.getAll();

      Recommendation? topRec;
      if (userId != null) {
        try {
          final recs = await _recommenderService.getRecommendations(userId);
          if (recs.isNotEmpty) topRec = recs.first;
        } catch (_) {}
      }

      setState(() {
        _firstName = firstName;
        _licensePlate = plate;
        _lots = lots;
        _topRecommendation = topRec;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
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
          : Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pozdrav + vozilo
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 8)
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Dobrodošli, ${_firstName ?? ''}',
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: primaryBlue),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Preporuka
            if (_topRecommendation != null) ...[
              const Text('Preporučeno za vas',
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: primaryBlue)),
              const SizedBox(height: 8),
              Builder(builder: (context) {
                // pronađi lot za preporuku (za adresu)
                final recLot = _lots.isNotEmpty
                    ? _lots.firstWhere(
                      (l) => l.id == _topRecommendation!.lotId,
                  orElse: () => _lots.first,
                )
                    : null;

                final isOpen = _topRecommendation!.type == 0;

                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 8)
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                                color: primaryBlue,
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.local_parking,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_topRecommendation!.lotName,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold)),
                              Text(
                                recLot?.address ?? '',
                                style: const TextStyle(
                                    fontSize: 13, color: Colors.grey),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(children: [
                        const Icon(Icons.event_seat,
                            size: 16, color: Colors.green),
                        const SizedBox(width: 6),
                        Text(
                            'Slobodna mjesta: ${_topRecommendation!.availableSpots}'),
                      ]),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.star,
                            size: 16, color: Colors.amber),
                        const SizedBox(width: 6),
                        Text(
                            'Cijena: ${(_topRecommendation!.ratePerMinute * 60).toStringAsFixed(2)} KM/h'),
                      ]),
                      const SizedBox(height: 4),
                      // Tip parkinga iz recommendera
                      Row(children: [
                        Icon(Icons.category,
                            size: 16,
                            color: isOpen
                                ? Colors.green.shade700
                                : Colors.blue.shade700),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isOpen
                                ? Colors.green.shade100
                                : Colors.blue.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isOpen ? 'Tip: Otvoreni (bez kamera)' : 'Tip: Zatvoreni (ulaz/izlaz kamere)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isOpen
                                  ? Colors.green.shade700
                                  : Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ]),
                      const SizedBox(height: 12),

                      // Navigiraj
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(

                          onPressed: () async {
                            final userId = await TokenStorage.getUserId();
                            if (userId == null) return;

                            try {
                              final Dio dio = DioClient.instance;
                              final response = await dio.get(
                                '${ApiConstants.userServiceBase}/api/users/$userId',
                              );
                              final address = response.data['address'] ?? '';
                              final city = response.data['city'] ?? '';
                              final origin = Uri.encodeComponent('$address, $city');
                              final destination = Uri.encodeComponent(recLot?.address ?? '');

                              final url = Uri.parse(
                                  'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=driving'
                              );

                              if (await canLaunchUrl(url)) {
                                await launchUrl(url, mode: LaunchMode.externalApplication);
                              }
                            } catch (e) {
                              print('Navigation error: $e');
                            }
                          },

                          icon: const Icon(Icons.navigation),
                          label: const Text('Navigiraj', style: TextStyle(fontSize: 16)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),


                      // Kupi ticket — samo za Open tip
                      if (isOpen) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pushNamed(
                                context,
                                '/buy-ticket',
                                arguments: recLot,
                              );
                            },
                            icon: const Icon(Icons.local_parking, size: 16),
                            label: const Text('Kupi ticket'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8)),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),
              const SizedBox(height: 16),
            ],

            // Lista parking zona
            const Text('Parking zone (Tiketi, Rezervacije, Navigacija)',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: primaryBlue)),
            const SizedBox(height: 8),

            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8)
                  ],
                ),
                child: Scrollbar(
                  thumbVisibility: true,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: _lots.length,
                    itemBuilder: (context, index) =>
                        _buildLotRow(_lots[index], primaryBlue),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),

      bottomNavigationBar: ParkSmartBottomNav(currentIndex: 0),
    );
  }

  Widget _buildLotRow(ParkingLot lot, Color primaryBlue) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lot.name,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(lot.address,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 2),
                Text(
                  lot.isOpen
                      ? 'Tip: Otvoreni (bez kamera)'
                      : 'Tip: Zatvoreni (ulaz/izlaz kamere)',
                  style: TextStyle(
                    fontSize: 11,
                    color: lot.isOpen ? Colors.green.shade700 : Colors.blue.shade700,
                  ),
                ),
              ],
            ),



          ),
          Text('${(lot.ratePerMinute * 60).toStringAsFixed(2)} KM/h',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/parking-details',
                arguments: lot,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(6)),
            ),
            child: const Text('Pregled', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }
}