# F1 exact-count attack via free-S4 orbit quotient (#215) — WORKING LOG (started 2026-07-04)

## Objective
Turn |C1-C5| from a validated estimate (1.3287e38 ±0.02%) into an EXACT integer, by making the
surviving F1 route feasible through the TR-5 free-action structure (count = N/24 exactly; if the
counting recursion can be performed on S4-orbit representatives, the state space may shrink 24x, and
if transition WEIGHTS are S4-invariant, the DP collapses further onto invariant classes).

## Known state (from the F1 no-go, ledger + f1_evidence/)
- phase1: 3-class count-regular stable partition at hexagram level (12/20/30 oriented) EXISTS
- phase2: 0/12 same-class swap exchangeability -> no small lumping at hexagram level
- phase3: pair-level bitmask recursion count(mask,last) — the ~5e12-op route (infeasible then)
## Plan
1. Reconstruct phase-3's exact recursion + honest op/memory count (agent, in flight)
2. Group action: S4 acts on line-positions -> on hexagrams -> on PAIRS (permutes the 32 pairs,
   commutes with rev/comp) -> acts on (mask,last) states. Free on full sequences; question: is the
   action on the DP state space free enough / are transition matrices equivariant? (They should be:
   d(g·a, g·b) = d(a,b) for coordinate permutations+global flips — signed perms preserve Hamming.)
3. Burnside/orbit-DP: either (a) run DP on orbit representatives of (mask,last) — needs canonical
   orbit labeling of 2^32 masks under S4's pair-permutation (24 elts) -> ~2^32/24 states, or
   (b) count = (1/24)·sum_g fix(g) is WRONG for plain count (free action means fix(g)=0 for g≠e on
   SOLUTIONS — but Burnside applies to counting ORBITS = N/24, consistent; the DP itself must count N
   or orbits directly). Route (a) is the real candidate.
## Step 1 result (reconstruction, validated 3/3 vs brute force on 8-pair subsets)
rec(mask,last): 31*2^31 ~ 6.66e10 states, ~2.0e12 edge ops, 149-447 GB peak (LAYERED) — MEMORY BINDS.
Counts |C1 ∩ C2 ∩ C4| (no C3/C5). C5-tracked variant: x~413/layer -> ~60-180 TB, 7.6e14 ops.

## Step 2: equivariance (argument)
S4 (signed line-permutations mod {±I}, fixing pair0 setwise per C4) permutes the 31 free pairs and
the exit hexagrams; d(g·a,g·b)=d(a,b) (signed perms preserve Hamming), and g maps orientations of pair
p to orientations of pair g(p). Hence transitions and weights are G-equivariant and rec(g·s)=rec(s):
DP values are constant on orbits. (Mask stabilizers need standard orbit-DP bookkeeping — the action on
masks is NOT free; handled by canonical representative + stabilizer-aware expansion.)

## Step 3: feasibility recount under the quotient
- |C1C2C4| exact: memory 149-447 GB / ~24 -> **6-19 GB**; ops ~2e12 edges + ~24x canonicalization
  overhead ~5e13 simple ops -> C on D128: hours. **FEASIBLE.** Value: MDL cell 7.571e41 (+/-0.01%)
  becomes EXACT; absolute estimator anchor at full scale.
- |C1..C5| exact: ~2.5 TB layers even quotiented -> NOT feasible this window. Foothold: C5-residual
  dominance pruning + deeper class-collapse might close the gap for a future model.

## Step 4 result (2026-07-04): orbit-DP prototype VALIDATED 3/3 exact
[`f1_orbit_dp.py`](f1_orbit_dp.py). G48 verified elementwise (isometry on all 64x64, permutes the
32-pair set, fixes pair0 setwise, commutes with rev); quotient = 24 pair-perms, closure asserted.
Pair-orbits of the 31 free pairs: sizes 3,3,3,4,6,6,6. Design note: GATHER formulation — canonical
masks store the exact plain forward values f(c,last); stabilizer weights (orbit size = n_eff/|stab|)
enter only in the per-layer mass identity (asserted each layer), and the full mask is G-fixed so the
final total needs no correction. Validation on group-closed orbit-unions (plain phase-3 rec ==
plain layered forward == orbit-DP, exact big ints + layer masses, <1s each):
- U1 9 pairs (3+3+3), start 0: 63,366,144 (C2-pruned; 9!·2^9 would be 185.8M)
- U2 12 pairs (6+6), start 0: 1,961,990,553,600 (= 12!·2^12 exactly — no d=5 prunes inside this union)
- U3 13 pairs (3+4+6), start 63: 39,239,811,072,000 (pruned vs 51.0T unconstrained)
Collapse measured: 4.4x/14.8x/12.0x whole-run (restricted actions aren't fully faithful at small n).
Full-31-pair sizing EXACT via Burnside on k-subsets (cycle types of the 24 perms): 2^31 masks ->
93,939,712 canonical (22.86x); entries 6.657e10 -> 2.912e9; peak two-live-layers k=16,17:
1.863e10 -> 8.096e8 entries = **19.4 GB @24B single-pass or 6.5 GB @8B x3 CRT passes** — confirms
Step 3's 6-19 GB band with exact numbers. Next: C implementation (in-solve.c gate question for
operator) + D128 Spot cost estimate.
