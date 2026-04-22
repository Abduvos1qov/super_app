# permissions

Unified runtime permissions for the super-app shell.

- `DefaultPermissionBroker` — `permission_handler`-backed implementation of
  `PermissionBroker` from `mini_app_sdk`.
- `InMemoryPermissionBroker` — deterministic test double.
- `PermissionMapper` — translates `MiniAppPermission` to the plugin enum.
- `PermissionRationalePresenter` — shell-owned UI hook for pre-request and
  permanently-denied rationales.

See `CLAUDE.md` for the mapping table and rationale flow.
