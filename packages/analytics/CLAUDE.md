# analytics

Vendor-agnostic analytics platform service. Provides default implementations
of the `AnalyticsTracker` contract declared in `mini_app_sdk`, so the shell
can compose one or more concrete trackers behind a single facade.

## Purpose

- Offer a dev-friendly logging tracker that prints events via `AppLogger`.
- Offer a fan-out tracker that relays every call to a list of underlying
  trackers — so production can combine Firebase + Mixpanel + PostHog without
  mini-apps noticing.
- Ship an in-memory tracker that application and mini-app tests can use to
  assert analytics behaviour without reaching for mocks.

## Rules

- Never depend on a vendor SDK directly (`firebase_analytics`, `mixpanel`,
  `posthog`, `amplitude`, etc.). Each vendor integration MUST live in its
  own adapter package (e.g. `analytics_firebase`, `analytics_mixpanel`) and
  be composed at the shell layer.
- No Flutter widgets, no navigation, no storage — this package is pure
  orchestration over the interface from `mini_app_sdk`.
- Fan-out is best-effort: a throwing tracker must not prevent the others
  from receiving the event. Errors are swallowed after being logged.
- Event names follow `<domain>.<action>` in `snake_case`, e.g.
  `demo.button.tapped`, `checkout.order.submitted`. Keep them stable across
  releases — they become analytics schema.

## Roadmap

Future vendor adapters will live as sibling packages and implement
`AnalyticsTracker` directly. They are composed via `FanoutAnalyticsTracker`
at the shell's composition root — never imported by mini-apps.

## Usage

```dart
final tracker = FanoutAnalyticsTracker([
  LoggingAnalyticsTracker(), // always on in debug
  // FirebaseAnalyticsTracker(...), PostHogAnalyticsTracker(...) in prod
]);

tracker.track('demo.button.tapped', props: {'variant': 'primary'});
tracker.setUserProperty('tier', 'gold');
await tracker.flush();
```

## Structure

```
lib/
├── analytics.dart                      // barrel
└── src/
    ├── logging_analytics_tracker.dart
    ├── fanout_analytics_tracker.dart
    └── in_memory_analytics_tracker.dart
test/
├── logging_analytics_tracker_test.dart
├── fanout_analytics_tracker_test.dart
└── in_memory_analytics_tracker_test.dart
```
