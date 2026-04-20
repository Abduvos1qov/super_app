import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:passenger_app/home/launcher_screen.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  group('LauncherScreen', () {
    testWidgets('renders Taxi, Food, Delivery, and Driver service cards', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const LauncherScreen(),
          ),
        ),
      );

      expect(find.text('Taxi'), findsOneWidget);
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('Delivery'), findsOneWidget);
      expect(find.text('Driver'), findsOneWidget);
    });
  });
}
