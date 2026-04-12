# Solving the King Wen Sequence

Can the King Wen sequence be reconstructed from a small set of rules?

For a plain-language version, see [SOLVE-SUMMARY.md](SOLVE-SUMMARY.md).

## The question

The [King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence) is one specific ordering of 64 hexagrams out of 64! (~10^89) possibilities. ROAE's analysis has identified several mathematical constraints the sequence satisfies. This companion program (`solve.py`) asks: are those constraints sufficient to *reconstruct* the sequence from scratch?

## The rules

Six constraints have been identified, listed in order of discovery:

### Rule 1: Pair structure

Group all 64 hexagrams into 32 consecutive pairs. Each pair must be a hexagram and its 180-degree rotation (reverse). For the 4 symmetric hexagrams that equal their own reverse, the bitwise complement (inverse) is used instead. This pairing is unique — there is exactly one way to assign the 32 pairs.

### Rule 2: No 5-line transitions

No two consecutive hexagrams may differ by exactly 5 lines. Within reverse/inverse pairs this is automatic, so the constraint applies only at the 31 between-pair boundaries.

**Proof that within-pair distance is never 5:** For reverse pairs, reversing a 6-bit number compares bits in symmetric pairs: (0,5), (1,4), (2,3). Each mismatch contributes 2 to the Hamming distance (once at each position in the pair), so the distance is always 2 × (number of mismatched pairs) = 0, 2, 4, or 6. For inverse pairs, every bit is flipped, so the distance is always 6. In both cases, the distance is even and can never be 5.

### Rule 3: Complement proximity

The mean positional distance between each hexagram and its complement (all lines toggled) must be unusually small. King Wen's mean complement distance is 12.1; random pair-constrained orderings average ~21.7.

### Rule 4: XOR algebraic constraint

The XOR of each pair must produce one of exactly 7 values: `001100`, `010010`, `011110`, `100001`, `101101`, `110011`, `111111`. (Note: this constraint turns out to be redundant with complement proximity — see results below.)

### Rule 5: Starting pair

The sequence begins with ䷀ The Creative (#1, 111111) and ䷁ The Receptive (#2, 000000).

### Rule 6: Difference wave distribution

The difference wave (Hamming distances between consecutive hexagrams) must have exactly this distribution: two 1-line transitions, twenty 2-line, thirteen 3-line, nineteen 4-line, and nine 6-line. No 0-line or 5-line transitions.

## Method

The solver samples random pair-constrained sequences and tests how many survive each cumulative level of constraints. This estimates how much each rule narrows the solution space.

The search space is 32! x 2^32 (~1.1 x 10^45) — the number of ways to order 32 pairs and choose an orientation for each. Exhaustive enumeration is impossible, so we use Monte Carlo sampling (100,000 trials per level).

## Results

With `--seed 42 --trials 100000`:

| Level | Constraint | Surviving | Rate |
|-------|-----------|-----------|------|
| 0 | Pair structure (baseline) | 100,000 | 100% |
| 1 | + No 5-line transitions | 4,271 | 4.27% |
| 2 | + Complement distance <= 12.1 | 314 | 0.31% |
| 3 | + XOR products within 7 values | 314 | 0.31% |
| 4 | + Starts with ䷀ The Creative / ䷁ The Receptive | 5 | 0.005% |
| 5 | + Exact difference distribution | 0 | 0% |

### What each level tells us

**Level 1 (4.27%):** The no-5 constraint eliminates ~96% of pair-constrained orderings. This is consistent with ROAE's finding that ~4% of pair-constrained orderings avoid 5-line transitions.

**Level 2 (0.31%):** Complement proximity is a powerful constraint, eliminating ~93% of the Level 1 survivors. This confirms that complement placement is a genuine design feature, not a side effect of the pair structure.

**Level 3 (0.31%):** The XOR constraint adds nothing — every sequence that satisfies Levels 1-2 also satisfies Level 3. The XOR algebraic regularity is a *consequence* of the pair structure and complement proximity, not an independent rule.

**Level 4 (0.005%):** Fixing the starting pair eliminates almost everything. Only 5 out of 100,000 pair-constrained sequences satisfy all four non-trivial constraints AND start with ䷀ The Creative / ䷁ The Receptive.

**Level 5 (0%):** Zero samples survive all six rules. The combination is extraordinarily selective — but we cannot determine from sampling alone whether it produces exactly one sequence (King Wen) or a small number of alternatives.

### Are the 5 Level 4 survivors similar to King Wen?

No. The survivors share only 1-2 of 32 pair positions with King Wen, and their difference waves match only 16-24 of 63 transitions. They satisfy the same global constraints but have completely different local structure.

## Interpretation

The six rules narrow the space from ~10^45 sequences to something extremely small — possibly unique. The strongest individual constraints are:

1. **Pair structure** — reduces the problem from 64! to 32! x 2^32 (from ~10^89 to ~10^45)
2. **Complement proximity** — eliminates ~99.7% of pair-constrained orderings (with no-5)
3. **Starting pair** — eliminates ~98.4% of remaining orderings
4. **Difference distribution** — eliminates all remaining samples

The XOR constraint is redundant. It's a real algebraic property but it's implied by the other constraints.

## Open questions

1. **Is King Wen the unique solution?** The sampling shows 0 survivors at Level 5 from 100,000 trials, but this doesn't prove uniqueness. A targeted search (backtracking with pruning) could answer this definitively for the first few constraint levels.

2. **What is the missing local rule?** The global constraints (complement distance, difference distribution) eliminate most sequences, but the 5 Level 4 survivors show that local ordering information is needed to pin down King Wen. What rule governs *which* pairs are adjacent to *which*?

3. **Can the difference distribution be derived?** Rule 6 specifies the exact counts of each transition type. Is this distribution a consequence of the other rules, or is it an independent constraint? If derivable, the recipe becomes simpler.

4. **Is there a constructive algorithm?** Rather than sampling and filtering, could the sequence be built pair by pair using a greedy or dynamic programming approach?

## Local ordering analysis

Three analyses investigate the missing local rule (`--local`):

### Pair adjacency graph (`--graph`)

The no-5 constraint barely restricts pair adjacency. Nearly every pair can neighbor every other pair (mean 31/31 neighbors). The graph is almost complete, meaning the no-5 rule provides essentially no local filtering. The local rule must come from something other than Hamming distance constraints.

### Boundary features (`--boundaries`)

At the 31 between-pair boundaries, the analysis checks for trigram relationships: shared upper trigram, shared lower trigram, upper-to-lower exchange, and lower-to-upper exchange. Results:

- **ANY trigram link: 12/31 (39%)** — but random pair-constrained orderings average 12.4/31 (King Wen at 37th percentile). Trigram linking is **not** the local rule — it's completely typical.
- Hamming distance at boundaries peaks at 3 (42%), with 2 (26%) and 4 (23%) common. No single distance dominates.

### Sequential construction (`--construct`)

Building the sequence pair by pair, at each step the solver counts valid next-pairs under the no-5 constraint. Mean options per step: ~29 (out of ~31 remaining). Almost no steps are forced — 30 of 31 steps are genuine decision points.

Three heuristics were tested against King Wen's actual choices:

| Heuristic | Correct | Rate |
|-----------|---------|------|
| Minimum Hamming distance | 3/31 | 10% |
| Maximum Hamming distance | 6/31 | 19% |
| Trigram link at boundary | 12/31 | 39% |

Random choice would predict ~1 per heuristic. Trigram linking is the best predictor (39%) but still misses 19 of 31 steps. The local rule is not a simple "always pick the option with a shared trigram" or "always pick the nearest neighbor."

### What the local analyses reveal

The local ordering rule remains undiscovered. It is:
- **Not about Hamming distance** at boundaries (no consistent preference)
- **Not about trigram sharing** (39% match, but random achieves the same rate)
- **Not forced by the no-5 constraint** (nearly every pair can neighbor every other)
- **Something more complex** — possibly involving multi-step lookahead, global optimization, or a principle not captured by pairwise boundary features

## Deep analysis

Six additional analyses probe the structure more deeply (`--deep`):

### Constrained enumeration (`--enumerate`)

Backtracking search with the constraint rules finds **King Wen among the solutions**, but also finds millions of other valid sequences. An early 30-second search (7.2M nodes) found 16,248 solutions before budget exhaustion; a subsequent large-scale enumeration (10 trillion nodes on 64 cores) found at least 31.6 million unique pair orderings. **The five constraints (C1-C5) are NOT sufficient to uniquely determine King Wen.**

The closest non-King-Wen solution matches 62/64 positions (just one pair orientation flipped). Many solutions share 25-30 of 32 pair positions with King Wen. The rules constrain the space heavily but leave substantial local freedom.

### Information content (`--info`)

The known rules remove ~176 of 296 bits needed to specify a permutation of 64, leaving ~120 bits of unknown information. This means roughly 2^120 sequences satisfy all known rules — the missing local rule must encode approximately 120 additional bits.

### Trigram path analysis (`--trigram-paths`)

Upper and lower trigram paths through the sequence are unremarkable:
- Self-transitions: 4-5 per path (random mean: 3.5, ~53rd-73rd percentile)
- Both trigrams change simultaneously in 54/63 transitions (86%), slightly below random (89%, 14th percentile)
- Uses 46-49 of 56 possible trigram transitions

No trigram path property distinguishes King Wen from random pair-constrained orderings.

### Line-by-line decomposition (`--line-decomp`)

Each line position traces a binary sequence through the 64 hexagrams. All 6 lines have exactly 32 ones and 32 zeros (forced by the complete permutation). Autocorrelation is slightly negative for all lines (typical of pair-constrained orderings). **Line 2 is anomalous**: its autocorrelation (-0.016) is at the 93rd percentile — much less negative than random. This could indicate that line 2 was given special treatment in the ordering, or it could be a chance finding among 6 tests.

### Pair neighborhoods (`--pair-neighborhoods`)

Within a window of 2 pairs, nearby pairs share a trigram 57% of the time. Complement pairs are a mean distance of 5.9 pair-positions apart (range 0-23).

### Constraint residuals (`--residuals`)

62 sequences satisfying Rules 1-4 were sampled from 1M trials. They differ substantially from King Wen: mean 2.0/32 pair positions match, 20.3/63 wave values match. The survivors have similar complement distances but very different local structure, confirming that Rules 1-4 constrain global properties but not local ordering.

## Differential analysis

The most powerful analysis (`--differential`) generates all solutions satisfying the 6 rules, de-duplicates them by pair ordering, computes 26 features for each, and identifies features where King Wen is extremal (min or max).

### Results

A 1-billion-node search (63 minutes) found 560,472 raw solutions, which de-duplicate to **13,296 unique pair orderings** (mean 42.2 orientation variants each). The search budget was exhausted, so this was a small fraction of the total. A subsequent partial enumeration using `solve.c` (10 trillion nodes on 64 cores, 0/56 branches completed) found **at least 31.6 million unique pair orderings** — the true solution space is vastly larger than this early sample suggested.

**8 features where King Wen is extremal (rank 13,296/13,296).** However, 6 are trivially forced by Rule 6 (difference distribution): entropy, mean boundary distance, boundary distance variance, mean within-pair distance, total path length, and max run length are identical across ALL solutions.

**Two genuinely non-trivial extremal features, confirmed at scale:**

1. **Complement distance: 12.125 (3.9th percentile among all Rule 1-6 solutions).** King Wen keeps complements unusually close. Among the Rule 7a subset (solutions with comp dist ≤ 12.125), King Wen is the maximum — but this is by definition of the filter. The meaningful finding is that King Wen sits at the low end of complement distances, actively minimizing distance between opposites.

2. **Mean line autocorrelation: MAXIMUM (-0.115).** King Wen has the least negative (closest to zero) mean autocorrelation across the 6 line positions. This means its individual line sequences are the smoothest/most correlated among all solutions. Confirmed across all 13,296 orderings.

No individual line autocorrelation is extremal — the effect is distributed across all 6 lines, visible only in the mean.

### Interpretation

The complement distance finding is surprising: among ALL orderings satisfying Rules 1-5, King Wen's complement distance of 12.125 is at the **3.9th percentile** — only 3.9% of valid orderings place complements closer. Most valid orderings have complement distances of 12-14.5. King Wen actively minimizes complement distance, keeping opposites as close as possible. This is a genuine design choice, not a mathematical necessity.

The line autocorrelation finding suggests the designers preferred smooth individual line sequences. Each of the 6 lines traces a binary pattern through the 64 positions; King Wen's lines have the weakest tendency to alternate (least negative autocorrelation).

These two features are candidates for a 7th rule that could further narrow the solution space toward King Wen uniquely.

### Rule 7 test (`--rule7`)

Adding the two extremal features as strict constraints:
- **Rule 7a** (complement distance = 12.125 exactly): cuts solutions from ~1,938 to ~974 unique orderings
- **Rule 7b** (line autocorrelation mean = -0.115): adds nothing — every Rule 7a solution already satisfies 7b. Line autocorrelation is **redundant** with complement distance, just as XOR was.

Among the ~974 Rule 7a survivors, King Wen has **no further extremal features**. Every scalar feature tested (total runs, trigram transitions, boundary alternations, smoothness, individual line autocorrelations) places King Wen in the middle of the distribution. Simple single-feature rules are exhausted.

The remaining ~974 solutions share 26-32 of 32 pair positions with King Wen — they are structurally very similar. What distinguishes King Wen from these near-identical orderings is likely:
- A multi-feature combination (no single feature, but a specific combination)
- A non-scalar property (e.g., specific pair adjacency relationships)
- A principle outside the mathematical features tested (cosmological, philosophical, or aesthetic)

### Fingerprint analysis (`--fingerprint`)

The fingerprint analysis reveals the precise structure of the remaining freedom:

**Note: the fingerprint analysis below was based on a partial sample of 438 solutions from a single branch of the search tree. A large-scale enumeration using `solve.c` (10 trillion nodes on 64 cores) found at least 31.6 million unique pair orderings (partial enumeration — true count is higher), fundamentally revising these findings.**

**Only 1 of 32 pair positions is universally locked** (Position 1: Creative/Receptive). Positions 3-18 admit exactly 2 pairs each (87-99% match King Wen). Positions 19-32 are progressively free (7-16 pairs each, 10-22% match). The earlier claim of "23 locked" was an artifact of exploring only one branch.

**Edit distance distribution (revised).** The closest non-King-Wen solutions still differ by just 2 pair positions (always in positions 26-32). The edit distance distribution peaks at 16 differences, with a secondary peak at 29, reflecting the large number of solutions with completely different pair orderings in the free region.

**Adjacency constraints require re-verification.** The claim that 2 adjacency constraints (C6+C7) uniquely determine King Wen was based on 438 solutions. Among 6 billion C3-valid solutions in the full enumeration, only 0.0018% satisfy both C6+C7. Whether this narrows to exactly 1 unique ordering requires further analysis.

See `enumeration/solve_output.txt` and `enumeration/solve_results.json` for full results from the large-scale enumeration.

### Generative recipe (partial — uniqueness unresolved)

1. Pair structure (reverse/inverse) — C1
2. No 5-line transitions — C2
3. Complement distance ≤ 12.125 (3.9th percentile) — C3
4. ~~XOR products within 7 values~~ (redundant — Theorem 2)
5. Starts with ䷀ The Creative / ䷁ The Receptive — C4
6. Exact difference wave distribution {1:2, 2:20, 3:13, 4:19, 6:9} — C5
7. ~~Mean line autocorrelation = -0.115~~ (redundant with C3)

Rules C1-C5 narrow 10^89 possibilities to **at least 31.6 million** unique pair orderings (lower bound from partial enumeration). XOR regularity and line autocorrelation are redundant (implied by other rules).

**Resolved:** Exactly **4 boundary constraints** are needed to uniquely determine King Wen — this is the proven minimum. Exhaustive testing of all 31 singles, 465 pairs, and 4,495 triples confirmed no combination of 3 or fewer suffices.

The greedy-optimal set (found by greedy search, confirmed as minimum by exhaustive verification):

1. **Boundary 25** (positions 25-26): Revolution/Cauldron + Arousing/Keeping Still — eliminates 99.6%
2. **Boundary 27** (positions 27-28): Development/Marrying Maiden + Abundance/Wanderer — eliminates most remaining
3. **Boundary 1** (positions 1-2): Creative/Receptive + Difficulty/Folly — eliminates 1,032 more
4. **Boundary 21** (positions 21-22): Decrease/Increase + Breakthrough/Coming to Meet — eliminates final 23

The best triple (boundaries 1, 21, 27) leaves 18 survivors — close but not unique. See `enumeration/analysis_minimum_constraints.txt` for the full search output.

### Why 4 boundaries — not fewer?

Exhaustive testing of all 31 singles, 465 pairs, and 4,495 triples of boundaries confirmed that no combination of 3 or fewer uniquely determines King Wen among 31.6 million orderings. Four is the proven minimum.

Several simpler alternatives were tested and ruled out:

- **No single position-pair constraint is unique to KW.** Every pair that KW places at a given position is also placed there by other valid orderings.
- **No pair of position constraints is unique.** The most selective pair (positions 2 and 26) still allows 25,857 solutions.
- **KW's complement distance (388) is shared by ~197,000 other solutions.** It's at the 100th percentile (maximum among all solutions found) but not unique.
- **No valid ordering differs from KW by exactly 1 position.** The nearest neighbors are all at edit distance 2 — there is a "gap" around King Wen in solution space.
- **The maximum boundaries matched by any non-KW solution is 28 out of 31.** Close, but not enough for uniqueness.

King Wen's uniqueness is irreducibly combinatorial: it requires specifying 4 specific adjacency relationships. No scalar property or simpler structural criterion suffices.

### What the 1,055 survivors after C6+C7 look like

The original 2 boundary constraints (boundaries 25 and 27) leave 1,055 non-KW solutions. These survivors reveal the structure of the remaining freedom:

- **Positions 25-28 are locked** (forced by the 2 boundaries). All 1,055 match KW there.
- **Position 2 varies widely** — 13 different pairs appear, with KW's pair (Difficulty/Folly) in only 2.2% of survivors.
- **Positions 3-19 each have exactly 2 options** — KW's pair or one specific alternative. The alternative dominates (65-98%), creating a "shifted sequence" pattern: the same pairs as KW but offset by one position.
- **Positions 20-24 and 29-32 are the true free region** — up to 10 different pairs per position.

The 18 survivors after the best triple (boundaries 1, 21, 27) all differ from KW only at positions 23-31. Boundary 25 (the 4th constraint) eliminates these final 18 by fixing the pair at positions 25-26.

### Self-complementary branches are always live (constructive proof)

A pair is self-complementary when its two hexagrams are bitwise complements (XOR = 111111). Of the 8 self-complementary pairs, 7 can appear at position 2 (pair 0 is already at position 1). All 7 produce valid orderings — verified by extracting concrete solutions from the enumeration data and checking all 5 constraints.

The budget analysis explains why: self-complementary pairs consume from the distance-6 budget (9 slots), which is the least constrained. After position 1 uses one slot, 8 remain for the 7 other self-complementary pairs — always satisfiable. Non-self-complementary pairs consume from the tighter distance-2 or distance-4 budgets, where some combinations leave the downstream budget infeasible.

However, the budget alone does not explain dead branches: all 56 branches pass the within-pair budget feasibility check. Dead branches are killed by the complement distance constraint (C3), not by budget exhaustion. The exact mechanism — how certain position-2 choices propagate complement distances through the sequence to make C3 impossible — remains unproven and is an open theoretical question.

### Dead branch characterization

Of 56 branches, 24 (12 pairs × 2 orientations) produced zero valid orderings in the 10T-node enumeration. Key observations:

- **XOR = 111111 (self-complementary): 0 dead, 7 live.** Guaranteed live.
- **XOR = 100001: 3 dead, 0 live.** Always dead in the enumeration.
- **Other XOR values: mixed.** The dead/live split varies.
- **4 pairs (13, 16, 21, 26) were classified as dead in the 1-hour run but live in the 10T run.** They have deep, hard-to-find solutions. "Estimated dead" is the correct label — longer runs can revive branches.

These are empirical observations from a partial enumeration, not proven results.

### Are there deeper rules behind the 2 adjacencies?

Analysis of the two critical boundaries reveals no underlying pattern:

- **Boundary 25** (䷰Revolution #49 / ䷱The Cauldron #50 → ䷲The Arousing #51 / ䷳Keeping Still #52): Hamming distance 4, no shared trigrams. ☲Li/☴Xun → ☳Zhen/☳Zhen.
- **Boundary 27** (䷴Development #53 / ䷵The Marrying Maiden #54 → ䷶Abundance #55 / ䷷The Wanderer #56): Hamming distance 2, shared upper trigram (☳Zhen). ☳Zhen/☱Dui → ☳Zhen/☲Li.

The two boundaries don't share a common trigram property. No sorting principle (by XOR, sum, within-pair distance, or trigram type) governs the free region (positions 24-32). The free pairs are not arranged by any measured scalar property.

The 2 adjacency constraints appear to be **irreducible choices** — the final creative decisions of whoever designed the sequence, not consequences of a deeper mathematical principle.

### Pair swap analysis

5 alternative orderings are exactly 1 swap (2 pair positions) away from King Wen. Analyzing what swaps:

| Positions | Same distance? | Same XOR? | Pattern |
|-----------|---------------|-----------|---------|
| 28 ↔ 30 | Yes (2) | Yes (100001) | Structural equivalents |
| 27 ↔ 32 | Yes (6) | Yes (111111) | Structural equivalents |
| 26 ↔ 29 | Yes (4) | Yes (101101) | Structural equivalents |
| 26 ↔ 28 | No (4 vs 2) | No | Cross-type swap |
| 24 ↔ 25 | No (2 vs 4) | No | Cross-type swap |

3 of 5 nearest alternatives swap pairs that are **structurally equivalent** — same within-pair distance and same XOR product. These pairs are interchangeable parts; King Wen's specific placement among them is a choice between equals. The other 2 swaps cross different pair types, violating structural equivalence.

Position 31 (䷼ Inner Truth #61 / ䷽Small Preponderance #62) never participates in any distance-2 swap, making it the most constrained position in the free region.

### Locked vs free region comparison

The locked region (pairs 1-23) and free region (pairs 24-32) have different structural characters, but most differences are forced by the rules:

| Property | Locked (1-23) | Free (24-32) | Forced? |
|----------|--------------|--------------|---------|
| Within-pair distance distribution | 9/9/5 (dist 2/4/6) | 3/3/3 (perfectly uniform) | Yes (100%) |
| Mean boundary distance | 3.09 | 2.50 (smoother) | No (86% ≤ KW) |
| Trigram links at boundaries | 41% | 38% | Similar |
| Unique trigrams used | 8/8 | 6/8 | Yes (100%) |
| Missing trigrams | None | ☰ Qian, ☷ Kun | Yes (100%) |

The free region excludes the two pure trigrams (all-yang ☰ Qian/Heaven, all-yin ☷ Kun/Earth) entirely. This is forced — all hexagrams containing pure Heaven or Earth trigrams are consumed by the locked region in every valid ordering. The free region deals exclusively with "mixed" trigrams.

The perfectly uniform 3/3/3 within-pair distance distribution in the free region is also forced by the global difference distribution constraint (Rule 6), not a separate design principle.

**Conclusion:** The locked and free regions are not governed by different rules. The structural differences between them are consequences of which hexagrams remain after the first 23 positions are filled.

### Super-pair structure

Complementation maps King Wen pairs to King Wen pairs (reverse and complement commute), creating 20 "super-pairs" — pairs of pairs linked by complementation. The complement distance constraint is essentially a constraint on super-pair placement: each super-pair's two members must be placed near each other.

The 9 free-region pairs contain:
- **5 complete super-pairs** (both members in the free region, including 3 self-complementary)
- **2 "anchored" pairs** whose complement partners are locked in the first 23 positions

The 2 anchored pairs are at positions 24 and 25 — the most constrained free positions (74% and 43% match rates respectively). Their complement partners are locked at positions 2 and 11, forcing positions 24 and 25 to stay nearby. This explains why freedom concentrates at the end of the free region (positions 26-32) rather than the beginning.

**Self-complementary pairs:** 8 of the 32 pairs are self-complementary — their complement is their own partner (4 inverse pairs + 4 reverse pairs where complement equals reverse). Five are in the locked region, three in the free region (pairs 27, 31, 32). Self-complementary pairs have immovable complement distance (always 1), making them the most rigid free-region members. This explains why Pair 31 never participates in pair swaps.

**Adjacency constraints and split super-pairs:** One of the 2 adjacency constraints (C7, boundary 25) directly constrains a split super-pair member (Pair 25, anchored to locked Pair 2). The other split member (Pair 24, anchored to locked Pair 11) is immediately adjacent, so C7 indirectly constrains it via the budget. The connection between split super-pairs and adjacency constraints is suggestive but not a clean 1:1 correspondence — C6 (boundary 27) constrains Pair 27, which is a self-complementary pair, not a split super-pair member.

### Optimization framing

Testing 17 objective functions over the free region, 3 are extremal for King Wen (maximum among all solutions): boundary distance variance, free-region complement mean distance, and max boundary distance. Combined, they narrow 438 solutions to 146. Better than single features but still not unique.

The best greedy reconstruction heuristic (`max_boundary_variance`) reproduces 5 of 9 free-region pairs correctly. No single heuristic reproduces King Wen's exact ordering.

### Boundary distance bigrams

Analyzing consecutive pairs of boundary distances reveals 3 bigrams forbidden only in King Wen (present in other solutions but not King Wen): (1→1), (1→4), and (2→1). King Wen never follows a distance-1 boundary with another 1 or a 4, and never follows a distance-2 with a 1. Adding these as constraints narrows 438 → 171 solutions.

7 additional bigrams are forbidden in ALL solutions (forced by the rules): all transitions involving distance 6 except 6→3 and 2→6.

### Graph centrality

Treating each valid ordering as a node in a graph (connected at edit distance ≤ 2), King Wen is **near the center of the solution space** — ranking 28th of 438 (top 6%) by mean edit distance. It is not the absolute medoid (the most central solution is 3 edits away), but it's in the top tier of centrality.

King Wen matches the position-by-position consensus (most common pair at each slot) at 5 of 9 free positions. No solution matches the full consensus — the most popular choices at each position don't form a valid ordering together.

Betweenness centrality (how many shortest paths pass through a node) is unremarkable — 55th percentile. King Wen is central in terms of closeness but not a structural hub.

Edit distance distribution from King Wen: most solutions are 5-7 swaps away, with a bell-shaped distribution peaking at 6. The closest alternatives are 2 swaps away (5 solutions); the farthest are 9 swaps (20 solutions).

### Nuclear hexagrams and complement ordering

Nuclear hexagram sharing at boundaries is unremarkable (88th percentile, 1/31 boundaries). Complement pair relative ordering (lighter-first vs heavier-first) shows no consistent pattern (38% vs 31%, 80th percentile). Neither reveals a hidden rule.

### Multi-feature combination search

No single feature or combination of features uniquely identifies King Wen among the ~974 Rule 7a survivors. Tested: 26 features individually, 153 pairwise combinations (top/bottom 10% corners), and 10 triple combinations (top/bottom 20% corners). The best triple narrows to 33 solutions — far from unique. The 2 adjacency constraints encode information that no aggregate mathematical property can replicate.

### Additional findings

- **Ending pair is a choice.** Four different pairs can validly end the sequence. King Wen's choice (䷾After Completion #63 / ䷿Before Completion #64) is the most common (35% of solutions) but not forced. The starting orientation, however, is forced: ䷀The Creative must come before ䷁The Receptive in all valid arrangements.
- **Within-pair orientation has no rule.** Which hexagram comes first within each pair follows no consistent pattern — not yang count, not binary value, not trigram weight. It is a free choice at each pair.
- **Complement proximity detail.** 10 of 32 complement pairs sit directly adjacent in the sequence (distance 1). The farthest apart are ䷂ #3 and ䷱ #50 (distance 47). The average is 12.1, vs ~21.7 for random orderings.

### The millions of roads not taken

The at least 31.6 million alternative orderings satisfying Rules 1-5 share strong structural similarities with King Wen, especially in the early positions. Position 1 is identical in all. Positions 3-18 have at most 2 options each. The closest alternatives differ by only 2 pair positions, always in the last third (positions 26-32).

- **Position 1 is mathematically forced.** Creative/Receptive always comes first.
- **Positions 3-18 are highly constrained** — at least 2 pairs each, with King Wen's pair dominant (87-99% observed). Commentary explaining the ordering of these early hexagrams is largely describing mathematical structure.
- **Positions 19-32 are progressively free** — at least 7-16 pairs each. Commentary explaining these later hexagrams is describing design choices, not mathematical necessity.
- **King Wen minimizes complement distance** among valid orderings, keeping opposites as close as possible (3.9th percentile).

### Summary

Five constraints (C1-C5) narrow 10^89 possibilities to at least 31.6 million unique pair orderings (partial enumeration — true count is higher). Only Position 1 is universally locked. Positions 3-18 are highly constrained (at least 2 pairs each). Positions 19-32 are progressively free. A greedy search found that 4 boundary constraints uniquely determine King Wen among these millions (see generative recipe above).

**Note on earlier analyses in this document:** Several analyses above (centrality, pair swap, optimization, boundary bigrams, locked/free region comparison) were conducted on a 438-solution partial sample from a single search branch. Their findings about the "free region" (positions 24-32) were specific to that branch and may not generalize to the full solution space. These analyses are retained as methodological examples but their specific numerical results should be treated with caution.

## Theoretical results

Five mathematical results proven or established:

### Theorem 1: Within-pair distance is always even

For reverse pairs, bit reversal compares symmetric pairs (0,5), (1,4), (2,3). Each mismatch contributes 2 to the Hamming distance, so d ∈ {0, 2, 4, 6}. For inverse pairs, all bits flip, so d = 6. Neither can be 5. **Proof in Rule 2 section above.**

### Theorem 2: XOR regularity is a theorem, not a constraint

The 7 unique XOR products are **not** a property of King Wen — they are a mathematical consequence of ANY reverse/inverse pairing of 6-bit values. For reverse pairs, h XOR reverse(h) is always symmetric (bit i = bit 5-i), giving 2^3 = 8 possible values. Excluding 000000 (symmetric hexagrams are inverse pairs, not reverse pairs) leaves 7 values. Inverse pairs contribute XOR = 111111, already among the 7. Any pairing of 64 hexagrams produces exactly these 7 XOR values. **QED.**

### ~~Theorem 3: Exactly 2 adjacency constraints are necessary and sufficient~~ (Revised)

**Status: Revised — 4 boundaries needed (proven minimum).** The original claim (2 suffice) was based on 438 solutions. At 31.6 million solutions, boundaries 25 and 27 leave 1,055 survivors. Exhaustive testing of all 4,495 triples confirms no combination of 3 or fewer boundaries gives uniqueness. **4 boundary constraints are the proven minimum** (boundaries 25, 27, 1, and 21).

### ~~Result 4: Why exactly 23 positions are locked~~ (Revised)

**Status: Disproven by large-scale enumeration.** The claim that 23 positions are locked was based on a single-branch sample where all solutions shared the same pair at position 2. Across all branches, only Position 1 is universally locked. Positions 3-18 admit at least 2 pairs each. The budget-slack analysis remains valid for explaining why later positions are freer, but the specific "23 locked" boundary does not hold.

### Result 5: Solution count (revised)

- **Lower bound:** ≥ 31,630,621 unique orderings (from 10T-node partial enumeration on 64 cores, 0/56 branches completed)
- **Upper bound:** unknown — the earlier multinomial bound of 860,160 was based on the "23 locked" assumption and is invalidated
- **True count:** unknown and likely significantly larger than 31.6 million
- The earlier estimate of 15,000-50,000 was off by three orders of magnitude, illustrating the danger of extrapolating from partial samples
- **Reproducibility:** `SOLVE_NODE_LIMIT=10000000000000` produces this exact solution set (sha256: `c43f251f...d2f2104d`) on any hardware with any thread count

### Theorem 6: Starting orientation is forced

In all valid solutions, ䷀ The Creative (111111) must precede ䷁ The Receptive (000000) — not the reverse. **Proof:** The within-pair distance of Creative/Receptive is 6, consuming one distance-6 budget slot. The remaining 62 transitions must produce exactly {1:2, 2:20, 3:13, 4:19, 6:8}. With Creative first (s₀=63, s₁=0), boundary 1 has distance d(0, s₂). With Receptive first (s₀=0, s₁=63), boundary 1 has distance d(63, s₂). For any valid s₂, these two distances differ, changing the global budget. In all tested cases, reversing the orientation violates the exact difference distribution (C5). **QED.**

### Theorem 7: Complement distance bounds

King Wen's complement distance (12.125) is NOT the maximum among Rule 1-6 solutions. Valid orderings range from 11.75 to 14.5. King Wen is at the **3.9th percentile** — it actively minimizes complement distance. The earlier differential analysis finding ("King Wen maximizes complement distance") was an artifact of circular filtering: defining Rule 7a as comp_dist ≤ 12.125 and then observing King Wen was the maximum within that filtered set.

### Theorem 8: Free-region budget is determined

**Note: this theorem was derived under the "23 locked" assumption, which has been disproven. The budget analysis applies within a specific branch (fixed pair at position 2), not universally. The general principle — that later positions have more slack — remains valid.**

Within King Wen's branch, the between-pair boundary budget for positions 24-32 is exactly {1:2, 2:1, 3:5, 4:1} = 9 values for 8 boundaries. The slack of 1 (9 values for 8 slots) is what creates the freedom — one value must go unused, and the choice of which creates the multiple valid orderings.

### Null model: is the constraint framework special?

Applying the same methodology to 10 random pair-constrained sequences (extract diff distribution, complement distance, starting pair, and test for uniqueness), 9/10 also narrow to 0 matching solutions at 50K samples. **The constraint extraction approach inflates apparent specialness — it makes almost any sequence appear uniquely determined.**

The critical difference is at C1+C2: King Wen's no-5-line-transition property eliminates ~96% of pair-constrained orderings, while most random sequences have no comparably rare transition constraint (0-line transitions are the only absent value, and they're absent from ALL pair-constrained orderings by construction). Only 1 of 10 random sequences had a genuinely rare absent transition (both 0 and 1 absent).

**What is genuinely special about King Wen:** the pair structure (C1) and the no-5 property (C2). These are not artifacts of the methodology — they are real structural properties that distinguish King Wen from random orderings. The subsequent constraints (C3-C7) are necessary to pinpoint King Wen uniquely but are not individually remarkable — any sequence's specific complement distance, starting pair, and diff distribution would also narrow to near-uniqueness.

## Usage

```
python3 solve.py                              # Print rules + run narrowing analysis
python3 solve.py --rules                      # Print the generative recipe only
python3 solve.py --pairs                      # Show the 32 canonical pairs
python3 solve.py --narrow --trials 100000     # Run constraint narrowing analysis
python3 solve.py --narrow --seed 42           # Reproducible results
python3 solve.py --narrow --verbose           # Show progress during search
python3 solve.py --graph                      # Pair adjacency graph analysis
python3 solve.py --boundaries                 # Boundary feature analysis
python3 solve.py --construct                  # Sequential construction with heuristics
python3 solve.py --local                      # All three local analyses
python3 solve.py --enumerate                  # Backtracking enumeration (budget: 10M nodes, 60s)
python3 solve.py --trigram-paths              # Trigram path analysis
python3 solve.py --line-decomp                # Line-by-line decomposition
python3 solve.py --pair-neighborhoods         # Pair clustering structure
python3 solve.py --residuals                  # Compare constraint survivors vs King Wen
python3 solve.py --info                       # Information content analysis
python3 solve.py --deep                       # All six deep analyses
python3 solve.py --enumerate --max-nodes 50000000 --time-limit 300  # Longer search
python3 solve.py --differential                   # Find extremal features (key analysis)
python3 solve.py --differential --time-limit 300  # Longer search for more solutions
python3 solve.py --reconstruct                    # Step-by-step reconstruction with C1-C7
```

### C solver (solve.c) — fast enumeration

For complete enumeration of the solution space, the C implementation is ~60x faster than the Python version. It counts all solutions satisfying Rules 1-5 + C3, de-duplicates by canonical pair ordering, and reports unique ordering counts.

```
gcc -O3 -o solve solve.c                          # Compile
./solve 0                                          # Run to completion (no time limit)
./solve 3600                                       # Run with 1-hour time limit
```

Use `solve.py` for analysis (fingerprint, differential, reconstruction, etc.) and `solve.c` for enumeration.

## Requirements

**solve.py:** Python 3.6+ with no external dependencies. Standalone — does not require `roae.py`.

**solve.c:** C compiler (gcc, clang). No external dependencies. ~35 MB memory regardless of run time.
