## 0.1.0

- Initial release.
- `TZDateTime.utcOffset` — always `UTC` / `UTC±…` (never letter codes like `CEST`).
- Public lookup API is `findLocation` (and `Location.name` for the IANA id); `findLocationName` and `availableLocationNames` are package-internal.
