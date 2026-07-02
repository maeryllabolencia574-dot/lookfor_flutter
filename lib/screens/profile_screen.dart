import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/notification_bell_button.dart';
import '../services/api_client.dart';
import '../widgets/app_bar_account_menu.dart';
import '../widgets/app_drawer.dart';
import '../services/profile_image_notifier.dart';
import 'change_profile_picture_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // ---------------- USER DATA ----------------
  bool isLoading = true;
  String name = "";
  String studentId = "";
  String email = "";
  String course = "";
  String section = "";
  String status = "";
  String role = "";

  String? profileImageUrl;
  File? profileImageFile;

  bool emailAuthEnabled = false;
  /*String name = "Maeryll Abolencia";
  String studentId = "02000362199";
  String email = "abolencia.362199@sti.edu.ph";
  String course = "Information Technology";
  String section = "BT 601";
  String status = "active";
  String role = "Student";

  String? profileImageUrl;
  File? profileImageFile;

  bool emailAuthEnabled = false;*/
  @override
  void initState() {
    super.initState();
    _loadPersistedProfileImage();
    _fetchUserData();
  }

  Future<void> _loadPersistedProfileImage() async {
    final savedPath = await getPersistedProfileImagePath();
    if (!mounted) return;

    final persistedFile = savedPath != null && File(savedPath).existsSync()
        ? File(savedPath)
        : null;

    setState(() {
      profileImageFile = persistedFile;
    });
  }

  Future<void> _fetchUserData({bool forceProfileImageRefresh = false}) async {
    try {
      final userData = await apiClient.getCurrentUser();
      if (!mounted) return;

      final nextProfileImageUrl = apiClient.getProfileImageUrl(
        userData['profile_pic'],
      );
      final savedPath = await getPersistedProfileImagePath();
      final persistedFile = savedPath != null && File(savedPath).existsSync()
          ? File(savedPath)
          : null;

      setProfileImageUrl(
        nextProfileImageUrl,
        forceNotify: forceProfileImageRefresh,
      );

      setState(() {
        name = userData['full_name'] ?? "No Name";
        studentId = userData['student_no'] ?? "N/A";
        email = userData['email'] ?? "";
        course = userData['course'] ?? "";
        section = userData['section'] ?? "";
        status = (userData['is_student_active'] ?? false)
            ? "active"
            : "inactive";
        role = userData['role_label'] ?? "Student";
        emailAuthEnabled = userData['two_factor_enabled'] ?? false;
        profileImageFile = persistedFile;
        profileImageUrl = _withProfileImageVersion(nextProfileImageUrl);
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => isLoading = false);
      _infoDialog("Error loading profile: $e");
    }
  }
  // ---------------- NOTIFICATIONS ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(currentPage: "Profile", userName: name, userRole: role),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF005BAB)),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Look",
              style: GoogleFonts.greatVibes(
                fontSize: 28,
                color: const Color(0xFF0066CC),
              ),
            ),
            Text(
              "For",
              style: GoogleFonts.greatVibes(
                fontSize: 28,
                color: const Color(0xFFFFCC00),
              ),
            ),
          ],
        ),
        actions: [
          const NotificationBellButton(),
          AppBarAccountMenu(userName: name, userRole: role),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetchUserData,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildHeaderCard(context),
                    const SizedBox(height: 20),
                    _buildInfoCard(),
                    const SizedBox(height: 20),
                    _buildSecurityCard(),
                  ],
                ),
              ),
            ),
    );
  }

  // ==================================================
  // PROFILE HEADER
  // ==================================================
  Widget _buildHeaderCard(BuildContext context) {
    return _card(
      Column(
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: const Color(0xFF005BAB),
            backgroundImage: profileImageFile != null
                ? FileImage(profileImageFile!)
                : profileImageUrl != null
                ? NetworkImage(profileImageUrl!)
                : null,
            child: profileImageFile == null && profileImageUrl == null
                ? const Icon(Icons.person, size: 60, color: Colors.white)
                : null,
          ),
          const SizedBox(height: 12),
          Text(
            name,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0066CC),
            ),
          ),
          Text(studentId, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: 200,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0066CC),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: const Text("Change Profile Picture"),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChangeProfilePictureScreen(
                      currentImageUrl: profileImageUrl,
                    ),
                  ),
                );

                if (result != null && result["image"] != null) {
                  setState(() => isLoading = true);
                  try {
                    final selectedImage = result["image"] as File;
                    final savedImagePath = await persistProfileImageLocally(
                      selectedImage,
                    );

                    if (mounted) {
                      setState(() {
                        profileImageFile = savedImagePath != null
                            ? File(savedImagePath)
                            : selectedImage;
                        profileImageUrl = null;
                      });
                    }

                    await apiClient.updateProfile(
                      fullName: name,
                      studentNo: studentId,
                      course: course,
                      section: section,
                      profilePic: selectedImage,
                    );
                    await _fetchUserData(forceProfileImageRefresh: true);
                    _infoDialog("Profile picture updated successfully!");
                  } catch (e) {
                    _infoDialog("Update failed: $e");
                  } finally {
                    if (mounted) {
                      setState(() => isLoading = false);
                    }
                  }
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  String? _withProfileImageVersion(String? url) {
    if (url == null || url.isEmpty) return url;
    final separator = url.contains('?') ? '&' : '?';
    return '$url${separator}v=${profileImageVersion.value}';
  }

  // ==================================================
  // PERSONAL INFORMATION
  // ==================================================
  Widget _buildInfoCard() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Personal Information",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF005BAB),
            ),
          ),
          const Divider(),
          _infoRow(Icons.person_outline, "Username", name),
          _infoRow(Icons.badge_outlined, "Student ID", studentId),
          _infoRow(Icons.email_outlined, "Email", email),
          _infoRow(Icons.book_outlined, "Course", course),
          _infoRow(Icons.group_outlined, "Section", section),
        ],
      ),
    );
  }

  // ==================================================
  // SECURITY SETTINGS
  // ==================================================
  Widget _buildSecurityCard() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.security, color: Color(0xFF0066CC)),
              SizedBox(width: 8),
              Text(
                "Security Settings",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0066CC),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Email Authentication
          Container(
            padding: const EdgeInsets.all(14),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                const Icon(Icons.email_outlined, color: Color(0xFF0066CC)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Email Authentication",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Receive a verification code via email when logging in from a new device",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: emailAuthEnabled,
                  activeThumbColor: const Color(0xFF0066CC),
                  onChanged: (val) {
                    setState(() => emailAuthEnabled = val);
                  },
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Change Password
          Container(
            padding: const EdgeInsets.all(14),
            decoration: _cardDecoration(),
            child: Row(
              children: [
                const Icon(Icons.lock_outline, color: Color(0xFF0066CC)),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    "Change Password",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                OutlinedButton(
                  onPressed: _showChangePasswordDialog,
                  child: const Text("Change"),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================================================
  // CHANGE PASSWORD DIALOG
  // ==================================================
  void _showChangePasswordDialog() {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();
    final confirmPass = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Change Password",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0066CC),
                ),
              ),
              const SizedBox(height: 16),
              _passwordField("Current Password", oldPass),
              _passwordField("New Password", newPass),
              _passwordField("Confirm New Password", confirmPass),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFE000),
                        foregroundColor: Colors.black,
                      ),
                      onPressed: () async {
                        if (newPass.text != confirmPass.text) {
                          _infoDialog("Passwords do not match.");
                          return;
                        }
                        try {
                          await apiClient.changePassword(
                            currentPassword: oldPass.text,
                            newPassword: newPass.text,
                          );
                          if (!mounted) return;
                          Navigator.pop(context);
                          _showSnackBar("Password changed successfully.");
                        } catch (error) {
                          if (!mounted) return;
                          _infoDialog("Failed to change password: $error");
                        }
                      },
                      child: const Text("Update"),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==================================================
  // HELPERS
  // ==================================================
  Widget _passwordField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        obscureText: true,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: const Color(0xFFF2F6FF),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  void _infoDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(message),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFE000),
              foregroundColor: Colors.black,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _infoRow(IconData icon, String label, String value) => Row(
    children: [
      Icon(icon, color: const Color(0xFF0066CC)),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    ],
  );

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(18),
    border: Border.all(color: const Color(0xFFFFCC00), width: 1.2),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );

  Widget _card(Widget child) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(20),
    decoration: _cardDecoration(),
    child: child,
  );
}
