# PRE-REGISTRATION ADDENDUM A1 — TR-8 dof-matched KW-fitting-predicate sampler — pre-run annotations, **2026-10-03, BEFORE ANY DRAW**

> **What this file is.** The §7 pre-run annotations of the frozen pre-registration
> `PREREG_TR8_DOF_MATCHED_SAMPLER_20260811.md` (private; sha256
> `4b307f07767199b746e770cfa595a3153519a57cdc2043843d9019f71683d2f5`, 66,659 bytes, frozen
> 2026-08-11, escrowed on [PREREGISTRATION_ESCROW.md](PREREGISTRATION_ESCROW.md)). The frozen
> file is **not edited**: its bytes and its escrow row are unchanged. Under the escrow page's
> rule of 2026-09-04 ("a pre-registration file is closed at its freeze"), the annotations the
> frozen text itself calls for — "amendable only by dated annotation appended in §7" (frozen
> file `frozen:24-26`) — are kept as this separate, dated file, and **its own digest is escrowed on the
> same page in the same commit, before any draw**. For the run, the kit reads the byte
> concatenation *frozen file ‖ this addendum ‖ the bank annotation A2* and records the digest of
> each part; a reader holding the private file can reproduce every one of them.
>
> **Every choice below is fixed by the frozen text, not by data.** There is no data: no seed of
> the frozen root `ROAE-TR8-DOFMATCH-2026-08-11` has been fed to any random-number generator
> (§A1.6 lists exactly what was checked). The decisions here either implement a sentence of the
> frozen registration that the public instrument did not yet implement, or close a parameter the
> frozen text left open, each with the line of the frozen file that decides it. Nothing is
> re-chosen; where the text and the public code disagreed, **the code was changed to the text**.
>
> Line citations are written `frozen:NNN` and point into the frozen file's 942 lines (a private
> file; the notation is deliberately not a repository line citation). Costs are not quoted here;
> the registration's ceiling on cost (its §3.6) is referred to as "the cost ceiling".

## A1.1 — Instrument pin (§2, `frozen:133-137`)

The frozen file's one pin that "CANNOT be filled at freeze" is `solve.py` at "the repo commit
that lands the sampler — recorded as a dated §7 annotation *after* implementation and self-test
but *strictly before the first recorded pool draw*" (`frozen:133-137`). The pin is by **bytes**:

- **`solve.py` sha256 `38f3f886dcfed34b36fe5be4de17b2ed5363c719a63d3bde634934738aa4b609`,
  1,003,171 bytes.** This is the file as published with this addendum. The commit that lands it is
  the one that lands this file and cannot name itself; its hash is recorded in annotation A2
  (§A1.5) before the first pool draw, and the sampler writes this sha256 into every run's
  `header.json` (`solve_py_sha256`), so a run on any other bytes is visible as a mismatch.
- The pre-sampler baseline `solve.py` sha256
  `74f6f7dd6312f4c128485f1fa9dc94d148c94e3235009c274cd86fb1f98a4302` (`frozen:125`) and this file
  bound the diff the registration wants auditable (`frozen:135-136`).
- **Self-tests, §4.4 (1)–(5), all green on these bytes** (`python3 solve.py --tr8-dof-selftest`
  and `tests.py` classes `TestTr8DofSampler`, `TestTr8PreregConformanceQ932`,
  `TestHbBandIsDescribedAsImplemented`): (1) `pair_null_draw` reproduces 47/445740 inside the
  §3.5 4σ band at 10⁵ draws, scored by the unmodified `rc4_violations`
  (`test_h_b_null_calibration_tail`, re-pinned to that band today — see §A1.2); (2) H-a asserted
  in code before any pool draw and re-evaluated at merge; (3) determinism and shard/merge
  equivalence; (4) B_raw = 319, bank order, closed band, admitted ⊆ raw, and — new today — the
  per-family comparators of §3.3(i); (5) H = 1054 at 10⁷ (and 527 / 210 / 105 at the §3.4
  truncations), the raw-count boundaries X = 36/37/64/65/935/936/963/964, and L = 469, U = 532.
- **Interpreter pin:** CPython **3.12.3**, the interpreter on which these self-tests and the
  kit's smoke run were executed. The draws are pure functions of the seed through
  `random.Random`, `shuffle`, `random` and `sample` (`frozen:478-481`); the worker's exact version is
  written to every `env.json` and to the kit's token log, and the §4.4(3) determinism test is
  re-run on the worker's interpreter before any pool draw. A different 3.x minor is a disclosed
  deviation, not a silent one.

## A1.2 — The instrument was brought into conformance with the frozen text BEFORE this pin

The public sampler was implemented on 2026-08-11 after the freeze, and compared line by line
with the frozen file on 2026-10-02/03. **Six places differed.** The registration's own text
decides what to do with each: the pin follows "implementation and self-test" (`frozen:133-134`), the
self-tests are against §4 (`frozen:648-662`), and "if the implementation's CI disagrees with the
raw-count column … that is an implementation bug and halts the run; the count column governs"
(`frozen:375-377`). An implementation that computes a different clause, a different bar or a
different rule from the frozen one is therefore not the registered instrument, and it was
corrected **before** being pinned, with no draw in between. Public record:
[CORRECTIONS.md](CORRECTIONS.md) CX-279; the code's own notes name it the same way.

| # | frozen text | the code until today | now | could it have moved anything? |
|---|---|---|---|---|
| 1 | Family **E** = `sign(popcount(σ[2s]) − popcount(σ[2s−1])) ∈ {−1,0,+1}`, EQ (`frozen:226`) | the boolean `popcount(earlier) ≤ popcount(later)` | the three-valued sign, EQ | No drawn predicate: under the pair-only null every E instance has marginal in {1/16, 7/8, 15/16} under either reading (the 28 reversal pairs tie, the 4 complement pairs flip a fair coin), all outside [0.25, 0.75], so none is ever admitted. The published template text for E changes. |
| 2 | **I3** = `sign(Σ_{t=1}^{62}(d_t − d̄)(d_{t+1} − d̄))`, **EQ** (`frozen:238`) | the raw product sum `Σ d_t·d_{t+1}`, **GE** | the sign of the exact lag-1 autocovariance, EQ, computed in integers | Not expected: on throwaway roots the marginal of the registered I3 is ≈ 0.79 and of the old clause ≈ 0.86, both far above the band's upper edge at N_calib = 10⁵ (SE ≈ 0.0013). The frozen-seed calibration (A2) decides it; the halt rule of §A1.3(k) covers the case where it does not prune. Family I's comparators are now per instance, exactly as the family-I table pins them (`frozen:234-240`). |
| 3 | "P is at least as rare as King Wen" is the **integer** test `hits(P) ≤ H`, H = ⌊N_pool·47/445740⌋ (`frozen:316-320`) | the float test `hits/N_pool ≤ float(47/445740)` | the integer test, H from the exact rational | Identical at N_pool = 10⁷ (1054 ≤ H, 1055 > H either way); it is now the registered definition, and H is written into `results.json`. |
| 4 | D1 is read from F̂'s interval; "D2 does **not** alter D1" (`frozen:358-369`, `frozen:397`) | the verdict was forced to INCONCLUSIVE whenever the K = 16 median was censored | D1 from the interval only; D2 reported beside it; at N_pred = 1000 the interval verdict is cross-checked against the raw-count column and the merge **halts** on a disagreement (`frozen:375-377`) | Yes, had the median been censored: a BULK / TAIL-EXTREME / COMMON run would have been reported INCONCLUSIVE by the public command. |
| 5 | H-b bar: `\|n_le2 − E\| ≤ 4·√(E·(1 − 47/445740))`, i.e. **[925, 1184]** at 10⁷ (`frozen:383-388`) | `\|n_le2 − E\| ≤ 5·√E + 3`, Poisson, ≈ [889, 1219] | the frozen 4σ binomial band, computed from the exact rational | Yes, for `n_le2` in 889–924 or 1185–1219: the public command would have passed a pool the registration quarantines. |
| 6 | the §3.3(ii) abort floor "B_admitted < 120 ⇒ the run does not proceed" (`frozen:276-279`, `frozen:639`); the pool-B gate (`frozen:409-413`); the mean pairwise clause overlap and family composition (`frozen:341-344`); the raw-count cross-check (`frozen:375-377`) | not implemented | implemented: the sampler and `--tr8-dof-emit-bank` halt below 120 before any pool draw; `--tr8-dof-merge A --tr8-dof-replicate B` applies the gate and writes the governing verdict to `replication.json`; `results.json` carries `ensemble_context` | The verdict a reader can reproduce from the public command is now the registered one, including the override list of `frozen:379-381`. |

**What did not change, verified by the self-tests on these bytes:** the null draw
(`pair_null_draw`, the H-b identity `frozen:166-170`), the 319 templates of families A–D, F–H and
I1/I2/I4/I5, the bank order (`frozen:246-248`), the closed band (`frozen:263`), the seed derivation and the
23 materialised seeds (`frozen:446-466`, re-derived by the kit from the strings: 23/23), the K ladder,
N_pool, N_pred, N_calib, the Clopper–Pearson and order-statistic intervals, and the median
definition.

**Disclosure.** Deciding items 1 and 2 required looking at clause marginals on *throwaway* seed
roots (the public smoke example, the unit tests, and the kit's smoke run). Those are marginals
of two instances the band prunes, measured on roots that are not the frozen one; the band, the
families and every bar were frozen on 2026-08-11 before any of them was computed, so nothing
they show could re-choose anything. No frozen-root marginal, no F̂ and no median has been seen.

## A1.3 — Open parameters, each fixed now by the frozen text

**(a) An interrupted shard.** `frozen:439-440`: "Draws are NEVER discarded selectively. No shard is
redrawn under any outcome. No pool is extended. No seed is re-rolled." `frozen:748-749`: "If the VM is
evicted mid-run … shards are not redrawn, and a partial pool is either prefix-truncated by dated
annotation *before any statistic* or quarantined." `frozen:478-479`: each shard "is drawn by
`random.Random(seed_shard)`", a pure function of its seed; `frozen:655-656` (§4.4(3)): identical seed
⇒ identical hit counts across processes. **Fixed:** a shard process that stops before writing
its `shard_<pool>_<i>.json` has produced no draw that exists anywhere — the instrument writes
nothing until the shard completes — and is **re-executed once, from the start, on its own frozen
seed, to its full count**; by §4.4(3) the result is the bytes the first attempt would have
written, no new randomness enters and nothing is selected, so this is not a redraw in the sense
`frozen:439` forbids (a replacement of draws by other draws). The re-execution is recorded in the kit's
token log (`SHARD_<pool>_<i>_REEXEC=deterministic_same_seed`) and in the result annotation with
the time of the stop. A shard whose file exists is never re-executed. If the re-execution also
fails, the pool is **quarantined** (`frozen:749`); it is not prefix-truncated, because the truncation
clause is triggered by the timing probe before any draw (`frozen:429-431`) and that trigger will have
passed. The worker is a Standard (non-Spot) VM (§A1.3(g)), so an eviction is not expected.

**(b) Deciles of log₁₀ r̂** (`frozen:341`). **Fixed:** the ⌈q·N_pred⌉-th order statistic of the sorted
r̂ for q = 0.1 … 0.9 — nearest rank, **no interpolation**, exactly as the instrument's
`_tr8_quantile` has computed them since 2026-08-11. This is the same order-statistic reading
§3.4 uses for the median's interval (`frozen:333-338`), and it is the only reading under which a
censored decile stays exactly 0 and is printed as a bound ("cens"), never as log(0) or as a
smear between a bound and a point.

**(c) Exactly N_pred/2 zero-hit predicates.** `frozen:394` defines CENSORED as "at least half have
hits = 0"; `frozen:392` glosses UNCENSORED as "fewer than half … i.e. the median order statistic is
> 0". At exactly 500 of 1000 the two sentences part: the median (`frozen:333-334`, the mean of the
500th and 501st order statistics) would be the mean of a censored 0 and a point, which is
neither a point nor a bound. **Fixed:** the operative definition `frozen:394` governs — exactly half
is **CENSORED**, reported as the bound `< 1/N_pool` with the censoring fraction 0.500. The
instrument's `median_censored = (2·n_cens ≥ N_pred)` already says so.

**(d) Mean pairwise clause overlap** (`frozen:343`, `frozen:281-285`). `frozen:282-283` defines the quantity it
is meant to check: "the expected clause overlap between two independent predicates is
≈ K²/B_admitted". **Fixed:** the mean of |P ∩ Q| over **all** C(N_pred, 2) unordered pairs of
drawn predicates at each K, computed exactly from the per-clause draw counts (Σ_c C(n_c, 2) /
C(N_pred, 2)), reported beside its K²/B_admitted reference. Family composition (`frozen:343`) is the
count of clause slots per family across the N_pred predicates at each K (summing to K·N_pred).

**(e) Geometric-mean admitted-clause marginal** (`frozen:342`). `frozen:539-543` (§3.11(b)) says why it is
published: "r ≈ q^K … §3.4 mandates publishing the geometric-mean marginal, so a reader can see
the mechanism". **Fixed:** the geometric mean of the calibration marginals q̂ of the **admitted
bank**, one value per admitted instance, unweighted by how often a clause was drawn — the q of
`frozen:538`. Reported by the instrument as `geometric_mean_admitted_marginal` since 2026-08-11.

**(f) Order of calibration and probe.** `frozen:701-704` (§5(b)) runs `--tr8-dof-emit-bank` on the
calibration pool and appends the bank to §7 as the self-test stage that **blocks** (c); `frozen:741`
lists the worker-side sequence "timing probe → calibration pool → pools A and B"; `frozen:488-489`
(§3.8) requires the probe to time "draws/s per core and peak RSS", which depend on the admitted
width B_admitted. **Fixed:** the calibration (bank) runs **first**, as §5(b) orders, then the
probe times the real admitted width, then the pools. The probe's throwaway predicate ensembles
are drawn on the **timing-probe** seed, not on the frozen `predicates/K-<K>` seeds (`frozen:461`,
`frozen:483-484`: "probe-only, never a recorded pool"), so the first use of a frozen predicate seed is
by the shards, after A2 exists. The probe's hits are discarded unread (`frozen:489-491`).

**(g) Worker.** `frozen:709-714` names a westus2 Spot D4als_v7 or D8als_v7 and "westus3 hosts the live
Stage G run and is not to be touched". `frozen:642` classes the data layout as "performance, not
science — free to change without amending §3"; the draws are host-independent (§A1.1). The
project's standing VM rule since 2026-08-29 (CLAUDE.md §"Cost control — VM purchase type")
places work that cannot checkpoint — these pools write nothing until a shard completes — on a
**Standard, right-sized** VM, never Spot. **Fixed:** a Standard D8als_v7 or D16als_v7 (16 shard
processes, two pools × eight), in whichever of the project's regions the standing rules allow at
launch; the Stage G run that `frozen:714` protected has since ended. This is an operational deviation
from `frozen:709-714` that changes no draw, recorded here because the registration named a SKU. The
§3.6 ceilings (2 h wall; the cost ceiling) stand and are checked by the probe (§3.8).

**(h) Interpreter.** Fixed in §A1.1: CPython 3.12.3, re-verified on the worker by §4.4(3).

**(i) Knife-edge admission — a disclosure, not a choice.** Family C's clause at slot s is
`bit_diff(σ[2s−1], σ[2s]) == d_KW(s)` (`frozen:224`). Under the pair-only null, slot s holds a
uniformly random one of the 32 fixed pairs, whose within-pair distances are {2: 12 pairs, 4: 12
pairs, 6: 8 pairs}; so the **true** marginal of a C instance is exactly 12/32 = 0.375 at a
distance-2 or distance-4 slot and exactly **8/32 = 0.25** at each of the 8 distance-6 slots —
the band's closed lower edge (`frozen:263`). Each of those 8 instances is admitted iff its calibration
count is ≥ 25,000 of 10⁵, about a fair coin each, decided by the frozen calibration seed. **No
rounding, no substitution of the exact marginal, no re-draw**: `frozen:259-263` admits by the
*measured* q̂ on the frozen calibration pool, and the band is closed. B_admitted may therefore
land anywhere in a range of width 8 for this reason alone; that is calibration noise on an exact-
edge marginal, recorded here so it is not read as a choice. (On throwaway roots 27–28 of the 32
C instances were admitted.)

**(j) No instance is dropped for cost.** `frozen:288-289` allows instances to be dropped "at that
point for cost, dated and with reason". **Fixed:** none is; B_admitted is as measured.

**(k) Conformance check on the frozen calibration stream, and what halts.** The private run
kit (§A1.4) carries an independent transcription of all 319 extractors written from `frozen:220-240`,
and evaluates both it and the public code on the **identical** calibration draw stream.
**Fixed:** any instance on which the two disagree on any draw, or any comparator mismatch, or
any difference in the admitted set, **halts the run before any pool draw**; the code is then
conformed to the text and re-pinned by a further dated annotation, and the calibration is
re-run from the same frozen seed (deterministic). There is no ruling that lets a divergent
instrument proceed.

**(l) Which computation governs.** The registration's "published with its seed and probe count"
and "the exact reproduction command" (`frozen:754-757`, `frozen:677-678`) require that the public command
reproduce the published verdict. **Fixed:** the governing D1, D2, gates and §6 outcome are the
public instrument's — `python3 solve.py --tr8-dof-merge B_DIR`, then
`--tr8-dof-merge A_DIR --tr8-dof-replicate B_DIR`, whose `replication.json` carries
`governing_d1_k16` and `s6_outcome` (A reported, B never substituted, `frozen:413`). The kit
re-derives every statistic, gate and verdict from the shard files and the frozen text
independently; **if the two disagree on any gate, verdict or count, the run is void** — no
verdict is published, the disagreement is recorded as an implementation finding, and a new
dated annotation precedes any further attempt. The verdict is then decidable by counting X
(`frozen:364-369`) from the published per-predicate hits by anyone.

**(m) Truncation.** Not exercised. If the §3.8 probe projects more than 2 h or more than the
cost ceiling for the frozen counts, the run **stops** (`frozen:491-492`) and a further dated annotation
(A3) records any §3.6 truncation — per-shard count a multiple of 100,000, H recomputed by
`frozen:318` — before any pool draw. No truncation is pre-authorised here.

**(n) Nothing adaptive.** `frozen:405-408`: no extension, no re-banding, no post-hoc K, no clause
dropping after any rarity is computed. The kit has no flag for any of them.

## A1.4 — The run kit and the file the run is read against

The run is executed by a private kit (`roae-private/review_2026_09_27/q932_tr8_sampler/`,
`run.sh` + `kit.py`; their sha256 values are printed into every phase's token log) that only
drives the public instrument and checks it. It refuses to draw a pool unless: the frozen file
hashes to `4b307f07…`; the file it is given is the byte concatenation *frozen ‖ A1 ‖ A2* with no
frozen line changed or deleted; the `solve.py` under test hashes to `38f3f886…`; the commit it
checked out is the one A2 names; A2 carries the admitted-bank digest that `header.json` will
carry; the conformance check of §A1.3(k) passed on the frozen calibration stream; and the §3.8
probe gate passed. Every phase runs under `timeout`; the pools share one 2 h deadline.

## A1.5 — Annotation A2, fixed in form now, produced later with no human choice

After the calibration (§5(b), `frozen:701-704`) and before the first pool draw, the kit's `bankpost`
step writes A2 **mechanically from `bank.json`**: the calibration seed and draw count; B_raw;
B_admitted and the count per family; the admitted-bank sha256 in exactly the expression
`header.json` uses; the ordered list of every admitted instance with its comparator, measured
q̂ and template; the public commit hash and the `solve.py` sha256 of §A1.1; the worker's
interpreter version; the conformance tokens of §A1.3(k); and the sentence "No instance dropped.
No instance added. No rarity has been computed." Its sha256 is written to the kit's token log
before the first pool draw and is published on the escrow page with the result. The only human
act in A2 is appending it.

## A1.6 — Attestation: what has and has not been run

- The frozen root's 23 seeds (`frozen:838-862`) have **not** been used. Checked 2026-10-03: the
  private repository contains the frozen root only in the frozen file, this run's preparation
  report, and `solve.py`'s default constant inside archived source trees — in no run record,
  log or output; the public tree never invokes the sampler or `--tr8-dof-emit-bank` without an
  explicit throwaway `--tr8-dof-seed`; every unit test, the `--tr8-dof-selftest`, the public
  smoke example and the kit's smoke run use throwaway roots (`TR8-TESTS-THROWAWAY`,
  `TR8-SELFTEST-THROWAWAY`, `TR8-Q932-CONFORMANCE-THROWAWAY`, `SMOKE-THROWAWAY-DO-NOT-CITE`,
  `Q932-SMOKE-THROWAWAY-NOT-A-RESULT`), and the kit refuses the frozen root in smoke mode.
  This is attested from those checks; it is not a proof that no one ever typed the default
  command interactively, and no record of such a run exists.
- Nobody has seen a value of F̂, of any median, or of any frozen-root clause marginal.
- No VM has been created for this run.
- This addendum, its escrow row, CX-279 and the conformed instrument are published together,
  **before** the run, which is what makes the escrow of this file a pre-measurement one — the
  first such row the escrow page carries.

*Developed with AI assistance (Claude, Anthropic): decided and written by claude-fable-5-1,
batch 36, Q-932, 2026-10-03, from the frozen text alone. The §3.11(b) objection — that the
answer is a strong function of the clause bank — is not touched by anything here and travels
with any result.*
