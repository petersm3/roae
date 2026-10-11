# PRE-REGISTRATION — Q-OY1 (Ouyang 1993 H16-coset slot spacing) and Q-992 (韩仲民 1984 trigram-swap adjacency) — **FROZEN 2026-10-09, BEFORE ANY MEASUREMENT**

> # 🔒 FROZEN — 2026-10-09 — BEFORE ANY VALUE OF EITHER STATISTIC ON KING WEN EXISTS
>
> **Freeze authorised by the operator** (CURRENT_STATE.md 2026-10-09 ~05:45Z: "pre-register, then run
> against existing null models; candidate-C8 only"). This document is a **registration**, not a draft.
> The orchestrator commits it to `roae-private` **before** the measurement lane starts; the commit
> timestamp and the `PREREG_LOCK_LEDGER.txt` entry are the durable freeze evidence (§10). As with
> every ROAE pre-registration in a private repository, freeze timing is **attested, not checkable by
> an outside reader** (PREREG_CLASSA_QUERY_SET.md §0 states the limit; it applies here too).
>
> **What has and has not been computed at freeze (Fable 5.1, `claude-fable-5-1`, this session):**
> - **Neither statistic has been evaluated on King Wen.** The freezing session imported `verify.py`
>   for its bit conventions only; `verify.KW` was never indexed by position. The only numbers about
>   KW quoted here are the ones already public in `books/FINDING_OUYANG_1993_Q68_2026_10_08.md`
>   (the coset-id string and the occupancy slot set) and in Han 1984 (the "six" of Q-992) — both
>   are PREMISES being tested for consistency, not results, and §3.1 explains why Han's six is a
>   C1 consequence by theorem, not by measurement.
> - **No null distribution has been computed and no percentile exists.** The exact N0 laws in §4
>   are stated as formulas; the measurement lane evaluates them. A toy brute force (5 and 7 slots)
>   and the hexagram-SET facts of §3 were checked by `prereg_qoy1_q992_defcheck.py` (§3.4) —
>   properties of the 64 hexagrams and of random orderings, never of KW's order.
> - **No estimator run was launched, no VM created, no scorer implemented.** The seeds in §6 were
>   derived from frozen strings by SHA-256; deriving a seed is a commitment, not a measurement.
>
> **Amendment rule.** Amendable only by **dated annotation appended in §9**; never by editing the
> text above §9. The frozen bytes are identified by the sha256 recorded at commit (§10).
>
> **This document authorises no compute by itself.** It freezes the science; §7 fixes what the
> measurement lane runs and what it must output. [cost sentence omitted from the public copy]

**Drafted and frozen** 2026-10-09 by Claude Fable 5.1 (`claude-fable-5-1`), the project's Fable lane,
under the operator priority of 2026-10-09. Structural template: `PREREG_TR8_DOF_MATCHED_SAMPLER_20260811.md`
(§3 numbering: hypothesis → null → statistic → decision rule → seeds → meaning) with the two-sided and
candidate-gate conventions of `R8_DAVIS_PREREG_2026_07_10.md` §2.

---

## §0 What this is, in one paragraph

Two exploratory observations about the King Wen (KW) sequence surfaced in the 2026-10 literature
reads: (Q-OY1) 欧阳维诚 1993 places the eight pairs of his order-16 subgroup H16 as the "backbone" of
the received order (pp. 190–191); every C1 pair lies in one XOR-coset of H16, so each of the 32 pair
slots carries a coset id, and KW's coset-0 slots are a particular 8-subset of the 32. (Q-992) 韩仲民
1984 p. 22 states that KW has exactly six adjacent pairs whose two hexagrams exchange upper and lower
trigrams. Both were read off KW, so neither can be a constraint as posed. This file fixes, **before
anything is measured**, one scalar statistic per observation that does **not** re-derive the observed
pattern, the null populations (all pre-existing instruments), the two-sided test and its family
correction, the independence check against C1–C7, what each outcome will be allowed to mean, and the
exact output the measurement lane must produce. A striking result makes a **candidate C8 for further
scrutiny** — nothing more. "Flat is a result": every outcome is written up.

## §1 Pinned references — sha256 measured at freeze

Public repo `/home/claude/github/roae/roae` at HEAD `11003eddd3a9453b24c68c8b0c773930b45467f4`
(working tree clean at freeze); `roae-private` at `e441a039d73e5af9d9e0c5387772dcfc65b78922`.

| object | sha256 at freeze | role |
|---|---|---|
| `verify.py` | `d6aaf327e9a1fc8480ae672145bca71813aa4b3c8d0e75121a271be2c3e37134` | the KW table (`KW`, line 84) and the normative bit operations (`_lower/_upper/_cuo/_zong` 497–500, `_swap` 905, `_rev6/_comp6/_partner/_canonical_pairs` 2019–2046) |
| `solve.c` | `5ec963f094becafb4c7df917d70ec91d4fb68e3d5cf71cd8a75d69588f633c62` | pre-scorer baseline of the weighted-Knuth estimator (`--estimate-knuth`; scorer template `score_dav2` 6510–6611; C6/C7 pin `SOLVE_KNUTH_C67` 41837) |
| `solve.py` | `df4fe922c4758eca049bfc85ad4e287a83f308df221fa7f6465a30fd0509ceae` | pre-scorer baseline; spec-side pattern `dav2_*` 9736ff; corpus controls `_r7_jingfang/_r7_mawangdui` 11310/11347; pair-null sampler lineage (`king_wen_pairs`, `rc4_violations`) |
| `books/FINDING_OUYANG_1993_Q68_2026_10_08.md` §2.3 | (private; at `e441a039`) | source of Q-OY1; the coset-id string and slot set are DATA quoted there |
| `books/li_shangxin/raw/READ_CNKI_ROUND2_A13_A15_2026_10_09.md` lines 70–73 | (private; at `e441a039`) | source of Q-992 (Han 1984 p. 22, recomputed there) |
| `HARDENING_BACKLOG.md` row Q-992 (line 1020) | (private; at `e441a039`) | the query as posed |
| `scripts/ouyang1993_ch4_check.py` checks H1/H2 | (private; at `e441a039`) | the coset-consistency theorem; coset labelling `key=min` (coset 0 = H16) |

**Instrument pin that cannot be filled at freeze:** the `solve.c`/`solve.py` commit that lands the
scorer (§7.1). It is recorded as a dated §9 annotation **after** implementation and self-test and
**strictly before** the first recorded estimator run. A run whose implementing commit is not pinned
in §9 before it starts is not covered by this registration. `bash scripts/binary_freshness_check.sh`
printed `BINARY_FRESH=STALE` at freeze (built 2026-09-23, source 2026-10-09): the lane must rebuild
(§7.4) and print `BINARY_FRESH=FRESH` before any run.

## §2 Definitions (normative; all against `verify.py`'s conventions)

A sequence is an orientation-explicit permutation `s[0..63]` of {0..63}; hexagram bits as in
`verify.py` (`_lower(h) = h & 7`, `_upper(h) = (h >> 3) & 7`; `63` = 乾, `0` = 坤). Pair slot `k`
(1-based, k = 1..32) holds positions `2k−2, 2k−1` (0-based). Adjacency `i` (i = 0..62) joins `s[i]`
and `s[i+1]`; **even i is within a slot, odd i is a slot boundary**.

```python
# verify.py:905            swap: 上下互易, exchange upper and lower trigrams
def swap(h):  return ((h >> 3) & 0b111) | ((h & 0b111) << 3)
rev  = verify._zong         # 綜 / rev  (verify.py:500)
comp = verify._cuo          # 錯 / comp (verify.py:499)
def partner(h):             # SPECIFICATION.md C1; == verify._partner
    r = rev(h); return r if r != h else comp(h)
H16    = frozenset(h for h in range(64) if rev(h) == h or rev(h) == comp(h))     # Ouyang 1993 p. 91/190
COSETS = sorted({frozenset(h ^ c for c in H16) for h in range(64)}, key=min)     # 4 cosets; COSETS[0] == H16
def coset_id(h): return next(i for i, C in enumerate(COSETS) if h in C)
```

### §2.1 Q-992 — trigram-swap adjacency

```python
def q992_T(s): return sum(swap(s[i]) == s[i+1] for i in range(0, 63))          # all 63 adjacencies
def q992_W(s): return sum(swap(s[i]) == s[i+1] for i in range(0, 63, 2))       # within-slot  (i even)
def q992_X(s): return sum(swap(s[i]) == s[i+1] for i in range(1, 63, 2))       # cross-boundary (i odd)  <- PRIMARY
def q992_A(s):                                                                 # couples in adjacent slots, orientation ignored
    slot = {}
    for k in range(32): slot[frozenset((s[2*k], s[2*k+1]))] = k
    n = 0
    for k in range(32):
        a, b = s[2*k], s[2*k+1]
        q = frozenset((swap(a), swap(b)))
        if q in slot and slot[q] == k + 1: n += 1
    return n
```

`T = W + X`. **Han's "six" is `W`** (his six pairs are 5需/6讼, 7师/8比, 11泰/12否, 13同人/14大有,
35晋/36明夷, 63既济/64未济 — all within C1 pairs). **Primary statistic: `X`** (cross-boundary
swap adjacencies, values 0..11 by §3.1). `W` is the premise check; `T`, `A` are descriptive.

### §2.2 Q-OY1 — H16 coset-0 slot spacing

```python
def qoy1_cosets(s):            # coset id per slot, from the slot's FIRST hexagram; consistency flag
    ids = [coset_id(s[2*k]) for k in range(32)]
    consistent = all(coset_id(s[2*k]) == coset_id(s[2*k+1]) for k in range(32))   # a theorem under C1 (§3.2)
    return ids, consistent
def qoy1_D(s):                 # PRIMARY: circular gap dispersion of the coset-0 slots
    ids, _ = qoy1_cosets(s)
    a = [k + 1 for k in range(32) if ids[k] == 0]                 # 1-based slots, ascending; |a| == 8 under C1
    gaps = [a[i+1] - a[i] for i in range(len(a) - 1)] + [32 + a[0] - a[-1]]   # 8 circular gaps, sum 32
    return sum((g - 4) ** 2 for g in gaps)
def qoy1_NSAME(s):             # descriptive: same-coset slot boundaries (label-free clustering)
    ids, _ = qoy1_cosets(s)
    return sum(ids[k] == ids[k+1] for k in range(31))
```

`D` ranges over 0 (perfectly regular, every gap 4 — Ouyang's "rotation" reading) to 504 (the eight
coset-0 slots consecutive). It is **label-free** (uses only membership in coset 0), **orientation-free**,
**rotation- and reflection-invariant on the slot circle**, invariant under complement (63 ∈ H16) and
under the 48-element bit-permutation symmetry group (a bit permutation commuting with `rev` maps
palindromes to palindromes and anti-palindromes to anti-palindromes, so it fixes H16 as a set). It
therefore cannot encode *which* slots KW uses — only how evenly the eight are spread — which is exactly
the property Ouyang's "placed first, rotated by eights" reading asserts.

**Why not the finding's item (ii), the mass-rank of KW's exact 8-subset among C(32,8) = 10,518,300
patterns:** the only instrument for C1–C5 mass (§4.2) yields ≈3.6×10⁷ weighted leaves per 2×10¹⁰
probes, i.e. ≈3 weighted leaves per pattern under a heavy-tailed weight law; per-pattern masses would
carry relative errors of order 100% and the rank would be noise. Pre-registering it would pre-register
an uninformative instrument. Items (i) per-slot occupancy and (iii) the coset-id string distribution are
kept as **descriptive outputs** (§7.5), not tests.

## §3 Facts fixed by the hexagram set alone (checked; `DEFCHECK=PASS`)

These are properties of the 64 hexagrams and of the C1 pairing, not of KW's order. They decide the
C1 half of the independence question **by theorem**, before any population is consulted.

### §3.1 Q-992: `W` is forced to 6 by C1; `X` is not forced

- `swap` commutes with `partner` (`swap(rev h) = rev(swap h)`, `swap(comp h) = comp(swap h)`, and
  `rev h = h ⇔ rev(swap h) = swap h`), so swap maps C1 pairs to C1 pairs. The 32 pairs split into:
  **6 pairs with `swap(a) = b`** — `(2,16) (5,40) (7,56) (21,42) (23,58) (47,61)` — exactly the
  hexagrams built from two reversal-invariant trigrams (乾坤坎离), where swap coincides with 復 (Han's
  own remark, read note line 72); **4 swap-fixed pairs** — `(0,63) (9,36) (18,45) (27,54)`, the 八純卦;
  **22 pairs forming 11 couples** P ↔ Q with both hexagrams of P mapping into Q.
- Hence **every C1-respecting ordering has `W = 6`**, whichever of the 32!·2³² arrangements it is.
  Han's six is a C1 consequence. The measurement lane confirms this on every population member it
  touches (§7.5 `Q992_W_CONST`), but the status "explained by C1" for `W` is settled here.
- A cross-boundary swap event can only come from a couple (P, Q) in adjacent slots; `swap`-partners
  are at Hamming distance 2, 4 or 6 (never 5), so **C2 never blocks one**. Given adjacency of a couple,
  the event holds **iff the two slots' orientation bits differ** (checked on all 11 couples, both
  orders, all four orientations). So `X ∈ {0..11}`, and under the pair-only null `X` has the exact law
  of §4.1.

### §3.2 Q-OY1: the coset per slot is a C1 theorem; C4 pins one coset-0 slot

- `h ⊕ rev h` is a palindrome and `h ⊕ comp h = 63`, both in H16, so both members of a C1 pair lie in
  one coset (`ouyang1993_ch4_check.py` H1/H2). Four cosets, eight pairs each; `(63, 0)` is in coset 0,
  so **C4 forces slot 1 to be a coset-0 slot**. Because `D` is rotation-invariant on the slot circle,
  this pin does not change its null law: a uniformly random 7-subset of {2..32} with slot 1 added has
  the same `D`-law as a uniformly random 8-subset of {1..32} (the lane verifies both enumerations agree
  exactly, §7.3).
- Elements of H16 have Hamming weight in {0, 2, 3, 4, 6}, so a **same-coset boundary never has
  transition distance 1 or 5**; C5's two distance-1 transitions must sit at different-coset boundaries.
  This is the one mechanism by which C2/C5 can shape the coset string, and it is weak; §4.2 measures
  whatever shaping exists rather than arguing about it.

### §3.3 What is therefore NOT forced, and is what gets tested

`X` (0..11) and `D` (0..504) both vary over the C1∩C4 space with the exact laws of §4.1, so a KW value
can be in a tail. Whether C2–C5 (and C6/C7) move those laws toward or away from KW's value is the
population question of §4.2–4.3.

### §3.4 The check script

`review_2026_09_27/prereg_qoy1_q992_defcheck.py` (committed beside this file; it is the scratchpad
`prereg_defcheck.py` of the freezing session) prints the fifteen `PASS` lines behind §3.1–3.2, the
toy brute-force of the §4.1 law at (n, m) = (5, 2) and (7, 3), and `DEFCHECK=PASS`. It never indexes
`verify.KW`; its random orderings use seed `20261009` and start with `(63, 0)`.

## §4 Null populations — EXISTING instruments only, each named with its limits

No new enumeration. Three populations, two of them exact. The 13,320-record `solutions.bin` and the
560T canonical sets are **excluded**: they are budget-truncated DFS prefixes in a fixed traversal
order, which SPECIFICATION.md §C3 already flags as "not like-for-like" with any null.

### §4.1 N0 — the pair-only C1∩C4 null (TR-8 §2 null (b)) — EXACT

Uniform over the 31!·2³¹ orientation-explicit orderings of the 32 C1 pairs with `(63, 0)` in slot 1.
This is the null of `pair_null_gender_le2_exact()` (TR-8 Verification Guide) and of the TR-8 dof-matched
sampler (§3.2 of its prereg): "the truly undisputed structure". Both statistics have closed exact laws
here, so **nothing is sampled**:

- **`X`:** with n = 31 free slots and m = 11 couples, `P(X = x) = Σ_{j=x}^{11} (−1)^{j−x} C(j, x) C(11, j) (31−j)! / 31!`
  (inclusion–exclusion over couple-adjacency events; each event has probability (31−j)!/31! jointly for
  any j of them because the orientation coin halves the 2·(30)!/31! adjacency probability). `E[X] = 11/31`.
  Verified against brute force on the toys of §3.4.
- **`D`:** full enumeration of the C(31, 7) = 2,629,575 coset-0 slot sets containing slot 1 (and,
  as a check, of all C(32, 8) = 10,518,300 subsets; identical law by §3.2). Seconds in Python.

Cross-check (not the result): a seeded direct sampler of N0 (the `tests.py` `TestTr8DofSampler`
lineage: shuffle `king_wen_pairs()`, fair orientation coin per pair, slot 1 pinned), 10⁶ draws with the
`pairnull-crosscheck` seed of §6; each of `P(X = KW_X)` and `P(D ≤ KW_D)` must fall inside a 4σ
binomial band around the exact value, the H-b convention of the TR-8 prereg. Outside ⇒ implementation
bug, run halts.

### §4.2 N1 — the C1–C5 constraint-satisfying population (≈1.33×10³⁸ raw) — weighted-Knuth ESTIMATE

The project's only instrument for C1–C5 mass: `./solve --estimate-knuth N` with `SOLVE_KNUTH_SCORE=1`
and a per-leaf scorer, exactly the instrument of `LITERATURE_RULES_POPULATION_TESTS.md` (2×10¹⁰ probes)
and of the Davis waves. Leaves are orientation-explicit C1∩C2∩C4∩C5 completions with C3 ≤ 776 applied
at the leaf ("canonical leaves"); each leaf contributes its Knuth weight `W` to a value histogram of the
statistic (template: `score_dav2`, `[k*64]` bins, below/at/above masses with delta-method SE, Q-374).

**No-subsampling rule, stated rather than dodged:** the C1–C5 space cannot be enumerated (≈10³⁸); the
weighted-Knuth estimator is the project's established, exact-anchored (TR-11) instrument for it, and the
operator's instruction names the existing null models. The estimate is reported with its SE and with the
self-validation gate below; it is never called exact.

- **Probe count, frozen:** 2×10¹⁰ probes total = two halves of 1×10¹⁰, half A on the estimator's
  default seed constant (`SOLVE_KNUTH_SEED` unset = `0x243F6A8885A308D3`, the scoreboard's instrument),
  half B on the §6 `knuth-half-B` seed. The pooled histogram is the result; the halves are the
  replication gate.
- **Self-validation gate (Davis §2 precedent):** each half's printed `leaves_canonical_C1C5` estimate
  within **0.5 %** of 1.3287×10³⁸, and the pooled estimate within **0.2 %**. Fail ⇒ `VOID`.
- **Replication gate:** both halves must yield the same §5 verdict class for each query. Disagreement
  is reported as such and forces `VOID` (never resolved by picking a half).

### §4.3 N1′ — the same estimator under the C6/C7 pins (the "estimated C1–C7" population) — SECONDARY

`SOLVE_KNUTH_C67=1` (solve.c 41837: slots 24–27 fixed to KW's pairs, orientation free; the
SEARCH_SPACE_SIZE.md §C6/C7 instrument, 5×10¹⁰ probes on D32 in 2 h 04 min). Two halves of 5×10⁹ on
the §6 `knuth-c67-half-A/B` seeds; same self-validation form against that run's own published
C1–C7 estimate (≈5.2×10³¹; 1 % band, it is a smaller sample) and the same replication gate. **N1
governs the verdict; N1′ is an annotation**: C6/C7 are "descriptive, not explanatory" slot pins
(SPECIFICATION.md), and a C8 would stand beside them, not be derived from them. If N1′ changes the
verdict class, both are reported and the ASSESSMENT must say so in its first line for that query.

### §4.4 Reference (not a null): uniform random orderings of 64 and the corpus controls

- Uniform-64 (no C1) is reported for `W` only, to exhibit the C1-forcing contrast (`W` varies there).
  Not a test.
- **Corpus-control specificity** (Davis "candidate rule" gate): `X`, `D` evaluated on the Jing Fang
  Eight-Palaces order, the Mawangdui order and the Fu Xi order as held in `solve.py` (`_r7_jingfang`,
  `_r7_mawangdui`, and the Fu Xi sequence of the `_r7_*` family). These are non-C1 orderings: `W` need
  not be 6 and slot cosets need not be consistent (`qoy1_cosets` flag printed); their values are placed
  in the N1 histogram's tails exactly as KW's is. A control whose same-tail p is ≤ the per-query bar
  defeats specificity (§5.2).

## §5 Test, thresholds, family correction — FROZEN

### §5.1 Two-sided, both tails reported

For a statistic S with KW value `s`: `p_le = P(S ≤ s)`, `p_ge = P(S ≥ s)`, and
**`p_two = min(1, 2·min(p_le, p_ge))`** — the F5/TR-10/Davis convention. Under N0 these are exact
rationals (reported as rational and float). Under N1/N1′ the **operative** tail mass is the point
estimate **plus 3 × its delta-method SE** (conservative); if a tail's estimated mass is exactly 0 over
the whole run, the operative tail mass is `3 / L` where `L` is the run's printed count of canonical
leaves (rule of three). Direction is read from the smaller tail; for Q-OY1 Ouyang's claim predicts the
**low-D** tail, for Q-992 no direction is claimed — both are nevertheless two-sided.

### §5.2 Bars

- **Family:** this file registers **k = 2 primaries** (`X`, `D`). Family-wise α = **0.01**, Bonferroni:
  **per-query bar α_q = 0.005**. Percentile phrasing: a query is NOTABLE iff its KW value sits at or
  below the 0.25th or at or above the 99.75th percentile of the governing null (N1).
- **NOTABLE:** `p_two(N1) < 0.005`.
- **CANDIDATE C8 (for further scrutiny):** `p_two(N1) < 10⁻⁴` **and** corpus-control specificity:
  no control attains, in the same tail, an operative `p ≤ 0.005` (Davis §2 "candidate rule" gate).
- **Later queries:** a query added to this family after freeze is registered by a dated §9 addendum
  **before** its measurement and is measured at **0.01 / k_total** where k_total counts every primary
  registered in the family up to and including it (so the third query runs at 0.01/3). Earlier verdicts
  are **not** re-thresholded, but every ASSESSMENT line prints `FAMILY_K` as it stood. A statistic
  measured on KW without a prior addendum is exploratory and can never be NOTABLE or CANDIDATE under
  this file; it may only motivate a new addendum, which must then be measured on a fresh estimator
  seed.
- **No adaptive extension, no re-binning, no post-hoc statistic swap.** `W`, `T`, `A`, `NSAME`, the
  occupancy vector and the coset-string summaries are descriptive and carry no verdict.

### §5.3 The independence check (what "shaped by C1–C7" means here, operationally)

1. **C1 and C4 by theorem** (§3): `W` is constant; `X` and `D` vary with exact N0 laws. Both nulls
   already condition on C1∩C4, so every p-value is "conditional on C1".
2. **C2, C3, C5 by comparison of laws:** the lane prints the N0 law and the N1 histogram side by side
   for each statistic (`*_N0_HIST`, `*_N1_HIST`) and `E_N0`, `E_N1`. A visible shift says C2–C5 shape
   the statistic regardless of KW. The verdict then uses N1 (the population a C8 would be added to),
   and N0 supplies the annotation:
   - `INDEPENDENT_OF_C2_C5` iff `p_two(N0) < 0.005` **in the same tail** as the N1 result;
   - `C2_C5_CONDITIONAL` iff `p_two(N1) < 0.005` but `p_two(N0) ≥ 0.005` — the rarity exists only
     relative to the C2–C5-shaped population;
   - `EXPLAINED_BY_C2_C5` iff `p_two(N0) < 0.005` but `p_two(N1) ≥ 0.005` — the pair-only rarity is
     absorbed by constraints already published.
3. **C6/C7 by N1′** (§4.3): annotation only.

### §5.4 Verdict table — per query, mutually exclusive, jointly exhaustive, applied in this order

| verdict token | condition |
|---|---|
| `VOID` | any gate fails: `Q992_KW_W ≠ 6` (premise/definition mismatch — investigate, never re-define); `QOY1_KW_COSETS_CONSISTENT ≠ YES`; the two-language gate (§7.2) fails; the N0 sampler cross-check (§4.1) is outside its band; a self-validation or replication gate (§4.2) fails; `BINARY_FRESH ≠ FRESH`; the §9 instrument pin is missing |
| `FORCED` | the statistic is constant over every N1 leaf (`min == max`) — reported as EXPLAINED_BY_EXISTING (constraint consequence); expected for `W` only, and `W` is not a primary |
| `CANDIDATE_C8` | `p_two(N1) < 10⁻⁴` and specificity passes; carries the §5.3 annotation |
| `NOTABLE` | `p_two(N1) < 0.005` and not CANDIDATE (including a CANDIDATE-level p that fails specificity — then `SPECIFICITY=FAIL` is printed) |
| `EXPLAINED_BY_EXISTING` | `p_two(N1) ≥ 0.005` and `p_two(N0) < 0.005` |
| `UNINFORMATIVE` | `p_two(N1) ≥ 0.005` and `p_two(N0) ≥ 0.005` — "flat is a result" |

## §6 Seeds — FROZEN AND MATERIALIZED

Convention (A-4): uint64 = first 8 bytes, big-endian, of `sha256(<ASCII string>)`; the date token
`2026-10-09` is permanent. Re-derive with
`python3 -c "import hashlib,sys; [print(s, int.from_bytes(hashlib.sha256(s.encode()).digest()[:8],'big')) for s in sys.argv[1:]]" <strings>`.

| purpose | ASCII string | uint64 |
|---|---|---|
| N1 half A | *(none — estimator default constant `0x243F6A8885A308D3`, `SOLVE_KNUTH_SEED` unset)* | 2611923443488327891 |
| N1 half B | `ROAE-QOY1-Q992-2026-10-09/knuth-half-B` | 8087609961813646905 |
| N1′ half A | `ROAE-QOY1-Q992-2026-10-09/knuth-c67-half-A` | 7944743365876395449 |
| N1′ half B | `ROAE-QOY1-Q992-2026-10-09/knuth-c67-half-B` | 15064022667821298811 |
| N0 sampler cross-check | `ROAE-QOY1-Q992-2026-10-09/pairnull-crosscheck` | 4538186694822709970 |
| two-language gate random orderings | `ROAE-QOY1-Q992-2026-10-09/gate-random-c1-orderings` | 2192090898449286487 |

No seed has been used. The estimator is unbiased for any seed; the seeds exist so the runs are
reproducible and disjoint.

## §7 What the measurement lane must do and output — FROZEN

### §7.1 Implement (single-file rule: C in `solve.c`, Python in `solve.py`, tests in `tests.py`)

- `solve.py`: `q992_W/X/T/A`, `qoy1_cosets/D/NSAME` **byte-for-byte as in §2**, plus
  `QOY_KW_EXPECTED` filled by the lane — **that fill is the first evaluation on KW and is the
  measurement's date**; it happens only after this file is committed and the §9 pin is written.
- `solve.c`: scorer `score_qoy` under `SOLVE_KNUTH_SCORE_QOY=1`, template `score_dav2`: value
  histograms for `X` (bins 0..11), `D` (0..504), `NSAME` (0..31), `W` (0..31), `A` (0..11), plus the
  32-bin weighted coset-0 occupancy vector; below/at/above masses with the Q-374 squared-weight twins;
  per-leaf `W == 6` assertion counter (`Q992_W_CONST`); coset-consistency assertion counter.
  Estimator-only, sha-neutral: zero effect on enumeration paths (`tests.py` canonical-sha gates must
  stay green).
- `--qoy-verify <seq-source>`: the two-language gate — `solve.c` must reproduce `solve.py`'s output
  byte-for-byte on KW **and** on 10⁵ random C1∩C4 orderings drawn with the `gate-random-c1-orderings`
  seed. **Mutant leg (gates must discriminate):** a build with the within/cross parity swapped
  (`i even ↔ i odd` in `X`) must make the gate print `QOY_VERIFY=FAIL`.
- `tests.py`: the regression `TestQoyScorer` with the above two legs; red on the mutant.

### §7.2 Pre-run gates, all printed as `KEY=value`

`PREREG_SHA_VERIFIED=PASS` (the lane's `sha256sum` of this file equals the `PREREG_LOCK_LEDGER.txt`
entry); `DEFCHECK=PASS` (re-run §3.4); `QOY_VERIFY=PASS`; `QOY_VERIFY_MUTANT=FAIL`; `BINARY_FRESH=FRESH`;
`Q992_KW_W=6`; `QOY1_KW_COSETS_CONSISTENT=YES`; `INSTRUMENT_PIN=<commit>`; input hashes `VERIFY_PY_SHA256`,
`SOLVE_C_SHA256`, `SOLVE_PY_SHA256`, `SOLVE_BIN_SHA256`, `PUBLIC_HEAD`, `PRIVATE_HEAD`.

### §7.3 N0 exact

`Q992_N0_LAW` (12 rationals), `Q992_N0_E=11/31`, `QOY1_N0_LAW` (support and rationals over C(31,7)),
`QOY1_N0_C32_8_AGREES=YES` (the C(32,8) enumeration gives the identical law), `*_N0_P_LE`, `*_N0_P_GE`,
`*_N0_P_TWO` as rational and float, `N0_SAMPLER_CROSSCHECK=PASS` with the two observed counts and bands.

### §7.4 Runs

Build: `gcc -O2 -fopenmp -o solve solve.c -lm -lpthread -lz` (the freshness script's line; `-fopenmp`
mandatory). Then, each with `ulimit -s unlimited` and `SOLVE_KNUTH_SCORE=1 SOLVE_KNUTH_SCORE_QOY=1`:

```
SOLVE_THREADS=<T>                                   ./solve --estimate-knuth 10000000000   # N1 half A
SOLVE_THREADS=<T> SOLVE_KNUTH_SEED=8087609961813646905  ./solve --estimate-knuth 10000000000   # N1 half B
SOLVE_THREADS=<T> SOLVE_KNUTH_C67=1 SOLVE_KNUTH_SEED=7944743365876395449  ./solve --estimate-knuth 5000000000   # N1' half A
SOLVE_THREADS=<T> SOLVE_KNUTH_C67=1 SOLVE_KNUTH_SEED=15064022667821298811 ./solve --estimate-knuth 5000000000   # N1' half B
```

Unfiltered stdout+stderr of every run is archived under
`review_2026_09_27/qoy1_q992/RECORDED_<date>/` together with `TOKENS.txt`. Preserve runs: never
overwrite a previous RECORDED directory.

### §7.5 Result tokens (per query Q ∈ {Q992, QOY1}; statistic S = X or D)

`Q_KW_VALUE`, `Q_N1_PROBES=20000000000`, `Q_N1_SEEDS`, `Q_N1_HIST` (full weighted histogram, both
halves and pooled), `Q_N1_E`, `Q_N1_P_LE`, `Q_N1_P_GE`, `Q_N1_SE_LE`, `Q_N1_SE_GE`, `Q_N1_P_TWO_OPERATIVE`,
`Q_N1_SELFVALIDATION=PASS|FAIL` (with the three estimates and deviations), `Q_N1_REPLICATION=PASS|FAIL`
(with both halves' verdict classes), the same `Q_N1C67_*` family, `Q_CONTROL_JINGFANG`, `Q_CONTROL_MAWANGDUI`,
`Q_CONTROL_FUXI` (value and same-tail operative p), `Q_SPECIFICITY=PASS|FAIL|NA`, `Q_INDEPENDENCE`
(§5.3 token or `NA`), `Q_VERDICT` (§5.4 token). Descriptive: `Q992_KW_T`, `Q992_KW_A`, `Q992_W_CONST=YES|NO`
(every N1 leaf had W = 6), `Q992_W_UNIFORM64_HIST` (uniform-64 reference, 10⁶ draws, any seed, labelled
reference), `QOY1_KW_NSAME`, `QOY1_N1_NSAME_HIST`, `QOY1_N1_OCCUPANCY` (32 weighted probabilities),
`QOY1_KW_COSET_STRING` (must equal the finding's `03223023033110023211211332012100` under the
`key=min` labelling — a transcription check, printed as `QOY1_COSET_STRING_MATCHES_FINDING=YES|NO`).
Family: `FAMILY_K=2`, `FAMILY_ALPHA=0.01`, `PER_QUERY_BAR=0.005`, `CANDIDATE_BAR=1e-4`.

### §7.6 [cost section omitted from the public copy]

## §8 What each outcome will mean — decided before it exists

- **`CANDIDATE_C8`** means exactly: "a pre-registered statistic places KW at operative `p_two < 10⁻⁴`
  in the C1–C5 population and the controls do not share the tail." It is a **candidate for further
  scrutiny**, not a constraint. Promotion requires, in order: (a) Fable review of the recorded run;
  (b) **replication by an exact instrument** (a DP or SAT count over C1∩C2∩C4∩C5 of the orderings at
  or beyond KW's value — the Knuth estimate alone never promotes); (c) an operator decision;
  (d) only then edits to the published surfaces a constraint touches — SPECIFICATION.md's constraint
  list and the ≈5.2×10³¹ C1–C7 figure, the TR-11/TR-12 counts and ladders, README, CITATIONS (Ouyang
  1993 / Han 1984 credit as the describers of the feature), the knowledge compiler's constraint set.
  **Nothing in this registration edits any of them.** A C8 would also be a KW-read slot statistic and
  must carry the same "descriptive, not explanatory" status language C6/C7 carry until a derivation exists.
- **`NOTABLE`** means: recorded in the ASSESSMENT with all tokens; eligible for an exact-instrument
  re-measurement under a new dated prereg; **no public claim** and no constraint language.
- **`EXPLAINED_BY_EXISTING` / `FORCED`** means: the observation is a consequence of C1–C5 (or of C1
  by theorem); the finding and the backlog row are closed with that sentence; CITATIONS may note that
  Ouyang/Han described a feature that C1–C5 already entail.
- **`UNINFORMATIVE`** means: KW is unremarkable in the pre-registered statistic under both nulls. This
  is published in the ASSESSMENT exactly as a NOTABLE would be. It is **not** evidence that Ouyang's
  or Han's readings are wrong — only that this statistic does not distinguish KW.
- **`VOID`** means: the instrument failed; written up in full as a failed instrument; re-running
  requires a new dated prereg (or a §9 annotation if the failure is a pure implementation bug fixed
  before any N1 number was read — the annotation must say which).
- **The one thing no outcome can do:** license the sentence "King Wen is explained by H16 / by
  trigram swaps." The strongest sentence any outcome supports is the population-conditional one above.

**Publish-regardless.** Every outcome is written to `roae-private/ASSESSMENT_2026_10_09.md` with the
full token set, the RECORDED directory path, and this file's sha256. Public text changes only after the
§8 chain for CANDIDATE, and never for the other outcomes beyond closing the Q-992 row and Q-OY1's
status note in the finding.

## §9 Amendment log — OPEN (dated annotations only; append below this line)

*(none at freeze)*

## §10 Freeze procedure and the frozen-bytes identity

1. The orchestrator commits this file (and `prereg_qoy1_q992_defcheck.py`) to `roae-private`
   **before** the measurement lane is briefed; the commit message names this file and the token below.
2. Immediately after the commit, the orchestrator appends the committed bytes' digest to
   `docs/data/PREREG_LOCK_LEDGER.txt` in the ledger's existing form:
   `sha256sum review_2026_09_27/PREREG_QOY1_Q992_2026_10_09.md >> docs/data/PREREG_LOCK_LEDGER.txt`
   (the ledger line is the frozen identity; this file cannot contain its own hash).
3. The measurement lane's first act is `sha256sum` of this file compared with that ledger line
   (`PREREG_SHA_VERIFIED=PASS`, §7.2); a mismatch halts everything.
4. §9 annotations are appended **after** that comparison and are therefore outside the frozen bytes
   by construction; the ASSESSMENT cites both the frozen digest and the digest of the annotated file.

PREREG_QOY1_Q992=FROZEN
