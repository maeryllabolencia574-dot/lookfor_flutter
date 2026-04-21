import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/app_drawer.dart';
import 'login_screen.dart';

final List<Map<String, String>> notifications = [
  {
    "title": "Item Match Found",
    "message": "A found item matches your reported lost item.",
    "time": "2 mins ago",
  },
  {
    "title": "Item Claimed",
    "message": "Your lost item has been successfully claimed.",
    "time": "1 hour ago",
  },
];

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  /*void _logout(BuildContext context) {
  Navigator.of(context).pushNamedAndRemoveUntil(
    '/login',
    (route) => false,
  );
}*/
  void showLogoutDialog(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // AVATAR
              const CircleAvatar(
                radius: 30,
                backgroundColor: Color(0xFF005BAB),
                child: CircleAvatar(
                  radius: 26,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 30),
                ),
              ),

              const SizedBox(height: 10),

              // NAME
              Text(
                data["name"],
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Color(0xFF005BAB),
                ),
              ),

              const SizedBox(height: 4),

              // ROLE
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  data["role"],
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),

              const SizedBox(height: 20),

              // LOGOUT BUTTON
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFE000),
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.logout),
                  label: const Text("Log out"),
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                ),
              ),

              const SizedBox(height: 8),

              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Color(0xFF005BAB)),
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
    // Mock user data (replace later with real state)
    const String userName = "Maeryll Abolencia";
    const String userRole = "Student";

    return Scaffold(
      drawer: const AppDrawer(currentPage: "Home"),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF005BAB)),
        centerTitle: true,

        // -------- APP TITLE --------
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Look",
              style: GoogleFonts.greatVibes(
                fontSize: 30,
                color: const Color(0xFF005BAB),
              ),
            ),
            Text(
              "For",
              style: GoogleFonts.greatVibes(
                fontSize: 30,
                color: const Color(0xFFFFE000),
              ),
            ),
          ],
        ),

        // -------- ACTIONS --------
        actions: [
          // Notifications
          PopupMenuButton<int>(
            offset: const Offset(0, 45),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            icon: Stack(
              children: [
                const Icon(Icons.notifications_none),
                if (notifications.isNotEmpty)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        notifications.length.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            itemBuilder: (context) {
              if (notifications.isEmpty) {
                return [
                  const PopupMenuItem<int>(
                    enabled: false,
                    child: Text(
                      "No notifications yet",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                ];
              }

              return notifications.map((notif) {
                return PopupMenuItem<int>(
                  enabled: false,
                  child: Container(
                    width: 260,
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notif["title"]!,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          notif["message"]!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notif["time"]!,
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        const Divider(),
                      ],
                    ),
                  ),
                );
              }).toList();
            },
          ),
          // -------- PROFILE + LOGOUT MENU --------
          IconButton(
            icon: const CircleAvatar(
              radius: 16,
              backgroundColor: Color(0xFFDDDDDD),
              child: Icon(Icons.person, color: Color(0xFF003366), size: 20),
            ),
            tooltip: "Logout",
            onPressed: () => showLogoutDialog(context, {
              "name": userName,
              "role": userRole,
            }), // ✅ FIXED
          ),
        ],
      ),

      // ---------------- BODY ----------------
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // -------- SYSTEM ANNOUNCEMENTS --------
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Column(
                children: [
                  Icon(Icons.trending_up, color: Colors.white),
                  SizedBox(height: 8),
                  Text(
                    "System Announcements",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "🔍 CLIP AI Technology is now active! We'll automatically match your lost items with found items based on image and text similarity.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // -------- DASHBOARD STAT CARDS --------
            _statCard(
              icon: Icons.folder_open,
              iconColor: const Color(0xFFFFCC00),
              title: "Found Item Inventory",
              subtitle: "Items waiting to be claimed",
              count: "1",
            ),

            _statCard(
              icon: Icons.search,
              iconColor: const Color(0xFF005BAB),
              title: "Lost Item Inventory",
              subtitle: "Items reported as lost",
              count: "1",
            ),

            _statCard(
              icon: Icons.access_time,
              iconColor: Colors.orange,
              title: "Pending Surrender",
              subtitle: "Items pending admin review",
              count: "0",
            ),

            _statCard(
              icon: Icons.check_circle,
              iconColor: Colors.green,
              title: "Successfully Claimed",
              subtitle: "Items returned to owners",
              count: "0",
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- STAT CARD WIDGET ----------------
  static Widget _statCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required String count,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: const Color(0xFFFFE000)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 4),
              ],
            ),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          Text(
            count,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF003366),
            ),
          ),
        ],
      ),
    );
  }
}
