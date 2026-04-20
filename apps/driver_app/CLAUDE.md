# Driver App

Flutter mobile app for drivers. Runs on iOS + Android.

## Scope

Features this app owns (and only this app):

- Driver authentication (phone + OTP, KYC-gated)
- Driver onboarding: document upload (license, vehicle registration, insurance)
- Online/offline status toggle
- Ride request incoming-notification with 15s timeout to accept/reject
- Navigation to pickup (external maps handoff: Yandex Maps / Google Maps)
- In-trip UI (rider details, fare counter, emergency button)
- End-of-trip summary and rating
- Daily/weekly earnings view with breakdown
- Payout requests and payout history
- Support chat

## Architecture

Same feature-first structure as rider_app. See ARCHITECTURE.md §4.

```
lib/features/
├── auth/
├── onboarding/           // KYC flow — unique to driver_app
├── home/                 // map + online toggle
├── ride_queue/           // incoming ride requests
├── ride_in_progress/
├── earnings/
├── documents/            // re-upload expired docs
└── support/
```

## Key Dependencies

Same core deps as rider_app, plus:

- `image_picker` + `image_cropper` — document uploads
- `flutter_foreground_task` — keep location alive when online
- `local_auth` — biometric unlock for going online (fraud prevention)
- `flutter_map` OR `google_maps_flutter` — same as rider for consistency

## Specific Rules for Driver App

- **Going online requires biometric confirmation** — prevents someone borrowing a logged-in device
- **Foreground service is mandatory on Android** when online. Follow Play Store foreground service policy and declare `FOREGROUND_SERVICE_LOCATION`.
- **Document expiry checks** at app launch. If any required document expires within 7 days, show persistent banner. If expired, block going online.
- **Ride acceptance has a hard 15-second timeout** — after that the request auto-rejects and moves to the next driver. Timer must be visible and audible.
- **Emergency button** is always accessible in-trip. Tapping it dials local emergency services AND notifies the admin dashboard via API.

## Earnings & Money

- All monetary values go through `core`'s `Money` type — never `double` for currency
- Display always in UZS with proper formatting (`1 250 000 so'm`, not `1250000 UZS`)
- Server is the source of truth for earnings; never compute totals client-side
- Show trip-level breakdown: base fare + distance + time + surge − commission = driver earning

## What This App Should NOT Contain

- ❌ Ride-request-from-passenger logic (that's rider_app)
- ❌ Admin operations
- ❌ Anything that looks like an admin dashboard
- ❌ Direct database/API access outside of `shared_services`
