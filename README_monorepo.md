# Super-App Platform Monorepo

Flutter monorepo for a general-purpose super-app platform. One shell, many mini-apps, a handful of shared packages, one codebase.

## Prerequisites

- Flutter `^3.27.0`
- Dart `^3.6.0`
- Melos: `dart pub global activate melos`

## First-Time Setup

```bash
# 1. Clone and enter the repo
git clone <your-repo-url> super_app
cd super_app

# 2. Install dependencies (Dart workspaces does the heavy lifting)
flutter pub get

# 3. Bootstrap Melos (runs hooks, codegen, etc.)
melos bootstrap

# 4. Verify everything works
melos run analyze
melos run test
```

## Running the Shell

```bash
cd apps/super_app
flutter run            # iOS simulator / Android emulator
flutter run -d chrome  # web (if web target is enabled)
```

## Repository Structure

```
super_app/
├── CLAUDE.md                 # AI assistant instructions (Claude Code)
├── ARCHITECTURE.md           # Architectural deep-dive
├── README.md                 # Short project intro
├── README_monorepo.md        # You are here
├── SETUP.md                  # Onboarding walkthrough
├── pubspec.yaml              # Workspace root config
├── melos.yaml                # Scripts and orchestration
├── analysis_options.yaml     # Lint rules for the whole repo
├── .claude/
│   └── rules/                # Path-scoped rules for Claude Code
├── apps/
│   └── super_app/            # The shell (iOS + Android)
└── packages/
    ├── core/                 # Pure Dart primitives
    ├── shared_models/        # Cross-domain freezed models
    ├── shared_ui/            # Design system
    ├── mini_app_sdk/         # Shell <-> mini-app contract
    ├── mini_app_registry/    # Discovery + gating
    ├── auth/                 # SessionController implementation
    ├── networking/           # NetworkGateway implementation
    ├── storage/              # StorageScope implementation
    ├── analytics/            # AnalyticsTracker implementation
    ├── feature_flags/        # FeatureFlagService implementation
    ├── payments/             # PaymentGateway implementation
    ├── notifications/        # NotificationRouter implementation
    ├── deep_links/           # DeepLinkDispatcher implementation
    ├── permissions/          # PermissionBroker implementation
    ├── event_bus/            # AppEventBus implementation
    └── mini_apps/
        └── demo_mini_app/    # Reference mini-app (copy this)
```

## Daily Workflow

| Task | Command |
|------|---------|
| Install/update deps | `flutter pub get` |
| Run all tests | `melos run test` |
| Test one package | `melos exec --scope="<name>" -- flutter test` |
| Static analysis | `melos run analyze` |
| Format code | `melos run format` |
| Run codegen (freezed, riverpod) | `melos run gen` |
| Watch codegen | `melos run gen:watch` |
| Clean | `melos run clean` |

## Git Workflow

The repo uses **Conventional Commits**. Melos parses them for automatic versioning and changelogs.

Examples:

- `feat(mini_apps/demo_mini_app): add empty state to home` — minor bump
- `fix(networking): retry 5xx responses with exponential backoff` — patch
- `feat(mini_app_sdk)!: rename MiniApp.build to MiniApp.buildRoot` — major (breaking)
- `chore: bump dio to 5.5.0`
- `docs(architecture): clarify platform-service surface`
- `test(core): add boundary cases for Money.format`

Branch naming: `feat/<scope>/<slug>`, `fix/<scope>/<slug>`, `chore/<slug>`.

Before opening a PR:

```bash
melos run analyze
melos run test
melos run format
```

## Adding a New Package

1. Create the directory under `packages/` (or `packages/mini_apps/` for a vertical).
2. Run `dart create --template=package .` (or `flutter create --template=package .` if it needs Flutter).
3. In the package's `pubspec.yaml` add `resolution: workspace`.
4. Register the path in the root `pubspec.yaml` under `workspace:`.
5. From repo root: `flutter pub get`.
6. Add a `CLAUDE.md` to the new package with its rules and scope.

For a **new mini-app**, copy `packages/mini_apps/demo_mini_app/` and register it in `apps/super_app/lib/bootstrap/mini_app_registry_provider.dart`. See `CLAUDE.md` → "How to Add a New Mini-App" for the full recipe.

For a **new platform service**, define an abstract interface in `mini_app_sdk` first. See `CLAUDE.md` → "How to Add a New Platform Service".

## Working with Claude Code

This repo is optimized for Claude Code. `CLAUDE.md` files at every level teach the assistant about architecture, conventions, and rules.

To start Claude Code in this repo:

```bash
claude   # from the monorepo root
```

Claude automatically loads:

- Root `CLAUDE.md` (always)
- Root `.claude/rules/*.md` (always, unless path-scoped)
- The relevant package-level `CLAUDE.md` (when working in that package)

If Claude makes the same mistake twice, add a rule to the closest relevant `CLAUDE.md` or `.claude/rules/*.md` file.

## License

Proprietary. All rights reserved.
