#!/usr/bin/env bash
# R12b #8 (Q-286) — `solve.py --tr8-dof-merge` must refuse an undeclared extra shard
# and a bank.json that has changed since the shards were drawn.
#
# (a) The pool was checked for expected-MINUS-seen and never seen-MINUS-expected, so an
#     extra shard id outside the header's range merged silently. R12b's deterministic
#     fixture is an extra shard carrying zero draws and zero hits: it changes no
#     statistic, it is not "missing", and it passed. A stale NONZERO extra would have
#     merged too, and only a coincidental H-b failure would have caught it.
# (b) The header carries admitted_bank_sha256 and the merge never recomputed it, so a
#     template or marginal could be edited in place and the merge still exit 0. A digest
#     written and never checked is decoration.
#
# THREE-WAY, because a gate that refuses everything would "catch" both defects:
#   control        -> merge proceeds past both checks
#   extra shard    -> refused, naming the undeclared id
#   mutated bank   -> refused, quoting declared vs recomputed
# Verdict: TR8_MERGE_POOL_INTEGRITY=PASS|FAIL
set -uo pipefail
cd "$(dirname "$0")/.."
python3 - <<'PY'
import json, os, sys, tempfile, hashlib, subprocess

def digest(bank, marg, admitted):
    return hashlib.sha256("\n".join(
        "%s%d|%s|%s|%.6f" % (bank[i][0], bank[i][1], bank[i][2], bank[i][3], marg[i])
        for i in admitted).encode("utf-8")).hexdigest()

BANK = [("fam", 0, "le", "tmpl")]
MARG = [0.25]
ADMIT = [0]

def build(dirpath, extra_shard=False, mutate_bank=False):
    # n_pool is required by _tr8_results_md (h["n_pool"] // h["n_shards"]). Omitting it made
    # the CONTROL crash with KeyError -- and the control only looked for refusal strings, so a
    # traceback read as "passed". A control that cannot fail is the defect this gate exists to
    # catch, so it now demands rc == 0 as well.
    # Every key the finish path reads, collected from h["..."] in _tr8_finish /
    # _tr8_results_md rather than discovered one KeyError at a time.
    hdr = {"n_shards": 1, "n_pool": 10, "k_ladder": [4], "n_pred": 1, "pool": "p",
           "seed_root": "r", "calibration_draws": 10, "admission_band": [0.0, 1.0],
           "b_raw": 1, "b_admitted": 1, "r_kw": 0.25, "seeds": {},
           "admitted_bank_sha256": digest(BANK, MARG, ADMIT)}
    def shard(i):
        return {"header": hdr, "shard": i, "hits": {"4": [0]}, "hb_hits": 0, "draws": 10}
    json.dump(shard(0), open(os.path.join(dirpath, "shard_000.json"), "w"))
    if extra_shard:                      # id outside the declared 0..0 range
        json.dump(shard(5), open(os.path.join(dirpath, "shard_005.json"), "w"))
    marg = [0.99] if mutate_bank else MARG      # shape preserved, value changed
    json.dump({"bank": [{"family": BANK[0][0], "index": BANK[0][1],
                         "comparator": BANK[0][2], "template": BANK[0][3],
                         "marginal": marg[0], "admitted": True}]},
              open(os.path.join(dirpath, "bank.json"), "w"))

def run(**kw):
    d = tempfile.mkdtemp()
    build(d, **kw)
    p = subprocess.run([sys.executable, "solve.py", "--tr8-dof-merge", d],
                       capture_output=True, text=True, timeout=180)
    return p.returncode, (p.stdout + p.stderr)

fails = 0
rc, out = run()
if rc != 0:
    print(f"   [FAIL] control pool did not MERGE CLEANLY (rc={rc}) -- a control that only checks")
    print(f"          for absent refusal strings passes on a traceback: {out.strip()[-90:]}")
    fails += 1
elif "outside this run's declared range" in out or "does not match the run header" in out:
    print(f"   [FAIL] control pool was refused -- the gate refuses everything")
    fails += 1
else:
    print("   [ok]   control: a consistent pool merges cleanly (rc=0), neither check fires")

rc, out = run(extra_shard=True)
if "outside this run's declared range" in out:
    print("   [ok]   extra undeclared shard refused, and the id is named")
else:
    print(f"   [FAIL] extra shard id 5 NOT refused (rc={rc}): {out.strip()[:110]}")
    fails += 1

rc, out = run(mutate_bank=True)
if "does not match the run header" in out:
    print("   [ok]   mutated bank.json refused, declared vs recomputed quoted")
else:
    print(f"   [FAIL] mutated bank.json NOT refused (rc={rc}): {out.strip()[:110]}")
    fails += 1

print("TR8_MERGE_POOL_INTEGRITY=" + ("FAIL" if fails else "PASS"))
sys.exit(1 if fails else 0)
PY
