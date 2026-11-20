# Q-735: a 2-adic divisibility in the n=31 atlas — statement, proof, tables, reproducers (2026-11-13)

*Dated note, added 2026-11-13 (backlog Q-1128). Status: **a hand proof with exhaustive finite tables,
independently re-derived; not formalised in Lean.** The theorem was found and proved by a Fable lane
(Claude Fable 5.2) and re-checked by a second Fable lane of this project, with code written for that check. That
checking lane also supplied the argument for the six V1 pairs with trivial stabiliser (§3, "V1, the
six pairs"), which a third Fable lane of this project, again with code written for that read, re-checked. These are checks by AI model lanes working under this project's direction, not independent examination ([METHODS.md](../../METHODS.md), "Authorship independence"). "Independently re-derived" in the status line means that the tables and the n = 31 checks were rebuilt with code written apart from the author's scripts; the hand argument was read step by step. ⚠ (reworded 2026-11-14, CX-37C-R: this read "independently verified by a separate Fable lane with its own code", "That verifying lane" and "which a third Fable lane, again with its own code, independently verified".) This directory
was assembled from the three lanes' scripts. Developed with AI assistance (Claude, Anthropic).
It is a statement about divisibility of counts. It says nothing about why King Wen's sequence is what
it is.*
*Dated note, 2026-11-17 (Q-1127).* `free_moves.py` and `fibres_n31_touching.tsv` were added later: the
script was assembled by an Opus lane (Claude Opus 5.5) from the checking scripts of the two Fable lanes
that wrote and read the "Free moves" argument of §3, and is not a further independent implementation.
*Dated note, 2026-11-20 (Q-1127, Q-1150).* "Not formalised in Lean" in the status line above was true when it
was written. Since this date the divisibility statements of §1 are also machine-checked in Lean
(`lean/SuperspaceDivisibility.lean`), within the scope given in §4 (the dated note under "Not formalised
in Lean"). So is the family count of §3 ("Free moves"), for the fibre as the Lean file models it. The
per-fibre bound 33 − t of item 1 is not in Lean. The Lean file was written and read by Fable lanes of this
project (Claude Fable 5.2); that is not independent examination.

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

*Dated note, 2026-11-17 (Q-1127).* "Complement pairs" in this README means the pairs that C1 forms by
complement: both hexagrams are their own reversal (§2). The 3 free ones are King Wen's hexagrams 27 and 28,
29 and 30, 61 and 62. Four of the 28 reversible pairs, pair 5 (hexagrams 11 and 12) among them, are made
of two hexagrams that are also each other's complement. They are reversible pairs; the 2^21 statement is
not about them.

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

**Free moves.** Notation of §2. In a nonempty fibre let j, j + 1 be the two slots joined by the class-6
boundary. They have the same support s*, with |s*| = 1 or 2, and hold a pair and the pair of its two
complements (both reversible; not a complement pair in the sense of §2); so the other two slots of
support s* hold the remaining two pairs. A move is t_k ↦ t_k + o_k·s̃_k + v_{s_k} + w·111·[k ∈ {j, j + 1}],
with bits o_k and w, and v_s ∈ F_2^3 (v_0 = 0): 53 bits (31 flips o_k, 7 × 3 shift bits v_s, 1 bit w), of
which 2^7 choices give the identity (for each of the seven non-empty supports s, flipping all four slots
of support s and shifting them by v_s = s; w = 0, since 111 is not in the span of s*), so 2^46 moves.
Every move keeps the pairs of a walk of the fibre distinct. Let δ_k be the change of t_k + s̃_k + t_{k+1}.
Boundary k keeps its class if: δ_k ∧ m_k = 0 (class 1: two conditions; cross class 2 or 4: one); δ_k ∧ m_k ∈ {0,
m_k} (class 3, supports differing in one coordinate: one); nothing (class 3, three coordinates); o_k = o_{k+1}
(internal, both slots or neither in {j, j + 1}; o_1 = 0 at the anchor): one; and, for an internal
boundary between a slot of {j, j + 1} and a third slot of support s*: o_k + o_{k+1} = w if |s*| = 1, w = 0
if |s*| = 2: one. At the anchor boundary k = 0 the anchor is not moved, so δ_0 is the change of t_1
alone, with m_0 the coordinates outside s_1; the condition "o_1 = 0" is the internal case and applies
only when s_1 = 0. A "third slot" is one of the two slots of support s* other than j and j + 1. In the
third-slot case put u = s* if |s*| = 2 and u = 111 + s* if |s*| = 1; the third slot holds neither pair of slots
j, j + 1, so the two hexagrams at the boundary differ in exactly one coordinate of u, and a change δ_k ∈ {0,
u} keeps the class. These conditions are sufficient; at an internal boundary of a support of weight 2
they are not always necessary, so the count can be exceeded (the third-slot condition is also necessary).
These are at most 2·b1 + b2 + b4 + b6 + t = 20 + t linear conditions, all met by the 2^7 identity
choices, so at least 2^{26 − t} ≥ 2^13 moves map the fibre onto itself, and none but the identity fixes a
walk. With Step 6, 2^14·3 divides N, every N(c) and every V2 cell by counting orbits. The finite steps
are checked exhaustively by `free_moves.py`. These finite steps are: the change of class under a
translation of both sides of a boundary, for every pair of hexagrams in different pairs and every pair of
translations; the condition table above, including the anchor and equal-support rows; that the two
class-6 slots hold a pair and the pair of its two complements and no class-6 step exists in supports 0
and 111; that every move keeps the four pairs of a support distinct (every support); and the third-slot
rule with its converse. On a small complete universe of n slots (every support class it contains holds
all its pairs) the same count gives at least 2^(n + 22 − (2·b1 + b2 + b4 + b6 + t) − κ) moves, where κ = 3 × (non-empty supports
absent) + (non-empty supports present) and 2^κ is the number of identity choices; at n = 31, κ = 7 and this is 2^(26 − t).

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

**Why this number? Partly families of walks, partly a Fourier argument.** *Proved (a hand proof, read by
a second lane of this project with its own code; not formalised in Lean).* Three kinds of relabelling
never leave a walk unchanged. Kind (1) carries each fibre to another fibre of the same size. Those moves
of kinds (2) and (3) that keep every boundary's class carry a fibre onto itself. (1) Reorder the three
line pairs: 6 ways, and no skeleton is left fixed, so walks come in sets of 6 (Step 6). (2) Inside one
skeleton, turn the pair in any slot end-for-end, or shift all four pairs of one reversible support class
together. (3) Replace both hexagrams of the two slots joined by the class-6 boundary by their
complements; those two slots always hold a pair and the pair of its two complements, so this exchanges
them. Kinds (2) and (3) give 2^46 moves. A move keeps one boundary's class if it meets at most one linear
condition, two for a class-1 boundary and none for a class-3 boundary between supports that differ in all
three coordinates. One case needs an extra fact: at a class-2 or class-4 boundary between one of the two
class-6 slots and a third slot of the same support, one condition is still enough, because that third
slot never holds either of the two pairs in the class-6 slots. That is at most 20 + t conditions in all,
so in every fibre at least 2^{26 − t} ≥ 2^13 moves keep every class (the proof is under "Free moves"
above). So each fibre is a union of families of 2^{26 − t} walks, and by (1) fibres come in sets of six
of equal size. Counting these families, and nothing else, shows that 2^14·3 divides N, every N(c) and
every V2 cell. The atlas stores no N(c); that part rests on the fibre-level proof and Step 6, not on an
atlas check. The group of moves depends on the fibre; we do not have one group acting on all walks. The
moves themselves were found in this project's two earlier analyses of this surplus (orientation flips,
translations of a window of slots by a reversal-symmetric vector, of which the complement move of kind
(3) is one, and the free action of S3 on skeletons). What later lanes of this project added, in turn, is
the count for every fibre: 25 − t for kind (2), then the observation on five fibres that kind (3)
supplies one more factor, then the proof that kinds (2) and (3) together give 26 − t in every fibre (in
some fibres no move of kind (3) keeps the fibre, and flips and shifts alone give 26 − t there), which a
further lane re-derived and tested with its own code. These are checks by AI model lanes of this project,
not independent examination. The proof is by a Fable lane (Claude Fable 5.2) and was read by a second
Fable lane with its own code; `free_moves.py` was assembled by an Opus lane (Claude Opus 5.5) from those
two lanes' checking scripts and is not a further independent implementation. *Proved, by the Fourier
argument.* The bound of Step 5 is 2^{33 − t}, which is 2^7 more than the families give. The Fourier
argument yields one factor of 2 for each of the eight support classes beyond its flips and shifts: for a
class with no internal boundary, every Fourier coefficient is the number of its flips and shifts times a
sum of six signs, and a sum of six signs is even; the table of Step 4 shows that the count survives
internal boundaries. Kinds (2) and (3) together match one of these eight factors by free moves. For the
other seven we know no free move, and we do not claim that none exists. *Computed, not proved.* On five
of the recorded fibres of exactly 2^20·3^7 walks (`check_climb303_1`, `check_climb303_2`,
`check_climb303_3`, `check_tmax202_5`, `check_tmax202_6` of `fibres_n31.tsv`; another recorded fibre of
the same size, `r2b_min_seed11`, has 2^14 such translations, so the statement is about these five) we
listed every bijection of the fibre that acts on each slot separately (a map (h_1, …, h_31) ↦ (σ_1(h_1),
…, σ_31(h_31)), each σ_k a permutation of the hexagrams that occur at slot k in the fibre, that maps the
fibre onto itself). There are 2^16. Of these, 2^13 are translations (exactly the number the proof
guarantees, since t = 13 there); they move every walk, so every orbit has at least 2^13 walks, and the
orbits we sampled have exactly 2^13 (1,000 walks per fibre, drawn uniformly (each walk of the fibre
equally likely, drawn from the exact layered count with a fixed seed)). So on these fibres moves of this
kind account for 2^13 of the 2^20 and no group of them accounts for more; the other 2^7 rests on the
Fourier argument alone. Not tested: moves that change a slot according to its neighbours, and moves that
carry one fibre to another (`free_moves.py`). All of this is for n = 31 and King Wen's budget, and for N,
N(c) and V2 cells only; the family count for V1 cells was not worked out. *Open.* Whether any family of
walks accounts for the remaining 2^7 on those five fibres is not known; we state no conjecture either
way. The first 48 = 2^4·3 of the divisor (the hexagram symmetries) is the classical orbit-counting rule.

*Dated note, 2026-11-20 (Q-1150).* The family count of this paragraph is now also checked in Lean
(`lean/SuperspaceDivisibility.lean`, Part 2), so "not formalised in Lean" in its first label was true only
until this date. Lean proves three of its sentences in a narrower or more exact form. "2^46 moves": exactly
2^46 translations, in a fibre that is not empty. "each fibre is a union of families of 2^{26 − t} walks":
Lean proves what this rests on, for the fibre as the file models it (three bits for each of the 31 free
slots). In a fibre that is not empty the moves that meet the conditions give 2^d translations with d at
least 26 − t; each maps the fibre onto itself; none but the identity fixes a walk; and 2^{26 − t} divides
the size of every such fibre. "Counting these families, and nothing else": the Lean proofs of the three
2^14·3 statements use the families, Step 1 (sequences as sums of fibres) and Step 6. A census in this
directory (`LeanClosureCensus.lean.in`, `lean_closure_census.py`) lists what each of these proofs uses: none
of the 29 Walsh/character definitions of Part 1 that the census names and nothing declared in the table
sections of the Lean file (its §3 and §9–§12) is among them. The census does not examine the definitions of
Part 2 itself. They do use plain finite-sum and slot-counting lemmas that the Lean file keeps in the
sections of Steps 2 to 5 (`lean/README.md` has the command and the counts). Not in Lean:
that the conditions on a move are needed and not only enough, the small-universe form of the count, and
everything under "Computed, not proved" and "Open". The Lean work was written and read by AI model lanes
of this project; this is not independent examination.

*Corrections relative to the private write-up.* The second lane's check ⚠ *(reworded 2026-11-14, CX-37C-R: this read "The independent check")* found three wording defects in
the author's text, none used by the argument; this README carries the corrected forms. (i) Step 4: a
class-6 boundary costs at most one factor, as the table and Step 5 use, not two. (ii) The summary
formula for this budget is 33 − t, not "34 − t − (0 or 1)". (iii) The atlas V1 block for the complement
pairs had been hand-edited; `atlas_check.py` prints the proved floor 2^21 for them directly. The third reader's two
notes on the six-pair argument are applied as well: the evidence that single pins reach exactly 2^18 is
shown for the six pairs themselves (it had been quoted from a minimum over all reversible pairs), and the
displayed sum carries the middle term F_p(s•, c) + F_p(τs•, c).

## 4. Scope and what is not shown

- **Proved:** items 1–3 of §1, for n = 31 and King Wen's budget only.
- **Proved, by free actions (2026-11-17):** 2^14·3 divides N, every N(c) and every V2 cell by counting
  families of walks (§3, "Free moves" and "Why this number?"). A hand proof by one Fable lane of this
  project, read by a second Fable lane with its own code; not formalised in Lean. For V1 cells no family
  count was worked out.
  *Dated note, 2026-11-20 (Q-1150).* Now also machine-checked in Lean, in the scope given under "Not
  formalised in Lean" below. For V1 cells there is still no family count, by hand or in Lean.
- **Not shown — the remaining 2^7.** Between 2^14·3 and 2^21·3 is 2^7. On five recorded fibres of exactly 2^20·3^7
  walks (the five named in §3) no group of slot-by-slot bijections accounts for any of it (computed,
  `free_moves.py` leg G); moves that depend on neighbouring slots, or that move walks between fibres,
  were not tested. No claim either way.
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
  *Dated note, 2026-11-20 (Q-1127, Q-1150).* The divisibility statements are now machine-checked, kernel-only,
  in `lean/SuperspaceDivisibility.lean`: 2^20 divides every fibre (`fibre_dvd`), 2^21·3 divides N
  (`superCount_dvd`), every V2 cell (`cellV2_dvd`) and every N(c) (`censusC_dvd`), and the three V1
  statements of §1 item 3 are proved (`cellV1_dvd`, `cellV1_compl_dvd`, `cellV1_tai_dvd`). Lean proves them
  for the counts defined in that file and does not read the atlas, so that the atlas's tables hold these
  counts is not machine-checked; "divides", not "exactly". The finite tables of the Lean proof are checked
  in Lean's kernel (`decide`; no `native_decide`), and its V1 argument does not use the pinned table. Not
  in Lean: the finer per-fibre bound 33 − t, and kernel cells.
  The family count of §3 ("Free moves") is machine-checked in the same file (its Part 2), within these
  limits. Lean proves it for the fibre as the Lean file models it: three bits for each of the 31 free slots. For that
  fibre, 2^(26 − t) divides its size whenever the class sequence has King Wen's budget (`gplus_fibre`).
  From this, 2^14·3 divides N, every V2 cell and every N(c) (`superCount_dvd_families`,
  `cellV2_dvd_families`, `censusC_dvd_families`; these three count sequences). In a fibre that is not
  empty, exactly 2^7 of the 2^53 choices do nothing, so the choices give exactly 2^46 translations
  (`ident_exact`, `moves_exact`); the divisibility proof itself needs only "at most 2^7" (`ident_bound`).
  In such a fibre the moves that meet the conditions keep the fibre, and they form a family of 2^d moves
  with d at least 26 − t (`gplus_family`). A census in this directory lists every constant of the Lean file
  that the three 2^14·3 proofs use. It finds none of the 29 Walsh/character definitions of Part 1 that it
  names, and nothing declared in the table sections of the Lean file (its §3 and §9–§12), among them; it
  does not examine the definitions of Part 2 itself (a documented command in `lean/README.md`, not
  a leg of `verify_all.sh`). Still not in Lean: the same statement fibre by fibre for sequences; that the
  conditions on a move are needed and not only enough; the count on small universes; and that 2^(26 − t)
  is the largest such power of two for any fibre.

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
*Dated note, 2026-11-17 (Q-1127).* `free_moves.py` has its own tokens file,
`EXPECTED_TOKENS_FREE_MOVES.txt`, which lists the tokens of its `--quick` run, a documented command
(`tests.py` runs legs L and A and the error paths only, so these rows are a record of a run, not a test);
the verdict lines of its default run are listed there as comment lines.
*Dated note, 2026-11-20 (Q-1150).* `LeanClosureCensus.lean.in` and `lean_closure_census.py` are not reproducers of the
hand proof. They check a statement about the Lean proofs in `lean/SuperspaceDivisibility.lean`: which earlier
results the family proofs use. They need Lean 4.31.0; the command is in `lean/README.md`, and
`EXPECTED_TOKENS_LEAN_CLOSURE.txt` is the record of a run, not a test.

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
| `free_moves.py` | the "Free moves" statement of §3: the local lemma exhaustively (leg L); the whole theorem on small complete universes from the definition, every walk (leg E; leg S checks the counting code against brute force); every recorded t = 13 or touching fibre and every fibre of `fibres_n31_touching.tsv`, with the exact translation stabiliser, direct tests on sampled walks and, on the 45 with t = 13 and a touching boundary, exact joint counts (leg T); every slot-by-slot bijection of five recorded fibres of exactly 2^20·3^7 walks (`check_climb303_1/2/3`, `check_tmax202_5/6`) (leg G); the atlas against 2^14·3 and the V1 statements, with the minima pair by pair (leg A); mutants that must fail, each after the unmutated check passes on the same input (leg M). No leg computes an N(c) directly: that 2^14·3 divides each N(c) follows from the per-fibre statement and Step 6; the atlas stores no N(c), so this is not an atlas check. The script was assembled from the checking scripts of the lane that wrote the proof and the lane that read it; it repeats their checks in one file and is not a further independent implementation |
| (both TSV files) | a skeleton is 31 integers 0–7, one per slot: bit j of the integer is line pair j (lines j and 5 − j), bit 0 the bottom line pair; a class sequence is 31 integers; a witness is 31 hexagrams as 6-bit integers, bit i = line i, bit 0 the bottom line |
| `fibres_n31_touching.tsv` | 76 generated n = 31 fibres built to be hard for the proof: in 69 the class-6 window is next to a third slot of its support class (45 of those with t = 13), and they include windows at slots 1, 2 and 30, 31 and t from 0 to 13; one witness walk each. The source column names the generator and its arguments; the generators are not shipped, and each row's witness walk makes the fibre checkable without them. F is filled in for the 68 rows whose generator recorded it, and empty for the 8 rows whose only count would be `free_moves.py`'s own |
| `EXPECTED_TOKENS_FREE_MOVES.txt` | the tokens of the `--quick` run of `free_moves.py`, a documented command: `tests.py` runs legs L and A and the error paths only, and the `--quick` rows are a record of a run, not a test; as comment lines, the verdict lines of the default run |
| `LeanClosureCensus.lean.in` | a Lean 4 template, not a module of `lean/`: for 14 family theorems, 6 control theorems and 2 probes of `lean/SuperspaceDivisibility.lean` it prints every constant of that file that the theorem's statement and proof use, with the line of its declaration; it stops with an error on a missing theorem or when it runs out of steps |
| `lean_closure_census.py` | reads that output and the section headings of the Lean file: a family theorem must reach none of the 29 Walsh/character definitions and nothing declared in §3 and §9–§12, and no Part 1 definition outside its list of 57, a control theorem at least 10 and at least 100; last line `POS_VERDICT=PASS` or `POS_VERDICT=FAIL`, exit status 0 or 1 |
| `EXPECTED_TOKENS_LEAN_CLOSURE.txt` | the lines of the recorded census run: a record of a run, not a test; the command is in `lean/README.md` |

```
python3 reports/evidence/q735_two_adic/fourier_table.py --check reports/evidence/q735_two_adic          # ~10 s
python3 reports/evidence/q735_two_adic/fourier_table.py --pins --check reports/evidence/q735_two_adic   # minutes
python3 reports/evidence/q735_two_adic/identity_check.py 20261113 4                                     # ~30 s
python3 reports/evidence/q735_two_adic/n31_bound.py                                                     # ~40 s; --dp 2 adds ~1 min
python3 reports/evidence/q735_two_adic/atlas_check.py runs/20260906_kc_ladders_n31/atlas_n31.json       # < 1 s
python3 reports/evidence/q735_two_adic/free_moves.py --quick --atlas runs/20260906_kc_ladders_n31/atlas_n31.json   # EXPECTED_TOKENS_FREE_MOVES.txt; about 1.5 to 5 min, 1.0 GB
python3 reports/evidence/q735_two_adic/free_moves.py --atlas runs/20260906_kc_ladders_n31/atlas_n31.json           # the full default reproduction; about 10 to 50 min, 2.3 GB
```

The probe gate `MARGINAL_RAW_EVERY_CELL_MOD16_EQ_0` of `python3 solve.py --atlas-probe` (named
`MARGINAL_RAW_EVERY_CELL_MOD16_EQ_0_EMPIRICAL` until 2026-11-13) now prints its basis beside it,
`MARGINAL_RAW_MOD16_BASIS=THEOREM:Q735_N31` on the n = 31 atlas, by §1 item 3.
