// Cross-border and same-state timezone lookups.
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

  print(
    'Boundaries for IANA tzdb ${finder.ianaDatabaseVersion}, '
    '${finder.availableTimeZones.length} zones (exact tier)',
  );
}
