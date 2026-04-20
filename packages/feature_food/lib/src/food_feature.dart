import 'package:flutter/widgets.dart';

import 'food_home_screen.dart';

class FoodFeature {
  const FoodFeature._();

  static const String route = '/food';
  static const String label = 'Food';

  static Widget buildEntry() => const FoodHomeScreen();
}
