# TR-8 — A Reordering Revisited: Two Computational Answers to McKenna and Mair (1979)

*Technical report — not peer-reviewed. Every MEASURED result carries a reproduction command, and every
proof cited as machine-checked names its certificate or Lean theorem; claims of scope, attribution and
interpretation are argued, not verified. One caveat is structural, and it frames all the rest: the same
author wrote the claims, the software that checks them, and this report that grades the check.
Verification here is independent in mechanism, never in authorship; no independent party has yet
audited or reproduced any of it (METHODS.md §"Authorship independence").*

Methods, environment pinning, statistics conventions, and artifact access: see [METHODS.md](METHODS.md).

## Executive summary

In 1979, [McKenna and Mair](../documentation/CITATIONS.md#mckenna-mair1979) proposed that the King Wen sequence would be "better" reordered — that a
rearrangement could smooth its irregularities. The proposal drew one published reply — a philosophical
critique ([Hershock 1991](../documentation/CITATIONS.md#hershock1991)) that rejected its method but
shared its premise and tested neither claim — and sat computationally untested for 47 years. This report
answers it twice. First, by measurement: the properties their argument assumed to be defects are, when
checked against the space of valid orderings, among the sequence's rarest measured configurations. A
calibration caveat travels with this from the outset: the rules being measured (Moore's parity, Schulz's
gender rule) are **descriptions read off King Wen**, and a predicate crafted to fit a specific sequence is
rare almost by construction — so rarity here is a measured property of King Wen's position, not by itself
evidence of design. A direct sensitivity check makes the point quantitative: when the reference class of
KW-fitting predicates is matched to the literature rules' actual structural complexity (≈16 clauses), King
Wen's rules fall in the **bulk** of that rarity distribution — the median dof-matched KW-fitting predicate
reaches a rarity near ~6×10⁻⁵, and about half are at least as rare as King Wen's ~1×10⁻⁴ — so the rarity
is largely a matter of specification, not demonstrated design, and King Wen is **not** claimed to be
tail-extreme among comparably-specified predicates. *(Reproducibility flag, added 2026-08-01 — this
report's banner promises a reproduction command for every measured result; this one does not. The baseline
has **no artifact, command, code path or evidence bundle anywhere in the repo**: §Commands below gives
runnable commands for the Gray-code theorem and the exact pair-null but none for this; nothing in the
repo defines the ≈16-clause predicate space, how predicates were drawn, the probe count or the seed.
[METHODS.md](METHODS.md) §"Data-like vs principled constraints", which cites this baseline, carries the
same disclosure and directs readers to treat the ~6×10⁻⁵ median as an **unreproduced figure until a
regeneration command is published**. The direction it points — that a predicate crafted to fit one
sequence is rare largely by construction — is independently supported by the data-like/principled
firewall and by TR-9's pricing; the specific numbers are not yet checkable. What would settle it: a
`solve.py` sampler over the ≈16-clause KW-fitting predicate space, published with its seed and probe
count, reporting the median rarity with a CI.)* **WITHDRAWN PENDING ARTIFACT (2026-08-07 —
[CORRECTIONS](../documentation/CORRECTIONS.md) CX-27; operator-authorized action on the 18-lens
red-team review).** The v1.10 flag above was disclosure without consequence: the flagged figure kept
doing load-bearing work in this summary. The ~6×10⁻⁵ median and the "about half are at least as
rare" comparison are now **withdrawn as citable figures** — not to be cited or relied on, by readers
or by this report's own text, until the sampler named above exists with its seed and probe count
published. The disclosure stays, and the qualitative **direction** stays as an acknowledged open
question rather than a result: it argues *against* this suite's own rarity claims (a conservative
direction, against interest), and is independently supported by the data-like/principled firewall
([METHODS.md](METHODS.md) §"Data-like vs principled constraints") and by
[TR-9](TR9_PRICING_THE_CONSTRAINTS.md)'s pricing — but the placement of King Wen's rules in the
*bulk* of the dof-matched distribution is exactly as strong as the unpublished sampler behind it,
which is to say: not yet claimable. **Look-elsewhere context (F-32):** the suite's
enterprise-wide observable ledger is frozen at **91** observables ([METHODS.md](METHODS.md) §Global
observable ledger), so a Bonferroni-style global bar sits at
0.05/91 ≈ **5.5×10⁻⁴**. Read against that bar rather than against 0.05, a per-rule rarity of order
10⁻⁴ — specifically the Schulz gender rule's **pair-null exact** value, 47/445740 = 1.054426×10⁻⁴
(§Commands) — clears it by only a factor of **~5 under Bonferroni** — the correction family this
suite applies throughout — and by **≥~10× under Benjamini–Hochberg FDR
([Benjamini & Hochberg 1995](../documentation/CITATIONS.md#benjamini-hochberg1995)) at q = 0.05** on the same
91-observable ledger; neither is "the" margin, and both are stated because the margin is
correction-specific. *(Why the BH figure is a floor rather than a point: BH's bar is rank-dependent,
*i*·0.05/91, so a value's BH margin is exactly *i* times its Bonferroni margin. Only *i* ≥ 2 is
supported here — forced by `dav_rotinv` at 6.5×10⁻⁵ — giving ≥~10×; the bar reaches ~500× only at the
maximum rank *i* = 91, which is the same ~500× that reading against an uncorrected 0.05 would suggest.
A ~52× figure for this rarity is BH at rank *i* = 10 and is **not** used: rank 10 requires nine
strictly-smaller ledger values, and the only nine available were withdrawn from ranking on 2026-08-01.
One asymmetry is load-bearing and is stated rather than assumed. The same rule carries **two**
rarities in this report and they are different numbers in different classes: the value the margins
above are computed on is the pair-null exact 1.054426×10⁻⁴, while its C1–C5 counterpart — the
published ×11,364, i.e. ≈8.80×10⁻⁵ — is a literature-rule **registry mass**
([TR-1](TR1_EIGHT_CENTURIES_MEASURED.md) §7), the class METHODS excludes from BH ranking, so *that*
one may hold no rank at all. Whether the pair-null restatement of the same rule escapes the same
exclusion is not something this report decides, so the BH figure remains **conditional** on reading
this rarity as a ledger member, and the ~5× is therefore the firmer of the two. Read instead on the
registry mass the margins would be ~6.2× Bonferroni and ≥~12.5× BH, so the figures published here are
the **smaller**, conservative pair either way. *(Corrected 2026-08-30 — this passage anchored the
margins on 1.054×10⁻⁴ while calling that quantity "a literature-rule registry mass", which is the
other number; §"Verification Guide" below already said in as many words that the two are "different
quantities". No published margin moves, and the direction of the error was against interest. See
v1.16.)*
See [METHODS.md](METHODS.md) §"Statistics conventions", under **Correction-family disclosure**.)* So the family choice moves this margin
by an order of magnitude — from ~5× to ~10× or beyond — while changing **no** verdict in this report,
and exactly one in the suite (`dav_trigarray`, in [TR-10](TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md)).
Under either family the dof-matched comparison above — itself withdrawn pending artifact (CX-27) —
*suggested* that much of even the smaller (Bonferroni) margin is attributable to specification; that
attribution now stands as an open question rather than a shown result, and independently of it,
nothing in this report's conclusion turns on which family a reader prefers. The multiple-comparisons accounting for the battery as a whole is in
[CRITIQUE.md](../documentation/CRITIQUE.md) and is not re-derived here. Against that baseline the honest claim is narrower than
"removing them removes what is special": removing them removes the measured regularities the received order
happens to sit at. Second, by proof: no **fully smooth** ordering — one in
which *every* adjacent pair differs in a single line — can realize a complement/inversion pairing at
all, because within-pair Hamming distances under such a pairing are always even and nonzero. That is a
two-line parity argument anyone can verify by hand, and it applies to the classical pairing and to
McKenna and Mair's own all-complement pairing alike. **It does not refute their construction**, and
versions v1.0–v1.15 of this report said that it did. Their published ordering is *hybrid* by design:
the Gray-code single-line step governs only the transitions **between** pair representatives, while the
step **within** each pair changes all six lines (PEW 29:4 pp. 424–426, Figure 2). It meets the
requirement they actually stated — a single-line step at all 31 between-pair transitions, which follows
directly from their taking consecutive 6-bit Gray-code values as the 32 pair bases — and it *replaces*
the classical 28-inversion/4-complement pairing rather than keeping it, so neither conjunct of "a Gray
path that keeps the classical pairing" is something they proposed. What answers their *position* is
§2's premise measurement. The theorem's honest content is that the received order cannot be smoothed
into a Gray path, and that no fully smooth ordering realizes a pairing of this family — which is
precisely why a construction like theirs has to be hybrid. The credit is unchanged: theirs was a
concrete, falsifiable proposal, which is exactly what made it answerable.

Verification model: both results are mechanically checkable; the verification is procedural.

---

## Abstract

In a 1979 article in *Philosophy East and West*, Stephen E. McKenna and Victor H. Mair argued that the received (King
Wen) ordering of the sixty-four hexagrams is structurally indefensible beyond its local pairing, and
proposed a replacement ordering constructed on Gray-code principles. Both halves of their position can
now be evaluated computationally. First, exhaustive and sampling analyses show that the received order
carries measurable structure far beyond pairing: positional regularities first noted by commentators from
the thirteenth century onward hold in as few as one in ten thousand comparable orderings — whether the
comparison population is the full C1–C5 constraint-satisfying space (≈1.33×10³⁸ orderings) or the far
larger space constrained only by the pairing itself (32!·2³² ≈ 1.1×10⁴⁵; direct seeded sampling, same
order of rarity for the gender rule). Second, a two-line proof
settles the smoothness question their proposal raised: consecutive partners in the received order differ
in two, four, or six lines, never one, so no sequence in which *every* adjacent pair differs in a single
line can reproduce that pairing. Because within-pair distances are even and nonzero under any
complement/inversion pairing — including the all-complement pairing McKenna and Mair themselves adopt —
no fully smooth ordering realizes a pairing of this family. This does **not** refute their published
construction, which is hybrid by design (single-line steps between pair representatives, six-line
complement steps within them) and which replaces the classical pairing rather than preserving it. McKenna and Mair
retain a distinction that should be credited plainly: theirs was the first proposal to evaluate the
received order against an explicitly constructed alternative — the methodological seed of the present
analysis. We supply the instruments their question required.

## Structure — section summaries (4)

**Note on this report's form (Q-352; relabelled 2026-08-29).** The four numbered items below are
**section summaries, not written-out sections** — this report's fully-written material is the
Verification Guide and §Commands beneath them, which carry the runnable form of both quantitative
claims. Saying so is the point: TR-2 carried the identical "Structure (N sections)" heading over a
summary list and was relabelled for it (v1.13), and TR-3's list was written out into prose; TR-8 was
left, and a masthead plus a peer listing in [reports/README.md](README.md) invited a reader to
expect four sections that are not there. The summaries are deliberate — §1 and §4 are
humanities-register prose about what named scholars proposed, where every added sentence is a
further claim about a person — but the label was not.

1. **The 1979 position** — summarises their premise (no defensible global structure), their proposal
   (Gray-code reordering starting from Kun), and their motivation, and credits theirs as the first
   constructive test proposal in the literature. The only published reply we have located
   ([Hershock 1991](../documentation/CITATIONS.md#hershock1991), JCP) critiqued their method on
   philosophical grounds while sharing their premise of global randomness and proposing a mandala
   reordering of his own — so the premise itself went unmeasured, and the construction's feasibility
   undecided, until now.
2. **The premise, measured** — two null populations, stated precisely (they are different spaces and give
   different numbers): (a) the C1–C5 constraint-satisfying population (≈1.33×10³⁸ orderings, estimator
   validated against exhaustive slices) — this is the population over which the quoted rarities are
   mass fractions; note C2/C5 are themselves regularities read off the received order, so this null is
   conservative, not "undisputed"; (b) the pair-only (C1) space, 32!·2³² ≈ 1.1×10⁴⁵ — the truly
   undisputed structure, checkable by direct seeded sampling on a laptop (Commands below). Measured
   rule rarities are reported for three rules only (over population (a): [Moore](../documentation/CITATIONS.md#moore2005) parity ×1,362; [Schulz](../documentation/CITATIONS.md#schulz1990-motifs) gender
   ×11,364; the 18:18 split ×2.7 as the honest weak case; the gender rule re-measured against null (b)
   computes **exactly** to 1.05×10⁻⁴ (47/445740; §Commands) — same order, different null) with sources credited (rules are
   Zhu Yuansheng/Schulz/Moore observations, not ours; measurement is ours). Exact commands are given
   in §Commands below, against the open repository.
3. **The smoothness question, decided — and what that does not decide** — Theorem: no *fully smooth*
   ordering (every adjacent pair at Hamming distance 1) realizes a complement/inversion pairing.
   Proof: within-pair Hamming distances under such a pairing are always even and nonzero
   (machine-checked in Lean via kernel `decide` since the 2026-07-27 migration; the evenness half,
   which alone rules out Gray adjacency, is also kernel-`decide`d as `within_even`; a two-line parity
   argument is in-text); Gray adjacency requires distance 1. **Scope, stated because this report had
   it wrong through v1.15:** the theorem covers McKenna and Mair's own all-complement pairing as
   readily as the classical one, so it is *not* a refutation of their construction — that construction
   is hybrid precisely because a fully smooth path is unavailable, applying the single-line step only
   between pair representatives (PEW 29:4 pp. 424–426), and it discards the classical
   28-inversion/4-complement pairing rather than keeping it. What the theorem does decide is that the
   received order cannot be smoothed into a Gray path. Their specific construction is separately
   evaluated directly, as the `reg_mmt3`–`reg_mmt6` scorers in `solve.py` record. (Also cite the modern complement: [Radisic 2026](../documentation/CITATIONS.md#radisic2026) proves the pairing is the
   unique Hamming-optimal comp/rev matching — the structure they discarded is, by a natural criterion, the
   optimal part of its class.)
4. **What their question opened** — the constructed-alternative methodology at scale; one forward pointer
   to the conflict result ([TR-2](TR2_THE_RULES_CONFLICT.md)) without developing it.

## Verification Guide (question → answer)
- **"How do we trust the 10³⁸ number?"** — a reproduce-command is given below, and the estimator is
  validated to <1% against exhaustive slices at overlapping scales. **One of §2's three rule rarities is
  independent of that estimator's absolute value:** the Schulz gender rule is also stated against the
  pair-only (C1) null, which is small enough to compute exactly and runnable on a laptop (§Commands),
  at 47/445740 = 1.054426×10⁻⁴. The other two — Moore parity ×1,362 and the 18:18 split ×2.7 — are
  C1–C5 registry masses only; **no pair-null value or command is published for either**, so §2 as it
  stands is not estimator-independent throughout. ⚠ **[CORRECTED 2026-08-30 —** v1.15 restated a drafting directive, "§2 can be written so that nothing depends on the estimator's absolute value", as a fact about the finished report, adding that "both nulls are labelled wherever they appear". Neither half
  held: only one of the three rarities has a pair-null restatement, and the executive summary was
  itself mislabelling one of the two nulls. See v1.16. Generalising the exact DP to the parity and
  18:18 rules is the fix that would make the stronger sentence true; it has not been done.**]** The two
  nulls are **different quantities**: the published ×11,364 is a C1–C5 mass fraction (≈8.80×10⁻⁵),
  while the pair-null exact figure is 1.054426×10⁻⁴ — the same order, not the same number.

### Commands
Run from a clone of the public repo (environment per METHODS.md); both tested 2026-07-03 on a 2-core
box.
- **Gray-code impossibility, for any complement/inversion pairing (§3):**
  `python3 -c "import solve; print(sorted({solve.bit_diff(a,b) for a,b in solve.king_wen_pairs()}))"`
  → `[2, 4, 6]` — every within-pair Hamming distance is even and nonzero, never 1, so no *fully smooth*
  ordering (all adjacent pairs at distance 1) can realize this pairing. Machine-checked form: `within_pair_even_nonzero` in
  `lean/KingWen.lean` (kernel `decide` since the 2026-07-27 migration; the evenness half also stands alone as `within_even`;
  `cd lean && lean KingWen.lean`, exit 0 — from inside `lean/`, so the pinned 4.31.0 toolchain is the one that runs; from the repo root elan uses its default instead, measured 2026-09-03). Runs in <1 s.
- **Pair-rarity — exact (§2, null (b) — the pair-only space):** the pair-only null is small enough to
  solve exactly, so this figure need not be sampled at all. `pair_null_gender_le2_exact` returns the exact
  rational probability that a uniformly random C1-preserving ordering matches KW's Schulz-gender compliance
  level (≤2 gender/parity violations — KW sits at exactly 2):
  ```
  python3 -c "import solve; p=solve.pair_null_gender_le2_exact(); print(p, '=', float(p))"
  ```
  → `47/445740 = 1.054426e-04` — an **exact** value (a DP over the pair-only null that aligns C1's pairs
  with the Schulz inversion classes; runs in <1 s), not a sampled estimate. It supersedes the earlier
  finite-sample figure `10/100000` and retires the F-31 precision caveat (that quick draw rested on 10
  hits, ±32% Poisson; now moot — the quantity is computed, not estimated). Seeded direct sampling
  reproduces it as an independent cross-check:
  ```
  python3 -c "import random,solve; rng=random.Random(42); P=solve.king_wen_pairs(); N=100000; sh=(lambda: (lambda q: (rng.shuffle(q), q)[1])(list(P))); hit=sum(solve.rc4_violations([x for a,b in sh() for x in ((b,a) if rng.random()<0.5 else (a,b))])[0]<=2 for _ in range(N)); print(f'{hit}/{N} = {hit/N:.5f}')"
  ```
  → order 10⁻⁴, consistent with the exact value within Poisson error (the sampler's station model is
  verified to agree with `rc4_violations` on every draw). The exact distribution is available via
  `solve.pair_null_gender_distribution_exact()`.
  This is the pair-null quantity; the published ×11,364 (C1–C5 mass fraction) reproduces via [TR-1](TR1_EIGHT_CENTURIES_MEASURED.md)'s
  registry pipeline ([`solve.py --registry-verify`](../documentation/SOLVE_C_CLI.md) gates + the population run in [TR-1](TR1_EIGHT_CENTURIES_MEASURED.md)'s Verification
  Guide; per-rule record in [LITERATURE_RULES_POPULATION_TESTS.md](../documentation/LITERATURE_RULES_POPULATION_TESTS.md)).
- "Is the Gray-code theorem yours?" -> elementary; stated with humility; Lean-checked file in repo.
- "AI assistance?" -> disclosed per repo policy; all results mechanically checkable independent of how
  they were found.

## Revision history
| Version | Date | Changes |
|---|---|---|
| v1.0 | 2026-07-04 | First public release |
| v1.1 | 2026-07-04 | Plain-language executive summary added; internal drafting TODOs resolved (figures kept as planned improvements) |
| v1.2 | 2026-07-10 | Reception history added: Hershock (1991), the one published reply to McKenna & Mair, acquired (ILL) and audited — philosophical critique, premise shared, neither claim tested; "sat untested" sharpened to "computationally untested" |
| v1.3 | 2026-07-11 | Process sections relocated: the venue-targeting line, the venue Q&A bullet, and the dormant journal-submission checklist moved out of the public report (process content, not findings; now maintained privately). "this journal" in the abstract made explicit (*Philosophy East and West*). No findings changed |
| v1.4 | 2026-07-11 | Trust-base wording precision: the within-pair evenness/nonzero lemma is `native_decide`-checked (extended trust base per lean/README.md), not "kernel-verified"; noted that the evenness half — which alone rules out Gray adjacency — is also kernel-`decide`d (`within_even`). No result changes |
| v1.5 | 2026-07-20 | **Statistical precision pass (adversarial-review F-31, F-32).** F-31: the pair-null figure `10/100000` rests on **ten hits**, so its Poisson error is ~±32% — it is now quoted as "order 10⁻⁴" rather than 1.0×10⁻⁴, with the N=10⁷ setting named as what to cite when the number carries weight. F-32: look-elsewhere context added — the extraction battery is frozen at 91 observables, so a Bonferroni-style global bar sits at ≈5.5×10⁻⁴, against which a per-rule rarity of order 10⁻⁴ is only marginally past, and the dof-matched comparison shows much of that margin is specification. No measurement changed |
| v1.6 | 2026-07-21 | **Pair-null figure made exact (retires F-31).** The pair-only (C1) null is small enough to solve in closed form: `solve.pair_null_gender_le2_exact()` returns the exact rational P(rc4_violations ≤ 2) = **47/445740 = 1.054426×10⁻⁴**, replacing the sampled `10/100000` and its ±32% caveat with a computed value (a DP that aligns C1's pairs with the Schulz inversion classes). Independently verified two ways — a from-scratch second DP reproduces 47/445740, and the station model agrees with `rc4_violations` on all 10⁵ random draws — with the seeded sampler retained as a cross-check. §Commands, §2 body, and the null-labeling caution updated; new `solve.py` functions `pair_null_gender_le2_exact` / `pair_null_gender_distribution_exact` + a `tests.py` regression guard. Exactness collapse: Claude (Opus 4.8), from the exactness pass; no qualitative conclusion changed |
| v1.7 | 2026-07-30 | **Ledger-terminology precision (novelty-gate editorial pass).** The F-32 look-elsewhere sentence called the 91-observable freeze "the suite's extraction battery"; the frozen 91 is the **enterprise-wide observable ledger** (METHODS.md §Global observable ledger: 28 exploratory extraction-battery + 58 + 5 = 91), of which the extraction battery proper is the 28-observable base. Wording aligned with METHODS; the 5.5×10⁻⁴ bar and every verdict unchanged |
| v1.8 | 2026-07-31 | **Trust-base label refreshed (kernel migration).** The §Commands note on `within_pair_even_nonzero` still carried v1.4's `native_decide` label; since the 2026-07-27 kernel migration the lemma is kernel `decide` (see lean/README.md's trust-base note). Label updated; no result changed |
| v1.9 | 2026-08-01 | **Two corrections from the 2026-08-01 in-house calibration review.** (i) §Executive summary's look-elsewhere aside said a per-rule rarity of order 10⁻⁴ read against 0.05 would suggest "~5,500×" — the correct factor is **~500×** (0.05 / 1.054×10⁻⁴ = 474; consistency check: 5.2 × the ledger factor 91 = 474). The sentence exists to *restrain* a naive margin and overstated it by 10×. (ii) §3's trust-base parenthetical still labelled `within_pair_even_nonzero` as `native_decide`; it is kernel `decide` since the 2026-07-27 migration — v1.8 fixed this label in §Commands but missed §3. No measurement, verdict, or certificate changed |
| v1.10 | 2026-08-01 | **Reproducibility flag on the dof-matched baseline (lens sweep unit q-tr1-tr2-tr8-tr10).** The executive summary's honesty calibration rests on an unreproducible number: the "median dof-matched KW-fitting predicate reaches a rarity near ~6×10⁻⁵". A repo-wide search finds no dof-matching function, no evidence bundle, no probe count, no seed, and no statement of what the ≈16-clause predicate space is or how predicates were drawn — while §Commands publishes runnable commands for both of the report's other quantitative claims. Since this is the claim licensing "King Wen is **not** claimed to be tail-extreme among comparably-specified predicates" — the suite's circularity firewall — the figure is now flagged in place as unreproduced, with the measurement that would settle it named. METHODS carries the matching disclosure (its pointer had also named a "CRITIQUE.md Q1" section that does not exist; corrected there the same day). The conclusion is unchanged and the direction is independently supported by the data-like/principled firewall; only the number's status is corrected. No measurement, theorem or certificate changed |
| v1.11 | 2026-08-02 | **Correction-family qualified on the look-elsewhere margin (unit d73-margin).** §Executive summary reported the global-bar margin as "a factor of ~5" without naming a correction family, while [METHODS.md](METHODS.md) §"Statistics conventions" (under **Correction-family disclosure**) reported that the family choice moves only one *verdict* in the suite. Both statements were true and both were under-qualified: they answer different questions (margins vs verdicts) and neither said which. The margin is now stated under **both** families — ~5× under Bonferroni, ≥~10× under BH-FDR at q = 0.05 — with the reason the BH figure is a floor rather than a point (BH's bar is rank-dependent, *i*·0.05/91, so the BH margin is exactly *i*× the Bonferroni margin; only *i* ≥ 2 is supported, forced by `dav_rotinv` at 6.5×10⁻⁵). A **~52×** figure that circulated for this rarity is recorded and **declined**: it is BH at rank *i* = 10, and rank 10 requires the nine registry masses METHODS withdrew from ranking on 2026-08-01. METHODS carries the matching scope split (its "only one verdict moves" sentence now says in place that it is about verdicts, and that margins are correction-specific and move by an order of magnitude with no verdict changing). Neither family is suppressed, because selecting the family that flatters a number is what makes a correction record dishonest. No measurement, verdict, theorem or certificate changed |
| v1.12 | 2026-08-02 | **Revision-table order repaired (doc_gates GATE 12, hardening item A4).** v1.11 was added by replacing the v1.10 line and re-adding v1.10 underneath (`85d3b2c`), so the table ran 2026-08-02 then 2026-08-01 and `*(current)*` was not its last row. The two rows are restored to chronological order with their text unchanged; no claim, figure, date or scope was altered. The same prepend mistake was live in TR-4 (repaired there as v1.17) |
| v1.13 | 2026-08-06 | **Benjamini–Hochberg cited at point of use (citation audit, UNASKED-7).** The executive summary's look-elsewhere margin has invoked "Benjamini–Hochberg FDR" since v1.11 without a source; the reference ([Benjamini & Hochberg 1995](../documentation/CITATIONS.md#benjamini-hochberg1995), *JRSS-B* 57(1)) is now in CITATIONS.md §Statistical methodology and linked where the FDR margin is stated. No figure, margin, or verdict changed |
| v1.14 | 2026-08-07 | **The dof-matched median is WITHDRAWN PENDING ARTIFACT ([CORRECTIONS](../documentation/CORRECTIONS.md) CX-27; operator-authorized action on the 18-lens red-team review).** v1.10 flagged the ~6×10⁻⁵ dof-matched median as unreproduced — no artifact, command, code path or evidence bundle anywhere in the repo — but left it in the executive summary doing load-bearing work: it is the single number that answers the predicate-specification objection in its own currency, and the look-elsewhere passage continued to lean on it ("the dof-matched comparison above shows…"). The figure and the "about half are at least as rare" comparison are now withdrawn as citable figures until the fix v1.10 itself specified exists: a `solve.py` sampler over the ≈16-clause KW-fitting predicate space, published with its seed and probe count, reporting the median rarity with a CI. The disclosure is kept, and the qualitative direction is kept as an acknowledged open question — it is conservative and argues against this suite's own rarity claims, and is independently supported by the data-like/principled firewall and TR-9's pricing — but the bulk-of-the-distribution placement is exactly as strong as the unpublished sampler behind it and is no longer claimed. The look-elsewhere sentence that leaned on the figure now reads "suggested", with the attribution-to-specification stated as open. No measurement with an artifact, theorem, certificate or verdict changed |
| v1.15 | 2026-08-29 | **Form labelling and author-directive removal (Q-352; the fix TR-2 took at v1.13 and TR-3 by being written out).** The heading read `Structure (4 sections)` over what are four **section summaries**, with no written-out §1-§4 beneath them — while the report ships a full technical-report masthead and [reports/README.md](README.md) lists it as a peer of TR-1..TR-11 with an evidence column, so a reader was invited to expect four sections that are not there. Relabelled `Structure — section summaries (4)` with a form note stating plainly what is summary and what is written out, and why §1/§4 deliberately stay summaries (humanities-register prose about what named scholars proposed). Three items carried planning voice addressed to the writer rather than the reader ("fair summary:", "One paragraph of historical respect:", "Table of measured rule rarities for THREE rules only", "Verifiability box:") and are rewritten as description. The Verification Guide carried two **instructions to the author** in published prose — "section 2 **can be written** so that NOTHING depends on the estimator's absolute value" and "**PREFER** the laptop-runnable framing throughout" — now stated as facts about the report the reader is holding: nothing in §2 depends on the estimator's absolute value, and both nulls are labelled wherever they appear. **Both of those fact-statements were false and are retracted at v1.16 below** — only one of §2's three rarities has a pair-null restatement, and the executive summary was mislabelling one of the two nulls at the time this row was written. Nothing is deleted: a dated row is a record of what that pass wrote. **Sibling sweep:** the Q-352 finding said TR-8 was the only report still containing author-directive text; that was not quite right — TR-2 items 2 and 4 carried "Method in one page:", "Verifiability box." and "One paragraph on … honestly", and those are converted in the same pass (TR-2 v1.28). No measurement, theorem, certificate, figure or verdict changed |
| v1.16 *(current)* | 2026-08-30 | **Three corrections: the Gray-code theorem re-scoped off a claim McKenna and Mair never made, and two defects created by the v1.15 correction pass itself.** **(i) SUBSTANTIVE — the impossibility result was mapped onto the wrong claim.** The executive summary (§"Second, by proof"), the abstract, and summary item 3 stated that "the specific smooth construction their proposal requires (a Gray-code-style path) is mathematically impossible for any ordering that keeps the classical pairing", and called the result decisive against their constructive proposal. That tests a conjunction their 1979 construction negates on **both** conjuncts. Their construction is **hybrid**: all 32 pairs are p'ang-t'ung complements — the classical 28-inversion/4-complement pairing is deliberately *replaced*, which is the proposal's own point — and the Gray-code single-line step governs only the transition between pair representatives, while the within-pair step changes all six lines (PEW 29:4 pp. 424–426, incl. Figure 2). Their published 64-position ordering is a constructive existence proof that what they proposed is not impossible, and it meets the requirement they stated: a single-line step at all 31 between-pair transitions. This report's own tree already said so — `solve.py`'s `reg_mmt6` docstring records "their own ordering achieves HD1 on all 31 inter-pair transitions", and item 3 called the classical pairing "the structure they discarded". **The parity theorem is untouched and remains machine-checked** (within-pair distances even and nonzero; the evenness half kernel-`decide`d as `within_even`); what changes is what it is said to decide. Re-scoped throughout to: no *fully smooth* ordering (every adjacent pair at Hamming distance 1) realizes **any** complement/inversion pairing — including McKenna and Mair's own, which is exactly why their construction has to be hybrid — and the received order cannot be smoothed into a Gray path. Their *position* is answered by §2's premise measurement, not by an impossibility. The credit paragraph is unchanged. No number, certificate, or Lean artifact changes; this is a published-wording mis-mapping of a correct theorem. **Sibling still outstanding, reported not fixed here:** [CITATIONS.md](../documentation/CITATIONS.md)'s McKenna & Mair entry carries the same framing ("its construction refuted (with credit)"; "no Gray-code ordering can satisfy the pairing constraint at all") and needs the same re-scoping; [CRITIQUE.md](../documentation/CRITIQUE.md)'s Claim 2 was checked and is **correctly** scoped already. **(ii) The v1.15 pass converted an author-directive into a false certification.** v1.15 restated "§2 **can be written** so that NOTHING depends on the estimator's absolute value" as the fact "nothing in §2 depends on the estimator's absolute value: every rarity is also stated against the pair-only (C1) null", and added "both nulls are labelled wherever they appear". Measured: §2 reports three rule rarities over the C1–C5 population (Moore parity ×1,362; Schulz gender ×11,364; the 18:18 split ×2.7) and re-measures **only** gender against the pair-only null; no pair-null value or command exists for the other two. And the executive summary anchored its look-elsewhere margins on **1.054426×10⁻⁴** — the pair-null exact value, re-executed 2026-08-30 as `solve.pair_null_gender_le2_exact()` = 47/445740 — while calling that quantity "a literature-rule **registry mass**", which is the *different* ×11,364 figure (≈8.80×10⁻⁵). Both sentences are narrowed to what is true, and the two quantities are separated where the margins are stated. **No published margin moves**: on the registry mass the margins would be ~6.2× Bonferroni / ≥~12.5× BH, so the published ~5× / ≥~10× understate the margin — the error ran against interest. Every underlying quantity reproduces under its own null. **(iii)** The v1.15 row's own sibling-sweep pointer said the matching TR-2 conversions landed at "TR-2 v1.24"; v1.24 is TR-2's convergence-gate-figure supersession row (2026-08-02) and the Q-352 sweep is **v1.28** (2026-08-29), as [CORRECTIONS.md](../documentation/CORRECTIONS.md) already records. Pointer corrected. No measurement, theorem, certificate or verdict changed by any of the three |
