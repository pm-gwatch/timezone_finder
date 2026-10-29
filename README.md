# timezone_finder

An add-on for [`package:timezone`](https://pub.dev/packages/timezone). It turns a point on Earth into a `Location`.

## Split in 1.0.0

Up to [0.2.0](https://pub.dev/packages/timezone_finder/versions/0.2.0), this package also converted a `TZDateTime` to another `Location` and gave English time zone names. Those features moved to [`timezone_extensions`](https://pub.dev/packages/timezone_extensions). If you used them, add both packages:

```yaml
dependencies:
  timezone_extensions: ^0.1.0
  timezone_finder: ^1.0.1
```

## Initialization

Two datasets have to be ready before a lookup:

1. **tzdata** — IANA zone rules, from `package:timezone`. Load **`latest_all`**. `latest` drops the tzdb link identifiers. 106 of this package's 419 boundary identifiers are missing from it, and a lookup that resolves to one of those identifiers throws.
2. **Boundaries** — land polygons, from this package. They are compiled into the VM, CLI, server, and Flutter mobile and desktop libraries. On the web they are a ~4 MB `.bin` you install once at startup.

`package:timezone_finder/timezone_finder.dart` exports the lookup API. On the web, import `package:timezone_finder/browser.dart` instead. That library is web-only. It exports the same lookup API, plus the functions that install the `.bin`. Importing `browser.dart` off the web is a compile error. Importing `timezone_finder.dart` on the web compiles, and then `findLocation`, `ensurePreloaded`, and `boundaryDataVersion` throw `StateError` because the `.bin` is not embedded.

A Flutter app that also targets mobile or desktop should conditionally import `browser.dart` on the same branch that loads the `.bin`.

### VM, CLI, server, Flutter mobile and desktop

Import `package:timezone/data/latest_all.dart`, `package:timezone/timezone.dart`, and `package:timezone_finder/timezone_finder.dart`. Call `tz.initializeTimeZones()` before any lookup that returns a `Location`.

```dart
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart';
import 'package:timezone_finder/timezone_finder.dart';

void main() {
  tz.initializeTimeZones();

  final paris = findLocation(2.3522, 48.8566); // Europe/Paris Location
}
```

On a server, call `await ensurePreloaded()` in each isolate at startup. That moves the container decode off the first request. Ring coordinates are still read on the lookup that needs them. Details are under [`ensurePreloaded`](#futurevoid-ensurepreloaded).

### Dart web

Import `package:timezone/browser.dart` and `package:timezone_finder/browser.dart`. Load `latest_all.tzf` by path. The default fetch is `latest.tzf`. Then fetch and install the `.bin` with `initializeBoundaries`. Its default URL is `packages/timezone_finder/data/boundaries.bin?v=2026e`. Pass another URL to self-host.

The deployed site has to serve `packages/`. `webdev serve`, `dart test -p chrome`, and `build_web_compilers` do. `dart compile js` by itself does not. That covers both the tzdata path and the default URL of `initializeBoundaries`.

```dart
import 'package:timezone/browser.dart' as tz;
import 'package:timezone_finder/browser.dart';

Future<void> main() async {
  await tz.initializeTimeZone('packages/timezone/data/latest_all.tzf');
  await initializeBoundaries();

  final paris = findLocation(2.3522, 48.8566); // Europe/Paris Location
}
```

### Flutter web

Declare both files in the app's `pubspec.yaml`. Flutter serves an asset under `assets/`, so `initializeTimeZone` cannot fetch `packages/timezone/data/latest_all.tzf`. Load each file with `rootBundle`.

```yaml
flutter:
  assets:
    - packages/timezone/data/latest_all.tzf
    - packages/timezone_finder/data/boundaries.bin
```

The `.bin` path stays the same across boundary updates. This package does not declare that file as a Flutter asset, so an app that never lists it does not ship those 4 MB. An app that lists it bundles the file on every target, including Android and iOS, which still look up zones from the embedded index.

Import `package:timezone/timezone.dart` and `package:timezone_finder/browser.dart`.

```dart
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:timezone/timezone.dart';
import 'package:timezone_finder/browser.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final tzdata = await rootBundle.load(
    'packages/timezone/data/latest_all.tzf',
  );
  initializeDatabase(
    tzdata.buffer.asUint8List(tzdata.offsetInBytes, tzdata.lengthInBytes),
  );

  final data = await rootBundle.load(
    'packages/timezone_finder/data/boundaries.bin',
  );
  installBoundaries(
    data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
  );

  final paris = findLocation(2.3522, 48.8566); // Europe/Paris Location

  runApp(const MyApp());
}
```

`findLocation`, `ensurePreloaded`, and `boundaryDataVersion` throw `StateError` until `installBoundaries` has run.

## API

`timezone_finder.dart` exports:
- `findLocation`,
- `ensurePreloaded`, and
- `boundaryDataVersion`.

`browser.dart` re-exports those three. Furthermore, `initializeBoundaries` throws `BoundariesInitException` when the fetch fails or the body has the wrong length, and corrupt bytes throw `IndexFormatException`.

### `Location? findLocation(double longitude, double latitude)`

Argument order is GeoJSON: longitude, then latitude.

The result is the `package:timezone` `Location` whose land polygon contains the point. `Location.name` is the IANA identifier. `null` means no land polygon covers the point. Coastal belts extend ~22 km offshore, so a narrow strait often resolves and open ocean does not. `null` is a normal answer. A point with no land zone does not need tzdata.

A longitude outside `-180` to `180`, a latitude outside `-90` to `90`, or a NaN or infinite value throws `ArgumentError`.

`findLocation` throws `StateError` in three cases:

- tzdata was never initialized, and the point lies in a land zone
- the initialized database has no `Location` for the zone that was found (`latest` instead of `latest_all`, or an older `latest_all`)
- on the web, the `.bin` is not installed yet. This throws for every call, including a point that would otherwise return `null`

```dart
final departureLocation = findLocation(-118.6884215, 34.0327862); // America/Los_Angeles
final arrivalLocation = findLocation(151.2430457, -33.8760146); // Australia/Sydney
```

### `Future<void> ensurePreloaded()`

This decodes the container and the polygon table (1,155 polygons in the current index). Ring coordinates stay packed until the lookup that needs them. A second call in the same isolate does not decode the container again. Each isolate has its own index, so call it in each isolate that should pay the cost at startup.

On the VM, CLI, server, and Flutter mobile and desktop, the index stays packed until the first `findLocation` or the first read of `boundaryDataVersion`. `await ensurePreloaded()` moves that container decode to startup, which is what a server wants so the first request does not pay it. The first lookup in a region still reads that region's rings.

On the web, `installBoundaries` and `initializeBoundaries` already decode the `.bin`. `ensurePreloaded` after either of them does not decode again. `ensurePreloaded` before the `.bin` is installed throws `StateError`. A web app installs the bytes during startup and does not need this call.

### `String get boundaryDataVersion`

The Timezone Boundary Builder release for the borders in this package, such as `'2026e'`. This getter does not report the tzdb release inside `package:timezone`. A boundary update can ship without a new tzdb, and a tzdb update can ship without new borders.

Reading it decodes the index on the VM. On the web it throws `StateError` until the `.bin` is installed.

## Data used

| Dataset | Source | What it answers |
| --- | --- | --- |
| Land polygons | [Timezone Boundary Builder](https://github.com/evansiroky/timezone-boundary-builder) from [OpenStreetMap](https://www.openstreetmap.org) | Which IANA zone contains this longitude/latitude |
| Zone rules | `package:timezone` (IANA tzdb) | Offsets, DST, abbreviations |

Coordinates come from wherever you already have them: a GPS fix, a map tap, a database column. From an address, [Nominatim](https://nominatim.org/release-docs/latest/api/Search/) and [Photon](https://photon.komoot.io) return a `FeatureCollection`. Pick a feature and pass its Point coordinates to `findLocation`.

## Licenses

- **Code** — MIT ([`LICENSE`](https://github.com/pm-gwatch/timezone_finder/blob/main/LICENSE)).
- **Boundary data** — ODbL v1.0 ([`LICENSE-DATA`](https://github.com/pm-gwatch/timezone_finder/blob/main/LICENSE-DATA)). Share-alike: if you publicly ship an adapted database, offer that adapted database under ODbL too.

If you redistribute the boundary data (or a work produced from it), include:

> Time zone boundary data © OpenStreetMap contributors, available under the Open Database License (ODbL). Boundaries built by [Timezone Boundary Builder](https://github.com/evansiroky/timezone-boundary-builder).

IANA publishes no official polygons. [tz-link](https://data.iana.org/time-zones/tz-link.html) cites Timezone Boundary Builder as the de facto source. Timezone Boundary Builder is by Evan Siroky, built from [OpenStreetMap](https://www.openstreetmap.org) data.
