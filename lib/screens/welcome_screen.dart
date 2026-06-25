import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // 🔹 Logo / Title
            Column(
              children: [
                RichText(
                  text: const TextSpan(
                    children: [
                      TextSpan(
                        text: "Look",
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF005BAB),
                        ),
                      ),
                      TextSpan(
                        text: "For",
                        style: TextStyle(
                          fontSize: 42,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFFCC00),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                const Icon(Icons.search, size: 40, color: Colors.grey),
              ],
            ),

            const SizedBox(height: 40),

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
                  // TODO: Add biometrics logic
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
              onPressed: () {
                // TODO: forgot password logic
              },
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
                children: const [
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.home, color: Color(0xFF005BAB)),
                      SizedBox(height: 4),
                      Text("Login"),
                    ],
                  ),
                  VerticalDivider(width: 1),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.more_horiz, color: Colors.grey),
                      SizedBox(height: 4),
                      Text("More"),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
