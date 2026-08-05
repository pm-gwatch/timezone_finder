// Overlap regression pins.
//
// ============================ THESE ARE NOT GROUND TRUTH ====================
//
// Every coordinate here is genuinely inside TWO time zones. Both polygons
// really cover the point; timezone-boundary-builder documents and permits the
// overlap. No external source can say which identifier is "correct", because
// there is no fact of the matter — the answer is produced by the arbitrary
// tiebreak in the overlap tiebreak (smallest polygon by planar area, then lexicographic
// identifier).
//
// These entries therefore pin DETERMINISM, not correctness. They exist so that
// a change to the tiebreak, the area computation, or the quantization shows up
// as a failing test rather than as a silent change in published answers.
//
// Most of these regions are disputed territories — Abyei, the West Bank,
// Kashmir, the Aegean. `selected` records which identifier the rule happens to
// return. It is not a claim about sovereignty, and this package makes no such
// claim. See the README.
//
// ---------------------------------------------------------------------------
// If one of these tests fails:
//
//   DO NOT update the expectation to match the new output. A change here means
//   the tiebreak changed, which changes answers users depend on in disputed
//   regions. Find out why it changed and decide deliberately.
//
// Cross-checking these against timezonefinder or tzf is meaningless: those
// implementations have their own tiebreaks and will disagree by design. That
// is precisely how Ürümqi was caught being mis-filed as ground truth.
// ---------------------------------------------------------------------------
//
// Coverage: 21 of the 25 documented overlap pairs. The other four
// (Asia/Ho_Chi_Minh–Asia/Manila, Asia/Ho_Chi_Minh–Asia/Shanghai,
// Asia/Kolkata–Asia/Shanghai, Asia/Manila–Asia/Shanghai) do not overlap
// anywhere in the 2026c land-only geometry at sampling densities up to
// 200x200. They cannot be pinned because the situation they
// describe does not arise in this dataset.
library;

/// A coordinate covered by two zones, and which one the tiebreak selects.
class OverlapPin {
  const OverlapPin(
    this.description,
    this.latitude,
    this.longitude,
    this.contenders,
    this.selected,
  );

  /// The disputed or shared area this point falls in.
  final String description;

  /// Degrees north.
  final double latitude;

  /// Degrees east.
  final double longitude;

  /// Every identifier whose polygons contain the point, in precedence order.
  final List<String> contenders;

  /// What the overlap tiebreak returns — always `contenders.first`.
  final String selected;

  @override
  String toString() =>
      '$description ($latitude, $longitude): ${contenders.join(' + ')} '
      '→ $selected';
}

/// Points inside documented zone overlaps. See the file header before editing.
const List<OverlapPin> overlapPins = <OverlapPin>[
  OverlapPin('Abyei / Kafia Kingi (Sudan–South Sudan)', 9.75450, 27.83900, [
    'Africa/Juba',
    'Africa/Khartoum',
  ], 'Africa/Juba'),
  OverlapPin('Burkina Faso–Benin border area', 10.99700, 0.91300, [
    'Africa/Porto-Novo',
    'Africa/Ouagadougou',
  ], 'Africa/Porto-Novo'),
  OverlapPin('Alaska–Yukon boundary at 141°W', 69.65850, -141.00200, [
    'America/Dawson',
    'America/Anchorage',
  ], 'America/Dawson'),
  OverlapPin(
    'Southern Patagonia (Argentina–Chile)',
    -49.54200,
    -73.54600,
    ['America/Punta_Arenas', 'America/Argentina/Rio_Gallegos'],
    'America/Punta_Arenas',
  ),
  OverlapPin('Bolivia–Brazil border', -10.79600, -65.36700, [
    'America/Porto_Velho',
    'America/La_Paz',
  ], 'America/Porto_Velho'),
  OverlapPin('Strait of Juan de Fuca (USA–Canada)', 48.49600, -125.00000, [
    'America/Vancouver',
    'America/Los_Angeles',
  ], 'America/Vancouver'),
  OverlapPin('Bay of Fundy approaches (USA–Canada)', 44.37100, -67.30250, [
    'America/Moncton',
    'America/New_York',
  ], 'America/Moncton'),
  OverlapPin('Haida Gwaii / southeast Alaska', 54.55000, -133.09600, [
    'America/Sitka',
    'America/Vancouver',
  ], 'America/Sitka'),
  OverlapPin('Andaman Sea (Thailand–Myanmar)', 9.76900, 98.28200, [
    'Asia/Bangkok',
    'Asia/Yangon',
  ], 'Asia/Bangkok'),
  OverlapPin('West Bank / Gaza vicinity', 31.39100, 34.88400, [
    'Asia/Hebron',
    'Asia/Jerusalem',
  ], 'Asia/Hebron'),
  OverlapPin('Kalapani / Nepal–India border', 30.42600, 80.52700, [
    'Asia/Kathmandu',
    'Asia/Kolkata',
  ], 'Asia/Kathmandu'),
  OverlapPin('Tumen estuary (North Korea–China–Russia)', 42.86200, 130.25200, [
    'Asia/Pyongyang',
    'Asia/Shanghai',
  ], 'Asia/Pyongyang'),
  OverlapPin('Bhutan–China border', 27.27500, 88.90750, [
    'Asia/Thimphu',
    'Asia/Shanghai',
  ], 'Asia/Thimphu'),
  OverlapPin('Xinjiang–Tajikistan border', 39.29150, 73.63000, [
    'Asia/Urumqi',
    'Asia/Shanghai',
  ], 'Asia/Urumqi'),
  OverlapPin('Ürümqi, Xinjiang', 43.8256, 87.6168, [
    'Asia/Urumqi',
    'Asia/Shanghai',
  ], 'Asia/Urumqi'),
  OverlapPin('Abkhazia coast (Georgia–Russia)', 43.22200, 39.89600, [
    'Asia/Tbilisi',
    'Europe/Moscow',
  ], 'Asia/Tbilisi'),
  OverlapPin('Ems estuary (Netherlands–Germany)', 53.72000, 6.34950, [
    'Europe/Amsterdam',
    'Europe/Berlin',
  ], 'Europe/Amsterdam'),
  OverlapPin('Aegean (Greece–Türkiye)', 37.05250, 27.13500, [
    'Europe/Athens',
    'Europe/Istanbul',
  ], 'Europe/Athens'),
  OverlapPin('Serbia–Croatia Danube border', 45.90800, 18.81750, [
    'Europe/Belgrade',
    'Europe/Zagreb',
  ], 'Europe/Belgrade'),
  OverlapPin('Luxembourg–Germany border', 50.09200, 6.12000, [
    'Europe/Luxembourg',
    'Europe/Berlin',
  ], 'Europe/Luxembourg'),
  OverlapPin('Piran Bay (Slovenia–Croatia)', 45.56600, 13.38550, [
    'Europe/Ljubljana',
    'Europe/Zagreb',
  ], 'Europe/Ljubljana'),
  OverlapPin('Mont Blanc massif (France–Italy)', 45.84100, 6.84100, [
    'Europe/Rome',
    'Europe/Paris',
  ], 'Europe/Rome'),
];
