# F11 — Corruption vs. tendency: Bayes-factor RESULTS (executed under the frozen pre-registration)

> **Reproduce:** `python3 f11_events.py` then `python3 compute_f11_bf.py` from this directory;
> the raw run outputs are preserved beside them (`f11_runA.out`, `f11_runB.out`, `f11_runC.out`,
> `f11_runC2.out`, `f11_events.json`). This bundle carries its instruments deliberately — see
> [../f11halfb/README.md](../f11halfb/README.md), which contrasts itself against this one.

> **Bayes verdict RESOLVED and RE-AFFIRMED (2026-07-13).** After this document was computed, the
> direct N_gs measurement in [../r11/](../r11/) fell **outside** the derived bracket used here,
> firing a pre-registered stop-and-investigate gate (2026-07-11). That gate is now closed: the
> derived bracket [1.03, 3.57]×10²⁵ was two point estimates carrying no propagated uncertainty —
> never a valid confidence interval — and a four-seed direct re-measurement gives
> N_gs = 4.50×10²⁵ (±6%, all three pre-registered convergence gates passing), which **re-affirms**
> the verdict at BF ≈ 5.2×10³ (U) / 6.3×10³ (A). See [TR-2 v1.12](../../TR2_THE_RULES_CONFLICT.md)
> §"Stop-flag resolution" and [../r11/](../r11/). Everything below is the as-computed 2026-07-04
> record, unchanged.

> **Calibration veto (2026-08-03; note added 2026-08-06 —
> [CORRECTIONS CX-25](../../../documentation/CORRECTIONS.md)).** The two-model pair behind this
> verdict — M_corr versus M_tend — has since failed its own pre-registered synthetic-draw
> confusability gate: Half B (M_tend self-recovery) **FAILED at 68/100** against a bar frozen at 70
> before the run (Half A passed 93/100; master seed published before launch, not re-run). The
> published BF ≈ 5.2×10³ (U) / 6.3×10³ (A) and the ≈0.9998 posterior are therefore **no longer
> calibrated in the pooled sense**; the numbers are unchanged and not withdrawn — what is withdrawn
> is their *calibration support*. The failure is stratum-confined (V=0 provably confusable, 0/277;
> V≥5 provably distinguishable, 599/599; the received sequence has V=6), but the gate's registration
> defines no bar at n=1000 and cannot produce a PASS, so the V-restricted rate may not be quoted as
> the gate outcome; a V-matched gate is a new instrument, registered but not yet run. See
> [../f11halfb/](../f11halfb/) and [TR-2](../../TR2_THE_RULES_CONFLICT.md) §"The result".

> **Withdrawal (2026-08-07 — [CORRECTIONS CX-26](../../../documentation/CORRECTIONS.md)).** The
> note above stopped at withdrawing calibration support; that split is superseded. The BF and the
> ≈0.9998 posterior are **withdrawn as claimed results**: everything below is the as-computed
> 2026-07-04 record — recorded, not claimed — and asserts no corruption-vs-tendency verdict pending
> the V-matched gate. See [TR-2](../../TR2_THE_RULES_CONFLICT.md) v1.27.

**Executed 2026-07-04** under the frozen pre-registration [PREREGISTRATION.md](PREREGISTRATION.md)
(FROZEN 2026-07-04, operator approval "approve F11 defaults" — PROOF_PROGRAM UPDATE 32). Model forms,
model prior (50:50), and Jeffreys decision bands (BF > 10 substantial, > 100 strong —
[Jeffreys 1961](../../../documentation/CITATIONS.md#jeffreys1961); a frozen project convention, not
Jeffreys' published table, see §5) are as frozen;
nothing in this document was altered after seeing the numbers except the numbers themselves. Per the
pre-registered commitment, the FULL sensitivity table is published regardless of direction.

Developed with AI assistance (Claude, Anthropic). Rule attribution: [Moore 1989](../../../documentation/CITATIONS.md#moore1989) (*The Trigrams of Han*,
App. 2) rhythm; [Moore 2005](../../../documentation/CITATIONS.md#moore2005) (*Oracle Papers* No. 1) pair-positioning parity; [Schulz 1990](../../../documentation/CITATIONS.md#schulz1990-motifs) (JCP 17:3)
gender/position-parity (exception first noted by Zhu Yuansheng, 13th c.), elaborated [Cook 2006](../../../documentation/CITATIONS.md#cook2006);
corruption mechanism [Rutt 1996](../../../documentation/CITATIONS.md#rutt1996) (bamboo-slat cords) as discussed by [Hacker & Moore 2003](../../../documentation/CITATIONS.md#hacker-moore2003).

**STATUS: COMPLETE — computed 2026-07-04.** Evidence archived in this directory,
`reports/evidence/f11/` (`f11_runA.out`, `f11_runB.out`, `f11_runC.out`, `f11_runC2.out`,
`f11_events.out`, `f11_events.json`); integration script `compute_f11_bf.py` (same directory).

**Headline (both frozen corruption-location variants, primary configuration):
BF(corruption/tendency) ≈ 6.6×10³ (variant U, uniform edit location) and ≈ 7.9×10³
(variant A, bamboo-adjacent-biased). Both exceed the frozen BF > 100 "strong" band.
Full sensitivity range across every pre-committed configuration: 1.4×10³ – 2.7×10⁴.
Under the frozen 50:50 model prior, posterior P(M_corr | data) ≈ 0.9998.**

## 0. Honest note on the grids

The frozen pre-registration declares the model forms, the 50:50 model prior, the two
corruption-location variants, and the Jeffreys bands explicitly, but records the priors as
"p_c ∈ {grid}, λ-prior {grid}" — symbolic placeholders; no numeric grid appears in the frozen
document or anywhere else in the repo (checked: git history of the prereg, PROOF_PROGRAM, FOOTHOLDS,
all *.md). The grids used here are therefore DECLARED at computation time, chosen wide (both spanning
~2 orders of magnitude, uniform weights) so that the per-gridpoint sensitivity table — which the
pre-registration commits to publishing in full — is the real deliverable, and any grid re-weighting a
reader prefers can be applied from the table alone:

- **p_c grid** (corruption-size parameter; k slot-edits ~ Geometric(p_c), support k ≥ 0,
  P(k) = (1−p_c)^k · p_c, E[k] = (1−p_c)/p_c): `{0.05, 0.1, 0.2, 0.3, 0.5, 0.7, 0.9}`, uniform.
- **λ grid** (Gibbs tendency strength): `{0.1, 0.2, 0.5, 1, 2, 5, 10}`, uniform. λ = 0 is excluded
  as it degenerates M_tend into the uniform-valid null rather than a "soft-preference" model.

## 1. The data event

Both models are full generative models over C1–C5 space (the shared substrate, which cancels), so the
likelihood is evaluated at the **exact received sequence** (King Wen). This is the
information-complete choice: KW's violation profile (2+2+2), the co-location of the violations, and
the SAT-exact repair distance 3 are all consequences of the exact sequence, not separate data items.
KW's violation vector was re-verified at computation time (`f11_events.py` import gates):
Moore-parity violations = 2, Moore-rhythm breaks = 2, Schulz-gender violations = 2 at class positions
{25, 26} — total V(KW) = 6.

## 2. Ingredient table

| # | Ingredient | Value | Status | Source / evidence |
|---|---|---|---|---|
| 1 | KW violation profile (2,2,2), V=6 | exact | REUSED (re-asserted) | solve.py checkers; sat.py import gates; `f11_events.py` asserts |
| 2 | Minimal repair = 3 slot-edits (grand-strict) | exact | REUSED | SAT + DRAT ([LITERATURE_RULES_POPULATION_TESTS.md](../../../documentation/LITERATURE_RULES_POPULATION_TESTS.md) §results 5–7); independently REPRODUCED by the k≤2 exhaustive event enumeration in RUN D (0 hits) |
| 3 | \|C1–C5\| space, **raw / orientation-explicit** (printed as `N_can`) | **1.328702e38** raw (2e10 probes, relerr 0.03%, 95%CI [1.3280e38, 1.3294e38]) — matches the published raw anchor 1.3287×10³⁸ ([SEARCH_SPACE_SIZE.md](../../../documentation/SEARCH_SPACE_SIZE.md)); RUN C2 independent: 1.328327e38 raw. ⚠ **[LABEL CORRECTED 2026-09-01 — this cell read "canonical space N_can". In this corpus *canonical* means orientation-DEDUPLICATED, a count of pair orderings whose ceiling is 31! ≈ 8.2228×10³³; 1.328702e38 exceeds that ceiling by ~16,159× and cannot be a canonical count. The VALUE is right and nothing downstream moves — it is the raw orientation-explicit estimate (raw ceiling 31!·2³¹ ≈ 1.77×10⁴³), it equals the published raw anchor, and every f11 mass that consumes it is a fraction of the same population, so no ratio in §4 changes. What was wrong is the label, inherited from the estimator's own printed `leaves_canonical_C1C5` line. The symbol `N_can` is kept because it is what `compute_f11_bf.py` prints (line 171); read it as *raw*. The orientation-deduplicated count of this space is NOT this figure — the previously published ≈3.3×10³⁷ estimate for it was withdrawn 2026-08-24 for exceeding the same 31! ceiling.]** | RE-MEASURED (same-run consistency) | c208/c211 scoreboard; `f11_runA.out` |
| 4 | Moore-joint strict size N_mj | **1.16583e29** (5e9 probes, relerr 2.98%) — +3.5% vs the 1.1266e29 anchor (inside ±4.7%); RUN C independent: 1.091306e29 (−3.1%) | RE-MEASURED | c208 strict walk; `f11_runB.out` |
| 5 | Triple-strict ("grand-strict") size N_gs | **3.57e25** primary (RUN C: 1.091306e29 × 3.27e-4); **1.03e25** cross (RUN B (0,0,0) cell: 1.16583e29 × 8.8277e-5). ×3.5 disagreement (rare-cell estimator noise); BOTH carried through the sensitivity table; the LARGER (corruption-conservative) is primary | **DERIVED** — see honest note below the table: the planned in-walk gender-strict prune output did not ship; N_gs comes from the gender-0-violation fraction *within* the delivered Moore-joint walks | `f11_runC.out` (scoreboard), `f11_runB.out` (hist plane); prereg anticipated: "the triple-strict size is measurable" |
| 6 | Gender-strict-only size | **~1.3e32** (RUN C2: 1.328327e38 × 1e-6; scoreboard precision 1 s.f.) — i.e. gender-strict mass ≈ 1e-6 of the raw C1–C5 space (row 3), one order LARGER than the prereg data-vector's rough "~<1e-7" guess (flagged in §8; info-only, does not enter the BF) | MEASURED FRESH (info/cross-check) | `f11_runC2.out` |
| 7 | Joint violation histogram f(v1,v2,v3) | **4,892 cells, Σf = 1.000000**; min total-V observed = 2 (cell (1,1,0)); KW's own cell (2,2,2) observed: f = 1.981e-8 ≈ 2.63e30 orderings | **MEASURED FRESH** (new SOLVE_KNUTH_F11_HIST instrument) | `f11_runA.out` (bulk) |
| 8 | Conditional gender histogram within Moore-strict (0,0,v3 plane) | **complete plane v3 = 0..24, Σf = 1.000000**; (0,0,0) = 8.8277e-5 | MEASURED FRESH | `f11_runB.out` |
| 9 | Conditional (v1,v2,0) plane within gender-strict | **NOT DELIVERED** — RUN C2 shipped scoreboard only (no `f11_hist` lines). The `aug`/`bridge` Z therefore uses the RUN B plane + the N_gs cell only (disclosed; effect bounded — see §6) | — (absent) | `f11_runC2.out` |
| 10 | Edit-event geometry: n_k (KW-producing events), \|E_k\|, variant-A weights, validity fractions, k = 1..6 | **n_1 = n_2 = 0** (reproduces SAT minimal-repair = 3), **n_3 = 2** of 7,975, n_4 = 9 of 86,681, n_5 = 18 of 783,783, n_6 = 23 of 6,076,161; variant-A weighted hits zA_3 = 0.5 of 1,602.25; GRAND-base validity fractions 0.3226 (k=1) → 0.00752 (k=6) | **MEASURED FRESH** (exact enumeration, not sampled) | `f11_events.json` / `f11_events.py` / `f11_events.out` |
| 11 | Grand-strict witness (precursor) | exact sequence | REUSED | SAT witness (LITERATURE doc result 6); re-verified by `f11_events.py` gates |
| 12 | Per-rule strict/KW-level masses (5e-6, 6.3e-4, <1e-7; ×1362, ×26, ×11364) | RUN A scoreboard cross-checks: M1-strict 5e-6 ✓, M2-strict 6.26e-4 ✓; gender-strict re-measured at ~1e-6 (see row 6 — the prereg's "~<1e-7" was a rough bound, off ~10×; info-only) | REUSED (cross-checks only — the BF uses ingredients 3–9 directly) | LITERATURE_RULES_POPULATION_TESTS.md; c208/c211 evidence |

**Honest note on ingredient 5 (N_gs) — instrument deviation.** The pre-drafted plan (and the §7
instrument-provenance paragraph below) expected RUN C to be a triple-strict *pruned* walk
(SOLVE_KNUTH_GENDER_STRICT) whose `leaves_canonical` (the estimator's printed label for the RAW
orientation-explicit count — see the row-3 note) would be N_gs directly, with an in-walk
leaf-scorer cross-check line ("mismatches must be 0"). The delivered `f11_runC.out` is instead a
second independent Moore-joint-strict walk (5e9 probes, 64 threads) whose scoreboard reports the
gender-0-violation fraction within that space (3.27e-4, scoreboard precision 3 s.f.); no prune
line and no mismatch line are present. N_gs is therefore a derived product, not a direct pruned
count, and it is the single least-precise ingredient in the whole computation: the two independent
derivations (RUN C: 3.57e25; RUN B's exactly-printed (0,0,0) histogram cell: 1.03e25) disagree by
×3.5, consistent with heavy-tailed weighted-estimator noise on a cell holding ~1e-13 of the raw
C1–C5 space. Per the
strictest-reading rule, the LARGER value (which weakens M_corr, since L_corr ∝ 1/N_gs) is primary,
and the full sensitivity table reports every configuration under both. The BF conclusion is
unchanged under either (§4).

## 3. Model implementations (frozen forms, operationalized)

### M_corr (both corruption-location variants)
Uniform precursor draw from the grand-strict set (probability 1/N_gs each) × a corruption event of k
slot-edits, k ~ Geometric(p_c). An event is a set of disjoint adjacent-slat transpositions (slots s,
s+1 exchange) plus slat inversions (orientation flips) — the two elementary operations **we adopt to
model** Rutt's bamboo-slat mechanism, not operations Rutt specifies: what is sourced (Rutt 1996 via
Hacker & Moore 2003, where this project read him) is cord-fraying on re-strung slats as a physical
corruption possibility; the restriction to *disjoint* and *adjacent* transpositions, the inclusion of
orientation flips, the geometric k and the adjacency weighting below are this work's
operationalization. Displaced slats may additionally be inverted. Slot 0 (pair 0 = 63,0) is fixed
by canonical form; edits act on slots 1–31. The slot-edit count k = number of slots whose
(pair, orientation) content changed — exactly sat.py's near-k metric, so the SAT distance results
apply verbatim. Events are involutions, so P(received = KW) enumerates KW-anchored events E with
E(KW) ∈ grand-strict:

    L_corr(p_c) = [ Σ_k Geom(k; p_c) · Σ_{E: |E|=k, E(KW)∈GS} P(E | k, variant) ] / (N_gs · D)

- **Variant U** (frozen: "edit location uniform"): P(E|k) uniform over all events of footprint k.
- **Variant A** (frozen: "bamboo-adjacent-biased"): P(E|k) ∝ 2^(−blocks(E)), blocks = number of
  contiguous slot-runs in the footprint — each additional damage locus costs a factor 2. This is the
  computation-time operationalization of the frozen phrase (disclosed; the prereg named the variant
  but not its functional form).
- **D** = P(C1–C5-valid outcome | model): the frozen "both conditioned on C1–C5" clause. Computed
  from the exhaustive event enumeration around the SAT witness precursor (a proxy for the GS-average;
  disclosed). Sensitivity row: D = 1 (unconditioned).
- Truncation at k ≤ 6 (exhaustively enumerated); contribution by k is reported so the truncation
  error is visible. Strictest-reading refinements applied at computation time (both push AGAINST
  M_corr): (a) the numerator keeps only the enumerated k ≤ 6 terms (omitting the positive k > 6
  tail); (b) the conditioning denominator D extends the geometric tail k > 6 with validity
  fraction vf_6 — an upper bound, since vf_k is monotonically decreasing (0.3226 → 0.00752 over
  k = 1..6) — making D larger. Numerator truncation error is small anyway: the k = 6 term carries
  0.4–0.9% of the numerator across the p_c grid.

### M_tend
Gibbs form P(S) ∝ exp(−λ·V(S)) over the C1–C5 space of §2 row 3 (raw / orientation-explicit), V = parity + rhythm + gender violations:

    L_tend(λ) = exp(−6λ) / Z(λ),   Z(λ) = Σ_cells N(v1,v2,v3) · exp(−λ(v1+v2+v3))

Z(λ) from the measured joint histogram (ingredient 7), with the rare low-V region — beyond sampling
reach of the unconditioned run — supplied by the dedicated conditional runs (ingredients 5, 6, 8, 9).
Three Z variants reported: `hist` (RUN A only), `aug` (strict planes + N_gs added), `bridge`
(log-linear interpolation across still-unobserved total-V levels; upper-Z / tendency-favorable).

Computation-time outcomes on the Z variants (disclosed): ingredient 9's (v1,v2,0) plane was not
delivered, so `aug` = RUN A histogram + RUN B (0,0,v3) plane (rescaled by N_mj) + the N_gs cell at
(0,0,0). Because the RUN B plane covers every total-V level 0..24 and RUN A covers 2..49, `aug` has
NO unobserved interior total-V level, so `bridge` degenerates to exactly `aug` (0 levels filled) —
it is retained in the table for completeness of the pre-committed variant list. `hist` (which lacks
V = 0, 1 entirely and so UNDERSTATES Z) is the most tendency-favorable variant and functions as the
conservative column. Note also that both models evaluate the likelihood of the EXACT received
sequence (§1), so the M_tend numerator is exp(−λ·6) with no cell-count factor; RUN A's direct
observation of KW's (2,2,2) cell (~2.63e30 orderings) enters only Z, not the numerator.

### Bayes factor
BF = [mean over p_c grid of L_corr] / [mean over λ grid of L_tend], per location variant × Z variant.
Model prior 50:50 (frozen), so posterior odds = BF.

## 4. Results

Population masses (recomputed at integration time from the archived outputs):
N_can = 1.328702e38 (raw / orientation-explicit — legacy symbol, see §2 row 3), N_mj = 1.16583e29, N_gs = 3.5686e25 (primary, RUN C) / 1.0292e25 (cross,
RUN B), N_gender-only ≈ 1.3e32.

**Headline (primary configuration: N_gs = RUN C, Z = `aug`, conditioned on C1–C5):**

| Corruption-location variant | marginal L(corr) | marginal L(tend) | **BF (corr/tend)** | log10 BF |
|---|---|---|---|---|
| **U** (uniform edit location) | 2.534e-30 | 3.815e-34 | **6.6×10³** | 3.82 |
| **A** (bamboo-adjacent-biased) | 3.022e-30 | 3.815e-34 | **7.9×10³** | 3.90 |

Under the frozen 50:50 model prior, posterior odds = BF; P(M_corr | data) ≈ 0.99985 (variant U).

**Full pre-committed sensitivity table** (every configuration; BF = corruption/tendency):

| N_gs source | Z variant | location | conditioned | BF | log10 BF |
|---|---|---|---|---|---|
| C (3.57e25, primary) | hist | U | yes | 6.6×10³ | 3.82 |
| C | hist | U | no (D=1) | 1.4×10³ | 3.16 |
| C | hist | A | yes | 7.9×10³ | 3.90 |
| C | hist | A | no | 1.7×10³ | 3.24 |
| C | aug | U | yes | **6.6×10³** | 3.82 |
| C | aug | U | no | 1.4×10³ | 3.16 |
| C | aug | A | yes | **7.9×10³** | 3.90 |
| C | aug | A | no | 1.7×10³ | 3.24 |
| C | bridge (≡ aug) | U | yes | 6.6×10³ | 3.82 |
| C | bridge | U | no | 1.4×10³ | 3.16 |
| C | bridge | A | yes | 7.9×10³ | 3.90 |
| C | bridge | A | no | 1.7×10³ | 3.24 |
| B (1.03e25, cross) | hist | U | yes | 2.3×10⁴ | 4.36 |
| B | hist | U | no | 5.0×10³ | 3.70 |
| B | hist | A | yes | 2.7×10⁴ | 4.44 |
| B | hist | A | no | 6.0×10³ | 3.78 |
| B | aug | U | yes | 2.3×10⁴ | 4.36 |
| B | aug | U | no | 5.0×10³ | 3.70 |
| B | aug | A | yes | 2.7×10⁴ | 4.44 |
| B | aug | A | no | 6.1×10³ | 3.78 |
| B | bridge (≡ aug) | U | yes | 2.3×10⁴ | 4.36 |
| B | bridge | U | no | 5.0×10³ | 3.70 |
| B | bridge | A | yes | 2.7×10⁴ | 4.44 |
| B | bridge | A | no | 6.1×10³ | 3.78 |

Range: **1.4×10³ – 2.7×10⁴** (log10 BF 3.16 – 4.44). Every marginalized configuration exceeds the
frozen "strong" threshold (BF > 100) by at least an order of magnitude.

**Per-gridpoint likelihoods (primary configuration)** — so any reader can re-weight the priors:

| p_c | 0.05 | 0.1 | 0.2 | 0.3 | 0.5 | 0.7 | 0.9 |
|---|---|---|---|---|---|---|---|
| L_corr (U) | 5.58e-30 | 4.99e-30 | 3.62e-30 | 2.45e-30 | 9.01e-31 | 1.94e-31 | 7.09e-33 |
| L_corr (A) | 6.57e-30 | 5.94e-30 | 4.34e-30 | 2.96e-30 | 1.10e-30 | 2.38e-31 | 8.78e-33 |

| λ | 0.1 | 0.2 | 0.5 | 1 | 2 | 5 | 10 |
|---|---|---|---|---|---|---|---|
| L_tend (aug) | 5.36e-38 | 3.29e-37 | 2.99e-35 | 2.12e-33 | 5.23e-34 | 1.45e-39 | 2.45e-52 |

BF(p_c, λ) matrix, variant U, primary configuration (posterior odds if ALL prior mass sat on one
gridpoint of each grid):

| p_c \ λ | 0.1 | 0.2 | 0.5 | 1 | 2 | 5 | 10 |
|---|---|---|---|---|---|---|---|
| 0.05 | 1.0e8 | 1.7e7 | 1.9e5 | 2.6e3 | 1.1e4 | 3.8e9 | 2.3e22 |
| 0.1 | 9.3e7 | 1.5e7 | 1.7e5 | 2.4e3 | 9.5e3 | 3.4e9 | 2.0e22 |
| 0.2 | 6.7e7 | 1.1e7 | 1.2e5 | 1.7e3 | 6.9e3 | 2.5e9 | 1.5e22 |
| 0.3 | 4.6e7 | 7.5e6 | 8.2e4 | 1.2e3 | 4.7e3 | 1.7e9 | 1.0e22 |
| 0.5 | 1.7e7 | 2.7e6 | 3.0e4 | 4.3e2 | 1.7e3 | 6.2e8 | 3.7e21 |
| 0.7 | 3.6e6 | 5.9e5 | 6.5e3 | 91 | 3.7e2 | 1.3e8 | 7.9e20 |
| 0.9 | 1.3e5 | 2.2e4 | 2.4e2 | 3.3 | 14 | 4.9e6 | 2.9e19 |

Gridpoint extremes (variant U): minimum BF = 3.3 at the single least-favorable corner
(p_c = 0.9 — i.e. a prior conviction that corruptions are almost always 1 slot-edit, disfavoring
the observed k = 3 — combined with λ = 1, M_tend's best fit). 48 of 49 gridpoints give BF > 10;
46 of 49 give BF > 100. Variant A: minimum 4.1, same corner. Under the RUN-B N_gs the worst
gridpoint rises to 11.6. So even a reader free to concentrate ALL prior mass on the single most
tendency-favorable gridpoint cannot push the evidence below "substantial" except marginally at
that one corner under the conservative N_gs.

## 5. Jeffreys-band interpretation

Frozen decision bands: BF > 10 substantial, BF > 100 strong.

**Band provenance (note added 2026-08-06; the bands themselves are as frozen 2026-07-04 and are
unchanged).** These values are a project convention loosely following
[Jeffreys (1961)](../../../documentation/CITATIONS.md#jeffreys1961), **not a quotation of his
table**, and they match neither published scale: Jeffreys' own "substantial" grade is ≈3.2–10, and
[Kass & Raftery (1995)](../../../documentation/CITATIONS.md#kass-raftery1995) place "strong" at
20–150. Each frozen threshold sits at or above its published counterpart, so every verdict below
that clears the frozen bands also clears both published tables. See the full band-provenance note in
[TR-2](../../TR2_THE_RULES_CONFLICT.md) §"Pre-registration discipline".

- **Variant U (uniform edit location): BF ≈ 6.6×10³ → STRONG evidence for M_corr** (corruption),
  ~66× beyond the strong threshold.
- **Variant A (bamboo-adjacent-biased): BF ≈ 7.9×10³ → STRONG evidence for M_corr**, ~79× beyond.
- Every one of the 24 pre-committed marginal configurations is in the strong band
  (range 1.4×10³ – 2.7×10⁴); the direction never flips anywhere in the sensitivity space,
  including every per-gridpoint cell.

The verdict is stated at the corruption-conservative (larger, RUN-C) N_gs; the RUN-B N_gs would
make it ~3.5× stronger still. **(RESOLVED 2026-07-13:** the later direct N_gs measurement
([../r11/](../r11/)) landed outside this bundle's derived bracket and fired the pre-registered
stop-and-investigate gate (2026-07-11); the investigation found the bracket was never a valid
confidence interval, and a four-seed direct re-measurement gives N_gs = 4.50×10²⁵ (±6%, all three
convergence gates passing) — **re-affirming** this Jeffreys-band verdict at BF ≈ 5.2×10³ (U) /
6.3×10³ (A). See [TR-2 v1.12](../../TR2_THE_RULES_CONFLICT.md) §"Stop-flag resolution". The
as-computed record here is unchanged; the flip threshold at the directly measured value is ≈ 52×.**)**
*(Superseded in one respect, 2026-08-03 — see the calibration-veto note in the document header:
the pair later failed its confusability gate, so this Jeffreys-band verdict is no longer calibrated
in the pooled sense; the numbers stand, their calibration support does not.
[CORRECTIONS CX-25](../../../documentation/CORRECTIONS.md).)*

## 6. Sensitivity — which ingredient dominates

1. **N_gs (×3.5 between the two independent derivations) is the largest single uncertainty**, and
   it maps linearly onto the BF (L_corr ∝ 1/N_gs): BF spans 6.6×10³ → 2.3×10⁴ (variant U,
   conditioned) across it. It cannot change the verdict: pushing the BF down to the strong
   threshold (100) would need N_gs ≈ 2.4e27, ~66× the larger estimate — far outside any plausible
   estimator noise, and the two independent runs bracket 1e25–3.6e25.
2. **C1–C5 conditioning (D)** is the next-largest factor: ~×4.6 on the marginal BF (D ranges
   0.080 at p_c = 0.05 to 0.930 at p_c = 0.9; the D = 1 rows are the unconditioned floor at
   1.4×10³). The conditioned rows are the
   model-faithful ones (the frozen "both conditioned on C1–C5" clause); the unconditioned rows
   still clear the strong band.
3. **Corruption-location variant (U vs A)**: ×1.2 — negligible; both frozen variants agree.
4. **Z variant (hist / aug / bridge)**: <×1.01 — Z is dominated by the mid-V bulk at the λ values
   where M_tend is competitive (λ ≈ 0.5–2), which RUN A pins to 0.03% relative error. The sparse
   low-V cells of RUN A (weighted rare-event estimates) affect only the λ ≥ 5 gridpoints, which
   are ~10⁵ further suppressed; O(few)× noise there moves nothing.
5. **Priors within the declared grids**: the p_c grid spans ×14 in L_corr (p_c = 0.05 → 0.9); the
   λ grid spans ×10⁴ in L_tend among its competitive points (λ = 0.5–2 vs the rest). This is the
   spread a reader re-weighting the grids can exploit — bounded by the gridpoint matrix above
   (minimum 3.3 at one corner, >100 at 46/49 points).
6. **RUN-D truncation (k ≤ 6)**: <1% on the numerator (k = 6 carries 0.4–0.9%); the denominator
   tail is bounded above by construction. Direction of both residuals is anti-corruption
   (strictest reading), so the true BF is, if anything, slightly larger.

What makes the result this one-sided, in one sentence: M_tend must pay for the enormous
near-compliant population (its best λ ≈ 1 still leaves Z ≈ 1.2e30-equivalent mass, so the exact
sequence gets ≤ 2.1e-33), while M_corr concentrates 1/N_gs ≈ 2.8e-26 × an exactly-enumerated
event probability ~1e-4–1e-5 on sequences 3 edits from strictness — and KW is one of very few
such sequences (2 of 7,975 k = 3 events).

## 7. Reproduction

Computed 2026-07-04. Evidence files (archived copies of the worker outputs; byte-identical to the
`/tmp/f11_*.out` originals delivered from c222-f11):

    reports/evidence/f11/f11_runA.out    # 2e10-probe joint violation histogram (main evidence)
    reports/evidence/f11/f11_runB.out    # 5e9-probe Moore-joint-strict walk + (0,0,v3) plane
    reports/evidence/f11/f11_runC.out    # 5e9-probe Moore-joint-strict walk (scoreboard only)
    reports/evidence/f11/f11_runC2.out   # 2e9-probe unconditioned walk (scoreboard only)
    reports/evidence/f11/f11_events.out  # RUN D exact edit-event enumeration, k = 1..6
    reports/evidence/f11/f11_events.json # RUN D full per-k records (hits, zA weights, validity)

To reproduce the Bayes factors (pure closed-form integration over the archived outputs, ~1 s,
no sampling, no network):

    cd reports/evidence/f11
    python3 compute_f11_bf.py

The script re-derives every population mass from the raw run outputs, re-asserts the sanity gates
(declared probe counts 2e10/5e9/5e9/2e9; both histograms sum to 1.000000; RUN B cells all
(0,0,·); RUN A contains no Moore-strict-plane cell; event-space counts base-independent;
n_1 = n_2 = 0 reproducing SAT minimal-repair = 3), and prints the headline BFs, the full 24-row
sensitivity table, the per-gridpoint likelihoods, and the 7×7 BF(p_c, λ) matrix exactly as
tabulated in §4. To regenerate RUN D from scratch (exact enumeration; measured 2026-09-02 on the
2-core orchestrator: 4 m 39 s, rc 0, stdout and `f11_events.json` byte-identical to the tracked copies):

    cd reports/evidence/f11
    python3 f11_events.py                     # rewrites f11_events.json

The script locates the repo's `solve.py` itself (a `sys.path` line, the same idiom as the `f1/`,
`f5/` and `r11/` instruments). Until 2026-09-02 it did not, so the header's `python3 f11_events.py`
"from this directory" died with `ModuleNotFoundError: No module named 'solve'` unless the reader
supplied `PYTHONPATH=../../..` — which this paragraph prescribed but the header did not. Found by
`scripts/exec_lane.sh`; the `PYTHONPATH` form still works.

Instrument provenance: the F11 estimator extension (SOLVE_KNUTH_F11_HIST joint histogram +
SOLVE_KNUTH_GENDER_STRICT in-walk prune; estimator-only, sha-neutral) ran on the worker as
`solve_c_f11.patch` and was **merged into the public `solve.c` on 2026-07-04** (selftest sha
`403f7202…` unchanged; both flags documented in [SOLVE_C_CLI.md](../../../documentation/SOLVE_C_CLI.md) §ENVIRONMENT), so the RUN A
histogram is re-derivable from the public tree. Worker: c222-f11, Spot D32als_v7, launcher `f11_launch.sh`
(c215 pattern: throttle probe, selftest gate, auto-shutdown backstop, delete-on-completion).
Deviation note: the delivered RUN C/C2 outputs contain the scoreboard only — the planned
gender-strict prune output and its leaf-scorer mismatch line did NOT ship, so N_gs is derived
rather than directly counted (see the honest note under §2), and the RUN C2 (v1,v2,0) plane
(ingredient 9) is absent. Neither gap can flip the verdict (§6, item 1).

## 8. Honest outcome (pre-committed publication, whatever the direction)

The pre-registration's freeze condition was publish-whatever-it-says. What it says: **the
evidence favors corruption over tendency, strongly, in both frozen corruption-location variants
and in every cell of the pre-committed sensitivity space.** BF ≈ 6.6×10³ (variant U) and
≈ 7.9×10³ (variant A) at the primary configuration; never below 1.4×10³ in any marginalized
configuration; direction never flips at any single prior gridpoint (worst corner 3.3, still
above 1). This is not an equivocal result and it is reported as such — but its scope must be
stated precisely:

- It is a comparison of exactly TWO models. It says the received sequence looks far more like
  "a rule-perfect ordering hit by a small physical corruption at slots 21/22" than like "an
  arranger who held the three literature rules as soft Gibbs preferences." It does NOT test, and
  cannot support, "the rules are real" against models outside this pair (e.g. the rules being
  post-hoc pattern-noise on a sequence arranged by entirely other principles — that is F-series
  work elsewhere in the program).
- It inherits the three rules and the corruption mechanism from the literature (Moore, Schulz,
  Rutt/Hacker); the Gibbs form and the event model are our operationalizations, disclosed above.
- Honest caveats, none verdict-threatening: the priors grids were declared at computation time
  (§0) because the frozen document left them symbolic; N_gs — the weakest ingredient — is a
  derived quantity whose two independent estimates disagree ×3.5 (both reported, conservative one
  primary); ingredient 9 was never delivered; the prereg's rough "~<1e-7" gender-strict guess
  measured ~10× larger (~1e-6, info-only). Every discretionary choice forced by these gaps was
  taken in the direction that WEAKENS the winning model, and the margin survives all of them by
  ≥ an order of magnitude.

One-line honest interpretation: **conditional on the literature's three rules being the relevant
regularities, the King Wen sequence is far better explained as a corrupted rule-perfect ordering
than as the output of a soft-preference arranger; whether the rules themselves are the right
lens remains outside this test's scope.**
