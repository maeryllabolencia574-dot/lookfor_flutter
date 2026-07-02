import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';

import '../services/api_client.dart';
import '../services/auth_session_store.dart';
import 'dashboard_screen.dart';
import 'login_screen.dart';

class BiometricScreen extends StatefulWidget {
  const BiometricScreen({Key? key}) : super(key: key);

  @override
  State<BiometricScreen> createState() => _BiometricScreenState();
}

class _BiometricScreenState extends State<BiometricScreen> {
  final LocalAuthentication _auth = LocalAuthentication();
  bool _canCheckBiometrics = false;
  bool _hasSavedSession = false;
  bool _isAuthenticating = false;
  String _statusMessage = 'Checking biometric login...';
  String? _savedEmail;

  @override
  void initState() {
    super.initState();
    _checkBiometrics();
  }

  Future<void> _checkBiometrics() async {
    bool canCheckBiometrics = false;
    AuthSession? savedSession;
    try {
      final isDeviceSupported = await _auth.isDeviceSupported();
      final hasBiometrics = await _auth.canCheckBiometrics;
      final availableBiometrics = await _auth.getAvailableBiometrics();
      canCheckBiometrics =
          isDeviceSupported && hasBiometrics && availableBiometrics.isNotEmpty;
      savedSession = await AuthSessionStore.load();
    } catch (_) {
      canCheckBiometrics = false;
    }

    if (!mounted) return;

    setState(() {
      _canCheckBiometrics = canCheckBiometrics;
      _hasSavedSession = savedSession != null;
      _savedEmail = savedSession?.email;
      _statusMessage = _buildReadyMessage(canCheckBiometrics, savedSession);
    });
  }

  String _buildReadyMessage(bool canUseBiometrics, AuthSession? session) {
    if (!canUseBiometrics) {
      return 'No enrolled fingerprint or face authentication was found on this device.';
    }
    if (session == null) {
      return 'Login once with your email and password to save this account for biometric login.';
    }
    return 'Ready to sign in${session.email == null ? '' : ' as ${session.email}'}.';
  }

  Future<void> _authenticate() async {
    setState(() {
      _isAuthenticating = true;
      _statusMessage = 'Authenticating...';
    });

    try {
      final savedSession = await AuthSessionStore.load();
      if (savedSession == null) {
        setState(() {
          _hasSavedSession = false;
          _isAuthenticating = false;
          _statusMessage =
              'No saved account found. Please login with email and password first.';
        });
        return;
      }

      final authenticated = await _auth.authenticate(
        localizedReason: 'Scan your fingerprint or face to login',
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );

      if (!authenticated) {
        if (!mounted) return;
        setState(() {
          _isAuthenticating = false;
          _statusMessage = 'Biometric authentication was cancelled or failed.';
        });
        return;
      }

      apiClient.setToken(
        savedSession.accessToken,
        isAdmin: savedSession.isAdmin,
      );

      await _verifySavedSession();
    } catch (e) {
      if (!mounted) return;
      apiClient.clearToken();
      await AuthSessionStore.clear();
      if (!mounted) return;
      setState(() {
        _hasSavedSession = false;
        _isAuthenticating = false;
        _statusMessage =
            'Saved login expired or could not be verified. Please login with your password again.';
      });
    }
  }

  Future<void> _verifySavedSession() async {
    try {
      final user = await apiClient.getCurrentUser();
      final mustChangePassword = _truthy(user['must_change_password']);

      if (!mounted) return;

      if (mustChangePassword) {
        apiClient.clearToken();
        await AuthSessionStore.clear();
        if (!mounted) return;
        setState(() {
          _hasSavedSession = false;
          _isAuthenticating = false;
          _statusMessage =
              'Your password must be changed before biometric login can be used.';
        });
        return;
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (_) {
      try {
        await apiClient.refreshToken();
        await AuthSessionStore.save(
          accessToken: apiClient.accessToken!,
          isAdmin: apiClient.isAdmin,
          email: _savedEmail,
        );
        await apiClient.getCurrentUser();

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      } catch (_) {
        rethrow;
      }
    }
  }

  bool _truthy(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }

  void _goToPasswordLogin() {
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Biometric Login'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Icon(
              Icons.fingerprint,
              size: 100,
              color: Colors.blueAccent,
            ),
            const SizedBox(height: 24),
            const Text(
              'Welcome back',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Use your fingerprint or face recognition to sign in securely.',
              style: TextStyle(fontSize: 16, color: Colors.black54),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Biometric available'),
                        Text(_canCheckBiometrics ? 'Yes' : 'No'),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Saved account'),
                        Flexible(
                          child: Text(
                            _hasSavedSession
                                ? (_savedEmail ?? 'Available')
                                : 'None',
                            textAlign: TextAlign.end,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _statusMessage,
                        style: const TextStyle(color: Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.fingerprint),
                label: Text(_isAuthenticating ? 'Authenticating' : 'Login with Biometrics'),
                onPressed: _canCheckBiometrics && _hasSavedSession && !_isAuthenticating
                    ? _authenticate
                    : null,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _isAuthenticating ? null : _goToPasswordLogin,
              child: const Text('Use email and password'),
            ),
          ],
        ),
      ),
    );
  }
}
