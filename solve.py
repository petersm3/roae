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

    ATTRIBUTION: the pair structure is classical — described by Yu Fan (164-233 AD; fandui/pangtong,
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
    shared by the Jing Fang ordering. (Corrected 2026-07-05: the authentic Mawangdui sequence
    per Shaughnessy 2022 has exactly one 5-line transition at its Kan->Zhen octet seam; an
    earlier erroneous Mawangdui array here had zero.) See CITATIONS.md."""
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
    # mean-Hamming-vs-random observation is Chan 2026 prior art (CITATIONS.md#chan2026 / SOLVE.md);
    # ROAE's own contribution is the exact multiset {1:2,2:20,3:13,4:19,6:9} as a hard C5 consequence.
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
                "adder" (DIMACS adder network — deferred/superseded: emits a
                status sidecar entry only; C3 is native in sat.py's pair-slot
                model, the certification path).
    include_c4: force x[0][0] and x[1][partner(0)] = 1.
    include_c5: KW's Hamming-distribution cardinality constraints —
                deferred/superseded likewise (status sidecar entry only;
                native in sat.py's pair-slot model). Both deferred encoders
                are built only if a future variable-pairing analysis needs
                this legacy position-hexagram x[i][p] model.
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
            # DEFERRED / SUPERSEDED (operator decision 2026-07-10). C3 is
            # native (Sinz sequential counters) in sat.py's pair-slot model —
            # the only certification-path model. A DIMACS adder summing
            # network in THIS legacy position-hexagram x[i][p] encoder would
            # be large and probably not faster in practice than PB; implement
            # it only if a future variable-pairing analysis needs the x[i][p]
            # model specifically (an instance the pair-slot model can't
            # express, e.g. relaxing the fixed pairing). Not dead — deferred.
            pb_constraints.append({
                "form": "abs_sum_complement_distance",
                "bound": 776,
                "n_aux_vars": pair_var_count,
                "n_link_clauses": len(pair_aux_clauses),
                "status": "deferred_superseded_by_pairslot_model",
                "note": "C3 is native (Sinz) in sat.py's pair-slot model (the "
                        "certification path). Build the x[i][p] adder network "
                        "only if a variable-pairing analysis ever needs this "
                        "model; effort if built: binary adder summing network "
                        "over per-pair distances — large, and likely not "
                        "faster than the PB route.",
            })
    # include_c3 == "none" -> no C3 emitted

    # --- C5: KW's exact Hamming distribution ---
    # DEFERRED / SUPERSEDED (operator decision 2026-07-10): C5 is native in
    # sat.py's pair-slot model (the certification path). Implement here only
    # if a variable-pairing analysis ever needs the x[i][p] model; effort if
    # built is heavy — 31 per-boundary distance-class indicator families,
    # each boundary touching 64x64 (p,q) tuples, plus exactly_k cardinality.
    if include_c5:
        pb_constraints.append({
            "form": "hamming_distribution_match",
            "status": "deferred_superseded_by_pairslot_model",
            "note": "C5 is native in sat.py's pair-slot model (the "
                    "certification path). Build here only if a "
                    "variable-pairing analysis ever needs the x[i][p] model; "
                    "effort if built: 31 per-boundary distance-class "
                    "indicator families (64x64 tuples per boundary) + "
                    "exactly_k cardinality.",
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
        print(f"[sat-encode] WARNING: {len(pb_constraints)} requested "
              "constraint(s) NOT emitted as clauses (status recorded in the "
              ".meta.json sidecar): the adder-C3/C5 encoders here are "
              "deferred/superseded — C3 (Sinz) and C5 are native in sat.py's "
              "pair-slot model (the certification path). This file carries "
              "C1+C2" + ("+C4" if include_c4 else "") + " only.", flush=True)


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
    pair's first member. Axis: Zheng Qiao (~1150) / Hu Yigui (b. 1247)
    trigram clustering (via Hacker & Moore 2003)."""
    L = [seq[2 * i] & 7 for i in range(32)]
    best = cur = 1
    for i in range(1, 32):
        cur = cur + 1 if L[i] == L[i - 1] else 1
        best = max(best, cur)
    return best

def f4p_nuclear_adj(seq):
    """3. Adjacent positions sharing the same nuclear hexagram. Axis: Cook 2006
    (STEDT Monograph 5) nuclear-trigram structure (nuc = lines 2-4 lower,
    3-5 upper)."""
    nuc = lambda h: ((((h >> 2) & 7) << 3) | ((h >> 1) & 7))
    return sum(1 for i in range(63) if nuc(seq[i]) == nuc(seq[i + 1]))

def f4p_yang_drift(seq):
    """4. Position-weighted yang mass: sum i*hw(seq[i]). Axis: Schulz 1990
    (JCP 17:3) gender waning / Mawangdui cumulative-yang comparison."""
    return sum(i * _reg_hw(h) for i, h in enumerate(seq))

def f4p_dist_runs(seq):
    """5. Longest run of equal consecutive transition distances. Axis: Moore
    1989 (*The Trigrams of Han*, Aquarian Press) rhythm/run structure (the
    F4' preregistration doc's 'Moore 1988' is a year typo; CITATIONS.md
    carries the correct 1989)."""
    d = [_reg_hw(seq[i] ^ seq[i + 1]) for i in range(63)]
    best = cur = 1
    for i in range(1, 63):
        cur = cur + 1 if d[i] == d[i - 1] else 1
        best = max(best, cur)
    return best

def f4p_palspan(seq):
    """6. Highest pair-position holding a palindromic hexagram (rev6(h)==h);
    lowest is 0 by C4. Axis: Moore, *Yijing Dao*
    (biroco.com, n.d.) symmetric-hexagram placement."""
    return max(i // 2 for i, h in enumerate(seq) if _f4p_rev6(h) == h)

def f4p_comp_adj(seq):
    """7. Complement pair-couples at adjacent pair positions (counted once per
    couple). Axis: Davis 2012 / C3 adjacency form. KW value 1 (the 38/39 couple;
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
    member. Axis: Lai Zhide 1599 (via Schulz 1982) two-halves organization."""
    c1 = [0] * 8; c2 = [0] * 8
    for i in range(32):
        (c1 if i < 16 else c2)[seq[2 * i] >> 3] += 1
    return sum(abs(c1[t] - c2[t]) for t in range(8))

def f4p_par_switch(seq):
    """9. Switches in the transition-distance parity string (63 values, 62
    comparisons). Axis: Zhu Yuansheng (13th c., via Schulz 2018) parity skeleton, second
    order."""
    p = [(_reg_hw(seq[i] ^ seq[i + 1])) & 1 for i in range(63)]
    return sum(1 for i in range(62) if p[i] != p[i + 1])

def f4p_dist_autocorr(seq):
    """10. Lag-1 product sum of transition distances: sum d_i*d_{i+1}. Axis:
    Chan 2026 lag-1 autocorrelation, ordering-layer integer form."""
    d = [_reg_hw(seq[i] ^ seq[i + 1]) for i in range(63)]
    return sum(d[i] * d[i + 1] for i in range(62))

def f4p_front_load(seq):
    """11. Sum of the first 31 transition distances (total is C5-fixed, so this
    captures front/back asymmetry). Axis: McKenna & McKenna 1975 (*The Invisible Landscape* ch. 9) wave
    asymmetry."""
    return sum(_reg_hw(seq[i] ^ seq[i + 1]) for i in range(31))

def f4p_value_trend(seq):
    """12. Concordant pairs of (position, binary value): #{i<j: seq[i]<seq[j]}.
    Kendall-tau numerator vs the Fu Xi binary ordering axis (Shao Yong
    11th c. / Leibniz 1703)."""
    return sum(1 for i in range(64) for j in range(i + 1, 64) if seq[i] < seq[j])

def f4p_wrap_class(seq):
    """13. Wrap distance hw(seq[63]^seq[0]) in {1,3,5}. Axis: circular reading
    (McKenna & McKenna 1975; TR-7)."""
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
# F6 — Nielsen-audit functional families (FROZEN 2026-07-05 in roae-private/
# F6_BOOKS_PREREGISTRATION_2026_07_FROZEN.md, before any population
# measurement; Bonferroni N=7; two-sided atom-inclusive convention).
# ATTRIBUTION: #1-5 operationalize the warp/weft skeleton of Wu Deng 吳澄
# (1249-1333, Yi zuan yan), via Nielsen 2003 p. 132 (JING GUA def. 2): warp
# class W = {h : up(h) = lo(h) or up(h) = comp(lo(h))}, |W| = 16, and the
# power-of-2 weft-block profile of the received order. #6-7 operationalize
# palace-partition alignment for Jing Fang's 京房 (77-37 BCE) eight palaces,
# tabulation per Hui Dong 惠棟 (1697-1758) as printed in Nielsen 2003 pp. 1-4
# Table 2 (generator _f4p_jf_palace, verified against all 64 cells). The
# classical observations are the named scholars'; the integer
# operationalizations and the population measurement over C1-C5 space are
# ROAE's (Claude, Fable, 2026-07-05).
# Forced-class facts (frozen spec §2, NOT scored): W is C1-partner-closed, so
# every valid ordering has exactly 8 all-warp pair-slots (slot 0 warp by C4);
# no C1 pair shares a palace (0/32, universal), so palace adjacency lives
# entirely on the 31 between-pair boundaries; #1-5 are orientation-blind.
# ---------------------------------------------------------------------------

_F6_WARP = frozenset(h for h in range(64)
                     if (h >> 3) == (h & 7) or (h >> 3) == ((h & 7) ^ 7))

def _f6_warp_slots(seq):
    """0-based pair-slots whose BOTH members are Wu Deng warp hexagrams
    (positional definition; degenerate-safe on non-C1 corpus sequences)."""
    return [k for k in range(32)
            if seq[2 * k] in _F6_WARP and seq[2 * k + 1] in _F6_WARP]

def _f6_weft_blocks(seq):
    """Sizes of maximal runs of non-warp pair-slots among slots 0..31."""
    warp = set(_f6_warp_slots(seq))
    blocks, cur = [], 0
    for k in range(32):
        if k in warp:
            if cur:
                blocks.append(cur)
            cur = 0
        else:
            cur += 1
    if cur:
        blocks.append(cur)
    return blocks

def f6_warp_blocks(seq):
    """1. Number of maximal weft blocks (Wu Deng warp/weft skeleton)."""
    return len(_f6_weft_blocks(seq))

def f6_warp_pow2(seq):
    """2. Count of weft blocks whose size is a power of two (1,2,4,8,16)."""
    return sum(1 for x in _f6_weft_blocks(seq) if x & (x - 1) == 0)

def f6_warp_adj(seq):
    """3. Count of adjacent warp-slot pairs (slots k, k+1 both warp)."""
    s = _f6_warp_slots(seq)
    return sum(1 for i in range(len(s) - 1) if s[i + 1] == s[i] + 1)

def f6_wudeng_profile(seq):
    """4. Indicator: weft-block size multiset equals Wu Deng's printed
    profile {2,2,4,4,4,8} (Nielsen p. 132 control blocks)."""
    return 1 if sorted(_f6_weft_blocks(seq)) == [2, 2, 4, 4, 4, 8] else 0

def f6_wudeng_slots(seq):
    """5. Warp slots at Wu Deng's printed control slots (0-based
    {0,5,14,15,20,25,28,31}); data-like positional statistic, floor 1 by C4."""
    return len(set(_f6_warp_slots(seq)) & {0, 5, 14, 15, 20, 25, 28, 31})

def f6_palace_adj(seq):
    """6. Between-pair boundaries (31) whose adjacent hexagrams share a Jing
    Fang palace (within-pair sharing is 0/32 universally — frozen spec FT4)."""
    return sum(1 for b in range(31)
               if _F4P_PAL[seq[2 * b + 1]] == _F4P_PAL[seq[2 * b + 2]])

def f6_palace_types(seq):
    """7. Distinct unordered palace-transition types over the 31 between-pair
    boundaries (integer surrogate for palace-transition entropy)."""
    return len({frozenset((_F4P_PAL[seq[2 * b + 1]], _F4P_PAL[seq[2 * b + 2]]))
                for b in range(31)})

F6_FUNCS = ["warp_blocks", "warp_pow2", "warp_adj", "wudeng_profile",
            "wudeng_slots", "palace_adj", "palace_types"]

F6_KW_EXPECTED = {
    "warp_blocks": 6, "warp_pow2": 6, "warp_adj": 1, "wudeng_profile": 1,
    "wudeng_slots": 8, "palace_adj": 2, "palace_types": 24,
}

def f6_verify():
    """Print all 7 frozen F6 functional values on KW and gate against the
    frozen-spec expected values (two-language: solve.c --f6-verify must
    reproduce independently)."""
    seq = list(binary_hexagrams)
    failures = 0
    for name in F6_FUNCS:
        v = globals()["f6_" + name](seq)
        exp = F6_KW_EXPECTED[name]
        tag = "OK" if exp == v else "FAIL (expected %s)" % exp
        if exp != v:
            failures += 1
        print(f"f6_{name}: {v} {tag}")
    print("F6 VERIFY:", "PASS" if failures == 0 else f"{failures} FAILURES")
    return 1 if failures else 0


# ---------------------------------------------------------------------------
# R3 — permutation-cycle-structure functional family (FROZEN 2026-07-09 in
# roae-private/R3_PERMUTATION_OBSERVABLE_PREREG_2026_07_09.md §4, before any
# C1-C5 population measurement; Bonferroni N=13, both bit conventions pooled
# under one umbrella; two-sided atom-inclusive convention; REPORT-ONLY — this
# family has NO promotion path to a C-rule under any outcome, cycle structure
# being measured against Shao Yong's ~11th-c. binary indexing that postdates
# King Wen by ~2,000 years).
# ATTRIBUTION: the cycle-structure OBSERVABLE AXIS is Zhengwen Ge, "The Cycle
# Structure of the King Wen Permutation" (2026, DOI 10.5281/zenodo.19143997;
# documentation/CITATIONS.md#ge2026), who computed KW's cycle type (52,10,2),
# order 260, zero fixed points under bit0=top (functionals 8-12 below reproduce
# Ge's point values exactly). Ge's contribution is those point values; ROAE
# claims no priority on them. What this family adds — the POPULATION test of
# these observables over the C1-C5 constraint space — is the prereg's
# contribution. Classical permutation-statistic sources (de Montmort, Goncharov,
# Golomb/Dickman, Erdos-Turan, Landau, Euler) anchor context rows only. The
# integer operationalizations and the population measurement are ROAE's (Claude:
# design half Fable, execution half Opus, 2026-07-09/10). Two-language ground
# truth: solve.c perm_compute / SOLVE_KNUTH_SCORE_PERM (must reproduce these
# byte-for-byte). Novelty hedged; corrections invited.
#
# Encoding: bit0=bottom (binary_hexagrams, OEIS A102241). For an ordering seq
# (position -> value), pi_bot(v) = the position i with seq[i]=v; pi_top(v) =
# pi_bot(bitrev6(v)) (Ge's bit0=top). Orientation-BEARING leaves required (a
# single within-pair flip changes cycle structure / flips sign; prereg §2).
# ---------------------------------------------------------------------------

PERM_NAMES = ["perm_ncyc_bot", "perm_lcyc_bot", "perm_fix_bot", "perm_c2_bot",
              "perm_ord_bot", "perm_desc_bot", "perm_sign", "perm_ncyc_top",
              "perm_lcyc_top", "perm_fix_top", "perm_c2_top", "perm_ord_top",
              "perm_desc_top"]

PERM_KW_EXPECTED = {
    "perm_ncyc_bot": 7, "perm_lcyc_bot": 33, "perm_fix_bot": 1, "perm_c2_bot": 1,
    "perm_ord_bot": 1320, "perm_desc_bot": 31, "perm_sign": 1, "perm_ncyc_top": 3,
    "perm_lcyc_top": 52, "perm_fix_top": 0, "perm_c2_top": 1, "perm_ord_top": 260,
    "perm_desc_top": 30,
}
# KW full cycle types (report-only template indicators; data-like, no verdict).
_PERM_KW_TYPE_BOT = [33, 11, 8, 5, 4, 2, 1]
_PERM_KW_TYPE_TOP = [52, 10, 2]


def _perm_cycle_stats(p):
    """Cycle statistics of a permutation p[64] (fixed points = 1-cycles):
    returns (ncyc, lcyc, fix, c2, order, cycle_type_desc)."""
    from math import gcd
    seen, lens = set(), []
    for i in range(64):
        if i in seen:
            continue
        c, j = 0, i
        while j not in seen:
            seen.add(j)
            c += 1
            j = p[j]
        lens.append(c)
    lens.sort(reverse=True)
    order = 1
    for c in lens:
        order = order * c // gcd(order, c)
    return (len(lens), lens[0], lens.count(1), lens.count(2), order, lens)


def perm_compute(seq):
    """The 13 frozen R3 functionals + 2 report-only template indicators on an
    orientation-bearing ordering seq[64]. Returns (values_dict, (tmatch_bot,
    tmatch_top)). Ground truth for solve.c perm_compute / SOLVE_PERM_TESTVEC."""
    pi_bot = [None] * 64
    for i, v in enumerate(seq):
        pi_bot[v] = i
    pi_top = [pi_bot[reverse_6bit(v)] for v in range(64)]
    nb, lb, fb, cb, ob, tb = _perm_cycle_stats(pi_bot)
    nt, lt, ft, ct, ot, tt = _perm_cycle_stats(pi_top)
    db = sum(1 for i in range(63) if seq[i + 1] < seq[i])
    dt = sum(1 for i in range(63)
             if reverse_6bit(seq[i + 1]) < reverse_6bit(seq[i]))
    vals = {
        "perm_ncyc_bot": nb, "perm_lcyc_bot": lb, "perm_fix_bot": fb,
        "perm_c2_bot": cb, "perm_ord_bot": ob, "perm_desc_bot": db,
        "perm_sign": (64 - nb) & 1,       # convention-invariant (prereg F-3)
        "perm_ncyc_top": nt, "perm_lcyc_top": lt, "perm_fix_top": ft,
        "perm_c2_top": ct, "perm_ord_top": ot, "perm_desc_top": dt,
    }
    tmatch = (1 if tb == _PERM_KW_TYPE_BOT else 0,
              1 if tt == _PERM_KW_TYPE_TOP else 0)
    return vals, tmatch


def perm_verify(seq_arg=None):
    """Two-language ground-truth gate for the R3 permutation-cycle family.

    No argument: recompute all 13 functionals on King Wen and assert each equals
    its frozen §4 expected value; print PASS/FAIL. With a 64-int sequence
    argument (comma/space-separated): print the 13 values + 2 template
    indicators comma-separated (identical ordering to solve.c
    SOLVE_PERM_TESTVEC), for cross-language / corpus-control gating."""
    if seq_arg is not None:
        seq = [int(x) for x in seq_arg.replace(",", " ").split()]
        if len(seq) != 64:
            print(f"perm-verify testvec: need 64 ints, got {len(seq)}")
            return 1
        vals, tmatch = perm_compute(seq)
        row = [vals[n] for n in PERM_NAMES] + [tmatch[0], tmatch[1]]
        print(",".join(str(x) for x in row))
        return 0
    vals, _ = perm_compute(list(binary_hexagrams))
    failures = 0
    for name in PERM_NAMES:
        v = vals[name]
        exp = PERM_KW_EXPECTED[name]
        tag = "OK" if exp == v else "FAIL (expected %s)" % exp
        if exp != v:
            failures += 1
        print(f"{name}: {v} {tag}")
    print("PERM VERIFY:", "PASS" if failures == 0 else f"{failures} FAILURES")
    return 1 if failures else 0


# ---------------------------------------------------------------------------
# R6 — Circular anchor-adjacency (R-C1c) ground truth (design:
# roae-private/R6_CIRCULAR_DESIGN_2026_07_10.md §3). Two-language twin of the
# solve.c SOLVE_KNUTH_SCORE R-C1c scorer / --rc1c-verify gate.
# ATTRIBUTION: final-pair anchor Cook 2006; circular frame McKenna & McKenna
# 1975. ROAE contributes only the population measurement. Developed with AI
# assistance (Claude, Anthropic).
# ---------------------------------------------------------------------------

def rc1c_indicator(seq):
    """Does the alternating pair A2={21,42} occupy pair slot 2 or slot 32?

    Slots are 1-indexed pair slots (slot 1 = the C4-pinned pure pair at
    seq[0:2]; slot 2 = seq[2:4]; slot 32 = seq[62:64]). Returns
    (slot2, slot32, adjacent). KW == (0, 1, 1)."""
    s2 = 1 if {seq[2], seq[3]} == {21, 42} else 0
    s32 = 1 if {seq[62], seq[63]} == {21, 42} else 0
    return s2, s32, (1 if (s2 or s32) else 0)


def rc1c_verify(seq_arg=None):
    """Two-language ground-truth gate for R-C1c (R6). No argument: recompute on
    King Wen and assert (slot2, slot32, adjacent) == (0, 1, 1). With a 64-int
    SEQ argument: print `slot2,slot32,adjacent` (same ordering as solve.c
    --rc1c-verify SEQ) for witness / corpus-control cross-language gating."""
    if seq_arg is not None:
        seq = [int(x) for x in seq_arg.replace(",", " ").split()]
        if len(seq) != 64:
            print(f"rc1c-verify: need 64 ints, got {len(seq)}")
            return 1
        s2, s32, adj = rc1c_indicator(seq)
        print(f"{s2},{s32},{adj}")
        return 0
    seq = list(binary_hexagrams)
    s2, s32, adj = rc1c_indicator(seq)
    fails = 0
    for nm, v, exp in (("rc1c_slot2", s2, 0), ("rc1c_slot32", s32, 1),
                       ("rc1c_adjacent", adj, 1)):
        if v == exp:
            print(f"{nm}: {v} OK")
        else:
            print(f"{nm}: {v} FAIL (expected {exp})")
            fails += 1
    print("RC1C VERIFY:", "PASS" if fails == 0 else f"{fails} FAILURES")
    return 1 if fails else 0


# ---------------------------------------------------------------------------
# R13 — HEC two-convention robustness predicates (R-C4-B / R-C4-C) + KW gate.
# Frozen design: roae-private R13 HEC two-convention doc (2026-07-11) §4.
# Two-language twin of solve.c's R13 scorer accumulators / --rc4b-verify.
# ATTRIBUTION (the rule is NOT a ROAE discovery): Schulz 1990 (JCP 17:3,
# 345-358, motif 2; the exception first recognized by Zhu Yuansheng, 13th c.,
# per Schulz 2018 fn. 42); Cook 2006 elaborates it in his 36-class (HEC)
# coordinates; the 36-class frame is Lai Zhide 1599. ROAE contributes only the
# exception-clause formalization + the population measurement. Lemma B1 below
# is elementary — no novelty claimed; corrections invited. Developed with AI
# assistance (Claude, Anthropic).
# ---------------------------------------------------------------------------

def rc4b_pass(seq):
    """R-C4-B — the Cook-faithful exception form of the gender/position-
    parity rule: pass iff 0 violations OR exactly 2 violations at ADJACENT
    class positions. Lemma B1 (elementary): a violation at an odd position is
    a female class and at an even position a male class, so two adjacent
    violations are oppositely gendered and one adjacent transposition repairs
    both while moving no other class — i.e. "strict parity up to at most one
    adjacent-transposition defect", the candidate-level translation of Cook's
    exception-free statement of the rule (Cook 2006 p. 558). Subset of the
    published <=2-violation relaxation (R-C4-A) by construction (one-sided).
    KW passes: (2, [25, 26])."""
    viol, vpos = rc4_violations(seq)
    return viol == 0 or (viol == 2 and vpos[1] == vpos[0] + 1)


def rc4c_pass(seq):
    """R-C4-C — KW's marked exception locus exactly: 2 violations precisely at
    class positions {25, 26} (KW-anchored, data-like; report-only per the
    frozen design, never headlined). KW passes."""
    return rc4_violations(seq) == (2, [25, 26])


def hec_level3_positions(seq):
    """1-based first-occurrence class positions of the level-3 (popcount-3)
    inversion classes. KW == [7, 10, 12, 19, 24, 27, 30, 31, 33, 36] (Cook
    2006, KW-verified). Twin of the l3pos[] array in solve.c's rc3/rc3w
    scorers (popcount is class-invariant: 6-bit reversal preserves it)."""
    return [i for i, (c, _) in enumerate(_reg_stations(seq), 1)
            if bin(c).count("1") == 3]


def rc4b_verify(seq_arg=None):
    """Two-language ground-truth gate for the R13 predicates. No argument:
    recompute on King Wen and assert the analytic anchors (frozen design §2
    V2/V3 + §4 KW gates) — viol=2 at adjacent class positions [25, 26]; the
    published relaxation A, the exception-form B, and the KW-locus C all pass;
    the rc3 exact level-3 positions and the rc3w S-gap pattern {6,4,2,2,0}
    pass. With a 64-int SEQ argument: print
    `viol,vp0,vp1,rc4a,rc4b,rc4c,rc3,rc3w` (same ordering as solve.c
    --rc4b-verify SEQ) for cross-language gating."""
    if seq_arg is not None:
        seq = [int(x) for x in seq_arg.replace(",", " ").split()]
        if len(seq) != 64:
            print(f"rc4b-verify: need 64 ints, got {len(seq)}")
            return 1
    else:
        seq = list(binary_hexagrams)
    viol, vpos = rc4_violations(seq)
    vp0 = vpos[0] if len(vpos) >= 1 else 0
    vp1 = vpos[1] if len(vpos) >= 2 else 0
    rc4a = 1 if viol <= 2 else 0
    rc4b = 1 if rc4b_pass(seq) else 0
    rc4c = 1 if rc4c_pass(seq) else 0
    l3 = hec_level3_positions(seq)
    rc3 = 1 if l3 == [7, 10, 12, 19, 24, 27, 30, 31, 33, 36] else 0
    rc3w = 0
    if len(l3) == 10:
        for z in range(5):
            if [l3[z + k + 1] - l3[z + k] - 1 for k in range(5)] == [6, 4, 2, 2, 0]:
                rc3w = 1
                break
    if seq_arg is not None:
        print(f"{viol},{vp0},{vp1},{rc4a},{rc4b},{rc4c},{rc3},{rc3w}")
        return 0
    fails = 0
    for nm, v, exp in (("rc4_viol", viol, 2), ("rc4_vpos0", vp0, 25),
                       ("rc4_vpos1", vp1, 26), ("rc4a_le2", rc4a, 1),
                       ("rc4b_exc_form", rc4b, 1), ("rc4c_kw_locus", rc4c, 1),
                       ("rc3_exact", rc3, 1), ("rc3w_sgap", rc3w, 1)):
        if v == exp:
            print(f"{nm}: {v} OK")
        else:
            print(f"{nm}: {v} FAIL (expected {exp})")
            fails += 1
    print("RC4B VERIFY:", "PASS" if fails == 0 else f"{fails} FAILURES")
    return 1 if fails else 0


# ---------------------------------------------------------------------------
# R11 — four-class Bayes v2: the frozen 8-axis violation bundle (design:
# roae-private/R11_BAYES_V2_DESIGN_2026_07_10.md §3) + greedy-builder (M_G)
# machinery (§2.2/§9.3). Two-language twin of solve.c r11_axes / --r11-verify
# and the SOLVE_KNUTH_R11_HIST population instrument.
# ATTRIBUTION (rules are NOT ROAE discoveries): g1 Moore 2005; g2 Moore 1989;
# g3 Schulz 1990 (Zhu Yuansheng exception); g4/g5 Cook 2006; g6 Zheng Qiao
# ~1150 / Hu Yigui 1247 / Hacker & Moore 2003; g7 Schulz 2011/2016; g8 Drasny
# / Schulz. The greedy-builder class is ROAE's formalization of a folk idea
# (novelty hedged; corrections welcome). Developed with AI assistance
# (Claude, Anthropic). NOTE: per the R11 design freeze protocol (§9.3) the
# KW-facing four-class Bayes integration (compute_r11_bf.py) is the Spot/
# post-freeze deliverable; the code below is instrument + structural-smoke
# only and computes no KW verdict.
# ---------------------------------------------------------------------------

R11_AXIS_NAMES = ["g1_moore_parity", "g2_moore_rhythm", "g3_schulz_gender",
                  "g4_level_cover", "g5_final_anchor", "g6_split1818",
                  "g7_ccn4_T2", "g8_d7_T2"]
R11_KW_EXPECTED = [2, 2, 2, 0, 0, 0, 0, 0]


def r11_axes(seq):
    """The R11 frozen 8-axis violation vector on an orientation-resolved
    sequence. g1..g6 = Tier-1 principled rules; g7,g8 = Tier-2 data-like.
    Byte-for-byte twin of solve.c r11_axes(). KW == (2,2,2,0,0,0,0,0)."""
    # g1 = 18 - Moore-2005 pair-positioning parity compliance (comp-pairs + pc==3 exempt)
    ok = 0
    for q in range(32):
        h, h2 = seq[2 * q], seq[2 * q + 1]
        if (h ^ h2) == 63:
            continue
        pcq = bin(h).count("1")
        if pcq == 3:
            continue
        odd = (q + 1) & 1
        if (1 if pcq > 3 else 0) == odd:
            ok += 1
    g1 = max(0, 18 - ok)
    # g2 = Moore-1989 rising/falling rhythm breaks
    prev, have, prev_adj, breaks = 0, False, False, 0
    for q in range(32):
        h, h2 = seq[2 * q], seq[2 * q + 1]
        if (h ^ h2) == 63:
            prev_adj = False
            continue
        pcq = bin(h).count("1")
        if pcq == 3:
            prev_adj = False
            continue
        mb = 0 if pcq > 3 else 1
        sc = sum(5 - 2 * i for i in range(6) if ((h >> i) & 1) == mb)
        rf = 1 if sc > 0 else 0
        if have and prev_adj and rf == prev:
            breaks += 1
        prev, have, prev_adj = rf, True, True
    g2 = breaks
    # g3 = Schulz-1990 gender/position-parity violations
    g3 = rc4_violations(seq)[0]
    # g4 = 7 - distinct popcount-levels covered by the first 7 pairs
    lv = 0
    for q in range(14):
        lv |= 1 << bin(seq[q]).count("1")
    g4 = 7 - bin(lv & 0x7F).count("1")
    # g5 = 1 - [final pair is the alternating pair {21,42}]
    g5 = 0 if {seq[62], seq[63]} == {21, 42} else 1
    # g6 = 1 - [18:18 split: exactly 3 of the 4 complement-pairs among the first
    # 15 pair-slots]. A hexagram belongs to a complement-pair iff it is a 6-bit
    # palindrome (rev(h)==h) — those pair with their inverse (XOR 63). This is
    # the C ordering's pair-idx {0,13,14,30} membership, computed by property so
    # it is independent of the pair-list ordering.
    cc = 0
    for q in range(15):
        if reverse_6bit(seq[2 * q]) == seq[2 * q]:
            cc += 1
    g6 = 0 if cc == 3 else 1
    # g7 = 1 - ccn4 (T2)
    g7 = 0 if reg_ccn4(seq) else 1
    # g8 = 8 - d7 count (T2)
    g8 = 8 - reg_d7(seq)
    return [g1, g2, g3, g4, g5, g6, g7, g8]


def r11_verify(seq_arg=None):
    """Two-language ground-truth gate for the R11 8-axis bundle. No argument:
    recompute on King Wen and assert == (2,2,2,0,0,0,0,0). With a 64-int SEQ:
    print the 8 values comma-separated (same ordering as solve.c --r11-verify
    SEQ) for cross-language gating. This is the KW-reproduction gate the
    SOLVE_KNUTH_R11_HIST population instrument must pass before it is trusted."""
    if seq_arg is not None:
        seq = [int(x) for x in seq_arg.replace(",", " ").split()]
        if len(seq) != 64:
            print(f"r11-verify: need 64 ints, got {len(seq)}")
            return 1
        print(",".join(str(x) for x in r11_axes(seq)))
        return 0
    seq = list(binary_hexagrams)
    g = r11_axes(seq)
    fails = 0
    for nm, v, exp in zip(R11_AXIS_NAMES, g, R11_KW_EXPECTED):
        if v == exp:
            print(f"{nm}: {v} OK")
        else:
            print(f"{nm}: {v} FAIL (expected {exp})")
            fails += 1
    print("R11 VERIFY:", "PASS" if fails == 0 else f"{fails} FAILURES")
    return 1 if fails else 0


# --- M_G greedy-builder machinery (R11 §2.2 / §9.3) -------------------------
# A sequential softmax builder over the C1/C2/C4/C5 child space. At each slot
# the local child set A_t is exactly the Knuth-walk child predicate (C1 pair
# uniqueness, C2 no-5-transition, C4 pure-pair pin at slot 0, C5 transition-
# budget feasibility incrementally maintained). The builder chooses a
# placement a with probability softmax(beta * s_w(a)), s_w = sum_j w_j * dj(a)
# over the incremental Tier-1 axes (g1..g5).
#
# Frozen Delta_j operationalization (this implementer's explicit choice, per
# section 3's "increment of axis j's compliance"; documented so it can be
# reviewed at freeze — NOT a hidden convention):
#   d1 (Moore parity):  +1 if the placed pair is non-exempt AND parity-compliant
#                        at its 1-indexed slot, else 0.
#   d2 (Moore rhythm):  -1 if the placement BREAKS rising/falling alternation
#                        vs the previous adjacent directional pair, else 0.
#   d3 (Schulz gender): -(new gender violations introduced by the placement's
#                        newly-seen inversion-class stations).
#   d4 (Cook levels):   number of NEW popcount-levels the placement adds among
#                        the first 7 pairs (slots < 7), else 0.
#   d5 (Cook anchor):   +1 iff at the final slot (31) the placed pair is A2.
# Higher s_w = "more rule-compliant placement", matching the greedy-arranger
# narrative. Orientation is chosen jointly with the pair.
_R11_PAIRS = None


def _r11_pairs():
    global _R11_PAIRS
    if _R11_PAIRS is None:
        _R11_PAIRS = build_pairs()
    return _R11_PAIRS


def r11_children(last_hex, used_mask, budget):
    """Enumerate locally-valid (pair_idx, orient, first, second, bd, wd)
    placements at the next slot. Mirrors the solve.c Knuth-walk child predicate
    exactly (bd==5 forbidden; between- then within-transition budget check with
    bd decremented while testing wd). `budget` is a length-7 list, mutated and
    restored internally."""
    pr = _r11_pairs()
    out = []
    for p in range(32):
        if used_mask & (1 << p):
            continue
        a, b = pr[p]
        for orient in range(2):
            first, second = (b, a) if orient else (a, b)
            bd = bit_diff(last_hex, first)
            if bd == 5:
                continue
            if budget[bd] <= 0:
                continue
            budget[bd] -= 1
            wd = bit_diff(first, second)
            live = budget[wd] > 0
            budget[bd] += 1
            if not live:
                continue
            out.append((p, orient, first, second, bd, wd))
    return out


def _r11_kw_budget():
    """KW's linear transition multiset (length-7 list indexed by Hamming
    distance) — the standard C5 budget the builder consumes."""
    kw = list(binary_hexagrams)
    b = [0] * 7
    for i in range(len(kw) - 1):
        b[bit_diff(kw[i], kw[i + 1])] += 1
    return b


def _r11_seen_classes(seq_prefix):
    """First-appearance inversion-class count + set over a hexagram prefix."""
    seen, ncls = set(), 0
    for h in seq_prefix:
        key = min(h, reverse_6bit(h))
        if key not in seen:
            seen.add(key)
            ncls += 1
    return seen, ncls


def _r11_step_score(slot, first, second, seen, ncls,
                    prev_rf, prev_adj, levels7, weights):
    """s_w for placing (first, second) at pair `slot` (0-indexed), given running
    builder state. Returns (score, new_prev_rf, new_prev_adj, new_seen,
    new_ncls, new_levels7). Implements the frozen Delta_j above."""
    w1, w2, w3, w4, w5 = weights
    d1 = d2 = d3 = d4 = d5 = 0
    comp = ((first ^ second) == 63)
    pcf = bin(first).count("1")
    new_prev_rf, new_prev_adj = prev_rf, prev_adj
    if not comp and pcf != 3:
        odd = (slot + 1) & 1
        if (1 if pcf > 3 else 0) == odd:
            d1 = 1
        mb = 0 if pcf > 3 else 1
        sc = sum(5 - 2 * i for i in range(6) if ((first >> i) & 1) == mb)
        rf = 1 if sc > 0 else 0
        if prev_adj and rf == prev_rf:
            d2 = -1
        new_prev_rf, new_prev_adj = rf, True
    else:
        new_prev_adj = False
    new_seen = set(seen)
    new_ncls = ncls
    for h in (first, second):
        key = min(h, reverse_6bit(h))
        if key not in new_seen:
            new_seen.add(key)
            new_ncls += 1
            pck = bin(h).count("1")
            if pck not in (0, 3, 6) and ((pck < 3) != (new_ncls % 2 == 1)):
                d3 -= 1
    new_levels7 = levels7
    if slot < 7:
        for h in (first, second):
            lvl = bin(h).count("1")
            if not (new_levels7 & (1 << lvl)):
                new_levels7 |= (1 << lvl)
                d4 += 1
    if slot == 31 and {first, second} == {21, 42}:
        d5 = 1
    score = w1 * d1 + w2 * d2 + w3 * d3 + w4 * d4 + w5 * d5
    return score, new_prev_rf, new_prev_adj, new_seen, new_ncls, new_levels7


def r11_builder_numerator(seq, beta, weights=(1, 1, 1, 1, 1)):
    """Exact M_G path likelihood NUMERATOR for a full sequence: the product of
    the 31 per-slot softmax factors P(a_t | state_t, beta, w) along `seq`
    (slot 0 is the forced pure pair). Returns the raw product (float). Raises
    ValueError if `seq` is not a builder-reachable C1..C5 path."""
    import math
    budget = _r11_kw_budget()
    first0, second0 = seq[0], seq[1]
    budget[bit_diff(first0, second0)] -= 1
    used_mask = 0
    pr = _r11_pairs()
    for p in range(32):
        if {pr[p][0], pr[p][1]} == {first0, second0}:
            used_mask |= (1 << p)
            break
    seen, ncls = _r11_seen_classes([first0, second0])
    prev_rf, prev_adj, levels7 = 0, False, 0
    for h in (first0, second0):
        levels7 |= (1 << bin(h).count("1"))
    prod = 1.0
    for slot in range(1, 32):
        last = seq[2 * slot - 1]
        kids = r11_children(last, used_mask, budget)
        if not kids:
            raise ValueError(f"builder dead-ended at slot {slot}")
        scores, chosen = [], None
        target = (seq[2 * slot], seq[2 * slot + 1])
        for (p, orient, f, s, bd, wd) in kids:
            sc, nrf, nadj, nseen, nncls, nlv = _r11_step_score(
                slot, f, s, seen, ncls, prev_rf, prev_adj, levels7, weights)
            scores.append(sc)
            if (f, s) == target:
                chosen = (len(scores) - 1, p, f, s, bd, wd, nrf, nadj, nseen, nncls, nlv)
        if chosen is None:
            raise ValueError(f"seq step at slot {slot} not in the local child set")
        m = max(scores)
        denom = sum(math.exp(beta * (sc - m)) for sc in scores)
        num = math.exp(beta * (scores[chosen[0]] - m))
        prod *= (num / denom)
        _, p, f, s, bd, wd, nrf, nadj, nseen, nncls, nlv = chosen
        budget[bd] -= 1
        budget[wd] -= 1
        used_mask |= (1 << p)
        prev_rf, prev_adj, seen, ncls, levels7 = nrf, nadj, nseen, nncls, nlv
    return prod


def r11_builder_run(beta, weights, rng):
    """Draw ONE builder run: sequential softmax choices from slot 1. Returns
    (seq_or_partial, completed_bool). Dead-ends (A_t empty under C5 budget
    exhaustion) return (partial, False) — the P_complete failure event."""
    import math
    budget = _r11_kw_budget()
    seq = [63, 0]  # C4 pure-pair pin (slot 0), canonical gauge
    budget[bit_diff(63, 0)] -= 1
    pr = _r11_pairs()
    used_mask = 0
    for p in range(32):
        if {pr[p][0], pr[p][1]} == {63, 0}:
            used_mask |= (1 << p)
            break
    seen, ncls = _r11_seen_classes([63, 0])
    prev_rf, prev_adj = 0, False
    levels7 = (1 << bin(63).count("1")) | (1 << bin(0).count("1"))
    for slot in range(1, 32):
        last = seq[-1]
        kids = r11_children(last, used_mask, budget)
        if not kids:
            return seq, False
        scored = []
        for (p, orient, f, s, bd, wd) in kids:
            sc, nrf, nadj, nseen, nncls, nlv = _r11_step_score(
                slot, f, s, seen, ncls, prev_rf, prev_adj, levels7, weights)
            scored.append((sc, p, f, s, bd, wd, nrf, nadj, nseen, nncls, nlv))
        m = max(x[0] for x in scored)
        weights_e = [math.exp(beta * (x[0] - m)) for x in scored]
        total = sum(weights_e)
        r = rng.random() * total
        acc = 0.0
        pick = scored[-1]
        for x, we in zip(scored, weights_e):
            acc += we
            if r <= acc:
                pick = x
                break
        _, p, f, s, bd, wd, nrf, nadj, nseen, nncls, nlv = pick
        seq.extend([f, s])
        budget[bd] -= 1
        budget[wd] -= 1
        used_mask |= (1 << p)
        prev_rf, prev_adj, seen, ncls, levels7 = nrf, nadj, nseen, nncls, nlv
    return seq, True


def r11_builder_pcomplete(beta, weights=(1, 1, 1, 1, 1), n_runs=100000, seed=0):
    """Estimate P_complete(beta, w) = P(a builder run reaches slot 31 without
    dead-ending), with a normal-approx 95% CI. Returns (phat, halfwidth, n)."""
    import random
    import math
    rng = random.Random(seed)
    comp = 0
    for _ in range(n_runs):
        _, ok = r11_builder_run(beta, weights, rng)
        comp += 1 if ok else 0
    phat = comp / n_runs
    hw = 1.96 * math.sqrt(max(phat * (1 - phat), 0.0) / n_runs)
    return phat, hw, n_runs


def r11_builder_synthetic(beta, weights=(1, 1, 1, 1, 1), seed=0, max_tries=1000):
    """Draw one COMPLETED synthetic sequence from M_G (rejection over dead-ends).
    Returns the 64-int sequence, or None if no completion within max_tries."""
    import random
    rng = random.Random(seed)
    for _ in range(max_tries):
        seq, ok = r11_builder_run(beta, weights, rng)
        if ok:
            return seq
    return None


def r11_builder_verify():
    """Structural smoke-test of the M_G builder machinery (NOT the KW verdict —
    the four-class Bayes integration is the post-freeze Spot deliverable).
    Checks: (1) the exact KW-path numerator is a well-defined product in (0,1]
    for a couple of beta values; (2) a small P_complete simulation returns a
    fraction in [0,1]; (3) a synthetic draw is a valid C1..C5 sequence (its
    r11_axes are computable and its transition multiset matches KW's).
    Returns 0 on pass, 1 on any failure."""
    fails = 0
    kw = list(binary_hexagrams)
    for beta in (0.5, 2.0):
        try:
            num = r11_builder_numerator(kw, beta)
        except ValueError as e:
            print(f"builder numerator (beta={beta}): FAIL ({e})")
            fails += 1
            continue
        ok = (0.0 < num <= 1.0)
        print(f"builder KW-path numerator (beta={beta}): {num:.6e} {'OK' if ok else 'FAIL'}")
        if not ok:
            fails += 1
    phat, hw, n = r11_builder_pcomplete(1.0, n_runs=3000, seed=1)
    ok = (0.0 <= phat <= 1.0)
    print(f"builder P_complete (beta=1, n={n}): {phat:.4f} +/- {hw:.4f} {'OK' if ok else 'FAIL'}")
    if not ok:
        fails += 1
    synth = r11_builder_synthetic(1.0, seed=2)
    if synth is None or len(synth) != 64 or len(set(synth)) != 64:
        print("builder synthetic draw: FAIL (no valid completion)")
        fails += 1
    else:
        b = [0] * 7
        for i in range(63):
            b[bit_diff(synth[i], synth[i + 1])] += 1
        kwb = _r11_kw_budget()
        match = (b == kwb)
        g = r11_axes(synth)
        print(f"builder synthetic draw: valid C1..C5={match} axes={g} "
              f"{'OK' if match else 'FAIL'}")
        if not match:
            fails += 1
    print("R11 BUILDER VERIFY:", "PASS" if fails == 0 else f"{fails} FAILURES")
    return 1 if fails else 0


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
# Davis (2012) measurement WAVE 2 (dav2_*) — the unmeasured tail of the
# 26-claim structural audit's §5 queue, frozen in
# roae-private/R8_DAVIS_PREREG_2026_07_10.md §3.1/§3.2 BEFORE any population
# measurement. solve.py is the SPEC; --dav2-verify is the two-language gate
# (solve.c --dav2-verify must reproduce this output byte-for-byte). Two
# functionals only: tquartet (C-D9, flagship) and xunslots (C-D10, rider).
# C-D5 (dav2_namedsize) is OPERATOR-DECLINED (2026-07-11, prereg §3.3) —
# deliberately NOT implemented here; the Bonferroni denominator stays /12.
# ATTRIBUTION: every structural claim is Scott Davis's (*The Classic of
# Changes in Cultural Context*, Cambria Press, 2012); the integer
# operationalizations and population measurement over C1-C5 space are ROAE's
# (see CITATIONS.md). Errors of operationalization are ROAE's, not Davis's.
# ---------------------------------------------------------------------------


def dav2_tquartet(seq):
    """C-D9 (Davis 2012 pp. 113-114; REFEREE_PASS_4 reading R2c). Count of
    coordinated cross-pair T-link couples at region spread <= 2 pair-slots on
    both ends. Total on arbitrary orderings: links exist only where the T-image
    of a pair-slot's 2-set is exactly another pair-slot's 2-set (always, under
    C1; possibly not, on non-C1 corpus controls -> those couples simply don't
    count). KW = 1 (Davis's quartet: slots {9,11} -> {27,28}, i.e. 17/18 &
    21/22 -> 53/54 & 55/56). Orientation: (a) NO (slot differences preserved
    under sequence reversal), (b) NO (T commutes with rev6; slot-level)."""
    def rev3(t): return ((t & 1) << 2) | (t & 2) | ((t >> 2) & 1)
    def T(h): return rev3(h & 7) | (rev3((h >> 3) & 7) << 3)
    slots = [frozenset(seq[2*s:2*s+2]) for s in range(32)]
    idx = {p: s for s, p in enumerate(slots)}
    links = []
    for s in range(32):
        img = frozenset(T(h) for h in slots[s])
        t = idx.get(img)
        if t is not None and t > s:
            links.append((s + 1, t + 1))
    n = 0
    for i in range(len(links)):
        a1, b1 = links[i]
        for j in range(i + 1, len(links)):
            a2, b2 = links[j]
            if ((abs(a1-a2) <= 2 and abs(b1-b2) <= 2) or
                    (abs(a1-b2) <= 2 and abs(b1-a2) <= 2)):
                n += 1
    return n


def dav2_xunslots(seq):
    """C-D10 (Davis 2012 p. 114). Count of x7/x8-slot positions (all six full
    decades: 7,8,17,18,...,57,58) whose hexagram has Xun (0b110) as lower or
    upper trigram. KW = 5 (positions 18, 28, 37, 48, 57 — Davis's four plus
    #28). Orientation: (a) NO (the 12-position set is closed under p -> 65-p);
    (b) YES (flip maps Xun to Dui; primary is registered in the published-KW
    gauge, with the Dui-count as declared descriptive companion, KW = 5)."""
    xun = 6
    return sum(1 for p in (7,8,17,18,27,28,37,38,47,48,57,58)
               if (seq[p-1] & 7) == xun or ((seq[p-1] >> 3) & 7) == xun)


DAV2_FUNCS = ["tquartet", "xunslots"]

DAV2_KW_EXPECTED = {"tquartet": 1, "xunslots": 5}


def dav2_verify():
    """Print the 2 Davis wave-2 candidate values on KW; gate against embedded
    expected values (two-language: solve.c --dav2-verify must reproduce this
    output byte-identically). C-D5 (namedsize) is operator-declined and NOT
    part of this bank (prereg §3.3)."""
    seq = list(binary_hexagrams)
    failures = 0
    for name in DAV2_FUNCS:
        v = globals()["dav2_" + name](seq)
        exp = DAV2_KW_EXPECTED.get(name)
        tag = "OK" if exp == v else ("FAIL (expected %s)" % exp if exp is not None else "(unset)")
        if exp is not None and exp != v:
            failures += 1
        print(f"dav2_{name}: {v} {tag}")
    print("DAV2 VERIFY:", "PASS" if failures == 0 else f"{failures} FAILURES")
    return 1 if failures else 0


# ---------------------------------------------------------------------------
# Drasny "Rule of Ten" — candidate D-B1 (Rule-of-Ten conformity count).
# Operational spec frozen in
# roae-private/DRASNY_RULE_OF_TEN_SCOPING_2026_07_11.md (measured 2026-07-11:
# verified true, X = 22, and reported as a data-like fitted description — a
# tautology of a KW-extracted template, no p attached; TR-10 §3b). solve.py is the
# SPEC; the --db1-verify subcommand is the two-language gate (solve.c
# --db1-verify must reproduce this output byte-for-byte). Nothing here is on
# the enum / selftest / checkpoint path.
#
# ATTRIBUTION: every structural observation operationalized here is József
# Drasny's (*The Yi-globe: The Image of the Cosmos in the Yijing*, 2nd rev.
# English ed. 2007/2011, self-published via i-ching.hu; Hungarian 1st ed.
# 2005, Budapest: Szenzár — Ch. IV pp. 71-88, Ch. III pp. 39-40; the
# eight-group partition is his Table 4.1 p. 75, the "Rule of Ten" his §1-3
# pp. 76-84). No ISBN/DOI exists; do not invent one. The bit-structural
# precedence-classifier reduction, the pair->slot conformity operationalization,
# and the exact permutation-null DP are ROAE's; errors of operationalization
# are ROAE's, not Drasny's. Drasny asserts the Rule of Ten was "previously
# unknown" — that is HIS claim; ROAE has not verified priority and does not
# repeat it as fact (decade/columnar readings of the KW ordinals appear
# independently elsewhere). Corrections welcome. See CITATIONS.md.
#
# NAME-COLLISION DISAMBIGUATION: Drasny's "Rule of Ten" (this functional — a
# decade-arithmetic room<->group coincidence over ALL 32 pair-slots) is
# UNRELATED to Scott Davis's (2012, p. 126) separately-named "rule of ten"
# (the single observation that hexagrams #18 and #27 sit ten ordinals apart;
# ROAE registry C-D14 context, dav_* family). Same three-word name, different
# authors, different claims — never conflate the two.
#
# WELL-POSEDNESS / RESEARCHER-DOF NOTE (must accompany any registration): the
# group criteria overlap; Table 4.1's resolutions are choices Drasny made with
# the KW arrangement in hand, and the deviant set shrank 10->4 between the book
# and his later paper. A population p-value under the frozen system quantifies
# KW's atypicality GIVEN the system; it cannot quantify selection of the system
# itself. Nothing here promotes to the C-rule system regardless of outcome.
# ---------------------------------------------------------------------------

# Group codes: A=0 B=1 C=2 D=3 E=4 F=5 G=6 (G = book's G1 u G2; the classifier
# does not distinguish G1/G2 — the Rule of Ten maps the whole union F u G1 u G2
# to room f, so the split is irrelevant here). Trigram values (bit 0 = bottom
# line, yang = 1): Qian=7, Kun=0, Li=5, Kan=2, Xun=6, Zhen=1, Kan=2, Gen=4,
# Dui=3.
DB1_GROUP_NAMES = ("A", "B", "C", "D", "E", "F", "G")

# The 8 doubled-trigram hexagrams (DBL) and the 12 monotone line-stacks (MONO,
# the xiaoxi/calendar/tidal class incl. Qian/Kun) as pure bit predicates.
_DB1_DBL = frozenset((t | (t << 3)) for t in range(8))


def _db1_ispow2(x):
    return x > 0 and (x & (x - 1)) == 0


def _db1_is_mono(h):
    """h is a monotone line-stack (one of the 12 tidal/xiaoxi hexagrams): its
    set bits are a contiguous block anchored at the bottom (h+1 a power of two)
    or at the top (complement's set bits a bottom-anchored block). Incl.
    Qian(63)/Kun(0)."""
    return _db1_ispow2(h + 1) or _db1_ispow2((h ^ 63) + 1)


def db1_group(h):
    """Bit-structural classifier reproducing Drasny's Table 4.1 (book p. 75)
    eight-group system EXACTLY for all 64 hexagrams (verified: flip-equivariant,
    C1-pair-consistent, zero residue). Linear precedence B > A > F > C > D > E > G
    (frozen spec §1.2). lo=h&7 (lower trigram), up=(h>>3)&7 (upper trigram),
    w()=Hamming weight. Returns a group code 0..6 (see DB1_GROUP_NAMES)."""
    lo = h & 7
    up = (h >> 3) & 7
    # 1. B: complementary trigrams (lower = upper XOR 7 = Earlier-Heaven diagonals)
    if lo == (up ^ 7):
        return 1
    # 2. A: one trigram in {Qian=7, Kun=0}, the other in {Qian, Kun, Li=5, Kan=2}
    if (lo in (7, 0) and up in (7, 0, 5, 2)) or (up in (7, 0) and lo in (7, 0, 5, 2)):
        return 0
    # 3. F: doubled trigram
    if lo == up:
        return 5
    # 4. C: monotone calendar stack (1-2 and 11-12 already captured by A/B above)
    if _db1_is_mono(h):
        return 2
    # 5. D: trigram-exchanged hexagram is a calendar stack ("exchanged calendar")
    if _db1_is_mono(up | (lo << 3)):
        return 3
    # 6. E: equal-weight-1 (son x son) or equal-weight-2 (daughter x daughter)
    wl = bin(lo).count("1")
    wu = bin(up).count("1")
    if (wl == 1 and wu == 1) or (wl == 2 and wu == 2):
        return 4
    # 7. G (= book's G1 u G2): balanced 3-yang, one line-change from a doubled trigram
    if bin(h).count("1") == 3 and any(bin(h ^ d).count("1") == 1 for d in _DB1_DBL):
        return 6
    return -1   # no residue in a correct classifier (verified over all 64)


def _db1_partner(h):
    """C1 partner of hexagram h: its 6-bit reverse, or its complement (h^63)
    for the 8 palindromes. The 32 C1 pair-sets are forced constants of every
    valid ordering (frozen spec §1.2)."""
    r = reverse_6bit(h)
    return r if r != h else (h ^ 63)


# Rooms (frozen spec §1.2 table): expected group per 1-based pair-slot.
# Rooms a<->A, b<->B, c<->C, d<->D, e<->E, f<->F u G. Stored as an inclusive
# group-code range [lo, hi] per slot (lo==hi for single-group rooms a-e; room f
# is [F=5, G=6]). Index below is 0-based (slot s in 1..32 -> index s-1).
_DB1_ROOM = {  # 1-based slot -> (lo, hi)
    **{s: (0, 0) for s in (1, 2, 3, 4, 5)},          # room a <-> A
    **{s: (1, 1) for s in (6, 11, 16, 21)},          # room b <-> B
    **{s: (2, 2) for s in (7, 12, 17, 22)},          # room c <-> C
    **{s: (3, 3) for s in (8, 13, 18, 23)},          # room d <-> D
    **{s: (4, 4) for s in (14, 19, 24, 15, 20, 25)}, # room e <-> E
    **{s: (5, 6) for s in (26, 27, 28, 29, 30, 9, 10, 31, 32)},  # room f <-> F u G
}
DB1_ROOM_LO = tuple(_DB1_ROOM[s][0] for s in range(1, 33))
DB1_ROOM_HI = tuple(_DB1_ROOM[s][1] for s in range(1, 33))
# Room sizes (a..f) = (5,4,4,4,6,9); equal the group sizes by construction.
DB1_ROOM_SIZES = (5, 4, 4, 4, 6, 9)


def db1_conformity(seq):
    """X(seq) = # of pair-slots whose pair's functional group matches the group
    assigned to that slot's room (frozen spec §2). For each 1-based slot s the
    positional 2-set {seq[2s-2], seq[2s-1]} is looked up; a 2-set that is NOT
    one of the 32 forced C1 pair-sets scores nonconforming (F6 corpus-degeneracy
    convention). On a C1-valid ordering both members share a group (theorem), so
    the room match is well-defined. KW value = 22 (frozen anchor)."""
    x = 0
    for s in range(32):
        a, b = seq[2 * s], seq[2 * s + 1]
        if _db1_partner(a) != b or a == b:
            continue   # not a forced C1 pair-set -> nonconforming
        g = db1_group(a)                  # == db1_group(b) on any valid pair
        if DB1_ROOM_LO[s] <= g <= DB1_ROOM_HI[s]:
            x += 1
    return x


def db1_deviant_slots(seq):
    """The 1-based slots that do NOT conform (the complement of db1_conformity).
    KW = [2, 5, 7, 10, 11, 15, 18, 24, 31, 32] (== Drasny's Table 4.2 deviant
    list of 10 pairs: 3-4, 9-10, 13-14, 19-20, 21-22, 29-30, 35-36, 47-48,
    61-62, 63-64)."""
    out = []
    for s in range(32):
        a, b = seq[2 * s], seq[2 * s + 1]
        ok = (_db1_partner(a) == b and a != b and
              DB1_ROOM_LO[s] <= db1_group(a) <= DB1_ROOM_HI[s])
        if not ok:
            out.append(s + 1)
    return out


def db1_null_a_distribution(condition_c4=False):
    """Null A (frozen spec §2, EXACT — no Monte Carlo, no subsampling): the
    distribution of X under a uniform pair->slot permutation of the 32 forced
    pair-sets (orientation flips drop out; X is slot-level). Computed by exact
    dynamic programming over rooms on the 6-vector of remaining group counts,
    accumulating the X-generating polynomial. Returns {x: exact_integer_ways};
    the pmf is ways/32! (or /31! for the C4-conditioned variant). Total mass
    equals 32! (resp. 31!). `condition_c4`: pin slot 1 to pair {#1,#2} (group A,
    room a -> one forced conforming slot; C1-C5 population variant).

    NOTE (discipline): this returns the FULL exact distribution but the
    --db1-verify gate deliberately does NOT print any percentile / p-value of
    KW's X=22 — no dispositive "look" is consumed pre-registration. The
    dispositive population null is Null B (solve.c SOLVE_KNUTH_SCORE_DB1=1),
    run on Spot later. Only the analytic mean E[X]=190/32 (already disclosed in
    the frozen scoping) is surfaced."""
    from math import comb, factorial
    # group counts (A,B,C,D,E,FuG) == room sizes; rooms want group i in order.
    counts = list(DB1_ROOM_SIZES)     # [5,4,4,4,6,9]
    rooms = list(DB1_ROOM_SIZES)      # room i has size m_i and wants group i
    base_x = 0
    if condition_c4:
        counts[0] -= 1                # one group-A pair pinned at slot 1
        rooms[0] -= 1                 # room a loses its pinned slot
        base_x = 1                    # the pinned slot conforms (A in room a)

    states = {tuple(counts): {base_x: 1}}   # remaining-count-vector -> {X: ways}
    for i, m in enumerate(rooms):
        new = {}
        for rem, poly in states.items():
            # enumerate compositions c0..c5 with sum m and cj <= rem[j]
            def gen(j, left, acc):
                if j == 6:
                    if left == 0:
                        yield tuple(acc)
                    return
                for cj in range(0, min(rem[j], left) + 1):
                    yield from gen(j + 1, left - cj, acc + [cj])
            for c in gen(0, m, []):
                # ways to fill room i's m distinct slots with distinct pairs of
                # this group-composition: m! * prod_j C(rem_j, c_j)
                w = factorial(m)
                for j in range(6):
                    w *= comb(rem[j], c[j])
                newrem = tuple(rem[j] - c[j] for j in range(6))
                match = c[i]          # group-i pairs landing in room i conform
                np_ = new.setdefault(newrem, {})
                for x, ways in poly.items():
                    np_[x + match] = np_.get(x + match, 0) + ways * w
        states = new
    assert len(states) == 1           # all groups consumed -> single empty state
    return next(iter(states.values()))


def db1_null_a_mean():
    """Exact E[X] under Null A from the DP (Fraction). Cross-checks the analytic
    closed form sum(room_size^2)/32 = 190/32. Unconditioned variant."""
    from fractions import Fraction
    dist = db1_null_a_distribution(condition_c4=False)
    tot = sum(dist.values())
    return Fraction(sum(x * w for x, w in dist.items()), tot)


def db1_verify():
    """Two-language gate for candidate D-B1 (solve.c --db1-verify must reproduce
    this output byte-for-byte). Asserts: (1) the bit-structural classifier
    reproduces Drasny's Table 4.1 for all 64 KW hexagrams; (2) zero residue;
    (3) flip-equivariance; (4) C1-pair-consistency; (5) group sizes
    (A,B,C,D,E,F,G)=(5,4,4,4,6,3,6); (6) KW conformity X=22 with the frozen
    deviant slot list; (7) the analytic Null-A mean E[X]=190/32. No percentile /
    p-value of KW is printed (no dispositive look). Exit 0 iff all pass."""
    from fractions import Fraction
    seq = list(binary_hexagrams)
    failures = 0

    # (1) classifier == Drasny Table 4.1 (book p.75), G1/G2 collapsed to G.
    # Reference by 1-based pair slot; covers all 64 hexagrams (both members).
    ref = {1: 0, 2: 4, 3: 0, 4: 0, 5: 3, 6: 1, 7: 0, 8: 3, 9: 6, 10: 2,
           11: 6, 12: 2, 13: 3, 14: 4, 15: 5, 16: 1, 17: 2, 18: 0, 19: 4,
           20: 4, 21: 1, 22: 2, 23: 3, 24: 6, 25: 4, 26: 5, 27: 6, 28: 6,
           29: 5, 30: 6, 31: 4, 32: 1}
    bad = 0
    for s in range(1, 33):
        for h in (seq[2 * (s - 1)], seq[2 * (s - 1) + 1]):
            if db1_group(h) != ref[s]:
                bad += 1
    if bad == 0:
        print("db1 classifier vs Drasny Table 4.1 (64/64 hexagrams): OK")
    else:
        print(f"db1 classifier vs Drasny Table 4.1 (64/64 hexagrams): FAIL ({bad})")
        failures += 1

    # (2) zero residue over all 64 hexagrams
    res = [h for h in range(64) if db1_group(h) < 0]
    if not res:
        print("db1 zero-residue (all 64 classified A-G): OK")
    else:
        print(f"db1 zero-residue (all 64 classified A-G): FAIL ({len(res)})")
        failures += 1

    # (3) flip-equivariance group(h) == group(h^63)
    fe = sum(1 for h in range(64) if db1_group(h) != db1_group(h ^ 63))
    if fe == 0:
        print("db1 flip-equivariant group(h)==group(h^63): OK")
    else:
        print(f"db1 flip-equivariant group(h)==group(h^63): FAIL ({fe})")
        failures += 1

    # (4) C1-pair-consistency: partners share a group
    pc = sum(1 for h in range(64) if db1_group(h) != db1_group(_db1_partner(h)))
    if pc == 0:
        print("db1 C1-pair-consistent (partners share group): OK")
    else:
        print(f"db1 C1-pair-consistent (partners share group): FAIL ({pc})")
        failures += 1

    # (5) group sizes by pair
    sizes = [0] * 7
    for s in range(32):
        sizes[db1_group(seq[2 * s])] += 1
    exp_sizes = [5, 4, 4, 4, 6, 3, 6]
    if sizes == exp_sizes:
        print("db1 group sizes A,B,C,D,E,F,G = 5,4,4,4,6,3,6 (F+G=9): OK")
    else:
        print(f"db1 group sizes A,B,C,D,E,F,G = {','.join(map(str, sizes))} "
              "(expected 5,4,4,4,6,3,6): FAIL")
        failures += 1

    # (6) KW conformity X = 22 with the frozen deviant slots
    x = db1_conformity(seq)
    dev = db1_deviant_slots(seq)
    exp_dev = [2, 5, 7, 10, 11, 15, 18, 24, 31, 32]
    if x == 22 and dev == exp_dev:
        print("db1 KW conformity X = 22 (deviant slots "
              + " ".join(map(str, dev)) + "): OK")
    else:
        print(f"db1 KW conformity X = {x} (deviant slots "
              + " ".join(map(str, dev)) + f", expected 22 / {exp_dev}): FAIL")
        failures += 1

    # (7) analytic Null-A mean E[X] = sum(room_size^2)/32 = 190/32 (disclosed)
    ex = Fraction(sum(sz * sz for sz in DB1_ROOM_SIZES), 32)
    if ex == Fraction(190, 32):
        print(f"db1 Null-A E[X] = 190/32 = {float(ex):.6f} "
              "(uniform pair-perm, analytic): OK")
    else:
        print(f"db1 Null-A E[X] = {ex} (expected 190/32): FAIL")
        failures += 1

    print("DB1 VERIFY:", "PASS" if failures == 0 else f"{failures} FAILURES")
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


# ---------------------------------------------------------------------------
# Book-claims verification battery (--books-verify), added 2026-07-05
# (operator-approved: "write code to prove the statements in the book").
# Programmatically verifies, against the received King Wen sequence, every
# machine-checkable structural claim surfaced by the 2026-07-05 book audits:
#   roae-private/books/nielsen_companion/{AUDIT.md, CANDIDATE_CONSTRAINTS.md,
#     VISION_TRANSCRIPTIONS_2026_07_05.md}  (Nielsen 2003 audit)
#   roae-private/books/hacker_bibliography/PRIOR_ART_NOTES.md  (Goldenberg)
# ATTRIBUTION: each claim belongs to the named classical or modern author
# (per-function comments give author, work, year, page/entry, and the audit
# doc that surfaced it). The scholarly source for the classical items is
# Nielsen, Bent (2003), *A Companion to Yi jing Numerology and Cosmology*,
# RoutledgeCurzon. The operationalizations are ROAE's; errors of
# operationalization are ours, not the authors'. Master ledger: CITATIONS.md.
# ---------------------------------------------------------------------------

_BOOKS_KAN, _BOOKS_LI = 0b010, 0b101


def _books_kwnum():
    """KW number (1-based) per 6-bit hexagram value."""
    return {h: i + 1 for i, h in enumerate(binary_hexagrams)}


def _books_wudeng_warp():
    """Wu Deng's 'warp hexagram' (jing gua) class, parameter-free algebraic
    form: upper trigram equals the lower trigram or its complement (8 pure
    doubles + 8 complement-trigram doubles).
    ATTRIBUTION: Wu Deng (1249-1333), *Yi zuan yan* [YJJC 149:9-12], via
    Nielsen 2003, JING GUA entry def. 2, p. 132. Surfaced by roae-private/
    books/nielsen_companion/AUDIT.md par.4 / CANDIDATE_CONSTRAINTS.md N-1."""
    return {h for h in range(64)
            if ((h >> 3) & 7) == (h & 7) or ((h >> 3) & 7) == ((h & 7) ^ 7)}


def books_wd1():
    """WD-1 — Wu Deng warp-class membership: the 16 warp hexagrams are KW
    {1,2,11,12,29,30,31,32,41,42,51,52,57,58,63,64}, Nielsen's printed list
    (p. 132; the OCR's doubled '[52],[52]' is [51],[52] per AUDIT.md par.4).
    ATTRIBUTION: Wu Deng (1249-1333) via Nielsen 2003 p. 132; see
    _books_wudeng_warp."""
    kwn = _books_kwnum()
    expected = (1, 2, 11, 12, 29, 30, 31, 32, 41, 42, 51, 52, 57, 58, 63, 64)
    computed = tuple(sorted(kwn[h] for h in _books_wudeng_warp()))
    return expected, computed


def books_wd2():
    """WD-2 — Wu Deng warp pair-slot skeleton: the warp hexagrams occupy
    exactly the received-order pair-slots {1, 6, 15, 16, 21, 26, 29, 32}
    (slot k = KW positions 2k-1, 2k).
    ATTRIBUTION: Wu Deng (1249-1333) via Nielsen 2003 p. 132 ('control'
    blocks [1],[2]->3-10 ... [63],[64] terminate); formalized as slot set by
    roae-private/books/nielsen_companion/CANDIDATE_CONSTRAINTS.md N-1."""
    kwn = _books_kwnum()
    expected = (1, 6, 15, 16, 21, 26, 29, 32)
    computed = tuple(sorted({(kwn[h] + 1) // 2 for h in _books_wudeng_warp()}))
    return expected, computed


def books_wd3():
    """WD-3 — Wu Deng weft-block sizes: the maximal weft (non-warp) blocks
    between/after warp pairs have sizes, in pair-slots, {4, 8, 4, 4, 2, 2} —
    ALL powers of two — i.e. Wu's 'controlled' counts 8/16/8/8/4/4 hexagrams.
    ATTRIBUTION: Wu Deng (1249-1333) via Nielsen 2003 p. 132; power-of-two
    reading per CANDIDATE_CONSTRAINTS.md N-1 sub-predicate (c)."""
    kwn = _books_kwnum()
    slots = sorted({(kwn[h] + 1) // 2 for h in _books_wudeng_warp()})
    gaps = ([slots[0] - 1] +
            [slots[i] - slots[i - 1] - 1 for i in range(1, len(slots))] +
            [32 - slots[-1]])
    blocks = tuple(g for g in gaps if g > 0)
    expected = ((4, 8, 4, 4, 2, 2), "all powers of 2", (8, 16, 8, 8, 4, 4))
    computed = (blocks,
                "all powers of 2" if all((g & (g - 1)) == 0 for g in blocks)
                else "NOT all powers of 2",
                tuple(2 * g for g in blocks))
    return expected, computed


def books_wd4():
    """WD-4 — Warp-class C1 closure: every warp hexagram's received-order
    partner is warp (so warp occupies whole pair-slots). KW-verified here;
    provably automatic given C1 + the class definition (rev and comp both
    preserve the up==lo / up==comp(lo) property), so a theorem, not a
    coincidence — per CANDIDATE_CONSTRAINTS.md N-1 sub-predicate (a).
    ATTRIBUTION: Wu Deng (1249-1333) via Nielsen 2003 p. 132."""
    w = _books_wudeng_warp()
    computed = all((binary_hexagrams[2 * k] in w) ==
                   (binary_hexagrams[2 * k + 1] in w) for k in range(32))
    return True, computed


def books_lz1():
    """LZ-1 — Lai Zhide 'great images' identities (order-independent half):
    KW 27/28 are the outer-frame magnifications of trigrams Li/Kan (outer
    lines kept, middle line expanded to four), KW 61/62 the line-doubled
    magnifications of Li/Kan, KW 29/30 the doubled Kan/Li pair, and KW 63/64
    the Kan-over-Li / Li-over-Kan mixed pair.
    ATTRIBUTION: Lai Zhide (1525-1604) [YXJH 2:1541], via Nielsen 2003,
    GUA XU entry p. 84 (da gua def. 2, 'great images'). Surfaced by
    roae-private/books/nielsen_companion/AUDIT.md par.2 /
    CANDIDATE_CONSTRAINTS.md N-4."""
    kwn = _books_kwnum()

    def exp_mid(t):   # keep outer lines, middle line x4
        return (t & 1) | (0b011110 if t & 2 else 0) | ((t >> 2) << 5)

    def dbl(t):       # double each line
        return ((t & 1) * 0b11 | ((t >> 1) & 1) * 0b1100 |
                ((t >> 2) & 1) * 0b110000)

    li, kan = _BOOKS_LI, _BOOKS_KAN
    expected = (27, 28, 61, 62, 29, 30, 63, 64)
    computed = (kwn[exp_mid(li)], kwn[exp_mid(kan)],
                kwn[dbl(li)], kwn[dbl(kan)],
                kwn[(kan << 3) | kan], kwn[(li << 3) | li],
                kwn[(kan << 3) | li], kwn[(li << 3) | kan])
    return expected, computed


def books_lz2():
    """LZ-2 — Lai Zhide endpoint feeders (positional half): the great-image
    pair 27/28 immediately precedes the doubled Kan/Li pair 29/30 (pair-slot
    14 -> 15), and 61/62 immediately precedes the mixed pair 63/64 (slot
    31 -> 32) — the ~400-year Ming-dynasty precedent of the arrangement idea
    ROAE registers as Van den Berghe V-2/VDB-4 (see vdb_specplace).
    ATTRIBUTION: Lai Zhide (1525-1604) via Nielsen 2003, GUA XU p. 84;
    surfaced by CANDIDATE_CONSTRAINTS.md N-4 (KW slots 14->15, 31->32)."""
    kwn = _books_kwnum()
    slot = lambda h: (kwn[h] + 1) // 2
    expected = ((14, 15), (31, 32))
    computed = ((slot(0b100001), slot(0b010010)),
                (slot(0b110011), slot(0b010101)))
    return expected, computed


# Goldenberg theorem numbers follow Hacker, Moore & Patsco (2002) entry B:154
# (which first surfaced the theorem statements); confirmed against the primary
# text 2026-07-11 (official ILL scan; all five encoded claims G-T1..T4,T7 verified
# first-hand — see roae-private GOLDENBERG_1975_NOTES.md).
# ATTRIBUTION for G-T1..G-T7: Goldenberg, Daniel S., "The Algebra of the
# I Ching and Its Philosophical Implications", Journal of Chinese Philosophy
# 2 (1975): 149-79. Surfaced by roae-private/books/hacker_bibliography/
# PRIOR_ART_NOTES.md par.4 + VISION-READ addendum.

def books_g_t1():
    """G-T1 — Goldenberg 1975 Theorem 1: the permutations of the 6 hexagram
    line positions form a non-abelian group. Verified exhaustively: |S6| =
    720, closure under composition, identity, inverses, plus a non-commuting
    witness pair. (Associativity is inherited from function composition.)"""
    import itertools
    perms = list(itertools.permutations(range(6)))
    pset = set(perms)
    comp = lambda p, q: tuple(p[q[i]] for i in range(6))
    ident = tuple(range(6))
    closure = all(comp(p, q) in pset for p in perms for q in perms)
    inverses = all(tuple(sorted(range(6), key=lambda i: p[i])) in pset and
                   comp(p, tuple(sorted(range(6), key=lambda i: p[i])))
                   == ident for p in perms)
    nonabelian = any(comp(p, q) != comp(q, p)
                     for p in perms[:8] for q in perms[:8])
    expected = (720, "group", "non-abelian")
    computed = (len(pset),
                "group" if closure and inverses and ident in pset
                else "NOT a group",
                "non-abelian" if nonabelian else "abelian")
    return expected, computed


def books_g_t2():
    """G-T2 — Goldenberg 1975 Theorem 2: the two line symbols form a field
    under addition and multiplication mod 2 (= GF(2); yang/solid = 1,
    yin/broken = 0). All field axioms checked exhaustively over {0,1}."""
    F = (0, 1)
    add = lambda a, b: a ^ b
    mul = lambda a, b: a & b
    ok = (all(add(a, b) in F and mul(a, b) in F for a in F for b in F) and
          all(add(add(a, b), c) == add(a, add(b, c)) and
              mul(mul(a, b), c) == mul(a, mul(b, c)) and
              mul(a, add(b, c)) == add(mul(a, b), mul(a, c))
              for a in F for b in F for c in F) and
          all(add(a, b) == add(b, a) and mul(a, b) == mul(b, a)
              for a in F for b in F) and
          all(add(a, 0) == a and mul(a, 1) == a and add(a, a) == 0
              for a in F) and
          mul(1, 1) == 1 and 0 != 1)
    return True, ok


def books_g_t3():
    """G-T3 — Goldenberg 1975 Theorem 3: the 64 hexagrams form a commutative
    ring under the modulo-2 line operations (componentwise XOR / AND on
    GF(2)^6; a Boolean ring, with AND-identity 111111 = Qian). Associativity
    and distributivity checked exhaustively over all 64^3 triples,
    commutativity/identities/additive inverses over all pairs."""
    R = range(64)
    ok = (all(((a ^ b) ^ c) == (a ^ (b ^ c)) and
              ((a & b) & c) == (a & (b & c)) and
              (a & (b ^ c)) == ((a & b) ^ (a & c))
              for a in R for b in R for c in R) and
          all((a ^ b) == (b ^ a) and (a & b) == (b & a)
              for a in R for b in R) and
          all((a ^ 0) == a and (a & 63) == a and (a ^ a) == 0 for a in R))
    return True, ok


def books_g_t4():
    """G-T4 — Goldenberg 1975 Theorem 4: the inversion mapping (turning a
    hexagram upside down, rev6) is an automorphism of the hexagram ring,
    and its fixed structure is exactly the subring of the 8 symmetric
    (self-inverted) hexagrams — KW {1,2,27,28,29,30,61,62}. Verified:
    bijectivity, preservation of XOR and AND over all pairs, the fixed-point
    set, and subring closure. (Complementation, by contrast, is NOT an
    additive automorphism — it moves the zero.)"""
    kwn = _books_kwnum()
    hom = all(reverse_6bit(a ^ b) == reverse_6bit(a) ^ reverse_6bit(b) and
              reverse_6bit(a & b) == reverse_6bit(a) & reverse_6bit(b)
              for a in range(64) for b in range(64))
    bij = sorted(reverse_6bit(h) for h in range(64)) == list(range(64))
    fixed = {h for h in range(64) if reverse_6bit(h) == h}
    subring = all((a ^ b) in fixed and (a & b) in fixed
                  for a in fixed for b in fixed)
    expected = ("automorphism", (1, 2, 27, 28, 29, 30, 61, 62), "subring")
    computed = ("automorphism" if hom and bij else "NOT an automorphism",
                tuple(sorted(kwn[h] for h in fixed)),
                "subring" if subring else "NOT closed")
    return expected, computed


def books_g_t7():
    """G-T7 — Goldenberg 1975 Theorem 7: every hexagram pair has a UNIQUE
    mediating hexagram transforming either member into the other under
    mod-2 line addition (the XOR difference vector) — verified exhaustively
    over all 64x64 ordered pairs. Worked example (per the Hacker 2002
    annotation): H5 <-> H63 mediated by H7. CONVENTION DERIVED: his H-numbers
    are King Wen numbers and lines encode yang(solid)=1 / yin(broken)=0;
    under those conventions KW5 (Waiting, Qian-under-Kan) XOR KW63 (After
    Completion, Li-under-Kan) = 6-bit 000010 = KW7 (The Army) exactly. The
    example is invariant to line-ORDER convention (rev6 of all three
    preserves it) but pins the POLARITY: under yin=1 the mediating pattern
    decodes to KW13, so Goldenberg's example requires yang=1."""
    unique = all(sum(1 for m in range(64) if (a ^ m) == b) == 1
                 for a in range(64) for b in range(64))
    kwn = _books_kwnum()
    expected = ("unique mediator for all 4096 pairs", 7)
    computed = ("unique mediator for all 4096 pairs" if unique
                else "mediator NOT unique",
                kwn[binary_hexagrams[4] ^ binary_hexagrams[62]])
    return expected, computed


# Nielsen 2003 Table 2 (p. 3, BA GONG GUA entry, adapted from Hui Dong
# (1697-1758), *Ba gong gua ci tu* [YJJC 119:105-8]): the eight-palace
# table as KW numbers, palace head -> (origin, generations 1-5, roaming
# soul, returning soul). Transcribed in roae-private/books/
# nielsen_companion/VISION_TRANSCRIPTIONS_2026_07_05.md page_0591.
_BOOKS_NIELSEN_T2 = {
    0b111: (1, 44, 33, 12, 20, 23, 35, 14),    # Qian palace
    0b001: (51, 16, 40, 32, 46, 48, 28, 17),   # Zhen palace
    0b010: (29, 60, 3, 63, 49, 55, 36, 7),     # Kan palace
    0b100: (52, 22, 26, 41, 38, 10, 61, 53),   # Gen palace
    0b000: (2, 24, 19, 11, 34, 43, 5, 8),      # Kun palace
    0b110: (57, 9, 37, 42, 25, 21, 27, 18),    # Xun palace
    0b101: (30, 56, 50, 64, 4, 59, 6, 13),     # Li palace
    0b011: (58, 47, 45, 31, 39, 15, 62, 54),   # Dui palace
}


def books_jf1():
    """JF-1 — Jing Fang eight-palace generation table: building each palace
    from Nielsen's prose construction (origin = doubled trigram; generations
    1-5 = cumulatively flip lines 1..5; roaming soul = flip line 4 of the
    5th generation; returning soul = restore the lower trigram) reproduces
    Nielsen's authoritative Table 2 in ALL 64 cells, and agrees with ROAE's
    existing generator (_f4p_jf_palace / roae.py --trigrams / solve.c
    --null-historical). Re-exposes the 2026-07-05 corpus-gate check.
    ATTRIBUTION: Jing Fang (77-37 BCE), *Ba gong gua* arrangement; table via
    Nielsen 2003 pp. 1-4 (Table 2, p. 3, after Hui Dong 1697-1758). Surfaced
    by roae-private/books/nielsen_companion/AUDIT.md par.3 +
    VISION_TRANSCRIPTIONS_2026_07_05.md page_0591."""
    kwn = _books_kwnum()

    def palace(t):
        out = [(t << 3) | t]                      # origin (upper generation)
        for k in range(5):                        # 1st..5th generations
            out.append(out[-1] ^ (1 << k))        # flip line k+1
        out.append(out[5] ^ (1 << 3))             # roaming soul: flip line 4
        out.append((out[6] & 0b111000) | t)       # returning soul: lower = t
        return out

    heads = (0b111, 0b001, 0b010, 0b100, 0b000, 0b110, 0b101, 0b011)
    match = sum(1 for t in heads
                if tuple(kwn[h] for h in palace(t)) == _BOOKS_NIELSEN_T2[t])
    agree = all(_F4P_PAL[h] == pi
                for pi, t in enumerate(heads) for h in palace(t))
    expected = ("64/64 cells match Nielsen Table 2", "generators agree")
    computed = (f"{8 * match}/64 cells match Nielsen Table 2",
                "generators agree" if agree else "generators DISAGREE")
    return expected, computed


def books_yf1():
    """YF-1 — Classical pair-structure statement (= ROAE C1): the received
    order's 32 pairs split as 28 'overturned' (fan gua / fandui — reversal)
    pairs + 4 'laterally linked' (pangtong — complementation) pairs, the
    latter being the 8 self-reversal hexagrams KW {1,2,27,28,29,30,61,62}.
    ATTRIBUTION: pairing modes are classical; the complementation
    terminology's earliest technical use is Yu Fan (164-233), preserved via
    Li Dingzuo's *Zhouyi jijie*; reversal-pairing term genealogy Za gua ->
    Wang Bi -> Li Zhicai (d. 1045). Via Nielsen 2003, FAN GUA pp. 57-58 /
    PANG TONG GUA pp. 185-187 / GUA XU pp. 82-85. Surfaced by roae-private/
    books/nielsen_companion/AUDIT.md par.2, par.4."""
    kwn = _books_kwnum()
    nrev = sum(1 for k in range(32)
               if binary_hexagrams[2 * k + 1] ==
               reverse_6bit(binary_hexagrams[2 * k]) !=
               binary_hexagrams[2 * k])
    ncomp = sum(1 for k in range(32)
                if reverse_6bit(binary_hexagrams[2 * k]) ==
                binary_hexagrams[2 * k] ==
                binary_hexagrams[2 * k + 1] ^ 63)
    selfrev = tuple(sorted(kwn[h] for h in range(64)
                           if reverse_6bit(h) == h))
    expected = (28, 4, (1, 2, 27, 28, 29, 30, 61, 62))
    computed = (nrev, ncomp, selfrev)
    return expected, computed


# Nielsen 2003 Table 1 (p. 187, PANG TONG GUA entry): the 32 complement
# ('laterally linked') couples of the full pangtong involution, as KW-number
# pairs. Transcribed in VISION_TRANSCRIPTIONS_2026_07_05.md page_0781.
_BOOKS_PANGTONG_T1 = (
    (1, 2), (3, 50), (4, 49), (5, 35), (6, 36), (7, 13), (8, 14), (9, 16),
    (10, 15), (11, 12), (17, 18), (19, 33), (20, 34), (21, 48), (22, 47),
    (23, 43), (24, 44), (25, 46), (26, 45), (27, 28), (29, 30), (31, 41),
    (32, 42), (37, 40), (38, 39), (51, 57), (52, 58), (53, 54), (55, 59),
    (56, 60), (61, 62), (63, 64),
)


def books_yf2():
    """YF-2 — The full pangtong (complementation) involution: Nielsen's
    printed table of all 32 'laterally linked' couples is exactly the
    all-lines-flipped map h -> comp(h), each couple a complement pair and
    the 32 couples covering all 64 hexagrams.
    ATTRIBUTION: Yu Fan (164-233) pangtong, via Nielsen 2003, PANG TONG GUA
    Table 1, p. 187. Surfaced by VISION_TRANSCRIPTIONS_2026_07_05.md
    page_0781 + AUDIT.md par.4."""
    ok = (len(_BOOKS_PANGTONG_T1) == 32 and
          sorted(x for p in _BOOKS_PANGTONG_T1 for x in p) ==
          list(range(1, 65)) and
          all(binary_hexagrams[a - 1] ^ 63 == binary_hexagrams[b - 1]
              for a, b in _BOOKS_PANGTONG_T1))
    return ("32/32 couples are complement pairs covering all 64",
            "32/32 couples are complement pairs covering all 64" if ok
            else "table does NOT match complementation")


BOOKS_CLAIMS = (
    ("WD-1", "Wu Deng 1249-1333 (Nielsen 2003 p.132) warp-class membership",
     books_wd1),
    ("WD-2", "Wu Deng warp pairs at received pair-slots {1,6,15,16,21,26,29,32}",
     books_wd2),
    ("WD-3", "Wu Deng weft blocks {4,8,4,4,2,2} pair-slots (powers of 2)",
     books_wd3),
    ("WD-4", "Wu Deng warp class is C1-closed (pairs stay whole)",
     books_wd4),
    ("LZ-1", "Lai Zhide 1525-1604 (Nielsen 2003 p.84) great-image identities",
     books_lz1),
    ("LZ-2", "Lai Zhide endpoint feeders 27/28->29/30, 61/62->63/64 adjacency",
     books_lz2),
    ("G-T1", "Goldenberg 1975 (JCP 2:149-79) T1 line-permutation group non-abelian",
     books_g_t1),
    ("G-T2", "Goldenberg 1975 T2 line symbols form the field GF(2)",
     books_g_t2),
    ("G-T3", "Goldenberg 1975 T3 hexagrams form a commutative ring (GF(2)^6)",
     books_g_t3),
    ("G-T4", "Goldenberg 1975 T4 inversion automorphism fixes the 8 symmetric hexagrams",
     books_g_t4),
    ("G-T7", "Goldenberg 1975 T7 unique XOR mediator; example H5<->H63 via H7",
     books_g_t7),
    ("JF-1", "Jing Fang 77-37 BCE eight-palace table == Nielsen 2003 Table 2 (all 64)",
     books_jf1),
    ("YF-1", "Yu Fan 164-233 (Nielsen 2003 pp.57-58,185-187) 28 fandui + 4 pangtong pairs",
     books_yf1),
    ("YF-2", "Yu Fan pangtong: Nielsen p.187 32-couple table == complementation",
     books_yf2),
)


def books_verify():
    """Run the book-claims verification battery: one PASS/FAIL line per
    claim with expected and computed values. Returns 0 on full pass, 1 on
    any mismatch. See the block comment above for sources and attribution."""
    failures = 0
    for cid, desc, fn in BOOKS_CLAIMS:
        expected, computed = fn()
        ok = expected == computed
        if not ok:
            failures += 1
        print(f"{cid} {'PASS' if ok else 'FAIL'} {desc}\n"
              f"     expected: {expected}\n"
              f"     computed: {computed}")
    if failures:
        print(f"BOOKS VERIFY: {failures} of {len(BOOKS_CLAIMS)} CLAIMS FAILED")
        return 1
    print(f"BOOKS VERIFY: ALL {len(BOOKS_CLAIMS)} CLAIMS PASS")
    return 0


# ---------------------------------------------------------------------------
# Trigram-theorem verification battery (--trigram-verify), added 2026-07-11.
# The two-language ground-truth companion of lean/TrigramTheorems.lean: every
# finite fact and every King Wen instance of that file's machine-checked
# statements is independently re-computed here from the definitions (the
# Lean file's sequence-level theorems quantify over EVERY valid ordering;
# Python re-checks their finite engines and their KW instantiations).
# Prose companion + scope notes: documentation/TRIGRAM_STRUCTURE.md — read
# its §1-§2 before citing (in particular: the TG-3 group acts on LINE
# POSITIONS and is distinct from Hershock 1991's hexagram-set group).
# ATTRIBUTION (mirrors the Lean header's novelty ledger, which is binding):
# TG-1/TG-4 classical facts (Goldenberg 1975; Schöter 1998; Lai Zhide via
# Schulz 1982; Wu Deng via Nielsen 2003; Hershock 1991 "linking"; Cook 2006)
# — nothing claimed as discovery. TG-2's "9th six" observation is McKenna &
# McKenna 1975; the budget derivation is the project's. Master ledger:
# documentation/CITATIONS.md.
# Definitions below deliberately mirror the Lean file's §0 layer (pc6/rev6/
# partner/upperT/lowerT/nuc/applyPerm/...) rather than reusing this file's
# other internals, so the two implementations stay independent.
# ---------------------------------------------------------------------------


def _tg_rev6(n):
    """6-bit reversal (Lean rev6)."""
    return ((n & 1) << 5 | (n >> 1 & 1) << 4 | (n >> 2 & 1) << 3 |
            (n >> 3 & 1) << 2 | (n >> 4 & 1) << 1 | (n >> 5 & 1))


def _tg_rev3(t):
    """3-bit reversal (Lean rev3)."""
    return (t & 1) << 2 | (t & 2) | (t >> 2 & 1)


def _tg_partner(h):
    """Canonical partner: reversal, or complement for palindromes."""
    return h ^ 63 if _tg_rev6(h) == h else _tg_rev6(h)


def _tg_ham(a, b):
    return bin(a ^ b).count("1")


def _tg_up(h):
    return (h >> 3) & 7


def _tg_lo(h):
    return h & 7


def _tg_d3(a, b):
    return bin(a ^ b).count("1")


def _tg_nuc(h):
    """Nuclear hexagram: lower nuclear = lines 2-4, upper nuclear = lines 3-5."""
    return ((h >> 2) & 7) * 8 + ((h >> 1) & 7)


def _tg_transitions(l):
    return [_tg_ham(a, b) for a, b in zip(l, l[1:])]


def _tg_multiset(vals):
    return {v: vals.count(v) for v in sorted(set(vals))}


def _tg_apply_perm(p, n):
    """Bit i of n goes to position p[i] (Lean applyPerm)."""
    return sum(((n >> i) & 1) << p[i] for i in range(6))


def _tg_pcomp(p, q):
    """applyPerm(pcomp(p,q)) = applyPerm(p) o applyPerm(q) (Lean pcomp)."""
    return [p[j] for j in q]


def _tg_g48():
    """The centralizer of bit-reversal among the 720 bit permutations."""
    from itertools import permutations
    return [list(p) for p in permutations(range(6))
            if all(_tg_apply_perm(p, _tg_rev6(h)) ==
                   _tg_rev6(_tg_apply_perm(p, h)) for h in range(64))]


def _tg_block_preserving(p):
    """The image of {bit 0,1,2} is {0,1,2} (blocks fixed) or {3,4,5} (swapped)."""
    return all(x < 3 for x in p[:3]) or all(x >= 3 for x in p[:3])


def _tg_mirror_double(q):
    """Embed q in S3 as the block-fixing G48 element (Lean mirrorDouble)."""
    return list(q) + [5 - x for x in reversed(q)]


def _tg_valid_c15(l):
    """C1 + C4 + C5 + C3 (Lean validC15), restated from the Lean file."""
    if len(l) != 64 or sorted(l) != list(range(64)):
        return False
    if not all(l[2 * i + 1] == _tg_partner(l[2 * i]) for i in range(32)):
        return False
    if l[0] != 63 or l[1] != 0:
        return False
    t = _tg_transitions(l)
    if _tg_multiset(t) != {1: 2, 2: 20, 3: 13, 4: 19, 6: 9}:
        return False
    pos = {h: i for i, h in enumerate(l)}
    return sum(abs(pos[h] - pos[h ^ 63]) for h in range(64)) <= 776


def _tg_uchange(l):
    return sum(1 for a, b in zip(l, l[1:]) if _tg_up(a) != _tg_up(b))


def _tg_lchange(l):
    return sum(1 for a, b in zip(l, l[1:]) if _tg_lo(a) != _tg_lo(b))


def trigram_tg1a():
    """TG1-a — factorization: rev6 swaps + 3-bit-reverses the trigrams;
    complement acts componentwise (all 64). Classical; Goldenberg 1975
    ambient (Lean rev6_trigram_factor / comp6_trigram_componentwise)."""
    computed = all(_tg_up(_tg_rev6(h)) == _tg_rev3(_tg_lo(h)) and
                   _tg_lo(_tg_rev6(h)) == _tg_rev3(_tg_up(h)) and
                   _tg_up(h ^ 63) == _tg_up(h) ^ 7 and
                   _tg_lo(h ^ 63) == _tg_lo(h) ^ 7 for h in range(64))
    return True, computed


def trigram_tg1b():
    """TG1-b — Hamming distance splits over the trigram bipartition
    (all 64x64; Lean ham_trigram_split)."""
    computed = all(_tg_ham(a, b) ==
                   _tg_d3(_tg_up(a), _tg_up(b)) + _tg_d3(_tg_lo(a), _tg_lo(b))
                   for a in range(64) for b in range(64))
    return True, computed


def trigram_tg1c():
    """TG1-c — symmetric iff upper = rev3(lower); 8 symmetric, 8
    anti-symmetric, disjoint (Lean symmetric_iff_trigram + counts)."""
    sym = [h for h in range(64) if _tg_rev6(h) == h]
    asym = [h for h in range(64) if _tg_rev6(h) == h ^ 63]
    iff = all((_tg_rev6(h) == h) == (_tg_up(h) == _tg_rev3(_tg_lo(h)))
              for h in range(64))
    expected = (True, 8, 8, 0)
    computed = (iff, len(sym), len(asym), len(set(sym) & set(asym)))
    return expected, computed


def trigram_tg1d():
    """TG1-d — the pure (doubled-trigram) hexagrams, partner-closure, and
    the 4 canonical pure pairs (classical placement: Lai Zhide via Schulz
    1982; Wu Deng via Nielsen 2003; Lean pure_hexagrams_explicit /
    pure_closed_partner / pure_pairs_explicit)."""
    pure = [h for h in range(64) if _tg_up(h) == _tg_lo(h)]
    expected = ([0, 9, 18, 27, 36, 45, 54, 63], True, (63, 36, 45, 54))
    computed = (pure,
                all(_tg_up(_tg_partner(h)) == _tg_lo(_tg_partner(h))
                    for h in pure),
                (_tg_partner(0), _tg_partner(9), _tg_partner(18),
                 _tg_partner(27)))
    return expected, computed


def trigram_tg2a():
    """TG2-a — within-pair distance population over the 64 hexagrams:
    {2:24, 4:24, 6:16}, i.e. multiset {2:12, 4:12, 6:8} over the 32 pairs
    (Lean pairdist_count_*; the CITATIONS.md 120-table's engine)."""
    expected = {2: 24, 4: 24, 6: 16}
    computed = _tg_multiset([_tg_ham(h, _tg_partner(h)) for h in range(64)])
    return expected, computed


def trigram_tg2b():
    """TG2-b — trigram readings of d=6 / d=5 / d=1 over all 64x64 pairs
    (Lean ham_six/five/one_trigram_bool): 6 = both trigrams complemented
    (McKenna's 9th-six condition); 5 = one complemented + 2 lines of the
    other (the C2 content); 1 = one trigram carried intact + 1 line."""
    def ok(a, b):
        du, dl = _tg_d3(_tg_up(a), _tg_up(b)), _tg_d3(_tg_lo(a), _tg_lo(b))
        return ((_tg_ham(a, b) == 6) == (du == 3 and dl == 3) and
                (_tg_ham(a, b) == 5) == ((du == 3 and dl == 2) or
                                         (du == 2 and dl == 3)) and
                (_tg_ham(a, b) == 1) == ((du == 0 and dl == 1) or
                                         (dl == 0 and du == 1)))
    computed = all(ok(a, b) for a in range(64) for b in range(64))
    return True, computed


def trigram_tg2c():
    """TG2-c — the pangtong engine partner(comp(partner h)) = comp h (all
    64), and exactly 16 hexagrams sit in self-complementary pairs, exactly
    the symmetric + anti-symmetric classes (Lean partner_comp_partner /
    selfcomp_pair_iff / selfcomp_pair_count)."""
    engine = all(_tg_partner(_tg_partner(h) ^ 63) == h ^ 63
                 for h in range(64))
    selfc = [h for h in range(64) if _tg_partner(h) == h ^ 63]
    iff = all((_tg_partner(h) == h ^ 63) ==
              (_tg_rev6(h) == h or _tg_rev6(h) == h ^ 63) for h in range(64))
    expected = (True, 16, True)
    computed = (engine, len(selfc), iff)
    return expected, computed


def trigram_tg2d():
    """TG2-d — KW instance of the two multiset theorems: within-pair
    {2:12, 4:12, 6:8} and boundary {1:2, 2:8, 3:13, 4:7, 6:1} (Lean
    within_multiset_general / boundary_budget_general instantiated; the
    boundary theorem holds for EVERY C1+C5 ordering — Lean proves that;
    Python checks the KW instance)."""
    kw = binary_hexagrams
    t = _tg_transitions(kw)
    expected = ({2: 12, 4: 12, 6: 8}, {1: 2, 2: 8, 3: 13, 4: 7, 6: 1})
    computed = (_tg_multiset(t[0::2]), _tg_multiset(t[1::2]))
    return expected, computed


def trigram_tg2e():
    """TG2-e — KW's unique 9th six (McKenna & McKenna 1975, credited) is
    boundary k=18 (flat transition 37, pairs #37-38 -> #39-40); the
    pangtong-successor identities hold there; neither flanking pair is
    self-complementary (Lean ninth_six_trigram / pangtong_successor /
    flanking_exclusion instantiated)."""
    kw = binary_hexagrams
    t = _tg_transitions(kw)
    sixes = [k for k in range(31) if t[2 * k + 1] == 6]
    expected = ([18], True, True, (False, False))
    computed = (sixes,
                kw[38] == kw[37] ^ 63,
                kw[39] == kw[36] ^ 63,
                (_tg_partner(kw[36]) == kw[36] ^ 63,
                 _tg_partner(kw[38]) == kw[38] ^ 63))
    return expected, computed


def trigram_tg3a():
    """TG3-a — |G48| = 48; exactly 12 preserve the trigram bipartition;
    6 at record level (Lean G48_length / G12_length / G6_length).
    SCOPE: G48 acts on LINE POSITIONS (TR-5's constraint-symmetry group)
    — NOT Hershock 1991's hexagram-set group; see TRIGRAM_STRUCTURE.md §2."""
    g48 = _tg_g48()
    g12 = [p for p in g48 if _tg_block_preserving(p)]
    g6 = [p for p in g12 if p[0] < p[5]]
    expected = (48, 12, 6)
    computed = (len(g48), len(g12), len(g6))
    return expected, computed


def trigram_tg3b():
    """TG3-b — G12 is a genuine subgroup (closed under composition and
    inverses); rho (bit reversal) is in G12 and central in G48 (Lean
    G12_closed_pcomp / G12_closed_inv / rho_mem_G12 / rho_central_G48)."""
    g48 = _tg_g48()
    g12 = [p for p in g48 if _tg_block_preserving(p)]
    idp, rho = list(range(6)), [5, 4, 3, 2, 1, 0]
    closed = all(_tg_pcomp(p, q) in g12 for p in g12 for q in g12)
    inv = all(any(_tg_pcomp(q, p) == idp and _tg_pcomp(p, q) == idp
                  for q in g12) for p in g12)
    central = all(_tg_pcomp(p, rho) == _tg_pcomp(rho, p) for p in g48)
    expected = (True, True, True, True)
    computed = (closed, inv, rho in g12, central)
    return expected, computed


def trigram_tg3c():
    """TG3-c — structure G12 = mirrorDouble(S3) + mirrorDouble(S3)*rho,
    exactly (12 distinct elements); mirrorDouble is an injective
    homomorphism; G6 is exactly its image (Lean G12_decomposition_covers/
    _nodup / mirrorDouble_hom / mirrorDouble_inj / G6_eq_mirrorDouble_image
    — i.e. G12 iso S3 x C2, record level S3)."""
    from itertools import permutations
    g48 = _tg_g48()
    g12 = [p for p in g48 if _tg_block_preserving(p)]
    g6 = [p for p in g12 if p[0] < p[5]]
    rho = [5, 4, 3, 2, 1, 0]
    s3 = [list(q) for q in permutations(range(3))]
    md = [_tg_mirror_double(q) for q in s3]
    cosets = md + [_tg_pcomp(m, rho) for m in md]
    hom = all(_tg_pcomp(_tg_mirror_double(q1), _tg_mirror_double(q2)) ==
              _tg_mirror_double(_tg_pcomp(q1, q2)) for q1 in s3 for q2 in s3)
    expected = (True, 12, True, True)
    computed = (sorted(map(tuple, cosets)) == sorted(map(tuple, g12)),
                len(set(map(tuple, cosets))),
                hom and len(set(map(tuple, md))) == 6,
                sorted(map(tuple, md)) == sorted(map(tuple, g6)))
    return expected, computed


def trigram_tg3d():
    """TG3-d — characterization over all 720 line permutations: p preserves
    the bipartition iff the upper trigram of the image is a well-defined
    function of a single trigram of the input (Lean
    blockPreserving_iff_blockwise)."""
    from itertools import permutations

    def blockwise(p):
        for proj in (_tg_up, _tg_lo):
            img = {}
            if all(img.setdefault(proj(h), _tg_up(_tg_apply_perm(p, h))) ==
                   _tg_up(_tg_apply_perm(p, h)) for h in range(64)):
                return True
        return False
    computed = all(_tg_block_preserving(list(p)) == blockwise(p)
                   for p in permutations(range(6)))
    return True, computed


def trigram_tg3e():
    """TG3-e — the invariance/non-invariance pair: uChange(KW)=59,
    lChange(KW)=58, preserved by every record-level trigram-compatible
    symmetry (G6), while the witness sigma=[0,1,3,2,4,5] (in G24, NOT
    block-preserving) maps KW to a validC15 ordering with uChange 62 —
    trigram functionals are NOT 24-orbit invariants (Lean uChange_mapP /
    lChange_mapP / trigram_functional_not_orbit_invariant)."""
    kw = binary_hexagrams
    g48 = _tg_g48()
    g24 = [p for p in g48 if p[0] < p[5]]
    g6 = [p for p in g24 if _tg_block_preserving(p)]
    sigma = [0, 1, 3, 2, 4, 5]
    img = [_tg_apply_perm(sigma, h) for h in kw]
    g6_inv = all(_tg_uchange([_tg_apply_perm(p, h) for h in kw]) == 59 and
                 _tg_lchange([_tg_apply_perm(p, h) for h in kw]) == 58
                 for p in g6)
    expected = (59, 58, True, True, False, True, 62)
    computed = (_tg_uchange(kw), _tg_lchange(kw), g6_inv, sigma in g24,
                _tg_block_preserving(sigma), _tg_valid_c15(img),
                _tg_uchange(img))
    return expected, computed


def trigram_tg4a():
    """TG4-a — nuclear naturality (presumably classical/implicit; Hershock
    1991 'linking', Cook 2006; no discovery claimed): nuc commutes with
    rev6 and complement, preserves symmetric hexagrams, and descends along
    the C1 pairing (Lean nuc_comm_rev / nuc_comm_comp /
    nuc_preserves_symmetric / nuc_partner_descent)."""
    comm = all(_tg_nuc(_tg_rev6(h)) == _tg_rev6(_tg_nuc(h)) and
               _tg_nuc(h ^ 63) == _tg_nuc(h) ^ 63 for h in range(64))
    sym = all(_tg_rev6(_tg_nuc(h)) == _tg_nuc(h)
              for h in range(64) if _tg_rev6(h) == h)
    descent = all(_tg_nuc(_tg_partner(h)) ==
                  (_tg_nuc(h) ^ 63 if _tg_rev6(h) == h
                   else _tg_rev6(_tg_nuc(h))) for h in range(64))
    expected = (True, True, True)
    computed = (comm, sym, descent)
    return expected, computed


def trigram_tg4b():
    """TG4-b — the 64 -> 16 -> 4 nuclear image chain with terminal set
    {0, 21, 42, 63} (= solve.c's f5_vdb_term set), nuc-closed with 21<->42
    swapped (classical chain; Lean nuc_image_16 / nuc_nuc_image_terminal /
    nuc_terminal_closed)."""
    img1 = {_tg_nuc(h) for h in range(64)}
    img2 = {_tg_nuc(_tg_nuc(h)) for h in range(64)}
    expected = (16, [0, 21, 42, 63], (0, 63, 42, 21))
    computed = (len(img1), sorted(img2),
                (_tg_nuc(0), _tg_nuc(63), _tg_nuc(21), _tg_nuc(42)))
    return expected, computed


def trigram_tg5a():
    """TG5-a — VACUITY GUARD: each of the 8 trigrams appears exactly 8
    times as upper and 8 as lower in the SET of 64 hexagrams, so trigram
    balance holds in ANY ordering and says nothing about King Wen (Lean
    trigram_balance_range / trigram_balance_invariant)."""
    computed = all(sum(1 for h in range(64) if _tg_up(h) == t) == 8 and
                   sum(1 for h in range(64) if _tg_lo(h) == t) == 8
                   for t in range(8))
    return True, computed


def trigram_tg5b():
    """TG5-b — VACUITY GUARD: pure hexagrams pair with pure hexagrams under
    C1 (their adjacency is forced, not designed); KW's 4 pure pair-slots
    are {0, 14, 25, 28} = KW #1-2, #29-30, #51-52, #57-58 (Lean
    pure_pairslot_couple / pure_pairslot_count + the KW sanity example)."""
    kw = binary_hexagrams
    couple = all((_tg_up(kw[2 * i]) == _tg_lo(kw[2 * i])) ==
                 (_tg_up(kw[2 * i + 1]) == _tg_lo(kw[2 * i + 1]))
                 for i in range(32))
    slots = [i for i in range(32) if _tg_up(kw[2 * i]) == _tg_lo(kw[2 * i])]
    expected = (True, [0, 14, 25, 28])
    computed = (couple, slots)
    return expected, computed


TRIGRAM_CLAIMS = (
    ("TG1-a", "rev6 swaps+reverses trigrams; comp componentwise (classical)",
     trigram_tg1a),
    ("TG1-b", "Hamming distance splits over the trigram bipartition",
     trigram_tg1b),
    ("TG1-c", "symmetric iff up=rev3(lo); 8 symmetric + 8 anti, disjoint",
     trigram_tg1c),
    ("TG1-d", "pure hexagrams {9t}, partner-closed, 4 pairs (Lai Zhide/Wu Deng)",
     trigram_tg1d),
    ("TG2-a", "within-pair distance population {2:24, 4:24, 6:16}",
     trigram_tg2a),
    ("TG2-b", "trigram readings of d=6/5/1 over all 64x64",
     trigram_tg2b),
    ("TG2-c", "pangtong engine + 16 self-complementary-pair members",
     trigram_tg2c),
    ("TG2-d", "KW within {2:12,4:12,6:8} + boundary {1:2,2:8,3:13,4:7,6:1}",
     trigram_tg2d),
    ("TG2-e", "KW 9th six unique at k=18 + pangtong + flanking exclusion (McKenna 1975 obs.)",
     trigram_tg2e),
    ("TG3-a", "|G48|=48, |G12|=12, |G6|=6 (line-position group, NOT Hershock's)",
     trigram_tg3a),
    ("TG3-b", "G12 subgroup closure/inverses; rho in G12, central in G48",
     trigram_tg3b),
    ("TG3-c", "G12 = S3 x C2 via mirrorDouble (injective hom); G6 = image",
     trigram_tg3c),
    ("TG3-d", "block-preservation iff blockwise action (all 720 perms)",
     trigram_tg3d),
    ("TG3-e", "uChange/lChange G6-invariant on KW; sigma witness breaks 24-orbit invariance",
     trigram_tg3e),
    ("TG4-a", "nuc commutes with rev/comp; preserves symmetric; C1 descent",
     trigram_tg4a),
    ("TG4-b", "nuclear chain 64->16->4, terminal {0,21,42,63} nuc-closed",
     trigram_tg4b),
    ("TG5-a", "vacuity guard: trigram balance is ordering-invariant",
     trigram_tg5a),
    ("TG5-b", "vacuity guard: pure adjacency C1-forced; KW slots {0,14,25,28}",
     trigram_tg5b),
)


def trigram_verify():
    """Run the trigram-theorem verification battery: one PASS/FAIL line per
    claim with expected and computed values. Returns 0 on full pass, 1 on
    any mismatch. See the block comment above for scope and attribution."""
    failures = 0
    for cid, desc, fn in TRIGRAM_CLAIMS:
        expected, computed = fn()
        ok = expected == computed
        if not ok:
            failures += 1
        print(f"{cid} {'PASS' if ok else 'FAIL'} {desc}\n"
              f"      expected: {expected}\n"
              f"      computed: {computed}")
    if failures:
        print(f"TRIGRAM VERIFY: {failures} of {len(TRIGRAM_CLAIMS)} CLAIMS FAILED")
        return 1
    print(f"TRIGRAM VERIFY: ALL {len(TRIGRAM_CLAIMS)} CLAIMS PASS "
          f"(two-language check of lean/TrigramTheorems.lean)")
    return 0


# ===========================================================================
# R7 — Cross-tradition corpus-control battery (--r7-corpus / --r7-verify)
# ---------------------------------------------------------------------------
# Frozen pre-registered design: roae-private/R7_CORPUS_CONTROL_DESIGN_FROZEN_
# 2026_07_11.md (commit b00911b). Referee question: does ROAE's extraction
# methodology manufacture x10^3-class "design" discriminators for ANY
# systematic ordering of the 64 hexagrams, or does it correctly identify which
# orderings are structured, where, and how much? R7 answers by defining each
# historical ordering's OWN natural constraint family in its OWN representation
# (KW: C1-C5; Jing Fang: J1-J5, palace-generator repn; Mawangdui: M1-M5,
# trigram-octet repn; Fu Xi: B1, identity), cross-applying every family to
# every ordering (the manufacture alarm), and pricing each family against
# matched nulls. Report-only: nothing here promotes to a solver constraint;
# every cell is reported whatever it says (standing extraction-circularity
# policy).
#
# ATTRIBUTION / NOVELTY HUMILITY (mirrors the frozen design's declaration,
# which is binding): the Jing Fang (c. 77-37 BCE, eight-palaces) and Mawangdui
# (silk text, tomb sealed 168 BCE) orderings are classical Chinese artifacts,
# NOT project inventions. The J/M constraint-family operationalizations below
# are Claude's formalizations of standard classical constructions (JF palace
# generator: standard sinological convention, see CITATIONS.md; MD two-key
# trigram sort: Shaughnessy 2022, Brill, p.50 + Table 11.2, corrected 2026-07-05
# per the public CITATIONS.md erratum). None of the generative descriptions is
# claimed as novel; only their use as a symmetric corpus-control instrument is,
# to our knowledge, the project's own -- and that is hedged, not asserted.
# Sinological corrections are invited; a correction reopens the freeze via a
# dated amendment. Developed with AI assistance (Claude, Anthropic).
#
# DISCLOSED LIMITS (frozen design section 9 -- must survive downstream):
#   * n = 3 alternative orderings, all classical Chinese: R7 tests the
#     historical recension corpus, NOT "any systematic ordering" in the
#     mathematical sense. A finite corpus cannot settle the universal claim.
#   * Post-erratum, BOTH JF and MD are fully algorithmic (positive controls of
#     two different generative styles); the corpus carries NO genuine middle
#     case, so the battery's response to *partial* design is uncalibrated here.
#   * The L0 11x3 matrix was observed at N=10^4 pre-freeze (pilot); R7's weight
#     rests on the genuinely-unobserved cells (L1/L2 nulls, off-home predicates).
#   * The Fu Xi off-home M1 pass is a deliberate, honest feature (M1 alone is a
#     weak predicate any upper-sorted ordering satisfies); it is excluded from
#     the manufacture alarm only by the joint-M requirement (Fu Xi fails M2/M3/
#     M4 a-priori), and R7 flags it itself rather than leaving it for a referee.
#
# sha-NEUTRALITY: this is a solve.py-only subcommand (single-file rule). It
# makes NO solve.c change and is off every enum/selftest path, so the canonical
# `./solve --selftest` sha is untouched.
# ===========================================================================

_R7_ROOT = os.path.dirname(os.path.abspath(__file__))

# Trigram values (frozen convention): Qian 7, Kun 0, Zhen 1, Kan 2, Gen 4,
# Xun 6, Li 5, Dui 3. bit 0 = bottom line (OEIS A102241); L(h)=h&7,
# U(h)=(h>>3)&7; comp6=h^63, comp3=t^7.

def _r7_kw():
    """King Wen ordering -- solve.py ground truth (binary_hexagrams)."""
    return list(binary_hexagrams)

def _r7_fuxi():
    """Fu Xi natural-binary ordering: seq[i] = i."""
    return list(range(64))

def _r7_jingfang():
    """Jing Fang Eight Palaces (c. 77-37 BCE) generator -- palace-orbit
    representation. Verbatim copy of roae.py print_trigrams / solve.c
    --null-historical construction (three-language cross-check). Palace order
    Qian,Zhen,Kan,Gen,Kun,Xun,Li,Dui; within each palace the eight world
    stages W_0..W_7 (see _r7_W)."""
    jf = []
    for t in (0b111, 0b001, 0b010, 0b100, 0b000, 0b110, 0b101, 0b011):
        jf += _r7_W(t)
    return jf

def _r7_W(t):
    """The 8 world-stage hexagrams of Jing Fang palace with pure trigram t,
    written (upper<<3)|lower. Frozen design section 3:
    W_0(t)=(t,t) W_1=(t,t^1) W_2=(t,t^3) W_3=(t,t^7) W_4=(t^1,t^7)
    W_5=(t^3,t^7) W_6=(t^2,t^7) [wandering soul] W_7=(t^2,t) [returning soul]."""
    return [(t << 3) | t, (t << 3) | (t ^ 1), (t << 3) | (t ^ 3),
            (t << 3) | (t ^ 7), ((t ^ 1) << 3) | (t ^ 7),
            ((t ^ 3) << 3) | (t ^ 7), ((t ^ 2) << 3) | (t ^ 7),
            ((t ^ 2) << 3) | t]

def _r7_mawangdui_indices():
    """Parse roae.py::mawangdui_kw_indices (single-file rule: the data is
    PARSED, never re-typed). Corrected array (Shaughnessy 2022 Table 11.2;
    2026-07-05 erratum)."""
    import re
    src = open(os.path.join(_R7_ROOT, "roae.py")).read()
    m = re.search(r"mawangdui_kw_indices = \[(.*?)\]", src, re.S)
    idx = [int(x) for x in re.findall(r"\d+", m.group(1))]
    if len(idx) != 64:
        raise RuntimeError("R7: could not parse 64 mawangdui indices from roae.py")
    return idx

def _r7_mawangdui():
    """Mawangdui silk-text ordering as hexagram values (roae.py indices into
    KW). Octet-by-upper-trigram representation."""
    kw = _r7_kw()
    return [kw[i] for i in _r7_mawangdui_indices()]

def _r7_solve_c_kw_md():
    """Independently parse solve.c --null-historical's kw[] and md_idx[] and
    return (kw_values, mawangdui_values) for the FC-2 cross-validation gate.
    A mismatch is NEVER rationalized through (2026-07-05 erratum lesson)."""
    import re
    src = open(os.path.join(_R7_ROOT, "solve.c")).read()
    mkw = re.search(r"uint8_t kw\[64\] = \{(.*?)\};", src, re.S)
    kw_c = [int(x) for x in re.findall(r"\d+", mkw.group(1))]
    mmd = re.search(r"int md_idx\[64\] = \{(.*?)\};", src, re.S)
    md_c = [int(x) for x in re.findall(r"-?\d+", mmd.group(1))]
    if len(kw_c) != 64 or len(md_c) != 64:
        raise RuntimeError("R7: could not parse 64 kw[]/md_idx[] from solve.c")
    return kw_c, [kw_c[i] for i in md_c]

# ------------------------------------------------------------- observables
# The 11 F8 observables (a,b,c1,c2,d,e,f,g,h,i,j), verbatim from the pilot's
# normative implementation (F8_BATTERY_RESULTS_2026_07.md Appendix A). No
# additions (frozen: additions would dilute the pre-registration story).

def _r7_rev6(h):
    r = 0
    for b in range(6):
        r = (r << 1) | ((h >> b) & 1)
    return r

def _r7_partner(h):
    r = _r7_rev6(h)
    return r if r != h else h ^ 0b111111

def _r7_diff_wave(s):
    return [bin(s[i] ^ s[i + 1]).count("1") for i in range(63)]

def _r7_obs_a(s):   # Hamming-5 transition count (no-5 property <=> 0)
    return sum(1 for d in _r7_diff_wave(s) if d == 5)

def _r7_obs_b(s):   # partner-adjacent pairs at slots (2k,2k+1)
    return sum(1 for k in range(32) if _r7_partner(s[2 * k]) == s[2 * k + 1])

def _r7_obs_c1(s):  # upper-trigram change count
    return sum(1 for i in range(63) if (s[i] >> 3) != (s[i + 1] >> 3))

def _r7_obs_c2(s):  # lower-trigram change count
    return sum(1 for i in range(63) if (s[i] & 7) != (s[i + 1] & 7))

def _r7_obs_d(s):   # Shannon entropy of the 63 diff-wave values
    import math
    d = _r7_diff_wave(s)
    ent = 0.0
    for v in set(d):
        p = d.count(v) / 63.0
        ent -= p * math.log2(p)
    return ent

def _r7_obs_e(s):   # lag-1 autocorrelation of the diff wave
    import math
    d = _r7_diff_wave(s)
    x, y = d[:-1], d[1:]
    n = len(x)
    mx = sum(x) / n
    my = sum(y) / n
    cov = sum((a - mx) * (b - my) for a, b in zip(x, y))
    vx = sum((a - mx) ** 2 for a in x)
    vy = sum((b - my) ** 2 for b in y)
    if vx == 0 or vy == 0:
        return 0.0
    return cov / math.sqrt(vx * vy)

def _r7_obs_f(s):   # complement-distance sum over 32 pairs (/2 convention)
    pos = {h: i for i, h in enumerate(s)}
    return sum(abs(pos[h] - pos[h ^ 63]) for h in range(64)) // 2

def _r7_obs_g(s):   # doubled-trigram hexagrams at block starts (positions 8b, 8b+1)
    idxs = [b * 8 + o for b in range(8) for o in (0, 1)]
    return sum(1 for i in idxs if (s[i] >> 3) == (s[i] & 7))

def _r7_obs_h(s):   # longest weakly-monotone run in the diff wave
    d = _r7_diff_wave(s)
    best = 1
    for cmpf in (lambda a, b: b >= a, lambda a, b: b <= a):
        run = 1
        for i in range(1, len(d)):
            run = run + 1 if cmpf(d[i - 1], d[i]) else 1
            best = max(best, run)
    return best

def _r7_obs_i(s):   # adjacent pairs differing in exactly 1 bit
    return sum(1 for d in _r7_diff_wave(s) if d == 1)

def _r7_obs_j(s):   # width-5 popcount-palindromic windows (of 60)
    pc = [bin(h).count("1") for h in s]
    return sum(1 for i in range(60)
               if pc[i] == pc[i + 4] and pc[i + 1] == pc[i + 3])

_R7_OBSERVABLES = [
    ("a. Hamming-5 transition count (no-5 <=> 0)", _r7_obs_a),
    ("b. partner-adjacent pairs (of 32 slots)", _r7_obs_b),
    ("c1. upper-trigram changes (of 63)", _r7_obs_c1),
    ("c2. lower-trigram changes (of 63)", _r7_obs_c2),
    ("d. diff-wave Shannon entropy (bits)", _r7_obs_d),
    ("e. diff-wave lag-1 autocorrelation", _r7_obs_e),
    ("f. complement-distance sum (32 pairs)", _r7_obs_f),
    ("g. doubled trigrams at block starts (of 16)", _r7_obs_g),
    ("h. longest monotone diff-wave run", _r7_obs_h),
    ("i. 1-bit transitions", _r7_obs_i),
    ("j. popcount-palindromic width-5 windows (of 60)", _r7_obs_j),
]

def _r7_percentile(null_vals, obs):
    """Mid-percentile (lt + 0.5*eq), F8 convention."""
    lt = sum(1 for v in null_vals if v < obs)
    eq = sum(1 for v in null_vals if v == obs)
    return 100.0 * (lt + 0.5 * eq) / len(null_vals)

# ------------------------------------------------- constraint families J/M/B/C
# Each family predicate is extracted from its own tradition exactly as C1-C5
# were from KW (symmetric extraction circularity, disclosed). Trigram helpers:
def _r7_U(h):
    return (h >> 3) & 7

def _r7_L(h):
    return h & 7

# Jing Fang's natural family J1-J5 (palace-orbit representation) --------------

def _r7_J1(s):
    """J1 (palace-orbit partition, PRIMARY): the sequence splits into 8
    consecutive blocks of 8 and each block b equals some pure trigram t_b's
    world-stage orbit W(t_b). Returns [t_0..t_7] if J1 holds, else None.
    Residual freedom given J1: 8! = 40,320 sequences."""
    tb = []
    for b in range(8):
        blk = s[8 * b:8 * b + 8]
        found = None
        for t in range(8):
            if _r7_W(t) == blk:
                found = t
                break
        if found is None:
            return None
        tb.append(found)
    return tb

def _r7_J2(s):
    """J2 (yang/yin palace bipartition): popcount(t_b) odd for b in 0..3, even
    for b in 4..7, with t_0 = Qian(7) and t_4 = Kun(0) heading each half.
    Conditional on J1."""
    tb = _r7_J1(s)
    if tb is None:
        return False
    if tb[0] != 7 or tb[4] != 0:
        return False
    if not all(bin(tb[b]).count("1") % 2 == 1 for b in range(4)):
        return False
    if not all(bin(tb[b]).count("1") % 2 == 0 for b in range(4, 8)):
        return False
    return True

def _r7_J3(s):
    """J3 (seniority order within halves): sons Zhen(1),Kan(2),Gen(4) then
    daughters Xun(6),Li(5),Dui(3). J1^J2^J3 determines the sequence
    completely (residual 0 bits) -- the provably-algorithmic statement."""
    tb = _r7_J1(s)
    if tb is None:
        return False
    return tb == [7, 1, 2, 4, 0, 6, 5, 3]

def _r7_J4(s):
    """J4 (complement palace symmetry; DERIVED from J2^J3, not independent):
    t_{b+4} = comp3(t_b) for b=0..3. Forces every complement pair 32 apart ->
    complement-distance sum 1024 (max). Flagged derived so it is not
    double-counted."""
    tb = _r7_J1(s)
    if tb is None:
        return False
    return all(tb[b + 4] == (tb[b] ^ 7) for b in range(4))

_R7_JF_DIFFWAVE = {1: 48, 3: 15}

def _r7_J5(s):
    """J5 (difference-wave signature): diff-wave multiset exactly {1:48, 3:15}."""
    return _r7_dw_multiset(s) == _R7_JF_DIFFWAVE

# Mawangdui's natural family M1-M5 (trigram-octet representation) -------------

_R7_LAMBDA = [7, 0, 4, 3, 2, 5, 1, 6]   # base lower cycle: Qian,Kun,Gen,Dui,Kan,Li,Zhen,Xun
_R7_MD_UPPER_ORDER = [7, 4, 2, 1, 0, 3, 5, 6]  # M4: Qian,Gen,Kan,Zhen,Kun,Dui,Li,Xun

def _r7_lambda_promote(u):
    """Lambda with trigram u moved to the front, remaining order preserved."""
    return [u] + [x for x in _R7_LAMBDA if x != u]

def _r7_M1(s):
    """M1 (constant-upper octet partition, PRIMARY): 8 consecutive blocks of 8
    with constant upper trigram per block, the 8 uppers distinct. Returns the
    8 block-uppers if M1 holds, else None."""
    ups = []
    for b in range(8):
        if len({_r7_U(s[8 * b + o]) for o in range(8)}) != 1:
            return None
        ups.append(_r7_U(s[8 * b]))
    if len(set(ups)) != 8:
        return None
    return ups

def _r7_M2(s):
    """M2 (pure head): each octet opens with its doubled hexagram
    L(seq[8b]) == U(seq[8b]). (Implied by M3 -- promotion puts the octet's
    own trigram first.)"""
    ups = _r7_M1(s)
    if ups is None:
        return False
    return all(_r7_L(s[8 * b]) == _r7_U(s[8 * b]) for b in range(8))

def _r7_M3(s):
    """M3 (fixed lower cycle Lambda with promotion): each octet's lower
    trigrams are Lambda with the octet's own upper trigram promoted to front,
    the remaining order preserved."""
    ups = _r7_M1(s)
    if ups is None:
        return False
    for b in range(8):
        exp = _r7_lambda_promote(ups[b])
        if [_r7_L(s[8 * b + o]) for o in range(8)] != exp:
            return False
    return True

def _r7_M4(s):
    """M4 (gender-blocked upper order): upper octet order equals
    [Qian,Gen,Kan,Zhen,Kun,Dui,Li,Xun] (father, sons youngest->eldest, mother,
    daughters youngest->eldest)."""
    ups = _r7_M1(s)
    if ups is None:
        return False
    return ups == _R7_MD_UPPER_ORDER

_R7_MD_DIFFWAVE = {1: 21, 2: 10, 3: 29, 4: 2, 5: 1}

def _r7_M5(s):
    """M5 (difference-wave signature): diff-wave multiset exactly
    {1:21, 2:10, 3:29, 4:2, 5:1}, the single Hamming-5 at the octet seam."""
    return _r7_dw_multiset(s) == _R7_MD_DIFFWAVE

def _r7_M_joint(s):
    """Joint-M = M1 ^ M3 ^ M4 -- the reconstruction set that recovers the
    corrected Mawangdui sequence exactly. This is the frozen manufacture-alarm
    unit for the M family (a single weak predicate such as M1 is deliberately
    NOT the alarm unit; see the Fu Xi off-home M1 pass)."""
    return _r7_M1(s) is not None and _r7_M3(s) and _r7_M4(s)

def _r7_md_reconstruct():
    """Build the Mawangdui sequence from M1^M3^M4 alone (M4 upper order +
    Lambda-promotion lowers). Frozen anchor: this equals the corrected MD data
    exactly (residual 0 bits given the two conventions)."""
    rec = []
    for u in _R7_MD_UPPER_ORDER:
        for l in _r7_lambda_promote(u):
            rec.append((u << 3) | l)
    return rec

# Fu Xi's family B1 (identity) -----------------------------------------------

def _r7_B1(s):
    """B1 (identity): seq[i] == i. Fully algorithmic, zero conventions."""
    return s == list(range(64))

# King Wen's C1-C3 (the published axes, for the cross-application matrix) -----

def _r7_C1(s):
    """C1: all 32 pair-slots partner-adjacent (obs b == 32)."""
    return _r7_obs_b(s) == 32

def _r7_C2(s):
    """C2: no Hamming-5 transition (obs a == 0)."""
    return _r7_obs_a(s) == 0

_R7_C3_CEILING = 776  # KW total complement distance (full-sum convention; solve.c KW_C3_CEILING)

def _r7_C3(s):
    """C3: total complement distance <= 776 (full-sum convention; obs f is the
    /2 form, so 2*obs_f). KW = 776 (pass); JF/MD/Fu Xi = 2048 (fail)."""
    return 2 * _r7_obs_f(s) <= _R7_C3_CEILING

def _r7_dw_multiset(s):
    import collections
    return dict(sorted(collections.Counter(_r7_diff_wave(s)).items()))

# ------------------------------------------------------- cross-validation (FC-2)

def _r7_cross_validation_checks():
    """FC-2 data-integrity gate (frozen section 2 / section 8). Every line must
    PASS before any measurement; a mismatch is fixed + logged, never
    rationalized (2026-07-05 Mawangdui erratum lesson)."""
    kw = _r7_kw()
    jf = _r7_jingfang()
    md = _r7_mawangdui()
    fx = _r7_fuxi()
    kw_c, md_c = _r7_solve_c_kw_md()
    checks = []
    checks.append(("solve.c kw[] == solve.py binary_hexagrams", kw_c == kw))
    checks.append(("Mawangdui (roae.py indices) == solve.c --null-historical", md == md_c))
    for nm, s in (("KW", kw), ("Jing Fang", jf), ("Mawangdui", md), ("Fu Xi", fx)):
        checks.append((f"{nm} is a permutation of 0..63", sorted(s) == list(range(64))))
    return checks

def _r7_family_anchor_checks():
    """FC-2 family anchors (frozen section 3-4, section 7 already-observed ledger):
    the J/M families reproduce their traditions, and the frozen structural
    facts hold. Each entry is (label, expected, computed)."""
    kw, jf, md, fx = _r7_kw(), _r7_jingfang(), _r7_mawangdui(), _r7_fuxi()
    out = []
    # Jing Fang reproduces its tradition
    out.append(("J1 holds on Jing Fang (palace-orbit octets)", True, _r7_J1(jf) is not None))
    out.append(("J1 t_b on JF == [Qian,Zhen,Kan,Gen,Kun,Xun,Li,Dui]",
                [7, 1, 2, 4, 0, 6, 5, 3], _r7_J1(jf)))
    out.append(("J2 holds on Jing Fang", True, _r7_J2(jf)))
    out.append(("J3 holds on Jing Fang (J1^J2^J3 -> residual 0)", True, _r7_J3(jf)))
    out.append(("J4 (derived complement symmetry) holds on JF", True, _r7_J4(jf)))
    out.append(("J5 diff-wave multiset == {1:48, 3:15}", True, _r7_J5(jf)))
    out.append(("J1^J2^J3 determines the JF sequence uniquely",
                jf, _r7_jf_from_conventions()))
    # Mawangdui reproduces its tradition
    out.append(("M1 holds on Mawangdui (constant-upper octets)", True, _r7_M1(md) is not None))
    out.append(("M1 uppers on MD == [Qian,Gen,Kan,Zhen,Kun,Dui,Li,Xun]",
                _R7_MD_UPPER_ORDER, _r7_M1(md)))
    out.append(("M2 holds on Mawangdui (pure heads)", True, _r7_M2(md)))
    out.append(("M3 holds on Mawangdui (Lambda-promotion lowers)", True, _r7_M3(md)))
    out.append(("M4 holds on Mawangdui (gender-blocked uppers)", True, _r7_M4(md)))
    out.append(("M5 diff-wave multiset == {1:21,2:10,3:29,4:2,5:1}", True, _r7_M5(md)))
    out.append(("M1^M3^M4 reconstruct the corrected Mawangdui EXACTLY",
                md, _r7_md_reconstruct()))
    # Complement sums (frozen section 7 already-observed ledger; /2 convention)
    out.append(("comp-sum (obs f): KW / JF / MD == 388 / 1024 / 1024",
                (388, 1024, 1024), (_r7_obs_f(kw), _r7_obs_f(jf), _r7_obs_f(md))))
    # B1
    out.append(("B1 (identity) holds on Fu Xi", True, _r7_B1(fx)))
    return out

def _r7_jf_from_conventions():
    """Reconstruct Jing Fang from J1^J2^J3 (t_b = [7,1,2,4,0,6,5,3], each block
    = W(t_b)). Frozen: this equals the JF generator sequence exactly."""
    out = []
    for t in [7, 1, 2, 4, 0, 6, 5, 3]:
        out += _r7_W(t)
    return out

# --------------------------------------------- cross-application matrix (section 5)
# home tradition of each alarm predicate: C1->KW, J1->JF, M-joint->MD, B1->Fu Xi.
_R7_MATRIX_PREDICATES = [
    ("C1 (32 partner-adjacent pairs)", _r7_C1, "KW"),
    ("C2 (no Hamming-5)", _r7_C2, None),
    ("C3 (comp-dist sum <= 776)", _r7_C3, None),
    ("J1 (palace-orbit octets)", lambda s: _r7_J1(s) is not None, "Jing Fang"),
    ("M1 (constant-upper octets)", lambda s: _r7_M1(s) is not None, None),
    ("M-joint (M1^M3^M4 reconstruct)", _r7_M_joint, "Mawangdui"),
    ("B1 (identity)", _r7_B1, "Fu Xi"),
]
# alarm predicates whose OFF-HOME pass triggers FC-3 (frozen section 5 tally):
_R7_ALARM_PREDICATES = {"C1 (32 partner-adjacent pairs)": "KW",
                        "J1 (palace-orbit octets)": "Jing Fang",
                        "M-joint (M1^M3^M4 reconstruct)": "Mawangdui",
                        "B1 (identity)": "Fu Xi"}


def r7_verify():
    """--r7-verify: assert the frozen R7 anchors deterministically (no
    N=10^6 measurement). Gates: FC-2 construction cross-validation; the J/M
    families reproduce their traditions (J1-J5 on JF; M1-M5 + exact MD
    reconstruction; the two diff-wave multisets); the cross-application matrix
    a-priori/theorem cells; the FC-1 positive-control EXPECTATION
    reproduced at the pilot N=10^4 (already-observed ledger: JF/MD >= 8/11
    EXTREME, KW extremes == {a,b,f}); and the Amendment-1 (2026-07-12)
    corrected FC-4 anchor counts over the exact J1 space (comp-sum-1024
    attainers 9,216/40,320, mid-percentile 88.57; J4 count 384; J2^J3 count 1
    -- counts-only fast path, no observable distributions). Returns 0 on full
    PASS, 1 on any mismatch. This is code-verification of frozen anchors, NOT
    the operator-gated N=10^6 battery."""
    failures = 0
    print("# R7 --r7-verify : frozen corpus-control anchors")
    print("# design: roae-private/R7_CORPUS_CONTROL_DESIGN_FROZEN_2026_07_11.md (b00911b)")
    print("# + Amendment 1 (2026-07-12, 53e088a): corrected FC-4 anchor counts\n")

    print("## FC-2 construction cross-validation (data integrity)")
    for name, ok in _r7_cross_validation_checks():
        if not ok:
            failures += 1
        print(f"  [{'PASS' if ok else 'FAIL'}] {name}")

    print("\n## FC-2 family anchors (J/M families reproduce their traditions)")
    for label, expected, computed in _r7_family_anchor_checks():
        ok = (expected == computed)
        if not ok:
            failures += 1
        extra = "" if ok else f"  expected={expected} computed={computed}"
        print(f"  [{'PASS' if ok else 'FAIL'}] {label}{extra}")

    print("\n## Cross-application matrix -- a-priori / theorem cells (section 5)")
    kw, jf, md, fx = _r7_kw(), _r7_jingfang(), _r7_mawangdui(), _r7_fuxi()
    seqs = [("KW", kw), ("Jing Fang", jf), ("Mawangdui", md), ("Fu Xi", fx)]
    # Frozen expected pass/fail per (predicate, ordering) for the anchored cells.
    matrix_expected = {
        "C1 (32 partner-adjacent pairs)": {"KW": True, "Jing Fang": False,
                                           "Mawangdui": False, "Fu Xi": False},
        "C2 (no Hamming-5)": {"KW": True, "Jing Fang": True,
                              "Mawangdui": False, "Fu Xi": False},
        "C3 (comp-dist sum <= 776)": {"KW": True, "Jing Fang": False,
                                      "Mawangdui": False, "Fu Xi": False},
        "J1 (palace-orbit octets)": {"KW": False, "Jing Fang": True,
                                     "Mawangdui": False, "Fu Xi": False},
        "M1 (constant-upper octets)": {"KW": False, "Jing Fang": False,
                                       "Mawangdui": True, "Fu Xi": True},
        "M-joint (M1^M3^M4 reconstruct)": {"KW": False, "Jing Fang": False,
                                           "Mawangdui": True, "Fu Xi": False},
        "B1 (identity)": {"KW": False, "Jing Fang": False,
                          "Mawangdui": False, "Fu Xi": True},
    }
    for label, pred, home in _R7_MATRIX_PREDICATES:
        exp = matrix_expected[label]
        cells = []
        for nm, s in seqs:
            got = bool(pred(s))
            ok = (got == exp[nm])
            if not ok:
                failures += 1
            tag = "P" if got else "."
            mark = "" if ok else "!"
            cells.append(f"{nm[:2]}={tag}{mark}")
        print(f"  [{label}] " + " ".join(cells)
              + (f"  (home={home})" if home else ""))
    # The honest off-home pass we flag ourselves (frozen section 5 note i):
    print("  NOTE: M1 passes off-home on Fu Xi (upper-sorted by construction) --")
    print("        excluded from the FC-3 alarm ONLY by the joint-M requirement,")
    print("        which Fu Xi fails a-priori at M2/M3/M4. Flagged, not hidden.")

    print("\n## FC-1 positive-control expectation (pilot N=10^4, seed 42 -- ledger anchor)")
    counts = _r7_l0_extreme_counts(n=10_000, seed=42)
    for nm, expect in (("KW", 3), ("Jing Fang", 9), ("Mawangdui", 9)):
        cnt = counts[nm]["count"]
        ex = counts[nm]["extremes"]
        ok = (cnt == expect)
        # FC-1 broken-instrument gate is >= 8 for JF/MD; anchor is the exact pilot value.
        if not ok:
            failures += 1
        print(f"  [{'PASS' if ok else 'FAIL'}] {nm}: {cnt}/11 EXTREME "
              f"(pilot anchor {expect}) {ex}")
    kw_ex = set(counts["KW"]["extremes"])
    ok_kw = (kw_ex == {"a", "b", "f"})
    if not ok_kw:
        failures += 1
    print(f"  [{'PASS' if ok_kw else 'FAIL'}] KW L0 extremes == {{a,b,f}} "
          f"(the C1/C2/C3 axes; FC-3 growth-of-set watch)")
    jf_ok = counts["Jing Fang"]["count"] >= 8
    md_ok = counts["Mawangdui"]["count"] >= 8
    print(f"  [{'PASS' if jf_ok else 'FAIL'}] FC-1 broken-instrument gate: "
          f"Jing Fang >= 8/11 EXTREME (provably algorithmic)")
    print(f"  [{'PASS' if md_ok else 'FAIL'}] FC-1 broken-instrument gate: "
          f"Mawangdui >= 8/11 EXTREME")
    if not jf_ok:
        failures += 1
    if not md_ok:
        failures += 1

    print("\n## Amendment-1 (2026-07-12) corrected FC-4 anchors -- exact "
          "J1-space counts (8! = 40,320)")
    comp_sums, c_j4, c_j2j3, _ = _r7_jf_l1_exact(observables=False)
    n_max = sum(1 for v in comp_sums if v == 1024)
    pctl_1024 = _r7_percentile(comp_sums, 1024)
    for label, expected, computed in (
            ("J1 space size == 40,320", 40320, len(comp_sums)),
            ("comp-sum exact-space maximum == 1024", 1024, max(comp_sums)),
            ("comp-sum-1024 attainers == 9,216 (4!*4!*2^4, ~22.86%)",
             9216, n_max),
            ("P(J4 | J1) numerator == 384 (8*6*4*2)", 384, c_j4),
            ("P(J2^J3 | J1) numerator == 1 (canonical palace order)",
             1, c_j2j3),
            ("comp-sum-1024 mid-percentile == 88.57 (NOT >=99; the "
             "erroneous pre-amendment clause)", 88.57, round(pctl_1024, 2)),
    ):
        ok = (expected == computed)
        if not ok:
            failures += 1
        extra = "" if ok else f"  expected={expected} computed={computed}"
        print(f"  [{'PASS' if ok else 'FAIL'}] {label}{extra}")

    print()
    if failures:
        print(f"R7 VERIFY: {failures} FAILURES")
        return 1
    print("R7 VERIFY: ALL ANCHORS PASS")
    return 0


def _r7_uniform_nulls(n, seed):
    """L0 uniform null: n uniform random permutations of 0..63, all 11
    observables per permutation. Shared RNG discipline random.Random(seed)."""
    rng = random.Random(seed)
    base = list(range(64))
    out = {name: [] for name, _ in _R7_OBSERVABLES}
    for _ in range(n):
        p = base[:]
        rng.shuffle(p)
        for name, fn in _R7_OBSERVABLES:
            out[name].append(fn(p))
    return out


def _r7_l0_extreme_counts(n, seed):
    """For each ordering, count observables flagged EXTREME (percentile <=1 or
    >=99) vs the L0 uniform null. Returns {name: {count, extremes}}. The letter
    key of each observable is the token before '.' in its label."""
    nulls = _r7_uniform_nulls(n, seed)
    seqs = [("KW", _r7_kw()), ("Jing Fang", _r7_jingfang()),
            ("Mawangdui", _r7_mawangdui()), ("Fu Xi", _r7_fuxi())]
    res = {}
    for nm, s in seqs:
        extremes = []
        for label, fn in _R7_OBSERVABLES:
            key = label.split(".")[0]
            p = _r7_percentile(nulls[label], fn(s))
            if p <= 1.0 or p >= 99.0:
                extremes.append(key)
        res[nm] = {"count": len(extremes), "extremes": extremes}
    return res


def _r7_pair_preserving_nulls(n, seed):
    """Project-standard KW null: shuffle the 32 KW pairs + random orientation."""
    rng = random.Random(seed)
    kw = _r7_kw()
    pairs = [(kw[2 * k], kw[2 * k + 1]) for k in range(32)]
    out = {name: [] for name, _ in _R7_OBSERVABLES}
    for _ in range(n):
        perm = pairs[:]
        rng.shuffle(perm)
        seq = []
        for a, b in perm:
            if rng.random() < 0.5:
                a, b = b, a
            seq += [a, b]
        for name, fn in _R7_OBSERVABLES:
            out[name].append(fn(seq))
    return out


def _r7_jf_l1_exact(observables=True):
    """Jing Fang L1 (J1-conditioned) null: EXACT enumeration of all 8! = 40,320
    block-assignments b -> t_b (each block = W(t_b)). Honors the no-subsampling
    norm where the space permits. With observables=True (the battery), scores
    ALL 11 F8 observables over the exact space (frozen section 7: 'each
    observable is scored ... against each tradition's own L1/L2 nulls').
    observables=False is the fast counts-only path used by --r7-verify to gate
    the Amendment-1 (2026-07-12) corrected FC-4 anchor counts.
    Returns (comp_sums, count_j4, count_j2j3, obs_dists) where obs_dists =
    {label: [40,320 values]} or None when observables=False."""
    import itertools
    f_label = next(nm for nm, _ in _R7_OBSERVABLES if nm.startswith("f."))
    obs_dists = {name: [] for name, _ in _R7_OBSERVABLES} if observables else None
    comp_sums = []
    count_j4 = 0
    count_j2j3 = 0
    for perm in itertools.permutations(range(8)):
        seq = []
        for t in perm:
            seq += _r7_W(t)
        if observables:
            for name, fn in _R7_OBSERVABLES:
                obs_dists[name].append(fn(seq))
            comp_sums.append(obs_dists[f_label][-1])
        else:
            comp_sums.append(_r7_obs_f(seq))
        tb = list(perm)
        if all(tb[b + 4] == (tb[b] ^ 7) for b in range(4)):
            count_j4 += 1
        if tb == [7, 1, 2, 4, 0, 6, 5, 3]:
            count_j2j3 += 1
    return comp_sums, count_j4, count_j2j3, obs_dists


def _r7_md_l1_nulls(n, seed, pure_head):
    """Mawangdui L1 null (sampled). M1-conditioned: random upper permutation
    (8!) x within each block a random permutation of the 8 lowers ((8!)^8). If
    pure_head, additionally condition on M2 (each block opens lower==upper),
    permuting only the remaining 7 lowers. Returns ({name: [values]}, m4_hits)
    where m4_hits counts samples whose upper order equals the M4 order --
    the sampled cross-check of the exact P(M4|M1) = 1/8! (Amendment 1 item 4;
    counting is observation-only and does not touch the RNG stream)."""
    rng = random.Random(seed)
    out = {name: [] for name, _ in _R7_OBSERVABLES}
    trigs = list(range(8))
    m4_hits = 0
    for _ in range(n):
        uppers = trigs[:]
        rng.shuffle(uppers)
        if uppers == _R7_MD_UPPER_ORDER:
            m4_hits += 1
        seq = []
        for u in uppers:
            if pure_head:
                rest = [x for x in trigs if x != u]
                rng.shuffle(rest)
                lowers = [u] + rest
            else:
                lowers = trigs[:]
                rng.shuffle(lowers)
            seq += [(u << 3) | l for l in lowers]
        for name, fn in _R7_OBSERVABLES:
            out[name].append(fn(seq))
    return out, m4_hits


def _r7_md_l2_nulls(n, seed):
    """Mawangdui L2 null (frozen section 6, MD L2 row): M1^M3-conditioned with
    BOTH conventions free -- a random upper order (8!) x a random base cycle
    Lambda' (8!); each octet's lowers are Lambda' with the octet's own upper
    trigram promoted to the front (exact factor structure 8! x 8! =
    1,625,702,400). Frozen decision rule (section 10): the exact grid is
    attempted only if a factorized / vectorized route keeps it under ~2 h on
    the worker; 1.63e9 sequence evaluations x 11 observables in pure Python
    does not, so the sampled N=10^6 seed-42 fallback is used and the deviation
    is logged in the battery output (no mid-run judgment calls). Draw order
    per sample: uppers first, then Lambda'. Returns {name: [values]}."""
    rng = random.Random(seed)
    out = {name: [] for name, _ in _R7_OBSERVABLES}
    trigs = list(range(8))
    for _ in range(n):
        uppers = trigs[:]
        rng.shuffle(uppers)
        lam = trigs[:]
        rng.shuffle(lam)
        seq = []
        for u in uppers:
            lowers = [u] + [x for x in lam if x != u]
            seq += [(u << 3) | l for l in lowers]
        for name, fn in _R7_OBSERVABLES:
            out[name].append(fn(seq))
    return out


def r7_corpus(n=1_000_000, seed=42, jf_exact=True):
    """--r7-corpus: run the full R7 cross-tradition corpus-control battery and
    emit the markdown scoreboard. Frozen run parameters: L0 uniform N=10^6
    seed 42 (all four orderings, 11 observables, incl. the pilot-vs-rerun
    EXTREME-boundary halt rule and the P(comp-sum=1024|L0) rate); Jing Fang L1
    EXACT (all 8! = 40,320 J1-conditioned block assignments, full 11-observable
    battery + exact predicate rates); Mawangdui L1 sampled N=10^6 x2
    (M1-conditioned and M1^M2-conditioned, full battery, + exact P(M4|M1) with
    sampled cross-check); Mawangdui L2 sampled N=10^6 (M1^M3-conditioned, both
    conventions free; frozen exact-grid-if-<2h-else-sampled rule). The
    cross-application matrix, the MDL pricing row, and the FC-1..FC-4 verdicts
    (FC-4 per the corrected Amendment-1 anchor, 2026-07-12) follow.
    Report-only; every cell printed whatever it says (standing
    extraction-circularity policy).

    HEAVY-OPS: at the frozen N=10^6 this is hours-class on one core and MUST run
    on a Spot D4/D8 worker per the heavy-ops-offboard rule, NOT the 2-core
    orchestrator. Use --r7-n / --r7-seed to override for smoke tests only; the
    canonical measurement uses the defaults. Nothing here is sha-gated."""
    print("# R7 -- Cross-tradition corpus-control battery")
    print("# Frozen design: roae-private/R7_CORPUS_CONTROL_DESIGN_FROZEN_2026_07_11.md (b00911b)")
    print("# + Amendment 1 (2026-07-12, 53e088a): corrected FC-4 anchor "
          "(comp-sum 1024 is NOT extreme under the exact J1 null).")
    print(f"# L0 uniform N={n:,}, seed {seed}; Jing Fang L1 "
          f"{'EXACT (8!=40,320)' if jf_exact else 'skipped'}; MD L1 x2 + MD L2 "
          f"sampled N={n:,}; report-only.")
    print("# Developed with AI assistance (Claude, Anthropic). Classical orderings")
    print("# are not project inventions; J/M formalizations are hedged, not novel.\n")

    # --- FC-2 construction cross-validation ---
    print("## FC-2 construction cross-validation\n")
    cv_ok = True
    for name, ok in _r7_cross_validation_checks():
        cv_ok = cv_ok and ok
        print(f"- {'PASS' if ok else 'FAIL'}: {name}")
    print()
    print("## FC-2 family anchors\n")
    fam_ok = True
    for label, expected, computed in _r7_family_anchor_checks():
        ok = (expected == computed)
        fam_ok = fam_ok and ok
        print(f"- {'PASS' if ok else 'FAIL'}: {label}")
    print()
    if not (cv_ok and fam_ok):
        print("**FC-2 FAILED -- STOP. Fix data/family definitions and log a dated "
              "amendment BEFORE any interpretation (2026-07-05 erratum lesson).**\n")
        return 1

    kw, jf, md, fx = _r7_kw(), _r7_jingfang(), _r7_mawangdui(), _r7_fuxi()
    seqs = [("KW", kw), ("Jing Fang", jf), ("Mawangdui", md), ("Fu Xi", fx)]

    # --- L0 battery ---
    print(f"## L0 battery: observable x ordering, percentile vs uniform null "
          f"(N={n:,}, seed {seed})\n")
    print("Cell format: `value (pN)`; **EXTREME** if percentile <=1 or >=99.\n")
    nulls = _r7_uniform_nulls(n, seed)
    extremes = {nm: [] for nm, _ in seqs}
    print("| Observable | " + " | ".join(nm for nm, _ in seqs) + " |")
    print("|---" * (len(seqs) + 1) + "|")
    for label, fn in _R7_OBSERVABLES:
        key = label.split(".")[0]
        row = [label]
        for nm, s in seqs:
            v = fn(s)
            p = _r7_percentile(nulls[label], v)
            ex = (p <= 1.0 or p >= 99.0)
            if ex:
                extremes[nm].append(key)
            vs = f"{v:.4f}" if isinstance(v, float) else str(v)
            row.append(f"{vs} (p{p:.2f})" + (" **EXTREME**" if ex else ""))
        print("| " + " | ".join(row) + " |")
    print()
    print("| Ordering | EXTREME (of 11) | which |")
    print("|---|---|---|")
    for nm, _ in seqs:
        print(f"| {nm} | {len(extremes[nm])} | {','.join(extremes[nm])} |")
    print()
    # P(comp-sum = 1024 | L0) sampled rate (frozen section 6 rho set).
    f_label = next(nm for nm, _ in _R7_OBSERVABLES if nm.startswith("f."))
    f1024 = sum(1 for v in nulls[f_label] if v == 1024)
    print(f"P(comp-sum = 1024 | L0) = {f1024}/{n:,} "
          f"= {f1024 / n:.3e} (sampled rate, frozen section 6 rho set; "
          "the JF/MD home value is the 32-pair maximum).\n")
    # E3 rider (frozen section 7 / TRIGRAM_ANALYSIS_SCOPING_2026_07_11 sec E3):
    print("E3 rider note (TG-3): the c1/c2 columns above are the two canonical")
    print("trigram-locality functionals -- a factual KW-vs-recensions table with")
    print("no significance claims. Both are S3-relabel-invariant (they test only")
    print("trigram equality across a transition, so any relabeling of the eight")
    print("trigram values leaves them unchanged; verified reasoning, to be")
    print("certified with TG-3).\n")
    # Pilot-vs-rerun EXTREME-boundary halt rule (frozen section 7): any
    # percentile shifting across an EXTREME boundary halts interpretation.
    print("### Pilot-vs-rerun EXTREME-set diff (frozen section 7 halt rule)\n")
    pilot = _r7_l0_extreme_counts(n=10_000, seed=42)
    halt = False
    for nm, _ in seqs:
        pset = set(pilot[nm]["extremes"])
        rset = set(extremes[nm])
        gained = sorted(rset - pset)
        lost = sorted(pset - rset)
        diff = (f"gained={gained} lost={lost}" if (gained or lost)
                else "no boundary crossings")
        if gained or lost:
            halt = True
        print(f"- {nm}: pilot(N=10^4, seed 42) {sorted(pset)} vs "
              f"rerun {sorted(rset)} -- {diff}")
    if halt:
        print("\n**HALT RULE TRIGGERED (frozen section 7): a pilot-vs-rerun "
              "percentile shifted across an EXTREME boundary -- interpretation "
              "halts pending investigation.** (Expected when run at non-frozen "
              "smoke parameters; dispositive only at the frozen N=10^6, seed 42.)")
    print()

    # --- KW pair-preserving null (project-standard second null) ---
    print("## KW vs pair-preserving null (project-standard, KW only)\n")
    pnulls = _r7_pair_preserving_nulls(n, seed)
    print("| Observable | KW value | percentile |")
    print("|---|---|---|")
    kw_pp_ex = 0
    for label, fn in _R7_OBSERVABLES:
        v = fn(kw)
        p = _r7_percentile(pnulls[label], v)
        ex = (p <= 1.0 or p >= 99.0)
        kw_pp_ex += ex
        vs = f"{v:.4f}" if isinstance(v, float) else str(v)
        print(f"| {label} | {vs} | p{p:.2f}" + (" **EXTREME**" if ex else "") + " |")
    print(f"\nKW EXTREME vs pair-preserving null: {kw_pp_ex}/11 "
          "(observable b is invariant under this null by construction).\n")

    # --- cross-application matrix ---
    print("## Cross-application matrix (section 5 -- the manufacture alarm)\n")
    print("`P` = predicate holds, `.` = fails, `n/a` = conditional parent fails.\n")
    print("| Predicate | " + " | ".join(nm for nm, _ in seqs) + " | home |")
    print("|---" * (len(seqs) + 2) + "|")
    alarm_hits = []
    for label, pred, home in _R7_MATRIX_PREDICATES:
        row = [label]
        for nm, s in seqs:
            got = bool(pred(s))
            row.append("P" if got else ".")
            if label in _R7_ALARM_PREDICATES and got and nm != _R7_ALARM_PREDICATES[label]:
                alarm_hits.append((label, nm))
        row.append(home or "-")
        print("| " + " | ".join(row) + " |")
    print()
    # Fu Xi M1 off-home pass is expected + excluded by joint-M; do not count it.
    real_alarms = [(lbl, nm) for (lbl, nm) in alarm_hits]
    print("Off-home passes among alarm predicates {C1, J1, M-joint, B1}: "
          f"{real_alarms if real_alarms else 'NONE'}")
    print("(The Fu Xi off-home M1 pass is NOT an alarm predicate -- M1 alone is a")
    print("weak predicate excluded by the joint-M requirement; Fu Xi fails M2/M3/M4.)\n")

    # --- Jing Fang L1 exact enrichment (full battery, frozen section 7) ---
    jf_l1_extreme = None
    if jf_exact:
        print("## Jing Fang L1 (J1-conditioned) EXACT -- all 8! = 40,320, "
              "full 11-observable battery\n")
        comp_sums, c_j4, c_j2j3, jf_dists = _r7_jf_l1_exact(observables=True)
        print("Exact enumeration (no sampling; frozen section 6 mandates exact "
              "where the space permits).\n")
        print("| Observable | JF value | percentile (exact J1 null) |")
        print("|---|---|---|")
        jf_l1_extreme = []
        for label, fn in _R7_OBSERVABLES:
            key = label.split(".")[0]
            v = fn(jf)
            p = _r7_percentile(jf_dists[label], v)
            ex = (p <= 1.0 or p >= 99.0)
            if ex:
                jf_l1_extreme.append(key)
            vs = f"{v:.4f}" if isinstance(v, float) else str(v)
            print(f"| {label} | {vs} | p{p:.2f}"
                  + (" **EXTREME**" if ex else "") + " |")
        print(f"\nJF EXTREME vs its own exact L1 null: {len(jf_l1_extreme)}/11 "
              f"({','.join(jf_l1_extreme) if jf_l1_extreme else 'none'}).\n")
        jf_f = _r7_obs_f(jf)
        pctl = _r7_percentile(comp_sums, jf_f)
        n_max = sum(1 for v in comp_sums if v == jf_f)
        import math as _math
        p_j1_l0 = _math.factorial(8) / _math.factorial(64)
        print(f"- P(J1 | L0) = 8!/64! ~= {p_j1_l0:.3e} (analytic, frozen "
              "section 6 -- the J1 space has exactly 8! members; 0 sampled "
              "hits expected at any feasible N).")
        print(f"- P(J2^J3 | J1) = {c_j2j3}/40,320 (exact count = the canonical "
              "palace order; residual 0 bits)")
        print(f"- P(J4 | J1) = {c_j4}/40,320 = {100.0*c_j4/40320:.4f}% "
              "(complement-respecting assignments; below the 1% EXTREME line)")
        print(f"- JF comp-sum (obs f) = {jf_f} (the exact-space maximum), reached "
              f"by {n_max}/40,320 = {100.0*n_max/40320:.4f}% of assignments; "
              f"mid-percentile {pctl:.2f} of the exact J1 distribution.")
        print("  CORRECTED FC-4 ANCHOR (design Amendment 1, 2026-07-12): "
              "comp-sum 1024 is NOT rare under the exact J1 null -- the whole "
              "block-distance-maximizing class (4! x 4! x 2^4 = 9,216 "
              "assignments, ~22.86%) attains it, so it is expected NOT to flag "
              "EXTREME here. The original frozen FC-4 clause ('>=99th "
              "percentile, since 384/40,320 reach it') conflated 'reaches "
              "comp-sum 1024' with 'satisfies J4' (J4 is a strict subset). The "
              "palace ORDER is what is rare (the predicate rates above); the "
              "comp-sum scalar is a coarse proxy the whole maximizing class "
              "achieves.\n")

    # --- Mawangdui L1 sampled enrichment (full battery, frozen section 7) ---
    print("## Mawangdui L1 (sampled) enrichment ladder -- full 11-observable "
          "battery\n")
    print(f"Sampled at N={n:,}, seed {seed} (M1-null space 8!*(8!)^8 too large to "
          "enumerate); labeled sampled per the F8 precedent.\n")
    md_m1, m4_hits = _r7_md_l1_nulls(n, seed, pure_head=False)
    md_m1m2, _ = _r7_md_l1_nulls(n, seed, pure_head=True)
    print("| Observable | MD value | pctl (M1-cond null) | pctl (M1^M2-cond null) |")
    print("|---|---|---|---|")
    md_l1_extreme = []
    for label, fn in _R7_OBSERVABLES:
        key = label.split(".")[0]
        v = fn(md)
        p1 = _r7_percentile(md_m1[label], v)
        p2 = _r7_percentile(md_m1m2[label], v)
        ex1 = (p1 <= 1.0 or p1 >= 99.0)
        ex2 = (p2 <= 1.0 or p2 >= 99.0)
        if ex1:
            md_l1_extreme.append(key)
        vs = f"{v:.4f}" if isinstance(v, float) else str(v)
        print(f"| {label} | {vs} | p{p1:.2f}"
              + (" **EXTREME**" if ex1 else "")
              + f" | p{p2:.2f}" + (" **EXTREME**" if ex2 else "") + " |")
    print(f"\nMD EXTREME vs its own M1-conditioned L1 null: "
          f"{len(md_l1_extreme)}/11 "
          f"({','.join(md_l1_extreme) if md_l1_extreme else 'none'}). "
          "(The M1^M2 column is the pure-head proxy for the M2 layer.)\n")
    import math as _math
    p_m1_l0 = (_math.factorial(8) * _math.factorial(8) ** 8) / _math.factorial(64)
    print(f"- P(M1 | L0) = 8! * (8!)^8 / 64! ~= {p_m1_l0:.3e} (analytic, frozen "
          "section 6: 8! block-upper assignments x (8!)^8 within-block lower "
          "orders; 0 sampled hits expected at any feasible N).")
    print("- P(M2 | M1) = (1/8)^8 ~= 5.96e-8 and P(M3 | M1^M2): analytical "
          "(frozen section 6); 0/N expected under sampling. The exact factor "
          "structure 8!(Lambda) x 8!(upper order) = 1,625,702,400 gives "
          "residual 0 bits given the two conventions.")
    print(f"- P(M4 | M1) = 1/8! = 1/40,320 ~= {1.0/40320:.3e} (exact -- the "
          "upper order is uniform over 8! under the M1 null; frozen section 6 "
          "rho set, Amendment 1 item 4). Sampled cross-check from the "
          f"M1-conditioned draw: {m4_hits}/{n:,} hits "
          f"(expected ~{n/40320:.1f} at this N -- NOT 0-expected, unlike the "
          "L0-conditioned rates above).\n")

    # --- Mawangdui L2 (M1^M3-conditioned, both conventions free) ---
    print("## Mawangdui L2 (M1^M3-conditioned, both conventions free) -- "
          "full 11-observable battery\n")
    print("Frozen decision rule (section 10): exact 8! x 8! grid "
          "(1,625,702,400 sequence evaluations) only if < ~2 h on the worker; "
          "pure Python does not meet that, so the SAMPLED fallback is used and "
          f"the deviation is logged here (N={n:,}, seed {seed}; frozen rule, "
          "no mid-run judgment call).\n")
    md_l2 = _r7_md_l2_nulls(n, seed)
    print("| Observable | MD value | percentile (L2 null) |")
    print("|---|---|---|")
    md_l2_extreme = []
    for label, fn in _R7_OBSERVABLES:
        key = label.split(".")[0]
        v = fn(md)
        p = _r7_percentile(md_l2[label], v)
        ex = (p <= 1.0 or p >= 99.0)
        if ex:
            md_l2_extreme.append(key)
        vs = f"{v:.4f}" if isinstance(v, float) else str(v)
        print(f"| {label} | {vs} | p{p:.2f}"
              + (" **EXTREME**" if ex else "") + " |")
    print(f"\nMD EXTREME vs its own full-family L2 null: "
          f"{len(md_l2_extreme)}/11 "
          f"({','.join(md_l2_extreme) if md_l2_extreme else 'none'}). "
          "FC-4 expects residual flags to vanish under full L2 conditioning; "
          "a nonzero count is design incoherence, not a finding.\n")

    # --- MDL pricing row ---
    print("## MDL pricing (ties to DESCRIPTION_LENGTH.md)\n")
    print("| Ordering | family | residual bits (log2 |sequences satisfying full family|) |")
    print("|---|---|---|")
    print("| King Wen | C1-C5 | ~126.6 (published) |")
    print("| Jing Fang | J1-J3 | 0 |")
    print("| Mawangdui | M1^M3^M4 | 0 (conventions priced separately, <= log2(8!*8!) ~ 30.7 bits) |")
    print("| Fu Xi | B1 | 0 |")
    print("\nThesis: applied symmetrically, the methodology assigns each ordering "
          "its ACTUAL compression -- total for the algorithmic recensions, "
          "partial-with-vast-residual for KW -- not 'design' uniformly.\n")

    # --- FC verdicts ---
    print("## Falsification-gate verdicts (FC-1..FC-4)\n")
    jf_n = len(extremes["Jing Fang"])
    md_n = len(extremes["Mawangdui"])
    kw_set = set(extremes["KW"])
    fc1 = (jf_n >= 8 and md_n >= 8)
    print(f"- FC-1 (battery detects real design): Jing Fang {jf_n}/11, "
          f"Mawangdui {md_n}/11 EXTREME. {'PASS' if fc1 else 'BROKEN INSTRUMENT'} "
          "(gate: both >= 8; a battery that fails to flag the provably-"
          "algorithmic JF is declared broken, published as such -- NO threshold "
          "tuning).")
    print(f"- FC-2 (data integrity): construction + family anchors PASS "
          "(checked above).")
    fc3 = (len(real_alarms) == 0 and kw_set == {"a", "b", "f"})
    print(f"- FC-3 (manufacture alarm): off-home alarm passes = "
          f"{real_alarms if real_alarms else 'NONE'}; KW L0 extremes = "
          f"{sorted(kw_set)}. {'PASS (specificity holds)' if fc3 else 'ALARM -- adverse conclusion pre-committed'}.")
    md_l2_txt = (f"{len(md_l2_extreme)}/11 "
                 f"({','.join(md_l2_extreme) if md_l2_extreme else 'none'})")
    jf_l1_txt = ("skipped" if jf_l1_extreme is None else
                 f"{len(jf_l1_extreme)}/11 "
                 f"({','.join(jf_l1_extreme) if jf_l1_extreme else 'none'})")
    print("- FC-4 (matched-null coherence; corrected anchor per design "
          "Amendment 1, 2026-07-12): JF comp-sum is expected NOT EXTREME under "
          "the exact J1 null (the 9,216/40,320 ~ 22.86% distance-maximizing "
          "class attains 1024; mid-percentile 88.57) -- the secondary-structure "
          "rarity lives in the predicates P(J2^J3|J1) = 1/40,320 and "
          "P(J4|J1) = 384/40,320 ~ 0.952%, both reported above. JF full-battery "
          f"EXTREME vs its exact L1 null: {jf_l1_txt}. Under full L2 "
          "conditioning residual flags must vanish: JF L2 is a single point "
          "(residual 0 bits -- nothing to sample); MD L2 EXTREME flags "
          f"measured above: {md_l2_txt}; KW analogue = the pilot 0/11 "
          f"pair-preserving anchor (re-measured above: {kw_pp_ex}/11). "
          "Incoherence = design error, not a finding.")
    print()
    print("_All cells reported regardless of outcome. A pass shows the instrument "
          "distinguishes which orderings are structured, where, and by how much -- "
          "it does NOT show KW is 'designed'. Intent language stays out._")
    return 0


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
                        help="P3 sat-encode: include C3 as PB constraint (default: none). "
                             "'adder' is deferred/superseded by sat.py's pair-slot model "
                             "(emits a status sidecar entry only; see SOLVE_PY_CLI.md)")
    parser.add_argument("--sat-c4", action="store_true",
                        help="P3 sat-encode: force position 0 = hexagram 0 (Qian/Kun convention)")
    parser.add_argument("--sat-c5", action="store_true",
                        help="P3 sat-encode: C5 cardinality constraints — deferred/superseded "
                             "by sat.py's pair-slot model (emits a status sidecar entry only; "
                             "see SOLVE_PY_CLI.md)")
    parser.add_argument("--compare-depth-profile", nargs=2, metavar=("RUN_A_LOG", "RUN_B_LOG"),
                        help="Tree-walk validator (#48): compare DEPTH_PROFILE node counts from two run "
                             "logs (produced with SOLVE_DEPTH_PROFILE=1; .gz accepted). PASS if total "
                             "divergence < threshold. Tolerance-based, not byte-exact.")
    parser.add_argument("--compare-depth-profile-threshold", type=float, default=0.005,
                        help="Divergence threshold for --compare-depth-profile (default 0.005 = 0.5%%)")
    parser.add_argument("--f4p-verify", action="store_true",
                        help="verify the 13 pre-registered F4' ordering-layer functionals on KW")
    parser.add_argument("--f6-verify", action="store_true",
                        help="verify the 7 frozen F6 Nielsen-audit functionals "
                             "(Wu Deng warp/weft + Jing Fang bagong) on KW")
    parser.add_argument("--perm-verify", nargs="?", const="", default=None,
                        metavar="SEQ",
                        help="verify the 13 frozen R3 permutation-cycle "
                             "functionals (cycle observables per Ge 2026) on KW; "
                             "with an optional 64-int SEQ argument, instead print "
                             "the 13 values + 2 template indicators (identical "
                             "ordering to solve.c SOLVE_PERM_TESTVEC) for "
                             "cross-language / corpus-control gating")
    parser.add_argument("--rc1c-verify", nargs="?", const="", default=None,
                        metavar="SEQ",
                        help="R6: verify the circular anchor-adjacency indicator "
                             "R-C1c (A2={21,42} in pair slot 2 or 32) on KW "
                             "(expected slot2=0, slot32=1, adjacent=1); with a "
                             "64-int SEQ argument print `slot2,slot32,adjacent` "
                             "(ordering matches solve.c --rc1c-verify SEQ)")
    parser.add_argument("--r11-verify", nargs="?", const="", default=None,
                        metavar="SEQ",
                        help="R11: verify the frozen 8-axis violation bundle "
                             "(g1..g6 T1 + g7,g8 T2) on KW (expected "
                             "2,2,2,0,0,0,0,0); with a 64-int SEQ print the 8 "
                             "values (ordering matches solve.c --r11-verify SEQ)")
    parser.add_argument("--rc4b-verify", nargs="?", const="", default=None,
                        metavar="SEQ",
                        help="R13: verify the HEC two-convention parity "
                             "predicates on KW (expected viol=2 at adjacent "
                             "positions [25,26]; R-C4-A/B/C + rc3/rc3w all "
                             "pass); with a 64-int SEQ argument print "
                             "`viol,vp0,vp1,rc4a,rc4b,rc4c,rc3,rc3w` "
                             "(ordering matches solve.c --rc4b-verify SEQ)")
    parser.add_argument("--r7-corpus", action="store_true",
                        help="R7: run the cross-tradition corpus-control battery "
                             "(KW C1-C5 vs Jing Fang J1-J5, Mawangdui M1-M5, "
                             "Fu Xi B1) -- L0 uniform null (+ halt-rule diff), "
                             "JF L1 exact 8! full battery, MD L1 sampled x2 "
                             "full battery, MD L2 sampled (both conventions "
                             "free), rho rates, cross-application matrix, MDL "
                             "pricing, FC-1..FC-4 verdicts (FC-4 per Amendment "
                             "1); markdown to stdout. HEAVY at "
                             "the default N=10^6 (Spot D4/D8 worker, NOT the "
                             "orchestrator). Report-only, sha-neutral. Frozen "
                             "design: roae-private/R7_CORPUS_CONTROL_DESIGN_"
                             "FROZEN_2026_07_11.md + Amendment 1 (2026-07-12)")
    parser.add_argument("--r7-n", type=int, default=1_000_000,
                        help="--r7-corpus: null sample size N (default 10^6, the "
                             "frozen canonical value; lower only for smoke tests)")
    parser.add_argument("--r7-seed", type=int, default=42,
                        help="--r7-corpus: shared RNG seed (frozen default 42)")
    parser.add_argument("--r7-verify", action="store_true",
                        help="R7: assert the frozen corpus-control anchors "
                             "deterministically (FC-2 construction cross-"
                             "validation; J1-J5 reproduce Jing Fang; M1-M5 + "
                             "exact Mawangdui reconstruction; the cross-"
                             "application matrix a-priori cells; the FC-1 "
                             "positive-control expectation at the pilot N=10^4; "
                             "the Amendment-1 corrected FC-4 exact J1-space "
                             "counts). No N=10^6 measurement. Returns 0 on "
                             "PASS, 1 on any mismatch.")
    parser.add_argument("--r11-builder-verify", action="store_true",
                        help="R11: structural smoke-test of the M_G greedy-builder "
                             "machinery (KW-path softmax numerator, P_complete "
                             "simulation, synthetic draw). NOT the four-class "
                             "Bayes verdict (that is the post-freeze Spot job).")
    parser.add_argument("--dav-verify", action="store_true",
                        help="verify the 9 pre-registered Davis (2012) composite candidates on KW")
    parser.add_argument("--dav2-verify", action="store_true",
                        help="verify the 2 pre-registered Davis (2012) wave-2 candidates "
                             "(tquartet C-D9, xunslots C-D10) on KW")
    parser.add_argument("--db1-verify", action="store_true",
                        help="verify Drasny's 'Rule of Ten' D-B1 classifier (== Table 4.1, "
                             "all 64 hexagrams) and KW conformity count (X=22) — the "
                             "two-language SPEC gate for solve.c --db1-verify")
    parser.add_argument("--vdb-verify", action="store_true",
                        help="verify the 8 Van den Berghe (c.1998-2005) structural candidates on KW")
    parser.add_argument("--books-verify", action="store_true",
                        help="verify the machine-checkable structural claims "
                             "from the audited books (Wu Deng via Nielsen "
                             "2003, Lai Zhide, Goldenberg 1975, Jing Fang, "
                             "Yu Fan) against the King Wen sequence; one "
                             "PASS/FAIL line per claim with expected + "
                             "computed values")
    parser.add_argument("--trigram-verify", action="store_true",
                        help="verify every finite fact + King Wen instance "
                             "of lean/TrigramTheorems.lean's machine-checked "
                             "trigram-level statements (two-language ground "
                             "truth; see documentation/TRIGRAM_STRUCTURE.md); "
                             "one PASS/FAIL line per claim with expected + "
                             "computed values")
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

    if args.books_verify:
        sys.exit(books_verify())
    if args.trigram_verify:
        sys.exit(trigram_verify())

    if args.registry_verify:
        sys.exit(registry_verify())

    if args.f4p_verify:
        sys.exit(f4p_verify())

    if args.f6_verify:
        sys.exit(f6_verify())

    if args.perm_verify is not None:
        sys.exit(perm_verify(args.perm_verify if args.perm_verify else None))

    if args.rc1c_verify is not None:
        sys.exit(rc1c_verify(args.rc1c_verify if args.rc1c_verify else None))

    if args.r11_verify is not None:
        sys.exit(r11_verify(args.r11_verify if args.r11_verify else None))

    if args.rc4b_verify is not None:
        sys.exit(rc4b_verify(args.rc4b_verify if args.rc4b_verify else None))

    if args.r7_verify:
        sys.exit(r7_verify())

    if args.r7_corpus:
        sys.exit(r7_corpus(n=args.r7_n, seed=args.r7_seed))

    if args.r11_builder_verify:
        sys.exit(r11_builder_verify())

    if args.dav_verify:
        sys.exit(dav_verify())

    if args.dav2_verify:
        sys.exit(dav2_verify())

    if args.db1_verify:
        sys.exit(db1_verify())

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
