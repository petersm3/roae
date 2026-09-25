# W0-D lower-bound node-mapping certificate (full-31)

**What this is.** A certificate, in the Q-768 W0-D schema, that the t-units of the TR-12
Exhaustion Atlas (XA) are a **lower bound** on the production enumerator's node count, branch by
branch, in the full-31 space:

    production_nodes(b)  >=  1 x t(b)      for every one of the 56 first-level branches b

Here `production_nodes(b)` is the total of `solve.c`'s `SOLVE_NODE_LIMIT` counter over all of `b`'s
sub-branches in an **exhaustive** normal-mode run, at `SOLVE_DEPTH=2` or `3`. `t(b)` is the atlas's
`prefixes_t_units(b)`. The certificate is `w0d_lower_bound_cert.json` (kind `lower-bound`,
`nodes_per_t_unit` `"1/1"`, `scope.n` 31). Produced 2026-09-25 by lane Opus SS (Claude Opus 5.5).

**What it is not.** It is not the runbook's W0-D (an **exact** mapping measured by exhausting a
reduced-n production DFS at n ≤ 13). That run still cannot happen, because the production
enumerator has no reduced-n mode (`init_pairs()` fixes all 32 King Wen pairs). The certificate is
also not an exhaustion, and it does not measure production nodes directly. It gives a bound in one
direction, established from the code plus an exact finite enumeration.

## The argument

Two prefix sets, both starting after the pinned opening pair (63, 0):

- **K**: what the t-ladder counts. A prefix is in K when every boundary transition avoids
  distance 5 (C2) and its boundary-class counts never exceed B0 = (2, 8, 13, 7, 1) over d =
  (1, 2, 3, 4, 6). B0 is King Wen's boundary multiset. The reference DFS is `kc_brute_rec` in
  `solve.c`.
- **P**: what the production DFS visits (`backtrack` / `backtrack_iterative`, the sub-branch
  generator and `thread_func_single` in `solve.c`). Inside the tree it prunes on only three
  things: pair already used, C2, and **one combined budget over all 63 transitions** (`kw_dist`).
  Each placement debits both its boundary distance and its within-pair distance from that budget.
  C3 is applied only at the full-walk leaf (`cd <= kw_comp_dist_x64` at step 32). It is a filter
  there and never prunes, so it changes no node count.

**Lemma (K ⊆ P).** Let W be the 32 within-pair distances and `wplaced` the ones already placed.
For a prefix in K, production's boundary check sees a remaining combined budget of
(B0 + W − bnd − wplaced) in class bd, which is at least 1 + W − wplaced ≥ 1. After the boundary
debit, the within check sees (B0 + W − bnd′ − wplaced) in class wd, which is at least
W − wplaced ≥ 1, because the new pair's own within-pair distance has not been placed yet. So
every step passes.

**Counting.** The counter starts at depth d0: 2 for `SOLVE_DEPTH=2` and 3 for `SOLVE_DEPTH=3`. The
wrapper places the sub-branch prefix without counting it. So

    production_nodes(b) = |P_b at depth >= d0|  >=  t(b) − T(b) + X(b)

Here T(b) is the set of K-prefixes of `b` above d0 (the uncounted trunk), and X(b) is the set of
P-but-not-K prefixes at depth ≥ 3. Both modes count X(b), and t does not include it. The
producer computes T(b) exactly. It then counts X(b) exactly by depth-limited enumeration, with
iterative deepening, and stops as soon as X(b) ≥ T(b). The recorded X is a count of distinct
prefixes, so stopping early still gives a valid lower bound on the true X. Nothing is sampled.
If X(b) ≥ T(b) on every branch, the additive term goes away and the bound reads
`production_nodes(b) >= t(b)`.

**Why lower, not upper.** P strictly contains K. Measured: P = K through depth 3 (158,364
prefixes each), and every branch has P-not-K prefixes by depth 5. Those prefixes overdraw a
boundary class while the combined budget still has room, so they are dead. The production DFS
visits them and t does not count them. So t cannot bound production nodes from above. The Q-768
ruling and TR-12 §3 (before its 2026-09-25 correction) assumed the opposite direction, on the
premise that production prunes with C3. An `upper-bound` certificate built on that premise would
have made EXHAUSTIBLE rows unsound.

## Measured (worker `c302-worker`, D8als_v7 Spot, 2026-09-25)

Tree: 5c296837 plus integration batches 1–6, the Q-772 loader and this change (uncommitted, so
`provenance.engine_git` reads `5c29683742b0+uncommitted`). Build:
`gcc -O3 -pthread -fopenmp -o solve solve.c -lm -lz`.

`python3 solve.py --xa-w0d-lb-cert w0d_lower_bound_cert.json atlas_n31.json` (15 s), with
verdict tokens in `producer_tokens.txt`:

    W0D_LB_B0=d1:2,d2:8,d3:13,d4:7,d6:1
    W0D_LB_BRANCHES=56
    W0D_LB_K_PREFIXES_DEPTH_1_2_3=56,3030,158364
    W0D_LB_P_PREFIXES_DEPTH_1_2_3=56,3030,158364
    W0D_LB_K_SUBSET_P_VIOLATIONS=0
    W0D_LB_BRANCHES_X_GE_T_SOLVE_DEPTH_2=56/56
    W0D_LB_BRANCHES_X_GE_T_SOLVE_DEPTH_3=56/56
    W0D_LB_X_SEARCH_DEPTH_MAX=5
    W0D_LB_ATLAS_FMASS_1_2_3_EQ_K=PASS
    W0D_LB_ATLAS_BRANCH_SET_EQ=PASS
    XA_W0D_LB_CERT=PASS

`atlas_n31.json` is the n=31 atlas that TR-12 pins by sha256
(`9d6ba3d2b1a860b1992c3306191d228c49787c44f1d0366d23e6798b63210558`). It is not distributed, so
the certificate is also reproducible **without** it. Only the last two tokens need the atlas.
They are positive controls that the K mirror is the t-ladder's K: the atlas's `fmass[1..3]` equals
the enumerated K totals, and its 56 branches are the same (entry, exit) set.

**Production-binary positive controls** (`production_crosscheck.txt`). These check the P mirror
against the real binary, not against a model of it:

- `./solve --list-branches` lists 56 branches. Each branch's (entry, exit, depth-2 sub-branch
  count) equals the mirror's, with 0 mismatches, and the counts sum to 3,030.
- `SOLVE_DEPTH=3 SOLVE_PER_SUB_BRANCH_LIMIT=1 ./solve 60 2` prints
  `Sub-branches: 158364 remaining of 158364 total`, which matches the mirror's P depth-3 total.

## Reproduce

    gcc -O3 -pthread -fopenmp -o solve solve.c -lm -lz
    python3 solve.py --xa-w0d-lb-cert /tmp/w0d.json            # XA_W0D_LB_CERT=PASS, exit 0
    ./solve --list-branches                                     # the depth-2 control
    python3 solve.py --atlas-queries ATLAS_N31.json --atlas-select xa \
        --xa-node-mapping-cert /tmp/w0d.json --atlas-out /tmp/xa

The enumeration is deterministic: there are no seeds. `tests.py TestW0dLowerBoundCert` runs the
producer end to end. It also kills the mutant "production uses the t-ladder's cap" (P = K, so
X = 0 and no certificate is written), and it checks that the consumer refuses a `scope.n` = 31
certificate on an n=9 atlas.

## What it does to the XA verdict

With this certificate and no throughput anchors, `TR12_XA_CD` moves from
`PENDING:W0-D-node-mapping` to `PENDING:xa-throughput-anchors`. The nodes/sec anchor still has no
public basis (TR-12 §3), and the repro battery's `c_xa_cd` row still skips for that reason. When an
operator supplies anchors, the token is `TR12_XA_CD=ONE-SIDED:lower-bound`. Rows can then read
INFEASIBLE or `UNDECIDED:lower-bound`, and never EXHAUSTIBLE.

## What it does not prove

- **Nothing about reduced-n atlases.** Production has no reduced-n mode. The certificate declares
  `scope.n` 31, and the XA consumer refuses it on any other n.
- **Nothing about `--sub-branch` parallel mode.** That counter starts at depth 5, and its trunk
  was not enumerated.
- **Nothing about node- or time-limited runs.** The bound applies to the exhaustive count.
- **Nothing about how loose the bound is.** P \ K is large but was not counted beyond T(b), so
  the true production cost may be far above t.
- **Code-to-proof bridge.** The lemma is a statement about the predicates as they read in
  `solve.c` at `provenance.engine_source_sha`. The binary controls above tie the mirror to the
  shipped code for the first three layers. Below that, the argument is a reading of the source,
  as with every other structural claim in this repository.

Whether a **one-sided** call can be published in TR-12 is an operator decision. This directory
does not make that decision.

`provenance.engine_source_sha` and `producer_source_sha` name the `solve.c` and `solve.py` shipped with this certificate (regenerated on the committed tree at assembly; the batch 7–10 pre-publication review checked that every non-provenance field reproduces).
