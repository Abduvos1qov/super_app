import 'package:flutter/material.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:shared_ui/shared_ui.dart';

/// Home screen for the wallet mini-app.
class WalletHomeScreen extends StatelessWidget {
  /// Creates the wallet home screen.
  const WalletHomeScreen({required this.miniAppContext, super.key});

  /// Mini-app context provided by the shell.
  final MiniAppContext miniAppContext;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppColors>() ?? AppColors.light();
    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Wallet')),
      body: ListView(
        padding: EdgeInsets.all(spacing.md),
        children: [
          _BalanceCard(
            colors: colors,
            spacing: spacing,
            textTheme: textTheme,
          ),
          SizedBox(height: spacing.lg),
          Text(
            'Quick actions',
            style: textTheme.titleMedium?.copyWith(color: colors.textPrimary),
          ),
          SizedBox(height: spacing.md),
          Row(
            children: [
              _WalletAction(
                label: 'Send',
                icon: Icons.north_east,
                onTap: () => miniAppContext.analytics.track(
                  'wallet.action.tapped',
                  props: const <String, Object?>{'action': 'send'},
                ),
              ),
              SizedBox(width: spacing.md),
              _WalletAction(
                label: 'Receive',
                icon: Icons.south_west,
                onTap: () => miniAppContext.analytics.track(
                  'wallet.action.tapped',
                  props: const <String, Object?>{'action': 'receive'},
                ),
              ),
              SizedBox(width: spacing.md),
              _WalletAction(
                label: 'Top up',
                icon: Icons.add_card,
                onTap: () => miniAppContext.analytics.track(
                  'wallet.action.tapped',
                  props: const <String, Object?>{'action': 'topup'},
                ),
              ),
            ],
          ),
          SizedBox(height: spacing.lg),
          Text(
            'Recent activity',
            style: textTheme.titleMedium?.copyWith(color: colors.textPrimary),
          ),
          SizedBox(height: spacing.sm),
          const _ActivityRow(
            title: 'Coffee shop',
            amount: r'-$4.50',
            icon: Icons.coffee,
          ),
          const _ActivityRow(
            title: 'Salary',
            amount: r'+$2,400.00',
            icon: Icons.payments,
          ),
          const _ActivityRow(
            title: 'Grocery',
            amount: r'-$62.30',
            icon: Icons.shopping_cart,
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({
    required this.colors,
    required this.spacing,
    required this.textTheme,
  });

  final AppColors colors;
  final AppSpacing spacing;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(spacing.lg),
      decoration: BoxDecoration(
        color: const Color(0xFF7ED321),
        borderRadius: BorderRadius.circular(AppRadii.defaults.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Available balance',
            style: textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
          SizedBox(height: spacing.sm),
          Text(
            r'$1,234.56',
            style: textTheme.headlineMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _WalletAction extends StatelessWidget {
  const _WalletAction({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppColors>() ?? AppColors.light();
    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;

    return Expanded(
      child: Semantics(
        button: true,
        label: label,
        child: Material(
          color: colors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppRadii.defaults.md),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppRadii.defaults.md),
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: spacing.md),
              child: Column(
                children: [
                  Icon(icon, color: const Color(0xFF7ED321)),
                  SizedBox(height: spacing.xs),
                  Text(
                    label,
                    style: textTheme.labelMedium?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.title,
    required this.amount,
    required this.icon,
  });

  final String title;
  final String amount;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppColors>() ?? AppColors.light();
    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: spacing.sm),
      child: Row(
        children: [
          Icon(icon, color: colors.textSubtle),
          SizedBox(width: spacing.md),
          Expanded(
            child: Text(
              title,
              style: textTheme.bodyLarge?.copyWith(color: colors.textPrimary),
            ),
          ),
          Text(
            amount,
            style: textTheme.bodyLarge?.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
