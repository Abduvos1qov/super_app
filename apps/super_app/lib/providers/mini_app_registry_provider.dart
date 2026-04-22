import 'package:demo_mini_app/demo_mini_app.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:food_mini_app/food_mini_app.dart';
import 'package:mini_app_registry/mini_app_registry.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:shipments_mini_app/shipments_mini_app.dart';
import 'package:super_app/providers/platform_providers.dart';
import 'package:taxi_mini_app/taxi_mini_app.dart';
import 'package:wallet_mini_app/wallet_mini_app.dart';

/// Compile-time list of [MiniApp]s shipped with this build of the shell.
///
/// Adding a new vertical means (a) landing the package in
/// `packages/mini_apps/`, (b) declaring it as a dependency in
/// `apps/super_app/pubspec.yaml`, and (c) adding its class here. The registry
/// enforces id uniqueness at review time; a dynamic install pipeline is
/// future work.
final miniAppRegistryProvider = Provider<MiniAppRegistry>((ref) {
  return const MiniAppRegistry(<MiniApp>[
    DemoMiniApp(),
    FoodMiniApp(),
    WalletMiniApp(),
    TaxiMiniApp(),
    ShipmentsMiniApp(),
  ]);
});

/// Mini-apps currently visible to the user.
///
/// Reactively recomputes whenever the session state or the feature-flag
/// snapshot changes — the registry's [MiniAppRegistry.allVisible] is pure so
/// a fresh call is cheap.
final visibleMiniAppsProvider = Provider<List<MiniApp>>((ref) {
  final registry = ref.watch(miniAppRegistryProvider);
  final session = ref.watch(_sessionForRegistryProvider);
  final flags = ref.watch(featureFlagServiceProvider);
  return registry.allVisible(session: session, featureFlags: flags);
});

/// Synchronous view of the current [SessionState]. Falls back to
/// [SessionAnonymous] while the underlying stream warms up, so consumers
/// (e.g. the launcher) always get a usable value during the first frame.
final _sessionForRegistryProvider = Provider<SessionState>((ref) {
  return ref.watch(sessionStateProvider).maybeWhen(
        data: (state) => state,
        orElse: () => const SessionAnonymous(),
      );
});
