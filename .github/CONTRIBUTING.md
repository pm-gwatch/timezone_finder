# Contributing to timezone_finder

Bug reports, fixes and improvements are welcome. Open an
[issue](https://github.com/pm-gwatch/timezone_finder/issues/new/choose) first
for anything larger than a small fix, so we can agree on the approach before
you write the code.

## Wrong time zone at a coordinate?

Check these before opening a code issue:

- **Open sea returns `null`.** Land polygons extend ~22 km offshore. Beyond
  that, `null` is the expected answer.
- **Borders are simplified to ~110 m.** A point within about 110 m of a zone
  border can land on the other side.
- **The borders come from
  [Timezone Boundary Builder](https://github.com/evansiroky/timezone-boundary-builder),
  built from OpenStreetMap.** If the border is wrong there too, the fix belongs
  in OpenStreetMap. It reaches this package with the next boundary release.

If none of these explains it, use the **Wrong time zone** issue form and give
the longitude and latitude.

## Setting up

You need Dart 3.10 or later.

```bash
git clone https://github.com/<you>/timezone_finder.git
cd timezone_finder
dart pub get
```

## Before you open a pull request

Pull requests to `main` must pass the same checks as CI:

```bash
dart analyze --fatal-infos
dart format .
dart test
```

- **Formatting** is checked with Dart 3.13.0. Other SDK versions format a few
  constructs differently, so if CI's format job fails on lines you did not
  touch, mention it in the pull request rather than fighting it.
- **Web code** (`lib/browser.dart` and the integer/bit paths) also runs in
  Chrome: `dart test -p chrome test/varint_test.dart test/quantization_test.dart test/browser_parity_test.dart test/browser_preinstall_test.dart`.
- **Oracle tests** compare lookups against the full source GeoJSON. They skip
  themselves unless you fetch it first with `dart run tool/fetch_data.dart`
  (a ~51 MB download, ~170 MB on disk under `.dart_tool/`). Run them when you
  change the index format, the geometry code or the lookup.

For a first-time contributor, CI waits until a maintainer approves the run.

## What to leave alone

- **`lib/src/generated/` and `tool/release/`** are generated. Do not edit them
  by hand. Boundary data refreshes are done by the maintainer with
  `tool/refresh.dart` (see
  [the release runbook](../tool/docs/release-runbook.md)).
- **Version numbers.** The maintainer sets the version at release. Add a line
  under a new `## Unreleased` heading in `CHANGELOG.md` for any change users
  will notice.

## Licensing

Code contributions are accepted under the MIT licence in
[`LICENSE`](../LICENSE). The boundary data is under ODbL v1.0
([`LICENSE-DATA`](../LICENSE-DATA)); a contribution that changes the data, or
how it is derived, has to stay compatible with ODbL share-alike.

## Security

Report security problems privately. See [`SECURITY.md`](SECURITY.md).
