import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase_sdk;

// User model
class User {
  final String id;
  final String name;
  final String email;
  final String? photoUrl;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
  });

  factory User.fromSupabase(Map<String, dynamic> data) {
    return User(
      id: data['user_id'],
      name: data['name'],
      email: data['email'],
      photoUrl: data['photo_url'],
    );
  }
}

class UserProfileController with ChangeNotifier {
  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchUserData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final supabaseClient = supabase_sdk.Supabase.instance.client;
      final currentUser = supabaseClient.auth.currentUser;

      if (currentUser == null) {
        _errorMessage = "User not logged in.";
        _user = null;
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await supabaseClient
          .from('users')
          .select()
          .eq('user_id', currentUser.id)
          .maybeSingle(); // safer than .single()

      if (response == null) {
        _errorMessage = "No user data found in database.";
        _user = null;
      } else {
        _user = User.fromSupabase(response);
      }
    } catch (e) {
      print('Error fetching user data from Supabase: $e');
      _errorMessage = "Failed to fetch user data: ${e.toString()}";
      _user = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await supabase_sdk.Supabase.instance.client.auth.signOut();
      _user = null;
    } catch (e) {
      print('Error during logout: $e');
      _errorMessage = "Logout failed: ${e.toString()}";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
