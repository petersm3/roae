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

# Using Lists instead of Dictionaries for faster lookup
# https://en.wikipedia.org/wiki/King_Wen_sequence#Structure_of_the_sequence
unicode_hexagrams = []
unicode_hexagrams.append("䷀"); # Element 0; sequence 1
unicode_hexagrams.append("䷁");
unicode_hexagrams.append("䷂");
unicode_hexagrams.append("䷃");
unicode_hexagrams.append("䷄");
unicode_hexagrams.append("䷅");
unicode_hexagrams.append("䷆");
unicode_hexagrams.append("䷇");
unicode_hexagrams.append("䷈");
unicode_hexagrams.append("䷉");
unicode_hexagrams.append("䷊");
unicode_hexagrams.append("䷋");
unicode_hexagrams.append("䷌");
unicode_hexagrams.append("䷍");
unicode_hexagrams.append("䷎");
unicode_hexagrams.append("䷏");
unicode_hexagrams.append("䷐");
unicode_hexagrams.append("䷑");
unicode_hexagrams.append("䷒");
unicode_hexagrams.append("䷓");
unicode_hexagrams.append("䷔");
unicode_hexagrams.append("䷕");
unicode_hexagrams.append("䷖");
unicode_hexagrams.append("䷗");
unicode_hexagrams.append("䷘");
unicode_hexagrams.append("䷙");
unicode_hexagrams.append("䷚");
unicode_hexagrams.append("䷛");
unicode_hexagrams.append("䷜");
unicode_hexagrams.append("䷝");
unicode_hexagrams.append("䷞");
unicode_hexagrams.append("䷟");
unicode_hexagrams.append("䷠");
unicode_hexagrams.append("䷡");
unicode_hexagrams.append("䷢");
unicode_hexagrams.append("䷣");
unicode_hexagrams.append("䷤");
unicode_hexagrams.append("䷥");
unicode_hexagrams.append("䷦");
unicode_hexagrams.append("䷧");
unicode_hexagrams.append("䷨");
unicode_hexagrams.append("䷩");
unicode_hexagrams.append("䷪");
unicode_hexagrams.append("䷫");
unicode_hexagrams.append("䷬");
unicode_hexagrams.append("䷭");
unicode_hexagrams.append("䷮");
unicode_hexagrams.append("䷯");
unicode_hexagrams.append("䷰");
unicode_hexagrams.append("䷱");
unicode_hexagrams.append("䷲");
unicode_hexagrams.append("䷳");
unicode_hexagrams.append("䷴");
unicode_hexagrams.append("䷵");
unicode_hexagrams.append("䷶");
unicode_hexagrams.append("䷷");
unicode_hexagrams.append("䷸");
unicode_hexagrams.append("䷹");
unicode_hexagrams.append("䷺");
unicode_hexagrams.append("䷻");
unicode_hexagrams.append("䷼");
unicode_hexagrams.append("䷽");
unicode_hexagrams.append("䷾");
unicode_hexagrams.append("䷿"); # Element 63; sequence 64

# https://oeis.org/A102241
binary_hexagrams = []
binary_hexagrams.append(0b111111) # ䷀ Element 0; sequence 1
binary_hexagrams.append(0b000000) # ䷁
binary_hexagrams.append(0b010001) # ䷂
binary_hexagrams.append(0b100010) # ䷃
binary_hexagrams.append(0b010111) # ䷄
binary_hexagrams.append(0b111010) # ䷅
binary_hexagrams.append(0b000010) # ䷆
binary_hexagrams.append(0b010000) # ䷇
binary_hexagrams.append(0b110111) # ䷈
binary_hexagrams.append(0b111011) # ䷉
binary_hexagrams.append(0b000111) # ䷊
binary_hexagrams.append(0b111000) # ䷋
binary_hexagrams.append(0b111101) # ䷌
binary_hexagrams.append(0b101111) # ䷍
binary_hexagrams.append(0b000100) # ䷎
binary_hexagrams.append(0b001000) # ䷏
binary_hexagrams.append(0b011001) # ䷐
binary_hexagrams.append(0b100110) # ䷑
binary_hexagrams.append(0b000011) # ䷒
binary_hexagrams.append(0b110000) # ䷓
binary_hexagrams.append(0b101001) # ䷔
binary_hexagrams.append(0b100101) # ䷕
binary_hexagrams.append(0b100000) # ䷖
binary_hexagrams.append(0b000001) # ䷗
binary_hexagrams.append(0b111001) # ䷘
binary_hexagrams.append(0b100111) # ䷙
binary_hexagrams.append(0b100001) # ䷚
binary_hexagrams.append(0b011110) # ䷛
binary_hexagrams.append(0b010010) # ䷜
binary_hexagrams.append(0b101101) # ䷝
binary_hexagrams.append(0b011100) # ䷞
binary_hexagrams.append(0b001110) # ䷟
binary_hexagrams.append(0b111100) # ䷠
binary_hexagrams.append(0b001111) # ䷡
binary_hexagrams.append(0b101000) # ䷢
binary_hexagrams.append(0b000101) # ䷣
binary_hexagrams.append(0b110101) # ䷤
binary_hexagrams.append(0b101011) # ䷥
binary_hexagrams.append(0b010100) # ䷦
binary_hexagrams.append(0b001010) # ䷧
binary_hexagrams.append(0b100011) # ䷨
binary_hexagrams.append(0b110001) # ䷩
binary_hexagrams.append(0b011111) # ䷪
binary_hexagrams.append(0b111110) # ䷫
binary_hexagrams.append(0b011000) # ䷬
binary_hexagrams.append(0b000110) # ䷭
binary_hexagrams.append(0b011010) # ䷮
binary_hexagrams.append(0b010110) # ䷯
binary_hexagrams.append(0b011101) # ䷰
binary_hexagrams.append(0b101110) # ䷱
binary_hexagrams.append(0b001001) # ䷲
binary_hexagrams.append(0b100100) # ䷳
binary_hexagrams.append(0b110100) # ䷴
binary_hexagrams.append(0b001011) # ䷵
binary_hexagrams.append(0b001101) # ䷶
binary_hexagrams.append(0b101100) # ䷷
binary_hexagrams.append(0b110110) # ䷸
binary_hexagrams.append(0b011011) # ䷹
binary_hexagrams.append(0b110010) # ䷺
binary_hexagrams.append(0b010011) # ䷻
binary_hexagrams.append(0b110011) # ䷼
binary_hexagrams.append(0b001100) # ䷽
binary_hexagrams.append(0b010101) # ䷾
binary_hexagrams.append(0b101010) # ䷿ Element 63; sequence 64

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

for index in range(0, 64, 2):
    if(binary_hexagrams[index] == reverse_6bit(binary_hexagrams[index+1])):
        reverse_count += 1
        print(str(index+1).zfill(2) + " ", end="")
        print(unicode_hexagrams[index], end="")
        print(" Reverse ", end="")
        print(str(index+2).zfill(2) + " ", end="")
        print(unicode_hexagrams[index+1])
    elif (binary_hexagrams[index] == binary_hexagrams[index+1] ^ 0b00111111):
        inverse_count += 1
        print(str(index+1).zfill(2) + " ", end="")
        print(unicode_hexagrams[index], end="")
        print(" Inverse ", end="")
        print(str(index+2).zfill(2) + " ", end="")
        print(unicode_hexagrams[index+1])
    else:
        neither_count += 1
        print(str(index+1).zfill(2) + " ", end="")
        print(unicode_hexagrams[index], end="")
        print(" IS NOT A REVERSE OR INVERSE ", end="")
        print(str(index+2).zfill(2) + " ", end="")
        print(unicode_hexagrams[index+1])

print("---")
# Reverse
print("Reverse count pairs: " + str(reverse_count).zfill(2), end="")
print("/" + str(int(len(binary_hexagrams)/2)) + " (", end="")
print(str(reverse_count/(len(binary_hexagrams)/2)*100) + "%)")
# Inverse
print("Inverse count pairs: " + str(inverse_count).zfill(2), end="")
print("/" + str(int(len(binary_hexagrams)/2)) + " (", end="")
print(str(inverse_count/(len(binary_hexagrams)/2)*100) + "%)")
# Neither
print("Neither count pairs: " + str(neither_count).zfill(2), end="")
print("/" + str(int(len(binary_hexagrams)/2)) + " (", end="")
print(str(neither_count/(len(binary_hexagrams)/2)*100) + "%)")
print("---")
