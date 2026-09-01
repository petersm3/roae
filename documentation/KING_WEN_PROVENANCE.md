# Where the King Wen sequence comes from — and what this project does *not* study

Written to be read by someone who has never opened an *I Ching*, while staying precise enough that a
specialist can check every claim. **Nothing here is a new finding** — it is the orientation a reader
needs before the technical reports make sense, and the single place this repository states where the
sequence comes from and which orderings it does not study.

*Added 2026-08-16. Previously this material was split across three places
([README](../README.md), [CRITIQUE](CRITIQUE.md), [CITATIONS](CITATIONS.md#shaughnessy2022)), each
carrying the same summary and each omitting the same two witnesses. Consolidated here so the record
lives in one place and cannot drift apart again; those three now link here.*

---

## 1. What the King Wen sequence is

The *Zhouyi* (*I Ching*) has 64 figures called **hexagrams**, each a stack of six lines that are
individually either solid or broken. Sixty-four is simply 2⁶ — every combination of six binary
choices.

Those 64 can be listed in any of 64! ≈ 1.27 × 10⁸⁹ orders. The one that has come down to us — the one
in essentially every printed edition and translation — is called the **King Wen sequence**. This
project studies the mathematical structure of *that particular order*: how tightly a handful of
structural rules constrain it, and how many other orders satisfy the same rules.

## 2. The honest answer about its age

**Traditionally** the ordering is attributed to **King Wen of Zhou, around 1000 BCE**.

**The earliest artifact securely attesting the received order is the Xiping Stone Classics
(熹平石經), carved 175–183 CE** — which survives in fragments, sufficient to establish the received
arrangement (Shaughnessy 2022, ch. 11). *(Corrected 2026-09-01: this previously described Xiping as
a physical object showing the received order in full. The monument as carved was whole; the object a
reader can inspect is not, and the cited source says fragments suffice to show the received
arrangement — it does not claim a whole object survives.)*

**That is a gap of roughly 1,200 years between the traditional attribution and the earliest secure
artifactual evidence.** A received-*like* witness narrows it earlier — Haihun Hou, mid-1st c. BCE
(§3) — to roughly 1,050 years, if its order proves identical to the received one, which we have not
verified. The traditional
ascription is not something archaeology has confirmed; the sequence's antiquity beyond the early Han
rests on inference. This is not a fringe view — it is the mainstream philological position, and it is
why this repository hedges whenever it refers to the sequence's age.

**None of this affects the mathematics.** We analyse the received order as an object. Whether it was
fixed in 1000 BCE or 200 CE changes the historical story, not the combinatorics.

## 3. The artifactual record

| witness | date | what it actually shows |
|---|---|---|
| **上博 Shanghai Museum Chu slips** | ~300 BCE | The **earliest known *Zhouyi* manuscript**. Only 34 of 64 hexagrams survive, on 58 bamboo strips that **arrived unbound and disordered** — looted and purchased on the Hong Kong antiquities market in 1994, so there is no excavation record and no find-state was ever observed; the ~300 BCE date is paleographic. The original hexagram order is **not recoverable**. Its modern editor arranged the slips by the received sequence and said so explicitly, precisely because the manuscript is incomplete. |
| **馬王堆 Mawangdui silk** | copied before 168 BCE | Complete, and a **genuinely different order**, generated exactly by a stated three-part rule: eight octets grouped by upper trigram in a fixed octet order, the lower trigrams cycling in a fixed order within each octet, with the octet's own trigram promoted to first (Shaughnessy 2022, Table 11.2 — see [CITATIONS](CITATIONS.md#shaughnessy2022)). |
| **阜陽 Fuyang** | tomb dated 165 BCE | Fragmentary; a **partial** witness consistent with the received order. |
| **海昏侯 Haihun Hou** | mid-1st c. BCE | Order **similar to** the received text, with hexagram numbering **identical** to the received numbering — including the 30/34 upper/lower split (Yang Jun 2017; Li Ling 2020). Exact order-identity is *not* something we have verified: our source says "similar to", and settling it requires Li Ling's 2020 transcription, which we do not hold. A hemerological text, not a *Zhouyi*. |
| **熹平石經 Xiping Stone Classics** | 175–183 CE | **Earliest secure artifactual witness of the received sequence** — surviving in fragments, which suffice to show the received arrangement. |

Sources: Shaughnessy, *The Origin and Early Development of the Zhou Changes* (Brill 2022), ch. 11,
for the dated witnesses; 馬承源 ed. / 濮茅左 释文考释, 《上海博物館藏戰國楚竹書（三）》 (上海古籍
2003) for the Chu manuscript.

**A note on the earliest item, because it is the one most likely to be raised.** It would be easy to
present a ~300 BCE manuscript as the earliest attestation of the King Wen order. **It is not.** The
strips are disordered, half the hexagrams are missing, and the published arrangement is the modern
editor's, taken from the received text. It attests the *existence* of the *Zhouyi* at that date, not
its *ordering*.

## 4. Other orderings — real, interesting, and out of scope

These exist. We are not studying them, and the reasons differ:

| ordering | what it is | why out of scope |
|---|---|---|
| **馬王堆** | Han silk manuscript order | **Generated exactly by a stated rule** — upper-trigram octets in a fixed order, lower trigrams cycling with the octet's own trigram promoted (Shaughnessy 2022, Table 11.2; encoded in `solve.py` as `M1`∧`M3`∧`M4`, whose joint reconstruction of the order is checked there). Upper-trigram grouping *alone* does not pick it out — `M1` is satisfied by the Fu Xi order too, and leaves 8!⁹ ≈ 2.8 × 10⁴¹ orders. The full rule reconstructs the order exactly, so it poses **no combinatorial puzzle of the King Wen kind**; *why* that scheme was adopted is a historical question outside our scope. *(We do use it: as a historical control in a null test.)* |
| **京房 eight palaces** 八宮 | Han systematic arrangement | Also rule-generated, and a divinatory scheme rather than a text order. |
| **邵雍 / "Fu Xi" binary order** 先天 | Song-dynasty | Straight binary counting order. Nothing to explain. |
| **王家台《歸藏》** | Qin-era excavated divination text | **A different text**, with different hexagram names — not a *Zhouyi* ordering at all. |
| **上博 Chu slips** | ~300 BCE | **Order not recoverable** (§3). Nothing to analyse. |
| **序卦傳 / 雜卦傳** | classical commentaries | Commentarial rationales and pairings *about* the received order, not competing orders. |

**The common thread:** an ordering produced by a simple, stated rule poses no combinatorial puzzle —
you can write the rule down and generate it. The King Wen sequence is interesting *because no such
rule is known for it*, despite two millennia of attempts. That is the question this project addresses.

**Out of scope is not a claim that they do not matter.** It is a statement about what we measured.

## 5. What we do and do not claim

**We claim:** the received King Wen order satisfies a specific set of structural constraints, and we
count how many of the 64! orders satisfy the same constraints. That count is a mathematical fact
about the constraint system, verifiable independently.

**We do not claim:** that King Wen wrote it, that it dates to 1000 BCE, that it is unique, that its
structure was intentional, or that our constraints are the ones its makers had in mind.

**On the pairing rule specifically** — that hexagrams run two-by-two, each paired with its own
reversal or, where a hexagram is reversal-symmetric, its complement — **this is classical and ancient,
not ours.** It is stated explicitly by 孔穎達 (574–648) and has an earlier lineage.

*What we can add is a measurement, not a claim of authorship.* That rule reproduces King Wen's
adjacent-pair structure **64/64**; every alternative tested scores 12–16/64 — **including one built
from a rival group the tradition itself supplies.** 焦循's 八卦相錯 (c. 1813) generates 20 orbits with
the *same* size profile as ⟨complement, reversal⟩ — 8 of size 2 and 12 of size 4, structurally
indistinguishable — and King Wen respects it only 24/64. Exactly, not sampled: of the 3.845×10⁴⁶
involutions on the 64 with eight fixed points, **exactly 70** reproduce King Wen's pairing, and all 70
are 孔穎達's rule up to a **vacuous relabelling** on the hexagrams where the two operations coincide.
**So the classical rule is not *a* symmetry that happens to fit; it is *the* rule** — and the rival it
beats was supplied by the same tradition, not constructed by us. Reproduce with
`python3 verify.py --check-classical-groups`. It is also
applied to the Chu manuscript's symbols by 濮茅左 (2003), and to a 36-unit quotient by 近藤浩之
(2005). **We claim no priority for the pairing insight.**

**Nor for combining the two operations — that is Yuan-dynasty, c. 1300.**
[吳澄 (1249–1333)](CITATIONS.md#wucheng), in 《易纂言外翼》卷一〈卦對第二〉, gives the **complete
decomposition of all 64**: 「卦畫奇偶正對，二篇共**二十對**…正對不反易者四…正對兼反易者四…反易取正對
者十二」 — twelve groups of four and eight of two, twenty in all, with his three classes matching the
three ways a hexagram can be fixed by one of the operations. 「反易取正對」 *is* the composition, and
he defines the operation at the **line** level (卦畫奇偶), explicitly distinguishing it from the
**trigram**-level one (上下二體).

Others reached parts of it independently: [崔述 (1740–1816)](CITATIONS.md#cuishu) covers 6 of the 20
orbits on sixteen hexagrams — creditably, since Wu Cheng's book was lost after the Ming and only
recovered in 1781; 焦循 (c. 1813) composes the operations (「反對旁通四卦交互」) for five ad-hoc
quadruples; 來知德 (c. 1600) tabulates both operations across all 64 but never composes them;
李尚信 (2002) names the relation 「互為錯綜卦」. **We claim no priority for any of this.**

**Nor for the orbit structure on hexagrams.** **朱元昇 (d. c. 1273) has it in full by 1270**, in
《三易備遺》卷八 — twelve quadruples written under both operations at once, plus the two degenerate
classes of eight, covering all 64. [吳澄](CITATIONS.md#wucheng) has it again c. 1310s and adds the
**count** (「二十對」) and the operational phrasing, which 朱元昇 does not give.
*(The 朱元昇 attribution was found on 2026-08-16, hours after the 吳澄 one, by a search designed for
the question. It is the second time in a single day that this cession moved earlier.)* In modern work,
張清宇 (1994/1998) published the complement/reversal orbit tally, and Radisic (2026) names
⟨complement, reversal⟩ as the Klein four-group and verifies results about it in Lean 4. Both are
cited throughout this repository.

What this project contributes is narrower still, and should be read narrowly: **counting the
ORDERINGS of the 64 that respect the orbits**, subject to a stated constraint system. Wu Cheng, Cui
Shu, 焦循, 來知德 and Kong Yingda all **classify** the 64; **none of those five counts arrangements of
it.** See [TR5](../reports/TR5_SYMMETRY.md) for the scoped statement.

**Two qualifications, added 2026-08-16, both of which narrow that claim.**

**First, "classify versus count" flatters us.** It is accurate for the five classical authors named
above and for no one else. **李尚信 (1999, 2002) does not classify** — he argues that the received
sequence is *arranged* on 錯綜 principles, with the orbits falling at regular intervals, and that the
spacing cannot be coincidence. He never counts orderings, so the counting claim survives him; but the
honest contrast is **"they argue the order is principled; we measure how constraining the principles
are,"** not "they classify and we count."

**Second, and more important: we had not finished looking.** Every prior-art sweep this project ran
before 2026-08-16 was aimed at the *symmetry* question or the *symbol* question, and two papers whose
titles sit directly on the ordering-count question — 王俊龍 on 「the mathematical regularity of the
order of the hexagrams in the received version」 and 管小思 on 「the structural mathematical model of
the hexagrams' sequence」 — were unread when this paragraph was first written.

**⚠ Updated 2026-08-28 and 2026-08-29.** A search designed for the ordering-count question was run
on 2026-08-16, and both named papers have since been read, along with every other obtainable paper
by either author; **the adjudication of those reads is now published** —
[CITATIONS.md](CITATIONS.md#acquisition-2026-08) carries annotated entries for the full 2026-08
acquisition round (2026-08-29). The sentence above still means exactly what it says — a claim about
the five named classical authors — and must not be widened into "no one counts orderings": the
published entries record closed-form counts of simply-constrained ordering spaces in the modern
literature ([Huang Shisheng 1997](CITATIONS.md#huangshisheng1997), after 沈宜甲/董光璧;
[Chen Zhuangwei 2007](CITATIONS.md#chenzhuangwei2007)). One item remains unobtainable: 王俊龍 2007,
in 劉大鈞 ed. 大易集釋, pp. 812–836; the remaining residues are flagged in that section's preamble.
(One of the two author names was misspelled here until 2026-08-28; see
[CORRECTIONS.md](CORRECTIONS.md).)

*A note on how this section was built, because it bears on how much to trust it.* Each cession above
was checked against the primary source, not against a summary. One paper (李尚信 2002) was
characterised three different ways in a single day — overstated, over-corrected, then read in the
original — and the version here is the one taken from the PDF. Where we have **not** read the source
first-hand, the citation says so.

## 6. Reproducing the structural claim in §5

That the sequence seats every hexagram beside its own partner is checkable in one command, with no
data files:

```
python3 verify.py --check-kw-pair-adjacency
```

It reports 32 pairs — 28 by reversal, 4 by complement — with zero unrelated pairs and zero hexagrams
whose partner is not adjacent.

The same command also records a **negative** result worth stating plainly: because King Wen's blocks
and its pairing orbits coincide *by construction*, symbol evidence from the Chu manuscript **cannot
distinguish** "the symbols respect reversal" from "the symbols are constant on contiguous blocks of
the received order." Tested on directly-observed symbols only, the editor's invariance claim holds 9
out of 9 — and that agreement is equally predicted by both explanations. **This is an impossibility
argument, not a criticism of his reading.**

---

*Corrections welcome. This is a statement about our sources and our reading of them, not a claim to
have settled a philological question.*
