import 'package:flutter/widgets.dart';

import 'taxi_home_screen.dart';

/// Entry point the super app uses to mount this module. Routing, icon, and
/// label live here so the launcher doesn't need to know the internals.
class TaxiFeature {
  const TaxiFeature._();

  static const String route = '/taxi';
  static const String label = 'Taxi';

  static Widget buildEntry() => const TaxiHomeScreen();
}
