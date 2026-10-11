# Q-OY1 / Q-992 pre-registration — the two §9 annotations, copied verbatim

The frozen registration ([PREREGISTRATION.md](PREREGISTRATION.md)) says it can be amended only by dated
annotations appended in its §9, and that those annotations fall outside the frozen bytes. The
measurement lane wrote two, both before any estimator run. They are copied below exactly as they
stand in the private annotated file (its lines 441–468). The frozen digest does not cover them.
Their own digest is in [README.md](README.md).

---

### §9-A1 — 2026-10-09T07:04Z (written 07:04:16–07:04:39Z) — instrument pin (measurement lane, Claude Opus 5.5; before any KW evaluation and before any estimator run)

- Frozen bytes verified first: `sha256sum` = `5e15192fc8e4a5283dddb74c7918e32dca2581e414a8e23e2db5defc0c3651fa`, equal to the
  `docs/data/PREREG_LOCK_LEDGER.txt` line 2 entry (commit `0a83ac56`). `DEFCHECK=PASS` re-run (15 PASS lines).
- **INSTRUMENT_PIN** (pre-fill): public worktree detached at `11003eddd3a9453b24c68c8b0c773930b45467f4`, changes STAGED,
  staged tree `git write-tree` = `8fbd4b8e165e7d99016f78df794014575f8ffa83`;
  `solve.c` sha256 `60937db15e2e9e93ceb27d6d859f5f1dd933909ce07a311edc201bec982b4e97`,
  `solve.py` sha256 `542f105a518f98482df07019cdba691c3bed673c737316dc371d75b60b178acd`,
  `tests.py` sha256 `f91b3e11f11aee56a170cd8635e618d2b4baec615bad8440d168973ef962384d`, `verify.py` unchanged (`d6aaf327…`).
- **Deviation D1 (pin form).** §1/§7.2 ask for a *commit*. The lane was instructed "stage only; no commit"; the pin is
  therefore the content-addressed staged tree id plus the three file digests above (equally binding: any later commit
  carrying these bytes reproduces the digests). Recorded here before any run, as §1 requires of the pin.
- Pre-pin self-test (no KW line, random orderings only, so no statistic was evaluated on King Wen):
  `solve.py --qoy-gate <solve> --qoy-gate-skip-kw` on the 10^5 gate-seed orderings → `QOY_VERIFY=PASS`
  (py/C output sha256 both `e379e154…`); parity-mutant build → `QOY_VERIFY=FAIL` (first diff line 1, X↔W).
- Next, in order: fill `QOY_KW_EXPECTED` (the first KW evaluation; §7.1), annotate the post-fill tree (§9-A2), full
  gate with KW + mutant, then the runs.

### §9-A2 — 2026-10-09T07:08Z — KW fill and post-fill instrument (measurement lane; before any estimator run)

- **QOY_KW_EXPECTED fill** (the first evaluation of either statistic on King Wen, §7.1) at 2026-10-09T07:04:39Z:
  `qoy X=0 W=6 T=6 A=0 D=94 NSAME=8 CONSISTENT=YES IDS=03223023033110023211211332012100` (solve.py and solve.c agree).
- **INSTRUMENT_PIN (post-fill, governs the runs):** staged tree `4b590dfcbd0024beefd2bf354949e66ef95c951b` on base
  `11003edd`; `solve.c` `60937db15e2e9e93ceb27d6d859f5f1dd933909ce07a311edc201bec982b4e97` (unchanged from §9-A1),
  `solve.py` `a0ed4150ba1ae6d8fe43ba4d72c6096377133607db3ac2c1a4e4afd134b0b607` (only the `QOY_KW_EXPECTED` literal and
  its comment differ from §9-A1), `tests.py` `f91b3e11…` (unchanged).
- Full gate (KW + 10^5 gate-seed orderings): `QOY_VERIFY=PASS`, `QOY_KW_EXPECTED_MATCH=YES`; parity mutant:
  `QOY_VERIFY=FAIL` ⇒ `QOY_VERIFY_MUTANT=FAIL`. `tests.py TestQoyScorer`: 4/4 OK (incl. the mutant leg red).
