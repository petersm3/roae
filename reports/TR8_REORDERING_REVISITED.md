# TR-8 — A Reordering Revisited: Two Computational Answers to McKenna and Mair (1979)

*Technical report — not peer-reviewed. Every claim is machine-verifiable; see the Verification Guide below.*

Methods, environment pinning, statistics conventions, and artifact access: see [METHODS.md](METHODS.md).

## Executive summary

In 1979, [McKenna and Mair](../documentation/CITATIONS.md#mckenna-mair1979) proposed that the King Wen sequence would be "better" reordered — that a
rearrangement could smooth its irregularities. The proposal drew one published reply — a philosophical
critique ([Hershock 1991](../documentation/CITATIONS.md#hershock1991)) that rejected its method but
shared its premise and tested neither claim — and sat computationally untested for 47 years. This report
answers it twice. First, by measurement: the properties their argument assumed to be defects are, when
checked against the space of valid orderings, among the sequence's rarest and most distinctive features
— removing them removes what is special. Second, by proof: the specific smooth construction their
proposal requires (a Gray-code-style path) is **mathematically impossible** for any ordering that keeps
the classical pairing — a two-line parity argument anyone can verify by hand. The refutation is offered
with credit: theirs was a concrete, falsifiable proposal, which is exactly what made it answerable.

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
order of rarity for the gender rule). Second — and decisively for
their constructive proposal — no Gray-code ordering can satisfy the pair structure at all: consecutive
partners in the received order differ in two, four, or six lines, never one, so a sequence in which every
adjacent pair differs in a single line cannot reproduce the pairing (a two-line proof). McKenna and Mair
retain a distinction that should be credited plainly: theirs was the first proposal to evaluate the
received order against an explicitly constructed alternative — the methodological seed of the present
analysis. We supply the instruments their question required.

## Structure (4 sections)
1. **The 1979 position** — fair summary: their premise (no defensible global structure), their proposal
   (Gray-code reordering starting from Kun), their motivation. One paragraph of historical respect: first
   constructive test proposal in the literature. Reception note: the only published reply we have located
   ([Hershock 1991](../documentation/CITATIONS.md#hershock1991), JCP) critiqued their method on
   philosophical grounds while sharing their premise of global randomness and proposing a mandala
   reordering of his own — so the premise itself went unmeasured, and the construction's feasibility
   undecided, until now.
2. **The premise, measured** — two null populations, stated precisely (they are different spaces and give
   different numbers): (a) the C1–C5 constraint-satisfying population (≈1.33×10³⁸ orderings, estimator
   validated against exhaustive slices) — this is the population over which the quoted rarities are
   mass fractions; note C2/C5 are themselves regularities read off the received order, so this null is
   conservative, not "undisputed"; (b) the pair-only (C1) space, 32!·2³² ≈ 1.1×10⁴⁵ — the truly
   undisputed structure, checkable by direct seeded sampling on a laptop (Commands below). Table of
   measured rule rarities for THREE rules only (over population (a): [Moore](../documentation/CITATIONS.md#moore2005) parity ×1,362; [Schulz](../documentation/CITATIONS.md#schulz1990-motifs) gender
   ×11,364; the 18:18 split ×2.7 as the honest weak case; the gender rule re-measured against null (b)
   by direct sampling lands at the same order, ~1×10⁻⁴) with sources credited (rules are
   Zhu Yuansheng/Schulz/Moore observations, not ours; measurement is ours). Verifiability box: exact
   commands, open repository.
3. **The proposal, decided** — Theorem: no Gray-code ordering satisfies the pair structure. Proof:
   within-pair Hamming distances are always even and nonzero (machine-checked in Lean via
   `native_decide` — extended trust base per lean/README.md; the evenness half, which alone rules out
   Gray adjacency, is also kernel-`decide`d as `within_even`; a two-line parity argument is in-text);
   Gray adjacency requires distance 1. Their specific construction
   also evaluated directly. (Also cite the modern complement: [Radisic 2026](../documentation/CITATIONS.md#radisic2026) proves the pairing is the
   unique Hamming-optimal matching — the structure they discarded is, by a natural criterion, the optimal
   part.)
4. **What their question opened** — the constructed-alternative methodology at scale; one forward pointer
   to the conflict result ([TR-2](TR2_THE_RULES_CONFLICT.md)) without developing it.

## Verification Guide (question → answer)
- "How do we trust the 10³⁸ number?" -> reproduce-command; validated <1% vs exhaustive slices at
  overlapping scales; but NOTE: section 2 can be written so that NOTHING depends on the estimator's
  absolute value — rarities can ALSO be stated vs the pair-only (C1) null by direct sampling
  (laptop-runnable; Commands below). CAUTION: the two nulls are different quantities — the published
  ×11,364 is a C1–C5 mass fraction; the pair-null sampled figure is ~1×10⁻⁴ (same order, not the same
  number). PREFER the laptop-runnable framing throughout, with both nulls labeled.

### Commands
Run from a clone of the public repo (environment per METHODS.md); both tested 2026-07-03 on a 2-core
box.
- **Gray-code impossibility (§3):**
  `python3 -c "import solve; print(sorted({solve.bit_diff(a,b) for a,b in solve.king_wen_pairs()}))"`
  → `[2, 4, 6]` — every within-pair Hamming distance is even and nonzero, never 1, so no Gray-code
  ordering can realize the pairing. Machine-checked form: `within_pair_even_nonzero` in
  `lean/KingWen.lean` (`native_decide`; the evenness half is also kernel-`decide`d as `within_even`;
  `lean lean/KingWen.lean`, exit 0). Runs in <1 s.
- **Pair-rarity direct sampling (§2, null (b) — the pair-only space, seeded per METHODS.md):**
  ```
  python3 -c "import random,solve; rng=random.Random(42); P=solve.king_wen_pairs(); N=100000; sh=(lambda: (lambda q: (rng.shuffle(q), q)[1])(list(P))); hit=sum(solve.rc4_violations([x for a,b in sh() for x in ((b,a) if rng.random()<0.5 else (a,b))])[0]<=2 for _ in range(N)); print(f'{hit}/{N} = {hit/N:.5f}')"
  ```
  → `10/100000 = 0.00010` (fraction of uniformly-sampled pair-preserving orderings matching KW's
  Schulz-gender compliance level, ≤2 violations; ~5 s at 10⁵ samples on 2 cores, ~8 min at 10⁷).
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
