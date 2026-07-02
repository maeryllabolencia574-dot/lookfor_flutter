import 'package:flutter/material.dart';

class TermsConditionScreen extends StatelessWidget {
  const TermsConditionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms & Conditions'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Welcome to LookFor',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  'Please read these terms and conditions carefully before using the LookFor application. Your access to and use of the service is conditioned on your acceptance of and compliance with these terms.',
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                SizedBox(height: 24),
                Text(
                  '1. Acceptance of Terms',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'By accessing or using LookFor, you agree to be bound by these terms. If you do not agree with any part of the terms, you may not use the app.',
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                SizedBox(height: 24),
                Text(
                  '2. Use of the App',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'LookFor is provided as a tool to help you search for products, services, or locations. You agree to use the app in a lawful manner and not to misuse any features.',
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                SizedBox(height: 24),
                Text(
                  '3. User Responsibilities',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'You are responsible for maintaining the confidentiality of your account details and for all activities that occur under your account. Notify us immediately if you suspect unauthorized access.',
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                SizedBox(height: 24),
                Text(
                  '4. Privacy and Data',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'We collect and use personal information in accordance with our privacy policy. By using LookFor, you consent to the collection and use of information in accordance with that policy.',
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                SizedBox(height: 24),
                Text(
                  '5. Changes to Terms',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                SizedBox(height: 8),
                Text(
                  'We may update these terms from time to time. Continued use of the app after changes are posted constitutes acceptance of the updated terms.',
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
                SizedBox(height: 32),
                Text(
                  'If you have any questions about these terms, please contact support.',
                  style: TextStyle(fontSize: 16, height: 1.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
