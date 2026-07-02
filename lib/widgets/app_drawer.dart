import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/about_screen.dart';
import '../screens/dashboard_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/messages_screen.dart';
import '../screens/profile_screen.dart';
import '../widgets/logout_dialog.dart';
import '../widgets/profile_avatar.dart';

class AppDrawer extends StatelessWidget {
  final String currentPage;
  final String userName;
  final String userRole;

  const AppDrawer({
    super.key,
    this.currentPage = "",
    this.userName = "Current User",
    this.userRole = "Student",
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF5F7FA), // ✅ light background
      child: Column(
        children: [
          // ✅ TOP HEADER (BLUE CURVED)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 40, 20, 25),
            decoration: const BoxDecoration(
              color: Color(0xFF0F3F70),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 🔹 Logo
                Row(
                  children: [
                    Text(
                      "Look",
                      style: GoogleFonts.greatVibes(
                        fontSize: 30,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "For",
                      style: GoogleFonts.greatVibes(
                        fontSize: 30,
                        color: Color(0xFFFFCC00),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 4),

                const Text(
                  "Lost & Found System",
                  style: TextStyle(color: Colors.white70),
                ),

                const SizedBox(height: 16),

                // ✅ USER CARD
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    children: [
                      const ProfileAvatar(
                        radius: 22,
                        backgroundColor: Colors.white,
                        iconColor: Color(0xFF0F3F70),
                        iconSize: 26,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              userName.toUpperCase(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              userRole,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.white70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // ✅ MENU LIST
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 10),
              children: [
                _drawerItem(
                  icon: Icons.home_outlined,
                  title: "Home",
                  isSelected: currentPage == "Home",
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const DashboardScreen()),
                    );
                  },
                ),

                _drawerItem(
                  icon: Icons.search,
                  title: "Lost Items",
                  isSelected: currentPage == "Lost Items",
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InventoryScreen(type: "Lost"),
                      ),
                    );
                  },
                ),

                _drawerItem(
                  icon: Icons.inventory_2_outlined,
                  title: "Found Items",
                  isSelected: currentPage == "Found Items",
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const InventoryScreen(type: "Found"),
                      ),
                    );
                  },
                ),

                _drawerItem(
                  icon: Icons.message_outlined,
                  title: "Messages",
                  isSelected: currentPage == "Messages",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const MessagesScreen()),
                    );
                  },
                ),

                _drawerItem(
                  icon: Icons.person_outline,
                  title: "Profile",
                  isSelected: currentPage == "Profile",
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ProfileScreen()),
                    );
                  },
                ),

                const Divider(height: 30),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 14),
                  child: Text(
                    "More",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),

                const SizedBox(height: 10),

                _drawerItem(
                  icon: Icons.info_outline,
                  title: "About",
                  isSelected: currentPage == "About",
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const AboutScreen()),
                    );
                  },
                ),

                _drawerItem(
                  icon: Icons.logout_outlined,
                  title: "Logout",
                  isSelected: false,
                  onTap: () {
                    showLogoutDialog(context, {
                      "name": userName,
                      "role": userRole,
                    });
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ✅ DRAWER ITEM STYLE
  Widget _drawerItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFFDCEBFF) // ✅ light blue selected bg
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? const Color(0xFF0F3F70)
                  : Colors.grey[700],
            ),
            const SizedBox(width: 14),
            Text(
              title,
              style: TextStyle(
                color: isSelected
                    ? const Color(0xFF0F3F70)
                    : Colors.black87,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
