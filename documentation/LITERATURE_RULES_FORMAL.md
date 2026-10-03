# Formal Statements of the Literature Rules

**Purpose (2026-10-02, Q-946 / lens-sweep item T3-21).** Until this date every literature rule this
project measures existed only as code — `solve.py`'s `reg_*` predicates, `r11_axes` and
`rc4_violations` — and [LITERATURE_RULES_POPULATION_TESTS.md](LITERATURE_RULES_POPULATION_TESTS.md)
said so: "there is no document that states Moore parity, Moore rhythm, Schulz gender, CC-N4 or CC-N8
formally enough for an independent team to re-encode them." This document states each rule in the
form an encoder needs: the input, the derived objects, the predicate, what it returns, and its
King Wen value. It states the rule **as this project implements it** — the reading the population
figures and the SAT theorems actually rest on — and records, where the implementation deviates from
a source's wording, that it does. It is a specification of our encoding, not an interpretation of the
sources; attributions and the reading-direction conventions behind them are in
[CITATIONS.md](CITATIONS.md) and in each predicate's docstring.

**What is checked, and what is not.** The five theorem-bearing rules of §2 — the rules the
four-rule and five-rule conflict theorems and every `sat.py` target enforce — are re-encoded in
`tests.py` (`TestLiteratureRulesFormalStatements`) **from the text of this document**, using no
project helper beyond integer bit operations, and the re-encodings must agree with the project's
predicates on King Wen, on the 44 public non-King-Wen witnesses and on 400 seeded random pair
orderings with random orientations; a planted one-token deviation in a re-encoding is shown to be
caught. The 29 scoreboard rules of §3 are transcriptions checked by reading only; the test asserts
that each rule identifier appears in this document and that the King Wen value stated here is the
value the code returns, nothing more. The one-point King Wen gate of every rule
(`solve.py --registry-verify`) is unchanged and is still a one-point check.

## 1. Conventions

- **Hexagram.** An integer `h` in 0..63. Bit `i` (`(h >> i) & 1`) is line `i+1` counted from the
  **bottom**: bit 0 is the bottom line, bit 5 the top line. A set bit is a yang (solid) line; a clear
  bit is yin. `popcount(h)` = the number of yang lines. **Lower trigram** `lo(h) = h & 7` (bits 0–2);
  **upper trigram** `up(h) = (h >> 3) & 7`. Trigram codes: Qian 7, Kun 0, Zhen 1, Xun 6, Kan 2,
  Li 5, Gen 4, Dui 3.
- **Reversal and complement.** `rev(h)` reverses the six bits (the hexagram turned upside down);
  `comp(h) = h XOR 63`. A **palindrome** is `h` with `rev(h) = h` (8 of them; each pairs with its
  complement in King Wen). An **anti-symmetric** hexagram has `rev(h) = comp(h)` (8 of them).
  `HD(a, b) = popcount(a XOR b)` is the Hamming distance.
- **Sequence.** `S = (S[0], …, S[63])`, a permutation of 0..63. **Pair** `k` (k = 0..31) is
  `(S[2k], S[2k+1])`; its **representative** is the first member `S[2k]`; its **position** is
  `k + 1` (1-based). King Wen in this encoding, used for every KW value below (`solve.py`
  `binary_hexagrams`; pair 0 is (63, 0)):
  `63 0 17 34 23 58 2 16 55 59 7 56 61 47 4 8 25 38 3 48 41 37 32 1 57 39 33 30 18 45 28 14 60 15
  40 5 53 43 20 10 35 49 31 62 24 6 26 22 29 46 9 36 52 11 13 44 54 27 50 19 51 12 21 42`.
- **Stations** (the 36 inversion classes in first-appearance order; Lai Zhide's consolidation).
  Scan `S` left to right; the class key of `h` is `min(h, rev(h))`. The first time a key is met,
  open a new station whose **canonical gua** is that `h` (the member met first) and whose
  **member set** is `{h}` if `h` is a palindrome, else `{h, rev(h)}`. Stations are numbered
  1..36 in opening order; `station(h)` is the index of the station containing `h`. Any
  permutation of 0..63 yields exactly 36 stations (28 reversal classes and 8 palindromes).
- **Balance** of a station = `2·popcount(canonical) − 6`, yang minus yin lines; well defined on the
  class because `rev` preserves `popcount`.
- **Gender of a hexagram class** (Schulz): with `pc = popcount` of the class, `pc < 3` is male,
  `pc > 3` female, and `pc ∈ {0, 3, 6}` is exempt (the pure hexagrams and the balanced ones).
- **Parts.** First Part = `S[0..29]` (hexagrams 1–30, stations 1–18); Latter Part = `S[30..63]`
  (hexagrams 31–64, stations 19–36). Several rules index slots directly; those indices are
  0-based positions in `S` exactly as written.
- A rule that **returns bool** scores "holds" as `True`; a rule that **returns a count** is a
  statistic whose KW value is the registry's anchor. Where a conjunct is implied by the others it is
  marked *(implied)*: it discriminates no ordering, and an encoder may omit it.

## 2. The five theorem-bearing rules

These are the rules `sat.py`'s targets enforce (`RULESETS`), scored by `solve.r11_axes` (parity,
rhythm), `solve.rc4_violations` (gender), `solve.reg_ccn4` and `solve.reg_ccn8`. The SAT layer
imports these semantics and enforces "strict" = zero violations / `True`.

### 2.1 Moore 2005 pair-positioning parity — `parity`, score g1

Source: [Moore 2005](CITATIONS.md#moore2005). For each pair `k` with members `(h, h2)` and
position `p = k + 1`:

1. if `h XOR h2 = 63` (a complement pair) the pair is **not counted**;
2. else if `popcount(h) = 3` the pair is **not counted**;
3. else the pair is **compliant** iff `[popcount(h) > 3] = [p is odd]` — a female pair
   (four or more yang lines) must stand at an odd position and a male pair (two or fewer) at an even
   one.

`ok` = the number of compliant pairs; **g1 = max(0, 18 − ok)**. The constant 18 is the number of
counted pairs in King Wen's pair set (32 pairs, minus the 4 complement pairs, minus the 10
reversal pairs of popcount 3). KW: ok = 16, **g1 = 2**, the non-compliant pairs at positions 22
and 23. Strict form: g1 = 0.

### 2.2 Moore 1989 rising/falling rhythm — `rhythm`, score g2

Source: [Moore 1989](CITATIONS.md#moore1989). Scan pairs in order with three registers:
`prev` (the last counted pair's direction), `have` (a counted pair has been seen) and `adj`
(the immediately preceding pair was counted), all initially false/0. For pair `k` with members
`(h, h2)`:

1. if `h XOR h2 = 63`, or `popcount(h) = 3`: set `adj := false` and continue (not counted; it also
   breaks adjacency);
2. else let the **minority line** be `mb = 0` (yin) if `popcount(h) > 3`, else `mb = 1` (yang);
   `sc = Σ_{i = 0..5, bit i of h = mb} (5 − 2i)` — the minority lines weighted +5, +3, +1, −1, −3,
   −5 from bottom to top; the pair is **rising** (`rf = 1`) iff `sc > 0`, else falling (`rf = 0`);
3. if `have` and `adj` and `rf = prev`: count one **break**;
4. set `prev := rf`, `have := true`, `adj := true`.

**g2 = the number of breaks**: two consecutive counted pairs, with no exempt pair between them, must
alternate rising and falling. KW: **g2 = 2**, the breaks at pair positions (7, 8) and (22, 23).
Strict form: g2 = 0. Encoder note: the sign convention of the weights is immaterial. A counted pair's
first member has popcount 1, 2, 4 or 5, so it has one or two minority lines; `sc = 0` would need two
minority lines at mirror positions `{i, 5 − i}`, which makes `h` a palindrome, hence a member of a
complement pair, hence exempt. So `sc ≠ 0` on every counted pair, reversing every weight relabels
rising and falling uniformly, and the break count is unchanged. What carries the rule is the alternation and the
adjacency reset at exempt pairs (measured and then derived while writing this document).

### 2.3 Schulz 1990 gender / position parity — `gender`, score g3

Source: [Schulz 1990](CITATIONS.md#schulz1990-motifs) motif 2; the exception first noticed by
[Zhu Yuansheng](CITATIONS.md#zhuyuansheng). Over the stations of §1, with `n` the station index and
`pc` the popcount of the station's canonical gua:

- exempt if `pc ∈ {0, 3, 6}`;
- otherwise a **violation** iff `[pc < 3] ≠ [n is odd]` — a male class must stand at an odd station
  index and a female class at an even one.

**g3 = the number of violations**, with the violating station indices as the companion output.
KW: **g3 = 2** at stations **{25, 26}**. Strict form: g3 = 0. (The `rc4-kwexempt` SAT target
exempts exactly those two stations; every other target scores the rule as stated.)

### 2.4 CC-N4, the S25–S28 face configuration — `ccn4`

Source: [Schulz 2016](CITATIONS.md#schulz2016) pp. 23–24, [Schulz 2011](CITATIONS.md#schulz2011).
Let `f_s` be the canonical gua of station `s` for `s = 25, 26, 27, 28`. The rule holds iff
`up(f_s) = Dui (3)` for all four **and** `(lo(f_25), lo(f_26), lo(f_27), lo(f_28)) = (Qian 7, Kun 0,
Kan 2, Li 5)` in that order. Returns bool; KW **True** (faces 31, 24, 26, 29). Convention note:
the 2016 book's "xun on top" reads the figure top-down; under this project's bottom-to-top encoding
the top trigram of those faces is Dui, and that is what is encoded.

### 2.5 CC-N8, exception co-location — `ccn8`

Source: [Schulz 2016](CITATIONS.md#schulz2016) pp. 14–15 (SC-7). The rule holds iff the gender
violation set of §2.3 is **exactly** `{25, 26}` **and** both 25 and 26 are in the R-S2 violation set
of §3.2. Returns bool; KW **True**. It requires only that the two violation sets *share* the locus
(R-S2's set may be larger — King Wen's is `{11, 13, 14, 25, 26, 32}`).

## 3. The 29 scoreboard rules

Identifiers are the `solve.py --registry-verify` row names (`reg_<id>`); the scoreboard in
[LITERATURE_RULES_POPULATION_TESTS.md](LITERATURE_RULES_POPULATION_TESTS.md) uses the same names.

### 3.1 `rs1` — R-S1, xiaoxi trisection and solstice minimum

Source: [Schulz & Cunningham 1990](CITATIONS.md#schulz-cunningham1990) /
[Schulz 1990](CITATIONS.md#schulz1990-motifs). With Fu = 1 (`000001`, one yang at the bottom) and
Gou = 62 (`111110`): **trisect** iff `station(63) = 1`, `station(1) = 13` and `station(62) = 25`;
**minimum** iff the balance of Fu's station equals `−4` and equals the minimum balance over the
**non-pure** stations (canonical popcount not in `{0, 6}`). Holds iff trisect and minimum. Bool;
KW True. (The registry's "all 36 stations" wording would make Kun's station the −6 minimum; the pure
gua are the trisection anchors and are exempt from the minimum.)

### 3.2 `rs2` — R-S2, adjacent-station equal-and-opposite balance pairing

Source: [Schulz 1990](CITATIONS.md#schulz1990-motifs) pp. 348–350. Let `b_1..b_36` be the station
balances. Split 1..36 into **maximal runs** of consecutive stations with non-zero balance; a
zero-balance station separates runs and belongs to none. Within each run pair the stations
consecutively from the run's start: (1st, 2nd), (3rd, 4th), …. A paired station **complies** iff
its partner's balance is the negative of its own (`b_a = −b_b`); when a pair is not equal-and-opposite
both of its stations are violators; the unpaired last station of an odd-length run is a violator.
**Violation set** = all violators; the rule's value is `(number of non-zero-balance stations) −
(number of violators)`. Count; KW **20** (26 non-zero stations, violators `{11, 13, 14, 25, 26, 32}`,
which is Schulz's exception set). The registry's fixed `(2j−1, 2j)` pairing over all 36 stations
yields 12 on King Wen and is a mis-formalisation; the run-segmented reading is the one implemented.

### 3.3 `ccn1` — CC-N1, the all-resonant stations

Source: [Schulz 2016](CITATIONS.md#schulz2016) pp. 15–16, [Schulz 2018](CITATIONS.md#schulz2018).
A hexagram is **all-resonant** iff `(h XOR (h >> 3)) & 7 = 7` — every lower line differs from the
upper line above it (lower trigram = complement of upper); there are 8. Let `I` = the set of
station indices containing an all-resonant hexagram. Holds iff `|I| = 4` and `I = {7, 19, 24, 36}`
(the implementation also checks that the least index ≥ 19 is 19 and that `max(I) = 36`; both
*implied*). Bool; KW True.

### 3.4 `ccn2` — CC-N2, the doubled Zhen and Xun stations

Source: [Schulz 2016](CITATIONS.md#schulz2016) pp. 17–18. Holds iff `station(9) = 29` (doubled
Zhen, `001001`) and `station(54) = 32` (doubled Xun, `110110`); both in 19..36 *(implied)*. Bool;
KW True.

### 3.5 `ccn3` — CC-N3, the HD-1 cluster around the terminal pair

Source: [Schulz 2016](CITATIONS.md#schulz2016) pp. 22–24 (= Schulz 2011 element A6). Holds iff
every member `h` of every station in `{3, 4, 21, 22, 23, 28}` satisfies
`min(HD(h, 21), HD(h, 42)) ≤ 1` (21 = `010101` Ji-ji, 42 = `101010` Wei-ji). Bool; KW True.

### 3.6 `ccn6` — CC-N6, Upper Classic yin surplus at station level

Source: [Schulz 2016](CITATIONS.md#schulz2016) p. 15. `Y = Σ_{s = 1..18} popcount(canonical of
station s)` over 108 lines; holds iff `Y < 108 − Y`, i.e. `Y < 54`. Bool; KW True (52 yang, 56 yin).
The count is over the 18 canonical gua, not the 30 raw hexagrams.

### 3.7 `ccn7` — CC-N7, S36's trigrams are the union of S17's and S18's

Source: [Schulz 2016](CITATIONS.md#schulz2016) p. 27 (SC-19). For a station `s` let `T(s)` be the
list of `lo(h), up(h)` over its members `h`. Holds iff `set(T(17)) = {Kan 2}`, `set(T(18)) = {Li 5}`
and `sorted(T(36)) = [2, 2, 5, 5]`. Bool; KW True.

### 3.8 `c2011n1` — C2011-N1, the mirrored five-station Opposite sets

Source: [Schulz 2011](CITATIONS.md#schulz2011) pp. 651–652 (Element 6). A station is
**self-Opposite** iff its canonical `c` has `rev(c) = comp(c)`. Two stations `a, b` form an
**Opposite class pair** iff `{comp(h) : h ∈ M_a} = M_b` (member sets) and no member of
`M_a ∪ M_b` is a palindrome. Holds iff station 7 and station 30 are self-Opposite, (5, 8) and (6, 9)
are Opposite class pairs, and (29, 32) and (31, 33) are Opposite class pairs. The implementation's
fifth conjunct, `(29 − 18) − (18 − 9 + 1) = 1`, is a constant and always true *(implied)*. Bool;
KW True.

### 3.9 `c2011n2` — C2011-N2, the four self-Opposite stations

Source: [Schulz 2011](CITATIONS.md#schulz2011) pp. 651–653. Holds iff the sorted list of station
indices whose canonical `c` has `rev(c) = comp(c)` equals `[7, 10, 30, 36]`. Bool; KW True.

### 3.10 `c2011n4` — C2011-N4, the unique adjacent Opposite station pair

Source: [Schulz 2011](CITATIONS.md#schulz2011) (inferred from Element 6). Let `F` = the list of
`(s, s+1)`, `s = 1..35`, with `{comp(h) : h ∈ M_s} = M_{s+1}` and no palindrome in `M_s ∪ M_{s+1}`.
Holds iff `F = [(22, 23)]`. Bool; KW True. The check is class-level (member sets), not
canonical-versus-canonical.

### 3.11 `mmt3` — MM-T3, HD-1 transitions between consecutive representatives

Source: [McKenna & Mair 1979](CITATIONS.md#mckenna-mair1979) p. 425. With `r_k = S[2k]`:
value = `#{k ∈ 0..30 : HD(r_k, r_{k+1}) = 1}`. Count; KW **4** (a KW-measured anchor; the source
states no figure).

### 3.12 `mmt4` — MM-T4, complement pairs at HD 6, inversion pairs not all

Source: [McKenna & Mair 1979](CITATIONS.md#mckenna-mair1979) p. 422. Let `C` = the pairs whose
representative is a palindrome and `V` = the other pairs. Holds iff `|C| = 4`, `HD(a, b) = 6` for
every `(a, b) ∈ C`, and **not** every `(a, b) ∈ V` has `HD(a, b) = 6`. Bool; KW True.

### 3.13 `mmt5` — MM-T5, the trigram family order in an 8-window

Source: [McKenna & Mair 1979](CITATIONS.md#mckenna-mair1979) pp. 428–429. Value =
`#{i ∈ 0..56 : (lo(S[i]), …, lo(S[i+7])) = (7, 0, 1, 6, 2, 5, 4, 3)}` (Qian, Kun, Zhen, Xun, Kan, Li,
Gen, Dui). Count; KW **0**.

### 3.14 `mmt6` — MM-T6, no all-HD-1 window of four representatives

Source: [McKenna & Mair 1979](CITATIONS.md#mckenna-mair1979) p. 425. With `r_k = S[2k]`: value =
`#{k ∈ 0..28 : HD(r_{k+j}, r_{k+j+1}) = 1 for all j ∈ 0..2}`. Count; KW **0** (KW-measured anchor).

### 3.15 `p1c4` — P1-C4, the dual pairs are placed as inversion pairs

Source: [Schulz 1982](CITATIONS.md#schulz1982) pp. 139–140 (citing [Lai Zhide](CITATIONS.md#laizhide)).
Let `D` = the pairs `(a, b)` with `rev(a) = comp(a)` and `rev(b) = comp(b)`. Holds iff `|D| = 4`
and `rev(a) = b` for every `(a, b) ∈ D` (the implementation also requires neither member to be a
palindrome, *implied*: an anti-symmetric hexagram is never a palindrome). Bool; KW True. As a
predicate over orderings this is the same function as `r3` (§3.25), measured on 60,320 orderings.

### 3.16 `p2c3` — P2-C3, line-count remainder symmetry

Source: [Schulz 1982](CITATIONS.md#schulz1982) p. 213, [Schulz 2011](CITATIONS.md#schulz2011)
(SC-8). `Y_A = Σ popcount(S[0..29])`, `Y_B = Σ popcount(S[30..63])`, `K_A = Σ popcount(canonical)`
over stations 1..18, `K_B` over 19..36. Holds iff `(180 − Y_A) − Y_A = 8`, `Y_B − (204 − Y_B) = 8`,
`(108 − K_A) − K_A = 4` and `K_B − (108 − K_B) = 4`; equivalently `Y_A = 86`, `Y_B = 106`,
`K_A = 52`, `K_B = 56`. Bool; KW True.

### 3.17 `p2c4` — P2-C4, the median pairs

Source: [Schulz 1982](CITATIONS.md#schulz1982) pp. 207–208. Holds iff `{S[10], S[11]} = {7, 56}`
(Tai `000111`, Pi `111000`) and `{S[40], S[41]} = {35, 49}` (Sun `100011`, Yi `110001`). The
implementation's two line-count conjuncts (`12 + 6·8 = 60` in each Part) are constants *(implied)*.
Bool; KW True.

### 3.18 `p2c5` — P2-C5, both Part closures use only Kan and Li

Source: [Schulz 1982](CITATIONS.md#schulz1982) pp. 211–212. Holds iff for each `h` in
`(S[28], S[29], S[62], S[63])`: `lo(h) ∈ {2, 5}` and `up(h) ∈ {2, 5}`. Bool; KW True.

### 3.19 `p2c6` — P2-C6, median pairs reverse the head pairs' trigrams

Source: [Schulz 1982](CITATIONS.md#schulz1982) pp. 207–212. Let `swap(h) = (lo(h) << 3) | up(h)`
(exchange the trigrams), `H = {lo, up of S[0] and S[1]}`, `M = {lo, up of S[10] and S[11]}`.
**Part A** iff `M = H`, `swap(S[10]) = S[11]` and `S[10] ∉ {S[0], S[1]}`; **Part B** iff
`swap(S[30]) = S[40]` and `swap(S[31]) = S[41]`. Holds iff both. Bool; KW True.

### 3.20 `d4` — D4, Kan/Li and Ji-ji/Wei-ji close the two Parts

Source: [Drasny](CITATIONS.md#drasny2007). Holds iff `S[28] = 18` (`010010`, doubled Kan),
`S[29] = 45` (`101101`, doubled Li), `S[62] = 21` (`010101`, Ji-ji), `S[63] = 42` (`101010`,
Wei-ji) and `p2c5(S)` holds. Bool; KW True.

### 3.21 `d7` — D7, sovereign hexagrams in the group-B slots

Source: [Drasny](CITATIONS.md#drasny2007) and [Schulz 1990](CITATIONS.md#schulz1990-motifs) for the
identification of the twelve xiaoxi; the positional count is this project's own formalisation and is
classified DATA-LIKE ([METHODS](../reports/METHODS.md) §"Data-like vs principled"). Let
`X = {2^k − 1 : k = 1..6} ∪ {comp(x)}` = `{1, 3, 7, 15, 31, 63, 62, 60, 56, 48, 32, 0}`. Value =
`#{i ∈ (18, 19, 22, 23, 32, 33, 42, 43) : S[i] ∈ X}`. Count; KW **8**, the range ceiling.

### 3.22 `s1` — S1, the change hexagram of every pair is characterisable

Source: [Schöter 1998](CITATIONS.md#schoter1998) (Definition 9). Let `C` = `{a XOR b}` over pairs
whose representative is a palindrome and `V` = `{a XOR b}` over the other pairs. Holds iff `|C| = 4`,
every element of `C` equals 63, and every element of `V` is a palindrome. Bool; KW True.

### 3.23 `s6` — S6, Klein four-group orbit structure

Source: Schöter (via biroco), formalised by [Radisic 2026](CITATIONS.md#radisic2026). Let
`orbit(h) = {h, comp(h), rev(h), comp(rev(h))}`. Holds iff every pair `(a, b)` has `b ∈ orbit(a)`;
every pair whose `|orbit(a)| = 4` has `rev(a) = b`; and the number of distinct size-4 orbits over
0..63 is 12 (a constant of the hexagram set, *implied*). Bool; KW True.

### 3.24 `m2` — M2, Kan early, Li late

Source: [Moore 2005](CITATIONS.md#moore2005). `ct(H, t) = Σ_{h ∈ H} ([lo(h) = t] + [up(h) = t])`.
Holds iff `ct(S[0..7], Kan)/16 > ct(S[32..63], Kan)/64` (a per-slot density; King Wen 0.375 vs
0.125) **and** `ct(S[32..63], Li) > ct(S[0..31], Li)` (raw counts over equal halves). Bool; KW True.
The registry's raw-count comparison over the unequal Kan windows fails on King Wen (6 < 8); the
density form is the one implemented.

### 3.25 `r3` — R3, the anti-symmetric hexagrams form four pairs

Source: [Radisic 2026](CITATIONS.md#radisic2026) (Theorem 3.3). Let `A` = the pairs `(a, b)` with
`rev(a) = comp(a)` and `rev(b) = comp(b)`. Holds iff `|A| = 4` and `b = rev(a) = comp(a)` for every
pair in `A`; the HD-6 conjunct the implementation also carries is *implied* by that equation. Bool;
KW True. Same predicate as `p1c4` (§3.15).

### 3.26 `r4` — R4, total Hamming cost of the pairing

Source: [Radisic 2026](CITATIONS.md#radisic2026) (Corollary 4.12). Value =
`Σ_{k = 0..31} HD(S[2k], S[2k+1])`. Count; KW **120**.

### 3.27 `r5` — R5, the pairing-optimality witness

Source: [Radisic 2026](CITATIONS.md#radisic2026) (Theorems 1.1, 4.8). Let `F` = the pairs with
`popcount(a) ≠ popcount(b)`. Holds iff `|F| = 4`, every `(a, b) ∈ F` has `rev(a) = a` and
`b = comp(a)`, and `r4(S) = 120`. Bool; KW True. (The registry entry claimed 8 failures; reversal
preserves popcount, so only the 4 palindrome-complement pairs can fail.)

### 3.28 `c1` — C1, yang balance of consecutive groups of four

Source: [Chan 2026](CITATIONS.md#chan2026) (Table 2; exact formulation pending full-paper access,
registry proxy used). Value = `Σ_{i ∈ 0, 4, …, 60} | Σ_{j = 0..3} popcount(S[i+j]) − 12 |`. Count;
KW **24** (KW-measured anchor).

### 3.29 `c2` — C2, the within-pair Hamming-distance profile

Source: [Chan 2026](CITATIONS.md#chan2026) (Table 2; proxy, as above). Value = the histogram of
`HD(S[2k], S[2k+1])` over `k`, as the tuple of `(distance, number of pairs)` sorted by distance.
KW **((2, 12), (4, 12), (6, 8))**.

## 4. Scope, stated

- Each statement above is the implemented reading. Where a source's wording admits another
  reading, the docstring of the predicate records which was chosen and why; this document does not
  adjudicate the sources.
- The one-point King Wen gate (`--registry-verify`, `--r11-verify`) establishes that the encoding
  reproduces the source's King Wen tally. It cannot distinguish a faithful rendering of what a source
  wrote from a differently scoped predicate that agrees on that one sequence. The population figures
  in [LITERATURE_RULES_POPULATION_TESTS.md](LITERATURE_RULES_POPULATION_TESTS.md) live at that scope.
- The executable check that this document is encodable covers §2 only (five rules, re-encoded from
  this text and compared to the code on 445 orderings). A test on finitely many sequences is not a
  proof of equivalence; the SAT-side equivalence of the CC-N4 clause family over every C1-valid
  ordering is a separate result (`sat.py --ccn4-equiv-cnf`, [SAT_CLI.md](SAT_CLI.md)).

*Developed with AI assistance (Claude, Anthropic). Errors are Claude's; corrections welcome.*
