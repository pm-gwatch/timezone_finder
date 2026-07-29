// Resolving the time zone of a geocoded address.
//
// The bundled index arrives at milestone 8; until then a finder must be
// constructed with explicit index bytes, so this example only shows the shape
// of the call.

import 'package:timezone_finder/timezone_finder.dart';

void main() {
  final finder = TimeZoneFinder();

  for (final (name, lat, lon) in <(String, double, double)>[
    ('Paris', 48.8566, 2.3522),
    ('Sydney', -33.8688, 151.2093),
    ('mid-Pacific', 0.0, -140.0),
  ]) {
    try {
      print('$name -> ${finder.find(lat, lon) ?? 'not on land'}');
    } on StateError catch (error) {
      print('$name -> $error');
      return;
    }
  }
}
