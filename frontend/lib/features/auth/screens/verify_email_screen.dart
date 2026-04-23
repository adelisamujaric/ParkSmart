import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _authService = AuthService();
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _startPolling();
  }

  void _startPolling() async {
    while (!_isVerified && mounted) {
      await Future.delayed(const Duration(seconds: 3));
      try {
        final verified = await _authService.checkEmailVerified(widget.email);
        if (verified && mounted) {
          setState(() {
            _isVerified = true;
          });
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryBlue = Color(0xFF1A5276);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F3F4),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40),
                    child: Container(
                      width: 400,
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 20,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'ParkSmart',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 40),
                          Icon(
                            _isVerified ? Icons.check_circle_outline : Icons.mark_email_unread_outlined,
                            size: 64,
                            color: _isVerified ? Colors.green : primaryBlue,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            _isVerified ? 'Email potvrđen!' : 'Provjerite vaš email',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: _isVerified ? Colors.green : primaryBlue,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _isVerified
                                ? 'Vaš račun je aktiviran. Možete se prijaviti.'
                                : 'Poslali smo vam link za potvrdu na ${widget.email}. Kliknite na link kako biste aktivirali vaš račun.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14, color: Colors.grey),
                          ),
                          const SizedBox(height: 40),
                          if (_isVerified)
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                child: const Text('Prijava', style: TextStyle(fontSize: 16)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}