import 'package:mini_app_sdk/src/services/analytics_tracker.dart';
import 'package:mini_app_sdk/src/services/app_event_bus.dart';
import 'package:mini_app_sdk/src/services/deep_link_dispatcher.dart';
import 'package:mini_app_sdk/src/services/feature_flag_service.dart';
import 'package:mini_app_sdk/src/services/navigation_gateway.dart';
import 'package:mini_app_sdk/src/services/network_gateway.dart';
import 'package:mini_app_sdk/src/services/notification_router.dart';
import 'package:mini_app_sdk/src/services/payment_gateway.dart';
import 'package:mini_app_sdk/src/services/permission_broker.dart';
import 'package:mini_app_sdk/src/services/session_controller.dart';
import 'package:mini_app_sdk/src/services/storage_scope.dart';

/// Facade handed to a mini-app by the shell. It exposes every platform
/// service the mini-app may legitimately use.
///
/// Mini-apps resolve dependencies through the context rather than importing
/// concrete service packages. The shell is free to substitute
/// implementations (fake in tests, remote-backed in release) without
/// breaking the contract.
abstract class MiniAppContext {
  /// Authentication and session state facade.
  SessionController get session;

  /// HTTP facade scoped to the calling mini-app.
  NetworkGateway get network;

  /// Payments and wallet facade.
  PaymentGateway get payments;

  /// In-app and push notification facade.
  NotificationRouter get notifications;

  /// Product analytics facade.
  AnalyticsTracker get analytics;

  /// Feature-flag resolver.
  FeatureFlagService get featureFlags;

  /// Cross-mini-app event bus.
  AppEventBus get events;

  /// Deep-link dispatcher scoped to the calling mini-app.
  DeepLinkDispatcher get deepLinks;

  /// OS-level permission broker.
  PermissionBroker get permissions;

  /// Namespaced key-value storage for the calling mini-app.
  StorageScope get storage;

  /// Shell-mediated navigation facade.
  NavigationGateway get navigation;
}
