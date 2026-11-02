# Errata to reports/evidence/c8screen/PREREGISTRATION_AMENDMENT_1.md (2026-11-01)

**The frozen amendment is not edited.** [`PREREGISTRATION_AMENDMENT_1.md`](../reports/evidence/c8screen/PREREGISTRATION_AMENDMENT_1.md)
is byte-identical to its published copy (sha256 `3429f1d2272a74344fd6af06cde4e6ba2fcd3c0f57c798053c2f8c0eec6ba8b5`).
This page records one self-contradiction in it. No count changes. Found by Codex (gpt-6-astra), fix-verification
round, F02-005#6; triaged by Fable. Ledger: [CORRECTIONS.md](CORRECTIONS.md) CX-36J-H.

## 1. Not every positional member is NA on Fu Xi

The "Pre-declared consequence" paragraph opens: "Every positional member is `NA` on every control". Its own Fu Xi
bullet, two lines later, says `C-D[083]`, `C-D[115]`, `C-D[127]`, `T-CM[pure]` and `T-DISP[pure]` are defined on
Fu Xi, and its NA count is 49, not 54.

- **As registered:** every positional member is NA on every control.
- **Corrected:** every positional member is NA on Jing Fang and Mawangdui (54 NA each); on Fu Xi five are defined —
  `C-D[083]`, `C-D[115]`, `C-D[127]`, `T-CM[pure]` and `T-DISP[pure]` — giving 49 NA. The pinned counts 54 / 54 / 49
  (`C8_CONTROL_NA_DECLARED`, checked by `C8_CONTROLS_NA_MAP` and `TestC8Scorer`) are the operative statement and
  were always right; only the summary sentence was too broad.
