# VERIFY.md — the independent second instruments (`verify.py`, `verify.c`)

*Companion to `verify.py` (and its C-side sibling `verify.c`). Addresses the
single-instrument caveat raised in
[TR-11 §10(vi)](../reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md): "at full
31 … the full-31 integer will initially rest on a single instrument." (That
caveat's instrument half is now closed: on 2026-07-25 `verify.c --ie-count`
performed the independent full-scale recomputation — exact match. See the
closing section.)*

`verify.py` is a genuinely **independent** second opinion on the ROAE results.
It is standard-library-only Python, imports **none** of `solve.c` / `solve.py` /
`roae.py` / `sat.py`, and rebuilds every quantity **clean-room from the published
mathematical definitions** (SPECIFICATION.md constraints C1–C5, `rev`/`comp`/
`partner`, the 48-element symmetry group; TR-11's reduced-rung tables). Its
counting method is deliberately **different** from `solve.c`'s symmetry-quotient
DP, so a conceptual bug in the quotient method would not be shared.

It verifies published results on **three** surfaces — records, exact counts,
and (artifact-consistency only) completed-run certificates:

| mode | what it checks |
|---|---|
| `python3 verify.py [solutions.bin]` | the RECORDS: re-decodes every record and re-checks C1–C5 (C4 in its **oriented** spec form) + record-format conformance + order/dups. See §"What the records path actually enforces" below |
| `python3 verify.py --enumerate-reference N` (2≤N≤9) | small-n completeness: brute-forces the reduced N-pair problem two independent ways (exhaustive vs prune-as-you-go) and asserts identical solution sets |
| `python3 verify.py --recount` | the exact COUNTS: independently reproduces the small-n structural facts, the reduced-rung C1∩C2∩C4 union counts, **and (since 2026-07-21) the C5 ladder rungs n = 9/13/16** (TR-11 §4b) — each rung's budget `B0` re-derived independently by TR-11 §5's first-completion DFS, then counted by a plain budgeted (mask, last, p) DP — and prints a match table |
| `python3 verify.py --recount-fiber` | (added 2026-08-01) the **orientation fiber** of [TR-1](../reports/TR1_EIGHT_CENTURIES_MEASURED.md) §7 — the frozen dispositive null against which the eleven-functional battery's exact p-values are computed, so it is the denominator every verdict in that table rests on. A transfer DP over King Wen's *own* pair sequence, varying only the 32 within-pair orientations, with the boundary budget `B0` recomputed from KW rather than copied from the report. Reproduces **1,720,320** (C4-oriented), **983,040** (pair-only C4, flipped opening), **2,703,360** (their sum), the stated `3·5·7·2¹⁴` factorization, and the forced/free bit structure (slot 30 is the only additionally forced bit — 30 of 31 vary). Two facts make this exact rather than a 2³¹ search, and the mode re-derives both instead of assuming them: within-pair distances are orientation-invariant, so C5 reduces to the 31 between-pair values; and `C3 = 16 + 8·G` with the orientation bits cancelling in `G`, so C3 is **constant** across the fiber and constrains nothing. Instant. Reads no files |
| `python3 verify.py --recount-gender-null` | (added 2026-08-01) TR-8 §Commands' **exact pair-null Schulz-gender figure** `P(rc4_violations ≤ 2) = 47/445740`. Both prior implementations of this rational lived inside `solve.py`, so the figure was single-FILE even though it was described as verified two ways; this is the genuinely independent second instrument. The functional is rebuilt from the **published** definition (SOLVE_C_CLI.md §`--rc4b-verify`; Schulz 1990 motif 2 via Cook 2006) rather than from `solve.py`'s code, and the reading is gated on King Wen's published anchors (2 violations, class positions 25/26). The 32!·2³² null is then solved **exactly two ways** — a multivariate-hypergeometric closed form, and a slot-by-slot DP over pair-type states that never uses the closed form's decomposition — cross-asserted term-by-term, in `fractions.Fraction`. No sampling. Instant. Reads no files |
| `python3 verify.py --check-certificate DIR` | a completed f1c5 run's ARTIFACTS (run.out per-layer certificate rows, manifest, preserved digests) against structural identities and independently derived quantities. Recomputes **nothing** — internal-consistency and digest-integrity only, per its docstring |
| `./verify --check-layers DIR [max_k] [run.out]` | (C side, NEW 2026-07-23; orbit-weighted mass added same day) the **on-disk layer files themselves**, read against [F1C5_LAYER_FORMAT.md](F1C5_LAYER_FORMAT.md) with no `solve.c` code: header/`pl_hash`/`b0` vs the manifest, `masks`/`off` layout, per mask popcount/range/**canonicity** (numeric minimum of its orbit), and per entry the key packing, `rid < R`, ascending order, nonzero value, and the **sum invariant** (rid mixed-radix digits sum to `k`). With the TR-11 §2 group **derived independently in-file** (the 48 `C_{S6}(rev)` bit-perms → 24 induced pair-permutations → the run's distinct restricted perms, closure-verified), it re-derives the §Reading-recipe **orbit-weighted mass** `Σᵢ sᵢ·(|G|/|stab(maskᵢ)|)` from the layer bytes at **every** layer and, when a `run.out` is given, compares it to `solve.c`'s reported `mass=` per layer — the full-scale counterpart of the small-`k` plain-DP mass check. Entry-streaming and `O(nm)` memory, so it reaches every layer on disk — and at the final layer (full-31) the summed value bytes must equal the published 39-digit count and be `≡ 0 (mod 24)`. Handles v1 (raw) and v2 (per-block zlib). `--check-layers-selftest` synthesizes v1+v2 fixtures, a corrupted case, a **non-trivial-stabilizer** mass fixture (pair-orbit `3.0`, `|stab|=2`, orbit `3 < |G|=6`), a wrong-reported-mass case, and a non-canonical-mask case — no real data needed. **Campaign-VM tool** (run where the layers live). |
| `./verify --check-g-ladder FDIR GDIR [max_k]` | (C side, NEW 2026-07-24) the **g-ladder layer files** (`--kc-g-build` artifacts: exact count-from-any-prefix, the rank instrument's substrate), read against [GT_LADDER_FORMAT.md](GT_LADDER_FORMAT.md) with no `solve.c` code. Structural: `F1C5GLY1/2` magic+version, `g_manifest_v1`, header fields, v1/v2 file-size formulas, layout, mask **canonicity**, per-entry key packing / ascending order / `rid < R` / **sum invariant** / nonzero values, the **stored-domain rule** (`last` in the mask's pair-element set), and the exact **seed** (2n sorted pair elements, `rid = R−1`, all values 1) and **anchor** (layer 0 = `g(0)`) content. Identity: the **f·g cut identity** — `Σ orbit(mask)·f(s)·g(s) = N` at **every** layer, with `N` re-derived from the f ladder's final-layer value bytes (and, at full-31, checked against the published count). An independent implementation of the same gate `solve.c --kc-g-check` asserts — a true second instrument for the g ladder. **Campaign-VM tool** |
| `./verify --check-t-ladder FDIR TDIR [max_k]` | (C side, NEW 2026-07-24) the **t-ladder layer files** (`--kc-t-build` artifacts: exact search-tree node counts, `t(s) = 1 + Σ_c t(s∘c)`), against [GT_LADDER_FORMAT.md](GT_LADDER_FORMAT.md). Structural: `F1C5TLY1/2` magic, `t_manifest_v1`, **byte-exact f-geometry mirror** (masks/off/keys identical to the f layer at every `k`), every value ≥ 1, seed layer all 1s, anchor singleton. Identity: `M_j` (orbit-weighted f masses = exact # valid depth-`j` prefixes) re-derived from the f ladder's bytes, `M_0 = 1`, then the **f·t node identity** `Σ orbit·f·t = Σ_{j≥k} M_j` at **every** layer (the backward recurrence unfolded, `S_k = S_{k+1} + M_k`) plus `t(root) = Σ M_j`. The independent counterpart of `solve.c --kc-t-check`. `--check-gt-selftest` covers both modes: it brute-forces a complete, consistent f+g+t fixture from the published definitions on a **non-trivial instance** (the 6-pair orbit `{10,15,20,23,27,29}`, transitive restricted group `geff=6`, budget spanning 3 classes incl. `d=6`, **252 dead-end states**, anchors `N=96` / `t(root)=1285` cross-derived by an independent Python implementation), round-trips v1 and v2, and asserts five corruption legs FAIL (g value tamper, t value tamper, t geometry tamper, g/t magic confusion, g seed tamper) — no real data needed |
| `python3 verify.py --check-null-g` | the **reference distribution for C3**: the exact G-distribution under the C1&C4 null (12 cross-couples + 7 self-pairs into 31 slots), gated against `total == 31!`, support `[12,228]`, `E[G] == 128` (also true DP-free by linearity, since `E\|i−j\| = (n+1)/3` for a uniform 2-subset of `{1..n}`), and `P(G ≤ 95) == 641983711307479/7919632354008375`. Since `C3 = 16 + 8·G`, this is the baseline any "KW's C3 is unusual" claim must beat. Accumulates **open-couple counts, not ± slot indices** — deliberately different arithmetic from `solve.c`'s G channel, so agreement is evidence rather than tautology. **Scope: C1&C4 only** — no C2, no C5, no budget truncation; not like-for-like against ceiling-tie shares measured over conditioned enumerated populations. Reads no files |
| `python3 verify.py --check-layer-sidecars DIR` | the per-layer SIDECARS (`f1c5_layer_stats_KK.json`): two *independent* marginal decompositions (`marginal_last_mass` by terminal pair, `marginal_rid_mass` by boundary-residue id) each summing to `mass_total`; histogram totals against `n_entries` / `n_masks − n_empty_masks`; `mass_total` inside its own value-histogram bounds; `n`/`b0`/`pl_hash` agreement with the manifest; and the layer-to-layer **sha256 lineage chain** (`input_sha256_decompressed[k] == own_sha256_decompressed[k−1]`). Reads **only** the small JSON sidecars — no layer-file I/O, so it costs nothing and works long after the campaign VM is gone. Recomputes no masses |

The C-side sibling, **`verify.c`** (same independence discipline: no `solve.c`
header, no shared table, no copied constant), recomputes the engine's per-layer
*plain* masses with a plain, non-quotient layered DP **on the true full-31
instance** and compares against the run.out rows — agreeing at every layer
within its memory reach (the plain state space grows ~16× per layer, so it
exhausts long before k = 31; it is corroboration, **not** the independent
full-scale recomputation §10(vi) asks for).

## The independent method (`--recount`)

Two methods, deliberately unlike the symmetry-quotient DP:

1. **Exhaustive backtracking** (no memoization, no DP table, no symmetry):
   place the pairs one at a time in every order and both orientations, prune
   only on the published boundary rule (Hamming distance ≠ 5), count the
   complete leaves. This is as primitive and independent as it gets, and is used
   both for the small-n `--enumerate-reference` check and to cross-validate the
   recurrence.
2. **Plain layered subset DP** (a *counting recurrence*): state = `(placed-pair
   mask, last-exit hexagram)` → exact big-integer count; a transition places any
   unused pair in either orientation iff the boundary distance ≠ 5 (C2). It
   stores **every** mask (no canonical-representative collapse), so a
   quotient/canonicalization bug **cannot** be shared with `solve.c`. Only two
   popcount layers are ever live; peak memory is ~24 MB.

All arithmetic is exact Python big integers. The two methods are shown to agree
exactly on small prefixes (k = 3..7) before the recurrence is trusted at U1/U2/U3.

## Match table (from `python3 verify.py --recount`)

Every quantity below carries a **published** value and an **independent** value
computed by the method named; ✓ = exact match.

### Target 1 — small-n structural facts

| quantity | published | independent | match | method |
|---|---|---|---|---|
| Canonical partner-pairing == 32 published KW pairs | (equal sets) | equal | ✓ | derive `partner()` orbits, compare |
| KW is a permutation of {0..63} | true | true | ✓ | flatten published pair table |
| C1: every KW pair is {h, partner(h)} | true | true | ✓ | recompute `partner()` |
| Within-pair distance multiset (32 pairs) | {2:12, 4:12, 6:8} | {2:12, 4:12, 6:8} | ✓ | popcount within each pair |
| XOR-product set {h ⊕ partner(h)} | {12,18,30,33,45,51,63} | same | ✓ | XOR within each pair, dedup |
| KW difference-wave D(S), 63 transitions (C5) | {1:2,2:20,3:13,4:19,6:9} | same | ✓ | popcount along KW |
| KW between-pair boundary multiset, 31 boundaries (reduced-C5 B0) | {1:2,2:8,3:13,4:7,6:1} | same | ✓ | popcount at 31 boundaries |
| KW C3 complement-distance sum (×64 integer form) | 776 | 776 | ✓ | Σ\|pos(h)−pos(comp(h))\| |
| C2: no distance-5 adjacency in KW | true | true | ✓ | popcount |
| C4: KW starts (63, 0) | true | true | ✓ | read s₀,s₁ |
| \|symmetry group C_S₆(rev)\| | 48 | 48 | ✓ | keep perms commuting with reversal |
| group fixes {0,63} + is Hamming-isometric | true | true | ✓ | check on all/subset |
| distinct induced pair-permutations (record group S₄) | 24 | 24 | ✓ | induce on 32 pairs, dedup |
| King Wen orbit size at record level (KW + twins) | 24 | 24 | ✓ | apply 48 bit-perms, canonicalize |
| King Wen record-level twin count | 23 | 23 | ✓ | orbit − KW |

### Target 2 — reduced-rung C1∩C2∩C4 union counts (TR-11 Verification Guide §4a)

| rung | published | independent | match | method |
|---|---|---|---|---|
| U1 = 9 pairs {3.0,3.1,3.2}@0 | 63,366,144 | 63,366,144 | ✓ | counting recurrence |
| U1 (same), second method | 63,366,144 | 63,366,144 | ✓ | raw exhaustive backtracking |
| U2 = 12 pairs {6.0,6.1}@0 | 1,961,990,553,600 | 1,961,990,553,600 | ✓ | counting recurrence |
| U2 closed form 12!·2¹² | 1,961,990,553,600 | 1,961,990,553,600 | ✓ | closed form |
| U3 = 13 pairs {3.0,4.0,6.2}@63 | 39,239,811,072,000 | 39,239,811,072,000 | ✓ | counting recurrence |

**Result: every quantity with a published target reproduced EXACTLY, 0 mismatch**
(rerun `python3 verify.py --recount` to regenerate the full table; exit 0 requires
every published target to match). Peak RSS ~24 MB for the tables above; wall time
dominated by the 63 M-leaf U1 backtracking and the n = 16 budgeted DP.

### Target 3 — reduced-rung C1∩C2∩C4∩**C5** ladder (TR-11 §4b; added 2026-07-21)

| rung | published | independent | match | method |
|---|---|---|---|---|
| n=9 `{3.0,3.1,3.2}@0`, B0 = (2,5,0,2,0) | 26,112 | 26,112 | ✓ | B0 re-derived by §5 Step-1 DFS, then plain budgeted (mask, last, p) DP |
| n=13 `{3.0,4.0,6.2}@0`, B0 = (1,6,0,6,0) | 2,063,395,607,040 | 2,063,395,607,040 | ✓ | same |
| n=16 `{4.0,6.0,6.1}@0`, B0 = (1,8,1,6,0) | 267,765,117,419,520 | 267,765,117,419,520 | ✓ | same |

The larger rungs (n = 18–28) remain out of pure-Python reach on a light host
(the budget dimension multiplies the state count by thousands); they are covered
by the engine's own 4/4 cross-mode ladder (TR-11 §8), not by this instrument.

## Two published-recipe defects this instrument surfaced (both fixed)

1. **The reduced-C5 rung definition was under-specified (F-3, fixed in TR-11
   v1.2, 2026-07-20).** As originally published, the recipe said to retain
   states whose boundary multiset was a *sub-multiset* of King Wen's — under
   which the 13-pair rung counts 38,492,859,594,240, **not** the published
   2,063,395,607,040 — and the per-rung target budget vector lived only in
   `solve.c`'s private `f1c5_unions[]` table. TR-11 §4b/§5 now publish the
   ordered pair lists, the per-rung `B0` targets, and the exact-match rule; the
   Target-3 checks above run against the corrected public recipe, with `B0`
   re-derived rather than copied.
2. **The full-31 `B0`-coincidence claim was false (fixed in TR-11 v1.8,
   2026-07-21).** TR-11 §5 claimed the Step-1 first-completion DFS reproduces
   King Wen's boundary multiset at full 31. Both this file's Python and
   `verify.c`'s C implementation of the published recipe return (2,7,13,8,1)
   against KW's (2,8,13,7,1): at full 31 the budget is **defined** as KW's
   multiset, not derived via Step 1. No published number was affected — the
   engine uses KW's multiset — but the documented derivation was wrong, and an
   independent instrument is what caught it.

## What the records path actually enforces (A3 audit, 2026-08-01)

An adversarial audit asked a narrow question of `verify.py [solutions.bin]`: for
each of C1–C5, is the predicate the code tests **logically equivalent** to the
formal statement in SPECIFICATION.md, or has it drifted? Three defects in the
instrument itself, all now fixed:

1. **C4 was only half-checked (the serious one).** SPECIFICATION.md C4 is two
   conjuncts — `s₀ = 63` **and** `s₁ = 0` — but the code tested only the *pair
   index* (`first_pair != START_PAIR`), never the orientation bit. Because the
   2026-07-26 retraction established that complementation `x ↦ x ⊕ 63` is an
   exact symmetry of C1∩C2∩C3∩C5 (machine-checked, `lean/KingWen.lean`), **no
   other check in the file could compensate**: a record encoding `comp(KW)` —
   which opens (0, 63) — passed C1, C2, C3 and C5, passed the index-only C4, and
   printed `VERIFY PASS`. The check had been silently leaning on the
   enumerator's hardcoded `seq[0]=63; seq[1]=0`, which is precisely the
   invariant an *independent* verifier is not entitled to assume — its job is to
   catch enumerator bugs, not inherit them. A correct oriented predicate already
   existed in `--recount-finite`'s `classify()`, but not on the records path.
   Now tested in spec form. *(No canonical artifact was ever affected: `solve.c`
   pins the orientation, and the format's dedup rule keeps the lexicographically
   smallest orient variant. The defect was a latent false-PASS, not a false
   result.)*
2. **The reference tables were self-verifying.** `PAIRS`, `KW_DIST` and
   `KW_COMP_DIST` are all derived from the `KW` literal at the top of the file,
   so a corrupted `KW` table would silently redefine C1 and C5 and then check
   every record against the corruption — accepting violating records and
   rejecting compliant ones, consistently. The rule-derived cross-checks existed
   but were reachable only via `--recount`. They are now an **import-time gate**
   (`_verify_tables_against_rules()`): KW is a permutation of {0..63}; `PAIRS`
   equals the `partner()`-derived canonical pairing; every pair is
   partner-exact; the difference-wave multiset equals SPECIFICATION.md C5's
   literal `{1:2, 2:20, 3:13, 4:19, 6:9}`; `cd(KW) = 776`. Explicit raises, not
   `assert`, so they survive `python3 -O`.
3. **Reserved fields were unchecked.** SOLUTIONS_FORMAT.md specifies `bit 0:
   unused, always 0` per record byte, and header bytes 16–31 `MUST be zero`.
   Record bit 0 is masked out of the canonical sort key (`& 0xFC`) but *does*
   participate in the full-byte dedup tie-break, so a set bit 0 breaks
   byte-exact reproducibility between two otherwise-conformant implementations.
   Both are now counted as format errors — counted rather than raised, so the
   record-level verdicts are still reported alongside them.
4. **King Wen's presence was print-only.** `King Wen: YES/No` was never folded
   into the exit status, so on a complete canonical its absence — a real defect
   — was visible only to an operator reading the line. The default is correct
   and unchanged (an individual shard legitimately need not contain KW); the
   new **`--expect-kw`** promotes presence to a hard requirement for runs over a
   complete canonical.

Found sound and unchanged: **C2** (all 63 linear transitions, correct range, no
spurious wrap-around); **C3** (`Σ|pos(v) − pos(v⊕63)| ≤ 776`, the ceiling
anchored to the spec literal); **C5** (exact multiset equality, which also
forces the d=5 count to zero); **C1**'s permutation property (`pidx < 32` +
each pair used exactly once + disjoint partner-pairs); header/framing; the
chunk-boundary stitching (adjacent-pair sortedness ⇒ global sortedness, no
off-by-one at the seams); the gzip path; and the `& 0xFC` dedup key, which is
correct rather than over-strict because the format collapses orientation
variants by design. `verify.c` is unaffected — it has no records path.

All four fixes are covered by regression tests in `tests.py`: `comp(KW)` must
FAIL on C4 **alone** (it passes C1/C2/C3/C5 — a live executable demonstration
of the Complement Z₂ symmetry theorem), a bit-0-tampered record and a nonzero
header reserved field must FAIL on format, `--expect-kw` must fail when King
Wen is absent, King Wen itself must still PASS, and the table gate must reject
a corrupted `KW`. That last fixture is chosen so **only** the C5 gate can catch
it: swapping pair-blocks 1 and 2 leaves cd exactly 776 (the C3 anchor is
blind), leaves the pairing set unchanged (the C1 gate is blind), and introduces
no d=5 transition (a C2-style check is blind).

*Audit provenance: the same drift was found independently twice — by Fable on
2026-07-30 (fixes held for the commit window) and again by a fresh probe on
2026-08-01 that was given no knowledge of the first. Two independent
rediscoveries of the same defect set, with the second adding the header
reserved-field item, is the cross-model control the review protocol asks for.*

## The Route B engine: `verify.c --ie-count`

`./verify --ie-count` recomputes \|C1∩C2∩C4∩C5\| by classical signed inclusion–exclusion over
subsets of the 31 free pairs: N = Σ_S (−1)^(31−|S|) W(S), where W(S) counts repetition-allowed
31-step walks over S with the d ∈ {1,2,3,4,6} boundary predicate and class budgets capped at
KW's boundary multiset (2,8,13,7,1). DP state is `(last hexagram, budget vector)` — no mask,
<1 MB per thread. The 24-element record group enters only as a startup-re-verified
subset-enumeration lemma (W(gS) = W(S)); `--ie-no-quotient` disables it. Arithmetic: three
passes modulo the largest primes below 2⁶³ (Miller–Rabin-proven at startup), CRT-combined; on
small instances the mod-2⁶⁴ wrap pass cross-checks the mod-p path exactly. Spot-safe chunk
checkpointing (`--ie-checkpoint`); `--ie-negctl` is a must-differ negative control;
`--ie-probe NSAMP` sizes a full run. Validation ladder and the 2026-07-25 full-scale MATCH:
TR-11 §10(vi).

## Corroboration chain for the full-scale count

- **Independent full-scale recomputation (`verify.c --ie-count`, 2026-07-25).** A signed
  inclusion–exclusion transfer-walk over free-pair subsets (DP state `(last, budget)`, no mask
  — a different algorithm class sharing no code or machinery with `solve.c`) recomputed the
  full-31 integer via three Miller–Rabin-proven 63-bit prime passes, CRT-combined: **exact
  match**, with the mod-24 gate holding. This is the direct discharge of TR-11 §10(vi)'s
  instrument half; the items below are the (retained) corroboration that pre-dated it.

Tier-2 scope was intentional (per TR-11, the full 31-pair count is out of scope
here). The full-scale exact count
|C1∩C2∩C4∩C5| = 1,097,051,278,789,181,790,036,112,071,176,579,186,688 (TR-11 §9)
does **not** rest on this instrument. Its corroboration chain is:

- **Method-agreement at the reduced rungs (here).** An independent instrument,
  a different counting method (plain no-quotient recurrence + raw backtracking),
  and stdlib-only code reproduce the C1∩C2∩C4 unions, the C5 ladder rungs
  n = 9/13/16 (budgets re-derived), and every small-n structural fact exactly —
  validating the recursion and the pairing/symmetry machinery the full-scale
  run depends on.
- **The project's own two engines agree at every validated subset size (≤28
  pairs).** The in-RAM symmetry-quotient DP and the out-of-core streaming DP
  produce identical layer content and digit-identical totals at every validated
  subset size (24/25/27/28 pairs reproduced digit-for-digit, TR-11 §8;
  byte-identical files in those v1-format validation runs — under current
  defaults the two modes' files are content-identical but byte-different, per
  TR-11 §10(vi)'s precision note). At full 31 the in-RAM path is infeasible
  (TR-11 §6), so this agreement does **not** extend to full scale. The
  compiler / DFS lineages cross-check the enumeration side.
- **Per-layer mass agreement at full 31, within memory reach (`verify.c`).** A
  plain non-quotient DP reproduces the engine's per-layer plain masses on the
  true full-31 instance for every layer it can hold — exercising exactly the
  stabilizer bookkeeping TR-11 §2 flags as delicate.
- **The mod-24 free-action gate.** The free action of the order-24 record group
  forces N ≡ 0 (mod 24); the full-scale integer satisfies it exactly — a
  zero-code reader-side arithmetic check.
- **The Knuth estimator.** The exact full-scale integer falls inside the
  independent unbiased random-probe estimate's stated ±0.01% envelope (the
  0.0044% figure sometimes quoted is the estimate's five-sig-fig rounding gap,
  not a resolved estimator error).

Method-diverse agreement at Tier-2 here, the ≤28-pair two-engine equivalence,
the full-31 per-layer masses within `verify.c`'s reach, the mod-24 gate, and
the estimator together corroborate the full-scale count. TR-11 §10(vi)'s
instrument half is now discharged: the full-31 integer was independently
recomputed at full scale (2026-07-25) by `verify.c --ie-count` and matches
exactly. The remaining honest residual is that both instruments are
project-authored — no third-party recomputation exists. (The C5-ladder
definitional gap this instrument originally surfaced
is resolved — see the defects section above.)

---
*`verify.py` is stdlib-only and imports no project code — run `python3 verify.py
--recount` to regenerate the match table. `verify.c` builds with `cc -O2 -o
verify verify.c -lz -lpthread` and reads a run's `run.out`. Developed with AI assistance
(Claude, Anthropic).*

**Provenance of the C5-ladder rows (2026-07-21):** the C5 ladder entries below are backed by an actual
`python3 verify.py --recount` execution on 2026-07-21 (27 quantities reproduced, 0 MISMATCH,
~134 s), not merely by TR-11's published statement. The landed run's `count_result.json` retains
its original `"estimate accurate to 0.0044%"` note verbatim: it is a machine-readable record of
what that run produced, so it is annotated here rather than edited — post-hoc rewriting of a
landed artifact would damage its provenance value. The hedged reading (that figure is the
estimate's rounding gap, not a resolved error) is carried in the surrounding prose.
