import 'package:core/core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_ui/shared_ui.dart';

/// Demo screen wiring `core` (fare), `shared_models` (User), and
/// `shared_ui` (theme + button). Real pickup/destination UI lands next.
class TaxiHomeScreen extends ConsumerWidget {
  const TaxiHomeScreen({super.key});

  static const _demoRider = User.rider(
    id: 'demo',
    phone: '+998900000000',
    displayName: 'Demo Rider',
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;

    final fare = calculateFare(
      distanceKm: 4,
      minutes: 10,
      surgeMultiplier: 1.2,
      config: FareConfig.uzsDefault,
    );

    final greeting = switch (_demoRider) {
      Rider(:final displayName) => 'Hello, $displayName',
      Driver(:final displayName) => 'Driver $displayName',
      Admin(:final email) => 'Admin $email',
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Taxi')),
      body: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(greeting, style: textTheme.headlineMedium),
            SizedBox(height: spacing.md),
            Text('Estimated fare: ${fare.formatUzs()}', style: textTheme.titleLarge),
            SizedBox(height: spacing.sm),
            Text(
              'Pickup and destination UI goes here.',
              style: textTheme.bodyMedium,
            ),
            const Spacer(),
            PrimaryButton(
              label: 'Request ride',
              icon: Icons.local_taxi_outlined,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
