## 1.0.0

First stable release. Breaking: **the package is split in two.**
`timezone_finder` now only turns a point into a `Location`. Clock conversion
and English time zone labels, which shipped here through 0.2.0, moved to the
new [`timezone_extensions`](https://pub.dev/packages/timezone_extensions)
package under the same names: `TZDateTime.toLocation`,
`TZDateTime.offsetDifference`, `TZDateTime.timeZoneLongName`,
`TZDateTime.utcOffsetLabel`, `Location.timeZoneGenericName` and `cldrVersion`.

To keep using them, add `timezone_extensions` to `dependencies` and
`import 'package:timezone_extensions/timezone_extensions.dart';`.

Other changes:

- Removed `String.findLocation` (`GeoJsonLocation`). Nominatim and Photon
  return a `FeatureCollection`; pick a point and call
  `findLocation(longitude, latitude)`.
- The web asset is now always `boundaries.bin`, so boundary updates no longer
  rename it: point your Flutter `assets:` entry at
  `packages/timezone_finder/data/boundaries.bin` once. `boundariesDefaultUrl`
  adds `?v=<release>` so browsers do not reuse a stale cached copy.
- Requires `package:timezone` `^0.11.2` (tzdb 2026e).
- Boundaries refreshed to timezone-boundary-builder 2026e (OSM updates, and
  `Pacific/Easter` limited to Chilean territorial waters). Same 419
  identifiers; only borders moved. `boundaryDataVersion` is now `'2026e'`.
  From here, a boundary update with the same identifiers is a patch release;
  one that adds or removes identifiers is a minor release.
- `initializeBoundaries` reads the response with `arrayBuffer()` instead of
  `Response.bytes()`, so it also works on browsers that lack `bytes()`.
- A corrupt index (out-of-range zone id, short grid, polygon without rings)
  now throws `IndexFormatException` when installed, instead of a `RangeError`
  at lookup.

## 0.2.0

Breaking. 0.1.0 names have no `@Deprecated` aliases.

- **`Location` / `TZDateTime` extensions** still ship in this package, with
  the CLDR tables and `LICENSE-CLDR`; several are renamed below.
  *Corrected after release: this entry first said they had moved to
  `package:timezone_extensions` and that `formatUtcOffset` was exported.
  Neither was true in 0.2.0. The split happened in 1.0.0.*

- **`browser.dart` is web-only**, like `package:timezone/browser.dart`. Importing it off web is now a compile error (0.1.0 failed at runtime). Cross-platform apps should conditionally import it on the same branch that loads the `.bin`. VM, CLI, server, and Flutter mobile/desktop keep using `timezone_finder.dart` (boundaries are embedded).
- **Cross-location APIs** now sit beside `package:timezone` names:
  - `String.toLocation()` → `String.findLocation()`
  - `TZDateTime.convertTo(location)` → `TZDateTime.toLocation(location)` (`toUtc` / `toLocal` analogue)
  - `TZDateTime.utcOffsetDifference(location)` → `TZDateTime.offsetDifference(location)`
- **English labels** drop "metazone" from public names (that word is CLDR lookup jargon):
  - `Location.metazoneName` → `Location.timeZoneGenericName`
  - `TZDateTime.metazoneName` → `TZDateTime.timeZoneLongName` (beside `timeZoneName`)
  - `MetazoneLocation` → `LocationZoneNames`
  - `MetazoneTZDateTime` → `TZDateTimeZoneNames`
  - Removed `TZDateTime.metazoneAbbreviation` — use `timeZoneName` (`CEST`) or `utcOffsetLabel` (`UTC±…`)
- **`TZDateTime.utcOffset`** → **`TZDateTime.utcOffsetLabel`** — display string (`UTC+04:30`), not `timeZoneOffset` (`Duration`).
- **`ianaDatabaseVersion`** → **`boundaryDataVersion`** — timezone-boundary-builder release, independent of the tzdb version behind `package:timezone`.

## 0.1.0

*   Initial release.
