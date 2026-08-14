// Overlap pins — NOT ground truth. Documented tiebreak (smallest area, then
// id), not sovereignty. Do not update a fail to match new output.
// 21 of 25 pairs; four have no land overlap in 2026c.
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
