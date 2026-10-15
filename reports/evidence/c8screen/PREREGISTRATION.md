# PRE-REGISTRATION — Pilot A, the systematic C8 screen: a declared and counted family of label-free slot/adjacency statistics against the C1–C5 population — **DRAFTED 2026-10-11, TO BE FROZEN BEFORE ANY MEASUREMENT**

> # 🔒 FREEZE LINE — nothing below §9 may be edited after the lock; NO VALUE OF ANY FAMILY MEMBER ON KING WEN EXISTS AT FREEZE
>
> **Gate P1 of `TASK_GATED_PILOT_A_C8_SCREEN.md`** (operator 2026-10-11: "yes, queue pilot a"). This document is a
> **registration**, not a draft: the orchestrator commits it and `scripts/prereg_c8screen_defcheck.py` to `roae-private`
> and appends both digests to `docs/data/PREREG_LOCK_LEDGER.txt` (gate P2) **before** the measurement lane is briefed.
> As with every ROAE pre-registration in a private repository, freeze timing is **attested, not checkable by an outside
> reader** (`PREREG_CLASSA_QUERY_SET.md` §0 states the limit; it applies here).
>
> **What has and has not been computed at freeze (Fable 5.1, `claude-fable-5-1`, this session):**
> - **No member of the family has been evaluated on King Wen.** The defcheck imports `verify.py` for `_zong/_cuo` only;
>   its self-grep (`KW_TOUCHED=NO`) asserts that neither `verify.KW` nor `solve.binary_hexagrams` is named anywhere else in
>   it. The only King Wen numbers quoted in this file are already public (SPECIFICATION.md's C4/C5/C6/C7 values and the
>   Q-992 / Q-OY1 results of `review_2026_09_27/QOY1_Q992_MEASUREMENT_2026_10_09.md`), and they enter only as
>   **exclusions** (§3), never as inputs to a member.
> - **No null distribution has been computed, no percentile exists, no estimator run was launched, no scorer implemented.**
>   The defcheck's random orderings (seed `20261011`, start `(63, 0)`) are synthetic N0-type draws used to verify ranges,
>   forcing theorems and definition equivalences — properties of the hexagram set and of random orderings, not of KW's order.
> - **Seeds** (§6) were derived from frozen strings by SHA-256; deriving a seed is a commitment, not a measurement.
>
> **Amendment rule.** Amendable only by **dated annotation appended in §9**; never by editing the text above §9. The frozen
> bytes are identified by the sha256 recorded at commit (§10).
>
> **This document authorises no compute by itself.** It freezes the science; §7 fixes what the measurement lane runs and
> what it must output. [cost sentence omitted from the public copy]

**Drafted** 2026-10-11 by Claude Fable 5.1 (`claude-fable-5-1`), the project's Fable lane, on the template of
`review_2026_09_27/PREREG_QOY1_Q992_2026_10_09.md` (frozen digest `5e15192f…`, ledger line 2) with its §5.1 two-sided and
§5.2 candidate-gate conventions, and with the one design correction that run exposed (validation bands sized from the
printed SE, `ASSESSMENT_2026_10_09.md` §b). Design notes and open operator questions: `review_2026_09_27/PILOT_A_PREREG_NOTES.md`.

---

## §0 What this is, in one paragraph

Every literature pattern the project has operationalised so far sits at the mode of its null (`WORKSTATION_FUTURE_ASSESSMENT_2026_10_11.md`
§1.2). Rather than another one-at-a-time literature lead, this file declares **one family of 1,349 label-free statistics of the
pair-slot sequence** — boundary and entry membership counts under **all 651 order-16 XOR subgroups** of (ℤ/2)⁶, the eight
trigram relations across the 31 slot boundaries, the positional structure of the difference wave, of the yang-count walk and of
the pair yang-sum classes, and the positions of each trigram's and of the pure hexagrams' slots — **counts the family before
anything is measured**, fixes a family-wise two-sided correction at α = 0.01, the same three null populations as the Q-OY1/Q-992
run, the estimator and its sample sizes (justified against the printed standard error of the 2026-10-09 run), and mechanical
verdict rules. A **SURVIVOR** goes to an exact instrument and a circularity audit before anyone writes "candidate"; **no survivor
publishes the null and closes the C8 route for this class** (the pre-declared stop rule, TASK_GATED_PILOT_A_C8_SCREEN.md).
"Flat is a result": every outcome is written up.

**The question, verbatim (gate P1):** does any label-free single-slot or adjacency statistic, from a family declared and
counted in advance, distinguish King Wen after a multiplicity correction?

## §1 Pinned references — digests measured at drafting

Public repo `/home/claude/github/roae/roae` at `main` = `9967ec14c364cf10d2b5010a3cfc5c792a0dbb66` (working tree clean);
`roae-private` at `6ab986e6f3b36d42b0446ff533bbaf5ec4fa2eb4` (dirty with unrelated operator-prompt files at drafting).

| object | sha256 at drafting | role |
|---|---|---|
| `verify.py` | `d6aaf327e9a1fc8480ae672145bca71813aa4b3c8d0e75121a271be2c3e37134` | the KW table (`KW`, line 84; **never read by this registration**) and the normative bit operations (`_lower/_upper/_cuo/_zong` 497–500) |
| `solve.c` | `3725fc275dcbc3814c0924fc91de28a5e9545ab3001b7010ee37cbe194b25d1d` | baseline of the weighted-Knuth estimator (`--estimate-knuth`; `KNUTH_MASS_SE` 8800; scorer template `score_dav2` and, once the QOY push lands, `score_qoy`; C6/C7 pin `SOLVE_KNUTH_C67`; pair-only null driver `--null-pair-constrained`) |
| `solve.py` | `73c688c1ec76266c0be5269f5cdc3d22ff09ab407d0e67432cb6354b19d7c76f` | baseline; corpus controls `_r7_jingfang/_r7_mawangdui/_r7_fuxi` (11306–11347); the literature-rule registry whose members §3 excludes |
| `tests.py` | `544ecfcc8cedcdec7cc1a3cff95bcfc155cae4dc74ba83f72732267da20b438a` | baseline; `TestTr8DofSampler` (N0 sampler lineage) |
| `scripts/prereg_c8screen_defcheck.py` | `bb017ec5fc57f20acd0e6e20fff4053fe46e29ce1c13659994cbf019080e8091` at drafting; **the ledger line is the frozen identity** | the family count, the forcing theorems, the reference implementations (§2.5), `DEFCHECK=PASS` (31 PASS lines) |
| `review_2026_09_27/PREREG_QOY1_Q992_2026_10_09.md` + `QOY1_Q992_MEASUREMENT_2026_10_09.md` | frozen `5e15192f…` (ledger line 2) | the template; the measured statistics §3 excludes; the instrument calibration §4.2 and §7.6 rest on |
| `documentation/SPECIFICATION.md`, `documentation/LITERATURE_RULES_FORMAL.md`, `documentation/LITERATURE_RULES_POPULATION_TESTS.md`, `reports/METHODS.md` §"Global observable ledger", `reports/TR8_REORDERING_REVISITED.md`, `F4PRIME_PREREGISTRATION.md`, `F5_ORIENTATION_PREREGISTRATION_2026_07_FROZEN.md`, `documentation/PREREG_H1_H3_TEST_2026_07_26.md`, `documentation/DISTRIBUTIONAL_ANALYSIS.md` | (at the HEADs above) | the already-measured rosters that §3 excludes from the family |

**Instrument pin that cannot be filled at freeze:** the `solve.c`/`solve.py`/`tests.py` state that lands the scorer (§7.1).
It is recorded as a dated §9 annotation **after** implementation and self-test and **strictly before** the first recorded run
(the QOY §9-A1/A2 pattern, staged-tree id plus file digests is acceptable). `bash scripts/binary_freshness_check.sh` printed
`BINARY_FRESH=STALE` at drafting (built 2026-09-23, source 2026-10-10): the lane rebuilds (§7.4) and prints `BINARY_FRESH=FRESH|YES`
before any run. Should the QOY instrument push (`SOLVE_KNUTH_SCORE_QOY`, `--qoy-verify`) not have landed on `main` when the lane
starts, the lane builds on the staged QOY tree `4b590dfc…` on `11003edd` instead, and the §9 pin says which.

## §2 Definitions (normative) and the family, member by member

### §2.1 Conventions (all against `verify.py`)

A sequence is an orientation-explicit permutation `s[0..63]` of {0..63}; hexagram bits as in `verify.py` (`_lower(h) = h & 7`,
`_upper(h) = (h >> 3) & 7`; `63` = 乾, `0` = 坤; `y(h) = popcount(h)`; `rev = _zong`, `comp = _cuo`, `partner(h) = rev h` if
`rev h ≠ h` else `comp h`). **Slot** `k = 1..32` holds the **entry** `e_k = s[2k−2]` and the **exit** `x_k = s[2k−1]`
(C1: `x_k = partner(e_k)`). **Boundary** `b = 1..31` joins `x_b` and `e_{b+1}`; its **difference word** is `t_b = x_b ⊕ e_{b+1}`
and its distance `d_b = y(t_b)`. `rev3` is 3-bit reversal; `L, U` the lower/upper trigram. `PAL = {h : rev h = h}` =
{0, 12, 18, 30, 33, 45, 51, 63} = span{12, 18, 33}, an XOR subgroup of order 8 (defcheck A3); every `h ⊕ partner(h)` lies in it (A4).

**Label-free (this file's definition).** A member is a function of the sequence of 6-bit words under the received line-position
convention; it never references a hexagram's King Wen number or name, and wherever it constructs a categorical value whose
labels are arbitrary (a coset index) it uses that value only through label-invariant operations (membership in the subgroup
itself, equality across a boundary). Trigram identities and yang counts are canonical bit patterns, not labels, and may be
named. The constraint symmetry group G48 (SPECIFICATION.md, 48 line-position permutations commuting with `rev`) is **not**
imposed: trigram-content members are not G48-invariant, and a survivor among them would be a feature of the received line
positions; §8.3 item 4 makes that explicit in the audit rather than excluding the class.

### §2.2 Positional primitives

For a set `K ⊂ {1..32}` of slots: **CM(K)** = Σ_{k∈K} k (centre of mass, integer); **DISP(K)** = Σ of squared **circular** gaps
between consecutive elements of K on the 32-cycle (with `|K| = m`, gaps sum to 32); **D(K)**, used only when `|K| = 8`, =
Σ (g − 4)² = DISP(K) − 128 (since Σg = 32 and m = 8) — kept in Q-OY1's exact form `Σ (g − 4)²` so that the H16 member coincides with the measured D.
For a set `B ⊂ {1..31}` of boundaries: **CM(B)** = Σ b; **LDISP(B)** = Σ of squared **linear** gaps between consecutive elements.

### §2.3 The 651 subgroups, indexed canonically

ℋ = all subgroups of order 16 of (ℤ/2)⁶ = all 4-dimensional subspaces of F₂⁶; `|ℋ| = [6,2]₂ = 63·31/3 = 651` (defcheck B1).
Enumeration: every 4×6 reduced-row-echelon matrix over F₂ (column `c` ↔ bit `5−c`), the 16 XOR-combinations of its rows,
each subgroup as its sorted 16-tuple, **the list sorted lexicographically, indexed `H_000..H_650`**;
`SUBGROUP_LIST_SHA256=44e8a16bd08c4caf0edd1619ca598b891e5515836ca6feb67ae59fd605d40d52` (B2). Two distinguished sub-families:
- **ℋ_PAL** (7 subgroups: indices 127, 244, 368, 404, 484, 564, 644): `H ⊇ PAL`, equivalently `H = PAL ⊕ ⟨v⟩`; for these and only
  these both members of every C1 pair lie in **one** coset, so the "coset string" of slots is well defined (B3, B4). Ouyang 1993's
  H16 (palindromes ∪ anti-palindromes) is `H_644`.
- **ℋ_PC** (19 subgroups: the 7 above plus 83, 115, 197, 229, 279, 378, 401, 518, 584, 614, 632, 641): `H` is **pair-closed**
  (`h ∈ H ⇒ partner(h) ∈ H`), i.e. a union of exactly 8 C1 pairs (B5, B7). For every other `H` some pair has exactly one member in
  `H` (B6).

### §2.4 The family — 1,349 members in five classes, two strata

```
K = 1349 = K_C + K_S;   K_C = 1300 (stratum C, the subgroup scan);   K_S = 49 (stratum S, the structural classes)
MEMBER_LIST_SHA256 = 486cac40f85c1639bd4e05915541525e48b05a5097c589121ac28962a82db06c   (ids, strata, declared ranges)
```

**Class C — subgroup scan (stratum C, 1,300 members).** For each `H ∈ ℋ`:
- `C-N[H]` = #{b : t_b ∈ H}, the boundaries whose difference word lies in `H` (range 0..31). For `H ∈ ℋ_PAL` this is exactly the
  number of same-coset slot boundaries (Q-OY1's `NSAME`, defcheck E5). **651 − 1 = 650 members** (`C-N[644]` = NSAME(H16) is
  excluded: measured 2026-10-09 as a descriptive output, §3).
- `C-M[H]` = #{k : e_k ∈ H}, the entry hexagrams lying in `H` (range 0..32) — the orientation preference of the ordering relative
  to `H` (a pair with exactly one member in `H` contributes iff that member leads). For `H ∈ ℋ_PC` it is **forced = 8** (B4/B7, E2),
  so **651 − 19 = 632 members**.
- `C-D[H]` for `H ∈ ℋ_PC` only: `D(K_H)` with `K_H = {k : {e_k, x_k} ⊂ H}` (always 8 slots; range 0..504). For `H_644` this is Q-OY1's
  `D` (E6), measured and excluded: **19 − 1 = 18 members**.

**Class B — trigram relations across the 31 boundaries (stratum S, 8 members).** Counts over `b = 1..31` of:
`B-SL: L(x_b) = L(e_{b+1})` · `B-SU: U(x_b) = U(e_{b+1})` · `B-CL: L(x_b) = L(e_{b+1}) ⊕ 7` · `B-CU: U(x_b) = U(e_{b+1}) ⊕ 7` ·
`B-RL: L(e_{b+1}) = rev3(L(x_b))` · `B-RU: U(e_{b+1}) = rev3(U(x_b))` · `B-XL: L(e_{b+1}) = U(x_b)` · `B-XU: U(e_{b+1}) = L(x_b)`
(each 0..31). The conjunction `XL ∧ XU` is Q-992's `X` (E7), measured and excluded.

**Class P — positional structure of the difference wave (stratum S, 9 members).** With `B_2, B_3, B_4` the boundaries of distance
2, 3, 4 and `B_odd = B_1 ∪ B_3` (sizes 8, 13, 7, 15 are **forced** in every C1∩C5 ordering — the trigram-level theorem,
`lean/TrigramTheorems.lean`; defcheck C1 re-checks the within-pair half): `P-CM[c]` = CM(B_c) and `P-DISP[c]` = LDISP(B_c) for
`c ∈ {2, 3, 4, odd}` (8 members), and `P-MAXRUN` = the longest run of equal pair-parity class (`y(e_k) mod 2`) over slots 1..32
(1..32; the number of runs is forced = 16 by the 15-alternation theorem, the longest run is not).

**Class Y — the yang-count walk (stratum S, 14 members).** `Y-AC` = Σ_{b=1}^{31} (y(x_b) − 3)(y(e_{b+1}) − 3) (−279..279; the
within-pair products are a forced multiset, so only the boundary sum is registered); `Y-TV` = Σ_b |y(e_{b+1}) − y(x_b)| (0..186);
`Y-RUNS` and `Y-MAXRUN` = the number and the longest of the maximal runs of the ternary sign sequence `sgn(y(s_i) − 3)`, `i = 0..63`
(1..64). Pair yang-sum classes `v_k = y(e_k) + y(x_k) ∈ {2, 4, 6, 8, 10}` with the forced multiset {2:3, 4:6, 6:14, 8:6, 10:3}
(C3): `Y-CM[v]` = CM(S_v) and `Y-DISP[v]` = DISP(S_v), `S_v = {k : v_k = v}` (10 members).

**Class T — trigram content by slot, orientation-free (stratum S, 18 members).** `T_t = {k : t ∈ {L(e_k), U(e_k), L(x_k), U(x_k)}}`
for each trigram `t = 0..7` (sizes forced: {0:8, 1:15, 2:8, 3:15, 4:15, 5:8, 6:15, 7:8}, C2): `T-CM[t]`, `T-DISP[t]` (16 members).
`S_pure = {k : L(e_k) = U(e_k)}` (the 4 pure 八純 pairs; slot 1 always): `T-CM[pure]`, `T-DISP[pure]` (2 members).

Why no single-slot members: a statistic whose value is one slot or boundary index, or the category of one slot, takes ≤ 32 values
with near-uniform mass under every null here, so its smallest attainable two-sided p is of order 2/32 ≫ any bar below; it can
**never** be a SURVIVOR (a gate that cannot be satisfied). The per-slot marginals of the question are therefore registered through
their positional aggregates (CM, DISP, counts) over the whole sequence, whose null tails can be arbitrarily small. The atlas
kernel's per-slot expectations (S2) are **not** used by any member: a member must be computable from the sequence alone.

### §2.5 Reference implementations

`scripts/prereg_c8screen_defcheck.py` holds the normative Python for every member (`C_N, C_M, C_D, B_rel, P_CM, P_DISP, P_MAXRUN,
Y_AC, Y_TV, Y_RUNS, Y_MAXRUN, Y_CM, Y_DISP, T_CM, T_DISP, T_CM_pure, T_DISP_pure`, the subgroup enumeration `rref_subspaces`, and the
`MEMBERS` list). `solve.py` must carry that code **byte-for-byte** (§7.1); `solve.c` must reproduce it (§7.2 two-language gate).

## §3 Exclusions — forced by theorem, or already measured (each with its proof or citation, and the prior-art verdict)

| excluded statistic | why | where |
|---|---|---|
| `W` (within-slot swap count) | forced = 6 by C1 (theorem; defcheck C6 re-checks the 6 swap pairs) | PREREG_QOY1 §3.1; Lean W = 6 (ASSESSMENT_2026_10_09 §a) |
| `X` (cross-boundary swap), `A` (couples), `T` | measured 2026-10-09, UNINFORMATIVE | QOY1_Q992_MEASUREMENT §1; `B-XL`/`B-XU` are registered **separately**, their conjunction is `X` (E7) |
| `D(H16)`, `NSAME(H16)`, the H16 occupancy vector | measured 2026-10-09 (D primary; NSAME, occupancy descriptive) | same; `C-D[644]`, `C-N[644]` removed |
| `C-M[H]` for the 19 pair-closed `H` | forced = 8 (B4/B7, E2) | this file |
| boundary distance counts per `d`; the 15 alternations; wrap parity; the position-free trigram counts `|T_t|`; the pair yang-sum multiset; `|S_pure|`; within-pair distance profile (`c2`) | forced by C1 (∩C5) | SPECIFICATION.md theorems; defcheck C1–C4, E3 |
| position of the distance-6 boundary; span of the two distance-1 boundaries | single-index statistics (§2.4) **and** measured (F5 `f5_bpd_six_pos`, `f5_bpd_one_span`) | F5_ORIENTATION_PREREGISTRATION §list |
| lag-1 product sum of the difference wave | measured (F4′ `dist_autocorr`; H1/H3 `A`) | F4PRIME_PREREGISTRATION amendment 1; PREREG_H1_H3 §functionals |
| yang centre of mass Σ i·y(s_i) | measured (F4′ `yang_drift`) — `Y-CM[v]` are the per-class positional versions, not this sum | F4PRIME amendment 1 |
| canon yang totals, 18:18 split, Moore parity/rhythm, Schulz gender, Chan groups-of-four `c1` | measured in the C1–C5 population (TR-8; scoreboard) — no canon-split or orientation-by-yang member is registered | LITERATURE_RULES_POPULATION_TESTS; TR-8 §2; LITERATURE_RULES_FORMAL §2.1–2.3, §3.16, §3.6, §3.28 |
| orientation-lead statistics (`f5_correct_lead`, `f5_lex_dev`, `f5_orient_alt`, `f5_greedy_entry`, `vdb_nuc`) | measured (F5) — `C-M[H]` is orientation **relative to a subgroup**, a different object | F5 §list |
| complement-pair positions (`palspan`, `comp_adj`, H3 `P`/`Q`, the classic-ends concentration) | measured — no comp-pair positional member is registered | F4′; PREREG_H1_H3; DISTRIBUTIONAL_ANALYSIS trigram addendum |
| longest shared-lower-trigram run (`trigram_runs`), `nuclear_adj`, Jing Fang house statistics | measured (F4′) — `B-SL` is a count, not a run length | F4′ |
| upper/lower trigram **change rates** | measured against a **C1-only** null (`roae.py --trigrams`) and as corpus-table columns (R7 `_r7_obs_c1/c2`, no significance claim); the canonical-population versions are explicitly "unmeasured" (DISTRIBUTIONAL_ANALYSIS addendum) — so `B-SU`, `B-SL` are admissible and are **the** canonical-population measurement | DISTRIBUTIONAL_ANALYSIS §Trigram-level addendum; TRIGRAM_ANALYSIS_SCOPING E3 |
| `m2`, `d4`, `p2c5`, `ccn2`, `c2011n2`, `r3`, `_r7_obs_g` | measured **Booleans** about pure/palindromic/Kan-Li placement; `T-CM[pure]`, `T-DISP[pure]`, `T-CM[t]` are distinct continuous statistics, kept, and **flagged for the §8.3 audit** | LITERATURE_RULES_FORMAL §3 |
| the 10-dimensional observable vector (FFT etc.), R3 permutation observables, F6 palace/warp statistics, the atlas kernel log-score, EW-1 typicality, TR-10's nine | not in the family; listed so the 91/95-observable ledger (METHODS.md) is seen to have been read | METHODS.md §Global observable ledger |

**Prior-art verdicts** (`bash scripts/prior_art_check.sh '<phrase>'`, 2026-10-11, `PRIOR_ART_SELFCHECK=PASS` on every run):
`'coset string'` HIT n=8 (the 10-09 assessment, the QOY prereg, the Pilot A task — the proposal, not a measurement) ·
`'subgroup membership'` HIT n=2 (a 2026-07 Codex dossier, unrelated) · `'subgroup scan'` NONE · `'order-16 XOR-subgroup'` HIT n=4
(Q-OY1 only; quoted from WORKSTATION_FUTURE_ASSESSMENT App. A) · `'shared trigram'` HIT n=33 (SOLVE.md boundary descriptions and
copies; no population measurement) · `'trigram relation'` HIT n=28 (the trigram scoping note and its reads) · `'trigram content'`
HIT n=33 (TRIGRAM_STRUCTURE.md, CITATIONS; no slot-position measurement) · `'boundary difference'` HIT n=27 (C2/C5 prose) ·
`'XOR-difference'` HIT n=11 (book reviews, scan analysis; unrelated) · `'difference word'` NONE · `'yang-count run'` NONE ·
`'run structure'` HIT n=34 (F4′ `dist_runs`/Moore rhythm — distance runs, excluded above; not yang-count runs) ·
`'lag-1 autocorrelation'` HIT n=45 and `'autocovariance'` HIT n=24 (F4′/H1 difference-wave statistics — **excluded** above; the
yang-count boundary product `Y-AC` is not among the hits) · `'centre of mass'` NONE · `'center of mass'` HIT n=2 (unrelated notes)
· `'gap dispersion'` HIT n=9 (Q-OY1 `D` only) · `'parity run'` HIT n=3 (ops notes, unrelated) · `'pair-sum class'` NONE ·
`'orientation preference'` NONE · `'weighted Bonferroni'` NONE · `'single-slot statistic'` HIT n=2 (the Pilot A task and the
10-09 assessment) · `'C8 screen'` HIT n=9 (the proposal documents only). Every hit was read before the row above was written;
none records a population measurement of a registered member.

## §4 Null populations — the same three as Q-OY1/Q-992, existing instruments only

### §4.1 N0 — the pair-only C1∩C4 null (TR-8 §2 null (b)) — SAMPLED, 10⁷ draws

Uniform over the 31!·2³¹ orientation-explicit orderings of the 32 C1 pairs with `(63, 0)` in slot 1 (the `TestTr8DofSampler`
lineage: shuffle the 31 free pairs, fair orientation coin per pair). No closed form exists for 1,349 members, so N0 is **sampled**:
`10⁷` draws by the C implementation (`--c8-null0`, §7.1: Fisher–Yates over the 31 free pair slots **with `(63, 0)` pinned in slot 1**
and a fair orientation coin per free pair; the existing `run_null_pair_constrained` driver is the template and is used only if it pins
slot 1, else a pinned variant is written), seed §6 `null0-draws`. Resolution: an empty tail is reported as `3/10⁷ = 3×10⁻⁷`, below both bars; the sampled N0 tail SE is binomial.
**Role:** the §5.3 independence annotation and the attainability line (the smallest N0 two-sided p any value of the member
could reach — a sanity output, not a verdict). N0 imposes neither C2 nor C5, so the Class P set sizes vary under it (E4); the
Class P members' N0 laws are reported but their annotation is read with that caveat.

### §4.2 N1 — the C1–C5 constraint-satisfying population (≈1.33×10³⁸ raw) — weighted-Knuth ESTIMATE, GOVERNS the verdict

`./solve --estimate-knuth N` with `SOLVE_KNUTH_SCORE=1` and the per-leaf scorer of §7.1, exactly the instrument of
`LITERATURE_RULES_POPULATION_TESTS.md` and of the 2026-10-09 run: leaves are orientation-explicit C1∩C2∩C4∩C5 completions with
C3 ≤ 776 applied at the leaf ("canonical leaves"), each contributing its Knuth weight to a value histogram per member with the
Q-374 squared-weight twin (`KNUTH_MASS_SE`, solve.c 8800).

**No-subsampling rule, stated:** the C1–C5 space cannot be enumerated; the estimator is the project's established,
exact-anchored instrument for it; estimates carry their SE and the self-validation gate; nothing is called exact.

- **Probe count, frozen:** `2×10¹⁰` probes total = two halves of `1×10¹⁰` on the §6 `knuth-half-A` / `knuth-half-B` seeds (fresh
  seeds, not the estimator default: the 10-09 half A already consumed the default stream and this run must be seed-disjoint from it).
- **Sample-size justification (from the 10-09 run's printed numbers, `TOKENS.txt`):** 2×10¹⁰ probes scored **35,941,839** canonical
  leaves; the printed SE at a tail of mass 0.662 was 1.316×10⁻⁴, i.e. an effective sample size `ESS = p(1−p)/SE² ≈ 1.30×10⁷`.
  The operative tail (§5.1) is `p̂ + 3·SE` with `SE ≈ sqrt(p/ESS)` to first order, so a member whose **true** two-sided tail mass is
  `p_t` is expected to clear a bar `β` iff `p_t + 3·sqrt(p_t/ESS) < β`: **`p_t ≤ 2.5×10⁻⁶` for the stratum-C bar 3.85×10⁻⁶, and
  `p_t ≤ 9.4×10⁻⁵` for the stratum-S bar 1.02×10⁻⁴** (`python3 -c` arithmetic recorded in PILOT_A_PREREG_NOTES.md). The
  rule-of-three floor `3/L = 8.3×10⁻⁸` sits 46× below the tighter bar. This is the stated detectable effect size: a feature
  that puts KW at the 2.5-in-a-million level of the C1–C5 population (stratum C) or the 1-in-10,000 level (stratum S) survives in
  expectation; weaker features are declared NULL **at this instrument size**, which the publish text must say. The ESS is a
  bulk figure; in far tails the heavy-tailed weight law can reduce it, which the per-tail SE already reflects and the §5.2
  leaf-count condition guards.
- **Self-validation gate (sized from the printed SE, the 10-09 correction):** each half's printed `leaves_canonical_C1C5` estimate
  must satisfy `|est − 1.3287×10³⁸| ≤ max(3·SE_printed, 0.5 %·1.3287×10³⁸)`, and the pooled estimate `|est − ref| ≤ max(3·SE_pooled,
  0.2 %·ref)` (the 10-09 bands as floors, never tighter than 3σ). Fail ⇒ `VOID`.
- **Replication:** per member, §5.2.

### §4.3 N1′ — the same estimator under the C6/C7 pins — ANNOTATION ONLY

`SOLVE_KNUTH_C67=1`, two halves of `5×10⁹` probes on the §6 `knuth-c67-half-A/B` seeds (the 10-09 sizes: ≈5,762 leaves per
2×5×10⁹, so N1′ resolves tails only to ≈5×10⁻⁴ and **cannot judge any bar**). Self-validation: each half and the pooled estimate
within `max(3·SE_printed, 1 %)` of 5.21×10³¹ (the 10-09 band was tighter than the estimator's own 1σ; corrected here). Its one
decision-relevant use is the survivor annotation of §5.4 (`C67_CONSISTENT` / `C67_ABSORBS`). N1 governs every verdict.

### §4.4 Reference (not a null): corpus controls

Every member is evaluated on the Jing Fang Eight-Palaces order, the Mawangdui order and the Fu Xi order as held in `solve.py`
(`_r7_jingfang`, `_r7_mawangdui`, `_r7_fuxi`); these are non-C1 orderings (slot-based members are still defined on them as
sequences). Their values are placed in the N1 histogram exactly as KW's is; they feed only the §5.2 specificity condition.

## §5 Test, family correction, verdict rules — FROZEN

### §5.1 Two-sided operative p, per member

For member `m` with KW value `s`: `p_le = P_N1(S ≤ s)`, `p_ge = P_N1(S ≥ s)` (pooled weighted masses), each with its delta-method
SE. **Operative** tails are `p_le + 3·SE_le` and `p_ge + 3·SE_ge`; a tail whose estimated mass is exactly 0 over the whole run takes
`3/L` (`L` = the run's printed canonical-leaf count). `p_op(m) = min(1, 2·min(operative tails))`. Under N0 the same with sampled
masses and binomial SE (`p_op,N0`). Direction = the smaller operative tail. Both tails are always reported.

### §5.2 Weighted Bonferroni over the declared count, α = 0.01, two strata

Family-wise `α = 0.01`, split equally between the two strata: `α_C = α_S = 0.005`. Within each stratum, Bonferroni over its
declared count: **`β_C = 0.005/1300 = 3.846154×10⁻⁶`** for the 1,300 subgroup-scan members, **`β_S = 0.005/49 =
1.020408×10⁻⁴`** for the 49 structural members. This controls the family-wise error at 0.01 over all 1,349 members
(weighted Bonferroni is a Bonferroni procedure); the split keeps the mechanical scan from pricing the literature-motivated
classes at the scan's bar. No Holm step-down, no FDR, no re-binning, no post-hoc statistic swap, no adaptive extension: a
statistic evaluated on KW without a prior dated §9 addendum (registered **before** its evaluation, at `0.005/(K_stratum + 1)`
of its stratum) is exploratory and can never be a SURVIVOR under this file.

### §5.3 Independence annotation (what "shaped by C1–C7" means, operationally)

C1 and C4 are conditioned on by every null. For every member: `INDEPENDENT_OF_C2_C5` iff `p_op,N0 < β_m` in the same tail as the
N1 result; `C2_C5_CONDITIONAL` iff `p_op < β_m` but `p_op,N0 ≥ β_m`; `EXPLAINED_BY_C2_C5` iff `p_op,N0 < β_m` but `p_op ≥ β_m`;
`NA` otherwise. Annotation only; the verdict uses N1.

### §5.4 Verdict table — per member, mutually exclusive, jointly exhaustive, applied in this order

Let `β_m` be the member's stratum bar; `p_op,A`, `p_op,B` the half-wise operative values; `n_A`, `n_B` the number of scored
leaves in the smaller tail (value at or beyond KW's, in KW's direction) in each half; `ctrl` the three corpus controls.

| token | condition |
|---|---|
| `VOID` (family-level) | any §7.2 gate fails; a §4.2 self-validation fails; `BINARY_FRESH` not FRESH/YES; the §9 instrument pin missing; `C8_CLAMPED_TOTAL ≠ 0` |
| `FORCED` | the member is constant over every N1 leaf (`min == max`) — reported; indicates an exclusion this file missed; counts as UNINFORMATIVE in the family tally |
| `UNINFORMATIVE` | not FORCED and **either** (a) `min over the N1 pooled support v of p_op(v) ≥ β_m` — no value could have survived; **or** (b) `p_op(m) < β_m` but one of: `p_op,A ≥ 10·β_m`, `p_op,B ≥ 10·β_m`, `n_A < 10`, `n_B < 10` (below the bar but unreplicated or carried by too few leaves); **or** (c) `p_op(m) < β_m` and some control has same-tail operative `p ≤ β_m` (non-specific). The reason token is printed (`ATTAIN`, `REPLICATION`, `LEAVES`, `SPECIFICITY`) |
| `SURVIVOR` | `p_op(m) < β_m` **and** `p_op,A < 10·β_m` **and** `p_op,B < 10·β_m` **and** `n_A ≥ 10` **and** `n_B ≥ 10` **and** no control has same-tail operative `p ≤ β_m` |
| `NULL` | `p_op(m) ≥ β_m` and not UNINFORMATIVE(a) |

**Family verdict:** `FAMILY=SURVIVOR` iff ≥ 1 member is SURVIVOR; else `FAMILY=NULL` iff the number of UNINFORMATIVE+FORCED members
is ≤ 67 (5 % of 1,349); else `FAMILY=UNINFORMATIVE` (the instrument did not resolve the family; reported as an instrument limit,
re-run requires a new dated prereg). **Survivor annotation (N1′):** `C67_CONSISTENT` iff the survivor's N1′ pooled operative
`p_op,N1′ < 0.05`; else `C67_ABSORBS` (its rarity does not persist once slots 24–27 are pinned to KW's pairs — the published C6/C7
pins already carry it; the §8.2 chain **halts** and the member is written up as explained by C6/C7).

## §6 Seeds — FROZEN AND MATERIALIZED

Convention (A-4): uint64 = first 8 bytes, big-endian, of `sha256(<ASCII string>)`; the date token `2026-10-11` is permanent.
Re-derive: `python3 -c "import hashlib,sys; [print(s, int.from_bytes(hashlib.sha256(s.encode()).digest()[:8],'big')) for s in sys.argv[1:]]" <strings>`.

| purpose | ASCII string | uint64 |
|---|---|---|
| N1 half A | `ROAE-C8SCREEN-2026-10-11/knuth-half-A` | 359881319887057140 |
| N1 half B | `ROAE-C8SCREEN-2026-10-11/knuth-half-B` | 716349220184206698 |
| N1′ half A | `ROAE-C8SCREEN-2026-10-11/knuth-c67-half-A` | 16185144687099509794 |
| N1′ half B | `ROAE-C8SCREEN-2026-10-11/knuth-c67-half-B` | 6479258443758798337 |
| N0 draws | `ROAE-C8SCREEN-2026-10-11/null0-draws` | 9041319306645778315 |
| two-language gate random orderings | `ROAE-C8SCREEN-2026-10-11/gate-random-c1-orderings` | 8109856556285410379 |
| defcheck synthetic orderings | *(constant `20261011` in the script)* | — |

No seed has been used. The estimator is unbiased for any seed; the seeds exist so the runs are reproducible and disjoint from
every earlier run.

## §7 What the measurement lane must do and output — FROZEN

### §7.1 Implement (single-file rule: C in `solve.c`, Python in `solve.py`, tests in `tests.py`)

- `solve.py`: the §2.5 reference code **byte-for-byte** (the defcheck's functions and `MEMBERS` construction; the subgroup
  enumeration included), `c8_values(seq) -> list of 1349 ints in MEMBERS order`, `c8_line(seq)` printing them, `--c8-verify <solve>`
  (two-language gate) and `--c8-kw` (**the first evaluation on King Wen; it is run only after the §9 pin is written and is itself
  recorded as the measurement's date**). No `C8_KW_EXPECTED` literal is embedded before that fill.
- `solve.c`: scorer `score_c8` under `SOLVE_KNUTH_SCORE_C8=1`, template `score_qoy`: per leaf all 1,349 values; weighted histograms
  with squared-weight twins (bins per declared range; out-of-range ⇒ a clamp counter that must stay 0); raw sums printed at full
  precision as `c8_hist <member-id> <value> <sum_w> <sum_w2>` lines plus `C8_RAW_SC/QC/N`, `C8_LEAVES_SCORED`, `C8_CLAMPED`.
  The estimator prints **no KW line** (unlike `qoy_report`): KW's values come only from `--c8-kw`. `--c8-null0 <N>` (seed from `SOLVE_KNUTH_SEED`): the
  pair-only sampler of §4.1 (slot 1 pinned) with the same scorer and the same output lines, plus `C8_NULL0_DRAWS=<N>`. Estimator-only, sha-neutral: zero effect on enumeration paths.
- **Mutant leg (gates must discriminate):** a build with `e_k ↔ x_k` swapped in `C-M` must make `--c8-verify` print `C8_VERIFY=FAIL`.
- `tests.py`: `TestC8Scorer` — the gate on 10⁵ random C1∩C4 orderings (seed §6 `gate-random-c1-orderings`), red on the mutant.
- Memory: ≈1 MB of histograms per thread (651×(32+33)+… bins ×2 ×8 B); per-leaf cost ≈ 651×63 membership lookups ≈ tens of µs,
  i.e. ≲ 1 CPU-h over 3.6×10⁷ leaves (§7.6).

### §7.2 Pre-run gates, all printed as `KEY=value` into `gates.txt`

`PREREG_SHA_VERIFIED=PASS` (the lane's `sha256sum` of this file equals the ledger line); `DEFCHECK_SHA_VERIFIED=PASS` (same for
the script); `DEFCHECK=PASS` (re-run; 31 PASS lines; `FAMILY_K=1349`, `MEMBER_LIST_SHA256=486cac40…`, `SUBGROUP_LIST_SHA256=44e8a16b…`
reproduced); `C8_VERIFY=PASS` on 10⁵ gate orderings (py/C output digests equal); `C8_VERIFY_MUTANT=FAIL`; `BINARY_FRESH=FRESH|YES`;
`SELFTEST=PASS`; `INSTRUMENT_PIN=<tree/commit + file digests>`; `VERIFY_PY_SHA256`, `SOLVE_C_SHA256`, `SOLVE_PY_SHA256`,
`TESTS_PY_SHA256`, `SOLVE_BIN_SHA256`, `PUBLIC_HEAD`, `PRIVATE_HEAD`, `SOLVE_THREADS`, `BUILD` line. Only then `--c8-kw` (§9-A2).

### §7.3 Runs

Build: `gcc -O2 -fopenmp -o solve solve.c -lm -lpthread -lz` (`-fopenmp` mandatory). Then, each with `ulimit -s unlimited`,
`SOLVE_KNUTH_SCORE=1 SOLVE_KNUTH_SCORE_C8=1`, `SOLVE_THREADS=16` (pinned, as on 2026-10-09, so the probe streams are reproducible):

```
SOLVE_KNUTH_SEED=359881319887057140                       ./solve --estimate-knuth 10000000000   # N1 half A
SOLVE_KNUTH_SEED=716349220184206698                       ./solve --estimate-knuth 10000000000   # N1 half B
SOLVE_KNUTH_C67=1 SOLVE_KNUTH_SEED=16185144687099509794   ./solve --estimate-knuth 5000000000    # N1' half A
SOLVE_KNUTH_C67=1 SOLVE_KNUTH_SEED=6479258443758798337    ./solve --estimate-knuth 5000000000    # N1' half B
SOLVE_KNUTH_SEED=9041319306645778315                      ./solve --c8-null0 10000000            # N0
```

Unfiltered stdout+stderr of every run under `review_2026_09_27/c8screen/RECORDED_<date>/` with `TOKENS.txt`, `gates.txt`,
`analyze.py` and `vm/`. Preserve runs: never overwrite a RECORDED directory. A Spot-evicted run is re-run from scratch with the
same seed (the runs are independent and deterministic given seed and thread count); partial outputs are kept, labelled, and not pooled.

### §7.4 Result tokens

Per member `m` (ids as in `MEMBERS`): `m_KW`, `m_N1_HIST_A/B/POOLED`, `m_N1_E`, `m_N1_MIN_MAX`, `m_N1_P_LE/GE`, `m_N1_SE_LE/GE`,
`m_N1_P_TWO_OPERATIVE`, `m_N1_P_TWO_OPERATIVE_A/B`, `m_N1_TAIL_LEAVES_A/B`, `m_N1_SMALLER_TAIL`, `m_N1_MIN_ATTAINABLE_P`,
`m_N0_P_TWO`, `m_N0_MIN_ATTAINABLE_P`, `m_N1C67_P_TWO_OPERATIVE`, `m_CONTROL_JINGFANG/MAWANGDUI/FUXI` (value, same-tail operative p),
`m_INDEPENDENCE`, `m_VERDICT` (+ reason). Family: `FAMILY_K=1349`, `FAMILY_K_C=1300`, `FAMILY_K_S=49`, `FAMILY_ALPHA=0.01`,
`BAR_C=3.846154e-06`, `BAR_S=1.020408e-04`, `N1_PROBES=20000000000`, `N1_SEEDS`, `N1_SELFVALIDATION`, `N1C67_SELFVALIDATION`,
`N0_DRAWS=10000000`, `C8_CLAMPED_TOTAL=0`, `COUNT_SURVIVOR`, `COUNT_NULL`, `COUNT_UNINFORMATIVE`, `COUNT_FORCED`,
`SURVIVORS=<ids or NONE>`, `SMALLEST_P_OP=<id, value>` (reported whatever the verdict), `FAMILY=SURVIVOR|NULL|UNINFORMATIVE`.
`TOKENS.txt` is the full set; a compact `SUMMARY.tsv` (one row per member) accompanies it.

### §7.5 Analysis script

`analyze.py` (committed with the RECORDED directory) implements §5 literally from `MEMBERS`, the five run outputs and the `--c8-kw`
line; it must print `FAMILY=` last and must be runnable by a third party on the archived outputs.

### §7.6 [cost section omitted from the public copy]

## §8 What each outcome will mean — decided before it exists

### §8.1 Meaning

- **`FAMILY=NULL`** means exactly: "no member of the registered family of 1,349 label-free slot/adjacency statistics places King Wen
  at operative two-sided `p < 0.005/1300` (subgroup scan) or `p < 0.005/49` (structural classes) in the C1–C5 population, at an
  instrument size that would in expectation have detected a true tail mass of 2.5×10⁻⁶ / 9.4×10⁻⁵ respectively." It is **not** "King
  Wen has no structure"; it is the pre-declared stop rule: **the C8 route is closed for this class** (per-slot marginals, subgroup
  coset membership, boundary trigram relations, difference-wave and yang-count positional structure). Reopening it needs a new family and
  a new registration.
- **`FAMILY=SURVIVOR`** means: "a pre-registered statistic places King Wen below its Bonferroni bar in the C1–C5 estimate, replicated
  across seed halves and carried by ≥ 10 leaves in each, and no corpus control shares the tail." It is **a survivor of a screen**,
  not a constraint and not yet a "candidate" (§8.2).
- **`FAMILY=UNINFORMATIVE`** means: the instrument did not resolve the family (too many members unattainable or unreplicated);
  written up as an instrument limit; re-run under a new dated prereg.
- **`VOID`** means: the instrument failed; written up in full; re-run needs a new prereg (or a §9 annotation if the failure is a pure
  implementation bug fixed before any N1 number was read — the annotation must say which).
- **The one thing no outcome can do:** license "King Wen is explained by …". The strongest supported sentence is the
  population-conditional one above.

### §8.2 Follow-up for a SURVIVOR, in order (the only path to the word "candidate")

1. **Fable review** of the recorded run against this file; the §5.4 reason tokens re-derived by hand from the raw histograms.
2. **N1′ annotation** read: `C67_ABSORBS` halts the chain (explained by the published C6/C7 pins); only `C67_CONSISTENT` continues.
3. **Exact instrument (replication, never the estimate alone):** a DP or SAT/#SAT count over **C1∩C2∩C4∩C5** (the exact SUPER
   population, 1,097,051,278,789,181,790,036,112,071,176,579,186,688 orderings, TR-12) of the orderings whose member value lies at or
   beyond KW's in KW's tail, giving the exact `P_SUPER(tail)`; every registered member is a sum of local slot/boundary terms or a
   gap/run functional, so it folds into a transfer-matrix DP over the slot sequence with the C5 budget state (the knowledge-compiler
   state space) or into a counting-SAT target; the instrument, its state space, its cost and its acceptance inequality
   (`2·P_SUPER(tail) < β_m`, exact, no SE) are registered as a dated §9 addendum **before** it runs; [cost sentence omitted from the public copy]
4. **Circularity audit** (§8.3). Only after 1–4 pass may the member be called a **candidate C8 (for further scrutiny)**, and only then
   is the hardware question of WORKSTATION_FUTURE_ASSESSMENT §5 re-asked with a concrete target.
5. Nothing in this registration edits SPECIFICATION.md's constraint list, the C1–C7 figure, the TR-11/TR-12 counts, README or CITATIONS.

### §8.3 The circularity audit — what it must establish, item by item

1. **Origin:** the member's definition is in the frozen bytes; the class it belongs to was motivated by which literature descriptions
   (Ouyang 1993 for Class C, 韓仲民 1984 / the trigram-relation tradition for Class B, 程頤 1099 / Schulz for Classes Y and P, the
   pure-hexagram placement tradition for `T-*[pure]`) — listed, with the statement that none of those sources' King Wen tallies
   entered the member's definition or selection.
2. **Not forced:** N1 variance > 0 (`min ≠ max`) and the §5.3 token; a theorem attempt if the N0 law is degenerate.
3. **Not a re-measurement:** the nearest already-measured statistic (§3 table) is named; if that statistic already placed KW in the
   same tail at `p < 0.005` on the scoreboard, the survivor is reported as a refinement of a known feature, not as new.
4. **Labelling dependence:** the member is evaluated on KW's 23 record-level G48 twins (`SYMMETRY_SEARCH.md`); if the twins are not
   all in the tail, the feature is a property of the received line positions (reported as such; it is still a feature of KW, but a
   C8 built on it would break the G48 symmetry the C1–C5 system has, which the write-up must state).
5. **Look-elsewhere accounting:** `K`, the strata and the bars are quoted; any §9 addendum member is counted at its registration bar.
6. **Instrument independence:** the exact count (§8.2 step 3) and the Knuth estimate are two instruments sharing no code path for
   the tail; their agreement within the estimate's SE is required.

### §8.4 Publish-regardless — what lands publicly in each outcome, in public-safe wording

Every outcome lands privately in full (`ASSESSMENT_<date>.md`, the RECORDED directory, this file's frozen and annotated digests),
and publicly as follows, after the Fable prepub pass and the two-pass review:

- **NULL:** (i) a public copy of this registration under `documentation/` in the `PREREG_CLASSA_QUERY_SET.md` style, **with §7.6
  removed** and private paths glossed, stating its own digest and the private frozen digest and the "attested, not checkable" caveat;
  (ii) the instrument (`SOLVE_KNUTH_SCORE_C8`, `--c8-verify`, `--c8-kw`, `--c8-null0`, `TestC8Scorer`) with `SOLVE_C_CLI.md` /
  `SOLVE_PY_CLI.md` rows; (iii) `TOKENS.txt`, `SUMMARY.tsv`, `analyze.py` and the five unfiltered run outputs under
  `reports/evidence/c8screen/` (checked for identifiers; none expected); (iv) a short addendum to
  `documentation/LITERATURE_RULES_POPULATION_TESTS.md` (five class rows + the family sentence) and a line in the TR-12 Open Problems /
  Confidence Ledger, both in exactly the §8.1 wording: *"A pre-registered family of 1,349 label-free slot and adjacency statistics
  (counted before measurement; frozen digest …) was scored against the C1–C5 population; no member distinguishes King Wen after a
  family-wise correction at α = 0.01. The smallest operative two-sided p was … (member …). The C8 search over this class is closed."*;
  (v) a HISTORY.md line. No change to SPECIFICATION.md, the counts, the ladders or README.
- **UNINFORMATIVE / VOID:** items (i)–(iii) and (v), with the sentence *"the instrument did not resolve the family at this size
  (… members unattainable/unreplicated); no claim is made"*; no scoreboard rows.
- **SURVIVOR:** items (i)–(iii) and (v) land **unchanged** (the null-side artifacts are published regardless); the survivor itself is
  reported publicly only as *"one member fell below its pre-registered bar in the estimate and is under exact-instrument replication
  and audit (§8.2); no claim is made"* until the §8.2 chain completes, and never with the words "constraint", "rule" or "explained".
  The private ASSESSMENT carries the full record from day one.
- **Public-safe wording rules for all outcomes:** no costs, no VM names, no cloud identifiers, no private paths (glossed as
  "the private pre-registration"), "proven" only for the theorems cited, "measured"/"estimated" with SE for everything else,
  Ouyang 1993 / Han 1984 / 程頤 / Schulz credited as the describers of the features the classes operationalise.

## §9 Amendment log — OPEN (dated annotations only; append below this line)

*(none at freeze)*

## §10 Freeze procedure and the frozen-bytes identity

1. The orchestrator commits this file and `scripts/prereg_c8screen_defcheck.py` to `roae-private` **before** the measurement lane is
   briefed; the commit message names both files and the token below.
2. Immediately after the commit, the orchestrator appends the committed bytes' digests to `docs/data/PREREG_LOCK_LEDGER.txt` in the
   ledger's existing form (`sha256sum PREREG_C8SCREEN_2026_10_11.md scripts/prereg_c8screen_defcheck.py`, with `commit=` and
   `locked=` fields); the ledger lines are the frozen identities (this file cannot contain its own hash).
3. The measurement lane's first acts are `sha256sum` of both files compared with those ledger lines (`PREREG_SHA_VERIFIED=PASS`,
   `DEFCHECK_SHA_VERIFIED=PASS`, §7.2); a mismatch halts everything.
4. §9 annotations are appended **after** that comparison and are therefore outside the frozen bytes by construction; the ASSESSMENT
   cites both the frozen digest and the digest of the annotated file.

PREREG_C8SCREEN=READY_TO_FREEZE
