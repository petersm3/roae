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

There is no hidden periodicity in the wave. The autocorrelation drops off immediately, and the FFT shows no dominant frequency. The structure that does exist is algebraic (pair relationships, XOR regularity) rather than fractal. The signal he built his entire theory on doesn't contain the kind of self-similar structure his theory assumed.

## What ROAE cannot answer

The program cannot answer whether the wave "maps onto history" because that is an interpretive claim, not a mathematical one.
