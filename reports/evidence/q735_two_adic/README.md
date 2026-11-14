# Q-735: a 2-adic divisibility in the n=31 atlas — statement, proof, tables, reproducers (2026-11-13)

*Dated note, added 2026-11-13 (backlog Q-1128). Status: **a hand proof with exhaustive finite tables,
independently re-derived; not formalised in Lean.** The theorem was found and proved by a Fable lane
(Claude Fable 5.2) and independently verified by a separate Fable lane with its own code. That
verifying lane also supplied the argument for the six V1 pairs with trivial stabiliser (§3, "V1, the
six pairs"), which a third Fable lane, again with its own code, independently verified. This directory
was assembled from the three lanes' scripts. Developed with AI assistance (Claude, Anthropic).
It is a statement about divisibility of counts. It says nothing about why King Wen's sequence is what
it is.*

## 1. Statement

The space is SUPER = C1 ∩ C2 ∩ C4 ∩ C5 at full size (n = 31 free pairs after the anchor pair
{Qian, Kun}), with King Wen's boundary-class budget {1: 2, 2: 8, 3: 13, 4: 7, 6: 1}. N is the number of
its walks; a **V2 cell** (k, d) counts the walks whose boundary k has class d (`layers[k].by_class` in
the n=31 atlas); a **V1 cell** (k, p) counts the walks that place pair p at slot k+1
(`layers[k].marginal_raw`).

**Theorem.** We prove:

1. **(fibres)** For every support skeleton s• and every class sequence c with this budget, the fibre
   F(s•, c) is divisible by 2^20; more precisely v2(F(s•, c)) ≥ 33 − t(s•, c), where t is the number of
   class-3 boundaries whose two supports differ in exactly one coordinate (t ≤ 13).
2. **(V2)** 2^21·3 divides N, every class-sequence census N(c), and every V2 cell of the n=31 atlas.
3. **(V1)** 2^19 divides every V1 cell of all 28 reversible pairs (2^19·3 for pair 5, whose stabiliser
   in the coordinate permutations S3 is all of S3), and 2^21 divides every V1 cell of the 3 complement
   pairs. In particular 16 divides every raw V1 cell.

What the atlas adds (read from it, not from the proof): the gcd of the 154 nonzero V2 cells is exactly
2^21·3, with minimum v2 = 21 in every layer, and the V1 minima are 2^19 for all 28 reversible pairs and
2^21 for the complement pairs, so the V1 floors of item 3 are attained. That 2^21·3 is the exact gcd therefore comes from the atlas together
with the exhibited fibre F = 2,293,235,712 = 2^20·3^7 (`fibres_n31.tsv`), which shows that the
per-fibre bound 2^20 is attained. The proof alone gives only the lower bound.

## 2. Notation

**Coordinates.** Each line pair (bits j and 5 − j of a hexagram, j = 0, 1, 2) is mapped to Z_4 by the
standard Gray map 00→0, 01→1, 11→2, 10→3 (Hammons, Kumar, Calderbank, Sloane and Solé, IEEE Trans.
Inform. Theory 40(2) (1994) 301–319), under which Hamming distance is Lee distance. A hexagram becomes
x ∈ Z_4^3, written x = s + 2t with s = x mod 2 ∈ F_2^3 (the **odd support**: which line pairs are
antisymmetric) and t ∈ F_2^3, the usual 2-adic digits of a Z_4 element. Reversal is x ↦ −x,
complement is x ↦ x + (2, 2, 2), and the hexagram group of order 48 is the coordinate negations and
permutations. In these coordinates (checked on all 4,096 ordered pairs and all 64 hexagrams by
`q735_common.coordinates_check`):

  d(x, y) = |s + s′| + 2·|(t + t′) ∧ ¬(s + s′)|,   mate(s, t) = (s, t + s̃),  s̃ = s for s ≠ 0, s̃ = 111 for s = 0.

So the 28 reversible pairs are 7 nonzero supports × 4 pairs (the cosets of ⟨s⟩), and the complement
pairs (including the anchor) are the 4 cosets of ⟨111⟩ in support 0.

**Fibres.** Slot k (k = 1..31) has support s_k and entry t_k; slot 0 is the anchor, support 0 and exit
t = 000. Boundary k (k = 0..30) joins slot k to slot k+1, and

  class_k = |s_k + s_{k+1}| + 2·|(t_k + s̃_k + t_{k+1}) ∧ m_k|,  m_k = the coordinates where s_k = s_{k+1}.

F(s•, c) is the number of walks with slot supports s_1..s_31 and boundary classes c_0..c_30. Write
r_k = (c_k − |s_k + s_{k+1}|)/2 and K_s for the slots of support s. A fibre is nonempty only if |K_s| = 4
for s ≠ 0 and |K_0| = 3, and the entries of K_s must lie in distinct cosets of ⟨s̃⟩ (for s = 0, also off
the anchor's coset {000, 111}). Boundary k is **internal** if s_k = s_{k+1} (the anchor boundary is
internal to support 0 when s_1 = 0), otherwise **cross**; a cross boundary has |m_k| ≤ 2.

## 3. Proof

**Step 1 (factorisation).** F(s•, c) = Σ_t ∏_s Φ_s(t|K_s) · ∏_{cross k} g_k((t_k + t_{k+1}) ∧ m_k), where
Φ_s is the 0/1 indicator of "distinct cosets, and every internal boundary of s has its prescribed r",
and g_k(v) = [ |v + (s̃_k ∧ m_k)| = r_k ] on F_2^{m_k} (at k = 0 the anchor's exit is 000, so there is no
shift and g_0 depends on t_1 alone). Every boundary is either internal, a condition on one support
class, or cross, a condition on the compared coordinates only.

**Step 2 (Fourier expansion of the cross factors).** g_k = Σ_w ĝ_k(w)·(−1)^{w·v} with ĝ_k(w) ∈ 2^{−e_k}·Z:

| class | supports differ in | \|m_k\| | r_k | g_k | e_k |
|---|---|---|---|---|---|
| 1 | 1 coordinate | 2 | 0 | a point of F_2^2 | 2 |
| 2 (cross) | 2 | 1 | 0 | a point of F_2 | 1 |
| 3 | 3 | 0 | 0 | constant 1 | 0 |
| 3 | 1 | 2 | 1 | a coset of ⟨11⟩ (ĝ = ±1/2 on {00, 11}) | 1 |
| 4 (cross) | 2 | 1 | 1 | a point of F_2 | 1 |

Classes 2 and 4 with equal supports, and class 6, are internal (class 6 needs equal supports). Class 5
does not occur in this budget; its row (class 5, supports differing in 1, e = 2) is in `ek_table.tsv`
because the reproducer covers every class. The table is recomputed over all 56 ordered support pairs
and the 7 anchor cases.

**Step 3 (character sum).** A product of the characters (−1)^{w_k·(t_k + t_{k+1})} is a character of
t ∈ (F_2^3)^31, and the slots are partitioned by support, so the sum over t factorises:

  F(s•, c) = Σ_{(w_k)} ∏_{cross k} ĝ_k(w_k) · ∏_s Φ̂_s(u^w|K_s),  Φ̂_s(u) = Σ_t Φ_s(t)(−1)^{u·t} ∈ Z.

Each term lies in 2^{Σμ_s − Σe_k}·Z, where μ_s is the minimum of v2(Φ̂_s(u)) over **all** characters u
with Φ̂_s(u) ≠ 0. Hence v2(F) ≥ Σ_s μ_s − Σ_{cross k} e_k. This is character orthogonality on F_2^n, the
principle behind Krawtchouk counting of walks on the hypercube; the self-avoidance (distinct pairs)
constraint is not expanded but stays inside each Φ_s.

**Step 4 (the finite table).** μ_s depends only on s and on the internal pattern of K_s: for each gap
between consecutive slots of K_s, "not adjacent" or adjacent with class 2, 4 or 6 (and, for s = 0, the
anchor boundary). Computed exhaustively for all eight supports, every pattern and every one of the 8^4
(8^3 for s = 0) characters — 512 patterns, 327 feasible (`mu_table.tsv`):

| support | free pattern: count, μ | min net ν, by number of class-6 boundaries |
|---|---|---|
| \|s\| = 1 (3 supports) | 384 = 2^7·3, μ = 7 | 0 (none), −1 (one), −2 (two) |
| \|s\| = 2 (3 supports) | 384, μ = 7 | 0, −1, −2 |
| \|s\| = 3 | 384, μ = 7 | 0 (class 6 infeasible) |
| s = 0 (complement class) | 48 = 2^4·3, μ = 4 | 0 (class 6 infeasible) |

Here net ν = μ − μ_free + (number of internal class-2 and class-4 boundaries). In words: every Fourier
coefficient of the unconstrained factor is divisible by 2^7 (2^4 for the complement class), each
internal class-2 or class-4 boundary costs at most one factor of 2, and **each class-6 boundary costs at
most one factor of 2**. No pattern violates μ ≥ μ_free − #(class 2/4) − #(class 6).

**Step 5 (bookkeeping).** Let the budget be (b1, b2, b3, b4, b6), let a and a′ be the numbers of internal
class-2 and class-4 boundaries, and t as in §1. Then Σ e_k = 2·b1 + (b2 − a) + t + (b4 − a′) and
Σ_s μ_s ≥ 7·7 + 4 − a − a′ − b6, so

  v2(F(s•, c)) ≥ 53 − 2·b1 − b2 − b4 − b6 − t.

For King Wen's budget this is 53 − 4 − 8 − 7 − 1 − t = **33 − t ≥ 20**, since t ≤ b3 = 13. ∎ (fibres)

**Step 6 (the factor 6).** A coordinate permutation g ∈ S3 is an isometry that preserves pairs and fixes
the anchor and its exit, so F(g·s•, c) = F(s•, c). A nonempty skeleton contains all three singleton
supports, and only the identity fixes all three, so S3 acts freely on skeletons. Every N(c), every V2
cell (k, d) = Σ_{c_k = d} N(c), and N are sums of 6·F over S3-orbits of skeletons. **Hence 2^21·3 divides
every V2 cell, every N(c), and N.** ∎

**V1 (one pair pinned).** Fixing pair p at slot k+1 multiplies the factor Φ_s of its support by the
indicator of one coset of ⟨s̃⟩ at one slot. The pinned tables (`pin_table.tsv`, every support, pattern,
slot and pair) show that this costs at most **2** more factors of 2 for s ≠ 0 and **none** for s = 0
(pinning a single hexagram costs at most 3 and 1). So each pinned fibre is divisible by 2^18 (reversible
pair) or 2^20 (complement pair). The V1 cell (k, p) is invariant under the stabiliser H_p of p in S3,
which still acts freely on skeletons, so the cell is a sum of |H_p|·(pinned fibre): 2^18·|H_p| or
2^20·|H_p|. The stabiliser sizes are 2 for the 3 complement pairs, 2 for 21 reversible pairs and 6 for
pair 5, which gives 2^21, 2^19 and 2^19·3. ∎

**V1, the six pairs with trivial stabiliser** (pairs 10, 15, 20, 23, 27, 29). For these the argument
above gives only 2^18, and single pinned fibres really do sit at exactly 2^18 for these six pairs (two
witness fibres in `fibres_n31.tsv`, checked by `n31_bound.py`: at slot 3 of one, pairs 10 and 23 each
give 573,308,928 = 2^18·3^7). The missing factor comes from adding the pair to its mirror pair before
taking valuations. Such a pair p has a support s of weight 1 and unequal entries on the other two
coordinates; let τ be the transposition of those two coordinates. τ fixes s, and p′ = τp is the other
trivial-stabiliser pair of that support (the mirror pairs are (10, 23), (15, 20), (27, 29)). τ is an
isometry preserving pairs and the anchor, so F_p(τs•, c) = F_{p′}(s•, c), where F_q counts the fibre's
walks with pair q at slot k+1. τ acts freely on skeletons (it swaps the two other weight-1 supports,
whose slots are disjoint). Grouping skeletons in τ-orbits {s•, τs•}:

  cell(k, p) = Σ_c Σ_{s•} F_p(s•, c) = Σ_c Σ_{orbits {s•, τs•}} [F_p(s•, c) + F_p(τs•, c)]
            = Σ_c Σ_{orbits} [F_p(s•, c) + F_{p′}(s•, c)].

Nothing is divided by the symmetry: τ only regroups the sum. The bracket is the fibre with slot k+1
pinned to p ∪ p′, whose entries are the half {t : λ·t = 1} of the support class (λ = the two coordinates
outside s), a coset of an index-2 subgroup. Steps 1–5 apply with Φ_s multiplied by that indicator, and
the half-pin table (`pin_table.tsv`, last column: every support, pattern, slot and every such half, both
cosets) shows that a half pin costs at most **one** factor of 2 (none for s = 0). Hence
v2(F_p + F_{p′}) ≥ 33 − t − 1 ≥ 19 for every skeleton and class sequence, and 2^19 divides every V1 cell
of the six pairs. ∎

*Corrections relative to the private write-up.* The independent check found three wording defects in
the author's text, none used by the argument; this README carries the corrected forms. (i) Step 4: a
class-6 boundary costs at most one factor, as the table and Step 5 use, not two. (ii) The summary
formula for this budget is 33 − t, not "34 − t − (0 or 1)". (iii) The atlas V1 block for the complement
pairs had been hand-edited; `atlas_check.py` prints the proved floor 2^21 for them directly. The third reader's two
notes on the six-pair argument are applied as well: the evidence that single pins reach exactly 2^18 is
shown for the six pairs themselves (it had been quoted from a minimum over all reversible pairs), and the
displayed sum carries the middle term F_p(s•, c) + F_p(τs•, c).

## 4. Scope and what is not shown

- **Proved:** items 1–3 of §1, for n = 31 and King Wen's budget only.
- **Not shown — kernel cells.** The raw one-step kernel cells are open. Pinning one hexagram costs at
  most three factors per slot (tabulated), but no statement about kernel cells is claimed.
- **Not shown — other budgets.** Step 5 gives 2^{22 − b1} | F for any class-5-free budget at n = 31. That
  generalisation follows from the same steps but has not been tested on any other n = 31 budget.
- **Not shown — exactness.** The proof bounds the gcd from below. That it is exactly 2^21·3 is read from
  the atlas (cells with v2 = 21 exist) together with the exhibited 2^20·3^7 fibre.
- **Small universes.** The proof needs every support class to hold all four of its pairs, which only the
  full n = 31 universe has. On the n = 9 universes the skeleton fibres do not carry the observed surplus,
  and the n = 9 divisibility rests on a separate argument.
- **Not formalised in Lean.** The finite parts (the e_k table, the μ table, the pinned table) are small
  enough for `decide`/`native_decide`; that has not been done.

## 5. Related results

Counts that are divisible by more powers of 2 than their obvious symmetry accounts for are known in
other settings, for example domino tilings (Pachter 1997; Cohn 1999) and Latin squares (McKay and
Wanless 2005). For orderings of the hexagrams under these constraints, we are not aware of an earlier
statement of this divisibility. <!-- Q1129-WORDING -->

For context only: the standard count of the Hamiltonian cycles of the 6-cube is Haanpää and Östergård
(Math. Comp. 83 (2014) 979–995). The constraint system here is different (steps of Hamming distance
1, 2, 3, 4 or 6, and the C1 pairing).

The ingredients are standard: the Z_4 Gray map (Hammons et al. 1994), character orthogonality on F_2^n
and the Krawtchouk polynomials used to count walks on the hypercube (MacWilliams and Sloane 1977, ch. 5), and the factorisation of a character
sum over a product set. Full references are in `documentation/CITATIONS.md` (its last section,
"Divisibility of counts, and the Z_4 coordinates — the Q-735 note").

## 6. Files and reproduction

Python 3, standard library only. Every script prints whole-line `KEY=value` verdict tokens;
`EXPECTED_TOKENS.txt` lists the tokens of the default runs below, and `SHA256SUMS` the digests of every
other file here.

| file | what it is |
|---|---|
| `q735_common.py` | shared definitions: the King Wen table (verbatim from `solve.py`), the coordinates, Φ_s from 6-bit hexagrams, the cross factors, the bound, the exact character sum, and an independent exact layered count |
| `fourier_table.py` | Steps 2 and 4, exhaustively, twice (from 6-bit hexagrams and from the Z_4^3 description); `--pins` adds the V1 pinned tables (one pair, one hexagram, every half) and identifies the six mirror-pair unions as halves; `--check DIR` compares with the committed TSVs |
| `identity_check.py` | Steps 1–3 as an exact identity, and the bound, against brute force over every walk of small complete skeletons (7, 8 or 11 slots) |
| `n31_bound.py` | the bound at n = 31 on the 52 recorded fibres of `fibres_n31.tsv`; recomputes each F exactly by the character sum and checks it against the value recorded by the lane that found it; recomputes the six-pair witnesses (single pins at exactly 2^18, half pins at 2^19 or more) by the layered count; `--dp K` also recomputes the first K fibres by the layered count |
| `atlas_check.py` | the atlas against the statement: V2 divisibility, gcd and per-layer minima; V1 floors per stabiliser class (2^19 for the six pairs); 16 \| every V1 cell |
| `mu_table.tsv` | the μ table: every support, pattern and anchor value (512 rows) |
| `ek_table.tsv` | the e_k table |
| `pin_table.tsv` | the pinned tables: extra cost of a one-pair, a one-hexagram and a half pin, per support and pattern |
| `fibres_n31.tsv` | 52 n = 31 fibres: King Wen's, 40 local-move samples, nine fibres at v2(F) = 20 found by the searches of the first two lanes, and the third lane's two six-pair witnesses, with the exact F each recorded |

```
python3 reports/evidence/q735_two_adic/fourier_table.py --check reports/evidence/q735_two_adic          # ~10 s
python3 reports/evidence/q735_two_adic/fourier_table.py --pins --check reports/evidence/q735_two_adic   # minutes
python3 reports/evidence/q735_two_adic/identity_check.py 20261113 4                                     # ~30 s
python3 reports/evidence/q735_two_adic/n31_bound.py                                                     # ~40 s; --dp 2 adds ~1 min
python3 reports/evidence/q735_two_adic/atlas_check.py runs/20260906_kc_ladders_n31/atlas_n31.json       # < 1 s
```

The probe gate `MARGINAL_RAW_EVERY_CELL_MOD16_EQ_0` of `python3 solve.py --atlas-probe` (named
`MARGINAL_RAW_EVERY_CELL_MOD16_EQ_0_EMPIRICAL` until 2026-11-13) now prints its basis beside it,
`MARGINAL_RAW_MOD16_BASIS=THEOREM:Q735_N31` on the n = 31 atlas, by §1 item 3.
