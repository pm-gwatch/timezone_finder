# timezone_finder

Offline lookup of the IANA time zone identifier (`Continent/City`) for any
latitude/longitude on land. Pure Dart, no network, no dependencies.

> **Status: early development (0.1.0).** The lookup works and the boundary
> data is bundled, but the package has not been published yet and the API may
> still change.

## What it is for

Resolving the time zone of a geocoded postal or street address:

```text
address → geocoder (Nominatim, Photon, …) → (lat, lon) → find → Continent/City
```

The boundary data is bundled in the package, so lookups work fully offline on Dart CLI/server and on Flutter for mobile and desktop.

## Usage

```dart
final finder = TimeZoneFinder();

finder.find(48.8566, 2.3522);   // 'Europe/Paris'
finder.find(0.0, -140.0);       // null — not inside any land time zone
```

`find` is synchronous. The index decodes lazily on first use; the optional
`ensurePreloaded()` pays that cost up front instead.

## Two sizes

The boundary data ships inside the package, so the download is not small.
Import whichever tier suits you — **never both**, since each carries its own
copy of the data.

| | import | download | binary | peak memory |
| --- | --- | --- | --- | --- |
| **Exact** | `package:timezone_finder/timezone_finder.dart` | 25 MB | 43.7 MB | 88 MB |
| **Compact** | `package:timezone_finder/compact.dart` | ~4 MB | 11.4 MB | 29 MB |

The compact tier simplifies boundaries to roughly 110 m. The API is identical;
only the accuracy near borders differs, and it differs in a measured way:

| where the coordinate is | answers differing from the exact tier |
| --- | --- |
| anywhere on land, drawn at random | **0.008 %** |
| within ~2 km of a boundary | 1.0 % |
| within ~500 m of a boundary | 30 % |

So for a geocoded street address the two tiers almost always agree, and within
a few hundred metres of a border they often will not. All 265 test fixtures —
including every enclave and small-island case, Lesotho and Vatican City among
them — resolve identically in both.

Simplification drops 33 polygons and 27 holes that collapse to nothing at this
tolerance, so a handful of very small islands resolve to a neighbouring zone or
to `null` in the compact tier.

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
