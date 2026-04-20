import 'package:feature_delivery/feature_delivery.dart';
import 'package:feature_driver/feature_driver.dart';
import 'package:feature_food/feature_food.dart';
import 'package:feature_taxi/feature_taxi.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../home/launcher_screen.dart';

/// Single [GoRouter] for the passenger super app. Each feature contributes
/// its own route; the launcher is the root.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'launcher',
        builder: (context, state) => const LauncherScreen(),
      ),
      GoRoute(
        path: TaxiFeature.route,
        name: 'taxi',
        builder: (context, state) => TaxiFeature.buildEntry(),
      ),
      GoRoute(
        path: FoodFeature.route,
        name: 'food',
        builder: (context, state) => FoodFeature.buildEntry(),
      ),
      GoRoute(
        path: DeliveryFeature.route,
        name: 'delivery',
        builder: (context, state) => DeliveryFeature.buildEntry(),
      ),
      GoRoute(
        path: DriverFeature.route,
        name: 'driver',
        builder: (context, state) => DriverFeature.buildEntry(),
      ),
    ],
  );
});
