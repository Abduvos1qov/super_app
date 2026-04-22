import 'package:meta/meta.dart';

/// Severity level used to style in-app notifications.
enum InAppNotificationSeverity {
  /// Neutral informational message.
  info,

  /// Positive confirmation (e.g. payment succeeded).
  success,

  /// Caution; user may want to review.
  warning,

  /// Blocking error that requires attention.
  error,
}

/// A transient notification surfaced inside the shell UI (snackbar, banner,
/// toast) on behalf of a mini-app.
@immutable
class InAppNotification {
  /// Creates an in-app notification.
  const InAppNotification({
    required this.title,
    this.body,
    this.severity = InAppNotificationSeverity.info,
    this.actionLabel,
    this.deepLink,
  });

  /// Primary message shown to the user.
  final String title;

  /// Optional secondary text.
  final String? body;

  /// Severity used to style the surface.
  final InAppNotificationSeverity severity;

  /// Label for the optional action button. Requires [deepLink] to be set.
  final String? actionLabel;

  /// Deep link followed when the user taps the notification or its action.
  final Uri? deepLink;
}

/// Inbound push message received from the remote notifications provider.
@immutable
class PushMessage {
  /// Creates a push message.
  const PushMessage({
    required this.id,
    required this.title,
    required this.receivedAt,
    this.body,
    this.data = const <String, String>{},
  });

  /// Provider-assigned message identifier.
  final String id;

  /// User-visible title.
  final String title;

  /// User-visible body text.
  final String? body;

  /// UTC timestamp at which the shell received the message.
  final DateTime receivedAt;

  /// Free-form payload attached by the sender.
  final Map<String, String> data;
}

/// Shell-side notification facade exposed to mini-apps.
///
/// Mini-apps never call the push SDK or the platform UI framework directly;
/// they request surfaces through this router and observe inbound traffic.
abstract class NotificationRouter {
  /// Shows a transient in-app notification.
  Future<void> showInApp(InAppNotification notification);

  /// Observes inbound push messages delivered while the mini-app is active.
  Stream<PushMessage> incoming();
}
