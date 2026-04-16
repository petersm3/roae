# How the King Wen Sequence Was Built

A plain-language summary of what `solve.py` and `solve.c` discovered.

## The puzzle

About 3,000 years ago, someone in ancient China arranged 64 symbols (called [hexagrams](https://en.wikipedia.org/wiki/Hexagram_(I_Ching))) in a specific order. This ordering is called the [King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence). There are more possible arrangements of 64 things than there are atoms in the universe — roughly 10^89 (a 1 followed by 89 zeros). But somehow, the designers picked one specific arrangement:

䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

We wanted to know: **what rules did they follow?** And can we figure out those rules just by studying the result?

## What a hexagram is

Each hexagram is a stack of 6 lines. Each line is either solid (⚊ [yang](https://en.wikipedia.org/wiki/Yin_and_yang)) or broken (⚋ [yin](https://en.wikipedia.org/wiki/Yin_and_yang)) — like a 6-digit binary number with only 1s and 0s. With 6 positions and 2 choices each, there are exactly 2^6 = 64 possible hexagrams. The King Wen sequence puts all 64 in a specific order.

| | ䷀ The Creative #1 | ䷄ Waiting #5 | ䷁ The Receptive #2 |
|---|:---:|:---:|:---:|
| Line 6 (top) | ⚊ **1** | ⚋ **0** | ⚋ **0** |
| Line 5 | ⚊ **1** | ⚊ **1** | ⚋ **0** |
| Line 4 | ⚊ **1** | ⚋ **0** | ⚋ **0** |
| Line 3 | ⚊ **1** | ⚊ **1** | ⚋ **0** |
| Line 2 | ⚊ **1** | ⚊ **1** | ⚋ **0** |
| Line 1 (bottom) | ⚊ **1** | ⚊ **1** | ⚋ **0** |
| Binary | **111111** | **010111** | **000000** |

To get the binary code, read the 1s and 0s from the top of the table downward. For example, ䷀ The Creative #1 is all solid lines: 111111. ䷁ The Receptive #2 is all broken lines: 000000. ䷄ Waiting #5 reads 0, 1, 0, 1, 1, 1 from top to bottom, giving 010111 — a mix of solid and broken.

## The rules we found

We discovered six rules. Each rule eliminates more and more possible arrangements:

### Rule 1: Every hexagram has a partner

The 64 hexagrams are grouped into 32 consecutive pairs. Each hexagram is paired with the one you get by flipping it upside down. (For 4 symmetric hexagrams that look the same upside down — ䷀䷁ ䷚䷛ ䷜䷝ ䷼䷽ — the partner is the one with every line toggled instead.)

**What this does:** Cuts the possibilities from 10^89 down to about 10^45. Still enormous, but 44 zeros gone in one step.

Flip (28 pairs, partner highlighted):<br>
䷀䷁ ䷂<mark>**䷃**</mark> ䷄<mark>**䷅**</mark> ䷆<mark>**䷇**</mark> ䷈<mark>**䷉**</mark> ䷊<mark>**䷋**</mark> ䷌<mark>**䷍**</mark> ䷎<mark>**䷏**</mark> ䷐<mark>**䷑**</mark> ䷒<mark>**䷓**</mark> ䷔<mark>**䷕**</mark> ䷖<mark>**䷗**</mark> ䷘<mark>**䷙**</mark> ䷚䷛ ䷜䷝ ䷞<mark>**䷟**</mark> ䷠<mark>**䷡**</mark> ䷢<mark>**䷣**</mark> ䷤<mark>**䷥**</mark> ䷦<mark>**䷧**</mark> ䷨<mark>**䷩**</mark> ䷪<mark>**䷫**</mark> ䷬<mark>**䷭**</mark> ䷮<mark>**䷯**</mark> ䷰<mark>**䷱**</mark> ䷲<mark>**䷳**</mark> ䷴<mark>**䷵**</mark> ䷶<mark>**䷷**</mark> ䷸<mark>**䷹**</mark> ䷺<mark>**䷻**</mark> ䷼䷽ ䷾<mark>**䷿**</mark><br>
Pairs: 3↔4, 5↔6, 7↔8, 9↔10, 11↔12, 13↔14, 15↔16, 17↔18, 19↔20, 21↔22, 23↔24, 25↔26, 31↔32, 33↔34, 35↔36, 37↔38, 39↔40, 41↔42, 43↔44, 45↔46, 47↔48, 49↔50, 51↔52, 53↔54, 55↔56, 57↔58, 59↔60, 63↔64

Inverse (4 pairs, partner highlighted):<br>
䷀<mark>**䷁**</mark> ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚<mark>**䷛**</mark> ䷜<mark>**䷝**</mark> ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼<mark>**䷽**</mark> ䷾䷿<br>
Pairs: 1↔2, 27↔28, 29↔30, 61↔62

### Rule 2: No 5-line jumps

When you move from one hexagram to the next, some number of lines change (1 through 6). This is called the [Hamming distance](https://en.wikipedia.org/wiki/Hamming_distance). In the King Wen sequence, the number 5 never appears — no two consecutive hexagrams differ by exactly 5 lines.

Examples from the King Wen sequence:

| Lines changed | Transition | Example |
|:---:|---|---|
| 1 | ䷳ Keeping Still #52 → ䷴ Development #53 | `100100` → `110100` |
| 2 | ䷁ The Receptive #2 → ䷂ Difficulty at the Beginning #3 | `000000` → `010001` |
| 3 | ䷅ Conflict #6 → ䷆ The Army #7 | `111010` → `000010` |
| 4 | ䷂ Difficulty at the Beginning #3 → ䷃ Youthful Folly #4 | `010001` → `100010` |
| **5** | **(never occurs in King Wen)** | |
| 6 | ䷀ The Creative #1 → ䷁ The Receptive #2 | `111111` → `000000` |

The difference wave — each character represents one transition, height proportional to lines changed (1-6):

`█▂▅▅▅▃▂▅▂▅█▂▂▅▂▂█▃▅▃▂▂▂▃▅▂█▂█▃▂▃▅▅▅▂▅█▅▃▂▅▂▃▅▃▂▃▅▅▅▁█▂▂▃▅▃▂▁█▃█`

The tallest blocks (█) are distance 6. The shortest (▁) are distance 1. No block reaches height 5 (▅) — that transition never occurs. See [all 63 transitions](#appendix-all-63-transitions) in the appendix.

**What this does:** Eliminates about 96% of the remaining arrangements.

<a id="rule-3"></a>
### Rule 3: Opposites kept unusually close

Every hexagram has an "opposite" — the one where every solid line becomes broken and vice versa. In the King Wen sequence, opposites are placed significantly closer together than you'd expect by chance. If you shuffled randomly, opposites would average about 22 positions apart. In King Wen, they average only 12.1 — at the **3.9th percentile** (only 3.9% of valid orderings place complements closer). King Wen doesn't just happen to have complements nearby; it actively keeps them as close as possible.

To illustrate: King Wen's worst complement pair (䷂ #3 and ䷱ #50, distance 47) is better than most random orderings' average case (~22).

**What this does:** Eliminates about 93% of what's left after Rule 2.

Closest complements highlighted (distance 1 — adjacent in the sequence):<br>
<mark>**䷀䷁**</mark> ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ <mark>**䷊䷋**</mark> ䷌䷍ ䷎䷏ <mark>**䷐䷑**</mark> ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ <mark>**䷚䷛**</mark> <mark>**䷜䷝**</mark> ䷞䷟ ䷠䷡ ䷢䷣ ䷤<mark>**䷥**</mark> <mark>**䷦**</mark>䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ <mark>**䷴䷵**</mark> ䷶䷷ ䷸䷹ ䷺䷻ <mark>**䷼䷽**</mark> <mark>**䷾䷿**</mark><br>
Pairs: 1↔2, 11↔12, 17↔18, 27↔28, 29↔30, 38↔39, 53↔54, 61↔62, 63↔64

10 of 32 complement pairs sit directly next to each other. The farthest apart are ䷂ #3 and ䷱ #50 (distance 47) — but the average is only 12.1. See [all 32 complement pairs](#appendix-all-32-complement-pairs-by-distance) in the appendix.

Farthest complements highlighted (䷂ #3 and ䷱ #50, 47 positions apart):<br>
䷀䷁ <mark>**䷂**</mark>䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰<mark>**䷱**</mark> ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿<br>
Pair: 3↔50

### Rule 4: It starts with Heaven and Earth

The sequence begins with the two most extreme hexagrams: all solid lines (䷀ The Creative #1, representing Heaven) followed by all broken lines (䷁ The Receptive #2, representing Earth).

**What this does:** Eliminates another 98%.

<mark>**䷀䷁**</mark> ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

### Rule 5: Specific transition counts

The "jumps" between consecutive hexagrams follow a specific recipe — called the [difference wave](https://en.wikipedia.org/wiki/Terence_McKenna#Novelty_theory_and_Timewave_Zero): exactly 2 jumps of size 1, 20 jumps of size 2, 13 jumps of size 3, 19 jumps of size 4, and 9 jumps of size 6. No jumps of size 0 or 5.

**What this does:** After all previous rules, a backtracking enumeration (`solve.c`, 10 trillion nodes on 64 cores) found at least **742 million** valid orderings — an enormous reduction from 10^89, but far more than the "near-unique" result suggested by earlier [Monte Carlo](https://en.wikipedia.org/wiki/Monte_Carlo_method) sampling. (An earlier published figure of 31.6M at this same 10T scale turned out to be a ~23× undercount caused by a file-naming collision in the solver; the corrected 2026-04-14 run found 742,043,303 unique orderings. See [HISTORY.md](HISTORY.md) for the forensics.)

### What the rules determine — and what remains open

A partial enumeration using `solve.c` (10 trillion nodes explored across 64 CPU cores) found **at least 742 million** unique pair orderings satisfying Rules 1-5. The enumeration is partial in the sense that each of the 3,030 sub-branches hits its per-sub-branch node budget rather than completing naturally — so the true count is unknown and could be significantly larger. Only Position 1 (Creative/Receptive) is universally locked — the same pair appears in every valid ordering. The remaining 31 positions show a gradient of constraint:

| Positions | Pairs observed | KW match rate | Character |
|-----------|---------------|-------------------|-----------|
| 1 | 1 | 100% | Fully determined |
| 3-18 | at least 2 each | 87-99% | Highly constrained |
| 19-20 | at least 2-4 | ~50% | Moderately constrained |
| 21-32 | at least 7-16 each | 10-22% | Progressively free |
| 2 | at least 16 | 0.2% | Branch-dependent |

**Caveats on these rates:** The match rates are computed from a partial, non-uniform sample. Each search branch was explored to an unknown depth (none completed), so shallower solutions are overrepresented. The "at least N pairs" counts are lower bounds — a complete enumeration could reveal additional pairs at each position. The rates should be treated as indicative, not definitive.

Earlier analysis based on a partial sample (438 solutions from a single search branch) claimed 23 of 32 positions were locked and that two adjacency constraints sufficed for uniqueness. The larger enumeration reveals this was an artifact of undersampling. The constraint gradient is real but much more nuanced.

Among 6 billion C3-valid solutions (including orientation variants), only 0.0018% satisfy both legacy adjacency constraints (C6+C7). Note: this rate mixes orientation variants (~297 per unique ordering) with unique orderings, so the per-ordering rate would differ. These constraints significantly narrow the space but their sufficiency for uniqueness is unverified at scale.

**What makes King Wen unique among millions of valid orderings is an open question.** It is equally possible that additional mathematical rules exist to be discovered, or that King Wen is simply one choice among many with no further mathematical distinction.

### The millions of roads not taken

The millions of alternative arrangements satisfying Rules 1-5 are not random — they share strong structural similarities with King Wen, especially in the first half of the sequence. The closest non-King-Wen solutions differ by only 2 pair positions, always in the last third (positions 26-32). This means:

- **Position 1 is mathematically forced.** Creative/Receptive always comes first.
- **Position 2 partially constrains positions 3-19, but not deterministically.** Earlier docs claimed "for 16 of 31 branches, positions 3-19 are fully locked" (based on `--prove-cascade`). That result is correct *only within the shift-pattern subspace* (where every position is restricted to KW's pair or the previous pair) — and direct measurement on 742M shows that subspace contains only 2.93% of all valid orderings. In the full 742M dataset, every reachable first-level branch admits 2-29 distinct pair sequences at positions 3-19; none are uniquely determined. The cascade region is heavily constrained (per-position Shannon entropy 0.28-1.72 bits, well below the 5-bit maximum) but not deterministic.
- **Freedom is concentrated in the back half but spread across the cascade too.** The earlier framing of "13 free positions (20-32)" oversimplified. The 742M analysis shows position 3 actually has the highest freedom (4.12 bits, 31 distinct pairs observed), positions 22-31 carry 3.45-3.65 bits each (14 distinct pairs), and the "cascade region" (4-20) carries 0.28-1.72 bits each — heavily constrained but not zero. The traditional [Xugua](https://en.wikipedia.org/wiki/Ten_Wings) commentary explaining why specific hexagrams follow each other in the back half is describing the designers' choices among genuinely available alternatives, not mathematical necessity.
- **King Wen keeps complements close.** Among all valid orderings, King Wen **minimizes** complement distance — keeping opposites as close as possible. Only 3.9% of valid orderings place complements closer.
- **The starting orientation is forced.** ䷀ The Creative must come before ䷁ The Receptive in all valid arrangements.
- **Within-pair orientation has no rule.** Which hexagram comes first within each pair follows no consistent pattern — not yang count, not binary value, not trigram weight. It appears to be a free choice at each pair.

## What this means

Five constraints, discoverable through analysis, narrow 10^89 possible arrangements to **at least 742 million** (likely more — the enumeration is incomplete). Position 1 is fully determined. The cascade region (positions 3-20) is heavily constrained (per-position entropy 0.28-1.72 bits — far below the 5-bit maximum) but not deterministic: every first-level branch admits 2-29 distinct pair sequences across positions 3-19. Positions 22-31 have substantially more freedom (entropy 3.5-3.6 bits). The earlier framing that "position 2 locks positions 3-19" was based on the bug-undercounted 31.6M dataset and on an analysis (`--prove-cascade`) that operated within a shift-pattern subspace containing only 2.93% of all valid orderings; it does not survive the corrected 742M dataset. The rules were extracted from King Wen (confirmatory analysis, not independent prediction), but the constraint structure they reveal is genuine.

Someone, roughly [3,000 years ago](https://en.wikipedia.org/wiki/King_Wen_of_Zhou), designed an arrangement of 64 symbols that satisfies a set of interlocking mathematical constraints so strict that only hundreds of millions of arrangements in the entire universe of 10^89 possibilities can satisfy them all. Exactly **4 boundary constraints** (specifying which pairs must be adjacent at 4 specific positions) are needed to narrow the 742 million known orderings to exactly 1 — King Wen. **The 4-boundary minimum is proven for the 742M dataset (not as a universal theorem)**: exhaustive testing of all 4,495 three-subsets of the 31 candidate boundaries against the 742M solutions confirmed that no combination of three suffices — the best 3-subset (positions {2, 25, 27}) leaves 24 total survivors, of which 20 are non-KW and 4 are orient variants of KW itself. The 20 non-KW survivors form a tightly structured family: 6 distinct pair-orderings, all permutations of pairs {20, 21, 22, 23} at positions 21-24 (`--analyze` section [17]). Exhaustive testing of all 31,465 four-subsets identifies exactly **4 working sets**: `{2, 21, 25, 27}`, `{2, 22, 25, 27}`, `{3, 21, 25, 27}`, `{3, 22, 25, 27}`. **Boundaries 25 and 27 are truly mandatory** — they appear in every working 4-set. Boundaries {2 ↔ 3} and {21 ↔ 22} are pairwise interchangeable. Rigorous identity-level verification (`--analyze` section [19]) confirms the four working 4-sets are **logically equivalent**: each leaves exactly the same 4 records (the 4 KW orient variants) with zero non-KW survivors. The result is robust under orient-collapse: grouping the 742M records by pair-index sequence yields 284.7M unique pair-orderings (`--analyze` section [15]); the same 4 working 4-sets and mandatory `{25, 27}` emerge. This is a computational finite-case proof over the current dataset, not a formal derivation; a deeper enumeration that finds additional valid orderings could in principle change the family.

### Per-position constraint strength (Shannon entropy)

Across the 742M valid orderings, the Shannon entropy H(p) of the pair distribution at each position p quantifies how much "choice" exists at that position (in bits; max possible is log₂(32) = 5.0 bits if any pair were equally likely). The gradient is crisp:

| Positions | H (bits) | Character |
|-----------|---------:|-----------|
| 1 | 0.00 | Fully determined (only Creative/Receptive) |
| 2 | 3.83 | Near-free (28 distinct pairs observed) |
| 3 | 4.12 | Most free of all positions (31 pairs observed) |
| 4-20 | 0.28 – 1.72 | Highly constrained — the "cascade region" |
| 21 | 1.71 | Transition |
| 22-31 | 3.45 – 3.65 | Moderately free |
| 32 | 2.66 | Partial constraint (7 pairs) |

Mean H = 2.05 bits per position. The peak at position 3 (not position 2) is because the solver's enumeration fixes position 2 first, so freedom is pushed one step downstream. The cascade region (positions 4-20) carries only 0.3-1.7 bits each — a very different regime from the "free" regions above and below it.

### How positions relate to one another (mutual information)

Pairwise mutual information I(p; q) measures how much knowing the pair at position p reduces uncertainty about position q. The strongest correlations are between adjacent positions in the cascade region (e.g., position 19 ↔ 20 = 1.15 bits), reflecting the tight local propagation. Notably: **boundaries 25 and 27 — both mandatory — have weak mutual information with everything else** (max I ≈ 0.19 bits).

Per-boundary conditional entropy (`--analyze` section [18]) directly quantifies how much fixing a boundary to match KW reduces total sequence uncertainty (baseline: 65.8 bits across 32 positions). The most informative boundaries are the early ones: boundary 2 contributes 35.3 bits of information, boundary 3 contributes 35.3 bits, boundary 4 contributes 33.3 bits. **Boundaries 25 and 27 sit mid-pack at 11.4 and 10.8 bits** — roughly one-third the information content of the top boundaries. Yet they are mandatory while the high-information boundaries are interchangeable. What makes `{25, 27}` mandatory is not that they carry more information but that the information they carry is **structurally independent** of all other boundaries: they eliminate non-KW solutions that no combination of other boundaries can reach.

### Boundary redundancy and independence

Joint-survivor analysis (counting how many solutions match KW at *both* of two given boundaries simultaneously) reveals two distinct boundary clusters:

- **Boundaries 15-19 are fully redundant.** For every pair within this set, `joint(b1, b2) = min(survivors(b1), survivors(b2))` — knowing one of these boundaries implies all the others. The cascade region propagates so tightly that constraints near its end carry overlapping information.
- **Boundaries 26 and 27 are highly independent of the cascade region.** Joint/min-single ratios with cascade-region boundaries (3-8) are 0.007-0.010 — essentially uncorrelated. This is what makes them structurally valuable in the minimum-boundary set: they eliminate solutions that the cascade region cannot.

This explains why the minimum 4-set picks {2, 21, 25, 27}: position 2 catches the high-entropy choice at the front, 21 catches the cascade-end transition, and 25 and 27 contribute *independent* information not implied by any other boundary.

### Within-pair orient freedom: a constraint-geometry finding (not KW-specific)

King Wen appears 4 times in the 742M dataset: same pair sequence at every position, but differing in within-pair orientation at exactly 5 positions: {2, 3, 28, 29, 30}. Early inspection suggested this might be a KW-specific "hidden symmetry" — it is not. Running the orient-coupling generalization analysis (`./solve --analyze`, section [14]) across all 742M solutions shows:

- **The 742M records collapse to 284.7M distinct pair-orderings** (when within-pair orient is masked), meaning there are on average 2.6 orient variants per unique pair sequence.
- **The maximum number of orient variants per pair-ordering is 4.** 98.7 million pair-orderings share KW's 4-variant pattern; 125.9M have 2 variants; 42.4M have only 1; 17.7M have 3. No pair-ordering has more than 4 variants.
- **Within-pair orient is *forced* at positions 5-20 across every valid ordering.** At positions 6-19, exactly 0% of pair-orderings show any orient variation; position 5 is 0.002%; position 20 is 0.049%. The constraint system (Rules 2 and 5) completely determines within-pair orient in this "cascade region."
- **Orient freedom is concentrated at positions 2, 3, and 21-32.** Position 2 flexes in 81% of pair-orderings, position 3 in 69%, position 32 in 15%, positions 21-31 in 7-14% each.

So KW's 4-variant orient pattern is **at the maximum possible but not unique** — it's a feature of the constraint geometry, not of King Wen specifically. The stronger result is the negative finding: within-pair orient is completely locked across the cascade region for every valid ordering the constraints admit.

## The numbers at a glance

| Step | Rule | Arrangements remaining |
|------|------|----------------------|
| 0 | All possible orderings | 10^89 |
| 1 | Pair structure | 10^45 |
| 2 | No 5-line jumps | ~4% of step 1 |
| 3 | Opposites kept close (3.9th percentile) | ~0.3% of step 1 |
| 4 | Start with Heaven/Earth | ~0.005% of step 1 |
| 5 | Specific transition counts | **at least 742 million** (partial enumeration at 10T nodes) |
| 6 | 4 boundary constraints | **1 (King Wen)** |

## An important caveat

Applying the same methodology to random pair-constrained sequences — extract their diff distribution, complement distance, and starting pair, then test for uniqueness — also produces apparent uniqueness in 9 out of 10 cases. **The constraint extraction approach makes almost any sequence appear uniquely determined.** This means Rules 3-7 are not individually remarkable — any sequence's specific properties would similarly narrow the search space.

What IS genuinely special about King Wen is **Rules 1 and 2**: the perfect pair structure and the no-5-line-transition property. Only ~4% of pair-constrained orderings avoid 5-line transitions. The pair structure itself is vanishingly unlikely by chance. These two properties are real discoveries, not artifacts of the methodology.

## What we can and cannot say

The analysis shows the King Wen sequence satisfies a set of interlocking mathematical constraints. It cannot show whether the designers understood those constraints explicitly or arrived at them through centuries of refinement. A simple practice — "pair each hexagram with its mirror, keep opposites nearby, avoid jarring transitions" — applied consistently over generations could produce the same result as deliberate mathematical design. The sequence is the same either way; only the history differs, and the history is outside the reach of computation.

For full technical details, methodology, and reproducible commands, see [SOLVE.md](SOLVE.md).

<a id="appendix-all-32-complement-pairs-by-distance"></a>
## Appendix: All 32 complement pairs by distance

Visualization of [Rule 3 (Opposites stay close)](#rule-3). Each line shows the King Wen sequence with one complement pair highlighted. Sorted from closest (distance 1 — adjacent) to farthest (distance 47). The mean across all 32 pairs is 12.1.

Close complement pairs (distance 1-7) are always in the same half of the sequence. Far complement pairs (distance 19+) always cross the midpoint. No exceptions. (Note: some distance groups show highlights on both sides — e.g., distance 6 has four pairs, two in the first half and two in the second. Each individual pair stays in its own half.)

Multi-pair distances always come in groups of 2 (e.g., 5↔35 AND 6↔36). This is because complementation maps King Wen pairs to King Wen pairs: if A and reverse(A) form a pair, then complement(A) and complement(reverse(A)) also form a pair. So both members of one pair always point to members of the same other pair, at the same distance.

Distance 1 (9 pairs):<br>
<mark>**䷀䷁**</mark> ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ <mark>**䷊䷋**</mark> ䷌䷍ ䷎䷏ <mark>**䷐䷑**</mark> ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ <mark>**䷚䷛**</mark> <mark>**䷜䷝**</mark> ䷞䷟ ䷠䷡ ䷢䷣ ䷤<mark>**䷥**</mark> <mark>**䷦**</mark>䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ <mark>**䷴䷵**</mark> ䷶䷷ ䷸䷹ ䷺䷻ <mark>**䷼䷽**</mark> <mark>**䷾䷿**</mark><br>
Pairs: 1↔2, 11↔12, 17↔18, 27↔28, 29↔30, 38↔39, 53↔54, 61↔62, 63↔64

Distance 3 (1 pair):<br>
䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ <mark>**䷤**</mark>䷥ ䷦<mark>**䷧**</mark> ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿<br>
Pair: 37↔40

Distance 4 (2 pairs):<br>
䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ <mark>**䷶䷷**</mark> ䷸䷹ <mark>**䷺䷻**</mark> ䷼䷽ ䷾䷿<br>
Pairs: 55↔59, 56↔60

Distance 5 (1 pair):<br>
䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ ䷈<mark>**䷉**</mark> ䷊䷋ ䷌䷍ <mark>**䷎**</mark>䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿<br>
Pair: 10↔15

Distance 6 (4 pairs):<br>
䷀䷁ ䷂䷃ ䷄䷅ <mark>**䷆䷇**</mark> ䷈䷉ ䷊䷋ <mark>**䷌䷍**</mark> ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ <mark>**䷲䷳**</mark> ䷴䷵ ䷶䷷ <mark>**䷸䷹**</mark> ䷺䷻ ䷼䷽ ䷾䷿<br>
Pairs: 7↔13, 8↔14, 51↔57, 52↔58

Distance 7 (1 pair):<br>
䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ <mark>**䷈**</mark>䷉ ䷊䷋ ䷌䷍ ䷎<mark>**䷏**</mark> ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿<br>
Pair: 9↔16

Distance 10 (2 pairs):<br>
䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ <mark>**䷞䷟**</mark> ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ <mark>**䷨䷩**</mark> ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿<br>
Pairs: 31↔41, 32↔42

Distance 14 (2 pairs):<br>
䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ <mark>**䷒䷓**</mark> ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ <mark>**䷠䷡**</mark> ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿<br>
Pairs: 19↔33, 20↔34

Distance 19 (1 pair):<br>
䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘<mark>**䷙**</mark> ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ <mark>**䷬**</mark>䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿<br>
Pair: 26↔45

Distance 20 (2 pairs):<br>
䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ <mark>**䷖䷗**</mark> ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ <mark>**䷪䷫**</mark> ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿<br>
Pairs: 23↔43, 24↔44

Distance 21 (1 pair):<br>
䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ <mark>**䷘**</mark>䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬<mark>**䷭**</mark> ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿<br>
Pair: 25↔46

Distance 25 (1 pair):<br>
䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔<mark>**䷕**</mark> ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ <mark>**䷮**</mark>䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿<br>
Pair: 22↔47

Distance 27 (1 pair):<br>
䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ <mark>**䷔**</mark>䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮<mark>**䷯**</mark> ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿<br>
Pair: 21↔48

Distance 30 (2 pairs):<br>
䷀䷁ ䷂䷃ <mark>**䷄䷅**</mark> ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ <mark>**䷢䷣**</mark> ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿<br>
Pairs: 5↔35, 6↔36

Distance 45 (1 pair):<br>
䷀䷁ ䷂<mark>**䷃**</mark> ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ <mark>**䷰**</mark>䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿<br>
Pair: 4↔49

Distance 47 (1 pair):<br>
䷀䷁ <mark>**䷂**</mark>䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰<mark>**䷱**</mark> ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿<br>
Pair: 3↔50

<a id="appendix-all-63-transitions"></a>
## Appendix: All 63 transitions in the King Wen sequence

Every consecutive hexagram transition, showing the number of lines that change
([Hamming distance](https://en.wikipedia.org/wiki/Hamming_distance)).
A distance of 5 never occurs — this is [Rule 2](#rule-2-no-5-line-jumps).

The difference wave as a sparkline (each character = one transition, height = lines changed):

`█▂▅▅▅▃▂▅▂▅█▂▂▅▂▂█▃▅▃▂▂▂▃▅▂█▂█▃▂▃▅▅▅▂▅█▅▃▂▅▂▃▅▃▂▃▅▅▅▁█▂▂▃▅▃▂▁█▃█`

**The difference wave** — the sequence of Hamming distances read left to right:

`6 2 4 4 4 3 2 4 2 4 6 2 2 4 2 2 6 3 4 3 2 2 2 3 4 2 6 2 6 3 2 3 4 4 4 2 4 6 4 3 2 4 2 3 4 3 2 3 4 4 4 1 6 2 2 3 4 3 2 1 6 3 6`

**Transition counts:** 1: 2, 2: 20, 3: 13, 4: 19, **5: 0 (never)**, 6: 9

| # | From | To | Distance |
|--:|------|-----|:--------:|
| 1 | ䷀ #1 The Creative | ䷁ #2 The Receptive | 6 |
| 2 | ䷁ #2 The Receptive | ䷂ #3 Difficulty | 2 |
| 3 | ䷂ #3 Difficulty | ䷃ #4 Youthful Folly | 4 |
| 4 | ䷃ #4 Youthful Folly | ䷄ #5 Waiting | 4 |
| 5 | ䷄ #5 Waiting | ䷅ #6 Conflict | 4 |
| 6 | ䷅ #6 Conflict | ䷆ #7 The Army | 3 |
| 7 | ䷆ #7 The Army | ䷇ #8 Holding Together | 2 |
| 8 | ䷇ #8 Holding Together | ䷈ #9 Small Taming | 4 |
| 9 | ䷈ #9 Small Taming | ䷉ #10 Treading | 2 |
| 10 | ䷉ #10 Treading | ䷊ #11 Peace | 4 |
| 11 | ䷊ #11 Peace | ䷋ #12 Standstill | 6 |
| 12 | ䷋ #12 Standstill | ䷌ #13 Fellowship | 2 |
| 13 | ䷌ #13 Fellowship | ䷍ #14 Great Possession | 2 |
| 14 | ䷍ #14 Great Possession | ䷎ #15 Modesty | 4 |
| 15 | ䷎ #15 Modesty | ䷏ #16 Enthusiasm | 2 |
| 16 | ䷏ #16 Enthusiasm | ䷐ #17 Following | 2 |
| 17 | ䷐ #17 Following | ䷑ #18 Decay | 6 |
| 18 | ䷑ #18 Decay | ䷒ #19 Approach | 3 |
| 19 | ䷒ #19 Approach | ䷓ #20 Contemplation | 4 |
| 20 | ䷓ #20 Contemplation | ䷔ #21 Biting Through | 3 |
| 21 | ䷔ #21 Biting Through | ䷕ #22 Grace | 2 |
| 22 | ䷕ #22 Grace | ䷖ #23 Splitting Apart | 2 |
| 23 | ䷖ #23 Splitting Apart | ䷗ #24 Return | 2 |
| 24 | ䷗ #24 Return | ䷘ #25 Innocence | 3 |
| 25 | ䷘ #25 Innocence | ䷙ #26 Great Taming | 4 |
| 26 | ䷙ #26 Great Taming | ䷚ #27 Nourishment | 2 |
| 27 | ䷚ #27 Nourishment | ䷛ #28 Preponderance of Great | 6 |
| 28 | ䷛ #28 Preponderance of Great | ䷜ #29 The Abysmal | 2 |
| 29 | ䷜ #29 The Abysmal | ䷝ #30 The Clinging | 6 |
| 30 | ䷝ #30 The Clinging | ䷞ #31 Influence | 3 |
| 31 | ䷞ #31 Influence | ䷟ #32 Duration | 2 |
| 32 | ䷟ #32 Duration | ䷠ #33 Retreat | 3 |
| 33 | ䷠ #33 Retreat | ䷡ #34 Great Power | 4 |
| 34 | ䷡ #34 Great Power | ䷢ #35 Progress | 4 |
| 35 | ䷢ #35 Progress | ䷣ #36 Darkening | 4 |
| 36 | ䷣ #36 Darkening | ䷤ #37 The Family | 2 |
| 37 | ䷤ #37 The Family | ䷥ #38 Opposition | 4 |
| 38 | ䷥ #38 Opposition | ䷦ #39 Obstruction | 6 |
| 39 | ䷦ #39 Obstruction | ䷧ #40 Deliverance | 4 |
| 40 | ䷧ #40 Deliverance | ䷨ #41 Decrease | 3 |
| 41 | ䷨ #41 Decrease | ䷩ #42 Increase | 2 |
| 42 | ䷩ #42 Increase | ䷪ #43 Breakthrough | 4 |
| 43 | ䷪ #43 Breakthrough | ䷫ #44 Coming to Meet | 2 |
| 44 | ䷫ #44 Coming to Meet | ䷬ #45 Gathering | 3 |
| 45 | ䷬ #45 Gathering | ䷭ #46 Pushing Upward | 4 |
| 46 | ䷭ #46 Pushing Upward | ䷮ #47 Oppression | 3 |
| 47 | ䷮ #47 Oppression | ䷯ #48 The Well | 2 |
| 48 | ䷯ #48 The Well | ䷰ #49 Revolution | 3 |
| 49 | ䷰ #49 Revolution | ䷱ #50 The Cauldron | 4 |
| 50 | ䷱ #50 The Cauldron | ䷲ #51 The Arousing | 4 |
| 51 | ䷲ #51 The Arousing | ䷳ #52 Keeping Still | 4 |
| 52 | ䷳ #52 Keeping Still | ䷴ #53 Development | 1 |
| 53 | ䷴ #53 Development | ䷵ #54 Marrying Maiden | 6 |
| 54 | ䷵ #54 Marrying Maiden | ䷶ #55 Abundance | 2 |
| 55 | ䷶ #55 Abundance | ䷷ #56 The Wanderer | 2 |
| 56 | ䷷ #56 The Wanderer | ䷸ #57 The Gentle | 3 |
| 57 | ䷸ #57 The Gentle | ䷹ #58 The Joyous | 4 |
| 58 | ䷹ #58 The Joyous | ䷺ #59 Dispersion | 3 |
| 59 | ䷺ #59 Dispersion | ䷻ #60 Limitation | 2 |
| 60 | ䷻ #60 Limitation | ䷼ #61 Inner Truth | 1 |
| 61 | ䷼ #61 Inner Truth | ䷽ #62 Small Preponderance | 6 |
| 62 | ䷽ #62 Small Preponderance | ䷾ #63 After Completion | 3 |
| 63 | ䷾ #63 After Completion | ䷿ #64 Before Completion | 6 |
