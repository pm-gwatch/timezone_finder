# timezone_finder

> 🎯 **Add-on for [`package:timezone`](https://pub.dev/packages/timezone):** find the `Location` for a point on Earth; add metazone labels and multi-place helpers to the `Location` and `TZDateTime` you already hold.

**Where you run it**

- **VM, CLI, server, Flutter mobile and desktop** — import `package:timezone_finder/timezone_finder.dart`. Boundaries are embedded; no install step.
- **Web and Flutter web** — import `package:timezone_finder/browser.dart` and install the packed `.bin` before any lookup (see [Web / Flutter web](#web--flutter-web)). Copy-pasting the VM sample onto web will throw.

## What you get

- **OpenStreetMap borders** (Timezone Boundary Builder) → IANA zone for a longitude/latitude or GeoJSON Point, offline — no network
- **IANA tzdb** (via `package:timezone`) → offsets, DST, and abbreviations on real `Location` / `TZDateTime` values
- **Unicode CLDR** → English metazone names (*Pacific Time*, *Central European Summer Time*, …).
- **Extensions**, not new classes — nothing to construct, no wrapper types; facts live on `Location` and `TZDateTime` (`String.toLocation`, `Location.metazoneName`, `TZDateTime.convertTo`, …)

A **metazone** is CLDR's grouping of zones that share a display name: Paris, Madrid and Zurich are all *Central European Time*.

```text
longitude, latitude    ─┐                                  local time
                        ├─→  Location  ─→  TZDateTime  ─→  metazone name
GeoJSON Point/Feature  ─┘                                  abbreviation
```

Coordinates come from wherever you already have them — a GPS fix, a map tap, a database column. If you start from an address, [Nominatim](https://nominatim.org/release-docs/latest/api/Search/) and [Photon](https://photon.komoot.io) are OpenStreetMap-based geocoders whose answers are GeoJSON, which `toLocation` reads directly.

**Coordinates only** (VM / mobile / desktop / CLI) — needs `latest_all` so the
IANA id can become a `Location` (`Location.name` is that identifier):

```dart
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone_finder/timezone_finder.dart';

tz.initializeTimeZones();

findLocation(2.3522, 48.8566)?.name; // 'Europe/Paris' — longitude, latitude
findLocation(-140.0, 0.0);           // null — no land polygon
```

**With GeoJSON and multi-place helpers:**

```dart
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone_finder/timezone_finder.dart';

tz.initializeTimeZones();          // required before any Location exists

// GeoJSON from Nominatim (ask for it: &format=geojson) or Photon (default).
// Coordinates are [longitude, latitude].
const cdg = '{"type": "Point", "coordinates": [2.5479, 49.0097]}';
const jfk = '{"type": "Point", "coordinates": [-73.7781, 40.6413]}';

final paris = cdg.toLocation()!;         // a Location, straight from GeoJSON
paris.name;                              // 'Europe/Paris' — store this
paris.metazoneName;                      // 'Central European Time'

final takeOff = tz.TZDateTime(paris, 2026, 8, 23, 10, 15);
final landing = takeOff.add(const Duration(hours: 8, minutes: 20));
final jfkLoc = jfk.toLocation()!;

// convertTo returns a new value; landing stays in Paris (CEST).
final atJfk = landing.convertTo(jfkLoc); // 12:35 at JFK — same instant
takeOff.utcOffsetDifference(jfkLoc);     // -6 hours (signed; JFK behind Paris)
atJfk.metazoneName;                      // 'Eastern Daylight Time'
atJfk.metazoneAbbreviation;              // 'EDT'
atJfk.utcOffset;                         // 'UTC-04'
```

## API

**Top-level — from coordinates, synchronous, offline (after tzdata init):**

- `findLocation(longitude, latitude)` → a `Location`, or `null` when no land polygon covers the point. `Location.name` is the IANA identifier to **store**.
- `'{"type":"Point",…}'.toLocation()` → the same, from a geocoder's GeoJSON
- `ensurePreloaded()` — decode the index at startup (**once per isolate**) instead of on first use
- `ianaDatabaseVersion`, `cldrVersion`

**On `Location`** — a place, so nothing here depends on an instant:

- `metazoneName` → *Pacific Time* (English). Season-neutral by design; `null` for nine zones CLDR leaves unnamed. There is deliberately no abbreviation: every tzdb abbreviation is either standard or daylight, so a place could only ever answer for half the year.

**On `TZDateTime`** — a place *and* a moment:

- `convertTo(location)` → the same instant, on another clock
- `utcOffsetDifference(location)` → signed UTC-offset gap at this instant (positive = other place ahead); not `TZDateTime.difference` (elapsed time). Use `.abs()` for a directionless magnitude
- `utcOffset` → `UTC-07` / `UTC+04:30` / `UTC` — always the numeric offset form, never a letter abbreviation like `PDT`
- `metazoneName` → *Pacific Daylight Time* — English, standard or daylight, at this instant; `null` where CLDR has no name
- `metazoneAbbreviation` → `PDT`, or `UTC+04:30` when tzdb's value is numeric (always a `String` — tzdb names every instant)

## Web / Flutter web

On web the index is **not** embedded as Dart source. Hand the packed `.bin` (~4.01 MB) to `installBoundaries` before any lookup — however your app gets bytes: an asset bundle, your own CDN, a cache. The filename tracks the boundary data release (`boundaries_<ianaDatabaseVersion>.bin`, currently `boundaries_2026c.bin`) — **so a boundary release changes the path your app declares and loads**, and an upgrade that skips it fails at the fetch or the asset lookup, not at compile time.

**Flutter web.** Declare the asset in **your app's** `pubspec.yaml`. The package deliberately does not declare it, so Android and iOS builds — which use the embedded index — do not carry 4 MB they never read:

```yaml
flutter:
  assets:
    - packages/timezone_finder/data/boundaries_2026c.bin
```

```dart
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:timezone/browser.dart' as tz;
import 'package:timezone_finder/browser.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized(); // required before rootBundle
  await tz.initializeTimeZone('packages/timezone/data/latest_all.tzf');

  final data = await rootBundle.load(
    'packages/timezone_finder/data/boundaries_2026c.bin',
  );
  installBoundaries(data.buffer.asUint8List());

  final myLocation = findLocation(2.3522, 48.8566); // Europe/Paris Location
  
  runApp(const MyApp());
}
```

**Dart web** — including [Jaspr](https://pub.dev/packages/jaspr) and other non-Flutter browser apps — has no `rootBundle` asset pipeline, so fetch the package asset instead. `initializeBoundaries` is a convenience wrapper around fetch + install; the default `packages/…` URL depends on `<base href>` and on your host serving the package tree, so prefer `installBoundaries` once you have somewhere to put the file:

```dart
import 'package:timezone/browser.dart' as tz;
import 'package:timezone_finder/browser.dart';

Future<void> main() async {
  await tz.initializeTimeZone('packages/timezone/data/latest_all.tzf');
  await initializeBoundaries();

  final myLocation = findLocation(2.3522, 48.8566); // Europe/Paris Location
}
```

Lookups or `ensurePreloaded` before install throw a `StateError` naming `installBoundaries`. A second `installBoundaries` with the same data version is a no-op; a different version replaces the installed index. Fetch failures throw `BoundariesInitException`; corrupt bytes throw `IndexFormatException`.

[`example/server/`](https://github.com/pm-gwatch/timezone_finder/tree/main/example/server) is a Shelf departure-board demo (VM server, not a browser app). The snippets above are the browser init recipe.

## Before you start

- **Initialize `latest_all`, never `latest`.** `latest` omits the tzdb link identifiers — 341 locations against this dataset's 419 — so `findLocation` throws a `StateError` for the other 106. The call differs by target, and so does its name:
	- **VM, CLI, server, Flutter mobile and desktop** — import `package:timezone/data/latest_all.dart`, then `initializeTimeZones()` — plural, synchronous, no argument.
	- **Web and Flutter web** — import `package:timezone/browser.dart`, then `await initializeTimeZone('packages/timezone/data/latest_all.tzf')` — singular, async. **The default path fetches `latest.tzf`**, so that argument is not optional. Also install boundaries (see [Web / Flutter web](#web--flutter-web)).

    To avoid the fetch and the name difference entirely, the VM form works on web too: `package:timezone/data/latest_all.dart` compiles there and `initializeTimeZones()` stays synchronous. It costs about 1.4 MB more JavaScript than fetching the `.tzf`, which is why fetching is the default advice here.

- **Coordinates are longitude first, everywhere.** `findLocation` and `toLocation` take `(longitude, latitude)` / GeoJSON `[longitude, latitude]` — `[2.3522, 48.8566]` is Paris.
- **Pass one feature, not the whole geocoder response.** Nominatim and Photon both answer with a `FeatureCollection`, which is several places; `toLocation` takes a single `Feature` or a bare `Point` and rejects the collection, because choosing among matches is your decision.
- **`null` means no land polygon covers the point**, which is not quite "at sea": coastal zones extend ~22 km offshore, so narrow straits resolve and wide seas do not. It means *only* that — malformed GeoJSON throws `FormatException` and a position off the Earth throws `ArgumentError`, so `null` is never ambiguous.

## Good to know

- Boundaries are simplified to **~110 m**; random land coordinates disagree with the unsimplified source **0.006 %** of the time, more beside enclaves.
- **Disputed territories:** 25 zone pairs overlap. One identifier is returned by an arbitrary deterministic rule. **No answer is a statement about sovereignty.**
- The boundary index ships inside the package — that is what buys the offline lookup. The published archive is about **7 MB** because both forms ship: base64 chunks for VM/native (embedded at compile time) and a packed `.bin` for web (installed at runtime). Each consumer only *uses* one of them.
- **Ambiguous and nonexistent wall-clock times are out of scope.** On the night a zone springs forward 02:30 does not exist; on the night it falls back it happens twice. `TZDateTime` picks one silently, and this package does not change that — it resolves *where* a coordinate is, not which of two instants a local time means.

## Licences and attribution

- **Code** — MIT ([`LICENSE`](https://github.com/pm-gwatch/timezone_finder/blob/main/LICENSE)).
- **Boundary data** — ODbL v1.0 ([`LICENSE-DATA`](https://github.com/pm-gwatch/timezone_finder/blob/main/LICENSE-DATA)). Share-alike: if you publicly ship an *adapted* database, offer that adapted database under ODbL too.
- **Metazone strings** — Unicode License v3 ([`LICENSE-CLDR`](https://github.com/pm-gwatch/timezone_finder/blob/main/LICENSE-CLDR)).

If you redistribute the boundary data (or a work produced from it), include:

> Time zone boundary data © OpenStreetMap contributors, available under the Open Database License (ODbL). Boundaries built by [Timezone Boundary Builder](https://github.com/evansiroky/timezone-boundary-builder).

IANA publishes no official polygons; [tz-link](https://data.iana.org/time-zones/tz-link.html) cites TZBB as the de facto source. TZBB is by Evan Siroky, built from [OpenStreetMap](https://www.openstreetmap.org) data.
