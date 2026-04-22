import 'package:flutter/material.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:shared_ui/shared_ui.dart';
import 'package:wallet_mini_app/src/manifest.dart';
import 'package:wallet_mini_app/src/presentation/wallet_home_screen.dart';

/// Wallet / payments mini-app.
class WalletMiniApp extends MiniApp {
  /// Creates a const instance.
  const WalletMiniApp();

  @override
  MiniAppManifest get manifest => walletMiniAppManifest;

  @override
  List<MiniAppRoute> routes(MiniAppContext context) => <MiniAppRoute>[
        MiniAppRoute(
          path: '/',
          name: 'wallet-home',
          builder: (_, __) => WalletHomeScreen(miniAppContext: context),
        ),
      ];

  @override
  Widget buildLauncherTile(
    BuildContext context,
    MiniAppContext miniAppContext,
  ) {
    return _WalletLauncherTile(
      onTap: () => miniAppContext.navigation.openMiniApp(manifest.id),
    );
  }
}

class _WalletLauncherTile extends StatelessWidget {
  const _WalletLauncherTile({required this.onTap});

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
      label: 'Open Wallet mini-app',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadii.defaults.md),
        child: Padding(
          padding: EdgeInsets.all(spacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.account_balance_wallet,
                size: 48,
                color: Color(0xFF7ED321),
              ),
              SizedBox(height: spacing.sm),
              Text(
                'Wallet',
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
