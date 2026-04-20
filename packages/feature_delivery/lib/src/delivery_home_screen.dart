import 'package:flutter/material.dart';
import 'package:shared_ui/shared_ui.dart';

class DeliveryHomeScreen extends StatelessWidget {
  const DeliveryHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Delivery')),
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(spacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.delivery_dining, size: 64),
              SizedBox(height: spacing.md),
              Text('Coming soon', style: textTheme.headlineSmall),
              SizedBox(height: spacing.sm),
              Text(
                'Parcel pickup, live courier tracking, and proof-of-delivery land next.',
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
