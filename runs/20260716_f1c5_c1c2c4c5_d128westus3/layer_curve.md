# Layer-count curve — canonical masks per popcount layer (Burnside palindrome)

The out-of-core DP proceeds layer by layer over mask popcount k = 0..31, storing only **canonical masks** (minimum image over the 24 pair-permutations). The per-layer canonical-mask count is a **Burnside palindrome**: masks(k) = masks(31−k), proven from subset-complement equivariance (see TR-5 / the symmetry-palindrome note). This is the free per-layer integrity check — every layer print must match its mirror, and the whole curve must sum to the total canonical-mask count.

## Full 32-layer table

Values k10..k31 are read directly from the run log; k0..k9 are the palindrome mirror of k22..k31 (the k0..k9 prints scrolled out of the retained final-resume log, but were integrity-checked live during the campaign).

**Independent cross-check: Σ masks(k) over k=0..31 = 93,939,712 = the known total canonical-mask count** (TR-11 §3: "93,939,712 canonical masks in place of 2³¹"). The reconstructed table reproduces this total exactly, confirming the k0..k9 values.

| k | canonical_masks | source |
|---|---|---|
| 0 | 1 | palindrome (= k31) |
| 1 | 7 | palindrome (= k30) |
| 2 | 56 | palindrome (= k29) |
| 3 | 378 | palindrome (= k28) |
| 4 | 2,087 | palindrome (= k27) |
| 5 | 9,707 | palindrome (= k26) |
| 6 | 38,262 | palindrome (= k25) |
| 7 | 128,414 | palindrome (= k24) |
| 8 | 369,823 | palindrome (= k23) |
| 9 | 919,819 | palindrome (= k22) |
| 10 | 1,986,807 | log |
| 11 | 3,746,013 | log |
| 12 | 6,191,140 | log |
| 13 | 8,998,676 | log |
| 14 | 11,530,906 | log |
| 15 | **13,047,760** | log (peak) |
| 16 | **13,047,760** | log (peak) |
| 17 | 11,530,906 | log |
| 18 | 8,998,676 | log |
| 19 | 6,191,140 | log |
| 20 | 3,746,013 | log |
| 21 | 1,986,807 | log |
| 22 | 919,819 | log |
| 23 | 369,823 | log |
| 24 | 128,414 | log |
| 25 | 38,262 | log |
| 26 | 9,707 | log |
| 27 | 2,087 | log |
| 28 | 378 | log |
| 29 | 56 | log |
| 30 | 7 | log |
| 31 | 1 | log |
| **Σ** | **93,939,712** | **= total canonical masks ✓** |

## Shape (each `#` ≈ 326,194 masks)

```
 0 |                                          1
 1 |                                          7
 2 |                                          56
 3 |                                          378
 4 |                                          2,087
 5 |                                          9,707
 6 |                                          38,262
 7 |                                          128,414
 8 | #                                        369,823
 9 | ###                                      919,819
10 | ######                                   1,986,807
11 | ###########                              3,746,013
12 | ###################                      6,191,140
13 | ############################             8,998,676
14 | ###################################      11,530,906
15 | ######################################## 13,047,760  <- peak
16 | ######################################## 13,047,760  <- peak
17 | ###################################      11,530,906
18 | ############################             8,998,676
19 | ###################################      6,191,140  (mirror of 12)
20 | ###########                              3,746,013
21 | ######                                   1,986,807
22 | ###                                      919,819
23 | #                                        369,823
24 |                                          128,414
25 |                                          38,262
26 |                                          9,707
27 |                                          2,087
28 |                                          378
29 |                                          56
30 |                                          7
31 |                                          1
```

Symmetric about the k15/k16 midline (13,047,760 = C(31,15) canonical-reduced), monotone to k0 = k31 = 1. The peak two-live-layer window (k15 + k16) is where the out-of-core mode's ~4 TB disk footprint is set.
