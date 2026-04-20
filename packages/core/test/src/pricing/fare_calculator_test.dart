import 'package:core/core.dart';
import 'package:test/test.dart';

void main() {
  group('calculateFare', () {
    final config = FareConfig.uzsDefault;

    test('returns minimum fare for a near-zero-distance trip', () {
      final fare = calculateFare(
        distanceKm: 0.1,
        minutes: 0,
        surgeMultiplier: 1.0,
        config: config,
      );
      expect(fare, equals(config.minimumFare));
    });

    test('computes subtotal from base + distance + time at surge 1x', () {
      // base 5000 + (4 × 2500) + (10 × 500) = 5000 + 10000 + 5000 = 20000
      final fare = calculateFare(
        distanceKm: 4,
        minutes: 10,
        surgeMultiplier: 1.0,
        config: config,
      );
      expect(fare, equals(Money.uzs(20000)));
    });

    test('applies surge multiplier', () {
      // Same trip as above × 2.0 = 40000
      final fare = calculateFare(
        distanceKm: 4,
        minutes: 10,
        surgeMultiplier: 2.0,
        config: config,
      );
      expect(fare, equals(Money.uzs(40000)));
    });

    test('formatted UZS uses thousands separator', () {
      expect(Money.uzs(12500).formatUzs(), equals('12 500 UZS'));
      expect(Money.uzs(1000000).formatUzs(), equals('1 000 000 UZS'));
    });

    test('rejects negative distance', () {
      expect(
        () => calculateFare(
          distanceKm: -1,
          minutes: 0,
          surgeMultiplier: 1.0,
          config: config,
        ),
        throwsArgumentError,
      );
    });

    test('rejects non-positive surge multiplier', () {
      expect(
        () => calculateFare(
          distanceKm: 1,
          minutes: 5,
          surgeMultiplier: 0,
          config: config,
        ),
        throwsArgumentError,
      );
    });
  });
}
