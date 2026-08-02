// Cross-border and same-state timezone lookups.
//
// These return IANA identifiers or Locations. Pass a Location to
// package:timezone's TZDateTime for civil times.

import 'package:timezone/data/latest_all.dart';
import 'package:timezone/timezone.dart';
import 'package:timezone_finder/timezone_finder.dart';

void main() {
  initializeTimeZones();

  // Across the US–Mexico border: El Paso, Texas and Ciudad Juárez, Chihuahua
  // sit almost opposite each other, yet each follows its own country's zone.
  final elPaso = findId(31.8122375, -106.5823795);
  final ciudadJuarez = findId(31.653962, -106.6081154);

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
  final chihuahuaCity = findId(28.6353, -106.0889);

  print('Ciudad Juárez, Chihuahua -> $ciudadJuarez'); // America/Ciudad_Juarez
  print('Chihuahua city           -> $chihuahuaCity'); // America/Chihuahua
  print(
    'Same Mexican state       -> '
    '${ciudadJuarez != chihuahuaCity ? 'different zones' : 'same zone'}',
  );
  print('');

  final sf = '37.7749,-122.4194'.toLocation()!;
  final local = TZDateTime(sf, 2026, 8, 2, 17);
  print(
    'San Francisco wall clock -> $local '
    '(${local.location.name})',
  );
  print('');

  print(
    'Boundaries for IANA tzdb $ianaDatabaseVersion, '
    '${availableTimeZoneIds.length} zones',
  );
}
