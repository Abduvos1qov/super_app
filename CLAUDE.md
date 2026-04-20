# Ride-Hailing Monorepo

## Project Overview

Flutter monorepo for a ride-hailing platform with three client applications and shared packages. Managed with **Dart Workspaces** (native, Dart 3.6+) for dependency resolution and **Melos** for workflow orchestration.

- `apps/rider_app` — passenger mobile app (iOS + Android)
- `apps/driver_app` — driver mobile app (iOS + Android)
- `apps/admin_web` — admin dashboard (Flutter Web)
- `packages/core` — pure Dart business logic (fare calc, validators, constants)
- `packages/shared_models` — domain models (User, Trip, Driver, Payment)
- `packages/shared_services` — API clients, auth, storage, location
- `packages/shared_ui` — design system (theme, buttons, forms, widgets)

For deep architecture details, dependency graph, and design decisions: @ARCHITECTURE.md

## Tech Stack

- Flutter **3.27+**, Dart **3.6+** (workspace support required)
- State management: **Riverpod** (`flutter_riverpod`, `riverpod_generator`)
- Routing: **go_router**
- HTTP: **dio** with interceptors in `shared_services`
- Serialization: **freezed** + **json_serializable**
- Logging: **logger** package
- Testing: **flutter_test** + **mocktail** + golden tests via `alchemist`
- Lints: **very_good_analysis**
- Monorepo: **melos** + **Dart Workspaces**

## Architecture Rules (NON-NEGOTIABLE)

These rules prevent the codebase from rotting. Never violate them without explicit approval.

1. **Dependency direction is one-way**: `apps/` → `packages/`. Packages NEVER import from `apps/`.
2. **Package dependency graph is a tree, not a web**:
   - `core` depends on nothing in this repo
   - `shared_models` depends only on `core`
   - `shared_services` depends on `core` + `shared_models`
   - `shared_ui` depends only on `core` (NO services, NO network)
   - Apps depend on all four packages
3. **shared_ui is dumb**: zero network calls, zero storage, zero business logic. Only presentation.
4. **No god packages**: prefer granular (`auth`, `networking`, `theme`) over dumping grounds named `common` or `utils`.
5. **Every package in this repo MUST declare `resolution: workspace`** in its pubspec.yaml.
6. **No hardcoded strings in UI** — use `core/lib/l10n/` constants or arb localization.
7. **No raw `Color(0xFF...)` or magic numbers in widgets** — use `AppTheme.colors` and `AppSpacing` from shared_ui.

## Commands

Always use these commands from the repo root. Do not invent alternatives.

| Task | Command |
|------|---------|
| Install all dependencies | `flutter pub get` (from root — workspaces handle the rest) |
| Bootstrap Melos scripts | `melos bootstrap` |
| Run all tests | `melos run test` |
| Test a specific package | `melos exec --scope="<name>" -- flutter test` |
| Static analysis everywhere | `melos run analyze` |
| Format everything | `melos run format` |
| Run code generation | `melos run gen` |
| Run rider app (debug) | `cd apps/rider_app && flutter run` |
| Run admin web | `cd apps/admin_web && flutter run -d chrome` |
| Clean everything | `melos run clean` |

Before any commit, run: `melos run analyze && melos run test`.

## Coding Conventions

- 2-space indentation, trailing commas in multi-arg constructors
- File names: `snake_case.dart`
- Class names: `PascalCase`
- Private members prefixed with `_`
- Prefer `final` for all locals that aren't reassigned
- Use `const` constructors wherever possible
- Prefer named parameters once a widget/function has 2+ args
- Use expression bodies (`=>`) only for single-return one-liners
- Import order: `dart:*`, `package:flutter/*`, `package:*`, relative
- Generated files MUST NOT be committed (`*.g.dart`, `*.freezed.dart`, `*.gr.dart`)

More Dart-specific rules: @.claude/rules/dart-conventions.md
Testing rules: @.claude/rules/testing.md

## Git Workflow

- **Branch naming**: `feat/<scope>/<description>`, `fix/<scope>/<description>`, `chore/...`
- **Commits follow Conventional Commits** — Melos parses these for automatic versioning
  - `feat: add fare surge calculation` → minor bump
  - `fix: correct timezone in trip history` → patch bump
  - `feat!: rename User.id to User.uuid` → major bump (breaking)
- Scope the commit to one logical change; atomic refactors across packages are fine and encouraged in a monorepo
- Never commit secrets, `.env` files, or `CLAUDE.local.md`

## How to Extend the Monorepo

When asked to add a new feature:

1. Decide **where it belongs**: is it an app-level screen or shared logic? Shared logic goes in a package.
2. If shared, decide **which package**: pure Dart → `core`; domain model → `shared_models`; needs I/O → `shared_services`; UI widget → `shared_ui`.
3. If none fit, **create a new granular package** (e.g., `packages/payments`) rather than dumping into `shared_services`.
4. Register the new package path in root `pubspec.yaml` under `workspace:`.
5. Run `flutter pub get` from root.

## Common Mistakes to Avoid

- ❌ Importing `shared_services` from `shared_ui` (circular-ish, breaks UI purity)
- ❌ Using `Navigator.of(context).push(...)` directly → always go through the shared `AppRouter` (go_router)
- ❌ Adding `http` or `dio` to `shared_ui` pubspec.yaml
- ❌ Writing business logic inside widgets → extract to a Riverpod notifier in the app layer or a pure function in `core`
- ❌ Forgetting `resolution: workspace` in a new package's pubspec.yaml (will cause dependency resolution failures)
- ❌ Publishing any package to pub.dev — these are all private/internal

## When Uncertain

- Read the relevant package's local `CLAUDE.md` (e.g., `packages/shared_ui/CLAUDE.md`)
- Read `ARCHITECTURE.md` for the big picture
- Ask before introducing a new third-party dependency
- Ask before creating a new package at the top level
