# The roster's p-value vector (CX-37C-K, 2026-11-13)

`pvector_bounds.tsv` has one row per observable of the roster in
[CRITIQUE.md](../../../documentation/CRITIQUE.md) §"The observable roster": 1,452 rows. The
Benjamini–Hochberg and Benjamini–Yekutieli readings dated 2026-11-13 in METHODS, TR-8 and TR-10 are computed
on it, and `TestBatchQ1007.test_bh_statements_on_the_public_vector` re-runs each of them from this file.

**Columns.** `id` (the roster's stable id; the prefix names the family), `family`, `status`, `p1_lo`/`p1_hi`
(one-sided p-value, lower and upper bound), `p2_lo`/`p2_hi` (two-sided, min(1, 2·one-sided)), `note`.
`status` is one of `RECORDED` (a printed p-value), `DERIVED` (computed from printed counts as
min(below+at, at+above)/N; `kw` in the note is the King Wen value), `MULTI` (a section printing several
statistics: lo is the smallest, hi the largest), `BOUNDED` (only a bound is printed), `NO_TEST` (a roster
line with no test) and `MISSING` (a registered member never measured).

**Completions.** No reading depends on a value the file does not hold without saying so. Each BH or BY
statement is checked under four completions: *recorded* (`MISSING` and `NO_TEST` at 1, `MULTI` at its
smallest, `exp:constraints` at its printed bound), *worst* (`MULTI` at its largest), *best* (`MISSING` at 0)
and *widest* (*best*, and `NO_TEST` at 0 as well).

**Sources by family.** `c8:` (1,349) — `reports/evidence/c8screen/SUMMARY.tsv`. `dav:` (9) and `dav2:` (3) —
`reports/evidence/dav_tier1.out` and `dav2_tier1.out`. `f4p:` (13) — `f4p_tier1.out`. `r3:` (13) —
`perm_tier1.out`. `f5:` (11) — `f5/f5_tier1.out`. `exp:` (28) — the sections of `roae.py`, as quoted in each
row's note. `r7:`, `h1h3:`, `qoy:`, `tr8:`, `repr:` and `decoy:` — the registrations and reports named in the
roster's lines. `f6:` (7) — the tier output of the F6 books family is not in this repository; its seven values
are attested here, and five of them (all between 0.04 and 0.57 one-sided) are published for the first time.

Developed with AI assistance (Claude, Anthropic): assembled by a Fable lane (claude-fable-5-2), checked
against the public evidence in a second Fable review; packaged by an Opus lane.
