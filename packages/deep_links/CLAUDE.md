# deep_links

Default implementation of the `DeepLinkDispatcher` contract declared in
`mini_app_sdk`. Parses incoming URIs and fans resolved links out to the
owning mini-app.

## Purpose

- Centralise deep-link parsing for the shell (custom scheme + Universal
  Links + App Links).
- Route each parsed `DeepLink` to exactly one mini-app's subscription
  stream, with zero cross-talk.
- Keep mini-apps decoupled from the platform: they depend on the
  `DeepLinkDispatcher` interface from `mini_app_sdk`, not on this package.

## URL grammar

Custom scheme (primary):

```
superapp://<miniAppId>/<subPath>?<query>
```

Universal / App Links (optional, host-gated):

```
https://<allowedHost>/<miniAppId>/<subPath>?<query>
```

The first path segment becomes the target `miniAppId`; the remainder
becomes the in-app `path`. Missing paths default to `/`.

## Platform integration

This package does NOT depend on `app_links` or `uni_links`. The shell
owns the plugin wiring and calls `DefaultDeepLinkDispatcher.submit(uri)`
for every URI delivered by the platform (cold-start link, warm foreground
link, debug injection). That keeps this package pure Dart + Flutter SDK
and trivially unit-testable.

## Why scheme config

`DeepLinkSchemeConfig` makes the allow-list explicit so production can
switch from the custom `superapp://` scheme to HTTPS Universal Links
without code changes elsewhere. Add verified domains to
`allowedHttpsHosts` once App Site Association / Digital Asset Links are
provisioned.

## Security

- Unknown schemes are dropped silently — they are never routed.
- HTTPS URIs are rejected unless the host is in `allowedHttpsHosts`.
- Parse failures do not throw; invalid URIs simply do not fan out.

## Rules

- Only the shell constructs `DefaultDeepLinkDispatcher`. Mini-apps must
  not import this package.
- Do NOT add platform link plugins here. Keep this package a pure
  parser + dispatcher.
