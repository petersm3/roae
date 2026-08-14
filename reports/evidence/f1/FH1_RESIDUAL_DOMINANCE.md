# FH-1 step 1: C5-residual dominance — theory, measurement, projection (2026-07-04)

Executes the first step of FOOTHOLDS FH-1 line (a): does a C5-residual equivalence collapse make
exact |C1..C5| feasible? Reference implementation extended (as a copy):
[`fh1_residual_instrument.py`](fh1_residual_instrument.py) (original `f1_orbit_dp.py` untouched).
Background: `F1_ORBIT_QUOTIENT_2026_07.md` (orbit-DP, 93,939,712 canonical masks, peak
two-live-layers 8.096e8 (mask,last) entries), `F1_PHASE3_RECONSTRUCTION.md` (boundary-residual
sizing, ≤413 residual vectors/layer).

**Headline: the capping idea is proven exact, but it is exactly dead-state pruning and nothing
more — a complete characterization shows NO two live residuals are ever future-equivalent. For
KW-realistic budgets the measured collapse at the wide layers is only ~1.2–1.4x (not the
conjectured 10–50x); the huge collapses (25x) appear only for pathologically skewed budgets.
Projected peak memory 1.2–2.0 TB (3x64-bit CRT passes): NOT feasible on 256 GB D64 or 672 GB
E96; marginal-to-feasible on a 2 TB+ M-series box or via out-of-core NVMe streaming.**

---

## 1. Setting and notation

State of the C5-tracked pair-level DP: `(mask, last, r)` where `r` is the residual budget vector
over the five boundary distance classes `d ∈ D = {1,2,3,4,6}`. C1 fixes the 32 within-pair
distances (12xd2, 12xd4, 8xd6) independent of order/orientation, so C5 (whole-walk transition
multiset = KW's `(2,20,13,19,9)` over d=(1,2,3,4,6)) is equivalent to a condition on the 31
boundary transitions with budget

    B0 = (2, 8, 13, 7, 1)   over d = (1, 2, 3, 4, 6),  Σ B0 = 31

(recomputed from `solve.binary_hexagrams` in this session; matches F1_PHASE3_RECONSTRUCTION §4).
Each transition consumes one unit of its class (requires `r_d ≥ 1`); C5 requires final residual 0.
`S = 31 − k` denotes remaining transitions at layer k (popcount of mask). `M(mask,last)` = the set
of boundary-distance multisets achievable by completions from `(mask,last)` to the full mask;
`P(mask,last)` = the set of prefix multisets (≤ B0) reaching `(mask,last)`.

## 2. Theory

**Lemma 1 (sum invariant).** Every forward-reachable residual at layer k satisfies `Σ_d r_d = S`.
*Proof.* Initially `Σ B0 = 31 = S` at k = 0; each step consumes exactly one unit and reduces S by
one. ∎

**Lemma 2 (order-irrelevance; what the DP value is).** A completion path π from `(mask,last)` is
admissible under residual r (never draws on an empty class) iff its multiset μ(π) satisfies
`μ(π) ≤ r` componentwise; and under Lemma 1 (`Σ μ = S = Σ r`), `μ(π) ≤ r ⟺ μ(π) = r`. Hence

    F(mask, last, r) = #{ completions π : μ(π) = r },

and the C5 end-condition (residual 0 at the full mask) is automatic — "at-most" and
"exact-multiset" semantics coincide on sum-consistent states.
*Proof.* Class-wise consumption is cumulative and order-independent: π blocks iff some class's
total usage exceeds its budget, i.e. iff NOT μ(π) ≤ r. The equivalence with equality is forced by
the matching sums. ∎

**Theorem (capping is exact).** Let `Bmax_d ≥ max{μ_d : μ ∈ M(mask,last)}` be any valid per-class
usage upper bound (with `Bmax_d := S` always valid, and `M = ∅` making every state dead). Define
`cap(r) = (min(r_d, Bmax_d))_d`. Then for every forward-reachable r:

    F(mask, last, r) = F(mask, last, cap(r)).

*Proof.* If `r ≤ Bmax` componentwise, `cap(r) = r` — identity. Otherwise `r_d > Bmax_d` for some
d. LHS: by Lemma 2, `F(r) = #{μ ∈ M : μ = r} = 0` because every `μ ∈ M` has `μ_d ≤ Bmax_d < r_d`.
RHS: `Σ cap(r) < Σ r = S` (strict at class d), so no μ with `Σ μ = S` satisfies `μ = cap(r)`;
`F(cap(r)) = 0`. Both sides are 0. ∎
The symmetric lower-bound version holds by the same argument (`r_d < min usage ⟹ F = 0`), giving
an exact **box test**: r is dead whenever it leaves `[Bmin(mask,last), Bmax(mask,last)]`.

**Two honest corrections to the FH-1 sketch.**
1. *The "safe bound = slots remaining" is vacuous.* By Lemma 1, `r_d ≤ Σ r = S` on every
   forward-reachable state, so capping at S never fires. Only class-specific bounds
   (`Bmax_d < S`) do anything.
2. *Capping never merges live states.* If `cap(r1) = cap(r2)` with `r1 ≠ r2`, at least one was
   strictly capped, and a strictly capped vector has deficient sum — so it, the shared image, and
   (by the Theorem) the pre-image are all dead. Live states (Σ = S, inside the box) are fixed
   points of cap. Capping = exact dead-state pruning, no more.

**Proposition (complete characterization of future-equivalence).** For r1 ≠ r2 at the same
`(mask,last)`: r1 and r2 are future-equivalent (every completion feasible-and-counted identically
under both) **iff both are dead** (`F(r1) = F(r2) = 0` path-wise, i.e. r1, r2 ∉ M).
*Proof.* If r1 ∈ M, some completion π has μ(π) = r1; π is admissible under r1 but not under r2
(Lemma 2, r2 ≠ r1) — not equivalent. Symmetrically for r2 ∈ M. If neither is in M, no completion
is admissible under either — equivalent (and both count 0). ∎
**Consequence: there is no residual "lumping" to be had among live states.** The minimal exact
per-state storage of ANY forward scheme is the live set
`live(mask,last) = {B0 − p : p ∈ P} ∩ M`, and the only lever is how cheaply dead residuals are
detected (box test = cheap partial detector; full M-intersection = gold, but computing M is a
backward DP as expensive as the forward one).

## 3. Instrumentation (exact, this box, 2026-07-04)

`fh1_residual_instrument.py`: S4-orbit-quotient layered DP (gather formulation lifted from
`f1_orbit_dp.py`) tracking multisets both ways — forward `P` (budget-killed at B0), backward `M`
(unbudgeted, spooled per layer), SWAR-packed 5x8-bit vectors, numpy set-arithmetic. Per layer, at
each (canonical-mask, last) it counts:
RAW = |P| (what a naive C5-tracked DP stores), BOX-mask / BOX-state (box test at mask / state
level — the practical cap), LIVE = |{B0−p} ∩ M| (gold, perfect pruning).

Validation (all PASS, asserted on every run):
- **V1**: 7-pair arbitrary subset, trivial group: per-layer states/RAW/LIVE equal a brute-force
  all-prefix DFS + memoized completion enumeration.
- **V2**: U1 (9 pairs, group-closed): plain-instrument per-layer RAW/LIVE totals == orbit-size-
  weighted canonical totals (stabilizer bookkeeping exact).
- **V3**: B0 ∈ M(0,start) and B0 reached at the full mask, every run.

Runs (group-closed unions; B0 = boundary multisets of actual valid completions found by
randomized DFS — achievable by construction; ~24 distinct budgets sampled per union, min/median/
max-V_peak representatives run):

| union | n | B0 (d=1,2,3,4,6) | V_peak | peak RAW/state (frac of V) | peak LIVE/state (frac of V) | BOX collapse | RAW/LIVE collapse |
|---|---|---|---|---|---|---|---|
| U13 (3+4+6) | 13 | (1,6,0,6,0) | 13 | 7.00 (0.54) | 7.00 (0.54) | 1.02x | 1.02x |
| U16 (4+6+6) | 16 | (1,8,1,6,0) | 28 | 8.71 (0.31) | 4.00 (0.14) | 1.11x | 2.07x |
| U16 | 16 | (6,5,2,3,0) | 64 | 19.2 (0.30) | 9.33 (0.15) | 1.68x | 1.99x |
| U16 | 16 | (3,5,3,4,1) | 132 | 45.4 (0.34) | 35.1 (0.27) | 1.24x | 1.36x |
| U18 (6+6+6) | 18 | (0,7,1,10,0) | 16 | 7.68 (0.48) | 0.65 (0.04) | 1.32x | 24.9x |
| U18 | 18 | (2,3,8,5,0) | 70 | 25.6 (0.37) | 18.3 (0.26) | 1.26x | 1.39x |
| U18 | 18 | (3,5,5,4,1) | 180 | 72.6 (0.40) | 62.6 (0.35) | 1.11x | 1.24x |

(Full per-layer tables in the script output; each n=18 forward pass 4–31 s, backward 44–73 s,
all runs within the 150 s local cap after the numpy rewrite.)

**Findings.**
- Peak-layer RAW is a stable **0.30–0.48 of V** across sizes and budgets (mildly increasing
  with n). The state space does not fill V, but it comes within a factor ~2–3 of it.
- For **balanced budgets** (the KW-realistic case — KW's (2,8,13,7,1) spreads over all five
  classes), RAW/LIVE collapse at the wide layers is only **1.24–1.39x**, and the *practical*
  box-cap detector captures just 1.1–1.3x. The FOOTHOLDS conjecture of a 10–50x collapse at the
  wide layers is **refuted for realistic budgets**.
- Large collapses exist only for extreme budgets (U18's (0,7,1,10,0): 24.9x) — states die because
  the budget is nearly unrealizable, not because of structural equivalence. KW's budget is not of
  this kind (it is the multiset of an actual walk with 63.4-bit log-count mass around it).
- Consistent with the Proposition: collapse tracks *deadness*, and near-peak layers of a
  permissive budget almost everything reachable is live.

## 4. Projection to 31 pairs (exact combinatorics x measured fractions)

Exact inputs (Burnside canonical-mask counts per layer from the 24 pair-perm cycle types, verbatim
`f1_orbit_dp.py` logic; V(s) from B0 = (2,8,13,7,1), peak V(15)=V(16)=413):

- C5-tracked orbit-DP entries if every state carried ALL sum-consistent residuals:
  Σ_k orb(k)·2k·V(31−k) = **1.100e12**; peak two live layers at k=15,16: **3.341e11** entries;
  edge ops 3.32e13.
- Applying the measured RAW fraction f (what a forward DP with budget-kill + box pruning actually
  stores; extrapolation assumes f transfers from n=16–18 to n=31 — the visible trend is mildly
  rising, so the upper end is the safer planning number):

| f | peak 2-layer entries | @12 B/entry (8B value, 3x64-bit CRT + 2B id + index) | @28 B (24B ~150-bit value, single pass) |
|---|---|---|---|
| 0.30 | 1.00e11 | **1.20 TB** | 2.81 TB |
| 0.40 | 1.34e11 | **1.60 TB** | 3.74 TB |
| 0.50 | 1.67e11 | **2.00 TB** | 4.68 TB |

Gold-live storage (unattainable without a backward pass of equal cost, shown as the theoretical
floor): live fraction 0.26–0.35 → 0.87e11–1.17e11 entries ≈ **1.0–1.4 TB @12 B** — pruning
perfection buys only ~15–25% off RAW for this budget. Edge ops ≈ 1.0–1.7e13 per CRT pass.
The task's coarser formula (effR x 93.94e6 canonical masks x 64 lasts) gives 9–15 TB @12 B; it
overcounts by holding all layers and all 64 lasts simultaneously — the layered figure above is
the operative one.

## 5. Verdict

- **256 GB (D64): NOT feasible.** Off by ~5–8x even at the theoretical live floor.
- **672 GB (E96): NOT feasible** in RAM (floor ≈ 1.0 TB).
- **2 TB M-series (M128s 2 TiB; M128ms 3.8 TiB): marginal-to-feasible.** f=0.30–0.40 @12 B fits
  in 2 TiB with thin margin; f=0.50 needs the 3.8 TiB SKU or 4-byte moduli (5 CRT passes,
  ~7 B/entry → 0.7–1.2 TB, comfortable). This is the only in-RAM route.
- **Out-of-core alternative:** the DP is strictly layered; 1.2–2.0 TB layers stream to/from
  Premium NVMe with mask-partitioned gathers (predecessors of a mask block live in a bounded set
  of predecessor blocks). Feasible on far cheaper hardware, at engineering cost; pairs naturally
  with per-layer checkpointing (Spot-safe).

**Run plan sketch (if operator green-lights; NOT started).** C implementation inside the existing
solve.c gate question (single-C-file rule): 3x (or 5x) CRT passes of the layered orbit-DP with
budget-kill + mask-level box pruning; per-layer checkpoint to Premium SSD; validate by (i)
reproducing |C1C2C4| exactly with C5 disabled ((7.5706e41 anchor), (ii) reduced-size sha-equality
against this instrument's Python totals, (iii) 3 CRT residues CRT-reconstructed and cross-checked
against the 1.3287e38 ±0.02% estimator value. Hardware: Standard (not Spot) M-series for the
in-RAM route — mid-layer eviction loses ~hours of uncheckpointed gather unless out-of-core
spooling is built anyway. Cost estimate (scoped, ±2x): M128s ~13 $/h on-demand westus3; edges
1.0–1.7e13/pass, memory-latency-bound ~1–2e9 edge/s aggregate → 2–5 h/pass, 3 passes + overheads
≈ 8–24 h ≈ **$100–320**; the out-of-core D64+NVMe route ≈ $30–80 but +days of implementation.
Per feedback_cost_awareness this needs operator sign-off either way.

**Caveats (honest).** (1) f is extrapolated from n=16–18 group-closed unions whose inter-pair
distance structure differs from the full 31-pair set; the bracketing 0.30–0.50 covers the
measured spread but n=31 could sit outside it. (2) Reduced-size budgets are analogues, not
restrictions, of KW's budget; the balanced-budget rows are the relevant comparison and they agree
with each other. (3) The 12 B/entry figure assumes the ragged (mask,last)->residual-id index
amortizes to ≤2 B/entry; a hash-table implementation would be ~2x worse.

---
*Attribution: FH-1 direction, the residual-dominance conjecture and the capping idea are the
operator's (FOOTHOLDS.md); the sum-invariant analysis, the dead/live characterization (§2), the
instrument and projections are Claude (Fable 5), 2026-07-04. The §2 proofs are believed complete
but have not been independently reviewed; the §4 extrapolation is an estimate, not a proof.
Correctness of the instrument is scoped to the validated instances (V1/V2/V3). Not committed
(operator instruction).*
