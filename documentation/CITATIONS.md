# Citations and Prior Literature

This document lists prior published work on the mathematical structure of the King Wen sequence and the methodological/algorithmic sources underlying ROAE's computations. Its purpose is to be honest about what is **independently verified** here versus what is **novel to ROAE**.

> **Disclaimer.** This list is **not exhaustive**. Scholarship on the I Ching spans three millennia, multiple languages (primarily Chinese, with significant secondary literature in Japanese, English, German, and French), and several fields (sinology, combinatorics, philosophy, comparative religion, mathematical recreation, psychedelic studies). Omissions are unintentional. **If you are aware of prior work not cited here, or see a claim below that should be updated or corrected, please submit a pull request** against this repository (`petersm3/roae`) with the proposed addition or correction. Opening an issue is also fine for cases where you'd like to discuss before editing. Additions and clarifications are welcome and will be incorporated; pull requests make it easiest to track attribution of the contribution back to the submitter.

> **Anchors (cross-doc linking).** Every bibliographic entry in this file carries an HTML anchor of the form `id="lastnameYYYY"` (e.g. `#cook2006`, `#goldenberg1975`) so other Markdown docs in this repo can deep-link to it. GitHub-flavored Markdown does not support `{#id}`, so plain `<a id>` tags are used. Multi-author works hyphenate the first two surnames (`#mckenna-mckenna1975`); same-author-same-year collisions take a topic suffix (`#schulz1990-motifs`). Added per task #227.

---

## Prior observations about King Wen mathematical structure

### C1 — pair structure (reverse / inverse / complement pairs)

The pairing of the 64 hexagrams into 32 consecutive reverse-or-complement pairs is a **classical observation**, not novel to any modern author. It appears in the earliest layers of I Ching commentary (the *Yi Zhuan* or "Ten Wings," traditionally attributed to Confucius, ~5th–3rd c. BCE, though modern dating is later). The explicit modern formulation is given in:

- **Wilhelm, Richard and Baynes, Cary F. (trans.)** (1967). *The I Ching or Book of Changes*. 3rd edition, Princeton University Press / Bollingen Series. The pairing convention is used throughout. ISBN 978-0-691-09750-3. [Open Library](https://openlibrary.org/isbn/9780691097503)
- **Cook, Richard S.** (2006). *Classical Chinese Combinatorics: Derivation of the Book of Changes Hexagram Sequence* (周易卦序詮解 Zhouyi Guaxu Quanjie). STEDT Monograph Series Vol. 5, University of California, Berkeley, 656 pages. ISBN 978-0944613443. [Open Library](https://openlibrary.org/isbn/9780944613443) Cook's monograph is the most rigorous academic treatment; it derives the full hexagram sequence from combinatorial principles and situates the pair structure within broader classification of binary sequences. **Preview pages (front cover, abstract, TOC, introduction, acknowledgments — 19 pages total)** available online at the author's UC Berkeley page: [linguistics.berkeley.edu/~rscook/images/CCCprev/CCCprev.html](https://linguistics.berkeley.edu/~rscook/images/CCCprev/CCCprev.html). The full 656-page monograph is print-only as of 2026-05; library copies via OCLC 77009740 or purchase formerly via the STEDT Web Store at lulu.com/stedt (dead link as of 2026-07-04; [archived copy](https://web.archive.org/web/20230329134852/https://www.lulu.com/stedt), snapshot 2023-03-29, verified resolving 2026-08-01) (ISBN 0-944613-44-6).

<a id="kongyingda"></a>
- **Kong Yingda 孔颖达** (574–648). *Zhouyi zhengyi* 周易正义 (in the *Shisanjing zhushu* 十三经注疏, Zhonghua Shuju edition, 1980). **The classical formulation of C1**: his subcommentary on the [Xugua](#xugua) states the received order's pairing principle — the hexagrams run two-by-two, each pair related to its partner by reversal or, where the reversal is symmetric, by complement — the Tang-dynasty source every modern statement of the pairing rule descends from or independently rediscovers. The concept has still earlier attestation lineage (Yu Fan 虞翻, 164–233, whose pangtong/fandui pair relations transmit via Li Dingzuo's *Zhouyi jijie*; and, hedged, Western-Zhou-era material per Li Xueqin 2003), but Kong Yingda's is the explicit formulation. Added 2026-07-30 (constraint-provenance audit; the repo previously carried no Kong Yingda citation anywhere). *Cited here at attribution level — the paraphrase above states the rule; the verbatim classical wording is held for a future classical-Chinese verification pass.*

**Status in ROAE:** ROAE independently encodes this rule as constraint C1 and uses it as the starting point of the enumeration. Not novel to ROAE.

### C2 — absence of 5-line transitions

The observation that consecutive hexagrams in the King Wen sequence **never differ by exactly five lines** is attributed to Terence McKenna.

- **McKenna, Terence and McKenna, Dennis** (1975). *The Invisible Landscape: Mind, Hallucinogens, and the I Ching*. Seabury Press, New York (**2nd, revised and updated edition: HarperSanFrancisco/HarperCollins, 1993, 229 pp. — this is the edition carrying Peter Meyer's appendix *The Mathematics of Timewave Zero*, pp. 211–220**; subsequent printing 1994, ISBN 0-06-250635-8 / 978-0062506351; [Open Library](https://openlibrary.org/isbn/9780062506351)). The "first-order of difference" analysis appears in **Part Two, Chapter 9 ("Order in the I Ching and Order in the World")**. McKenna explicitly states "a perfect ratio of three to one; three even integers to each odd integer" and gives the count as "fourteen threes and two ones constitute sixteen instances of an odd integer occurring out of a possible sixty-four" — confirming he was using the **circular reading** (64 transitions including the wrap-around s₆₃ → s₀, which has Hamming distance 3 in King Wen). Figure 17 (Table II, "Change in the King Wen Sequence") enumerates the full difference-wave histogram pair-by-pair. In the same chapter McKenna formalizes the sequence design under three rules: (1) absolutely exclude transitions of value 5 (= our **C2**); (2) minimize transitions of value 1 except where doing so would force a value 5 — empirically measured at the d3 560T canonical 2026-06-15 (`9a968fa2…`, 10,525,271,997 records: 80.03% of C1-C5 records violate it; KW is in the 19.97% minority that obeys it). **NOT promoted to a formal C-rule** — it would be reverse-engineered from KW's specific value-1 placements without first-principles or independent-corroboration support; see MCKENNA.md for the peer-review-defensibility analysis; (3) maintain a three-to-one ratio of even to odd transitions (= our **Theorem on wrap-around parity**, since 3:1 circular is a consequence of C4 + C5 + the XOR parity identity).
- *Status of earlier references:* The 1975 first edition (Seabury Press) contains the same I Ching analysis as the 1994 HarperCollins reprint; the work was reprinted, not revised. The underlying intuitions date to the McKennas' 1971 Amazonian expedition (see *True Hallucinations*, 1993, and Timewave-Zero biographical sources). No pre-1975 peer-reviewed paper or published lecture transcript on the I Ching analysis has been located via open web sources.
- Cook (2006) also presents the 5-line absence as part of the broader combinatorial analysis; independently derived within his framework.

**Status in ROAE:** ROAE encodes this as constraint C2 and independently verifies it across the canonical datasets. We do not claim originality for the observation itself; ROAE's contribution is the **exhaustive null-model testing** (see §Methodology below) which shows C2 is essentially unreachable in de Bruijn and random permutation families, and the **analytic decomposition** of why Latin-square row×col traversals satisfy C2 at 57.96% rate (believed novel; see [CRITIQUE.md](CRITIQUE.md)).

### C3 — complement distance minimization

The observation that King Wen positions complementary hexagrams (bitwise-opposites) unusually close to each other — formally, that the total positional distance $\sum_{v} |pos(v) - pos(\overline{v})| = 776$ is low (3.9th percentile, sampled — **figure flagged 2026-08-01**, see below and [SOLVE.md](SOLVE.md) §Rule 3) among orderings satisfying the other extracted constraints (C1+C2+C4+C5; scope label corrected 2026-07-22 — under the bare C1&C4 null the exact tail is 8.1%, `verify.py --check-null-g`) — is **not found in the prior published literature reviewed here**.

- Cook (2006) does not, to our reading of reviews and summaries, present this specific property.
- McKenna (1975) does not present it.
- No prior peer-reviewed citation is known to the author.
- <a id="barrett2019"></a>**Hilary Barrett (2019)** — the nearest prior art we have found is an informal blog post, "Complementary hexagrams and direction" (I Ching with Clarity, [onlineclarity.co.uk](https://www.onlineclarity.co.uk/answers/2019/04/05/complementary-hexagrams-and-direction/), 5 April 2019; archived [via the Wayback Machine](http://web.archive.org/web/20230312000515/https://www.onlineclarity.co.uk/answers/2019/04/05/complementary-hexagrams-and-direction/)). It observes, qualitatively, *where individual* complementary (bitwise-opposite) pairs sit relative to each other in the King Wen sequence — visualizing whether each pair "looks forward or back" for its complement — and explicitly names the largest gaps: "the greatest distance… is that between 3 and 50," the "second greatest" beginning at hexagram 5 (→ 35), and the "third-biggest" between 21 and 48. It is entirely informal ("counting complementary hexagrams instead of sheep") — no total sum, no percentile, no invariant, no bound — and does **not** anticipate the C3 total (776), its distribution, or the **C3 = 16 + 8·G** collapse (the latter a machine-checked repo theorem since 2026-07-04, `lean/C3Decomposition.lean`; see [TR-11 §10](../reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md)). (Barrett's informal ranking is also not exhaustive — the actual second-largest gap is 4↔49 at distance 45, which the post skips — underscoring its eyeball character.) Credited as the nearest-in-spirit prior art on complement *distances*; not a prior statement of any quantified ROAE C3 result. Corrections welcome.

**Status in ROAE:** We believe C3 as a specifically-quantified constraint (776 as the KW value) is an original observation. *(**Amended 2026-08-01, lens sweep:** this claim previously read "776 as the KW value; 3.9th percentile — sampled — within orderings satisfying the other constraints, C1+C2+C4+C5". The 3.9th-percentile figure is flagged — it is not supported by the population it is labelled with, and the suite's own ledger gives ≈12% at that scope; see [SOLVE.md](SOLVE.md) §Rule 3. **The novelty claim does not depend on the figure** — it is about 776 being identified and quantified as a constraint at all — but the specific percentile must not travel with it.)* If prior work exists, please notify — we will credit appropriately.

**Scope qualifier (added 2026-04-20 after d3 100T enumeration; scope label corrected 2026-07-22):** KW's C3 is low (3.9th percentile, sampled — **flagged 2026-08-01, see [SOLVE.md](SOLVE.md) §Rule 3: not supported by that population; ledger ≈12%**) *within orderings satisfying the other constraints (C1+C2+C4+C5)* — not within C1-only orderings, where the measured tail is ~6-8% (C3|C1 = exact 6.4211367496% via `verify.py --check-null-g --unpinned` — the 10⁹-sample MC via `solve.c --null-pair-constrained` measured 6.42%, consistent; exact 8.106% at C1&C4 via `verify.py --check-null-g`) — but once the full C1+C2+C3 canonical is enumerated, **KW sits at the C3 ceiling (776), not the floor**. Minimum C3 is 424 (221 records) at 100T and 392 at the deeper 560T canonical; about **1 in 10 (~10%)** of canonical orderings tie with KW at 776 — a fraction measured over the enumerated set, not a universal constant (9.91% over the 100T sample, 10.11% over the deeper 560T sample; both correct, converging near 10% — the full ~10³⁸ space was never fully enumerated). So within the conjoint C1+C2+C3 frame, KW's C3 value is a *jointly satisfied upper bound* that many other orderings match, not a distinguishing minimum. The low-percentile framing of C3 applies specifically to the C1+C2+C4+C5 comparison population (every constraint except C3 itself) and should not be generalized — and it is a lowest-4% placement, not a minimization. See [SOLVE.md](SOLVE.md) §Rule 3 revision and [DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md).

### C4 — fixed start (Qian, Kun)

The placement of the two constant hexagrams (Qian 乾, Kun 坤) first is classically attested,
independently of any modern analysis:

<a id="xugua"></a>
- **Xugua zhuan** 序卦传 ("Sequence of the Hexagrams"), one of the Ten Wings of the *Yi Zhuan*
  commentary layer. Opens by transmitting Heaven/Earth (Qian/Kun) first — the classical warrant for
  C4's pair choice. Known through the standard commentary tradition (the [Kong Yingda](#kongyingda)
  subcommentary is the C1-relevant stratum of the same text).
- Modern documenter: **[Schulz & Cunningham (1990)](#schulz-cunningham1990)** — the crisper prior
  source for C4 (see that entry: the qian/kun "pure yang / pure yin" precedence as an "unavoidable
  priority", p. 298).

**Status in ROAE:** classical fact, encoded as C4; not novel to ROAE. The orientation layer (63
before 0) is definitional/classically attested — the former "Theorem 6 (forced orientation)" claim
was retracted 2026-07-26 (see CLAIMS_DECIDED.md). *(Stub added 2026-07-30 — constraint-provenance
audit; C4 previously had no subsection here.)*

### C5 — transition-distance multiset

C5's axis (the multiset of consecutive Hamming distances) has two distinct prior-art strata,
both already cited in full elsewhere in this file; this stub is the landing point:

- **As data:** [Meyer (1998)](#meyer1998) publishes the complete cyclic line-change sequence
  (all Hamming distances including the wrap-around term) with an explicit XOR-and-popcount
  formalization — prior art for the transition multiset *as data*.
- **As a measured statistic:** [Chan (2026)](#chan2026) first published the mean consecutive
  Hamming distance 3.35 (= 211/63) measured against random permutations — the same number ROAE's
  C5 multiset forces exactly.

**Status in ROAE:** the multiset is extracted from King Wen (confirmatory, not derived) and priced
as such throughout the suite; C2 ⊂ C5 (the multiset contains no 5s) is disclosed in METHODS.
*(Stub added 2026-07-30 — constraint-provenance audit; C5 previously had no subsection here.)*

### Pair structure + no-5-line + complement proximity as a *joint* constraint system

The framing of C1+C2+C3 as a specific system that narrows 10^89 orderings to ~700 million is ROAE-specific. Individual constraints appear in prior work; the conjunction, the exhaustive enumeration under the conjunction, and the 4-boundary / pair-stability analysis are ROAE-original.

### Fu Xi ordering, binary representation

<a id="leibniz1703"></a>
- **Leibniz, Gottfried Wilhelm** (1703). "Explication de l'arithmétique binaire, qui se sert des seuls caractères 0 et 1, avec des remarques sur son utilité, et sur ce qu'elle donne le sens des anciennes figures chinoises de Fohy." *Mémoires de l'Académie royale des Sciences*. Shows correspondence between Fu Xi's binary ordering and the natural binary count 0–63.
<a id="shaoyong"></a>
- **Shao Yong** (邵雍, 1011–1077 CE). *Huangji jingshi shu* (皇極經世書). Developed the circular/square binary arrangement (xiantian diagram) that Leibniz later rediscovered.

### Mawangdui silk-text ordering

- **Shaughnessy, Edward L.** (1996). *I Ching: The Classic of Changes* (Mawangdui Texts). Ballantine Books. ISBN 978-0345362438. [Open Library](https://openlibrary.org/isbn/9780345362438) Translation and analysis of the 168 BCE Mawangdui silk manuscripts' alternative hexagram ordering.
- **Shaughnessy, Edward L.** (2022). *The Origin and Early Development of the Zhou Changes*. Leiden: Brill (Prognostication in History 9). Open access. **The authority for the Mawangdui ordering array used by ROAE** (p. 50 + Table 11.2: eight octets by upper trigram Qian, Gen, Kan, Zhen, Kun, Dui, Li, Xun; lower trigrams cycling Qian, Kun, Gen, Dui, Kan, Li, Zhen, Xun with the octet's own trigram promoted to first).

**ERRATUM (2026-07-05).** From 2026-04-06 to 2026-07-05 the Mawangdui array in `roae.py`/`solve.c` was **wrong** — right octet membership, wrong octet order, wrong within-octet order (a synthesized double loop that matched neither the manuscript nor its own code comment; the cited Wikipedia article contains no sequence at all). The error was caught by cross-checking Shaughnessy 2022 Table 11.2 during a literature audit, and the corrected array was verified against multiple independent sources (Shaughnessy 2022; Cook 2006's full 64-position table; Shaughnessy 1996's generation rule via Rutt's review; S. J. Marshall's biroco.com conversion chart; independent web statements of the rule). Consequence: the former claim that Mawangdui satisfies C2 is **withdrawn** — the authentic Mawangdui order has **exactly one 5-line transition**, at the octet seam #48 Jing → #51 Zhen (positions 24→25), where its trigram-block construction resets. C2 is satisfied by King Wen and Jing Fang only (2 of 4 tested orderings), and the former "three of four / classical Chinese design principle" reframing of McKenna's observation is likewise **withdrawn**. All published Mawangdui-derived numbers were recomputed on the corrected array 2026-07-05; no other verdict flipped ([TR-1](../reports/TR1_EIGHT_CENTURIES_MEASURED.md)'s F5 corpus gate and [TR-10](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md)'s specificity gate both still pass — in both cases more cleanly). See also:

<a id="jingfang"></a>
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
  Improve Neural Network Training*. arXiv:2604.09234 (v2, revised 2026-06-25).
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

<a id="yangxiong"></a>
- **Online discussions** (e.g., the [I Ching Community](https://www.onlineclarity.co.uk/friends/archive/index.php/t-10608.html) forum) have pointed out the correspondence, sometimes citing classical Chinese figures like **Yang Xiong** (楊雄, 53 BCE – 18 CE) as having anticipated de Bruijn-like structures in the *Taixuanjing* (*Canon of Supreme Mystery*), which uses ternary rather than binary.
<a id="vanaardenne-debruijn1951"></a>
- **van Aardenne-Ehrenfest, T. and de Bruijn, N. G.** (1951). "Circuits and trees in oriented linear graphs." *Simon Stevin* 28: 203–217. The BEST theorem; used by ROAE to count B(2, 5) Eulerian circuits (= 2^27 = 134,217,728 with fixed starting vertex).

ROAE's **exhaustive enumeration of all 2^27 B(2, 6) permutations and analytic proof that 0 satisfy C1** (via the period-4 contradiction) is believed novel. If a prior rigorous null-model test of B(2, 6) permutations against King Wen's structural constraints exists, please notify.

### Gray codes, recreational mathematics, and the I Ching

<a id="vanderblij1967"></a>
- **van der Blij, F.** (1967). "Combinatorial aspects of the hexagrams in the Chinese Book of
  Changes." *Scripta Mathematica* 28(1): 37–49 (Zbl 0157.33001; Hacker, Moore & Patsco 2002,
  B:437, date the same issue 1966 — we follow zbMATH, Cook 2006, and Nielsen 2003 in citing
  1967). The earliest Western mathematical-journal treatment of the hexagrams we have located.
  Per the H/M/P annotation it explains the Fu Xi ordering as binary counting, relates the
  Ho Tu / Lo Shu diagrams to the trigram arrangements, computes yarrow probabilities, and
  concedes the King Wen order is *still unsolved* — seven years before Gardner's column. Not
  prior art for any ROAE constraint; it documents that the ordering problem was formally open.
  Known at annotation level only; primary text not yet obtained (*Scripta Mathematica* ceased
  1973; interlibrary-loan route). Corrections welcome.
<a id="gardner"></a><a id="gardner1974"></a>
- **Gardner, Martin** (1974, January). "Mathematical Games: The combinatorial basis of the
  *I Ching*, the Chinese book of divination and wisdom." *Scientific American* 230(1): 108–113.
  [doi:10.1038/scientificamerican0174-108](https://doi.org/10.1038/scientificamerican0174-108)
  (Reprinted in *Knotted Doughnuts and Other Mathematical Entertainments*, 1986.) States the C1
  pairing rule (each odd-numbered hexagram followed by its inverse, or its complement when
  reversal-symmetric), then asks whether any mathematical order determines the succession of the
  hexagram *pairs* — "This is an unsolved problem" (p. 108). The mainstream-1974 statement, at
  exactly the pair-quotient granularity ROAE enumerates over, that the ordering problem was
  open; the column Davis (2012, p. 84 n6) cites for the absence of global mathematical pattern
  beyond the pairing, and the source of the yarrow vs. three-coin moving-line probabilities
  (1/16 vs. 3/16) that Clarke (1987) builds on. [read — scan in hand; page span verified against
  the scan, the publisher's metadata, and Beebe's *Scientific American* bibliography. Hacker,
  Moore & Patsco (2002, B:147) print the span as 109–113; 108–113 is correct.]
<a id="gardner1972"></a>
- **Gardner, Martin** (1972, August). "Mathematical Games: The curious properties of the Gray
  code and how it can be used to solve puzzles." *Scientific American* 227(2): 106–109.
  [doi:10.1038/scientificamerican0872-106](https://doi.org/10.1038/scientificamerican0872-106)
  The Gray-code column; background for ROAE's Gray-code null family. (We have not read this
  column first-hand; whether it itself connects Gray codes to the I Ching is unverified, so the
  I Ching connection is scoped to the 1974 column.)
<a id="savage1997"></a>
- **Savage, Carla D.** (1997). "A survey of combinatorial Gray codes." *SIAM Review* 39: 605–629. [doi:10.1137/S0036144595295272](https://doi.org/10.1137/S0036144595295272) Standard reference on Gray code families.

ROAE's **analytic proof that no 6-bit Gray code satisfies C1** (Hamming-1 adjacency is disjoint from C1's required {0, 2, 4, 6}) is believed novel but straightforward; it follows trivially from the Gray code definition.

---

## The (Z/2)⁶ hexagram algebra and hexagram-level group actions — priority ceded

*(Section added 2026-07-30, novelty-gate review. These entries close the repo's largest citation gap:
the Chinese and Japanese algebraic literature on the hexagram set, previously uncited anywhere in
this repository.)*

The algebraic framing this project uses — the 64 hexagrams as (Z/2)⁶ under line-wise XOR, with the 8
self-complementary hexagrams as an order-8 subgroup whose cosets organize the reversal-pairs — is
prior art: Ouyang Weicheng 欧阳维诚 ([1992](#ouyang1992)) proved the group structure and read the
Jing Fang, Mawangdui, and Fuxi sequences as subgroup-coset arrangements, and Suenaga Takayasu
末永高康 ([2012](#suenaga2012)) independently developed the same machinery and initiated counting
the arrangement space, computing the number of order-8 subgroups exactly (1395 = [6 choose 3]₂) and
posing, though not completing, a full product count. We claim no originality for this framing or for
the idea of counting hexagram-arrangement spaces; the contributions here are the exact
full-scale counts at the C1∩C2∩C4 and C1∩C2∩C4∩C5 layers (with validated estimates for C1–C5 and
C1–C7, which remain estimates — TR-11 §10) — a different counting object — the equivariance-ceiling theorem, and the
machine-checked formalization.

By our current accounting ROAE is the **fifth independent arrival** at this algebra:
[Goldenberg (1975)](#goldenberg1975) (first Western) → Ouyang (≤1986, framework; [1992](#ouyang1992),
fullest, with proofs and cosets) → [Suenaga (2012)](#suenaga2012) (independent, adds counting) →
[Radisic (2026)](#radisic2026) (Lean-verified matching layer) → ROAE, with
[Schöter (1998)](#schoter1998) a further independent-then-crediting arrival (he reports the bulk of
his work predated his awareness of Goldenberg). All of these act on the
**hexagram set**; none states a group acting on the space of admissible **orderings** (TR-5's object),
enumerates that space, or proves a ceiling on it.

<a id="ouyang1990"></a>
- **Ouyang Weicheng 欧阳维诚** (1990). "Zhouyi guaxu tanyuan" 周易卦序探原 [Tracing the origin of the
  Zhouyi hexagram sequence]. *Qiusuo* 求索 1990(6): 70–74. The sharpest published statement of the
  **no-intrinsic-order / under-determination** position: the hexagrams have no intrinsic order; an
  ordering must be imposed by added conditions, "like defining an ordered set in mathematics" — plus
  five proto-axiomatic requirements for any such condition set (本质性/和谐性/完备性/简单性/有效性).
  Speculative/programmatic, not a measurement; ROAE's 5.21×10³¹ C1–C7 survivor count is the
  quantitative form of the position he articulated. [analyzed 2026-07; notes in the private trove]
<a id="ouyang1992"></a>
- **Ouyang Weicheng 欧阳维诚** (1992). "Yiqun yanjiu" 易群研究 [A study of the Yi group]. *Zhouyi
  yanjiu* 周易研究 1992(3): 69–77. **The earliest and fullest hexagram-level group theory located by
  this project**: proves the 64 hexagrams form an abelian group ≅ (Z/2)⁶ (his framework dates to
  *Hunan shuxue tongxun* 湖南数学通讯 1986(1)), develops a named subgroup lattice with a subgroup
  chain and expansion theorem, and — twenty years before Suenaga — exhibits the Jing Fang, Mawangdui,
  and Fuxi sequences' 8×8 squares as **subgroup × coset partitions** (his 可乘划分). His counting
  objects (卦变 transformation distances; 384 magic squares) are disjoint from ROAE's ordering
  counts. Notable intellectual history: in 1987 (*Chuanshan xuebao* 船山学报 1987(1): 116–123) the
  same author — the framework's originator — argued the King Wen *sequence* has **no** mathematical
  structure and that ordering the hexagrams is "impossible and unnecessary" (endorsing Wang Chuanshan);
  by 1990 he had **reversed** this denial and was seeking the ordering's constraint principles. We
  cite the 1987 denial only as evidence that even a sophisticated algebraist initially judged the
  ordering problem empty — not as a standing assessment (he retracted it himself). [analyzed 2026-07]
<a id="zhang1994"></a>
- **Zhang Qingyu 张清宇** (1994). "Yitu de neihan-ge jieshi" 易图的内涵格解释 [An intension-lattice
  interpretation of the Yi diagrams]. *Zhexue yanjiu* 哲学研究 1994(3): 36–44. Origin of his
  intension-lattice program and the first appearance of the **K₄-orbit tally** of the 64 hexagrams
  under complement (错) and reversal (综): 32 错-pairs / 28 综-pairs / 8 自综 / 4 错综. The orbit
  *concept* ({x, x̄, x*, x̄*} as the minimal set closed under both operations) is developed in his
  1998 sequel ("Liushisi gua fangtu he Zhouyi guaxu fenxi" 六十四卦方图和周易卦序分析, *Zhexue
  yanjiu* 1998(7): 62–68, which credits Shen Youding 沈有鼎 and concedes it cannot fix the 48 散卦),
  and the *name* 错综不变组 plus a full secondary-hexagram solution arrive in 2000 ("Cuozong
  bubianzu he sangua guaxu jiegou" 错综不变组和散卦卦序结构, *Zhexue yanjiu* 2000(12): 68–72). The
  1994 paper has no 卦序 content; his later ordering work is rational reconstruction of the single
  received sequence — no enumeration of admissible orderings, no ceiling, no group on orderings, no
  formal verification. His group action is hexagram-level (K₄, orbit size ≤ 4), distinct from TR-5's
  ordering-level S₄/B₃ action (orbit size 24/48). Canonical fact from his tables: the lower canon
  has **16** 交综 pairs (a circulating "17" is an OCR error; 28 total 综 − 12 upper = 16).
  [analyzed 2026-07]
<a id="suenaga2012"></a>
- **Suenaga Takayasu 末永高康** (2012). "Kinbon *Shūeki* no kajo o megutte" 今本『周易』の卦序をめぐって
  [On the hexagram order of the received *Zhouyi*]. *Tōyō koten-gaku kenkyū* 東洋古典學研究 34: 1–18.
  Independent rediscovery of the (Z/2)⁶/XOR framing (yin=0/yang=1, six-bit vectors), the order-8
  subgroup of the 8 self-complementary hexagrams, and the coset organization of reversal-pairs — and
  **the first author we have located to start counting the arrangement space**: computes exactly
  1395 = [6 choose 3]₂ order-8 subgroups, and poses (but does not complete — halted, he reports, by
  his calculator's display) the product 1395 × 56 × 48 × 40 × 32 × 24 × 16 × 8 ≈ 1.47×10¹³ for
  eight-palace-style templates. He also reports finding **no rule that fixes the King Wen sequence**
  (an informal under-determination statement). His counted objects (F₂⁶ subspaces; algebraic
  templates) are disjoint from ROAE's constraint-satisfying total orders; he never completed or
  validated a count and connected no structure to the King Wen ordering. A one-off within his
  oeuvre (he is a *Liji* specialist), best read as the terminus of the Ouyang (1992) → Suenaga
  (2012) lineage rather than an isolated spike. [analyzed 2026-07; obtained via Hiroshima OA]
<a id="luojianjin2015"></a>
- **Luo Jianjin 罗见今** (2015). "Zhouyi guaxu de duicheng jiegou tanze" 周易卦序的对称结构探赜——
  邵雍先天图的数学解析和应用 [Exploring the symmetric structure of the Zhouyi hexagram sequence: a
  mathematical analysis and application of Shao Yong's Xiantian diagram]. *Gaodeng shuxue yanjiu*
  高等数学研究 [Studies in College Mathematics] 18(4): 33–39.
  [doi:10.3969/j.issn.1008-1399.2015.04.013](https://doi.org/10.3969/j.issn.1008-1399.2015.04.013).
  *(Title confirmed 2026-07-31 from the article PDF; an earlier acquisition-tracker variant was a
  back-translation of the English title.)* A mathematics-
  journal symmetry analysis of the King Wen (plus Guicang and silk-text) orderings — binary hexagram
  values, the Shao Yong rhombus, three involutions (his coinage 交射), and a five-class pair-symmetry
  classification of the received sequence. **Poses the enumeration question this suite answers** —
  §5.1 asks, as a derived open mathematical problem (还可引出一数学问题): "under the condition that
  the Zhouyi's structure is unchanged, how many orderings can the 64 hexagrams generate? It should
  be far smaller than the usually assumed 64!" (在周易结构不变的条件下，64卦可衍生出多少种排序方式？
  应比通常认为的 64！要小得多) — without formalizing constraints, computing any count, bounding the
  space, or introducing a group on orderings. To our knowledge the question remained unanswered in
  the literature; ROAE's exact counts and estimates (TR-4, TR-11) are, we believe, the first
  quantitative answers to Luo's 2015 question. [analyzed 2026-07-30]

### Additional works reviewed for priority

*(Added 2026-07-31.) The priority survey covered the broader Chinese-language mathematical literature
on the hexagram sequence. The works below were reviewed and are listed for completeness: **none states
the constraint-satisfaction enumeration problem, computes a constraint-satisfying ordering count,
proves a limitative/ceiling result, or gives a machine-checked formalization** — each is descriptive,
constructive, or confirmatory in aim, and so is not prior art for this project's specific
contributions (the exact C1∩C2∩C4 and C1∩C2∩C4∩C5 full-scale counts — C1–C5/C1–C7 remain validated estimates — the equivariance ceiling, and the Lean formalization).
Recorded here to document the survey's breadth.*

- **Gu Chengcheng 谷成城** (2021/2022). *Xitong kexue xuebao* 系统科学学报 30(3). An intension-lattice /
  systems-theory reading; the author notes that lattice methods yield a *sufficient-not-necessary*
  condition and cannot derive the King Wen order de novo (confirmatory, not enumerative).
- **Liu Gang 刘钢** (2017). "Lun xiantian yitu yu buer daishu de dengjiaxing" 论先天易图与布尔代数的等价性.
  *Zhexue dongtai* 哲学动态 2017(11): 88–92. Proves the Fuxi (先天) eight-trigram diagram is isomorphic
  to the Boolean algebra 2³ — a structure characterization of the *trigram* diagram, not the sequence.
- **Hou Weimin 侯维民** (1997). "Fuxi guatu zhong de buer daishu" 伏羲卦图中的布尔代数. *Zhouyi yanjiu*
  周易研究 1997(3): 81–85. A Boolean-algebra reading of the Fuxi diagram (八卦 as B₂³, 64 as B₂⁶); descriptive.
- **Ke Zineng 柯资能** (2001). *Zhouyi yanjiu* 周易研究 2001(3): 79–91. The Fuxi (先天) order as a binary
  ordinal (Peano-style) system; concerns 先天, not King Wen.
- **Wang Junlong 王俊龙** (2002–2005 trilogy; 2010; 2014). Numerological constructions that presuppose
  the received King Wen order (back-fitting rather than deriving it).
- **Wu Guokai 吴国凯** (2012). *Yangming xuekan* 阳明学刊 6: 193–226. A formula fitting the Jing Fang
  eight-palace (京房八宫) order, within Ouyang (1992)'s coset framing.
- **Zhang Kebin 张克宾** (2020). "Guaxu er ti" 卦序二题. *Zhongguo zhexue shi* 中国哲学史 2020(2): 49–55.
  An exegetical treatment that itself notes the ordering's non-uniqueness.
- **Zhao Zhongguo 赵中国** (2008). *Zhouyi yanjiu* 周易研究 2008(1): 75–82. A historiographical survey of
  the 先天-diagram / binary-encoding debate.
- **Su Zhi 苏智** (2017). *Weinan shifan xueyuan xuebao* 渭南师范学院学报 32(15): 45–50. A
  Saussurean-semiotics reading (non-mathematical).

---

## Methodological and algorithmic citations

### Enumeration algorithms

<a id="hierholzer1873"></a>
- **Hierholzer, Carl** (1873). "Ueber die Möglichkeit, einen Linienzug ohne Wiederholung und ohne Unterbrechung zu umfahren." *Mathematische Annalen* 6(1): 30–32. [doi:10.1007/BF01442866](https://doi.org/10.1007/BF01442866) Eulerian-circuit algorithm, used by ROAE's randomized de Bruijn sampler.
<a id="fisher-yates1938"></a>
- **Fisher, R. A. and Yates, F.** (1938). *Statistical Tables for Biological, Agricultural and Medical Research* (3rd ed.), Oliver & Boyd, London. Fisher-Yates shuffle algorithm, used in `--null-random` and `--null-pair-constrained`.
<a id="burnside-cauchy-frobenius"></a>
- **Burnside / Cauchy–Frobenius orbit-counting lemma** (standard; see Burnside, W., *Theory of Groups of Finite Order*, Cambridge University Press, 1897). The orbit-counting identity (|orbits| = average number of fixed points over the group) underlying ROAE's symmetry-quotient exact count in [TR-11](../reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md).
<a id="mckay1998"></a>
- **McKay, Brendan D.** (1998). "Isomorph-free exhaustive generation." *Journal of Algorithms* 26(2): 306–324. Canonical-representative / isomorph-free generation tradition; the lineage ROAE's canonical-mask orbit enumeration follows (TR-11).

### Random number generation

<a id="marsaglia2003"></a>
- **Marsaglia, George** (2003). "Xorshift RNGs." *Journal of Statistical Software* 8(14): 1–6. [doi:10.18637/jss.v008.i14](https://doi.org/10.18637/jss.v008.i14) Xorshift64 variant used in `--null-random` and `--null-pair-constrained`.

### Statistical methodology

<a id="wilson1927"></a>
- **Wilson, E. B.** (1927). "Probable inference, the law of succession, and statistical inference." *Journal of the American Statistical Association* 22: 209–212. [doi:10.1080/01621459.1927.10502953](https://doi.org/10.1080/01621459.1927.10502953) Wilson score interval, used for confidence intervals on the null-model proportions.
<a id="bonferroni1936"></a>
- **Bonferroni, Carlo Emilio** (1936). "Teoria statistica delle classi e calcolo delle probabilità." *Pubblicazioni del R Istituto Superiore di Scienze Economiche e Commerciali di Firenze*. Bonferroni correction for multiple testing.
<a id="hanley-lippmanhand1983"></a>
- **Rule of Three** for upper bounds on zero-observed-event rates: see Hanley & Lippman-Hand (1983), "If nothing goes wrong, is everything all right? Interpreting zero numerators." *JAMA* 249(13): 1743–1745. [doi:10.1001/jama.1983.03330370053031](https://doi.org/10.1001/jama.1983.03330370053031)
<a id="knuth1975"></a>
- **Knuth, Donald E.** (1975). "Estimating the efficiency of backtrack programs." *Mathematics of Computation* 29(129): 121–136. The tree-size / backtrack-cost estimator — ROAE's load-bearing statistical instrument for the search-space size ([TR-4](../reports/TR4_SIZE_OF_THE_SPACE.md)) and the exact-count cross-witness (TR-9, TR-11).

### Equivariance / symmetry arguments

*(Added 2026-07-30 — resolves a dangling pointer: `lean/README.md` and `lean/KingWen.lean`'s
equivariance-ceiling hedges said "see CITATIONS.md" for Curie/Smidt, but no entries existed here.)*

<a id="curie1894"></a>
- **Curie, Pierre** (1894). "Sur la symétrie dans les phénomènes physiques, symétrie d'un champ
  électrique et d'un champ magnétique." *Journal de Physique Théorique et Appliquée* 3(1): 393–415.
  Curie's principle — the symmetry of causes reappears in effects — is the *argument* underlying the
  equivariance ceiling in `lean/KingWen.lean` (a G-invariant score induces an output distribution
  constant on each orbit, so no such generator can concentrate on a single orbit element,
  P ≤ 1/|orbit|). **No novelty is claimed for the argument**; ROAE's contribution is bounded to its
  instantiation at the King Wen record orbit (the 1/24 constant riding on `twins_24_records`) and
  the machine-checked formalization.
<a id="smidt2021"></a>
- **Smidt, Tess E.; Geiger, Mario; Miller, Benjamin Kurt** (2021). "Finding symmetry breaking order
  parameters with Euclidean neural networks." *Physical Review Research* 3, L012002.
  [doi:10.1103/PhysRevResearch.3.L012002](https://doi.org/10.1103/PhysRevResearch.3.L012002)
  The equivariant-ML symmetry-breaking literature that works Curie's principle out explicitly in the
  modern setting; the two companion treatments the lean hedge also names: "Symmetry Breaking and
  Equivariant Neural Networks" ([arXiv:2312.09016](https://arxiv.org/abs/2312.09016)) and "Improving
  Equivariant Networks with Probabilistic Symmetry Breaking"
  ([arXiv:2503.21985](https://arxiv.org/abs/2503.21985)).

### SAT solving, proof checking, and certified model counting

*(Added 2026-07-31 — the SAT/certificate layer (`sat.py`) used these tools but had not
formally cited them. The TR-2 conflict theorem, the rigidity/C3 CNF gates, and the
certified-counting checks rest on this stack.)*

<a id="sinz2005"></a>
- **Sinz, Carsten** (2005). "Towards an Optimal CNF Encoding of Boolean Cardinality
  Constraints." In *Principles and Practice of Constraint Programming (CP 2005)*, LNCS 3709.
  The sequential-counter cardinality encoding used in `sat.py`.
<a id="kissat2022"></a>
- **Biere, Armin; Fleury, Mathias** (2022). "Gimsatul, IsaSAT and Kissat Entering the SAT
  Competition 2022." In *Proc. of SAT Competition 2022 — Solver and Benchmark Descriptions*,
  University of Helsinki. [hdl:10138/359079](http://hdl.handle.net/10138/359079). The Kissat
  SAT solver used to decide the conflict-theorem and rigidity instances.
<a id="drattrim2014"></a>
- **Wetzler, Nathan; Heule, Marijn J. H.; Hunt, Warren A.** (2014). "DRAT-trim: Efficient
  Checking and Trimming Using Expressive Clausal Proofs." In *Theory and Applications of
  Satisfiability Testing (SAT 2014)*, LNCS 8561. The DRAT proof checker that independently
  replays every UNSAT certificate (removing us from the trust chain).
<a id="d4-2017"></a>
- **Lagniez, Jean-Marie; Marquis, Pierre** (2017). "An Improved Decision-DNNF Compiler."
  In *Proc. IJCAI 2017*. The D4 knowledge compiler underlying the certified model-counting checks.
<a id="cpog2023"></a>
- **Bryant, Randal E.; Nawrocki, Wojciech; Avigad, Jeremy; Heule, Marijn J. H.** (2023).
  "Certified Knowledge Compilation with Application to Verified Model Counting." In *Theory and
  Applications of Satisfiability Testing (SAT 2023)*, LIPIcs vol. 271.
  [doi:10.4230/LIPIcs.SAT.2023.6](https://doi.org/10.4230/LIPIcs.SAT.2023.6). The CPOG
  certified-proof framework (built on D4, with a Lean 4 verified checker) behind the
  model-counting certificates.

### Information theory (description length / MDL)

<a id="rissanen1978"></a>
- **Rissanen, Jorma** (1978). "Modeling by shortest data description." *Automatica* 14(5): 465–471. Two-part minimum-description-length principle — the methodological foundation of [TR-9](../reports/TR9_PRICING_THE_CONSTRAINTS.md)'s "pricing the constraints" bit-ledger. ROAE applies this framework to the King Wen object; the two-part-code framework itself is Rissanen's (not original to ROAE).
<a id="grunwald2007"></a>
- **Grünwald, Peter D.** (2007). *The Minimum Description Length Principle.* MIT Press. Comprehensive MDL reference for the two-part code used in TR-9.

### File formats and cryptographic hashing

<a id="nist2015"></a>
- **National Institute of Standards and Technology** (2015). "Secure Hash Standard (SHS)." *FIPS PUB 180-4*. [doi:10.6028/NIST.FIPS.180-4](https://doi.org/10.6028/NIST.FIPS.180-4) SHA-256 specification, used for the canonical `solutions.bin` integrity anchor.
<a id="drat2014"></a>
- **Wetzler, Nathan; Heule, Marijn J. H.; Hunt, Warren A. Jr.** (2014). "DRAT-trim: Efficient Checking and Trimming Using Expressive Clausal Proofs." *Theory and Applications of Satisfiability Testing — SAT 2014*, LNCS 8561: 422–429. The DRAT proof format + checker underlying ROAE's UNSAT certificates (TR-2, TR-6).

### Combinatorial identities

- **van Aardenne-Ehrenfest, T. and de Bruijn, N. G.** (1951). Listed above under de Bruijn; also the reference for the BEST theorem enumeration of de Bruijn sequences: for B(2, n), the count of distinct cyclic sequences is $2^{2^{n-1}-n}$, which at n=6 gives $2^{26} = 67{,}108{,}864$ (= half of the 2^27 rooted Eulerian circuits that ROAE's `--null-debruijn-exact` enumerates).

---

## Integer Sequences (OEIS)

<a id="oeis-a102241"></a>
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
3. **Large-scale budgeted enumeration under the C1+C2+C3 conjunction at 10T, 100T, and 560T scale** (every sub-branch budget-limited, none exhausted — see [SEARCH_SPACE_SIZE.md](SEARCH_SPACE_SIZE.md); "exhaustive" corrected to "budgeted" 2026-08-01 to match the repo's own coverage framing; constraint set is the full C1–C5 canonical — "C1+C2+C3" in older text is legacy naming for the same population, see METHODS §"Legacy shorthand"; corrected 2026-08-01 from an earlier parenthetical of mine that asserted C1+C2+C3 was the narrower truth) — 10,525,271,997 d3 560T (sha `9a968fa2…`, 2026-06-08, **current deepest**) / 3,432,399,297 d3 100T (sha `915abf30…`) / 706,427,594 d3 10T (current canonical `b85c8871…`) / 286,357,503 d2 10T. Revealed that the boundary-minimum is monotone non-decreasing with scale (greedy minimum: 4 at 10T, 5 at 100T, 5 at 560T with the identical set {1, 4, 21, 25, 27}; working 4-set count drops 8 → 0 across 11.2T → 560T, where the 8 is log-verified at d3 10T and the 11.2T attribution is pending archived-log confirmation (note added 2026-07-04) — see [BOUNDARY_MINIMUM.md](BOUNDARY_MINIMUM.md); corrected 2026-07-04 from an earlier "non-monotone, 4 again at 560T" reading, a survivor-counting error) and that KW sits at the C3 ceiling, not the floor, reaffirmed at 560T.
4. **Comprehensive null-model testing framework** — seven structured and unstructured permutation families tested via `solve.c --null-*` subroutines: de Bruijn, Gray, Latin-square, lexicographic, historical, random, pair-constrained.
5. **Analytic C1 impossibility proofs** for the de Bruijn B(2, 6) family (period-4 contradiction) and the Gray code family (Hamming-1 disjoint). See [CRITIQUE.md](CRITIQUE.md).
6. **Latin-square C2 rate decomposition** — analytic explanation of the 57.96% rate as a function of row-permutation class (Hamiltonian-path popcount distribution in the 3-cube). See [CRITIQUE.md](CRITIQUE.md).
7. **Partition-stability analysis** — the finding that boundaries {25, 27} are mandatory in every working 4-boundary set at BOTH d2 and d3, while the other two boundaries are partition-dependent.
8. ~~**Mawangdui C2 observation** — that the ancient silk-text ordering accidentally satisfies C2 (zero 5-line transitions) while failing C1 and C3.~~ **WITHDRAWN 2026-07-05**: this was an artifact of an erroneous Mawangdui array (see the erratum in §Mawangdui above). The authentic ordering (Shaughnessy 2022, Table 11.2) has exactly one 5-line transition, at a trigram-octet seam. The replacement observation — that Mawangdui's sole C2 breach sits exactly at a mechanical block boundary — is noted but not claimed as novel.
9. **C3 total complement distance as a specifically quantified constraint** — 776 (= 12.125 × 64) as the King Wen value, positioning KW at the 3.9th percentile (sampled — **flagged 2026-08-01, see [SOLVE.md](SOLVE.md) §Rule 3; the novelty claim stands on 776 itself, not on this percentile**) within orderings satisfying the other constraints (C1+C2+C4+C5; scope label corrected 2026-07-22 — the exact bare C1&C4-null tail is 8.1%).
10. **Format v1 `solutions.bin`** — canonical binary format with 32-byte header + 32-byte records, designed for partition-invariant sha256 reproducibility.

Each of the above claims to originality is **tentative** — if you find prior work establishing any of them, please contact the author and this document will be updated.

<a id="uniqueness-conjecture"></a>
## The "Uniqueness Conjecture" — attribution note (added 2026-07-11)

The conjecture refuted in [TR-4](../reports/TR4_SIZE_OF_THE_SPACE.md) — that the published constraints
uniquely determine the King Wen sequence — carries a name **coined by this project**, and honesty
requires saying who actually held it. To our knowledge, **no author asserted in so many words that the
C1–C7 constraint inventory pins down the sequence**. What the refutation decides is:

- **The strong reading of the literature's derivation-flavored claims.** Several programs present the
  sequence as derivable from structural principles — most prominently [Cook (2006)](#cook2006), whose
  monograph is titled *…Derivation of the Book of Changes Hexagram Sequence* and derives the full
  sequence within his own framework. Each such program invokes principles beyond the C1–C7 inventory
  tested in TR-4, so the refutation does **not** contradict any of those works as stated; it decides the
  narrower, natural question their framing raises — whether the published constraint system alone
  determines the sequence. It does not: ≈5.2×10³¹ orderings survive C1–C7.
- **This project's own early working hypothesis.** ROAE's discovery phase operated on the assumption
  that the extracted constraints might isolate King Wen at scale; the measurement refuted our own
  expectation along with the strong reading.

**Prior negatives (appended 2026-07-30, novelty-gate review).** The refutation's *direction* has
substantial prior support — several authors asserted or conceded under-determination before ROAE
measured it: [Ouyang Weicheng (1990)](#ouyang1990) stated the sharpest form (no intrinsic order; an
ordering must be imposed by added conditions), having himself in 1987 denied the sequence any
mathematical structure at all (a denial he reversed by 1990 — see the [#ouyang1992](#ouyang1992)
entry); [Zhang Qingyu's (1998)](#zhang1994) orbit analysis conceded it could not fix the 48 散卦
within his framework (his 2000 sequel proposes a completion); and [Suenaga (2012)](#suenaga2012)
reported finding no rule that fixes the King Wen sequence. All of these are qualitative/speculative
statements; ROAE's contribution is the measurement (≈5.2×10³¹ C1–C7 survivors). None of them
asserted the *positive* conjecture (that the published constraint inventory pins down the sequence),
so the attribution note above stands.

If you know of prior work asserting constraint-determinism of the sequence directly, please report it
and this note will be upgraded to a direct attribution.

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
<a id="hacker-moore2003"></a>
- **18:18 two-part class split** (18 inversion-classes in each half of the text): classical observation —
  **Zhang Xingcheng 张行成** and **Zhu Xi 朱熹** (Song dynasty, per the first-hand pass of
  [Li Shangxin (2008)](#li2008); *attribution corrected 2026-07-30 — this entry previously credited
  Zheng Qiao (c. 1104–1162), a claim the primary pass could not support: Li's treatment attributes the
  observation to Zhang Xingcheng and Zhu Xi, and Zheng Qiao does not appear*) and **Hu Yigui** (b. 1247, the 36-figure condensation); modern treatment
  **Hacker, E. & Moore, S.,** "A brief note on the two-part division of the received order of the hexagrams
  in the Zhouyi," *Journal of Chinese Philosophy* 30:2 (2003), 219–221 ([doi:10.1163/15406253-03002005](https://doi.org/10.1163/15406253-03002005)); also Cook 2006.
- **Pair-positioning parity rule** (yang-preponderant pairs at odd pair-positions, yin-preponderant at even;
  14 balanced pairs exempt; King Wen complies 16/18 with the two violations at adjacent pair positions
  22–23): **Moore, Steve,** "Structural Elements in the King Wen Sequence of Hexagrams," *Oracle Papers*
  No. 1, London, 2005 (revised from *The Trigrams of Han*, Aquarian Press, 1989, pp. 188–198), building on
  the *Dazhuan* odd=Heaven/yang, even=Earth/yin attribution. Moore also conjectured a fully-compliant
  (18/18) precursor ordering; ROAE's population measurement addresses that conjecture empirically.
- **Gender/position-parity rule over the 36 consolidated units** (the strongest measured literature
  discriminator at the time of the SAT work, ×11,364; later exceeded by the S25–28 trigram rule at
  ×5×10⁷ — see [LITERATURE_RULES_POPULATION_TESTS.md](LITERATURE_RULES_POPULATION_TESTS.md)): **Schulz, Larry J.,** "Structural motifs in the arrangement of the 64 gua in the
  Zhouyi," *Journal of Chinese Philosophy* 17:3 (1990), 345–358 — his second motif, incl. the exceptions at
  stations 25–26; elaborated by Cook 2006 (attribution corrected 2026-07-03 upon first-hand reading; Cook
  had been credited as primary). The lineage extends further back: per Schulz 2018 (fn. 42), the single
  exception to the parity rule was first recognized by **Zhu Yuansheng (13th century)**. Schulz's later
  treatments: "Structural Elements in the Zhou Yijing Hexagram Sequence," *JCP* 38:4 (2011), 639–665
  (formalizes the "exception-proves-the-rule" design principle); *Hexagrammatics: Rules and Properties in
  Binary Sequences*, 2nd ed. (Zizai, 2016); "N Gua Theory" (ZiZai, 2018). The companion seasonal
  hypothesis: Schulz & Cunningham, "The Seasonal Structure Underlying the Arrangement of Hexagrams in the
  Yijing," *JCP* 17 (1990), 289–313. Schulz's first motif (balance-value pairing) and third (xiaoxi trisection,
  with Schulz & Cunningham 1988 seasonal hypothesis) are under population test as R-S2/R-S1. The pair
  structure's classical lineage runs to <a id="yufan"></a>**Yu Fan (164–233 AD)** (pangtong/fandui, via Li Dingzuo) and the
  36-unit consolidation + 18:18 reasoning to <a id="laizhide"></a>**Lai Zhide (1525–1604)**; **Davis, Scott,**
  *The Classic of Changes in Cultural Context* (Cambria, 2012) and "Operating the Yijing Apparatus,"
  *The Oracle* 2:7 (1998).

## Trigram-level theorems (2026-07-11) — per-result credits

The machine-checked trigram theorems ([lean/TrigramTheorems.lean](../lean/TrigramTheorems.lean)) carry
per-result credits; the binding attribution/novelty ledger travels in the Lean file's header and is
reproduced in [TRIGRAM_STRUCTURE.md](TRIGRAM_STRUCTURE.md) §4 — this list is the bibliographic index into
this document:

- **The "9th six"** (exactly one Hamming-distance-6 transition, i.e. one boundary complementing both
  trigrams simultaneously): the *observation* is due to [McKenna & McKenna (1975)](#mckenna-mckenna1975)
  (see [MCKENNA.md](MCKENNA.md)). ROAE's contribution is the derivation from C1+C5 for **every** valid
  ordering (TG-2, `ninth_six_trigram`), turning the 560T-scale measurement into a corollary; the 9th six's
  *position* remains ordering-dependent.
- **Classical/algebraic foundations of the trigram factorization layer (TG-1)**: the ambient algebra is
  [Goldenberg (1975)](#goldenberg1975) (Theorem 4; the (654321) line-permutation framing), with
  [Schöter (1998)](#schoter1998) for the Boolean-algebra vocabulary. The placement of the 8 doubled-trigram
  ("pure") hexagrams in adjacent pairs is classical: [Lai Zhide](#laizhide) (16th c., via
  [Schulz 1982](#schulz1982)) and [Wu Deng](#wudeng)'s warp/weft skeleton (13th c., via
  [Nielsen 2003](#nielsen2003)). Nothing in TG-1 is claimed as a discovery; the contribution is the
  machine-checked lemma layer only (the three TG-1 counts are kernel `decide` since 2026-07-27,
  migrated from `native_decide` — the 2026-07-26 label correction is thereby resolved in the strong
  direction).
- **TG-3** (exactly 12 of the 48 constraint symmetries respect the trigram bipartition; ≅ S₃ × C₂):
  project-specific — the constraint-symmetry group itself is project-specific — with
  [Goldenberg (1975)](#goldenberg1975) credited for the ambient S₆-on-the-set framing. **Not** to be
  conflated with [Hershock (1991)](#hershock1991)'s group generated by complement, reversal, and trigram
  swap acting on the hexagram *set* (his 14 "families of derivation") — a different group acting on a
  different object; see [TRIGRAM_STRUCTURE.md](TRIGRAM_STRUCTURE.md) §2. No located external prior art —
  a statement about our literature search, not a novelty guarantee; corrections invited.
- **TG-4** (nuclear naturality): the nuclear map and its 64 → 16 → 4 image chain are classical (commentary
  tradition; treated in [Hershock 1991](#hershock1991) as "linking" and in [Cook 2006](#cook2006)); the
  commutation/descent lemmas are presumed classical/implicit — no discovery claimed.
- The **pangtong-successor** and **flanking-exclusion** corollaries (TG-2) appear to be new *as explicit
  propositions*, hedged: the pangtong relation across King Wen's #37–38 → #39–40 boundary may well be
  remarked in the classical or structuralist literature (Schulz's and Cook's pair-relation tables are the
  places to check before any publication claim; the pangtong pair-relation concept itself is classical —
  [Yu Fan](#yufan), 164–233 AD). Corrections invited, per the standing invitation above.

## First-principles optimality of the pairing (C1) — Radisic 2026

**Radisic, Alejandro.** "Optimal Equivariant Matchings on the 6-Cube, With an Application to the King Wen
Sequence." arXiv:2601.07175 (v3, May 2026). *Verification status (2026-07-26): his Lean 4 + Mathlib
artifact (the arXiv ancillary source) was independently rebuilt and re-verified by this project —
`lake build` clean on the pinned toolchain, zero `sorry`/`admit`/axiom declarations, axiom audit on the
main theorems — and the comp/rev optimality theorem is additionally machine-checked in-repo with a
kernel-only proof ([lean/HammingOptimalMatching.lean](../lean/HammingOptimalMatching.lean); see
[lean/README.md](../lean/README.md) for the full verification record, including two documented
artifact-level findings that do not affect the result).* Proves (Lean 4 + Mathlib verified) that among comp/rev
matchings on {0,1}⁶ there is a **unique Hamming-cost minimizer** — the reverse-priority rule, which is
exactly this project's `partner()` function / the C1 pairing — with cost 120 (vs 192 complement-only;
independently confirmed by our within-pair distance table 2×12+4×12+6×8 = 120); that the King Wen sequence
realizes precisely this matching; and that under the full Klein four-group the King Wen rule is recovered
as the unique Hamming-weight-preserving optimum (stable for the energy α|Δw|+βd_H whenever α > β).
**Effect on this project's claims:** C1's provenance upgrades from "classical + measured-rare" to
"classical + measured-rare + *derived as the unique optimum of a natural variational principle*" — to our
knowledge, the first *variational* (optimality-principle) first-principles derivation of any layer of the
constraint system (derivation programs in the Cook tradition derive the sequence within richer frameworks —
see the [uniqueness-conjecture note](#uniqueness-conjecture); corrections welcome), and it is Radisic's, not
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

<a id="chan2026"></a>
Chan, A. (2026). *Statistical properties of the King Wen sequence: An anti-habituation structure that does
not improve neural network training*. arXiv:2604.09234 (v2, revised 2026-06-25). https://arxiv.org/abs/2604.09234
[doi:10.48550/arXiv.2604.09234](https://doi.org/10.48550/arXiv.2604.09234)
  Monte Carlo statistical analysis of the sequence against 100,000 random permutations; predates ROAE;
  per-finding overlap scoped above. *Version check (2026-08-01, strengthened 2026-08-01): our reading was taken against v1; the
  paper has since been revised to v2 (2026-06-25). **The author's own arXiv version comment states the
  revision "added two figures; corrected author names/titles for two cited references" and
  "code-availability attribution; no changes to results or conclusions."** The v1 and v2 abstracts are
  additionally byte-identical. The overlap analysis therefore stands as written. (An earlier form of this
  note inferred "no result changed" from the identical abstracts alone — a stronger conclusion than that
  evidence supports, since abstracts do not carry body percentiles; the author's statement is the actual
  warrant and is now cited in its place.)*
  [read]

<a id="clarke1987"></a>
Clarke, A. G. (1987). Probability theory applied to the I Ching. *Journal of Chinese Philosophy, 14*(1),
65–72. [doi:10.1163/15406253-01401004](https://doi.org/10.1163/15406253-01401004)
  [analyzed 2026-07-09 — OUT-OF-SCOPE: divination mechanics, not the ordering. Computes yarrow-stalk vs.
  three-coin line-change probabilities over the 4,096 = 64×64 cast → related-hexagram space and derives a
  hexagram study-prioritization heuristic; never permutes or statistically tests the King Wen sequence, so
  not found to be prior art for any ROAE null-model / ordering result. Appears in the same JCP 14:1 issue
  as Hacker (1987), immediately following it. Cites Gardner (1974, *Scientific American*) for the yarrow
  1/16-yin vs. 3/16-yang per-line change probabilities — divination content from the same Jan-1974
  column cited in full at [Gardner (1974)](#gardner1974); Clarke builds on its divination-probability
  content, ROAE leans on its ordering-problem statement. Background only.]

<a id="cook2006"></a>
Cook, R. S. (2006). *Classical Chinese combinatorics: Derivation of the Book of Changes hexagram sequence*
(STEDT Monograph Series No. 5). University of California, Berkeley.
  The most extensive modern derivation system; source of several measured rules (final-pair anchor, level
  coverage) and elaborator of the Schulz gender rule. [analyzed]

<a id="davis1987"></a>
Davis, S. [= Dai Sike 戴思客] (1987 [or 1995 — see note]). *Jiegou yu lishi: Lüetan Zhongguo gujingwen
de zucheng wenti* 結構與歷史：略談中國古經文的組成問題 [Structure and history: Remarks on the problems
in the composition of ancient Chinese classical texts]. Taipei: Wenshizhe (The Liberal Arts Press).
81 pp., bilingual (English text pp. 29–81); ISBN 957-547-951-3.
  Dating conflict we cannot yet resolve: Hacker, Moore & Patsco (2002, entry A:109) date it 1987;
  the memorial bibliography in *Sino-Platonic Papers* 359 (von Falkenhausen, 2024) dates it 1995.
  Either way it predates the 1998 *Oracle* article: per the H/M/P annotation it already contains the
  #7–#16 block-symmetry observation (measured at population scale in
  [TR-10](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md)) and Davis's position that the received
  order cannot be described by a mathematical formula. The block-symmetry observation itself is older
  still: SPP 359 identifies Dai Sike 戴思客 as Davis's own Chinese name, under which he published
  "Cong jiegouguan zhankan Yijing daxiaogua" 從結構觀點看易經大小卦, *Ehu yuekan* 43: 33–35 (1979 per
  SPP 359; Davis's own 2012 footnote dates it 1978) — the article Davis (2012, p. 87 n32) cites for
  the 7–16 symmetry. Not prior art for any ROAE constraint; origin-dating for the Davis structural
  program only. Corrections welcome — primary texts not obtained. [secondary]

<a id="davis1998"></a>
Davis, S. (1998). Operating the Yijing apparatus: A compositional analysis. *The Oracle: The Journal of
Yijing Studies, 2*(7). [not obtained]

<a id="davis2012"></a>
Davis, S. (2012). *The classic of changes in cultural context: A textual archaeology of the Yi jing*.
Cambria Press.
  Window-symmetry claims; the flagship compositional-unit rule measures population-typical (×7;
  figure predates the purchase). Audited first-hand 2026-07-04 (26-claim structural audit of the
  purchased e-book) and measured at population scale the same day in
  [TR-10](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md): nine pre-registered composites — four
  null, one Bonferroni-notable (the #43–50 trigram array), one borderline, three data-like; nothing
  promotes. One uniqueness claim (p. 257 n.2, fewest-derivatives status of #63/64) is refuted with
  a concrete counterexample (#51/52), his worked examples confirmed; a second candidate refutation
  (p. 114) was withdrawn under our own hostile review — that claim survives its fairest reading
  (TR-10 §4). One further claim of his — the big/little named-hexagram size pattern (pp. 94–96: the
  six "big"/"small"-named hexagrams #9/#14/#26/#28/#34/#62 sited small–big–big–big–big–small by
  pair-slot, which King Wen satisfies) — was conditionally frozen as a follow-up candidate and then
  **declined without measurement on 2026-07-11** by a project scope decision: it would take hexagram
  *names* (a tradition/translation-dependent semantic attribute) rather than bit structure as input,
  its target template is itself read off King Wen, and TR-10 §5(c) had already placed names "outside
  this instrument." The observation remains Davis's, credited here; the decline is ours and is not a
  verdict on it. The follow-up family's Bonferroni denominator stays frozen at /12, fixed before the
  decision so the decline cannot weaken the correction (see [HISTORY.md](HISTORY.md), 2026-07-11).
  A second wave (complete design — functionals, KW values, gates, /12 denominator — fixed in the
  **public** commit `09e2107`, 2026-07-11, before the public results; a private freeze-timestamp exists as
  non-load-bearing provenance only, see TR-10 §3b; measured 2026-07-11) closed the audit
  queue: the coordinated rotation-quartet configuration behind his surviving p. 114 claim measures
  population-common (~88% of valid orderings contain one at his own compactness — NULL; the in-KW
  uniqueness stands), and the wind-trigram slot count lands mildly above expectation (NULL); an
  analytic power note at the same landing shows the declined named-size test could never have
  attained p below 1/15 under the pair-exchangeable null
  ([TR-10 §3b](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md)). [read]

<a id="drasny2007"></a>
Drasny, J. (c. 2007). *The regular grouping of the hexagrams before the Yi jing* [Paper]; *The Yi-globe:
The image of the cosmos in the Yijing* [Book].
  Early-Predecessor theory with four "alien" pairs as anomaly loci; also author of a critical review of
  Cook (2006). His book's ch. IV "Rule of Ten" (presented there as a previously unreported
  regularity — his claim, recorded as his) — the eight trigram-defined functional groups occupy
  decade-arithmetic "rooms" of the King Wen table, with ten deviant pairs — was operationalized
  and measured (D-B1; measured 2026-07-11, landed 2026-07-12): the observation is true and
  verified (his Table 4.1 group classifier reproduces 64/64 from pure bit predicates,
  two-language `--db1-verify` gate;
  KW conformity X = 22/32 with his ten deviant pairs exact), but each "room" is verifiably the
  maximum-coverage decade window for its own group's King Wen positions plus a residue, so the
  count is a fitted description scored against its own source — classified data-like, no p-value
  attached, no design inference ([TR-10 §3b](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md);
  process record in [CRITIQUE.md](CRITIQUE.md)). Unrelated to Davis 2012's separately-named
  "rule of ten" (p. 126). Paper [analyzed, via mirror]; book [read].

<a id="ge2026"></a>
Ge, Z. (2026). The cycle structure of the King Wen permutation: A group-theoretic analysis of two classical
hexagram orderings (v1.0). Zenodo. [doi:10.5281/zenodo.19143997](https://doi.org/10.5281/zenodo.19143997)
(CC BY 4.0; code MIT). Published 2026-03-21.
  Related quantitative analysis — **not prior art for any ROAE constraint or count.** Ge treats the (much
  later) Shao Yong binary → King Wen map as an element of S₆₄ and reports its cycle type **(52, 10, 2)**,
  order 260, zero fixed points — a descriptive, post-hoc permutation statistic of the same sequence, not a
  generative rule, constraint, or enumeration. That cycle-decomposition result is Ge's own contribution:
  ROAE never claimed it (our C2 tooling reproduces it, but we make no priority claim on it, and Ge reports
  finding no prior instance in the literature surveyed). Where Ge and ROAE numerically coincide is only in
  trivially-reproducible descriptive statistics of the fixed sequence — mean adjacent Hamming 3.349 over the
  63 transitions (ROAE's exact multiset `{1:2, 2:20, 3:13, 4:19, 6:9}`, mean 211/63 ≈ 3.3492) and the ~3:1
  even:odd step ratio — and **neither is novel to ROAE or Ge**: ROAE credits the mean-Hamming-vs-random
  observation to [Chan (2026)](#chan2026) and the even:odd ratio to [McKenna 1975](#mckenna-mckenna1975) /
  [Cook 2006](#cook2006) as prior art. So this is not a ROAE-vs-Ge concurrent discovery; it is an independent
  third computation of shared, well-trodden statistics — which we welcome as an external cross-check that our
  C2 encoding reproduces Ge's numbers byte-for-byte (verified 2026-07-09, including Ge's exact permutation
  array). Corrections invited. [analyzed 2026-07-08; timing + independent-computation framing added 2026-07-09]

<a id="hacker1982"></a>
Hacker, E. A. (1982). Temperature and the assignment of the hexagrams of the I-Ching to the calendar.
*Journal of Chinese Philosophy, 9*(4), 395–400. [doi:10.1163/15406253-00904002](https://doi.org/10.1163/15406253-00904002)
  [analyzed 2026-07-08 — OUT-OF-SCOPE: guaqi calendar/temperature assignment (monthly yang-line counts
  correlate ~.96 with temperature records), not the King Wen 64-order; no C1–C5. Background only.]

<a id="hacker1983"></a>
Hacker, E. A. (1983). A note on formal properties of the later heaven sequence. *Journal of Chinese
Philosophy, 10*(2), 169–171. [doi:10.1163/15406253-01002004](https://doi.org/10.1163/15406253-01002004)
  [analyzed 2026-07-08 — OUT-OF-SCOPE: the **8-trigram** Later Heaven (bagua) arrangement (a magic-square
  generative recipe for the trigram circle), a different object from ROAE's 64-hexagram order. Background only.]

<a id="hacker1987"></a>
Hacker, E. A. (1987). Order in the textual sequence of the hexagrams of the I Ching. *Journal of Chinese
Philosophy, 14*(1), 59–64. [doi:10.1163/15406253-01401003](https://doi.org/10.1163/15406253-01401003)
  Possibly the earliest Western formal ordering analysis. [analyzed]
  *Erratum (reader's note, 2026-07-07):* in Fig. 2 (p. 61) the cell for hexagram 41 (Olsvanger square,
  row 6, rightmost) is misprinted <mark>**39**</mark>; the correct value is <mark>**49**</mark> (hexagram 41 written bottom-line-
  first is 110001 = 49). Confirmed three ways: direct computation; 63 of the 64 cells match; and
  Hacker's own Fig. 4 (p. 63) prints 49 at that same cell, which the Fig. 2 → Fig. 4 transformation
  leaves unchanged. A minor typographical error introduced in Hacker's reproduction: the primary source
  (Olsvanger, *Fû-Hsî: The Sage of Ancient China*, Massadah, Jerusalem, 1948, p. 10) prints **49**
  correctly and consistently across all three copies of the square, so the error is Hacker's typesetting,
  not inherited from the source. (Hacker cites Olsvanger as 1984; the original is 1948 — 1984 is a reprint.)

<a id="hacker-moore2002"></a>
Hacker, E. A., Moore, S., & Patsco, L. (2002). *I Ching: An annotated bibliography*. Routledge. [analyzed]

<a id="hershock1991"></a>
Hershock, P. D. (1991). The structure of change in the I Ching. *Journal of Chinese Philosophy, 18*(3),
257–285. [doi:10.1111/j.1540-6253.1991.tb00449.x](https://doi.org/10.1111/j.1540-6253.1991.tb00449.x)
  The only published reply to [McKenna & Mair (1979)](#mckenna-mair1979) we have located: a philosophical
  critique of their Gray-code reordering (an external principle imposed on the hexagram system; a rigid
  opposition/contingency alternation), which nonetheless shares their premise that the received pair
  sequence is globally random — the premise TR-8 measures — and answers with a third reordering, a
  circular mandala built from the complement, reverse, trigram-swap, and nuclear operations. Its
  "families of derivation" appendix is a correct orbit decomposition of the 64 hexagrams under the group
  generated by complement, reverse, and trigram swap (14 orbits; machine-verified against ROAE's tables
  2026-07-10, zero errors). Contains no transition statistics or constraint analysis of the King Wen
  order itself; reception history for TR-8, not prior art for any ROAE constraint or result (corrections
  invited). [analyzed 2026-07-10]

<a id="huang2000"></a>
Huang, A. (2000). *The numerology of the I Ching: A sourcebook of symbols, structures, and traditional
wisdom*. Inner Traditions. [Open Library](https://openlibrary.org/works/OL8444700W)
  Independent 18:18-aware "hidden balance" reasoning, rejected by Hacker & Moore (2003) as special
  pleading. [secondary]

<a id="kunst1985"></a>
Kunst, R. A. (1985). *The original "Yijing": A text, phonetic transcription, translation, and indexes,
with sample glosses* [Doctoral dissertation, University of California, Berkeley].
  Textual scholarship; not used by any ROAE code or finding. [not consulted]

<a id="li2008"></a>
Li, S. 李尚信 (2008). *Guaxu yu jiegua lilu* 卦序与解卦理路 [The hexagram sequence and the logic of
hexagram interpretation]. Bashu Shushe. (228 pp.)
  Book-length study of the received sequence's arrangement logic, working from the 36-unit
  consolidated view. Third-party citations: Davis (2012, p. 119 n19) credits Li
  for the pair-unit trisection at units 13/25 (the same object as our R-S1 measurement — any published
  R-S1 result credits Li alongside Schulz); Schulz (2018, fn. 42) cites him alongside Zhu Yuansheng
  (13th c.) on the first recognition of the parity-rule exception; Shaughnessy (2022, p. 50) cites him
  as arguing the received sequence's antiquity. **Status updated 2026-07-30: acquired and now
  load-bearing** — the book is the source of the six-principle constraint exegesis tracked in the
  project's private acquisition notes, and its first-hand pass grounds the corrected 18:18 attribution
  (Zhang Xingcheng 张行成 + Zhu Xi 朱熹, superseding the unsupported Zheng Qiao credit — see
  [§18:18](#hacker-moore2003) above). [analyzed]

<a id="mckenna-mckenna1975"></a>
McKenna, T., & McKenna, D. (1975). *The invisible landscape: Mind, hallucinogens, and the I Ching*.
Seabury Press.
  Earliest published source of the no-5-line-transition observation (C2) and the difference-wave
  construction. [analyzed]

<a id="mckenna-mair1979"></a>
McKenna, S. E., & Mair, V. H. (1979). A reordering of the hexagrams of the I Ching. *Philosophy East and
West, 29*(4), 421–441. [doi:10.2307/1398813](https://doi.org/10.2307/1398813)
  Gray-code replacement proposal; its structural-poverty premise is now measured and refuted; first to
  test the sequence against constructed alternatives. [analyzed]

<a id="moore1989"></a>
Moore, S. (1989). *The trigrams of Han: Inner structures of the I Ching*. Aquarian Press. [Open Library](https://openlibrary.org/works/OL2534956W)
  Source of the rising/falling rhythm rule (R-M2) and the pairs-22/23 anomaly discussion. [analyzed]

<a id="moore2005"></a>
Moore, S. (2005). *Structural elements in the King Wen sequence* (Oracle Papers No. 1).
  Source of the pair-positioning parity rule (R-M1) and the corruption/precursor conjecture, materialized
  by SAT in 2026. [analyzed]

<a id="olsvanger1948"></a>
Olsvanger, I. (1948). *Fû-Hsî: The Sage of Ancient China*. Jerusalem: Massadah. (OCLC [29364796](https://search.worldcat.org/oclc/29364796).)
  Earliest source located by us that represents the King Wen hexagrams as binary numbers under the
  bottom-line-as-least-significant-bit convention ROAE also uses (p. 7), and lays the sequence out as an
  8×8 numeric square. Olsvanger himself attributes the 0/1 line-valuation to Leibniz (p. 15), claiming
  novelty only for the binary analysis of the square. His symmetric "magic-group" sum properties (pp. 11–14)
  are arithmetic features of that specific layout, not constraints on the ordering; his pairing rule
  (a hexagram with its reversal, or its complement when self-reversal-invariant, p. 4) is the classical
  pair structure, obtained under free within-pair orientation — the orientation layer is relaxed, not
  resolved. No adjacency (C2), complement-distance (C3), fixed-start (C4), or wrap-around content. We credit
  the binary-representation precedent to Olsvanger 1948 and invite correction on earlier sources.
  [analyzed first-hand 2026-07-08]

<a id="radisic2026"></a>
Radisic, A. (2026). *Optimal equivariant matchings on the 6-cube, with an application to the King Wen
sequence*. arXiv. https://arxiv.org/abs/2601.07175 [doi:10.48550/arXiv.2601.07175](https://doi.org/10.48550/arXiv.2601.07175)
  Lean-verified proof that the C1 pairing is the unique Hamming-cost optimum among comp/rev matchings —
  to our knowledge, the first *variational* (optimality-principle) derivation of any constraint layer
  (see the [uniqueness-conjecture note](#uniqueness-conjecture)). Artifact independently rebuilt + re-verified 2026-07-26; theorem
  also machine-checked in-repo ([lean/HammingOptimalMatching.lean](../lean/HammingOptimalMatching.lean)). [read]

<a id="rutt1996"></a>
Rutt, R. (1996). *Zhouyi: The Book of Changes*. Curzon Press. [Open Library](https://openlibrary.org/works/OL4988348W)
  Bamboo-slat cord-fraying physical corruption mechanism (p. 105), via Hacker & Moore (2003). [secondary]

<a id="schoter1998"></a>
Schöter, A. (1998). Boolean algebra and the Yi Jing. *The Oracle: The Journal of Yijing Studies, 2*(7),
19–34.
  Boolean operations and lattice structure on hexagrams — a functionally complete Boolean algebra
  (complement, OR, AND, XOR) extending the XOR/AND algebra of [Goldenberg (1975)](#goldenberg1975) with
  the complement operation Goldenberg lacked; does not address the King Wen ordering. [read in full
  2026-07; previously analyzed via mirror]

<a id="schulz1982"></a>
Schulz, L. J. (1982). *Lai Chih-te (1525–1604) and the phenomenology of change* [Doctoral dissertation,
Princeton University].
  The study of Lai Zhide; recovers Lai's own 16th-century sequence arguments (36-unit consolidation,
  18:18 count, line-balance symmetry). [analyzed]

<a id="schulz1990-motifs"></a>
Schulz, L. J. (1990). Structural motifs in the arrangement of the 64 gua in the Zhouyi. *Journal of
Chinese Philosophy, 17*(3), 345–358. [doi:10.1163/15406253-01703004](https://doi.org/10.1163/15406253-01703004)
  Three motifs over the consolidated units; motif 2 is the strongest measured discriminator at the time
  of the SAT work (×11,364; later exceeded by S25–28 at ×5×10⁷),
  with exceptions at stations 25/26. First-hand read 2026-07-08 confirms ROAE's attribution + dual-CNF
  encoding are correct: the gender rule (motif 2) originates here, but the other conflict-theorem rules
  (S25–28 trigram, exception co-location) are Schulz 2011/2016 — no internal conflict in this paper. [read]

<a id="schulz2011"></a>
Schulz, L. J. (2011). Structural elements in the Zhou Yijing hexagram sequence. *Journal of Chinese
Philosophy, 38*(4), 639–665. [doi:10.1163/15406253-03804010](https://doi.org/10.1163/15406253-03804010)
  Ten-element taxonomy; first formalization of the "exception-proves-the-rule" design principle at
  stations 25/26. [analyzed]

<a id="schulz2016"></a>
Schulz, L. J. (2016). *Hexagrammatics: Rules and properties in binary sequences* (2nd ed.). Zizai.
  Consolidated rule inventory; names stations 25/26 as the double-exception locus for both of his rules.
  [analyzed]

<a id="schulz2018"></a>
Schulz, L. J. (2018). *N Gua theory: Imaging categorical dynamics inherent in binary structures*.
Atlanta: ZiZai. (55 pp.; ISBN 978-1-387-73732-1. ZiZai appears to be the author's own imprint — it
also carries *Hexagrammatics* — with the PDF circulated via ResearchGate and Academia.edu, which is
how it was obtained.)
  Hamming formalism; Ifa cross-cultural parallel; attributes the parity-exception's first recognition
  to Zhu Yuansheng (13th c.), citing [Li Shangxin (2008)](#li2008). [analyzed]

<a id="schulz-cunningham1990"></a>
Schulz, L. J., & Cunningham, T. J. (1990). The seasonal structure underlying the arrangement of hexagrams
in the Yijing. *Journal of Chinese Philosophy, 17*(3), 289–313. [doi:10.1163/15406253-01703002](https://doi.org/10.1163/15406253-01703002)
(Working-paper version: Federal Reserve Bank of Atlanta Occasional Paper Series, 1988.)
  Prior documenter of C4, and an independent documenter of C1 (verified first-hand, 2026-07-08) — though
  [Goldenberg (1975)](#goldenberg1975) documents C1 fifteen years earlier, making Schulz & Cunningham the
  crisper prior source for C4 and the circular-year framing rather than the earliest C1 documenter: §III
  (p. 296) states the invert-pairing
  rule and its self-inverse exception (the eight palindromic gua paired instead with their polar opposite/
  complement) explicitly, and p. 298 states the qian/kun "pure yang / pure yin" precedence as an "unavoidable
  priority"; it also motivates the circular reading, tying the *zhou/zhounian* ("rounded year") etymology to
  reading the order as an annual cycle (p. 297) — a thematic motivation, not a wrap-around adjacency claim.
  Novelty-humility caveat: C1 and C4 are classical facts the paper reports (from the Xugua/Tuan/Xici
  commentary tradition), not ones it invents — ROAE claims only the conjoint C1–C5 system, its exhaustive
  enumeration, and the population-scale measurements, never the pair or start primitives themselves. Its own
  contribution is orthogonal: the guaqi/xiaoxi seasonal framework and a temperature/humidity regression on a
  running line-sum (a descriptive statistical axis); it anticipates none of C2, C3, C5, the ~10^38
  search-space size, the S4 symmetry theorem, or exhaustive enumeration. [analyzed]

<a id="shaughnessy1996"></a>
Shaughnessy, E. L. (1996). *I Ching: The classic of changes*. Ballantine Books.
  Translation of the Mawangdui manuscript. [read, data]

<a id="shaughnessy2022"></a>
Shaughnessy, E. L. (2022). *The origin and early development of the Zhou Changes*. Brill.
  Authority for the Mawangdui ordering tested by `--null-historical` (p. 50 + Table 11.2;
  adopted 2026-07-05, correcting an erroneous earlier array). [read, data]

<a id="smith2000"></a>
Smith, R. J. (2000). *A brief Western-language bibliography of the Yijing (Classic of Changes)*. Rice
University.
  The bibliography that surfaced the Hacker JCP papers. [analyzed]

<a id="waley1933"></a>
Waley, A. (1933). The Book of Changes. *Bulletin of the Museum of Far Eastern Antiquities, 5*, 121–142.
[unread]

<a id="wilhelm-baynes1967"></a>
Wilhelm, R. (1967). *The I Ching or Book of Changes* (C. F. Baynes, Trans.; 3rd ed.). Princeton
University Press.
  Hexagram names used throughout. [read, data]

### Classical sources

Yu Fan (164–233, via Li Dingzuo's *Zhouyi jijie*), Zhang Xingcheng 张行成 and Zhu Xi 朱熹 (Song, the
18:18 split, via Li Shangxin 2008 — *corrected 2026-07-30 from a previously listed "Zheng Qiao (~1150)",
which the Li 2008 primary pass does not support*), Hu Yigui (b. 1247, *Zhouyi Qimeng
Yizhuan*), Lai Zhide (1525–1604, via Schulz, 1982), Kong Yingda (574–648, *Zhouyi zhengyi* — see the
[§C1 entry](#kongyingda)), and Zhu Yuansheng (13th c., via Schulz, 2018) are all
[secondary], known through the modern literature above.

### Websites

<a id="moore-biroco"></a><a id="marshall-biroco"></a>
Marshall, S. J. [pen name Joel Biroco] (n.d.). *Yijing Dao*. biroco.com. https://www.biroco.com/yijing/
  S. J. Marshall's archive (author of *The Mandate of Heaven*, Columbia University Press, 2001) — host of the Moore papers, Schulz (1990), Waley (1933), and others. **NOTE:** Marshall (Joel Biroco) is a *different person* from Steve Moore (1949–2014), who is cited separately for the Moore 1989/2005 rules; the Cook-derivation review hosted at biroco.com/yijing/cook.htm is by J. Drasny. [swept 2026-07; attribution corrected 2026-07-19 — the entry previously misattributed the site to "Steve Moore." Legacy anchor `moore-biroco` retained for inbound links.]

<a id="meyer1998"></a>
Meyer, P. (1998). *The King Wen sequence and the first order of differences*. Web document (Serendipity
site; rev. 1998-01-04). **The web document itself is gone (checked 2026-08-01):** `www.serendipity.li/dna/kws.html`
returns 404 (the site root is still live, so the page was removed rather than the host disappearing), and the
Internet Archive holds **no snapshot of it at all** — zero captures from both the Wayback availability API and
a CDX query. An earlier "[Archived]" hyperlink here pointed at a Wayback URL that does not resolve; it has
been removed rather than left to imply a retrievable copy exists.

**Meyer's identifiable print contribution** is *The Mathematics of Timewave Zero*, published as an appendix
(pp. 211–220) in Terence McKenna & Dennis McKenna, *[The Invisible Landscape](#mckenna-mckenna1975)*,
**2nd (revised) edition, HarperSanFrancisco/HarperCollins, 1993** — print-published and permanently citable,
unlike the lost web document. That appendix is the timewave *construction*, not the first-order-of-difference
observations themselves.

**Attribution correction (2026-08-01).** An earlier version of this note (added 2026-08-01) cited two
properties — that the first order of difference "within pairs … is always found to be an even number", and
that there are "sixteen instances of an odd integer occurring out of a possible sixty-four" — as retrievable
evidence for *Meyer's* prior art. **That was wrong on attribution.** Both sentences occur on a page authored
by **Terence McKenna** (fractal-timewave.com, "Derivation of the Timewave from the King Wen Sequence"), and
this repository already credits the second one to **McKenna & McKenna (1975)** in three other places
(the entry above, [MCKENNA.md](MCKENNA.md), [SPECIFICATION.md](SPECIFICATION.md) §"wrap-around parity").
Using a McKenna sentence to establish Meyer's priority was circular, and it is withdrawn. The two properties
are credited to McKenna & McKenna, as they already were.

*What remains attributable to Meyer, honestly stated:* the lost 1998 web document, whose specific content
this project can no longer verify; and the 1993 timewave-mathematics appendix. **No ROAE novelty claim rests
on the Meyer entry** — the corresponding priority belongs to McKenna & McKenna 1975 and is credited there.
  Publishes the complete cyclic line-change sequence of the King Wen order (Hamming distances including
  the wraparound term) with an explicit XOR-and-popcount formalization — prior art for the transition
  multiset AS DATA (C5's axis) and for the cyclic reading's difference data. The absence of distance-5
  is visible in his published list but unremarked; the no-5 property as a stated claim remains McKenna &
  McKenna (1975). Found via the zhouyi.com bibliography review, 2026-07-04. [analyzed]

<a id="vandenberghe1999"></a>
Van den Berghe, D. (c. 1999–2002). *The explanation of King Wen's order of the 64 hexagrams*. Web
document (icrea site, Belgium; later fourpillars.net). [Archived](https://web.archive.org/web/2002/http://www.ping.be/icrea/explan.html); live PDF: https://fourpillars.net/pdf/kingwen.pdf (with a 2005 sequel, https://fourpillars.net/pdf/ic_landscape.pdf)
  States the pair structure as a two-rule system — inverse pairing, with complement pairing for the
  eight self-symmetric hexagrams — matching C1's modern formulation; also notes the four pairs where
  inverse equals complement and several special-pair placement observations, within an informal
  seasonal/landscape reconstruction. Modern web prior art for C1's formulation (classical priority
  remains Yu Fan, 3rd c.). Found via the zhouyi.com bibliography review, 2026-07-04. [analyzed]
  **Source and sole author of the nuclear orientation rule** (kingwen.pdf p. 11, Appendix 2): a
  nuclear-hexagram decision procedure predicting which member of each pair comes first, which he
  reported King Wen follows in 29 of the 30 pairs it addresses, with one declared exception (hexagram
  pair 3/4). Our measurement (TR-1 §7, 2026-07-05; scope corrected 2026-07-26) confirms his 29/30
  exactly and sharpens it: 29 is
  the maximum of the 1,720,320-vector **C4-oriented** orientation fiber of King Wen's pair sequence —
  the vectors keeping the classically attested (63, 0) opening — (12 vectors
  attain it; exact P(X ≥ 29) = 6.9754×10⁻⁶ one-sided, 1.3951×10⁻⁵ two-sided), where 30/30 is
  unattainable — **his declared exception is forced given the received opening orientation**, making
  the rule perfect up to impossibility rather than "almost perfect". On the pair-only-C4 fiber
  (2,703,360 vectors, both openings; re-checked 2026-07-26) exactly 2 vectors attain 30/30, both
  opening (0, 63) — the minimal one reverses precisely the opening pair and his own exception pair
  3/4 — so the exception traces to the classical opening, not to pair geometry alone
  (fiber-wide P(X ≥ 29) = 1.1097×10⁻⁵ one-sided). The rule was derived from King Wen, so this is exact
  population atypicality of his description, not independent confirmation; see TR-1 §7 for the full scoping.
  His broader reconstruction also audits cleanly: 17 of 19 checkable claim-groups verify exactly,
  and his two self-declared exceptions sit precisely where computation finds the misfits. The finding
  is his; the operationalization, exact enumeration, and population placement are ROAE's.

<a id="drasny-yiglobe"></a>
Drasny, J. (n.d.). *The Yi-globe*. i-ching.hu. https://www.i-ching.hu/ (unreachable as of 2026-07-04; [archived copy](https://web.archive.org/web/2024/https://www.i-ching.hu/))
  HTTP-only, partially blocked; core paper recovered via mirror. [partial]

<a id="schoter-yijingalgebra"></a>
Schöter, A. (n.d.). *Yijing algebra*. yijing.co.uk. https://www.yijing.co.uk/ (unreachable as of 2026-07-04; [archived copy](https://web.archive.org/web/2024/https://www.yijing.co.uk/))
  HTTP-only, partially blocked; 1998 paper via mirror; three later papers paywalled. [partial]

<a id="hacker-moore-zhouyi"></a>
Hacker, E. A., Moore, S., & Patsco, L. (n.d.). *Zhouyi.com* [Archived website]. Internet Archive.
  Blocked to our tooling; primarily a link aggregator. [not reached]

Wikipedia and OEIS entries used for reader orientation and the binary encoding are listed in
[README.md](../README.md) §References. [read]

---

*Revision 2026-07-04 (primary-evidence sweep): the d3 100T record count cited in this document was corrected 3,432,399,298 → 3,432,399,297 — a 2026-05-30 doc-pass "correction" divided the file size by 32 without subtracting the 32-byte header; the sha256 anchor `915abf30…` is unaffected. See [CANONICAL_HASHES.md](CANONICAL_HASHES.md) §d3 100T.*

*Revision 2026-07-22 (C3 scope-consistency sweep): the 3.9th-percentile figure's scope label was corrected from "C1-satisfying orderings" to **C1+C2+C4+C5** (every constraint except C3 itself — the measured solve.py differential population). The project's own C1-scope figures — C3|C1 = 6.42% (`solve.c --null-pair-constrained`) and the exact 8.106% at C1&C4 (`verify.py --check-null-g`) — rule out the C1-only label. The novelty claims themselves are unchanged; the value 776 and all counts are unchanged.*

*Revision 2026-08-01 (lens sweep — C3 percentile flag): the 3.9th-percentile complement-distance figure is **flagged and withdrawn from citation**. It is a statistic of the 13,296-ordering `solve.py` differential slice, whose stated range [11.75, 14.5] cannot be the range of C1+C2+C4+C5 — the strictly smaller C1–C5 canonical contains orderings at cd = 6.125 — and the suite's own ledger gives 1.3287×10³⁸ / 1.097051×10³⁹ ≈ **12%** at that scope. The 2026-07-22 scope correction above fixed the figure's *label*, not the figure. Authoritative statement of the flag, and the measurement that would settle it: [SOLVE.md](SOLVE.md) §Rule 3. No canonical count, sha, or theorem changed.*

*Revision 2026-07-05 (Mawangdui correction): the Mawangdui array was wrong from 2026-04-06 to 2026-07-05; novel-claim #8 is withdrawn and the §Mawangdui erratum added. Authority: Shaughnessy 2022, Table 11.2; discovery credit: the Shaughnessy-2022 literature-audit cross-check.*

*Revision 2026-07-30 (novelty-gate review, manifest M1): added the §"The (Z/2)⁶ hexagram algebra and hexagram-level group actions —
priority ceded" section with entries for Ouyang Weicheng (1990, 1992 — incl. his 1987 denial and its
1990 reversal), Zhang Qingyu (1994 tally / 1998 orbit / 2000 name), Suenaga (2012), and Luo Jianjin
(2015 — poser of the enumeration question this suite answers); added #kongyingda (the classical C1
formulation, previously uncited repo-wide), #curie1894 + #smidt2021 (closing the lean/ ceiling
hedge's dangling pointer), the #barrett2019 anchor, §C4/§C5 stubs + #xugua, and the prior-negatives
appendix to the uniqueness-conjecture note. **Corrected the 18:18 split's classical credit: Zhang
Xingcheng 张行成 + Zhu Xi 朱熹 (per the Li 2008 first-hand pass), replacing an unsupported Zheng Qiao
attribution (both occurrences); li2008 status refreshed to acquired/load-bearing.** No ROAE result
changed; all edits are attribution/citation hygiene.*

*Revision 2026-07-12 (Davis wave 2 + Drasny D-B1): davis2012 annotation extended with the wave-2
measurement outcomes (both null; TR-10 §3b) and the C-D5 power note; drasny2007 annotation extended
with the D-B1 Rule-of-Ten fitted-description classification (verified true, X = 22; data-like, no
p-value attached). No other entry touched.*

<a id="goldenberg1975"></a>
## Goldenberg, Daniel S. (1975)
"The Algebra of the I Ching and Its Philosophical Implications." *Journal of Chinese Philosophy* 2
(March 1975): 149–79. [doi:10.1163/15406253-00202003](https://doi.org/10.1163/15406253-00202003) The earliest algebraic formalization of the hexagram set known to this
project: line symbols as GF(2), hexagrams as the mod-2 ring (= GF(2)⁶), the inversion automorphism,
and the "mediating hexagram" (XOR difference) of any pair — set-level prior art for the vector-space
framing used throughout this repository, distinct from our ordering-level constraint results
([SYMMETRY_SEARCH.md](SYMMETRY_SEARCH.md) §Related work). Located via Hacker, Moore & Patsco (2002),
entry B:154; read in full 2026-07-11 — official interlibrary-loan scan in the private trove; all
repo-encoded claims (G-T1–T4, T7, incl. the KW5↔KW63-via-KW7 worked example, p. 170) verified against
the primary text.
[Schöter (1998)](#schoter1998) independently corroborates this lineage first-hand: he credits
Goldenberg's ⊕ (XOR) and ⊗ (AND) as the direct parallels of his own bit-wise operators, reports that the
bulk of his own work predated his awareness of Goldenberg, and notes his divinatory change operator
matches Goldenberg's Theorem 7 — Schöter's addition being the complement operation Goldenberg lacked.
The primary text also documents C1 explicitly: the King Wen mirror-pairing with complement fallback for
the eight symmetric hexagrams (p. 157) and their KW placement {1, 2, 27, 28, 29, 30, 61, 62} (pp. 165–66)
— the earliest explicit statement of C1 in the modern formal literature known to this project, predating
[Schulz & Cunningham (1990)](#schulz-cunningham1990) by fifteen years. Both are post-classical documenters
of a classical fact (the fandui/pangtong pairing, credited via [Nielsen (2003)](#nielsen2003)/Yu Fan);
Goldenberg documents, does not invent, and ROAE never claimed C1 as novel. His Lemma 3 / Table VI prefigure
[SPECIFICATION.md](SPECIFICATION.md)'s XOR-universality theorem at the set level. Caution when quoting his
Fu Hsi numerals: Fig. 2's numbering polarity is inverted relative to his own in-text yang=1 convention, and
the "60" on p. 166 is a misprint for 63.

<a id="nielsen2003"></a>
## Nielsen, Bent (2003)
*A Companion to Yi jing Numerology and Cosmology.* RoutledgeCurzon. [Open Library](https://openlibrary.org/works/OL4004550W) Encyclopedic reference for the
Han-through-Song numerological systems; used here as the authoritative source for classical-sequence
definitions. Three specific debts: (1) his Jing Fang eight-palace table (after Hui Dong) verified our
corpus-gate generator cell-for-cell (all 64), grounding TR-1 §7's Jing Fang control; (2) his <a id="wudeng"></a>Wu Deng
(1249–1333) entry — "Wu Deng" is Nielsen's own romanization (verified against his p. 132 JING GUA
entry and his biographical entry, 2026-07-26), retained repo-wide for fidelity to the cited source;
the scholar is 吳澄, author of the *Yi zuan yan* 易纂言, universally romanized **Wu Cheng** in other
scholarship (澄 has a rare secondary reading *dèng*) — records a "warp/weft" structural skeleton of
the received order — 16 hexagrams with
upper trigram equal to the lower or its complement, at pair-slots {1,6,15,16,21,26,29,32} — a
13th-century strict extension of what we credited to Van den Berghe as V-1; (3) his Lai Zhide (~1600)
entry shows the arrangement idea we credited as VdB-4 has a Ming-dynasty precedent. Where our reports
credit modern authors for structural observations, these classical precedents take priority; the
modern authors' contribution is independent rediscovery and, in VdB's case, quantification.

*Verification pointer:* the machine-checkable claims from both book audits — [Wu Deng](#wudeng)'s warp/weft
skeleton, [Lai Zhide](#laizhide)'s endpoint feeders, the Jing Fang eight-palace table, [Yu Fan](#yufan)'s fandui/pangtong
pair structure (all via Nielsen 2003), and Goldenberg's (1975) theorems T1–T4 + T7 — are
programmatically verified against the King Wen sequence by [`solve.py --books-verify`](SOLVE_C_CLI.md#--books-verify-solvepy-only)
(14 claims, one PASS/FAIL line each with expected + computed values; all 14 PASS as of 2026-07-05).

## Encyclopedic & reference links (Wikipedia, OEIS)

*Mirrored from the [README](../README.md) so this file is a single source of references. Reader
orientation only — not primary scholarly sources; the primary literature is cited in full above.*

- [King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence) — Wikipedia
- [King Wen of Zhou](https://en.wikipedia.org/wiki/King_Wen_of_Zhou) — Wikipedia (traditional attribution ~1000 BCE; modern scholarship divided on exact origin/dating)
- [OEIS A102241](https://oeis.org/A102241) — binary encoding of King Wen hexagrams
- [Bagua (eight trigrams)](https://en.wikipedia.org/wiki/Bagua) — Wikipedia (trigram names and associations)
- [Hexagram (I Ching)](https://en.wikipedia.org/wiki/Hexagram_(I_Ching)) — Wikipedia (hexagram structure, nuclear trigrams)
- [I Ching divination](https://en.wikipedia.org/wiki/I_Ching_divination) — Wikipedia (three-coin method, simulated by `roae.py --cast`)
- [Shao Yong](https://en.wikipedia.org/wiki/Shao_Yong) — Wikipedia (Fu Xi binary ordering)
- [Mawangdui Silk Texts](https://en.wikipedia.org/wiki/Mawangdui_Silk_Texts) — Wikipedia (background; the ordering array follows Shaughnessy 2022, tested by `solve.c --null-historical`)
- [Jing Fang](https://en.wikipedia.org/wiki/Jing_Fang) — Wikipedia (Eight Palaces ordering, also tested by `solve.c --null-historical`)
- [Terence McKenna: Novelty theory and Timewave Zero](https://en.wikipedia.org/wiki/Terence_McKenna#Novelty_theory_and_Timewave_Zero) — Wikipedia (see [MCKENNA.md](MCKENNA.md); full scholarly citation above)
