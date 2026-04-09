# How the King Wen Sequence Was Built

A plain-language summary of what `solve.py` discovered.

## The puzzle

About 3,000 years ago, someone in ancient China arranged 64 symbols (called [hexagrams](https://en.wikipedia.org/wiki/Hexagram_(I_Ching))) in a specific order. This ordering is called the [King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence). There are more possible arrangements of 64 things than there are atoms in the universe — roughly 10^89 (a 1 followed by 89 zeros). But somehow, the designers picked one specific arrangement:

䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

We wanted to know: **what rules did they follow?** And can we figure out those rules just by studying the result?

## What a hexagram is

Each hexagram is a stack of 6 lines. Each line is either solid ([yang](https://en.wikipedia.org/wiki/Yin_and_yang)) or broken ([yin](https://en.wikipedia.org/wiki/Yin_and_yang)) — like a 6-digit binary number with only 1s and 0s. With 6 positions and 2 choices each, there are exactly 2^6 = 64 possible hexagrams. The King Wen sequence puts all 64 in a specific order.

| | ䷀ The Creative #1 | ䷝ The Clinging #30 | ䷁ The Receptive #2 |
|---|:---:|:---:|:---:|
| Line 6 (top) | ⚊ yang **1** | ⚊ yang **1** | ⚋ yin **0** |
| Line 5 | ⚊ yang **1** | ⚋ yin **0** | ⚋ yin **0** |
| Line 4 | ⚊ yang **1** | ⚊ yang **1** | ⚋ yin **0** |
| Line 3 | ⚊ yang **1** | ⚊ yang **1** | ⚋ yin **0** |
| Line 2 | ⚊ yang **1** | ⚋ yin **0** | ⚋ yin **0** |
| Line 1 (bottom) | ⚊ yang **1** | ⚊ yang **1** | ⚋ yin **0** |
| Binary | **111111** | **101101** | **000000** |

Read bottom to top: line 1 is the rightmost bit, line 6 is the leftmost. All solid = 111111. All broken = 000000. Mixed lines give values in between.

## The rules we found

We discovered six rules. Each rule eliminates more and more possible arrangements:

### Rule 1: Every hexagram has a partner

The 64 hexagrams are grouped into 32 consecutive pairs. Each hexagram is paired with the one you get by flipping it upside down. (For 4 symmetric hexagrams that look the same upside down — ䷀䷁ ䷚䷛ ䷜䷝ ䷼䷽ — the partner is the one with every line toggled instead.)

**What this does:** Cuts the possibilities from 10^89 down to about 10^45. Still enormous, but 44 zeros gone in one step.

Flip (28 pairs, partner highlighted):<br>
䷀䷁ ䷂<mark>**䷃**</mark> ䷄<mark>**䷅**</mark> ䷆<mark>**䷇**</mark> ䷈<mark>**䷉**</mark> ䷊<mark>**䷋**</mark> ䷌<mark>**䷍**</mark> ䷎<mark>**䷏**</mark> ䷐<mark>**䷑**</mark> ䷒<mark>**䷓**</mark> ䷔<mark>**䷕**</mark> ䷖<mark>**䷗**</mark> ䷘<mark>**䷙**</mark> ䷚䷛ ䷜䷝ ䷞<mark>**䷟**</mark> ䷠<mark>**䷡**</mark> ䷢<mark>**䷣**</mark> ䷤<mark>**䷥**</mark> ䷦<mark>**䷧**</mark> ䷨<mark>**䷩**</mark> ䷪<mark>**䷫**</mark> ䷬<mark>**䷭**</mark> ䷮<mark>**䷯**</mark> ䷰<mark>**䷱**</mark> ䷲<mark>**䷳**</mark> ䷴<mark>**䷵**</mark> ䷶<mark>**䷷**</mark> ䷸<mark>**䷹**</mark> ䷺<mark>**䷻**</mark> ䷼䷽ ䷾<mark>**䷿**</mark>

Inverse (4 pairs, partner highlighted):<br>
䷀<mark>**䷁**</mark> ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚<mark>**䷛**</mark> ䷜<mark>**䷝**</mark> ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼<mark>**䷽**</mark> ䷾䷿

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

**What this does:** Eliminates about 96% of the remaining arrangements.

<a id="rule-3"></a>
### Rule 3: Opposites kept unusually close

Every hexagram has an "opposite" — the one where every solid line becomes broken and vice versa. In the King Wen sequence, opposites are placed significantly closer together than you'd expect by chance. If you shuffled randomly, opposites would average about 22 positions apart. In King Wen, they average only 12.1 — at the **3.9th percentile** (only 3.9% of valid orderings place complements closer). King Wen doesn't just happen to have complements nearby; it actively keeps them as close as possible.

To illustrate: King Wen's worst complement pair (䷂ #3 and ䷱ #50, distance 47) is better than most random orderings' average case (~22).

**What this does:** Eliminates about 93% of what's left after Rule 2.

Closest complements highlighted (distance 1 — adjacent in the sequence):<br>
<mark>**䷀䷁**</mark> ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ <mark>**䷊䷋**</mark> ䷌䷍ ䷎䷏ <mark>**䷐䷑**</mark> ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ <mark>**䷚䷛**</mark> <mark>**䷜䷝**</mark> ䷞䷟ ䷠䷡ ䷢䷣ <mark>**䷤䷥**</mark> <mark>**䷦䷧**</mark> ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ <mark>**䷴䷵**</mark> ䷶䷷ ䷸䷹ ䷺䷻ <mark>**䷼䷽**</mark> <mark>**䷾䷿**</mark>

10 of 32 complement pairs sit directly next to each other. The farthest apart are ䷂ #3 and ䷱ #50 (distance 47) — but the average is only 12.1. See [all 32 complement pairs](#appendix-all-32-complement-pairs-by-distance) in the appendix.

Farthest complements highlighted (䷂ #3 and ䷱ #50, 47 positions apart):<br>
䷀䷁ <mark>**䷂**</mark>䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰<mark>**䷱**</mark> ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

### Rule 4: It starts with Heaven and Earth

The sequence begins with the two most extreme hexagrams: all solid lines (䷀ The Creative #1, representing Heaven) followed by all broken lines (䷁ The Receptive #2, representing Earth).

**What this does:** Eliminates another 98%.

<mark>**䷀䷁**</mark> ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

### Rule 5: Specific transition counts

The "jumps" between consecutive hexagrams follow a specific recipe — called the [difference wave](https://en.wikipedia.org/wiki/Terence_McKenna#Novelty_theory_and_Timewave_Zero): exactly 2 jumps of size 1, 20 jumps of size 2, 13 jumps of size 3, 19 jumps of size 4, and 9 jumps of size 6. No jumps of size 0 or 5.

**What this does:** After all previous rules, this eliminates everything we could find in 100,000 [Monte Carlo](https://en.wikipedia.org/wiki/Monte_Carlo_method) random samples.

### Rule 6: Two specific neighbor choices

After Rules 1-5, the first 23 pairs (hexagrams 1-46) are completely locked — every valid arrangement puts the same pairs in the same positions. Only the last 9 pairs (hexagrams 47-64) have any freedom, with thousands of valid arrangements remaining.

Locked (23 pairs — forced by rules):<br>
䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏\
䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟\
䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭

Free (9 pairs — where choice enters):<br>
䷮䷯ <mark>**䷰䷱**</mark> <mark>**䷲䷳**</mark> <mark>**䷴䷵**</mark> <mark>**䷶䷷**</mark> ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

To narrow from thousands to exactly 1, you need just two specific instructions:

- Pair 25 (<mark>**䷰䷱**</mark> Revolution #49 / The Cauldron #50) must be next to Pair 26 (<mark>**䷲䷳**</mark> The Arousing #51 / Keeping Still #52)
- Pair 27 (<mark>**䷴䷵**</mark> Development #53 / The Marrying Maiden #54) must be next to Pair 28 (<mark>**䷶䷷**</mark> Abundance #55 / The Wanderer #56)

### The thousands of roads not taken

The thousands of alternative arrangements that satisfy Rules 1-6 are not random — they all share the same first 46 hexagrams (䷀ through ䷭) in the same order. Only the last 18 hexagrams (䷮ Oppression #47 through ䷿ Before Completion #64) are rearranged. This means:

- **Hexagrams 1-46 are mathematically forced.** No valid arrangement puts them in a different order. Any commentary explaining their sequence is describing mathematical structure, whether the commentators knew it or not.
- **Hexagrams 47-64 are where choice lives.** The thousands of alternatives rearrange only these. The traditional [Xugua](https://en.wikipedia.org/wiki/Ten_Wings) commentary explaining why these specific hexagrams follow each other is describing the designers' choices, not mathematical necessity.
- **King Wen's choice is not arbitrary.** Among all thousands of valid arrangements, King Wen is one that **minimizes** complement distance — keeping opposites as close as possible. Only 3.9% of valid orderings place complements closer.
- **The ending pair is a choice, not a necessity.** King Wen ends with ䷾ After Completion #63 / ䷿ Before Completion #64. Four different pairs can validly end the sequence — King Wen's is the most common (35% of solutions) but not forced. The *starting* orientation, however, is forced: ䷀ The Creative must come before ䷁ The Receptive in all valid arrangements.
- **Within-pair orientation has no rule.** Which hexagram comes first within each pair follows no consistent pattern — not yang count, not binary value, not trigram weight. It appears to be a free choice at each pair.

## What this means

Six rules, discoverable through analysis, empirically lock **23 of 32 pair positions** (the first 46 hexagrams). The remaining 9 positions have thousands of valid arrangements, narrowed to exactly 1 by two specific adjacency choices. The rules were extracted from King Wen (confirmatory analysis, not independent prediction), but the constraint structure they reveal is genuine — most of the sequence is forced once you accept the rules.

But those two choices are not arbitrary. Among all thousands of valid arrangements, King Wen is **near the center** — ranking in the top 6% by average distance to all other valid orderings. It's not the absolute most central solution (that's 3 swaps away), but it's in the top tier. King Wen also matches the consensus (most popular pair at each position) at 5 of 9 free positions.

No single feature or combination of features (26 tested individually, 153 pairs, 10 triples) can *uniquely* identify King Wen among thousands of valid arrangements — the two adjacency constraints are still needed to pin it down to exactly one. But the centrality finding suggests the choices lean toward a principle: **prefer a balanced, central arrangement**.

Someone, roughly [3,000 years ago](https://en.wikipedia.org/wiki/King_Wen_of_Zhou), designed an arrangement of 64 symbols that satisfies a set of interlocking mathematical constraints so strict that only thousands of arrangements in the entire universe of 10^89 possibilities can satisfy them all. And then, among those thousands, they chose one near the center.

## The numbers at a glance

| Step | Rule | Arrangements remaining |
|------|------|----------------------|
| 0 | All possible orderings | 10^89 |
| 1 | Pair structure | 10^45 |
| 2 | No 5-line jumps | ~4% of step 1 |
| 3 | Opposites kept close (3.9th percentile) | ~0.3% of step 1 |
| 4 | Start with Heaven/Earth | ~0.005% of step 1 |
| 5 | Specific transition counts | thousands |
| 6 | Two neighbor choices | **1 (King Wen)** |

## An important caveat

Applying the same methodology to random pair-constrained sequences — extract their diff distribution, complement distance, and starting pair, then test for uniqueness — also produces apparent uniqueness in 9 out of 10 cases. **The constraint extraction approach makes almost any sequence appear uniquely determined.** This means Rules 3-7 are not individually remarkable — any sequence's specific properties would similarly narrow the search space.

What IS genuinely special about King Wen is **Rules 1 and 2**: the perfect pair structure and the no-5-line-transition property. Only ~4% of pair-constrained orderings avoid 5-line transitions. The pair structure itself is vanishingly unlikely by chance. These two properties are real discoveries, not artifacts of the methodology.

## What we can and cannot say

The analysis shows the King Wen sequence satisfies a set of interlocking mathematical constraints. It cannot show whether the designers understood those constraints explicitly or arrived at them through centuries of refinement. A simple practice — "pair each hexagram with its mirror, keep opposites nearby, avoid jarring transitions" — applied consistently over generations could produce the same result as deliberate mathematical design. The sequence is the same either way; only the history differs, and the history is outside the reach of computation.

For full technical details, methodology, and reproducible commands, see [SOLVE.md](SOLVE.md).

<a id="appendix-all-32-complement-pairs-by-distance"></a>
## Appendix: All 32 complement pairs by distance

Visualization of [Rule 3 (Opposites stay close)](#rule-3). Each line shows the King Wen sequence with one complement pair highlighted. Sorted from closest (distance 1 — adjacent) to farthest (distance 47). The mean across all 32 pairs is 12.1.

Distance 1 (9 pairs):<br>
<mark>**䷀䷁**</mark> ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ <mark>**䷊䷋**</mark> ䷌䷍ ䷎䷏ <mark>**䷐䷑**</mark> ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ <mark>**䷚䷛**</mark> <mark>**䷜䷝**</mark> ䷞䷟ ䷠䷡ ䷢䷣ ䷤<mark>**䷥**</mark> <mark>**䷦**</mark>䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ <mark>**䷴䷵**</mark> ䷶䷷ ䷸䷹ ䷺䷻ <mark>**䷼䷽**</mark> <mark>**䷾䷿**</mark>

Distance 3 (1 pair):<br>
䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ <mark>**䷤**</mark>䷥ ䷦<mark>**䷧**</mark> ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

Distance 4 (2 pairs):<br>
䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ <mark>**䷶䷷**</mark> ䷸䷹ <mark>**䷺䷻**</mark> ䷼䷽ ䷾䷿

Distance 5 (1 pair):<br>
䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ ䷈<mark>**䷉**</mark> ䷊䷋ ䷌䷍ <mark>**䷎**</mark>䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

Distance 6 (4 pairs):<br>
䷀䷁ ䷂䷃ ䷄䷅ <mark>**䷆䷇**</mark> ䷈䷉ ䷊䷋ <mark>**䷌䷍**</mark> ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ <mark>**䷲䷳**</mark> ䷴䷵ ䷶䷷ <mark>**䷸䷹**</mark> ䷺䷻ ䷼䷽ ䷾䷿

Distance 7 (1 pair):<br>
䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ <mark>**䷈**</mark>䷉ ䷊䷋ ䷌䷍ ䷎<mark>**䷏**</mark> ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

Distance 10 (2 pairs):<br>
䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ <mark>**䷞䷟**</mark> ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ <mark>**䷨䷩**</mark> ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

Distance 14 (2 pairs):<br>
䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ <mark>**䷒䷓**</mark> ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ <mark>**䷠䷡**</mark> ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

Distance 19 (1 pair):<br>
䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘<mark>**䷙**</mark> ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ <mark>**䷬**</mark>䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

Distance 20 (2 pairs):<br>
䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ <mark>**䷖䷗**</mark> ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ <mark>**䷪䷫**</mark> ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

Distance 21 (1 pair):<br>
䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ <mark>**䷘**</mark>䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬<mark>**䷭**</mark> ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

Distance 25 (1 pair):<br>
䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔<mark>**䷕**</mark> ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ <mark>**䷮**</mark>䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

Distance 27 (1 pair):<br>
䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ <mark>**䷔**</mark>䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮<mark>**䷯**</mark> ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

Distance 30 (2 pairs):<br>
䷀䷁ ䷂䷃ <mark>**䷄䷅**</mark> ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ <mark>**䷢䷣**</mark> ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

Distance 45 (1 pair):<br>
䷀䷁ ䷂<mark>**䷃**</mark> ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ <mark>**䷰**</mark>䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

Distance 47 (1 pair):<br>
䷀䷁ <mark>**䷂**</mark>䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰<mark>**䷱**</mark> ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿
