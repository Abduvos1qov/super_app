import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:super_app/home/launcher_screen.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  group('LauncherScreen', () {
    testWidgets('renders empty-state placeholder', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const LauncherScreen(),
          ),
        ),
      );

      expect(find.text('Super App'), findsOneWidget);
      expect(find.text('No mini-apps installed yet'), findsOneWidget);
    });
  });
}
