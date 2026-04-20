# shared_ui Package

Design system. Flutter-only. Presentation layer. Zero I/O, zero business logic.

Also see the path-scoped rules in `.claude/rules/ui-rules.md` — they apply automatically when editing files in this directory.

## Purpose

Every pixel that appears in multiple apps is defined here. If a rider and a driver see the same button, that button lives here — exactly once.

## Contents

```
lib/
├── shared_ui.dart                // barrel
├── src/
│   ├── theme/
│   │   ├── app_theme.dart        // ThemeData for light + dark
│   │   ├── app_colors.dart       // semantic tokens, not raw colors
│   │   ├── app_typography.dart
│   │   ├── app_spacing.dart      // xs, sm, md, lg, xl, xxl
│   │   └── app_radii.dart
│   ├── buttons/
│   │   ├── primary_button.dart
│   │   ├── secondary_button.dart
│   │   └── icon_button.dart
│   ├── inputs/
│   │   ├── app_text_field.dart
│   │   ├── phone_field.dart
│   │   └── otp_field.dart
│   ├── feedback/
│   │   ├── loading_overlay.dart
│   │   ├── empty_state.dart
│   │   ├── error_view.dart
│   │   └── app_snackbar.dart
│   ├── layout/
│   │   ├── app_scaffold.dart
│   │   ├── app_card.dart
│   │   └── app_bottom_sheet.dart
│   └── icons/
│       └── app_icons.dart
├── example/                      // runnable showcase app
└── test/
    └── goldens/
```

## Theme Tokens

Semantic names, not visual names:

- ✅ `AppColors.brandPrimary`, `AppColors.surfaceElevated`, `AppColors.textSubtle`
- ❌ `AppColors.green500`, `AppColors.gray100`

This lets us rebrand without touching widgets.

## Typography

- All text styles live in `AppTypography`: `displayLarge`, `headlineMedium`, `titleSmall`, `bodyLarge`, `bodyMedium`, `labelSmall`, etc.
- Widgets use `Theme.of(context).textTheme.bodyMedium`, never inline `TextStyle(...)`.

## Example Rule for New Widgets

When adding a widget:

1. It must work in light **and** dark theme
2. It must render correctly at 1× and 3× text scale
3. It must have a Semantics label for screen readers
4. It must have a golden test for at least light + dark
5. It must have an entry in `example/lib/main.dart`
6. Its public API must have dartdoc comments
7. It must NOT import anything from `shared_services` or apps

## Example: PrimaryButton

```dart
/// The primary action button, used for the most important action on a screen.
///
/// Use at most one [PrimaryButton] per screen. For secondary actions, use
/// [SecondaryButton]. For destructive actions, use [PrimaryButton.destructive].
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    super.key,
  });

  const PrimaryButton.destructive({
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    super.key,
  }) : _variant = _Variant.destructive;

  // ...
}
```

Note: caller passes `isLoading`. The widget does NOT call anything to find out.

## Dependencies

- `flutter` (material + cupertino)
- `google_fonts`
- `flutter_svg`
- `cached_network_image`
- `core` (for formatters, types)

Dev dependencies:

- `alchemist` (golden tests)
- `flutter_test`

## What This Package Must Never Depend On

- ❌ `shared_services`
- ❌ `dio`, `http`, any network library
- ❌ `shared_preferences`, `flutter_secure_storage`
- ❌ `flutter_riverpod` — widgets here are framework-agnostic, apps wire them up
- ❌ Any `apps/*` package
