// Interesting border, same-state, coastal, and compact-tier timezone lookups.
//
// These lookups return IANA identifiers. To turn one into a civil time, use
// finder.findLocation() or '<lat>,<lon>'.toLocation(finder) and pass the
// Location to package:timezone's TZDateTime.

import 'package:timezone_finder/timezone_finder.dart';

void main() {
  final finder = TimeZoneFinder.exact();

  // Across the US–Mexico border: El Paso, Texas and Ciudad Juárez, Chihuahua
  // sit almost opposite each other, yet each follows its own country's zone.
  final elPaso = finder.find(31.8122375, -106.5823795);
  final ciudadJuarez = finder.find(31.653962, -106.6081154);

  print('El Paso, TX                          -> $elPaso'); // America/Denver
  print(
    'Ciudad Juárez, Chihuahua             -> $ciudadJuarez',
  ); // America/Ciudad_Juarez
  print(
    'Same metro area, different countries -> '
    '${elPaso != ciudadJuarez ? 'different zones' : 'same zone'}',
  );
  print('');

  // Inside Chihuahua state: northwest border municipalities (including
  // Ciudad Juárez) keep America/Ciudad_Juarez — aligned with the US side
  // (standard UTC−07:00, observes DST). The rest of the state, including
  // Chihuahua city, uses America/Chihuahua (standard UTC−06:00, no DST).
  final chihuahuaCity = finder.find(28.6353, -106.0889);

  print('Ciudad Juárez, Chihuahua -> $ciudadJuarez'); // America/Ciudad_Juarez
  print('Chihuahua city           -> $chihuahuaCity'); // America/Chihuahua
  print(
    'Same Mexican state       -> '
    '${ciudadJuarez != chihuahuaCity ? 'different zones' : 'same zone'}',
  );
  print('');

  // Across the Adriatic: the Port of Dubrovnik and the Port of Bari sit on
  // opposite coasts. Onshore port coordinates still resolve; open water
  // between them does not — the dataset is land-only, so sea returns null.
  const portOfDubrovnikLat = 42.6634651;
  const portOfDubrovnikLon = 18.0591377;
  const portOfBariLat = 41.137428;
  const portOfBariLon = 16.8600823;

  final portOfDubrovnik = finder.find(portOfDubrovnikLat, portOfDubrovnikLon);
  final portOfBari = finder.find(portOfBariLat, portOfBariLon);

  final midpointLat = (portOfDubrovnikLat + portOfBariLat) / 2;
  final midpointLon = (portOfDubrovnikLon + portOfBariLon) / 2;
  final midpoint = finder.find(midpointLat, midpointLon);

  print(
    'Port of Dubrovnik, Croatia       -> $portOfDubrovnik',
  ); // Europe/Zagreb
  print('Port of Bari, Italy              -> $portOfBari'); // Europe/Rome
  print(
    'Midpoint (Adriatic Sea)          -> ${midpoint ?? 'null (not on land)'}',
  );
  print(
    'Coastal ports on opposite shores -> '
    '${portOfDubrovnik != portOfBari ? 'different zones' : 'same zone'}',
  );
  print('');

  // Compact tier: enough for most apps (city / address lookups), far smaller
  // AOT binary (~11.4 MB vs ~43.7 MB for exact). Mainland China uses a single
  // zone named for Shanghai — there is no Asia/Beijing, even in Beijing.
  final compactFinder = TimeZoneFinder.compact();
  final palaceMuseum = compactFinder.find(39.9163488, 116.3945797);

  print('Palace Museum, Beijing -> $palaceMuseum'); // Asia/Shanghai
  print(
    'Note: IANA has no Asia/Beijing time zone — Beijing and Shanghai share '
    'Asia/Shanghai.',
  );
  print('');

  // The Dover Strait shows what "land-only" does *not* mean. The dataset
  // excludes the synthetic Etc/GMT ocean zones, but country polygons follow
  // OpenStreetMap administrative boundaries, which for a coastal state extend
  // about 12 nautical miles (~22 km) out over territorial waters.
  //
  // The strait is only ~42 km across, so the British and French claims meet in
  // the middle with nothing unclaimed between them. The midpoint is open water
  // and still resolves — it falls just on the French side of the boundary that
  // runs down the strait. Compare the Adriatic above, ~197 km across, where the
  // middle is international water and does return null.
  final portOfDover = finder.find(51.1269705, 1.3230653);
  final portOfCalais = finder.find(50.9744815, 1.8765687);
  final midpointOfDoverAndCalais = finder.find(51.050726, 1.599817);

  print('Port of Dover, United Kingdom -> $portOfDover'); // Europe/London
  print('Port of Calais, France        -> $portOfCalais'); // Europe/Paris
  print(
    'Midpoint (English Channel)    -> $midpointOfDoverAndCalais',
  ); // Europe/Paris — water, but inside France's claim; see README
  print('A null means no country claims the point, not that it is dry land.');
  print('');

  // Under Brazilian legal definitions (re-established by Federal Law No.
  // 12,876/2013 following earlier historical legislation), the time zone
  // boundary in the state of Amazonas is defined by an imaginary line drawn
  // between two specific municipalities: Tabatinga (in western Amazonas) and
  // Porto Acre (in the state of Acre). Due to the size of the municipalities
  // in the Amazonas state, two time zones may be defined in some of them.
  final easternPartOfPauini = compactFinder.find(-7.7120204, -67.0130633);
  final westernPartOfPauini = compactFinder.find(-7.7857015, -68.5215298);
  print(
    'Eastern part of Pauini Municipality, Amazonas, Brazil -> $easternPartOfPauini',
  ); // America/Manaus
  print(
    'Western part of Pauini Municipality, Amazonas, Brazil -> $westernPartOfPauini',
  ); // America/Eirunepe
  print('Some municipalities may be split into two time zones.');
  print('');

  print(
    'Boundaries for IANA tzdb ${finder.ianaDatabaseVersion}, '
    '${finder.availableTimeZones.length} zones (exact tier)',
  );
}
