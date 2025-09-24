// data/models/onboarding_page.dart

import 'package:flutter/material.dart';

class OnboardingPage {
  final String title;
  final String description;
  final String image;
  final Color color;

  // --- ADD THESE NEW PROPERTIES ---
  final double? imageHeight;
  final double? imageTop;
  final double? imageLeft;
  final double? imageRight;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
    required this.color,
    // Add them to the constructor
    this.imageHeight,
    this.imageTop,
    this.imageLeft,
    this.imageRight,
  });
}