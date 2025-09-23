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
  final bool initialIsSignup;
  final VoidCallback onClose;
  final void Function(bool isSignupView) onViewModeChange;

  const AuthView({
    super.key,
    this.initialIsSignup = false,
    required this.onClose,
    required this.onViewModeChange,
  });

  @override
  State<AuthView> createState() => _AuthViewState();
}

class _AuthViewState extends State<AuthView> with WidgetsBindingObserver {
  late bool _isSignup;
  bool _isLoading = false;
  bool _showLoginPanel = false;

  // State variables for password visibility
  bool _obscureLoginPassword = true;
  bool _obscureSignupPassword = true;
  bool _obscureConfirmPassword = true;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _loginPasswordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  late final AuthController _authController;

  final ScrollController _scrollController = ScrollController();
  final FocusNode _phoneFocusNode = FocusNode();
  final FocusNode _passwordFocusNode = FocusNode();
  final FocusNode _confirmPasswordFocusNode = FocusNode();
  final FocusNode _loginPasswordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _isSignup = widget.initialIsSignup;
    _authController = AuthController(AuthService());

    WidgetsBinding.instance.addObserver(this);

    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _showLoginPanel = true;
        });
      }
    });

    _phoneFocusNode.addListener(_scrollToFocusedField);
    _passwordFocusNode.addListener(_scrollToFocusedField);
    _confirmPasswordFocusNode.addListener(_scrollToFocusedField);
    _loginPasswordFocusNode.addListener(_scrollToFocusedField);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);

    _emailController.dispose();
    _loginPasswordController.dispose();
    _passwordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _confirmPasswordController.dispose();

    _scrollController.dispose();
    _phoneFocusNode.removeListener(_scrollToFocusedField);
    _passwordFocusNode.removeListener(_scrollToFocusedField);
    _confirmPasswordFocusNode.removeListener(_scrollToFocusedField);
    _loginPasswordFocusNode.removeListener(_scrollToFocusedField);
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _loginPasswordFocusNode.dispose();

    super.dispose();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && MediaQuery.of(context).viewInsets.bottom == 0) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _scrollToFocusedField() {
    Future.delayed(const Duration(milliseconds: 200), () {
      if (!mounted) return;

      BuildContext? focusedContext;
      if (_phoneFocusNode.hasFocus) {
        focusedContext = _phoneFocusNode.context;
      } else if (_passwordFocusNode.hasFocus) {
        focusedContext = _passwordFocusNode.context;
      } else if (_confirmPasswordFocusNode.hasFocus) {
        focusedContext = _confirmPasswordFocusNode.context;
      } else if (_loginPasswordFocusNode.hasFocus) {
        focusedContext = _loginPasswordFocusNode.context;
      }

      if (focusedContext != null) {
        Scrollable.ensureVisible(
          focusedContext,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
          alignment: 0.05,
        );
      }
    });
  }

  void _toggleView() {
    _emailController.clear();
    _loginPasswordController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    _firstNameController.clear();
    _lastNameController.clear();
    _phoneController.clear();
    FocusScope.of(context).unfocus();

    _obscureLoginPassword = true;
    _obscureSignupPassword = true;
    _obscureConfirmPassword = true;

    setState(() {
      _isSignup = !_isSignup;
    });
    widget.onViewModeChange(_isSignup);
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    String? errorMessage;

    try {
      final email = _emailController.text.trim();
      final user = await _authController.signInWithEmailAndPassword(
        email,
        _loginPasswordController.text.trim(),
      );

      if (user != null) {
        final userType = await _authController.getUserTypeByEmail(email);
        if (userType != null) {
          if (!mounted) return;
          // SUCCESS! Navigate and exit.
          if (userType.toLowerCase().trim() == 'admin') {
            Navigator.of(context).pushNamedAndRemoveUntil('/admin-home', (route) => false);
          } else {
            Navigator.of(context).pushNamedAndRemoveUntil('/user-home', (route) => false);
          }
          return; // IMPORTANT: Exit here to prevent setState on a disposed widget.
        } else {
          errorMessage = "Login successful, but could not determine user role.";
        }
      } else {
        errorMessage = "Login failed. Please check your credentials.";
      }
    } catch (e) {
      errorMessage = "An error occurred during login: $e";
    }

    // If we reach here, it means login failed or an error occurred.
    // The widget is still mounted, so we can safely update the state.
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage ?? "An unknown error occurred.")),
      );
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleSignup() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }
    setState(() => _isLoading = true);
    try {
      final String fullName =
      '${_firstNameController.text.trim()} ${_lastNameController.text.trim()}'
          .trim();
      final user = await _authController.signUpWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        name: fullName,
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final loginPanelHeight = _isSignup ? screenHeight * 0.99 : screenHeight * 0.70;
    final double formTopPadding = loginPanelHeight * 0.25;

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          AnimatedPositioned(
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeInOutCubic,
            bottom: _showLoginPanel ? 0 : -loginPanelHeight,
            left: 0,
            right: 0,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeInOutCubic,
              height: loginPanelHeight,
              width: screenWidth,
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Stack(
                  children: [
                    ClipPath(
                      clipper: RPSClipper(),
                      child: Container(color: Colors.white),
                    ),
                    Padding(
                      padding: EdgeInsets.only(
                          top: formTopPadding,
                          left: 30,
                          right: 30,
                          bottom: 20),
                      child: SingleChildScrollView(
                        controller: _scrollController,
                        physics: const NeverScrollableScrollPhysics(),
                        child: Form(
                          key: _formKey,
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 400),
                            transitionBuilder: (child, animation) {
                              return FadeTransition(
                                  opacity: animation, child: child);
                            },
                            child:
                            _isSignup ? _buildSignupForm() : _buildLoginForm(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginForm() {
    return Column(
      key: const ValueKey('login_form'),
      children: [
        Column(
          children: [
            TextFormField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Email Address'),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Please enter your email';
                if (!value.contains('@')) return 'Please enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              focusNode: _loginPasswordFocusNode,
              controller: _loginPasswordController,
              obscureText: _obscureLoginPassword,
              decoration: InputDecoration(
                labelText: 'Password',
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureLoginPassword
                        ? Icons.visibility_off
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscureLoginPassword = !_obscureLoginPassword;
                    });
                  },
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty)
                  return 'Please enter your password';
                return null;
              },
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text(
                            "Forgot Password clicked - implement navigation")));
                  },
                  child: const Text('Forgot Password?',
                      style: TextStyle(color: Color(0xFF5E8B7E))),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 30),
        _buildAuthButton(label: 'LOGIN', onPressed: _handleLogin),
        _buildFooter(
          text: "Don't have an account? ",
          actionText: 'SIGN UP',
          onTap: _toggleView,
        ),
        const SizedBox(height: 250),
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
            if (value == null || value.isEmpty)
              return 'Please enter your first name';
            return null;
          },
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: _lastNameController,
          decoration: const InputDecoration(labelText: 'Last Name'),
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Please enter your last name';
            return null;
          },
        ),
        const SizedBox(height: 15),
        TextFormField(
          controller: _emailController,
          decoration: const InputDecoration(labelText: 'Email'),
          keyboardType: TextInputType.emailAddress,
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Please enter a valid email';
            if (!value.contains('@')) return 'Please enter a valid email';
            return null;
          },
        ),
        const SizedBox(height: 15),
        TextFormField(
          focusNode: _phoneFocusNode,
          controller: _phoneController,
          decoration: const InputDecoration(labelText: 'Phone'),
          keyboardType: TextInputType.phone,
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Please enter your phone number';
            return null;
          },
        ),
        const SizedBox(height: 15),
        TextFormField(
          focusNode: _passwordFocusNode,
          controller: _passwordController,
          obscureText: _obscureSignupPassword,
          decoration: InputDecoration(
            labelText: 'Password',
            suffixIcon: IconButton(
              icon: Icon(
                _obscureSignupPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscureSignupPassword = !_obscureSignupPassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Please enter a password';
            if (value.length < 6)
              return 'Password must be at least 6 characters';
            return null;
          },
        ),
        const SizedBox(height: 15),
        TextFormField(
          focusNode: _confirmPasswordFocusNode,
          controller: _confirmPasswordController,
          obscureText: _obscureConfirmPassword,
          decoration: InputDecoration(
            labelText: 'Confirm Password',
            suffixIcon: IconButton(
              icon: Icon(
                _obscureConfirmPassword
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () {
                setState(() {
                  _obscureConfirmPassword = !_obscureConfirmPassword;
                });
              },
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty)
              return 'Please confirm your password';
            if (value != _passwordController.text)
              return 'Passwords do not match';
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
        const SizedBox(height: 250),
      ],
    );
  }

  Widget _buildAuthButton(
      {required String label, required VoidCallback onPressed}) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF5E8B7E),
          foregroundColor: Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _isLoading
            ? const CircularProgressIndicator(color: Colors.white)
            : Text(label,
            style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildFooter(
      {required String text,
        required String actionText,
        required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(top: 15.0, bottom: 5.0),
      child: GestureDetector(
        onTap: onTap,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(text, style: const TextStyle(color: Colors.black54)),
            Text(actionText,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Color(0xFF5E8B7E)))
          ],
        ),
      ),
    );
  }
}