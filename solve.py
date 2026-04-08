#!/usr/bin/env python3
# Developed with AI assistance (Claude, Anthropic)
"""
Constraint solver for the King Wen sequence.

Attempts to reconstruct the King Wen sequence from a minimal set of rules.
Standalone — no external dependencies.

See SOLVE.md for methodology and results.
"""
import argparse
import random
import sys
import time

# --- Hexagram data (King Wen order) ---

# Each hexagram as a 6-bit integer: 1=solid (yang), 0=broken (yin).
# Bit 0 = bottom line, bit 5 = top. Source: https://oeis.org/A102241
binary_hexagrams = [
    0b111111, 0b000000, 0b010001, 0b100010, 0b010111, 0b111010, 0b000010, 0b010000,
    0b110111, 0b111011, 0b000111, 0b111000, 0b111101, 0b101111, 0b000100, 0b001000,
    0b011001, 0b100110, 0b000011, 0b110000, 0b101001, 0b100101, 0b100000, 0b000001,
    0b111001, 0b100111, 0b100001, 0b011110, 0b010010, 0b101101, 0b011100, 0b001110,
    0b111100, 0b001111, 0b101000, 0b000101, 0b110101, 0b101011, 0b010100, 0b001010,
    0b100011, 0b110001, 0b011111, 0b111110, 0b011000, 0b000110, 0b011010, 0b010110,
    0b011101, 0b101110, 0b001001, 0b100100, 0b110100, 0b001011, 0b001101, 0b101100,
    0b110110, 0b011011, 0b110010, 0b010011, 0b110011, 0b001100, 0b010101, 0b101010,
]

# English names (Wilhelm/Baynes translation)
hexagram_names = [
    "The Creative", "The Receptive", "Difficulty at the Beginning", "Youthful Folly",
    "Waiting", "Conflict", "The Army", "Holding Together",
    "Small Taming", "Treading", "Peace", "Standstill",
    "Fellowship", "Great Possession", "Modesty", "Enthusiasm",
    "Following", "Work on the Decayed", "Approach", "Contemplation",
    "Biting Through", "Grace", "Splitting Apart", "Return",
    "Innocence", "Great Taming", "Nourishment", "Great Preponderance",
    "The Abysmal", "The Clinging", "Influence", "Duration",
    "Retreat", "Great Power", "Progress", "Darkening of the Light",
    "The Family", "Opposition", "Obstruction", "Deliverance",
    "Decrease", "Increase", "Breakthrough", "Coming to Meet",
    "Gathering Together", "Pushing Upward", "Oppression", "The Well",
    "Revolution", "The Cauldron", "The Arousing", "Keeping Still",
    "Development", "The Marrying Maiden", "Abundance", "The Wanderer",
    "The Gentle", "The Joyous", "Dispersion", "Limitation",
    "Inner Truth", "Small Preponderance", "After Completion", "Before Completion",
]

# --- Utility functions ---

def reverse_6bit(n):
    """Reverse the bit order of a 6-bit value (flip hexagram upside down)."""
    return (
        ((n >> 0) & 1) << 5 | ((n >> 1) & 1) << 4 | ((n >> 2) & 1) << 3 |
        ((n >> 3) & 1) << 2 | ((n >> 4) & 1) << 1 | ((n >> 5) & 1) << 0
    )

def bit_diff(a, b):
    """Count bits that differ between two 6-bit values (Hamming distance)."""
    return bin(a ^ b).count("1")

# The 32 canonical pairs: each hexagram paired with its reverse (or inverse
# for the 4 symmetric hexagrams). This pairing is unique and deterministic.
def build_pairs():
    """Build the 32 canonical reverse/inverse pairs from the 64 hexagrams."""
    used = set()
    pairs = []
    for v in range(64):
        if v in used:
            continue
        rev = reverse_6bit(v)
        inv = v ^ 0b111111
        if rev != v:
            partner = rev
        else:
            partner = inv
        pairs.append((v, partner))
        used.add(v)
        used.add(partner)
    return pairs

# King Wen's pair ordering and orientation (ground truth)
def king_wen_pairs():
    """Extract the 32 pairs as they appear in the King Wen sequence."""
    pairs = []
    for i in range(0, 64, 2):
        pairs.append((binary_hexagrams[i], binary_hexagrams[i + 1]))
    return pairs

# XOR products of King Wen pairs
def king_wen_xor_products():
    """The 7 unique XOR products of King Wen's 32 pairs."""
    products = set()
    for a, b in king_wen_pairs():
        products.add(a ^ b)
    return products

# --- Constraint functions ---

def has_no_five(seq):
    """Check if a sequence has no 5-line transitions."""
    for i in range(len(seq) - 1):
        if bit_diff(seq[i], seq[i + 1]) == 5:
            return False
    return True

def mean_complement_distance(seq):
    """Compute mean positional distance between each hexagram and its complement."""
    pos = {v: i for i, v in enumerate(seq)}
    total = 0
    count = 0
    for v in range(64):
        comp = v ^ 0b111111
        if comp != v:
            total += abs(pos[v] - pos[comp])
            count += 1
    return total / count if count > 0 else 0

def xor_products(pairs):
    """Return the set of XOR products for a list of pairs."""
    return set(a ^ b for a, b in pairs)

def matches_king_wen(seq):
    """Check if a sequence exactly matches King Wen."""
    return seq == binary_hexagrams

# --- Solver ---

def flatten_pairs(pair_order, orientations):
    """Convert a pair ordering + orientations into a flat 64-element sequence."""
    seq = []
    for i, (a, b) in enumerate(pair_order):
        if orientations[i]:
            seq.extend([b, a])
        else:
            seq.extend([a, b])
    return seq

def solve_backtrack(pairs, constraints, max_solutions=1000, verbose=False):
    """Backtracking search over pair orderings and orientations.

    pairs: list of 32 (a, b) tuples
    constraints: dict of constraint name -> function(partial_seq) -> bool
    max_solutions: stop after finding this many
    verbose: print progress

    Returns list of complete sequences satisfying all constraints.
    """
    n = len(pairs)
    solutions = []
    calls = [0]
    start = time.time()

    # Pre-compute: for each pair, both orientations
    pair_options = [[(a, b), (b, a)] for a, b in pairs]

    def backtrack(placed_pairs, remaining_indices, seq):
        calls[0] += 1
        if calls[0] % 1000000 == 0 and verbose:
            elapsed = time.time() - start
            print(f"  {calls[0]:,} nodes explored, {len(solutions)} solutions, "
                  f"{elapsed:.1f}s", file=sys.stderr)

        if len(solutions) >= max_solutions:
            return

        if not remaining_indices:
            solutions.append(list(seq))
            return

        for idx in list(remaining_indices):
            for orient in range(2):
                a, b = pair_options[idx][orient]
                new_seq = seq + [a, b]

                # Check between-pair transition (last of previous pair -> first of new pair)
                if seq:
                    valid = True
                    for name, check_fn in constraints.items():
                        if not check_fn(new_seq):
                            valid = False
                            break
                    if not valid:
                        continue

                new_remaining = remaining_indices - {idx}
                backtrack(placed_pairs + [idx], new_remaining, new_seq)

    backtrack([], set(range(n)), [])

    elapsed = time.time() - start
    if verbose:
        print(f"  Search complete: {calls[0]:,} nodes, {len(solutions)} solutions, "
              f"{elapsed:.1f}s", file=sys.stderr)
    return solutions

def solve_random_sample(pairs, constraints, trials=100000, seed=None, verbose=False):
    """Random sampling: shuffle pairs and orientations, check constraints.

    Much faster than backtracking for estimating solution counts.
    Returns (count_satisfying, total_trials, example_solutions).
    """
    if seed is not None:
        random.seed(seed)

    count = 0
    examples = []
    start = time.time()

    for t in range(trials):
        if verbose and t % 10000 == 0 and t > 0:
            elapsed = time.time() - start
            print(f"  {t:,}/{trials:,} trials, {count} found, {elapsed:.1f}s",
                  file=sys.stderr)

        pair_order = list(pairs)
        random.shuffle(pair_order)
        orientations = [random.randint(0, 1) for _ in range(32)]
        seq = flatten_pairs(pair_order, orientations)

        valid = True
        for name, check_fn in constraints.items():
            if not check_fn(seq):
                valid = False
                break

        if valid:
            count += 1
            if len(examples) < 10:
                examples.append(seq)

    elapsed = time.time() - start
    if verbose:
        print(f"  Sampling complete: {trials:,} trials, {count} found, {elapsed:.1f}s",
              file=sys.stderr)
    return count, trials, examples

# --- Analysis ---

def compare_sequences(seq, reference=None):
    """Compare a sequence against King Wen on key metrics."""
    if reference is None:
        reference = binary_hexagrams

    # How many pairs are in the same position?
    pair_matches = 0
    for i in range(0, 64, 2):
        ref_pair = {reference[i], reference[i + 1]}
        seq_pair = {seq[i], seq[i + 1]}
        if ref_pair == seq_pair:
            pair_matches += 1

    # How many hexagrams are in the exact same position?
    position_matches = sum(1 for i in range(64) if seq[i] == reference[i])

    # Difference wave
    diffs = [bit_diff(seq[i], seq[i + 1]) for i in range(63)]
    ref_diffs = [bit_diff(reference[i], reference[i + 1]) for i in range(63)]
    wave_matches = sum(1 for i in range(63) if diffs[i] == ref_diffs[i])

    # Complement distance
    comp_dist = mean_complement_distance(seq)
    ref_comp_dist = mean_complement_distance(reference)

    return {
        "pair_position_matches": pair_matches,
        "position_matches": position_matches,
        "wave_matches": wave_matches,
        "complement_distance": comp_dist,
        "ref_complement_distance": ref_comp_dist,
        "has_no_five": has_no_five(seq),
        "is_king_wen": seq == reference,
    }

# --- Main ---

def print_constraint_narrowing(pairs, seed=None, trials=100000, verbose=True):
    """Stage 2: measure how each constraint narrows the solution space."""
    print("=" * 70)
    print("CONSTRAINT NARROWING ANALYSIS")
    print("=" * 70)
    print()
    print(f"Total pair-constrained sequences: 32! x 2^32 ~ 1.1 x 10^45")
    print(f"Sampling {trials:,} random pair-constrained sequences per constraint level.")
    print()

    kw_comp_dist = mean_complement_distance(binary_hexagrams)
    kw_xor = king_wen_xor_products()

    # Level 0: pair structure only (baseline — all samples satisfy this by construction)
    print("--- Level 0: Pair structure only (baseline) ---")
    print(f"All {trials:,} samples satisfy pair structure by construction.")
    print()

    # Level 1: + no 5-line transitions
    print("--- Level 1: + No 5-line transitions ---")
    c1 = {"no_five": lambda seq: has_no_five(seq)}
    n1, _, ex1 = solve_random_sample(pairs, c1, trials=trials, seed=seed, verbose=verbose)
    pct1 = n1 / trials * 100
    print(f"Sequences satisfying: {n1:,}/{trials:,} ({pct1:.2f}%)")
    if n1 > 0:
        print(f"Estimated solution space: ~{pct1:.2f}% of 1.1 x 10^45")
    print()

    # Level 2: + complement distance <= King Wen's
    print(f"--- Level 2: + Complement distance <= {kw_comp_dist:.1f} ---")
    c2 = {
        "no_five": lambda seq: has_no_five(seq),
        "comp_dist": lambda seq: mean_complement_distance(seq) <= kw_comp_dist,
    }
    n2, _, ex2 = solve_random_sample(pairs, c2, trials=trials, seed=seed, verbose=verbose)
    pct2 = n2 / trials * 100
    print(f"Sequences satisfying: {n2:,}/{trials:,} ({pct2:.2f}%)")
    print()

    # Level 3: + XOR products subset of King Wen's 7
    print(f"--- Level 3: + XOR products within King Wen's 7 values ---")
    c3 = {
        "no_five": lambda seq: has_no_five(seq),
        "comp_dist": lambda seq: mean_complement_distance(seq) <= kw_comp_dist,
        "xor": lambda seq: xor_products(
            [(seq[i], seq[i + 1]) for i in range(0, 64, 2)]
        ).issubset(kw_xor),
    }
    n3, _, ex3 = solve_random_sample(pairs, c3, trials=trials, seed=seed, verbose=verbose)
    pct3 = n3 / trials * 100
    print(f"Sequences satisfying: {n3:,}/{trials:,} ({pct3:.2f}%)")
    print()

    # Level 4: + starts with Creative/Receptive pair
    print("--- Level 4: + Starts with The Creative / The Receptive ---")
    c4 = {
        "no_five": lambda seq: has_no_five(seq),
        "comp_dist": lambda seq: mean_complement_distance(seq) <= kw_comp_dist,
        "xor": lambda seq: xor_products(
            [(seq[i], seq[i + 1]) for i in range(0, 64, 2)]
        ).issubset(kw_xor),
        "start": lambda seq: seq[0] == 0b111111 and seq[1] == 0b000000,
    }
    n4, _, ex4 = solve_random_sample(pairs, c4, trials=trials, seed=seed, verbose=verbose)
    pct4 = n4 / trials * 100
    print(f"Sequences satisfying: {n4:,}/{trials:,} ({pct4:.2f}%)")
    print()

    # Level 5: + exact difference wave distribution
    kw_diffs = [bit_diff(binary_hexagrams[i], binary_hexagrams[i + 1]) for i in range(63)]
    kw_dist = {}
    for d in kw_diffs:
        kw_dist[d] = kw_dist.get(d, 0) + 1

    print(f"--- Level 5: + Exact difference wave distribution {dict(sorted(kw_dist.items()))} ---")
    def check_diff_dist(seq):
        diffs = [bit_diff(seq[i], seq[i + 1]) for i in range(63)]
        dist = {}
        for d in diffs:
            dist[d] = dist.get(d, 0) + 1
        return dist == kw_dist

    c5 = {
        "no_five": lambda seq: has_no_five(seq),
        "comp_dist": lambda seq: mean_complement_distance(seq) <= kw_comp_dist,
        "xor": lambda seq: xor_products(
            [(seq[i], seq[i + 1]) for i in range(0, 64, 2)]
        ).issubset(kw_xor),
        "start": lambda seq: seq[0] == 0b111111 and seq[1] == 0b000000,
        "diff_dist": check_diff_dist,
    }
    n5, _, ex5 = solve_random_sample(pairs, c5, trials=trials, seed=seed, verbose=verbose)
    pct5 = n5 / trials * 100
    print(f"Sequences satisfying: {n5:,}/{trials:,} ({pct5:.2f}%)")
    print()

    # Summary
    print("=" * 70)
    print("SUMMARY")
    print("=" * 70)
    print()
    print(f"{'Level':<8} {'Constraint':<45} {'Surviving':>12} {'Rate':>8}")
    print(f"{'-----':<8} {'----------':<45} {'---------':>12} {'----':>8}")
    print(f"{'0':<8} {'Pair structure (baseline)':<45} {trials:>12,} {'100%':>8}")
    print(f"{'1':<8} {'+ No 5-line transitions':<45} {n1:>12,} {f'{pct1:.2f}%':>8}")
    print(f"{'2':<8} {'+ Complement distance <= King Wen':<45} {n2:>12,} {f'{pct2:.2f}%':>8}")
    print(f"{'3':<8} {'+ XOR products within 7 values':<45} {n3:>12,} {f'{pct3:.2f}%':>8}")
    print(f"{'4':<8} {'+ Starts with Creative/Receptive':<45} {n4:>12,} {f'{pct4:.2f}%':>8}")
    print(f"{'5':<8} {'+ Exact difference distribution':<45} {n5:>12,} {f'{pct5:.2f}%':>8}")
    print()

    # Check if any surviving solutions are King Wen
    all_examples = ex1 + ex2 + ex3 + ex4 + ex5
    kw_found = any(matches_king_wen(s) for s in all_examples)
    print(f"King Wen found among sampled solutions: {'Yes' if kw_found else 'No'}")
    print()

    # Analyze example solutions at highest constraint level
    best_examples = ex5 if ex5 else (ex4 if ex4 else (ex3 if ex3 else ex2))
    if best_examples:
        print("--- Comparison of surviving solutions vs King Wen ---")
        for i, sol in enumerate(best_examples[:5]):
            stats = compare_sequences(sol)
            print(f"  Solution {i+1}: "
                  f"pair_pos={stats['pair_position_matches']}/32, "
                  f"exact_pos={stats['position_matches']}/64, "
                  f"wave_match={stats['wave_matches']}/63, "
                  f"comp_dist={stats['complement_distance']:.1f} "
                  f"(KW={stats['ref_complement_distance']:.1f}), "
                  f"is_KW={'YES' if stats['is_king_wen'] else 'no'}")
        print()

def print_pair_info(pairs):
    """Print information about the canonical pairs."""
    print("=" * 70)
    print("CANONICAL PAIRS")
    print("=" * 70)
    print()
    print("The 64 hexagrams form 32 unique pairs. Each hexagram is paired with")
    print("its 180-degree rotation (reverse). For the 4 symmetric hexagrams that")
    print("equal their own reverse, the complement (inverse) is used instead.")
    print()

    kw_pairs = king_wen_pairs()
    kw_xor = king_wen_xor_products()

    print(f"{'#':>2} {'Pair':>15} {'Type':<8} {'Hamming':>7} {'XOR':>8} {'KW Pos':>8}")
    print(f"{'--':>2} {'----':>15} {'----':<8} {'-------':>7} {'---':>8} {'------':>8}")

    # Build position lookup
    pos = {v: i + 1 for i, v in enumerate(binary_hexagrams)}

    for i, (a, b) in enumerate(kw_pairs):
        a_bin = bin(a)[2:].zfill(6)
        b_bin = bin(b)[2:].zfill(6)
        is_rev = a == reverse_6bit(b)
        ptype = "reverse" if is_rev else "inverse"
        dist = bit_diff(a, b)
        xor_val = bin(a ^ b)[2:].zfill(6)
        kw_pos = f"{pos[a]}-{pos[b]}"
        print(f"{i+1:>2} {a_bin}+{b_bin} {ptype:<8} {dist:>7} {xor_val:>8} {kw_pos:>8}")

    print(f"\nUnique XOR products: {len(kw_xor)}")
    print(f"XOR values: {', '.join(bin(x)[2:].zfill(6) for x in sorted(kw_xor))}")

def print_rules():
    """Print the discovered rules as a generative recipe."""
    print("=" * 70)
    print("GENERATIVE RECIPE (discovered constraints)")
    print("=" * 70)
    print()
    print("To reconstruct the King Wen sequence, satisfy these rules simultaneously:")
    print()
    print("Rule 1: PAIR STRUCTURE")
    print("  Group all 64 hexagrams into 32 consecutive pairs. Each pair must be")
    print("  a hexagram and its 180-degree rotation (reverse), or for the 4")
    print("  symmetric hexagrams, its bitwise complement (inverse).")
    print()
    print("Rule 2: NO 5-LINE TRANSITIONS")
    print("  No two consecutive hexagrams may differ by exactly 5 lines.")
    print("  (Within pairs this is automatic; the constraint applies at the")
    print("  31 between-pair boundaries.)")
    print()
    print("Rule 3: COMPLEMENT PROXIMITY")
    print(f"  Mean positional distance between complementary hexagrams must be")
    print(f"  <= {mean_complement_distance(binary_hexagrams):.1f} (King Wen's value).")
    print(f"  Random pair-constrained orderings average ~21.7.")
    print()
    print("Rule 4: XOR ALGEBRAIC CONSTRAINT")
    print("  The XOR of each pair must produce one of exactly 7 values:")
    kw_xor = sorted(king_wen_xor_products())
    for x in kw_xor:
        print(f"    {bin(x)[2:].zfill(6)} ({x})")
    print()
    print("Rule 5: STARTING PAIR")
    print("  The sequence begins with The Creative (111111) / The Receptive (000000).")
    print()
    print("Rule 6: DIFFERENCE WAVE DISTRIBUTION")
    kw_diffs = [bit_diff(binary_hexagrams[i], binary_hexagrams[i + 1]) for i in range(63)]
    dist = {}
    for d in kw_diffs:
        dist[d] = dist.get(d, 0) + 1
    print("  The difference wave must have exactly this distribution:")
    for d in sorted(dist):
        print(f"    {d}-line transitions: {dist[d]}")
    print()
    print("OPEN QUESTION: Are these rules sufficient to uniquely determine the")
    print("King Wen sequence, or do additional rules remain undiscovered?")
    print("The --narrow analysis attempts to answer this.")

def upper_trigram(val):
    return (val >> 3) & 0b111

def lower_trigram(val):
    return val & 0b111

TRIGRAM_NAMES = {
    0b000: "Kun",  0b001: "Zhen", 0b010: "Kan",  0b011: "Dui",
    0b100: "Gen",  0b101: "Li",   0b110: "Xun",  0b111: "Qian",
}

def print_adjacency_graph(pairs):
    """Analyze the pair adjacency graph: which pairs can be neighbors?"""
    print("=" * 70)
    print("PAIR ADJACENCY GRAPH")
    print("=" * 70)
    print()
    print("Two pairs can be adjacent if placing them next to each other (in some")
    print("orientation) does not create a 5-line transition at the boundary.")
    print("This graph shows how constrained the ordering problem is.")
    print()

    kw_pairs = king_wen_pairs()
    n = len(kw_pairs)

    # For each pair of pairs, check if any orientation combo avoids 5-line boundary
    adj = [[False] * n for _ in range(n)]
    for i in range(n):
        for j in range(n):
            if i == j:
                continue
            ai, bi = kw_pairs[i]
            aj, bj = kw_pairs[j]
            # 4 possible boundary transitions: bi->aj, bi->bj, ai->aj, ai->bj
            for tail in [ai, bi]:
                for head in [aj, bj]:
                    if bit_diff(tail, head) != 5:
                        adj[i][j] = True

    # Degree distribution
    degrees = [sum(1 for j in range(n) if adj[i][j]) for i in range(n)]
    print(f"Pairs: {n}")
    print(f"Mean neighbors per pair: {sum(degrees)/n:.1f}")
    print(f"Min neighbors: {min(degrees)} (pair {degrees.index(min(degrees))+1})")
    print(f"Max neighbors: {max(degrees)} (pair {degrees.index(max(degrees))+1})")
    print()

    # How constrained is each step in King Wen?
    print("--- King Wen path through the adjacency graph ---")
    print("At each step, how many valid next-pairs exist?")
    print()
    used = {0}  # pair 0 is placed first
    print(f"{'Step':>4} {'Pair':>5} {'Options':>8} {'Forced?':>8}")
    print(f"{'----':>4} {'----':>5} {'-------':>8} {'-------':>8}")
    print(f"{'1':>4} {'1':>5} {'—':>8} {'start':>8}")

    forced_count = 0
    choice_counts = []
    for step in range(1, n):
        prev = step - 1
        options = sum(1 for j in range(n) if j not in used and adj[prev][j])
        forced = "YES" if options <= 2 else ""
        if options <= 2:
            forced_count += 1
        choice_counts.append(options)
        used.add(step)
        print(f"{step+1:>4} {step+1:>5} {options:>8} {forced:>8}")

    print(f"\nForced or near-forced steps (<=2 options): {forced_count}/{n-1}")
    print(f"Mean options per step: {sum(choice_counts)/len(choice_counts):.1f}")
    print(f"Total path freedom (product of options): ~10^{sum(len(str(c)) for c in choice_counts if c > 0):.0f}")
    print()

    # What fraction of the graph does King Wen traverse?
    kw_edges = 0
    total_edges = sum(degrees)
    for step in range(n - 1):
        if adj[step][step + 1]:
            kw_edges += 1
    print(f"King Wen uses {kw_edges}/{n-1} valid adjacencies out of {total_edges} total edges")

def print_boundary_features():
    """Analyze features at each between-pair boundary in King Wen."""
    print("=" * 70)
    print("BOUNDARY FEATURE ANALYSIS")
    print("=" * 70)
    print()
    print("At each of the 31 between-pair boundaries, what properties does the")
    print("transition have? Looking for consistent patterns that could be rules.")
    print()

    kw_pairs = king_wen_pairs()

    # Compute features at each boundary
    features = []
    for i in range(len(kw_pairs) - 1):
        _, tail = kw_pairs[i]      # last hexagram of pair i
        head, _ = kw_pairs[i + 1]  # first hexagram of pair i+1

        dist = bit_diff(tail, head)
        tail_upper = upper_trigram(tail)
        tail_lower = lower_trigram(tail)
        head_upper = upper_trigram(head)
        head_lower = lower_trigram(head)

        shared_upper = tail_upper == head_upper
        shared_lower = tail_lower == head_lower
        upper_to_lower = tail_upper == head_lower  # upper trigram becomes lower
        lower_to_upper = tail_lower == head_upper  # lower trigram becomes upper
        any_shared = shared_upper or shared_lower or upper_to_lower or lower_to_upper

        features.append({
            "boundary": i + 1,
            "tail": tail,
            "head": head,
            "dist": dist,
            "shared_upper": shared_upper,
            "shared_lower": shared_lower,
            "upper_to_lower": upper_to_lower,
            "lower_to_upper": lower_to_upper,
            "any_trigram_link": any_shared,
            "tail_upper": TRIGRAM_NAMES[tail_upper],
            "tail_lower": TRIGRAM_NAMES[tail_lower],
            "head_upper": TRIGRAM_NAMES[head_upper],
            "head_lower": TRIGRAM_NAMES[head_lower],
        })

    # Print boundary table
    print(f"{'#':>2} {'Tail':>8} {'Head':>8} {'Dist':>4} {'ShrU':>5} {'ShrL':>5} "
          f"{'U->L':>5} {'L->U':>5} {'Link?':>5}  Trigram transition")
    print(f"{'--':>2} {'----':>8} {'----':>8} {'----':>4} {'----':>5} {'----':>5} "
          f"{'----':>5} {'----':>5} {'-----':>5}  ---")

    for f in features:
        tail_bin = bin(f['tail'])[2:].zfill(6)
        head_bin = bin(f['head'])[2:].zfill(6)
        link = "*" if f['any_trigram_link'] else ""
        trig_str = (f"{f['tail_upper']}/{f['tail_lower']} -> "
                    f"{f['head_upper']}/{f['head_lower']}")
        print(f"{f['boundary']:>2} {tail_bin:>8} {head_bin:>8} {f['dist']:>4} "
              f"{'Y' if f['shared_upper'] else '.':>5} "
              f"{'Y' if f['shared_lower'] else '.':>5} "
              f"{'Y' if f['upper_to_lower'] else '.':>5} "
              f"{'Y' if f['lower_to_upper'] else '.':>5} "
              f"{link:>5}  {trig_str}")

    # Summary statistics
    total = len(features)
    shared_upper_count = sum(1 for f in features if f['shared_upper'])
    shared_lower_count = sum(1 for f in features if f['shared_lower'])
    u_to_l_count = sum(1 for f in features if f['upper_to_lower'])
    l_to_u_count = sum(1 for f in features if f['lower_to_upper'])
    any_link_count = sum(1 for f in features if f['any_trigram_link'])

    print(f"\n--- Summary of 31 between-pair boundaries ---")
    print(f"Shared upper trigram:        {shared_upper_count}/{total} ({shared_upper_count/total*100:.0f}%)")
    print(f"Shared lower trigram:        {shared_lower_count}/{total} ({shared_lower_count/total*100:.0f}%)")
    print(f"Upper -> Lower exchange:     {u_to_l_count}/{total} ({u_to_l_count/total*100:.0f}%)")
    print(f"Lower -> Upper exchange:     {l_to_u_count}/{total} ({l_to_u_count/total*100:.0f}%)")
    print(f"ANY trigram link:            {any_link_count}/{total} ({any_link_count/total*100:.0f}%)")
    print()

    # Distance distribution at boundaries
    dist_counts = {}
    for f in features:
        dist_counts[f['dist']] = dist_counts.get(f['dist'], 0) + 1
    print("Hamming distance distribution at boundaries:")
    for d in sorted(dist_counts):
        print(f"  Distance {d}: {dist_counts[d]} boundaries ({dist_counts[d]/total*100:.0f}%)")

    # Compare against random: how often do random pair-constrained orderings
    # have this many trigram links?
    print()
    print("--- Trigram link null model ---")
    print("How many trigram links do random pair-constrained orderings have?")

    kw_link_count = any_link_count
    trials = 10000
    random.seed(42)
    link_counts = []
    for _ in range(trials):
        pair_order = list(kw_pairs)
        random.shuffle(pair_order)
        orients = [random.randint(0, 1) for _ in range(32)]
        count = 0
        for j in range(31):
            a1, b1 = pair_order[j]
            if orients[j]:
                a1, b1 = b1, a1
            a2, b2 = pair_order[j + 1]
            if orients[j + 1]:
                a2, b2 = b2, a2
            tail = b1
            head = a2
            tu, tl = upper_trigram(tail), lower_trigram(tail)
            hu, hl = upper_trigram(head), lower_trigram(head)
            if tu == hu or tl == hl or tu == hl or tl == hu:
                count += 1
        link_counts.append(count)

    mean_links = sum(link_counts) / len(link_counts)
    pct = sum(1 for c in link_counts if c >= kw_link_count) / trials * 100
    print(f"King Wen trigram links: {kw_link_count}/31")
    print(f"Random mean: {mean_links:.1f}/31")
    print(f"King Wen percentile: {100-pct:.1f}% (higher = more linked)")

def print_sequential_construction():
    """Analyze sequential construction: at each step, how constrained is the choice?"""
    print("=" * 70)
    print("SEQUENTIAL CONSTRUCTION ANALYSIS")
    print("=" * 70)
    print()
    print("Build the King Wen sequence pair by pair. At each step, count how many")
    print("valid next-pairs exist under the no-5 constraint. Steps with few options")
    print("are forced; steps with many options reveal where the unknown rule applies.")
    print()

    kw_pairs = king_wen_pairs()
    n = len(kw_pairs)

    # At each step, which pairs could come next?
    print(f"{'Step':>4} {'KW pair':>8} {'Valid next':>10} {'KW rank':>8} "
          f"{'Boundary':>8} Transition")
    print(f"{'----':>4} {'-------':>8} {'---------':>10} {'-------':>8} "
          f"{'--------':>8} ----------")

    used = set()
    used.add(0)  # pair index 0 is placed

    total_options = 0
    decision_points = 0

    for step in range(1, n):
        prev_pair = kw_pairs[step - 1]
        curr_pair = kw_pairs[step]
        _, prev_tail = prev_pair  # last hexagram of previous pair

        # Count valid next pairs (any unused pair in any orientation)
        valid = []
        for j in range(n):
            if j in used:
                continue
            cand_a, cand_b = kw_pairs[j]
            # Try both orientations: (a,b) means a is first, boundary is prev_tail->a
            # (b,a) means b is first, boundary is prev_tail->b
            for orient, first in [(0, cand_a), (1, cand_b)]:
                if bit_diff(prev_tail, first) != 5:
                    valid.append((j, orient, first))

        # Where does King Wen's actual choice rank?
        curr_first = curr_pair[0]
        boundary_dist = bit_diff(prev_tail, curr_first)

        # Sort valid options by Hamming distance to see if KW prefers small distances
        valid_sorted = sorted(valid, key=lambda x: bit_diff(prev_tail, x[2]))
        kw_rank = next((i + 1 for i, (j, o, f) in enumerate(valid_sorted)
                        if f == curr_first), "?")

        pair_label = f"{step+1}"
        tu = TRIGRAM_NAMES[upper_trigram(prev_tail)]
        tl = TRIGRAM_NAMES[lower_trigram(prev_tail)]
        hu = TRIGRAM_NAMES[upper_trigram(curr_first)]
        hl = TRIGRAM_NAMES[lower_trigram(curr_first)]
        trans = f"{tu}/{tl} -> {hu}/{hl}"

        n_valid = len(valid)
        total_options += n_valid
        if n_valid > 2:
            decision_points += 1

        print(f"{step+1:>4} {pair_label:>8} {n_valid:>10} {kw_rank:>8} "
              f"{boundary_dist:>8} {trans}")

        used.add(step)

    print(f"\nMean valid options per step: {total_options/(n-1):.1f}")
    print(f"Decision points (>2 options): {decision_points}/{n-1}")
    print()

    # What heuristic best predicts King Wen's choice?
    print("--- Heuristic analysis ---")
    print("At each decision point, which selection strategy matches King Wen?")
    print()

    used = set()
    used.add(0)

    heuristics = {
        "min_distance": 0,    # choose smallest Hamming distance
        "max_distance": 0,    # choose largest Hamming distance
        "trigram_link": 0,    # choose pair that shares a trigram
    }
    testable_steps = 0

    for step in range(1, n):
        prev_pair = kw_pairs[step - 1]
        curr_pair = kw_pairs[step]
        _, prev_tail = prev_pair
        curr_first = curr_pair[0]

        valid = []
        for j in range(n):
            if j in used:
                continue
            cand_a, cand_b = kw_pairs[j]
            for orient, first in [(0, cand_a), (1, cand_b)]:
                if bit_diff(prev_tail, first) != 5:
                    valid.append((j, orient, first))

        if len(valid) <= 1:
            used.add(step)
            continue

        testable_steps += 1
        boundary_dist = bit_diff(prev_tail, curr_first)

        # Min distance heuristic
        min_d = min(bit_diff(prev_tail, f) for _, _, f in valid)
        if boundary_dist == min_d:
            heuristics["min_distance"] += 1

        # Max distance heuristic
        max_d = max(bit_diff(prev_tail, f) for _, _, f in valid)
        if boundary_dist == max_d:
            heuristics["max_distance"] += 1

        # Trigram link heuristic
        tu = upper_trigram(prev_tail)
        tl = lower_trigram(prev_tail)
        hu = upper_trigram(curr_first)
        hl = lower_trigram(curr_first)
        has_link = (tu == hu or tl == hl or tu == hl or tl == hu)
        if has_link:
            heuristics["trigram_link"] += 1

        used.add(step)

    print(f"{'Heuristic':<20} {'Correct':>8} {'of':>3} {testable_steps:>3} {'Rate':>8}")
    print(f"{'----------':<20} {'-------':>8} {'--':>3} {'---':>3} {'----':>8}")
    for name, count in heuristics.items():
        rate = count / testable_steps * 100 if testable_steps > 0 else 0
        print(f"{name:<20} {count:>8} {'of':>3} {testable_steps:>3} {rate:>7.0f}%")

    # What would random choice predict?
    random_expected = testable_steps / (total_options / (n - 1))  # rough
    print(f"\nRandom choice expected: ~{random_expected:.0f}% per heuristic")

def print_enumerate(max_nodes=10_000_000, time_limit=60):
    """Backtracking enumeration with all constraints and a node/time budget."""
    print("=" * 70)
    print("CONSTRAINED ENUMERATION")
    print("=" * 70)
    print()
    print(f"Backtracking search with Rules 1-6. Budget: {max_nodes:,} nodes, {time_limit}s.")
    print("Attempts to count ALL sequences satisfying all known constraints.")
    print()

    kw_pairs = king_wen_pairs()
    n = len(kw_pairs)

    # King Wen's difference distribution (Rule 6)
    kw_diffs = [bit_diff(binary_hexagrams[i], binary_hexagrams[i + 1]) for i in range(63)]
    kw_dist = {}
    for d in kw_diffs:
        kw_dist[d] = kw_dist.get(d, 0) + 1

    # King Wen complement distance (Rule 3)
    kw_comp_dist = mean_complement_distance(binary_hexagrams)

    # Rule 5: first pair must be Creative/Receptive
    first_pair_idx = None
    for i, (a, b) in enumerate(kw_pairs):
        if (a == 0b111111 and b == 0b000000) or (b == 0b111111 and a == 0b000000):
            first_pair_idx = i
            break

    solutions = []
    nodes = [0]
    start = time.time()
    exhausted = [True]

    def backtrack(seq, used, dist_budget):
        nodes[0] += 1
        if nodes[0] > max_nodes or (time.time() - start) > time_limit:
            exhausted[0] = False
            return
        if nodes[0] % 1000000 == 0:
            elapsed = time.time() - start
            print(f"  {nodes[0]:,} nodes, {len(solutions)} solutions, {elapsed:.1f}s",
                  file=sys.stderr)

        step = len(seq) // 2  # how many pairs placed

        if step == n:
            # Check Rule 3: complement distance
            if mean_complement_distance(seq) <= kw_comp_dist:
                solutions.append(list(seq))
            return

        for j in range(n):
            if j in used:
                continue
            a, b = kw_pairs[j]
            for first, second in [(a, b), (b, a)]:
                # Rule 2: no 5-line transition at boundary
                if seq and bit_diff(seq[-1], first) == 5:
                    continue

                # Rule 6: check difference distribution budget
                new_budget = dict(dist_budget)
                feasible = True
                if seq:
                    # Within-pair diff (second of prev pair -> first of this pair already checked)
                    # But also check the boundary diff against budget
                    bd = bit_diff(seq[-1], first)
                    if new_budget.get(bd, 0) <= 0:
                        continue
                    new_budget[bd] -= 1

                # Within-pair diff
                wd = bit_diff(first, second)
                if new_budget.get(wd, 0) <= 0:
                    continue
                new_budget[wd] -= 1

                new_used = used | {j}
                backtrack(seq + [first, second], new_used, new_budget)

                if nodes[0] > max_nodes or (time.time() - start) > time_limit:
                    exhausted[0] = False
                    return

    # Start with Rule 5: Creative/Receptive first
    if first_pair_idx is not None:
        init_budget = dict(kw_dist)
        # Account for the within-pair diff of first pair
        fd = bit_diff(0b111111, 0b000000)
        init_budget[fd] -= 1
        backtrack([0b111111, 0b000000], {first_pair_idx}, init_budget)

    elapsed = time.time() - start
    print(f"\nSearch {'COMPLETE' if exhausted[0] else 'EXHAUSTED BUDGET'}: "
          f"{nodes[0]:,} nodes, {elapsed:.1f}s")
    print(f"Solutions found: {len(solutions)}")

    if solutions:
        kw_found = any(s == binary_hexagrams for s in solutions)
        print(f"King Wen among solutions: {'YES' if kw_found else 'No'}")
        print()
        print("--- Solution comparison ---")
        for i, sol in enumerate(solutions[:10]):
            stats = compare_sequences(sol)
            is_kw = "*** KING WEN ***" if stats['is_king_wen'] else ""
            print(f"  #{i+1}: pair_pos={stats['pair_position_matches']}/32, "
                  f"exact={stats['position_matches']}/64, "
                  f"wave={stats['wave_matches']}/63 {is_kw}")
    elif exhausted[0]:
        print("\nSearch space fully explored. No sequence satisfies all 6 rules")
        print("with complement distance <= King Wen's. The complement distance")
        print("threshold may need adjustment, or King Wen may be unique under")
        print("a slightly relaxed complement constraint.")

def print_trigram_paths():
    """Track upper and lower trigram paths through the sequence."""
    print("=" * 70)
    print("TRIGRAM PATH ANALYSIS")
    print("=" * 70)
    print()
    print("Track the upper and lower trigram independently through the 64-step")
    print("sequence. Each traces a path through the 8 possible trigrams.")
    print()

    upper_path = [upper_trigram(v) for v in binary_hexagrams]
    lower_path = [lower_trigram(v) for v in binary_hexagrams]

    # Transition matrices for each path
    for name, path in [("Upper trigram", upper_path), ("Lower trigram", lower_path)]:
        print(f"--- {name} path ---")
        trans = {}
        for i in range(len(path) - 1):
            key = (path[i], path[i + 1])
            trans[key] = trans.get(key, 0) + 1

        # Self-transitions (staying on same trigram)
        self_trans = sum(v for (a, b), v in trans.items() if a == b)
        print(f"Self-transitions (same trigram consecutive): {self_trans}/63")

        # Unique transitions used
        print(f"Unique transitions used: {len(trans)}/56 possible (8x7)")

        # Most common transitions
        sorted_trans = sorted(trans.items(), key=lambda x: -x[1])
        print("Top 5 transitions:")
        for (a, b), count in sorted_trans[:5]:
            print(f"  {TRIGRAM_NAMES[a]} -> {TRIGRAM_NAMES[b]}: {count}")

        # Visit order: which trigrams appear in what order?
        first_visit = {}
        for i, t in enumerate(path):
            if t not in first_visit:
                first_visit[t] = i + 1
        print(f"First visit order: ", end="")
        visit_order = sorted(first_visit.items(), key=lambda x: x[1])
        print(", ".join(f"{TRIGRAM_NAMES[t]}@{pos}" for t, pos in visit_order))

        # Run lengths: consecutive same-trigram sequences
        runs = []
        current_run = 1
        for i in range(1, len(path)):
            if path[i] == path[i - 1]:
                current_run += 1
            else:
                runs.append(current_run)
                current_run = 1
        runs.append(current_run)
        max_run = max(runs)
        mean_run = sum(runs) / len(runs)
        print(f"Run lengths: mean={mean_run:.1f}, max={max_run}, total runs={len(runs)}")
        print()

    # Cross-path analysis: how do upper and lower relate?
    print("--- Cross-path correlation ---")
    both_change = 0
    only_upper = 0
    only_lower = 0
    neither = 0
    for i in range(63):
        uc = upper_path[i] != upper_path[i + 1]
        lc = lower_path[i] != lower_path[i + 1]
        if uc and lc:
            both_change += 1
        elif uc:
            only_upper += 1
        elif lc:
            only_lower += 1
        else:
            neither += 1
    print(f"Both change:  {both_change}/63 ({both_change/63*100:.0f}%)")
    print(f"Only upper:   {only_upper}/63 ({only_upper/63*100:.0f}%)")
    print(f"Only lower:   {only_lower}/63 ({only_lower/63*100:.0f}%)")
    print(f"Neither:      {neither}/63 ({neither/63*100:.0f}%)")

    # Compare against random
    print()
    print("--- Null model: random pair-constrained orderings ---")
    random.seed(42)
    kw_pairs = king_wen_pairs()
    trials = 10000
    rand_self_upper = []
    rand_self_lower = []
    rand_both_change = []

    for _ in range(trials):
        pair_order = list(kw_pairs)
        random.shuffle(pair_order)
        orients = [random.randint(0, 1) for _ in range(32)]
        seq = flatten_pairs(pair_order, orients)
        up = [upper_trigram(v) for v in seq]
        lo = [lower_trigram(v) for v in seq]
        rand_self_upper.append(sum(1 for i in range(63) if up[i] == up[i+1]))
        rand_self_lower.append(sum(1 for i in range(63) if lo[i] == lo[i+1]))
        rand_both_change.append(sum(1 for i in range(63)
                                    if up[i] != up[i+1] and lo[i] != lo[i+1]))

    kw_self_upper = sum(1 for i in range(63) if upper_path[i] == upper_path[i+1])
    kw_self_lower = sum(1 for i in range(63) if lower_path[i] == lower_path[i+1])

    pct_su = sum(1 for x in rand_self_upper if x >= kw_self_upper) / trials * 100
    pct_sl = sum(1 for x in rand_self_lower if x >= kw_self_lower) / trials * 100
    pct_bc = sum(1 for x in rand_both_change if x >= both_change) / trials * 100

    print(f"Upper self-transitions: KW={kw_self_upper}, random mean={sum(rand_self_upper)/trials:.1f}, "
          f"percentile={100-pct_su:.1f}%")
    print(f"Lower self-transitions: KW={kw_self_lower}, random mean={sum(rand_self_lower)/trials:.1f}, "
          f"percentile={100-pct_sl:.1f}%")
    print(f"Both-change rate: KW={both_change}, random mean={sum(rand_both_change)/trials:.1f}, "
          f"percentile={100-pct_bc:.1f}%")

def print_line_decomposition():
    """Analyze each of the 6 line positions independently."""
    print("=" * 70)
    print("LINE-BY-LINE DECOMPOSITION")
    print("=" * 70)
    print()
    print("Each line position (1-6) traces an independent binary sequence through")
    print("the 64 hexagrams. Analyzing autocorrelation and run structure per line.")
    print()

    for line in range(6):
        bits = [(binary_hexagrams[i] >> line) & 1 for i in range(64)]
        ones = sum(bits)
        zeros = 64 - ones

        # Runs (consecutive same-value)
        runs = 1
        for i in range(1, 64):
            if bits[i] != bits[i - 1]:
                runs += 1

        # Run length distribution
        run_lengths = []
        curr = 1
        for i in range(1, 64):
            if bits[i] == bits[i - 1]:
                curr += 1
            else:
                run_lengths.append(curr)
                curr = 1
        run_lengths.append(curr)
        max_run = max(run_lengths)
        mean_run = sum(run_lengths) / len(run_lengths)

        # Lag-1 autocorrelation
        mean_b = ones / 64
        var_b = sum((b - mean_b) ** 2 for b in bits) / 64
        if var_b > 0:
            autocorr = sum((bits[i] - mean_b) * (bits[i+1] - mean_b)
                          for i in range(63)) / (64 * var_b)
        else:
            autocorr = 0

        print(f"Line {line+1} ({'top' if line == 5 else 'bottom' if line == 0 else 'mid'}): "
              f"1s={ones} 0s={zeros} runs={runs} "
              f"max_run={max_run} mean_run={mean_run:.1f} "
              f"autocorr={autocorr:+.3f}")

        # Visual
        visual = "".join(str(b) for b in bits)
        print(f"         {visual}")
        print()

    # Compare against random pair-constrained orderings
    print("--- Null model: line autocorrelation ---")
    random.seed(42)
    kw_pairs = king_wen_pairs()
    trials = 10000
    rand_autocorrs = [[] for _ in range(6)]

    for _ in range(trials):
        pair_order = list(kw_pairs)
        random.shuffle(pair_order)
        orients = [random.randint(0, 1) for _ in range(32)]
        seq = flatten_pairs(pair_order, orients)
        for line in range(6):
            bits = [(seq[i] >> line) & 1 for i in range(64)]
            mean_b = sum(bits) / 64
            var_b = sum((b - mean_b) ** 2 for b in bits) / 64
            if var_b > 0:
                ac = sum((bits[i] - mean_b) * (bits[i+1] - mean_b)
                        for i in range(63)) / (64 * var_b)
            else:
                ac = 0
            rand_autocorrs[line].append(ac)

    print(f"{'Line':>4} {'KW autocorr':>12} {'Random mean':>12} {'Percentile':>10}")
    print(f"{'----':>4} {'-----------':>12} {'-----------':>12} {'----------':>10}")
    for line in range(6):
        bits = [(binary_hexagrams[i] >> line) & 1 for i in range(64)]
        mean_b = sum(bits) / 64
        var_b = sum((b - mean_b) ** 2 for b in bits) / 64
        if var_b > 0:
            kw_ac = sum((bits[i] - mean_b) * (bits[i+1] - mean_b)
                       for i in range(63)) / (64 * var_b)
        else:
            kw_ac = 0
        rand_mean = sum(rand_autocorrs[line]) / trials
        pct = sum(1 for x in rand_autocorrs[line] if x <= kw_ac) / trials * 100
        print(f"{line+1:>4} {kw_ac:>12.3f} {rand_mean:>12.3f} {pct:>9.1f}%")

def print_pair_neighborhoods():
    """Analyze pair neighborhood structure — which pairs cluster together?"""
    print("=" * 70)
    print("PAIR NEIGHBORHOOD STRUCTURE")
    print("=" * 70)
    print()
    print("Instead of immediate adjacency, look at which pairs are within")
    print("distance 2-3 of each other (nearby in the sequence).")
    print()

    kw_pairs = king_wen_pairs()
    n = len(kw_pairs)

    # Pair types based on Hamming distance
    for radius in [2, 3, 4]:
        print(f"--- Pairs within window of {radius} (positions within {radius*2} hexagrams) ---")

        # For each pair, what other pairs are nearby?
        neighborhood_dists = []  # Hamming distance between nearby pair members
        for i in range(n):
            for j in range(max(0, i - radius), min(n, i + radius + 1)):
                if i == j:
                    continue
                a1, b1 = kw_pairs[i]
                a2, b2 = kw_pairs[j]
                # Min Hamming distance between any members
                min_d = min(bit_diff(x, y) for x in [a1, b1] for y in [a2, b2])
                neighborhood_dists.append(min_d)

        if neighborhood_dists:
            mean_d = sum(neighborhood_dists) / len(neighborhood_dists)
            print(f"Mean min-Hamming between nearby pairs: {mean_d:.2f}")

            # Count how many nearby pairs share a trigram
            trigram_links = 0
            total_nearby = 0
            for i in range(n):
                for j in range(max(0, i - radius), min(n, i + radius + 1)):
                    if i == j:
                        continue
                    total_nearby += 1
                    a1, b1 = kw_pairs[i]
                    a2, b2 = kw_pairs[j]
                    for x in [a1, b1]:
                        for y in [a2, b2]:
                            if (upper_trigram(x) == upper_trigram(y) or
                                lower_trigram(x) == lower_trigram(y)):
                                trigram_links += 1
                                break
                        else:
                            continue
                        break

            print(f"Nearby pairs sharing a trigram: {trigram_links}/{total_nearby} "
                  f"({trigram_links/total_nearby*100:.0f}%)")
        print()

    # Complement pairs: how close are they?
    print("--- Complement pair proximity ---")
    comp_dists = []
    for i in range(n):
        a, b = kw_pairs[i]
        comp_a = a ^ 0b111111
        # Find which pair contains comp_a
        for j in range(n):
            ca, cb = kw_pairs[j]
            if comp_a in (ca, cb):
                comp_dists.append(abs(i - j))
                break
    print(f"Mean pair-distance to complement pair: {sum(comp_dists)/len(comp_dists):.1f}")
    print(f"Max: {max(comp_dists)}, Min: {min(comp_dists)}")

def print_constraint_residuals():
    """Compare Level 4 survivors against King Wen to find the missing rule."""
    print("=" * 70)
    print("CONSTRAINT RESIDUAL ANALYSIS")
    print("=" * 70)
    print()
    print("Generate sequences satisfying Rules 1-4 (pair structure, no-5,")
    print("complement distance, starting pair) and compare against King Wen.")
    print("What distinguishes King Wen from other valid sequences?")
    print()

    kw_pairs = king_wen_pairs()
    kw_comp_dist = mean_complement_distance(binary_hexagrams)

    random.seed(42)
    trials = 1_000_000
    survivors = []

    print(f"Sampling {trials:,} pair-constrained sequences...")
    start = time.time()

    for t in range(trials):
        if t % 200000 == 0 and t > 0:
            print(f"  {t:,} trials, {len(survivors)} found...", file=sys.stderr)

        pair_order = list(kw_pairs)
        random.shuffle(pair_order)
        orients = [random.randint(0, 1) for _ in range(32)]
        seq = flatten_pairs(pair_order, orients)

        # Rule 2: no-5
        if not has_no_five(seq):
            continue
        # Rule 3: complement distance
        if mean_complement_distance(seq) > kw_comp_dist:
            continue
        # Rule 5: starts with Creative/Receptive
        if seq[0] != 0b111111 or seq[1] != 0b000000:
            continue

        survivors.append(seq)

    elapsed = time.time() - start
    print(f"\nFound {len(survivors)} survivors from {trials:,} trials ({elapsed:.1f}s)")
    print()

    if not survivors:
        print("No survivors found. Try increasing trials.")
        return

    # Analyze what distinguishes survivors from King Wen
    print("--- Feature comparison: King Wen vs survivors ---")
    print()

    # Compute features for King Wen
    kw_diffs = [bit_diff(binary_hexagrams[i], binary_hexagrams[i + 1]) for i in range(63)]
    kw_diff_dist = {}
    for d in kw_diffs:
        kw_diff_dist[d] = kw_diff_dist.get(d, 0) + 1

    # Features for each survivor
    features = {
        "diff_dist_match": [],     # how many diff values match KW's distribution
        "wave_correlation": [],     # correlation of difference waves
        "pair_position_match": [],
        "complement_distance": [],
        "max_run_length": [],       # longest run of same diff value
    }

    for sol in survivors:
        stats = compare_sequences(sol)
        features["pair_position_match"].append(stats["pair_position_matches"])
        features["complement_distance"].append(stats["complement_distance"])
        features["wave_correlation"].append(stats["wave_matches"])

        diffs = [bit_diff(sol[i], sol[i + 1]) for i in range(63)]
        dist = {}
        for d in diffs:
            dist[d] = dist.get(d, 0) + 1
        match = sum(min(dist.get(k, 0), kw_diff_dist.get(k, 0)) for k in set(list(dist) + list(kw_diff_dist)))
        features["diff_dist_match"].append(match)

        runs = 1
        max_run = 1
        for i in range(1, len(diffs)):
            if diffs[i] == diffs[i-1]:
                runs += 1
                max_run = max(max_run, runs)
            else:
                runs = 1
        features["max_run_length"].append(max_run)

    # King Wen's values
    kw_max_run = 1
    r = 1
    for i in range(1, len(kw_diffs)):
        if kw_diffs[i] == kw_diffs[i-1]:
            r += 1
            kw_max_run = max(kw_max_run, r)
        else:
            r = 1

    print(f"{'Feature':<25} {'King Wen':>10} {'Surv mean':>10} {'Surv min':>10} {'Surv max':>10}")
    print(f"{'-------':<25} {'--------':>10} {'---------':>10} {'--------':>10} {'--------':>10}")

    def fmt(v):
        return f"{v:.1f}" if isinstance(v, float) else str(v)

    rows = [
        ("Pair positions /32", 32, features["pair_position_match"]),
        ("Wave matches /63", sum(1 for i in range(63) if kw_diffs[i] == kw_diffs[i]), features["wave_correlation"]),
        ("Diff dist overlap /63", 63, features["diff_dist_match"]),
        ("Complement distance", mean_complement_distance(binary_hexagrams), features["complement_distance"]),
        ("Max run length", kw_max_run, features["max_run_length"]),
    ]
    for label, kw_val, vals in rows:
        if vals:
            print(f"{label:<25} {fmt(kw_val):>10} {fmt(sum(vals)/len(vals)):>10} "
                  f"{fmt(min(vals)):>10} {fmt(max(vals)):>10}")

    print(f"\nTotal survivors analyzed: {len(survivors)}")
    kw_found = any(s == binary_hexagrams for s in survivors)
    print(f"King Wen among survivors: {'YES' if kw_found else 'No'}")

def print_info_content():
    """Estimate the information content needed beyond known constraints."""
    print("=" * 70)
    print("INFORMATION CONTENT ANALYSIS")
    print("=" * 70)
    print()
    print("How many bits of additional information are needed beyond the known")
    print("constraints to specify King Wen uniquely?")
    print()

    import math

    # Total information to specify a permutation of 64 objects
    total_bits = math.log2(math.factorial(64))
    print(f"Total information in a permutation of 64: {total_bits:.1f} bits")
    print()

    # Information removed by each constraint
    print("--- Information removed by each constraint ---")
    print()

    # Rule 1: Pair structure
    # Reduces from 64! to 32! * 2^32
    pair_bits = math.log2(math.factorial(32)) + 32
    removed_1 = total_bits - pair_bits
    print(f"Rule 1 (pair structure):     removes {removed_1:.1f} bits")
    print(f"  Remaining: {pair_bits:.1f} bits  (32! x 2^32)")

    # Rule 2: No-5 (~4.27% survive)
    no5_rate = 0.0427
    removed_2 = -math.log2(no5_rate)
    remaining_2 = pair_bits - removed_2
    print(f"Rule 2 (no 5-line):          removes {removed_2:.1f} bits  (~{no5_rate*100:.1f}% survive)")
    print(f"  Remaining: {remaining_2:.1f} bits")

    # Rule 3: Complement distance (0.31% of no-5 survive)
    comp_rate = 0.0031 / 0.0427  # conditional on no-5
    removed_3 = -math.log2(comp_rate) if comp_rate > 0 else 0
    remaining_3 = remaining_2 - removed_3
    print(f"Rule 3 (complement dist):    removes {removed_3:.1f} bits  (~{comp_rate*100:.1f}% of L1 survive)")
    print(f"  Remaining: {remaining_3:.1f} bits")

    # Rule 5: Starting pair (1/32 pairs * 1/2 orientations)
    removed_5 = math.log2(32) + 1
    remaining_5 = remaining_3 - removed_5
    print(f"Rule 5 (starting pair):      removes {removed_5:.1f} bits  (1/32 pairs x 2 orients)")
    print(f"  Remaining: {remaining_5:.1f} bits")

    # Rule 6: Difference distribution (estimated from narrowing: 0% at 100K)
    # At Level 4, 5/100000 survive. At Level 5, 0/100000.
    # Estimate: ~1 in 50000 of Level 4 survivors also satisfy Level 5
    removed_6_est = math.log2(50000)  # rough estimate
    remaining_6 = remaining_5 - removed_6_est
    print(f"Rule 6 (diff distribution):  removes ~{removed_6_est:.1f} bits  (est. ~1 in 50,000)")
    print(f"  Remaining: ~{remaining_6:.1f} bits")

    print()
    print(f"Total bits removed by known rules: ~{total_bits - remaining_6:.1f} of {total_bits:.1f}")
    print(f"Remaining unknown information: ~{max(0, remaining_6):.1f} bits")
    print()
    if remaining_6 > 0:
        print(f"This means ~2^{remaining_6:.0f} = ~{2**remaining_6:.0f} sequences likely satisfy")
        print(f"all known rules. The missing local rule must encode ~{remaining_6:.0f} additional bits.")
    else:
        print("The known rules may be sufficient to uniquely determine King Wen.")
        print("(Estimate is rough — actual count requires enumeration.)")

def compute_features(seq):
    """Compute a comprehensive feature vector for a sequence."""
    import math

    diffs = [bit_diff(seq[i], seq[i + 1]) for i in range(63)]

    # Difference distribution
    diff_dist = {}
    for d in diffs:
        diff_dist[d] = diff_dist.get(d, 0) + 1

    # Runs in difference wave
    max_run = 1
    total_runs = 1
    r = 1
    for i in range(1, len(diffs)):
        if diffs[i] == diffs[i - 1]:
            r += 1
            max_run = max(max_run, r)
        else:
            total_runs += 1
            r = 1

    # Shannon entropy of difference wave
    entropy = 0
    for count in diff_dist.values():
        p = count / 63
        if p > 0:
            entropy -= p * math.log2(p)

    # Trigram features
    upper_path = [upper_trigram(v) for v in seq]
    lower_path = [lower_trigram(v) for v in seq]

    upper_self = sum(1 for i in range(63) if upper_path[i] == upper_path[i + 1])
    lower_self = sum(1 for i in range(63) if lower_path[i] == lower_path[i + 1])
    both_change = sum(1 for i in range(63)
                      if upper_path[i] != upper_path[i + 1]
                      and lower_path[i] != lower_path[i + 1])

    # Trigram transitions used
    upper_trans = set()
    lower_trans = set()
    for i in range(63):
        if upper_path[i] != upper_path[i + 1]:
            upper_trans.add((upper_path[i], upper_path[i + 1]))
        if lower_path[i] != lower_path[i + 1]:
            lower_trans.add((lower_path[i], lower_path[i + 1]))

    # Boundary trigram links (at between-pair boundaries only)
    boundary_links = 0
    for i in range(0, 62, 2):  # between-pair: positions 1->2, 3->4, ...
        tail = seq[i + 1]
        head = seq[i + 2]
        tu, tl = upper_trigram(tail), lower_trigram(tail)
        hu, hl = upper_trigram(head), lower_trigram(head)
        if tu == hu or tl == hl or tu == hl or tl == hu:
            boundary_links += 1

    # Line autocorrelations
    line_autocorrs = []
    for line in range(6):
        bits = [(seq[i] >> line) & 1 for i in range(64)]
        mean_b = sum(bits) / 64
        var_b = sum((b - mean_b) ** 2 for b in bits) / 64
        if var_b > 0:
            ac = sum((bits[i] - mean_b) * (bits[i + 1] - mean_b)
                     for i in range(63)) / (64 * var_b)
        else:
            ac = 0
        line_autocorrs.append(ac)

    # Complement distance
    comp_dist = mean_complement_distance(seq)

    # Pair-level features
    pairs_seq = [(seq[i], seq[i + 1]) for i in range(0, 64, 2)]

    # Boundary Hamming distance distribution
    boundary_dists = [bit_diff(seq[i + 1], seq[i + 2]) for i in range(0, 62, 2)]
    mean_boundary_dist = sum(boundary_dists) / len(boundary_dists)
    boundary_dist_var = (sum((d - mean_boundary_dist) ** 2 for d in boundary_dists)
                         / len(boundary_dists))

    # Within-pair distance distribution
    within_dists = [bit_diff(seq[i], seq[i + 1]) for i in range(0, 64, 2)]
    mean_within_dist = sum(within_dists) / len(within_dists)

    # Alternation: how often does the boundary distance alternate high/low?
    alternations = 0
    for i in range(len(boundary_dists) - 1):
        if (boundary_dists[i] > mean_boundary_dist) != (boundary_dists[i + 1] > mean_boundary_dist):
            alternations += 1

    # Path smoothness: sum of |d[i+1] - d[i]| in difference wave
    smoothness = sum(abs(diffs[i + 1] - diffs[i]) for i in range(len(diffs) - 1))

    # Total path length
    total_path = sum(diffs)

    return {
        "diff_dist": diff_dist,
        "max_run": max_run,
        "total_runs": total_runs,
        "entropy": entropy,
        "upper_self_trans": upper_self,
        "lower_self_trans": lower_self,
        "both_change": both_change,
        "upper_unique_trans": len(upper_trans),
        "lower_unique_trans": len(lower_trans),
        "boundary_trigram_links": boundary_links,
        "line_autocorr": line_autocorrs,
        "line_autocorr_mean": sum(line_autocorrs) / 6,
        "line_autocorr_max": max(line_autocorrs),
        "line_autocorr_min": min(line_autocorrs),
        "line_2_autocorr": line_autocorrs[1],
        "complement_distance": comp_dist,
        "mean_boundary_dist": mean_boundary_dist,
        "boundary_dist_var": boundary_dist_var,
        "mean_within_dist": mean_within_dist,
        "boundary_alternations": alternations,
        "smoothness": smoothness,
        "total_path": total_path,
    }

def print_differential_analysis(max_nodes=10_000_000, time_limit=300):
    """Generate solutions, compute features, find what makes King Wen unique."""
    print("=" * 70)
    print("DIFFERENTIAL ANALYSIS")
    print("=" * 70)
    print()
    print("Step 1: Generate solutions satisfying all 6 rules.")
    print("Step 2: De-duplicate by pair ordering.")
    print("Step 3: Compute feature vectors.")
    print("Step 4: Find features where King Wen is extremal.")
    print()

    kw_pairs = king_wen_pairs()
    n = len(kw_pairs)

    # King Wen's difference distribution
    kw_diffs = [bit_diff(binary_hexagrams[i], binary_hexagrams[i + 1]) for i in range(63)]
    kw_dist = {}
    for d in kw_diffs:
        kw_dist[d] = kw_dist.get(d, 0) + 1
    kw_comp_dist = mean_complement_distance(binary_hexagrams)

    # --- Step 1: Generate solutions via backtracking ---
    print(f"--- Step 1: Backtracking enumeration (budget: {max_nodes:,} nodes, {time_limit}s) ---")

    first_pair_idx = None
    for i, (a, b) in enumerate(kw_pairs):
        if (a == 0b111111 and b == 0b000000) or (b == 0b111111 and a == 0b000000):
            first_pair_idx = i
            break

    solutions = []
    nodes = [0]
    start = time.time()
    exhausted = [True]

    pair_options = [[(a, b), (b, a)] for a, b in kw_pairs]

    def backtrack(seq, used, dist_budget):
        nodes[0] += 1
        if nodes[0] > max_nodes or (time.time() - start) > time_limit:
            exhausted[0] = False
            return
        if nodes[0] % 2000000 == 0:
            elapsed = time.time() - start
            print(f"  {nodes[0]:,} nodes, {len(solutions)} solutions, {elapsed:.1f}s",
                  file=sys.stderr)

        step = len(seq) // 2

        if step == n:
            if mean_complement_distance(seq) <= kw_comp_dist:
                solutions.append(list(seq))
            return

        for j in range(n):
            if j in used:
                continue
            for first, second in pair_options[j]:
                if seq and bit_diff(seq[-1], first) == 5:
                    continue

                new_budget = dict(dist_budget)
                if seq:
                    bd = bit_diff(seq[-1], first)
                    if new_budget.get(bd, 0) <= 0:
                        continue
                    new_budget[bd] -= 1

                wd = bit_diff(first, second)
                if new_budget.get(wd, 0) <= 0:
                    continue
                new_budget[wd] -= 1

                backtrack(seq + [first, second], used | {j}, new_budget)

                if nodes[0] > max_nodes or (time.time() - start) > time_limit:
                    exhausted[0] = False
                    return

    init_budget = dict(kw_dist)
    fd = bit_diff(0b111111, 0b000000)
    init_budget[fd] -= 1
    backtrack([0b111111, 0b000000], {first_pair_idx}, init_budget)

    elapsed = time.time() - start
    status = "COMPLETE" if exhausted[0] else "BUDGET EXHAUSTED"
    print(f"\n{status}: {nodes[0]:,} nodes, {len(solutions)} solutions, {elapsed:.1f}s")

    if len(solutions) < 2:
        print("Not enough solutions for differential analysis.")
        return

    # --- Step 2: De-duplicate by pair ordering ---
    print(f"\n--- Step 2: De-duplicate by pair ordering ---")

    def pair_ordering_key(seq):
        """Extract pair ordering ignoring within-pair orientation."""
        pairs = []
        for i in range(0, 64, 2):
            pair = tuple(sorted([seq[i], seq[i + 1]]))
            pairs.append(pair)
        return tuple(pairs)

    seen_orderings = {}
    for sol in solutions:
        key = pair_ordering_key(sol)
        if key not in seen_orderings:
            seen_orderings[key] = []
        seen_orderings[key].append(sol)

    unique_orderings = len(seen_orderings)
    print(f"Total solutions: {len(solutions)}")
    print(f"Unique pair orderings: {unique_orderings}")
    print(f"Mean orientation variants per ordering: {len(solutions)/unique_orderings:.1f}")

    # Take one representative per unique ordering
    representatives = [variants[0] for variants in seen_orderings.values()]

    # --- Step 3: Compute feature vectors ---
    print(f"\n--- Step 3: Compute features for {len(representatives)} unique orderings ---")

    kw_features = compute_features(binary_hexagrams)
    all_features = []
    kw_index = None
    for i, sol in enumerate(representatives):
        f = compute_features(sol)
        all_features.append(f)
        if sol == binary_hexagrams:
            kw_index = i

    if kw_index is not None:
        print(f"King Wen is solution #{kw_index + 1}")
    else:
        print("King Wen not found among representatives (may be an orientation variant)")
        # Find it among all solutions
        for sol in solutions:
            if sol == binary_hexagrams:
                kw_features = compute_features(binary_hexagrams)
                print("(Using King Wen features directly)")
                break

    # --- Step 4: Find extremal features ---
    print(f"\n--- Step 4: Features where King Wen is extremal ---")
    print()
    print("For each feature, showing King Wen's rank among all solutions.")
    print("Rank 1 = lowest, rank N = highest. Extremal = rank 1 or rank N.")
    print()

    # Scalar features to test
    scalar_features = [
        "max_run", "total_runs", "entropy", "upper_self_trans", "lower_self_trans",
        "both_change", "upper_unique_trans", "lower_unique_trans",
        "boundary_trigram_links", "line_autocorr_mean", "line_autocorr_max",
        "line_autocorr_min", "line_2_autocorr", "complement_distance",
        "mean_boundary_dist", "boundary_dist_var", "mean_within_dist",
        "boundary_alternations", "smoothness", "total_path",
    ]

    print(f"{'Feature':<28} {'KW value':>10} {'Rank':>6} {'of':>3} "
          f"{'N':>5} {'Min':>10} {'Max':>10} {'Extremal?':>10}")
    print(f"{'-'*28} {'-'*10} {'-'*6} {'-'*3} "
          f"{'-'*5} {'-'*10} {'-'*10} {'-'*10}")

    extremal_features = []
    notable_features = []
    n_sol = len(all_features)

    for feat_name in scalar_features:
        kw_val = kw_features[feat_name]
        all_vals = sorted(f[feat_name] for f in all_features)
        rank = sum(1 for v in all_vals if v <= kw_val)
        min_val = all_vals[0]
        max_val = all_vals[-1]

        is_extremal = ""
        if rank == 1 or rank == n_sol:
            is_extremal = "*** EXTREMAL"
            extremal_features.append((feat_name, kw_val, rank, n_sol))
        elif rank <= 3 or rank >= n_sol - 2:
            is_extremal = "* near"
            notable_features.append((feat_name, kw_val, rank, n_sol))

        kw_str = f"{kw_val:.3f}" if isinstance(kw_val, float) else str(kw_val)
        min_str = f"{min_val:.3f}" if isinstance(min_val, float) else str(min_val)
        max_str = f"{max_val:.3f}" if isinstance(max_val, float) else str(max_val)

        print(f"{feat_name:<28} {kw_str:>10} {rank:>6} {'of':>3} "
              f"{n_sol:>5} {min_str:>10} {max_str:>10} {is_extremal:>10}")

    # Also test individual line autocorrelations
    for line in range(6):
        feat_name = f"line_{line+1}_autocorr"
        kw_val = kw_features["line_autocorr"][line]
        all_vals = sorted(f["line_autocorr"][line] for f in all_features)
        rank = sum(1 for v in all_vals if v <= kw_val)
        min_val = all_vals[0]
        max_val = all_vals[-1]

        is_extremal = ""
        if rank == 1 or rank == n_sol:
            is_extremal = "*** EXTREMAL"
            extremal_features.append((feat_name, kw_val, rank, n_sol))
        elif rank <= 3 or rank >= n_sol - 2:
            is_extremal = "* near"
            notable_features.append((feat_name, kw_val, rank, n_sol))

        print(f"{feat_name:<28} {kw_val:>10.3f} {rank:>6} {'of':>3} "
              f"{n_sol:>5} {min_val:>10.3f} {max_val:>10.3f} {is_extremal:>10}")

    print()
    print("=" * 70)
    print("SUMMARY")
    print("=" * 70)
    print()

    if extremal_features:
        print(f"EXTREMAL features ({len(extremal_features)} found):")
        print("King Wen has the min or max value among ALL solutions:")
        for name, val, rank, total in extremal_features:
            direction = "MINIMUM" if rank == 1 else "MAXIMUM"
            val_str = f"{val:.3f}" if isinstance(val, float) else str(val)
            print(f"  {name}: {val_str} ({direction} of {total} solutions)")
        print()
        print("These are candidate rules — properties that could narrow the solution")
        print("space to King Wen alone. To verify, add each as a constraint and")
        print("re-run enumeration.")
    else:
        print("No extremal features found. King Wen is not at the min or max of")
        print("any measured property. The missing rule may involve a combination")
        print("of features or a property not yet measured.")

    if notable_features:
        print(f"\nNear-extremal features ({len(notable_features)} found):")
        for name, val, rank, total in notable_features:
            pct = rank / total * 100
            val_str = f"{val:.3f}" if isinstance(val, float) else str(val)
            print(f"  {name}: {val_str} (rank {rank}/{total}, {pct:.0f}th percentile)")

    print()
    print(f"Solutions analyzed: {n_sol} unique pair orderings")
    print(f"Features tested: {len(scalar_features) + 6} (including 6 line autocorrelations)")
    search_status = "complete" if exhausted[0] else "partial (budget exhausted)"
    print(f"Search: {search_status}")
    if not exhausted[0]:
        print("Note: more solutions may exist beyond the search budget. Extremal")
        print("findings are relative to the solutions found, not the full space.")

def print_rule7_test(max_nodes=100_000_000, time_limit=3600):
    """Test candidate 7th rules: filter solutions by extremal features."""
    import math

    print("=" * 70)
    print("RULE 7 CANDIDATE TEST")
    print("=" * 70)
    print()
    print("Testing whether the two discovered extremal features narrow the")
    print("solution space to King Wen uniquely.")
    print()
    print("Rule 7a: complement_distance must equal 12.125 (exact maximum)")
    print("Rule 7b: mean line autocorrelation must equal -0.115 (exact maximum)")
    print()

    kw_pairs = king_wen_pairs()
    n = len(kw_pairs)

    kw_diffs = [bit_diff(binary_hexagrams[i], binary_hexagrams[i + 1]) for i in range(63)]
    kw_dist = {}
    for d in kw_diffs:
        kw_dist[d] = kw_dist.get(d, 0) + 1
    kw_comp_dist = mean_complement_distance(binary_hexagrams)
    kw_features = compute_features(binary_hexagrams)
    kw_autocorr_mean = kw_features["line_autocorr_mean"]

    first_pair_idx = None
    for i, (a, b) in enumerate(kw_pairs):
        if (a == 0b111111 and b == 0b000000) or (b == 0b111111 and a == 0b000000):
            first_pair_idx = i
            break

    # Collect solutions at three levels:
    # Level A: Rules 1-6 only (baseline)
    # Level B: + Rule 7a (complement distance == max)
    # Level C: + Rule 7a + 7b (complement distance == max AND autocorr == max)
    solutions_baseline = []
    solutions_7a = []
    solutions_7ab = []
    nodes = [0]
    start = time.time()
    exhausted = [True]

    pair_options = [[(a, b), (b, a)] for a, b in kw_pairs]

    def backtrack(seq, used, dist_budget):
        nodes[0] += 1
        if nodes[0] > max_nodes or (time.time() - start) > time_limit:
            exhausted[0] = False
            return
        if nodes[0] % 2000000 == 0:
            elapsed = time.time() - start
            print(f"  {nodes[0]:,} nodes, {len(solutions_baseline)} baseline, "
                  f"{len(solutions_7a)} rule7a, {len(solutions_7ab)} rule7ab, "
                  f"{elapsed:.1f}s", file=sys.stderr)

        step = len(seq) // 2

        if step == n:
            cd = mean_complement_distance(seq)
            if cd > kw_comp_dist:
                return

            solutions_baseline.append(list(seq))

            # Rule 7a: exact complement distance
            if abs(cd - kw_comp_dist) < 0.001:
                solutions_7a.append(list(seq))

                # Rule 7b: exact line autocorrelation mean
                feat = compute_features(seq)
                if abs(feat["line_autocorr_mean"] - kw_autocorr_mean) < 0.0001:
                    solutions_7ab.append(list(seq))
            return

        for j in range(n):
            if j in used:
                continue
            for first, second in pair_options[j]:
                if seq and bit_diff(seq[-1], first) == 5:
                    continue

                new_budget = dict(dist_budget)
                if seq:
                    bd = bit_diff(seq[-1], first)
                    if new_budget.get(bd, 0) <= 0:
                        continue
                    new_budget[bd] -= 1

                wd = bit_diff(first, second)
                if new_budget.get(wd, 0) <= 0:
                    continue
                new_budget[wd] -= 1

                backtrack(seq + [first, second], used | {j}, new_budget)

                if nodes[0] > max_nodes or (time.time() - start) > time_limit:
                    exhausted[0] = False
                    return

    print(f"Searching (budget: {max_nodes:,} nodes, {time_limit}s)...")
    init_budget = dict(kw_dist)
    fd = bit_diff(0b111111, 0b000000)
    init_budget[fd] -= 1
    backtrack([0b111111, 0b000000], {first_pair_idx}, init_budget)

    elapsed = time.time() - start
    status = "COMPLETE" if exhausted[0] else "BUDGET EXHAUSTED"
    print(f"\n{status}: {nodes[0]:,} nodes, {elapsed:.1f}s")
    print()

    # De-duplicate each level
    def dedup(solutions):
        seen = set()
        unique = []
        for sol in solutions:
            key = tuple(tuple(sorted([sol[i], sol[i+1]])) for i in range(0, 64, 2))
            if key not in seen:
                seen.add(key)
                unique.append(sol)
        return unique

    base_unique = dedup(solutions_baseline)
    r7a_unique = dedup(solutions_7a)
    r7ab_unique = dedup(solutions_7ab)

    print("=" * 70)
    print("RESULTS")
    print("=" * 70)
    print()
    print(f"{'Level':<40} {'Raw':>8} {'Unique':>8}")
    print(f"{'-----':<40} {'---':>8} {'------':>8}")
    print(f"{'Rules 1-6 (baseline)':<40} {len(solutions_baseline):>8,} {len(base_unique):>8,}")
    print(f"{'+ Rule 7a (complement dist = 12.125)':<40} {len(solutions_7a):>8,} {len(r7a_unique):>8,}")
    print(f"{'+ Rule 7b (line autocorr mean = -0.115)':<40} {len(solutions_7ab):>8,} {len(r7ab_unique):>8,}")
    print()

    # Check if King Wen is among the survivors
    kw_in_base = any(s == binary_hexagrams for s in solutions_baseline)
    kw_in_7a = any(s == binary_hexagrams for s in solutions_7a)
    kw_in_7ab = any(s == binary_hexagrams for s in solutions_7ab)
    print(f"King Wen in baseline: {'YES' if kw_in_base else 'No'}")
    print(f"King Wen in Rule 7a:  {'YES' if kw_in_7a else 'No'}")
    print(f"King Wen in Rule 7ab: {'YES' if kw_in_7ab else 'No'}")
    print()

    if r7ab_unique:
        if len(r7ab_unique) == 1 and r7ab_unique[0] == binary_hexagrams:
            print("*** KING WEN IS THE UNIQUE SOLUTION UNDER RULES 1-7 ***")
            print()
            print("The generative recipe is complete. The King Wen sequence is the")
            print("only ordering of 64 hexagrams satisfying all 8 constraints:")
            print("  1. Pair structure (reverse/inverse)")
            print("  2. No 5-line transitions")
            print("  3. Complement distance <= 12.125")
            print("  4. XOR products within 7 values (redundant)")
            print("  5. Starts with Creative/Receptive")
            print("  6. Exact difference wave distribution")
            print("  7a. Complement distance = 12.125 (maximum)")
            print("  7b. Mean line autocorrelation = -0.115 (maximum)")
        else:
            print(f"Rules 1-7 narrow to {len(r7ab_unique)} unique orderings.")
            print("King Wen is not yet uniquely determined.")
            print()
            print("--- Surviving solutions ---")
            for i, sol in enumerate(r7ab_unique[:20]):
                stats = compare_sequences(sol)
                is_kw = "*** KING WEN ***" if stats['is_king_wen'] else ""
                print(f"  #{i+1}: pair_pos={stats['pair_position_matches']}/32, "
                      f"exact={stats['position_matches']}/64, "
                      f"wave={stats['wave_matches']}/63 {is_kw}")

            if len(r7ab_unique) <= 50:
                print()
                print("--- Feature analysis of survivors ---")
                all_feat = [compute_features(s) for s in r7ab_unique]
                kw_feat = compute_features(binary_hexagrams)
                scalar_feats = [
                    "total_runs", "upper_self_trans", "lower_self_trans",
                    "both_change", "upper_unique_trans", "lower_unique_trans",
                    "boundary_trigram_links", "boundary_alternations", "smoothness",
                ]
                print(f"{'Feature':<28} {'KW':>8} {'Min':>8} {'Max':>8} {'Extremal?':>10}")
                print(f"{'-'*28} {'-'*8} {'-'*8} {'-'*8} {'-'*10}")
                for fname in scalar_feats:
                    kv = kw_feat[fname]
                    vals = [f[fname] for f in all_feat]
                    mn, mx = min(vals), max(vals)
                    ext = ""
                    if kv == mn and kv != mx:
                        ext = "*** MIN"
                    elif kv == mx and kv != mn:
                        ext = "*** MAX"
                    print(f"{fname:<28} {kv:>8} {mn:>8} {mx:>8} {ext:>10}")

    elif len(solutions_7a) > 0 and len(solutions_7ab) == 0:
        print("Rule 7b eliminated all Rule 7a survivors (including King Wen).")
        print("This suggests the autocorrelation threshold is too strict for")
        print("the partial search. A longer run may find matching solutions.")

    search_note = "" if exhausted[0] else " (partial — more solutions may exist)"
    print(f"\nSearch: {status}{search_note}")

def generate_rule7a_solutions(max_nodes=30_000_000, time_limit=120):
    """Generate solutions satisfying Rules 1-6 + Rule 7a (exact complement distance).
    Returns list of unique pair orderings."""
    kw_pairs = king_wen_pairs()
    n = len(kw_pairs)
    kw_diffs = [bit_diff(binary_hexagrams[i], binary_hexagrams[i + 1]) for i in range(63)]
    kw_dist = {}
    for d in kw_diffs:
        kw_dist[d] = kw_dist.get(d, 0) + 1
    kw_comp_dist = mean_complement_distance(binary_hexagrams)

    first_pair_idx = 0  # Creative/Receptive
    pair_options = [[(a, b), (b, a)] for a, b in kw_pairs]

    solutions = []
    nodes = [0]
    start = time.time()

    def backtrack(seq, used, dist_budget):
        nodes[0] += 1
        if nodes[0] > max_nodes or (time.time() - start) > time_limit:
            return
        step = len(seq) // 2
        if step == n:
            cd = mean_complement_distance(seq)
            if abs(cd - kw_comp_dist) < 0.001:
                solutions.append(list(seq))
            return
        for j in range(n):
            if j in used:
                continue
            for first, second in pair_options[j]:
                if seq and bit_diff(seq[-1], first) == 5:
                    continue
                new_budget = dict(dist_budget)
                if seq:
                    bd = bit_diff(seq[-1], first)
                    if new_budget.get(bd, 0) <= 0:
                        continue
                    new_budget[bd] -= 1
                wd = bit_diff(first, second)
                if new_budget.get(wd, 0) <= 0:
                    continue
                new_budget[wd] -= 1
                backtrack(seq + [first, second], used | {j}, new_budget)
                if nodes[0] > max_nodes or (time.time() - start) > time_limit:
                    return

    init_budget = dict(kw_dist)
    init_budget[bit_diff(0b111111, 0b000000)] -= 1
    backtrack([0b111111, 0b000000], {first_pair_idx}, init_budget)

    # De-duplicate
    seen = set()
    unique = []
    for sol in solutions:
        key = tuple(tuple(sorted([sol[i], sol[i + 1]])) for i in range(0, 64, 2))
        if key not in seen:
            seen.add(key)
            unique.append(sol)

    elapsed = time.time() - start
    print(f"  Generated {len(solutions)} raw -> {len(unique)} unique orderings "
          f"({nodes[0]:,} nodes, {elapsed:.1f}s)", file=sys.stderr)
    return unique

def print_fingerprint(max_nodes=30_000_000, time_limit=120):
    """Three analyses to characterize the missing rule."""
    print("=" * 70)
    print("FINGERPRINT ANALYSIS")
    print("=" * 70)
    print()
    print("Characterize what distinguishes King Wen from the ~974 other orderings")
    print("satisfying Rules 1-7a.")
    print()

    print("Generating Rule 7a solutions...")
    survivors = generate_rule7a_solutions(max_nodes=max_nodes, time_limit=time_limit)

    if len(survivors) < 2:
        print("Not enough solutions for analysis.")
        return

    # Separate King Wen from the rest
    kw_seq = binary_hexagrams
    others = [s for s in survivors if s != kw_seq]
    kw_found = len(survivors) - len(others) > 0
    print(f"\nTotal unique orderings: {len(survivors)}")
    print(f"King Wen found: {'YES' if kw_found else 'No'}")
    print(f"Non-King-Wen orderings: {len(others)}")
    print()

    # Extract pair orderings for comparison
    def get_pair_ordering(seq):
        """Return list of 32 (canonical_pair, orientation) tuples."""
        result = []
        for i in range(0, 64, 2):
            a, b = seq[i], seq[i + 1]
            canonical = tuple(sorted([a, b]))
            orient = 0 if a <= b else 1
            result.append((canonical, orient))
        return result

    kw_pairs_ord = get_pair_ordering(kw_seq)
    kw_canonical = [p for p, o in kw_pairs_ord]

    # =========================================================
    # ANALYSIS 1: Free vs locked positions
    # =========================================================
    print("=" * 70)
    print("ANALYSIS 1: FREE vs LOCKED PAIR POSITIONS")
    print("=" * 70)
    print()
    print("Which of the 32 pair positions always match King Wen (locked)")
    print("vs sometimes differ (free)?")
    print()

    position_varies = [False] * 32
    position_match_counts = [0] * 32

    for sol in survivors:
        sol_canonical = [tuple(sorted([sol[i], sol[i + 1]])) for i in range(0, 64, 2)]
        for pos in range(32):
            if sol_canonical[pos] == kw_canonical[pos]:
                position_match_counts[pos] += 1
            else:
                position_varies[pos] = True

    locked = [i for i in range(32) if not position_varies[i]]
    free = [i for i in range(32) if position_varies[i]]

    print(f"Locked positions (same in ALL solutions): {len(locked)}/32")
    print(f"Free positions (vary across solutions):   {len(free)}/32")
    print()

    if locked:
        print("Locked positions:", ", ".join(str(i + 1) for i in locked))
    if free:
        print("Free positions:  ", ", ".join(str(i + 1) for i in free))
        print()
        print("Match rate per free position (% of solutions matching King Wen):")
        for pos in free:
            rate = position_match_counts[pos] / len(survivors) * 100
            kw_pair = kw_canonical[pos]
            a, b = kw_pair
            print(f"  Position {pos + 1:>2}: {rate:>5.1f}% match KW  "
                  f"(pair: {bin(a)[2:].zfill(6)}+{bin(b)[2:].zfill(6)})")

    # =========================================================
    # ANALYSIS 2: Edit distance clustering
    # =========================================================
    print()
    print("=" * 70)
    print("ANALYSIS 2: EDIT DISTANCE FROM KING WEN")
    print("=" * 70)
    print()
    print("How many pair positions differ between each survivor and King Wen?")
    print()

    edit_distances = []
    for sol in others:
        sol_canonical = [tuple(sorted([sol[i], sol[i + 1]])) for i in range(0, 64, 2)]
        diff_count = sum(1 for i in range(32) if sol_canonical[i] != kw_canonical[i])
        edit_distances.append(diff_count)

    if edit_distances:
        dist_counts = {}
        for d in edit_distances:
            dist_counts[d] = dist_counts.get(d, 0) + 1

        print(f"{'Pairs different':>15} {'Count':>8} {'Cumulative':>12}")
        print(f"{'---------------':>15} {'-----':>8} {'----------':>12}")
        cumulative = 0
        for d in sorted(dist_counts):
            cumulative += dist_counts[d]
            print(f"{d:>15} {dist_counts[d]:>8} {cumulative:>12}")

        # Show the closest non-KW solutions
        print()
        closest = sorted(zip(edit_distances, others), key=lambda x: x[0])
        print(f"--- Closest non-King-Wen solutions ---")
        for i, (dist, sol) in enumerate(closest[:10]):
            sol_canonical = [tuple(sorted([sol[i2], sol[i2 + 1]]))
                            for i2 in range(0, 64, 2)]
            diff_positions = [pos + 1 for pos in range(32)
                             if sol_canonical[pos] != kw_canonical[pos]]
            print(f"  Edit distance {dist}: positions {diff_positions}")

    # =========================================================
    # ANALYSIS 3: Minimum distinguishing constraints
    # =========================================================
    print()
    print("=" * 70)
    print("ANALYSIS 3: MINIMUM DISTINGUISHING CONSTRAINTS")
    print("=" * 70)
    print()
    print("For each pair adjacency in King Wen, how many survivors share it?")
    print("Adjacencies that ALL survivors share are forced by the rules.")
    print("Adjacencies unique to King Wen are the distinguishing constraints.")
    print()

    # King Wen's pair adjacencies (which canonical pair follows which)
    kw_adjacencies = []
    for i in range(31):
        kw_adjacencies.append((kw_canonical[i], kw_canonical[i + 1]))

    # Count how many survivors share each adjacency
    adjacency_counts = [0] * 31
    for sol in survivors:
        sol_canonical = [tuple(sorted([sol[i], sol[i + 1]])) for i in range(0, 64, 2)]
        for pos in range(31):
            if (sol_canonical[pos] == kw_canonical[pos] and
                    sol_canonical[pos + 1] == kw_canonical[pos + 1]):
                adjacency_counts[pos] += 1

    universal = []
    rare = []
    unique_to_kw = []

    print(f"{'Boundary':>8} {'Shared by':>10} {'of':>3} {len(survivors):>5} {'Rate':>7} Note")
    print(f"{'--------':>8} {'---------':>10} {'--':>3} {'-----':>5} {'----':>7} ----")
    for pos in range(31):
        count = adjacency_counts[pos]
        rate = count / len(survivors) * 100
        note = ""
        if count == len(survivors):
            note = "UNIVERSAL (forced by rules)"
            universal.append(pos)
        elif count == 1:
            note = "UNIQUE TO KING WEN"
            unique_to_kw.append(pos)
        elif rate < 10:
            note = "rare"
            rare.append(pos)
        print(f"{pos + 1:>8} {count:>10} {'of':>3} {len(survivors):>5} {rate:>6.1f}% {note}")

    print()
    print(f"Universal adjacencies (forced by rules): {len(universal)}/31")
    print(f"Rare adjacencies (<10% of survivors):    {len(rare)}/31")
    print(f"Unique to King Wen:                      {len(unique_to_kw)}/31")

    if unique_to_kw:
        print()
        print("The unique adjacencies ARE the missing rule — King Wen is the only")
        print("solution that has these specific pairs next to each other:")
        for pos in unique_to_kw:
            a1, b1 = kw_canonical[pos]
            a2, b2 = kw_canonical[pos + 1]
            # Get position numbers in King Wen
            pos1 = pos * 2 + 1
            pos2 = pos * 2 + 3
            print(f"  Boundary {pos + 1}: pair at positions {pos1}-{pos1+1} "
                  f"({bin(a1)[2:].zfill(6)}+{bin(b1)[2:].zfill(6)}) "
                  f"adjacent to pair at positions {pos2}-{pos2+1} "
                  f"({bin(a2)[2:].zfill(6)}+{bin(b2)[2:].zfill(6)})")

    # How many rare+unique adjacencies needed to eliminate all non-KW solutions?
    if others:
        print()
        print("--- Minimum constraint set ---")
        print("Greedy search: what's the smallest set of King Wen adjacencies")
        print("that eliminates all non-King-Wen solutions?")
        print()

        remaining = set(range(len(others)))
        selected = []

        # Build elimination matrix: which adjacency eliminates which solution
        elim = {}
        for pos in range(31):
            elim[pos] = set()
            for idx, sol in enumerate(others):
                sol_canonical = [tuple(sorted([sol[i], sol[i + 1]]))
                                for i in range(0, 64, 2)]
                if (sol_canonical[pos] != kw_canonical[pos] or
                        sol_canonical[pos + 1] != kw_canonical[pos + 1]):
                    elim[pos].add(idx)

        while remaining:
            # Pick adjacency that eliminates the most remaining solutions
            best_pos = max(range(31), key=lambda p: len(elim[p] & remaining))
            eliminated = elim[best_pos] & remaining
            if not eliminated:
                print(f"  WARNING: cannot eliminate {len(remaining)} remaining solutions")
                print(f"  with pair adjacency constraints alone.")
                break
            remaining -= eliminated
            selected.append((best_pos, len(eliminated)))
            print(f"  Adjacency {best_pos + 1:>2}: eliminates {len(eliminated):>4} solutions "
                  f"({len(remaining):>4} remaining)")

        print()
        print(f"Minimum adjacency constraints needed: {len(selected)}")
        print(f"Constraint positions: {[pos + 1 for pos, _ in selected]}")
        print()
        if len(selected) <= 10:
            print("These adjacencies, combined with Rules 1-7a, uniquely determine")
            print("the King Wen sequence.")

def main():
    parser = argparse.ArgumentParser(
        description="Constraint solver for the King Wen sequence",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="See SOLVE.md for methodology and results.",
    )
    parser.add_argument("--pairs", action="store_true",
                        help="Show the 32 canonical pairs with XOR products")
    parser.add_argument("--rules", action="store_true",
                        help="Print the discovered generative recipe")
    parser.add_argument("--narrow", action="store_true",
                        help="Run constraint narrowing analysis")
    parser.add_argument("--graph", action="store_true",
                        help="Analyze the pair adjacency graph")
    parser.add_argument("--boundaries", action="store_true",
                        help="Analyze features at between-pair boundaries")
    parser.add_argument("--construct", action="store_true",
                        help="Sequential construction analysis with heuristics")
    parser.add_argument("--local", action="store_true",
                        help="Run all local ordering analyses (graph + boundaries + construct)")
    parser.add_argument("--enumerate", action="store_true",
                        help="Backtracking enumeration with all constraints")
    parser.add_argument("--trigram-paths", action="store_true",
                        help="Track upper/lower trigram paths through the sequence")
    parser.add_argument("--line-decomp", action="store_true",
                        help="Analyze each of the 6 line positions independently")
    parser.add_argument("--pair-neighborhoods", action="store_true",
                        help="Pair clustering and neighborhood structure")
    parser.add_argument("--residuals", action="store_true",
                        help="Compare constraint survivors against King Wen")
    parser.add_argument("--info", action="store_true",
                        help="Information content analysis")
    parser.add_argument("--deep", action="store_true",
                        help="Run all deep analyses (enumerate + trigram + lines + neighborhoods + residuals + info)")
    parser.add_argument("--differential", action="store_true",
                        help="Differential analysis: find features where King Wen is extremal among solutions")
    parser.add_argument("--rule7", action="store_true",
                        help="Test Rule 7 candidates: filter by extremal complement distance and line autocorrelation")
    parser.add_argument("--fingerprint", action="store_true",
                        help="Fingerprint analysis: free positions, edit distances, minimum constraints")
    parser.add_argument("--max-nodes", type=int, default=10_000_000,
                        help="Max nodes for backtracking enumeration (default: 10M)")
    parser.add_argument("--time-limit", type=int, default=60,
                        help="Time limit in seconds for enumeration (default: 60)")
    parser.add_argument("--trials", type=int, default=100000,
                        help="Number of random samples (default: 100000)")
    parser.add_argument("--seed", type=int, default=None,
                        help="Random seed for reproducible results")
    parser.add_argument("--verbose", action="store_true",
                        help="Print progress during search")

    args = parser.parse_args()

    if args.local:
        args.graph = True
        args.boundaries = True
        args.construct = True

    if args.deep:
        args.enumerate = True
        args.trigram_paths = True
        args.line_decomp = True
        args.pair_neighborhoods = True
        args.residuals = True
        args.info = True

    all_flags = [args.pairs, args.rules, args.narrow, args.graph,
                 args.boundaries, args.construct, args.enumerate,
                 args.trigram_paths, args.line_decomp, args.pair_neighborhoods,
                 args.residuals, args.info, args.differential, args.rule7,
                 args.fingerprint]
    if not any(all_flags):
        args.rules = True
        args.narrow = True

    pairs = build_pairs()

    if args.pairs:
        print_pair_info(pairs)
        print()

    if args.rules:
        print_rules()
        print()

    if args.narrow:
        print_constraint_narrowing(pairs, seed=args.seed, trials=args.trials,
                                   verbose=args.verbose)

    if args.graph:
        print_adjacency_graph(pairs)
        print()

    if args.boundaries:
        print_boundary_features()
        print()

    if args.construct:
        print_sequential_construction()
        print()

    if args.enumerate:
        print_enumerate(max_nodes=args.max_nodes, time_limit=args.time_limit)
        print()

    if args.trigram_paths:
        print_trigram_paths()
        print()

    if args.line_decomp:
        print_line_decomposition()
        print()

    if args.pair_neighborhoods:
        print_pair_neighborhoods()
        print()

    if args.residuals:
        print_constraint_residuals()
        print()

    if args.info:
        print_info_content()
        print()

    if args.differential:
        print_differential_analysis(max_nodes=args.max_nodes,
                                    time_limit=args.time_limit)
        print()

    if args.rule7:
        print_rule7_test(max_nodes=args.max_nodes, time_limit=args.time_limit)
        print()

    if args.fingerprint:
        print_fingerprint(max_nodes=args.max_nodes, time_limit=args.time_limit)
        print()

if __name__ == "__main__":
    main()
