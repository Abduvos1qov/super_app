import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:shared_ui/shared_ui.dart';

import 'package:super_app/shell/launcher_screen.dart';

/// Root scaffold for the super-app shell.
///
/// Hosts the bottom navigation (Home / Wallet / Inbox / Profile) and swaps
/// between the four top-level tabs. Only the Home tab is wired up today;
/// the rest render a placeholder so the nav chrome is representative without
/// blocking on features that live in future mini-apps.
class ShellScaffold extends ConsumerStatefulWidget {
  /// Creates the shell scaffold.
  const ShellScaffold({super.key});

  @override
  ConsumerState<ShellScaffold> createState() => _ShellScaffoldState();
}

class _ShellScaffoldState extends ConsumerState<ShellScaffold> {
  int _index = 0;

  static const _tabs = <_ShellTab>[
    _ShellTab(icon: Icons.home_outlined, selected: Icons.home, label: 'Home'),
    _ShellTab(
      icon: Icons.account_balance_wallet_outlined,
      selected: Icons.account_balance_wallet,
      label: 'Wallet',
    ),
    _ShellTab(
      icon: Icons.notifications_outlined,
      selected: Icons.notifications,
      label: 'Inbox',
    ),
    _ShellTab(
      icon: Icons.person_outline,
      selected: Icons.person,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_tabs[_index].label)),
      body: IndexedStack(
        index: _index,
        children: const <Widget>[
          LauncherScreen(),
          _ComingSoonView(label: 'Wallet'),
          _ComingSoonView(label: 'Inbox'),
          _ComingSoonView(label: 'Profile'),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        destinations: <Widget>[
          for (final tab in _tabs)
            NavigationDestination(
              icon: Icon(tab.icon),
              selectedIcon: Icon(tab.selected),
              label: tab.label,
            ),
        ],
      ),
    );
  }
}

class _ShellTab {
  const _ShellTab({
    required this.icon,
    required this.selected,
    required this.label,
  });

  final IconData icon;
  final IconData selected;
  final String label;
}

class _ComingSoonView extends StatelessWidget {
  const _ComingSoonView({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final spacing =
        Theme.of(context).extension<AppSpacing>() ?? const AppSpacing();
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(spacing.lg),
        child: Text(
          '$label coming soon',
          style: textTheme.titleMedium,
        ),
      ),
    );
  }
}
