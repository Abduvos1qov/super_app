import 'package:flutter_test/flutter_test.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:notifications/notifications.dart';

void main() {
  group('InMemoryNotificationRouter', () {
    late InMemoryNotificationRouter sut;

    setUp(() {
      sut = InMemoryNotificationRouter();
    });

    tearDown(() async {
      await sut.dispose();
    });

    test('captures showInApp calls in order', () async {
      await sut.showInApp(const InAppNotification(title: 'one'));
      await sut.showInApp(
        const InAppNotification(
          title: 'two',
          severity: InAppNotificationSeverity.warning,
        ),
      );

      expect(sut.shownInApp.map((n) => n.title), ['one', 'two']);
      expect(sut.shownInApp[1].severity, InAppNotificationSeverity.warning);
    });

    test('pushSink simulates inbound push on incoming stream', () async {
      final received = <String>[];
      final sub = sut.incoming().listen((m) => received.add(m.id));

      sut
        ..pushSink(
          PushMessage(id: 'p-1', title: 't', receivedAt: DateTime.utc(2026)),
        )
        ..pushSink(
          PushMessage(id: 'p-2', title: 't', receivedAt: DateTime.utc(2026)),
        );
      await Future<void>.delayed(Duration.zero);

      expect(received, ['p-1', 'p-2']);

      await sub.cancel();
    });

    test('clear empties shownInApp but keeps push subscribers alive',
        () async {
      final received = <String>[];
      final sub = sut.incoming().listen((m) => received.add(m.id));
      await sut.showInApp(const InAppNotification(title: 'x'));

      sut
        ..clear()
        ..pushSink(
          PushMessage(id: 'after', title: 't', receivedAt: DateTime.utc(2026)),
        );

      expect(sut.shownInApp, isEmpty);
      await Future<void>.delayed(Duration.zero);

      expect(received, ['after']);

      await sub.cancel();
    });

    test('pushSink after dispose is a no-op and does not throw', () async {
      await sut.dispose();

      expect(
        () => sut.pushSink(
          PushMessage(id: 'x', title: 't', receivedAt: DateTime.utc(2026)),
        ),
        returnsNormally,
      );
    });
  });
}
