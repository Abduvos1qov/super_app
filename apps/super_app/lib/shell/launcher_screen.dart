import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:shared_ui/shared_ui.dart';

import 'package:super_app/providers/mini_app_registry_provider.dart';
import 'package:super_app/providers/platform_providers.dart';

/// Home tab: renders a tile for every currently-visible mini-app.
///
/// Each tile is built by the owning mini-app via `buildLauncherTile`, so the
/// shell never hard-codes icons or labels. The context passed to the tile is
/// produced by [miniAppContextFactoryProvider] and carries per-mini-app scope
/// (storage, navigation).
class LauncherScreen extends ConsumerWidget {
  /// Creates the launcher screen.
  const LauncherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visibleMiniApps = ref.watch(visibleMiniAppsProvider);
    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final colors =
        Theme.of(context).extension<AppColors>() ?? AppColors.light();
    final textTheme = Theme.of(context).textTheme;

    if (visibleMiniApps.isEmpty) {
      return _LauncherEmpty(
        spacing: spacing,
        colors: colors,
        textTheme: textTheme,
      );
    }

    return Padding(
      padding: EdgeInsets.all(spacing.md),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 140,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
        ),
        itemCount: visibleMiniApps.length,
        itemBuilder: (_, index) => _LauncherTileSlot(
          miniApp: visibleMiniApps[index],
        ),
      ),
    );
  }
}

/// Renders a single mini-app's launcher tile, resolving its [MiniAppContext]
/// from the registry-backed factory.
class _LauncherTileSlot extends ConsumerWidget {
  const _LauncherTileSlot({required this.miniApp});

  final MiniApp miniApp;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final factory = ref.watch(miniAppContextFactoryProvider);
    final router = GoRouter.of(context);
    final miniAppContext = factory(miniApp.manifest.id, router: router);
    return miniApp.buildLauncherTile(context, miniAppContext);
  }
}

class _LauncherEmpty extends StatelessWidget {
  const _LauncherEmpty({
    required this.spacing,
    required this.colors,
    required this.textTheme,
  });

  final AppSpacing spacing;
  final AppColors colors;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.apps, size: 72, color: colors.brandPrimary),
            SizedBox(height: spacing.md),
            Text('No mini-apps available', style: textTheme.titleLarge),
            SizedBox(height: spacing.sm),
            Text(
              'Mini-apps will appear here once the registry is populated.',
              style: textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
