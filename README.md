# timezone_finder

Offline lookup of the IANA time zone identifier (`Continent/City`) for any
latitude/longitude on land. Pure Dart, no network, no dependencies.

> **Status: early development (0.1.0).** The package is scaffolding, licensing and metadata only — the lookup is not implemented yet and the API below is the intended shape, not working code. Not usable, and not yet published.

## What it is for

Resolving the time zone of a geocoded postal or street address:

```text
address → geocoder (Nominatim, Photon, …) → (lat, lon) → find → Continent/City
```

The boundary data is bundled in the package, so lookups work fully offline on Dart CLI/server and on Flutter for mobile and desktop.

## Intended API

```dart
final finder = TimeZoneFinder();

finder.find(48.8566, 2.3522);   // 'Europe/Paris'
finder.find(0.0, -140.0);       // null — not inside any land time zone
```

`find` is synchronous. The index decodes lazily on first use; the optional
`ensurePreloaded()` pays that cost up front instead.

## Scope

This package answers one question: *which time zone is this coordinate in?*

- It returns an **identifier only**. For UTC offsets, DST and civil-time arithmetic, pass the identifier to
  [`package:timezone`](https://pub.dev/packages/timezone).
- The dataset covers **land only**, so a coordinate at sea returns `null`. Coordinates on beaches, piers, ferries and large lakes may also fall outside every polygon — expected for the address use case, worth knowing if you feed it raw GPS fixes.
- **Web is not a target for v1.** The bundled index is too large for a browser payload; supporting it needs a different delivery model.

## Data and licensing

The package **code** is MIT licensed. The bundled boundary data is a derived database under the **Open Database License (ODbL)** and is covered separately —
see [`LICENSE-DATA`](LICENSE-DATA), which includes the attribution notice you must keep if you redistribute it.

Boundaries come from [Timezone Boundary Builder](https://github.com/evansiroky/timezone-boundary-builder), built from OpenStreetMap data.

### Disputed territories

The upstream data allows 25 pairs of time zones to overlap, most of them disputed territories. Where a coordinate falls inside more than one zone, this package returns a single identifier chosen by a fixed, documented tie-break. That choice is technical and is **not a statement about sovereignty**.
