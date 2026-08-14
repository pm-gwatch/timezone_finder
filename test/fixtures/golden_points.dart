// Harder goldens: borders, enclaves, islands, antimeridian, ocean.
// External ground truth (see test/fixtures/README.md); never adopt the
// implementation. Weaker provenance: 'Unclaimed Antarctic sector, 10°W',
// 'Dover Strait, mid-channel'. Overlaps → overlap_pins.dart.
library;

import 'golden_point.dart';

/// Externally sourced expectations covering the harder cases.
const List<GoldenPoint> goldenPoints = <GoldenPoint>[
  // ======================================================= zone borders ====
  // Adjacent settlements in different zones. These are the fixtures most
  // likely to catch an off-by-one in the index, and the ones where an
  // implementation that simplifies its polygons will start to disagree.
  GoldenPoint(
    'Basel, Switzerland',
    47.5596,
    7.5886,
    'Europe/Zurich',
    category: GoldenCategory.border,
    note: 'Paired with Saint-Louis, ~3 km away in Europe/Paris.',
  ),
  GoldenPoint(
    'Saint-Louis, France',
    47.5833,
    7.5667,
    'Europe/Paris',
    category: GoldenCategory.border,
  ),
  GoldenPoint(
    'Frankfurt (Oder), Germany',
    52.3412,
    14.5500,
    'Europe/Berlin',
    category: GoldenCategory.border,
    note: 'Paired with Słubice directly across the Oder in Europe/Warsaw.',
  ),
  GoldenPoint(
    'Słubice, Poland',
    52.3500,
    14.5667,
    'Europe/Warsaw',
    category: GoldenCategory.border,
  ),
  GoldenPoint(
    'Haparanda, Sweden',
    65.8356,
    24.1333,
    'Europe/Stockholm',
    category: GoldenCategory.border,
    note: 'Twin town of Tornio, ~1 km away and one hour ahead.',
  ),
  GoldenPoint(
    'Tornio, Finland',
    65.8481,
    24.1444,
    'Europe/Helsinki',
    category: GoldenCategory.border,
  ),
  GoldenPoint(
    'Detroit, USA',
    42.3314,
    -83.0458,
    'America/Detroit',
    category: GoldenCategory.border,
    note: 'Windsor lies south of Detroit and in a different zone.',
  ),
  GoldenPoint(
    'Windsor, Canada',
    42.3149,
    -83.0364,
    'America/Toronto',
    category: GoldenCategory.border,
  ),
  GoldenPoint(
    'Badajoz, Spain',
    38.8794,
    -6.9707,
    'Europe/Madrid',
    category: GoldenCategory.border,
  ),
  GoldenPoint(
    'Elvas, Portugal',
    38.8813,
    -7.1633,
    'Europe/Lisbon',
    category: GoldenCategory.border,
  ),
  GoldenPoint(
    'Namche Bazaar, Nepal',
    27.8069,
    86.7140,
    'Asia/Kathmandu',
    category: GoldenCategory.border,
  ),
  GoldenPoint(
    'Tingri, Tibet, China',
    28.6500,
    87.0000,
    'Asia/Shanghai',
    category: GoldenCategory.border,
  ),
  GoldenPoint(
    'Window Rock, Navajo Nation, USA',
    35.6811,
    -109.0537,
    'America/Denver',
    category: GoldenCategory.border,
    note:
        'The Navajo Nation observes DST while the rest of Arizona does not, '
        'so it falls in America/Denver, not America/Phoenix.',
  ),
  GoldenPoint(
    'Page, Arizona, USA',
    36.9147,
    -111.4558,
    'America/Phoenix',
    category: GoldenCategory.border,
  ),
  GoldenPoint(
    'Indianapolis, USA',
    39.7684,
    -86.1581,
    'America/Indiana/Indianapolis',
    category: GoldenCategory.border,
    note: 'Three-segment identifier; Indiana is split across several zones.',
  ),
  GoldenPoint(
    'Louisville, USA',
    38.2527,
    -85.7585,
    'America/Kentucky/Louisville',
    category: GoldenCategory.border,
  ),
  GoldenPoint(
    'Center, North Dakota, USA',
    47.1164,
    -101.2996,
    'America/North_Dakota/Center',
    category: GoldenCategory.border,
  ),
  GoldenPoint(
    'El Paso, USA',
    31.7619,
    -106.4850,
    'America/Denver',
    category: GoldenCategory.border,
  ),
  GoldenPoint(
    'Ciudad Juárez, Mexico',
    31.6904,
    -106.4245,
    'America/Ciudad_Juarez',
    category: GoldenCategory.border,
  ),

  // A boundary inside a single municipality. Every other border fixture here
  // straddles a national or state line; Brazilian law (Federal Law 12,876/2013)
  // draws the Amazonas time zone boundary as a straight line between the
  // municipalities of Tabatinga and Porto Acre, and Pauini is large enough to
  // sit on both sides of it.
  GoldenPoint(
    'Pauini, Amazonas — east of the line',
    -7.7120204,
    -67.0130633,
    'America/Manaus',
    category: GoldenCategory.border,
    note: 'Paired with the western half of the same municipality.',
  ),
  GoldenPoint(
    'Pauini, Amazonas — west of the line',
    -7.7857015,
    -68.5215298,
    'America/Eirunepe',
    category: GoldenCategory.border,
  ),

  // ========================================================== enclaves ====
  // Microstates and true holes in a surrounding zone's polygon. A hole-
  // handling bug shows up here and almost nowhere else.
  GoldenPoint(
    'Vatican City',
    41.9029,
    12.4534,
    'Europe/Vatican',
    category: GoldenCategory.enclave,
  ),
  GoldenPoint(
    'San Marino',
    43.9424,
    12.4578,
    'Europe/San_Marino',
    category: GoldenCategory.enclave,
  ),
  GoldenPoint(
    'Monaco',
    43.7384,
    7.4246,
    'Europe/Monaco',
    category: GoldenCategory.enclave,
  ),
  GoldenPoint(
    'Vaduz, Liechtenstein',
    47.1410,
    9.5209,
    'Europe/Vaduz',
    category: GoldenCategory.enclave,
  ),
  GoldenPoint(
    'Andorra la Vella',
    42.5063,
    1.5218,
    'Europe/Andorra',
    category: GoldenCategory.enclave,
  ),
  GoldenPoint(
    'Gibraltar',
    36.1408,
    -5.3536,
    'Europe/Gibraltar',
    category: GoldenCategory.enclave,
  ),
  GoldenPoint(
    'Büsingen am Hochrhein, Germany',
    47.6961,
    8.6892,
    'Europe/Busingen',
    category: GoldenCategory.enclave,
    note:
        'German exclave entirely surrounded by Switzerland, with its own '
        'IANA identifier.',
  ),
  GoldenPoint(
    'Maseru, Lesotho',
    -29.3151,
    27.4869,
    'Africa/Maseru',
    category: GoldenCategory.enclave,
    note: 'Lesotho is wholly enclosed by South Africa — the canonical hole.',
  ),

  // =========================================================== islands ====
  GoldenPoint(
    'Valletta, Malta',
    35.8989,
    14.5146,
    'Europe/Malta',
    category: GoldenCategory.island,
  ),
  GoldenPoint(
    'Reykjavík, Iceland',
    64.1466,
    -21.9426,
    'Atlantic/Reykjavik',
    category: GoldenCategory.island,
  ),
  GoldenPoint(
    'Ponta Delgada, Azores',
    37.7412,
    -25.6756,
    'Atlantic/Azores',
    category: GoldenCategory.island,
  ),
  GoldenPoint(
    'Funchal, Madeira',
    32.6669,
    -16.9241,
    'Atlantic/Madeira',
    category: GoldenCategory.island,
  ),
  GoldenPoint(
    'Las Palmas, Canary Islands',
    28.1235,
    -15.4363,
    'Atlantic/Canary',
    category: GoldenCategory.island,
  ),
  GoldenPoint(
    'Praia, Cape Verde',
    14.9330,
    -23.5133,
    'Atlantic/Cape_Verde',
    category: GoldenCategory.island,
  ),
  GoldenPoint(
    'Hamilton, Bermuda',
    32.2949,
    -64.7814,
    'Atlantic/Bermuda',
    category: GoldenCategory.island,
  ),
  GoldenPoint(
    'Tórshavn, Faroe Islands',
    62.0079,
    -6.7708,
    'Atlantic/Faroe',
    category: GoldenCategory.island,
  ),
  GoldenPoint(
    'Nuuk, Greenland',
    64.1836,
    -51.7214,
    'America/Nuuk',
    category: GoldenCategory.island,
  ),
  GoldenPoint(
    'Port Louis, Mauritius',
    -20.1609,
    57.5012,
    'Indian/Mauritius',
    category: GoldenCategory.island,
  ),
  GoldenPoint(
    'Malé, Maldives',
    4.1755,
    73.5093,
    'Indian/Maldives',
    category: GoldenCategory.island,
  ),
  GoldenPoint(
    'Victoria, Seychelles',
    -4.6191,
    55.4513,
    'Indian/Mahe',
    category: GoldenCategory.island,
  ),
  GoldenPoint(
    'Saint-Denis, Réunion',
    -20.8823,
    55.4504,
    'Indian/Reunion',
    category: GoldenCategory.island,
  ),
  GoldenPoint(
    'Apia, Samoa',
    -13.8333,
    -171.7667,
    'Pacific/Apia',
    category: GoldenCategory.island,
  ),
  GoldenPoint(
    "Nuku'alofa, Tonga",
    -21.1393,
    -175.2049,
    'Pacific/Tongatapu',
    category: GoldenCategory.island,
  ),
  GoldenPoint(
    'Hagåtña, Guam',
    13.4745,
    144.7504,
    'Pacific/Guam',
    category: GoldenCategory.island,
  ),
  GoldenPoint(
    'Papeete, Tahiti',
    -17.5516,
    -149.5585,
    'Pacific/Tahiti',
    category: GoldenCategory.island,
  ),
  GoldenPoint(
    'Puerto Ayora, Galápagos',
    -0.7393,
    -90.3134,
    'Pacific/Galapagos',
    category: GoldenCategory.island,
  ),
  GoldenPoint(
    'Hanga Roa, Easter Island',
    -27.1500,
    -109.4333,
    'Pacific/Easter',
    category: GoldenCategory.island,
  ),
  GoldenPoint(
    'Nouméa, New Caledonia',
    -22.2758,
    166.4580,
    'Pacific/Noumea',
    category: GoldenCategory.island,
  ),
  GoldenPoint(
    'Kingston, Norfolk Island',
    -29.0408,
    167.9547,
    'Pacific/Norfolk',
    category: GoldenCategory.island,
  ),
  GoldenPoint(
    'Waitangi, Chatham Islands',
    -43.9535,
    -176.5597,
    'Pacific/Chatham',
    category: GoldenCategory.island,
    note: 'A 45-minute offset from Pacific/Auckland, and a small target.',
  ),
  GoldenPoint(
    'Honiara, Solomon Islands',
    -9.4456,
    159.9729,
    'Pacific/Guadalcanal',
    category: GoldenCategory.island,
  ),
  GoldenPoint(
    'Port Vila, Vanuatu',
    -17.7333,
    168.3273,
    'Pacific/Efate',
    category: GoldenCategory.island,
  ),
  GoldenPoint(
    'Palikir, Micronesia',
    6.9248,
    158.1611,
    'Pacific/Pohnpei',
    category: GoldenCategory.island,
    note: 'Palikir is on Pohnpei; Micronesia spans several identifiers.',
  ),
  GoldenPoint(
    'Saint-Pierre',
    46.7784,
    -56.1774,
    'America/Miquelon',
    category: GoldenCategory.island,
  ),
  GoldenPoint(
    'Stanley, Falkland Islands',
    -51.6938,
    -57.8569,
    'Atlantic/Stanley',
    category: GoldenCategory.island,
  ),
  GoldenPoint(
    'Jamestown, Saint Helena',
    -15.9387,
    -5.7168,
    'Atlantic/St_Helena',
    category: GoldenCategory.island,
  ),
  GoldenPoint(
    'Willemstad, Curaçao',
    12.1091,
    -68.9316,
    'America/Curacao',
    category: GoldenCategory.island,
  ),
  GoldenPoint(
    'Bridgetown, Barbados',
    13.1132,
    -59.5988,
    'America/Barbados',
    category: GoldenCategory.island,
  ),

  // ========================================================= antarctic ====
  GoldenPoint(
    'Rothera Station',
    -67.5675,
    -68.1272,
    'Antarctica/Rothera',
    category: GoldenCategory.antarctic,
  ),
  GoldenPoint(
    'Palmer Station',
    -64.7743,
    -64.0530,
    'Antarctica/Palmer',
    category: GoldenCategory.antarctic,
  ),
  GoldenPoint(
    'Casey Station',
    -66.2821,
    110.5285,
    'Antarctica/Casey',
    category: GoldenCategory.antarctic,
  ),
  GoldenPoint(
    'Davis Station',
    -68.5764,
    77.9689,
    'Antarctica/Davis',
    category: GoldenCategory.antarctic,
  ),
  GoldenPoint(
    'Mawson Station',
    -67.6027,
    62.8738,
    'Antarctica/Mawson',
    category: GoldenCategory.antarctic,
  ),
  GoldenPoint(
    'Vostok Station',
    -78.4645,
    106.8372,
    'Antarctica/Vostok',
    category: GoldenCategory.antarctic,
  ),
  GoldenPoint(
    'Syowa Station',
    -69.0067,
    39.5900,
    'Antarctica/Syowa',
    category: GoldenCategory.antarctic,
  ),
  GoldenPoint(
    'Troll Station',
    -72.0114,
    2.5350,
    'Antarctica/Troll',
    category: GoldenCategory.antarctic,
  ),
  GoldenPoint(
    "Dumont d'Urville Station",
    -66.6628,
    140.0014,
    'Antarctica/DumontDUrville',
    category: GoldenCategory.antarctic,
  ),
  GoldenPoint(
    'Unclaimed Antarctic sector, 10°W',
    -78.0000,
    -10.0000,
    'Etc/UTC',
    category: GoldenCategory.antarctic,
    note:
        'Antarctic territory with no station keeping a national time falls to '
        'Etc/UTC. This is the only identifier in the dataset absent from '
        "tzdb's zone.tab, which makes it easy to mistake for an artifact and "
        'filter out; it is a real six-vertex land polygon.\n'
        '\n'
        'PROVENANCE, weaker than the rest of this file: the expectation is '
        'externally verified — timezonefinder and tzf both return Etc/UTC here '
        '— but the coordinate was chosen from the dataset, because the region '
        'contains no named station to anchor it to. It is the one fixture here '
        'that was not written before looking at the data.',
  ),

  // ===================================================== antimeridian ====
  // The five zones split by the 180th meridian. A fixture on one
  // side exercises only one polygon, so where a place in the far half can be
  // named from an external source, both halves are sampled: Adak/Attu,
  // Anadyr/Cape Dezhnev, Suva/Taveuni, McMurdo/Ross Ice Shelf.
  //
  // Pacific/Funafuti is sampled on one side only, deliberately — see its note.
  GoldenPoint(
    'Adak, Alaska, USA',
    51.8800,
    -176.6581,
    'America/Adak',
    category: GoldenCategory.antimeridian,
    note: 'East half of a zone split at 180. Attu covers the west half.',
  ),
  GoldenPoint(
    'Attu Island, Alaska, USA',
    52.9000,
    172.9000,
    'America/Adak',
    category: GoldenCategory.antimeridian,
    note:
        'West of 180 but administratively Alaskan — the far side of the '
        'America/Adak split.',
  ),
  GoldenPoint(
    'Anadyr, Russia',
    64.7337,
    177.5087,
    'Asia/Anadyr',
    category: GoldenCategory.antimeridian,
    note: 'West of 180; paired with Cape Dezhnev on the far side.',
  ),
  GoldenPoint(
    'Cape Dezhnev, Russia',
    66.0800,
    -169.6500,
    'Asia/Anadyr',
    category: GoldenCategory.antimeridian,
    note:
        'The easternmost point of Eurasia, in Chukotka — past 180, and so in '
        'the other half of the Asia/Anadyr split.',
  ),
  GoldenPoint(
    'Suva, Fiji',
    -18.1416,
    178.4419,
    'Pacific/Fiji',
    category: GoldenCategory.antimeridian,
  ),
  GoldenPoint(
    'Taveuni, Fiji',
    -16.8500,
    -179.9700,
    'Pacific/Fiji',
    category: GoldenCategory.antimeridian,
    note:
        'The 180th meridian runs through Taveuni, putting it in the eastern '
        'half of the Pacific/Fiji split.',
  ),
  GoldenPoint(
    'Funafuti, Tuvalu',
    -8.5211,
    179.1962,
    'Pacific/Funafuti',
    category: GoldenCategory.antimeridian,
    note:
        'Only one half is sampled. Tuvalu\'s inhabited atolls all lie west of '
        '180; the geometry crossing the meridian belongs to islets that '
        'cannot be named from an external source, and inventing a coordinate '
        'there would make this an oracle-derived fixture.',
  ),
  GoldenPoint(
    'McMurdo Station',
    -77.8419,
    166.6863,
    'Antarctica/McMurdo',
    category: GoldenCategory.antimeridian,
    note:
        'The Ross Dependency spans the meridian, so McMurdo is one of the '
        'five split zones.',
  ),
  GoldenPoint(
    'Ross Ice Shelf, east of 180',
    -80.0000,
    -170.0000,
    'Antarctica/McMurdo',
    category: GoldenCategory.antimeridian,
    note:
        'The Ross Dependency runs from 160°E to 150°W, so this is the eastern '
        'half of the Antarctica/McMurdo split. Not a settlement, but a '
        'defensible external claim about the territory.',
  ),

  // ============================================================ coastal ====
  // Working ports. The README warns that a coordinate on a beach, pier or
  // ferry can fall outside every land polygon and return null — a real risk
  // for the address use case, and until now an entirely untested one. A port
  // is that risk at its sharpest: infrastructure that is on land by any human
  // reckoning but sits right on the coastline the polygons follow.
  GoldenPoint(
    'Port of Dubrovnik, Croatia',
    42.6634651,
    18.0591377,
    'Europe/Zagreb',
    category: GoldenCategory.border,
    note:
        'Paired with the Port of Bari across the Adriatic; the sea between '
        'them is an ocean fixture below.',
  ),
  GoldenPoint(
    'Port of Bari, Italy',
    41.137428,
    16.8600823,
    'Europe/Rome',
    category: GoldenCategory.border,
  ),

  GoldenPoint(
    'Port of Dover, United Kingdom',
    51.1269705,
    1.3230653,
    'Europe/London',
    category: GoldenCategory.border,
    note: 'Paired with the Port of Calais across the Dover Strait.',
  ),
  GoldenPoint(
    'Port of Calais, France',
    50.9744815,
    1.8765687,
    'Europe/Paris',
    category: GoldenCategory.border,
  ),
  GoldenPoint(
    'Dover Strait, mid-channel',
    51.050726,
    1.599817,
    'Europe/Paris',
    category: GoldenCategory.border,
    note:
        'Open water that still resolves, and the reason `null` cannot be read '
        'as "at sea". Country polygons follow OSM administrative boundaries, '
        'which extend ~12 nautical miles over territorial waters; the strait '
        'is only ~42 km across, so the British and French claims meet mid-'
        'channel with nothing unclaimed between them.\n'
        '\n'
        'PROVENANCE, as for the Antarctic sector below: the coordinate is the '
        'midpoint of the two ports, but which side of the maritime boundary it '
        'falls on was verified rather than predicted — the ports are not '
        'directly opposite, so their midpoint is not the median line. '
        'timezonefinder and tzf both return Europe/Paris here.',
  ),

  // ============================================================= ocean ====
  // A land-only dataset must return nothing here. Only timezonefinder can
  // verify these: tzf ships the with-oceans variant and answers Etc/GMT±N.
  GoldenPoint('Mid-Pacific', 0.0, -140.0, null, category: GoldenCategory.ocean),
  GoldenPoint(
    'South Atlantic',
    -40.0,
    -30.0,
    null,
    category: GoldenCategory.ocean,
  ),
  GoldenPoint(
    'Equatorial Atlantic',
    0.0,
    -25.0,
    null,
    category: GoldenCategory.ocean,
  ),
  GoldenPoint(
    'Central Indian Ocean',
    -20.0,
    80.0,
    null,
    category: GoldenCategory.ocean,
  ),
  GoldenPoint(
    'North Pacific',
    40.0,
    -170.0,
    null,
    category: GoldenCategory.ocean,
  ),
  GoldenPoint(
    'Southern Ocean',
    -55.0,
    100.0,
    null,
    category: GoldenCategory.ocean,
  ),
  GoldenPoint(
    'Arctic Ocean, near the pole',
    88.0,
    0.0,
    null,
    category: GoldenCategory.ocean,
  ),
  GoldenPoint(
    'Bay of Bengal',
    15.0,
    88.0,
    null,
    category: GoldenCategory.ocean,
  ),
  GoldenPoint(
    'Adriatic Sea, between Dubrovnik and Bari',
    41.9004,
    17.4596,
    null,
    category: GoldenCategory.ocean,
    note:
        'The midpoint of the two port fixtures above. A narrow sea between two '
        'land zones, rather than open ocean — the case where a grid cell is '
        'most likely to wrongly claim water for a neighbour.',
  ),

  // ============================================== additional coverage ====
  // More zones, to widen the share of the 419 identifiers exercised at all.
  GoldenPoint('Reykjahlíð, Iceland', 65.6417, -16.9181, 'Atlantic/Reykjavik'),
  GoldenPoint('Oslo, Norway', 59.9139, 10.7522, 'Europe/Oslo'),
  GoldenPoint('Copenhagen, Denmark', 55.6761, 12.5683, 'Europe/Copenhagen'),
  GoldenPoint('Brussels, Belgium', 50.8503, 4.3517, 'Europe/Brussels'),
  GoldenPoint('Amsterdam, Netherlands', 52.3676, 4.9041, 'Europe/Amsterdam'),
  GoldenPoint('Luxembourg City', 49.6116, 6.1319, 'Europe/Luxembourg'),
  GoldenPoint('Vienna, Austria', 48.2082, 16.3738, 'Europe/Vienna'),
  GoldenPoint('Prague, Czechia', 50.0755, 14.4378, 'Europe/Prague'),
  GoldenPoint('Bratislava, Slovakia', 48.1486, 17.1077, 'Europe/Bratislava'),
  GoldenPoint('Budapest, Hungary', 47.4979, 19.0402, 'Europe/Budapest'),
  GoldenPoint('Ljubljana, Slovenia', 46.0569, 14.5058, 'Europe/Ljubljana'),
  GoldenPoint('Zagreb, Croatia', 45.8150, 15.9819, 'Europe/Zagreb'),
  GoldenPoint(
    'Sarajevo, Bosnia and Herzegovina',
    43.8563,
    18.4131,
    'Europe/Sarajevo',
  ),
  GoldenPoint('Belgrade, Serbia', 44.7866, 20.4489, 'Europe/Belgrade'),
  GoldenPoint('Skopje, North Macedonia', 41.9981, 21.4254, 'Europe/Skopje'),
  GoldenPoint('Tirana, Albania', 41.3275, 19.8187, 'Europe/Tirane'),
  GoldenPoint('Sofia, Bulgaria', 42.6977, 23.3219, 'Europe/Sofia'),
  GoldenPoint('Chișinău, Moldova', 47.0105, 28.8638, 'Europe/Chisinau'),
  GoldenPoint('Minsk, Belarus', 53.9006, 27.5590, 'Europe/Minsk'),
  GoldenPoint('Vilnius, Lithuania', 54.6872, 25.2797, 'Europe/Vilnius'),
  GoldenPoint('Riga, Latvia', 56.9496, 24.1052, 'Europe/Riga'),
  GoldenPoint('Tallinn, Estonia', 59.4370, 24.7536, 'Europe/Tallinn'),
  GoldenPoint('Nicosia, Cyprus', 35.1856, 33.3823, 'Asia/Nicosia'),
  GoldenPoint('Tbilisi, Georgia', 41.7151, 44.8271, 'Asia/Tbilisi'),
  GoldenPoint('Baku, Azerbaijan', 40.4093, 49.8671, 'Asia/Baku'),
  GoldenPoint('Almaty, Kazakhstan', 43.2220, 76.8512, 'Asia/Almaty'),
  GoldenPoint('Bishkek, Kyrgyzstan', 42.8746, 74.5698, 'Asia/Bishkek'),
  GoldenPoint('Dushanbe, Tajikistan', 38.5598, 68.7870, 'Asia/Dushanbe'),
  GoldenPoint('Ashgabat, Turkmenistan', 37.9601, 58.3261, 'Asia/Ashgabat'),
  GoldenPoint('Kabul, Afghanistan', 34.5553, 69.2075, 'Asia/Kabul'),
  GoldenPoint('Baghdad, Iraq', 33.3152, 44.3661, 'Asia/Baghdad'),
  GoldenPoint('Amman, Jordan', 31.9454, 35.9284, 'Asia/Amman'),
  GoldenPoint('Beirut, Lebanon', 33.8938, 35.5018, 'Asia/Beirut'),
  GoldenPoint('Damascus, Syria', 33.5138, 36.2765, 'Asia/Damascus'),
  GoldenPoint('Kuwait City, Kuwait', 29.3759, 47.9774, 'Asia/Kuwait'),
  GoldenPoint('Doha, Qatar', 25.2854, 51.5310, 'Asia/Qatar'),
  GoldenPoint('Manama, Bahrain', 26.2285, 50.5860, 'Asia/Bahrain'),
  GoldenPoint('Muscat, Oman', 23.5880, 58.3829, 'Asia/Muscat'),
  GoldenPoint("Sana'a, Yemen", 15.3694, 44.1910, 'Asia/Aden'),
  GoldenPoint('Colombo, Sri Lanka', 6.9271, 79.8612, 'Asia/Colombo'),
  GoldenPoint('Yangon, Myanmar', 16.8661, 96.1951, 'Asia/Yangon'),
  GoldenPoint('Phnom Penh, Cambodia', 11.5564, 104.9282, 'Asia/Phnom_Penh'),
  GoldenPoint('Vientiane, Laos', 17.9757, 102.6331, 'Asia/Vientiane'),
  GoldenPoint(
    'Hanoi, Vietnam',
    21.0278,
    105.8342,
    'Asia/Bangkok',
    note:
        'Counterintuitive but correct, and verified against IANA\'s own '
        'zone1970.tab, which lists "Asia/Bangkok — north Vietnam" and '
        '"Asia/Ho_Chi_Minh — south Vietnam". Northern Vietnam has agreed with '
        'Bangkok since 1970, so tzdb does not give it a separate zone. '
        'Do not "correct" this to Asia/Ho_Chi_Minh.',
  ),
  GoldenPoint(
    'Ho Chi Minh City, Vietnam',
    10.8231,
    106.6297,
    'Asia/Ho_Chi_Minh',
    note: 'The southern counterpart to Hanoi, in the zone Hanoi is not in.',
  ),
  GoldenPoint('Kuala Lumpur, Malaysia', 3.1390, 101.6869, 'Asia/Kuala_Lumpur'),
  GoldenPoint('Bandar Seri Begawan, Brunei', 4.9031, 114.9398, 'Asia/Brunei'),
  GoldenPoint('Taipei, Taiwan', 25.0330, 121.5654, 'Asia/Taipei'),
  GoldenPoint('Macau', 22.1987, 113.5439, 'Asia/Macau'),
  GoldenPoint('Ulaanbaatar, Mongolia', 47.8864, 106.9057, 'Asia/Ulaanbaatar'),
  GoldenPoint('Pyongyang, North Korea', 39.0392, 125.7625, 'Asia/Pyongyang'),
  // Ürümqi is deliberately absent: it sits inside the documented
  // Asia/Shanghai–Asia/Urumqi overlap, so its answer comes from the overlap
  // tiebreak rather than from any external fact. It is pinned in
  // overlap_pins.dart instead. This was caught by cross-verification —
  // timezonefinder and tzf disagreed there because each applies its own
  // tiebreak, which is exactly the signal that a fixture is mis-filed.
  GoldenPoint('Thimphu, Bhutan', 27.4712, 89.6339, 'Asia/Thimphu'),
  GoldenPoint('Dili, Timor-Leste', -8.5569, 125.5603, 'Asia/Dili'),
  GoldenPoint('Jayapura, Indonesia', -2.5330, 140.7181, 'Asia/Jayapura'),
  GoldenPoint('Makassar, Indonesia', -5.1477, 119.4327, 'Asia/Makassar'),
  GoldenPoint(
    'Port Moresby, Papua New Guinea',
    -9.4438,
    147.1803,
    'Pacific/Port_Moresby',
  ),
  // Darwin is deliberately absent: it is already in bootstrapGoldens, and the
  // two sets are concatenated. A test rejects cross-set duplicates.
  GoldenPoint('Hobart, Australia', -42.8821, 147.3272, 'Australia/Hobart'),
  GoldenPoint(
    'Eucla, Australia',
    -31.6767,
    128.8836,
    'Australia/Eucla',
    note: 'A 45-minute offset and a very small zone.',
  ),
  GoldenPoint(
    'Lord Howe Island, Australia',
    -31.5553,
    159.0821,
    'Australia/Lord_Howe',
    note: 'A 30-minute DST shift, unique in tzdb.',
  ),
  GoldenPoint(
    'Wellington, New Zealand',
    -41.2866,
    174.7756,
    'Pacific/Auckland',
  ),
  GoldenPoint('Dakar, Senegal', 14.7167, -17.4677, 'Africa/Dakar'),
  GoldenPoint('Abidjan, Côte d\'Ivoire', 5.3600, -4.0083, 'Africa/Abidjan'),
  GoldenPoint('Bamako, Mali', 12.6392, -8.0029, 'Africa/Bamako'),
  GoldenPoint(
    'Ouagadougou, Burkina Faso',
    12.3714,
    -1.5197,
    'Africa/Ouagadougou',
  ),
  GoldenPoint('Niamey, Niger', 13.5117, 2.1251, 'Africa/Niamey'),
  GoldenPoint('N\'Djamena, Chad', 12.1348, 15.0557, 'Africa/Ndjamena'),
  GoldenPoint('Khartoum, Sudan', 15.5007, 32.5599, 'Africa/Khartoum'),
  GoldenPoint('Juba, South Sudan', 4.8594, 31.5713, 'Africa/Juba'),
  GoldenPoint('Kampala, Uganda', 0.3476, 32.5825, 'Africa/Kampala'),
  GoldenPoint(
    'Dar es Salaam, Tanzania',
    -6.7924,
    39.2083,
    'Africa/Dar_es_Salaam',
  ),
  GoldenPoint('Kigali, Rwanda', -1.9441, 30.0619, 'Africa/Kigali'),
  GoldenPoint('Kinshasa, DR Congo', -4.4419, 15.2663, 'Africa/Kinshasa'),
  GoldenPoint(
    'Lubumbashi, DR Congo',
    -11.6876,
    27.5026,
    'Africa/Lubumbashi',
    note: 'DR Congo spans two zones; both are sampled.',
  ),
  GoldenPoint('Luanda, Angola', -8.8390, 13.2894, 'Africa/Luanda'),
  GoldenPoint('Windhoek, Namibia', -22.5609, 17.0658, 'Africa/Windhoek'),
  GoldenPoint('Gaborone, Botswana', -24.6282, 25.9231, 'Africa/Gaborone'),
  GoldenPoint('Harare, Zimbabwe', -17.8252, 31.0335, 'Africa/Harare'),
  GoldenPoint('Lusaka, Zambia', -15.3875, 28.3228, 'Africa/Lusaka'),
  GoldenPoint('Maputo, Mozambique', -25.9692, 32.5732, 'Africa/Maputo'),
  GoldenPoint(
    'Antananarivo, Madagascar',
    -18.8792,
    47.5079,
    'Indian/Antananarivo',
  ),
  GoldenPoint('Tunis, Tunisia', 36.8065, 10.1815, 'Africa/Tunis'),
  GoldenPoint('Tripoli, Libya', 32.8872, 13.1913, 'Africa/Tripoli'),
  GoldenPoint('Nouakchott, Mauritania', 18.0735, -15.9582, 'Africa/Nouakchott'),
  GoldenPoint(
    'Guatemala City, Guatemala',
    14.6349,
    -90.5069,
    'America/Guatemala',
  ),
  GoldenPoint(
    'San Salvador, El Salvador',
    13.6929,
    -89.2182,
    'America/El_Salvador',
  ),
  GoldenPoint(
    'Tegucigalpa, Honduras',
    14.0723,
    -87.1921,
    'America/Tegucigalpa',
  ),
  GoldenPoint('Managua, Nicaragua', 12.1150, -86.2362, 'America/Managua'),
  GoldenPoint('San José, Costa Rica', 9.9281, -84.0907, 'America/Costa_Rica'),
  GoldenPoint('Panama City, Panama', 8.9824, -79.5199, 'America/Panama'),
  GoldenPoint('Kingston, Jamaica', 17.9714, -76.7931, 'America/Jamaica'),
  GoldenPoint(
    'Port-au-Prince, Haiti',
    18.5944,
    -72.3074,
    'America/Port-au-Prince',
  ),
  GoldenPoint(
    'Santo Domingo, Dominican Republic',
    18.4861,
    -69.9312,
    'America/Santo_Domingo',
  ),
  GoldenPoint(
    'San Juan, Puerto Rico',
    18.4655,
    -66.1057,
    'America/Puerto_Rico',
  ),
  GoldenPoint('Caracas, Venezuela', 10.4806, -66.9036, 'America/Caracas'),
  GoldenPoint('Georgetown, Guyana', 6.8013, -58.1551, 'America/Guyana'),
  GoldenPoint('Paramaribo, Suriname', 5.8520, -55.2038, 'America/Paramaribo'),
  GoldenPoint('Cayenne, French Guiana', 4.9224, -52.3135, 'America/Cayenne'),
  GoldenPoint('Quito, Ecuador', -0.1807, -78.4678, 'America/Guayaquil'),
  GoldenPoint('Asunción, Paraguay', -25.2637, -57.5759, 'America/Asuncion'),
  GoldenPoint('Montevideo, Uruguay', -34.9011, -56.1645, 'America/Montevideo'),
  GoldenPoint('La Paz, Bolivia', -16.4897, -68.1193, 'America/La_Paz'),
  GoldenPoint(
    'Manaus, Brazil',
    -3.1190,
    -60.0217,
    'America/Manaus',
    note: 'Brazil spans several zones; three are sampled.',
  ),
  GoldenPoint('Recife, Brazil', -8.0476, -34.8770, 'America/Recife'),
  GoldenPoint(
    'St. John\'s, Canada',
    47.5615,
    -52.7126,
    'America/St_Johns',
    note: 'A 30-minute offset — Newfoundland.',
  ),
  GoldenPoint('Halifax, Canada', 44.6488, -63.5752, 'America/Halifax'),
  GoldenPoint('Edmonton, Canada', 53.5461, -113.4938, 'America/Edmonton'),
  GoldenPoint('Whitehorse, Canada', 60.7212, -135.0568, 'America/Whitehorse'),
  GoldenPoint('Iqaluit, Canada', 63.7467, -68.5170, 'America/Iqaluit'),
  GoldenPoint(
    'Regina, Canada',
    50.4452,
    -104.6189,
    'America/Regina',
    note: 'Saskatchewan does not observe DST and has its own identifier.',
  ),
  GoldenPoint('Juneau, USA', 58.3019, -134.4197, 'America/Juneau'),
  GoldenPoint('Nome, USA', 64.5011, -165.4064, 'America/Nome'),
  GoldenPoint('Boise, USA', 43.6150, -116.2023, 'America/Boise'),
  GoldenPoint('Tijuana, Mexico', 32.5149, -117.0382, 'America/Tijuana'),
  GoldenPoint('Cancún, Mexico', 21.1619, -86.8515, 'America/Cancun'),
  GoldenPoint('Chihuahua, Mexico', 28.6320, -106.0691, 'America/Chihuahua'),
];
