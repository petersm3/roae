#!/usr/bin/env python3
def reverse_6bit(n):
    # Shift each bit to its reversed position
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

# https://en.wikipedia.org/wiki/King_Wen_sequence#Structure_of_the_sequence
unicode_hexagrams = [  # Element 0–63; sequence 1–64
    "䷀", "䷁", "䷂", "䷃", "䷄", "䷅", "䷆", "䷇",
    "䷈", "䷉", "䷊", "䷋", "䷌", "䷍", "䷎", "䷏",
    "䷐", "䷑", "䷒", "䷓", "䷔", "䷕", "䷖", "䷗",
    "䷘", "䷙", "䷚", "䷛", "䷜", "䷝", "䷞", "䷟",
    "䷠", "䷡", "䷢", "䷣", "䷤", "䷥", "䷦", "䷧",
    "䷨", "䷩", "䷪", "䷫", "䷬", "䷭", "䷮", "䷯",
    "䷰", "䷱", "䷲", "䷳", "䷴", "䷵", "䷶", "䷷",
    "䷸", "䷹", "䷺", "䷻", "䷼", "䷽", "䷾", "䷿",
]

# https://oeis.org/A102241
binary_hexagrams = [  # Element 0–63; sequence 1–64
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

# Check for reverse and inverse pairs
reverse_count = 0
inverse_count = 0
neither_count = 0
total_count = int(len(binary_hexagrams)/2)

for index in range(0, 64, 2):
    print(str(index+1).zfill(2) + " ", end="")
    if(binary_hexagrams[index] == reverse_6bit(binary_hexagrams[index+1])):
        reverse_count += 1
        print(unicode_hexagrams[index], end="")
        print(" Reverse ", end="")
    elif (binary_hexagrams[index] == binary_hexagrams[index+1] ^ 0b00111111):
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

diff_array = [0, 0, 0, 0, 0, 0, 0]
for index in range(0, 63):
    print(str(index+1).zfill(2) + " ", end="")
    print(unicode_hexagrams[index], end="")
    print(" to ", end="")
    print(str(index+2).zfill(2) + " ", end="")
    print(unicode_hexagrams[index+1], end="")
    print(" difference ", end="")
    diff = binary_hexagrams[index] ^ binary_hexagrams[index+1]
    diff_count = bin(diff).count("1")
    diff_array[diff_count] = diff_array[diff_count] + 1 
    print(diff_count, end="")
    print(" " + "*"*diff_count)

print("---")
# Print tally
# 0 changes total of 0 is expected
# 5 changes total of 0 is observed by McKenna
for diff_number in range(len(diff_array)):
    print(diff_number, end="")
    print(" line changes total ", end="")
    print(diff_array[diff_number])
