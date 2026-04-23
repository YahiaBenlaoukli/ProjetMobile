import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../services/biometric_service.dart';

class BiometricScreen extends StatefulWidget {
  final Widget nextScreen;

  const BiometricScreen({super.key, required this.nextScreen});

  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen> {
  bool _isAuthenticated = false;
  bool _isAuthenticating = false;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    final biometricService = context.read<BiometricService>();
    final isSupported = await biometricService.isBiometricSupported();

    if (!isSupported) {
      // If not supported, skip authentication (or handle differently)
      _proceedToNextScreen();
      return;
    }

    _authenticate();
  }

  Future<void> _authenticate() async {
    if (_isAuthenticating) return;
    
    setState(() {
      _isAuthenticating = true;
    });

    final biometricService = context.read<BiometricService>();
    final success = await biometricService.authenticate(
      reason: 'Unlock the Secure Audio App',
    );

    if (mounted) {
      setState(() {
        _isAuthenticating = false;
        _isAuthenticated = success;
      });

      if (success) {
        _proceedToNextScreen();
      }
    }
  }

  void _proceedToNextScreen() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => widget.nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_outline,
              size: 100,
              color: Colors.deepPurple,
            ),
            const SizedBox(height: 30),
            const Text(
              'App Locked',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            if (!_isAuthenticated && !_isAuthenticating)
              ElevatedButton.icon(
                onPressed: _authenticate,
                icon: const Icon(Icons.fingerprint),
                label: const Text('Unlock to Continue'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                ),
              ),
            if (_isAuthenticating)
              const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
