# McKenna and the King Wen Sequence

## What was Terence McKenna looking for?

McKenna believed the King Wen sequence encoded a mathematical structure that described the ebb and flow of "novelty" — essentially, how much change or newness occurs over time. His theory (Timewave Zero) proposed that:

1. The first-order difference wave of the King Wen sequence wasn't arbitrary — it was a deliberately constructed signal.
2. That signal, when fractally expanded (folded onto itself at multiple scales and combined), produced a wave that mapped onto the rise and fall of novelty throughout human history.
3. The wave would reach a point of infinite novelty (zero point) at a specific date, which he ultimately pegged to December 21, 2012.

## What he was specifically looking for

- **Why no 5-line transitions?** This was his entry point. He saw the absence of 5 as evidence of intentional design, not coincidence. This program's Monte Carlo analysis (`--stats`) confirms it's unusual (~1 in 550) but not impossible.
- **The shape of the wave itself** — he treated the difference values (the wave this program computes with `--wave`) as raw data for his fractal transformation. The program shows the wave but stops short of his fractal expansion step (the Timewave Zero algorithm is excluded for copyright reasons relating to McKenna's estate).
- **Hidden periodicity** — he believed the wave contained self-similar structure at multiple scales. The program's `--autocorrelation` and `--fft` analyses address this directly: the autocorrelation shows no strong periodic signal, and the FFT shows no dominant frequency. This is evidence *against* the kind of built-in periodicity McKenna's theory required.
- **Deliberate design** — he was convinced the sequence was engineered, not accumulated randomly over time. The program's `--constraints` analysis actually supports this: zero random permutations satisfy King Wen's combined properties. Whether "engineered" means what McKenna thought it means is a separate question.

## Where ROAE supports McKenna

The sequence is genuinely unusual and appears deliberately constructed under multiple constraints. The combined probability of satisfying both the perfect pair structure and the no-5-line property by chance is effectively zero in testing. Someone designed this sequence with intention.

## Where ROAE challenges McKenna

### Claims challenged by this program

1. **"The absence of 5 is extraordinary"** — McKenna treated the no-5-line-transition property as a smoking gun of deep intentional design. The Monte Carlo (`--stats`) shows it's ~1 in 550. Unusual, yes. Miraculous, no. It's roughly as likely as being dealt a specific two-pair hand in poker.

2. **"The wave contains hidden periodic structure"** — McKenna believed the difference wave had self-similar, fractal-like properties at multiple scales. The `--autocorrelation` shows the correlation drops to near-zero after lag 1, and the `--fft` shows no dominant frequency. The wave is not periodic at any scale.

3. **"The sequence encodes a sophisticated signal"** — The `--entropy` analysis places King Wen at the 13th percentile — more structured than random, but 1 in 8 random shuffles would be equally structured. The `--markov` analysis shows some transition patterns (6 is always followed by 2, 1 is always followed by 6), but these are consequences of the pair structure, not an independent signal.

4. **"The ordering was optimized for smooth transitions"** — The `--path` analysis shows King Wen is *longer* than 97% of random paths and 3.35x rougher than a Gray code. Whatever the designers optimized for, it wasn't smoothness. This contradicts the idea that the wave was crafted to be a clean, intentional waveform.

### Claims challenged by published researchers

5. **McKenna's wave construction was arbitrary** — Mathematician Matthew Watkins showed that McKenna and his collaborator Royce Kelley made several unjustified choices when transforming the first-order difference into the Timewave: how the wave was "folded" onto itself, how many iterations of expansion were applied, and which mathematical operations combined the scales. Different (equally valid) choices produce completely different timewaves, meaning the output is not uniquely determined by the sequence.

6. **Errors in the original computation** — Peter Meyer, who programmed the original Timewave Zero software, and later Watkins independently confirmed that some of McKenna's hand calculations contained arithmetic errors that propagated into the published wave. When corrected, the wave shape changed.

7. **The 384-day period is assumed, not derived** — McKenna claimed the wave's base period was 384 days (6 lines x 64 hexagrams), which he connected to 13 lunar months. But this number is simply the count of lines in the sequence — it has no mathematical relationship to the wave's shape or properties. Any base period could be substituted.

8. **The end-date was moved** — McKenna originally calculated a different end-date, then shifted it to December 21, 2012 to coincide with the Maya calendar long count completion. This was a post-hoc adjustment, not a prediction derived from the mathematics.

### Additional findings from ROAE

- **The wave's structure is local, not global** — `--windowed-entropy` shows entropy varies across the sequence, with some regions more structured than others. There is no uniform "signal" — the structure comes in patches.
- **Upper and lower trigrams change independently** — `--mutual-info` shows near-zero mutual information between upper and lower trigram transitions. Whatever rules govern the sequence, they don't couple the two halves of each hexagram.
- **Perfect yin-yang balance** — `--yinyang` confirms exactly 192 yang and 192 yin lines across all 64 hexagrams. This is a necessary consequence of containing all 64 possible hexagrams exactly once, not evidence of additional design.
- **The sequence is unique among historical orderings** — `--sequences` shows that neither the Fu Xi (binary) nor Mawangdui ordering avoids 5-line transitions. This property is specific to King Wen.

## What holds up

- The pair structure is genuinely perfect and vanishingly unlikely by chance (`--constraints` shows 0/10,000 random permutations achieve it).
- The combined constraints (pairs + no-5) are extraordinary together.
- The XOR algebraic regularity (`--symmetry`) is real and not well-explained.
- The sequence was clearly designed with intentional mathematical structure by people ~3,000 years ago.

The King Wen sequence is genuinely remarkable as a combinatorial object, but McKenna's specific claims about what it *encodes* and what the wave *means* don't survive mathematical scrutiny.

## What ROAE cannot answer

The program cannot answer whether the wave "maps onto history" because that is an interpretive claim, not a mathematical one.
