# TR-8 dof-matched KW-fitting-predicate sampler — run output

Instrument: `solve.py --tr8-dof-sampler`. This file is a RUN RECORD, not a
publication: a number here is citable only under a FROZEN pre-registration, and
the withdrawn TR-8 median is never reinstated by it (CORRECTIONS.md CX-27).

## Seed and probe count (what TR-8 requires published alongside the number)

| parameter | value |
|---|---|
| seed root | `ROAE-TR8-DOFMATCH-2026-08-11` |
| pool | A |
| probe count (N_pool) | 10000000 draws (8 shards x 1250000) |
| predicates per K (N_pred) | 1000 |
| K ladder | 8, 12, 16, 20, 24 |
| calibration draws | 100000 |
| admission band | [0.25, 0.75] |
| B_raw / B_admitted | 319 / 242 |
| admitted-bank sha256 | `65663a14decc7fd03064810a01be93271b112e09f61a4436967ddaba780e4484` |
| geometric-mean admitted marginal | 0.446630 |
| r_KW (exact) | 47/445740 = 1.054426e-04 |

Every seed is `uint64(sha256("<seed root>/<purpose>")[:8], big-endian)`:

| purpose | seed |
|---|---|
| `bank-calibration` | 16808612684394547738 |
| `pool-A/shard-0` | 13125219832949938161 |
| `pool-A/shard-1` | 180824748240221595 |
| `pool-A/shard-2` | 13611947216661545302 |
| `pool-A/shard-3` | 14895033114697523849 |
| `pool-A/shard-4` | 13467026396961934414 |
| `pool-A/shard-5` | 17354032610239031994 |
| `pool-A/shard-6` | 613349725478716716 |
| `pool-A/shard-7` | 1273508160404237185 |
| `predicates/K-12` | 13098566881017873166 |
| `predicates/K-16` | 8433741811206836744 |
| `predicates/K-20` | 4864257483467187375 |
| `predicates/K-24` | 6694891894007310856 |
| `predicates/K-8` | 5773044589811096261 |
| `timing-probe` | 16606691537943803774 |

## Sanity gates

- **H-a** (King Wen satisfies every raw template clause, so every drawn predicate): **PASS**
- **H-b** (the pool reproduces the exact pair-null gender rate): **PASS** — observed 1047, expected 1054.43, binomial sigma 32.47, 4-sigma band [925, 1184]
- **B_raw = 319**: **PASS**; **B_admitted >= 120** (the §3.3(ii) abort floor): **PASS**

## Statistics

`F_hat` = fraction of drawn predicates at least as rare as King Wen (PRIMARY; CI conditional on the shared pool). `m_hat` = median rarity (SECONDARY).

| K | F_hat | 95% CP CI | m_hat | 95% order-stat CI | censored |
|---|---|---|---|---|---|
| 8 | 0.0000 | [0.0000, 0.0037] | 1.8450e-03 | [1.7461e-03, 1.9230e-03] | 0.0% |
| 12 | 0.6370 | [0.6063, 0.6669] | 8.1400e-05 | [7.6700e-05, 8.6900e-05] | 0.0% |
| 16 | 1.0000 | [0.9963, 1.0000] | 3.6000e-06 | [3.4000e-06, 4.1000e-06] | 0.2% |
| 20 | 1.0000 | [0.9963, 1.0000] | 2.0000e-07 | [2.0000e-07, 2.0000e-07] | 23.7% |
| 24 | 1.0000 | [0.9963, 1.0000] | < 1.000e-07 (CENSORED) | [< 1.000e-07, < 1.000e-07] | 83.7% |

Deciles of the rarity distribution (log10; `cens` = below the 1/N_pool floor):

| K | d1 | d2 | d3 | d4 | d5 | d6 | d7 | d8 | d9 |
|---|---|---|---|---|---|---|---|---|---|
| 8 | -3.07 | -2.97 | -2.88 | -2.81 | -2.73 | -2.68 | -2.61 | -2.53 | -2.43 |
| 12 | -4.60 | -4.43 | -4.29 | -4.18 | -4.09 | -4.01 | -3.92 | -3.83 | -3.68 |
| 16 | -6.00 | -5.80 | -5.62 | -5.52 | -5.44 | -5.31 | -5.19 | -5.04 | -4.87 |
| 20 | cens | cens | -7.00 | -7.00 | -6.70 | -6.52 | -6.40 | -6.30 | -6.10 |
| 24 | cens | cens | cens | cens | cens | cens | cens | cens | -7.00 |

Threshold H = floor(N_pool · 47/445740) = 1054: a predicate is at least as rare as King Wen iff hits <= H.

Ensemble context (from the frozen predicate seeds): mean pairwise clause overlap |P ∩ Q| over all predicate pairs, its K²/B_admitted reference, and the family composition of the drawn clause slots:

| K | mean overlap | K²/B_adm | family composition |
|---|---|---|---|
| 8 | 0.263 | 0.264 | A=1197, B=2155, C=882, D=1014, F=384, G=169, H=2112, I=87 |
| 12 | 0.596 | 0.595 | A=1760, B=3187, C=1385, D=1542, F=607, G=251, H=3159, I=109 |
| 16 | 1.058 | 1.058 | A=2350, B=4322, C=1869, D=2111, F=728, G=349, H=4121, I=150 |
| 20 | 1.653 | 1.653 | A=2949, B=5256, C=2366, D=2568, F=978, G=438, H=5298, I=147 |
| 24 | 2.382 | 2.380 | A=3644, B=6281, C=2835, D=3027, F=1180, G=523, H=6299, I=211 |

**D1 (pre-registered rule on F_hat, headline K = 16): COMMON** — CI(F_hat) lies entirely above 0.95. **D2 (the median deliverable at K = 16): UNCENSORED** — D2 never alters D1.

## Admitted clause bank

| clause | marginal | template (instantiated at King Wen's own value) |
|---|---|---|
| A1 | 0.34604 | gender label at inversion-class position 1 == exempt | 
| A2 | 0.33304 | gender label at inversion-class position 2 == exempt | 
| A3 | 0.33486 | gender label at inversion-class position 3 == male | 
| A4 | 0.33457 | gender label at inversion-class position 4 == female | 
| A5 | 0.33414 | gender label at inversion-class position 5 == male | 
| A6 | 0.33275 | gender label at inversion-class position 6 == female | 
| A7 | 0.33370 | gender label at inversion-class position 7 == exempt | 
| A8 | 0.33424 | gender label at inversion-class position 8 == female | 
| A9 | 0.33246 | gender label at inversion-class position 9 == male | 
| A10 | 0.33118 | gender label at inversion-class position 10 == exempt | 
| A11 | 0.33668 | gender label at inversion-class position 11 == male | 
| A12 | 0.33244 | gender label at inversion-class position 12 == exempt | 
| A13 | 0.33365 | gender label at inversion-class position 13 == male | 
| A14 | 0.33315 | gender label at inversion-class position 14 == female | 
| A15 | 0.33259 | gender label at inversion-class position 15 == male | 
| A16 | 0.33526 | gender label at inversion-class position 16 == female | 
| A17 | 0.33555 | gender label at inversion-class position 17 == male | 
| A18 | 0.33278 | gender label at inversion-class position 18 == female | 
| A19 | 0.33258 | gender label at inversion-class position 19 == exempt | 
| A20 | 0.33398 | gender label at inversion-class position 20 == female | 
| A21 | 0.33542 | gender label at inversion-class position 21 == male | 
| A22 | 0.33248 | gender label at inversion-class position 22 == female | 
| A23 | 0.33474 | gender label at inversion-class position 23 == male | 
| A24 | 0.33495 | gender label at inversion-class position 24 == exempt | 
| A25 | 0.33342 | gender label at inversion-class position 25 == female | 
| A26 | 0.33078 | gender label at inversion-class position 26 == male | 
| A27 | 0.33392 | gender label at inversion-class position 27 == exempt | 
| A28 | 0.33154 | gender label at inversion-class position 28 == female | 
| A29 | 0.33188 | gender label at inversion-class position 29 == male | 
| A30 | 0.33238 | gender label at inversion-class position 30 == exempt | 
| A31 | 0.33365 | gender label at inversion-class position 31 == exempt | 
| A32 | 0.33361 | gender label at inversion-class position 32 == female | 
| A33 | 0.33279 | gender label at inversion-class position 33 == exempt | 
| A34 | 0.33379 | gender label at inversion-class position 34 == female | 
| A35 | 0.33373 | gender label at inversion-class position 35 == male | 
| A36 | 0.34255 | gender label at inversion-class position 36 == exempt | 
| B1 | 0.49585 | popcount parity at position 1 == 0 | 
| B2 | 0.49585 | popcount parity at position 2 == 0 | 
| B3 | 0.49881 | popcount parity at position 3 == 0 | 
| B4 | 0.49881 | popcount parity at position 4 == 0 | 
| B5 | 0.50025 | popcount parity at position 5 == 0 | 
| B6 | 0.50025 | popcount parity at position 6 == 0 | 
| B7 | 0.49871 | popcount parity at position 7 == 1 | 
| B8 | 0.49871 | popcount parity at position 8 == 1 | 
| B9 | 0.50063 | popcount parity at position 9 == 1 | 
| B10 | 0.50063 | popcount parity at position 10 == 1 | 
| B11 | 0.50085 | popcount parity at position 11 == 1 | 
| B12 | 0.50085 | popcount parity at position 12 == 1 | 
| B13 | 0.49948 | popcount parity at position 13 == 1 | 
| B14 | 0.49948 | popcount parity at position 14 == 1 | 
| B15 | 0.50135 | popcount parity at position 15 == 1 | 
| B16 | 0.50135 | popcount parity at position 16 == 1 | 
| B17 | 0.49966 | popcount parity at position 17 == 1 | 
| B18 | 0.49966 | popcount parity at position 18 == 1 | 
| B19 | 0.49862 | popcount parity at position 19 == 0 | 
| B20 | 0.49862 | popcount parity at position 20 == 0 | 
| B21 | 0.50102 | popcount parity at position 21 == 1 | 
| B22 | 0.50102 | popcount parity at position 22 == 1 | 
| B23 | 0.49989 | popcount parity at position 23 == 1 | 
| B24 | 0.49989 | popcount parity at position 24 == 1 | 
| B25 | 0.50132 | popcount parity at position 25 == 0 | 
| B26 | 0.50132 | popcount parity at position 26 == 0 | 
| B27 | 0.50176 | popcount parity at position 27 == 0 | 
| B28 | 0.50176 | popcount parity at position 28 == 0 | 
| B29 | 0.50332 | popcount parity at position 29 == 0 | 
| B30 | 0.50332 | popcount parity at position 30 == 0 | 
| B31 | 0.50038 | popcount parity at position 31 == 1 | 
| B32 | 0.50038 | popcount parity at position 32 == 1 | 
| B33 | 0.50065 | popcount parity at position 33 == 0 | 
| B34 | 0.50065 | popcount parity at position 34 == 0 | 
| B35 | 0.50136 | popcount parity at position 35 == 0 | 
| B36 | 0.50136 | popcount parity at position 36 == 0 | 
| B37 | 0.50069 | popcount parity at position 37 == 0 | 
| B38 | 0.50069 | popcount parity at position 38 == 0 | 
| B39 | 0.49799 | popcount parity at position 39 == 0 | 
| B40 | 0.49799 | popcount parity at position 40 == 0 | 
| B41 | 0.49868 | popcount parity at position 41 == 1 | 
| B42 | 0.49868 | popcount parity at position 42 == 1 | 
| B43 | 0.50305 | popcount parity at position 43 == 1 | 
| B44 | 0.50305 | popcount parity at position 44 == 1 | 
| B45 | 0.49893 | popcount parity at position 45 == 0 | 
| B46 | 0.49893 | popcount parity at position 46 == 0 | 
| B47 | 0.50238 | popcount parity at position 47 == 1 | 
| B48 | 0.50238 | popcount parity at position 48 == 1 | 
| B49 | 0.50123 | popcount parity at position 49 == 0 | 
| B50 | 0.50123 | popcount parity at position 50 == 0 | 
| B51 | 0.50051 | popcount parity at position 51 == 0 | 
| B52 | 0.50051 | popcount parity at position 52 == 0 | 
| B53 | 0.50030 | popcount parity at position 53 == 1 | 
| B54 | 0.50030 | popcount parity at position 54 == 1 | 
| B55 | 0.49821 | popcount parity at position 55 == 1 | 
| B56 | 0.49821 | popcount parity at position 56 == 1 | 
| B57 | 0.50210 | popcount parity at position 57 == 0 | 
| B58 | 0.50210 | popcount parity at position 58 == 0 | 
| B59 | 0.49967 | popcount parity at position 59 == 1 | 
| B60 | 0.49967 | popcount parity at position 60 == 1 | 
| B61 | 0.50089 | popcount parity at position 61 == 0 | 
| B62 | 0.50089 | popcount parity at position 62 == 0 | 
| B63 | 0.50002 | popcount parity at position 63 == 1 | 
| B64 | 0.50002 | popcount parity at position 64 == 1 | 
| C1 | 0.25140 | within-pair Hamming distance at slot 1 == 6 | 
| C2 | 0.37388 | within-pair Hamming distance at slot 2 == 4 | 
| C3 | 0.37668 | within-pair Hamming distance at slot 3 == 4 | 
| C4 | 0.37340 | within-pair Hamming distance at slot 4 == 2 | 
| C5 | 0.37440 | within-pair Hamming distance at slot 5 == 2 | 
| C7 | 0.37434 | within-pair Hamming distance at slot 7 == 2 | 
| C8 | 0.37639 | within-pair Hamming distance at slot 8 == 2 | 
| C9 | 0.25263 | within-pair Hamming distance at slot 9 == 6 | 
| C10 | 0.37376 | within-pair Hamming distance at slot 10 == 4 | 
| C11 | 0.37437 | within-pair Hamming distance at slot 11 == 2 | 
| C12 | 0.37551 | within-pair Hamming distance at slot 12 == 2 | 
| C13 | 0.37470 | within-pair Hamming distance at slot 13 == 4 | 
| C15 | 0.25127 | within-pair Hamming distance at slot 15 == 6 | 
| C16 | 0.37508 | within-pair Hamming distance at slot 16 == 2 | 
| C17 | 0.37585 | within-pair Hamming distance at slot 17 == 4 | 
| C18 | 0.37787 | within-pair Hamming distance at slot 18 == 4 | 
| C19 | 0.37574 | within-pair Hamming distance at slot 19 == 4 | 
| C20 | 0.37455 | within-pair Hamming distance at slot 20 == 4 | 
| C21 | 0.37413 | within-pair Hamming distance at slot 21 == 2 | 
| C22 | 0.37740 | within-pair Hamming distance at slot 22 == 2 | 
| C23 | 0.37482 | within-pair Hamming distance at slot 23 == 4 | 
| C24 | 0.37816 | within-pair Hamming distance at slot 24 == 2 | 
| C25 | 0.37667 | within-pair Hamming distance at slot 25 == 4 | 
| C26 | 0.37543 | within-pair Hamming distance at slot 26 == 4 | 
| C27 | 0.25103 | within-pair Hamming distance at slot 27 == 6 | 
| C28 | 0.37373 | within-pair Hamming distance at slot 28 == 2 | 
| C29 | 0.37711 | within-pair Hamming distance at slot 29 == 4 | 
| C30 | 0.37339 | within-pair Hamming distance at slot 30 == 2 | 
| D2 | 0.48468 | parity of seam distance 2 == 0 | 
| D4 | 0.48180 | parity of seam distance 4 == 0 | 
| D6 | 0.51616 | parity of seam distance 6 == 1 | 
| D8 | 0.48272 | parity of seam distance 8 == 0 | 
| D10 | 0.48392 | parity of seam distance 10 == 0 | 
| D12 | 0.48033 | parity of seam distance 12 == 0 | 
| D14 | 0.48465 | parity of seam distance 14 == 0 | 
| D16 | 0.48081 | parity of seam distance 16 == 0 | 
| D18 | 0.51668 | parity of seam distance 18 == 1 | 
| D20 | 0.51528 | parity of seam distance 20 == 1 | 
| D22 | 0.48191 | parity of seam distance 22 == 0 | 
| D24 | 0.51689 | parity of seam distance 24 == 1 | 
| D26 | 0.48830 | parity of seam distance 26 == 0 | 
| D28 | 0.48308 | parity of seam distance 28 == 0 | 
| D30 | 0.51348 | parity of seam distance 30 == 1 | 
| D32 | 0.51383 | parity of seam distance 32 == 1 | 
| D34 | 0.48513 | parity of seam distance 34 == 0 | 
| D36 | 0.48437 | parity of seam distance 36 == 0 | 
| D38 | 0.48612 | parity of seam distance 38 == 0 | 
| D40 | 0.51609 | parity of seam distance 40 == 1 | 
| D42 | 0.48525 | parity of seam distance 42 == 0 | 
| D44 | 0.51682 | parity of seam distance 44 == 1 | 
| D46 | 0.51679 | parity of seam distance 46 == 1 | 
| D48 | 0.51527 | parity of seam distance 48 == 1 | 
| D50 | 0.48718 | parity of seam distance 50 == 0 | 
| D52 | 0.51863 | parity of seam distance 52 == 1 | 
| D54 | 0.48431 | parity of seam distance 54 == 0 | 
| D56 | 0.51713 | parity of seam distance 56 == 1 | 
| D58 | 0.51543 | parity of seam distance 58 == 1 | 
| D60 | 0.51742 | parity of seam distance 60 == 1 | 
| D62 | 0.51443 | parity of seam distance 62 == 1 | 
| F4 | 0.36294 | sign of running yang balance at position 4 == -1 | 
| F8 | 0.40658 | sign of running yang balance at position 8 == -1 | 
| F20 | 0.43112 | sign of running yang balance at position 20 == -1 | 
| F24 | 0.43492 | sign of running yang balance at position 24 == -1 | 
| F28 | 0.43634 | sign of running yang balance at position 28 == -1 | 
| F32 | 0.43700 | sign of running yang balance at position 32 == -1 | 
| F36 | 0.43731 | sign of running yang balance at position 36 == -1 | 
| F40 | 0.43588 | sign of running yang balance at position 40 == -1 | 
| F48 | 0.42876 | sign of running yang balance at position 48 == -1 | 
| F52 | 0.42110 | sign of running yang balance at position 52 == -1 | 
| F56 | 0.40578 | sign of running yang balance at position 56 == -1 | 
| F60 | 0.27365 | sign of running yang balance at position 60 == 0 | 
| G4 | 0.40251 | yang mass of block 4 >= 26 | 
| G5 | 0.59528 | yang mass of block 5 >= 24 | 
| G6 | 0.40718 | yang mass of block 6 >= 26 | 
| G7 | 0.59610 | yang mass of block 7 >= 24 | 
| G8 | 0.40578 | yang mass of block 8 >= 26 | 
| H1 | 0.49759 | lower-trigram yang-majority class at position 1 == 1 | 
| H2 | 0.50014 | lower-trigram yang-majority class at position 2 == 0 | 
| H3 | 0.49900 | lower-trigram yang-majority class at position 3 == 0 | 
| H4 | 0.49930 | lower-trigram yang-majority class at position 4 == 0 | 
| H5 | 0.49904 | lower-trigram yang-majority class at position 5 == 1 | 
| H6 | 0.50092 | lower-trigram yang-majority class at position 6 == 0 | 
| H7 | 0.50136 | lower-trigram yang-majority class at position 7 == 0 | 
| H8 | 0.49884 | lower-trigram yang-majority class at position 8 == 0 | 
| H9 | 0.49852 | lower-trigram yang-majority class at position 9 == 1 | 
| H10 | 0.49842 | lower-trigram yang-majority class at position 10 == 1 | 
| H11 | 0.49918 | lower-trigram yang-majority class at position 11 == 1 | 
| H12 | 0.50125 | lower-trigram yang-majority class at position 12 == 0 | 
| H13 | 0.50233 | lower-trigram yang-majority class at position 13 == 1 | 
| H14 | 0.50055 | lower-trigram yang-majority class at position 14 == 1 | 
| H15 | 0.49981 | lower-trigram yang-majority class at position 15 == 0 | 
| H16 | 0.49739 | lower-trigram yang-majority class at position 16 == 0 | 
| H17 | 0.49970 | lower-trigram yang-majority class at position 17 == 0 | 
| H18 | 0.49830 | lower-trigram yang-majority class at position 18 == 1 | 
| H19 | 0.49935 | lower-trigram yang-majority class at position 19 == 1 | 
| H20 | 0.50055 | lower-trigram yang-majority class at position 20 == 0 | 
| H21 | 0.49751 | lower-trigram yang-majority class at position 21 == 0 | 
| H22 | 0.49733 | lower-trigram yang-majority class at position 22 == 1 | 
| H23 | 0.49948 | lower-trigram yang-majority class at position 23 == 0 | 
| H24 | 0.49930 | lower-trigram yang-majority class at position 24 == 0 | 
| H25 | 0.49826 | lower-trigram yang-majority class at position 25 == 0 | 
| H26 | 0.49935 | lower-trigram yang-majority class at position 26 == 1 | 
| H27 | 0.50229 | lower-trigram yang-majority class at position 27 == 0 | 
| H28 | 0.50144 | lower-trigram yang-majority class at position 28 == 1 | 
| H29 | 0.50138 | lower-trigram yang-majority class at position 29 == 0 | 
| H30 | 0.50293 | lower-trigram yang-majority class at position 30 == 1 | 
| H31 | 0.49923 | lower-trigram yang-majority class at position 31 == 0 | 
| H32 | 0.50132 | lower-trigram yang-majority class at position 32 == 1 | 
| H33 | 0.50035 | lower-trigram yang-majority class at position 33 == 0 | 
| H34 | 0.49769 | lower-trigram yang-majority class at position 34 == 1 | 
| H35 | 0.49906 | lower-trigram yang-majority class at position 35 == 0 | 
| H36 | 0.49647 | lower-trigram yang-majority class at position 36 == 1 | 
| H37 | 0.49983 | lower-trigram yang-majority class at position 37 == 1 | 
| H38 | 0.50071 | lower-trigram yang-majority class at position 38 == 1 | 
| H39 | 0.50160 | lower-trigram yang-majority class at position 39 == 0 | 
| H40 | 0.49925 | lower-trigram yang-majority class at position 40 == 0 | 
| H41 | 0.49909 | lower-trigram yang-majority class at position 41 == 1 | 
| H42 | 0.49938 | lower-trigram yang-majority class at position 42 == 0 | 
| H43 | 0.50082 | lower-trigram yang-majority class at position 43 == 1 | 
| H44 | 0.49987 | lower-trigram yang-majority class at position 44 == 1 | 
| H45 | 0.49983 | lower-trigram yang-majority class at position 45 == 0 | 
| H46 | 0.50126 | lower-trigram yang-majority class at position 46 == 1 | 
| H47 | 0.49755 | lower-trigram yang-majority class at position 47 == 0 | 
| H48 | 0.49841 | lower-trigram yang-majority class at position 48 == 1 | 
| H49 | 0.49966 | lower-trigram yang-majority class at position 49 == 1 | 
| H50 | 0.50133 | lower-trigram yang-majority class at position 50 == 1 | 
| H51 | 0.49846 | lower-trigram yang-majority class at position 51 == 0 | 
| H52 | 0.50088 | lower-trigram yang-majority class at position 52 == 0 | 
| H53 | 0.49947 | lower-trigram yang-majority class at position 53 == 0 | 
| H54 | 0.50023 | lower-trigram yang-majority class at position 54 == 1 | 
| H55 | 0.49920 | lower-trigram yang-majority class at position 55 == 1 | 
| H56 | 0.49882 | lower-trigram yang-majority class at position 56 == 0 | 
| H57 | 0.50042 | lower-trigram yang-majority class at position 57 == 1 | 
| H58 | 0.49834 | lower-trigram yang-majority class at position 58 == 1 | 
| H59 | 0.49735 | lower-trigram yang-majority class at position 59 == 0 | 
| H60 | 0.49815 | lower-trigram yang-majority class at position 60 == 1 | 
| H61 | 0.49942 | lower-trigram yang-majority class at position 61 == 1 | 
| H62 | 0.49942 | lower-trigram yang-majority class at position 62 == 0 | 
| H63 | 0.50155 | lower-trigram yang-majority class at position 63 == 1 | 
| H64 | 0.50097 | lower-trigram yang-majority class at position 64 == 0 | 
| I1 | 0.25348 | shared_trigram_adjacencies >= 9 | 
| I2 | 0.70721 | par_switch >= 30 | 
