import 'package:flutter/material.dart';

class DottedArcPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round;

    final path = Path();
    path.moveTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.5,
      size.height * 0.1,
      size.width,
      size.height * 0.3,
    );

    // Draw dotted line
    const dashWidth = 8.0;
    const dashSpace = 8.0;
    double startX = 0;
    final pathMetrics = path.computeMetrics().first;

    while (startX < pathMetrics.length) {
      final endX = (startX + dashWidth).clamp(0.0, pathMetrics.length);
      final pathSegment = pathMetrics.extractPath(startX, endX);
      canvas.drawPath(pathSegment, paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
