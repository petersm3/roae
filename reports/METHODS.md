# Shared Methods Appendix — environment, statistics, and artifact access
*Referenced by every technical report's Verification Guide. Addresses the systemic gaps identified by
the adversarial replication reviews (archived alongside this suite).*

## Environment (version pinning)
| Component | Version | Source |
|---|---|---|
| Repository | pin to the release tag stamped at publication (git tag per suite version) | github.com/petersm3/roae |
| C toolchain | gcc (Ubuntu 22.04 class), flags: `-O2 -pthread -fopenmp` (canonical); `-march=native` allowed for estimator-only runs | — |
| solve.c selftest anchor | sha256 `403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e` | every commit gate |
| Python | 3.10+ stdlib-only (solve.py, sat.py, roae.py, verify.py) | — |
| SAT solver | kissat 4.0.4 (build from source) | github.com/arminbiere/kissat |
| Proof checker | drat-trim (2024+ master) | github.com/marijnheule/drat-trim |
| Lean | 4.31.0 via elan; core only (no mathlib) | `lean lean/KingWen.lean` exits 0 |

## Statistics conventions
- **Knuth estimator CIs**: per-thread means of walk weights; 95% CI = mean ± 1.96·SE across probes
  (SE from the weight variance; printed by `--estimate-knuth` as `95%CI=[..]  relerr=..`). CIs degrade
  visibly at hit rates below ~10⁻⁷ per probe; every reported number states its probe count, and
  strict-form masses near 10⁻⁶ carry the ±10–15% relative-error caveat in-text.
- **Permutation-test nulls**: seeded (`random.Random(42)` unless stated); N=10,000 default; the
  pair-preserving null = shuffle the 32 canonical pairs + independent uniform orientation flips, first
  pair fixed by C4 where stated.
- **Population fractions** are ratios of weighted canonical-leaf masses (orientation-resolved unless
  marked canonical); every scorer's rule semantics has a KW-value reproduction gate
  (`solve.py --registry-verify`) run before any measurement is trusted.

## Artifact access
- **Certificates (DRAT) and raw run outputs** ship publicly with the suite under `reports/certificates/`
  and `reports/evidence/` at publication (relocated from private staging — the verification story
  requires them public). Each cert pairs with the exact `sat.py --emit-cnf <target>` regeneration
  command; encodings are deterministic, so regenerated CNF + archived proof must check.
- **solutions.bin artifacts** are not distributed (size); they are re-derivable to the byte
  (CANONICAL_HASHES.md per-anchor commands) and their shas are the scientific anchor.

## Independence ladder (what requires trusting project code)
1. **Nothing**: DRAT certificates (drat-trim), Lean theorems (kernel), the two-line parity proofs.
2. **Only the encoder** (validated by KW-value gates + two-way SAT tests): the conflict theorem's rule
   faithfulness.
3. **The instrument stack** (cross-validated two-language + self-check): population fractions, estimator
   counts.
Every report's Verification Guide tags its claims with the rung they sit on.
