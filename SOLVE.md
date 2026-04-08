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

The most likely candidates for further investigation:
- Trigram *sequence* patterns (not just pairwise, but the path of trigrams across multiple boundaries)
- Cosmological or philosophical ordering principles from the [Xugua](https://en.wikipedia.org/wiki/Ten_Wings) commentary
- Optimization of a multi-objective function combining several weak preferences

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
```

## Requirements

Python 3.6+ with no external dependencies. Standalone — does not require `roae.py`.
