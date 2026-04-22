import 'dart:async';

import 'package:mini_app_sdk/mini_app_sdk.dart';

/// A deterministic [NotificationRouter] for tests.
///
/// * [shownInApp] records every [showInApp] call in order, so assertions can
///   verify surfaces without relying on mocks.
/// * [pushSink] lets tests simulate an inbound push by pushing a
///   [PushMessage] into the stream exposed by [incoming].
/// * [clear] resets recorded state between tests.
class InMemoryNotificationRouter implements NotificationRouter {
  /// Creates an in-memory router with a broadcast push controller.
  InMemoryNotificationRouter()
      : _pushController = StreamController<PushMessage>.broadcast();

  final StreamController<PushMessage> _pushController;

  /// Notifications passed to [showInApp], recorded in call order.
  final List<InAppNotification> shownInApp = <InAppNotification>[];

  /// Test hook that simulates a push arriving on the underlying stream.
  ///
  /// No-ops silently after [dispose] to mirror the production router.
  void pushSink(PushMessage message) {
    if (_pushController.isClosed) return;
    _pushController.add(message);
  }

  @override
  Future<void> showInApp(InAppNotification notification) async {
    shownInApp.add(notification);
  }

  @override
  Stream<PushMessage> incoming() => _pushController.stream;

  /// Clears [shownInApp]. The underlying push controller is not replaced so
  /// existing subscribers stay attached.
  void clear() {
    shownInApp.clear();
  }

  /// Closes the push controller. Subsequent [pushSink] calls become no-ops.
  Future<void> dispose() async {
    await _pushController.close();
  }
}
