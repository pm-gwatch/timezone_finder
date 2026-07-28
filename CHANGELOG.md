## 0.1.0

Development version. No lookup implementation yet — the API described in the
README is the intended shape, not working code.

- Package scaffolding, licensing and metadata. Package code is MIT; the bundled
  boundary data will be ODbL (see `LICENSE-DATA`).
- Bootstrap golden fixtures: 66 hand-authored coordinate → IANA identifier
  pairs across 66 distinct zones, in `test/fixtures/bootstrap_goldens.dart`.
  These are the ground truth the forthcoming reference implementation is
  validated against. Verified against two independent implementations
  (`timezonefinder`, `tzf`) and against the identifier list of
  timezone-boundary-builder `2026c`; see `test/fixtures/README.md`.
- 10 fixture integrity tests.
- Targets Dart CLI/server and Flutter on mobile and desktop. Web is deferred.
