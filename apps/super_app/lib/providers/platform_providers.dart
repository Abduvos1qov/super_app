import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mini_app_sdk/mini_app_sdk.dart';

import 'package:super_app/bootstrap/app_bootstrap.dart';

/// Owns the root [AppBootstrap] instance for the lifetime of the
/// `ProviderContainer`.
///
/// Production builds override this provider with their environment-specific
/// `AppBootstrap` (Firebase, real secure storage, real FCM). Dev and widget
/// tests fall back to [AppBootstrap.dev].
///
/// `ref.onDispose` releases every disposable the bootstrap owns so stream
/// subscriptions do not leak between container rebuilds.
final appBootstrapProvider = Provider<AppBootstrap>((ref) {
  final bootstrap = AppBootstrap.dev();
  ref.onDispose(bootstrap.dispose);
  return bootstrap;
});

/// Exposes the shared [SessionController] surfaced by the auth package.
final sessionControllerProvider = Provider<SessionController>((ref) {
  return ref.watch(appBootstrapProvider).sessionController;
});

/// Reactive view of the current [SessionState].
///
/// Widgets and router redirects consume this instead of calling
/// `sessionController.watch()` directly so they can rely on Riverpod's
/// dependency graph for cache invalidation.
final sessionStateProvider = StreamProvider<SessionState>((ref) {
  return ref.watch(sessionControllerProvider).watch();
});

/// Shared [NetworkGateway]. Mini-apps do not consume this directly; the shell
/// routes it through [MiniAppContext.network].
final networkGatewayProvider = Provider<NetworkGateway>((ref) {
  return ref.watch(appBootstrapProvider).networkGateway;
});

/// Shared [PaymentGateway].
final paymentGatewayProvider = Provider<PaymentGateway>((ref) {
  return ref.watch(appBootstrapProvider).paymentGateway;
});

/// Shared [NotificationRouter]. The shell subscribes to its `inAppStream`
/// separately to render snackbars.
final notificationRouterProvider = Provider<NotificationRouter>((ref) {
  return ref.watch(appBootstrapProvider).notificationRouter;
});

/// Shared [AnalyticsTracker].
final analyticsTrackerProvider = Provider<AnalyticsTracker>((ref) {
  return ref.watch(appBootstrapProvider).analyticsTracker;
});

/// Shared [FeatureFlagService].
final featureFlagServiceProvider = Provider<FeatureFlagService>((ref) {
  return ref.watch(appBootstrapProvider).featureFlagService;
});

/// Shared [AppEventBus]. Mini-apps publish / subscribe here.
final appEventBusProvider = Provider<AppEventBus>((ref) {
  return ref.watch(appBootstrapProvider).eventBus;
});

/// Shared [DeepLinkDispatcher]. The shell feeds incoming links via its
/// concrete `DefaultDeepLinkDispatcher.submit` hook (wired in
/// `main.dart` once a platform link source is added).
final deepLinkDispatcherProvider = Provider<DeepLinkDispatcher>((ref) {
  return ref.watch(appBootstrapProvider).deepLinkDispatcher;
});

/// Shared [PermissionBroker].
final permissionBrokerProvider = Provider<PermissionBroker>((ref) {
  return ref.watch(appBootstrapProvider).permissionBroker;
});

/// Produces a [MiniAppContext] for a given mini-app id.
///
/// Every mini-app gets its own context instance so per-scope services
/// ([StorageScope], [NavigationGateway]) stay isolated. The [GoRouter] must
/// be passed because the navigation gateway is router-specific.
final miniAppContextFactoryProvider = Provider<MiniAppContextFactory>((ref) {
  final bootstrap = ref.watch(appBootstrapProvider);
  return (String miniAppId, {required GoRouter router}) =>
      bootstrap.buildContext(miniAppId: miniAppId, router: router);
});
