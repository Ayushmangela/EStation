import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../main.dart'; // Adjusted path for supabase client

class AdminHomeView extends StatelessWidget {
  const AdminHomeView({super.key});

  Future<void> _signOut(BuildContext context) async {
    try {
      await supabase.auth.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('userRole');
      if (context.mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil(
          '/welcome',
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

  Future<bool> _onWillPop(BuildContext context) async {
    return (await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App?'),
            content: const Text('Are you sure you want to exit the app?'),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => SystemNavigator.pop(),
                child: const Text('Yes'),
              ),
            ],
          ),
        )) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: Scaffold(
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
                Text('Email: ${user.email ?? "N/A"}'),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
