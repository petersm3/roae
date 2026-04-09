# McKenna and the King Wen Sequence

## What was Terence McKenna looking for?

[McKenna](https://en.wikipedia.org/wiki/Terence_McKenna) believed the [King Wen sequence](https://en.wikipedia.org/wiki/King_Wen_sequence) encoded a mathematical structure that described the ebb and flow of "novelty" — essentially, how much change or newness occurs over time. His theory ([Timewave Zero](https://en.wikipedia.org/wiki/Terence_McKenna#Novelty_theory_and_Timewave_Zero)) proposed that:

1. The first-order difference wave of the King Wen sequence wasn't arbitrary — it was a deliberately constructed signal.
2. That signal, when fractally expanded (folded onto itself at multiple scales and combined), produced a wave that mapped onto the rise and fall of novelty throughout human history.
3. The wave would reach a point of infinite novelty (zero point) at a specific date, which he ultimately pegged to [December 21, 2012](https://en.wikipedia.org/wiki/2012_phenomenon).

## What he was specifically looking for

- **Why no 5-line transitions?** This was his entry point. He saw the absence of 5 as evidence of intentional design, not coincidence. This program's Monte Carlo analysis (`--stats`) confirms it's unusual (~1 in 550) but not impossible.
- **The shape of the wave itself** — he treated the difference values (the wave this program computes with `--wave`) as raw data for his fractal transformation. The program shows the wave but does not implement his fractal expansion step (the Timewave Zero algorithm is outside the scope of this project).
- **Hidden periodicity** — he believed the wave contained self-similar structure at multiple scales. The program's `--autocorrelation` and `--fft` analyses address this directly: no significant periodicity is detected, though with only N=63 data points the statistical power to detect weak periodicity is limited.
- **Deliberate design** — he was convinced the sequence was engineered, not accumulated randomly over time. The program's `--constraints` analysis supports this: zero random permutations satisfy King Wen's combined properties (95% upper bound: less than 1 in 3,333). Whether "engineered" means what McKenna thought it means is a separate question.

## Where ROAE supports McKenna

The sequence is genuinely unusual and appears deliberately constructed under multiple constraints. The combined probability of satisfying both the perfect pair structure and the no-5-line property by chance is effectively zero in testing. Someone designed this sequence with intention.

## Where ROAE challenges McKenna

### Claims challenged by this program

1. **"The absence of 5 is extraordinary"** — McKenna treated the no-5-line-transition property as a smoking gun of deep intentional design. The Monte Carlo (`--stats`) shows it's ~1 in 550. Unusual, yes. Miraculous, no. It's roughly as likely as being dealt a specific two-pair hand in poker.

2. **"The wave contains hidden periodic structure"** — McKenna believed the difference wave had self-similar, fractal-like properties at multiple scales. The `--autocorrelation` shows no significant lags outside the 95% noise band (+/-0.25 for N=63), and the `--fft` shows no frequencies above the white noise floor. However, the sequence is short enough that weak periodicity cannot be ruled out — absence of evidence is not evidence of absence at this sample size.

3. **"The sequence encodes a sophisticated signal"** — The `--entropy` analysis places King Wen at the 13th percentile — more structured than random, but 1 in 8 random shuffles would be equally structured. The `--markov` permutation test shows King Wen's transition matrix is at the 43rd percentile — indistinguishable from random orderings. The apparent Markov patterns (e.g., "6 is always followed by 2") are based on sample sizes of 2-8 observations and are not statistically significant.

4. **"The ordering was optimized for smooth transitions"** — Compared against unconstrained random paths, King Wen is at the 97th percentile (3.35x a Gray code). But this is misleading: compared against the correct null model (random orderings that also satisfy the pair constraint), King Wen is at the ~29th percentile — completely typical. The pair constraint itself makes paths longer; King Wen is not unusually rough given its structure.

### Claims challenged by published researchers

5. **McKenna's wave construction was arbitrary** — Mathematician [Matthew Watkins](https://empslocal.ex.ac.uk/people/staff/mrwatkin/) showed that McKenna and his collaborator Royce Kelley made several unjustified choices when transforming the first-order difference into the Timewave: how the wave was "folded" onto itself, how many iterations of expansion were applied, and which mathematical operations combined the scales. Different (equally valid) choices produce completely different timewaves, meaning the output is not uniquely determined by the sequence. ([The Watkins Objection](https://www.fourmilab.ch/rpkp/autopsy.html))

6. **Errors in the original computation** — [Peter Meyer](https://www.fractal-timewave.com/), who programmed the original Timewave Zero software ([history](https://fractal-timewave.com/articles/hist.html)), and later Watkins independently confirmed that some of McKenna's hand calculations contained arithmetic errors that propagated into the published wave. When corrected, the wave shape changed.

7. **The 384-day period is assumed, not derived** — McKenna claimed the wave's base period was 384 days (6 lines x 64 hexagrams), which he connected to 13 lunar months ([derivation](https://www.fractal-timewave.com/articles/derivation_10.htm)). But this number is simply the count of lines in the sequence — it has no mathematical relationship to the wave's shape or properties. Any base period could be substituted.

8. **The end-date was moved** — McKenna originally calculated a different end-date, then shifted it to [December 21, 2012](https://en.wikipedia.org/wiki/2012_phenomenon) to coincide with the Maya calendar long count completion ([zero date analysis](https://www.fractal-timewave.com/articles/zerodate_10.html)). This was a post-hoc adjustment, not a prediction derived from the mathematics.

### Additional findings from ROAE

- **The wave's structure is local, not global** — `--windowed-entropy` shows entropy varies across the sequence, with some regions more structured than others. There is no uniform "signal" — the structure comes in patches. (Note: windowed entropy is exploratory visualization without a null model; apparent patterns may reflect random variation.)
- **Upper and lower trigrams change independently** — `--mutual-info` shows near-zero mutual information between upper and lower trigram transitions. Whatever rules govern the sequence, they don't couple the two halves of each hexagram. (Note: with all 64 combinations present exactly once, independence is expected by construction.)
- **Yin-yang balance is a tautology** — `--yinyang` confirms exactly 192 yang and 192 yin lines across all 64 hexagrams. This is a necessary consequence of containing all 64 possible hexagrams exactly once, not evidence of additional design. The local balance (where yang or yin clusters) is a property of the ordering.
- **The sequence is unique among historical orderings** — `--sequences` shows that neither the [Fu Xi](https://en.wikipedia.org/wiki/Shao_Yong) (binary) nor [Mawangdui](https://en.wikipedia.org/wiki/Mawangdui_Silk_Texts) ordering avoids 5-line transitions. This property is specific to King Wen.
- **Complements are deliberately close** — `--complements` shows King Wen places complementary hexagrams significantly closer together than random (0th percentile), suggesting intentional organization around opposition.
- **Palindromes are unremarkable** — `--palindromes` under pair-constrained null model shows King Wen at the 49th percentile for count and 14th for longest palindrome. No evidence of deliberate palindromic structure.
- **The canon split is not structural** — `--canons` permutation test shows the Upper/Lower Canon division does not correspond to a statistically significant boundary (~12th percentile for mean-difference gap).

## What holds up

- The pair structure is genuinely perfect and vanishingly unlikely by chance (`--constraints` shows 0/10,000 random permutations achieve it; 95% upper bound: less than 1 in 3,333).
- The no-5 property is real but largely explained by the pair structure: ~4% of pair-constrained orderings also avoid 5-line transitions (~1 in 23), compared to ~1 in 550 for unconstrained orderings. Within reverse/inverse pairs, 5-line transitions are mathematically impossible (distances are always even or 6).
- The complement distance is genuinely unusual — complements are placed significantly closer than random (0th percentile), suggesting deliberate organization around opposition.
- The XOR algebraic regularity (`--symmetry`) is a mathematical theorem — any reverse/inverse pairing of 6-bit values produces exactly 7 XOR products. It is not specific to King Wen.
- The constraint solver (`solve.py`) finds that 6 rules extracted from the sequence empirically lock **23 of 32 pair positions**. Only 2 specific adjacency choices in the last 9 pairs are needed to uniquely determine King Wen. See [SOLVE.md](SOLVE.md) for the complete generative recipe.
- The sequence was clearly designed with intentional mathematical structure by people in antiquity (traditionally attributed to [~1000 BCE](https://en.wikipedia.org/wiki/King_Wen_of_Zhou), though modern scholarship is divided on the exact origin and dating).

## What does not hold up

- The difference wave is not a "signal" in any meaningful sense — its Markov structure and path length are indistinguishable from random orderings that share the pair constraint.
- There is no detectable periodicity, though the data is too short to be conclusive.
- Several properties initially reported as findings (yin-yang balance, Markov patterns, trigram independence) are either tautological or statistically insignificant.
- Palindromes, canon split, recurrence rate, and neighborhood clustering are all within chance expectations under appropriate null models.

The King Wen sequence is genuinely remarkable as a combinatorial object — 6 rules lock 23 of 32 pair positions, and only two specific adjacency choices among thousands of valid arrangements cannot be explained by any discovered property. But McKenna's specific claims about what it *encodes* and what the wave *means* don't survive mathematical scrutiny.

## What ROAE cannot answer

The program cannot answer whether the wave "maps onto history" because that is an interpretive claim, not a mathematical one.

See [CRITIQUE.md](CRITIQUE.md) for known limitations of the program's methodology.
