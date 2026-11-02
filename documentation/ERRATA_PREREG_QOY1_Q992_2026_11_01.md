# Errata to reports/evidence/qoy1_q992/PREREGISTRATION.md (2026-11-01)

**The frozen registration is not edited.** [`PREREGISTRATION.md`](../reports/evidence/qoy1_q992/PREREGISTRATION.md)
is byte-identical to its published copy (sha256 `005a0dab66f77f5921e2cad9260a0310874cfc5ebd6e56a27195e67fc8d23fc2`).
This page records one error of wording in its §9 outcome classes. No verdict or number changes. Found by Codex
(gpt-6-astra), fix-verification round, F02-004#4 and F02-001#3; triaged by Fable. Ledger:
[CORRECTIONS.md](CORRECTIONS.md) CX-36J-H.

## 1. EXPLAINED_BY_EXISTING is not entailment

§9 says that `EXPLAINED_BY_EXISTING` / `FORCED` mean "the observation is a consequence of C1–C5 (or of C1 by
theorem)" and that CITATIONS may note that Ouyang/Han described a feature "that C1–C5 already entail".

- **As registered:** both classes are read as entailment.
- **Corrected:** `EXPLAINED_BY_EXISTING` is a statistical classification — King Wen's value is typical under the
  N1 null — and it does not exclude C1–C5 orderings with other values of the feature; it means **compatible with C1–C5 under
  N1, not entailed**. Entailment language is reserved for `FORCED`, with a proof or an exhaustive demonstration.
