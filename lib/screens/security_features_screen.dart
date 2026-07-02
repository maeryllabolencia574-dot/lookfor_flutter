import 'package:flutter/material.dart';

class SecurityFeaturesScreen extends StatelessWidget {
	const SecurityFeaturesScreen({Key? key}) : super(key: key);

	@override
	Widget build(BuildContext context) {
		return Scaffold(
			appBar: AppBar(
				title: const Text('Security Features'),
			),
			body: SafeArea(
				child: SingleChildScrollView(
					padding: const EdgeInsets.all(16.0),
					child: Column(
						crossAxisAlignment: CrossAxisAlignment.start,
						children: const [
							SizedBox(height: 8),
							Text(
								'LookFor — Security Overview',
								style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
							),
							SizedBox(height: 12),
							Text(
								'LookFor is designed with user safety and privacy in mind. Below are the core security features that help protect your data and ensure safe interactions within the app.',
							),
							SizedBox(height: 16),
							_FeatureTile(
								title: 'Encrypted Data',
								description:
										'All sensitive data is encrypted in transit using HTTPS/TLS and encrypted at rest where applicable.',
							),
							_FeatureTile(
								title: 'Secure Authentication',
								description:
										'Supports strong authentication methods, including OAuth and optional two-factor authentication (2FA) to protect accounts.',
							),
							_FeatureTile(
								title: 'Minimal Data Collection',
								description:
										'We collect only the data necessary to provide the service and avoid storing unnecessary personal information.',
							),
							_FeatureTile(
								title: 'Privacy Controls',
								description:
										'Users can manage permissions, control visibility, and delete their data from the app at any time.',
							),
							_FeatureTile(
								title: 'Secure Matching & Reporting',
								description:
										'Matching algorithms are designed to avoid exposing personal data. Users can report suspicious activity directly from profiles or messages.',
							),
							SizedBox(height: 20),
							Text(
								'Tips for Staying Safe',
								style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
							),
							SizedBox(height: 8),
							Text('- Use a strong, unique password and enable 2FA.'),
							Text('- Review app permissions and only grant what is needed.'),
							Text('- Report any suspicious behavior to our support team.'),
							SizedBox(height: 24),
							Center(
								child: Text(
									'For more details, visit the Privacy & Security section in Settings.',
									style: TextStyle(color: Colors.black54),
									textAlign: TextAlign.center,
								),
							),
						],
					),
				),
			),
		);
	}
}

class _FeatureTile extends StatelessWidget {
	final String title;
	final String description;

	const _FeatureTile({required this.title, required this.description});

	@override
	Widget build(BuildContext context) {
		return Padding(
			padding: const EdgeInsets.symmetric(vertical: 8.0),
			child: Row(
				crossAxisAlignment: CrossAxisAlignment.start,
				children: [
					const Icon(Icons.security, size: 28, color: Colors.blueAccent),
					const SizedBox(width: 12),
					Expanded(
						child: Column(
							crossAxisAlignment: CrossAxisAlignment.start,
							children: [
								Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
								const SizedBox(height: 4),
								Text(description),
							],
						),
					),
				],
			),
		);
	}
}
