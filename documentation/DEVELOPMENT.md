# Development notes

Notes for anyone picking up this project — human or AI — who wants to reproduce
the results, extend the analysis, or continue the engineering work.

> **Access boundary.** This document cites operational files in `roae-private`, the project's
> private staging repository (runbooks, audits, bench protocols, design specs). It is not publicly
> accessible: those citations are provenance pointers, not material a reader can fetch, and a
> procedure or finding whose only cited support is a `roae-private` file is operator-attested.
> Everything needed to *build, test, and reproduce* the published results is in this repository;
> the private files carry operational detail (cloud runbooks, incident forensics) beyond that.

This is a *conventions* document, not a *reference*. Concrete technical details
live in:

- [solve.c](../solve.c) top-of-file comment — architecture, all run modes, bug
  history, build flags, environment variables.
- [HISTORY.md](HISTORY.md) — day-by-day project narrative, including missteps
  and the forensic trail that led to each correction.
- [SOLVE_SUMMARY.md](SOLVE_SUMMARY.md) — plain-language findings.
- [SPECIFICATION.md](SPECIFICATION.md) — formal constraint definitions.
- [CRITIQUE.md](CRITIQUE.md) — limitations, statistical caveats.
- [DEPLOYMENT.md](DEPLOYMENT.md) — cloud-VM deployment architecture + lessons.
- [enumeration/LEADERBOARD.md](../enumeration/LEADERBOARD.md) — current state of
  the enumeration.
- [SOLVE_C_CLI.md](SOLVE_C_CLI.md) — full `solve.c` command-line reference
  (subcommands, env vars, exit codes).
- [ROAE_PY_CLI.md](ROAE_PY_CLI.md) — full `roae.py` analysis-CLI reference.

---

## Build prerequisites

Measured on a clean Ubuntu 24.04 host, 2026-08-04, while executing the published reproduction
recipe end to end for the first time. The build line links `-lz` and `-fopenmp`, but no document
in this repository named the packages those need — a fresh machine failed at step one with
nothing here to explain why. That gap is what this section closes.

```
sudo apt-get install -y build-essential zlib1g-dev
```

- **`build-essential`** — `gcc` and the C toolchain (verified with gcc 13.3.0).
- **`zlib1g-dev`** — `zlib.h`. `solve.c` uses zlib natively for the per-block-gzip layer format;
  without the headers the compile fails at the first `#include <zlib.h>`.
- **OpenMP** — ships with gcc as `libgomp` on Debian/Ubuntu; no separate package.
- **`python3`** — for `tests.py`, `solve.py`, `roae.py`, `verify.py`. Stdlib only for the core
  solve / verify / test paths: `python3 tests.py`, `python3 roae.py`, `sat.py --emit-cnf`, and
  `verify.py`'s default and `--recount` legs need no third-party module (re-confirmed 2026-08-30
  by running them with numpy/pyarrow/pandas/scipy/sklearn/matplotlib blocked at import — 77 tests
  OK, 1 skipped). The **P2 population post-processing modes are not stdlib**: `solve.py
  --compute-stats`, `--marginals`, `--joint-density`, `--joint-density-v2`, `--bivariate`, and
  `verify.py --check-t5-c3` import numpy and pyarrow (plus scikit-learn for the KDE modes and
  matplotlib for `--bivariate`). On a machine with only the standard library installed, `--compute-stats` fails at once with
  `ModuleNotFoundError: No module named 'pyarrow'`. If you intend to run P2:

  ```
  pip install numpy pyarrow scikit-learn matplotlib
  ```

  *(This note used to warn that the deps row in [SOLVE_PY_CLI.md](SOLVE_PY_CLI.md)
  named `pandas/pyarrow/scipy`. That row was corrected in `98e4a81f` and now reads
  `numpy`/`pyarrow` for P2, `matplotlib` for `--bivariate`, `scikit-learn` for the
  KDE modes — matching the list above. Re-verified 2026-09-02: `pandas` and `scipy`
  are imported nowhere in `solve.py`, `verify.py`, `roae.py`, `sat.py` or `tests.py`.
  The warning is retired; the only remaining mentions of those two names in the repo
  are this paragraph and the import-blocking test method described above.)
- **Lean 4** (only for `lean/`) — via [elan](https://github.com/leanprover/elan). The pin is
  `lean/lean-toolchain` (`leanprover/lean4:v4.31.0`), and elan honours it only when `lean` is run
  from inside `lean/` (it resolves the toolchain from the working directory upward, not from the
  input file's path — measured 2026-09-03), so run modules as `cd lean && lean <Module>.lean`.
  `elan default leanprover/lean4:v4.31.0` is a convenience for running from elsewhere, not the pin;
  `reports/certificates/verify_all.sh` §4 runs from `lean/` and prints the kernel it used as
  `LEAN_ID=`. Memory matters:
  the heaviest files need ~10 GB free RAM to verify (an 8 GB host cannot check
  `lean/Automorphism.lean` or `lean/KingWen.lean`) — see the measured per-file wall/RSS table in
  [lean/README.md](../lean/README.md) §"Verify yourself" before running the Lean suite. *(These
  figures were re-confirmed against measurement 2026-08-07 after the final `native_decide` →
  kernel migration tranche: the two newly-migrated files peak below the pre-existing ceiling, so
  the requirement did not move.)*

Verified from a fresh clone on 2026-08-04: `--selftest` printed
`403f7202a33a9337b781f4ee17e497d5c0773c2656e16fa0db87eeccd6f3332e`, `python3 tests.py` ran 64 tests
OK (1 skipped), and `lean lean/KingWen.lean` exited 0 with no output — as recorded; NOTE 2026-09-03: run from the repo root, that command lets elan pick its *default* toolchain rather than `lean/lean-toolchain`, so the record attests a check under that host's default Lean, not specifically 4.31.0; the command to use is `cd lean && lean KingWen.lean`, and `verify_all.sh` §4 now prints the kernel it used as `LEAN_ID=`. (The harness has since grown:
as of 2026-09-02 it holds 133 tests — count re-verified by a local `python3 tests.py` run reporting
`Ran 133 tests in 95.920s … OK`; (the previous figures — 67 on 2026-08-06, 76 on 2026-08-21 (`Ran 76 tests in 24.329s … OK`), 77 on 2026-09-01, and 128 then 129 earlier on 2026-09-02 — were each correct when recorded and
drifted as tests were added — corrected 2026-08-21 after a cold reviewer pass flagged it, and again 2026-09-02 by re-measurement); the fresh-clone figures above are preserved as recorded on their date.)

Note that `documentation/REBUILD_FROM_SPEC.md` §Prerequisites is deliberately silent on all of the
above and should stay that way — it describes writing an independent verifier in *any* language,
and naming a C toolchain there would narrow it.

## Project conventions

### "Proven" language must be universal or explicitly scoped

Any claim calling something "proven" must be a universal/formal proof. If the
proof is scoped (e.g., a computational finite-case check over a specific
dataset), the scope must be stated explicitly in the same sentence.

- Universal: "proven"
- Scoped: "proven for the 742M dataset", "proven at 10T node budget",
  "exhaustively verified for all 4,495 three-subsets against the current
  dataset"
- Acceptable weaker alternatives: "exhaustively verified", "empirically
  confirmed", "no counterexamples found among N tested"

Same rule applies to synonyms: "theorem", "guaranteed", "verified formally".
These imply universality.

This convention emerged from the 2026-04-14 bug discovery: an earlier
"31.6 million unique orderings" figure was a ~23× undercount, but the bug was
deterministic so the sha256 reproduced. Claims couched as "proven" retrospectively
became "proven only under a specific bug." Explicit scoping prevents this.

### A reproducible sha256 is not a proof of correctness

Deterministic code that produces the same output on every run only proves that
the bug (if any) is reproducible. Output *shape* must also be cross-checked
against what the architecture predicts — record counts, file counts, expected
ratios. The sub-branch filename collision bug was invisible to sha-based audits
because the bug was deterministic. It was caught by `ls sub_*.bin | wc -l` (saw
47 files where the architecture predicted ~3030).

Always include at least one "does the output shape match the architecture"
check in any new analysis.

### Dataset-scope any quantitative claim

"742M unique orderings" is a lower bound for the 10T enumeration, not the true
count. Every per-sub-branch enumeration hit the per-sub-branch node budget
rather than completing naturally, so more solutions likely exist beyond the
enumerated space. When citing quantitative results, note the enumeration depth
(10T, 100T, etc.) and whether the budget was saturated.

### Asset preservation

- **Managed data disks are never deleted.** The persistent `solver-data` volume
  holds committed solver work (sub_*.bin files, solutions.bin). Between runs,
  VMs come and go; the data disk stays. On cleanup, delete the VM and its
  orphan OS disk, preserve the data disk.
- **sha256 files are committed but solutions.bin is excluded.** The multi-GB
  `solutions.bin` files live on the managed disk, not in the git repo. The
  authoritative registry of *live* reproduction shas is
  [CANONICAL_HASHES.md](CANONICAL_HASHES.md); per-run sidecars live at
  `runs/<date>_<scale>_<depth>_<runtag>/solutions.sha256`. Two committed
  sha files are **not** reproduction references: `enumeration/solutions.sha256`
  holds the invalidated 742M-era `aa141517…` (audit trail only — see
  §"Reproduce from scratch"), and every `runs/*10T_d3*/solutions.sha256`
  still records the deprecated `f7b8c4fb…`, superseded 2026-05-13 by
  `b85c8871…` (706,427,594 records, +4,607). Check any sha against
  CANONICAL_HASHES.md before treating it as a target.
- **Analysis outputs (text, small) are committed.** `enumeration/
  analyze_c_742M.txt`, `analyze_section14_742M.txt`, etc. serve as
  reproducibility references.

### Performance changes — empirical record required

Any commit modifying solve.c hot paths (DFS, prune predicates, hash-table
operations, merge inner loops, SIMD-vectorized arithmetic) or build flags
affecting per-thread rate must append an entry to
[PERFORMANCE_HISTORY.md](PERFORMANCE_HISTORY.md). The entry follows the schema
at the top of that file.

Standardized paired-bench harness lives at `scripts/perf_bench.sh`. It runs
control vs treatment on a single fresh Spot VM in westus3, runs a pure-CPU
preflight throttle probe on every core **and refuses to bench a host that does
not read `HEALTHY`** (teardown, exit 5), flushes the page cache between paired
runs **and verifies that the flush happened**, captures enum-only wall (merge
wall separately, not part of the speedup metric), takes `sha` and `records`
over the **decompressed** stream, and emits a JSON block that pastes directly
into a new entry. Multi-scale: 1B / 1T
/ 11.2T selectable via `--scale` — note the SKU is chosen **per scale**
(`Standard_D8als_v7` for 1B, `Standard_D128als_v7` for 1T and 11.2T,
`scripts/perf_bench.sh` `case "$SCALE"`), so a bench is comparable only to
another bench at the same scale. *(This paragraph previously said "a single
fresh D128als_v7 Spot" without qualification; corrected 2026-09-02 to match the
script and `PERFORMANCE_HISTORY.md` §"Standard bench harness".)*

> **Known harness defects — all cleared as of 2026-09-02.** The notes are kept
> because the paragraphs above them once told operators to install zlib by hand
> and to recompute the sha themselves, and both instructions are now wrong.
> Item 4 records the probe the 2026-08-30 audit found missing.
>
> 1. ~~**The provisioned VM cannot build.**~~ **CLEARED** — the install line now
>    reads `build-essential zlib1g-dev`, so the bench VM builds `solve.c`
>    (`#include <zlib.h>` at `solve.c:317`) without a manual step. Fixed
>    `bb0b7430`; this note is kept because the paragraph above it told operators
>    to install zlib by hand and that instruction is now wrong.
> 2. ~~**The JSON certifies a page-cache flush that may not have happened.**~~
>    **CLEARED 2026-09-02** — `"page_cache_flushed"` was an unconditional literal
>    `true` while the flush itself ended `|| true`. Each build now emits a
>    whole-line verdict token
>    (`PERFBENCH_PAGE_CACHE_FLUSHED_{N,U}=CONFIRMED|FAILED|UNVERIFIED`), the JSON
>    reports that status plus a detail string, and anything other than
>    `CONFIRMED` on both builds sets `"methodology_valid": false`, emits
>    `PERF_BENCH_METHODOLOGY=VIOLATED` and exits 3. A missing token reads
>    `UNVERIFIED`, not pass. Gate a caller with
>    `perf_bench.sh ... | grep -qx PERF_BENCH_METHODOLOGY=OK`.
> 3. ~~**STILL OPEN — its `sha` and `records` fields are container-level, not logical.**~~
>    **CLEARED 2026-09-02** — the script used to run `sha256sum solutions.bin`
>    and derive `records=(BYTES-32)/32` from the on-disk size; under the #169
>    gz-framed default (`SOLVE_COMPRESS` defaults ON) those were the sha of the
>    *compressed container* and a fictional record count, while every canonical
>    sha in [CANONICAL_HASHES.md](CANONICAL_HASHES.md) is taken on the
>    **decompressed** stream. It now sniffs the gzip magic and hashes and counts
>    over `gzip -dc solutions.bin` (`framing=gzip`), or the file itself when it
>    is raw (`framing=raw`); the container sha is still emitted, labelled
>    `container_sha`, and a failed decompression reports `sha=DECOMPRESS-FAILED`.
>    A harness `sha` in any entry dated before 2026-09-02 is a container sha and
>    is not comparable to an anchor.
> 4. **Preflight throttle probe — added 2026-09-02** (the 2026-08-30 audit found
>    the script carried only a comment referring to the rule). After the build
>    and before any bench: `yes > /dev/null` on every core for `--burn-seconds`
>    (default 60, floor 30), per-core MHz sampled at the end of the burn, minimum
>    must be `>= --throttle-min-mhz` (default 3664, the D128als_v7 precedent,
>    applied at every scale unless overridden). Verdict token
>    `PERFBENCH_THROTTLE_PROBE=HEALTHY|THROTTLED|UNVERIFIED` plus a
>    `PERFBENCH_THROTTLE_DETAIL=` line; anything but `HEALTHY` (including a
>    missing token or a burn under the floor) tears the VM down before the
>    bench, emits `PERF_BENCH_METHODOLOGY=VIOLATED` and exits 5. The JSON carries
>    `throttle_probe` / `throttle_probe_detail`, and `methodology_valid` requires
>    `HEALTHY` as well as both flushes `CONFIRMED`.
>
> The entry that PERFORMANCE_HISTORY.md identifies as the first produced by this
> harness (2026-05-18, task #78) predates #169 and is unaffected.

Why this matters: the project narrative — "v1 → v2 → v2+PGO speedup over time,
which changes mattered, which regressed" — is a presentation deliverable. Each
change's contribution (improvement OR regression) needs an empirical
measurement at ship time. Without uniform records, the cumulative-speedup
chart cannot be reconstructed honestly later.

The log captures regressions too: see the `#71 C2 lookahead` entry for the
canonical "instructive loss" example. Failed experiments are first-class
records, not omissions.

### Git hooks — opt-in, and they must be installed by hand

Hooks live in `.git/hooks`, which git does not track, so **cloning this repo
does not install them — and no commit can change that.** Git refuses by
design to auto-run code shipped in a clone, so one manual activation step
per clone is irreducible; the honest framing is a single documented command,
not a pretense of self-activation. This is that command (no `chmod` needed —
the symlink targets are tracked with their exec bit):

```sh
ln -sf ../../scripts/pre_push_gate.sh .git/hooks/pre-push && ln -sf ../../scripts/pre_commit_gate.sh .git/hooks/pre-commit
```

Each hook is a **dispatcher** script under `scripts/` that runs every gate
belonging to that hook point — install the dispatcher, never a single gate
directly, because a bare symlink to one gate silently disables the others
(this section documented exactly that bare-symlink install for `pre-commit`
until 2026-08-06, while the working checkout ran a dispatcher that existed
only as an untracked file; both defects are fixed by the tracked
dispatchers).

Why symlinks rather than `git config core.hooksPath hooks`: `.git/hooks` is
in the repo's *common* git dir, so the symlinked hooks also fire for commits
made from every linked worktree (`git worktree add` checkouts, which this
project uses for pinned campaign trees). A relative `core.hooksPath`
resolves against each worktree's own root and would silently run **no hooks
at all** in any worktree whose checkout predates a tracked `hooks/`
directory. Do not "upgrade" to `core.hooksPath` without re-deriving that
trade-off.

| hook | dispatcher runs | blocks on |
|---|---|---|
| `pre-push` | for **each pushed sha**, in a temporary detached worktree of that sha: the pushed tree's own `doc_gates.sh all` (~12–20 s), then its `pre_push_compile_gate.sh` (~56 s), and — when `needs_generated()` says the pushed range touches `roae.py`/`example/`, or the base cannot be determined — `doc_gates.sh generated` (~67 s). All three always run, findings aggregate; worktree add+remove ≈0.5 s; deletion pushes gate nothing | any hard doc gate red (the blocking set is the PASS banner in `doc_gates.sh`; its report-only gates print `[WARN]`/`[note]` without blocking), or `solve.c` missing/empty, gcc non-zero, `--selftest` not producing sha `403f7202…`, or a pushed tree with **no gate scripts at all** (deliberate pushes of pre-gate history use `--no-verify`, visibly) |
| `pre-commit` | `pre_commit_registry_gate.sh` (WARN-only; full 6-gate scan when a registry/ledger file is staged, the two cheap retraction scans when any `reports/*.md`, `documentation/*.md` or `README.md` is staged), then `pre_commit_generated_gate.sh` (blocking) | a commit touching `roae.py` or any `example/` artifact whose `doc_gates.sh generated` check fails |

**Pre-commit rc contract (2026-09-02, route C6).** The dispatcher reads **three** verdicts from
`pre_commit_registry_gate.sh`, not two: rc `0` = CLEAN or NOT-APPLICABLE, rc `1` = FINDINGS, rc `2` =
COULD-NOT-RUN; anything else (127 = the gate script is missing or unexecutable, ≥128 = signal) is
classified as "could not look", never defaulted to findings. Each gate also prints one whole-line
token at column 0 for `grep -qx` — `PRECOMMIT_REGISTRY=CLEAN | FINDINGS | COULD-NOT-RUN |
NOT-APPLICABLE | REFUSED-DIRTY` and `PRECOMMIT_GENERATED=CLEAN | FINDINGS | COULD-NOT-RUN` — and the
verdict is that token, never inferred from the shape of the text above it. The WARN-only disposition of
the registry gate is unchanged; the contract exists so that "the gate found nothing" and "the gate never
ran" are distinguishable downstream. They were not on 2026-09-02, when a mid-edit `doc_gates.sh` made
every leg return 2 and the dispatcher reported it as findings over a commit staging the two files those
gates exist to police.

**The pre-push hook gates the committed trees being published, not the
working tree** (task #150). The 218-commit replay (task #149) found 12
commits whose committed trees failed their own gates — four pushed, red in
public for ~2.5 days — every one invisible to a working-tree hook because
the defect was fixed (or not yet present) in uncommitted edits. The hook
therefore replays each pushed sha in a throwaway detached worktree, removed
on every exit path including failure and interrupt. A fix that exists only
as an uncommitted edit does **not** clear the push gate: commit it first.

*Corrected 2026-08-08 (adversarial sweep).* This paragraph described `doc_gates.sh
generated` as *"deliberately **not** in the pre-push dispatcher"* with the residual
`--no-verify` hole *"accepted"*. **Both statements were superseded the day after they
were written and are no longer true.** Since `3f480689` (2026-08-07) the pre-push
dispatcher carries a **third, blocking, fail-closed leg**: `needs_generated()`
(`scripts/pre_push_gate.sh:125-132`) decides per-sha whether the pushed range touches
`roae.py` or `example/`, and if so runs `doc_gates.sh generated` in the pushed sha's
own worktree (`:219-228`). It is **required on four paths, not merely "when there is a
base"** — base empty, base all-zeros, base commit absent locally, or the diff erroring
— so the fail-closed direction is preserved when the range cannot be determined.
Cost is **~67 s measured 2026-08-07** (the ~107 s figure above is the 2026-08-06
measurement and is superseded).

**Why this went stale, since it is the instructive part:** the commit that ADDED the
two-leg dispatcher also authored this paragraph, and the commit that added the third
leg touched four files — none of them this one. A doc that describes a mechanism is
not updated by the commit that changes the mechanism unless something forces it. A
case-insensitive search of this file for `needs_generated`, `third leg`, `GATE 8` or
`67 s` returned **zero** before this correction.

The pre-push hook and the pre-commit **generated** gate fail **closed**: a
false stop costs one retry, a false pass ships a compile error or a
hand-edited artifact into the published record. The pre-commit **registry**
gate is the deliberate exception — WARN-only, blocking nothing; §"Gate
verdicts" below says why, and what its exit status does and does not mean. Neither has
a private `SKIP=1` escape hatch, because an env-var bypass is how a gate
quietly stops running — `git push --no-verify` / `git commit --no-verify`
already exist and leave the decision visible in shell history.

The pre-commit gate exists because hand-editing generated output has happened
**three times** (`example/report.html` at `dbba77d` was caught by the operator,
not by a gate). `doc_gates.sh` could always detect it; nothing forced it to
run. **Read its header before trusting it** — but the caveat this paragraph
carried is now closed. It read: for `report.txt`, `report.md` and `README.md`
the underlying gate compares non-numeric lines only, because `roae.py` seeds
nothing by default, so a hand-edited *digit* in `example/report.txt` is caught
by nothing; closing that hole means shipping `example/` generated with
`--seed`, which changes published artifacts and is an operator decision. **That
decision was taken on 2026-09-04.** `example/` is regenerated and shipped under
`--seed 20260904`, GATE 8 regenerates under the same seed, and all eleven
tracked artifacts are compared **byte-exact, digits included** — see
[ROAE_PY_CLI.md §REPRODUCING `example/` BYTE-FOR-BYTE](ROAE_PY_CLI.md#reproducing-example-byte-for-byte).
The price is that every number in `example/` is now one fixed draw rather than
a fresh sample; no claim depends on those figures, and the reports print the
seed into themselves so a reader can tell.

#### Gate verdicts: three states, not two (reworked 2026-09-02, `0414d072`)

A crashed gate and a gate with findings are different answers, and until
2026-09-02 the pre-commit dispatcher printed the second when it had received
the first. Reproduced on unmodified HEAD: another unit was mid-edit on
`scripts/doc_gates.sh`, `bash` could not parse it, all six registry legs
returned 2, and the hook announced `registry gate reported findings (rc=1) -
WARN ONLY, commit proceeds` — on a commit staging `RETRACTED_PHRASES.tsv` and
`CORRECTIONS.md`, the two files GATE 3 and GATE 11 exist to police. Nothing
had been checked. The states now have separate words and separate statuses.

**Read the verdict from the token, never from the shape of the text.** Every
terminal path of both pre-commit gates prints a whole-line `KEY=value` token
at column 0, so `grep -qx` is the correct reader:

| token | values |
|---|---|
| `PRECOMMIT_REGISTRY=` | `CLEAN` · `FINDINGS` · `COULD-NOT-RUN` · `NOT-APPLICABLE` · `REFUSED-DIRTY` |
| `PRECOMMIT_GENERATED=` | `CLEAN` · `FINDINGS` · `COULD-NOT-RUN` |

**Return codes are NOT uniform across the two gates, and the difference is
deliberate.** `pre_commit_registry_gate.sh` implements the three-state
contract declared in its own header — `0` = CLEAN **or** NOT-APPLICABLE, `1`
= FINDINGS, `2` = COULD-NOT-RUN, with `REFUSED-DIRTY` (index and working tree
disagree on a watched path, so the gates would inspect bytes the commit does
not contain) also exiting `2`, because that is "not measured", not "found
something". `pre_commit_generated_gate.sh` does **not** carry a `2`: it is a
blocking gate, so CLEAN exits `0` and *everything else* — FINDINGS,
missing `doc_gates.sh`, unparseable `doc_gates.sh`, an inner gate that
exited neither 0 nor 1 — exits `1`. Its token still separates the three
states even though its status does not. If you are scripting on the
generated gate, `grep -qx 'PRECOMMIT_GENERATED=COULD-NOT-RUN'` is the only
way to tell a crash from a finding; the exit status cannot.

`pre_commit_gate.sh` is the dispatcher and does no checking of its own. It
classifies the registry gate's status (`0` silent, `1` "reported FINDINGS",
**anything else** — 2, 126/127 from exec, ≥128 from a signal — the loud
"COULD NOT RUN … it reported NOTHING") and then `exec`s the generated gate,
whose status becomes the hook's.

🔴 **WARN-ONLY IS UNCHANGED. This rework did not make anything block.** The
registry gate still cannot refuse a commit — not on FINDINGS and not on
COULD-NOT-RUN — per operator ruling O-redfloor: a hook that refuses a red
commit also stops a unit committing to protect its work from another unit's
`git checkout -- .`, which has destroyed uncommitted work four times. What
changed is *classification*: "I could not look" now has its own words and its
own exit status, so the two states are no longer indistinguishable
downstream. A COULD-NOT-RUN commit proceeds — and must not be recorded as
gated. Re-run `bash scripts/pre_commit_registry_gate.sh` once `bash -n
scripts/doc_gates.sh` is quiet, and read *that* result.

Both gates run `bash -n scripts/doc_gates.sh` **before** dispatch, which is
the check the failure above needed and did not have: a file that does not
parse cannot have an opinion, and asking it for one costs six subshells that
all return 2 and read as six failing gates. Measured 2026-09-02: 11 ms,
against ~4.4 s for the six registry legs and ~62 s for the generated gate.

The same class was swept through `pre_push_gate.sh` in the same commit — its
branch-registry leg, its `doc_gates.sh all` leg and its conditional
`doc_gates.sh generated` leg each now distinguish "exited neither 0 nor 1"
from "found something" in their message text. **The pre-push hook emits no
`PREPUSH_*` token and its return codes did not change**: every one of those
legs was blocking before and is blocking after, so only the wording moved.
Do not write a `grep -qx` reader against the pre-push hook expecting one.



### `doc_gates.sh emitted-surface` (GATE 89) — the emitted-name census

Every gate in the code→documentation presence family looks at an **input**
surface: GATE 2 (`cli`) the flag names, GATE 2c (`citation-lines`) the
`solve.c:NNNNN` citations, GATE 24 (`value-domains`) a declared value
registry, GATE 84 (`env-surface`) the `getenv("SOLVE_*")` names. GATE 89
looks at what the programs **print**, which nothing did before 2026-09-08:

* **LEG 1 — JSON keys.** Every distinct key literal `solve.c` prints inside a
  JSON object must be named somewhere under `documentation/`.
* **LEG 2 — verdict tokens.** Every distinct whole-line `KEY=value` token that
  `solve.c` or a `scripts/*.sh` gate prints — the lines callers match with
  `grep -qx` — must be named somewhere under `documentation/`.
* **LEG 3 — `solve.py` JSON keys.** `solve.py` builds its payloads as dicts
  assembled across many statements, so a literal scrape of it would be partial
  and *silently* so. LEG 3 is therefore an `ast` pass: it resolves the
  expression flowing into every `json.dump`/`json.dumps` call through dict
  literals, `**` unpacking, `.update()`, subscript assignment, dict
  comprehensions with a literal key, `dict(...)`, if-expressions, containers and
  comprehensions, name binding along the scope chain, the return expressions of
  a function defined in the same file, and one level of parameter
  back-resolution from that function's call sites. It does **not** model
  attribute or element types, does not element-type an iterable, and does not
  enter an imported callable. Every position it cannot resolve is **counted and
  printed with its site**, never dropped, so the key census is honest about
  being a lower bound; that count is ratcheted, and a rise fails the gate.

The corpus is `documentation/` **only**, and every `documentation/DOC_GATE_*`
file is excluded from it, so neither the gate's own allowance table nor an
emitting script's own header comment can absolve its own subject. It runs inside
`all`, and also by name:

```sh
bash scripts/doc_gates.sh emitted-surface
```

It is hard for **newly** undocumented names only. The pre-existing census is
carried in `documentation/DOC_GATE_EMITTED_SURFACE_OPEN.tsv`, whose rows print
`[OPEN]` and do not set the exit code; an allowance row that matches nothing
fails, so a row cannot outlive its fix.

**Verdict tokens this gate emits** (whole line, read them with `grep -qx`,
never on output shape). Each count is `-1` when nothing was measured:

| token | meaning |
|---|---|
| `DOC_GATE_EMITTED_SURFACE` | `OK` \| `FAIL` \| `ERROR` — the gate's verdict. `ERROR` means it could not judge its subject (unreadable input, a population below its floor, a failed closure proof), never that the tree is clean |
| `DOC_GATE_EMITTED_SURFACE_JSON_KEYS` | distinct JSON keys extracted from `solve.c` |
| `DOC_GATE_EMITTED_SURFACE_TOKENS` | distinct `KEY=value` verdict tokens extracted from `solve.c` and `scripts/*.sh` |
| `DOC_GATE_EMITTED_SURFACE_NEW` | undocumented names that are **not** in the allowance table — this is what sets the exit code |
| `DOC_GATE_EMITTED_SURFACE_OPEN` | undocumented names carried as adjudicated-open rows |
| `DOC_GATE_EMITTED_SURFACE_DROPPED` | emitted lines rejected as shell-fragment generation rather than verdicts (`echo 'WORK=$(mktemp -d); RAW=...'`) |
| `DOC_GATE_EMITTED_SURFACE_PY_JSON_KEYS` | distinct JSON keys the LEG 3 `ast` pass resolved out of `solve.py` |
| `DOC_GATE_EMITTED_SURFACE_PY_NEW` | LEG 3 undocumented keys that are **not** in the allowance table — this also sets the exit code |
| `DOC_GATE_EMITTED_SURFACE_PY_OPEN` | LEG 3 undocumented keys carried as adjudicated-open rows |
| `DOC_GATE_EMITTED_SURFACE_PY_UNRESOLVED` | positions the LEG 3 pass could **not** resolve. Non-zero means the key count above is a lower bound, never that `solve.py` emits nothing; each one is printed with its site |

LEG 3 reports through its own `PY_` counters rather than widening `JSON_KEYS`,
`NEW` and `OPEN`. Those three are pinned numbers other lanes read, and a count
that silently changes what it counts is the same class of defect as an emitted
key no document names. The `DOC_GATE_EMITTED_SURFACE` verdict covers all three
legs, so it — not any single count — is the thing to gate on.


### `gate_published_consistency.sh` — the `PUBLISHED_CONSISTENCY` token

`scripts/gate_published_consistency.sh` is the published-consistency **ratchet**: nineteen legs
(`G1`…`G19`) over the cross-document drift classes that dominated v3 lens B's surviving yield — a
claim that stopped being true when a sibling document moved. It is run from the pushed tree by
`scripts/pre_push_gate.sh`, which reads its verdict with `grep -qx` at three places, so this token
gates every push and is worth knowing exactly.

Each leg produces a **count**, and each count is compared against a pinned value in
`scripts/gate_published_consistency.pin`. The pin file is not a list of acceptable defects; it is
a list of known-open ones, each with a written reason. Fifteen stood on the day the gate was
written, which is why the verdict is a ratchet rather than an absolute — a gate that printed
`FAIL` on every push would be bypassed within a week.

| value | fires when | what the pushing lane should do |
|---|---|---|
| `PUBLISHED_CONSISTENCY=FAIL` | any leg's count **rose above** its pin — a *new* published-consistency defect — **or** the pin file is missing, unreadable, or has a malformed/absent `G<n>` entry | blocked. Fix the drift, or re-pin in the same commit with the reason written down. An unpinned ratchet certifies nothing, which is why a missing pin is `FAIL` and not a skip |
| `PUBLISHED_CONSISTENCY=PASS-AT-PIN` | no count rose, but **at least one of the nineteen legs has a non-zero count** | **accepted by `pre_push_gate.sh`, and deliberately so.** It means "no regression; known-open items stand". The gate prints an `OUTSTANDING:` line naming exactly which legs and at what counts, and `pre_push_gate.sh` echoes it into the push log. This is the live verdict on the current tree |
| `PUBLISHED_CONSISTENCY=PASS` | no count rose and **every one of the nineteen legs measured zero** | tighten any non-zero pin to zero in this same commit — a budget resting on repaired defects is headroom for new ones |

🔴 **`grep -qx`, never a substring test.** `PASS` is a prefix of `PASS-AT-PIN`, so
`grep -q PUBLISHED_CONSISTENCY=PASS` matches both and silently converts "fifteen known defects
stand" into "clean". `pre_push_gate.sh` tests the three values in the order `FAIL`,
`PASS-AT-PIN`, `PASS`, each with `grep -qx`, and treats *no token at all* as a failure — a gate
that cannot report is not a gate that passed.

🔴 **The exit code is not the verdict.** The script exits **0** on all three values; only the
pin-file errors exit **1**. Read the token, not `$?`.

🔴 **`PASS` means every leg measured zero — the boundary was corrected on 2026-09-08, and what it
used to be is worth knowing.** The flag separating `PASS` from `PASS-AT-PIN` used to be an internal
`fail` variable that only the `G1`–`G4` legs and the disclosure-registry checks ever set; `G5`–`G19`
reached the verdict through the ratchet alone, so a `G5`–`G19` count sitting **at** a non-zero pin
did not stop the script printing `PASS`. Measured before the change, on a tree with `G1`–`G4` clean
and the other fifteen legs each at a pinned `1`: the script emitted `PASS` while fifteen legs
printed `[FAIL]`, every one of them saying *"this leg measured NOTHING"*. The boundary is now "any
leg non-zero", which is what the script's own comment always claimed it was.

This cost nothing at the push gate and did not drain the distinction. `pre_push_gate.sh` accepts
`PASS` and `PASS-AT-PIN` alike, so the only verdict that can newly appear where `PASS` stood is the
strictly more honest one — no push that used to succeed now fails. And `PASS` remains **reachable**:
it is emitted exactly when all nineteen counts are zero, verified on a purpose-built clean tree.
The live verdict is unchanged at `PASS-AT-PIN` (`G1:5 G2:10 G4:8 G10:1`).

🔴 **The verdict names its own open legs.** Immediately above the token the gate prints either
`OUTSTANDING: N of 19 leg(s) non-zero — G1:5 G2:10 …` or `OUTSTANDING: none — all 19 legs measured
zero.` (colons, not `=`, so these are not mistaken for emitted verdict tokens). Quote that line
alongside the token; a bare `PASS-AT-PIN` does not say how much is open, and this one does.

🔴 **The gate checks its own wiring.** Each leg's count must reach the ratchet, and twice it has not:
`G5`–`G16` were assigned and never read (fixed 2026-09-07), and `G3_N` was read and never assigned
(fixed 2026-09-08 — its ratchet had been comparing `0` against a pinned `0`, and `G3_N=7 bash …`
from the *environment* reached the ratchet unchallenged). Two guards now make that class
self-detecting rather than audit-detected: a leg that prints a finding while every count is zero
emits `FAIL`, and the ratchet reads each count as a bare `$G<n>` with **no `${…:-0}` default**, so a
leg whose count is never assigned aborts under `set -u` with no verdict token at all — which
`pre_push_gate.sh` treats as "could not run" and blocks. Do not add a default back.


### `scripts/exec_lane.sh` — the `EXEC_LANE_*` tokens

The execution lane extracts every command-shaped line from the tracked `*.md`
corpus and runs the executable ones verbatim, serially, in a scratch copy of
the tree under a **default** environment (soft stack limit 8 MB, no special
flags). Its whole-line tokens are the machine-readable half of that report;
read every one with `grep -qx`, never as a substring.

| token | what it counts, and what it asserts |
|---|---|
| `EXEC_LANE` | `PASS` when no **gating** failure was recorded, `FAIL` when `EXEC_LANE_FAIL` is above zero, `ERROR` when the lane could not measure at all — the extractor crashed, zero commands were extracted, the MEASURED leg could not run, or that leg printed no count. All three are whole-line on **stdout** and a whole-line grep(1) match (`-qx`)-able. Until 2026-09-08 the `ERROR` form carried its reason on the verdict line *and* went to stderr, so a caller reading stdout saw no `EXEC_LANE=` line at all; the reason is now `EXEC_LANE_ERROR=<cause>` on its own line and the prose sits above it. A caller that still sees no `EXEC_LANE=` line must read that as "the lane did not run", never as a pass |
| `EXEC_LANE_ERROR` | emitted only alongside `EXEC_LANE=ERROR`, naming which of the four could-not-measure conditions fired: `extractor-failed`, `zero-commands-extracted`, `measured-leg-could-not-run`, `measured-leg-no-count`. The extractor's own `rc` stays in the prose line above it |
| `EXEC_LANE_EXTRACTED` | commands the extractor pulled out of the corpus — fenced blocks, `Reproduce:` paragraphs and inline backtick spans. This is the size of the inventory, not the number executed, and under `--list` it is emitted alone alongside `EXEC_LANE_SCOPE=LIST-ONLY`. That it is a function of the corpus and **not** of the process working directory is what `exec_lane_verdict_gate.sh` leg D asserts |
| `EXEC_LANE_RUN` | commands actually executed: the BUILD lines (always, even under `--only`) plus the RUN commands surviving the `--only` filter. Always below `EXEC_LANE_EXTRACTED` — pre-classified `SKIP-OPS` and `SKIP-PLACEHOLDER` rows are printed but never run |
| `EXEC_LANE_PASS` | executed commands whose outcome class was `PASS`: exit 0, or one of the adjudicated non-zero passes — the grep(1) family exit 1 with no error/usage text (no-match is a documented result), diff(1)/cmp(1) exit 1 where the surrounding doc context says the inputs differ, a refusal naming a prerequisite that same document states earlier, or a command a correction note says fails and which did fail |
| `EXEC_LANE_FAIL` | **gating** failures, and the only count that sets the verdict. It covers crashes (SIGSEGV), a build or link line that did not build, an unexplained nonzero exit, a diff(1) that differed where the doc promised identical bytes, a refusal naming a prerequisite the doc does **not** state, every unbounded invocation counted by `EXEC_LANE_UNBOUNDED`, and every unresolved MEASURED figure |
| `EXEC_LANE_FAIL_NONGATING` | the same failure classes, but sourced from a document that narrates a **past** run (`documentation/HISTORY.md`, `documentation/PERFORMANCE_HISTORY.md`, `runs/`, `enumeration/`) or from the operator file `CLAUDE.md`. Executed and reported, deliberately not gating: a command that ran in April is not a present-tense claim that it runs today |
| `EXEC_LANE_SKIP` | non-verdicts — MISSING-TOOL, MISSING-INPUT, BUDGET, RESOURCE, PLACEHOLDER, OPS, DIFF-UNSTATED and FRAGMENT outcomes together, plus the two pre-classified skip classes. 🔴 The four counts below are **sub-counts of this one, not additions to it**: a `SKIP-DIFF-UNSTATED` row increments both `EXEC_LANE_SKIP` and `EXEC_LANE_DIFF_UNSTATED`, so the counts do not sum to `EXEC_LANE_RUN` |
| `EXEC_LANE_FRAGMENT` | inline prose mentions that turned out not to be complete commands — the run produced a usage-error shape and the mention came from an inline backtick span rather than a fenced block |
| `EXEC_LANE_FRAGMENT_UNJUSTIFIED` | the subset of `EXEC_LANE_FRAGMENT` for which the corpus publishes **no** complete form of the same command anywhere, so the only invocation a reader has is the one that did not run. Non-gating by default and **this is the number to watch**; `EXEC_LANE_STRICT_FRAGMENT=1` promotes the ones from gating documents to `FAIL` |
| `EXEC_LANE_UNDOC_DEP` | commands that died on `ModuleNotFoundError` for a Python module the source document never names. These are gating FAILs, counted separately so the exemption's blast radius is a number rather than a guess — when the document **does** name the module the identical failure is a `SKIP-MISSING-TOOL` instead |
| `EXEC_LANE_DIFF_UNSTATED` | diff(1)/cmp(1) invocations that exited 1 (the inputs differ) where nothing in the doc context says whether that was expected. Skips, not verdicts, and each one is printed with its source so the exemption cannot hide a real mismatch |
| `EXEC_LANE_BUILD_MISSING_SOURCE` | BUILD lines that could not find a source, header or tool their compile line names. For a BUILD line this is a `FAIL` and not the `SKIP-MISSING-INPUT` a RUN line would get: a compile recipe naming a file the tree does not ship is precisely the defect this lane exists to find |
| `EXEC_LANE_UNBOUNDED` | gating rows classed `FAIL-UNBOUNDED` — a `--branch`/`--sub-branch` invocation, or the bare full-enum form, with no `SOLVE_*_LIMIT` and a `time_limit` of `0`. They are counted and **never executed**, because running one does not return, and they are FAILs by policy rather than skips: a skip here is the could-not-fail shape. Each also raises `EXEC_LANE_FAIL` |


### `scripts/exec_lane_verdict_gate.sh` — the `EXEC_LANE_VERDICT_GATE*` and `EXEC_LANE_CWD_INVARIANT` tokens

This gate does not re-implement the lane's classifier — a copied predicate
passes while the shipped one rots. It **extracts** the real decision text out
of `scripts/exec_lane.sh` (the classifier if/elif chain, and
`unbounded_branch()`), evaluates that under controlled inputs, and runs the
lane's own `--list` from two different working directories.

| token | what it asserts |
|---|---|
| `EXEC_LANE_VERDICT_GATE` | `PASS` every case measured behaved as expected; `FAIL` at least one case measured a wrong verdict; `ERROR` it could not measure at all — the lane file is missing, an extraction failed, `--list` failed, or a leg ran zero cases. 🔴 `ERROR` is not a pass; a check that silently measures nothing is the same could-not-fail shape the gate exists to catch |
| `EXEC_LANE_VERDICT_GATE_CASES` | cases measured across the legs. Zero is reported as `ERROR`, never as a pass |
| `EXEC_LANE_VERDICT_GATE_BAD` | cases that measured a **wrong** verdict. It is not printed on the `ERROR` path (where `_CASES` appears alone), so read it only next to a `PASS` or `FAIL` verdict |
| `EXEC_LANE_CWD_INVARIANT` | the cwd leg alone, so the invariant can be asserted without running the whole gate. `PASS` when `exec_lane.sh` with `--list` yields the same non-empty inventory — same count **and** identical line for line — from the repo root and from a scratch directory; `FAIL` when the counts differ or the inventories differ row by row; `ERROR` when either listing could not be produced, or when both extracted zero commands, because two zeros are equal too and that equality proves nothing. The defect it pins: `shutil.which()` on a slash-bearing token abandons `PATH` and resolves against the process cwd, which made every repo-relative published command visible only when the lane was launched from the repo root — measured 2026-09-08 as 1,137 extracted rows from the root against 1,119 from `/tmp`, 16 of the 18 gating RUN rows, so the lane's own verdict was a function of an invisible input |


### `scripts/selftest_resume_167_gate.sh` — the `RESUME_167_*` tokens

`solve --selftest-resume` is blind to the #167 zero-yield resume fix in both
directions: the fixed binary and the pre-fix baseline pass it byte-identically.
The guard's `[#167-guard]` lines are written into tempdirs the driver deletes
before returning, and the verdict is a sha comparison while the fix changes
**work, not output**. This gate re-runs the same three-phase shape but keeps
the artifacts, and decides on four quantities — three of which the guard under
test does not produce, so the verifier takes no witness from its own closure.
Every token is emitted on **every** exit path, `VACUOUS` and `ERROR` included,
and each reads `-1` when the run could not derive it.

| token | how it is derived, and what it discriminates |
|---|---|
| `RESUME_167_SIDECARS` | S — `sub_*.dfs_state` checkpoint sidecars in PHASE_A's directory, counted from the **filesystem** with `find` (never a glob), after any mutation and before PHASE_B runs. This is the state PHASE_B's guard will actually see |
| `RESUME_167_ZERO_YIELD_CELLS` | Z — of those sidecars, the ones with **no** matching `sub_*.bin` shard: the cells that checkpointed having found nothing. Z is the population the #167 path exists for, and `Z == 0` is reported `VACUOUS` (rc 42), never `PASS` — the path could not be exercised at that shape. Z is re-measured every run and pinned to no constant, because it moves with the PHASE_A budget |
| `RESUME_167_RESUMED` | R — `checkpoint ATTESTS zero yield` lines counted out of `phase_b.log` before anything is deleted: cells the guard resumed. `R + D == 0` with `Z > 0` is `VACUOUS`, not `PASS`; a guard that was never reached has attested nothing |
| `RESUME_167_DISCARDED` | D — `discarding resume, walking cell fresh` lines from the same log: cells the guard threw away and re-walked. Every discard variant ends in that phrase. The verdict rule is exact — `R != Z` or `D != 0` is a `FAIL` (rc 40): attested zero-yield cells re-walked, or unattested cells resumed |
| `RESUME_167_NODES_A` | nodes summed over PHASE_A's own checkpoint lines. PHASE_B **appends** to PHASE_A's `checkpoint_t*.txt` files, so the two runs are separated by each line's trailing `budget N` suffix, and the gate errors rather than guesses if the two budgets cannot be isolated as distinct |
| `RESUME_167_NODES_B` | the same sum over the PHASE_B (resume) lines, selected by the PHASE_B budget suffix |
| `RESUME_167_NODES_SINGLE` | the same sum for the single-shot control run at the final budget in a fresh directory |
| `RESUME_167_EXCESS_NODES` | EXCESS = nodes_A + nodes_B − nodes_single: work the resumed pair did that the single-shot run did not. This is the second, independent witness that the resume **saved** the work it claims, and it is a per-run delta, which is why it discriminates where the sidecar's cumulative `prior_nodes_walked` cannot. `EXCESS >= Z * budget_A / 2` is a `FAIL`. Measured 2026-09-05 at the pinned shape: 3,030 for the fixed binary (one node per resumed cell — the captured frame's ENTER counted once by each phase) against 31,897,530 for the pre-fix one (exactly Z × budget_A, every zero-yield cell re-walking its whole PHASE_A budget) |
| `RESUME_167_MUTANTS_KILLED` | `--battery` only, and printed as `<killed>/<total>`, not a bare integer — a reader parsing it as a number gets the numerator. A mutant counts as killed only when the gate reached the **expected verdict for the expected reason**, the counts asserted as well as the verdict. The seven are M0 unmutated (expect `PASS`), M1 PHASE_B run by the pre-fix binary (`FAIL`, R=0 D=Z), M2 every shard-less sidecar removed (`VACUOUS` by the Z rule), M3 and M4 one zero-yield sidecar's attestation bytes cleared or falsified (`FAIL`, R=Z−1 D=1), M5 one productive shard removed (`FAIL` with the sha still equal), M6 the guard's lines stripped from the log (`VACUOUS` by the R+D rule). M2 and M6 are the two that matter — they are the "passed means never looked" cases, and unaugmented `--selftest-resume` passes both |
| `SELFTEST_RESUME_167_BATTERY` | `PASS` only when every mutant was killed **and** no mutant survived; `FAIL` otherwise (exit 40). It is emitted only in `--battery` mode; a single run emits `SELFTEST_RESUME_167` instead, and the two must not be confused by a caller |


### Standalone gate verdict tokens — the one-line reference

Most checks in `scripts/` are not part of `doc_gates.sh`: they are single-defect
gates, each printing one whole-line `KEY=value` verdict. A reader who meets one
of these in a log has to be able to look it up, so every one of them is named
here with what it actually asserts and what its values mean.

🔴 **Two conventions that are easy to get wrong.** (1) `ERROR` — "I could not
measure" — is never a pass; several of these gates were written specifically
because a check that measures nothing had been reading as a clean tree.
(2) Every verdict line in this table is whole-line matchable, and `grep -qx
'KEY=OK'` is how to read it. That became true on **2026-09-08**: seven of these
tokens used to carry trailing detail on the verdict line — counts, an error
cause — so the `grep -qx` their own headers promised could never match them. The
detail did not go away; it moved to its own line, or to a companion
`KEY_SOMETHING=value` token that is itself whole-line. Treat the absence of any
`KEY=` line as "did not run", never as a pass. A row that is genuinely not
whole-line matchable is flagged **[suffixed]**; there are none left in this
table, and adding one is a defect, not a style.

| token | emitter | values, and what the verdict rests on |
|---|---|---|
| `A2_SLOT_VERDICT` | `a2_slot_verdict_gate.sh` | `OK` \| `FAIL` \| `ERROR`. Pins the atlas's per-pair A2 slot check against the pair-slot convention published in `viz/viz_kc_field.md` — layer *k* fills pair-slot *k*+2 — which the gate re-reads rather than hardcoding, and pins the four sibling verdicts (`TR12_Q10A`, `TR12_XA_A`, `TR12_XA_B`, `TR12_XA_MOD24`) that were literal `PASS` strings or presence-only tests. A fixture that does not reach the full-31 path, or that comes back `SKIP`, is `ERROR`: a red-test built to exercise a path and missing it has measured nothing |
| `ATLAS_PATH_PORTABLE` | `atlas_path_portability_gate.sh` | `PASS` \| `FAIL` \| `ERROR` (exit 2, added 2026-09-08). Builds the f/g/t ladders and runs `--kc-scan` twice, in two different directories, and requires the two `atlas.json` files to be **byte-identical**. The defect (Q-92) was absolute ladder paths embedded in the artifact, so two correct runs disagreed under `sha256sum` — invisible to the TR-12 battery, whose normaliser rewrites those fields before diffing. Failing to build, or producing an empty atlas on either side, is also `FAIL`, stated as "measured NOTHING". `ERROR` is the third value, and the only one that is not a statement about the artifact: handed a `SOLVE` binary that does not correspond to `solve.c`, the gate cannot establish its own subject and says so instead of grading. It needs that guard more than most, because it compares one binary against **itself** in two directories — a stale binary that embedded absolute paths *consistently* would report `PASS` and certify a property of an engine nobody is shipping, and one that predates the Q-92 fix reports `FAIL` against a defect that is fixed. Both were measured on 2026-09-08: the 2026-09-05 `./solve` gave `FAIL`, a binary built from the same tree gave `PASS`. `ATLAS_PORTABILITY_ALLOW_STALE=1` overrides deliberately |
| `CITATION_LINE_GATE` | `citation_line_gate.sh` | `PASS` \| `FAIL` \| `ERROR`. For every `solve.c:N` citation in `SOLVE_C_CLI.md`, mines the citing line — or, when that yields nothing, the nearest preceding heading — for distinctive identifiers, and requires at least one to occur inside the cited span. A **ratchet**, not an absolute: `FAIL` when the stale count rises above the pinned budget **or** a new stale citation key appears; `ERROR` when the document yields no citation at all or none that is checkable. Both directions are red-tested on a fixture pair differing by one digit of one citation |
| `DISK_PRECHECK_MARKER` | `disk_precheck_marker_gate.sh` | `PASS` \| `FAIL` \| `ERROR`. Six legs over `--disk-precheck`'s marker check plus two mutants. The legs that carry it are the zero-byte and junk markers — those separate "reports the marker's content" from "asserts the marker is present", and a `stat()` cannot establish disk identity. One mutant is the reword-only half-fix, which must die there; the other stops the assertion comparing at all. Leg 4 is the anti-overclaim leg: a well-formed marker with no expected digest must be **reported**, never asserted, since a validator that refuses everything is a permanent FALSE dressed as rigour |
| `EVICTION_RESUME_MANIFEST` | `test_eviction_resume_manifest.sh` | `PASS` (rc 0) \| `FAIL` (rc 1) \| `ERROR` (rc 2), all whole-line. 🔴 **Until 2026-09-08 `ERROR` was the only value this token ever took**: the pass and fail paths printed prose and an exit status and no token at all, so a consumer told to `grep -qx` for `=PASS` would have waited forever on a test that had already passed. All three are now emitted. `ERROR` is the stale-binary guard and it earns its own value: the test is designed to FAIL on the pre-#164 binary and PASS on the fixed one, which makes a stale `./solve` indistinguishable from a live regression, so an unestablished subject is reported as `ERROR` and kept distinct from the `exit 1` failures — `EVICT_RESUME_ALLOW_STALE=1` overrides it deliberately. The "binary not executable" path moved from rc 1 to rc 2 in the same change, because a missing subject is the same class as a stale one. What the test asserts, in both directions from one binary: with a per-cell `.dfs_state` present, a divergent `shard_manifest.txt` at startup is **advisory** and the enum proceeds (the #164 eviction false-abort); with `.dfs_state` removed, the same divergence stays **fatal** at exit 22, which is the tamper tripwire the fix had to preserve |
| `EVICTION_RESUME_MANIFEST_ERROR` | `test_eviction_resume_manifest.sh` | emitted only alongside `=ERROR`, naming the cause: `stale-binary:<path>` (the binary does not correspond to `solve.c`) or `binary-not-executable:<path>` |
| `F1C5_ADOPT_DIGEST_GATE` | `f1c5_adopt_digest_gate.sh` | `PASS` \| `FAIL` \| `ERROR` (rc 40), all whole-line. RCQ03 finding 2: until 2026-09-10 `f1c5_finalized_try_adopt()` READ the `.finalized` marker's `sha256_decompressed`, PRINTED it in the `adopted finalized layer` line, and never compared it — and this was documented as intended. Flip byte 100 of an n=9 f layer 1 (the low byte of `off[2]`), resume, and the build adopted the altered layer, logged the ORIGINAL digest, and exited 0 with `total = 18768` for a true 26,112. Nothing structural sees it (a bumped offset is still monotone with the right endpoints), `--kc-g-check` misses a large fraction of the class (its merge-join sees only keys in BOTH ladders' spans), and `--kc-ladder-verify` misses it too when the eviction lands in the sidecar window, because the resume regenerates the sidecar from the altered bytes. 🔴 **Five legs, and the two DIRECTIONS carry equal weight**: A corrupt layer refuses (`F1C5_ADOPT_DIGEST=MISMATCH`, layer re-swept, total 26,112); B clean layer still ADOPTS (`=OK`); C a marker with no digest refuses (`=MISSING`); D `SOLVE_F1_ADOPT_UNVERIFIED=1` adopts that one unattested (`=UNVERIFIED`); E the same opt-out with a corrupt layer STILL refuses — E is the mutant leg, because the first draft read the env var before recomputing and measured 18,768 with it set. Without B a binary that refused every adoption would pass, and that would turn every eviction-resume into a full re-sweep — worse than the defect. `ERROR` is the cannot-measure guard and is never read as agreement. THREE causes, and the third was added 2026-09-10 minutes after this gate misled its own author: no binary; the binary at the given path does not embed `sha256(solve.c)`, i.e. it was built from DIFFERENT SOURCE; or the drill hook produced no marker. The stale-binary arm exists because run bare the gate defaults to `./solve`, the checked-in binary, which in this repo is routinely stale (measured: 131 h behind `solve.c`) — and against a pre-fix binary leg A reports `total=18768` and `F1C5_ADOPT_DIGEST_GATE=FAIL`, the exact defect signature, for a binary that simply predates the fix. "I was given the wrong binary" is not "the code is wrong", so it ERRORs (rc 40) and never FAILs |
| `Q7RANKS_PARSE` · `Q7RANKS_PARSE_LEGS` | `q7ranks_parse_gate.sh` | `PASS` \| `FAIL` \| `ERROR` (rc 2), all whole-line. F-5 round 5 **B1(r5)**: `a2_q7_ranks` asserted `rank3 == 0` by reading the engine with `sed 's/.*\brank3=\([0-9]*\).*/\1/p'`, but `solve.c`'s `--kc-o3-rank` driver prints **`printf("rank3\t%s\n", tdec)`** — a TAB. Verified by execution: `cat -A` shows `rank3^I0$`. The only `rank3=` in `solve.c` is `class_first_rank3=`, which the `\b` deliberately did not match because `_` is a word character — so the pattern dodged the false positive and **never matched the true one. The row could only ever FAIL**, publishing `TR12_Q7_RANKS=FAIL` for a correct `rank_O3(KW)=0`, in the row carrying the labeling theorem TR-12 leans on. It is **n ≥ 31-only**, so no golden, no rehearsal and no gate had ever run it against the engine, and the battery ships FROZEN by `git archive` at launch, so a mid-run fix could not reach the run's `VERDICTS.txt`. 🔴 **How it survived its own red test, which is why this gate exists:** the test drove four STUBS printing `rank3=0` and `rank3=5` — the regex was validated against fixtures written to match the regex. That is verifier closure, the check handed its witness by the thing it checks. **`row_assertion_gate.sh` cannot own this class**: it proves a row ASSERTS, not that the assertion's PARSE MATCHES ITS PRODUCER. 🔴 **The first version of this gate defined its OWN copy of the row's parse and never read `scripts/tr12_repro.sh` at all** — F-5 round 6 measured that restoring the exact defect in the ROW left it reporting `PASS`, and that deleting `tr12_repro.sh` entirely still left it reporting `PASS`. It bound to the producer and to a COPY of the consumer, so its red test mutated **the gate**, not **the row**: the same verifier closure it was built to catch, committed inside the instrument. It now **EXTRACTS the `a2_q7_ranks` block from the battery by its own `row_begin`/`row_end` markers and EXECUTES it**, with `row_begin`/`row_end` stubbed and everything else — the parse, both assertions, the `IN` branch, the n≥31 guard — being the battery's own text. ⚠ **Scope, corrected after F-5 round 7:** it covers the ONE n≥31-only copy of that parse (`tr12_repro.sh:1970`); the same awk at `:564` and `:2029` IS exercised at n=9 by the battery, so those are not this gate's subject — an earlier draft of this row said "exactly one copy of the parse in the tree", which was false. It also does NOT cover the n≥31 guard: extraction starts at `row_begin`, inside the `if`, so the extracted block carries no `N_PAIRS` test (proved by mutation — `-ge 32` leaves the gate passing). Five legs against a freshly built `-DSOURCE_SHA` binary and real n=9 ladders: (1) the engine prints a tab-separated `rank3` field; (2) the extracted row returns 0 on the O3-least walk with a matching anchor; (3) a walk of rank 16244 fails the row **and the value is named**; (4) an anchor mismatch fails the row; (5) the producer's format is restated so a change is visible. **Red tests, all executed:** R1 the row reverted to the defective `sed` → `=FAIL`; R2 the row deleted from the battery → `=ERROR` ("the subject of this gate is absent, which is not the same as passing"); R3 the real tree → `=PASS`; R4 this gate's script absent → `TR12_REPRO_GATE=ERROR`, because the leg used to `return 0` on absence and deleting the check made everything green. `ERROR` covers five causes: no compiler, a failed build, absent ladders, an unreadable battery, and an empty extraction — the last two added by the round-6 rewrite that made this gate read `scripts/tr12_repro.sh`, and missing from this sentence until F-5 round 7 caught it (a list of ERROR causes that omits two real ones is the drift this gate exists to catch). Note also that legs 1 and 5 are the same measurement on a regenerated copy, so `ROW_ASSERTION`-style leg counting reads five legs but four distinct measurements — a gate that cannot see its subject must never report `PASS`. In `CORE`, so the reproduction fingerprint covers it |
| `Q2_WITNESS` · `Q2_WITNESS_LEGS` | `q2_witness_gate.sh` | `PASS` \| `FAIL` \| `ERROR` (rc 2), all whole-line. Raised by external reviewer **R5 (item 4)**, 2026-09-11; backlog **Q-487**. Rows `a1_q2c`/`a1_q2d` published `FIRST^C15` and `LAST^C15` with the solver's **exit status as their only failure flag**, and an enumeration that finds nothing exits 0. Measured against the real binary on a real n=9 ladder: `--kc-enum f --kc-c3-max 0 --kc-limit 1` prints `[kc] enumerated 0 walk(s) (C3 in-path)` at rc 0, and `--kc-enum-desc` the same. At n=31 these goldens are **minted from whatever the run emits**, so an n=31-only pruning defect that suppressed every candidate — or a wrong C3 threshold plumbed into the row — would have published an **empty extremal walk** as `TR12_Q2C=PASS`/`TR12_Q2D=PASS`, uncorrectably, because the battery ships FROZEN by `git archive` at launch. Both rows now require a **witness**: one walk line of `2n` fields, `--kc-member` → `MEMBER`, and `--kc-profile` → `cd ≤ C3MAX`. ⚠ **Scope — extremality is NOT checked and cannot be.** B32 records that only membership is checkable for these two rows and that limit is unchanged; this gate proves the rows refuse to publish *nothing*, not that what they publish is least or greatest. It also carries the replacement for a safeguard that was **documented and never built**: `QUERY_INVENTORY.md` promised "abort-and-report if >10⁶ backtracks" in two places and `grep -i backtrack` finds no such mechanism anywhere — a wall-clock bound (`TR12_Q2_ENUM_TIMEOUT`, default 6 h) replaced it rather than an engine change, and both inventory rows were corrected (CX-44). Following F-5 round 6, the gate **EXTRACTS the `kc_first_last_witness` helper and BOTH rows from the battery by their own markers and EXECUTES them**; `row_begin`/`row_end` are stubbed and everything else is the battery's own text, and every fixture walk comes out of the real binary rather than a stub written to match the check. Eight legs: (1) extraction integrity; (2) baseline on the real universe; (3a) the zero-walk-at-rc-0 condition **reproduced, not assumed**; (3b) the row fails on it and names the field count; (4) a real `cd=31` walk fails against `C3MAX=30` and `cd` is named; (5) a real non-member fails and `--kc-member` is named; (6) `a1_q2d` carries the same requirement, so the fix cannot reach one row only; (7) the wall-clock bound fires and is loud. **Mutants, all executed and all killed:** M1 the witness call deleted from the row → `=FAIL`; M2 the helper returning 0 unconditionally → `=FAIL`; M3 the battery absent → `=ERROR`; M4 the timeout branch disabled → `=FAIL`. In `CORE`, so the reproduction fingerprint covers it |
| `ROW_ASSERTION` | `row_assertion_gate.sh` | `PASS` \| `FAIL` \| `ERROR`, all whole-line. Added 2026-09-11 to own a CLASS rather than an instance. F-5 round 4 found `c_v2` and `c_v5` in `scripts/tr12_repro.sh` emitting a table and asserting nothing about it — an atlas with every `by_class` object stripped produced a header-only table and exited 0. That is round 1's D11 finding, **fixed for `c_v1` and never swept to its siblings**: the class was found, one instance was repaired, and nothing looked for the rest. This gate is the sweep, standing. It parses every `row_begin`…`row_end` block, decides whether the block can reach its own `rc` through a content-guarded failure path, and FAILs naming each row that cannot. `ERROR` when the battery is absent or does not parse — a check that cannot see its subject must never report `PASS`. **Red-tested by deleting the `c_v1`, `c_v2` and `c_v5` assertions that are CURRENTLY FIXED**, plus a mutant where the checks are written but the flag never reaches `exit`, and one where an exempted row is *given* an assertion (a stale exemption is also a defect). 7 of 7 killed. A detector that only recognises the rows already known to be bad is a list, not a gate. Wired into `scripts/pre_push_gate.sh` as ADVISORY: four driver-built rows are known-unasserted today and a blocking leg would stop every push on work nobody has scheduled |
| `ROW_ASSERTION_POP` | `row_assertion_gate.sh` | the population it parsed: `row_begin` blocks in the battery. First of eight counts printed together; `ROW_ASSERTION_EMIT`, `ROW_ASSERTION_DRIVER`, `ROW_ASSERTION_ASSERT`, `ROW_ASSERTION_UNASSERTED`, `ROW_ASSERTION_RCONLY`, `ROW_ASSERTION_KNOWN`, `ROW_ASSERTION_NEW`, `ROW_ASSERTION_STALE` follow on their own lines. Measured 2026-09-11: `POP=53`, `EMIT=38`, `ASSERT=27`, `UNASSERTED=11` |
| `ROW_ASSERTION_EMIT` · `ROW_ASSERTION_DRIVER` | `row_assertion_gate.sh` | rows that emit a table or artifact, and the subset the DRIVER builds (as opposed to publish-only rows that copy a producer's output). The driver-built subset is where the D11 class lives: a publish-only row asserting nothing is carrying its producer's rc, which is a weaker claim but not a manufactured one |
| `ROW_ASSERTION_ASSERT` · `ROW_ASSERTION_UNASSERTED` | `row_assertion_gate.sh` | rows with, and without, a content-guarded failure path that reaches the row's `rc`. `ROW_ASSERTION_UNASSERTED` is the finding: a row that can publish an empty or wrong table and still exit 0 |
| `ROW_ASSERTION_RCONLY` | `row_assertion_gate.sh` | rows whose emission AND `rc` both belong to the producer — reported as advisory, never as FAIL. This is the `N31_ATTESTATION_SCOPE` axis: the row is not manufacturing a verdict, it is forwarding one, and forwarding is a different (weaker) claim from asserting |
| `ROW_ASSERTION_KNOWN` · `ROW_ASSERTION_NEW` · `ROW_ASSERTION_STALE` | `row_assertion_gate.sh` | unasserted rows already on the exemption list, ones that are not, and exemptions whose row has since GAINED an assertion. `ROW_ASSERTION_STALE` is deliberate: an exemption that outlived its reason is the same defect as a gate nobody runs, one level up. `ROW_ASSERTION_NEW` is what makes the gate FAIL |
| `ROW_ASSERTION_ERROR` | `row_assertion_gate.sh` | emitted only alongside `=ERROR`, naming the cause: the battery is unreadable, or its `row_begin`/`row_end` blocks do not balance |
| `ROW_ASSERTION_SELFTEST` · `ROW_ASSERTION_SELFTEST_FAILS` | `row_assertion_gate.sh` | `--selftest` plants one fixture per verdict class — an asserting row, an unasserted row, an rc-only row, a stale exemption, an unbalanced battery, an empty battery — and checks the gate grades each correctly. `PASS` requires `ROW_ASSERTION_SELFTEST_FAILS=0`. The gate's own warrant, since its whole value is that it can FAIL |
| `FAILOPEN_CLOSURE` | `failopen_closure_gate.sh` | `OK` \| `FAIL` \| `ERROR`, all whole-line since 2026-09-08 (`OK` and `FAIL` used to end in counts that were already on their own `FAILOPEN_CLOSURE_*` lines). The meta-gate for the fail-open class, checking one rule on the observable rather than on code shape: *run with its target absent, a gate must neither print an OK-class token nor exit 0*. Each gate-shaped script is copied alone into an empty directory and executed there, so every relative input is missing. `ERROR` covers a collapsed population (fewer than five runnable scripts), a population filter returning under half its own independent upper bound, an ungradable timeout, or a stale allowlist row. Scripts touching cloud/privileged commands, or hardcoding an absolute path, are `UNRUN`/`ABSPATH` — graded by reading, and counted, never silently dropped |
| `FAILOPEN_CLOSURE_ERROR` | `failopen_closure_gate.sh` | emitted only alongside `=ERROR`, naming the cause: `bad-args`, `bad-timeout`, `no-scripts-dir`, `allowlist-unreadable`, `allowlist-malformed`, or `graded-error` (the population it did grade produced an error — collapsed population, a filter under half its upper bound, or an ungradable timeout; the specific `[ERROR]` line is printed above it) |
| `FAILOPEN_CLOSURE_POP` | `failopen_closure_gate.sh` | the population it graded: gate-shaped scripts under `scripts/`, excluding the gate itself (which carries the UNRUN regex as a literal and would match it; its own warrant is `--selftest`, which plants one script of every verdict class). It is the first of seven counts printed by one `printf` — `_RUN`, `_OPEN`, `_RC0`, `_ALLOWED`, `_UNRUN`, `_TIMEOUT` follow on their own lines. `_OPEN` and `_RC0` are the findings: a script that printed an OK token, or exited 0, from an empty world |
| `KNUTH_C67_REPRO` | `knuth_c67_repro_gate.sh` | `OK` \| `FAIL` \| `ERROR`, all whole-line since 2026-09-08 (the `ERROR` forms used to name their cause on the verdict line; it moved to `KNUTH_C67_REPRO_ERROR`). Leg 1 requires the published 1169/233/75 tree-node figures to carry their reproduction command in the same document; leg 2 **runs** those commands and compares the binary's own output to the published integers, so a doc edit cannot satisfy it and a doc typo cannot break it. Deleting the figures collapses the population and is `ERROR`, not a pass |
| `KNUTH_C67_REPRO_ERROR` | `knuth_c67_repro_gate.sh` | emitted only alongside `=ERROR`, naming the cause: `extractor-failed`, `population-collapsed`, `build-failed`, `not-executable:<path>`, or `stale-subject:<path>` (a handed-in `SOLVE_BIN` that does not correspond to `solve.c`; `KNUTH_C67_ALLOW_STALE=1` overrides) |
| `MANIFEST_ZERO_ENTRY` | `manifest_zero_entry_gate.sh` | `PASS` \| `FAIL` \| `ERROR`. Q-445: a fresh run wrote a **zero-entry** `shard_manifest.txt` about 238 ms after launch, and the next launch correctly refused it — a run that bricked its own directory, deterministically. The fix is at the write site and leg 2a is why: at verify time a fresh directory is indistinguishable from a truncated sidecar write, so tolerating an empty manifest would hand `PASS` to the state most likely to mean it is broken. The invariant the gate holds: *`shard_manifest.txt` exists ⟹ it attests at least one shard* |
| `MISSING_SHARD_MERGE` | `q317_missing_shard_merge_gate.sh` | `PASS` \| `FAIL` \| `ERROR`. 🔴 **A `FAIL` here is the gate working.** Q-317 item (4) is not landed: the end-of-enum cross-reference has no `else` arm for a shard whose size probe returns −1, so an entirely **deleted** shard passes the merge while its checkpoint row still claims *N* records. The truncation leg beside it is the control, and `ERROR` is reserved for the harness — a truncation this binary is known to catch failing to surface, or the delete leg never reaching the merge scan, means nothing was measured and the delete leg's exit code proves nothing either way |
| `Q314_MOD48` | `q314_mod48_gate.sh` | `PASS` \| `FAIL` \| `ERROR` (exit 2). Q-314 item (1): the atlas's divisibility check read a **precomputed** `mod24_ok` column — the emitter graded against itself — and stopped at 24, while the free G48 action makes the complete raw sequences divisible by **48**. Six legs over three faults, and each fault must **isolate** the gate it targets, because a new check that only fires where an old one already fires has added no coverage. `--atlas-fault q10-mod48` adds `_ATLAS_ORBIT` (=24) to the layer-0 flow, leaving it 24-divisible and no longer 48-divisible: `XA-48` must fire and the mod-24 gate must stay silent. `v2-mod48` must fire `V2-48` and not `V1-16`; `v1-mod16` must fire `V1-16` and not `V2-48` — the pre-existing faults cannot test either, since a class-mass swap preserves divisibility exactly and a dropped pair sets a cell to 0, which is divisible by everything, so each new gate needs its own fault or it ships untestable. Legs 5 and 6 run the consumer with **no** `--atlas-walks`, which is the only configuration that can exist at n=31 — brute force means enumerating all 26,112 walks explicitly — and require both `V2-B0` vertical-conservation gates present and passing on a clean n=9 atlas, then `V2-B0`, and no pre-existing gate, to fire on `v2-class-swap`: the fault that moves mass between distance classes, and the one that was invisible in exactly the configuration the full-31 numbers are produced in. `ERROR`, never `FAIL`, when a handed-in `Q314_SOLVE` does not correspond to `solve.c` — an unestablished subject is not a defect, and reporting one sends a reader hunting a bug that is not there. `Q314_ALLOW_STALE=1` overrides deliberately. Runs standalone and as a leg of `tr12_repro_gate.sh`, which hands it the binary it has already built so the gate costs no second compile |
| `Q326_QUERY_SURFACE` | `q326_kc_query_surface_gate.sh` | `PASS` \| `FAIL` \| `ERROR`. Q-326 items (3)(4)(5): `--kc-count`/`--kc-rank`/`--kc-member` parsed `--kc-c3-max` and dropped it, returning the superspace count at rc 0 with nothing naming the scope; `--kc-c3-max` was `long long` at the CLI and `int` inside the enumerator, so 2³² truncated to 0 walks at rc 0; and `kc_parse_walk` validated each slot without checking the pairs form a **permutation**, so duplicate-pair vectors got a positive multiplicity under a trailer stamping the ratified convention. Legs 6, 7 and 10 exist because refusing everything is not a fix, and leg 11 because the permutation check belongs in the shared parser — a fix in the `--kc-repr` branch alone passes every other leg |
| `Q326_UNRANK_M0` | `q326_kc_unrank_m0_gate.sh` | `PASS` \| `FAIL` \| `ERROR`. Q-326 item (1): `--kc-unrank … --kc-record` printed the class representative unconditionally, including on `kc_class_repr`'s `m == 0` exits, which leave `repr` unwritten — a record line built from uninitialised stack, indexing a 64-entry table with bytes up to 255, at rc 0 under a conformance trailer. Leg 3 is the load-bearing one: a guard that sets rc 1 and still prints `repr` passes legs 1 and 2 and is still reading uninitialised memory, so only the run-to-run byte-identity check sees it |
| `Q422_RATIO_COLUMNS_GATE` | `q422_ratio_columns_gate.sh` | `PASS` \| `FAIL` (exit 40) \| `ERROR` (exit 2, added 2026-09-08). Every could-not-measure path *about the artifact* is still folded into `FAIL` — fail-closed. `ERROR` is reserved for the one condition that is not about the artifact at all: a `Q422_SOLVE` binary that does not correspond to `solve.c`, where the gate has no established subject to grade. Folding that into `FAIL` would assert "the Q-422 ratio columns are broken" about a binary nobody committed; measured on 2026-09-08, the 2026-09-05 `./solve` produced an unearned `Q422_RATIO_COLUMNS_GATE=PASS` through this arm. `Q422_ALLOW_STALE=1` overrides deliberately. The atlas consumer's cell-by-cell gates compared only the integer columns, so zeroing every derived ratio left 29 consumer gates printing `PASS`, `ATLAS_CONSUMER=PASS`, `TR12_REPRO=PASS` and a byte-identical committed golden, while the field V1 plots drew empty. The gate runs the consumer three ways on a fresh n=9 universe and requires `--atlas-fault ratio-zero` to fail **exactly** the five derived-column gates and no integer gate — an integer gate firing would mean the injected fault is not the one described |
| `GROUPC_REHEARSAL` | `group_c_n9_rehearsal_gate.sh` | `PASS` \| `FAIL` \| `ERROR`, with `GROUPC_REHEARSAL_VERDICTS` (how many verdicts the consumer emitted) and `GROUPC_REHEARSAL_N31_GUARDS` (the ratcheted count of `n == 31` guards in the atlas consumer) beside it. Group C is nine query families of post-processing on a tens-of-KB JSON — milliseconds, $0 — but it runs AFTER a scan measured in days, so a family that needs a field the scan did not emit costs another full scan. `QUERY_INVENTORY.md` had said since it was written that this *should* be rehearsed at n=9 first, against a fixture path that does not exist. Three gates: it can run at all; every family that can run at n=9 does, with the verdict COUNT asserted because a family that silently stops emitting leaves every remaining verdict green; and every `n == 31`-only path either announces itself as `SKIP:n=<n>` or names a file that drives it at n=31 — which must exist, must actually mention the symbol, and if it is a `.sh` gate must have an invoker. That last clause is not decoration: `TR12_A5_ORBIT_COLUMNS` emitted nothing at all below n=31, and the one gate exercising its code had no invoker |
| `KC_WRITER_DEVFULL_GATE` | `kc_writer_devfull_gate.sh` | `PASS` \| `FAIL` \| `ERROR`, with `KC_WRITER_DEVFULL_CHECKS` (writers probed) and `KC_WRITER_DEVFULL_FAILS` beside it. Every KC artifact writer announced success when its output could not be written: on `/dev/full`, `--kc-scan` printed "atlas written" and `KC_SCAN=OK` at rc 0, the chunk writer `KC_SCAN_CHUNK=OK` at rc 0, `--kc-profile --kc-tsv` `KC_PROFILE=OK` at rc 0, and the check-arrangement, t-cert, o3-cert and oracle writers all printed "certificate written" — with nothing on disk. Found 2026-09-02, ONE of the seven writers (the merge) was fixed on 2026-09-04 and the rest were left, and a fresh review re-found it 2026-09-09; this gate exists so that cannot recur silently. Each writer is required **both** ways — nonzero exit and a FAIL token to `/dev/full`, and a clean exit with a non-empty file to a real path — because a gate checking only the red half passes on an engine that refuses to write anything at all. Probing fewer than seven writers is `ERROR`, not `PASS` |
| `Q433_XA_CERT` | `q433_xa_cert_gate.sh` | `PASS` \| `FAIL` \| `ERROR`. The XA pricing path's refusal tested that a certificate **path string** had been supplied and never opened the file, so naming a nonexistent path was enough to unblock an EXHAUSTIBLE/INFEASIBLE verdict — weaker than `test -f`. Leg 0 is static and checks the **wiring**: the refusal guard must actually call the validator, since a helper nothing invokes is the defect it was written to fix. Leg 1 requires a well-formed certificate to be **accepted**, and mutant M2 — opens the file, checks it parses, never checks what it says — must die on leg 3 alone |
| `RESUME_BUDGET_INFINITY` | `resume_budget_infinity_gate.sh` | `PASS` \| `FAIL` \| `ERROR`. Q-317 (1): the resume path decided whether to re-run a stored budgeted sub-branch with a test guarded on `current_budget > 0`, but budget **0 means uncapped**, i.e. infinite — so an uncapped resume skipped every stored budgeted cell and inherited truncated results as a complete enumeration. An undercount presented as exhaustive is this project's worst error direction. Both directions are checked from the same binary, because a one-sided test passes on a binary that never skips anything: a capped run whose stored budget is at least the current one must still skip the cell, and an uncapped run must not skip it at any finite stored budget. `ERROR` is reserved for an unestablished subject — a missing binary, or a `./solve` older than `solve.c` (`RESUME_BUDGET_ALLOW_STALE=1` overrides). That guard was added after the gate announced a live `FAIL` against a binary two days older than the commit that fixed the defect: an unestablished subject is not a defect, and reporting it as one sends a reader hunting a bug that is not there |
| `RESIDUAL_CONSISTENCY` | `check_residual_consistency.sh` | `PASS` \| `FAIL` \| `ERROR`, all whole-line since 2026-09-08 — the verdict line used to end `offenders=<n> scanned=<n>` and the `ERROR` forms to end in their cause, so the script's own header promise of `grep -qx` did not hold against what it emitted. It asserts that the ~105–139-bit residual is never stated as a bare **point** estimate in TR-10, TR-9 or the README. Fail-closed since the 2026-09-05 sweep: before that an absent or renamed report read through `cat … 2>/dev/null` as zero offenders and `PASS` |
| `RESIDUAL_CONSISTENCY_ERROR` | `check_residual_consistency.sh` | emitted only alongside `=ERROR`: `unreadable:<file>`, `empty:<file>` or `population-collapsed` |
| `RESIDUAL_CONSISTENCY_OFFENDERS` | `check_residual_consistency.sh` | bare point estimates found. `-1` when the run could not measure — an ERROR never reports zero offenders |
| `RESIDUAL_CONSISTENCY_SCANNED` | `check_residual_consistency.sh` | lines scanned across the three reports. `-1` when unmeasured; a real count below the floor of 100 is itself the `population-collapsed` ERROR |
| `SIDECAR_SHA_GATE` | `sidecar_sha_gate.sh` | `OK` \| `FAIL`. Q-324: every `solutions.sha256` writer must record the **logical** sha — the decompressed canonical byte stream — not the sha of the file as it sits on disk. The standalone `--merge` path shelled out to `sha256sum <outname>`, so with gz framing the default since #169, the sidecar (and the `solutions.meta.json` parsed back out of it) held the sha of the **container**. That direction manufactures phantom drift, because gzip framing varies with zlib version and level while the content does not |
| `SIZE_GATE` | `pre_commit_size_gate.sh` | `OK` \| `REFUSED` \| `ERROR`, all whole-line since 2026-09-08 (every one of the three used to carry trailing prose on the verdict line, against its own header's `grep -qx` promise). Enforces the standing rule that a file at or above 1 MiB needs a recorded approval before it is **newly tracked**; the scope is first-time tracking only, because 22 tracked files already exceed the threshold and a gate that fires on every commit is removed within a day. `REFUSED` (rc 1) names the count of unapproved staged files; `ERROR` (rc 2) covers not being in a git repo, an unlistable index, or an unparseable approval table |
| `SIZE_GATE_ERROR` | `pre_commit_size_gate.sh` | emitted only alongside `=ERROR`: `not-in-git-repo`, `staged-list-failed` or `allowlist-unparseable` |
| `SIZE_GATE_LIMIT` | `pre_commit_size_gate.sh` | the threshold in bytes actually applied (1,310,720 = 1.25 MiB, raised from 1 MiB on 2026-09-04). `-1` when the run ended before reading it |
| `SIZE_GATE_UNAPPROVED` | `pre_commit_size_gate.sh` | unapproved first-time files at or over the limit, emitted on every terminal path. `-1` when the gate could not measure |
| `SPOT_PRECHECK` | `spot_health_precheck.sh` | `OK` \| `WAIT` \| `HARD-FAIL` \| `ERROR`, printed **bare** and last on every exit path — this one really is `grep -qx`-able, and was made so deliberately in 2026-09-02 after the only two tokens it emitted were prefixed, suffixed and on stderr while the OK/WAIT/HARD-FAIL paths emitted none at all. Three escalating signals: published SKU restrictions, family vCPU quota headroom, then a real ~$0.01 D2als_v7 Spot probe. `ERROR` (rc 4) is not a capacity verdict — treat it as do-not-launch, but escalate it as a broken precheck. A non-integer `need_vcpu` is `ERROR` for a measured reason: the numeric test failed, bash read the failed test as false, and the script printed a green light having checked nothing immediately before a real `az vm create` |
| `TR12_N31_GOLDEN` | `tr12_n31_golden_gate.sh` | `OK` \| `ABSENT` \| `PLACEHOLDER`. A millisecond pre-flight, not the thing that makes n=31 certification able to fail — `tr12_repro.sh` already refuses both cases, and this gate's header says so. What it buys: the refusal arrives before a multi-day battery rather than after it; it requires `_MANIFEST.txt`, because the n=9 goldens are hashed by `tr12_repro_gate.sh` and an n=31 golden would otherwise be editable without trace; and it names **which** problem it is instead of 50 undifferentiated mismatches |
| `TR12_REPRO_GATE_CURRENT` | `tr12_repro_gate.sh --check` | `YES` \| `NO` \| `UNKNOWN`, all whole-line since 2026-09-08 (`NO` and `UNKNOWN` used to carry their explanation on the verdict line, so only `YES` was ever `grep -qx`-able — which is why the two existing consumers both matched it by substring). The cheap fingerprint-only leg (milliseconds, no build) that other checks call on every run: `YES` means none of the derived inputs, the gate itself, or any expected block has changed since the last recorded `PASS`; `NO` means one of them has; `UNKNOWN` means no stamp exists yet. It answers a narrower question than `TR12_REPRO_GATE=PASS` — "is that recorded pass still current", not "does the tree reproduce" |
| `TR12_REPRO_ROWS` | `tr12_repro.sh` | rows the battery attempted. Written into the run's `VERDICTS.txt`, **not** to stdout, alongside `TR12_REPRO_SKIPPED` and `TR12_REPRO_COMPLETE=YES\|NO` on the following lines. Read it with the skip count beside it: a battery is not complete because it did not fail |
| `TR12_REPRO_REASON` | `tr12_repro.sh` | present only on one specific refusal — `no-expected-block-set-for-n<N>`, i.e. `--expect` names no directory for this universe. A battery with nothing to diff against cannot pass, so the run stops before Group A0 rather than reporting rows it never compared |
| `TR12_REPRO_MINTED` | `tr12_repro.sh` | count of rows whose expected block did **not** exist and was **written** by this run under `--mint-missing`, into `VERDICTS.txt` beside `TR12_REPRO_ROWS`; when non-zero, `TR12_REPRO_MINTED_ROWS=<ids>` follows it naming them. A minted row's `PASS` attests exit status and in-row gates only — nothing was diffed — so a battery with `TR12_REPRO_MINTED` above 0 has recorded what it saw, not reproduced a golden. Without `--mint-missing` the count is always 0 and a missing block is a failure |
| `TR12_C3_FILTER_DEGENERATE` | `tr12_repro.sh` | `YES` \| `NO`, also into `VERDICTS.txt`. `YES` when the measured retention of the C3 filter at the run's threshold is exactly 1.0 or exactly 0.0 — the filter kept everything or nothing, which makes every C15 leg silently identical to the superspace leg (or empty). The battery still runs; the token exists so that a C15 result is never read as a C3-constrained one without the reader knowing the filter did nothing |

The five `d5_*` gates share one shape: each extracts a row body **verbatim**
out of `scripts/tr12_repro.sh` — never re-typed, because a copy drifts — and
runs it in a stub harness at full-31 magnitude, with a red leg proving the row
can still fail. Each emits `PASS` or `FAIL` only, and folds every
could-not-measure path into `FAIL` at exit 40, which is the fail-closed
direction.

| token | the WRONG-OBJECT defect it pins |
|---|---|
| `D5_01_Q1C_SKIP_GATE` | row `a2_q1c` ran unconditionally, but at n≥31 rank_O3(KW)=0 by the labeling theorem, so its keep-test can never hold: the row failed — after burning 3–5 h in the descent loop — and took `TR12_REPRO=FAIL` with it, for a row already ruled `SKIP:merged-into-Q4AC`. **Re-pointed 2026-09-10 (N3):** the guard is no longer a pair-count proxy emitting a hand-typed skip; the row measures the conditioning interval and the gate pins the contract between that measurement and the spend — `NONEMPTY` spends, `EMPTY`, `ERROR` and *producer silence* do not, and the token each case yields is pinned. The fourth leg is the point, as the third was before it: an **unmeasured** state must not become a free pass, and mutants M4/M5 exist to prove that leg is load-bearing |
| `N3_MEASURED_NULLS_GATE` | Q1c and Q10a's KW-orbit-rank leg were published as **hand-written absence claims** — `SKIP:merged-into-Q4AC`, and the sentence "(iv) KW-orbit-rank: DROPPED" inside a golden. Both were true and neither was checked, so from outside "we computed it and the answer is nothing" was indistinguishable from "we never ran it". Each is now produced by a function that can FAIL, and this gate extracts both verbatim and runs them against certificates the live battery will never see: a rank-0 anchor (real `--kc-o3-unrank 0` output), two engine sources disagreeing, a bracket contradicting its own rank, a certificate that has grown a class-rank field. 11 pinned verdicts — 2 EMPTY, 2 refusals, 1 COMPUTABLE, 6 ERROR — and 9 mutants, every one killed. n=9 can only ever exercise the *refusal* direction, which is exactly why the EMPTY direction needs a red-test rather than a run |
| `D5_02_Q8_CHI2_GALLERY_GATE` | row `a1_q8_chi2` ran the engine's own n=13 sampler self-test on a universe it builds in-process, while TR-12, `QUERY_INVENTORY` and the runbook all promise a chi-square over 16 rank buckets of the **gallery** ranks. The row now computes that statistic in exact integer arithmetic from the rank column of the gallery TSV; the engine self-test survives as its own separately named row |
| `D5_03_LS_W0_EXACT_GATE` | row `a0_ls_w0` ran a Monte-Carlo pair-constrained null while the prose names TR-8's **exact** pair-only null, 47/445740. The literal is written into the gate from TR-8, not read out of `solve.py`, so a drift in the function plus a regold to match it still fails; the MC survives as its own labelled row |
| `D5_04_Q7_WITNESSES_GATE` | the Q7 SAT-witness leg was never invoked at all, yet the parent `TR12_Q7` aggregated to `PASS`. The witnesses need a solver that is absent, so the leg is now a **named** skip and a leg of the parent — the point being that "the query ran and matched" and "the query did not run" must not look alike. The gate runs the extracted `tok_record`/`agg` logic in both worlds, with and without a stub solver on `PATH` |
| `D5_08_Q6_Q10A_SHELL_GATE` | sibling residue from Q-394: the consumer was re-specified and the battery's own second implementation was left on the pre-ruling spec. `c_q6` emitted a rank-block contribution as a "percentile" — identically 0 for the King Wen anchor at full-31 — and `c_q10a` printed N/24 once per layer as an "orbit census" while the atlas gate already forces that equality. Both now compute the specified objects, and a missing or unparseable layer sidecar fails the row |


### Build reproducibility — toolchain manifest and cross-build verification

A reproducible-from-the-same-binary sha is not the same as a reproducible-from-the-same-commit sha. The 2026-05-12 investigation
(see HISTORY.md "May 11–12 — canonical c34390c0 found irreproducible from git history")
established that the d3 5.6T canonical `c34390c0…` is not reproducible from any committed code state — the same `solve.c` rebuilt on
current hardware produces sha `f66920c1…`. The most likely cause is a build-environment difference (gcc/glibc/libgomp/CPU-microarchitecture)
between the canonical-generation host and today's hosts, possibly amplified by a then-present stack-bounds bug since fixed in `f42f2ae`.

Going forward, every canonical `solutions.bin` archive **must** capture both the source identity and the build-environment identity. Two
shas with matching `solve.c` commit but mismatching build-environment manifest are NOT contradictions — they're a flag that the toolchain
or CPU microarchitecture changed between builds.

#### What to capture per build (mandatory)

Include this block in every canonical run's `metadata.txt` (next to the existing source-commit and env-var fields):

```bash
# Build environment manifest
echo "=== source ==="
echo "solve.c commit:    $(cd <repo> && git rev-parse HEAD)"
echo "solve.c sha256:    $(sha256sum solve.c | cut -d' ' -f1)"
echo "build flags:       <exact gcc command line used>"
echo ""
echo "=== toolchain ==="
gcc --version | head -1
ldd --version | head -1               # glibc
gcc -print-prog-name=libgomp.so.1     # path → confirms libgomp linkage
echo ""
echo "=== host ==="
uname -srvmpio
grep "model name" /proc/cpuinfo | head -1
grep "flags" /proc/cpuinfo | head -1 | tr ' ' '\n' | grep -E "avx|sse|fma|bmi" | tr '\n' ' '; echo
echo ""
echo "=== os image ==="
. /etc/os-release; echo "$NAME $VERSION_ID $VERSION_CODENAME"
[ -r /etc/cloud/build.info ] && cat /etc/cloud/build.info        # Azure image SKU + date
```

The manifest is captured once at build time and embedded in the same `metadata.txt` shipped with `solutions.bin.gz` to cold storage.

#### Use `-march=x86-64-v3` for canonical builds — for PORTABILITY, not because the sha changes

**The output sha is architecture- and flag-invariant.** The enumeration is deterministic integer
arithmetic; instruction selection does not change the records or their byte layout. This is
established empirically, not assumed: the 11.2T canonical is byte-identical between the x86
`-march=native` build and an **ARM Neoverse-N2 `-mcpu=native`** build (CANONICAL_HASHES §"cross-architecture
witness"), and the selftest sha `403f7202…` is identical across `-O2`, `-O3 -march=native`,
`-O3 -march=x86-64-v3`, and `-O3 -flto` (verified 2026-08-01 on AMD EPYC). So the documented recipes **tested to date** all reproduce the canonical sha. Evidence: one same-host
flag matrix plus one cross-architecture rebuild — two independent witnesses, not an exhaustive
guarantee over every compiler version and host.

The reason to prefer a fixed baseline for the *canonical* build is **portability of the binary**, not
reproducibility of the output: a `-march=native` binary emits host-specific instructions and may fail to
*run* (SIGILL) on an older CPU — which matters when someone else rebuilds/re-runs to reproduce. Pick:

- `-march=x86-64-v3` — AVX2 baseline. Runs on every Intel Haswell+ / AMD Excavator+ (ubiquitous since 2013). **Recommended canonical default.**
- `-march=x86-64-v4` — AVX-512 baseline. Use only if AVX-512 is a measured speedup AND you accept locking to Skylake-X / Zen 4+ silicon.

Performance impact of `-march=x86-64-v3` vs `-march=native`: typically 5–15% slower for HPC-ish workloads — acceptable for a portable canonical build. `-march=native` remains fine for internal tuning runs and reproduces the same sha; it just may not run everywhere.

#### Cross-build regression gate

Before adding any new sha to [CANONICAL_HASHES.md](CANONICAL_HASHES.md), the canonical must reproduce on a **second independent binary build**:

1. Build A on VM-A (e.g., westus3 Spot D128, day 1). Capture full manifest. Run canonical workload. Record sha.
2. Build B on VM-B (different day, different host or region, ideally different CPU generation if available). Capture full manifest. Run
   the same canonical workload. Record sha.
3. Sha A must equal sha B. Both manifests are committed to the archive directory alongside the canonical.
4. If shas diverge: the canonical is not yet eligible. Investigate the manifest delta; track down whatever non-determinism the divergence
   reveals (toolchain, microarchitecture, latent UB).

Cost: ~$5–15 of extra VM-hour per canonical for the second build. Negligible relative to the cost of an unreproducible canonical entering
the public record.

The intra-day 4-equivalence test (full-enum L1, deterministic re-run L2, `--merge-layers` of full-enum, `--merge-layers` of 56-branch
reconstruction) remains useful but is **insufficient on its own** — it proves intra-day binary determinism, not cross-build reproducibility.
Use 4-equivalence inside a single VM, then cross-build verify across VMs.

#### Container-pinned toolchain (target state for any future deeper canonical; not used by 560T)

The 560T canonical (`9a968fa2…`, 2026-06-08) shipped on the stock D128als_v7 Ubuntu 24.04 image (gcc-13.x, glibc 2.39) without container pinning — the host-fingerprint sidecar + Tier 1 hardening (`solve --validate-canonical`) was deemed sufficient for that scale. (**"Tier 1" and "Tier 2.1" in this subsection are *determinism-hardening levels*** — rungs of the Task #110 hardening programme in [HISTORY.md](HISTORY.md) — and are unrelated to the campaign-scale "Tier 1" of [LARGE_SCALE_CAMPAIGNS.md](LARGE_SCALE_CAMPAIGNS.md), to the Lean proof tiers of [`lean/README.md`](../lean/README.md), and to the Hot/Cool/Archive **storage** tiers used later in this file.) For any future deeper canonical, container pinning remains the **target state** (the 1120T extension this was written for is **not planned** as of 2026-08-01) but is **operator-deferred** (Tier 2.1 per `project_tier1_shipped_2026_05_28`). The image would contain:

- An explicit gcc version (e.g., `gcc-13.2.0-23ubuntu4` — pinned by apt version pin or by base-image digest)
- An explicit glibc version (frozen with the base image)
- An explicit libgomp version
- A fixed `-march=` baseline
- **`SOURCE_DATE_EPOCH`, and the rest of the deterministic flag set above** ⚠ **[ADDED 2026-09-03
  (Codex V2-F15 #16) — the four ingredients above are NOT sufficient for the claim that follows.
  Pinning the compiler, libc, libgomp and `-march=` still leaves `__DATE__`/`__TIME__` baked into
  `.rodata`, so two builds in the same container differ. `SOURCE_DATE_EPOCH`, `-fno-record-gcc-switches`,
  `-ffile-prefix-map` and `-fdebug-prefix-map` are what make the binary reproducible, and the container
  pins the toolchain those flags are applied by.]**

Build `solve.c` inside the container **with the deterministic flag set**; the same container + same
source + the same `SOURCE_DATE_EPOCH` → bit-identical binary on any host. Publish the container image digest alongside `CANONICAL_HASHES.md`. This is the gold standard for scientific reproducibility (used by Nature/Cell/CodeOcean submissions, Bitcoin Core, Debian package builds).

Effort: ~2–4 hours of one-time Dockerfile setup, then zero ongoing cost. Status: deferred pending operator authorization; if shipped, a future deeper canonical's pre-launch checklist gains a "build container image digest" gate.

#### Canonical pipeline runbook (added 2026-05-17, post-#81 v2 saga)

For the operational mechanics of running a canonical enumeration ≥11.2T — pre-launch checklist, recovery procedures, trap discipline, three-tier storage redundancy, the specific failure modes that have actually occurred in practice — see **`roae-private/CANONICAL_PIPELINE_RUNBOOK.md`** (private staging repo). The cross-build regression gate above is the build-side reproducibility guarantee; the runbook is the run-side operational guarantee. The runbook was forced into existence by the v2 11.2T re-derivation saga (2026-05-16/17, ~$18 across four attempts vs ~$5 first-shot expected) — every failure mode it documents corresponds to a real overrun.

The runbook's mandatory invariants for canonical runs:

- Enum OS disk: explicit `--storage-sku StandardSSD_LRS` (Azure defaults `s`-suffix VMs to Premium_LRS otherwise)
- Shards on attached managed disk (`solver-data-westus3`), not the enum VM's OS disk
- ERR trap preserves the enum VM (never auto-`teardown_enum`); recovery from Phase 2 errors is then a $0.50 Phase-2-only re-run instead of a $4 enum redo
- Cold-archive upload via streaming `curl -T file` (NEVER `--data-binary @file` — OOMs at 2 GB+)
- Mount logic handles existing-ext4 (operator data on solver-data); write canonical outputs to `$ARCHIVE_PREFIX/` subdirectory
- Mandatory $0.02 D2 pre-flight test of the critical-path commands before committing to a 4h+ canonical enum
- Triple-redundancy archival: managed disk + cold archive + claude `/tmp` (size-permitting)

The corresponding operator-memory entry at `feedback_canonical_pipeline_pattern.md` codifies the same rules for Claude.

### Resume-path defense in depth (added 2026-05-14, post-Phase E.2)

The c34390c0 / f7b8c4fb undercount investigation (Phase B re-derivation + Phase E mechanism validation, May 12–14 2026) demonstrated empirically that pre-`c3ad271` solve.c code had at least **two distinct resume-path bugs** that produce silent or noisy data loss: `c3ad271` bug 2 (in-process merge cross-ref rejection in v1 recursive path → loud abort) and `c3ad271` bug 3 (off-by-one frame budget in v2 iterative path → silent record loss). Both fixes are in `main` since May 1 2026. This section documents the five defense-in-depth measures that protect against future regressions of this class.

| # | Item | Status | Where |
|---|---|---|---|
| 1 | Checkpoint-resume equivalence in selftest (**no signal sent** — see 1b) | **DONE** 2026-05-14 (verified PASS on post-fix code) | `solve.c` `--selftest-resume` subcommand |
| 1b | SIGTERM-mid-walk eviction-resume invariance | **DONE** (subtest 8 of 9) | `solve.py --extended-selftest <solve-binary>` subtest 8 (`proc.terminate()` mid `--branch` walk, then resume) |
| 2 | Build provenance + resume history in `.sha256` metadata | **DONE** 2026-05-14 (verified emits all fields) | `solve.c` — auto-merge sha-write site + `write_sha256_with_metadata` + `SOLVE_RESUME_HISTORY` env var |
| 3 | Resume-state invariant assertions | **DONE** 2026-05-14 | `solve.c` — DFS resume entry in `backtrack` |
| 4 | Canonical merges off Spot priority | **DONE** (standing operational policy, codified here 2026-05-14) | this doc + operational practice |
| 5 | Differential per-sub-branch checksum during resume | **DONE** 2026-05-14 (4/4 test cases PASS) | `solve.c` `--emit-shard-manifest` + `--verify-shard-manifest` subcommands |

#### ⚠ `--selftest-resume` IS BLIND TO THE `#167` GUARD — measured 2026-09-05, use `scripts/selftest_resume_167_gate.sh`

**`--selftest-resume` cannot see whether the `#167` zero-yield guard fired, and it passes either way.**
Measured on both binaries: the pre-fix and post-fix builds BOTH return PASS with the *same* solutions
sha `b3862357fbde42e7743e219508ede16099b8934ebdf6cbcfc7dd051f8eca4072`, and `--selftest-resume-d3` is blind the same way (both PASS, `c37e3ea6cfc80816de187dfd0361c1ab2890d0f3f5d47e262b1f7ec23b67dd85`). Two
independent causes, and neither is incidental:

* the three child runs log to `phase_?.log` **inside their tmpdirs**, and the driver `rm -rf`s both
  before returning — so the guard's output cannot reach the caller on any binary. On the pre-fix
  binary the guard fires **1,933 times** in PHASE_B and every one of those lines was being deleted.
* the sha comparison is **insensitive by construction**: discard-and-re-walk produces the single-shot
  set by design, so the `#167` fix changes **work**, not **output**.

**Use `scripts/selftest_resume_167_gate.sh`.** It counts shard-less sidecars from the FILESYSTEM
(independent of the guard, so it does not learn its subject from the thing under test), reads the
guard's own counts from `phase_b.log` BEFORE deletion, and computes excess work from a per-run
quantity — never `prior_nodes_walked`, which is cumulative and reads budget−1 whether a cell resumed
or re-walked. Verdicts `SELFTEST_RESUME_167=PASS|FAIL|VACUOUS`; **`VACUOUS` (rc 42) is the point** —
it refuses to report success when nothing was exercised.

Measured 2026-09-05, both pinned in the script header: **fixed → PASS** (`R=Z=1933, D=0,
EXCESS=3,030`, exactly one node per resumed cell); **pre-fix → FAIL** (rc 40; `R=0, D=1933,
EXCESS=31,897,530`, exactly 1,933 × 16,501 — every zero-yield cell re-walking its whole PHASE_A budget,
63.8% of the 50M budget redone). **7 of 7 mutants killed**, including the two that today's
`--selftest-resume` passes: deleting every zero-yield sidecar, and stripping the guard lines from the
log, both return VACUOUS rather than PASS.

🔴 It runs enumerations, so it is **VM-only** — it cannot be a pre-commit hook, and it is not wired
into any suite. Run it beside `--selftest-resume` when touching the resume path.

#### Item 1: checkpoint-resume equivalence in selftest (`--selftest-resume`) — DONE

**Goal:** convert the c34390c0-class failure mode from "discovered weeks later via cross-build" to "caught at CI time before any canonical work."

**Scope — read this before relying on it.** `--selftest-resume` sends **no signal**. PHASE_A exits normally at its node limit and PHASE_B resumes from the checkpoint it left behind; `grep -nE 'kill|SIGTERM|signal' ` over the subcommand's whole range in solve.c returns nothing. What it proves is *checkpoint-resume equivalence*, not interruption safety. Signal interruption is a materially different path — an eviction can land mid-write, between a shard's `.bin` flush and its `.dfs_state` write, which is why the write-order invariant exists at all. The SIGTERM exercise lives in Python: `python3 solve.py --extended-selftest ./solve`, subtest 8 of 9 ("eviction-resume invariance (SIGTERM mid-walk)"), which `proc.terminate()`s a `--branch` walk mid-flight, resumes it, and requires the resumed sha to equal the clean-run sha. **Any change touching signal handling or checkpoint write ordering must run both gates**, not just the C one.

**Implementation:** subcommand `./solve --selftest-resume` (solve.c, near the existing `--selftest` block). Three `system()` invocations: (1) PHASE_A `SOLVE_NODE_LIMIT=50000000` in a tempdir, (2) PHASE_B `SOLVE_NODE_LIMIT=200000000` in the same tempdir (resumes from PHASE_A's checkpoint), (3) single-shot `SOLVE_NODE_LIMIT=200000000` in a fresh tempdir. All four runs use `SOLVE_THREADS=4 SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1`. Compares the two solutions.bin shas. Match → PASS; mismatch → FAIL with diagnostic citing Phase E.2.

**Verified 2026-05-14:** on post-fix code (current main), `--selftest-resume` produces sha `e43f2905ba8f2cb64a4f0691baae78cadd709058bf8f7c0ada6bcbc6058f34e9` for both the resume and single-shot paths (PASS). This sha matches the reference value in the `c3ad271` commit body, confirming the test targets the historically-buggy code path.

**Wall time:** 3 min 3 sec on a 2-ARM-core / 4-thread `claude` orchestrator. Faster on more-core boxes. Acceptable for a daily / pre-merge CI step; too slow for every-push pre-commit on small boxes. Recommended cadence: include in `make check` or weekly CI, not every commit.

**Future:** add to pre-commit hook (alongside `--selftest`) once a faster scale (e.g., 20M → 50M) is empirically tuned. Phase E.2 used 50M → 200M because that's the exact ratio the c3ad271 fix commit validated at; smaller scales may not exercise enough BUDGETED sub-branches.

#### Item 2: Build provenance + resume history in `.sha256` metadata

**What changed 2026-05-14:** `write_sha256_with_metadata` (in solve.c — locate by name, `grep -n write_sha256_with_metadata solve.c`; defined at ~line 9718 as of 2026-08-09, cited here as ~3537 before the function moved) now records `SOLVE_DFS_ITERATIVE`, `SOLVE_DFS_CHECKPOINT`, `SOLVE_PER_SUB_BRANCH_LIMIT`, and a `SOLVE_RESUME_HISTORY` line populated from the env var of the same name. Existing fields (date, build, git hash, record count, node count, branches done, `SOLVE_NODE_LIMIT`, time limit, threads) are preserved.

**Operator responsibility:** when restarting a canonical run after Spot eviction or any other interruption, set `SOLVE_RESUME_HISTORY` before the restart. The value is free-form text — recommended format: a comma-separated list of resume events with UTC timestamps and trigger. Examples:

```bash
# After Spot eviction at 90%
SOLVE_RESUME_HISTORY="2026-05-14T18:23:00Z=spot-eviction-at-90%" \
    ./solve 0 64

# After two interruptions
SOLVE_RESUME_HISTORY="2026-05-14T18:23:00Z=spot-eviction-at-90%, 2026-05-14T20:11:00Z=oom-kill-during-merge-stage" \
    ./solve --merge
```

**Schema captured in `.sha256` sidecar (post-2026-05-14):**

```
# Date: <UTC ISO8601>
# Build: <gcc date> <gcc time> (git: <hash>)
# Record format: 32 bytes packed (pair_index<<2 | orient<<1)
# Unique orderings: <count>
# Nodes explored: <count>
# Branches: <total> total, <completed> completed
# SOLVE_NODE_LIMIT=<N>
# Time limit: <seconds> (or absent for time-unlimited)
# SOLVE_THREADS: any (output is thread-independent with node limit)
# SOLVE_DFS_ITERATIVE=<0|1>
# SOLVE_DFS_CHECKPOINT=<0|1>
# SOLVE_PER_SUB_BRANCH_LIMIT=<N>   (only if > 0)
# SOLVE_RESUME_HISTORY: <free-form, "(none — clean single-shot run)" if env var not set>
```

**Future extensions (Item 2 follow-ups, not yet landed):** host fingerprint (CPU model + microcode + kernel version), per-sub-branch checksum manifest reference (see Item 5), VM provider + region + Spot/Regular priority. None of these block landing the schema above.

#### Item 3: Resume-state invariant assertions

**What landed 2026-05-14 (solve.c:`backtrack`, around the DFS-state-resume entry point):**

- Assert `dfs_resume_partition_prefix_len > 0` whenever `dfs_resume_active` is set. A zero value here would silently mis-index `dfs_resume_frames` — exactly the failure-class behind c34390c0/f7b8c4fb's silent data loss.
- Assert each consumed frame's `(pair_idx, orient)` is in valid range `[0, 31] × [0, 1]`. A malformed frame would mis-encode the saved iterator and skip work.

Violation → `_exit(21)` with diagnostic to stderr (distinct from existing exit codes; identifies this rule). Refuses to continue rather than producing a silently-corrupted solutions.bin.

**Future invariant additions (not yet landed):** post-`load_sub_checkpoint` assertion that `branch_nodes ≤ stored_budget` (catches the bug 3 mechanism class at load time, not just at use time); cross-check that the number of `dfs_state` files matches the expected per-thread count after a PHASE_A→PHASE_B handoff.

#### Item 4: Canonical merges off Spot priority

**Standing policy (codified 2026-05-14, was de facto since Phase B):**

- **Enumeration phase** (sub-branch DFS, parallel, OK to evict mid-walk): Spot priority is required (CLAUDE.md cost-control rule). The mid-walk checkpoint capability (`SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1`) handles eviction-recovery safely on post-`c3ad271` code.
- **Merge phase** (`solve --merge`, single-threaded, eviction-fragile): **Standard (non-Spot) priority is required.** A merge that is evicted leaves a partial solutions.bin and re-running it costs 60+ minutes per attempt. The cost difference between Spot D32 ($0.30/hr) and Standard D32 ($1.30/hr) for a 60-minute merge is $1 — trivial vs the risk of corrupting a canonical artifact.

**Operator pre-flight gate (manual, mandatory):** before launching any canonical-scale `solve --merge`, run `az vm show --query priority -o tsv` on the target VM. If output is anything other than `null` or `Regular`, stop and switch to a non-Spot VM.

**Past incidents this rule exists to prevent:** the 2026-04-29 cascade-build-a Spot eviction during the c34390c0 generation's merge phase (one of several contributing factors to the +1,030 record deficit). Pre-Phase-E, this was a soft preference; post-Phase-E it's a hard policy.

#### Item 5: Differential per-sub-branch checksum during resume — DONE

**Implementation:** two subcommands in solve.c:
- `./solve --emit-shard-manifest [path]` — scans `sub_*.bin` in CWD, computes sha256 + size per shard, writes a tab-separated manifest (default `shard_manifest.txt`): `<filename>\t<size>\t<sha256_hex>` per line.
- `./solve --verify-shard-manifest [path]` — reads the manifest and, for each entry, asserts: (1) shard exists, (2) current size **equals** stored size ⚠ **[CORRECTED 2026-09-03 — this read "current size ≥ stored size (legitimate resume only grows shards)", which is now the OPPOSITE of the shipped verifier (Codex V2-F15 #7 / V2-L05 #3). Since the Q-367 fix, growth is classified `DIVERGED` unconditionally — `solve.c` prints `DIVERGED <shard> grew-to-<n>-bytes-manifest-says-<m>` and exits 22. That is deliberate: a silent append was a false-accept, because the merger globs the enlarged file and the extra records enter the merged result.]**, (3) sha256 of the first `<stored_size>` bytes matches the stored sha256 (catches mid-write corruption + bug-2-class cross-ref divergence). Any failure → `_exit(22)` with diagnostic.

**Workflow for resume-protected canonical runs:**
1. After PHASE_A enum completes: `solve --emit-shard-manifest shards.manifest`
2. (Optional Spot eviction + reallocation. Or asymmetric-extension PHASE_B at higher budget.)
3. Before PHASE_B merge: `solve --verify-shard-manifest shards.manifest`. Aborts loudly if any shard was modified since the manifest was emitted.
   🔴 **After an INTENTIONAL asymmetric extension (step 2), RE-EMIT the manifest before verifying** —
   `solve --emit-shard-manifest`. Growth is `DIVERGED` by design since Q-367, so verifying an extended
   shard set against the pre-extension manifest fails by construction. Without this step an operator
   either discards legitimately extended shards as corrupt, or bypasses the integrity gate to get past
   it — and the bypass is the dangerous one.

**Verified 2026-05-14, four test cases:**

| Case | Action | Result |
|---|---|---|
| Positive | No corruption | PASS — 1097 entries, 0 missing/shrunk/diverged |
| Negative 1 | Append bytes to a shard | **FAIL — append rejected**, `DIVERGED … grew-to-N-bytes-manifest-says-M`, exit 22 ⚠ **[the 2026-05-14 run recorded "PASS — append accepted"; Q-367 reversed this deliberately, because the merger reads the enlarged file and the appended records would enter the merged result. Re-verified 2026-09-03.]** |
| Negative 2 | Truncate a shard to 10 bytes | FAIL — `1 shrunk` detected, exit 22 |
| Negative 3 | Modify the first 4 bytes of a shard | FAIL — `1 diverged` detected, exit 22, diagnostic prints both shas |

**Coverage semantics:** the byte-prefix manifest verifier accepts legitimate resume (shard grew) but rejects all bit-level corruption modes of PHASE_A's content (disappeared, shrunk, first-N-bytes diverged). Byte-prefix sha256 over N bytes of a 32-byte-record file IS mathematically a record-level integrity check for those records — sha256 of the byte-prefix and the chain-hash of the individual records are equivalent. So PHASE_A's recorded content is integrity-protected at the record level by this scheme.

**The class byte-prefix CANNOT catch by itself** is semantic: PHASE_B emitting INVALID extra records (records that don't satisfy C1-C5) in the region beyond PHASE_A's boundary. No checksum scheme catches that without a reference to what the "correct" extra content should be (which would require re-running the canonical). This is closed at a different layer: **`solve --verify solutions.bin`** runs C1-C5 structural verification on every record, catching any invalid record emitted anywhere in the file — including the PHASE_B-new region.

**Recommended post-merge integrity gate for any canonical run that went through interruption + recovery** — the two-step sequence:

```bash
solve --verify-shard-manifest shards.manifest   # bit-level integrity of PHASE_A's content
solve --verify solutions.bin                    # C1-C5 structural check of all records
```

Run both; both must pass. The first catches any corruption of PHASE_A's recorded content; the second catches any invalid record emitted anywhere in solutions.bin, including the PHASE_B-new region. (An earlier draft added a `--verify-resume` coordinator subcommand wrapping both; removed 2026-05-15 as redundant — the two-step recipe here is the same thing without adding a maintained subcommand.)

**Cost:** zero at canonical time. Manifest write is O(shard count); manifest verify is O(shard count × shard size) with streaming sha256; structural verify is O(record count) running the same C1-C5 logic as the existing `solve --verify` mode.

### Phase 1 speedup benchmarking methodology (2026-05-15)

Each Phase 1 sha-preserver gets two gates: (a) **sha preservation** at canonical params (the existing plan), and (b) **quantified speedup** vs the v1 baseline (operator request 2026-05-15). Sha preservation is binary (PASS/FAIL); speedup is a measured ratio reported against a **noise floor** (coefficient of variation, below) — not a confidence interval: no distributional quantile is computed and no interval is placed on the ratio itself.

#### Benchmark protocol — codified in `v2_bench_d64.sh` (private repo)

The full protocol lives in the private operational repo at `petersm3/roae-private:v2_bench_d64.sh`. It runs as `./v2_bench_d64.sh <binary> <node_limit> <output_tsv>`. Per-trial discipline encoded into the script (so any future session running it inherits the same rigor):

| Element | Choice / Encoded in script |
|---|---|
| Workload | `SOLVE_THREADS=N SOLVE_NODE_LIMIT=B` at default depth-2; B picked per scale tier (see "Phase 1 scale tiering" below); N defaults to 64 (D64), overridable via env var |
| Trials | 4 per binary minimum (raised from 3 on 2026-05-15 — three trials had insufficient resolution to distinguish a cold-cache outlier from real variance); raise to 6-8 if speedup is suspected close to noise floor |
| Warmup | 1 discarded run per binary at 1/10 the trial budget |
| **Pre-flight: CPU throttling** | **MANDATORY.** Read `cpu MHz` from `/proc/cpuinfo`; abort if below `MIN_FREQ_MHZ` (default 2000). AMD Genoa healthy baseline is 3000-3700 MHz; throttled Spot hosts run at ~600 MHz (observed 3× during v1 Phase B in westus3 May 13-14). Re-checked before every trial — Spot evictions / co-tenant pressure can throttle mid-run. |
| **Pre-flight: no stale processes** | **MANDATORY.** `pgrep -af "solve\|bench"` must return empty (excluding the bench script itself + systemd-resolved). Stale orphan processes from prior work consume cores and bias the benchmark. (Lesson 2026-05-15 — see HISTORY.md §"Methodology lesson learned … (and contamination correction)".) |
| **Between trials of same binary** | `sync; echo 3 > /proc/sys/vm/drop_caches` (needs sudo) + `sleep ${COOLDOWN_SEC}` (default 60s). Clears page cache and lets thermal/frequency state settle to a comparable starting point for each trial. |
| **Between binaries** | Operator-driven: **reboot the VM** between binaries (`sudo reboot`; ~60-90 sec to SSH-ready). Each binary's 4-trial sequence then starts from full cold-state, so cross-binary comparison is fair. The bench script handles per-trial state within one binary; reboot orchestration is operator-managed (or could be wrapped by a higher-level script). |
| **Host fingerprint** | Captured per run: kernel, CPU model, microcode, core count, AVX-512 feature presence, binary sha + size, run params, CPU MHz at start. Written as `# ` comments at the top of the output TSV. Lets retrospective analysis correlate weird numbers with the specific physical Spot host. |
| Metric | wall time from `/usr/bin/time -f "%e"`; speedup = `mean(baseline_time) / mean(optimized_time)` |
| Reporting | TSV with per-trial wall time + cpu_freq_mhz at trial start; mean ± stddev computed offline. **Noise floor = coefficient of variation (CoV) = `stddev / mean`** — a relative-dispersion statistic, carrying no distributional quantile and placing no interval on the speedup ratio (see the caveat above the table); speedup ratios within that floor reported as "within noise" rather than as a positive result. |

> **The public harness cannot produce this number.** `scripts/perf_bench.sh` calls its
> `run_enum_only` exactly once per binary — one control run and one treatment run, no trial
> loop — so it yields no within-binary variance and therefore no noise floor at all. Its
> paired results are **screening-grade**: use them to decide whether a change is worth
> benching properly. Before a [PERFORMANCE_HISTORY.md](PERFORMANCE_HISTORY.md) entry claims a
> quantified speedup, run the 4-trial protocol above (`v2_bench_d64.sh`, private repo) and
> report the CoV alongside the ratio; an entry produced by `perf_bench.sh` alone must say so
> and must not quote a dispersion figure.

#### Phase 1 scale tiering on D64als_v7 64-thread

| Scale | Wall/trial | 4-trial × 3-binary cycle wall | Cost (Spot $0.50/hr) | Purpose |
|---|---|---|---|---|
| 100M | ~5-10s | <2 min | ~$0.02 | sha preservation only (selftest scale); too short for speedup signal |
| 10B | ~10-15s | ~3-4 min | ~$0.03 | quick sanity sweep |
| **100B** | **~1-2 min** | **~30-40 min** | **~$0.25-0.33** | **default Phase 1 speedup measurement** — long enough to escape startup-dispatch noise, fast enough for iterative AVX-512 dev |
| 1T | ~12-15 min | ~3 hr | ~$1.50 | canonical-correlation confirmation (run once per Phase 1 task after the 100B numbers settle) |
| 11.2T canonical | ~77 min | ~15 hr | ~$7.50 | mandatory sha-preservation regression — operator-gate, not iterative |

Recommended workflow during AVX-512 dev (Phase 1a, 3-5 days engineering): provision one D64 Spot VM, leave it running for the session, iterate at 100B between code changes (~30-40 min per cycle), then run 1T once at the end of each binary's tuning to confirm canonical-scale behavior. ~$5-15 in compute for the whole Phase 1a depending on session length.

Reboot-between-binaries operator pattern:

```bash
# On D64 VM, post-provisioning:
./v2_bench_d64.sh /path/to/solve_baseline 100000000000 baseline.tsv
sudo reboot
# wait ~60-90 sec, SSH back in
./v2_bench_d64.sh /path/to/solve_avx512 100000000000 avx512.tsv
sudo reboot
./v2_bench_d64.sh /path/to/solve_pgo 100000000000 pgo.tsv
# offline analysis: compute mean/stddev/speedup from the three TSV files
```

#### Host strategy

- **`claude` orchestrator (D2as_v6, AMD EPYC Zen 4, 2 cores, x86_64):** has **full AVX-512** instruction support (F/DQ/BW/VL/VNNI/BF16/VBMI/VBMI2/BITALG/VPOPCNTDQ — the complete Zen 4 stack), plus AVX2, FMA, BMI1/2, popcount. Suitable for **all sha-preservation regression at selftest scale** AND **AVX-512 development + selftest-scale speedup measurement**. The "scalar fallback path for ARM" plan element from the original V2_IMPLEMENTATION_PLAN_2026_05_06.md is still relevant for actual Cobalt ARM hosts (D-ps-v6 / Cobalt 100 family) — but claude is not one of those; its 2 cores run the full AVX-512 path natively. Wall time on claude is ~45–50s per 200M-node depth-2 trial (after correcting for benchmark contamination 2026-05-15); a full Phase 1 4-trial benchmark completes in ~3-4 minutes.
- **x86 Spot D-series in westus3 (D32 or D64als_v7):** required for **canonical-scale (11.2T) sha-preservation regression** (claude has only 2 cores, can't realistically complete 11.2T in operator-friendly time) and for **AVX-512 actual canonical-scale speedup measurement** (Genoa AVX-512 throughput varies by core count + boost behavior; the 11.2T pilot is the operator-meaningful number). Cost: ~$1.50 per pilot run.
- **Cobalt ARM Spot (Dpsv6 family) in westus3:** required for cross-arch validation that the AVX-512-or-scalar fallback path produces identical sha on ARM. The plan's "validate scalar fallback on ARM" task lives here, not on claude (which is x86 and would never exercise the scalar fallback).

#### Per-Phase-1 task — what gets measured

- **#46 AVX-512:** baseline scalar vs AVX-512-enabled. Speedup expected 1.4–2.0× per the implementation plan; will validate empirically. ⚠ **[REFUTED 2026-05-16 — it was validated empirically, and the expectation did not survive. The definitive 1T paired bench put AVX2 at 433.0 s against AVX-512 at 434.6 s (**0.9963×**, Welch t = −1.281, 95% CI [−4.05, +0.85] s, null not rejected); #46 was closed via REVERT. Root cause: gcc 13.3 with `-march=native` already auto-vectorizes the one loop that benefits, so the scalar baseline was never scalar. The task description above is preserved as written; the AVX-512 host guidance earlier in this section remains accurate as a statement about instruction support, but no longer implies pending speedup work. This callout added 2026-09-02; it was the last of the three 1.4–2.0× sites left unmarked after prose batch P64 marked the two in HISTORY.md.]** Development + selftest-scale benchmarks happen on `claude` directly (full AVX-512 stack supported). Canonical-scale speedup measurement on D64als_v7 Spot in westus3 ($1.50, 1.5h). Scalar-fallback cross-arch validation on Cobalt ARM (Dpsv6) — that's the "did the fallback regress when we added the AVX-512 path?" check, not the speedup measurement.
- **#47 LTO:** baseline `-O3 -march=native` vs `-O3 -flto -march=native`. Speedup expected 0–5% (LTO mostly helps cross-translation-unit optimization; single-file project gets modest gains from extra dead-code elimination + cross-function inlining beyond `-O3`'s defaults). On claude.
- **#47 PGO (profile-guided optimization):** baseline `-O3` vs `-O3 -fprofile-generate` → run profile workload → `-O3 -fprofile-use`. Speedup expected 5–15%. On claude. **Build invariant (added 2026-05-24 after the silent no-PGO incident):** use `scripts/build_pgo.sh` for all PGO builds. Under `-flto`, GCC keys the `.gcda` lookup on the output binary's name; if Pass 1 and Pass 2 use different output names (e.g., `solve_inst` vs `solve_U`), Pass 2 silently misses the profile data and falls back to no-PGO with a one-line warning. The helper enforces three rules: (1) same output name in both passes (rename after), (2) `-Werror=missing-profile` on Pass 2 so any future regression fails the build loud, (3) assert `.gcda` count > 0 between passes. Past incident: the v1-vs-v3 paired bench 2026-05-24 measured only +4.38% v3 advantage (vs predicted +9.2%) because PGO silently didn't apply. See `roae-private/V1_V3_PAIRED_BENCH_RESULTS_2026_05_24.md`.
- **#47 huge pages + NUMA:** runtime-environment changes (transparent huge pages, NUMA pinning); benchmarked on the host where they actually apply (D-series VM with NUMA-aware OS).

#### Reporting template (one row per Phase 1 task)

```
| Task | Host | Workload | Baseline (s) | Optimized (s) | Speedup | Notes |
|---|---|---|---|---|---|---|
| #47 LTO | claude D2as_v6 2-thread | 200M nodes depth-2 | <mean ± stddev> | <mean ± stddev> | <ratio> | sha preserved at selftest (403f7202) and at 11.2T regression: <PASS/FAIL/pending> |
```

Each row is appended to a "Phase 1 speedup measurements" table in `HISTORY.md` as each task's data lands.

#### What's measured vs what's claimed

- **Measured:** end-to-end wall-clock speedup on the specific benchmark workload on the specific host.
- **Not claimed without further work:** speedup at canonical 11.2T scale (different memory profile, different per-sub-branch budget, may differ); speedup on hardware not tested (need separate runs per CPU family for AVX-512).

Multi-task composition (e.g., AVX-512 + LTO + PGO together) gets its own line in the table — not assumed multiplicative until measured.

### v1 vs v2 search-space efficiency measurement (planned 2026-05-15, implemented alongside v2)

When v2 lands (after the K-pilot decision and v2 bundled re-baseline), the operator will want to compare v1 and v2 search efficiency — specifically: *given a v1 canonical at budget B finding N records, what is the smallest v2 budget B′ that produces the same N (or a superset of v1's exact records)?* This section documents the design for that measurement so the tooling can land alongside v2 implementation rather than be retrofitted later.

#### Two reasonable questions, two precision levels

1. **Count-matching K (cheaper):** what v2 budget B′ yields the same *number* of unique valid records as v1 at budget B? Answer: K = B / B′.
2. **Set-matching K (stricter):** what v2 budget B′ yields a *superset* of v1's exact records at budget B?

For pure-pruning v2 (skips only doomed subtrees, preserves DFS order), set-matching and count-matching converge — v2's leaf set at any budget is a superset of v1's at the same budget. For v2 that *also* changes DFS order (e.g., #69 variable ordering heuristic), set-matching is strictly harder than count-matching; the two can give different K values at small budgets. Both are useful to measure.

#### Recommended approach: opt-in leaf-rate logger in both binaries

Add an opt-in env var `SOLVE_LEAF_RATE_LOG_INTERVAL_NODES` (default `0` = disabled, sha-preserving) to both v1 and v2 solve.c. When set to a positive integer N, the existing `update_progress()` callsite (solve.c — the single callsite, in the rate-limited thread-0 branch of the sub-branch completion path; ~line 8926 as of 2026-08-09, `grep -n update_progress solve.c`; cited here as ~2560, which in the 2026-05-15 tree was the *definition* — the single callsite there was solve.c:2813, unconditional on every sub-branch completion, and that is the cadence still assumed below) also appends one line to `leaf_rate.log`:

```
<elapsed_seconds>\t<total_nodes_walked>\t<sub_branches_done>\t<solutions_c3_so_far>\t<UTC_timestamp>
```

Implementation: a few LoC of additions to `update_progress()` gated on the env var being non-zero. Both v1 and v2 binaries produce comparably-formatted logs. Reuse the existing periodic-checkpoint cadence (every sub-branch completion → progress + checkpoint update); the log just gets one extra append.

#### Post-processor (`solve.py --compare-leaf-rates v1.log v2.log`)

Reads both logs, builds two interpolation curves `leaf_count_v1(nodes)` and `leaf_count_v2(nodes)`. Outputs:

- **K(N) for each leaf count threshold N:** the v1 node count to reach N leaves divided by the v2 node count to reach N leaves
- **Targeted answer for canonical comparison:** "v1 at 11.2T finds 759,608,573 records; v2 reaches that count at B′ ≈ X.XX T" (interpolated from v2's log)
- **Per-leaf-count K curve plot:** ASCII / matplotlib if available

#### What this measures and what it doesn't

**Measures:** count-matching K from instrumented v1 and v2 runs at the same scale. With pure-pruning v2 (no DFS-order change), this is also the set-matching K because v2's coverage is a strict superset of v1's at the same budget.

**Doesn't measure (without further instrumentation):** set-matching K when v2 changes DFS order. For that, v2 would need to emit per-record timestamps (`solutions.bin` companion: `solutions.timestamps.bin`, one int64 per record = node count at which v2 first produced this record). Lookup each v1 canonical record in v2's timestamp map, take the max — that's the set-matching B′. This is heavier instrumentation but exact. Sidecar size = `records × 8 B`: at the v1 11.2T record count this section already uses above (759,608,573) that is **6.08 GB (5.66 GiB)**, not the ~30 GB an earlier revision of this line asserted. The v2 count at the same budget is unknown until v2 exists — size it from v2's own measured count when the time comes, and note that ~30 GB would require ~3.75 billion records, roughly 4.9× v1's.

#### Sequencing

- **Now (free):** design captured here.
- **When v2 work starts:** implement the leaf-rate logger in both v1 and v2 simultaneously (~50 LoC each, opt-in, sha-preserving). One pre-K-pilot v1 baseline run with the env var set produces the v1 reference log.
- **Post-K-pilot:** run v2 with the same env var, run the comparator. Output is the K curve and the "v2 budget to match 11.2T v1" answer.
- **If set-matching precision is needed:** add per-record timestamp emission to v2 only (~50 LoC + a lookup utility in solve.py).

#### Pre-implementation cheaper proxy — "shadow v2" predicate evaluation

An even cheaper *pre-v2* tool would implement only the *predicates* of each v2 pruning rule (#67 mid-walk C3, #68 C5 feasibility, #70 C3 optimistic-completion bound, #71 C2 lookahead) in v1, evaluate them at each DFS step without applying them, and count how many subtrees v2 would have pruned. This gives a K estimate *before* committing to full v2 implementation. ~100 LoC per predicate, one instrumented v1 run at 1B nodes (~$0.50). Recommended as a decision input *before* v2 K-pilot if the v2 implementation cost is significant; skip it if operator is committed to v2 regardless. Captured here for completeness; not the recommended primary measurement.

### Layered enumeration (extension-friendly run organization)

A "layer" is a single `(scope, per-sub-branch budget)` enumeration result.
Layers compose: a later layer can extend an earlier one with higher budget
(or different scope) without destroying the earlier layer's data. This is
how to organize runs that may need to be extended later.

**Layer = directory.** Each layer lives in its own subdirectory under a
`<run_root>/`. Convention: name layers so lexical sort = intended order.

```
<run_root>/
  01_full_5T_2026_04_29/        # layer 0: full enumeration, 5.6T budget
    sub_*.bin                   #   ~158K shards
    checkpoint.txt
  02_extend_dead_50T_2026_04_30/  # layer 1: extension, higher budget on subset
    sub_*.bin                   #   shards only for the extended sub-branches
    checkpoint.txt
  _merged_/                     # produced by --merge-layers
    sub_*.bin                   #   symlinks to winning layer's shards
    solutions.bin
    MANIFEST.txt                #   records which layer won per shard
```

**Eviction recovery is NOT a new layer.** A spot-VM eviction → restart →
checkpoint resume continues writing into the same layer dir. Same scope,
same budget, same data continuation. New layer only when the operator
intentionally chooses a new `(scope, budget)` pair.

**Merge:** `solve --merge-layers <run_root>` — 🔴 **`<run_root>` MUST BE AN
ABSOLUTE PATH.** The winners are installed as symlinks whose target is built as
`<layer_path>/<shard>` (`solve.c`, the `--merge-layers` walk), so a *relative*
run_root yields targets that resolve relative to `_merged_/` — **100% of the
winner symlinks dangle**, and the run then aborts on the first override with
`ERROR: symlink … File exists` (exit 20), because a dangling `dst` makes the
`access(dst, F_OK)` override check false so the `unlink` never happens. Measured
2026-09-03 (Codex V2-F15 #10); `solve.c` does not `realpath()` the layer root, so
this is a live constraint on the caller, not a historical note. Given an absolute
run_root it walks the layer subdirs in sort order; for each sub-branch tuple, the LAST layer to contain a shard
wins. Winners are symlinked into `<run_root>/_merged_/`, the standard
merge runs in that dir, and produces `<run_root>/_merged_/solutions.bin`
plus a `MANIFEST.txt` recording each shard's source layer. The result is
deterministic — given the same set of layers, the merged sha is stable.

**Extending a run:** to raise the per-sub-branch budget on some subset of
sub-branches, create a new layer dir and run `solve --branch <p1> <o1>` (or
the full enum scoped to a subset) with `SOLVE_PER_SUB_BRANCH_LIMIT=<higher>`.
The new layer will only contain shards for the extended sub-branches; the
earlier layer's shards remain authoritative for everything else.

**Rollback** is `rm -rf <new_layer>` (and `_merged_/`); the prior state is
intact. Compared to in-place extension (which would overwrite the earlier
shards), this is non-destructive.

### Storage strategy: parallel redundancy and long-term archival

> **Status: DEPLOYED — this is current policy, not a proposal.**
> Cold-blob archival has been in production since the June–July 2026
> campaign. [CANONICAL_HASHES.md](CANONICAL_HASHES.md), not this section, is
> the authority on what exists. Every active-lineage canonical scale has
> `canonical-archive/…` entries there — d3 560T holds a warm gzip mirror plus a
> cold blob for the original campaign **and** for the byte-identical 2026-06-30
> re-run; d3 100T a cold blob whose presence was re-verified live 2026-07-17
> (plus a known byte-redundant duplicate); d3 11.2T a build-A/build-B pair, a
> witness-only v3 upload and the 2026-05-31 dress rehearsal; d3 10T, d3 5.6T
> and d2 10T a build-A/build-B pair each. Read the counts off that file rather
> than from here: it also lists the CLOSED v2-lineage archives and one path
> (`canonical-archive/20260530_100T_revalidation_4e15885/`) that its own note
> records as never populated, so a raw grep over-counts. Uploads run from **one** implementation —
> `roae-private/scripts/lib/archive_canonical_lib.sh` in the private operator repo
> (`~/github/roae-private/`, not committed here). Do not write a second
> uploader; a divergent second path is how an archive stops matching its
> catalogue. The flow written out below is the **original 2026-04 design**,
> kept because its folder taxonomy and tier economics are still the ones in
> use — read it as the design record, and read CANONICAL_HASHES.md for state.

⚠ **[CORRECTED 2026-09-02 — the banner above previously carried a status of
OPTIONAL / ASPIRATIONAL, described the Azure Blob Archive flow as a backup tier
that had been designed but never stood up, and stated categorically that the
working copy on the `solver-data` managed disk was the project's sole
redundancy tier. Both statements were the exact inverse of the catalogue by the
time anyone was likely to read them, and the cost of believing them is the
reason this is a correction rather than a silent edit: an operator responding to
an incident would have declared recoverable data lost, or re-paid to archive
what was already archived. The retired phrasings are registered in
[RETRACTED_PHRASES.tsv](RETRACTED_PHRASES.tsv) and keyed in
[CORRECTIONS.md](CORRECTIONS.md) as `RP-456ed634` (the undeployed-status phrasing) and
`RP-2e39a795` (the sole-redundancy-tier phrasing). Origin is
stale-ledger residue, not a wrong measurement: the archival campaign ran June–
July 2026 and never swept this May-era section — the same shape as the
`needs_generated` staleness recorded under §"Git hooks". Found by Codex review
V2-F15 #9. Note that one site of this defect was already repaired: the
historical paragraph further down carries a *Superseded:* note added by an
earlier pass, which fixed the sentence "No run has yet been archived" and left
the banner — that sentence has zero matches corpus-wide today while the banner
survived, which is why this correction exists at all.]**

The managed disk is the *working* copy of large artifacts, not the *durable*
copy. Two things would motivate a separate backup tier:

1. **Accidental deletion or corruption.** A disk wipe, a rogue `az disk delete`,
   or a mount-point bug can lose the primary copy in seconds. Managed disks
   have Azure's 11-9s durability guarantee, but the operator (me or a future
   session) is the real risk.
2. **Cost during long pauses.** At 23.7 GB (10T) or 80-260 GB (1000T), keeping
   a managed disk idle between sessions costs $0.04-0.40/GB/month. For a
   multi-month pause, that adds up fast. Blob Archive tier is ~40× cheaper
   per GB.

**Proposed parallel-backup policy (would run after any canonical run, once
we establish a canonical run and choose an automation mechanism):**

For every canonical enumeration (10T, 100T, 1000T, or any run that produces a
sha256 referenced in committed docs):

1. After sha256 verification of `solutions.bin` on the working disk,
   upload to Azure Blob Storage with the Archive access tier:
   ```
   az storage blob upload \
     --account-name <storage-account> \
     --container-name roae-archives \
     --name <run-id>/solutions.bin \
     --file /data/solutions.bin \
     --tier Archive
   ```
2. Alongside `solutions.bin`, upload (Archive tier for all):
   - `solutions.sha256` — validates any future download
   - `solve_results.json` — run metadata
   - The compiled `solve` binary used for the run (~100 KB)
   - `git rev-parse HEAD` written to a `git_hash.txt` (~50 bytes)
   - `checkpoint.txt` — per-sub-branch yield data (needed for saturation
     analysis at any future scale)
   - A README documenting run date, `SOLVE_NODE_LIMIT`, VM SKU, total cost
3. Sha-verify the upload by downloading the blob's sha256 file and comparing.
4. Once verified: the managed disk remains authoritative for active work;
   the blob is the durable backup.

*(Historical, 2026-04:* the 10T run `aa1415174c...b719b` (23.7 GB) was the
original archive candidate, but that sha is a hash-table-bug-era undercount —
see HISTORY.md Day 8 and SPECIFICATION.md §"Partial enumeration". *Superseded:*
runs at every canonical scale have since been archived to cold blob storage;
[CANONICAL_HASHES.md](CANONICAL_HASHES.md) lists the `canonical-archive/…`
container path for each.) At Archive-tier pricing (~$0.00099/GB/month) a 10T
backup is ~$0.02/month — essentially free insurance.

**Validation-first approach for major solver refactors.** When significant
enumeration-path refactoring occurs (e.g., the Option B depth-3 work-unit
rewrite for 100T), re-run the 10T enumeration with the new solve.c *before*
archiving and *before* deploying 100T. The acceptance target is the **current**
10T d3 anchor from [CANONICAL_HASHES.md](CANONICAL_HASHES.md) —
`b85c887128ce9881229741380a799c4e1608335df438cedc3da9e087fd94dbbc`,
706,427,594 records — **not** the deprecated `aa1415174c…` or `f7b8c4fb…`
shas that older revisions of this section named; reproducing either of those
would mean the refactor reproduced a known-bad artifact. If the retooled
solve.c produces the anchor sha, that proves the refactor did not alter
enumeration semantics. Only after this sha-identity check passes should the
10T output be archived and the 100T run deployed. The refactor might touch
infrastructure (checkpointing granularity, work-unit partitioning) without
changing the enumeration output; the sha-identity check distinguishes these
cases.

**Archive folder taxonomy.** For auditability and retrieval:
- Folder name: `<run-name>_<YYYYMMDD>_<sha8>/` where `sha8` is the first 8 hex
  chars of solutions.bin's sha256. Example: `10T_20260513_b85c8871/` (the live
  10T d3 anchor; see [CANONICAL_HASHES.md](CANONICAL_HASHES.md)).
- The sha8 in the folder name self-describes the run identity without opening
  blobs. Multiple runs with identical sha8 (deterministic re-validation) are
  distinguishable by date.
- Inside each folder: `solutions.bin`, `solutions.sha256`, `solve_results.json`,
  `checkpoint.txt`, `solve` binary, `git_hash.txt`, `README.txt`.

**Long-term pause procedure (when stepping away for weeks-to-months):**

1. Ensure the parallel backup above exists and has been sha-verified.
2. Optionally download a local copy to operator-controlled hardware (external
   SSD, home server) as a third tier of redundancy. Cost: one-time transfer.
3. **Do NOT delete the managed disk.** ⚠ **[CORRECTED 2026-09-02 — this step
   read "**Delete the managed disk** (only after both blob backup and, if
   chosen, local backup are verified)", justified by dropping storage cost
   from ~$0.04/GB/month to ~$0.001/GB/month, ~$64 over 6 months for 260 GB.
   That instruction contradicts the standing operator rule this repo states
   three times elsewhere — [DEPLOYMENT.md](DEPLOYMENT.md) §"Teardown" ("never
   delete data disks"), its retrospective ("Managed disks preserved = the win
   condition for every class of failure"), and its teardown script comments
   ("Never delete `solver-data`"). It was harmless while this section was
   labelled aspirational and became executable the moment the banner above was
   corrected to DEPLOYED, so it is corrected in the same pass. Found while
   verifying the banner, not by the review that filed the banner.]** Shrink the
   idle footprint by *resizing* the data disk down to what the retained
   artifacts need, or by detaching it; the disk itself is preserved. Every
   recovery this project has had — eviction, truncation, regex bug — was saved
   by `solver-data` outliving a VM.
4. Delete all VMs (their OS disks contain nothing campaign-related). Full idle
   state, data disk retained and unattached.

**Rehydration procedure (resuming work):**

1. Request rehydration from Archive to Hot tier:
   ```
   az storage blob set-tier \
     --account-name <storage-account> \
     --container-name roae-archives \
     --name <run-id>/solutions.bin \
     --tier Hot --rehydrate-priority Standard
   ```
   Standard priority: 1-15 hour wait, cheapest. High priority: <1 hour, costs
   a few dollars for multi-GB blobs.
2. Poll rehydration status: `az storage blob show --query properties.rehydrationStatus`
3. Create a new managed disk sized for the run (see "Running on cloud"
   section for sizing), provision merge VM, attach disk.
4. Download blob to disk inside the VM (free within-region egress, ~10-30 min
   at spot VM network speeds for 260 GB).
5. Sha-verify against the preserved `solutions.sha256`.
6. Resume.

**Cost-tier reference (westus2, April 2026 approximate):**

| Tier | $/GB/month | Min retention | Restore time |
|---|---|---|---|
| Managed Disk (Standard HDD) | $0.041 | none | instant (attach) |
| Blob Hot | $0.018 | none | instant |
| Blob Cool | $0.010 | 30 days | seconds |
| Blob Cold | $0.0036 | 90 days | hours |
| **Blob Archive** | **$0.00099** | **180 days** | **1-15 hours** |

Archive tier's 180-day minimum retention matches the "several months pause"
use case naturally. Shorter pauses may prefer Cold (90-day minimum) or even
keeping the managed disk.

**What we do NOT back up to archive:**

- The `claude` orchestration VM's OS disk (trivially reproducible via
  `git clone` and standard setup).
- Intermediate `sub_*.bin` shards when a merged `solutions.bin` exists. The
  merged bin is the canonical derived artifact; shards can be regenerated
  only by re-running the enumeration, which the sha256 of `solutions.bin`
  still anchors against.
- Analysis output text files (`analyze_*_742M.txt`) — these are committed to
  the git repo and live there.

---

## Canonical run discipline (added 2026-05-25 after the v3.1 hardening audit)

Every canonical-scale enumeration (≥1T `SOLVE_NODE_LIMIT`) MUST run in a clean, dedicated run directory. The solver enforces this in part with startup gates (LOCK file, `build.sha` check, `.budget` sidecar verification) — but those guard against subsets of the failure modes documented in the audit (`petersm3/roae-private:V3_1_HARDENING_AUDIT_2026_05_25.md`). One mode (Outlier #6: filename-pattern false-positive from foreign `sub_*.bin` files in the run dir) is intentionally NOT enforced in code, because a hard "empty cwd" gate would be too operator-unfriendly. Instead, follow this convention:

**One canonical campaign → one fresh subdirectory.** Pattern: `solver-data-westus3:/<YYYYMMDD>_<lineage>_<scale>_<campaign_id>/` (e.g., `20260521_v2_100T_buildA/`).

What goes in the run dir:
- The solver binary `solve` (or a build-recipe script that produces it)
- `solutions.bin` and `solutions.bin.sha256` (after the merge)
- Shard files `sub_*.bin` and `sub_*.bin.budget` (during enum; the `.budget` sidecars are MANDATORY post-2026-05-25 — `promote_orphaned_shards` refuses to promote a sub-branch without a matching-budget sidecar by default, since strict-default is the post-hardening behavior. Backward-compat escape via `SOLVE_ALLOW_MISSING_BUDGET_SIDECAR=1`. Both `.bin` and `.budget` can be deleted post-archive at operator discretion, except for v3 lineage where the convention is "preserve shards" per `project_v2_100T_precedes_560T` memory.)
- `checkpoint.txt` (always)
- `solve.lock` (during run only; auto-cleaned on normal exit)
- `build.sha` (always; first run creates it)
- Run-metadata file (operator-written, e.g., `RUN_METADATA.txt`, `WITNESS.md`)

What MUST NOT go in the run dir:
- Files matching `sub_*.bin` from another campaign. Even at a different scale, a manually-copied shard from another campaign with the same filename pattern would be picked up by `promote_orphaned_shards()` and merged into the final output, producing wrong-but-deterministic canonical bytes. The `.budget` sidecar partially mitigates (sidecar mismatch → refuse promotion), but a foreign shard with a coincidentally-matching budget would still slip through.
- Build artifacts or staging files matching the shard naming pattern.

If you're recovering from a failed run and need to combine partial shards from multiple attempts: do so in a freshly-created run dir, not in either source dir. The `solve --merge` step is meant to be the single point where shards meet `solutions.bin`; do the assembly explicitly.

For the 560T campaign specifically (per `project_560T_review_gate`): the run-dir convention is mandatory pre-launch and the dir must be created on `solver-data-westus3` immediately before the enum VM is provisioned — no shared / reused dirs. The strict-default `.budget` sidecar check means a fresh 560T enum doesn't need an explicit env var to opt into strict mode — strict is the default. Don't set `SOLVE_ALLOW_MISSING_BUDGET_SIDECAR=1` for 560T; let any missing-sidecar shard re-walk via the LOAD path.

### Auto-protect gates that fire on canonical-enum startup (added 2026-05-26)

Beyond the LOCK / `build.sha` / `.budget` gates above, six more dummy-proof gates fire automatically on every canonical-enum dispatch (no `--xxx` subcommand). Each has an explicit env-var escape; setting the escape is operator-acknowledgment of the failure mode being bypassed. See [SOLVE_C_CLI.md](SOLVE_C_CLI.md) "Hardening overrides" + "EXIT STATUS" for the full env-var / exit-code table.

| Gate | What it checks | Exit | Escape |
|---|---|---|---|
| Auto-selftest | Binary reproduces `--selftest` sha `403f7202…` | 24 | `SOLVE_SKIP_AUTO_SELFTEST=1` |
| Disk-space pre-check | `cwd` filesystem has projected required bytes free | 29 | `SOLVE_SKIP_DISK_CHECK=1` |
| Binary snapshot | Copies running binary to `solve.binary.snapshot` for forensics | (warn) | `SOLVE_SKIP_BINARY_SNAPSHOT=1` |
| Sub-canonical hard-gate | Refuses `SOLVE_NODE_LIMIT < 1T` without `SOLVE_PER_SUB_BRANCH_LIMIT` | 25 | `SOLVE_ALLOW_SUB_CANONICAL=1` |
| Shard manifest auto-verify | Existing `shard_manifest.txt` matches current shards | 22 | `SOLVE_SKIP_AUTO_MANIFEST=1` |
| Auto-emit shard manifest | Writes `shard_manifest.txt` after each flush + promote | — | `SOLVE_SKIP_AUTO_MANIFEST=1` |

Two more fire on the merge path:
| Stack raise | `setrlimit(RLIMIT_STACK, RLIM_INFINITY)` at `--merge` | 28 | `SOLVE_SKIP_STACK_RAISE=1` |
| Auto-verify-solutions | Runs `solve --verify solutions.bin` after `--merge` completes | 30 | `SOLVE_SKIP_AUTO_VERIFY=1` |

Not in either table above, but armed on the same dispatch: the **disk-IOPS pre-flight** (task #107, retooled #115) — a concurrent fsync-rate probe that refuses to start (exit 31) when projected fsync-wait exceeds 25% of estimated enum wall. Escapes: `SOLVE_SKIP_IOPS_CHECK=1` (skip the probe) or `SOLVE_ALLOW_SLOW_IOPS=1` (probe, then proceed anyway). See [SOLVE_C_CLI.md](SOLVE_C_CLI.md) exit 31 — and the eviction-resume rule immediately below.

`SOLVE_DFS_ITERATIVE=1` and `SOLVE_DFS_CHECKPOINT=1` also default to ON at canonical scale (`SOLVE_NODE_LIMIT >= 1T`) since 2026-05-26 — the operator does not need to set these explicitly for any 11.2T+ run.

For 560T specifically, the rule is **launch-phase-dependent**:

- **First launch:** set none of the skip-\* escapes. The whole point of these gates is to catch silent failures on the ~$50 single-shot 3.5-day enum where forensic recovery cost exceeds the gate-implementation cost by 100×.
- **Every eviction-resume / post-`az vm start` relaunch:** set `SOLVE_SKIP_IOPS_CHECK=1`, and nothing else. The #107/#115 IOPS pre-flight (exit 31) probes fsync rate against cold caches after a restart and mis-fires: the 11.2T dress rehearsal's resumed solve measured 223 fsync/s and exited 31 (HISTORY.md, dress-rehearsal bug 3). Over a 5-day campaign with ~5–10 expected evictions, leaving it armed deadlocks at the *first* eviction, so `SOLVE_SKIP_IOPS_CHECK=1` was baked into the real 560T `launch_enum` env (commits `86276eb`, `6d6539f`). This matches [SOLVE_C_CLI.md](SOLVE_C_CLI.md)'s ENVIRONMENT entry: "Recommended on every eviction-resume / post-`az vm start` launch (cold caches give noisy readings; the first-launch gate is authoritative)." The disk does not change between resumes, so the first-launch probe remains the authoritative measurement — this is a bypass of a known-noisy re-probe, not a relaxation of the gate. **All other gates stay armed on resume.**

### build.sha invariant (Outlier #4)

The `build.sha` file in the run directory holds `sha256(/proc/self/exe)` from the first solve invocation that ran there. Every subsequent invocation re-computes its own `/proc/self/exe` sha and compares — on a mismatch **between two well-formed 64-hex shas**, exit 26 with a "build provenance mismatch" error. That qualifier is load-bearing; see "When the guard does NOT fire" below. Purpose: prevent resuming a checkpointed enumeration across two different binaries. The on-disk `.dfs_state` checkpoint encodes search-tree state computed by binary X's prune-stack logic; a different binary Y interpreting that resumed state can produce wrong-but-deterministic canonical bytes — a sha that looks valid but doesn't match any reference and is hard to bisect.

**When the guard fires in practice:**

1. **Same VM, same OS disk across `az vm deallocate` + `az vm start`** — guard passes naturally; `/proc/self/exe` is byte-identical (OS disk preserved). No override needed.
2. **Fresh VM rebuild** (campaign failure-recovery deleted the OS disk; new provision rebuilds solve) — the rebuilt binary has a different sha than `build.sha` on the persistent Premium SSD. The canonical launchers handle this by preserving the stale `build.sha` as `parent_build.sha.<timestamp>` for archival, then deleting it so the new binary writes fresh. No override needed in the launcher's env.
3. **Cross-campaign extension** (e.g., 1120T binary touching 560T's RUN_DIR) — same hygiene step in the launcher's `build()` preserves the parent campaign's `build.sha` and lets the new binary write fresh.
4. **Mid-campaign manual rebuild** (operator ssh's into the enum VM and rebuilds solve directly, bypassing `build()`) — guard correctly fires. Operator must explicitly delete `build.sha` (audited decision) or set `SOLVE_ALLOW_BUILD_MISMATCH=1` for one invocation (audited decision).

**When the guard does NOT fire — fail-open modes (verified by execution 2026-08-30):**

The guard's comparison branch is entered only when the on-disk `build.sha` parses as exactly one 64-character token. Three states bypass it, all returning 0 (proceed):

1. **Malformed / truncated / partially-written `build.sha`** — **and this state also destroys the evidence.** `fscanf` yields `rn != 1` or a length ≠ 64, control falls through to the "First run (or unreadable prior)" path, and the file is *overwritten* with the current binary's sha. Reproduced here: a run directory seeded with `build.sha` containing `deadbeef-truncated-not-a-sha`, then a `SOLVE_NODE_LIMIT=2000000` dispatch → the log prints `[hardening] build.sha CREATED (binary sha 9992e1f1 (transient red-test value, not in-tree))`, exit code carries no guard signal, and the prior content is gone. The strictest case the guard exists for — an abnormal run directory — is the one it converts into silent acceptance plus evidence replacement. `build.sha` *is* written tmp+rename, so this needs an out-of-band cause (a full disk, a manual edit, an interrupted recovery) — which is precisely the population the guard is for.
2. **`popen` of the sha tool fails** — warns, SKIPPED, proceeds.
3. **No sha256 tool on `PATH`** — the guard itself warns and proceeds, but on the enum / merge / `--branch` dispatch paths this branch is **unreachable**: an earlier preflight (`require_sha256_tool`) already exits **10** with an install-coreutils message. Verified by running with an emptied `PATH`: rc 10, `build.sha` untouched. The fail-open is real in the function but not reachable where canonical work happens.

**Operator consequence:** a clean exit is *not* evidence that the build-provenance guard compared anything. Before resuming a canonical run in an existing directory, confirm the log line reads `[hardening] build.sha PASS (binary sha … matches prior run)`. A `build.sha CREATED` line in a directory you believe is a resume means the guard found no usable prior — stop and inspect rather than proceeding. **Pending code fix:** malformed-but-present `build.sha` should hard-error (exit 26) and leave the file untouched instead of overwriting it.

**Why solve binaries vary across rebuilds:** `solve.c` embeds `__DATE__`/`__TIME__` macros in diagnostic strings (~6 sites). Every fresh `gcc` invocation stamps a different build time → different binary sha — even from byte-identical source. `glibc`/`libgomp` patches between rebuilds add further divergence. The `build.sha` invariant is therefore host-fragile by construction; it's a strict cross-binary guard, not a cross-source-version guard. A future improvement is `-DSOURCE_SHA=…` deterministic builds that strip the timestamp dependency.

**Override semantics:** `SOLVE_ALLOW_BUILD_MISMATCH=1` lets solve continue on mismatch and overwrites `build.sha` with the current binary's sha so subsequent runs match. The flag has historically been baked into canonical launchers' env as defense; that's no longer the default as of 2026-06-13 — launchers handle legitimate rebuild scenarios via post-rebuild hygiene instead. See [SOLVE_C_CLI.md ENVIRONMENT table](SOLVE_C_CLI.md#environment) for the env-var entry.

### Metadata equivalence across enumeration paths (task #102, 2026-05-26)

Every canonical-scale run now ships with **`solutions.provenance.json`** alongside `solutions.bin` + `solutions.sha256` + `solutions.meta.json`. The provenance file aggregates per-shard `.provenance.json` sidecars (written automatically by `flush_sub_solutions[_d3]` and the orphan-promotion path) into a campaign-level rollup: shard count by status (EXHAUSTED / BUDGETED / INTERRUPTED), final budget distribution, extensions observed, binary / git / host fingerprint sets, cumulative node + record counts, earliest + latest write UTCs.

**Equivalence guarantee.** A single-shot 11.2T enum and a (56 × 100B + 56 × 100B-extension)-merged 11.2T composition produce byte-identical `solutions.bin` (partition invariance) AND structurally-equivalent `solutions.provenance.json` (verified via `solve --compare-provenance`). Same guarantee scales to 560T.

`--compare-provenance` normalizes away timestamps, host fingerprints, and merge-invocation metadata. Must-match fields: `solutions_bin_sha256`, `solutions_bin_record_count`, `shard_count`, `shards_by_final_status` (the EXHAUSTED/BUDGETED/INTERRUPTED counts), `final_budget_distribution`, `cumulative.total_nodes_explored`, `cumulative.total_records_emitted`.

For full schema + design rationale see `roae-private/METADATA_EQUIVALENCE_DESIGN_2026_05_26.md`. For per-cli reference see [SOLVE_C_CLI.md](SOLVE_C_CLI.md) `--compare-provenance` + Files section.

#### The provenance field reference — what a reviewer verifies a run from

These are the fields that answer "which binary, built from which source, on which host, produced
these bytes". They are the reproducibility surface of a canonical run, so they are grouped here in
one place rather than left to be discovered field by field. Three files carry them.

**A. Per-shard `sub_*.bin.provenance.json`** — written next to every shard by the flush path and
the orphan-promotion path, and **appended to** on every subsequent write to the same shard, so a
resumed or budget-extended shard keeps its whole history rather than the last state only.

| key | what it holds |
|---|---|
| `shard_filename` | the `.bin` this sidecar belongs to, recorded inside the file so a detached sidecar is still attributable |
| `sub_branch` | the depth-2 or depth-3 cell as `{p1, o1, p2, o2}` or `{p1, o1, p2, o2, p3, o3}` — pair index and orientation per level |
| `writes[]` | one record **per write**, appended; the fields below live inside these records |
| `writes[].write_utc` | UTC timestamp of that write |
| `writes[].binary_sha256` | the sha256 read from `build.sha` in the working directory at write time — **the recorded build identity, not a digest of the running process**. Empty when `build.sha` is absent or not 64 hex characters; an empty field means the run could not be bound to a build, not that it matched |
| `writes[].nodes_explored_in_this_shard` | nodes this write explored, for this shard alone |
| `writes[].records_emitted` | records this write emitted |
| `writes[].dfs_iterative` / `writes[].dfs_checkpoint` | whether the iterative DFS and checkpointing were enabled for that write — the two switches that change resume behaviour, recorded per write because a resumed shard can differ from its first write |
| `writes[].resume_history` | the escaped resume-history string for that write |
| `writes[].extends_prior_budget` | `true` when this write continued an existing budget rather than starting one. Auto-detected from the prior sidecar, which is why the sidecar must not be deleted between extensions |
| `final_status` | the shard's status as of the latest write: `EXHAUSTED`, `BUDGETED` or `INTERRUPTED` |
| `cumulative_nodes_explored` | ⚠ **not cumulative in this file.** The comment in the emitter is explicit: for a first write it equals that write's value, and for appended writes it still records *this* write's value. The real summation across writes is done by the aggregator. Do not read it as a shard total |

**B. Aggregate `solutions.provenance.json`** — written by `--merge` from every
`sub_*.bin.provenance.json` in the working directory.

| key | what it holds |
|---|---|
| `earliest_shard_write_utc` / `latest_shard_write_utc` | the campaign's write window, min and max over every per-shard record |
| `sum_compute_seconds_note` | a **string, not a number**: schema v1 does not capture per-shard compute seconds, and the field says so and points at `checkpoint.txt`. It is a documented hole, deliberately left visible rather than filled with a wrong sum |
| `budget_history.branches_seen_at_budget` | a map from per-sub-branch budget to the number of branches ever seen at that budget — the census of budgets the campaign passed through, not just the final one |
| `budget_history.extensions_observed[].from_budget` / `.to_budget` | one entry per observed budget extension: the budget before and after |
| `budget_history.extensions_observed[].earliest_extension_utc` / `.latest_extension_utc` | the time window over which that particular extension was applied across shards |
| `binary_provenance.binary_sha256_set` | the **set** of distinct `build.sha` values across all shards. More than one entry means the campaign was not produced by a single build — legitimate for a resumed or extended campaign, and exactly what a reviewer must see rather than infer |
| `binary_provenance.git_hash_set` | the set of distinct `GIT_HASH` values across all shards |
| `binary_provenance.host_fingerprint_set` | the set of distinct host fingerprints across all shards; more than one entry means the campaign spanned hosts |
| `merge_invocation.merge_utc` | when the merge ran |
| `merge_invocation.merge_binary_sha256` | the `build.sha` of the binary that performed the **merge**, which is a different question from the binaries that performed the enumeration and is recorded separately for that reason |
| `merge_invocation.merge_git_hash` | the merging binary's `GIT_HASH` |
| `merge_invocation.merge_host_fingerprint` | the merging host's fingerprint, or `unknown` |
| `merge_invocation.input_shard_manifest_sha256` | the sha256 of the shard manifest the merge consumed — the binding between "these shards" and "this merged output". Empty when no manifest was supplied |
| `merge_invocation.analytics_integrated` / `.analytics_filename` | whether an analytics sidecar was folded in, and which file |

⚠ `--compare-provenance` **normalises away** every timestamp, the host fingerprints and the whole
`merge_invocation` object. Two provenance files can therefore compare equal while disagreeing on
which host and which merging binary produced them. That is intended — it is what makes the
partition-invariance comparison meaningful — but it means `--compare-provenance` equality is not
an attribution check, and the fields above must be read directly for that.

**C. `canonical-host-fingerprint.json`** — the build-environment capture, written once per
run directory by the hardening path via a shell pipeline. It is written **only if absent**: an
existing non-empty file is left unchanged, so the fingerprint records the first run in that
directory. Any field that fails to capture degrades to an empty string or `unknown` rather than
failing the run.

| key | what it holds |
|---|---|
| `capture_utc` | when the fingerprint was taken |
| `gcc_version` / `glibc_version` | first line of `gcc --version` and `ldd --version` — the compiler and libc identity that a matching `solve.c` commit does **not** pin |
| `uname_a` | full `uname -a` |
| `os_release` | `PRETTY_NAME` from `/etc/os-release` |
| `cpu_model` | `model name` from `/proc/cpuinfo` |
| `cpu_microcode` | the `microcode` revision from `/proc/cpuinfo` — the field that distinguishes two otherwise identical CPUs after a host patch |
| `memory_total_kb` | `MemTotal` from `/proc/meminfo` |
| `azure_vm_sku` / `azure_location` / `azure_host_id` | read from the instance metadata endpoint, each defaulting to `unknown` off-cloud or when the 1-second probe times out. `azure_host_id` identifies the physical host a Spot VM landed on, which is what makes a per-host performance or reproducibility anomaly attributable |
| `binary_full_sha256` | sha256 of the **running executable**, resolved through `/proc/self/exe`. Unlike `binary_sha256` in the shard sidecars this is measured, not read from `build.sha`; `unknown` if it could not be taken |
| `binary_text_sha256` | sha256 of the executable's `.text` section alone, extracted with `objcopy`. It is deliberately narrower than `binary_full_sha256`: two builds differing only in embedded build metadata or section layout agree here while their full digests differ, so a `binary_text_sha256` match is the stronger statement that *the code* is the same |
| `disk_iops.agg_fsync_per_sec` | aggregate fsyncs/second measured by the pre-flight probe |
| `disk_iops.probe_threads` / `disk_iops.fsync_batch_size` | the probe's own parameters — without them the rate above is not comparable between runs |
| `disk_iops.projected_fsync_wait_h` | hours of fsync wait projected for the configured campaign at that measured rate |
| `disk_iops.fsync_wall_fraction_pct` | that projection as a percentage of projected wall time — the number the IOPS verdict is actually taken on |
| `git_hash_macro` | the `GIT_HASH` compiled into the binary, so the file records the source identity the binary *claims* alongside the digests of what it *is* |
| `build_source_sha` | the `SOURCE_SHA` compiled in. `unknown` under the documented build, which is why the digests above exist |


## Known gotchas

### Compile

- Build flags: `gcc -O3 -pthread -fopenmp -march=native -DGIT_HASH="\"$(git rev-parse --short HEAD)\"" -DGIT_BRANCH="\"$(git rev-parse --abbrev-ref HEAD)\"" -o solve solve.c -lm -lz` (minimum to reproduce canonical sha; the `-DGIT_HASH` stamp is sha-neutral — measured 2026-09-02 — and without it every artifact the run writes records `"git_hash": "unknown"`); `gcc -O3 -flto -pthread -fopenmp -march=native -DGIT_HASH="\"$(git rev-parse --short HEAD)\"" -o solve solve.c -lm -lz` (recommended — sha-preserving, ~2% faster at 100B-node canonical-correlation scale on AMD Zen 4 D64, Phase 1c validated 2026-05-15). The `-lz` (zlib) link flag is required since #169 (native-gzip live compression); it is the only build change and is sha-neutral (gzip is a non-sha-determining storage layer).
- `-fopenmp` parallelizes the `--analyze` hot loops. Without it, pragmas are
  no-ops and everything still compiles + runs single-threaded. `libgomp`
  (gcc's OpenMP runtime) ships with gcc under the GCC Runtime Library
  Exception, so no LICENSE.md change is needed.
- `-march=native` enables popcount / AVX intrinsics. Required for the
  `__builtin_popcountll` paths to hit hardware popcount.

### Reproducible-build recipe (task #110, 2026-05-27)

For canonical-grade reproducibility, use the **deterministic recipe**:

```bash
SOURCE_DATE_EPOCH=$(git log -1 --pretty=%ct -- solve.c) \
gcc -O3 -g -march=native -flto -pthread -fopenmp \
    -fno-record-gcc-switches \
    -Wl,--build-id=sha1 \
    -ffile-prefix-map="$(pwd)=." \
    -fdebug-prefix-map="$(pwd)=." \
    -DGIT_BRANCH="\"$(git rev-parse --abbrev-ref HEAD)\"" \
    -DGIT_HASH="\"$(git rev-parse --short HEAD)\"" \
    solve.c -lm -lz -o solve
```

Compared to the bare `-O3 -flto -pthread -fopenmp -march=native`, these flags add:

| Flag | What it does | Why it matters for reproducibility |
|---|---|---|
| `SOURCE_DATE_EPOCH=<unix-ts>` | Pins `__DATE__` and `__TIME__` to a deterministic value | Eliminates the `.rodata` cosmetic non-determinism documented in `roae-private/TASK_108_SUMMARY_FOR_OPERATOR_2026_05_27.md` Q10 |
| `-fno-record-gcc-switches` | Removes embedded build command line from `.GCC.command_line` section | Builds without referencing the build directory |
| `-Wl,--build-id=sha1` | Derives the ELF build-id deterministically from binary content (instead of random hash). ⚠ **[CORRECTED 2026-09-03 — this recipe said `sha256`, which GNU ld does not accept: it emits `warning: unrecognized --build-id style ignored` and the binary ends up with **NO build-id at all**, so the row's own guarantee was unverifiable. Measured on the stock toolchain (Codex V2-F15 #16). `sha1` is accepted, reproducible across rebuilds, and content-derived — a changed source gives a different id.]** | Two builds of same source on same host produce identical build-ids |
| `-ffile-prefix-map="$(pwd)=."` | Strips the absolute build path from any embedded references | Same source compiled in different directories produces identical binary |
| `-fdebug-prefix-map="$(pwd)=."` | Same for debug info (DWARF section) | Debug builds across hosts have identical DWARF paths |

**Result**: two builds of the same source on the same host produce **byte-identical binaries** (the same `.text`, same `.rodata`, same build-id — the last of these only since the `sha1` correction above; under the previously documented `sha256` the flag was ignored and there was no build-id to compare). The empirical Q10 finding showed that without these flags, two builds had byte-identical `.text` but differing `.rodata` and build-id — cosmetic but messy. The deterministic recipe eliminates the mess.

**Caveat — cross-host reproducibility**: even with this recipe, builds across different physical hosts (different gcc patch, glibc patch, kernel, CPU revision) can produce DIFFERENT binaries — and may in principle produce a different canonical sha. ⚠ **[CORRECTED 2026-09-04 — this read "and may produce different canonical sha at BUDGETED-cell-density-sensitive scales like 1T". The cell-density mechanism is withdrawn, and 1T is not an instance of it: the two published 1T values are two per-cell budgets (published 6,315,458 vs auto-divided 6,314,566), reproduced from one binary on one host on 2026-09-04. **No host-level drift event is on the project's record.** The caveat above is kept as a statement of what has not been tested, not of what has been observed. See [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §d3 1T and [CORRECTIONS.md](CORRECTIONS.md) §"2026-09-04 — the 1T anchor pair was two per-cell budgets".]** See the structured `validation_history` block in `CANONICAL_HASHES.md` and the `feedback_canonical_sha_drift_management` memory for the operational discipline.

For canonical campaigns at 11.2T+, this isn't a concern (drift mechanism does not fire at higher scales per Item 4 empirical evidence 2026-05-27).

### Solver

- **Independent verifier**: `verify.py` (repo root) is a pure-Python implementation
  (stdlib-only on every verification leg, except the `--check-t5-c3`
  analytics leg, which imports numpy/pyarrow — see Build prerequisites) of the verifier recipe in
  [REBUILD_FROM_SPEC.md](REBUILD_FROM_SPEC.md) (originally ~160 lines; it has
  since grown the independent re-counting and artifact-check surfaces —
  `--recount`, `--check-certificate` — documented in [VERIFY.md](VERIFY.md),
  alongside the C-side sibling `verify.c`). Reads any format-v1
  `solutions.bin`, reconstructs each 64-hexagram sequence, and checks
  **C1 (pair structure), C2 (no 5-line transitions), C3 (complement
  distance ≤ 776, added 2026-04-19), C4 (starts with
  pair 0), C5 (exact distance distribution)** plus sort
  order and dedup. No shared code with solve.c — genuine second opinion.
  Usage: `python3 verify.py [--jobs N] /path/to/solutions.bin`. Exit 0
  on PASS, 1 on constraint failures, 2 on header/format errors. `--jobs`
  defaults to 1, so the default invocation is the single-thread arm.
  Wall time scales with record count at ~19k records/sec per Python worker
  (CPU-bound, post-2026-05-08 streaming-reads patch), which puts the current
  10T d3 file (706,427,594 records) at **~10 h single-threaded** and ~40 min
  at `--jobs 16`, and the 100T file (3,432,399,297 records) at ~3 h at
  `--jobs 16`. Treat 19k as a projection, not a floor: the 560T campaign
  measured roughly a 3× shortfall against it — see
  [DEPLOYMENT.md](DEPLOYMENT.md) §"Memory-budget validation for chunk-based
  parallel verifiers" for the measured rates and the disk-contention caveat,
  and budget from a rate you measured on your own hardware.

  ⚠ **[CORRECTED 2026-09-02 — this passage previously advertised a
  single-threaded run of one to five minutes on the 10T solutions.bin, in the
  same sentence as the ~19k records/sec rate that contradicts it. The two are inconsistent by
  more than two orders of magnitude, and the arithmetic needed to see it is
  entirely inside the sentence: 706,427,594 / 19,000 = 37,180 s = 10.3 h. The
  sentence's own 100T arm was already right (3,432,399,297 / (16 × 19,000) =
  11,291 s = 3.1 h), which is what identifies the 10T arm as the defect rather
  than the rate. [HISTORY.md](HISTORY.md) §"May 4 - May 5, 2026 PDT" measured
  it: the single-threaded run took ~10 h on the 759M-record file before an
  eviction killed it at ~95%, and the same file finished in ~6 min at
  `--jobs 128` — 16.5k records/sec/worker, corroborating the rate and
  refuting the claim. (The adjudication cited HISTORY.md:1590-1593 for this;
  the passage is at ~:1604-1632 today. Locate by content.) Likely origin: the figure described the
  original ~160-line spot-check verifier, before `--recount` and the
  artifact-check surfaces grew the per-record work — but the sentence sits in
  the CURRENT tool description with no era stated, and an era defence needs
  the era on the page. Operational cost of the retired figure: a contributor
  who schedules a 5-minute timeout kills a healthy verifier and reports a
  hang. The retired phrasing is registered in
  [RETRACTED_PHRASES.tsv](RETRACTED_PHRASES.tsv) and keyed in
  [CORRECTIONS.md](CORRECTIONS.md) as `RP-e0ad193f`. Found by Codex review
  V2-F15 #14.]**

- **Independent completeness reference** (added 2026-05-28):
  `python3 verify.py --enumerate-reference NPAIRS` (2 ≤ NPAIRS ≤ 9).
  Does NOT read solutions.bin. Brute-forces the reduced NPAIRS-pair
  problem under the cleanly-reducible structural constraints (C1 + C2 +
  C4; C3/C5 are global over the full 64-sequence and excluded) **two
  ways** — exhaustive generate-then-filter (ground truth) vs
  prune-as-you-go DFS (mirrors solve.c's incremental pruning) — and
  asserts the two produce the identical valid set. A mismatch means a
  pruning step is unsound/incomplete (dropped or added a valid sequence)
  — the "did an optimization silently drop a real solution" failure
  class, checked in independent code. **Scope/limit (honest):** this
  grounds the structural-constraint enumeration *semantics* on a reduced
  problem; it does NOT differential-test solve.c's full enumeration —
  that is infeasible (solve.c never exhausts any cell; global C3/C5
  don't reduce; solve.c has no reduced-pair mode). solve.c prune
  completeness at canonical scale is covered empirically by the K-pilots
  (v1 ⊆ v1+prunes at every tested scale). Exit 0 PASS / 1 mismatch / 2
  bad-arg.

  **Streaming-reads memory model (added 2026-05-08, task #84 follow-up):**
  Each worker uses bounded memory (32 MB streaming batch) regardless of
  input size. Total memory at `--jobs N` is `N × 32 MB`, not `file_size`
  as in the original design. The pre-2026-05-08 verify.py loaded the
  full per-worker chunk via `f.read(chunk_size * 32)` — at 100T scale
  on a 32 GB VM that thrashed the page cache (13× re-read multiplier;
  OOM-killed at 5h 5min). Streaming pattern is the project standard
  for any chunk-based parallel verifier. Banned pattern: `chunk =
  f.read(N * record_size)` for unbounded `N` in a parallel context.

- **Two-tier solver selftest**:
  - `./solve --selftest` (~5 sec on 4 threads): runs a bounded
    enumeration with a fixed budget and checks the resulting
    `solutions.bin` sha256 against the canonical baseline `403f7202…`.
    Catches gross regressions in the constraint logic, partition
    structure, or merge code. Use as a build smoke-test.
  - `python3 solve.py --extended-selftest <path-to-solve-binary>`
    (~10 min on 4 threads, added 2026-04-30): a CI-grade regression
    suite that drives the supplied binary through nine subtests +
    a cross-check:
      1. Single-shot 3-way @ 100M nodes (recursive vs iterative vs
         iterative+v2). Catches regressions in the iterative DFS,
         v2 capture, or fork-merge dispatch.
      2. v2 resume @ 50M → 200M (PHASE_A captures, PHASE_B resumes,
         resumed sha must match single-shot 200M sha `e43f2905…`).
         Catches regressions in the off-by-one capture-frame fix
         and the resume gate.
      3. v1 resume @ 50M → 200M (recursive path with the "walk-fresh
         on resume + load_prior_shard" policy). Same sha check.
      Cross-check: recursive single-shot 200M sha == iterative
      single-shot 200M sha (DFS-engine independence).
    Returns 0 on full PASS, 1 on any failure. Suitable as a CI gate
    before commits that touch `backtrack`, the v2 capture/resume
    fields, the bitmap key encoding, or the merge dispatch.

- **Never assume `fwrite` succeeded without checking.** The 2026-04-14
  `solutions.bin` was silently truncated from 23.7 GB to 8 GB because the disk
  filled up mid-write. The solver's sha256 still matched the truncated file
  (sha was computed post-write from what landed on disk). Every `fwrite`,
  `fopen`, `fclose`, `fflush`, `fsync`, `rename`, `fseek`, `ftell`, and
  `fread` has its return checked in the paths named here (enumeration flush,
  external-sort chunks, both merge paths). Short reads are hard errors, not
  warnings. Post-write `stat()` verifies size at those writes.
  ⚠ **[SCOPED 2026-09-03 — this read "at every call site" and "at every file
  write", and that universal is FALSE (Codex V2-F15 #3). The checkpoint
  METADATA writers are the exception and they are resume-critical: the
  `sub_ckpt_meta.txt` writer calls `fprintf`, `fflush`, `fsync`, `fclose` and
  `rename` with **none** of them checked, so a failed flush still lets the
  `rename` install a possibly-truncated meta OVER the good one. The
  `sub_ckpt_depth<tid>.txt` and `sub_ckpt_task_done.txt` writers repeat the
  pattern. These files restore `shared_nodes` (budget state) and the
  completed-task frontier on resume, so a bad one is not cosmetic. The worker
  snapshot writer immediately above them DOES check (`if (fflush(wf) != 0 ||
  fsync(fileno(wf)) != 0)`) and aborts the checkpoint — which is what makes the
  omission a gap rather than a convention. The fix (check the flush and SKIP the
  rename on failure — a stale-but-consistent meta is recoverable, an
  installed-truncated one is not) is a `solve.c` change and is HELD behind the
  five-condition MASTER GATE; this note is the honest statement until then.]**
- **Preflight disk space**: `free_disk >= estimated_output × 1.5`. At 10T the
  sub_*.bin shards total ~23 GB AND the final solutions.bin is ~24 GB —
  together they exceed a naive 32 GB disk.
- **Preflight sha256 tool.** `solve.c` shells to `sha256sum` (GNU coreutils)
  or `shasum -a 256` (BSD/macOS) for output digests. The solver walks `$PATH`
  at startup and exits 10 with install hints if neither is available —
  prevents a successful multi-hour enumeration from producing an empty
  `.sha256` file at the end. Modes that don't write digests
  (`--verify`, `--validate`, `--analyze`, `--prove-*`, `--list-branches`)
  skip the preflight.
- **time_limit and reproducibility are incompatible.** For any canonical
  run whose sha256 needs to be reproducible across machines or
  re-enumerations, set `SOLVE_NODE_LIMIT` only and pass `0` for the
  CLI time_limit arg. Per-sub-branch node budgets are deterministic;
  wall-clock interrupts are not. If time_limit fires first, whatever
  sub-branches happened to be running at the N-second mark are tagged
  INTERRUPTED with their partial solutions preserved — and which
  sub-branches those are depends on thread scheduling. Two identical
  invocations of `./solve 60` on the same inputs will produce different
  solutions.bin sha256 under load. The solver prints a WARNING at
  startup when both limits are set together.
  Use time_limit alone for "run N minutes, take what we got"
  exploratory workflows only. The --selftest harness previously passed
  a 60-second time_limit as a safety net; under load, that caused
  spurious sha-mismatch failures. Fixed 2026-04-18 — selftest now uses
  node_limit only.
- **Per-sub-branch filenames include the full (p1, o1, p2, o2) key**. Earlier
  versions keyed only on (p2, o2), causing silent overwrites. Never narrow the
  file-naming key without proving no collisions can occur.
- **Status taxonomy: EXHAUSTED / BUDGETED / INTERRUPTED.** Each sub-branch
  records one of three end states. EXHAUSTED means the search completed
  naturally (no more solutions possible). BUDGETED means the per-sub-branch
  node budget was hit (deterministic under the same budget; re-run at a
  higher budget may find more solutions). INTERRUPTED means a signal or
  process kill cut it short. Resume: always re-run INTERRUPTED, re-run
  BUDGETED only if the new budget exceeds the stored one, skip EXHAUSTED.
- **Hash table auto-resizes; zero silent drops.** Per-thread tables start
  at 2^24 slots (configurable via `SOLVE_HASH_LOG2`) and double when load
  exceeds 75%. Probe is over the full table with no cap. OOM during resize
  triggers FATAL abort. The earlier 64-probe cap that silently dropped 241M
  records at 10T depth-2 no longer exists.
- **solve.c uses pthreads; solve.c's `--analyze`, `--validate`, `--prove-*`
  use OpenMP.** Don't mix both in the same phase of execution — they compete
  for cores. The main enumeration uses pthreads only; OpenMP is confined to
  post-enumeration modes.
- **Enumeration and merge have very different resource profiles — run them
  on separate VMs.** Enumeration is core-bound (64 pthreads, ~10 GB RAM flat);
  merge is RAM-bound (`malloc(unique_records × 32)`). At 100T the merge needs
  ≥128 GB RAM, at 1000T ≥256 GB — far more than the enumeration VM needs.
  Splitting the phases keeps enumeration on a lean F-series SKU and only pays
  for a memory-dense E/M-series VM during the brief merge. See
  [DEPLOYMENT.md §Two-phase deployment](DEPLOYMENT.md#two-phase-deployment-enumeration-vm-vs-merge-vm)
  for the full pattern, cost table, and orchestration requirements.
- **`--analyze` has shared state with lifetime boundaries that bite new
  sections.** `bmask[]` (31 packed per-boundary match bitmaps, **`31 × ceil(N/64) × 8 B`**
  for `N` records — the solver prints the figure at startup: `[masks] Allocating 31
  packed bitmaps (… GB total)`) is allocated before section [3] and freed at the end of
  analyze_mode. Any new section
  that reads `bmask[]` must be inserted before the free, OR rebuild it
  internally via a fresh streaming pass. A prior edit freed `bmask[]` between
  sections [13] and [14] to make room for [14]'s ~24 GB sort buffer on
  tight-RAM VMs; adding sections [16]-[19] after [15] then silently
  use-after-freed that memory and segfaulted mid-run (output truncated at
  [17]'s header). Fix: keep `bmask[]` alive to the end. **Size the VM per record
  count, not from a fixed number** — `bmask[]` is linear in `N`:

  | Dataset | Records | `bmask[]` = `31 × ceil(N/64) × 8 B` | With [14]'s ~24 GB sort buffer | Minimum practical VM RAM |
  |---|---|---|---|---|
  | 11.2T v1 | 759,608,573 | 2.94 GB | ~27 GB | 32 GB |
  | 10T d3 (`b85c8871…`) | 706,427,594 | 2.74 GB | ~27 GB | 32 GB |
  | 560T d3 (`9a968fa2…`, current deepest canonical) | 10,525,271,997 | **40.8 GB** | **≥ 65 GB** | ≥ 96 GB |

  The `bmask[]` column is exact (the formula is the allocation). The fourth column is a
  **lower bound**: it adds the ~24 GB sort buffer this passage measured at the 742M/759M
  scale, which has not been re-measured at 10.5B records and is likely larger there; the
  mmap'd input adds page-cache pressure on top. Measure before provisioning, and read the
  solver's own `[masks] Allocating 31 packed bitmaps (… GB total)` startup line.

  The single fixed "~27 GB / 32 GB minimum" figure that stood here applies **only** at
  the 742M/759M-era record counts it was written about; at the 560T canonical the bitmaps alone
  exceed a 32 GB box. The F32als_v6 used for the smaller runs has 64 GB, which is not
  enough for 560T `--analyze`. Verify with `free -g` remotely during a full run if ever
  moving this boundary. The same pattern may arise with other shared buffers —
  whenever the solver code has a comment asserting a memory constraint,
  verify with `free -g` rather than trust the comment.

### Monitor / orchestrator

- **`ps -o pcpu` is cumulative-averaged, not instantaneous.** `ps` reports
  CPU% as `total_CPU_seconds / elapsed_wall × 100` since process start. For a
  process whose first phase ran at low CPU (e.g. solve's resume "fast-skip"
  phase loading shards into the hash table at ~32% utilization), `ps pcpu`
  will appear to "ramp" for hours after the process actually saturates,
  because the slow startup is baked into the lifetime average. To check
  whether solve is **actually** saturating cores right now, use
  `top -bn2 -d 1` (two samples 1 second apart) and read the second %CPU
  value — that's the true instantaneous utilization. On D128 at steady-state
  real-walking, this should be near 12,800% (100% × 128 cores). Caught
  during 100T v2 recovery2 monitoring 2026-05-22: `ps pcpu` was reading
  ~5600% (interpreted as "still ramping up") while `top` confirmed actual
  steady-state of 12,800% (full saturation). The lifetime average had
  another ~6h of accumulation before it would asymptote to the true rate.
- **Separate launcher and monitor processes.** If the launcher script crashes
  during setup, the monitor should survive. Auto-teardown via `trap cleanup
  EXIT INT TERM` is how we guarantee VMs don't linger on error.
- **Use `set -uo pipefail`, NOT `set -euo pipefail`.** A transient scp failure
  should not kill the monitor loop. Guard individual risky commands with
  explicit `if ! cmd; then log; fi` instead of relying on `-e`.
- **Never redirect orchestrator stderr to `/dev/null`.** Silent death is the
  worst failure mode.
- **Monitor completion-detection must match solver's actual output.** Earlier
  the monitor grepped for `"SEARCH COMPLETE"` while the solver writes
  `"SEARCH_COMPLETE"` (underscore) to solve_results.json. Match a stable
  machine-readable marker, not stderr prose whose exact wording evolves.
- **Don't grep-hide SSH host-key warnings.** Use `ssh -o
  UserKnownHostsFile=/dev/null -o LogLevel=ERROR -o StrictHostKeyChecking=no`
  for VMs whose IPs get reused across recreation cycles. Historically we had
  grep chains filtering out WARNING lines; that's hygiene, not a fix.
- **Solver-launch SSH must be belt-and-suspenders detached.** The naive form
  `ssh host "nohup ~/solve > out 2>&1 &"` hangs the local SSH client even
  with `ssh -n` and remote `< /dev/null` — observed empirically 2026-04-16.
  The remote `bash -c` lingered for minutes after backgrounding `nohup`,
  because some fd inheritance path kept the SSH channel open. Solve was
  happily running but the launching monitor never returned from `ssh`,
  stuck in `do_wait`, missing spot evictions. **Required form:**
  `timeout 15 ssh -n … "cd /data && setsid nohup ~/solve … > out 2>&1 < /dev/null &" < /dev/null`.
  - `setsid` puts solve in its own session, fully detached from SSH's
    process group / controlling tty
  - `timeout 15` guarantees the local ssh dies even if the remote shell
    refuses to release the channel; the nohup+setsid'd solve survives
  - The next monitor step probes `pgrep -x solve` via a fresh SSH so a
    forced-killed launch SSH doesn't false-fail launch detection.
- **A stuck monitor is blind to spot eviction.** If the monitor's main
  poll loop never starts (hung in launch SSH, hung in setup), the VM can
  evict undetected. Every long-blocking call in the launch path needs a
  hard timeout for this reason.
- **Supervisor → monitor takeover: kill monitor FIRST, then touch /data.**
  When a supervisor wraps a monitor (e.g., to chain runs or re-archive
  after the monitor finishes), kill the monitor *before* doing any
  `/data` operations or VM teardown. Otherwise the monitor's own
  archive/teardown flow races with the supervisor — observed scenario:
  monitor's `az vm delete` runs while supervisor's `scp solver@host:/data/...`
  is in flight, and the scp dies with no route to host mid-pull.
- **Pattern-based wipes preserve everything outside the patterns.** The
  monitor's stale-data clear is `rm -f /data/sub_*.bin /data/solutions.bin
  /data/checkpoint.txt …` (enumerated patterns), not `rm -rf /data/*`. To
  carry a file across runs on the shared managed disk, give it a name
  outside the pattern set — e.g., `solutions_d3_<sha8>.bin` survives a
  depth-2 wipe because no pattern matches it. (This is also the reason
  we say "clear stale run artifacts," not "wipe the disk" — see
  `Asset preservation` for terminology.)
- **Chained runs: supervisor owns VM teardown, not the inner monitors.**
  When the supervisor takes over completion handling, the monitor
  shouldn't auto-teardown — the supervisor decides when the VM goes away
  (typically: pull metadata via SSH first, then delete VM). The
  managed data disk auto-detaches and survives VM deletion.
- **Chained runs: prefer sequential monitors over a supervisor.** The
  supervisor pattern (kill monitor mid-merge, take over /data) has race
  conditions. The sequential pattern (let each monitor run to natural
  completion, then start the next) is simpler and correct. Between runs,
  a temp VM can rename files on the managed disk if needed.
- **Write run_id.txt BEFORE the wipe, not after.** The monitor's
  `sync_files` function checks `/data/run_id.txt` to detect stale data.
  If `run_id.txt` is written after the wipe, there's a race window where
  a concurrent sync reads the old ID and skips the sync. Writing the new
  ID first closes this window. (Observed 2026-04-17: "Run ID mismatch on
  sync" warnings from this race — cosmetic, but confused diagnostics.)
- **Solver correctness is independent of monitor state.** The monitor's
  sync warnings, log errors, or even crashes don't affect the solver
  process running on the VM. The solver reads no state from the monitor.
  Monitor failures are observability problems, not data problems.
- **Post-completion gate: --verify + hash-drop check.** After solver
  writes solutions.bin, the monitor runs `./solve --verify solutions.bin`
  on the VM (independent C1-C5 check on every record) and greps
  solve_output.txt for nonzero hash-table drops. Either failure aborts
  before archiving — no invalid output is ever accepted as a completed run.
- **Progress-stall watchdog must exempt the merge phase.** The watchdog
  checks `progress.txt` staleness to detect hung solvers. But the merge
  phase (reading 158K files, sorting billions of records, writing
  solutions.bin) legitimately takes 15-30+ minutes without updating
  progress.txt. The watchdog must check `solve_output.txt` for merge
  indicators ("Reading sub-branch", "Sorting", "Writing", "Computing
  sha256") before declaring a stall. Observed 2026-04-17: watchdog killed
  a healthy solver mid-merge on a 10T depth-3 run, losing the merge
  output while all sub_*.bin files were intact on disk.
- **Merge is not checkpoint-protected — use on-demand VMs.** The merge
  phase (malloc + qsort + write) is a single uninterruptible operation.
  If spot-evicted mid-sort, all work is lost and must restart from the
  sub_*.bin files. For production merges, use an on-demand VM (~$2 for
  30 min on F64). This is the two-phase pattern: spot for enumeration
  (checkpoint-protected), on-demand for merge (must complete in one shot).
- **Progress rate + ETA in sync logs.** Each checkpoint sync computes
  sub-branches/hour and estimated time remaining. Essential for overnight
  100T+ runs where "is it still progressing?" can't be answered by a
  single checkpoint count.
- **Disk usage per poll cycle.** Logged as "Disk: 45% (54GB / 121GB)"
  at each sync. Shows growth rate and predicts whether the dynamic
  expansion watchdog will trigger before completion.
- **Sub_*.bin integrity check on eviction resume.** After spot eviction
  and redeploy, the monitor checks every existing sub_*.bin for
  `size % 32 == 0`. Truncated files (eviction killed the flush mid-write
  before fsync) are removed so the solver re-runs those sub-branches
  from checkpoint rather than merging corrupt data.
- **All merge code paths must use canonical dedup.** The solver's normal-
  mode merge and the standalone `--merge` flag must both use
  `compare_canonical` (orient bits masked) for dedup — not
  `compare_solutions` (full-byte). A mismatch means `--merge` on the
  same sub_*.bin files produces a different sha than the solver would
  have. This was a bug through commit 872a861; fixed afterward.
- **External merge-sort for memory-independent merging.** At 10T depth-3,
  the merge buffer is 82 GB (2.77B records × 32 bytes). For larger runs
  or smaller VMs, `SOLVE_MERGE_MODE=external` uses disk-based sorted
  chunks + k-way heap merge. Produces identical output to in-memory merge.
  Default (`auto`) selects external when needed RAM exceeds 70% of
  physical. `SOLVE_MERGE_CHUNK_GB` controls chunk size (default 4 GB).
- **Disk tier dominates external merge time.** Lesson from the 2026-04-18
  10T depth-3 production-scale external merge test on Standard_LRS
  (HDD-tier): rate was ~6-7 min per 4 GB chunk × 20+ chunks in phase 1,
  projecting to ~3-4 hours total wall and ~$12-15 at F64 on-demand. That
  is **~6× the time and ~6× the cost** of the same merge in-memory on the
  same F64 (fits in 128 GB RAM comfortably). The HDD is the bottleneck,
  not the code. Implication: never do an external merge on Standard HDD
  at > 10T scale without a very good reason. At 100T the numbers become
  untenable (extrapolated 30+ hours on HDD vs ~3 hours on Premium SSD).
- **Use `SOLVE_TEMP_DIR` to keep temp chunks on Premium SSD while keeping
  shards and final output on cheap archival storage.** External merge
  does ~2× chunk-size worth of I/O to the temp directory
  (write chunks in phase 1, read chunks in phase 2). Pointing
  `SOLVE_TEMP_DIR` at a Premium SSD attached only for the merge runs
  that I/O at SSD speeds (~200 MB/s on P20/P30, ~3-4× HDD). The SSD gets
  destroyed after the merge — no long-term Premium-storage cost, only
  the prorated hourly rate during the merge (pennies). Shards stay on
  `solver-data` (Standard HDD, ~$3/month). Final `solutions.bin` also
  lands on `solver-data` since CWD during merge is unchanged. See
  [DEPLOYMENT.md §Premium-SSD-attach-for-merge](DEPLOYMENT.md)
  for the concrete az CLI workflow.
- **Standing rule: never provision `solver-data` as Premium SSD.** It
  holds cold shards 99% of the time. Standard_LRS ($3/month for 300 GB,
  $10/month for 1 TB) is the right tier for archival. The factor-10
  cost jump to Premium is only justified during active merges, and those
  are better served by attach-a-temp-Premium-SSD-just-for-the-merge.
- **External merge has a hard pre-dedup size ceiling.** `MAX_SORTED_CHUNKS
  = 4096` in solve.c × default `SOLVE_MERGE_CHUNK_GB=4` = **16 TB of
  pre-dedup input**. At observed d3 rates (~8.3 GB per 1T nodes) that's
  ~2,000T of enumeration. Comfortable for 10T-1,000T; restrictive only
  at ~1,500T+. Mitigation is env-var (`SOLVE_MERGE_CHUNK_GB=16` buys 4×
  headroom, 32 buys 8×) with no code change; or bump the constant as a
  one-line source change. Solver emits a clear error with the mitigation
  if the limit is hit. Before this bites: `ulimit -n` default of 1024
  open FDs is hit around 500T (the k-way merge opens every chunk
  simultaneously). `ulimit -n 16384` before running fixes it.

- **Stack `ulimit -s`.** Production builds run cleanly at the default
  Linux stack limit (8 MB on every distro tested: Ubuntu 24.04 cloud-
  init, Cobalt ARM, the orchestrator VM). main()'s peak stack usage
  is ~4-6 MB after the 2026-05-05 #54 fix, leaving comfortable
  headroom. **No `ulimit -s` adjustment needed for production runs.**

  **AddressSanitizer / sanitizer-instrumented builds DO require
  `ulimit -s unlimited`.** ASan adds redzones around every stack-
  allocated array, which inflates main()'s frame from ~6 MB to
  ~16 MB. Without the bump, ASan binaries SIGSEGV at main() entry
  with a misleading "stack-overflow" report before any user code
  runs. Build flags `-fsanitize=address -no-pie -fno-pie -O1 -g`
  combined with `ulimit -s unlimited` produce the right
  diagnostic environment.

  solve.c includes a startup constructor (`check_stack_ulimit()`,
  added 2026-05-05 task #75) that prints a stderr warning if the
  running process's `RLIMIT_STACK` is below the build's
  recommended threshold (8 MB production, 64 MB ASan). Surfaces
  the requirement loudly before any code-path-specific failure.

### Accumulating ground truth — single-branch exhaustion workflow

Long-horizon enumeration strategy: exhaust individual first-level branches
over time, accumulate their shards on a shared archive disk, and concentrate
new-run compute budgets on the remaining un-exhausted branches. This is
formally justified by the partition-invariance theorem — see
[PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md) for the proof that
merging shards from independent single-branch runs produces identical
output to a full-parallel run (under exhaustive enumeration).

Operational procedure:

1. Run `./solve --branch P O 0` (no node limit → exhaustive) for a
   targeted first-level branch. Sub-branches within that branch complete
   as EXHAUSTED; shards land in the CWD as `sub_P_O_*.bin`.
2. Archive those shards + the branch's checkpoint entries onto a
   shared disk (e.g., `solver-data` or a dedicated `solver-ground-truth`
   disk). Retain the checkpoint lines marking EXHAUSTED status.
3. Next full run: `cp` (or symlink) the archived shards + concatenated
   checkpoint into the working directory before launching. `solve.c`
   reads the checkpoint on startup, sees EXHAUSTED entries, skips those
   sub-branches entirely. Enumeration only runs on the remaining branches.
4. Merge at end reads all shards in CWD — pre-existing and freshly-written
   alike — producing a `solutions.bin` that combines exhausted-ground-truth
   with budgeted-partial for the remainder.

**Budget distribution option**: by default, the per-sub-branch node limit
is `SOLVE_NODE_LIMIT / total_partition_size`, which preserves reproducibility
across fresh vs. resumed runs at the same node limit. For the accumulation
workflow where you want the remaining node budget concentrated on
un-exhausted branches, opt-in via `SOLVE_CONCENTRATE_BUDGET=1`. This
divides by the *remaining* sub-branch count instead. Trade-off: output
sha256 depends on how many branches were pre-completed; NOT reproducible
by `SOLVE_NODE_LIMIT` alone. The solver prints a WARNING when this
env var is active.

**Workaround without the env var**: if you want concentration semantics
under the default reproducible path, compute the target total manually:

🔴 **[CORRECTED 2026-09-03 — the recipe that stood here was wrong by its own
arithmetic (Codex V2-F15 #2), and it under-budgeted every remaining branch.** It
set `SOLVE_NODE_LIMIT = TARGET_PER_BRANCH × REMAINING_SUB_BRANCHES`. But the
default (non-`CONCENTRATE`) path divides `SOLVE_NODE_LIMIT` by the **full**
partition — `n_all_subs + n_skipped_subs` — never by the remaining count. So each
remaining branch actually received `TARGET × REMAINING/TOTAL`: at half
completion, **half** the intended depth, while the text below promised "same
effective per-sub-branch depth". Scaling the numerator by `remaining` cannot
work under a total-divisor.]**

Use the per-sub-branch control directly, which is what it is for:

```bash
SOLVE_PER_SUB_BRANCH_LIMIT=$TARGET_PER_BRANCH ./solve 0
```

or simply **re-supply the ORIGINAL total budget** unchanged — under a
total-divisor the per-branch depth is already what you wanted, and completed
branches cost nothing to re-skip. Either gives the same effective per-sub-branch
depth on the remaining branches with full reproducibility of the pass.

### `--sub-branch` CLI mode (targeted depth-3 sub-branch exhaustion)

Added 2026-04-19. Runs a single depth-3 sub-branch `(p1, o1, p2, o2, p3, o3)`
to exhaustion (or node-limit budget). Usage:

```bash
SOLVE_NODE_LIMIT=0 ./solve --sub-branch <p1> <o1> <p2> <o2> <p3> <o3>
```

Writes a single `sub_P1_O1_P2_O2.bin` shard and a single checkpoint line
with status EXHAUSTED (if the tree finishes) or BUDGETED (if a node limit
is set and hit first). Designed for the stratified-sample exhaustion study
— each run produces one data point of (wall time, node count, solution
count, status) for cost-extrapolation analysis.

Unlike `--branch` (which runs ALL sub-branches of a first-level branch),
`--sub-branch` targets exactly one. It bypasses checkpoint.txt loading so
that a fresh run is a fresh run — no accidental resume from stale state.

Sizing. ⚠ **[CORRECTED 2026-09-03 — this paragraph described the pre-P1 engine
(Codex V2-F15 #15). It read "the workload is single-threaded inside a sub-branch,
so D128 is 99% wasted" and advised pairing with D2/D4; that has not been true
since P1.]** `--sub-branch` **auto-parallelizes across intra-branch tasks whenever
`SOLVE_THREADS > 1`** (`solve.c`, "P1 parallel-sub-branch: auto-enable when
SOLVE_THREADS > 1"); set `SOLVE_SUB_BRANCH_PARALLELISM=single` to opt out, which
is the regression-mode path. So size the VM **from measured scaling on your own
workload**, not from a single-thread assumption — the old advice would leave a
parallel run on two cores. See `DSERIES_ROI_REPORT.md` (outside repo) for SKU
sizing rationale, and note it predates P1 on this same point.

Validation guarantee: if you later exhaust a sub-branch via `--sub-branch`
AND separately compute a full `--merge`'d canonical from independent
whole-partition enumeration, merging the single-exhausted-sub-branch
shard into a fuller dataset (following the accumulation workflow above)
is byte-identical to running everything in one invocation, per
partition invariance.

### `--kde-score-stream` CLI mode (native KDE scorer for distributional analysis)

Added 2026-04-24 alongside the consolidation-hang postmortem and bug fix.
Companion subcommand for the `solve.py --joint-density-v2` distributional
analysis pipeline. Reads fit points from a binary file, streams query
points from stdin (float64 packed), writes count-below-threshold to stdout.
Implements Gaussian kernel KDE log-density via log-sum-exp, parallelized
via OpenMP.

```bash
./solve --kde-score-stream --fit-file FIT.bin --d N --bandwidth BW --threshold T
```

~10× faster than sklearn's pure-Python `KernelDensity.score_samples` on
typical inputs (validated bit-identical on a 500-point synthetic test).
Makes exhaustive distributional analysis on the 100T canonical (3.43B
records) tractable in ~2 hours on D64 (vs ~9 days pure-Python).

See `roae-private/DISTRIBUTIONAL_V2_SPEC.md` (private staging repo)
for the analysis pipeline + Python integration.

### `solve.py --sat-encode` (DIMACS / OPB encoder for #SAT model counting)

Added 2026-04-24. Emits propositional encoding of C1+C2 (optionally +C3
as Pseudo-Boolean linear constraint, +C4 unit) for input to exact #SAT
solvers (`ganak`, `d4`, `sharpSAT-TD`).

```bash
solve.py --sat-encode kw.cnf [--sat-c3 pb] [--sat-c4]
```

Produces:
- `kw.cnf` — DIMACS CNF (4,096 vars / 272,128 clauses for C1+C2)
- `kw.cnf.opb` — Pseudo-Boolean OPB format with C3 PB constraint added
  (266,240 vars / 1,058,560 clauses; C3 sum has 258,048 terms)
- `kw.cnf.meta.json` — variable/clause counts, sha256 of clauses for
  reproducibility

See `roae-private/SAT_EXPERIMENT_SPEC.md` (private staging repo)
for the experimental protocol and validation strategy.

### Infrastructure

- **Spot-VM evictions in westus2 under F64 averaged ~1 per 3 hours during
  April 2026 testing.** Sub-branch-granularity recovery is too coarse at
  large per-sub-branch budgets (100T+). Depth-3 work units (Option B,
  shipped via `SOLVE_DEPTH=3`) make the recovery granularity affordable.
- **Non-zonal managed disks cannot attach to zonal VMs.** If your data disk
  was created without a zone but the VM you want to attach it to is zonal,
  Azure returns `BadRequest`. Provision analysis VMs as non-zonal when they
  need the data disk.
- **Teardown is dependency-ordered.** VM → NIC → public-IP → NSG → vnet,
  sequential. Parallel deletes return spurious exit-1 because dependents
  hold references.

### Solver-VM network topology: private IP only

Solver VMs live on the shared `claude-vnet/default` subnet alongside the
orchestrator (`claude` VM at `$ORCH_IP`). Each new solver VM created by
`monitor_canonical.sh` gets a private IP (the next free private IP on the
subnet) and **no public IP and no NSG rule**. The orchestrator SSHes to the
private IP directly.

**Why:** no port 22 reachable from the internet, no public-IP cost
(~$0.005/hr per VM), simpler resource inventory.

**Documented exception — `scripts/perf_bench.sh` (the standardized paired
benchmark harness).** This one endorsed script does **not** follow the rule,
on every invocation and not only from a laptop. It provisions a *fresh
resource group of its own* with its own `vnet`/`subnet` at `10.0.0.0/16`
(`perf_bench.sh:104-105`) rather than joining `claude-vnet`, so no private
path from the orchestrator exists at all, and then creates the VM with
`--public-ip-sku Standard --nsg-rule SSH` (`:110`) and connects with
`StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null` (`:118-119`).
Read honestly, that is: port 22 open to the internet with no source-IP
restriction, plus an accepted first-connection MITM window on every run.
Mitigations, such as they are — key-only auth (`--ssh-key-values`), a Spot VM
that exists for the length of one bench, and no secret on the box beyond
public repo source and bench output. The residual is real, not zero. The
teardown that closes the window is `az group delete` (`:88-92`), called
explicitly at three sites (`:123`, `:195`, `:336`) with **no `trap`** — so an
interrupted or crashed run leaves the public-IP VM standing until someone
removes the resource group by hand, and `--keep-vm` suppresses teardown by
design. Check for orphans after any bench that did not print `TEARDOWN`.

⚠ **[CORRECTED 2026-09-02 — this section previously asserted, as an
unconditional property of solver VMs, that they present no external attack
surface whatsoever, with the only caveat being an analyst running from a
laptop off the vnet. The claim was
contradicted by a script shipped in this repo and endorsed by the performance
methodology section above, taking the public path unconditionally — including
when run from the orchestrator. The retired phrasings are registered in
[RETRACTED_PHRASES.tsv](RETRACTED_PHRASES.tsv) and keyed in
[CORRECTIONS.md](CORRECTIONS.md) as `RP-5e7da3fc`. Found by
Codex review V2-L21 #2, filed High and adjudicated Medium on threat model: the
exposure is key-auth-only port 22 on a transient Spot VM holding public source,
so it is a posture contradiction rather than a credential or data-secrecy
stake. The preferred repair is in `perf_bench.sh`, not here — put the NIC on
`claude-vnet/default` with no public IP when the run originates on the
orchestrator, keeping an explicit `--public` flag for the off-vnet case. That
is a change to `scripts/`, which this pass does not own; the exception is
documented rather than closed, and the script change is left open.]**

**How `monitor_canonical.sh` does it:**
- `az network nic create --vnet-name claude-vnet --subnet default`
  (no `--public-ip-address`, no `--network-security-group`)
- `get_ip()` queries the NIC's `privateIPAddress` instead of a public-IP
  resource

**Pre-2026-04-16 monitor scripts** created public IPs and NSG rules per
run; their cleanup paths still attempt to delete those resources for
backward compatibility but new runs don't create them.

**Caveat:** since both VMs must share `claude-vnet`, an analyst running
this from a laptop (not from the orchestrator VM) needs a different
SSH path — either keep the public IP, or set up vnet peering / a jump
host. The orchestrator-on-vnet pattern is the simplest local case.

### Dynamic disk expansion (online resize while solver runs)

Azure managed disks support online expansion while attached to a running
Linux VM with ext4. `monitor_canonical.sh` watches `/data` usage every poll
cycle and grows the disk + filesystem if usage crosses a threshold.

**Settings (env vars, defaults shown):**
- `DISK_EXPAND_THRESHOLD_PCT=75` — trigger expansion when /data is 75% full
- `DISK_EXPAND_INCREMENT_GB=100` — grow by 100 GB per trigger
- `MAX_DISK_GB=1024` — hard ceiling (don't grow beyond 1 TB)

**Mechanism:**
1. `df -BG /data` on the solver VM measures usage
2. If pct ≥ threshold and current disk size < `MAX_DISK_GB`:
   - Orchestrator: `az disk update -g RG-CLAUDE -n solver-data --size-gb (cur + INCREMENT)`
   - Inside VM: `sudo resize2fs $(mount | grep /data | cut -d" " -f1)`
3. Telemetry CSV gets a `disk_expanded` row.

The solver continues writing throughout — no unmount, no reboot, no
disruption. Online expansion typically takes ~30 sec (azure provisioning)
+ ~1 sec (resize2fs).

**Why:** for runs whose final size exceeds initial sizing (especially
100T/1000T where the unique-count projection has wide uncertainty), this
prevents disk-full mid-merge — the failure mode that produced the
2026-04-14 8 GB / 23.7 GB truncation incident. Combined with the static
preflight check (in `solve.c` merge mode and the monitor's launch-time
check), this is defense in depth: preflight rejects obviously-undersized
starts; watchdog handles unexpected mid-run growth.

**Disks can grow but not shrink.** If 100T finishes with the disk grown
to 500 GB but only 200 GB used, the disk stays at 500 GB until manually
shrunk via snapshot + recreate. Cost continues at the larger size until
then.

---

## Reproduce from scratch

1. **Build the solver.**
   ```
   gcc -O3 -pthread -fopenmp -march=native \
       -DGIT_HASH=\"$(git rev-parse --short HEAD)\" -o solve solve.c -lm -lz
   ```

2. **Run a canonical enumeration.** On a machine with ≥64 cores and ≥64 GB
   free disk (128 cores and 1.5 TB for 100T). Use the exact parameter row from
   [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §Reproducibility parameters:
   ```
   SOLVE_DEPTH=3 SOLVE_NODE_LIMIT=10000000000000 \
   SOLVE_PER_SUB_BRANCH_LIMIT=63146557 \
   SOLVE_DFS_ITERATIVE=1 SOLVE_DFS_CHECKPOINT=1 \
   SOLVE_THREADS=128 ./solve 0    # 10T d3 canonical (SOLVE_THREADS=64 gives the same sha)
   ```
   `SOLVE_PER_SUB_BRANCH_LIMIT=63146557` is required: it is the empirical
   per-cell budget the canonical was generated under. If left unset, solve
   auto-divides `node_limit/158364` = 63,145,664, which is 893 nodes per
   cell below the recipe value and produces a valid but different,
   non-canonical sha — see the recipe-table
   comment in solve.c and CANONICAL_HASHES.md §Reproducibility parameters.

   ⚠ **[CORRECTED 2026-09-02 — this gave the auto-divide as 63,146,544 and
   the shortfall as 13 nodes per cell. Both digits were wrong:
   `10000000000000 / 158364 = 63145664`, so the shortfall is 893 —
   `python3 -c 'print(10**13 // 158364, 63146557 - 10**13 // 158364)'`.
   Nothing about the instruction changes: 63146557 is still the required
   value and is still not derivable from the formula. The same wrong floor
   was published in the [CANONICAL_HASHES.md](CANONICAL_HASHES.md)
   §"PSB-formula caveat" table and corrected there on 2026-09-01; this site
   and [BRANCHES_EXPLAINED.md](BRANCHES_EXPLAINED.md) did not receive that
   fix. No sha, record count or file size depends on either figure. See
   [CORRECTIONS.md](CORRECTIONS.md).]**

   Pass `0` as the wall-clock argument for the reproducibility rule — each
   sub-branch runs to its full per-branch node budget, producing byte-identical
   output regardless of thread count or hardware. Empirical timing: 10T d3
   completes in ~83 min on D128als_v7 (Zen 5) or ~5 h on F64als_v6 (Zen 4).
   Walks all 158,364 depth-3 cells but produces **~56K** `sub_*.bin` shards, not
   158,364: a cell that yields zero solutions writes no shard. The archived 10T d3
   run produced 56,404 shard files (HISTORY.md, 2026-04-17: "the remainder had 0
   solutions"); the 11.2T rehearsal produced 56,874. Expect `find . -name 'sub_*.bin'
   | wc -l` in the tens of thousands, and do not treat a count below 158,364 as a
   failure. Then a merged `solutions.bin` (~22.6 GB) and `solutions.sha256`.

3. **Verify the output.** The expected sha is the current canonical, not
   any legacy file in `enumeration/`:
   ```
   gzip -dc solutions.bin | sha256sum
   # (gz-framed by default since #169; every canonical sha is on the DECOMPRESSED stream, so plain
   #  `sha256sum solutions.bin` hashes the container. Under SOLVE_COMPRESS=0 plain sha256sum is correct.)
   # must equal b85c887128ce9881229741380a799c4e1608335df438cedc3da9e087fd94dbbc  (10T d3, 706,427,594 records)
   # or        a09280fb8caeb63defbcf4f8fd38d023bfff441d42fe2d0132003ee41c2d64e2  (10T d2)
   # (the older f7b8c4fb… 10T d3 sha is DEPRECATED — pre-resume-fix undercount;
   #  see CANONICAL_HASHES.md §Deprecated)
   ./solve --validate solutions.bin            # ALL CONSTRAINTS VERIFIED
   ```

4. **Reproduce the scientific analyses.**
   ```
   ./solve --analyze solutions.bin > analyze_output.txt
   ```
   **There is no archived analyze reference for the current `b85c8871…` canonical.**
   Every `analyze_output.log.gz` under `runs/` was produced from an earlier dataset —
   `runs/20260418_10T_d3_fresh/` is the **deprecated** `f7b8c4fb…` file (4,607 records
   fewer), not the canonical you just built. Diffing against it is a structural
   cross-check only, and it *will* report numeric differences:
   ```
   zcat runs/20260418_10T_d3_fresh/analyze_output.log.gz > expected.txt
   diff analyze_output.txt expected.txt
   ```
   **Discriminator — how to read that diff.** Expected (not a regression): the header
   block, timings, and every count-dependent line — total record count (706,427,594 vs
   706,422,987) and the per-section counts, percentages, and histogram bins derived from
   it. A regression: any *structural* difference — a section missing or reordered, a
   constraint reported as violated, a categorical result (which boundaries match, which
   symmetry classes appear) that changes. If you see only count-dependent drift in the
   direction of +4,607 records, the reproduction is good. The authoritative pass/fail for
   step 4 is step 3's sha, not this diff.

5. **Cross-check downstream doc claims** against `analyze_output.txt`. Every
   numerical claim in HISTORY.md / SOLVE_SUMMARY.md / CRITIQUE.md / LEADERBOARD.md
   has a corresponding section in the analyze output.

Per-run archival artifacts live under `runs/<date>_<scale>_<depth>_<runtag>/`. Each
per-run directory contains `solutions.sha256`, `solutions.meta.json`, compressed
enum + merge logs, and a compressed `analyze_output.log.gz`. Treat these as a
**historical record of the run that produced them**, not automatically as the current
reproduction target: `runs/20260418_10T_d3_fresh/`, `…_d3_v1/`, and
`…_10T_d3_d128westus3/` all carry the deprecated `f7b8c4fb…` sha. The authoritative
list of live shas is [CANONICAL_HASHES.md](CANONICAL_HASHES.md); check there first.

The older `enumeration/solutions.sha256` and `enumeration/analyze_c_742M.txt`
files hold the invalidated 742M-era sha and analyze outputs (see HISTORY.md
for forensics). They are kept for audit trail only and should NOT be used as
a reproduction reference.

## Running on cloud (high-level)

The repo intentionally does not ship cloud-provider-specific scripts. Running
the solver on a cloud VM (Azure, AWS, GCP) follows an architecture-agnostic
recipe; adapt to your provider of choice. The pattern we used in April 2026
(Azure spot F64als_v6) is documented in
[DEPLOYMENT.md](DEPLOYMENT.md) Appendix A as a reference example — translate
to `aws ec2`, `gcloud compute`, etc. as appropriate.

Architecture-agnostic rules (all in [DEPLOYMENT.md](DEPLOYMENT.md)):

- **Persistent data volume separate from the compute VM.** Attach a durable
  disk for solver output; VMs come and go, disk persists across evictions
  and recreates.
- **Orchestrator script provisions VM + disk + networking, launches solver
  under `nohup`, exits.**
- **Separate long-running monitor** periodically syncs state from the VM to
  local / archives, detects eviction, handles restart with exponential
  backoff.
- **Completion detection** on a stable marker (JSON status field, not
  stderr text).
- **Teardown** is trap-guaranteed: the VM dies even if the monitor crashes.
  Never delete the data disk.

A new Claude session (or any new contributor) should read DEPLOYMENT.md to
understand the rules, then write provider-specific scripts matching those
rules. Concrete commands vary by provider; the architecture does not.

## Cost expectations (April 2026 baseline)

- Solver run (10T on Azure F64 spot): ~$1.70 uninterrupted, ~$3-5 with 1-2
  evictions.
- Analysis session (F32 spot, `--analyze` on 742M): ~$0.10-0.15 per session.
- Persistent data disk (64 GB Standard HDD): ~$3/mo.
- User's informal budget cap: ~$50/month for an ongoing project at this scale.

Future 100T: projected ~$50-100 on spot with Option B (depth-3 work units)
reducing eviction recovery cost. Without Option B, spot is infeasible (first
attempt projected 30+ days).

Future 1000T: would need architectural changes — solutions.bin at ~2.2 TB
exceeds single-disk capacity; requires chunked output + sharded analysis,
possibly M-series VM for analysis step. Queued, not scoped.

---

## What's pending / open

Beyond the current committed state, the following work is known to be useful
but not yet done. A fresh session wanting to continue the project should
consider these in rough priority order. Much of this section is a dated
snapshot (largely written 2026-04-19; the stalest items carry in-place
status notes below). For up-to-date status see [HISTORY.md](HISTORY.md)
(the dated narrative — it has no single "current state" section; read the
most recent dated entries), [enumeration/LEADERBOARD.md](../enumeration/LEADERBOARD.md),
and the private operational log named in CLAUDE.md §"In-flight state".

### Operational (historical snapshot, 2026-04-19 — no longer in flight)

*(Status note, 2026-08-06: the two items below are kept as a dated record
of what was pending when this list was written. The 100T d3 run completed
2026-04-20, and d3 560T has been the deepest canonical since 2026-06-08 —
see [CANONICAL_HASHES.md](CANONICAL_HASHES.md) and
[enumeration/LEADERBOARD.md](../enumeration/LEADERBOARD.md). The present
tense in these two items is the 2026-04-19 framing, not current state.)*

1. **100T d3 enumeration on D128als_v7 westus3.** Launched 2026-04-19
   ~08:00 UTC; at the time of this doc refresh, enumeration is in flight.
   Expected outcome: a 100T-budget canonical sha that supersedes the 10T d3
   sha as the deepest partial dataset. Per PARTITION_INVARIANCE.md the
   100T sha is distinct from 10T (different `SOLVE_NODE_LIMIT`) but still
   reproducible. Post-run: update LEADERBOARD.md with the new sha +
   canonical count, refresh `--analyze` outputs for the deeper dataset,
   reassess {25, 27} interchangeable-pairs structure at 10× budget.
2. **4-corners validation at 100T.** The 10T d3 canonical has been
   validated across {F64 Zen 4 westus2, D128 Zen 5 westus3} × {external,
   heap-sort merge} (all four produce byte-identical output, see
   HISTORY.md). 100T has only been run via the D128+external corner so
   far; running the other three corners at 100T would tighten the
   partition-invariance empirical claim — but is not required for the
   canonical sha, which is theorem-guaranteed reproducible.

### Scientific / analysis extensions (longer horizon)

Tracked in detail in `LONG_TERM_PLAN.md` (project-local staging in
`~/github/roae-private/`, not committed to this repo). Highlights:

3. **~~Formal proof of forced-orientation (Theorem 6)~~ — CLOSED BY
   RETRACTION (2026-07-26).** The claim was false (complementation is an
   exact symmetry of C1∩C2∩C3∩C5; only oriented C4 breaks it). The true
   replacement statement — the Complement Z₂ symmetry theorem — is
   machine-checked in `lean/KingWen.lean`; C4's orientation is
   definitional — this project's convention, not a classical
   attestation — needing no theorem. ⚠ **[CORRECTED 2026-09-02 — the
   parenthetical here credited the *Xugua* with attesting the
   orientation, written as a hyphenated short form that every earlier
   sweep of this retraction grepped past. The *Xugua* attests that the
   {Heaven, Earth} pair opens, not the order of Heaven over Earth
   within it — 天地 is a compound, not an ordering. What the classical
   record does attest is C1's pairing rule (孔穎達《周易正義·序卦傳疏》,
   二二相耦，非覆即變) together with C4's *pair choice*, which is
   unaffected. Narrowed in [METHODS.md](../reports/METHODS.md)
   §"Constraint set" on 2026-08-30; this file missed the propagation.
   The Theorem 6 retraction this item records is untouched — it rests
   on the complementation symmetry, machine-checked in Lean, not on any
   attestation.]** See SPECIFICATION.md §Theorems and CLAIMS_DECIDED's
   corrections ledger.
4. **Bootstrap confidence intervals** on percentile claims (complement
   distance at 3.9th percentile — a figure flagged 2026-08-01, see
   SOLVE.md §Rule 3 — shift pattern percentages on the current
   canonical datasets, per-position entropies). Report `X% [Y%, Z%]`
   instead of point estimates.
5. **~~Null-model comparison against structured permutations~~ — DONE
   (2026-04-19; this entry corrected 2026-08-06).** Seven null-model
   families are now tested (de Bruijn exact, Gray-code, Latin-square,
   lexicographic, historical, random, pair-constrained) — see
   [CRITIQUE.md](CRITIQUE.md) §"Missing analyses". The claim formerly
   here — that CRITIQUE.md compared only to random and pair-constrained
   permutations — was stale. Costas arrays specifically were not among
   the seven families and remain unexplored.
6. **~~Partition-stability re-check on 100T data.~~ — DONE (measured at
   100T and again at 560T; this entry corrected 2026-09-02).** The outcome
   was *refine*, and sharply: the greedy-ordered minimum boundary-set size
   rose from **4 at d3 10T to 5 at d3 100T and stays 5 at d3 560T**, and the
   count of working unordered 4-subsets collapsed **8 → 0 → 0** over the
   same three scales. No 4-set identifies King Wen beyond 10T, so the
   4-boundary framing is scale-bounded, not a live hypothesis. The
   mandatory-{25, 27} sub-claim survived every scale and partition tested and
   is the one durable part. Full table, method and scope note in
   [PARTITION_STABILITY_BOUNDARIES.md](PARTITION_STABILITY_BOUNDARIES.md);
   the 560T survivor-count correction is in
   [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md).

   ⚠ **[CORRECTED 2026-09-02 — two defects in one item, one of them not in
   the charge that found it. (1) The item was written in the future tense
   ("A 100T dataset will either confirm the full 4-boundary structure or
   refine it"), which reads as an open measurement and invites a researcher
   to re-spend the compute or to cite the 4-boundary structure as live. The
   measurement completed in 2026-07 and the July completion never swept this
   list — the same stale-ledger residue as the archival banner above; found
   by Codex review V2-F15 #18. (2) **The item attributed the wrong family to
   the wrong partition.** It named `{25, 27} ∪ one-of-{2,3} ∪
   one-of-{21,22}` as established on the **d3** 10T canonical. That shorthand
   is the **d2** 10T family — exactly 2 × 2 = 4 sets, and exactly what
   §[8] reports for d2. The d3 10T family is **8** explicitly enumerated
   sets, none of which involve boundaries 21 or 22. Every other site in the
   corpus scopes the shorthand to d2 correctly — CRITIQUE.md:3 and :108,
   SOLVE.md:389 and :603, SOLVE_SUMMARY.md:218, LEADERBOARD.md:178-181 — and
   this was the last remaining site carrying the d3 attribution. Found by
   grepping the retired value rather than the charge's named defect. This
   second half is not registered as a retracted phrase: the string is a
   correct statement about d2 at six other sites, so a needle narrow enough
   to catch this one would have to encode the surrounding attribution, and a
   needle wide enough to be robust would fire on six honest sentences.]**
7. **Connection to known combinatorial structures** (block designs, error-
   correcting codes, group actions). Would elevate empirical findings
   to mathematical connections. Exploratory notes in `INSIGHTS.md` and
   `BREAKTHROUGH_REQUIREMENTS.md` (operator staging in
   `~/github/roae-private/`, not committed to this repo).

### Infrastructure / archival (deferred)

Not planned at this time per operator direction (2026-04-18), but worth
noting so a future session understands the scope they were declined from:

- CI/CD automation (GitHub Actions) for buildability over time.
- Linux-path portability (`/proc/self/exe` fallback for non-Linux).
- Archival deposits (Zenodo + Software Heritage) for 20-year preservation.

All three are discussed in `SCIENTIFIC_REVIEW.md` (project-local).

See [HISTORY.md](HISTORY.md) for the latest dated status (its most recent
entries; there is no single "current state" section), and its §"Missteps
and corrections" table for worked examples of how the project
self-corrects. Items
that were previously in this list and are now complete:

- Hash-table silent-drop fix → commit `585880f` (auto-resizing hash table, zero silent drops).
- Status-label taxonomy → commit `3f0167f` (EXHAUSTED/BUDGETED/INTERRUPTED).
- Option B depth-3 work units → commit `ac5a9ba`; 10T d3 enumeration completed 2026-04-17 with all 158,364 sub-branches processed.
