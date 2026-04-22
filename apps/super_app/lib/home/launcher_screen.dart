import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

class LauncherScreen extends StatelessWidget {
  const LauncherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final colors = Theme.of(context).extension<AppColors>() ?? AppColors.light();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Super App')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.apps, size: 72, color: colors.brandPrimary),
              SizedBox(height: spacing.md),
              Text('No mini-apps installed yet', style: textTheme.titleLarge),
              SizedBox(height: spacing.sm),
              Text(
                'Mini-apps will appear here once the platform registry is wired up.',
                style: textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
