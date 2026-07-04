import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_screen.dart';
import '../services/api_client.dart';
import '../services/auth_session_store.dart';
import 'welcome_screen.dart';

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

  static final RegExp _uppercasePattern = RegExp(r'[A-Z]');
  static final RegExp _lowercasePattern = RegExp(r'[a-z]');
  static final RegExp _numberPattern = RegExp(r'[0-9]');
  static final RegExp _specialPattern = RegExp(r'[^A-Za-z0-9]');

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

      await _continueAfterAuthenticated(
        currentPassword: password.text,
        authenticatedEmail: email.text,
      );
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Login failed: ${e.toString()}")),
        );
      }
    }
  }

  Future<void> _continueAfterAuthenticated({
    required String currentPassword,
    required String authenticatedEmail,
  }) async {
    try {
      final user = await apiClient.getCurrentUser();
      final mustChangePassword = _truthy(user['must_change_password']);

      if (!mounted) return;
      setState(() => isLoading = false);

      if (mustChangePassword) {
        final changed = await _showDefaultPasswordChangeDialog(
          currentPassword: currentPassword,
        );
        if (!changed || !mounted) return;
      }

      final accessToken = apiClient.accessToken;
      if (accessToken != null && accessToken.isNotEmpty) {
        await AuthSessionStore.save(
          accessToken: accessToken,
          isAdmin: apiClient.isAdmin,
          email: authenticatedEmail,
        );
      }

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const DashboardScreen()),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unable to verify password status: ${e.toString()}"),
        ),
      );
    }
  }

  bool _truthy(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final text = value?.toString().trim().toLowerCase();
    return text == 'true' || text == '1' || text == 'yes';
  }

  bool _isStrongPassword(String value, String currentPassword) {
    return value.length >= 8 &&
        _uppercasePattern.hasMatch(value) &&
        _lowercasePattern.hasMatch(value) &&
        _numberPattern.hasMatch(value) &&
        _specialPattern.hasMatch(value) &&
        value != currentPassword;
  }

  Future<bool> _showDefaultPasswordChangeDialog({
    required String currentPassword,
  }) async {
    final newPassword = TextEditingController();
    final confirmPassword = TextEditingController();
    bool obscureNewPassword = true;
    bool obscureConfirmPassword = true;
    bool isUpdating = false;

    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: StatefulBuilder(
          builder: (context, setDialogState) {
            final passwordText = newPassword.text;
            final confirmText = confirmPassword.text;
            final canSubmit =
                _isStrongPassword(passwordText, currentPassword) &&
                confirmText == passwordText;

            void refreshRequirements(String _) {
              setDialogState(() {});
            }

            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              title: const Text(
                "Change Default Password",
                style: TextStyle(
                  color: Color(0xFF003366),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Your account is still using the default password. Create a new password to continue.",
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: newPassword,
                      obscureText: obscureNewPassword,
                      onChanged: refreshRequirements,
                      decoration: inputDecoration("New Password").copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureNewPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureNewPassword = !obscureNewPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmPassword,
                      obscureText: obscureConfirmPassword,
                      onChanged: refreshRequirements,
                      decoration: inputDecoration("Confirm Password").copyWith(
                        suffixIcon: IconButton(
                          icon: Icon(
                            obscureConfirmPassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setDialogState(() {
                              obscureConfirmPassword = !obscureConfirmPassword;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _passwordRequirement(
                      "At least 8 characters",
                      passwordText.length >= 8,
                    ),
                    _passwordRequirement(
                      "One uppercase letter",
                      _uppercasePattern.hasMatch(passwordText),
                    ),
                    _passwordRequirement(
                      "One lowercase letter",
                      _lowercasePattern.hasMatch(passwordText),
                    ),
                    _passwordRequirement(
                      "One number",
                      _numberPattern.hasMatch(passwordText),
                    ),
                    _passwordRequirement(
                      "One special character",
                      _specialPattern.hasMatch(passwordText),
                    ),
                    _passwordRequirement(
                      "Different from the default password",
                      passwordText.isNotEmpty &&
                          passwordText != currentPassword,
                    ),
                    _passwordRequirement(
                      "Passwords match",
                      confirmText.isNotEmpty && confirmText == passwordText,
                    ),
                  ],
                ),
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFE000),
                      foregroundColor: Colors.black,
                    ),
                    onPressed: !canSubmit || isUpdating
                        ? null
                        : () async {
                            setDialogState(() => isUpdating = true);
                            try {
                              await apiClient.changePassword(
                                currentPassword: currentPassword,
                                newPassword: passwordText,
                              );
                              if (!dialogContext.mounted) return;
                              Navigator.pop(dialogContext, true);
                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Password changed successfully.",
                                    ),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (!dialogContext.mounted) return;
                              setDialogState(() => isUpdating = false);
                              if (mounted) {
                                ScaffoldMessenger.of(this.context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      "Failed to change password: ${e.toString()}",
                                    ),
                                  ),
                                );
                              }
                            }
                          },
                    child: isUpdating
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text("Update Password"),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    newPassword.dispose();
    confirmPassword.dispose();
    return changed ?? false;
  }

  Widget _passwordRequirement(String label, bool isMet) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.radio_button_unchecked,
            size: 18,
            color: isMet ? const Color(0xFF198754) : Colors.grey,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isMet ? const Color(0xFF198754) : Colors.grey.shade700,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
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
                      await _continueAfterAuthenticated(
                        currentPassword: password.text,
                        authenticatedEmail: email,
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
  final confirmPasswordController = TextEditingController();

  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => StatefulBuilder(
      builder: (context, setModalState) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: SingleChildScrollView(
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

                  const SizedBox(height: 8),

                  const Text(
                    "Enter the verification code sent to your email and create a new password.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey),
                  ),

                  const SizedBox(height: 20),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: controllers.map((c) {
                      return SizedBox(
                        width: 45,
                        child: TextField(
                          controller: c,
                          maxLength: 1,
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
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

                  TextField(
                    controller: newPasswordController,
                    obscureText: obscureNewPassword,
                    decoration: inputDecoration(
                      "New Password",
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureNewPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setModalState(() {
                            obscureNewPassword =
                                !obscureNewPassword;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  TextField(
                    controller: confirmPasswordController,
                    obscureText: obscureConfirmPassword,
                    decoration: inputDecoration(
                      "Confirm Password",
                    ).copyWith(
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setModalState(() {
                            obscureConfirmPassword =
                                !obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFFFE000),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () async {
                        final code =
                            controllers.map((c) => c.text).join();

                        if (code.length != 6) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Please enter all 6 digits",
                              ),
                            ),
                          );
                          return;
                        }

                        if (!_isStrongPassword(
                          newPasswordController.text,
                          '',
                        )) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Password must contain uppercase, lowercase, number, special character and be at least 8 characters long.",
                              ),
                            ),
                          );
                          return;
                        }

                        if (newPasswordController.text !=
                            confirmPasswordController.text) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content: Text(
                                "Passwords do not match",
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

                            ScaffoldMessenger.of(this.context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Password reset successful. Please login.",
                                ),
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(this.context)
                                .showSnackBar(
                              SnackBar(
                                content: Text(
                                  "Reset failed: ${e.toString()}",
                                ),
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
      },
    ),
  ).whenComplete(() {
    for (final controller in controllers) {
      controller.dispose();
    }

    newPasswordController.dispose();
    confirmPasswordController.dispose();
  });
}
Widget _buildback({
    required IconData icon,
    required String text,
    IconData? trailingIcon,
    Color? trailingColor,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          
          child: Row(
            children: [
              Icon(icon, size: 30, color: const Color(0xFF005BAB)),
              const SizedBox(width: 16),

              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ),

              if (trailingIcon != null)
                Icon(trailingIcon,
                    color: trailingColor ?? Colors.grey),
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
                _buildback(
              icon: Icons.arrow_back,
              text: "Back",
              //trailingIcon: Icons.arrow_forward_ios,
              onTap: () {
                Navigator.pushReplacementNamed(context, '/');
              },
            ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Look",
                      style: GoogleFonts.greatVibes(
                        fontSize: 44,
                        color: Color(0xFF0066CC),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "For",
                      style: GoogleFonts.greatVibes(
                        fontSize: 44,
                        color: const Color(0xFFFFE000),
                        fontWeight: FontWeight.bold,
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
                Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: ElevatedButton.icon(
                icon: const Icon(Icons.lock),
                label: const Text(
                  "Log in with biometrics",
                  style: TextStyle(fontSize: 16),
                ),
                onPressed: () {
                  Navigator.pushReplacementNamed(context, '/biometric');
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 60),
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF005BAB),
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),

              ],
            ),
          ),
        ),
      ),
    );
  }
}
