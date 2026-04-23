import 'package:flutter/material.dart';
import '../../auth/models/user.dart';
import '../../auth/services/auth_service.dart';
import '../../parking/models/parking_lot.dart';
import '../../parking/models/parking_spot.dart';
import '../../parking/services/parking_lot_service.dart';
import '../../parking/models/violation_config.dart';
import '../../parking/services/violation_config_service.dart';

class PostavkeScreen extends StatefulWidget {
  const PostavkeScreen({super.key});

  @override
  State<PostavkeScreen> createState() => _PostavkeScreenState();
}

class _PostavkeScreenState extends State<PostavkeScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _parkingService = ParkingLotService();
  final _authService = AuthService();
  final _violationConfigService = ViolationConfigService();
  List<ViolationConfig> _violationConfigs = [];
  List<ParkingLot> _lots = [];
  List<ParkingSpot> _spots = [];
  List<UserModel> _users = [];
  ParkingLot? _selectedLot;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadAll();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    await Future.wait([_loadLots(), _loadUsers()]);
    setState(() => _isLoading = false);
    await Future.wait([_loadLots(), _loadUsers(), _loadViolationConfigs()]);
  }

  Future<void> _loadViolationConfigs() async {
    try {
      final configs = await _violationConfigService.getAll();
      setState(() => _violationConfigs = configs);
    } catch (_) {}
  }

  Future<void> _loadLots() async {
    try {
      final lots = await _parkingService.getAllAdmin();
      setState(() {
        _lots = lots;
        if (_selectedLot != null) {
          _selectedLot = lots.firstWhere(
                (l) => l.id == _selectedLot!.id,
            orElse: () => lots.isNotEmpty ? lots.first : _selectedLot!,
          );
        } else if (lots.isNotEmpty) {
          _selectedLot = lots.first;
          _loadSpots();
        }
      });
    } catch (_) {}
  }

  Future<void> _loadSpots() async {
    if (_selectedLot == null) return;
    try {
      final spots = await _parkingService.getSpotsByLotId(_selectedLot!.id);
      spots.sort((a, b) => _naturalCompare(a.spotNumber, b.spotNumber));
      setState(() => _spots = spots);
    } catch (_) {}
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _authService.getAllUsers();
      setState(() => _users = users);
    } catch (_) {}
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

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1A5276);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _PostavkeTabButton(
              label: 'Korisnici',
              isSelected: _tabController.index == 0,
              onTap: () => setState(() => _tabController.animateTo(0)),
            ),
            const SizedBox(width: 8),
            _PostavkeTabButton(
              label: 'Parking zone',
              isSelected: _tabController.index == 1,
              onTap: () => setState(() => _tabController.animateTo(1)),
            ),
            const SizedBox(width: 8),
            _PostavkeTabButton(
              label: 'Parking mjesta',
              isSelected: _tabController.index == 2,
              onTap: () => setState(() => _tabController.animateTo(2)),
            ),
            const SizedBox(width: 8),
            _PostavkeTabButton(
              label: 'Prekršaji',
              isSelected: _tabController.index == 3,
              onTap: () => setState(() => _tabController.animateTo(3)),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
            controller: _tabController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildUsersTab(primaryBlue),
              _buildLotsTab(primaryBlue),
              _buildSpotsTab(primaryBlue),
              _buildViolationsTab(primaryBlue),
            ],
          ),
        ),
      ],
    );
  }

  // ---- TAB 0: Korisnici ----
  Widget _buildUsersTab(Color primaryBlue) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Container(
            height: 48,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
            ),
            child: Row(
              children: const [
                Expanded(child: Center(child: Text('Ime i prezime', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text('Email', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text('Telefon', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text('Uloga', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text('Akcija', style: TextStyle(fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _users.length,
              itemBuilder: (context, index) {
                final user = _users[index];
                return Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8), child: Text(user.fullName))),
                      Expanded(child: Center(child: Text(user.email, style: const TextStyle(fontSize: 13)))),
                      Expanded(child: Center(child: Text(user.phoneNumber ?? '–'))),
                      Expanded(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: user.role == 1 ? const Color(0xFF1A5276) : const Color(0xFF2E86C1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(user.roleLabel, style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: user.isActive ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(user.isActive ? 'Aktivan' : 'Neaktivan', style: const TextStyle(color: Colors.white, fontSize: 12)),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Center(
                          child: IconButton(
                            icon: const Icon(Icons.delete, color: Color(0xFFE74C3C)),
                            onPressed: () => _confirmDelete(
                              'Obriši korisnika',
                              'Da li ste sigurni da želite obrisati korisnika "${user.fullName}"?',
                                  () async {
                                await _authService.deleteUser(user.id);
                                _loadUsers();
                              },
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---- TAB 1: Parking zone ----
  Widget _buildLotsTab(Color primaryBlue) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [

          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _showAddLotDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Dodaj zonu'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),

          Container(
            height: 48,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
            ),
            child: Row(
              children: const [
                Expanded(child: Center(child: Text('Naziv', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text('Adresa', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text('Mjesta', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text('Cijena/min', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text('Radno vrijeme', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text('Akcija', style: TextStyle(fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _lots.length,
              itemBuilder: (context, index) {
                final lot = _lots[index];
                return Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Padding(padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8), child: Text(lot.name))),
                      Expanded(child: Center(child: Text(lot.address, style: const TextStyle(fontSize: 13)))),
                      Expanded(child: Center(child: Text('${lot.totalSpots}'))),
                      Expanded(child: Center(child: Text('${lot.ratePerMinute.toStringAsFixed(2)} KM'))),
                      Expanded(child: Center(child: Text('${lot.openTime.substring(0, 5)} – ${lot.closeTime.substring(0, 5)}'))),
                      Expanded(
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: lot.isActive ? const Color(0xFF27AE60) : const Color(0xFFE74C3C),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              lot.isActive ? 'Aktivna' : 'Neaktivna',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF1A5276)),
                              onPressed: () => _showLotDialog(lot: lot),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Color(0xFFE74C3C)),
                              onPressed: () => _confirmDelete(
                                'Obriši zonu',
                                'Da li ste sigurni da želite obrisati zonu "${lot.name}"?',
                                    () async {
                                  await _parkingService.deleteLot(lot.id);
                                  _loadLots();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ---- TAB 2: Parking mjesta ----
  Widget _buildSpotsTab(Color primaryBlue) {
    return Column(
      children: [
        Row(
          children: [
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
                    if (lot != null) {
                      setState(() => _selectedLot = lot);
                      _loadSpots();
                    }
                  },
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Container(
                  height: 48,
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
                  ),
                  child: Row(
                    children: const [
                      Expanded(child: Center(child: Text('Broj mjesta', style: TextStyle(fontWeight: FontWeight.bold)))),
                      Expanded(child: Center(child: Text('Tip', style: TextStyle(fontWeight: FontWeight.bold)))),
                      Expanded(child: Center(child: Text('Status', style: TextStyle(fontWeight: FontWeight.bold)))),
                      Expanded(child: Center(child: Text('Rezervabilno', style: TextStyle(fontWeight: FontWeight.bold)))),
                      Expanded(child: Center(child: Text('Sprat', style: TextStyle(fontWeight: FontWeight.bold)))),
                      Expanded(child: Center(child: Text('Akcija', style: TextStyle(fontWeight: FontWeight.bold)))),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _spots.length,
                    itemBuilder: (context, index) {
                      final spot = _spots[index];
                      return Container(
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
                        ),
                        child: Row(
                          children: [
                            Expanded(child: Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 16), child: Text(spot.spotNumber)))),
                            Expanded(child: Center(child: Text(_spotTypeLabel(spot.type)))),
                            Expanded(child: Center(child: Text(_spotStatusLabel(spot.status)))),
                            Expanded(child: Center(child: Icon(spot.isReservable ? Icons.check_circle : Icons.cancel, color: spot.isReservable ? const Color(0xFF27AE60) : Colors.grey))),
                            Expanded(child: Center(child: Text(spot.floor != null ? '${spot.floor}' : '–'))),
                            Expanded(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [

                                  IconButton(
                                    icon: Icon(
                                      Icons.edit,
                                      color: spot.status == 0 ? const Color(0xFF1A5276) : Colors.grey,
                                    ),
                                    onPressed: spot.status == 0
                                        ? () => _showSpotDialog(spot: spot)
                                        : null, // disabled ako je zauzeto
                                    tooltip: spot.status != 0 ? 'Ne možete urediti zauzeto mjesto' : null,
                                  ),


                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Color(0xFFE74C3C)),
                                    onPressed: () => _confirmDelete(
                                      'Obriši mjesto',
                                      'Da li ste sigurni da želite obrisati mjesto "${spot.spotNumber}"?',
                                          () async {
                                        await _parkingService.deleteSpot(spot.id);
                                        _loadSpots();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---- TAB 3: Prekršaji ----
  Widget _buildViolationsTab(Color primaryBlue) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => _showAddViolationConfigDialog(),
                icon: const Icon(Icons.add),
                label: const Text('Dodaj tip prekršaja'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ),
          Container(
            height: 48,
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
            ),
            child: Row(
              children: const [
                Expanded(child: Center(child: Text('Tip prekršaja', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text('Opis', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text('Cijena (KM)', style: TextStyle(fontWeight: FontWeight.bold)))),
                Expanded(child: Center(child: Text('Akcija', style: TextStyle(fontWeight: FontWeight.bold)))),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _violationConfigs.length,
              itemBuilder: (context, index) {
                final config = _violationConfigs[index];
                return Container(
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Color(0xFFE0E0E0))),
                  ),
                  child: Row(
                    children: [
                      Expanded(child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                        child: Text(config.typeName),
                      )),
                      Expanded(child: Center(child: Text(config.description, style: const TextStyle(fontSize: 13)))),
                      Expanded(child: Center(child: Text('${config.fineAmount.toStringAsFixed(2)} KM'))),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF1A5276)),
                              onPressed: () => _showEditViolationConfigDialog(config),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Color(0xFFE74C3C)),
                              onPressed: () => _confirmDelete(
                                'Obriši tip prekršaja',
                                'Da li ste sigurni da želite obrisati "${config.typeName}"?',
                                    () async {
                                  await _violationConfigService.delete(config.id);
                                  _loadViolationConfigs();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  void _showAddViolationConfigDialog() {
    final typeNameController = TextEditingController();
    final descriptionController = TextEditingController();
    final fineAmountController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Dodaj tip prekršaja', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _DialogField('Naziv tipa', typeNameController),
              const SizedBox(height: 12),
              _DialogField('Opis', descriptionController),
              const SizedBox(height: 12),
              _DialogField('Cijena (KM)', fineAmountController, keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await _violationConfigService.create({
                            'typeName': typeNameController.text,
                            'description': descriptionController.text,
                            'fineAmount': double.tryParse(fineAmountController.text.replaceAll(',', '.')) ?? 0,
                          });
                          Navigator.pop(context);
                          _loadViolationConfigs();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Greška: $e'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A5276),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Dodaj'),
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
      ),
    );
  }

  void _showEditViolationConfigDialog(ViolationConfig config) {
    final typeNameController = TextEditingController(text: config.typeName);
    final descriptionController = TextEditingController(text: config.description);
    final fineAmountController = TextEditingController(text: config.fineAmount.toString());

    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
          width: 450,
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Uredi tip prekršaja', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),
              _DialogField('Naziv tipa', typeNameController),
              const SizedBox(height: 12),
              _DialogField('Opis', descriptionController),
              const SizedBox(height: 12),
              _DialogField('Cijena (KM)', fineAmountController, keyboardType: TextInputType.number),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        try {
                          await _violationConfigService.update(config.id, {
                            'typeName': typeNameController.text,
                            'description': descriptionController.text,
                            'fineAmount': double.tryParse(fineAmountController.text.replaceAll(',', '.')) ?? 0,
                          });
                          Navigator.pop(context);
                          _loadViolationConfigs();
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Greška: $e'), backgroundColor: Colors.red),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A5276),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('Spremi'),
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
      ),
    );
  }






  void _showAddLotDialog() {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    final rateController = TextEditingController();
    final resRateController = TextEditingController();
    final openController = TextEditingController(text: '08:00');
    final closeController = TextEditingController(text: '22:00');
    final totalSpotsController = TextEditingController();
    bool isActive = true;
    int selectedType = 0;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Dodaj zonu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 24),
                  _DialogField('Naziv zone', nameController),
                  const SizedBox(height: 12),
                  _DialogField('Adresa', addressController),
                  const SizedBox(height: 12),
                  _DialogField('Broj mjesta', totalSpotsController, keyboardType: TextInputType.number),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: selectedType,
                    decoration: InputDecoration(
                      labelText: 'Tip parkinga',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF1A5276)),
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Otvoreni (bez kamera)')),
                      DropdownMenuItem(value: 1, child: Text('Zatvoreni (ulaz/izlaz kamere)')),
                    ],
                    onChanged: (v) => setDialogState(() => selectedType = v ?? 0),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _DialogField('Cijena/min (KM)', rateController, keyboardType: TextInputType.number)),
                      const SizedBox(width: 12),
                      Expanded(child: _DialogField('Cijena rezervacije/min', resRateController, keyboardType: TextInputType.number)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _DialogField('Otvaranje (HH:MM)', openController)),
                      const SizedBox(width: 12),
                      Expanded(child: _DialogField('Zatvaranje (HH:MM)', closeController)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Aktivna:', style: TextStyle(color: Colors.grey)),
                      const SizedBox(width: 8),
                      Switch(
                        value: isActive,
                        activeColor: const Color(0xFF1A5276),
                        onChanged: (v) => setDialogState(() => isActive = v),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(

                          onPressed: () async {
                            final lotName = nameController.text.trim();
                            final totalSpots = int.tryParse(totalSpotsController.text) ?? 0;
                            final data = {
                              'name': lotName,
                              'address': addressController.text,
                              'type': selectedType,
                              'totalSpots': totalSpots,
                              'ratePerMinute': double.tryParse(rateController.text.replaceAll(',', '.')) ?? 0,
                              'reservationRatePerMinute': double.tryParse(resRateController.text.replaceAll(',', '.')),
                              'openTime': '${openController.text}:00',
                              'closeTime': '${closeController.text}:00',
                            };

                            print('Creating lot with data: $data');
                            try {
                              final createdLot = await _parkingService.createLot(data);
                              // Auto-kreiraj spotove
                              final prefix = lotName.contains(' ')
                                  ? lotName.split(' ').last
                                  : lotName;
                              for (int i = 1; i <= totalSpots; i++) {
                                await _parkingService.createSpot({
                                  'lotId': createdLot.id,
                                  'spotNumber': '$prefix$i',
                                  'type': 0,
                                  'isReservable': false,
                                });
                              }
                              Navigator.pop(context);
                              _loadLots();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Greška: $e'), backgroundColor: Colors.red),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A5276),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: const Text('Dodaj'),
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
          ),
        ),
      ),
    );
  }

  void _showLotDialog({ParkingLot? lot}) {
    if (lot == null) return;
    final nameController = TextEditingController(text: lot.name);
    final addressController = TextEditingController(text: lot.address);
    final rateController = TextEditingController(text: lot.ratePerMinute.toString());
    final resRateController = TextEditingController(text: lot.reservationRatePerMinute?.toString() ?? '');
    final openController = TextEditingController(text: lot.openTime.substring(0, 5));
    final closeController = TextEditingController(text: lot.closeTime.substring(0, 5));
    bool isActive = lot.isActive;
    int selectedType = lot.type;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 500,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Uredi zonu', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                _DialogField('Naziv', nameController),
                const SizedBox(height: 12),
                _DialogField('Adresa', addressController),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Tip parkinga',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1A5276)),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Otvoreni (bez kamera)')),
                    DropdownMenuItem(value: 1, child: Text('Zatvoreni (ulaz/izlaz kamere)')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedType = v ?? 0),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _DialogField('Cijena/min (KM)', rateController, keyboardType: TextInputType.number)),
                    const SizedBox(width: 12),
                    Expanded(child: _DialogField('Cijena rezervacije/min', resRateController, keyboardType: TextInputType.number)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _DialogField('Otvaranje (HH:MM)', openController)),
                    const SizedBox(width: 12),
                    Expanded(child: _DialogField('Zatvaranje (HH:MM)', closeController)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Aktivna:', style: TextStyle(color: Colors.grey)),
                    const SizedBox(width: 8),
                    Switch(
                      value: isActive,
                      activeColor: const Color(0xFF1A5276),
                      onChanged: (v) => setDialogState(() => isActive = v),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {

                          final data = {
                            'name': nameController.text,
                            'address': addressController.text,
                            'type': selectedType,
                            'totalSpots': lot.totalSpots,
                            'ratePerMinute': double.tryParse(rateController.text) ?? 0,
                            'reservationRatePerMinute': double.tryParse(resRateController.text),
                            'openTime': '${openController.text}:00',
                            'closeTime': '${closeController.text}:00',
                            'isActive': isActive,
                          };


                          await _parkingService.updateLot(lot.id, data);
                          Navigator.pop(context);
                          _loadLots();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A5276),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Spremi'),
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
        ),
      ),
    );
  }

  void _showSpotDialog({ParkingSpot? spot}) {
    if (spot == null) return;
    final numberController = TextEditingController(text: spot.spotNumber);
    final floorController = TextEditingController(text: spot.floor?.toString() ?? '');
    int selectedType = spot.type;
    bool isReservable = spot.isReservable;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 400,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Uredi mjesto', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 24),
                _DialogField('Broj mjesta', numberController),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: selectedType,
                  decoration: InputDecoration(
                    labelText: 'Tip mjesta',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1A5276)),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Normalno')),
                    DropdownMenuItem(value: 1, child: Text('Invalidsko')),
                    DropdownMenuItem(value: 2, child: Text('Električno vozilo')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedType = v ?? 0),
                ),
                const SizedBox(height: 12),
                _DialogField('Sprat (opcionalno)', floorController, keyboardType: TextInputType.number),
                const SizedBox(height: 12),
                Row(
                  children: [
                    const Text('Rezervabilno:', style: TextStyle(color: Colors.grey)),
                    const SizedBox(width: 8),
                    Switch(
                      value: isReservable,
                      activeColor: const Color(0xFF1A5276),
                      onChanged: (v) => setDialogState(() => isReservable = v),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final data = {
                            'spotNumber': numberController.text,
                            'type': selectedType,
                            'isReservable': isReservable,
                            'floor': int.tryParse(floorController.text),
                            'lotId': _selectedLot!.id,
                          };
                          await _parkingService.updateSpot(spot.id, data);
                          Navigator.pop(context);
                          _loadSpots();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1A5276),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Spremi'),
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
        ),
      ),
    );
  }

  Future<void> _confirmDelete(String title, String message, Future<void> Function() onConfirm) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Odustani'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE74C3C),
              foregroundColor: Colors.white,
            ),
            child: const Text('Obriši'),
          ),
        ],
      ),
    );
    if (confirmed == true) await onConfirm();
  }

  String _spotTypeLabel(int type) {
    switch (type) {
      case 0: return 'Normalno';
      case 1: return 'Invalidsko';
      case 2: return 'Električno';
      default: return '–';
    }
  }

  String _spotStatusLabel(int status) {
    switch (status) {
      case 0: return 'Slobodno';
      case 1: return 'Zauzeto';
      case 2: return 'Rezervisano';
      case 3: return 'Van usluge';
      default: return '–';
    }
  }
}

class _PostavkeTabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _PostavkeTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1A5276);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: primaryBlue),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : primaryBlue,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _DialogField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType keyboardType;

  const _DialogField(this.label, this.controller,
      {this.keyboardType = TextInputType.text});

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF1A5276)),
        ),
      ),
    );
  }
}