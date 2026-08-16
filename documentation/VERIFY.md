# VERIFY.md — the independent second instruments (`verify.py`, `verify.c`)

*Companion to `verify.py` (and its C-side sibling `verify.c`). Addresses the
single-instrument caveat raised in
[TR-11 §10(vi)](../reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md): "at full
31 … the full-31 integer will initially rest on a single instrument." (That
caveat's instrument half is now closed: on 2026-07-25 `verify.c --ie-count`
performed the independent full-scale recomputation — exact match. See the
closing section.)*

`verify.py` is a genuinely **independent** second opinion on the ROAE results.
It is standard-library-only Python, imports **none** of `solve.c` / `solve.py` /
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
| `--jobs N` *(modifier)* | parallelises the records pass over N worker processes. Memory is bounded by streamed 1M-record batches (~32 MB per worker), not by file size. Output must match `--jobs 1` byte-for-byte apart from the worker-count header line — that equality is itself a check |
| `python3 verify.py --enumerate-reference N` (2≤N≤9) | small-n completeness: brute-forces the reduced N-pair problem two independent ways (exhaustive vs prune-as-you-go) and asserts identical solution sets |
| `python3 verify.py --recount` | the exact COUNTS: independently reproduces the small-n structural facts, the reduced-rung C1∩C2∩C4 union counts, **and (since 2026-07-21) the C5 ladder rungs n = 9/13/16** (TR-11 §4b) — each rung's budget `B0` re-derived independently by TR-11 §5's first-completion DFS, then counted by a plain budgeted (mask, last, p) DP — and prints a match table |
| `python3 verify.py --recount-fiber` | (added 2026-08-01) the **orientation fiber** of [TR-1](../reports/TR1_EIGHT_CENTURIES_MEASURED.md) §7 — the frozen dispositive null against which the eleven-functional battery's exact p-values are computed, so it is the denominator every verdict in that table rests on. A transfer DP over King Wen's *own* pair sequence, varying only the 32 within-pair orientations, with the boundary budget `B0` recomputed from KW rather than copied from the report. Reproduces **1,720,320** (C4-oriented), **983,040** (pair-only C4, flipped opening), **2,703,360** (their sum), the stated `3·5·7·2¹⁴` factorization, and the forced/free bit structure (slot 30 is the only additionally forced bit — 30 of 31 vary). Two facts make this exact rather than a 2³¹ search, and the mode re-derives both instead of assuming them: within-pair distances are orientation-invariant, so C5 reduces to the 31 between-pair values; and `C3 = 16 + 8·G` with the orientation bits cancelling in `G`, so C3 is **constant** across the fiber and constrains nothing. Instant. Reads no files |
| `python3 verify.py --fiber-sweep [solutions.bin]` | (added 2026-08-01) the **orientation-fiber factor** — the exact conversion between the two counting levels this suite publishes side by side: deduped **records** (pair orderings, what `solutions.bin` stores) and orientation-explicit **sequences** (what the C1–C5 space estimate counts). `--recount-fiber` above answers TR-1 §7's question for King Wen's *own* ordering; this mode generalises the same object to an **arbitrary** C1 ordering, which is what makes the two levels inter-convertible: `N = Σ_P |fiber(P)|`, `R = #{P : |fiber(P)| ≥ 1}`, and the dedup factor is exactly the mean fiber `N/R`. Gated on King Wen's three published fiber sizes **and** on agreement with `--recount-fiber`'s independent DP before it reports anything; then, if a `solutions.bin` is present, prints the exact fiber-size distribution over its records. ~0.2 ms per ordering. Scope: the sample mean is over the records of the file given, which is a budget-truncated slice, **not** the C1–C5 space |
| `python3 verify.py --check-repr [N]` / `--check-repr-offset R` | (added 2026-08-15) the **repr(k) oracle** — independently recomputes the canonical representative for `N` records starting at record `R` (defaults: 1000 from 0) and compares it against what the artifact stores. **Why it is needed:** `solve.c`'s `--kc-repr-normalize` states outright that "there is NO separate repr oracle in this tree" — its only built-in check is IDEMPOTENCE (re-run on the output, expect byte-identical), which is self-consistent and therefore cannot catch a normalization that is stable but *wrong*. The `SOLVE_REPR_FC` A/B is weaker than it looks for the same reason at one remove: both arms share `solve.c`'s DFS, child order and code, so a defect in the shared traversal is invisible to it at any sample size. **Independence is the deliverable:** this is written from the DEFINITION in [`lean/RecordConvention.lean`](../lean/RecordConvention.lean) — repr(k) is the lexicographically least orientation completion of the pair-order key satisfying the constraint set, slot 0 forced by C4 — not transcribed from `orb_recanon_dfs`, and it builds on this file's own KW table, `_partner()`-derived pairs and `hamming()`, re-deriving and asserting the C5 budget. Reproduces **King Wen from King Wen's own key**. Verdicts are `KEY=value` (`CHECKED`/`AGREE`/`DISAGREE`/`INCOMPUTABLE`/`CHECK_REPR=PASS\|FAIL`) plus an explicit `SCOPE=` line. **Scope, stated plainly: it checks the records it reads and no others** — use several offsets rather than resampling one window, and never report a sampled pass as whole-artifact agreement. Fails closed: an *incomputable* key is a finding too, since the artifact claims a canonical record for a key this instrument says cannot be completed. Python cost is a DFS per record and the underlying search is heavy-tailed, so prefer `verify.c --check-repr` (below) for large `N` **APPLICABILITY (2026-08-15): run this against a repr-NORMALIZED artifact, not against a raw merge output. `solutions.bin` is pre-normalization — `solve --kc-repr-normalize` (task #20) has not been run on it — so a DISAGREE there is EXPECTED and identifies exactly the records the post-pass would rewrite. It is the correct acceptance test for the post-pass OUTPUT. See §'What the 2026-08-15 sweep actually found' below.** |
| `python3 verify.py --check-artifact [N]` / `--check-artifact-offset R` / `./verify --check-artifact FILE [N] [OFFSET]` | (added 2026-08-15) the **artifact validator** — checks what `solutions.bin` actually CLAIMS, in one linear pass per record: (1) **validity**, each record's OWN orientations satisfy the constraint set (forced `63->0` opening, no HD-5 transition, C5 budget consumed EXACTLY); (2) **sortedness**, pair-order keys strictly increase, matching `compare_solutions`; (3) **dedup**, strictness in (2) IS the one-record-per-canonical-class claim. `N` defaults to **-1 = to EOF** — this is a whole-artifact instrument, not a sampler, because it is linear rather than a search. **Prefer this over `--check-repr` on the merge output.** `--check-repr` cannot validate the artifact as it exists today — `solutions.bin` is pre-normalization, so its disagreements are the post-pass's work-list, not defects — and even after normalization it is *structurally blind to a wrong pair sequence* — `repr_of_key` is handed the key decoded from the very record it is compared against, so a disagreement can only ever be an orientation bit. This one checks the pair sequence directly. Verdicts are `KEY=value` (`RECORDS`, `BAD_KEY`, `BAD_SPARE_BIT`, `BAD_OPENING`, `BAD_HD5`, `BAD_BUDGET`, `BAD_BUDGET_RESIDUE`, `BAD_ORDER`, `ARTIFACT=PASS\|FAIL`) plus `SCOPE=`. **Requires a `ROAE` header and refuses without one** (`ARTIFACT=FAIL_no_ROAE_header`): a headerless raw `sub_*.bin` shard would otherwise have its FIRST RECORD silently consumed as a header, and the checker could then report `PASS` on a file it never fully read — the same failure mode as the recon off-by-one this repo already carries a fix for. It fails closed rather than auto-detecting, because this tool validates the *merged* artifact and a shard should be an explicit refusal, not a silent reinterpretation. **Does NOT check completeness** — that no valid solution is *missing* is the enumeration's claim, attested by the canonical sha; a forward pass cannot establish it. Sharding caveat: the sortedness check compares against the predecessor WITHIN the range read, so a sharded run cannot see a violation across a shard seam — overlap by one record, or run offset 0 to EOF |
| `python3 verify.py --check-shen-orbits` / `--check-flips` | (added 2026-08-15) two **reproduction commands for figures published in [CITATIONS.md](CITATIONS.md) and in this file**, because a private script does not make a public number reproducible. `--check-shen-orbits` verifies that Shen Youding's 1936 six groups of principal hexagrams are **exactly the six K₄ orbits** of his sixteen (sizes 2,2,2,2,4,4) — his criterion, equal generational rank of inner and outer trigram, is **KW-independent**, and this checks a CLASSIFICATION, not an ordering claim. It is independent of `solve.c`'s orbit code by construction: the claim is *about* orbit structure, so a check that used that code would not be independent. `--check-flips` prints the census of the 31 single-orientation-bit flips of King Wen's own record by failure mode (**9 PASS / 15 `BAD_BUDGET` / 7 `BAD_HD5`**), which exists because the figure first shipped as "16" — the measuring harness grepped `^BAD_[A-Z_]+=[1-9]`, a character class that excludes DIGITS, so `BAD_HD5` never matched. Both read **no files** |
| `python3 verify.py --check-kw-pair-adjacency` | (added 2026-08-16) **reproduction command for a classical fact and for a NEGATIVE result.** Re-verifies that King Wen seats every hexagram beside its own partner — 32 pairs, **28 by reversal, 4 by complement**, zero unrelated, zero hexagrams whose partner is not adjacent. **That rule is not ours and not new**: it is 非覆即變, stated by Kong Yingda 孔穎達 (574–648) with earlier lineage via Yu Fan 虞翻 — see [CITATIONS.md#kongyingda](CITATIONS.md#kongyingda). The command exists so a reader can confirm the premise without taking anyone's word for it. It then draws the consequence for excavated evidence: the head/tail symbols of the Shanghai Museum Chu bamboo *Zhouyi* ([Pu Maozuo 2003](CITATIONS.md#pu2003)) **cannot distinguish** "the symbol respects reversal" — Pu's claim, which holds **9 testable pairs / 9 agreements / 0 disagreements** on his directly-observed symbols — from "the symbol is merely constant on contiguous King Wen blocks", because blocks and orbits coincide by construction of the sequence. It reports `SHANGBO_DISCRIMINATING_PAIRS=0`. **An impossibility argument, not a criticism of his reading, and not a failed search.** Reads **no files** |
| `python3 verify.py --check-classical-groups` | (added 2026-08-16) **the group actions the CLASSICAL literature attests, and how King Wen scores against each — none of the rivals are ours.** Sources: **⟨comp,rev⟩** and **⟨rev,swap⟩** both from 吳澄 Wu Cheng (1249–1333) 《易纂言外翼》卷一〈卦對第二〉 ([#wucheng](CITATIONS.md#wucheng)); **⟨comp,swap⟩** from 焦循 Jiao Xun (1763–1820) 《易圖略》八卦相錯圖 ([#jiaoxun](CITATIONS.md#jiaoxun)). **The result:** ⟨comp,swap⟩ has the *identical* orbit profile to ⟨comp,rev⟩ — 20 orbits, 8×2 + 12×4 — yet King Wen seats partners adjacently **64/64** under ⟨comp,rev⟩ and only **24/64** under ⟨comp,swap⟩. At the sharper pairing-rule level: reversal-with-complement-fallback (= C1, 非覆即變) scores **64/64**, every alternative tested scores 12–16/64, and **20,000 random involutions with the same structure reach a best of 12/64 and never 64**. So a structurally indistinguishable rival, drawn from the same tradition, does not fit — the choice is a property of the sequence, not an artifact of looking for symmetry. Also re-derives 吳澄's own 「共十八對」 as a reading check (24 orbits − 6 meeting the 八純卦 = 18 ✓). **Scope: this is about PAIRING. It changes no enumeration and no published count.** Reads **no files** |
| `python3 verify.py --recount-gender-null` | (added 2026-08-01) TR-8 §Commands' **exact pair-null Schulz-gender figure** `P(rc4_violations ≤ 2) = 47/445740`. Both prior implementations of this rational lived inside `solve.py`, so the figure was single-FILE even though it was described as verified two ways; this is the genuinely independent second instrument. The functional is rebuilt from the **published** definition (SOLVE_C_CLI.md §`--rc4b-verify`; Schulz 1990 motif 2 via Cook 2006) rather than from `solve.py`'s code, and the reading is gated on King Wen's published anchors (2 violations, class positions 25/26). The 32!·2³² null is then solved **exactly two ways** — a multivariate-hypergeometric closed form, and a slot-by-slot DP over pair-type states that never uses the closed form's decomposition — cross-asserted term-by-term, in `fractions.Fraction`. No sampling. Instant. Reads no files |
| `python3 verify.py --recount-rung N` | (N = 18 or 19) the **worker-sized C5 ladder rungs** — a packed-state budgeted DP, self-gated against the in-file plain DP at n=16. Larger rungs (n = 20–28) need a worker and are not run here |
| `python3 verify.py --recount-subtree` | the exact **deterministic subtree anchors** of TR-5 §3 / SEARCH_SPACE_SIZE (KW-following prefixes at 5/7/9 free positions: `tree_nodes` 443 / 62,256 / 9,422,793 and canonical leaves 4 / 2,232 / 16,504), plus the sigma-related-prefix tree-isomorphism check. ~1–2 min. Reads no files |
| `python3 verify.py --check-c2-shift [N]` | the **C2 conditioning shift** on the C3 tail by importance-weighted Monte-Carlo: `P(C3 ≤ 776 | C1∩C2∩C4) ≈ 8.9%` (95% CI [8.5%, 9.2%]) against the exact 8.106% C1&C4 null. A measured estimate with a CI, not an exact count — cited in [SPECIFICATION.md](SPECIFICATION.md) §C3 |
| `python3 verify.py --check-null-g --unpinned` | the same exact G-law **without the C4 start pin**, giving `C3\|C1 = 6.4211367496%` exactly — the figure [SPECIFICATION.md](SPECIFICATION.md) and [SOLVE_SUMMARY.md](SOLVE_SUMMARY.md) both cite. `--unpinned` is a modifier on `--check-null-g`, not a mode of its own |
| `python3 verify.py --check-certificate DIR` | a completed f1c5 run's ARTIFACTS (run.out per-layer certificate rows, manifest, preserved digests) against structural identities and independently derived quantities. Recomputes **nothing** — internal-consistency and digest-integrity only, per its docstring |
| `./verify --check-layers DIR [max_k] [run.out]` | (C side, NEW 2026-07-23; orbit-weighted mass added same day) the **on-disk layer files themselves**, read against [F1C5_LAYER_FORMAT.md](F1C5_LAYER_FORMAT.md) with no `solve.c` code: header/`pl_hash`/`b0` vs the manifest, `masks`/`off` layout, per mask popcount/range/**canonicity** (numeric minimum of its orbit), and per entry the key packing, `rid < R`, ascending order, nonzero value, and the **sum invariant** (rid mixed-radix digits sum to `k`). With the TR-11 §2 group **derived independently in-file** (the 48 `C_{S6}(rev)` bit-perms → 24 induced pair-permutations → the run's distinct restricted perms, closure-verified), it re-derives the §Reading-recipe **orbit-weighted mass** `Σᵢ sᵢ·(|G|/|stab(maskᵢ)|)` from the layer bytes at **every** layer and, when a `run.out` is given, compares it to `solve.c`'s reported `mass=` per layer — the full-scale counterpart of the small-`k` plain-DP mass check. Entry-streaming and `O(nm)` memory, so it reaches every layer on disk — and at the final layer (full-31) the summed value bytes must equal the published 39-digit count and be `≡ 0 (mod 24)`. Handles v1 (raw) and v2 (per-block zlib). `--check-layers-selftest` synthesizes v1+v2 fixtures, a corrupted case, a **non-trivial-stabilizer** mass fixture (pair-orbit `3.0`, `|stab|=2`, orbit `3 < |G|=6`), a wrong-reported-mass case, and a non-canonical-mask case — no real data needed. **Campaign-VM tool** (run where the layers live). |
| `./verify --check-g-ladder FDIR GDIR [max_k]` | (C side, NEW 2026-07-24) the **g-ladder layer files** (`--kc-g-build` artifacts: exact count-from-any-prefix, the rank instrument's substrate), read against [GT_LADDER_FORMAT.md](GT_LADDER_FORMAT.md) with no `solve.c` code. Structural: `F1C5GLY1/2` magic+version, `g_manifest_v1`, header fields, v1/v2 file-size formulas, layout, mask **canonicity**, per-entry key packing / ascending order / `rid < R` / **sum invariant** / nonzero values, the **stored-domain rule** (`last` in the mask's pair-element set), and the exact **seed** (2n sorted pair elements, `rid = R−1`, all values 1) and **anchor** (layer 0 = `g(0)`) content. Identity: the **f·g cut identity** — `Σ orbit(mask)·f(s)·g(s) = N` at **every** layer, with `N` re-derived from the f ladder's final-layer value bytes (and, at full-31, checked against the published count). An independent implementation of the same gate `solve.c --kc-g-check` asserts — a true second instrument for the g ladder. **Campaign-VM tool** |
| `./verify --check-t-ladder FDIR TDIR [max_k]` | (C side, NEW 2026-07-24) the **t-ladder layer files** (`--kc-t-build` artifacts: exact search-tree node counts, `t(s) = 1 + Σ_c t(s∘c)`), against [GT_LADDER_FORMAT.md](GT_LADDER_FORMAT.md). Structural: `F1C5TLY1/2` magic, `t_manifest_v1`, **byte-exact f-geometry mirror** (masks/off/keys identical to the f layer at every `k`), every value ≥ 1, seed layer all 1s, anchor singleton. Identity: `M_j` (orbit-weighted f masses = exact # valid depth-`j` prefixes) re-derived from the f ladder's bytes, `M_0 = 1`, then the **f·t node identity** `Σ orbit·f·t = Σ_{j≥k} M_j` at **every** layer (the backward recurrence unfolded, `S_k = S_{k+1} + M_k`) plus `t(root) = Σ M_j`. The independent counterpart of `solve.c --kc-t-check`. `--check-gt-selftest` covers both modes: it brute-forces a complete, consistent f+g+t fixture from the published definitions on a **non-trivial instance** (the 6-pair orbit `{10,15,20,23,27,29}`, transitive restricted group `geff=6`, budget spanning 3 classes incl. `d=6`, **252 dead-end states**, anchors `N=96` / `t(root)=1285` cross-derived by an independent Python implementation), round-trips v1 and v2, and asserts five corruption legs FAIL (g value tamper, t value tamper, t geometry tamper, g/t magic confusion, g seed tamper) — no real data needed |
| `./verify --knuth-anchors` | (C side, NEW 2026-08-08, task #194) the **clean-room Knuth prober's validation gate** — run it before trusting any `--knuth-probe` run. Structural checks (partner-exact KW pairing; within-pair {2:12,4:12,6:8} + KW boundary multiset == the C5 literal; 8 self-complement pairs / 12 cross complement-couples, [lean/C3Decomposition.lean](../lean/C3Decomposition.lean)'s counts; the SPECIFICATION.md C6/C7 pin sets {29,46}/{9,36}/{11,52}/{13,44} == KW pairs 24–27; `c3x64(KW) = 776 = 16 + 8·95`), then exhaustive DFS below KW-following prefixes gated on the **published exact subtree anchors** (SEARCH_SPACE_SIZE §Validation / TR-5 §3: 5-free 443 nodes / 4 canonical, 7-free 62,256 / 2,232, 9-free 9,422,793 / 16,504, and exactly **8** of the 16,504 satisfying C6/C7) with the spec-vs-Lean C3 identity asserted at every one of the ~696K complete leaves, and finally a fixed-seed probe run on the 9-free prefix that must match the exact counts within 4σ of its own Wald CI (exercises the weighting/RNG path the exact DFS never runs). ~2 s. Reads no files |
| `./verify --knuth-probe N [--knuth-seed S] [--knuth-threads T] [--knuth-no-c67] [--knuth-free F]` | (C side, NEW 2026-08-08, task #194; pre-registered gate in the private repo before first run) the **clean-room Knuth (1975) random-probe estimator** — a second, independent instrument on the published `solve.c --estimate-knuth` estimate \|C1∩C2∩C3∩C4∩C5∩C6∩C7\| ≈ 5.21×10³¹, whose one uncorroborated full-scale factor is the **C3 conditional ratio (~0.101)** (every existing full-scale cross-check is C3-free by scope). Own C3 predicate — computed BOTH ways at every complete leaf, the SPECIFICATION.md positional sum and the Lean slot decomposition `16 + 8·G`, cross-asserted — and own C6/C7 pin logic (pinned pairs excluded from non-pinned slots, which removes only zero-leaf subtrees, so the walk tree differs from `solve.c`'s but the leaf estimands are unbiased for the same targets). Default estimates the C6/C7-pinned targets; `--knuth-no-c67` the C1–C5 space; `--knuth-free F` probes the KW (32−F)-slot prefix subtree (validation aid). Reports canonical + no-C3 + tree-node estimates with Wald CIs, the seed, and a free calibration: the no-C3 leaf estimand is compared against this file's own **exact** Route B/D constants (5.16880…×10³² pinned / 1.097051…×10³⁹ unpinned). splitmix64 RNG, per-thread disjoint 2⁴⁰-draw segments; modulo child-selection bias < d/2⁶⁴ ≈ 4×10⁻¹⁸, negligible. Reads no files |
| `python3 verify.py --check-null-g` | the **reference distribution for C3**: the exact G-distribution under the C1&C4 null (12 cross-couples + 7 self-pairs into 31 slots), gated against `total == 31!`, support `[12,228]`, `E[G] == 128` (also true DP-free by linearity, since `E\|i−j\| = (n+1)/3` for a uniform 2-subset of `{1..n}`), and `P(G ≤ 95) == 641983711307479/7919632354008375`. Since `C3 = 16 + 8·G`, this is the baseline any "KW's C3 is unusual" claim must beat. Accumulates **open-couple counts, not ± slot indices** — deliberately different arithmetic from `solve.c`'s G channel, so agreement is evidence rather than tautology. **Scope: C1&C4 only** — no C2, no C5, no budget truncation; not like-for-like against ceiling-tie shares measured over conditioned enumerated populations. Reads no files |
| `python3 verify.py --t3-stats DIR` | (added 2026-08-11) two of the three pre-registered validity statistics of the **T3 exact-uniform draw sample** — (a) uniformity of the rank stream (χ² over 16 equal buckets, bucket = ⌊16·r/N⌋, 15 dof, **PASS below 37.70**) and (c) the C3 fraction at `cd ≤ 387` against `p₀ = 1/8.26 = 0.12107`, **flagged beyond 4σ** either direction. Both bars are frozen in the pre-registration (private repo, `PREREG_F_CATALOG_T1_T4_2026_08_06.md` §3, committed **before** the first recorded draw) and neither may be adjusted to make a result land — a breach quarantines the sample. `N = \|C1∩C2∩C4∩C5\| = 1,097,051,278,789,181,790,036,112,071,176,579,186,688` (TR-11 §9). Statistic (b) is deliberately **not** restated here; run `--t3-membership`. DIR is a directory of `t3_stream_*.out[.gz]`, or one such file. **Input is not in this repo** — see §"Analyses over large artifacts" for the generating command and its measured cost. Analysis itself: **≈22.9 MB peak RSS** for 10⁶ draws (reproducible across 7 runs); wall is a few seconds but is load-dependent and is **not** a reproducible figure — see §"Analyses over large artifacts" |
| `python3 verify.py --t3-membership PATH [--t3-membership-limit N]` | (added 2026-08-11) the third pre-registered statistic, (b) **membership**: every emitted walk must satisfy C1∩C2∩C4∩C5. Bar **100%** — a single failure is a first-order finding. This is the *second language* for that check, so its value is that it shares no code with the sampler: the predicates are transcribed from [SPECIFICATION.md](SPECIFICATION.md) §C1/C2/C4/C5 and it uses only `verify.py`'s own rule-derived helpers (`_partner`, `hamming`, `compute_comp_dist`), all gated at import against the spec literals. Before reporting anything it (i) self-tests the transcription (partner is an involution; exactly 8 self-reverse hexagrams; `partner(63) = 0`; the C5 target sums to 63; `compute_comp_dist(KW) = 776`; King Wen itself is accepted) and (ii) runs a **positive control per constraint** — each control breaks exactly one of C1/C2/C4/C5 and the run aborts unless that constraint's own predicate fires, which is what separates a working checker from one that says MEMBER to everything. Two checks beyond the prereg: the engine-recorded `cd=` is independently recomputed (`cd = compute_comp_dist(S)/2 − 1`, the −1 being the C4-pinned `(63,0)` pair), and duplicates are detected. `--t3-membership-limit 1000` on one stream reproduces exactly the pre-registered spot-check leg in a fraction of a second. Full census: **≈149 MB peak RSS** for 10⁶ draws, the one figure that reproduced across every measurement condition; wall ranged **60–98 s** depending on what else the box was doing and is **not** a reproducible figure — see §"Analyses over large artifacts", which records two successive wrong answers about it |
| `python3 verify.py --g-structure C2ON_LOG C2OFF_LOG` | (added 2026-08-11) structure of the **full-31 G distribution** from two enumerator logs carrying `G_HIST` lines — C2-ON (C1&C2&C4) and C2-OFF (C1&C4). Re-derives the moments as exact rationals, checks every bin is divisible by 48, and on the C2-OFF side runs the sharp identities: `G_HIST_WSUM == 128 · G_HIST_TOTAL` exactly, and `P(G ≤ 95)` equal **as a rational** to the closed-form null `641983711307479/7919632354008375` — the same constant `--check-null-g` derives from scratch, so this is a cross-instrument agreement rather than a restatement. Then a convolution test (`q^(1/m)` coefficient tails for 14 values of m) showing no `m` truncates, i.e. G is **not** an independent-sum statistic — consistent with a permutation statistic (sampling without replacement). **Scope:** this says nothing about prefix-G g48-invariance; a quotiented run cannot test the assumption its own quotient makes. Analysis is instant and reads only the logs; producing them is not — see §"Analyses over large artifacts" |
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
| `--t3-stats`, `--t3-membership` | the T3 exact-uniform draw sample: 16 streams × 62,500 draws = 10⁶ draws (~107 MB gzipped) | one KC-sampler invocation per stream — arguments `--kc-sample <f-dir> 62500 <seed> --kc-record --kc-ooc --kc-cache-mb 384`, with `SOLVE_F1_OOC_READ_MB=1`, against the Stage F **f-ladder**. **Not on `main`:** see the branch note below the table | **≈12.6 h wall** on one D16als_v7 (16 lanes, Premium P50 f-disk) against a **3.1 TB** f-ladder — plus building the branch that carries the sampler. Seed-deterministic: the same seeds, f-ladder and binary regenerate the same draws |
| `--g-structure` | two full-31 enumerator logs carrying `G_HIST` bin lines — one C2-ON (base C1∩C2∩C4), one C2-OFF (base C1∩C4) | two full-31 `solve --f1-c3-hist --f1-pairs 31 --f1-out-of-core DIR` runs, the C2-OFF one adding `--no-c2` (all on `main`; see [SOLVE_C_CLI.md](SOLVE_C_CLI.md) §`--f1-c3-hist`) | **23,054 s** (C2-ON) and **39,003 s** (C2-OFF) on 128 threads — see the cost caveat below the table |

**Branch note (T3 sampler).** The `--kc-*` subcommands are **not on `main`**.
They live in `solve.c` on the published branch `v4-compiler`, which
[BRANCH_REGISTRY.tsv](BRANCH_REGISTRY.tsv) classes as a *snapshot* — a frozen
working branch, not the authoritative corpus, and not something to cite for
claims. Regenerating the T3 sample therefore costs a checkout and build of that
branch on top of the ~12.6 h of compute. The arguments above are deliberately
written **without** a `solve` prefix: an invocation form would assert that the
command runs against this ref's binary, and it does not.

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

**Result: every quantity with a published target reproduced EXACTLY, 0 mismatch**
(rerun `python3 verify.py --recount` to regenerate the full table; exit 0 requires
every published target to match). Peak RSS ~24 MB for the tables above; wall time
dominated by the 63 M-leaf U1 backtracking and the n = 16 budgeted DP.

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
*`verify.py` is stdlib-only and imports no project code — run `python3 verify.py
--recount` to regenerate the match table. `verify.c` builds with `cc -O2 -o
verify verify.c -lz -lpthread` and reads a run's `run.out`. Developed with AI assistance
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
`solve --kc-repr-normalize IN.bin OUT.bin` (task #20), and that pass has not
been run on it. The disagreeing records **are** the post-pass's work-list. So
`--check-repr` is the right acceptance test for the post-pass *output* and is
expected to fail on its *input*; running it on a raw merge is a category error,
not a finding.

> **⚠ NOT AVAILABLE IN THIS TREE.** `--kc-repr-normalize`, `orb_normalize_rec_op`, `orb_repr_global`
> and `orb_recanon` do **not** exist in `main`'s `solve.c` — zero occurrences. They live on an
> **unlanded** v4 branch that `BRANCH_REGISTRY.tsv` marks *snapshot — do not cite*. A reader of
> `main` cannot run this pass. Relatedly, the `--check-repr` row's quotation *"there is NO separate
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

### Controls (a positive plus seven negatives; all pass)

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

`BAD_BUDGET_RESIDUE` has **no control because none is possible**: the budget totals
63 and a complete record consumes exactly `1 + 31*2 = 63`, so a record whose every
decrement succeeded has zero residue by arithmetic. It is retained as a fail-closed
guard against a future table change, and is documented as unreachable rather than
claimed as tested.
