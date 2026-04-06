#!/usr/bin/env python3
import argparse
import random

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

def upper_trigram(val):
    return (val >> 3) & 0b111

def lower_trigram(val):
    return val & 0b111

def trigram_label(t):
    symbol, pinyin, meaning = trigram_names[t]
    return f"{symbol} {pinyin:<4} {meaning}"

def trigram_short(t):
    symbol, pinyin, _ = trigram_names[t]
    return f"{symbol}{pinyin}"

# ---------------------------------------------------------------------------

def print_header():
    print("---")
    print("Received Order Analysis Engine")
    print("of the King Wen sequence including")
    print("observations by Terence McKenna")
    # https://en.wikipedia.org/wiki/Terence_McKenna#Novelty_theory_and_Timewave_Zero
    print("---")

def print_table():
    print("Pos Hex Binary  Upper        Lower        Name")
    for i in range(64):
        b = binary_hexagrams[i]
        upper = upper_trigram(b)
        lower = lower_trigram(b)
        bits = bin(b)[2:].zfill(6)
        us, up, um = trigram_names[upper]
        ls, lp, lm = trigram_names[lower]
        print(f"{i+1:02}  {unicode_hexagrams[i]}  {bits}  "
              f"{us} {up:<4} {um:<7}  {ls} {lp:<4} {lm:<7}  "
              f"{hexagram_names[i]}")

def print_pairs():
    print("---")
    print("Reverse (180 degree rotation) vs. Inverse pairs")
    print("---")

    # The King Wen sequence arranges hexagrams in pairs (1-2, 3-4, ..., 63-64).
    # Each pair is related by one of two transformations:
    #   Reverse: flip the hexagram upside down (reverse the 6 bits)
    #   Inverse: toggle every line, solid<->broken (XOR with 0b111111)
    # A key structural property is that EVERY pair is one or the other — never neither.
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
            print(" Reverse ", end="")
        # Check if toggling all lines (XOR 0b111111) of the second yields the first
        elif binary_hexagrams[index] == binary_hexagrams[index+1] ^ 0b111111:
            inverse_count += 1
            print(unicode_hexagrams[index], end="")
            print(" Inverse ", end="")
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
    label = "difference" if order == 1 else f"order-{order} difference"
    if wrap:
        print(f"First order of {label} (with 64\u21921 wrap-around)")
    else:
        print(f"First order of difference")
    print("How many lines change between each hexagram")
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
        symbol, pinyin, meaning = trigram_names[t]
        u = upper_counts[t]
        l = lower_counts[t]
        print(f"{symbol} {pinyin:<4} {meaning:<12}   {u:2}     {l:2}     {u+l:2}")

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

def print_stats(trials=100000):
    print("---")
    print(f"Monte Carlo analysis ({trials:,} random permutations)")
    print("How likely is the 'no 5-line transitions' property by chance?")
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

def main():
    parser = argparse.ArgumentParser(
        description="Received Order Analysis Engine of the King Wen sequence")
    parser.add_argument("--table", action="store_true",
                        help="Print hexagram table with trigrams and names")
    parser.add_argument("--pairs", action="store_true",
                        help="Print reverse/inverse pair classification")
    parser.add_argument("--wave", action="store_true",
                        help="Print difference wave between consecutive hexagrams")
    parser.add_argument("--trigrams", action="store_true",
                        help="Print trigram frequency and transition analysis")
    parser.add_argument("--stats", action="store_true",
                        help="Run Monte Carlo statistical comparison")
    parser.add_argument("--all", action="store_true",
                        help="Run all sections (default if no flags given)")
    parser.add_argument("--wrap", action="store_true",
                        help="Include 64->1 wrap-around transition in wave")
    parser.add_argument("--order", type=int, default=1,
                        help="Compute Nth order of difference (default: 1)")
    parser.add_argument("--trials", type=int, default=100000,
                        help="Number of Monte Carlo trials (default: 100000)")
    args = parser.parse_args()

    run_all = args.all or not any([args.table, args.pairs, args.wave,
                                   args.trigrams, args.stats])

    print_header()
    if run_all or args.table:    print_table()
    if run_all or args.pairs:    print_pairs()
    if run_all or args.wave:     print_wave(order=args.order, wrap=args.wrap)
    if run_all or args.trigrams: print_trigrams()
    if run_all or args.stats:    print_stats(trials=args.trials)

if __name__ == "__main__":
    main()
