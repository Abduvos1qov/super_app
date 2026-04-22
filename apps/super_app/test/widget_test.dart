import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:super_app/app.dart';

void main() {
  group('SuperApp shell', () {
    testWidgets('renders the shell scaffold with Home tab selected',
        (tester) async {
      await tester.pumpWidget(const ProviderScope(child: SuperApp()));
      // First frame renders the scaffold; async session bootstrap is kicked
      // off but not awaited here.
      await tester.pump();

      expect(find.text('Home'), findsWidgets);
      expect(find.text('Wallet'), findsWidgets);
      expect(find.text('Inbox'), findsWidgets);
      expect(find.text('Profile'), findsWidgets);
    });

    testWidgets('renders the Demo launcher tile from the registry',
        (tester) async {
      await tester.pumpWidget(const ProviderScope(child: SuperApp()));
      await tester.pump();

      expect(find.text('Demo'), findsOneWidget);
    });

    testWidgets('tapping the Demo tile navigates to /m/com.superapp.demo',
        (tester) async {
      await tester.pumpWidget(const ProviderScope(child: SuperApp()));
      await tester.pump();

      await tester.tap(find.text('Demo'));
      await tester.pumpAndSettle();

      // The demo mini-app's home screen shows this headline copy.
      expect(
        find.textContaining('demo mini-app'),
        findsOneWidget,
      );
    });
  });
}
