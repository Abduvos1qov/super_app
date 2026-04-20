---
paths:
  - "**/test/**/*.dart"
  - "**/*_test.dart"
  - "**/integration_test/**/*.dart"
---

# Testing Conventions

These rules apply to all test files.

## File & Test Naming

- Test files mirror source: `lib/src/fare_calculator.dart` → `test/src/fare_calculator_test.dart`
- Test descriptions use active voice: `test('returns zero for zero distance', ...)` not `test('test zero', ...)`
- Group related tests: one `group()` per class/function under test

## Structure

```dart
void main() {
  group('FareCalculator', () {
    late FareCalculator sut; // system under test

    setUp(() {
      sut = FareCalculator();
    });

    test('returns base fare for minimum distance', () {
      final result = sut.calculate(distanceKm: 0.5);
      expect(result, equals(5000)); // 5000 UZS minimum
    });

    group('when distance exceeds 10km', () {
      test('applies long-distance discount', () {
        final result = sut.calculate(distanceKm: 15);
        expect(result, lessThan(15 * 2500));
      });
    });
  });
}
```

## Mocking with mocktail

- Use `mocktail` (not `mockito`) — no codegen, nicer API
- Create mocks per test group, not globally
- Register fallback values in `setUpAll()` for custom types

```dart
class MockApiClient extends Mock implements ApiClient {}

void main() {
  setUpAll(() {
    registerFallbackValue(const TripRequest.empty());
  });

  // tests...
}
```

## Widget Tests

- Every screen needs a smoke test that verifies it renders without crashing with default providers
- Use `ProviderScope(overrides: [...])` to inject fake providers
- Use `pumpAndSettle()` only when you have animations; prefer explicit `pump()` with duration

## Golden Tests (shared_ui only)

- Use `alchemist` for cross-platform goldens
- Every public widget has goldens for: light theme, dark theme, at least one "edge case" (long text, loading state, error state)
- Update goldens ONLY when changes are intentional: `flutter test --update-goldens`
- Goldens go in `test/goldens/` — commit them to git

## Integration Tests

- Live in `integration_test/` at each app root, not in `test/`
- Cover critical flows only: book-a-ride, accept-a-ride, login, payment
- Use realistic test data, not lorem ipsum
- Run against a local mock server, not production

## What NOT to Test

- Generated code (`*.g.dart`, `*.freezed.dart`)
- Third-party packages
- Simple getters/setters with no logic
- Private implementation details (test the public API instead)

## Coverage

- Target 80%+ line coverage in `core`, `shared_services`, `shared_models`
- Target 60%+ in apps (UI-heavy code is harder to cover meaningfully)
- Do not game coverage — a test that imports a file without asserting anything is worse than no test
