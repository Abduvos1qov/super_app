import 'package:flutter_test/flutter_test.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:notifications/notifications.dart';

void main() {
  group('NotificationInbox', () {
    late NotificationInbox sut;

    setUp(() {
      sut = NotificationInbox();
    });

    test('records in-app notifications newest-first', () {
      final first = sut.recordInApp(
        const InAppNotification(title: 'one'),
        receivedAt: DateTime.utc(2026, 4, 21, 10),
      );
      final second = sut.recordInApp(
        const InAppNotification(title: 'two'),
        receivedAt: DateTime.utc(2026, 4, 21, 11),
      );

      expect(sut.entries.map((e) => e.id), [second.id, first.id]);
      expect(sut.entries.first.title, 'two');
    });

    test('records push messages using message id and timestamp', () {
      final entry = sut.recordPush(
        PushMessage(
          id: 'm-42',
          title: 'Ride confirmed',
          body: 'Driver on the way',
          receivedAt: DateTime.utc(2026, 4, 21, 9),
        ),
      );

      expect(entry.id, 'm-42');
      expect(entry.title, 'Ride confirmed');
      expect(entry.body, 'Driver on the way');
      expect(entry.receivedAt, DateTime.utc(2026, 4, 21, 9));
    });

    test('unreadCount reflects entries whose read flag is false', () {
      final a = sut.recordInApp(const InAppNotification(title: 'a'));
      sut.recordInApp(const InAppNotification(title: 'b'));

      expect(sut.unreadCount, 2);

      sut.markRead(a.id);

      expect(sut.unreadCount, 1);
    });

    test('markRead returns false for unknown id', () {
      sut.recordInApp(const InAppNotification(title: 'x'));

      expect(sut.markRead('nope'), isFalse);
      expect(sut.unreadCount, 1);
    });

    test('markRead is idempotent on an already-read entry', () {
      final entry = sut.recordInApp(const InAppNotification(title: 'x'));

      expect(sut.markRead(entry.id), isTrue);
      expect(sut.markRead(entry.id), isTrue);
      expect(sut.unreadCount, 0);
    });

    test('evicts oldest entries when capacity is exceeded', () {
      final inbox = NotificationInbox(capacity: 2);

      final a = inbox.recordInApp(const InAppNotification(title: 'a'));
      final b = inbox.recordInApp(const InAppNotification(title: 'b'));
      final c = inbox.recordInApp(const InAppNotification(title: 'c'));

      expect(inbox.entries.map((e) => e.id), [c.id, b.id]);
      expect(inbox.entries.any((e) => e.id == a.id), isFalse);
    });

    test('clear removes every entry', () {
      sut
        ..recordInApp(const InAppNotification(title: 'a'))
        ..recordInApp(const InAppNotification(title: 'b'))
        ..clear();

      expect(sut.entries, isEmpty);
      expect(sut.unreadCount, 0);
    });

    test('entries is an unmodifiable view', () {
      sut.recordInApp(const InAppNotification(title: 'a'));

      expect(() => sut.entries.clear(), throwsUnsupportedError);
    });
  });
}
