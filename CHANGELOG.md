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
- Phase A reference oracle in `test/reference/` — a deliberately naive
  implementation that parses the boundary GeoJSON and tests every polygon. It
  never ships; it is the correctness authority the real index will be
  validated against. Passes all 66 bootstrap goldens.
- `tool/fetch_data.dart` caches the boundary data under `.dart_tool/`;
  `tool/probe_overlaps.dart` reports which documented zone overlaps are
  reachable in the land-only dataset.
- Full golden set: 264 ground-truth fixtures across 236 zones, covering
  borders, enclaves, islands, Antarctic stations, the antimeridian and open
  ocean, plus 21 regression pins for the documented zone overlaps.
- Query longitudes are normalised at the antimeridian so that 180° and -180°
  return the same identifier.
- 66 tests. The tests needing boundary data skip when it has not been fetched;
  the quantization tests always run.
- Targets Dart CLI/server and Flutter on mobile and desktop. Web is deferred.
