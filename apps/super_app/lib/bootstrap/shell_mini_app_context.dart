import 'package:mini_app_sdk/mini_app_sdk.dart';

/// Concrete [MiniAppContext] that the shell hands to each mini-app.
///
/// The shell builds one [ShellMiniAppContext] per mini-app id so the
/// per-scope services ([StorageScope], [DeepLinkDispatcher] filtering, the
/// [NavigationGateway]) stay isolated. Shared services (session, analytics,
/// feature flags, events, notifications, permissions, network, payments) are
/// singletons passed into every instance unchanged.
class ShellMiniAppContext implements MiniAppContext {
  /// Wires every platform service into a context bound to [miniAppId].
  const ShellMiniAppContext({
    required this.miniAppId,
    required SessionController session,
    required NetworkGateway network,
    required PaymentGateway payments,
    required NotificationRouter notifications,
    required AnalyticsTracker analytics,
    required FeatureFlagService featureFlags,
    required AppEventBus events,
    required DeepLinkDispatcher deepLinks,
    required PermissionBroker permissions,
    required StorageScope storage,
    required NavigationGateway navigation,
  })  : _session = session,
        _network = network,
        _payments = payments,
        _notifications = notifications,
        _analytics = analytics,
        _featureFlags = featureFlags,
        _events = events,
        _deepLinks = deepLinks,
        _permissions = permissions,
        _storage = storage,
        _navigation = navigation;

  /// The id of the mini-app this context was built for.
  final String miniAppId;

  final SessionController _session;
  final NetworkGateway _network;
  final PaymentGateway _payments;
  final NotificationRouter _notifications;
  final AnalyticsTracker _analytics;
  final FeatureFlagService _featureFlags;
  final AppEventBus _events;
  final DeepLinkDispatcher _deepLinks;
  final PermissionBroker _permissions;
  final StorageScope _storage;
  final NavigationGateway _navigation;

  @override
  SessionController get session => _session;

  @override
  NetworkGateway get network => _network;

  @override
  PaymentGateway get payments => _payments;

  @override
  NotificationRouter get notifications => _notifications;

  @override
  AnalyticsTracker get analytics => _analytics;

  @override
  FeatureFlagService get featureFlags => _featureFlags;

  @override
  AppEventBus get events => _events;

  @override
  DeepLinkDispatcher get deepLinks => _deepLinks;

  @override
  PermissionBroker get permissions => _permissions;

  @override
  StorageScope get storage => _storage;

  @override
  NavigationGateway get navigation => _navigation;
}
