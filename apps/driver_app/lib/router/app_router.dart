import 'package:feature_driver/feature_driver.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Single [GoRouter] for the driver app. Screens use `context.go('/...')` —
/// never `Navigator.of(context).push(...)`.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        name: 'home',
        builder: (context, state) => DriverFeature.buildEntry(),
      ),
    ],
  );
});
