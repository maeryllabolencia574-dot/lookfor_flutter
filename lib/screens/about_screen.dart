import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF005BAB)),
        centerTitle: true,
        title: Text(
          'About',
          style: GoogleFonts.greatVibes(
            fontSize: 30,
            color: const Color(0xFF005BAB),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LookFor',
              style: GoogleFonts.greatVibes(
                fontSize: 42,
                color: const Color(0xFF005BAB),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Lost & Found System',
              style: TextStyle(
                fontSize: 18,
                color: Color(0xFF333333),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'About this app',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF005BAB),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'LookFor helps students and staff manage lost and found items in one place. You can report lost or found items, check matched reports, and communicate securely through messages.',
              style: TextStyle(fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 18),
            const Text(
              'How it works',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF005BAB),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '• Report lost items and attach up to three images.\n• Submit found items and add photos to help match the owner.\n• Check messages and view your profile.\n• Use the sidebar to navigate and sign out safely.',

              style: TextStyle(fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 18),
            const Text(
              'Version',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF005BAB),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '1.0.0',
              style: TextStyle(fontSize: 14, height: 1.6),
            ),
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0066CC),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Text(
                'Thank you for using LookFor! If you need help, open the sidebar for logout or further navigation.',
                style: TextStyle(color: Colors.white, fontSize: 14, height: 1.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
