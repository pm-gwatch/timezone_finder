# timezone_finder

Offline lookup of the IANA time zone identifier (`Continent/City`) for any
latitude/longitude on land. Pure Dart, no network, no dependencies.

```dart
import 'package:timezone_finder/timezone_finder.dart';

final finder = TimeZoneFinder();

finder.find(48.8566, 2.3522);    // 'Europe/Paris'
finder.find(-33.8688, 151.2093); // 'Australia/Sydney'
finder.find(0.0, -140.0);        // null — not inside any land zone
```

> **Status: 0.1.0, not yet published.** The lookup works and the boundary data
> is bundled, but the API may still change.

## What it is for

Resolving the time zone of a geocoded postal or street address:

```text
address → geocoder (Nominatim, Photon, …) → (lat, lon) → find → Continent/City
```

The boundary data ships inside the package, so lookups work fully offline on
Dart CLI/server and on Flutter for mobile and desktop.

`find` is synchronous. The index decodes lazily on first use; the optional
`ensurePreloaded()` pays that cost up front instead.

## Scope

This package answers one question: *which time zone is this coordinate in?*

- It returns an **identifier only**. For UTC offsets, DST and civil-time
  arithmetic, pass the identifier to
  [`package:timezone`](https://pub.dev/packages/timezone).
- The dataset covers **land only**, so a coordinate at sea returns `null`.
  Coordinates on beaches, piers, ferries and large lakes may also fall outside
  every polygon — expected for the address use case, worth knowing if you feed
  it raw GPS fixes.
- **Web is not a target yet.** The bundled index is too large for a browser
  payload; supporting it needs a different delivery model.

## Two sizes

The boundary data ships inside the package, so the download is not small.
Import whichever tier suits you — **never both**, since each carries its own
copy of the data.

| | import | class | binary | peak memory |
| --- | --- | --- | --- | --- |
| **Exact** | `package:timezone_finder/timezone_finder.dart` | `TimeZoneFinder` | 43.7 MB | 88 MB |
| **Compact** | `package:timezone_finder/compact.dart` | `CompactTimeZoneFinder` | 11.4 MB | 29 MB |

Both tiers are in the published archive either way — 29 MiB compressed, 16 % of
pub.dev's limit. What the import decides is which one ends up in *your* binary.
Accept `BaseTimeZoneFinder` in your own signatures if you want to stay agnostic
about which a caller passes.

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

## Disputed territories

**Worth reading if your application touches a contested border.**

The upstream boundary data permits **25 pairs of time zones to overlap**, and
most of those overlaps are disputed territories. Where a coordinate falls
inside more than one zone there is no fact of the matter about which identifier
is correct — both polygons genuinely cover the point.

The affected areas include:

| overlap | area |
| --- | --- |
| `Africa/Juba` – `Africa/Khartoum` | Abyei, Kafia Kingi |
| `Asia/Hebron` – `Asia/Jerusalem` | West Bank |
| `Asia/Kathmandu` – `Asia/Kolkata` | Kalapani |
| `Asia/Urumqi` – `Asia/Shanghai` | Xinjiang |
| `Asia/Pyongyang` – `Asia/Shanghai` | Tumen estuary |
| `Europe/Athens` – `Europe/Istanbul` | Aegean |
| `Asia/Tbilisi` – `Europe/Moscow` | Abkhazia |
| `America/Punta_Arenas` – `America/Argentina/Rio_Gallegos` | southern Patagonia |

plus further pairs, including small survey discrepancies along uncontested
borders.

In these areas this package returns **one identifier, chosen by an arbitrary
deterministic rule**: the smallest containing polygon by planar area, and
lexicographic identifier order if two are the same size. The rule was chosen
because it is reproducible, not because it means anything. **No answer this
package gives is a statement about sovereignty**, and none should be read as
one.

There is currently no API to retrieve every zone containing a point, so the
single arbitrary answer is the only one available. If your application needs to
represent a contested location honestly, handle those coordinates yourself
rather than relying on this package's tie-break.

## Data and licensing

The package **code** is MIT licensed. The bundled boundary data is a derived
database under the **Open Database License (ODbL) v1.0** and is covered
separately — see [`LICENSE-DATA`](LICENSE-DATA).

If you redistribute this data, or a work produced from it, ODbL requires you to
keep this attribution:

> Time zone boundary data © OpenStreetMap contributors, available under the
> Open Database License (ODbL). Boundaries built by
> [Timezone Boundary Builder](https://github.com/evansiroky/timezone-boundary-builder).

ODbL is share-alike: publicly using an adapted version of the database means
offering that adapted database under the ODbL too.

## Data updates

The bundled index is built from a specific
[timezone-boundary-builder](https://github.com/evansiroky/timezone-boundary-builder)
release, currently **2026c**. `finder.dataVersion` reports it at runtime.

Boundary releases appear two to four times a year and are decoupled from IANA
tzdb releases: most tzdb releases change daylight-saving *rules*, which this
package does not model, and move no boundary. A new package version follows a
boundary release, not a tzdb one.

- A release that changes only geometry gets a **patch** version.
- A release that adds, removes or renames an identifier gets a **minor**
  version and a changelog entry, because it can change an answer you depend on.

## Accuracy

Answers are validated against a deliberately naive reference implementation
that reads the source boundaries directly. The two are compared over **ten
million sampled coordinates**, weighted toward zone borders, enclaves, grid
boundaries and the antimeridian rather than spread uniformly — **zero
disagreements** for the exact tier.

## Credits

Boundaries from
[Timezone Boundary Builder](https://github.com/evansiroky/timezone-boundary-builder)
by Evan Siroky, built from [OpenStreetMap](https://www.openstreetmap.org) data.
IANA publishes no official time zone polygons; tzbb is cited as the de facto
source on IANA's own [tz-link](https://data.iana.org/time-zones/tz-link.html)
page.
