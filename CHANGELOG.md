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
- Full golden set: 265 ground-truth fixtures across 237 zones, covering
  borders, enclaves, islands, Antarctic stations, the antimeridian and open
  ocean, plus 21 regression pins for the documented zone overlaps.
- Query longitudes are normalised at the antimeridian so that 180° and -180°
  return the same identifier.
- Packed coordinate format: rings stored as zigzag-varint deltas between
  consecutive vertices, with a vertex count prefix so a ring can be decoded
  from its offset alone.
- Shortcut grid: a 1° raster narrowing a lookup from 1,184 polygons to a mean
  of 1.9 candidates before any geometry is tested.
- Runtime lookup: `TimeZoneFinder.find` resolves a coordinate against the
  packed index, decoding ring coordinates only for the polygons it actually
  tests. The index container carries a magic number and format version, and is
  rejected rather than misparsed if either is wrong.
- 100 tests. The tests needing boundary data skip when it has not been fetched;
  the quantization tests always run.
- Targets Dart CLI/server and Flutter on mobile and desktop. Web is deferred.
