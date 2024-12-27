// lib/test_page.dart
import 'package:flutter/material.dart';

class TestPage extends StatelessWidget {
  const TestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Page'),
      ),
      body: const Center(
        child: Text(
          'This is the Test Page',
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}