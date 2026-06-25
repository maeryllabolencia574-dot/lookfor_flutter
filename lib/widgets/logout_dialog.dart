import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../screens/login_screen.dart';
import 'profile_avatar.dart';

void showLogoutDialog(BuildContext context, Map<String, dynamic> data) {
  showDialog(
    context: context,
    builder: (dialogContext) => Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0xFFEAF3FF),
                  child: ProfileAvatar(
                    radius: 20,
                    backgroundColor: Colors.white,
                    iconSize: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data["name"]?.toString() ?? "Current User",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        data["role"]?.toString() ?? "Student",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const Text(
              "Log out of your account?",
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              "You will need to sign in again to access your reports and messages.",
              style: TextStyle(
                color: Color(0xFF64748B),
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    child: const Text("Cancel"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: const Icon(Icons.logout_outlined, size: 18),
                    label: const Text("Logout"),
                    onPressed: () {
                      final navigator = Navigator.of(
                        dialogContext,
                        rootNavigator: true,
                      );
                      apiClient.clearToken();
                      navigator.pop();
                      navigator.pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                        (route) => false,
                      );
                    },
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
