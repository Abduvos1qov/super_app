import 'package:flutter/widgets.dart';

import 'delivery_home_screen.dart';

class DeliveryFeature {
  const DeliveryFeature._();

  static const String route = '/delivery';
  static const String label = 'Delivery';

  static Widget buildEntry() => const DeliveryHomeScreen();
}
