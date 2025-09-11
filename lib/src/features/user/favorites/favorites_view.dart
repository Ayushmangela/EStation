import 'package:flutter/material.dart';

class UserFavoritesView extends StatelessWidget {
  const UserFavoritesView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Favorites')),
      body: const Center(child: Text('User Favorites - Placeholder')),
    );
  }
}
