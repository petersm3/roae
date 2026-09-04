# Shared Methods Appendix — environment, statistics, and artifact access
*Referenced by every technical report's Verification Guide. Addresses systemic gaps identified by
adversarial replication reviews conducted during development. Those review documents are **not
public** — they live in a private operational repository and are not publishable from it, so this
sentence points at their effect on this appendix, not at a document you can open. What they produced
is here, and in [CORRECTIONS.md](../documentation/CORRECTIONS.md). (Corrected 2026-08-07, CX-31: the
prior wording, "archived alongside this suite", implied a public artifact that does not exist.)*

## Constraint set (C1–C5, and the identifying C6/C7)

Every report measures the same object. The formal predicates (full statements + theorems:
[SPECIFICATION.md](../documentation/SPECIFICATION.md)):

- **C1 — classical pairing.** The 64 hexagrams form 32 consecutive pairs, each a hexagram and its
  reverse (or, for the 8 self-reverse hexagrams, its complement) — the Yu Fan / Lai Zhide pang-tong/fan-dui
  structure. Radisic (2026) proves this is the unique Hamming-cost-minimizing comp/rev matching.
- **C2 — no distance-5 transition.** No adjacent transition has Hamming distance 5. (Mathematically
  implied by C5's histogram; retained as an O(1) boundary pre-filter.)
- **C3 — complement-proximity ceiling.** For the ×64 integer representation, the complement-distance sum
  `Σ_{v∈H} |pos(v) − pos(v̄)|` **≤ 776** (the sum runs over all **64** hexagrams — hence mean cd = 776/64 = 12.125; notation corrected 2026-08-01 from `Σ_pairs`, which would halve it) (equivalently mean complement distance cd(S) ≤ 12.125). **The bound is a
  ceiling, not an equality: King Wen attains it exactly (776), and any ordering with a smaller sum also
  satisfies C3** (e.g. the wrap-d5 witness at 752). The threshold 776 is King Wen's own value —
  reverse-engineered, not derived; priced as circular in [TR-9](TR9_PRICING_THE_CONSTRAINTS.md).
- **C4 — fixed opening pair, defined orientation.** The first pair is {Qian(63), Kun(0)}; its orientation
  (Heaven 63 before Earth 0) is **definitional**. ⚠ **[CORRECTED 2026-08-30 — the parenthetical
  previously read "and classically attested (the Xugua opens Heaven-then-Earth)". The Xugua does not
  attest the WITHIN-PAIR order.** Its opening, 有天地，然後萬物生焉, sequences *the pair* before the myriad
  things — 天地 is a compound, not an ordering of Heaven over Earth. What the classical record does
  attest is **C1**, the pairing rule: 孔穎達《周易正義·序卦傳疏》 gives 二二相耦，非覆即變 — "they pair
  two-by-two; if not inverted, then complemented" — with both halves enumerated. That is the pairing
  pedigree, and it is 7th-century. C4's orientation is **ours by definition**, and the honest framing is
  that it is a convention we fixed, not an inheritance we found.]** It is NOT forced by the other constraints — complementation (x ↦ x ⊕ 63) is an
  exact symmetry of C1∩C2∩C3∩C5 broken only by oriented C4, machine-checked in
  [lean/KingWen.lean](../lean/KingWen.lean) *(the former "Theorem 6" forced-orientation claim is
  retracted, 2026-07-26 — see CLAIMS_DECIDED's corrections ledger)*. [TR-9](TR9_PRICING_THE_CONSTRAINTS.md)
  already prices C4 at its full 6 bits (pair + orientation), so no ledger value moves.
- **C5 — transition-distance multiset.** The multiset of all **63** consecutive-hexagram Hamming distances
  equals King Wen's: **{1:2, 2:20, 3:13, 4:19, 6:9}** ([SPECIFICATION.md](../documentation/SPECIFICATION.md) §C5).
  Extracted from KW (confirmatory, not predictive). *(Corrected 2026-08-01: this read "the 31 between-pair
  boundary Hamming distances … {1:2, 2:8, 3:13, 4:7, 6:1}". That multiset is **not the definition of C5** —
  it is the machine-checked theorem `boundary_budget_general` (lean/TrigramTheorems.lean), which DERIVES the
  boundary budget from C1 + full C5. Stating the theorem's conclusion as the constraint's definition made the
  theorem vacuous, and broke the very next bullet: C2 is implied by the 63-transition histogram directly, but
  from a boundary-only multiset only via C1's within-pair-evenness theorem. The two are equivalent **given
  C1**; as free-standing predicates they are different constraints.)*
- **C6, C7 — identifying adjacency pins.** Specific slot-24–27 (0-based pair slots — pairs 25–28, boundaries 25 and 27, in the 1-based numbering used elsewhere) adjacency choices used only to single out
  King Wen within the C1–C5 family (they cut the space by ×2.55×10⁶ but leave ≈5.21×10³¹ orderings —
  [TR-4](TR4_SIZE_OF_THE_SPACE.md) §4). Not part of the enumerated canonical constraint set; data-like,
  priced ≈0 in [TR-9](TR9_PRICING_THE_CONSTRAINTS.md).

The minimum independent rule set is {C1, C3, C4, C5} (SPECIFICATION.md §Numbering note). "The space" in
the reports means the **C1–C5** population unless stated otherwise.

**Legacy shorthand — "C1+C2+C3" means the same thing (note added 2026-08-01).** Several older passages
(and `solve.c`'s own console strings) describe the canonical enumerated population as "C1+C2+C3". That
is **historical naming, not a narrower constraint set**: the enumerator's counter is called `solutions_c3`
but, as its own source comment states, *"C3-valid" = passed ALL constraints (C1-C5), not just C3*
(`solve.c:865`) — and `solve --verify` confirms every canonical record satisfies C1–C5
(CANONICAL_HASHES §"d3 560T", CAMPAIGN_METHODOLOGY §7). Read "the C1+C2+C3 canonical" as
**the C1–C5 canonical** wherever it appears. New text should say C1–C5.

## Canonical quantities (single source of truth)

Every load-bearing integer in the suite, with its status, counting convention, and source report. Where
two numbers differ, they differ by **convention** (orientation-raw vs orientation-deduplicated vs
orbit-quotient), not by disagreement.

| Quantity | Value | Status | Convention | Source |
|---|---|---|---|---|
| C1–C5 space size | 1.3287×10³⁸ (95% CI [1.3283, 1.3292]×10³⁸, 0.02%) | **estimate** (Knuth) | raw (orientation-explicit; label unified 2026-08-06 — "orientation-resolved" elsewhere in the suite is the same convention) | [TR-4] §3 |
| C1–C5 space size | ≈3.3×10³⁷ | 🔴 **WITHDRAWN 2026-08-24** — this *orientation-dedup* figure exceeds its own 31! ≈ 8.2228×10³³ ceiling by ~4,013×; see [CORRECTIONS.md](../documentation/CORRECTIONS.md). **The raw 1.3287×10³⁸ estimate above is unaffected and stands.** | orientation-dedup | [TR-4] §Abstract |
| \|C1∩C2∩C4\| | 757,058,601,340,255,440,651,419,713,405,330,315,358,208 ≈ 7.5706×10⁴¹ | **exact** (two-instrument — independently recomputed at full scale 2026-07-25 by `verify.c --ie-count --ie-no-budget`, exact MATCH; mod-24 gated) | raw (orientation-explicit, C4 pinned) | [TR-11] §1–4 |
| \|C1∩C2∩C4∩C5\| | 1,097,051,278,789,181,790,036,112,071,176,579,186,688 ≈ 1.097051×10³⁹ | **exact** (two-instrument: independently recomputed at full scale 2026-07-25 by the verify.c IE transfer-walk engine — exact MATCH; mod-24 + ladder-corroborated) | raw (orientation-explicit, C4 pinned) | [TR-11] §9 |
| \|C1–C7\| | 5.21×10³¹ (95% CI [5.13, 5.29]×10³¹, 0.78%) | **estimate** | raw (orientation-explicit) | [TR-4] §4 |
| \|C1–C7\|, C3 dropped | 516,880,238,445,773,965,371,923,491,676,160 ≈ 5.16880×10³² | **exact** (two-instrument — (i) IE pinned-step recount 2026-07-25, `verify.c --ie-pin-c6c7 --ie-no-quotient`, small-n-validated 52/52, 3-prime-CRT self-consistent; (ii) independent direct mask-DP recount 2026-07-26, `verify.c --dp-count --dp-pin-c6c7` — a different algorithm class (explicit exact-cover subset DP with polynomial budget-coefficient extraction, no inclusion–exclusion, sharing only the problem spec), small-n-validated 44/44 incl. three-way vs brute force, matched the same integer exactly; mod-24 N/A under pins; lands inside the prior 5.18×10³² estimate's 0.25% CI, ~0.22% below the point estimate — a 3rd independent estimator-calibration anchor) | raw (orientation-explicit) | [TR-4] §4 |
| Symmetry group (sequence level) | 48 (B₃ ≅ Z₂≀S₃) | **proven** (finite gates + classical closure) | — | [TR-5] |
| Symmetry group (record level) | 24 (S₄); free action | **proven** | orbit | [TR-5] |
| Twins per solution | 23 (orbit size 24) | **proven** | orbit | [TR-5] §4 |
| Orbit count \|C1∩C2∩C4∩C5\|/24 | 45,710,469,949,549,241,251,504,669,632,357,466,112 | **exact** (= N/24 of the two-instrument count above; the recomputed N is ≡ 0 mod 24, so the division is exact) | **record-level** orbit (S₄, order 24, free action at the canonical *pair-ordering* level; at the orientation-explicit **sequence** level the group is the order-48 lift and the divisor is 48 — [TR-5] §3(i)) | [TR-11] §9 |

*All three exact full-scale quantities — \|C1∩C2∩C4\| (via `--ie-no-budget`), the C5-layer count
\|C1∩C2∩C4∩C5\|, and its orbit count — are **two-instrument** as of 2026-07-25: independently
recomputed at full scale by `verify.c`'s inclusion–exclusion transfer-walk engine (`--ie-count`;
build: `cc -O2 -o verify verify.c -lz -lpthread -lm` — see [VERIFY.md](../documentation/VERIFY.md)
(⚠ `-lm` corrected 2026-08-21; without it the link fails on `sqrtl`)
— a different algorithm class sharing no code or machinery with `solve.c`; exact MATCH, mod-24
verified), additionally corroborated by the mod-24 gate and the 4/4 out-of-core ladder +
identical cross-mode layer content (byte-identical in the v1-format validation runs; under
current defaults the two modes' files are content-identical but byte-different — [TR-11]
§10(vi) precision note).*

## Environment (version pinning)
| Component | Version | Source |
|---|---|---|
| Repository | **pin to a commit sha** — content-addressed and immutable. *(Corrected 2026-08-07, CX-31: this row previously said "pin to the release tag stamped at publication (git tag per suite version)". No such per-suite-version tagging exists: 14 tags are present but only `reports-v1.0` (2026-07-03) is a suite version, while reports have since advanced to TR-2 v1.24, TR-3 v1.9 and beyond with no subsequent tag. Combined with the withdrawn DOI claim in [reports/README](README.md), the stated pinning policy had no executable mechanism at all — the sha is the one that always works.)* | [github.com/petersm3/roae](https://github.com/petersm3/roae) |
| C toolchain | gcc (Ubuntu 22.04 class), flags: `-O2 -pthread -fopenmp` (portable default). **The output sha is flag- and architecture-invariant on every recipe tested**, so the differing build lines a replicator meets across this repo are interchangeable: `-O2`, `-O3 -march=native`, `-O3 -march=x86-64-v3` and `-O3 -flto` all produce the same selftest sha `403f7202…`, and the 11.2T canonical is byte-identical between an x86 `-march=native` build and an ARM Neoverse-N2 `-mcpu=native` build. The published canonical recipe ([CANONICAL_HASHES.md](../documentation/CANONICAL_HASHES.md) §"Solver version") is therefore `-O3 … -march=native`; the reason to prefer a fixed `-march` baseline for a redistributed binary is SIGILL on older CPUs, **not** sha movement ([DEVELOPMENT.md](../documentation/DEVELOPMENT.md) §"Use `-march=x86-64-v3` for canonical builds"). Two witnesses, not an exhaustive guarantee over every compiler version and host. | — |
| solve.c selftest anchor | sha256 `403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e` | pre-push compile gate (git hooks, installed per clone — opt-in) + manual operator runs; not a commit-time gate |
| Python | 3.10+, **stdlib-only on every reproduction path in this report**: `roae.py` and `sat.py` import nothing outside the standard library; `solve.py` and `verify.py` are stdlib-only on their default, `--verify`, `--recount` and SAT-emission legs. *(Scoped 2026-09-02, prose lane: this row read "stdlib-only (solve.py, sat.py, roae.py, verify.py)", which is false of two files' optional modes — `solve.py`'s P2 population post-processing modes lazily import `numpy`/`pyarrow`, with `matplotlib` for `--bivariate` and `scikit-learn` for the joint-density / stratified modes, and `verify.py --check-t5-c3` lazily imports `numpy` + `pyarrow.parquet`. Every such import sits inside its handler, so no default path needs them — [DEVELOPMENT.md](../documentation/DEVELOPMENT.md) §Prerequisites lists the modes; the [SOLVE_PY_CLI.md](../documentation/SOLVE_PY_CLI.md) dependencies row is the per-feature attribution.)* | — |
| SAT solver | kissat 4.0.4 (build from source) | [github.com/arminbiere/kissat](https://github.com/arminbiere/kissat) |
| Proof checker | drat-trim ([Wetzler, Heule & Hunt 2014](../documentation/CITATIONS.md#drattrim2014)). **Unpinned** — built from the upstream master branch circa 2024; no commit hash was recorded at build time, so this row names a moving target, not a version (disclosure replacing the earlier "2024+ master" phrasing, which read as a pin; that open task is now CLOSED for verification runs from 2026-08-09 onward: the 2026-08-09 end-to-end `verify_all.sh` run — 60 passed / 0 failed / **0 skipped**, on a fresh clone of public HEAD `c1113a2` — used drat-trim at commit **`2e3b2dc0ecf938addbd779d42877b6ed69d9a985`** (committed 2024-11-25, consistent with the "circa 2024" above). **SCOPE, stated because the distinction is the whole point of this row:** that hash pins the checker used by *that verification run*. It does **not** retroactively identify the build that produced the archived certificates — no hash was recorded then, and that gap is not closeable after the fact. A replicator can therefore pin the *checking* step exactly, while the *production* step remains a moving target) | [github.com/marijnheule/drat-trim](https://github.com/marijnheule/drat-trim) |
| Lean | 4.31.0 via elan; core only (no mathlib) ([de Moura & Ullrich 2021](../documentation/CITATIONS.md#demoura-ullrich2021)) | `cd lean && lean KingWen.lean` exits 0 — run from INSIDE `lean/`: elan picks the toolchain from the working directory upward, so only there does `lean/lean-toolchain` (4.31.0) apply; from the repo root it silently uses whatever `elan default` is (measured 2026-09-03 with a planted 4.30.0 default). `reports/certificates/verify_all.sh` §4 now runs from `lean/` and records the kernel it used as a whole-line `LEAN_ID=` token |

## Data-like vs principled constraints (the circularity firewall) — F-23

Several conclusions in this suite turn on whether a constraint is **principled** (stated independently of
King Wen, so King Wen's compliance is evidence) or **data-like** (a specific configuration read off King
Wen, so its compliance is near-tautological and carries little evidential weight). The distinction has
been applied case-by-case; the operational test it encodes is:

> A constraint is **data-like** if its statement fixes a specific configuration extracted from the
> received order — i.e. it can be written as "positions/values match King Wen's" with **≥1 fitted
> degree of freedom read from KW** and no independent derivation. It is **principled** if it is stated as
> a general rule (an author's design principle, a symmetry, an optimality criterion) whose form does not
> reference King Wen's particular values, so that a different valid ordering could have failed it.

Operationally: count the degrees of freedom the constraint's **stated form** borrows from King Wen —
*not* the KW-level at which a measurement functional happens to be thresholded. (A principled rule such as
Schulz gender is measured against KW's own violation count, but its *statement* — a parity condition on
consolidated units — borrows no KW-specific value; it stays principled. The dof count is on the rule as
its author stated it.) Zero borrowed dof in the statement → principled; each fitted slot, value, or
threshold baked into the rule's definition is one borrowed dof, and a constraint with ≥1 is priced as data (its "rarity" is specification, not discovery — see the dof-matched baseline in
[TR-8](TR8_REORDERING_REVISITED.md) §Executive summary). *(Corrected 2026-08-01: this pointer also named
"CRITIQUE.md Q1". CRITIQUE.md has no Q1 and no dof-matched material; the baseline is stated only in TR-8,
which quantifies it but does not publish a regeneration command for it — treat the ~6×10⁻⁵ median as an
unreproduced figure until one is published.)* *(Escalated 2026-08-07 —
[CORRECTIONS](../documentation/CORRECTIONS.md) CX-27: the median is now **withdrawn pending
artifact**, not merely flagged — TR-8 v1.14 marks it not to be cited or relied on until the sampler
exists; the qualitative specification-not-discovery direction stands on this firewall itself, not on
that number.)* Borderline cases
(C3's 776 threshold, the S25–28 trigram configuration) are classified data-like precisely because their
defining number or face-set is KW's own. This is the firewall that keeps a fitted description from being
reported as a design finding; where a result depends on the classification, the report states which side
the constraint falls on and why.

**When the author's statement cannot be used (added 2026-08-02).** "The dof count is on the rule as its
author stated it" presumes the author's statement is both *available* and *about orderings*. Two cases
break that presumption, and the rule above had no provision for either. The resolution, in both, is that
**the classification attaches to the predicate this suite actually measures** — the code in `solve.py`,
which is what produced every published figure — with the divergence disclosed:

- **(a) Statement unavailable.** If the source is unobtainable, or is available only as a secondary
  summary that does not fix the predicate's dof, classify the *implemented* predicate and label the
  classification **implementation-scoped**: it is a verdict about what we measured, not a reading of what
  the author claimed. Never leave the row unclassified — an unclassified load-bearing constraint defaults,
  in practice, to being read as principled.
- **(b) Statement available but not an ordering constraint.** An author's claim may be about hexagram
  *bit-patterns* (a classification, an identity) rather than about *positions*. Such a claim is constant on
  every ordering: its population mass is 1 by inspection, it cannot discriminate, and it is not the thing
  a rarity figure describes. If the suite has turned such a claim into an ordering predicate, that
  predicate is **the suite's own formalization**, it is classified on its own borrowed dof, and the
  attribution must be split — the author is credited for what they stated, not for the predicate.

`d7` is the worked example of (b), and the first row classified under this provision: see
[TR-1](TR1_EIGHT_CENTURIES_MEASURED.md) §3 headline 3.

## Statistics conventions
- **Knuth estimator CIs**: for the ESTIMATOR TOTALS the per-probe weight X and X² are accumulated in
  IEEE-754 double precision, and the tool prints mean ± 1.96·√(v̂ar/N) with relerr = SE/mean — a
  standard Wald CI on Knuth's (1975) unbiased estimator. ⚠ **[SCOPE CORRECTED 2026-08-28 — this read "for each reported quantity", which is
  false. Exactly three accumulators keep a second moment (`sumsq`, `sumsq_leaf`, `sumsq_node`); the
  score-mode accumulators behind published figures — `score_dav`, `score_perm`, `score_registry`, which
  carry TR-10's Davis masses among others — keep **none**, and there is zero co-occurrence between the
  two sets in `solve.c`. Those quantities are printed as bare point estimates with no CI, and the
  sentence claimed otherwise for every one of them. Found by the effort-none Codex run (T07 + T10,
  convergent) during the Q-332 triage and verified here against the source. **Note for whoever lands
  Q-325:** that row's drafted fix corrects only "exactly" (double-precision rounding) and "i.i.d." — it
  leaves "for each reported quantity" intact and would have shipped a still-false sentence.]**
  **[CURED IN CODE 2026-08-28, same day (Q-374):** squared-weight twin accumulators and delta-method
  SEs were added for every published mass family — `score_dav`, `score_dav2`, `score_f4p`, `score_f5`,
  `score_f6`, `score_perm`, `score_db1`, `score_registry`, the `[score]` scalar masses and the
  wrap-distance masses — and each mass line now prints `se=` (ratio-estimator delta method:
  Var(m) ≈ [ΣW²I·(1−2m) + m²·ΣW²]/(ΣW)², exact for 0/1 indicators). Validated 2026-09-02 against 12
  independent-seed replicates at 10⁷ probes — `SOLVE_KNUTH_SEED` = 1, 2, …, 12 at `SOLVE_THREADS=2`,
  archived with the run script, the ratio script and a README under `evidence/q374_se_replicates/`
  (reproduce: `ulimit -s unlimited; bash reports/evidence/q374_se_replicates/run_replicates.sh`, then
  `python3 reports/evidence/q374_se_replicates/analyze.py reports/evidence/q374_se_replicates`).
  Printed SE ÷ replicate SD for the seven non-degenerate `at=` masses: 0.75 / 0.92 / 0.91 / 1.02 /
  0.69 / 1.56 / 1.44 (termruns / compmirror / trigarray / palnbr / rotinv / pureplace / asymhalf) —
  six of seven inside the 12-replicate chi-square 95% band [0.71, 1.70]; `leaves_canonical` 1.38, in-band.
  The exception, `rotinv`, averages ≈1 hit per replicate (2 of 12 replicates hit nothing and print
  `se=0`), and the two rarer tails (`compmirror`/`trigarray` `above=`, ≤3 hitting replicates of 12)
  print SE ÷ SD ≈ 0.29: **the delta-method SE is validated where a mass has hits and understates in
  the zero/single-hit regime** — the zero-hit/starvation caveat below, made quantitative. *(An earlier
  12-replicate validation, 2026-08-28, reported ratios 0.73–1.45 but recorded neither its seeds nor its
  outputs; it is withdrawn as unreproducible and superseded by the archived run above.)* Per-bin histogram rows (`dav_hist` etc.) remain point estimates. Archived
  evidence files from earlier runs (e.g. `dav_tier1.out`, 2026-07-04) predate the field and carry
  no `se=`; the masses themselves are unchanged (same-seed emissions byte-identical).]** Weighted fractions (masses of canonical weight) are
  same-run ratios ΣWX/ΣW; for fractions ≪ 1 the delta-method variance reduces exactly to the numerator's
  own relative variance, so a fraction's honest relerr equals the relerr of its numerator. *That is a
  statement about **variance only**.* ΣWX/ΣW is a ratio of correlated random sums, so it also carries a
  **bias** of order 1/n_eff that this suite does not quantify; at the deep-tail rows (n_eff of order 10²,
  see just below) that is percent-scale. No published verdict turns on a few percent, but the population
  fractions should not be read as bias-corrected. S(k)-style
  ratios of separate runs add relative variances (the whole-space denominator's 0.02% is negligible).
  Caveats: weights are right-skewed, so CIs at low effective sample size (n_eff = 1/relerr²; e.g. relerr
  10% → n_eff ≈ 100) are approximate and skew toward underestimation — figures at ≥10% relerr should be
  read as ±20% with ~90–93% practical coverage; zero-hit estimates print 0 with a degenerate CI and are
  reported as starvation, not as bounds. **That is a reports-side convention applied by hand; the
  estimator's own output does not mark it** (measured 2026-08-30 against `solve.c`'s print sites). A
  starved fiber layer prints, verbatim, `records_C1C2C4C5 : est=0.000000e+00  95%CI=[0.0000e+00,
  0.0000e+00]  relerr=0.00%` — a zero-width interval labelled 95%, whose coverage is zero — and the
  fiber `records_*` lines carry no `hitrate=` or `hits=` field at any probe count (the `leaves` and
  `[score]` lines do), so on those lines starvation is not machine-distinguishable from a measurement
  except by the `est=0` itself. A reader of raw console output has to apply this convention
  themselves. The change that would turn this sentence into a checkable behaviour rather than a
  convention — an explicit `STARVATION` token on the line with the CI suppressed — is registered and
  is **not in the binary**: no such token exists in `solve.c` today. This note is to be replaced by
  the enforced wording when it does. PRNG seeds are fixed constants: re-runs at identical (probes,
  threads) reproduce identical output (a reproducibility feature; runs at the same thread count and
  different probe counts share stream prefixes and are not independent draws). *This rule is restated
  under its own heading — §"Reproducibility rule for estimator output" below — which is the anchor to
  cite; it lived only inside this bullet until 2026-09-02.* CIs degrade visibly at hit
  rates below ~10⁻⁷ per probe; every reported number states its probe count.
- **Estimator arithmetic and randomness — what "accumulated" and "random probe" mean here.** This
  section used to assert two idealizations flatly ("accumulated exactly", i.i.d. probes); both are
  now stated with their bounds. Raised by Codex A06 (tracked as Q-325); the code facts and the two
  bounds below were re-derived from `solve.c` for this entry rather than carried over from the review.
  **(i) The accumulation is `double`, not exact.** The moment accumulators are plain C `double`
  (`sum_leaf, sumsq_leaf, sum_c3, sumsq_c3, sum_node, sumsq_node`, declared together in the per-thread
  worker struct and updated as `a->sum_leaf += leaf; a->sumsq_leaf += leaf*leaf;`), one struct per
  thread, reduced once at the end. Naive sequential summation of non-negative terms has a worst-case
  relative error of at most n·u, with u = 2⁻⁵³ ≈ 1.11×10⁻¹⁶ and n the number of additions into one
  accumulator. For the headline whole-tree run (5×10¹⁰ probes over 32 threads — n ≈ 1.5625×10⁹ per
  accumulator, plus a 32-term final reduction) that bound is **≤ 1.8×10⁻⁷**, about three decades below
  the same run's 0.02% relative standard error and so below every published digit. It is a *bound*,
  not a measurement: no compensated-summation replay has been run against the production stream.
  **(ii) The probes are a deterministic stream, not i.i.d. draws.** A probe descends by choosing among
  the d admissible children with `ks_next(&rng) % (uint64_t)d` — xorshift64 (shifts 13/7/17) reduced by
  modulo. Taking the 64-bit word as uniform, each residue's probability differs from 1/d by less than
  2⁻⁶⁴, a *relative* bias under d/2⁶⁴; d ≤ 64 here (32 pairs × 2 orientations bounds both the child
  loop and the child array), so the bias is **≤ 3.5×10⁻¹⁸**. A third departure is *not* quantified
  in-tree: xorshift64's own equidistribution (its cycle is 2⁶⁴−1 long and it never emits 0), for which
  this suite has run no test-battery. Independence across probes is likewise a model idealization of a
  seeded deterministic stream; its concrete consequence — runs at the same thread count but different
  probe counts share stream prefixes and are not independent draws — is stated in the bullet above and
  under §"Reproducibility rule for estimator output" below. Both bounded effects are numerically
  immaterial at every probe count this suite publishes; they are recorded because a statistics
  contract that says "exactly" about floating-point arithmetic is the same wording class this suite
  polices in its results.
- **Permutation-test nulls**: seeded (`random.Random(42)` unless stated); N=10,000 default; the
  pair-preserving null = shuffle the 32 canonical pairs + independent uniform orientation flips, first
  pair fixed by C4 where stated.
- **Population fractions** are ratios of weighted canonical-leaf masses (orientation-resolved unless
  marked canonical); every scorer's rule semantics has a KW-value reproduction gate
  (`solve.py --registry-verify`) run before any measurement is trusted.
- **Global observable ledger (enterprise-wide multiple comparisons).** Bonferroni corrections in this
  suite are applied within each pre-registered family (F5 /11, F4′ /13, Davis /9, Davis follow-up /12,
  permutation /13). Family-wise control does not control the error rate of the whole enterprise. The
  enterprise-wide observable count is **frozen at exactly 91**: the 28 exploratory discovery-phase
  observables (roae.py sweep) + the five pre-registered testing families (F5 /11, F4′ /13, Davis /9,
  Davis follow-up /12, permutation /13 = 58) + the R7 corpus-control battery's five off-home predicates
  = 28 + 58 + 5 = **91** (itemization maintained in [CRITIQUE.md](../documentation/CRITIQUE.md)
  §"Observable-selection accounting"). The exploratory suite **is included** — it is the base of the
  count, not excluded. A per-family "notable" label is therefore a family-scoped claim; against the
  global ledger the corresponding bar is 0.05/91 ≈ **5.5×10⁻⁴**.
  **Scope disclosure (added 2026-08-01, after an itemised roster was built from the frozen
  pre-registrations).** The 91 counts *tests performed under registered corrections*, not distinct
  observables, and it is **deliberately retained as the conservative choice**. Two offsetting facts:
  (i) the "Davis /9" and "Davis follow-up /12" components are **not disjoint** — the R8 pre-registration
  freezes the /12 as "the full cross-wave Davis family (9 wave-1 + 3 wave-2 maximum)", so the nine are
  re-counted inside the twelve, and the distinct Davis contribution is 12, giving **82 distinct
  observables**; (ii) the ledger omits the **F6 books family** (7 functionals, frozen and measured
  2026-07-05), so a strict "everything examined" reading gives **89**. The two errors nearly cancel.
  **(iii) Added 2026-08-30 — a third omission, and unlike (i) and (ii) it does not cancel.** The
  ledger also omits the pre-registered **H1/H3 family**: four predicates T1–T4, shipped as
  `roae.py --prereg-h1h3`, spec frozen 2026-07-26 and escrowed as `PREREG_H1_H3_TEST_2026_07_26.md`
  in [PREREGISTRATION_ESCROW.md](../documentation/PREREGISTRATION_ESCROW.md). A grep for `H1/H3`
  returns **zero** hits in this file and zero in `CRITIQUE.md` §"Observable-selection accounting",
  the itemization of record — so a shipped, pre-registered, escrowed family has no roster ids at all.
  That is what the counting rule below forbids: an observable enters the ledger at **first
  registration**, not on its outcome, precisely so that roster membership cannot be conditioned on
  how a test came out (T1–T4's own pre-registered prediction is that all four fail, which is not a
  reason to leave them out). Entering them gives **95** on the published convention, **93** on the
  distinct-"everything examined" reading of (ii). Whether any of the four re-register an earlier F4′
  id — arguable for the A-functional — is unestablished; if they do, the roster must say so in place
  under the exactly-once rule rather than omit them. **This correction moves the bar DOWN, so 91 is
  not the conservative choice on this axis**, unlike (i) and (ii): 0.05/95 = 5.26×10⁻⁴, below the
  5.49–6.10×10⁻⁴ span the sentence below studies. **The published 91 is retained here as a
  disclosure, not as a defence.** Re-freezing the total is a corpus-wide edit — the figure and its
  0.05/91 bar appear across eleven tracked markdown files, including `CRITIQUE.md`, which holds the
  itemization of record — and is deliberately not made piecemeal in this file. What would settle it:
  rebuild the stable-id roster with T1–T4 entered, re-derive the total *from* the roster per the
  counting rule, and re-check every published verdict against the corrected bar.
  **All three candidate bars — 0.05/91 = 5.49×10⁻⁴, 0.05/89 = 5.62×10⁻⁴, 0.05/82 = 6.10×10⁻⁴ — span
  under 11%, and NO published verdict differs between them** (the only value in the gap zone,
  `dav_trigarray` at 6.8×10⁻⁴, fails at all three). The published bar is therefore the strictest
  defensible choice **among those three**, and no conclusion in the suite depends on the count as
  between them. *(Extended 2026-08-30 for (iii) above. The corrected bars are 0.05/95 = 5.26×10⁻⁴
  and 0.05/93 = 5.38×10⁻⁴, and both lie **below** the studied span — so the no-flip statement in this
  paragraph, established over 5.49–6.10×10⁻⁴, does not cover them. `dav_trigarray` still fails at
  every candidate bar, and no published verdict has been **shown** to fall in the newly exposed
  interval (5.26, 5.49)×10⁻⁴ — but showing that none does requires the roster rebuild named in (iii)
  and has not been done. Stated in the honest direction: the exposure interval is real and, so far as
  anything here establishes, unoccupied.)*
  **Correction-family disclosure (added 2026-08-01, self-reported).** The sentence above is scoped to
  the three *denominators*; it says nothing about the choice of *correction family*, and that choice is
  not neutral. The suite applies **Bonferroni (family-wise error rate)** throughout, and the global-ledger
  layer was added on 2026-07-11 — **after** the measurements it adjudicates. Under **Benjamini–Hochberg
  FDR** ([Benjamini & Hochberg 1995](../documentation/CITATIONS.md#benjamini-hochberg1995)) at q = 0.05
  the same 91-observable ledger would reach a different verdict on exactly one value:
  `dav_trigarray` (6.8×10⁻⁴) would be **declared significant**. BH rejects at **every** rank *i* ≥ 2,
  since even *i* = 2 gives 2·0.05/91 = 1.1×10⁻³ > 6.8×10⁻⁴; only *i* = 1 would fail. And *i* = 1 is
  excluded by `dav_rotinv` (6.5×10⁻⁵) — a smaller p-value inside the same registered Davis family — so
  *i* ≥ 2 and the rejection stands.
  ⚠ **[SIDEDNESS STATED 2026-09-03 — every p-value in this paragraph is the ONE-SIDED mass, and it did
  not say so. TR-10 publishes `trigarray` as **two-sided 1.36×10⁻³** and freezes its own thresholds
  two-sided, so the two conventions sit unmarked in the same argument. The rank arithmetic is not
  invariant to the swap: one-sided 6.8×10⁻⁴ rejects at *i* ≥ 2 (2·0.05/91 = 1.099×10⁻³), but two-sided
  1.36×10⁻³ needs *i* ≥ 3 (3·0.05/91 = 1.648×10⁻³). **At *i* ≥ 3 this paragraph's support is
  incomplete**: it excludes *i* = 1 by exhibiting one strictly smaller value (`dav_rotinv`, two-sided
  1.31×10⁻⁴), and *i* ≥ 3 requires a **second**, which is not exhibited here. So the FDR counterfactual
  is sidedness-dependent and, two-sided, is not established by the argument as written.
  **No published verdict moves.** The suite applies Bonferroni throughout and retains the FWER reading
  as the conservative choice; `dav_trigarray` fails the Bonferroni bar on either mass. This is a
  disclosure that the counterfactual is narrower than it reads, not a retraction of anything claimed.]**
  *(Ranking support narrowed 2026-08-01, second pass. This paragraph previously supported the rank with
  "at least twelve ledger values are strictly smaller … so its BH rank is i ≥ 13 … about 10× the measured
  p", listing nine `ccn*`/`rs1`/`d4`/`d7`/`p2c6`/`c2011n*` values plus three Davis entries. **Both extra
  categories were wrong to rank.** (a) The nine are literature-rule **registry masses** from
  `solve.py --registry-verify` (published in [TR-1](TR1_EIGHT_CENTURIES_MEASURED.md) §7); they are not in
  the 91-observable roster — the itemization of record, `CRITIQUE.md` §"Observable-selection accounting",
  contains none of them — and they are not test p-values: TR-1 states each is read at King Wen's own value
  "by construction of the threshold forms". Calling them "ledger values" is exactly the error the counting
  rule below exists to prevent: a value counts as being in the ledger only by appearing in the itemised roster. (b) Two of the three Davis entries have **zero
  sampled mass**, which §"Knuth estimator CIs" above reports as starvation, not as a bound — a
  non-number cannot hold a BH rank. What survives is `dav_rotinv` alone — [TR-10](TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md)
  §3 row 6 classifies it *data-like* and does not promote it, but it is a registered member of the Davis
  family carrying a measured p-value, which is what a BH ranking needs — enough for the
  conclusion, not enough for the withdrawn "≈10×" margin. Net effect on the disclosure: none — it is
  self-penalizing, and the narrower base still reaches the same verdict.)*
  **What the preceding sentence claims — and what it does not (scope split added 2026-08-02).** That
  is the *only* verdict in the suite the family choice moves, and it moves the one result most favourable
  to the hypothesis this suite argues against. **That is a statement about *verdicts*, not about
  *margins*.** The reported **margin** — the factor by which a p-value clears or misses its bar — is
  correction-specific and *does* move with the family, by an order of magnitude, with no verdict changing.
  The reason is structural, not incidental: Bonferroni supplies a single **rank-free** bar (0.05/91 ≈
  5.5×10⁻⁴) that any value can be read against, whereas BH supplies a **rank-dependent** bar *i*·0.05/91,
  so the same value's BH margin is exactly *i* times its Bonferroni margin — 2× to 91× larger depending
  on where it ranks. Worked pair (the one place in the suite a global-bar margin is published as a
  number, [TR-8](TR8_REORDERING_REVISITED.md) §Executive summary): a per-rule rarity of 1.054×10⁻⁴ clears
  the global bar by **~5×** under Bonferroni and by **≥~10×** under BH at q = 0.05 — the BH figure is a
  floor, not a point, because only *i* ≥ 2 is supported (forced by `dav_rotinv` at 6.5×10⁻⁵ being strictly
  smaller and inside the roster). A **~52×** figure for that same rarity circulated in draft; it is BH at
  rank *i* = 10, which requires nine strictly-smaller values, and the only nine available are the registry
  masses the narrowing above **withdrew from ranking** — so ~52× is not publishable on this ledger and TR-8
  does not carry it. The asymmetry runs deeper than size: that TR-8 rarity is itself a literature-rule
  registry mass, the same class the narrowing excludes, so it may hold **no BH rank at all** — its
  Bonferroni margin is well-defined (a rank-free bar applies to any value) while its BH margin is
  conditional on roster membership. FWER margins are therefore the firmer quantity as well as the
  smaller one, which is a second reason this suite publishes them. Two consequences for readers: **every margin published in this suite is a Bonferroni
  margin unless it says otherwise**, and a margin quoted without naming its family is under-specified even
  where the verdict is not. The two families thus disagree by an order of magnitude on *how far* King
  Wen's rarity sits from the global bar while agreeing on *every* published verdict but one — both halves
  are reported here because reporting only the family that flatters a given number is what makes a
  correction record dishonest. Two facts keep the published reading defensible, and both
  are stated rather than assumed: (i) FWER is the strictly more conservative family, so **every claim
  that the suite reports as *clearing* the bar clears it under BH as well** — nothing in the positive
  direction depends on this; (ii) the exposure is entirely in the negative direction, on one Davis
  observable, and it is disclosed here rather than left for a reader to discover. A reader who prefers
  FDR control should read `dav_trigarray` as surviving global correction and everything else unchanged.
  **Counting rule going forward:** an observable enters the ledger exactly once, at first registration,
  under a stable id; a family's Bonferroni denominator may span waves and exceed its new-id count; and
  this total must be **derived from the itemised roster**, never stated independently of it; and each
  "notable" verdict states in place whether it clears that bar. Model comparisons (the TR-2 Bayes factors) are **not** observables
  and do not enter this ledger. This accounting does not touch the suite's headline findings — the
  nulls, and the proven/certified impossibilities, which are deductive.

### Reproducibility rule for estimator output

*(Heading added 2026-09-02, prose lane. The rule itself is unchanged; until today it was stated only
inside the "Knuth estimator CIs" bullet above, so every citation of it resolved through a bold label
rather than a section.)* The Knuth estimator's PRNG seeds are fixed constants and the thread count
selects the sample, so **a re-run reproduces a published estimator output only at the identical
(probes, threads) pair**. Consequences: every reproduction command for a sampled figure must carry its
thread count (`SOLVE_THREADS=N`) as well as its probe count; runs at the same thread count and different
probe counts share stream prefixes and are **not** independent draws; and a reader on a host with a
different core count who omits the pin reproduces a *different* draw, not the published one. Exact-mode
commands (`--estimate-knuth 0`, the orbit-quotient DP, `--verify`) are deterministic and need no pin.

## Artifact access
- **Certificates (DRAT) and raw run outputs** ship publicly with the suite under `reports/certificates/`
  and `reports/evidence/` at publication (relocated from private staging — the verification story
  requires them public). Each cert pairs with the exact `sat.py --emit-cnf <target>` regeneration
  command; encodings are deterministic, so regenerated CNF + archived proof must check.
- **solutions.bin artifacts** are not distributed (size); they are re-derivable to the byte
  ([CANONICAL_HASHES.md](../documentation/CANONICAL_HASHES.md) per-anchor commands) and their shas are the scientific anchor.

## Independence ladder (what requires trusting project code)
1. **Nothing**: DRAT certificates (drat-trim), **kernel-checked** Lean theorems, the two-line parity proofs.
   *(Scope, added 2026-08-01: a DRAT certificate places its **verdict** here — what the CNF **means** is rung 2. See the note under rung 2; do not read "DRAT-certified" as assumption-free end to end.)*
   *(Qualified 2026-08-01: this read "Lean theorems (kernel)" without restriction. A disclosed subset of the
   suite's Lean theorems is proved by `native_decide`, which trusts Lean's **compiler** rather than its kernel —
   TrigramTheorems §4a–§6, PartitionInvariance §12, PruneGInvariance §1+§8, and all of SymmetryCompleteness.
   Those belong one rung lower in spirit: they require trusting no project code, but they are not kernel-checked.
   The per-file inventory is in [lean/README.md](../lean/README.md) §Trust base; this was the one place in the
   suite where a distinction maintained everywhere else was flattened.)*
   *(Resolved 2026-08-07: the 2026-08-01 qualification above is now empty of members. The `native_decide` →
   kernel migration completed in three tranches — 2026-07-27/31, then PartitionInvariance §12 +
   PruneGInvariance on 2026-08-07, then TrigramTheorems + SymmetryCompleteness later the same day — and the
   Lean corpus carries **zero** `native_decide`; a module-wide axiom scan over every non-internal constant of
   all twelve compiled modules observed zero compiler-trust axioms ([lean/README.md](../lean/README.md)
   §Trust base, "RE-EXECUTED" note). "Kernel-checked Lean theorems" on this rung now means all of them.)*
2. **Only the encoder** (validated by KW-value gates + two-way SAT tests): the conflict theorem's rule
   faithfulness.
   *(Added 2026-08-01: the conflict theorem is the **same object** as one of rung 1's DRAT certificates, and
   it belongs on both rungs by design — drat-trim's UNSAT verdict on the CNF requires trusting no project
   code (rung 1), while the claim that those clauses **are** Moore's/Schulz's/CC-N4's/CC-N8's rules requires
   trusting `sat.py` (rung 2). Every certificate-backed impossibility in this suite splits the same way, so
   "DRAT-certified" should never be read as "assumption-free end to end".)*
3. **The instrument stack** (cross-validated two-language + self-check): population fractions, estimator
   counts.
Every report's Verification Guide tags its claims with the rung they sit on.

### Authorship independence — who checked, as distinct from what was checked

The ladder above ranks what a reader must trust about project **code**. A separate axis ranks who
wrote the check, and on that axis the suite's position needs stating plainly: **algorithmic
independence is not authorship independence.** The same author wrote the claims, the software that
tests them, and the reports that grade the outcome. From weakest to strongest:

1. **Same author, same implementation** — a program checking itself (`--selftest`, the regression
   harness). Establishes internal consistency and catches regressions; establishes nothing against a
   defect present at design time, which the check inherits.
2. **Same author, second implementation** (different language or different algorithm) — the
   solve.py-vs-solve.c two-language gates, verify.py/verify.c, TR-11's two-instrument exact count.
   Strong against implementation bugs: two code paths rarely fail identically. Weak against the
   failure mode that matters most for this suite's claims — a shared misreading of a cited source, a
   mis-modelled constraint, a wrong formalization — because both implementations came from one
   author's understanding and agree wherever that understanding is wrong. (TR-11 §10(vi) says this
   about the exact count: the independence is algorithmic, not specificational.)
3. **Same author's statement, externally authored checker** — the Lean-kernel-checked theorems and
   the drat-trim-verified DRAT certificates. The *derivation* is checked by a tool this project did
   not write, so the mathematics is as strong as machine-checking makes it. What stays same-author
   is the statement: whether the Lean proposition or the CNF means what the prose says it means
   (rung 2 of the code-trust ladder above — the encoder caveat — is exactly this gap).
4. **Different author** — a party outside the project re-deriving results from the written
   specifications, or auditing the modelling and the reports, without relying on this project's code
   or on its author's understanding. **Nothing in this suite is on this rung.** The review passes
   recorded in the revision histories — "hostile review", "adversarial review", "independent
   review" — were commissioned by the project and carried out by AI models working under its
   direction; they sharpen the checks on the lower rungs and are not third-party scrutiny. Wherever
   this suite says "independent", read it as a claim on rungs 2–3, never on rung 4.

**What to discount, and what not to.** The rung-3 mathematics — the kernel-checked theorems, the
certified impossibilities — does not weaken under this disclosure: those derivations hold or fail
regardless of who submitted them to the checker. The claims a reader should hold to a same-author
discount are the ones the report banners already mark "argued, not verified": that a formalized rule
is faithful to the literature it cites, that a constraint was extracted fairly rather than read off
the answer, that a null was graded honestly, and that each report's framing of its own results is
fair. None of those has yet had an examiner who did not also write them. Everything a rung-4 examiner
needs is public — [REBUILD_FROM_SPEC](../documentation/REBUILD_FROM_SPEC.md),
[SPECIFICATION](../documentation/SPECIFICATION.md),
[CANONICAL_HASHES](../documentation/CANONICAL_HASHES.md), and the certificates under
`reports/certificates/` — and such an examination would move the suite up this ladder; until one
happens, this section is the ceiling on what "verified" can mean here.

**The review record, including what was rejected.** Naming a mechanism is not the same as showing
its output, so the record is public and auditable rather than summarised: every accepted correction
is an entry in [CORRECTIONS](../documentation/CORRECTIONS.md), every withdrawn phrasing is a row in
[RETRACTED_PHRASES](../documentation/RETRACTED_PHRASES.tsv) that a gate then blocks from recurring,
and each report's revision table dates its own changes. **Findings were also rejected**, and those
are recorded too — a proposed ~52× look-elsewhere factor for TR-8 was examined and *declined*
because the evidence supports only a floor of ≥~10×, and that decision is written down rather than
quietly dropped. Rejections are the part of a review record that is easy to omit and hardest to
reconstruct later; a reader who wants to audit the grading should start there.

**The file drawer — an open gap, stated as such.** For an argument of this shape ("the received
ordering is atypical"), the denominator matters: how many constraint families were tested and set
aside before the published set was fixed? **This suite does not currently publish that denominator.**
Some constraints are inherited from the literature and so are not ours to have selected; others were
formalized here, and the full ledger of what was tried and dropped has not been assembled. Until it
is, the multiple-comparisons correction a sceptical reader would want cannot be computed from
published material, and no p-value here should be read as if it had been. *(Scope pointer, added
2026-08-07 — two quantities, stated as two.)* This admission concerns the **discovery-phase**
denominator: what was tried and set aside before the published constraint set was fixed. It is a
different quantity from the **testing-phase** ledger of §"Global observable ledger" above (the
frozen 91, with its 89/82 candidate variants), which *was* independently itemised from the frozen
pre-registrations and validated — no published verdict differs across its three candidate bars.
Reconstructing that testing ledger does not close this gap, and nothing in this paragraph is
weakened by it: the discovery-phase denominator remains unassembled and open.

**Pre-registration, honestly scoped.** Where a test could have been graded after the fact, the
design was frozen first and published: see [evidence/f11/PREREGISTRATION](evidence/f11/PREREGISTRATION.md)
for the model forms, the 50:50 prior and the Jeffreys bands ([Jeffreys 1961](../documentation/CITATIONS.md#jeffreys1961);
[Kass & Raftery 1995](../documentation/CITATIONS.md#kass-raftery1995) — the frozen bands are a project
convention matching neither published table; see the band-provenance note in
[TR-2](TR2_THE_RULES_CONFLICT.md) §"Pre-registration discipline"), all fixed before the numbers existed.
The practice has teeth — a pre-registered confusability gate on the four-class comparison **failed**,
and §6.3 of that design permanently withholds the result rather than reporting it; a second gate on
the two-model pair also failed and is recorded in [CORRECTIONS](../documentation/CORRECTIONS.md)
CX-25. **The scope limit is real and should be stated plainly: pre-registration governs the recent
model-comparison work, not the suite retrospectively.** Earlier results were not pre-registered, and
nothing here converts them.
