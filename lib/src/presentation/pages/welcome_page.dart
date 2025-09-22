import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'auth_view.dart';
import 'onboarding_view.dart'; // Added import for OnboardingView

class EnzivoWelcomeScreen extends StatefulWidget {
  const EnzivoWelcomeScreen({super.key});

  @override
  State<EnzivoWelcomeScreen> createState() => _EnzivoWelcomeScreenState();
}

class _EnzivoWelcomeScreenState extends State<EnzivoWelcomeScreen> {
  static const Color darkGreen = Color(0xFF1A4314);
  static const Color accentGreen = Color(0xFF5DB075);

  bool _showAuthPanel = false;
  bool _initialAuthModeIsSignup = false;

  void _presentAuthPanel({required bool isSignup}) {
    setState(() {
      _initialAuthModeIsSignup = isSignup;
      _showAuthPanel = true;
    });
  }

  void _hideAuthPanel() {
    setState(() {
      _showAuthPanel = false;
    });
  }

  void _handleAuthViewModeChange(bool isSignupView) {
    setState(() {
      _initialAuthModeIsSignup = isSignupView;
    });
  }

  Widget _buildAuthPanelHeader(BuildContext context) {
    String title = _initialAuthModeIsSignup ? "Create Account" : "Login";
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 10.0, left: 15.0, right: 15.0),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                onPressed: _hideAuthPanel,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.poppins(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The fix is here
      resizeToAvoidBottomInset: false,
      backgroundColor: darkGreen,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Spacer(flex: 3),
                  Image.asset(
                    'assets/applogo.png',
                    height: 250,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome to Enzivo',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Where innovation meets the road. Fast, reliable, and future-ready charging at your fingertips.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 15,
                      height: 1.5,
                    ),
                  ),
                  const Spacer(flex: 4),
                  ElevatedButton(
                    onPressed: () {
                      _presentAuthPanel(isSignup: false);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentGreen,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.0),
                      ),
                    ),
                    child: const Text(
                      'Login',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: () {
                      _presentAuthPanel(isSignup: true);
                    },
                    child: const Text(
                      'Create an account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ),
          if (_showAuthPanel)
            Positioned.fill(
              child: AuthView(
                initialIsSignup: _initialAuthModeIsSignup,
                onClose: _hideAuthPanel,
                onViewModeChange: _handleAuthViewModeChange,
              ),
            ),
          if (_showAuthPanel) _buildAuthPanelHeader(context),
          if (!_showAuthPanel)
            Positioned(
              top: 0,
              left: 0,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.only(top: 10.0, left: 15.0),
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(builder: (_) => const OnboardingView()),
                      );
                    },
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}