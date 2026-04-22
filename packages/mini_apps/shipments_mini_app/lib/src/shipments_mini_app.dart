import 'package:flutter/material.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:shipments_mini_app/src/manifest.dart';
import 'package:shipments_mini_app/src/presentation/shipments_home_screen.dart';

/// Shipments / parcel delivery mini-app.
class ShipmentsMiniApp extends MiniApp {
  /// Creates a const instance.
  const ShipmentsMiniApp();

  @override
  MiniAppManifest get manifest => shipmentsMiniAppManifest;

  @override
  List<MiniAppRoute> routes(MiniAppContext context) => <MiniAppRoute>[
        MiniAppRoute(
          path: '/',
          name: 'shipments-home',
          builder: (_, __) => ShipmentsHomeScreen(miniAppContext: context),
        ),
      ];

  @override
  Widget buildLauncherTile(
    BuildContext context,
    MiniAppContext miniAppContext,
  ) {
    return _ShipmentsLauncherTile(
      onTap: () => miniAppContext.navigation.openMiniApp(manifest.id),
    );
  }
}

class _ShipmentsLauncherTile extends StatelessWidget {
  const _ShipmentsLauncherTile({required this.onTap});

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
      label: 'Open Shipments mini-app',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.defaults.md),
        child: Padding(
          padding: EdgeInsets.all(spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_shipping,
                size: 40,
                color: Color(0xFF9013FE),
              ),
              SizedBox(height: spacing.sm),
              Text(
                'Shipments',
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
