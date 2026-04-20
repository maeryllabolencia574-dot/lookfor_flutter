import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/dashboard_screen.dart';
import '../screens/inventory_screen.dart';
import '../screens/messages_screen.dart';
import '../screens/profile_screen.dart';

class AppDrawer extends StatelessWidget {
  final String currentPage;

  const AppDrawer({super.key, this.currentPage = ""});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFF0066CC),
      child: ListView(
        children: [
          DrawerHeader(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      "Look",
                      style: GoogleFonts.greatVibes(
                        fontSize: 32,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      "For",
                      style: GoogleFonts.greatVibes(
                        fontSize: 32,
                        color: const Color(0xFFFFCC00),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  "Lost & Found System",
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),

          _drawerItem(
            icon: Icons.home_outlined,
            title: "Home",
            isSelected: currentPage == "Home",
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              );
            },
          ),

          _drawerItem(
            icon: Icons.search,
            title: "Lost Items",
            isSelected: currentPage == "Lost Items",
            onTap: () {
              Navigator.pop(context);
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
              Navigator.pop(context);
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
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MessagesScreen()),
              );
            },
          ),

          _drawerItem(
            icon: Icons.person_outline,
            title: "Profile",
            isSelected: currentPage == "Profile",
            onTap: () {
              Navigator.pop(context);
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _drawerItem({
    required IconData icon,
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFCC00) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          leading: Icon(
            icon,
            color: isSelected ? const Color(0xFF0066CC) : Colors.white,
          ),
          title: Text(
            title,
            style: TextStyle(
              color: isSelected ? const Color(0xFF0066CC) : Colors.white,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
