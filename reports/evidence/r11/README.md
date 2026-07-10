# R11 evidence bundle — four-class Bayes v2 ingredients (collection stage)

Ingredient runs for the pre-registered four-class model comparison
(`R11_BAYES_V2_DESIGN` — private staging; freeze pending operator approval).
**No Bayes factor has been computed from these files**: per the frozen
ordering-of-operations, calibration and the KW-facing integration are
post-freeze deliverables. This directory currently holds instrument outputs
only:

- unconditioned 8-axis joint violation histogram — 150,758 cells; mass sums
  to 1; seven marginals reproduce the run's independent scoreboard lines to
  <0.3%. The raw dump (`r11_hist.out`, 6.5 MB; gzip -9 → 1.7 MB) is **not
  committed** (over the repository's 1 MB asset threshold) and is exactly
  regenerable from the pushed code:
  `SOLVE_KNUTH_SCORE=1 SOLVE_KNUTH_R11_HIST=1 ./solve --estimate-knuth 20000000000`.
  The KW cell (2,2,2,0,0,0,0,0) is
  absent by rarity, as expected: its estimated mass (~10⁻²³ of canonical
  mass) is ~11 orders below the run's smallest sampled cell (5.9×10⁻¹²);
  scorer correctness is established by the two-language `--r11-verify` gate,
  not by sampling.
- `r11_moore_strict.out` — Moore-joint-strict conditional plane (1,514
  cells, all g1=g2=0), N_mj = 1.131×10²⁹ — consistent with the published
  F11 value.
- `r11_ngs.out` — the DIRECT triple-strict count (the instrument F11
  documented as missing), with its in-walk cross-check line mismatches = 0.
  **N_gs = 5.00×10²⁵ (relerr 16.7%), which falls OUTSIDE the F11 derived
  bracket [1.03, 3.57]×10²⁵ — per the pre-registered rule this is a
  stop-and-investigate finding before any integration**, recorded here so
  the flag travels with the evidence.

Developed with AI assistance (Claude, Anthropic); rules and mechanisms
credited in the design doc (Moore, Schulz, Cook, Hacker & Moore, Rutt,
McKenna & Mair, Davis, Van den Berghe).
