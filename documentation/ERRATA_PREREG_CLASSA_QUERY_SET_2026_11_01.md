# Errata to PREREG_CLASSA_QUERY_SET.md (2026-11-01)

**The frozen registration is not edited.** [PREREG_CLASSA_QUERY_SET.md](PREREG_CLASSA_QUERY_SET.md) is
byte-identical to its escrowed revision (sha256 `e73993f602861fddfeb8e6c7d2d88e88b4689bbd0bb764a2d7da6c34055c4b1e`,
[PREREGISTRATION_ESCROW.md](PREREGISTRATION_ESCROW.md)). This page records one error of status in it. No number,
observable or decision rule changes. Found by Codex (gpt-6-astra), fix-verification round, F02-002#1 and F02-H04#1;
triaged by Fable. Ledger: [CORRECTIONS.md](CORRECTIONS.md) CX-36J-H.

## 1. The n=31 scan atlas and King Wen's n=31 profile exist

The two **Class A** paragraphs say that the scan atlas the reader leg loads "has never been built" and that no
full-31 `--kc-profile` run over King Wen's path "has ever been performed"; the second repeats that "the scan atlas
at n=31 has never been built".

- **As registered:** both are unknowns at registration.
- **Corrected:** the n=31 scan atlas is committed at `runs/20260906_kc_ladders_n31/atlas_n31.json` (built
  2026-09-06), and King Wen's n=31 `--kc-profile --kc-tsv --kc-alts` transcript is banked at
  `reports/evidence/tr12/banked_n31_20260922/a2_q3_profile.txt` (2026-09-22; checked by that directory's
  `SHA256SUMS`). Every row of the registration whose answer can be read from either artifact is therefore a
  **pre-known check**, not an escrowed unknown — the same reclassification the registration itself makes for
  `t(root)`. The rows that read neither artifact keep their status.
