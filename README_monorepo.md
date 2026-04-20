# Ride-Hailing Monorepo

Flutter monorepo for a ride-hailing platform. Three apps, four shared packages, one codebase.

## Prerequisites

- Flutter `^3.27.0`
- Dart `^3.6.0`
- Melos: `dart pub global activate melos`

## First-Time Setup

```bash
# 1. Clone and enter the repo
git clone <your-repo-url> ride_hailing_monorepo
cd ride_hailing_monorepo

# 2. Install dependencies (Dart workspaces does the heavy lifting)
flutter pub get

# 3. Bootstrap Melos (runs hooks, codegen, etc.)
melos bootstrap

# 4. Verify everything works
melos run analyze
melos run test
```

## Running Apps

```bash
# Rider app (mobile)
cd apps/rider_app && flutter run

# Driver app (mobile)
cd apps/driver_app && flutter run

# Admin web (browser)
cd apps/admin_web && flutter run -d chrome
```

## Repository Structure

```
ride_hailing_monorepo/
├── CLAUDE.md                 # AI assistant instructions (Claude Code)
├── ARCHITECTURE.md           # Architectural deep-dive
├── README.md                 # You are here
├── pubspec.yaml              # Workspace root config
├── melos.yaml                # Scripts and orchestration
├── analysis_options.yaml     # Lint rules for the whole repo
├── .claude/
│   └── rules/                # Path-scoped rules for Claude Code
├── apps/
│   ├── rider_app/            # Passenger mobile app
│   ├── driver_app/           # Driver mobile app
│   └── admin_web/            # Operations web dashboard
└── packages/
    ├── core/                 # Pure Dart business logic
    ├── shared_models/        # Domain models (freezed)
    ├── shared_services/      # API, auth, storage, location
    └── shared_ui/            # Design system
```

## Daily Workflow

| Task | Command |
|------|---------|
| Install/update deps | `flutter pub get` |
| Run all tests | `melos run test` |
| Test one package | `melos exec --scope="core" -- flutter test` |
| Static analysis | `melos run analyze` |
| Format code | `melos run format` |
| Run codegen (freezed, riverpod) | `melos run gen` |
| Watch codegen | `melos run gen:watch` |
| Clean | `melos run clean` |

## Git Workflow

This repo uses **Conventional Commits**. Melos parses these for automatic versioning and changelog generation.

Examples:

- `feat(rider): add saved places` → minor version bump
- `fix(shared_ui): correct dark-mode contrast on PrimaryButton` → patch
- `feat!: rename User.id to User.uuid` → major (breaking)
- `chore: bump dio to 5.4.0`
- `docs(architecture): clarify dependency rules`
- `test(core): add boundary cases for FareCalculator`

Branch naming: `feat/<scope>/<slug>`, `fix/<scope>/<slug>`, `chore/<slug>`.

Before opening a PR:

```bash
melos run analyze
melos run test
melos run format
```

## Adding a New Package

1. Create the directory under `packages/` (or elsewhere if it's app-specific)
2. Run `dart create --template=package .` (or `flutter create --template=package .` if it needs Flutter)
3. In the package's `pubspec.yaml`, add:
   ```yaml
   resolution: workspace
   ```
4. Register the path in the root `pubspec.yaml` under `workspace:`
5. From root: `flutter pub get`
6. Add a `CLAUDE.md` to the new package with its rules and scope

## Working with Claude Code

This repo is optimized for Claude Code. The `CLAUDE.md` files at every level teach the assistant about architecture, conventions, and rules.

To get started with Claude Code in this repo:

```bash
claude   # from the monorepo root
```

Claude will automatically load:

- Root `CLAUDE.md` (always)
- Root `.claude/rules/*.md` (always, unless path-scoped)
- The relevant package-level `CLAUDE.md` (when working in that package)

If Claude makes the same mistake twice, add a rule to the closest relevant `CLAUDE.md` or `.claude/rules/*.md` file.

## License

Proprietary. All rights reserved.
