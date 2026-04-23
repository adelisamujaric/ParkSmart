import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../auth/models/vehicle_with_owner.dart';
import '../models/parking_lot.dart';
import '../models/parking_spot.dart';
import '../services/parking_lot_service.dart';



class ParkingDetailsScreen extends StatefulWidget {
  final ParkingLot lot;
  const ParkingDetailsScreen({super.key, required this.lot});

  @override
  State<ParkingDetailsScreen> createState() => _ParkingDetailsScreenState();
}

class _ParkingDetailsScreenState extends State<ParkingDetailsScreen> {
  final _service = ParkingLotService();
  List<ParkingSpot> _spots = [];
  bool _isLoading = true;
  List<ParkingSpot> _reservableSpots = [];

  @override
  void initState() {
    super.initState();
    _loadSpots();
  }

  List<VehicleResponse> _vehicles = [];
  VehicleResponse? _selectedVehicle;

  Future<void> _loadSpots() async {
    try {
      final spots = await _service.getSpotsByLotId(widget.lot.id);

      List<VehicleResponse> vehicles = [];
      VehicleResponse? selectedVehicle;

      final userId = await TokenStorage.getUserId();
      if (userId != null) {
        try {
          final Dio dio = DioClient.instance;
          final vehicleRes = await dio.get(
            '${ApiConstants.userServiceBase}/api/vehicles/user/$userId',
          );

          final allVehicles = (vehicleRes.data as List)
              .map((v) => VehicleResponse.fromJson(v))
              .toList();

          // Dohvati aktivne tikete
          try {
            final ticketRes = await dio.get(
              '${ApiConstants.parkingServiceBase}/api/ParkingTicket/active/user',
            );
            final activeTickets = ticketRes.data as List;
            final activePlates = activeTickets
                .map((t) => t['licensePlate'].toString().toUpperCase())
                .toSet();

            vehicles = allVehicles
                .where((v) => !activePlates.contains(v.licensePlate.toUpperCase()))
                .toList();
          } catch (_) {
            vehicles = allVehicles;
          }

          if (vehicles.isNotEmpty) selectedVehicle = vehicles.first;



        } catch (e) {
          print('Greška pri učitavanju vozila: $e');
        }
      }

      setState(() {
        _spots = spots;
        _reservableSpots = spots.where((s) => s.isReservable && s.status == 0).toList();
        _vehicles = vehicles;
        _selectedVehicle = selectedVehicle;
        _isLoading = false;
      });
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1A5276);
    final available = _spots.where((s) => s.status == 0).length;
    final reserved = _spots.where((s) => s.status == 2).length;
    final availableSpots = _spots.where((s) => s.status == 0 && !s.isReservable).toList();


    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F4),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        title: const Text('ParkSmart',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
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
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color: primaryBlue,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.local_parking, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Text(widget.lot.name,
                          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _infoRow(Icons.location_on, widget.lot.address, Colors.grey),
                  const SizedBox(height: 8),
                  _infoRow(Icons.access_time,
                      '${widget.lot.openTime.substring(0, 5)} – ${widget.lot.closeTime.substring(0, 5)}',
                      Colors.grey),
                  const SizedBox(height: 8),
                  _infoRow(Icons.event_seat, 'Slobodna mjesta: $available', Colors.green),
                  const SizedBox(height: 8),
                  _infoRow(Icons.bookmark, 'Rezervisana mjesta: $reserved', Colors.orange),
                  const SizedBox(height: 8),
                  _infoRow(Icons.star,
                      'Cijena: ${(widget.lot.ratePerMinute * 60).toStringAsFixed(2)} KM/h',
                      Colors.amber),
                  if (widget.lot.reservationRatePerMinute != null) ...[
                    const SizedBox(height: 8),
                    _infoRow(Icons.bookmark_add,
                        'Doplata za rezervaciju: +${(widget.lot.reservationRatePerMinute! * 60).toStringAsFixed(2)} KM/h',
                        Colors.blue),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

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
                    final destination = Uri.encodeComponent(widget.lot.address);

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
            if (widget.lot.isOpen) ...[
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: availableSpots.isEmpty
                      ? null
                      : () => _showBuyTicketDialog(availableSpots),
                  icon: const Icon(Icons.local_parking),
                  label: const Text('Kupi ticket', style: TextStyle(fontSize: 16)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ),

              if (availableSpots.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'Nema slobodnih parking mjesta.',
                    style: TextStyle(color: Colors.red, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              const SizedBox(height: 12),
            ],

            // Rezerviši
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton.icon(
                onPressed: _reservableSpots.isEmpty ? null : () {
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    builder: (context) => Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('Dostupna mjesta za rezervaciju',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 12),
                          Flexible(
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: _reservableSpots.length,
                              itemBuilder: (context, index) {
                                final spot = _reservableSpots[index];
                                return ListTile(
                                  leading: const Icon(Icons.local_parking, color: Color(0xFF1A5276)),
                                  title: Text('Mjesto ${spot.spotNumber}'),
                                  subtitle: spot.floor != null ? Text('Sprat ${spot.floor}') : null,
                                  trailing: ElevatedButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                      _showReservationDialog(spot);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1A5276),
                                      foregroundColor: Colors.white,
                                    ),
                                    child: const Text('Rezerviši'),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.bookmark_add),
                label: const Text('Rezerviši', style: TextStyle(fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _reservableSpots.isEmpty ? Colors.grey : const Color(0xFF1A5276),
                  side: BorderSide(color: _reservableSpots.isEmpty ? Colors.grey : const Color(0xFF1A5276)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),

            if (_reservableSpots.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Nema dostupnih mjesta za rezervaciju.',
                  style: TextStyle(color: Colors.red, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
      bottomNavigationBar: ParkSmartBottomNav(currentIndex: 0),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 14))),
      ],
    );
  }

  Future<void> _showBuyTicketDialog(List<ParkingSpot> availableSpots) async {
    const primaryBlue = Color(0xFF1A5276);
    ParkingSpot? selectedSpot = availableSpots.first;
    int hours = 1;
    int minutes = 0;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final totalMinutes = hours * 60 + minutes;
          final price = totalMinutes * widget.lot.ratePerMinute;

          return AlertDialog(
            title: Row(
              children: [
                const Icon(Icons.local_parking, color: Color(0xFF1A5276)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Kupi ticket – ${widget.lot.name}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),


            content: SingleChildScrollView(

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Odaberi mjesto:',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),

                  DropdownButtonFormField<ParkingSpot>(
                    value: selectedSpot,
                    menuMaxHeight: 200,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: availableSpots.map((spot) {
                      return DropdownMenuItem(
                        value: spot,
                        child: Text('Mjesto ${spot.spotNumber}'
                            '${spot.floor != null ? ' (Sprat ${spot.floor})' : ''}'),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedSpot = val),
                  ),


                  const SizedBox(height: 16),
                  const Text('Tablica vozila:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<VehicleResponse>(
                    value: _selectedVehicle,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _vehicles.map((v) {
                      return DropdownMenuItem(
                        value: v,
                        child: Text(v.licensePlate),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => _selectedVehicle = val),
                  ),


                  const SizedBox(height: 16),
                  const Text('Trajanje:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Sati', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: minutes > 0
                                      ? () => setDialogState(() => minutes --)
                                      : null,
                                  icon: const Icon(Icons.remove_circle_outline),
                                  color: primaryBlue,
                                ),


                                Text('$hours',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                IconButton(
                                  onPressed: hours < 24 ? () => setDialogState(() => hours++) : null,
                                  icon: const Icon(Icons.add_circle_outline),
                                  color: primaryBlue,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const Text(':', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                      Expanded(
                        child: Column(
                          children: [
                            const Text('Minute', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: minutes >= 0
                                      ? () => setDialogState(() => minutes --)
                                      : null,
                                  icon: const Icon(Icons.remove_circle_outline),
                                  color: primaryBlue,
                                ),
                                Text(minutes.toString().padLeft(2, '0'),
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                IconButton(
                                  onPressed: minutes < 59
                                      ? () => setDialogState(() => minutes ++)
                                      : null,
                                  icon: const Icon(Icons.add_circle_outline),
                                  color: primaryBlue,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Trajanje:'),
                            Text('${hours}h ${minutes.toString().padLeft(2, '0')}min'),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Ukupno:', style: TextStyle(fontWeight: FontWeight.bold)),
                            Text('${price.toStringAsFixed(2)} KM',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, color: primaryBlue, fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Plaćanje se vrši po isteku parkinga.',
                          style: TextStyle(fontSize: 11, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Odustani'),
              ),
              ElevatedButton(
                onPressed: totalMinutes == 0
                    ? null
                    : () async {
                  await _confirmBuyTicket(selectedSpot!, totalMinutes);
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
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

  Future<void> _confirmBuyTicket(ParkingSpot spot, int durationMinutes) async {
    try {
      if (_selectedVehicle == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Odaberi vozilo!'), backgroundColor: Colors.red),
          );
        }
        return;
      }

      final Dio dio = DioClient.instance;
      await dio.post(
        '${ApiConstants.parkingServiceBase}/api/ParkingTicket/checkin',
        data: {
          'spotId': spot.id,
          'licensePlate': _selectedVehicle!.licensePlate,
          'durationMinutes': durationMinutes,
        },
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket uspješno kreiran!'), backgroundColor: Colors.green),
        );
        _loadSpots();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Greška pri kreiranju ticketa.';
        final errorStr = e.toString();
        if (errorStr.contains('already has an active ticket')) {
          errorMessage = 'Vaše vozilo već ima aktivan parking ticket!';
        } else if (errorStr.contains('currently occupied')) {
          errorMessage = 'Odabrano parking mjesto je zauzeto!';
        } else if (errorStr.contains('out of service')) {
          errorMessage = 'Odabrano parking mjesto nije u funkciji!';
        } else if (errorStr.contains('currently inactive')) {
          errorMessage = 'Parking zona nije aktivna!';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }

    }
  }

  Future<void> _showReservationDialog(ParkingSpot spot) async {
    const primaryBlue = Color(0xFF1A5276);
    DateTime startTime = DateTime.now().add(const Duration(minutes: 1));
    DateTime endTime = DateTime.now().add(const Duration(hours: 1, minutes: 1));
    VehicleResponse? selectedVehicle = _vehicles.isNotEmpty ? _vehicles.first : null; // DODANO

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final duration = endTime.difference(startTime);
          final hours = duration.inMinutes / 60;
          final rate = widget.lot.reservationRatePerMinute ?? widget.lot.ratePerMinute;
          final price = (hours * 60 * rate);

          return AlertDialog(
            title: Text('Rezervacija - Mjesto ${spot.spotNumber}'),
            content: SingleChildScrollView( // DODANO da ne overflow
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Tablica vozila:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<VehicleResponse>(
                    value: selectedVehicle,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: _vehicles.map((v) {
                      return DropdownMenuItem(
                        value: v,
                        child: Text(v.licensePlate),
                      );
                    }).toList(),
                    onChanged: (val) => setDialogState(() => selectedVehicle = val),
                  ),
                  const SizedBox(height: 16),
                  const Text('Od:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: startTime,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (date == null) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(startTime),
                      );
                      if (time == null) return;
                      setDialogState(() {
                        startTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                        if (endTime.isBefore(startTime)) {
                          endTime = startTime.add(const Duration(hours: 1));
                        }
                      });
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                        '${startTime.day}.${startTime.month}.${startTime.year} ${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}'),
                  ),
                  const SizedBox(height: 12),
                  const Text('Do:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: endTime,
                        firstDate: startTime,
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );
                      if (date == null) return;
                      final time = await showTimePicker(
                        context: context,
                        initialTime: TimeOfDay.fromDateTime(endTime),
                      );
                      if (time == null) return;
                      setDialogState(() {
                        endTime = DateTime(date.year, date.month, date.day, time.hour, time.minute);
                      });
                    },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(
                        '${endTime.day}.${endTime.month}.${endTime.year} ${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}'),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Ukupno:', style: TextStyle(fontWeight: FontWeight.bold)),
                        Text('${price.toStringAsFixed(2)} KM',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, color: primaryBlue, fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Odustani'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedVehicle == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Odaberi vozilo!'), backgroundColor: Colors.red),
                    );
                    return;
                  }
                  await _confirmReservation(spot, startTime, endTime, selectedVehicle!.licensePlate); // ISPRAVLJENO
                  if (mounted) Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A5276),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Potvrdi rezervaciju'),
              ),
            ],
          );
        },
      ),
    );
  }


  Future<void> _confirmReservation(ParkingSpot spot, DateTime startTime, DateTime endTime, String licensePlate) async {
    try {
      final Dio dio = DioClient.instance;
      await dio.post(
        '${ApiConstants.parkingServiceBase}/parkingReservation/Reservation/create',
        data: {
          'spotId': spot.id,
          'licensePlate': licensePlate,
          'startTime': startTime.toUtc().toIso8601String(),
          'endTime': endTime.toUtc().toIso8601String(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Rezervacija uspješno kreirana!'),
              backgroundColor: Colors.green),
        );
        _loadSpots();
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Greška pri kreiranju rezervacije.';
        final errorStr = e.toString();
        if (errorStr.contains('at least 5 minutes')) {
          errorMessage = 'Rezervacija mora trajati najmanje 5 minuta!';
        } else if (errorStr.contains('in the past')) {
          errorMessage = 'Vrijeme početka ne može biti u prošlosti!';
        } else if (errorStr.contains('already reserved')) {
          errorMessage = 'Odabrano mjesto je već rezervisano u tom periodu!';
        } else if (errorStr.contains('not available for reservation')) {
          errorMessage = 'Ovo mjesto nije dostupno za rezervaciju!';
        } else if (errorStr.contains('currently inactive')) {
          errorMessage = 'Parking zona nije aktivna!';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    }
  }
}