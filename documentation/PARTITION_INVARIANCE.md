# Partition invariance of solve.c enumeration

A formal claim about the solver's behavior: under exhaustive enumeration of
the depth-2 partition, the final `solutions.bin` carries the same logical
(decompressed) record stream — hence the same canonical sha256 — regardless
of whether the 56 first-level branches are enumerated concurrently in a
single invocation or individually across multiple invocations with a
subsequent merge.

This document is the companion to [`SPECIFICATION.md`](SPECIFICATION.md) and
[`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md). It is cited from several other
markdown documents in this repository; see §6 below.

## 1. Statement

**Theorem (Partition Invariance).** Let `S` be the full depth-2 partition
of the search space into 56 first-level (pair, orient) branches, each with
its ≤ 60 depth-2 sub-branches. Let `E(B)` denote exhaustive backtracking
enumeration of branch `B` under constraints C1–C5 with unlimited node
budget, producing a set of `sub_P1_O1_P2_O2.bin` shard files. Let `M(F)`
denote the merge operation applied to a set of shard files `F`, producing
a `solutions.bin`.

Write `E_full(B)` for the shards branch `B` contributes to a single
full-parallel invocation over all of `S`, and `E_branch(B)` for the shards
produced by an invocation restricted to `B` alone (`--branch P O`). These are
a priori two different functions of `B` — nothing in the definitions forces
them to agree — and the theorem is that they merge to the same canonical
output:

    sha256( M( ⋃_{B ∈ S} E_full(B) ) )  =  sha256( M( ⋃_{B ∈ S} E_branch(B) ) )

Each `sha256` is taken over the **logical (decompressed)** record stream of
the merged `solutions.bin`, per [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md)
§"On-disk framing". §2.1 and §2.2 supply the bridge (`E_full = E_branch`
pointwise, as sets of named shards) and §2.3 that the merge is a function of
the shard set alone. The parameterisation mirrors `grouping_invariance` (T5)
in [`lean/PartitionInvariance.lean`](../lean/PartitionInvariance.lean), which
quantifies over an arbitrary per-cell shard function and two groupings of the
cell-index list rather than assuming the two sides equal.

Informally: running the solver 56 times, one branch each, merging the
shards once at the end, produces the same canonical output as running
the solver once over the whole partition.

**Empirical validation grid.** The theorem has been validated against the
project's reference sha256s — which are computed over the logical
(decompressed) stream — across multiple independent axes:

| Axis | Validations |
|---|---|
| **Hardware: Zen 4 vs Zen 5** | F64als_v6 westus2 ↔ D128als_v7 westus3, d3 10T sha `f7b8c4fb…` matches (2026-04-19; sha since deprecated as a canonical — the cross-hardware match evidence stands, see [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §Deprecated) |
| **Architecture: x86 vs ARM** | Zen 5 ↔ Cobalt 100 ARM (D96ps_v6 westus3), d3 10T sha `f7b8c4fb…` matches (2026-04-28; same deprecation note) |
| **Region: westus2 vs westus3** | F64 westus2 ↔ D128 westus3, same sha (2026-04-19) |
| **Merge mode: external vs in-memory** | Both produce the canonical sha at d3 10T (2026-04-19) |
| **Partition strategy: full-enum vs --branch reconstruction (depth 3, same per-sub-branch budget)** | sha `c34390c00a2a871d78f49dd419779c0f649ed8271387c424ac4d36e0f3910dbd` matches across both paths at 5.6T budget (35.4M nodes/sub-branch). Verified via `--double-regression-test` (2026-04-30). |
| **Layered-merge correctness** | Layer 1 + Layer 2 of identical scope, merged via `--merge-layers`, produces same sha as a single-layer run (2026-04-30). |

The 5.6T regression test is the strongest validation of the theorem to
date — it explicitly verifies the `solve 0 64 == solve --branch p1 o1 × 56`
equivalence at depth-3 partitioning with controlled per-sub-branch
budgets via `SOLVE_PER_SUB_BRANCH_LIMIT`. See
[`HISTORY.md`](HISTORY.md) §"April 29, 2026" for the full retrospective
including the depth-2 bug that surfaced and was fixed during the test.

## 2. Proof

The equivalence follows from three independent determinism properties
of `solve.c`. Each is described in detail in a referenced doc; stated
concisely here:

### 2.1 Per-sub-branch backtracking is deterministic

Given a fixed prefix `(P1, O1, P2, O2)` and the constraint set (C1–C5),
the backtracking search in `solve.c`:

- Visits nodes in a fixed order (outer loop over pair index 0..31, inner
  loop over orient 0..1; see `backtrack` in the solver).
- Uses a deterministic per-thread hash table to canonicalize records
  (FNV-1a hash; orient bits masked via `& 0xFC` at insert; full-byte
  equality check on probe — see [`SPECIFICATION.md`](SPECIFICATION.md)
  Definitions and the `compare_canonical` comment block in `solve.c`).
- Flushes the hash-table contents to `sub_P1_O1_P2_O2.bin` at end of
  sub-branch in a deterministic record order (atomic write via
  `.tmp` + `rename`; see [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md)).

**Consequence**: two invocations that enumerate the same `(P1, O1, P2, O2)`
prefix to exhaustion produce `sub_P1_O1_P2_O2.bin` shards with **identical
decompressed record streams** (identical logical sha256), regardless of
thread count, time of day, machine architecture (for byte-addressable
8-bit-byte hosts), or invocation mode (full-parallel vs. single-branch via
`--branch P O`).

Physical container bytes match *additionally* only under a fixed compression
profile: since #169 shards are gzip-framed by default (`SOLVE_COMPRESS`, at
level `SOLVE_GZIP_LEVEL`), and gzip framing varies with zlib version and
level. A physical-container sha256 must therefore **not** be used as the
acceptance test — it false-mismatches an artifact that is identical where it
counts. `solve.c`'s own `SOLVE_COMPRESS` comment block states the rule: gzip
is a non-sha-determining storage layer, and every sha is computed on
decompressed bytes.

### 2.2 Shard filenames are content-addressable by prefix

The filename `sub_P1_O1_P2_O2.bin` is determined solely by the sub-branch's
prefix. Same prefix → same filename. There is no invocation-specific suffix,
no thread ID, no timestamp embedded in the name.

**Consequence**: when shards from multiple invocations are gathered into
one directory, each `(P1, O1, P2, O2)` appears exactly once. The merge's
input set is uniquely determined by the union of prefixes enumerated.

### 2.3 Merge is deterministic

The merge (`./solve --merge` or the post-enumeration merge in normal mode):

- Enumerates all `sub_*.bin` files in the working directory (order
  varies by `readdir`, but the merge is insensitive to it).
- Reads all records into a buffer (in-memory mode) or sorts chunks via
  external-merge-sort.
- Sorts by `compare_solutions`, which defines a **total strict order** on
  distinct records (see [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md) §Sort
  order). No two distinct records compare equal; therefore any correct
  sort algorithm produces the same sorted sequence.
- Removes canonical duplicates via `compare_canonical`, keeping the
  lexicographically-smallest orient variant per canonical class (defined
  unambiguously by the total-order sort).
- Writes the v1 header + record stream. The header contains only
  deterministic-from-input fields (magic, format version, record count);
  no timestamps or build identifiers.

**Consequence**: the `solutions.bin` produced by the merge is a pure
function of the input shard set. Same shard set → same logical record
stream, hence the same canonical sha256.

### 2.4 Combining the three properties

(2.1) and (2.2) imply that the union of shards from 56 single-branch
invocations and the union of shards from one full-parallel invocation
are **the same set of shard names carrying the same logical record
streams** — that is, `E_full = E_branch` pointwise. (2.3) implies the
merge produces the same logical `solutions.bin` stream given equal input
sets. Therefore the two paths produce the same canonical sha256. ∎

## 2a. Machine-checked formalization (Lean 4) — and its exact scope

The mathematical core of the argument above is machine-checked:
[`lean/PartitionInvariance.lean`](../lean/PartitionInvariance.lean)
(Lean 4.31.0, core only, standalone file, zero `sorry`; toolchain
pinned in [`lean/lean-toolchain`](../lean/lean-toolchain)) proves that
the abstract merge model — sort by the two-tier comparator, keep the
first record of each canonical class — is invariant to input order
(T1), partition choice (T3, including cross-depth prefix-cell
partitions), invocation grouping (T5), and merge hierarchy / dedup
placement (T4), and characterizes the output's content exactly (T2).
See [`lean/README.md`](../lean/README.md) §Tier 3 for the theorem
list.

**Scope of the machine-checked result — read carefully.** What is
machine-proven is the abstract merge **model**. The connection between
that model and the actual C enumerator (`solve.c`) runs through four
stated **bridge facts B1–B4** — per-cell exhaustive
completeness/determinism (§2.1), content-addressed shard union
semantics (§2.2), min-selection at every dedup site, and
serialization determinism — which are explicit modeling assumptions,
cited in the Lean file's header by `solve.c` function name, and are
**NOT themselves machine-checked**. In particular, nothing in the
Lean development proves the enumeration pipeline or `solve.c` itself
correct or bug-free; the machine-checked theorem is a model-level
result. The end-to-end evidence for the real pipeline remains the
empirical sha-reproduction record in §5a (cross-hardware, cross-ISA,
cross-region, cross-merge-mode, cross-invocation-mode sha-identical
canonicals) — the formal model and the empirical record are
complements, not substitutes.

## 3. Scope restriction: exhaustive vs budgeted

The theorem as stated requires **exhaustive enumeration** of each
sub-branch (enumeration completes naturally, tagged EXHAUSTED). Under a
node budget (`SOLVE_NODE_LIMIT > 0`), the sub-branch may terminate with
BUDGETED status, having found only a subset of its valid records.

In budgeted runs, the per-sub-branch budget is derived from the total
budget divided by the number of sub-branches enumerated:

    per_branch_node_limit = SOLVE_NODE_LIMIT / n_sub_branches_in_this_run

The denominator depends on invocation mode:

| Invocation | n_sub | Per-sub-branch budget at 10T total |
|---|---|---|
| `./solve 0` (full enum, depth 2 / SOLVE_DEPTH=2) | 3,030 | ~3.3B nodes |
| `./solve 0` (full enum, depth 3 / SOLVE_DEPTH=3) | 158,364 | ~63M nodes |
| `./solve --branch P O 0` (one first-level branch, depth 2) | ~54 | ~185B nodes |
| `./solve --branch P O 0` (one first-level branch, depth 3, post-2026-04-30 fix) | ~2,828 | ~3.5B nodes |

Without controlling per-sub-branch budget explicitly, the single-branch
runs receive different per-sub-branch budgets than full-enum for the same
`SOLVE_NODE_LIMIT`. They reach further into (or shorter into) each
sub-branch's search tree, find different valid records, and the merge
produces a different sha256.

**Recommended: use `SOLVE_PER_SUB_BRANCH_LIMIT` (added 2026-04-29).**
This env var sets the per-sub-branch budget DIRECTLY, overriding the
auto-divide. Both invocation modes can pass the same value to walk every
sub-branch with identical budget regardless of how many sub-branches are
in their respective scopes. This is how the 2026-04-30
`--double-regression-test` verifies invariance: full-enum and
56-branch-reconstruction both run with `SOLVE_PER_SUB_BRANCH_LIMIT=35361572`
at SOLVE_DEPTH=3, producing byte-identical sha
`c34390c00a2a871d78f49dd419779c0f649ed8271387c424ac4d36e0f3910dbd`.

The legacy manual scaling (multiply `--branch` budget by
`n_sub_in_branch / total_sub_branches`) is mathematically equivalent
when budgets are uniform, but `SOLVE_PER_SUB_BRANCH_LIMIT` is more direct
and less error-prone — particularly because n_sub varies across the 56
first-level branches at depth 3: **2,824 to 2,850 cells per branch, mean
2,827.93 of 158,364 total — a spread of 26 cells, under 1%**. (Recomputable
from public artifacts: run `solve.c`'s depth-3 partition loops — the
`p1/o1 → p2/o2 → p3/o3` nest with the `bd == 5` and C5-budget prunes — over
`verify.py`'s `PAIRS` table and `_c5_budget_from_kw()`; the same enumeration
yields the 3,030 depth-2 and 158,364 depth-3 cell totals quoted above.) The
auto-divide therefore produces mildly non-uniform per-sub-branch budgets that
defeat an invariance comparison; `SOLVE_PER_SUB_BRANCH_LIMIT` avoids the
issue entirely.

Under exhaustive enumeration, all of this is moot — no budget applies —
and the theorem in §1 holds unconditionally.

**Bug note (2026-04-29 / 30).** Prior to commit `cdd8575`, `--branch
P O` always partitioned to depth-2 even when `SOLVE_DEPTH=3` was set.
This produced `sub_P1_O1_P2_O2.bin` shards (depth-2 names) while
full-enum at SOLVE_DEPTH=3 produced `sub_P1_O1_P2_O2_P3_O3.bin` shards
(depth-3 names) — incomparable file sets, so the merges could not be
sha-checked even with matched per-sub-branch budgets. The fix routes
`--branch` at SOLVE_DEPTH=3 through the depth-3 enumeration path,
producing matching shard names. The 5.6T regression test PASSED with
this fix in place.

## 4. Cross-depth invariance

The theorem is **depth-specific** under budget. The depth-2 and depth-3
partitions are genuinely different partitions (3,030 sub-branches vs
158,364 sub-branches). Under the same `SOLVE_NODE_LIMIT`, the auto-divide
produces per-sub-branch budgets that differ by a factor of ~52, so the
depth-2 and depth-3 outputs find different subsets of the valid-orderings
space and their shas differ.

**Within a fixed depth, partition-strategy invariance has been empirically
confirmed.** At depth 3 with `SOLVE_PER_SUB_BRANCH_LIMIT=35361572`
(equivalent to 5.6T total budget / 158,364 sub-branches):

- Full-enum at depth-3 produces sha `c34390c00a2a871d78f49dd419779c0f649ed8271387c424ac4d36e0f3910dbd`
- 56 invocations of `--branch p1 o1 0 64` at depth-3 with same per-sub-branch
  budget, merged via `--merge-layers`, produce **byte-identical sha**.
- A repeat of the same enumeration produces byte-identical sha (deterministic).

This was the 2026-04-30 `--double-regression-test` verification.

**Under exhaustive enumeration**, the depth-2 and depth-3 partitions
**both** enumerate the same mathematical object (all orderings satisfying
C1–C5), so the final `solutions.bin` files would carry identical logical
record streams, hence identical canonical sha256. This
is a stronger claim — cross-depth invariance under exhaustion — that
follows from the same three determinism properties combined with the
observation that the canonical dedup step erases any trace of partition
depth from the output.

We have **not empirically verified** depth-invariance under exhaustion
because neither a 10T d3 run nor a 10T d2 run reaches exhaustion on
any sub-branch at current budgets. Both hit BUDGETED on every
sub-branch. This remains an empirical conjecture. Note what the awaited
test has to be: exhausting one *arbitrary* cell at each depth compares two
different search domains and settles nothing, because a depth-2 cell covers
the union of many depth-3 child cells. A valid local test is exhausting one
depth-2 sub-branch **together with all of its depth-3 children**, and then
checking that the merge of the children's shards equals the depth-2 cell's
own output. At the **model
level** it is now machine-checked: `cross_depth_invariance` in
[`lean/PartitionInvariance.lean`](../lean/PartitionInvariance.lean)
proves that exhaustive enumeration sharded at any two depths merges to
identical canonical output — subject to the same B1–B4 bridge-fact
scope stated in §2a (the theorem is about the merge model, not about
`solve.c` itself).

## 5. Practical applications

This theorem underpins several project workflows:

- **Cross-validation of the canonical sha** (Phases B and C of the
  2026-04-18 validation cycle): re-merging 2026-04-17 shards vs.
  freshly re-enumerating the same partition produces the same canonical
  sha256 precisely because of (2.1). See
  [`HISTORY.md`](HISTORY.md) "Canonical v1 reference shas established"
  entry.
- **Accumulating ground-truth workflow**: exhausting individual
  first-level branches in sequence, accumulating their shards on a
  shared disk, and later running full-mode enumeration on the
  remaining branches produces a larger (still partition-invariant)
  `solutions.bin`. See [`DEVELOPMENT.md`](DEVELOPMENT.md) for the
  operational procedure and the `SOLVE_CONCENTRATE_BUDGET` env var
  that controls how the remaining node budget is distributed.
- **Independent verification**: a third party implementing an
  alternative verifier (see [`REBUILD_FROM_SPEC.md`](REBUILD_FROM_SPEC.md))
  does not need to replicate the solver's invocation mode — they need
  only to correctly apply the constraints and the canonical-dedup
  semantics. Partition invariance guarantees the underlying solution
  set is the same regardless of how it was computed, *given the same
  budget regime* (§3). **Scope**: such a verifier checks that every
  published record is valid, correctly ordered and correctly deduped. It
  cannot establish that the published set is **complete** — every canonical
  is budget-limited, and C1–C5 plus the dedup semantics do not determine
  which subset a finite DFS budget reaches. Completeness of the published
  stream is the enumeration's claim, attested by the canonical sha256, not
  something re-derivable from the specification; `REBUILD_FROM_SPEC.md`
  §"Gaps and limitations of this recipe" says so in its own terms ("this
  recipe produces a verifier, not an enumerator").
- **Distributed / pooled enumeration** (speculative, long horizon):
  if the project ever extends to a "many contributors enumerate
  different branches" model, the merge-from-any-subset property is
  what makes it work. Each contributor produces a shard with the same
  logical record stream for their assigned prefix; the coordinator merges
  all contributions. Acceptance must compare **logical** (decompressed)
  shard sha256s, never container bytes — contributors will not share a
  zlib version or compression level (§2.1).
- **Layered enumeration extension**: the `--merge-layers` mode
  (added 2026-04-29, see [`DEVELOPMENT.md`](DEVELOPMENT.md)
  §"Layered enumeration") composes invariance across multiple
  enumeration runs at potentially different per-sub-branch budgets.
  Later layers' shards override earlier layers' for the same
  sub-branch; the merger is deterministic on the logical stream given a
  fixed set of layers in a fixed sort order. Verified at 5.6T scale 2026-04-30.

## 5a. Empirical evidence — invariance verified directly at 5.6 T and 100 T; inherited at 560 T

Each row below states the proposition its evidence actually establishes,
drawn from a fixed vocabulary: **partition-path**, **execution-mode**,
**host/ISA + build**, **re-run determinism**, **inherited**. Partition
invariance itself is directly witnessed at 5.6 T and 100 T. The 11.2 T
witnesses vary build, host and ISA rather than the partition, and 560 T
inherits — see the paragraph below the table.

| Scale | First witness | Independent re-derivations | Evidence type |
|---|---|---|---|
| 5.6 T | 2026-04-30 | `--double-regression-test` + `--merge-layers` of 56 `--branch p1 o1` reconstruction layers | **Partition-path** — direct sha-equality across 4 partition paths |
| 11.2 T | 2026-04-30 / 2026-05-01 | Build A + Build B (different physical D64als_v7 hosts) + ARM Cobalt + v3 lineage + Tier 1 hardening — the witness list of record is [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §"d3 11.2T"; this document does not restate its count | **Host/ISA + build** — direct sha-equality across host class, source commit and ISA. Not a partition witness: none of these runs varies the partition |
| 100 T | 2026-04-19/20 (full-enum), then T9+d 2026-05-10 (62-branch-loop reconstruction) | T9+d's `solve --branch` × 62 + `solve --merge` execution path reproduced the canonical `915abf30…` of the full-enum path | **Execution-mode** — direct sha-equality between full-enum and 62-branch reconstruction + merge |
| **560 T** | **2026-06-08; re-run 2026-06-30** | `solve --verify` PASS on all 10,525,271,997 records + `verify.py` re-verify, **and** a from-scratch re-run (2026-06-30, eviction-resume-fixed binary, different eviction pattern) reproduced `9a968fa2` exactly | **Re-run determinism** (from-scratch re-run reproducing the canonical sha over the **same** d3 partition) + **inherited** — partition invariance from the 5.6 T and 100 T direct witnesses on the same `solve.c` lineage |

At the 560 T scale, a full independent partition-strategy re-run was deferred on
cost grounds and **has not been performed**. The 2026-06-30 from-scratch re-run
(eviction-resume-fixed binary, a different eviction pattern) reproduced the canonical
`9a968fa2` exactly, but it re-ran the **same depth-3 partition**: what it witnesses
is re-derivation determinism and eviction-resume correctness, **not** partition
invariance, and it does not discharge the deferred partition-strategy run. Partition
invariance at 560 T is therefore **inherited**, and the inheritance rests on two
things: (i) partition invariance is a theorem about the deduplication semantics, not
the scale, and (ii) the same `solve.c` lineage shown partition-invariant directly at
5.6 T (4 partition paths) and 100 T (full-enum vs 62-branch reconstruction) is what
produced the 560 T canonical — with the 11.2 T witnesses establishing that this
lineage is sha-stable across build, host and ISA. The 5.6 T and 100 T direct
witnesses are thus the partition-invariance load-bearing evidence for the entire
canonical chain.

The 2026-06-14 three-point per-cell trajectory analysis adds an
independent consistency check: keyed by pair-identity (the dedup
granularity), the canonical record sets are **strictly nested**
(11.2 T ⊆ 100 T ⊆ 560 T) with **0 monotonicity violations** in either
jump — exactly what monotone per-cell budget growth predicts under
scale-invariant dedup semantics. A budget-only extension that violated
partition/dedup invariance **would be expected to** drop or reorder
records at the larger scale; none occur (0 cells lose records; all only
gain). But the necessity does not hold: strict nesting of the observed
sets is equally consistent with a defect that only *adds* records, one
that omits the same records at every scale, or one that lives only in an
invocation mode these runs did not exercise. This is therefore
corroboration of monotone budget traversal — **not** a test of partition
invariance, and not a substitute for the direct sha-equality witnesses
above — that the 560 T canonical sits on the same invariant lineage.
(Orientation-specific keying shows spurious
"violations" that are an artifact of orientation-collapse dedup choosing
a different representative per scale, not real non-monotonicity; masking
orientation removes all of them.) See
[HISTORY.md](HISTORY.md) §"3-point per-cell scaling trajectory" for the
per-scale figures. Reproduction note: the comparison ran over the archived
per-cell shards of the three canonicals — nothing in this checkout — and
this document carries no command for re-deriving the "0 monotonicity
violations" figure, so read it as a recorded measurement rather than a
re-runnable one.

## 6. Citations from other repository docs

This theorem is referenced by:

- [`SPECIFICATION.md`](SPECIFICATION.md) — Theorem (Partition invariance)
  block, next to the existing Theorem 1 (within-pair distance) and
  Theorem 2 (XOR universality).
- [`DEVELOPMENT.md`](DEVELOPMENT.md) — the accumulation-workflow
  subsection relies on this theorem to justify that `cp`-ing shards
  across runs preserves output correctness.
- [`REBUILD_FROM_SPEC.md`](REBUILD_FROM_SPEC.md) — footnote in the
  "independent verifier trust" section.
- [`HISTORY.md`](HISTORY.md) — Phase C cross-validation narrative.
- [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md) — §Sort order +
  §Deduplication sections reference partition invariance as the
  reason their determinism guarantees matter.

## 7. Further reading

- [`SPECIFICATION.md`](SPECIFICATION.md) — formal definitions of
  C1–C5, pair structure, partner function.
- [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md) — binary file format,
  total-order comparator, canonical-dedup semantics.
- [`BRANCHES_EXPLAINED.md`](BRANCHES_EXPLAINED.md) — plain-language
  walkthrough of branches, sub-branches, all-branch vs single-branch
  enumeration, and how partition invariance composes.
- [`DEVELOPMENT.md`](DEVELOPMENT.md) — `Layered enumeration` section
  documenting the `--merge-layers` infrastructure verified by the
  2026-04-30 regression test.
- `solve.c` — the `compare_solutions` and `compare_canonical` comment
  block gives the proof-of-correctness argument for the merge's
  determinism in terms of the code path.
- [`lean/PartitionInvariance.lean`](../lean/PartitionInvariance.lean) +
  [`lean/README.md`](../lean/README.md) §Tier 3 — the machine-checked
  model-level formalization of §2 (scope note in §2a above).
- [`REBUILD_FROM_SPEC.md`](REBUILD_FROM_SPEC.md) — a language-agnostic
  recipe for an independent **verifier**. It establishes record validity
  (C1–C5), sort order and canonical dedup; by its own §"Gaps and limitations
  of this recipe" it is not an enumerator and establishes neither
  completeness nor budget reachability. The solution set's completeness is
  the enumeration's claim, attested by the canonical sha256.
