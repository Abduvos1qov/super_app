# storage

Two-layer key-value storage for the super-app shell and mini-apps.

- `SecureStorage` — Keychain / EncryptedSharedPreferences for tokens & PII
- `PreferencesStorage` — shared_preferences for settings & flags
- `ScopedStorage` / `ScopedSecureStorage` — per-mini-app namespaced wrappers
  implementing `StorageScope` from `mini_app_sdk`

See `CLAUDE.md` for rules and security notes.
