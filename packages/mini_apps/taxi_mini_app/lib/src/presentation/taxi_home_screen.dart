import 'package:flutter/material.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:shared_ui/shared_ui.dart';

/// Home screen for the taxi mini-app.
class TaxiHomeScreen extends StatelessWidget {
  /// Creates the taxi home screen.
  const TaxiHomeScreen({required this.miniAppContext, super.key});

  /// Mini-app context provided by the shell.
  final MiniAppContext miniAppContext;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppColors>() ?? AppColors.light();
    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;

    const rideTypes = <_RideType>[
      _RideType(label: 'Economy', icon: Icons.directions_car, eta: '3 min'),
      _RideType(label: 'Comfort', icon: Icons.car_rental, eta: '5 min'),
      _RideType(
        label: 'Premium',
        icon: Icons.directions_car_filled,
        eta: '8 min',
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Taxi')),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: ColoredBox(
              color: const Color(0xFFE8F4F8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map,
                      size: 96,
                      color: colors.textSubtle,
                    ),
                    SizedBox(height: spacing.sm),
                    Text(
                      'Map placeholder',
                      style: textTheme.bodyMedium?.copyWith(
                        color: colors.textSubtle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Padding(
              padding: EdgeInsets.all(spacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _AddressField(
                    icon: Icons.trip_origin,
                    label: 'From',
                    value: 'Current location',
                    colors: colors,
                    spacing: spacing,
                    textTheme: textTheme,
                  ),
                  SizedBox(height: spacing.sm),
                  _AddressField(
                    icon: Icons.place,
                    label: 'To',
                    value: 'Choose destination',
                    colors: colors,
                    spacing: spacing,
                    textTheme: textTheme,
                  ),
                  SizedBox(height: spacing.lg),
                  Text(
                    'Ride type',
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                  SizedBox(height: spacing.sm),
                  Expanded(
                    child: ListView.separated(
                      itemCount: rideTypes.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(height: spacing.sm),
                      itemBuilder: (_, index) => _RideTypeCard(
                        type: rideTypes[index],
                        onTap: () => miniAppContext.analytics.track(
                          'taxi.ride_type.tapped',
                          props: <String, Object?>{
                            'type': rideTypes[index].label,
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RideType {
  const _RideType({
    required this.label,
    required this.icon,
    required this.eta,
  });

  final String label;
  final IconData icon;
  final String eta;
}

class _AddressField extends StatelessWidget {
  const _AddressField({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    required this.spacing,
    required this.textTheme,
  });

  final IconData icon;
  final String label;
  final String value;
  final AppColors colors;
  final AppSpacing spacing;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(spacing.md),
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.defaults.md),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFF8C51C)),
          SizedBox(width: spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.textSubtle,
                  ),
                ),
                Text(
                  value,
                  style: textTheme.bodyLarge?.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RideTypeCard extends StatelessWidget {
  const _RideTypeCard({required this.type, required this.onTap});

  final _RideType type;
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
      label: type.label,
      child: Material(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.defaults.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.defaults.md),
          child: Padding(
            padding: EdgeInsets.all(spacing.md),
            child: Row(
              children: [
                Icon(type.icon, size: 32, color: const Color(0xFFF8C51C)),
                SizedBox(width: spacing.md),
                Expanded(
                  child: Text(
                    type.label,
                    style: textTheme.titleMedium?.copyWith(
                      color: colors.textPrimary,
                    ),
                  ),
                ),
                Text(
                  type.eta,
                  style: textTheme.bodyMedium?.copyWith(
                    color: colors.textSubtle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
