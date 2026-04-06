#!/usr/bin/env python3

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

print("---")
print("Received Order Analysis Engine")
print("of the King Wen sequence including")
print("observations by Terence McKenna")
# https://en.wikipedia.org/wiki/Terence_McKenna#Novelty_theory_and_Timewave_Zero
print("---")

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

print("Pos Hex Binary")
for index in range(64):
    print(str(index+1).zfill(2) + "  ", end="")
    print(unicode_hexagrams[index] + "   ", end="")
    print(str(bin(binary_hexagrams[index]))[2:].zfill(6))

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
total_count = int(len(binary_hexagrams)/2)

for index in range(0, 64, 2):
    print(str(index+1).zfill(2) + " ", end="")
    # Check if flipping the second hexagram upside down yields the first
    if(binary_hexagrams[index] == reverse_6bit(binary_hexagrams[index+1])):
        reverse_count += 1
        print(unicode_hexagrams[index], end="")
        print(" Reverse ", end="")
    # Check if toggling all lines (XOR 0b111111) of the second yields the first
    elif (binary_hexagrams[index] == binary_hexagrams[index+1] ^ 0b111111):
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
# Reverse
print("Reverse count pairs: " + str(reverse_count).zfill(2), end="")
print("/" + str(total_count) + " (", end="")
print(str((reverse_count/total_count)*100) + "%)")
# Inverse
print("Inverse count pairs: " + str(inverse_count).zfill(2), end="")
print("/" + str(total_count) + " (", end="")
print(str((inverse_count/total_count)*100) + "%)")
# Neither
print("Neither count pairs: " + str(neither_count).zfill(2), end="")
print("/" + str(total_count) + " (", end="")
print(str((neither_count/total_count)*100) + "%)")

print("---")
print("First order of difference")
print("How many lines change between each hexagram")
print("---")

# Tally of how many times each difference count (0–6) occurs
diff_array = [0, 0, 0, 0, 0, 0, 0]
for index in range(0, 63):
    print(str(index+1).zfill(2) + " ", end="")
    print(unicode_hexagrams[index], end="")
    print(" to ", end="")
    print(str(index+2).zfill(2) + " ", end="")
    print(unicode_hexagrams[index+1], end="")
    print(" difference ", end="")
    # XOR reveals which bits differ; popcount gives the number of changed lines
    diff = binary_hexagrams[index] ^ binary_hexagrams[index+1]
    diff_count = bin(diff).count("1")
    diff_array[diff_count] = diff_array[diff_count] + 1 
    print(diff_count, end="")
    print(" " + "*"*diff_count)

print("---")
# Summary: how often each difference count (0–6 line changes) occurs.
# Notable findings:
#   0 changes: 0 — no consecutive hexagrams are identical (expected)
#   5 changes: 0 — McKenna's observation; this never occurs in the sequence,
#                   which is statistically unlikely for a random ordering
for diff_number in range(len(diff_array)):
    print(diff_number, end="")
    print(" line changes total ", end="")
    print(diff_array[diff_number])
