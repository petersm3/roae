# VERIFY.md — the independent second instrument (`verify.py`)

*Companion to `verify.py`. Answers the single-instrument caveat raised in
[TR-11 §10(vi)](../reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md): "at full
31 … the full-31 integer will initially rest on a single instrument."*

`verify.py` is a genuinely **independent** second opinion on the ROAE results.
It is standard-library-only Python, imports **none** of `solve.c` / `solve.py` /
`roae.py` / `sat.py`, and rebuilds every quantity **clean-room from the published
mathematical definitions** (SPECIFICATION.md constraints C1–C5, `rev`/`comp`/
`partner`, the 48-element symmetry group; TR-11's reduced-rung tables). Its
counting method is deliberately **different** from `solve.c`'s symmetry-quotient
DP, so a conceptual bug in the quotient method would not be shared.

It verifies **both** kinds of published result:

| mode | what it checks |
|---|---|
| `python3 verify.py [solutions.bin]` | the RECORDS: re-decodes every record and re-checks C1–C5 + order/dups |
| `python3 verify.py --enumerate-reference N` (2≤N≤9) | small-n completeness: brute-forces the reduced N-pair problem two independent ways (exhaustive vs prune-as-you-go) and asserts identical solution sets |
| `python3 verify.py --recount` | the exact COUNTS: independently reproduces the small-n structural facts and the reduced-rung C1∩C2∩C4 union counts by a counting recurrence, and prints a match table |

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

**Result: 21 quantities with published targets, all reproduced EXACTLY, 0 mismatch.**
Peak RSS ~24 MB, wall time ~40 s (dominated by the 63 M-leaf U1 backtracking).

## Not independently re-counted — the C1∩C2∩C4∩**C5** ladder (TR-11 §4b)

The seven C5-tracked ladder rungs (n = 13, 16, 19, 24, 25, 27, 28) are recorded
as **NOT independently re-counted**, for two reasons — the first of which is a
substantive finding this instrument surfaced:

1. **The reduced-C5 definition as published is under-specified / imprecise.**
   The Verification Guide (TR-11 "How to recompute a rung independently") says to
   "retain only states whose [boundary-distance] multiset is a **sub-multiset**
   compatible with C5 (King Wen's {1:2, 2:8, 3:13, 4:7, 6:1})." Taken literally,
   the 13-pair rung `{3.0,4.0,6.2}@0` then counts **38,492,859,594,240** — **not**
   the published **2,063,395,607,040**. The published value instead equals the
   count for **one exact target boundary multiset**, `{d1:1, d2:6, d4:6}` (i.e.
   the residual budget must land on a specific vector, not merely stay within
   B0). That per-rung target vector lives in `solve.c`'s private `f1c5_unions[]`
   table and is **not given in any public document**, so it cannot be reproduced
   here without reading solver code — which would defeat independence. This
   discrepancy is worth fixing in the public docs: either publish the per-rung
   target budget vectors, or restate the reduced-C5 rung definition so the
   published counts follow from it.
2. **Pure-Python budget.** A residual-tracking recurrence (adding the C5 budget
   dimension to the DP state) blows past this host's memory/time budget by
   n ≥ 16 (the residual dimension multiplies the state count by thousands). Even
   with the exact target vector known, only n = 13 is comfortably in reach on a
   light host.

## Corroboration chain for the full-scale count (which this instrument did NOT run)

Tier-2 scope was intentional (per TR-11, the full 31-pair count is out of scope
here). The full-scale exact count
|C1∩C2∩C4∩C5| = 1,097,051,278,789,181,790,036,112,071,176,579,186,688 (TR-11 §9)
does **not** rest on this instrument. Its corroboration chain is:

- **Method-agreement at the reduced rungs (here).** An independent instrument,
  a different counting method (plain no-quotient recurrence + raw backtracking),
  and stdlib-only code reproduce the C1∩C2∩C4 unions and every small-n
  structural fact exactly — validating the recursion and the pairing/symmetry
  machinery the full-scale run depends on.
- **The project's own two engines agree at full scale.** The in-RAM
  symmetry-quotient DP and the out-of-core streaming DP produce **byte-identical
  layer files** and digit-identical totals at every validated subset size
  (24/25/27/28 pairs reproduced digit-for-digit, TR-11 §8), and the compiler /
  DFS lineages cross-check the enumeration side.
- **The mod-24 free-action gate.** The free action of the order-24 record group
  forces N ≡ 0 (mod 24); the full-scale integer satisfies it exactly — a
  zero-code reader-side arithmetic check.
- **The Knuth estimator.** The independent unbiased random-probe estimate
  (≈1.0971×10³⁹) agrees with the exact full-scale integer to 0.0044%.

Method-diverse agreement at Tier-2 here, plus the two full-scale engines, the
mod-24 gate, and the estimator, together address the TR-11 §10(vi) single-
instrument caveat for the reduced rungs; the honest residual is the C5-ladder
definitional gap noted above.

---
*`verify.py` is stdlib-only and imports no project code — run `python3 verify.py
--recount` to regenerate the match table. Developed with AI assistance (Claude,
Anthropic).*
