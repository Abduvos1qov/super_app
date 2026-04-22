import 'package:meta/meta.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';

/// A read/unread record of a notification the user has seen.
///
/// Produced by [NotificationInbox.recordInApp] and
/// [NotificationInbox.recordPush]; consumers (e.g. a "Notifications" screen)
/// list [NotificationInbox.entries] and toggle [InboxEntry.read] via
/// [NotificationInbox.markRead].
@immutable
class InboxEntry {
  /// Creates an inbox entry.
  const InboxEntry({
    required this.id,
    required this.title,
    required this.receivedAt,
    this.body,
    this.severity = InAppNotificationSeverity.info,
    this.deepLink,
    this.read = false,
  });

  /// Stable identifier within the inbox. For push messages this matches
  /// [PushMessage.id]; for in-app records the inbox synthesises one.
  final String id;

  /// User-visible title.
  final String title;

  /// Optional secondary text.
  final String? body;

  /// Severity used for styling the row.
  final InAppNotificationSeverity severity;

  /// Optional deep link to follow when the entry is tapped.
  final Uri? deepLink;

  /// UTC timestamp at which the entry was recorded.
  final DateTime receivedAt;

  /// Whether the user has marked this entry as read.
  final bool read;

  /// Returns a copy of this entry with [read] set to the given value.
  InboxEntry copyWith({bool? read}) {
    return InboxEntry(
      id: id,
      title: title,
      body: body,
      severity: severity,
      deepLink: deepLink,
      receivedAt: receivedAt,
      read: read ?? this.read,
    );
  }
}

/// In-memory notification history.
///
/// Stores a bounded list of [InboxEntry]s so a mini-app (or the shell itself)
/// can render a "Notifications" screen without wiring persistent storage.
///
/// This inbox intentionally does **not** use [StorageScope]; persistence
/// belongs to the mini-app or a future `notifications_inbox_persistence`
/// package. On app restart, the inbox is empty.
class NotificationInbox {
  /// Creates an inbox that keeps at most [capacity] entries (default 100).
  NotificationInbox({this.capacity = 100})
      : assert(capacity > 0, 'capacity must be positive');

  /// Maximum number of entries retained. Older entries are evicted FIFO.
  final int capacity;

  final List<InboxEntry> _entries = <InboxEntry>[];

  /// An unmodifiable snapshot of the current entries, newest first.
  List<InboxEntry> get entries => List<InboxEntry>.unmodifiable(_entries);

  /// Count of entries with `read == false`.
  int get unreadCount => _entries.where((e) => !e.read).length;

  /// Records an [InAppNotification] that was shown to the user.
  ///
  /// A new [InboxEntry] is prepended and returned so the caller can reference
  /// it (e.g. to mark read). [receivedAt] defaults to `DateTime.now().toUtc()`.
  InboxEntry recordInApp(
    InAppNotification notification, {
    String? id,
    DateTime? receivedAt,
  }) {
    final entry = InboxEntry(
      id: id ?? _synthesizeId(),
      title: notification.title,
      body: notification.body,
      severity: notification.severity,
      deepLink: notification.deepLink,
      receivedAt: receivedAt ?? DateTime.now().toUtc(),
    );
    _insert(entry);
    return entry;
  }

  /// Records an inbound [PushMessage].
  ///
  /// Uses [PushMessage.id] as the inbox id and [PushMessage.receivedAt] as
  /// the timestamp. Severity defaults to [InAppNotificationSeverity.info].
  InboxEntry recordPush(PushMessage message) {
    final entry = InboxEntry(
      id: message.id,
      title: message.title,
      body: message.body,
      receivedAt: message.receivedAt,
    );
    _insert(entry);
    return entry;
  }

  /// Marks the entry with [id] as read. Returns `true` if a matching entry
  /// existed; `false` otherwise.
  bool markRead(String id) {
    for (var i = 0; i < _entries.length; i++) {
      if (_entries[i].id == id) {
        if (_entries[i].read) return true;
        _entries[i] = _entries[i].copyWith(read: true);
        return true;
      }
    }
    return false;
  }

  /// Removes every entry.
  void clear() {
    _entries.clear();
  }

  void _insert(InboxEntry entry) {
    _entries.insert(0, entry);
    if (_entries.length > capacity) {
      _entries.removeRange(capacity, _entries.length);
    }
  }

  int _idSeed = 0;

  String _synthesizeId() {
    _idSeed++;
    return 'inapp-${DateTime.now().microsecondsSinceEpoch}-$_idSeed';
  }
}
