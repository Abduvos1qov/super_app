# permissions

Unified runtime permissions broker for the super-app shell. Wraps the
`permission_handler` Flutter plugin and exposes the `PermissionBroker`
interface defined in `mini_app_sdk`.

## Purpose

One broker governs every OS permission prompt in the super-app. The shell
requests and the user grants; once granted, every mini-app inherits that
grant via the `MiniAppContext`. A mini-app can never reach the camera
behind another mini-app's grant — all access funnels through the shell.

## MiniAppPermission mapping

| MiniAppPermission      | plugin permission          |
|------------------------|----------------------------|
| `location`             | `Permission.location`      |
| `locationBackground`   | `Permission.locationAlways`|
| `camera`               | `Permission.camera`        |
| `microphone`           | `Permission.microphone`    |
| `contacts`             | `Permission.contacts`      |
| `photos`               | `Permission.photos`        |
| `storage`              | `Permission.storage`       |
| `notifications`        | `Permission.notification`  |
| `calendar`             | `Permission.calendarFullAccess` |
| `bluetooth`            | `Permission.bluetooth`     |
| `payments`             | *(app-level — not OS)*     |
| `biometrics`           | *(local_auth — not OS)*    |

`payments` and `biometrics` are not resolved by the OS; the broker reports
them as `PermissionStatus.notDetermined`. Callers are expected to route
these capabilities through their dedicated services.

Plugin `limited` and `provisional` statuses collapse to
`PermissionStatus.granted` — the contract only distinguishes "capability
available or not", not the partial-access sub-states.

## Rationale flow

`request` runs this exact sequence:

1. `check` the current status.
2. If `granted` or `restricted`, return immediately.
3. If `permanentlyDenied`, delegate to `PermissionRationalePresenter.
   showPermanentlyDeniedRationale` (typically "Open Settings"). The OS
   prompt no longer appears, so we never call `request` in this state.
4. If `denied` and a presenter is wired, call
   `showRationaleForRequest`. If the user declines, return `denied`
   without disturbing the OS.
5. Otherwise invoke the plugin's native `request` and map the result.

The presenter lives in the shell (go_router / Riverpod) so this package
stays free of navigation coupling.

## Shell wiring

```dart
final presenter = RiverpodRationalePresenter(ref);
final broker = DefaultPermissionBroker(rationalePresenter: presenter);
// Expose via the mini-app context's PermissionBroker slot.
```

## Testing

- Use `InMemoryPermissionBroker` for any code that consumes
  `PermissionBroker`. It records every call and round-trips configured
  statuses.
- `DefaultPermissionBroker` accepts `statusReader` and `statusRequester`
  hooks for unit tests — never mock `permission_handler`'s platform
  channels.
- Real plugin behaviour is covered by shell integration tests, not here.

## Rules

- Only the shell depends on this package. Mini-apps depend on the
  `PermissionBroker` abstraction from `mini_app_sdk`.
- Do not leak plugin types (`ph.Permission`, `ph.PermissionStatus`)
  across the package boundary — translate at the seam.
- Never throw from `check` / `request`; surface unsupported permissions
  as `PermissionStatus.notDetermined`.
