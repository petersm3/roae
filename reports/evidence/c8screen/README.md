# Pilot A, the pre-registered C8 screen: evidence bundle (2026-10-11)

**What this is.** The record of one pre-registered screen of the King Wen (KW) sequence: a family of
1,349 label-free slot and adjacency statistics, counted and frozen before any of them was evaluated on
King Wen, each scored against the C1–C5 population. The pre-registered verdict is
**`FAMILY=UNINFORMATIVE`**: 0 survivors, 680 testable members all NULL, 669 members that could not reach
their bar for any ordering (`UNINFORMATIVE ATTAIN`), 0 forced. No claim is made, no scoreboard row is
added, and no follow-up run is planned. The corrections entry is
[CORRECTIONS.md](../../../documentation/CORRECTIONS.md) CX-354.

## The result, in the words of the verdict review

The text below is the publish-regardless wording of the registration's §8.4 for the UNINFORMATIVE
outcome, as drafted by the verdict review (gate P4, Claude Fable 5.1) and used here verbatim:

> **Pre-registered C8 screen (2026-10-11): unresolved, no claim.** A family of 1,349 label-free slot and adjacency statistics of
> the pair-slot sequence — membership counts under all 651 order-16 XOR subgroups of (ℤ/2)⁶ (Ouyang 1993's coset idea
> generalised), the eight trigram relations across the 31 boundaries (the tradition Han 1984 describes), and the positional
> structure of the difference wave, the yang-count walk (程頤, Schulz) and the trigram and pure-hexagram slots — was counted and
> frozen before any member was evaluated on King Wen (frozen digest `2ba24ece…`, amendment `3429f1d2…`; the freeze is attested,
> not externally checkable). Each member was scored against the C1–C5 population by the weighted-Knuth estimator (2×10¹⁰ probes
> in two seed-disjoint halves, 35,942,553 scored leaves, self-validation within 0.03 % of the published count) with a family-wise
> two-sided Bonferroni correction at α = 0.01, split equally between the 1,300 subgroup-scan members and the 49 structural members.
> **No member fell below its bar.** 680 members were testable and all were null; the smallest operative two-sided p in the family
> was 4.1×10⁻⁴ (member `C-N[392]`, against a bar of 3.8×10⁻⁶), which is the level a null family of this size produces by chance.
> The remaining 669 members could not have reached their bar for any ordering: 632 of them (every entry-in-subgroup count
> `C-M[H]`) take at most 14 consecutive values whose extreme has probability at least 2⁻¹³ under the pair-only null, so their
> smallest possible two-sided p (2.4×10⁻⁴) exceeds the bar by a factor of 63; the other 37 have similarly coarse laws. Under the
> frozen rule more than 5 % untestable members makes the family verdict **UNINFORMATIVE** rather than NULL, and that is the verdict
> recorded: the instrument did not resolve the family, and no claim is made. This limit is a property of the family's composition
> and bar, not of the run length — a larger run would not change it — and is recorded as a design lesson: a family-wise cap must
> be priced against each member's minimum attainable p before freeze. King Wen's values on all 669 untestable members lie in the
> bulk of their estimated laws (operative p ≥ 3.6×10⁻³), stated as description only. The registration, instrument, verdict script
> and unfiltered run outputs are published with this note.

**The registration's own sentence for this outcome.** §8.4 prescribes, for `UNINFORMATIVE`, the
sentence *"the instrument did not resolve the family at this size (669 members unattainable, 0
unreplicated); no claim is made"*, and it is recorded here as written. The wording above departs
from it in one phrase: it does not say "at this size", because the limit is a property of the
family's composition and bar, not of the run length, as the next paragraph shows. This is the third
departure from §8.4; the other two concern the public copy and are listed below.

**The design lesson, plainly.** The screen was built so that its "null" outcome could not happen.
`C-M[H]` counts the pair entries that lie in the subgroup `H`. Pairs wholly inside or wholly outside
`H` contribute a fixed amount whatever their orientation, so only the pairs split by `H` move the
count, one fair coin each under the pair-only null, and no subgroup splits more than 13 of the 31 free
pairs. The most extreme value of every `C-M` member therefore has probability at least 2⁻¹³, and its
smallest two-sided p is 2·2⁻¹³ = 2.4×10⁻⁴, 63 times the bar of 3.85×10⁻⁶. That is one line of
arithmetic, the same argument the registration's own §2.4 makes to exclude single-slot statistics, and
it was not applied to `C-M` before the freeze. With 632 such members against a cap of 67 (5 % of the
family), `FAMILY=NULL` was out of reach from the moment of freeze, whatever King Wen's values. ⚠ *(Scoped 2026-10-17: the 2⁻¹³ floor is a fact about the pair-only null N0, not the N1 population the verdict uses — see §"Notes on the frozen registration" below.)* The
632 members also added to the Bonferroni count without adding any power, so every other
subgroup-scan member paid a bar of 0.005/1300 instead of 0.005/668. A future screen must compute each member's minimum
attainable p under the cheapest null before it freezes, and either exclude the members that cannot
reach the bar or price the cap against them.

**No follow-up run.** The registration permits only a new dated registration, and none is warranted.
No run length changes the `C-M` floor: the extreme bins already hold hundreds to millions of scored
leaves each. ⚠ *(Scoped 2026-10-17: the 2⁻¹³ floor is a fact about the pair-only null N0, not the N1 population the verdict uses — see §"Notes on the frozen registration" below.)* The other 37 untestable members could at most move from `ATTAIN` to `NULL`: King Wen's
operative p on each of them is at least 0.038. On all 669, King Wen's raw tail mass is at least
1.8×10⁻³ with at least 64,285 scored leaves behind it.

**What "closed" means here.** The registration ties "the C8 route is closed for this class" to
`FAMILY=NULL`, which did not occur. Read member by member, the screen is closed for the 680 testable
members at the declared power. These are the whole `C-D` scan (18), 619 of the 650 `C-N` subgroup counts, all eight boundary trigram
relations, the nine difference-wave positional members, the four yang-count walk and run statistics,
six of the ten yang-sum-class positional members, and 16 of the 18 trigram-content members
(18 + 619 + 8 + 9 + 4 + 6 + 16 = 680). The family as a whole is formally unresolved. For
the 632 `C-M` members the result says nothing about King Wen at all: the class cannot single out any
ordering at a bar of this size, so it belongs in the next registration's exclusion table.

## Notes on the frozen registration (2026-10-17)

Codex's final review (gpt-6-astra; runs F02-001, F02-002, F02-003, F02-004 and F02-006) checked the registration
and this note against the shipped outputs; Fable triaged the findings. The registration is frozen and is not
edited; each point below is recorded in [CORRECTIONS.md](../../../documentation/CORRECTIONS.md) (fast-track
batch FT2b-4). The verdict, `FAMILY=UNINFORMATIVE`, and every count above are unchanged.

- **The 2⁻¹³ floor is an N0 fact.** The one-line arithmetic above holds under the pair-only null N0, where each
  split pair is a fair coin. The verdict is read against N1, the C1–C5 population, and under N1 the floor does
  not carry over: `SUMMARY.tsv`'s `min_attainable` column puts 208 of the 632 `C-M` members below 2·2⁻¹³
  (the smallest, 1.56×10⁻⁴). All 632 are still at least 40 times the bar 3.85×10⁻⁶, so the `ATTAIN` verdicts
  stand. But "whatever King Wen's values" and "no run length changes the `C-M` floor" are not shown by the N0
  argument. What the no-follow-up decision rests on is measured: King Wen's operative two-sided p on every one
  of the 669 untestable members is at least 3.6×10⁻³ under N1.
- **The power boundaries in §4.2.** The registration sizes detectability with `p_t + 3·sqrt(p_t/ESS) < β`,
  a one-sided tail's error applied to a two-sided `p_t`. With the two-sided error, `p_t + 3·sqrt(2·p_t/ESS) < β`,
  the boundaries are 2.1×10⁻⁶ (stratum C) and 9.1×10⁻⁵ (stratum S), not 2.5×10⁻⁶ and 9.4×10⁻⁵.
- **The rule of three on weighted masses.** §5.1 sets an empty tail to `3/L`. On importance-weighted masses
  that is not a bound (METHODS §"Statistics conventions" reports a zero-hit estimate as starvation). No King
  Wen operative p in this screen took that value: the smallest is 4.1×10⁻⁴.
- **N0 is not TR-8's null (b).** §4.1 names N0 as TR-8 §2's null (b), in the TR-8 sampler's lineage. N0 pins
  `(63, 0)` to slot 1 (31!·2³¹ orderings); TR-8's null (b), which the TR-8 dof-matched sampler and
  `pair_null_gender_le2_exact()` use, draws all 32 pairs freely (32!·2³²), a population 64 times larger.
- **"Every literature pattern … sits at the mode of its null"** (§0) is not so: Schulz's S25–28 trigram
  configuration has C1–C5 mass about 2×10⁻⁸ (TR-1), and the Q-OY1 statistic's King Wen value, D = 94, is
  not its N0 mode (D = 52, `qoy1_q992/n0_exact.out`).
- **CX-354's "nearly doubled the bar".** Counting the 632 `C-M` members set the subgroup-scan bar at
  0.005/1300 instead of 0.005/668: the bar was roughly halved, a stricter test for every other member.


| item | value |
|---|---|
| frozen file (private) | `PREREG_C8SCREEN_2026_10_11.md`, 45,464 bytes |
| sha256 of the frozen original | `2ba24eceb2bddcba3c14f40231c1024c9a94d79c1ba37225eece1c84a969f161` |
| locked | private commit `b2fa6f9d`; lock-ledger entry 2026-10-11 01:03:24 UTC |
| public copy | [PREREGISTRATION.md](PREREGISTRATION.md), 44,113 bytes |
| sha256 of the public copy | `de89498bb6df51fe55b271f22ac26fcec919653203e5a92677d39075cbca1d67` |
| amendment 1 (§9-A1 … §9-A4), verbatim | [PREREGISTRATION_AMENDMENT_1.md](PREREGISTRATION_AMENDMENT_1.md), 23,335 bytes, sha256 `3429f1d2272a74344fd6af06cde4e6ba2fcd3c0f57c798053c2f8c0eec6ba8b5`; private commit `d7e2eb23`; lock-ledger entry 2026-10-11 05:01:23 UTC |
| freeze-time check script | [prereg_c8screen_defcheck.py](prereg_c8screen_defcheck.py), sha256 `bb017ec5fc57f20acd0e6e20fff4053fe46e29ce1c13659994cbf019080e8091` (same commit and ledger entry as the frozen file) |
| amended check script | [prereg_c8screen_defcheck_a1.py](prereg_c8screen_defcheck_a1.py), sha256 `28889b9f4f50e02ccda9ea6359c7c7b1cdafd367fe3c678d0d325bda34022adb` (same commit and ledger entry as the amendment) |
| pre-run gates recorded | 2026-10-11 05:44:25 UTC ([gates.txt](gates.txt)) |
| instrument pin recorded, then first King Wen evaluation | 2026-10-11 05:51:27 UTC ([S9_A5_INSTRUMENT_PIN.txt](S9_A5_INSTRUMENT_PIN.txt); `C8_KW_DATE_UTC` in `kw.out`) |

All five digests are also on [PREREGISTRATION_ESCROW.md](../../../documentation/PREREGISTRATION_ESCROW.md)
§"2026-10-11 — the Pilot A C8-screen pre-registration and its amendment: frozen privately before
measurement, published with the result". They were published there with the result, not before the run.

**Digests the registration and the amendment quote in short form**, given here in full:

| short form | full value | what it is |
|---|---|---|
| `c5341672…` | `c53416726ec065c7c1d4804ebbd58e035277d8b208f6d142c244dc0560b4d62a` | sha256 of the scorer patch as built, before amendment 1 |
| `e07e64a4…` | `e07e64a4525739f7415c0c6cf9bd4e7dad848396b621a6319738295012e9de78` | sha256 of the reference-code extract of the frozen check script (amendment 1 replaces it with `6a1aa402…`) |
| `83cff06a…` | `83cff06adc89954c52d9cc67f7efbb47e774f3ba17cf2d16f9dc9abcab0b2e45` | sha256 of the verdict script before amendment 1 (now `65d98b44…`) |
| `4b590dfc…` | `4b590dfcbd0024beefd2bf354949e66ef95c951b` | git tree id of the staged Q-OY1/Q-992 instrument the registration first named as its base |
| `a4014080…` | `a40140806206cb9ef13bcb2efd40d62a90a8a7fb` | git tree id of the instrument the runs used (below) |

**The amendment is published byte for byte.** A reader can hash it and get `3429f1d2…`. It was written
and locked after the scorer build and before any measurement. It widens four binning ranges (A1),
defines when a corpus control counts (A2), declares added output lines (A3) and makes one annotation
rule exhaustive (A4). It says that no King Wen value existed when it was written.

**The public copy of the registration is not byte-identical to the frozen file.** Three passages that
state costs were removed, and nothing else was changed:

1. Line 26, the last sentence of the header box, pointed to §7.6 and stated a spending limit. It is
   replaced by `[cost sentence omitted from the public copy]`.
2. §7.6 ("Where, and cost"), lines 371–382 of the frozen file, is replaced by the single line
   `### §7.6 [cost section omitted from the public copy]`.
3. In §8.2 step 3, the clause on how a follow-up instrument would be priced and approved, at the end
   of line 413 and all of line 414, is replaced by `[cost sentence omitted from the public copy]`.

`diff` against the frozen file shows exactly these three hunks. Because of them the public copy's
digest differs from the frozen one, and a reader cannot recompute `2ba24ece…` from this repository.
The frozen digest is given so that the file can be checked if it is ever disclosed. Paths in the copy
that point into the private repository, and the author's checkout path on line 53, are left as
written. The registration's own §8.4(i) asks for private paths to be glossed. This copy follows the
precedent of the Q-OY1/Q-992 bundle instead, so that the diff against the frozen file stays exactly
the three cost hunks; the files those paths name are private, except the two check scripts, which
ship here.

**What the timing evidence is.** As the registration's header box says, freeze timing for a
pre-registration kept in a private repository is **attested, not checkable by an outside reader**. The
commit and ledger times above come from the private repository's history. They are a claim, not a
proof. What a reader *can* check is that every rule applied to the results is the one written in the
public copy and the amendment, and that [analyze.py](analyze.py) re-derives every verdict token from the
shipped outputs.

## Contents

| file | what it is |
|---|---|
| `TOKENS.txt.gz` | every result token (`KEY=value` lines, 2,675,560 bytes uncompressed); the family verdict is the last line, `FAMILY=UNINFORMATIVE` |
| [SUMMARY.tsv](SUMMARY.tsv) | one row per member: King Wen's value, the operative two-sided p and its halves, tail leaves, minimum attainable p, N0 and N1′ p, verdict and reason |
| `N1_A.out.gz`, `N1_B.out.gz` | unfiltered stdout+stderr of the two C1–C5 runs (10¹⁰ weighted-Knuth probes each, §6 seeds) |
| `N1P_A.out.gz`, `N1P_B.out.gz` | the same for the two runs with the C6/C7 slot pins (5×10⁹ probes each; annotation only) |
| `N0.out.gz` | the pair-only null N0, 10⁷ draws (single-threaded, a function of its seed) |
| `N1_A.out.evicted1` | the first, interrupted attempt at N1_A: the machine was stopped after the four header lines. Kept and labelled, not pooled; N1_A was re-run from scratch with the same seed (§7.3) |
| `*.done` | per-run completion records: exit code, wall seconds, seed, launch number, sha256 of the uncompressed output |
| `kw.out` | `solve.py --c8-kw`: the 1,349 member values on King Wen, with the instrument pin echoed and the evaluation time |
| `controls.out` | `solve.py --c8-controls`: the member values on the Jing Fang, Mawangdui and Fu Xi orderings, `NA` per amendment A2 |
| `members.tsv`, `subgroups.tsv` | `solve --c8-list members` and `--c8-list subgroups`: the member table with declared ranges, and the 651 subgroups in canonical order |
| `gates.txt` | the pre-run gates (§7.2 as amended): digests verified, defchecks, the two-language gate and its mutant, build, self-test, instrument pin |
| [S9_A5_INSTRUMENT_PIN.txt](S9_A5_INSTRUMENT_PIN.txt) | the §9-A5 instrument pin, written before `--c8-kw` ran, kept beside the run so that the locked amendment bytes stay unchanged |
| `c8_gate_full.out`, `c8_gate_mutant.out` | the two-language gate (`solve.py` against `solve.c`) on 10⁵ gate-seed orderings, and a parity mutant that must fail |
| `seeds_rederived.out` | the six §6 seeds re-derived from their frozen strings |
| `binary_fresh.out`, `ANALYZE_SELFTEST.txt` | the build-freshness check and the verdict script's synthetic self-test |
| [analyze.py](analyze.py) | applies the frozen §5 rules as amended to the files above; its stdout is `TOKENS.txt` and it writes `SUMMARY.tsv`; sha256 `65d98b444d3d4928d78efd178c0145b88b0afcc54542826d0724f3f8278c5009`, the value amendment §9-A0 pins |
| [prereg_c8screen_defcheck.py](prereg_c8screen_defcheck.py), `defcheck.out` | the freeze-time check of the family count, the member definitions on synthetic orderings and the exclusion theorems (it never reads King Wen's order) |
| [prereg_c8screen_defcheck_a1.py](prereg_c8screen_defcheck_a1.py), `defcheck_a1.out` | the same, as amended |
| [instrument_pin_a4014080.patch](instrument_pin_a4014080.patch) | the exact instrument the runs used (see below); sha256 `ba30dd4ec1e2243259fc44637173f46d0e43623a4617d7dc620b046e34edcb66` |
| `RECORDED_SHA256SUMS` | the run record's own digests, for the shipped files, of the uncompressed bytes |
| `SHA256SUMS` | the digests of every file in this directory as shipped, except itself |

The six large outputs are compressed with `gzip -9 -n`. Each shipped file is under 1 MB; the
uncompressed outputs are 1.9–2.8 MB each.

**Scrubbed.** These files were copied from the private record unchanged. Before copying, every file,
including the uncompressed outputs, was checked for network addresses, machine and resource names,
account identifiers and costs, and none was found. Left out of this bundle: the machine-lifecycle
files and the lane log (they name the temporary machine and its paths), the captured `tests.py`
output (it names the machine's checkout path), a pre-measurement smoke run of `--c8-null0` on the
non-frozen seed 7, the empty stderr captures, and the private record's own digest files. `gates.txt`
records the compiler, the CPU model and the thread count.

**Three files name the private repository and four carry a checkout path**, and all of them must ship
as they are. The registration copy keeps its paths as written (above). The amendment is published byte
for byte, so that a reader can recompute its locked digest; its line 180 names the private repository.
Line 12 of both check scripts hard-codes the author's checkout path; change it to your own checkout
before running them. The instrument-pin patch must reproduce the pinned files byte for byte, and
those files name the private registration path. The two evidence sweeps in `tests.py` exempt these
files only while their whole sha256 equals the value recorded in this README (CX-354 item 6).

## The instrument, and how the committed code differs from it

The runs used a staged, uncommitted instrument: tree `a40140806206cb9ef13bcb2efd40d62a90a8a7fb` on public
commit `9967ec14c364cf10d2b5010a3cfc5c792a0dbb66`, with `solve.c` sha256
`eab41a106fc8385486e70b376ac66cee54e7c2b590c68ba230056e62e52b6dcb`, `solve.py`
`5d194b325cd79e03d9e5c4a4d03bdf46c2a8ba18409082e8569b76d158d5d502` and `tests.py`
`a4eed2821e19609db0f9394f5c79e9fae7d6b0aee723c8f42a124f6a458abc75`. That tree is 9967ec14 plus the then
unlanded Q-OY1/Q-992 instrument, the C8 scorer and amendment 1. `instrument_pin_a4014080.patch`
reproduces the three files exactly:

```bash
git worktree add --detach /tmp/c8-pin 9967ec14c364cf10d2b5010a3cfc5c792a0dbb66
cd /tmp/c8-pin && git apply /path/to/reports/evidence/c8screen/instrument_pin_a4014080.patch
sha256sum solve.c solve.py tests.py   # eab41a10…  5d194b32…  a4eed282…
```

The committed code carries the same scorer, in the same places as the pinned tree, where no line that
a document cites by number moves. It differs from the pinned scorer only in comments and tests.
Comments that named the private registration path now name the public copy and the shipped check
scripts, and one stale comment's member-list digest now reads `529fb27a…` (amendment A1) beside the
frozen `486cac40…`. `TestC8Scorer` now re-extracts the scorer's reference code from the shipped
amended check script on every run, where it was skipped before. It also checks that the two shipped
check scripts differ, inside the reference-code ranges, only at line 147. No executable line of the
scorer changed. CX-354 gives the equivalence checks.

**One statement in the locked amendment is measured to be inexact, and it does not matter.**
§9-A0 says the amended check script is "identical to the frozen `bb017ec5…` on lines 1–163 except
line 147". Measured: the module docstring, lines 2–10, differs as well. Lines 2–10 lie outside the
reference-code ranges (`11, 15–25, 37–52, 55, 57–59, 83–158, 163`), so the conclusion the sentence
supports holds: inside those ranges only line 147 differs. `TestC8Scorer` checks both facts.

## Reproduce

**The verdict from the shipped outputs** (Python 3, standard library only; under a minute). The
script writes `SUMMARY.tsv` beside its inputs, so run it on a copy:

```bash
cp -r reports/evidence/c8screen /tmp/c8 && cd /tmp/c8 && gunzip *.gz
sha256sum -c RECORDED_SHA256SUMS            # after gunzip (= gzip -dc): the uncompressed outputs are the recorded bytes
mv SUMMARY.tsv SUMMARY.shipped.tsv
python3 analyze.py . | diff - TOKENS.txt && echo TOKENS=REPRODUCED
diff SUMMARY.tsv SUMMARY.shipped.tsv && echo SUMMARY=REPRODUCED
python3 analyze.py --selftest                # C8_ANALYZE_SELFTEST=PASS
```

**The check scripts** (a few seconds each, after editing line 12 to your checkout):
`python3 prereg_c8screen_defcheck_a1.py | diff - defcheck_a1.out`, and the same for the frozen one.

**The pair-only null, on a laptop.** N0 is single-threaded and depends only on its seed. Build with
`gcc -O2 -fopenmp -o solve solve.c -lm -lpthread -lz`, then
`SOLVE_KNUTH_SEED=9041319306645778315 ./solve --c8-null0 10000000 | diff - N0.out`
(uncompressed `N0.out`) should print nothing.

**The two-language gate:** `python3 solve.py --c8-verify ./solve` should print `C8_VERIFY=PASS`, with both
output digests equal to `3d5d8ea8547af82ccafd18493874b3b99ee4b4a9033a9234d7aa519057572bdf`, the value in
`c8_gate_full.out`. `python3 tests.py TestC8Scorer` runs a smaller version of the same gate, its two mutant
builds, and the reference-code re-extraction.

**The population runs.** These need a multi-core machine for hours: the recorded runs took about
1.9 hours (N1) and 53 minutes (N1′) each, on 16 threads. Each needs `ulimit -s unlimited`,
`SOLVE_THREADS=16` and `SOLVE_KNUTH_SCORE=1 SOLVE_KNUTH_SCORE_C8=1`:

```bash
SOLVE_KNUTH_SEED=359881319887057140                       ./solve --estimate-knuth 10000000000   # N1 half A
SOLVE_KNUTH_SEED=716349220184206698                       ./solve --estimate-knuth 10000000000   # N1 half B
SOLVE_KNUTH_C67=1 SOLVE_KNUTH_SEED=16185144687099509794   ./solve --estimate-knuth 5000000000    # N1' half A
SOLVE_KNUTH_C67=1 SOLVE_KNUTH_SEED=6479258443758798337    ./solve --estimate-knuth 5000000000    # N1' half B
```

METHODS §"Reproducibility rule for estimator output" states that a re-run at the identical (probes, threads)
reproduces the output; these runs used 16 threads. No such re-run of these histograms has been made. At any
other thread count a re-run is a different draw and should agree with the shipped one within the printed
standard errors.

## What a reader can and cannot verify

**Can verify:** that the amendment and both check scripts hash to their locked digests; that the
public copy of the registration and every other file hash to the values above and in `SHA256SUMS`;
that `analyze.py` turns the shipped outputs into exactly `TOKENS.txt` and `SUMMARY.tsv`; that the
uncompressed outputs are the recorded bytes; that the check scripts reproduce their outputs; that N0
reproduces byte for byte from its seed; that the patch reproduces the pinned instrument; that the two
languages agree on the gate orderings; and the arithmetic behind the 632 unattainable `C-M` members.

**Cannot verify:** that the registration and the amendment were frozen before King Wen was evaluated
(attested only); that the public copy differs from the frozen file only by the three cost hunks (the
original is private); and that the N1 and N1′ histograms are bit-for-bit what a re-run gives. No
re-run has checked that: under METHODS's rule one at the recorded 16 threads should reproduce them, and
one at another thread count checks them only within standard error.
