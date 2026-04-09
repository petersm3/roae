# How the King Wen Sequence Was Built

A plain-language summary of what `solve.py` discovered.

## The puzzle

About 3,000 years ago, someone in ancient China arranged 64 symbols (called [hexagrams](https://en.wikipedia.org/wiki/Hexagram_(I_Ching))) in a specific order. This ordering is called the [King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence). There are more possible arrangements of 64 things than there are atoms in the universe — roughly 10^89 (a 1 followed by 89 zeros). But somehow, the designers picked one specific arrangement:

䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

We wanted to know: **what rules did they follow?** And can we figure out those rules just by studying the result?

## What a hexagram is

Each hexagram is a stack of 6 lines. Each line is either solid ([yang](https://en.wikipedia.org/wiki/Yin_and_yang)) or broken (yin) — like a 6-digit binary number with only 1s and 0s. With 6 positions and 2 choices each, there are exactly 2^6 = 64 possible hexagrams. The King Wen sequence puts all 64 in a specific order.

## The rules we found

We discovered 7 mathematical rules. Each rule eliminates more and more possible arrangements:

### Rule 1: Every hexagram has a partner

The 64 hexagrams are grouped into 32 consecutive pairs. Each hexagram is paired with the one you get by flipping it upside down. (For 4 symmetric hexagrams that look the same upside down — ䷀䷁ ䷚䷛ ䷜䷝ ䷼䷽ — the partner is the one with every line toggled instead.)

**What this does:** Cuts the possibilities from 10^89 down to about 10^45. Still enormous, but 44 zeros gone in one step.

<table>
<tr><td><b>Flip:</b></td><td>䷀䷁</td><td>䷂<mark><b>䷃</b></mark></td><td>䷄<mark><b>䷅</b></mark></td><td>䷆<mark><b>䷇</b></mark></td><td>䷈<mark><b>䷉</b></mark></td><td>䷊<mark><b>䷋</b></mark></td><td>䷌<mark><b>䷍</b></mark></td><td>䷎<mark><b>䷏</b></mark></td><td>䷐<mark><b>䷑</b></mark></td><td>䷒<mark><b>䷓</b></mark></td><td>䷔<mark><b>䷕</b></mark></td><td>䷖<mark><b>䷗</b></mark></td><td>䷘<mark><b>䷙</b></mark></td><td>䷚䷛</td><td>䷜䷝</td><td>䷞<mark><b>䷟</b></mark></td><td>䷠<mark><b>䷡</b></mark></td><td>䷢<mark><b>䷣</b></mark></td><td>䷤<mark><b>䷥</b></mark></td><td>䷦<mark><b>䷧</b></mark></td><td>䷨<mark><b>䷩</b></mark></td><td>䷪<mark><b>䷫</b></mark></td><td>䷬<mark><b>䷭</b></mark></td><td>䷮<mark><b>䷯</b></mark></td><td>䷰<mark><b>䷱</b></mark></td><td>䷲<mark><b>䷳</b></mark></td><td>䷴<mark><b>䷵</b></mark></td><td>䷶<mark><b>䷷</b></mark></td><td>䷸<mark><b>䷹</b></mark></td><td>䷺<mark><b>䷻</b></mark></td><td>䷼䷽</td><td>䷾<mark><b>䷿</b></mark></td></tr>
<tr><td><b>Inverse:</b></td><td>䷀<mark><b>䷁</b></mark></td><td>䷂䷃</td><td>䷄䷅</td><td>䷆䷇</td><td>䷈䷉</td><td>䷊䷋</td><td>䷌䷍</td><td>䷎䷏</td><td>䷐䷑</td><td>䷒䷓</td><td>䷔䷕</td><td>䷖䷗</td><td>䷘䷙</td><td>䷚<mark><b>䷛</b></mark></td><td>䷜<mark><b>䷝</b></mark></td><td>䷞䷟</td><td>䷠䷡</td><td>䷢䷣</td><td>䷤䷥</td><td>䷦䷧</td><td>䷨䷩</td><td>䷪䷫</td><td>䷬䷭</td><td>䷮䷯</td><td>䷰䷱</td><td>䷲䷳</td><td>䷴䷵</td><td>䷶䷷</td><td>䷸䷹</td><td>䷺䷻</td><td>䷼<mark><b>䷽</b></mark></td><td>䷾䷿</td></tr>
</table>

### Rule 2: No 5-line jumps

When you move from one hexagram to the next, some number of lines change (1 through 6). This is called the [Hamming distance](https://en.wikipedia.org/wiki/Hamming_distance). In the King Wen sequence, the number 5 never appears — no two consecutive hexagrams differ by exactly 5 lines.

**What this does:** Eliminates about 96% of the remaining arrangements.

### Rule 3: Opposites stay close

Every hexagram has an "opposite" — the one where every solid line becomes broken and vice versa. In the King Wen sequence, opposites are placed significantly closer together than you'd expect by chance. If you shuffled randomly, opposites would average about 22 positions apart. In King Wen, they average about 12.

**What this does:** Eliminates about 93% of what's left after Rule 2.

### Rule 4: It starts with Heaven and Earth

The sequence begins with the two most extreme hexagrams: all solid lines (䷀ The Creative #1, representing Heaven) followed by all broken lines (䷁ The Receptive #2, representing Earth).

**What this does:** Eliminates another 98%.

<mark>**䷀䷁**</mark> ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

### Rule 5: Specific transition counts

The "jumps" between consecutive hexagrams follow a specific recipe — called the [difference wave](https://en.wikipedia.org/wiki/Terence_McKenna#Novelty_theory_and_Timewave_Zero): exactly 2 jumps of size 1, 20 jumps of size 2, 13 jumps of size 3, 19 jumps of size 4, and 9 jumps of size 6. No jumps of size 0 or 5.

**What this does:** After all previous rules, this eliminates everything we could find in 100,000 [Monte Carlo](https://en.wikipedia.org/wiki/Monte_Carlo_method) random samples.

### Rule 6: Opposites as far apart as the rules allow

This is the surprising one. Rule 3 says opposites must be close (average distance ≤ 12.1). Among ALL arrangements satisfying Rules 1-5, King Wen has the **maximum** complement distance — exactly 12.1. It doesn't just keep opposites close. It keeps them as far apart as the constraint allows, as if balancing closeness against some other goal.

### Rule 7: Two specific neighbor choices

After Rules 1-6, the first 23 pairs (hexagrams 1-46) are completely locked — every valid arrangement puts the same pairs in the same positions. Only the last 9 pairs (hexagrams 47-64) have any freedom, with about 450 valid arrangements remaining.

To narrow from 450 to exactly 1, you need just two specific instructions:

- Pair 25 (䷰ Revolution #49 / ䷱ The Cauldron #50) must be next to Pair 26 (䷲ The Arousing #51 / ䷳ Keeping Still #52)
- Pair 27 (䷴ Development #53 / ䷵ The Marrying Maiden #54) must be next to Pair 28 (䷶ Abundance #55 / ䷷ The Wanderer #56)

䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ <mark>**䷰䷱**</mark> <mark>**䷲䷳**</mark> <mark>**䷴䷵**</mark> <mark>**䷶䷷**</mark> ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

## What this means

The King Wen sequence is **97% determined by mathematics**. Seven rules, discoverable through analysis, lock 23 of 32 pair positions. The remaining 3% — two specific choices about which pairs sit next to each other — is where human creativity enters. Those two choices have no mathematical explanation we can find. They may reflect philosophical ideas, cosmological beliefs, or aesthetic preferences that are invisible to a computer.

Someone, roughly [3,000 years ago](https://en.wikipedia.org/wiki/King_Wen_of_Zhou), designed an arrangement of 64 symbols that satisfies a set of interlocking mathematical constraints so strict that only about 450 arrangements in the entire universe of 10^89 possibilities can satisfy them all. And then, among those 450, they made two specific choices that we can identify but cannot explain.

## The numbers at a glance

| Step | Rule | Arrangements remaining |
|------|------|----------------------|
| 0 | All possible orderings | 10^89 |
| 1 | Pair structure | 10^45 |
| 2 | No 5-line jumps | ~4% of step 1 |
| 3 | Opposites stay close | ~0.3% of step 1 |
| 4 | Start with Heaven/Earth | ~0.005% of step 1 |
| 5 | Specific transition counts | ~0 in 100,000 samples |
| 6 | Maximum complement distance | ~450 |
| 7 | Two neighbor choices | **1 (King Wen)** |

For full technical details, methodology, and reproducible commands, see [SOLVE.md](SOLVE.md).
