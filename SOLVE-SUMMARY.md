# How the King Wen Sequence Was Built

A plain-language introduction to what `solve.py` and `solve.c` compute. Several of the core observations (the pair structure C1, the no-5-line-transition property C2) have been noted in prior literature — see [CITATIONS.md](CITATIONS.md) for credits. ROAE's specific contribution is **exhaustive enumeration** of solutions under the conjoined constraint system, **partition-invariant reproducibility** of the canonical counts, and a **seven-family null-model framework** testing how the King Wen structure compares to structured and unstructured permutation families.

For deeper material referenced throughout this article:

- Canonical enumeration counts and their reproducibility shas: [CLAUDE.md §Canonical shas](CLAUDE.md) and [HISTORY.md](HISTORY.md).
- Partition invariance theorem and the cross-path validation grid: [PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md).
- Joint-observable distributional analysis (where King Wen sits in the 3.43B-ordering density): [DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md).
- Methodological critique, including the null-model caveat on the "N boundaries uniquely determine King Wen" finding: [CRITIQUE.md](CRITIQUE.md).
- Formal constraint definitions and theorems: [SPECIFICATION.md](SPECIFICATION.md).

> **For HOW the enumeration actually works** — what a branch / sub-branch / node means, the difference between all-branch and single-branch enumeration, and the open research questions — see [BRANCHES_EXPLAINED.md](BRANCHES_EXPLAINED.md). It's the step-by-step companion to this summary.

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

Five independent rules (C1–C5 in [SPECIFICATION.md](SPECIFICATION.md)), each eliminating more and more possible arrangements. Rules 1 and 2 are known in prior literature (Rule 1 from I Ching scholarship / Cook 2006; Rule 2 from Terence & Dennis McKenna's *The Invisible Landscape*, 1975); Rules 3–5 are formalized and quantified here. See [CITATIONS.md](CITATIONS.md).

(A sixth "XOR rule" was identified during discovery but later proven mathematically redundant — it follows automatically from Rule 1; see [SOLVE.md](SOLVE.md) Theorem 2. It is therefore not listed below.)

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
### Rule 3: Opposites placed below the 776 ceiling — a constraint, not a minimization

Every hexagram has an "opposite" — the one where every solid line becomes broken and vice versa. King Wen's total complement distance (summed across all 64 hexagrams) is exactly 776, which corresponds to a mean of 12.1 positions between each hexagram and its opposite. Compared to random permutations (mean ~22), this is significantly smaller.

**Updated finding (2026-04-20 from 100T d3 canonical analysis)**: The earlier framing — "King Wen actively keeps opposites as close as possible" — was measured relative to *unconstrained* random orderings and relative to C1-only pair-constrained random orderings (where KW sits at the 3.9th percentile). **However, within the filtered set of 3.43 billion valid orderings that satisfy C1+C2+C3 (all three rules), KW is NOT at the minimum of complement distance.** The minimum is 424 (achieved by 221 orderings), and 340 million orderings (~9.91% of the canonical set) tie with KW at exactly 776 — the ceiling of the constraint. KW is in a large equivalence cohort at the maximum-allowed C3, not a distinguished minimum.

So Rule 3 is more accurately stated as **"complement distance is bounded ≤ 776"** than **"complement distance is minimized."** The 776 figure defines the constraint ceiling (it's KW's own value); any ordering at or below 776 passes. The 3.9th-percentile claim remains true in the narrow C1-only comparison but is misleading in the context of C1+C2+C3 valid orderings.

To illustrate the updated picture:
- King Wen's worst complement pair is still ䷂ #3 ↔ ䷱ #50 at distance 47; its best pairs are adjacent (distance 1).
- Among 3.43B valid C1+C2+C3 orderings, 340M of them have the same total complement distance as KW (776). Within that cohort, what distinguishes KW further remains an open question.

**What this does:** Eliminates orderings with complement distance >776, but does not narrow to KW alone. Among 3.43B C1+C2+C3 orderings, KW is one of ~340M at the ceiling.

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

**What this does:** After all previous rules, a backtracking enumeration (`solve.c`, 10 trillion nodes partitioned across parallel threads) finds hundreds of millions of valid orderings — an enormous reduction from 10^89, but far more than the "near-unique" result suggested by earlier [Monte Carlo](https://en.wikipedia.org/wiki/Monte_Carlo_method) sampling. Canonical counts as of 2026-04-18: **706,422,987** at the depth-3 partition, **286,357,503** at depth-2. The count depends on which partition strategy samples the search space; under true exhaustive enumeration both would converge.

### What the rules determine — and what remains open

Canonical enumerations using `solve.c` at the 10T node budget find hundreds of millions of unique orderings satisfying Rules 1-5. At the depth-3 partition (158,364 sub-branches): **706,422,987**. At depth-2 (3,030 sub-branches): **286,357,503**. Both enumerations are partial in the sense that each sub-branch hits its per-sub-branch node budget rather than completing naturally — so the true count under exhaustive enumeration is unknown and likely larger. Only Position 1 (Creative/Receptive) is universally locked — the same pair appears in every valid ordering. The remaining 31 positions show a gradient of constraint:

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
- **Position 2 partially constrains positions 3-19, but not deterministically.** Earlier docs claimed "for 16 of 31 branches, positions 3-19 are fully locked" (based on `--prove-cascade`). That result is correct *only within the shift-pattern subspace* (where every position is restricted to KW's pair or the previous pair) — and the canonical analyses show this subspace is a shrinking minority of valid orderings: **2.69% at d2, 0.062% at d3**. In the full canonical datasets, every reachable first-level branch admits multiple distinct pair sequences at positions 3-19; none are uniquely determined. The cascade region is heavily constrained (per-position entropy 0.3-1.9 bits at d3, well below the 5-bit maximum) but not deterministic.
- **Freedom is concentrated in the back half but spread across the cascade too.** The canonical analyses show position 3 has the highest freedom (d3: 4.52 bits, d2: 4.05 bits, 28-31 distinct pairs observed), positions 22-31 carry 3.40-3.54 bits each at d3 (14 distinct pairs), and the "cascade region" (5-20) carries 0.48-1.85 bits each at d3 — heavily constrained but not zero. The traditional [Xugua](https://en.wikipedia.org/wiki/Ten_Wings) commentary explaining why specific hexagrams follow each other in the back half is describing the designers' choices among genuinely available alternatives, not mathematical necessity.
- **King Wen's complement distance is 776 (mean 12.1)** — small vs random permutations (~22), small vs C1-only orderings (3.9th percentile). But within the full C1+C2+C3 canonical set (3.43B orderings), **KW is at the ceiling, not the minimum** — 340M orderings tie with KW at 776 and 3.43B orderings have smaller or equal C3. Rule 3 is a ceiling constraint, not a minimization. See §Rule 3 for the updated framing.
- **The starting orientation is forced.** ䷀ The Creative must come before ䷁ The Receptive in all valid arrangements.
- **Within-pair orientation has no rule.** Which hexagram comes first within each pair follows no consistent pattern — not yang count, not binary value, not trigram weight. It appears to be a free choice at each pair.

## What this means

Five constraints, discoverable through analysis, narrow 10^89 possible arrangements to hundreds of millions (d3 canonical: 706M; d2 canonical: 286M). Position 1 is fully determined. The cascade region (positions 3-20) is heavily constrained (per-position entropy 0.3-1.9 bits at d3 — far below the 5-bit maximum) but not deterministic: every first-level branch admits multiple distinct pair sequences across positions 3-19. Positions 22-31 have substantially more freedom (entropy 3.4-3.5 bits at d3). The rules were extracted from King Wen (confirmatory analysis, not independent prediction), but the constraint structure they reveal is genuine.

Someone, roughly [3,000 years ago](https://en.wikipedia.org/wiki/King_Wen_of_Zhou), designed an arrangement of 64 symbols that satisfies a set of interlocking mathematical constraints so strict that only hundreds of millions of arrangements in the entire universe of 10^89 possibilities can satisfy them all. Exactly **4 boundary constraints** (specifying which pairs must be adjacent at 4 specific positions) are needed to narrow those millions to exactly 1 — King Wen. **The 4-boundary minimum is proven at both d2 and d3 scales** (exhaustive 3-subset testing confirms no triple suffices at either partition depth).

**A key partition-scope finding** (2026-04-19): the *specific* boundaries that work are **partition-dependent**. What IS stable across d2 and d3: boundaries **{25, 27}** are mandatory in every working 4-set. What is NOT stable: the other 2 boundaries.

- **d2 10T** (286M): 4 working 4-subsets — `{25, 27} ∪ one-of-{2, 3} ∪ one-of-{21, 22}`.
- **d3 10T** (706M): 8 working 4-subsets — `{25, 27}` plus pairs drawn from `{1..6}` (specifically {1,3}, {1,4}, {2,3}, {2,4}, {2,5}, {3,4}, {3,5}, {3,6}).

**Only {25, 27} can be cited as the stable "mandatory boundaries" result.** The broader phrasing about "one-of-{2,3} ∪ one-of-{21,22}" is a d2-specific statement — at deeper partition sampling, different early-zone boundaries become interchangeable. This is exactly the kind of partition-depth sensitivity the null-model caveat (see [CRITIQUE.md](CRITIQUE.md)) anticipates: structural claims that look specific at one partition may look different at another.

### Per-position constraint strength (Shannon entropy)

Across the canonical datasets, the Shannon entropy H(p) of the pair distribution at each position p quantifies how much "choice" exists at that position (in bits; max possible is log₂(32) = 5.0 bits if any pair were equally likely). Values below are from the d3 10T canonical dataset (706M orderings):

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

Per-boundary conditional entropy on d3 (`analyze_d3.log` section [18]) directly quantifies how much fixing a boundary to match KW reduces total sequence uncertainty (baseline: 73.17 bits across 32 positions). The most informative boundaries are the early ones: boundary 4 contributes 46.8 bits of information, boundary 5 contributes 42.7 bits, boundary 6 contributes 39.7 bits. **Boundaries 25 and 27 sit mid-pack at 9.96 and 10.64 bits** — roughly one-fifth the information content of the top boundaries. Yet they are mandatory while the high-information boundaries are interchangeable. What makes `{25, 27}` mandatory is not that they carry more information but that the information they carry is **structurally independent** of all other boundaries: they eliminate non-KW solutions that no combination of other boundaries can reach.

### Boundary redundancy and independence

Joint-survivor analysis (counting how many solutions match KW at *both* of two given boundaries simultaneously) reveals two distinct boundary clusters:

- **Boundaries 15-19 are fully redundant.** For every pair within this set, `joint(b1, b2) = min(survivors(b1), survivors(b2))` — knowing one of these boundaries implies all the others. The cascade region propagates so tightly that constraints near its end carry overlapping information.
- **Boundaries 26 and 27 are highly independent of the cascade region.** Joint/min-single ratios with cascade-region boundaries (3-8) are 0.007-0.010 — essentially uncorrelated. This is what makes them structurally valuable in the minimum-boundary set: they eliminate solutions that the cascade region cannot.

This explains why a minimum 4-set like {2, 21, 25, 27} (d2's greedy pick) or {1, 4, 25, 27} (d3's greedy pick) works: early boundaries catch the high-entropy choices in the front zone, and 25 and 27 contribute *independent* information not implied by any other boundary. The specific early-zone picks vary by partition depth; the mandatory-status of {25, 27} does not.

### 100T d3 canonical results (2026-04-20)

Running the same C1+C2+C3 enumeration at 10× the node budget (100 trillion vs 10 trillion) produced **3,432,399,297 canonical orderings** — roughly 4.86× the 10T count. Findings:

- **Boundary minimum jumps from 4 to 5.** The d2 10T and d3 10T canonicals have 4 specific boundaries uniquely determining KW. At d3 100T, no 4-subset works; minimum is 5, greedy-optimal set **{1, 4, 21, 25, 27}**. Boundaries {25, 27} remain mandatory across all three partitions — this is the most stable structural finding. The specific "4 boundaries" narrative is SUPERSEDED at deeper enumeration; the true boundary-minimum is a function of partition depth.
- **Complement distance (C3) = 776 is the CEILING, not the floor.** KW's C3 is at the maximum of the constraint. 340,179,649 records (9.91%) tie at exactly 776; minimum C3 is 424 (221 records). Axiom "minimize C3" does NOT pick KW; KW is in a large ~10% equivalence cohort at the C3 ceiling. Rule 3 is a ceiling constraint, not a minimization (see updated §Rule 3).
- **Edit-distance distribution heavily right-skewed toward KW's far side.** Mode at edit distance 30 (867M records = 25.3%); only 10.87% of records within edit distance 25 of KW. KW sits in a sparse neighborhood of the solution manifold.
- **Shift-pattern conformance: 0.077%** (2,635,756 of 3.43B). Trajectory: d2 2.69% → d3 10T 0.062% → d3 100T 0.077%. Not monotonically decreasing.
- **Mean per-position Shannon entropy: 2.37 bits** (of 5.0 max). Similar shape to 10T; KW is identifiable within only ~7% of the 32 position slots without additional constraints.

Canonical sha256: `915abf30cc58160fe123c755df2495e7999315afcfc6ef23f0ae22da6b56c3c5` (102.3 GB). See [`solve_c/runs/20260419_100T_d3_d128westus3/`](solve_c/runs/20260419_100T_d3_d128westus3/) for the run archive and `analyze_output.log.gz` for the full data.

### Within-pair orient freedom: a constraint-geometry finding (not KW-specific)

King Wen appears exactly once per canonical dataset (d3: 1 variant, d2: 1 variant — the canonical dedup keeps the lex-smallest orient variant per pair-sequence). Earlier 742M-era analysis found 4 KW orient variants with coupling at positions {2, 3, 28, 29, 30}; the canonical format v1 with per-canonical-class dedup collapses these to 1. The pair-sequence is the invariant; orient variants are cheaply recoverable by testing 2^31 combinations. Running the orient-coupling generalization analysis (`--analyze` section [14]) across the canonical datasets shows:

In the canonical v1 format, each pair-ordering appears exactly once (lex-smallest orient variant kept; other variants cheaply recoverable by testing 2^31 combinations). The d3 10T dataset contains 706,422,987 unique pair-orderings; the d2 10T dataset contains 286,357,503. The 742M-era "4 KW orient variants" finding was an artifact of pre-format-v1 storage that stored all orient variants rather than collapsing them.

The underlying constraint geometry — that within-pair orient is almost entirely forced across positions 5-20 for every valid pair-sequence — is unchanged. What changes is the STORAGE: canonical format v1 doesn't duplicate-store the orient variants that exist, it stores the canonical form + the implicit fact that some pair-orderings have multiple valid orient variants which could be regenerated on demand.

## Observed structural regularity: yield clustering + orientation-symmetry

An analysis of the 100T d3 canonical enumeration log (60,533 non-zero-yield
depth-3 sub-branches, one per valid (pair₁, orient₁, pair₂, orient₂, pair₃,
orient₃) prefix) — reveals strong regularity that is not visible in the merged
canonical records:

- **Only 9,325 distinct yield values across 60,533 sub-branches** (average of 6.5 sub-branches sharing each yield value). The enumeration is not "flat" across prefix classes; it has a strongly-clustered structure.
- **380 depth-3 prefix groups** (where a "group" = all 2³ = 8 orientation variants sharing the same (pair₁, pair₂, pair₃) triple) — every one of the 8 variants yields an **identical** solution count. That is: for these prefixes, orientation does not affect how many C1-C5-valid orderings extend the prefix.
- **16.3% of multi-variant groups overall (1,636 of 10,027)** exhibit this perfect orientation-symmetry. The remaining 83.7% show variant-dependent yields.

This pattern implies a **partial orientation-invariance property** of the C1-C5 constraint system on depth-3 prefixes: for a substantial minority of prefixes, the count of valid continuations depends only on the pair identities, not the hexagram-within-pair orderings.

Reproducibility: the built-in `./solve --yield-report` subcommand reads a solve.c enumeration log on stdin and produces this report. Invoke via `zcat enum_output.log.gz | ./solve --yield-report`. No external dependencies beyond what `solve.c` already requires.

## Observed distributional regularity: KW's position in joint observable space

Separate from the yield-clustering analysis above — at the record level across
the 3,432,399,297 C1-C5 valid orderings in the 100T d3 canonical — a 10-dimensional
observable-statistics vector was computed per ordering and KW's position in the
joint distribution was quantified via kernel density estimation + bootstrap.

**Headline result: KW sits at the 0.000%-ile (bootstrap 95% CI [0.000%, 0.000%])
of the joint observable-density distribution.** KW's joint-feature configuration
is unrepresented in a 100,000-record uniform sample from the canonical — the
KDE assigns KW a log-density ~12,800× lower than any sampled ordering.

The distributional extremity is driven by KW simultaneously being at the 95th+
percentile across four independent structural dimensions (complement distance
at ceiling, both C6/C7 adjacencies satisfied, all 17 shift-pattern positions
conformant, and literally unique-to-KW position-matching). A typical C1-C5
valid ordering does not concentrate extreme values across multiple dimensions
this way.

**A concurrent analytical finding: invariant transition-Hamming distribution.**
The multiset of 63 consecutive-hexagram Hamming distances is identical across
every C1-C5 valid ordering (direct consequence of C5's budget constraint —
it's the constraint itself, re-expressed). So any aggregate statistic of that
multiset (mean, max, variance) is structurally constant — not observable
variation to analyze.

Reproducibility: `solve.py --compute-stats` → per-record parquet, then
`solve.py --marginals`, `solve.py --bivariate`, `solve.py --joint-density`.
Full analysis: [DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md).

## The numbers at a glance

| Step | Rule | Arrangements remaining |
|------|------|----------------------|
| 0 | All possible orderings | 10^89 |
| 1 | Pair structure | 10^45 |
| 2 | No 5-line jumps | ~4% of step 1 |
| 3 | Opposites kept close (3.9th percentile) | ~0.3% of step 1 |
| 4 | Start with Heaven/Earth | ~0.005% of step 1 |
| 5 | Specific transition counts | **706,422,987** (d3 10T canonical); **286,357,503** (d2 10T canonical) |
| 6 | 4 boundary constraints | **1 (King Wen)** |

## An important caveat

Applying the same methodology to random pair-constrained sequences — extract their diff distribution, complement distance, and starting pair, then test for uniqueness — also produces apparent uniqueness in 9 out of 10 cases. **The constraint extraction approach makes almost any sequence appear uniquely determined.** This means Rules 3-7 are not individually remarkable — any sequence's specific properties would similarly narrow the search space.

What IS genuinely special about King Wen is **Rules 1 and 2**: the perfect pair structure and the no-5-line-transition property. Only ~4% of pair-constrained orderings avoid 5-line transitions (ROAE's 10^9-sample pair-constrained null gives 4.29% precisely). The pair structure itself is vanishingly unlikely by chance — a random 64-permutation has probability ~10^-44 of satisfying it. Both observations are **prior knowledge** — Rule 1 is classical (*Yi Zhuan* commentary, Cook 2006) and Rule 2 is from McKenna & McKenna 1975 (*The Invisible Landscape*). ROAE's contribution is **independent computational verification** at scale, plus **null-model testing** across seven structured permutation families showing no family other than KW simultaneously satisfies C1+C2+C3. See [CITATIONS.md](CITATIONS.md) and [CRITIQUE.md](CRITIQUE.md) §Missing analyses.

## What we can and cannot say

The analysis shows the King Wen sequence satisfies a set of interlocking mathematical constraints. It cannot show whether the designers understood those constraints explicitly or arrived at them through centuries of refinement. A simple practice — "pair each hexagram with its mirror, keep opposites nearby, avoid jarring transitions" — applied consistently over generations could produce the same result as deliberate mathematical design. The sequence is the same either way; only the history differs, and the history is outside the reach of computation.

## Impact and scientific implications

ROAE's contribution to the study of the King Wen sequence — distinct from what was previously known — is primarily about **quantifying** how specific and KW-distinctive the combined constraint system is, and about **reproducibility** of that quantification.

**What was already known** ([CITATIONS.md](CITATIONS.md)):

- The pair structure (Rule 1) is ancient, discussed in *Yi Zhuan* commentary (5th–3rd c. BCE), formalized in modern combinatorial terms in **Cook 2006** (*Classical Chinese Combinatorics*).
- The no-5-line-transition property (Rule 2) is documented in **McKenna & McKenna 1975** (*The Invisible Landscape*).
- **Statistical properties of King Wen vs random permutations** are documented in **Chan 2026** (arXiv:2604.09234) — Monte Carlo permutation analysis against 100,000 random baselines, reporting KW's higher-than-random mean Hamming distance (3.35 at 98.2nd percentile), negative lag-1 autocorrelation of Hamming distances (3.7th percentile), within-pair vs between-pair distance asymmetry (99.2nd percentile), yang-balanced groups of four (99.8th percentile), and surprise-distribution variance. Chan's research predates ROAE; where ROAE's findings overlap with Chan's (specifically: the mean-Hamming, lag-1 autocorrelation, and within/between-pair asymmetry observations) Chan's prior art is acknowledged.

**What ROAE adds:**

1. **Exhaustive enumeration at scale.** Under the conjoined C1 + C2 + C3 constraint system, ROAE counts **706,422,987** distinct orderings at a 10 trillion-node partial enumeration (10T d3; sha `f7b8c4fb…`). The count is exact, reproducible byte-identically across hardware and region, and was previously only estimated or approximated.

2. **Seven-family null-model framework.** Measures how other structured permutation families compare to KW's structural properties. Main finding: zero of 1.86 billion permutations across six unconditional families satisfy C1 (consistent with the theoretical rate of ~10⁻⁴⁴ for random permutations). For the de Bruijn and Gray code families, 0% is also proved analytically, not just observed. This is the first systematic null-model test of this scope for the KW structural constraints.

3. **C1 does most of the structural work.** A 10⁹-sample pair-constrained null (C1 guaranteed by construction) shows that given C1, the conditional C2 hit rate jumps from 0.18% (random) to 4.29% (a 23.5× multiplier), and C3 from 0.003% to 6.42% (a 2,264× multiplier). This quantifies what was previously intuitive: the pair structure is doing the heavy lifting; C2 and C3 are relatively modest additional filters.

4. **C3 (complement-distance ceiling of 776) as a specifically quantified constraint.** Believed ROAE-original; if prior work exists, please see [CITATIONS.md](CITATIONS.md).

5. **Mawangdui and Jing Fang 8 Palaces comparison.** New observation (surfaced during null-model testing): the ancient **Mawangdui silk-text ordering (168 BCE) and Jing Fang's 8 Palaces arrangement (c. 77-37 BCE) both satisfy C2** (zero 5-line transitions) despite failing C1 and C3. Of four tested historical orderings (Fu Xi, King Wen, Mawangdui, Jing Fang), only Fu Xi (Leibniz's natural-binary, not a traditional divinatory ordering) has non-zero Hamming-5 transitions. This suggests **C2 was likely a shared classical Chinese design principle** rather than a King-Wen-specific property — reframing McKenna's 1975 observation in a broader context. To this author's knowledge, the specific comparative finding across these four orderings is not previously documented.

6. **Latin-square C2-rate decomposition.** The 8! × 8! Latin-square row × column traversal family has a surprisingly high C2 rate (57.96%). ROAE provides an analytic decomposition that reproduces this rate exactly from first principles: only 7 of 63 transitions in a Latin-square traversal can be 5-line, and the rate is controlled by the row-permutation's Hamming profile (Hamiltonian path in the 3-cube) combined with the column-permutation's first-last XOR. See [CRITIQUE.md §Latin-square C2-rate decomposition](CRITIQUE.md).

7. **Partition Invariance theorem.** A formal guarantee ([PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md)) that the canonical solutions.bin sha256 is byte-identical across any choice of hardware, thread count, region, merge algorithm, or enumeration path — for fixed solver + input parameters. Cross-validated across the "4 corners": {Zen 4 F64 westus2, Zen 5 D128 westus3} × {external merge, in-memory heap-sort}.

**Open questions this work surfaces:** see [CRITIQUE.md §Open questions](CRITIQUE.md). In brief: Costas arrays at order 64 remain untested (infeasible at 64! candidates); Latin-square's 57.96% C2 rate invites parallel analysis of whether KW's own adjacency geometry has an analogous within/between decomposition; whether any published order-64 Costas arrays accidentally satisfy C1+C2+C3 is a concrete follow-up.

For full technical details, methodology, and reproducible commands, see [SOLVE.md](SOLVE.md) and [CITATIONS.md](CITATIONS.md).

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
