// Conference call across four university hospitals.
//
// Shows the whole pipeline this package is built for:
//
//   place name → geocoder → GeoJSON Feature → IANA zone → civil time

import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart';
import 'package:timezone_finder/timezone_finder.dart';

typedef Place = ({String name, String feature});

typedef TimeSlot = ({
  String city,
  TZDateTime localStartTime,
  TZDateTime localEndTime,
});

String _civil(TZDateTime t) {
  final y = t.year.toString().padLeft(4, '0');
  final mo = t.month.toString().padLeft(2, '0');
  final d = t.day.toString().padLeft(2, '0');
  final h = t.hour.toString().padLeft(2, '0');
  final mi = t.minute.toString().padLeft(2, '0');
  return '$y-$mo-$d $h:$mi';
}

/// Nominatim free-text search.
Future<Place> searchWithNominatim(String query) => _geocode(
  Uri.parse(
    'https://nominatim.openstreetmap.org/search'
    '?q=${Uri.encodeQueryComponent(query)}&limit=1&format=geojson',
  ),
);

/// Nominatim structured search.
Future<Place> advancedSearchWithNominatim(
  Map<String, dynamic> queryComponents,
) => _geocode(
  Uri.parse(
    'https://nominatim.openstreetmap.org/search'
    '?${queryComponents.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&')}&limit=1&format=geojson',
  ),
);

/// Fetches [uri] and returns the first GeoJSON feature.
///
/// Nominatim returns a FeatureCollection; [GeoJsonLocation.findLocation] wants
/// one Feature. Hospital name comes from `properties.name`.
Future<Place> _geocode(Uri uri) async {
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    // Nominatim rejects stock library User-Agents.
    request.headers.set(
      HttpHeaders.userAgentHeader,
      'timezone_finder/example/0.2.0 (https://github.com/pm-gwatch/timezone_finder)',
    );
    final response = await request.close();
    final text = await response.transform(utf8.decoder).join();
    final bodyPreview = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (response.statusCode != HttpStatus.ok) {
      throw HttpException(
        '${uri.host} returned ${response.statusCode} '
        '${response.reasonPhrase}\n'
        '  request: $uri\n'
        '  body:    ${bodyPreview.substring(0, math.min(bodyPreview.length, 160))}',
      );
    }
    final body = jsonDecode(text) as Map<String, dynamic>;
    final features = body['features'] as List<dynamic>;
    if (features.isEmpty) {
      throw HttpException('No match from ${uri.host}', uri: uri);
    }

    final feature = features.first as Map<String, dynamic>;
    final properties = feature['properties'] as Map<String, dynamic>;
    // Display-only: Nominatim structured search sometimes omits the name.
    final name = properties['name'];
    return (
      name: name is String && name.isNotEmpty ? name : uri.host,
      feature: jsonEncode(feature),
    );
  } finally {
    client.close();
  }
}

/// Nominatim allows at most one request per second.
Future<void> _nominatimPause() =>
    Future<void>.delayed(const Duration(seconds: 1));

TimeSlot _schedule(
  String city,
  Place place,
  TZDateTime start,
  Duration length,
) {
  final location = place.feature.findLocation();
  if (location == null) {
    throw StateError('No land time zone for $city (${place.name})');
  }
  final localStartTime = start.toLocation(location);
  final localEndTime = start.add(length).toLocation(location);
  return (
    city: city,
    localStartTime: localStartTime,
    localEndTime: localEndTime,
  );
}

void _printConfCallTable(List<TimeSlot> rows) {
  final header = <String>[
    'City',
    'Start (local)',
    'End (local)',
    'Zone',
    'Offset',
  ];
  final body = <List<String>>[
    for (final row in rows)
      <String>[
        row.city,
        _civil(row.localStartTime),
        _civil(row.localEndTime),
        // Africa/Casablanca has had no English CLDR name since 2018-10-28.
        row.localStartTime.timeZoneLongName ?? '',
        row.localStartTime.utcOffsetLabel,
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
  tz.initializeTimeZones();

  late final Place geneva;
  late final Place casablanca;
  late final Place montreal;
  late final Place tokyo;
  try {
    // Geneva University Hospitals
    geneva = await searchWithNominatim('hug geneva');

    await _nominatimPause();

    // Hospital Ibn Rochd, Casablanca
    casablanca = await searchWithNominatim('hospital ibn rochd casablanca');

    await _nominatimPause();

    // CHUM, Montreal
    montreal = await searchWithNominatim(
      'centre hospitalier universite montreal',
    );

    await _nominatimPause();

    // Tokyo Medical University Hospital
    tokyo = await advancedSearchWithNominatim({
      'amenity': 'hospital',
      'street': 'nishi shinjuku 6',
      'city': 'tokyo',
      'country': 'japan',
    });
  } on IOException catch (error) {
    stderr
      ..writeln('Geocoding failed.')
      ..writeln(error);
    exitCode = 1;
    return;
  }

  final start = TZDateTime.utc(2026, 9, 16, 12, 0);
  const callLength = Duration(minutes: 45);
  final confCall = <TimeSlot>[
    _schedule('Geneva', geneva, start, callLength),
    _schedule('Casablanca', casablanca, start, callLength),
    _schedule('Montreal', montreal, start, callLength),
    _schedule('Tokyo', tokyo, start, callLength),
  ];

  _printConfCallTable(confCall);
  print('TZBB boundary release: $boundaryDataVersion, CLDR: $cldrVersion');
}
