# TR-11 F1 evidence

Working notes and Python prototypes behind
[TR-11 — Exact counting by symmetry quotient](../../TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md).

Published 2026-08-14. TR-11's working-notes pointer previously said publication relocation was "TBD";
this directory discharges that. Layout follows the [`f11/`](../f11/) convention: notes, scripts, and
run logs together.

## Contents

**Result**

| File | What it is |
|---|---|
| `f1_exact.out` | The headline result: exact \|C1∩C2∩C4\| and the cross-check against the Knuth estimator (ratio 0.999945). |
| `f1_exact.progress.log` | The run's progress/telemetry stream — group self-checks, per-layer canonical-mask counts, mass, timings. **Renamed on publication** from `f1_exact.err`. It is *not* an error log; the original extension would have suggested the run failed, which it did not. |

**Working notes**

| File | What it is |
|---|---|
| `F1_PHASE3_RECONSTRUCTION.md` | Recursion and state math. |
| `F1_ORBIT_QUOTIENT_2026_07.md` | Quotient design and prototype validation. |
| `FH1_RESIDUAL_DOMINANCE.md` | Capping exactness, irreducibility, projections. |

**Prototypes**

| File | What it is |
|---|---|
| `f1_phase1.py`, `f1_phase2.py`, `f1_phase3.py` | The three phases of the orbit DP. |
| `f1_orbit_dp.py` | The orbit-quotient dynamic program. |
| `fh1_residual_instrument.py` | Residual-dominance instrumentation. |
| `f3_rung_b0_cleanroom.py` | Clean-room rung-b0 recomputation. |

## Running these

The prototypes import from the repository root. On publication their `sys.path` line was changed from a
hardcoded developer path to a resolution relative to each script's own location, so they work from a fresh
clone with no editing. Without that change no reader could have run them, which would have satisfied the
letter of TR-11's artifact-access promise while defeating its purpose.

These are **prototypes**, not the canonical engine. The canonical enumeration lives in `solve.c`; the
analysis ground truth lives in `solve.py`. These scripts document how the exact count was reached and are
published so the result can be checked, not as a supported tool.

## What is not here

Compiled bytecode (`__pycache__`) is deliberately excluded — it embeds absolute build-time source paths
and carries no evidentiary value.
