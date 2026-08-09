/// Browser / Flutter web entry: install the packed boundary index, then use
/// the same API as `package:timezone_finder/timezone_finder.dart`.
///
/// Web needs **two** inits before [findLocation]: `latest_all` tzdata (so
/// identifiers become [Location]s) and this package's `.bin` (so coordinates
/// become identifiers). Skip either and the first lookup throws a [StateError]
/// naming it. On the VM the index is already embedded; importing this library
/// there is fine — only [initializeBoundaries] is web-only.
///
/// Prefer [installBoundaries] when you have bytes (Flutter `rootBundle`, CDN,
/// cache). [initializeBoundaries] fetches [boundariesDefaultUrl] and is
/// sensitive to `<base href>` and how the host serves package assets.
///
/// ```dart
/// import 'package:timezone/browser.dart' as tz;
/// import 'package:timezone_finder/browser.dart';
///
/// Future<void> main() async {
///   await tz.initializeTimeZone('packages/timezone/data/latest_all.tzf');
///   await initializeBoundaries();
///   findLocation(2.3522, 48.8566)?.name; // 'Europe/Paris'
/// }
/// ```
///
/// Flutter web: declare `packages/timezone_finder/data/boundaries_2026c.bin`
/// under `flutter: assets:` in **your** pubspec — that path is
/// [boundariesDefaultUrl], and the filename alone is [boundariesBinName].
///
/// ```dart
/// Future<void> main() async {
///   WidgetsFlutterBinding.ensureInitialized(); // required before rootBundle
///   await tz.initializeTimeZone('packages/timezone/data/latest_all.tzf');
///   final data = await rootBundle.load(boundariesDefaultUrl);
///   installBoundaries(data.buffer.asUint8List());
///   runApp(const MyApp());
/// }
/// ```
///
/// Self-hosting the `.bin` elsewhere: copy it and pass your own URL, e.g.
/// `initializeBoundaries('https://cdn.example.com/$boundariesBinName')`.
library;

import 'src/boundaries_bin.dart';
import 'src/fetch_stub.dart'
    if (dart.library.js_interop) 'src/fetch_web.dart'
    as fetch_impl;
import 'src/install.dart';

export 'src/boundaries_bin.dart' show boundariesBinName, boundariesDefaultUrl;
export 'src/install.dart' show BoundariesInitException, installBoundaries;
export 'src/index.dart' show IndexFormatException;
export 'timezone_finder.dart';

/// Fetches the packed `.bin` from [url] and [installBoundaries].
///
/// Defaults to [boundariesDefaultUrl]. Prefer [installBoundaries] when you
/// already have bytes.
///
/// The response must be exactly the `.bin` shipped with this package version
/// (wrong length is rejected — usually an HTML 404). Network / HTTP / size
/// failures throw [BoundariesInitException]; well-sized but corrupt bytes throw
/// [IndexFormatException].
///
/// Off web, throws [BoundariesInitException] directing you to
/// [installBoundaries].
Future<void> initializeBoundaries([String url = boundariesDefaultUrl]) =>
    fetch_impl.initializeBoundaries(url);
