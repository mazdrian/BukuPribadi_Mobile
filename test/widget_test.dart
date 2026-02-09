// Basic widget test for Money Manager app
// To run: flutter test

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kerja_praktik_app/main.dart';

void main() {
  testWidgets('App initializes correctly', (WidgetTester tester) async {
    // Build our app and trigger a frame
    await tester.pumpWidget(const ProviderScope(child: MoneyManagerApp()));

    // Verify that the app loads
    // Note: More comprehensive tests would require Firebase initialization
    await tester.pumpAndSettle();

    // App should show either login screen or loading indicator
    expect(
      find.byType(CircularProgressIndicator).evaluate().isNotEmpty ||
          find.text('Money Manager').evaluate().isNotEmpty,
      true,
    );
  });

  testWidgets('MoneyManagerApp has correct title', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MoneyManagerApp()));
    await tester.pumpAndSettle();

    final MaterialApp app = tester.widget(find.byType(MaterialApp));
    expect(app.title, 'Money Manager');
  });
}
