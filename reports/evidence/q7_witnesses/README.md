# Q7 pinned SAT witnesses — `moore-strict` and `grand-strict`

**2026-09-25 (CX-93, Fable).** These are the two SAT-constructed witnesses that
[TR-12 §Q7](../../TR12_QUERY_PROGRAM.md) names — TR-1/TR-2's `moore-strict` and `grand-strict`
targets of [`sat.py`](../../../sat.py) — produced **once**, with the solver version, the exact
commands and the input/output hashes recorded here, and then **pinned**: each file carries one
`SEQ=` line of 64 hexagram values ([SPECIFICATION.md §H](../../../documentation/SPECIFICATION.md)),
C4 anchor `63,0` first.

**Why bytes are pinned.** A solver-chosen witness has no reproducibility contract of its own:
*which* member of the satisfying set a solver returns is build-dependent, so a golden of
solver-chosen bytes would pin one build's arbitrary choice (QUERY_INVENTORY row
`TR12_Q7_WITNESSES`, the reason the row was a named skip from 2026-09-05). The contract that *is*
reproducible is a **property** of a fixed sequence. So the battery row `a0_q7_witnesses`
([`scripts/tr12_repro.sh`](../../../scripts/tr12_repro.sh)) never runs a solver: it reads these
files and re-verifies each pinned sequence — `$SOLVE --check-arrangement` (the independent
first-principles C1..C5 checker: IN SUPER and IN C15), KW-distinctness (string comparison with the
battery's own `q7_kw.json`, and positions/pair-slot layout via `solve.py`), and a re-score of every
literature rule the target enforces through `solve.py`'s scorers (`sat.target_verdict`), with Schulz
gender also recounted by `verify.py`'s independent re-implementation. Its output is byte-identical
with and without `kissat` on PATH. The certificate it writes, `q7_<target>.json`, is what
`a2_q7_ranks` consumes at n = 31 for the witness's `rank_O3` — the "serial number" of §Q7, which is
a rank in the KW-derived O3 coordinate (D5-14), not a rarity statement.

The **live** re-solve — the inventory's own `python3 sat.py --witness <target>` — is battery row
`a0_q7_resolve`, opt-in via `--q7-resolve`. It asserts the whole-line `WITNESS_RESULT=WITNESS`
token and re-verifies whatever sequence comes back with the same solver-free checks; it **never**
asserts byte-equality with the files here. Gate: `scripts/d5_04_q7_witnesses_gate.sh`.

## Files

| file | sha256 | content |
|---|---|---|
| `moore-strict.txt` | `79fa29f5bdbfa1b4e0fb3bdc40399430b1a586a11aae0e914d2a32412389e788` | witness for `moore-strict` (C1&C2&C4&C5, C3 ≤ 776, Moore-2005 parity 18/18, Moore-1989 rhythm 0 breaks) |
| `grand-strict.txt` | `860c221d407ca58c5e0ed17fea02cf5f31e3441daf3cb1eebc7e08da246a9569` | witness for `grand-strict` (the above AND Schulz-1990 gender 0 violations) |

**Both files pin the same sequence.** Every production chain below — the CNF-plus-`kissat` chain
and the inventory's `--witness` loop, for each of the two targets — returned this one ordering on
this build, and a `grand-strict` witness is by definition also a `moore-strict` witness. It is
recorded as what the commands produced, not curated into two distinct objects.

```
SEQ=63,0,17,34,23,58,2,16,55,59,7,56,61,47,8,4,25,38,3,48,41,37,32,1,57,39,33,30,18,45,28,14,60,15,40,5,53,43,20,10,35,49,24,6,62,31,26,22,29,46,9,36,52,11,13,44,54,27,50,19,51,12,21,42
```

Relation to King Wen (`solve._r7_kw()`): 6 of 64 positions differ, in two local edits — pair 7
`4,8` reversed to `8,4`, and pairs 21/22 `31,62 | 24,6` replaced by `24,6 | 62,31` (order swapped,
one reversed). So the pair-slot layout differs from KW's (it is not an orientation variant), C3 stays
at 776, and the step-distance histogram stays KW's. Re-scored on the five literature rules
(`sat.rule_scores`): parity 0, rhythm 0, gender 0, ccn4 1, ccn8 1 (KW: 2, 2, 2, 0, 0). CC-N4 and
CC-N8 are not enforced by either target; the four-rule and five-rule unions are UNSAT
(`grand-ccn4`, `grander-strict`; [SAT_CLI.md](../../../documentation/SAT_CLI.md)).

## Provenance — how each witness was produced (once)

Host: an 8-core x86-64 Ubuntu 24.04 worker (gcc 13.3.0, Python 3.12.3); repository at public
`5c296837` with the 2026-09-25 batch overlaid, `sat.py` sha256
`7d37ecc73286c1036ba18107b962eed3221546e9ab5c040be18af7a256a63be1`, `solve.py`
`7442d328555ca640fa7daebd8b9b1663737f294767b663e89aae8096c8888cc0`. Solver: **kissat 4.0.4**
(`kissat --version` → `4.0.4`; binary sha256
`7f4080c46bcdbc06df0dc332fcf813a15c988eec66b7175a7148bd7b95f85891`, built from source).

Chain B — emit the CNF with C3 ≤ 776 encoded natively, solve, decode and re-verify solver-free:

```
python3 sat.py --emit-cnf moore-strict --with-c3 moore-strict.cnf     # vars=36858 clauses=328276
kissat -q moore-strict.cnf > moore-strict.model                        # exit 10, s SATISFIABLE, 0.03 s
python3 sat.py --decode moore-strict.model moore-strict --with-c3      # DECODE_VERDICT=PASS, 1.0 s

python3 sat.py --emit-cnf grand-strict --with-c3 grand-strict.cnf     # vars=37011 clauses=331389
kissat -q grand-strict.cnf > grand-strict.model                        # exit 10, s SATISFIABLE, 0.03 s
python3 sat.py --decode grand-strict.model grand-strict --with-c3      # DECODE_VERDICT=PASS, 1.0 s
```

| artifact | sha256 |
|---|---|
| `moore-strict.cnf` | `12e56f1ba4df7b2a22aabf6dc6a611e858b8b8f36ad2266fc761230e47750f9c` |
| `moore-strict.model` (kissat `s`/`v` lines, 230,087 bytes) | `98aa87f293d078d080796fdbd22c4b7947ebe8a66c8f28f76a06e5e3f507bc99` |
| `grand-strict.cnf` | `12ec22b92ef0361a9fe0816e8e74a52c17acff38b80f7bbee830c80d53967547` |
| `grand-strict.model` (kissat `s`/`v` lines, 231,151 bytes) | `b8e17e464a76f2b35945800cdeb8b575bf6fb1e2238d66d4934e7411683e0c4b` |

Both `--decode` runs printed `verify=True  c3=776  c3<=776 PASS` and
`rule re-score (solve.py): parity-viol=0 rhythm-viol=0 gender-viol=0 ccn4-viol=1 ccn8-viol=1`.
The CNFs regenerate from `sat.py` at the sha above; the model files are not committed (they are
solver output, 0.46 MB of literals, reproducible in 0.03 s with any kissat) — their hashes are the
record.

Chain A — the inventory's own command (QUERY_INVENTORY row Q7), run for the record:

```
python3 sat.py --witness moore-strict    # attempt 0: verify=True ... c3=776 c3<=776 PASS; WITNESS_RESULT=WITNESS; 1.0 s
python3 sat.py --witness grand-strict    # attempt 0: verify=True ... c3=776 c3<=776 PASS; WITNESS_RESULT=WITNESS; 1.0 s
```

Both returned the pinned sequence at attempt 0. **That agreement is an observation about this
build, not a contract** — a different kissat version, seed or CNF ordering may return another
member of the satisfying set, and the battery's re-solve row is written so that this does not
matter.

## Verify without a solver

```
./solve --check-arrangement "$(sed -n 's/^SEQ=//p' reports/evidence/q7_witnesses/moore-strict.txt)"
#   verdict SUPER (C1&C2&C4&C5): IN ; verdict C15 (C1-C5, C3<=776): IN ; C3 value 776
python3 -c 'import sat; s=[int(x) for x in open("reports/evidence/q7_witnesses/grand-strict.txt").read().split("SEQ=")[-1].split(",")]; print(sat.target_verdict(s,"grand-strict")["ok"], sat.rule_scores(s), s==sat.KW)'
#   True {'parity': 0, 'rhythm': 0, 'gender': 0, 'ccn4': 1, 'ccn8': 1} False
```

Or run the battery: `scripts/tr12_repro.sh --n9 --out /tmp/tr12 --solve ./solve` and read
`TR12_Q7_WITNESSES=PASS` with the row's raw output in `/tmp/tr12/raw/a0_q7_witnesses.txt`.

## What the battery row asserts (CX-321, 2026-10-09)

`a0_q7_witnesses` verifies more than membership. In addition to CX-93's checks it asserts, of each pinned
sequence, the claims the reports make of it — by name, in the diffed output, with no solver:

| claim | source of the claim | asserted from |
|---|---|---|
| the rule set the target enforces (`moore-strict`: parity, rhythm; `grand-strict`: + gender) | TR-12 §Q7, SAT_CLI.md | written in the row; `sat.target_rules` must agree |
| **C3 = 776** (an equality, not `<= 776`) | TR-12 §Q7; LRPT result 6 | `--check-arrangement`'s `value` line AND `sat.target_verdict`, separately |
| exactly 3 slot-edits from King Wen: slot 7 flipped; pairs 21/22 swapped, slot 22 flipped; 6 positions differ | LRPT result 7; TR-12 §Q7 | computed against `solve._r7_kw()` |
| parity, rhythm, gender re-tallied in C | — | `solve.c --r11-verify` fields 1..3 (parsed, never its exit status) must equal `solve.py --r11-verify` and read 0 on every enforced rule |
| the instrument is alive | — | King Wen must violate the target's rules; King Wen with slot 1 flipped must be OUT; a passing control fails the row |

Whole-line tokens: `Q7WIT_CONTRACT	HOLDS	...` on a green run, `pins_identical	YES` (the two files carry one
sequence). Gate: `scripts/d5_04_q7_witnesses_gate.sh` legs 12–18 (each red on a fixture whose precondition
is asserted first; the C3 = 776 check is proven live by moving the claim constant, because no member of
either target with C3 ≠ 776 is known without a solver) and `tests.py::TestQ431WitnessPropertyContract`.

**Q-796, decided (operator 2026-09-30, D11): `Q7_DISTINCT_WITNESSES=NO`.** The two targets share one
pinned sequence, recorded as the commands produced it. A distinct moore-strict member can be written down
by hand (this witness with slots 8 and 14 flipped: parity 0, rhythm 0, gender 2, C3 = 776), so the point
is editorial, not mathematical: TR-12 names two targets and one sequence, and the row prints
`pins_identical` so that a future re-pin yielding two would be a documented change.

## The witness's `rank_O3` (added 2026-11-13, CX-37C-L, Q-1065)

TR-12 §Q7 promised the witness a serial number — its walk rank in the O3 order — and CX-93 recorded that
none had been computed. It has now been computed twice, by two routes that share no counting code:

| | route | rank3 | class_first_rank3 | orient_idx | class size m | King Wen |
|---|---|--:|--:|--:|--:|--:|
| 2026-09-25 | `solve --kc-o3-rank FDIR GDIR WALK` on the n = 31 f and g ladders, through the battery's own `a0_q7_kw`, `a0_q7_witnesses` and `a2_q7_ranks` rows | 1,969,309,902,352 | 1,969,309,884,416 | 17,936 | 2,064,384 | rank 0, m = 1,720,320 |
| 2026-11-13 | `python3 reports/evidence/q7_witnesses/q7_witness_rank_ladderfree.py` — no ladder; a memoised count over (unused pairs, last hexagram, remaining C5 budget) | 1,969,309,902,352 | 1,969,309,884,416 | 17,936 | 2,064,384 | rank 0, m = 1,720,320 |

```
python3 reports/evidence/q7_witnesses/q7_witness_rank_ladderfree.py --check-g reports/evidence/tr12/atlas_followups_n31_20260925/q8
#   Q7LF_KW_RANK3=0
#   Q7LF_G_EQUALS_LADDER_G=143/143
#   Q7LF_RANK3:moore-strict=1969309902352
#   Q7LF_CLASS_FIRST_RANK3:moore-strict=1969309884416
#   Q7LF_ORIENT_IDX:moore-strict=17936
#   Q7LF_CLASS_M:moore-strict=2064384
#   Q7LF_PAIR_BLOCKS:moore-strict=slot21:pair21:1969309884416
#   ... the same five lines for grand-strict (the two files pin one sequence) ...
#   Q7LF_VERDICT=PASS
python3 reports/evidence/q7_witnesses/q7_witness_rank_ladderfree.py --selftest       # Q7LF_SELFTEST=PASS members_checked=1072
```

**What each route rests on.** The 2026-09-25 run read completion counts from the ladders. It did **not**
record its `solve.c` commit (its tables print `git=unknown`), and it has not been repeated: the n = 31
ladders are not distributed with this repository. The script reads the King Wen sequence from `solve.py`
and the two pinned files, and nothing else from the repository; the constraints are written out in it
from `documentation/SPECIFICATION.md` and the order from the comment above `kc_o3_rank` in `solve.c`.
Its self-test enumerates every member of three small universes (1,072 orderings), sorts them by the O3
key and requires each rank to equal its index. `--check-g` also requires its completion counts to equal
the ladder's `g` at every step from 19 on in the eleven committed `--kc-profile` tables (143 of 143).

**What the number counts.** The witness keeps King Wen's pair order through slot 20 and places pair 22
at slot 21, where King Wen has pair 21. Every ordering that precedes it in O3 either has pair 21 at slot
21 after King Wen's first 21 pairs — 1,969,309,884,416 orderings, counting every valid orientation and
every valid order of the last ten pairs — or has the witness's own pair order and a smaller orientation
vector (17,936).

**What it is not.** It is a coordinate in an order built from King Wen's own pair table, in which King
Wen is rank 0 by construction (TR-12 §Q7, D5-14). It is not a rarity statement, and it is not small or
large in any sense that does not depend on that table. The space is C1∩C2∩C4∩C5, with C3 not applied.
It is a walk rank; the class rank (the number of distinct records preceding) is not computed. The
script is fast only because the witness leaves King Wen's pair order late: it refuses, by name, an
arrangement that would need a count over more than 12 unplaced pairs (`--max-free`), and it is not a
replacement for `--kc-o3-rank`.

*(Note 2026-11-15, Q-1133: witnesses for the rule pairs {parity, CC-N8} and {rhythm, CC-N8} are in [../core_pair_witnesses/](../core_pair_witnesses/README.md). They are separate from the two Q7 targets and are not read by the battery row described here.)*
