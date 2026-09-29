# TR-12 evidence — the 2026-09-22 n=31 battery's answer rows

**What this is.** The receipts that the TR-12 reproduction battery wrote for its answer rows on its
full-31 run of 2026-09-22: King Wen's REL rank (Q1b), the O3 certificate and its two riders (Q1),
the O3 endpoint and midpoint walks with bracket certificates (Q2), the REL endpoints (Q2b), King
Wen's per-step profile with every alternative (Q3), the C3 census estimate (Q4), the two 1,000-walk
galleries and their gates (Q8), and the two Q10 rows. They were kept when the run's host was
released, and are published here on 2026-09-27 (Q-857). The run's verdict file is
[`../VERDICTS_n31_20260922.txt`](../VERDICTS_n31_20260922.txt).

**What this is not.** It is not a passing battery. That run's whole-run token is `TR12_REPRO=FAIL`,
and the three FAIL rows are a published result, not a defect in these rows
([`../README.md`](../README.md) §"The three FAILs are one fault"). Its `TR12_Q2=PASS` also does not
meet TR-12's Q2 completion contract, for the reason given in the same README. Nothing here changes
any of that.

**Attested, not reproduced, unless stated.** Every rank, unrank, sample draw and profile lookup in
these files reads the f ladder, and the Q2/Q3 rows also read the g ladder. Those ladders are not
distributed ([TR-12](../../../TR12_QUERY_PROGRAM.md)), so the values are **attested (2026-09-22
battery); not reproducible without the f/g ladders**. What *can* be re-derived from these bytes
alone is listed under "What a reader can re-check", and `check_receipts.sh` does it.

## Provenance

| item | value |
|---|---|
| run | TR-12 reproduction battery, universe n=31, the post-scan `--atlas` pass, run with `--fdir`, `--gdir` and `--tdir`; driver exit 2026-09-22 |
| `solve` binary | sha256 `a253828bfe9e065a82c57f1eec7f00e66f0416822deb1c7521cb7204eb576e59`, the binary named in [`runs/20260906_kc_ladders_n31/README.md`](../../../../runs/20260906_kc_ladders_n31/README.md) |
| engine source | `solve.c` at commit `8af5e55c8eed` (the TR-12 §12 engine pin; the tag `tr12-v1.10` is on a later commit that carries the same `solve.c`); `git show 8af5e55c8eed:solve.c \| sha256sum` gives `ed9c65b24e9f2ff9cab05eef9f817dca9453ea2edf25b9186fc1f667abe063c9` |
| battery script | `scripts/tr12_repro.sh` with sha256 `b1b035aedee7ccffbd62cf23086a321a08039ae61a28b7dd5c96a9f9892ab152`, which is that file at commit `c633504e` |
| universe | n=31, N = 1097051278789181790036112071176579186688, anchor King Wen |
| knobs | `C3MAX=387 SEED=9276183659154465378 Q8_K=1000 Q4AC_M=1000000 Q1C_M=10000 V3_K=1000` |
| ladders | the f/g/t ladders whose per-layer digests are published in [`runs/20260906_kc_ladders_n31/`](../../../../runs/20260906_kc_ladders_n31/README.md) |
| goldens | the run diffed every Group A/B row against a pre-minted n=31 golden set, and minted the Group C rows (`c_q10a`, `c_q10a_kwrank`) |

The engine's `#provenance` lines print placeholders where the battery's own `norm()` rewrote
run-host paths and pins: `<FDIR>`/`<GDIR>` are the ladder directories, `<GIT>` is `8af5e55c8eed`,
`<SRC>` is the engine-source sha above, `<BRANCH>` is the branch name the binary printed (not
recorded), and `<ART>` is the run's artifact directory. One further redaction: in `a2_q1.txt` the
engine's note on the exact C15 count carried a price estimate twice, and both now read
`<PRICE-REDACTED>` (TR-12 §9 redacts that figure, and this directory does not restate it); the
run's copy had sha256 `8dcdfb86177b050c15594c7655fc063dd785e81934c9961090e3fda7ea44ce67`. No other
byte differs from the run's copies.

**Determinism across runs (attested).** The 2026-09 campaign ran the battery three times against
the same ladders and binary (a pre-scan pass on 2026-09-21, this post-scan pass, and a later pass
on 2026-09-22). `a1_q1b`, `a1_q2b`, `a2_q1`, `a2_q3_profile`, `a1_q4ac`, `a1_q8_super`,
`a1_q8_c15` and `a1_q8_chi2` were byte-identical in all three; `a2_q2` in the two passes that ran
it. That is evidence that the engine is deterministic on the same inputs, not an independent
derivation.

## Files

| file | row / what | bytes |
|---|---|---|
| `a1_q1b.txt` | Q1b: `rank_REL(KW) = 724527916019628379431626015409038066987` | 589 |
| `a2_q1.txt` | Q1: the `--kc-o3-cert` certificate (the JSON is embedded); one price string redacted, see Provenance | 3,942 |
| `a2_q1_labeling.txt` | Q1: the labelling check, rank 0/0/0 | 362 |
| `a2_q1c.txt` | Q1(c): the conditioning interval, measured `EMPTY` | 820 |
| `a2_q2.txt` | Q2: `unrank_O3` at 0, N−1 and ⌊N/2⌋ under `--kc-bracket`, each `CERTIFICATE PASS` | 6,416 |
| `a1_q2b.txt` | Q2b: `--kc-unrank` at the same three ranks, with records | 3,383 |
| `a2_q3_profile.txt` | Q3: `--kc-profile --kc-tsv --kc-alts` transcript, 880 `#alt` rows | 83,415 |
| `q3_profile_exact.tsv` | Q3: the 16-column exact table that transcript's run wrote (`g_alt_min`, `g_alt_max`, `choice_rank` are not in the committed `tr12/q3_profile_kw.tsv`) | 4,820 |
| `a1_q4ac.txt` | Q4(a,c): C3 census over M = 10⁶ SUPER draws, estimates and per-bin Wilson intervals | 9,432 |
| `a1_q8_super.txt` | Q8: 1,000 SUPER draws (`rank cd walk` + `record` lines) | 419,138 |
| `a1_q8_c15.txt` | Q8: 1,000 C15-accepted draws | 419,124 |
| `a1_q8_chi2.txt` | Q8: 16-bucket chi², 20.224 | 447 |
| `a1_q8_subset.txt` | Q8: 110 of the 1,000 SUPER draws have `cd ≤ 387` | 467 |
| `a1_q8_member.txt` | Q8: member re-check, 1000 re-checked, 0 failures | 46 |
| `c_q10a_20260922_asrun.txt` | Q10(a): the row as it ran; census column `NA:schema-v1-sidecar` on all 32 layers | 12,153 |
| `c_q10a.txt` | Q10(a): the same row re-run with the Q-857 fallback on the published sidecars; census filled on all 32 layers (regenerated 2026-09-29 for the CX-232 label corrections; the as-run receipt is unchanged) | 14,768 |
| `c_q10a_kwrank.txt` | Q10(a): the KW-orbit-rank leg, measured `EMPTY` | 819 |
| `check_receipts.sh` | the reader-side re-check described below | — |
| `SHA256SUMS` | sha256 of every file above except this README and `SHA256SUMS` | — |

Not included: the run's raw artifact copies of the Q1 JSON and the Q8 galleries (they carry run-host
paths; their bytes are inside the transcripts above), the Q4 per-draw raw file (439 MB; archived
off-tree, and needed only for `μ_rec^C15`), and the outputs of the 2026-09-25 atlas follow-up window
(TR-12 §12.7 says why).

## What a reader can re-check from these bytes

```bash
bash reports/evidence/tr12/banked_n31_20260922/check_receipts.sh
```

needs only this tree and `python3` (it imports `solve.py`'s constraint helpers) and ends in
`CHECK_RECEIPTS=PASS`. It checks:

- **Q2 / Q2b.** `unrank_O3(0)` is King Wen; `unrank_O3(N−1)` is in SUPER and has C3 = 688 ≤ 776, so
  it lies in C15 and is O3-`LAST^C15` (the "O3-greatest" half is the attested certificate); the
  midpoint has C3 = 904; the REL-greatest walk has C3 = 1568. King Wen's 776 is the control.
- **Q3.** 880 `#alt` rows, equal to the Σ of `alts`; at each of the 31 steps the alternatives' g sum
  to `g_parent`, their min and max are `g_alt_min`/`g_alt_max`, and the alternative at `choice_rank`
  is King Wen's move with the table's g. The same checks run on the committed n=9 golden
  `scripts/tr12_expected/n9/a2_q3_profile.txt`, a universe anyone can rebuild with
  `scripts/tr12_repro.sh --n9`, which diffs that golden on every run.
- **Q4.** `p̂ = 120937 / 10⁶`, its Wilson interval, `μ_walk^C15` and its interval, and all 175 per-bin
  intervals, recomputed from the counts with the row's own formula. `μ_rec^C15` is **not**
  re-derivable: it needs each draw's record size.
- **Q8.** Every walk in both galleries satisfies C1, C2, C4 and C5, with `C3 = 2·(cd + 1)`; every C15
  walk has C3 ≤ 776; the 16 bucket counts, chi² = 20.224 and the 110/1000 subset count recompute
  from the rank and `cd` columns. That the draws are uniform over SUPER is **not** re-derivable:
  the sampler is gated at n=9 (golden) and n=13 (`TR12_Q8_MIDN13`), and attested at n=31.
- **Q10(a).** The battery's own `c_q10a` row, cut verbatim from `scripts/tr12_repro.sh`, is run on
  the published atlas and the 64 published layer sidecars
  (`runs/20260906_kc_ladders_n31/sidecars/`). Without the t sidecars it reproduces
  `c_q10a_20260922_asrun.txt` byte for byte; with them it reproduces `c_q10a.txt`. This row is
  therefore **reproducible from the tree**, not only attested.

Check the published copies: `cd reports/evidence/tr12/banked_n31_20260922 && sha256sum -c SHA256SUMS`.
These are plain files hashed as raw bytes. None of them is gz-framed, so the #169 framing era does not apply.

## Reproduce with the ladders

Every row except `c_q10a` needs the f ladder, and `a2_q1`, `a2_q2` and `a2_q3_profile` also need the
g ladder: `scripts/tr12_repro.sh --fdir F --gdir G --tdir T --solve SOLVE --out OUT --atlas ATLAS`
with the knobs above.
