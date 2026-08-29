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
- **Kong Yingda 孔穎達** (574–648). *Zhouyi zhengyi* 周易正義 (in the *Shisanjing zhushu* 十三經注疏, Zhonghua Shuju edition, 1980). **The classical formulation of C1**: his subcommentary on the [Xugua](#xugua) states the received order's pairing principle — the hexagrams run two-by-two, each pair related to its partner by reversal or, where the reversal is symmetric, by complement — the Tang-dynasty source every modern statement of the pairing rule descends from or independently rediscovers. The concept has still earlier attestation lineage (Yu Fan 虞翻, 164–233, whose pangtong/fandui pair relations transmit via Li Dingzuo's *Zhouyi jijie*; and, hedged, Western-Zhou-era material per Li Xueqin 2003), but Kong Yingda's is the explicit formulation.
  **Measured 2026-08-16, and it sharpens what the rule is worth.** His 非覆即變 — reversal, falling
  back to complement where a hexagram is reversal-symmetric — reproduces King Wen's adjacent-pair
  structure **64/64**. Every alternative pairing rule tested scores 12–16/64, including one built from
  a **structurally indistinguishable rival group that the tradition itself supplies**:
  [Jiao Xun](#jiaoxun)'s 八卦相錯 generates 20 orbits with the *same* size profile as ⟨complement,
  reversal⟩ (8 of size 2, 12 of size 4), and King Wen respects it only 24/64. Exactly, not by sampling:
  **70 of 3.845×10⁴⁶ involutions score 64/64, and all 70 are Kong Yingda's rule up to a vacuous
  relabelling** on the degenerate hexagrams. So the pairing rule is not *a* symmetry that happens to
  fit — it is **the** rule, against a rival the tradition supplied rather than one we constructed.
  Reproduce with `python3 verify.py --check-classical-groups`. Added 2026-07-30 (constraint-provenance audit; the repo previously carried no Kong Yingda citation anywhere). *Cited here at attribution level — the paraphrase above states the rule; the verbatim classical wording is held for a future classical-Chinese verification pass.*

**Status in ROAE:** ROAE independently encodes this rule as constraint C1 and uses it as the starting point of the enumeration. Not novel to ROAE.

### C2 — absence of 5-line transitions

The observation that consecutive hexagrams in the King Wen sequence **never differ by exactly five lines** is attributed to Terence McKenna.

- **McKenna, Terence and McKenna, Dennis** (1975). *The Invisible Landscape: Mind, Hallucinogens, and the I Ching*. Seabury Press, New York (**2nd, revised and updated edition: HarperSanFrancisco/HarperCollins, 1993, 229 pp. — this is the edition carrying Peter Meyer's appendix *The Mathematics of Timewave Zero*, pp. 211–220**; subsequent printing 1994, ISBN 0-06-250635-8 / 978-0062506351; [Open Library](https://openlibrary.org/isbn/9780062506351)). The "first-order of difference" analysis appears in **Part Two, Chapter 9 ("Order in the I Ching and Order in the World")**. McKenna explicitly states "a perfect ratio of three to one; three even integers to each odd integer" and gives the count as "fourteen threes and two ones constitute sixteen instances of an odd integer occurring out of a possible sixty-four" — confirming he was using the **circular reading** (64 transitions including the wrap-around s₆₃ → s₀, which has Hamming distance 3 in King Wen). Figure 17 (Table II, "Change in the King Wen Sequence") enumerates the full difference-wave histogram pair-by-pair. In the same chapter McKenna formalizes the sequence design under three rules: (1) absolutely exclude transitions of value 5 (= our **C2**); (2) minimize transitions of value 1 except where doing so would force a value 5 — empirically measured at the d3 560T canonical 2026-06-15 (`9a968fa2…`, 10,525,271,997 records: 80.03% of C1-C5 records violate it; KW is in the 19.97% minority that obeys it). **NOT promoted to a formal C-rule** — it would be reverse-engineered from KW's specific value-1 placements without first-principles or independent-corroboration support; see MCKENNA.md for the peer-review-defensibility analysis; (3) maintain a three-to-one ratio of even to odd transitions (= our **Theorem on wrap-around parity**, since 3:1 circular is a consequence of C4 + C5 + the XOR parity identity).
- *Status of earlier references:* The 1975 first edition (Seabury Press) contains the same I Ching analysis as the 1994 HarperCollins reprint; the work was reprinted, not revised. The underlying intuitions date to the McKennas' 1971 Amazonian expedition (see *True Hallucinations*, 1993, and Timewave-Zero biographical sources). No pre-1975 peer-reviewed paper or published lecture transcript on the I Ching analysis has been located via open web sources.
- Cook (2006) also presents the 5-line absence as part of the broader combinatorial analysis; independently derived within his framework.

**Status in ROAE:** ROAE encodes this as constraint C2 and independently verifies it across the canonical datasets. We do not claim originality for the observation itself; ROAE's contribution is the **exhaustive null-model testing** (see §Methodology below) which shows C2 is essentially unreachable in de Bruijn and random permutation families, and the **analytic decomposition** of why Latin-square row×col traversals satisfy C2 at 57.96% rate (believed novel; see [CRITIQUE.md](CRITIQUE.md)).

### C3 — complement distance minimization

The observation that King Wen positions complementary hexagrams (bitwise-opposites) unusually close to each other — formally, that the total positional distance $\sum_{v} |pos(v) - pos(\overline{v})| = 776$ is low (3.9th percentile, sampled — **figure flagged 2026-08-01**, see below and [SOLVE.md](SOLVE.md) §Rule 3) among orderings satisfying the other extracted constraints (C1+C2+C4+C5; scope label corrected 2026-07-22 — under the bare C1&C4 null the exact tail is 8.1%, `verify.py --check-null-g`) — is **not found in the prior published literature reviewed here**.

- Cook (2006) does not, to our first-hand reading of the monograph, present this specific property (the full scan set was read chapter by chapter; per-part notes are held privately).
- McKenna (1975) does not present it.
- No prior peer-reviewed citation is known to the author.
- <a id="barrett2019"></a>**Hilary Barrett (2019)** — the nearest prior art we have found is an informal blog post, "Complementary hexagrams and direction" (I Ching with Clarity, [onlineclarity.co.uk](https://www.onlineclarity.co.uk/answers/2019/04/05/complementary-hexagrams-and-direction/), 5 April 2019; archived [via the Wayback Machine](http://web.archive.org/web/20230312000515/https://www.onlineclarity.co.uk/answers/2019/04/05/complementary-hexagrams-and-direction/)). It observes, qualitatively, *where individual* complementary (bitwise-opposite) pairs sit relative to each other in the King Wen sequence — visualizing whether each pair "looks forward or back" for its complement — and explicitly names the largest gaps: "the greatest distance… is that between 3 and 50," the "second greatest" beginning at hexagram 5 (→ 35), and the "third-biggest" between 21 and 48. It is entirely informal ("counting complementary hexagrams instead of sheep") — no total sum, no percentile, no invariant, no bound — and does **not** anticipate the C3 total (776), its distribution, or the **C3 = 16 + 8·G** collapse (the latter a machine-checked repo theorem since 2026-07-04, `lean/C3Decomposition.lean`; see [TR-11 §10](../reports/TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md)). (Barrett's informal ranking is also not exhaustive — the actual second-largest gap is 4↔49 at distance 45, which the post skips — underscoring its eyeball character.) Credited as the nearest-in-spirit prior art on complement *distances*; not a prior statement of any quantified ROAE C3 result. Corrections welcome.

**Status in ROAE:** We believe C3 as a specifically-quantified constraint (776 as the KW value) is an original observation. *(**Amended 2026-08-01, lens sweep:** this claim previously read "776 as the KW value; 3.9th percentile — sampled — within orderings satisfying the other constraints, C1+C2+C4+C5". The 3.9th-percentile figure is flagged — it is not supported by the population it is labelled with, and the suite's own ledger gives ≈12% at that scope; see [SOLVE.md](SOLVE.md) §Rule 3. **The novelty claim does not depend on the figure** — it is about 776 being identified and quantified as a constraint at all — but the specific percentile must not travel with it.)* If prior work exists, please notify — we will credit appropriately.

**Scope qualifier (added 2026-04-20 after d3 100T enumeration; scope label corrected 2026-07-22):** KW's C3 is low (3.9th percentile, sampled — **flagged 2026-08-01, see [SOLVE.md](SOLVE.md) §Rule 3: not supported by that population; ledger ≈12%**) *within orderings satisfying the other constraints (C1+C2+C4+C5)* — not within C1-only orderings, where the measured tail is ~6-8% (C3|C1 = exact 6.4211367496% via `verify.py --check-null-g --unpinned` — the 10⁹-sample MC via `solve.c --null-pair-constrained` measured 6.42%, consistent; exact 8.106% at C1&C4 via `verify.py --check-null-g`) — but once the full C1–C5 canonical is enumerated, **KW sits at the C3 ceiling (776), not the floor**. Minimum C3 is 424 (221 records) at 100T and 392 at the deeper 560T canonical; about **1 in 10 (~10%)** of canonical orderings tie with KW at 776 — a fraction measured over the enumerated set, not a universal constant (9.91% over the 100T sample, 10.11% over the deeper 560T sample; both correct, converging near 10% — the full ~10³⁸ space was never fully enumerated). So within the conjoint C1–C5 frame, KW's C3 value is a *jointly satisfied upper bound* that many other orderings match, not a distinguishing minimum. The low-percentile framing of C3 applies specifically to the C1+C2+C4+C5 comparison population (every constraint except C3 itself) and should not be generalized — and it is a lowest-4% placement, not a minimization. See [SOLVE.md](SOLVE.md) §Rule 3 revision and [DISTRIBUTIONAL_ANALYSIS.md](DISTRIBUTIONAL_ANALYSIS.md).

### C4 — fixed start (Qian, Kun)

The placement of the two constant hexagrams (Qian 乾, Kun 坤) first is classically attested,
independently of any modern analysis:

<a id="xugua"></a>
- **Xugua zhuan** 序卦傳 ("Sequence of the Hexagrams"), one of the Ten Wings of the *Yi Zhuan*
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

The framing of C1–C5 as a specific *joint* constraint system is ROAE-specific. Individual constraints appear in prior work; the conjunction, the budgeted enumeration under the conjunction, and the 4-boundary / pair-stability analysis are ROAE-original.

*Corrected 2026-08-07 (CX-30).* This sentence previously read "…a specific system that **narrows 10^89 orderings to ~700 million**". That is wrong by roughly **29 orders of magnitude**, and in the direction that most flatters the project. 10^89 ≈ 64! is right for the unconstrained space, but C1–C5 does **not** narrow it to ~700 million: the C1–C5 space is **estimated at 1.33×10³⁸** orientation-explicit, ≈3.3×10³⁷ ⚠ **[WITHDRAWN 2026-08-24 — this figure exceeds its own 31! ≈ 8.2228×10³³ ceiling by ~4,013×; see documentation/CORRECTIONS.md]** after orientation-dedup ([TR-4](../reports/TR4_SIZE_OF_THE_SPACE.md); a Knuth random-probe estimate, not a proven cardinality). Figures in the hundreds of millions to low billions are **enumerated record counts from budgeted slices** — what the solver actually wrote to disk under a per-cell budget — not the size of the constrained space. The two are not comparable quantities, and conflating them inverts this project's central finding, which is that C1–C5 leaves a space far too large to enumerate. The "~700 million" figure itself appeared nowhere else in the corpus and had no supporting source.

### Fu Xi ordering, binary representation

<a id="leibniz1703"></a>
- **Leibniz, Gottfried Wilhelm** (1703). "Explication de l'arithmétique binaire, qui se sert des seuls caractères 0 et 1, avec des remarques sur son utilité, et sur ce qu'elle donne le sens des anciennes figures chinoises de Fohy." *Mémoires de l'Académie royale des Sciences*. Shows correspondence between Fu Xi's binary ordering and the natural binary count 0–63.
<a id="shaoyong"></a>
- **Shao Yong** (邵雍, 1011–1077 CE). *Huangji jingshi shu* (皇極經世書). Developed the circular/square binary arrangement (xiantian diagram) that Leibniz later rediscovered. A candidate (second-hand, unconfirmed) earlier statement of the 8+28=36 reversal-figure count in this work is recorded in §"Attributed candidate rules under population test (2026-07-02)" below — see the ⚠ CANDIDATE EARLIER CESSION entry; the attribution has not been moved.

### Mawangdui silk-text ordering

- **Shaughnessy, Edward L.** (1996). *I Ching: The Classic of Changes* (Mawangdui Texts). Ballantine Books. ISBN 978-0345362438. [Open Library](https://openlibrary.org/isbn/9780345362438) Translation and analysis of the 168 BCE Mawangdui silk manuscripts' alternative hexagram ordering.
- **Shaughnessy, Edward L.** (2022). *The Origin and Early Development of the Zhou Changes*. Leiden: Brill (Prognostication in History 9). Open access. **The authority for the Mawangdui ordering array used by ROAE** (p. 50 + Table 11.2: eight octets by upper trigram Qian, Gen, Kan, Zhen, Kun, Dui, Li, Xun; lower trigrams cycling Qian, Kun, Gen, Dui, Kan, Li, Zhen, Xun with the octet's own trigram promoted to first).

**Earliest attestation of the received sequence** (Shaughnessy 2022, ch. 11 — the same chapter Table 11.2 sits in). This is the concrete philology behind the repo-wide hedge that "the dating of the ordering's fixation is debated in modern scholarship": the earliest artifactual witness of the *received* hexagram sequence is the Xiping Stone Classics (175–183 CE), with the fragmentary Fuyang *Zhouyi* (tomb dated 165 BCE) an earlier partial witness. Mawangdui (copied before 168 BCE) attests a *different* ordering in circulation, so the received order's antiquity beyond the early Han rests on inference, not artifact.

**Expanded 2026-08-16 — two earlier witnesses were missing from this summary.** The paragraph above cited ch. 11 while omitting two of the witnesses that chapter discusses: the **Shanghai Museum Chu bamboo *Zhouyi*** (c. 300 BCE — the earliest known *Zhouyi* manuscript, ~135 years before Fuyang) and the **Haihun Hou 海昏侯 *Yijing*** (mid-1st c. BCE, a received-*like* order including the 30/34 split). Neither omission was a claim, but a reader checking the cited chapter would have found an unexplained gap. **Why the earliest one does not move the attestation date:** the Chu strips preserve only 34 of 64 hexagrams and came out of the ground **unbound and disordered**, and the published arrangement is the modern editor's own, taken from the received sequence *because* the manuscript is incomplete — [Pu Maozuo 2003](#pu2003), p. 135: 「又楚竹書《周易》尚不完整，本篇卦序排列也暫按今本」. It attests the *existence* of the *Zhouyi* at that date, not its *ordering*. **The full dated record now lives in [KING_WEN_PROVENANCE.md](KING_WEN_PROVENANCE.md)**, which also states which other orderings this project does not study and why; this entry, [the README](../README.md) and [CRITIQUE](CRITIQUE.md) all link there so the record cannot drift apart again.

**ERRATUM (2026-07-05).** From 2026-04-06 to 2026-07-05 the Mawangdui array in `roae.py`/`solve.c` was **wrong** — right octet membership, wrong octet order, wrong within-octet order (a synthesized double loop that matched neither the manuscript nor its own code comment; the cited Wikipedia article contains no sequence at all). The error was caught by cross-checking Shaughnessy 2022 Table 11.2 during a literature audit, and the corrected array was verified against multiple independent sources (Shaughnessy 2022; Cook 2006's full 64-position table; Shaughnessy 1996's generation rule via Rutt's review; S. J. Marshall's biroco.com conversion chart; independent web statements of the rule). Consequence: the former claim that Mawangdui satisfies C2 is **withdrawn** — the authentic Mawangdui order has **exactly one 5-line transition**, at the octet seam #48 Jing → #51 Zhen (positions 24→25), where its trigram-block construction resets. C2 is satisfied by King Wen and Jing Fang only (2 of 4 tested orderings), and the former "three of four / classical Chinese design principle" reframing of McKenna's observation is likewise **withdrawn**. All published Mawangdui-derived numbers were recomputed on the corrected array 2026-07-05; no other verdict flipped ([TR-1](../reports/TR1_EIGHT_CENTURIES_MEASURED.md)'s F5 corpus gate and [TR-10](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md)'s specificity gate both still pass — in both cases more cleanly). See also:

<a id="jingfang"></a>
- **Jing Fang** (京房, 77–37 BCE). The *Ba Gong Gua* (八宮卦) arrangement is preserved in traditional Yi Jing commentary and divinatory practice. The specific "origin → five worlds → wandering soul (遊魂) → returning soul (歸魂)" convention ROAE uses follows standard sinological sources. Alternative orderings within the same palaces exist; PR welcome for corrections. Traditional attribution of the arrangement to Jing Fang; historical certainty of the full ordering is debated in scholarly literature.

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
  among C1–C5-satisfying orderings" is true in ROAE's frame
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
- **Online discussions** (e.g., the [I Ching Community](https://www.onlineclarity.co.uk/friends/archive/index.php/t-10608.html) forum) have pointed out the correspondence, sometimes citing classical Chinese figures like **Yang Xiong** (揚雄, 53 BCE – 18 CE) as having anticipated de Bruijn-like structures in the *Taixuanjing* (*Canon of Supreme Mystery*), which uses ternary rather than binary.
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
<a id="shen1936"></a>
- **Shen Youding 沈有鼎** (1936a). "Zhouyi xugua gugou dayi" 周易序卦骨构大意 [Outline of the
  skeletal frame of the Zhouyi hexagram sequence]. *Beijing chenbao* 北京晨报, "Sibian" 思辨
  supplement no. 36, **6 May 1936**, p. 11. — (1936b). "Zhouyi guaxu fenxi" 周易卦序分析 [Analysis
  of the Zhouyi hexagram sequence]. *Zhexue pinglun* 哲学评论 **7(1), September 1936**. Both
  reprinted in 《沈有鼎文集》 (*Shen Youding wenji*), 人民出版社 1992, pp. 97–98 and p. 99
  respectively; ISBN 7-01-001170-2. Source notes and quotations below are read from that edition.
  **Dates and venues verified against the 1992 reprint 2026-08-15**, correcting an earlier working
  assumption in this project that Shen's sequence work was 1984; the 1984 item cited in the
  secondary literature must be a reprint or notice. Note for anyone repeating the search: 1936a is a
  **newspaper supplement**, which CNKI does not index, so a CNKI null on it is evidence about CNKI's
  coverage and not about the work.

  Shen partitions the 64 hexagrams into **16 主卦 (principal) and 48 散卦/从卦 (subordinate)** by
  whether inner and outer trigrams share generational rank 序 (老/长/中/少), the sixteen falling into
  **six groups** (乾坤; 泰否; 坎离; 既/未济; 震艮巽兑; 咸恒损益) and comprising the eight doubled
  trigrams 八卦自重 plus the eight whose six lines all correspond. In 1936b he frames the sequence as
  built on a **"Principle of Architectonic" (建构原则)** rather than a **"Principle of Continuity"
  (平等原则)** — his own English terms — with the sixteen 立其骨构 ("establishing the skeletal
  frame") and **three 序**: 回互 for the upper canon, **顺布 for the lower, and 交错 spanning both** (「回互之序用于上篇，顺布之序用于下篇。而交错之序通上下篇」, p. 98; p. 99 agrees). **Six patterns are named and none is defined** — the three 序 above, and the **三势** 抱, 插, 嵌
  (mentioned at p. 98 as 上下篇各有抱插嵌三势). Neither 1936a nor 1936b defines any of the six, and
  [Xing Wen 2021](#xingwen2021) does not either.

  **Scope, as far as these two papers go:** every quantity Shen states counts members of a defined
  **class of hexagrams**; we find no count or bound on **orderings**, no ceiling, no uniqueness
  claim, and no proof. Where the symmetry that later becomes Zhang's 错综 orbit does appear —
  逆顺错综，处处对称 — Shen writes 不详述 ("not elaborated"), 限于篇幅.

  **Do not read that brevity as undeveloped thinking.** In the *same year*, in
  评《东西乐制之研究》 (《清华学报》11(1), **1936年1月**, in the same collected volume at pp. 87–96),
  Shen defines his terms precisely (自然段落 / 优越段落 / 殊胜音差), tabulates them, corrects the
  reviewed author's arithmetic, and verifies to five decimal places — his 优越段落 2, 5, 12, 41, 53,
  306, 665 are exactly the continued-fraction convergent denominators of log₂(3/2), derived by hand.
  Four months later he named six patterns and defined none, in a **newspaper column**; 1936b runs to
  不足二百字. **The brevity tracks the medium.** This removes one explanation for the missing
  definitions — it does not supply them, and it licenses no reconstruction: a definition fitted to
  the King Wen sequence would be unfalsifiable however confident one is that Shen had something
  definite in mind. This reading is offered as a
  reading and **corrections are welcome**; it concerns only 1936a/1936b, and 《周易》释词 (same
  volume, pp. 176–186) is not covered by it.

  **Two attribution notes.** (i) **张清宇 (Zhang Qingyu) is a co-editor of the 1992 collected
  works** (with 刘培育 and 诸葛殷同; editors' preface signed 1991-05-16), so his crediting of Shen in
  [1998](#zhang1994) is first-hand rather than citation-chain — and his 1998 title
  《六十四卦方图和**周易卦序分析**》 incorporates the title of Shen 1936b verbatim. (ii) Shen
  himself credits a predecessor: 予初创此说，以为前人所未发，近读崔东璧遗书易卦次图说，乃与予说不谋而合 —
  having thought the account 前人所未发, he found that **崔述 (Cui Dongbi 崔东壁, 1740–1816)** had reached it
  independently. **Reference corrected 2026-08-15** against Xing Wen 2021, who works directly from
  Cui: the work is 《**易卦图说**》, of which 《易卦次图说》 is one of three constituent essays
  (alongside 《易卦画图说》 and 《易十二卦应十二月图说》); Xing cites it in 《崔东壁集》 (Shanghai:
  群学社, 1928), pp. 2–21, and reproduces its diagrams from the **1817 (嘉庆二十二年) woodblock
  edition cut by Cui's disciple 陈履和** **The correction concerns which EDITION Xing works from, and which work the essay sits inside —
  not where it lives.** Shen's own sentence, quoted above, says he read it 在崔东璧遗书, and that is
  not in dispute: Cui's writings were compiled by 陈履和 as 《崔东壁遗书》 (道光四年/1824). What this
  project had wrong was treating 《易卦次图说》 as a standalone work, when it is one of three essays
  *inside* 《易卦图说》 — and searching for the wrong title is why earlier digital searches returned
  nothing.
  Xing judges the convergence with Shen genuine (「这确实与沈先生的卦序论"不谋而合"」), and Cui
  claims the novelty himself: 纯卦人皆知之，而交卦则罕有言者。反对人多言之，而平对则罕有及者. Shen scopes the convergence himself:
  至散卦之排列，崔氏未详其故 — Cui does **not** account for the arrangement of the 48 subordinate
  hexagrams, which is where all of Shen's 三序/三势 material sits. We have **not** examined Cui's
  text; recorded as *per Shen's 1936 report*, not as a verified earlier root.

  **The 1936 pieces state nothing orbit-theoretic — though one of them turns out to be
  orbit-theoretic in extension.** Shen claims no group, no action, and no orbit; in that sense they
  attest the 16/48 skeleton decomposition and no more. But his six groups are not merely K₄-closed:
  computing over all 64 hexagrams, **they are exactly the six K₄ orbits of his sixteen** (sizes
  2,2,2,2,4,4), and this is forced — 错 is the identity on generational rank while flipping gender,
  综 is the identity on gender while permuting rank by the transposition (长 少) fixing 老 and 中, . 错 acts componentwise on (lower, upper); **综 SWAPS them** —
  (lower, upper) ↦ (rev(upper), rev(lower)) — so it is not a diagonal action, and an earlier revision
  of this entry describing it as one was wrong. The invariance holds regardless: both generators
  apply the *same* rank map to each component, and Shen's criterion asserts the two components' ranks
  are EQUAL — a condition preserved by a componentwise map and by a swap alike. **This is our observation, not his claim** — reproduce with
  `python3 verify.py --check-shen-orbits` (reads no files). Both halves belong in any account:
  the concept is absent from 1936, the extension is not. If Zhang's credit to Shen concerns the 错综不变组 idea, it must rest on later Shen
  material or on Zhang's first-hand knowledge as a commissioned editor — not on anything in 1936a/b.
  The two claims should be kept apart in any account of the lineage.

  **Do not conflate Shen's sixteen with Zhang's sixteen.** They are different objects that share a
  number: Shen's are sixteen individual hexagrams; Zhang's canonical 交综 count is a count of orbit
  classes. **Shen's sixteen** overlap the eight self-inverse hexagrams
  (乾坤颐大过坎离中孚小过) in only four (乾坤坎离), and the eight self-错综 hexagrams
  (泰否既济未济随蛊渐归妹) in only four (泰否既济未济). *(Corrected 2026-08-15: this previously made
  "Shen's eight doubled-trigram hexagrams" the subject of both clauses, which is false — their
  intersection with the self-错综 eight is EMPTY.)* Shen nowhere states or uses the K₄ coincidence noted above.

  *Edition orthography, if quoting the 1992 reprint verbatim:* it prints 即 for 既 throughout
  既济/未济, and 首干 for 首乾 on p. 99.
<a id="xingwen2021"></a>
- **Xing Wen 邢文** (2021). "Fenxing yixue chutan: zai tan Shen Youding xiansheng guaxu lun"
  分形易学初探——再谈沈有鼎先生卦序论 [A first exploration of the fractal studies of the Changes: a
  further discussion of Shen Youding's theory of the hexagram sequences]. *Zhouyi yanjiu* 周易研究
  2021(4): 31–36. Read in full 2026-08-15. Xing is Shen's principal expositor — he studied the two
  1936 papers in 1993 at Li Xueqin's request — so this is the closest thing to an authoritative
  modern reading of [Shen 1936](#shen1936).

  **It proposes "fractal Yi studies" as a way of *reading* Shen, and says so explicitly**: 因并无材料
  反映沈先生对分形的意见或了解 — "no material reflects Shen's opinion of or acquaintance with
  fractals." The three criteria offered (similarity/self-similarity of form; repetition/iteration in
  construction; unity of simplicity and complexity) are qualitative, and are loosened in the same
  breath — 不一定所有的分形都是典型的分形. A Hutchinson operator is written down but never
  instantiated: no maps, no contraction ratios, no attractor, no dimension, and the phrase is 视作
  ("if we view … as"). **All the claimed iteration is at the level of hexagram CONSTRUCTION
  (lines → trigrams → hexagrams), never at the level of the sequence.**

  **Load-bearing for scope:** Xing does **not** define 回互, 交错 or 顺布 — they appear once, as an
  undifferentiated list — and 抱, 插, 嵌 do not appear at all. He cites **no Shen material later than
  1936** (all quotations are footnoted to pp. 97–99 of the 1992 collected works). He counts and bounds
  nothing about orderings. So this paper neither collides with ROAE nor supplies the external
  formalisation that would make Shen's six named-but-undefined patterns testable — and, coming from
  the best-placed scholar writing 85 years later, it is meaningful evidence that no such definition
  exists.

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
<a id="jiaoxun"></a>
- **Jiao Xun 焦循** (1763–1820). *Yi tulüe* 《易圖略》 [Outline of Yi diagrams], 8 juan; in 《焦氏叢書》.
  Free: `https://ctext.org/wiki.pl?if=gb&chapter=953240`.
  A Qing mathematician's systematic *Yi* apparatus, and the source of one of the two **rival group
  actions** this project measures King Wen against. Three items bear on us:
  *(i)* **旁通 = complementation.** 《易圖略》卷一 旁通圖 tabulates all 32 complement pairs, credited by
  him to 虞翻.
  *(ii)* **He composes the two operations.** 卷六〈原序第三〉: 「**反對旁通四卦交互，如九數之維乘**」 —
  reversal and complementation, four hexagrams interlocking, "like the cross-multiplication of the
  nine numbers" — with worked quadruples 屯蒙鼎革, 豐旅節渙, 賁噬嗑困井, 蹇解睽家人, 小畜履謙豫,
  **all five verified as exact ⟨錯,綜⟩ orbits** — reproduce with
  `python3 verify.py --check-classical-groups` (`JIAOXUN_WORKED_QUADRUPLES_ARE_EXACT_ORBITS=5/5`). But he gives no general line-rule for 反對 (instances
  only), no enumeration and no orbit census: the quadruple is a hermeneutic bridge (比例), not a
  classification. **[Wu Cheng](#wucheng) does all of that, 500 years earlier.**
  *(iii)* **八卦相錯 is a DIFFERENT operation**, not complementation — 卷四 八卦相錯圖, a binary
  operation exchanging the lower trigrams of two hexagrams, from 說卦傳. He separates it from 虞翻's
  兩象易 explicitly: 「此與相錯似近，而非」. **The group ⟨complement, trigram-swap⟩ it generates is an
  exhaustive partition of the 64 into 20 orbits with the SAME size profile as ⟨錯,綜⟩ (8 of size 2,
  12 of size 4) — yet King Wen respects it only 24/64, against 64/64 for ⟨錯,綜⟩.** That measurement,
  reproducible with `python3 verify.py --check-classical-groups`, is why this entry matters: **the
  rival group is not ours, it is his**, and a structurally indistinguishable alternative from the same
  tradition does not fit the sequence.
  ⚠ **Not obtained:** 《易通釋》20卷, the fuller work 《易圖略》 abridges, where he may work the
  quadruples harder. Scans only, OCR unusable. *(Added 2026-08-16.)* [analyzed 2026-08-16]

<a id="laizhide"></a>
- **Lai Zhide 來知德** (1525–1604; the birth year is also given as 1526 in some sources — this repository uses 1525 throughout, following Schulz 1982). *Zhouyi jizhu* 《周易集註》, 卷首上/下. Free:
  `https://ctext.org/wiki.pl?if=gb&chapter=339923` (definitions) and `chapter=670057` (the tables).
  **The Ming source that fixed the modern vocabulary**: 「**錯者，隂陽橫相對也；綜者，隂陽上下相顛倒
  也**」 — 錯 is complementation, 綜 is reversal, both by explicit line rule. 卷首下 carries a
  **complete 64-row table** giving 錯 for every hexagram and 綜 for each of the 56 that has one. He is
  **more complete than [Cui Shu](#cuishu) on the degenerate cases**, naming all four orbits where
  complement coincides with reversal: 「否泰既濟未濟…歸妹漸隨蠱…此八卦**可錯可綜**」.
  **But he never composes the two.** His table contains no 錯綜 compound, and he presents the
  operations as **two side-by-side diagrams** (「伏羲圓圖相錯圖　文王序卦相綜圖…因此將二圖並列之」) —
  two attributes per hexagram, never a four-element set, never a size. **That is exactly the line
  between Lai Zhide and [Wu Cheng](#wucheng)**, and it is why the composition is ceded to the latter.
  Corroborated by a hostile contemporary: 黃宗羲《易學象數論》 objects that 來知德 「於頤、過八卦相反之
  外取反對者，而**亦復錯之**」 — an objection that is itself evidence the practice was conspicuous.
  Cited by [Li Shangxin 2002](#lishangxin2002) as his source for both definitions.
  *(Added 2026-08-16 — surfaced while testing whether [Cui Shu](#cuishu)'s claim that the joint use
  was rare could be sustained. It cannot.)* [analyzed 2026-08-16]

<a id="wucheng"></a>
- **Wu Cheng 吳澄** (1249–1333). *Yi zuanyan waiyi* 《易纂言外翼》, juan 1, 〈卦對第二〉
  [Hexagram pairing, chapter 2]. In the *Siku quanshu*; the work was lost after the Ming and
  reconstructed from the 《永樂大典》 in 1781. Free: `https://ctext.org/wiki.pl?if=gb&chapter=974228`
  and `https://zh.wikisource.org/wiki/易纂言外翼_(四庫全書本)/卷1`, which agree character-for-character.
  **⚠ SUPERSEDED AS "EARLIEST" ON 2026-08-16, THE SAME DAY IT WAS WRITTEN — SEE
  [朱元昇](#zhuyuansheng) BELOW.** This entry previously read "the earliest source we have found with
  the complete ⟨錯, 綜⟩ orbit decomposition of all 64." **朱元昇《三易備遺》卷八, complete by 1270
  (Southern Song), has the same decomposition roughly forty years earlier.** The hedge "we have
  found" was doing real work and it is why this correction is a narrowing rather than a retraction —
  but the sentence is now replaced.
  **What Wu Cheng retains is the COUNT and the operational phrasing**, which 朱元昇 does not give:
  Verbatim: 「**卦畫奇偶正對，二篇共二十對**…
  **正對不反易者四**…**正對兼反易者四**…**反易取正對者十二**…共四十八卦。」 That is **12 classes of
  four plus 8 classes of two = 20 classes covering all 64** — exactly the orbit structure of the
  four-group, with his three classes corresponding precisely to the three stabiliser types:
  正對不反易 = reversal acts trivially (乾坤·坎離·頤大過·中孚小過), 正對兼反易 = complement equals
  reversal (泰否·隨蠱·既濟未濟·漸歸妹), 反易取正對 = trivial stabiliser (the twelve quadruples).
  **Independently re-derived**, not taken from a summary: his 20 classes decoded to King Wen numbers
  and checked against orbits computed from this repository's own bit operations — zero mismatches,
  all 64 covered exactly once, and the class set is identical to the true orbit set. Reproduce the
  orbit arithmetic with `python3 verify.py --check-shen-orbits` for the sixteen-hexagram subset;
  the full-64 check is the same computation over all orbits.
  **It is the concept, not a coincidence of extension.** 「反易取正對」 is literally the composition of
  the two operations. He defines 正對 at the **line** level — 「卦畫**奇偶**正對」, 「此各卦**竒偶二畫**
  之對」 — and then explicitly contrasts it with the **trigram**-level operation, 「此各卦**上下二體**
  之對」, drawing the very distinction that separates a genuine line-operation grouping from a set that
  merely coincides. He also gives a **second, different** group in the same chapter — under
  ⟨reversal, trigram-swap⟩ he counts 「共**十八對**…純卦八…不與」, which is exact.
  Authenticated by his own 小序 via the 四庫 提要: 「二曰卦對，**以奇偶反易成二卦**」.
  **⭐ His degeneracy classes are not decorative — they exactly characterise a modern result.** Of the
  **3.845×10⁴⁶** involutions on the 64 hexagrams with eight fixed points, **exactly 70** reproduce
  King Wen's adjacent-pair structure, and **the hexagrams where that 70-fold freedom lives are
  precisely Wu Cheng's two degenerate classes** — his 正對不反易者四 (the 8 self-reverse) plus his
  正對兼反易者四 (the 8 where complement coincides with reversal). All 70 agree with reversal
  elsewhere, so they are **one rule under 70 labellings**: "fixed point" versus "swapped pair" is a
  vacuous distinction exactly where the two operations coincide — i.e. exactly on his sixteen.
  Reproduce with `python3 verify.py --check-classical-groups`.
  **What this leaves us.** The orbit decomposition itself is ceded to Wu Cheng. **Nothing in Wu Cheng
  — or in [Cui Shu](#cuishu), 焦循, 來知德 or [Kong Yingda](#kongyingda) — counts ORDERINGS.** They
  classify the 64; this project counts arrangements of them subject to constraints, which is a
  different object. **⚠ Scoped 2026-08-16: that is a statement about those five authors, NOT a survey
  result. ⚠ Updated 2026-08-28 — the two limits recorded here have since been addressed, and this
  paragraph is a state description, not a survey result. A prior-art search designed for the
  ordering-count question was run on 2026-08-16. The two papers named here as unread — 王俊龍 on the
  mathematical regularity of the received hexagram order, and 管小思 on a structural mathematical
  model of the hexagram sequence — have both been read, as has every other obtainable paper by
  either author; one item remains unobtainable (王俊龍 2007, in 劉大鈞 ed. 大易集釋, pp. 812–836).
  The adjudication of those reads is not yet published, so the claim above continues to be stated
  narrowly: it is a statement about those five authors, not a survey result. (This file carried a
  misspelling of 管小思's name until 2026-08-28; see
  [CORRECTIONS.md](CORRECTIONS.md).)** See [TR5](../reports/TR5_SYMMETRY.md) and
  [KING_WEN_PROVENANCE.md](KING_WEN_PROVENANCE.md).
  *(Added 2026-08-16. Recorded plainly: this repository already cited Wu Cheng — for 〈卦統第一〉, via
  Nielsen — and never opened 〈卦對第二〉, the next chapter of the same book. The miss originated at
  Nielsen's* Companion *pp. 57–58 and 199, where 反易卦 was filed under "other transforms".
  Corrections welcome.)* [read from two independent transcriptions 2026-08-16]

<a id="zhuyuansheng"></a>
- **Zhu Yuansheng 朱元昇** (d. c. 1273). 《三易備遺》卷八. Southern Song; 四庫提要 dates the work
  「**咸淳庚午〔1270〕備遺成帙**」, submitted to the throne by 家鉉翁 with a 進書狀 of 咸淳八年 (1272).
  Free on ctext and 維基文庫 (四庫本), which agree on the passage below.
  **⭐⭐⭐ THE EARLIEST SOURCE WE HAVE FOUND WITH THE COMPLETE ⟨錯, 綜⟩ ORBIT DECOMPOSITION OF ALL 64,
  and the deepest cession this project makes.** He first isolates the sixteen hexagrams where the
  先天 (complement) and 後天 (King Wen textual) pairings coincide, then asks
  「**餘四十八卦之對不同，何也？**」 — and answers with **twelve quadruples, each written under BOTH
  operations at once**: 「**先天屯對鼎、蒙對革；後天屯對蒙、鼎對革**…」 (×12, covering all 48), followed by
  the degeneracy split 「至於**乾坤頤大過中孚小過坎離八卦，不可得而反對**；**泰否隨蠱漸歸妹既濟未濟八卦，
  可得而反對，亦可得而變對**；總十六卦。」 **He names both operations distinctly — 反對 = reversal,
  變對 = complement.**
  **Independently validated, and reproducible: `python3 verify.py --check-zhu-yuansheng`.** His
  twelve groups are transcribed there as King Wen numbers with the 先天 and 後天 pairs kept
  SEPARATE, so each half of each line is tested on its own against this repository's own bit
  operations. All twelve quadruples were checked — every 先天對 is a true complement pair, every 後天對 a true reversal pair, the 48
  quadruple members are disjoint from the 16, and 12×4 + 8×2 = 64 exactly. Two separate
  transcriptions carry the passage, which together with the arithmetic makes transcription error
  effectively impossible.
  **Why this is a composition and not a table.** The test applied throughout this repository: *two
  attributes per hexagram is not a composition; one structure of four is.* Each line takes a
  complement pair and gives its reversal partners **on the same four elements**, so {屯 蒙 鼎 革} is a
  4-set closed under both operations, written as such. That is what separates this from
  [Lai Zhide](#laizhide), who tabulates both operations across all 64 and never composes them.
  **What is left to [Wu Cheng](#wucheng), c. 1310s:** the **count** (二十對; 反易取正對者十二) and the
  operational phrasing. 朱元昇 displays the twelve; he does not count them, give the 上下篇
  distribution, or state the composition as an operation. **Wu Cheng nowhere cites 朱元昇** — he was 21
  in 1270 — so his statement may be independent, but independence is not priority.
  *(Found 2026-08-16 by a prior-art sweep designed for this question — unlike the other cessions
  recorded here, which arrived incidentally. A disclosed gap remains: 張行成《易通變》卷三–四十 appears
  undigitised everywhere and is formally unchecked.)*

<a id="cuishu"></a>
- **Cui Shu 崔述** (1740–1816). "Yi gua ci tu shuo" 〈易卦次圖說〉, in *Yi gua tu shuo* 《易卦圖說》
  (one of three essays therein); in 《崔東壁先生遺書》 / 《崔東壁遺書》. Editions: 陳履和 東陽 printing,
  colophon 道光四年 = **1824** (composition ≤1816); 群學社《崔東壁集》 1928; 上海古籍 1983 (顧頡剛 編訂).
  **Read from the print 2026-08-16** — Kansai University 内藤文庫 IIIF scan, public domain, open, no
  login: `https://www.iiif.ku-orcas.kansai-u.ac.jp/books/202252574` (leaves at images
  `L21--1-589-14-0093`…`-0096`); ctext transcription `https://ctext.org/wiki.pl?if=gb&chapter=917813`
  agrees character-for-character on every load-bearing sentence.
  **⚠ SUPERSEDED as "earliest" the same day — see [Wu Cheng](#wucheng), c. 1300, who has the
  COMPLETE 20-orbit decomposition of all 64. Cui is an INDEPENDENT REDISCOVERER of a subset**, and
  creditably so: 《易纂言外翼》 was lost after the Ming and only reconstructed from the 永樂大典 in
  1781, so he almost certainly could not have read it.
  **He groups hexagrams by BOTH operations, defining each by an explicit line rule.** 「何謂平對？陰陽之爻互易者也。何謂反對？上下之爻互易者也。」 — 平對 = invert
  all six lines (= 錯 / 旁通), 反對 = turn the hexagram over (= 綜 / 覆). He then forms the
  four-element sets and **states their sizes**: 「震與巽平對而反對則艮也；兌與艮平對而反對則巽也。
  **兩體而四卦具焉，故四卦乃當乾坤之兩卦。**」 His diagram 「純卦交卦綱領之圖」 prints each hexagram's
  反對 **physically upside down** beneath it, annotating each row 「兩卦仍為兩卦」 or 「兩卦化為四卦」.
  He recovers all three stabiliser types correctly: 有平對無反對 (乾坤, 坎離), 平對即反對 (泰否,
  既濟未濟), and 有平對有反對 (震艮巽兌, 咸恆損益).
  **Scope, and it is the limit that matters:** he applies this only to his sixteen 主卦 — **6 of the
  20 orbits, 16 of 64.** He never carries 平對/反對 through the remaining 48 (「至散卦之排列，崔氏未詳
  其故」, Shen's words), and never notices that 頤/大過, 中孚/小過, 隨/蠱 and 漸/歸妹 are size-2 orbits
  inside his 散卦 — he files 漸歸妹 under 震艮. **The full 12 + 8 decomposition of all 64 is not in
  Cui.**
  **This project claims no priority for grouping by both operations** — that belongs to
  [Wu Cheng](#wucheng), c. 1300, with Cui an independent rediscoverer c. 1800. Reproduce the arithmetic — the six groups on the sixteen ARE the six K₄ orbits — with
  `python3 verify.py --check-shen-orbits` (reads no files); the same check covers both Cui and
  [Shen 1936](#shen1936), because **their sixteen and their six groups are identical**, which is why
  Shen wrote 「近讀崔東壁遺書易卦次圖說，乃與予說不謀而合」. Their *epistemic status* differs — see
  that entry.
  ⚠ Cui's remark that the joint use was uncommon in his day — 「反對人多言之，而**平對則罕有及者**」
  — **must NOT be quoted as evidence of novelty. It is false as a survey claim**: 虞翻 (c. 220),
  [Kong Yingda](#kongyingda) (648, 非覆即變, in the 十三經注疏), [Wu Cheng](#wucheng) (c. 1300) and
  Lai Zhide 來知德 (c. 1600, a complete 64-row table of 錯 and 綜) all precede him. It survives only
  as a remark about his own coinages 平對 / 交卦. His text names no predecessor at all — only
  「先儒」 — so it is best read as evidence he had not surveyed. He uses **neither** 錯/綜 nor 變/覆. *(Added 2026-08-16. A prior secondhand report that this text is "a generation/classification
  chart, not the King Wen ordering" was answering about ORDERING; the essay opens
  「上經何以三十卦也？下經何以三十四卦也？」 and the grouping by line operations is its core. Our earlier
  note giving an "1817 woodblock" is corrected to the 1824 colophon.)* [read from the print 2026-08-16]

<a id="pu2003"></a>
- **Ma Chengyuan 馬承源** (ed.), **Pu Maozuo 濮茅左** (transcription and commentary) (2003).
  *Shanghai bowuguan cang Zhanguo Chu zhushu (san)* 《上海博物館藏戰國楚竹書（三）》
  [Warring States Chu bamboo manuscripts in the Shanghai Museum, vol. 3]. Shanghai: Shanghai Guji
  Chubanshe. ISBN 7-5325-3637-8.
  Publishes the **earliest known *Zhouyi* manuscript** (c. 300 BCE): 58 bamboo slips covering 34 of
  the 64 hexagrams. Its distinctive feature is a set of red and black symbols at the head and tail
  of each hexagram unit — Pu's terms 首符 / 尾符, six forms, three simple and three nested. In
  附錄二 (pp. 251–260) he argues the symbol class is **invariant under 綜 (reversal)** and gives a
  24 + 4 + 4 partition of the 64 into reversal pairs, complement pairs, and pairs that are both.
  **Two cessions and one limit, all of which bear on ROAE.** *(i)* The pair partition is not new to
  him and is not ours: it is the classical 非覆即變 / 二二相偶 doctrine (see [Kong Yingda](#kongyingda)),
  which he cites. **We claim no priority for the pairing insight.** *(ii)* He treats reversal and
  complement as two separate classification *labels* on pairs — his "both" category records the
  coincidence R(x) = C(x) for four pairs, **not** the composition R∘C. There is no four-element
  group, no action on a single hexagram, and no orbit language in pp. 251–260; his framing is
  philosophical (對立統一), not algebraic. *(iii)* **The published slip order is editorial, not
  evidence** — p. 135: 「又楚竹書《周易》尚不完整，**本篇卦序排列也暫按今本**」 ("since the Chu bamboo
  *Zhouyi* is incomplete, this volume's hexagram arrangement also provisionally follows the received
  text"). The manuscript therefore supplies **no independent second ordering**.
  His invariance claim survives its first non-circular test — checked against only the symbols his
  per-slip 釋文考釋 reports as physically observed, excluding every entry 附錄二 reconstructs *from*
  the invariance: **9 testable pairs, 9 agreements, 0 disagreements**. That agreement is nonetheless
  **non-discriminating**, because King Wen seats every hexagram beside its own partner, so
  "respects reversal" and "constant on contiguous King Wen blocks" predict identically on every
  available observation. Reproduce with `python3 verify.py --check-kw-pair-adjacency` (reads no
  files). **This is a limit on what the evidence can show, not a criticism of his reading.**
  See [KING_WEN_PROVENANCE.md](KING_WEN_PROVENANCE.md). *(Added 2026-08-16 — volume obtained and
  read; the repo previously carried no citation to any excavated *Zhouyi* manuscript other than
  Mawangdui.)* [analyzed 2026-08-16]

<a id="kondo2005"></a>
- **Kondō Hiroyuki 近藤浩之** (2005). "Shanhai hakubutsukan zō Sengoku So chikusho *Shūeki* no
  «shufu» «bifu»" 上海博物館藏戰國楚竹書『周易』の「首符」「尾符」 [The "head symbols" and "tail
  symbols" of the Shanghai Museum Warring States Chu bamboo *Zhouyi*]. *Chūgoku tetsugaku* 中国哲学
  33 (Hokkaido University Chinese Philosophy Society): 1–20. ISSN 0287-1742. Chinese translation by
  Cao Feng 曹峰 in *Zhouyi yanjiu* 周易研究 2006(6); an open copy at jianbo.sdu.edu.cn carries two
  figures the journal printing omits.
  **The nearest published construction to ROAE's orbit framing, and the reason our negative is
  sourced rather than inferred from silence.** He collapses the 64 to **36 卦畫 by identifying 覆
  (= 綜, reversal) pairs**, then partitions those 36 into **nine 宮 of four**, deriving a 宮
  succession from the hexagrams whose head and tail symbols disagree. That is one step from an
  orbit quotient — but he **explicitly declines to take it**, leaving complement partners free to
  fall in different 宮: 「乾、坤等並不成對，分別屬於他宮之可能性也是存在的」. So the closest published
  work *of this kind* quotients by **綜 alone**, not by ⟨錯, 綜⟩.
  ⚠ **Do not read that as a general novelty claim.** A later sweep the same day found that the
  ⟨錯, 綜⟩ composite **is** constructed elsewhere in the Chinese literature — see
  [Li Shangxin 2002](#lishangxin2002), who names the joint object 「六十四卦錯綜圖」 and the
  four-element relation 「互為錯綜卦」. Kondō's significance is narrower and specific: he is the
  scholar who came closest to an orbit quotient **of the manuscript symbols** and consciously
  declined it.
  *(Added 2026-08-16. Corrections welcome: this is a statement about our literature search, not a
  novelty guarantee.)* [analyzed via the Chinese translation 2026-08-16; Japanese original not
  obtained]

<a id="lishangxin2000"></a>
- **Li Shangxin 李尚信** (2000). "Yinyang pingheng hubu yu biantong pei sishi" (陰陽平衡互補與變通配四時). *Zhouyi yanjiu* 周易研究 2000(3) 总45期: 51–60 **+ p.73**. Read in full 2026-08-20 (`FABLE_LI_SHANGXIN_2000_AUDIT_20260820.md`, roae-private — a private reading-audit note, not publicly accessible; the bibliographic facts stated here are checkable against the published article itself). Completes his 1999→2002 arc. ⚠ The 文章编号 suffix `-0051-10` counts only ten pages, so **p.73 — which carries the tail of the appended Q&A and the entire five-item reference list — is easily missed**. His arithmetic (the 当位 parity rule with exactly two exceptions, the A/B 28–20 yang mirror, the 13/25 tripartition) was independently recomputed and holds.
<a id="lishangxin2002"></a>
- **Li Shangxin 李尚信** (2002). "«Xugua» guaxu zhong de «canwu» «cuozong» sixiang"
  〈《序卦》卦序中的「參伍」「錯綜」思想〉 [The "canwu" and "cuozong" conceptions in the *Xugua*
  hexagram order]. *Zhouyi yanjiu* 周易研究 2002(6) [no. 56]: 46–49, 61.
  **Read in full from the original PDF, 2026-08-16.** An intermediate summary of this paper
  overstated it in one direction and a first correction overstated it in the other; what follows is
  from the source.
  He composes 錯 and 綜 **informally** and names the resulting relation 「**互為錯綜卦**」 — but the
  passage doing so is about the **eight trigrams**, explaining the 《易緯·乾坤鑿度》 「古文八卦」
  ordering: 「乾之錯為坤，坤之綜仍為坤，故乾坤互為錯綜卦；巽之錯為震，震之綜為艮，故巽艮互為錯綜卦。
  他卦倣此，坎離、震兌亦分別互為錯綜卦。」 At the hexagram level the composite appears once:
  「屯蒙變鼎革為錯，變革鼎則為錯而綜」. His operations are attributed by him to 來知德 and 孔穎達
  (「明來知德即把『錯』理解為孔氏所說的『變』…他還把『綜』理解為孔氏所說的『覆』」), and the
  「六十四卦錯綜圖」 he invokes is the **classical 36-figure woodcut he reproduces**, not a
  construction of his.
  He **is** conscious of the degenerate cases: 「泰否與隨蠱（泰否與隨蠱的錯卦皆為其本身，它們有相同的
  性質，故它們算一對）」, with 頤大過、坎離 excluded as 「皆為特殊卦，不算在內」 — but as ad-hoc
  exclusions inside a numerological scheme, not as an orbit-size classification.
  **What it does NOT do, verified by full read:** it forms **no orbit partition of the 64** (his
  錯綜卦 are a *selected subset* — five per canon, chosen because their spacings realise 3 and 5),
  uses **no group language** (no 群, no closure, identity or inverse), and **expressly declines to
  constrain the arrangement space**: 「關於錯綜卦的具體選取問題，即各個卦位究竟應排何卦的問題…此處
  暫不予討論。」 The paper's purpose is 象數 exegesis — reading 參伍 in the 《繫辭傳》 as 三才/五行,
  and the sequence as built to realise 3-spacings and 5-counts.
  **Consequence for scoping, stated carefully in both directions.** This project claims no priority
  for composing the two operations or for noticing 錯 = 綜 on the degenerate pairs — that is here,
  and in 來知德 before it. **But citing this paper as prior *orbit* work would overstate it**, and
  our ordering-level claim ([TR5](../reports/TR5_SYMMETRY.md)) is **not** narrowed by it, since he
  defers even which hexagram occupies which position. Hexagram-level orbit structure remains ceded
  to [Zhang Qingyu 1998](#zhang1994) and [Radisic 2026](#radisic2026).
  ⚠ *Two textual cautions for anyone quoting this article.* Journal page 61 is **shared**: its upper
  half (the 卦氣說 material and a reference list ending 責任編輯:劉玉建) belongs to a **different
  article**; Li's text resumes under 「(上接第49頁)」. And the typeset 綜 definition ends 「即為錯」
  where 「即為綜」 is plainly intended (屯→蒙 is a reversal) — an apparent printing error.
  Related items in the same programme. 〈今本《周易》六十四卦卦序的基本骨架〉 *Zhouyi yanjiu*
  1999(4) and 〈《序卦》卦序中的陰陽平衡互補與變通配四時思想〉 1999–2000(3) were **obtained and read
  2026-08-16** (both free from CNKI); *(status corrected 2026-08-19 — this line previously read
  "texts not yet obtained", which was true when written and is no longer)*. ⚠ **Those reads are
  single, unaudited passes and nothing is cited from them here.** PhD 《今、帛、竹書〈周易〉卦序研究》
  (Shandong Univ., 2007): existence confirmed, **not obtained**.
  *(Added 2026-08-16 — found by a targeted sweep of the excavated-manuscript symbol literature,
  which the 2026-07-30 prior-art review did not cover. That review was scoped to 卦序 mathematics;
  this paper sits in neither field cleanly and was missed by both.)* [analyzed 2026-08-16; free PDF
  from the Shandong University 易學 centre]

<a id="suenaga2012"></a>
- **Suenaga Takayasu 末永高康** (2012). "Kinbon *Shūeki* no kajo o megutte" 今本『周易』の卦序をめぐって
  [On the hexagram order of the received *Zhouyi*]. *Tōyō koten-gaku kenkyū* 東洋古典學研究 34: 1–18.
  Independent rediscovery of the (Z/2)⁶/XOR framing (yin=0/yang=1, six-bit vectors), the order-8
  subgroup of the 8 self-complementary hexagrams, and the coset organization of reversal-pairs — and
  **an independent arrival at counting the arrangement space** ⚠ **[FIRSTNESS CLAIM WITHDRAWN 2026-08-28 — this read "the first author we have located to start counting the arrangement space". This project's own Chen Zhuangwei adjudication ruled that FALSE AS WRITTEN on 2026-08-24; the sentence entered main on 2026-07-31 (`6a3feaaa`) and was never removed. Q-127 (DONE) and Q-263 (OPEN) both recorded it as no longer live because the checks read this section's preamble (:293) and never this entry body — so Q-263's question to the operator rests on a false premise. No firstness is asserted here; the cession chain is public. Found by the D2 novelty lens; see Q-358.]**: computes exactly
  1395 = [6 choose 3]₂ order-8 subgroups, and poses (but does not complete — halted, he reports, by
  his calculator's display) the product 1395 × 56 × 48 × 40 × 32 × 24 × 16 × 8 ≈ 1.47×10¹³ for
  eight-palace-style templates. He also reports finding **no rule that fixes the King Wen sequence**
  (an informal under-determination statement). His counted objects (F₂⁶ subspaces; algebraic
  templates) are disjoint from ROAE's constraint-satisfying total orders; he never completed or
  validated a count and connected no structure to the King Wen ordering. We have found no other hexagram-sequence
  work by him (his published field is *Liji* studies); on the evidence we have, the paper reads as
  the terminus of the Ouyang (1992) → Suenaga (2012) lineage rather than an isolated spike. [analyzed 2026-07; obtained via Hiroshima OA]
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

*(Added 2026-08-06 — citation audit: the Bayes-factor machinery (TR-2 / F11), the FDR
correction-family disclosure, the runs test, and the effect-size reporting were all in use
without named sources.)*

<a id="jeffreys1961"></a>
- **Jeffreys, Harold** (1961). *Theory of Probability* (3rd ed.). Oxford University Press. Appendix B's Bayes-factor evidence grades are the ancestor of the decision bands used in [TR-2](../reports/TR2_THE_RULES_CONFLICT.md) §"Pre-registration discipline" and the F11 framework ([reports/evidence/f11/](../reports/evidence/f11/RESULTS.md)). **Provenance caveat:** ROAE's frozen bands (BF > 10 "substantial", BF > 100 "strong") are a project convention loosely following Jeffreys, **not a quotation of his table** — Jeffreys' own "substantial" grade is ≈3.2–10, and the Kass–Raftery scale (below) places "strong" at 20–150. See the band-provenance note in TR-2 §"Pre-registration discipline".
<a id="kass-raftery1995"></a>
- **Kass, Robert E. and Raftery, Adrian E.** (1995). "Bayes Factors." *Journal of the American Statistical Association* 90(430): 773–795. [doi:10.1080/01621459.1995.10476572](https://doi.org/10.1080/01621459.1995.10476572) The standard modern reference for Bayes-factor interpretation scales, cited alongside Jeffreys in the band-provenance note; its "strong" band (20–150) also differs from ROAE's frozen convention.
<a id="benjamini-hochberg1995"></a>
- **Benjamini, Yoav and Hochberg, Yosef** (1995). "Controlling the False Discovery Rate: A Practical and Powerful Approach to Multiple Testing." *Journal of the Royal Statistical Society, Series B* 57(1): 289–300. [doi:10.1111/j.2517-6161.1995.tb02031.x](https://doi.org/10.1111/j.2517-6161.1995.tb02031.x) The FDR correction in the suite's correction-family disclosure ([METHODS.md](../reports/METHODS.md) §"Correction-family disclosure"; [TR-8](../reports/TR8_REORDERING_REVISITED.md), [TR-10](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md)) — the counterpart to the Bonferroni FWER family the suite applies throughout.
<a id="wald-wolfowitz1940"></a>
- **Wald, Abraham and Wolfowitz, Jacob** (1940). "On a Test Whether Two Samples are from the Same Population." *Annals of Mathematical Statistics* 11(2): 147–162. [doi:10.1214/aoms/1177731909](https://doi.org/10.1214/aoms/1177731909) The runs test applied to the difference wave in `roae.py` and reported in [CRITIQUE.md](CRITIQUE.md) §Summary.
<a id="cohen1988"></a>
- **Cohen, Jacob** (1988). *Statistical Power Analysis for the Behavioral Sciences* (2nd ed.). Lawrence Erlbaum Associates. Cohen's d effect sizes, reported alongside percentiles in `roae.py`'s entropy and complement-distance analyses ([CRITIQUE.md](CRITIQUE.md) §Summary).

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
<a id="demoura-ullrich2021"></a>
- **de Moura, Leonardo and Ullrich, Sebastian** (2021). "The Lean 4 Theorem Prover and Programming
  Language." In *Automated Deduction — CADE 28*, LNCS 12699: 625–635.
  [doi:10.1007/978-3-030-79876-5_37](https://doi.org/10.1007/978-3-030-79876-5_37) The Lean 4 proof
  assistant checking every machine-verified theorem in `lean/`
  ([lean/README.md](../lean/README.md); [METHODS.md](../reports/METHODS.md) §Environment). *(Added
  2026-08-06, citation audit — the proof assistant itself had gone uncited while the tools it
  checks were cited.)*

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
- <a id="zlib"></a>**zlib** (Jean-loup Gailly and Mark Adler) — [zlib.net](https://zlib.net/). DEFLATE compression library, load-bearing in `verify.c` (the v2 layer codec is per-block zlib; the build line links `-lz`) and in `solve.c`'s native-gzip live compression (`-lz` required since #169; sha-neutral storage layer, see [DEVELOPMENT.md](DEVELOPMENT.md)). *(Added 2026-08-06, citation audit.)*
- **GCC** (GNU Compiler Collection) with `-O3`. Specific version and build flags documented in [DEVELOPMENT.md](DEVELOPMENT.md).
- **Python 3.x standard library** (no third-party dependencies used in `solve.py`, `roae.py`, `verify.py`, `sat.py`). *(Corrected 2026-08-09: this list named a fourth file, `null_compare.py`, that has never existed in the repository — an original-authorship slip present since the 2026-04-19 creation commit and untouched by every later correction to this file. The null-model surface is solve.c's `--null-*` subcommands, documented in [SOLVE_C_CLI.md](SOLVE_C_CLI.md), not a Python file. The sentence's substantive claim — stdlib-only, no third-party dependencies — was and remains true of the files that do exist.)*

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
  36-unit consolidation + 18:18 reasoning to [**Lai Zhide (1525–1604)**](#laizhide);
  ⚠ **CANDIDATE EARLIER CESSION, recorded 2026-08-21, NOT yet applied.** [Shao Yong](#shaoyong) (邵雍, 1011–1077) appears to state the 8+28=36 reversal-figure **count** in 皇極經世 (pp. 335–337 as cited by 謝向榮 2005 pp. 18/20) — some five centuries before Lai Zhide. Evidence is currently **second-hand**: we have 謝's citation, not a first-hand reading of the 觀物外篇 locus. He states a count; he does **not** compose the sequence from it. **Do not move the attribution until the locus is read directly** — but do not let this lapse either: it is the earliest candidate we have found for the 36-unit count. Source: `FABLE_SONG_SWEEP_46_20260820.md` (roae-private — a private survey note, not publicly accessible; the second-hand chain it records, 謝向榮 2005 citing 皇極經世, is stated in full here and checkable against those published works). **Davis, Scott,**
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

## The 1979 reordering proposal — measured, and its construction refuted (with credit)

**McKenna, Stephen E. & Mair, Victor H.** "A Reordering of the Hexagrams of the I Ching," *Philosophy East
and West* 29:4 (October 1979), 421–441. (Distinct from McKenna & McKenna 1975.) They judged the received
order structurally indefensible beyond its local pairing and proposed a Gray-code-based replacement. Both
halves of that position are now formally addressed: population measurement finds discriminating structure
far beyond pairing (rules to ×11,364 rarity, measured under the ≤2-violations convention and robust to the source-stated exception form — see
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
  [TR-10](../reports/TR10_TEXTUAL_ARCHAEOLOGY_MEASURED.md): nine pre-registered composites — five
  null, one Bonferroni-notable (the #43–50 trigram array), three data-like; nothing
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
  generated by complement, reverse, and trigram swap (14 orbits; machine-verified against ROAE's tables 2026-07-10, zero
  errors — reproduce with `python3 verify.py --check-classical-groups`,
  `THREE_GENERATOR_ORBITS=14`). Contains no transition statistics or constraint analysis of the King Wen
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
  Gray-code replacement proposal; its structural-poverty premise is now measured, and its Gray-code construction refuted; first to
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
which the Li 2008 primary pass does not support*), Hu Yigui (b. 1247, *Yixue qimeng yizhuan*
易學啟蒙翼傳 — his "winged" supplement to Zhu Xi's *Yixue qimeng*), Lai Zhide (1525–1604, via Schulz, 1982), Kong Yingda (574–648, *Zhouyi zhengyi* — see the
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
(the entry above, [MCKENNA.md](MCKENNA.md), [SPECIFICATION.md](SPECIFICATION.md) §"Theorem (Wrap-around parity is odd)").
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
