import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController email = TextEditingController();
  final TextEditingController password = TextEditingController();
bool obscurePassword = true;
bool isLoading = false;
  @override
  void dispose() {
    email.dispose();
    password.dispose();
    super.dispose();
  }

  // =====================
  // COMMON INPUT DECORATION (1px BORDER)
  // =====================
  InputDecoration inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Colors.grey,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(
          color: Color(0xFF005BAB),
          width: 1,
        ),
      ),
    );
  }

  void _login() {
    if (email.text.endsWith('@novaliches.sti.edu.ph') || email.text.endsWith('@novaliches.sti.edu.ph') &&
        password.text.length == 6) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid STI email or password")),
      );
    }
  }

  // =====================
  // FORGOT PASSWORD MODAL
  // =====================
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
                  onPressed: () {
                    Navigator.pop(context);
                    _showOtpVerificationModal();
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

  // =====================
  // OTP VERIFICATION MODAL
  // =====================
  void _showOtpVerificationModal() {
    final controllers = List.generate(6, (_) => TextEditingController());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "OTP Verification",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 16),

            // OTP BOXES WITH 1px BORDER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: controllers.map((c) {
                return SizedBox(
                  width: 45,
                  child: TextField(
                    controller: c,
                    maxLength: 1,
                    textAlign: TextAlign.center,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      counterText: "",
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Colors.grey,
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color:Color(0xFF0066CC),
                          width: 1,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
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
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("OTP verified. Password reset allowed."),
                    ),
                  );
                },
                child: const Text("Verify OTP"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: const Color(0xFF0066CC)),
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Look",
                      style: GoogleFonts.greatVibes(
                        fontSize: 44,
                        color: Color(0xFF0066CC),
                      ),
                    ),
                    Text(
                      "For",
                      style: GoogleFonts.greatVibes(
                        fontSize: 44,
                        color: const Color(0xFFFFE000),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // EMAIL FIELD
                TextField(
                  controller: email,
                  decoration: inputDecoration("Email"),
                ),
                const SizedBox(height: 16),

                // PASSWORD FIELD
                TextField(
  controller: password,
  obscureText: obscurePassword, // ✅ USE STATE VARIABLE
  decoration: inputDecoration("Password").copyWith(
    suffixIcon: IconButton(
      icon: Icon(
        obscurePassword
            ? Icons.visibility_off
            : Icons.visibility,
        color: Colors.grey,
      ),
      onPressed: () {
        setState(() {
          obscurePassword = !obscurePassword;
        });
      },
    ),
  ),
),
                

                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFE000),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: _login,
                    child: const Text("Log in"),
                    
                  ),
                ),
                TextButton(
                  onPressed: _showForgotPasswordModal,
                  child: const Text("Forgot Password"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
