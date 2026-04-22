# Citations and Prior Literature

This document lists prior published work on the mathematical structure of the King Wen sequence and the methodological/algorithmic sources underlying ROAE's computations. Its purpose is to be honest about what is **independently verified** here versus what is **novel to ROAE**.

> **Disclaimer.** This list is **not exhaustive**. Scholarship on the I Ching spans three millennia, multiple languages (primarily Chinese, with significant secondary literature in Japanese, English, German, and French), and several fields (sinology, combinatorics, philosophy, comparative religion, mathematical recreation, psychedelic studies). Omissions are unintentional. **If you are aware of prior work not cited here, or see a claim below that should be updated or corrected, please submit a pull request** against this repository (`petersm3/roae`) with the proposed addition or correction. Opening an issue is also fine for cases where you'd like to discuss before editing. Additions and clarifications are welcome and will be incorporated; pull requests make it easiest to track attribution of the contribution back to the submitter.

---

## Prior observations about King Wen mathematical structure

### C1 — pair structure (reverse / inverse / complement pairs)

The pairing of the 64 hexagrams into 32 consecutive reverse-or-complement pairs is a **classical observation**, not novel to any modern author. It appears in the earliest layers of I Ching commentary (the *Yi Zhuan* or "Ten Wings," traditionally attributed to Confucius, ~5th–3rd c. BCE, though modern dating is later). The explicit modern formulation is given in:

- **Wilhelm, Richard and Baynes, Cary F. (trans.)** (1967). *The I Ching or Book of Changes*. 3rd edition, Princeton University Press / Bollingen Series. The pairing convention is used throughout. ISBN 978-0-691-09750-3.
- **Cook, Richard S.** (2006). *Classical Chinese Combinatorics: Derivation of the Book of Changes Hexagram Sequence* (周易卦序詮解 Zhouyi Guaxu Quanjie). STEDT Monograph Series Vol. 5, University of California, Berkeley, 656 pages. ISBN 978-0944613443. Cook's monograph is the most rigorous academic treatment; it derives the full hexagram sequence from combinatorial principles and situates the pair structure within broader classification of binary sequences.

**Status in ROAE:** ROAE independently encodes this rule as constraint C1 and uses it as the starting point of the enumeration. Not novel to ROAE.

### C2 — absence of 5-line transitions

The observation that consecutive hexagrams in the King Wen sequence **never differ by exactly five lines** is attributed to Terence McKenna.

- **McKenna, Terence and McKenna, Dennis** (1975). *The Invisible Landscape: Mind, Hallucinogens, and the I Ching*. Seabury Press, New York (reprinted HarperOne 1993, ISBN 978-0062506351). The "first-order of difference" analysis and the 14:2 ratio of 3-line to 1-line between-pair transitions with 5-line transitions absent, is discussed in the chapters on the King Wen sequence as a quantified modular hierarchy. Specific page references have not been verified here; readers investigating the original wording should consult the 1975 or 1993 editions directly.
- *Status of earlier references:* The claim is rooted in McKenna's 1971 Amazonian experience (see *True Hallucinations*, 1993, and Timewave-Zero biographical sources), but no pre-1975 peer-reviewed paper or published lecture transcript on the subject has been located via open web sources. An exhaustive archival search (McKenna papers, early 1970s conference proceedings, underground press archives) might surface earlier statements; not undertaken here.
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
3. **Exhaustive enumeration under the C1+C2+C3 conjunction at 10T and 100T scale** — 3,432,399,297 d3 100T (sha `915abf30…`) / 706,422,987 d3 10T / 286,357,503 d2 10T. Revealed that the boundary-minimum grows with partition depth (4 at 10T, 5 at 100T) and that KW sits at the C3 ceiling, not the floor.
4. **Comprehensive null-model testing framework** — seven structured and unstructured permutation families tested via `solve.c --null-*` subroutines: de Bruijn, Gray, Latin-square, lexicographic, historical, random, pair-constrained.
5. **Analytic C1 impossibility proofs** for the de Bruijn B(2, 6) family (period-4 contradiction) and the Gray code family (Hamming-1 disjoint). See [CRITIQUE.md](CRITIQUE.md).
6. **Latin-square C2 rate decomposition** — analytic explanation of the 57.96% rate as a function of row-permutation class (Hamiltonian-path popcount distribution in the 3-cube). See [CRITIQUE.md](CRITIQUE.md).
7. **Partition-stability analysis** — the finding that boundaries {25, 27} are mandatory in every working 4-boundary set at BOTH d2 and d3, while the other two boundaries are partition-dependent.
8. **Mawangdui C2 observation** — that the ancient silk-text ordering accidentally satisfies C2 (zero 5-line transitions) while failing C1 and C3.
9. **C3 total complement distance as a specifically quantified constraint** — 776 (= 12.125 × 64) as the King Wen value, positioning KW at the 3.9th percentile within C1-satisfying orderings.
10. **Format v1 `solutions.bin`** — canonical binary format with 32-byte header + 32-byte records, designed for partition-invariant sha256 reproducibility.

Each of the above claims to originality is **tentative** — if you find prior work establishing any of them, please contact the author and this document will be updated.
