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
- **Knuth estimator CIs**: probes are i.i.d.; for each reported quantity the per-probe weight X and X²
  are accumulated exactly, and the tool prints mean ± 1.96·√(v̂ar/N) with relerr = SE/mean — a standard
  Wald CI on Knuth's (1975) unbiased estimator. Weighted fractions (masses of canonical weight) are
  same-run ratios ΣWX/ΣW; for fractions ≪ 1 the delta-method variance reduces exactly to the numerator's
  own relative variance, so a fraction's honest relerr equals the relerr of its numerator. S(k)-style
  ratios of separate runs add relative variances (the whole-space denominator's 0.02% is negligible).
  Caveats: weights are right-skewed, so CIs at low effective sample size (n_eff = 1/relerr²; e.g. relerr
  10% → n_eff ≈ 100) are approximate and skew toward underestimation — figures at ≥10% relerr should be
  read as ±20% with ~90–93% practical coverage; zero-hit estimates print 0 with a degenerate CI and are
  reported as starvation, not as bounds. PRNG seeds are fixed constants: re-runs at identical (probes,
  threads) reproduce identical output (a reproducibility feature; runs at the same thread count and
  different probe counts share stream prefixes and are not independent draws). CIs degrade visibly at hit
  rates below ~10⁻⁷ per probe; every reported number states its probe count.
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
  ([CANONICAL_HASHES.md](../documentation/CANONICAL_HASHES.md) per-anchor commands) and their shas are the scientific anchor.

## Independence ladder (what requires trusting project code)
1. **Nothing**: DRAT certificates (drat-trim), Lean theorems (kernel), the two-line parity proofs.
2. **Only the encoder** (validated by KW-value gates + two-way SAT tests): the conflict theorem's rule
   faithfulness.
3. **The instrument stack** (cross-validated two-language + self-check): population fractions, estimator
   counts.
Every report's Verification Guide tags its claims with the rung they sit on.
