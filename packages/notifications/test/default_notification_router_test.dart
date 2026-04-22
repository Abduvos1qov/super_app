import 'package:flutter_test/flutter_test.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:notifications/notifications.dart';

void main() {
  group('DefaultNotificationRouter', () {
    late DefaultNotificationRouter sut;

    setUp(() {
      sut = DefaultNotificationRouter();
    });

    tearDown(() async {
      await sut.dispose();
    });

    test('showInApp emits on inAppStream', () async {
      const notification = InAppNotification(
        title: 'Saved',
        severity: InAppNotificationSeverity.success,
      );
      final future = sut.inAppStream.first;

      await sut.showInApp(notification);

      final received = await future;
      expect(received.title, 'Saved');
      expect(received.severity, InAppNotificationSeverity.success);
    });

    test('incoming emits when ingestPush is called', () async {
      final future = sut.incoming().first;
      final message = PushMessage(
        id: 'm-1',
        title: 'New trip',
        receivedAt: DateTime.utc(2026, 4, 21, 12),
      );

      sut.ingestPush(message);

      final received = await future;
      expect(received.id, 'm-1');
      expect(received.title, 'New trip');
    });

    test('inAppStream is a broadcast stream with multiple subscribers',
        () async {
      final a = <String>[];
      final b = <String>[];
      final subA = sut.inAppStream.listen((n) => a.add(n.title));
      final subB = sut.inAppStream.listen((n) => b.add(n.title));

      await sut.showInApp(const InAppNotification(title: 'one'));
      await sut.showInApp(const InAppNotification(title: 'two'));
      await Future<void>.delayed(Duration.zero);

      expect(a, ['one', 'two']);
      expect(b, ['one', 'two']);

      await subA.cancel();
      await subB.cancel();
    });

    test('incoming broadcasts to multiple subscribers', () async {
      final a = <String>[];
      final b = <String>[];
      final subA = sut.incoming().listen((m) => a.add(m.id));
      final subB = sut.incoming().listen((m) => b.add(m.id));

      sut
        ..ingestPush(
          PushMessage(id: '1', title: 't', receivedAt: DateTime.utc(2026)),
        )
        ..ingestPush(
          PushMessage(id: '2', title: 't', receivedAt: DateTime.utc(2026)),
        );
      await Future<void>.delayed(Duration.zero);

      expect(a, ['1', '2']);
      expect(b, ['1', '2']);

      await subA.cancel();
      await subB.cancel();
    });

    test('dispose closes both streams', () async {
      final inAppDone = expectLater(sut.inAppStream, emitsDone);
      final pushDone = expectLater(sut.incoming(), emitsDone);

      await sut.dispose();

      await inAppDone;
      await pushDone;
    });

    test('showInApp after dispose is a no-op and does not throw', () async {
      await sut.dispose();

      await expectLater(
        sut.showInApp(const InAppNotification(title: 'ignored')),
        completes,
      );
    });

    test('ingestPush after dispose is a no-op and does not throw', () async {
      await sut.dispose();

      expect(
        () => sut.ingestPush(
          PushMessage(id: 'x', title: 't', receivedAt: DateTime.utc(2026)),
        ),
        returnsNormally,
      );
    });
  });
}
