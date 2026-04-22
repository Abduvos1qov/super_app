# super_app

Flutter monorepo for a **general-purpose super-app platform**. One shell hosts many independently-developed mini-apps through a single, well-typed contract.

- Architecture overview: [`ARCHITECTURE.md`](./ARCHITECTURE.md)
- Day-to-day monorepo workflow: [`README_monorepo.md`](./README_monorepo.md)
- First-time setup and onboarding: [`SETUP.md`](./SETUP.md)
- Assistant guidance (Claude Code): [`CLAUDE.md`](./CLAUDE.md)

## Quick start

```bash
flutter pub get
melos bootstrap
melos run analyze
melos run test
cd apps/super_app && flutter run
```

## License

Proprietary. All rights reserved.
