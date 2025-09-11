import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart'; // For AuthException
import '../../features/user/authentication/auth_service.dart';
import '../../features/user/authentication/auth_controller.dart';

class SignupView extends StatefulWidget {
  const SignupView({super.key});

  @override
  _SignupViewState createState() => _SignupViewState();
}

class _SignupViewState extends State<SignupView> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _agreeToTerms = false;
  bool _isLoading = false;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
  TextEditingController();

  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController(AuthService());
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the errors in the form.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must agree to the terms and conditions.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      final password = _passwordController.text.trim();
      final firstName = _firstNameController.text.trim();
      final lastName = _lastNameController.text.trim();
      final phone = _phoneController.text.trim();
      final fullName = '$firstName $lastName'.trim();

      final user = await _authController.signUpWithEmailAndPassword(
        email: email,
        password: password,
        name: fullName,
        phone: phone,
      );

      if (mounted && user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Signup successful! Please verify your email before logging in.',
            ),
            backgroundColor: Colors.green,
          ),
        );

        Navigator.of(context).pushNamedAndRemoveUntil(
          '/login',
              (route) => false,
          arguments: {'animate': true},
        );
      }
    } on AuthException catch (e) {
      String errorMessage = 'Signup failed. Please try again.';

      if (e.message.toLowerCase().contains('email rate limit exceeded')) {
        errorMessage = 'Too many signup attempts. Try again later.';
      } else if (e.message.toLowerCase().contains('user already registered')) {
        errorMessage = 'This email is already registered. Please login.';
      } else if (e.message.toLowerCase().contains('password should be')) {
        errorMessage = 'Password must be at least 6 characters.';
      } else if (e.message.toLowerCase().contains('email address') &&
          e.message.toLowerCase().contains('invalid')) {
        errorMessage = 'Invalid email address format.';
      } else if (e.message.isNotEmpty) {
        errorMessage = e.message;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unexpected error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(''),
        backgroundColor: theme.scaffoldBackgroundColor,
        foregroundColor: theme.colorScheme.onBackground,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Create Your\nCharging Station Account!',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // First Name
                      _buildInputField(
                        controller: _firstNameController,
                        label: "First Name",
                        prefixIcon: Icons.person,
                        validator: (value) =>
                        value == null || value.isEmpty
                            ? "Enter first name"
                            : null,
                      ),
                      const SizedBox(height: 15),

                      // Last Name
                      _buildInputField(
                        controller: _lastNameController,
                        label: "Last Name",
                        prefixIcon: Icons.person_outline,
                        validator: (value) =>
                        value == null || value.isEmpty
                            ? "Enter last name"
                            : null,
                      ),
                      const SizedBox(height: 15),

                      // Phone
                      _buildInputField(
                        controller: _phoneController,
                        label: "Phone Number",
                        prefixIcon: Icons.phone,
                        keyboardType: TextInputType.phone,
                        validator: (value) =>
                        value == null || value.isEmpty
                            ? "Enter phone number"
                            : null,
                      ),
                      const SizedBox(height: 15),

                      // Email
                      _buildInputField(
                        controller: _emailController,
                        label: "Email",
                        prefixIcon: Icons.email,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) => value == null ||
                            !value.contains("@")
                            ? "Enter valid email"
                            : null,
                      ),
                      const SizedBox(height: 15),

                      // Password
                      _buildPasswordField(
                        controller: _passwordController,
                        label: "Password",
                        isVisible: _isPasswordVisible,
                        onToggleVisibility: () => setState(() =>
                        _isPasswordVisible = !_isPasswordVisible),
                        validator: (value) => value != null &&
                            value.length < 6
                            ? "Password must be at least 6 characters"
                            : null,
                      ),
                      const SizedBox(height: 15),

                      // Confirm Password
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        label: "Confirm Password",
                        isVisible: _isConfirmPasswordVisible,
                        onToggleVisibility: () => setState(() =>
                        _isConfirmPasswordVisible =
                        !_isConfirmPasswordVisible),
                        validator: (value) => value !=
                            _passwordController.text
                            ? "Passwords do not match"
                            : null,
                      ),
                      const SizedBox(height: 15),

                      // Terms Checkbox
                      Row(
                        children: [
                          Checkbox(
                            value: _agreeToTerms,
                            onChanged: (value) => setState(
                                    () => _agreeToTerms = value ?? false),
                          ),
                          const Expanded(
                            child: Text(
                              "I agree to the Terms & Conditions",
                              style: TextStyle(fontSize: 13),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Submit Button
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _isLoading || !_agreeToTerms
                              ? null
                              : _handleSignup,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: theme.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                              : const Text(
                            'Create Account',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // 🔹 Fixed bottom section with safe padding
            Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account? ",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                    ),
                  ),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/login',
                              (route) => false,
                          arguments: {'animate': true},
                        ),
                    child: Text(
                      'Login',
                      style: TextStyle(
                        color: theme.primaryColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔹 Input field
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData prefixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(prefixIcon, color: Colors.grey.shade600, size: 20),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }

  // 🔹 Password field
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required bool isVisible,
    required VoidCallback onToggleVisibility,
    String? Function(String?)? validator,
  }) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextFormField(
        controller: controller,
        obscureText: !isVisible,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(Icons.lock, color: Colors.grey.shade600, size: 20),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible ? Icons.visibility : Icons.visibility_off,
              color: isVisible ? theme.primaryColor : Colors.grey.shade600,
              size: 20,
            ),
            onPressed: onToggleVisibility,
          ),
          border: InputBorder.none,
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
          labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
      ),
    );
  }
}
