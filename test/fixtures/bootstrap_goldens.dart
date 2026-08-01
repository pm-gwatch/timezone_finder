// Bootstrap golden fixtures.
//
// These pairs are the ONLY ground truth in this package that does not come
// from the timezone-boundary-builder data. They exist to break a circular
// dependency: the reference oracle is validated against this set, and only
// once it passes does it become the authority for the wider fixture set and
// for differential testing.
//
// Provenance and rules:
//
//   * Every pair was written by hand from independent knowledge of world
//     geography, BEFORE any cross-check was run. Nothing here was generated
//     from tzbb data, from this package, or from another implementation.
//   * Each pair was then verified against Python `timezonefinder`
//     (`timezone_at_land`), an independent implementation with its own
//     preprocessing. See test/fixtures/README.md for the disagreement log.
//   * Every identifier was checked against the 419 entries in tzbb 2026c's
//     `timezone-names.json`, which confirms the zone exists without
//     consulting any geometry.
//
// Selection criteria: major city centres, well inside a country, chosen to be
// unambiguous rather than interesting. Border cases, enclaves, antimeridian
// zones and the 25 documented overlap pairs belong in golden_points.dart —
// deliberately NOT here, because a bootstrap set must be beyond doubt.
//
// Do not add a pair to this file by running an implementation and recording
// what it said. That defeats the entire purpose of the file.

import 'golden_point.dart';

export 'golden_point.dart' show GoldenCategory, GoldenPoint;

/// Externally sourced coordinate → identifier pairs. See the file header.
const List<GoldenPoint> bootstrapGoldens = <GoldenPoint>[
  // ---------------------------------------------------------------- Europe
  GoldenPoint('Paris, France', 48.8566, 2.3522, 'Europe/Paris'),
  GoldenPoint('Berlin, Germany', 52.5200, 13.4050, 'Europe/Berlin'),
  GoldenPoint('Madrid, Spain', 40.4168, -3.7038, 'Europe/Madrid'),
  GoldenPoint('Rome, Italy', 41.9028, 12.4964, 'Europe/Rome'),
  GoldenPoint('Warsaw, Poland', 52.2297, 21.0122, 'Europe/Warsaw'),
  GoldenPoint(
    'Kyiv, Ukraine',
    50.4501,
    30.5234,
    'Europe/Kyiv',
    note: 'Renamed from Europe/Kiev in tzdb 2022b. Kyiv is the current form.',
  ),
  GoldenPoint('Moscow, Russia', 55.7558, 37.6173, 'Europe/Moscow'),
  GoldenPoint('Athens, Greece', 37.9838, 23.7275, 'Europe/Athens'),
  GoldenPoint('Stockholm, Sweden', 59.3293, 18.0686, 'Europe/Stockholm'),
  GoldenPoint('Lisbon, Portugal', 38.7223, -9.1393, 'Europe/Lisbon'),
  GoldenPoint('London, United Kingdom', 51.5074, -0.1278, 'Europe/London'),
  GoldenPoint('Dublin, Ireland', 53.3498, -6.2603, 'Europe/Dublin'),
  GoldenPoint('Helsinki, Finland', 60.1699, 24.9384, 'Europe/Helsinki'),
  GoldenPoint('Bucharest, Romania', 44.4268, 26.1025, 'Europe/Bucharest'),
  GoldenPoint(
    'Ankara, Türkiye',
    39.9334,
    32.8597,
    'Europe/Istanbul',
    note:
        'Turkey has one zone, named for Istanbul. Ankara is used instead of '
        'Istanbul because Europe/Athens–Europe/Istanbul is a documented '
        'overlap pair in the Aegean; Ankara is far inland of it.',
  ),

  // -------------------------------------------------------------- Americas
  GoldenPoint('New York, USA', 40.7128, -74.0060, 'America/New_York'),
  GoldenPoint('Chicago, USA', 41.8781, -87.6298, 'America/Chicago'),
  GoldenPoint('Denver, USA', 39.7392, -104.9903, 'America/Denver'),
  GoldenPoint('Los Angeles, USA', 34.0522, -118.2437, 'America/Los_Angeles'),
  GoldenPoint(
    'Phoenix, USA',
    33.4484,
    -112.0740,
    'America/Phoenix',
    note:
        'Arizona does not observe DST and has its own zone, distinct from '
        'America/Denver.',
  ),
  GoldenPoint('Anchorage, USA', 61.2181, -149.9003, 'America/Anchorage'),
  GoldenPoint('Honolulu, USA', 21.3069, -157.8583, 'Pacific/Honolulu'),
  GoldenPoint('Toronto, Canada', 43.6532, -79.3832, 'America/Toronto'),
  GoldenPoint('Winnipeg, Canada', 49.8951, -97.1384, 'America/Winnipeg'),
  GoldenPoint('Vancouver, Canada', 49.2827, -123.1207, 'America/Vancouver'),
  GoldenPoint('Mexico City, Mexico', 19.4326, -99.1332, 'America/Mexico_City'),
  GoldenPoint('Havana, Cuba', 23.1136, -82.3666, 'America/Havana'),
  GoldenPoint('Bogotá, Colombia', 4.7110, -74.0721, 'America/Bogota'),
  GoldenPoint('Lima, Peru', -12.0464, -77.0428, 'America/Lima'),
  GoldenPoint('Santiago, Chile', -33.4489, -70.6693, 'America/Santiago'),
  GoldenPoint(
    'Buenos Aires, Argentina',
    -34.6037,
    -58.3816,
    'America/Argentina/Buenos_Aires',
    note:
        'Three-segment identifier — exercises parsing that must not assume '
        'exactly one slash.',
  ),
  GoldenPoint('São Paulo, Brazil', -23.5505, -46.6333, 'America/Sao_Paulo'),

  // ---------------------------------------------------------------- Africa
  GoldenPoint('Cairo, Egypt', 30.0444, 31.2357, 'Africa/Cairo'),
  GoldenPoint('Lagos, Nigeria', 6.5244, 3.3792, 'Africa/Lagos'),
  GoldenPoint('Nairobi, Kenya', -1.2921, 36.8219, 'Africa/Nairobi'),
  GoldenPoint(
    'Johannesburg, South Africa',
    -26.2041,
    28.0473,
    'Africa/Johannesburg',
  ),
  GoldenPoint('Casablanca, Morocco', 33.5731, -7.5898, 'Africa/Casablanca'),
  GoldenPoint('Addis Ababa, Ethiopia', 9.0300, 38.7400, 'Africa/Addis_Ababa'),
  GoldenPoint('Algiers, Algeria', 36.7538, 3.0588, 'Africa/Algiers'),
  GoldenPoint('Accra, Ghana', 5.6037, -0.1870, 'Africa/Accra'),

  // ------------------------------------------------------------------ Asia
  GoldenPoint('Tokyo, Japan', 35.6762, 139.6503, 'Asia/Tokyo'),
  GoldenPoint('Seoul, South Korea', 37.5665, 126.9780, 'Asia/Seoul'),
  GoldenPoint(
    'Beijing, China',
    39.9042,
    116.4074,
    'Asia/Shanghai',
    note:
        'Counterintuitive but correct: mainland China uses a single zone '
        'named for Shanghai. Do not "correct" this to Asia/Beijing.',
  ),
  GoldenPoint('Hong Kong', 22.3193, 114.1694, 'Asia/Hong_Kong'),
  GoldenPoint('Singapore', 1.3521, 103.8198, 'Asia/Singapore'),
  GoldenPoint('Bangkok, Thailand', 13.7563, 100.5018, 'Asia/Bangkok'),
  GoldenPoint('Jakarta, Indonesia', -6.2088, 106.8456, 'Asia/Jakarta'),
  GoldenPoint(
    'Delhi, India',
    28.6139,
    77.2090,
    'Asia/Kolkata',
    note:
        'Counterintuitive but correct: all of India uses a single zone '
        'named for Kolkata. Do not "correct" this to Asia/Delhi.',
  ),
  GoldenPoint('Karachi, Pakistan', 24.8607, 67.0011, 'Asia/Karachi'),
  GoldenPoint('Dhaka, Bangladesh', 23.8103, 90.4125, 'Asia/Dhaka'),
  GoldenPoint('Dubai, UAE', 25.2048, 55.2708, 'Asia/Dubai'),
  GoldenPoint('Tehran, Iran', 35.6892, 51.3890, 'Asia/Tehran'),
  GoldenPoint('Riyadh, Saudi Arabia', 24.7136, 46.6753, 'Asia/Riyadh'),
  GoldenPoint('Manila, Philippines', 14.5995, 120.9842, 'Asia/Manila'),
  GoldenPoint('Kathmandu, Nepal', 27.7172, 85.3240, 'Asia/Kathmandu'),
  GoldenPoint('Tashkent, Uzbekistan', 41.2995, 69.2401, 'Asia/Tashkent'),
  GoldenPoint('Yerevan, Armenia', 40.1792, 44.4991, 'Asia/Yerevan'),

  // -------------------------------------------------------- Russia (Asian)
  GoldenPoint(
    'Yekaterinburg, Russia',
    56.8389,
    60.6057,
    'Asia/Yekaterinburg',
    note:
        'Russia spans many zones; three are sampled to catch an index that '
        'collapses a large country to one answer.',
  ),
  GoldenPoint('Novosibirsk, Russia', 55.0084, 82.9357, 'Asia/Novosibirsk'),
  GoldenPoint('Vladivostok, Russia', 43.1332, 131.9113, 'Asia/Vladivostok'),

  // --------------------------------------------------------------- Oceania
  GoldenPoint('Sydney, Australia', -33.8688, 151.2093, 'Australia/Sydney'),
  GoldenPoint('Perth, Australia', -31.9505, 115.8605, 'Australia/Perth'),
  GoldenPoint('Brisbane, Australia', -27.4698, 153.0251, 'Australia/Brisbane'),
  GoldenPoint('Adelaide, Australia', -34.9285, 138.6007, 'Australia/Adelaide'),
  GoldenPoint('Darwin, Australia', -12.4634, 130.8456, 'Australia/Darwin'),
  GoldenPoint('Auckland, New Zealand', -36.8485, 174.7633, 'Pacific/Auckland'),
];
