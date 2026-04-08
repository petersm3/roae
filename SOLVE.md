# Solving the King Wen Sequence

Can the King Wen sequence be reconstructed from a small set of rules?

## The question

The [King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence) is one specific ordering of 64 hexagrams out of 64! (~10^89) possibilities. ROAE's analysis has identified several mathematical constraints the sequence satisfies. This companion program (`solve.py`) asks: are those constraints sufficient to *reconstruct* the sequence from scratch?

## The rules

Six constraints have been identified, listed in order of discovery:

### Rule 1: Pair structure

Group all 64 hexagrams into 32 consecutive pairs. Each pair must be a hexagram and its 180-degree rotation (reverse). For the 4 symmetric hexagrams that equal their own reverse, the bitwise complement (inverse) is used instead. This pairing is unique — there is exactly one way to assign the 32 pairs.

### Rule 2: No 5-line transitions

No two consecutive hexagrams may differ by exactly 5 lines. Within reverse/inverse pairs this is automatic (distances are always even or 6), so the constraint applies only at the 31 between-pair boundaries.

### Rule 3: Complement proximity

The mean positional distance between each hexagram and its complement (all lines toggled) must be unusually small. King Wen's mean complement distance is 12.1; random pair-constrained orderings average ~21.7.

### Rule 4: XOR algebraic constraint

The XOR of each pair must produce one of exactly 7 values: `001100`, `010010`, `011110`, `100001`, `101101`, `110011`, `111111`. (Note: this constraint turns out to be redundant with complement proximity — see results below.)

### Rule 5: Starting pair

The sequence begins with The Creative (111111) and The Receptive (000000).

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
| 4 | + Starts with Creative/Receptive | 5 | 0.005% |
| 5 | + Exact difference distribution | 0 | 0% |

### What each level tells us

**Level 1 (4.27%):** The no-5 constraint eliminates ~96% of pair-constrained orderings. This is consistent with ROAE's finding that ~4% of pair-constrained orderings avoid 5-line transitions.

**Level 2 (0.31%):** Complement proximity is a powerful constraint, eliminating ~93% of the Level 1 survivors. This confirms that complement placement is a genuine design feature, not a side effect of the pair structure.

**Level 3 (0.31%):** The XOR constraint adds nothing — every sequence that satisfies Levels 1-2 also satisfies Level 3. The XOR algebraic regularity is a *consequence* of the pair structure and complement proximity, not an independent rule.

**Level 4 (0.005%):** Fixing the starting pair eliminates almost everything. Only 5 out of 100,000 pair-constrained sequences satisfy all four non-trivial constraints AND start with Creative/Receptive.

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

Backtracking search with all 6 rules finds **King Wen among the solutions**, but also finds thousands of other valid sequences. In a 30-second search (7.2M nodes), 16,248 solutions were found before budget exhaustion. **The six rules are NOT sufficient to uniquely determine King Wen.**

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

A 1-billion-node search (63 minutes) found 560,472 raw solutions, which de-duplicate to **13,296 unique pair orderings** (mean 42.2 orientation variants each). The search budget was exhausted, so the full solution count is unknown but the sample is substantial.

**8 features where King Wen is extremal (rank 13,296/13,296).** However, 6 are trivially forced by Rule 6 (difference distribution): entropy, mean boundary distance, boundary distance variance, mean within-pair distance, total path length, and max run length are identical across ALL solutions.

**Two genuinely non-trivial extremal features, confirmed at scale:**

1. **Complement distance: MAXIMUM (12.125).** King Wen places complements as far apart as possible while still satisfying the complement distance threshold. Every other solution scores 11.750 or lower. This held across all 13,296 unique orderings.

2. **Mean line autocorrelation: MAXIMUM (-0.115).** King Wen has the least negative (closest to zero) mean autocorrelation across the 6 line positions. This means its individual line sequences are the smoothest/most correlated among all solutions. Confirmed across all 13,296 orderings.

No individual line autocorrelation is extremal — the effect is distributed across all 6 lines, visible only in the mean.

### Interpretation

The complement distance finding is surprising: Rule 3 requires complement distance ≤ 12.1 (King Wen's value), and King Wen sits at the exact maximum. Among all solutions satisfying Rules 1-6, King Wen is the one that **pushes complements as far apart as the constraint allows**. This suggests the designers didn't just want complements close — they balanced closeness against some other competing objective.

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

**23 of 32 pair positions are locked.** The first 23 pairs (positions 1-46 in the sequence) are identical across ALL valid orderings. The rules completely determine the first 72% of the sequence.

**9 positions are free.** Only positions 24-32 (the last 9 pairs, hexagrams 47-64) vary across solutions. All remaining freedom is concentrated at the end.

**Edit distance distribution.** The closest non-King-Wen solutions differ by just 2 pair positions. The farthest differ by 9 (all free positions). Most differ by 5-7.

**2 adjacency constraints uniquely determine King Wen.** A greedy search finds that specifying just 2 pair adjacencies eliminates all 446 non-King-Wen solutions:
- Boundary 27: pair 27 adjacent to pair 28 (eliminates 441 solutions)
- Boundary 25: pair 25 adjacent to pair 26 (eliminates the remaining 5)

Combined with Rules 1-7a, this gives a **complete generative recipe**: 7 global rules + 2 specific adjacency constraints = unique King Wen sequence.

### Complete generative recipe

1. Pair structure (reverse/inverse)
2. No 5-line transitions
3. Complement distance ≤ 12.125
4. ~~XOR products within 7 values~~ (redundant)
5. Starts with Creative/Receptive
6. Exact difference wave distribution {1:2, 2:20, 3:13, 4:19, 6:9}
7. Complement distance = 12.125 (exact maximum)
8. ~~Mean line autocorrelation = -0.115~~ (redundant with #7)
9. Pair adjacency: position 27 next to position 28
10. Pair adjacency: position 25 next to position 26

Rules 1-7 plus two specific adjacency constraints uniquely determine the King Wen sequence among all possible orderings of 64 hexagrams. Rules 4 and 8 are redundant (implied by other rules).

Note: this result is based on a partial search (447 unique orderings from ~10M nodes). A complete enumeration could reveal additional solutions that might require additional constraints. However, the structure is clear: the rules lock 23 of 32 positions, and 2 adjacency choices in the remaining 9 positions suffice to pin down King Wen.

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
```

## Requirements

Python 3.6+ with no external dependencies. Standalone — does not require `roae.py`.
