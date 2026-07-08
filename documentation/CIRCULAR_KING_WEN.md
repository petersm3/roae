# The Circular King Wen Sequence

**Question (operator-queued 2026-07-02; [McKenna](CITATIONS.md#mckenna-mckenna1975)'s reading):** what do the project's constraints, theorems,
and measurements say when the King Wen sequence is read as a *cycle* — position 64 wrapping to position 1 —
as McKenna & McKenna (1975) did in constructing the difference wave (their counts use 64 transitions
including the wrap; see [MCKENNA.md](MCKENNA.md) and [CITATIONS.md](CITATIONS.md))?

## What carries over unchanged
- **C1, C3, C4** are position/pair properties, unaffected by closure.
- **The wrap-around parity theorem** ([SPECIFICATION.md](SPECIFICATION.md)): for any C4+C5 sequence the
  wrap distance d(s₆₃, s₀) is odd — proven via the XOR parity identity. KW's wrap is d = 3.
- **McKenna's 3:1 even:odd transition ratio** is the circular reading of that theorem plus C5 (16 odd of
  64) — forced, not designed (MCKENNA.md).

## What changes under closure
- **C5 (circular form):** the transition multiset gains the wrap value. For KW: {1:2, 2:20, **3:14**,
  4:19, 6:9} (the d=3 count rises 13→14). Orderings with d=1 wraps have {1:3, …, 3:13, …} instead.
- **The parity-alternation theorem** ([PARITY_ALTERNATION.md](PARITY_ALTERNATION.md)): the linear form
  forces exactly 15 parity-class alternations; on the cycle the count must be even, and the wrap boundary
  is forced to alternate (equivalent to the wrap-parity theorem — two routes to one fact). **Corollary:
  every valid circular reading has exactly 16 alternations**, and the first and last hexagrams of any
  valid linear ordering lie in opposite popcount-parity classes (KW: 63 even → 42 odd ✓).

## New result (2026-07-03, SAT-decided): circular C2 is a GENUINE extra constraint
Under closure, C2 (no 5-line transitions) acquires a 64th application — the wrap. Three facts:
1. The wrap-parity theorem restricts the wrap to d ∈ {1, 3, 5}.
2. At the 560T canonical, the wrap is d=3 in 91.83% of records, d=1 in 8.17%, and **d=5 in exactly zero
   of 10,525,271,997** (SPECIFICATION §wrap-parity).
3. **Nevertheless, valid linear orderings with a 5-line wrap EXIST** — SAT-decided with an explicit
   C1–C5-valid witness (final pair (32, 1); wrap d(1, 63) = 5; complement-distance sum 752):
   `63,0,17,34,23,58,2,16,55,59,7,56,61,47,4,8,25,38,3,48,41,37,57,39,33,30,18,45,28,14,60,15,40,5,53,43,
   20,10,35,49,31,62,24,6,26,22,29,46,9,36,52,11,13,44,54,27,50,19,51,12,21,42,32,1`
   (reproduce: `python3 sat.py --witness wrap-d5`).

So the circular reading is *not* free: "no 5-line transition anywhere on the cycle" excludes real members
of the linear solution set. Its absence from the 560T slice is a slice phenomenon — per the twins lesson
([SYMMETRY_SEARCH.md](SYMMETRY_SEARCH.md)), budgeted-slice absence does not measure full-space rarity;
the full-space wrap-distance masses are now MEASURED (2×10¹⁰ probes, 2026-07-03): **d=1: 17.5%, d=3: 65.2%, d=5: 17.4%** — the 5-wrap orderings that no budgeted slice has ever contained are between a fifth and a sixth of the full space, and circular C2 would cut the space by ×1.21.

## Symmetry under closure
Closure invites a larger symmetry question: without C4 (which pins the starting pair), a circular
constraint system would be invariant under the 32 pair-slot rotations as well as the B₃ relabelings —
a quotient the linear system's C4 deliberately breaks. Under the actual system (C4 kept), the circular
reading changes nothing about the symmetry group.

*Attribution: the circular reading of the sequence is McKenna & McKenna (1975); the wrap-parity theorem,
its 560T measurement, the alternation corollary, and the wrap-d5 SAT decision are ROAE (to our knowledge —
corrections welcome via CITATIONS.md).*

## Status decision (operator, 2026-07-03): documented, NOT promoted

Circular C2 is **not** promoted into the formal constraint system and is **not** implemented in `solve.c`
in any form. Rationale (consistent with the R-series non-promotion discipline): the circular reading is
McKenna's interpretive frame, not an attested property of the received artifact; enforcing it would add a
reverse-engineered constraint. For the record, the implementation analysis: as a pure leaf-emission filter
it would be **byte-identical to the current lineage at every published canonical scale** (zero 5-wrap
records exist in any slice — divergence begins only in territory no budget has reached, as the SAT witness
proves); as a prune it would change node consumption and open a new sha lineage. Neither is warranted.
The full-space mass of 5-wrap orderings has since been measured (2026-07-03, 2×10¹⁰ probes: 17.4% — see
above); it remains knowledge, not enforcement.
