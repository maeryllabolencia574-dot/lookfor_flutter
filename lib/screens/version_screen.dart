import 'package:flutter/material.dart';

class VersionScreen extends StatelessWidget {
  const VersionScreen({Key? key}) : super(key: key);

  static const String appName = 'Lookfor';
  static const String appVersion = '1.0.0';
  static const String appDescription =
      'Lookfor is a simple app to help you find and save the things that matter most. ' 
      'Use it to track lost items quickly and easily.';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About Lookfor'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: const [
                  Icon(
                    Icons.info_outline,
                    size: 80,
                    color: Colors.blueAccent,
                  ),
                  SizedBox(height: 16),
                  Text(
                    appName,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Version',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              appVersion,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'About',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              appDescription,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const Spacer(),
            Center(
              child: Text(
                '© ${DateTime.now().year} Lookfor',
                style: const TextStyle(
                  color: Colors.black45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
