import 'package:flutter/material.dart';
import 'package:mini_app_sdk/mini_app_sdk.dart';
import 'package:shared_ui/shared_ui.dart';

/// Home screen for the food mini-app.
class FoodHomeScreen extends StatelessWidget {
  /// Creates the food home screen.
  const FoodHomeScreen({required this.miniAppContext, super.key});

  /// Mini-app context provided by the shell.
  final MiniAppContext miniAppContext;

  @override
  Widget build(BuildContext context) {
    final colors =
        Theme.of(context).extension<AppColors>() ?? AppColors.light();
    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;

    const categories = <_FoodCategory>[
      _FoodCategory(label: 'Pizza', icon: Icons.local_pizza),
      _FoodCategory(label: 'Burgers', icon: Icons.lunch_dining),
      _FoodCategory(label: 'Sushi', icon: Icons.set_meal),
      _FoodCategory(label: 'Desserts', icon: Icons.icecream),
      _FoodCategory(label: 'Coffee', icon: Icons.coffee),
      _FoodCategory(label: 'Salads', icon: Icons.eco),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Food')),
      body: ListView(
        padding: EdgeInsets.all(spacing.md),
        children: [
          Text(
            'Order from your favorite restaurants.',
            style: textTheme.bodyMedium?.copyWith(color: colors.textPrimary),
          ),
          SizedBox(height: spacing.lg),
          Text(
            'Categories',
            style: textTheme.titleMedium?.copyWith(color: colors.textPrimary),
          ),
          SizedBox(height: spacing.md),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 140,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
            ),
            itemCount: categories.length,
            itemBuilder: (_, index) => _FoodCategoryCard(
              category: categories[index],
              onTap: () => miniAppContext.analytics.track(
                'food.category.tapped',
                props: <String, Object?>{'label': categories[index].label},
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FoodCategory {
  const _FoodCategory({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _FoodCategoryCard extends StatelessWidget {
  const _FoodCategoryCard({required this.category, required this.onTap});

  final _FoodCategory category;
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
      label: category.label,
      child: Material(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppRadii.defaults.md),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadii.defaults.md),
          child: Padding(
            padding: EdgeInsets.all(spacing.md),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  category.icon,
                  size: 40,
                  color: const Color(0xFFF5A623),
                ),
                SizedBox(height: spacing.sm),
                Text(
                  category.label,
                  style: textTheme.labelLarge?.copyWith(
                    color: colors.textPrimary,
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
