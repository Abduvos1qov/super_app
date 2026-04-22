import 'package:mini_app_sdk/mini_app_sdk.dart';

/// Lightweight fake [MiniAppContext] for widget tests.
///
/// Every getter is overrideable via the constructor; anything left `null`
/// throws `UnimplementedError` so tests fail loudly if the production code
/// starts reaching for a service it did not previously use.
class FakeMiniAppContext implements MiniAppContext {
  /// Creates a fake context. Pass only the services the system under test
  /// actually needs; the rest will throw on access.
  FakeMiniAppContext({
    AnalyticsTracker? analytics,
    PermissionBroker? permissions,
    AppEventBus? events,
    NavigationGateway? navigation,
  })  : _analytics = analytics,
        _permissions = permissions,
        _events = events,
        _navigation = navigation;

  final AnalyticsTracker? _analytics;
  final PermissionBroker? _permissions;
  final AppEventBus? _events;
  final NavigationGateway? _navigation;

  @override
  AnalyticsTracker get analytics =>
      _analytics ?? (throw UnimplementedError('analytics not provided'));

  @override
  PermissionBroker get permissions =>
      _permissions ?? (throw UnimplementedError('permissions not provided'));

  @override
  AppEventBus get events =>
      _events ?? (throw UnimplementedError('events not provided'));

  @override
  NavigationGateway get navigation =>
      _navigation ?? (throw UnimplementedError('navigation not provided'));

  @override
  SessionController get session =>
      throw UnimplementedError('session not used in demo tests');

  @override
  NetworkGateway get network =>
      throw UnimplementedError('network not used in demo tests');

  @override
  PaymentGateway get payments =>
      throw UnimplementedError('payments not used in demo tests');

  @override
  NotificationRouter get notifications =>
      throw UnimplementedError('notifications not used in demo tests');

  @override
  FeatureFlagService get featureFlags =>
      throw UnimplementedError('featureFlags not used in demo tests');

  @override
  DeepLinkDispatcher get deepLinks =>
      throw UnimplementedError('deepLinks not used in demo tests');

  @override
  StorageScope get storage =>
      throw UnimplementedError('storage not used in demo tests');
}

/// Single analytics call captured by [RecordingAnalyticsTracker].
class RecordedAnalyticsCall {
  /// Creates a recorded call.
  const RecordedAnalyticsCall(this.event, this.props);

  /// Event name passed to `track`.
  final String event;

  /// Properties map passed to `track`.
  final Map<String, Object?> props;
}

/// Minimal [AnalyticsTracker] that records every call in-memory so tests can
/// assert on the exact event name and properties emitted by the code under
/// test.
class RecordingAnalyticsTracker implements AnalyticsTracker {
  final List<RecordedAnalyticsCall> _calls = <RecordedAnalyticsCall>[];

  /// Calls captured since the tracker was instantiated, in order.
  List<RecordedAnalyticsCall> get calls => List.unmodifiable(_calls);

  @override
  void track(String event, {Map<String, Object?> props = const {}}) {
    _calls.add(RecordedAnalyticsCall(event, Map<String, Object?>.of(props)));
  }

  @override
  void setUserProperty(String key, Object? value) {}

  @override
  Future<void> flush() async {}
}

/// Minimal [AppEventBus] that records every published event.
class RecordingAppEventBus implements AppEventBus {
  final List<AppEvent> _published = <AppEvent>[];

  /// Events captured since the bus was instantiated, in order.
  List<AppEvent> get published => List.unmodifiable(_published);

  @override
  void publish<T extends AppEvent>(T event) {
    _published.add(event);
  }

  @override
  Stream<T> on<T extends AppEvent>() => const Stream.empty();
}

/// Minimal [NavigationGateway] that records every navigation intent.
class RecordingNavigationGateway implements NavigationGateway {
  final List<String> openedMiniApps = <String>[];

  @override
  void openMiniApp(
    String id, {
    String? subPath,
    Map<String, String>? params,
  }) {
    openedMiniApps.add(id);
  }

  @override
  void pop() {}

  @override
  void pushWithin(String path) {}
}

/// Minimal [PermissionBroker] that returns a configurable fixed status and
/// records every call.
class RecordingPermissionBroker implements PermissionBroker {
  /// Creates a broker that always resolves to [status].
  RecordingPermissionBroker({this.status = PermissionStatus.granted});

  /// Status returned by every call, regardless of permission.
  final PermissionStatus status;

  final List<MiniAppPermission> requested = <MiniAppPermission>[];

  @override
  Future<PermissionStatus> check(MiniAppPermission permission) async => status;

  @override
  Future<PermissionStatus> request(
    MiniAppPermission permission, {
    required String rationale,
  }) async {
    requested.add(permission);
    return status;
  }
}
