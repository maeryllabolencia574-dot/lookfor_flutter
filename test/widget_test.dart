// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutterlookfor/main.dart';




void main() {
  testWidgets('LookFor app loads', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const LookForApp());

    // Allow routing & animations to settle
    await tester.pumpAndSettle();

    // ✅ Verify that login screen content appears
    expect(find.text('LOG IN'), findsOneWidget);
    expect(find.text('Look'), findsWidgets);
    expect(find.text('For'), findsWidgets);
  });
}