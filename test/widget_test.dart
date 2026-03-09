// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:myapp/main.dart';

void main() {
  testWidgets('HomePage UI Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const RobotApp());

    // Verify that the AppBar title is correct.
    expect(find.text('Robot N20 - Bluetooth'), findsOneWidget);

    // Verify that the header text is present.
    expect(find.text('Selecciona tu ESP32'), findsOneWidget);
    
    // Verify that the refresh icon is present.
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}
