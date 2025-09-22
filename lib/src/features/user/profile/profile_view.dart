import 'package:flutter/material.dart';
import 'profile_controller.dart'; // Import the controller
import '../favorites/favorites_view.dart'; // Import for FavoritesView

class ProfileView extends StatefulWidget {
  const ProfileView({super.key});

  @override
  State<ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<ProfileView> {
  late UserProfileController _profileController;

  @override
  void initState() {
    super.initState();
    _profileController = UserProfileController();
    _profileController.addListener(_onProfileChanged);
    _profileController.fetchUserData();
  }

  void _onProfileChanged() {
    if (!_profileController.isLoading &&
        _profileController.user == null &&
        _profileController.errorMessage == null &&
        mounted) {
      // Navigate to AuthView after logout
      Navigator.of(context).pushNamedAndRemoveUntil('/auth', (route) => false);
    } else if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _profileController.removeListener(_onProfileChanged);
    _profileController.dispose();
    super.dispose();
  }

  Widget _buildBody(BuildContext context) {
    if (_profileController.isLoading && _profileController.user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_profileController.errorMessage != null && _profileController.user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _profileController.errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _profileController.fetchUserData(),
                child: const Text("Retry"),
              ),
            ],
          ),
        ),
      );
    }

    if (_profileController.user == null) {
      return const Center(
        child: Text(
          "No user data available. Please try logging in again.",
          textAlign: TextAlign.center,
        ),
      );
    }

    final user = _profileController.user!;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // User Card section
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 10,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center, // vertically center Column
            children: [
              CircleAvatar(
                radius: 55,
                backgroundImage: user.photoUrl != null
                    ? NetworkImage(user.photoUrl!)
                    : const AssetImage("assets/profile.jpg") as ImageProvider,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // wrap content
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Options section
        _buildSection([
          ProfileListItem(
            icon: Icons.favorite,
            text: "Favorites",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FavoritesView()),
              );
            },
          ),
          ProfileListItem(
            icon: Icons.directions_car,
            text: "My Vehicle",
            onTap: () => print("My Vehicle tapped"),
          ),
          ProfileListItem(
            icon: Icons.edit,
            text: "Edit Profile",
            onTap: () => print("Edit Profile tapped"),
          ),
        ]),

        const SizedBox(height: 16),

        // Logout section
        _buildSection([
          ProfileListItem(
            icon: Icons.logout,
            text: "Logout",
            isDestructive: true,
            onTap: () async {
              if (_profileController.isLoading) return;
              await _profileController.logout();
              // Navigation handled by _onProfileChanged
            },
          ),
        ]),

        if (_profileController.errorMessage != null && _profileController.user != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Text(
              "Error: ${_profileController.errorMessage}",
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        ),
        centerTitle: true,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2))
        ],
      ),
      child: Column(children: children),
    );
  }
}

class ProfileListItem extends StatelessWidget {
  final IconData icon;
  final String text;
  final VoidCallback onTap;
  final bool isDestructive;

  const ProfileListItem({
    super.key,
    required this.icon,
    required this.text,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isDestructive ? Colors.red : Colors.green),
      title: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          color: isDestructive ? Colors.red : Colors.black,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
