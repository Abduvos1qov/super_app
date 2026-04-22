import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:shared_ui/shared_ui.dart';

import 'package:super_app/providers/mini_app_registry_provider.dart';
import 'package:super_app/providers/platform_providers.dart';

/// Mount point for a single mini-app.
///
/// The shell owns the route pattern `/m/:miniAppId/:subPath*` and delegates
/// the inner screen to the mini-app's own routes. For the MVP the host finds
/// the mini-app's root [MiniAppRoute] (one whose `path == '/'`) and renders
/// its builder with a freshly-minted [MiniAppContext]. Nested sub-routes are
/// wired up in a follow-up step once more than one mini-app contributes
/// deep structure.
class MiniAppHost extends ConsumerWidget {
  /// Creates a host bound to [miniAppId].
  const MiniAppHost({required this.miniAppId, this.state, super.key});

  /// Mini-app manifest id resolved from the route parameter.
  final String miniAppId;

  /// Opaque routing state forwarded to the mini-app's route builder. May be
  /// `null` when the shell mounts the root route without parameters.
  final Object? state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final registry = ref.watch(miniAppRegistryProvider);
    final miniApp = registry.byId(miniAppId);

    if (miniApp == null) {
      return _MiniAppNotFound(miniAppId: miniAppId);
    }

    final factory = ref.watch(miniAppContextFactoryProvider);
    final router = GoRouter.of(context);
    final miniAppContext = factory(miniAppId, router: router);
    final routes = miniApp.routes(miniAppContext);
    final rootRoute = _rootRouteOrNull(routes);

    if (rootRoute == null) {
      return _MiniAppNotFound(
        miniAppId: miniAppId,
        reason: 'Mini-app declared no root route (path "/").',
      );
    }

    return rootRoute.builder(context, state);
  }

  MiniAppRoute? _rootRouteOrNull(List<MiniAppRoute> routes) {
    for (final route in routes) {
      if (route.path == '/' || route.path.isEmpty) return route;
    }
    return routes.isNotEmpty ? routes.first : null;
  }
}

class _MiniAppNotFound extends StatelessWidget {
  const _MiniAppNotFound({required this.miniAppId, this.reason});

  final String miniAppId;
  final String? reason;

  @override
  Widget build(BuildContext context) {
    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final colors =
        Theme.of(context).extension<AppColors>() ?? AppColors.light();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Not found')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, size: 64, color: colors.danger),
              SizedBox(height: spacing.md),
              Text(
                'Mini-app "$miniAppId" is unavailable',
                style: textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (reason case final String detail) ...[
                SizedBox(height: spacing.sm),
                Text(
                  detail,
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
