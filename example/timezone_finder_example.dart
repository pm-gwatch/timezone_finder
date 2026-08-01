// Border, same-state and territorial-water timezone lookups.
//
// These lookups return IANA identifiers. To turn one into a civil time, use
// finder.findLocation() or '<lat>,<lon>'.toLocation(using: finder), then pass
// the Location to package:timezone's TZDateTime.

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

  // The Dover Strait shows what "land-only" does *not* mean. The dataset
  // excludes the synthetic Etc/GMT ocean zones, but country polygons follow
  // OpenStreetMap administrative boundaries, which for a coastal state extend
  // about 12 nautical miles (~22 km) out over territorial waters.
  //
  // The strait is only ~42 km across, so the British and French claims meet in
  // the middle with nothing unclaimed between them. The midpoint is open water
  // and still resolves — it falls just on the French side of the boundary that
  // runs down the strait. The README contrasts this with the Adriatic, ~197 km
  // across, where the middle is international water and does return null.
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

  print(
    'Boundaries for IANA tzdb ${finder.ianaDatabaseVersion}, '
    '${finder.availableTimeZones.length} zones (exact tier)',
  );
}
