import 'package:flutter/material.dart';
import '../models/register_request.dart';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  String? _errorMessage;

  final _errors = <String, String?>{};

  static const primaryBlue = Color(0xFF1A5276);

  String? _validateRequired(String value, String fieldName) {
    if (value.trim().isEmpty) return '$fieldName je obavezno polje.';
    return null;
  }

  String? _validateEmail(String value) {
    if (value.trim().isEmpty) return 'Email je obavezno polje.';
    final emailRegex = RegExp(r'^[\w\-.]+@([\w\-]+\.)+[\w\-]{2,}$');
    if (!emailRegex.hasMatch(value.trim())) return 'Unesite ispravan email.';
    return null;
  }

  String? _validatePassword(String value) {
    if (value.isEmpty) return 'Lozinka je obavezno polje.';
    if (value.length < 6) return 'Lozinka mora imati najmanje 6 znakova.';
    return null;
  }

  bool _validate() {
    final newErrors = {
      'firstName': _validateRequired(_firstNameController.text, 'Ime'),
      'lastName': _validateRequired(_lastNameController.text, 'Prezime'),
      'email': _validateEmail(_emailController.text),
      'password': _validatePassword(_passwordController.text),
    };
    setState(() => _errors.addAll(newErrors));
    return newErrors.values.every((e) => e == null);
  }

  Future<void> _register() async {
    if (!_validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await _authService.register(
        RegisterRequest(
          firstName: _firstNameController.text.trim(),
          lastName: _lastNameController.text.trim(),
          email: _emailController.text.trim(),
          password: _passwordController.text,
        ),
      );

      if (!mounted) return;
      Navigator.pushReplacementNamed(context, '/verify-email',
          arguments: _emailController.text.trim());
    }  catch (e) {
      setState(() {
      _errorMessage = e.toString().replaceAll('Exception: ', '');
      });

    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String errorKey,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          onChanged: (_) {
            if (_errors[errorKey] != null) {
              setState(() => _errors[errorKey] = null);
            }
          },
          decoration: InputDecoration(
            labelText: label,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: primaryBlue),
            ),
          ),
        ),
        if (_errors[errorKey] != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4, bottom: 4),
            child: Text(
              _errors[errorKey]!,
              style: const TextStyle(color: Colors.red, fontSize: 12),
            ),
          )
        else
          const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
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
                          const SizedBox(height: 8),
                          const Text(
                            'Kreirajte novi račun',
                            style: TextStyle(fontSize: 16, color: Colors.grey),
                          ),
                          const SizedBox(height: 40),
                          _buildField(
                            controller: _firstNameController,
                            label: 'Ime',
                            errorKey: 'firstName',
                          ),
                          _buildField(
                            controller: _lastNameController,
                            label: 'Prezime',
                            errorKey: 'lastName',
                          ),
                          _buildField(
                            controller: _emailController,
                            label: 'Email',
                            errorKey: 'email',
                            keyboardType: TextInputType.emailAddress,
                          ),
                          _buildField(
                            controller: _passwordController,
                            label: 'Lozinka',
                            errorKey: 'password',
                            obscureText: true,
                          ),
                          if (_errorMessage != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(_errorMessage!,
                                  style: const TextStyle(color: Colors.red)),
                            ),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _register,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: _isLoading
                                  ? const CircularProgressIndicator(
                                  color: Colors.white)
                                  : const Text('Registracija',
                                  style: TextStyle(fontSize: 16)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextButton(
                            onPressed: () =>
                                Navigator.pushReplacementNamed(context, '/'),
                            child: const Text(
                              'Nazad',
                              style: TextStyle(color: primaryBlue),
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