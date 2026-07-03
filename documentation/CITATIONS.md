# Citations and Prior Literature

This document lists prior published work on the mathematical structure of the King Wen sequence and the methodological/algorithmic sources underlying ROAE's computations. Its purpose is to be honest about what is **independently verified** here versus what is **novel to ROAE**.

> **Disclaimer.** This list is **not exhaustive**. Scholarship on the I Ching spans three millennia, multiple languages (primarily Chinese, with significant secondary literature in Japanese, English, German, and French), and several fields (sinology, combinatorics, philosophy, comparative religion, mathematical recreation, psychedelic studies). Omissions are unintentional. **If you are aware of prior work not cited here, or see a claim below that should be updated or corrected, please submit a pull request** against this repository (`petersm3/roae`) with the proposed addition or correction. Opening an issue is also fine for cases where you'd like to discuss before editing. Additions and clarifications are welcome and will be incorporated; pull requests make it easiest to track attribution of the contribution back to the submitter.

---

## Prior observations about King Wen mathematical structure

### C1 — pair structure (reverse / inverse / complement pairs)

The pairing of the 64 hexagrams into 32 consecutive reverse-or-complement pairs is a **classical observation**, not novel to any modern author. It appears in the earliest layers of I Ching commentary (the *Yi Zhuan* or "Ten Wings," traditionally attributed to Confucius, ~5th–3rd c. BCE, though modern dating is later). The explicit modern formulation is given in:

- **Wilhelm, Richard and Baynes, Cary F. (trans.)** (1967). *The I Ching or Book of Changes*. 3rd edition, Princeton University Press / Bollingen Series. The pairing convention is used throughout. ISBN 978-0-691-09750-3.
- **Cook, Richard S.** (2006). *Classical Chinese Combinatorics: Derivation of the Book of Changes Hexagram Sequence* (周易卦序詮解 Zhouyi Guaxu Quanjie). STEDT Monograph Series Vol. 5, University of California, Berkeley, 656 pages. ISBN 978-0944613443. Cook's monograph is the most rigorous academic treatment; it derives the full hexagram sequence from combinatorial principles and situates the pair structure within broader classification of binary sequences. **Preview pages (front cover, abstract, TOC, introduction, acknowledgments — 19 pages total)** available online at the author's UC Berkeley page: [linguistics.berkeley.edu/~rscook/images/CCCprev/CCCprev.html](https://linguistics.berkeley.edu/~rscook/images/CCCprev/CCCprev.html). The full 656-page monograph is print-only as of 2026-05; library copies via OCLC 77009740 or purchase via [STEDT Web Store](http://www.lulu.com/stedt) (ISBN 0-944613-44-6).

**Status in ROAE:** ROAE independently encodes this rule as constraint C1 and uses it as the starting point of the enumeration. Not novel to ROAE.

### C2 — absence of 5-line transitions

The observation that consecutive hexagrams in the King Wen sequence **never differ by exactly five lines** is attributed to Terence McKenna.

- **McKenna, Terence and McKenna, Dennis** (1975). *The Invisible Landscape: Mind, Hallucinogens, and the I Ching*. Seabury Press, New York (reprinted HarperCollins 1994, ISBN 0-06-250635-8 / 978-0062506351). The "first-order of difference" analysis appears in **Part Two, Chapter 9 ("Order in the I Ching and Order in the World")**. McKenna explicitly states "a perfect ratio of three to one; three even integers to each odd integer" and gives the count as "fourteen threes and two ones constitute sixteen instances of an odd integer occurring out of a possible sixty-four" — confirming he was using the **circular reading** (64 transitions including the wrap-around s₆₃ → s₀, which has Hamming distance 3 in King Wen). Figure 17 (Table II, "Change in the King Wen Sequence") enumerates the full difference-wave histogram pair-by-pair. In the same chapter McKenna formalizes the sequence design under three rules: (1) absolutely exclude transitions of value 5 (= our **C2**); (2) minimize transitions of value 1 except where doing so would force a value 5 — empirically measured at the d3 560T canonical 2026-06-15 (`9a968fa2…`, 10,525,271,997 records: 80.03% of C1-C5 records violate it; KW is in the 19.97% minority that obeys it). **NOT promoted to a formal C-rule** — it would be reverse-engineered from KW's specific value-1 placements without first-principles or independent-corroboration support; see MCKENNA.md for the peer-review-defensibility analysis; (3) maintain a three-to-one ratio of even to odd transitions (= our **Theorem on wrap-around parity**, since 3:1 circular is a consequence of C4 + C5 + the XOR parity identity).
- *Status of earlier references:* The 1975 first edition (Seabury Press) contains the same I Ching analysis as the 1994 HarperCollins reprint; the work was reprinted, not revised. The underlying intuitions date to the McKennas' 1971 Amazonian expedition (see *True Hallucinations*, 1993, and Timewave-Zero biographical sources). No pre-1975 peer-reviewed paper or published lecture transcript on the I Ching analysis has been located via open web sources.
- Cook (2006) also presents the 5-line absence as part of the broader combinatorial analysis; independently derived within his framework.

**Status in ROAE:** ROAE encodes this as constraint C2 and independently verifies it across the canonical datasets. We do not claim originality for the observation itself; ROAE's contribution is the **exhaustive null-model testing** (see §Methodology below) which shows C2 is essentially unreachable in de Bruijn and random permutation families, and the **analytic decomposition** of why Latin-square row×col traversals satisfy C2 at 57.96% rate (believed novel; see [CRITIQUE.md](CRITIQUE.md)).

### C3 — complement distance minimization

The observation that King Wen positions complementary hexagrams (bitwise-opposites) unusually close to each other — formally, that the total positional distance $\sum_{v} |pos(v) - pos(\overline{v})| = 776$ is near-minimal among C1-satisfying orderings — is **not found in the prior published literature reviewed here**.

- Cook (2006) does not, to our reading of reviews and summaries, present this specific property.
- McKenna (1975) does not present it.
- No prior peer-reviewed citation is known to the author.

**Status in ROAE:** We believe C3 as a specifically-quantified constraint (776 as the KW value, 3.9th percentile within C1-satisfying orderings) is an original observation. If prior work exists, please notify — we will credit appropriately.

**Scope qualifier (added 2026-04-20 after d3 100T enumeration):** KW is near-extremal on C3 *within C1-only orderings*, but once the full C1+C2+C3 canonical is enumerated, **KW sits at the C3 ceiling (776), not the floor**. Minimum C3 in the 100T d3 canonical is 424 (221 records); the 95th-percentile records also tie with KW at 776 (9.91% of canonical orderings). So within the conjoint C1+C2+C3 frame, KW's C3 value is a *jointly satisfied upper bound* that many other orderings match, not a distinguishing minimum. The "minimizes complement distance" framing of C3 applies specifically to the C1-only comparison population and should not be generalized. See [SOLVE.md](SOLVE.md) §Rule 3 revision and [DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md).

### Pair structure + no-5-line + complement proximity as a *joint* constraint system

The framing of C1+C2+C3 as a specific system that narrows 10^89 orderings to ~700 million is ROAE-specific. Individual constraints appear in prior work; the conjunction, the exhaustive enumeration under the conjunction, and the 4-boundary / pair-stability analysis are ROAE-original.

### Fu Xi ordering, binary representation

- **Leibniz, Gottfried Wilhelm** (1703). "Explication de l'arithmétique binaire, qui se sert des seuls caractères 0 et 1, avec des remarques sur son utilité, et sur ce qu'elle donne le sens des anciennes figures chinoises de Fohy." *Mémoires de l'Académie royale des Sciences*. Shows correspondence between Fu Xi's binary ordering and the natural binary count 0–63.
- **Shao Yong** (邵雍, 1011–1077 CE). *Huangji jingshi shu* (皇極經世書). Developed the circular/square binary arrangement (xiantian diagram) that Leibniz later rediscovered.

### Mawangdui silk-text ordering

- **Shaughnessy, Edward L.** (1996). *I Ching: The Classic of Changes* (Mawangdui Texts). Ballantine Books. ISBN 978-0345362438. Translation and analysis of the 168 BCE Mawangdui silk manuscripts' alternative hexagram ordering.

ROAE observation that **both Mawangdui and Jing Fang 8 Palaces satisfy C2** (zero 5-line transitions) while failing C1 and C3 is, to our knowledge, a novel comparative finding. Combined with King Wen, this gives three of four tested ancient Chinese hexagram orderings satisfying C2 exactly — reframing McKenna's observation as likely a **classical Chinese design principle** shared across multiple traditions rather than unique to King Wen. Surfaced here during null-model testing (`./solve --null-historical`). See also:

- **Jing Fang** (京房, 77–37 BCE). The *Ba Gong Gua* (八宫卦) arrangement is preserved in traditional Yi Jing commentary and divinatory practice. The specific "origin → five worlds → wandering soul (游魂) → returning soul (归魂)" convention ROAE uses follows standard sinological sources. Alternative orderings within the same palaces exist; PR welcome for corrections. Traditional attribution of the arrangement to Jing Fang; historical certainty of the full ordering is debated in scholarly literature.

---

## Independent statistical analyses of King Wen vs random permutations

The following projects independently measure statistical properties of
the King Wen sequence by comparing it against a population of random
permutations of all 64 hexagrams. ROAE's framing is different — we
enumerate the space of orderings satisfying constraints C1–C5 and
compare KW against THAT distribution — but several of our findings
align mathematically with this body of work and ROAE should
acknowledge prior/parallel statements of the same phenomenon where
applicable.

- **Chan, Augustin** (2026-04-10). *Statistical Properties of the
  King Wen Sequence: An Anti-Habituation Structure That Does Not
  Improve Neural Network Training*. arXiv:2604.09234.
  ([arxiv.org/abs/2604.09234](https://arxiv.org/abs/2604.09234)).
  Code and data:
  [github.com/augchan42/king-wen-agi-framework](https://github.com/augchan42/king-wen-agi-framework);
  Zenodo archive DOI: 10.5281/zenodo.14679537.

  Negative-result study examining whether King Wen's statistical
  properties translate to neural-network training benefits (Chan
  concludes no). Reports Monte Carlo permutation analysis against
  100,000 random baselines.

  **Timing relationship to ROAE: Chan's underlying research
  predates ROAE's enumeration work.** The GitHub repository's
  commit history shows substantive King Wen analysis activity
  clustering in early 2025 through March 2026, indicating
  ~12+ months of prior development. The arXiv preprint was
  submitted 2026-04-10, which was contemporaneous with ROAE's
  project start (April 10-11, 2026 per `HISTORY.md`), but the
  *underlying research findings* in the paper were developed
  prior to ROAE's existence. **Where ROAE makes claims that
  match Chan's findings, those should be acknowledged as prior
  art rather than parallel discovery.** ROAE arrived at the
  same mathematical observations (specifically: KW's mean
  Hamming distance, lag-1 autocorrelation, within/between-pair
  asymmetry) independently and via different methodology, but
  Chan published first.

  The arXiv preprint is the formal publication; the GitHub
  repository is the code, paper sources, and reproducibility
  materials.

  Five reported statistical properties of King Wen, of which
  several **overlap with ROAE's findings as the same phenomenon
  under different framing**:

  1. **Mean Hamming distance between consecutive hexagrams: 3.35**
     (98.2nd percentile vs random; sigma=0.15). ROAE's C5 enforces
     the exact distance-distribution multiset
     `{1: 2, 2: 20, 3: 13, 4: 19, 6: 9}`, whose mean is exactly
     `(1·2 + 2·20 + 3·13 + 4·19 + 6·9) / 63 = 211/63 ≈ 3.349`.
     **Same number, same phenomenon** — augchan42 measures it
     statistically vs random permutations; ROAE encodes it as a
     hard constraint. Either framing is valid; readers should be
     aware of both.
  2. **Lag-1 autocorrelation of Hamming distances: −0.251**
     (3.7th percentile, p=0.037 — large transitions followed by
     small). ROAE's `CRITIQUE.md` independently reports the
     Wald-Wolfowitz runs test on the difference wave detecting
     alternation (Z=+2.13, p=0.033). **Same phenomenon, similar
     significance, different statistical tests.** ROAE notes the
     finding does not survive Bonferroni correction across our
     test battery (threshold p<0.0018); augchan42's measurement
     stands on its own without multiple-comparison correction.
  3. **7/16 groups of four consecutive hexagrams have exactly 12
     yang lines** (99.8th percentile, p=0.002). **NOT measured in
     ROAE's analyses.** This is unique to augchan42 and we do not
     claim it. If a future ROAE analysis investigates yang-balance
     in groups of consecutive hexagrams, this finding should be
     attributed to augchan42.
  4. **Within-pair vs between-pair Hamming-distance asymmetry:
     0.63 coefficient** (99.2nd percentile). ROAE's C1 (pair
     structure) STRUCTURALLY forces within-pair distances into
     `{0, 2, 4, 6}` via the reverse/complement construction
     (Hamming-2 for reverse-pair, Hamming-6 for complement-pair),
     while between-pair distances are unrestricted. ROAE's
     `CRITIQUE.md` notes this structural consequence. **Same
     phenomenon, different framing** — augchan42 measures the
     resulting asymmetry as statistical surprise vs random; ROAE
     encodes the underlying structure as constraint C1.
  5. **Surprise distribution variance: KW 0.390 vs random 0.202**
     (Levene's test p=0.009). **NOT measured in ROAE's analyses.**
     Information-theoretic surprise framing is unique to augchan42's
     work.

  **Methodological independence note.** ROAE's enumeration approach
  (3.4B canonical orderings under C1+C2+C3+C4+C5 at 100T-d3) and
  augchan42's Monte Carlo approach (KW vs 100K random permutations)
  are complementary, not redundant: each addresses a different
  baseline. ROAE characterizes KW relative to other constraint-
  satisfying orderings; augchan42 characterizes KW relative to
  arbitrary permutations. A claim like "KW maximizes inter-state
  change at the 98.2nd percentile" is true in augchan42's frame
  (vs random) and tautological in ROAE's frame (C5 enforces the
  exact distribution); a claim like "KW sits at the C3 ceiling
  among C1+C2+C3-satisfying orderings" is true in ROAE's frame
  and not directly addressed in augchan42's.

  **What ROAE should cite vs not.** When ROAE makes claims that
  touch findings 1, 2, or 4 above (mean Hamming distance,
  lag-1 autocorrelation, within/between-pair asymmetry), the
  augchan42 paper should be cited as parallel/independent
  statement of the same observation. Findings 3 (yang-balanced
  groups of 4) and 5 (surprise distribution variance) are
  augchan42-original; ROAE should not claim them and should
  attribute them when discussing.

## de Bruijn sequences and I Ching

The natural correspondence between B(2, 6) de Bruijn sequences (cyclic 64-bit sequences containing every 6-bit window exactly once) and permutations of the 64 hexagrams has been noted in the I Ching literature and online discussion, though usually in passing rather than as a systematic study:

- **Online discussions** (e.g., the [I Ching Community](https://www.onlineclarity.co.uk/friends/archive/index.php/t-10608.html) forum) have pointed out the correspondence, sometimes citing classical Chinese figures like **Yang Xiong** (楊雄, 53 BCE – 18 CE) as having anticipated de Bruijn-like structures in the *Taixuanjing* (*Canon of Supreme Mystery*), which uses ternary rather than binary.
- **van Aardenne-Ehrenfest, T. and de Bruijn, N. G.** (1951). "Circuits and trees in oriented linear graphs." *Simon Stevin* 28: 203–217. The BEST theorem; used by ROAE to count B(2, 5) Eulerian circuits (= 2^27 = 134,217,728 with fixed starting vertex).

ROAE's **exhaustive enumeration of all 2^27 B(2, 6) permutations and analytic proof that 0 satisfy C1** (via the period-4 contradiction) is believed novel. If a prior rigorous null-model test of B(2, 6) permutations against King Wen's structural constraints exists, please notify.

### Gray codes and I Ching

- **Gardner, Martin** (various columns, *Scientific American*, 1960s–1970s). Discussed binary Gray codes and noted connections to combinatorial structures including the I Ching at times.
- **Savage, Carla D.** (1997). "A survey of combinatorial Gray codes." *SIAM Review* 39: 605–629. Standard reference on Gray code families.

ROAE's **analytic proof that no 6-bit Gray code satisfies C1** (Hamming-1 adjacency is disjoint from C1's required {0, 2, 4, 6}) is believed novel but straightforward; it follows trivially from the Gray code definition.

---

## Methodological and algorithmic citations

### Enumeration algorithms

- **Hierholzer, Carl** (1873). "Ueber die Möglichkeit, einen Linienzug ohne Wiederholung und ohne Unterbrechung zu umfahren." *Mathematische Annalen* 6(1): 30–32. Eulerian-circuit algorithm, used by ROAE's randomized de Bruijn sampler.
- **Fisher, R. A. and Yates, F.** (1938). *Statistical Tables for Biological, Agricultural and Medical Research* (3rd ed.), Oliver & Boyd, London. Fisher-Yates shuffle algorithm, used in `--null-random` and `--null-pair-constrained`.

### Random number generation

- **Marsaglia, George** (2003). "Xorshift RNGs." *Journal of Statistical Software* 8(14): 1–6. Xorshift64 variant used in `--null-random` and `--null-pair-constrained`.

### Statistical methodology

- **Wilson, E. B.** (1927). "Probable inference, the law of succession, and statistical inference." *Journal of the American Statistical Association* 22: 209–212. Wilson score interval, used for confidence intervals on the null-model proportions.
- **Bonferroni, Carlo Emilio** (1936). "Teoria statistica delle classi e calcolo delle probabilità." *Pubblicazioni del R Istituto Superiore di Scienze Economiche e Commerciali di Firenze*. Bonferroni correction for multiple testing.
- **Rule of Three** for upper bounds on zero-observed-event rates: see Hanley & Lippman-Hand (1983), "If nothing goes wrong, is everything all right? Interpreting zero numerators." *JAMA* 249(13): 1743–1745.

### File formats and cryptographic hashing

- **National Institute of Standards and Technology** (2015). "Secure Hash Standard (SHS)." *FIPS PUB 180-4*. SHA-256 specification, used for the canonical `solutions.bin` integrity anchor.

### Combinatorial identities

- **van Aardenne-Ehrenfest, T. and de Bruijn, N. G.** (1951). Listed above under de Bruijn; also the reference for the BEST theorem enumeration of de Bruijn sequences: for B(2, n), the count of distinct cyclic sequences is $2^{2^{n-1}-n}$, which at n=6 gives $2^{26} = 67{,}108{,}864$ (= half of the 2^27 rooted Eulerian circuits that ROAE's `--null-debruijn-exact` enumerates).

---

## Integer Sequences (OEIS)

- **[A102241](https://oeis.org/A102241)** — King Wen binary encoding of the 64 hexagrams. Used as the source of ROAE's `binary_hexagrams` constants in `roae.py`.

---

## Software and tool citations

- **OpenMP**, **POSIX threads** — parallelism in `solve.c`.
- **GCC** (GNU Compiler Collection) with `-O3`. Specific version and build flags documented in [DEVELOPMENT.md](DEVELOPMENT.md).
- **Python 3.x standard library** (no third-party dependencies used in `solve.py`, `roae.py`, `verify.py`, `null_compare.py`).

---

## What is original to ROAE (to the best of this author's knowledge)

Subject to the disclaimer at the top of this document, the following are believed to be ROAE-original contributions:

1. **Partition Invariance theorem** — the guarantee that the canonical `solutions.bin` sha256 is byte-identical across hardware, region, thread count, and merge algorithm for fixed solver + input parameters. Formal statement in [PARTITION_INVARIANCE.md](PARTITION_INVARIANCE.md).
2. **4-corners validation grid** — cross-SKU, cross-region, cross-merge-algorithm empirical confirmation of partition invariance. See [HISTORY.md](HISTORY.md) and [SOLVE.md](SOLVE.md).
3. **Exhaustive enumeration under the C1+C2+C3 conjunction at 10T, 100T, and 560T scale** — 10,525,271,997 d3 560T (sha `9a968fa2…`, 2026-06-08, **current deepest**) / 3,432,399,298 d3 100T (sha `915abf30…`) / 706,422,987 d3 10T / 286,357,503 d2 10T. Revealed that the boundary-minimum is partition + scale-dependent and NON-MONOTONE with scale (greedy-ordered minimum: 4 at 10T, 5 at 100T, 4 again at 560T; unordered working 4-set count drops 8 → 0 across 11.2T → 560T — see [SOLVE-SUMMARY.md](SOLVE-SUMMARY.md) §"560T canonical results") and that KW sits at the C3 ceiling, not the floor, reaffirmed at 560T.
4. **Comprehensive null-model testing framework** — seven structured and unstructured permutation families tested via `solve.c --null-*` subroutines: de Bruijn, Gray, Latin-square, lexicographic, historical, random, pair-constrained.
5. **Analytic C1 impossibility proofs** for the de Bruijn B(2, 6) family (period-4 contradiction) and the Gray code family (Hamming-1 disjoint). See [CRITIQUE.md](CRITIQUE.md).
6. **Latin-square C2 rate decomposition** — analytic explanation of the 57.96% rate as a function of row-permutation class (Hamiltonian-path popcount distribution in the 3-cube). See [CRITIQUE.md](CRITIQUE.md).
7. **Partition-stability analysis** — the finding that boundaries {25, 27} are mandatory in every working 4-boundary set at BOTH d2 and d3, while the other two boundaries are partition-dependent.
8. **Mawangdui C2 observation** — that the ancient silk-text ordering accidentally satisfies C2 (zero 5-line transitions) while failing C1 and C3.
9. **C3 total complement distance as a specifically quantified constraint** — 776 (= 12.125 × 64) as the King Wen value, positioning KW at the 3.9th percentile within C1-satisfying orderings.
10. **Format v1 `solutions.bin`** — canonical binary format with 32-byte header + 32-byte records, designed for partition-invariant sha256 reproducibility.

Each of the above claims to originality is **tentative** — if you find prior work establishing any of them, please contact the author and this document will be updated.

## Attributed candidate rules under population test (2026-07-02)

The following King Wen structural rules are **externally attributed** — ROAE did not discover them. ROAE's
contribution is limited to formalizing each rule in the C1–C5 pair representation and measuring the fraction
of the constraint-satisfying population that exhibits it (unbiased weighted-Knuth estimation). Any future
promotion of these rules into the formal constraint system carries these credits.

- **Final-pair anchor** (the perfectly-alternating pair closes the sequence) and **first-7-pairs level
  coverage** (the first seven pairs exhibit all seven yang-count levels): **Cook, Richard S.,** *Classical
  Chinese Combinatorics: Derivation of the Book of Changes Hexagram Sequence*, STEDT Monograph Series 5,
  Berkeley, 2006 (his subset-sB terminal rule and "seven levels" opening constraint). For a critical
  review of Cook's derivation see J. Drasny's review at biroco.com/yijing/cook.htm.
- **18:18 two-part class split** (18 inversion-classes in each half of the text): classical observation —
  **Zheng Qiao** (c. 1104–1162) and **Hu Yigui** (b. 1247, the 36-figure condensation); modern treatment
  **Hacker, E. & Moore, S.,** "A brief note on the two-part division of the received order of the hexagrams
  in the Zhouyi," *Journal of Chinese Philosophy* 30:2 (2003), 219–221; also Cook 2006.
- **Pair-positioning parity rule** (yang-preponderant pairs at odd pair-positions, yin-preponderant at even;
  14 balanced pairs exempt; King Wen complies 16/18 with the two violations at adjacent pair positions
  22–23): **Moore, Steve,** "Structural Elements in the King Wen Sequence of Hexagrams," *Oracle Papers*
  No. 1, London, 2005 (revised from *The Trigrams of Han*, Aquarian Press, 1989, pp. 188–198), building on
  the *Dazhuan* odd=Heaven/yang, even=Earth/yin attribution. Moore also conjectured a fully-compliant
  (18/18) precursor ordering; ROAE's population measurement addresses that conjecture empirically.
- **Gender/position-parity rule over the 36 consolidated units** (the strongest measured literature
  discriminator, ×11,364): **Schulz, Larry J.,** "Structural motifs in the arrangement of the 64 gua in the
  Zhouyi," *Journal of Chinese Philosophy* 17:3 (1990), 345–358 — his second motif, incl. the exceptions at
  stations 25–26; elaborated by Cook 2006 (attribution corrected 2026-07-03 upon first-hand reading; Cook
  had been credited as primary). The lineage extends further back: per Schulz 2018 (fn. 42), the single
  exception to the parity rule was first recognized by **Zhu Yuansheng (13th century)**. Schulz's later
  treatments: "Structural Elements in the Zhou Yijing Hexagram Sequence," *JCP* 38:4 (2011), 639–665
  (formalizes the "exception-proves-the-rule" design principle); *Hexagrammatics: Rules and Properties in
  Binary Sequences*, 2nd ed. (Zizai, 2016); "N Gua Theory" (ResearchGate, 2018). The companion seasonal
  hypothesis: Schulz & Cunningham, "The Seasonal Structure Underlying the Arrangement of Hexagrams in the
  Yijing," *JCP* 17 (1990), 289–313. Schulz's first motif (balance-value pairing) and third (xiaoxi trisection,
  with Schulz & Cunningham 1988 seasonal hypothesis) are under population test as R-S2/R-S1. The pair
  structure's classical lineage runs to **Yu Fan (220–265 AD)** (pangtong/fandui, via Li Dingzuo) and the
  36-unit consolidation + 18:18 reasoning to **Lai Zhide (1525–1604)**; **Davis, Scott,**
  *The Classic of Changes in Cultural Context* (Cambria, 2012) and "Operating the Yijing Apparatus,"
  *The Oracle* 2:7 (1998).

## First-principles optimality of the pairing (C1) — Radisic 2026

**Radisic, Alejandro.** "Optimal Equivariant Matchings on the 6-Cube, With an Application to the King Wen
Sequence." arXiv:2601.07175 (v3, May 2026). Proves (Lean 4 + Mathlib verified) that among comp/rev
matchings on {0,1}⁶ there is a **unique Hamming-cost minimizer** — the reverse-priority rule, which is
exactly this project's `partner()` function / the C1 pairing — with cost 120 (vs 192 complement-only;
independently confirmed by our within-pair distance table 2×12+4×12+6×8 = 120); that the King Wen sequence
realizes precisely this matching; and that under the full Klein four-group the King Wen rule is recovered
as the unique Hamming-weight-preserving optimum (stable for the energy α|Δw|+βd_H whenever α > β).
**Effect on this project's claims:** C1's provenance upgrades from "classical + measured-rare" to
"classical + measured-rare + *derived as the unique optimum of a natural variational principle*" — the
first genuine first-principles derivation of any layer of the constraint system, and it is Radisic's, not
ours. His weight-conservation principle is the exact-preservation strengthening of the parity-preservation
lemma underlying [PARITY_ALTERNATION.md](PARITY_ALTERNATION.md); his K₄ matching analysis and our B₃
constraint-system symmetry group are complementary results about different objects.

## The 1979 reordering proposal — measured and refuted (with credit)

**McKenna, Stephen E. & Mair, Victor H.** "A Reordering of the Hexagrams of the I Ching," *Philosophy East
and West* 29:4 (October 1979), 421–441. (Distinct from McKenna & McKenna 1975.) They judged the received
order structurally indefensible beyond its local pairing and proposed a Gray-code-based replacement. Both
halves of that position are now formally addressed: population measurement finds discriminating structure
far beyond pairing (rules to ×11,364 rarity — see
[LITERATURE_RULES_POPULATION_TESTS.md](LITERATURE_RULES_POPULATION_TESTS.md)), and no Gray-code ordering
can satisfy the pairing constraint at all ([CRITIQUE.md](CRITIQUE.md) Claim 2). They retain clear priority
for the idea that drives this project's methodology: evaluating the King Wen sequence against explicitly
constructed alternatives rather than by inspection alone.

## Textual scholarship (reference)
**Kunst, Richard A.** *The Original "Yijing": A Text, Phonetic Transcription, Translation, and Indexes,
with Sample Glosses.* Ph.D. dissertation, University of California, Berkeley, 1985. (General textual
scholarship on the received text; relocated from README's reference list 2026-07-03 — not used by any
ROAE code or finding.)

---

## Annotated bibliography (A–Z, APA 7th edition)

Every article, book, and website analyzed by this project, with a brief annotation and an honest
consultation status: **[read]** = read in full first-hand; **[analyzed]** = systematically ingested with
notes; **[secondary]** = known only through another source's discussion; **[pending]** = acquisition in
progress; **[unread]** = obtained, deliberately deprioritized; **[not obtained]**. The thematic sections
above carry the per-finding attribution; this list is the raw inventory.

### Articles, books, and dissertations

Chan, A. (2026). *Statistical properties of the King Wen sequence: An anti-habituation structure that does
not improve neural network training*. arXiv. https://arxiv.org/abs/2604.09234
  Monte Carlo statistical analysis of the sequence against 100,000 random permutations; predates ROAE;
  per-finding overlap scoped above. [read]

Cook, R. S. (2006). *Classical Chinese combinatorics: Derivation of the Book of Changes hexagram sequence*
(STEDT Monograph Series No. 5). University of California, Berkeley.
  The most extensive modern derivation system; source of several measured rules (final-pair anchor, level
  coverage) and elaborator of the Schulz gender rule. [analyzed]

Davis, S. (1998). Operating the Yijing apparatus: A compositional analysis. *The Oracle: The Journal of
Yijing Studies, 2*(7). [not obtained]

Davis, S. (2012). *The classic of changes in cultural context: A textual archaeology of the Yi jing*.
Cambria Press.
  Window-symmetry claims; the flagship rule measured population-typical (×7) from secondary description —
  purchase deliberately declined on that evidence. [secondary]

Drasny, J. (c. 2007). *The regular grouping of the hexagrams before the Yi jing* [Paper]; *The Yi-globe:
The image of the cosmos in the Yijing* [Book].
  Early-Predecessor theory with four "alien" pairs as anomaly loci; also author of a critical review of
  Cook (2006). Paper [analyzed, via mirror]; book [not obtained].

Hacker, E. A. (1982). Temperature and the assignment of the hexagrams of the I-Ching to the calendar.
*Journal of Chinese Philosophy, 9*(4), 395–400. [pending]

Hacker, E. A. (1983). A note on formal properties of the later heaven sequence. *Journal of Chinese
Philosophy, 10*(2), 169–171. [pending]

Hacker, E. A. (1987). Order in the textual sequence of the hexagrams of the I Ching. *Journal of Chinese
Philosophy, 14*(1), 59–64.
  Possibly the earliest Western formal ordering analysis. [pending]

Hacker, E. A., & Moore, S. (2003). A brief note on the two-part division of the received order of the
hexagrams in the Zhouyi. *Journal of Chinese Philosophy, 30*(2), 219–221.
  Primary source of the 18:18 condensed-figure hypothesis (via Hu Yigui, 1247); its 3-vs-1 opposite-pair
  distribution is the measured R-C5. [read]

Hacker, E. A., Moore, S., & Patsco, L. (2002). *I Ching: An annotated bibliography*. Routledge. [not obtained]

Huang, A. (2000). *The numerology of the I Ching: A sourcebook of symbols, structures, and traditional
wisdom*. Inner Traditions.
  Independent 18:18-aware "hidden balance" reasoning, rejected by Hacker & Moore (2003) as special
  pleading. [secondary]

Kunst, R. A. (1985). *The original "Yijing": A text, phonetic transcription, translation, and indexes,
with sample glosses* [Doctoral dissertation, University of California, Berkeley].
  Textual scholarship; not used by any ROAE code or finding. [not consulted]

McKenna, T., & McKenna, D. (1975). *The invisible landscape: Mind, hallucinogens, and the I Ching*.
Seabury Press.
  Earliest published source of the no-5-line-transition observation (C2) and the difference-wave
  construction. [analyzed]

McKenna, S. E., & Mair, V. H. (1979). A reordering of the hexagrams of the I Ching. *Philosophy East and
West, 29*(4), 421–441.
  Gray-code replacement proposal; its structural-poverty premise is now measured and refuted; first to
  test the sequence against constructed alternatives. [analyzed]

Moore, S. (1989). *The trigrams of Han: Inner structures of the I Ching*. Aquarian Press.
  Source of the rising/falling rhythm rule (R-M2) and the pairs-22/23 anomaly discussion. [analyzed]

Moore, S. (2005). *Structural elements in the King Wen sequence* (Oracle Papers No. 1).
  Source of the pair-positioning parity rule (R-M1) and the corruption/precursor conjecture, materialized
  by SAT in 2026. [analyzed]

Radisic, A. (2026). *Optimal equivariant matchings on the 6-cube, with an application to the King Wen
sequence*. arXiv. https://arxiv.org/abs/2601.07175
  Lean-verified proof that the C1 pairing is the unique Hamming-cost optimum — the first first-principles
  derivation of any constraint layer. [read]

Rutt, R. (1996). *Zhouyi: The Book of Changes*. Curzon Press.
  Bamboo-slat cord-fraying physical corruption mechanism (p. 105), via Hacker & Moore (2003). [secondary]

Schöter, A. (1998). Boolean algebra and the Yi Jing.
  Boolean operations and lattice structure on hexagrams; does not address the King Wen ordering.
  [analyzed, via mirror]

Schulz, L. J. (1982). *Lai Chih-te (1525–1604) and the phenomenology of change* [Doctoral dissertation,
Princeton University].
  The study of Lai Zhide; recovers Lai's own 16th-century sequence arguments (36-unit consolidation,
  18:18 count, line-balance symmetry). [analyzed]

Schulz, L. J. (1990). Structural motifs in the arrangement of the 64 gua in the Zhouyi. *Journal of
Chinese Philosophy, 17*(3), 345–358.
  Three motifs over the consolidated units; motif 2 is the strongest measured discriminator (×11,364),
  with exceptions at stations 25/26. [read]

Schulz, L. J. (2011). Structural elements in the Zhou Yijing hexagram sequence. *Journal of Chinese
Philosophy, 38*(4), 639–665.
  Ten-element taxonomy; first formalization of the "exception-proves-the-rule" design principle at
  stations 25/26. [analyzed]

Schulz, L. J. (2016). *Hexagrammatics: Rules and properties in binary sequences* (2nd ed.). Zizai.
  Consolidated rule inventory; names stations 25/26 as the double-exception locus for both of his rules.
  [analyzed]

Schulz, L. J. (2018). *N Gua theory: Imaging categorical dynamics inherent in binary structures*.
ResearchGate.
  Hamming formalism; Ifa cross-cultural parallel; attributes the parity-exception's first recognition to
  Zhu Yuansheng (13th c.). [analyzed]

Schulz, L. J., & Cunningham, T. J. (1990). The seasonal structure underlying the arrangement of hexagrams
in the Yijing. *Journal of Chinese Philosophy, 17*(3), 289–313. (Working-paper version: Federal Reserve
Bank of Atlanta Occasional Paper Series, 1988.)
  The seasonal hypothesis behind the xiaoxi trisection. [pending]

Shaughnessy, E. L. (1996). *I Ching: The classic of changes*. Ballantine Books.
  Translation of the Mawangdui manuscript; source of the Mawangdui ordering tested by
  `--null-historical`. [read, data]

Smith, R. J. (2000). *A brief Western-language bibliography of the Yijing (Classic of Changes)*. Rice
University.
  The bibliography that surfaced the Hacker JCP papers. [analyzed]

Waley, A. (1933). The Book of Changes. *Bulletin of the Museum of Far Eastern Antiquities, 5*, 121–142.
[unread]

Wilhelm, R. (1967). *The I Ching or Book of Changes* (C. F. Baynes, Trans.; 3rd ed.). Princeton
University Press.
  Hexagram names used throughout. [read, data]

### Classical sources

Yu Fan (220–265, via Li Dingzuo's *Zhouyi jijie*), Zheng Qiao (~1150), Hu Yigui (b. 1247, *Zhouyi Qimeng
Yizhuan*), Lai Zhide (1525–1604, via Schulz, 1982), and Zhu Yuansheng (13th c., via Schulz, 2018) are all
[secondary], known through the modern literature above.

### Websites

Moore, S. (n.d.). *Yijing Dao*. biroco.com. https://www.biroco.com/yijing/
  Steve Moore's archive; source of the Moore papers, Schulz (1990), Waley (1933), and others. [swept 2026-07]

Drasny, J. (n.d.). *The Yi-globe*. i-ching.hu. https://www.i-ching.hu/
  HTTP-only, partially blocked; core paper recovered via mirror. [partial]

Schöter, A. (n.d.). *Yijing algebra*. yijing.co.uk. https://www.yijing.co.uk/
  HTTP-only, partially blocked; 1998 paper via mirror; three later papers paywalled. [partial]

Hacker, E. A., Moore, S., & Patsco, L. (n.d.). *Zhouyi.com* [Archived website]. Internet Archive.
  Blocked to our tooling; primarily a link aggregator. [not reached]

Wikipedia and OEIS entries used for reader orientation and the binary encoding are listed in
[README.md](../README.md) §References. [read]
