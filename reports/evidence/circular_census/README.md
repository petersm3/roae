# TR-7 circular census — the four wrap classes at 2×10¹⁰ probes each (2026-09-24)

**What this is.** The measurement behind TR-7 v2.6's correction of the circular solution-space size
([TR-7](../../TR7_CIRCULAR_READING.md) §"The anchors on the circle"). Through v2.5, TR-7 printed a
two-term sum as the exact size of the circular space. It is a lower bound: two of the four wrap
classes were left out. This directory measures the two omitted classes and re-measures one of the
two published ones.

**Why four classes.** Under TR-7's own circular definition (§1, §4), a member of the circular space
C_circ is a C1+C3+C4-valid ordering whose 64 cyclic transitions have exactly King Wen's circular
multiset **C = {1:2, 2:20, 3:14, 4:19, 6:9}**, with no 5-line step anywhere on the cycle. Its linear
63-transition multiset is C minus its wrap distance w, so the space splits by w:

| w | linear multiset L = C − {w} | term | this directory |
|---|---|---|---|
| 3 | {1:2, 2:20, 3:13, 4:19, 6:9} = King Wen's linear C5 | T3 = f₃ · N_lin | not re-run (published pair, `evidence/wrap_mass_reseed/`) |
| 1 | M′ = {1:1, 2:20, 3:14, 4:19, 6:9} | T1 = N(M′) · f₁(M′) | re-measured (`Mp_*`) |
| 2 | M₂ = {1:2, 2:19, 3:14, 4:19, 6:9} | T2 = N(M₂) · f₂(M₂) | **measured (`M2_*`); omitted through v2.5** |
| 4 | M₄ = {1:2, 2:20, 3:14, 4:18, 6:9} | T4 = N(M₄) · f₄(M₄) | **measured (`M4_*`); omitted through v2.5** |
| 6 | {…, 6:8} | — | impossible: it would put hexagram 0 last, and C4 puts it second |
| 5 | — | — | excluded by circular C2 |

M₂ and M₄ each have 16 odd transitions (2 + 14), so their walks end on an even-popcount hexagram and
the wrap is even. The wrap-parity theorem (`wrap_parity_general`) does not apply to them, because its
hypothesis is King Wen's *linear* multiset, with 15 odd transitions.

## Result

Estimates and SEs are written in the e-notation that `pool.sh` prints.

| term | wrap bin read | estimate | SE | relerr | χ²₁₉ (chunk spread vs printed SE) |
|---|---|---:|---:|---:|---:|
| T2 (M₂) | d2 | 4.753074e+37 | 2.199e+34 | 0.046% | 14.89 |
| T4 (M₄) | d4 | 4.150069e+37 | 2.067e+34 | 0.050% | 17.76 |
| T1 (M′) | d1 | 1.138453e+37 | 9.557e+33 | 0.084% | 15.72 |
| T3 (linear) | d3 | 8.657772e+37 | ≈2.18e+34 | ≈0.025% | — |

- **|C_circ| = T3 + T1 + T2 + T4 = 1.869937×10³⁸ ± 3.8×10³⁴ ≈ 1.407 × N_lin** (N_lin = 1.32889×10³⁸).
- The two omitted classes, T2 + T4, are **47.6%** of the circular space.
- The two published terms sum to 9.80×10³⁷ = 0.737 × N_lin, which is the ratio TR-7 printed through v2.5.
- **T1 re-measured.** TR-7 published T1 as 0.175 × 6.507×10³⁷ ≈ 1.1388×10³⁷, with no SE. The fresh,
  seed-distinct value 1.1385×10³⁷ agrees to 0.03% (0.36 of its own SE).
- **SE validated by replication.** Each class is 20 independent-seed chunks. The χ²₁₉ statistic compares
  the spread of the 20 chunk estimates with the SE each chunk prints, and all three values lie inside
  the 95% band [8.9, 32.9].
- **Parity control PASS.** In every chunk, every bin of the other parity is exactly 0: the M₂ and M₄
  walks put nothing in d1/d3/d5, the M′ walk nothing in d0/d2/d4/d6. d0 and d6 are 0 everywhere.

**How T3 and its SE are formed.** T3 is f₃ × N_lin from the published seed-distinct 2×10¹⁰ pair in
[`evidence/wrap_mass_reseed/`](../wrap_mass_reseed/): f₃ = 0.651504 ± 0.000096 and N_lin = the mean of
the two `leaves_canonical_C1C5` lines. Its SE is propagated in quadrature from those two SEs. That is an
approximation, because f₃ and N_lin come from the same runs, and no artifact prints T3's absolute
d3 bin with its own SE. The total's ± includes it. Without it, the ± of T1 + T2 + T4 is 3.17×10³⁴.

`pool.sh` (a bash + awk shell script) computes every figure above from the chunk outputs and prints
them as `KEY=value` lines ([`pool.out`](pool.out)). Run it from anywhere:
`bash reports/evidence/circular_census/pool.sh`. Before pooling, it checks each chunk for:

- `RC=0`;
- the probe count and thread count;
- the multiset that `solve.c` echoes;
- a `SEED OVERRIDE` base equal to that chunk's own seed;
- all seven wrap bins;
- exactly zero mass in every bin of the other parity (the parity control, printed as `Q741_PARITY`).

Any failed check exits non-zero; a parity violation still prints the figures, then `Q741_PARITY=FAIL`.

## Method

- **Instrument.** `--estimate-knuth` with `SOLVE_KNUTH_SCORE=1` and the C5-budget override
  `SOLVE_KNUTH_C5_BUDGET` (the walk TR-7 already uses for N(M′)). For each multiset the term is the
  **absolute** wrap-bin estimate `sWR[w]/N`, which equals N(L) · f_w(L) directly, with se =
  √(sample variance / N). `solve.c` prints it for every bin d0..d6 on the `[score] wrap-bin` lines
  (documented in `documentation/SOLVE_C_CLI.md` §`SOLVE_KNUTH_SCORE`).
- **Binary.** These chunks were produced before the print was landed in `solve.c`. They were built from
  `solve.c` at public commit `5c296837` plus one print block, from a scratch source with sha256
  `0ed7c429ab438dbc47cf8c6ad559f7be13fabebe279841b43d4cc441c800fc9b`, which labels the lines
  `WRAPBIN-SCRATCH`. The landed print computes the same quantities from the same accumulators.
  A paired run (same seed, threads and probes; 2×10⁵ probes on M₂, source built both ways) printed
  byte-identical output apart from the label and `wall_s`. Both prints are print-only:
  - For the scratch print: `--selftest` printed `403f7202…` PASS, a paired sub-canonical enumeration
    gave the same sha as the unpatched build, and a function-level disassembly diff changed only
    `estimate_tree_knuth`.
  - For the landed print: a function-level disassembly diff against the unpatched build changes only
    `estimate_tree_knuth`, and the estimator's other output lines are byte-identical.

  The census binary's own sha256 was not recorded.
- **Build.** `gcc -O3 -pthread -fopenmp -o solve solve.c -lm -lz`.
- **Host.** Azure D64als_v7 Spot, westus3, 64 threads. A pre-run throttle probe read a 3567 MHz mean
  over 64 CPUs, and `--selftest` passed on the host before the run.
- **Chunks.** 60 chunks of 1×10⁹ probes: M₂, M₄ and M′ × 20 each. Each chunk has its own seed,
  `SOLVE_KNUTH_SEED` = S = 2026100000 + 100·m + c, where m = 0 (M₂), 1 (M₄), 2 (M′) and c = 0..19.
  - The estimator seeds worker i as `base ^ ((i+1)·0x9E3779B97F4A7C15)`. Before launch, all
    3,840 per-thread seeds (60 chunks × 64 threads) were asserted distinct.
  - Chunking made the run eviction-tolerant: an eviction loses at most one ≈3.5-minute chunk.
- **Pooling.** Every chunk has the same probe count, so the pooled estimate is the mean of the 20 chunk
  estimates and the pooled SE is √(Σ seᵢ²)/20.
- **Run.** 2026-09-24, 18:52Z → 22:27Z. The 60 chunks total 12,686 s of wall time, at about $2 of
  Spot time.

## Reproduce

⚠ The estimator needs a stack limit of **at least 16 MB** (`ulimit -s 16384` suffices;
`ulimit -s unlimited` is one sufficient setting).

**The thread count is part of the sample.** A chunk reproduces only at its identical (probes, threads,
seed) triple and binary. A different compiler or host may differ in the last digits. On the landed
`solve.c` the lines are labelled `wrap-bin` rather than `WRAPBIN-SCRATCH`, and `pool.sh` reads both.

```bash
gcc -O3 -pthread -fopenmp -o solve solve.c -lm -lz
ulimit -s unlimited
mkdir -p out
run() {  # $1 = file prefix, $2 = m, $3 = multiset
  for c in $(seq 0 19); do
    S=$((2026100000 + 100*$2 + c)); f=out/$1_c$(printf %02d $c).out
    SOLVE_KNUTH_SEED=$S SOLVE_THREADS=64 SOLVE_KNUTH_SCORE=1 SOLVE_KNUTH_C5_BUDGET="$3" \
      ./solve --estimate-knuth 1000000000 > "$f" 2>&1
    echo "RC=$?" >> "$f"; echo "SEED=$S" >> "$f"
  done
}
run M2 0 "1:2,2:19,3:14,4:19,6:9"
run M4 1 "1:2,2:20,3:14,4:18,6:9"
run Mp 2 "1:1,2:20,3:14,4:19,6:9"
cp /path/to/reports/evidence/circular_census/pool.sh . && bash pool.sh   # pool.sh reads out/ beside itself
```

`2>&1` is required: the `SEED OVERRIDE` line goes to stderr, and without it the artifact loses its
seed provenance. For a quick check that the print works, run one chunk at 10⁵ probes. Its figures will
not match these; mass ratios are heavy-tail dominated at small budgets.

## Files

- `out/` — the 60 chunk outputs, unmodified, 4.8 KB each. [`SHA256SUMS`](SHA256SUMS) lists their
  sha256; check them with `sha256sum -c SHA256SUMS` from this directory. The chunk outputs are plain
  text with no gzip framing, so the digests are over their raw bytes.
- [`pool.sh`](pool.sh) — the pooling script (bash + awk). [`pool.out`](pool.out) — its output.

## Chunks

| chunk file | `SOLVE_KNUTH_SEED` | term estimate | se | `wall_s` |
|---|---:|---:|---:|---:|
| out/M2_c00.out | 2026100000 | 4.756664e+37 | 9.829e+34 | 201 |
| out/M2_c01.out | 2026100001 | 4.756834e+37 | 9.857e+34 | 205 |
| out/M2_c02.out | 2026100002 | 4.745538e+37 | 9.830e+34 | 201 |
| out/M2_c03.out | 2026100003 | 4.759300e+37 | 9.839e+34 | 195 |
| out/M2_c04.out | 2026100004 | 4.748148e+37 | 9.829e+34 | 253 |
| out/M2_c05.out | 2026100005 | 4.761257e+37 | 9.858e+34 | 204 |
| out/M2_c06.out | 2026100006 | 4.748535e+37 | 9.838e+34 | 207 |
| out/M2_c07.out | 2026100007 | 4.747033e+37 | 9.825e+34 | 206 |
| out/M2_c08.out | 2026100008 | 4.744425e+37 | 9.814e+34 | 199 |
| out/M2_c09.out | 2026100009 | 4.760279e+37 | 9.834e+34 | 189 |
| out/M2_c10.out | 2026100010 | 4.741709e+37 | 9.818e+34 | 199 |
| out/M2_c11.out | 2026100011 | 4.768099e+37 | 9.856e+34 | 202 |
| out/M2_c12.out | 2026100012 | 4.755629e+37 | 9.852e+34 | 203 |
| out/M2_c13.out | 2026100013 | 4.745630e+37 | 9.806e+34 | 197 |
| out/M2_c14.out | 2026100014 | 4.754527e+37 | 9.835e+34 | 192 |
| out/M2_c15.out | 2026100015 | 4.743529e+37 | 9.821e+34 | 198 |
| out/M2_c16.out | 2026100016 | 4.748038e+37 | 9.830e+34 | 205 |
| out/M2_c17.out | 2026100017 | 4.770725e+37 | 9.846e+34 | 188 |
| out/M2_c18.out | 2026100018 | 4.742922e+37 | 9.796e+34 | 197 |
| out/M2_c19.out | 2026100019 | 4.762661e+37 | 9.849e+34 | 201 |
| out/M4_c00.out | 2026100100 | 4.153150e+37 | 9.238e+34 | 211 |
| out/M4_c01.out | 2026100101 | 4.149339e+37 | 9.242e+34 | 209 |
| out/M4_c02.out | 2026100102 | 4.148754e+37 | 9.253e+34 | 260 |
| out/M4_c03.out | 2026100103 | 4.145442e+37 | 9.220e+34 | 209 |
| out/M4_c04.out | 2026100104 | 4.130571e+37 | 9.215e+34 | 205 |
| out/M4_c05.out | 2026100105 | 4.154824e+37 | 9.222e+34 | 256 |
| out/M4_c06.out | 2026100106 | 4.173124e+37 | 9.299e+34 | 202 |
| out/M4_c07.out | 2026100107 | 4.149956e+37 | 9.247e+34 | 199 |
| out/M4_c08.out | 2026100108 | 4.153102e+37 | 9.257e+34 | 197 |
| out/M4_c09.out | 2026100109 | 4.137821e+37 | 9.239e+34 | 255 |
| out/M4_c10.out | 2026100110 | 4.156657e+37 | 9.238e+34 | 246 |
| out/M4_c11.out | 2026100111 | 4.141511e+37 | 9.234e+34 | 256 |
| out/M4_c12.out | 2026100112 | 4.141192e+37 | 9.241e+34 | 208 |
| out/M4_c13.out | 2026100113 | 4.145293e+37 | 9.231e+34 | 206 |
| out/M4_c14.out | 2026100114 | 4.152333e+37 | 9.248e+34 | 198 |
| out/M4_c15.out | 2026100115 | 4.151309e+37 | 9.268e+34 | 199 |
| out/M4_c16.out | 2026100116 | 4.148188e+37 | 9.236e+34 | 211 |
| out/M4_c17.out | 2026100117 | 4.157892e+37 | 9.248e+34 | 204 |
| out/M4_c18.out | 2026100118 | 4.150802e+37 | 9.249e+34 | 209 |
| out/M4_c19.out | 2026100119 | 4.160128e+37 | 9.261e+34 | 211 |
| out/Mp_c00.out | 2026100200 | 1.138523e+37 | 4.264e+34 | 202 |
| out/Mp_c01.out | 2026100201 | 1.138589e+37 | 4.273e+34 | 204 |
| out/Mp_c02.out | 2026100202 | 1.141335e+37 | 4.287e+34 | 211 |
| out/Mp_c03.out | 2026100203 | 1.140321e+37 | 4.300e+34 | 207 |
| out/Mp_c04.out | 2026100204 | 1.140681e+37 | 4.274e+34 | 215 |
| out/Mp_c05.out | 2026100205 | 1.132281e+37 | 4.251e+34 | 206 |
| out/Mp_c06.out | 2026100206 | 1.146204e+37 | 4.312e+34 | 207 |
| out/Mp_c07.out | 2026100207 | 1.140591e+37 | 4.274e+34 | 202 |
| out/Mp_c08.out | 2026100208 | 1.133682e+37 | 4.253e+34 | 195 |
| out/Mp_c09.out | 2026100209 | 1.143311e+37 | 4.288e+34 | 252 |
| out/Mp_c10.out | 2026100210 | 1.133229e+37 | 4.246e+34 | 200 |
| out/Mp_c11.out | 2026100211 | 1.138696e+37 | 4.286e+34 | 202 |
| out/Mp_c12.out | 2026100212 | 1.138908e+37 | 4.304e+34 | 208 |
| out/Mp_c13.out | 2026100213 | 1.140545e+37 | 4.275e+34 | 202 |
| out/Mp_c14.out | 2026100214 | 1.138059e+37 | 4.277e+34 | 197 |
| out/Mp_c15.out | 2026100215 | 1.136527e+37 | 4.259e+34 | 208 |
| out/Mp_c16.out | 2026100216 | 1.134535e+37 | 4.246e+34 | 258 |
| out/Mp_c17.out | 2026100217 | 1.143576e+37 | 4.294e+34 | 258 |
| out/Mp_c18.out | 2026100218 | 1.131891e+37 | 4.244e+34 | 202 |
| out/Mp_c19.out | 2026100219 | 1.137575e+37 | 4.275e+34 | 257 |

## Attribution and scope

- The circular reading is McKenna & McKenna (1975).
- Codex (review target V3A-093) found that the census omitted the even-wrap classes, and supplied an
  explicit wrap-2 witness. Fable adjudicated the finding and executed the witness.
- Developed with AI assistance (Claude, Anthropic); errors are ours, and corrections are welcome via
  [CITATIONS.md](../../../documentation/CITATIONS.md).
- These are weighted-Knuth estimates of a space far too large to enumerate: measurements with stated
  SEs, not counts.
