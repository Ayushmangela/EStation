import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  /// 🔹 Sign up a new user with Supabase Authentication
  Future<User?> signUpWithEmailAndPassword({
    required String email,
    required String password,
    Map<String, dynamic>? userMetadata,
  }) async {
    try {
      final AuthResponse response = await _supabaseClient.auth.signUp(
        email: email,
        password: password,
        data: userMetadata, // Pass metadata directly here
      );

      if (response.user == null) {
        throw Exception('Signup failed: No user returned.');
      }

      return response.user;
    } on AuthException catch (e) {
      print('AuthService signUp Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('AuthService signUp Exception: $e');
      rethrow;
    }
  }

  /// 🔹 Insert user into public.users table
  Future<void> addUserToPublicTable({
    required String userId,
    required String email,
    required String name,
    required String phone,
    String userType = 'user',
  }) async {
    try {
      final response = await _supabaseClient.from('users').insert({
        'user_id': userId,
        'email': email,
        'name': name,
        'phone': phone,
        'user_type': userType,
      });

      if (response != null && response.error != null) {
        throw Exception('Failed to insert user: ${response.error!.message}');
      }
    } catch (e) {
      print('AuthService addUserToPublicTable Exception: $e');
      rethrow;
    }
  }

  /// 🔹 Sign in
  Future<User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final AuthResponse response = await _supabaseClient.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed: No user returned.');
      }

      return response.user;
    } on AuthException catch (e) {
      print('AuthService signIn Error: ${e.message}');
      rethrow;
    } catch (e) {
      print('AuthService signIn Exception: $e');
      rethrow;
    }
  }

  /// 🔹 Sign out
  Future<void> signOut() async {
    try {
      await _supabaseClient.auth.signOut();
    } catch (e) {
      print('AuthService signOut Exception: $e');
      rethrow;
    }
  }

  /// 🔹 Get user type by email
  Future<String?> getUserType(String email) async {
    try {
      final response = await _supabaseClient
          .from('users')
          .select('user_type')
          .eq('email', email)
          .maybeSingle(); // <-- changed from .single()

      if (response == null || response['user_type'] == null) return null;
      return response['user_type'] as String;
    } catch (e) {
      print('AuthService getUserType Exception: $e');
      return null;
    }
  }


  /// 🔹 Get user name by userId
  Future<String?> getUserName(String userId) async {
    try {
      final response = await _supabaseClient
          .from('users')
          .select('name')
          .eq('user_id', userId)
          .maybeSingle(); // <-- changed from .single()

      if (response == null || response['name'] == null) return null;
      return response['name'] as String;
    } catch (e) {
      print('AuthService getUserName Exception: $e');
      return null;
    }
  }
}
