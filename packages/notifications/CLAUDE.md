# notifications

Vendor-agnostic notifications platform service. Provides the default
implementation of the `NotificationRouter` contract declared in
`mini_app_sdk`, plus an in-memory test double and an optional in-memory
`NotificationInbox` for rendering a "Notifications" screen.

## Purpose

- Route transient in-app notifications from mini-apps to the shell's
  Overlay (snackbar / toast / banner) via a broadcast stream.
- Expose a `Stream<PushMessage>` that the shell feeds from any push adapter
  (FCM, APNs, OneSignal) living in a sibling package.
- Offer a bounded in-memory inbox so mini-apps can list recent notifications
  without persistent storage wiring.

## In-app vs push

- **In-app** originates inside a mini-app: it calls
  `NotificationRouter.showInApp(n)`. The shell listens on
  `DefaultNotificationRouter.inAppStream` and renders each notification.
- **Push** originates outside the app. A platform adapter decodes the
  native payload into a `PushMessage` and calls
  `DefaultNotificationRouter.ingestPush(message)`. Mini-apps observe them
  via `NotificationRouter.incoming()`.

## Shell wiring

```dart
final router = DefaultNotificationRouter();

// Render in-app notifications through the Overlay.
router.inAppStream.listen((n) => overlay.showSnackBar(n));

// Forward decoded FCM payloads.
FirebaseMessaging.onMessage.listen((rm) {
  router.ingestPush(PushMessage(
    id: rm.messageId ?? const Uuid().v4(),
    title: rm.notification?.title ?? '',
    body: rm.notification?.body,
    receivedAt: DateTime.now().toUtc(),
    data: rm.data.map((k, v) => MapEntry(k, v.toString())),
  ));
});
```

## Rules

- Never depend on a vendor SDK (`firebase_messaging`, `onesignal_flutter`,
  `flutter_local_notifications`). Each adapter lives in its own package
  (e.g. `notifications_fcm`, `notifications_apns`) and calls `ingestPush`.
- No widgets, no navigation, no storage — this package is pure transport.
- `NotificationInbox` is memory-only. Persistence belongs to the mini-app
  or a future `notifications_inbox_persistence` package; do not reach for
  `StorageScope` here.
- `showInApp` and `ingestPush` must no-op after `dispose` so late native
  callbacks cannot crash the shell.

## Structure

```
lib/
├── notifications.dart                    // barrel
└── src/
    ├── default_notification_router.dart
    ├── in_memory_notification_router.dart
    └── notification_inbox.dart
test/
├── default_notification_router_test.dart
├── in_memory_notification_router_test.dart
└── notification_inbox_test.dart
```
