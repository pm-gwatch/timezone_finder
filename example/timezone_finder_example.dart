// One flight, across four and a half hours of offset.
//
// Shows the whole pipeline this package is built for:
//
//   place name → geocoder → GeoJSON Feature → IANA zone → civil time
//
// Only the first step needs the network. Geocoding is the geocoder's job —
// Nominatim for one airport, Photon for the other, to show that either will
// do — and from the coordinates onward everything runs offline against the
// bundled boundaries.
//
// Uses dart:io rather than package:http so the example carries no dependency
// the package itself does not have.

import 'dart:convert';
import 'dart:io';

import 'package:timezone/data/latest_all.dart';
import 'package:timezone/timezone.dart';
import 'package:timezone_finder/timezone_finder.dart';

/// A geocoded place: its display name, and its GeoJSON Feature verbatim.
///
/// The Feature is kept as text rather than unpacked, because unpacking
/// `[longitude, latitude]` by hand is exactly the mistake `toLocation` exists
/// to prevent.
typedef Place = ({String name, String feature});

/// Collapses an error body to one readable line. These services report
/// failures as an HTML page, unreadable verbatim and short once flattened.
String _oneLine(String body) {
  final flat = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  return flat.length <= 160 ? flat : '${flat.substring(0, 160)}…';
}

/// Looks [query] up in Nominatim, OpenStreetMap's own geocoder.
Future<Place> geocodeWithNominatim(String query) => _geocode(
  Uri.parse(
    'https://nominatim.openstreetmap.org/search'
    '?q=${Uri.encodeQueryComponent(query)}&format=geojson',
  ),
);

/// Looks [query] up in Photon, a second geocoder over the same OSM data.
Future<Place> geocodeWithPhoton(String query) => _geocode(
  Uri.parse(
    'https://photon.komoot.io/api/'
    '?q=${Uri.encodeQueryComponent(query)}&limit=1',
  ),
);

/// Fetches [uri] and returns the first GeoJSON feature.
///
/// One parser serves both services: they answer with the same shape, a
/// `FeatureCollection` of Features. `toLocation` takes one Feature, not the
/// collection — a collection is several places — so this hands back a single
/// feature re-encoded as text.
Future<Place> _geocode(Uri uri) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    // Photon answers 403 to Dart's default agent, and Nominatim's usage
    // policy requires identification outright. Send something that names you,
    // and keep to their rate limits — Nominatim allows one request a second.
    request.headers.set(
      HttpHeaders.userAgentHeader,
      'timezone_finder-example/0.1.0 (https://github.com/pm-gwatch/timezone_finder)',
    );
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    if (response.statusCode != HttpStatus.ok) {
      // Report what the server said, not just that something went wrong: a
      // 403 from a missing user agent and a 429 from rate limiting need
      // different fixes, and the body usually says which.
      throw HttpException(
        '${uri.host} returned ${response.statusCode} '
        '${response.reasonPhrase}\n'
        '  request: $uri\n'
        '  body:    ${_oneLine(text)}',
      );
    }
    final body = jsonDecode(text) as Map<String, dynamic>;
    final features = body['features'] as List<dynamic>;
    if (features.isEmpty) {
      throw HttpException('No match from ${uri.host}', uri: uri);
    }

    final feature = features.first as Map<String, dynamic>;
    final properties = feature['properties'] as Map<String, dynamic>;

    return (name: properties['name'] as String, feature: jsonEncode(feature));
  } finally {
    client.close();
  }
}

Future<void> main() async {
  initializeTimeZones();

  final Place lhr;
  final Place bom;
  try {
    lhr = await geocodeWithNominatim('london heathrow airport');
    bom = await geocodeWithPhoton('mumbai international airport');
  } on IOException catch (error) {
    // Only this first step needs the network. Everything after it — the
    // boundary lookup, the zone, the civil time — runs offline.
    stderr
      ..writeln('Geocoding failed, so there are no coordinates to look up.')
      ..writeln(error);
    exitCode = 1;
    return;
  }
  // BA 139, London Heathrow to Mumbai, Monday 3 August 2026. It leaves at
  // 09:40 and lands at 23:40 — but that is 14 hours only because the two
  // times are read off different clocks. 9h30 of it is the flight; the other
  // 4h30 is India's offset from British Summer Time.
  //
  // Each geocoded Feature becomes a Location, then inLocation re-expresses
  // the arrival instant as Mumbai reads it, without moving the moment itself.
  final heathrow = lhr.feature.toLocation()!;
  final mumbai = bom.feature.toLocation()!;

  final takeOff = TZDateTime(heathrow, 2026, 8, 3, 9, 40);
  final arrival = takeOff
      .add(const Duration(hours: 9, minutes: 30))
      .inLocation(mumbai);

  print('-- Example 1 ------------------------------');
  print(
    'Flight BA139 from ${lhr.name} (LHR)\n'
    'to ${bom.name} (BOM)\n'
    'on 3 August 2026 at 09:40 AM (local time) \n'
    'with a duration of 9 hours and 30 minutes:',
  );
  print('');

  print('LHR -> ${heathrow.name}   (via Nominatim)');
  print('BOM -> ${mumbai.name}   (via Photon)');
  print('');

  // Same flight from both ends. `inLocation` does not move the instant — it
  // reports the one arrival moment as the clocks in Mumbai read it.
  print('BA 139 departs LHR -> $takeOff');
  print('BA 139 arrives BOM -> $arrival');
  print('-------------------------------------------');
  print('');
  print(
    'Boundaries for IANA tzdb $ianaDatabaseVersion, '
    '${availableTimeZoneIds.length} zones',
  );
}
