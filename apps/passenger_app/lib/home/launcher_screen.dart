import 'package:feature_delivery/feature_delivery.dart';
import 'package:feature_driver/feature_driver.dart';
import 'package:feature_food/feature_food.dart';
import 'package:feature_taxi/feature_taxi.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_ui/shared_ui.dart';

/// Super-app home. Each service registers a route + label + icon; the
/// launcher just lays them out as tappable cards.
class LauncherScreen extends StatelessWidget {
  const LauncherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final services = <_Service>[
      _Service(
        route: TaxiFeature.route,
        label: TaxiFeature.label,
        icon: Icons.local_taxi,
      ),
      _Service(
        route: FoodFeature.route,
        label: FoodFeature.label,
        icon: Icons.restaurant,
      ),
      _Service(
        route: DeliveryFeature.route,
        label: DeliveryFeature.label,
        icon: Icons.delivery_dining,
      ),
      _Service(
        route: DriverFeature.route,
        label: DriverFeature.label,
        icon: Icons.drive_eta,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('My Super App')),
      body: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: spacing.md,
          mainAxisSpacing: spacing.md,
          children: [
            for (final service in services)
              _ServiceCard(
                service: service,
                onTap: () => context.push(service.route),
              ),
          ],
        ),
      ),
    );
  }
}

class _Service {
  const _Service({required this.route, required this.label, required this.icon});

  final String route;
  final String label;
  final IconData icon;
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard({required this.service, required this.onTap});

  final _Service service;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>() ?? AppColors.light();
    final textTheme = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      label: service.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.textSubtle.withValues(alpha: 0.15)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(service.icon, size: 48, color: colors.brandPrimary),
              const SizedBox(height: 12),
              Text(service.label, style: textTheme.titleLarge),
            ],
          ),
        ),
      ),
    );
  }
}
