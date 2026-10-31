# Layer-count curve — canonical masks per popcount layer (Burnside palindrome)

The out-of-core DP proceeds layer by layer over mask popcount k = 0..31, storing only **canonical masks** (minimum image over the 24 pair-permutations). The per-layer canonical-mask count is a **Burnside palindrome**: masks(k) = masks(31−k), proven from subset-complement equivariance (see TR-5 / the symmetry-palindrome note). This is the free per-layer integrity check — every layer print must match its mirror, and the whole curve must sum to the total canonical-mask count.

## Full 32-layer table

Values k1..k31 are read directly from the run log (`run.out` carries the k1..k9 prints of the first, 64-thread segment as well as k10..k31); k0 = 1 is the empty mask and equals its mirror k31. *(Note 2026-10-22, Codex F07-010#17: this line said k0..k9 were the palindrome mirror of k22..k31 because their prints had scrolled out of the retained final-resume log, and the table's source column still says so for k0..k9. The published `run.out` holds k1..k9, every value matches the table, so all fifteen recoverable mirror pairs k1/k30 … k15/k16 hold directly, not the six that `count_result.json` and the README record. [CORRECTIONS.md](../../documentation/CORRECTIONS.md) CX-35X-K.)*

**Independent cross-check: Σ masks(k) over k=0..31 = 93,939,712 = the known total canonical-mask count** (TR-11 §3: "93,939,712 canonical masks in place of 2³¹"). The reconstructed table reproduces this total exactly, confirming the k0..k9 values.

| k | canonical_masks | source |
|---|---|---|
| 0 | 1 | palindrome (= k31) |
| 1 | 7 | log (and palindrome = k30) |
| 2 | 56 | log (and palindrome = k29) |
| 3 | 378 | log (and palindrome = k28) |
| 4 | 2,087 | log (and palindrome = k27) |
| 5 | 9,707 | log (and palindrome = k26) |
| 6 | 38,262 | log (and palindrome = k25) |
| 7 | 128,414 | log (and palindrome = k24) |
| 8 | 369,823 | log (and palindrome = k23) |
| 9 | 919,819 | log (and palindrome = k22) |
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
19 | ###################                      6,191,140  (mirror of 12)
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

Symmetric about the k15/k16 midline (13,047,760 = C(31,15) canonical-reduced), monotone to k0 = k31 = 1. The peak two-live-layer window (k15 + k16) is where the out-of-core mode's ~4 TB disk footprint is set. *(Corrected 2026-10-02, Q-943: the k=19 bar was drawn with 35 marks, the length of the k=14 and k=17 bars, although its value is 6,191,140, the same as k=12; it now has 19 marks like k=12. Only the bar changed; every count in this file is as it was.)*

*Note 2026-10-22 (Codex F07-010#16; [CORRECTIONS.md](../../documentation/CORRECTIONS.md) CX-35X-K): the sentence above names k15 + k16 as the peak two-live-layer window. By bytes it is k16 + k17: `run.out`'s `two_layer` column is 4,496.37 GB at k16 and 4,508.61 GB at k17, the layer whose write keeps k16 live; TR-11 §6 publishes that pair. k15/k16 is the midline of the mask-count curve, not of the byte curve, because entries per mask differ by layer.*
