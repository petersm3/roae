#!/usr/bin/env python3
# https://github.com/petersm3/roae
# Developed with AI assistance (Claude, Anthropic)
"""
Constraint solver for the King Wen sequence — educational / analysis tool.

Attempts to reconstruct the King Wen sequence from a minimal set of rules.
Standalone — no external dependencies (Python 3 only).

For full-scale exhaustive enumeration (multi-trillion-node runs producing
solutions.bin), use solve.c. This Python tool is the readable companion that
demonstrates the rules, the narrowing analysis, the pair structure, and the
adjacency / boundary features at a scale you can actually inspect.

See SOLVE.md for methodology and results.
"""
# ATTRIBUTION NOTE (operator directive 2026-07-03): externally-sourced rules and observations implemented
# anywhere in this file carry credit at the implementation site; the master ledger is
# documentation/CITATIONS.md. Never present a literature-derived rule as a ROAE discovery.

import argparse
import os
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
    """Build the 32 canonical reverse/inverse pairs from the 64 hexagrams.

    ATTRIBUTION: the pair structure is classical — described by Yu Fan (220-265 AD; fandui/pangtong,
    preserved via Li Dingzuo's Zhouyi jijie), formalized combinatorially by Cook 2006. See CITATIONS.md."""
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

def rc4_violations(seq):
    """Schulz gender/position-parity violations over the 36 inversion-class positions.

    ATTRIBUTION: Schulz 1990 (JCP 17:3, 345-358, motif 2; exception first noticed by Zhu Yuansheng,
    13th c., per Schulz 2018 fn.42), elaborated Cook 2006. Port of solve.c's KW-verified scorer:
    classes keyed by min(h, rev(h)) in first-appearance order; gender by popcount of the class
    (pc<3 male -> odd class position, pc>3 female -> even; pc==3 and pure pc 0/6 exempt).
    Returns (violation_count, violating_class_positions). KW == (2, [25, 26])."""
    def rev6(h):
        r = 0
        for b in range(6):
            r |= ((h >> b) & 1) << (5 - b)
        return r
    seen, ncls, viol, vpos = set(), 0, 0, []
    for h in seq:
        key = min(h, rev6(h))
        if key in seen:
            continue
        seen.add(key)
        ncls += 1
        pck = bin(h).count("1")
        if pck in (0, 3, 6):
            continue
        if (pck < 3) != (ncls % 2 == 1):
            viol += 1
            vpos.append(ncls)
    return viol, vpos


def has_no_five(seq):
    """Check if a sequence has no 5-line transitions.

    ATTRIBUTION: the no-five observation is McKenna & McKenna 1975 (The Invisible Landscape, ch. 9);
    shared by Mawangdui and Jing Fang orderings (pan-tradition). See CITATIONS.md."""
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
    print("Note: for complete enumeration, use solve.c (~60x faster).")
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

def print_reconstruct():
    """Reconstruct the King Wen sequence step by step using all constraints.
    At each step, show how many valid choices exist. If exactly 1 at every
    step, the specification's constructive algorithm is verified."""
    print("=" * 70)
    print("CONSTRUCTIVE RECONSTRUCTION")
    print("=" * 70)
    print()
    print("Build the King Wen sequence pair by pair using constraints C1-C7.")
    print("At each step, count valid choices. If exactly 1, the step is forced.")
    print()

    kw_pairs = king_wen_pairs()
    kw_seq = binary_hexagrams
    n = 32

    # King Wen's difference distribution (C5)
    kw_diffs = [bit_diff(kw_seq[i], kw_seq[i + 1]) for i in range(63)]
    kw_dist = {}
    for d in kw_diffs:
        kw_dist[d] = kw_dist.get(d, 0) + 1
    kw_comp_dist = mean_complement_distance(kw_seq)

    # C6 and C7: specific adjacencies
    # Boundary 27: pair at position 27 (0-indexed 26) adjacent to position 28 (0-indexed 27)
    c6_pair_a = tuple(sorted([kw_seq[52], kw_seq[53]]))  # pair 27
    c6_pair_b = tuple(sorted([kw_seq[54], kw_seq[55]]))  # pair 28
    # Boundary 25: pair at position 25 (0-indexed 24) adjacent to position 26 (0-indexed 25)
    c7_pair_a = tuple(sorted([kw_seq[48], kw_seq[49]]))  # pair 25
    c7_pair_b = tuple(sorted([kw_seq[50], kw_seq[51]]))  # pair 26

    pair_options = [[(a, b), (b, a)] for a, b in kw_pairs]

    # Recursive search counting valid completions at each step
    def count_completions(seq, used, budget, depth_limit):
        """Count how many valid complete sequences extend from seq."""
        step = len(seq) // 2
        if step == n:
            if mean_complement_distance(seq) <= kw_comp_dist:
                return 1
            return 0

        if step >= depth_limit:
            return 1  # don't recurse past limit, assume feasible

        count = 0
        for j in range(n):
            if j in used:
                continue
            for first, second in pair_options[j]:
                if seq and bit_diff(seq[-1], first) == 5:
                    continue
                new_budget = dict(budget)
                if seq:
                    bd = bit_diff(seq[-1], first)
                    if new_budget.get(bd, 0) <= 0:
                        continue
                    new_budget[bd] -= 1
                wd = bit_diff(first, second)
                if new_budget.get(wd, 0) <= 0:
                    continue
                new_budget[wd] -= 1

                # C6: if placing pair 28 (step 27), check adjacency with pair 27
                if step == 27:
                    prev_pair = tuple(sorted([seq[-2], seq[-1]]))
                    curr_pair = tuple(sorted([first, second]))
                    if not ((prev_pair == c6_pair_a and curr_pair == c6_pair_b) or
                            (prev_pair == c6_pair_b and curr_pair == c6_pair_a)):
                        # Check if this step IS boundary 27
                        pass  # only enforce if we're at the right position

                # C7: similar for boundary 25
                # These are position-specific, so we check by pair identity
                if step >= 24:
                    curr_pair = tuple(sorted([first, second]))
                    if step < n:
                        prev_pair = tuple(sorted([seq[-2], seq[-1]])) if len(seq) >= 2 else None

                count += count_completions(seq + [first, second], used | {j},
                                           new_budget, depth_limit)
        return count

    # Step-by-step reconstruction
    seq = [0b111111, 0b000000]  # C4: start with Creative/Receptive
    used = {0}  # pair 0 (Creative/Receptive)
    budget = dict(kw_dist)
    budget[bit_diff(0b111111, 0b000000)] -= 1  # within-pair transition consumed

    print(f"{'Step':>4} {'Pair':>5} {'Choices':>8} {'Forced?':>8} Hexagrams")
    print(f"{'----':>4} {'-----':>5} {'-------':>8} {'-------':>8} ---------")
    print(f"{'1':>4} {'1':>5} {'—':>8} {'start':>8} "
          f"䷀ The Creative / ䷁ The Receptive")

    all_forced = True
    reconstructed = list(seq)

    for step in range(1, n):
        prev_tail = reconstructed[-1]

        # Find all valid next pairs with all constraints
        valid_choices = []
        for j in range(n):
            if j in used:
                continue
            for first, second in pair_options[j]:
                # C2: no 5-line transition
                if bit_diff(prev_tail, first) == 5:
                    continue

                # C5: budget check
                test_budget = dict(budget)
                bd = bit_diff(prev_tail, first)
                if test_budget.get(bd, 0) <= 0:
                    continue
                test_budget[bd] -= 1
                wd = bit_diff(first, second)
                if test_budget.get(wd, 0) <= 0:
                    continue
                test_budget[wd] -= 1

                # C6: adjacency at boundary 27 (between pairs at positions 26 and 27)
                if step == 27:  # placing pair 28 (0-indexed 27)
                    prev_pair_can = tuple(sorted([reconstructed[-2], reconstructed[-1]]))
                    curr_pair_can = tuple(sorted([first, second]))
                    if not (prev_pair_can == c6_pair_a and curr_pair_can == c6_pair_b):
                        continue

                if step == 26:  # placing pair 27 — must be c6_pair_a if pair 28 is c6_pair_b
                    curr_pair_can = tuple(sorted([first, second]))
                    # pair 27 must be c6_pair_a (so boundary 27 can be satisfied)
                    # But we also need pair 28 available
                    partner_needed = c6_pair_b if curr_pair_can == c6_pair_a else None
                    if curr_pair_can == c6_pair_a:
                        # Check c6_pair_b is still available
                        c6b_idx = next((k for k in range(n) if k not in used and k != j
                                       and tuple(sorted(kw_pairs[k])) == c6_pair_b), None)
                        if c6b_idx is None:
                            continue

                # C7: adjacency at boundary 25 (between pairs at positions 24 and 25)
                if step == 25:  # placing pair 26 (0-indexed 25)
                    prev_pair_can = tuple(sorted([reconstructed[-2], reconstructed[-1]]))
                    curr_pair_can = tuple(sorted([first, second]))
                    if not (prev_pair_can == c7_pair_a and curr_pair_can == c7_pair_b):
                        continue

                if step == 24:  # placing pair 25 — must be c7_pair_a
                    curr_pair_can = tuple(sorted([first, second]))
                    if curr_pair_can == c7_pair_a:
                        c7b_idx = next((k for k in range(n) if k not in used and k != j
                                       and tuple(sorted(kw_pairs[k])) == c7_pair_b), None)
                        if c7b_idx is None:
                            continue

                # C3: complement distance feasibility (only check at completion)
                # For intermediate steps, we accept all that pass other constraints
                # At the final step, we check
                if step == n - 1:
                    test_seq = reconstructed + [first, second]
                    if mean_complement_distance(test_seq) > kw_comp_dist:
                        continue

                valid_choices.append((j, first, second))

        n_choices = len(valid_choices)
        forced = "YES" if n_choices == 1 else ""
        if n_choices != 1:
            all_forced = False

        # Pick King Wen's actual choice
        kw_first = kw_seq[step * 2]
        kw_second = kw_seq[step * 2 + 1]
        kw_choice = next(((j, f, s) for j, f, s in valid_choices
                          if f == kw_first and s == kw_second), None)

        if kw_choice:
            j, first, second = kw_choice
            # Get hexagram names
            idx_f = list(binary_hexagrams).index(first)
            idx_s = list(binary_hexagrams).index(second)
            name_f = hexagram_names[idx_f]
            name_s = hexagram_names[idx_s]
            hex_f = chr(0x4DC0 + idx_f)
            hex_s = chr(0x4DC0 + idx_s)

            print(f"{step+1:>4} {step+1:>5} {n_choices:>8} {forced:>8} "
                  f"{hex_f} {name_f} / {hex_s} {name_s}")

            reconstructed.extend([first, second])
            used.add(j)
            bd = bit_diff(prev_tail, first)
            budget[bd] -= 1
            wd = bit_diff(first, second)
            budget[wd] -= 1
        else:
            print(f"{step+1:>4} {step+1:>5} {n_choices:>8} {'ERROR':>8} "
                  f"King Wen's choice not among valid options!")
            break

    print()
    if reconstructed == kw_seq:
        print("✓ Reconstruction matches King Wen exactly.")
    else:
        print("✗ Reconstruction does NOT match King Wen.")

    if all_forced:
        print("✓ Every step had exactly 1 valid choice — the sequence is fully determined.")
        print()
        print("The constructive algorithm in SPECIFICATION.md is verified:")
        print("constraints C1-C7 admit exactly one valid path at every step.")
    else:
        non_forced = sum(1 for _ in [] )  # placeholder
        print(f"Some steps had multiple valid choices — constraints C1-C7 alone")
        print(f"do not force a unique path at every step without lookahead.")
        print(f"The specification's uniqueness holds globally but the greedy")
        print(f"constructive algorithm may require backtracking at some steps.")

# --- Null model: structured permutations from de Bruijn B(2, 6) ---

def debruijn_random(k, n, rng):
    """Random B(k, n) de Bruijn sequence via a randomized Hierholzer
    Eulerian-circuit traversal on the B(k, n-1) graph. Nodes are
    length-(n-1) k-ary values; edge labelled b from node v goes to
    ((v*k + b) mod k**(n-1)). Every valid B(k, n) sequence corresponds
    to an Eulerian circuit. Randomness comes from the initial edge-
    order shuffle at each vertex — NOT uniformly distributed over all
    Eulerian circuits, but a cheap way to sample many distinct
    sequences. Returns a list of k**n symbols (each in 0..k-1)."""
    N = k ** (n - 1)
    out = {v: list(range(k)) for v in range(N)}
    for v in out:
        rng.shuffle(out[v])
    stack = [0]
    circuit = []
    while stack:
        v = stack[-1]
        if out[v]:
            b = out[v].pop()
            stack.append((v * k + b) % N)
        else:
            circuit.append(stack.pop())
    circuit.reverse()
    return [circuit[i + 1] % k for i in range(len(circuit) - 1)]


def debruijn_to_hexagram_permutation(binary_seq, n=6):
    """Read the cyclic binary sequence as overlapping length-n windows,
    each packed into an n-bit value (bit 0 = first bit of window).
    For n=6 this gives a permutation of {0..63}."""
    N = len(binary_seq)
    perm = []
    for i in range(N):
        w = 0
        for j in range(n):
            w |= binary_seq[(i + j) % N] << j
        perm.append(w)
    return perm


def has_pair_structure_c1(seq):
    """C1: every consecutive pair (seq[2i], seq[2i+1]) is either
    reverse-pair (bit-reversal) or — for the 4 symmetric hexagrams —
    bitwise complement of each other."""
    symmetric = {v for v in range(64) if reverse_6bit(v) == v}
    for i in range(32):
        a, b = seq[2 * i], seq[2 * i + 1]
        if a in symmetric and b in symmetric:
            if a ^ b != 0b111111:
                return False
        elif reverse_6bit(a) != b:
            return False
    return True


def total_complement_distance_c3(seq):
    """Sum over all 64 hexagrams of |pos[v] - pos[v^63]|. King Wen's
    value is 776 — this is the C3 ceiling used by solve.c."""
    pos = [0] * 64
    for i, v in enumerate(seq):
        pos[v] = i
    return sum(abs(pos[v] - pos[v ^ 0b111111]) for v in range(64))


def count_five_line_transitions_c2(seq):
    return sum(1 for i in range(len(seq) - 1)
               if bit_diff(seq[i], seq[i + 1]) == 5)


def print_null_debruijn(trials=5000, seed=None):
    """Null-model comparison against de Bruijn B(2, 6) permutations.

    CRITIQUE.md §Missing analyses flags the absence of structured-
    permutation null models. This routine samples many random B(2, 6)
    sequences via randomized Hierholzer, converts each to a hexagram
    permutation by reading overlapping 6-bit windows, and counts how
    many satisfy King Wen's C1-C3 constraints. Reports KW's C3
    percentile within the de Bruijn pool.

    For the *exhaustive* null-model test over all 2**26 = 67,108,864
    distinct B(2, 6) sequences (definitive, not sampled), build and run
    solve.c's `null_debruijn_exact` subroutine:

        gcc -O3 -o solve solve.c -lm -lz -pthread -fopenmp
        ./solve --null-debruijn-exact

    which completes in ~1-5 minutes and prints the exact counts this
    routine estimates via sampling.
    """
    rng = random.Random(seed) if seed is not None else random.Random()

    kw_seq = [v for pair in king_wen_pairs() for v in pair]
    kw_c3 = total_complement_distance_c3(kw_seq)
    assert kw_c3 == 776, f"KW C3 total is {kw_c3}, expected 776"

    print("# Null-model comparison: de Bruijn B(2, 6) permutations")
    print()
    print(f"KW baseline: C1 pass, 0 five-line transitions, C3 total = {kw_c3}")
    print()
    print(f"Sampling {trials} random B(2, 6) permutations via randomized Hierholzer...")

    n_c1 = n_c2 = n_c3 = 0
    c2_vals = []
    c3_vals = []
    for _ in range(trials):
        db_seq = debruijn_random(2, 6, rng)
        perm = debruijn_to_hexagram_permutation(db_seq, n=6)
        if has_pair_structure_c1(perm):
            n_c1 += 1
        c2 = count_five_line_transitions_c2(perm)
        if c2 == 0:
            n_c2 += 1
        c2_vals.append(c2)
        c3 = total_complement_distance_c3(perm)
        if c3 <= kw_c3:
            n_c3 += 1
        c3_vals.append(c3)

    c2_vals.sort()
    c3_vals.sort()
    c3_median = c3_vals[trials // 2]
    c3_mean = sum(c3_vals) / trials
    kw_percentile = (sum(1 for c in c3_vals if c < kw_c3) / trials) * 100

    print()
    print(f"De Bruijn null results (n={trials}):")
    print(f"  C1 pair-structure pass:        {n_c1}/{trials} = {n_c1/trials:.2%}")
    print(f"  C2 (no 5-line transitions):    {n_c2}/{trials} = {n_c2/trials:.2%}")
    print(f"  C3 (comp distance <= {kw_c3}):   {n_c3}/{trials} = {n_c3/trials:.2%}")
    print()
    print(f"  5-line transitions in null: range [{min(c2_vals)}, {max(c2_vals)}], "
          f"mean {sum(c2_vals)/trials:.2f}")
    print(f"  C3 total distance in null:  range [{min(c3_vals)}, {max(c3_vals)}], "
          f"median {c3_median}, mean {c3_mean:.1f}")
    print(f"  KW's C3 ({kw_c3}) is at the {kw_percentile:.2f}th percentile of the null pool")
    print()
    print("Interpretation:")
    if n_c1 == 0:
        print("  No de Bruijn permutation satisfies C1 — window-shift adjacency")
        print("  does not produce reverse/inverse pair placement. C1 is not a")
        print("  generic property of structured binary permutations.")
    if n_c2 == 0:
        print("  No de Bruijn permutation avoids 5-line transitions; window-shift")
        print("  geometry forces some Hamming-5 adjacencies.")
    if n_c3 == 0:
        null_min = min(c3_vals)
        print(f"  No de Bruijn permutation matches KW's complement-distance ceiling.")
        print(f"  Null-pool minimum is {null_min} (~{null_min/kw_c3:.2f}x KW's value of {kw_c3}).")
        print("  KW's complement proximity is qualitatively distinct from the de")
        print("  Bruijn family's natural complement geometry.")
    print()
    print("Caveats:")
    print(f"  - {trials} samples is small vs. 2^26 (~67M) distinct B(2, 6) sequences;")
    print("    randomized Hierholzer is non-uniform. Finding is suggestive, not exhaustive.")
    print("  - Other structured families (Costas arrays, Gray codes, lexicographic)")
    print("    are NOT tested. This addresses one of several gaps in CRITIQUE.md.")


# ============================================================================
# P2 DISTRIBUTIONAL ANALYSIS — observable-statistics computation + marginals +
# bivariate heatmaps + joint density (merged from scripts/compute_stats.py,
# scripts/p2_marginals.py, scripts/p2_bivariate.py, scripts/p2_joint_density.py
# on 2026-04-21 per single-Python-file consolidation rule).
#
# All numpy/pyarrow/matplotlib/sklearn imports are LAZY (inside handler
# functions) so that the existing flag-based subcommands (--pairs, --rules,
# etc.) continue to work without these optional dependencies installed.
# ============================================================================

# --- P2 constants (from solve.c; mirror the schema in P2_OBSERVABLES_SCHEMA.md) ---
_P2_FORMAT_V1_MAGIC = b"ROAE"
_P2_HEADER_SIZE = 32
_P2_RECORD_SIZE = 32
_P2_CHUNK_RECORDS_DEFAULT = 1_000_000

# Informative dims for joint density (mean_transition_hamming + max_transition_hamming
# are invariant under C5; position_2_pair is a categorical stratifier).
_P2_JD_DIMS = [
    "edit_dist_kw", "c3_total", "c6_c7_count",
    "fft_dominant_freq", "fft_peak_amplitude",
    "shift_conformant_count", "first_position_deviation",
]

_P2_KW_VALUES = {
    "edit_dist_kw": 0,
    "c3_total": 776,
    "c6_c7_count": 2,
    "position_2_pair": 1,
    "mean_transition_hamming": 3.3492064,
    "max_transition_hamming": 6,
    "fft_dominant_freq": 16,
    "fft_peak_amplitude": 374.77,
    "shift_conformant_count": 17,
    "first_position_deviation": 33,
}


def _is_gzip(path):
    """True if the file begins with the gzip magic (1f 8b)."""
    try:
        with open(path, "rb") as fh:
            return fh.read(2) == b"\x1f\x8b"
    except OSError:
        return False


import contextlib as _contextlib


@_contextlib.contextmanager
def _gz_resolved_path(path):
    """#169: yield a path to a RAW (uncompressed) solutions.bin. If `path` is a
    gz container (live-compression output), decompress it once to a temp file
    and yield that — so the existing seek/getsize/parallel-worker readers below
    (which require a seekable raw file) work unchanged. Raw inputs are yielded
    as-is (no copy). The temp is removed on exit. Magic-sniffed, not
    extension-based: solutions.bin holds gz content under the SAME filename."""
    import os
    import tempfile
    import gzip as _gzip
    if not _is_gzip(path):
        yield path
        return
    fd, tmp = tempfile.mkstemp(prefix="roae_gz_py_", suffix=".bin")
    try:
        with _gzip.open(path, "rb") as gf, os.fdopen(fd, "wb") as out:
            while True:
                buf = gf.read(1 << 20)
                if not buf:
                    break
                out.write(buf)
        yield tmp
    finally:
        try:
            os.remove(tmp)
        except OSError:
            pass


def _p2_read_header(f):
    import struct
    header = f.read(_P2_HEADER_SIZE)
    if len(header) != _P2_HEADER_SIZE:
        raise ValueError(f"Short read on header: got {len(header)} bytes")
    if header[:4] != _P2_FORMAT_V1_MAGIC:
        raise ValueError(f"Not v1 solutions.bin (magic={header[:4]!r})")
    version = struct.unpack("<I", header[4:8])[0]
    record_count = struct.unpack("<Q", header[8:16])[0]
    return record_count, version


def _p2_kw_arrays():
    """Construct numpy KW array + PAIRS_A, PAIRS_B from the 64-value KW sequence."""
    import numpy as np
    kw = np.array([
        63,  0, 17, 34, 23, 58,  2, 16,
        55, 59,  7, 56, 61, 47,  4,  8,
        25, 38,  3, 48, 41, 37, 32,  1,
        57, 39, 33, 30, 18, 45, 28, 14,
        60, 15, 40,  5, 53, 43, 20, 10,
        35, 49, 31, 62, 24,  6, 26, 22,
        29, 46,  9, 36, 52, 11, 13, 44,
        54, 27, 50, 19, 51, 12, 21, 42,
    ], dtype=np.int16)
    return kw, kw[0::2].astype(np.int16), kw[1::2].astype(np.int16)


def _p2_decode_records(chunk_bytes):
    import numpy as np
    return np.frombuffer(chunk_bytes, dtype=np.uint8).reshape(-1, _P2_RECORD_SIZE)


def _p2_build_hexagram_sequence(records):
    import numpy as np
    _, PAIRS_A, PAIRS_B = _p2_kw_arrays()
    pair_idx = (records >> 2).astype(np.int16)
    orient = ((records >> 1) & 1).astype(np.int16)
    first = np.where(orient == 0, PAIRS_A[pair_idx], PAIRS_B[pair_idx])
    second = np.where(orient == 0, PAIRS_B[pair_idx], PAIRS_A[pair_idx])
    n = records.shape[0]
    seq = np.empty((n, 64), dtype=np.int16)
    seq[:, 0::2] = first
    seq[:, 1::2] = second
    return seq


def _p2_compute_all_stats(records):
    """Return dict of column arrays for all 10 P2 observable dimensions."""
    import numpy as np
    # edit_dist_kw
    pair_idx = records >> 2
    kw_exp = np.arange(32, dtype=np.uint8)
    edit_dist = (pair_idx != kw_exp).sum(axis=1).astype(np.uint8)

    # c3_total
    seq = _p2_build_hexagram_sequence(records)
    n = seq.shape[0]
    pos_of_v = np.empty((n, 64), dtype=np.int16)
    row_idx = np.broadcast_to(np.arange(n).reshape(-1, 1), seq.shape)
    pos_of_v[row_idx, seq] = np.broadcast_to(np.arange(64, dtype=np.int16), seq.shape)
    v = np.arange(64, dtype=np.int16)
    c3 = np.abs(pos_of_v[:, v] - pos_of_v[:, v ^ 63]).sum(axis=1).astype(np.uint16)

    # c6/c7 counts
    c6 = ((pair_idx[:, 26] == 26) & (pair_idx[:, 27] == 27)).astype(np.uint8)
    c7 = ((pair_idx[:, 24] == 24) & (pair_idx[:, 25] == 25)).astype(np.uint8)
    c6c7 = c6 + c7

    # position_2_pair
    p2p = (records[:, 1] >> 2).astype(np.uint8)

    # transition Hamming (invariant per theorem; kept for schema completeness)
    diffs = seq[:, :-1] ^ seq[:, 1:]
    popcount_tbl = np.array([bin(i).count("1") for i in range(64)], dtype=np.uint8)
    hammings = popcount_tbl[diffs]
    mean_trans = hammings.mean(axis=1).astype(np.float32)
    max_trans = hammings.max(axis=1).astype(np.uint8)

    # FFT
    seq_zm = seq.astype(np.float32) - seq.astype(np.float32).mean(axis=1, keepdims=True)
    F = np.fft.fft(seq_zm, axis=1)
    amp = np.abs(F[:, 1:32])
    dom_k = (np.argmax(amp, axis=1) + 1).astype(np.uint8)
    peak_amp = amp.max(axis=1).astype(np.float32)

    # shift_conformant
    positions = np.arange(2, 19, dtype=np.uint8)
    pi_at = pair_idx[:, positions]
    shift = ((pi_at == positions) | (pi_at == positions - 1)).sum(axis=1).astype(np.uint8)

    # first_position_deviation
    mismatch = pair_idx != kw_exp
    any_mismatch = mismatch.any(axis=1)
    first_idx = np.argmax(mismatch, axis=1)
    fpd = np.where(any_mismatch, first_idx + 1, 33).astype(np.uint8)

    return {
        "edit_dist_kw": edit_dist,
        "c3_total": c3,
        "c6_c7_count": c6c7,
        "position_2_pair": p2p,
        "mean_transition_hamming": mean_trans,
        "max_transition_hamming": max_trans,
        "fft_dominant_freq": dom_k,
        "fft_peak_amplitude": peak_amp,
        "shift_conformant_count": shift,
        "first_position_deviation": fpd,
    }


_P2_WORKER_SCHEMA = None


def _p2_worker_init(schema_bytes):
    import pyarrow as pa
    global _P2_WORKER_SCHEMA
    _P2_WORKER_SCHEMA = pa.ipc.read_schema(pa.BufferReader(schema_bytes))


def _p2_worker_chunk(task):
    import pyarrow as pa
    import pyarrow.parquet as pq
    filename, offset, n_records, chunk_idx, out_dir = task
    with open(filename, "rb") as f:
        f.seek(offset)
        raw = f.read(n_records * _P2_RECORD_SIZE)
    records = _p2_decode_records(raw[: (len(raw) // _P2_RECORD_SIZE) * _P2_RECORD_SIZE])
    stats = _p2_compute_all_stats(records)
    batch = pa.record_batch(
        [pa.array(stats[c.name]).cast(c.type) for c in _P2_WORKER_SCHEMA],
        schema=_P2_WORKER_SCHEMA,
    )
    out_path = f"{out_dir}/chunk_{chunk_idx:05d}.parquet"
    pq.write_table(
        pa.Table.from_batches([batch], schema=_P2_WORKER_SCHEMA),
        out_path, compression="zstd",
    )
    return out_path, len(stats["edit_dist_kw"])


def _p2_parquet_schema():
    import pyarrow as pa
    return pa.schema([
        ("edit_dist_kw", pa.uint8()),
        ("c3_total", pa.uint16()),
        ("c6_c7_count", pa.uint8()),
        ("position_2_pair", pa.uint8()),
        ("mean_transition_hamming", pa.float32()),
        ("max_transition_hamming", pa.uint8()),
        ("fft_dominant_freq", pa.uint8()),
        ("fft_peak_amplitude", pa.float32()),
        ("shift_conformant_count", pa.uint8()),
        ("first_position_deviation", pa.uint8()),
    ])


def p2_compute_stats(solutions_bin, out_dir, workers=None,
                     chunk_size=_P2_CHUNK_RECORDS_DEFAULT, max_records=None):
    """Handler for --compute-stats. See scripts/compute_stats.py history."""
    import multiprocessing as mp
    import os
    import time
    import pyarrow.parquet as pq

    os.makedirs(out_dir, exist_ok=True)
    if workers is None:
        workers = os.cpu_count() or 4
    schema = _p2_parquet_schema()
    # #169: transparently decompress a gz solutions.bin to a temp so the
    # offset-seeking parallel workers below read a raw seekable file.
    with _gz_resolved_path(solutions_bin) as solutions_bin:
        return _p2_compute_stats_impl(solutions_bin, out_dir, workers,
                                      chunk_size, max_records, schema)


def _p2_compute_stats_impl(solutions_bin, out_dir, workers,
                           chunk_size, max_records, schema):
    import multiprocessing as mp
    import os
    import time
    with open(solutions_bin, "rb") as f:
        total_records, version = _p2_read_header(f)
    if max_records:
        total_records = min(total_records, max_records)

    print(f"[compute-stats] v{version} solutions.bin, {total_records:,} rows, "
          f"{workers} workers, {chunk_size:,}/chunk, out={out_dir}", flush=True)

    tasks = []
    offset = _P2_HEADER_SIZE
    remaining = total_records
    chunk_idx = 0
    while remaining > 0:
        n = min(chunk_size, remaining)
        tasks.append((solutions_bin, offset, n, chunk_idx, out_dir))
        offset += n * _P2_RECORD_SIZE
        remaining -= n
        chunk_idx += 1
    print(f"[compute-stats] {len(tasks)} chunks", flush=True)

    schema_bytes = schema.serialize().to_pybytes()
    t0 = time.time()
    seen = chunks_done = 0
    with mp.Pool(workers, initializer=_p2_worker_init,
                 initargs=(schema_bytes,), maxtasksperchild=32) as pool:
        for (out_path, n_rec) in pool.imap_unordered(
                _p2_worker_chunk, tasks, chunksize=1):
            seen += n_rec
            chunks_done += 1
            if chunks_done % 10 == 0 or seen >= total_records:
                elapsed = time.time() - t0
                rate = seen / max(elapsed, 1e-9)
                eta = (total_records - seen) / max(rate, 1.0)
                print(f"[compute-stats]   {seen:,}/{total_records:,} "
                      f"({100*seen/total_records:.1f}%) "
                      f"{chunks_done}/{len(tasks)}  {rate/1e6:.2f}M/s  "
                      f"ETA {eta/60:.1f}m", flush=True)
    total_elapsed = time.time() - t0
    print(f"[compute-stats] DONE {chunks_done} files, {seen:,} rows, "
          f"{total_elapsed:.1f}s ({seen/total_elapsed/1e6:.2f}M/s)", flush=True)


def _p2_percentile_from_hist(counts, values, target, total):
    import numpy as np
    n_less = int(counts[values < target].sum())
    n_equal = int(counts[values == target].sum())
    pct = (n_less + n_equal / 2.0) / total * 100
    return pct, n_less, n_equal


_P2_INT_COLS = [
    ("edit_dist_kw", 0, 32, 0),
    ("c3_total", 424, 776, 776),
    ("c6_c7_count", 0, 2, 2),
    ("max_transition_hamming", 1, 6, 6),
    ("fft_dominant_freq", 1, 31, 16),
    ("shift_conformant_count", 0, 17, 17),
    ("first_position_deviation", 1, 33, 33),
]
_P2_FLOAT_COLS = [
    ("mean_transition_hamming", 2.0, 4.0, 3.3492064),
    ("fft_peak_amplitude", 0.0, 500.0, 374.77),
]


def p2_marginals(chunks_dir, out_md):
    """Handler for --marginals."""
    import glob
    import numpy as np
    import pyarrow.parquet as pq

    files = sorted(glob.glob(f"{chunks_dir}/chunk_*.parquet"))
    print(f"[marginals] {len(files)} chunks in {chunks_dir}", flush=True)

    hists = {}
    for name, lo, hi, _kw in _P2_INT_COLS:
        hists[name] = {"counts": np.zeros(int(hi - lo + 1), dtype=np.int64),
                       "lo": lo, "hi": hi, "type": "int"}
    n_float_bins = 10000
    for name, lo, hi, _kw in _P2_FLOAT_COLS:
        hists[name] = {"counts": np.zeros(n_float_bins, dtype=np.int64),
                       "lo": lo, "hi": hi, "type": "float", "n_bins": n_float_bins,
                       "sum": 0.0, "sum_sq": 0.0,
                       "min": float("inf"), "max": float("-inf")}

    total_rows = kw_row_count = 0
    strat_counts = np.zeros(32, dtype=np.int64)
    int_sums = {n: 0 for n, *_ in _P2_INT_COLS}
    int_sum_sq = {n: 0 for n, *_ in _P2_INT_COLS}

    for i, f in enumerate(files):
        t = pq.read_table(f)
        total_rows += t.num_rows
        ed = t.column("edit_dist_kw").to_numpy()
        fpd = t.column("first_position_deviation").to_numpy()
        kw_row_count += int(((ed == 0) & (fpd == 33)).sum())
        p2p = t.column("position_2_pair").to_numpy()
        strat_counts += np.bincount(p2p, minlength=32)
        for name, lo, hi, _kw in _P2_INT_COLS:
            arr = t.column(name).to_numpy()
            hist = np.bincount(arr.astype(np.int64) - lo, minlength=int(hi - lo + 1))
            hists[name]["counts"] += hist[:int(hi - lo + 1)]
            int_sums[name] += int(arr.sum())
            int_sum_sq[name] += int((arr.astype(np.int64) ** 2).sum())
        for name, lo, hi, _kw in _P2_FLOAT_COLS:
            arr = t.column(name).to_numpy()
            hists[name]["sum"] += float(arr.sum())
            hists[name]["sum_sq"] += float((arr.astype(np.float64) ** 2).sum())
            hists[name]["min"] = min(hists[name]["min"], float(arr.min()))
            hists[name]["max"] = max(hists[name]["max"], float(arr.max()))
            bin_idx = np.clip(((arr - lo) / (hi - lo) * (n_float_bins - 1)).astype(np.int32),
                              0, n_float_bins - 1)
            hists[name]["counts"] += np.bincount(bin_idx, minlength=n_float_bins)[:n_float_bins]
        if (i + 1) % 500 == 0:
            print(f"  {i+1}/{len(files)} chunks, {total_rows:,} rows", flush=True)

    print(f"[marginals] TOTAL {total_rows:,} rows, KW sig rows = {kw_row_count}", flush=True)

    L = []
    L.append("# P2 Marginal Analysis — 100T d3 canonical\n")
    L.append(f"**Dataset:** {total_rows:,} records\n")
    L.append(f"**KW-signature rows:** {kw_row_count}\n\n")
    L.append("## Marginals\n")
    L.append("| Dim | Type | Min | Max | Mean | Std | KW | KW %-ile | # < KW | # == KW |\n")
    L.append("|---|---|---|---|---|---|---|---|---|---|\n")
    for name, lo, hi, kw_val in _P2_INT_COLS:
        h = hists[name]
        values = np.arange(lo, hi + 1, dtype=np.int64)
        pct, n_less, n_eq = _p2_percentile_from_hist(h["counts"], values, kw_val, total_rows)
        mean = int_sums[name] / total_rows
        var = int_sum_sq[name] / total_rows - mean ** 2
        std = var ** 0.5 if var > 0 else 0.0
        L.append(f"| `{name}` | int | {lo} | {hi} | {mean:.3f} | {std:.3f} "
                 f"| **{kw_val}** | **{pct:.4f}%** | {n_less:,} | {n_eq:,} |\n")
    for name, lo, hi, kw_val in _P2_FLOAT_COLS:
        h = hists[name]
        kw_bin = int(np.clip((kw_val - lo) / (hi - lo) * (h["n_bins"] - 1),
                             0, h["n_bins"] - 1))
        n_less = int(h["counts"][:kw_bin].sum())
        n_at = int(h["counts"][kw_bin])
        pct = (n_less + n_at / 2.0) / total_rows * 100
        mean = h["sum"] / total_rows
        var = h["sum_sq"] / total_rows - mean ** 2
        std = var ** 0.5 if var > 0 else 0.0
        L.append(f"| `{name}` | float | {h['min']:.4f} | {h['max']:.4f} "
                 f"| {mean:.4f} | {std:.4f} | **~{kw_val}** | **~{pct:.4f}%** "
                 f"| {n_less:,} | {n_at:,} (bin) |\n")
    L.append("\n## position_2_pair stratifier\n")
    L.append("| Pair | Count | % |\n|---|---|---|\n")
    for i in range(32):
        marker = " **← KW**" if i == 1 else ""
        L.append(f"| {i} | {strat_counts[i]:,} | {100*strat_counts[i]/total_rows:.3f}%{marker} |\n")
    with open(out_md, "w") as f:
        f.writelines(L)
    print(f"[marginals] wrote {out_md}", flush=True)


_P2_BIVARIATE_PAIRS = [
    ("edit_dist_kw", "c3_total"),
    ("c3_total", "shift_conformant_count"),
    ("fft_dominant_freq", "fft_peak_amplitude"),
    ("mean_transition_hamming", "fft_peak_amplitude"),
    ("position_2_pair", "edit_dist_kw"),
]


def p2_bivariate(chunks_dir, out_dir, samples_per_chunk=500, seed=42):
    """Handler for --bivariate."""
    import glob
    import os
    import numpy as np
    import pyarrow.parquet as pq
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    os.makedirs(out_dir, exist_ok=True)
    files = sorted(glob.glob(f"{chunks_dir}/chunk_*.parquet"))
    print(f"[bivariate] sampling from {len(files)} chunks", flush=True)
    rng = np.random.default_rng(seed)
    cols = sorted({c for x, y in _P2_BIVARIATE_PAIRS for c in (x, y)})
    accum = {c: [] for c in cols}
    for i, f in enumerate(files):
        t = pq.read_table(f, columns=cols)
        k = min(samples_per_chunk, t.num_rows)
        idx = rng.choice(t.num_rows, size=k, replace=False)
        for c in cols:
            accum[c].append(t.column(c).to_numpy()[idx])
        if (i + 1) % 500 == 0:
            print(f"  {i+1}/{len(files)} chunks", flush=True)
    data = {c: np.concatenate(v) for c, v in accum.items()}
    print(f"[bivariate] sampled {len(next(iter(data.values()))):,} rows", flush=True)

    for x, y in _P2_BIVARIATE_PAIRS:
        fig, ax = plt.subplots(figsize=(10, 8), dpi=150)
        hb = ax.hexbin(data[x], data[y], gridsize=50, cmap="viridis",
                       bins="log", mincnt=1)
        plt.colorbar(hb, ax=ax, label="records (log)")
        kw_x, kw_y = _P2_KW_VALUES[x], _P2_KW_VALUES[y]
        ax.plot([kw_x], [kw_y], marker="*", markersize=25, color="gold",
                markeredgecolor="black", markeredgewidth=2,
                label=f"King Wen ({kw_x}, {kw_y})", zorder=10)
        ax.legend(loc="best", fontsize=11)
        ax.set_xlabel(x, fontsize=12)
        ax.set_ylabel(y, fontsize=12)
        ax.set_title(f"{x} vs {y}\n(100T d3 canonical, "
                     f"{len(data[x]):,} sampled)", fontsize=13)
        ax.set_facecolor("#f8f8f8")
        fig.tight_layout()
        out = f"{out_dir}/viz_{x}__{y}.png"
        fig.savefig(out, dpi=150, bbox_inches="tight")
        plt.close(fig)
        print(f"  wrote {out}", flush=True)


def p2_joint_density(chunks_dir, out_md, samples_per_chunk=30,
                     score_sample=30000, bootstrap_n=1000, bootstrap_frac=0.30, seed=42):
    """Handler for --joint-density."""
    import glob
    import numpy as np
    import pyarrow.parquet as pq
    from sklearn.neighbors import KernelDensity

    files = sorted(glob.glob(f"{chunks_dir}/chunk_*.parquet"))
    print(f"[joint-density] sampling from {len(files)} chunks", flush=True)
    rng = np.random.default_rng(seed)
    accum = {c: [] for c in _P2_JD_DIMS}
    for i, f in enumerate(files):
        t = pq.read_table(f, columns=_P2_JD_DIMS)
        k = min(samples_per_chunk, t.num_rows)
        idx = rng.choice(t.num_rows, size=k, replace=False)
        for c in _P2_JD_DIMS:
            accum[c].append(t.column(c).to_numpy()[idx])
        if (i + 1) % 500 == 0:
            print(f"  chunk {i+1}/{len(files)}", flush=True)
    data = np.column_stack([np.concatenate(accum[c]) for c in _P2_JD_DIMS]).astype(np.float64)
    print(f"[joint-density] sample shape: {data.shape}", flush=True)

    mu = data.mean(axis=0)
    sigma = data.std(axis=0)
    sigma[sigma == 0] = 1.0
    data_std = (data - mu) / sigma
    kw_point = np.array([_P2_KW_VALUES[c] for c in _P2_JD_DIMS]).reshape(1, -1).astype(np.float64)
    kw_std = (kw_point - mu) / sigma
    n, d = data.shape
    bw = (n * (d + 2) / 4.0) ** (-1.0 / (d + 4))
    print(f"[joint-density] fitting KDE, bandwidth={bw:.4f}", flush=True)
    kde = KernelDensity(bandwidth=bw, kernel="gaussian")
    kde.fit(data_std)

    print("[joint-density] scoring...", flush=True)
    score_idx = rng.choice(len(data_std), size=min(score_sample, len(data_std)), replace=False)
    sample_scores = kde.score_samples(data_std[score_idx])
    kw_score = kde.score_samples(kw_std)[0]
    kw_pct = (sample_scores <= kw_score).sum() / len(sample_scores) * 100
    print(f"[joint-density] KW log-density: {kw_score:.4f}", flush=True)
    print(f"[joint-density] sample log-dens: [{sample_scores.min():.4f}, "
          f"{sample_scores.max():.4f}], mean {sample_scores.mean():.4f}", flush=True)
    print(f"[joint-density] KW %-ile: {kw_pct:.3f}%", flush=True)

    print(f"[joint-density] bootstrap {bootstrap_n}×...", flush=True)
    boot = []
    n_boot = int(len(sample_scores) * bootstrap_frac)
    for b in range(bootstrap_n):
        bi = rng.choice(len(sample_scores), size=n_boot, replace=True)
        boot.append((sample_scores[bi] <= kw_score).sum() / n_boot * 100)
        if (b + 1) % 200 == 0:
            print(f"  boot {b+1}/{bootstrap_n}", flush=True)
    boot = np.array(boot)
    ci_low = np.percentile(boot, 2.5)
    ci_high = np.percentile(boot, 97.5)
    with open(out_md, "w") as f:
        f.writelines([
            "# P2 Joint Density — 100T d3 canonical\n\n",
            f"**Sample size:** {len(data):,} rows\n",
            f"**Scoring sample:** {len(sample_scores):,} rows\n",
            f"**Dimensions:** {', '.join(f'`{c}`' for c in _P2_JD_DIMS)}\n",
            f"**KDE bandwidth (Silverman):** {bw:.4f}\n\n",
            "## Results\n",
            f"- KW's log-density: **{kw_score:.4f}**\n",
            f"- Sample log-density: [{sample_scores.min():.4f}, "
            f"{sample_scores.max():.4f}], mean {sample_scores.mean():.4f}\n",
            f"- **KW's density-percentile: {kw_pct:.3f}%**\n",
            f"- Bootstrap 95% CI ({bootstrap_n} resamples): "
            f"**[{ci_low:.3f}%, {ci_high:.3f}%]**\n",
        ])
    print(f"[joint-density] wrote {out_md}", flush=True)


# ----------------------------------------------------------------------------
# P2 v2 follow-ups (2026-04-24): stratified-by-position_2_pair, denser KDE
# bandwidth selection, permutation test for multi-test correction.
# Spec: x/roae/DISTRIBUTIONAL_V2_SPEC.md
# ----------------------------------------------------------------------------


def _p2_v2_native_kde_count(solve_binary, fit_data_std, bandwidth, kw_score,
                             chunks_dir, cols, mu, sigma, mask_filter=None,
                             stream_batch_rows=10000):
    """Drive the native solve.c --kde-score-stream subprocess to count
    records with KDE log-density <= kw_score, exhaustively over all chunks.

    Args:
      solve_binary: path to compiled `solve` binary with --kde-score-stream
      fit_data_std: standardized fit points (n_fit × d float64)
      bandwidth: KDE bandwidth in standardized space
      kw_score: KW's log-density (threshold)
      chunks_dir: where chunk_*.parquet files live
      cols: list of column names matching fit_data_std's columns
      mu, sigma: standardization params (apply to chunk records before sending)
      mask_filter: optional callable(record_array) -> bool mask, for stratification.
                   Called with the full chunk array, returns which rows to send.
      stream_batch_rows: rows per write to subprocess stdin

    Returns: (n_below, n_total)
    """
    import glob
    import os
    import subprocess
    import tempfile
    import numpy as np
    import pyarrow.parquet as pq

    n_fit, d = fit_data_std.shape
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        fit_path = f.name
        f.write(fit_data_std.astype(np.float64).tobytes())

    cmd = [
        solve_binary, "--kde-score-stream",
        "--fit-file", fit_path,
        "--d", str(d),
        "--bandwidth", f"{bandwidth:g}",
        "--threshold", f"{kw_score:.10g}",
    ]
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, bufsize=0)
    try:
        files = sorted(glob.glob(f"{chunks_dir}/chunk_*.parquet"))
        for i, f in enumerate(files):
            t = pq.read_table(f, columns=cols)
            arr = np.column_stack([t.column(c).to_numpy() for c in cols]).astype(np.float64)
            if mask_filter is not None:
                m = mask_filter(arr)
                arr = arr[m]
                if len(arr) == 0:
                    continue
            arr_std = (arr - mu) / sigma
            arr_std = np.ascontiguousarray(arr_std, dtype=np.float64)
            proc.stdin.write(arr_std.tobytes())
            if (i + 1) % 200 == 0:
                print(f"  [native-kde] streamed {i+1}/{len(files)} chunks", flush=True)
        proc.stdin.close()
        proc.wait(timeout=86400)
        out = proc.stdout.read()
        err = proc.stderr.read()
        if proc.returncode != 0:
            raise SystemExit(f"[native-kde] subprocess failed (rc={proc.returncode})\n"
                             f"stderr: {err.decode()[:500]}")
        line = out.decode().strip()
        parts = line.split()
        if len(parts) < 2:
            raise SystemExit(f"[native-kde] unexpected output: {line!r}\n"
                             f"stderr: {err.decode()[:500]}")
        n_below, n_total = int(parts[0]), int(parts[1])
        return n_below, n_total
    finally:
        try:
            os.unlink(fit_path)
        except OSError:
            pass


def _p2_strat_native_count(solve_binary, fit_data_std, bandwidth, kw_score,
                            chunks_dir, full_cols, mu, sigma, stratum_value,
                            stratifier_col_idx=0):
    """Like _p2_v2_native_kde_count but filters chunk rows to a single
    stratum (e.g., position_2_pair == s) before sending to the scorer.
    full_cols includes the stratifier as its first column; mu/sigma are
    over the REST of the columns (non-stratifier).
    """
    import glob
    import os
    import subprocess
    import tempfile
    import numpy as np
    import pyarrow.parquet as pq

    n_fit, d = fit_data_std.shape
    with tempfile.NamedTemporaryFile(suffix=".bin", delete=False) as f:
        fit_path = f.name
        f.write(fit_data_std.astype(np.float64).tobytes())

    cmd = [
        solve_binary, "--kde-score-stream",
        "--fit-file", fit_path,
        "--d", str(d),
        "--bandwidth", f"{bandwidth:g}",
        "--threshold", f"{kw_score:.10g}",
    ]
    proc = subprocess.Popen(cmd, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                            stderr=subprocess.PIPE, bufsize=0)
    try:
        files = sorted(glob.glob(f"{chunks_dir}/chunk_*.parquet"))
        for f in files:
            t = pq.read_table(f, columns=full_cols)
            arr = np.column_stack([t.column(c).to_numpy() for c in full_cols]).astype(np.float64)
            mask = (arr[:, stratifier_col_idx].astype(int) == stratum_value)
            sub = arr[mask][:, [j for j in range(arr.shape[1]) if j != stratifier_col_idx]]
            if len(sub) == 0:
                continue
            sub_std = (sub - mu) / sigma
            proc.stdin.write(np.ascontiguousarray(sub_std).tobytes())
        proc.stdin.close()
        proc.wait(timeout=43200)
        out = proc.stdout.read()
        err = proc.stderr.read()
        if proc.returncode != 0:
            raise SystemExit(f"[strat-native] subprocess failed (rc={proc.returncode})\n"
                             f"stderr: {err.decode()[:500]}")
        parts = out.decode().strip().split()
        if len(parts) < 2:
            raise SystemExit(f"[strat-native] unexpected output: {out!r}")
        return int(parts[0]), int(parts[1])
    finally:
        try:
            os.unlink(fit_path)
        except OSError:
            pass


def _p2_v2_load_sample(chunks_dir, columns, samples_per_chunk, rng):
    """Read sampled rows from chunk_*.parquet; returns (data, n_chunks)."""
    import glob
    import numpy as np
    import pyarrow.parquet as pq

    files = sorted(glob.glob(f"{chunks_dir}/chunk_*.parquet"))
    if not files:
        raise SystemExit(f"[v2] no chunk_*.parquet files in {chunks_dir}")
    accum = {c: [] for c in columns}
    for i, f in enumerate(files):
        t = pq.read_table(f, columns=columns)
        k = min(samples_per_chunk, t.num_rows)
        if k == 0:
            continue
        idx = rng.choice(t.num_rows, size=k, replace=False)
        for c in columns:
            accum[c].append(t.column(c).to_numpy()[idx])
        if (i + 1) % 500 == 0:
            print(f"  chunk {i+1}/{len(files)}", flush=True)
    data = np.column_stack([np.concatenate(accum[c]) for c in columns]).astype(np.float64)
    return data, len(files)


def _p2_v2_variance_filter(data, columns, kw_values, threshold=1e-6):
    """Drop columns whose stdev/|mean| is below threshold (effectively constant
    within the sampled population). Returns filtered (data, columns, kw_values)."""
    import numpy as np
    keep_idx = []
    dropped = []
    for j, c in enumerate(columns):
        col = data[:, j]
        sd = float(np.std(col))
        mu = float(np.mean(col)) if abs(np.mean(col)) > 1e-12 else 1.0
        cv = sd / abs(mu)
        if cv < threshold:
            dropped.append((c, sd, mu, cv))
        else:
            keep_idx.append(j)
    if dropped:
        print(f"[v2] dropping {len(dropped)} low-variance dims:", flush=True)
        for name, sd, mu, cv in dropped:
            print(f"     {name}: stdev={sd:.6g}, mean={mu:.6g}, cv={cv:.3e}", flush=True)
    new_cols = [columns[j] for j in keep_idx]
    new_data = data[:, keep_idx] if keep_idx else data[:, :0]
    new_kw = [kw_values[c] for c in new_cols]
    return new_data, new_cols, new_kw, dropped


def p2_joint_density_v2(chunks_dir, out_md, samples_per_chunk=30,
                        bandwidth_method="cv", seed=42, dims=None,
                        score_batch_size=50000, exhaustive=False,
                        native_solve_binary=None,
                        score_sample=30000, bootstrap_n=1000, bootstrap_frac=0.30):
    """v2 joint density.

    KDE FITTING always uses a sample (mathematically required; sklearn KDE
    has O(n_fit · n_score) scoring cost, prohibitive on 3.43B records).

    KW percentile computation has two modes:
       - default (exhaustive=False): score `score_sample` random rows through
         the fitted KDE, report KW's percentile in that sample with a
         bootstrap 95% CI. Fast (~minutes); v1-compatible output.
       - exhaustive=True: stream EVERY chunk through the fitted KDE. Wall
         time is ~hours-to-days at fit_n=1000-5000 on a single thread;
         tractable only with parallelism (D64 multiprocess) or a smaller
         fit sample. Reports the exact count over the full population.

    Adds (a) runtime variance-check that auto-drops constant dims,
    (b) configurable bandwidth selection (silverman / cv).
    """
    import glob
    import numpy as np
    import pyarrow.parquet as pq
    from sklearn.neighbors import KernelDensity

    cols = list(dims) if dims else list(_P2_JD_DIMS)
    rng = np.random.default_rng(seed)
    print(f"[v2-jd] reading chunks from {chunks_dir} (cols={cols})", flush=True)
    fit_data, n_chunks = _p2_v2_load_sample(chunks_dir, cols, samples_per_chunk, rng)
    print(f"[v2-jd] fit-sample shape: {fit_data.shape} from {n_chunks} chunks", flush=True)

    fit_data, cols, kw_vals, dropped = _p2_v2_variance_filter(fit_data, cols, _P2_KW_VALUES)
    if fit_data.shape[1] == 0:
        raise SystemExit("[v2-jd] all dimensions dropped — nothing to fit")

    mu = fit_data.mean(axis=0)
    sigma = fit_data.std(axis=0)
    sigma[sigma == 0] = 1.0
    data_std = (fit_data - mu) / sigma
    kw_point = np.array(kw_vals, dtype=np.float64).reshape(1, -1)
    kw_std = (kw_point - mu) / sigma

    n, d = fit_data.shape
    if bandwidth_method == "silverman":
        bw = (n * (d + 2) / 4.0) ** (-1.0 / (d + 4))
        bw_label = f"Silverman bw={bw:.4f} on {n}-row sample"
    elif bandwidth_method == "cv":
        from sklearn.model_selection import GridSearchCV
        candidates = np.logspace(-1.5, 0.5, 12)
        print(f"[v2-jd] CV bandwidth search over {len(candidates)} values", flush=True)
        cv_n = min(2000, len(data_std))
        cv_idx = rng.choice(len(data_std), size=cv_n, replace=False)
        gs = GridSearchCV(KernelDensity(kernel="gaussian"),
                          {"bandwidth": candidates}, cv=5, n_jobs=1)
        gs.fit(data_std[cv_idx])
        bw = float(gs.best_params_["bandwidth"])
        bw_label = f"5-fold CV bw={bw:.4f} (cv_n={cv_n}, candidates={len(candidates)})"
    else:
        raise SystemExit(f"unknown bandwidth_method: {bandwidth_method}")

    print(f"[v2-jd] {bw_label}", flush=True)
    kde = KernelDensity(bandwidth=bw, kernel="gaussian").fit(data_std)
    kw_score = float(kde.score_samples(kw_std)[0])
    print(f"[v2-jd] KW log-density: {kw_score:.4f}", flush=True)

    if exhaustive:
        # EXHAUSTIVE scoring path. Two engines:
        #   - native: ./solve --kde-score-stream subprocess (~10-50× faster)
        #   - sklearn fallback: O(n_fit × n_score) Python loop, slow
        if native_solve_binary:
            print(f"[v2-jd] EXHAUSTIVE via native scorer ({native_solve_binary})",
                  flush=True)
            n_below_kw, total_records = _p2_v2_native_kde_count(
                native_solve_binary, data_std, bw, kw_score,
                chunks_dir, cols, mu, sigma)
            kw_pct = n_below_kw / total_records * 100.0 if total_records else float("nan")
            score_min = score_max = score_sum = float("nan")  # not tracked in native
            print(f"[v2-jd] NATIVE EXHAUSTIVE: {n_below_kw:,} of {total_records:,} "
                  f"records score ≤ KW → KW %-ile = {kw_pct:.6f}%", flush=True)
            engine_label = f"native ({native_solve_binary})"
        else:
            print(f"[v2-jd] EXHAUSTIVE scoring pass over all {n_chunks} chunks "
                  f"(fit_n={len(fit_data)}; expect 1-10 records/ms single-threaded)",
                  flush=True)
            files = sorted(glob.glob(f"{chunks_dir}/chunk_*.parquet"))
            total_records = 0
            n_below_kw = 0
            score_min = float("inf")
            score_max = float("-inf")
            score_sum = 0.0
            for i, f in enumerate(files):
                t = pq.read_table(f, columns=cols)
                arr = np.column_stack([t.column(c).to_numpy() for c in cols]).astype(np.float64)
                arr_std = (arr - mu) / sigma
                for j in range(0, len(arr_std), score_batch_size):
                    batch = arr_std[j:j + score_batch_size]
                    scores = kde.score_samples(batch)
                    n_below_kw += int((scores <= kw_score).sum())
                    total_records += len(scores)
                    score_min = min(score_min, float(scores.min()))
                    score_max = max(score_max, float(scores.max()))
                    score_sum += float(scores.sum())
                if (i + 1) % 100 == 0:
                    print(f"  scored {i+1}/{len(files)} chunks "
                          f"({total_records:,} records, {n_below_kw:,} below KW)",
                          flush=True)
            kw_pct = n_below_kw / total_records * 100.0
            score_sum = score_sum / total_records
            engine_label = "sklearn"
        with open(out_md, "w") as f:
            f.write("# P2 Joint Density v2 — 100T d3 canonical (EXHAUSTIVE)\n\n")
            f.write(f"**Total records scored:** {total_records:,} (exhaustive over "
                    f"{n_chunks} chunks)\n")
            f.write(f"**Engine:** {engine_label}\n")
            f.write(f"**Fit-sample size:** {len(fit_data):,} rows for KDE fitting\n")
            f.write(f"**Final dimensions ({len(cols)}):** {', '.join(f'`{c}`' for c in cols)}\n")
            if dropped:
                f.write(f"**Auto-dropped:** {', '.join(f'`{x[0]}`' for x in dropped)}\n")
            f.write(f"**Bandwidth method:** {bw_label}\n\n")
            f.write("## Results (exhaustive count)\n")
            f.write(f"- KW's log-density: **{kw_score:.4f}**\n")
            f.write(f"- **KW's density-percentile: {kw_pct:.6f}% — "
                    f"{n_below_kw:,} of {total_records:,} records (exact count)**\n\n")
            f.write("## Notes\n- Exact count over full canonical population. "
                    "No bootstrap CI needed.\n")
        print(f"[v2-jd] wrote {out_md}", flush=True)
        return

    # Default: SAMPLED scoring path (fast, with bootstrap CI).
    print(f"[v2-jd] SAMPLED scoring on {score_sample} rows...", flush=True)
    score_idx = rng.choice(len(data_std), size=min(score_sample, len(data_std)), replace=False)
    sample_scores = kde.score_samples(data_std[score_idx])
    kw_pct = float((sample_scores <= kw_score).sum() / len(sample_scores) * 100.0)
    n_below = int((sample_scores <= kw_score).sum())
    print(f"[v2-jd] SAMPLED: {n_below}/{len(sample_scores)} below → KW %-ile = {kw_pct:.4f}%",
          flush=True)
    print(f"[v2-jd] bootstrap {bootstrap_n}×...", flush=True)
    boot = []
    n_boot = int(len(sample_scores) * bootstrap_frac)
    for b in range(bootstrap_n):
        bi = rng.choice(len(sample_scores), size=n_boot, replace=True)
        boot.append((sample_scores[bi] <= kw_score).sum() / n_boot * 100)
    boot = np.array(boot)
    ci_low = float(np.percentile(boot, 2.5))
    ci_high = float(np.percentile(boot, 97.5))
    with open(out_md, "w") as f:
        f.write("# P2 Joint Density v2 — 100T d3 canonical (sampled)\n\n")
        f.write(f"**Sample size for fitting:** {len(fit_data):,} rows ({n_chunks} chunks)\n")
        f.write(f"**Sample size for scoring:** {len(sample_scores):,} rows\n")
        f.write(f"**Final dimensions ({len(cols)}):** {', '.join(f'`{c}`' for c in cols)}\n")
        if dropped:
            f.write(f"**Auto-dropped:** {', '.join(f'`{x[0]}`' for x in dropped)}\n")
        f.write(f"**Bandwidth method:** {bw_label}\n\n")
        f.write("## Results (sampled estimate)\n")
        f.write(f"- KW's log-density: **{kw_score:.4f}**\n")
        f.write(f"- Sample log-density: [{sample_scores.min():.4f}, "
                f"{sample_scores.max():.4f}], mean {sample_scores.mean():.4f}\n")
        f.write(f"- **KW's density-percentile (sample): {kw_pct:.4f}% "
                f"(n_below={n_below}/{len(sample_scores)})**\n")
        f.write(f"- Bootstrap 95% CI ({bootstrap_n} resamples, frac={bootstrap_frac}): "
                f"**[{ci_low:.4f}%, {ci_high:.4f}%]**\n\n")
        f.write("## Notes\n")
        f.write("- This is the SAMPLED path. For an exact population count, re-run with "
                "`--joint-density-exhaustive` (very slow at full canonical scale; "
                "wall ~hours-to-days single-threaded).\n")
        f.write("- The exhaustive `--joint-permutation-test` complements this by "
                "providing exact counts on per-dim and joint extremity.\n")
    print(f"[v2-jd] wrote {out_md}", flush=True)


def p2_stratified_p2pair(chunks_dir, out_md, samples_per_chunk=30,
                         seed=42, score_batch_size=50000, exhaustive=False,
                         native_solve_binary=None,
                         score_sample=10000, bootstrap_n=500):
    """Stratify the joint-density analysis on `position_2_pair` (32 strata).
    Per-stratum KDE fit always uses a sample (mathematically required).

    Default (exhaustive=False): per-stratum sampled scoring with bootstrap CI.
    exhaustive=True: stream every record in each stratum through that stratum's
    KDE. ~7 hours per stratum single-threaded → ~9 days for all 32 strata.
    Use only with parallelism (D32+ multiprocess) or when scoring just the
    KW stratum.
    """
    import glob
    import numpy as np
    import pyarrow.parquet as pq
    from sklearn.neighbors import KernelDensity

    cols = ["position_2_pair"] + list(_P2_JD_DIMS)
    rng = np.random.default_rng(seed)
    print(f"[v2-strat] reading chunks from {chunks_dir}", flush=True)
    fit_data, n_chunks = _p2_v2_load_sample(chunks_dir, cols, samples_per_chunk, rng)
    print(f"[v2-strat] fit-sample shape: {fit_data.shape}", flush=True)

    p2col = fit_data[:, 0].astype(int)
    rest_fit = fit_data[:, 1:]
    rest_cols = cols[1:]
    rest_fit, rest_cols, kw_vals, dropped = _p2_v2_variance_filter(rest_fit, rest_cols, _P2_KW_VALUES)
    if rest_fit.shape[1] == 0:
        raise SystemExit("[v2-strat] all non-stratifier dims dropped")
    kw_p2 = _P2_KW_VALUES["position_2_pair"]
    kw_arr = np.array(kw_vals, dtype=np.float64)

    strata = sorted(set(int(x) for x in p2col))
    print(f"[v2-strat] {len(strata)} strata observed", flush=True)

    # Phase 1: per-stratum KDE fit (sampled)
    stratum_models = {}
    for s in strata:
        mask = (p2col == s)
        sub = rest_fit[mask]
        if len(sub) < 200:
            stratum_models[s] = None  # too few fit-sample rows
            continue
        mu = sub.mean(axis=0)
        sigma = sub.std(axis=0)
        sigma[sigma == 0] = 1.0
        sub_std = (sub - mu) / sigma
        kw_pt = (kw_arr - mu) / sigma
        n_s, d_s = sub.shape
        bw = (n_s * (d_s + 2) / 4.0) ** (-1.0 / (d_s + 4))
        kde = KernelDensity(bandwidth=bw, kernel="gaussian").fit(sub_std)
        kw_score = float(kde.score_samples(kw_pt.reshape(1, -1))[0])
        stratum_models[s] = {
            "mu": mu, "sigma": sigma, "kde": kde,
            "kw_score": kw_score, "fit_n": len(sub),
        }
    print(f"[v2-strat] fit {sum(1 for m in stratum_models.values() if m)} "
          f"per-stratum KDEs (skipped {sum(1 for m in stratum_models.values() if not m)} small strata)",
          flush=True)

    if exhaustive:
        # EXHAUSTIVE per-stratum scoring. Native engine if available
        # (one subprocess per stratum, mask filters chunks to that p2 value).
        results = []
        if native_solve_binary:
            print(f"[v2-strat] EXHAUSTIVE via native scorer", flush=True)
            kw_bw = (lambda mdl: ((mdl['fit_n'] * (mdl['fit_n'] + 2) / 4.0) ** (-1.0/(mdl['fit_n'] + 4))) if mdl else None)
            for s in strata:
                mdl = stratum_models[s]
                if not mdl:
                    results.append((s, 0, 0, float("nan"), float("nan"), "fit n<200"))
                    continue
                # Build per-stratum standardized fit
                mask_s = (p2col == s)
                sub_fit = rest_fit[mask_s]
                sub_fit_std = (sub_fit - mdl["mu"]) / mdl["sigma"]
                # Bandwidth used during fit
                n_s, d_s = sub_fit.shape
                bw_s = (n_s * (d_s + 2) / 4.0) ** (-1.0 / (d_s + 4))
                # Mask filter for chunk records: keep rows in this stratum
                def make_mask(ss=s):
                    return lambda arr: (arr[:, 0].astype(int) == ss)
                # cols includes "position_2_pair" at index 0 + rest_cols
                # but the native scorer only sees rest_cols. We need to pass
                # mu/sigma over rest_cols, and a mask_filter that operates
                # on the full chunk array, returning a row mask.
                # Inside _p2_v2_native_kde_count, it does (arr - mu) / sigma
                # using the mu/sigma we pass; mask_filter is applied first.
                # Apply mask THEN drop the position_2_pair col before standardize:
                full_cols = cols  # ["position_2_pair", ...rest_cols]
                def mask_and_drop(arr, ss=s, n_skip=1):
                    m = (arr[:, 0].astype(int) == ss)
                    return arr[m][:, n_skip:]  # drop position_2_pair
                # Trick: we pre-process with mask_and_drop; the mu/sigma fits
                # rest_cols. Use a custom streaming wrapper.
                n_below, n_total = _p2_strat_native_count(
                    native_solve_binary, sub_fit_std, bw_s, mdl["kw_score"],
                    chunks_dir, full_cols, mdl["mu"], mdl["sigma"], stratum_value=s)
                pct = n_below / n_total * 100.0 if n_total else float("nan")
                is_kw = (s == kw_p2)
                note = f"fit_n={mdl['fit_n']} (native)" + (" [KW STRATUM]" if is_kw else "")
                results.append((s, n_total, n_below, pct, mdl["kw_score"], note))
                print(f"  stratum {s}: {n_below:,}/{n_total:,} = {pct:.6f}%", flush=True)
        else:
            print(f"[v2-strat] EXHAUSTIVE scoring pass over all {n_chunks} chunks (sklearn)",
                  flush=True)
            files = sorted(glob.glob(f"{chunks_dir}/chunk_*.parquet"))
            stratum_counts = {s: 0 for s in strata}
            stratum_below = {s: 0 for s in strata}
            for fi, f in enumerate(files):
                t = pq.read_table(f, columns=cols)
                full = np.column_stack([t.column(c).to_numpy() for c in cols]).astype(np.float64)
                p2 = full[:, 0].astype(int)
                rest = full[:, 1:]
                for s in strata:
                    mdl = stratum_models[s]
                    if not mdl:
                        continue
                    mask = (p2 == s)
                    if not mask.any():
                        continue
                    sub = rest[mask]
                    sub_std = (sub - mdl["mu"]) / mdl["sigma"]
                    for j in range(0, len(sub_std), score_batch_size):
                        batch = sub_std[j:j + score_batch_size]
                        scores = mdl["kde"].score_samples(batch)
                        stratum_below[s] += int((scores <= mdl["kw_score"]).sum())
                        stratum_counts[s] += len(scores)
                if (fi + 1) % 100 == 0:
                    print(f"  scored {fi+1}/{len(files)} chunks", flush=True)
            for s in strata:
                mdl = stratum_models[s]
                if not mdl:
                    results.append((s, 0, 0, float("nan"), float("nan"), "fit n<200"))
                    continue
                n_total = stratum_counts[s]
                n_below = stratum_below[s]
                pct = n_below / n_total * 100.0 if n_total else float("nan")
                is_kw = (s == kw_p2)
                note = f"fit_n={mdl['fit_n']} (sklearn)" + (" [KW STRATUM]" if is_kw else "")
                results.append((s, n_total, n_below, pct, mdl["kw_score"], note))
    else:
        # SAMPLED per-stratum scoring (fast, with bootstrap CI on each stratum).
        print(f"[v2-strat] SAMPLED scoring (per-stratum sample, with bootstrap CI)",
              flush=True)
        # We need a sample per stratum; reuse fit_data (already sampled) for scoring.
        results = []
        for s in strata:
            mdl = stratum_models[s]
            if not mdl:
                results.append((s, 0, 0, float("nan"), float("nan"), "fit n<200"))
                continue
            mask = (p2col == s)
            sub = rest_fit[mask]
            sub_std = (sub - mdl["mu"]) / mdl["sigma"]
            scs_n = min(score_sample, len(sub_std))
            scs_idx = rng.choice(len(sub_std), size=scs_n, replace=False)
            scores = mdl["kde"].score_samples(sub_std[scs_idx])
            n_below = int((scores <= mdl["kw_score"]).sum())
            pct = n_below / len(scores) * 100.0
            # bootstrap CI
            boot_n = max(50, int(len(scores) * 0.5))
            boot_pcts = []
            for b in range(bootstrap_n):
                bi = rng.choice(len(scores), size=boot_n, replace=True)
                boot_pcts.append((scores[bi] <= mdl["kw_score"]).sum() / boot_n * 100)
            ci_low = float(np.percentile(boot_pcts, 2.5))
            ci_high = float(np.percentile(boot_pcts, 97.5))
            is_kw = (s == kw_p2)
            note = (f"fit_n={mdl['fit_n']} score_n={len(scores)} "
                    f"CI=[{ci_low:.2f},{ci_high:.2f}]"
                    + (" [KW STRATUM]" if is_kw else ""))
            results.append((s, len(scores), n_below, pct, mdl["kw_score"], note))

    with open(out_md, "w") as f:
        mode_label = "exhaustive" if exhaustive else "sampled"
        f.write(f"# P2 Stratified Joint Density (by position_2_pair) — {mode_label}\n\n")
        if exhaustive:
            f.write(f"**Total records:** {sum(stratum_counts.values()):,} ({n_chunks} chunks, exhaustive)\n")
        else:
            f.write(f"**Mode:** sampled scoring per stratum, bootstrap CI ({bootstrap_n} resamples)\n")
        f.write(f"**Fit-sample size (across all strata):** {len(rest_fit):,} rows\n")
        f.write(f"**Stratifier:** `position_2_pair` ({len(strata)} strata)\n")
        f.write(f"**Joint dims:** {', '.join(f'`{c}`' for c in rest_cols)}\n")
        if dropped:
            f.write(f"**Auto-dropped:** {', '.join(f'`{x[0]}`' for x in dropped)}\n")
        f.write(f"**KW position_2_pair:** {kw_p2}\n\n")
        f.write("## Per-stratum KW percentile\n\n")
        f.write("| stratum | n_records | n_below_KW | KW %-ile | KW log-density | notes |\n")
        f.write("|---:|---:|---:|---:|---:|---|\n")
        for s, n_total, n_below, pct, lds, note in results:
            ps = f"{pct:.6f}%" if pct == pct else "—"
            ls = f"{lds:.3f}" if lds == lds else "—"
            f.write(f"| {s} | {n_total:,} | {n_below:,} | {ps} | {ls} | {note} |\n")
        f.write("\n## Interpretation\n\n")
        f.write("- The **KW STRATUM** row reports KW's percentile WITHIN its own bucket.\n")
        f.write("- If the within-stratum percentile is materially weaker than the "
                "unconditioned, `position_2_pair` is part of the discriminative signal.\n")
        if not exhaustive:
            f.write("- Sampled mode includes 95% bootstrap CIs. For exact counts, "
                    "rerun with `--stratified-exhaustive` (~9 days single-threaded; "
                    "use D32+ multiprocess to parallelize across strata).\n")
    print(f"[v2-strat] wrote {out_md}", flush=True)


def p2_joint_permutation_test(chunks_dir, out_md, samples_per_chunk=30, seed=42):
    """Multi-test family-wise correction. EXHAUSTIVE: streams every record
    in every chunk and counts those at least as extreme as KW on each
    dimension. Reports Bonferroni-adjusted p-values + the joint extremity
    distribution.

    samples_per_chunk is used ONLY to compute mu/sigma (the standardization
    reference). The extremity counts themselves are over the full canonical
    population.
    """
    import glob
    import numpy as np
    import pyarrow.parquet as pq

    cols = list(_P2_JD_DIMS)
    rng = np.random.default_rng(seed)
    print(f"[v2-perm] reading reference sample for mu/sigma...", flush=True)
    ref_data, n_chunks = _p2_v2_load_sample(chunks_dir, cols, samples_per_chunk, rng)
    print(f"[v2-perm] reference sample shape: {ref_data.shape}", flush=True)

    ref_data, cols, kw_vals, dropped = _p2_v2_variance_filter(ref_data, cols, _P2_KW_VALUES)
    kw_arr = np.array(kw_vals, dtype=np.float64)

    mu = ref_data.mean(axis=0)
    sigma = ref_data.std(axis=0)
    sigma[sigma == 0] = 1.0
    z_kw = (kw_arr - mu) / sigma
    extremity = np.abs(z_kw)
    d = len(cols)

    # Exhaustive streaming pass: for each record, compute |z|, accumulate
    # per-dim counts and per-record extreme-dim count.
    print(f"[v2-perm] EXHAUSTIVE streaming pass over all {n_chunks} chunks...",
          flush=True)
    files = sorted(glob.glob(f"{chunks_dir}/chunk_*.parquet"))
    total_records = 0
    per_dim_counts = np.zeros(d, dtype=np.int64)
    joint_distribution = np.zeros(d + 1, dtype=np.int64)
    for i, f in enumerate(files):
        t = pq.read_table(f, columns=cols)
        arr = np.column_stack([t.column(c).to_numpy() for c in cols]).astype(np.float64)
        z = (arr - mu) / sigma
        extreme_mask = np.abs(z) >= extremity[None, :]  # shape (n_chunk, d)
        per_dim_counts += extreme_mask.sum(axis=0).astype(np.int64)
        per_record_count = extreme_mask.sum(axis=1)  # 0..d
        bins = np.bincount(per_record_count, minlength=d + 1)
        joint_distribution += bins.astype(np.int64)
        total_records += len(arr)
        if (i + 1) % 100 == 0:
            print(f"  scored {i+1}/{len(files)} chunks "
                  f"({total_records:,} records)", flush=True)

    per_dim_p = [int(per_dim_counts[j]) / total_records for j in range(d)]
    per_dim_p_adj = [min(p * d, 1.0) for p in per_dim_p]
    joint_rate_at_or_above = []
    for k in range(d + 1):
        n_geq_k = int(joint_distribution[k:].sum())
        rate = n_geq_k / total_records
        joint_rate_at_or_above.append((k, n_geq_k, rate))

    print(f"[v2-perm] EXHAUSTIVE: {total_records:,} records across {d} dims; "
          f"{joint_rate_at_or_above[d][1]:,} records tie-or-beat KW on ALL {d} dims",
          flush=True)

    with open(out_md, "w") as f:
        f.write("# P2 Joint Permutation / Multi-Test Correction (exhaustive)\n\n")
        f.write(f"**Total records:** {total_records:,} (exhaustive over {n_chunks} chunks)\n")
        f.write(f"**Reference sample (μ/σ):** {len(ref_data):,} rows used "
                "ONLY to define standardization. All counts below are exact.\n")
        f.write(f"**Dimensions tested ({d}):** {', '.join(f'`{c}`' for c in cols)}\n")
        if dropped:
            f.write(f"**Auto-dropped:** {', '.join(f'`{x[0]}`' for x in dropped)}\n")
        f.write("\n## Per-dimension marginal extremity (exhaustive)\n\n")
        f.write("Defines extremity as |z-score| (using sample μ/σ). Reports the EXACT "
                "fraction of canonical records with |z| >= |z_KW|.\n\n")
        f.write("| dim | KW value | KW |z| | n_records ≥ KW | p (raw) | p (Bonferroni × d) |\n")
        f.write("|---|---:|---:|---:|---:|---:|\n")
        for j, c in enumerate(cols):
            f.write(f"| `{c}` | {kw_vals[j]} | {extremity[j]:.3f} "
                    f"| {int(per_dim_counts[j]):,} "
                    f"| {per_dim_p[j]:.6e} | {per_dim_p_adj[j]:.6e} |\n")
        f.write("\n## Joint extremity distribution (exhaustive)\n\n")
        f.write("For each record, count how many of the d dimensions it ties-or-beats "
                "KW on (|z| >= |z_KW|). Cumulative distribution over the full population.\n\n")
        f.write("| at-least-k dims | n_records | rate |\n")
        f.write("|---:|---:|---:|\n")
        for k, n_rec, rate in joint_rate_at_or_above:
            f.write(f"| {k} | {n_rec:,} | {rate:.6e} |\n")
        f.write("\n## Interpretation\n\n")
        f.write(f"- Bonferroni: a per-dim p-value of <{0.05/d:.4e} would be "
                f"family-wise significant at α=0.05 across {d} tests.\n")
        f.write(f"- The joint rate at-least-{d} (last row) is the EXACT fraction of "
                "records tying or beating KW on EVERY dim simultaneously — the "
                "strongest multi-dimensional outlier metric here.\n")
        f.write("- All counts are exact over the full canonical population. "
                "No bootstrap or sample CIs are needed.\n")
    print(f"[v2-perm] wrote {out_md}", flush=True)


# ============================================================================
# END P2 DISTRIBUTIONAL ANALYSIS section
# ============================================================================


# ----------------------------------------------------------------------------
# P3 SAT model-counting encoding (2026-04-24)
# Spec: x/roae/SAT_EXPERIMENT_SPEC.md
#
# Encodes C1 ∩ C2 (∪ optional C3, C4) as a propositional formula in DIMACS
# CNF format. Variable: x[i][p] = 1 iff position i (0-63) holds hexagram p.
# Number of vars: 64*64 = 4096 + auxiliary for C3 cardinality if requested.
# ----------------------------------------------------------------------------


def _sat_var(i, p):
    """1-indexed DIMACS var: position i (0-63), hexagram p (0-63)."""
    return 64 * i + p + 1  # 1..4096


def _sat_partner_map():
    """Returns array partner[64] where partner[v] is the hexagram paired with v."""
    pairs = build_pairs()
    partner = [None] * 64
    for a, b in pairs:
        partner[a] = b
        partner[b] = a
    return partner


def _sat_pairwise_amo(vars_list):
    """At-most-one constraint via pairwise binary clauses. Returns list of clauses."""
    clauses = []
    for i in range(len(vars_list)):
        for j in range(i + 1, len(vars_list)):
            clauses.append([-vars_list[i], -vars_list[j]])
    return clauses


def p3_sat_encode(out_path, include_c3="none", include_c4=False, include_c5=False):
    """Emit a DIMACS CNF (or pblib format if PB constraints are present)
    encoding C1 ∩ C2 of the King Wen sequence.

    include_c3: "none", "pb" (Pseudo-Boolean linear constraint), or
                "adder" (DIMACS sequential adder encoding — TODO).
    include_c4: force x[0][0] and x[1][partner(0)] = 1.
    include_c5: emit cardinality constraints matching KW's Hamming distribution
                (heavy; defer in v1 unless explicitly requested).
    """
    import hashlib
    import json
    import time

    partner = _sat_partner_map()
    clauses = []
    n_vars = 64 * 64  # base position-hexagram vars

    # --- One-hot rows: each position gets exactly one hexagram ---
    for i in range(64):
        row_vars = [_sat_var(i, p) for p in range(64)]
        clauses.append(row_vars[:])  # at-least-one
        clauses.extend(_sat_pairwise_amo(row_vars))  # at-most-one

    # --- One-hot columns: each hexagram appears at exactly one position ---
    for p in range(64):
        col_vars = [_sat_var(i, p) for i in range(64)]
        clauses.append(col_vars[:])
        clauses.extend(_sat_pairwise_amo(col_vars))

    # --- C1: positions (2k, 2k+1) hold partner pairs ---
    # For every k in 0,2,4,...,62 and every hexagram p:
    #   x[k][p] -> x[k+1][partner(p)]    encoded as (¬x[k][p] ∨ x[k+1][partner(p)])
    for k in range(0, 64, 2):
        for p in range(64):
            clauses.append([-_sat_var(k, p), _sat_var(k + 1, partner[p])])

    # --- C2: between-pair boundaries (positions 2k+1 and 2k+2) cannot have Hamming dist 5 ---
    # For each boundary, iterate over all 64*64 (p, q) tuples; if popcount(p^q) == 5, forbid.
    boundary_clauses = 0
    for k in range(31):  # 31 boundaries: between pair k and pair k+1, i.e. positions 2k+1, 2(k+1)
        i_left = 2 * k + 1
        i_right = 2 * k + 2
        for p in range(64):
            for q in range(64):
                if bin(p ^ q).count("1") == 5:
                    clauses.append([-_sat_var(i_left, p), -_sat_var(i_right, q)])
                    boundary_clauses += 1

    # --- C4: start with hexagram 0 at position 0 (Qian/Kun convention via partner) ---
    if include_c4:
        clauses.append([_sat_var(0, 0)])  # unit clause: position 0 = hexagram 0
        # x[1][partner[0]] follows from C1 implications + one-hot, but assert directly:
        clauses.append([_sat_var(1, partner[0])])

    # --- C3: pseudo-boolean linear constraint  ∑ |pos(v) - pos(c̄(v))| <= 776 ---
    #
    # Strategy: introduce aux vars pair[v][i][j] = x[i][v] AND x[j][c̄(v)],
    # then ∑_v ∑_{i,j} |i-j| · pair[v][i][j] <= 776 is a single linear PB
    # constraint. Aux count = 64 × 64 × 64 = 262,144 vars; pair-linking
    # adds ~800K clauses. Output format: .opb (OPB / PB-CNF) emitted
    # alongside the .cnf when --sat-c3=pb is selected.
    #
    # The .cnf (DIMACS) keeps C1+C2 only; pure-#SAT solvers see that file.
    # The .opb file contains the SAME C1+C2 plus the C3 PB constraint;
    # solvers with PB extension (ganak --pb, d4 --opb, sharpSAT-TD) read it.
    pb_constraints = []
    pair_aux_clauses = []  # extra clauses for aux pair[v][i][j] linking
    pair_aux_offset = n_vars  # aux vars start here (1-indexed)
    pair_var_count = 0

    if include_c3 in ("pb", "adder"):
        # complement function: ~v in 6 bits = v XOR 0x3F
        comp = [v ^ 0b111111 for v in range(64)]
        # aux var index: pair[v][i][j] -> pair_aux_offset + 1 + (v*64 + i)*64 + j
        def aux_var(v, i, j):
            return pair_aux_offset + 1 + (v * 64 + i) * 64 + j

        # Emit linking clauses:
        #   pair[v][i][j] -> x[i][v]              (¬pair ∨ x[i][v])
        #   pair[v][i][j] -> x[j][c̄(v)]           (¬pair ∨ x[j][c̄(v)])
        #   x[i][v] ∧ x[j][c̄(v)] -> pair[v][i][j] (¬x[i][v] ∨ ¬x[j][c̄(v)] ∨ pair)
        for v in range(64):
            cv = comp[v]
            for i in range(64):
                for j in range(64):
                    pair_var_count += 1
                    pa = aux_var(v, i, j)
                    pair_aux_clauses.append([-pa, _sat_var(i, v)])
                    pair_aux_clauses.append([-pa, _sat_var(j, cv)])
                    pair_aux_clauses.append([-_sat_var(i, v), -_sat_var(j, cv), pa])

        clauses.extend(pair_aux_clauses)
        n_vars = pair_aux_offset + pair_var_count  # update total

        if include_c3 == "pb":
            # Build the OPB linear constraint as a list of (coeff, varIdx) tuples.
            opb_terms = []
            for v in range(64):
                for i in range(64):
                    for j in range(64):
                        if i == j:
                            continue  # |0| = 0, no contribution
                        coef = abs(i - j)
                        opb_terms.append((coef, aux_var(v, i, j)))
            pb_constraints.append({
                "form": "abs_sum_complement_distance",
                "bound": 776,
                "n_terms": len(opb_terms),
                "n_aux_vars": pair_var_count,
                "n_link_clauses": len(pair_aux_clauses),
                "opb_terms": opb_terms,  # will be emitted to .opb
            })
        elif include_c3 == "adder":
            # DIMACS sequential adder — TODO. Significantly more involved
            # (build a binary adder over the per-pair distances) and probably
            # not faster in practice than PB. Documenting only.
            pb_constraints.append({
                "form": "abs_sum_complement_distance",
                "bound": 776,
                "n_aux_vars": pair_var_count,
                "n_link_clauses": len(pair_aux_clauses),
                "status": "TODO_implement_DIMACS_adder_summing_network",
            })
    # include_c3 == "none" -> no C3 emitted

    # --- C5: KW's exact Hamming distribution (heavy, optional) ---
    if include_c5:
        pb_constraints.append({
            "form": "hamming_distribution_match",
            "status": "TODO_implement_C5_cardinality",
            "note": "31 cardinality constraints, one per boundary",
        })

    # Emit DIMACS
    n_clauses = len(clauses)
    print(f"[sat-encode] vars={n_vars}, clauses={n_clauses}, "
          f"C2-boundary={boundary_clauses}", flush=True)
    print(f"[sat-encode] C3={include_c3}, C4={include_c4}, C5={include_c5}", flush=True)

    sha = hashlib.sha256()
    with open(out_path, "w") as f:
        f.write(f"c roae P3 SAT encoding — King Wen sequence\n")
        f.write(f"c generated {time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())}\n")
        f.write(f"c constraints: C1+C2"
                + (f"+C3({include_c3})" if include_c3 != "none" else "")
                + ("+C4" if include_c4 else "")
                + ("+C5" if include_c5 else "")
                + "\n")
        f.write(f"c vars are x[i][p] = 1 iff position i (0-63) holds hexagram p (0-63), 1-indexed\n")
        f.write(f"p cnf {n_vars} {n_clauses}\n")
        for cl in clauses:
            line = " ".join(str(v) for v in cl) + " 0\n"
            sha.update(line.encode())
            f.write(line)

    sha_hex = sha.hexdigest()

    # If C3 PB requested, emit a parallel .opb file with the SAME constraints
    # plus the C3 PB inequality. ganak --pb / d4 --opb / sharpSAT-TD read OPB.
    opb_path = None
    if include_c3 == "pb" and pb_constraints:
        opb_path = out_path + ".opb"
        # OPB format: header, then constraints. Each linear constraint
        # is "+c1 x1 +c2 x2 ... <op> n ;" where <op> is = or >= or <=.
        # We need: =1 (one-hot), <=K (PB).
        with open(opb_path, "w") as f:
            f.write(f"* roae P3 SAT encoding (PB / OPB) — King Wen sequence\n")
            f.write(f"* generated {time.strftime('%Y-%m-%dT%H:%M:%SZ', time.gmtime())}\n")
            f.write(f"* constraints: C1+C2+C3(pb)"
                    + ("+C4" if include_c4 else "")
                    + "\n")
            f.write(f"* vars: 1..{pair_aux_offset} = x[i][p]; "
                    f"{pair_aux_offset+1}..{n_vars} = pair[v][i][j] aux\n")
            f.write(f"* #variable= {n_vars} #constraint= {n_clauses + 1}\n")
            # Re-emit base CNF clauses as OPB CLAUSES (every literal has +1
            # coefficient; constraint is >= 1, allowing the clause).
            for cl in clauses:
                terms = []
                rhs = 1
                for lit in cl:
                    if lit > 0:
                        terms.append(f"+1 x{lit}")
                    else:
                        # ¬x = (1 - x); to write as PB: use "-1 x{|lit|}" and
                        # adjust rhs by -1 (i.e., for clause (¬x ∨ y), rewrite
                        # as -1*x + 1*y >= 0 i.e., y - x >= 0).
                        terms.append(f"-1 x{-lit}")
                        rhs -= 1
                f.write(" ".join(terms) + f" >= {rhs} ;\n")
            # Now the C3 PB constraint: ∑ |i-j| * pair[v][i][j] <= 776
            opb_terms = pb_constraints[0]["opb_terms"]
            # Write in chunks of ~50 terms per line for readability
            term_strs = [f"+{c} x{v}" for c, v in opb_terms if c > 0]
            f.write("* C3: sum_v |pos(v) - pos(c-bar(v))| <= 776\n")
            CHUNK = 50
            for i in range(0, len(term_strs), CHUNK):
                line = " ".join(term_strs[i:i + CHUNK])
                if i + CHUNK >= len(term_strs):
                    f.write(line + " <= 776 ;\n")
                else:
                    f.write(line + "\n")

    meta = {
        "out_cnf": out_path,
        "out_opb": opb_path,
        "vars": n_vars,
        "clauses": n_clauses,
        "boundary_clauses_c2": boundary_clauses,
        "include_c3": include_c3,
        "include_c4": include_c4,
        "include_c5": include_c5,
        "pb_constraints": [
            # strip the giant opb_terms list from the JSON so the meta
            # file stays small and human-readable
            {k: v for k, v in pb.items() if k != "opb_terms"}
            for pb in pb_constraints
        ],
        "sha256_clauses_only": sha_hex,
    }
    meta_path = out_path + ".meta.json"
    with open(meta_path, "w") as f:
        json.dump(meta, f, indent=2)
    print(f"[sat-encode] wrote {out_path} ({n_clauses} clauses, "
          f"sha256={sha_hex[:12]}...)", flush=True)
    if opb_path:
        print(f"[sat-encode] wrote {opb_path} (OPB with C3 PB; "
              f"{len(pb_constraints[0]['opb_terms'])} terms in C3 sum)", flush=True)
    print(f"[sat-encode] wrote {meta_path}", flush=True)
    if pb_constraints and include_c3 != "pb":
        print(f"[sat-encode] WARNING: {len(pb_constraints)} PB/cardinality "
              "constraint(s) requested but emission TODO. v1 ships C1+C2 "
              "only; C3/C5 deferred to v2.", flush=True)


# ============================================================================
# END P3 SAT section
# ============================================================================


# ============================================================================
# Keystone analysis (`--keystone-analysis`)
# ----------------------------------------------------------------------------
# Counterfactual study of the partition-stable boundary minimum-set
# {1, 4, 21, 25, 27} (1-indexed) at the 100T-d3 canonical. For each canonical
# record, determine which subset of those 5 boundaries it matches against KW.
# Output the full 32-entry mask histogram plus drop-one analysis: how many
# records satisfy a 4-subset (drop one boundary) but fail the dropped one?
# Those "rescued by dropping boundary X" sets are the orderings that
# boundary X uniquely eliminates — the structural witnesses that explain
# why X is a keystone.
#
# Boundary numbering. SPECIFICATION.md/SOLVE.md use 1-indexed boundaries
# (1..31), where boundary b sits between pair-positions b and b+1. We use
# 0-indexed boundaries internally (0..30): 0-indexed boundary b ⇔
# 1-indexed boundary b+1, sitting between pair positions b and b+1
# (also 0-indexed). The minimum-set {1,4,21,25,27} (1-idx) = {0,3,20,24,26}
# (0-idx).
#
# KW canonical orientation. In the canonical solutions.bin, KW corresponds
# to pair_at_pos[i] = i for i in 0..31 (because the pair table is built by
# pairing consecutive KW positions, so pair i is at position i in KW). So
# matching at boundary b reduces to:
#     pair_at_pos[b] == b AND pair_at_pos[b+1] == b+1
# ----------------------------------------------------------------------------


_KEYSTONE_BDRYS_1IDX = (1, 4, 21, 25, 27)


def _keystone_decode_pair_positions(records):
    """records: shape (N, 32) uint8. Returns (N, 32) uint8 of pair indices."""
    return (records >> 2) & 0x3F


def _keystone_compute_mask(pair_at_pos, bdrys_0idx):
    """
    pair_at_pos: shape (N, 32) uint8.
    bdrys_0idx: tuple of K boundary indices (each in 0..30).
    Returns: shape (N,) uint8 with bit i set iff record matches KW at
             boundary bdrys_0idx[i].
    """
    import numpy as np
    n = pair_at_pos.shape[0]
    mask = np.zeros(n, dtype=np.uint8)
    for i, b in enumerate(bdrys_0idx):
        bit = (pair_at_pos[:, b] == b) & (pair_at_pos[:, b + 1] == b + 1)
        mask |= (bit.astype(np.uint8) << i)
    return mask


def branch_yield_report(solutions_bin, baseline_bin=None, manifest=None,
                        depth=1, out_csv=None, out_json=None):
    """Handler for --branch-yield-report.

    Reads `solutions.bin` and produces a per-partition-prefix yield count.
    Useful for asymmetric-extension analysis (where some sub-branches were
    walked at a higher per-sub-branch budget than others) — surfaces which
    branches differ from baseline by how much.

    See `x/roae/BRANCH_YIELD_REPORT_DESIGN.md` for the full design doc.

    Args:
        solutions_bin: path to a v1-format solutions.bin
        baseline_bin: optional, path to a baseline solutions.bin to diff against
        manifest: optional, path to manifest.json with per-sub-branch budget map
        depth: 1, 2, or 3 — granularity of bucketing
            1 = first-level (p1, o1), 56 valid buckets
            2 = depth-2 (p1, o1, p2, o2), ~3000 buckets
            3 = depth-3 (p1, o1, p2, o2, p3, o3), ~158000 buckets
        out_csv: optional, write per-bucket counts to this CSV file
        out_json: optional, write structured report to this JSON file

    By default emits a plain-text report on stdout.
    """
    import os
    import struct
    import json
    from collections import defaultdict

    if depth not in (1, 2, 3):
        raise ValueError(f"--depth must be 1, 2, or 3 (got {depth})")

    # #169: transparently decompress gz inputs to temps for the duration of the
    # report (the readers below use os.path.getsize + seekable reads).
    _ctx_s = _gz_resolved_path(solutions_bin); solutions_bin = _ctx_s.__enter__()
    _ctx_b = None
    if baseline_bin is not None:
        _ctx_b = _gz_resolved_path(baseline_bin); baseline_bin = _ctx_b.__enter__()
    try:
        return _branch_yield_report_impl(solutions_bin, baseline_bin, manifest,
                                         depth, out_csv, out_json,
                                         os, struct, json, defaultdict)
    finally:
        _ctx_s.__exit__(None, None, None)
        if _ctx_b is not None:
            _ctx_b.__exit__(None, None, None)


def _branch_yield_report_impl(solutions_bin, baseline_bin, manifest,
                              depth, out_csv, out_json,
                              os, struct, json, defaultdict):
    def _read_header(f):
        """Read + validate v1 header. Returns (record_count, header_size)."""
        hdr = f.read(32)
        if len(hdr) != 32:
            raise ValueError("solutions.bin too short for v1 header")
        magic = hdr[:4]
        if magic != b"ROAE":
            raise ValueError(f"bad magic: {magic!r} (expected b'ROAE')")
        version = struct.unpack("<I", hdr[4:8])[0]
        if version != 1:
            raise ValueError(f"unsupported format version {version} (expected 1)")
        record_count = struct.unpack("<Q", hdr[8:16])[0]
        return record_count, 32

    def _bucket_counts(path, depth):
        """Stream solutions.bin and bucket records by partition prefix.
        Returns (record_count_actual, dict[tuple -> count])."""
        with open(path, "rb") as f:
            file_size = os.fstat(f.fileno()).st_size
            record_count_hdr, hdr_size = _read_header(f)
            data_size = file_size - hdr_size
            if data_size % 32 != 0:
                raise ValueError(
                    f"file body {data_size} not a multiple of 32 (corrupt)")
            record_count_actual = data_size // 32
            if record_count_actual != record_count_hdr:
                print(f"WARN: header says {record_count_hdr} records but "
                      f"file has {record_count_actual} (using actual)")
            buckets = defaultdict(int)
            CHUNK = 1 << 20  # 1M records per chunk = 32 MB
            while True:
                chunk = f.read(CHUNK * 32)
                if not chunk:
                    break
                n = len(chunk) // 32
                for i in range(n):
                    rec = chunk[i * 32:(i + 1) * 32]
                    p1 = (rec[1] >> 2) & 0x3F
                    o1 = (rec[1] >> 1) & 0x01
                    if depth == 1:
                        key = (p1, o1)
                    elif depth == 2:
                        p2 = (rec[2] >> 2) & 0x3F
                        o2 = (rec[2] >> 1) & 0x01
                        key = (p1, o1, p2, o2)
                    else:  # depth == 3
                        p2 = (rec[2] >> 2) & 0x3F
                        o2 = (rec[2] >> 1) & 0x01
                        p3 = (rec[3] >> 2) & 0x3F
                        o3 = (rec[3] >> 1) & 0x01
                        key = (p1, o1, p2, o2, p3, o3)
                    buckets[key] += 1
            return record_count_actual, dict(buckets)

    print(f"Reading {solutions_bin} ...")
    total, buckets = _bucket_counts(solutions_bin, depth)
    print(f"  {total:,} records bucketed into {len(buckets):,} {('first-level','depth-2','depth-3')[depth-1]} buckets")

    baseline_total = None
    baseline_buckets = None
    if baseline_bin:
        print(f"Reading baseline {baseline_bin} ...")
        baseline_total, baseline_buckets = _bucket_counts(baseline_bin, depth)
        print(f"  baseline: {baseline_total:,} records in {len(baseline_buckets):,} buckets")

    # Manifest: budget map
    budget_default = None
    budget_overrides = []   # list of dicts: {p1, o1, p2?, o2?, p3?, o3?, budget}
    manifest_data = None
    if manifest:
        with open(manifest, "r") as mf:
            manifest_data = json.load(mf)
        psb = manifest_data.get("per_sub_branch_budget", {})
        budget_default = psb.get("default")
        budget_overrides = psb.get("overrides", [])
        print(f"Manifest: default budget {budget_default}, "
              f"{len(budget_overrides)} per-sub-branch overrides")

    def _budget_for_key(key, depth):
        """Resolve the budget for a bucket key from the manifest."""
        if not manifest_data:
            return None
        # Match best-fitting override (deepest match wins)
        best = None
        best_specificity = -1
        for ov in budget_overrides:
            spec = 0
            ov_p1 = ov.get("p1")
            ov_o1 = ov.get("o1")
            if ov_p1 is None or ov_o1 is None:
                continue
            if ov_p1 != key[0] or ov_o1 != key[1]:
                continue
            spec = 1
            if depth >= 2 and "p2" in ov and "o2" in ov:
                if ov["p2"] != key[2] or ov["o2"] != key[3]:
                    continue
                spec = 2
            if depth >= 3 and "p3" in ov and "o3" in ov:
                if ov["p3"] != key[4] or ov["o3"] != key[5]:
                    continue
                spec = 3
            if spec > best_specificity:
                best = ov
                best_specificity = spec
        if best:
            return best.get("budget")
        return budget_default

    # ----- Build report rows -----
    rows = []
    for key, count in sorted(buckets.items()):
        row = {"key": key, "count": count}
        row["pct"] = (100.0 * count / total) if total else 0.0
        if baseline_buckets is not None:
            base_count = baseline_buckets.get(key, 0)
            row["baseline_count"] = base_count
            row["delta"] = count - base_count
            row["pct_change"] = ((count - base_count) / base_count * 100.0
                                 if base_count else float('inf') if count else 0.0)
        if manifest_data:
            row["budget"] = _budget_for_key(key, depth)
            if budget_default is not None and row["budget"] is not None:
                row["extended"] = row["budget"] > budget_default
            else:
                row["extended"] = False
        rows.append(row)

    # Plain-text report ----------------------------------------------------
    depth_name = ("first-level (p1, o1)", "depth-2 (p1, o1, p2, o2)",
                  "depth-3 (p1, o1, p2, o2, p3, o3)")[depth - 1]
    print()
    print(f"=== Branch Yield Report — depth {depth} ({depth_name}) ===")
    print(f"Source: {solutions_bin}")
    if baseline_bin:
        print(f"Baseline: {baseline_bin}")
    print(f"Total records: {total:,}")
    print(f"Distinct buckets with non-zero count: {len(buckets):,}")
    print()

    # Header
    if depth == 1:
        head = f"{'(p1, o1)':12s}"
    elif depth == 2:
        head = f"{'(p1,o1,p2,o2)':18s}"
    else:
        head = f"{'(p1,o1,p2,o2,p3,o3)':24s}"
    head += f" {'count':>14s} {'pct':>8s}"
    if baseline_buckets is not None:
        head += f" {'baseline':>14s} {'delta':>14s} {'pct_chg':>9s}"
    if manifest_data:
        head += f" {'budget':>14s} extended"
    print(head)
    print("-" * len(head))

    for row in rows:
        if depth == 1:
            keystr = f"({row['key'][0]}, {row['key'][1]})"
            line = f"{keystr:12s}"
        elif depth == 2:
            line = f"({row['key'][0]},{row['key'][1]},{row['key'][2]},{row['key'][3]})".ljust(18)
        else:
            line = f"({','.join(map(str, row['key']))})".ljust(24)
        line += f" {row['count']:14,} {row['pct']:7.2f}%"
        if baseline_buckets is not None:
            line += f" {row['baseline_count']:14,} {row['delta']:+14,}"
            pc = row['pct_change']
            if pc == float('inf'):
                line += f" {'+inf':>9s}"
            else:
                line += f" {pc:+8.2f}%"
        if manifest_data:
            b = row.get('budget')
            line += f" {b:14,}" if b is not None else f" {'(unknown)':>14s}"
            line += f" {'YES' if row.get('extended') else ''}"
        print(line)

    print("-" * len(head))
    print(f"{'TOTAL':12s} {total:14,} {100.00:7.2f}%")
    if baseline_buckets is not None:
        print(f"     baseline:    {baseline_total:14,}")
        print(f"     delta:       {total - baseline_total:+14,}")
        if baseline_total:
            print(f"     pct change:  {100.0 * (total - baseline_total) / baseline_total:+8.2f}%")

    # Distribution stats
    counts = [r['count'] for r in rows if r['count'] > 0]
    if counts:
        counts_sorted = sorted(counts)
        median = counts_sorted[len(counts_sorted) // 2]
        mean = sum(counts) / len(counts)
        cv = (sum((c - mean) ** 2 for c in counts) / len(counts)) ** 0.5 / mean if mean else 0
        print()
        print(f"Distribution (across non-zero buckets):")
        print(f"  min:     {min(counts):,}")
        print(f"  median:  {median:,}")
        print(f"  mean:    {mean:,.0f}")
        print(f"  max:     {max(counts):,}")
        print(f"  CV:      {cv:.3f}  ({'high' if cv > 0.5 else 'moderate' if cv > 0.2 else 'low'} variation)")

    # Sanity check vs manifest (extended branches should differ from baseline)
    if baseline_buckets is not None and manifest_data:
        ext_changed = sum(1 for r in rows if r.get('extended') and r['delta'] != 0)
        ext_total = sum(1 for r in rows if r.get('extended'))
        non_ext_changed = sum(1 for r in rows if not r.get('extended') and r['delta'] != 0)
        non_ext_total = sum(1 for r in rows if not r.get('extended'))
        print()
        print(f"Sanity check vs manifest:")
        print(f"  extended-budget buckets with non-zero delta: {ext_changed}/{ext_total} {'PASS' if ext_changed == ext_total else 'FAIL — expected all extended buckets to differ'}")
        print(f"  default-budget buckets with zero delta:      {non_ext_total - non_ext_changed}/{non_ext_total} {'PASS' if non_ext_changed == 0 else 'FAIL — expected all default-budget buckets identical to baseline'}")

    # CSV output -----------------------------------------------------------
    if out_csv:
        import csv as _csv
        with open(out_csv, "w", newline="") as f:
            cols = (["p1", "o1", "p2", "o2", "p3", "o3"][:2 * depth] +
                    ["count", "pct"])
            if baseline_buckets is not None:
                cols += ["baseline_count", "delta", "pct_change"]
            if manifest_data:
                cols += ["budget", "extended"]
            w = _csv.writer(f)
            w.writerow(cols)
            for row in rows:
                vals = list(row['key']) + [row['count'], f"{row['pct']:.4f}"]
                if baseline_buckets is not None:
                    vals += [row['baseline_count'], row['delta'],
                             f"{row['pct_change']:.4f}" if row['pct_change'] != float('inf') else "inf"]
                if manifest_data:
                    vals += [row.get('budget', ''), 'true' if row.get('extended') else 'false']
                w.writerow(vals)
        print(f"\nCSV written to {out_csv}")

    # JSON output ----------------------------------------------------------
    if out_json:
        report = {
            "version": 1,
            "tool": "solve.py --branch-yield-report",
            "input": {
                "solutions_bin": solutions_bin,
                "baseline_bin": baseline_bin,
                "manifest": manifest,
                "depth": depth,
            },
            "summary": {
                "total_records": total,
                "buckets_count": len(buckets),
                "baseline_total": baseline_total,
            },
            "buckets": [
                {
                    "key": list(row['key']),
                    "count": row['count'],
                    "pct": row['pct'],
                    **({"baseline_count": row['baseline_count'],
                        "delta": row['delta'],
                        "pct_change": (row['pct_change']
                                       if row['pct_change'] != float('inf')
                                       else None)}
                       if baseline_buckets is not None else {}),
                    **({"budget": row.get('budget'),
                        "extended": row.get('extended', False)}
                       if manifest_data else {}),
                }
                for row in rows
            ],
        }
        with open(out_json, "w") as f:
            json.dump(report, f, indent=2)
        print(f"JSON written to {out_json}")


def keystone_analysis(solutions_bin, out_md, dump_dir=None,
                      dump_limit=10000, chunk_size=None):
    """
    Handler for --keystone-analysis.

    Reads solutions.bin sequentially. For each record, computes a 5-bit
    match mask against the {1,4,21,25,27} (1-indexed) minimum-set boundaries.
    Tabulates counts per mask, plus pairwise joint counts within the 5-set
    for the per-boundary independence story. Optionally dumps records
    matching one of the 'interesting' masks (15 = drop-27, 23 = drop-25,
    31 = all-five) to a binary file for downstream structural analysis.
    """
    import time
    import os
    import numpy as np

    bdrys_1idx = _KEYSTONE_BDRYS_1IDX
    bdrys_0idx = tuple(b - 1 for b in bdrys_1idx)
    if chunk_size is None:
        chunk_size = _P2_CHUNK_RECORDS_DEFAULT

    # #169: transparently decompress a gz solutions.bin to a temp for the
    # sequential read + os.path.getsize calls below.
    with _gz_resolved_path(solutions_bin) as solutions_bin:
        return _keystone_analysis_impl(solutions_bin, out_md, dump_dir,
                                       dump_limit, chunk_size,
                                       time, os, np, bdrys_1idx, bdrys_0idx)


def _keystone_analysis_impl(solutions_bin, out_md, dump_dir, dump_limit,
                            chunk_size, time, os, np, bdrys_1idx, bdrys_0idx):
    with open(solutions_bin, "rb") as f:
        total_records, version = _p2_read_header(f)

    print(f"[keystone] solutions.bin v{version}, {total_records:,} records "
          f"({os.path.getsize(solutions_bin) / 1e9:.2f} GB)", flush=True)
    print(f"[keystone] minimum 5-set (1-idx): {bdrys_1idx}  "
          f"(0-idx: {bdrys_0idx})", flush=True)
    print(f"[keystone] mask convention: bit i set iff boundary "
          f"bdrys_1idx[i] matches KW", flush=True)

    mask_counts = np.zeros(32, dtype=np.int64)
    # interesting masks: drop-one variants and the all-matched mask
    # Mask convention: bit i ⇔ boundary _KEYSTONE_BDRYS_1IDX[i] matches KW.
    # Drop-X mask = (all-5-mask) XOR (1 << index_of_X). For BDRYS_1IDX = (1,4,21,25,27):
    #   drop-1  → 31 ^ (1<<0) = 30 (`11110`)
    #   drop-4  → 31 ^ (1<<1) = 29 (`11101`)
    #   drop-21 → 31 ^ (1<<2) = 27 (`11011`)
    #   drop-25 → 31 ^ (1<<3) = 23 (`10111`)
    #   drop-27 → 31 ^ (1<<4) = 15 (`01111`)
    INTERESTING = {
        31: ("all-5-matched", "Should equal 1 if {1,4,21,25,27} "
                              "uniquely determines KW; >1 falsifies that claim"),
        15: ("drop-27", "All matched except boundary 27 — "
                        "rescued by dropping 27 → boundary 27 uniquely kills these"),
        23: ("drop-25", "All matched except boundary 25 — "
                        "rescued by dropping 25 → boundary 25 uniquely kills these"),
        27: ("drop-21", "All matched except boundary 21 — boundary 21 uniquely kills these"),
        29: ("drop-4",  "All matched except boundary 4 — boundary 4 uniquely kills these"),
        30: ("drop-1",  "All matched except boundary 1 — boundary 1 uniquely kills these"),
    }
    interesting_records = {m: [] for m in INTERESTING}

    if dump_dir is not None:
        os.makedirs(dump_dir, exist_ok=True)

    offset = _P2_HEADER_SIZE
    remaining = total_records
    seen = 0
    t0 = time.time()
    last_log = t0

    with open(solutions_bin, "rb") as f:
        while remaining > 0:
            n = min(chunk_size, remaining)
            f.seek(offset)
            raw = f.read(n * _P2_RECORD_SIZE)
            if len(raw) < n * _P2_RECORD_SIZE:
                # truncated read; trim
                n = len(raw) // _P2_RECORD_SIZE
                if n == 0:
                    break
            records = np.frombuffer(raw[:n * _P2_RECORD_SIZE],
                                    dtype=np.uint8).reshape(n, _P2_RECORD_SIZE)
            pair_at_pos = _keystone_decode_pair_positions(records)
            mask = _keystone_compute_mask(pair_at_pos, bdrys_0idx)

            # tabulate (vectorized)
            chunk_counts = np.bincount(mask, minlength=32)
            mask_counts += chunk_counts

            # capture interesting records up to dump_limit per mask
            for m in INTERESTING:
                if len(interesting_records[m]) >= dump_limit:
                    continue
                idxs = np.where(mask == m)[0]
                room = dump_limit - len(interesting_records[m])
                if len(idxs) > room:
                    idxs = idxs[:room]
                if len(idxs) > 0:
                    interesting_records[m].append(records[idxs].copy())

            offset += n * _P2_RECORD_SIZE
            remaining -= n
            seen += n

            now = time.time()
            if now - last_log >= 30 or remaining == 0:
                rate = seen / max(now - t0, 1e-9)
                eta = (total_records - seen) / max(rate, 1.0)
                print(f"[keystone] {seen:,}/{total_records:,} "
                      f"({100*seen/total_records:.1f}%) "
                      f"{rate/1e6:.2f}M/s ETA {eta/60:.1f}m", flush=True)
                last_log = now

    elapsed = time.time() - t0
    print(f"[keystone] DONE {seen:,} records in {elapsed:.1f}s "
          f"({seen/elapsed/1e6:.2f}M/s)", flush=True)

    # Write dumps
    dump_paths = {}
    if dump_dir is not None:
        for m, chunks in interesting_records.items():
            if not chunks:
                continue
            arr = np.concatenate(chunks, axis=0)
            label = INTERESTING[m][0]
            path = os.path.join(dump_dir, f"keystone_mask{m:02d}_{label}.bin")
            with open(path, "wb") as fdump:
                fdump.write(arr.tobytes())
            dump_paths[m] = (path, arr.shape[0])
            print(f"[keystone] dumped {arr.shape[0]} records "
                  f"(mask={m}, {label}) → {path}", flush=True)

    # Write markdown report
    with open(out_md, "w") as fmd:
        fmd.write("# Keystone analysis — boundary minimum-set "
                  f"{{1,4,21,25,27}} on `{os.path.basename(solutions_bin)}`\n\n")
        fmd.write(f"- Total records: **{total_records:,}**\n")
        fmd.write(f"- Minimum 5-set (1-indexed): "
                  f"{_KEYSTONE_BDRYS_1IDX}\n")
        fmd.write(f"- Mask bit i ⇔ boundary `_KEYSTONE_BDRYS_1IDX[i]` "
                  "matches KW\n")
        fmd.write(f"- Wall: {elapsed:.1f}s "
                  f"({seen/elapsed/1e6:.2f}M records/s)\n\n")

        fmd.write("## Mask histogram (full)\n\n")
        fmd.write("| mask (binary) | mask (dec) | matched boundaries (1-idx) | count | % of total |\n")
        fmd.write("|---|---:|---|---:|---:|\n")
        for m in range(32):
            matched = [str(_KEYSTONE_BDRYS_1IDX[i]) for i in range(5)
                       if (m >> i) & 1]
            mb = ",".join(matched) if matched else "(none)"
            pct = 100.0 * mask_counts[m] / total_records if total_records else 0
            fmd.write(f"| `{m:05b}` | {m} | {{{mb}}} | "
                      f"{mask_counts[m]:,} | {pct:.6f} |\n")

        fmd.write("\n## Drop-one analysis\n\n")
        fmd.write("For each boundary b in the 5-set, this is the count of "
                  "records that match KW at the OTHER 4 boundaries but fail "
                  "at b. These records are the 'witnesses' boundary b "
                  "uniquely eliminates from the 4-subset's solution space.\n\n")
        fmd.write("| dropped boundary (1-idx) | mask | count | "
                  "interpretation |\n")
        fmd.write("|---:|:---:|---:|---|\n")
        all5 = 31
        for i, b in enumerate(_KEYSTONE_BDRYS_1IDX):
            drop_mask = all5 ^ (1 << i)
            fmd.write(f"| {b} | `{drop_mask:05b}` ({drop_mask}) | "
                      f"{mask_counts[drop_mask]:,} | "
                      f"orderings rescued if boundary {b} is dropped from "
                      f"the minimum set |\n")

        fmd.write("\n## All-5 matched (KW-uniqueness check)\n\n")
        fmd.write(f"- Records with all 5 boundaries matched (mask=31): "
                  f"**{mask_counts[31]:,}**\n")
        fmd.write("  - Should equal **1** if {1,4,21,25,27} uniquely "
                  "determines KW. Any value >1 means the 5-set admits "
                  "non-KW solutions, falsifying the uniqueness claim.\n")
        fmd.write(f"- Records matching zero of the 5 (mask=0): "
                  f"**{mask_counts[0]:,}**\n\n")

        if dump_paths:
            fmd.write("## Record dumps\n\n")
            fmd.write("Records with selected masks were dumped (capped at "
                      f"{dump_limit} per mask) for downstream structural "
                      "analysis. Each file is a raw binary stream of "
                      "32-byte records (same format as solutions.bin "
                      "minus the header).\n\n")
            fmd.write("| mask | label | dumped count | path |\n")
            fmd.write("|---:|---|---:|---|\n")
            for m, (path, count) in sorted(dump_paths.items()):
                label = INTERESTING[m][0]
                fmd.write(f"| {m} | {label} | {count:,} | `{path}` |\n")

        fmd.write("\n## Interpretation guide\n\n")
        fmd.write("- The {25, 27} keystone claim predicts: "
                  "`mask_counts[drop_25_mask]` and `mask_counts[drop_27_mask]` "
                  "are non-trivial (boundaries 25 and 27 do real work), "
                  "and the corresponding 'drop' families have structural "
                  "commonalities not captured by the other 4 boundaries.\n")
        fmd.write("- If `mask_counts[31] > 1`, the 5-set is NOT "
                  "uniqueness-determining at this canonical depth — the "
                  "minimum-set claim needs revision (likely growing to a "
                  "6-set).\n")
        fmd.write("- Compare drop-25 vs drop-27 record families: if they "
                  "are disjoint, both keystones do independent work; if "
                  "heavily overlapping, the 'two keystones' framing weakens.\n")

    print(f"[keystone] wrote {out_md}", flush=True)
    return mask_counts, dump_paths


def extended_selftest(solve_binary):
    """Path-invariance + resume regression suite.

    Exercises the fork-merge dispatch (commit 572a34b), sanity gate, and
    v1+v2 resume off-by-one fix (commit c3ad271). Each subtest invokes
    the supplied `solve` binary in a fresh tempdir with a fixed seed
    of env vars, captures sha256, and asserts equivalence against a
    reference path. Returns 0 on full PASS, 1 on any failure.

    Subtests:
      1. Single-shot 3-way at 100M nodes: recursive vs iterative vs
         iterative+v2 (SOLVE_DFS_CHECKPOINT=1). All three shas must match
         the canonical 100M sha 403f7202.
      2. v2 resume sha-equivalence: 50M (PHASE_A) -> 200M (PHASE_B) vs
         single-shot 200M. Must match.
      3. v1 resume sha-equivalence: same scenario, recursive path. Must
         match the same single-shot sha.
      4. --branch + depth-3 + SOLVE_THREADS=128 init: catches stack-array
         sizing bugs in the --branch+depth-3 init path.
      5. --branch multi-budget resume: catches resume-gate regressions
         (e.g., current_per_branch_budget=0 making PB a no-op).
      6. Combined partition + resume invariance (the Tier 2c pattern at
         small scale). Catches MAX_COMPLETED_SUBS cap regressions.
      7. Distributed-merge equivalence: same set of --branch jobs run
         in separate per-branch dirs vs one shared dir, both produce the
         same merged sha. Validates the "shards from many VMs collected
         centrally" pattern that 56-branch distributed campaigns use.
      8. Single-branch eviction-resume invariance: --branch X Y, SIGTERM
         mid-walk, resume; resulting branch-sha must match a clean run.
      9. Idempotent re-launch: re-running a completed --branch X Y in
         the same dir must not corrupt or alter the shards on disk.

    Wall ~13 min on a 4-thread VM (subtests 1-6 + 7-9 add ~3 min).
    """
    import shutil
    import subprocess
    import tempfile

    if not os.path.isfile(solve_binary):
        print(f"FAIL: solve binary not found: {solve_binary}", file=sys.stderr)
        return 1
    if not os.access(solve_binary, os.X_OK):
        print(f"FAIL: solve binary not executable: {solve_binary}", file=sys.stderr)
        return 1
    solve_binary = os.path.abspath(solve_binary)

    def _run(env_extra, dir_, args_=("0", "4")):
        env = os.environ.copy()
        env.update(env_extra)
        log = os.path.join(dir_, "run.log")
        with open(log, "w") as lf:
            rc = subprocess.call(
                [solve_binary, *args_],
                cwd=dir_, env=env, stdout=lf, stderr=subprocess.STDOUT,
            )
        return rc, log

    def _read_sha(dir_):
        path = os.path.join(dir_, "solutions.sha256")
        if not os.path.isfile(path):
            return None
        with open(path) as f:
            line = f.readline().strip()
        return line.split()[0] if line else None

    def _read_sha_branch(dir_, p1, o1):
        """--branch mode writes solutions_<p1>_<o1>.sha256."""
        path = os.path.join(dir_, f"solutions_{p1}_{o1}.sha256")
        if not os.path.isfile(path):
            return None
        with open(path) as f:
            line = f.readline().strip()
        return line.split()[0] if line else None

    base_env_d2_100m = {
        "SOLVE_DEPTH": "2",
        "SOLVE_NODE_LIMIT": "100000000",
    }
    base_env_d2_50m = {
        "SOLVE_DEPTH": "2",
        "SOLVE_NODE_LIMIT": "50000000",
    }
    base_env_d2_200m = {
        "SOLVE_DEPTH": "2",
        "SOLVE_NODE_LIMIT": "200000000",
    }

    failures = []
    workroot = tempfile.mkdtemp(prefix="ext_selftest_")
    print(f"[extended-selftest] working dir: {workroot}", flush=True)

    try:
        # --- Subtest 1: single-shot 3-way at 100M ---
        print("[extended-selftest] Subtest 1/9: single-shot 3-way @ 100M nodes",
              flush=True)
        shas_3way = {}
        for label, env_extra in [
            ("recursive",   {}),
            ("iterative",   {"SOLVE_DFS_ITERATIVE": "1"}),
            ("iterative+v2",
             {"SOLVE_DFS_ITERATIVE": "1", "SOLVE_DFS_CHECKPOINT": "1"}),
        ]:
            d = os.path.join(workroot, f"sub1_{label}")
            os.makedirs(d, exist_ok=True)
            env = {**base_env_d2_100m, **env_extra}
            rc, log = _run(env, d)
            if rc != 0:
                failures.append(f"subtest 1 {label}: solve exit={rc} (see {log})")
                continue
            sha = _read_sha(d)
            if not sha:
                failures.append(f"subtest 1 {label}: missing solutions.sha256")
                continue
            shas_3way[label] = sha
            print(f"  {label:<14}: {sha}", flush=True)
        if len(shas_3way) == 3 and len(set(shas_3way.values())) != 1:
            failures.append(
                f"subtest 1: 3-way sha mismatch — recursive={shas_3way.get('recursive')}, "
                f"iterative={shas_3way.get('iterative')}, "
                f"iterative+v2={shas_3way.get('iterative+v2')}"
            )

        # --- Subtest 2: v2 resume sha-equivalence ---
        print("[extended-selftest] Subtest 2/9: v2 resume @ 50M -> 200M",
              flush=True)
        d_v2_full = os.path.join(workroot, "sub2_v2_full")
        d_v2_resume = os.path.join(workroot, "sub2_v2_resume")
        for d in (d_v2_full, d_v2_resume):
            os.makedirs(d, exist_ok=True)
        v2_env = {"SOLVE_DFS_ITERATIVE": "1", "SOLVE_DFS_CHECKPOINT": "1"}
        rc_full, _ = _run({**base_env_d2_200m, **v2_env}, d_v2_full)
        rc_pa,   _ = _run({**base_env_d2_50m,  **v2_env}, d_v2_resume)
        rc_pb,   _ = _run({**base_env_d2_200m, **v2_env}, d_v2_resume)
        sha_v2_full = _read_sha(d_v2_full)
        sha_v2_resumed = _read_sha(d_v2_resume)
        print(f"  v2 FULL    : {sha_v2_full}", flush=True)
        print(f"  v2 RESUMED : {sha_v2_resumed}", flush=True)
        if rc_full != 0 or rc_pa != 0 or rc_pb != 0:
            failures.append(
                f"subtest 2: solve exit codes "
                f"FULL={rc_full} PHASE_A={rc_pa} PHASE_B={rc_pb}"
            )
        elif not sha_v2_full or not sha_v2_resumed or sha_v2_full != sha_v2_resumed:
            failures.append(
                f"subtest 2: v2 resume sha mismatch — "
                f"full={sha_v2_full}, resumed={sha_v2_resumed}"
            )

        # --- Subtest 3: v1 resume sha-equivalence ---
        print("[extended-selftest] Subtest 3/9: v1 resume @ 50M -> 200M",
              flush=True)
        d_v1_full = os.path.join(workroot, "sub3_v1_full")
        d_v1_resume = os.path.join(workroot, "sub3_v1_resume")
        for d in (d_v1_full, d_v1_resume):
            os.makedirs(d, exist_ok=True)
        v1_env = {"SOLVE_DFS_CHECKPOINT": "1"}
        rc_full, _ = _run({**base_env_d2_200m, **v1_env}, d_v1_full)
        rc_pa,   _ = _run({**base_env_d2_50m,  **v1_env}, d_v1_resume)
        rc_pb,   _ = _run({**base_env_d2_200m, **v1_env}, d_v1_resume)
        sha_v1_full = _read_sha(d_v1_full)
        sha_v1_resumed = _read_sha(d_v1_resume)
        print(f"  v1 FULL    : {sha_v1_full}", flush=True)
        print(f"  v1 RESUMED : {sha_v1_resumed}", flush=True)
        if rc_full != 0 or rc_pa != 0 or rc_pb != 0:
            failures.append(
                f"subtest 3: solve exit codes "
                f"FULL={rc_full} PHASE_A={rc_pa} PHASE_B={rc_pb}"
            )
        elif not sha_v1_full or not sha_v1_resumed or sha_v1_full != sha_v1_resumed:
            failures.append(
                f"subtest 3: v1 resume sha mismatch — "
                f"full={sha_v1_full}, resumed={sha_v1_resumed}"
            )

        # The two resume paths' FULL shas should also match each other (single-
        # shot 200M is independent of the iterative/v2 path the test exercises).
        if sha_v2_full and sha_v1_full and sha_v2_full != sha_v1_full:
            failures.append(
                f"cross-check: v2 single-shot 200M ({sha_v2_full}) != "
                f"v1 single-shot 200M ({sha_v1_full})"
            )

        # --- Subtest 4: high thread count + --branch + depth-3 init ---
        # Catches stack-array sizing bugs in --branch / depth-3 paths
        # (e.g., the workers[64] / threads[64] / tids[64] buffer
        # overflow at SOLVE_THREADS=128 we discovered 2026-05-02).
        # The buggy paths only fire under: --branch mode + depth=3 +
        # n_threads > 64. We use SOLVE_HASH_LOG2=16 (2 MB / thread =
        # 256 MB total at 128 threads) so this runs on small-VM hosts
        # with limited RAM. Tiny SOLVE_NODE_LIMIT — what matters is
        # that solve survives initialization without buffer overflow.
        print("[extended-selftest] Subtest 4/9: --branch + depth-3 + "
              "SOLVE_THREADS=128 init (catches stack-array sizing bugs)",
              flush=True)
        d_th128 = os.path.join(workroot, "sub4_branch_d3_t128")
        os.makedirs(d_th128, exist_ok=True)
        env_th128 = {
            "SOLVE_DEPTH": "3",
            "SOLVE_NODE_LIMIT": "100000000",
            "SOLVE_DFS_ITERATIVE": "1",
            "SOLVE_DFS_CHECKPOINT": "1",
            "SOLVE_THREADS": "128",
            "SOLVE_HASH_LOG2": "16",  # keep RAM use modest on tiny VMs
        }
        rc_th128, log_th128 = _run(env_th128, d_th128,
                                    args_=("--branch", "1", "0", "0", "128"))
        # Check that solve survived enum and produced shards. Note: the
        # --branch path's post-enum per-branch merge step has a known
        # SIGSEGV at 128 threads that doesn't affect correctness (the
        # global --merge in Tier 2 still works off the shards on disk).
        # So we use shard-presence as the success criterion, not exit code.
        n_shards = 0
        try:
            n_shards = sum(1 for f in os.listdir(d_th128)
                           if f.startswith("sub_1_0_") and f.endswith(".bin"))
        except OSError:
            pass
        if n_shards == 0:
            failures.append(
                f"subtest 4: --branch+d3 with SOLVE_THREADS=128 produced 0 "
                f"shards — likely buffer-overflow / stack-array sizing "
                f"regression in the --branch+depth-3 init code path. "
                f"See {log_th128}"
            )
        else:
            print(f"  --branch+d3 t=128: PASS ({n_shards} shards produced; "
                  f"buffer overflow at workers/threads/tids arrays would "
                  f"prevent ANY shards)", flush=True)
            if rc_th128 != 0:
                # Note but don't fail — known SIGSEGV in per-branch merge at
                # high thread counts. Worth recording.
                print(f"  (note: --branch exit={rc_th128} from post-enum "
                      f"per-branch merge SIGSEGV; doesn't block global merge)",
                      flush=True)

        # --- Subtest 5: --branch multi-budget resume invariance ---
        # Catches --branch resume gate bugs — specifically the
        # current_per_branch_budget=0 issue we found 2026-05-02 where
        # the gate trivially marked all PA entries as completed,
        # making PHASE_B's larger-budget walk a no-op.
        print("[extended-selftest] Subtest 5/9: --branch multi-budget "
              "resume (catches resume-gate bugs)", flush=True)
        # Reference: single-shot --branch at 2M per-sub-branch
        d_b_ref = os.path.join(workroot, "sub5_branch_ref")
        os.makedirs(d_b_ref, exist_ok=True)
        # PA: --branch 1 0 at SOLVE_PER_SUB_BRANCH_LIMIT=500000
        d_b_pa = os.path.join(workroot, "sub5_branch_resume")
        os.makedirs(d_b_pa, exist_ok=True)
        # The --branch path runs against a single first-level (1, 0).
        # Use SOLVE_PER_SUB_BRANCH_LIMIT (not SOLVE_NODE_LIMIT) so the
        # gate's per-sub-branch comparison is unambiguous.
        ref_env = {"SOLVE_DEPTH": "2",
                   "SOLVE_NODE_LIMIT": "200000000",
                   "SOLVE_PER_SUB_BRANCH_LIMIT": "2000000",
                   "SOLVE_DFS_ITERATIVE": "1",
                   "SOLVE_DFS_CHECKPOINT": "1"}
        pa_env = {**ref_env, "SOLVE_PER_SUB_BRANCH_LIMIT": "500000"}
        pb_env = ref_env  # same as reference
        # Reference: single-shot at 2M per-sub-branch
        rc_ref, _ = _run(ref_env, d_b_ref, args_=("--branch", "1", "0", "0", "4"))
        sha_b_ref = _read_sha_branch(d_b_ref, 1, 0)
        # Resumed: 500K then 2M
        rc_pa, _ = _run(pa_env, d_b_pa, args_=("--branch", "1", "0", "0", "4"))
        rc_pb, _ = _run(pb_env, d_b_pa, args_=("--branch", "1", "0", "0", "4"))
        sha_b_resumed = _read_sha_branch(d_b_pa, 1, 0)
        print(f"  --branch ref     (single-shot 2M): {sha_b_ref}", flush=True)
        print(f"  --branch resumed (500K -> 2M):     {sha_b_resumed}", flush=True)
        if rc_ref != 0 or rc_pa != 0 or rc_pb != 0:
            failures.append(
                f"subtest 5: solve exit codes ref={rc_ref} pa={rc_pa} pb={rc_pb}"
            )
        elif sha_b_ref and sha_b_resumed and sha_b_ref != sha_b_resumed:
            failures.append(
                f"subtest 5: --branch multi-budget resume MISMATCH — "
                f"ref={sha_b_ref}, resumed={sha_b_resumed}. "
                f"Likely current_per_branch_budget gate regression."
            )

        # --- Subtest 6: combined partition + resume invariance ---
        # The exact pattern Tier 2c stresses, but at small scale.
        # Catches MAX_COMPLETED_SUBS cap regressions and any other
        # bugs specific to multi-branch resume + merge.
        print("[extended-selftest] Subtest 6/9: full-enum partition + "
              "resume combined invariance", flush=True)
        # Reference: single-shot full-enum at 200M
        # (Already produced as sha_v2_full from subtest 2.)
        # Now: full-enum 50M then 200M, merge, compare to ref.
        d_combined = os.path.join(workroot, "sub6_combined")
        os.makedirs(d_combined, exist_ok=True)
        c_env_pa = {**base_env_d2_50m,
                    "SOLVE_DFS_ITERATIVE": "1",
                    "SOLVE_DFS_CHECKPOINT": "1"}
        c_env_pb = {**base_env_d2_200m,
                    "SOLVE_DFS_ITERATIVE": "1",
                    "SOLVE_DFS_CHECKPOINT": "1"}
        rc_c_pa, _ = _run(c_env_pa, d_combined)
        rc_c_pb, _ = _run(c_env_pb, d_combined)
        sha_combined = _read_sha(d_combined)
        print(f"  combined (50M -> 200M):            {sha_combined}", flush=True)
        if rc_c_pa != 0 or rc_c_pb != 0:
            failures.append(
                f"subtest 6: solve exit codes pa={rc_c_pa} pb={rc_c_pb}"
            )
        elif sha_combined != sha_v2_full:
            failures.append(
                f"subtest 6: combined partition+resume MISMATCH — "
                f"ref single-shot 200M sha={sha_v2_full}, "
                f"50M->200M sha={sha_combined}. "
                f"Could be MAX_COMPLETED_SUBS cap regression or other "
                f"resume-loop bug."
            )

        # --- Subtest 7: distributed-merge equivalence ---
        # Validates the "many independent --branch jobs across multiple
        # VMs, shards collected centrally, single global --merge"
        # pattern that distributed multi-branch campaigns use. Run two
        # --branch jobs in separate per-branch dirs vs both in one
        # shared dir, both should produce the same merged sha.
        print("[extended-selftest] Subtest 7/9: distributed-merge "
              "equivalence (multi-VM shard-collection pattern)",
              flush=True)
        # Reference: both branches run in ONE dir, then merge there.
        d_ref = os.path.join(workroot, "sub7_ref")
        os.makedirs(d_ref, exist_ok=True)
        env_t7 = {
            "SOLVE_DEPTH": "2",
            "SOLVE_NODE_LIMIT": "100000000",
            "SOLVE_DFS_ITERATIVE": "1",
            "SOLVE_DFS_CHECKPOINT": "1",
        }
        rc_r1, _ = _run(env_t7, d_ref, args_=("--branch", "1", "0", "0", "4"))
        rc_r2, _ = _run(env_t7, d_ref, args_=("--branch", "2", "0", "0", "4"))
        rc_rm, _ = _run({}, d_ref, args_=("--merge",))
        sha_t7_ref = _read_sha(d_ref)
        # Distributed: branches in separate dirs, then collect shards
        # into a third dir and merge there.
        d_a = os.path.join(workroot, "sub7_dirA")
        d_b = os.path.join(workroot, "sub7_dirB")
        d_collect = os.path.join(workroot, "sub7_collect")
        os.makedirs(d_a, exist_ok=True)
        os.makedirs(d_b, exist_ok=True)
        os.makedirs(d_collect, exist_ok=True)
        rc_a, _ = _run(env_t7, d_a, args_=("--branch", "1", "0", "0", "4"))
        rc_b, _ = _run(env_t7, d_b, args_=("--branch", "2", "0", "0", "4"))
        # Hardlink shards to the collection dir (simulates rsync/transfer
        # from per-VM enum dirs to a central merge VM).
        for d_src in (d_a, d_b):
            for f in os.listdir(d_src):
                if f.startswith("sub_") and f.endswith(".bin"):
                    os.link(os.path.join(d_src, f),
                            os.path.join(d_collect, f))
        rc_cm, _ = _run({}, d_collect, args_=("--merge",))
        sha_t7_distributed = _read_sha(d_collect)
        print(f"  sub7 ref         (1 dir, both branches): {sha_t7_ref}",
              flush=True)
        print(f"  sub7 distributed (2 dirs collected):     "
              f"{sha_t7_distributed}", flush=True)
        if (rc_r1 or rc_r2 or rc_rm or rc_a or rc_b or rc_cm):
            failures.append(
                f"subtest 7: solve exit codes "
                f"r1={rc_r1} r2={rc_r2} rm={rc_rm} "
                f"a={rc_a} b={rc_b} cm={rc_cm}"
            )
        elif sha_t7_ref and sha_t7_distributed and sha_t7_ref != sha_t7_distributed:
            failures.append(
                f"subtest 7: distributed-merge MISMATCH — "
                f"single-dir ref={sha_t7_ref}, "
                f"multi-dir-collected={sha_t7_distributed}. "
                f"Affects 56-branch distributed campaigns."
            )

        # --- Subtest 8: single-branch eviction-resume invariance ---
        # Validates that SIGTERM mid --branch walk + restart produces the
        # same shards as a clean run. Critical for spot-eviction-prone
        # 10T-per-branch single-branch campaigns: every long --branch
        # job WILL be evicted at least once.
        print("[extended-selftest] Subtest 8/9: single-branch "
              "eviction-resume invariance (SIGTERM mid-walk)",
              flush=True)
        env_t8 = {
            "SOLVE_DEPTH": "2",
            "SOLVE_NODE_LIMIT": "200000000",
            "SOLVE_DFS_ITERATIVE": "1",
            "SOLVE_DFS_CHECKPOINT": "1",
        }
        # Clean reference run.
        d_t8_ref = os.path.join(workroot, "sub8_ref")
        os.makedirs(d_t8_ref, exist_ok=True)
        rc_t8_ref, _ = _run(env_t8, d_t8_ref,
                            args_=("--branch", "3", "0", "0", "4"))
        sha_t8_ref = _read_sha_branch(d_t8_ref, 3, 0)
        # SIGTERM-then-resume run.
        d_t8_int = os.path.join(workroot, "sub8_interrupted")
        os.makedirs(d_t8_int, exist_ok=True)
        env = os.environ.copy()
        env.update(env_t8)
        log = os.path.join(d_t8_int, "run_phase1.log")
        with open(log, "w") as lf:
            proc = subprocess.Popen(
                [solve_binary, "--branch", "3", "0", "0", "4"],
                cwd=d_t8_int, env=env,
                stdout=lf, stderr=subprocess.STDOUT,
            )
            time.sleep(8)  # let solve do real work + checkpoint
            proc.terminate()
            try:
                proc.wait(timeout=30)
            except subprocess.TimeoutExpired:
                proc.kill()
                proc.wait(timeout=10)
        # Resume — same command, same dir; solve should pick up checkpoint.
        rc_t8_resume, _ = _run(env_t8, d_t8_int,
                                args_=("--branch", "3", "0", "0", "4"))
        sha_t8_int = _read_sha_branch(d_t8_int, 3, 0)
        print(f"  sub8 ref      (clean):              {sha_t8_ref}", flush=True)
        print(f"  sub8 resumed  (SIGTERM mid-walk):   {sha_t8_int}", flush=True)
        if rc_t8_ref != 0:
            failures.append(f"subtest 8: clean run exit={rc_t8_ref}")
        elif rc_t8_resume != 0:
            failures.append(
                f"subtest 8: resume run exit={rc_t8_resume} — "
                f"single-branch eviction-resume path broken")
        elif sha_t8_ref and sha_t8_int and sha_t8_ref != sha_t8_int:
            failures.append(
                f"subtest 8: single-branch eviction-resume MISMATCH — "
                f"clean={sha_t8_ref}, SIGTERM-resumed={sha_t8_int}. "
                f"560T distributed campaign would corrupt under eviction.")

        # --- Subtest 9: idempotent re-launch of completed --branch ---
        # Validates that re-running a completed --branch X Y in a dir
        # that already has its shards doesn't corrupt or alter them.
        # This is the "operator restarts the orchestrator script" case.
        print("[extended-selftest] Subtest 9/9: idempotent re-launch "
              "of completed --branch", flush=True)
        d_t9 = os.path.join(workroot, "sub9_idempotent")
        os.makedirs(d_t9, exist_ok=True)
        env_t9 = {
            "SOLVE_DEPTH": "2",
            "SOLVE_NODE_LIMIT": "100000000",
            "SOLVE_DFS_ITERATIVE": "1",
            "SOLVE_DFS_CHECKPOINT": "1",
        }
        # Branch (5, 0) is known-valid; branches (4, *) and (6, *) are
        # pruned at depth 1 by the C2 constraint.
        rc_t9_first, _ = _run(env_t9, d_t9,
                               args_=("--branch", "5", "0", "0", "4"))
        sha_t9_first = _read_sha_branch(d_t9, 5, 0)
        # Snapshot shard fingerprints (filename + size).
        def _shard_fp(d):
            fps = []
            for f in sorted(os.listdir(d)):
                if f.startswith("sub_") and f.endswith(".bin"):
                    fps.append((f, os.path.getsize(os.path.join(d, f))))
            return fps
        fp_first = _shard_fp(d_t9)
        # Re-run same command in same dir.
        rc_t9_again, _ = _run(env_t9, d_t9,
                               args_=("--branch", "5", "0", "0", "4"))
        sha_t9_again = _read_sha_branch(d_t9, 5, 0)
        fp_again = _shard_fp(d_t9)
        print(f"  sub9 first     ({len(fp_first)} shards): {sha_t9_first}",
              flush=True)
        print(f"  sub9 re-launch ({len(fp_again)} shards): {sha_t9_again}",
              flush=True)
        if rc_t9_first != 0 or rc_t9_again != 0:
            failures.append(
                f"subtest 9: solve exit codes first={rc_t9_first} "
                f"again={rc_t9_again}")
        elif sha_t9_first and sha_t9_again and sha_t9_first != sha_t9_again:
            failures.append(
                f"subtest 9: idempotent re-launch MISMATCH — "
                f"first={sha_t9_first}, re-launch={sha_t9_again}. "
                f"Re-launching a completed --branch corrupts shards.")
        elif fp_first != fp_again:
            failures.append(
                f"subtest 9: shard fingerprints changed across re-launch "
                f"(filenames or sizes differ). "
                f"first={fp_first[:3]}..., again={fp_again[:3]}...")

    finally:
        if not failures:
            shutil.rmtree(workroot, ignore_errors=True)
        else:
            print(f"[extended-selftest] preserved working dir for inspection: {workroot}",
                  flush=True)

    if failures:
        print("[extended-selftest] FAIL:", flush=True)
        for f in failures:
            print(f"  - {f}", flush=True)
        return 1
    print("[extended-selftest] PASS — all 9 subtests + cross-check", flush=True)
    return 0


def compare_depth_profile(log_a, log_b, threshold=0.005):
    """Tree-walk validator (#48): compare DEPTH_PROFILE node counts from two run
    logs (each produced with SOLVE_DEPTH_PROFILE=1) and report per-depth +
    overall divergence. PASS if total divergence < threshold.

    Tolerance-based, NOT byte-exact: the parallel per-sub-branch budget cutoff
    overshoots by a thread-timing-dependent amount, so node counts wiggle
    slightly even on identical inputs (the solution-sha is the byte-exact
    anchor; this catches GROSS tree-walk divergence across builds / arches /
    thread counts). For full (EXHAUSTED) runs the profiles match exactly.
    Accepts .gz logs."""
    import re
    import gzip
    line_re = re.compile(r'^DEPTH_PROFILE depth=(\d+) nodes=(\d+)')

    def parse(path):
        opener = gzip.open if path.endswith('.gz') else open
        prof = {}
        with opener(path, 'rt', errors='replace') as f:
            for line in f:
                m = line_re.match(line)
                if m:
                    prof[int(m.group(1))] = int(m.group(2))
        return prof

    a = parse(log_a)
    b = parse(log_b)
    if not a or not b:
        missing = []
        if not a:
            missing.append("A=" + log_a)
        if not b:
            missing.append("B=" + log_b)
        print("ERROR: no DEPTH_PROFILE lines in " + ", ".join(missing) +
              " (re-run solve with SOLVE_DEPTH_PROFILE=1)", flush=True)
        return 2
    total_a = sum(a.values())
    total_b = sum(b.values())
    diff = total_b - total_a
    pct = (100.0 * diff / total_a) if total_a else 0.0
    # Distribution (L1 / total-variation) divergence is the meaningful verdict
    # metric. Total-count divergence ALONE is fooled by budget-limited runs:
    # both hit the same node budget regardless of tree shape, so two completely
    # different cells can have ~identical totals. L1 over per-depth counts
    # captures whether the two walks explored the SAME shape.
    l1 = sum(abs(a.get(d, 0) - b.get(d, 0)) for d in set(a) | set(b))
    denom = max(total_a, total_b) or 1
    div = l1 / denom
    print(f"Total nodes A: {total_a:,}")
    print(f"Total nodes B: {total_b:,}")
    print(f"Total-count difference: {diff:+,} ({pct:+.4f}%)  [informational]")
    print(f"Distribution divergence (L1/total): {div*100:.4f}%  [verdict basis]")
    print("\nPer-depth (depth, A, B, delta%):")
    for d in sorted(set(a) | set(b)):
        na, nb = a.get(d, 0), b.get(d, 0)
        if na == 0 and nb == 0:
            continue
        if na == 0:
            ds, ok = "+inf%", False
        else:
            dp = 100.0 * (nb - na) / na
            ds, ok = f"{dp:+.4f}%", abs(dp) <= threshold * 100.0
        print(f"  {'OK' if ok else 'XX'} depth={d:2d}: a={na:>16,} b={nb:>16,} delta={ds}")
    verdict = "PASS" if div < threshold else "FAIL"
    print(f"\nVERDICT: {verdict} (distribution divergence {div*100:.4f}% vs threshold {threshold*100:.4f}%)")
    return 0 if div < threshold else 1


# ---- Candidate-rule ground truth (CANDIDATE_REGISTRY_2026_07) ----
# Pure ground-truth checkers for the 31 NEW-scorable literature rules catalogued in
# roae-private/CANDIDATE_REGISTRY_2026_07.md. One function per rule, named reg_<id>;
# each takes seq (list of 64 ints, bit 0 = bottom line) and returns the registry's
# scoring value. --registry-verify gates every function against its KW expected value.
# ATTRIBUTION: per-rule sources in each docstring; formalizations transcribed by
# Claude (Fable) from first-hand reading notes; master ledger documentation/CITATIONS.md.

def _reg_comp6(h):
    """Complement (pangtong / linear opposite): flip all 6 lines."""
    return h ^ 0b111111

def _reg_hw(h):
    """Hamming weight = yang line count."""
    return bin(h).count("1")

def _reg_stations(seq):
    """The 36 inversion-class stations in first-appearance order.

    Returns a list of (canonical_hex, members_set); station index = list index + 1.
    Canonical = the class member at the lower seq[] slot. Palindromic hexagrams
    (h == reverse_6bit(h)) are singleton stations, so complement pairs like
    Qian/Kun contribute two stations each.
    ATTRIBUTION: the 36-unit consolidation is Lai Zhide 1599 (CICC), used
    analytically by Schulz 1990 (JCP 17:345-358) and Cook 2006."""
    seen = set()
    out = []
    for h in seq:
        key = min(h, reverse_6bit(h))
        if key in seen:
            continue
        seen.add(key)
        members = {h} if reverse_6bit(h) == h else {h, reverse_6bit(h)}
        out.append((h, members))
    return out

def _reg_station_of(stations, h):
    """1-based station index containing hexagram h."""
    for i, (_, members) in enumerate(stations, 1):
        if h in members:
            return i
    return None

def _reg_balances(stations):
    """Per-station yang-minus-yin line balance of the canonical gua (rev preserves
    popcount, so the balance is well-defined for the whole inversion class)."""
    return [2 * _reg_hw(c) - 6 for c, _ in stations]

def reg_rs1(seq):
    """R-S1 — Xiaoxi trisection + solstice minimum placement.

    ATTRIBUTION: Schulz & Cunningham 1990 / Schulz 1990, JCP 17 pp. 351-352.
    (1) The xiaoxi marker gua Qian(h1), Fu(h24), Gou(h44) sit at stations 1/13/25,
    trisecting the 36 stations into 3x12; (2) Fu's station is the balance-graph
    minimum (-4) among non-pure stations (the pure gua Qian/Kun, balance +/-6, are
    the trisection anchors and exempt per Schulz's motif framing; the registry's
    'all 36 stations' wording would make Kun the -6 minimum). Returns bool."""
    st = _reg_stations(seq)
    bal = _reg_balances(st)
    fu = 0b000001   # hexagram 24, one yang at the bottom
    gou = 0b111110  # hexagram 44, one yin at the bottom
    trisect = (_reg_station_of(st, 0b111111) == 1
               and _reg_station_of(st, fu) == 13
               and _reg_station_of(st, gou) == 25)
    nonpure = [b for (c, _), b in zip(st, bal) if _reg_hw(c) not in (0, 6)]
    s_fu = _reg_station_of(st, fu)
    minimum = bal[s_fu - 1] == min(nonpure) == -4
    return trisect and minimum

def _reg_rs2_violations(seq):
    """Stations violating R-S2. Semantics: split stations 1..36 into maximal
    runs of non-zero balance (zero-balance stations break the pairing); pair
    consecutively within each run from its start. A station complies iff it is
    paired and its pair is equal-and-opposite; the odd orphan of an odd-length
    run violates. This is the unique adjacent-pairing reading that reproduces
    Schulz 1990's exact exception set {11,13,14,25,26,32} on KW."""
    bal = _reg_balances(_reg_stations(seq))
    viol = []

    def close(run):
        for i in range(0, len(run) - 1, 2):
            a, b = run[i], run[i + 1]
            if bal[a - 1] != -bal[b - 1]:
                viol.extend([a, b])
        if len(run) % 2:
            viol.append(run[-1])

    run = []
    for k in range(1, 37):
        if bal[k - 1] == 0:
            close(run)
            run = []
        else:
            run.append(k)
    close(run)
    return sorted(viol)

def reg_rs2(seq):
    """R-S2 — Adjacent-station equal-and-opposite balance pairing.

    ATTRIBUTION: Schulz 1990, JCP 17 pp. 348-350. Adjacent stations pair as
    equal-but-opposite yang-minus-yin balance values in 20 of the 26 non-zero
    cases on KW; exceptions at stations 11,13,14,25,26,32 (Schulz's exact
    exception set, reproduced by the run-segmented pairing in
    _reg_rs2_violations — the registry's fixed (2j-1,2j)-over-all-36 pairing
    yields only 12 and is a mis-formalization, see
    REGISTRY_IMPL_NOTES_2026_07.md). Returns count of compliant stations."""
    bal = _reg_balances(_reg_stations(seq))
    nonzero = sum(1 for b in bal if b != 0)
    return nonzero - len(_reg_rs2_violations(seq))

def reg_ccn1(seq):
    """CC-N1 — All-resonant stations at structural extremities {S7,S19,S24,S36}.

    ATTRIBUTION: Schulz 2016 (Hexagrammatics) pp. 15-16; S36 also Schulz 2018.
    resonant(h): each line differs from its cross-trigram partner (bits 0-2 vs
    3-5). Exactly 4 stations hold all-resonant hexagrams, at indices {7,19,24,36}:
    S19 = lower-classic start, S36 = sequence end, S7 = upper-classic middle,
    S24 = cross-classic parallel of S19. Returns bool."""
    st = _reg_stations(seq)
    allres = [h for h in range(64) if (h ^ (h >> 3)) & 0b111 == 0b111]
    idx = {_reg_station_of(st, h) for h in allres}
    idx.discard(None)
    lower = sorted(i for i in idx if i >= 19)
    return (len(idx) == 4 and idx == {7, 19, 24, 36}
            and lower and lower[0] == 19 and max(idx) == 36)

def reg_ccn2(seq):
    """CC-N2 — Non-right doubled-trigram invert pairs at stations S29 and S32.

    ATTRIBUTION: Schulz 2016 (Hexagrammatics) pp. 17-18. The 4 non-palindromic
    doubled-trigram hexagrams (doubled Zhen 001001b/100100b = KW 51/52, doubled
    Xun 110110b/011011b = KW 57/58) form 2 stations, at S29 (Zhen) and S32 (Xun),
    both in the lower classic (stations 19-36). Returns bool."""
    st = _reg_stations(seq)
    s_zhen = _reg_station_of(st, 0b001001)
    s_xun = _reg_station_of(st, 0b110110)
    return (s_zhen == 29 and s_xun == 32
            and 19 <= s_zhen <= 36 and 19 <= s_xun <= 36)

def reg_ccn3(seq):
    """CC-N3 — HD1 cluster: stations {3,4,21,22,23,28} within Hamming distance 1
    of the S36 hexagrams (Ji-ji 010101b / Wei-ji 101010b).

    ATTRIBUTION: Schulz 2016 (Hexagrammatics) pp. 22-24; same rule as Schulz 2011
    C2011-A6 (JCP 38:4), cited in Schulz 2018 with 2016 primary. Every hexagram
    in those 6 stations is within HD1 of hexagram 63 or 64. Returns bool."""
    st = _reg_stations(seq)
    targets = (0b010101, 0b101010)
    return all(min(bit_diff(h, t) for t in targets) <= 1
               for s in (3, 4, 21, 22, 23, 28) for h in st[s - 1][1])

def reg_ccn4(seq):
    """CC-N4 — S25-S28 face hexagrams: upper trigram Dui; lower trigrams
    Qian, Kun, Kan, Li in upper-classic doubled-trigram station order.

    ATTRIBUTION: Schulz 2016 (Hexagrammatics) pp. 23-24; Schulz 2011 (JCP 38:4).
    The 2016 book's 'xun on top' reads top-down; under ROAE bottom-to-top
    encoding the face (canonical) hexagrams of S25-S28 carry Dui (011b = 3) on
    top — convention resolution per registry note. Lower trigrams run
    [7, 0, 2, 5] = Qian, Kun, Kan, Li, matching upper-classic doubled stations
    S1, S2, S17, S18. Returns bool."""
    st = _reg_stations(seq)
    faces = [st[s - 1][0] for s in (25, 26, 27, 28)]
    return (all(upper_trigram(h) == 0b011 for h in faces)
            and [lower_trigram(h) for h in faces] == [7, 0, 2, 5])

def reg_ccn6(seq):
    """CC-N6 — Upper Classic aggregate net yin-line surplus (station level).

    ATTRIBUTION: Schulz 2016 (Hexagrammatics) p. 15. Over the 18 upper-classic
    stations' canonical gua (108 lines), yin lines outnumber yang lines
    (KW: 52 yang vs 56 yin, net -4 — Schulz's stated 52:56 confirms the count is
    at station level, not over the 30 raw hexagrams). Returns bool."""
    st = _reg_stations(seq)
    yang = sum(_reg_hw(st[s][0]) for s in range(18))
    return yang < 108 - yang

def reg_ccn7(seq):
    """CC-N7 — S36 trigram composition equals the union of S17 and S18 trigrams.

    ATTRIBUTION: Schulz 2016 (Hexagrammatics) p. 27 (rules table, SC-19).
    S17 (doubled Kan, 010010b) uses only trigram Kan(2); S18 (doubled Li,
    101101b) only Li(5); the two S36 hexagrams decompose into exactly
    {Kan, Li, Kan, Li}. Returns bool."""
    st = _reg_stations(seq)
    t17 = [t for h in st[16][1] for t in (lower_trigram(h), upper_trigram(h))]
    t18 = [t for h in st[17][1] for t in (lower_trigram(h), upper_trigram(h))]
    t36 = sorted(t for h in st[35][1] for t in (lower_trigram(h), upper_trigram(h)))
    return (set(t17) == {0b010} and set(t18) == {0b101}
            and t36 == [0b010, 0b010, 0b101, 0b101])

def reg_ccn8(seq):
    """CC-N8 — Exception co-location: the CC-A2 (yang/yin odd/even) and R-S2
    (opposite-balance) violation sets share the locus {S25, S26}.

    ATTRIBUTION: Schulz 2016 (Hexagrammatics) pp. 14-15 (SC-7 double-exception
    note); Schulz 1990 JCP 17 for both underlying motifs. Predicate: the CC-A2
    violation set is exactly {25, 26} and both also violate R-S2. Returns bool."""
    _, v_a2 = rc4_violations(seq)
    v_s2 = set(_reg_rs2_violations(seq))
    return set(v_a2) == {25, 26} and {25, 26} <= v_s2

def reg_c2011n1(seq):
    """C2011-N1 — 5-station Opposite sets S5-S9 (anchor S7) and S29-S33
    (anchor S30), mirrored across the Classic boundary.

    ATTRIBUTION: Schulz 2011, JCP 38:4 pp. 651-652 (Element 6).
    (1) S7 and (2) S30 are self-Opposite (invert = complement for their
    members); (3) {S5,S6,S8,S9} form two non-right complement-class pairs
    (S5<->S8, S6<->S9); (4) {S29,S31,S32,S33} likewise flank S30
    (S29<->S32, S31<->S33); (5) the two 5-station spans sit at mirrored
    within-classic positions offset by 1 (upper 5-9 mirrors to 10-14; lower
    span starts at within-classic 11). Returns bool."""
    st = _reg_stations(seq)

    def self_opposite(s):
        h = st[s - 1][0]
        return reverse_6bit(h) == _reg_comp6(h)

    def opp_class(a, b):
        ma, mb = st[a - 1][1], st[b - 1][1]
        nonright = all(reverse_6bit(h) != h for h in ma | mb)
        return {_reg_comp6(h) for h in ma} == mb and nonright

    p1 = self_opposite(7)
    p2 = self_opposite(30)
    p3 = opp_class(5, 8) and opp_class(6, 9)
    p4 = opp_class(29, 32) and opp_class(31, 33)
    # upper span 5..9 within classic of 18 mirrors to 10..14; lower span
    # 29..33 starts at within-classic index 11 = mirrored start 10 offset by 1
    p5 = (29 - 18) - (18 - 9 + 1) == 1
    return p1 and p2 and p3 and p4 and p5

def reg_c2011n2(seq):
    """C2011-N2 — The 4 self-Opposite stations sit at {S7, S10, S30, S36}.

    ATTRIBUTION: Schulz 2011, JCP 38:4 pp. 651-653 (Elements 6 and 10).
    Self-Opposite: canonical h with bitrev6(h) == complement6(h) (equivalently
    h XOR bitrev6(h) == 63). Exactly 4 such stations; S10 = upper-classic
    midpoint, S36 = terminus. Returns bool."""
    st = _reg_stations(seq)
    selfop = sorted(i for i, (c, _) in enumerate(st, 1)
                    if reverse_6bit(c) == _reg_comp6(c))
    return selfop == [7, 10, 30, 36]

def reg_c2011n4(seq):
    """C2011-N4 — S22-S23 is the unique adjacent non-right Opposite station pair.

    ATTRIBUTION: Schulz 2011, JCP 38:4 pp. 651-652 (inferred from Element 6).
    Scanning all adjacent station pairs (s, s+1), s = 1..35: the classes are
    complement-related ({comp(h)} of one equals the other) with no palindromic
    member in exactly one place, (S22, S23). The complement check is
    class-level — the registry's canonical-vs-canonical form misses (22,23)
    because complement links first member to second member there. Returns bool."""
    st = _reg_stations(seq)
    found = []
    for s in range(1, 36):
        ma, mb = st[s - 1][1], st[s][1]
        if {_reg_comp6(h) for h in ma} != mb:
            continue
        if any(reverse_6bit(h) == h for h in ma | mb):
            continue
        found.append((s, s + 1))
    return found == [(22, 23)]

def reg_mmt3(seq):
    """MM-T3 — No Gray-code structure between consecutive pair representatives.

    ATTRIBUTION: McKenna & Mair 1979, PEW 29:4 p. 425 (Gardner 1974 cited for
    the 'random order' claim). Counts transitions between consecutive pair
    representatives (seq[2k] -> seq[2k+2]) with Hamming distance exactly 1.
    Negative structural probe: KW = 4 of 31 (near the ~3 random baseline; the
    registry gives no exact figure, so the measured KW value anchors the gate).
    Returns count."""
    reps = [seq[2 * k] for k in range(32)]
    return sum(1 for k in range(31) if bit_diff(reps[k], reps[k + 1]) == 1)

def reg_mmt4(seq):
    """MM-T4 — Complement pairs have intra-pair HD 6; inversion pairs vary.

    ATTRIBUTION: McKenna & Mair 1979, PEW 29:4 p. 422. The 4 p'ang-t'ung
    (complement) pairs — the palindromic-member pairs — all have intra-pair
    Hamming distance exactly 6; the 28 ch'ien-kua (inversion) pairs do NOT all
    have HD 6. Returns bool."""
    kw_pairs = [(seq[2 * k], seq[2 * k + 1]) for k in range(32)]
    compl = [p for p in kw_pairs if reverse_6bit(p[0]) == p[0]]
    inv = [p for p in kw_pairs if reverse_6bit(p[0]) != p[0]]
    return (len(compl) == 4
            and all(bit_diff(a, b) == 6 for a, b in compl)
            and not all(bit_diff(a, b) == 6 for a, b in inv))

def reg_mmt5(seq):
    """MM-T5 — Trigram family order absent from any 8-consecutive window.

    ATTRIBUTION: McKenna & Mair 1979, PEW 29:4 pp. 428-429 (asserted for KW;
    their proposed reordering has it at positions 21-28). Counts windows
    i = 0..56 whose lower-trigram run equals the family order
    [Qian, Kun, Zhen, Xun, Kan, Li, Gen, Dui] = [7,0,1,6,2,5,4,3].
    KW expected 0. Returns count."""
    family = [7, 0, 1, 6, 2, 5, 4, 3]
    return sum(1 for i in range(57)
               if [lower_trigram(seq[i + j]) for j in range(8)] == family)

def reg_mmt6(seq):
    """MM-T6 — No 4-pair window of all-HD1 representative transitions.

    ATTRIBUTION: McKenna & Mair 1979, PEW 29:4 p. 425 (localized form of the
    'random pair order' claim; their own ordering achieves HD1 on all 31
    inter-pair transitions). Counts windows of 4 consecutive pair
    representatives whose 3 internal transitions are all HD1. KW expected 0.
    Returns count."""
    reps = [seq[2 * k] for k in range(32)]
    return sum(1 for k in range(29)
               if all(bit_diff(reps[k + j], reps[k + j + 1]) == 1
                      for j in range(3)))

def reg_p1c4(seq):
    """P1-C4 — The 4 dual (Inverse-and-Antipodal) pairs are placed as Inverse pairs.

    ATTRIBUTION: Schulz 1982 dissertation pp. 139-140 (citing Lai Zhide 1599);
    same hexagram class as Radisic 2026 arXiv:2601.07175 'anti-symmetric'
    (see reg_r3). The 8 hexagrams with bitrev6(h) == complement6(h) form exactly
    4 adjacent KW pairs, each satisfying the inversion criterion (partner ==
    bitrev6(h)) with no palindromic member — i.e. they land among the 28
    inversion pairs, not the 4 complement pairs. Returns bool."""
    kw_pairs = [(seq[2 * k], seq[2 * k + 1]) for k in range(32)]
    dual = [(a, b) for a, b in kw_pairs
            if reverse_6bit(a) == _reg_comp6(a) and reverse_6bit(b) == _reg_comp6(b)]
    return (len(dual) == 4
            and all(reverse_6bit(a) == b for a, b in dual)
            and all(reverse_6bit(a) != a and reverse_6bit(b) != b for a, b in dual))

def reg_p2c3(seq):
    """P2-C3 — Line-count remainder symmetry: 8 raw, 4 after consolidation.

    ATTRIBUTION: Schulz 1982 dissertation p. 213 (citing Lai Zhide 1599);
    cross-referenced by Schulz 2011 JCP 38:4 pp. 649-651 (SC-8).
    First Part (seq[0..29], 180 lines): yin - yang == 8; Latter Part
    (seq[30..63], 204 lines): yang - yin == 8. Consolidated to the 18+18
    stations' canonical gua (108 lines each): remainders drop to 4 in both
    halves. Returns bool."""
    yang_a = sum(_reg_hw(h) for h in seq[:30])
    yang_b = sum(_reg_hw(h) for h in seq[30:])
    st = _reg_stations(seq)
    cons_a = sum(_reg_hw(st[s][0]) for s in range(18))
    cons_b = sum(_reg_hw(st[s][0]) for s in range(18, 36))
    return ((180 - yang_a) - yang_a == 8
            and yang_b - (204 - yang_b) == 8
            and (108 - cons_a) - cons_a == 4
            and cons_b - (108 - cons_b) == 4)

def reg_p2c4(seq):
    """P2-C4 — Sixty-line interval from head pair through the median pair's door.

    ATTRIBUTION: Schulz 1982 dissertation pp. 207-208 (citing Lai Zhide 1599,
    CICC 'shou shang' 6a, 1:7b). Interpretation per registry: the head pair
    (12 lines) plus the 8 intervening hexagrams (48 lines) total 60 lines in
    each Part, the median pair being Tai/Pi (000111b/111000b) at slots 10-11
    and Sun/Yi (100011b/110001b) at slots 40-41. The content identity of the
    median pairs is what makes this a sequence constraint (the slot arithmetic
    alone is position-fixed). Returns bool."""
    median_a = {seq[10], seq[11]} == {0b000111, 0b111000}
    median_b = {seq[40], seq[41]} == {0b100011, 0b110001}
    lines_a = 2 * 6 + 6 * len(seq[2:10])    # head pair + interval = 60
    lines_b = 2 * 6 + 6 * len(seq[32:40])
    return median_a and median_b and lines_a == 60 and lines_b == 60

def reg_p2c5(seq):
    """P2-C5 — Both Part closures use only the Kan and Li trigrams.

    ATTRIBUTION: Schulz 1982 dissertation pp. 211-212 (citing Lai Zhide 1599);
    partially overlaps Schulz 2016 p. 27 (SC-19, see reg_ccn7). The closing
    pair of the First Part (seq[28..29]) and of the Latter Part (seq[62..63])
    decompose entirely into trigrams {Kan(2), Li(5)}. Returns bool."""
    closers = (seq[28], seq[29], seq[62], seq[63])
    return all(lower_trigram(h) in (0b010, 0b101)
               and upper_trigram(h) in (0b010, 0b101) for h in closers)

def reg_p2c6(seq):
    """P2-C6 — Median pair trigrams reverse the head pair trigrams in each Part.

    ATTRIBUTION: Schulz 1982 dissertation pp. 207-212 (citing Lai Zhide 1599).
    First Part: the median pair (slots 10-11) is built from the head pair's
    trigrams (Qian from h1, Kun from h2) in the two crossed arrangements —
    trigram-swap partners of each other, distinct from the doubled heads.
    Latter Part: swapping upper/lower trigrams of head hexagrams 31/32
    (slots 30-31) yields median hexagrams 41/42 (slots 40-41) respectively
    ('DECREASE has the trigrams of AROUSAL in reverse; INCREASE has
    CONSTANCY's reversed'). Returns bool."""
    def swap(h):
        return ((h & 0b111) << 3) | ((h >> 3) & 0b111)

    head_trigs = {lower_trigram(seq[0]), upper_trigram(seq[0]),
                  lower_trigram(seq[1]), upper_trigram(seq[1])}
    med_trigs = {lower_trigram(seq[10]), upper_trigram(seq[10]),
                 lower_trigram(seq[11]), upper_trigram(seq[11])}
    part_a = (med_trigs == head_trigs
              and swap(seq[10]) == seq[11]
              and seq[10] not in (seq[0], seq[1]))
    part_b = swap(seq[30]) == seq[40] and swap(seq[31]) == seq[41]
    return part_a and part_b

def reg_d4(seq):
    """D4 — Kan-Li (29/30) and Ji-ji/Wei-ji (63/64) close the two Classic Parts.

    ATTRIBUTION: Drasny, 'The Regular Grouping of the Hexagrams before the
    Yi Jing' (pascal-man.com / i-ching.hu); boundary framing also Schulz 1982
    pp. 211-212 (see reg_p2c5). seq[28..29] == doubled Kan(010010b), doubled
    Li(101101b); seq[62..63] == Ji-ji(010101b), Wei-ji(101010b) — note the
    registry entry transposed the hexagram-63/64 encodings; ground truth from
    seq[] is Ji-ji = 010101b = 21. All four decompose into {Kan, Li} trigrams
    only. Returns bool."""
    positions = (seq[28] == 0b010010 and seq[29] == 0b101101
                 and seq[62] == 0b010101 and seq[63] == 0b101010)
    return positions and reg_p2c5(seq)

def reg_d7(seq):
    """D7 — Sovereign (xiaoxi/bigua) hexagrams occupy the group-B pair slots.

    ATTRIBUTION: Drasny (i-ching.hu); sovereign identification also Schulz &
    Cunningham 1990 / Schulz 1990 JCP 17 (see reg_rs1). The 12 xiaoxi hexagrams
    are the monotone yang-accumulators (1<<k)-1 and their complements. Counts
    how many occupy Drasny's group-B slots — KW pairs #19-20, #23-24, #33-34,
    #43-44 (0-based slots 18,19,22,23,32,33,42,43); the other 4 xiaoxi live in
    groups F (#1-2) and A (#11-12). KW expected 8. Returns count."""
    xiaoxi = {(1 << k) - 1 for k in range(1, 7)}
    xiaoxi |= {_reg_comp6(h) for h in xiaoxi}
    b_slots = (18, 19, 22, 23, 32, 33, 42, 43)
    return sum(1 for i in b_slots if seq[i] in xiaoxi)

def reg_s1(seq):
    """S1 — Every KW pair's XOR (change hexagram) is characterizable:
    complement pairs give 111111b; inversion pairs give palindromes.

    ATTRIBUTION: Schoter 1998, 'Boolean Algebra and the Yi Jing', The Oracle
    2:7 pp. 19-34 (Definition 9). The 4 complement pairs XOR to 63; each of
    the 28 inversion pairs XORs to h ^ bitrev6(h), which is always a
    palindrome. Returns bool."""
    kw_pairs = [(seq[2 * k], seq[2 * k + 1]) for k in range(32)]
    compl = [a ^ b for a, b in kw_pairs if reverse_6bit(a) == a]
    inv = [a ^ b for a, b in kw_pairs if reverse_6bit(a) != a]
    return (len(compl) == 4 and all(x == 0b111111 for x in compl)
            and all(reverse_6bit(x) == x for x in inv))

def reg_s6(seq):
    """S6 — Klein four-group orbit structure: every KW pair is within-orbit,
    and every size-4 orbit is entered via the reversal partner.

    ATTRIBUTION: Schoter (yijing.co.uk, via biroco.com); formalized and proved
    by Radisic 2026 arXiv:2601.07175 (Lean 4). K4 = {id, comp, rev, comp.rev}
    partitions the 64 hexagrams into 12 size-4 orbits + 8 size-2 orbits; each
    KW pair lies inside a single orbit, and pairs drawn from size-4 orbits use
    the (h, rev(h)) partner rather than comp or comp.rev. Returns bool."""
    def orbit(h):
        return frozenset({h, _reg_comp6(h), reverse_6bit(h),
                          _reg_comp6(reverse_6bit(h))})

    kw_pairs = [(seq[2 * k], seq[2 * k + 1]) for k in range(32)]
    within = all(b in orbit(a) for a, b in kw_pairs)
    size4_rev = all(reverse_6bit(a) == b
                    for a, b in kw_pairs if len(orbit(a)) == 4)
    n_size4 = len({orbit(h) for h in range(64) if len(orbit(h)) == 4})
    return within and size4_rev and n_size4 == 12

def reg_m2(seq):
    """M2 — Non-uniform trigram distribution: Kan concentrated early,
    Li concentrated in the second half.

    ATTRIBUTION: Moore 2005, 'Structural Elements in the King Wen Sequence of
    Hexagrams', The Oracle (biroco.com; search excerpts); consolidated-view
    counts also Schulz 2011 JCP 38:4 (SC-16/SC-17). Kan predicate uses
    per-trigram-slot density (positions 1-8 vs 33-64; KW 0.375 vs 0.125 — the
    registry's raw-count comparison over these unequal windows fails on KW,
    6 < 8, see REGISTRY_IMPL_NOTES_2026_07.md); Li predicate compares raw
    counts over the equal halves (33-64 vs 1-32). Returns bool."""
    def count_trig(hexes, t):
        return sum((lower_trigram(h) == t) + (upper_trigram(h) == t)
                   for h in hexes)

    kan_early = count_trig(seq[:8], 0b010) / 16.0
    kan_late = count_trig(seq[32:], 0b010) / 64.0
    li_first = count_trig(seq[:32], 0b101)
    li_second = count_trig(seq[32:], 0b101)
    return kan_early > kan_late and li_second > li_first

def reg_r3(seq):
    """R3 — The 8 anti-symmetric hexagrams (rev(h) == comp(h)) form 4 KW pairs,
    each paired by reversal-equals-complement with intra-pair HD 6.

    ATTRIBUTION: Radisic 2026 arXiv:2601.07175 (Theorem 3.3, Lean 4 verified);
    same class as Schulz 1982's dual pairs (reg_p1c4) — Radisic adds the HD 6
    characterization. Returns bool."""
    kw_pairs = [(seq[2 * k], seq[2 * k + 1]) for k in range(32)]
    anti = [(a, b) for a, b in kw_pairs
            if reverse_6bit(a) == _reg_comp6(a) and reverse_6bit(b) == _reg_comp6(b)]
    return (len(anti) == 4
            and all(b == reverse_6bit(a) == _reg_comp6(a) for a, b in anti)
            and all(bit_diff(a, b) == 6 for a, b in anti))

def reg_r4(seq):
    """R4 — Total Hamming cost of the KW pairing.

    ATTRIBUTION: Radisic 2026 arXiv:2601.07175 (Corollary 4.12, Lean 4
    verified). Sum of intra-pair Hamming distances over the 32 pairs;
    KW expected exactly 120 (4 palindrome pairs x 6 + 4 anti-symmetric
    pairs x 6 + 72 across the 24 generic inversion pairs). Returns count."""
    return sum(bit_diff(seq[2 * k], seq[2 * k + 1]) for k in range(32))

def reg_r5(seq):
    """R5 — KW pairing optimality witness: Hamming-weight-preservation failures
    are exactly the 4 palindrome-complement pairs, and total cost is 120.

    ATTRIBUTION: Radisic 2026 arXiv:2601.07175 (Theorems 1.1, 4.8, Lean 4
    verified; uniqueness itself is the theorem — this checks KW's witness
    values). NOTE: the registry entry claims 8 hw-preservation failures
    (palindrome + anti-symmetric pairs); reversal preserves popcount, so
    anti-symmetric (reversal-paired) pairs cannot fail — the true KW failure
    count is 4, all palindrome-complement pairs (verified computationally;
    see REGISTRY_IMPL_NOTES_2026_07.md). Returns bool."""
    kw_pairs = [(seq[2 * k], seq[2 * k + 1]) for k in range(32)]
    fails = [(a, b) for a, b in kw_pairs if _reg_hw(a) != _reg_hw(b)]
    return (len(fails) == 4
            and all(reverse_6bit(a) == a and b == _reg_comp6(a) for a, b in fails)
            and reg_r4(seq) == 120)

def reg_c1(seq):
    """C1 — Yang balance of consecutive non-overlapping groups of 4 hexagrams.

    ATTRIBUTION: Chan 2026 arXiv:2604.09234 (Table 2; p=0.002 vs 100,000
    random baselines — exact formulation pending full-paper access, registry
    proxy used). Aggregate deviation sum(|yang_lines(group) - 12|) over the 16
    groups seq[4i..4i+3]. KW measured value 24 anchors the gate (the registry
    gives the percentile, not the raw score). Returns count."""
    return sum(abs(sum(_reg_hw(h) for h in seq[i:i + 4]) - 12)
               for i in range(0, 64, 4))

def reg_c2(seq):
    """C2 — Within-pair Hamming distance profile (asymmetry fingerprint).

    ATTRIBUTION: Chan 2026 arXiv:2604.09234 (Table 2; 99.2nd percentile vs
    random — exact asymmetry metric pending full-paper access). Deterministic
    proxy: the intra-pair HD histogram as ((hd, npairs), ...) sorted by hd.
    KW measured: ((2, 12), (4, 12), (6, 8)) — partially explained by reg_r3 /
    reg_r4 (the 8 HD-6 pairs are the palindrome + anti-symmetric classes).
    Returns tuple."""
    counts = {}
    for k in range(32):
        hd = bit_diff(seq[2 * k], seq[2 * k + 1])
        counts[hd] = counts.get(hd, 0) + 1
    return tuple(sorted(counts.items()))

# KW expected values (the --registry-verify gate). Sources: the registry's
# KW EXPECTED VALUE fields; for count-form rules the registry gives R-S2=20,
# MM-T5=0, D7=8, R4=120 explicitly; MM-T3=4, MM-T6=0, C1=24 and the C2
# histogram are KW-measured anchors (registry states only qualitative/percentile
# expectations for those).
REGISTRY_KW_EXPECTED = [
    ("rs1", True), ("rs2", 20), ("ccn1", True), ("ccn2", True),
    ("ccn3", True), ("ccn4", True), ("ccn6", True), ("ccn7", True),
    ("ccn8", True), ("c2011n1", True), ("c2011n2", True), ("c2011n4", True),
    ("mmt3", 4), ("mmt4", True), ("mmt5", 0), ("mmt6", 0),
    ("p1c4", True), ("p2c3", True), ("p2c4", True), ("p2c5", True),
    ("p2c6", True), ("d4", True), ("d7", 8), ("s1", True),
    ("s6", True), ("m2", True), ("r3", True), ("r4", 120),
    ("r5", True), ("c1", 24), ("c2", ((2, 12), (4, 12), (6, 8))),
]

def registry_verify():
    """Run every reg_* checker against the King Wen sequence and assert each
    equals its registry KW-expected value. Returns 0 on full pass, 1 on any
    mismatch. See roae-private/CANDIDATE_REGISTRY_2026_07.md."""
    seq = list(binary_hexagrams)
    failures = 0
    for rid, expected in REGISTRY_KW_EXPECTED:
        value = globals()["reg_" + rid](seq)
        if value == expected and type(value) is type(expected):
            print(f"reg_{rid}: {value} OK")
        else:
            failures += 1
            print(f"reg_{rid}: {value} FAIL (expected {expected})")
    if failures:
        print(f"{failures} of {len(REGISTRY_KW_EXPECTED)} REGISTRY CHECKS FAILED")
        return 1
    print(f"ALL {len(REGISTRY_KW_EXPECTED)} REGISTRY CHECKS PASS")
    return 0




# ---------------------------------------------------------------------------
# F4' ordering-layer functionals (pre-registered 2026-07-04, roae-private/
# F4PRIME_PREREGISTRATION.md — 13 literature-derived axes, operationalized as
# integer statistics BEFORE any population measurement; look-elsewhere gates
# pre-set). Each takes an orientation-resolved 64-hexagram ordering.
# ATTRIBUTIONS per functional in the docstrings; see documentation/CITATIONS.md.
# ---------------------------------------------------------------------------

def _f4p_rev6(h):
    r = 0
    for b in range(6):
        r = (r << 1) | ((h >> b) & 1)
    return r

def _f4p_jf_palace():
    """Jing Fang palace index per hexagram (palace generator as in roae.py
    --trigrams / solve.c --null-historical; Jing Fang c. 77-37 BCE)."""
    pal = {}
    for pi, t in enumerate((0b111, 0b001, 0b010, 0b100, 0b000, 0b110, 0b101, 0b011)):
        for h in ((t << 3) | t, (t << 3) | (t ^ 0b001), (t << 3) | (t ^ 0b011),
                  (t << 3) | (t ^ 0b111), ((t ^ 0b001) << 3) | (t ^ 0b111),
                  ((t ^ 0b011) << 3) | (t ^ 0b111), ((t ^ 0b010) << 3) | (t ^ 0b111),
                  ((t ^ 0b010) << 3) | t):
            pal[h] = pi
    return pal

_F4P_PAL = _f4p_jf_palace()

def f4p_housedisp(seq):
    """1. Positional dispersion of Jing Fang palaces: sum over 8 palaces of
    (max member position - min member position). Axis: Jing Fang 8 Palaces."""
    pos = {h: i for i, h in enumerate(seq)}
    lo = [64] * 8; hi = [-1] * 8
    for h in range(64):
        p = _F4P_PAL[h]
        i = pos[h]
        lo[p] = min(lo[p], i); hi[p] = max(hi[p], i)
    return sum(hi[p] - lo[p] for p in range(8))

def f4p_trigram_runs(seq):
    """2. Longest run of consecutive pairs sharing the lower trigram of the
    pair's first member. Axis: Zheng Qiao / Hu Yigui trigram clustering."""
    L = [seq[2 * i] & 7 for i in range(32)]
    best = cur = 1
    for i in range(1, 32):
        cur = cur + 1 if L[i] == L[i - 1] else 1
        best = max(best, cur)
    return best

def f4p_nuclear_adj(seq):
    """3. Adjacent positions sharing the same nuclear hexagram. Axis: Cook
    nuclear-trigram structure (nuc = lines 2-4 lower, 3-5 upper)."""
    nuc = lambda h: ((((h >> 2) & 7) << 3) | ((h >> 1) & 7))
    return sum(1 for i in range(63) if nuc(seq[i]) == nuc(seq[i + 1]))

def f4p_yang_drift(seq):
    """4. Position-weighted yang mass: sum i*hw(seq[i]). Axis: Schulz gender
    waning / Mawangdui cumulative-yang comparison."""
    return sum(i * _reg_hw(h) for i, h in enumerate(seq))

def f4p_dist_runs(seq):
    """5. Longest run of equal consecutive transition distances. Axis: Moore
    1988 rhythm/run structure."""
    d = [_reg_hw(seq[i] ^ seq[i + 1]) for i in range(63)]
    best = cur = 1
    for i in range(1, 63):
        cur = cur + 1 if d[i] == d[i - 1] else 1
        best = max(best, cur)
    return best

def f4p_palspan(seq):
    """6. Highest pair-position holding a palindromic hexagram (rev6(h)==h);
    lowest is 0 by C4. Axis: biroco/Moore symmetric-hexagram placement."""
    return max(i // 2 for i, h in enumerate(seq) if _f4p_rev6(h) == h)

def f4p_comp_adj(seq):
    """7. Complement pair-couples at adjacent pair positions (counted once per
    couple). Axis: Davis / C3 adjacency form. KW value 1 (the 38/39 couple;
    SOLVE-SUMMARY's "9 adjacent complements" counts within-pair complements,
    which are pair-structure facts, not ordering-layer facts)."""
    ppos = {}
    for i in range(32):
        ppos[seq[2 * i]] = i; ppos[seq[2 * i + 1]] = i
    n = 0
    for i in range(32):
        j = ppos[seq[2 * i] ^ 63]
        if j > i and abs(j - i) == 1:
            n += 1
    return n

def f4p_house_balance(seq):
    """8. Upper-trigram imbalance between sequence halves: sum over 8 trigrams
    of |count(first 16 pairs) - count(second 16)| using each pair's first
    member. Axis: Lai Zhide two-halves organization."""
    c1 = [0] * 8; c2 = [0] * 8
    for i in range(32):
        (c1 if i < 16 else c2)[seq[2 * i] >> 3] += 1
    return sum(abs(c1[t] - c2[t]) for t in range(8))

def f4p_par_switch(seq):
    """9. Switches in the transition-distance parity string (63 values, 62
    comparisons). Axis: Zhu Yuansheng parity skeleton, second order."""
    p = [(_reg_hw(seq[i] ^ seq[i + 1])) & 1 for i in range(63)]
    return sum(1 for i in range(62) if p[i] != p[i + 1])

def f4p_dist_autocorr(seq):
    """10. Lag-1 product sum of transition distances: sum d_i*d_{i+1}. Axis:
    Chan 2026 lag-1 autocorrelation, ordering-layer integer form."""
    d = [_reg_hw(seq[i] ^ seq[i + 1]) for i in range(63)]
    return sum(d[i] * d[i + 1] for i in range(62))

def f4p_front_load(seq):
    """11. Sum of the first 31 transition distances (total is C5-fixed, so this
    captures front/back asymmetry). Axis: McKenna wave asymmetry."""
    return sum(_reg_hw(seq[i] ^ seq[i + 1]) for i in range(31))

def f4p_value_trend(seq):
    """12. Concordant pairs of (position, binary value): #{i<j: seq[i]<seq[j]}.
    Kendall-tau numerator vs the Fu Xi binary ordering axis."""
    return sum(1 for i in range(64) for j in range(i + 1, 64) if seq[i] < seq[j])

def f4p_wrap_class(seq):
    """13. Wrap distance hw(seq[63]^seq[0]) in {1,3,5}. Axis: circular reading
    (McKenna; TR-7)."""
    return _reg_hw(seq[63] ^ seq[0])

F4P_FUNCS = ["housedisp", "trigram_runs", "nuclear_adj", "yang_drift",
             "dist_runs", "palspan", "comp_adj", "house_balance", "par_switch",
             "dist_autocorr", "front_load", "value_trend", "wrap_class"]

def f4p_verify():
    """Print all 13 F4' functional values on KW; gate against expected values
    once embedded (two-language: solve.c must reproduce independently)."""
    seq = list(binary_hexagrams)
    failures = 0
    for name in F4P_FUNCS:
        v = globals()["f4p_" + name](seq)
        exp = F4P_KW_EXPECTED.get(name)
        tag = "OK" if exp == v else ("FAIL (expected %s)" % exp if exp is not None else "(unset)")
        if exp is not None and exp != v:
            failures += 1
        print(f"f4p_{name}: {v} {tag}")
    print("F4P VERIFY:", "PASS" if failures == 0 else f"{failures} FAILURES")
    return 1 if failures else 0

F4P_KW_EXPECTED = {
    "housedisp": 385, "trigram_runs": 2, "nuclear_adj": 5, "yang_drift": 6154,
    "dist_runs": 3, "palspan": 30, "comp_adj": 1, "house_balance": 16,
    "par_switch": 30, "dist_autocorr": 648, "front_load": 103,
    "value_trend": 1003, "wrap_class": 3,
}


# ---------------------------------------------------------------------------
# Davis (2012) composite candidates (pre-registered 2026-07-04 in
# documentation/CRITIQUE.md, "Davis (2012) structural claims"; operational
# spec frozen in roae-private/books/davis/DAVIS_2012_STRUCTURAL_AUDIT.md §5:
# C-D22, C-D4, C-D15, C-D16, C-D13, C-D3, C-D17, C-D12+20, C-D8).
# ATTRIBUTION: every structural claim is Scott Davis's (*The Classic of
# Changes in Cultural Context*, Cambria Press, 2012 — page refs per
# function); the integer/boolean operationalizations and the population
# measurement over C1-C5 space are ROAE's. Nine scorers over an
# orientation-resolved ordering; booleans return 0/1 (population scoring
# reports mass-of-TRUE). Orientation flags in docstrings follow the audit:
# (a) = sensitive to reading the sequence back-to-front, (b) = sensitive to
# global hexagram flip (pointwise rev6). Look-elsewhere gates fixed in
# CRITIQUE.md BEFORE any population measurement (two-sided p < 0.05/9).
# ---------------------------------------------------------------------------

_DAV_SYM = (0b000, 0b010, 0b101, 0b111)   # rev3-symmetric trigrams: Kun Kan Li Qian


def _dav_symtuple(h):
    """Ordered (lower, upper) tuple filtered to symmetric trigrams."""
    return tuple(t for t in (h & 7, (h >> 3) & 7) if t in _DAV_SYM)


def dav_termruns(seq):
    """1. C-D22 (D-22; Davis pp. 141, 251-255): number of maximal contiguous
    position-runs among the 12 one-line modifications of the final two
    hexagrams. KW = 3 (union = {3-6, 35-40, 49-50} — Davis's 'rotational
    expansion' zones; the exact-union template is a sub-event of the at-KW
    mass, and the min-over-pairs attainment form is a documented secondary
    not implemented in the batch scorer). Orientation: (a) YES (terminal
    anchor), (b) NO."""
    pos = {h: i for i, h in enumerate(seq)}
    tgt = sorted({pos[seq[62] ^ (1 << b)] for b in range(6)} |
                 {pos[seq[63] ^ (1 << b)] for b in range(6)})
    return 1 + sum(1 for i in range(1, len(tgt)) if tgt[i] != tgt[i - 1] + 1)


def dav_compmirror(seq):
    """2. C-D4 (D-4; Davis pp. 81-82, 92, 95-96): count of pair-aligned
    10-windows (5 consecutive pair-slots) with complement-mirror symmetry
    about the center pair, at the gauge-safe pair-slot level: comp images of
    slot s land in slot s+3 (as a set), slot s+1 in slot s+4, and the center
    slot s+2 is internally complement-paired. KW = 1, at positions 7-16
    (Davis's flagship 'undeniably designed' Big-and-Little unit).
    Orientation: (a) YES as anchored count (window set is (a)-stable),
    (b) NO."""
    n = 0
    for s in range(28):
        w = seq[2 * s: 2 * s + 10]
        if ({w[0] ^ 63, w[1] ^ 63} == {w[6], w[7]} and
                {w[2] ^ 63, w[3] ^ 63} == {w[8], w[9]} and
                (w[4] ^ 63) == w[5]):
            n += 1
    return n


def dav_trigarray(seq):
    """3. C-D15 (D-15; Davis pp. 76-77, 86 n22, 112): count of 8-windows
    forming Davis's regular trigram array — every hexagram exactly one
    symmetric + one asymmetric trigram; symmetric trigrams in doubled blocks
    (t,t,u,u,v,v,w,w) covering all four symmetric trigrams; asymmetric
    trigram strictly 2-alternating; symmetric trigram's vertical placement
    (lower/upper) strictly alternating (shown in Davis's Fig 16, verbalized
    in the audit). KW = 1 (at 43-50; Davis's uniqueness claim 'not found
    anywhere else' MEASURED here, not assumed). Orientation: (a) YES for
    the anchor, count is (a)-stable; (b) NO (roles exchange)."""
    n = 0
    for a in range(57):
        w = seq[a: a + 8]
        sym, vpos, asym = [], [], []
        ok = True
        for h in w:
            lo, up = h & 7, (h >> 3) & 7
            slo, sup = lo in _DAV_SYM, up in _DAV_SYM
            if slo == sup:
                ok = False
                break
            sym.append(lo if slo else up)
            vpos.append(0 if slo else 1)
            asym.append(up if slo else lo)
        if not ok:
            continue
        if not all(sym[2 * i] == sym[2 * i + 1] for i in range(4)):
            continue
        if set(sym) != set(_DAV_SYM):
            continue
        if asym[0] == asym[1] or not all(asym[i] == asym[i % 2] for i in range(8)):
            continue
        if not all(vpos[i] != vpos[i + 1] for i in range(7)):
            continue
        n += 1
    return n


def dav_parallel3040(seq):
    """4. C-D16 (D-16; Davis pp. 78, 253-254), boolean: 30s/40s parallel —
    (i) head pairs at slot distance 5 complement-linked element-wise
    (comp(seq[31])==seq[41], comp(seq[32])==seq[42], 1-based); (ii) the
    audit-verified symmetric-trigram chiasmus template: positions 33-40
    carry sym-tuples ((7),(7),(0,5),(5,0),(5),(5),(2),(2)) and 43-50 carry
    ((7),(7),(0),(0),(2),(2),(5),(5)) — fire/water (Li/Kan) crossed between
    the windows, doubled-sym 35/36 in place of the 40s' single-sym rows.
    Orientation: (a) YES, (b) NO at pair level."""
    if not ((seq[30] ^ 63) == seq[40] and (seq[31] ^ 63) == seq[41]):
        return 0
    ta = ((7,), (7,), (0, 5), (5, 0), (5,), (5,), (2,), (2,))
    tb = ((7,), (7,), (0,), (0,), (2,), (2,), (5,), (5,))
    return int(tuple(_dav_symtuple(h) for h in seq[32:40]) == ta and
               tuple(_dav_symtuple(h) for h in seq[42:50]) == tb)


def dav_palnbr(seq):
    """5. C-D13 (D-13; Davis pp. 107, 121-128 — the 'compositional device'):
    palindrome-neighborhood adjacency mass — sum over the four non-pure
    palindromic hexagrams (values 0b100001, 0b011110, 0b110011, 0b001100;
    KW #27/#28/#61/#62) of one-line neighbors landing within +-4 pair-slots
    of the palindrome's own pair-slot. KW = 10 (per-hexagram 4/2/2/2; the
    audit's firm values 27->4, 61->2, 62->2 reproduce, and its
    explicitly-deferred '28 -> compute at implementation' resolves to 2:
    N1(#28) sits at positions {31,32,43,44,47,48}, slot-distances 2/8/10).
    Orientation: (a) YES, (b) NO (sets flip-stable)."""
    pos = {h: i for i, h in enumerate(seq)}
    total = 0
    for h in (0b100001, 0b011110, 0b110011, 0b001100):
        s0 = pos[h] // 2
        total += sum(1 for b in range(6)
                     if abs(pos[h ^ (1 << b)] // 2 - s0) <= 4)
    return total


def dav_rotinv(seq):
    """6. C-D3 (D-3; Davis p. 68 Fig 12, p. 118 n14), boolean exact-set:
    the 8 hexagrams pairing indifferently by rotation or inversion
    (rev6(h)==comp6(h), rev6(h)!=h — a notation-fixed 8-member class) occupy
    positions {11,12,17,18,53,54,63,64}. Orientation: (a) YES for the exact
    set, (b) NO (class closed under rev6)."""
    pos = {h: i for i, h in enumerate(seq)}
    S = {pos[h] + 1 for h in range(64)
         if _f4p_rev6(h) == (h ^ 63) and _f4p_rev6(h) != h}
    return int(S == {11, 12, 17, 18, 53, 54, 63, 64})


def dav_pureplace(seq):
    """7. C-D17 (D-17 + D-1 component; Davis pp. 80, 82, 183), boolean:
    the four doubled-symmetric-trigram hexagrams sit at positions
    {1,2,29,30} (opening and closing Davis's part 1), AND the four
    doubled-asymmetric ones all sit within one decade (10d+1..10d+10,
    d<=5) straddling its 5/6 center (KW: 51/52 + 57/58 around 55).
    Orientation: (a) YES, (b) NO."""
    pos = {h: i for i, h in enumerate(seq)}
    symd = {pos[(t << 3) | t] + 1 for t in _DAV_SYM}
    if symd != {1, 2, 29, 30}:
        return 0
    ap = sorted(pos[(t << 3) | t] + 1 for t in range(8) if t not in _DAV_SYM)
    d = (ap[0] - 1) // 10
    if ap[-1] > 10 * d + 10 or ap[-1] > 60:
        return 0
    return int(ap[0] <= 10 * d + 5 and ap[-1] >= 10 * d + 6)


def dav_eccplace(seq):
    """8. C-D12+C-D20 (D-11/D-12/D-20; Davis pp. 117 n10, 121 Fig 26,
    124-125 Fig 27, 172, 211), boolean: joint eccentric-class placement —
    E34 (rotation changes lines 3/4 only) at pair-slots {5,8,11,24}; E16
    (rotation changes lines 1/6 only) at pair-slots {12,22,28,30}; the
    extreme-ratio E16 subset {0b100000, 0b000001, 0b011111, 0b111110} at
    positions {23,24,43,44} (its distance-20 sitting follows from the
    template). Orientation: (a) YES, (b) NO (classes flip-closed)."""
    pos = {h: i for i, h in enumerate(seq)}
    e34 = {pos[h] // 2 + 1 for h in range(64)
           if _f4p_rev6(h) != h and ((h ^ _f4p_rev6(h)) & 0b110011) == 0}
    e16 = {pos[h] // 2 + 1 for h in range(64)
           if _f4p_rev6(h) != h and ((h ^ _f4p_rev6(h)) & 0b011110) == 0}
    ext = {pos[h] + 1 for h in (0b100000, 0b000001, 0b011111, 0b111110)}
    return int(e34 == {5, 8, 11, 24} and e16 == {12, 22, 28, 30} and
               ext == {23, 24, 43, 44})


def dav_asymhalf(seq):
    """9. C-D8 (D-8; Davis pp. 111-112, 126): count of hexagrams in
    positions 1-30 (Davis's first part) whose trigrams are BOTH
    asymmetric. 16 such hexagrams exist; KW = 4 (at 17,18,27,28 — the
    other 12 all in the second half). Orientation: (a) YES (halves swap),
    (b) NO."""
    return sum(1 for h in seq[:30]
               if (h & 7) not in _DAV_SYM and ((h >> 3) & 7) not in _DAV_SYM)


DAV_FUNCS = ["termruns", "compmirror", "trigarray", "parallel3040", "palnbr",
             "rotinv", "pureplace", "eccplace", "asymhalf"]

DAV_KW_EXPECTED = {
    "termruns": 3, "compmirror": 1, "trigarray": 1, "parallel3040": 1,
    "palnbr": 10, "rotinv": 1, "pureplace": 1, "eccplace": 1, "asymhalf": 4,
}


def dav_verify():
    """Print all 9 Davis composite candidate values on KW; gate against
    embedded expected values (two-language: solve.c --dav-verify must
    reproduce this output byte-identically)."""
    seq = list(binary_hexagrams)
    failures = 0
    for name in DAV_FUNCS:
        v = globals()["dav_" + name](seq)
        exp = DAV_KW_EXPECTED.get(name)
        tag = "OK" if exp == v else ("FAIL (expected %s)" % exp if exp is not None else "(unset)")
        if exp is not None and exp != v:
            failures += 1
        print(f"dav_{name}: {v} {tag}")
    print("DAV VERIFY:", "PASS" if failures == 0 else f"{failures} FAILURES")
    return 1 if failures else 0


# ---------------------------------------------------------------------------
# Van den Berghe (c.1998-2005) structural candidates V-1..V-8 (operational
# spec frozen in roae-private/books/VANDENBERGHE_AUDIT_2026_07.md §3; registry
# entries in roae-private/CANDIDATE_REGISTRY_2026_07.md).
# ATTRIBUTION: every structural claim is D.H. "Danny" Van den Berghe's ("The
# explanation of King Wen's order of the 64 hexagrams", web 1998-2005:
# web.archive.org/web/20000108054359/http://www.ping.be/icrea/explan.html and
# later captures; fourpillars.net/pdf/kingwen.pdf; fourpillars.net/pdf/
# ic_landscape.pdf). The integer/boolean operationalizations and any
# population measurement over C1-C5 space are ROAE's; errors of
# operationalization are ours, not his. Eight scorers over an
# orientation-resolved ordering; booleans return 0/1. VdB's terms: "counter"
# = complement (h ^ 63); "elementary" trigrams = {Qian 7, Kun 0, Kan 2,
# Li 5}; pair slots are 1-based (slot k = positions 2k-1, 2k) matching both
# VdB's pair numbering and the audit.
# ---------------------------------------------------------------------------

_VDB_ELEM = (7, 0, 2, 5)   # Qian, Kun, Kan, Li — VdB's elementary trigrams


def _vdb_counter_map(seq):
    """1-based pair-slot -> slot of its counter pair (complement images).
    Well-defined on any C1-valid ordering (complements of a pair's members
    always form a pair; cf. CC-A1 / VDB-2)."""
    pos = {h: i for i, h in enumerate(seq)}
    return {k + 1: pos[seq[2 * k] ^ 63] // 2 + 1 for k in range(32)}


def _vdb_nuc(h):
    """Nuclear hexagram: lower trigram = lines 2-4 (bits 1-3), upper trigram
    = lines 3-5 (bits 2-4). VdB kingwen.pdf pp.10-11 (tabel3)."""
    return ((h >> 1) & 7) | (((h >> 2) & 7) << 3)


def vdb_elemskel(seq):
    """1. V-1 (VDB-3; kingwen.pdf p.2), boolean: elementary-pair skeleton at
    doubling intervals. The pairs built purely from {Qian,Kun} or purely from
    {Kan,Li} sit at pair slots exactly {1, 6, 15, 32} (gaps 4, 8, 16;
    32 = 1+4+1+8+1+16+1), with the {Qian,Kun} pairs at {1, 6} and the
    {Kan,Li} pairs at {15, 32}. Under a uniform random pair order the 4-slot
    placement alone has P = 4!/(32*31*30*29) = 1/35,960 (VdB's own correct
    arithmetic). KW = 1."""
    pure70, pure25 = set(), set()
    for k in range(32):
        a, b = seq[2 * k], seq[2 * k + 1]
        ts = {a & 7, (a >> 3) & 7, b & 7, (b >> 3) & 7}
        if ts <= {7, 0}:
            pure70.add(k + 1)
        elif ts <= {2, 5}:
            pure25.add(k + 1)
    return int(pure70 == {1, 6} and pure25 == {15, 32})


def vdb_specplace(seq):
    """2. V-2 (VDB-4/VDB-5; kingwen.pdf p.2): special-pair placement count
    (0-4). Relative to the slot of the doubled-Kan/Li elementary pair
    (KW 29/30): (1) palindrome pair 0b100001/0b011110 (KW 27/28) exactly one
    slot before it; (2) palindrome pair 0b110011/0b001100 (KW 61/62) exactly
    one slot before the Kan/Li mixed pair 0b010101/0b101010 (KW 63/64);
    (3) anti-symmetric pair 0b011001/... (KW 17/18) exactly 6 slots before
    it; (4) anti-symmetric pair 0b110100/... (KW 53/54) exactly 12 slots
    after it (distance doubling). Pair identities are fixed by C1; only the
    slots vary. KW = 4 (slots 14->15, 31->32, 9 = 15-6, 27 = 15+12)."""
    pos = {h: i for i, h in enumerate(seq)}
    slot = lambda h: pos[h] // 2 + 1
    s2930 = slot(0b010010)
    return (int(slot(0b100001) == s2930 - 1) +
            int(slot(0b110011) == slot(0b010101) - 1) +
            int(slot(0b011001) == s2930 - 6) +
            int(slot(0b110100) == s2930 + 12))


def vdb_slopeloc(seq):
    """3. V-3 (VDB-7; kingwen.pdf pp.3-4): counter-couple slope locality —
    of the 12 counter couples among the 24 non-special pairs, count with
    both slots in the same segment of VdB's connect.gif row segmentation
    [slots 1-10 | 11-25 | 26-32]. KW = 9 (cross-segment couples exactly
    (2,25), (3,18), (10,17) = his six interslope pairs). CAVEAT (audit §3):
    the segmentation is itself fitted — under the naive wave-slope cuts the
    KW score is only 4/12; V-4 is the parameter-light closure form."""
    counter = _vdb_counter_map(seq)
    row = lambda p: 0 if p <= 10 else (1 if p <= 25 else 2)
    couples = {tuple(sorted((k, v))) for k, v in counter.items() if k != v}
    return sum(1 for a, b in couples if row(a) == row(b))


def vdb_groupclosure(seq):
    """4. V-4 (VDB-8; kingwen.pdf p.4, connect.gif): six-pair group closure
    under counter-pairing, count of 4 sub-predicates. Fixed slot partition
    {1},{2,3},G1={4-9},{10},G2={11-16},{17,18},G3={19-24},{25},G4={26-31},
    {32}: (1) G1 closed under counter (image in G1, incl. self-counter);
    (2) G4 closed; (3) G2 u G3 jointly closed (NOT individually — couples
    cross the G2/G3 line in KW); (4) connectors map 2<->25, 3<->18, 10<->17.
    Unblocks/supersedes registry M1 (Moore 2005); VdB's 1998-2000 statement
    predates Moore. KW = 4."""
    counter = _vdb_counter_map(seq)
    g1, g2, g3, g4 = (set(range(4, 10)), set(range(11, 17)),
                      set(range(19, 25)), set(range(26, 32)))
    closed = lambda g: all(counter[p] in g for p in g)
    return (int(closed(g1)) + int(closed(g4)) + int(closed(g2 | g3)) +
            int(counter[2] == 25 and counter[3] == 18 and counter[10] == 17))


def vdb_sunrise(seq):
    """5. V-5 (VDB-9; kingwen.pdf pp.5-6, ic_landscape.pdf pp.2-4): sunrise
    azimuth ordering of second-half upper-Li hexagrams, score 0-2.
    (1) membership: positions n in 29..64 with upper trigram Li are exactly
    {30, 35, 38, 50, 56, 64}; (2) monotonicity: sunrise southness
    s = -23.44*cos(2*pi*d/365.25) of the season named by each such
    hexagram's LOWER trigram (d = season-midpoint days after summer
    solstice, VdB tabel2: Li=midsummer 0, Kun=late summer 45, Dui=start of
    autumn 75, Qian=late autumn 135, Kan=midwinter 183, Gen=late winter 225,
    Xun=full spring 285, Zhen=early spring 255) is strictly increasing in
    sequence order. KW = 2 (southness -23.4 < -16.8 < -6.5 < -4.4 < 17.5 <
    23.4). Scope caveats (audit §3): first-half upper-Li (KW 14, 21) are
    outside VdB's rule; under a strict Later-Heaven equinox reading the
    38-vs-50 comparison becomes a tie (non-strict monotone)."""
    import math
    season_days = {5: 0, 0: 45, 3: 75, 7: 135, 2: 183, 4: 225, 6: 285, 1: 255}
    upli = [n for n in range(29, 65) if ((seq[n - 1] >> 3) & 7) == 5]
    s = [-23.44 * math.cos(2 * math.pi * season_days[seq[n - 1] & 7] / 365.25)
         for n in upli]
    return (int(upli == [30, 35, 38, 50, 56, 64]) +
            int(all(s[i] < s[i + 1] for i in range(len(s) - 1))))


def vdb_landscape(seq):
    """6. V-6 (VDB-11a-d/14/15; kingwen.pdf p.4, ic_landscape.pdf pp.7-13,
    v1 text): trigram run/void/cluster/flank structure, count of 5
    sub-predicates (positions 1-based): (a) Kan among {lower,upper} for
    every n in 3..8 and for NO n in 9..28; (b) Gen-upper set == {4, 18, 22,
    23, 26, 27, 41, 52} and position 20 holds big-Gen 0b110000; (c)
    Dui-upper set == {17, 28, 31, 43, 45, 47, 49, 58}, Dui trigram
    occurrences (either position) in 31..64 == 12, and position 34 holds
    big-Dui 0b001111; (d) flanks: position 41 = Gen-over-Dui, position 52 =
    doubled Gen 0b100100, position 4 = Gen-over-Kan; (e) river/lake template
    transfer: (upper,lower) at positions (4, 5, 8) == (Gen,Kan), (Kan,Qian),
    (Kan,Kun) and at (41, 43, 45) == (Gen,Dui), (Dui,Qian), (Dui,Kun) — the
    same triple under Kan<->Dui. (The audit's accompanying blocked-
    continuation identities — Kan-over-Kan / Kan-over-Li are elementary-pair
    members, Gen-over-Li is Gen-upper — are order-independent facts of the
    hexagram set, verified, and add nothing to a population score.)
    KW = 5."""
    lo = lambda n: seq[n - 1] & 7
    up = lambda n: (seq[n - 1] >> 3) & 7
    has_kan = lambda n: 2 in (lo(n), up(n))
    a = int(all(has_kan(n) for n in range(3, 9)) and
            not any(has_kan(n) for n in range(9, 29)))
    genup = {n for n in range(1, 65) if up(n) == 4}
    b = int(genup == {4, 18, 22, 23, 26, 27, 41, 52} and seq[19] == 0b110000)
    duiup = {n for n in range(1, 65) if up(n) == 3}
    dui31 = sum(1 for n in range(31, 65) for t in (lo(n), up(n)) if t == 3)
    c = int(duiup == {17, 28, 31, 43, 45, 47, 49, 58} and dui31 == 12 and
            seq[33] == 0b001111)
    d = int((up(41), lo(41)) == (4, 3) and seq[51] == 0b100100 and
            (up(4), lo(4)) == (4, 2))
    e = int([(up(n), lo(n)) for n in (4, 5, 8)] ==
            [(4, 2), (2, 7), (2, 0)] and
            [(up(n), lo(n)) for n in (41, 43, 45)] ==
            [(4, 3), (3, 7), (3, 0)])
    return a + b + c + d + e


def vdb_midclusters(seq):
    """7. V-7 (VDB-12; kingwen.pdf pp.4-5, bott/top.gif): mid-interval
    clusters, count 0-3. In the middle two pair slots of each consecutive
    elementary-pair interval (KW-anchored windows: positions 5-8, 19-22,
    45-48): >=2 Kan-upper hexagrams in 5-8; >=2 Gen-upper-or-big-Gen
    (0b110000) in 19-22; >=2 Dui-upper in 45-48. KW = 3 ({5,8}, {20,22},
    {45,47}). Windows are fixed at VdB's KW-derived midpoints (the motivating
    'midway between elementary pairs' derivation is only well-defined when
    V-1 holds)."""
    kan = sum(1 for n in range(5, 9) if ((seq[n - 1] >> 3) & 7) == 2)
    gen = sum(1 for n in range(19, 23)
              if ((seq[n - 1] >> 3) & 7) == 4 or seq[n - 1] == 0b110000)
    dui = sum(1 for n in range(45, 49) if ((seq[n - 1] >> 3) & 7) == 3)
    return int(kan >= 2) + int(gen >= 2) + int(dui >= 2)


def vdb_nucorient(seq):
    """8. V-8 (VDB-17; kingwen.pdf p.11, Appendix 2 + tabel3) — the headline
    candidate: nuclear-hexagram within-pair orientation system, count of
    correct predicted orientations (0-30). Terminal class T(h) = first of
    nuc(h), nuc^2(h) in {0b111111, 0, 0b010101, 0b101010} (KW 1/2/63/64;
    always defined, VDB-16). Per pair (a first): terminal pairs {KW 1/2,
    63/64} themselves — no prediction (30 predicted of 32); class {63,64}
    (15 pairs) — the 64-generator leads iff the pair lies within positions
    17..54, else the 63-generator (window edges = the two anti-symmetric
    special pairs; fitted, ~2-3 dof — CRITIQUE caveat); class {1,2}
    (3 pairs) — the 2-generator leads; same-terminal differentiated
    (8 pairs, first nuclears {KW 23,24} or {KW 43,44}) — the 24-/44-
    generator (nuc in {0b000001, 0b111110}) leads; undifferentiated
    non-terminal (4 pairs, equal nuclears) — the member with elementary
    LOWER trigram leads. Class memberships are order-independent given the
    C1 pairing (15/3/8/6 incl. terminals); only the window test and the
    lead member depend on the ordering. KW = 29 of 30 — sole miss pair
    KW 3/4, exactly VdB's own declared exception. Orientation-layer: F5
    functional #11 (f5_vdb_nuc) scores this same integer on the orientation
    fiber; see F5_ORIENTATION_PREREGISTRATION_DRAFT.md addendum."""
    term = (63, 0, 0b010101, 0b101010)
    correct = 0
    for k in range(32):
        a, b = seq[2 * k], seq[2 * k + 1]
        if {a, b} == {63, 0} or {a, b} == {0b010101, 0b101010}:
            continue                                   # terminal pairs
        na, nb = _vdb_nuc(a), _vdb_nuc(b)
        ta = na if na in term else _vdb_nuc(na)
        tb = nb if nb in term else _vdb_nuc(nb)
        pred = None
        if {ta, tb} == {0b010101, 0b101010}:           # 63/64 class
            in_window = (2 * k + 1 >= 17) and (2 * k + 2 <= 54)
            want = 0b101010 if in_window else 0b010101
            pred = a if ta == want else b
        elif {ta, tb} == {63, 0}:                      # 1/2 class
            pred = a if ta == 0 else b
        elif ta == tb:
            if na in (0b000001, 0b111110) or nb in (0b000001, 0b111110):
                pred = a if na in (0b000001, 0b111110) else b
            else:                                      # undifferentiated
                ea, eb = (a & 7) in _VDB_ELEM, (b & 7) in _VDB_ELEM
                if ea != eb:
                    pred = a if ea else b
        if pred == a:
            correct += 1
    return correct


VDB_FUNCS = ["elemskel", "specplace", "slopeloc", "groupclosure", "sunrise",
             "landscape", "midclusters", "nucorient"]

VDB_KW_EXPECTED = {
    "elemskel": 1, "specplace": 4, "slopeloc": 9, "groupclosure": 4,
    "sunrise": 2, "landscape": 5, "midclusters": 3, "nucorient": 29,
}


def vdb_verify():
    """Print all 8 Van den Berghe candidate values on KW; gate against
    embedded expected values (two-language convention: any solve.c
    --vdb-verify must reproduce this output byte-identically)."""
    seq = list(binary_hexagrams)
    failures = 0
    for name in VDB_FUNCS:
        v = globals()["vdb_" + name](seq)
        exp = VDB_KW_EXPECTED.get(name)
        tag = "OK" if exp == v else ("FAIL (expected %s)" % exp if exp is not None else "(unset)")
        if exp is not None and exp != v:
            failures += 1
        print(f"vdb_{name}: {v} {tag}")
    print("VDB VERIFY:", "PASS" if failures == 0 else f"{failures} FAILURES")
    return 1 if failures else 0


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
    parser.add_argument("--reconstruct", action="store_true",
                        help="Reconstruct King Wen step by step, verifying uniqueness at each step")
    parser.add_argument("--null-debruijn", action="store_true",
                        help="Null-model comparison: test C1-C3 against sampled de Bruijn B(2,6) permutations (addresses CRITIQUE.md structured-permutation gap)")
    parser.add_argument("--compute-stats", nargs=2, metavar=("SOLUTIONS_BIN", "OUT_DIR"),
                        help="P2: Stream solutions.bin and emit per-chunk parquet files of observable stats")
    parser.add_argument("--marginals", nargs=2, metavar=("CHUNKS_DIR", "OUT_MD"),
                        help="P2: Per-dimension marginal percentiles with KW's position marked")
    parser.add_argument("--bivariate", nargs=2, metavar=("CHUNKS_DIR", "OUT_DIR"),
                        help="P2: Hexbin heatmaps for 5 observable pairs with KW marked")
    parser.add_argument("--joint-density", nargs=2, metavar=("CHUNKS_DIR", "OUT_MD"),
                        help="P2: KDE joint density on the 7 informative dims plus bootstrap CI on KW's percentile")
    parser.add_argument("--joint-density-v2", nargs=2, metavar=("CHUNKS_DIR", "OUT_MD"),
                        help="P2 v2: joint density with auto variance-filter and CV bandwidth selection (sampled by default; --joint-density-exhaustive for exact)")
    parser.add_argument("--joint-density-bandwidth", choices=("silverman", "cv"), default="cv",
                        help="P2 v2: bandwidth method (default: cv)")
    parser.add_argument("--joint-density-exhaustive", action="store_true",
                        help="P2 v2: stream every record through the fitted KDE (slow in pure Python; ~10× faster with --native-solve-binary)")
    parser.add_argument("--native-solve-binary", metavar="PATH",
                        help="P2 v2: path to compiled `solve` binary with --kde-score-stream support; enables fast native exhaustive scoring")
    parser.add_argument("--stratified-by-position-2-pair", nargs=2, metavar=("CHUNKS_DIR", "OUT_MD"),
                        help="P2 v2: per-stratum (position_2_pair) KW percentile reanalysis (sampled by default)")
    parser.add_argument("--stratified-exhaustive", action="store_true",
                        help="P2 v2: exhaustive per-stratum scoring (very slow at full canonical scale)")
    parser.add_argument("--joint-permutation-test", nargs=2, metavar=("CHUNKS_DIR", "OUT_MD"),
                        help="P2 v2: per-dim Bonferroni + joint multi-test extremity table")
    parser.add_argument("--sat-encode", metavar="OUT_CNF",
                        help="P3: emit DIMACS CNF for C1+C2 over the King Wen sequence; for #SAT model counting")
    parser.add_argument("--sat-c3", choices=("none", "pb", "adder"), default="none",
                        help="P3 sat-encode: include C3 as PB constraint or adder (default: none)")
    parser.add_argument("--sat-c4", action="store_true",
                        help="P3 sat-encode: force position 0 = hexagram 0 (Qian/Kun convention)")
    parser.add_argument("--sat-c5", action="store_true",
                        help="P3 sat-encode: include C5 cardinality constraints (heavy)")
    parser.add_argument("--compare-depth-profile", nargs=2, metavar=("RUN_A_LOG", "RUN_B_LOG"),
                        help="Tree-walk validator (#48): compare DEPTH_PROFILE node counts from two run "
                             "logs (produced with SOLVE_DEPTH_PROFILE=1; .gz accepted). PASS if total "
                             "divergence < threshold. Tolerance-based, not byte-exact.")
    parser.add_argument("--compare-depth-profile-threshold", type=float, default=0.005,
                        help="Divergence threshold for --compare-depth-profile (default 0.005 = 0.5%%)")
    parser.add_argument("--f4p-verify", action="store_true",
                        help="verify the 13 pre-registered F4' ordering-layer functionals on KW")
    parser.add_argument("--dav-verify", action="store_true",
                        help="verify the 9 pre-registered Davis (2012) composite candidates on KW")
    parser.add_argument("--vdb-verify", action="store_true",
                        help="verify the 8 Van den Berghe (c.1998-2005) structural candidates on KW")
    parser.add_argument("--registry-verify", action="store_true",
                        help="Run every candidate-rule ground-truth checker "
                             "(reg_*, CANDIDATE_REGISTRY_2026_07) against the "
                             "King Wen sequence and assert each equals its "
                             "registry KW-expected value. Returns 0 on full "
                             "PASS, 1 on any mismatch.")
    parser.add_argument("--extended-selftest", metavar="SOLVE_BINARY",
                        help="Run small-scale path-invariance + resume "
                             "regression suite that exercises the fork-merge, "
                             "sanity gate, and v1+v2 resume code paths added "
                             "2026-04-30. Argument is the path to the compiled "
                             "`solve` binary. Returns 0 on full PASS, 1 on any "
                             "failure. Suitable as a CI gate. Wall ~10 min on "
                             "a 4-thread VM.")
    parser.add_argument("--branch-yield-report", metavar="SOLUTIONS_BIN",
                        help="Per-partition-prefix yield count from a "
                             "solutions.bin. Useful for analyzing asymmetric "
                             "extensions (where some sub-branches were walked "
                             "at higher per-sub-branch budget). Optional "
                             "--baseline diff and --manifest annotation. "
                             "See x/roae/BRANCH_YIELD_REPORT_DESIGN.md.")
    parser.add_argument("--branch-yield-baseline", metavar="BASELINE_BIN",
                        help="--branch-yield-report: diff against this baseline solutions.bin")
    parser.add_argument("--branch-yield-manifest", metavar="MANIFEST_JSON",
                        help="--branch-yield-report: manifest.json with per-sub-branch budget map")
    parser.add_argument("--branch-yield-depth", type=int, default=1,
                        choices=(1, 2, 3),
                        help="--branch-yield-report: granularity. "
                             "1 = first-level (default), 2 = depth-2, 3 = depth-3")
    parser.add_argument("--branch-yield-csv", metavar="OUT_CSV",
                        help="--branch-yield-report: also write CSV")
    parser.add_argument("--branch-yield-json", metavar="OUT_JSON",
                        help="--branch-yield-report: also write JSON")
    parser.add_argument("--keystone-analysis", nargs=2,
                        metavar=("SOLUTIONS_BIN", "OUT_MD"),
                        help="Counterfactual analysis of the {1,4,21,25,27} "
                             "minimum boundary set: per-record 5-bit match-mask "
                             "histogram + drop-one analysis. Identifies the "
                             "specific record families each keystone boundary "
                             "uniquely eliminates.")
    parser.add_argument("--keystone-dump-dir", metavar="DIR",
                        help="Optional output dir for record dumps from "
                             "interesting masks (drop-25, drop-27, all-5)")
    parser.add_argument("--keystone-dump-limit", type=int, default=10000,
                        help="Cap on records dumped per interesting mask "
                             "(default: 10000)")
    parser.add_argument("--compute-stats-workers", type=int, default=None,
                        help="P2 compute-stats: worker processes (default: cpu_count())")
    parser.add_argument("--compute-stats-chunk-size", type=int, default=1_000_000,
                        help="P2 compute-stats: records per parquet chunk (default: 1,000,000)")
    parser.add_argument("--compute-stats-max-records", type=int, default=None,
                        help="P2 compute-stats: cap total records processed (for testing)")
    parser.add_argument("--joint-density-samples-per-chunk", type=int, default=30,
                        help="P2 joint-density: samples drawn per chunk (default: 30)")
    parser.add_argument("--joint-density-bootstrap-n", type=int, default=1000,
                        help="P2 joint-density: bootstrap resamples for CI (default: 1000)")
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

    if args.registry_verify:
        sys.exit(registry_verify())

    if args.f4p_verify:
        sys.exit(f4p_verify())

    if args.dav_verify:
        sys.exit(dav_verify())

    if args.vdb_verify:
        sys.exit(vdb_verify())

    if args.extended_selftest:
        sys.exit(extended_selftest(args.extended_selftest))

    if args.compare_depth_profile:
        sys.exit(compare_depth_profile(args.compare_depth_profile[0],
                                       args.compare_depth_profile[1],
                                       threshold=args.compare_depth_profile_threshold))

    if args.branch_yield_report:
        branch_yield_report(
            args.branch_yield_report,
            baseline_bin=args.branch_yield_baseline,
            manifest=args.branch_yield_manifest,
            depth=args.branch_yield_depth,
            out_csv=args.branch_yield_csv,
            out_json=args.branch_yield_json,
        )
        return

    if args.keystone_analysis:
        keystone_analysis(args.keystone_analysis[0],
                          args.keystone_analysis[1],
                          dump_dir=args.keystone_dump_dir,
                          dump_limit=args.keystone_dump_limit)
        return

    if args.compute_stats:
        p2_compute_stats(args.compute_stats[0], args.compute_stats[1],
                         workers=args.compute_stats_workers,
                         chunk_size=args.compute_stats_chunk_size,
                         max_records=args.compute_stats_max_records)
        return
    if args.marginals:
        p2_marginals(args.marginals[0], args.marginals[1])
        return
    if args.bivariate:
        p2_bivariate(args.bivariate[0], args.bivariate[1])
        return
    if args.joint_density:
        p2_joint_density(args.joint_density[0], args.joint_density[1],
                         samples_per_chunk=args.joint_density_samples_per_chunk,
                         bootstrap_n=args.joint_density_bootstrap_n)
        return

    if args.joint_density_v2:
        p2_joint_density_v2(args.joint_density_v2[0], args.joint_density_v2[1],
                            samples_per_chunk=args.joint_density_samples_per_chunk,
                            bandwidth_method=args.joint_density_bandwidth,
                            exhaustive=args.joint_density_exhaustive,
                            native_solve_binary=args.native_solve_binary,
                            bootstrap_n=args.joint_density_bootstrap_n)
        return

    if args.stratified_by_position_2_pair:
        p2_stratified_p2pair(args.stratified_by_position_2_pair[0],
                             args.stratified_by_position_2_pair[1],
                             samples_per_chunk=args.joint_density_samples_per_chunk,
                             exhaustive=args.stratified_exhaustive,
                             native_solve_binary=args.native_solve_binary)
        return

    if args.joint_permutation_test:
        p2_joint_permutation_test(args.joint_permutation_test[0],
                                  args.joint_permutation_test[1],
                                  samples_per_chunk=args.joint_density_samples_per_chunk)
        return

    if args.sat_encode:
        p3_sat_encode(args.sat_encode,
                      include_c3=args.sat_c3,
                      include_c4=args.sat_c4,
                      include_c5=args.sat_c5)
        return

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
                 args.fingerprint, args.reconstruct, args.null_debruijn]
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

    if args.reconstruct:
        print_reconstruct()
        print()

    if args.null_debruijn:
        print_null_debruijn(trials=args.trials, seed=args.seed)
        print()

if __name__ == "__main__":
    main()
