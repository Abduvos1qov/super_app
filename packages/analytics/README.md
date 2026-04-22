# analytics

Vendor-agnostic analytics tracker for the super-app. Provides three
implementations of `AnalyticsTracker` from `mini_app_sdk`:

- `LoggingAnalyticsTracker` — logs events through `AppLogger` for development.
- `FanoutAnalyticsTracker` — relays calls to many trackers; best-effort on
  failure so one misbehaving vendor cannot break the pipeline.
- `InMemoryAnalyticsTracker` — records events in memory for tests.

Vendor SDKs (Firebase, Mixpanel, PostHog, Amplitude) never live in this
package. Each vendor belongs in its own adapter package and is composed at
the shell via `FanoutAnalyticsTracker`.

## Install

Add to your `pubspec.yaml` (workspace-resolved):

```yaml
dependencies:
  analytics: any
```

## Usage

```dart
import 'package:analytics/analytics.dart';

final tracker = FanoutAnalyticsTracker([
  LoggingAnalyticsTracker(),
]);

tracker.track('demo.button.tapped', props: {'variant': 'primary'});
tracker.setUserProperty('tier', 'gold');
await tracker.flush();
```

Event names use the `<domain>.<action>` convention, e.g.
`checkout.order.submitted`.
