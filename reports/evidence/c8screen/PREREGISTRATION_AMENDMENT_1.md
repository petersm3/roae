# PREREG_C8SCREEN — AMENDMENT 1 (§9-A1 … §9-A4), dated 2026-10-11 — DECLARED BEFORE ANY MEASUREMENT

> # 🔒 This file is the §9 annotation block of the frozen `PREREG_C8SCREEN_2026_10_11.md` (sha256 `2ba24eceb2bddcba3c14f40231c1024c9a94d79c1ba37225eece1c84a969f161`, commit `b2fa6f9d`, `docs/data/PREREG_LOCK_LEDGER.txt` line 4). The frozen file is not edited; §10.4 of that file places annotations outside its frozen bytes by construction, and this file is locked by its own ledger line. NO VALUE OF ANY FAMILY MEMBER ON KING WEN EXISTS AT THIS AMENDMENT.
>
> **Written** 2026-10-11 by Claude Fable 5.1 (`claude-fable-5-1`), the project's Fable lane, on the orchestrator's brief, from
> `review_2026_09_27/PILOT_A_SCORER_REPORT.md` (commit `84998c43`, read in full) and the staged scorer tree `e6783293`
> (`review_2026_09_27/pilota_scorer/pilota_scorer.patch`, sha256 `c5341672…`).
>
> **What has and has not been computed at this amendment.** No estimator run (`--estimate-knuth`) was launched; `--c8-kw` was
> never run (its refusal path only, inside `tests.py`); no N1 histogram, percentile or p-value exists for any member. The only
> computations made for this file are (i) exact combinatorics of the N0 *law* of one member (`P-CM[odd]`, a DP over parity
> arrangements of synthetic C1&C4 draws), (ii) random C1&C4 orderings (`--c8-null0` on a non-frozen seed, `7`), (iii) the
> **set cardinalities** of the three corpus controls (not their member values: the one scratch file that held control values
> was deleted without its value lines being read), and (iv) builds and tests of the instrument. Every seed of §6 remains
> unused. `KW_TOUCHED=NO` is asserted by the amended defcheck's self-grep exactly as the frozen one asserts it.
>
> **Amendment rule honoured.** Each item below is dated, cites the ground that forces it, states why that ground is
> independent of any King Wen outcome, and lists the exact instrument changes. Nothing above §9 of the frozen file is
> reinterpreted beyond what each item says.

---

## §9-A0 — Identities (what the lock ledger must carry beside this file)

| object | sha256 | note |
|---|---|---|
| this file | *(ledger line, written by the orchestrator at lock)* | the amendment's identity; `AMENDMENT_SHA_VERIFIED` (§9-A3) compares against it |
| `scripts/prereg_c8screen_defcheck_a1.py` | `28889b9f4f50e02ccda9ea6359c7c7b1cdafd367fe3c678d0d325bda34022adb` (317 lines) | the amended defcheck: `DEFCHECK=PASS`, **41 PASS lines**, `KW_TOUCHED=NO`; identical to the frozen `bb017ec5…` on lines 1–163 **except line 147** (A1), so the normative extract ranges `11, 15–25, 37–52, 55, 57–59, 83–158, 163` of §2.5/§7.1 stay valid; blocks G (A1) and H (A2) appended after E11 |
| `MEMBER_LIST_SHA256` | **`529fb27a96ec9ebc422b64ef0f5d091319a85e859bb65fbc93f6f61aef6ff34a`** | replaces the frozen `486cac40f85c1639bd4e05915541525e48b05a5097c589121ac28962a82db06c`; defcheck G6 proves the two preimages differ in exactly the four `P-CM` rows (re-substituting 465 reproduces `486cac40…`) |
| `C8_REFERENCE_SRC` (solve.py, the byte-for-byte §2.5 extract) | `6a1aa402697aca2a03091835dfb2f1d689396ca8ff38c18787f22652cb319983` | replaces `e07e64a4…`; differs from it in one line (the `P-CM` range line) |
| `SUBGROUP_LIST_SHA256` | `44e8a16bd08c4caf0edd1619ca598b891e5515836ca6feb67ae59fd605d40d52` | **unchanged** |
| `review_2026_09_27/pilota_scorer/amendment_1.patch` | `3cbac76a7d806f3f207c6cc88d6386a65591d7040c9258e4ddad3afe4cd27ddf` (212 lines, 12 hunks; `solve.c`, `solve.py`, `tests.py`, `documentation/SOLVE_PY_CLI.md`) | the public-tree changes, **not applied to any public worktree by this lane**; replayed in a throwaway worktree: `9967ec14` + QOY patch → `a7d59569` + scorer patch → `e6783293` + this patch → tree **`a40140806206cb9ef13bcb2efd40d62a90a8a7fb`**; `solve.c` `eab41a106fc8385486e70b376ac66cee54e7c2b590c68ba230056e62e52b6dcb`, `solve.py` `5d194b325cd79e03d9e5c4a4d03bdf46c2a8ba18409082e8569b76d158d5d502`, `tests.py` `a4eed2821e19609db0f9394f5c79e9fae7d6b0aee723c8f42a124f6a458abc75` |
| `scripts/c8screen_analyze.py` (private verdict script, **edited in place**, uncommitted) | `65d98b444d3d4928d78efd178c0145b88b0afcc54542826d0724f3f8278c5009` (was `83cff06a…`) | `C8_ANALYZE_SELFTEST=PASS` with the new A2/A4 legs (§9-A3) |

The digest of the amended defcheck is pinned inside the patch (`solve.py` `C8_DEFCHECK_SHA256`, `tests.py` `DEFCHECK_SHA`): **the orchestrator must lock the defcheck byte-identical to the file delivered**, or re-pin those two literals before applying the patch.

---

## §9-A1 — 2026-10-11 — the four `P-CM[c]` declared ranges: `(0, 465)` → `(0, 496)`; new `MEMBER_LIST_SHA256`

**The defect (scorer report A1, confirmed independently here).** The frozen range `31·15 = 465` was derived from the C1∩C5 theorem
(`|B_odd| = 15` forced, so under N1 `max P-CM[odd] = 17+…+31 = 360`, and `|B_2|,|B_3|,|B_4| = 8, 13, 7` give 220, 325, 196).
N0 imposes no C5 (frozen §4.1, defcheck E4), and under N0 `P-CM[odd] = 496 = 1+…+31` is **attained**: pair parity is a pair property
(`rev` preserves `y`; `comp` maps `y ↦ 6−y`), there are 16 even and 16 odd pairs with `(63,0)` even, so the slot parities can
alternate perfectly from slot 2 (odd, even, …, odd), making all 31 boundaries odd. Exact N0 law of `P-CM[odd]` (DP over the
`C(31,15) = 300,540,195` equiprobable parity arrangements of slots 2..32; defcheck G2, re-derived here from scratch and agreeing with
the scorer lane's number): `P(P-CM[odd] > 465) = 684 / 300,540,195 = 2.2759×10⁻⁶`, i.e. **22.8 expected clamps in the frozen 10⁷ N0
draws**, `P(≥ 1 clamp) ≈ 1 − 1.3×10⁻¹⁰`; the maximum 496 is attained by exactly one arrangement; `P(> 496) = 0`. `P-CM[3]` also
attains 496 (a C1&C4 ordering with all 31 boundaries at distance 3 exists; defcheck G4, found by bounded DFS in 32 nodes);
`P-CM[2]`, `P-CM[4]` were not searched to exhaustion (not claimed, not needed: 496 bounds them). As frozen, §5.4 makes the family
`VOID` on `C8_CLAMPED_TOTAL ≠ 0`, so **the frozen registration would have voided itself with near certainty on a null that is annotation-only** —
an instrument defect, not a property of King Wen.

**Why the frozen E1 check missed it.** E1 samples 300 random C1&C4 orderings; the exceedance probability is 2.3×10⁻⁶, so E1 had
≈ 0.07 % power. An absence claim needs a positive control; G3 now supplies one (the alternating construction, deterministic).

**The change.** Line 147 of the defcheck (inside the normative extract) becomes

```
    MEMBERS.append((f"P-CM[{c}]", "S", (lambda c: lambda s: P_CM(s, c))(c), (0, 496)))   # A1: 496 = sum(1..31), universal; frozen 31*15 = 465 was N1-only
```

**Why 496 and not the attainable maximum per `c`.** 496 = Σ_{b=1}^{31} b is the **universal** bound of a sum over any subset of the 31
boundary indices — the same principle under which the frozen file already bounds `Y-CM`/`T-CM` by 528 = Σ_{k=1}^{32} k, `*-DISP` by 32²,
`P-DISP` by 30² and `C-D` by 7·9 + 21² = 504. Defcheck G5 now verifies **every** declared range against the universal bound of its
member class, so no range depends on which population is being sampled (which was exactly the error). A range is only a binning
envelope: widening it changes no member's value, no bar, no verdict rule; the only bins it adds (466..496, four members, 124 bins) can
receive mass from N0 alone, since every N1/N1′ leaf satisfies C5 and tops out at 360.

**Independence from any King Wen outcome.** The bound is arithmetic on `{1..31}`; the exceedance law is a property of random
C1&C4 orderings; no King Wen value enters, and none exists. The change cannot move KW's position in any N1 histogram (N1 is unaffected
above 360) and cannot move any N0 two-sided p except by *correctly* binning the ≈ 23 N0 draws the frozen instrument would have
piled at 465 — a correction of the annotation, in the direction of the frozen definition.

**Execution record (gates must discriminate; non-frozen seed, random orderings only).** `--c8-null0 3000000` with
`SOLVE_KNUTH_SEED=7`: amended binary `C8_CLAMPED=0`, `P-CM[odd]` bins above 465 = {468:1, 470:2, 472:1, 482:1, 490:1} (six draws;
expectation 6.8); frozen binary on the identical stream `C8_CLAMPED=6`, all six piled at 465; every other member's `c8_hcnt` histogram
byte-identical between the two binaries. Observed maxima in that stream: `P-CM[2/3/4/odd]` = 352/419/372/490.

**`C8_CLAMPED_TOTAL` reading, resolved.** The literal reading stands: the sum over all five runs (N1 A/B, N1′ A/B, N0), printed per run
as `C8_CLAMPED_<run>` and as `C8_CLAMPED_RULE=TOTAL_OVER_…`. After A1 every range is a universal bound, so a clamp anywhere can only be an
instrument bug, and voiding on it is the right behaviour. The scorer lane's options (a) scope-to-N1 and (c) attainable-max bins are
rejected: (a) would leave N0's upper tail mis-binned; (c) would re-introduce population-dependent ranges.

**Instrument changes (all in `amendment_1.patch`).**
- `solve.c` line 51986: `c8_add_member(&n, id, 'S', 0, 31 * 15)` → `0, 496` (comment added). `--c8-list members` now prints `P-CM[*] S 0 496`.
- `solve.py`: `C8_DEFCHECK_SHA256` → `28889b9f…` (the a1 file), `C8_REFERENCE_SHA256` → `6a1aa402…`, `C8_MEMBER_LIST_SHA256` → `529fb27a…`,
  the `P-CM` line of `C8_REFERENCE_SRC` as above, the `compile()` pseudo-filename → `prereg_c8screen_defcheck_a1.py …`, the block comment.
- `tests.py` `TestC8Scorer`: `MEMBER_SHA`, `REFERENCE_SHA`, `DEFCHECK_SHA` re-pinned; the re-extraction test's positive control
  `replace("31 * 15", "31 * 16")` (now a no-op) → `replace("(0, 496)", "(0, 497)")` plus `assertIn("(0, 496)))", exc)`.
- `scripts/c8screen_analyze.py`: the gate check `MEMBER_LIST_SHA256` now compares the full `529fb27a…` (was a prefix of `486cac40…`).
- The §7.2 `DEFCHECK` gate reads: `python3 scripts/prereg_c8screen_defcheck_a1.py` → `DEFCHECK=PASS`, **41 PASS lines**,
  `FAMILY_K=1349`, `MEMBER_LIST_SHA256=529fb27a…`, `SUBGROUP_LIST_SHA256=44e8a16b…`, `KW_TOUCHED=NO`.

---

## §9-A2 — 2026-10-11 — corpus controls (§4.4, §5.4(c)): the `DEFINED` rule; an undefined control is `NA` and never defeats specificity

**The defect (scorer report A2).** §4.4 evaluates every member on the Jing Fang, Mawangdui and Fu Xi orderings, "non-C1 orderings
(slot-based members are still defined on them as sequences)". That parenthesis is true of the **count** members and false of the
**positional** ones: on Fu Xi (`s[i] = i`, so slot k holds `(2k, 2k+1)` and `y(2k+1) = y(2k)+1`) every pair yang-sum is odd, all five
`S_v` are empty, and the frozen `circ_disp([])` raises (defcheck H3 reproduces this). `qoy_D` silently mis-computes when `|K_H| ≠ 8`
(it reads 8 gaps regardless), and `CM(∅) = 0` is a number with no positional meaning. So §5.4(c) is not evaluable as frozen, and the
scorer refuses non-C1 input on both sides (`C8_VERIFY_INPUT=REFUSED`) rather than invent a convention.

**The decision (made on the definitions alone; no control value and no King Wen value consulted).** The frozen rule and its QOY
precedent (`PREREG_QOY1_Q992` §4.4: `D = NA` when coset 0 is absent; measurement I1: `SPECIFICITY=NA` when not evaluable) are kept;
what is added is the one convention the frozen text lacks, and it is the frozen text's own precondition made explicit:

> A member's value on a control is **DEFINED** iff (a) the member is a count (`C-N[H]`, `C-M[H]`, `B-*`, `P-MAXRUN`, `Y-AC`, `Y-TV`,
> `Y-RUNS`, `Y-MAXRUN`: 1,295 members; defined on any sequence of 64 distinct words), or (b) the member is positional (`C-D[H]`,
> `P-CM/P-DISP[c]`, `Y-CM/Y-DISP[v]`, `T-CM/T-DISP[t]`, `T-CM/T-DISP[pure]`: 54 members) **and the slot/boundary set it positions has
> the cardinality every N1 leaf forces**: `|K_H| = 8` (B7), `|B_2|,|B_3|,|B_4|,|B_odd| = 8, 13, 7, 15` (the C1∩C5 theorem, §2.4),
> `|S_v| = {2:3, 4:6, 6:14, 8:6, 10:3}` (C3), `|T_t| = {8,15,8,15,15,8,15,8}` (C2), `|S_pure| = 4` (C4). Otherwise the value is **`NA`**.
> §5.4(c) and the SURVIVOR row read "… some **DEFINED** control has same-tail operative `p ≤ β_m`" / "… no **DEFINED** control …";
> an `NA` control can never defeat specificity. Per-member tokens print `value=NA same_tail(…)_operative_p=NA`.

**Why this rule and not the alternatives the brief listed.**
- *Define the members numerically on non-C1 inputs* (`circ_disp(∅) := 0`, `qoy_D` on `|K| ≠ 8`, …) would add post-freeze numerical
  conventions, and would create a **new by-construction UNINFORMATIVE path**: `CM(∅) = 0` lies below the entire N1 support of every
  `Y-CM`/`T-CM` member, so any lower-tail survivor among them would be killed by Fu Xi "having" the feature it does not have. Rejected.
- *Restrict the controls to C1 orderings*: none of the three is C1 (`C8_CTRL_IS_C1_*=NO`, verified), so this empties the rule; a
  "C1 projection" of a corpus ordering would be a new, un-registered object. Rejected.
- *Drop the rule*: it would loosen the SURVIVOR condition after freeze — the one direction a sceptic scrutinises — and discard the
  QOY-precedent design the frozen file chose. Not necessary once `NA` is defined. Rejected.
- The `DEFINED` rule is the minimal, conservative completion: it is **vacuous on every C1∩C5 leaf and on King Wen** (defcheck H1; the
  sets have their forced sizes there by theorem), so it cannot change any KW value or any N1 histogram; it can only decide whether a
  control *enters* the specificity comparison, and it does so by a set-size test fixed before any value was seen.

**Pre-declared consequence (cardinalities only, computed from `solve.py`'s `_r7_jingfang/_r7_mawangdui/_r7_fuxi` at tree `e6783293`).**
Every positional member is `NA` on every control, so the specificity rule acts on the 1,295 count members only:
- Jing Fang: **54 NA** = all 18 `C-D` + all 36 positional stratum-S members (8 P, 10 Y, 16 T, 2 pure).
- Mawangdui: **54 NA**, the same set.
- Fu Xi: **49 NA** = 15 `C-D` (`C-D[083]`, `C-D[115]`, `C-D[127]` are defined: those three pair-closed subgroups happen to contain 8
  Fu Xi slots) + 8 P + 10 Y + 16 T; `T-CM[pure]`, `T-DISP[pure]` are defined (Fu Xi's entries 0, 18, 36, 54 are pure).
These counts are pinned as `C8_CONTROL_NA_DECLARED` and checked by the producer (`C8_CONTROLS_NA_MAP=PASS|FAIL`) and by `TestC8Scorer`.

**What the retained rule still does, stated so no one is surprised.** A DEFINED control's value is placed in the N1 histogram
"exactly as KW's is" (frozen §4.4): a non-C1 ordering can therefore sit at or beyond the N1 support on a count member (e.g. Fu Xi's
`C-M[H] = |H ∩ {even words}| ∈ {8, 16}`), in which case its same-tail operative `p` is `3/L` and any would-be survivor on that member in
that tail becomes `UNINFORMATIVE SPECIFICITY`. This is the frozen design and the QOY precedent, not a new path; it acts only on members
already below the bar, is fully reported (member value, control value, reason token), and the §8.4 write-up must name every such
member. The family verdict logic is otherwise untouched: `FAMILY=SURVIVOR` iff ≥ 1 SURVIVOR; `NULL` iff ≤ 67 UNINFORMATIVE+FORCED;
else `UNINFORMATIVE`.

**Instrument changes.**
- `solve.py` (SPEC side only; the C scorer never sees a control): `C8_CONTROL_NA_DECLARED`, `C8_P_FORCED`, `c8_defined(seq, mid)`,
  `c8_control_values(seq)`, `c8_controls()` and the flag `--c8-controls`, printing one `c8_ctrl <CTRL> <member-id> <value|NA>` line per
  member, `C8_CTRL_IS_C1_<CTRL>=NO`, `C8_CTRL_NA_<CTRL>=<n>`, `C8_CTRL_MEMBERS=1349`, `C8_CONTROLS_NA_MAP=PASS|FAIL` (exit 1 on FAIL).
  No member is evaluated on King Wen (the Mawangdui ordering is built by KW-index lookup, the control definition frozen §1 already pins).
- `tests.py`: `test_controls_producer_amendment_1` (NA map 54/54/49; all three non-C1; every `Y-DISP` NA on Fu Xi; count members never
  NA; no `c8_kw` line; no control equals King Wen; the rule vacuous for non-P members on random C1∩C4 draws).
- `documentation/SOLVE_PY_CLI.md`: the `--c8-controls` row.
- `scripts/c8screen_analyze.py`: parses `NA`; `nonspec` ignores NA; `CONTROL_NA_<CTRL>` tokens; `C8_CONTROLS_NA_MAP=PASS` (read from
  `controls.out`) joins the pre-run gates; selftest legs: an NA control on a survivor leaves it SURVIVOR, a DEFINED control in the tail
  gives `UNINFORMATIVE SPECIFICITY`, `C8_CONTROLS_NA_MAP=FAIL` gives `FAMILY=VOID`.
- Runbook: `controls.out` = stdout of `python3 solve.py --c8-controls`, run **with the §7.2 gates (before the pin and before `--c8-kw`)**,
  since it evaluates nothing on King Wen; its `C8_CONTROLS_NA_MAP` line is copied into `gates.txt`.

---

## §9-A3 — 2026-10-11 — declared instrument additions (the §9 pin's vocabulary) and the §7.2 gate list as amended

Declared as part of §7.1/§7.2/§7.4, additive to the frozen lines (which are unchanged):
- **`c8_hcnt <member-id> <value> <leaves>`** lines after the `c8_hist` lines in every scorer output: the per-bin scored-leaf counts
  from which §5.4's `n_A`, `n_B` ("scored leaves in the smaller tail") are read; the frozen `c8_hist` weights cannot give them.
  `TestC8Scorer` asserts the counts are conserved (every scored leaf once per member).
- **`C8_UNDEFINED`** (every run): the number of member evaluations whose reference definition is undefined (an empty position set, or a
  pair-closed `K_H` with `|K_H| ≠ 8`). It is **0 on every C1 ordering by theorem** (defcheck E3, B7); `C8_UNDEFINED ≠ 0` in any run is a
  §7.2-class instrument failure and makes the family `VOID` (already in `c8screen_analyze.py`; declared here).
- **N0 tokens** `C8_NULL0_DRAWS`, `C8_NULL0_SEED`, `C8_NULL0_NOT_C1` (must be 0); `--c8-null0` requires `SOLVE_KNUTH_SEED` and refuses otherwise.
- **CLI names the frozen text left open:** C `--c8-verify FILE`, `--c8-list members|subgroups`, `--c8-null0 N`; Python `--c8-print FILE`,
  `--c8-verify BINARY [--c8-verify-n N]`, `--c8-kw --c8-pin TEXT`, `--c8-controls` (A2).
- **Base tree.** Frozen §1 named the QOY staged tree `4b590dfc` on `11003edd`; `main` moved to `9967ec14` and the QOY push has not landed,
  so the §9 instrument pin names the actual base: `9967ec14` + QOY patch → `a7d59569` + scorer patch → `e6783293` + `amendment_1.patch`
  → `a4014080…` (file digests in §9-A0), or the publishing batch's equivalent, with digests.
- **§7.2 gate list, amended:** add `AMENDMENT_SHA_VERIFIED=PASS` (the lane's `sha256sum` of this file equals its ledger line),
  `DEFCHECK_A1_SHA_VERIFIED=PASS` (same for `scripts/prereg_c8screen_defcheck_a1.py`), `DEFCHECK=PASS` **from the a1 script**
  (41 PASS lines, `MEMBER_LIST_SHA256=529fb27a…`), and `C8_CONTROLS_NA_MAP=PASS`. `tests.py` is run with
  `ROAE_C8_DEFCHECK=<roae-private>/scripts/prereg_c8screen_defcheck_a1.py` so the byte-for-byte re-extraction test is exercised, not skipped.
- **Minor readings of the scorer report, ratified as written:** half-wise `p_op,A/B` apply §5.1 within each half with that half's `L`;
  an N1′ self-validation failure is reported and is not `VOID` (N1′ is annotation-only); `SE_printed` = printed 95 % CI width ÷ 3.92.

---

## §9-A4 — 2026-10-11 — §5.3 independence annotation: the overlapping clauses resolved (QOY precedent I2)

As frozen, `INDEPENDENT_OF_C2_C5` ("`p_op,N0 < β_m` in the same tail as the N1 result") does not require `p_op < β_m`, so with
`p_op ≥ β_m` it coincides with `EXPLAINED_BY_C2_C5`. Resolved, as the QOY measurement's I2 resolved the same text:

| token | condition |
|---|---|
| `INDEPENDENT_OF_C2_C5` | `p_op < β_m` **and** `p_op,N0 < β_m` **and** the two smaller tails are the same side |
| `C2_C5_CONDITIONAL` | `p_op < β_m` and `p_op,N0 ≥ β_m` |
| `EXPLAINED_BY_C2_C5` | `p_op ≥ β_m` and `p_op,N0 < β_m` |
| `NA` | otherwise: both `≥ β_m`, or both `< β_m` in opposite tails |

Mutually exclusive and jointly exhaustive. Annotation only; no verdict depends on it. `c8screen_analyze.py` already applied this reading
and now prints `INDEPENDENCE_RULE=AMENDMENT_1_A4`.

---

## §9-A5 — reserved: the instrument pin and the `--c8-kw` date (measurement lane, before any run)

The lane appends its pin here in the QOY §9-A1/§9-A2 form (staged tree id + file digests, `BINARY_FRESH`, gate tokens), then runs
`--c8-kw` and records its `C8_KW_DATE_UTC`. Nothing in A1–A4 is to be re-opened by the lane; a further defect is a new dated item.

---

## Re-check: does the amendment create any new way to `VOID` or to go `UNINFORMATIVE` by construction?

| path | status after amendment 1 |
|---|---|
| clamp (`C8_CLAMPED_TOTAL ≠ 0` → VOID) | **closed**, not opened: every range is now a universal bound (G5); a clamp can only be a bug. Frozen: near-certain VOID from N0 alone |
| `C8_UNDEFINED ≠ 0` → VOID | cannot fire on C1 input (theorem; E3/B7); bug-only |
| `C8_CONTROLS_NA_MAP=FAIL` → VOID | computable at gate time, before any run and independent of KW (controls only); verified `PASS` on the amended tree now |
| `MEMBER_LIST_SHA256` mismatch → VOID | both languages reproduce `529fb27a…` (tests pass in both); caught at gate time |
| `NA` controls | cannot defeat specificity → no new UNINFORMATIVE; the DEFINED rule is vacuous on KW and on every N1 leaf |
| `UNINFORMATIVE ATTAIN / REPLICATION / LEAVES` | unchanged (support-, replication- and count-based; ranges play no part) |
| `UNINFORMATIVE SPECIFICITY` | unchanged in logic; now evaluable; acts only on members already below the bar; fully reported |
| the 124 new bins | receive N0 mass only; N1/N1′ leaves never exceed 360 on `P-CM` |

No new path. The amendment removes one by-construction `VOID` (A1), makes one frozen rule evaluable without adding a numerical
convention (A2), declares additive outputs (A3) and makes an annotation exhaustive (A4).

## Record of what was executed for this amendment (all on synthetic input; private scratchpad, session `a4fc41bf`)

`a1_dp.py` (exact N0 law), `a1_attain.py` (bounded DFS: `c=3` attains 496 in 32 nodes; `c=2`, `c=4` not found within 120 s each),
`a2_defined_map.py` (control set cardinalities), `build_a1.py` (generates the a1 defcheck from the frozen bytes and proves the extract
differs in one line), `defcheck_a1.out` (41 PASS), scratch export of tree `e6783293` with the patch applied: `gcc -O2 -fopenmp` build OK,
`TestC8Scorer` 18/18 OK (43.9 s, re-extraction exercised), `--c8-controls` `PASS`, `--c8-null0 3000000` seed 7 on amended and frozen
binaries (the discriminating pair above), `CLI_DECL_METADATA=PASS`; throwaway worktree `roae-q-amend1-tmp` for the git-dependent gates
(removed after use): `scripts/doc_gates.sh` → `DOC_GATE_EMITTED_SURFACE=OK` (`NEW=0`, `PY_NEW=0`; no newly undocumented token),
`scripts/doc_gates.sh cli` → `DOC GATES: PASS (cli)`, `scripts/citation_line_gate.sh --all-files --all-targets` → `CITATION_LINE_GATE=PASS`
(leg A **0 shifted**: the inserted `solve.py` lines move no cited line; leg B 54 stale, all pinned, unchanged), `CLI_DECL_METADATA=PASS`.
No public worktree was modified; `roae-q-pilota` still stages tree `e6783293`. No commit, no push, no ledger write, no P3 run.
No prior-art check was run: this file registers no finding and makes no absence claim about the literature.

PREREG_C8SCREEN_AMENDMENT_1=READY_TO_LOCK
