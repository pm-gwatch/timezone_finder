## 0.2.0

Breaking. 0.1.0 names have no `@Deprecated` aliases.

- **`browser.dart` is web-only**, like `package:timezone/browser.dart`. Importing it off web is now a compile error (0.1.0 failed at runtime). Cross-platform apps should conditionally import it on the same branch that loads the `.bin`. VM, CLI, server, and Flutter mobile/desktop keep using `timezone_finder.dart` (boundaries are embedded).
- **Cross-location APIs** now sit beside `package:timezone` names:
  - `String.toLocation()` → `String.findLocation()`
  - `TZDateTime.convertTo(location)` → `TZDateTime.toLocation(location)` (`toUtc` / `toLocal` analogue)
  - `TZDateTime.utcOffsetDifference(location)` → `TZDateTime.offsetDifference(location)`
- **English labels** drop "metazone" from public names (that word is CLDR lookup jargon):
  - `Location.metazoneName` → `Location.timeZoneGenericName`
  - `TZDateTime.metazoneName` → `TZDateTime.timeZoneLongName` (beside `timeZoneName`)
  - `MetazoneLocation` → `LocationZoneNames`
  - `MetazoneTZDateTime` → `TZDateTimeZoneNames`
  - Removed `TZDateTime.metazoneAbbreviation` — use `timeZoneName` (`CEST`) or `utcOffsetLabel` (`UTC±…`)
- **`TZDateTime.utcOffset`** → **`TZDateTime.utcOffsetLabel`** — display string (`UTC+04:30`), not `timeZoneOffset` (`Duration`).
- **`ianaDatabaseVersion`** → **`boundaryDataVersion`** — timezone-boundary-builder release, independent of the tzdb version behind `package:timezone`.

## 0.1.0

*   Initial release.
