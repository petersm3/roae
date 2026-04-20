# Solving the King Wen Sequence

> **Note (2026-04-20):** Canonical reference figures have been re-established with the corrected solver (format v1). Authoritative counts across three partitions:
>
> - **d3 100T: 3,432,399,297 canonical orderings** (sha `915abf30cc58160fe123c755df2495e7999315afcfc6ef23f0ae22da6b56c3c5`, 102.3 GB solutions.bin) — **deepest partial enumeration**, 2026-04-19/20.
> - **d3 10T: 706,422,987 canonical orderings** (sha `f7b8c4fbf2980a169a203b17a6a92c3d175515b00ee74de661d80e949aa6187e`)
> - **d2 10T: 286,357,503 canonical orderings** (sha `a09280fb8caeb63defbcf4f8fd38d023bfff441d42fe2d0132003ee41c2d64e2`)
>
> d2 and d3 10T verified cross-independently across three merge paths (byte-identical output on Phase B external merge, Phase C fresh re-enumeration, in-memory heap-sort). d3 100T run on D128als_v7 westus3 with external-merge via P40 Premium SSD; sha stands on the Partition Invariance theorem. See [HISTORY.md](HISTORY.md) and [PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md).
>
> **Novel 2026-04-20 finding (from d3 100T --c3-min analysis):** King Wen's C3 of 776 is the **maximum** observed among the 3.43B canonical records, not the minimum. Minimum C3 = 424 (221 records). KW sits at the ceiling of the constraint C3 ≤ 776, NOT the floor. The common framing "KW places complements unusually close" is now refined: relative to C1-only orderings, yes (KW is at the 3.9th percentile); relative to the intersection C1+C2+C3 that solve.c enumerates, KW is actually at the C3-maximum, with 99.999999%+ of canonical orderings beating it on complement proximity. **This breaks the derivability axiom "minimize C3"** (negative result for Open Question #7 Phase A Day 1 MVP). The 221 C3=424 records form a "C3-extremal family" structurally distinct from KW.
>
> Older figures (31.6M, 742M) were invalidated by the sub-branch filename collision bug and the hash-table probe-cap bug respectively (both fixed 2026-04). This document has been revised; legacy paragraphs referring to 742M should be read as historical context only, and any "X at dataset-size Y" claim should be verified against the current canonical data via `roae/solve_c/runs/20260418_10T_d3_fresh/analyze_output.log.gz` (d3) and `20260418_10T_d2_fresh/analyze_output.log.gz` (d2).

Can the King Wen sequence be reconstructed from a small set of rules?

For a plain-language version, see [SOLVE-SUMMARY.md](SOLVE-SUMMARY.md).

## The question

The [King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence) is one specific ordering of 64 hexagrams out of 64! (~10^89) possibilities. ROAE's analysis has identified several mathematical constraints the sequence satisfies. This document asks: are those constraints sufficient to *reconstruct* the sequence from scratch? The initial companion prototype (`solve.py`, Python) explored this question interactively; the production enumerator (`solve.c`, multi-threaded C) produces the canonical shas cited above.

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

Backtracking search with the constraint rules finds **King Wen among the solutions**, but also finds millions of other valid sequences. An early 30-second search (7.2M nodes) found 16,248 solutions before budget exhaustion; large-scale enumerations under the current canonical solver find hundreds of millions of unique pair orderings (d3 10T: 706,422,987; d2 10T: 286,357,503). **The five constraints (C1-C5) are NOT sufficient to uniquely determine King Wen.**

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

A 1-billion-node search (63 minutes) found 560,472 raw solutions, which de-duplicate to **13,296 unique pair orderings** (mean 42.2 orientation variants each). Current canonical enumerations at 10T node budget yield hundreds of millions: d3 partition 706M unique, d2 partition 286M unique — the true solution space under exhaustive enumeration is likely larger still.

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

**Note: the fingerprint analysis below was based on a partial sample of 438 solutions from a single branch of the search tree. Current canonical enumerations (d3 10T: 706M, d2 10T: 286M) fundamentally revise these findings — scopes and percentiles in this section are historical.**

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

Rules C1-C5 narrow 10^89 possibilities to a dataset-dependent count under partial enumeration. Canonical reference counts established 2026-04-18:

- **d3 10T partition** (158,364 sub-branches × 63M-node budget each): **706,422,987** canonical pair orderings.
- **d2 10T partition** (3,030 sub-branches × 3.3B-node budget each): **286,357,503** canonical pair orderings.

The difference is a property of partition strategy, not constraints — d3's finer partitioning spreads coverage more broadly at the same total 10T budget. Under true exhaustive enumeration both partitions would converge. XOR regularity and line autocorrelation are redundant (implied by other rules).

**Resolved at 10T scales, REVISED at 100T (2026-04-20):** Exhaustive testing of all 31 singles, 465 pairs, and 4,495 triples confirms no 3-or-fewer-boundary combination suffices at d2, d3 10T, or d3 100T — so the **boundary-minimum is ≥ 4**. However, at d3 100T (3.43B records canonical, sha `915abf30…`), **NO 4-subset works either** (`analyze_output.log.gz` section [8]: total working 4-subsets = 0). The true boundary-minimum is **≥ 5 at 100T**; 4-boundary uniqueness was a d2-and-d3-10T-scale finding that SUPERSEDES at deeper enumeration.

- **d2 10T**: 4 working 4-subsets, structure `{25, 27} ∪ one-of-{2, 3} ∪ one-of-{21, 22}`. Minimum = 4.
- **d3 10T**: 8 working 4-subsets with interchangeable boundaries in `{1..6}` plus mandatory `{25, 27}`. Minimum = 4.
- **d3 100T**: 0 working 4-subsets; exhaustive test confirms no quadruple uniquely identifies KW. Greedy-optimal 5-set: **{1, 4, 21, 25, 27}**. Minimum = 5.

**⚠️ Key scope note (2026-04-20 revision):** boundaries **{25, 27} remain mandatory across all three partitions (d2 10T, d3 10T, d3 100T)** — the partition-stability of {25, 27} is robust. What is NOT partition-stable: (a) the number of boundaries needed (4 at 10T → 5 at 100T), and (b) the specific other boundaries in the minimum set (interchangeable range varies with partition depth). The trajectory suggests the true minimum may continue to grow at 1000T+ enumeration.

The d3 greedy-optimal set (from `analyze_d3.log` section [6]):

1. **Boundary 1** (positions 1-2) — eliminates 706,418,596 of 706,422,986 non-KW (99.999%)
2. **Boundary 27** (positions 27-28) — eliminates 4,352 of remaining 4,390
3. **Boundary 25** (positions 25-26) — eliminates 37 of remaining 38
4. **Boundary 4** (positions 4-5) — eliminates the final 1

For comparison, the d2 greedy-optimal set is {2, 21, 25, 27}. The four boundaries differ — same total (4), same mandatory pair {25, 27}, different interchangeable slots.

### Search-order provenance (why the result isn't greedy-biased)

The 4-boundary minimum structure was discovered and verified in a specific pipeline, in this order, within the `--analyze` code path:

1. **Greedy minimum-boundary search** (`analyze.log` section [6]): picks one boundary at a time, each choice maximizing elimination of non-KW survivors. Terminates when only KW remains. Produces ONE working 4-subset as a fast heuristic.
2. **Exhaustive 3-subset disproof** (`analyze.log` section [7]): tests all C(31,3) = 4,495 triples of boundaries. Confirms no triple suffices (best triple leaves ≥2 survivors at d3, ≥7 at d2). Proves the 4-minimum is tight.
3. **Exhaustive 4-subset enumeration** (`analyze.log` section [8]): tests all C(31,4) = 31,465 quadruples. Lists every working 4-subset that uniquely identifies KW. Produces the complete family (4 sets at d2, 8 at d3).

Step 3 is the critical one: every 4-subset is scored on **equal footing** against the full canonical dataset. The structural claims about `{25, 27}` mandatory status and the partition-dependent interchangeable slots come from step 3, not step 1. **Even if the greedy search had picked a different starting 4-subset, the exhaustive pass would produce the same full family** — the result is not sensitive to greedy bias. Step 1 serves as a quick sanity check and provides a human-readable "chosen representative" 4-subset; step 3 is the rigorous characterization.

### Why 4 boundaries — not fewer?

Exhaustive testing confirms that no combination of 3 or fewer uniquely determines King Wen in either dataset. Four is the empirical minimum at d2 and d3.

Several simpler alternatives were tested and ruled out:

- **No single position-pair constraint is unique to KW.** Every pair that KW places at a given position is also placed there by other valid orderings.
- **No pair of position constraints is unique.** The most selective pair (positions 2 and 26) still allows 25,857 solutions.
- **KW's complement distance (388) is shared by ~197,000 other solutions.** It's at the 100th percentile (maximum among all solutions found) but not unique.
- **No valid ordering differs from KW by exactly 1 position.** The nearest neighbors are all at edit distance 2 — there is a "gap" around King Wen in solution space.
- **The maximum boundaries matched by any non-KW solution is 28 out of 31.** Close, but not enough for uniqueness.

King Wen's uniqueness is irreducibly combinatorial: it requires specifying 4 specific adjacency relationships. No scalar property or simpler structural criterion suffices.

Exhaustive testing of all 31,465 boundary quadruples produces **dataset-dependent working 4-sets**. The count and composition differ between d2 and d3:

**d2 10T dataset** — 4 working 4-sets (`analyze_d2.log` section [8]):

- {2, 21, 25, 27}, {2, 22, 25, 27}, {3, 21, 25, 27}, {3, 22, 25, 27}

Structure: `{25, 27} ∪ one-of-{2, 3} ∪ one-of-{21, 22}` → 2 × 2 = 4 combos.

**d3 10T dataset** — 8 working 4-sets (`analyze_d3.log` section [8]):

- {1, 3, 25, 27}, {1, 4, 25, 27}, {2, 3, 25, 27}, {2, 4, 25, 27}, {2, 5, 25, 27}, {3, 4, 25, 27}, {3, 5, 25, 27}, {3, 6, 25, 27}

Structure: `{25, 27}` plus two-of-`{1..6}` chosen in varied combinations. Boundary frequency: `25`=100%, `27`=100%, `3`=62.5%, `2`=37.5%, `4`=37.5%, others 12.5%-25%.

**What is partition-stable:** boundaries **{25, 27}** appear in every working 4-set at BOTH scales. Their mandatory status is robust across partition depth.

**What is NOT partition-stable:** the remaining 2 boundaries in the 4-set. At d2 they're `{2,3} × {21,22}`; at d3 they're combinations in `{1..6}`. The deeper d3 enumeration exposes more "near-miss" solutions in the early zone (positions 1-6) that require early-boundary distinctions, while d2's coarser partition samples fewer of those.

**Scientific interpretation:** the canonical claim "{25, 27} are mandatory" is a stable finding. The broader phrasing "{25,27} ∪ one-of-{2,3} ∪ one-of-{21,22}" is a d2-specific statement, not a general property of C1-C5 orderings. See CRITIQUE.md for the scope-aware framing and the null-model caveat.

Per-boundary conditional entropy at d3 (`analyze_d3.log` section [18], baseline 73.17 bits): boundary 4 contributes 46.8 bits, boundary 5 contributes 42.7 bits — highest info gain. Boundaries 25 and 27 sit at 9.96 bits and 10.63 bits — mid-pack. Their mandatory status is due to structural independence (no other boundary combination can eliminate what they eliminate), not informational weight.

### What "boundary 25" and "boundary 27" concretely specify

A boundary constraint is a **pair-adjacency constraint**: boundary $N$ specifies that the pair at position $N$ matches KW's pair at position $N$ AND the pair at position $N+1$ matches KW's pair at position $N+1$. It locks a 4-hexagram window (two consecutive pairs).

Concretely, KW's pair content at the mandatory boundaries (1-indexed positions; hexagram names in Wilhelm/Baynes translation):

**Boundary 25 (between pair 25 and pair 26):**
- Pair 25 = ䷰ Ge (Revolution, 革) / ䷱ Ding (The Cauldron, 鼎) — a reverse pair
- Pair 26 = ䷲ Zhen (The Arousing, Thunder, 震) / ䷳ Gen (Keeping Still, Mountain, 艮) — a reverse pair

Enforcing boundary 25 means: any candidate ordering must place Revolution→Cauldron in positions 49-50 AND Thunder→Mountain in positions 51-52 — exactly as King Wen does. This locks a 4-hexagram window in the sequence's second half.

**Boundary 27 (between pair 27 and pair 28):**
- Pair 27 = ䷴ Jian (Gradual Development, 漸) / ䷵ Gui Mei (The Marrying Maiden, 歸妹) — a reverse pair
- Pair 28 = ䷶ Feng (Abundance, 豐) / ䷷ Lu (The Wanderer, 旅) — a reverse pair

Enforcing boundary 27 means: Gradual Development→Marrying Maiden in positions 53-54 AND Abundance→Wanderer in positions 55-56 — exactly as King Wen does. Locks a second 4-hexagram window two positions later.

**Together**, enforcing boundaries {25, 27} locks positions 25, 26, 27, 28 (= pairs 25-28 = the 8-hexagram sub-sequence Revolution / Cauldron / Thunder / Mountain / Gradual / Marrying Maiden / Abundance / Wanderer). Combined with C4 (which forces pair 1 = Creative/Receptive), this fixes 5 of 32 pair positions. The other 27 pairs retain some freedom, producing 43,236 total survivors at d3 10T (13,595 at d2 10T). Adding just 2 more boundary constraints (chosen from the partition-dependent set — at d3, two of {1..6}) narrows from ~40k survivors to exactly 1: King Wen.

The mandatory-{25,27} finding says: **no matter how cleverly you choose the other 2 of your 4 boundary constraints, you cannot uniquely identify King Wen without locking the Revolution→Cauldron→Thunder→Mountain window (boundary 25) and the Gradual→Marrying-Maiden→Abundance→Wanderer window (boundary 27)** — across both d2 and d3 partition depths. Why those two windows specifically? Currently unknown. Open Question: is there a combinatorial or symmetry reason these two second-half adjacencies are irreplaceable?

### What the survivors after the mandatory {25, 27} boundaries look like

Applying only the mandatory boundaries {25, 27} to the current canonical datasets:

- **d3 10T**: 43,236 total survivors (43,235 non-KW). Positions 1, 25, 26, 27, 28 are locked (5 of 32 positions forced by C4 + {25, 27}). Positions 5-22 show a strong "shift cascade" local structure (pos p is almost always pair p−1, p−2, p−3, or p−4). See `roae/solve_c/runs/20260418_10T_d3_fresh/analyze_output.log.gz` section [23].
- **d2 10T**: 13,595 total survivors (13,594 non-KW). Same 5 positions locked. See `roae/solve_c/runs/20260418_10T_d2_fresh/analyze_output.log.gz` section [23].

The ~3.2× ratio between d3 and d2 survivors reflects the dataset size ratio (706M/286M ≈ 2.47×) plus some additional near-miss solutions that d3's deeper partitioning exposes.

### The shift pattern — scope-sensitive

The "shift pattern" (positions 3-19 must be pair p−1 or p−2) was originally stated as universal. It is not. Corrected scope at each scale:

- **d2 10T**: 2.69% of solutions fully shift-conforming (97.31% violate at ≥1 position)
- **d3 10T**: **0.062%** of solutions fully shift-conforming (99.94% violate)
- **d3 100T**: **0.077%** (2,635,756 of 3.43B) — slightly higher than 10T, suggesting some rare shift-conforming orderings only surface at deeper budget. Absolute count went up ~6× vs 10T but remains a tiny fraction overall.

The dramatic reduction from d2 to d3 (~43× rarer) indicates the pattern becomes even more restrictive as the partitioning spreads to more of the solution space. Under exhaustive enumeration it would likely be rarer still. The pattern is a local property satisfied by a small, shrinking fraction of the broader space.

The `--prove-cascade` formal proof remains correct but is scoped to the shift-pattern subspace only — it proves that within solutions obeying the binary shift constraint, position 2 determines positions 3-19. It does not constrain the 97% of solutions that violate the shift pattern.

Per-first-level-branch direct count on the current canonical d2 dataset (`analyze_d2.log` section [11]) shows every branch admits 2-29 distinct configurations at positions 3-19, with no branch having exactly 1. The "position 2 fully determines positions 3-19" claim was an artifact of an earlier bug and does not hold.

### Structure of the best-triple survivors (dataset-scoped)

The best 3-subset minimum survivor count differs between datasets:

- **d3 10T** (`analyze_d3.log` section [7]): best triple `{4, 25, 27}` leaves **2 survivors** (1 KW + 1 non-KW). Adding any 4th boundary completes uniqueness.
- **d2 10T** (`analyze_d2.log` section [7]): best triple `{3, 25, 27}` leaves **7 survivors** (1 KW + 6 non-KW). The 6 non-KW records at d2 are permutations of {20, 21, 22, 23} at positions 21-24:

| Permutation at pos 21-24 | Type |
|:---:|:---|
| `20 22 21 23` (KW: `20 21 22 23`) | swap 21<->22 at pos 22, 23 |
| `20 22 23 21` | 3-cycle of pairs 21, 22, 23 |
| `20 23 22 21` | reverse of pairs 21, 22, 23 |
| `21 20 22 23` | swap 20<->21 at pos 21, 22 |
| `21 22 20 23` | displace pair 20 to pos 23 |
| `21 22 23 20` | displace pair 20 to pos 24 |

The 4! = 24 permutations of {20, 21, 22, 23} at positions 21-24 include KW itself. Of the 23 non-identity permutations, only 6 survive the C1-C5 constraints imposed by the surrounding sequence at d2 scale — the other 17 are eliminated elsewhere in the ordering. Adding the 4th boundary (position 21 or 22) fixes the KW adjacency at that position and kills all 6 survivors.

**At d3 scale** the survivor structure is different: the best-triple `{4, 25, 27}` leaves only 1 non-KW survivor (a permutation with swapped early positions). The shift from "6 survivors clustered around positions 21-24" (d2) to "1 survivor elsewhere" (d3) reflects the partition-dependence of the 4-boundary structure — d3's finer partitioning captures different near-miss solutions.

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

The hundreds of millions of alternative orderings satisfying Rules 1-5 (d3 canonical: 706M, d2 canonical: 286M) share strong structural similarities with King Wen, especially in the early positions. Position 1 is identical in all. The closest alternatives differ by only 2 pair positions.

- **Position 1 is mathematically forced.** Creative/Receptive always comes first.
- **Positions 3-18 are highly constrained** — at least 2 pairs each, with King Wen's pair dominant (87-99% observed). Commentary explaining the ordering of these early hexagrams is largely describing mathematical structure.
- **Positions 19-32 are progressively free** — at least 7-16 pairs each. Commentary explaining these later hexagrams is describing design choices, not mathematical necessity.
- **King Wen minimizes complement distance** among valid orderings, keeping opposites as close as possible (3.9th percentile).

### Summary

Five constraints (C1-C5) narrow 10^89 possibilities to hundreds of millions of unique pair orderings (d3 canonical: 706M; d2 canonical: 286M — partition-dependent subsets of the exhaustive solution space). Only Position 1 is universally locked. Positions 3-18 are highly constrained. Positions 19-32 are progressively free. The minimum boundary set to uniquely determine KW is **4 boundaries**, with **{25, 27} mandatory at both d2 and d3 scales** (the other 2 boundaries are partition-dependent; see "Why 4 boundaries" above).

**Note on earlier analyses in this document:** Several analyses above (centrality, pair swap, optimization, boundary bigrams, locked/free region comparison) were conducted on a 438-solution partial sample from a single search branch. Their findings about the "free region" (positions 24-32) were specific to that branch and may not generalize to the full solution space. These analyses are retained as methodological examples but their specific numerical results should be treated with caution.

## Theoretical results

Five mathematical results proven or established:

### Theorem 1: Within-pair distance is always even

For reverse pairs, bit reversal compares symmetric pairs (0,5), (1,4), (2,3). Each mismatch contributes 2 to the Hamming distance, so d ∈ {0, 2, 4, 6}. For inverse pairs, all bits flip, so d = 6. Neither can be 5. **Proof in Rule 2 section above.**

### Theorem 2: XOR regularity is a theorem, not a constraint

The 7 unique XOR products are **not** a property of King Wen — they are a mathematical consequence of ANY reverse/inverse pairing of 6-bit values. For reverse pairs, h XOR reverse(h) is always symmetric (bit i = bit 5-i), giving 2^3 = 8 possible values. Excluding 000000 (symmetric hexagrams are inverse pairs, not reverse pairs) leaves 7 values. Inverse pairs contribute XOR = 111111, already among the 7. Any pairing of 64 hexagrams produces exactly these 7 XOR values. **QED.**

### ~~Theorem 3: Exactly 2 adjacency constraints are necessary and sufficient~~ (Revised)

**Status: Revised — 4 boundaries needed (proven minimum at both d2 and d3 scales).** The original claim (2 suffice) was based on 438 solutions. On the current canonical datasets: exhaustive testing of all 4,495 triples confirms no combination of 3 or fewer boundaries gives uniqueness at either d2 or d3 (min 3-subset survivors: 7 and 2 respectively). **4 boundary constraints are the current minimum.**

- **d2**: 4 working 4-subsets, structure `{25, 27} ∪ one-of-{2,3} ∪ one-of-{21,22}`.
- **d3**: 8 working 4-subsets, structure `{25, 27}` plus pairs drawn from `{1..6}`.

**Partition-stable finding**: boundaries `{25, 27}` are mandatory in every working 4-subset at both scales. **Not partition-stable**: the other 2 boundaries. The structure could continue to change at deeper partitions or under exhaustive enumeration.

### ~~Result 4: Why exactly 23 positions are locked~~ (Revised)

**Status: Disproven by large-scale enumeration.** The claim that 23 positions are locked was based on a single-branch sample where all solutions shared the same pair at position 2. Across all branches, only Position 1 is universally locked. Positions 3-18 admit at least 2 pairs each. The budget-slack analysis remains valid for explaining why later positions are freer, but the specific "23 locked" boundary does not hold.

### Result 5: Solution count (canonical, 2026-04-18)

Current canonical reference counts under the v1 format with the corrected solver:

- **d3 10T partition**: **706,422,987** unique canonical pair orderings
  - sha256: `f7b8c4fbf2980a169a203b17a6a92c3d175515b00ee74de661d80e949aa6187e`
  - Partition: SOLVE_DEPTH=3 (158,364 sub-branches, 63M-node each)
- **d2 10T partition**: **286,357,503** unique canonical pair orderings
  - sha256: `a09280fb8caeb63defbcf4f8fd38d023bfff441d42fe2d0132003ee41c2d64e2`
  - Partition: SOLVE_DEPTH=2 (3,030 sub-branches, 3.3B-node each)

The difference is a partition-dependent sampling effect at the same 10T total budget, not a constraint difference. Under exhaustive enumeration both partitions would converge to the same count.

- **Upper bound on true exhaustive count**: unknown; likely ≥ 1B
- **Reproducibility**: **partition-invariant** under the formal theorem (see [PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md)): same partition + same solver + same node budget → byte-identical solutions.bin regardless of hardware, region, or number of shard-merge passes. Confirmed empirically across Phase B external merge, Phase C fresh re-enumeration, and today's in-memory heap-sort merge.
- **Invalidated earlier figures**: the 31.6M (filename collision bug) and 742M (hash-probe-cap bug) counts do NOT appear in any current canonical artifact. They are historical only.

### Theorem 6 (empirical): Starting orientation is forced

**Claim.** In every ordering satisfying C1-C5, the sequence begins with ䷀ The Creative (s₀=63) followed by ䷁ The Receptive (s₁=0) — the reversed orientation (s₀=0, s₁=63) yields zero valid orderings.

**Status.** Empirically supported, not yet analytically proven. See LONG_TERM_PLAN.md #13 for the proof agenda (Level 1: tighten prose; Level 2: machine-check in Lean 4 or Rocq).

**Setup and notation.** Pair 0 of the canonical pair table is (63, 0) — Creative/Receptive. C4 fixes this pair at position 1 (the first pair slot in the sequence, indices s₀, s₁). C1 allows both orientations of any pair, so before applying any further constraint there are two candidates for the first pair:

- **Forward orientation**: s₀ = 63, s₁ = 0. Within-pair distance d(63, 0) = 6.
- **Reversed orientation**: s₀ = 0, s₁ = 63. Within-pair distance d(0, 63) = 6.

Both consume one distance-6 slot from the C5 budget {1:2, 2:20, 3:13, 4:19, 6:9}, leaving {1:2, 2:20, 3:13, 4:19, 6:8} for the remaining 62 transitions.

**Structural difference.** The first boundary transition is d(s₁, s₂). Under forward, s₁ = 0, so d(0, s₂) = popcount(s₂). Under reversed, s₁ = 63, so d(63, s₂) = 6 − popcount(s₂). These are complementary: if forward gives boundary distance k, reversed gives 6−k for the same s₂.

This is a weaker constraint than a direct contradiction — one could hope that a different s₂' in the reversed case achieves a valid boundary distance that still permits C5 to close. The theorem's force comes from showing that no such s₂' (and subsequent extension) exists.

**Empirical evidence.** The canonical d3 10T enumeration (706,422,987 orderings, sha `f7b8c4fb…`) contains **zero orderings** with the reversed starting orientation — KW-like and non-KW-like alike. Since the enumeration exhaustively explores the search tree up to a per-sub-branch node budget of 63M, and no reversed-orientation extension surfaced in any of 158,364 sub-branches, either (a) no such ordering exists, or (b) every such ordering requires more than 63M nodes per sub-branch to find.

The 100T d3 enumeration currently running (631M nodes per sub-branch, 10× deeper) will tighten this bound. At full exhaustion (SOLVE_NODE_LIMIT=0), any remaining reversed-orientation ordering must surface.

**What a rigorous analytic proof would require.** Case analysis over all (pair2, orient2) choices at position 2, showing that for each, no extension satisfies C5 — independent of budget. With 31 remaining pairs × 2 orientations = 62 cases at position 2, this is a mechanical but nontrivial induction. A Lean 4 / Rocq formalization would encode C1-C5 as typed predicates and discharge the cases via constraint propagation over finite sets.

Until that lands, the theorem is best stated as: **empirically forced to 706M-ordering depth**. The solver's inlined assumption `seq[0] = 63; seq[1] = 0` is a correctness commitment that will be invalidated if and only if a counter-example ever surfaces at deeper partition.

### Theorem 7: Complement distance bounds

King Wen's complement distance (12.125) is NOT the maximum among Rule 1-6 solutions. Valid orderings range from 11.75 to 14.5. King Wen is at the **3.9th percentile** — it actively minimizes complement distance. The earlier differential analysis finding ("King Wen maximizes complement distance") was an artifact of circular filtering: defining Rule 7a as comp_dist ≤ 12.125 and then observing King Wen was the maximum within that filtered set.

### Theorem 8: Free-region budget is determined

**Note: this theorem was derived under the "23 locked" assumption, which has been disproven. The budget analysis applies within a specific branch (fixed pair at position 2), not universally. The general principle — that later positions have more slack — remains valid.**

Within King Wen's branch, the between-pair boundary budget for positions 24-32 is exactly {1:2, 2:1, 3:5, 4:1} = 9 values for 8 boundaries. The slack of 1 (9 values for 8 slots) is what creates the freedom — one value must go unused, and the choice of which creates the multiple valid orderings.

### Null model: is the constraint framework special?

Applying the same methodology to 10 random pair-constrained sequences (extract diff distribution, complement distance, starting pair, and test for uniqueness), 9/10 also narrow to 0 matching solutions at 50K samples. **The constraint extraction approach inflates apparent specialness — it makes almost any sequence appear uniquely determined.**

The critical difference is at C1+C2: King Wen's no-5-line-transition property eliminates ~96% of pair-constrained orderings, while most random sequences have no comparably rare transition constraint (0-line transitions are the only absent value, and they're absent from ALL pair-constrained orderings by construction). Only 1 of 10 random sequences had a genuinely rare absent transition (both 0 and 1 absent).

**What is genuinely special about King Wen:** the pair structure (C1) and the no-5 property (C2). These are not artifacts of the methodology — they are real structural properties that distinguish King Wen from random orderings. The subsequent constraints (C3-C7) are necessary to pinpoint King Wen uniquely but are not individually remarkable — any sequence's specific complement distance, starting pair, and diff distribution would also narrow to near-uniqueness.

**Structured-permutation nulls (seven families tested; exhaustive where feasible, 10^9-sample otherwise). See [CITATIONS.md](CITATIONS.md) for scope and prior literature.**

| Family | Scope | C1 | C2 (no 5-line) | C3 (≤ 776) |
|---|---|---|---|---|
| de Bruijn B(2, 6) | Exhaustive 2^27 = 134,217,728 | **0** — also analytic | 0 — min observed 1 | 0.1841% |
| 6-bit Gray code orbit | 256 (rot × rev × compl) | **0** — analytic ∀ Gray | 100% (trivial) | 0% — range [1792, 2048] |
| 6-bit Gray codes (random) | 10^5 random Q_6 walks | **0** — analytic ∀ Gray | 100% (trivial) | **0 — min C3 = 832 > KW's 776** |
| Latin-square row × column | Exhaustive 8!×8! = 1,625,702,400 | **0** | **57.96%** (decomposed) | 6.67% — range [512, 2048] |
| Latin-square column × row | Exhaustive 8!×8! (direction-invariance check) | **0** | 57.96% (**identical**) | 6.67% (**identical**) |
| Lexicographic (6! bit-orders) | Exhaustive 720 | 0 | 0 | 0 — always 2048 |
| Historical (Fu Xi, KW, Mawangdui, Jing Fang) | 4 point-tests | KW only | **KW + Mawangdui + Jing Fang** | KW only |
| Random 64-permutations | 10^9 uniform samples | **0 / 10^9** | 0.1828% | 0.002836% |
| **Pair-constrained (C1 given)** | 10^9 samples | 100% (construction) | **4.29%** cond. on C1 | **6.42%** cond. on C1 |

Across **~1.86 billion permutations** from the six unconditional families, **zero satisfy C1** — consistent with the theoretical rate of ~10^-44 for a uniform random permutation. The C1 result is additionally **proven analytically** for de Bruijn B(2, 6) and for all 6-bit Gray codes (see CRITIQUE.md §C1 impossibility).

**C1 does most of the structural work.** The pair-constrained null measures what happens *given* C1: a 10^9-sample Monte Carlo shows C2 | C1 = 4.29% (vs. 0.18% unconditional — a **23.5× multiplier**) and C3 | C1 = 6.42% (vs. 0.003% unconditional — a **2,264× multiplier**). The pair structure alone enormously constrains adjacency and complement geometry toward KW-like; C2 and C3 then act as relatively modest additional filters. This aligns with ROAE's canonical enumeration: solve.c finds 706,422,987 orderings satisfying C1+C2+C3 at d3 10T, rough order-of-magnitude consistent with ~0.28% (≈ 4.29% × 6.42%) of the ~10^14 C1-only orderings.

**What varies across families.** C2 (no 5-line transitions) is **rare in random (0.18%), impossible in de Bruijn, trivially automatic in Gray codes, and majority-satisfied in Latin-square row×col (57.96%)**. More importantly, **3 of 4 tested ancient Chinese hexagram orderings** — King Wen, Mawangdui silk-text, and Jing Fang 8 Palaces — all satisfy C2 exactly, suggesting C2 was likely a shared classical design principle across multiple traditions rather than unique to King Wen. Only Fu Xi (natural binary, a mathematical construction not traditionally divinatory) fails C2. The **conjunction C1 ∧ C2 ∧ C3 is uniquely satisfied by King Wen** across every tested family — Mawangdui and Jing Fang fail both C1 and C3 (they have their own pair structures and complement-distance profiles, but not KW's specific ones).

**Remaining gap**: Costas arrays of order 64. Existence via Welch/Lempel–Golomb constructions is uncertain (those give adjacent orders 62 and 66, not 64), and full 64! enumeration is infeasible (~10^89). Deferred.

**Credit.** C1 (pair structure) is **classical** — see [CITATIONS.md](CITATIONS.md) for Cook (2006) and the I Ching commentarial tradition. C2 (no-5-line transitions) is attributed to **Terence McKenna (1975)** in *The Invisible Landscape*. ROAE's contribution here is the **null-model testing framework** across seven families, the **analytic C1 impossibility proofs** for de Bruijn and Gray code, and the **Latin-square C2-rate decomposition** (see CRITIQUE.md §Latin-square C2-rate decomposition). C3 as a specific quantified threshold (776) is believed ROAE-original; if prior work exists, see CITATIONS.md disclaimer.

## Usage

`solve.py` is the Python exploratory prototype — useful for interactive analysis (fingerprints, differential features, reconstruction heuristics, narrowing trials). `solve.c` is the production enumerator used for the canonical 10T+ runs cited at the top of this doc. Use `solve.py` for exploration; use `solve.c` when you need a reproducible `solutions.bin` sha.

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
python3 solve.py --null-debruijn --trials 20000   # Null-model comparison against de Bruijn permutations (sampled)
```

### Null-model analyses in solve.c (exhaustive)

```
./solve --null-debruijn-exact     # All 2^27 B(2,6) Eulerian circuits — ~80 sec on a 2-core VM
./solve --null-gray               # 6-bit Gray code orbit (256 members) — <1 sec
./solve --null-latin              # Full 8! × 8! = 1.6B Latin-square row×col traversals — ~10 min
./solve --null-latin-col          # Column-first variant (direction-invariance check) — ~6 min
./solve --null-latin-explain      # Analytic decomposition of the 57.96% C2 rate — <1 sec
./solve --null-lex                # 6! = 720 lexicographic bit-order variants — <1 sec
./solve --null-historical         # Fu Xi, King Wen, Mawangdui — <1 sec
./solve --null-random [N]         # N uniform random 64-permutations (default 10^9) — ~10 min
./solve --null-pair-constrained [N]  # Random pair-order + orientation (C1 baked in), conditional C2|C1, C3|C1 — ~10 min
```

### C solver (solve.c) — fast enumeration

For complete enumeration of the solution space, the C implementation is ~60x faster than the Python version. It counts all solutions satisfying Rules 1-5 + C3, de-duplicates by canonical pair ordering, and reports unique ordering counts.

```
gcc -O3 -pthread -fopenmp -o solve solve.c -lm    # Compile
SOLVE_NODE_LIMIT=10000000000000 ./solve 0          # Canonical 10T run (deterministic)
./solve 3600                                        # Exploratory 1-hour run (non-reproducible)
```

**Reproducibility rule.** For canonical runs whose `solutions.bin` sha256 should be re-verifiable by others, set `SOLVE_NODE_LIMIT` and pass `0` for the time_limit — every sub-branch runs to its per-sub-branch node budget, producing byte-identical output regardless of thread count or machine. A wall-clock time_limit (`./solve 3600`) interrupts whatever sub-branches happen to be running at the N-second mark; which ones those are depends on thread scheduling and load, so the result is not reproducible. The solver prints a startup warning if both limits are set simultaneously. See the `REPRODUCIBILITY RULE OF THUMB` block at the top of solve.c for the full explanation.

Use `solve.py` for analysis (fingerprint, differential, reconstruction, etc.) and `solve.c` for enumeration.

## Requirements

**solve.py:** Python 3.6+ with no external dependencies. Standalone — does not require `roae.py`.

**solve.c:** C compiler (gcc, clang) plus libc, libm, pthreads, and OpenMP (`libgomp`, ships with gcc). One runtime dependency: `sha256sum` (GNU coreutils) *or* `shasum -a 256` (BSD/macOS) must be on `PATH` for modes that write `solutions.sha256` — `solve --merge`, `solve --selftest`, and normal/single-branch enumeration. The solver preflights this at startup and fails fast (exit 10) with install hints if neither binary is available, so a missing coreutils can never waste hours of enumeration before being caught. Read-only modes (`--verify`, `--validate`, `--analyze`, `--prove-*`, `--list-branches`) have no runtime dependencies beyond libc and libm. Memory is ~35 MB regardless of run time for the search phase; the merge phase scales with unique-record count (see [DEVELOPMENT.md §Gotchas](DEVELOPMENT.md#known-gotchas) and `SOLVE_MERGE_MODE=external` for memory-independent merging).
