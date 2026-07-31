# timezone_finder

Offline lookup of the IANA time zone identifier (`Continent/City`) for any
latitude/longitude on land. Pure Dart, no network, no dependencies.

```dart
import 'package:timezone_finder/timezone_finder.dart';

final finder = TimeZoneFinder.exact();

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
- The dataset covers **land only**, so a coordinate well out to sea returns
  `null`. Coordinates on beaches, piers, ferries and large lakes may also fall
  outside every polygon — expected for the address use case, worth knowing if
  you feed it raw GPS fixes. See [What `null` really means](#what-null-really-means)
  before treating it as "this point is at sea".
- **Web is not a target yet.** The bundled index is too large for a browser
  payload; supporting it needs a different delivery model.

## What `null` really means

`null` means *no time zone polygon contains this point* — which is not quite the
same as *this point is at sea*.

"Land only" is the upstream dataset's term, and it means the boundaries exclude
the synthetic `Etc/GMT±N` ocean zones. It does not mean they stop at the
shoreline. Country polygons follow OpenStreetMap administrative boundaries, and
for a coastal state those extend over territorial waters — roughly 12 nautical
miles, about 22 km, from the coast.

The consequence is visible in any narrow strait. The Dover Strait is about
42 km across, so the British and French claims meet in the middle with nothing
unclaimed between them:

```dart
finder.find(51.1269705, 1.3230653); // Port of Dover   -> Europe/London
finder.find(50.9744815, 1.8765687); // Port of Calais  -> Europe/Paris
finder.find(51.050726,  1.599817);  // mid-Channel     -> Europe/Paris
```

That last one is water, and it still resolves — the boundary between the two
zones runs down the middle of the strait, and the midpoint falls just on the
French side of it. Sail west along the Channel and it opens out; past roughly
100 km of width there is international water in the middle and lookups start
returning `null`.

So: a `null` tells you no country claims that point. A non-null answer does not
promise you are standing on dry land.

## Two sizes

The boundary data ships inside the package, so the download is not small.
Import whichever tier suits you — **never both**, since each carries its own
copy of the data.

| | constructor | boundary resolution | binary | peak memory |
| --- | --- | --- | --- | --- |
| **Exact** | `TimeZoneFinder.exact()` | unsimplified, stored to ~11 cm | 43.7 MB | 88 MB |
| **Compact** | `TimeZoneFinder.compact()` | simplified to ~110 m | 11.4 MB | 29 MB |

One import, one class; the constructor picks the tier. Only the tier you
construct is compiled in — both are in the published archive either way (29 MiB
compressed, 16 % of pub.dev's limit), so the constructor decides what you
*ship*, not what you download.

**On "~11 cm".** That is the exact tier's storage resolution — coordinates are
quantized to 1e-6°, and no vertices are dropped. It is not an accuracy claim:
the boundaries come from OpenStreetMap, whose own positional error is metres to
tens of metres. The quantization is deliberately finer than the source so it
contributes nothing of its own. The compact tier's ~110 m, by contrast, *is* a
deliberate loss.

The compact tier's loss is measured, not estimated:

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
release, currently **2026c**. `finder.ianaDatabaseVersion` reports it at runtime.

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
