import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_screen.dart';
import '../services/api_client.dart';

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
        borderSide: const BorderSide(color: Colors.grey, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFF005BAB), width: 1),
      ),
    );
  }

  void _login() async {
    if (!email.text.endsWith('@novaliches.sti.edu.ph') &&
        !email.text.endsWith('@novaliches.sti.edu')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please use a valid STI email")),
      );
      return;
    }

    if (password.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your password")),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await apiClient.login(email.text, password.text);

      // Check if MFA is required
      if (response.containsKey('step') && response['step'] == 'mfa_required') {
        setState(() => isLoading = false);
        _showMFAVerification(email.text);
        return;
      }

      // Login successful
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const DashboardScreen()),
        );
      }
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login failed: ${e.toString()}")),
        );
      }
    }
  }

  // =====================
  // MFA VERIFICATION MODAL
  // =====================
  void _showMFAVerification(String email) {
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
              "MFA Verification",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF003366),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              "Enter the 6-digit code sent to your email",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),

            // OTP BOXES
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
                          color: Color(0xFF0066CC),
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
                onPressed: () async {
                  final code = controllers.map((c) => c.text).join();
                  if (code.length != 6) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Please enter all 6 digits"),
                      ),
                    );
                    return;
                  }

                  try {
                    await apiClient.verifyMfa(email, code);
                    if (mounted) {
                      Navigator.pop(context);
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const DashboardScreen(),
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("Verification failed: ${e.toString()}"),
                        ),
                      );
                    }
                  }
                },
                child: const Text("Verify Code"),
              ),
            ),
          ],
        ),
      ),
    );
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
                      if (mounted) {
                        Navigator.pop(context);
                        _showOtpVerificationModal(resetEmail.text);
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Failed to send code: ${e.toString()}",
                            ),
                          ),
                        );
                      }
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

  // =====================
  // OTP VERIFICATION MODAL
  // =====================
  void _showOtpVerificationModal(String email) {
    final controllers = List.generate(6, (_) => TextEditingController());
    final newPasswordController = TextEditingController();

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
                "Reset Password",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF003366),
                ),
              ),
              const SizedBox(height: 16),

              // OTP BOXES
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
                            color: Color(0xFF0066CC),
                            width: 1,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(height: 16),

              // NEW PASSWORD FIELD
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: inputDecoration("New Password"),
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
                    final code = controllers.map((c) => c.text).join();
                    if (code.length != 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please enter all 6 digits"),
                        ),
                      );
                      return;
                    }

                    if (newPasswordController.text.length < 6) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            "Password must be at least 6 characters",
                          ),
                        ),
                      );
                      return;
                    }

                    try {
                      await apiClient.resetPassword(
                        email,
                        code,
                        newPasswordController.text,
                      );
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              "Password reset successful. Please login.",
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text("Reset failed: ${e.toString()}"),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text("Reset Password"),
                ),
              ),
            ],
          ),
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
