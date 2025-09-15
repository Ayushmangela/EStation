import 'package:flutter/material.dart';
// Adjusted import paths for the new structure:
import '../widgets/dotted_arc_painter.dart';
import '../../data/models/onboarding_page.dart';

class OnboardingView extends StatefulWidget { // New class name
  const OnboardingView({super.key});

  @override
  _OnboardingViewState createState() => _OnboardingViewState(); // New state class name
}

class _OnboardingViewState extends State<OnboardingView> { // New state class name
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Assuming OnboardingPage model will be moved to src/data/models/
  // and DottedArcPainter to src/presentation/widgets/
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: "Get your smart life with\nsmart bike",
      description:
      "The future of transportation is electric, and we\'re here to help you get there.",
      image: "assets/scooty.png", // Asset paths remain the same relative to project root
      color: const Color(0xFFE3F2FD),
      imageWidth: 500,
      imageHeight: 500,
    ),
    OnboardingPage(
      title: "Eco-friendly\nTransportation",
      description:
      "Reduce your carbon footprint while enjoying a smooth and efficient ride.",
      image: "assets/car.png",
      color: const Color(0xFFE8F5E8),
      imageWidth: 750,
      imageHeight: 750,
    ),
    OnboardingPage(
      title: "Smart Features\nfor Smart Living",
      description:
      "GPS tracking, battery monitoring, and smart connectivity at your fingertips.",
      image: "assets/charging_station.png",
      color: const Color(0xFFF3E5F5),
      imageWidth: 380,
      imageHeight: 420,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishOnboarding();
    }
  }

  void _skipOnboarding() {
    _finishOnboarding();
  }

  void _finishOnboarding() {
    // Navigation will need to be updated to use App routes if defined in app.dart
    // For now, using named routes as it was.
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
          (route) => false,
      arguments: {'animate': true},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            onPageChanged: (index) {
              setState(() {
                _currentPage = index;
              });
            },
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPage(_pages[index]);
            },
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pages.length,
                          (index) => Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _currentPage == index
                              ? Colors.black
                              : Colors.grey.shade400,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4CAF50),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        _currentPage == _pages.length - 1
                            ? 'Get Started'
                            : 'Next',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _skipOnboarding,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Container(
      color: page.color,
      child: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 6,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                child: Stack(
                  children: [
                    Positioned(
                      top: 10,
                      left: 0,
                      right: 0,
                      // Assuming DottedArcPainter is correctly imported
                      child: CustomPaint(
                        painter: DottedArcPainter(),
                        size: const Size(double.infinity, 100),
                      ),
                    ),
                    Center(
                      child: Container(
                        margin: const EdgeInsets.only(top: 160),
                        child: SizedBox(
                          width: page.imageWidth,
                          height: page.imageHeight,
                          child: Image.asset(page.image, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              flex: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.0001,
                    ),
                    Text(
                      page.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.07,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                        height: 1.2,
                      ),
                    ),
                    SizedBox(height: MediaQuery.of(context).size.height * 0.02),
                    Text(
                      page.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width * 0.04,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}