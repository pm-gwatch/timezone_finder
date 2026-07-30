## 0.1.0

Initial release. Pre-1.0: the API may still change.

Offline lookup of the IANA time zone identifier for a coordinate on land, in
pure Dart with no runtime dependencies and no network access.

```dart
final finder = TimeZoneFinder.exact();
finder.find(48.8566, 2.3522); // 'Europe/Paris'
finder.find(0.0, -140.0);     // null — not inside any land zone
```

### API

- `TimeZoneFinder.exact()` and `TimeZoneFinder.compact()` pick a data tier;
  `find(latitude, longitude)` returns a `Continent/City` identifier or `null`.
- `ensurePreloaded()` optionally decodes the index up front instead of on the
  first lookup. `ianaDatabaseVersion` and `availableTimeZones` report what
  is bundled.
- Out-of-range, NaN or infinite coordinates throw `ArgumentError`. `null` is
  reserved for "no land time zone here", so a bad argument is never mistaken
  for a legitimate answer.

### Two tiers

Boundary data is bundled, so the package is large. Both tiers are in the
archive; only the one you construct is compiled into your program.

| | boundary resolution | binary | peak memory |
| --- | --- | --- | --- |
| `TimeZoneFinder.exact()` | unsimplified, stored to ~11 cm | 43.7 MB | 88 MB |
| `TimeZoneFinder.compact()` | simplified to ~110 m | 11.4 MB | 29 MB |

Away from borders the tiers agree on all but 0.008% of random land coordinates.
Within a few hundred metres of a border they often differ; the measured rates
are in the README. The compact tier also omits a few very small islands and
enclaves that cannot survive simplification.

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
regions, with no disagreements for the exact tier. 265 hand-authored fixtures
cover cities, borders, enclaves, small islands, Antarctic stations, the
antimeridian, working ports and open ocean.

`dart run tool/refresh.dart --release 2026c --verify` rebuilds the bundled data
and confirms it matches byte for byte.

### Scope

- Identifiers only. For UTC offsets, DST and civil-time arithmetic, pass the
  result to [`package:timezone`](https://pub.dev/packages/timezone).
- Land only: coordinates at sea return `null`, as can a point on a beach, pier
  or large lake.
- Dart CLI/server and Flutter on mobile and desktop. Web is not supported — the
  bundled data is too large for a browser payload.
- Requires Dart 3.8 or later, verified on CI against that floor as well as
  stable.
