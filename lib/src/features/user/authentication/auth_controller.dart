import 'auth_service.dart';

class AuthController {
  final AuthService _authService;

  AuthController(this._authService);

  /// 🔹 Sign up a new user
  Future<dynamic> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    required String phone,
  }) async {
    final userMetadata = {
      'full_name': name,
      'phone_number': phone,
    };

    final user = await _authService.signUpWithEmailAndPassword(
      email: email,
      password: password,
      userMetadata: userMetadata,
    );

    if (user != null) {
      await _authService.addUserToPublicTable(
        userId: user.id,
        email: user.email!,
        name: name,
        phone: phone,
      );
    }

    return user;
  }

  /// 🔹 Sign in
  Future<dynamic> signInWithEmailAndPassword(String email, String password) async {
    return await _authService.signInWithEmailAndPassword(email, password);
  }

  /// 🔹 Sign out
  Future<void> signOut() async {
    await _authService.signOut();
  }

  /// 🔹 Get user type by email (used in LoginView)
  Future<String?> getUserTypeByEmail(String email) async {
    return await _authService.getUserType(email);
  }

  /// 🔹 Get user name by user ID
  Future<String?> getUserName(String userId) async {
    return await _authService.getUserName(userId);
  }
}
