# Partition invariance of solve.c enumeration

A formal claim about the solver's behavior: under exhaustive enumeration of
the depth-2 partition, the final `solutions.bin` is byte-identical regardless
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

Then:

    sha256( M( ⋃_{B ∈ S} E(B) ) )  =  sha256( M( ⋃_{B ∈ S} E(B) ) )

where the left side denotes shards produced by a single full-parallel
invocation and the right side denotes shards produced by 56 independent
single-branch invocations. The two `solutions.bin` files are byte-identical.

Informally: running the solver 56 times, one branch each, merging the
shards once at the end, produces the same canonical output as running
the solver once over the whole partition.

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
  sub-branch in a byte-exact deterministic manner (atomic write via
  `.tmp` + `rename`; see [`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md)).

**Consequence**: two invocations that enumerate the same `(P1, O1, P2, O2)`
prefix to exhaustion produce byte-identical `sub_P1_O1_P2_O2.bin` files,
regardless of thread count, time of day, machine architecture (for byte-
addressable 8-bit-byte hosts), or invocation mode (full-parallel vs.
single-branch via `--branch P O`).

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
function of the input shard set. Same shard set → byte-identical output.

### 2.4 Combining the three properties

(2.1) and (2.2) imply that the union of shards from 56 single-branch
invocations and the union of shards from one full-parallel invocation
are **identical sets of byte-identical files**. (2.3) implies the
merge produces byte-identical `solutions.bin` given equal input sets.
Therefore the two paths produce byte-identical `solutions.bin` and
hence identical sha256. ∎

## 3. Scope restriction: exhaustive vs budgeted

The theorem as stated requires **exhaustive enumeration** of each
sub-branch (enumeration completes naturally, tagged EXHAUSTED). Under a
node budget (`SOLVE_NODE_LIMIT > 0`), the sub-branch may terminate with
BUDGETED status, having found only a subset of its valid records.

In budgeted runs, the per-sub-branch budget is derived from the total
budget divided by the number of sub-branches enumerated:

    per_branch_node_limit = SOLVE_NODE_LIMIT / n_sub_branches_in_this_run

The denominator depends on invocation mode:

| Invocation | Typical n_sub | Per-sub-branch budget at 10T total |
|---|---|---|
| `./solve 0` (full parallel, depth 2) | 3,030 | ~3.3B nodes |
| `./solve --branch P O 0` (one first-level branch, depth 2) | ~54 | ~185B nodes |
| 56 × `--branch P O 0` individually at 10T each | ~54 each | ~185B each (aggregate 10T × 56 = 560T node budget) |

Under budget, the single-branch runs receive 56× more per-sub-branch
budget than full-parallel for the same `SOLVE_NODE_LIMIT`. They reach
further into each sub-branch's search tree, find more valid records,
produce different shards, and the merge produces a different sha256.

To reproduce the full-parallel budgeted sha via stitched single-branch
runs, pass each `--branch P O` invocation a budget of:

    SOLVE_NODE_LIMIT × (n_sub_in_this_branch / total_sub_branches)

For 10T full-mode at depth 2 (3,030 total sub-branches, ~54 per first-
level branch): each single-branch run gets 10T × 54 / 3030 ≈ 178B nodes.
Every sub-branch across both invocation modes then sees the same ~3.3B
per-sub-branch budget, produces the same shards, and the merges match.

Under exhaustive enumeration, this scaling is moot — no budget applies —
and the theorem in §1 holds unconditionally.

## 4. Cross-depth invariance

The theorem is **depth-specific**. The depth-2 and depth-3 partitions
are genuinely different partitions (3,030 sub-branches vs 158,364
sub-branches). Under the same `SOLVE_NODE_LIMIT`, the per-sub-branch
budgets differ by a factor of 52, so the depth-2 and depth-3 outputs
find different subsets of the valid-orderings space and their shas
differ.

Under exhaustive enumeration, the depth-2 and depth-3 partitions
**both** enumerate the same mathematical object (all orderings
satisfying C1–C5), so the final `solutions.bin` files would be
byte-identical. This is a stronger claim — depth-invariance under
exhaustion — that follows from the same three determinism properties
combined with the observation that the canonical dedup step erases
any trace of partition depth from the output.

We have **not empirically verified** depth-invariance under exhaustion
because neither a 10T d3 run nor a 10T d2 run reaches exhaustion on
any sub-branch at current budgets. Both hit BUDGETED on every
sub-branch. This remains a conjecture pending eventual exhaustion of
at least one sub-branch at each depth.

## 5. Practical applications

This theorem underpins several project workflows:

- **Cross-validation of the canonical sha** (Phases B and C of the
  2026-04-18 validation cycle): re-merging 2026-04-17 shards vs.
  freshly re-enumerating the same partition produces byte-identical
  output precisely because of (2.1). See
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
  set is the same regardless of how it was computed.
- **Distributed / pooled enumeration** (speculative, long horizon):
  if the project ever extends to a "many contributors enumerate
  different branches" model, the merge-from-any-subset property is
  what makes it work. Each contributor produces a byte-identical shard
  for their assigned prefix; the coordinator merges all contributions.

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
- `solve.c` — the `compare_solutions` and `compare_canonical` comment
  block gives the proof-of-correctness argument for the merge's
  determinism in terms of the code path.
- [`REBUILD_FROM_SPEC.md`](REBUILD_FROM_SPEC.md) — a language-agnostic
  recipe for an independent verifier; demonstrates by construction
  that the solution set is specification-derivable.
