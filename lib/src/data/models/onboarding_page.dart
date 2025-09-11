import 'package:flutter/material.dart';

class OnboardingPage {
  final String title;
  final String description;
  final String image;
  final Color color;
  final double imageWidth;
  final double imageHeight;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.image,
    required this.color,
    this.imageWidth = 400,
    this.imageHeight = 450,
  });
}
