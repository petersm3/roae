# The Full-31 Exact Layer Aggregates

**What this is.** The per-layer aggregate of the exact full-scale computation of
|C1∩C2∩C4∩C5| — all 31 layers, as integers. Every previous small artifact in this repository
has been either a **sampled** subset of the full computation or a **smaller-problem** rung
(n=9…19). Both are proxies. This is neither: it is an *aggregate of an exact computation*,
and an aggregate of an exact computation is itself exact, where a sample of one is not.

**Who it is for.** A reader who wants to *check us* is already served by `REPRODUCE.md` and the
small-n catalogs. A reader who wants to *do their own research* is served by neither, because
n=19 is ~0.015% scale and answers nothing about the real object. Exact per-layer widths and
masses let you test scaling laws, size your own build, or contradict us with arithmetic.

**Reproduction command.** The table below is the layer telemetry of

```
./solve --f1-exact-c1c2c4c5 --f1-out-of-core <DIR>          # n defaults to 31
```

That run is a multi-day, multi-terabyte build; the two rungs in §2 run in **under a second** on
a laptop and are the part you can check immediately.

## 1. The 31 layers

`k` is the layer (number of pairs placed). `canonical_masks` counts orbit representatives of the
placed-set under the 24-element pair-permutation quotient of G48, out of C(31,k) sets in total.
`states` counts distinct (canonical mask, last-exit) pairs; `entries` counts stored
(canonical mask, last-exit, C5-residual) triples. `V_k` is the per-layer valid-exit bound.
`mass` is the **orbit-weighted count of valid length-k prefixes in the full (unquotiented)
space** — the column of scientific interest.

| k | canonical_masks | C(31,k) | states | entries | V_k | layer GB | mass = valid k-prefixes |
|---|---|---|---|---|---|---|---|
| 1 | 7 | 31 | 12 | 12 | 5 | 0.000000 | 56 |
| 2 | 56 | 465 | 193 | 263 | 14 | 0.000008 | 3,030 |
| 3 | 378 | 4,495 | 2,224 | 6,012 | 29 | 0.000173 | 158,364 |
| 4 | 2,087 | 31,465 | 16,682 | 110,732 | 50 | 0.003126 | 7,975,320 |
| 5 | 9,707 | 169,911 | 97,070 | 1,418,864 | 77 | 0.039845 | 386,225,352 |
| 6 | 38,262 | 736,281 | 459,144 | 12,465,946 | 110 | 0.349506 | 17,953,712,064 |
| 7 | 128,414 | 2,629,575 | 1,797,796 | 78,990,559 | 149 | 2.213277 | 799,742,878,656 |
| 8 | 369,823 | 7,888,725 | 5,917,168 | 383,080,548 | 193 | 10.730693 | 34,079,740,200,000 |
| 9 | 919,819 | 20,160,075 | 16,556,742 | 1,470,651,410 | 239 | 41.189277 | 1,386,778,721,641,920 |
| 10 | 1,986,807 | 44,352,165 | 39,736,140 | 4,522,319,129 | 283 | 126.648777 | 53,778,179,165,666,496 |
| 11 | 3,746,013 | 84,672,315 | 82,412,286 | 11,297,381,503 | 322 | 316.371634 | 1,982,685,632,661,686,784 |
| 12 | 6,191,140 | 141,120,525 | 148,587,360 | 23,398,431,312 | 355 | 655.230370 | 69,297,073,054,612,254,336 |
| 13 | 8,998,676 | 206,253,075 | 233,965,576 | 40,833,342,233 | 382 | 1143.441567 | 2,288,361,598,674,100,118,016 |
| 14 | 11,530,906 | 265,182,525 | 322,865,368 | 60,643,413,855 | 402 | 1698.153959 | 71,118,248,538,309,913,334,784 |
| 15 | 13,047,760 | 300,540,195 | 391,432,800 | 76,987,817,848 | 413 | 2155.815473 | 2,070,824,388,087,331,433,378,304 |
| 16 | 13,047,760 | 300,540,195 | 417,528,320 | 83,585,570,784 | 413 | 2340.552555 | 56,211,765,063,412,670,123,796,480 |
| 17 | 11,530,906 | 265,182,525 | 392,050,804 | 77,425,711,716 | 402 | 2168.058299 | 1,414,432,652,498,644,875,990,374,400 |
| 18 | 8,998,676 | 206,253,075 | 323,952,336 | 61,293,906,654 | 382 | 1716.337370 | 32,782,812,504,527,868,436,121,137,152 |
| 19 | 6,191,140 | 141,120,525 | 235,263,320 | 41,584,984,170 | 355 | 1164.453850 | 694,784,554,864,374,040,154,866,606,080 |
| 20 | 3,746,013 | 84,672,315 | 149,840,520 | 24,094,948,608 | 322 | 674.703513 | 13,352,785,490,617,816,554,330,511,097,856 |
| 21 | 1,986,807 | 44,352,165 | 83,445,894 | 11,810,354,354 | 283 | 330.713764 | 230,374,545,580,221,571,332,437,462,237,184 |
| 22 | 919,819 | 20,160,075 | 40,472,036 | 4,840,233,152 | 239 | 135.537566 | 3,527,101,592,023,293,517,730,048,219,185,152 |
| 23 | 369,823 | 7,888,725 | 17,011,858 | 1,643,386,030 | 193 | 46.019247 | 47,189,095,955,370,668,803,894,645,047,459,840 |
| 24 | 128,414 | 2,629,575 | 6,163,872 | 459,819,732 | 149 | 12.876493 | 541,901,315,038,665,955,828,368,548,486,971,392 |
| 25 | 38,262 | 736,281 | 1,913,100 | 105,376,944 | 110 | 2.951014 | 5,201,506,044,559,500,865,538,795,401,017,163,776 |
| 26 | 9,707 | 169,911 | 504,764 | 19,466,384 | 77 | 0.545175 | 40,405,957,458,993,167,992,215,179,071,190,728,704 |
| 27 | 2,087 | 31,465 | 112,698 | 2,823,150 | 50 | 0.079073 | 241,089,913,499,030,894,367,335,168,548,233,019,392 |
| 28 | 378 | 4,495 | 21,168 | 307,746 | 29 | 0.008621 | 1,028,154,652,541,345,880,891,026,404,825,956,876,288 |
| 29 | 56 | 465 | 3,248 | 22,824 | 14 | 0.000640 | 2,735,137,247,822,487,449,972,313,400,020,144,488,448 |
| 30 | 7 | 31 | 420 | 1,056 | 5 | 0.000030 | 3,542,919,560,536,222,176,509,199,567,089,521,655,808 |
| 31 | 1 | 1 | 32 | 32 | 1 | 0.000001 | 1,097,051,278,789,181,790,036,112,071,176,579,186,688 |

**Row 31 is a published integer.** `mass` at k=31 is
1,097,051,278,789,181,790,036,112,071,176,579,186,688 — the value `METHODS.md`, `TR-2`, `TR-4`,
`TR-5` and `TR-11` give for |C1∩C2∩C4∩C5|. The table's last row is therefore anchored to a
figure that was published, and independently reproduced, before this artifact existed.

### Per-column provenance — read this before quoting a column

Not every column here carries the same weight, and saying so is the point of this section.

| column | status |
|---|---|
| `mass` | **independently gated** at n=9 and n=13 — see §2. Terminal row matches the published full-31 integer. Its *rendering* is separately gated across the full 192-bit range by `verify.py --f1-dec-roundtrip`, which matters because n=9 and n=13 masses fit in one 64-bit limb while the k=31 value does not. |
| `canonical_masks` | **independently gated** — `verify.py --recount-orbit-widths 31` recomputes all 31 by Burnside over the 24-element pair-permutation quotient, derived from the 48 commuting bit-permutations rather than read from the engine. Two different derivations, not a restatement. |
| `C(31,k)` | arithmetic. |
| `states`, `entries`, `V_k`, `layer GB` | **engine-internal telemetry, not independently reproduced.** They describe how *this* implementation laid the layer out. A different correct implementation may legitimately differ. Do not cite them as properties of the mathematical object. |

## 2. The gate: independent per-layer recount at n=9 and n=13

`mass` is a claim about the object, so it is checked by an instrument that shares no code with
the engine. `verify.py` recomputes the layer masses with a plain layered (mask, last, budget) DP
— **no symmetry quotient at all** — so a conceptual error in the engine's orbit-quotient DP is
not shared. Each rung's boundary budget `B0` is re-derived by first-completion DFS rather than
read from a table.

```
./solve --f1-exact-c1c2c4c5 --f1-pairs 9      # engine
python3 verify.py --recount-rung-layers 9     # independent recount + gate
python3 verify.py --recount-orbit-widths 31   # Burnside gate on canonical_masks (all 31 layers)
```

| k | n=9 mass | | k | n=13 mass |
|---|---|---|---|---|
| 1 | 12 | | 1 | 6 |
| 2 | 96 | | 2 | 144 |
| 3 | 660 | | 3 | 3,096 |
| 4 | 3,624 | | 4 | 60,480 |
| 5 | 13,956 | | 5 | 1,063,296 |
| 6 | 36,888 | | 6 | 16,616,448 |
| 7 | 68,352 | | 7 | 227,208,960 |
| 8 | 80,160 | | 8 | 2,625,811,488 |
| 9 | 26,112 | | 9 | 24,294,300,960 |
| | | | 10 | 167,936,990,976 |
| | | | 11 | 788,262,374,016 |
| | | | 12 | 2,116,284,083,712 |
| | | | 13 | 2,063,395,607,040 |

All 22 layer masses agree exactly. The terminal rows (26,112 and 2,063,395,607,040) are the
rung totals already published in TR-11 §4b; the twelve **intermediate** rows had never been
cross-checked against anything before this artifact.

**The gate has been shown able to fail.** Weakening the budget cap from `p >= B0` to `p > B0` —
a one-character off-by-one of exactly the kind that is otherwise silent — leaves k=1 *identical*
at 12 and diverges from k=2 onward (174 instead of 96), ending at 3,731,760 instead of 26,112.
Two things follow. A gate that checked only the **first** layer would pass that engine. A gate
that checked only the **total** would catch it, but would not tell you the divergence begins at
k=2. Per-layer checking is strictly stronger than either.

**What the gate does not cover.** n=9 and n=13 are 29% and 42% of the ladder's depth and a
vanishing fraction of its width. Agreement at two rungs is evidence that the *method* is right,
not proof that layer 24 of the full-31 build is. No instrument in this repository can recount
full-31 independently — the plain DP's peak live-state count exceeds any single-node RAM budget
past n≈19 — and this artifact does not claim otherwise.

## 3. Source

Layer telemetry extracted from the Stage F build log `run_f/run.out`
(sha256 `46250754ba4c8a9ce5e75a496e02df105a8e6b40018c59f196dc99a733c6adfb`, 39,347 bytes), whose
final line reads `F1C5 EXACT |C1 & C2 & C4 & C5| = 1097051278789181790036112071176579186688`.
The 31 extracted layer lines hash to
`05555b9fab28015cf9395a7741860b1ed06a6f142291f28ccc325588c459bfba`.
