import 'package:flutter/material.dart';
import '../../../../main.dart'; // Adjusted path for supabase client
import '../../../presentation/pages/login_view.dart'; // Adjusted path for LoginView

class AdminHomeView extends StatelessWidget { // New class name
  const AdminHomeView({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await supabase.auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginView()), // Navigate to LoginView
          (route) => false,
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Sign out failed: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Home'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _signOut(context),
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Welcome Admin!', style: Theme.of(context).textTheme.headlineMedium),
            if (user != null) ...[
              const SizedBox(height: 16),
              Text('User ID: ${user.id}'),
              const SizedBox(height: 8),
              Text('Email: ${user.email ?? "N/A"}'), // Handle potential null email
            ],
          ],
        ),
      ),
    );
  }
}
