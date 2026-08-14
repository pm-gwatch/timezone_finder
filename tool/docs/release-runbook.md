# Release runbook — tzdb, tzbb, and CLDR

Maintainer guide. App consumers never run these tools — generated files are
committed. Run commands from the package root.

## Which upstream means what

| Upstream | Example | What this repo does |
| --- | --- | --- |
| **IANA tzdb** | `2026a` → `2026b` | **Nothing in generators.** Offsets / DST / letter abbreviations come from `package:timezone` in the consuming app. A tzdb release matters here only once TZBB ships boundaries built against it (and when you bump the `timezone` dependency for tests / docs). |
| **timezone-boundary-builder (TZBB)** | `2026c` → `2027a` | Regenerates every shipped boundary artifact. Tags are named after the tzdb version they target — that is why `boundaryDataVersion` reads e.g. `2026c`. |
| **Unicode CLDR** | `48` → `49` | Regenerates English metazone display names only. No boundary data changes. |

TZBB tags are **not** IANA transition rules. Keep using `latest_all` in apps and docs.

Both regeneration paths need the network. The TZBB path also downloads ~51 MB
(expanding to ~170 MB under `.dart_tool/`) unless that release is already
cached.

| Upstream | Primary command |
| --- | --- |
| **TZBB** | `dart run tool/refresh.dart --release <tag>` |
| **CLDR** | `dart run tool/generate_metazone_data.dart` (or full refresh) |
| **IANA tzdb** | Bump `package:timezone` — see [New IANA tzdb release](#new-iana-tzdb-release) |

---

## New TZBB release

### 1. Look before you rebuild

```bash
dart run tool/refresh.dart --release <new-tag> --verify
```

Read the triage block at the top — it fetches a few kilobytes of
`timezone-names.json` before the 51 MB archive and tells you whether the
identifier set moved:

- *identifier set unchanged* → geometry only → **patch** release.
- *IDENTIFIER SET CHANGED* → answers users depend on can change → **minor**
  release, and a changelog entry naming the added/removed identifiers.

The byte comparison that follows **will FAIL**, and that is correct: byte
identity is only claimed release-for-release, and what is committed is still
the old release. You are running this for the triage, not the verdict.

### 2. Bump the pin first

Edit `defaultRelease` in `tool/src/fetch.dart` to the new tag.

Do this **before** the regeneration run, not after. `refresh.dart` runs the
full suite at the end, and several tests compare the regenerated data against
`defaultRelease`; leaving it stale makes an otherwise good run fail at the last
step.

### 3. Regenerate

```bash
dart run tool/refresh.dart --release <new-tag>
```

That triages, runs `tool/generate_data.dart` for both index tiers, refreshes
the CLDR metazone tables, formats, and runs the suite. It writes:

- `lib/src/generated/` — the bundled index as base64 Dart chunks, and
  `metazone_data.dart`
- `lib/src/generated/boundaries_bin.dart` — `boundariesBinName` (and related constants)
- `lib/data/boundaries_<tag>.bin` — the web asset
- `tool/release/` — the unsimplified baseline and `timezone-names.json`

Add `--no-tests` to iterate faster, but do not commit on the strength of a run
that skipped them.

Default `--tolerance` (~110 m) and `--chunk-kb` are fine unless you
intentionally change what ships. See `tool/refresh.dart` for flags.

### 4. Check the dart2js headroom

```bash
dart run tool/measure_pip_bound.dart
```

Point-in-polygon runs in fixed-point integers, and on dart2js `int` is a
double. The pack already refuses to emit rings whose sound `|side|` bound
reaches 2⁵³ (`assertPipDart2jsSafe` in `tool/src/build_index.dart`), so an
unsafe release fails at step 3 rather than shipping.

This step is the only report of how much margin is left. Record the headroom
multiple it prints and compare it with the previous release: a shrinking
multiple is the early warning that a future TZBB geometry change will hard-fail
the pack — better known now than mid-bump. `refresh.dart` does not run this
tool, so it is a manual step.

### 5. Delete the previous `.bin`

```bash
rm lib/data/boundaries_<old-tag>.bin
```

Nothing does this for you. Emit writes the new filename and leaves the old
file in place, so the package would publish both — about 4 MB of dead weight.
(Stale *chunk* files are cleaned automatically; the `.bin` is not.)

### 6. Fix what the suite flags

These are hand-maintained and will fail loudly. That is the design — each one
is a fact a human should confirm rather than a number a script should
overwrite.

| Where | What |
| --- | --- |
| `test/browser_parity_test.dart` | Literal version string and zone count |
| `test/bundled_data_test.dart` | Zone count, in several places |
| `test/runtime_test.dart` | Unsimplified container size budget |
| `README.md` | The literal `.bin` filename in Flutter asset instructions |
| `test/fixtures/overlap_pins.dart` | If a disputed-territory tiebreak moved — regenerate raw material with `dart run tool/probe_overlaps.dart` and update pins by hand |
| `test/fixtures/golden_points.dart` | If a border moved under a golden point |

A test scans `README.md` and fails if it still names a stale `.bin`. The
pubspec snippet has to be a literal because it is YAML with no constant to
reach for. `browser.dart` interpolates `boundariesBinName`.

Do **not** "fix" a golden by recording what the new data returned. The
bootstrap fixtures exist precisely to be independent of the data under test.

### 7. Finish

Bump `version:` in `pubspec.yaml` per the triage verdict from step 1, and add a
`CHANGELOG.md` entry naming the TZBB release.

### 8. Confirm reproducibility

```bash
dart run tool/refresh.dart --verify
```

With `defaultRelease` now pointing at the new tag this should report that
committed data reproduces the tag exactly, and must leave the tree untouched.
If it writes anything, something is wrong with the verify path, not with your
data.

Oracle-only GeoJSON (no regenerate):

```bash
dart run tool/fetch_data.dart --release <tag>
```

---

## New CLDR release

Metazone generation always fetches from `unicode-org/cldr-json` **main** (no
CLDR pin on the CLI). "Upgrading CLDR" is just running the generator again.
The version that came down is recorded in the generated `cldrVersion` constant.

**CLDR-only** (boundaries unchanged):

```bash
dart run tool/generate_metazone_data.dart
dart format lib/src/generated/metazone_data.dart
dart test test/zone_names_test.dart
```

It reads `tool/release/timezone-names.json` for the identifier set (committed
in every checkout). Output is `lib/src/generated/metazone_data.dart` only — typically
a **patch** bump.

Or fold CLDR into a full refresh against the **current** TZBB tag:

```bash
dart run tool/refresh.dart --release <current-tag>
```

### The build gate

The generator refuses to write if the set of identifiers with no current
English name drifts from `_knownNullMetazoneNameNow`:

| Message | Meaning | Fix |
| --- | --- | --- |
| `null timeZoneGenericName at now, not on allow-list` | CLDR dropped a name this package relied on | Confirm it is genuinely unnamed upstream, then add the id to the allow-list |
| `allow-listed ids now have a name (remove from allow-list)` | CLDR filled a gap | Remove the id from the allow-list |

Either way the run exits 1 and writes nothing.

---

## New IANA tzdb release

1. Wait for / bump **`package:timezone`** so `data/latest_all` includes the
   new rules (`pubspec.yaml` / lockfile as appropriate).
2. Keep documenting and testing against **`latest_all`**, never `latest`.
3. Run the suite (especially bridge / tzdata coverage that every boundary id
   resolves).
4. When TZBB publishes a matching boundary release, follow
   [New TZBB release](#new-tzbb-release).

No `tool/refresh.dart` step is required for tzdb alone.

---

## Related tools (not the release path)

| Command | Role |
| --- | --- |
| `dart run tool/generate_data.dart --release <tag> …` | Indexes only (no CLDR / full suite). Same `--release` / `--tolerance` / `--chunk-kb`, plus `--emit bundled\|unsimplified\|both`. |
| `dart run tool/fetch_data.dart --release <tag>` | Warm GeoJSON cache; oracle tests skip if missing |
| `dart run tool/differential.dart` | Heavy agreement gate vs oracle |
| `dart run tool/probe_overlaps.dart` | Overlap fixture research |
| `dart run tool/measure_pip_bound.dart` | dart2js `\|side\|` headroom against 2⁵³ — part of the release path, see [step 4](#4-check-the-dart2js-headroom) |
| `dart run tool/measure_grid.dart`, `measure_simplification.dart`, `measure_geometry.dart` | Grid / simplification / geometry experiments |

Unknown flags are rejected rather than falling through to defaults.
`--tolerance` (default `1000`, ≈110 m) is the one flag that changes what ships;
byte identity is claimed only for a given release *and* tolerance.
