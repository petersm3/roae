#!/usr/bin/env python3
# Developed with AI assistance (Claude, Anthropic)
import argparse
import cmath
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
# https://press.princeton.edu/books/hardcover/9780691097503/the-i-ching-or-book-of-changes
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
# https://en.wikipedia.org/wiki/Bagua
trigram_names = {
    0b111: ("☰", "Qian",  "Heaven"),
    0b000: ("☷", "Kun",   "Earth"),
    0b001: ("☳", "Zhen",  "Thunder"),
    0b010: ("☵", "Kan",   "Water"),
    0b011: ("☱", "Dui",   "Lake"),
    0b100: ("☶", "Gen",   "Mountain"),
    0b101: ("☲", "Li",    "Fire"),
    0b110: ("☴", "Xun",   "Wind"),
}

# Fu Xi (binary/natural) ordering: hexagrams ordered by their binary value 0–63.
# This is the "mathematical" ordering, unlike King Wen which is the traditional one.
# https://en.wikipedia.org/wiki/King_Wen_sequence#Fu_Xi_sequence
fuxi_order = list(range(64))  # Binary values 0–63 in natural order

# Mawangdui ordering: an alternative ancient sequence found on silk manuscripts
# in the Mawangdui tomb (168 BCE). Upper trigrams cycle through Qian, Gen, Kan,
# Zhen, Kun, Dui, Li, Xun, with each lower trigram cycling within.
# Represented as King Wen index (0-based) for each position.
# https://en.wikipedia.org/wiki/Mawangdui_Silk_Texts
mawangdui_kw_indices = [
     0, 43, 12, 24, 11,  9,  5, 32,  # Qian upper
    42, 27, 48, 16, 44, 57, 46, 30,  # Gen upper
     4, 47, 62,  2,  7, 59, 28, 38,  # Kan upper
    33, 31, 54, 50, 15, 53, 39, 61,  # Zhen upper
    10, 45, 35, 23,  1, 18,  6, 14,  # Kun upper
     8, 56, 36, 41, 19, 60, 58, 52,  # Dui upper
    13, 49, 29, 20, 34, 37, 63, 55,  # Li upper
    25, 17, 21, 26, 22, 40,  3, 51,  # Xun upper
]

# Module-level lookup: binary value -> King Wen 0-based index
VAL_TO_POS = {}

# Spark line characters for visualizing difference values 0–6
SPARK = " ▁▂▃▅▆█"

# Build the value-to-position lookup
for _i, _b in enumerate(binary_hexagrams):
    VAL_TO_POS[_b] = _i

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
# https://en.wikipedia.org/wiki/Hexagram_(I_Ching)
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

def progress_bar(current, total, label="", width=30):
    """Print an in-place progress bar to stderr."""
    pct = current / total
    filled = int(width * pct)
    bar = "#" * filled + "-" * (width - filled)
    display = f"\r  {label + ': ' if label else ''}[{bar}] {pct*100:5.1f}%"
    sys.stderr.write(display)
    sys.stderr.flush()
    if current >= total:
        sys.stderr.write("\n")
        sys.stderr.flush()

# Look up the King Wen sequence position (1–64) for a given binary value
def binary_to_kw_position(val):
    pos = VAL_TO_POS.get(val)
    return pos + 1 if pos is not None else None

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
    print("Key observation (McKenna, The Invisible Landscape, 1975): the value 5 never appears — no consecutive hexagrams")
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
    #   5 changes: 0 — McKenna's observation (The Invisible Landscape, 1975); this never occurs in the sequence,
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
    # Count how often each hexagram appears as a nuclear hexagram
    nuclear_counts = [0] * 64
    for i in range(64):
        nuc_val = nuclear_hexagram(binary_hexagrams[i])
        nuc_pos = VAL_TO_POS[nuc_val]
        nuclear_counts[nuc_pos] += 1

    for i in range(64):
        b = binary_hexagrams[i]
        nuc_val = nuclear_hexagram(b)
        nuc_pos = VAL_TO_POS[nuc_val]
        # Trace the nuclear chain until it reaches a fixed point
        # Trace the nuclear chain until we hit a cycle or fixed point
        chain = [i]
        seen = {i}
        current = nuc_val
        while VAL_TO_POS[current] not in seen:
            pos = VAL_TO_POS[current]
            chain.append(pos)
            seen.add(pos)
            current = nuclear_hexagram(current)
        # Append the cycle-closing element to show where it loops back
        chain.append(VAL_TO_POS[current])
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


    distances = []
    for i in range(64):
        complement = binary_hexagrams[i] ^ 0b111111
        comp_pos = VAL_TO_POS[complement]
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
    print("Caveat: with only N=63 data points, the 95% noise threshold is +/-0.25.")
    print("Values within that band are indistinguishable from random noise.")
    print("---")

    diffs = compute_diffs(wrap=False)
    n = len(diffs)
    mean = sum(diffs) / n
    variance = sum((d - mean) ** 2 for d in diffs) / n

    if variance == 0:
        print("Variance is zero — cannot compute autocorrelation.")
        return

    # 95% confidence band for white noise: +/- 1.96/sqrt(N)
    noise_threshold = 1.96 / math.sqrt(n)

    # Compute normalized autocorrelation for lags 0 to n//2
    print(f"Mean difference: {mean:.3f}")
    print(f"Variance: {variance:.3f}")
    print(f"95% noise threshold: +/-{noise_threshold:.3f} (values inside this are not significant)")
    print()
    print(f"{'Lag':<5} {'Autocorrelation':>16} {'Sig?':>5}  Visualization")
    print(f"{'---':<5} {'---------------':>16} {'----':>5}  -------------")

    significant_count = 0
    for lag in range(n // 2 + 1):
        autocorr = 0
        for i in range(n - lag):
            autocorr += (diffs[i] - mean) * (diffs[i + lag] - mean)
        autocorr /= (n * variance)

        sig = "*" if abs(autocorr) > noise_threshold and lag > 0 else ""
        if sig:
            significant_count += 1

        # Visual bar: map -1..1 to a bar display
        bar_width = 30
        bar_center = bar_width // 2
        bar_pos = int(autocorr * bar_center) + bar_center
        bar = [' '] * bar_width
        bar[bar_center] = '|'
        # Mark noise threshold
        thresh_pos_r = int(noise_threshold * bar_center) + bar_center
        thresh_pos_l = int(-noise_threshold * bar_center) + bar_center
        bar[max(0, min(bar_width-1, thresh_pos_r))] = ':'
        bar[max(0, min(bar_width-1, thresh_pos_l))] = ':'
        if bar_pos != bar_center:
            marker_pos = max(0, min(bar_width - 1, bar_pos))
            bar[marker_pos] = '#'
        bar_str = ''.join(bar)

        print(f"{lag:<5} {autocorr:>16.4f} {sig:>5}  [{bar_str}]")

    print(f"\nSignificant lags (outside noise band): {significant_count}/{n//2}")
    if significant_count == 0:
        print("No significant autocorrelation detected — consistent with no hidden periodicity,")
        print("but note that N=63 provides limited statistical power to detect weak periodicity.")

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

    # Pair-constrained comparison: the right null model
    # Generate random orderings that preserve the pair structure (pairs stay adjacent)
    print(f"\n--- Pair-constrained comparison ---")
    print("The above compares against fully random orderings. A fairer comparison is")
    print("against random orderings that also preserve the pair structure (each pair")
    print("of hexagrams stays adjacent). This is the right null model for asking")
    print("whether King Wen's path length is unusual GIVEN its pair constraint.")

    pair_trials = 5000
    pair_totals = []
    pairs = [(2*i, 2*i+1) for i in range(32)]
    for _ in range(pair_trials):
        # Shuffle the 32 pairs, then optionally flip each pair
        random.shuffle(pairs)
        ordering = []
        for a, b in pairs:
            if random.random() < 0.5:
                ordering.extend([a, b])
            else:
                ordering.extend([b, a])
        total = sum(bit_diff(binary_hexagrams[ordering[i]],
                             binary_hexagrams[ordering[i+1]]) for i in range(63))
        pair_totals.append(total)

    mean_pair = sum(pair_totals) / len(pair_totals)
    pair_totals.sort()
    below_pair = sum(1 for t in pair_totals if t < kw_total)
    pair_pct = below_pair / len(pair_totals) * 100

    print(f"Mean pair-constrained path length: {mean_pair:.1f}")
    print(f"Min pair-constrained observed:     {min(pair_totals)}")
    print(f"Max pair-constrained observed:     {max(pair_totals)}")
    print(f"King Wen percentile (pair-constrained): {pair_pct:.1f}%")

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
    step = max(1, trials // 40)
    for t in range(trials):
        if t % step == 0:
            progress_bar(t, trials, "Shuffling")
        random.shuffle(values)
        has_five = False
        for i in range(63):
            if bit_diff(values[i], values[i+1]) == 5:
                has_five = True
                break
        if not has_five:
            no_five_count += 1
    progress_bar(trials, trials, "Shuffling")

    pct = no_five_count / trials * 100
    print(f"Permutations with no 5-line transitions: {no_five_count:,}/{trials:,} ({pct:.2f}%)")
    if no_five_count == 0:
        print("None observed — the King Wen property is extremely rare.")
    else:
        print(f"Approximately 1 in {trials // no_five_count} random orderings share this property.")

def print_fft():
    """Spectral analysis of the difference wave using Discrete Fourier Transform."""
    print("---")
    print("Spectral analysis (Discrete Fourier Transform)")
    print("The DFT decomposes the difference wave into frequency components, like splitting")
    print("white light into a rainbow. Each frequency represents a periodic pattern in the")
    print("wave. A strong peak at frequency F means the wave has a repeating cycle every")
    print("63/F transitions. If the King Wen ordering has hidden periodic structure, the")
    print("spectrum will show clear peaks rather than flat noise.")
    print("Caveat: with only 63 samples, each of the 31 frequency bins has wide")
    print("uncertainty. A flat spectrum may indicate no periodicity, or insufficient data.")
    print("---")

    diffs = compute_diffs(wrap=False)
    n = len(diffs)
    mean = sum(diffs) / n
    variance = sum((d - mean) ** 2 for d in diffs) / n

    # Compute DFT manually using cmath (stdlib)
    # Subtract mean to focus on oscillations, not DC offset
    centered = [d - mean for d in diffs]
    magnitudes = []
    for k in range(n // 2 + 1):
        total = complex(0, 0)
        for t in range(n):
            angle = -2 * math.pi * k * t / n
            total += centered[t] * cmath.exp(complex(0, angle))
        mag = abs(total) / n
        magnitudes.append((k, mag))

    # Expected magnitude for white noise: sqrt(variance / N)
    noise_floor = math.sqrt(variance / n)

    # DC component (frequency 0) is just the mean, skip it
    print(f"Number of samples: {n}")
    print(f"Mean (DC component): {mean:.3f}")
    print(f"White noise floor: {noise_floor:.4f} (magnitudes near this are not significant)")
    print()
    print(f"{'Freq':>4} {'Period':>8} {'Magnitude':>10} {'Sig?':>5}  Spectrum")
    print(f"{'----':>4} {'------':>8} {'---------':>10} {'----':>5}  --------")

    max_mag = max(m for _, m in magnitudes[1:]) if len(magnitudes) > 1 else 1
    sig_count = 0
    for k, mag in magnitudes[1:]:  # Skip DC
        period = n / k if k > 0 else float('inf')
        bar_len = int(mag / max_mag * 40) if max_mag > 0 else 0
        bar = "#" * bar_len
        sig = "*" if mag > 2 * noise_floor else ""
        if sig:
            sig_count += 1
        print(f"{k:>4} {period:>8.1f} {mag:>10.4f} {sig:>5}  {bar}")

    print(f"\nFrequencies above 2x noise floor: {sig_count}/{n//2}")

def print_markov():
    """Markov chain analysis of the difference wave transitions."""
    print("---")
    print("Markov chain analysis")
    print("If we treat each difference value as a 'state', we can ask: does the current")
    print("difference predict the next one? In a random sequence, knowing that the last")
    print("transition changed 2 lines tells you nothing about the next transition. But if")
    print("certain patterns like '6 is always followed by 2' emerge, it reveals hidden")
    print("rules in the King Wen ordering. The matrix shows the probability of each")
    print("transition between difference values.")
    print("---")

    diffs = compute_diffs(wrap=False)

    # Count transitions between consecutive difference values
    # Only count states that actually appear (0 and 5 don't)
    states = sorted(set(diffs))
    transition_counts = {}
    for s in states:
        transition_counts[s] = {}
        for t in states:
            transition_counts[s][t] = 0

    for i in range(len(diffs) - 1):
        transition_counts[diffs[i]][diffs[i+1]] += 1

    # Print transition probability matrix
    print("Transition probability matrix (row = from, column = to)")
    print(f"{'':>6}", end="")
    for s in states:
        print(f"  -> {s}  ", end="")
    print()

    for s_from in states:
        row_total = sum(transition_counts[s_from].values())
        print(f"  {s_from}   ", end="")
        for s_to in states:
            count = transition_counts[s_from][s_to]
            if row_total > 0:
                prob = count / row_total
                print(f" {prob:5.2f}  ", end="")
            else:
                print(f"   -   ", end="")
        print(f"  (n={row_total})")

    # Highlight notable patterns with small-N caveat
    print("\n--- Notable transition patterns ---")
    print("(Caveat: rows with small n are unreliable — patterns based on <5 observations")
    print("are anecdotes, not statistically meaningful.)")
    for s_from in states:
        row_total = sum(transition_counts[s_from].values())
        if row_total == 0:
            continue
        for s_to in states:
            count = transition_counts[s_from][s_to]
            prob = count / row_total
            if prob >= 0.4 and count >= 3:
                caveat = " [small sample]" if row_total < 5 else ""
                print(f"  {s_from} -> {s_to}: {prob:.0%} ({count}/{row_total} times){caveat}")

    # Permutation test: is the transition matrix more structured than random?
    print("\n--- Permutation test ---")
    print("Is the transition matrix more concentrated than random orderings produce?")

    def matrix_concentration(diffs_seq):
        """Sum of squared probabilities — higher = more concentrated."""
        s = sorted(set(diffs_seq))
        tc = {}
        for sv in s:
            tc[sv] = {}
            for tv in s:
                tc[sv][tv] = 0
        for i in range(len(diffs_seq) - 1):
            tc[diffs_seq[i]][diffs_seq[i+1]] += 1
        total = 0
        for sv in s:
            rt = sum(tc[sv].values())
            if rt > 0:
                for tv in s:
                    p = tc[sv][tv] / rt
                    total += p * p
        return total

    kw_conc = matrix_concentration(diffs)
    trials = 5000
    values = list(binary_hexagrams)
    more_concentrated = 0
    for _ in range(trials):
        random.shuffle(values)
        rand_diffs = [bit_diff(values[i], values[i+1]) for i in range(63)]
        if matrix_concentration(rand_diffs) >= kw_conc:
            more_concentrated += 1

    pct = more_concentrated / trials * 100
    print(f"King Wen matrix concentration: {kw_conc:.4f}")
    print(f"Random orderings equally or more concentrated: {more_concentrated}/{trials} ({pct:.1f}%)")

def print_graycode():
    """Compare the King Wen ordering against a Gray code."""
    print("---")
    print("Gray code comparison")
    print("A Gray code is an ordering of binary values where each consecutive pair differs")
    print("by exactly 1 bit. For 6-bit hexagrams, a Gray code path would change exactly 1")
    print("line at every step — the smoothest possible sequence. The King Wen sequence does")
    print("NOT follow a Gray code (most transitions change 2-6 lines). This comparison")
    print("shows how much 'rougher' King Wen is than the theoretical minimum, suggesting")
    print("the ordering prioritizes something other than smooth transitions.")
    print("---")

    # Generate standard 6-bit Gray code
    def gray_code(n_bits):
        if n_bits == 0:
            return [0]
        lower = gray_code(n_bits - 1)
        return lower + [x | (1 << (n_bits - 1)) for x in reversed(lower)]

    gray = gray_code(6)
    gray_diffs = [bit_diff(gray[i], gray[i+1]) for i in range(63)]
    kw_diffs = compute_diffs(wrap=False)

    gray_total = sum(gray_diffs)
    kw_total = sum(kw_diffs)

    print(f"{'Metric':<35} {'Gray Code':>10} {'King Wen':>10}")
    print(f"{'-'*35} {'-'*10} {'-'*10}")
    print(f"{'Total path length':<35} {gray_total:>10} {kw_total:>10}")
    print(f"{'Mean change per transition':<35} {gray_total/63:>10.2f} {kw_total/63:>10.2f}")
    print(f"{'Max single transition':<35} {max(gray_diffs):>10} {max(kw_diffs):>10}")
    print(f"{'Min single transition':<35} {min(gray_diffs):>10} {min(kw_diffs):>10}")
    print(f"{'King Wen / Gray Code ratio':<35} {'':>10} {kw_total/gray_total:>10.2f}x")

    gray_tally = [0] * 7
    kw_tally = [0] * 7
    for d in gray_diffs:
        gray_tally[d] += 1
    for d in kw_diffs:
        kw_tally[d] += 1

    print(f"\n{'Difference distribution:':<35} {'Gray Code':>10} {'King Wen':>10}")
    for n in range(7):
        if gray_tally[n] > 0 or kw_tally[n] > 0:
            print(f"  {n} line changes{'':>20} {gray_tally[n]:>10} {kw_tally[n]:>10}")

    gray_spark = "".join(SPARK[d] for d in gray_diffs)
    kw_spark = "".join(SPARK[d] for d in kw_diffs)
    print(f"\nGray code wave: {gray_spark}")
    print(f"King Wen wave:  {kw_spark}")

def print_symmetry():
    """Analyze the XOR group structure of the King Wen sequence."""
    print("---")
    print("Symmetry group analysis (XOR algebra)")
    print("The 64 hexagrams form a mathematical group under XOR: combining any two hexagrams")
    print("by toggling their differing lines always produces another valid hexagram. This is")
    print("like mixing colors — every combination is itself a color. Under this algebra,")
    print("certain sets of hexagrams form 'subgroups' (closed sets where combining any two")
    print("members stays in the set). This section checks whether the King Wen pairs, inverse")
    print("pairs, and the canonical divisions correspond to meaningful algebraic subgroups.")
    print("---")

    # Check which XOR subgroups exist among the 64 hexagrams
    # The identity element under XOR is 0b000000 (The Receptive, hexagram 2)


    print("XOR identity element: 0b000000 (hexagram 2, The Receptive)")
    print()

    # Self-inverse elements: hexagrams where XOR with themselves = identity (all of them!)
    # More interesting: which hexagrams are their own complement?
    # Under XOR, the complement is XOR with 0b111111
    print("--- Fixed points under complement (XOR 0b111111) ---")
    print("Hexagrams that are their own complement do not exist (since XOR with")
    print("0b111111 always flips all bits, no 6-bit value equals its own complement).")
    print()

    # Check the 32 King Wen pairs: do they form a quotient group?
    # Each pair {a, b} where b = reverse(a) or b = complement(a)
    print("--- King Wen pair XOR products ---")
    print("For each pair, XOR the two hexagrams to see what 'difference element' they produce.")
    print("If many pairs produce the same XOR product, the pairing has algebraic regularity.")
    print()
    xor_products = {}
    for index in range(0, 64, 2):
        product = binary_hexagrams[index] ^ binary_hexagrams[index + 1]
        product_pos = VAL_TO_POS[product]
        if product not in xor_products:
            xor_products[product] = []
        xor_products[product].append(index // 2)

    print(f"{'XOR Product':<14} {'Hexagram':>10} {'Pair count':>11}  Pairs")
    for product in sorted(xor_products.keys()):
        pos = VAL_TO_POS[product]
        pairs_str = ", ".join(f"{p*2+1}-{p*2+2}" for p in xor_products[product])
        print(f"  {bin(product)[2:].zfill(6)}   "
              f"{pos+1:02} {unicode_hexagrams[pos]}   "
              f"{len(xor_products[product]):>5}      {pairs_str}")

    print(f"\nUnique XOR products: {len(xor_products)} (out of 32 pairs)")
    print("If this number is small, the pairs share algebraic structure.")

    # Check: do the 4 inverse pairs form a subgroup under XOR?
    print("\n--- Inverse pair XOR closure test ---")
    inverse_pairs = []
    for index in range(0, 64, 2):
        if binary_hexagrams[index] == binary_hexagrams[index+1] ^ 0b111111:
            inverse_pairs.extend([binary_hexagrams[index], binary_hexagrams[index+1]])

    # Test closure: XOR of any two members should be in the set
    inverse_set = set(inverse_pairs)
    closed = True
    for a in inverse_pairs:
        for b in inverse_pairs:
            if (a ^ b) not in inverse_set:
                closed = False
                break
        if not closed:
            break
    print(f"Inverse pair hexagrams ({len(inverse_pairs)} total): ", end="")
    print(", ".join(f"{VAL_TO_POS[v]+1:02}" for v in inverse_pairs))
    print(f"Closed under XOR: {'Yes — forms a subgroup' if closed else 'No — not a subgroup'}")

def print_sequences():
    """Compare King Wen against alternative historical orderings."""
    print("---")
    print("Alternative sequence comparison")
    print("The King Wen ordering is not the only way to arrange 64 hexagrams. The Fu Xi")
    print("(binary) sequence orders them by numerical value (0-63), which is mathematically")
    print("natural but has no traditional significance. The Mawangdui sequence was found on")
    print("silk manuscripts in a 168 BCE tomb and may represent an independent tradition.")
    print("Comparing the same analyses across orderings reveals what is unique to King Wen.")
    print("---")

    def analyze_ordering(order, name):
        """Compute difference statistics for a given ordering of binary hexagram values."""
        diffs = [bit_diff(order[i], order[i+1]) for i in range(len(order) - 1)]
        tally = [0] * 7
        for d in diffs:
            tally[d] += 1
        total = sum(diffs)
        return {
            "name": name,
            "diffs": diffs,
            "tally": tally,
            "total": total,
            "mean": total / len(diffs),
            "spark": "".join(SPARK[d] for d in diffs),
        }

    # King Wen
    kw = analyze_ordering(binary_hexagrams, "King Wen")

    # Fu Xi (natural binary order)
    fuxi_values = list(range(64))
    fx = analyze_ordering(fuxi_values, "Fu Xi (binary)")

    # Mawangdui
    mw_values = [binary_hexagrams[i] for i in mawangdui_kw_indices]
    mw = analyze_ordering(mw_values, "Mawangdui")

    # Comparison table
    orderings = [kw, fx, mw]
    print(f"{'Metric':<25}", end="")
    for o in orderings:
        print(f" {o['name']:>16}", end="")
    print()
    print(f"{'-'*25}", end="")
    for _ in orderings:
        print(f" {'-'*16}", end="")
    print()

    print(f"{'Total path length':<25}", end="")
    for o in orderings:
        print(f" {o['total']:>16}", end="")
    print()

    print(f"{'Mean change':<25}", end="")
    for o in orderings:
        print(f" {o['mean']:>16.2f}", end="")
    print()

    for n in range(7):
        has_any = any(o['tally'][n] > 0 for o in orderings)
        if has_any:
            print(f"{n}-line transitions{'':>7}", end="")
            for o in orderings:
                print(f" {o['tally'][n]:>16}", end="")
            print()

    print(f"\n{'Waves:'}")
    for o in orderings:
        print(f"  {o['name']:<20} {o['spark']}")

    # Highlight what makes King Wen unique
    print(f"\n--- What makes King Wen unique ---")
    print(f"Zero 5-line transitions: King Wen={kw['tally'][5]}, "
          f"Fu Xi={fx['tally'][5]}, Mawangdui={mw['tally'][5]}")
    print(f"Zero 0-line transitions: King Wen={kw['tally'][0]}, "
          f"Fu Xi={fx['tally'][0]}, Mawangdui={mw['tally'][0]}")

def print_constraints():
    """Estimate how many orderings satisfy the known King Wen constraints."""
    print("---")
    print("Constraint satisfaction analysis")
    print("The King Wen sequence satisfies several constraints simultaneously:")
    print("  1. All 32 consecutive pairs are either reverse or inverse (never unrelated)")
    print("  2. No consecutive hexagrams differ by exactly 5 lines")
    print("  3. No consecutive hexagrams are identical (0-line transitions)")
    print("How rare is it for a random ordering to satisfy all these at once? We test")
    print("random permutations against each constraint individually and combined.")
    print("---")

    trials = 10000
    values = list(binary_hexagrams)
    count_pairs_ok = 0
    count_no_five = 0
    count_both = 0

    for _ in range(trials):
        random.shuffle(values)

        # Check pair constraint: every consecutive pair is reverse or inverse
        pairs_ok = True
        for j in range(0, 64, 2):
            is_reverse = values[j] == reverse_6bit(values[j+1])
            is_inverse = values[j] == values[j+1] ^ 0b111111
            if not is_reverse and not is_inverse:
                pairs_ok = False
                break

        # Check no-5 constraint
        no_five = True
        for j in range(63):
            if bit_diff(values[j], values[j+1]) == 5:
                no_five = False
                break

        if pairs_ok:
            count_pairs_ok += 1
        if no_five:
            count_no_five += 1
        if pairs_ok and no_five:
            count_both += 1

    print(f"Results from {trials:,} random permutations:")
    print(f"  All pairs reverse/inverse:  {count_pairs_ok:>6,} ({count_pairs_ok/trials*100:.3f}%)")
    print(f"  No 5-line transitions:      {count_no_five:>6,} ({count_no_five/trials*100:.2f}%)")
    print(f"  Both constraints together:  {count_both:>6,} ({count_both/trials*100:.4f}%)")
    if count_both == 0:
        # Report the statistical upper bound: with 0 hits in N trials,
        # the 95% CI upper bound is approximately 3/N (rule of three)
        upper_bound = 3.0 / trials * 100
        print(f"  No random permutation satisfied both constraints.")
        print(f"  Statistical note: 0/{trials:,} gives a 95% upper bound of <{upper_bound:.4f}%")
        print(f"  (i.e., the true rate is less than ~1 in {trials//3:,}, but we cannot")
        print(f"  distinguish 'impossible' from 'extremely rare' with this sample size).")
    else:
        print(f"  Approximately 1 in {trials // count_both:,} random orderings satisfy both.")

def print_barchart():
    """Print an ASCII bar chart of the difference wave."""
    print("---")
    print("Difference wave bar chart")
    print("A visual representation of the first-order difference wave. Each column shows")
    print("how many lines changed in that transition. The horizontal axis is the position")
    print("in the King Wen sequence (1-63), the vertical axis is the number of lines")
    print("changed (1-6). This makes the wave pattern easier to see than a list of numbers.")
    print("---")

    diffs = compute_diffs(wrap=False)

    # Print top-down, row by row (6 down to 1)
    for level in range(6, 0, -1):
        print(f"  {level} |", end="")
        for d in diffs:
            if d >= level:
                print("#", end="")
            else:
                print(" ", end="")
        print("|")

    # X-axis
    print(f"    +{'-'*63}+")
    # Position markers every 10
    print(f"     ", end="")
    for i in range(63):
        if (i + 1) % 10 == 0:
            print(f"{i+1:>2}"[0], end="")
        else:
            print(" ", end="")
    print()
    print(f"     ", end="")
    for i in range(63):
        if (i + 1) % 10 == 0:
            print(f"{i+1:>2}"[1], end="")
        else:
            print(" ", end="")
    print()

def print_lookup(query):
    """Look up a specific hexagram by number or name."""


    # Try to parse as number
    idx = None
    try:
        num = int(query)
        if 1 <= num <= 64:
            idx = num - 1
    except ValueError:
        pass

    # Try to match by name (case-insensitive substring)
    if idx is None:
        query_lower = query.lower()
        matches = [(i, n) for i, n in enumerate(hexagram_names)
                   if query_lower in n.lower()]
        if len(matches) == 1:
            idx = matches[0][0]
        elif len(matches) > 1:
            print(f"Multiple matches for '{query}':")
            for i, n in matches:
                print(f"  {i+1:02} {unicode_hexagrams[i]} {n}")
            return
        else:
            print(f"No hexagram found matching '{query}'.")
            return

    b = binary_hexagrams[idx]
    bits = bin(b)[2:].zfill(6)
    upper = upper_trigram(b)
    lower = lower_trigram(b)
    _, up, um = trigram_names[upper]
    _, lp, lm = trigram_names[lower]
    nuc_val = nuclear_hexagram(b)
    nuc_pos = VAL_TO_POS[nuc_val]
    comp_val = b ^ 0b111111
    comp_pos = VAL_TO_POS[comp_val]
    rev_val = reverse_6bit(b)
    rev_pos = VAL_TO_POS[rev_val]

    print(f"---")
    print(f"Hexagram {idx+1}: {unicode_hexagrams[idx]}  {hexagram_names[idx]}")
    print(f"---")
    print(f"Binary:     {bits}")
    print(f"Decimal:    {b}")
    print()

    # Draw the hexagram as lines
    print("  Lines (top to bottom):")
    for line in range(5, -1, -1):
        bit = (b >> line) & 1
        if bit:
            print(f"    --------- (yang, line {line+1})")
        else:
            print(f"    ---   --- (yin,  line {line+1})")
    print()

    print(f"  Upper trigram: {up} ({um})")
    print(f"  Lower trigram: {lp} ({lm})")
    print(f"  Nuclear:       {nuc_pos+1:02} {unicode_hexagrams[nuc_pos]} {hexagram_names[nuc_pos]}")
    print(f"  Complement:    {comp_pos+1:02} {unicode_hexagrams[comp_pos]} {hexagram_names[comp_pos]}")
    print(f"  Reverse:       {rev_pos+1:02} {unicode_hexagrams[rev_pos]} {hexagram_names[rev_pos]}")

    # Pair info
    if idx % 2 == 0:
        partner = idx + 1
    else:
        partner = idx - 1
    pb = binary_hexagrams[partner]
    if b == reverse_6bit(pb):
        rel = "Reverse"
    elif b == pb ^ 0b111111:
        rel = "Inverse"
    else:
        rel = "Neither"
    print(f"  Pair partner:  {partner+1:02} {unicode_hexagrams[partner]} "
          f"{hexagram_names[partner]} ({rel})")

    # Neighbors in sequence
    print()
    if idx > 0:
        d = bit_diff(binary_hexagrams[idx-1], b)
        print(f"  Previous: {idx:02} {unicode_hexagrams[idx-1]} "
              f"{hexagram_names[idx-1]} (diff: {d})")
    if idx < 63:
        d = bit_diff(b, binary_hexagrams[idx+1])
        print(f"  Next:     {idx+2:02} {unicode_hexagrams[idx+1]} "
              f"{hexagram_names[idx+1]} (diff: {d})")

def print_compare(a_query, b_query):
    """Compare two specific hexagrams."""


    def resolve(query):
        try:
            num = int(query)
            if 1 <= num <= 64:
                return num - 1
        except ValueError:
            pass
        query_lower = query.lower()
        matches = [i for i, n in enumerate(hexagram_names) if query_lower in n.lower()]
        if len(matches) == 1:
            return matches[0]
        return None

    idx_a = resolve(a_query)
    idx_b = resolve(b_query)

    if idx_a is None:
        print(f"Could not find hexagram: {a_query}")
        return
    if idx_b is None:
        print(f"Could not find hexagram: {b_query}")
        return

    a = binary_hexagrams[idx_a]
    b = binary_hexagrams[idx_b]
    bits_a = bin(a)[2:].zfill(6)
    bits_b = bin(b)[2:].zfill(6)

    print(f"---")
    print(f"Comparing hexagram {idx_a+1} and {idx_b+1}")
    print(f"---")
    print(f"  {idx_a+1:02} {unicode_hexagrams[idx_a]} {hexagram_names[idx_a]:<30} {bits_a}")
    print(f"  {idx_b+1:02} {unicode_hexagrams[idx_b]} {hexagram_names[idx_b]:<30} {bits_b}")
    print()

    # Hamming distance
    d = bit_diff(a, b)
    diff_bits = a ^ b
    changed = [i+1 for i in range(6) if diff_bits & (1 << i)]
    print(f"  Hamming distance: {d} line(s) differ")
    if changed:
        print(f"  Changed lines:    {', '.join(str(c) for c in changed)}")
    print()

    # Relationships
    is_reverse = a == reverse_6bit(b)
    is_inverse = a == b ^ 0b111111
    is_complement = is_inverse
    nuc_a = nuclear_hexagram(a)
    nuc_b = nuclear_hexagram(b)

    relationships = []
    if is_reverse:
        relationships.append("Reverse (one is the other flipped upside down)")
    if is_inverse:
        relationships.append("Inverse/Complement (every line toggled)")
    if nuc_a == b:
        relationships.append(f"{idx_a+1} contains {idx_b+1} as its nuclear hexagram")
    if nuc_b == a:
        relationships.append(f"{idx_b+1} contains {idx_a+1} as its nuclear hexagram")
    if nuc_a == nuc_b:
        nuc_pos = VAL_TO_POS[nuc_a]
        relationships.append(f"Share the same nuclear hexagram: "
                           f"{nuc_pos+1:02} {hexagram_names[nuc_pos]}")
    if upper_trigram(a) == upper_trigram(b):
        _, p, m = trigram_names[upper_trigram(a)]
        relationships.append(f"Share upper trigram: {p} ({m})")
    if lower_trigram(a) == lower_trigram(b):
        _, p, m = trigram_names[lower_trigram(a)]
        relationships.append(f"Share lower trigram: {p} ({m})")

    if relationships:
        print("  Relationships:")
        for r in relationships:
            print(f"    - {r}")
    else:
        print("  No direct structural relationship found.")

    # Distance in the sequence
    seq_dist = abs(idx_a - idx_b)
    print(f"\n  Distance in King Wen sequence: {seq_dist} positions apart")

def print_help_sections():
    """Print descriptions of all available sections without running them."""
    sections = [
        ("--table", "Hexagram reference table with binary encoding, trigrams, and names"),
        ("--pairs", "Reverse vs. inverse pair analysis — tests the pairing structure"),
        ("--wave", "First-order difference wave — the core 'signal' of the King Wen sequence"),
        ("--trigrams", "Trigram frequency, transitions, and 8x8 transition matrices"),
        ("--nuclear", "Nuclear hexagram chains — hidden inner hexagram derivations"),
        ("--lines", "Line change positional analysis — which lines change most often"),
        ("--complements", "Complement distance — where each hexagram's opposite sits"),
        ("--palindromes", "Palindrome search in the difference wave"),
        ("--canons", "Upper Canon (1-30) vs. Lower Canon (31-64) statistical comparison"),
        ("--hamming", "Full 64x64 Hamming distance matrix"),
        ("--autocorrelation", "Autocorrelation — tests for hidden periodicity"),
        ("--entropy", "Shannon entropy — how structured vs. random the wave is"),
        ("--path", "Graph theory path analysis — is King Wen an efficient route?"),
        ("--stats", "Monte Carlo — probability of the 'no 5-line transitions' property"),
        ("--fft", "Spectral analysis (DFT) — frequency decomposition of the wave"),
        ("--markov", "Markov chain — do difference values predict the next value?"),
        ("--graycode", "Gray code comparison — King Wen vs. theoretically smoothest path"),
        ("--symmetry", "XOR group algebra — algebraic structure of the pairing system"),
        ("--sequences", "Compare King Wen vs. Fu Xi vs. Mawangdui orderings"),
        ("--constraints", "Constraint satisfaction — how rare is King Wen's combined properties?"),
        ("--barchart", "ASCII bar chart visualization of the difference wave"),
        ("--windowed-entropy", "Sliding window entropy — where structure concentrates"),
        ("--mutual-info", "Mutual information between upper/lower trigram changes"),
        ("--bootstrap", "Bootstrap confidence intervals for Monte Carlo estimates"),
        ("--yinyang", "Yin-yang balance wave through the sequence"),
        ("--neighborhoods", "Hamming distance-1 neighborhoods for each hexagram"),
        ("--recurrence", "Recurrence plot — where the difference wave repeats"),
        ("--codons", "DNA codon mapping — structural comparison with genetics"),
        ("", ""),
        ("--lookup N", "Look up a hexagram by number (1-64) or name"),
        ("--compare A B", "Compare two hexagrams (by number or name)"),
        ("--cast", "Simulate an I Ching reading (three-coin method)"),
        ("--explain N", "Walk through transition N step by step (1-63)"),
        ("--self-test", "Run mathematical invariant checks"),
        ("", ""),
        ("--json", "Export all hexagram data as JSON"),
        ("--csv", "Export hexagram data as CSV"),
        ("--dot", "Export sequence as Graphviz DOT graph"),
        ("--svg", "Export hexagram line diagrams as SVG"),
        ("--html", "Generate self-contained HTML report with all analyses"),
        ("--midi", "Export difference wave as MIDI file (to stdout)"),
    ]
    print("---")
    print("Available analysis sections")
    print("Run with no flags for all sections, or select specific ones.")
    print("---")
    for flag, desc in sections:
        if flag:
            print(f"  {flag:<22} {desc}")
        else:
            print()

def print_self_test():
    """Run mathematical invariant checks to verify data integrity."""
    print("---")
    print("Self-test: mathematical invariant checks")
    print("---")

    passed = 0
    failed = 0

    def check(name, condition):
        nonlocal passed, failed
        status = "PASS" if condition else "FAIL"
        if condition:
            passed += 1
        else:
            failed += 1
        print(f"  [{status}] {name}")

    # Data integrity
    check("64 unicode hexagrams", len(unicode_hexagrams) == 64)
    check("64 binary hexagrams", len(binary_hexagrams) == 64)
    check("64 hexagram names", len(hexagram_names) == 64)
    check("8 trigram definitions", len(trigram_names) == 8)
    check("64 Mawangdui indices", len(mawangdui_kw_indices) == 64)

    # All binary values are valid 6-bit numbers
    check("All binary values 0-63", all(0 <= b <= 63 for b in binary_hexagrams))

    # All 64 binary values are unique (it's a permutation of some subset)
    check("All binary values unique", len(set(binary_hexagrams)) == 64)

    # All 64 possible 6-bit values are present
    check("All 64 possible values present", set(binary_hexagrams) == set(range(64)))

    # Mawangdui indices are valid
    check("Mawangdui indices valid (0-63)", all(0 <= i <= 63 for i in mawangdui_kw_indices))
    check("Mawangdui indices all unique", len(set(mawangdui_kw_indices)) == 64)

    # Pair structure: every pair is reverse or inverse
    all_pairs_ok = True
    for i in range(0, 64, 2):
        is_rev = binary_hexagrams[i] == reverse_6bit(binary_hexagrams[i+1])
        is_inv = binary_hexagrams[i] == binary_hexagrams[i+1] ^ 0b111111
        if not is_rev and not is_inv:
            all_pairs_ok = False
            break
    check("All 32 pairs are reverse or inverse", all_pairs_ok)

    # No 5-line transitions
    no_five = True
    for i in range(63):
        if bit_diff(binary_hexagrams[i], binary_hexagrams[i+1]) == 5:
            no_five = False
            break
    check("No 5-line transitions in sequence", no_five)

    # No 0-line transitions (no duplicates adjacent)
    no_zero = True
    for i in range(63):
        if binary_hexagrams[i] == binary_hexagrams[i+1]:
            no_zero = False
            break
    check("No 0-line transitions (no adjacent duplicates)", no_zero)

    # Yin-yang balance
    total_yang = sum(bin(b).count("1") for b in binary_hexagrams)
    total_yin = 64 * 6 - total_yang
    check("Perfect yin-yang balance (192 each)", total_yang == 192 and total_yin == 192)

    # Each trigram appears exactly 8 times in upper and lower positions
    upper_ok = True
    lower_ok = True
    for t in trigram_names:
        uc = sum(1 for b in binary_hexagrams if upper_trigram(b) == t)
        lc = sum(1 for b in binary_hexagrams if lower_trigram(b) == t)
        if uc != 8:
            upper_ok = False
        if lc != 8:
            lower_ok = False
    check("Each trigram appears 8 times as upper", upper_ok)
    check("Each trigram appears 8 times as lower", lower_ok)

    # VAL_TO_POS is consistent
    check("VAL_TO_POS has 64 entries", len(VAL_TO_POS) == 64)
    vtp_ok = all(binary_hexagrams[VAL_TO_POS[b]] == b for b in VAL_TO_POS)
    check("VAL_TO_POS maps correctly", vtp_ok)

    # reverse_6bit is its own inverse
    rev_ok = all(reverse_6bit(reverse_6bit(b)) == b for b in range(64))
    check("reverse_6bit is self-inverse", rev_ok)

    # XOR complement is self-inverse
    comp_ok = all((b ^ 0b111111) ^ 0b111111 == b for b in range(64))
    check("XOR complement is self-inverse", comp_ok)

    print(f"\n  {passed} passed, {failed} failed, {passed + failed} total")
    if failed == 0:
        print("  All checks passed.")
    else:
        print("  WARNING: some checks failed — data may be corrupted.")

def print_windowed_entropy():
    """Compute Shannon entropy over a sliding window of the difference wave."""
    print("---")
    print("Windowed entropy analysis")
    print("Instead of one entropy value for the whole wave, we slide a window across it")
    print("and compute entropy locally. This reveals WHERE in the sequence structure")
    print("concentrates (low entropy = predictable) vs. dissolves (high entropy = varied).")
    print("Dips in the curve mark regions with repetitive transition patterns.")
    print("---")

    diffs = compute_diffs(wrap=False)
    window = 15  # Window size

    def shannon_entropy(values):
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

    print(f"Window size: {window}")
    print(f"{'Center':>6} {'Entropy':>8} {'':>2} Visualization")
    print(f"{'------':>6} {'-------':>8} {'':>2} -------------")

    entropies = []
    for i in range(len(diffs) - window + 1):
        chunk = diffs[i:i + window]
        e = shannon_entropy(chunk)
        entropies.append(e)
        center = i + window // 2 + 1
        bar_len = int(e / math.log2(7) * 40)
        bar = "#" * bar_len
        print(f"{center:>6} {e:>8.4f}   {bar}")

    mean_e = sum(entropies) / len(entropies)
    min_e = min(entropies)
    max_e = max(entropies)
    min_pos = entropies.index(min_e) + window // 2 + 1
    max_pos = entropies.index(max_e) + window // 2 + 1

    print(f"\nMean windowed entropy: {mean_e:.4f}")
    print(f"Min entropy: {min_e:.4f} at position {min_pos} (most structured)")
    print(f"Max entropy: {max_e:.4f} at position {max_pos} (most varied)")

    spark = ""
    for e in entropies:
        level = int(e / math.log2(7) * 6)
        spark += SPARK[min(level, 6)]
    print(f"\nEntropy spark: {spark}")

def print_mutual_info():
    """Mutual information between upper and lower trigram transitions."""
    print("---")
    print("Mutual information: upper vs. lower trigram transitions")
    print("When two consecutive hexagrams differ, do the upper and lower trigrams change")
    print("independently, or is knowing that the upper trigram changed informative about")
    print("whether the lower trigram also changed? Mutual information quantifies this:")
    print("  0 bits = completely independent (knowing one tells you nothing about the other)")
    print("  higher = correlated (they tend to change together or stay together)")
    print("---")

    # For each transition, record whether upper and lower trigrams changed
    upper_changed = []
    lower_changed = []
    for i in range(63):
        uc = upper_trigram(binary_hexagrams[i]) != upper_trigram(binary_hexagrams[i+1])
        lc = lower_trigram(binary_hexagrams[i]) != lower_trigram(binary_hexagrams[i+1])
        upper_changed.append(1 if uc else 0)
        lower_changed.append(1 if lc else 0)

    n = len(upper_changed)

    # Joint and marginal probabilities
    joint = {}
    for u, l in zip(upper_changed, lower_changed):
        key = (u, l)
        joint[key] = joint.get(key, 0) + 1

    p_upper = [0, 0]
    p_lower = [0, 0]
    for u in upper_changed:
        p_upper[u] += 1
    for l in lower_changed:
        p_lower[l] += 1

    # Mutual information: I(U;L) = sum P(u,l) * log2(P(u,l) / (P(u)*P(l)))
    mi = 0
    for (u, l), count in joint.items():
        p_ul = count / n
        p_u = p_upper[u] / n
        p_l = p_lower[l] / n
        if p_ul > 0 and p_u > 0 and p_l > 0:
            mi += p_ul * math.log2(p_ul / (p_u * p_l))

    print("Joint distribution of trigram changes:")
    print(f"  {'':>20} Lower unchanged  Lower changed")
    for u_val, u_label in [(0, "Upper unchanged"), (1, "Upper changed  ")]:
        row = f"  {u_label}     "
        for l_val in [0, 1]:
            count = joint.get((u_val, l_val), 0)
            pct = count / n * 100
            row += f"    {count:2} ({pct:5.1f}%)    "
        print(row)

    print(f"\nMutual information: {mi:.4f} bits")
    # Maximum possible MI for binary variables
    max_mi = min(-sum(p/n * math.log2(p/n) for p in p_upper if p > 0),
                 -sum(p/n * math.log2(p/n) for p in p_lower if p > 0))
    if max_mi > 0:
        print(f"Normalized MI: {mi/max_mi:.4f} (0=independent, 1=perfectly correlated)")

    # Compare against random permutations
    trials = 5000
    random_mis = []
    values = list(binary_hexagrams)
    for _ in range(trials):
        random.shuffle(values)
        r_joint = {}
        for i in range(63):
            uc = 1 if upper_trigram(values[i]) != upper_trigram(values[i+1]) else 0
            lc = 1 if lower_trigram(values[i]) != lower_trigram(values[i+1]) else 0
            key = (uc, lc)
            r_joint[key] = r_joint.get(key, 0) + 1
        r_pu = [sum(1 for i in range(63) if (upper_trigram(values[i]) != upper_trigram(values[i+1])) == bool(v)) for v in [0, 1]]
        r_pl = [sum(1 for i in range(63) if (lower_trigram(values[i]) != lower_trigram(values[i+1])) == bool(v)) for v in [0, 1]]
        r_mi = 0
        for (u, l), count in r_joint.items():
            p_ul = count / 63
            p_u = r_pu[u] / 63
            p_l = r_pl[l] / 63
            if p_ul > 0 and p_u > 0 and p_l > 0:
                r_mi += p_ul * math.log2(p_ul / (p_u * p_l))
        random_mis.append(r_mi)

    mean_rmi = sum(random_mis) / len(random_mis)
    below = sum(1 for r in random_mis if r < mi)
    print(f"\nMean MI of random permutations: {mean_rmi:.4f} bits")
    print(f"King Wen percentile: {below/len(random_mis)*100:.1f}%")

    # Full 8-state MI: use actual trigram identities, not just changed/unchanged
    print(f"\n--- Full 8-state trigram mutual information ---")
    print("Using actual trigram identities (8 possible values each) rather than")
    print("binary changed/unchanged, which preserves more information.")

    # For each transition, record the (upper_from, upper_to) and (lower_from, lower_to)
    # Then compute MI between upper_to and lower_to conditioned on the transition
    upper_vals = [upper_trigram(binary_hexagrams[i]) for i in range(64)]
    lower_vals = [lower_trigram(binary_hexagrams[i]) for i in range(64)]

    # MI between upper and lower trigram of each hexagram (static)
    joint8 = {}
    for i in range(64):
        key = (upper_vals[i], lower_vals[i])
        joint8[key] = joint8.get(key, 0) + 1

    p_u8 = {}
    p_l8 = {}
    for i in range(64):
        p_u8[upper_vals[i]] = p_u8.get(upper_vals[i], 0) + 1
        p_l8[lower_vals[i]] = p_l8.get(lower_vals[i], 0) + 1

    mi8 = 0
    for (u, l), count in joint8.items():
        p_ul = count / 64
        p_u = p_u8[u] / 64
        p_l = p_l8[l] / 64
        if p_ul > 0 and p_u > 0 and p_l > 0:
            mi8 += p_ul * math.log2(p_ul / (p_u * p_l))

    # For a complete set of 64 hexagrams (all combinations), MI should be 0
    print(f"MI(upper, lower) across all 64 hexagrams: {mi8:.6f} bits")
    print("(Expected: 0.0 — since all 64 combinations appear exactly once,")
    print("the trigrams are perfectly independent in the static set.)")

def print_bootstrap(trials=100000):
    """Bootstrap confidence intervals for Monte Carlo results."""
    print("---")
    print("Bootstrap confidence intervals")
    print("The Monte Carlo results (e.g., '0.18% of random orderings avoid 5-line")
    print("transitions') are estimates based on sampling. Bootstrap resampling quantifies")
    print("how precise those estimates are by repeatedly resampling from the results and")
    print("computing confidence intervals. Narrower intervals = more reliable estimates.")
    print("---")

    # Run the base Monte Carlo
    values = list(binary_hexagrams)
    results = []  # 1 = no five, 0 = has five
    step = max(1, trials // 40)
    for t in range(trials):
        if t % step == 0:
            progress_bar(t, trials, "Sampling")
        random.shuffle(values)
        has_five = any(bit_diff(values[i], values[i+1]) == 5 for i in range(63))
        results.append(0 if has_five else 1)
    progress_bar(trials, trials, "Sampling")

    base_rate = sum(results) / len(results) * 100

    # Bootstrap: resample with replacement 1000 times
    n_bootstrap = 1000
    boot_rates = []
    boot_step = max(1, n_bootstrap // 40)
    for b in range(n_bootstrap):
        if b % boot_step == 0:
            progress_bar(b, n_bootstrap, "Resampling")
        sample = [results[random.randint(0, len(results)-1)] for _ in range(len(results))]
        boot_rates.append(sum(sample) / len(sample) * 100)
    progress_bar(n_bootstrap, n_bootstrap, "Resampling")

    boot_rates.sort()
    ci_lower = boot_rates[int(n_bootstrap * 0.025)]
    ci_upper = boot_rates[int(n_bootstrap * 0.975)]

    print(f"Base trials: {trials:,}")
    print(f"Bootstrap resamples: {n_bootstrap}")
    print(f"\nNo-5-line-transition rate: {base_rate:.3f}%")
    print(f"95% confidence interval: [{ci_lower:.3f}%, {ci_upper:.3f}%]")
    print(f"Interval width: {ci_upper - ci_lower:.3f} percentage points")

    if base_rate > 0:
        approx_ratio = 100 / base_rate
        ci_ratio_lower = 100 / ci_upper if ci_upper > 0 else float('inf')
        ci_ratio_upper = 100 / ci_lower if ci_lower > 0 else float('inf')
        print(f"\nApproximately 1 in {approx_ratio:.0f} random orderings")
        print(f"95% CI: 1 in {ci_ratio_lower:.0f} to 1 in {ci_ratio_upper:.0f}")

def print_yinyang():
    """Track the running yin-yang balance through the sequence."""
    print("---")
    print("Yin-yang balance wave")
    print("Each hexagram has 6 lines that are either yang (solid, 1) or yin (broken, 0).")
    print("Note: since the King Wen sequence contains all 64 possible hexagrams exactly")
    print("once, the total yin-yang count is necessarily balanced (192 each). This is a")
    print("mathematical tautology, not a property of the ordering. However, the LOCAL")
    print("balance as you move through the sequence IS a property of the ordering — it")
    print("shows where yang-dominant or yin-dominant hexagrams cluster together.")
    print("---")

    running_yang = []
    cumulative = 0
    for i in range(64):
        yang_count = bin(binary_hexagrams[i]).count("1")
        cumulative += yang_count
        running_yang.append(yang_count)

    total_yang = sum(running_yang)
    total_yin = 64 * 6 - total_yang
    mean_yang = total_yang / 64

    print(f"Total yang lines: {total_yang} / {64*6} ({total_yang/(64*6)*100:.1f}%)")
    print(f"Total yin lines:  {total_yin} / {64*6} ({total_yin/(64*6)*100:.1f}%)")
    print(f"Mean yang per hexagram: {mean_yang:.2f}")
    print()

    # Running average over a window
    window = 8
    print(f"Running yang average (window={window}):")
    print(f"{'Pos':>4} {'Yang':>5} {'RunAvg':>7}  {'':>2} Visualization")

    running_avgs = []
    for i in range(64):
        start = max(0, i - window + 1)
        avg = sum(running_yang[start:i+1]) / (i - start + 1)
        running_avgs.append(avg)
        bar_center = 20
        bar_pos = int((avg - 0) / 6 * 40)
        bar = [' '] * 41
        bar[20] = '|'  # center line at 3.0
        bar[min(40, bar_pos)] = '#'
        bar_str = ''.join(bar)
        print(f"{i+1:>4}   {running_yang[i]:>3}   {avg:>5.2f}   [{bar_str}]")

    # Spark line of raw yang counts per hexagram
    yang_spark = "".join(SPARK[min(y, 6)] for y in running_yang)
    print(f"\nYang count spark: {yang_spark}")

    # Check for runs of high-yang or high-yin
    print(f"\n--- Yang/Yin dominance runs ---")
    current_run = 0
    current_type = None
    runs = []
    for i in range(64):
        y = running_yang[i]
        t = "yang" if y > 3 else ("yin" if y < 3 else "balanced")
        if t == current_type:
            current_run += 1
        else:
            if current_type and current_type != "balanced" and current_run >= 3:
                runs.append((i - current_run, current_run, current_type))
            current_run = 1
            current_type = t
    if current_type and current_type != "balanced" and current_run >= 3:
        runs.append((64 - current_run, current_run, current_type))

    if runs:
        for start, length, rtype in runs:
            print(f"  Positions {start+1:02}-{start+length:02}: {length} consecutive {rtype}-dominant hexagrams")
    else:
        print("  No runs of 3+ consecutive yang- or yin-dominant hexagrams found.")

def print_neighborhoods():
    """Show Hamming distance neighborhoods for each hexagram."""
    print("---")
    print("Hexagram neighborhoods")
    print("For each hexagram, which others are 'nearby' (differ by only 1 or 2 lines)?")
    print("Dense neighborhoods mean a hexagram has many close relatives; sparse ones are")
    print("more isolated. This also shows whether King Wen places neighbors near each")
    print("other in the sequence or scatters them.")
    print("---")



    for i in range(64):
        d1 = []  # Distance-1 neighbors
        d2 = []  # Distance-2 neighbors
        for j in range(64):
            if i == j:
                continue
            d = bit_diff(binary_hexagrams[i], binary_hexagrams[j])
            if d == 1:
                d1.append(j)
            elif d == 2:
                d2.append(j)

        d1_str = ", ".join(f"{j+1:02}" for j in d1)
        d1_seq_dists = [abs(j - i) for j in d1]
        mean_seq = sum(d1_seq_dists) / len(d1_seq_dists) if d1_seq_dists else 0

        print(f"{i+1:02} {unicode_hexagrams[i]} {hexagram_names[i]:<28} "
              f"d=1: [{d1_str}] ({len(d1)} neighbors, "
              f"mean seq dist: {mean_seq:.1f})")

    # Summary: how close are Hamming-1 neighbors in the sequence?
    print(f"\n--- Neighborhood clustering in King Wen sequence ---")
    all_seq_dists = []
    for i in range(64):
        for j in range(64):
            if bit_diff(binary_hexagrams[i], binary_hexagrams[j]) == 1:
                all_seq_dists.append(abs(j - i))

    mean_d = sum(all_seq_dists) / len(all_seq_dists)

    # Compare against random expectation
    random_mean = sum(abs(i - j) for i in range(64) for j in range(64) if i != j) / (64 * 63)
    print(f"Mean sequence distance between Hamming-1 neighbors: {mean_d:.1f}")
    print(f"Mean sequence distance between any two hexagrams:   {random_mean:.1f}")
    if mean_d < random_mean:
        print("Hamming-1 neighbors are closer than average in the sequence (clustered).")
    else:
        print("Hamming-1 neighbors are NOT closer than average (not clustered).")

def print_recurrence():
    """Generate a recurrence plot of the difference wave."""
    print("---")
    print("Recurrence plot")
    print("A recurrence plot shows where the difference wave repeats itself. Each cell (i,j)")
    print("is marked if the difference at position i equals the difference at position j.")
    print("Diagonal lines indicate repeated sequences; vertical/horizontal lines indicate")
    print("values that persist. Clusters of marks reveal recurring local patterns.")
    print("---")

    diffs = compute_diffs(wrap=False)
    n = len(diffs)

    # Print column headers (tens)
    print("     ", end="")
    for j in range(n):
        if (j + 1) % 10 == 0:
            print(str((j + 1) // 10), end="")
        else:
            print(" ", end="")
    print()
    # Print column headers (ones)
    print("     ", end="")
    for j in range(n):
        print(str((j + 1) % 10), end="")
    print()

    for i in range(n):
        print(f"{i+1:>3}  ", end="")
        for j in range(n):
            if diffs[i] == diffs[j]:
                if i == j:
                    print("+", end="")  # Diagonal
                else:
                    print("#", end="")
            else:
                print(".", end="")
        print()

    # Count recurrence rate
    matches = sum(1 for i in range(n) for j in range(n) if i != j and diffs[i] == diffs[j])
    total_pairs = n * (n - 1)
    print(f"\nRecurrence rate: {matches}/{total_pairs} ({matches/total_pairs*100:.1f}%)")

def print_casting():
    """Simulate an I Ching reading using the three-coin method.
    https://en.wikipedia.org/wiki/I_Ching_divination"""
    print("---")
    print("I Ching casting (three-coin method)")
    print("In a traditional reading, three coins are tossed six times to generate a")
    print("hexagram. Heads=3, Tails=2. The sum of three coins (6,7,8,9) determines each")
    print("line: 6=old yin (changing), 7=young yang, 8=young yin, 9=old yang (changing).")
    print("'Changing' lines transform to produce a second hexagram showing the situation's")
    print("trajectory. This is a simulation — not a substitute for a real casting!")
    print("---")

    lines = []
    changing = []
    for line_num in range(6):
        # Three coins: heads=3, tails=2
        coins = [random.choice([2, 3]) for _ in range(3)]
        total = sum(coins)
        coin_str = "+".join(str(c) for c in coins)

        if total == 6:
            lines.append(0)  # old yin
            changing.append(True)
            line_type = "--- x --- old yin (changing)"
        elif total == 7:
            lines.append(1)  # young yang
            changing.append(False)
            line_type = "--------- young yang"
        elif total == 8:
            lines.append(0)  # young yin
            changing.append(False)
            line_type = "---   --- young yin"
        else:  # 9
            lines.append(1)  # old yang
            changing.append(True)
            line_type = "----o---- old yang (changing)"

        print(f"  Line {line_num+1}: coins={coin_str}={total}  {line_type}")

    # Build the primary hexagram (bits: line 1 = bit 0)
    primary_val = sum(lines[i] << i for i in range(6))


    if primary_val not in VAL_TO_POS:
        print(f"\nError: generated value {primary_val} not found in hexagram table.")
        return

    primary_pos = VAL_TO_POS[primary_val]
    print(f"\n  Primary hexagram: {primary_pos+1:02} {unicode_hexagrams[primary_pos]} "
          f"{hexagram_names[primary_pos]}")

    # Build the relating hexagram (change old yin->yang, old yang->yin)
    has_changing = any(changing)
    if has_changing:
        relating_lines = list(lines)
        for i in range(6):
            if changing[i]:
                relating_lines[i] = 1 - relating_lines[i]
        relating_val = sum(relating_lines[i] << i for i in range(6))
        relating_pos = VAL_TO_POS[relating_val]
        changing_positions = [i+1 for i in range(6) if changing[i]]
        print(f"  Changing lines: {', '.join(str(p) for p in changing_positions)}")
        print(f"  Relating hexagram: {relating_pos+1:02} {unicode_hexagrams[relating_pos]} "
              f"{hexagram_names[relating_pos]}")
    else:
        print("  No changing lines — the situation is stable.")

def print_explain(position):
    """Walk through the binary math of a single transition step by step."""
    pos = None
    try:
        pos = int(position)
    except ValueError:
        print(f"Expected a number (1-63), got: {position}")
        return

    if pos < 1 or pos > 63:
        print(f"Position must be between 1 and 63 (there are 63 transitions).")
        return

    i = pos - 1  # 0-indexed
    a = binary_hexagrams[i]
    b = binary_hexagrams[i + 1]
    bits_a = bin(a)[2:].zfill(6)
    bits_b = bin(b)[2:].zfill(6)

    print("---")
    print(f"Step-by-step explanation of transition {pos}: "
          f"hexagram {i+1} -> hexagram {i+2}")
    print("---")

    print(f"\n  Hexagram {i+1}: {unicode_hexagrams[i]} {hexagram_names[i]}")
    print(f"  Hexagram {i+2}: {unicode_hexagrams[i+1]} {hexagram_names[i+1]}")

    print(f"\n  Step 1: Binary representation")
    print(f"  Each hexagram has 6 lines. We encode them as bits:")
    print(f"  1 = solid line (yang), 0 = broken line (yin)")
    print(f"  Bit positions: [top=bit5] [bit4] [bit3] [bit2] [bit1] [bottom=bit0]")
    print()
    print(f"  {unicode_hexagrams[i]}  = {bits_a}")
    print(f"  {unicode_hexagrams[i+1]}  = {bits_b}")

    # Show lines visually
    print(f"\n  Visual comparison (top to bottom):")
    for line in range(5, -1, -1):
        bit_a = (a >> line) & 1
        bit_b = (b >> line) & 1
        sym_a = "---------" if bit_a else "---   ---"
        sym_b = "---------" if bit_b else "---   ---"
        changed = " <-- CHANGED" if bit_a != bit_b else ""
        print(f"    Line {line+1}: {sym_a}  ->  {sym_b}{changed}")

    print(f"\n  Step 2: XOR to find differences")
    print(f"  XOR compares each bit: 1 if different, 0 if same")
    xor = a ^ b
    bits_xor = bin(xor)[2:].zfill(6)
    print(f"    {bits_a}")
    print(f"  ^ {bits_b}")
    print(f"  = {bits_xor}")
    print(f"  Each '1' in the result marks a line that changed.")

    print(f"\n  Step 3: Count the 1s (popcount)")
    diff = bit_diff(a, b)
    ones = [i for i in range(6) if bits_xor[5-i] == '1']
    print(f"  {bits_xor} has {diff} ones")
    if ones:
        print(f"  Changed line positions: {', '.join(str(o+1) for o in ones)}")

    print(f"\n  Step 4: Trigram extraction")
    print(f"  Lower trigram = bits 0-2, Upper trigram = bits 3-5")
    _, up_a, um_a = trigram_names[upper_trigram(a)]
    _, lp_a, lm_a = trigram_names[lower_trigram(a)]
    _, up_b, um_b = trigram_names[upper_trigram(b)]
    _, lp_b, lm_b = trigram_names[lower_trigram(b)]
    print(f"  {unicode_hexagrams[i]}:  upper={up_a} ({um_a}), lower={lp_a} ({lm_a})")
    print(f"  {unicode_hexagrams[i+1]}:  upper={up_b} ({um_b}), lower={lp_b} ({lm_b})")
    upper_changed = upper_trigram(a) != upper_trigram(b)
    lower_changed = lower_trigram(a) != lower_trigram(b)
    print(f"  Upper trigram {'CHANGED' if upper_changed else 'unchanged'}, "
          f"lower trigram {'CHANGED' if lower_changed else 'unchanged'}")

    print(f"\n  Result: transition {pos} changes {diff} of 6 lines.")
    print(f"  This contributes '{diff}' to the difference wave. {'*' * diff}")

def print_codons():
    """Map the 64 hexagrams to the 64 DNA codons and compare structures.
    https://en.wikipedia.org/wiki/Genetic_code
    https://en.wikipedia.org/wiki/DNA_and_RNA_codon_tables"""
    print("---")
    print("DNA codon mapping")
    print("Both the I Ching (64 hexagrams) and the genetic code (64 codons) are systems")
    print("of 64 elements built from binary-like pairs: yin/yang for hexagrams, and the")
    print("base pairs A-T and G-C for DNA. Each codon is a sequence of 3 bases from the")
    print("set {A, C, G, U}, giving 4^3 = 64 possibilities. While this is a numerical")
    print("coincidence (both are 2^6 = 64), comparing their structural properties is")
    print("instructive about combinatorial systems in general.")
    print("---")

    # Standard genetic code: map 6-bit values to codons
    # Encoding: each pair of bits maps to a base
    # Using the convention: 00=U, 01=C, 10=A, 11=G
    bases = {0b00: 'U', 0b01: 'C', 0b10: 'A', 0b11: 'G'}

    # Standard codon table (codon -> amino acid)
    codon_table = {
        "UUU": "Phe", "UUC": "Phe", "UUA": "Leu", "UUG": "Leu",
        "UCU": "Ser", "UCC": "Ser", "UCA": "Ser", "UCG": "Ser",
        "UAU": "Tyr", "UAC": "Tyr", "UAA": "Stop", "UAG": "Stop",
        "UGU": "Cys", "UGC": "Cys", "UGA": "Stop", "UGG": "Trp",
        "CUU": "Leu", "CUC": "Leu", "CUA": "Leu", "CUG": "Leu",
        "CCU": "Pro", "CCC": "Pro", "CCA": "Pro", "CCG": "Pro",
        "CAU": "His", "CAC": "His", "CAA": "Gln", "CAG": "Gln",
        "CGU": "Arg", "CGC": "Arg", "CGA": "Arg", "CGG": "Arg",
        "AUU": "Ile", "AUC": "Ile", "AUA": "Ile", "AUG": "Met",
        "ACU": "Thr", "ACC": "Thr", "ACA": "Thr", "ACG": "Thr",
        "AAU": "Asn", "AAC": "Asn", "AAA": "Lys", "AAG": "Lys",
        "AGU": "Ser", "AGC": "Ser", "AGA": "Arg", "AGG": "Arg",
        "GUU": "Val", "GUC": "Val", "GUA": "Val", "GUG": "Val",
        "GCU": "Ala", "GCC": "Ala", "GCA": "Ala", "GCG": "Ala",
        "GAU": "Asp", "GAC": "Asp", "GAA": "Glu", "GAG": "Glu",
        "GGU": "Gly", "GGC": "Gly", "GGA": "Gly", "GGG": "Gly",
    }

    def val_to_codon(val):
        """Convert a 6-bit value to a 3-base codon."""
        b1 = bases[(val >> 4) & 0b11]
        b2 = bases[(val >> 2) & 0b11]
        b3 = bases[val & 0b11]
        return b1 + b2 + b3

    print("Pos | Hex | Binary | Codon | Amino Acid | Name")
    print("----|-----|--------|-------|------------|----")
    amino_acids = []
    for i in range(64):
        b = binary_hexagrams[i]
        bits = bin(b)[2:].zfill(6)
        codon = val_to_codon(b)
        aa = codon_table.get(codon, "?")
        amino_acids.append(aa)
        print(f"{i+1:02}  | {unicode_hexagrams[i]}   | {bits} | {codon}  | {aa:<10} | {hexagram_names[i]}")

    # How many unique amino acids does the King Wen sequence map to?
    unique_aa = set(amino_acids)
    print(f"\nUnique amino acids in King Wen order: {len(unique_aa)}")
    print(f"Total possible amino acids + stop: 21")

    # Structural comparison: in the genetic code, single-base mutations often
    # preserve the amino acid (degeneracy). Is this true for single-line hexagram changes?
    print(f"\n--- Degeneracy comparison ---")
    print("In DNA, many single-base changes preserve the amino acid (the code is 'degenerate').")
    print("Do single-line hexagram changes preserve the mapped amino acid?")

    preserved = 0
    total_neighbors = 0
    for i in range(64):
        for bit in range(6):
            neighbor = binary_hexagrams[i] ^ (1 << bit)
            codon_a = val_to_codon(binary_hexagrams[i])
            codon_b = val_to_codon(neighbor)
            aa_a = codon_table.get(codon_a, "?")
            aa_b = codon_table.get(codon_b, "?")
            total_neighbors += 1
            if aa_a == aa_b:
                preserved += 1

    print(f"Single-line changes that preserve amino acid: {preserved}/{total_neighbors} "
          f"({preserved/total_neighbors*100:.1f}%)")

def export_midi(filename="wave.mid"):
    """Export the difference wave as a MIDI file."""
    # Write raw MIDI bytes (no external dependencies)
    # Format: single track, map diff values 1-6 to notes

    diffs = compute_diffs(wrap=False)

    # MIDI note mapping: difference 1-6 mapped to a pentatonic scale
    # Base note: middle C (60)
    note_map = {1: 60, 2: 62, 3: 64, 4: 67, 5: 69, 6: 72}
    velocity = 80
    duration = 480  # quarter note in ticks

    def var_length(value):
        """Encode a variable-length quantity for MIDI."""
        result = []
        result.append(value & 0x7F)
        value >>= 7
        while value:
            result.append((value & 0x7F) | 0x80)
            value >>= 7
        result.reverse()
        return bytes(result)

    def write_midi_bytes():
        """Build MIDI file as bytes."""
        # Track data
        track_data = bytearray()

        # Tempo: 120 BPM (500000 microseconds per beat)
        track_data += var_length(0)  # delta time
        track_data += bytes([0xFF, 0x51, 0x03, 0x07, 0xA1, 0x20])

        # Track name
        name = b"King Wen Difference Wave"
        track_data += var_length(0)
        track_data += bytes([0xFF, 0x03, len(name)]) + name

        for d in diffs:
            note = note_map.get(d, 60)
            # Note on
            track_data += var_length(0)
            track_data += bytes([0x90, note, velocity])
            # Note off
            track_data += var_length(duration)
            track_data += bytes([0x80, note, 0])

        # End of track
        track_data += var_length(0)
        track_data += bytes([0xFF, 0x2F, 0x00])

        # Header chunk
        header = bytearray()
        header += b'MThd'
        header += (6).to_bytes(4, 'big')  # chunk length
        header += (0).to_bytes(2, 'big')   # format 0 (single track)
        header += (1).to_bytes(2, 'big')   # 1 track
        header += (480).to_bytes(2, 'big')  # 480 ticks per beat

        # Track chunk
        track = bytearray()
        track += b'MTrk'
        track += len(track_data).to_bytes(4, 'big')
        track += track_data

        return bytes(header + track)

    midi_bytes = write_midi_bytes()

    with open(filename, "wb") as f:
        f.write(midi_bytes)
    print(f"MIDI written to {filename}")

def export_svg(filename="hexagrams.svg"):
    """Export hexagram line diagrams as an SVG image."""
    line_w = 30
    line_h = 4
    gap = 2
    hex_h = 6 * (line_h + gap) - gap
    hex_w = line_w + 10
    cols = 8
    rows = 8
    margin = 40
    label_h = 16

    total_w = margin + cols * (hex_w + 10)
    total_h = margin + rows * (hex_h + label_h + 15)

    lines = []
    lines.append(f'<svg xmlns="http://www.w3.org/2000/svg" width="{total_w}" height="{total_h}"'
                 f' font-family="monospace" font-size="9">')
    lines.append(f'<rect width="100%" height="100%" fill="white"/>')

    for i in range(64):
        col = i % cols
        row = i // cols
        x = margin + col * (hex_w + 10)
        y = margin + row * (hex_h + label_h + 15)

        b = binary_hexagrams[i]

        # Label
        lines.append(f'  <text x="{x + hex_w//2}" y="{y - 3}" text-anchor="middle">'
                     f'{i+1}. {unicode_hexagrams[i]}</text>')

        # Draw 6 lines, top to bottom (bit 5 = top, bit 0 = bottom)
        for line in range(6):
            bit = (b >> (5 - line)) & 1
            ly = y + line * (line_h + gap)
            if bit:  # Yang - solid line
                lines.append(f'  <rect x="{x}" y="{ly}" width="{line_w}" height="{line_h}"'
                             f' fill="black"/>')
            else:  # Yin - broken line
                seg_w = (line_w - gap * 2) // 2
                lines.append(f'  <rect x="{x}" y="{ly}" width="{seg_w}" height="{line_h}"'
                             f' fill="black"/>')
                lines.append(f'  <rect x="{x + seg_w + gap * 2}" y="{ly}" width="{seg_w}"'
                             f' height="{line_h}" fill="black"/>')

    lines.append('</svg>')
    with open(filename, "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"SVG written to {filename}")

def export_html(filename="report.html"):
    """Generate a self-contained HTML report with all analyses."""
    import io
    from contextlib import redirect_stdout

    out = open(filename, "w")
    _print = lambda *a, **k: print(*a, **k, file=out)

    _print("<!DOCTYPE html>")
    _print("<html><head>")
    _print('<meta charset="UTF-8">')
    _print("<title>ROAE - King Wen Sequence Analysis</title>")
    _print("<style>")
    _print("  @font-face { font-family: 'HexFallback'; "
           "src: local('DejaVu Sans'), local('Segoe UI Symbol'), "
           "local('Arial Unicode MS'); }")
    _print("  body { font-family: monospace; background: #1a1a2e; color: #e0e0e0; "
           "max-width: 1000px; margin: 0 auto; padding: 20px; }")
    _print("  pre { font-family: 'DejaVu Sans Mono', 'Noto Sans Mono', "
           "'Courier New', monospace, 'HexFallback'; "
           "background: #16213e; padding: 15px; "
           "overflow-x: auto; border-left: 3px solid #e94560; }")
    _print("  h1 { color: #e94560; }")
    _print("  h2 { color: #0f3460; background: #e0e0e0; padding: 8px; margin-top: 30px; }")
    _print("  .section { margin-bottom: 20px; }")
    _print("</style>")
    _print("</head><body>")
    _print("<h1>Received Order Analysis Engine</h1>")
    _print("<p>Analysis of the King Wen sequence including observations by Terence McKenna</p>")

    # Capture each section's output
    sections = [
        ("Hexagram Table", print_table),
        ("Reverse/Inverse Pairs", print_pairs),
        ("Difference Wave", lambda: print_wave(order=1, wrap=False)),
        ("Bar Chart", print_barchart),
        ("Trigram Analysis", print_trigrams),
        ("Nuclear Hexagrams", print_nuclear),
        ("Line Change Analysis", print_line_changes),
        ("Complement Distance", print_complements),
        ("Palindromes", print_palindromes),
        ("Canon Comparison", print_canons),
        ("Autocorrelation", print_autocorrelation),
        ("Spectral Analysis", print_fft),
        ("Markov Chain", print_markov),
        ("Gray Code Comparison", print_graycode),
        ("Symmetry Groups", print_symmetry),
        ("Alternative Sequences", print_sequences),
        ("Windowed Entropy", print_windowed_entropy),
        ("Mutual Information", print_mutual_info),
        ("Yin-Yang Balance", print_yinyang),
        ("Neighborhoods", print_neighborhoods),
        ("Recurrence Plot", print_recurrence),
        ("DNA Codons", print_codons),
        ("Shannon Entropy", print_entropy),
        ("Path Analysis", print_path),
        ("Constraint Satisfaction", print_constraints),
        ("Bootstrap", lambda: print_bootstrap(trials=10000)),
        ("Monte Carlo", lambda: print_stats(trials=10000)),
    ]

    import re
    def fix_hexagram_spacing(text):
        """In terminal output, hexagram chars (U+4DC0-4DFF) are double-width,
        so they're followed by extra padding spaces. In HTML/PDF with fallback
        fonts, this creates misalignment. Remove one trailing space after each."""
        return re.sub(r'([\u4DC0-\u4DFF])   ', r'\1  ', text)

    for title, func in sections:
        f = io.StringIO()
        with redirect_stdout(f):
            func()
        output = fix_hexagram_spacing(f.getvalue())
        _print(f'<div class="section">')
        _print(f'<h2>{title}</h2>')
        _print(f'<pre>{output}</pre>')
        _print(f'</div>')

    _print("</body></html>")
    out.close()
    print(f"HTML report written to {filename}")
    # Try to also generate a PDF if wkhtmltopdf is installed
    import subprocess
    pdf_filename = filename.rsplit(".", 1)[0] + ".pdf"
    try:
        result = subprocess.run(
            ["wkhtmltopdf", "--quiet", filename, pdf_filename],
            capture_output=True, text=True
        )
        if result.returncode == 0:
            print(f"PDF written to {pdf_filename}")
    except FileNotFoundError:
        pass  # wkhtmltopdf not installed; skip PDF generation

def print_graphviz(filename="wave.dot"):
    """Output a Graphviz DOT representation of the King Wen sequence as a
    directed graph, with edge weights showing the Hamming distance."""
    lines = []
    lines.append("// King Wen sequence as a Graphviz directed graph")
    lines.append("digraph KingWen {")
    lines.append("    rankdir=LR;")
    lines.append("    node [shape=circle, fontsize=10];")
    lines.append("    edge [fontsize=8];")
    lines.append("")
    for i in range(64):
        bits = bin(binary_hexagrams[i])[2:].zfill(6)
        label = f"{i+1}\\n{unicode_hexagrams[i]}\\n{bits}"
        lines.append(f'    h{i+1} [label="{label}"];')
    lines.append("")
    for i in range(63):
        d = bit_diff(binary_hexagrams[i], binary_hexagrams[i+1])
        lines.append(f'    h{i+1} -> h{i+2} [label="{d}"];')
    lines.append("}")
    dot_text = "\n".join(lines)
    with open(filename, "w") as f:
        f.write(dot_text + "\n")
    print(f"DOT written to {filename}")
    # Try to also generate PNG and SVG if Graphviz is installed
    import subprocess
    try:
        for fmt, outfile in [("png", filename + ".png"), ("svg", filename + ".svg")]:
            result = subprocess.run(
                ["dot", f"-T{fmt}", "-o", outfile],
                input=dot_text, capture_output=True, text=True
            )
            if result.returncode == 0:
                print(f"{fmt.upper()} written to {outfile}")
    except FileNotFoundError:
        pass  # Graphviz not installed; skip image generation

def export_json(filename="hexagrams.json"):
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

    with open(filename, "w") as f:
        f.write(json.dumps(data, indent=2, ensure_ascii=False))
    print(f"JSON written to {filename}")

def export_csv(filename="hexagrams.csv"):
    """Export hexagram data as CSV."""
    with open(filename, "w") as f:
        f.write("position,unicode,binary,decimal,name,upper_pinyin,upper_meaning,"
                "lower_pinyin,lower_meaning,nuclear_position\n")
        for i in range(64):
            b = binary_hexagrams[i]
            bits = bin(b)[2:].zfill(6)
            _, up, um = trigram_names[upper_trigram(b)]
            _, lp, lm = trigram_names[lower_trigram(b)]
            nuc_pos = binary_to_kw_position(nuclear_hexagram(b))
            name = hexagram_names[i].replace(",", ";")  # escape commas in names
            f.write(f"{i+1},{unicode_hexagrams[i]},{bits},{b},{name},{up},{um},{lp},{lm},{nuc_pos}\n")
    print(f"CSV written to {filename}")

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
    parser.add_argument("--barchart", action="store_true",
                        help="Print ASCII bar chart of the difference wave")
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
    parser.add_argument("--fft", action="store_true",
                        help="Spectral analysis (DFT) of the difference wave")
    parser.add_argument("--markov", action="store_true",
                        help="Markov chain analysis of difference transitions")
    parser.add_argument("--graycode", action="store_true",
                        help="Compare King Wen against Gray code ordering")
    parser.add_argument("--symmetry", action="store_true",
                        help="XOR group algebra analysis of pair structure")
    parser.add_argument("--sequences", action="store_true",
                        help="Compare King Wen vs Fu Xi vs Mawangdui orderings")
    parser.add_argument("--constraints", action="store_true",
                        help="Constraint satisfaction analysis")
    parser.add_argument("--windowed-entropy", action="store_true",
                        help="Sliding window entropy across the wave")
    parser.add_argument("--mutual-info", action="store_true",
                        help="Mutual information between upper/lower trigram changes")
    parser.add_argument("--bootstrap", action="store_true",
                        help="Bootstrap confidence intervals for Monte Carlo")
    parser.add_argument("--yinyang", action="store_true",
                        help="Yin-yang balance wave through the sequence")
    parser.add_argument("--neighborhoods", action="store_true",
                        help="Hamming distance-1 neighborhoods for each hexagram")
    parser.add_argument("--recurrence", action="store_true",
                        help="Recurrence plot of the difference wave")
    parser.add_argument("--codons", action="store_true",
                        help="DNA codon mapping comparison")
    parser.add_argument("--all", action="store_true",
                        help="Run all analysis sections (default if no flags given)")
    parser.add_argument("--quick", action="store_true",
                        help="Run core sections only (table, pairs, wave, barchart, "
                             "trigrams, canons, graycode, stats)")

    # Interactive / special modes
    parser.add_argument("--self-test", action="store_true",
                        help="Run mathematical invariant checks")
    parser.add_argument("--lookup", type=str, default=None,
                        help="Look up a hexagram by number (1-64) or name")
    parser.add_argument("--compare", nargs=2, type=str, default=None,
                        help="Compare two hexagrams (by number or name)")
    parser.add_argument("--cast", action="store_true",
                        help="Simulate an I Ching reading (three-coin method)")
    parser.add_argument("--explain", type=str, default=None,
                        help="Walk through transition N step by step (1-63)")

    # Modifiers
    parser.add_argument("--wrap", action="store_true",
                        help="Include 64->1 wrap-around transition in wave")
    parser.add_argument("--order", type=int, default=1,
                        help="Compute Nth order of difference (default: 1)")
    parser.add_argument("--trials", type=int, default=100000,
                        help="Number of Monte Carlo trials (default: 100000)")
    parser.add_argument("--seed", type=int, default=None,
                        help="Random seed for reproducible Monte Carlo results")
    parser.add_argument("--color", action="store_true",
                        help="Enable ANSI color output")

    # Export formats
    parser.add_argument("--json", action="store_true",
                        help="Export hexagram data (writes hexagrams.json)")
    parser.add_argument("--csv", action="store_true",
                        help="Export hexagram data (writes hexagrams.csv)")
    parser.add_argument("--dot", action="store_true",
                        help="Export Graphviz graph (writes wave.dot, + .png/.svg if Graphviz installed)")
    parser.add_argument("--svg", action="store_true",
                        help="Export hexagram line diagrams (writes hexagrams.svg)")
    parser.add_argument("--html", action="store_true",
                        help="Export HTML report (writes report.html, + .pdf if wkhtmltopdf installed)")
    parser.add_argument("--midi", action="store_true",
                        help="Export difference wave (writes wave.mid)")

    # Help
    parser.add_argument("--help-sections", action="store_true",
                        help="List all available analysis sections with descriptions")

    args = parser.parse_args()

    # Special modes that bypass normal output
    if args.help_sections:
        print_help_sections()
        return
    if args.self_test:
        print_self_test()
        return
    if args.lookup:
        print_header()
        print_lookup(args.lookup)
        return
    if args.compare:
        print_header()
        print_compare(args.compare[0], args.compare[1])
        return
    if args.cast:
        print_header()
        print_casting()
        return
    if args.explain:
        print_header()
        print_explain(args.explain)
        return
    if args.json:
        export_json()
        return
    if args.csv:
        export_csv()
        return
    if args.dot:
        print_graphviz()
        return
    if args.svg:
        export_svg()
        return
    if args.html:
        export_html()
        return
    if args.midi:
        export_midi()
        return

    all_sections = [args.table, args.pairs, args.wave, args.barchart, args.trigrams,
                    args.nuclear, args.lines, args.complements, args.palindromes,
                    args.canons, args.hamming, args.autocorrelation, args.entropy,
                    args.path, args.stats, args.fft, args.markov, args.graycode,
                    args.symmetry, args.sequences, args.constraints,
                    args.windowed_entropy, args.mutual_info, args.bootstrap,
                    args.yinyang, args.neighborhoods, args.recurrence, args.codons]
    run_all = args.all or (not args.quick and not any(all_sections))
    run_quick = args.quick

    if args.seed is not None:
        random.seed(args.seed)

    print_header()
    use_color = args.color
    # Quick mode runs: table, pairs, wave, barchart, trigrams, canons, graycode, stats
    q = run_quick
    if run_all or q or args.table:           print_table(use_color=use_color)
    if run_all or q or args.pairs:           print_pairs(use_color=use_color)
    if run_all or q or args.wave:            print_wave(order=args.order, wrap=args.wrap)
    if run_all or q or args.barchart:        print_barchart()
    if run_all or q or args.trigrams:        print_trigrams()
    if run_all or args.nuclear:              print_nuclear()
    if run_all or args.lines:                print_line_changes()
    if run_all or args.complements:          print_complements()
    if run_all or args.palindromes:          print_palindromes()
    if run_all or q or args.canons:          print_canons()
    if run_all or args.hamming:              print_hamming()
    if run_all or args.autocorrelation:      print_autocorrelation()
    if run_all or args.fft:                  print_fft()
    if run_all or args.markov:               print_markov()
    if run_all or q or args.graycode:        print_graycode()
    if run_all or args.symmetry:             print_symmetry()
    if run_all or args.sequences:            print_sequences()
    if run_all or args.constraints:          print_constraints()
    if run_all or args.windowed_entropy:     print_windowed_entropy()
    if run_all or args.mutual_info:          print_mutual_info()
    if run_all or args.yinyang:              print_yinyang()
    if run_all or args.neighborhoods:        print_neighborhoods()
    if run_all or args.recurrence:           print_recurrence()
    if run_all or args.codons:               print_codons()
    if run_all or args.entropy:              print_entropy()
    if run_all or args.path:                 print_path()
    if run_all or args.bootstrap:            print_bootstrap(trials=args.trials)
    if run_all or q or args.stats:           print_stats(trials=args.trials)

    if run_all:
        print("\n---")
        print("Note on multiple comparisons")
        print("This report runs 33 analyses. When testing many properties, some will")
        print("appear 'unusual' by chance alone. A result at the 5% level (p<0.05)")
        print("is expected ~1.7 times out of 33 tests even for a purely random sequence.")
        print("The strongest findings (pair structure, combined constraints) survive this")
        print("correction easily. Weaker findings (specific Markov transitions, individual")
        print("entropy percentiles) should be interpreted with this caveat in mind.")
        print("---")

if __name__ == "__main__":
    main()
