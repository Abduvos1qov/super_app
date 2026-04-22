/// Contract between the super-app shell and mini-apps.
///
/// This library exposes:
///
/// * `MiniApp` — the base class every vertical implements.
/// * `MiniAppManifest` and related value types that describe a mini-app.
/// * `MiniAppContext` — the facade the shell hands to each mini-app.
/// * Platform service interfaces (session, network, payments, analytics, …)
///   that mini-apps use instead of importing concrete platform packages.
library;

export 'src/context/mini_app_context.dart';
export 'src/events/app_event.dart';
export 'src/manifest/mini_app_category.dart';
export 'src/manifest/mini_app_manifest.dart';
export 'src/manifest/mini_app_permission.dart';
export 'src/manifest/mini_app_visibility.dart';
export 'src/mini_app.dart';
export 'src/mini_app_route.dart';
export 'src/services/analytics_tracker.dart';
export 'src/services/app_event_bus.dart';
export 'src/services/deep_link_dispatcher.dart';
export 'src/services/feature_flag_service.dart';
export 'src/services/navigation_gateway.dart';
export 'src/services/network_gateway.dart';
export 'src/services/notification_router.dart';
export 'src/services/payment_gateway.dart';
export 'src/services/permission_broker.dart';
export 'src/services/session_controller.dart';
export 'src/services/storage_scope.dart';
