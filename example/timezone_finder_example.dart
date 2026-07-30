// Resolving the time zone of a geocoded address.

import 'package:timezone_finder/timezone_finder.dart';

void main() {
  final finder = TimeZoneFinder();

  for (final (name, lat, lon) in <(String, double, double)>[
    ('Calais, France', 50.9523508, 1.827782),
    // Dover is located in the UK and is the closest point to Calais.
    ('Dover, UK', 51.126331, 1.2597898),
    // El Paso stands on the Rio Grande across the Mexico–United States border
    // from Ciudad Juárez, the most populous city in the Mexican state of
    // Chihuahua.
    ('El Paso, US', 31.8122375, -106.5823795),
    // Ciduad Juárez is located in Chihuahua State, Mexico but follows the same
    // time zone as El Paso (Mountain Standard Time UTC-7 with DST).
    ('Ciudad Juárez, Mexico', 31.653962, -106.6081154),
    // Chihuahua is located in Chihuahua State, Mexico and follows the Central
    // Time Zone (UTC-6).
    ('Chihuahua, Mexico', 28.6773621, -106.222981),
    // Puerto Williams is a city, port and naval base on Navarino Island in
    // Chile.
    ('Puerto Williams, Chile', -54.933056, -67.316389),
    // Ushuaia is located on the other side of the Beagle Channel from Puerto
    // Williams and in Argentina.
    ('Ushuaia, Argentina', -54.8066643, -68.4586898),
    // "Asia/Shanghai" is used instead of "Asia/Beijing" because Shanghai is the
    // most populous city in the zone
    ('Beijing, China', 39.9389436, 116.067809),
    // timezone_finder only finds time zones on land, so the mid-Pacific point
    // is not found.
    ('mid-Pacific', 0.0, -140.0),
  ]) {
    print('$name -> ${finder.find(lat, lon) ?? 'not on land'}');
  }
}
