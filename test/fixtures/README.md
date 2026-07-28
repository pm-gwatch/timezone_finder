# Test fixtures

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
