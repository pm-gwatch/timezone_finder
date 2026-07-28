# Test fixtures

Three files, with three different contracts. The distinction matters more than
it looks:

| File | Contract | On failure |
| --- | --- | --- |
| `bootstrap_goldens.dart` | External ground truth, independent of tzbb. Validates the oracle. | Oracle or fixture is wrong |
| `golden_points.dart` | External ground truth, harder cases. | Oracle or fixture is wrong |
| `overlap_pins.dart` | **Not ground truth.** Pins the §6.5 tiebreak where two zones genuinely contain a point. | The tiebreak changed — investigate, do not refresh |

---

## `golden_points.dart` — milestone 3

196 fixtures extending the bootstrap set into borders, enclaves, islands,
Antarctic stations, the antimeridian, and open ocean. Combined with the
bootstrap set: **262 fixtures across 236 distinct zones**.

| Category | Count |
| --- | --- |
| city | 182 |
| island | 30 |
| border | 19 |
| antarctic | 9 |
| enclave | 8 |
| ocean | 8 |
| antimeridian | 6 |

### Verification log — 2026-07-28

Same discipline as the bootstrap set: written by hand first, verified after.

| Check | Method | Result |
| --- | --- | --- |
| Identifier exists | tzbb `2026c` `timezone-names.json` | **all present** |
| Coordinate → zone | `timezonefinder` 8.2.5 (authoritative) | **262/262** |
| Coordinate → zone | `tzf` via `tzfpy` 1.3.2 (advisory) | **254/254** of the non-null fixtures |

**Verification weighting is inverted from the bootstrap set.** There, both
tools were equal peers because every point was deep inland. Here, border
fixtures sit within metres of a zone boundary, and `tzf` simplifies its
polygons to ~110 m — so a `tzf` disagreement near a border is an expected
artifact of its preprocessing, not a finding. `timezonefinder`, which keeps
full-precision coordinates, is authoritative for those. Ocean fixtures have
only one possible verifier at all: `tzf` ships the with-oceans variant and
answers `Etc/GMT±N` where a land-only dataset must answer nothing.

### Disagreements found and resolved

The first pass produced three. All were resolved from a third source, none by
adopting a tool's answer.

1. **Hanoi — I was wrong.** I expected `Asia/Ho_Chi_Minh`; both tools said
   `Asia/Bangkok`. IANA's own `zone1970.tab` settles it:
   `Asia/Bangkok — north Vietnam`, `Asia/Ho_Chi_Minh — south Vietnam`.
   Northern Vietnam has agreed with Bangkok since 1970, so tzdb gives it no
   separate zone. Kept as a fixture with a note, and Ho Chi Minh City added as
   its southern counterpart — the pair is worth more than either alone.
2. **Palikir — authoring slip.** Expected `Pacific/Kosrae` while the note
   itself said Pohnpei. Corrected to `Pacific/Pohnpei`.
3. **Ürümqi — mis-filed, not wrong.** The two tools disagreed with each other:
   `timezonefinder` said `Asia/Urumqi`, `tzf` said `Asia/Shanghai`. Neither is
   wrong — the point lies inside the documented `Asia/Shanghai`–`Asia/Urumqi`
   overlap, and each implementation applies its own tiebreak. It is not
   ground truth at all, and moved to `overlap_pins.dart`.

That third case is the reason the files are split, and it is worth
generalising: **two independent implementations disagreeing with each other,
rather than both disagreeing with you, is the signature of a fixture that has
no external answer.** A sweep of all 262 fixtures against the oracle confirmed
Ürümqi was the only one affected; `dart run tool/probe_overlaps.dart
--check-fixtures` re-runs that sweep, and a test enforces it permanently.

---

## `overlap_pins.dart` — milestone 3

21 of the 25 documented overlap pairs, pinned. Read the file header before
touching it: these record what an arbitrary tiebreak returns in mostly
disputed territories, and are not claims about sovereignty.

The other four pairs (`Asia/Ho_Chi_Minh`–`Asia/Manila`,
`Asia/Ho_Chi_Minh`–`Asia/Shanghai`, `Asia/Kolkata`–`Asia/Shanghai`,
`Asia/Manila`–`Asia/Shanghai`) do not overlap anywhere in the 2026c land-only
geometry at sampling densities up to 200×200. They cannot be pinned because
the situation does not arise. See plan §9.4 — grid sampling cannot prove
absence, so this is "not found", not "does not exist".

---

## `bootstrap_goldens.dart` — milestone 1

66 coordinate → IANA identifier pairs. This is the only ground truth in the
package that does not derive from timezone-boundary-builder data.

### Why it exists

The Phase A reference oracle (milestone 2) is the authority for everything
else: the wider golden set, and the differential testing that validates the
real index. But the oracle cannot be validated against fixtures derived from
itself. This file breaks that circle. Once the oracle passes this set, the
oracle — not this file — becomes the authority.

### How it was produced

1. **Authored by hand first.** All 66 pairs were written from independent
   knowledge of world geography before any tool was run. Nothing was generated
   from tzbb data, from this package, or from another implementation. The
   ordering matters: had candidates been generated and their zones filled in
   from a tool, the independence this file exists to provide would be gone and
   no later test could recover it.
2. **Verified afterwards**, as two independent passes (below).

### Verification log — 2026-07-28

| Check | Method | Result |
| --- | --- | --- |
| Identifier exists | Membership in the 419 entries of tzbb `2026c` `timezone-names.json` | **66/66 present** |
| Coordinate → zone (1) | Python `timezonefinder` 8.2.5, `timezone_at_land()` | **66/66 agree, 0 disagreements** |
| Coordinate → zone (2) | `tzf` via `tzfpy` 1.3.2, `get_tz()` | **66/66 agree, 0 disagreements** |
| Duplicate coordinates | Exact match on (lat, lon) | none |
| Harness discriminates | Negative control, both tools | passed |

Two independent implementations were used, as §10.1 requires. They share the
same upstream boundaries but have entirely separate preprocessing pipelines and
lookup code — `timezonefinder` keeps full-precision coordinates, `tzf` uses
simplified topology-encoded polygons — so agreement across both is meaningful
insurance against a quirk in either one.

Note that `tzf` ships the *with-oceans* dataset and returns `Etc/GMT±N` at sea
rather than nothing. Irrelevant here, since every point in this set is well
inland, but it is why `tzf` cannot be used to check land-only null behaviour.

The identifier check consults no geometry at all — it only confirms each zone
name exists in the release, catching typos and renames (such as
`Europe/Kiev` → `Europe/Kyiv`) cheaply.

`timezone_at_land()` is used rather than `timezone_at()` because it matches
this package's land-only semantics: it returns `None` at sea instead of a
synthetic `Etc/GMT±N` zone.

#### Negative control

Zero disagreements is the result a broken comparison also produces, so both
harnesses were checked against deliberately wrong expectations.

For `timezonefinder`, all four were caught: Paris claimed as `Europe/Berlin`,
Beijing claimed as the nonexistent `Asia/Beijing`, Phoenix claimed as
`America/Denver`, and a lat/lon swap (which raised a range error). For `tzf`,
both were caught: Paris claimed as `Europe/Berlin` and Sydney as
`Australia/Perth`. Both comparisons discriminate.

`tzfpy.get_tz()` takes **(longitude, latitude)** — the opposite order to
`timezonefinder`. Getting that backwards silently produces garbage rather than
an error for many coordinates, which is precisely why the negative control was
run per-tool rather than once.

#### Reproducing the cross-check

Both tools are Python packages and deliberately not dependencies of this
repository. To re-run the check:

```bash
python3 -m venv /tmp/tzcheck && /tmp/tzcheck/bin/pip install timezonefinder tzfpy
```

```bash
curl -sLO https://github.com/evansiroky/timezone-boundary-builder/releases/download/2026c/timezone-names.json
```

```python
import re, json
import tzfpy
from timezonefinder import TimezoneFinder

src = open('test/fixtures/bootstrap_goldens.dart').read()
body = src.split('bootstrapGoldens = <GoldenPoint>[', 1)[1]
pat = re.compile(r"GoldenPoint\(\s*'((?:[^']|\\')*)'\s*,\s*(-?[\d.]+)\s*,\s*(-?[\d.]+)\s*,\s*'([^']+)'")
pairs = [(m[1], float(m[2]), float(m[3]), m[4]) for m in pat.finditer(body)]

names = set(json.load(open('timezone-names.json')))
assert not [z for _, _, _, z in pairs if z not in names]

tf = TimezoneFinder()
for n, lat, lon, z in pairs:
    a = tzfpy.get_tz(lon, lat)                    # (lng, lat) order!
    b = tf.timezone_at_land(lat=lat, lng=lon)
    if a != z or b != z:
        print(f'DISAGREE {n}: expected {z}, tzf {a}, timezonefinder {b}')
```

### Scope — what is deliberately absent

This set is chosen to be **beyond doubt, not interesting**. Major city centres,
well inside a country, away from zone borders.

The hard cases belong in the milestone 3 golden set and are intentionally not
here, because a bootstrap set that argues with itself is useless:

- near-border pairs (Basel/Saint-Louis, the China/Nepal border, Arizona/Navajo)
- the 5 antimeridian-split zones
- all 25 documented overlap pairs
- enclaves and hole cases (Lesotho, Vatican City)
- small-island and Antarctic zones

### Coverage

All inhabited continents: 66 points across **66 distinct zones** — no zone is
sampled twice — spanning the `Africa`, `America`, `Asia`, `Australia`, `Europe`
and `Pacific` areas. Deliberate inclusions worth keeping:

- **Three-segment identifier** — `America/Argentina/Buenos_Aires`, which
  exercises parsing that must not assume exactly one slash.
- **Counterintuitive-but-correct pairs** — Beijing → `Asia/Shanghai`, Delhi →
  `Asia/Kolkata`. Both carry a note so a reviewer does not "fix" them.
- **Same-country multi-zone sampling** — four Russian cities (Moscow plus three
  east of the Urals), five Australian and seven US, each in a distinct zone, to
  catch an index that collapses a large country to a single answer.
  `America/Phoenix` is included specifically because Arizona is a within-state
  exception rather than a border case.

### Rule for adding pairs

Do not add a pair by running an implementation and recording what it said. Write
the expectation first, then verify. Anything else quietly converts this file
from ground truth into a snapshot of a possibly-wrong implementation.
