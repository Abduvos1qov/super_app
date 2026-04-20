import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';

enum _Variant { normal, destructive }

/// The primary action button, used for the most important action on a
/// screen. Use at most one [PrimaryButton] per screen. For secondary actions
/// use `SecondaryButton`; for destructive actions use
/// [PrimaryButton.destructive].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    super.key,
  }) : _variant = _Variant.normal;

  const PrimaryButton.destructive({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    super.key,
  }) : _variant = _Variant.destructive;

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final _Variant _variant;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColors>() ?? AppColors.light();
    final spacing = Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();

    final background = switch (_variant) {
      _Variant.normal => colors.brandPrimary,
      _Variant.destructive => colors.danger,
    };
    final foreground = colors.brandOnPrimary;
    final disabled = onPressed == null || isLoading;

    return Semantics(
      button: true,
      enabled: !disabled,
      label: label,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: background,
          foregroundColor: foreground,
          disabledBackgroundColor: background.withValues(alpha: 0.4),
          disabledForegroundColor: foreground.withValues(alpha: 0.8),
          minimumSize: const Size.fromHeight(52),
          padding: EdgeInsets.symmetric(horizontal: spacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadii.defaults.md),
          ),
          textStyle: Theme.of(context).textTheme.labelLarge,
        ),
        onPressed: disabled ? null : onPressed,
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation(foreground),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    SizedBox(width: spacing.sm),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}
