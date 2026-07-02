import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_client.dart';


// ...existing code...
class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // 🔹 Logo / Title
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Look",
                  style: GoogleFonts.greatVibes(
                    fontSize: 60,
                    color: const Color(0xFF005BAB),
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "For",
                  style: GoogleFonts.greatVibes(
                    fontSize: 60,
                    color: const Color(0xFFFFCC00),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 30),
            // 🔹 Biometrics Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.fingerprint, size: 28),
                label: const Text(
                  "Log in with Biometrics",
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, '/biometric');
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF005BAB),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🔹 Login with Password
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.lock, size: 26),
                label: const Text(
                  "Log in with Password",
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF005BAB),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // 🔹 Forgot Password
            TextButton(
              onPressed: _showForgotPasswordModal,
              child: const Text(
                "Forgot Password?",
                style: TextStyle(
                  color: Color(0xFF005BAB),
                  fontSize: 15,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),

            const Spacer(),

            // 🔹 Bottom Navigation Style Bar
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.home, color: Color(0xFF005BAB)),
                      SizedBox(height: 4),
                      Text("Login"),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  /*Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.more_horiz, color: Colors.grey),
                      const SizedBox(height: 4),
                      const Text("More"),
                      TextButton(
                        onPressed: () {
                          Navigator.pushReplacementNamed(context, '/more');
                        },
                        child: const Text("More"),
                      ),
                    ],
                  ),*/
                  GestureDetector(
                    onTap: () {
                      Navigator.pushReplacementNamed(context, '/more');
                    },
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.more_horiz, color: Colors.grey),
                        SizedBox(height: 4),
                        Text("More"),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      filled: true,
      fillColor: Colors.grey[100],
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  void _showForgotPasswordModal() {
    final TextEditingController resetEmail = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Forgot Password",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "Enter your STI email address and we will send you a verification code.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // EMAIL WITH BORDER
              TextField(
                controller: resetEmail,
                decoration: inputDecoration("STI Email"),
              ),

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE000),
                    foregroundColor: Colors.black,
                  ),
                  onPressed: () async {
                    if (!resetEmail.text.endsWith('@novaliches.sti.edu.ph') &&
                        !resetEmail.text.endsWith('@novaliches.sti.edu')) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please use a valid STI email"),
                        ),
                      );
                      return;
                    }

                    try {
                      await apiClient.requestPasswordReset(resetEmail.text);
                      if (!mounted) return;
                      Navigator.pop(context);
                      _showOtpVerificationModal(resetEmail.text);
                    } catch (e) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            "Failed to send code: ${e.toString()}",
                          ),
                        ),
                      );
                    }
                  },
                  child: const Text("Send Code"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOtpVerificationModal(String email) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Verification Code Sent'),
        content: Text('A verification code was sent to $email.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
