import 'package:flutter/material.dart';

import 'package:shared_ui/shared_ui.dart';

/// Card-style list tile used on the demo home screen.
///
/// Kept local to this mini-app: if a second mini-app ever needs the same
/// visual, the tile should graduate to `shared_ui` as a deliberate promotion.
class DemoActionTile extends StatelessWidget {
  /// Creates a demo action tile.
  const DemoActionTile({
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  /// Primary label rendered in the card.
  final String title;

  /// Secondary explanatory text.
  final String subtitle;

  /// Invoked when the tile is tapped.
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
      label: title,
      hint: subtitle,
      child: Padding(
        padding: EdgeInsets.only(bottom: spacing.md),
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: textTheme.titleMedium?.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        SizedBox(height: spacing.xs),
                        Text(
                          subtitle,
                          style: textTheme.bodySmall?.copyWith(
                            color: colors.textSubtle,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: spacing.sm),
                  Icon(Icons.chevron_right, color: colors.textSubtle),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
