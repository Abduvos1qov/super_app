import 'package:demo_mini_app/src/presentation/demo_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:shared_ui/shared_ui.dart';

import '../helpers/fake_mini_app_context.dart';

void main() {
  group('DemoHomeScreen', () {
    Future<void> pumpScreen(
      WidgetTester tester, {
      required MiniAppContext context,
    }) {
      return tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: DemoHomeScreen(miniAppContext: context),
        ),
      );
    }

    testWidgets('renders the app bar and three action tiles', (tester) async {
      await pumpScreen(tester, context: FakeMiniAppContext());

      expect(find.widgetWithText(AppBar, 'Demo'), findsOneWidget);
      expect(find.text('Track analytics event'), findsOneWidget);
      expect(find.text('Ask for camera permission'), findsOneWidget);
      expect(find.text('Publish domain event'), findsOneWidget);
    });

    testWidgets(
      'tapping the analytics tile calls analytics.track with expected args',
      (tester) async {
        final analytics = RecordingAnalyticsTracker();
        await pumpScreen(
          tester,
          context: FakeMiniAppContext(analytics: analytics),
        );

        await tester.tap(find.text('Track analytics event'));
        await tester.pump();

        expect(analytics.calls, hasLength(1));
        expect(analytics.calls.single.event, equals('demo.button.tapped'));
        expect(analytics.calls.single.props, equals({'source': 'home'}));
      },
    );

    testWidgets(
      'tapping the permission tile asks the broker for camera access',
      (tester) async {
        final permissions = RecordingPermissionBroker();
        await pumpScreen(
          tester,
          context: FakeMiniAppContext(permissions: permissions),
        );

        await tester.tap(find.text('Ask for camera permission'));
        await tester.pump();

        expect(permissions.requested, equals([MiniAppPermission.camera]));
      },
    );

    testWidgets(
      'tapping the events tile publishes a DemoPingEvent on the bus',
      (tester) async {
        final events = RecordingAppEventBus();
        await pumpScreen(
          tester,
          context: FakeMiniAppContext(events: events),
        );

        await tester.tap(find.text('Publish domain event'));
        await tester.pump();

        expect(events.published, hasLength(1));
        expect(events.published.single, isA<DemoPingEvent>());
        expect(
          events.published.single.topic,
          equals('com.superapp.demo.ping'),
        );
      },
    );
  });
}
