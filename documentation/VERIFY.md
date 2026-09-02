# VERIFY.md — the independent second instruments (`verify.py`, `verify.c`)

*Companion to `verify.py` (and its C-side sibling `verify.c`). Addresses the
single-instrument caveat raised in
[TR-11 §10(vi)](../reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md): "at full
31 … the full-31 integer will initially rest on a single instrument." (That
caveat's instrument half is now closed: on 2026-07-25 `verify.c --ie-count`
performed the independent full-scale recomputation — exact match. See the
closing section.)*

## Hardware you need (added 2026-08-21)

| resource | requirement | why |
|---|---|---|
| **RAM** | **≥ 12 GB free** for the full `verify_all.sh` suite | the Lean phase peaks at **~9.3–9.6 GB** on `Automorphism.lean` and **~8.0 GB** on `KingWen.lean`; **an 8 GB host cannot check those two files.** ⚠ *(Corrected 2026-09-01: this row named `PruneGInvariance.lean` as the second-heaviest file. It is not — it measures ~4.1 GB and an 8 GB host runs it fine. The same transposition was corrected in `reports/certificates/verify_all.sh`'s header on 2026-08-28 and never propagated here; the ≥ 12 GB requirement is unchanged and was never wrong, only the file named as its reason.)* Per-file measured table in [lean/README.md](../lean/README.md) §"Verify yourself" — half the files check in ~1 s under 0.7 GB |
| **Stack** | at least **16 MB** for any `--estimate-knuth` command — `ulimit -s 16384` suffices; `ulimit -s unlimited` is one sufficient setting, not the requirement (narrowed 2026-09-02, prose batch P37) | `main`'s frame is ~7.23 MB and the estimator adds ~1.02 MB, so an 8 MB default stack is exceeded on entry. The binary now **refuses with an actionable message** instead of segfaulting |
| **Disk** | ~2 GB scratch | regenerated CNF + decompressed proofs |
| **CPU** | any | the verification path is not core-hungry and needs no large VM. Large-scale *enumeration* is a different matter — see [CAMPAIGN_METHODOLOGY.md](CAMPAIGN_METHODOLOGY.md) for the D128 + Premium-SSD envelope and why random-IO isolation matters there |

*These figures existed before, in `lean/README.md` and a mid-file comment in `verify_all.sh`. They
are restated here because a cold external-reviewer pass on a 4 GB host (2026-08-21) hit `ERROR 134`
on **every Lean module then present** and reported them as unverifiable — the requirement was
documented, just not where a replicator reads it.*

⚠ **That reviewer did not hit the RAM limit, and a bigger host would not have helped him
(Q-347, measured 2026-08-28).** A blanket `ERROR 134` across *every* module — including the ones
this table says check in ~1 s under 0.7 GB — is the signature of an **address-space** cap
(`ulimit -v`, which containers and CI images commonly set), not of the RSS figures above. On a
4 GB `-v`-capped host every module failed at **~480 MB RSS**, i.e. at 5 % of what this table would
have you provision for: the cap starves Lean's thread-stack reservation long before RSS
approaches anything here, and it surfaces as `lean::exception: failed to create thread`, not as an
allocator error. **Try the free fix before buying RAM:**

```sh
LEAN_NUM_THREADS=1 lake env lean <file>.lean    # or: lean --threads=1 <file>.lean
```

On that same capped host it kernel-verified `C1RuleConstants.lean` and `PruneSafety.lean`. The
table above governs case (a), genuine memory; this paragraph governs case (b), address space.
Full diagnosis in [lean/README.md](../lean/README.md) — the Q-347 note in §"Executive summary
(plain English)", under the "No proof gaps" bullet. Check which one you hit before provisioning.

`verify.py` is a genuinely **independent** second opinion on the ROAE results.
It is standard-library-only Python **on every mode but one** — `--check-t5-c3` (the T5 parquet
cross-check, below) imports `numpy` and `pyarrow`, and only to *read the parquet under test*; the
imports are function-local, so no other mode acquires the dependency, and the C3 recomputation
itself is plain Python integer arithmetic. *(Scoped 2026-09-01: this sentence was unqualified, and
had been since `--check-t5-c3` landed on 2026-08-20. Derivation-independence is unaffected —
neither library carries any ROAE semantics — but the environment contract handed to a replicator
was wrong, and on a host without them that mode dies `ModuleNotFoundError`.)* It imports
**none** of `solve.c` / `solve.py` /
`roae.py` / `sat.py`, and rebuilds every quantity **clean-room from the published
mathematical definitions** (SPECIFICATION.md constraints C1–C5, `rev`/`comp`/
`partner`, the 48-element symmetry group; TR-11's reduced-rung tables). Its
counting method is deliberately **different** from `solve.c`'s symmetry-quotient
DP, so a conceptual bug in the quotient method would not be shared.

It verifies published results on **four** surfaces — records, exact counts,
(artifact-consistency only) completed-run certificates, and — since 2026-08-11 —
**analyses over large artifacts the caller supplies** (see
§"Analyses over large artifacts" below for what that fourth surface can and
cannot promise):

| mode | what it checks |
|---|---|
| `python3 verify.py [solutions.bin]` | the RECORDS: re-decodes every record and re-checks C1–C5 (C4 in its **oriented** spec form) + record-format conformance + order/dups. See §"What the records path actually enforces" below |
| `--jobs N` *(modifier)* | parallelises the records pass over N worker processes. Memory is bounded by streamed 1M-record batches (~32 MB per worker), not by file size. On a **raw** `solutions.bin`, output must match `--jobs 1` byte-for-byte apart from the worker-count header line — that equality is itself a check. ⚠ **On a gzipped artifact it cannot, and gzip is the default form** (`SOLVE_COMPRESS` defaults on): the gzip branch decompresses to an `mkstemp` path and prints that random name twice — in `Detected gzip-compressed solutions.bin; decompressing to …` and again in `Verifying N records from …` — so **two runs with identical arguments already differ in those two lines**, independent of `--jobs`. A CI diff implementing the equality as written false-mismatches on compressed input. Until the gzip branch is made deterministic, run the equality on raw input, or exclude those two lines as well as the `Parallel:` line. *(Measured 2026-09-01; `verify.py` reassigns `path` to the temp file before the `Verifying …` line is printed.)* |
| `python3 verify.py --enumerate-reference N` (2≤N≤9) | small-n completeness: brute-forces the reduced N-pair problem two independent ways (exhaustive vs prune-as-you-go) and asserts identical solution sets |
| `python3 verify.py --recount` | the exact COUNTS: independently reproduces the small-n structural facts, the reduced-rung C1∩C2∩C4 union counts, **and (since 2026-07-21) the C5 ladder rungs n = 9/13/16** (TR-11 §4b) — each rung's budget `B0` re-derived independently by TR-11 §5's first-completion DFS, then counted by a plain budgeted (mask, last, p) DP — and prints a match table |
| `python3 verify.py --recount-fiber` | (added 2026-08-01) the **orientation fiber** of [TR-1](../reports/TR1_EIGHT_CENTURIES_MEASURED.md) §7 — the frozen dispositive null against which the eleven-functional battery's exact p-values are computed, so it is the denominator every verdict in that table rests on. A transfer DP over King Wen's *own* pair sequence, varying only the 32 within-pair orientations, with the boundary budget `B0` recomputed from KW rather than copied from the report. Reproduces **1,720,320** (C4-oriented), **983,040** (pair-only C4, flipped opening), **2,703,360** (their sum), the stated `3·5·7·2¹⁴` factorization, and the forced/free bit structure (slot 30 is the only additionally forced bit — 30 of 31 vary). Two facts make this exact rather than a 2³¹ search, and the mode re-derives both instead of assuming them: within-pair distances are orientation-invariant, so C5 reduces to the 31 between-pair values; and `C3 = 16 + 8·G` with the orientation bits cancelling in `G`, so C3 is **constant** across the fiber and constrains nothing. Instant. Reads no files |
| `python3 verify.py --fiber-sweep [solutions.bin]` | (added 2026-08-01) the **orientation-fiber factor** — the exact conversion between the two counting levels this suite publishes side by side: deduped **records** (pair orderings, what `solutions.bin` stores) and orientation-explicit **sequences** (what the C1–C5 space estimate counts). `--recount-fiber` above answers TR-1 §7's question for King Wen's *own* ordering; this mode generalises the same object to an **arbitrary** C1 ordering, which is what makes the two levels inter-convertible: `N = Σ_P |fiber(P)|`, `R = #{P : |fiber(P)| ≥ 1}`, and the dedup factor is exactly the mean fiber `N/R`. Gated on King Wen's three published fiber sizes **and** on agreement with `--recount-fiber`'s independent DP before it reports anything; then, if a `solutions.bin` is present, prints the exact fiber-size distribution over its records. ~0.2 ms per ordering. Scope: the sample mean is over the records of the file given, which is a budget-truncated slice, **not** the C1–C5 space |
| `python3 verify.py --check-repr [N]` / `--check-repr-offset R` | (added 2026-08-15) the **repr(k) oracle** — independently recomputes the canonical representative for `N` records starting at record `R` (defaults: 1000 from 0) and compares it against what the artifact stores. **Why it is needed:** `solve.c`'s `--kc-repr-normalize` states outright that "there is NO separate repr oracle in this tree" — its only built-in check is IDEMPOTENCE (re-run on the output, expect byte-identical), which is self-consistent and therefore cannot catch a normalization that is stable but *wrong*. The `SOLVE_REPR_FC` A/B is weaker than it looks for the same reason at one remove: both arms share `solve.c`'s DFS, child order and code, so a defect in the shared traversal is invisible to it at any sample size. **Independence is the deliverable:** this is written from the DEFINITION in [`lean/RecordConvention.lean`](../lean/RecordConvention.lean) — repr(k) is the lexicographically least orientation completion of the pair-order key satisfying the constraint set, slot 0 forced by C4 (**the oracle implements only part of that set — see the C3 caveat below**) — not transcribed from `orb_recanon_dfs`, and it builds on this file's own KW table, `_partner()`-derived pairs and `hamming()`, re-deriving and asserting the C5 budget. Reproduces **King Wen from King Wen's own key**. Verdicts are `KEY=value` (`CHECKED`/`AGREE`/`DISAGREE`/`INCOMPUTABLE`/`CHECK_REPR=PASS\|FAIL`) plus an explicit `SCOPE=` line. **Scope, stated plainly: it checks the records it reads and no others** — use several offsets rather than resampling one window, and never report a sampled pass as whole-artifact agreement. Fails closed **only over the constraints it implements**: an *incomputable* key is a finding too, since the artifact claims a canonical record for a key this instrument says cannot be completed. ✅ **C3 landed 2026-09-02; the oracle now fails closed on it.** [`lean/RecordConvention.lean`](../lean/RecordConvention.lean) states the definition's completion predicate as `P` = "the completed sequence satisfies C2/C3/C5" (C1/C4 by construction). Until 2026-09-02 `verify.py`'s `repr_of_key` and `verify.c`'s `vc_repr_of_key` applied the forced (63,0) opening, the HD-5 exclusion and the exact C5 budget and **nothing else**, so a key whose pair sequence has `C3 > 776` — which under the definition has **no** valid completion — was completed anyway rather than reported incomputable. Because C3 is orientation-invariant it could never change *which* completion is lex-least, so no `AGREE`/`DISAGREE` verdict was ever wrong; what it corrupted was the `INCOMPUTABLE` leg, the one this row advertises as fail-closed. Both oracles now apply a **C3 pre-filter before the DFS** (C3 is a function of the key alone, so it is decided once and *prunes* rather than costing) and return no completion when the ceiling is exceeded. Red-tested before the fix and re-measured after, on a one-record artifact whose key has `C3 = 1080` and whose stored record IS the lex-least completion: **before**, both languages printed `AGREE=1`, `DISAGREE=0`, `INCOMPUTABLE=0`, `CHECK_REPR=PASS`, rc = 0; **after**, both print `AGREE=0`, `DISAGREE=0`, `INCOMPUTABLE=1`, `CHECK_REPR=FAIL`, rc = 1. Gated permanently by `tests.py::TestCheckArtifactControls::test_ctl_repr_c3_is_incomputable`, which asserts the tokens by whole-line match in **both** implementations. **No registered canonical is exposed:** every registered canonical's VERIFY PASS is a records-path pass. Python cost is a DFS per record and the underlying search is heavy-tailed, so prefer `verify.c --check-repr` (below) for large `N` **APPLICABILITY (2026-08-15): run this against a repr-NORMALIZED artifact, not against a raw merge output. `solutions.bin` is pre-normalization — `solve --kc-repr-normalize` (task #20 — ⚠ **that flag does not exist in this tree**; see the NOT-AVAILABLE box further down this file) has not been run on it — so a DISAGREE there is EXPECTED and identifies exactly the records the post-pass would rewrite. It is the correct acceptance test for the post-pass OUTPUT. See §'What the 2026-08-15 sweep actually found' below.** |
| `python3 verify.py --check-artifact [N]` / `--check-artifact-offset R` / `./verify --check-artifact FILE [N] [OFFSET]` | (added 2026-08-15) the **artifact validator** — checks what `solutions.bin` actually CLAIMS, in one linear pass per record: (1) **validity**, each record's OWN orientations satisfy the *orientation-dependent* constraints — forced `63->0` opening (C4), no HD-5 transition, C5 budget consumed EXACTLY — plus record-format conformance (key is a permutation of the 32 pairs, reserved bit clear). **Not the whole constraint set: C3 is absent, see below;** (2) **sortedness**, pair-order keys strictly increase, matching `compare_solutions`; (3) **dedup**, strictness in (2) IS the one-record-per-canonical-class claim. `N` defaults to **-1 = to EOF** — this is a whole-artifact instrument, not a sampler, because it is linear rather than a search. **Prefer this over `--check-repr` on the merge output.** `--check-repr` cannot validate the artifact as it exists today — `solutions.bin` is pre-normalization, so its disagreements are the post-pass's work-list, not defects — and even after normalization it is *structurally blind to a wrong pair sequence* — `repr_of_key` is handed the key decoded from the very record it is compared against, so a disagreement can only ever be an orientation bit. This one checks the pair sequence directly. ✅ **C3 and header conformance landed 2026-09-02.** Until then this loop checked C4/C2/C5 and never computed the C3 sum, so a record whose decoded pair sequence has `C3 > 776` was certified `ARTIFACT=PASS` with rc = 0 by **both** implementations — and **no negative control could have shown it**, because a controls table exercises the counters that exist and is blind, by construction, to a missing predicate. The gap bit here in particular because C3 is the one constraint that is *purely* a pair-sequence property (orientation-free, constant across the orientation fiber), which is exactly what an instrument sold as checking the pair sequence directly is expected to cover. Both implementations now carry a `BAD_C3` counter, computed from the decoded sequence (**not** via the `16 + 8·G` identity, which these files exist to check rather than to assume), folded into the verdict. The same revision closed three header legs that were equally invisible — the magic was previously the *only* header field either implementation read: `BAD_HDR_VERSION` (format version must be 1), `BAD_HDR_RESERVED` (bytes 16–31 must be zero), and `BAD_GEOMETRY` (the declared count must equal the records in the stream, checked on a whole-file read only, so a sub-range invocation stays green). A fourth divergence surfaced while red-testing them and is now closed in the same direction: on a **torn trailing record** `verify.py` silently dropped the partial tail and returned `ARTIFACT=PASS` rc = 0 while `verify.c` returned `ARTIFACT=FAIL_partial_record` rc = 2; `verify.c` was right and `verify.py` now matches it. All five controls were measured RED against the pre-change binaries before the predicates were added, and are gated permanently in `tests.py::TestCheckArtifactControls`, which asserts that the two independent implementations emit **identical** verdict tokens on every fixture. **No registered canonical is exposed:** every registered canonical's VERIFY PASS is a records-path pass, and the enumerator enforces C3 in-walk. Verdicts are `KEY=value` (`RECORDS`, `BAD_KEY`, `BAD_SPARE_BIT`, `BAD_OPENING`, `BAD_HD5`, `BAD_BUDGET`, `BAD_BUDGET_RESIDUE`, `BAD_ORDER`, `BAD_C3`, `BAD_HDR_VERSION`, `BAD_HDR_RESERVED`, `BAD_GEOMETRY`, `ARTIFACT=PASS\|FAIL`) plus `SCOPE=`. **Requires a `ROAE` header and refuses without one** (`ARTIFACT=FAIL_no_ROAE_header`): a headerless raw `sub_*.bin` shard would otherwise have its FIRST RECORD silently consumed as a header, and the checker could then report `PASS` on a file it never fully read — the same failure mode as the recon off-by-one this repo already carries a fix for. It fails closed rather than auto-detecting, because this tool validates the *merged* artifact and a shard should be an explicit refusal, not a silent reinterpretation. **Does NOT check completeness** — that no valid solution is *missing* is the enumeration's claim, attested by the canonical sha; a forward pass cannot establish it. Sharding caveat: the sortedness check compares against the predecessor WITHIN the range read, so a sharded run cannot see a violation across a shard seam — overlap by one record, or run offset 0 to EOF |
| `python3 verify.py --check-shen-orbits` / `--check-flips` | (added 2026-08-15) two **reproduction commands for figures published in [CITATIONS.md](CITATIONS.md) and in this file**, because a private script does not make a public number reproducible. `--check-shen-orbits` verifies that Shen Youding's 1936 six groups of principal hexagrams are **exactly the six K₄ orbits** of his sixteen (sizes 2,2,2,2,4,4) — his criterion, equal generational rank of inner and outer trigram, is **KW-independent**, and this checks a CLASSIFICATION, not an ordering claim. It is independent of `solve.c`'s orbit code by construction: the claim is *about* orbit structure, so a check that used that code would not be independent. `--check-flips` prints the census of the 31 single-orientation-bit flips of King Wen's own record by failure mode (**9 PASS / 15 `BAD_BUDGET` / 7 `BAD_HD5`**), which exists because the figure first shipped as "16" — the measuring harness grepped `^BAD_[A-Z_]+=[1-9]`, a character class that excludes DIGITS, so `BAD_HD5` never matched. Both read **no files** |
| `python3 verify.py --check-kw-pair-adjacency` | (added 2026-08-16) **reproduction command for a classical fact and for a NEGATIVE result.** Re-verifies that King Wen seats every hexagram beside its own partner — 32 pairs, **28 by reversal, 4 by complement**, zero unrelated, zero hexagrams whose partner is not adjacent. **That rule is not ours and not new**: it is 非覆即變, stated by Kong Yingda 孔穎達 (574–648) with earlier lineage via Yu Fan 虞翻 — see [CITATIONS.md#kongyingda](CITATIONS.md#kongyingda). The command exists so a reader can confirm the premise without taking anyone's word for it. It then draws the consequence for excavated evidence: the head/tail symbols of the Shanghai Museum Chu bamboo *Zhouyi* ([Pu Maozuo 2003](CITATIONS.md#pu2003)) **cannot distinguish** "the symbol respects reversal" — Pu's claim — from "the symbol is merely constant on contiguous King Wen blocks", because blocks and orbits coincide by construction of the sequence. It reports `SHANGBO_TESTABLE_PAIRS=9` and `SHANGBO_DISCRIMINATING_PAIRS=0`. **An impossibility argument, not a criticism of his reading, and not a failed search.** ⚠ **Scope of what is COMPUTED here, tightened 2026-09-01:** this row previously reported Pu's claim as holding "9 testable pairs / 9 agreements / 0 disagreements", worded as a figure the command checks. **It does not check it.** `verify.py` holds those nine entries as King Wen *numbers* only and carries no symbol values at all, so `SHANGBO_TESTABLE_PAIRS` is a `len()` of the transcribed list and `SHANGBO_DISCRIMINATING_PAIRS` is a pure contiguity computation — a mistranscribed or oppositely-classified symbol would leave the command's output byte-identical. The agreement census is **Pu's reading as transcribed**, not something this repository recomputes, and by this file's own standard it therefore has no reproduction command yet. The per-slip observed symbol values do exist in the project's private record (observed entries separated from reconstructed ones); embedding them here — page-cited to Pu 2003's 考釋, observed only — and printing `SHANGBO_AGREEMENTS=`/`SHANGBO_DISAGREEMENTS=` beside the existing tokens, with a flipped-value negative control, is what would close it. **The impossibility result is unaffected**: it needs only the King Wen numbers, which are published. Reads **no files** |
| `python3 verify.py --check-classical-groups` | (added 2026-08-16) **the group actions the CLASSICAL literature attests, and how King Wen scores against each — none of the rivals are ours.** Sources: **⟨comp,rev⟩** and **⟨rev,swap⟩** both from 吳澄 Wu Cheng (1249–1333) 《易纂言外翼》卷一〈卦對第二〉 ([#wucheng](CITATIONS.md#wucheng)); **⟨comp,swap⟩** from 焦循 Jiao Xun (1763–1820) 《易圖略》八卦相錯圖 ([#jiaoxun](CITATIONS.md#jiaoxun)). **The result:** ⟨comp,swap⟩ has the *identical* orbit profile to ⟨comp,rev⟩ — 20 orbits, 8×2 + 12×4 — yet King Wen seats partners adjacently **64/64** under ⟨comp,rev⟩ and only **24/64** under ⟨comp,swap⟩. At the sharper pairing-rule level: reversal-with-complement-fallback (= C1, 非覆即變) scores **64/64**; every **complete** alternative pairing rule tested scores **12–16/64** (`RULE_COMP_ALONE`, `RULE_SWAP_THEN_COMP` and `RULE_COMP_OF_REV` at 16/64, `RULE_SWAP_ALONE` at 12/64). Bare reversal is the one exception and is not a rival: it is the rule C1 *completes*, scoring **56/64** (`RULE_REV_ALONE`) and leaving exactly the eight self-reverse hexagrams unpaired — 64 − 8. *(Corrected 2026-09-01: this sentence read "every alternative tested scores 12–16/64", a universal that the cited command refutes in its own output on every run.)* And this is **exact, not sampled**: of the **3.845×10⁴⁶** involutions on the 64 with eight fixed points, **exactly 70** score 64/64 — a fraction of **1.8×10⁻⁴⁵** — and all 70 agree with reversal off the degenerate hexagrams. **Those 70 are one rule under 70 labellings**, since 'fixed point' versus 'swapped pair' is a vacuous distinction exactly where the two operations coincide. **And the hexagrams where that freedom lives are exactly [吳澄's two degenerate classes](CITATIONS.md#wucheng)** — 正對不反易者四 + 正對兼反易者四. So a structurally indistinguishable rival, drawn from the same tradition, does not fit — the choice is a property of the sequence, not an artifact of looking for symmetry. Also re-derives 吳澄's own 「共十八對」 as a reading check (24 orbits − 6 meeting the 八純卦 = 18 ✓). **Scope: this is about PAIRING. It changes no enumeration and no published count.** Reads **no files** |
| `python3 verify.py --check-zhu-yuansheng` | (added 2026-08-16) **the earliest known complete ⟨錯,綜⟩ orbit decomposition, checked rather than trusted.** 朱元昇 Zhu Yuansheng (d. c.1273) 《三易備遺》卷八, complete by 1270 ([#zhuyuansheng](CITATIONS.md#zhuyuansheng)) — Southern Song, ~30 years before [吳澄](CITATIONS.md#wucheng), to whom this had been ceded earlier the same day. His twelve quadruples are transcribed as King Wen numbers with the **先天 (complement) and 後天 (reversal) pairs kept SEPARATE**, so each half of each line is tested on its own against this repository's bit operations: all 24 先天 pairs are true complements, all 24 後天 pairs true reversals, the 48 are disjoint from his 16 coincident hexagrams, 12×4+8×2 = **64**, his eight 不可得而反對 are exactly the self-reverse hexagrams, his eight 可得而反對亦可得而變對 are exactly those where complement = reversal, and **his twelve quadruples ARE the size-4 orbits**. A failure means the transcription is wrong or the cession is wrong — both worth knowing, which is why it ships as a command. **Scope: this attests a 13th-century READING. It changes no enumeration and no published count of ours.** Reads **no files** |
| `python3 verify.py --check-parity-alternation` | (added 2026-08-16) **re-derives every published figure in [PARITY_ALTERNATION.md](PARITY_ALTERNATION.md)** — a paper-citable finding that until today published its central numbers with no way for a reviewer to re-derive them (**GATE 25 LEG 2 flagged the file; this is the answer to that flag**). Recomputes the 63 transition distances and the multiset `{1:2, 2:20, 3:13, 4:19, 6:9}` from the KW table, confirms the **15** odd transitions, confirms the pair parity class is **well defined** rather than assuming Lemma 3, confirms the **16/16** class split that `C(32,16)` presupposes, measures KW's own alternation count (**15**), checks C4 pins pair `{63,0}` to the even class, and counts the 15-change arrangements **twice by routes sharing no code** — a DP over (position, evens used, last class, changes) against the closed form `2·C(15,7)² = 82,818,450` — recovering the published `601,080,390` total and `×7.2578` reduction. **Scope: it attests the FIGURES; the theorem is a proof and is not re-proven here.** Reads **no files**, ~1 s |
| `python3 verify.py --recount-gender-null` | (added 2026-08-01) TR-8 §Commands' **exact pair-null Schulz-gender figure** `P(rc4_violations ≤ 2) = 47/445740`. Both prior implementations of this rational lived inside `solve.py`, so the figure was single-FILE even though it was described as verified two ways; this is the genuinely independent second instrument. The functional is rebuilt from the **published** definition (SOLVE_C_CLI.md §`--rc4b-verify`; Schulz 1990 motif 2 via Cook 2006) rather than from `solve.py`'s code, and the reading is gated on King Wen's published anchors (2 violations, class positions 25/26). The 32!·2³² null is then solved **exactly two ways** — a multivariate-hypergeometric closed form, and a slot-by-slot DP over pair-type states that never uses the closed form's decomposition — cross-asserted term-by-term, in `fractions.Fraction`. No sampling. Instant. Reads no files |
| `python3 verify.py --recount-rung N` | (N = 18 or 19) the **worker-sized C5 ladder rungs** — a packed-state budgeted DP, self-gated against the in-file plain DP at n=16. Larger rungs (n = 20–28) need a worker and are not run here |
| `python3 verify.py --recount-rung-layers N` | (N = 9 or 13) gates the **per-layer masses** published in `reports/FULL31_EXACT_AGGREGATES.md` against an independent recount by the plain budgeted DP, with `B0` re-derived. The rung *totals* were already gated; until this mode the *intermediate* layers were gated by nothing. A missing or unparsable table FAILS rather than passing quietly. Runs in under 5 s |
| `python3 verify.py --f1-dec-roundtrip` | gates `solve.c`'s 192-bit decimal renderer `f1_dec()` against exact Python integer arithmetic — both limb boundaries, 10⁰…10⁵⁷, and **every layer mass published in `reports/FULL31_EXACT_AGGREGATES.md`**. Until this mode the renderer was exercised only at 26112, which is one limb wide, while the published headline integer sits in limb 2. Needs a `solve` binary (`SOLVE_BIN` or `./solve`); absence FAILS rather than skipping |
| `python3 verify.py --f1u192-binary-roundtrip` | three arms: **v1 raw** and **v2 per-block zlib** (the format `--f1-out-of-core` writes, and therefore what every real Stage F / 560T layer is made of), each building the n=9 layers with `solve` and reading the final layer back **from raw bytes in Python** (72-byte header, `masks u32[]`, `off u64[]`, `keys u32[]`, `vals` as 24-byte little-endian limb triples) and checks its mass against this file's own independent count. `solve`'s own write→resume round-trip **cannot** do this: writer and reader share any limb-order defect and cancel it exactly — measured, see below. Absence of a binary FAILS. A third arm sweeps every kept n=16 v2 layer for block-seam structure — no rung at n≤13 reaches the 65,536-entry block size (widest n=13 layer: 11,102), so without it the block seam would never be crossed; the arm fails if it sweeps layers and none crossed it. Prints `F1U192_V2_LAYOUT=GATED` on success |
| `python3 verify.py --recount-orbit-widths 31` | gates the **`canonical_masks` column** of `reports/FULL31_EXACT_AGGREGATES.md` — all 31 layers — by a **Burnside count** over the 24-element pair-permutation quotient, derived here from the 48 commuting bit-permutations rather than read from `solve.c` or from the artifact. It is a property of the object, not of the implementation, and had no instrument until now. Milliseconds; prints `ORBIT_WIDTHS=GATED` |
| `python3 verify.py --recount-subtree` | the exact **deterministic subtree anchors** of TR-5 §3 / SEARCH_SPACE_SIZE (KW-following prefixes at 5/7/9 free positions: `tree_nodes` 443 / 62,256 / 9,422,793 and canonical leaves 4 / 2,232 / 16,504), plus the sigma-related-prefix tree-isomorphism check. ~1–2 min. Reads no files |
| `python3 verify.py --check-c2-shift [N]` | the **C2 conditioning shift** on the C3 tail by importance-weighted Monte-Carlo: `P(C3 ≤ 776 | C1∩C2∩C4) ≈ 8.9%` (95% CI [8.5%, 9.2%]) against the exact 8.106% C1&C4 null. A measured estimate with a CI, not an exact count — cited in [SPECIFICATION.md](SPECIFICATION.md) §C3 |
| `python3 verify.py --check-null-g --unpinned` | the same exact G-law **without the C4 start pin**, giving `C3\|C1 = 6.4211367496%` exactly — the figure [SPECIFICATION.md](SPECIFICATION.md) and [SOLVE_SUMMARY.md](SOLVE_SUMMARY.md) both cite. `--unpinned` is a modifier on `--check-null-g`, not a mode of its own |
| `python3 verify.py --check-certificate DIR` | a completed f1c5 run's ARTIFACTS (run.out per-layer certificate rows, manifest, preserved digests) against structural identities and independently derived quantities. Recomputes **nothing** — internal-consistency and digest-integrity only, per its docstring |
| `./verify --check-layers DIR [max_k] [run.out]` | (C side, NEW 2026-07-23; orbit-weighted mass added same day) the **on-disk layer files themselves**, read against [F1C5_LAYER_FORMAT.md](F1C5_LAYER_FORMAT.md) with no `solve.c` code: header/`pl_hash`/`b0` vs the manifest, `masks`/`off` layout, per mask popcount/range/**canonicity** (numeric minimum of its orbit), and per entry the key packing, `rid < R`, ascending order, nonzero value, and the **sum invariant** (rid mixed-radix digits sum to `k`). With the TR-11 §2 group **derived independently in-file** (the 48 `C_{S6}(rev)` bit-perms → 24 induced pair-permutations → the run's distinct restricted perms, closure-verified), it re-derives the §Reading-recipe **orbit-weighted mass** `Σᵢ sᵢ·(|G|/|stab(maskᵢ)|)` from the layer bytes at **every** layer and, when a `run.out` is given, compares it to `solve.c`'s reported `mass=` per layer — the full-scale counterpart of the small-`k` plain-DP mass check. Entry-streaming and `O(nm)` memory, so it reaches every layer on disk — and at the final layer (full-31) the summed value bytes must equal the published **40**-digit count and be `≡ 0 (mod 24)`. Handles v1 (raw) and v2 (per-block zlib). `--check-layers-selftest` synthesizes v1+v2 fixtures, a corrupted case, a **non-trivial-stabilizer** mass fixture (pair-orbit `3.0`, `|stab|=2`, orbit `3 < |G|=6`), a wrong-reported-mass case, and a non-canonical-mask case — no real data needed. **Campaign-VM tool** (run where the layers live). |
| `./verify --check-g-ladder FDIR GDIR [max_k]` | (C side, NEW 2026-07-24) the **g-ladder layer files** (`--kc-g-build` artifacts: exact count-from-any-prefix, the rank instrument's substrate), read against [GT_LADDER_FORMAT.md](GT_LADDER_FORMAT.md) with no `solve.c` code. Structural: `F1C5GLY1/2` magic+version, `g_manifest_v1`, header fields, v1/v2 file-size formulas, layout, mask **canonicity**, per-entry key packing / ascending order / `rid < R` / **sum invariant** / nonzero values, the **stored-domain rule** (`last` in the mask's pair-element set), and the exact **seed** (2n sorted pair elements, `rid = R−1`, all values 1) and **anchor** (layer 0 = `g(0)`) content. Identity: the **f·g cut identity** — `Σ orbit(mask)·f(s)·g(s) = N` at **every** layer, with `N` re-derived from the f ladder's final-layer value bytes (and, at full-31, checked against the published count). An independent implementation of the same gate `solve.c --kc-g-check` asserts — a true second instrument for the g ladder. **Campaign-VM tool** |
| `./verify --check-t-ladder FDIR TDIR [max_k]` | (C side, NEW 2026-07-24) the **t-ladder layer files** (`--kc-t-build` artifacts: exact search-tree node counts, `t(s) = 1 + Σ_c t(s∘c)`), against [GT_LADDER_FORMAT.md](GT_LADDER_FORMAT.md). Structural: `F1C5TLY1/2` magic, `t_manifest_v1`, **byte-exact f-geometry mirror** (masks/off/keys identical to the f layer at every `k`), every value ≥ 1, seed layer all 1s, anchor singleton. Identity: `M_j` (orbit-weighted f masses = exact # valid depth-`j` prefixes) re-derived from the f ladder's bytes, `M_0 = 1`, then the **f·t node identity** `Σ orbit·f·t = Σ_{j≥k} M_j` at **every** layer (the backward recurrence unfolded, `S_k = S_{k+1} + M_k`) plus `t(root) = Σ M_j`. The independent counterpart of `solve.c --kc-t-check`. `--check-gt-selftest` covers both modes: it brute-forces a complete, consistent f+g+t fixture from the published definitions on a **non-trivial instance** (the 6-pair orbit `{10,15,20,23,27,29}`, transitive restricted group `geff=6`, budget spanning 3 classes incl. `d=6`, **252 dead-end states**, anchors `N=96` / `t(root)=1285` cross-derived by an independent Python implementation), round-trips v1 and v2, and asserts seven negative legs FAIL (g value tamper, t value tamper, t geometry tamper, g/t magic confusion, g seed tamper, and — added 2026-08-30 after the skip-as-pass finding — an intermediate f layer DELETED under the g check and the final f layer DELETED beyond `max_k` under the t check: a skipped identity is a failure, never a pass; both modes print an `IDENTITIES_CHECKED=` / `IDENTITIES_SKIPPED=` census and exit nonzero when zero identities executed or any skip fell inside the requested range) — no real data needed |
| `./verify --knuth-anchors` | (C side, NEW 2026-08-08, task #194) the **clean-room Knuth prober's validation gate** — run it before trusting any `--knuth-probe` run. Structural checks (partner-exact KW pairing; within-pair {2:12,4:12,6:8} + KW boundary multiset == the C5 literal; 8 self-complement pairs / 12 cross complement-couples, [lean/C3Decomposition.lean](../lean/C3Decomposition.lean)'s counts; the SPECIFICATION.md C6/C7 pin sets {29,46}/{9,36}/{11,52}/{13,44} == KW pairs 24–27; `c3x64(KW) = 776 = 16 + 8·95`), then exhaustive DFS below KW-following prefixes gated on the **published exact subtree anchors** (SEARCH_SPACE_SIZE §Validation / TR-5 §3: 5-free 443 nodes / 4 canonical, 7-free 62,256 / 2,232, 9-free 9,422,793 / 16,504, and exactly **8** of the 16,504 satisfying C6/C7) with the spec-vs-Lean C3 identity asserted at every one of the ~696K complete leaves, and finally a fixed-seed probe run on the 9-free prefix that must match the exact counts within 4σ of its own Wald CI (exercises the weighting/RNG path the exact DFS never runs). ~2 s. Reads no files |
| `./verify --knuth-probe N [--knuth-seed S] [--knuth-threads T] [--knuth-no-c67] [--knuth-free F]` | (C side, NEW 2026-08-08, task #194; pre-registered gate in the private repo before first run) the **clean-room Knuth (1975) random-probe estimator** — a second, independent instrument on the published `solve.c --estimate-knuth` estimate \|C1∩C2∩C3∩C4∩C5∩C6∩C7\| ≈ 5.21×10³¹, whose one uncorroborated full-scale factor is the **C3 conditional ratio (~0.101)** (every existing full-scale cross-check is C3-free by scope). Own C3 predicate — computed BOTH ways at every complete leaf, the SPECIFICATION.md positional sum and the Lean slot decomposition `16 + 8·G`, cross-asserted — and own C6/C7 pin logic (pinned pairs excluded from non-pinned slots, which removes only zero-leaf subtrees, so the walk tree differs from `solve.c`'s but the leaf estimands are unbiased for the same targets). Default estimates the C6/C7-pinned targets; `--knuth-no-c67` the C1–C5 space; `--knuth-free F` probes the KW (32−F)-slot prefix subtree (validation aid). Reports canonical + no-C3 + tree-node estimates with Wald CIs, the seed, and a free calibration: the no-C3 leaf estimand is compared against this file's own **exact** Route B/D constants (5.16880…×10³² pinned / 1.097051…×10³⁹ unpinned). splitmix64 RNG, per-thread disjoint 2⁴⁰-draw segments; modulo child-selection bias < d/2⁶⁴ ≈ 4×10⁻¹⁸, negligible. Reads no files |
| `python3 verify.py --check-null-g` | the **reference distribution for C3**: the exact G-distribution under the C1&C4 null (12 cross-couples + 7 self-pairs into 31 slots), gated against `total == 31!`, support `[12,228]`, `E[G] == 128` (also true DP-free by linearity, since `E\|i−j\| = (n+1)/3` for a uniform 2-subset of `{1..n}`), and `P(G ≤ 95) == 641983711307479/7919632354008375`. Since `C3 = 16 + 8·G`, this is the baseline any "KW's C3 is unusual" claim must beat. Accumulates **open-couple counts, not ± slot indices** — deliberately different arithmetic from `solve.c`'s G channel, so agreement is evidence rather than tautology. **Scope: C1&C4 only** — no C2, no C5, no budget truncation; not like-for-like against ceiling-tie shares measured over conditioned enumerated populations. Reads no files |
| `python3 verify.py --t3-stats DIR` | (added 2026-08-11) two of the three pre-registered validity statistics of the **T3 exact-uniform draw sample** — (a) uniformity of the rank stream (χ² over 16 equal buckets, bucket = ⌊16·r/N⌋, 15 dof, **PASS below 37.70**) and (c) the C3 fraction at `cd ≤ 387` against `p₀ = 1/8.26 = 0.12107`, **flagged beyond 4σ** either direction. Both bars are frozen in the pre-registration (private repo, `PREREG_F_CATALOG_T1_T4_2026_08_06.md` §3, committed **before** the first recorded draw) and neither may be adjusted to make a result land — a breach quarantines the sample. `N = \|C1∩C2∩C4∩C5\| = 1,097,051,278,789,181,790,036,112,071,176,579,186,688` (TR-11 §9). Statistic (b) is deliberately **not** restated here; run `--t3-membership`. DIR is a directory of `t3_stream_*.out[.gz]`, or one such file. **Input is not in this repo** — see §"Analyses over large artifacts" for the generating command and its measured cost. Analysis itself: **≈22.9 MB peak RSS** for 10⁶ draws (reproducible across 7 runs); wall is a few seconds but is load-dependent and is **not** a reproducible figure — see §"Analyses over large artifacts" |
| `python3 verify.py --t3-membership PATH [--t3-membership-limit N]` | (added 2026-08-11) the third pre-registered statistic, (b) **membership**: every emitted walk must satisfy C1∩C2∩C4∩C5. Bar **100%** — a single failure is a first-order finding. This is the *second language* for that check, so its value is that it shares no code with the sampler: the predicates are transcribed from [SPECIFICATION.md](SPECIFICATION.md) §C1/C2/C4/C5 and it uses only `verify.py`'s own rule-derived helpers (`_partner`, `hamming`, `compute_comp_dist`), all gated at import against the spec literals. Before reporting anything it (i) self-tests the transcription (partner is an involution; exactly 8 self-reverse hexagrams; `partner(63) = 0`; the C5 target sums to 63; `compute_comp_dist(KW) = 776`; King Wen itself is accepted) and (ii) runs a **positive control per constraint** — each control breaks exactly one of C1/C2/C4/C5 and the run aborts unless that constraint's own predicate fires, which is what separates a working checker from one that says MEMBER to everything. Two checks beyond the prereg: the engine-recorded `cd=` is independently recomputed (`cd = compute_comp_dist(S)/2 − 1`, the −1 being the C4-pinned `(63,0)` pair), and duplicates are detected. `--t3-membership-limit 1000` on one stream reproduces exactly the pre-registered spot-check leg in a fraction of a second. Full census: **≈149 MB peak RSS** for 10⁶ draws, the one figure that reproduced across every measurement condition; wall ranged **60–98 s** depending on what else the box was doing and is **not** a reproducible figure — see §"Analyses over large artifacts", which records two successive wrong answers about it |
| `python3 verify.py --g-structure C2ON_LOG C2OFF_LOG` | (added 2026-08-11) structure of the **full-31 G distribution** from two enumerator logs carrying `G_HIST` lines — C2-ON (C1&C2&C4) and C2-OFF (C1&C4). Re-derives the moments as exact rationals, checks every bin is divisible by 48, and on the C2-OFF side runs the sharp identities: `G_HIST_WSUM == 128 · G_HIST_TOTAL` exactly, and `P(G ≤ 95)` equal **as a rational** to the closed-form null `641983711307479/7919632354008375` — the same constant `--check-null-g` derives from scratch, so this is a cross-instrument agreement rather than a restatement. Then a convolution test (`q^(1/m)` coefficient tails for 14 values of m) showing no `m` truncates, i.e. G is **not** an independent-sum statistic — consistent with a permutation statistic (sampling without replacement). **Scope:** this says nothing about prefix-G g48-invariance; a quotiented run cannot test the assumption its own quotient makes. Analysis is instant and reads only the logs; producing them is not — see §"Analyses over large artifacts" |
| `python3 verify.py --check-t5-c3 SOLUTIONS_BIN CHUNKS_DIR` | (added 2026-08-20) independently recomputes `c3_total` for **every** record of the T5 mega-sample and compares it against the parquet that the `solve.py` pipeline produced. The two routes are disjoint: this one uses `C3 = 16 + 8·G` over the 12 complement-couples' **slot gaps** (machine-checked in [lean/C3Decomposition.lean](../lean/C3Decomposition.lean)) — slot map only, no transition walk, no path, orientation-independent — while `solve.py --compute-stats` walks the ordering. It exists because T5's load-bearing figure, `P(C3 ≤ 776) = 12.1288%`, came out of a single pipeline, and a pipeline agreeing with itself is not a check. All 1,000,000 records, never a subsample; ~5 s. Verdict `T5_C3_AGREE=PASS`/`=FAIL`, matched with `grep -qx`; a single swapped pair-index in one record is caught and its index printed. **Scope: `verify.py` imports nothing from `solve.py`, so this is IMPLEMENTATION-independent — but both are Python, so it does NOT discharge the two-LANGUAGE half of the cross-check gate** |
| `python3 verify.py --check-layer-sidecars DIR` | the per-layer SIDECARS (`f1c5_layer_stats_KK.json`): two *independent* marginal decompositions (`marginal_last_mass` by terminal pair, `marginal_rid_mass` by boundary-residue id) each summing to `mass_total`; histogram totals against `n_entries` / `n_masks − n_empty_masks`; `mass_total` inside its own value-histogram bounds; `n`/`b0`/`pl_hash` agreement with the manifest; and the layer-to-layer **sha256 lineage chain** (`input_sha256_decompressed[k] == own_sha256_decompressed[k−1]`). Reads **only** the small JSON sidecars — no layer-file I/O, so it costs nothing and works long after the campaign VM is gone. Recomputes no masses |

The C-side sibling, **`verify.c`** (same independence discipline: no `solve.c`
header, no shared table, no copied constant), recomputes the engine's per-layer
*plain* masses with a plain, non-quotient layered DP **on the true full-31
instance** and compares against the run.out rows — agreeing at every layer
within its memory reach (the plain state space grows ~16× per layer, so it
exhausts long before k = 31; it is corroboration, **not** the independent
full-scale recomputation §10(vi) asks for).

## Analyses over large artifacts — reproducible *at a stated price*

*Added 2026-08-11 (task #213 C). Read this before citing `--t3-stats`,
`--t3-membership` or `--g-structure` as "reproducible".*

Three analyses used to exist only as scripts in the private staging repo. The
numbers they produce were published; the method was not runnable by anyone
outside the project. **A script in a private repo does not make a public number
reproducible** — that was the whole of the #213 debt, and moving the *analysis*
into `verify.py` is what pays it down.

What moved is the analysis, not the data. The inputs are large and remain
privately held, so each mode takes an **artifact path from the caller**. That
is an honest promise only if the reader is also told how to *generate* the
artifact and what that costs, so both are stated here and in each flag's
`--help`:

| mode | input artifact | how it is generated | measured cost to generate |
|---|---|---|---|
| `--t3-stats`, `--t3-membership` | the T3 exact-uniform draw sample: 16 streams × 62,500 draws = 10⁶ draws (~107 MB gzipped) | one KC-sampler invocation per stream — arguments `--kc-sample <f-dir> 62500 <seed_i> --kc-record --kc-ooc --kc-cache-mb 384`, with `SOLVE_F1_OOC_READ_MB=1`, against the Stage F **f-ladder** — the sixteen `<seed_i>` values are **published below**, so this is a runnable recipe rather than a template. **Not on `main`:** see the branch note below the table | **≈12.6 h wall** on one D16als_v7 (16 lanes, Premium P50 f-disk) against a **3.1 TB** f-ladder — plus building the branch that carries the sampler. Seed-deterministic: the same seeds, f-ladder and binary regenerate the same draws — and **the seeds are now published** (§"The sixteen T3 seeds" below), so that promise is checkable instead of asserted |
| `--g-structure` | two full-31 enumerator logs carrying `G_HIST` bin lines — one C2-ON (base C1∩C2∩C4), one C2-OFF (base C1∩C4) | two full-31 `solve --f1-c3-hist --f1-pairs 31 --f1-out-of-core DIR` runs, the C2-OFF one adding `--no-c2` (all on `main`; see [SOLVE_C_CLI.md](SOLVE_C_CLI.md) §`--f1-c3-hist`) | **23,054 s** (C2-ON) and **39,003 s** (C2-OFF) on 128 threads — see the cost caveat below the table |

**Branch note (T3 sampler).** The `--kc-*` subcommands are **not on `main`**.
They live in `solve.c` on the published branch `v4-compiler`, which
[BRANCH_REGISTRY.tsv](BRANCH_REGISTRY.tsv) classes as a *snapshot* — a frozen
working branch, not the authoritative corpus, and not something to cite for
claims. Regenerating the T3 sample therefore costs a checkout and build of that
branch on top of the ~12.6 h of compute. The arguments above are deliberately
written **without** a `solve` prefix: an invocation form would assert that the
command runs against this ref's binary, and it does not.

**The sixteen T3 seeds (published 2026-09-01).** Until today the generation recipe above carried
only a `<seed>` placeholder and no seed value appeared anywhere in this repository — so a
replicator could spend the stated ~12.6 h against the 3.1 TB f-ladder and obtain **a different
million draws**, while this section promised the opposite. The seeds were hash-committed before
the first recorded draw (private pre-registration `PREREG_F_CATALOG_T1_T4_2026_08_06.md` §3); what
was missing was publication, not determinism. This closes that gap for the same reason the section
opens with: *a script in a private repo does not make a public number reproducible*, and a seed a
replicator cannot see is the same defect one level down.

**Derivation convention (A-4), so the table is self-checking.** Stream `i` (0–15) has seed string
`ROAE-A34-MEGASAMPLE-2026-08-06/stream-<i>`, and its `uint64` seed is the **first 8 bytes,
big-endian, of that string's SHA-256**. Recompute all sixteen without trusting this table:

```sh
python3 -c 'import hashlib
for i in range(16):
    s = "ROAE-A34-MEGASAMPLE-2026-08-06/stream-%d" % i
    print(i, int.from_bytes(hashlib.sha256(s.encode()).digest()[:8], "big"))'
```

| stream `i` | `uint64` seed | SHA-256 of that stream's RAW (uncompressed) `.out` |
|---|---|---|
| 0 | `9669408800517721104` | `e832639eb0f13634c2d57dd3e5225497490053173258c8ddf35439d7b029b878` |
| 1 | `6242241442386181616` | `bb4422881da274f843447a055cc9d89564d045ae2d29d11b72243001f6b9f75f` |
| 2 | `1416358277983929375` | `53d1029227ad7e4880df85819d0aa81b8109845660cef9f2bdaf0190c15a6a75` |
| 3 | `4646029019256462395` | `bcb19f5775b4c2cf64c26748881d3bed18ce1ea39d543a2ce6ed763768312e5a` |
| 4 | `10132470525042148459` | `ec75437bee24937d85860e181511afedca9632dc52643761f84c395b15f25667` |
| 5 | `5461764689074339727` | `c9d36ea1004cf5d46ae74b556e753a95960181401285c7c7ea3d99ac40c07f1f` |
| 6 | `5499611017164625166` | `5412b8bf7a1aee48597fc1e2b876b795108a933c605ccd5d2f07960c6873ac65` |
| 7 | `13711452108361363374` | `b15bb27dc29fa1640ba30a5b2a7940e347b5963cd0f7b82e18e57125301d7096` |
| 8 | `1690275703773005641` | `92d673b3d78304ce775d10f0e839bc13786a2ab49cae1bcf660c2105d7dcb975` |
| 9 | `7786930182613696262` | `317310fd82eecd4f1a7c971ef65e9dc38e62ba4b6c4dd8151660157df93a138b` |
| 10 | `2270373624679916037` | `d3e2158191965cffc295e77ece87695f21223953273285d1b1d4e429f774e007` |
| 11 | `12452849671881695376` | `7121dbaf5fe9c4cb692d0480960d287827c59d20550fe8fdfc9cee9e7b3d4c05` |
| 12 | `12023112334724232975` | `ec9f9c75a95bc9f373eb310e4d769342daee66aeecfbea8e01f36d46eb95c169` |
| 13 | `18396732811704272006` | `c72acc338db7b6adde2fcb7d5a3b3bd3c430fc05f3b20cb57f0f4c3c572d539c` |
| 14 | `3818886581895625039` | `fe3790886dff1dd281a01124089dd811c7b78ec000096474e76fccc297e2e74c` |
| 15 | `1763809942541937727` | `620027c5a0ac66b7ca3f5fde365f49b90e8c2281a6d162cc88aef3148b0afe35` |

The third column lets a regenerated stream be checked byte-for-byte without access to the archived
sample: run the stream, `sha256sum` its raw stdout, compare. (The archive stores the streams
gzipped and carries the same digests in its own `RAW_SHA256.txt`; verify with
`gzip -dc t3_stream_<i>.out.gz | sha256sum`.)

**Truncation provenance.** The pre-registration froze 16 streams × **625,000** draws (M = 10⁷).
Before any T3 stream started, the prereg's own frozen truncation clause was exercised — measured
throughput extrapolated M = 10⁷ to ~10–14 days wall, past both the committed wall bound and the
cost band — and all sixteen streams were cut to an **equal** 62,500 each (M = 10⁶). Seeds, command
and every decision rule were unchanged, and no draw was ever discarded selectively; an
equal-length prefix of an exact-uniform iid stream is exact-uniform iid. So the 62,500 above is
the clause being exercised as written, not a discrepancy with the pre-registration.

**f-ladder identity.** The draws descend the Stage F ladder recorded by the run's own
`[kc-ooc] opened` line as `n=31 layers=0..31 kind=f format=v2` (~3.1 TB, Premium P50). A
regeneration against a *different* f-ladder is not a reproduction of this sample, however the
seeds are set.

**Cost caveat (`--g-structure` inputs).** Those two figures are each the
**final attempt's** reported wall. Both runs were checkpoint/resumed across Spot
evictions — the C2-OFF log on hand begins with `RESUME from last complete layer
k=16`, so its 39,003 s covers layers 17–31 only. They are therefore **lower
bounds** on from-scratch cost, not the total. For scale, the C2-ON run's
first-attempt-start to final-exit span was ≈33.6 h.

Analysing an artifact you already have is cheap by comparison. Measured
2026-08-11 with `/usr/bin/time -v` on the project's 2-vCPU orchestrator VM
(Azure D2as_v6, AMD EPYC 9V74, the two vCPUs being SMT siblings; Python 3.12.3),
over the same 10⁶-draw sample:

| analysis | peak RSS — reproducible | wall — band, not a figure |
|---|---|---|
| `--t3-stats` | 22,740–23,084 kbytes (≈22.9 MB), 7 runs | ~3–5 s — load-dependent |
| `--t3-membership`, full census | 148,844–149,092 kbytes (≈149 MB), 7 runs | ~60–100 s — load-dependent |
| `--g-structure` | not measured | not measured |

**Peak RSS is the reproducible figure. Wall is not — quote it only as an order
of magnitude.** This section has now been wrong twice about wall, in opposite
directions, and both errors are recorded here rather than replaced quietly:

1. It first published a bare **"82 s"**. Five identical full-census runs spanned
   **76.9–97.9 s**, so a single number was never right.
2. It was then rewritten to publish that band and to assert the spread was
   intrinsic — *"the spread is in user CPU time … a quieter machine will not
   remove it."* **That was also wrong.** Independent re-measurement on a genuinely
   idle box returned **60.6–61.2 s at 99 % CPU**, below the whole published band.
   A quieter machine did remove it. The "carrying no workload but the runs
   themselves" claim was simply false: several agents were writing to this
   two-vCPU box concurrently while those numbers were taken, and the two clusters
   near 78 s and 96 s are that contention, not a property of the workload.

The lesson generalises past this file: **a wall-clock figure measured on a
2-vCPU shared-tenancy box while anything else runs is not a measurement of the
program.** Peak RSS reproduced across every condition — 0.17 % over the noisy
runs, and the independent idle runs landed inside the same band — so RSS is what
this section stands behind. Re-measure either mode yourself with `/usr/bin/time -v` in front of the
documented command — the input directory is the one described in the table
above.

So the cost of reproduction is dominated entirely by regenerating the input, and
that is the number a reader needs.

**Independence is unchanged.** These modes import nothing from `solve.c` /
`solve.py` / `roae.py` / `sat.py`, exactly like the rest of this file. The
membership evaluator is the sharpest case: its *only* value is that it shares no
code with the sampler whose output it judges, so its predicates are transcribed
from [SPECIFICATION.md](SPECIFICATION.md) and `partner` is re-derived from the
stated rule (reverse; complement for the self-reverse hexagrams) rather than
copied from any table. It reuses `verify.py`'s own rule-derived helpers, which
are gated at import by `_verify_tables_against_rules()` against the
SPECIFICATION.md literals — the same clean-room derivation, not a shortcut
through the engine. Importing an engine helper here would destroy the property
that makes the check worth running; the source carries that warning too.

**What these modes do not establish.** `--t3-stats` (a) tests uniformity of the
**rank stream**, i.e. the unrank path — not uniformity over the solution space
in any richer sense; a PASS licenses the sample as a uniform null and says
nothing about whether a particular downstream observable is well-behaved.
`--g-structure` says nothing about prefix-G g48-invariance, because a quotiented
run cannot test the assumption its own quotient makes.

## The independent method (`--recount`)

Two methods, deliberately unlike the symmetry-quotient DP:

1. **Exhaustive backtracking** (no memoization, no DP table, no symmetry):
   place the pairs one at a time in every order and both orientations, prune
   only on the published boundary rule (Hamming distance ≠ 5), count the
   complete leaves. This is as primitive and independent as it gets, and is used
   both for the small-n `--enumerate-reference` check and to cross-validate the
   recurrence.
2. **Plain layered subset DP** (a *counting recurrence*): state = `(placed-pair
   mask, last-exit hexagram)` → exact big-integer count; a transition places any
   unused pair in either orientation iff the boundary distance ≠ 5 (C2). It
   stores **every** mask (no canonical-representative collapse), so a
   quotient/canonicalization bug **cannot** be shared with `solve.c`. Only two
   popcount layers are ever live; peak memory is ~24 MB.

All arithmetic is exact Python big integers. The two methods are shown to agree
exactly on small prefixes (k = 3..7) before the recurrence is trusted at U1/U2/U3.

## Match table (from `python3 verify.py --recount`)

Every quantity below carries a **published** value and an **independent** value
computed by the method named; ✓ = exact match.

### Target 1 — small-n structural facts

| quantity | published | independent | match | method |
|---|---|---|---|---|
| Canonical partner-pairing == 32 published KW pairs | (equal sets) | equal | ✓ | derive `partner()` orbits, compare |
| KW is a permutation of {0..63} | true | true | ✓ | flatten published pair table |
| C1: every KW pair is {h, partner(h)} | true | true | ✓ | recompute `partner()` |
| Within-pair distance multiset (32 pairs) | {2:12, 4:12, 6:8} | {2:12, 4:12, 6:8} | ✓ | popcount within each pair |
| XOR-product set {h ⊕ partner(h)} | {12,18,30,33,45,51,63} | same | ✓ | XOR within each pair, dedup |
| KW difference-wave D(S), 63 transitions (C5) | {1:2,2:20,3:13,4:19,6:9} | same | ✓ | popcount along KW |
| KW between-pair boundary multiset, 31 boundaries (reduced-C5 B0) | {1:2,2:8,3:13,4:7,6:1} | same | ✓ | popcount at 31 boundaries |
| KW C3 complement-distance sum (×64 integer form) | 776 | 776 | ✓ | Σ\|pos(h)−pos(comp(h))\| |
| C2: no distance-5 adjacency in KW | true | true | ✓ | popcount |
| C4: KW starts (63, 0) | true | true | ✓ | read s₀,s₁ |
| \|symmetry group C_S₆(rev)\| | 48 | 48 | ✓ | keep perms commuting with reversal |
| group fixes {0,63} + is Hamming-isometric | true | true | ✓ | check on all/subset |
| distinct induced pair-permutations (record group S₄) | 24 | 24 | ✓ | induce on 32 pairs, dedup |
| King Wen orbit size at record level (KW + twins) | 24 | 24 | ✓ | apply 48 bit-perms, canonicalize |
| King Wen record-level twin count | 23 | 23 | ✓ | orbit − KW |

### Target 2 — reduced-rung C1∩C2∩C4 union counts (TR-11 Verification Guide §4a)

| rung | published | independent | match | method |
|---|---|---|---|---|
| U1 = 9 pairs {3.0,3.1,3.2}@0 | 63,366,144 | 63,366,144 | ✓ | counting recurrence |
| U1 (same), second method | 63,366,144 | 63,366,144 | ✓ | raw exhaustive backtracking |
| U2 = 12 pairs {6.0,6.1}@0 | 1,961,990,553,600 | 1,961,990,553,600 | ✓ | counting recurrence |
| U2 closed form 12!·2¹² | 1,961,990,553,600 | 1,961,990,553,600 | ✓ | closed form |
| U3 = 13 pairs {3.0,4.0,6.2}@63 | 39,239,811,072,000 | 39,239,811,072,000 | ✓ | counting recurrence |

**Result: every quantity RE-COUNTED HERE reproduced its published target EXACTLY,
0 mismatch** (rerun `python3 verify.py --recount` to regenerate the full table; exit 0
requires every re-counted target to match AND at least one target to have been
re-counted — the six large C5 rungs that exceed this host are reported as
`RECOUNT_NA` in the machine-readable summary, not silently folded into the claim).
Peak RSS ~24 MB for the tables above; wall time dominated by the 63 M-leaf U1
backtracking and the n = 16 budgeted DP.

### Target 3 — reduced-rung C1∩C2∩C4∩**C5** ladder (TR-11 §4b; added 2026-07-21)

| rung | published | independent | match | method |
|---|---|---|---|---|
| n=9 `{3.0,3.1,3.2}@0`, B0 = (2,5,0,2,0) | 26,112 | 26,112 | ✓ | B0 re-derived by §5 Step-1 DFS, then plain budgeted (mask, last, p) DP |
| n=13 `{3.0,4.0,6.2}@0`, B0 = (1,6,0,6,0) | 2,063,395,607,040 | 2,063,395,607,040 | ✓ | same |
| n=16 `{4.0,6.0,6.1}@0`, B0 = (1,8,1,6,0) | 267,765,117,419,520 | 267,765,117,419,520 | ✓ | same |

The larger rungs (n = 18–28) remain out of pure-Python reach on a light host
(the budget dimension multiplies the state count by thousands); they are covered
by the engine's own 4/4 cross-mode ladder (TR-11 §8), not by this instrument.

## Two published-recipe defects this instrument surfaced (both fixed)

1. **The reduced-C5 rung definition was under-specified (F-3, fixed in TR-11
   v1.2, 2026-07-20).** As originally published, the recipe said to retain
   states whose boundary multiset was a *sub-multiset* of King Wen's — under
   which the 13-pair rung counts 38,492,859,594,240, **not** the published
   2,063,395,607,040 — and the per-rung target budget vector lived only in
   `solve.c`'s private `f1c5_unions[]` table. TR-11 §4b/§5 now publish the
   ordered pair lists, the per-rung `B0` targets, and the exact-match rule; the
   Target-3 checks above run against the corrected public recipe, with `B0`
   re-derived rather than copied.
2. **The full-31 `B0`-coincidence claim was false (fixed in TR-11 v1.8,
   2026-07-21).** TR-11 §5 claimed the Step-1 first-completion DFS reproduces
   King Wen's boundary multiset at full 31. Both this file's Python and
   `verify.c`'s C implementation of the published recipe return (2,7,13,8,1)
   against KW's (2,8,13,7,1): at full 31 the budget is **defined** as KW's
   multiset, not derived via Step 1. No published number was affected — the
   engine uses KW's multiset — but the documented derivation was wrong, and an
   independent instrument is what caught it.

## What the records path actually enforces (A3 audit, 2026-08-01)

An adversarial audit asked a narrow question of `verify.py [solutions.bin]`: for
each of C1–C5, is the predicate the code tests **logically equivalent** to the
formal statement in SPECIFICATION.md, or has it drifted? Three defects in the
instrument itself, all now fixed:

1. **C4 was only half-checked (the serious one).** SPECIFICATION.md C4 is two
   conjuncts — `s₀ = 63` **and** `s₁ = 0` — but the code tested only the *pair
   index* (`first_pair != START_PAIR`), never the orientation bit. Because the
   2026-07-26 retraction established that complementation `x ↦ x ⊕ 63` is an
   exact symmetry of C1∩C2∩C3∩C5 (machine-checked, `lean/KingWen.lean`), **no
   other check in the file could compensate**: a record encoding `comp(KW)` —
   which opens (0, 63) — passed C1, C2, C3 and C5, passed the index-only C4, and
   printed `VERIFY PASS`. The check had been silently leaning on the
   enumerator's hardcoded `seq[0]=63; seq[1]=0`, which is precisely the
   invariant an *independent* verifier is not entitled to assume — its job is to
   catch enumerator bugs, not inherit them. A correct oriented predicate already
   existed in `--recount-finite`'s `classify()`, but not on the records path.
   Now tested in spec form. *(No canonical artifact was ever affected: `solve.c`
   pins the orientation, and the format's dedup rule keeps the lexicographically
   smallest orient variant. The defect was a latent false-PASS, not a false
   result.)*
2. **The reference tables were self-verifying.** `PAIRS`, `KW_DIST` and
   `KW_COMP_DIST` are all derived from the `KW` literal at the top of the file,
   so a corrupted `KW` table would silently redefine C1 and C5 and then check
   every record against the corruption — accepting violating records and
   rejecting compliant ones, consistently. The rule-derived cross-checks existed
   but were reachable only via `--recount`. They are now an **import-time gate**
   (`_verify_tables_against_rules()`): KW is a permutation of {0..63}; `PAIRS`
   equals the `partner()`-derived canonical pairing; every pair is
   partner-exact; the difference-wave multiset equals SPECIFICATION.md C5's
   literal `{1:2, 2:20, 3:13, 4:19, 6:9}`; `cd(KW) = 776`. Explicit raises, not
   `assert`, so they survive `python3 -O`.
3. **Reserved fields were unchecked.** SOLUTIONS_FORMAT.md specifies `bit 0:
   unused, always 0` per record byte, and header bytes 16–31 `MUST be zero`.
   Record bit 0 is masked out of the canonical sort key (`& 0xFC`) but *does*
   participate in the full-byte dedup tie-break, so a set bit 0 breaks
   byte-exact reproducibility between two otherwise-conformant implementations.
   Both are now counted as format errors — counted rather than raised, so the
   record-level verdicts are still reported alongside them.
4. **King Wen's presence was print-only.** `King Wen: YES/No` was never folded
   into the exit status, so on a complete canonical its absence — a real defect
   — was visible only to an operator reading the line. The default is correct
   and unchanged (an individual shard legitimately need not contain KW); the
   new **`--expect-kw`** promotes presence to a hard requirement for runs over a
   complete canonical.

Found sound and unchanged: **C2** (all 63 linear transitions, correct range, no
spurious wrap-around); **C3** (`Σ|pos(v) − pos(v⊕63)| ≤ 776`, the ceiling
anchored to the spec literal); **C5** (exact multiset equality, which also
forces the d=5 count to zero); **C1**'s permutation property (`pidx < 32` +
each pair used exactly once + disjoint partner-pairs); header/framing; the
chunk-boundary stitching (adjacent-pair sortedness ⇒ global sortedness, no
off-by-one at the seams); the gzip path; and the `& 0xFC` dedup key, which is
correct rather than over-strict because the format collapses orientation
variants by design. `verify.c` is unaffected — it has no records path.

All four fixes are covered by regression tests in `tests.py`: `comp(KW)` must
FAIL on C4 **alone** (it passes C1/C2/C3/C5 — a live executable demonstration
of the Complement Z₂ symmetry theorem), a bit-0-tampered record and a nonzero
header reserved field must FAIL on format, `--expect-kw` must fail when King
Wen is absent, King Wen itself must still PASS, and the table gate must reject
a corrupted `KW`. That last fixture is chosen so **only** the C5 gate can catch
it: swapping pair-blocks 1 and 2 leaves cd exactly 776 (the C3 anchor is
blind), leaves the pairing set unchanged (the C1 gate is blind), and introduces
no d=5 transition (a C2-style check is blind).

*Audit provenance: the same drift was found independently twice — by Fable on
2026-07-30 (fixes held for the commit window) and again by a fresh probe on
2026-08-01 that was given no knowledge of the first. Two independent
rediscoveries of the same defect set, with the second adding the header
reserved-field item, is the cross-model control the review protocol asks for.*

## The repr(k) oracle in C: `verify.c --check-repr`

`./verify --check-repr FILE [N] [OFFSET]` is the same instrument as
`verify.py --check-repr` above, in C, because Python cannot cover 1.78×10⁹
records: the underlying search is a DFS per record and its cost is heavy-tailed.
It is written independently of the Python version as well as of `solve.c` — same
definition from [`lean/RecordConvention.lean`](../lean/RecordConvention.lean),
built on `verify.c`'s own `KW[]`, `build_pairs()` and `hamming()`, with the C5
budget re-derived and asserted against `[0,2,20,13,19,0,9]`. Reads gzip or plain
via zlib; skips to `OFFSET` by reading rather than seeking, so a short read is
distinguishable from EOF at the target rather than silently landing elsewhere.

The two implementations agree with each other on King Wen's key, and both
reproduce King Wen from it. Negative controls fire in both: a flipped orientation
bit is caught, and reversing the DFS child order to 1-before-0 yields a strictly
*greater* record — which is what makes the lexicographic-minimum claim
non-vacuous rather than merely "some valid completion was found".

✅ **The C3 gap recorded here was closed 2026-09-02, in this implementation and
its Python twin together.** `vc_repr_of_key` previously applied the forced opening,
the HD-5 exclusion and the C5 budget only, so a key whose pair sequence has
`C3 > 776` was completed rather than reported `INCOMPUTABLE`: `./verify --check-repr`
printed `AGREE=1`, `INCOMPUTABLE=0`, `CHECK_REPR=PASS`, rc = 0 on the `C3 = 1080`
fixture. It now applies a C3 pre-filter before entering the DFS and returns no
completion, giving `INCOMPUTABLE=1`, `CHECK_REPR=FAIL`, rc = 1 — byte-identical
verdict tokens to `verify.py` on the same fixture. The controls in the paragraph
above could not have shown the original gap, for the same structural reason the
`--check-artifact` controls table could not: each perturbs a record until an
*existing* check fires, and there was no C3 check to fire. That is why the
replacement control asserts a **token** (`INCOMPUTABLE=1`) rather than the mode
verdict — `CHECK_REPR=FAIL` alone would have been satisfied by a record that failed
for an unrelated reason.

Same verdict vocabulary and the same scope caveat as the Python mode: it checks
the records it reads. Spread coverage with several `OFFSET` values instead of
enlarging `N` at one position.

The model-level theorem these oracles complement is
[`lean/PruneReprFC.lean`](../lean/PruneReprFC.lean); as everywhere in this tree,
that proof is about the model and the bridge to the shipped binary is carried by
prose plus runtime gates, not by the proof.

## The Route B engine: `verify.c --ie-count`

`./verify --ie-count` recomputes \|C1∩C2∩C4∩C5\| by classical signed inclusion–exclusion over
subsets of the 31 free pairs: N = Σ_S (−1)^(31−|S|) W(S), where W(S) counts repetition-allowed
31-step walks over S with the d ∈ {1,2,3,4,6} boundary predicate and class budgets capped at
KW's boundary multiset (2,8,13,7,1). DP state is `(last hexagram, budget vector)` — no mask,
<1 MB per thread. The 24-element record group enters only as a startup-re-verified
subset-enumeration lemma (W(gS) = W(S)); `--ie-no-quotient` disables it. Arithmetic: three
passes modulo the largest primes below 2⁶³ (Miller–Rabin-proven at startup), CRT-combined; on
small instances the mod-2⁶⁴ wrap pass cross-checks the mod-p path exactly. Spot-safe chunk
checkpointing (`--ie-checkpoint`); `--ie-negctl` is a must-differ negative control;
`--ie-probe NSAMP` sizes a full run. Validation ladder and the 2026-07-25 full-scale MATCH:
TR-11 §10(vi).

## Corroboration chain for the full-scale count

- **Independent full-scale recomputation (`verify.c --ie-count`, 2026-07-25).** A signed
  inclusion–exclusion transfer-walk over free-pair subsets (DP state `(last, budget)`, no mask
  — a different algorithm class sharing no code or machinery with `solve.c`) recomputed the
  full-31 integer via three Miller–Rabin-proven 63-bit prime passes, CRT-combined: **exact
  match**, with the mod-24 gate holding. This is the direct discharge of TR-11 §10(vi)'s
  instrument half; the items below are the (retained) corroboration that pre-dated it.

Tier-2 scope was intentional (per TR-11, the full 31-pair count is out of scope
here). The full-scale exact count
|C1∩C2∩C4∩C5| = 1,097,051,278,789,181,790,036,112,071,176,579,186,688 (TR-11 §9)
does **not** rest on this instrument. Its corroboration chain is:

- **Method-agreement at the reduced rungs (here).** An independent instrument,
  a different counting method (plain no-quotient recurrence + raw backtracking),
  and stdlib-only code reproduce the C1∩C2∩C4 unions, the C5 ladder rungs
  n = 9/13/16 (budgets re-derived), and every small-n structural fact exactly —
  validating the recursion and the pairing/symmetry machinery the full-scale
  run depends on.
- **The project's own two engines agree at every validated subset size (≤28
  pairs).** The in-RAM symmetry-quotient DP and the out-of-core streaming DP
  produce identical layer content and digit-identical totals at every validated
  subset size (24/25/27/28 pairs reproduced digit-for-digit, TR-11 §8;
  byte-identical files in those v1-format validation runs — under current
  defaults the two modes' files are content-identical but byte-different, per
  TR-11 §10(vi)'s precision note). At full 31 the in-RAM path is infeasible
  (TR-11 §6), so this agreement does **not** extend to full scale. The
  compiler / DFS lineages cross-check the enumeration side.
- **Per-layer mass agreement at full 31, within memory reach (`verify.c`).** A
  plain non-quotient DP reproduces the engine's per-layer plain masses on the
  true full-31 instance for every layer it can hold — exercising exactly the
  stabilizer bookkeeping TR-11 §2 flags as delicate.
- **The mod-24 free-action gate.** The free action of the order-24 record group
  forces N ≡ 0 (mod 24); the full-scale integer satisfies it exactly — a
  zero-code reader-side arithmetic check.
- **The Knuth estimator.** The exact full-scale integer falls inside the
  independent unbiased random-probe estimate's stated ±0.01% envelope (the
  0.0044% figure sometimes quoted is the estimate's five-sig-fig rounding gap,
  not a resolved estimator error).

Method-diverse agreement at Tier-2 here, the ≤28-pair two-engine equivalence,
the full-31 per-layer masses within `verify.c`'s reach, the mod-24 gate, and
the estimator together corroborate the full-scale count. TR-11 §10(vi)'s
instrument half is now discharged: the full-31 integer was independently
recomputed at full scale (2026-07-25) by `verify.c --ie-count` and matches
exactly. The remaining honest residual is that both instruments are
project-authored — no third-party recomputation exists. (The C5-ladder
definitional gap this instrument originally surfaced
is resolved — see the defects section above.)

---
*`verify.py` imports no project code and is stdlib-only except `--check-t5-c3`, which needs
`numpy` + `pyarrow` to read the parquet under test — run `python3 verify.py
--recount` to regenerate the match table. `verify.c` builds with `cc -O2 -o
verify verify.c -lz -lpthread -lm` and reads a run's `run.out`. (⚠ `-lm` corrected
2026-08-21: the line previously omitted it and **failed to link** — `kn_ci` calls `sqrtl`, so
`cc` reports `undefined reference to 'sqrtl'`. Found by a cold external-reviewer pass and
reproduced here; the asymmetry with solve.c's own documented `-lm` build line had been sitting
in the text.) Developed with AI assistance
(Claude, Anthropic).*

**Provenance of the C5-ladder rows (2026-07-21):** the C5 ladder entries below are backed by an actual
`python3 verify.py --recount` execution on 2026-07-21 (27 quantities reproduced, 0 MISMATCH,
~134 s), not merely by TR-11's published statement. The landed run's `count_result.json` retains
its original `"estimate accurate to 0.0044%"` note verbatim: it is a machine-readable record of
what that run produced, so it is annotated here rather than edited — post-hoc rewriting of a
landed artifact would damage its provenance value. The hedged reading (that figure is the
estimate's rounding gap, not a resolved error) is carried in the surrounding prose.

## `--check-artifact`, and what the 2026-08-15 sweep actually found

`./verify --check-artifact FILE [N] [OFFSET]` / `python3 verify.py --check-artifact [N]`.
Two implementations, no shared code; both were gated against the same seven
controls below and agree counter-for-counter.

### The sweep result, and the correct reading of it

A `--check-repr` sweep was **started** against the 1,776,347,935-record merge output on
2026-08-15, **stopped early**, and reported disagreement — **regionally**, at rates
from **1.06 % to 42.2 %**, with **9 chunks of 5,242,880 records each agreeing
perfectly** (47,185,920 records) and `INCOMPUTABLE=0` throughout.
**Coverage, stated exactly: this did NOT cover the whole artifact.** Nine chunks passed, 212
reported disagreement, and the run was halted. The per-chunk manifest is not published, so the
percentages below are attributable to a named instrument and a named artifact, but are **not
reproducible from this repository alone**. A uniformly broken oracle cannot
produce that pattern, so the sweep was stopped before any conclusion was drawn
about the data.

**CONFIRMED 2026-08-15 — this is no longer an expectation.** The post-pass was run: 1,776,347,935
records normalized, idempotent (a second pass is byte-identical),
`--check-artifact` PASS over the whole output, and **`--check-repr` on the output AGREES 100 %** —
100,000/100,000 at each of six offsets, against 1.06–42.2 % disagreement on the input. *Scope: the
agreement is measured on 600,000 sampled records; the whole-artifact independent pass has not been
run, and the output's sha is deliberately NOT published here — registering a canonical is a
decision that has not been taken.*

**`solutions.bin` is a PRE-NORMALIZATION artifact.** The global repr(k) is
applied by `orb_normalize_rec_op` → `orb_repr_global`, exposed as
`solve --kc-repr-normalize IN.bin OUT.bin` (task #20) — ⚠ **on an unlanded branch, NOT in this
tree; see the box immediately below** — and that pass has not been run on it. The disagreeing records **are** the post-pass's work-list. So
`--check-repr` is the right acceptance test for the post-pass *output* and is
expected to fail on its *input*; running it on a raw merge is a category error,
not a finding.

> **⚠ NOT AVAILABLE IN THIS TREE — and the two cases are NOT the same.** None of
> `--kc-repr-normalize`, `orb_normalize_rec_op`, `orb_repr_global` or `orb_recanon` exists in
> `main`'s `solve.c` (zero occurrences), but where they *do* live differs, and an earlier version of
> this box wrongly implied all four were fetchable from one registry-listed branch:
>
> * `orb_normalize_rec_op`, `orb_repr_global`, `orb_recanon` — on **`orbit-port-188-candidate`**,
>   which IS pushed to origin and which [BRANCH_REGISTRY.tsv](BRANCH_REGISTRY.tsv) classes
>   *snapshot — do not cite*. A reader can fetch and inspect these, but must not cite them.
> * **`--kc-repr-normalize` and the forward-checked prunes (`SOLVE_REPR_FC`) — on NO PUBLISHED REF
>   AT ALL** (verified 2026-08-21: zero occurrences on `main`, `v4-compiler`, `v4-canonical`,
>   `stageg-telemetry` and `orbit-port-188-candidate`). They exist only on an unpushed local branch.
>   A reader **cannot obtain them by any means**, so nothing in this repository should be read as
>   offering them.
>
> ⚠ Consequently [`lean/PruneReprFC.lean`](../lean/PruneReprFC.lean) is a **freestanding model-level
> result**: its §1/§3 statements and the §5 counterexample stand on their own, but the declared
> bridge to the shipped binary (prose comment + code review + runtime gates) rests on material that
> is **not published**, so a reader cannot perform any leg of it. Read the theorem as about the
> model, never as evidence about a binary you can run. A reader of `main` cannot run this pass. Relatedly, the `--check-repr` row's quotation *"there is NO separate
> repr oracle in this tree"* is that branch's **runtime output**, not text in `main`'s `solve.c`, and
> must not be read as quoting this repository.

**One misreading, made and retracted the same day, is worth recording** so it is
not repeated. `orb_recanon` pins slots 0..3 from a member *cell's* prefix, and it
is tempting to read that as the record convention. It is not: its only caller is
`orb_expand_record`, for cell-faithful expansion shards. The "orb_recanon DFS
shape" named in `RecordConvention.lean` is `orb_recanon_dfs`, the shared DFS that
`orb_repr_global` enters at slot 1 having forced slot 0 alone. Cell-scoped
visited-min was considered and **proven insufficient** as a record representative
(`visitedMin_not_nested`): the merged cross-cell min moves with budget, breaking
partition-invariance and record-level nesting. The convention is settled, and it
is global.

### Why a linear instrument was still worth building

`--check-repr` cannot validate an un-normalized artifact, and it has a second
limitation that survives normalization: it is **structurally blind to a wrong
pair sequence**, because `repr_of_key` is handed the key decoded from the very
record it is compared against, so a disagreement can only ever be an orientation
bit. `--check-artifact` checks the pair sequence directly, applies to the
artifact as it exists today, and being linear rather than a search it streams the
whole file in minutes instead of the ~47 h a repr sweep costs.

### Direct evidence that a key has many valid orientations

Of the 31 single-orientation-bit flips of King Wen's own record, **9 still validate** under
`--check-artifact`; **15 trip `BAD_BUDGET`** and **7 trip `BAD_HD5`**. *(Corrected 2026-08-15: this
first read "16", computed as 31−15 on the assumption that `BAD_BUDGET` was the only failure mode.
The measuring harness grepped `^BAD_[A-Z_]+=[1-9]`, whose character class excludes DIGITS, so
`BAD_HD5=1` — the one counter whose name contains a digit — never matched, and 7 failures were
silently counted as passes. The conclusion below survives; the number did not.)*

**Reproduce, and do not trust any grep of mine:** `python3 verify.py --check-flips` prints the full
census by failure mode. Reads no files. So a pair-order key
routinely admits many valid orientation completions, and *which* one an
un-normalized record carries is walk-dependent — though not in the way an earlier revision of this
section said. Each thread keeps the **byte-wise least** variant it has seen for a canonical class
(`solve.c`: *"Lex-smallest record wins"*), chosen precisely so the result does **not** depend on
thread arrival order. The real dependence is on the **visited set**: the least-among-VISITED variant
moves as the budget slice changes. Normalization is what replaces that with a function of the key
alone — which is precisely why it is required for partition-invariance.

### Controls (a positive plus thirteen negatives; all pass)

| control | differs from positive by | expected |
|---|---|---|
| `ctl_pos` | — (6 valid records, King Wen among them) | `ARTIFACT=PASS` |
| `ctl_key` | one slot's pair index duplicated | `BAD_KEY=1` |
| `ctl_open` | slot 0 pair swapped away from (63,0) | `BAD_OPENING=1` |
| `ctl_hd5` | a pair placed at slot 1 with HD(0,first)=5 | `BAD_HD5=1` |
| `ctl_orient` | orientation bit at one specific slot | `BAD_BUDGET=1` — **the slot matters**: across all 31 flips, 9 pass, 15 give `BAD_BUDGET`, 7 give `BAD_HD5` |
| `ctl_spare` | one reserved bit0 set | `BAD_SPARE_BIT=1` |
| `ctl_dup` | one record repeated | `BAD_ORDER=1` (duplicate class) |
| `ctl_order` | two adjacent records swapped | `BAD_ORDER=1` (out of order) |
| `ctl_c3` | a record whose pair sequence has `C3 = 1080` (C1/C2/C4/C5-valid) | `BAD_C3=1` |
| `ctl_hdr_version` | header format version set to `2` | `BAD_HDR_VERSION=1` |
| `ctl_hdr_reserved` | one header reserved byte (16–31) nonzero | `BAD_HDR_RESERVED=1` |
| `ctl_geometry` | header declares 5 records over a 1-record body | `BAD_GEOMETRY=1` |
| `ctl_partial` | a torn trailing record (10 stray bytes after a whole one) | `ARTIFACT=FAIL_partial_record`, rc 2 |
| `ctl_repr_c3` | (`--check-repr`) the lex-least completion of a `C3 = 1080` key | `INCOMPUTABLE=1`, `CHECK_REPR=FAIL` |

`BAD_BUDGET_RESIDUE` has **no control because none is possible**: the budget totals
63 and a complete record consumes exactly `1 + 31*2 = 63`, so a record whose every
decrement succeeded has zero residue by arithmetic. It is retained as a fail-closed
guard against a future table change, and is documented as unreachable rather than
claimed as tested.

⚠ **What this table structurally cannot show (added 2026-09-01; the instance below
was closed 2026-09-02, the limitation was not).** Every row here perturbs a record until an
*existing* counter fires. That design can only ever exercise predicates the code already
implements — it is blind, by construction, to a constraint with no counter at all. **The
limitation is permanent and this note stays regardless of how many rows the table grows.**

The instance it was written about was **C3**, and it is now fixed, so the paragraph is kept as
the worked example rather than as an open item. Both implementations certified `ARTIFACT=PASS`
on a record whose pair sequence violates `Σ|pos(v) − pos(v⊕63)| ≤ 776`, and every row above
still behaved exactly as documented, because there was no `BAD_C3` to fire. The same omission
sat in the **repr oracle** — `repr_of_key` / `vc_repr_of_key` implemented a C4/C2/C5 completion
predicate where `RecordConvention.lean`'s is C2/C3/C5 — so `--check-repr` returned a completion,
and `INCOMPUTABLE=0`, for a key the definition says cannot be completed: two modes and four code
paths, found by sweeping the sibling class of the `--check-artifact` finding rather than by a
fresh charge. **Closed 2026-09-02**: a C3 leg in all four paths, a `BAD_C3` counter kept
counter-for-counter across the `--check-artifact` pair, an `INCOMPUTABLE`-side C3 rejection in
the repr pair, and the six new rows above — every one of them measured RED against the
pre-change binaries first. Three header legs (`BAD_HDR_VERSION`, `BAD_HDR_RESERVED`,
`BAD_GEOMETRY`) and one genuine two-instrument divergence on a torn trailing record were closed
in the same pass, the latter found only because red-testing the geometry control put a
malformed tail in front of both readers at once.

It was the **third instance** of the class the A3 audit above names — an independent verifier
inheriting an enumerator-enforced invariant instead of re-deriving it (the other two are that
section's items 1 and 2) — and the first to appear in a *new* instrument: `--check-artifact`
landed 2026-08-15, fourteen days after that audit fixed the class on the records path. The rule
that should have carried forward, and that the fix above is the occasion to restate: **any new
record-reading mode must enumerate its C1–C5 coverage against SPECIFICATION.md and justify each
omission in its docstring.**

## `verify.c` full option synopsis — Routes B and D, and the scan driver

**Added 2026-08-16.** `./verify --ie-count` was documented in this file; **its options were not,
and neither was the entire Route D DP engine nor the parallel scan driver** — 25 flags that a
reader of `documentation/` could not discover at all. A reviewer could start the Route B walk and
had no way to learn how to pin it, thread it, resume it, or cross-check it.

**Transcribed from `verify.c`'s own header block, which stays authoritative** — if these disagree,
the source is right and this section is stale. Routes B and D each have a fuller section header in
the source beside their implementation.

### Route B — independent inclusion–exclusion transfer walk (`--ie-count`)

The independent recount of `|C1∩C2∩C4∩C5|` (TR-11 §10(vi)); the second instrument behind the exact
full-scale figure.

```
./verify --ie-count [--ie-spec "3.0,3.1,3.2@0" | --ie-spec full31@0]
         [--ie-mod all|wrap|p0|p1|p2] [--ie-no-quotient] [--ie-no-budget]
         [--ie-threads N] [--ie-chunk-bits B] [--ie-checkpoint FILE]
         [--ie-range LO HI] [--ie-b0 a,b,c,d,e] [--ie-negctl]
         [--ie-expect DECIMAL] [--ie-pin SLOT:PAIR ...] [--ie-pin-c6c7]
         [--ie-brute]
./verify --ie-probe NSAMP [--ie-threads N]        # full-31 throughput probe
```

- `--ie-no-budget` — the `C1∩C2∩C4` (F4) variant.
- `--ie-pin` / `--ie-pin-c6c7` — the pinned-step (T3) variant for `|C1∩C2∩C4∩C5∩C6∩C7|`.
- `--ie-brute` — an independent small-n reference by explicit permutation DFS. **`n ≤ 12` only**,
  per the source; it is a cross-check on the walk, not a route to the full count.
- `--ie-negctl` — a negative control. A control that does not change the answer is not a control.

### Route D — layered exact-cover mask DP (`--dp-count`)

The **second instrument for the pinned (C6/C7) exact count, and a different algorithm class** — a
direct layered exact-cover mask DP with **no inclusion–exclusion**, so it shares no method with
Route B. That independence is the point of it.

```
./verify --dp-count [--dp-spec "3.0,3.1,3.2@0" | --dp-spec full31@0]
         [--dp-pin SLOT:PAIR ...] [--dp-pin-c6c7] [--dp-b0 a,b,c,d,e]
         [--dp-mod all|p0|p1|p2] [--dp-threads N] [--dp-checkpoint FILE]
         [--dp-expect DECIMAL] [--dp-negctl] [--dp-no-budget]
         [--dp-size-only]
```

Defaults: `spec full31@0`, `mod all`, `threads` = online CPUs. `--dp-negctl` swaps B0's d2/d4
budgets, and **the count MUST differ** — that is the control's whole content. `--dp-no-budget`
drops C5 entirely, giving a plain `(M,last)` DP and the F4-variant cross-check.

### The parallel scan driver (`--scan-layers`)

```
./verify --scan-layers DIR [max_k] [run.out]
./verify --scan-selftest
```

Runs **the same checks and masses as `--check-layers`** through a multi-observable parallel driver
(N `O_DIRECT` read lanes, plus riders: T7/BL-7 orbit census and a T6-slot stub). Environment:
`LC_SCAN_LANES`, `LC_SCAN_CHUNK_KB`, `LC_SCAN_ODIRECT`, `LC_SCAN_T6STUB`.

**`LC_RESUME=<path>`** *(documented 2026-08-22 — it was read by `verify.c` and documented nowhere,
flagged by the 2026-08-20 hardening sweep §F1a)*: path to a prior run's per-layer summary output.
When set, `--check-layers` **replays** the summary lines for layers already recorded there instead of
re-streaming those layers from disk, so an interrupted multi-layer check resumes rather than
restarting. The per-layer summary line is **identical for a freshly streamed layer and an
`LC_RESUME`-replayed one** (`verify.c:1062`), which is what makes the resumed output comparable to an
unresumed one. ⚠ A replayed layer is **asserted from the prior run, not re-read** — `census_got[k]`
is 0 for replayed layers (`verify.c:871`). **A resumed run therefore attests less than a full one;
do not report it as a from-scratch verification.**

**Identity contract:** with `[scan] `-prefixed lines removed, its stdout and its return code are
**byte-identical** to `--check-layers`. `--scan-selftest` proves that on fixtures — so the fast path
is held to the slow path's output, not merely believed to agree with it.
