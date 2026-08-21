# F1 phase-3 counting formulation — exact reconstruction (2026-07-04)

> **Reproduce:** `python3 f1_phase1.py`, then `f1_phase2.py`, then `f1_phase3.py`, from this
> directory and in that order. The scripts were already named above; the invocation was not.

Source scripts (read verbatim): [`f1_phase1.py`](f1_phase1.py), `f1_phase2.py`, `f1_phase3.py`.
Reconstruction + validation by Claude (Fable 5) for the operator's F1 symmetry re-attack
(`F1_ORBIT_QUOTIENT_2026_07.md`). Numbers below are computed, not recalled; validation run logged in §5.
Constraint names C1–C5 as defined in the repository-root `README.md` / `documentation/SPECIFICATION.md`.

---

## 1. The exact recursion phase 3 implements

`f1_phase3.py::count(pair_indices, start_exit=0)` is a **pair-level bitmask DP with memoization**
(`lru_cache` over `rec(mask, last)`), NOT a lumped/class DP. The lumped route was already dead by
phase 2 (0/12 exchangeability swaps); phase 3's `count` is the *exact* ground-truth recursion, used
there as the instrument for the exchangeability test.

**Objects.** `PAIRS[p] = (KW[2p], KW[2p+1])` for p = 0..31, hexagrams as 6-bit ints
(`solve.binary_hexagrams`; Qian = 63, Kun = 0). A pair placed with orientation `o ∈ {0,1}` presents
`entry f = PAIRS[p][o]`-reversed convention — precisely: `o=0 → (f,s) = (KW[2p], KW[2p+1])` (received
order), `o=1 → (f,s) = (KW[2p+1], KW[2p])` (flipped). `f` is the entry hexagram, `s` the exit hexagram.

**State.** `(mask, last)` where `mask` is the exact subset of `pair_indices` already placed
(membership bitmask over the n listed pairs) and `last` is the exit hexagram value of the most
recently placed pair (or `start_exit` when `mask = 0`).

**Transition.** For each unplaced pair `p` and each orientation `o`: admissible iff
`popcount(last XOR f) != 5`; new state `(mask | bit(p), s)`, weight 1.

**Base case.** `mask` full → return 1. So `count` returns the **number of complete orderings**
(sequencings-with-orientations) of the listed pairs appended after a virtual predecessor exiting at
`start_exit`.

**Where each constraint lives:**

| Constraint | Enforced? | Where |
|---|---|---|
| C1 (32 reverse/complement pairs, consecutive) | yes, structurally | the DP places whole pairs; within-pair order is the orientation bit |
| C2 (no adjacent d = 5) | yes | the single transition test `d(last, f) != 5` at every pair boundary. Within-pair distances are fixed by C1 at d ∈ {2,4,6} (12/12/8 over the 32 pairs), never 5 — so boundary-only checking enforces **full** C2 |
| C4 (starts Qian, Kun) | yes | via `start_exit=0` and pair-0 exclusion — see §3 |
| C3 (complement positional-distance ceiling) | **NO** | absent from all three scripts |
| C5 (transition-size multiset = KW's) | **NO** | absent — no budget vector in the state (see §4) |

So the full-size instance `count(range(1,32), 0)` computes exactly **|C1 ∩ C2 ∩ C4|** (pair-level,
orientation-explicit), not |C1–C5|. The FOOTHOLDS ledger prices C5 as a state multiplier on top of
this route; that is consistent with the code.

## 2. Honest operation and memory count (full size: 31 free pairs)

`last` ranges over the 62 non-{Qian,Kun} hexagrams (each free hexagram is the exit of its pair in
exactly one orientation) and must be an exit of a pair *in* `mask`: a mask with k pairs admits 2k
`last` values (+1 start state at mask = 0).

**States (memo entries):**
Σₖ C(31,k)·2k + 1 = 2·31·2³⁰ + 1 = **31·2³¹ + 1 = 66,571,993,089 ≈ 6.66×10¹⁰**.

**Ops (edge evaluations, each = one popcount test + one add on pass):**
Σₖ C(31,k)·2k·2(31−k) + 62 = 4·31·30·2²⁹ + 62 = **1,997,159,792,702 ≈ 2.0×10¹²**.
The naive bound 2³¹ masks × 62 lasts × 62 moves = 8.25×10¹² is 4× looser; the ledger's "~5×10¹²"
sits between the two (and in FOOTHOLDS it is actually quoted for the inclusion-exclusion-over-orbits
variant, ~4.5×10⁷ orbit terms × a 62-state DP — the raw-DP tight count is the 2.0×10¹² above).

**Memory.** Result magnitude: |C1C2C4| ≈ 31!·2³¹·(≈0.90)³¹ ≈ 10⁴²⁽ᵉˢᵗ⁾ > 2¹²⁸ → values need ~150
bits (24 B, or 3 × 64-bit CRT residues at 8 B/pass).
- Full memo (as coded, Python `lru_cache`): 6.66×10¹⁰ entries ≈ **≥1.1 TB values alone** (16 B),
  ~6+ TB with dict overhead — hopeless.
- Best exact variant (layer-by-popcount, dense combinatorial ranking, two live layers): peak at
  k = 15,16: C(31,15)·30 + C(31,16)·32 = 1.86×10¹⁰ entries → **447 GB @24 B** single pass, or
  **149 GB @8 B × 3 CRT passes** (ops then ×3 ≈ 6×10¹²).

**Binding constraint: memory.** The 2.0×10¹² ops are ~0.5–2 h in tight C on a D32 (they were only
"infeasible" in Python at ~µs/edge ≈ weeks); but 149 GB/pass minimum RAM (or an out-of-core
streaming design) is what actually killed the route on available SKUs — and C5 makes it far worse (§4).

## 3. What `start_exit=0` means, and how C4 enters

`0` is the hexagram Kun (all yin lines, binary 000000). C4 fixes the sequence to open with the pair
(Qian, Kun) — pair 0 in received orientation. Phase 3 hard-codes this three ways:
1. pair 0 is **excluded** from `pair_indices` (full problem uses `range(1,32)`);
2. its orientation is fixed (Qian → Kun), never summed over;
3. the DP seeds `last = start_exit = 0` = Kun's value, so the first boundary test
   `d(0, f) != 5` is C2 applied across the Kun→(first free pair) boundary.

So C4 costs nothing in state — it just pins the DP's initial condition. (The phase-3 exchangeability
harness also calls `count` on random 10-pair subsets with the same `start_exit=0` default, i.e. a
virtual Kun predecessor; my validation in §5 covers both `start_exit=0` and `63`.)

## 4. What is counted, and the C5 budget question

**It counts sequences N, not orbits and not weighted objects**: each admissible (order, orientation)
assignment of the free pairs contributes exactly 1. Under TR-5 the S₄ action is free on solutions, so
the orbit count is N/24; the DP as written counts N.

**C5 is not tracked at all in phase 3.** To track it exactly you add a remaining-budget vector to the
state. Two honest sizings:

- **Full-sequence multiset (the naive sizing):** KW's 63 adjacent transitions have distance histogram
  d = (1,2,3,4,6) with counts **(2, 20, 13, 19, 9)** (computed from `solve.binary_hexagrams`;
  matches the operator's figure). Tracking that whole multiset gives
  3×21×14×20×10 = **176,400** budget vectors.
- **Pair-level residual (the correct sizing for THIS DP — smaller, and I believe this is the right
  way to price it, though I invite correction):** C1 already fixes the 32 within-pair distances
  (12×d2, 12×d4, 8×d6, orientation-invariant since d is symmetric). So C5 is equivalent to a
  condition on only the **31 boundary transitions**, whose residual multiset is
  d = (1,2,3,4,6) with counts **(2, 8, 13, 7, 1)** → at most 3×9×14×8×2 = **6,048** budget
  vectors — 29× fewer than 176,400. Better still, remaining-budget sum is forced to equal
  31−k at layer k, so each vector is live in exactly one layer: **max 413 vectors coexist per layer**
  (at remaining-sum 15/16).

**C5-tracked totals (computed by convolving V(s) = #vectors with sum s into the layer sums):**
states Σₖ C(31,k)·2k·V(31−k) ≈ **2.52×10¹³**; edges ≈ **7.60×10¹⁴**; peak two-layer memory
7.70×10¹² entries ≈ 62 TB @8 B/residue. That — not the 2×10¹² base ops — is the state-space killer,
and it is why the ledger says "C5 multiplies state by ~1.7×10⁵" (using the naive 176,400 sizing;
the per-layer-residual view above softens it to ~×378 states / ×380 edges effective, still fatal
at ~10¹⁵ ops + tens of TB). Any symmetry quotient (S₄ on pairs, ×24) helps both factors but does
not by itself close a 3-orders-of-magnitude memory gap; the boundary-residual + per-layer-sum
structure found here is the more promising lever and should be combined with the orbit quotient.

## 5. Validation (this box, 2-core, 2026-07-04)

Ran phase-3 `count()` verbatim against phase-2 `count_exact_bruteforce()` verbatim (both lifted
unmodified from the scripts) on three 8-pair reduced instances, ~9 s total CPU:

| subset (pair indices) | start_exit | brute force | phase-3 DP | match |
|---|---|---|---|---|
| [1,2,3,4,5,6,7,8] | 0 (Kun) | 4,575,168 | 4,575,168 | YES |
| [1,4,5,8,9,21,24,26] (random, seed 42) | 0 | 3,426,592 | 3,426,592 | YES |
| [3,4,14,18,19,22,24,31] (random) | 63 (Qian) | 2,965,728 | 2,965,728 | YES |

3/3 exact agreement (brute ≈ 3 s each, DP ≈ 0.01 s each). The reconstruction in §1 is confirmed
faithful to what the script computes. (Phase 2's own in-file 7-pair sanity check is the same
cross-check pattern.)

---
*Not committed (operator instruction + no-commit-window discipline). Attribution: analysis direction
and the 176,400 budget-state framing are the operator's; the boundary-residual 6,048/413-per-layer
refinement is this reconstruction's suggestion and has not been independently checked.*
