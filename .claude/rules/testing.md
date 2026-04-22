---
paths:
  - "**/test/**/*.dart"
  - "**/*_test.dart"
  - "**/integration_test/**/*.dart"
---

# Testing Conventions

These rules apply to all test files.

## File & Test Naming

- Test files mirror source: `lib/src/visibility_evaluator.dart` → `test/visibility_evaluator_test.dart`
- Test descriptions use active voice: `test('returns fallback when key is missing', ...)` not `test('test missing', ...)`
- Group related tests: one `group()` per class/function under test

## Structure

```dart
void main() {
  group('Money.format', () {
    test('formats USD with 2 decimals', () {
      expect(Money.usd(9.99).format(), '9.99 \$');
    });

    test('formats UZS with 0 decimals', () {
      expect(Money.uzs(12500).format(), '12 500 UZS');
    });

    group('when symbol is suppressed', () {
      test('prints the numeric amount only', () {
        expect(Money.usd(1.5).format(symbol: false), '1.50');
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
class MockNetworkGateway extends Mock implements NetworkGateway {}

void main() {
  setUpAll(() {
    registerFallbackValue(
      const CheckoutRequest(
        amount: Money.usd(0),
        items: [],
      ),
    );
  });

  // tests...
}
```

## Test doubles over mocks

Every platform service package ships an `InMemory*` implementation of its
abstract interface (`InMemorySecureStorage`, `InMemoryPaymentGateway`,
`InMemoryAnalyticsTracker`, …). Prefer these over `mocktail` when available:
they enforce behavioral contracts and survive interface evolution.

## Widget Tests

- Every screen needs a smoke test that verifies it renders without crashing with default providers
- Use `ProviderScope(overrides: [...])` to inject fake providers — or swap the `MiniAppContext` for a fake
- Use `pumpAndSettle()` only when you have animations; prefer explicit `pump()` with duration

## Golden Tests (shared_ui only)

- Use `alchemist` for cross-platform goldens
- Every public widget has goldens for: light theme, dark theme, at least one "edge case" (long text, loading state, error state)
- Update goldens ONLY when changes are intentional: `flutter test --update-goldens`
- Goldens go in `test/goldens/` — commit them to git

## Integration Tests

- Live in `integration_test/` at each app root, not in `test/`
- Cover critical flows only: launcher → mini-app entry, sign-in, payment checkout, deep-link dispatch
- Use realistic test data, not lorem ipsum
- Run against in-memory platform service implementations, not production backends

## What NOT to Test

- Generated code (`*.g.dart`, `*.freezed.dart`)
- Third-party packages
- Simple getters/setters with no logic
- Private implementation details (test the public API instead)

## Coverage

- Target 80%+ line coverage in `core`, `shared_models`, and every platform service package
- Target 60%+ in mini-apps and the shell (UI-heavy code is harder to cover meaningfully)
- Do not game coverage — a test that imports a file without asserting anything is worse than no test
