// Resolving the time zone of a geocoded address.

import 'package:timezone_finder/timezone_finder.dart';

void main() {
  final finder = TimeZoneFinder.exact();

  for (final (name, lat, lon) in <(String, double, double)>[
    ('Paris', 48.8566, 2.3522),
    ('Sydney', -33.8688, 151.2093),
    ('mid-Pacific', 0.0, -140.0),
  ]) {
    print('$name -> ${finder.find(lat, lon) ?? 'not on land'}');
  }

  print(
    'boundaries for IANA tzdb ${finder.ianaDatabaseVersion}, '
    '${finder.availableTimeZones.length} zones',
  );
}
