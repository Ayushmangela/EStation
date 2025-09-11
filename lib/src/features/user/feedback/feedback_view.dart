import 'package:flutter/material.dart';

class UserFeedbackView extends StatelessWidget {
  const UserFeedbackView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Submit Feedback')),
      body: const Center(child: Text('User Feedback - Placeholder')),
    );
  }
}
