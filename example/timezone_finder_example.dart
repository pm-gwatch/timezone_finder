// Cross-border and same-state timezone lookups.
//
// These lookups return IANA identifiers. To turn one into a civil time, use
// finder.findLocation() or '<lat>,<lon>'.toLocation(), then pass the Location
// to package:timezone's TZDateTime.

import 'package:timezone_finder/timezone_finder.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

void main() {
  tz.initializeTimeZones(); // Required to use Location and TZDateTime classes from timezone package

  // final finder = TimeZoneFinder();

  // Across the US–Mexico border: El Paso, Texas and Ciudad Juárez, Chihuahua
  // sit almost opposite each other, yet each follows its own country's zone.

  //final elPaso = finder.findId(31.8122375, -106.5823795);
  final ciudadJuarez = "31.653962, -106.6081154".toLocation();

  //print('El Paso, TX                          -> $elPaso'); // America/Denver
  print(
    'Ciudad Juárez, Chihuahua             -> ${ciudadJuarez?.name}',
  ); // America/Ciudad_Juarez
  // print(
  //  'Same metro area, different countries -> '
  //  '${elPaso != ciudadJuarez?.name ? 'different zones' : 'same zone'}',
  //);
  print('');

  // Inside Chihuahua state: northwest border municipalities (including
  // Ciudad Juárez) keep America/Ciudad_Juarez — aligned with the US side
  // (standard UTC−07:00, observes DST). The rest of the state, including
  // Chihuahua city, uses America/Chihuahua (standard UTC−06:00, no DST).

  final chihuahuaCity = "28.6353, -106.0889".toLocation();

  print('Ciudad Juárez, Chihuahua -> $ciudadJuarez'); // America/Ciudad_Juarez
  print('Chihuahua city           -> $chihuahuaCity'); // America/Chihuahua
  print(
    'Same Mexican state       -> '
    '${ciudadJuarez != chihuahuaCity ? 'different zones' : 'same zone'}',
  );
  print('');

  tz.TZDateTime("37.757807,-122.5200013".toLocation()!, 2026, 08, 02, 17, 0, 0);

  // print(
  //   'Boundaries for IANA tzdb ${finder.ianaDatabaseVersion}, '
  //   '${finder.availableTimeZones.length} zones',
  // );
}
