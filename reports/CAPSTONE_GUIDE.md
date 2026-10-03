# The ROAE capstone guide: counting the King Wen sequence on a laptop

*A guided path through the ROAE project, for a reader with a laptop and no background in the I
Ching. Corrections to anything in it are recorded in
[CORRECTIONS.md](../documentation/CORRECTIONS.md).*

## In short

The King Wen sequence is the traditional order of the 64 symbols of the I Ching. We collected
seven rules that this order obeys and asked whether they allow any other order. They do: Section 6
shows a different order that passes all seven. Using four of the rules, two separately written
programs counted the possible orders exactly and got the same 40-digit number, about 1.1×10³⁹.
With all seven rules, the number is only estimated, at about 5.2×10³¹. Several rules were copied
from King Wen itself, so none of this says how or why the ancient order was made. On a laptop you
can rerun smaller versions of the count, check the first six of the full count's 31 stages, and
see that the checks can fail. The main exact count took about a week on a large server, and a
laptop cannot rerun it.

This guide is one of the project's three capstone pieces. The written report is
[TR-12, The Query Program](TR12_QUERY_PROGRAM.md), and its figures are shown and explained in
[viz/README.md](../viz/README.md). If you would rather start with no commands at all, read
[GUIDE.md](../documentation/GUIDE.md) first.

## Before you start

This guide walks you through one question about one ancient ordering of 64 symbols. Several
sections end with a command that checks the idea just explained. You will build two small C
programs, run a few Python checks, and compare what your machine prints with numbers we published.

*Why this section:* it tells you what to install, where the files come from and how to read a step,
so that nothing later surprises you.

There are **20 steps**, numbered in reading order. Every one runs from a clone of this repository,
and each has a command, its expected output and a one-core timing.

**How to read a step.** Each step has a box. Its first line is the step number in brackets, such
as `[4]`, followed by the command. Type or paste only the command, without the bracketed number.
The lines below it that begin `expect:` are not commands. They show text your run should print,
word for word, among its other output. Some printed lines go on past the text shown, with a file
name or a time; only the text shown has to match.

**What you need.** Linux on x86-64, `gcc` with OpenMP, the zlib headers (`zlib1g-dev` on Debian
and Ubuntu, `zlib-devel` on Fedora), Python 3.8 or later, and `git` to fetch the repository. No
step uses the network, and no third-party Python packages are needed. macOS is not supported,
because the build uses `-fopenmp` and the scripts use GNU tools. WSL2 on Windows may work; we have
not tested it. No measured step needs more than about half a gigabyte of memory.

**Where to get it.** Clone the repository with
`git clone https://github.com/petersm3/roae.git`, change into the new `roae` directory, and run
every step from there. The expected outputs below were checked on 2026-10-03 against the commit
that added this guide. The steps write a few files and directories into the top directory
(`solve`, `verify`, `out9`, `out13`, `kc13`, `log31.txt`, `table31.txt` and `planted.out`), and
deleting them leaves the clone as it was.

**How long it takes.** All 20 steps together take about a minute and a quarter on one core,
40 seconds of it in step 14. Steps 1, 3, 5, 13 and 15 to 20 were timed on a second, slower machine,
where step 14 took about 70 seconds of processor time, so those times are a guide to scale only.

**What you will and will not reproduce.** You will rebuild small versions of the main computation
and check them exactly, three different ways. You will also check the first six layers of the full
computation by enumerating every valid partial ordering with up to six free pairs after the fixed
opening pair, one at a time. You will **not** recompute the project's headline numbers. The full
count of orderings satisfying C1, C2, C4 and C5 took about a week on a 128-thread machine and
produced several terabytes of data. Each step below says which part of the work it checks.

**How numbers are labelled.** Every figure in this guide carries one of these words:

- **exact**: a result obtained by complete counting or exact arithmetic. Rounded displays of an
  exact value are marked with "about" or "≈".
- **estimated**: a statistical estimate (Knuth's random-probe method), with its 95% confidence
  interval.
- **withdrawn**: a figure we published and then took back. It appears only so you can recognise it.
- **proven**: a theorem, machine-checked in Lean 4.
- **measured**: a value observed in a run or calculated from a stated file: a time, a size, or a
  statistic of the catalog in Section 6.

The status labels follow the project's [METHODS](METHODS.md) page; the linked reports and
the command measurements give the source of each figure.

---

## 1. The object

*Why this section:* before asking why the order is what it is, you need to know what is being put
in order and how this project writes it down.

The I Ching is an ancient Chinese text built around 64 symbols called **hexagrams**. A hexagram is
a stack of six lines. Each line is either solid or broken. Two choices for each of six lines gives
2⁶ = 64 hexagrams, and the set contains every one of them exactly once.

Treat a solid line as 1 and a broken line as 0, read from the top line down, and each hexagram
becomes a six-bit number from 0 to 63. All solid lines is 111111, or 63. All broken lines is
000000, or 0. This project works with those numbers throughout. It ships no hexagram names, only
positions, bits and the two three-line halves (trigrams) each hexagram is built from. (The table
in step 1 has a column headed Name; what it holds is the two trigram names, Fire over Water, not a
title.)

Every received copy of the text puts the 64 hexagrams in one order. It is called the **King Wen
sequence**, after the ruler it is traditionally credited to (about 1000 BCE). The dating is debated.
The earliest secure physical evidence for the received order is in the surviving fragments of the
Xiping Stone Classics, carved in 175–183 CE;
[KING_WEN_PROVENANCE.md](../documentation/KING_WEN_PROVENANCE.md) explains the evidence. Here is the
order, read left to right:

> ䷀䷁ ䷂䷃ ䷄䷅ ䷆䷇ ䷈䷉ ䷊䷋ ䷌䷍ ䷎䷏ ䷐䷑ ䷒䷓ ䷔䷕ ䷖䷗ ䷘䷙ ䷚䷛ ䷜䷝ ䷞䷟ ䷠䷡ ䷢䷣ ䷤䷥ ䷦䷧ ䷨䷩ ䷪䷫ ䷬䷭ ䷮䷯ ䷰䷱ ䷲䷳ ䷴䷵ ䷶䷷ ䷸䷹ ䷺䷻ ䷼䷽ ䷾䷿

There are 64! ways to put 64 things in a row, about 1.27×10⁸⁹ (**exact** arithmetic). The received
order is one of them. Why this one?

Look closely and some structure jumps out. The hexagrams come in **pairs**, and the gaps above
group them that way. In 28 of the 32 pairs, the second hexagram is the first one turned upside
down. In the other 4 pairs, turning it upside down would change nothing, and the second hexagram
is the first with every line flipped instead. There are no exceptions (**exact**). People have also
noticed other regularities, such as how many lines change from one hexagram to the next, and for
centuries commentators have proposed rules that might explain the order. Some earlier works
describe patterns in the received order; others construct alternative orders and compare them.

This guide asks one question of the proposed rules: taken together, do they allow any ordering
other than King Wen? We study the order of the hexagrams only. These counts cannot establish the
text's meaning or the intentions of the people who arranged it.

**Step 1.** Print the sequence as a table, one hexagram per
row, with its position, its six bits and its two trigrams. *Why:* it connects the symbols above to
the six-bit numbers the rest of the guide uses.

```text
[1] python3 roae.py --table
    expect: 64  | ䷿   | 101010 | Li   Fire      | Kan  Water     | Fire over Water
```

That is the last of 64 rows. Time: under 0.5 s on one core, peak 33 MB (measured).

---

## 2. The rules

*Why this section:* everything later counts orderings that obey these rules, so you need to know
what each rule says and where it came from.

The project tests seven rules, called **C1 to C7**. Here they are in plain words. The formal
versions are in [SPECIFICATION.md](../documentation/SPECIFICATION.md). The **distance** between two
hexagrams is the number of lines that differ, from 0 to 6.

- **C1, pairs.** The 64 hexagrams sit as 32 consecutive pairs, each a hexagram and its upside-down
  partner (or its flipped partner, for the 8 hexagrams that look the same upside down). This is the
  classical pairing, described explicitly by Kong Yingda in the 7th century.
- **C2, no five-line jumps.** No two neighbours differ in exactly five lines. McKenna and McKenna
  published this in 1975, and Cook (2006) found it independently.
- **C3, complements stay close.** Every hexagram has a complement, with every line flipped. Measure
  how far apart each hexagram sits from its complement, and add this up over all 64. In King Wen the
  total is 776 (**exact**, read off King Wen), an average of 12.125 positions. C3 says the total
  may be at most 776.
- **C4, the opening.** The sequence starts with all-solid (63) followed by all-broken (0).
- **C5, the jump sizes.** Count how many of the 63 steps change 1, 2, 3, 4 or 6 lines. King Wen has
  2, 20, 13, 19 and 9 of them (**exact**, read off King Wen), and no step of 0 or 5. C5 says the
  counts must match exactly.
- **C6 and C7, two pins.** Number the 32 pair positions (slots) from 1, with the opening pair in
  slot 1. C7 requires King Wen's own pairs in slots 25 and 26, and C6 requires them in slots 27
  and 28. Which way each of those four pairs faces is left free.

C1 and C2 come from earlier literature, which states them as general properties of King Wen's
order; neither refers to a total or a position particular to King Wen. C4's opening pair is in the
classical commentary; the choice of which of the two comes first is our convention, and a Lean
theorem shows that C1, C2, C3 and C5 do not force it (**proven**). C3, C5, C6 and C7 were **read
off King Wen itself**: they use its own complement-distance total, its own jump counts and its own
pair neighbours.

A rule read off King Wen will always be satisfied by King Wen, so King Wen passing these rules is
no evidence that it was designed. What the rules can do is define a set of orderings, and then you
can ask how big that set is. That question is the subject of this guide. The METHODS section
"Data-like vs principled constraints" explains how we tell general rules from values fitted to
King Wen ([METHODS](METHODS.md)).

C3 alone is already strict. Among orderings that keep the 32 pairs (C1), about 1 in 16 also meets
C3: 6.4211367496%, computed exactly as a fraction and rounded here (**exact**).

**Step 2.** Build the counting engine. It is one C file. *Why:* every later step that starts with
`./solve` uses this program.

```text
[2] gcc -O2 -pthread -fopenmp -o solve solve.c -lm -lz && echo BUILD_SOLVE=OK
    expect: BUILD_SOLVE=OK
```

Time: 13.7 s on one core, peak 438 MB (measured). gcc 13 may print a few `-Wformat-truncation`
warnings while it builds. They are expected and do not affect the result.

**Step 3.** Check King Wen against the rules. *Why:* it confirms that the project's checker reports
C1 to C5 holding for King Wen itself, the starting point for every count below.

```text
[3] ./solve --check-arrangement KW
    expect: [check-arrangement] C3 complement distance:           HOLD (value 776, ceiling 776)
    expect: [check-arrangement] C5 distance multiset == KW's:     HOLD (hist d1..d6 = 2,20,13,19,0,9)
    expect: [check-arrangement] verdict C15  (C1-C5, C3<=776):   IN
```

Time: under 0.1 s on one core, peak 11 MB (measured).

The program prints one line per rule, C1 to C5, and every one says `HOLD`. For King Wen it reports
the C3 total and the jump-size counts listed above. Look at the C3 line: King Wen sits exactly at
the ceiling, because the ceiling is King Wen's own value. The checker covers C1 to C5 only; it
does not test C6 or C7.

---

## 3. The first real question

**How many orderings satisfy the same rules as King Wen?**

*Why this section:* the size of the set of orderings the rules allow is this guide's central
question, and here you count a small version of it with two different programs.

If the answer is 1, the rules pin down King Wen, and that would be a remarkable finding about the
rules. If the answer is large, these rules alone leave many possible orderings and cannot single
out King Wen. The count tells you how many candidates the rules leave. A claim that King Wen is
rare also has to say which population it compares against and how the orderings are weighted.

The full count is far too large to find by listing orderings, and Section 4 shows how it is done.
First, a version small enough to count in a second.

**Rungs.** Rule C4 fixes the first pair, which leaves **31 free pairs** to arrange. The
project's symmetry theorem (Section 4) sorts those 31 pairs into seven groups, of sizes 3, 3, 3, 4,
6, 6 and 6. Two pairs belong to the same group if one of the line-position shuffles described in
Section 4 carries one pair to the other. If you keep only some whole groups and throw the rest away,
you get a smaller problem with the same kind of rules, and keeping whole groups means those
shuffles still act on it. We call each such problem a **rung**, named by its number of free pairs.
This guide starts with the 9-pair rung.

A rung's orderings always begin with the fixed opening pair, so the 9-pair rung orders 10 pairs, or
20 hexagrams, and the 13-pair rung orders 14 pairs, or 28 hexagrams. A rung imposes C1, C2, C4 and
its own version of C5; it does not impose C3, C6 or C7. Turning a pair around gives a different
ordering, so each pair's direction is counted. Each rung has its own count, which cannot be used to
estimate the full problem's count.

A rung of 9 pairs cannot use King Wen's jump counts for its C5, so it uses a jump budget derived
from its own pairs by a fixed recipe: search the rung's pairs in a fixed order for the first
complete ordering that obeys C2, and take that ordering's between-pair jump counts as the budget.
This gives a reproducible test problem with at least one solution
([TR-11](TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md), "Reproducing the reduced-rung counts"). For
the 9-pair rung that budget, written B0, is (2,5,0,2,0): two between-pair steps of size 1, five of
size 2, none of size 3, two of size 4 and none of size 6. (Section 4 explains why the budget only
covers the steps *between* pairs.) Different rungs use different groups and do not sit inside
each other (the 9-pair and 13-pair rungs share one group of three), so agreement across rungs is
agreement across cases that overlap little. ([REPRODUCE.md](../documentation/REPRODUCE.md), "What `--f1-pairs n` means".)

**Step 4.** Count the 9-pair rung in Python. `verify.py` uses a plain counting method with no
symmetry tricks, and shares no code with the C engine. It counts layer by layer and compares each
layer with the published column. *Why:* it gives a count by a simple method that the next step
compares the engine against.

```text
[4] python3 verify.py --recount-rung-layers 9
    expect: layer  9: recount 26,112  published 26,112  [ok]
    expect: all 9 layer masses MATCH
```

Time: under 0.1 s on one core, peak 29 MB (measured).

**Step 5.** Count the same rung with the engine. *Why:* if two unrelated programs agree on a small
case, a mistake would have to give both of them the same wrong number.

```text
[5] SOLVE_F1_KEEP_LAYERS=1 ./solve --f1-exact-c1c2c4c5 --f1-pairs 9 --layers-dir out9
    expect: F1C5 SUBSET n=9 pairs [3,7,11,4,6,21,13,14,30] start_exit=0 B0=(2,5,0,2,0)
    expect:   orbit-quotient C5-DP total = 26112
```

Time: 0.3 s on one core, peak 16 MB (measured; 0.42 s on an 8-core machine, as published in
REPRODUCE.md).

Two programs that share no code agree. The 9-pair rung has exactly **26,112** orderings
(**exact**; the engine, the plain Python count and a C brute force all give it). The first line
also shows which 9 pairs the rung uses and its budget B0. The 26,112 belongs to this nine-pair
problem and its budget.

---

## 4. How you count about 10³⁹ things without listing them

*Why this section:* the headline count is far too big to list, and knowing how it was done tells
you what each later check actually tests.

The number this project computed exactly is the count of orderings that satisfy C1, C2, C4 and C5
together. It is a 40-digit integer, about 1.097×10³⁹ (Section 6 gives it in full). Even if you
merge orderings that differ only in which way their pairs face, at least 5.1×10²⁹ different orders
of pairs remain (**exact** arithmetic: each order of pairs accounts for at most 2³¹ orderings). The
largest list the project has written out holds 10,525,271,997 orders of pairs (**exact**); it was
made under a different rule set, C1 to C5, so the two figures do not measure how much of the space
that list covered. Listing is out of the question. We can count without listing every ordering by
combining partial orderings that have the same ways to finish. Three ideas make that work.

### Idea 1: think in pairs, and check C2 only where pairs meet

Because of C1, an ordering is really an arrangement of 32 pairs, where each pair can face either
way. C4 fixes the first pair and its direction. What is left is an order for the 31 free pairs, plus
one direction bit for each. That is 31! × 2³¹ ≈ 1.8×10⁴³ arrangements (**exact** arithmetic), and
every one of them satisfies C1 and C4 automatically.

Inside a pair, the distance is always 2, 4 or 6, never 5. (Turning a hexagram upside down always
changes an even number of lines, and flipping every line changes all six.) So C2 can only fail at
the 31 places where one pair ends and the next begins. You never need to check it anywhere else.

The same split helps with C5. Of King Wen's 63 steps, 32 are inside pairs, and those are fixed by
C1: twelve of size 2, twelve of size 4 and eight of size 6. Subtract them from King Wen's counts and
what remains is a budget for the 31 steps between pairs: (2, 8, 13, 7, 1) steps of size 1, 2, 3, 4
and 6. C5 becomes "use up this budget exactly".

### Idea 2: count states, not orderings

Build an ordering one pair at a time. The possible endings of a partial ordering depend on only
three things: which pairs you have used, which hexagram you ended on (the next step's distance
starts from it), and how much of the jump budget remains. Two different partial orderings that
agree on those three things have exactly the same set of possible endings.

So you never need to remember the partial orderings themselves. For each **state** (used pairs, last
hexagram, budget left), keep one number: how many partial orderings reach it. To extend by one
pair, each state passes its number on to every state it can step to, and the numbers add up. For
example, suppose three partial orderings reach one state and five reach another, and adding one
more pair takes both to the same next state. That next state receives 3 + 5 = 8. The engine stores
the number 8 once; it never stores the eight histories. This is dynamic programming, a standard
technique. Group the states by how many pairs they have used,
and you get 32 **layers**, from 0 pairs to all 31. The count in the last layer is the answer.

There is a catch. Ignore the budget for a moment, and there are still 31 × 2³¹ + 1 =
66,571,993,089 possible states (**exact** arithmetic). The numbers stored in them get very large,
past 2¹²⁸, and memory runs out first. Even holding only two layers at once, the plain method needs
between about 150 and 450 gigabytes, depending on how the numbers are stored
([TR-11](TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md) §1).

### Idea 3: use the symmetry, and get a free check

Some ways of shuffling the six line positions of every hexagram preserve everything rules C1 to C5
depend on. They keep distances the same, keep 0 and 63 in place, and send pairs to pairs. There are
48 such shuffles (**proven**, [TR-5](TR5_SYMMETRY.md)). Apply one to an ordering that
satisfies C1 to C5 and you get another one (**proven**). C6 and C7 pin particular pairs to
particular places, the shuffles move those pairs, and so C6 and C7 stay out of this argument.

One of the 48 is turning every hexagram upside down. It moves no pair: it swaps the two members of
each of the 28 upside-down pairs and leaves the other 4 alone. So if you look only at the order
the pairs come in, and forget their directions, the 48 shuffles act as a group of 24. At that
level the key fact is that the group acts **freely** (**proven**): no shuffle other than the
identity leaves a valid pair order unchanged. Valid pair orders therefore come in families of
exactly 24, and each has 23 twins that the rules cannot tell apart.

This guide counts oriented orderings, direction bits included. There the upside-down shuffle does
change the ordering, so the families have 48 members and the count must be divisible by 48. That
last step, from pair orders to oriented orderings, is argued in
[TR-11](TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md) §2 and is not itself machine-checked.
Divisibility by 24 is the weaker form of the same fact. The full-scale count checks in the
project's programs tested only that weaker form until 2026-10-02; since then they test divisibility
by 48.

1. **Less work.** States related by a shuffle have the same future, so the engine stores only one
   representative of each family of "used pairs" sets. At full scale that is 93,939,712 sets in
   place of 2³¹ = 2,147,483,648, a saving of about 22.9 times. It is a little under 24, because
   some partial sets are left unchanged by a few shuffles. The engine handles those with standard
   orbit-counting bookkeeping. Lean checks the mathematics of that bookkeeping, as a model
   (**proven**, [TR-11](TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md) §2); the C code that
   carries it out is not machine-checked. Steps 8 and 13 compare the engine with two other
   algorithms on the 13-pair rung, which is evidence for that case.
2. **A free check.** The final count must be divisible by 48, and so by 24. Nothing in the engine's
   arithmetic makes that happen on its own. In the full 31-pair run, the engine tests divisibility
   by 48 at the end and stops if it fails. (The run that produced the published total tested
   divisibility by 24, the test in place at the time.) That catches any error that leaves the total
   indivisible by 48; a wrong total that happens to be a multiple of 48 would pass. The smaller runs
   in this guide do not make that test, so at step 6 you do the division yourself.

### Running it

The rung with 13 pairs uses three of the seven groups (sizes 3, 4 and 6).

**Step 6.** Count the 13-pair rung with the engine. *Why:* on this larger rung the symmetry
shortcut does real work, so this is the case the next steps check against other methods.

```text
[6] SOLVE_F1_KEEP_LAYERS=1 ./solve --f1-exact-c1c2c4c5 --f1-pairs 13 --layers-dir out13
    expect: start_exit=0 B0=(1,6,0,6,0)
    expect: orbit-quotient C5-DP total = 2063395607040
```

Time: 0.6 s on one core, peak 12 MB (measured).

The 13-pair rung has exactly **2,063,395,607,040** orderings (**exact**). Divide by 48 and you get
42,987,408,480 with nothing left over, so by 24 as well. The same symmetry argument applies here,
because a rung is made of whole groups of pairs (Section 3), so the shuffles act on it too.

This is the same engine on a problem small enough to check exactly. The full count is about
5×10²⁶ times the 13-pair count. All 14 layer files you just wrote come to about 1.1 MB. The full
computation's layer files come to 3.29 TB (**measured**), and even the 19-pair rung's files are
only about 0.003% of that by size, the 21-pair rung's about 0.013%. Agreement on this rung checks
the method at 13 pairs; the 31-pair total needs its own full-scale computation.

**Step 7.** Check that your layer files are byte-for-byte the same as ours. *Why:* if they match,
your build and ours produced the same data, so the later comparisons are about the same files.

```text
[7] (cd out13 && find . -name '*.bin' | sort | xargs sha256sum | sha256sum)
    expect: 40387eed07b11319ba3943fca64ab94a7e19c6acfb56d2b42ce86e6ac0625c4e
```

Time: under 0.1 s on one core, peak 4 MB (measured).

The printed line ends with two spaces and a dash, which you can ignore. A matching digest confirms
that we produced the same files; step 8 recomputes the 13-pair count independently. If the digest
differs, check three things first: `SOLVE_F1_KEEP_LAYERS=1` was set, you hashed only `*.bin`
files, and you hashed from inside the directory with `| sort`
([REPRODUCE.md](../documentation/REPRODUCE.md), "Three mistakes").

**Step 8.** Count the 13-pair rung again in Python, with no symmetry, layer by layer. *Why:* it
recomputes the published 13-pair layer counts without the symmetry shortcut, so an error in the
shortcut would show up as a mismatch.

```text
[8] python3 verify.py --recount-rung-layers 13
    expect: layer 13: recount 2,063,395,607,040  published 2,063,395,607,040  [ok]
    expect: all 13 layer masses MATCH
```

Time: 3.3 s on one core, peak 94 MB (measured).

The plain method visits every state the engine merged by symmetry, and it gets the same number at
every layer.

**Step 9.** Check the symmetry bookkeeping at full scale. For each layer of the full 31-pair
problem, the engine's log records how many representative "used pairs" sets it stored, one per
family. That column depends only on the group, never on the counts. `verify.py` recomputes it with
Burnside's lemma, a standard way to count families under a group, and compares all 31 layers with
the published table. *Why:* it checks one ingredient of the full 31-pair computation at every
layer, in well under a second.

```text
[9] python3 verify.py --recount-orbit-widths 31
    expect: ORBIT_WIDTHS=GATED
```

Time: under 0.1 s on one core, peak 29 MB (measured).

`GATED` here means all 31 values matched. The column runs from 7 sets at layer 1 to 13,047,760 at
layers 15 and 16 (**exact**). So you have independently recomputed the published number of
symmetry classes of used-pair sets at every layer of the full problem.

You can also check one full-scale number by hand. Layer 1 of the full problem counts the ways to
place the first free pair after the opening. There are 62 hexagrams outside the opening pair, and
any of them can be the first hexagram of its pair, since a pair can face either way. The opening
ends on 0, so the step to the next hexagram changes as many lines as that hexagram has solid ones.
Six hexagrams have exactly five solid lines, and C2 forbids those. That leaves 62 − 6 = **56**, the
published layer 1 value (**exact**). Step 14 checks this and the next five layers by machine.

---

## 5. The knowledge compiler: a catalog you can query

*Why this section:* saving the counting work lets the project answer questions about individual
orderings, such as finding the ordering at a given position, without listing the orderings before
it.

Section 4 produced one number. Most interesting questions are about individual orderings. Is this
ordering valid? Where does King Wen fall among the others? What does a typical valid ordering look
like twenty pairs in?

You could answer those by searching, and run a new search for every question. The project instead
saves the counting work as a **catalog** that answers many questions without listing anything.
This is called knowledge compilation.

The catalog is built in up to three stages, each a stack of layer files.

- **f** (forward): for each state, how many ways there are to reach it from the start. This is what
  Section 4 computed.
- **g** (backward): for each state, how many ways there are to finish from it.
- **t** (tree): for each state, how big the search tree below it is, including the dead ends.

With these you can ask several kinds of question.

- **Count.** How many valid orderings are there? Read it off the last layer of f.
- **Rank and unrank.** Fix a standard order on all valid orderings. Then every ordering has a
  position number, its rank, and every position number names exactly one ordering. Going from an
  ordering to its number is ranking; going back is unranking. A rank is an address: rank 0
  identifies the first ordering under the chosen sorting convention.
- **Membership.** Is this particular ordering in the set?
- **Profile.** Step by step, how does one ordering's choices compare with all the others?

The catalog is built from C1, C2, C4 and C5. It has no record of C3, so it cannot count orderings
that must also meet C3 ([SPECIFICATION.md](../documentation/SPECIFICATION.md), C6). C6 and C7 are
different: they pin particular pairs to particular places, and a separate mode of `verify.c` can
impose those pins on the stored f and g layers ([VERIFY.md](../documentation/VERIFY.md),
`--c67-join`). At full scale, the f, g and t stacks measured 3.29 TB, 8.27 TB and 3.48 TB, about
15 TB together (**measured**). They are not distributed, and nothing in this guide reads them.
Every query you run below is against the 13-pair rung.

**Step 10.** Build the catalog for the 13-pair rung. *Why:* it creates the catalog that the next
step reads.

```text
[10] ./solve --kc-build kc13 --f1-pairs 13
    expect: KC BUILD n=13 dir=kc13 count=2063395607040
```

Time: 0.4 s on one core, peak 13 MB (measured).

**Step 11.** Ask it the simplest question, how many. *Why:* it shows that the saved catalog
answers a question by itself, from the files on disk, without rerunning the count.

```text
[11] ./solve --kc-count kc13
    expect: KC COUNT n=13 = 2063395607040
```

Time: under 0.1 s on one core, peak 12 MB (measured).

It gives the same **2,063,395,607,040** as step 6, now read back from a saved catalog. The catalog
directory is about 1.6 MB. The same program also offers `--kc-rank`, `--kc-unrank` and
`--kc-member` on this catalog; [SOLVE_C_CLI.md](../documentation/SOLVE_C_CLI.md) documents them, and
`documentation/QUERY_INVENTORY.md` lists every query the project defines.

---

## 6. What is known

*Why this section:* it lists what the project found, sorted by rule set: the counts that leave out
C3 are exact, and the two totals that include it are estimates.

For each count labelled **exact, two-instrument**, two different counting algorithms returned the
same integer, to the last digit. For the first two counts, those are the engine (`solve.c`) and
`verify.c`, which share no code. For the third, both algorithms live inside `verify.c` and share its
setup and arithmetic helpers. The project wrote all of these programs, and **no third party has
recomputed any of these numbers yet.**

### The exact counts

- Orderings satisfying C1, C2 and C4:
  757,058,601,340,255,440,651,419,713,405,330,315,358,208, about 7.5706×10⁴¹
  (**exact, two-instrument**).
- Orderings satisfying C1, C2, C4 and C5:
  1,097,051,278,789,181,790,036,112,071,176,579,186,688, about 1.097×10³⁹
  (**exact, two-instrument**). It is divisible by 48, and so by 24, as the symmetry argument of
  Section 4 requires.
- Orderings satisfying all seven rules except C3:
  516,880,238,445,773,965,371,923,491,676,160, about 5.169×10³²
  (**exact, two-instrument**).

The second number is the one Section 4 described. Rebuilding it with the engine's layer-by-layer
method needs about 64 GB of RAM and about 4 TB of disk
([TR-11](TR11_EXACT_COUNTING_BY_SYMMETRY_QUOTIENT.md)). The second instrument, `verify.c`'s
inclusion–exclusion mode, recomputed the same integer without any layer files. Both full-scale
computations are beyond this guide.

### The estimates, and why they are estimates

- Orderings satisfying C1 to C5: about **1.3287×10³⁸**, 95% CI [1.3283, 1.3292]×10³⁸
  (**estimated**).
- Orderings satisfying all seven rules, C1 to C7: about **5.21×10³¹**, 95% CI [5.13, 5.29]×10³¹
  (**estimated**).

Both come from Knuth's random-probe estimator, each run with 5×10¹⁰ random probes. Every exact
count above leaves out C3. C3 has exact results on its own terms (the 1-in-16 share in Section 2),
but the full-space counts that combine it with C1, C2, C4 and C5 are estimates, with or without C6
and C7. C3 depends on how far apart complementary hexagrams sit across the whole ordering, so to
count it exactly the program must carry extra information in every state, which makes the full
calculation much larger. A machine-checked identity rewrites C3 as a small whole number the counting method can
carry, so an exact method exists and is built. Running it at full scale was **declined**.

The estimator has been checked against exact answers where both exist. The exact 1.097×10³⁹ falls
inside the estimator's stated error envelope for the same quantity ([TR-4](TR4_SIZE_OF_THE_SPACE.md),
"Estimator calibration").

One figure is **withdrawn**: an earlier "about 3.3×10³⁷" for C1 to C5, counted with directions
merged. It was larger than its own ceiling, so it cannot be right. The 1.3287×10³⁸ above is a
different count and stands. The withdrawal, and every other correction this project has made, is
in [CORRECTIONS.md](../documentation/CORRECTIONS.md).

### The main finding

The seven rules do not pin down King Wen, and that much is **exact**, because a different ordering
that meets all seven can be written down. Count the pair slots from 1, with the opening pair in
slot 1. Take King Wen, swap the pairs in slots 2 and 3, and turn around the pair that now sits in
slot 3. Every other hexagram stays where it is, so the ordering begins 63, 0, 23, 58, 34, 17 and
then continues exactly as King Wen does. It passes C1 to C5, with the same C3 total of 776 and the
same jump counts, and because slots 25 to 28 are untouched it passes C6 and C7 as well
([BOUNDARY_MINIMUM.md](../documentation/BOUNDARY_MINIMUM.md), the 2026-09-19 correction under
"Implications for the analysis paper", which lists it as "swap 2↔3, flip 3"). It differs from
King Wen in the order of its pairs, not only in which way they face. You can test C1 to C5 for it
with the step 3 program by giving the 64 numbers, separated by commas, in place of `KW`.

How many orderings satisfy all seven rules is a separate question, and that answer is an estimate:
about 5.21×10³¹ (**estimated**; the lower end of its 95% interval is 5.13×10³¹). Steps 16 and 17
below add an exact count at small scale, with no estimator involved. All of this is a statement
about these seven rules; rules nobody has written down could still single out the received order.

### Checking the exact counts as far as a laptop can

**Step 12.** Build the second verifier. `verify.c` shares no code with `solve.c`. *Why:* steps 13
and 14 need a second program, written separately, to compare with the engine.

```text
[12] cc -O2 -o verify verify.c -lz -lpthread -lm && echo BUILD_VERIFY=OK
    expect: BUILD_VERIFY=OK
```

Time: 2.4 s on one core, peak 129 MB (measured).

**Step 13.** Recount the 13-pair rung with a different algorithm. This mode works by signed
inclusion–exclusion over sets of free pairs, and it never tracks which pairs are used. It is the
same program and mode that recomputed the 1.097×10³⁹ count at full scale. *Why:* agreement here
checks the 13-pair answer with a different counting formula, on a case small enough for a laptop.

```text
[13] ./verify --ie-count --ie-spec 3.0,4.0,6.2@0 --ie-expect 2063395607040 --ie-threads 4
    expect:           vs expected 2063395607040 : MATCH
    expect: IE_COMPARED=1
```

Time: 0.1 s on one core, peak 12 MB (measured; each pass took under 0.1 s with 4 threads on a
16-core machine).

The two algorithms agree on this 13-pair case.

**Step 14.** Count the first six layers of the full 31-pair problem one prefix at a time. No
states are merged and no symmetry is used. Each count is compared with the `mass` column in the
published log of the full run. *Why:* it is the only step that counts part of the full 31-pair
problem itself rather than a smaller version of it.

```text
[14] ./verify --brute-masses runs/20260716_f1c5_c1c2c4c5_d128westus3/run.out 6
    expect: BRUTE_MASSES_COMPARED=6
    expect: BRUTE_MASSES_MISMATCHED=0
    expect: BRUTE_MASSES_RESULT=PASS
```

Time: 40.1 s on one core, peak 4 MB (measured).

The six layers are 56; 3,030; 158,364; 7,975,320; 386,225,352; and 17,953,712,064 (**exact**),
each checked by plain enumeration. This guide does not recount layers 7 to 31; they rest on the
engine and on checks that read the multi-terabyte stacks. The final total was also recomputed
separately, by `verify.c`'s inclusion–exclusion mode, which reads no layer files.

**Step 15.** Check that the published table of all 31 layers is a faithful copy of the published
run log. The first `sed` takes the eight numbers of each `[f1c5] layer` line in the log and writes
them to `log31.txt`. The second takes the eight columns of each row of the table in Section 1 of
[FULL31_EXACT_AGGREGATES.md](FULL31_EXACT_AGGREGATES.md) and writes them to `table31.txt`.
`diff` then compares the two files. *Why:* it confirms that the full-run numbers this guide quotes
were copied faithfully from the run's own log.

```text
[15] sed -nE 's/^\[f1c5\] layer k= *([0-9]+)\/31: canonical_masks=([0-9]+) \(of C\(31,[0-9]+\)=([0-9]+)\) states=([0-9]+) entries=([0-9]+) V_k=([0-9]+) bytes=([0-9.]+)GB .* mass=([0-9]+) .*/\1 \2 \3 \4 \5 \6 \7 \8/p' runs/20260716_f1c5_c1c2c4c5_d128westus3/run.out > log31.txt; sed -n '/^## 1\./,/^## 2\./p' reports/FULL31_EXACT_AGGREGATES.md | grep -E '^\| [0-9]+ \|' | tr -d ',' | tr -s ' |' ' ' | sed 's/^ //;s/ $//' > table31.txt; wc -l < table31.txt; diff log31.txt table31.txt && echo LAYER_TABLE=MATCH
    expect: 31
    expect: LAYER_TABLE=MATCH
```

Time: under 0.1 s on one core, peak 4 MB (measured).

The `31` is the number of table rows read. `LAYER_TABLE=MATCH` prints only if the two files agree
in every column of every row; any difference is printed instead. Step 20 uses `log31.txt` again.
This step compares the published table with the published run log; the table's last row is the
headline count. Checking the calculation behind that total takes a separate full-scale recount,
which is what `verify.c` provided for the counts above.

### The exact check at small scale

This is a different kind of small calculation from the rungs. All 64 hexagrams stay in the
problem: King Wen's first 23 pairs are fixed and only the last nine are rearranged. Every
completion is therefore a full ordering, to which all seven rules apply.

Hold King Wen's first 23 pairs in place (the opening pair and the next 22), and leave the last 9
pairs free. Then count every completion exactly. The `PREFIX` line names King Wen's 22 pairs after
the opening, each with its direction bit. The `0` after `--estimate-knuth` means zero random
probes, so the program counts the subtree exactly instead of estimating it. These two steps need a
larger stack than most systems allow by default, which is why each starts with `ulimit -s
unlimited`. If your shell refuses that, use `ulimit -s 16384` (16 MB), the minimum they need.

**Step 16.** Count the completions that satisfy C1 to C5. *Why:* it gives an exact count, with no
estimator, on the real 64-hexagram problem.

```text
[16] ulimit -s unlimited; PREFIX="1 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 19 0 20 0 21 0 22 0"; ./solve --estimate-knuth 0 $PREFIX
    expect:   leaves_canonical_C1C5 : 16504
```

Time: under 1 s on one core, peak 12 MB (measured).

**Step 17.** Same subtree, now also requiring C6 and C7. *Why:* it shows how much the two pins cut
this subtree.

```text
[17] ulimit -s unlimited; PREFIX="1 0 2 0 3 0 4 0 5 0 6 0 7 0 8 0 9 0 10 0 11 0 12 0 13 0 14 0 15 0 16 0 17 0 18 0 19 0 20 0 21 0 22 0"; SOLVE_KNUTH_C67=1 ./solve --estimate-knuth 0 $PREFIX
    expect:   leaves_canonical_C1C5 : 8
```

Time: under 0.1 s on one core, peak 14 MB (measured).

The output label `leaves_canonical_C1C5` counts **oriented** completions, with each pair's
direction counted separately; the program prints a note saying so. Inside this one subtree,
**16,504** completions satisfy C1 to C5, and **8** of them also satisfy C6 and C7 (both **exact**).
All 8 put the last nine pairs in King Wen's own order. They differ only in which way some pairs
face.

Inside this subtree, the answer depends on whether pair directions count as distinct. As oriented
orderings, these 8 show, with no estimator, that the seven rules leave more than one ordering. As
orders of pairs, the 16,504 represent 899 different pair orders (**exact**, as stated in
[TR-4](TR4_SIZE_OF_THE_SPACE.md) §4; this guide has no command that prints it), and C6 and
C7 remove all but King Wen's. Outside this subtree, other orders of pairs do survive all seven
rules: the swapped ordering under "The main finding" is one, and it lies outside this subtree
because it changes slots 2 and 3.

### What the catalog showed at full scale

The repository includes an atlas, a 5,978,126-byte summary of the full f, g and t stacks
([TR-12](TR12_QUERY_PROGRAM.md) §12). The first six bullets below are statistics calculated
from it, each once, by one program, over orderings satisfying C1, C2, C4 and C5. The last bullet
compares atlas statistics with published C1-to-C5 results from a separate instrument. Several
bullets use **total variation**, the largest difference in probability that two distributions can
give the same event: 0 means identical, 1 means completely different.

How to read them: the probabilities give equal weight to every complete oriented ordering that
satisfies C1, C2, C4 and C5. A *layer* is how many free pairs have been placed so far, and a *slot*
is a pair position in the complete ordering, numbered from 1 with the opening pair in slot 1. The
atlas describes this population one layer or one slot at a time, so questions about whole
orderings, which depend on how the steps relate to each other, stay open.

- The jump budget (2, 8, 13, 7, 1) comes back exactly from the atlas's own column sums. The run was
  given that budget, so this checks the atlas's column totals.
- **68.67%** of the pruned search tree is dead ends: partial orderings that are valid so far but
  can never be completed (**measured**). The dead ends come late. None appear before layer 9, and
  they make up more than half of a layer only from layer 25. This figure is in the catalog's own
  units and says nothing direct about the running time of the project's other search programs.
- At each step, compare King Wen's transition with the other transitions of the same jump size at
  that layer, giving each transition a weight equal to the number of valid orderings that use it.
  King Wen's lower percentile at that step is the share of that total weight carried by transitions
  lighter than King Wen's own. It is below 0.25 at **24 of 31** steps, with a mean of 0.219 (**measured**). The 31 steps depend on each other
  and the atlas gives no distribution for their mean, so there is **no p-value**, and we have not
  established how unusual this pattern is.
- From one layer to the next, the distribution of single steps barely changes through the middle
  of the sequence: adjacent layers differ by at most 0.00099 in total variation over layers 6 to 23
  (**measured**). An ordering's score adds up the base-2 logarithms of the probabilities of its 31
  between-pair steps, each taken from that layer's distribution; one bit is a factor of two in
  probability. King Wen's score is 0.102 bits below the population average (**measured**). The atlas does not give the spread of whole-ordering
  scores, so it cannot say whether that gap is small or large.
- At each interior slot, 3 to 31, the distribution of which free pair sits there is within 0.0329
  total variation of uniform (**measured**). King Wen's own pair at its own slot has probability
  between 0.0299 and 0.0337 at every interior slot (**measured**), near the uniform 1/31 ≈ 0.0323.
  These are slot-by-slot comparisons; the joint pattern of placements has not been tested.
- At each layer, the distribution of the remaining jump budget is within 0.0415 total variation of
  what you get by shuffling the 31 jump sizes uniformly at random (**measured**). We have not
  tested whether this closeness is unusual.
- Two checks compare the atlas with numbers the project published from a different instrument, and
  both print `FAIL`, by about twelve times their tolerance. The populations differ by C3: the atlas
  has no C3, and the other instrument applied it. If both instruments are correct, C3 explains the
  gap; that explanation still needs a direct test.

**Step 18.** Recompute the atlas figures above, all but the
two `FAIL` comparisons, from the published atlas file. *Why:* it lets you recompute the full-scale
statistics above yourself instead of taking them from the text. Each figure prints as a `KEY=value` line you
can compare with the text, and `ATLAS_PROBE=PASS` means the atlas's tables are consistent with each
other and with the total count. The two `FAIL` comparisons come from a different command
([TR-12](TR12_QUERY_PROGRAM.md) §12.10).

```text
[18] python3 solve.py --atlas-probe runs/20260906_kc_ladders_n31/atlas_n31.json
    expect: ATLAS_PROBE=PASS
    expect: DOOMED_FRACTION_OF_T_ROOT=0.686725
```

Time: about 12 s on one core, peak 88 MB (measured). It reads a 6 MB file; one run on a 2-core
machine took about 7 seconds.

---

## 7. Prior art

*Why this section:* it shows which parts of this work were known before and what is new here.

The algebra and the counting question both have earlier sources.

**The algebra.** Treating the 64 hexagrams as six-bit vectors, with flipping and reversing as
operations on them, has been worked out independently many times. In the chain we have traced,
ROAE is the **seventh** independent arrival, after Goldenberg (1975, the first in a Western
language), Ouyang Weicheng (framework published in 1986; fullest account in 1992), Yuan Zuoxing
(1991), Cao Hongjun, Li Shuzhong and Liu Yanan (1995), Suenaga (2012) and Radisic (2026). Schöter
(1998) is a further arrival outside that chain: he reports that most of his work came before he
learned of Goldenberg. Neither Yuan nor Cao cites Ouyang, so their independence from him is
plausible but cannot be proven from the texts. Radisic proved in Lean that, among pairings built
from reversal or complementation, the classical pairing is the unique one with the smallest total
Hamming distance within pairs. All of these work on the set of 64 hexagrams. As far as we know,
none of them studies the space of valid *orderings* as a set to be counted or acted on by a group,
which is this project's object. ([CITATIONS.md](../documentation/CITATIONS.md), the "seventh
independent arrival" passage.)

**The counting question.** Asking how many orderings the hexagrams admit is not new either. Luo
Jianjin (2015) posed it in a mathematics journal, noting that the answer should be far smaller than
64!, without computing a count. Earlier still, Huang Shisheng (1997), reporting an argument by Shen
Yijia and Dong Guangbi, gave 1,625,702,400 = 8! × 8! (**exact** arithmetic) as the number of
arrangements when the orders of the upper and lower trigrams are left free. Counts of that kind
come from a closed formula. To our knowledge, the counts in Section 6 are the first computed
answers to Luo's question, for the particular rules used here.

**The finding.** That the rules do not fix the order was argued before this project counted.
Ouyang Weicheng (1990) held that the hexagrams have no intrinsic order, and that any order must be
imposed by added conditions. Zhang Qingyu (1998) conceded that his framework could not fix the
order of the 48 hexagrams it left over. Suenaga (2012) reported finding no rule that fixes the
sequence. For one stated set of seven rules, Section 6 adds an explicit second ordering that
satisfies all of them (**exact**) and a count:
about 5.21×10³¹ orderings satisfy all seven (**estimated**).

**The rules.** C1 is classical (Kong Yingda, 7th century, with roots in Yu Fan in the 3rd). C2 is
from McKenna and McKenna (1975), found independently by Cook (2006). C4's opening pair is in the
classical commentary. The project formalised C3, C5, C6 and C7 itself, from King Wen.

**The methods.** Every technique in this guide is standard: dynamic programming, Burnside's
orbit-counting lemma, inclusion–exclusion, Knuth's (1975) tree-size estimator, and knowledge
compilation. The repository provides commands and digests so you can compare a fresh run with the
published files. The new results here are the counts for these stated rule sets; the totals that
include C3 are still estimates.

Full references are in [CITATIONS.md](../documentation/CITATIONS.md). If you know of earlier work we
have missed, we want to hear about it.

---

## 8. Seeing a check fail

*Why this section:* a check that cannot fail tells you nothing, so here you plant a wrong value and
watch two of the checks above reject it.

Steps 14 and 15 compared published numbers with fresh counts and with the run log. Here you change
one published number by one, the layer 4 count 7,975,320, in a copy, and run each comparison again.
Neither step changes a file of the repository.

**Step 19.** Plant the wrong count in a copy of the run log, then repeat step 14's enumeration for
the first four layers against that copy. *Why:* it shows that step 14 rejects a log value that is
off by one.

```text
[19] sed 's/mass=7975320 /mass=7975321 /' runs/20260716_f1c5_c1c2c4c5_d128westus3/run.out > planted.out; ./verify --brute-masses planted.out 4
    expect: BRUTE_MASSES_MISMATCHED=1
    expect: BRUTE_MASSES_RESULT=FAIL
```

Time: under 0.1 s on one core, peak 4 MB (measured).

The table it prints marks the layer 4 row `*MISMATCH*`, and the command exits with status 1.

**Step 20.** Plant the same wrong count in a copy of the table, and compare it with the log extract
from step 15. *Why:* it shows that step 15's comparison catches a single changed digit in the
published table.

```text
[20] sed -n '/^## 1\./,/^## 2\./p' reports/FULL31_EXACT_AGGREGATES.md | sed 's/| 7,975,320 |$/| 7,975,321 |/' | grep -E '^\| [0-9]+ \|' | tr -d ',' | tr -s ' |' ' ' | sed 's/^ //;s/ $//' | diff log31.txt - || echo LAYER_TABLE=DIFFER
    expect: 4c4
    expect: > 4 2087 31465 16682 110732 50 0.003126 7975321
    expect: LAYER_TABLE=DIFFER
```

Time: under 0.1 s on one core, peak 4 MB (measured).

`diff` names the one row that differs and shows both versions of it.

Wall times and memory depend on your machine. The digests, counts and tokens should not. Please
report any difference in a digest, count or expected status message.

**What you have now checked.** If every step matched, you have counted the 9-pair rung two ways and
the 13-pair rung three ways, with separately written programs, matched the engine's published 13-pair layer files byte for
byte, recomputed the symmetry bookkeeping at every layer of the full problem, and counted the first
six layers of the full problem one partial ordering at a time. You have also checked that the
published table of the full run copies its log faithfully, counted every completion of King Wen's
first 23 pairs, recomputed the atlas statistics from the published summary, and seen two of the
checks reject a planted error. The headline totals come from separate
full-scale computations that this guide does not rerun.

---

## 9. What we do not know, and what would prove us wrong

*Why this section:* it tells you which conclusions further evidence could change, and what would
settle each open question.

**Open.**

- The exact counts for C1 to C5 and for C1 to C7. An exact method exists, and the full run was
  declined, so both stay **estimated**.
- Whether the search space could ever be fully listed. We cannot yet use the catalog to predict
  how long that would take: the catalog and the search program count different kinds of nodes, and
  there is no checked conversion between them yet.
- One proposed comparison, of King Wen's position under smaller symmetry groups, still needs a
  precise definition: which groups to use, and what to measure about King Wen.
- A direct test of whether C3 explains the two disagreements in Section 6.
- A calibrated test for the atlas patterns in Section 6: King Wen's low step percentiles, its
  0.102-bit score gap, and the closeness to a shuffled budget.
- Reproduction outside this project. The same author wrote the claims, the project code and the
  reports; the checks use several algorithms, two languages and externally written proof checkers.
  The Lean proofs and SAT certificates are in this repository and need at least 12 GB of free
  RAM to check. [TR-12](TR12_QUERY_PROGRAM.md) lists its open problems, and
  [CRITIQUE.md](../documentation/CRITIQUE.md) is the project's own case against its results.

**What would prove a result wrong.**

- Any step in this guide printing a different digest, integer or token on a correct build. Please
  report the command and its output.
- A second, independent computation of any **exact** count above that gives a different integer.
- An ordering of all 64 hexagrams that the project's checker says breaks a rule it actually meets,
  or the reverse.

**What would call an estimate into question.** An exact count of C1 to C5, or of C1 to C7, outside
the confidence interval given for it would show that this particular interval missed the true
value. A 95% interval can miss even when the method is working, so one miss would not on its own
show an error; a large gap would call for an audit of the estimator and its error calculation.
Testing how often such intervals cover the truth needs repeated independent runs.

If you want the checks without a full clone, the [reviewer package](../reviewer/README.md) bundles
thirteen of them, each with its expected output, into one file you can unpack and run.

---

*Written by Claude (Opus 5.5) for the project's author, 2026-10-01 to 2026-10-03, and reviewed in
draft by Claude (Fable 5) and by Codex (OpenAI). Developed with AI assistance (Claude, Anthropic).
Corrections are invited: please report any error, and any earlier work we have missed.*
