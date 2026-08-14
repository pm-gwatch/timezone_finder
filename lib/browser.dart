/// Web / Flutter web entry: install the packed `.bin`, then use the same API
/// as `package:timezone_finder/timezone_finder.dart`.
///
/// **Web only** — like `package:timezone/browser.dart`. Do not import both;
/// this library re-exports the main API. Conditionally import it on the same
/// branch that loads the `.bin`. VM / CLI / server / Flutter mobile and
/// desktop use `timezone_finder.dart` (boundaries are embedded).
///
/// Before [findLocation]: `latest_all` tzdata **and** this `.bin`. Prefer
/// [installBoundaries] when you already have bytes. [initializeBoundaries]
/// fetches [boundariesDefaultUrl] (`<base href>` and asset hosting matter).
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
/// Flutter web: declare [boundariesDefaultUrl] under `flutter: assets:` in
/// **your** pubspec, then `installBoundaries` from `rootBundle`. Self-host
/// with `initializeBoundaries('https://cdn.example.com/$boundariesBinName')`.
library;

import 'dart:js_interop';
import 'dart:typed_data';

import 'package:web/web.dart';

import 'src/generated/boundaries_bin.dart';
import 'src/exceptions.dart';
import 'src/index/boundary_store.dart' show installBoundaries;

export 'src/generated/boundaries_bin.dart'
    show boundariesBinName, boundariesDefaultUrl;
export 'src/exceptions.dart' show BoundariesInitException, IndexFormatException;
export 'src/index/boundary_store.dart' show installBoundaries;
export 'timezone_finder.dart';

/// Fetches [url] then [installBoundaries]. Prefer bytes when you already have
/// them.
///
/// Defaults to [boundariesDefaultUrl]. Wrong length (often an HTML 404) throws
/// [BoundariesInitException]; well-sized but corrupt bytes throw
/// [IndexFormatException].
Future<void> initializeBoundaries([String url = boundariesDefaultUrl]) async {
  try {
    final response = await window.fetch(url.toJS).toDart;
    if (!response.ok) {
      throw BoundariesInitException(
        'Request failed with status: ${response.status}',
      );
    }
    final jsBytes = await response.bytes().toDart;
    final bytes = Uint8List.fromList(jsBytes.toDart);
    if (bytes.length != boundariesBinLength) {
      throw BoundariesInitException(
        'Fetched ${bytes.length} bytes from $url, expected '
        '$boundariesBinLength ($boundariesBinName)',
      );
    }
    installBoundaries(bytes);
  } on BoundariesInitException {
    rethrow;
  } on IndexFormatException {
    rethrow;
  } catch (e) {
    throw BoundariesInitException(e.toString());
  }
}
