# timezone_finder

Offline IANA time zone lookup for any coordinate on land, returning a
`package:timezone` `Location` — so you can build correct local dates and times
for many places at once. Pure Dart, no network.

```dart
import 'package:timezone/data/latest_all.dart';
import 'package:timezone/timezone.dart';
import 'package:timezone_finder/timezone_finder.dart';

/// A geocoder's answer for Paris, as Nominatim or Photon returns it.
const parisFeature = '{"type": "Feature", "geometry": '
    '{"type": "Point", "coordinates": [2.3522, 48.8566]}}';

initializeTimeZones();           // required to create any Location

findId(48.8566, 2.3522);         // 'Europe/Paris' — the identifier
findLocation(48.8566, 2.3522);   // a Location, ready for TZDateTime
parisFeature.toLocation();       // the same, straight from a geocoder
findId(0.0, -140.0);             // null — not inside any land zone
```

> **Status: 0.1.0, not yet published.** The lookup works and the boundary data
> is bundled, but the API may still change.

## What it is for

Resolving the time zone of a geocoded postal or street address, and then
showing times there:

```text
address → geocoder (Nominatim, Photon, …) → GeoJSON Feature → Continent/City → Location
```

The boundary data ships inside the package, so lookups work fully offline on
Dart CLI/server and on Flutter for mobile and desktop.

Lookups are synchronous and need no setup — there is nothing to construct.
The index decodes lazily on first use; `ensurePreloaded()` pays that cost up
front instead.

**On a server, call `ensurePreloaded()` at startup.** The index is decoded
**once per isolate**, so without it the first request handled by each isolate
pays for the decode. Measured, each additional live isolate costs about **4 MB**
— eight of them hold eight copies, roughly 29 MB over one.

## One instant, several places

`package:timezone` models zones correctly — transition tables, DST rules,
historical changes — but it starts from an identifier you already know, and it
assumes a single ambient local zone per process. That second assumption is the
one that breaks whenever a program handles more than one place at a time: a
flight with a departure and an arrival, a meeting with participants in nine
countries, a fleet, a photo library.

This package supplies the missing half. Coordinates in, `Location` out, and one
instant rendered wherever it needs to be read:

```dart
const charlesDeGaulle = '{"type": "Feature", "geometry": '
    '{"type": "Point", "coordinates": [2.5479, 49.0097]}}';
const jfk = '{"type": "Feature", "geometry": '
    '{"type": "Point", "coordinates": [-73.7781, 40.6413]}}';

final takeOff = TZDateTime(charlesDeGaulle.toLocation()!, 2026, 8, 23, 10, 15);
final landing = takeOff.add(const Duration(hours: 8, minutes: 20));

takeOff;                                // 10:15, Paris
landing.inLocation(jfk.toLocation()!);  // 12:35 at JFK — the same instant
```

`inLocations` takes several places at once and returns one entry per place, in
order:

```dart
start.inLocations([newYork, tokyo, sydney]);  // List<TZDateTime>
```

Every entry resolves: a place with no time zone never becomes a `Location` in
the first place, so the list has no gaps.

Both preserve the moment and change only the wall clock. To keep the wall clock
and change the moment — *move* a meeting to New York's 17:30 rather than
*translate* it — construct a new `TZDateTime` with the other location.

**Not in scope: ambiguous and nonexistent wall-clock times.** On the night a
zone springs forward, 02:30 does not exist; on the night it falls back, it
happens twice. `TZDateTime` picks one silently, and this package does not
change that — it resolves *where* a coordinate is, not which of two instants a
local time means. If your application schedules by wall clock across DST
transitions, handle those cases yourself.

### Two things to know

**Initialize from `latest_all`.** This package depends on `package:timezone`'s
engine, never on a tzdata variant. Use
`package:timezone/data/latest_all.dart`: `data/latest.dart` drops the tzdb link
identifiers and carries 341 locations against this dataset's 419, so
`Europe/Zagreb`, `Africa/Accra` and 104 others would fail to resolve.
`findLocation` raises a `StateError` naming the fix if either problem occurs.

**Coordinate order differs, and that is deliberate.** `findId` and
`findLocation` take latitude first, the convention for a pair you type.
`toLocation` reads GeoJSON, which is longitude first — `[2.3522, 48.8566]` is
Paris. You never choose that order: it arrives from the geocoder in the
standard's layout, and reading it is exactly the job this package took over,
because a swapped pair does not throw. It resolves somewhere else and answers
confidently.

## Scope

This package answers one question: *which time zone is this coordinate in?* —
and hands the answer to `package:timezone` in a usable form.

- It resolves coordinates to a zone. **UTC offsets, DST and civil-time
  arithmetic are [`package:timezone`](https://pub.dev/packages/timezone)'s
  work**, and this package does not reimplement them.
- `findId` returns the **identifier**, which is what you store: it stays correct
  when daylight-saving rules change under it, where a stored UTC offset does
  not.
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

The consequence is easiest to see by comparing two stretches of open water.

**A narrow strait resolves.** The Dover Strait is about 42 km across, so the
British and French claims meet in the middle with nothing unclaimed between
them:

```dart
findId(51.1269705, 1.3230653); // Port of Dover   -> Europe/London
findId(50.9744815, 1.8765687); // Port of Calais  -> Europe/Paris
findId(51.050726,  1.599817);  // mid-Channel     -> Europe/Paris
```

That last coordinate is water, and it still resolves — the boundary between the
two zones runs down the middle of the strait, and the midpoint falls just on the
French side of it.

**A wide sea does not.** The Port of Dubrovnik and the Port of Bari face each
other across the Adriatic, 197 km apart. That is far more than two 22 km claims
can span, so the middle belongs to nobody:

```dart
findId(42.6634651, 18.0591377); // Port of Dubrovnik -> Europe/Zagreb
findId(41.137428,  16.8600823); // Port of Bari      -> Europe/Rome
findId(41.900447,  17.459610);  // mid-Adriatic      -> null
```

Both ports are onshore and resolve normally; only the water between them is
unclaimed. The crossover sits somewhere near 100 km of width — sail west along
the Channel as it widens and lookups start returning `null` there too.

So: a `null` tells you no country claims that point. A non-null answer does not
promise you are standing on dry land.

## Resolution, and what it costs

A time zone is a country or a state wide, so deciding which one an address
falls in does not need street-level geometry. The bundled boundaries are
simplified with Douglas-Peucker to **roughly 110 m**, which keeps the whole
package to a few megabytes and a compiled program to about 11 MB.

That simplification is the package's one deliberate loss, and it is measured
rather than estimated. Ten million coordinates, checked against a reference
implementation that reads the unsimplified source geometry directly:

| where the coordinate falls | answers that differ |
| --- | --- |
| anywhere on land, drawn at random | **0.006 %** |
| on a grid-cell edge | 0.1 % |
| inside a disputed-territory overlap | 0.3 % |
| within ~20 km of a zone boundary | 1.4 % |
| beside an enclave boundary | **19 %** |
| on a zone boundary itself | 41 % |
| on the antimeridian seam | **0 %** |

The first row is the address case: 12 differing points in 191,477 drawn
uniformly over land. An independent uniform sampling gave 0.008 %, so treat it
as *about one in fifteen thousand* rather than a precise figure. The sampling
deliberately over-weights borders, so the figure across all ten million points
(17 %) describes the test harness, not the package.

Sampled around 26 real border towns — the realistic worst case for an address
— the answers differ on **0.21 %** of coordinates within 1 km of the town
centre and 0.11 % within 5 km, roughly one address in 500.

All **419 identifiers** are present, and all 273 test fixtures resolve exactly
as the unsimplified geometry does.

**Enclaves are the exception worth knowing about.** Lesotho, Vatican City,
Büsingen and Gibraltar all resolve correctly, because their centres are
unambiguous. But an enclave boundary is short and intricate — precisely what
Douglas-Peucker smooths hardest — and 27 holes collapse entirely at this
tolerance. Beside one of those lines, close to one answer in five differs. If
your coordinates cluster around an enclave border, measure before relying on
this.

Simplification also drops 33 polygons that vanish at this tolerance. For a few
very small islands the result is not a wrong neighbour but **`null`** — Chagos,
Midway and Kiritimati among them.

**If a wrong answer within a few hundred metres of a border would be
expensive** — cargo and customs at a frontier, billing by local time in a split
jurisdiction like Chihuahua — this package is not the right tool, and there is
no higher-resolution option inside it. The unsimplified boundaries exist in the
repository as the baseline these numbers are measured against, but they are
25 MiB compressed and are not published; shipping them would make every
consumer download thirty megabytes for a precision almost none of them need.

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
release, currently **2026c**. `ianaDatabaseVersion` reports it at runtime.

Boundary releases appear two to four times a year and are decoupled from IANA
tzdb releases: most tzdb releases change daylight-saving *rules*, which this
package does not model, and move no boundary. A new package version follows a
boundary release, not a tzdb one.

- A release that changes only geometry gets a **patch** version.
- A release that adds, removes or renames an identifier gets a **minor**
  version and a changelog entry, because it can change an answer you depend on.

## Accuracy

Against the unsimplified source geometry (same quantization, grid and encoder,
no Douglas-Peucker), the pipeline shows **zero disagreements** over ten million
sampled coordinates. Everything the bundled data differs by is the
simplification cost under [Resolution](#resolution-and-what-it-costs).

```sh
dart run tool/differential.dart --index unsimplified   # expects zero
dart run tool/differential.dart --index bundled        # measures the cost
```

## Credits

Boundaries from
[Timezone Boundary Builder](https://github.com/evansiroky/timezone-boundary-builder)
by Evan Siroky, built from [OpenStreetMap](https://www.openstreetmap.org) data.
IANA publishes no official time zone polygons; tzbb is cited as the de facto
source on IANA's own [tz-link](https://data.iana.org/time-zones/tz-link.html)
page.
