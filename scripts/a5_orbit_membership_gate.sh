#!/usr/bin/env bash
# Q-421 / Codex MQ1 §2b — the SECOND half of the A-5 orbit-column check.
#
# WHAT WAS WEAK. solve.py's atlas_orbit_columns() compares the MULTISET of
# equal-column group sizes against the published (3,3,3,4,6,6,6). It never asks
# WHICH pairs are in which group, so swapping two pairs drawn from two DIFFERENT
# orbits of the SAME size leaves its output byte-identical and the check passes
# on a field that is wrong. The docstring and viz/viz_kc_field.md state that
# limit honestly; this gate closes it.
#
# WHERE THE PARTITION COMES FROM. solve.py::pair_orbit_partition() derives it
# from that module's own group machinery -- the centralizer of bit-reversal in
# S6 acting on king_wen_pairs() -- and NOT from solve.c's printed
# "[f1] pair-orbits ..." line. Hardcoding that line would be verifier closure:
# the checker handed its witness by the thing it checks (Codex N07). The two
# derivations agree exactly, membership included, which is the cross-check.
#
# Verdict: A5_ORBIT_MEMBERSHIP=OK|FAIL
#   $1 (optional) a real atlas.json to check in addition to the selftest.
set -uo pipefail
cd "$(dirname "$0")/.."
ATLAS=${1:-}
ATLAS="$ATLAS" python3 - <<'PY'
import os, sys, json, importlib.util
spec = importlib.util.spec_from_file_location("sv", "solve.py")
sv = importlib.util.module_from_spec(spec); sys.modules["sv"] = sv
try:
    spec.loader.exec_module(sv)
except SystemExit:
    pass

fails = 0
part = sv.pair_orbit_partition()
sizes = sorted(len(o) for o in part)
if sizes != [3, 3, 3, 4, 6, 6, 6]:
    print(f"   [FAIL] derived orbit sizes {sizes}, expected [3,3,3,4,6,6,6]"); fails += 1
if sum(sizes) != 31:
    print(f"   [FAIL] orbits cover {sum(sizes)} pairs, expected 31"); fails += 1

# CONVENTION ANCHOR. The derivation must land in the KING WEN pair-index
# convention; done in build_pairs() order it yields the SAME SEVEN SIZES with
# DIFFERENT MEMBERS, and every check below would then be self-consistently wrong
# -- the synthetic field is built from the same partition it is tested against,
# so a relabelling cancels out and passes. Measured: that mutant SURVIVED until
# this leg existed. Anchor on the PUBLISHED membership in viz/viz_kc_field.md,
# which is a third party -- neither this checker nor solve.c's runtime output.
import re as _re
_pub_src = "viz/viz_kc_field.md"
try:
    _txt = open(_pub_src, encoding="utf-8").read()
except OSError as e:
    print(f"   [FAIL] cannot read {_pub_src}: {e}"); fails += 1; _txt = ""
_m = _re.search(r'pair-orbits of the 31 free pairs:((?:\s*\d+:\[[0-9,]+\])+)', _txt)
if not _m:
    print(f"   [FAIL] {_pub_src} no longer publishes the pair-orbit line -- "
          "this leg measured NOTHING"); fails += 1
else:
    _pub = sorted((tuple(int(x) for x in g.split(","))
                   for g in _re.findall(r'\d+:\[([0-9,]+)\]', _m.group(1))),
                  key=lambda v: (len(v), v))
    if _pub != part:
        print(f"   [FAIL] derived partition disagrees with {_pub_src}")
        print(f"          derived:   {part}")
        print(f"          published: {_pub}")
        fails += 1
    else:
        print(f"   [ok]   derived partition == the membership published in {_pub_src}")

def atlas_from(assign):
    """Two layers whose marginal_raw is constant within each assigned group."""
    return {"layers": [{"marginal_raw": {p: v * 10 for p, v in assign.items()}},
                       {"marginal_raw": {p: v * 7 + 1 for p, v in assign.items()}}]}

# GREEN: colour every pair by its true orbit.
true_assign = {}
for oi, members in enumerate(part):
    for m in members:
        true_assign["pair%d" % m] = oi
ok, detail = sv.atlas_orbit_membership(atlas_from(true_assign))
if ok is True:
    print(f"   [ok]   faithful field accepted: {detail}")
else:
    print(f"   [FAIL] faithful field REJECTED: {detail}"); fails += 1

# RED: swap two pairs drawn from two DIFFERENT orbits of the SAME size. This is
# the exact mutation the multiset check cannot see -- sizes are unchanged.
size3 = [o for o in part if len(o) == 3]
a, b = size3[0][0], size3[1][0]
swapped = dict(true_assign)
swapped["pair%d" % a], swapped["pair%d" % b] = swapped["pair%d" % b], swapped["pair%d" % a]
ok2, detail2 = sv.atlas_orbit_membership(atlas_from(swapped))
if ok2 is False:
    print(f"   [ok]   same-size cross-orbit swap (pair{a}<->pair{b}) REJECTED: {detail2[:72]}")
else:
    print(f"   [FAIL] same-size cross-orbit swap NOT caught -- the gate cannot fail"); fails += 1

# and confirm the OLD check really is blind to it, so the gate's reason for
# existing is demonstrated rather than asserted
n1, s1, _, _ = sv.atlas_orbit_columns(atlas_from(true_assign))
n2, s2, _, _ = sv.atlas_orbit_columns(atlas_from(swapped))
if (n1, s1) == (n2, s2):
    print(f"   [ok]   atlas_orbit_columns is blind to it (both {n1} cols, sizes {s1})")
else:
    print(f"   [note] atlas_orbit_columns distinguished them ({s1} vs {s2}) -- unexpected")

real = os.environ.get("ATLAS", "")
if real:
    if not os.path.exists(real):
        print(f"   [FAIL] atlas {real} not found"); fails += 1
    else:
        okr, dr = sv.atlas_orbit_membership(json.load(open(real, encoding="utf-8")))
        if okr is False:
            print(f"   [FAIL] {real}: {dr}"); fails += 1
        else:
            print(f"   [ok]   {real}: {dr}")

print("A5_ORBIT_MEMBERSHIP=" + ("FAIL" if fails else "OK"))
sys.exit(1 if fails else 0)
PY
