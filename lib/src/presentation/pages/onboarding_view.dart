import 'package:flutter/material.dart';

// Removed import for DottedArcPainter as it's no longer used
import '../../data/models/onboarding_page.dart';
import 'login_view.dart'; // Correct path to LoginView

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  _OnboardingViewState createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Updated pages data with your content
  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: "Get your smart life with\nsmart bike",
      description:
      "The future of transportation is electric, and we're here to help you get there.",
      image: "assets/scooty.png",
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
        duration: const Duration(milliseconds: 400),
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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const LoginView()),
    );
  }

  @override
  Widget build(BuildContext context) {
    bool isLastPage = _currentPage == _pages.length - 1;

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
          // Skip Button - only show if not the last page
          if (!isLastPage)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10, // Consider safe area
              right: 20,
              child: TextButton(
                onPressed: _skipOnboarding,
                child: const Text(
                  'Skip',
                  style: TextStyle(
                    color: Colors.black54, // Changed for better contrast on light backgrounds
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          // Bottom Controls (Indicators and Next Button)
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Page Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 20 : 8, // Active dot is wider
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index ? Colors.black87 : Colors.grey[400], // Changed for better contrast
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                // Next Button / Get Started Button
                Container(
                  width: isLastPage ? 120 : 50, // Wider for text
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white, 
                    // Make it a rounded rectangle if it's the last page and has text
                    borderRadius: isLastPage ? BorderRadius.circular(25) : null,
                    shape: isLastPage ? BoxShape.rectangle : BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _nextPage,
                      borderRadius: isLastPage ? BorderRadius.circular(25) : BorderRadius.circular(50),
                      child: Center(
                        child: isLastPage
                            ? const Text(
                                'Get Started',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : const Icon(
                                Icons.arrow_forward_ios,
                                color: Colors.black, 
                                size: 20,
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(OnboardingPage page) {
    return Container(
      color: page.color, // Page background color (e.g., light blue, light green)
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          Expanded(
            flex: 7, // Adjust flex to give more space to image
            child: Padding(
              padding: const EdgeInsets.only(top: 60.0, bottom: 20.0, left: 20.0, right: 20.0), // Add padding for image
              child: Image.asset(
                page.image,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Expanded(
            flex: 3, // Adjust flex for text content
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.07, // Adjusted font size slightly
                      fontWeight: FontWeight.bold,
                      color: Colors.black87, // Changed for better contrast on light backgrounds
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    page.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.04,
                      color: Colors.black54, // Changed for better contrast on light backgrounds
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 120), // Space for bottom controls
        ],
      ),
    );
  }
}
