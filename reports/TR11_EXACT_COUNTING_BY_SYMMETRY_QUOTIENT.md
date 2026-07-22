# TR-11 — Exact Counting by Symmetry Quotient: The Orbit-DP, a 42-Digit Integer, and the Exactness Program
*Technical report — **v1.8** (2026-07-21; §5 full-31 B0-coincidence claim CORRECTED — found by the independent instruments — see Revision history).*
*Technical report — not peer-reviewed. Every claim is machine-verifiable; see the Verification Guide.*

Methods, environment pinning, statistics conventions, and artifact access: see [METHODS.md](METHODS.md).

## Executive summary

Almost every large number in this project is one of two kinds: an exact count from an exhaustive
enumeration (which can only ever cover a slice of the space), or a statistical estimate with an error
bar. This report documents the instrument that produced the suite's first number of a third kind: an
**exact count at full scale**. The number of hexagram orderings that keep the classical pairing, start
with the traditional first pair, and avoid the forbidden "distance-5" adjacency is **exactly
757,058,601,340,255,440,651,419,713,405,330,315,358,208** — a 42-digit integer, computed to the last
digit in about four minutes. The computation is only feasible because of the symmetry theorem of
[TR-5](TR5_SYMMETRY.md): the space's 24-fold symmetry shrinks the computation ~23× — small enough to fit
in memory — and the theorem then predicts, and the result confirms, that the integer is divisible by 24
exactly. The same run gave the project's statistical estimator its first full-scale check against ground truth
at a scale (10⁴¹) where nothing exact existed before: the exact value falls **inside** the estimate's
stated ±0.01% envelope. (The estimate was published to four significant figures, so its exact deviation
is unmeasured at that precision — bounded well within the envelope, not resolved to it; see §9's note.)
The report closes with the extension of exactness to the next constraint — its mathematics believed complete (one half now machine-checked in Lean, the other prose-proven and unreviewed), and
now engineered: the computation's terabyte-scale layers (measured: one layer alone exceeds 2.45 TB) are
streamed through disk by an out-of-core mode, so the full exact count runs on ~64 GB-RAM commodity
hardware plus ~4 TB of disk. That run has now **completed** (2026-07-16): the exact integer is
**1,097,051,278,789,181,790,036,112,071,176,579,186,688 ≈ 1.097×10³⁹** (§9) — divisible by 24 exactly,
and within 0.0044% of the prior statistical estimate. The final constraint (C3) is, as of this
version, no longer described as a structural obstruction: its global sum collapses to a bounded
scalar (**C3 = 16 + 8·G**, a machine-checked identity — see §10(ii)), so a bounded-state exact
design exists; what keeps the flagship |C1–C5| an estimate is the ~35–60× cost of carrying that
channel alongside C5's state, not missing mathematics.

## Abstract

We document the symmetry-quotient dynamic program (`solve --f1-exact-c1c2c4`) that computed the exact
cardinality **|C1∩C2∩C4| = 757,058,601,340,255,440,651,419,713,405,330,315,358,208 ≈ 7.5706×10⁴¹**
(log₂ = 139.12 bits; orientation-explicit sequences; 2026-07-04, 259 s wall on 64 cores) — to our
knowledge the project's first exact full-scale constrained count, and the third counting modality in the
suite alongside exhaustive enumeration (exact lower bounds; [TR-3](TR3_REPRODUCIBLE_ENUMERATION.md)) and
Knuth estimation (unbiased ±CI; [TR-4](TR4_SIZE_OF_THE_SPACE.md)). The naive pair-level DP is
memory-infeasible (6.66×10¹⁰ states; 149–447 GB peak even layered). TR-5's free-action theorem makes it
feasible: the record-level symmetry group S₄ (order 24) acts on the DP state space, DP values are
constant on orbits, and storing only canonical masks collapses 2³¹ masks to 93,939,712 (22.86×) — peak
memory drops into the tens of GB. The theorem simultaneously supplies an arithmetic gate: the action on
complete sequences is free, so the count must be ≡ 0 (mod 24); it is, exactly, on a 42-digit integer.
The exact value validates the Knuth estimator absolutely at full scale (stated 7.571×10⁴¹ ±0.01%;
deviation 5.5×10⁻⁵) and converts [TR-9](TR9_PRICING_THE_CONSTRAINTS.md)'s C2 ledger row from estimate to
exact arithmetic. We state the validation stack, the exactness frontier (the C5-tracked extension is
mathematically **believed complete** — an exact dead-state-pruning theorem (machine-checked in Lean as `capping_exact`, 2026-07-20) plus a prose proof, not independently reviewed, that no further state collapse
exists — and now engineered: measured per-layer footprints reach >2.45 TB for a single layer — beyond the in-RAM reach of the
machine classes this project provisioned (up to 2.75 TB RAM + 3.55 TB striped swap; larger single
nodes exist commercially but were not economically sensible here) — and an out-of-core mode (`--f1-out-of-core`,
2026-07-05) replaces the RAM requirement with ~4 TB of streamed layer files, validated 4/4 exactly
against the in-RAM path on independent hardware; the full-scale count **landed 2026-07-16 at
1,097,051,278,789,181,790,036,112,071,176,579,186,688 ≈ 1.097051×10³⁹**, divisible by 24 exactly and
0.999956× the Knuth estimate), and the honest limits (the flagship 1.3287×10³⁸ remains an estimate;
C3's global sum — formerly stated here as an open obstruction — collapses to the bounded scalar
identity C3 = 16 + 8·G, leaving a ~35–60× cost barrier rather than a structural one; §10(ii)).

*Novelty status: symmetry-quotiented counting is classical methodology (Burnside/orbit counting;
canonical-representative and isomorph-free generation techniques in the tradition of McKay); no novelty
is claimed for the technique. The contribution documented here is its instantiation for the King Wen
constraint system and the exactness tier it adds to this suite. We are not aware of a prior exact count
of this quantity; corrections welcome via [CITATIONS.md](../documentation/CITATIONS.md).*

## Sections

1. **The counting problem, and why the naive DP is infeasible.** The target is |C1∩C2∩C4|: complete
   64-hexagram sequences built from the 32 classical pairs (C1), with no Hamming-distance-5 adjacent
   transition (C2), opening with the fixed pair (Qian, Kun) in forced orientation (C4). C1 makes a
   pair-level formulation exact: place whole pairs with an orientation bit; C1 fixes the 32 within-pair
   distances (12×d2, 12×d4, 8×d6 — never 5), so checking C2 only at the 31 pair boundaries enforces full
   C2; C4 costs nothing in state — it pins the DP's initial condition (virtual predecessor exiting at
   Kun) and removes pair 0 from the free set. The exact recursion is a bitmask DP over states
   (used-pair-mask, last-exit-hexagram): 31·2³¹ + 1 = 66,571,993,089 states and ≈2.0×10¹² edge
   evaluations. Ops are cheap (~hours in C); **memory binds**: values reach ~7.6×10⁴¹ > 2¹²⁸, so ~150-bit
   integers are required, and even the best layered variant (layer = mask popcount, two live layers,
   dense combinatorial ranking) peaks at 1.86×10¹⁰ entries — 447 GB at 24 B/value single-pass, or 149 GB
   at 8 B/value × 3 CRT passes. This is what killed the route when first formulated (the "F1 no-go");
   the recursion itself was validated 3/3 against brute-force enumeration on reduced 8-pair instances.
2. **The free-action theorem → the 24× collapse.** TR-5 proves the C1–C5-preserving symmetry group: 48
   bit-position permutations (the centralizer of `rev` in S₆), acting at record level as **S₄ (order
   24)**, and — the load-bearing part — acting **freely** on complete valid sequences: no non-identity
   element fixes any solution, so every orbit has exactly 24 members and any symmetry-closed count is
   exactly 24 × (orbit count). Two distinct consequences power this report. *Feasibility:* the group is
   a Hamming isometry that permutes the 32 pairs (pair 0 fixed setwise), so it acts on DP states and DP
   values are constant on orbits — the computation may store one representative per orbit. *Arithmetic
   gate:* the count N must satisfy N ≡ 0 (mod 24) — a zero-compute integrity check any reader can apply,
   and one that (per the cross-suite observation) already certifies that every published *budgeted*
   canonical is not symmetry-closed (e.g. 10,525,271,997 ≡ 21 mod 24). One caution the implementation
   must respect: the action on complete sequences is free, but the action on *masks/prefixes* is **not**
   — prefix stabilizers exist and require standard orbit-DP bookkeeping. **That bookkeeping is now
   machine-checked at the model level** (2026-07-21): the transfer theorem **never assumes freeness**, so
   the non-free mask action costs nothing — no orbit weight ever enters a DP *value* — and the per-layer
   stabilizer weighting is exact orbit–stabilizer, proved division-free as `multiplicity × |stab| = |G|`
   (`orbit_transfer_exact`, `orbit_stabilizer_mult`, `stabilizer_weighted_mass` in `lean/PruneExactness.lean`
   §OrbitTransfer, **on the public `v4-canonical` branch**; core Lean 4, 0 `sorry`, kernel-`decide`).
   **Scope:** this is a model-level result. DP-reachability facts are hypotheses and the bridge to the C
   implementation remains prose plus the runtime gates — exactly the discipline `capping_exact` follows.
   It does **not** verify `solve.c`, and it does not bear on §10(vi)'s instrument question.
3. **The layered orbit-DP over canonical masks.** The implementation (`solve --f1-exact-c1c2c4`,
   argv-dispatched and sha-neutral — zero interaction with enumeration paths) proceeds layer by layer in
   mask popcount k = 0..31, storing only **canonical masks** (minimum image over the 24 pair-permutations):
   93,939,712 canonical masks in place of 2³¹ = 2,147,483,648 (22.86×); state entries collapse from
   6.66×10¹⁰ to 2.91×10⁹, with the two-live-layer peak (k = 16, 17) at ~8.1×10⁸ entries — tens of GB
   instead of hundreds. Exactness is carried by a **gather formulation**: the stored value at a canonical
   mask is the *exact plain-DP forward value* at that representative — each new-layer canonical mask
   pulls from its canonicalized predecessors, mapping the stored `last` hexagram through the inverse
   group element; no weights ever enter the values. Stabilizer weights (orbit size = n/|stab|) appear
   only in a per-layer total-mass identity checked against the plain DP in subset mode; the full mask is
   G-fixed (orbit size 1), so the final total needs no correction. Counts are hand-rolled add-only
   **192-bit unsigned integers** (the magnitude exceeds 2¹²⁷; the no-third-party-dependencies rule
   excludes GMP), run in a single pass — no CRT needed at this layer (the 8 B × 3-CRT-pass design remains
   the sizing basis for the larger C5-tracked extension, §5). Each completed layer checkpoints
   atomically (tmp + rename + fsync, with a manifest); a re-run with the same `--layers-dir` resumes
   from the last complete layer — the same eviction-safe discipline as the enumeration campaigns. The
   full run: **259 s wall on 64 cores**, final integer printed exactly.
4. **The validation stack.** Layered, in the suite's two-language tradition:
   - *Recursion ground truth:* the pair-level recursion validated 3/3 against brute-force enumeration
     on 8-pair reduced instances (both Kun- and Qian-seeded).
   - *Orbit machinery ground truth:* the Python orbit-DP prototype validated 3/3 exactly (big-integer
     equality plus per-layer mass identities) against the plain recursion on group-closed pair-orbit
     unions — U1 (9 pairs: 63,366,144), U2 (12 pairs: 1,961,990,553,600 = 12!·2¹², a union with no
     internal d=5 prunes — a known-closed-form check), U3 (13 pairs: 39,239,811,072,000).
   - *C port gates:* the C implementation mirrors the prototype's group construction, canonicalization,
     gather formulation, and stabilizer handling exactly; in `--f1-subset` mode a plain layered DP runs
     alongside and both the totals and every layer mass must match exactly (printed PASS/FAIL). All
     gates green at commit; standard selftest anchor unchanged (sha-neutrality).
   - *Reduced-instance oracle discipline:* as everywhere in the suite, nothing ran at full scale before
     exact agreement on reduced instances against an independent oracle (brute force, then plain DP) —
     the same gate pattern specified for any future orbit-reduced enumeration lineage.
   - *The arithmetic gate on ground truth:* the run **aborts** unless N ≡ 0 (mod 24); the result is
     divisible exactly — remainder zero on a 42-digit integer — confirming the free-action theorem's
     signature on ground truth (orbit count N/24 = 31,544,108,389,177,310,027,142,488,058,555,429,806,592).
   - *Absolute estimator calibration:* the pre-existing Knuth estimate of the same quantity (7.571×10⁴¹,
     stated ±0.01%) is confirmed to contain the exact value inside its envelope — the estimator's first
     validation against full-scale ground truth (previously nothing exact existed above brute-force scale
     on TR-4's ladder). The apparent 5.5×10⁻⁵ gap is the distance from the exact value to the estimate's
     own four-significant-figure rounding, not a measurement of the estimator's error, which is unresolved
     at the published precision but bounded well within ±0.01%. This upgrades TR-9's C2 ledger
     row from estimate to exact arithmetic (C2's marginal 4.54 bits and net +1.6 now rest on an exact
     numerator).
5. **The exactness frontier: C5, the irreducibility theorem, and the staged program.** The next layer,
   |C1∩C2∩C4∩C5| (C5 = KW's transition-distance multiset), adds a residual-budget dimension to the
   state. Since C1 fixes the within-pair distances, C5 reduces to a budget on the 31 boundary
   transitions, B0 = (2, 8, 13, 7, 1) over d = (1,2,3,4,6) — 6,048 budget vectors rather than the naive
   whole-walk 176,400, and a sum invariant (Σr = remaining transitions) makes each vector live in
   exactly one layer (≤413 coexist). Two results close the mathematics (working notes: FH-1):
   *capping the residual at the per-class achievable range is proven **exact** dead-state pruning*
   (states outside the box count zero on both sides), and — the negative that matters — a **complete
   characterization of future-equivalence**: two distinct residuals at the same state are
   future-equivalent **iff both are dead**. There is *no residual lumping available among live states*;
   the minimal exact storage of any **residual-lumping** forward scheme is the live set itself. (Narrowed
   on independent review, 2026-07-21: what is proven is that no residual equivalence-classing at a fixed
   state can merge live states — not an information-theoretic storage bound over *every* conceivable
   forward encoding, which value-deduplication or algebraic compression would sit outside.) Measured on group-closed
   reduced unions, realistic (KW-like, balanced) budgets collapse only 1.2–1.4× at the wide layers —
   the hoped-for 10–50× collapse is refuted. Projection at 31 pairs: peak two-live-layer storage
   **≈1.2–2.0 TB** (12 B/entry under 3×64-bit CRT passes; theoretical perfect-pruning floor ≈1.0–1.4 TB),
   with edge ops ~10¹³ per pass — beyond the memory of the hardware classes used to date. The
   implementation exists and is committed (`solve --f1-exact-c1c2c4c5`, with `--f1-pairs N` selecting
   group-closed pair-orbit unions, N ∈ {9,13,16,18,19,24,25,27,28,31}) and mirrors an exactly-validated
   Python instrument; the staged measurement program — reduced-pair runs of increasing size to measure
   the true peak-memory curve before any full-scale attempt — ran on 2026-07-04/05 and produced the
   measured profile of §6. (Projection caveat, as originally stated: the stored-fraction band 0.30–0.50
   was extrapolated from n = 16–18 unions and n = 31 could sit outside it. **The caveat fired**:
   entries-per-state growth at full scale exceeded the models — layer 15 alone ran 55%+ over its
   combinatorial-bound estimate; the realized footprints are §6's table.) **Status: mathematics believed complete — the dead-state-pruning exactness theorem is now machine-checked in Lean at the **model level** (`capping_exact`, `lean/PruneExactness.lean` on the public `v4-canonical` branch, 0 sorry, 2026-07-20 — the DP-reachability premises are hypotheses in the Lean statement and the bridge to the C implementation is carried by prose + the runtime gates, per that file's header), while the companion no-further-collapse argument remains prose-proven and gate-validated but not independently reviewed (§10(iv));
   the memory barrier is removed by the out-of-core mode (§7); the full-scale run LANDED 2026-07-16 (§9).**
6. **What the computation actually needs — the measured per-layer footprint profile.** The 2026-07-04/05
   full-scale attempts (an in-RAM run on a 2.75 TB-RAM M-series machine with 3.55 TB of striped swap,
   and the out-of-core run's telemetry/manifest) replaced §5's projections with measurements. Per-layer
   state footprint (entries × 28 B; layer k = mask popcount k of 31):

   | Layer k | Footprint | Provenance |
   |---|---|---|
   | 9 | 41 GB | measured |
   | 10 | 126.6 GB (4,522,319,129 entries) | measured |
   | 11 | 316 GB | measured |
   | 12 | ≈656 GB | derived (971.6 GB two-live-layer telemetry − L11's 316 GB) |
   | 13 | 1.14 TB | measured |
   | 14 | 1.6 TB | measured |
   | 15 | >2.45 TB | observed-incomplete (in-RAM run retired mid-layer) |

   Layers ≥16 shrink again (the canonical-mask count follows C(31,k)) but were never reached in RAM;
   the out-of-core manifest will complete the profile for every layer. Two consequences. *First*, the
   forward DP holds two adjacent layers live, so the in-RAM peak is at least L14 + L15 > 4.05 TB before
   overheads — layer 15 alone grew past 2.45 TB, 55%+ over the combinatorial-bound estimate
   (entries-per-state growth at full scale exceeded all models), and the in-RAM attempt was retired at
   that line under its pre-committed abort protocol. **No machine class this project provisioned sufficed**: the
   largest single-node RAM class used (2.75 TB) plus terabyte-scale swap still lost to layer 15's tail.
   (Larger single nodes — 6-24 TiB — exist commercially; what is established here is that the
   multi-terabyte route was empirically dead at the price points this project could justify, not that
   no such machine exists.) The in-RAM route at this scale is not merely expensive — the
   out-of-core mode was not the fallback, it was the answer. *Second*, the table is the report's answer
   to "what does this computation need": ~64 GB of RAM and ~4 TB of disk (§7), because at most two
   adjacent layers need exist at once and neither needs to be in memory.
7. **The out-of-core mode (`--f1-out-of-core DIR`) and the reproducibility claim.** Public commits
   01bf3ef + dbdfb0e add an out-of-core execution mode to the same DP — identical mathematics, different
   storage strategy. Design: (i) completed layers are written to DIR as the **same atomic per-layer
   checkpoint files** `--layers-dir` uses (tmp + rename + fsync + manifest; the two modes' layer files
   are **byte-identical**, itself a cross-mode gate) and freed from RAM; (ii) the next layer's gather
   **streams** the previous layer's file via bucketed, position-sorted, coalesced sequential reads
   (chunked targets, multi-MB windows, adjacent spans merged below a gap threshold — no per-entry random
   file access); (iii) the layer being *built* is **chunk-streamed back to disk** as it is emitted
   (bounded staging buffer; keys pwritten at their final offsets, values to a sidecar relocated at
   finalize), so **no layer's entries ever reside in RAM in full** — peak RSS is bounded by fixed
   streaming buffers plus the two live layers' 12 B/mask indexes, independent of layer size; (iv) layer
   k−1 is dropped before building k+1, so peak disk is ≈ two adjacent layers; (v) every completed layer
   file is a **free checkpoint**: `--resume-from-layers` does an index-only load and resumes from the
   last complete layer — Spot-safe by construction, the same eviction discipline as the enumeration
   campaigns. Exactness is invariant across modes: per-entry arithmetic is the shared
   `f1c5_gather_entries` kernel that the in-RAM path calls, so totals *and* layer files match
   byte-for-byte. Tuning knobs: `SOLVE_F1_OOC_READ_MB` / `SOLVE_F1_OOC_SCRATCH_MB` /
   `SOLVE_F1_OOC_GAP_KB`, with per-layer `[f1c5-ooc]` telemetry (bytes read/written, MB/s, RSS). **The
   reproducibility claim this establishes**: the full exact |C1∩C2∩C4∩C5| count runs end-to-end on
   commodity hardware — **~64 GB of RAM plus ~4 TB of disk** (the in-flight full-scale run uses a
   32-core/64 GiB VM with a 4 TB scratch stripe) — replacing the multi-terabyte-RAM requirement that
   §5's projections implied and §6's measurements confirmed no single machine can meet.
8. **Out-of-core validation, and the engineering history (limitations and mitigations).** In the
   suite's tradition, the mode's credibility rests on exact cross-instrument agreement plus an honest
   account of what broke and how the fix was proven.
   - *Commit-time cross-mode gates:* out-of-core totals equal in-RAM totals at 13 pairs
     (2,063,395,607,040), 16 pairs (267,765,117,419,520), and 19 pairs (63,244,766,587,981,824), with
     layer files and manifests byte-identical across modes, per-layer states/entries/mass lines
     field-identical, and a deliberately stressed small-buffer configuration (multi-chunk, hundreds of
     windows per layer) still identical; `kill -9` mid-run at 16 pairs → `--resume-from-layers` →
     identical total and byte-identical layer files; `--selftest` sha unchanged (sha-neutral,
     argv-dispatched, zero interaction with enumeration paths).
   - *The Spot validation ladder (4/4 exact):* on independently provisioned Spot hardware in a
     different region from the full-scale run (~$1.10 total), the out-of-core mode reproduced the
     recorded in-RAM values **digit-for-digit** at four group-closed subset sizes, including one rung
     deliberately killed mid-run and completed through `--resume-from-layers`:
     24 pairs = **7,477,248,378,538,061,907,099,648**;
     25 pairs = **83,855,263,774,549,546,015,506,432**;
     27 pairs = **61,666,352,085,618,532,666,071,318,528**;
     28 pairs = **2,155,118,806,480,613,893,163,229,118,464**.
     (Reference values from the 2026-07-04 in-RAM runs; the 28-pair in-RAM reference itself peaked at
     87.1 GB RSS — the out-of-core rung reproduced its integer within a bounded-RSS budget on a small
     VM.) Records: this repo's program ledger (UPDATE 41) and the retained run outputs.
   - *Limitation found and fixed — the full-scale OOM:* the first out-of-core build (01bf3ef) streamed
     the *gather* but accumulated the layer being *built* in realloc-grown RAM arrays. At full scale,
     layer 10 is 4,522,319,129 entries × 28 B = 126.6 GB against 64 GiB of RAM: the run was OOM-killed
     ~155 s into the layer-10 build at MaxRSS 61.6 GiB. Detection was itself non-trivial: GNU time
     appends a trailing "Exit status: 0" field even for signal deaths, so the kill initially read as a
     silent clean exit; the true cause was read directly off the still-running VM ("Command terminated
     by signal 9"). Before the fix was designed, a 32-bit-overflow hypothesis was ruled out by auditing
     every entry-count/offset/window variable (by eye and via `gcc -Wconversion -Wsign-conversion`):
     all 64-bit. The mitigation (dbdfb0e) is the chunk-streamed emission of §7(iii), with the
     OOM-prone growth path deleted entirely; the proof was run **at the breaking layer**: rebuilding
     full-scale layer 10 post-fix held RSS **flat at 1.48 GB** where the pre-fix build died at 61.6 GiB.
   - *Limitation measured and tuned — read amplification:* the windowed gather re-reads the predecessor
     layer once per streaming pass; at the initial scratch budget the full-scale gather amplified reads
     **22.8×** across 494K windows. Raising `SOLVE_F1_OOC_SCRATCH_MB` to 61440 (fewer, larger passes)
     cut amplification to **~1.1×**. This is a throughput property only — window count and buffer sizes
     cannot affect the totals (same kernel, byte-identical layer files), a fact the stressed-buffer
     gate above checks directly.
9. **The full-scale exact count — LANDED (2026-07-16).** The full-31 run completed on 2026-07-16 on the
   retooled solver (gzip'd layers + intra-layer checkpointing, merged to `main` 2026-07-09 commit
   `14db3f5`; D128als_v7 Spot, westus3, 4 TB disk (the run's first ~3 hours were on a D64 before a same-disk
   migration to the D128 — layer-checkpoint resume is shape-independent by design, and the migration
   preceded every layer that reached the final artifact's retained state) — the earlier c228/c231/c235 attempts were retired and
   this was a from-scratch re-run launched 2026-07-09, ~7 days wall spanning 12 Spot evictions, every one
   auto-recovered from the last complete layer checkpoint with no lost work). The result:
   **|C1∩C2∩C4∩C5| = 1,097,051,278,789,181,790,036,112,071,176,579,186,688 ≈ 1.097051×10³⁹**
   (log₂ ≈ 129.7 bits; orientation-explicit sequences, C4's pair pinned). Free-action gate:
   **N mod 24 = 0** exactly (the run hard-aborts otherwise; a reader can re-derive it in one line), with
   orbit count **N/24 = 45,710,469,949,549,241,251,504,669,632,357,466,112**. Ratio to the pre-existing
   Knuth estimate (1.0971×10³⁹): **0.999956** — the exact value again falls inside the estimate's stated
   ±0.01% envelope, a second full-scale validation (after §4's C2 anchor) at the 10³⁹ scale where nothing
   exact previously (the 0.0044% figure is the estimate's five-sig-fig rounding gap, not a resolved error)
   existed. Per-layer canonical-mask integrity: every printed layer matched the Burnside palindrome
   masks(k) = masks(31−k) — terminal tail k23..k31 = 369,823 · 128,414 · 38,262 · 9,707 · 2,087 · 378 ·
   56 · 7 · 1; peak k15 = k16 = 13,047,760 — and the six palindrome pairs recoverable from the retained
   run log (k10..k21 through k15..k16) all hold exactly. The retained `run.out` (final eviction-resume
   session) carries only prints k10..k31 — the k0..k9 prints scrolled out on resume — but the full
   32-layer table reconstructs by the palindrome (k0..k9 = mirror of k22..k31) and **its total is
   confirmed independently: Σ masks(k) over k = 0..31 = 93,939,712, exactly the known canonical-mask
   count (§3)** — so the reconstructed k0..k9 values are pinned, not merely assumed (and those layers were
   also integrity-checked live during the campaign). **This integer passed operator review
   (2026-07-16) and is published with this report; the downstream ledgers ([TR-9](TR9_PRICING_THE_CONSTRAINTS.md),
   [TR-4](TR4_SIZE_OF_THE_SPACE.md), and their documentation mirrors) now carry it as exact.**
10. **Honest limits — what stays estimated, and why.** (i) The flagship **1.3287×10³⁸ (|C1–C5|) remains
   a statistical estimate**, exactly as TR-4 states; this report does not change its status. (ii)
   **Corrected in this version (v1.5): C3 is a cost barrier, not a structural obstruction.** Through
   v1.4 this item read "C3 is a further, open obstruction … no feasible exact design for it is in
   hand." That was inaccurate. C3's global positional-distance sum between complement partners —
   Σ_v |pos(v) − pos(v̄)| over all 64 hexagrams, v̄ = v ⊕ 63 — **collapses to a bounded scalar**.
   Complement commutes with reversal, so it maps C1-pairs to C1-pairs: 8 of the 32 pairs are
   complement-closed (each contributes exactly 2 — its two members are adjacent, and the sum runs
   over all 64 hexagrams, so each such pair counts twice), and the remaining 24 pairs split into 12
   complement-**couples** {P, P′}; each couple's four hexagram-level distances collapse to
   8·|slot(P) − slot(P′)| — independent of both pairs' orientations (the orientation bits cancel).
   Hence the identity **C3 = 16 + 8·G**, where **G = Σ over the 12 couples of |slot(P) − slot(P′)|**
   (slot = the pair's index 0–31 in the pair order — exactly the DP's layer trajectory). G is bounded
   — G ∈ [12, 228] with C4's (Qian, Kun) pair, itself complement-closed, pinned at slot 0 — the
   constraint threshold translates exactly (**C3 ≤ 776 ⟺ G ≤ 95**), and King Wen sits **on the
   boundary** (G = 95). Verification status, stated precisely: the identity is a **machine-checked
   theorem, universal over every C1-valid ordering** — `c3_slot_decomposition` in this repo's
   [`lean/C3Decomposition.lean`](../lean/C3Decomposition.lean) (core Lean 4, 0 `sorry`, 2026-07-04,
   originally proved as the soundness core of `sat.py`'s C3 CNF encoding), with King Wen's G = 95
   also Lean-checked (`kw_slot_sum_95`); it was numerically re-confirmed 2026-07-21 by two
   independent implementations on thousands of random C1 orderings (3,000 + 2,000, exact agreement)
   plus an independent reproduction. G is additionally invariant under TR-5's 48-element group —
   each element maps the 12 couples to couples — machine-checked exhaustively over all 48 elements,
   both numerically and in Lean (`g48_couples_to_couples` + `g48_couple_image`, same file, kernel
   `decide` over the full group, 2026-07-21), so §§2–3's symmetry quotient carries over to a
   G-channel unchanged. The identity itself has been in this repo since 2026-07-04; what is new on 2026-07-21
   is the recognition that it dissolves the exact-counting obstruction this section previously
   asserted (identity and its counting consequence by Claude, this project; outside this project we
   are not aware of a prior statement of the identity, or of any bounded-invariant collapse of the
   complement-position-distance sum over King-Wen-type orderings — it may well be known, and
   corrections are welcome via [CITATIONS.md](../documentation/CITATIONS.md)). The consequence: a
   bounded-state exact design for C3 **does exist** — carry the running G (a channel ~96 wide under
   the C3 ≤ 776, i.e. G ≤ 95, filter) alongside the (mask, last, residual) state on the same
   symmetry-quotient DP. What remains is **cost, not design**: carrying the G-distribution alongside
   C5's budget vectors multiplies the DP footprint an estimated ~35–60× — order 40–190 TB of
   streamed layers and weeks of wall time, outside this project's budget — so the flagship |C1–C5|
   **remains a statistical estimate**, now for stated economic rather than structural reasons. Two
   things do become affordable: an exact **|C1∩C2∩C3∩C4|** rung (C3 without C5), at roughly the
   landed C5 run's scale; and **E[C3] over any ensemble this DP computes is free by linearity of
   expectation** (E[C3] = 16 + 8·E[G] — a single scalar accumulator, no distribution carried). The
   C5-layer count (formerly estimator-based at 1.0971×10³⁹) is now **computed exactly** (§9, landed
   2026-07-16, 1.097051×10³⁹) and is carried as exact downstream; everything below it (the C3 layer
   and the flagship) stays estimator-based.
   (iii) The absolute calibration point is a single full-scale anchor; it is strong evidence the stated
   envelopes are honest, not a proof that other estimates are exact. (iv) **The FH-1 §2 proofs have now been
   independently reviewed (2026-07-21) and found sound**, and the no-further-collapse Proposition and its
   capping corollary are additionally **machine-checked in Lean** (`no_live_lumping`,
   `cap_never_merges_live`, `lean/PruneExactness.lean` on the public `v4-canonical` branch, 0 `sorry`) —
   with the DP-reachability facts carried as hypotheses and the bridge to the C implementation still
   carried by prose + the runtime gates, exactly as for `capping_exact`. Two results of that review are
   recorded here rather than buried: one statement is **narrowed** — "no further collapse" rules out
   residual equivalence-classing among live states, not every conceivable storage encoding (§5, amended);
   and the Proposition is **not load-bearing for the landed integer** — the production DP merges no live
   states at all (residuals are injectively packed), so the count's correctness rests on the
   already-machine-checked capping-exactness alone, and a hole in the Proposition could only ever have
   cost a memory optimization, never a digit. (The companion caveat in earlier drafts —
   that §5's memory projections were estimates, not measurements — is discharged: §6 replaced them with
   measurements, which exceeded the projected band; the caveat's firing is itself documented in §5/§6.)
   (v) The exact count is orientation-explicit with C4's pair pinned, matching the ledger's raw
   convention (baseline 64!, C1+C4 layer 31!·2³¹); comparisons against orientation-deduplicated record
   counts must divide conventions carefully. (vi) The identical-integer two-memory-strategy validation
   (§8) currently extends to 28 pairs; at full 31 the in-RAM path is infeasible (§6), so the full-31
   integer will initially rest on a single instrument — the out-of-core mode — supported by the mod-24
   gate, the 4/4 ladder equivalence, and byte-identical layer files at every validated scale, not on an
   independent full-scale recomputation. **Update (2026-07-21) — the *mathematical* half of this caveat is
   now closed, at zero compute; the *instrument* half is not.** The orbit-transfer argument (the gather
   formulation with its inverse-element `last` mapping, computing exact plain-DP values at canonical
   representatives, together with the stabilizer-weighted mass identity that the runtime gate checks) is
   machine-checked in Lean at the **model level** — `orbit_transfer_exact`, `orbit_stabilizer_mult`,
   `stabilizer_weighted_mass`, `lean/PruneExactness.lean` §OrbitTransfer, **on the public `v4-canonical`
   branch**, 0 `sorry`. **This does not verify the implementation.** Reachability facts remain hypotheses;
   the bridge to `solve.c` is still carried by prose, the runtime gates, and the n ≤ 28 plain-vs-quotient
   agreement — specifically it is not machine-checked that `f1_gather_layer`/`f1c5_gather_entries`
   implement that recursion, that the concrete 24 pair-permutations satisfy the hypothesis set, that
   `f1_canon`'s min-image canonicalization is orbit-constant, or that the C5 residual coordinate is
   G-fixed. **What (vi) still asserts, unchanged, is the instrument point: the full-31 integer rests on a
   single instrument, and an independent full-scale recomputation has not been performed.**

## Verification Guide

- Exact count (full run): `./solve --f1-exact-c1c2c4` — ~4 minutes on 64 cores; prints the exact
  integer, N/24, and the ratio to the Knuth estimate; hard-aborts unless N ≡ 0 (mod 24). Spot-safe
  resume: add `--layers-dir DIR`. Timing probe: `SOLVE_F1_MAX_LAYER=K` (partial, no total).
- Divisibility gate, reader-side: reduce 757,058,601,340,255,440,651,419,713,405,330,315,358,208
  mod 24 (one line in any big-integer language; = 0).
- Internal cross-check gates: `./solve --f1-exact-c1c2c4 --f1-subset U1` (also U2, U3, or generic
  `"L.I,L.I,...[@START]"`) — runs the orbit-DP and a plain layered DP side by side; totals and
  per-layer masses must print PASS.
- C5-tracked extension + staged memory measurement: `./solve --f1-exact-c1c2c4c5 --f1-pairs N`
  (N ∈ {9,13,16,18,19,24,25,27,28,31}; per-layer stderr reports states/entries/bytes/peak).
- Full exact count on commodity hardware: `./solve --f1-exact-c1c2c4c5 --f1-out-of-core DIR` — ~64 GB
  RAM + ~4 TB disk at DIR; raise `SOLVE_F1_OOC_SCRATCH_MB` (e.g. 61440 on a 64 GiB box) to hold read
  amplification near 1× (§8). Every completed layer file in DIR is a checkpoint; after any interruption,
  re-run with `--resume-from-layers` (index-only load, resumes from the last complete layer). Per-layer
  `[f1c5-ooc]` telemetry prints bytes read/written, MB/s, and RSS. Knobs: `SOLVE_F1_OOC_READ_MB` /
  `SOLVE_F1_OOC_SCRATCH_MB` / `SOLVE_F1_OOC_GAP_KB` (documentation/SOLVE_C_CLI.md).
- Cross-mode equivalence, reader-side: run any `--f1-pairs N` subset both with and without
  `--f1-out-of-core` — totals must match exactly and the layer files must be byte-identical
  (`sha256sum` them); §8's ladder integers (24/25/27/28 pairs) are the recorded reference values.
- Divisibility gate on the full-31 count, reader-side: reduce
  1,097,051,278,789,181,790,036,112,071,176,579,186,688 mod 24 (one line in any big-integer language;
  = 0; orbit count = that ÷ 24 = 45,710,469,949,549,241,251,504,669,632,357,466,112).
- Free-action theorem and group: [TR-5](TR5_SYMMETRY.md) (proof, Lean kernel checks, tree isomorphism);
  documentation/SYMMETRY_SEARCH.md.
- Estimator calibration and exactness notes: documentation/SEARCH_SPACE_SIZE.md §"Absolute validation
  against an exact count"; documentation/DESCRIPTION_LENGTH.md (ledger row + exactness note).
- Working notes (roae-private, publication relocation TBD per METHODS artifact-access policy):
  F1_PHASE3_RECONSTRUCTION.md (recursion + state math), F1_ORBIT_QUOTIENT_2026_07.md (quotient design +
  prototype validation), FH1_RESIDUAL_DOMINANCE.md (capping exactness + irreducibility + projections),
  scripts/f1_evidence/ (Python prototypes).
- Independence-ladder rung ([METHODS.md](METHODS.md)): rung 3 (instrument stack, two-language
  cross-validated), with the mod-24 gate itself sitting at rung 1 (reader arithmetic, no project code).

### Reproducing the reduced-rung counts (independently recomputable)

The full-scale exact counts are validated against a ladder of **reduced instances**: the same DP
restricted to a subset of King Wen's 31 free pairs. For each reduced instance to be independently
recomputable, three things must be public: (1) the pairing itself (which hexagrams form each pair), (2)
the symmetry group that defines the "group-closed" subsets, and (3) the exact pair membership of each
rung with its expected count. All three are below; a reader can rebuild each instance and recompute its
count with any big-integer DP — no project code required. (The subset-spec grammar these tables use is
the same one `solve.c` accepts via `--f1-subset` / `--f1-pairs`; the C5 ladder specs are its public
`f1c5_unions[]` table.)

**1. The 32 King Wen pairs (index → hexagram values).**
Hexagrams are 6-bit integers, bit 0 = bottom line ([OEIS A102241](https://oeis.org/A102241) convention).
Pair `i` is `(KW[2i], KW[2i+1])`. Pair 0 = {Qian(63), Kun(0)} is fixed by C4 and by the whole group; the
31 **free** pairs are indices 1–31.

| pair | (a, b) | pair | (a, b) | pair | (a, b) | pair | (a, b) |
|---|---|---|---|---|---|---|---|
| 0 | (63, 0) | 8 | (25, 38) | 16 | (60, 15) | 24 | (29, 46) |
| 1 | (17, 34) | 9 | (3, 48) | 17 | (40, 5) | 25 | (9, 36) |
| 2 | (23, 58) | 10 | (41, 37) | 18 | (53, 43) | 26 | (52, 11) |
| 3 | (2, 16) | 11 | (32, 1) | 19 | (20, 10) | 27 | (13, 44) |
| 4 | (55, 59) | 12 | (57, 39) | 20 | (35, 49) | 28 | (54, 27) |
| 5 | (7, 56) | 13 | (33, 30) | 21 | (31, 62) | 29 | (50, 19) |
| 6 | (61, 47) | 14 | (18, 45) | 22 | (24, 6) | 30 | (51, 12) |
| 7 | (4, 8) | 15 | (28, 14) | 23 | (26, 22) | 31 | (21, 42) |

**2. The symmetry group (defines "group-closed").**
Let reversal be the bit-position permutation `rev = (0 5)(1 4)(2 3)` (top↔bottom line flip). Acting on a
6-bit hexagram `h`, a position-permutation `g ∈ S₆` sends bit `i` of `h` to position `g(i)`. The relevant
group is

- **G = C_{S₆}(rev)**, the centralizer of `rev` in `S₆` — the 48 position-permutations that commute with
  reversal (isomorphic to the octahedral group B₃ ≅ Z₂ ≀ S₃). Every `g ∈ G` is a Hamming isometry, fixes
  {0, 63} setwise, and permutes the 32-pair set. This is exactly the C1–C5 automorphism group proved in
  [TR-5](TR5_SYMMETRY.md).
- Its action **on pairs** factors through the kernel {id, rev} (both fix every pair setwise), giving a
  group of **24 distinct pair-permutations ≅ S₄** acting on the 31 free pairs (pair 0 fixed). A subset of
  pairs is **group-closed** iff it is a union of orbits under these 24 pair-permutations.

A reader reconstructs the 24 pair-permutations directly: enumerate the 48 `g ∈ S₆` commuting with `rev`,
map each to its induced permutation of the 32 pairs, and dedup (kernel {id, rev}).

**3. The pair-orbit partition of the 31 free pairs.**
Under the 24 pair-permutations the 31 free pairs split into **7 orbits** (sizes 3, 3, 3, 4, 6, 6, 6). The
label `L.I` = the `I`-th orbit (0-based) of size `L`, in sorted order — the same grammar `--f1-subset`
accepts:

| label | size | pair indices |
|---|---|---|
| `3.0` | 3 | {3, 7, 11} |
| `3.1` | 3 | {4, 6, 21} |
| `3.2` | 3 | {13, 14, 30} |
| `4.0` | 4 | {5, 8, 26, 31} |
| `6.0` | 6 | {1, 9, 17, 19, 22, 25} |
| `6.1` | 6 | {2, 12, 16, 18, 24, 28} |
| `6.2` | 6 | {10, 15, 20, 23, 27, 29} |

Every reduced rung below is a union of whole rows of this table (hence group-closed). `@START` records
the DP's fixed exit hexagram (Kun = 0 or Qian = 63); it must be a G-fixed value.

**4a. The C1∩C2∩C4 validation unions (orbit-quotient prototype).**
Counts are `|C1 ∩ C2 ∩ C4|` restricted to the union (no C5 tracking):

| name | orbit spec | pairs | pair indices | expected exact count |
|---|---|---|---|---|
| U1 | `3.0,3.1,3.2@0` | 9 | {3,4,6,7,11,13,14,21,30} | 63,366,144 |
| U2 | `6.0,6.1@0` | 12 | {1,2,9,12,16,17,18,19,22,24,25,28} | 1,961,990,553,600 (= 12!·2¹²) |
| U3 | `3.0,4.0,6.2@63` | 13 | {3,5,7,8,10,11,15,20,23,26,27,29,31} | 39,239,811,072,000 |

**4b. The C1∩C2∩C4∩C5 out-of-core ladder (`solve.c` `f1c5_unions`).**
Counts are `|C1 ∩ C2 ∩ C4 ∩ C5|` restricted to the union, all with `@0` (Kun exit). These are the rungs
the out-of-core mode reproduced digit-for-digit against the in-RAM DP (§8):

| pairs | orbit spec | pair list **in spec order** (order is load-bearing — see below) | target `B0` = (d1,d2,d3,d4,d6) | expected exact count |
|---|---|---|---|---|
| 9  | `3.0,3.1,3.2@0`        | 3,7,11, 4,6,21, 13,14,30 | (2,5,0,2,0) | 26,112 |
| 13 | `3.0,4.0,6.2@0`        | 3,7,11, 5,8,26,31, 10,15,20,23,27,29 | (1,6,0,6,0) | 2,063,395,607,040 |
| 16 | `4.0,6.0,6.1@0`        | 5,8,26,31, 1,9,17,19,22,25, 2,12,16,18,24,28 | (1,8,1,6,0) | 267,765,117,419,520 |
| 18 | `6.0,6.1,6.2@0`        | 1,9,17,19,22,25, 2,12,16,18,24,28, 10,15,20,23,27,29 | (0,7,1,10,0) | (in-RAM reference) |
| 19 | `3.0,4.0,6.0,6.1@0`    | 3,7,11, 5,8,26,31, 1,9,17,19,22,25, 2,12,16,18,24,28 | (2,11,0,6,0) | 63,244,766,587,981,824 |
| 24 | `3.0,3.1,6.0,6.1,6.2@0`| 3,7,11, 4,6,21, 1,9,17,19,22,25, 2,12,16,18,24,28, 10,15,20,23,27,29 | (1,10,2,11,0) | 7,477,248,378,538,061,907,099,648 |
| 25 | `3.0,4.0,6.0,6.1,6.2@0`| 3,7,11, 5,8,26,31, 1,9,17,19,22,25, 2,12,16,18,24,28, 10,15,20,23,27,29 | (2,11,1,11,0) | 83,855,263,774,549,546,015,506,432 |
| 27 | `3.0,3.1,3.2,6.0,6.1,6.2@0` | 3,7,11, 4,6,21, 13,14,30, 1,9,17,19,22,25, 2,12,16,18,24,28, 10,15,20,23,27,29 | (2,12,1,12,0) | 61,666,352,085,618,532,666,071,318,528 |
| 28 | `3.0,3.1,4.0,6.0,6.1,6.2@0` | 3,7,11, 4,6,21, 5,8,26,31, 1,9,17,19,22,25, 2,12,16,18,24,28, 10,15,20,23,27,29 | (2,12,1,13,0) | 2,155,118,806,480,613,893,163,229,118,464 |

**The pair ORDER is part of the instance definition, and the target `B0` is what C5 means on a reduced
rung.** Earlier revisions of this table published each rung as an ascending index *set* and told the
reader to keep final states whose boundary multiset was a *sub-multiset* of King Wen's `{1:2, 2:8, 3:13,
4:7, 6:1}`. Both were insufficient, and a reader following them would not have reproduced these counts
(defect found and corrected 2026-07-20, adversarial-review item F-3):

- **Order.** A rung's pair list is the concatenation of its orbit rows **in the order the spec names
  them**, each row ascending internally — e.g. `3.0,3.1,3.2` is `3,7,11, 4,6,21, 13,14,30`, **not** the
  sorted set `{3,4,6,7,11,13,14,21,30}`. Order matters because `B0` is defined by a *first-completion*
  DFS (below) that scans pairs in subset-index order: reorder the list and the witness it finds — hence
  the budget — changes. Concretely, the sorted order yields `B0 = (2,2,2,3,0)` for the n=9 rung against
  the correct `(2,5,0,2,0)`.
- **Target, not ceiling.** On a reduced rung the C5 analogue is not KW's budget nor any sub-multiset of
  it: it is the rung's own `B0`, and a completed walk must match it **exactly**. At full 31 the budget
  used is KW's own boundary multiset `(2,8,13,7,1)` — which is why the sub-multiset defect above was
  invisible at full scale.
  **Correction (2026-07-21).** An earlier revision of this bullet claimed that at full 31 the
  first-completion DFS of Step 1 and KW's boundary multiset *coincide*. **They do not.** Two independent
  implementations of the Step-1 recipe — `verify.py`'s (Python) and `verify.c`'s (C) — both return
  the witness `(2,7,13,8,1)` on the full-31 instance, against KW's `(2,8,13,7,1)`. The Step-1 recipe does
  reproduce `B0` correctly on the **reduced** rungs (`verify.py --recount` checks n = 9/13/16 exactly), so
  the error was specific to the full-31 coincidence claim, and the honest statement is: **at full 31 the
  budget is *defined* as KW's boundary multiset, not derived via Step 1.** **No published number is
  affected** — the engine uses KW's multiset, which is what every count rests on; the defect was in the
  documented derivation, not in the computation. (Found by the independent instruments themselves, the
  same way F-3 was.)

(Note the n=13 rung differs between 4a and 4b: the C1∩C2∩C4 prototype's U3 uses exit `@63`, while the C5
ladder's 13-pair rung uses `@0` — they are different reduced instances, listed with their own counts. The
n=18 "(in-RAM reference)" cell is validated against the in-RAM DP but carries no separately-printed target
here; n=9's 26,112 is the in-RAM DP's printed total, published here so the smallest rung is checkable by
hand.)

**5. How to recompute a rung independently.**
For a chosen rung take its **ordered** pair list `P` (spec order, per the table above) and exit
`START ∈ {0, 63}`. Write `d(x,y) = popcount(x ⊕ y)` and map each boundary distance to its class index in
`(1,2,3,4,6)`; distance 5 is forbidden by C2 and distance 0 cannot occur between distinct hexagrams.

*Step 1 — derive the rung's budget `B0` (deterministic first-completion DFS).* Search for the FIRST
complete C2-respecting walk over `P`, trying unplaced pairs in ascending position within `P` and, for
each, the two orientations in the order `o = 0` then `o = 1`, where `o = 0` **enters `b` and exits `a`**
and `o = 1` enters `a` and exits `b` for a pair listed `(a, b)` in the 32-pair table. Start from `last =
START`. `B0` is the class multiset of that first witness. (The witness itself is an arbitrary-but-fixed
convention; only its multiset is used, and it is achievable by construction. The published `B0` column
lets you check this step before trusting the rest.)

*Step 2 — the layered DP.* State = (subset of `P` already placed, `last` = exit hexagram of the most
recent pair, `p` = the running class-usage vector). Initialize `{(∅, START, 0): 1}`. A transition places
an unplaced pair in one orientation with boundary distance `d`, and is allowed iff `d ≠ 5` **and**
`p_class(d) < B0_class(d)` — the budget cap. The answer is the total mass on states whose subset is all
of `P` **and whose `p` equals `B0` exactly**.

Two consequences worth stating, because getting either wrong silently changes the number: the final
multiset must **equal** `B0`, not merely be dominated by it or by King Wen's `{1:2, 2:8, 3:13, 4:7, 6:1}`;
and by the sum invariant (`Σ_d p_d = k` at layer `k`) every full-subset state automatically carries
`p = B0`, so with the cap in place the equality filter is a no-op — but only with the cap in place.

Any big-integer DP reproduces the counts above; no symmetry quotient is needed to *verify* a rung (the
quotient only accelerates the full-31 run). This recipe was re-derived from this text alone, in a
clean-room implementation that shares no code with `solve.c`, and reproduces the engine's `B0` on all
nine rungs and the published counts at n = 9, n = 13 and n = 16 exactly (2026-07-20).

## Attribution

Direction, the orbit-quotient idea, and the FH-1 residual-dominance conjecture (including the capping
idea) are the operator's; the phase-3 recursion reconstruction, the sum-invariant/dead-state theory, the
Python instruments, and the solve.c implementation are by Claude (Fable 5), 2026-07-04. The out-of-core
program (§§6–9) follows the same split: direction and the reproducibility-first commitment are the
operator's; the streaming design, the OOM diagnosis, and the implementation (public commits 01bf3ef +
dbdfb0e) are by Claude (Fable 5), 2026-07-05. The underlying theorem is TR-5's. Technique-level prior
art is classical (see Novelty status above); out-of-core layered DP / external-memory streaming is
likewise classical systems methodology — no novelty is claimed for it.

## Revision history
| Version | Date | Changes |
|---|---|---|
| v1.0-draft | 2026-07-04 | Initial draft for operator review (not published; not to be cited) |
| v1.0-draft | 2026-07-05 | #221 fold-in: out-of-core mode (§7, commits 01bf3ef + dbdfb0e) + commodity-hardware reproducibility claim; 4/4 Spot validation ladder incl. kill+resume (§8); OOM/amplification engineering history as limitations-and-mitigations (§8); measured per-layer footprint table L9–L15 (§6); full-31 placeholders [COUNT]/[DIV24]/[RATIO] (§9, c228 in flight). Status unchanged: draft, operator review gates publication |
| v1.0-draft | 2026-07-16 | **Full-31 count LANDED** (2026-07-16, D128als_v7 Spot westus3, ~7 days / 12 auto-recovered evictions): §9 filled with the exact value **1,097,051,278,789,181,790,036,112,071,176,579,186,688 ≈ 1.097051×10³⁹**, N mod 24 = 0 exactly (orbit count N/24 = 45,710,469,949,549,241,251,504,669,632,357,466,112), ratio 0.999956 vs the 1.0971×10³⁹ Knuth estimate; tail-layer Burnside-palindrome integrity (6/6 recoverable pairs) + k0–k9-logging caveat recorded; in-flight/placeholder language in exec summary, abstract, §5, §10, and Verification Guide replaced with the landed value. **Landing data-fill by Claude (Opus 4.8); report body authored by Claude (Fable 5) per Attribution. Status: draft, HELD for operator review before publication — do not cite.** |
| v1.0 | 2026-07-16 | **First public release.** Operator review completed and publication approved ("do not cite" lifted); relocated from roae-private staging to public `reports/`; §9/§10 staged-for-review status language replaced with published status. No numbers change |
| v1.1 | 2026-07-17 | **Erratum (operator-approved):** §abstract/§6's "no single purchasable machine" universal narrowed to the honest measured scope (the machine classes this project provisioned — up to 2.75 TB + 3.55 TB swap — failed; 6–24 TiB single nodes exist commercially and were not tested); §9 discloses the run's first ~3 h ran on a D64 before the same-disk migration to the D128 (layer-checkpoint resume is shape-independent). Neither change affects any number or verification gate. |
| v1.2 | 2026-07-20 | **Reduced-rung reproducibility defect fixed (adversarial-review item F-3).** §4b published each rung as an ascending index *set* and §5 told the reader to retain final states whose boundary multiset was a *sub-multiset* of King Wen's `{1:2, 2:8, 3:13, 4:7, 6:1}`. Neither is the instance the engine solves: the pair list is ordered (orbit rows in spec order), and the C5 analogue on a reduced rung is that rung's own first-completion budget `B0`, matched **exactly**. A reader following the old text would not have reproduced the published counts (the sorted order alone gives `B0 = (2,2,2,3,0)` instead of `(2,5,0,2,0)` at n=9). §4b now publishes the spec-order pair list and the `B0` target for all nine rungs, §5 states the DFS convention and the exact-match rule, and n=9's total (26,112) is published so the smallest rung is hand-checkable. Verified by a clean-room reimplementation written from this text alone, sharing no code with `solve.c`: it reproduces the engine's `B0` on all nine rungs and the published counts at n=9, 13, 16. No count, theorem, or canonical value changed — the defect was in the published recipe, not in the computation |
| v1.3 | 2026-07-20 | **"Mathematics closed" softened, with one half now machine-checked (adversarial-review F-21).** The §5 status line and the abstract no longer say the C5 extension's mathematics is *closed*. Current state, stated precisely: the dead-state-pruning exactness theorem **is** now machine-checked in Lean (`capping_exact`, `lean/PruneExactness.lean` on the public `v4-canonical` branch, 0 sorry, 2026-07-20 — this is finding F-53 landing), while the companion no-further-collapse argument remains prose-proven and gate-validated but not independently reviewed (§10(iv)). The executive summary's "mathematically solved" is likewise qualified. No count, theorem statement, or canonical value changed |
| v1.4 | 2026-07-21 | **Estimator-calibration language corrected (F-20 probe).** A direct check showed the published "deviations" of the Knuth estimate from the two exact anchors (5.5×10⁻⁵ and 4.4×10⁻⁵) are exactly `(rounded estimate − exact)/exact` — the distance from each exact value to the estimate's own 4–5 significant-figure rounding, both positive only because both exact values round up. They are **not** measurements of the estimator's error, and the full-precision estimator output was never recorded. The exec summary, §4/§9 notes now state what is actually established — the exact value falls inside the estimator's stated ±0.01% envelope (a genuine validation) — and no longer claim a measured "accurate to 0.0055%/0.0044%", which overstated a rounding gap as a resolved error. Mirrors the hedge already carried in TR-4 v1.11 (F-14) and DESCRIPTION_LENGTH. No count, theorem, or envelope changed |
| v1.5 | 2026-07-21 | **C3-obstruction status corrected (§10(ii); exec summary + abstract mirrors).** The statement that C3 "poses an open structural obstruction" with "no feasible exact design in hand" is withdrawn: the C3 sum satisfies the bounded-scalar identity **C3 = 16 + 8·G** (G = the complement-couple slot-gap sum; G ∈ [12, 228]; C3 ≤ 776 ⟺ G ≤ 95; King Wen on the boundary at G = 95), G is invariant under TR-5's 48-group (machine-checked over all 48 elements, numerically and in Lean — `g48_couples_to_couples`, same file, added this version), and a bounded-state exact design therefore exists — the remaining barrier is footprint cost (~35–60× the C5 DP; est. 40–190 TB), not structure. The identity is a machine-checked Lean theorem already in this repo since 2026-07-04 (`lean/C3Decomposition.lean`, `c3_slot_decomposition`, universal over C1-valid orderings, from the SAT C3-encoding work); the 2026-07-21 contribution — by Claude, this project — is the recognition of its exact-counting consequence, the G48-invariance check, cross-implementation numeric re-verification (thousands of random C1 orderings), and the cost sizing. No external prior statement of the identity is known to us; it may be known — corrections welcome via CITATIONS.md. No count, theorem, or canonical value changed |
| v1.6 | 2026-07-21 | **§10(iv) closed: the FH-1 §2 / no-further-collapse proofs independently reviewed and machine-checked.** An independent review (2026-07-21) found the Proposition sound, and it plus its capping corollary are now Lean-checked (`no_live_lumping`, `cap_never_merges_live`, `lean/PruneExactness.lean` on the public `v4-canonical` branch, 0 `sorry`, reachability facts as hypotheses; C-bridge still prose+runtime-gates as for `capping_exact`). Two review results are recorded rather than buried: (a) **§5 narrowed** — "no further collapse" rules out residual equivalence-classing among live states, NOT an information-theoretic bound over every conceivable forward encoding, so "minimal storage of any forward scheme" now reads "any **residual-lumping** forward scheme"; and (b) the Proposition is **not load-bearing for the landed integer** — the production DP merges no live states, so correctness rests on the already-checked capping-exactness alone and a hole could only have cost a memory optimization, never a digit. Review + formalization by Claude (Fable 5); independent recompile/verification by Claude (Opus 4.8). No count, theorem statement, or canonical value changed |
| v1.7 | 2026-07-21 | **§10(vi)'s mathematical half closed (instrument half unchanged); §2 orbit-DP bookkeeping now machine-checked.** The orbit-transfer argument — the gather formulation with its inverse-element `last` mapping computing exact plain-DP values at canonical representatives, plus the stabilizer-weighted mass identity behind the runtime gate — is machine-checked in Lean at the **model level**: `orbit_transfer_exact`, `orbit_stabilizer_mult`, `stabilizer_weighted_mass` (`lean/PruneExactness.lean` §OrbitTransfer, **public `v4-canonical` branch**, core Lean 4, 0 `sorry`, kernel-`decide` throughout). Two points recorded explicitly rather than implied: the transfer theorem **never assumes freeness**, which is exactly why §2's non-free *mask* action is harmless (no orbit weight enters a value); and orbit–stabilizer is proved **division-free** (`multiplicity × |stab| = |G|`), so the implementation's `n_eff/|stab|` weight is correct *precisely when stabilizers are non-trivial*. **Scope guarded:** this does NOT verify `solve.c` — reachability facts stay hypotheses and the C bridge stays prose + runtime gates + the n ≤ 28 agreement (four named residuals listed in §10(vi)) — and it does not touch the instrument question: the full-31 integer still rests on a single instrument with no independent full-scale recomputation. Formalization by Claude (Fable 5); independent recompile/verification (exit 0, 0 sorry/axiom/admit, no `native_decide`) by Claude (Opus 4.8). No count, theorem statement, or canonical value changed |
| v1.8 *(current)* | 2026-07-21 | **§5 correction: the full-31 `B0`-coincidence claim was FALSE.** §5 asserted that at full 31 the Step-1 first-completion DFS and King Wen's boundary multiset *coincide*. They do not: two independent implementations of the Step-1 recipe — `verify.py`'s (Python) and the new `verify.c`'s (C) — both return `(2,7,13,8,1)` on the full-31 instance, against KW's `(2,8,13,7,1)` (which is also what the engine's manifest carries). Step 1 *does* reproduce `B0` correctly on the reduced rungs (`--recount` checks n=9/13/16 exactly), so the error was confined to the full-31 coincidence sentence; the honest statement is that at full 31 the budget is **defined** as KW's boundary multiset rather than derived via Step 1. **No count, theorem, or canonical value is affected** — the engine uses KW's multiset, which is what every published number rests on; the defect was in the documented derivation only. Found the same way F-3 was: by an independent instrument failing to reproduce a published recipe. Also lands `verify.c` (independent plain, non-quotient per-layer mass check against the engine's reported masses at full 31 — agrees k=1..N within memory reach) and `verify.py --check-certificate` (artifact/manifest/digest check for a completed run). Both by Claude (Opus 4.8) |
