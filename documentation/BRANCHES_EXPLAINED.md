# Branches, Sub-Branches, and Nodes: a step-by-step explanation

A plain-language walkthrough of what the ROAE solver actually does, what
a "branch" is, what a "node" means, and how the picture builds up.

For the formal version, see [SPECIFICATION.md](SPECIFICATION.md). For
the findings in plain language, see [SOLVE_SUMMARY.md](SOLVE_SUMMARY.md).
This document is the bridge: how the math actually gets done.

---

## Part 1: The puzzle

There are exactly **64 hexagrams** — patterns of 6 stacked lines, each
line either solid or broken. ([SOLVE_SUMMARY.md §What a hexagram is](SOLVE_SUMMARY.md)
shows the picture.)

Long ago — traditionally about 3,000 years, though the dating is debated —
somebody in ancient China, or generations of practitioners, arranged all 64 in a
specific order, called the **King Wen sequence**. The order isn't
obviously random — consecutive hexagrams differ in special ways. So we
ask: were there RULES? And if so, what?

These rules weren't all discovered at once, and not all of them are
ROAE's. Pulling apart the King Wen sequence to find its mathematical
structure has been a project of many people over the centuries. ROAE
codifies five rules — call them C1 through C5 — and the credit for each
is different:

- **C1 — Pairs.** The 64 hexagrams are arranged as 32 consecutive
  pairs. Within each pair, the two members are either complements of
  each other (every line flipped) or upside-down versions of each
  other. *This is a classical observation* — it appears in the *Yi
  Zhuan* commentary tradition (traditionally dated ~5th-3rd c. BCE,
  though modern dating is later); the earliest rigorous modern-form
  presentation known to this project is
  [Goldenberg (1975)](CITATIONS.md#goldenberg1975) (first in the Western
  literature), with
  the fullest treatment in [Cook (2006)](CITATIONS.md#cook2006); the
  pairing convention is used throughout
  [Wilhelm & Baynes (1967)](CITATIONS.md#wilhelm-baynes1967).
  Not novel to ROAE.
- **C2 — No 5-line transitions.** No two consecutive hexagrams differ
  by exactly 5 lines. Within a pair this is automatic, so in practice
  the rule constrains the boundaries between consecutive pairs.
  *Identified by [Terence McKenna](CITATIONS.md#mckenna-mckenna1975)* in *The Invisible
  Landscape* (1975), and independently by Cook (2006) in his combinatorial
  analysis. Not novel to ROAE.
- **C3 — Complement distance.** Every hexagram has a complement (every
  line flipped) sitting somewhere else in the sequence. Averaged over
  all 64 hexagrams, the distance between a hexagram's position and its
  complement's position must be at most 12.125 — or **776** in the ×64
  integer form the solver uses. *Formulated by ROAE* as a
  specifically-quantified constraint; no prior published source
  identified.
- **C4 — Starts with (63, 0).** The first hexagram is ䷀ #1
  (binary 111111, the all-solid pattern), and the second is its
  complement ䷁ #2 (binary 000000, all-broken). The
  *choice* of this pair first is classically attested (the *Xugua*
  commentary's ordering rationale); the *orientation* (Creative before
  Receptive) is C4's own definitional choice — this project's convention,
  not something the classical record attests — and is **not** forced by
  the other rules. ⚠ **[CORRECTED 2026-09-01 — the orientation was
  previously described here as classically attested too, on the strength
  of the *Xugua*'s opening. The *Xugua* attests that the {Heaven, Earth}
  pair opens, not the order of Heaven over Earth within it: 天地 is a
  compound, not an ordering. The pair-choice clause immediately above is
  unaffected and stands. Narrowed in
  [METHODS.md](../reports/METHODS.md) §"Constraint set" on 2026-08-30.]**
  Complementing every hexagram maps any valid arrangement to an
  equally-valid one opening (0, 63) that still satisfies C1, C2, C3, and
  C5 (machine-checked in [lean/KingWen.lean](../lean/KingWen.lean)). *(An earlier version claimed the
  orientation was forced by C5 — retracted 2026-07-26; see SOLVE_SUMMARY.md / CLAIMS_DECIDED.md.)*
- **C5 — Distance count.** Across the 63 consecutive transitions, the
  number of distances of each value (1, 2, 3, 4, 6) has to match a
  fixed distribution: 1×two, 2×twenty, 3×thirteen, 4×nineteen,
  6×nine. *Formulated by ROAE* as a specifically-quantified constraint;
  no prior published source identified.

(These labels match the formal constraint numbering in
[SPECIFICATION.md](SPECIFICATION.md).)

What ROAE adds is the **conjunction**: treating C1+C2+C3+C4+C5 as a
single constraint system and asking how many distinct orderings satisfy
all five at once. Individual rules are in prior work; **what this project
supplies is the measurement** — an exact, reproducible count over defined
slices. See [CITATIONS.md](CITATIONS.md) for the detailed prior-work
record.

**Scoped 2026-08-16.** This sentence previously read "the joint
enumeration is the novel contribution." **That was an unhedged priority
claim and it is withdrawn as stated.** A prior-art sweep aimed
specifically at the mathematics of the hexagram *ordering* — as distinct
from its symmetry or its symbols — was not run until 2026-08-16, and it
returned a Chinese literature this repository had not counted: work on
the 「錯綜」-invariant sets (2000), on the topological group structure of
the hexagram symbols (1995), and on the mathematical regularity of the
received sequence's *arrangement* (2002 and 2003). **None of those is yet
known to produce a count of satisfying orderings**, which is the specific
thing measured here — **but "not yet known" is not "does not exist", and
the claim is stated narrowly for that reason.** This matches the
[README](../README.md)'s longstanding framing: *the direction is not new,
the measurement is.* The measurement, its artifacts and its reproduction
commands stand regardless of how the priority question resolves.

The job of the solver is: **find every ordering of the 64 hexagrams
that satisfies C1-C5.** That is the *goal*; it is not what any run has
achieved. Every published enumeration is budgeted and returns a
reproducible *slice*, so its count is a lower bound — see
[`SOLUTIONS_FORMAT.md`](SOLUTIONS_FORMAT.md) and
[`SEARCH_SPACE_SIZE.md`](SEARCH_SPACE_SIZE.md). How many are there? Is King Wen one of
millions, or one of three? Or the only one?

---

## Part 2: Brute force is impossible

The number of ways to arrange 64 unique things in a row is 64 factorial,
written 64!. That's:

```
64! ≈ 1.27 × 10^89
```

(A 1 followed by 89 zeros.) For comparison, there are about 10^80 atoms
in the observable universe. So checking every arrangement and asking
"does this one obey C1-C5?" would take longer than the age of the
universe even on a computer that does a trillion checks per second.

But we don't have to check ALL of them. The constraints rule out huge
chunks of the search space EARLY, often after just the first few
hexagrams are placed. That's the key insight: **we can throw away whole
families of arrangements without examining them one by one.**

This is the core trick of "constraint-driven search" or "tree search
with pruning." Instead of checking 10^89 leaves of a tree, we walk the
tree from the top, and every time we reach a node where the rules are
already broken, we *cut off everything below it* and back up.

---

## Part 3: The first move is forced

Constraint C4 says the first hexagram must be ䷀ #1 (binary
value 63), and the second must be its complement ䷁ #2
(binary value 0). So position 0 = ䷀ #1, position 1 = ䷁ #2. No choice
there.

The decisions only start at position 2. Here's the picture (the
diagrams below use **binary values**, the 0-63 numbers the solver works
with internally — ䷀ #1 is binary 63, ䷁ #2 is binary 0):

```
Position:   0    1    2    3    4    5    6    7    ...   63
Hexagram:   63 → 0  → ?  → ?  → ?  → ?  → ?  → ?       → ?
           (䷀)  (䷁)
            └────┘ └────┘ └────┘ └────┘
            pair0  pair1  pair2  pair3   ... 32 pairs total
```

C4 fixes pair 0. The solver is choosing pair 1 (positions 2-3), pair 2
(positions 4-5), and so on, all the way to pair 31. The job is to fill
in 31 pairs, each a member-of and orientation-of choice.

---

## Part 4: A "branch" = a choice for the SECOND pair

For pair 1 (the second pair, at positions 2-3), the solver has choices
to make:

- **Which pair?** There are 31 pairs of hexagrams left (pair 0 is
  already used). Numbering them 1 through 31, that's 31 candidates.
- **Which orientation?** Each pair has two ways to lay down — `(a, b)`
  or `(b, a)`. Two choices.

So for pair 1, the solver has up to **31 × 2 = 62 candidate placements**.

But not all 62 work. Some of them immediately violate a rule (for
example, the boundary distance to the previous pair turns out to be
exactly 5, which C2 forbids). After this kind of early pruning,
**56 candidates remain** as valid first-level choices — others are dead
on arrival.

Each one of these 56 valid candidates is what we call a **first-level
branch**, or just a "branch" for short. A branch is a complete commitment
about what pair 1 looks like.

```
                        START
                          │
                          ▼
                   pair 0 = (䷀ #1, ䷁ #2)   ← forced by C4
                          │
            ┌─────┬───────┼─────┬─────────┐
            ▼     ▼       ▼     ▼         ▼
         B[1,0] B[1,1] B[2,0] B[2,1] ... B[31,1]      ← 56 valid branches
                                                        (62 attempted, 6 pruned)
```

Notation: `B[i, o]` means "pair index i with orientation o (= 0 or 1)."
Each box is one first-level branch.

---

## Part 5: Sub-branches: choosing pair 2

Once a first-level branch is fixed (say B[5, 0] — "pair 5 in orientation
0"), the solver moves to pair 2 (positions 4-5). Same kind of decision:
which of the 30 remaining pairs, in which orientation. That's 60 raw
candidates. Pruning leaves something like ~54 valid choices on average.

Each of these is a **sub-branch** of the first-level branch above it.

```
First-level branch B[5, 0]
                  │
        ┌─────────┼──────────┐
        ▼         ▼          ▼
    SB[5,0,1,0] SB[5,0,1,1] SB[5,0,2,0] ... SB[5,0,31,1]
                                              ~54 valid sub-branches
```

`SB[5,0,1,0]` means "first-level pair 5 orient 0, then sub-branch
pair 1 orient 0." A sub-branch is a depth-2 partition unit.

---

## Part 6: Sub-sub-branches: choosing pair 3

Same idea, one level deeper. Once you've fixed pairs 1 AND 2, you choose
pair 3 (positions 6-7), and that's a **sub-sub-branch** (or "depth-3
sub-branch").

```
Sub-branch SB[5,0,1,0]
            │
        ┌───┼───┐
        ▼   ▼   ▼
    SSB[5,0,1,0,2,0] ...
                          ~50 valid sub-sub-branches each
```

Across all 56 first-level branches, all valid sub-branches, and all
valid sub-sub-branches, the total count of depth-3 partition units is:

> **158,364 depth-3 sub-sub-branches.**

(The exact number falls out of the constraint pruning. Each first-level
branch has on average 158,364 / 56 ≈ 2,828 depth-3 descendants.)

This number — 158,364 — matters a lot in practice. It's the size of the
work pool when the solver runs in "depth-3 partition mode."

---

## Part 7: Going all the way down

A complete ordering of all 64 hexagrams is one full path from the root
to a leaf of this tree:

```
ROOT (pair 0)
 │
 └─→ first-level branch (pair 1)
       │
       └─→ sub-branch (pair 2)
             │
             └─→ sub-sub-branch (pair 3)
                   │
                   └─→ depth-4 (pair 4)
                         │
                         └─→ ... pair 5, pair 6, pair 7, ...
                                   │
                                   └─→ pair 31 (last, positions 62-63)
                                         = a complete ordering
```

If a path can be drawn from the root to a leaf without breaking any of
C1-C5 along the way, it's a **valid ordering**. That's what the solver
collects.

---

## Part 8: A "node" is one decision step

When the solver is walking the tree, every **frame entry** is a "node" —
including the frame the walk starts from, which costs a node before any
child is tried. A node represents one specific commitment: "given everything
I've already decided up to position P, I'm now trying value V at the next
position."

A node is the unit of WORK. The solver counts nodes to measure how much
of the search tree it has explored. In one run on a 128-core VM at full
speed, the solver visits about **1.6 billion nodes per second**.

Some nodes lead somewhere (a child placement survives, keep going down).
Most do not: no remaining pair fits, so the node is a dead end and the
walk backs up to try the next sibling. Most paths die somewhere in the
middle of the 32 pair slots. That's normal.

### Exactly what counts as a node (the replicator's definition)

The prose above is enough to read the rest of this page, but it is *not*
enough to re-derive a canonical sha. A different team writing its own
C1–C5 enumerator has to increment its counter on exactly the same events,
because the per-sub-branch node budget is the enumeration's only free
parameter, and a difference of **52 nodes in 70.7 million** (7×10⁻⁷) has
been *measured* to produce a valid but non-canonical sha: at the 11.2T
depth-3 canonical, a per-cell budget derived as `floor(node_limit/158364)`
= 70,723,144 instead of the published 70,723,196 produced a `solutions.bin`
whose sha begins `2184bdd8`, against the anchor `0c0fe37c…`. That
measurement is recorded in `solve.c`'s `CANONICAL_RECIPES` comment (locate
by the `--validate-canonical` note that names both shas) — and only as that
8-character prefix: the full 64-nibble digest of the non-canonical output
was never published, so `2184bdd8` cannot be expanded from anything in this
repository and is cited here as provenance, not as a checkable value. The
anchor it is measured against, `0c0fe37c…`, is fully published in
[CANONICAL_HASHES.md](CANONICAL_HASHES.md). The six-row
formula-vs-recipe comparison, with a one-line
command that reproduces every cell of it, is
[CANONICAL_HASHES.md](CANONICAL_HASHES.md) §"PSB-formula caveat". The same
trap at 10T is why [DEVELOPMENT.md](DEVELOPMENT.md) §"Reproduce from
scratch" requires `SOLVE_PER_SUB_BRANCH_LIMIT=63146557` rather than the
auto-divide's 63,145,664.

⚠ **[CORRECTED 2026-09-02 — this paragraph read that a 13-node gap in 63
million (2×10⁻⁷) already sufficed, and gave the 10T auto-divide as
63,146,544. That floor is wrong: `10000000000000 / 158364 = 63145664`
(`python3 -c 'print(10**13 // 158364)'`), so the 10T gap is 893 nodes and
1.4×10⁻⁵, not 13 and 2×10⁻⁷. The same wrong floor was published in the
[CANONICAL_HASHES.md](CANONICAL_HASHES.md) §"PSB-formula caveat" table and
corrected there on 2026-09-01; this site and
[DEVELOPMENT.md](DEVELOPMENT.md) did not receive that fix. The example is
now the 11.2T one because that gap is the only one of this class the
project has actually measured through to a sha — the 10T claim was an
inference from a wrong subtraction, and no run was ever cited for it. No
sha, record count or file size depends on either figure. See
[CORRECTIONS.md](CORRECTIONS.md).]**

The counter (`ts->nodes`, and the budget-bearing `ts->branch_nodes`) is
incremented in exactly one place per engine — on **frame entry**
(`solve.c` `backtrack_iterative`, the `ENTER` phase; and the recursive
`backtrack`, at function entry). Both engines count identically. What
that means concretely:

- **A candidate rejected by a rule is NOT a node.** While scanning for
  the next placement, the solver skips a (pair, orientation) candidate
  outright — no frame, no count — when the pair is already used, when the
  boundary transition would have Hamming distance 5 (C2), or when either
  the boundary-distance or the within-pair-distance budget is exhausted
  (C5). Only a candidate that survives all of those gets a frame pushed,
  and it is the *frame* that costs a node.
- **A node is therefore a legal placement, not a failed attempt.** A node
  "fails" only in the sense that its own subtree yields nothing.
- **The frame the walk starts from is counted** — the root of the walk
  (in partitioned mode, the first free position after the fixed prefix)
  costs one node before any child is tried.
- **Each orientation is its own node.** The two orientations of the same
  pair are distinct candidates; each one that survives the checks above
  gets its own frame and its own node.
- **A completed ordering is counted.** A leaf at pair slot 32 enters a
  frame like any other, so every solution costs one node too.

Ground truth is `solve.c` (the `ts->nodes++` / `ts->branch_nodes++` pair
at the top of each engine's frame-entry path); this section is a
statement of it, not a second definition. *(Added 2026-08-01, lens sweep:
no document previously stated the node-accounting semantics, so an
independent re-implementation had no way to hit the canonical record
count even given the published budget.)*

A "node budget" or "node limit" is a stopping rule. When a sub-branch
has consumed N nodes of work without finishing, we stop walking it and
move to the next. Budgets are how we guarantee runs finish in
predictable time.

---

## Part 9: Two ways to enumerate — all-branch vs single-branch

There are two main ways to drive the solver:

**All-branch enumeration** (`solve 0 64`): the solver starts at the root
and walks the WHOLE tree, depth-first, expanding all 56 first-level
branches in turn. One process does it all. Output: a directory full of
shard files — one per depth-3 cell **that found at least one solution**;
a zero-yield cell leaves a `.dfs_state` checkpoint and no `.bin`, because
`flush_sub_solutions_d3` in [solve.c](../solve.c) returns before opening
the file when `solution_count == 0`. (At 560T that is **65,281**
non-empty shards against **158,364** `.dfs_state` checkpoints — see
[CAMPAIGN_METHODOLOGY.md](CAMPAIGN_METHODOLOGY.md) §7. The `.dfs_state`
count, not the `.bin` count, is the progress denominator.) The shards are
automatically merged into a single `solutions.bin`.

```
   SOLVE_DEPTH=3 SOLVE_PER_SUB_BRANCH_LIMIT=<budget> solve 0 64 (one process)
        │
        ├─ walks all 56 first-level branches
        │  └─ which means all 158,364 depth-3 sub-sub-branches
        └─ writes one solutions.bin
```

**Single-branch enumeration** ([`solve --branch 22 0`](SOLVE_C_CLI.md#--branch)): the solver jumps
straight into one specific first-level branch — say pair 22, orientation 0
— and only walks that subtree. To cover the whole problem with this mode,
you'd run it 56 times (once per valid first-level branch) and merge the
results.

```
   SOLVE_DEPTH=3 SOLVE_PER_SUB_BRANCH_LIMIT=<budget> \
       solve --branch 22 0 (one of 56 processes)
        │
        ├─ walks ONLY first-level branch B[22, 0]
        │  └─ which means ~2,828 depth-3 sub-sub-branches
        └─ writes shards for that branch only
```

Why both? Different tradeoffs:

| | all-branch | single-branch |
|---|---|---|
| Number of processes | 1 | up to 56 |
| Hardware | one strong machine | one or many machines |
| Memory per process | high (all 158K shard files) | low (only 2,828 shards) |
| Recovery from crash | resume the whole walk | re-run just that branch |
| Final merge step | automatic | explicit, across 56 outputs |

**Both environment settings above are load-bearing, and neither is the
default.** `SOLVE_DEPTH` defaults to **2**, not 3 — [solve.c](../solve.c)
keeps depth 2 "for byte-identical behavior with the canonical 10T
baseline" — so the bare commands `solve 0 64` and `solve --branch 22 0`
partition at depth 2 (3,030 cells globally, ~54 per first-level branch)
and write depth-2-named shards, not the depth-3 cells the diagrams show.
And `SOLVE_NODE_LIMIT` is read only if it is set, so a bare command runs
**unbounded**. Set the per-cell budget with `SOLVE_PER_SUB_BRANCH_LIMIT`
rather than `SOLVE_NODE_LIMIT`: `SOLVE_NODE_LIMIT` is auto-divided by the
number of cells *in that invocation's scope*, so the same value gives the
all-branch and single-branch runs different per-cell budgets and
different shas — which is exactly what the invariance below does *not*
survive. See [PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md)
§"Scope restriction: exhaustive vs budgeted".

For 5.6 trillion-node runs at depth-3 partitioning, both produce
EXACTLY the same `solutions.bin` byte-for-byte. That's not an accident —
it's a theorem.

---

## Part 10: Partition invariance

This is the key mathematical guarantee that makes the parallelism above
work. Stated plainly:

> **At a fixed partition depth, no matter how you split the work — by
> first-level branches, by sub-branches, all at once, or across many
> machines — if every cell gets the same per-sub-branch budget, the
> resulting `solutions.bin` is byte-for-byte identical.**

"At a fixed partition depth" is load-bearing, and so is the budget
qualifier. Changing the depth changes the number of cells — 3,030 at
depth 2 against 158,364 at depth 3 — so an equal *per-cell* budget buys
52.27x the aggregate work at depth 3 and a strictly larger truncated
record set. The theorem as stated in
[PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md) §"Scope restriction:
exhaustive vs budgeted" requires **exhaustive** enumeration of each cell;
under a node budget it holds only when the per-sub-branch budget is held
equal across the partitionings being compared, which is what
`SOLVE_PER_SUB_BRANCH_LIMIT` exists to do.

We've verified this:
- Across CPU architectures (AMD EPYC x86-64 vs ARM Cobalt 100,
  Neoverse-N2) — the 11.2T cross-architecture witness in
  [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §d3 11.2T
- Across regions (Azure westus2 vs westus3)
- Across enumerator modes (all-branch vs single-branch via `--branch`)

The verification is by SHA-256: hash the solutions.bin from each path,
they have to match exactly. See [PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md)
for the formal statement and [HISTORY.md](HISTORY.md) for the validation
runs.

This is what makes ROAE's claims reproducible. Anyone with the source
code can re-run any of these enumerations and verify the same hash.

---

## Part 11: What we've found so far

After enumerating C1-C5-satisfying orderings under various budgets, the
counts come out as:

| Budget | Sub-branch budget | Unique orderings (canonical form) | sha256 prefix |
|---|---|---|---|
| 10T (10^13 nodes) | ~63 M / d3 sub-branch | 706,427,594 | `b85c8871…` ² |
| 100T (10^14 nodes) | ~631 M / d3 sub-branch | 3,432,399,297 | `915abf30…` |
| **560T (5.6 × 10^14 nodes)** | **~3.5 B / d3 sub-branch** | **10,525,271,997** | `9a968fa2…` |
| (unbounded — exhaustion) | (exhausted to true completion) | ≈3×10³⁷ distinct-canonical (est.)¹ — withdrawn. ⚠ **[WITHDRAWN 2026-08-24 — the ≈3×10³⁷ distinct-canonical figure on this line exceeds its own 31! ≈ 8.2228×10³³ ceiling by ~4,013×; see documentation/CORRECTIONS.md]** | — |

The "canonical form" means we collapse equivalent orderings (orientation
flips of pairs) into one representative, so the count reflects distinct
mathematical solutions rather than re-orderings of the same pairs.

¹ The true exhausted total is not enumerated directly, but an unbiased
Monte-Carlo estimate (Knuth random-probe) puts the full C1–C5 space at
roughly **1.3×10³⁸ raw** (≈**3×10³⁷ distinct-canonical**). This is an
exploration estimate, not a proven count — see
[SEARCH_SPACE_SIZE.md](SEARCH_SPACE_SIZE.md) for method and validation. ⚠ **[WITHDRAWN 2026-08-24 — the ≈3×10³⁷ distinct-canonical figure in the sentence just above exceeds its own 31! ≈ 8.2228×10³³ ceiling by ~4,013×; see documentation/CORRECTIONS.md]**

² Current canonical, re-established 2026-05-13; the original 2026-04-18 10T
figure (706,422,987, `f7b8c4fb…`) is deprecated — pre-resume-fix undercount,
see [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §Deprecated.

What this tells us about King Wen:

- **King Wen is one of these.** Its specific ordering is a valid C1-C5
  solution, so it shows up in the enumeration.
- **King Wen is NOT mathematically forced.** With BILLIONS of other
  valid orderings, the constraints alone don't pick out King Wen.
- **King Wen MAY be statistically special — but the tested measures say
  it isn't.** Other measures (distributional position, observable
  statistics) are how we test that.
  See [DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md): an earlier
  joint-density result (rank < 10⁻⁵) was withdrawn 2026-07-26 as circular
  (its driver dimensions were KW-referencing); the de-circularized re-run
  on the KW-independent dimensions places KW at ≈ the 30th percentile of
  joint density across the 3.43-billion-record d3 100T enumeration —
  distributionally unremarkable.

---

## Part 12: What ONE branch's data tells us

For each individual first-level branch (and each sub-branch, and each
sub-sub-branch), we record:

- **Yield** — how many valid orderings emerge from this branch?
- **Nodes spent** — how much computation did the search take here?
- **Depth profile** — at what positions did most of the work happen?
  **Not recorded per canonical cell.** The per-depth node histogram
  (`nodes_at_depth[33]` in [solve.c](../solve.c)) is gated on
  `SOLVE_DEPTH_PROFILE=1`, which is off by default precisely so that
  existing runs stay byte-identical — so canonical enumeration runs leave
  it off by construction — and when it is on it is aggregated per
  *invocation*, not per cell. The parallel `--sub-branch` path separately
  writes `per_task_stats.csv`, whose schema is per depth-5 task. Profile
  data does exist where the flag was set: [HISTORY.md](HISTORY.md)
  records a 1T profile for cell `22_0_30_1_20_0` with 99.9% of the work
  at depths 28-32, peaking at depth 30.
- **Distance to King Wen** — for each ordering produced, how many
  positions differ from King Wen's choice?

This per-branch data lets us ask:

- Which branches produce the MOST orderings? (rich/fertile branches)
- Which produce the FEWEST? (dead/sparse branches)
- Are there branches that produce orderings particularly NEAR King Wen?
- Are there branches that produce orderings FAR from King Wen?
- Does work concentrate at certain positions (e.g., position 14 vs
  position 50)? — answerable only for runs launched with
  `SOLVE_DEPTH_PROFILE=1`, which the canonical runs were not.

---

## Part 13: What COMPARING branches tells us

Comparing two or more branches' data gives us results that one branch
alone can't.

**Pair-orientation symmetry.** Branch B[i, 0] and B[i, 1] (same pair,
opposite orientation) do **not** produce equal counts. Summing the 60,533
per-shard yields recorded in the committed 100T d3 enumeration log by
first-level branch gives 56 branches over 28 pairs, with **exact equality
in 0 of 28**. Gaps run from 0.0068% (pair 20) to 28.9% (pair 13:
472,267,753 against 352,935,249; percentages relative to the pair's
mean). Reproduce from the tree:

```sh
gzip -dc runs/20260419_100T_d3_d128westus3/enum_output.log.gz |
  grep -o 'Wrote [0-9]* solutions to sub_[0-9]*_[0-9]*_' |
  awk '{split($5,a,"_"); s[a[2]"_"a[3]] += $2} END {for (k in s) print k, s[k]}' |
  sort -t_ -k1,1n -k2,2n
```

At the finer scope of multi-variant groups,
[PROJECT_OVERVIEW.md](PROJECT_OVERVIEW.md) records 16.3% (1,636 of
10,027) exhibiting perfect orientation-symmetry and the remaining 83.7%
variant-dependent.

⚠ These are **budget-truncated** yields. Per the 2026-07-02 reversal
recorded in [SYMMETRY_SEARCH.md](SYMMETRY_SEARCH.md), comparisons of this
kind measure budget and dedup artifacts, not solution-set asymmetry. The
counts above therefore refute the observed-count claim outright, but they
decide nothing about the underlying solution set in either direction —
mistaking one for the other is the exact error that document corrected.
For what is actually proven about the constraint system's symmetry group,
see [SYMMETRY_SEARCH.md](SYMMETRY_SEARCH.md).

**First-level yield distribution.** Plotting yields across all 56
first-level branches makes a histogram. If it's flat, the constraints
treat all first-levels equally. If it's spiky, certain first-levels are
favored. Empirically it's spiky — some first-level branches contain ten
times more orderings than others.

**KW's first-level branch.** King Wen begins (after pair 0) with a
specific (pair, orientation) at position 2. We can ask: is THIS branch
unusually rich, unusually sparse, or typical? In the 100T d3 data, KW's
first-level branch is one of the high-yield ones — but not THE highest.

**Cross-branch boundary patterns.** What boundary distances appear
between pair 1 and pair 2 across all valid orderings? Across all
branches? KW uses certain values; what's the marginal distribution?

These comparisons are what
[DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md) develops in
detail.

---

## Part 14: What we're trying to find

This is an active research project. The current open questions:

1. **What is the TRUE total count?** All enumerated numbers (706M, 3.4B,
   10.5B) are LOWER BOUNDS — they're under per-sub-branch budget caps. The
   true total (with no budget cap, all sub-branches walked to completion)
   has not been enumerated directly, but an unbiased Monte-Carlo estimate
   (Knuth random-probe) puts the full C1–C5 space at roughly **1.3×10³⁸
   raw** (≈**3×10³⁷ distinct-canonical**) — an exploration estimate, not a
   proven count. See [SEARCH_SPACE_SIZE.md](SEARCH_SPACE_SIZE.md). ⚠ **[WITHDRAWN 2026-08-24 — the ≈3×10³⁷ distinct-canonical figure in the sentence just above exceeds its own 31! ≈ 8.2228×10³³ ceiling by ~4,013×; see documentation/CORRECTIONS.md]**

2. **Is KW statistically special, and HOW?** The former headline result
   here (the joint-density rank < 10⁻⁵) was withdrawn 2026-07-26 as
   circular; the de-circularized result is a null (KW ≈ 30th percentile —
   [DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md)). Independent,
   KW-independent measurements remain the open route.

3. **What is the structure of the yield distribution across branches?**
   We see spikes, but is there a deeper symmetry? An algebraic
   description of which branches yield more or fewer orderings?

4. **Are there orientation/mirror symmetries beyond the obvious ones?**
   The bit-position symmetry group is now proven and machine-checked —
   see [SYMMETRY_SEARCH.md](SYMMETRY_SEARCH.md). The open part is whether
   its orbit structure can be turned into a real compression of the
   search, and whether the solution set admits automorphisms beyond it.

5. **Where does cumulative work go?** If 90% of node visits land in 10%
   of sub-branches, the remaining 90% of sub-branches are "easy" and
   could be eliminated by a smarter algorithm. Knowing the work
   distribution lets us identify the hard subset to study deeper.

---

## Part 15: Future approaches

A few directions on the roadmap:

**Single-branch exhaustion.** Pick ONE specific deep sub-branch (say,
the one used in the 100T pilot: `22_0_30_1_20_0`, meaning first-level
pair 22 orient 0, then pair 30 orient 1, then pair 20 orient 0). Run it
with NO budget cap, all the way to true completion. That gives us a
single point of "100% confidence" data we can compare to the budgeted
runs at the same depth-3 sub-branch.

**Selective extension via layered enumeration.** With the
`--merge-layers` infrastructure (see [DEVELOPMENT.md §Layered
enumeration](DEVELOPMENT.md)), we can layer additional compute on top of
existing runs without redoing the whole thing. So a "100T full enum"
result can be EXTENDED on a chosen subset of branches to 1000T, without
recomputing the others.

**Cross-arch validation continues.** ARM (Cobalt 100), x86 AMD EPYC, and
ideally an Intel x86 part (e.g. Sapphire Rapids) should all produce the
same sha256 for the same enumeration parameters. We've done two of three
so far.

**SAT-encoder cross-validation.** [solve.py](../solve.py) has a SAT/PB
encoder, but it does **not** currently emit the enumerator's problem, so
matching counts against it is not yet available as a check. Per
[SOLVE_PY_CLI.md](SOLVE_PY_CLI.md): `--sat-encode` writes DIMACS CNF for
**C1+C2 only**; `--sat-c3 pb` writes the C3 bound as a pseudo-Boolean
constraint into a *separate* `.opb` file, so the `.cnf` itself never
carries C3; `--sat-c4` is opt-in; and `--sat-c5` is deferred/superseded —
measured 2026-08-31, it emits no extra clauses at all, clause-sha
identical to `--sat-c3 none`. A model count against this encoding is
therefore guaranteed to **exceed** the C enumerator's C1-C5 count, and
reading that gap as a `solve.c` defect would be a mistake. The
certification path is [sat.py](../sat.py). An encoder carrying all of
C1-C5, against which counts could legitimately be matched, remains future
work.

**Exhaustion at the symmetry boundary.** If yield-symmetry holds
strictly (e.g., all (pair_i, orient_0) and (pair_i, orient_1) produce
identical counts), then we only need to enumerate HALF the first-level
branches; the other half is determined by symmetry. This would
double-effectively the available compute. Note that the measured
budget-truncated yields above do **not** settle this either way — see
[SYMMETRY_SEARCH.md](SYMMETRY_SEARCH.md) for the symmetry group that is
actually proven, and for why truncated yields cannot decide it.

**Distributional null models.** We've started this in
[DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md). The idea: take
"random pair-constrained sequences" with the same C1 structure but
randomly chosen positions, and measure how often they match KW's
extremity. If KW is extreme even within its own constraint family,
that's strong evidence that the order is structured beyond what C1-C5
alone explain.

---

## Part 16: Goals (in priority order)

1. **A true exhausted count** of valid orderings, even just to within
   an order of magnitude. The enumerated 100T-d3 number (3.43 billion)
   is a lower bound; an unbiased Monte-Carlo estimate (Knuth
   random-probe) now puts the full C1–C5 space at ≈**1.3×10³⁸ raw**
   (≈**3×10³⁷ distinct-canonical**) — an exploration estimate, not a proven count (see [SEARCH_SPACE_SIZE.md](SEARCH_SPACE_SIZE.md)). ⚠ **[WITHDRAWN 2026-08-24 — the ≈3×10³⁷ distinct-canonical figure in the sentence just above exceeds its own 31! ≈ 8.2228×10³³ ceiling by ~4,013×; see documentation/CORRECTIONS.md]** A
   defensible directly-exhausted value is still a goal.

2. **A reproducible sha256** that's been validated on at least three
   independent computational paths. We have two CPU architectures so far
   (AMD EPYC x86-64 and ARM Cobalt 100). The third is in planning.

3. **A formal account of where King Wen sits** in the joint distribution
   of observable structural features across all valid orderings.
   [DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md) is the start.

4. **A formalization of the symmetry group** acting on the constraint
   system — **done (2026-07-02, machine-checked in Lean 2026-07-05).**
   The group is the 48 bit-position permutations that commute with
   bit-reversal (B₃, the octahedral group; the effective group on
   canonical records is S₄, order 24), and it is complete over all 64!
   hexagram relabelings that preserve each constraint predicate. See
   [SYMMETRY_SEARCH.md](SYMMETRY_SEARCH.md). What remains open: whether
   the solution set's automorphism group exceeds that group (the proof
   gives containment only), and whether the orbit structure can be turned
   into an actual enumeration saving.

5. **A published canonical solutions.bin** (with a small reference
   format) so that anyone can audit the count and re-run the
   enumeration. The current canonical (d3 560T) is **336,808,703,936
   bytes** — ~336.8 GB for 10,525,271,997 records — per
   [CANONICAL_HASHES.md](CANONICAL_HASHES.md), which is the registry of
   record for canonical sizes and counts. That size is a logistics
   problem; we may compress, deduplicate, or shard for distribution.

---

## Glossary

| Term | One-line definition |
|---|---|
| **Hexagram** | One of 64 patterns of 6 stacked solid/broken lines. Has two numberings: **binary value 0-63** (used by the solver) and **King Wen number #1-#64** (the traditional ordering position). Example: ䷀ #1 has binary value 63 (= 111111). |
| **King Wen sequence (KW)** | The specific 64-hexagram received ordering from ancient China — traditionally attributed to King Wen of Zhou (~1000 BCE); the dating of its fixation is debated. |
| **Pair** | Two consecutive hexagrams at positions 2k and 2k+1 in the sequence. The 64-hexagram order has 32 pairs. |
| **C1 through C5** | The five constraints the King Wen sequence satisfies. C1 = pair structure, C2 = no 5-line transitions, C3 = complement distance ≤ 776 (×64 form), C4 = starts with (63, 0), C5 = transition-distance count. |
| **Branch (first-level)** | A specific (pair, orientation) choice for pair 1 of the sequence. There are 56 valid first-level branches. |
| **Sub-branch (depth-2)** | A specific choice for pair 2 inside a first-level branch. About 54 per first-level. |
| **Sub-sub-branch (depth-3)** | A specific choice for pair 3 inside a sub-branch. About 50 per sub-branch. There are 158,364 depth-3 sub-sub-branches total in the King Wen problem. |
| **Node** | One step of the solver: one frame entry in the search tree, including the frame the walk starts from. See §"Exactly what counts as a node (the replicator's definition)" for the replicator-grade statement. |
| **Node budget** | A maximum number of nodes the solver can spend in one sub-branch before stopping. |
| **Yield** | The number of valid orderings produced by a given branch (or the whole problem). |
| **Partition invariance** | The theorem that, **at a fixed partition depth**, the invocation modes (whole-tree vs by-branch) give byte-identical merged outputs. Stated for **exhaustive** enumeration; under a node budget it holds only when every cell gets the same per-sub-branch budget (`SOLVE_PER_SUB_BRANCH_LIMIT`). Changing the partition depth changes the cell count and so the aggregate work, and does **not** preserve the output. See [PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md) §"Scope restriction: exhaustive vs budgeted". |
| **`solutions.bin`** | The binary file containing all valid orderings produced by an enumeration run. Each record is exactly 32 bytes, one byte per **pair** (not per hexagram): `byte[i] = (pair_index << 2) \| (orient << 1)`, with `pair_index` in bits 7-2 and the orientation bit in bit 1. The 64 hexagrams are recovered by expanding each byte through the fixed pair table. See [SOLUTIONS_FORMAT.md](SOLUTIONS_FORMAT.md) §Record format. |
| **sha256** | A 256-bit cryptographic hash. We use it as a fingerprint of `solutions.bin`. Two runs that produce the same orderings in the same order have identical sha256. |
| **All-branch** | Solver mode that walks the whole tree from the root. One process. |
| **Single-branch (`--branch`)** | Solver mode that walks one first-level branch only. Run 56 of these to cover the whole problem. |

---

## A note on the scale of the work

The "5.6 trillion node" budget for the regression test isn't picked
arbitrarily. It's:

```
5.6 trillion nodes  =  35.4 million nodes per depth-3 sub-sub-branch  ×  158,364 sub-sub-branches
```

That gives every depth-3 sub-sub-branch identical compute: 35.4M nodes
to look around, prune, find solutions, and stop. The same recipe scales
to 56T (354M per sub-branch) or 560T (3.5B per sub-branch). The deeper
the per-sub-branch budget, the more solutions surface — until the
sub-branch is fully exhausted and no further budget produces any new
ordering.

Most depth-3 sub-sub-branches are NOT exhausted at 5.6T or even 100T.
The published ROAE counts are honest LOWER bounds, with sha256
reproducibility, but they don't represent the true total. Closing that
gap is one of the primary research goals of the project.

---

For implementation details and the actual C source code, see
[solve.c](../solve.c) and the per-mode comments at the top of that file.

---

*Revision 2026-07-04 (primary-evidence sweep): the d3 100T record count cited in this document was corrected 3,432,399,298 → 3,432,399,297 — a 2026-05-30 doc-pass "correction" divided the file size by 32 without subtracting the 32-byte header; the sha256 anchor `915abf30…` is unaffected. See [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §d3 100T.*

*Revision 2026-09-01 (prose-correction batch P21 — this document's first pass through the correction lane): eleven adjudicated findings applied. Partition invariance qualified to a fixed partition depth and to the exhaustive-vs-budgeted restriction (Part 10 and the glossary); the two Part 9 example commands given their `SOLVE_DEPTH=3` and `SOLVE_PER_SUB_BRANCH_LIMIT` prefixes, with the depth-2/unbounded defaults stated; the "one shard per depth-3 sub-sub-branch" invariant corrected to non-empty cells only; the node definition reconciled between Part 8 and the glossary (frame entry, root frame included); the `solutions.bin` record bytes corrected from hexagrams to `(pair_index << 2) \| (orient << 1)`; the "for most pairs … equal counts" claim replaced by a measurement re-derived from the committed 100T log (0 of 28 pairs equal) with its reproduction command; the `solve.py --sat-encode` cross-validation claim scoped to what the encoder actually emits; depth profiles scoped to `SOLVE_DEPTH_PROFILE=1`; the canonical `solutions.bin` size corrected 102 GB → 336.8 GB (d3 560T); and "Intel Zen 5" corrected to AMD EPYC x86-64 (Zen is AMD's microarchitecture family). Five further sites were swept as siblings rather than left inconsistent: two more CPU-generation references; the two places that still posed the constraint system's symmetry group as an open problem after [SYMMETRY_SEARCH.md](SYMMETRY_SEARCH.md) proved it; and the "exhaustion at the symmetry boundary" sketch, which the truncated yields cannot decide either way.*
