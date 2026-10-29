/// The shortcut grid: a uniform lat/lon raster that narrows a lookup from
/// every polygon (~1,200) to a handful before any geometry is tested.
///
/// Build-time only — the runtime reads the serialized form.
library;

import 'dart:typed_data';

import 'package:timezone_finder/src/index/varint.dart';

import 'geometry.dart';

/// Quantized units spanned by the whole globe, per axis.
const int _globeWidth = 360000000;
const int _globeHeight = 180000000;

/// A cell holds no polygon at all: the lookup returns null without testing
/// geometry.
const int cellEmpty = 0;

/// A uniform grid over the quantized coordinate space.
class GridSpec {
  const GridSpec(this.cellSize);

  /// Quantized units per cell, per axis. 1e6 is one degree.
  final int cellSize;

  int get columns => _globeWidth ~/ cellSize;
  int get rows => _globeHeight ~/ cellSize;
  int get cellCount => columns * rows;

  /// Degrees per cell, for reporting.
  double get degrees => cellSize / 1000000;

  /// Column containing quantized longitude [x].
  ///
  /// Query longitudes are normalised so +180 becomes −180 before reaching
  /// here, which is what keeps the result inside the array; the clamp covers
  /// polygon vertices, which are not normalised and may sit exactly on +180.
  int columnOf(int x) {
    final index = (x + _globeWidth ~/ 2) ~/ cellSize;
    return index < 0 ? 0 : (index >= columns ? columns - 1 : index);
  }

  /// Row containing quantized latitude [y].
  int rowOf(int y) {
    final index = (y + _globeHeight ~/ 2) ~/ cellSize;
    return index < 0 ? 0 : (index >= rows ? rows - 1 : index);
  }

  int indexOf(int x, int y) => rowOf(y) * columns + columnOf(x);
}

/// A polygon's bounding box, its position in the polygon table, and the two
/// values the overlap tiebreak orders by.
typedef PolygonBox = ({
  int id,
  int minX,
  int maxX,
  int minY,
  int maxY,
  int area,
  String zone,
});

/// A built grid, with its serialized form and the statistics that justify the
/// resolution.
class BuiltGrid {
  BuiltGrid({
    required this.spec,
    required this.cells,
    required this.pool,
    required this.emptyCells,
    required this.candidateCells,
    required this.candidateLengths,
    required this.distinctLists,
  });

  final GridSpec spec;

  /// One entry per cell: [cellEmpty], or a negative value whose complement is
  /// a byte offset into [pool].
  ///
  /// Positive values are reserved for a future `ZONE(id)` class — a cell
  /// proven to lie entirely within one zone, which needs edge rasterisation to
  /// establish and is deferred until the measurements justify it.
  final Int32List cells;

  /// Candidate lists, each `varint(count)` then polygon ids as zigzag varint
  /// deltas, **in overlap-tiebreak order**, not ascending. Each id is written
  /// with [writeRing], so it is a pair: the x delta is the id and the y delta
  /// is 0 (one extra byte). The runtime returns the first containing polygon,
  /// so this order decides disputed answers. Identical lists are stored once.
  final Uint8List pool;

  final int emptyCells;
  final int candidateCells;

  /// Candidate-list length for every non-empty cell, ascending.
  final List<int> candidateLengths;

  /// How many distinct candidate lists the pool holds.
  final int distinctLists;

  int get serializedBytes => cells.lengthInBytes + pool.lengthInBytes;

  /// Polygon ids to test for the cell containing ([x], [y]).
  List<int> candidatesAt(int x, int y) {
    final cell = cells[spec.indexOf(x, y)];
    if (cell == cellEmpty) return const <int>[];
    return _readList(pool, -cell - 1);
  }

  int percentileLength(int percentile) {
    if (candidateLengths.isEmpty) return 0;
    final rank = (candidateLengths.length - 1) * percentile ~/ 100;
    return candidateLengths[rank];
  }
}

/// Builds a grid from polygon bounding boxes alone.
///
/// A cell lists every polygon whose box overlaps it. That is a superset of the
/// polygons that could contain a point in the cell — a box overlapping a cell
/// does not mean the polygon does — so point-in-polygon still has to run on
/// each candidate. The grid is a filter, never an answer.
///
/// This over-approximates, and deliberately so: the alternative, proving a
/// cell lies wholly inside one polygon, needs the polygon's edges rasterised
/// onto the grid. That is the highest-risk code in the project and it is worth
/// writing only if the measurements below show the filter is too weak without
/// it.
BuiltGrid buildGrid(GridSpec spec, List<PolygonBox> boxes) {
  final buckets = List<List<int>?>.filled(spec.cellCount, null);
  final byId = <PolygonBox>[...boxes]..sort((a, b) => a.id.compareTo(b.id));

  for (final box in boxes) {
    final x0 = spec.columnOf(box.minX);
    final x1 = spec.columnOf(box.maxX);
    final y0 = spec.rowOf(box.minY);
    final y1 = spec.rowOf(box.maxY);
    for (var row = y0; row <= y1; row++) {
      final base = row * spec.columns;
      for (var column = x0; column <= x1; column++) {
        (buckets[base + column] ??= <int>[]).add(box.id);
      }
    }
  }

  final cells = Int32List(spec.cellCount);
  final pool = BytesBuilder();
  final interned = <String, int>{};
  final lengths = <int>[];
  var empty = 0;
  var occupied = 0;

  for (var i = 0; i < buckets.length; i++) {
    final bucket = buckets[i];
    if (bucket == null) {
      cells[i] = cellEmpty;
      empty++;
      continue;
    }
    occupied++;
    lengths.add(bucket.length);

    // Sorted by precedence, so the runtime can return the first polygon that
    // contains the point instead of collecting every hit and comparing. That
    // is what lets the shipped index omit polygon areas entirely — they are a
    // build-time concern once the order is baked in.
    //
    // Ids are therefore no longer ascending. The list codec zigzags its
    // deltas, so that costs nothing.
    bucket.sort((a, b) {
      final byRule = comparePrecedence(
        byId[a].area,
        byId[a].zone,
        byId[b].area,
        byId[b].zone,
      );
      // Polygon id as a final tiebreak. Two polygons of the same zone with
      // identical area compare equal under the precedence rule, and
      // `List.sort` is not stable — so without this the pool offsets could
      // differ between runs of the same input, and the byte-identity gate in
      // `tool/refresh.dart --verify` would be passing by luck.
      return byRule != 0 ? byRule : a.compareTo(b);
    });
    final key = bucket.join(',');
    final offset = interned.putIfAbsent(key, () {
      final at = pool.length;
      _writeList(pool, bucket);
      return at;
    });
    cells[i] = -(offset + 1);
  }

  lengths.sort();
  return BuiltGrid(
    spec: spec,
    cells: cells,
    pool: pool.toBytes(),
    emptyCells: empty,
    candidateCells: occupied,
    candidateLengths: lengths,
    distinctLists: interned.length,
  );
}

/// A box whose longitude span covers essentially the whole globe.
bool boxSpansAllLongitudes(PolygonBox box) =>
    box.minX <= -179000000 && box.maxX >= 179000000;

/// A box that reaches the arctic or antarctic, where a full-longitude span
/// is a polar cap rather than an unsplit antimeridian ring.
bool boxReachesAPole(PolygonBox box) =>
    box.minY <= -89000000 || box.maxY >= 89000000;

/// Non-polar boxes that claim every longitude.
///
/// Grid indexing treats x as a plain interval. An unsplit ring that crosses
/// ±180 would be filed across the globe while occupying a sliver.
List<PolygonBox> antimeridianWrappingBoxes(List<PolygonBox> boxes) => [
  for (final box in boxes)
    if (boxSpansAllLongitudes(box) && !boxReachesAPole(box)) box,
];

/// Throws [StateError] when [antimeridianWrappingBoxes] is not empty.
void assertNoAntimeridianWrap(List<PolygonBox> boxes) {
  final wrapping = antimeridianWrappingBoxes(boxes);
  if (wrapping.isEmpty) return;
  throw StateError(
    '${wrapping.length} polygon box(es) span every longitude without '
    'reaching a pole. Grid indexing treats longitude as a plain interval '
    'and cannot represent an unsplit antimeridian ring.',
  );
}

void _writeList(BytesBuilder out, List<int> ids) {
  final ring = Int32List(ids.length * 2);
  for (var i = 0; i < ids.length; i++) {
    ring[i * 2] = ids[i];
  }
  // Reuses the coordinate codec: its zigzag deltas encode a candidate list in
  // tiebreak order (ids not ascending) as compactly as coordinates. The
  // unused y slots cost one byte each; measured against a bespoke encoder the
  // difference is not worth a second format to maintain.
  writeRing(out, ring);
}

List<int> _readList(Uint8List pool, int offset) {
  final decoded = readRing(pool, offset);
  final count = decoded.ring.length ~/ 2;
  return <int>[for (var i = 0; i < count; i++) decoded.ring[i * 2]];
}
