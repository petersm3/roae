# VERIFY.md — the independent second instruments (`verify.py`, `verify.c`)

*Companion to `verify.py` (and its C-side sibling `verify.c`). Addresses the
single-instrument caveat raised in
[TR-11 §10(vi)](../reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md): "at full
31 … the full-31 integer will initially rest on a single instrument." (The
instrument half of that caveat still stands — see the closing section.)*

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
| `python3 verify.py [solutions.bin]` | the RECORDS: re-decodes every record and re-checks C1–C5 + order/dups |
| `python3 verify.py --enumerate-reference N` (2≤N≤9) | small-n completeness: brute-forces the reduced N-pair problem two independent ways (exhaustive vs prune-as-you-go) and asserts identical solution sets |
| `python3 verify.py --recount` | the exact COUNTS: independently reproduces the small-n structural facts, the reduced-rung C1∩C2∩C4 union counts, **and (since 2026-07-21) the C5 ladder rungs n = 9/13/16** (TR-11 §4b) — each rung's budget `B0` re-derived independently by TR-11 §5's first-completion DFS, then counted by a plain budgeted (mask, last, p) DP — and prints a match table |
| `python3 verify.py --check-certificate DIR` | a completed f1c5 run's ARTIFACTS (run.out per-layer certificate rows, manifest, preserved digests) against structural identities and independently derived quantities. Recomputes **nothing** — internal-consistency and digest-integrity only, per its docstring |
| `./verify --check-layers DIR [max_k]` | (C side, NEW 2026-07-23) the **on-disk layer files themselves**, read against [F1C5_LAYER_FORMAT.md](F1C5_LAYER_FORMAT.md) with no `solve.c` code: header/`pl_hash`/`b0` vs the manifest, `masks`/`off` layout, and per entry the key packing, `rid < R`, ascending order, nonzero value, and the **sum invariant** (rid mixed-radix digits sum to `k`). Entry-streaming and `O(nm)` memory, so it reaches **every** layer on disk — and at the final layer the summed value bytes must equal the published 39-digit count and be `≡ 0 (mod 24)`. Handles v1 (raw) and v2 (per-block zlib). `--check-layers-selftest` synthesizes v1+v2 fixtures + a corrupted case and needs no real data. **Campaign-VM tool** (run where the layers live). |
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

## Corroboration chain for the full-scale count (which this instrument did NOT run)

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
the estimator together corroborate the full-scale count. The honest residual is
unchanged from TR-11 §10(vi)'s instrument half: the full-31 integer rests on a
single instrument, and an independent full-scale recomputation has not been
performed. (The C5-ladder definitional gap this instrument originally surfaced
is resolved — see the defects section above.)

---
*`verify.py` is stdlib-only and imports no project code — run `python3 verify.py
--recount` to regenerate the match table. `verify.c` builds with `cc -O2 -o
verify verify.c` and reads a run's `run.out`. Developed with AI assistance
(Claude, Anthropic).*

**Provenance of the C5-ladder rows (2026-07-21):** the C5 ladder entries below are backed by an actual
`python3 verify.py --recount` execution on 2026-07-21 (27 quantities reproduced, 0 MISMATCH,
~134 s), not merely by TR-11's published statement. The landed run's `count_result.json` retains
its original `"estimate accurate to 0.0044%"` note verbatim: it is a machine-readable record of
what that run produced, so it is annotated here rather than edited — post-hoc rewriting of a
landed artifact would damage its provenance value. The hedged reading (that figure is the
estimate's rounding gap, not a resolved error) is carried in the surrounding prose.
