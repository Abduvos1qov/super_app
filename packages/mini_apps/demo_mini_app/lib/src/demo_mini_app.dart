import 'package:demo_mini_app/src/manifest.dart';
import 'package:demo_mini_app/src/presentation/demo_home_screen.dart';
import 'package:flutter/material.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:shared_ui/shared_ui.dart';

/// Reference implementation of [MiniApp].
///
/// Registered by the shell during bootstrap to validate that the
/// `mini_app_sdk` contract is honoured end-to-end. Because this class is
/// stateless at the instance level, a single `const DemoMiniApp()` can be
/// shared across the whole process.
class DemoMiniApp extends MiniApp {
  /// Creates a const instance. The shell keeps a single shared instance.
  const DemoMiniApp();

  @override
  MiniAppManifest get manifest => demoMiniAppManifest;

  @override
  List<MiniAppRoute> routes(MiniAppContext context) => <MiniAppRoute>[
        MiniAppRoute(
          path: '/',
          name: 'demo-home',
          builder: (_, __) => DemoHomeScreen(miniAppContext: context),
        ),
      ];

  @override
  Widget buildLauncherTile(
    BuildContext context,
    MiniAppContext miniAppContext,
  ) {
    return _DemoLauncherTile(
      onTap: () => miniAppContext.navigation.openMiniApp(manifest.id),
    );
  }
}

/// Minimal launcher tile shown on the super-app home screen.
///
/// Kept private and deliberately small; any richer launcher chrome should
/// live in `shared_ui` so every mini-app picks it up for free.
class _DemoLauncherTile extends StatelessWidget {
  const _DemoLauncherTile({required this.onTap});

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
      label: 'Open Demo mini-app',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.defaults.md),
        child: Padding(
          padding: EdgeInsets.all(spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.extension,
                size: 48,
                color: colors.brandPrimary,
              ),
              SizedBox(height: spacing.sm),
              Text(
                'Demo',
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
