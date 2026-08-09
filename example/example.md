# Examples

Two small programs — each entrypoint is a `main.dart` you can run directly.

| Target | Entry | Run |
| --- | --- | --- |
| VM / CLI | [`main.dart`](main.dart) | `dart run example/main.dart` |
| Local HTTP | [`server/main.dart`](server/main.dart) | `cd example/server && dart pub get && dart run` |

- **`main.dart`** — geocode five university hospitals, schedule a Geneva-anchored
  conference call, print local start/end times (`dart:io`, embedded boundaries).
- **`server/main.dart`** — Shelf + `shelf_router` departure board for Zurich Airport
  (ZRH). Takeoff is Zurich-local; landing is destination-local after the flight
  duration (`findLocation` + `TZDateTime`). Open http://localhost:8080/

Browser / Flutter web init (`initializeTimeZone` + `installBoundaries`) is
documented in the package README’s
[Web / Flutter web](../README.md#web--flutter-web) section.
