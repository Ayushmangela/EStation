import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:testing/src/app.dart'; // make sure this path is correct

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());


  });
}
