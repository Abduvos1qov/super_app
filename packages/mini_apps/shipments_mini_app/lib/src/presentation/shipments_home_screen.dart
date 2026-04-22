import 'package:flutter/material.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:shared_ui/shared_ui.dart';

/// Home screen for the shipments mini-app.
class ShipmentsHomeScreen extends StatelessWidget {
  /// Creates the shipments home screen.
  const ShipmentsHomeScreen({required this.miniAppContext, super.key});

  /// Mini-app context provided by the shell.
  final MiniAppContext miniAppContext;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppColors>() ?? AppColors.light();
    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;

    const shipments = <_Shipment>[
      _Shipment(
        trackingId: 'SH-2041',
        status: 'In transit',
        description: 'Small parcel · Tashkent → Samarkand',
        icon: Icons.local_shipping,
      ),
      _Shipment(
        trackingId: 'SH-2039',
        status: 'Out for delivery',
        description: 'Document · Same-day',
        icon: Icons.directions_bike,
      ),
      _Shipment(
        trackingId: 'SH-2033',
        status: 'Delivered',
        description: 'Box · Bukhara → Tashkent',
        icon: Icons.check_circle,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Shipments')),
      body: ListView(
        padding: EdgeInsets.all(spacing.md),
        children: [
          _NewShipmentCta(
            colors: colors,
            spacing: spacing,
            textTheme: textTheme,
            onTap: () => miniAppContext.analytics.track(
              'shipments.new_shipment.tapped',
            ),
          ),
          SizedBox(height: spacing.lg),
          Text(
            'Recent shipments',
            style: textTheme.titleMedium?.copyWith(color: colors.textPrimary),
          ),
          SizedBox(height: spacing.sm),
          ...shipments.map(
            (shipment) => _ShipmentCard(
              shipment: shipment,
              onTap: () => miniAppContext.analytics.track(
                'shipments.shipment.tapped',
                props: <String, Object?>{'tracking_id': shipment.trackingId},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Shipment {
  const _Shipment({
    required this.trackingId,
    required this.status,
    required this.description,
    required this.icon,
  });

  final String trackingId;
  final String status;
  final String description;
  final IconData icon;
}

class _NewShipmentCta extends StatelessWidget {
  const _NewShipmentCta({
    required this.colors,
    required this.spacing,
    required this.textTheme,
    required this.onTap,
  });

  final AppColors colors;
  final AppSpacing spacing;
  final TextTheme textTheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Create new shipment',
      child: Material(
        color: const Color(0xFF9013FE),
        borderRadius: BorderRadius.circular(AppRadii.defaults.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.defaults.md),
          child: Padding(
            padding: EdgeInsets.all(spacing.lg),
            child: Row(
              children: [
                const Icon(Icons.add_box, color: Colors.white, size: 32),
                SizedBox(width: spacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Send a parcel',
                        style: textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: spacing.xs),
                      Text(
                        'Same-day or scheduled',
                        style: textTheme.bodyMedium?.copyWith(
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Colors.white,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  const _ShipmentCard({required this.shipment, required this.onTap});

  final _Shipment shipment;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppColors>() ?? AppColors.light();
    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;

    return Padding(
      padding: EdgeInsets.only(bottom: spacing.sm),
      child: Semantics(
        button: true,
        label: '${shipment.trackingId} ${shipment.status}',
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
                  Icon(
                    shipment.icon,
                    color: const Color(0xFF9013FE),
                    size: 32,
                  ),
                  SizedBox(width: spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shipment.trackingId,
                          style: textTheme.titleMedium?.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        SizedBox(height: spacing.xs),
                        Text(
                          shipment.description,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.textSubtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: spacing.sm),
                  Text(
                    shipment.status,
                    style: textTheme.labelMedium?.copyWith(
                      color: const Color(0xFF9013FE),
                      fontWeight: FontWeight.w600,
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
