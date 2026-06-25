import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/item_model.dart';
import '../widgets/notification_bell_button.dart';
import '../services/api_client.dart';
import '../widgets/app_bar_account_menu.dart';
import '../widgets/app_drawer.dart';
import 'profile_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String name = "";
  String role = "";
  int _foundCount = 0;
  int _lostCount = 0;
  int _pendingSurrenderCount = 0;
  int _claimedCount = 0;
  bool _isLoadingStats = true;
  String? _statsError;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    await Future.wait([_loadCurrentUser(), _loadDashboardStats()]);
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userData = await apiClient.getCurrentUser();
      if (!mounted) return;

      setState(() {
        final fullName = userData['full_name']?.toString().trim() ?? '';
        name = fullName.isNotEmpty
            ? fullName
            : userData['email']?.toString() ?? "Current User";
        role = userData['role_label']?.toString() ?? "Student";
      });
    } catch (_) {
      // Keep fallback values when profile fetch is unavailable.
    }
  }

  Future<void> _loadDashboardStats() async {
    if (mounted) {
      setState(() {
        _isLoadingStats = true;
        _statsError = null;
      });
    }

    try {
      final results = await Future.wait([
        apiClient.getMyFoundItems(),
        apiClient.getMyLostReports(),
      ]);

      final foundReports = results[0]
          .whereType<Map<String, dynamic>>()
          .map((item) => ItemReport.fromJson(item, type: 'Found'))
          .toList();
      final lostReports = results[1]
          .whereType<Map<String, dynamic>>()
          .map((item) => ItemReport.fromJson(item, type: 'Lost'))
          .toList();
      final allReports = [...foundReports, ...lostReports];

      if (!mounted) return;
      setState(() {
        _foundCount = foundReports.length;
        _lostCount = lostReports.length;
        _pendingSurrenderCount = foundReports
            .where((report) => _isPendingSurrender(report.status))
            .length;
        _claimedCount = allReports
            .where((report) => report.status.toLowerCase().contains('claimed'))
            .length;
        _isLoadingStats = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _statsError = 'Unable to load dashboard totals.';
        _isLoadingStats = false;
      });
    }
  }

  bool _isPendingSurrender(String status) {
    final normalized = status.toLowerCase();
    return normalized.contains('pending') ||
        normalized.contains('approval') ||
        normalized.contains('surrender');
  }

  String _countText(int count) => _isLoadingStats ? '...' : count.toString();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: AppDrawer(currentPage: "Home", userName: name, userRole: role),
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
        actions: [
          const NotificationBellButton(),
          AppBarAccountMenu(
            userName: name,
            userRole: role,
            onProfileSelected: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F3F70),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.auto_awesome, color: Color(0xFFFFCC00)),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "System Announcements",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 6),
                          Text(
                            "CLIP AI Technology is active. Lost and found reports are automatically matched using image and text similarity.",
                            style: TextStyle(
                              color: Color(0xFFD8E7F8),
                              fontSize: 13,
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              if (_statsError != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _statsError!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              _statCard(
                icon: Icons.folder_open,
                iconColor: const Color(0xFFFFCC00),
                title: "Found Item Inventory",
                subtitle: "Items waiting to be claimed",
                count: _countText(_foundCount),
              ),
              _statCard(
                icon: Icons.search,
                iconColor: const Color(0xFF005BAB),
                title: "Lost Item Inventory",
                subtitle: "Items reported as lost",
                count: _countText(_lostCount),
              ),
              _statCard(
                icon: Icons.access_time,
                iconColor: Colors.orange,
                title: "Pending Surrender",
                subtitle: "Items pending admin review",
                count: _countText(_pendingSurrenderCount),
              ),
              _statCard(
                icon: Icons.check_circle,
                iconColor: Colors.green,
                title: "Successfully Claimed",
                subtitle: "Items returned to owners",
                count: _countText(_claimedCount),
              ),
            ],
          ),
        ),
      ),
    );
  }

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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
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
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
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
