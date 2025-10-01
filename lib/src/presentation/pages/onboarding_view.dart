// onboarding_view.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Added import
import '../../data/models/onboarding_page.dart';
import 'welcome_page.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  _OnboardingViewState createState() => _OnboardingViewState();
}

class _OnboardingViewState extends State<OnboardingView> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingPage> _pages = [
    // Page 1: Charge Station
    OnboardingPage(
      title: "Power Up Your Ride",
      description: "Welcome to the future of transportation. Easily find and use smart charging stations for your electric vehicle.",
      image: "assets/Charge_station.png",
      color: const Color(0xFF4CAF50),
      imageHeight: 400,
      imageTop: 50,
      imageLeft: 40,
      imageRight: 40,
    ),
    // Page 2: Car and Scooty
    OnboardingPage(
      title: "Electric Ride",
      description: "Whether you're on two wheels or four, our network supports all electric vehicles.\nFind the perfect spot to recharge",
      image: "assets/carscooty.png",
      color: const Color(0xFF4CAF50),
      imageHeight: 400, // Shorter image
      imageTop: 50,    // Positioned lower
      imageLeft: 20,
      imageRight: 20,
    ),
    // Page 3: Map Mobile View
    OnboardingPage(
      title: "Find, Charge and Go",
      description: "Instantly find available chargers and get directions. Your entire journey, all on our map.",
      image: "assets/map_mobileview.png",
      color: const Color(0xFF4CAF50),
      imageHeight: 400, // Taller image
      imageTop: 50,    // Positioned higher
      imageLeft: 50,
      imageRight: 50,
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

  // Modified to save onboarding completion state
  Future<void> _finishOnboarding() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboardingComplete', true);

    if (mounted) { // Check if the widget is still in the tree
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const EnzivoWelcomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Unchanged...
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
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            right: 20,
            child: AnimatedOpacity(
              opacity: isLastPage ? 0.0 : 1.0,
              duration: const Duration(milliseconds: 300),
              child: IgnorePointer(
                ignoring: isLastPage,
                child: TextButton(
                  onPressed: _skipOnboarding,
                  child: const Text(
                    'Skip',
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 24,
            right: 24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _pages.length,
                        (index) {
                      bool isActive = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 20 : 8,
                        height: 8,
                        curve: Curves.easeInOut,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.black87
                              : Colors.grey[400],
                          borderRadius: BorderRadius.circular(50),
                        ),
                      );
                    },
                  ),
                ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  width: isLastPage ? 120 : 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(isLastPage ? 25 : 50),
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
                      borderRadius:
                      BorderRadius.circular(isLastPage ? 25 : 50),
                      child: Center(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
                          transitionBuilder: (child, animation) =>
                              FadeTransition(
                                opacity: animation,
                                child: child,
                              ),
                          child: isLastPage
                              ? const Text(
                            'Get Started',
                            key: ValueKey("text"),
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                              : const Icon(
                            Icons.arrow_forward_ios,
                            key: ValueKey("icon"),
                            color: Colors.black,
                            size: 20,
                          ),
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

  // --- STEP 3: USE THE UNIQUE VALUES FROM THE PAGE OBJECT ---
  Widget _buildPage(OnboardingPage page) {
    return Stack(
      children: [
        Container(
          color: page.color,
        ),
        Positioned(
          // It now reads the values from the 'page' object
          // The '??' provides a default value if you don't specify one
          top: page.imageTop ?? 100,
          height: page.imageHeight ?? 350,
          left: page.imageLeft ?? 40,
          right: page.imageRight ?? 40,
          child: Image.asset(
            page.image,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                  child: Icon(Icons.image_not_supported,
                      size: 50, color: Colors.grey));
            },
          ),
        ),
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: MediaQuery.of(context).size.height * 0.45,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(40.0),
                topRight: Radius.circular(40.0),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 40.0, left: 24.0, right: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    page.title,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.07,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    page.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width * 0.04,
                      color: Colors.black54,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
