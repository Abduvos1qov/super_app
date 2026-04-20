import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_ui/shared_ui.dart';

/// Demo driver dashboard — online toggle + mock earnings. Real ride-offer
/// card and navigation hand-off land in follow-ups.
class DriverHomeScreen extends ConsumerStatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  ConsumerState<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends ConsumerState<DriverHomeScreen> {
  bool _online = false;

  static const _demoDriver = User.driver(
    id: 'demo-driver',
    phone: '+998900000001',
    displayName: 'Demo Driver',
    licenseNumber: 'AA1234BB',
    rating: 4.9,
  );

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final colors = Theme.of(context).extension<AppColors>() ?? AppColors.light();
    final textTheme = Theme.of(context).textTheme;

    final todayEarnings = Money.uzs(245000);
    final nameLine = switch (_demoDriver) {
      Driver(:final displayName, :final rating) => '$displayName  ·  ★ $rating',
      Rider(:final displayName) => displayName,
      Admin(:final email) => email,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Driver')),
      body: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(nameLine, style: textTheme.headlineSmall),
            SizedBox(height: spacing.lg),
            Container(
              padding: EdgeInsets.all(spacing.lg),
              decoration: BoxDecoration(
                color: colors.surfaceElevated,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.textSubtle.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.payments_outlined, color: colors.brandPrimary, size: 32),
                  SizedBox(width: spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Today's earnings", style: textTheme.labelLarge),
                        Text(todayEarnings.formatUzs(), style: textTheme.titleLarge),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: spacing.lg),
            SwitchListTile(
              value: _online,
              onChanged: (value) => setState(() => _online = value),
              title: Text(_online ? 'Online — receiving rides' : 'Offline'),
              subtitle: Text(
                _online
                    ? 'Your location is being shared with dispatch.'
                    : 'Toggle to start accepting ride offers.',
              ),
              activeColor: colors.brandPrimary,
            ),
            const Spacer(),
            PrimaryButton(
              label: _online ? 'Go offline' : 'Go online',
              icon: _online ? Icons.pause_circle_outline : Icons.play_circle_outline,
              onPressed: () => setState(() => _online = !_online),
            ),
          ],
        ),
      ),
    );
  }
}
