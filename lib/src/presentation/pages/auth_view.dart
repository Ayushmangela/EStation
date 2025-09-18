import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Your import paths
import '../../features/admin/dashboard/admin_home_view.dart';
import '../../features/user/authentication/auth_controller.dart';
import '../../features/user/authentication/auth_service.dart';
import '../../features/user/home/user_home_view.dart';

class RPSClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.moveTo(size.width * -0.0025, size.height * 0.31125);
    path.quadraticBezierTo(
        size.width * -0.00465, size.height * 0.1894125, size.width * 0.255, size.height * 0.1886);
    path.cubicTo(size.width * 0.379375, size.height * 0.188325, size.width * 0.6278813,
        size.height * 0.187775, size.width * 0.752175, size.height * 0.1875);
    path.quadraticBezierTo(
        size.width * 1.000825, size.height * 0.187325, size.width * 1.0025, size.height * 0.06125);
    path.lineTo(size.width * 1.0075, size.height * 0.06125);
    path.lineTo(size.width * 1.0025, size.height);
    path.lineTo(0, size.height * 1.00125);
    path.lineTo(size.width * -0.0025, size.height * 0.31125);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class AuthView extends StatefulWidget {
  const AuthView({super.key});

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> {
  bool _isSignup = false;
  bool _isLoading = false;
  bool _showLoginPanel = false;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController =
  TextEditingController(); // Removed pre-filled email
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController(AuthService());

    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _showLoginPanel = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _toggleView() {
    setState(() {
      _isSignup = !_isSignup;
    });
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = await _authController.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (user != null) {
        if (user.userMetadata?['role'] == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const AdminHomeView()),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const UserHomeView()),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Login failed. Please try again.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String fullName = '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'.trim();
      final user = await _authController.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: fullName, // Use combined full name
        phone: _phoneController.text.trim(),
      );

      if (user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Signup successful! Please login.")),
        );
        _toggleView();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Signup failed. Try again.")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // -------------------- UI code (unchanged) --------------------

  Widget _buildWelcomeScreenContent(BuildContext context) {
    String title = _isSignup ? "Create Account" : "Login";

    return Container(
      width: double.infinity,
      height: MediaQuery.of(context).size.height,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 15.0,
        right: 15.0,
        bottom: 20.0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: () {
                  if (_isSignup) {
                    _toggleView();
                  } else {
                    Navigator.pushReplacementNamed(context, '/onboarding');
                  }
                },
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                    color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final loginPanelHeight = _isSignup ? screenHeight * 0.99 : screenHeight * 0.70;

    final double formContentTopPadding = (loginPanelHeight * 0.188) + 40.0;

    return Scaffold(
      backgroundColor: const Color(0xFF1E3923),
      body: Stack(
        children: [
          _buildWelcomeScreenContent(context),
          _buildDecorativeCircles(context, screenHeight, screenWidth),
          AnimatedPositioned(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOutCubic,
            bottom: _showLoginPanel ? 0 : -loginPanelHeight,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubic,
              height: loginPanelHeight,
              width: screenWidth,
              child: Stack(
                children: [
                  ClipPath(
                    clipper: RPSClipper(),
                    child: Container(color: Colors.white),
                  ),
                  Padding(
                    padding: EdgeInsets.fromLTRB(30, formContentTopPadding, 30, 20),
                    child: SingleChildScrollView(
                      physics: _isSignup ? const NeverScrollableScrollPhysics() : null,
                      child: Form(
                        key: _formKey,
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 400),
                          transitionBuilder: (child, animation) {
                            return FadeTransition(opacity: animation, child: child);
                          },
                          child: _isSignup ? _buildSignupForm() : _buildLoginForm(),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // -------------------- Forms (updated) --------------------

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login_form'),
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email Address'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter your email';
                if (!value.contains('@')) return 'Please enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Password'),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter your password';
                return null;
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/forgot-password');
                  },
                  child: const Text('Forgot Password?',
                      style: TextStyle(color: Color(0xFF5E8B7E))),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 50),
        _buildAuthButton(label: 'LOGIN', onPressed: _handleLogin),
        _buildFooter(
          text: "Don\'t have an account? ",
          actionText: 'SIGN UP',
          onTap: _toggleView,
        ),
      ],
    );
  }

  Widget _buildSignupForm() {
    return Column(
      key: const ValueKey('signup_form'),
      children: [
        TextFormField(
          controller: _firstNameController,
          decoration: const InputDecoration(labelText: 'First Name'),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter your first name';
            return null;
          },
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: _lastNameController,
          decoration: const InputDecoration(labelText: 'Last Name'),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter your last name';
            return null;
          },
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter your email';
            if (!value.contains('@')) return 'Please enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: _phoneController,
          decoration: const InputDecoration(labelText: 'Phone'),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter your phone number';
            return null;
          },
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: _passwordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Password'),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter a password';
            if (value.length < 6) return 'Password must be at least 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: _confirmPasswordController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Confirm Password'),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please confirm your password';
            if (value != _passwordController.text) return 'Passwords do not match';
            return null;
          },
        ),
        const SizedBox(height: 25),
        _buildAuthButton(label: 'CREATE ACCOUNT', onPressed: _handleSignup),
        _buildFooter(
          text: "Already have an account? ",
          actionText: 'LOG IN',
          onTap: _toggleView,
        ),
        const SizedBox(height: 10),
      ],
    );
  }

  Widget _buildAuthButton({required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5E8B7E),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(label, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFooter({required String text, required String actionText, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0, bottom: 5.0),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text),
            Text(actionText,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF5E8B7E)))
          ],
        ),
      ),
    );
  }

  Widget _buildDecorativeCircles(BuildContext context, double screenHeight, double screenWidth) {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(top: 100, left: -50, child: _buildCircle(100)),
          Positioned(top: -20, right: -40, child: _buildCircle(80)),
          Positioned(bottom: 250, right: -60, child: _buildCircle(120)),
          Positioned(top: screenHeight * 0.5, left: screenWidth * 0.2, child: _buildCircle(60)),
        ],
      ),
    );
  }

  Widget _buildCircle(double size) {
    return Container(
      width: size,
      height: size,
      decoration:
      BoxDecoration(color: Colors.white.withOpacity(0.10), shape: BoxShape.circle),
    );
  }
}
