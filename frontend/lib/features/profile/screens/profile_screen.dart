import 'package:flutter/material.dart';
import '../../../core/widgets/bottom_nav_bar.dart';
import '../../../core/storage/token_storage.dart';
import '../models/user_profile.dart';
import '../models/vehicle_profil.dart';
import '../services/profile_service.dart';
import '../services/vehicle_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  final _profileService = ProfileService();
  late TabController _tabController;
  UserProfile? _profile;
  bool _isLoading = true;

  static const primaryBlue = Color(0xFF1A5276);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfile();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final userId = await TokenStorage.getUserId();
      final profile = await _profileService.getProfile(userId!);
      setState(() {
        _profile = profile;
        _isLoading = false;
      });

      final needsData = profile.address == null ||
          profile.city == null ||
          profile.postalCode == null ||
          profile.country == null;

      if (needsData && mounted) {
        Future.delayed(Duration.zero, () => _showEditDialog());
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _logout() async {
    await TokenStorage.clear();
    if (mounted) {
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    }
  }

  void _showEditDialog() {
    final firstNameController = TextEditingController(text: _profile?.firstName);
    final lastNameController = TextEditingController(text: _profile?.lastName);
    final phoneController = TextEditingController(text: _profile?.phoneNumber ?? '');
    final addressController = TextEditingController(text: _profile?.address ?? '');
    final cityController = TextEditingController(text: _profile?.city ?? '');
    final postalCodeController = TextEditingController(text: _profile?.postalCode ?? '');
    final countryController = TextEditingController(text: _profile?.country ?? '');
    bool isDisabled = _profile?.isDisabled ?? false; // NOVO

    final errors = <String, String?>{};
    bool isSaving = false;

    String? validateRequired(String value, String fieldName) {
      if (value.trim().isEmpty) return '$fieldName je obavezno polje.';
      return null;
    }

    String? validatePhone(String value) {
      if (value.trim().isEmpty) return null;
      final phoneRegex = RegExp(r'^\+?[0-9]{8,15}$');
      if (!phoneRegex.hasMatch(value.trim())) return 'Format neispravan. Primjer ispravnog formata: +38762111111.';
      return null;
    }

    Map<String, String?> validate() {
      return {
        'firstName': validateRequired(firstNameController.text, 'Ime'),
        'lastName': validateRequired(lastNameController.text, 'Prezime'),
        'phone': validatePhone(phoneController.text),
        'address': validateRequired(addressController.text, 'Adresa'),
        'city': validateRequired(cityController.text, 'Grad'),
        'postalCode': validateRequired(postalCodeController.text, 'Poštanski broj'),
        'country': validateRequired(countryController.text, 'Država'),
      };
    }

    showDialog(
      context: context,
      barrierDismissible: _profile?.address != null,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Widget buildField(String label, TextEditingController controller,
              String errorKey, {TextInputType keyboardType = TextInputType.text}) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    keyboardType: keyboardType,
                    onChanged: (_) {
                      if (errors[errorKey] != null) {
                        setDialogState(() => errors[errorKey] = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: label,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  if (errors[errorKey] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4, bottom: 8),
                      child: Text(
                        errors[errorKey]!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                ],
              ),
            );
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),

            child: Padding(
              padding: const EdgeInsets.all(20),

              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Uredi podatke',
                    style: TextStyle(color: primaryBlue, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 16),

                  Flexible(
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            buildField('Ime', firstNameController, 'firstName'),
                            buildField('Prezime', lastNameController, 'lastName'),
                            buildField('Telefon (neobavezno)', phoneController, 'phone',
                                keyboardType: TextInputType.phone),
                            buildField('Adresa', addressController, 'address'),
                            buildField('Grad', cityController, 'city'),
                            buildField('Poštanski broj', postalCodeController,
                                'postalCode', keyboardType: TextInputType.number),
                            buildField('Država', countryController, 'country'),
                            // NOVO: Invalid vozač checkbox
                            CheckboxListTile(
                              value: isDisabled,
                              onChanged: (val) =>
                                  setDialogState(() => isDisabled = val ?? false),
                              title: const Text('Invalid vozač',
                                  style: TextStyle(fontSize: 14)),
                              subtitle: const Text(
                                '⚠️ Samo za testiranje, u stvarnosti potrebna verifikacija.',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                              activeColor: primaryBlue,
                              controlAffinity: ListTileControlAffinity.leading,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: primaryBlue),
                          ),
                          child: const Text('Odustani',
                              style: TextStyle(color: primaryBlue)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                            final newErrors = validate();
                            final hasErrors =
                            newErrors.values.any((e) => e != null);
                            setDialogState(() => errors.addAll(newErrors));
                            if (hasErrors) return;

                            setDialogState(() => isSaving = true);
                            try {
                              final userId = await TokenStorage.getUserId();
                              await _profileService.updateProfile(
                                userId!,
                                firstName: firstNameController.text.trim(),
                                lastName: lastNameController.text.trim(),
                                phoneNumber: phoneController.text.trim().isEmpty
                                    ? null
                                    : phoneController.text.trim(),
                                address: addressController.text.trim(),
                                city: cityController.text.trim(),
                                postalCode: postalCodeController.text.trim(),
                                country: countryController.text.trim(),
                                isDisabled: isDisabled, // NOVO
                              );
                              if (mounted) Navigator.pop(context);
                              await _loadProfile();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Podaci uspješno ažurirani!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              setDialogState(() => isSaving = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Greška pri ažuriranju.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: isSaving
                              ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                              : const Text('Spremi'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F4),
      appBar: AppBar(
        backgroundColor: primaryBlue,
        automaticallyImplyLeading: false,
        title: const Text('ParkSmart',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Podaci'),
            Tab(text: 'Vozila'),
          ],
        ),
      ),
      bottomNavigationBar: ParkSmartBottomNav(currentIndex: 4),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
        controller: _tabController,
        children: [
          _buildPodaciTab(),
          const _VozilaTab(),
        ],
      ),
    );
  }

  Widget _buildPodaciTab() {
    if (_profile == null) {
      return const Center(child: Text('Greška pri učitavanju podataka.'));
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Text(
            '${_profile!.firstName} ${_profile!.lastName}',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: primaryBlue),
          ),
          const SizedBox(height: 2),
          Text(_profile!.email, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),

          _infoCard([
            _infoRow(Icons.phone, 'Telefon',
                _profile!.phoneNumber ?? 'Nije uneseno'),
            _infoRow(Icons.location_on, 'Adresa',
                _profile!.address ?? 'Nije uneseno'),
            _infoRow(Icons.location_city, 'Grad',
                _profile!.city ?? 'Nije uneseno'),
            _infoRow(Icons.markunread_mailbox, 'Poštanski broj',
                _profile!.postalCode ?? 'Nije uneseno'),
            _infoRow(Icons.flag, 'Država',
                _profile!.country ?? 'Nije uneseno'),
            _infoRow(Icons.accessible, 'Invalid vozač',
                _profile!.isDisabled ? 'Da' : 'Ne'), // NOVO
          ]),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showEditDialog,
              icon: const Icon(Icons.edit),
              label: const Text('Uredi podatke'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),

          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.red),
              label: const Text('Odjavi se',
                  style: TextStyle(color: Colors.red)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Colors.red),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _infoCard(List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8)
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(fontSize: 11, color: Colors.grey)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── VOZILA TAB ───────────────────────────────────────────────────────────────

class _VozilaTab extends StatefulWidget {
  const _VozilaTab();

  @override
  State<_VozilaTab> createState() => _VozilaTabState();
}

class _VozilaTabState extends State<_VozilaTab> {
  final _vehicleService = VehicleService();
  List<Vehicle> _vehicles = [];
  bool _isLoading = true;

  static const primaryBlue = Color(0xFF1A5276);

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  Future<void> _loadVehicles() async {
    try {
      final userId = await TokenStorage.getUserId();
      final vehicles = await _vehicleService.getVehiclesByUser(userId!);
      setState(() {
        _vehicles = vehicles;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteVehicle(String vehicleId) async {
    try {
      await _vehicleService.deleteVehicle(vehicleId);
      await _loadVehicles();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vozilo uspješno obrisano!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Greška pri brisanju vozila.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAddVehicleDialog() {
    final licensePlateController = TextEditingController();
    final brandController = TextEditingController();
    final modelController = TextEditingController();
    final errors = <String, String?>{};
    bool isSaving = false;

    String? validateRequired(String value, String fieldName) {
      if (value.trim().isEmpty) return '$fieldName je obavezno polje.';
      return null;
    }

    Map<String, String?> validate() {
      return {
        'licensePlate': validateRequired(licensePlateController.text, 'Tablica'),
        'brand': validateRequired(brandController.text, 'Marka'),
        'model': validateRequired(modelController.text, 'Model'),
      };
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Widget buildField(String label, TextEditingController controller,
              String errorKey) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: controller,
                    onChanged: (_) {
                      if (errors[errorKey] != null) {
                        setDialogState(() => errors[errorKey] = null);
                      }
                    },
                    decoration: InputDecoration(
                      labelText: label,
                      border: const OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  if (errors[errorKey] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 4, bottom: 8),
                      child: Text(
                        errors[errorKey]!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    )
                  else
                    const SizedBox(height: 12),
                ],
              ),
            );
          }

          return Dialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Dodaj vozilo',
                    style: TextStyle(
                        color: primaryBlue,
                        fontWeight: FontWeight.bold,
                        fontSize: 18),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.35 -
                        MediaQuery.of(context).viewInsets.bottom * 0.3,
                    child: Scrollbar(
                      thumbVisibility: true,
                      child: SingleChildScrollView(
                        child: Column(
                          children: [
                            buildField('Tablica', licensePlateController, 'licensePlate'),
                            buildField('Marka', brandController, 'brand'),
                            buildField('Model', modelController, 'model'),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            side: const BorderSide(color: primaryBlue),
                          ),
                          child: const Text('Odustani',
                              style: TextStyle(color: primaryBlue)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryBlue,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: isSaving
                              ? null
                              : () async {
                            final newErrors = validate();
                            final hasErrors =
                            newErrors.values.any((e) => e != null);
                            setDialogState(() => errors.addAll(newErrors));
                            if (hasErrors) return;

                            setDialogState(() => isSaving = true);
                            try {
                              final userId = await TokenStorage.getUserId();
                              await _vehicleService.addVehicle(
                                licensePlate: licensePlateController.text.trim(),
                                brand: brandController.text.trim(),
                                model: modelController.text.trim(),
                                userId: userId!,
                              );
                              if (mounted) Navigator.pop(context);
                              await _loadVehicles();
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Vozilo uspješno dodano!'),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } catch (e) {
                              setDialogState(() => isSaving = false);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Greška pri dodavanju vozila.'),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              }
                            }
                          },
                          child: isSaving
                              ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                              : const Text('Dodaj'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _confirmDelete(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Obriši vozilo'),
        content: Text(
            'Da li ste sigurni da želite obrisati vozilo ${vehicle.brand} ${vehicle.model} (${vehicle.licensePlate})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(context);
              _deleteVehicle(vehicle.id);
            },
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _showAddVehicleDialog,
              icon: const Icon(Icons.add),
              label: const Text('Dodaj vozilo'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _vehicles.isEmpty
                ? const Center(
              child: Text(
                'Nemate registrovanih vozila.',
                style: TextStyle(color: Colors.grey),
              ),
            )
            : Scrollbar(
              thumbVisibility: true,
              child:
              ListView.builder(
              itemCount: _vehicles.length,
              itemBuilder: (context, index) {
                final vehicle = _vehicles[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
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
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: primaryBlue,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.directions_car,
                            color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${vehicle.brand} ${vehicle.model}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                vehicle.licensePlate,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 1.2,
                                    fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => _confirmDelete(vehicle),
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red),
                      ),
                    ],
                  ),
                );

              },
            ),
          ),
          ),
        ],
      ),
    );
  }
}