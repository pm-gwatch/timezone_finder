/// Probes the documented zone overlaps using the Phase A reference oracle.
///
///     dart run tool/probe_overlaps.dart
///
/// timezone-boundary-builder ships `expectedZoneOverlaps.json`, listing pairs
/// of zones permitted to overlap and the bounds within which they may. Most
/// correspond to disputed territories. Because a point inside two polygons is
/// resolved by the precedence rule of plan §6.5, those regions are where the
/// rule actually decides an answer — and so they need golden fixtures.
///
/// This searches each documented region for a coordinate genuinely covered by
/// two or more zones, and reports what the precedence rule returns there. The
/// output is the raw material for the milestone 3 overlap fixtures; it is a
/// maintainer diagnostic, not a test.
///
/// It also reports dataset totals, as a cheap check that the oracle parsed
/// everything rather than silently dropping geometry.
library;

import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../test/reference/reference_finder.dart';
import 'src/fetch.dart';

const _overlapsUrl =
    'https://raw.githubusercontent.com/evansiroky/timezone-boundary-builder/'
    'master/expectedZoneOverlaps.json';

/// Default sampling density per axis. Override with `--steps N`.
const int _defaultGridSteps = 24;

late int _gridSteps;

Future<void> main(List<String> args) async {
  _gridSteps = _defaultGridSteps;
  String? only;
  for (var i = 0; i < args.length; i++) {
    if (args[i] == '--steps' && i + 1 < args.length) {
      _gridSteps = int.parse(args[i + 1]);
    } else if (args[i] == '--only' && i + 1 < args.length) {
      only = args[i + 1];
    }
  }
  await _run(only);
}

Future<void> _run(String? only) async {
  final cached = cachedGeoJsonFile(defaultRelease);
  if (!cached.existsSync()) {
    stderr.writeln('No cached data. Run: dart run tool/fetch_data.dart');
    exitCode = 1;
    return;
  }

  stdout.writeln('Loading reference oracle …');
  final oracle = await ReferenceTimeZoneFinder.load(cached);

  var vertices = 0;
  var rings = 0;
  var holes = 0;
  for (final polygon in oracle.polygons) {
    rings += 1 + polygon.holes.length;
    holes += polygon.holes.length;
    vertices += polygon.outer.length ~/ 2;
    for (final hole in polygon.holes) {
      vertices += hole.length ~/ 2;
    }
  }
  stdout
    ..writeln('zones:    ${oracle.zones.length}')
    ..writeln('polygons: ${oracle.polygons.length}')
    ..writeln('rings:    $rings (holes: $holes)')
    ..writeln('vertices: $vertices')
    ..writeln('');

  stdout.writeln('Fetching expectedZoneOverlaps.json …');
  final response = await http.get(Uri.parse(_overlapsUrl));
  final overlaps = jsonDecode(response.body) as Map<String, Object?>;
  stdout.writeln('${overlaps.length} documented overlap pairs\n');

  var found = 0;
  var missed = 0;
  for (final entry in overlaps.entries) {
    if (only != null && !entry.key.contains(only)) continue;
    final regions = entry.value! as List<Object?>;
    final hit = _searchRegions(oracle, regions);
    if (hit == null) {
      missed++;
      // Distinguish "this region is ocean, so the land-only variant has no
      // geometry here" from "this is land, but the polygons do not overlap".
      final coverage = _coverage(oracle, regions);
      stdout.writeln('  --  ${entry.key}\n'
          '      no multi-zone point found at ${_gridSteps}x$_gridSteps\n'
          '      of ${coverage.total} sampled points: ${coverage.empty} in no '
          'zone, ${coverage.single} in exactly one\n'
          '      zones seen: ${coverage.zones.isEmpty ? '(none)' : coverage.zones.join(', ')}');
      continue;
    }
    found++;
    stdout.writeln('  OK  ${entry.key}\n'
        '      (${hit.latitude.toStringAsFixed(5)}, '
        '${hit.longitude.toStringAsFixed(5)}) '
        'covered by ${hit.zones.join(' + ')}\n'
        '      precedence returns: ${hit.zones.first}');
  }

  stdout.writeln('\n$found of ${overlaps.length} pairs reproduced; '
      '$missed not found at ${_gridSteps}x$_gridSteps sampling.');
}

class _Hit {
  _Hit(this.latitude, this.longitude, this.zones);
  final double latitude;
  final double longitude;
  final List<String> zones;
}

class _Coverage {
  _Coverage(this.total, this.empty, this.single, this.zones);
  final int total;
  final int empty;
  final int single;
  final Set<String> zones;
}

/// How much of a documented region has any land geometry at all.
_Coverage _coverage(ReferenceTimeZoneFinder oracle, List<Object?> regions) {
  var total = 0, empty = 0, single = 0;
  final zones = <String>{};
  for (final region in regions) {
    final b = _bounds(region);
    for (var i = 0; i <= _gridSteps; i++) {
      for (var j = 0; j <= _gridSteps; j++) {
        final lon = b[0] + (b[2] - b[0]) * i / _gridSteps;
        final lat = b[1] + (b[3] - b[1]) * j / _gridSteps;
        final hits = oracle.zonesContaining(lat, lon);
        total++;
        if (hits.isEmpty) {
          empty++;
        } else if (hits.length == 1) {
          single++;
        }
        zones.addAll(hits);
      }
    }
  }
  return _Coverage(total, empty, single, zones);
}

List<double> _bounds(Object? region) =>
    ((region! as Map<String, Object?>)['bounds']! as List<Object?>)
        .map((v) => (v! as num).toDouble())
        .toList();

_Hit? _searchRegions(ReferenceTimeZoneFinder oracle, List<Object?> regions) {
  for (final region in regions) {
    // [west, south, east, north]
    final bounds = _bounds(region);
    final west = bounds[0], south = bounds[1], east = bounds[2], north = bounds[3];
    for (var i = 0; i <= _gridSteps; i++) {
      for (var j = 0; j <= _gridSteps; j++) {
        final lon = west + (east - west) * i / _gridSteps;
        final lat = south + (north - south) * j / _gridSteps;
        final zones = oracle.zonesContaining(lat, lon);
        if (zones.length >= 2) return _Hit(lat, lon, zones);
      }
    }
  }
  return null;
}
