# Large-scale canonical campaigns: methodology and reproducibility

> **Scope.** First published 2026-05-31 ahead of the 560T canonical campaign
> (#49); §7 has since been populated with that campaign's actuals. This
> document is the **entry point** for campaign methodology — new readers
> start here. [LARGE_SCALE_CAMPAIGNS.md](LARGE_SCALE_CAMPAIGNS.md) is the
> **operations reference** and is retained: the two are complementary, not
> a replacement pair, and neither is awaiting deletion. §10 sets out which
> document owns what, and names the material that exists only in the older
> file. For anything operational — sizing, per-thread rates, orchestrator
> pseudocode, branch distribution, merge mechanics, gotchas, and the
> scale-honesty disclosure — read that file.
>
> ⚠ **[CORRECTED 2026-09-01 — this boxed note contradicted itself and the
> document's own §10.** Within one paragraph it said §7 "**is populated**
> with the completed 560T campaign actuals" and then that the worked example
> "**will be filled in** once the campaign produces its actual sha, record
> count, wall time, cost, and eviction count" — both, about the same section.
> It also said this document "will eventually **replace**"
> `LARGE_SCALE_CAMPAIGNS.md` and that the older file was awaiting retirement,
> which §10 (rewritten 2026-08-08) had already settled the other way: the
> replacement premise "**was false**", the documents are "**complementary**",
> and the older one "**is not awaiting deletion**". Finally it pointed the
> reader at "the PORT-TODO checklist at the end of this document" —
> `git grep PORT-TODO` over the whole tree returned exactly one hit, that
> reference itself. There was no such checklist; §11 is "Open items" and
> carries prose. The pointer is deleted rather than repaired.]**

---

## TL;DR / who this document is for

This document explains the **methodology** used to produce the ROAE King Wen
canonical enumerations — and, just as importantly, the **methodology used to
extend** an existing canonical to a deeper search budget without rerunning the
work that produced the previous canonical.

It is aimed at three audiences:

1. **A third party who wants to reproduce one of our canonicals from scratch**
   on independent hardware, and confirm byte-identical output.
2. **A third party who wants to extend our deepest canonical to a deeper
   budget.** Read this as an aim the document is written toward, not a
   capability it currently discharges: **the incremental extension recipe in
   §4 is not runnable from published artifacts alone.** It consumes the
   parent campaign's `shards.tar.gz`, `dfs_state.tar.gz` and `budget.tar.gz`,
   and those live only in operator-held storage
   ([CANONICAL_HASHES.md](CANONICAL_HASHES.md) §Access boundary names the
   locations and states plainly that they are not public URLs). So audience 2
   needs **either** operator-supplied checkpoints **or** a full re-run of the
   parent campaign at the deeper budget — the latter is fully specified here
   and needs nothing private, but it is exactly the work the extension
   methodology exists to avoid. *(Added 2026-09-01: this item previously read
   "without our cooperation, given only the artifacts we publish", which the
   access boundary does not support. Verification needs nothing private;
   incremental extension does.)*
3. **Future maintainers of this project** who need to understand why the
   campaign pipeline looks the way it does — what's structural, what's
   operational, what's correctness-load-bearing, and what's a hygiene choice.

The conceptual core is **prefix-determinism per cell** — the property that
makes "enumerate to budget B, archive, later resume to budget B′ > B" produce
byte-identical results to "enumerate to budget B′ in one shot."  Everything
else is operationally derivable from that.

For the formal definition of the constraints C1-C5 and the canonical record
format, see [SOLVE.md](SOLVE.md) and
[SPECIFICATION.md](SPECIFICATION.md). For the partition-invariance theorem
(the work-partition choice is correctness-neutral), see
[PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md). For the reproducibility-
parameter registry (canonical shas, record counts, exact env vars), see
[CANONICAL_HASHES.md](CANONICAL_HASHES.md). For specific past campaigns'
operational details, see [HISTORY.md](HISTORY.md). (Note:
`LARGE_SCALE_CAMPAIGNS.md` is **retained** as the operations reference and is
not being retired — see §10 and the boxed note at the top. *Corrected
2026-09-01; this read "is being retired and merged into this document as of
the 560 T campaign port", contradicting §10's 2026-08-08 finding that the
replacement premise was false.*)

---

## 1. What "canonical" means here

A **canonical artifact** is a file `solutions.bin` produced by the C
enumerator at a specific search budget that:

1. **Contains every King Wen ordering satisfying constraints C1–C5** that the
   DFS reaches within the per-cell node budget;
2. **Is sorted** by canonical record key (so byte-equality across runs is
   meaningful);
3. **Is deduplicated** (each record appears once);
4. **Is reproducible byte-identically** on independent hardware in the same
   region/microcode class, given the same **source commit, partition depth,
   global node limit and per-sub-branch limit** — the full sha-determining
   tuple, set out with its evidence under "Why budget matters" below;
5. **Has a published sha256** in [CANONICAL_HASHES.md](CANONICAL_HASHES.md)
   that any third party can verify by recomputing it on their own host.

The sha256 is the reproducibility anchor — not the bytes themselves. If you
produce a mismatching sha for the same parameters, the project treats that as
a bug to investigate, not as a new finding. See "Sha stability vs host
environment" at the end of this document for the empirically-documented
limits of that.

⚠ **[CORRECTED 2026-09-02 (prose batch P70) — item 4 named only the source
commit and the search budget, dropping partition depth from a stated
reproducibility contract.** It is the same defect the 2026-09-01 pass fixed
at "Why budget matters" below, where the tuple is now four elements and
carries its own correction marker; that pass did not sweep this second site,
and the charge that raised it (Codex V2-F22 #5) named both. The consequence
is the one §8 step 4 warns about: `SOLVE_DEPTH` is sha-determining, omitting
it does not error because the code default is `2`, and a reader who plans a
reproduction from this list alone would enumerate the d2 partition and never
match a d3 sha. `CANONICAL_HASHES.md` §"Reproducibility parameters" publishes
distinct d3 and d2 canonicals at the same 10 T node limit, which is only
possible if depth is in the tuple. The retired wording is registered in
[RETRACTED_PHRASES.tsv](RETRACTED_PHRASES.tsv) and keyed in
[CORRECTIONS.md](CORRECTIONS.md) as `RP-60bf9367`.]**

### Why budget matters

The lowest credible "exhaust everything" budget is
**≥4.9 × 10¹⁸ nodes (≈4,900,000 T)** — beyond practical compute by a wide
margin. The derivation is two published factors: the one depth-3 cell whose
tree size has been measured needs **≥31 × 10¹² nodes**, and a uniform per-cell
budget must be at least as large as the *largest* cell, so
**158,364 × 31 × 10¹² = 4.909 × 10¹⁸**. Against that, the deepest canonical to
date (560 T) is `4.909 × 10¹⁸ / 560 × 10¹² =` **~8,767× short** of exhaustion.
See [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §"100B and sub-canonical
reference shas" item 1 for the probe that produced the ≥31 × 10¹² input, the
command that re-addresses that cell, and the one comparability assumption the
bound rests on.

⚠ **[CORRECTED 2026-09-01 — this read "≥4,900 T nodes", understating the
exhaustion threshold by a factor of ~1,002.** The error is a misplaced unit in
a two-factor product whose factors are both published: `158,364 × 31 × 10¹²`
is `4.909 × 10¹⁸`, which is ~4,900,000 T, not 4,900 T. At the figure as
published, the 560 T canonical read as **8.75×** short of exhausting the
space; correctly it is **~8,767×** short, and the difference is the difference
between "a few more campaigns away" and "unreachable at any planned scale."
`CANONICAL_HASHES.md` carried the same figure and is corrected in the same
pass. The corrected value is the one the underlying single-cell probe recorded
all along.]**

Every realistic canonical is therefore **budget-limited**: each of the 158,364 depth-3 cells
is given the same per-cell node budget, and the DFS for that cell stops when
the budget is reached. The set of records emitted for a cell depends on which
parts of its search tree fit in that budget.

This makes the canonical sha **a function of (source code, partition depth,
global node limit, per-sub-branch limit)** — the same tuple enumerated by
[CANONICAL_HASHES.md](CANONICAL_HASHES.md) §"Reproducibility parameters",
which publishes one row per canonical with `SOLVE_DEPTH`, `SOLVE_NODE_LIMIT`
and `SOLVE_PER_SUB_BRANCH_LIMIT` set out separately. All four must match:
two campaigns agreeing on every element should produce the same
sha; campaigns differing in the budget elements should not (the larger campaign will
include a superset of records up to the smaller campaign's per-cell boundary,
plus more records that the smaller didn't have budget to find).

⚠ **[CORRECTED 2026-09-01 — this read "a function of (source code, search
budget)", which is not the sha-determining tuple and is contradicted by this
document's own §8.** §8 states that `SOLVE_DEPTH` is "**sha-determining and
must be copied from the canonical's row**", that omitting it does **not**
error because the code default is `2` (confirmed in `solve.c`: the default is
2 and nothing warns unless a non-default is set), and that a run which omits
it "silently enumerates the d2 partition and can never reproduce a d3 sha".
`CANONICAL_HASHES.md` publishes distinct d3 and d2 canonicals at the same 10 T
budget — only possible if partition depth is in the tuple. "Search budget" is
also two parameters, not one: `SOLVE_NODE_LIMIT` and
`SOLVE_PER_SUB_BRANCH_LIMIT` are set independently, and
`CANONICAL_HASHES.md` §Reproducibility parameters warns that raising the
former alone leaves the frontier — and therefore the sha — unchanged.]**

---

## 2. Per-cell uniform budget

The canonical convention is **uniform per-cell budget** — every cell gets
exactly the same number of nodes. The campaign's "scale" is then a single
scalar — the total budget across all cells — even though the work is
partitioned 158,364 ways:

- 1 T canonical = 6.3 M nodes per cell × 158,364 cells
- 11.2 T canonical = 70.7 M nodes per cell × 158,364 cells
- 100 T canonical = 631 M nodes per cell × 158,364 cells
- 560 T canonical = 3.5 B nodes per cell × 158,364 cells
- 1120 T canonical = 7.1 B nodes per cell × 158,364 cells

The choice of "uniform per-cell" over "heterogeneous, asymmetric" budgets is
deliberate:

- **Comparable across milestones.** A doubling of scale is a doubling of
  per-cell budget — clean for cross-milestone analysis.
- **Audit-simple.** A single scalar describes the campaign; reviewers don't
  need a per-cell budget table to understand what was enumerated.
- **Composable with extension** (next section). Doubling a uniform budget is
  the natural "extend to higher scale" operation.

Heterogeneous budgets are sometimes used for *exploration* (e.g., spending
more compute on a cell suspected of containing a particular pattern), but
those runs are not canonical and are not entered into `CANONICAL_HASHES.md`.

---

## 3. Extension (the core idea)

> **FINALIZED METHODOLOGY (2026-06-20) — read first.** This section is the public, host-agnostic
> statement of how a canonical is extended. The authoritative, finalized points:
> - **Single-hop only.** Extend directly from the parent canonical to the target budget (e.g. *B* → 2*B*).
>   Do **not** chain successive budget-increase resumes (*B*→…→*B′*); chained resume is unsupported.
>   If intermediate scale milestones are wanted, capture each as a *separate* single hop from the same
>   parent — never a chain.
> - **What the resume actually reads (per cell):** the partial-solution shard, the DFS checkpoint, and
>   the budget sidecar (the budget the shard was made at — required, so a budget *increase* is accepted
>   and the cell is correctly re-walked deeper). The merged solutions file is the enumeration *output*,
>   **not** an input — it is not needed to resume.
> - **Working-disk sizing:** per-cell shards stay **compressed on disk**, so the working disk is far
>   smaller than a raw-bytes projection would suggest. Size the disk with a robust margin over the
>   measured compressed footprint, and never below the largest measured peak of a prior run. (Do not
>   size to an estimate alone.)
> - **Integrity:** measured per-cell counts + per-shard checkpoint verification at restore; a post-merge
>   sha for the new canonical; and the invariant that the new canonical contains **every** parent record
>   as a per-cell prefix (verified by an ordered-subset diff).
>
> **Decision (2026-08-08): the SKU, region and microcode identifiers below are RETAINED
> deliberately.** This paragraph previously carried a live "Pre-publish TODO (operator review) —
> genericize those to host-agnostic terms before publishing" inside an already-published document.
> That instruction was reviewed and **rejected as wrong**, not left undone.
>
> Two findings. (1) *Nothing here is sensitive.* An audit found 11 such references, all public
> product and region names (`D128als_v7`, `westus2`/`westus3`, AMD EPYC 9V74 / Bergamo Zen 4c),
> and there are no public IP addresses, subscription or tenant IDs, keys, endpoints, or credentials
> anywhere in the public corpus. The only IP-shaped strings in the tree are the Azure IMDS
> link-local address and RFC1918 example ranges — five occurrences, all non-secret: `solve.c` and
> `scripts/capture_build_manifest.sh` each query `169.254.169.254` (IMDS), and
> `scripts/perf_bench.sh` (twice) plus `documentation/DEPLOYMENT.md` name `10.0.0.0/16` and
> `10.0.0.0/24` in `az network vnet create` examples. *(Corrected 2026-09-01: this asserted a
> repo-wide scan found **zero** IP-shaped strings. Re-running that scan over `*.md`, `*.sh`, `*.c`
> and `*.py` returns the five above. The surrounding no-credentials claim is unaffected — link-local
> and RFC1918 literals disclose nothing — but the scan result as stated was false, and an assertion
> about a scan should be produced by that scan.)* (2) *They are load-bearing.* §6
> and §7 argue that a canonical sha reproduces byte-identically **on a specific host class** —
> that is the whole content of the sha-stability-vs-host-fragility result. "A large cloud VM"
> would make those claims uncheckable. Genericizing would damage the reproducibility argument it
> was meant to protect.
>
> The operational, cloud-specific runbook (credentials, resource names, launch scripts) is
> maintained privately and remains out of the public record. That boundary is unchanged.

A canonical produced at budget *B* per cell **enables a canonical at any
budget *B′* > B without redoing the original work**. This is the most
important property of the campaign methodology.

### Why this works: prefix-determinism per cell

Each of the 158,364 cells runs a depth-first search that visits its nodes in
a deterministic order — the order is a function of the source code, not of
host environment, not of wall-clock time, not of thread scheduling (the
iterative-DFS + per-cell-budget design guarantees this within the limits
documented in section 7). A "budget of *B* nodes" means "visit the first *B*
nodes of that walk, in canonical DFS order, and emit any that satisfy
C1-C5."

Therefore, for any single cell, the records emitted at budget *B* are an
**initial subset** of the records that would be emitted at any budget
*B′* > B — same records, same order, same byte-for-byte content, plus
additional records found in the (*B*, *B′*] range.

This makes the union-over-cells canonical at budget *B′* literally
extensible from the canonical at budget *B*: each cell's per-cell shard at
budget *B* is a prefix of its shard at budget *B′*. The DFS at budget *B′*
can be **resumed** from the per-cell state saved at the budget-*B*
boundary, walk forward to the *B′* boundary, and emit only the additional
records found.

### Concrete extension recipe (560T → 1120T or any higher scale)

Given the cold-archive directory `solver-data:/canonical-archive/<source-
campaign>/` produced by the source campaign (which contains
`shards.tar.gz`, `dfs_state.tar.gz`, `budget.tar.gz`, `solutions.bin.gz`,
provenance sidecars, and an `EXTENSION_RECIPE.txt`):

1. **Provision a new VM** (D128als_v7 Spot in westus3, same SKU class used
   for the source campaign) with a **new Premium SSD** sized for the larger
   shard set — roughly **2× the source archive's `shards.tar.gz` uncompressed
   size** plus a working margin. Mount both disks by UUID.
2. **Gunzip the three preservation tarballs** from the cold archive onto
   the new Premium's run directory, preserving the per-cell file layout:
   ```bash
   cd /mnt/premium/run_<new_scale>
   tar -xzf /mnt/solver-data/canonical-archive/<source-campaign>/shards.tar.gz
   tar -xzf /mnt/solver-data/canonical-archive/<source-campaign>/dfs_state.tar.gz
   tar -xzf /mnt/solver-data/canonical-archive/<source-campaign>/budget.tar.gz
   ```
   These three sets are what makes extension possible:
   - `sub_<cell>.bin` — the records found within the source budget
   - `<cell>.dfs_state` — the DFS state at the source-budget boundary
   - `<cell>.budget` — the source per-cell budget value (Outlier #5 protection)
3. **Build the C enumerator from the source campaign's git ref** (recorded in
   the archive's `build.sha` / provenance sidecars) — or a sha-equivalent
   descendant verifiable via `./solve --validate-canonical <source-sha> <source-scale>`.
   ⚠ **[SCOPED 2026-08-28 — `--validate-canonical` accepts `<scale>` only in `{1T, 11.2T, 100T}`;
   its own usage line says so, and it refuses anything else. This recipe is titled for extending
   **560T** to higher scales, so following it literally at the source scale it is written for
   **fails**. Verified by running the shipped binary. Until the scale list is extended, verify a
   560T-lineage build by the deeper canonical's recorded sha in
   [CANONICAL_HASHES.md](CANONICAL_HASHES.md) rather than through this flag. Tracked as Q-324.]**
4. **Launch the extension enum** with:
   - `SOLVE_NODE_LIMIT=<new_scale_total_nodes>`
   - `SOLVE_PER_SUB_BRANCH_LIMIT=<new_per_cell_budget>` (strictly greater
     than the source's `.budget` sidecar value)
   - `SOLVE_THREADS=128 SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 SOLVE_SKIP_AUTOMERGE=1`
   - `SOLVE_SKIP_IOPS_CHECK=1` (see the note below on the IOPS pre-check
     behavior — this flag bypasses a known issue at eviction-resume and on
     extension launch.)

   The enumerator picks up each cell from its `.dfs_state` checkpoint and
   walks forward to the new per-cell budget, appending only the additional
   records to each `sub_<cell>.bin`.

> **Note on `SOLVE_SKIP_IOPS_CHECK=1` and the I/O pre-check behavior.**
>
> The C enumerator includes an I/O performance pre-check at startup (tasks
> #107 and #115 in the project history) that aims to refuse-fast on a disk
> that's too slow for canonical work — historically, an accidentally-attached
> HDD-class disk where fsync latency would dominate enum wall. The check
> samples concurrent fsync throughput and projects what fraction of the
> estimated enum wall would be spent fsync-waiting; if that fraction exceeds
> 25%, it refuses to start with exit 31.
>
> Empirically, the probe is **noisy on a cold-cache VM** — that is, a VM that
> has just been brought up via `az vm start` (eviction-resume) or is being
> used for the first time (extension launch). The 100-iteration concurrent
> probe runs before any disk warmup, and on a freshly-attached Premium SSD
> can measure 200–300 fsync/sec where the warm disk would steady-state at
> 2000+ fsync/sec. That triggers a false refuse-to-start.
>
> This was first encountered during the 2026-05-31 dress rehearsal:
> the eviction-recovery code path provisioned a new VM, attached the
> existing Premium with the in-flight shards, and re-launched the enum to
> resume from `.dfs_state` checkpoints. The IOPS gate fired with
> "223 fsync/sec, projected 41% fsync-wall-fraction" and refused. The same
> Premium had passed the gate at first launch the same evening — only the
> probe changed (cold caches, no recent activity).
>
> The mitigation in the campaign supervisor is to set
> `SOLVE_SKIP_IOPS_CHECK=1` in every (re)launch's env. Rationale: the
> first-launch gate at campaign initialization is authoritative; the disk
> doesn't change between resumes; the probe is the unreliable component.
> This is **a bypass, not a fix.** The underlying probe design issue
> (cold-cache sensitivity on `az vm start`-type VM lifecycle events) is a
> known item for post-campaign hardening — likely either a longer warmup
> before the probe runs, or a check that detects "fresh-boot VM" and skips
> the gate automatically rather than requiring an env var.
>
> For an extension on a freshly-provisioned VM, the same condition applies:
> the disk is not pathological, but the probe is too quick to know that.
> Pass `SOLVE_SKIP_IOPS_CHECK=1` and proceed. If you are operating on a
> known-good Premium SSD that you provisioned yourself, you have already
> done the work the gate exists to do.
5. **Merge** with `solve --merge` (same pattern as the source campaign) to
   produce the new `solutions.bin` at the higher scale.
6. **Verify** with `./solve --verify` (C verifier) AND `python verify.py`
   (independent Python re-verifier) on the new `solutions.bin`. Both must
   PASS — but **passing both is necessary, not sufficient, to declare the new
   canonical valid.** Both are forward passes over the artifact, and
   [VERIFY.md](VERIFY.md) says so of the artifact validator in its own words:
   *"**Does NOT check completeness** — that no valid solution is missing is
   the enumeration's claim, attested by the canonical sha; a forward pass
   cannot establish it."* An untouched byte-for-byte copy of the **parent**
   canonical passes both, because the parent passed both. So structural PASS
   cannot distinguish a correct extension from a no-op.
7. **Establish that the extension did work at all.** This step did not exist
   before 2026-09-01, and its absence is what let all three published
   gates — `solve --verify`, `verify.py`, and the lineage check below — go
   green on a no-op. At minimum, assert both of:
   - `records(new) > records(src)` — a strict increase in record count. An
     extension that walked further and found nothing new is possible in
     principle but is a *finding* to be reported, not a silent pass.
   - a **per-cell coverage count** against the 158,364 `.dfs_state`
     inventory: every cell must carry a checkpoint whose recorded node
     boundary is the new per-cell budget, not the parent's. A cell still
     sitting at the parent boundary was not extended.

   Note that raising `SOLVE_NODE_LIMIT` alone does **not** move the frontier —
   see [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §Reproducibility parameters
   "EXTENSION WARNING", which is the mechanism by which an extension run can
   produce a byte-identical parent artifact while its metadata records a
   larger budget. That is precisely the no-op these two assertions catch.
8. **Record** the new canonical's sha256 in
   [CANONICAL_HASHES.md](CANONICAL_HASHES.md). The new canonical has no prior
   anchor (it's a new scale measurement), so the sha is recorded, not gated.

⚠ **[CORRECTED 2026-09-01 — the acceptance criteria published here certified a
no-op.** Old step 6 read "Both must PASS to declare the new canonical valid"
and old step 7 recorded the sha ungated. Neither verifier checks completeness,
by VERIFY.md's own statement of scope, so neither can tell a correct extended
artifact from an untouched copy of its parent. The lineage check below
compounded it: it computes `src - new`, which is **empty for an identical
copy**, and duly prints `SUBSET OK`. Three published gates, all green, on a
run that did nothing. The strict-increase and per-cell-coverage assertions
above are the missing leg; they are stated as required criteria, and are
**not yet implemented as tooling.**]**

The new canonical contains every record from the source canonical
**byte-identically as a prefix per cell**, plus the additional records
found in the budget-extension range.

### Verification that extension was byte-faithful

To prove that the extended canonical is correctly an extension of the source
(rather than a redo from scratch that happened to land at a similar sha), the
source `solutions.bin` records must appear as an ordered subset of the new
`solutions.bin` records:

> **CORRECTED 2026-08-01 — the recipe previously published here was NOT EXECUTABLE.**
> It ran `sort -u` / `comm` / `diff` directly on `solutions.bin`. That file has **no line
> structure**: it is a 32-byte header followed by fixed 32-byte records whose bytes are
> `(pair_index<<2)|(orient<<1)`, and **`0x0A` — newline — is a legal record byte** (pair 2,
> orient 1), as is `0x00`. The text tools therefore split records at arbitrary interior
> offsets and treat the header as data, so the check could produce a spurious verdict in
> either direction. It was also stated as an *unordered subset* test while the invariant
> claimed above it is a *per-cell prefix* property — weaker than advertised even had it run.
> Since this was the only published proof that an extended canonical extends its parent,
> and the catalog's lineage citation inherits it, the record-aware method is given instead.

> ⚠ **[CORRECTED AGAIN 2026-09-01 — the 2026-08-01 replacement repeated the defect its own
> correction note had just diagnosed, and added two more.** (i) It asserted `blob[:4] == b'ROAE'`
> on a **raw** read, but since #169 `solutions.bin` is written **gzip-framed by default**
> ([SOLUTIONS_FORMAT.md](SOLUTIONS_FORMAT.md) §"On-disk framing"), and the extension recipe above
> ships `solutions.bin.gz` — so it raised `bad magic` on the exact artifact it was written for.
> (ii) It did `f.read()` into a Python `set`, materializing the 336,808,703,936-byte parent on the
> 256 GB box §7 prescribes; a `set` of 10.5 billion `bytes` objects is several times worse again.
> (iii) The note directly above says the old check "was also stated as an *unordered subset* test
> while the invariant claimed above it is a *per-cell prefix* property — weaker than advertised
> even had it run" — and the replacement was `{body[i:i+R] for i in …}`, an unordered set with no
> cell identity. It reproduced the exact weakness it had identified one paragraph earlier.]**

```bash
# Lineage check: every SOURCE record present in NEW, and NEW strictly larger.
# Streaming merge-walk over two sorted, deduplicated record streams: O(1) memory,
# one sequential pass each. Record-aware (never text lines), and sniffs the gzip
# framing that `solve` has written by default since #169.
python3 - "$SRC/solutions.bin" "$NEW/solutions.bin" <<'PYEOF'
import gzip, sys
H, R = 32, 32                                # header bytes, record bytes (SOLUTIONS_FORMAT.md)
MASK = bytes(b & 0xFC for b in range(256))   # orient bits cleared -> primary sort key

def opener(path):
    with open(path, 'rb') as probe:
        magic = probe.read(2)
    return gzip.open(path, 'rb') if magic == b'\x1f\x8b' else open(path, 'rb')

def records(path):
    """Yield 32-byte records from the LOGICAL (decompressed) stream."""
    with opener(path) as f:
        head = f.read(H)
        if head[:4] != b'ROAE':
            sys.exit(f"{path}: bad magic {head[:4]!r} - not a solutions.bin")
        while True:
            rec = f.read(R)
            if not rec:
                return
            if len(rec) != R:
                sys.exit(f"{path}: trailing {len(rec)} bytes - not a multiple of {R}")
            yield rec

def key(rec):        # compare_solutions order: pair identity first, then full bytes
    return (rec.translate(MASK), rec)

src, new = records(sys.argv[1]), records(sys.argv[2])
s, n = next(src, None), next(new, None)
n_src = n_new = missing = 0
while s is not None:
    if n is None or key(n) > key(s):          # new stream walked past a source record
        missing += 1; n_src += 1; s = next(src, None); continue
    if key(n) < key(s):                       # a record new to this budget
        n_new += 1; n = next(new, None); continue
    n_src += 1; n_new += 1                    # equal: source record present
    s, n = next(src, None), next(new, None)
while n is not None:
    n_new += 1; n = next(new, None)
print(f"source records : {n_src:,}")
print(f"new records    : {n_new:,}")
print(f"source \\ new   : {missing:,}")
if missing:
    print("*** NOT A SUPERSET - the new canonical is missing source records ***"); sys.exit(1)
if n_new <= n_src:
    print(f"*** NO EXTENSION - new record count {n_new:,} does not exceed source {n_src:,} ***"); sys.exit(1)
print("SUPERSET OK, and strictly larger")
PYEOF
```

The merge-walk is valid because both files are sorted by `compare_solutions` and deduplicated
([SOLUTIONS_FORMAT.md](SOLUTIONS_FORMAT.md) §"Sort order"), so a two-pointer scan decides the
subset question exactly. The `n_new <= n_src` exit is the strict-increase assertion from step 7 of
the recipe: **it is what stops an untouched copy of the parent from passing.** Executed 2026-09-01
against four fixtures — a true extension (rc 0), an identical copy of the parent (rc 1,
`NO EXTENSION`), a file missing parent records (rc 1, `NOT A SUPERSET`), and mixed raw/gzip
framing across the pair (read correctly).

**What this establishes, and what it does not.** It is a **set-subset plus strict-growth** test.
It is *not* the per-cell prefix property, and that property is **not observable from any published
artifact**: the merged `solutions.bin` is in `compare_solutions` order, which is not DFS emission
order, and the per-cell shards are written by iterating the solution hash table slot by slot
(`flush_sub_solutions_d3` in `solve.c`), so they are in hash-slot order and are not in DFS order
either. Prefix-determinism per cell is the *mechanism* §4 relies on; the subset-plus-growth
property above is the strongest consequence of it that the artifacts can be made to witness. Say
that rather than claiming the stronger check.

*At canonical scale this Python form is a reference implementation, not an operational tool —
10.5 billion records per stream is far beyond what a Python loop will finish in reasonable wall
time. Use it on fixtures and sub-canonical artifacts to establish the method, and implement the
same two-pointer walk in the C path for a real 560 T-scale lineage attestation.*

This is a **partition-invariance witness** at a different scale — see
[PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md).

---

## 4. What must be preserved for extension

For extension to work, the source campaign's cold archive must contain, in
addition to the merged `solutions.bin`:

| File | Purpose |
|---|---|
| `shards.tar.gz` | Per-cell `sub_<cell>.bin` shard files — the records each cell found within the source budget. Without these, extension cannot reuse the source's prefix work. |
| `dfs_state.tar.gz` | Per-cell DFS resume state at the source-budget boundary. Without these, the resume would have to re-walk each cell's search from scratch — defeating the point of extension. |
| `budget.tar.gz` | Per-cell `.budget` sidecars recording the source per-cell budget. Extension reads these to confirm the new budget is strictly larger. |
| `solutions.bin.gz` (or `.sha256`) | The merged canonical artifact. Used by the verification step that confirms extension was byte-faithful. |
| `solutions.provenance.json` + `canonical-host-fingerprint.json` + `build.sha` | Build provenance — what source ref + compiler + host configuration produced the archived bytes. Needed to identify what to rebuild on the extension VM. |
| `EXTENSION_RECIPE.txt` | The operational version of section 3 of this doc, written by the archive supervisor. Pin to the archive bytes; not maintained over time. |

Crucially: the live "working" Premium SSD from the source campaign is
**redundant with the cold archive** for extension purposes. Either one works.
The cold archive is the durable, infrastructure-failure-resistant path; the
live Premium is a convenience (faster to re-attach + run than to gunzip from
cold archive).

### 4.1 Post-merge artifact preservation: NOT automatic (SPOF caveat)

A subtle, costly trap, surfaced during the 560 T campaign 2026-06-08:

**The merge supervisor copies LOGS, sidecars, and the sha256 sidecar to
solver-data — but does NOT copy `solutions.bin`, the per-cell `.bin` shards,
or the per-cell `.dfs_state` checkpoints.** After the supervisor's
`teardown_vm` step runs, those artifacts exist only on the detached
Premium SSD that hosted the merge. The Premium SSD is by standing pattern
the project's "transient external-merge scratch" — meaning, if anyone
operates on standing-pattern muscle memory and deletes it, the canonical
is gone.

The fix is two-pronged:

1. **Every canonical campaign at ≥ 11.2 T must include an explicit copy
   step** of `solutions.bin` + all shards + all `.dfs_state` checkpoints
   from Premium → solver-data **before** `teardown_vm` fires. The robust
   place for this is inside `phase_b_merge_supervise.sh` (or its
   replacement) — bake it in once and every future campaign inherits it.
2. **Pre-launch disk-space gate** for solver-data: it must be sized to
   hold uncompressed working copy + gzipped warm-tier mirror BEFORE
   launch, not after merge completes. The 560 T campaign's solver-data
   was 2 TB (≈ 800 GB free) at launch, insufficient for the 560 T uncompressed
   plus mirror (≈ 2.4 TB). It was resized 2 TB → 4 TB online 2026-06-08
   to fit, but the right policy is to size it before launch.

Capacity planning table (rough, derived from the 560 T artifact sizes,
power-law-projected for 1120 T):

| Scale | `solutions.bin` | Shards (.bin) | Checkpoints (.dfs_state) | Uncompressed total | Cold mirror (gzip-9 of binary subset) | Required solver-data free |
|---|---|---|---|---|---|---|
| 11.2 T | ~5 GB | ~10 GB | ~50 GB | ~65 GB | + ~30 GB | ~95 GB |
| 100 T | ~115 GB | ~150 GB | ~300 GB | ~565 GB | + ~250 GB | ~815 GB |
| 560 T | ~337 GB | ~870 GB | ~400 GB | ~1.6 TB | + ~800 GB | ~2.4 TB |
| 1120 T (projected) | ~620 GB | ~1.6 TB | ~750 GB | ~3.0 TB | + ~1.5 TB | ~4.5 TB |

This finding is non-obvious from the supervisor's published doc-comments
(which say "solutions.provenance.json copied to solver-data BEFORE teardown",
implying the data file is also copied — it isn't). Future maintainers should
audit any merge supervisor for explicit `cp solutions.bin → solver-data`
before the `teardown_vm` call.

---

## 5. Operations choices are orthogonal to correctness

Many seemingly significant operational choices are **correctness-neutral**
under the partition-invariance theorem
([PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md)):

| Choice | Correctness impact |
|---|---|
| Single-VM enum vs partitioned across N VMs | None — merge produces identical bytes either way |
| Spot vs Regular VM | None for enum (eviction is recoverable via DFS-state checkpoints); merge needs Regular because the external sort isn't checkpointable |
| Westus2 vs westus3 (same Microsoft-Datacenter microcode class) | None |
| One Premium SSD for everything vs separate scratch | None — operational choice for IOPS isolation |
| Thread count (128 vs 64 vs 16) | None for enum (per-cell budget pins the work) |
| Reboot mid-campaign | None — checkpoint resume is byte-clean |

These are **operations choices** to optimize cost, wall time, and blast
radius. They do not change the canonical bytes.

The choices that **do** matter for correctness:

- **Source git ref** of `solve.c` at build time (the only "source" the
  canonical depends on)
- **Per-cell node budget** (the scale-defining parameter)
- **Host environment factors at very small scales** — see next section

---

## 6. Sha stability vs host-environment fragility

Empirical finding from the project: **canonical sha stability is a function
of budget-vs-tree-size ratio**.

At very small budgets (e.g., 1 T = 6.3 M nodes per cell), the per-cell tree
is so big that the budget cuts off in the middle of a sub-tree, and the exact
set of records that "fit" before the cutoff is sensitive to subtle host
environment factors (gcc minor-version code generation, glibc allocator
behavior, kernel scheduler quanta, CPU microcode patch level). At 1 T scale,
moving from one Azure host to another in the same SKU class can produce a
*different* sha for the same source code.

At canonical scales used by the project (11.2 T and above), the per-cell
budget is large enough that the budget-cutoff happens at a deeper, more
deterministic point in the search tree, and the host-environment sensitivity
drops away. Empirically:

- **1 T canonical: host-fragile.** Two different Spot D128 hosts in the same
  westus3 SKU pool can produce different 1 T shas. Documented at length in
  [HISTORY.md](HISTORY.md).
- **11.2 T canonical: host-stable across our current host class.** Seven
  independent witnesses (Build A May 14, Build B May 14, cold-storage
  re-checksum May 15, v3 sha-equivalence May 24, c72eada+#108 witness May
  27, t62 dress May 28, and the Tier-1 post-hardening dress May 31) all
  produce the same sha on D128als_v7 Spot westus3. See the 11.2T row in
  [CANONICAL_HASHES.md](CANONICAL_HASHES.md).
- **100 T canonical: host-stable.** Re-validated May 30 on the current
  main lineage; reproduces the historical sha byte-identically.
- **560 T canonical: established 2026-06-08, sha `9a968fa21f74e36ad1d57b53453c867e1324ef9494856bd2a5d5f94ae3b5ee0e`.** 10,525,271,997 unique canonical solutions, 336,808,703,936 bytes on disk (32-byte header + records × 32; the merge log's 336,808,703,904 is record-bytes only). The first 560 T run defined the sha; a **from-scratch re-run on 2026-06-30** (different binary lineage — the eviction-resume-fixed solver — and a different 7-eviction pattern) **reproduced it byte-for-byte**, providing a second same-scale direct witness and CANONICAL-verifying the result (see HISTORY.md June 30 entry).

For extension specifically: **extension byte-faithfulness depends on the
extension host being in the same sha-stability class as the source host**.
Within "D128als_v7 Spot westus3 with current Azure microcode" (as of
2026-05-31), 11.2 T+ scales are sha-stable; extension works byte-identically.
Across host classes, sha-stability has been demonstrated **by direct
byte-identical reproduction**: the ARM Cobalt witness (2026-05-21, Neoverse-N2,
gcc 13.3.0 `-mcpu=native`, ARM binary `e5cfc6cd…`) reproduced the 11.2 T
canonical `0c0fe37c…` **byte-identically** — see
[CANONICAL_HASHES.md](CANONICAL_HASHES.md) §"Cross-build + cross-architecture
witnesses", whose row for that run records exactly that, and the v2 11.2 T
details, which repeat it.

⚠ **[CORRECTED 2026-09-01 — this read "sha-stability has been demonstrated
transitively via independent re-verification, not byte-identical direct
reproduction", citing the ARM Cobalt witness.** The row it cites says the
opposite, in one word: `0c0fe37c…` **byte-identical — cross-architecture
witness**. The document was misdescribing its own strongest evidence in the
direction that weakened it.]**

What this means for a third-party reproducer:

- Reproducing a canonical sha on **the same Azure SKU class in the same
  region** is the strongest expectation — should be byte-identical at 11.2 T
  and above.
- **A differing sha means a differing record set. Investigate it; do not
  accept it.** The header carries "only deterministic-from-input fields. No
  timestamps, git hashes, hostnames" and the sha "is a pure function of the
  enumeration inputs" ([SOLUTIONS_FORMAT.md](SOLUTIONS_FORMAT.md)
  §Reproducibility), and `compare_solutions` is a total order so the post-sort
  byte layout is fixed by the record set alone (§"Sort order"). A fixed record
  set therefore forces a fixed sha, and the contrapositive is the useful form:
  if the sha differs, the records differ. That is a real, documented
  phenomenon — host-environment-level drift (gcc/glibc/kernel patch versions,
  ASLR seed, microcode revision) changes *which* records a budgeted walk
  reaches, and `CANONICAL_HASHES.md`'s 1 T drift row measures the difference
  as 12,000 records. It is a finding to characterize, not a tolerance to
  grant.
- Structural verification (`solve --verify` + `verify.py`) on the differing
  artifact tells you the records it *does* contain are valid. It cannot tell
  you which records are missing — neither instrument checks completeness
  ([VERIFY.md](VERIFY.md)) — so it is a useful next step in the
  investigation, **not a substitute verdict**.
- **Also compare the record count**, which is the cheapest completeness
  signal available and needs no re-enumeration. The canonical file layout is
  a 32-byte header followed by fixed 32-byte records, so the count is
  `(filesize − 32) ÷ 32` — for the 560 T canonical,
  `(336,808,703,936 − 32) ÷ 32 = 10,525,271,997`, the count published for
  that scale in [CANONICAL_HASHES.md](CANONICAL_HASHES.md). A **differing**
  count proves the record sets differ and tells you by how much. A
  **matching** count does not prove the sets are equal — two different sets
  can be the same size — but it separates "the walk reached a different
  frontier" from "the walk stopped short", and that is the first fork in the
  investigation §1 asks you to open.

⚠ **[CORRECTED 2026-09-01 — the second bullet previously read: reproducing on
a different provider or on-premises "may produce a different sha at the same
record-set; the appropriate check then is structural verification … not
byte-identical sha equality".** That instructs a reproducer to accept a sha
mismatch, and its premise — that the same record set can yield a different sha
— is contradicted by the format specification quoted above. What actually
varies across host classes is the record set, which is a substantive result
worth chasing, and the old wording routed the reader away from chasing it.]**

---

## 7. Worked example — the 560 T canonical campaign (2026-06)

Completed 2026-06-08; this section now records actuals. The campaign launched 2026-06-01 00:03 UTC; enum completed 2026-06-08 03:34 UTC after 7.15 days of wall time; merge completed 2026-06-08 22:24 UTC after 18 h 42 m; the canonical sha `9a968fa2…` was established as the new deepest published canonical.

| Field | Value |
|---|---|
| Campaign | #49 — 560 T full-depth-3 canonical |
| Source commit | git `2b01b15` (current main lineage) |
| Compute SKU (enum) | D128als_v7 Spot in westus3 (AMD EPYC 9V74 / Bergamo Zen 4c) |
| Compute SKU (merge) | D16als_v7 Standard in westus3 |
| Per-cell budget | 3,536,157,207 nodes (= 560 T / 158,364 cells) |
| Total budget | 560,000,000,000,000 nodes |
| Launch UTC | 2026-06-01 00:03 UTC (= 2026-05-31 17:03 PT) |
| **Final sha256** | **`9a968fa21f74e36ad1d57b53453c867e1324ef9494856bd2a5d5f94ae3b5ee0e`** |
| Records | **10,525,271,997** unique canonical solutions |
| Bytes | **336,808,703,936** on disk (32-byte header + records × 32; record-bytes = 336,808,703,904) |
| Pre-merge shard records (per-sub-branch canonical) | **43,876,464,466** (4.17× cross-sub-branch rediscovery ratio — NOT an orientation-dedup ratio) ⚠ **[LABEL CORRECTED 2026-08-28 — these are per-sub-branch CANONICAL keys, not raw oriented leaves: `solve.c:39-61` deduplicates on pair identity with the orient bit masked and CLEARS the table after each sub-branch, so the total counts cross-sub-branch rediscovery. It is a LOWER BOUND on raw leaves visited. See documentation/CORRECTIONS.md 2026-08-28.]** |
| Final shard count | **65,281** cells with non-empty shards (41.2 % yield) |
| Cells with zero solutions | 93,083 (58.8 %) — fully scanned, budget exhausted, no records emitted |
| `.dfs_state` checkpoint count | 158,364 (100 % of cells scanned) |
| Enum wall | **171.5 h** (= 7.15 days, including all eviction-recovery defer windows) |
| Merge wall | **18 h 42 m** (single external chunked-sort pass, 250+ sort chunks) |
| `solve --verify` | PASS — all 10,525,271,997 records satisfy C1-C5 + sorted + no duplicates, King Wen sequence found |
| `verify.py --jobs 16` | PASS (2026-06-09) — independent Python re-verify of all 10,525,271,997 records; see CANONICAL_HASHES.md witness table |
| Total realized cost | **not published.** The pre-launch projection was $150–185; the realized total varied with eviction-defer wall-time and no itemized ledger has been published for it. ⚠ **[CORRECTED 2026-09-01 — this read "recorded in HISTORY.md campaign ledger". It is not: the 560 T entry in HISTORY.md records launch, wall, records, sha, dedup ratio, verify status and eviction count, and no cost total; that file's cost totals stop at earlier, smaller campaigns. The cross-reference pointed at a ledger that does not exist, and a `$360` 560 T total elsewhere in this document was anchored to it — see §7 rule 9, where both are withdrawn.]** ⚠ **[AMENDED 2026-09-01, later the same day — "not published" is right about the public corpus but was read here as "not known", and that is wrong. A realized total **was measured** at campaign closeout and is recorded in the project's private closeout analysis (`petersm3/roae-private:560T_FINAL_ANALYSIS.md`, the "Cost (realized)" row, stated against the $400 hard cap). So this is a **publication** gap, not a measurement gap. The figure is deliberately not restated here: a cost total carries no reproduction command, and §7 rule 9 has set the bar for putting one in this document at an **itemized** ledger — VM hours by SKU, disk-months, closeout — which the private one-line total does not supply. Withdrawing it as an estimation anchor (rule 9) and knowing it was measured are both true at once.]** |
| Eviction count handled | **5** — all M-F, all in a 37-min window 07:12-07:49 PT (Mon 07:12, Tue 07:39, Wed 07:34, Thu 07:42, Fri 07:49). **0 weekend evictions** (Sat 2026-06-06 + Sun 2026-06-07) — strong empirical support for M-F-only scheduled reclamation in the westus3 D128als_v7 Spot pool. |
| Throttled-host re-provisions | 0 (no host returned throttled state) |
| Cold archive | `solver-data:/canonical-archive/20260608_560T_9a968fa2/` (gzip warm mirror) + `canonical-archive/20260608_560T_9a968fa2/` (cold blob); uncompressed working copy at `solver-data:/run_560T/` (solutions.bin + 65,281 shards + 158,364 `.dfs_state` checkpoints) |
| Post-merge SPOF discovered + remediated | Per §4.1: the merge supervisor does NOT auto-copy solutions.bin to solver-data; explicit copy was added mid-campaign before teardown. solver-data resized 2 TB → 4 TB online to fit uncompressed + gzip-mirror artifacts. |

### Operations design choices made for this campaign

- **Launch at 17:01 PT (1 minute past UTC June 1)** — earliest clean
  June-billing UTC time + 12 hours of off-hours Spot runway before any M-F
  daytime defer risk.
- **Single-VM enum on a D128 Spot, separate Standard D16 for merge.**
  Eviction-resilient (DFS checkpoints), uncheckpointable phase isolated to a
  small Standard.
- **75-min wait + M-F daytime defer policy.** Off-hours evictions retry
  quickly; M-F daytime evictions defer to 18:01 PT same-day to avoid
  disrupting operator availability windows.
- **Throttle probe on every new VM, including post-eviction `az vm start`
  AND every main-loop poll cycle.** Spot D128 pool occasionally hands back
  thermally-throttled hosts at ~600 MHz vs the expected 2596 MHz base /
  3700 MHz boost. The campaign supervisor runs `solve --cpu-freq <threshold>`
  in three places: (a) after the initial `az vm create` provision; (b) after
  every post-eviction `az vm start` (which may relocate the VM identity to a
  different physical host); (c) inline in the main poll loop every 3 minutes
  against the live VM. The first two probes treat a single THROTTLED reading
  as a vacated host (`az vm deallocate`, re-enter the wait-relaunch-window
  policy, retry — up to 5 attempts before ABORT). The mid-run probe is a
  sustained-throttling gate: `THROTTLE_THRESHOLD` consecutive THROTTLED
  readings (default 20 = ~60 min) before the supervisor self-deallocates the
  VM (main loop then sees a normal eviction and routes through the same
  wait-relaunch-window). Together these three probes catch (i) bad initial
  hosts, (ii) post-eviction relocations to bad hosts, and (iii) hosts that
  pass the provisioning probe but degrade hours later. Probe cost is
  negligible (a 50ms `/proc/cpuinfo` read per cycle); prevents the long-tail
  scenario where a thermally-throttled host runs the enum at ~5× normal wall.
- **Observed eviction pattern: D128 Spot reclaimed daily around 07:15–07:40 PT.**
  Live observation from the in-flight 2026-06 560T campaign. Across the
  first three days every Spot eviction landed within a narrow 27-minute
  window:

  | Day | Eviction time (UTC) | Eviction time (PT) | cells with solutions at eviction |
  |---|---|---|---|
  | Mon 2026-06-01 | 14:12:20 | 07:12:20 PT | 17,433 |
  | Tue 2026-06-02 | 14:39:00 | 07:39:00 PT | 17,694 |
  | Wed 2026-06-03 | 14:33:42 | 07:33:42 PT | 23,553 |
  | Thu 2026-06-04 | 14:42:00 | 07:42:00 PT | 32,139 |
  | Fri 2026-06-05 | 14:49:32 | 07:49:32 PT | 40,396 |
  | Sat 2026-06-06 | (none) | (none) | — |
  | Sun 2026-06-07 | (none) | (none) | — |

  Five datapoints across M-F all within a **37-minute window (07:12–07:49 PT)** —
  100 % hit rate across the campaign's M-F sequence. Statistically
  improbable as coincidence. **Both weekend days produced zero evictions**
  (~54 hours of continuous Spot runway through Sat 00:00 PT → Sun 23:00 PT),
  strong empirical support for the M-F-only scheduled-reclamation hypothesis
  in the westus3 D128als_v7 Spot pool.
  Still can't fully distinguish "the westus3 D128als_v7 Spot pool has
  scheduled reclamation around 07:30 PT" from "this customer of the
  same pool happens to be aggressively renewing in that window."
  But the timing has been tight enough to be operationally
  actionable: the wait-relaunch-window's M-F daytime defer policy
  (defer to 18:01 PT same day) handles these cleanly without operator
  intervention. Wall-time cost per such eviction is ~10h 22min of defer
  (off-hours waits would be 75 min flat instead). Spend impact is
  negligible: the deallocated D128 doesn't bill; the Premium SSD baseline
  continues at $0.18/h.

  *Possible interpretation note* for operators planning future campaigns:
  if the pattern persists, launching a campaign just **after** the
  07:30 PT eviction window (say 08:00 PT) could give nearly 24 hours
  of clean runway before the first eviction; launching just **before**
  (e.g. 06:30 PT) almost guarantees an immediate first eviction. The
  current 560T campaign launched at 17:01 PT Sun, which gave ~14 hours
  of clean runway before the Mon 07:12 PT eviction.

- **CPU-frequency warmup is normal; expect a 3-6h ramp after `az vm start`.**
  Empirical observation from the 2026-06 560T campaign across four
  post-`az vm start` host instantiations (initial provision + 3
  eviction-recoveries): on a fresh post-`az vm start` host, the
  `solve --cpu-freq` probe returns min ≈ 2596 MHz (the EPYC 9V74 base
  clock = 2.6 GHz), avg ≈ 2620–2690 MHz, max ≈ 4540 MHz (a single momentary
  core boost). Over the following **3–10 hours of sustained load**, both
  min and avg climb to **3250–3550 MHz** as Linux DVFS / cpufreq governor
  decisions adapt, AMD Precision Boost grants sustained elevated clocks
  across all 128 cores once the workload pattern is observed, and thermal
  envelopes stabilize. Effective throughput tracks this: ~1,300 M nodes/sec
  at base clock, ~1,400–1,470 M nodes/sec at the elevated steady-state.
  **Implication**: do not treat a "low" cpu-freq reading immediately after
  `az vm start` as a problem — it's the host's cold-cache cold-thermal-
  cold-governor state. The supervisor's `--cpu-freq 2400` HEALTHY threshold
  is below the base clock by design, so freshly-started healthy hosts pass
  cleanly. The warmup is what's worth observing across the next several
  hours of brief-status polling.
- **Live-tunable wait + throttle policy via config file.** The four knobs —
  `DEFER_START_HR`, `DEFER_END_HR`, `OFFHOURS_WAIT_SEC` (the wait policy)
  and `THROTTLE_THRESHOLD` (the mid-run probe sensitivity) — live in a
  config file that the supervisor re-reads on every `wait_relaunch_window`
  call AND every main-loop cycle. The operator can edit the file mid-run
  to shift the daytime-defer boundary (e.g. 18:00 → 19:00 PT if a particular
  hour proves to be a high-eviction bucket) or to tighten/loosen the
  throttle threshold, without restarting the supervisor. Important for
  multi-day campaigns where empirical eviction or throttling patterns may
  diverge from the pre-launch plan and operator intervention needs to be
  cheap.
- **Progress measurement: count `.dfs_state` files (not `.bin`).**
  The C enumerator's stdout (`enum.out`) has two number-bearing patterns
  that look like progress indicators but mislead: (a) per-thread
  `*** Sub-branch NNNNN/158364 BUDGETED ***` announcements are emitted by
  whichever thread happens to exhaust its current cell's per-cell budget,
  and post-eviction-resume the new enum process picks cells out of order
  based on which `.dfs_state` checkpoints exist — so a tail-1 of those
  announcements returns a stale-looking cell index, not the maximum;
  (b) the periodic status line's `XXXX/158364 sub-branches (NN%)` field
  is the count of cells the in-process auto-merger has folded into the
  shared shard table, which stays at 0 throughout any campaign using
  `SOLVE_SKIP_AUTOMERGE=1` (the canonical-pipeline pattern). The reliable
  progress measure is **the filesystem itself**: each scanned cell writes
  a `sub_*.dfs_state` checkpoint regardless of whether it found
  solutions, so:

  ```bash
  CELLS_SCANNED=$(find $RUN_DIR -maxdepth 1 -name 'sub_*.dfs_state' -type f | wc -l)
  ```

  is the authoritative cells-scanned count and the right "% of campaign
  complete" denominator.

  **Important nuance** (empirically established mid-run on the 2026-06
  560T campaign): the `sub_*.bin` shard-file count is **NOT** a valid
  progress measure. solve.c writes a `.bin` only for cells that find
  ≥ 1 solution; cells whose 3.5 B-node budget fully exhausts but
  finds 0 solutions (C3/C5 prunes deeply enough to rule out valid King
  Wen orderings) leave a `.dfs_state` checkpoint but no `.bin`. In the
  2026-06 560T campaign, **58.8 % of fully-scanned cells produced zero
  solutions** — so the `.bin` count is roughly **0.41× the scanned-cells
  count**. ⚠ **[CORRECTED 2026-09-01 — this read "63.6 %" and "0.37×",
  labelled "empirically established mid-run". It was a mid-run snapshot, and
  the campaign's own finals in §7 of this document supersede it: 65,281
  non-empty shards (**41.22 %**) against 93,083 zero-solution cells
  (**58.78 %**) over 158,364 scanned. Applying the published 0.37 rule to the
  final 65,281 shards estimates 176,435 scanned cells — **111.4 % of the
  entire campaign**, an impossible progress reading, and progress reporting is
  exactly the use prescribed just above. The correct coefficient is
  65,281 / 158,364 = 0.4122.]** Reporting `.bin` count as "cells closed" or "cells complete"
  is misleading. The `.bin` count is the right shard inventory for
  **merge-stage planning** (how many files the merger consumes), but
  not for campaign-progress reporting.

  Use `find ... -name '...' -type f | wc -l` rather than shell glob:
  at canonical scale the glob hits `ARG_MAX` once the file count
  crosses ~ 30 K and silently fails (returns 0). The `find` invocation
  does its matching inside the find process and has no `argv` limit.
- **Cold archive includes shards + dfs_state + budget tarballs.** Cold
  archive itself is extension-ready (you do not need the live Premium to
  extend).
- **Extension recipe written into the archive directory** — see
  `EXTENSION_RECIPE.txt` in the archive.
- **`SOLVE_SKIP_IOPS_CHECK=1` on every (re)launch.** The C enumerator's I/O
  pre-check is noisy on cold-cache fresh-boot VMs (see the boxed note in
  section 3). The first-launch gate at campaign initialization is
  authoritative; subsequent eviction-resume launches bypass the gate via the
  env var. Known-bypass, not a fix — the underlying probe-design issue is a
  post-campaign hardening item.

### Close-out lessons learned (added 2026-06-10 — bake into the next extension's supervisors)

The 560T close-out cascade (warm copy → cold archive → analyze → blob upload)
took ~2 days of operator-attended babysitting because of a chain of small
failures that each required hand-correction. Any future extension (the 1120T step is not planned as of 2026-08-01; this recipe is retained so a
later operator can extend at any scale) must not repeat these patterns. Each rule below ships with the
specific symptom that motivated it.

1. **Separate VMs per disk source for post-merge workloads.**
   On 2026-06-09 we ran solve --analyze + verify.py (64 workers) +
   sha256sum + gzip step 2 of the cold archive **all on a single D64 Spot
   against one Standard SSD**. Aggregate IOPS budget ~5,000 split across
   130+ concurrent readers = ~38 IOPS each. solve --analyze ran 7+ h
   instead of expected ~2 h, the Spot eviction window caught it, ~$4 of
   D64 time + ~8 h of analyze work were lost.
   **Rule:** post-merge workloads (verify.py, solve --analyze, cold-archive
   gzip+azcopy, sha256sum) each get their own VM with their own attached
   disk source. Snapshot the merged solver-data into N independent disks
   if true parallelism is needed. Within a single VM, serialize — never
   run two disk-heavy workloads concurrently against the same SSD.

2. **Use account-key SAS tokens for blob writes; user-delegation SAS does
   not have data-plane permissions on this account.**
   The 2026-06-10 first cold-archive azcopy failed with
   `AuthorizationPermissionMismatch` against 354,220 files. Root cause:
   `az storage container generate-sas --as-user` produces a user-delegation
   SAS bound to the caller's AD identity, which does not have
   `Storage Blob Data Contributor` on the cold-archive storage account
   (open task #87). Account-key SAS via
   `az storage account keys list` + `az storage container generate-sas
   --account-key <key>` worked first try.
   **Rule:** all close-out azcopy scripts generate SAS via account-key,
   never via `--as-user`. Document the SAS source inline.

3. **Bash supervisor scripts must `set -o pipefail`.**
   The original cold-archive script ran
   `azcopy copy ... | tail -30` then checked `$?`. azcopy's non-zero exit
   was masked by the pipeline (tail exits 0). The script proceeded to
   touch `cold_archive.done` despite a 100%-failed upload. The fix used
   `${PIPESTATUS[0]}` to read azcopy's actual exit code; that's correct
   but easy to forget — `set -o pipefail` makes failure detection
   default.
   **Rule:** every supervisor bash script starts with
   `set -euo pipefail`. Done-marker `touch` is conditional on
   `if [ $? -eq 0 ]` of the last actual operation, never bare.

4. **Done-markers must be post-condition-checked, not just post-command-fired.**
   The cold-archive `.done` marker was touched even when the azcopy
   upload reported 0 bytes transferred and `Final Job Status: Failed`.
   The downstream watcher then fired, incorrectly indicating success.
   **Rule:** before `touch done.marker`, run a positive-verification probe
   (count files in blob = count files in staging; or list one
   representative file via `azcopy ls`). Touching the marker is the
   absolute last step after verification PASSes.

5. **Post-upload blob spot-check is mandatory.**
   On the second 560T cold-archive upload (the working one),
   `EXTENSION_RECIPE.txt` was silently skipped despite being in the
   staging dir at upload time. Cause is still unclear — possibly a race
   between the file's creation timestamp and azcopy's `--overwrite=ifSourceNewer`
   logic. A blob audit (`azcopy ls | grep -v 'shards/' | sort`)
   immediately after upload caught the omission within 60 seconds.
   **Rule:** every close-out upload script runs a blob audit at end:
   (a) count files in `<blob>/shards/` matches expected per-file-type;
   (b) listing of `<blob>/` top-level files matches expected manifest.
   Hard-fail the script if either diverges; do NOT touch the done-marker.

6. **Cold-archive's `find` pattern must enumerate ALL sub_* file types
   produced by solve.**
   The original cold-archive script's pattern was
   `\( -name 'sub_*.bin' -o -name 'sub_*.dfs_state' -o -name 'sub_*.budget' \)`.
   At canonical scale solve.c also produces `sub_*.bin.budget` and
   `sub_*.bin.provenance.json` per cell — 65,281 files each, 130,562
   total — silently excluded from the archive. The follow-up pass had to
   re-do them.
   **Rule:** the canonical cold-archive find pattern is
   `\( -name 'sub_*.bin' -o -name 'sub_*.dfs_state' -o
   -name 'sub_*.bin.budget' -o -name 'sub_*.bin.provenance.json' \)`.
   Pre-script: count files of each pattern on source, compare to expected
   total; hard-fail on mismatch.

7. **`.azcopy/plans` directory permission must be writable BEFORE the first
   `azcopy copy`.**
   On 2026-06-10 the cold-archive's first azcopy attempt failed with
   `mkdir /home/azureuser/.azcopy/plans: permission denied`. The
   `.azcopy/plans` dir was mode 000 (created by a prior session's
   `sudo`-prefixed command). The script needed
   `chmod -R 755 ~/.azcopy` to recover.
   **Rule:** any VM that will run azcopy gets a pre-flight
   `mkdir -p ~/.azcopy/plans && chmod 755 ~/.azcopy ~/.azcopy/plans`
   AND/OR `export AZCOPY_JOB_PLAN_LOCATION=/tmp/azcopy_plans` in the
   supervisor. Belt + suspenders.

8. **`solve --analyze` at canonical scale: D128 Standard is right-sized.
   The bottleneck is page-cache fraction of `solutions.bin`, not cores
   or RAM-for-bitmaps.**
   Empirical data from the 2026-06-10/11 560T analyze cascade (three
   attempts at three VM sizes): D32 (64 GB RAM, holds 19% of 336 GB
   `solutions.bin` in page cache) projected 3 h total wall — every
   re-pass-over-records section hits disk at ~450 MB/s Premium SSD
   bandwidth ≈ **12.5 min per pass** (336,808,703,936 B ÷ 450 MB/s = 748 s).
   ⚠ **[CORRECTED 2026-09-01 — this read "≈ 22 min per pass" here and again
   six lines below. The two published factors give 12.5 min, not 22. The same
   figure appears in `documentation/HISTORY.md` (2026-06-10/11 analyze-sizing
   entry) and is **not** corrected there by this pass — reported, not
   edited. ⚠ **[FOLLOW-UP CLOSED 2026-09-02 (prose batch P70) — the HISTORY.md
   site named above is now corrected, and its withdrawn cost comparison with
   it; that entry carries its own marker and the two retired forms are
   registered as `RP-a8eb3931` and `RP-dd27f0bf`. The handoff sentence above
   is preserved as the record of how the site was carried forward rather than
   lost.]**]** D64 (128 GB, 38% cache) was where the
   original §[10] code ran for 24h+ without finishing — but that was a
   pre-rewrite issue, not a sizing issue per se. **D128 (256 GB, 76%
   cache)** finished a full --analyze on the 560T canonical in
   **3 h 47 m (13,631 s, measured)** with the post-#141/#142/#143 rewrites —
   `analyze_v3_560T.log`, the run recorded in
   [HISTORY.md](HISTORY.md) §"560T `--analyze` scientific findings", and cited
   independently at the same 13,631 s by
   [PARTITION_STABILITY_BOUNDARIES.md](PARTITION_STABILITY_BOUNDARIES.md) and
   [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md).
   ⚠ **[CORRECTED 2026-09-01 — this read "finished a full --analyze on the
   560T canonical in ~1.5 h", stating a **projection** as an accomplished
   fact. HISTORY.md's pre-run entry is explicit that ~1.5 h was
   "**Projected** total wall on D128"; the run itself took 13,631 s, 2.5× the
   projection. Everything downstream of it in this rule — the cost figure and
   the 1120T forecast — was re-derived from 13,631 s in the same pass.]**
   The cache fraction matters
   more than core count because multiple sections (§[10] tile-by-records,
   §[11] hash-set dedup, §[12] null-model, §[13]a/b orbit, §[16] bug-
   impact, §[20] complement-orbit, §[22] complement-distance, §[24] NN
   catalog) each do one full pass over `n_sols` records via mmap.
   Without the cache, each is independently ~12.5 min disk-bound.
   With a 76% cache after the first [stream] pass, subsequent sections
   are largely cache-resident and finish in seconds-to-minutes.
   Compute ceiling: analyze saturates at ~5-10 effective cores regardless
   of VM size — the limiting factor is memory bandwidth in the parallel
   sections (§[10], §[20], §[22]). So a D128 spends compute mostly idle,
   but the extra RAM is what's actually doing the work.
   **Rule:** size analyze VM at **D128als_v7 Standard** for 560T+ canonicals.
   Cost: ~$5/hr × 3 h 47 m = **~$18.93 per analyze run**, measured, not
   projected. Down-sizing to D64 or D32 still saves nothing net once wall
   time is accounted for, and D32 hits a "this won't fit" regime once the
   file exceeds ~5× cache size. For 1120T extension
   (file ~540 GB projected): D128's 256 GB cache still fits 47% of the
   file — analyze remains feasible there.
   §[10]/§[11]/§[20] are now algorithmic-rewrite-bound rather than core-
   count-bound (see rule 14). Measured --analyze wall after the rewrites:
   **13,631 s (3 h 47 m) at 10.5 B records (560T) on D128.** Scaling that
   base linearly by record count, 1120T at ~18 B records projects to
   **≥6.5 h** (13,631 s × 18 / 10.525 = 23,311 s) — and ≥ is the right
   relation, because D128's cache fraction falls from 76 % to 47 % on the
   larger file, so the disk-bound sections get worse than linearly. Budget
   ~$33 and up for a 1120T analyze run.
   ⚠ **[CORRECTED 2026-09-01 — the cost read "~$5/hr × 1.5 h = ~$7.50" and
   the forecast read "~1.5 h at 10.5 B records (560T) … ~3-5 h at 18 B records
   (1120T)". Both descended from the ~1.5 h projection corrected above. At the
   measured 13,631 s the 560 T run cost ~$18.93, 2.5× what was published, and
   the 1120T forecast — which was **below** the true 560 T wall — is replaced
   by a re-derivation from the measured base. The D64/D32 comparison figures
   were struck rather than rescaled: they were projections against a
   projection, and no measured wall exists for either SKU at 560 T.]**

9. **Extension saves the parent's already-walked nodes — it does not skip
   cells. There is no published 560T cost total to anchor an estimate to.**
   The cost model previously published here rested on two things that are not
   so, and both are withdrawn rather than rescaled.
   **(a) No cell exhausts, so no cell is skipped.** At every realistic
   canonical scale *every* cell hits BUDGETED
   ([CANONICAL_HASHES.md](CANONICAL_HASHES.md) §"100B and sub-canonical
   reference shas" item 1), and §7 of this document records the 560 T
   campaign's own confirmation: **158,364 `.dfs_state` checkpoints, 100 % of
   cells scanned**, none EXHAUSTED. So the cap-hit fraction is **100 %**, not
   41-50 %. Every cell continues into an extension. What extension actually
   buys is that the parent's nodes are not re-walked — a 560T → 1120T
   extension would walk the *additional* 560 T nodes, i.e. roughly the **same
   enum compute as the source campaign**, not half of it. (No such extension
   has been run; 560 T remains the deepest canonical.)
   **(b) No `$360` anchor exists in the public corpus.** `grep -rn '\$360'`
   over `documentation/`, `reports/` and the root markdown returns exactly one
   hit — the sentence this note replaces. The 560 T campaign entry in
   HISTORY.md records launch, wall, records, sha, verify status
   and eviction count, and **no cost total** *(2026-09-02, prose lane: this list read
   "…sha, dedup ratio, verify status…"; measured, that HISTORY entry records no ratio of
   any kind — the pre-merge shard total and its 4.17× factor live in this file's own 560 T
   table above, relabelled 2026-08-28 as cross-sub-branch rediscovery of canonical keys,
   not an orientation-dedup ratio)*; the file's cost totals stop at
   earlier, smaller campaigns. The `$690 = 2 × $360` anchor and the `~$390
   incremental` figure derived from it therefore both rested on a number the
   corpus never published, and the `~$390` additionally assumed the 41-50 %
   model that (a) refutes. **No cost estimate for a 1120T extension is stated
   here until an itemized 560 T ledger — VM hours by SKU, disk-months,
   closeout — is published.**
   ⚠ **Additional hazard, latent, affecting any extension launched today.**
   `solve.c`'s `#167` resume guard discards a cell's checkpoint whenever its
   `.dfs_state` is present but its `.bin` shard is absent, and walks that cell
   **fresh from zero**. But `flush_sub_solutions_d3` returns before creating
   any file when a cell found no solutions — so a zero-yield cell legitimately
   has no `.bin`, and §7 records **93,083** such cells out of 158,364 at
   560 T. Every one of them would discard its checkpoint on resume:
   93,083 × 3,536,157,207 = **329,156,121,299,181 nodes (58.8 % of the entire
   560 T campaign) silently re-walked**, on top of the new work. The guard was
   written for damaged or legacy archives and its own comment calls it
   "critical for the 1120T extension"; it fires on legitimately-empty cells.
   **This is a code defect, not a documentation one, and it is not fixed.**
   Any extension cost or wall estimate must either assume the redo or wait for
   the guard to be made yield-aware.
   ⚠ **[CORRECTED 2026-09-01 — replaces "Extension cost is NOT 2× the source's
   cost; it's incremental … Real estimate … **~$390 incremental** … For
   560T → 1120T, that fraction was empirically ~41-50 %."** The 41-50 % was
   the campaign's *non-empty-shard yield* (41.22 %, stated in §7), reused
   ~300 lines later as if it were the cap-hit fraction; the two are unrelated
   and the cap-hit fraction is 100 %. The dollar figures are withdrawn for
   want of a ledger, per (b).]**

10. **Extension wall time ≈ the wall for the *added* budget — not 2×, and not
    sublinear from cell exhaustion.**
    A 560T → 1120T extension resumes every cell from its checkpoint and walks
    the additional 560 T nodes, so the enum wall is about **one source enum's
    worth (~7 days)**, not 14 and not the 3-5 days previously stated. The
    saving over a from-scratch 1120 T run is real — the parent's 560 T of
    nodes are not re-walked — but it is a saving of one source campaign, not
    a fraction of one.
    **Rule:** describe "extension to scale X" as "the wall to walk (X − source
    budget) nodes", not as a multiple of the source wall, and not as sublinear.
    ⚠ **[CORRECTED 2026-09-01 — this read "Real estimate is ~3-5 days enum
    (60% of source enum at most, since only ~50 % of cells continue past their
    source budget)" and attributed the sublinearity to "cell exhaustion at
    source budget". **No cell exhausts at 560 T** — §7 records 158,364
    `.dfs_state` checkpoints, 100 % of cells scanned and budgeted — so 100 %
    of cells continue, and the mechanism claimed for the sublinearity does not
    exist. Same defective model as rule 9, which carries the full
    correction. Note also that the `#167` redo hazard described in rule 9
    would add ~329 T nodes of repeated work to this wall until it is fixed.]**

11. **Cold archive completeness — split into two categories.**
    Original 560T cold archive shipped without `EXTENSION_RECIPE.txt`,
    full analyze log, `merge.full.log`, `verify_c.log`, or per-thread
    checkpoints. Operator audit caught it. The followup pass had to
    re-do all of them.

    **Rule — Category A (load-bearing for extension; MUST be present):**
    - `solutions.bin.gz` + `solutions.sha256` + `solutions.bin.computed.sha256`
    - `sub_*.bin.gz` (per-cell solutions) — **all 4 sub_* types as one set**
    - `sub_*.dfs_state.gz` (per-cell DFS resume state)
    - `sub_*.bin.budget.gz` (per-cell source budget)
    - `sub_*.bin.provenance.json.gz` (per-cell provenance)
    - `solutions.provenance.json`, `canonical-host-fingerprint.json`,
      `build.sha`, `shard_manifest.txt`
    - `EXTENSION_RECIPE.txt` (operational recipe per §3 — frozen at archive
      time; lives in the archive, not just the live repo)
    - `parent_canonical.txt` (lineage anchor — `this_canonical_sha`,
      `this_canonical_scale`, `parent_canonical_sha`, `parent_canonical_scale`;
      `ROOT` for fresh enums, `<sha> <scale>` for extensions. Convention
      baked into `phase_b_recover_and_archive_supervise.sh` 2026-06-11
      after the original 560T archive shipped without it. Required so
      future archive readers can verify the milestone-extension chain
      back to the lineage root.)

    Without any one of the above, a fresh-VM + fresh-storage extension
    cannot resume byte-faithfully.

    **Rule — Category B (forensic / audit completeness; SHOULD be present):**
    - `merge.full.log` (merge stage trace)
    - `verify_c.log` (`solve --verify` output)
    - `verify_py_*.log` (Python verifier output)
    - `analyze_*.log` (full `solve --analyze` findings)
    - `checkpoint_t*.txt.gz` (per-thread checkpoint files from the
      enum's #108 per-thread-state code path; ~27 MB compressed at
      canonical scale; useful for reconstructing per-thread interleaving
      across eviction-recovery cycles, NOT load-bearing for extension)
    - `preserve_logs/cold_archive.log` + `preserve_logs/azcopy_logs/`
      (supervisor logs from the archive run itself, preserved before VM
      deallocate per rule 12)

    Without Category B, extension still works but forensic audit of how
    the campaign actually ran (eviction-recovery sequence, per-thread
    timing, archive-supervisor failure modes) becomes guesswork.

    A pre-archive checklist that asserts each Category A file is present
    in staging before azcopy fires is the right gate. Category B files
    can be missing without blocking, but the supervisor should log a
    WARN per missing file so it surfaces in the post-archive audit.

12. **Pre-deallocate log preservation: copy /tmp/cold_archive*.log to
    solver-data first.**
    The cold-archive VM's /tmp is tmpfs and is lost on `az vm deallocate`
    (or even on reboot). Almost lost the upload-failure forensic logs
    that caught the AuthorizationPermissionMismatch.
    **Rule:** any VM that ran a supervisor script preserves /tmp/*.log
    + /tmp/azcopy_logs to `solver-data:/canonical-archive/<archive_dir>/preserve_logs/`
    before `az vm deallocate` is issued.

13. **Analyze + cold-archive can run on separate VMs simultaneously
    (with separate disk sources) — and should.**
    On 2026-06-09 attempt 2 (after the Spot eviction): split into
    c560-d64-coldarchive (on solver-data) + c560-d64-analyze2 (on Premium
    SSD). Analyze ran ~3× faster than the contended attempt 1 because no
    I/O competition for the same disk. Cost: one extra D64 hour
    (~$2.50), saved: 4-5 h of analyze wall = ~$10 of D64 + lower
    Spot-eviction risk.
    **Rule:** the canonical post-merge pattern is **two D64 Standard
    VMs**, each with its own disk: cold-archive on solver-data,
    analyze on Premium SSD. Don't try to bundle both on one VM unless
    operator explicitly authorizes for cost reasons.

14. **`solve --analyze` section design at canonical scale: one pass over
    records, never an outer loop with inner full-scan.**
    The 2026-06-10/11 §[10]/§[11]/§[20] rewrites (commits `8ac5e8f`,
    `fe58e71`, `bf8d8a5`) all collapse to the same fix: the original code
    nested an outer loop (over pairs / p1 values / re-orderings) around an
    inner `for (i = 0; i < n_sols; i++)`, doing K × `n_sols` record
    reads. At 100T this was unpleasant but tolerable; at 560T (10.5 B
    records, 336 GB file) it became 100s-of-hours infeasible. The §[10]
    case was the worst: 496 × `n_sols` = 167 TB of mmap reads = 24h+ on
    D64 without finishing.
    **Rule for any new section added to --analyze:** the section must
    iterate `n_sols` records **at most once**. Aggregation that requires
    "per-X per-record" updates is done inline during the single record
    pass (per-thread tables, hash sets, etc.). Multi-pass anti-patterns
    are forbidden at canonical scale. The same anti-pattern caused the
    §[20] OLD code to also allocate `n_sols × 32 byte` (336 GB at 560T)
    — same fix: stream the per-record computation against the already-
    sorted `all` via binary search; ZERO extra memory.
    Each canonical section's existing time-and-space pattern after the
    rewrites:
    - §[10] pairwise MI: ONE pass + 496 × 1024 = 4 MB joint-count table
      per thread; reduce at end
    - §[11] per-p1 distinct configs: ONE pass + 32 × 4096-slot hash
      sets (~2.2 MB total)
    - §[20] complement orbit: ONE parallel pass, ZERO extra memory,
      streams each complement into `all` via binary search
    Similarly-structured anti-pattern survives in §[12]-§[19]/§[21]-
    §[28] (each one re-reads the `n_sols` records once for its own
    aggregate). These remaining sections are cheap individually (~1-3
    min each at 560T on D128's cached file) but the cumulative effect
    of N sections × one pass × 336 GB is what makes D128's 76% cache
    fraction matter so much. A future pass to collapse multiple
    sections into one shared record-scan (with all their accumulators
    updated simultaneously) is the next-level optimization, but the
    current per-section ONE pass design is sufficient for 560T → 1120T
    extension on D128.
    **Companion rule for observability:** every n_sols-iterating loop in
    --analyze must emit per-1% progress to stderr using the shared
    `ANALYZE_EMIT_PROGRESS` macro at the top of `solve.c`. The macro
    auto-detects `omp_in_parallel()` × `omp_get_num_threads()` for
    accurate display under static OpenMP scheduling. Stdout (the
    canonical analyze output) is never touched — sha-neutral by
    construction.

---

## 8. Reproducing a canonical from scratch (third party, no cooperation)

Given only the public artifacts (`solve.c` at a specific git ref + the
[CANONICAL_HASHES.md](CANONICAL_HASHES.md) entry naming the expected sha + budget),
a third party can reproduce any canonical as follows:

1. Clone the source repository, checkout the git ref named in the canonical's
   row in [CANONICAL_HASHES.md](CANONICAL_HASHES.md).
2. Build with the canonical flags (`gcc -O3 -g -march=native -flto -pthread
   -fopenmp -o solve solve.c -lm -lz`).
3. Confirm the built binary's selftest sha matches the published selftest
   anchor (`./solve --selftest` should emit `403f7202...` — see
   [DEVELOPMENT.md](DEVELOPMENT.md)).
4. Run the canonical at the scale's published per-cell budget:
   ```bash
   SOLVE_DEPTH=<published_DEPTH> \
   SOLVE_NODE_LIMIT=<published_NL> SOLVE_PER_SUB_BRANCH_LIMIT=<published_PSB> \
   SOLVE_THREADS=<your_thread_count> SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 \
     ./solve 0 <your_thread_count>
   ```
   `SOLVE_DEPTH` is **sha-determining and must be copied from the canonical's row**
   ([CANONICAL_HASHES.md](CANONICAL_HASHES.md) §"Reproducibility parameters"): every d3
   canonical (1T / 5.6T / 10T / 11.2T / 100T / 560T) needs `SOLVE_DEPTH=3`. Omitting it does
   **not** error — the code default is `2` (solve.c, "Default 2 for byte-identical behavior with
   the canonical 10T baseline"), so the run silently enumerates the d2 partition and can never
   reproduce a d3 sha. Nothing flags the mismatch until the sha compare in step 6.
5. Merge the resulting shards: `SOLVE_MERGE_MODE=external ./solve --merge`.
   The merge is **sha-invariant to `SOLVE_MERGE_THREADS`**: serial (default `=1`) and parallel
   (`>1`) both produce the byte-identical canonical — validated at 1T and, on 2026-07-01, at **560T**
   (threads=16 external merge reproduced `9a968fa2…`). At canonical scale the Phase-2 k-way step opens
   all sorted chunks at once (a 1 GB-chunk 560T merge makes ~1,308); `solve` auto-raises `RLIMIT_NOFILE`
   at merge start so this can't hit "Too many open files" (override via `SOLVE_MERGE_NOFILE` /
   `SOLVE_SKIP_NOFILE_RAISE`; see SOLVE_C_CLI.md).
6. Compute `gzip -dc solutions.bin | sha256sum` and compare to the published sha. (Since #169
   `solutions.bin` is written **gzip-framed by default**; every canonical sha is computed on the
   DECOMPRESSED stream, so a plain `sha256sum solutions.bin` hashes the container and yields a
   false mismatch. Under `SOLVE_COMPRESS=0` the file is raw and plain `sha256sum` is correct. The
   `solutions.sha256` sidecar already carries the logical sha either way.)

On a host in the same SKU class as the original campaign (D128als_v7 Spot
westus3 for our 11.2T+ canonicals), the sha should match byte-identically.
On a different host class, structural verification (`solve --verify` +
`verify.py`) should PASS even if the sha differs — but read that carefully:
it confirms the records the artifact *contains* are valid. It says nothing
about records it is *missing*, because neither instrument checks completeness
([VERIFY.md](VERIFY.md)). A differing sha is a differing record set (§6), so
treat it as a result to characterize, not as a pass. *(Scoped 2026-09-01: this
read "that's a confirmation that the enumeration is correct", which overstates
what a forward pass can establish.)*

---

## 9. What this document does not cover

- The mathematical content of the constraints C1–C5, the partition-
  invariance theorem proof, the King Wen sequence interpretation —
  see [SOLVE.md](SOLVE.md), [SPECIFICATION.md](SPECIFICATION.md),
  and [PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md).
- Step-by-step Azure deployment (VM sizing, disk SKU choices, networking) —
  see [DEPLOYMENT.md](DEPLOYMENT.md).
- The full operational runbook for the 560 T pipeline, including supervisor
  scripts, eviction-recovery internals, and pre-flight gates — those live in
  the project's private operational repository.

---

## 10. Relationship to `LARGE_SCALE_CAMPAIGNS.md`

*Rewritten 2026-08-08. This section previously read "## DRAFT TODO before porting to public" and
carried ~16 unchecked checklist items, inside an already-published document. Two things were wrong
with that. First, a live pre-publish checklist in a public doc tells a reader the document is not
finished being published — and the reader is right. Second, its central premise was false.*

**The premise that was false.** The old plan asserted this document "REPLACES
`documentation/LARGE_SCALE_CAMPAIGNS.md`" and that that file's 1,100 lines were "subsumed here
during the port," ending with "delete `LARGE_SCALE_CAMPAIGNS.md`." A section-by-section comparison
on 2026-08-08 found no such subsumption. The two documents are **complementary**:

| | owns |
|---|---|
| **CAMPAIGN_METHODOLOGY.md** (this doc) | *Correctness* — what "canonical" means, per-cell uniform budget, extension, what must be preserved, sha stability vs host fragility, third-party reproduction |
| **[LARGE_SCALE_CAMPAIGNS.md](LARGE_SCALE_CAMPAIGNS.md)** | *Operations* — sizing and per-thread rates, campaign architecture pseudocode, branch distribution, disk-based external merge, common gotchas |

Material that exists **only** in `LARGE_SCALE_CAMPAIGNS.md`, with no counterpart here: §2 sizing
(the phrase "per-thread rate" occurs 8× there and 0× here), §6 runner/orchestrator pseudocode,
§9b/9c external and tiered merge, §13a gotchas, and — the one that mattered most in deciding not to
delete — **§13.0 "Scale honesty," the disclosure that `solve.c` is not empirically validated above
the 100T pilot.** Deleting the file per the old plan would have removed a candid limitation
statement from the public record. It is retained.

**Status of that file:** deprecated as the *entry point* (new readers start here), retained as the
operations reference. It is not awaiting deletion.

## 11. Open items

Tracked honestly rather than as a checklist, because a checkbox in a published document reads as an
obligation the document itself has not met:

- **560 T campaign numbers.** §7's worked example carries figures from the completed campaign. The
  authoritative sha and record count are in
  [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §"d3 560T" (`9a968fa2…`, 10,525,271,997 records,
  CANONICAL-verified 2026-06-30); where this document and that registry ever disagree, **the
  registry wins**.
- **`EXTENSION_RECIPE.txt`.** §3 describes the recipe the archive supervisor emits. The described
  text has not been diffed against actual supervisor output since commit `800a8df`.
- **Cold-read check.** Whether §§3, 4 and 8 suffice for a third party to extend or reproduce
  *without* author assistance has not been tested on an actual outside reader. §9 states the
  document's own scope limits.
