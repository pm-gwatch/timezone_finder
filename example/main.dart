// Conference call across five university hospitals.
//
// Shows the whole pipeline this package is built for:
//
//   place name → geocoder → GeoJSON Feature → IANA zone → civil time
//
// Only the first step needs the network. Geocoding is the geocoder's job —
// Nominatim for some hospitals, Photon for others — and from the coordinates
// onward everything runs offline against the bundled boundaries.
//
// Uses dart:io rather than package:http so the example carries no dependency
// the package itself does not have.
//
//     dart run example/main.dart

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:timezone/data/latest_all.dart';
import 'package:timezone/timezone.dart';
import 'package:timezone_finder/timezone_finder.dart';

/// A geocoded place: its display name, and its GeoJSON Feature verbatim.
///
/// The Feature is kept as text rather than unpacked, because unpacking
/// `[longitude, latitude]` by hand is exactly the mistake `toLocation` exists
/// to prevent.
typedef Place = ({String name, String feature});

/// One hospital row for the conference-call table.
typedef HospitalSchedule = ({
  String city,
  String metazone,
  String utcOffset,
  TZDateTime start,
  TZDateTime end,
});

/// Collapses an error body to one readable line. These services report
/// failures as an HTML page, unreadable verbatim and short once flattened.
String _oneLine(String body) {
  final flat = body.replaceAll(RegExp(r'\s+'), ' ').trim();
  return flat.length <= 160 ? flat : '${flat.substring(0, 160)}…';
}

/// Wall-clock formatting for the schedule table.
String _civil(TZDateTime t) {
  final y = t.year.toString().padLeft(4, '0');
  final mo = t.month.toString().padLeft(2, '0');
  final d = t.day.toString().padLeft(2, '0');
  final h = t.hour.toString().padLeft(2, '0');
  final mi = t.minute.toString().padLeft(2, '0');
  return '$y-$mo-$d $h:$mi';
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
/// feature re-encoded as text. The hospital name comes from
/// `properties.name`.
Future<Place> _geocode(Uri uri) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    // Photon answers 403 to Dart's default agent, and Nominatim's usage
    // policy requires identification outright. Send something that names you,
    // and keep to their rate limits — Nominatim allows one request a second.
    request.headers.set(
      HttpHeaders.userAgentHeader,
      'timezone_finder/example/0.1.0 (https://github.com/pm-gwatch/timezone_finder)',
    );
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    if (response.statusCode != HttpStatus.ok) {
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
    // Only used in error messages, so an unnamed feature is not a failure —
    // Nominatim's structured search returns an empty name for some buildings.
    final name = properties['name'];
    return (
      name: name is String && name.isNotEmpty ? name : uri.host,
      feature: jsonEncode(feature),
    );
  } finally {
    client.close();
  }
}

/// Nominatim asks for at most one request per second.
///
/// Call this immediately before every Nominatim request after the first, so
/// the guard stays attached to the call it protects: the Photon requests in
/// between are a different service with a different policy, and reordering
/// them must not silently remove the spacing.
Future<void> _nominatimPause() =>
    Future<void>.delayed(const Duration(seconds: 1));

HospitalSchedule _schedule(
  String city,
  Place place,
  TZDateTime startGeneva,
  Duration length,
) {
  final location = place.feature.toLocation();
  if (location == null) {
    throw StateError('No land time zone for $city (${place.name})');
  }
  final start = startGeneva.convertTo(location);
  final end = startGeneva.add(length).convertTo(location);
  return (
    city: city,
    metazone: start.metazoneName ?? location.metazoneName ?? location.name,
    utcOffset: start.utcOffset,
    start: start,
    end: end,
  );
}

void _printTable(List<HospitalSchedule> rows) {
  final header = <String>[
    'City',
    'Start (local)',
    'End (local)',
    'Metazone',
    'Offset',
  ];
  final body = <List<String>>[
    for (final row in rows)
      <String>[
        row.city,
        _civil(row.start),
        _civil(row.end),
        row.metazone,
        row.utcOffset,
      ],
  ];
  final table = <List<String>>[header, ...body];
  final widths = List<int>.generate(
    header.length,
    (c) => table.map((r) => r[c].length).reduce(math.max),
  );

  String line(List<String> cells) => [
    for (var c = 0; c < cells.length; c++) cells[c].padRight(widths[c]),
  ].join('  ');

  final rule = [for (final w in widths) '-' * w].join('  ');

  print('Conference Call');
  print(rule);
  print(line(header));
  print(rule);
  for (final row in body) {
    print(line(row));
  }
  print(rule);
}

Future<void> main() async {
  initializeTimeZones();

  // Geneva wall clock: Wednesday 16 September 2026, 14:00–14:45.
  const callLength = Duration(minutes: 45);

  late final Place geneva;
  late final Place dublin;
  late final Place istanbul;
  late final Place montreal;
  late final Place tokyo;
  try {
    // Geocode with Photon and Nominatim (GeoJSON Feature):
    // University Hospital Geneva:
    // https://nominatim.openstreetmap.org/search?q=hug+geneva&format=geojson
    geneva = await geocodeWithNominatim('hug geneva');

    // St Vincent's University Hospital, Dublin:
    // https://photon.komoot.io/api/?q=st+vincent+hospital+dublin&limit=1
    dublin = await geocodeWithPhoton('st vincent hospital dublin');

    // Başkent University Istanbul Hospital:
    // https://photon.komoot.io/api/?q=ba%C5%9Fkent+university+istanbul+hospital&limit=1
    istanbul = await geocodeWithPhoton('başkent university istanbul hospital');

    // CHUM, Montreal:
    // https://photon.komoot.io/api/?q=centre+hospitalier+universite+montreal&limit=1
    montreal = await geocodeWithPhoton(
      'centre hospitalier universite montreal',
    );

    // Second Nominatim request, so space it from the first.
    await _nominatimPause();

    // Tokyo Medical University Hospital (structured Nominatim search):
    // https://nominatim.openstreetmap.org/search?amenity=university+hospital&street=nishi+shinjuku+6&city=tokyo&country=japan&format=geojson
    tokyo = await _geocode(
      Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?amenity=${Uri.encodeQueryComponent('university hospital')}'
        '&street=${Uri.encodeQueryComponent('nishi shinjuku 6')}'
        '&city=${Uri.encodeQueryComponent('tokyo')}'
        '&country=${Uri.encodeQueryComponent('japan')}'
        '&format=geojson',
      ),
    );
  } on IOException catch (error) {
    // Only this first step needs the network. Everything after it — the
    // boundary lookup, the zone, the civil time — runs offline.
    stderr
      ..writeln('Geocoding failed, so there are no coordinates to look up.')
      ..writeln(error);
    exitCode = 1;
    return;
  }

  final genevaLocation = geneva.feature.toLocation();
  if (genevaLocation == null) {
    stderr.writeln('No land time zone for ${geneva.name}');
    exitCode = 1;
    return;
  }

  final startGeneva = TZDateTime(genevaLocation, 2026, 9, 16, 14);
  final confCall = <HospitalSchedule>[
    _schedule('Geneva', geneva, startGeneva, callLength),
    _schedule('Dublin', dublin, startGeneva, callLength),
    _schedule('Istanbul', istanbul, startGeneva, callLength),
    _schedule('Montreal', montreal, startGeneva, callLength),
    _schedule('Tokyo', tokyo, startGeneva, callLength),
  ];

  _printTable(confCall);
  print('');
  print('Boundaries for IANA tzdb $ianaDatabaseVersion, CLDR $cldrVersion');
}
