# timezone_finder

An add-on for [`package:timezone`](https://pub.dev/packages/timezone). It turns a point on Earth into a `Location`.

### Split in 1.0.0

Through [0.2.0](https://pub.dev/packages/timezone_finder/versions/0.2.0), this package also converted a `TZDateTime` to another `Location` and gave English time zone names. From 1.0.0 those features live in [`timezone_extensions`](https://pub.dev/packages/timezone_extensions), and `timezone_finder` only finds the `Location`. If you used them, add both packages:

```yaml
dependencies:
  timezone_extensions: ^0.1.0
  timezone_finder: ^1.0.0
```

Then `import 'package:timezone_extensions/timezone_extensions.dart';`. The names are unchanged: `toLocation`, `offsetDifference`, `timeZoneGenericName`, `timeZoneLongName`, `utcOffsetLabel` and `cldrVersion`.

## Initialization

`timezone_finder` is deeply connected to the official `timezone` package, so two datasets have to be ready first:

1. **tzdata** — IANA zone rules, from `package:timezone`. Always load **`latest_all`**. `latest` drops the tzdb link identifiers — 106 of this package's 419 boundary identifiers are missing from it, and a lookup that hits one throws.
2. **Boundaries** — land polygons, from this package. Already compiled in on the VM. On web they are a ~4 MB `.bin` you install once at startup.

On web, import `package:timezone_finder/browser.dart` instead of `package:timezone_finder/timezone_finder.dart`. It is web-only and re-exports the same API. A Flutter app that also targets mobile or desktop should conditionally import `browser.dart` on the same branch that loads the `.bin` — importing it off web is a compile error; using `timezone_finder.dart` on web compiles, then throws at lookup.

### VM, CLI, server, Flutter mobile and desktop

- Import
	- `package:timezone/data/latest_all.dart` and `package:timezone/timezone.dart`
	- `package:timezone_finder/timezone_finder.dart`
- Start the code with
	- `tz.initializeTimeZones()` to load tzdata for the `timezone` package.

```dart
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart';
import 'package:timezone_finder/timezone_finder.dart';

void main() {
  tz.initializeTimeZones();

  final paris = findLocation(2.3522, 48.8566); // Europe/Paris Location
}
```

On a server, `await ensurePreloaded()` at isolate startup if you do not want the first request to pay the decode.

### Dart web

- Import
	- `package:timezone/browser.dart`
	- `package:timezone_finder/browser.dart`
- Start the code with
	- `await tz.initializeTimeZone('packages/timezone/data/latest_all.tzf')`, not `latest.tzf` (default)
	- `await initializeBoundaries()` fetches the `.bin` from `packages/timezone_finder/data/boundaries.bin` without any asset pipeline. Pass a URL to self-host.

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

- Declare the `.bin` in **your app's** `pubspec.yaml`:

```yaml
flutter:
  assets:
    - packages/timezone_finder/data/boundaries.bin
```

The path stays the same across boundary updates, so this entry never needs changing. The `timezone_finder` package does not declare the `.bin` as a Flutter asset, so Android and iOS builds — which use the embedded index — do not carry 4 MB they never read.

- Import
	- `package:timezone/browser.dart`
	- `package:timezone_finder/browser.dart`
- Start the code with
	- `await tz.initializeTimeZone('packages/timezone/data/latest_all.tzf')`, not `latest.tzf` (default)
	- `installBoundaries(...)` from `rootBundle`

```dart
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:timezone/browser.dart' as tz;
import 'package:timezone_finder/browser.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await tz.initializeTimeZone('packages/timezone/data/latest_all.tzf');

  final data = await rootBundle.load(
    'packages/timezone_finder/data/boundaries.bin',
  );
  installBoundaries(data.buffer.asUint8List());

  final paris = findLocation(2.3522, 48.8566); // Europe/Paris Location

  runApp(const MyApp());
}
```

`findLocation`, `ensurePreloaded`, and `boundaryDataVersion` throw a `StateError` until the `.bin` is installed. Installing the same data version again still decodes the bytes but does not replace the index; a different version replaces it. `initializeBoundaries` fetch failures throw `BoundariesInitException`; corrupt bytes throw `IndexFormatException`.

## API

After initialization, the surface is small. Argument order is GeoJSON: **longitude, then latitude**.

### 🎯 Find a `Location`

`null` means no land polygon covers the point. Coastal belts extend ~22 km offshore, so a narrow strait often resolves and open ocean does not. Bad coordinates throw `ArgumentError`. Missing tzdata, `latest` instead of `latest_all`, or a web lookup before install throw `StateError`. `null` is never an error.

```dart
final home = findLocation(-118.6884215, 34.0327862)!; // America/Los_Angeles Location
final hotel = findLocation(151.2430457, -33.8760146)!; // Australia/Sydney Location
```

To convert that `Location` to another clock, or to read its labels, add
[`timezone_extensions`](https://pub.dev/packages/timezone_extensions).

Shipped data version: `boundaryDataVersion` (Timezone Boundary Builder release). It is independent of the tzdb version inside `package:timezone`.

## Data used

| Dataset | Source | What it answers |
| --- | --- | --- |
| Land polygons | [Timezone Boundary Builder](https://github.com/evansiroky/timezone-boundary-builder) from [OpenStreetMap](https://www.openstreetmap.org) | Which IANA zone contains this longitude/latitude |
| Zone rules | `package:timezone` (IANA tzdb) | Offsets, DST, abbreviations |

Coordinates come from wherever you already have them — a GPS fix, a map tap, a database column. From an address, [Nominatim](https://nominatim.org/release-docs/latest/api/Search/) and [Photon](https://photon.komoot.io) return a `FeatureCollection`; pick a feature and pass its Point coordinates to `findLocation`.

## Licenses

- **Code** — MIT ([`LICENSE`](https://github.com/pm-gwatch/timezone_finder/blob/main/LICENSE)).
- **Boundary data** — ODbL v1.0 ([`LICENSE-DATA`](https://github.com/pm-gwatch/timezone_finder/blob/main/LICENSE-DATA)). Share-alike: if you publicly ship an *adapted* database, offer that adapted database under ODbL too.

If you redistribute the boundary data (or a work produced from it), include:

> Time zone boundary data © OpenStreetMap contributors, available under the Open Database License (ODbL). Boundaries built by [Timezone Boundary Builder](https://github.com/evansiroky/timezone-boundary-builder).

IANA publishes no official polygons; [tz-link](https://data.iana.org/time-zones/tz-link.html) cites TZBB as the de facto source. TZBB is by Evan Siroky, built from [OpenStreetMap](https://www.openstreetmap.org) data.
