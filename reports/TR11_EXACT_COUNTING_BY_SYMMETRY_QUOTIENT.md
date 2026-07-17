# TR-11 — Exact Counting by Symmetry Quotient: The Orbit-DP, a 42-Digit Integer, and the Exactness Program
*Technical report — **v1.0** (first public release, 2026-07-16; operator review completed and publication approved).*
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
exactly. The same run recalibrated the project's statistical estimator against ground truth at a scale
(10⁴¹) where nothing exact existed before: the estimate was off by 0.0055%, half its claimed error bar.
The report closes with the extension of exactness to the next constraint — mathematically solved, and
now engineered: the computation's terabyte-scale layers (measured: one layer alone exceeds 2.45 TB) are
streamed through disk by an out-of-core mode, so the full exact count runs on ~64 GB-RAM commodity
hardware plus ~4 TB of disk. That run has now **completed** (2026-07-16): the exact integer is
**1,097,051,278,789,181,790,036,112,071,176,579,186,688 ≈ 1.097×10³⁹** (§9) — divisible by 24 exactly,
and within 0.0044% of the prior statistical estimate. The final constraint (C3) poses an open structural
obstruction.

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
mathematically closed — an exact dead-state-pruning theorem plus a proof that no further state collapse
exists — and now engineered: measured per-layer footprints reach >2.45 TB for a single layer, refuting
in-RAM execution on any single purchasable machine, and an out-of-core mode (`--f1-out-of-core`,
2026-07-05) replaces the RAM requirement with ~4 TB of streamed layer files, validated 4/4 exactly
against the in-RAM path on independent hardware; the full-scale count **landed 2026-07-16 at
1,097,051,278,789,181,790,036,112,071,176,579,186,688 ≈ 1.097051×10³⁹**, divisible by 24 exactly and
0.999956× the Knuth estimate), and the honest limits (the flagship 1.3287×10³⁸ remains an estimate;
C3's global sum is an open obstruction).

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
   — prefix stabilizers exist and require standard orbit-DP bookkeeping.
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
     stated ±0.01%) deviates from the exact value by **5.5×10⁻⁵** (ratio 0.999945) — about half its
     stated envelope, the estimator's first validation against full-scale ground truth (previously
     nothing exact existed above brute-force scale on TR-4's ladder). This upgrades TR-9's C2 ledger
     row from estimate to exact arithmetic (C2's marginal 4.6 bits and net +1.6 now rest on an exact
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
   the minimal exact storage of any forward scheme is the live set itself. Measured on group-closed
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
   combinatorial-bound estimate; the realized footprints are §6's table.) **Status: mathematics closed;
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
   that line under its pre-committed abort protocol. **No single purchasable machine suffices**: the
   largest single-node RAM class used (2.75 TB) plus terabyte-scale swap still lost to layer 15's tail.
   The multi-terabyte-RAM route is not merely expensive; it is empirically dead at full scale — the
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
   `14db3f5`; D128als_v7 Spot, westus3, 4 TB disk — the earlier c228/c231/c235 attempts were retired and
   this was a from-scratch re-run launched 2026-07-09, ~7 days wall spanning 12 Spot evictions, every one
   auto-recovered from the last complete layer checkpoint with no lost work). The result:
   **|C1∩C2∩C4∩C5| = 1,097,051,278,789,181,790,036,112,071,176,579,186,688 ≈ 1.097051×10³⁹**
   (log₂ ≈ 129.7 bits; orientation-explicit sequences, C4's pair pinned). Free-action gate:
   **N mod 24 = 0** exactly (the run hard-aborts otherwise; a reader can re-derive it in one line), with
   orbit count **N/24 = 45,710,469,949,549,241,251,504,669,632,357,466,112**. Ratio to the pre-existing
   Knuth estimate (1.0971×10³⁹): **0.999956** — the estimate was accurate to 0.0044%, a second absolute
   full-scale calibration (after §4's C2 anchor) at the 10³⁹ scale where nothing exact previously
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
   a statistical estimate**, exactly as TR-4 states; this report does not change its status. (ii) Even
   with the C5 layer computed exactly, **C3 is a further, open obstruction**: it constrains a *global*
   positional-distance sum between complement partners, which the pair-level (mask, last, residual)
   state does not carry; no feasible exact design for it is in hand. The C5-layer count
   (formerly estimator-based at 1.0971×10³⁹) is now **computed exactly** (§9, landed 2026-07-16,
   1.097051×10³⁹) and is carried as exact downstream; everything below it (C3 and the flagship) stays
   estimator-based.
   (iii) The absolute calibration point is a single full-scale anchor; it is strong evidence the stated
   envelopes are honest, not a proof that other estimates are exact. (iv) The FH-1 §2 proofs are
   believed complete but have not been independently reviewed. (The companion caveat in earlier drafts —
   that §5's memory projections were estimates, not measurements — is discharged: §6 replaced them with
   measurements, which exceeded the projected band; the caveat's firing is itself documented in §5/§6.)
   (v) The exact count is orientation-explicit with C4's pair pinned, matching the ledger's raw
   convention (baseline 64!, C1+C4 layer 31!·2³¹); comparisons against orientation-deduplicated record
   counts must divide conventions carefully. (vi) The identical-integer two-memory-strategy validation
   (§8) currently extends to 28 pairs; at full 31 the in-RAM path is infeasible (§6), so the full-31
   integer will initially rest on a single instrument — the out-of-core mode — supported by the mod-24
   gate, the 4/4 ladder equivalence, and byte-identical layer files at every validated scale, not on an
   independent full-scale recomputation.

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
