# PRE-REGISTRATION — H1 (compensation law) and H3 (distinguished-pair architecture) as K=4 pre-declared tests (2026-07-26)

*STAGED / HELD — roae-private only. This is a DESIGN document: a pre-registration + implementation
spec written BEFORE any code and BEFORE any run. It authorizes NOTHING — no code change, no VM, no
spend (recommendation ≠ authorization; operator go required for every step in §7). Developed with
AI assistance (Claude/Fable 5, Anthropic), operator-commissioned. H1/H3 remain private hypotheses
(`HYPOTHESIS_C6_2026_07_26.md`); no public-repo change is implied or staged by this document.*

*Freeze discipline: once the operator approves this spec, it is FROZEN (commit to roae-private =
the freeze event). Implementation and the single run follow the spec verbatim; any deviation is
logged in Appendix C before proceeding. KW is never seen by any threshold derivation (§3.4).*

---

## 0. What this is, and why NOT a grammar extension (the one-paragraph argument)

The obvious alternative — extend U2's grammar with product-aggregate and class-positional-count
operators so that H1/H3 "fall out of the search untouched" — self-defeats on its own accounting.
The extension would be chosen *because* we have already seen H1 and H3 look interesting on KW
(F4′'s `dist_autocorr` closest call; the §2c slot table read off KW this week), so "which operators
to add" is itself an untracked selection event: a garden-of-forking-paths step the run's
log₂(#distinct) charge would not capture. It would also multiply the syntactic space (U2 already
carries 341,331 candidates and a 13.05-bit selection charge), raising every candidate's bar while
adding thousands of never-hypothesized predicates as noise. The honest accounting for
*post-hoc-motivated* functionals is the opposite: a SMALL, fixed, pre-declared set of K named
predicates, charged log₂(K) explicitly, each with its own circularity audit — i.e., a targeted
pre-registered test through the existing rarity machinery. That is this document. K = 4.

Expected outcome, stated up front: **all four tests are predicted to FAIL their pre-registered
bars** (§5). That predicted null is a legitimate, defensible, *useful* result — it converts H1
from "the closest F4′ call" into a measured, honestly-comparatored pre-registered null, and gives
H3 its first measurement ever. It is not a disappointment and must not be re-run or re-tuned into
something else (see §8 decision tree).

## 1. Reference population (identical to U2's — the declared conditioning)

Uniform over C1∩C2∩C4∩C5, sampled by the existing exact-rejection sampler
`_gs_one_sample` in `roae/roae.py`: uniform over C1∩C4 orderings (31 free pair slots × 2³¹
orientations, first pair pinned (63,0)), accepted iff the transition multiset equals C5's
`[0,2,20,13,19,0,9]` (which implies C2). Measured acceptance ≈ 1/16,096; measured cost ≈ 108.8
cpu-ms/sample on D32als_v7 (U2 run record `U2_RUN_2026_07_26.md` §2). No new sampler is written;
the population definition is not re-derived.

Two structural facts (theorems, not observations) that make the H3 statistics well-posed pure
arrangement statistics: the within-pair distance multiset is a constant of the space
({2:12, 4:12, 6:8} — pair partition fixed by C1, distance orientation-invariant), hence the
boundary multiset is forced ({1:2, 2:8, 3:13, 4:7, 6:1}). So EVERY population member has exactly
8 within-pair-d=6 pairs and exactly 2 d=1 boundaries; only their *placement* varies.

## 2. The K = 4 pre-declared predicates (exact definitions)

Notation: S = (s₀,…,s₆₃) a population member; dᵢ = popcount(sᵢ ⊕ sᵢ₊₁), i = 0..62 (the 63-wave);
1-indexed pair slots j = 1..32 cover positions (s₂ⱼ₋₂, s₂ⱼ₋₁); within-pair transitions are even i,
boundaries odd i (the existing WITHIN/BOUNDARY gate convention). All definitions are KW-independent:
no constant below is read off the King Wen sequence.

**Structural classes (both of forced size, per §1):**
- D6(S) = { j ∈ 1..32 : popcount(s₂ⱼ₋₂ ⊕ s₂ⱼ₋₁) = 6 } — the slots holding the 8 complementary
  ("self-complementary-pair") pairs. |D6| = 8 always; 1 ∈ D6 always (C4 pins {63,0}).
- M1(S) = { j ∈ 1..31 : popcount(s₂ⱼ₋₁ ⊕ s₂ⱼ) = 1 } — the pair-slots followed by a d=1 boundary.
  |M1| = 2 always.

**Functionals:**
- A(S) = Σᵢ₌₀..₆₁ dᵢ·dᵢ₊₁ — the lag-1 product sum of the difference wave (H1's functional;
  identical to F4′ `dist_autocorr`). C5 fixes every moment of the dᵢ multiset, so A is the pure
  arrangement term of the lag-1 autocovariance.
- P(S) = #{ j ∈ D6(S) : j ∈ {1,32} ∨ (j−1) ∈ D6(S) ∨ (j+1) ∈ D6(S) } — the number of
  complementary pairs at an end slot or slot-adjacent (linear adjacency) to another complementary
  pair. P ∈ [1,8] (slot 1 always qualifies as an end).
- Q(S) = #{ j ∈ M1(S) : j ∈ D6(S) ∨ (j+1) ∈ D6(S) } — the number of d=1 ("Gray-step") boundaries
  directly flanked by a complementary pair. Q ∈ {0,1,2}.

**The four tests** (threshold derivation in §3; KW-satisfaction is a necessary condition — if KW
fails a predicate, that test's result is "KW-unsatisfied, 0 bits", also a legitimate outcome):

| # | Name | Predicate | Threshold source | Role |
|---|------|-----------|------------------|------|
| T1 | H1-median (honest weak form) | A(S) ≤ med\*(A) | Population median, sampled with KW held out (§3.2) | The honest H1 test |
| T2 | H1-perm-sign (sign-only control) | A(S) ≤ 693 | Closed form ⌊E_perm[A]⌋ = ⌊(S₁²−S₂)/63⌋ = ⌊43694/63⌋, S₁ = Σd = 211, S₂ = Σd² = 827 — a constant of C5's multiset, no sample, no KW | Quantifies how much anti-persistence-vs-free-arrangement the constraints already force |
| T3 | H3-P (edge/adjacency count) | P(S) ≥ med\*(P) | Population median, KW held out (§3.2) | The honest H3 placement test |
| T4 | H3-Q (cushion law, universal form) | ∀ j ∈ M1(S): j ∈ D6(S) ∨ (j+1) ∈ D6(S) (i.e. Q = 2 = \|M1\|) | None — universal quantifier over a forced-size class; no numeric threshold at all | The honest H3 cushion test |

**Sanity check, deliberately NOT charged in K:** the parity shadow — "no two odd-d transitions
adjacent" — is a theorem of the system (TR-6/TR-7: odd transitions sit only at odd indices).
Its population mass is provably 1, so it cannot be a discovery and carries no selection risk; it
is asserted on every batch purely as a sampler-correctness detector (alongside the existing
per-batch C4/C2 asserts in `_gs_rarity_batch`). Justification for exclusion from K: the selection
charge exists to price the chance of a false discovery among the tests that *could* pass; a
predicate with provable mass 1 has zero such chance.

**KW's values (computed this pass from `solve.py`'s array; these pin the SELFTEST, §6.4 — they
are evaluator-correctness constants, NEVER thresholds):** A(KW) = 648 (matches f4p
`dist_autocorr` kw=648); D6(KW) = {1,6,9,14,15,27,31,32}; P(KW) = 5; M1(KW) = {26,30};
Q(KW) = 2. NOTE: the hypothesis doc's illustrative "P ≥ 6" appears to be a miscount under its own
stated definition — under the formalization above, the qualifying members are {1,14,15,31,32},
so P(KW) = 5 (slots 6, 9, 27 have no D6 neighbor and are not ends). This spec's definition
governs; the discrepancy is flagged for the record and changes nothing (the threshold is
population-derived either way). Correction invited if the recount is wrong.

## 3. The comparator — the crux

### 3.1 Principle

The D-B1 firewall's threshold pathology is using KW's own value as the cut (C3's 776 pattern:
"A ≤ 648" is guaranteed KW-satisfied and prices as data, not as a principle). The U2 grammar
solved this by banning numeric magnitude thresholds outright. This spec gets magnitude back in
WITHOUT that circularity by making every threshold a **pre-declared population statistic**:
a deterministic function of (a) the sampled reference population with KW held out, or (b) a
closed-form constant of C5's declared multiset. KW's value 648 is never an input to any
threshold. The threshold *rules* below are frozen now, before any sampling.

### 3.2 Threshold derivation rules (frozen)

- med\*(A) = the smallest integer τ such that F̂_thr(A ≤ τ) ≥ 1/2, computed on the
  **threshold-derivation stream only** (§3.4). T1 ≔ A(S) ≤ med\*(A).
- med\*(P) = the largest integer τ such that F̂_thr(P ≥ τ) ≥ 1/2, same stream. T3 ≔ P(S) ≥ med\*(P).
- T2's threshold 693 is closed-form from C5's multiset (table in §2); no sample involved.
- T4 has no threshold (universal form).

Discreteness is handled by the explicit lower/upper-median rules above — no run-time judgment
calls. Predicted values (NOT bindings): med\*(A) ≈ 666–670 (from the published f4p histogram's
cumulative mass; the run resolves it exactly); med\*(P) unknown (H3 has never been measured;
best guess 3–5).

### 3.3 The two reporting tiers — honest test vs at-KW data

For each functional we report BOTH, explicitly labeled:

1. **Population-relative (the honest test):** frequency of the §2 predicate on the evaluation
   stream; bits-explained = −log₂ f; judged against the §4 bar. This is the only tier that can
   produce a "survivor".
2. **At-KW (C3-class, priced as data, NOT a test):** the one-sided masses at KW's own values —
   mass(A ≤ 648) and mass(A < 648) (cross-check §3.5), mass(P ≥ 5), mass(Q = 2) (= T4's own
   frequency). These are descriptive quantities for the DESCRIPTION_LENGTH ledger, exactly like
   C3's 776: admissible as *description*, never as a principled cut. From the doc: the at-KW H1
   figure is mass(A ≤ 648) = 4.79% → ×20.9 ≈ 4.4 bits — and §5 notes that even THIS circularly
   thresholded figure would fail the pre-registered bar, which defuses any temptation to promote it.

### 3.4 KW hold-out mechanics (enforced, not aspirational)

- **Stream separation:** threshold-derivation stream = seeds `seed+20000+b`; evaluation stream =
  seeds `seed+30000+b` (b = batch index). Both disjoint from each other and from U2's streams
  (`+100+w` probe, `+10000+b` rarity) at the same base seed 20260726.
- **Phase ordering in code:** Phase T (threshold stream) completes and its thresholds are
  computed, printed, and written to the JSON/checkpoint BEFORE any code path evaluates a
  functional on the KW array. KW enters exactly twice, both after the freeze point: (i) the
  KW-satisfaction bits of §2, (ii) the at-KW report of §3.3. The implementation makes this
  structural (KW evaluation lives in a phase that takes the frozen thresholds as arguments).
- **Auditability:** med\*(A), med\*(P) are deterministic functions of (base seed, N_thr, sampler
  code) — anyone can re-derive them without KW.

### 3.5 Cross-check gate against F4′ (reuse, don't re-invent)

H1's functional is ALREADY MEASURED: F4′ `dist_autocorr` (evidence/f4p_tier1.out row 10, Knuth
importance-weighted estimator) gives mean 671.22, mass strictly below 648 = 3.443%, at
648 = 1.347% → mass(A ≤ 648) = 4.789%. The evaluation stream's estimate of mass(A ≤ 648) — an
independent estimator (exact rejection sampling) of the same population — MUST satisfy
|p̂ − 0.04789| ≤ 0.005 (a wide gate: binomial σ at 10⁶ is ≈ 0.0002; the slack absorbs the Knuth
CI and binning). PASS → the two instruments corroborate and the f4p row is cross-validated for
free. FAIL → STOP: population-definition or sampler mismatch; investigate before interpreting
ANY result; no verdicts are issued. This gate is a validity precondition, not a hypothesis test.

## 4. Accounting: L(C), selection charge, success criterion (frozen)

### 4.1 Statement cost L(C)

Same convention as `_gs_cand_L`: L(C) = Σ over declared choice points of log₂(#alternatives),
with menus deliberately coarse and erring LARGE (against candidates), matching U2's
overprice-against-candidates stance. Declared menus:

- Statistic family (6, listed): {lag-product Aₖ, class slot-position count, boundary-flank count,
  parity-block profile stat, run-length stat, spectral stat} → log₂6 = 2.58 bits.
- Lag k ∈ {1,2,3,4} → 2.00. Direction {≤, ≥} → 1.00.
- Threshold rule {sample-median, closed-form E_perm, sample-q10, sample-q90} → 2.00.
- Pair class ∈ within-pair distance classes {2,4,6} → 1.58. Boundary class ∈ δ ∈ {1,2,3,4,6} → 2.32.
- Position feature {end∪adjacent, end-only, adjacent-only, canon-seam} → 2.00.
- Quantifier {ALL, EXISTS, NONE} → 1.58.

| Test | Choice points | L(C) bits |
|------|--------------|-----------|
| T1 | 2.58 + 2.00 + 1.00 + 2.00 | **7.58** |
| T2 | 2.58 + 2.00 + 1.00 + 2.00 | **7.58** |
| T3 | 2.58 + 1.58 + 2.00 + 1.00 + 2.00 | **9.17** |
| T4 | 2.58 + 2.32 + 1.58 + 1.58 | **8.06** |

### 4.2 Selection charge

**log₂ K = log₂ 4 = 2.00 bits**, added to every test's bar. This is the charge for the K tests
pre-declared HERE — not U2's 13.05 (these predicates are not members of U2's grammar: it has no
product terms and no class-position counts, so they were never among its 341,331 candidates) and
not a fictitious 10⁶.

**Lineage sensitivity (honesty note):** H1 surfaced as the closest call of the 13-functional F4′
battery, and H3 was read off KW in the hypothesis doc — the hypothesis-generation history is
itself a selection event that log₂4 does not fully cover. Sensitivity: charging the full lineage
(log₂(13 F4′ + 4) ≈ 4.09 bits) changes no verdict in §5 (all predicted margins are ≥ ~6 bits).
Chan (2026)'s independent external attestation of H1's direction partially externalizes H1's
share of this charge; H3 has no such external anchor (its classical warp/weft cousins — Wu Deng,
Lai Zhide — themselves read KW, so they attest at one remove only).

### 4.3 Success criterion (frozen)

A test **passes** iff: KW satisfies the predicate ∧ bits-explained = −log₂ f_eval > L(C) + 2.00,
with f_eval from the evaluation stream only. Bars: T1 > 9.58 bits (f < 1/766), T2 > 9.58,
T3 > 11.17, T4 > 10.06. Resolution at N_eval = 10⁶ is 19.9 bits — every bar is resolvable by
direct sampling; no zero-hit escalation path is needed (if any predicate somehow scores 0 hits,
report the one-sided 95% Wilson bound via `_gs_wilson_lower` and stop — no auto-escalation).
A pass is NOT a claim: it triggers §8's adversarial re-audit, nothing else.

**Robustness note:** the L menus are coarse by design. The §5 verdicts are insensitive to
repricing: under the most charitable defensible cost (2-member threshold menu, −1 bit) or the
harshest (U2's d1-T floor, 16.4 bits), every predicted FAIL stays a FAIL by ≥ 5 bits.

## 5. Pre-registered predictions — including the honest "H1 fails its own bar"

| Test | KW satisfies? (predicted) | Predicted bits-explained | Bar | Predicted verdict |
|------|--------------------------|--------------------------|-----|-------------------|
| T1 H1-median | Yes (648 < med\* ≈ 666–670) | ≈ 1.0 (mass ≈ ½ by construction of the median) | 9.58 | **FAIL by ≈ 8.6 bits** |
| T2 H1-perm-sign | Yes (648 ≤ 693) | ≈ 0.05 (mass ≈ 97% from the f4p histogram tail above 693) | 9.58 | **FAIL** — and the ~0.05 bits IS the finding: anti-persistence vs free arrangement is population-typical, i.e. mostly forced by C1–C5's parity skeleton |
| T3 H3-P | Uncertain — P(KW) = 5 vs unmeasured median (guess 3–5) | unmeasured; guess 0.5–2 | 11.17 | **FAIL predicted** (H3 is unmeasured; this run is its first measurement) |
| T4 H3-Q | Yes (Q(KW) = 2) | unmeasured; hypothesis doc's back-of-envelope ≈ 2.3 (×5) | 10.06 | **FAIL predicted** |

Stated plainly, in advance: **H1 is expected to fail its own bar, honestly.** Its non-circular
(population-median) cut is ≈ 1 bit against a ≥ 9.6-bit bar; even the *circularly-thresholded*
at-KW version (4.4 bits, C2-sized) would fail the same bar — so there is no accounting under
which H1 survives as a principle, and the run will demonstrate that rather than assume it. This
is the pre-registered expected NULL, consistent with the hypothesis doc's §4 ("U2 expected
survivors ≈ 0") and the EVAL_RESIDUAL prior. Its value:

1. H1 moves from "closest F4′ call" to "measured pre-registered null at an honest comparator" —
   adversarially defensible closure of the compensation-law candidacy at C6 grade.
2. H3's P and Q distributions get measured for the first time (closes it or escalates per §8).
3. The at-KW masses land in the DESCRIPTION_LENGTH ledger as properly-labeled C3-class data.
4. The f4p `dist_autocorr` row gets cross-validated by an independent estimator (§3.5), free.
5. T2 cleanly decomposes KW's anti-persistence into forced-share vs free-share.

## 6. Implementation plan (execute-without-rethinking; single-file rule: everything in roae.py)

### 6.1 Reused machinery (no re-implementation)

- `_gs_one_sample` — the sampler, unchanged.
- `_gs_rarity_batch`'s pattern — per-batch checkpointable workers with the C4/C2 per-batch
  asserts; JSONL checkpoint append + resume exactly as Phase D does.
- `_gs_wilson_lower` — only if a zero-hit occurs.
- The Phase-E ledger/verdict/JSON reporting style and the `report` dict convention.
- One tiny refactor: extract run_grammar_search's population-setup block (the ~15 lines building
  `_GS["others"]` / `_GS["target"]`, including the `[0,2,20,13,19,0,9]` assert) into
  `_gs_setup_population()`, called by both drivers. **Pure code motion — U2's output must remain
  byte-identical; verify by re-running `--grammar-search --gs-samples 2000 --gs-probe 256` and
  diffing against the recorded probe numbers before the prereg run.**

### 6.2 New functions (4)

1. `_ph_stats(seq)` → `(A, P, Q, parity_ok)` — one pass computing all §2 functionals plus the
   parity-shadow sanity bool. ~25 lines, integer arithmetic only.
2. `_ph_batch(args)` — `(batch_idx, seed_base, seed_off, want)` → per-batch histograms
   (dict A→count, dict P→count, dict Q→count), parity-violation count, trials, wall. Shared by
   both streams (differ only in seed offset). Reuses `_gs_one_sample` + the per-batch sanity
   asserts.
3. `_ph_median(hist, mode)` — the frozen §3.2 lower/upper-median rules ("le" for A, "ge" for P).
   Pure function of a histogram; unit-tested in the selftest.
4. `run_prereg_h1h3(n_eval, n_thr, workers, batches, seed, json_path, ckpt_path)` — driver:
   - Phase T: threshold stream (`seed+20000+b`), checkpointed; compute med\*(A), med\*(P);
     print + persist them (the freeze point).
   - Phase V: FIRST KW read — compute A/P/Q on `binary_hexagrams`, assert the §2 pinned values,
     record KW-satisfaction of T1–T4 against the frozen thresholds.
   - Phase E: evaluation stream (`seed+30000+b`), checkpointed; frequencies of T1–T4 and the
     at-KW masses (§3.3), the §3.5 cross-check gate (hard stop on fail).
   - Phase L: ledger — the §4.1 L table (hardcoded frozen constants with the menu breakdown in
     a comment pointing at this doc), +2.00 selection, per-test verdicts, predictions-vs-observed
     table, JSON report.

### 6.3 Flag surface (no new file; minimal new flags)

- New: `--prereg-h1h3` (action flag), `--ph-thr-samples` (int, default 100000).
- Reused: `--seed` (default 20260726 via the same fallback as U2), `--gs-samples` (= N_eval,
  default 1000000), `--gs-workers`, `--gs-batches` (default 100), `--gs-json`, `--gs-checkpoint`
  — when `--prereg-h1h3` is set and the latter two still hold their U2 defaults, the handler
  substitutes `prereg_h1h3_report.json` / `prereg_h1h3_ckpt.jsonl` (never clobber U2 artifacts).
- Documentation: one row in ROAE_PY_CLI.md **when and if the operator approves publication of the
  subcommand**; until then the code is staged like U2 was (nothing committed/pushed to public).

### 6.4 Selftest pins (extend `print_self_test`)

Assert: A(KW) = 648; D6(KW) = {1,6,9,14,15,27,31,32}; P(KW) = 5; M1(KW) = {26,30}; Q(KW) = 2;
⌊(211²−827)/63⌋ = 693; within-pair multiset {2:12,4:12,6:8}; boundary multiset
{1:2,2:8,3:13,4:7,6:1}; `_ph_median` on hand-built toy histograms (both parities, ties).
These pin the evaluators to independently-verified values (this doc + f4p row 10), not thresholds.

### 6.5 Sample sizes (justified)

- **N_eval = 10⁶** (evaluation stream). Justification: the existing U2 run's 10⁶ is the direct
  comparable; H1's relevant tail is 3.4–4.8% → ≥ 34k hits (rel. SE < 0.6%); resolution
  19.9 bits ≫ the max bar 11.2, so any pass/fail is resolvable; even a shock 10⁻⁴-mass outcome
  on T3 yields ~100 hits. Full population statistics via sampling is the declared method here —
  the population (~2¹²⁹·⁷) is not enumerable, and 10⁶ exact-rejection samples is the established
  instrument at this bar (matches the no-subsampling policy's intent: this IS the full declared
  measurement, not a shortcut of a feasible-larger one).
- **N_thr = 10⁵** (threshold stream). Median SE ≈ 1.25·σ/√N ≈ 0.06 in A-units (σ_A ≈ 15) —
  threshold jitter ≪ 1 integer step in expectation; costs only +10% sampling.

### 6.6 Run sizing and cost (measured basis, hedged)

Dominant cost is rejection sampling: 108.8 cpu-ms/sample measured on D32als_v7 (U2 record §2);
`_ph_stats` adds negligible per-sample work (4 integer functionals vs U2's 170 masks × 3,246
candidates). Total 1.1×10⁶ samples ≈ 33 cpu-h:

- **Spot D16als_v7 (~$0.12/hr): ≈ 2.1–2.5 h wall → ≈ $0.30.** Spot is fine at this scale
  (trivial-budget class; checkpointed batches resume across evictions). Alternatively Spot D32
  (~$0.30/hr): ≈ 1.1 h → ≈ $0.35. Either fits the **$1–5 envelope with wide margin**; quote
  $1–5 to absorb throttled-host retries and setup overhead. Throttle-probe on launch per
  standing rule; no wall-time cutoff (log-staleness monitoring only, per watchdog sizing rule);
  monitoring via zero-token bash monitors, not model calls.

### 6.7 Pre-registration checklist (ordered; each step operator-gated where marked)

1. Operator reviews this spec; approval = freeze; commit to roae-private (the freeze timestamp).
2. Implement §6.1–6.4 on a feature branch of the public repo working tree, STAGED ONLY (no
   commit/push; commit windows and review-before-push rules apply if/when it ships).
3. U2 code-motion regression: re-run the 2000-sample probe, diff vs the recorded numbers (§6.1).
4. Smoke test N ≤ 100 samples (orchestrator-permitted at this size; anything larger goes to the
   worker per the heavy-ops rule): selftest pins pass, thresholds print before KW phase,
   checkpoint resume works (kill + rerun).
5. **[OPERATOR GO — spend]** Launch one Spot D16/D32 (Spot-only rule; `az vm show --query
   priority` gate; session VM log; paired teardown plan). Run once: Phase T → V → E → L.
6. §3.5 cross-check gate. On FAIL: stop, preserve artifacts, investigate; no verdicts.
7. Record results in a run-record appendix to THIS doc (predictions table of §5 side-by-side
   with observed). Copy `prereg_h1h3_report.json` + checkpoint + unfiltered stdout into
   roae-private BEFORE teardown (evidence-before-teardown; archive-VM-scripts rule). Teardown.
8. No second run. No threshold changes, no quantile shopping, no added predicates. Any deviation
   → Appendix C entry BEFORE proceeding, with reason.

## 7. Circularity audit (per predicate, D-B1 rigor: functional form / parameters / threshold)

**T1 (H1-median).**
- *Functional form:* CLEAN. Predates the project — Chan (2026, arXiv:2604.09234, independent)
  measured the lag-1 anti-persistence; McKenna & McKenna (1975) named the wave; `dist_autocorr`
  was one of 13 pre-registered F4′ functionals. Statable with zero KW vocabulary.
- *Parameters:* lag 1 is the canonical smallest lag; charged anyway (2 bits, §4.1).
- *Threshold:* CLEAN — sample median with KW held out (§3.4); the direction (≤) was first seen
  on KW-side evidence but is externally attested by Chan and charged (1 bit + lineage
  sensitivity §4.2). Residual risk: none beyond the charged selection; the honest form simply
  buys ~1 bit.

**T2 (H1-perm-sign).**
- Fully clean end-to-end: functional as T1; threshold is a closed-form constant of C5's declared
  multiset (the conditioning, not a KW read — same status as U2's use of the multiset to define
  the population). The cleanest predicate in this set; also the weakest by construction.

**T3 (H3-P).**
- *Functional form:* **HIGH RISK, acknowledged.** The edge/adjacency pattern was read off KW's
  slot table in the hypothesis doc (§2c) — hypothesis generation, not evidence. This is exactly
  the region where Davis's operationalized placement claims went NULL and where D-B1 found
  fitted-circular structure. Mitigations: (i) aggregate COUNT over a C1-canonical class, not a
  slot template (Davis's pathology was exact placement); (ii) the class (complementary pairs) is
  KW-independent and of forced size; (iii) the feature choice is charged (2 bits) from a declared
  menu; (iv) classical warp/weft attestation (Wu Deng, Lai Zhide via Schulz 1982 / Nielsen 2003)
  exists but is KW-derived at one remove — claimed as motivation only, NOT as externalization of
  the selection charge.
- *Parameters/threshold:* CLEAN — population median, KW held out.
- *Standing rule:* a surprising PASS is literature/KW-derived-positive territory →
  **mandatory adversarial circularity audit before any staging** (per the D-B1 precedent rule);
  §8 encodes this.

**T4 (H3-Q).**
- *Functional form:* same KW-read-pattern caution as T3 (the "cushion" conjunction was noticed on
  KW). Mitigations as T3, plus: both classes (d=1 boundaries, complementary pairs) have forced
  sizes, and the predicate is a UNIVERSAL quantifier — no numeric threshold exists to fit. The
  forced part of the architecture (TG-2 flanking-exclusion: complementary pairs cannot flank the
  unique d=6 boundary) explains 0 bits and is NOT what T4 measures; T4 measures the free part
  (mass of Q=2 among arrangements).
- *Threshold:* none (universal form) — threshold-circularity is structurally impossible here.

**Meta-audit:** the K=4 set itself was chosen after seeing H1/H3 rank highly in a KW-informed
synthesis. That residual selection is priced by §4.2's charge + lineage sensitivity, and bounded
by the pre-registered predictions: since the declared expectation is 4/4 FAIL, there is no
"we predicted it" credit available for a pass — a pass is an anomaly that triggers scrutiny, not
a confirmed hypothesis.

## 8. Decision tree after the run (frozen)

- **4/4 FAIL (predicted).** Record the null in this doc's run appendix. H1 closed as a C6
  candidate at C6 grade (honest cut ≈ 1 bit, measured); H3 closed at its first measured
  magnitudes. at-KW masses go to the private ledger notes as C3-class data. No public change
  (Cook-influence-style discipline: private first; any public propagation is a separate
  operator-gated decision). Feeds the constraint-freeze discussion as evidence FOR the
  irreducibility characterization.
- **Any test passes its bar.** NO claim, NO staging. Sequence: (1) adversarial circularity
  re-audit (fresh pass, D-B1 rigor, ideally a separate session/model instance); (2) verify the
  §3.5 gate and re-derive thresholds independently; (3) present to operator with the audit;
  (4) only then discuss whether a v5-class definitional fork per U2's framing is even on the
  table. Nothing touches v4, any canonical sha, or the public repo.
- **Cross-check gate FAILS.** Validity failure, not a result: preserve artifacts, no verdicts,
  investigate the population/sampler discrepancy as its own root-cause task.

## Appendix A — frozen constants (verified this pass from solve.py's KW array + published evidence)

- C5 multiset [0,2,20,13,19,0,9]; S₁ = 211, S₂ = 827; E_perm[A] = 43694/63 ≈ 693.556 → T2 cut 693.
- Boundary multiset (forced) {1:2,2:8,3:13,4:7,6:1}; within-pair multiset (forced) {2:12,4:12,6:8}.
- A(KW) = 648; f4p row 10: mean 671.224, min 614, max 728, below 0.03443, at 0.01347
  (⇒ mass(A ≤ 648) = 0.04789, ×20.9 ≈ 4.38 bits, the C3-class at-KW figure).
- D6(KW) = {1,6,9,14,15,27,31,32}; P(KW) = 5 (see §2 note re the hypothesis doc's "≥6");
  M1(KW) = {26,30}; Q(KW) = 2.
- U2 measured: acceptance 1/16,096; 108.8 cpu-ms/sample (D32als_v7); U2 seed streams +100/+10000
  at base 20260726 (this spec claims +20000/+30000).

## Appendix B — predictions summary (to be diffed against observed in the run appendix)

T1: satisfy YES, be ≈ 1.0, FAIL. T2: satisfy YES, be ≈ 0.05, FAIL. T3: satisfy UNCERTAIN,
be unmeasured (guess 0.5–2), FAIL. T4: satisfy YES, be unmeasured (guess ≈ 2.3), FAIL.
Cross-check: p̂(A ≤ 648) ∈ 0.04789 ± 0.005. med\*(A) ≈ 666–670. med\*(P): no prediction (first
measurement).

## Appendix C — deviation log

(empty at freeze)

---

*Attribution: Chan (2026, arXiv:2604.09234) for the independent lag-1 anti-persistence prior
art; McKenna & McKenna (1975) for the difference wave; Wu Deng / Lai Zhide (via Schulz 1982,
Nielsen 2003) for the warp/weft skeleton motivating H3; TR-6/TR-7 for the parity-shadow
theorems; the F4′ battery (evidence/f4p_tier1.out) for the existing dist_autocorr measurement
this spec reuses; the U2 grammar-search design (roae.py + U2_RUN_2026_07_26.md) for the sampler,
the MDL convention, and the firewall this spec extends. Written by Claude (Fable 5, Anthropic)
under operator direction; developed with AI assistance. No novelty is claimed for pre-registered
population tests, MDL accounting, or held-out threshold derivation — all standard; the only
contribution is their specific application here, and errors are Claude's. Corrections invited —
including to P(KW) = 5 and the L-menu pricing. This document authorizes no code, no VM, no
spend, and no public change.*
