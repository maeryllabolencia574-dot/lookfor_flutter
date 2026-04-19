import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'messages_screen.dart';
import 'widgets/app_drawer.dart';

import 'screens/login_screen.dart';

void main() {
  runApp(const LookForApp());
}
void logout(BuildContext context) {
  Navigator.of(context).pushNamedAndRemoveUntil(
    '/login',
    (route) => false,
  );
}

class LookForApp extends StatelessWidget {
  const LookForApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'LookFor',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF0066CC)),
        useMaterial3: true,
      ),
      initialRoute: '/login',
      routes: {
        '/login': (context) => const LoginScreen(),
        '/dashboard': (context) => const DashboardPage(),
      },
    );
  }
}

// --- DATA MODEL ---
class ItemReport {
  String id;
  String name;
  String location;
  String status;

  ItemReport({
    required this.id,
    required this.name,
    required this.location,
    required this.status,
  });
  
}



// --- LOGIN PAGE ---
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passController = TextEditingController();

  void _handleLogin() {
    String email = _emailController.text;
    String pass = _passController.text;

    if (email.endsWith('@novaliches.sti.edu') && pass.length == 6) {
      _showSMSVerification();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Invalid STI email or password must be 6 digits"),
        ),
      );
    }
  }

  void _showSMSVerification() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          top: 20,
          left: 20,
          right: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "SMS Verification",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text("A 6-digit code was sent to your registered number."),
            const TextField(
              decoration: InputDecoration(hintText: "Enter Code"),
              keyboardType: TextInputType.number,
              maxLength: 6,
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const DashboardPage(),
                  ),
                );
              },
              child: const Text("Verify & Login"),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0066CC),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 30),
            padding: const EdgeInsets.all(25),
            decoration: BoxDecoration(
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
                        fontSize: 45,
                        color: const Color(0xFF0066CC),
                      ),
                    ),
                    Text(
                      "For",
                      style: GoogleFonts.greatVibes(
                        fontSize: 45,
                        color: const Color(0xFFFFCC00),
                      ),
                    ),
                  ],
                ),
                const Text(
                  "LOG IN",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0066CC),
                  ),
                ),
                const Text(
                  "Sign in to Continue",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Email",
                    style: TextStyle(
                      color: Color(0xFF0066CC),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    hintText: "lastname000000@novaliches.sti.edu",
                    filled: true,
                    fillColor: Color(0xFFF5F5F5),
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 15),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "Password",
                    style: TextStyle(
                      color: Color(0xFF0066CC),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                TextField(
                  controller: _passController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    hintText: "Enter your password",
                    filled: true,
                    fillColor: Color(0xFFF5F5F5),
                    border: OutlineInputBorder(borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 25),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFCC00),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _handleLogin,
                    child: const Text(
                      "Log in",
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text(
                    "Forgot Password",
                    style: TextStyle(color: Color(0xFF0066CC)),
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

// --- DASHBOARD PAGE ---
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Look", style: GoogleFonts.greatVibes(color: Colors.blue)),
            Text("For", style: GoogleFonts.greatVibes(color:Color(0xFFFFCC00))),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.blue),
            onPressed: () {
              Navigator.pop(context); // close modal
              logout(context); // 🔥 THIS is the important call
            },
          ),
          const CircleAvatar(
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 10),
        ],
      ),
      drawer: const AppDrawer(currentPage: "Home"),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Column(
                children: [
                  Text(
                    "System Announcements",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    "🔍 CLIP AI Technology is now active! We'll match your items automatically.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _buildStatCard(
              "Found Item Inventory",
              "1",
              Icons.folder_open,
              Colors.amber,
            ),
            _buildStatCard(
              "Lost Item Inventory",
              "1",
              Icons.search,
              Color(0xFF0066CC),
            ),
            _buildStatCard(
              "Pending Surrender",
              "0",
              Icons.access_time,
              Colors.orange,
            ),
            _buildStatCard(
              "Successfully Claimed",
              "0",
              Icons.check_circle_outline,
              Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String count,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color:Color(0xFFFFCC00), width: 0.5),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text("Items waiting to be processed"),
        trailing: Text(
          count,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}

// --- INVENTORY SCREEN (THE NEW MODULE) ---
class InventoryScreen extends StatefulWidget {
  final String type;
  const InventoryScreen({super.key, required this.type});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  List<ItemReport> items = [];

  // 1. UPLOAD/EDIT MODAL
  void _showReportModal({ItemReport? existingItem}) {
    final nameController = TextEditingController(text: existingItem?.name);
    final locController = TextEditingController(text: existingItem?.location);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(
          "${existingItem == null ? 'Upload' : 'Edit'} ${widget.type} Item",
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Item Name"),
            ),
            TextField(
              controller: locController,
              decoration: const InputDecoration(labelText: "Location"),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => _showDiscardConfirmation(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFCC00),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              Navigator.pop(context);
              _showReviewModal(
                nameController.text,
                locController.text,
                existingItem,
              );
            },
            child: const Text("Next"),
          ),
        ],
      ),
    );
  }

  // 2. REVIEW MODAL
  void _showReviewModal(String name, String loc, ItemReport? existingItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Review Report"),
        content: Text("Name: $name\nLocation: $loc\nType: ${widget.type}"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Back"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFFCC00),
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              setState(() {
                if (existingItem != null) {
                  existingItem.name = name;
                  existingItem.location = loc;
                } else {
                  items.add(
                    ItemReport(
                      id: DateTime.now().toString(),
                      name: name,
                      location: loc,
                      status: widget.type,
                    ),
                  );
                }
              });
              Navigator.pop(context);
            },
            child: const Text("Confirm"),
          ),
        ],
      ),
    );
  }

  // 3. DISCARD MODAL
  void _showDiscardConfirmation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Discard Changes?"),
        content: const Text(
          "Changes will be discarded if you exit without saving.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Pop discard alert
              Navigator.pop(context); // Pop main modal
            },
            child: const Text("Yes, Discard",style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
  

  // 4. DELETE MODAL
  void _showDeleteConfirmation(int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Report"),
        content: const Text("Are you sure you want to delete this report?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () {
              setState(() => items.removeAt(index));
              Navigator.pop(context);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("${widget.type} Inventory")),
      drawer: AppDrawer(currentPage: "${widget.type} Items"),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: ElevatedButton(
              onPressed: () => _showReportModal(),
              child: Text("Upload ${widget.type} Item"),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: items.length,
              itemBuilder: (context, index) => ListTile(
                title: Text(items[index].name),
                subtitle: Text(items[index].location),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () =>
                          _showReportModal(existingItem: items[index]),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete),
                      onPressed: () => _showDeleteConfirmation(index),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- SIDEBAR (DRAWER) ---
class AppDrawer extends StatelessWidget {
  final String currentPage;
  const AppDrawer({super.key, required this.currentPage});

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
                MaterialPageRoute(builder: (context) => const DashboardPage()),
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
                MaterialPageRoute(builder: (context) => const MessagesScreen()),
              );
            },
          ),
          _drawerItem(
            icon: Icons.search,
            title: "Lost Items",
            isSelected: currentPage == "Lost Items",
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InventoryScreen(type: "Lost"),
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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const InventoryScreen(type: "Found"),
                ),
              );
            },
          ),
          _drawerItem(
            icon: Icons.person_outline,
            title: "Profile",
            isSelected: false,
            onTap: () {},
          ),
          const Divider(color: Colors.white24),
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
