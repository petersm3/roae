# Branches, Sub-Branches, and Nodes: a step-by-step explanation

A plain-language walkthrough of what the ROAE solver actually does, what
a "branch" is, what a "node" means, and how the picture builds up.

For the formal version, see [SPECIFICATION.md](SPECIFICATION.md). For
the findings in plain language, see [SOLVE-SUMMARY.md](SOLVE-SUMMARY.md).
This document is the bridge: how the math actually gets done.

---

## Part 1: The puzzle

There are exactly **64 hexagrams** — patterns of 6 stacked lines, each
line either solid or broken. ([SOLVE-SUMMARY.md §What a hexagram is](SOLVE-SUMMARY.md)
shows the picture.)

About 3,000 years ago, somebody in ancient China arranged all 64 in a
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
  Zhuan* commentary tradition (~5th-3rd c. BCE) and is presented
  rigorously in modern form by Wilhelm & Baynes (1967) and Cook (2006).
  Not novel to ROAE.
- **C2 — Boundary distance.** Between two consecutive pairs, the last
  line-pattern of one pair and the first of the next cannot differ by
  exactly 5 lines. *Identified by Terence McKenna* in *The Invisible
  Landscape* (1975), and independently by Cook (2006) in his combinatorial
  analysis. Not novel to ROAE.
- **C3 — Distance count.** Across the 64 positions, the number of
  consecutive-pair-boundary distances of each value (1, 2, 3, 4, 6) has
  to match a fixed distribution: 1×two, 2×twenty, 3×thirteen, 4×nineteen,
  6×nine. *Formulated by ROAE* as a specifically-quantified constraint;
  no prior published source identified.
- **C4 — Pair distance budget.** Same idea for distances inside each
  pair (between the two members). *Formulated by ROAE.*
- **C5 — Position 0 forced.** The first hexagram is ䷀ The Creative #1
  (binary 111111, the all-solid pattern), and the second is its
  complement ䷁ The Receptive #2 (binary 000000, all-broken).
  *Direct observation* of the actual King Wen sequence — not a derived
  rule, just what the data shows.

What ROAE adds is the **conjunction**: treating C1+C2+C3+C4+C5 as a
single constraint system and asking how many distinct orderings satisfy
all five at once. Individual rules in prior work; the joint enumeration
is the novel contribution. See [CITATIONS.md](CITATIONS.md) for the
detailed prior-work record.

The job of the solver is: **find every ordering of the 64 hexagrams
that satisfies C1-C5.** How many are there? Is King Wen one of
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

Constraint C5 says the first hexagram must be ䷀ The Creative #1 (binary
value 63), and the second must be its complement ䷁ The Receptive #2
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

C5 fixes pair 0. The solver is choosing pair 1 (positions 2-3), pair 2
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
                   pair 0 = (䷀ #1, ䷁ #2)   ← forced by C5
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

When the solver is walking the tree, every step from a parent to a child
is a "node." A node represents one specific commitment: "given everything
I've already decided up to position P, I'm now trying value V at the next
position."

A node is the unit of WORK. The solver counts nodes to measure how much
of the search tree it has explored. In one run on a 128-core VM at full
speed, the solver visits about **1.6 billion nodes per second**.

Some node visits succeed (the rules still hold, keep going down). Others
fail (a rule is broken, back up and try the next sibling). Most paths
fail somewhere in the middle of the 64 positions, so most nodes are
"failed attempts that got pruned." That's normal.

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
shard files (one per depth-3 sub-sub-branch), automatically merged into
a single `solutions.bin`.

```
   solve 0 64 (one process)
        │
        ├─ walks all 56 first-level branches
        │  └─ which means all 158,364 depth-3 sub-sub-branches
        └─ writes one solutions.bin
```

**Single-branch enumeration** (`solve --branch 22 0`): the solver jumps
straight into one specific first-level branch — say pair 22, orientation 0
— and only walks that subtree. To cover the whole problem with this mode,
you'd run it 56 times (once per valid first-level branch) and merge the
results.

```
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

For 5.6 trillion-node runs at depth-3 partitioning, both produce
EXACTLY the same `solutions.bin` byte-for-byte. That's not an accident —
it's a theorem.

---

## Part 10: Partition invariance

This is the key mathematical guarantee that makes the parallelism above
work. Stated plainly:

> **No matter how you partition the work — by depth-2 sub-branches, by
> depth-3 sub-sub-branches, by first-level branches, all at once, or
> across many machines — if all per-sub-branch budgets are the same, the
> resulting `solutions.bin` is byte-for-byte identical.**

We've verified this:
- Across CPU architectures (Intel Zen 5 vs ARM Cobalt 100)
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
| 10T (10^13 nodes) | ~63 M / d3 sub-branch | 706,422,987 | `f7b8c4fb…` |
| 100T (10^14 nodes) | ~631 M / d3 sub-branch | 3,432,399,297 | `915abf30…` |
| (unbounded — exhaustion) | (exhausted to true completion) | not yet known | — |

The "canonical form" means we collapse equivalent orderings (orientation
flips of pairs) into one representative, so the count reflects distinct
mathematical solutions rather than re-orderings of the same pairs.

What this tells us about King Wen:

- **King Wen is one of these.** Its specific ordering is a valid C1-C5
  solution, so it shows up in the enumeration.
- **King Wen is NOT mathematically forced.** With BILLIONS of other
  valid orderings, the constraints alone don't pick out King Wen.
- **King Wen MAY be statistically special.** Other measures
  (distributional position, observable extremity) are how we test that.
  See [DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md): KW sits
  at the 0.000th percentile of the joint observable density across the
  3.43-billion-record d3 100T enumeration. That's "rare in a precise
  measurable sense" — different from "uniquely forced," but still
  remarkable.

---

## Part 12: What ONE branch's data tells us

For each individual first-level branch (and each sub-branch, and each
sub-sub-branch), we record:

- **Yield** — how many valid orderings emerge from this branch?
- **Nodes spent** — how much computation did the search take here?
- **Depth profile** — at what positions did most of the work happen?
- **Distance to King Wen** — for each ordering produced, how many
  positions differ from King Wen's choice?

This per-branch data lets us ask:

- Which branches produce the MOST orderings? (rich/fertile branches)
- Which produce the FEWEST? (dead/sparse branches)
- Are there branches that produce orderings particularly NEAR King Wen?
- Are there branches that produce orderings FAR from King Wen?
- Does work concentrate at certain positions (e.g., position 14 vs
  position 50)?

---

## Part 13: What COMPARING branches tells us

Comparing two or more branches' data gives us results that one branch
alone can't.

**Pair-orientation symmetry.** For most pairs, branch B[i, 0] and
B[i, 1] (same pair, opposite orientation) produce equal counts of
orderings — sometimes the very same orderings up to a structural mirror.
This isn't a coincidence; it falls out of the constraint structure. We
can quantify how often it holds, and where it fails.

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

1. **What is the TRUE total count?** All published numbers (706M, 3.4B)
   are LOWER BOUNDS — they're under per-sub-branch budget caps. The true
   total (with no budget cap, all sub-branches walked to completion) is
   not yet known. Probably in the 10-50 billion range, but that's a
   guess.

2. **Is KW statistically special, and HOW?** We have one strong result
   (the 0.000th percentile finding from
   [DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md)). We want
   more independent measurements.

3. **What is the structure of the yield distribution across branches?**
   We see spikes, but is there a deeper symmetry? An algebraic
   description of which branches yield more or fewer orderings?

4. **Are there orientation/mirror symmetries beyond the obvious ones?**
   Empirically, certain symmetries seem to hold. Can we prove them
   formally and use them to compress the search?

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

**Cross-arch validation continues.** ARM (Cobalt 100), x86 Zen 5, and
ideally x86 Sapphire Rapids should all produce the same sha256 for the
same enumeration parameters. We've done two of three so far.

**SAT-encoder cross-validation.** [solve.py](solve.py) has a SAT/PB
encoder (`solve.py --sat-encode`) that emits the same problem in DIMACS
or OPB format. Running an external SAT or model-counting solver on the
encoded problem and matching solution counts would give a completely
independent verification of the C-based enumerator.

**Exhaustion at the symmetry boundary.** If yield-symmetry holds
strictly (e.g., all (pair_i, orient_0) and (pair_i, orient_1) produce
identical counts), then we only need to enumerate HALF the first-level
branches; the other half is determined by symmetry. This would
double-effectively the available compute.

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
   an order of magnitude. Currently the 100T-d3 number (3.43 billion)
   is a lower bound; we want a defensible upper or true value.

2. **A reproducible sha256** that's been validated on at least three
   independent computational paths. We have two so far (Zen 5 and Cobalt
   100). The third is in planning.

3. **A formal account of where King Wen sits** in the joint distribution
   of observable structural features across all valid orderings.
   [DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md) is the start.

4. **A formalization of the symmetry group** acting on the constraint
   system. Empirically we observe orientation symmetries, but a clean
   mathematical statement and a proof that they're exact would let us
   simplify the enumeration considerably.

5. **A published canonical solutions.bin** (with a small reference
   format) so that anyone can audit the count and re-run the
   enumeration. The 102 GB current size is a logistics problem; we may
   compress, deduplicate, or shard for distribution.

---

## Glossary

| Term | One-line definition |
|---|---|
| **Hexagram** | One of 64 patterns of 6 stacked solid/broken lines. Has two numberings: **binary value 0-63** (used by the solver) and **King Wen number #1-#64** (the traditional ordering position). Example: ䷀ The Creative #1 has binary value 63 (= 111111). |
| **King Wen sequence (KW)** | The specific 64-hexagram ordering attributed to ancient China, ~3000 years old. |
| **Pair** | Two consecutive hexagrams at positions 2k and 2k+1 in the sequence. The 64-hexagram order has 32 pairs. |
| **C1 through C5** | The five constraints the King Wen sequence satisfies. C1 = pair structure, C2 = no boundary distance 5, C3 = consecutive-pair distance count, C4 = within-pair distance count, C5 = position 0 forced. |
| **Branch (first-level)** | A specific (pair, orientation) choice for pair 1 of the sequence. There are 56 valid first-level branches. |
| **Sub-branch (depth-2)** | A specific choice for pair 2 inside a first-level branch. About 54 per first-level. |
| **Sub-sub-branch (depth-3)** | A specific choice for pair 3 inside a sub-branch. About 50 per sub-branch. There are 158,364 depth-3 sub-sub-branches total in the King Wen problem. |
| **Node** | One step of the solver: one parent-to-child decision in the search tree. |
| **Node budget** | A maximum number of nodes the solver can spend in one sub-branch before stopping. |
| **Yield** | The number of valid orderings produced by a given branch (or the whole problem). |
| **Partition invariance** | The theorem that all partitioning strategies (whole-tree vs by-branch vs by-sub-sub-branch) give byte-identical merged outputs. |
| **`solutions.bin`** | The binary file containing all valid orderings produced by an enumeration run. Each ordering is 32 bytes (one hexagram per byte for 32 of the 64 positions; the rest is fixed by C1-C5). |
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
[solve.c](solve.c) and the per-mode comments at the top of that file.
