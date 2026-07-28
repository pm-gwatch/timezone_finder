/// The shared fixture record used by the golden sets.
library;

/// What a fixture is testing, so that a cluster of failures in one category
/// can be recognised as a systematic bug rather than several bad fixtures.
enum GoldenCategory {
  /// A city centre, well inside a country.
  city,

  /// Near a zone border, often paired with a point just across it.
  border,

  /// Inside a hole in another zone's polygon, or a microstate.
  enclave,

  /// A small island or island group with its own zone.
  island,

  /// An Antarctic research station.
  antarctic,

  /// A zone split by the 180th meridian, or a point on the meridian itself.
  antimeridian,

  /// Open ocean, where a land-only dataset must return nothing.
  ocean,
}

/// A hand-authored coordinate → IANA identifier expectation.
class GoldenPoint {
  const GoldenPoint(
    this.name,
    this.latitude,
    this.longitude,
    this.zone, {
    this.category = GoldenCategory.city,
    this.note,
  });

  /// Human-readable label, e.g. `'Paris, France'`.
  final String name;

  /// Degrees north, in [-90, 90].
  final double latitude;

  /// Degrees east, in [-180, 180].
  final double longitude;

  /// The expected IANA identifier, or `null` when the point is expected to
  /// fall outside every land polygon.
  final String? zone;

  /// What this fixture exercises.
  final GoldenCategory category;

  /// Why this point is here, when that is not obvious.
  final String? note;

  @override
  String toString() => '$name ($latitude, $longitude) → ${zone ?? 'null'}';
}
