# PRE-REGISTRATION ADDENDUM A2 — TR-8 dof-matched sampler — the admitted clause bank, 2026-10-03, BEFORE any pool draw (§3.3(ii), §5(b); form fixed by ADDENDUM A1 §A1.5)

Generated mechanically by the run kit (`kit.py bankpost`) from `bank.json`; the only human act is appending it. Frozen file sha256 `4b307f07767199b746e770cfa595a3153519a57cdc2043843d9019f71683d2f5`; A1 is the public `documentation/PREREG_TR8_DOF_MATCHED_SAMPLER_20260811_ADDENDUM_A1_20261003.md`.

- Instrument: public `solve.py` at commit `35782834ea709969910419cce4e739da39dac19f`, solve.py sha256 `38f3f886dcfed34b36fe5be4de17b2ed5363c719a63d3bde634934738aa4b609` (the A1 §A1.1 byte pin); interpreter CPython 3.12.3.
- Calibration: seed root `ROAE-TR8-DOFMATCH-2026-08-11`, 100000 draws, calibration seed `16808612684394547738`; band [0.25, 0.75], closed.
- B_raw = 319; **B_admitted = 242** (abort floor 120); admitted by family: A=36, B=64, C=28, D=31, F=12, G=5, H=64, I=2.
- Admitted-bank sha256 (the expression solve.py writes into header.json): `65663a14decc7fd03064810a01be93271b112e09f61a4436967ddaba780e4484`.
- Conformance (A1 §A1.3(k)) on the identical calibration stream, code vs the text's 319 extractors: divergent instances: none; comparator mismatches: none; admitted set identical under the text's extractors: yes. (Any value other than none/none/yes halts the run before any pool draw.)
- Knife-edge instances (A1 §A1.3(i)): the 8 family-C instances at distance-6 slots have true marginal 0.25; admitted here: 4 of 8 (measured q̂ >= 0.25 on this calibration).
- No instance dropped. No instance added. No rarity has been computed.

| # | clause | cmp | q̂ | template (instantiated at King Wen's value) |
|---|---|---|---|---|
| 1 | A1 | EQ | 0.34604 | gender label at inversion-class position 1 == exempt |
| 2 | A2 | EQ | 0.33304 | gender label at inversion-class position 2 == exempt |
| 3 | A3 | EQ | 0.33486 | gender label at inversion-class position 3 == male |
| 4 | A4 | EQ | 0.33457 | gender label at inversion-class position 4 == female |
| 5 | A5 | EQ | 0.33414 | gender label at inversion-class position 5 == male |
| 6 | A6 | EQ | 0.33275 | gender label at inversion-class position 6 == female |
| 7 | A7 | EQ | 0.33370 | gender label at inversion-class position 7 == exempt |
| 8 | A8 | EQ | 0.33424 | gender label at inversion-class position 8 == female |
| 9 | A9 | EQ | 0.33246 | gender label at inversion-class position 9 == male |
| 10 | A10 | EQ | 0.33118 | gender label at inversion-class position 10 == exempt |
| 11 | A11 | EQ | 0.33668 | gender label at inversion-class position 11 == male |
| 12 | A12 | EQ | 0.33244 | gender label at inversion-class position 12 == exempt |
| 13 | A13 | EQ | 0.33365 | gender label at inversion-class position 13 == male |
| 14 | A14 | EQ | 0.33315 | gender label at inversion-class position 14 == female |
| 15 | A15 | EQ | 0.33259 | gender label at inversion-class position 15 == male |
| 16 | A16 | EQ | 0.33526 | gender label at inversion-class position 16 == female |
| 17 | A17 | EQ | 0.33555 | gender label at inversion-class position 17 == male |
| 18 | A18 | EQ | 0.33278 | gender label at inversion-class position 18 == female |
| 19 | A19 | EQ | 0.33258 | gender label at inversion-class position 19 == exempt |
| 20 | A20 | EQ | 0.33398 | gender label at inversion-class position 20 == female |
| 21 | A21 | EQ | 0.33542 | gender label at inversion-class position 21 == male |
| 22 | A22 | EQ | 0.33248 | gender label at inversion-class position 22 == female |
| 23 | A23 | EQ | 0.33474 | gender label at inversion-class position 23 == male |
| 24 | A24 | EQ | 0.33495 | gender label at inversion-class position 24 == exempt |
| 25 | A25 | EQ | 0.33342 | gender label at inversion-class position 25 == female |
| 26 | A26 | EQ | 0.33078 | gender label at inversion-class position 26 == male |
| 27 | A27 | EQ | 0.33392 | gender label at inversion-class position 27 == exempt |
| 28 | A28 | EQ | 0.33154 | gender label at inversion-class position 28 == female |
| 29 | A29 | EQ | 0.33188 | gender label at inversion-class position 29 == male |
| 30 | A30 | EQ | 0.33238 | gender label at inversion-class position 30 == exempt |
| 31 | A31 | EQ | 0.33365 | gender label at inversion-class position 31 == exempt |
| 32 | A32 | EQ | 0.33361 | gender label at inversion-class position 32 == female |
| 33 | A33 | EQ | 0.33279 | gender label at inversion-class position 33 == exempt |
| 34 | A34 | EQ | 0.33379 | gender label at inversion-class position 34 == female |
| 35 | A35 | EQ | 0.33373 | gender label at inversion-class position 35 == male |
| 36 | A36 | EQ | 0.34255 | gender label at inversion-class position 36 == exempt |
| 37 | B1 | EQ | 0.49585 | popcount parity at position 1 == 0 |
| 38 | B2 | EQ | 0.49585 | popcount parity at position 2 == 0 |
| 39 | B3 | EQ | 0.49881 | popcount parity at position 3 == 0 |
| 40 | B4 | EQ | 0.49881 | popcount parity at position 4 == 0 |
| 41 | B5 | EQ | 0.50025 | popcount parity at position 5 == 0 |
| 42 | B6 | EQ | 0.50025 | popcount parity at position 6 == 0 |
| 43 | B7 | EQ | 0.49871 | popcount parity at position 7 == 1 |
| 44 | B8 | EQ | 0.49871 | popcount parity at position 8 == 1 |
| 45 | B9 | EQ | 0.50063 | popcount parity at position 9 == 1 |
| 46 | B10 | EQ | 0.50063 | popcount parity at position 10 == 1 |
| 47 | B11 | EQ | 0.50085 | popcount parity at position 11 == 1 |
| 48 | B12 | EQ | 0.50085 | popcount parity at position 12 == 1 |
| 49 | B13 | EQ | 0.49948 | popcount parity at position 13 == 1 |
| 50 | B14 | EQ | 0.49948 | popcount parity at position 14 == 1 |
| 51 | B15 | EQ | 0.50135 | popcount parity at position 15 == 1 |
| 52 | B16 | EQ | 0.50135 | popcount parity at position 16 == 1 |
| 53 | B17 | EQ | 0.49966 | popcount parity at position 17 == 1 |
| 54 | B18 | EQ | 0.49966 | popcount parity at position 18 == 1 |
| 55 | B19 | EQ | 0.49862 | popcount parity at position 19 == 0 |
| 56 | B20 | EQ | 0.49862 | popcount parity at position 20 == 0 |
| 57 | B21 | EQ | 0.50102 | popcount parity at position 21 == 1 |
| 58 | B22 | EQ | 0.50102 | popcount parity at position 22 == 1 |
| 59 | B23 | EQ | 0.49989 | popcount parity at position 23 == 1 |
| 60 | B24 | EQ | 0.49989 | popcount parity at position 24 == 1 |
| 61 | B25 | EQ | 0.50132 | popcount parity at position 25 == 0 |
| 62 | B26 | EQ | 0.50132 | popcount parity at position 26 == 0 |
| 63 | B27 | EQ | 0.50176 | popcount parity at position 27 == 0 |
| 64 | B28 | EQ | 0.50176 | popcount parity at position 28 == 0 |
| 65 | B29 | EQ | 0.50332 | popcount parity at position 29 == 0 |
| 66 | B30 | EQ | 0.50332 | popcount parity at position 30 == 0 |
| 67 | B31 | EQ | 0.50038 | popcount parity at position 31 == 1 |
| 68 | B32 | EQ | 0.50038 | popcount parity at position 32 == 1 |
| 69 | B33 | EQ | 0.50065 | popcount parity at position 33 == 0 |
| 70 | B34 | EQ | 0.50065 | popcount parity at position 34 == 0 |
| 71 | B35 | EQ | 0.50136 | popcount parity at position 35 == 0 |
| 72 | B36 | EQ | 0.50136 | popcount parity at position 36 == 0 |
| 73 | B37 | EQ | 0.50069 | popcount parity at position 37 == 0 |
| 74 | B38 | EQ | 0.50069 | popcount parity at position 38 == 0 |
| 75 | B39 | EQ | 0.49799 | popcount parity at position 39 == 0 |
| 76 | B40 | EQ | 0.49799 | popcount parity at position 40 == 0 |
| 77 | B41 | EQ | 0.49868 | popcount parity at position 41 == 1 |
| 78 | B42 | EQ | 0.49868 | popcount parity at position 42 == 1 |
| 79 | B43 | EQ | 0.50305 | popcount parity at position 43 == 1 |
| 80 | B44 | EQ | 0.50305 | popcount parity at position 44 == 1 |
| 81 | B45 | EQ | 0.49893 | popcount parity at position 45 == 0 |
| 82 | B46 | EQ | 0.49893 | popcount parity at position 46 == 0 |
| 83 | B47 | EQ | 0.50238 | popcount parity at position 47 == 1 |
| 84 | B48 | EQ | 0.50238 | popcount parity at position 48 == 1 |
| 85 | B49 | EQ | 0.50123 | popcount parity at position 49 == 0 |
| 86 | B50 | EQ | 0.50123 | popcount parity at position 50 == 0 |
| 87 | B51 | EQ | 0.50051 | popcount parity at position 51 == 0 |
| 88 | B52 | EQ | 0.50051 | popcount parity at position 52 == 0 |
| 89 | B53 | EQ | 0.50030 | popcount parity at position 53 == 1 |
| 90 | B54 | EQ | 0.50030 | popcount parity at position 54 == 1 |
| 91 | B55 | EQ | 0.49821 | popcount parity at position 55 == 1 |
| 92 | B56 | EQ | 0.49821 | popcount parity at position 56 == 1 |
| 93 | B57 | EQ | 0.50210 | popcount parity at position 57 == 0 |
| 94 | B58 | EQ | 0.50210 | popcount parity at position 58 == 0 |
| 95 | B59 | EQ | 0.49967 | popcount parity at position 59 == 1 |
| 96 | B60 | EQ | 0.49967 | popcount parity at position 60 == 1 |
| 97 | B61 | EQ | 0.50089 | popcount parity at position 61 == 0 |
| 98 | B62 | EQ | 0.50089 | popcount parity at position 62 == 0 |
| 99 | B63 | EQ | 0.50002 | popcount parity at position 63 == 1 |
| 100 | B64 | EQ | 0.50002 | popcount parity at position 64 == 1 |
| 101 | C1 | EQ | 0.25140 | within-pair Hamming distance at slot 1 == 6 |
| 102 | C2 | EQ | 0.37388 | within-pair Hamming distance at slot 2 == 4 |
| 103 | C3 | EQ | 0.37668 | within-pair Hamming distance at slot 3 == 4 |
| 104 | C4 | EQ | 0.37340 | within-pair Hamming distance at slot 4 == 2 |
| 105 | C5 | EQ | 0.37440 | within-pair Hamming distance at slot 5 == 2 |
| 106 | C7 | EQ | 0.37434 | within-pair Hamming distance at slot 7 == 2 |
| 107 | C8 | EQ | 0.37639 | within-pair Hamming distance at slot 8 == 2 |
| 108 | C9 | EQ | 0.25263 | within-pair Hamming distance at slot 9 == 6 |
| 109 | C10 | EQ | 0.37376 | within-pair Hamming distance at slot 10 == 4 |
| 110 | C11 | EQ | 0.37437 | within-pair Hamming distance at slot 11 == 2 |
| 111 | C12 | EQ | 0.37551 | within-pair Hamming distance at slot 12 == 2 |
| 112 | C13 | EQ | 0.37470 | within-pair Hamming distance at slot 13 == 4 |
| 113 | C15 | EQ | 0.25127 | within-pair Hamming distance at slot 15 == 6 |
| 114 | C16 | EQ | 0.37508 | within-pair Hamming distance at slot 16 == 2 |
| 115 | C17 | EQ | 0.37585 | within-pair Hamming distance at slot 17 == 4 |
| 116 | C18 | EQ | 0.37787 | within-pair Hamming distance at slot 18 == 4 |
| 117 | C19 | EQ | 0.37574 | within-pair Hamming distance at slot 19 == 4 |
| 118 | C20 | EQ | 0.37455 | within-pair Hamming distance at slot 20 == 4 |
| 119 | C21 | EQ | 0.37413 | within-pair Hamming distance at slot 21 == 2 |
| 120 | C22 | EQ | 0.37740 | within-pair Hamming distance at slot 22 == 2 |
| 121 | C23 | EQ | 0.37482 | within-pair Hamming distance at slot 23 == 4 |
| 122 | C24 | EQ | 0.37816 | within-pair Hamming distance at slot 24 == 2 |
| 123 | C25 | EQ | 0.37667 | within-pair Hamming distance at slot 25 == 4 |
| 124 | C26 | EQ | 0.37543 | within-pair Hamming distance at slot 26 == 4 |
| 125 | C27 | EQ | 0.25103 | within-pair Hamming distance at slot 27 == 6 |
| 126 | C28 | EQ | 0.37373 | within-pair Hamming distance at slot 28 == 2 |
| 127 | C29 | EQ | 0.37711 | within-pair Hamming distance at slot 29 == 4 |
| 128 | C30 | EQ | 0.37339 | within-pair Hamming distance at slot 30 == 2 |
| 129 | D2 | EQ | 0.48468 | parity of seam distance 2 == 0 |
| 130 | D4 | EQ | 0.48180 | parity of seam distance 4 == 0 |
| 131 | D6 | EQ | 0.51616 | parity of seam distance 6 == 1 |
| 132 | D8 | EQ | 0.48272 | parity of seam distance 8 == 0 |
| 133 | D10 | EQ | 0.48392 | parity of seam distance 10 == 0 |
| 134 | D12 | EQ | 0.48033 | parity of seam distance 12 == 0 |
| 135 | D14 | EQ | 0.48465 | parity of seam distance 14 == 0 |
| 136 | D16 | EQ | 0.48081 | parity of seam distance 16 == 0 |
| 137 | D18 | EQ | 0.51668 | parity of seam distance 18 == 1 |
| 138 | D20 | EQ | 0.51528 | parity of seam distance 20 == 1 |
| 139 | D22 | EQ | 0.48191 | parity of seam distance 22 == 0 |
| 140 | D24 | EQ | 0.51689 | parity of seam distance 24 == 1 |
| 141 | D26 | EQ | 0.48830 | parity of seam distance 26 == 0 |
| 142 | D28 | EQ | 0.48308 | parity of seam distance 28 == 0 |
| 143 | D30 | EQ | 0.51348 | parity of seam distance 30 == 1 |
| 144 | D32 | EQ | 0.51383 | parity of seam distance 32 == 1 |
| 145 | D34 | EQ | 0.48513 | parity of seam distance 34 == 0 |
| 146 | D36 | EQ | 0.48437 | parity of seam distance 36 == 0 |
| 147 | D38 | EQ | 0.48612 | parity of seam distance 38 == 0 |
| 148 | D40 | EQ | 0.51609 | parity of seam distance 40 == 1 |
| 149 | D42 | EQ | 0.48525 | parity of seam distance 42 == 0 |
| 150 | D44 | EQ | 0.51682 | parity of seam distance 44 == 1 |
| 151 | D46 | EQ | 0.51679 | parity of seam distance 46 == 1 |
| 152 | D48 | EQ | 0.51527 | parity of seam distance 48 == 1 |
| 153 | D50 | EQ | 0.48718 | parity of seam distance 50 == 0 |
| 154 | D52 | EQ | 0.51863 | parity of seam distance 52 == 1 |
| 155 | D54 | EQ | 0.48431 | parity of seam distance 54 == 0 |
| 156 | D56 | EQ | 0.51713 | parity of seam distance 56 == 1 |
| 157 | D58 | EQ | 0.51543 | parity of seam distance 58 == 1 |
| 158 | D60 | EQ | 0.51742 | parity of seam distance 60 == 1 |
| 159 | D62 | EQ | 0.51443 | parity of seam distance 62 == 1 |
| 160 | F4 | EQ | 0.36294 | sign of running yang balance at position 4 == -1 |
| 161 | F8 | EQ | 0.40658 | sign of running yang balance at position 8 == -1 |
| 162 | F20 | EQ | 0.43112 | sign of running yang balance at position 20 == -1 |
| 163 | F24 | EQ | 0.43492 | sign of running yang balance at position 24 == -1 |
| 164 | F28 | EQ | 0.43634 | sign of running yang balance at position 28 == -1 |
| 165 | F32 | EQ | 0.43700 | sign of running yang balance at position 32 == -1 |
| 166 | F36 | EQ | 0.43731 | sign of running yang balance at position 36 == -1 |
| 167 | F40 | EQ | 0.43588 | sign of running yang balance at position 40 == -1 |
| 168 | F48 | EQ | 0.42876 | sign of running yang balance at position 48 == -1 |
| 169 | F52 | EQ | 0.42110 | sign of running yang balance at position 52 == -1 |
| 170 | F56 | EQ | 0.40578 | sign of running yang balance at position 56 == -1 |
| 171 | F60 | EQ | 0.27365 | sign of running yang balance at position 60 == 0 |
| 172 | G4 | GE | 0.40251 | yang mass of block 4 >= 26 |
| 173 | G5 | GE | 0.59528 | yang mass of block 5 >= 24 |
| 174 | G6 | GE | 0.40718 | yang mass of block 6 >= 26 |
| 175 | G7 | GE | 0.59610 | yang mass of block 7 >= 24 |
| 176 | G8 | GE | 0.40578 | yang mass of block 8 >= 26 |
| 177 | H1 | EQ | 0.49759 | lower-trigram yang-majority class at position 1 == 1 |
| 178 | H2 | EQ | 0.50014 | lower-trigram yang-majority class at position 2 == 0 |
| 179 | H3 | EQ | 0.49900 | lower-trigram yang-majority class at position 3 == 0 |
| 180 | H4 | EQ | 0.49930 | lower-trigram yang-majority class at position 4 == 0 |
| 181 | H5 | EQ | 0.49904 | lower-trigram yang-majority class at position 5 == 1 |
| 182 | H6 | EQ | 0.50092 | lower-trigram yang-majority class at position 6 == 0 |
| 183 | H7 | EQ | 0.50136 | lower-trigram yang-majority class at position 7 == 0 |
| 184 | H8 | EQ | 0.49884 | lower-trigram yang-majority class at position 8 == 0 |
| 185 | H9 | EQ | 0.49852 | lower-trigram yang-majority class at position 9 == 1 |
| 186 | H10 | EQ | 0.49842 | lower-trigram yang-majority class at position 10 == 1 |
| 187 | H11 | EQ | 0.49918 | lower-trigram yang-majority class at position 11 == 1 |
| 188 | H12 | EQ | 0.50125 | lower-trigram yang-majority class at position 12 == 0 |
| 189 | H13 | EQ | 0.50233 | lower-trigram yang-majority class at position 13 == 1 |
| 190 | H14 | EQ | 0.50055 | lower-trigram yang-majority class at position 14 == 1 |
| 191 | H15 | EQ | 0.49981 | lower-trigram yang-majority class at position 15 == 0 |
| 192 | H16 | EQ | 0.49739 | lower-trigram yang-majority class at position 16 == 0 |
| 193 | H17 | EQ | 0.49970 | lower-trigram yang-majority class at position 17 == 0 |
| 194 | H18 | EQ | 0.49830 | lower-trigram yang-majority class at position 18 == 1 |
| 195 | H19 | EQ | 0.49935 | lower-trigram yang-majority class at position 19 == 1 |
| 196 | H20 | EQ | 0.50055 | lower-trigram yang-majority class at position 20 == 0 |
| 197 | H21 | EQ | 0.49751 | lower-trigram yang-majority class at position 21 == 0 |
| 198 | H22 | EQ | 0.49733 | lower-trigram yang-majority class at position 22 == 1 |
| 199 | H23 | EQ | 0.49948 | lower-trigram yang-majority class at position 23 == 0 |
| 200 | H24 | EQ | 0.49930 | lower-trigram yang-majority class at position 24 == 0 |
| 201 | H25 | EQ | 0.49826 | lower-trigram yang-majority class at position 25 == 0 |
| 202 | H26 | EQ | 0.49935 | lower-trigram yang-majority class at position 26 == 1 |
| 203 | H27 | EQ | 0.50229 | lower-trigram yang-majority class at position 27 == 0 |
| 204 | H28 | EQ | 0.50144 | lower-trigram yang-majority class at position 28 == 1 |
| 205 | H29 | EQ | 0.50138 | lower-trigram yang-majority class at position 29 == 0 |
| 206 | H30 | EQ | 0.50293 | lower-trigram yang-majority class at position 30 == 1 |
| 207 | H31 | EQ | 0.49923 | lower-trigram yang-majority class at position 31 == 0 |
| 208 | H32 | EQ | 0.50132 | lower-trigram yang-majority class at position 32 == 1 |
| 209 | H33 | EQ | 0.50035 | lower-trigram yang-majority class at position 33 == 0 |
| 210 | H34 | EQ | 0.49769 | lower-trigram yang-majority class at position 34 == 1 |
| 211 | H35 | EQ | 0.49906 | lower-trigram yang-majority class at position 35 == 0 |
| 212 | H36 | EQ | 0.49647 | lower-trigram yang-majority class at position 36 == 1 |
| 213 | H37 | EQ | 0.49983 | lower-trigram yang-majority class at position 37 == 1 |
| 214 | H38 | EQ | 0.50071 | lower-trigram yang-majority class at position 38 == 1 |
| 215 | H39 | EQ | 0.50160 | lower-trigram yang-majority class at position 39 == 0 |
| 216 | H40 | EQ | 0.49925 | lower-trigram yang-majority class at position 40 == 0 |
| 217 | H41 | EQ | 0.49909 | lower-trigram yang-majority class at position 41 == 1 |
| 218 | H42 | EQ | 0.49938 | lower-trigram yang-majority class at position 42 == 0 |
| 219 | H43 | EQ | 0.50082 | lower-trigram yang-majority class at position 43 == 1 |
| 220 | H44 | EQ | 0.49987 | lower-trigram yang-majority class at position 44 == 1 |
| 221 | H45 | EQ | 0.49983 | lower-trigram yang-majority class at position 45 == 0 |
| 222 | H46 | EQ | 0.50126 | lower-trigram yang-majority class at position 46 == 1 |
| 223 | H47 | EQ | 0.49755 | lower-trigram yang-majority class at position 47 == 0 |
| 224 | H48 | EQ | 0.49841 | lower-trigram yang-majority class at position 48 == 1 |
| 225 | H49 | EQ | 0.49966 | lower-trigram yang-majority class at position 49 == 1 |
| 226 | H50 | EQ | 0.50133 | lower-trigram yang-majority class at position 50 == 1 |
| 227 | H51 | EQ | 0.49846 | lower-trigram yang-majority class at position 51 == 0 |
| 228 | H52 | EQ | 0.50088 | lower-trigram yang-majority class at position 52 == 0 |
| 229 | H53 | EQ | 0.49947 | lower-trigram yang-majority class at position 53 == 0 |
| 230 | H54 | EQ | 0.50023 | lower-trigram yang-majority class at position 54 == 1 |
| 231 | H55 | EQ | 0.49920 | lower-trigram yang-majority class at position 55 == 1 |
| 232 | H56 | EQ | 0.49882 | lower-trigram yang-majority class at position 56 == 0 |
| 233 | H57 | EQ | 0.50042 | lower-trigram yang-majority class at position 57 == 1 |
| 234 | H58 | EQ | 0.49834 | lower-trigram yang-majority class at position 58 == 1 |
| 235 | H59 | EQ | 0.49735 | lower-trigram yang-majority class at position 59 == 0 |
| 236 | H60 | EQ | 0.49815 | lower-trigram yang-majority class at position 60 == 1 |
| 237 | H61 | EQ | 0.49942 | lower-trigram yang-majority class at position 61 == 1 |
| 238 | H62 | EQ | 0.49942 | lower-trigram yang-majority class at position 62 == 0 |
| 239 | H63 | EQ | 0.50155 | lower-trigram yang-majority class at position 63 == 1 |
| 240 | H64 | EQ | 0.50097 | lower-trigram yang-majority class at position 64 == 0 |
| 241 | I1 | GE | 0.25348 | shared_trigram_adjacencies >= 9 |
| 242 | I2 | GE | 0.70721 | par_switch >= 30 |
