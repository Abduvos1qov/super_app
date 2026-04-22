import 'package:flutter/material.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:taxi_mini_app/src/manifest.dart';
import 'package:taxi_mini_app/src/presentation/taxi_home_screen.dart';

/// Taxi / ride-hailing mini-app.
class TaxiMiniApp extends MiniApp {
  /// Creates a const instance.
  const TaxiMiniApp();

  @override
  MiniAppManifest get manifest => taxiMiniAppManifest;

  @override
  List<MiniAppRoute> routes(MiniAppContext context) => <MiniAppRoute>[
        MiniAppRoute(
          path: '/',
          name: 'taxi-home',
          builder: (_, __) => TaxiHomeScreen(miniAppContext: context),
        ),
      ];

  @override
  Widget buildLauncherTile(
    BuildContext context,
    MiniAppContext miniAppContext,
  ) {
    return _TaxiLauncherTile(
      onTap: () => miniAppContext.navigation.openMiniApp(manifest.id),
    );
  }
}

class _TaxiLauncherTile extends StatelessWidget {
  const _TaxiLauncherTile({required this.onTap});

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
      label: 'Open Taxi mini-app',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.defaults.md),
        child: Padding(
          padding: EdgeInsets.all(spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_taxi,
                size: 48,
                color: Color(0xFFF8C51C),
              ),
              SizedBox(height: spacing.sm),
              Text(
                'Taxi',
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
