import 'package:decimal/decimal.dart';
import 'package:meta/meta.dart';

import '../money/money.dart';

/// Immutable pricing configuration. Values come from remote config at
/// runtime; tests pass fixed configs for determinism.
@immutable
class FareConfig {
  const FareConfig({
    required this.baseFare,
    required this.perKmFare,
    required this.perMinuteFare,
    required this.minimumFare,
  });

  /// Reasonable defaults for Tashkent, used in tests and local dev.
  static final FareConfig uzsDefault = FareConfig(
    baseFare: Money.uzs(5000),
    perKmFare: Money.uzs(2500),
    perMinuteFare: Money.uzs(500),
    minimumFare: Money.uzs(8000),
  );

  final Money baseFare;
  final Money perKmFare;
  final Money perMinuteFare;
  final Money minimumFare;
}

/// Calculates the fare for a given trip.
///
/// Formula: `base + (distanceKm × perKm) + (minutes × perMinute)` then
/// multiplied by [surgeMultiplier], and finally floored at
/// [FareConfig.minimumFare].
///
/// Pure. Deterministic. No I/O.
Money calculateFare({
  required double distanceKm,
  required int minutes,
  required double surgeMultiplier,
  required FareConfig config,
}) {
  if (distanceKm < 0) throw ArgumentError.value(distanceKm, 'distanceKm');
  if (minutes < 0) throw ArgumentError.value(minutes, 'minutes');
  if (surgeMultiplier <= 0) throw ArgumentError.value(surgeMultiplier, 'surgeMultiplier');

  final distance = config.perKmFare.scale(Decimal.parse(distanceKm.toString()));
  final time = config.perMinuteFare.scale(Decimal.fromInt(minutes));
  final subtotal = config.baseFare + distance + time;
  final surged = subtotal.scale(Decimal.parse(surgeMultiplier.toString()));
  return Money.max(surged, config.minimumFare);
}
