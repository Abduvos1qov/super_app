import 'package:alchemist/alchemist.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_ui/shared_ui.dart';

void main() {
  group('PrimaryButton goldens', () {
    goldenTest(
      'renders in light theme',
      fileName: 'primary_button_light',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'default',
            child: _frame(
              AppTheme.light(),
              PrimaryButton(label: 'Request ride', onPressed: () {}),
            ),
          ),
          GoldenTestScenario(
            name: 'loading',
            child: _frame(
              AppTheme.light(),
              PrimaryButton(
                label: 'Request ride',
                isLoading: true,
                onPressed: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'destructive',
            child: _frame(
              AppTheme.light(),
              PrimaryButton.destructive(
                label: 'Cancel trip',
                onPressed: () {},
              ),
            ),
          ),
          GoldenTestScenario(
            name: 'disabled',
            child: _frame(
              AppTheme.light(),
              const PrimaryButton(label: 'Request ride', onPressed: null),
            ),
          ),
        ],
      ),
    );

    goldenTest(
      'renders in dark theme',
      fileName: 'primary_button_dark',
      builder: () => GoldenTestGroup(
        children: [
          GoldenTestScenario(
            name: 'default',
            child: _frame(
              AppTheme.dark(),
              PrimaryButton(label: 'Request ride', onPressed: () {}),
            ),
          ),
          GoldenTestScenario(
            name: 'destructive',
            child: _frame(
              AppTheme.dark(),
              PrimaryButton.destructive(
                label: 'Cancel trip',
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
    );
  });
}

Widget _frame(ThemeData theme, Widget child) => Theme(
      data: theme,
      child: ColoredBox(
        color: theme.colorScheme.surface,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SizedBox(width: 280, child: child),
        ),
      ),
    );
