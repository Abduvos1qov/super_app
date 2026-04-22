import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:super_app/shell/mini_app_host.dart';
import 'package:super_app/shell/shell_scaffold.dart';

/// Root [GoRouter] for the super-app shell.
///
/// Route table:
///
/// * `/`                     — [ShellScaffold] (bottom navigation root).
/// * `/m/:miniAppId`         — [MiniAppHost] mounts the mini-app's root route.
/// * `/m/:miniAppId/:subPath`— [MiniAppHost] with a sub-path passed through as
///   routing state; the host currently renders the mini-app's root route
///   until nested route mounting lands in a follow-up migration step.
final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: <RouteBase>[
      GoRoute(
        path: '/',
        name: 'shell',
        builder: (_, __) => const ShellScaffold(),
      ),
      GoRoute(
        path: '/m/:miniAppId',
        name: 'mini-app-root',
        builder: (_, state) => MiniAppHost(
          miniAppId: state.pathParameters['miniAppId'] ?? '',
          state: state,
        ),
        routes: <RouteBase>[
          GoRoute(
            path: ':subPath',
            name: 'mini-app-sub',
            builder: (_, state) => MiniAppHost(
              miniAppId: state.pathParameters['miniAppId'] ?? '',
              state: state,
            ),
          ),
        ],
      ),
    ],
  );
});
