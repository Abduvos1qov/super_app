// The shell is the documented single legitimate constructor of
// `StreamAppEventBus` and `DefaultDeepLinkDispatcher`; both classes are
// annotated `@visibleForTesting` inside their packages but are explicitly
// marked as shell-only public API in their CLAUDE.md. The ignore here is a
// deliberate waiver, not an escape hatch for production mini-app code.
// ignore_for_file: invalid_use_of_visible_for_testing_member

import 'package:analytics/analytics.dart';
import 'package:auth/auth.dart';
import 'package:core/core.dart';
import 'package:deep_links/deep_links.dart';
import 'package:event_bus/event_bus.dart';
import 'package:feature_flags/feature_flags.dart';
import 'package:go_router/go_router.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:networking/networking.dart';
import 'package:notifications/notifications.dart';
import 'package:payments/payments.dart';
import 'package:permissions/permissions.dart';
import 'package:storage/storage.dart';

import 'package:super_app/bootstrap/shell_mini_app_context.dart';
import 'package:super_app/bootstrap/shell_navigation_gateway.dart';

/// Factory that builds a [MiniAppContext] for a given mini-app id. The
/// [router] argument is passed lazily because the router is itself a
/// consumer of the bootstrap via provider wiring.
typedef MiniAppContextFactory = MiniAppContext Function(
  String miniAppId, {
  required GoRouter router,
});

/// Root composition container. Owns every platform service singleton that a
/// mini-app can reach through [MiniAppContext].
///
/// Two flavours ship:
///
/// * [AppBootstrap.dev] — fully in-memory / logging implementations. Safe to
///   instantiate without network, secure storage, or FCM. Suitable for
///   widget tests and local development runs.
/// * Production wiring (Firebase, real FCM backend, `FlutterSecureStorage`,
///   `SharedPreferences`) lives in a future `env/prod_bootstrap.dart` and
///   overrides the providers declared in `providers/platform_providers.dart`.
///
/// The class is deliberately not a `ConsumerWidget` or Riverpod notifier: it
/// represents the composition root. Riverpod providers adapt its fields into
/// the tree.
class AppBootstrap {
  AppBootstrap._({
    required this.secureStorage,
    required this.preferencesStorage,
    required this.sessionController,
    required this.apiClient,
    required this.networkGateway,
    required this.paymentGateway,
    required this.notificationRouter,
    required this.analyticsTracker,
    required this.featureFlagService,
    required this.eventBus,
    required this.deepLinkDispatcher,
    required this.permissionBroker,
  });

  /// Assembles a dev wiring: all services are in-memory or logging-backed.
  ///
  /// No real I/O is performed — the underlying [ApiClient] is built against a
  /// fake base URL and never called by the dev path. Production wiring will
  /// swap each implementation at the provider level.
  factory AppBootstrap.dev() {
    final SecureStorage secureStorage = InMemorySecureStorage();
    final PreferencesStorage preferencesStorage = InMemoryPreferencesStorage();
    final tokenStorage = SecureTokenStorage(secureStorage);

    // ApiClient needs a TokenProvider, but the AuthTokenProviderAdapter
    // needs a SessionController, which needs an AuthService, which needs
    // a NetworkGateway, which needs an ApiClient. Break the cycle with a
    // lazy _DeferredTokenProvider: ApiClient reads the eventual token
    // through it after the session controller is constructed.
    final deferredTokenProvider = _DeferredTokenProvider();

    final apiClient = ApiClient(
      baseUrl: 'http://localhost:8080',
      tokenProvider: deferredTokenProvider,
    );
    final NetworkGateway networkGateway = NetworkGatewayImpl(apiClient);

    final authService = OtpAuthService(gateway: networkGateway);
    final sessionController = DefaultSessionController(
      authService: authService,
      tokenStorage: tokenStorage,
    );
    deferredTokenProvider.delegate = AuthTokenProviderAdapter(
      sessionController: sessionController,
      tokenStorage: tokenStorage,
    );

    final PaymentGateway paymentGateway = InMemoryPaymentGateway(
      initialBalance: WalletBalance(
        available: Money.uzs(100000),
        updatedAt: DateTime.now().toUtc(),
      ),
    );

    final notificationRouter = DefaultNotificationRouter();

    final AnalyticsTracker analyticsTracker = FanoutAnalyticsTracker(
      <AnalyticsTracker>[LoggingAnalyticsTracker()],
    );

    final FeatureFlagService featureFlagService = CompositeFeatureFlagService(
      <FeatureFlagService>[
        InMemoryFeatureFlagService(),
        const StaticFeatureFlagService(<String, Object?>{}),
      ],
    );

    final eventBus = StreamAppEventBus();

    final deepLinkDispatcher = DefaultDeepLinkDispatcher(
      parser: const DeepLinkParser(DeepLinkSchemeConfig()),
    );

    final PermissionBroker permissionBroker = DefaultPermissionBroker();

    return AppBootstrap._(
      secureStorage: secureStorage,
      preferencesStorage: preferencesStorage,
      sessionController: sessionController,
      apiClient: apiClient,
      networkGateway: networkGateway,
      paymentGateway: paymentGateway,
      notificationRouter: notificationRouter,
      analyticsTracker: analyticsTracker,
      featureFlagService: featureFlagService,
      eventBus: eventBus,
      deepLinkDispatcher: deepLinkDispatcher,
      permissionBroker: permissionBroker,
    );
  }

  /// Platform-neutral secure key-value store (tokens, credentials).
  final SecureStorage secureStorage;

  /// Non-sensitive key-value store.
  final PreferencesStorage preferencesStorage;

  /// Shell-wide session controller shared across every mini-app.
  final DefaultSessionController sessionController;

  /// Underlying Dio-backed HTTP client.
  final ApiClient apiClient;

  /// Typed network facade exposed through [MiniAppContext].
  final NetworkGateway networkGateway;

  /// Payments facade. Dev wiring ships [InMemoryPaymentGateway].
  final PaymentGateway paymentGateway;

  /// Notifications transport. Concrete [DefaultNotificationRouter] so the
  /// shell can subscribe to [DefaultNotificationRouter.inAppStream] and
  /// render snackbars.
  final DefaultNotificationRouter notificationRouter;

  /// Analytics fan-out.
  final AnalyticsTracker analyticsTracker;

  /// Feature-flag composite (overrides + static defaults in dev).
  final FeatureFlagService featureFlagService;

  /// Cross-mini-app event bus. Concrete [StreamAppEventBus] so the shell can
  /// dispose it on teardown.
  final StreamAppEventBus eventBus;

  /// Deep-link dispatcher. Concrete so the shell can call
  /// [DefaultDeepLinkDispatcher.submit] from its platform link source.
  final DefaultDeepLinkDispatcher deepLinkDispatcher;

  /// OS permission broker.
  final PermissionBroker permissionBroker;

  /// Builds a [MiniAppContext] bound to [miniAppId].
  ///
  /// The returned context exposes shared services directly and per-mini-app
  /// [StorageScope] + [NavigationGateway] instances. Callers typically do not
  /// invoke this directly; they go through `miniAppContextFactoryProvider`.
  MiniAppContext buildContext({
    required String miniAppId,
    required GoRouter router,
  }) {
    return ShellMiniAppContext(
      miniAppId: miniAppId,
      session: sessionController,
      network: networkGateway,
      payments: paymentGateway,
      notifications: notificationRouter,
      analytics: analyticsTracker,
      featureFlags: featureFlagService,
      events: eventBus,
      deepLinks: deepLinkDispatcher,
      permissions: permissionBroker,
      storage: ScopedStorage(
        miniAppId: miniAppId,
        backend: preferencesStorage,
      ),
      navigation: ShellNavigationGateway(
        router: router,
        miniAppId: miniAppId,
      ),
    );
  }

  /// Releases every disposable resource. Called from the root
  /// `ProviderContainer` via `ref.onDispose` in app-level providers.
  Future<void> dispose() async {
    await eventBus.dispose();
    await notificationRouter.dispose();
    await deepLinkDispatcher.dispose();
    await sessionController.dispose();
  }
}

/// Late-bound [TokenProvider]. Solves the construction-order cycle between
/// [ApiClient] (needs a [TokenProvider]) and [AuthTokenProviderAdapter]
/// (needs a [DefaultSessionController], which is built after the gateway).
class _DeferredTokenProvider implements TokenProvider {
  TokenProvider? delegate;

  @override
  Future<String?> currentToken() async {
    if (delegate case final TokenProvider provider) {
      return provider.currentToken();
    }
    return null;
  }

  @override
  Future<void> invalidate() async {
    if (delegate case final TokenProvider provider) {
      await provider.invalidate();
    }
  }
}
