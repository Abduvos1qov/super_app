import 'package:flutter/widgets.dart';

import 'driver_home_screen.dart';

/// Entry point the super app uses to mount this module. Routing, icon, and
/// label live here so the launcher doesn't need to know the internals.
class DriverFeature {
  const DriverFeature._();

  static const String route = '/driver';
  static const String label = 'Driver';

  static Widget buildEntry() => const DriverHomeScreen();
}
