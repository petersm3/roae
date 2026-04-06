#!/usr/bin/env python3
import argparse
import json
import math
import random
import sys
import unicodedata

# Reverse the bit order of a 6-bit value, equivalent to flipping a hexagram
# upside down (180-degree rotation). Each hexagram has 6 lines (bits), so
# reversing maps bit 0 to bit 5, bit 1 to bit 4, etc.
# Example: 0b010001 (䷂) reversed becomes 0b100010 (䷃)
def reverse_6bit(n):
    return (
        ((n >> 0) & 1) << 5 |
        ((n >> 1) & 1) << 4 |
        ((n >> 2) & 1) << 3 |
        ((n >> 3) & 1) << 2 |
        ((n >> 4) & 1) << 1 |
        ((n >> 5) & 1) << 0
    )

# Count the number of bits that differ between two 6-bit values (popcount of XOR)
def bit_diff(a, b):
    return bin(a ^ b).count("1")

# Unicode hexagram characters in King Wen sequence order (1–64)
# https://en.wikipedia.org/wiki/King_Wen_sequence#Structure_of_the_sequence
unicode_hexagrams = [
    "䷀", "䷁", "䷂", "䷃", "䷄", "䷅", "䷆", "䷇",
    "䷈", "䷉", "䷊", "䷋", "䷌", "䷍", "䷎", "䷏",
    "䷐", "䷑", "䷒", "䷓", "䷔", "䷕", "䷖", "䷗",
    "䷘", "䷙", "䷚", "䷛", "䷜", "䷝", "䷞", "䷟",
    "䷠", "䷡", "䷢", "䷣", "䷤", "䷥", "䷦", "䷧",
    "䷨", "䷩", "䷪", "䷫", "䷬", "䷭", "䷮", "䷯",
    "䷰", "䷱", "䷲", "䷳", "䷴", "䷵", "䷶", "䷷",
    "䷸", "䷹", "䷺", "䷻", "䷼", "䷽", "䷾", "䷿",
]

# Each hexagram encoded as a 6-bit integer where each bit represents one line:
# 1 = solid (yang), 0 = broken (yin). Bit 0 is the bottom line, bit 5 the top.
# Values follow the King Wen sequence. Source: https://oeis.org/A102241
binary_hexagrams = [
    0b111111, 0b000000, 0b010001, 0b100010,  # ䷀ ䷁ ䷂ ䷃
    0b010111, 0b111010, 0b000010, 0b010000,  # ䷄ ䷅ ䷆ ䷇
    0b110111, 0b111011, 0b000111, 0b111000,  # ䷈ ䷉ ䷊ ䷋
    0b111101, 0b101111, 0b000100, 0b001000,  # ䷌ ䷍ ䷎ ䷏
    0b011001, 0b100110, 0b000011, 0b110000,  # ䷐ ䷑ ䷒ ䷓
    0b101001, 0b100101, 0b100000, 0b000001,  # ䷔ ䷕ ䷖ ䷗
    0b111001, 0b100111, 0b100001, 0b011110,  # ䷘ ䷙ ䷚ ䷛
    0b010010, 0b101101, 0b011100, 0b001110,  # ䷜ ䷝ ䷞ ䷟
    0b111100, 0b001111, 0b101000, 0b000101,  # ䷠ ䷡ ䷢ ䷣
    0b110101, 0b101011, 0b010100, 0b001010,  # ䷤ ䷥ ䷦ ䷧
    0b100011, 0b110001, 0b011111, 0b111110,  # ䷨ ䷩ ䷪ ䷫
    0b011000, 0b000110, 0b011010, 0b010110,  # ䷬ ䷭ ䷮ ䷯
    0b011101, 0b101110, 0b001001, 0b100100,  # ䷰ ䷱ ䷲ ䷳
    0b110100, 0b001011, 0b001101, 0b101100,  # ䷴ ䷵ ䷶ ䷷
    0b110110, 0b011011, 0b110010, 0b010011,  # ䷸ ䷹ ䷺ ䷻
    0b110011, 0b001100, 0b010101, 0b101010,  # ䷼ ䷽ ䷾ ䷿
]

# English names in King Wen order (Wilhelm/Baynes translation)
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

# The 8 trigrams (3-bit components), keyed by their binary value.
# Each hexagram is composed of an upper trigram (bits 3–5) and a lower trigram (bits 0–2).
trigram_names = {
    0b111: ("☰", "Qian",  "Heaven"),
    0b000: ("☷", "Kun",   "Earth"),
    0b001: ("☳", "Zhen",  "Thunder"),
    0b010: ("☵", "Kan",   "Water"),
    0b011: ("☶", "Gen",   "Mountain"),
    0b100: ("☴", "Xun",   "Wind"),
    0b101: ("☲", "Li",    "Fire"),
    0b110: ("☱", "Dui",   "Lake"),
}

# Spark line characters for visualizing difference values 0–6
SPARK = " ▁▂▃▅▆█"

# ANSI color codes
COLOR_RESET = "\033[0m"
COLOR_YANG = "\033[91m"   # red for solid/yang lines
COLOR_YIN = "\033[94m"    # blue for broken/yin lines
COLOR_REVERSE = "\033[92m"  # green for reverse pairs
COLOR_INVERSE = "\033[93m"  # yellow for inverse pairs
COLOR_BOLD = "\033[1m"
COLOR_DIM = "\033[2m"

def upper_trigram(val):
    return (val >> 3) & 0b111

def lower_trigram(val):
    return val & 0b111

# Extract the nuclear (inner) hexagram: formed by lines 2-3-4 (lower nuclear
# trigram) and lines 3-4-5 (upper nuclear trigram), where lines are numbered
# 1–6 from bottom. This gives a 6-bit value from the inner 4 lines.
def nuclear_hexagram(val):
    # Lines are bits 0–5 (bottom to top). Nuclear uses lines 2,3,4 and 3,4,5
    # (0-indexed: bits 1,2,3 and bits 2,3,4)
    lower_nuc = (val >> 1) & 0b111  # bits 1,2,3
    upper_nuc = (val >> 2) & 0b111  # bits 2,3,4
    return (upper_nuc << 3) | lower_nuc

def display_width(s):
    """Calculate terminal display width, accounting for wide Unicode characters.
    Hexagram (U+4DC0–U+4DFF) and misc symbol characters are treated as wide
    since most terminals render them at double width."""
    w = 0
    for c in s:
        cp = ord(c)
        eaw = unicodedata.east_asian_width(c)
        if eaw in ('W', 'F'):
            w += 2
        elif 0x4DC0 <= cp <= 0x4DFF:  # I Ching hexagram symbols
            w += 2
        elif 0x2600 <= cp <= 0x26FF:  # Misc symbols (includes ☰☱☲☳☴☵☶☷)
            w += 2
        else:
            w += 1
    return w

def pad(s, width):
    """Pad a string with spaces to a target display width."""
    return s + ' ' * (width - display_width(s))

def trigram_label(t):
    _, pinyin, meaning = trigram_names[t]
    return f"{pinyin} {meaning}"

# Look up the King Wen sequence position (1–64) for a given binary value
def binary_to_kw_position(val):
    for i, b in enumerate(binary_hexagrams):
        if b == val:
            return i + 1
    return None

def colorize_binary(val, use_color):
    """Render a 6-bit value as a colored binary string."""
    if not use_color:
        return bin(val)[2:].zfill(6)
    bits = bin(val)[2:].zfill(6)
    result = ""
    for ch in bits:
        if ch == '1':
            result += COLOR_YANG + ch + COLOR_RESET
        else:
            result += COLOR_YIN + ch + COLOR_RESET
    return result

# ---------------------------------------------------------------------------

def print_header():
    print("---")
    print("Received Order Analysis Engine")
    print("of the King Wen sequence including")
    print("observations by Terence McKenna")
    # https://en.wikipedia.org/wiki/Terence_McKenna#Novelty_theory_and_Timewave_Zero
    print("---")

def print_table(use_color=False):
    print("---")
    print("Hexagram reference table")
    print("Each hexagram is a stack of 6 lines, either solid (1/yang) or broken (0/yin).")
    print("The 'binary' column encodes these 6 lines as bits (bottom line = rightmost bit).")
    print("Each hexagram is also composed of two 3-line trigrams: an upper and a lower.")
    print("There are 8 possible trigrams (Heaven, Earth, Thunder, Water, Mountain, Wind,")
    print("Fire, Lake), giving 8x8 = 64 possible hexagrams.")
    print("---")
    print("Pos | Hex | Binary | Upper          | Lower          | Name")
    print("----|-----|--------|----------------|----------------|----")
    for i in range(64):
        b = binary_hexagrams[i]
        upper = upper_trigram(b)
        lower = lower_trigram(b)
        bits = colorize_binary(b, use_color) if use_color else bin(b)[2:].zfill(6)
        _, up, um = trigram_names[upper]
        _, lp, lm = trigram_names[lower]
        print(f"{i+1:02}  | {unicode_hexagrams[i]}   | {bits} | "
              f"{up:<5}{um:<9} | {lp:<5}{lm:<9} | "
              f"{hexagram_names[i]}")

def print_pairs(use_color=False):
    print("---")
    print("Reverse vs. Inverse pair analysis")
    print("The 64 hexagrams are traditionally grouped into 32 pairs (1-2, 3-4, ..., 63-64).")
    print("For each pair, we test two relationships:")
    print("  Reverse: flip the hexagram upside down (read the lines top-to-bottom instead of")
    print("           bottom-to-top). If the second hexagram upside-down equals the first,")
    print("           they are a reverse pair.")
    print("  Inverse: toggle every line (solid becomes broken, broken becomes solid).")
    print("           If toggling all lines of one hexagram gives the other, they are inverse.")
    print("Key finding: EVERY pair in the King Wen sequence is one or the other — none are")
    print("unrelated. This perfect pairing structure is unlikely to occur by chance.")
    print("---")
    reverse_count = 0
    inverse_count = 0
    neither_count = 0
    total_count = len(binary_hexagrams) // 2

    for index in range(0, 64, 2):
        print(str(index+1).zfill(2) + " ", end="")
        # Check if flipping the second hexagram upside down yields the first
        if binary_hexagrams[index] == reverse_6bit(binary_hexagrams[index+1]):
            reverse_count += 1
            print(unicode_hexagrams[index], end="")
            label = f"{COLOR_REVERSE} Reverse {COLOR_RESET}" if use_color else " Reverse "
            print(label, end="")
        # Check if toggling all lines (XOR 0b111111) of the second yields the first
        elif binary_hexagrams[index] == binary_hexagrams[index+1] ^ 0b111111:
            inverse_count += 1
            print(unicode_hexagrams[index], end="")
            label = f"{COLOR_INVERSE} Inverse {COLOR_RESET}" if use_color else " Inverse "
            print(label, end="")
        else:
            neither_count += 1
            print(unicode_hexagrams[index], end="")
            print(" IS NOT A REVERSE OR INVERSE ", end="")

        print(str(index+2).zfill(2) + " ", end="")
        print(unicode_hexagrams[index+1])

    print("---")
    print(f"Reverse count pairs: {reverse_count:02}/{total_count} ({reverse_count/total_count*100}%)")
    print(f"Inverse count pairs: {inverse_count:02}/{total_count} ({inverse_count/total_count*100}%)")
    print(f"Neither count pairs: {neither_count:02}/{total_count} ({neither_count/total_count*100}%)")

def compute_diffs(wrap=False):
    """Compute the number of line changes between consecutive hexagrams."""
    limit = 64 if wrap else 63
    diffs = []
    for i in range(limit):
        diffs.append(bit_diff(binary_hexagrams[i], binary_hexagrams[(i+1) % 64]))
    return diffs

def print_wave(order=1, wrap=False):
    print("---")
    print("First order of difference (the 'wave')")
    print("For each consecutive pair of hexagrams, count how many of the 6 lines change.")
    print("This produces a sequence of values from 0 (identical) to 6 (every line flipped).")
    print("The resulting 'wave' is central to analysis of the King Wen sequence.")
    print("Key observation (McKenna): the value 5 never appears — no consecutive hexagrams")
    print("differ by exactly 5 lines. The value 0 also never appears (no duplicates).")
    if wrap:
        print("(Including the 64->1 wrap-around transition to complete the cycle.)")
    print("---")

    diffs = compute_diffs(wrap=wrap)
    limit = len(diffs)

    # Tally of how many times each difference count (0–6) occurs
    diff_array = [0] * 7
    for i in range(limit):
        j = (i + 1) % 64
        print(f"{i+1:02} {unicode_hexagrams[i]} to {j+1:02} {unicode_hexagrams[j]} "
              f"difference {diffs[i]} {'*'*diffs[i]}")
        diff_array[diffs[i]] += 1

    print("---")
    # Summary: how often each difference count (0–6 line changes) occurs.
    # Notable findings:
    #   0 changes: 0 — no consecutive hexagrams are identical (expected)
    #   5 changes: 0 — McKenna's observation; this never occurs in the sequence,
    #                   which is statistically unlikely for a random ordering
    for n in range(7):
        print(f"{n} line changes total {diff_array[n]}")

    # Compact spark line visualization of the wave
    spark_line = "".join(SPARK[d] for d in diffs)
    print(f"\nSpark line: {spark_line}")

    # Higher orders of difference (difference of the difference)
    if order > 1:
        current = diffs
        for o in range(2, order + 1):
            current = [abs(current[i+1] - current[i]) for i in range(len(current) - 1)]
            print(f"\n--- Order {o} of difference ---")
            tally = [0] * 7
            for val in current:
                tally[val] += 1
            for n in range(7):
                if tally[n] > 0:
                    print(f"{n} changes total {tally[n]}")
            spark = "".join(SPARK[min(d, 6)] for d in current)
            print(f"Spark line: {spark}")

def print_trigrams():
    print("---")
    print("Trigram analysis")
    print("Each hexagram is built from two trigrams (3-line figures): an upper and a lower.")
    print("There are 8 possible trigrams. This section counts how often each trigram appears")
    print("in each position, checks how often the upper or lower trigram changes between")
    print("consecutive hexagrams, and shows the full 8x8 transition matrix (which trigram")
    print("follows which). A uniform distribution (8 of each) confirms that all 64 possible")
    print("upper/lower combinations are used exactly once.")
    print("---")

    # Count how often each trigram appears in upper and lower positions
    upper_counts = {}
    lower_counts = {}
    for t in trigram_names:
        upper_counts[t] = 0
        lower_counts[t] = 0

    for b in binary_hexagrams:
        upper_counts[upper_trigram(b)] += 1
        lower_counts[lower_trigram(b)] += 1

    print(f"{'Trigram':<20} Upper  Lower  Total")
    for t in sorted(trigram_names.keys()):
        _, pinyin, meaning = trigram_names[t]
        u = upper_counts[t]
        l = lower_counts[t]
        print(f"{pinyin:<5}{meaning:<14}   {u:2}     {l:2}     {u+l:2}")

    # Consecutive trigram transitions: how often does the upper (or lower)
    # trigram change between consecutive hexagrams?
    print("\n--- Consecutive trigram transitions ---")
    upper_changes = 0
    lower_changes = 0
    for i in range(63):
        if upper_trigram(binary_hexagrams[i]) != upper_trigram(binary_hexagrams[i+1]):
            upper_changes += 1
        if lower_trigram(binary_hexagrams[i]) != lower_trigram(binary_hexagrams[i+1]):
            lower_changes += 1
    print(f"Upper trigram changes: {upper_changes}/63 transitions ({upper_changes/63*100:.1f}%)")
    print(f"Lower trigram changes: {lower_changes}/63 transitions ({lower_changes/63*100:.1f}%)")

    # 8x8 trigram transition matrix: how often each upper trigram follows
    # another upper trigram in consecutive hexagrams (same for lower)
    print("\n--- Upper trigram transition matrix ---")
    print("Rows = from, Columns = to")
    trigram_order = sorted(trigram_names.keys())
    header = "          " + " ".join(f"{trigram_names[t][1]:<5}" for t in trigram_order)
    print(header)
    for t_from in trigram_order:
        row = f"{trigram_names[t_from][1]:<5}     "
        for t_to in trigram_order:
            count = 0
            for i in range(63):
                if upper_trigram(binary_hexagrams[i]) == t_from and \
                   upper_trigram(binary_hexagrams[i+1]) == t_to:
                    count += 1
            row += f"{count:<6}"
        print(row)

    print("\n--- Lower trigram transition matrix ---")
    print("Rows = from, Columns = to")
    print(header)
    for t_from in trigram_order:
        row = f"{trigram_names[t_from][1]:<5}     "
        for t_to in trigram_order:
            count = 0
            for i in range(63):
                if lower_trigram(binary_hexagrams[i]) == t_from and \
                   lower_trigram(binary_hexagrams[i+1]) == t_to:
                    count += 1
            row += f"{count:<6}"
        print(row)

def print_nuclear():
    """Nuclear hexagram analysis. Each hexagram contains an inner (nuclear)
    hexagram formed by lines 2-3-4 (lower trigram) and 3-4-5 (upper trigram).
    This traces the chain of nuclear derivation for each hexagram."""
    print("---")
    print("Nuclear hexagram analysis")
    print("Every hexagram contains a hidden 'nuclear' hexagram inside it, formed by")
    print("extracting the 4 middle lines (lines 2-3-4-5). Lines 2-3-4 form the lower")
    print("nuclear trigram, and lines 3-4-5 form the upper nuclear trigram (sharing lines")
    print("3 and 4). This creates a chain: each hexagram points to its nuclear hexagram,")
    print("which points to its own nuclear hexagram, and so on until the chain loops.")
    print("These chains reveal deep structural relationships between hexagrams that are")
    print("not obvious from the surface arrangement.")
    print("---")

    # Build a map from binary value to King Wen position
    val_to_pos = {}
    for i, b in enumerate(binary_hexagrams):
        val_to_pos[b] = i

    # Count how often each hexagram appears as a nuclear hexagram
    nuclear_counts = [0] * 64
    for i in range(64):
        nuc_val = nuclear_hexagram(binary_hexagrams[i])
        nuc_pos = val_to_pos[nuc_val]
        nuclear_counts[nuc_pos] += 1

    for i in range(64):
        b = binary_hexagrams[i]
        nuc_val = nuclear_hexagram(b)
        nuc_pos = val_to_pos[nuc_val]
        # Trace the nuclear chain until it reaches a fixed point
        # Trace the nuclear chain until we hit a cycle or fixed point
        chain = [i]
        seen = {i}
        current = nuc_val
        while val_to_pos[current] not in seen:
            pos = val_to_pos[current]
            chain.append(pos)
            seen.add(pos)
            current = nuclear_hexagram(current)
        # Append the cycle-closing element to show where it loops back
        chain.append(val_to_pos[current])
        chain_str = " -> ".join(f"{c+1:02} {unicode_hexagrams[c]}" for c in chain)
        print(f"{i+1:02} {unicode_hexagrams[i]} nuclear: "
              f"{nuc_pos+1:02} {unicode_hexagrams[nuc_pos]}  chain: {chain_str}")

    print("\n--- Nuclear hexagram frequency ---")
    print("How often each hexagram appears as another's nuclear hexagram")
    targets = [(i, nuclear_counts[i]) for i in range(64) if nuclear_counts[i] > 0]
    targets.sort(key=lambda x: -x[1])
    for pos, count in targets:
        print(f"{pos+1:02} {unicode_hexagrams[pos]} {hexagram_names[pos]:<30} appears {count} times")

def print_line_changes():
    """Analyze which specific lines (positions 1–6, bottom to top) change most
    often between consecutive hexagrams in the King Wen sequence."""
    print("---")
    print("Line change positional analysis")
    print("Each hexagram has 6 lines (positions 1-6, bottom to top). When consecutive")
    print("hexagrams differ, which specific lines are changing? If the King Wen sequence")
    print("were random, each line position would change about 50% of the time. Significant")
    print("deviation from 50% would suggest the ordering favors changing certain positions.")
    print("The co-change matrix shows which pairs of lines tend to flip together in the")
    print("same transition — revealing correlated line movements.")
    print("---")

    # Count how often each bit position differs between consecutive hexagrams
    line_counts = [0] * 6
    for i in range(63):
        diff = binary_hexagrams[i] ^ binary_hexagrams[i+1]
        for bit in range(6):
            if diff & (1 << bit):
                line_counts[bit] += 1

    for bit in range(6):
        bar = "#" * line_counts[bit]
        print(f"Line {bit+1}: {line_counts[bit]:2}/63 ({line_counts[bit]/63*100:5.1f}%)  {bar}")

    # Which pairs of lines most often change together?
    print("\n--- Line co-change frequency ---")
    print("How often pairs of lines change together in the same transition")
    pair_counts = [[0]*6 for _ in range(6)]
    for i in range(63):
        diff = binary_hexagrams[i] ^ binary_hexagrams[i+1]
        changed = [bit for bit in range(6) if diff & (1 << bit)]
        for a in changed:
            for b in changed:
                if a < b:
                    pair_counts[a][b] += 1

    print("      ", end="")
    for b in range(6):
        print(f"L{b+1:<4}", end="")
    print()
    for a in range(6):
        print(f"L{a+1}    ", end="")
        for b in range(6):
            if a < b:
                print(f"{pair_counts[a][b]:<5}", end="")
            else:
                print(f"{'.':<5}", end="")
        print()

def print_complements():
    """Find the bitwise complement (inverse) of each hexagram and show how far
    apart each hexagram and its complement are in the King Wen sequence."""
    print("---")
    print("Complement distance analysis")
    print("Every hexagram has an 'opposite' (complement) formed by toggling all 6 lines")
    print("(solid becomes broken, broken becomes solid). For example, The Creative (all")
    print("solid) and The Receptive (all broken) are complements. This section finds where")
    print("each hexagram's complement sits in the King Wen sequence and how far apart they")
    print("are. If complements tend to be near each other, it suggests the sequence was")
    print("deliberately organized around opposition; if far apart, they may serve as")
    print("bookends for larger structural sections.")
    print("---")

    val_to_pos = {}
    for i, b in enumerate(binary_hexagrams):
        val_to_pos[b] = i

    distances = []
    for i in range(64):
        complement = binary_hexagrams[i] ^ 0b111111
        comp_pos = val_to_pos[complement]
        dist = abs(comp_pos - i)
        distances.append(dist)
        print(f"{i+1:02} {unicode_hexagrams[i]} <-> "
              f"{comp_pos+1:02} {unicode_hexagrams[comp_pos]}  "
              f"distance: {dist:2}  {hexagram_names[i]} <-> {hexagram_names[comp_pos]}")

    print(f"\n--- Complement distance statistics ---")
    print(f"Mean distance:   {sum(distances)/len(distances):.1f}")
    print(f"Median distance: {sorted(distances)[32]}")
    print(f"Min distance:    {min(distances)} (adjacent = pair is an inverse pair)")
    print(f"Max distance:    {max(distances)}")

def print_palindromes():
    """Search for palindromic subsequences in the first-order difference wave.
    Palindromes suggest intentional symmetry in the King Wen ordering."""
    print("---")
    print("Palindrome analysis of the difference wave")
    print("A palindrome reads the same forwards and backwards (like 2,4,6,4,2). Finding")
    print("palindromic runs in the difference wave suggests the King Wen sequence contains")
    print("deliberate mirror symmetry — sections where the pattern of change rises and falls")
    print("in a balanced way. Longer palindromes are less likely to occur by chance and more")
    print("likely to reflect intentional design.")
    print("---")

    diffs = compute_diffs(wrap=False)

    # Find all palindromic subsequences of length >= 3
    found = []
    for length in range(len(diffs), 2, -1):
        for start in range(len(diffs) - length + 1):
            sub = diffs[start:start+length]
            if sub == sub[::-1]:
                found.append((start, length, sub))

    if not found:
        print("No palindromic subsequences of length >= 3 found.")
        return

    # Show the longest palindromes (up to 20)
    found.sort(key=lambda x: -x[1])
    shown = 0
    max_show = 20
    print(f"Found {len(found)} palindromic subsequences (showing longest {max_show})")
    print()
    for start, length, sub in found[:max_show]:
        positions = f"{start+1:02}-{start+length:02}"
        spark = "".join(SPARK[d] for d in sub)
        values = ",".join(str(d) for d in sub)
        print(f"Length {length:2} at positions {positions}: [{values}] {spark}")
        shown += 1

    # Statistical context: how many palindromes would a random sequence have?
    print(f"\n--- Palindrome count by length ---")
    by_length = {}
    for _, length, _ in found:
        by_length[length] = by_length.get(length, 0) + 1
    for length in sorted(by_length.keys(), reverse=True):
        print(f"Length {length:2}: {by_length[length]} found")

def print_canons():
    """Compare the Upper Canon (hexagrams 1–30) and Lower Canon (31–64),
    the traditional division of the I Ching."""
    print("---")
    print("Upper Canon (1-30) vs. Lower Canon (31-64) comparison")
    print("The I Ching is traditionally divided into two books: the Upper Canon (hexagrams")
    print("1-30) and Lower Canon (hexagrams 31-64). This division is ancient and may reflect")
    print("different authorship, time periods, or thematic groupings. This section compares")
    print("the mathematical properties of each half: do they have similar difference wave")
    print("patterns? Similar yin/yang balance? Does the 'no 5-line transition' property hold")
    print("in each half independently, or only in the whole?")
    print("---")

    upper = binary_hexagrams[:30]
    lower = binary_hexagrams[30:]

    def analyze_section(hexes, start_idx):
        """Compute statistics for a section of the sequence."""
        diffs = []
        for i in range(len(hexes) - 1):
            diffs.append(bit_diff(hexes[i], hexes[i+1]))
        tally = [0] * 7
        for d in diffs:
            tally[d] += 1

        yang_total = sum(bin(h).count("1") for h in hexes)
        yin_total = len(hexes) * 6 - yang_total

        return {
            "diffs": diffs,
            "tally": tally,
            "mean_diff": sum(diffs) / len(diffs) if diffs else 0,
            "yang_lines": yang_total,
            "yin_lines": yin_total,
        }

    upper_stats = analyze_section(upper, 0)
    lower_stats = analyze_section(lower, 30)

    print(f"{'Metric':<30} {'Upper (1-30)':>12} {'Lower (31-64)':>14}")
    print(f"{'-'*30} {'-'*12} {'-'*14}")
    print(f"{'Hexagrams':<30} {'30':>12} {'34':>14}")
    print(f"{'Transitions':<30} {'29':>12} {'33':>14}")
    print(f"{'Mean line changes':<30} {upper_stats['mean_diff']:>12.2f} {lower_stats['mean_diff']:>14.2f}")
    print(f"{'Yang lines (total)':<30} {upper_stats['yang_lines']:>12} {lower_stats['yang_lines']:>14}")
    print(f"{'Yin lines (total)':<30} {upper_stats['yin_lines']:>12} {lower_stats['yin_lines']:>14}")

    print(f"\n{'Difference distribution:':<30} {'Upper (1-30)':>12} {'Lower (31-64)':>14}")
    for n in range(7):
        print(f"{n} line changes{'':>17} {upper_stats['tally'][n]:>12} {lower_stats['tally'][n]:>14}")

    spark_upper = "".join(SPARK[d] for d in upper_stats["diffs"])
    spark_lower = "".join(SPARK[d] for d in lower_stats["diffs"])
    print(f"\nUpper Canon wave: {spark_upper}")
    print(f"Lower Canon wave: {spark_lower}")

    # Check for the no-5-changes property in each canon
    print(f"\n5-line transitions in Upper Canon: {upper_stats['tally'][5]}")
    print(f"5-line transitions in Lower Canon: {lower_stats['tally'][5]}")

def print_hamming():
    """Print the full 64x64 Hamming distance matrix between all hexagram pairs."""
    print("---")
    print("Hamming distance matrix (64x64)")
    print("The Hamming distance between two hexagrams is the number of lines that differ")
    print("between them (0 = identical, 6 = every line is opposite). This matrix shows the")
    print("distance between every possible pair of the 64 hexagrams. It is a property of")
    print("the hexagrams themselves, not their ordering — but it provides context for how")
    print("'close' or 'far' the King Wen sequence's consecutive pairs actually are.")
    print("---")

    # Build the matrix
    matrix = []
    for i in range(64):
        row = []
        for j in range(64):
            row.append(bit_diff(binary_hexagrams[i], binary_hexagrams[j]))
        matrix.append(row)

    # Print column headers
    print("    ", end="")
    for j in range(64):
        print(f"{j+1:02} ", end="")
    print()

    for i in range(64):
        print(f"{i+1:02}  ", end="")
        for j in range(64):
            print(f" {matrix[i][j]} ", end="")
        print()

    # Summary statistics
    all_dists = []
    for i in range(64):
        for j in range(i+1, 64):
            all_dists.append(matrix[i][j])

    print(f"\n--- Hamming distance statistics (all {len(all_dists)} unique pairs) ---")
    dist_counts = [0] * 7
    for d in all_dists:
        dist_counts[d] += 1
    for n in range(7):
        pct = dist_counts[n] / len(all_dists) * 100
        print(f"Distance {n}: {dist_counts[n]:4} pairs ({pct:5.1f}%)")
    print(f"Mean distance: {sum(all_dists)/len(all_dists):.2f}")

def print_autocorrelation():
    """Compute the autocorrelation of the first-order difference wave.
    Peaks in the autocorrelation reveal hidden periodicity in the sequence."""
    print("---")
    print("Autocorrelation of the difference wave")
    print("Autocorrelation measures whether the wave is correlated with a shifted copy of")
    print("itself. A peak at lag N means the pattern tends to repeat every N steps. A value")
    print("near +1 means strong repetition, near -1 means strong alternation, and near 0")
    print("means no relationship. If the King Wen ordering contains hidden periodic")
    print("structure, it will show up as peaks in this analysis.")
    print("---")

    diffs = compute_diffs(wrap=False)
    n = len(diffs)
    mean = sum(diffs) / n
    variance = sum((d - mean) ** 2 for d in diffs) / n

    if variance == 0:
        print("Variance is zero — cannot compute autocorrelation.")
        return

    # Compute normalized autocorrelation for lags 0 to n//2
    print(f"Mean difference: {mean:.3f}")
    print(f"Variance: {variance:.3f}")
    print()
    print(f"{'Lag':<5} {'Autocorrelation':>16} {'':>2} Visualization")
    print(f"{'---':<5} {'---------------':>16} {'':>2} -------------")

    for lag in range(n // 2 + 1):
        autocorr = 0
        for i in range(n - lag):
            autocorr += (diffs[i] - mean) * (diffs[i + lag] - mean)
        autocorr /= (n * variance)

        # Visual bar: map -1..1 to a bar display
        bar_width = 30
        bar_center = bar_width // 2
        bar_pos = int(autocorr * bar_center) + bar_center
        bar = [' '] * bar_width
        bar[bar_center] = '|'
        if bar_pos != bar_center:
            marker_pos = max(0, min(bar_width - 1, bar_pos))
            bar[marker_pos] = '#'
        bar_str = ''.join(bar)

        print(f"{lag:<5} {autocorr:>16.4f}   [{bar_str}]")

def print_entropy():
    """Compare the Shannon entropy of the King Wen difference wave against
    random permutations to quantify how ordered/disordered the sequence is."""
    print("---")
    print("Shannon entropy analysis")
    print("Entropy measures disorder: high entropy means the difference values are spread")
    print("evenly across all possibilities (random-looking), low entropy means certain values")
    print("dominate (structured). We compare the King Wen wave's entropy against thousands")
    print("of random permutations of the same 64 hexagrams. If King Wen's entropy is")
    print("unusually low, the sequence is more structured than random chance would produce.")
    print("---")

    diffs = compute_diffs(wrap=False)
    n = len(diffs)

    def shannon_entropy(values):
        """Compute Shannon entropy in bits."""
        counts = {}
        for v in values:
            counts[v] = counts.get(v, 0) + 1
        total = len(values)
        entropy = 0
        for count in counts.values():
            if count > 0:
                p = count / total
                entropy -= p * math.log2(p)
        return entropy

    kw_entropy = shannon_entropy(diffs)
    max_entropy = math.log2(7)  # 7 possible values (0–6)

    # Compare against random permutations
    trials = 10000
    random_entropies = []
    values = list(binary_hexagrams)
    for _ in range(trials):
        random.shuffle(values)
        rand_diffs = [bit_diff(values[i], values[i+1]) for i in range(63)]
        random_entropies.append(shannon_entropy(rand_diffs))

    mean_random = sum(random_entropies) / len(random_entropies)
    random_entropies.sort()

    # What percentile is the King Wen entropy?
    below = sum(1 for e in random_entropies if e < kw_entropy)
    percentile = below / len(random_entropies) * 100

    print(f"King Wen difference wave entropy: {kw_entropy:.4f} bits")
    print(f"Maximum possible entropy (uniform): {max_entropy:.4f} bits")
    print(f"Mean entropy of random permutations: {mean_random:.4f} bits")
    print(f"Min random entropy observed: {random_entropies[0]:.4f} bits")
    print(f"Max random entropy observed: {random_entropies[-1]:.4f} bits")
    print(f"King Wen percentile: {percentile:.1f}% (lower = more structured)")

    # Distribution of difference values vs. random expectation
    print(f"\n--- Distribution comparison ---")
    kw_tally = [0] * 7
    for d in diffs:
        kw_tally[d] += 1
    print(f"{'Value':<7} {'King Wen':>9} {'Expected (random avg)':>21}")
    # Compute average tally from random trials
    avg_tally = [0.0] * 7
    for _ in range(1000):
        random.shuffle(values)
        for i in range(63):
            avg_tally[bit_diff(values[i], values[i+1])] += 1
    avg_tally = [t / 1000 for t in avg_tally]
    for n in range(7):
        print(f"  {n}     {kw_tally[n]:>9}       {avg_tally[n]:>14.1f}")

def print_path():
    """Analyze the King Wen sequence as a path through a graph where nodes are
    hexagrams and edge weights are Hamming distances. Compare its total path
    length against random orderings and a greedy nearest-neighbor heuristic."""
    print("---")
    print("Path analysis (graph theory)")
    print("Imagine the 64 hexagrams as cities on a map, where the 'distance' between any")
    print("two is the number of lines that differ. The King Wen sequence is a route that")
    print("visits all 64 cities. Is it a short, efficient route (nearby hexagrams placed")
    print("next to each other), or a long, wandering one? We compare its total distance")
    print("against random routes and a greedy 'always go to the nearest unvisited city'")
    print("algorithm. This reveals whether the King Wen ordering was optimized for smooth")
    print("transitions or had other priorities.")
    print("---")

    diffs = compute_diffs(wrap=False)
    kw_total = sum(diffs)

    # Compare against random permutations
    trials = 10000
    random_totals = []
    indices = list(range(64))
    for _ in range(trials):
        random.shuffle(indices)
        total = sum(bit_diff(binary_hexagrams[indices[i]],
                             binary_hexagrams[indices[i+1]]) for i in range(63))
        random_totals.append(total)

    mean_random = sum(random_totals) / len(random_totals)
    random_totals.sort()
    below = sum(1 for t in random_totals if t < kw_total)
    percentile = below / len(random_totals) * 100

    # Greedy nearest-neighbor heuristic: always go to the closest unvisited hexagram
    visited = [False] * 64
    greedy_path = [0]  # Start at hexagram 1
    visited[0] = True
    greedy_total = 0
    for _ in range(63):
        current = greedy_path[-1]
        best_dist = 7
        best_next = -1
        for j in range(64):
            if not visited[j]:
                d = bit_diff(binary_hexagrams[current], binary_hexagrams[j])
                if d < best_dist:
                    best_dist = d
                    best_next = j
        greedy_path.append(best_next)
        visited[best_next] = True
        greedy_total += best_dist

    print(f"King Wen total path length:  {kw_total} (sum of all line changes)")
    print(f"Greedy nearest-neighbor:     {greedy_total}")
    print(f"Mean random path length:     {mean_random:.1f}")
    print(f"Min random observed:         {min(random_totals)}")
    print(f"Max random observed:         {max(random_totals)}")
    print(f"King Wen percentile:         {percentile:.1f}% (lower = shorter path)")

    # Theoretical bounds
    print(f"\n--- Theoretical bounds ---")
    print(f"Minimum possible (63 transitions of 1): 63")
    print(f"Maximum possible (63 transitions of 6): 378")
    print(f"King Wen uses {kw_total/378*100:.1f}% of maximum path length")

def print_stats(trials=100000):
    print("---")
    print(f"Monte Carlo analysis ({trials:,} random permutations)")
    print("The King Wen sequence has a striking property: no two consecutive hexagrams")
    print("differ by exactly 5 lines. With 6 lines per hexagram and 7 possible difference")
    print("values (0-6), is avoiding 5 remarkable or just a coincidence? To find out, we")
    print("randomly shuffle the 64 hexagrams thousands of times and check how often a")
    print("random ordering also avoids 5-line transitions. The rarer it is, the more")
    print("likely the King Wen sequence was intentionally designed with this constraint.")
    print("---")

    # Shuffle the 64 binary hexagram values and check whether any consecutive
    # pair differs by exactly 5 lines. Count how many random orderings share
    # the King Wen property of having zero 5-line transitions.
    values = list(binary_hexagrams)
    no_five_count = 0
    for _ in range(trials):
        random.shuffle(values)
        has_five = False
        for i in range(63):
            if bit_diff(values[i], values[i+1]) == 5:
                has_five = True
                break
        if not has_five:
            no_five_count += 1

    pct = no_five_count / trials * 100
    print(f"Permutations with no 5-line transitions: {no_five_count:,}/{trials:,} ({pct:.2f}%)")
    if no_five_count == 0:
        print("None observed — the King Wen property is extremely rare.")
    else:
        print(f"Approximately 1 in {trials // no_five_count} random orderings share this property.")

def print_graphviz():
    """Output a Graphviz DOT representation of the King Wen sequence as a
    directed graph, with edge weights showing the Hamming distance."""
    print("// King Wen sequence as a Graphviz directed graph")
    print("// Save as kw.dot and render with: dot -Tpng kw.dot -o kw.png")
    print("digraph KingWen {")
    print("    rankdir=LR;")
    print("    node [shape=circle, fontsize=10];")
    print("    edge [fontsize=8];")
    print()
    for i in range(64):
        bits = bin(binary_hexagrams[i])[2:].zfill(6)
        label = f"{i+1}\\n{unicode_hexagrams[i]}\\n{bits}"
        print(f'    h{i+1} [label="{label}"];')
    print()
    for i in range(63):
        d = bit_diff(binary_hexagrams[i], binary_hexagrams[i+1])
        print(f'    h{i+1} -> h{i+2} [label="{d}"];')
    print("}")

def export_json():
    """Export all hexagram data as JSON for use in other tools."""
    data = {
        "description": "King Wen sequence hexagram data",
        "source": "https://en.wikipedia.org/wiki/King_Wen_sequence",
        "hexagrams": []
    }
    for i in range(64):
        b = binary_hexagrams[i]
        data["hexagrams"].append({
            "position": i + 1,
            "unicode": unicode_hexagrams[i],
            "binary": bin(b)[2:].zfill(6),
            "decimal": b,
            "name": hexagram_names[i],
            "upper_trigram": {
                "pinyin": trigram_names[upper_trigram(b)][1],
                "meaning": trigram_names[upper_trigram(b)][2],
            },
            "lower_trigram": {
                "pinyin": trigram_names[lower_trigram(b)][1],
                "meaning": trigram_names[lower_trigram(b)][2],
            },
            "nuclear_position": binary_to_kw_position(nuclear_hexagram(b)),
        })

    diffs = compute_diffs(wrap=False)
    data["transitions"] = [
        {"from": i+1, "to": i+2, "line_changes": diffs[i]}
        for i in range(63)
    ]

    print(json.dumps(data, indent=2, ensure_ascii=False))

def export_csv():
    """Export hexagram data as CSV."""
    print("position,unicode,binary,decimal,name,upper_pinyin,upper_meaning,"
          "lower_pinyin,lower_meaning,nuclear_position")
    for i in range(64):
        b = binary_hexagrams[i]
        bits = bin(b)[2:].zfill(6)
        _, up, um = trigram_names[upper_trigram(b)]
        _, lp, lm = trigram_names[lower_trigram(b)]
        nuc_pos = binary_to_kw_position(nuclear_hexagram(b))
        name = hexagram_names[i].replace(",", ";")  # escape commas in names
        print(f"{i+1},{unicode_hexagrams[i]},{bits},{b},{name},{up},{um},{lp},{lm},{nuc_pos}")

def main():
    parser = argparse.ArgumentParser(
        description="Received Order Analysis Engine of the King Wen sequence")

    # Section selection
    parser.add_argument("--table", action="store_true",
                        help="Print hexagram table with trigrams and names")
    parser.add_argument("--pairs", action="store_true",
                        help="Print reverse/inverse pair classification")
    parser.add_argument("--wave", action="store_true",
                        help="Print difference wave between consecutive hexagrams")
    parser.add_argument("--trigrams", action="store_true",
                        help="Print trigram frequency, transition, and matrix analysis")
    parser.add_argument("--nuclear", action="store_true",
                        help="Print nuclear hexagram derivation chains")
    parser.add_argument("--lines", action="store_true",
                        help="Print line change positional analysis")
    parser.add_argument("--complements", action="store_true",
                        help="Print complement distance analysis")
    parser.add_argument("--palindromes", action="store_true",
                        help="Search for palindromes in the difference wave")
    parser.add_argument("--canons", action="store_true",
                        help="Compare Upper Canon (1-30) vs Lower Canon (31-64)")
    parser.add_argument("--hamming", action="store_true",
                        help="Print 64x64 Hamming distance matrix")
    parser.add_argument("--autocorrelation", action="store_true",
                        help="Compute autocorrelation of the difference wave")
    parser.add_argument("--entropy", action="store_true",
                        help="Shannon entropy analysis vs random permutations")
    parser.add_argument("--path", action="store_true",
                        help="Graph theory path analysis vs greedy and random")
    parser.add_argument("--stats", action="store_true",
                        help="Run Monte Carlo statistical comparison")
    parser.add_argument("--all", action="store_true",
                        help="Run all analysis sections (default if no flags given)")

    # Modifiers
    parser.add_argument("--wrap", action="store_true",
                        help="Include 64->1 wrap-around transition in wave")
    parser.add_argument("--order", type=int, default=1,
                        help="Compute Nth order of difference (default: 1)")
    parser.add_argument("--trials", type=int, default=100000,
                        help="Number of Monte Carlo trials (default: 100000)")
    parser.add_argument("--no-color", action="store_true",
                        help="Disable ANSI color output")

    # Export formats
    parser.add_argument("--json", action="store_true",
                        help="Export all hexagram data as JSON")
    parser.add_argument("--csv", action="store_true",
                        help="Export hexagram data as CSV")
    parser.add_argument("--dot", action="store_true",
                        help="Export sequence as Graphviz DOT graph")

    args = parser.parse_args()

    # Export modes bypass the normal output
    if args.json:
        export_json()
        return
    if args.csv:
        export_csv()
        return
    if args.dot:
        print_graphviz()
        return

    all_sections = [args.table, args.pairs, args.wave, args.trigrams,
                    args.nuclear, args.lines, args.complements, args.palindromes,
                    args.canons, args.hamming, args.autocorrelation, args.entropy,
                    args.path, args.stats]
    run_all = args.all or not any(all_sections)

    print_header()
    use_color = not args.no_color and sys.stdout.isatty()
    if run_all or args.table:          print_table(use_color=use_color)
    if run_all or args.pairs:          print_pairs(use_color=use_color)
    if run_all or args.wave:           print_wave(order=args.order, wrap=args.wrap)
    if run_all or args.trigrams:       print_trigrams()
    if run_all or args.nuclear:        print_nuclear()
    if run_all or args.lines:          print_line_changes()
    if run_all or args.complements:    print_complements()
    if run_all or args.palindromes:    print_palindromes()
    if run_all or args.canons:         print_canons()
    if run_all or args.hamming:        print_hamming()
    if run_all or args.autocorrelation: print_autocorrelation()
    if run_all or args.entropy:        print_entropy()
    if run_all or args.path:           print_path()
    if run_all or args.stats:          print_stats(trials=args.trials)

if __name__ == "__main__":
    main()
