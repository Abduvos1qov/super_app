import 'package:driver_app/features/home/driver_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  group('DriverHomeScreen', () {
    testWidgets('renders earnings card and online toggle', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const DriverHomeScreen(),
          ),
        ),
      );

      expect(find.text("Today's earnings"), findsOneWidget);
      expect(find.text('Offline'), findsOneWidget);
      expect(find.text('Go online'), findsOneWidget);
    });

    testWidgets('toggling the switch flips the label to online', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const DriverHomeScreen(),
          ),
        ),
      );

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(find.text('Online — receiving rides'), findsOneWidget);
      expect(find.text('Go offline'), findsOneWidget);
    });
  });
}
