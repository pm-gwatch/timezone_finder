// Interesting border, same-state, coastal, and compact-tier timezone lookups.
//
// This package returns IANA identifiers only. For UTC offsets and DST, pass
// those identifiers to package:timezone.

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

  print(
    'Boundaries for IANA tzdb ${finder.ianaDatabaseVersion}, '
    '${finder.availableTimeZones.length} zones (exact tier)',
  );
}
