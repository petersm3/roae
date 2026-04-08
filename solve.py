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
    parser.add_argument("--trials", type=int, default=100000,
                        help="Number of random samples (default: 100000)")
    parser.add_argument("--seed", type=int, default=None,
                        help="Random seed for reproducible results")
    parser.add_argument("--verbose", action="store_true",
                        help="Print progress during search")

    args = parser.parse_args()

    if not any([args.pairs, args.rules, args.narrow]):
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

if __name__ == "__main__":
    main()
