# CLAUDE.md

Orientation file for Claude (the AI assistant) working on this repo.
Humans: you probably want [README.md](README.md) or
[GUIDE.md](documentation/GUIDE.md). This file is terse by design — pointers and
invariants, not content.

## Project

ROAE = a mathematical analysis of the King Wen sequence (I Ching). Core
deliverable is `solve.c` — a multi-threaded C enumerator that searches for
orderings of 64 hexagrams satisfying constraints C1-C5 **within a per-cell
node budget** — plus the scientific record documenting what those
enumerations reveal about King Wen's uniqueness vs. combinatorial structure.

⚠ **It does not exhaust that space, and no run ever has.** Every published
enumeration is budgeted per cell, so what it produces is an
exactly-reproducible **slice** and its record count is a **LOWER BOUND** on
the C1–C5 population — an absence *inside a slice* is not an absence in
C1–C5. (Corrected 2026-08-28, Q-353; this sentence was missed by that sweep
and repaired 2026-09-02. The retired wording is registered in
[RETRACTED_PHRASES.tsv](documentation/RETRACTED_PHRASES.tsv) and recorded in
[CORRECTIONS.md](documentation/CORRECTIONS.md); the corrected statement of
what an enumeration artifact contains is
[SOLUTIONS_FORMAT.md](documentation/SOLUTIONS_FORMAT.md).)

## Authoritative sources

| Topic | Read |
|---|---|
| Python regression harness (one command: `python3 tests.py`) | [tests.py](tests.py) |
| **Technical report suite (findings in depth, living-versioned)** | [reports/README.md](reports/README.md) (+ METHODS.md, certificates/) |
| Detailed findings narrative (former front page) | [PROJECT_OVERVIEW.md](documentation/PROJECT_OVERVIEW.md) |
| Public scientific record (what holds, what doesn't) | [SOLVE.md](documentation/SOLVE.md), [SOLVE_SUMMARY.md](documentation/SOLVE_SUMMARY.md), [CRITIQUE.md](documentation/CRITIQUE.md) |
| Stable paper-citable findings | [PARTITION_STABILITY_BOUNDARIES.md](documentation/PARTITION_STABILITY_BOUNDARIES.md), [BOUNDARY_MINIMUM.md](documentation/BOUNDARY_MINIMUM.md), [SYMMETRY_SEARCH.md](documentation/SYMMETRY_SEARCH.md), [PASS1_TRAJECTORY_DETERMINISM.md](documentation/PASS1_TRAJECTORY_DETERMINISM.md) (consolidated from `findings/` 2026-06-11; boundary doc renamed 2026-07-04) |
| Plain-language explainer of branches, sub-branches, nodes, enumeration | [BRANCHES_EXPLAINED.md](documentation/BRANCHES_EXPLAINED.md) |
| Distributional analysis of KW's position in the observable-space joint distribution | [DISTRIBUTIONAL_ANALYSIS.md](documentation/DISTRIBUTIONAL_ANALYSIS.md) |
| Total C1–C5 search-space size (Monte-Carlo estimate ≈10³⁸; why KW is found early) | [SEARCH_SPACE_SIZE.md](documentation/SEARCH_SPACE_SIZE.md) |
| Bit-level constraint pricing (MDL ledger, unexplained residual) | [DESCRIPTION_LENGTH.md](documentation/DESCRIPTION_LENGTH.md) |
| Circular (wrap-around) reading: theorems + SAT decision | [CIRCULAR_KING_WEN.md](documentation/CIRCULAR_KING_WEN.md) |
| Literature rules measured at population scale + SAT-decided exact results | [LITERATURE_RULES_POPULATION_TESTS.md](documentation/LITERATURE_RULES_POPULATION_TESTS.md) |
| Parity-alternation theorem (three-modality verification) | [PARITY_ALTERNATION.md](documentation/PARITY_ALTERNATION.md) |
| Prior literature + what is classical / prior / novel / methodological citations | [CITATIONS.md](documentation/CITATIONS.md) |
| Formal constraint definitions + theorems | [SPECIFICATION.md](documentation/SPECIFICATION.md) |
| **Canonical sha256 registry + reproducibility parameters** | [CANONICAL_HASHES.md](documentation/CANONICAL_HASHES.md) |
| Binary output format + verifier recipe | [SOLUTIONS_FORMAT.md](documentation/SOLUTIONS_FORMAT.md), [REBUILD_FROM_SPEC.md](documentation/REBUILD_FROM_SPEC.md), [verify.py](verify.py) |
| Partition invariance theorem | [PARTITION_INVARIANCE.md](documentation/PARTITION_INVARIANCE.md) |
| Project narrative + why-decisions-were-made | [HISTORY.md](documentation/HISTORY.md) |
| Enumeration leaderboard | [enumeration/LEADERBOARD.md](enumeration/LEADERBOARD.md) |
| Build / self-test / developer invariants | [DEVELOPMENT.md](documentation/DEVELOPMENT.md) |
| **Full `solve` (C binary) CLI reference** (subcommands, env vars, exit codes; `--selftest`'s `TMPDIR` scratch directory is described there too) | [SOLVE_C_CLI.md](documentation/SOLVE_C_CLI.md) |
| **Full `solve.py` CLI reference** (analysis sections + verification/companion commands) | [SOLVE_PY_CLI.md](documentation/SOLVE_PY_CLI.md) |
| **Full `roae.py` CLI reference** (29 analysis sections, modifiers, exports) | [ROAE_PY_CLI.md](documentation/ROAE_PY_CLI.md) |
| **`sat.py` SAT/certificate-layer CLI** (CNF emit, witness, C3 encoding) | [SAT_CLI.md](documentation/SAT_CLI.md) |
| Azure deployment / VM sizing | [DEPLOYMENT.md](documentation/DEPLOYMENT.md) |
| Visualization tooling + how-to-read | [viz/README.md](viz/README.md) |
| **Live operational state** (current run, schedule, in-flight work) | The current-state file in the private notes (**not in this repo**) — current, read its lead block by offset (it is ~8,300 lines, see §In-flight state; this cell said "short" until 2026-11-03, Codex F12-019#6). The plan history beside it is ~451 KiB (measured 2026-09-18; this cell said ~416 KB) of append-only history: provenance only, never orientation |
| Operator memory (user preferences, feedback rules, infra notes) | `~/.claude/projects/*/memory/MEMORY.md` |

## Canonical shas — INVARIANT

Any `solutions.bin` produced with matching input parameters **must**
reproduce one of the published canonical shas byte-identically. A
mismatch is a bug, not a new result. The full registry of canonical
hashes — with reproducibility parameters, record counts, and validation
status per canonical — lives in [CANONICAL_HASHES.md](documentation/CANONICAL_HASHES.md).

Partition invariance (see [PARTITION_INVARIANCE.md](documentation/PARTITION_INVARIANCE.md))
proves these are invariant to shard partitioning, including enumeration vs. independent-shard-merge paths, and to merge order and hierarchy (a model-level theorem); identity across hardware and region
is measured, not proved, and so is the agreement of the shipped binary's two merge modes (PARTITION_INVARIANCE.md §5a; SOLVE_C_CLI.md §REPRODUCIBILITY; "proves these are reproducible across hardware, region, merge algorithm" until 2026-11-14, CX-37C-Y, the sibling of CX-35T-J; "identity across hardware, region and merge algorithm is measured, not proved" until 2026-11-19, CX-37G-I: the merge model is proved in Lean, PARTITION_INVARIANCE.md §2a) — and the
proof is about the **model** of the computation; the bridge from that
model to the shipped binary is carried by the runtime gates
(`--selftest`, the canonical-scale sha gates, two-language cross-checks),
not by the proof itself (TR-3 §Scope). If you
produce a mismatching sha, stop and investigate — don't silently
"update" the canonical.

Older figures in project history (31.6M filename-collision bug, 742M
hash-table bug) are invalidated forensic references only.

**Current status note (2026-06-30):** the d3 560T canonical
(`9a968fa2…`) is **CANONICAL-verified**. It was SUSPECT from 2026-06-21
(a proven eviction-resume defect + 5 Spot evictions on the pre-fix
solver); a from-scratch re-run on the eviction-resume-**fixed** solver
(2026-06-30) reproduced it **byte-for-byte** (identical sha, identical
10,525,271,997 records), across 7 fresh Spot evictions that all resumed
cleanly — so the original 560T was complete and the bug did not corrupt
it. 560T is now a trusted anchor. See
[CANONICAL_HASHES.md](documentation/CANONICAL_HASHES.md) §"d3 560T".

## Performance history — required record (parallel to canonical shas)

Any commit modifying solve.c **hot paths** (DFS, prune predicates,
hash-table operations, merge inner loops, SIMD-vectorized arithmetic,
build flags affecting per-thread rate) must append an entry to
[PERFORMANCE_HISTORY.md](documentation/PERFORMANCE_HISTORY.md) before
ship. The entry must follow the schema documented at the top of that
file and be produced by `scripts/perf_bench.sh` (or document why it
deviates).

The log captures BOTH improvements AND regressions — the latter are
just as important to the project narrative. A change that fails its
sha gate or under-performs prediction is recorded honestly and either
reverted (with reasoning) or shipped with the caveat documented.

Enforcement is currently process-level (rely on reviewer + this rule).
A `scripts/pre_push_compile_gate.sh`-style hook to block pushes when
solve.c hot paths changed but PERFORMANCE_HISTORY.md did not is
planned but not yet shipped; design pass needed first to avoid false
positives on whitespace / comment-only edits.

## VM purchase type and sizing (STRICT, mandatory gate)

Checkpointable enumeration runs on interruptible (Spot) capacity; merges and
anything that cannot resume run on regular capacity, sized to the job, with
a teardown plan stated before the VM is created. Check the VM's priority
before any launch over an hour (`az vm show … --query priority`): an
enumeration VM that does not report `Spot` is not launched. Machine sizes,
regions and the rules' history are in the private operations notes.

**Cost control — VM purchase type** and
**Cost control — SKU family restrictions** were this section's two headings
until 2026-11-15, when their text moved to the private operations notes; the
ledgers and a pre-registration addendum cite them by those names.

## Session-lifecycle VM discipline (STRICT, applies to any `az vm create`)

**Problem addressed:** "mount a disk briefly for inspection" has repeatedly
left VMs running long after the inspection ended. Each cleanup gap
wastes real compute, and the waste accumulates across sessions.

**Rules, applied to every Claude-initiated VM:**

1. **Every `az vm create` must be paired with a concrete teardown plan
   in the SAME command sequence or the SAME scheduled wakeup prompt.**
   Acceptable patterns:
   - "provision → run task → deallocate" in one bash command, OR
   - Provision, then set a scheduled wakeup that includes the full
     teardown sequence (detach managed-data-disks, delete VM, clean
     orphan NIC/pip/OS-disk) — NEVER leave teardown to "next human
     interaction."
2. **Maintain a session-lifetime VM log.** When creating a new VM,
   append to `/tmp/claude_session_vms.txt` (timestamp + name + purpose).
   Before ending any autonomous wakeup chain, `az vm list` and reconcile
   against this file; tear down anything still present unless the user
   has specifically authorized keeping it.
3. **Prefer ephemeral OS disks** (`--ephemeral-os-disk true`) for VMs
   that will be deleted at session end — halves cleanup work and
   guarantees OS disk doesn't leak. **Only on a size that has local
   storage.** The VM family this project runs on has none, and the
   vendor's size page for that family lists
   "Ephemeral OS Disk — Not Supported"; `az vm create` with that flag is
   refused there (seen on its 4- and 8-core sizes, 2026-08) and the failed
   create still leaves the NIC, public IP and NSG behind. On that family,
   create with `--os-disk-delete-option Delete` so the managed OS disk is
   removed with the VM (scoped 2026-09-25, Q-763; the fuller ad-hoc VM
   rules are in the private operations notes).
4. **Data disks (the project's managed data disks) are NEVER
   deleted by Claude.** Detach before VM delete. User explicit approval
   needed to touch data-disk contents or delete the disk itself.
5. **On any session crash / interrupt, the first thing the next wakeup
   does is reconcile VM state against the session-lifetime log.**
6. **First action of every Azure-touching session: reconcile both VMs AND
   long-running scripts.** Run `az vm list -d` and account for every
   running VM. ALSO run:
   ```
   ps -ef | grep -E "\.sh$|monitor|watcher|loop" | grep -v grep
   ```
   Any bash script alive longer than the current session is a candidate
   orphan from a prior session. `pkill -f` is unreliable; use
   `kill -9 <pid>` and verify with a re-`ps`. Orphan scripts will
   silently undo VM cleanup — e.g., a monitor designed to auto-restart
   a VM after Spot eviction will keep restarting it forever once the
   originating session ends.

**Past incidents** behind these rules are recorded in HISTORY.md §Missteps
and in the private operations notes.

## Never do without explicit user approval

- Delete managed disks — the exception is **SSD-backed temp disks
  for external merges**, which are temporary by standing pattern
  (attach → use → destroy). All other managed disks, including
  orphaned OS disks from deleted VMs, require explicit approval.
- Force-push or amend published commits.
- Commit changes to `petersm3/roae` when the user has said "no
  commits" for specific paths (currently: the `.claude/` directory).
- Push anything to `petersm3/roae` without the user having had a
  chance to review non-trivial changes. Staging-doc commits to
  the private notes (a separate repository) can proceed without per-commit
  review for routine working-log updates.
- Launch large compute (≥10T enumeration or ≥3 hr external merge)
  without the user's sign-off on the compute AND without running the VM-priority
  verification gate above.
- Run `mkfs -F` (or `--force`, `-FF`, `-y`) on any block device.
  See §"Disk-handling safety" below.

## Disk-handling safety (STRICT, mandatory — added 2026-05-06)

**Why this section exists:** on 2026-05-06 a setup script ran
`mkfs.ext4 -F /dev/nvme0n3` against what it thought was an empty
256 GB SSD-backed temp disk. On the VM in question, kernel device
naming had reversed Azure LUN order: `/dev/nvme0n3` was actually
the 3 TB data disk holding the 100T canonical
artifact (102 GB `solutions.bin`, sha `915abf30…`) and the entire
2026-05 validation campaign's intermediate state. The `-F` flag
was in the command, but it is not what let this through: mkfs's
"refuse to format existing filesystem" check is gated on stdin and
stdout both being terminals, so a scripted run never gets that
refusal with or without `-F` (measured 2026-09-19; see rule 1).
The disk's contents were destroyed. No snapshots existed.

The shas survived (the project's reproducibility anchor is the sha
in this repo, not the bytes), so the loss is recoverable via
re-derivation. But the wipe was a foreseeable failure mode that
multiple structural safeguards should have caught. These rules are
those safeguards, retroactively codified.

**The rules — every disk-handling script MUST follow these:**

1. **`mkfs -F` (and `--force`, `-FF`, `-y`) is BANNED.** The ban
   removes one way to be careless; it is **not** itself the safety.
   `mkfs.ext4` enables its existing-filesystem check only when
   stdin **and** stdout are terminals, and every disk command on
   this project is scripted and non-tty — so omitting `-F` buys
   nothing on its own. Measured 2026-09-19 on a loop file, both
   streams non-tty: `mkfs.ext4 -q` run twice with no `-F` returned
   rc 0 both times and the UUID changed (`43745021…` →
   `5f9dcb7d…`), silently reformatting a live ext4; the same second
   format under a pty printed `Proceed anyway? (y,N)` and exited 1.
   **What carries the safety is rules 3 and 5** — assert size AND
   empty FSTYPE AND not-mounted, and hard-fail on mismatch — never
   a refusal from `mkfs`. If a fresh format is needed on a disk
   that previously had data, the operator runs `wipefs -a` as a
   separate, deliberate, explicitly-authorized step — never bundled
   into `mkfs` invocation.

2. **Identify pre-existing disks by UUID, not by `/dev/<name>`.**
   Azure NVMe device naming is not stable across attaches:
   LUN 0 may be `nvme0n2` on one VM and `nvme0n3` on the next.
   Use `blkid -t UUID=<expected> -o device` to discover the current
   device path, or mount by UUID directly via
   `mount UUID=<expected> <mountpoint>`.

3. **Identify newly-created (empty) disks by size + empty-FS state.**
   The pattern: `lsblk -bno NAME,SIZE,FSTYPE | awk '$2==<bytes> && $3=="" {print}'`
   should match exactly one device. Hard-fail if zero or more than
   one matches.

4. **Verify post-mount with a known marker file.** Every canonical
   data disk has a marker (e.g., `solutions.sha256` for the
   canonical solution disks). Mount scripts must `[ -f <mountpoint>/<marker> ]`
   before treating the mount as the expected disk.

5. **Pre-flight assertion before any destructive op.** Before
   `mkfs`, `wipefs`, or `dd` to a block device, assert: size matches
   expected; filesystem state matches expected (empty for fresh
   disks, matching UUID for pre-existing disks); and the device is
   **not mounted**. Hard-fail on mismatch with a clear error
   message. This assertion — not any refusal from `mkfs` — is what
   stands between the command and the disk.

The helper functions `disk_by_uuid`, `new_disk_by_size`,
`mount_known_disk`, `safe_mkfs`, and `preflight_assert_empty` are
canonical implementations of these rules; they are kept in the private
notes. VM provisioning scripts should source them.

## Single C source file — `solve.c` — no new `.c` files

**Standing rule (2026-04-21):** All C code on this project lives in
`solve.c` and all Python in `solve.py`, **except for the approved separates
enumerated below**. No new `.c` or `.py` file outside that list, not even
for analysis tools — adding one is an operator decision, not an
implementation detail.

**The approved separates — this is the complete list, and `git ls-files
'*.py' '*.c'` must not exceed it.** Dates are *first-tracked* dates,
measured with `git log --diff-filter=A --format=%ad --date=short -1 -- <path>`:

- **`solve.c`, `solve.py`** — the two core files the rule is about.
- **`sat.py`** (2026-07-02, operator-approved) — SAT/certificate layer; see
  the paragraph below.
- **`verify.py`** (first tracked 2026-04-17), **`verify.c`** (2026-07-22) —
  the INDEPENDENCE exception, operator-approved 2026-07-21; see below.
- **`roae.py`** (first tracked 2025-07-11, predating this rule) — the
  analysis CLI, with its own reference in
  [ROAE_PY_CLI.md](documentation/ROAE_PY_CLI.md).
- **`tests.py`** (2026-07-04) — the regression harness. It has to be able to
  fail on `solve.py`, so it cannot live inside it.
- **`viz/visualize.py`** (2026-04-20), **`viz/growth_curve.py`**
  (2026-06-15), **`viz/report_figures.py`** (2026-07-04) — the `viz/`
  directory-scoped exception: heavy plotting dependencies, run independently.
- **`scripts/c2c3_joint_null.py`** (2026-08-28) — the published reproducer
  for the C2∧C3 joint null, shipped deliberately because "a published figure
  whose only reproduction path was a private script would not be reproducible
  at all" ([CORRECTIONS.md](documentation/CORRECTIONS.md)). Folding it into
  `solve.py` would destroy the independence it was created to supply.
- **`scripts/decomp_certify_v3.py`**, **`scripts/n12_partition_all.py`**,
  **`scripts/q424_partition_check.py`**, **`scripts/k37_isclause_port.py`**
  (2026-11-08; operator-approved, operator 2026-11-08), with **`scripts/n12_postcheck.sh`**
  — the published code behind the certified n=12 and n=3, 4, 6, 7 counts
  (driver, partition check, postcheck and the K-37 correspondence check;
  [SAT_CLI.md](documentation/SAT_CLI.md) NOTES, CORRECTIONS.md CX-36Z-A).
  Shipped because a published count needs its code in the same change;
  they are frozen run instruments, and folding them into `sat.py` would
  break the driver's self-sha in the run log and the partition check's
  independence from the driver.
- **`scripts/decomp_certify_v3_pipe.py`**, **`scripts/n12lean_run.py`**,
  **`scripts/n10lean_run.py`**, **`scripts/lrat_run.py`**, **`scripts/cover_cert_emit.py`**,
  **`scripts/cover_cert_check.py`** (2026-11-10; operator approval 2026-11-10), with the Lake
  project **`scripts/lratcheck/`** — the published code behind the certified n=10 count and
  the verified-checker results for the n=12 and n=10 pieces (driver variant, the two
  verified-checker runners, the LRAT runner, and the cover-certificate emitter and its
  separate checker; [SAT_CLI.md](documentation/SAT_CLI.md) NOTES, CORRECTIONS.md CX-37A-A).
  Shipped because a published result needs its code in the same change; they are frozen run
  instruments: `n10lean_run.py` pins `n12lean_run.py` by sha256, and `cover_cert_check.py`
  must share no code with `cover_cert_emit.py`, so neither can be folded into `sat.py`.
- **`scripts/lratcheck/renumber_lrat.py`** (2026-11-12; operator approval 2026-11-12, Q-1094) — the
  consecutive-id renumbering between `drat-trim -L` and the Lean 4 LRAT checker in
  `reports/certificates/verify_all.sh` §3d, beside the Lake project's second executable
  `scripts/lratcheck/MainPad.lean` (`lratcheck_padded`; `Main.lean` unchanged). Untrusted preprocessing
  the checker judges (a defect can only cause a rejection), tested on its own in `tests.py`.
- **`reports/evidence/**/*.py`** (**29** files; was 28 before 2026-11-20, CX-37G-G; was 27 before 2026-11-17, CX-37G-F; under `c8screen/`, `f1/`, `f5/`, `f11/`, `qoy1_q992/`,
  `r11/`, `q374_se_replicates/`, `reports/evidence/q7_witnesses/`, `reports/evidence/q735_two_adic/` and `reports/evidence/tr12/`) — evidence instruments shipped and frozen
  alongside the results they produced. ⚠ **[CORRECTED 2026-09-04 — this read
  "11 files under `f1/`, `f5/`, `f11/`, `r11/`" and BOTH halves were stale.**
  Measured at the time of the correction, `git ls-files 'reports/evidence/**/*.py'`
  returned **12**, not 11, and the twelfth —
  `reports/evidence/q374_se_replicates/analyze.py` (first tracked 2026-09-03) —
  sits in a fifth directory this bullet did not name. The 2026-09-04 landing of
  `f5/f5_pair_only_fiber.py` and `f5/f5_pair_only_verify30.py` (the follow-up
  commit TR-1 §7 promised on 2026-07-26) takes it to 14. The prohibition this
  bullet expresses was never violated: the licensing clause is the **glob**
  `reports/evidence/**/*.py`, which covered `q374_se_replicates/analyze.py` all
  along — what drifted was the parenthetical inventory beside it, which is
  exactly the failure mode a filesystem-wired gate exists to catch and a
  string-keyed one cannot. Verify with
  `git ls-files 'reports/evidence/**/*.py' | wc -l`.]*

- Need a tool to parse an enumeration log? Add it as a subcommand in
  `solve.c` (e.g., `./solve --yield-report`), not a separate `analyze_yields.c`.
- Need a Python analysis utility? Add it as a subcommand in `solve.py`
  (e.g., `solve.py --compute-stats`, `solve.py --marginals`,
  `solve.py --bivariate`, `solve.py --joint-density`) — not a separate
  `scripts/compute_stats.py` or similar.
- Shell, markdown, binaries outside the two consolidated files are fine.

⚠ This block previously described the rule as admitting exactly one Python
exception. That was false when written against the tree: **20 `.py` and 2
`.c` files are tracked**, sixteen of the Python files covered by no clause of
the rule, and four of those sixteen are named elsewhere in this very file. An
agent obeying the old wording literally would have consolidated files that
exist precisely to be separate. Corrected 2026-09-02; the retired wording is
registered in
[RETRACTED_PHRASES.tsv](documentation/RETRACTED_PHRASES.tsv) and recorded in
[CORRECTIONS.md](documentation/CORRECTIONS.md).

Why: single source of truth, one compile target, one test matrix, no
dependency sprawl. The canonical source files are `solve.c` (enumeration,
sha-anchored), `solve.py` (analysis + ground truth), and `sat.py` (SAT/
certificate layer, operator-approved 2026-07-02; imports solve.py and must
contain no hand-written constraint *predicates* — rule predicates and constants
come from solve.py (except the two local gender-violation tests `viol_hex`/`viol_ex`, SAT_CLI.md; Codex FV-G4-C3#6), while the clause arithmetic that places them (station
offsets, gender stations) is sat.py's own and is tested, not derived: CX-232,
Codex LSD review row R7; see its header and SAT_CLI.md). They stay
that way; SAT work goes in `sat.py`, not new files.

**The INDEPENDENCE exception — `verify.py` and `verify.c` (operator-approved
2026-07-21).** Independent verifiers are the one category that *cannot* live in
the file they verify: a second opinion compiled into `solve.c`, sharing its
helpers and constants, is not a second opinion. So there is exactly **one
independent verifier per language**, and all future verification work goes
INTO them, never into new files:
- `verify.py` — independent Python verifier (records, `--recount`,
  `--check-certificate`). Imports nothing from solve.c/solve.py/roae.py/sat.py.
- `verify.c` — independent C verifier (plain non-quotient per-layer mass check).
  Same discipline: no solve.c header, no shared table, no copied constant — except the King Wen input
  table itself, the one deliberately shared datum, acknowledged in verify.c's INDEPENDENCE header.

This is a NARROW exception justified by purpose, not a general licence. It was
established after `verify_layers.c` was created and pushed without approval
(2026-07-21) — the same failure as `analyze_yields.c` in 2026-04-21. If you need
more C verification, extend `verify.c`; do not add a third file. The two directory-scoped
exceptions, each a separate-toolchain component: `viz/` (**three plotting
scripts, not one** — `visualize.py`, `growth_curve.py`, `report_figures.py`;
heavy plotting deps, listed individually above) and `lean/` (**a per-module directory, not one file** — the Lean 4 machine-checked theorem
modules + README; every file is inventoried in `lean/README.md` and checked independently by
`reports/certificates/verify_all.sh`. The one-file wording here was written 2026-07-03 when `lean/`
held exactly one file; the second and third landed 2026-07-04 and it is now fifteen
(`PruneReprFC.lean`, the repr(k) prune-safety theorem, landed 2026-08-15, took it to
thirteen; `SatEncodingFidelity.lean` landed 2026-08-31 and took it to fourteen; `CompilerCorrectness.lean` arrived on `main` with the `v4-query-program` merge `a19682b2` on 2026-09-04 and takes it to fifteen; `SuperspaceDivisibility.lean` landed 2026-11-20 and takes it to sixteen (CX-37G-G) —
`git ls-files 'lean/*.lean' | wc -l`, agreeing with `lean/README.md`). Per-module is
the RIGHT structure for Lean and is not to be consolidated: compile cost is PER FILE. The landed
kernel-`decide` `PruneGInvariance.lean` peaks at ~4.13 GB (lean/README.md, re-measured 2026-08-21; this said ~3.9 GB until 2026-11-03, Codex F12-019#3) (an earlier revision of this sentence
said "near 10.6 GB" — that WAS a real measurement, kept here for provenance, but of the REJECTED
one-liner migration route, the direct 48×64×64 kernel enumeration of `applyPerm_isometry`; the
shipped route proves the isometry structurally, and the 10.6 GB figure applies to nothing in the
tree). The merge rationale as previously stated was also wrong in mechanism: merging files would
NOT multiply peak memory — peak is set by the single most expensive `decide` obligation wherever
it lives — but it WOULD force every verification run to pay the worst module's wall-time and
memory cost and would destroy cheap partial verification (half the files check in ~1 s at
<0.7 GB precisely because they are separate; measured table in lean/README.md §"Verify
yourself"). Do not split a file further without a measured reason either).

Past violations:
- 2026-04-21: `analyze_yields.c` created as a separate file; user directive
  "i do not want new c files, i want them in solve.c" established the rule
  for C.
- 2026-04-21: `scripts/compute_stats.py`, `scripts/p2_marginals.py`,
  `scripts/p2_bivariate.py`, `scripts/p2_joint_density.py` developed as
  separate files during the P2 distributional-analysis sprint. Consolidated
  into `solve.py` on 2026-04-21 per user directive "consolidate all except
  viz/visualize.py"; `scripts/` subdirectory removed.

## Never commit to this repo

- `.claude/` — local Claude Code metadata
- `solutions.bin` itself — too large; the sha256 is the reproducibility
  anchor, not the bytes
- Outside-repo staging docs — those live in the private notes (a
  separate repository). If an operator-planning doc is in the
  working tree here, move it there.

## In-flight state

For "what am I currently doing / what's running / what's next," read
**the current-state file in the private notes** first — its lead `▶ RESUME HERE`
block carries the live campaign, supervisor pids, open operator decisions and
active hazards. It is rewritten in place as state changes; this CLAUDE.md is
stable. ⚠ **Read that lead block by offset, not the whole file.** Through
2026-09-18 this line called it "a short (~150-line) current-state file"; it is
**~8,300 lines** (8,305 measured 2026-09-18), so the old wording understated it
by ~55× and advised reading whole a file that no longer fits that advice.
Re-measure before quoting any figure here rather than refreshing this one.

**Do NOT read the plan history to orient.** It is the append-only history
behind that file and is now ~451 KiB (461,844 bytes, measured 2026-09-18 —
the "~416 KB" this line carried until then was stale) — reading it whole
costs ~100k tokens and
its lead block only duplicates the current-state file. Consult it for provenance
(why a past decision was made), never for current state, and read it by
targeted `grep`/offset rather than whole.

Also check scheduled wake-ups (the runtime fires these automatically
when 100T/analysis/validation jobs hit milestones — the wake prompt
itself contains the decision tree).

## Architecture

A small always-on orchestrator VM and separate, larger compute VMs. Managed
disks are region-locked, so moving data between regions needs a snapshot
copy. Sizes, regions and resource names are in the private operations notes.

**Bi-region architecture** was this section's heading until 2026-11-15, when
its text moved to the private operations notes.

## One-line rule of thumb

Changes to this file should themselves be rare. If you're tempted to
add something, first check if it belongs in a more topic-specific doc
— this file only earns entries for things that no other doc already
says, AND that Claude specifically needs loaded in context to do the
right thing.
