## 0.1.0

Initial release. Pre-1.0: the API may still change.

Offline lookup of the IANA time zone for a coordinate on land, in pure Dart
with no network access, bridged to `package:timezone` for civil time.

```dart
initializeTimeZones();
final finder = TimeZoneFinder();
finder.find(48.8566, 2.3522);          // 'Europe/Paris'
finder.findLocation(48.8566, 2.3522);  // a Location, ready for TZDateTime
finder.find(0.0, -140.0);              // null — not inside any land zone
```

### API

- `TimeZoneFinder()` takes no configuration; `find(latitude, longitude)`
  returns a `Continent/City` identifier or `null`.
- `findLocation(latitude, longitude)` returns a `package:timezone` `Location`
  instead, and `'48.8566,2.3522'.toLocation(using: finder)` does the same from
  text. Latitude comes first, matching `find` — note that GeoJSON is the
  reverse.
- `TZDateTime.inLocation(location)` and `.inLocations([...])` re-express one
  instant in other places' zones, preserving the moment and changing only the
  wall clock. That is the multi-place case `package:timezone`'s single ambient
  `local` cannot serve.
- `ensurePreloaded()` optionally decodes the index up front instead of on the
  first lookup. `ianaDatabaseVersion` and `availableTimeZones` report what
  is bundled.
- Out-of-range, NaN or infinite coordinates throw `ArgumentError`; text that is
  not two comma-separated numbers throws `FormatException`. `null` is reserved
  for "no land time zone here", so neither is mistaken for a legitimate answer.

### Initializing the time zone database

`package:timezone` is a dependency, but **no tzdata variant is** — your
application chooses and initializes one, so the payload stays your decision and
nothing is initialized behind your back. Initializing twice would clear the
database and reset the local location to UTC, so this package never does it for
you.

Use `package:timezone/data/latest_all.dart`. The default `data/latest.dart`
drops the tzdb link identifiers and carries 341 locations against this dataset's
419 — `Europe/Zagreb` and `Africa/Accra` among the 106 missing. `findLocation`
raises a `StateError` naming the fix rather than letting the underlying
`LocationNotFoundException` point at the boundary data.

### Resolution

Boundaries are bundled, so lookups need no network and no setup. They are
simplified to roughly 110 m — far finer than a time zone — which keeps the
published archive at about 3 MB and a compiled program at about 11 MB.

All 419 identifiers are present. Against the unsimplified source geometry the
answers differ on 0.008% of random land coordinates, and on 0.21% within 1 km
of a border town centre. Simplification drops 33 polygons and 27 holes that
collapse at this tolerance, so a few very small islands resolve to a
neighbouring zone or to `null`. The README has the full table.

### Data

Boundaries are from timezone-boundary-builder release `2026c` — 419
identifiers, land only — built from OpenStreetMap.

Package code is MIT. **The bundled boundary data is ODbL**, which is
share-alike and requires attribution if you redistribute it; see `LICENSE-DATA`
and the README.

Where zones overlap — 25 documented pairs, mostly disputed territories — one
identifier is returned by a fixed, documented rule. That choice is technical
and is not a statement about sovereignty.

### Correctness

Answers were validated against a separate reference implementation that reads
the source boundaries directly, over 10,000,000 sampled coordinates weighted
toward borders, enclaves, grid boundaries, the antimeridian and the overlap
regions. Run against the unsimplified geometry the pipeline shows no
disagreements at all, so the bundled data's only deviation is the
simplification measured above. 273 hand-authored fixtures
cover cities, borders, enclaves, small islands, Antarctic stations, the
antimeridian, working ports and open ocean.

`dart run tool/refresh.dart --release 2026c --verify` rebuilds the bundled data
and confirms it matches byte for byte.

### Scope

- Boundaries only. UTC offsets, DST and civil-time arithmetic remain
  [`package:timezone`](https://pub.dev/packages/timezone)'s work; this package
  resolves the coordinate and hands over a `Location`.
- Land only: coordinates at sea return `null`, as can a point on a beach, pier
  or large lake.
- Dart CLI/server and Flutter on mobile and desktop. Web is not supported — the
  bundled data is too large for a browser payload.
- Requires Dart 3.10 or later, verified on CI against that floor as well as
  stable.
