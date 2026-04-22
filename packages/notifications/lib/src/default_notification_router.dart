import 'dart:async';

import 'package:mini_app_sdk/mini_app_sdk.dart';

/// Default [NotificationRouter] used by the shell.
///
/// Holds two broadcast streams that bridge mini-apps and the host:
///
/// * [inAppStream] — fed by [showInApp]; the shell subscribes and renders
///   each notification via its Overlay (snackbar, banner, toast).
/// * [incoming] — fed by [ingestPush]; push adapters (FCM, APNs) decode their
///   native payloads into [PushMessage] and call [ingestPush] on every
///   delivery. Mini-apps observe the stream through the interface.
///
/// The router is strictly a transport layer: it keeps no history, performs
/// no persistence, and holds no vendor SDK references.
class DefaultNotificationRouter implements NotificationRouter {
  /// Creates a router with its own broadcast controllers.
  DefaultNotificationRouter()
      : _inAppController = StreamController<InAppNotification>.broadcast(),
        _pushController = StreamController<PushMessage>.broadcast();

  final StreamController<InAppNotification> _inAppController;
  final StreamController<PushMessage> _pushController;

  /// Stream the shell subscribes to, rendering each notification as a
  /// snackbar, toast, or overlay card according to its severity.
  Stream<InAppNotification> get inAppStream => _inAppController.stream;

  /// Entry point for push adapters (FCM, APNs). They decode their native
  /// payload into a [PushMessage] and call this.
  ///
  /// No-ops silently after [dispose] so late callbacks from native code do
  /// not crash the shell.
  void ingestPush(PushMessage message) {
    if (_pushController.isClosed) return;
    _pushController.add(message);
  }

  @override
  Future<void> showInApp(InAppNotification notification) async {
    if (_inAppController.isClosed) return;
    _inAppController.add(notification);
  }

  @override
  Stream<PushMessage> incoming() => _pushController.stream;

  /// Closes both underlying controllers. Subsequent [showInApp] and
  /// [ingestPush] calls become no-ops.
  Future<void> dispose() async {
    await _inAppController.close();
    await _pushController.close();
  }
}
