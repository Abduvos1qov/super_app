import 'package:flutter/material.dart';
import 'package:food_mini_app/src/manifest.dart';
import 'package:food_mini_app/src/presentation/food_home_screen.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:shared_ui/shared_ui.dart';

/// Food ordering mini-app.
class FoodMiniApp extends MiniApp {
  /// Creates a const instance. The shell keeps a single shared instance.
  const FoodMiniApp();

  @override
  MiniAppManifest get manifest => foodMiniAppManifest;

  @override
  List<MiniAppRoute> routes(MiniAppContext context) => <MiniAppRoute>[
        MiniAppRoute(
          path: '/',
          name: 'food-home',
          builder: (_, __) => FoodHomeScreen(miniAppContext: context),
        ),
      ];

  @override
  Widget buildLauncherTile(
    BuildContext context,
    MiniAppContext miniAppContext,
  ) {
    return _FoodLauncherTile(
      onTap: () => miniAppContext.navigation.openMiniApp(manifest.id),
    );
  }
}

class _FoodLauncherTile extends StatelessWidget {
  const _FoodLauncherTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppColors>() ?? AppColors.light();
    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: 'Open Food mini-app',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.defaults.md),
        child: Padding(
          padding: EdgeInsets.all(spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.restaurant,
                size: 48,
                color: Color(0xFFF5A623),
              ),
              SizedBox(height: spacing.sm),
              Text(
                'Food',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: textTheme.labelLarge?.copyWith(
                  color: colors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
