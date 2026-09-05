# Decoy control, cardinality tier — raw output (2026-09-04)

**What this is.** The archived output of the decoy negative control at the C5 layer cited by
[TR-9](../../TR9_PRICING_THE_CONSTRAINTS.md) §2 ("Population context for the C5 marginal"), §4 and its
Verification Guide, and by [TR-4](../../TR4_SIZE_OF_THE_SPACE.md) §Update v1.7. For each of N = 1,000
targets drawn uniformly from C1∩C2 (`solve.py --extraction-null 1000 --extraction-null-seed 20260904`:
the 32 King Wen pairs shuffled with fair orientation coins, any draw carrying a distance-5 transition
rejected), the target's own 63-transition Hamming multiset was handed to the shipped estimator as the
C5 budget and |C1∩C2∩C4∩C5(target)| was estimated:

```
python3 solve.py --extraction-null 1000 --extraction-null-seed 20260904 \
  | grep -v '^EXTRACTION_NULL' \
  | while read m; do
      SOLVE_THREADS=2 SOLVE_KNUTH_C5_BUDGET=$m ./solve --estimate-knuth 100000 \
        | awk -v m="$m" '/leaves_C1C2C4C5/ {sub("est=","",$3); print $3 "\t" m}'
    done
```

Run 2026-09-04 on a 2-vCPU host, 10⁵ probes per decoy (≈0.7 s each), `SOLVE_THREADS=2`, engine at
public `f0bc74ec`. C4 (the opening pair) is held at King Wen's throughout, because the estimator pins it.

**Columns.** `estimate<TAB>multiset`, where `estimate` is the estimator's `leaves_C1C2C4C5 est=` value
and `multiset` is the `d:count,…` string that was passed as `SOLVE_KNUTH_C5_BUDGET`. Rows are in draw
order; the sampler is deterministic under its seed and the multiset column reproduces byte-for-byte.

**Thread count is load-bearing.** Knuth seeds are per-thread. With `SOLVE_THREADS=2` the estimates
reproduce digit-for-digit — checked 2026-09-05 on rows 1–3, 5 (the King Wen multiset,
`1:2,2:20,3:13,4:19,6:9` → `1.182455e+39`) and 204–205; `SOLVE_THREADS=1` returns different digits
(e.g. `1.092788e+39` for the King Wen row). Any thread count reproduces the percentile only to within
the ≈4 % per-decoy relative error at 10⁵ probes.

**The file has 1,001 lines, not 1,000.** Line 206 is a stray `0.000000e+00` with no multiset, written
by the 2026-09-04 harness; it is kept as written rather than silently deleted. Drop it with `NF==2`.
Separately, row 207 (`0<TAB>1:4,2:14,3:21,4:15,6:9`) is a decoy whose estimate is 0: no probe reached
a leaf at 10⁵ probes. That bounds its count loosely from above (King Wen's hit-rate at 10⁵ is 0.0146)
and is not a proof that its admissible set is empty.

**The percentile.** King Wen's comparator is the exact published |C1∩C2∩C4∩C5| = 1.097051×10³⁹
(TR-9 §2, TR-11), not an estimate.

```
awk -F'\t' 'NF==2 && $1+0 < 1.097051e39' decoy_cardinality_n1000_2026_09_04.tsv | wc -l    # 651
awk -F'\t' 'NF==2' decoy_cardinality_n1000_2026_09_04.tsv | wc -l                          # 1000
```

651 of 1,000 decoys lie below King Wen: the **65th percentile**. Median decoy (mean of the two middle
values over all 1,000 rows, the zero included) 7.857×10³⁸. Nonzero range 1.868×10³⁴ … 3.371×10³⁹.
In bits, over the 999 nonzero decoys: log₂ quantiles 5 % 124.8 · 25 % 127.7 · 50 % 129.2 · 75 % 130.0 ·
95 % 131.0; King Wen at 129.69, 0.48 bit above the median, interquartile range 2.4 bits. The C5
marginal, 139.1 − log₂(estimate) with 139.1 = log₂|C1∩C2∩C4| (exact, the same for every decoy):

```
awk -F'\t' 'NF==2 && $1+0>0 {print log(7.5706e41/($1+0))/log(2)}' decoy_cardinality_n1000_2026_09_04.tsv \
  | sort -g | awk '{a[NR]=$1} END {print a[int(NR*0.05)], a[int((NR+1)/2)], a[int(NR*0.95)]}'   # 8.1 9.9 14.2
```

against King Wen's 9.43 bits.

**What it measures and what it does not.** It measures the size of the admissible set at the
C1∩C2∩C4∩C5 layer — TR-9's 129.7-bit row — for a target's own extracted multiset. It does not measure
any decoy's own C3 cut (TR-9's 126.6-bit row adds King Wen's 3.0-bit C3 cut, which has no decoy
analogue here), any uniqueness rate (the historical "9 of 10" figure is a different tier and remains
unreproduced), or any per-boundary information rate (TR-4). C1, C2 and C4 are matched by construction.
The pre-registered criterion (survives below the 1st percentile, fails between the 5th and 95th)
returns FAIL for the specialness framing on this axis: the cardinality of King Wen's admissible set is
unremarkable.

The file is byte-identical to the working copy from which the 2026-09-04 result was written
(sha256 `0ecedf7f9fcfcfc9b8d0dacdf1fcebbadb7fbcc25a1731f3b287780bbdad8e5b`). Published 2026-09-05.
