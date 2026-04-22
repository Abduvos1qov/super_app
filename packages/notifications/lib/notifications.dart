/// Default implementations of the `NotificationRouter` contract declared in
/// `mini_app_sdk`. The shell wires these to platform UI (Overlay, snackbars)
/// and to optional push adapters (FCM, APNs) that live in sibling packages.
library;

export 'src/default_notification_router.dart';
export 'src/in_memory_notification_router.dart';
export 'src/notification_inbox.dart';
