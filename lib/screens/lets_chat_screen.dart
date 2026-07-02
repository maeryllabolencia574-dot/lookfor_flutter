import 'package:flutter/material.dart';

class LetsChatScreen extends StatelessWidget {
  const LetsChatScreen({Key? key}) : super(key: key);

  static const routeName = '/lets-chat';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
      ),
      body: const Center(
        child: Text(
          'No messages yet',
          style: TextStyle(fontSize: 16),
        ),
      ),
    );
  }
}
