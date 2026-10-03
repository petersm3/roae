#!/usr/bin/env python3
# https://github.com/petersm3/roae
# Developed with AI assistance (Claude, Anthropic)
"""
Figures for the technical-report suite (reports/TR*.md) — the "Planned improvements" figures.

Every number here is sourced from the public reports/documentation (data-source comments inline);
nothing is re-derived from enumeration data except the TR-6 parity-class string, which is computed
directly from solve.py's King Wen sequence (binary_hexagrams) exactly as TR-6/PARITY_ALTERNATION.md
define it (pair parity = popcount of the pair's hexagrams mod 2; pairs are parity-homogeneous, so the
first member suffices). The TR-7 cycle's edge distances and TR-5's 24-record orbit are computed from
the same sequence in the same way (Q-858); neither reads any enumeration output.

Figures produced (PNG + SVG, written to CWD — run from reports/figures/):
  fig_tr6_parity_alternations   — KW's 32-pair E/O class string with its 15 alternations marked (TR-6)
  fig_tr7_circular_cycle        — KW as a 64-cycle: odd transitions in red, the d = 3 wrap 64→1 (TR-7)
  fig_tr5_orbit_collapse        — B₃ (48) → S₄ (24) and King Wen's 24-record orbit, computed (TR-5)
  fig_tr4_boundary_information  — the S(k) log-decay curve + the k ≈ 14 marker where one surviving
                                  pair-ordering class is first reached at a constant last gain (TR-4 §5)
  fig_tr1_rules_tradeoff        — KW vs the grand unified precursor on the four conflicting rules
                                  (TR-1 §5 / TR-2; the conflict theorem's trade-off)
  fig_tr3_campaign_timeline     — first 560T run timeline with the 5 Spot-eviction marks
                                  (CAMPAIGN_METHODOLOGY.md eviction table)
  fig_tr12_kc_field             — V1 positional-marginal field   (viz/viz_kc_field.md)
  fig_tr12_kc_river             — V2 mass river + branch panel   (viz/viz_kc_river.md)
  fig_tr12_kc_spectrum          — V3 rank spectrum               (viz/viz_kc_spectrum.md)
  fig_tr12_kc_shells            — V4 King Wen's shells           (viz/viz_kc_shells.md)
  fig_tr12_kc_grammar           — V5 transition grammar          (viz/viz_kc_grammar.md)

The five TR-12 figures are TSV-in/figure-out, no analysis logic here: V1/V2/V5 read what `solve.py --atlas-queries ATLAS.json --atlas-out DIR` writes,
V4 needs `--atlas-q3-trace TRACE` added to that call, V3 needs the separate `solve.py --v3-spectrum GRID OUT` join (Q-699, V3A-140#3,
2026-09-25: this said all five came from the bare --atlas-queries call). V3 is optional; the other four refuse, with a message, if absent.

Requires: matplotlib (3.11.0 = EXPECTED_MATPLOTLIB for byte-identical PNGs), numpy (external — not a dependency of roae.py / solve.c).

Usage:
    cd reports/figures/ && python3 ../../viz/report_figures.py [--selftest] [--narrative] [TR12_ARTIFACT_ROOT]   (--narrative: also the two HELD, uncommitted narrative figures -- Q-862; a refusal of either exits 1, lane VR4)

TR12_ARTIFACT_ROOT defaults to the repository's own reports/tr12/ directory, resolved from THIS FILE's
location rather than from the working directory, so the invocation above works as written. It read
the bare relative path "tr12" until 2026-09-26, which from reports/figures/ named the nonexistent
reports/figures/tr12, so the documented command failed on all four required V-figures (VIZ1 F20).
"""
import math
import os
import re
import sys
import textwrap
from datetime import datetime, timedelta

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.dates as mdates

# Import solve.py (repo root) for the King Wen sequence — single source of truth.
_REPO_ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
sys.path.insert(0, _REPO_ROOT)
from solve import binary_hexagrams, reverse_6bit, _tsv_int  # noqa: E402

# 🔴 MINIMUM LEGIBLE TEXT (VIZ1 F18, 2026-09-26). THE FLOOR IS A DISPLAYED SIZE, NOT A POINT SIZE.
# These figures are read inline in rendered Markdown, where the viewer scales the WHOLE image to
# the column width. What a reader sees is fontsize_pt x (display_px / saved_width_pt), so a 6-pt
# label on a 13-inch canvas and a 10-pt label on a 22-inch one are equally unreadable; raising the
# raster dpi changes neither. Measured on the figures as committed before this change, at a 900-px
# display width: V2 branch labels 5.8 px, TR-6 positions 5.9 px, V4 alternative counts 6.8 px, the
# seven-point heat-map ticks 6.7 px, every provenance footer 4.8-5.2 px.
# The rule: every glyph must be at least MIN_TEXT_PX high when the saved figure's FULL width is
# shown at INLINE_PX, i.e. fontsize_pt >= MIN_TEXT_PX * width_pt / INLINE_PX. 900 px is about the
# width a rendered Markdown column gives an image on a desktop screen, and it is the width the review
# measured at; 12 px is the smallest size commonly used for secondary text on screen. The lever that
# makes the floor reachable is a NARROWER canvas (about 10 in), not a bigger font on a wide one: at
# 10 in the floor is 9.6 pt, at 13 in it would be 12.5 pt. save() MEASURES the SVG it is about to
# write and refuses to write either file when any glyph is below the floor, so this is a gate on
# the rendered bytes rather than a convention.
INLINE_PX = 900
MIN_TEXT_PX = 12


class FigureTextFloorError(Exception):
    """A figure carries text smaller than MIN_TEXT_PX at INLINE_PX display width (VIZ1 F18)."""


def _svg_text_sizes(svg):
    """(saved width in pt, [font size in pt of every text element]) read from matplotlib SVG TEXT.

    matplotlib writes each text artist as a `<g id="text_N">` group whose glyphs carry
    `scale(s -s)` with s = fontsize / 100 (DejaVu glyph units), so the sizes are read back from the
    bytes that will be published, not from the artists that were asked for.

    Q-889 (2026-09-28): EVERY GLYPH, NESTED SCALES COMPOSED. This read only each group's OUTER
    scale, but mathtext sets a superscript as `<use ... transform="translate(..) scale(0.7)">`
    INSIDE that group, so a 10-pt tick label `10^-42` carried its exponent at 7 pt and passed as
    10 pt: measured on the committed bytes, fig_tr4_boundary_information.svg shipped 25 glyphs at
    8.93 px and viz_scale.svg 21 at 8.84 px, under a 12-px floor the README calls "any glyph". The
    walk below composes every `<g>` and `<use>` transform from the text group down (scale, and
    matrix by its determinant) and reports one size per placed glyph; `<defs>` glyph outlines are
    font-unit definitions, not placements, and are skipped. A group with no placed glyph reports
    its outer scale, as before."""
    m = re.search(r'<svg\b[^>]*\swidth="([0-9.]+)pt"', svg)
    if not m:
        raise FigureTextFloorError("SVG carries no width in pt; the text floor cannot be measured")

    def factor(attrs):                   # the glyph-height scale one element's transform applies
        t = re.search(r'\btransform="([^"]*)"', attrs)
        f = 1.0
        for op, args in re.findall(r'(scale|matrix)\(([^)]*)\)', t.group(1) if t else ""):
            v = [float(x) for x in re.split(r'[\s,]+', args.strip())]
            f *= abs(v[-1]) if op == "scale" else math.sqrt(abs(v[0] * v[3] - v[1] * v[2]))
        return f

    sizes = []
    for chunk in svg.split('<g id="text_')[1:]:
        stack, in_defs, outer, placed = [1.0], 0, None, []
        for t in re.finditer(r'<(/?)(g|use|defs)\b([^>]*?)(/?)>', chunk):
            close, name, attrs, empty = t.groups()
            if name == "defs":
                in_defs += -1 if close else (0 if empty else 1)
            elif name == "g" and close:
                stack.pop()
                if not stack:
                    break                        # the text group itself has closed
            elif name == "g":
                f = stack[-1] * factor(attrs)
                if outer is None and f != 1.0:
                    outer = f
                if not empty:
                    stack.append(f)
            elif not in_defs:                    # a placed glyph
                placed.append(round(100.0 * stack[-1] * factor(attrs), 4))
        sizes.extend(placed if placed else ([round(100.0 * outer, 4)] if outer else []))
    return float(m.group(1)), sizes


def _text_floor_violations(width_pt, sizes):
    """The sizes that render below MIN_TEXT_PX when width_pt is displayed at INLINE_PX."""
    floor = MIN_TEXT_PX * width_pt / INLINE_PX
    return floor, sorted({s for s in sizes if s < floor - 1e-6})


def _full_size_decades(*axes):
    """Label log-axis decades as `1e-42` / `1e8` at the tick font size (Q-889, 2026-09-28).

    matplotlib's default `10^n` label sets n as a 0.7-scaled mathtext superscript: at the 10-pt
    tick size that is 7 pt, 8.8-8.9 px at a 900-px display, under the 12-px floor. Full-size
    characters carry the same number with no glyph below the tick size. Minor ticks stay unlabelled."""
    from matplotlib.ticker import FuncFormatter, NullFormatter

    def lab(v, _pos):
        e = round(math.log10(v)) if v > 0 else None
        return f"1e{e}" if e is not None and abs(math.log10(v) - e) < 1e-9 else ""
    for a in axes:
        a.set_major_formatter(FuncFormatter(lab))
        a.set_minor_formatter(NullFormatter())


# Q-899 / Q-900 (2026-09-28): TEXT CONTRAST IS CHECKED, NOT CHOSEN BY EYE. Codex VIZ H1/H2 measured
# text drawn in a series colour on white at 2.16-2.37:1 (V2's d=2 / d=3 band labels), white letters
# on TR-6's orange cells at 2.16:1 and TR-1's green value labels at 4.12:1, against the 4.5:1 WCAG 2
# floor for body text. Every text colour a renderer below places on a known background is asserted
# through this helper before anything is drawn, so a colour edit that drops under the floor refuses
# the figure instead of shipping it. Graphical marks (outlines, not text) are held to WCAG's 3:1
# non-text floor the same way (MIN_MARK_CONTRAST).
MIN_TEXT_CONTRAST = 4.5
MIN_MARK_CONTRAST = 3.0


def _wcag_contrast(a, b):
    """WCAG 2 contrast ratio of two '#rrggbb' colours (relative luminance, sRGB linearised)."""
    def lum(h):
        if not re.fullmatch(r"#[0-9a-fA-F]{6}", h):
            raise ValueError("not a #rrggbb colour: %r" % (h,))
        c = [int(h[i:i + 2], 16) / 255.0 for i in (1, 3, 5)]
        c = [v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4 for v in c]
        return 0.2126 * c[0] + 0.7152 * c[1] + 0.0722 * c[2]
    lo, hi = sorted((lum(a), lum(b)))
    return (hi + 0.05) / (lo + 0.05)


def _two_tone_floor(fg, under):
    """The worst case, over EVERY possible background, of the better of two stacked strokes.

    A thin `fg` stroke drawn over a wider `under` stroke shows the background both colours; the
    mark stays visible against a background if either colour contrasts with it. Contrast with a
    background of luminance L falls as L approaches a stroke's own, so the worst background is the
    one where both ratios are equal: (L + .05)^2 = (L_hi + .05)(L_lo + .05). V1's cyan outline
    alone reached 1.9:1 on the brightest magma cell and V5's white outline 2.2:1 on viridis green
    (Codex VIZ H05); with a #111111 under-stroke the floor is this function's value for ANY cell."""
    return math.sqrt(_wcag_contrast(fg, under))


# 🔴 Q-668, 2026-09-20. TEXT BAKED INTO A RENDERED FIGURE IS OUTSIDE EVERY GREP-BASED
# GATE. matplotlib renders labels to glyph paths, so GATE 3, GATE 6 and every retraction
# scan are blind to them -- a figure can assert a withdrawn claim while every
# documentation gate reports clean. That is not hypothetical: a superseded band label
# lived in a published PNG and SVG for 49 days (CX-55).
#
# This manifest binds each figure stem to the STATIC label text it renders, so the text
# gates have something they CAN read. It is generated from the source and pinned; the
# tests in tests.py fail when a label is edited here without updating it, and refuse any
# entry that matches a registered retracted phrase.
#
# ⚠ IT IS NOT COMPLETE, AND SAYING SO IS THE POINT. Labels built by f-string, string
# concatenation or a call are COMPUTED at render time and exist as no literal anywhere.
# Measured 2026-09-20: 34 static label sites, 10 computed ones. fig_tr12_kc_spectrum had
# ZERO static labels then -- every word it rendered was computed; since 2026-09-24 it has
# one (its x-axis label), and its titles are still computed. FIGURE_LABEL_UNCOVERED pins those counts as a RATCHET: new uncovered text cannot
# appear silently, it has to move a number a test is watching.
FIGURE_LABEL_MANIFEST = {
    'fig_tr12_kc_field': (
        # Q-899 (2026-09-28): slot s vs layer k, the pair -> hexagram key, the seven-profile note.
        'Pairs in one symmetry orbit have equal rows, so rows repeat by construction; a zero row\nis pair 0 (pinned to slot 1 by C4) or a pair this table does not place.',
        'The 31 free pairs share SEVEN distinct rows (their symmetry orbits): equal rows are\nforced by symmetry, not discovered. Pair 0 is pinned to slot 1 by C4, so its row is 0.',
        "V1 — positional-marginal field P(pair j in slot s), exact over\nC1C2C4C5-SUPERSPACE; C3 not imposed\nno King Wen placement is marked in this table (kw = 0 on every row)", "V1 — positional-marginal field P(pair j in slot s), exact over\nC1C2C4C5-SUPERSPACE; C3 not imposed\noutlined: King Wen's own placements (diagonal by construction —\nthe value, not the shape, is the content)",
        'pair j = King Wen hexagrams 2j+1 and 2j+2',
        'pair-slot s (layer k fills slot s = k+2)',
    ),
    'fig_tr12_kc_grammar': (
        # 2026-09-24: the title is now STATIC per branch (it was composed at runtime, which
        # left the orbit caveat as text no gate could read).  All three branch literals are
        # pinned; FIGURE_LABEL_UNCOVERED for this stem drops 1 -> 0.  2026-09-26 (VIZ1 F06): the
        # caveat's wording is corrected -- see the note at the titles in fig_tr12_kc_grammar.
        # Q-899 (2026-09-28): the space label says C3 is not imposed, d and w are defined in lines.
        "Each column averages over the whole superspace: it is not conditioned on King Wen's\n(or any walk's) earlier choices, and the columns do not compose into a chain.",
        "V5 — transition grammar P(class | layer k), exact over\nC1C2C4C5-SUPERSPACE; C3 not imposed; read DOWN each column (every column sums to 1)\nREDUCED FORM: this table carries no w axis (w = -1), so a row is a\ndistance class d and the white outline is King Wen's own d",
        'V5 — transition grammar P(class | layer k), exact over\nC1C2C4C5-SUPERSPACE; C3 not imposed; read DOWN each column (every column sums to 1)\nno King Wen overlay in this table — kw_d/kw_w match no plotted class\nat any layer (n != 31?)',
        "V5 — transition grammar P(d, w | layer k), exact over\nC1C2C4C5-SUPERSPACE; C3 not imposed; read DOWN each column (every column sums to 1)\nd = lines differing across the boundary into the new pair, w = lines differing\nbetween the new pair's two hexagrams.\nThe seven pair-orbits are grouped into three within-pair-distance categories;\neach row fixes one (d,w) combination and does not identify an individual pair.",
        'layer k (places the new pair in pair-slot k+2)',
    ),
    'fig_tr12_kc_river': (
        "KEY — d = number of lines that differ across a pair boundary (the exit hexagram of one pair\nagainst the entry hexagram of the next). King Wen's line marks which class it is in at each\nlayer; its height inside the band is not a probability. A branch is one first free placement:\na pair j and its orientation, named pair : entry, the entry hexagram's six-bit code (0–63).\nOne t-unit is one valid oriented prefix, not one production-DFS node.",
        "V2 — mass river: exact per-layer boundary-distance class mass over\nC1C2C4C5-SUPERSPACE; C3 not imposed. Each layer is a unit-width bin, so a band's\nAREA is its class total, fixed by the C1+C5 theorem; only the shape across k is informative",
        'branch = pair j : entry hexagram code (0–63), sorted by mass',
        'branch panel — solution mass (bars) vs exhaustion cost (line);\nmeasured at n=31 the two are CO-MONOTONE: no branch is small-but-expensive',
        'branch share of N',
        'exhaustion cost unavailable: every prefixes_t_units\ncell reads PENDING_T_LADDER (no t-ladder was given)',
        'layer k (fills pair-slot k+2); each layer is a unit-width bin',
        'log10 exhaustion cost (t-units = valid prefixes)',
        'share of C1C2C4C5-SUPERSPACE',
    ),
    'fig_tr12_kc_shells': (
        "V4 — King Wen's neighbourhood shells in C1C2C4C5-SUPERSPACE; C3 not imposed\nexact completions remaining after each of King Wen's 31 free placements\nEVERY point is King Wen's own trajectory — the line plots ONE walk, not a\npopulation (annotation = # admissible alternatives)",
        "V4 — neighbourhood shells of the traced walk in C1C2C4C5-SUPERSPACE; C3 not imposed\nexact completions remaining after each of the walk's free placements\nNOT identified as King Wen's walk — every point is this ONE walk's own\ntrajectory, not a population (annotation = # admissible alternatives)",
        "black tick: log2 a_i, the bits if all a_i admissible alternatives\nhad equal completion counts (a_i = the count printed above the curve).\nA bar above its tick: King Wen's choice has fewer completions\nthan the average alternative.",
        "black tick: log2 a_i, the bits if all a_i admissible alternatives\nhad equal completion counts (a_i = the count printed above the curve).\nA bar above its tick: the walk's choice has fewer completions\nthan the average alternative.",
        "log10 g(King Wen's prefix) — completions remaining",
        "log10 g(the walk's prefix) — completions remaining",
        "shaded bars: least to greatest g over ALL admissible\nalternatives at each step, King Wen's own choice included\n(this table's g_alt_min / g_alt_max)",
        "shaded bars: least to greatest g over ALL admissible\nalternatives at each step, King Wen's own choice included.\nATTESTED: 2026-09-22 n=31 battery receipts (q3_profile_exact.tsv);\nnot reproducible without the f/g ladders",
        "shaded bars: least to greatest g over ALL admissible\nalternatives at each step, the walk's own choice included\n(this table's g_alt_min / g_alt_max)",
        'step (free placement i)',
        "surprisal of King Wen's next choice: −log2 p_i bits, p_i = g_i / g_(i−1), the share of\nthe previous shell that makes King Wen's choice. The bars sum to log2 N, N = |C1∩C2∩C4∩C5|\n(EW-1). A step with ONE admissible alternative costs 0 bits.",
        "surprisal of the walk's next choice: −log2 p_i bits, p_i = g_i / g_(i−1), the share of\nthe previous shell that makes the walk's choice. The bars sum to log2 N, N = |C1∩C2∩C4∩C5|\n(EW-1). A step with ONE admissible alternative costs 0 bits.",
        '−log2 p_i (bits)',
    ),
    'fig_tr12_kc_spectrum': (
        'x = rank / N',
    ),
    'fig_tr1_rules_tradeoff': (
        # Q-900 (2026-09-28): a four-row table; every cell is a literal, so uncovered drops 1 -> 0.
        '0 breaks',
        '0 misses (18/18)',
        '0 violations',
        '2 breaks',
        '2 misses (16/18)',
        '2 violations',
        'KW keeps the trigram configuration exactly and misses the other three by two each\n(no extremal check excludes a smaller miss); the 3-edit grand precursor perfects\nthose three and breaks the trigram configuration. Both cannot be had.',
        'King Wen\n(received order)',
        'Moore 1989 — rising/falling rhythm',
        'Moore 2005 — pair-positioning parity\n(18 testable positions)',
        'Schulz 1990 — gender rule',
        'Schulz 2011/2016 — trigram configuration\nof stations 25–28 (binary rule)',
        "THE CONFLICT THEOREM's trade-off: the four rules cannot all be satisfied\n(jointly UNSAT under C1+C2+C4+C5, drat-trim-verified) — any ordering must choose",
        'precursor\n(3 slot-edits from KW)',
        "precursor = the grand unified precursor, 3 slot-edits from King Wen (TR-1 §5).\nstation = one of Lai Zhide's 36 consolidated units, the numbering Schulz's rules use (TR-2).",
        'rule (author, year)',
        'satisfied',
        'violated',
    ),
    'fig_tr3_campaign_timeline': (
        '2026, Pacific Time',
        'First 560T campaign timeline — 5 Spot evictions, all M-F\nin a 37-min window (07:12–07:49 PT), 0 on the weekend',
        'enum complete\n171.5 h wall',
        'launch\nSun 17:03 PT',
        'weekend: 0 evictions\n(Fri 18:01 → finish: 50.5 h uninterrupted)',
    ),
    'fig_tr4_boundary_information': (
        'S(k) = fraction of the full C1–C5 population (orientation-explicit)\nagreeing with KW (log scale)',
        'The boundary-information curve S(k) — slice-uniqueness vs space-uniqueness\n(the first 4 of the 5 boundaries that identify KW in the 560T slice still admit ≈8.4×10²⁵ full-space orderings)',
        'k = number of King Wen boundary constraints imposed',
        'k ≈ 14: the earliest the\npair-ordering floor is\nreached IF no later boundary\ngains more than the 8th\nmeasured one (6.14 bits).\nA scale marker, not a bound;\nno far end set by the data.',
        'one ORIENTED ordering:\n1/1.3287×10³⁸ = 7.53×10⁻³⁹,\n20.71 bits lower. Pins fix pair\nidentity, not orientation, so\nno k reaches this level.',
        'reachable floor: S = 1,720,320/1.3287×10³⁸ = 1.29×10⁻³² (one surviving pair-ordering class)',
    ),
    # Q-858 (2026-09-27): TR-5 and TR-7 have renderers; before that their committed artwork carried
    # text no gate could read AND no source that could be edited.
    'fig_tr5_orbit_collapse': (
        '',
        'B₃, order 48\nsigned line-permutations preserving C1–C5',
        'King\nWen',
        "King Wen's record and its 23 twins",
        'S₄, order 24\nacting faithfully and freely on\ncanonical pair-order records',
        'The symmetry collapse',
        "every record's orbit has exactly\n24 records: no record is fixed by\nany non-identity element",
        'free-action theorem: for an\nS₄-closed set of R records,\nrecord-orbit count = R/24,\nexactly (a budgeted slice\nneed not be S₄-closed)',
        'one orbit:\n24 canonical\npair-order records\n(48 oriented sequences),\nalike under every\nS₄-invariant criterion',
        'quotient by {±I}: −I turns each\nhexagram upside down, mapping\nevery pair onto itself; records\nignore the order within a pair,\nso ±I moves no record',
    ),
    'fig_tr6_parity_alternations': (
        '16→17: O→E — the alternation between the two rows',
        'pair position 1–32, pairs 1–16 on the top row and 17–32 below (pair p = King Wen\nsequence positions 2p−1, 2p; class = popcount parity, E = even, O = odd;\nfirst pair {63, 0} is even — pinned by C4)',
    ),
    'fig_tr7_circular_cycle': (
        'King Wen read as a cycle:\nthe wrap edge adds exactly one odd transition',
        "King Wen's wrap 64→1: d = 3\n(3 of the 6 lines change)",
        'the King Wen sequence as a cycle,\n#1 → #64 clockwise\n\nthick red edges: odd Hamming-distance\ntransitions\n\nlinear reading (63 edges): 15\ncircular reading (64 edges): 16',
        'wrap-parity theorem: for EVERY ordering satisfying C4 and C5,\nthe wrap distance d(#64, #1) is odd',
    ),
    'viz_narrative_n1_object': (
        '',
        'N-1 — the object: the received King Wen ordering of the 64 hexagrams,\nas its 32 consecutive pairs, drawn from the sequence itself\n(solve.py `binary_hexagrams`), not from a schematic',
        'WHAT THIS IS — the received King Wen ordering. Each cell is one pair; the numbers beneath the two\nhexagrams are their sequence positions, so pair p occupies positions 2p−1 and 2p, and the grey\nthread runs 1 → 64 through the pairs in order. Lines are read bottom-to-top: a full bar is a solid\n(yang) line, a split bar a broken (yin) line.\nTHE PAIRING RULE (C1, documentation/SPECIFICATION.md) — the second hexagram of a pair is the first\nREVERSED (turned upside down); where a hexagram is its own reversal, its partner is the line-by-line\nCOMPLEMENT instead. Both the split (28 reversal, 4 complement) and every individual pairing on this\nfigure are derived from the sequence by the generator and asserted, not annotated by hand.\nTHE RULE IS CLASSICAL AND NOT A RESULT OF THIS PROJECT — it is stated explicitly by Kong Yingda\n(574–648) and has an earlier lineage. The classical formulation is quoted, in Chinese, in\ndocumentation/KING_WEN_PROVENANCE.md and SPECIFICATION.md; it is not reproduced in this figure only\nbecause the stock matplotlib font carries no CJK glyphs and would render it as empty boxes.\nThis figure makes no claim about the ordering. It is the object that every later claim in the\nnarrative is a claim about.',
    ),
    'viz_narrative_n2_fg_mechanism': (
        '',
        'Every complete walk crosses every layer EXACTLY ONCE. So a walk through state s is a\nprefix that reaches s paired with a completion that leaves it — and the number of\nwalks through s is the PRODUCT f(s)·g(s). Summing that product over every state in\nthe layer counts every walk in the space, once:',
        'N-2 — the f·g mechanism: how an exact count is COMPUTED rather than\ncounted, over the C1C2C4C5-SUPERSPACE\nN = |C1∩C2∩C4∩C5| = 1,097,051,278,789,181,790,036,112,071,176,579,186,688\n— C3 is not among its constraints, and neither are C6/C7',
        'NOTHING HERE IS SAMPLED, ESTIMATED OR FITTED. The sum runs over every state in the\nlayer, the values are exact 192-bit integers, and the identity is CHECKED:\nreports/KC_G_CHECK_n31.txt evaluates it at all 32 layers and reports 0 failing layers.\nThis is why N can be COMPUTED from a completed ladder in seconds rather than counted\n— the enumerator never has to visit the walks in order to count them.',
        'f — the FORWARD ladder,\nbuilt k = 0 → 31',
        'f(s) = the exact number of valid\nPREFIXES that reach state s',
        'g — the BACKWARD ladder,\nbuilt k = 31 → 0',
        'g(s) = the exact number of\nCOMPLETIONS from state s',
        'k = 0\n(empty prefix)',
        'k = 31\n(a complete walk)',
        'log10 of the exact count',
        'one layer k —\na cut across every walk',
        "step i — King Wen's 31 free placements (C4 pins the first pair-slot);\nstep i arrives at ladder layer k = i",
        "the same two quantities as PUBLISHED EXACT INTEGERS, along King Wen's own\nwalk — f rises as prefixes accumulate, g falls as freedom is spent",
        'Σ over EVERY state s in layer k:   orbit(mask(s)) · f(s) · g(s)   =   N',
        '— and this holds at every one of the 32 layers, k = 0 … 31',
        '⚠ This panel is ONE walk. For a single state, f(s)·g(s)\nis the number of walks THROUGH THAT STATE — it is not N.\nOnly the sum over the whole layer, in the panel above,\nequals N.',
    ),
    'viz_scale': (
        '',
        'POINTS — budgeted C1–C5 slices: canonical pair orderings, orientation masked; each count is a LOWER BOUND.\nLINE — N = |C1∩C2∩C4∩C5|, exact, in orientation-explicit sequences: C1C2C4C5-SUPERSPACE; C3 not imposed.\nUNITS — The plotted ratio is 29.0 decades; comparing pair orderings with pair orderings gives 19.7–23.9 decades.',
        'The scale figure — a node-BUDGETED SLICE of C1–C5 against the EXACT\ncompiled C1C2C4C5-SUPERSPACE: three canonical enumerations; N sits ~29 decades\nabove the deepest, counted in different units (see caption)',
        'count (log scale) — ⚠ the two series COUNT DIFFERENT SPACES, see caption',
        'per-cell node budget, SOLVE_PER_SUB_BRANCH_LIMIT (log scale)',
    ),
}

FIGURE_LABEL_UNCOVERED = {
    'fig_tr12_kc_field': 0,
    'fig_tr12_kc_grammar': 0,
    'fig_tr12_kc_river': 1,
    'fig_tr12_kc_shells': 1,
    'fig_tr12_kc_spectrum': 3,   # Q-899 (2026-09-28): 2 -> 3, the reading-key panel's text is composed from the table
    'fig_tr1_rules_tradeoff': 0,   # Q-900 (2026-09-28): 1 -> 0, the table's cells are literals
    'fig_tr3_campaign_timeline': 1,
    'fig_tr4_boundary_information': 1,
    'fig_tr5_orbit_collapse': 0,
    'fig_tr6_parity_alternations': 3,
    'fig_tr7_circular_cycle': 1,
    'viz_narrative_n1_object': 3,
    'viz_narrative_n2_fg_mechanism': 0,
    'viz_scale': 3,     # Q-890 (2026-09-28): 2 -> 3, the N label is now generated from N
}


def save(fig, stem, provenance=None):
    """Write PNG + SVG, stamping the PROVENANCE footer into the figure margin.

    Q-307 (2026-08-27 D6 review, filed 2026-09-04): nothing bound a rendered
    figure to the TSV it was rendered from.  A reader holding the PNG had no way
    to tell WHICH v1_field.tsv produced it, and a re-render from a different
    table was indistinguishable from the original.  The footer carries the
    source basename and the first 12 hex of its sha256, which is enough to
    settle that question and short enough not to intrude on the plot.

    It is deliberately TIMESTAMP-FREE: a clock in the footer would make every
    re-render a different file and destroy byte-comparability, which is the
    property the atlas half of TR-12 exists to have.

    Q-667 (2026-09-20).  That footer property holds, and for the PNG the whole
    claim holds: a re-render of an UNMODIFIED generator reproduced the committed
    PNG byte-identically (CX-55, sha 5640d0cd), which is what let that cure
    attribute its change to the edit rather than to renderer drift.  THE SVG IS
    DIFFERENT AND THIS DOCSTRING USED TO OVERSTATE IT: it read "Same input bytes
    in, same figure out" without qualification.  matplotlib stamps a <dc:date>
    creation time and salts element ids, neither of which this function
    controls, so a zero-change SVG re-render produced 152 differing lines at an
    IDENTICAL byte count -- a size or length check sees nothing and only a line
    diff catches it.  So: PNG comparison is BYTE-wise; SVG comparison is
    LINE-wise, and any gate asserting SVG byte-equality would be unsatisfiable
    by construction (the class filed as Q-652).  Pinning the SVG out would mean
    setting svg.hashsalt and a fixed metadata Date, which rewrites every
    committed SVG in the tree; that is deliberately NOT done here, and CX-55
    records the same decision.

    The footer is also the thing GATE 6 polices: that gate greps the GENERATOR's
    annotation strings because matplotlib renders text to glyph paths and the
    rendered figure is unreadable to grep.  Text that reaches a figure only
    through this function is text GATE 6 can see."""
    import io
    if provenance:
        # VIZ1 F18 (2026-09-26): the footer was 5-pt text pinned to the figure's bottom-right
        # corner -- 4.8-5.2 px at a 900-px display. It is now set at the text floor for the
        # figure's own width, WRAPPED to that width at the double-space separators between
        # sources (a digest is never split), and placed BELOW everything else drawn, so a
        # larger footer cannot land on an axis label or a legend. The printed line below
        # still carries the unwrapped string, so the battery's c_viz golden does not move.
        r = fig.canvas.get_renderer()
        bb = fig.get_tightbbox(r)
        w_pt = (bb.width + 0.2) * 72.0          # + savefig's default 0.1-in pad each side
        fs = math.ceil(10.0 * MIN_TEXT_PX * w_pt / INLINE_PX) / 10.0
        per_line = max(20, int(bb.width * 72.0 / (0.602 * fs)))   # DejaVu Sans Mono advance
        lines, cur = [], ""
        for part in [p.strip() for p in provenance.split("  ") if p.strip()]:
            if cur and len(cur) + 2 + len(part) > per_line:
                lines.append(cur)
                cur = part
            else:
                cur = (cur + "  " + part) if cur else part
        lines.append(cur)
        fig.text(bb.x1 / fig.get_figwidth(), (bb.y0 - 0.06) / fig.get_figheight(),
                 "\n".join(lines), ha="right", va="top",
                 fontsize=fs, color="#6f6f6f", family="monospace")
    buf = io.BytesIO()
    fig.savefig(buf, format="svg", bbox_inches="tight")
    w_pt, sizes = _svg_text_sizes(buf.getvalue().decode("utf-8"))
    floor, bad = _text_floor_violations(w_pt, sizes)
    if bad:
        plt.close(fig)
        raise FigureTextFloorError(
            f"{stem}: text at {bad} pt is below the {floor:.2f}-pt floor for a {w_pt:.1f}-pt-wide "
            f"figure ({MIN_TEXT_PX} px at {INLINE_PX} px display); nothing was written")
    fig.savefig(f"{stem}.png", dpi=150, bbox_inches="tight")
    with open(f"{stem}.svg", "wb") as fh:
        fh.write(buf.getvalue())
    plt.close(fig)
    # 🔴 Codex MQ1 §2e, 2026-09-07. This line used to print filenames ONLY, and the c_viz
    # golden captured just those four "Saved ..." lines -- so a mutant that zeroed every
    # ordinate re-rendered happily and golded BYTE-IDENTICALLY. A gate whose observation
    # cannot change when the data changes is not gating the data.
    # The fix is NOT to hash the PNG/SVG bytes: those move with the matplotlib version and
    # would make the golden fail on an unrelated upgrade. This function already binds each
    # figure to its SOURCE by sha256 for the footer, so the honest observation is that
    # binding -- printed, and therefore golded. Change the data, change the source sha,
    # diverge the golden. `src=NONE` is printed rather than hidden when a figure carries no
    # provenance at all, because silence there is what let this through.
    print(f"Saved {stem}.png and {stem}.svg  src={provenance or 'NONE'}")


# ---------------------------------------------------------------------------
# TR-6 — King Wen's 32-pair parity-class string with its 15 alternations
# ---------------------------------------------------------------------------
def fig_tr6_parity_alternations():
    # Pair parity class: popcount of the pair's first hexagram mod 2 (pairs are
    # parity-homogeneous — TR-6 Lemma 1 — so the first member determines the class).
    classes = ["E" if bin(binary_hexagrams[i]).count("1") % 2 == 0 else "O"
               for i in range(0, 64, 2)]
    s = "".join(classes)
    n_alt = sum(1 for i in range(31) if s[i] != s[i + 1])
    assert s.count("E") == 16 and s.count("O") == 16, "16/16 split (TR-6 Lemma 2)"
    assert n_alt == 15, "exactly 15 alternations (TR-6 theorem)"

    col = {"E": "#1f77b4", "O": "#e8a33d"}
    # Q-900 (Codex VIZ H2-09, 2026-09-28): the cell letter IS the non-colour encoding, and white on
    # the orange cells was 2.16:1. O is now set in #111111 (8.76:1); E stays white on blue (4.82:1).
    ink = {"E": "#ffffff", "O": "#111111"}
    for c in col:
        assert _wcag_contrast(ink[c], col[c]) >= MIN_TEXT_CONTRAST, "TR-6 cell letter %s contrast" % c
    # VIZ1 F18 (2026-09-26): TWO ROWS OF 16, not one strip of 32. As one 16-inch strip the pair
    # positions rendered at 5.9 px on a 900-px display; no font size fixes that on a canvas that
    # wide, because the viewer shrinks the whole image. Pairs 1-16 are the top row, 17-32 the
    # bottom; an alternation between pair 16 and pair 17 is marked at the END of the top row.
    # Q-900 (Codex VIZ H2-10): that end-of-row mark had nothing after it, so the fifteenth
    # alternation had to be reconstructed by the reader. A dashed connector now runs from it to the
    # start of the second row, labelled with the pairs and classes it joins. The rows are further
    # apart (2.35, was 1.95) to make room for it.
    ROW = 16
    RY = (2.35, 0.0)                         # bottom edge of the cells in row 0 and row 1
    fig, ax = plt.subplots(figsize=(9.2, 4.75), dpi=150)
    for i, c in enumerate(classes):
        x, y = i % ROW, RY[i // ROW]
        ax.add_patch(plt.Rectangle((x, y), 0.92, 1, facecolor=col[c],
                                   edgecolor="white", linewidth=1.2))
        ax.text(x + 0.46, y + 0.5, c, ha="center", va="center",
                fontsize=13, fontweight="bold", color=ink[c])
        ax.text(x + 0.46, y - 0.24, str(i + 1), ha="center", va="center", fontsize=10.5,
                color="#444444")
    # alternation marks between consecutive pairs of different class
    for i in range(31):
        if classes[i] != classes[i + 1]:
            x, y = i % ROW, RY[i // ROW]
            ax.plot([x + 0.96, x + 0.96], [y - 0.05, y + 1.05], color="#d32f2f", lw=2.2, zorder=5)
            ax.plot(x + 0.96, y + 1.15, marker="v", color="#d32f2f", ms=6, zorder=5)
    wrap = classes[ROW - 1] != classes[ROW]
    assert wrap and (classes[ROW - 1], classes[ROW]) == ("O", "E"), \
        "the 16->17 boundary is an O->E alternation (the connector label says so)"
    # The connector: down from the end-of-row mark, back along the gap between the rows, and down
    # into the left edge of pair 17.
    yc = RY[0] - 0.62
    ax.plot([ROW - 0.04, ROW - 0.04, -0.2, -0.2], [RY[0] - 0.05, yc, yc, RY[1] + 1.02],
            color="#d32f2f", lw=1.3, ls=(0, (4, 2.5)), zorder=4)
    ax.plot(-0.2, RY[1] + 1.02, marker="v", color="#d32f2f", ms=6, zorder=5)
    ax.text(ROW - 0.12, yc - 0.06, "16→17: O→E — the alternation between the two rows",
            ha="right", va="top", fontsize=10.5, color="#8b1a1a")
    ax.text(8, 4.0,
            f"King Wen's parity-class string: 16 E / 16 O, exactly {n_alt} alternations\n"
            "(red marks) — forced by C1–C5, not a design choice",
            ha="center", va="center", fontsize=12.5)
    ax.text(8, -0.78, "pair position 1–32, pairs 1–16 on the top row and 17–32 below (pair p = King Wen\n"
                      "sequence positions 2p−1, 2p; class = popcount parity, E = even, O = odd;\n"
                      "first pair {63, 0} is even — pinned by C4)",
            ha="center", va="center", fontsize=10.5, color="#444444")
    ax.set_xlim(-0.4, 16.3)
    ax.set_ylim(-1.15, 4.4)
    ax.axis("off")
    fig.tight_layout()
    save(fig, "fig_tr6_parity_alternations")


# ---------------------------------------------------------------------------
# TR-7 — the King Wen sequence read as a cycle, odd transitions and the 64→1 wrap marked
# ---------------------------------------------------------------------------
# Q-858 (2026-09-27). This figure and TR-5's were committed on 2026-07-04 as finished artwork with
# no renderer anywhere (VIZ1 F15; open since the 2026-07-04 adversarial round-2 review). Both are
# now drawn here from solve.py's King Wen sequence, and every number the drawing shows is ASSERTED
# from that sequence before anything is drawn, as fig_tr6_parity_alternations does.
def _tr7_cycle_edges():
    """[(i, j, d)] for the 64 edges of King Wen read as a cycle: position i -> j = (i + 1) mod 64
    (0-based), d = Hamming distance. Edge 63 is the wrap edge #64 -> #1. Pure; no matplotlib."""
    kw = binary_hexagrams
    if len(kw) != 64 or sorted(kw) != list(range(64)):
        raise ValueError("binary_hexagrams is not a permutation of the 64 hexagrams")
    return [(i, (i + 1) % 64, bin(kw[i] ^ kw[(i + 1) % 64]).count("1")) for i in range(64)]


def fig_tr7_circular_cycle():
    edges = _tr7_cycle_edges()
    internal_odd = sum(1 for i, _, d in edges[:63] if d % 2)
    wrap_d = edges[63][2]
    # TR-7 as published: 15 odd transitions in the linear reading, the wrap 64 -> 1 has d = 3, so the
    # circular reading has 16. The static labels below state exactly these numbers, so they are
    # asserted rather than formatted in.
    assert internal_odd == 15, "15 odd transitions in the linear reading (TR-6/TR-7)"
    assert wrap_d == 3, "the wrap edge 64 -> 1 has Hamming distance 3 (TR-7)"
    assert internal_odd + (wrap_d % 2) == 16, "16 odd transitions around the cycle (TR-7)"

    # Position p (1-based) sits at angle 90 - (p - 0.5) * 360/64 degrees: #1 just clockwise of the
    # top, #64 just counter-clockwise of it, so the wrap edge is the short chord at 12 o'clock and
    # the sequence runs clockwise.
    ang = [math.radians(90.0 - (i + 0.5) * 360.0 / 64) for i in range(64)]
    xy = [(math.cos(a), math.sin(a)) for a in ang]
    c_even, c_odd, c_node = "#b7c7dc", "#d32f2f", "#3f5f8f"
    fig, ax = plt.subplots(figsize=(8.0, 8.0), dpi=150)
    for i, j, d in edges:
        (x0, y0), (x1, y1) = xy[i], xy[j]
        if i == 63:
            ax.plot([x0, x1], [y0, y1], color=c_odd, lw=6.0, solid_capstyle="round", zorder=3)
        elif d % 2:
            ax.plot([x0, x1], [y0, y1], color=c_odd, lw=3.4, solid_capstyle="round", zorder=2)
        else:
            ax.plot([x0, x1], [y0, y1], color=c_even, lw=1.5, zorder=1)
    ax.scatter([p[0] for p in xy], [p[1] for p in xy], s=46, color=c_node, zorder=4,
               edgecolors="white", linewidths=0.8)
    # Position labels outside the ring, every 16th position plus both ends of the wrap edge.
    # #1 and #64 straddle 12 o'clock, so they are set flush right/left of it rather than centred.
    for p, lab, ha in ((1, "#1", "left"), (16, "#16", "center"), (32, "#32", "center"),
                       (48, "#48", "center"), (64, "#64", "right")):
        a = ang[p - 1]
        ax.text(1.12 * math.cos(a), 1.12 * math.sin(a), lab, ha=ha, va="center",
                fontsize=12, color="#222222")
    # Q-900 (Codex VIZ H2-11, 2026-09-28): ONE annotation said both "King Wen's wrap has d = 3" and
    # "the theorem forces it odd", so a cold reader could not tell the particular fact from the
    # general one, and d was not defined. They are now two texts: King Wen's own distance at the
    # edge it labels (with d spelled out as lines changed), and the theorem, with its premise
    # (C4 and C5, TR-7 §2), under the ring as a statement about every such ordering.
    ax.annotate("King Wen's wrap 64→1: d = 3\n(3 of the 6 lines change)",
                xy=(0.0, 1.0), xytext=(0.72, 1.36), ha="center", va="center", fontsize=12,
                color="#8b1a1a",
                arrowprops=dict(arrowstyle="->", color="#8b1a1a", lw=1.3))
    ax.text(0.0, -1.36, "wrap-parity theorem: for EVERY ordering satisfying C4 and C5,\n"
                        "the wrap distance d(#64, #1) is odd",
            ha="center", va="center", fontsize=12, color="#2c4a73")
    ax.text(0.0, 0.0,
            "the King Wen sequence as a cycle,\n#1 → #64 clockwise\n\n"
            "thick red edges: odd Hamming-distance\ntransitions\n\n"
            "linear reading (63 edges): 15\ncircular reading (64 edges): 16",
            ha="center", va="center", fontsize=12.5, color="#2c4a73", linespacing=1.3)
    ax.set_title("King Wen read as a cycle:\nthe wrap edge adds exactly one odd transition",
                 fontsize=13, pad=14)
    ax.set_xlim(-1.3, 1.3)
    ax.set_ylim(-1.55, 1.55)
    ax.set_aspect("equal")
    ax.axis("off")
    fig.tight_layout()
    save(fig, "fig_tr7_circular_cycle",
         "source: solve.py binary_hexagrams (King Wen sequence, OEIS A102241)  "
         "theorem: reports/TR7_CIRCULAR_READING.md   (viz/report_figures.py)")


# ---------------------------------------------------------------------------
# TR-5 — the symmetry collapse B3 (48) -> S4 (24), and King Wen's record-level orbit of 24
# ---------------------------------------------------------------------------
def _tr5_kw_orbit():
    """King Wen's orbit under G = the bit permutations commuting with bit reversal (TR-5 §1).

    Returns {"G", "center", "oriented", "records", "quotient_orders"}: G as permutation tuples
    (bit i -> position p[i]), its centre, the distinct oriented sequences sigma(KW), the distinct
    canonical pair-order records they give (a record = the 32 pairs as unordered sets, so the
    orientation within a pair is forgotten), and the element-order histogram of G/centre. Pure;
    computed from solve.py's sequence and reverse_6bit, no matplotlib."""
    from itertools import permutations
    from collections import Counter

    def act(p, h):
        return sum(((h >> i) & 1) << p[i] for i in range(6))

    def comp(p, q):                    # act(comp(p, q), h) == act(p, act(q, h))
        return tuple(p[q[i]] for i in range(6))

    ident = tuple(range(6))
    G = [p for p in permutations(range(6))
         if all(act(p, reverse_6bit(h)) == reverse_6bit(act(p, h)) for h in range(64))]
    center = [z for z in G if all(comp(z, g) == comp(g, z) for g in G)]
    kw = binary_hexagrams
    oriented = {tuple(act(p, h) for h in kw) for p in G}
    records = {tuple(frozenset(s[2 * k:2 * k + 2]) for k in range(32)) for s in oriented}

    def qorder(g):
        k, x = 1, g
        while x not in center:
            x, k = comp(g, x), k + 1
        return k
    orders = Counter(qorder(g) for g in G)
    return {"G": G, "center": center, "ident": ident, "oriented": oriented, "records": records,
            "quotient_orders": {k: v // len(center) for k, v in sorted(orders.items())}}


def fig_tr5_orbit_collapse():
    o = _tr5_kw_orbit()
    rev = (5, 4, 3, 2, 1, 0)
    # Every number the drawing states, asserted from the sequence (TR-5 §1, §4).
    assert len(o["G"]) == 48, "B3 has order 48 (TR-5 §1)"
    assert sorted(o["center"]) == sorted([o["ident"], rev]), "the centre is {I, reversal} = {±I}"
    assert o["quotient_orders"] == {1: 1, 2: 9, 3: 8, 4: 6}, "G/{±I} has S4's element orders"
    assert len(o["oriented"]) == 48, "48 distinct oriented sequences in King Wen's orbit"
    assert len(o["records"]) == 24, "24 distinct canonical pair-order records: a free S4 orbit"
    n_ring = len(o["records"])

    fig, (axl, axr) = plt.subplots(1, 2, figsize=(10.4, 6.3), dpi=150,
                                   gridspec_kw={"width_ratios": [1.2, 1.0]})
    fig.subplots_adjust(left=0.01, right=0.99, top=0.92, bottom=0.02, wspace=0.02)
    box = dict(boxstyle="round,pad=0.45", facecolor="#eef3fa", edgecolor="#4a6fa5", lw=1.3)
    kw_txt = dict(ha="center", va="center", fontsize=12, color="#111111", bbox=box)
    axl.text(0.5, 0.90, "B₃, order 48\nsigned line-permutations preserving C1–C5", **kw_txt)
    axl.text(0.5, 0.52, "S₄, order 24\nacting faithfully and freely on\ncanonical pair-order records",
             **kw_txt)
    axl.text(0.5, 0.11, "every record's orbit has exactly\n24 records: no record is fixed by\n"
                        "any non-identity element", **kw_txt)
    for y0, y1 in ((0.80, 0.65), (0.39, 0.24)):
        axl.annotate("", xy=(0.5, y1), xytext=(0.5, y0),
                     arrowprops=dict(arrowstyle="-|>", color="#4a6fa5", lw=2.0))
    # Q-900 (Codex VIZ H2-07 / H2-08, 2026-09-28). The quotient step named {±I} without saying what
    # −I is or why a record cannot see it; it is now said: −I turns every hexagram upside down
    # (TR-5 §1: "rev is the central −I"), which maps each C1 pair onto itself, and a record forgets
    # the order within a pair. The theorem step stated R/24 with no premise, and a budgeted slice
    # is not symmetry-closed (the 560T canonical's 10,525,271,997 records are 21 mod 24); it now
    # carries the S₄-closed premise that TR-5 §4 states.
    axl.text(0.54, 0.725, "quotient by {±I}: −I turns each\nhexagram upside down, mapping\n"
                          "every pair onto itself; records\nignore the order within a pair,\n"
                          "so ±I moves no record",
             ha="left", va="center", fontsize=10.5, color="#2c4a73")
    axl.text(0.54, 0.315, "free-action theorem: for an\nS₄-closed set of R records,\n"
                          "record-orbit count = R/24,\nexactly (a budgeted slice\nneed not be S₄-closed)",
             ha="left", va="center", fontsize=10.5, color="#2c4a73")
    axl.set_title("The symmetry collapse", fontsize=13)
    axl.set_xlim(0, 1)
    axl.set_ylim(0, 1)
    axl.axis("off")

    for k in range(n_ring):
        a = math.radians(-360.0 * k / n_ring)          # King Wen at 3 o'clock
        is_kw = k == 0
        axr.plot(math.cos(a), math.sin(a), "o", ms=13 if is_kw else 11,
                 color="#d32f2f" if is_kw else "#b8c9e1",
                 markeredgecolor="#7a1f1f" if is_kw else "#4a6fa5", markeredgewidth=1.2)
    axr.text(1.17, 0.0, "King\nWen", ha="left", va="center", fontsize=12, color="#8b1a1a")
    axr.text(0.0, 0.0, "one orbit:\n24 canonical\npair-order records\n(48 oriented sequences),\n"
                       "alike under every\nS₄-invariant criterion",
             ha="center", va="center", fontsize=11, color="#2c4a73", linespacing=1.25)
    axr.set_title("King Wen's record and its 23 twins", fontsize=13)
    # The y range is chosen so that the equal-aspect box fills the panel (4.6 in x 5.7 in since
    # Q-900 made the figure taller for the longer step notes): the axes then keep their full
    # height, and the two panel titles sit on one line.
    axr.set_xlim(-1.3, 1.62)
    axr.set_ylim(-1.8, 1.8)
    axr.set_aspect("equal")
    axr.axis("off")
    save(fig, "fig_tr5_orbit_collapse",
         "source: solve.py binary_hexagrams + reverse_6bit (the orbit is computed, not drawn "
         "by hand)  theorem: reports/TR5_SYMMETRY.md §1, §4   (viz/report_figures.py)")


# ---------------------------------------------------------------------------
# TR-4 §5 — boundary-information curve S(k) with the band extrapolating to one surviving
# pair-ordering class (NOT to one ordering — see NOTE 2026-09-19 in the function)
# ---------------------------------------------------------------------------
def fig_tr4_boundary_information():
    # Data: TR4_SIZE_OF_THE_SPACE.md §5 (pinned Knuth walks, 2e9 probes/prefix, rel. err <= 10%):
    #   k=1: 7.49e-4 (9.95e34 survivors); k=2: 9.39e-7 (1.25e32);
    #   k=3: 4.27e-10 (5.68e28); k=4: 6.34e-13 (8.42e25).
    # Full-space size 1.3287e38 (TR-4 §3); greedy per-boundary cut ~1e3; weakest-boundary
    # bracket (k=5-8) reported at x15-17 per boundary but ILLUSTRATIVE, not measured — its
    # chain outputs are not archived and it is not reproducible from published material
    # (restated 2026-09-02, TR-4 v1.25); the ~15-20 band (it superseded a ~13-14 estimate) is
    # WITHDRAWN, see NOTE 2026-09-26 at the axvline; what any continuation converges to is one
    # surviving PAIR-ORDERING CLASS, not one ordering — see NOTE 2026-09-19 below. The
    # observed-rate extrapolation is ~12 and is NOT a bound: TR-4 v1.16 removed the "floor"
    # label rather than re-qualifying it, and CLAIMS_DECIDED.md reads "NOT a floor of any kind".
    # The rendered text carried that superseded floor label until 2026-09-19 (Q-658).
    # NOTE 2026-08-01: the former "hard"-floor-of-13 wording was WITHDRAWN (the exact
    # retracted string is deliberately not repeated here — doc_gates.sh GATE 6 scans this
    # file for registered retracted phrasings and cannot distinguish narration from
    # assertion). The divisor 10.38 is only the
    # unconditional maximum gain, and the same data shows 11.10 at step 3, giving 12; and no
    # necessity bound follows from the argument at all (TR-4 v1.15). The old wording was still
    # RENDERED in the committed SVG, where matplotlib had turned it into glyph paths — invisible
    # to the markdown retraction gate. Regenerate the figure after changing this text.
    # NOTE 2026-08-06: the title's parenthetical formerly asserted that 4 boundaries uniquely
    # identify KW in the 560T slice — the claim CORRECTIONS.md CX-06 (2026-07-04) retracted:
    # the 4-count was a survivor-counting error (the count stopped at 1 remaining non-KW
    # survivor, rec#330177707, KW with positions 2-3 pair-swapped); the 560T slice-identifying
    # set has FIVE boundaries, {4, 27, 25, 21, 1}, identical at 100T and 560T. The corrected
    # title matches TR-4 v1.7.1: the first 4 of the 5 (the ones S(k) measures here) still
    # admit ~8.4e25 full-space orderings. The stale wording survived 33 days in the rendered
    # PNG/SVG because it is not a registered string in RETRACTED_PHRASES.tsv, so GATE 6's
    # generator scan had nothing to match. (This comment narrates; it does not restate the
    # retracted claim as fact.)
    # NOTE 2026-09-19 (Q-658; CORRECTIONS.md CX-53/CX-54): the level plotted here was 1/N_total,
    # labelled as the point where a single ordering survives, beneath a band labelled for
    # uniqueness across the whole space. Neither retired string is repeated verbatim here: this
    # row's closure gate greps this file for the old phrasing, and GATE 6 cannot tell narration
    # from assertion — the same reason the 2026-08-01 note above paraphrases rather than quotes. A
    # boundary constraint pins PAIR IDENTITY ONLY — solve.c:7900 (knuth_pin_mask) constrains the pair index chosen
    # at a step and leaves the orientation loop untouched, and SOLVE_KNUTH_PIN_SLOTS accepts steps
    # 1-31 (solve.c:41846) — so pinning is blind to the orientation layer by construction. Pin all
    # 31 and 1,720,320 orderings remain: King Wen's C4-oriented orientation fibre (TR-1 §7, gated
    # by doc_gates.sh GATE 32, recomputed with `python3 verify.py --recount-fiber`). The reachable
    # floor is therefore 1,720,320/N_total = 1.29e-32, and 1/N_total = 7.53e-39 sits
    # log2(1,720,320) = 20.71 bits below it — 1,720,320x lower, and unreachable at any k. The
    # correction landed in SEARCH_SPACE_SIZE.md on 2026-09-07 and in TR-4 on 2026-09-19 but never
    # reached this generator, so the committed PNG/SVG went on asserting the unreachable endpoint
    # in glyph paths no markdown gate can read. Every S(k) value, per-boundary gain and the band
    # position are UNCHANGED; only the endpoint they converge to is renamed. The
    # {4, 27, 25, 21, 1} legend is deliberately untouched (CX-54; GATE 64 checks it).
    # Regenerate the figure after changing this text.
    k = np.array([1, 2, 3, 4])
    S = np.array([7.49e-4, 9.39e-7, 4.27e-10, 6.34e-13])
    survivors = ["9.95×10³⁴", "1.25×10³²", "5.68×10²⁸", "8.42×10²⁵"]
    N_total = 1.3287e38        # raw, ORIENTATION-EXPLICIT C1–C5 population (TR-4 §3)
    FIBER = 1720320            # KW's C4-oriented orientation fibre — survives ALL 31 pair pins
    S_class = FIBER / N_total  # 1.29e-32: the floor pair-level boundaries can actually reach
    S_oriented = 1.0 / N_total # 7.53e-39: one ORIENTED ordering — NOT reachable at any k

    # Q-889 (2026-09-28): 8.2 in tall, not 7. The legend moved below the axes and the y range grew by
    # two decades; at 7 in each decade shrank from ~21 px to ~18 px and the fixed-height ORIENTED
    # block rose into the reachable-floor line. The width, and so the text floor, is unchanged.
    fig, ax = plt.subplots(figsize=(10, 8.2), dpi=150)
    ax.set_yscale("log")

    # measured greedy points
    ax.plot(k, S, "-", color="#1f77b4", lw=1.5, alpha=0.7, zorder=4)
    # Q-889 (2026-09-28): the legend said "measured S(k)". These are pinned-Knuth ESTIMATES with a
    # relative error of at most 10% (TR-4 §5, 2e9 probes per prefix), not counts; it now says so.
    ax.scatter(k, S, s=90, color="#d32f2f", zorder=5,
               label="S(k) estimated (pinned Knuth, ≤10%), greedy 560T identifying order {4, 27, 25, 21, 1}")
    for ki, Si, sv in zip(k, S, survivors):
        ax.annotate(f"S({ki}) = {Si:.2e}\n{sv} survivors", (ki, Si),
                    textcoords="offset points", xytext=(10, 4), fontsize=10)

    # The ~x1e3-per-boundary rate inferred from k = 1-4 (TR-4 §5), drawn ONLY to k = 8.
    # NOTE 2026-09-26 (VIZ1 F17): this line ran to k = 20. Continued, it crossed the reachable
    # floor at k = 10.56 and the oriented level at k = 12.64 and stood at 6.34e-43 at k = 14 --
    # below BOTH, which no S(k) can be. Its rate (9.97 bits per boundary) also contradicts the
    # k = 14 marker's own premise (no later gain above 6.14 bits), and it already underpredicts
    # the reported S(8) about 130-fold. It is kept only as what it is: the early-rate
    # illustration, superseded by the later measured decline.
    k_ext = np.arange(4, 9)
    ax.plot(k_ext, S[-1] * (1e-3) ** (k_ext - 4), "--", color="#1f77b4", lw=1.3, alpha=0.8,
            label="Early-rate illustration from k=1–4; superseded by the later measured decline.")

    # weakest-remaining-boundary bracket: k=5-8 reported at x15-17 per boundary.
    # ILLUSTRATIVE, not measured: the only archived S(k) outputs (reports/evidence/sk/)
    # are greedy chains, so these two literals are the one thing on this figure with no
    # file under reports/evidence/ behind it. Labelled as such since 2026-09-02.
    k_br = np.arange(4, 9)
    ax.fill_between(k_br, S[-1] * (1 / 17.0) ** (k_br - 4), S[-1] * (1 / 15.0) ** (k_br - 4),
                    color="#e8a33d", alpha=0.35,
                    label="weakest-remaining-boundary bracket, ×15–17/boundary (illustrative, k = 5–8)")

    # the REACHABLE floor (one pair-ordering class); the k = 14 marker is drawn below
    ax.axhline(S_class, color="#388e3c", lw=1.3, ls="-.")
    ax.text(0.7, S_class * 3,
            "reachable floor: S = 1,720,320/1.3287×10³⁸ = 1.29×10⁻³² (one surviving pair-ordering class)",
            fontsize=10, color="#2e7d32", va="bottom")
    # the ORIENTED level, drawn to show what no number of pair-level pins reaches
    ax.axhline(S_oriented, color="#9e9e9e", lw=1.1, ls=":")
    # Kept narrow and right-aligned on purpose: a wider block runs under the lower-left legend
    # (measured 2026-09-19 — two earlier placements did, and the rendered text is unreadable to
    # every gate in the tree, so a collision here is only ever caught by looking at the image).
    ax.text(20.3, S_oriented * 1.8,
            "one ORIENTED ordering:\n1/1.3287×10³⁸ = 7.53×10⁻³⁹,\n"
            "20.71 bits lower. Pins fix pair\nidentity, not orientation, so\nno k reaches this level.",
            fontsize=10, color="#616161", ha="right", va="bottom")
    # NOTE 2026-09-26 (Q-827 ruling, implemented as Q-842): the green k = 15-20 band is
    # WITHDRAWN. It was first published on 2026-07-02, three days BEFORE S(6)-S(8) were
    # measured, and TR-4 v1.8 carried it forward without stating a continuation rule. Every rule
    # tried against TR-4's own gains (k = 1..8: 10.38, 9.64, 11.10, 9.40, 10.13, 8.64, 7.93,
    # 6.14; sum 73.36 bits; floor log2(1.3287e38) - log2(1,720,320) = 105.93 bits, oriented
    # level 126.64) puts the FLOOR outside it: last gain held constant -> floor at k = 14
    # (oriented 17, which falls inside the band, but pins never reach that level); the k = 1..8
    # mean (9.17) -> 12 and 14; a least-squares line through k = 5..8 reaches zero gain at
    # k = 13 having added 12.55 bits (reaches neither); a geometric decline at the k = 5..8
    # ratio (x0.846) -> floor at k ~ 28, oriented never. The band is replaced by ONE
    # conditional line at k = 14, labelled as a scale marker: hold every later gain at the 8th's
    # 6.14 bits and the floor is first reached at k = 8 + ceil(32.57 / 6.14) = 14. It is a line,
    # not a band, because the data set no far end (a continued decline: k ~ 28 or never).
    ax.axvline(14, color="#388e3c", lw=1.3, ls="-", alpha=0.8)
    # Q-889 (2026-09-28): re-wrapped to stay inside the axes. At five lines it ran ~30 px past the
    # right spine into the figure margin (the longest line, "not a bound; no far end set by the
    # data.", was wider than k = 14.25..20.5 at 10 pt). Same words, six narrower lines.
    ax.text(14.25, 1e0, "k ≈ 14: the earliest the\npair-ordering floor is\nreached IF no later boundary\n"
                         "gains more than the 8th\nmeasured one (6.14 bits).\n"
                         "A scale marker, not a bound;\nno far end set by the data.",
            fontsize=10, color="#2e7d32", ha="left", va="top")

    ax.set_xlim(0.5, 20.5)
    # Q-889: the top is 1e1, not 1e-1. The S(1) annotation (two lines above its point at 7.49e-4)
    # straddled the top spine at 1e-1; two more decades of headroom clear it. The decade ticks are
    # pinned so the headroom adds no tick, and they are labelled full-size (see _full_size_decades).
    ax.set_ylim(1e-42, 1e1)
    ax.set_yticks([10.0 ** e for e in range(-42, 0, 5)])
    _full_size_decades(ax.yaxis)
    ax.set_xticks(range(1, 21))
    ax.set_xlabel("k = number of King Wen boundary constraints imposed", fontsize=12)
    ax.set_ylabel("S(k) = fraction of the full C1–C5 population (orientation-explicit)\n"
                  "agreeing with KW (log scale)", fontsize=11)
    ax.set_title("The boundary-information curve S(k) — slice-uniqueness vs space-uniqueness\n"
                 "(the first 4 of the 5 boundaries that identify KW in the 560T slice still admit "
                 "≈8.4×10²⁵ full-space orderings)", fontsize=12)
    ax.grid(True, which="both", ls=":", alpha=0.4)
    # Q-863 / Q-889 (2026-09-28): the legend sat at `lower left`, INSIDE the axes, on top of the
    # dotted ORIENTED line (7.53e-39) from k = 0.5 to about k = 8.5, so the level the figure exists
    # to show as unreachable was hidden for its first eight boundaries. It is now below the axes,
    # where it covers nothing.
    ax.legend(fontsize=10, loc="upper center", bbox_to_anchor=(0.5, -0.09), frameon=False)
    ax.set_facecolor("#f8f8f8")
    fig.tight_layout()
    save(fig, "fig_tr4_boundary_information")


# ---------------------------------------------------------------------------
# TR-1 §5 / TR-2 — the conflict theorem's trade-off: KW vs the grand unified precursor
# ---------------------------------------------------------------------------
def fig_tr1_rules_tradeoff():
    # Data: TR1_EIGHT_CENTURIES_MEASURED.md §5 + TR2_THE_RULES_CONFLICT.md abstract.
    # KW: Moore 2005 parity 16/18 (2 misses), Moore 1989 rhythm 2 breaks, Schulz 1990
    # gender 2 violations, Schulz S25-28 trigram configuration (ccn4) satisfied EXACTLY.
    # Grand unified precursor (3 slot-edits from KW): 18/18, 0 breaks, 0 violations —
    # and it breaks the trigram configuration (binary rule; no graded miss count).
    #
    # Q-900 (Codex VIZ H2-01 / H2-02, 2026-09-28): A FOUR-ROW TABLE, NOT A BAR CHART. The bars told
    # King Wen from the precursor by red vs green alone, and every precursor bar had zero length,
    # so the one visible series carried the whole comparison and its identity was a hue: under
    # deuteranopia the two legend swatches measured 1.03:1. The green "0 — perfect" labels were
    # 4.12:1 on white. Named columns carry the identity now; each cell states its count in its own
    # unit; the cell tint repeats the verdict and is never its only carrier. "S25–28" was undefined
    # on the figure: the row now names the stations, and a note says what a station is (TR-2).
    kw = [2, 2, 2]      # numeric misses on the three graded rules
    gp = [0, 0, 0]
    assert kw == [2, 2, 2] and gp == [0, 0, 0], "the cell texts below state these counts"
    ink, ok_bg, miss_bg, head_bg = "#111111", "#e3f1e4", "#fbe3e1", "#e9edf3"
    for bg in (ok_bg, miss_bg, head_bg, "#ffffff"):
        assert _wcag_contrast(ink, bg) >= MIN_TEXT_CONTRAST, "TR-1 table text contrast on %s" % bg
    fig, ax = plt.subplots(figsize=(9.6, 5.6), dpi=150)
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.axis("off")
    X = (0.0, 0.47, 0.735, 1.0)                       # column edges: rule | King Wen | precursor
    Y = (0.93, 0.80, 0.66, 0.55, 0.44, 0.30)          # row edges: header, then the four rules
    tint = [head_bg, head_bg, head_bg] + [miss_bg, ok_bg] * 3 + [ok_bg, miss_bg]
    cells = [(c, r) for r in range(5) for c in range(3) if not (r > 0 and c == 0)]
    for (c, r), bg in zip(cells, tint):
        ax.add_patch(plt.Rectangle((X[c], Y[r + 1]), X[c + 1] - X[c], Y[r] - Y[r + 1],
                                   facecolor=bg, edgecolor="#ffffff", lw=2.0))
    for r in range(1, 5):
        ax.add_patch(plt.Rectangle((X[0], Y[r + 1]), X[1] - X[0], Y[r] - Y[r + 1],
                                   facecolor="#ffffff", edgecolor="#d0d4da", lw=0.8))
    L = dict(ha="left", va="center", fontsize=11, color=ink)
    C = dict(ha="center", va="center", fontsize=12, color=ink)
    ax.text(0.01, (Y[0] + Y[1]) / 2, "rule (author, year)", **L)
    ax.text((X[1] + X[2]) / 2, (Y[0] + Y[1]) / 2, "King Wen\n(received order)", fontweight="bold",
            **dict(C, fontsize=11.5))
    ax.text((X[2] + X[3]) / 2, (Y[0] + Y[1]) / 2, "precursor\n(3 slot-edits from KW)",
            fontweight="bold", **dict(C, fontsize=11.5))
    ax.text(0.01, (Y[1] + Y[2]) / 2, "Moore 2005 — pair-positioning parity\n(18 testable positions)", **L)
    ax.text(0.01, (Y[2] + Y[3]) / 2, "Moore 1989 — rising/falling rhythm", **L)
    ax.text(0.01, (Y[3] + Y[4]) / 2, "Schulz 1990 — gender rule", **L)
    ax.text(0.01, (Y[4] + Y[5]) / 2, "Schulz 2011/2016 — trigram configuration\nof stations 25–28 "
                                     "(binary rule)", **L)
    ax.text((X[1] + X[2]) / 2, (Y[1] + Y[2]) / 2, "2 misses (16/18)", **C)
    ax.text((X[2] + X[3]) / 2, (Y[1] + Y[2]) / 2, "0 misses (18/18)", **C)
    ax.text((X[1] + X[2]) / 2, (Y[2] + Y[3]) / 2, "2 breaks", **C)
    ax.text((X[2] + X[3]) / 2, (Y[2] + Y[3]) / 2, "0 breaks", **C)
    ax.text((X[1] + X[2]) / 2, (Y[3] + Y[4]) / 2, "2 violations", **C)
    ax.text((X[2] + X[3]) / 2, (Y[3] + Y[4]) / 2, "0 violations", **C)
    ax.text((X[1] + X[2]) / 2, (Y[4] + Y[5]) / 2, "satisfied", **C)
    ax.text((X[2] + X[3]) / 2, (Y[4] + Y[5]) / 2, "violated", **C)
    ax.set_title("THE CONFLICT THEOREM's trade-off: the four rules cannot all be satisfied\n"
                 "(jointly UNSAT under C1+C2+C4+C5, drat-trim-verified) — any ordering must choose",
                 fontsize=12)
    # The superlative ("the minimal measured margins") was WITHDRAWN 2026-08-28: f11_runA.out
    # carries `f11_hist 1 1 0` (4.13e-09) and `f11_hist 2 1 1` (2.93e-08), both nonzero and
    # componentwise no worse than KW's `2 2 2`, and that histogram is not CC-N4-conditioned, so
    # no extremal check exists. The prose and captions were corrected then and on 2026-09-01;
    # this rendered string was the last live copy (fixed 2026-09-02, prose batch P73).
    ax.text(0.5, 0.25,
            "KW keeps the trigram configuration exactly and misses the other three by two each\n"
            "(no extremal check excludes a smaller miss); the 3-edit grand precursor perfects\n"
            "those three and breaks the trigram configuration. Both cannot be had.",
            ha="center", va="top", fontsize=10.5, color="#444444")
    ax.text(0.5, 0.115,
            "precursor = the grand unified precursor, 3 slot-edits from King Wen (TR-1 §5).\n"
            "station = one of Lai Zhide's 36 consolidated units, the numbering Schulz's rules use (TR-2).",
            ha="center", va="top", fontsize=10.5, color="#444444")
    save(fig, "fig_tr1_rules_tradeoff")


# ---------------------------------------------------------------------------
# TR-3 — first 560T campaign timeline with the 5 Spot-eviction marks
# ---------------------------------------------------------------------------
def fig_tr3_campaign_timeline():
    # Data: documentation/CAMPAIGN_METHODOLOGY.md 560T campaign record —
    # launch 2026-05-31 17:03 PT; enum wall 171.5 h (incl. eviction-defer windows);
    # per-eviction table (PT): Mon 06-01 07:12:20, Tue 06-02 07:39:00, Wed 06-03 07:33:42,
    # Thu 06-04 07:42:00, Fri 06-05 07:49:32; 0 weekend evictions (Sat 06-06 + Sun 06-07);
    # M-F daytime defer policy resumes at 18:01 PT same day.
    # (The 2026-06-30 re-run's 7 evictions are shown in the run-dir telemetry figure —
    # per-eviction timestamps for it are not in the public docs, so it is not drawn here.)
    launch = datetime(2026, 5, 31, 17, 3)
    enum_end = launch + timedelta(hours=171.5)
    evictions = [
        datetime(2026, 6, 1, 7, 12, 20),
        datetime(2026, 6, 2, 7, 39, 0),
        datetime(2026, 6, 3, 7, 33, 42),
        datetime(2026, 6, 4, 7, 42, 0),
        datetime(2026, 6, 5, 7, 49, 32),
    ]
    resumes = [e.replace(hour=18, minute=1, second=0) for e in evictions]  # defer-to-18:01-PT policy
    # Q-889 / Q-895 (2026-09-28): the weekend note read "~54 h clean Spot runway", an interval that
    # matches nothing plotted (Fri 18:01 -> Mon 00:00, the policy window, is 54.0 h; the run ended
    # inside it). The note now states the plotted interval, asserted from the two datetimes it names.
    runway_h = (enum_end - resumes[-1]).total_seconds() / 3600
    assert f"{runway_h:.1f}" == "50.5", "annotation: 'Fri 18:01 → finish: 50.5 h uninterrupted'"

    # VIZ1 F18 (2026-09-26): 10 in wide, not 13, and no text under 10 pt -- see INLINE_PX.
    fig, ax = plt.subplots(figsize=(10, 3.9), dpi=150)
    # weekend shading (Sat 06-06 00:00 -> Mon 06-08 00:00 PT)
    ax.axvspan(datetime(2026, 6, 6), datetime(2026, 6, 8), color="#bbdefb", alpha=0.5, zorder=0)
    # Below the bar, not above it: the longer note, above the bar, ran into the Fri 07:49 eviction
    # label and the "enum complete" label (Q-889 redraw, 2026-09-28).
    ax.text(datetime(2026, 6, 7, 0, 0), 0.08, "weekend: 0 evictions\n(Fri 18:01 → finish: 50.5 h uninterrupted)",
            ha="center", va="bottom", fontsize=10, color="#1565c0")

    # running / deferred-downtime segments
    y0, hh = 0.55, 0.9
    starts = [launch] + resumes
    stops = evictions + [enum_end]
    for a, b in zip(starts, stops):
        ax.barh(y0 + hh / 2, (b - a).total_seconds() / 86400, left=a, height=hh,
                color="#66bb6a", edgecolor="none", zorder=2)
    for e, r in zip(evictions, resumes):
        ax.barh(y0 + hh / 2, (r - e).total_seconds() / 86400, left=e, height=hh,
                color="#9575cd", edgecolor="none", zorder=2)
        ax.plot(e, y0 + hh + 0.12, marker="v", color="#d32f2f", ms=9, zorder=5)
        ax.text(e, y0 + hh + 0.28, e.strftime("%a\n%H:%M PT"), ha="center", fontsize=10,
                color="#b71c1c")
    ax.plot(launch, y0 + hh / 2, marker=">", color="#1b5e20", ms=10, zorder=5)
    ax.text(launch - timedelta(hours=3), y0 - 0.28, "launch\nSun 17:03 PT", ha="left", fontsize=10,
            color="#1b5e20")
    ax.plot(enum_end, y0 + hh / 2, marker="*", color="#d32f2f", ms=16, zorder=5)
    ax.text(enum_end + timedelta(hours=4), y0 + hh + 0.28, "enum complete\n171.5 h wall", ha="right",
            fontsize=10,
            color="#b71c1c")

    # legend proxies
    from matplotlib.patches import Patch
    from matplotlib.lines import Line2D
    ax.legend(handles=[
        Patch(color="#66bb6a", label="enumerating on Spot D128"),
        Patch(color="#9575cd", label="deferred downtime; resume bars: policy 18:01 PT (reconstructed)"),
        Line2D([], [], marker="v", color="#d32f2f", ls="none", label="Spot eviction"),
        Patch(color="#bbdefb", label="weekend (PT)"),
    ], fontsize=10, loc="upper center", bbox_to_anchor=(0.5, -0.30), ncol=2, frameon=False)

    ax.set_ylim(0, 2.25)
    ax.set_yticks([])
    ax.set_xlim(datetime(2026, 5, 31, 10), datetime(2026, 6, 8, 8))
    ax.xaxis.set_major_locator(mdates.DayLocator())
    ax.xaxis.set_major_formatter(mdates.DateFormatter("%a\n%m-%d"))
    ax.tick_params(axis="x", labelsize=10)
    ax.set_xlabel("2026, Pacific Time", fontsize=10.5)
    ax.set_title("First 560T campaign timeline — 5 Spot evictions, all M-F\n"
                 "in a 37-min window (07:12–07:49 PT), 0 on the weekend", fontsize=12.5)
    ax.grid(True, axis="x", ls=":", alpha=0.4)
    ax.set_facecolor("#f8f8f8")
    fig.tight_layout()
    save(fig, "fig_tr3_campaign_timeline")



# ---------------------------------------------------------------------------
# THE SCALE FIGURE (spec: viz/viz_scale.md) — the three canonicals' record
# counts with N, the exact compiled superspace count, as one horizontal line.
#
# 🔴 THE CAPTION IS THE WHOLE RISK, AND THE SPEC PAGE SAYS SO. This figure puts
# two counts of DIFFERENT SPACES on one axis: the points are record counts over
# node-BUDGETED SLICES of C1–C5, each a LOWER BOUND (SOLUTIONS_FORMAT.md); the
# line is the EXACT |C1∩C2∩C4∩C5| of the C1C2C4C5-SUPERSPACE, which does not
# have C3 among its constraints and does not have C6/C7 either. Putting them on
# one axis is the point of the figure; a caption that says only "solutions"
# invites exactly the conflation it was drawn to prevent. Both space labels go
# in the CAPTION, not in a footnote, and the gap is named as a gap between a
# budgeted slice and a compiled superspace — never as "how much of the space we
# found". viz_scale.md §"The caption MUST carry BOTH space labels".
#
# AXIS CHOICE: the axis runs the FULL ~29 decades, unbroken. The REASONING for
# that choice is NOT repeated here — it belongs to the spec page, which asked
# that the drafter state it "in the page, not in the image", and this comment
# was the one place it had been left instead. See viz_scale.md §"Decided at
# drafting — axis treatment". The `assert` on `decades` below is that decision
# made enforceable; keep the two in sync via the page, not by editing this line.
# ---------------------------------------------------------------------------
SCALE_INPUTS = os.path.join(_REPO_ROOT, "viz", "viz_scale_inputs.tsv")
SCALE_REGISTRY = os.path.join(_REPO_ROOT, "documentation", "CANONICAL_HASHES.md")
SCALE_N_SOURCE = os.path.join(_REPO_ROOT, "reports", "METHODS.md")


def _scale_inputs(path, registry=None, n_source=None):
    """viz/viz_scale_inputs.tsv -> ([(budget, records, label, sha8)] by budget, N)  (Q-890).

    The scale figure's constants used to live in this file as literals, so its footer could name
    documents but no digest of what was plotted. They are now a committed table read through
    _read_tsv (whose digest the footer carries). When `registry` / `n_source` are given, every
    (label, sha prefix, record count) must appear as a Quick-reference row of CANONICAL_HASHES.md,
    every budget as that scale's SOLVE_PER_SUB_BRANCH_LIMIT recipe row, and N's digits in
    METHODS.md: a table that disagrees with the registry it transcribes is refused, not drawn."""
    rows = _read_tsv(path, required=("series", "per_cell_budget", "count", "sha256_prefix", "source"))
    scales, n = [], None
    for r in rows:
        if r["series"] == "N":
            if n is not None:
                raise TsvShapeError(f"{path}: more than one N row")
            n = _tsv_int(r["count"], "N")
            continue
        if not re.fullmatch(r"[0-9a-f]{8}", r["sha256_prefix"]):
            raise TsvShapeError(f"{path}: {r['series']}: sha256_prefix {r['sha256_prefix']!r} "
                                f"is not 8 lowercase hex digits")
        scales.append((_tsv_int(r["per_cell_budget"], "budget"), _tsv_int(r["count"], "count"),
                       r["series"], r["sha256_prefix"]))
    if n is None or len(scales) != 3 or scales != sorted(scales):
        raise TsvShapeError(f"{path}: want three canonical rows in rising budget order and one N "
                            f"row; got {len(scales)} canonical row(s), N {'present' if n else 'absent'}")
    if registry is not None:
        with open(registry, encoding="utf-8") as fh:
            reg = fh.read()
        for b, c, lab, sh in scales:
            if not re.search(rf"^\| (\*\*)?d3 {re.escape(lab)}(\*\*)? \| `{sh}…` \| {c:,} \|", reg, re.M):
                raise TsvShapeError(f"{path}: {lab} `{sh}` {c:,} is not a Quick-reference row of "
                                    f"{os.path.basename(registry)}")
            if not re.search(rf"^\| d3 {re.escape(lab)} \| `[^`]*\bSOLVE_PER_SUB_BRANCH_LIMIT={b}\b",
                             reg, re.M):
                raise TsvShapeError(f"{path}: {lab} budget {b} is not the SOLVE_PER_SUB_BRANCH_LIMIT "
                                    f"of that scale's recipe row in {os.path.basename(registry)}")
    if n_source is not None:
        with open(n_source, encoding="utf-8") as fh:
            if f"{n:,}" not in fh.read():
                raise TsvShapeError(f"{path}: N = {n:,} does not appear in {os.path.basename(n_source)}")
    return scales, n


def fig_viz_scale():
    # x — per-cell node budget (SOLVE_PER_SUB_BRANCH_LIMIT, the only budget the
    #     DFS enforces): documentation/CANONICAL_HASHES.md §"Reproducibility
    #     parameters", the d3 11.2T / 100T / 560T recipe rows.
    # y — canonical record counts + sha prefixes: CANONICAL_HASHES.md registry.
    #     Both renderers use 3,432,399,297 for 100T (CANONICAL_HASHES.md); viz/growth_curve.py
    #     carried the retired …298 until 2026-09-23.
    # N = |C1 ∩ C2 ∩ C4 ∩ C5|, EXACT (two-instrument, mod-24 gated) — from
    # reports/METHODS.md §"Canonical quantities", TR-11 §9, and the n=31 row of
    # documentation/VERIFY.md (`solve --kc-count` against a completed Stage F
    # ladder, 10.3 s); the mod-24 assert below is the reader's one-line check.
    # Q-890 (2026-09-28): all of these are read from viz/viz_scale_inputs.tsv, each asserted against
    # the registry row it transcribes, and the footer carries that table's digest.
    SCALES, N = _scale_inputs(SCALE_INPUTS, SCALE_REGISTRY, SCALE_N_SOURCE)
    assert N % 24 == 0, "TR-5 free-action gate: 24 | N (documentation/VERIFY.md)"

    budgets = np.array([s[0] for s in SCALES], dtype=float)
    records = np.array([s[1] for s in SCALES], dtype=float)
    # Power-law fit over the three measured points — the same arithmetic
    # viz/growth_curve.py publishes (α ≈ 0.67, CANONICAL_HASHES.md §"d3 560T").
    alpha, logk = np.polyfit(np.log(budgets), np.log(records), 1)
    kfit = math.exp(logk)
    assert 0.6 < alpha < 0.75, "published 3-point fit is alpha ~ 0.67"
    # The gap, from the published constants alone: N / (deepest measured slice).
    decades = math.log10(N) - math.log10(SCALES[-1][1])
    assert 28.5 < decades < 29.5, "viz_scale.md: the line sits ~29 decades up"
    # VIZ1 F11/F12 (2026-09-26): the embedded caption now names the two COUNTING UNITS and states
    # the extrapolation's premise. Its numbers are static text, so they are recomputed here from
    # the constants above and asserted, and a changed constant cannot leave the caption behind.
    # Like units: C4 admits at most 31! pair orderings, and each pair ordering's orientation
    # fiber holds 1 to 2^31 sequences, so N holds between N/2^31 and 31! pair orderings
    # (viz/viz_scale.md; SOLUTIONS_FORMAT.md §Deduplication).
    assert f"{decades:.1f}" == "29.0", "caption: 'The plotted ratio is 29.0 decades'"
    like_lo, like_hi = N / 2 ** 31, float(math.factorial(31))
    gap_lo = math.log10(like_lo) - math.log10(SCALES[-1][1])
    gap_hi = math.log10(like_hi) - math.log10(SCALES[-1][1])
    assert (f"{gap_lo:.1f}", f"{gap_hi:.1f}") == ("19.7", "23.9"), "caption: '19.7–23.9 decades'"
    nodes_lo, nodes_hi = (like_lo / kfit) ** (1 / alpha), (like_hi / kfit) ** (1 / alpha)
    assert (f"{nodes_lo:.1e}", f"{nodes_hi:.1e}") == ("6.4e+38", "1.1e+45"), \
        "caption: 'approximately 6.4×10³⁸–1.1×10⁴⁵ nodes per cell'"

    # VIZ1 F18: 10 in wide (was 11.5) so the 10-pt text floor is reachable -- see INLINE_PX.
    fig, ax = plt.subplots(figsize=(10, 9.5), dpi=150)
    ax.set_xscale("log")
    ax.set_yscale("log")

    xs = np.logspace(math.log10(budgets.min() * 0.45), math.log10(budgets.max() * 2.6), 200)
    ax.plot(xs, kfit * xs ** alpha, "-", color="#1f77b4", lw=1.4, alpha=0.75, zorder=3)
    # Q-900 (Codex VIZ H17, 2026-09-28): the three legend entries were 70-90 characters each, so
    # the legend box ran from the left spine to x ~ 538 pt and sat across the gap arrow at the 560T
    # budget (x ~ 483 pt), over the very separation the figure is drawn to show. The entries are now
    # short; what they abbreviated is the three-line note under the plot and the caption.
    ax.scatter(budgets, records, s=110, color="#d32f2f", zorder=6,
               label="budgeted C1–C5 records (each a lower bound)")
    ax.plot([], [], "-", color="#1f77b4", lw=1.4, alpha=0.75,
            label=f"three-run power-law fit (α ≈ {alpha:.2f})")
    for b, r, lab, sh in zip(budgets, records, [s[2] for s in SCALES], [s[3] for s in SCALES]):
        # ABOVE-right, not below. At (13, -30) the label is thrown downward into the x-axis
        # tick labels: measured on the first render, `0c0f687c` crossed the 10^9 tick and
        # `915abf30` was struck through by the axis line. The band between the points and the
        # N line is empty, so upward is free.
        ax.annotate(f"{lab}\n{r:,.0f}\nsha {sh}…", (b, r), textcoords="offset points",
                    xytext=(11, 15), fontsize=10, color="#8b1a1a")

    # N — the one horizontal line this figure adds to the existing growth curve.
    ax.axhline(N, color="#6a1b9a", lw=2.0, zorder=5,
               label="N, exact count of C1C2C4C5-SUPERSPACE")
    # Q-890: the label is generated from N (it was a literal typed beside it).
    ax.text(budgets.min() * 0.5, N * 2.2, f"N = {N:,}   (exact, two-instrument; 24 | N)",
            fontsize=10, color="#4a148c", va="bottom")

    # The gap itself, drawn at the deepest measured budget.
    ax.annotate("", xy=(budgets[-1], N), xytext=(budgets[-1], records[-1]),
                arrowprops=dict(arrowstyle="<->", color="#6a1b9a", lw=1.8, alpha=0.9))
    # Placed at 10^17, below the centre-left legend: at the arithmetic midpoint of the two
    # exponents (~10^24.5) the 10-in canvas put it under the legend (VIZ1 F18 re-layout).
    ax.text(budgets[-1] * 1.25, 1e17,
            f"N / (deepest measured slice)\n= 1.097×10³⁹ / 1.053×10¹⁰\n"
            f"≈ 1.04×10²⁹  ({decades:.1f} decades)",
            fontsize=10.5, color="#4a148c", va="center")

    ax.set_xlim(budgets.min() * 0.4, budgets.max() * 12)
    ax.set_ylim(1e8, 1e42)
    _full_size_decades(ax.xaxis, ax.yaxis)      # Q-889: `1e40`, not a 7-pt superscript
    ax.set_xlabel("per-cell node budget, SOLVE_PER_SUB_BRANCH_LIMIT (log scale)", fontsize=11)
    ax.set_ylabel("count (log scale) — ⚠ the two series COUNT DIFFERENT SPACES, see caption",
                  fontsize=11)
    ax.set_title("The scale figure — a node-BUDGETED SLICE of C1–C5 against the EXACT\n"
                 "compiled C1C2C4C5-SUPERSPACE: three canonical enumerations; N sits ~29 decades\n"
                 "above the deepest, counted in different units (see caption)", fontsize=12.5)
    ax.grid(True, which="both", ls=":", alpha=0.4)
    # 🔴 THIS PLACEMENT WAS WRONG THREE TIMES, SO THE REASONING IS RECORDED, NOT THE ANSWER.
    # `upper left` sat on the N annotation at (budgets.min()*0.5, N*2.2) — on the 40-digit
    # exact N. `lower right` struck through the 100T point's sha label. `lower left` then
    # covered the 11.2T label. All three failed for ONE structural reason: every datum in this
    # figure lives in a thin band at the BOTTOM (records ~1e8..1e10) or in a single line at the
    # TOP (N ~1e39), and the point annotations follow the points. Any corner is therefore
    # occupied. The empty region is the MIDDLE-LEFT — ~29 decades of blank between the two
    # series, which is the very gap this figure exists to show.
    ax.legend(fontsize=10, loc="center left")
    ax.set_facecolor("#f8f8f8")

    # Q-900 (Codex VIZ H17): this note was 15 lines and 187 words, a second copy of the external
    # caption set in the image. It is cut to the three things a reader needs at the plot -- what a
    # point counts, what the line counts, and the gap in both units. The derivation and the
    # conditional extrapolation (6.4×10³⁸–1.1×10⁴⁵ nodes per cell, asserted above) stay in the
    # caption (TR-12 §"What this document is", README), where there is room to state the premise.
    fig.text(0.02, -0.025,
             "POINTS — budgeted C1–C5 slices: canonical pair orderings, orientation masked; each count is a LOWER BOUND.\n"
             "LINE — N = |C1∩C2∩C4∩C5|, exact, in orientation-explicit sequences: C1C2C4C5-SUPERSPACE; C3 not imposed.\n"
             "UNITS — The plotted ratio is 29.0 decades; comparing pair orderings with pair orderings gives 19.7–23.9 decades.",
             ha="left", va="top", fontsize=10, color="#333333")

    fig.tight_layout()
    save(fig, "viz_scale",
         _prov(SCALE_INPUTS) + "  rows asserted against: documentation/CANONICAL_HASHES.md  "
         "reports/METHODS.md §Canonical quantities (N)  spec: viz/viz_scale.md")


# ---------------------------------------------------------------------------
# N-1 — THE OBJECT (spec: viz/archive/viz_narrative.md §"Figure N-1"), narrative §1.
#
# Job: show what a King Wen ordering IS, before any claim is made about it —
# 64 hexagrams, 32 pairs, the pairing rule visible, the sequence running
# through them.
#
# 🔴 THE SPEC'S STATED FAILURE MODE: "it must be drawn from the actual King Wen
# sequence, not a schematic. The pairing is the content; a stylised diagram that
# gets the pairing approximately right is worse than no figure, because it looks
# authoritative." So every glyph here is rendered from solve.py's
# `binary_hexagrams` (the repo's single source of truth for the sequence) and
# every pair's TYPE is derived with solve.py's own `reverse_6bit` — no pairing
# is hand-written here, and the 28/4 split is ASSERTED, not annotated. If the
# sequence or the rule moved, this figure would fail rather than mislead.
# ---------------------------------------------------------------------------
def fig_viz_narrative_n1_object():
    # Bit convention (solve.py:32, restated verify.py): bit 0 = bottom line,
    # bit 5 = top; 1 = solid (yang), 0 = broken (yin). Source OEIS A102241.
    seq = list(binary_hexagrams)
    assert len(seq) == 64 and sorted(seq) == list(range(64)), \
        "the sequence must be a permutation of all 64 hexagrams"

    # C1 (documentation/SPECIFICATION.md §C1): s_{i+1} = partner(s_i), where
    # partner is the reversal, or the complement for the 8 reversal-symmetric
    # hexagrams (the 6-bit palindromes). Derived, never tabulated by hand.
    def partner(h):
        r = reverse_6bit(h)
        return r if r != h else h ^ 0b111111
    pairs = [(seq[2 * i], seq[2 * i + 1]) for i in range(32)]
    kinds = []
    for a, b in pairs:
        assert b == partner(a), "C1 pairing must hold on the received sequence"
        kinds.append("reversal" if reverse_6bit(a) != a else "complement")
    assert kinds.count("reversal") == 28 and kinds.count("complement") == 4, \
        "the received sequence pairs 28 by reversal and 4 by complement"

    C_REV, C_COMP, C_INK = "#1f77b4", "#d32f2f", "#222222"
    W, LT, LP = 1.0, 0.085, 0.155        # glyph width, line thickness, line pitch
    DX, PX, PY = 1.25, 2.95, 2.25        # within-pair offset, pair pitch, row pitch
    PER_ROW = 4                          # VIZ1 F18: 4 pairs a row at 10 in (was 8 at 16.5 in)
    GH = 6 * LP                          # glyph height

    # VIZ1 F18 (2026-09-26): 10 in wide (was 16.5) and no text under 10 pt -- see INLINE_PX.
    fig, ax = plt.subplots(figsize=(10, 14), dpi=150)

    def hexagram(x0, y0, v):
        for L in range(6):                       # L = 0 is the BOTTOM line
            y = y0 + L * LP
            if (v >> L) & 1:
                ax.add_patch(plt.Rectangle((x0, y), W, LT, facecolor=C_INK, lw=0))
            else:
                ax.add_patch(plt.Rectangle((x0, y), 0.42 * W, LT, facecolor=C_INK, lw=0))
                ax.add_patch(plt.Rectangle((x0 + 0.58 * W, y), 0.42 * W, LT,
                                           facecolor=C_INK, lw=0))

    centers = []
    for p, ((a, b), kind) in enumerate(zip(pairs, kinds)):
        r, c = p // PER_ROW, p % PER_ROW
        x0, y0 = c * PX, -r * PY
        col = C_REV if kind == "reversal" else C_COMP
        ax.add_patch(plt.Rectangle((x0 - 0.16, y0 - 0.5), DX + W + 0.32, GH + 0.94,
                                   fill=False, edgecolor=col, lw=1.5))
        hexagram(x0, y0, a)
        hexagram(x0 + DX, y0, b)
        ax.text(x0 + W / 2, y0 - 0.34, str(2 * p + 1), ha="center", fontsize=10, color="#444444")
        ax.text(x0 + DX + W / 2, y0 - 0.34, str(2 * p + 2), ha="center", fontsize=10,
                color="#444444")
        ax.text(x0 + (DX + W) / 2, y0 + GH + 0.56, f"pair {p + 1}", ha="center", fontsize=10,
                color=col)
        centers.append((x0 + (DX + W) / 2, y0 + GH / 2, r))

    # The sequence thread: positions 1 -> 64 run through the pairs in order.
    for i in range(31):
        (x1, y1, r1), (x2, y2, r2) = centers[i], centers[i + 1]
        if r1 == r2:
            ax.annotate("", xy=(x2 - 1.28, y2), xytext=(x1 + 1.28, y1),
                        arrowprops=dict(arrowstyle="->", color="#9e9e9e", lw=1.1))
        else:
            ax.plot([x1 + 1.28, x1 + 1.95, x1 + 1.95], [y1, y1, y1 - PY + 0.35],
                    color="#9e9e9e", lw=1.1, ls=":")
            ax.plot([x1 + 1.95, -1.05, -1.05], [y1 - PY + 0.35, y1 - PY + 0.35, y2],
                    color="#9e9e9e", lw=1.1, ls=":")
            ax.annotate("", xy=(x2 - 1.28, y2), xytext=(-1.05, y2),
                        arrowprops=dict(arrowstyle="->", color="#9e9e9e", lw=1.1))

    from matplotlib.lines import Line2D
    leg = ax.legend(handles=[
        Line2D([], [], color=C_REV, lw=1.5, label="pair joined by REVERSAL — the second hexagram "
                                                  "is the first turned upside down (28 pairs)"),
        Line2D([], [], color=C_COMP, lw=1.5, label="pair joined by COMPLEMENT — used where a "
                                                   "hexagram is its own reversal (4 pairs)"),
        Line2D([], [], color="#9e9e9e", lw=1.1, label="sequence order: positions 1 → 64"),
    ], fontsize=10.5, loc="upper center", bbox_to_anchor=(0.5, -0.005), ncol=1, frameon=False)

    ax.set_xlim(-1.9, (PER_ROW - 1) * PX + DX + W + 0.6)
    ax.set_ylim(-(32 // PER_ROW - 1) * PY - 1.55, GH + 1.35)
    ax.set_aspect("equal")
    ax.axis("off")
    ax.set_title("N-1 — the object: the received King Wen ordering of the 64 hexagrams,\n"
                 "as its 32 consecutive pairs, drawn from the sequence itself\n"
                 "(solve.py `binary_hexagrams`), not from a schematic", fontsize=13)

    # Anchored to the legend's bottom edge, so the caption follows the legend wherever the
    # equal-aspect axes leave it (VIZ1 F18 re-layout at 10 in).
    ax.annotate(
             "WHAT THIS IS — the received King Wen ordering. Each cell is one pair; the numbers beneath the two\n"
             "hexagrams are their sequence positions, so pair p occupies positions 2p−1 and 2p, and the grey\n"
             "thread runs 1 → 64 through the pairs in order. Lines are read bottom-to-top: a full bar is a solid\n"
             "(yang) line, a split bar a broken (yin) line.\n"
             "THE PAIRING RULE (C1, documentation/SPECIFICATION.md) — the second hexagram of a pair is the first\n"
             "REVERSED (turned upside down); where a hexagram is its own reversal, its partner is the line-by-line\n"
             "COMPLEMENT instead. Both the split (28 reversal, 4 complement) and every individual pairing on this\n"
             "figure are derived from the sequence by the generator and asserted, not annotated by hand.\n"
             "THE RULE IS CLASSICAL AND NOT A RESULT OF THIS PROJECT — it is stated explicitly by Kong Yingda\n"
             "(574–648) and has an earlier lineage. The classical formulation is quoted, in Chinese, in\n"
             "documentation/KING_WEN_PROVENANCE.md and SPECIFICATION.md; it is not reproduced in this figure only\n"
             "because the stock matplotlib font carries no CJK glyphs and would render it as empty boxes.\n"
             "This figure makes no claim about the ordering. It is the object that every later claim in the\n"
             "narrative is a claim about.",
             xy=(0.5, 0.0), xycoords=leg, xytext=(0, -8), textcoords="offset points",
             ha="center", va="top", fontsize=10, color="#333333")

    fig.tight_layout(rect=(0, 0.06, 1, 1))
    save(fig, "viz_narrative_n1_object",
         "source: solve.py binary_hexagrams (King Wen sequence, OEIS A102241)  "
         "pairing rule: documentation/SPECIFICATION.md §C1  "
         "spec: viz/archive/viz_narrative.md §N-1   (viz/report_figures.py)")


# ===========================================================================
# TR-12 — the V-family figures (V1..V5)
#
# TSV in, figure out.  These functions read the evidence tables written by
#   python3 solve.py --atlas-queries ATLAS.json --atlas-out DIR
# (the atlas consumer) and do NOTHING else: no re-derivation, no filtering,
# no arithmetic beyond the axis transforms matplotlib needs.  Every analytic
# quantity — masses, probabilities, the King Wen overlay columns — is
# computed in solve.py and gated there (`--atlas-selftest`, ATLAS_CONSUMER).
# Column names and order are pinned by viz/viz_kc_*.md.
#
# The mass columns are 192-bit decimal strings and are deliberately NOT read
# here; the float `p` / `p_cond` / `share` columns exist for the axes.
# ===========================================================================

class TsvShapeError(Exception):
    """A source TSV is not the shape its own spec says it is.

    Q-307.  Three distinct old behaviours, and the FIRST is the one that matters:

      - A table that lost whole rows -- the ordinary shape of a truncated write --
        was not detectably wrong at all.  Every row it kept was well formed, so
        `_read_tsv` returned happily and the generator drew a perfectly plausible
        figure over a smaller grid.  No error, no clue, and the output LOOKS like
        evidence.  That is the worst failure mode a figure generator has, and it
        is what `_check_grid` now refuses.
      - A row with EXTRA tabs was silently truncated to the header's width, because
        the reader was `dict(zip(head, fields))` and zip() stops at the shorter
        argument.  Silent, and wrong.
      - A row torn mid-write did raise -- but as a `KeyError` from deep inside the
        plotting code, hundreds of lines from the cause and naming a column rather
        than a file.  Loud, but pointing at the wrong place.

    All three are now one named error that names the file, the line and the reason."""


# Q-890 (2026-09-28): sha256 of the bytes each reader PARSED, keyed by absolute path, for _prov().
# The footer used to hash a SECOND open of the file, so a table replaced between the parse and the
# stamp would put the new file's digest under a figure drawn from the old one. The readers now take
# the bytes once, parse them and record their digest here; _prov() consumes (pops) that digest, and
# hashes the file itself only for a path no reader has parsed since its last stamp.
_SOURCE_SHA256 = {}


def _read_tsv(path, required=()):
    """Tab-separated reader -> list of dicts.  No type coercion, but STRICT shape.

    Raises TsvShapeError on: an empty file, a missing header, a duplicated header
    column, any data row whose field count differs from the header's, a blank or
    whitespace-only row (Q-894), or a missing `required` column.  `required` is the column list the format's own
    spec document (viz/viz_kc_*.md) states -- structure, not analysis.

    The file is read ONCE, as bytes; the rows are parsed from those bytes (decoded exactly as
    `open(path)` decodes) and their sha256 is recorded for the footer (Q-890)."""
    import hashlib
    import io
    with open(path, "rb") as raw:
        data = raw.read()
    with io.TextIOWrapper(io.BytesIO(data)) as fh:
        first = fh.readline()
        if not first:
            raise TsvShapeError(f"{path}: file is empty -- 0 bytes, no header")
        head = first.rstrip("\n").split("\t")
        if len(set(head)) != len(head):
            dup = sorted({c for c in head if head.count(c) > 1})
            raise TsvShapeError(f"{path}: header repeats column(s) {dup}")
        missing = [c for c in required if c not in head]
        if missing:
            raise TsvShapeError(f"{path}: header is missing required column(s) "
                                f"{missing}; header = {head}")
        rows = []
        for lineno, line in enumerate(fh, start=2):
            if not line.strip():
                # Q-894 (2026-09-28): this was `continue`, so a row of bare tabs or spaces -- a
                # torn write, not a table row -- was never counted against the header's width.
                raise TsvShapeError(f"{path}:{lineno}: a blank or whitespace-only row inside the "
                                    f"table -- every line after the header must be a data row")
            f = line.rstrip("\n").split("\t")
            if len(f) != len(head):
                raise TsvShapeError(
                    f"{path}:{lineno}: {len(f)} field(s) against a {len(head)}-column "
                    f"header -- the table is torn or mis-delimited, not merely short")
            rows.append(dict(zip(head, f)))
    if not rows:
        raise TsvShapeError(f"{path}: header only, 0 data rows")
    _SOURCE_SHA256[os.path.abspath(path)] = hashlib.sha256(data).hexdigest()
    return rows


def _check_grid(rows, cols, path):
    """Assert the tidy table is a COMPLETE, DUPLICATE-FREE grid over `cols`.

    Q-307's first fix.  Derived from the TSV's own index ranges -- nothing here
    knows 992 or 155 or 31, and nothing here is told what full-31 looks like, so
    the check works unchanged at every rung.  Three properties, each of which a
    truncated or double-appended table violates:

      (a) every index column parses as an integer;
      (b) the observed index tuples are EXACTLY the cartesian product of the
          per-column value sets -- so a table that lost rows from the middle, or
          lost the tail of its last layer, is caught, and a duplicate row is
          caught in the same test (product size == row count);
      (c) each index column's values form a CONTIGUOUS integer run -- so a table
          truncated at a clean layer boundary, which is still rectangular, is
          caught by the hole it leaves in `k`.

    (c) does not catch a truncation that removes the HIGHEST layers and nothing
    else; that is stated here rather than papered over, and is why the footer in
    save() carries the source sha256 -- the two together say what the figure was
    made from even when the shape alone cannot.  Q-892 (2026-09-28): the callers now also
    check the spec's own inventory on top of this -- see _expect_inventory below."""
    import itertools
    vals = {}
    for c in cols:
        v = []
        for r in rows:
            try:
                v.append(_tsv_int(r[c], "column %r" % c))   # strict: no "+5", " 5", "1_0", "05"
            except (KeyError, ValueError):
                raise TsvShapeError(f"{path}: column {c!r} is not an integer index "
                                    f"in every row (offending value {r.get(c)!r})")
        vals[c] = v
    seen = list(zip(*[vals[c] for c in cols]))
    sets = [sorted(set(vals[c])) for c in cols]
    want = 1
    for sv in sets:
        want *= len(sv)
    if len(seen) != want or len(set(seen)) != len(seen):
        dup = len(seen) - len(set(seen))
        raise TsvShapeError(
            f"{path}: {len(seen)} row(s) over index {cols} whose observed ranges "
            f"{[f'{c}:{sets[i][0]}..{sets[i][-1]}({len(sets[i])})' for i, c in enumerate(cols)]} "
            f"require exactly {want}"
            + (f"; {dup} duplicate index tuple(s)" if dup else "")
            + " -- the table is incomplete (truncated write?) or double-appended")
    if set(seen) != set(itertools.product(*sets)):
        raise TsvShapeError(f"{path}: index {cols} is not a complete grid over its "
                            f"own observed ranges -- {want - len(set(seen))} cell(s) absent")
    for i, c in enumerate(cols):
        sv = sets[i]
        if sv != list(range(sv[0], sv[0] + len(sv))):
            hole = sorted(set(range(sv[0], sv[-1] + 1)) - set(sv))
            raise TsvShapeError(f"{path}: index column {c!r} is not contiguous -- "
                                f"missing {hole[:8]}{'...' if len(hole) > 8 else ''}")
    return sets


# Q-892 / Q-894 (2026-09-28). _check_grid infers every dimension from the rows it is checking, so a
# table that lost a WHOLE endpoint layer, a whole pair row or a whole class is still a complete grid
# over what is left, and rendered (its docstring admits the highest-layer case). The inventories
# below are the ones the spec pages state, checked against the rows on top of _check_grid:
#   layers  k = 0..n-1           (viz_kc_field/river/grammar.md: "k | int, 0...30" at n = 31)
#   pairs   0..31 at EVERY n     (viz_kc_field.md: "global pair index", "32 rows"; measured on the
#                                 n = 9 battery's v1_field.tsv: all 32 pair rows, 9 layers)
#   classes d in {1,2,3,4,6}, w in {2,4,6} (or the reduced form w = -1), the full d x w product
#   V4      steps 1..n, and the walk is complete: its last g is 1
# n is the universe size. tr12_figures() knows it (the Q3 sidecar's atlas_n, else the Q3 table's
# own step count, which V4 checks ends at g = 1) and passes it; a renderer called without n still
# requires the lowest layer (k starts at 0) and every other inventory above, and only the highest
# layer then rests on the footer digest, as before.
# _V_SCHEMA is each table's column list as its spec page states it (Q-894: the callers used to
# require subsets -- V1 rendered without `slot` and `mass`, V3 without `walk`).
_V_SCHEMA = {
    "V1": ("k", "slot", "pair", "mass", "p", "kw"),
    "V2": ("k", "d", "mass", "p", "kw_d"),
    "V2b": ("branch", "pair", "entry", "exit", "d", "solutions", "share", "prefixes_t_units",
            "t_source", "kw"),
    "V3": ("i", "rank", "x", "order", "walk"),
    "V4": ("step", "pair", "entry", "exit", "orient", "alts", "mass_below", "f", "g", "g_parent",
           "p_num", "p_den", "p", "bits"),
    "V5": ("k", "d", "w", "mass", "p_cond", "kw_d", "kw_w"),
}
_V_PAIRS = tuple(range(32))
_V_D = (1, 2, 3, 4, 6)
_V_W = (2, 4, 6)
# The four KW-anchored V3 observables: solve.py --v3-spectrum writes no kw_* column for them because
# each measures similarity TO King Wen (its _KW_TAUTOLOGICAL; viz_kc_spectrum.md). Q-893.
_V3_KW_ANCHORED = ("edit_dist_kw", "first_position_deviation", "shift_conformant_count", "c6_c7_count")
# Q-899 (Codex VIZ H09, 2026-09-28): V3's panels were titled with SCHEMA names (`c3_total`,
# `fft_dominant_freq`, ...), which name a column and define nothing. Each panel is now titled with a
# display label (first line) over its schema name (second line, so the key and the spec still
# resolve), and the figure's key panel defines every one it draws. Definitions: solve.py
# _p2_compute_all_stats, the function that computes these columns. A column not listed here keeps
# its schema name as its title and gets no definition line.
_V3_DISPLAY = {
    "edit_dist_kw": ("pair slots differing from King Wen",
                     "pair slots differing: pair slots (of 32) not holding King Wen's pair"),
    "c3_total": ("complement separation (positions)",
                 "complement separation: Σ over the 64 hexagrams of |pos(h) − pos(complement h)|"),
    "c6_c7_count": ("C6/C7 blocks kept (0–2)",
                    "C6/C7 blocks kept: King Wen's pairs kept in slots 25–26 (C7), 27–28 (C6)"),
    "fft_dominant_freq": ("dominant DFT frequency",
                          "DFT: of the 64 six-bit hexagram codes, mean removed; cycles per 64 positions"),
    "fft_peak_amplitude": ("peak DFT magnitude",
                           "peak DFT magnitude: unnormalised |DFT| at the dominant frequency"),
    "shift_conformant_count": ("shift-rule matches (of 17)",
                               "shift rule: slot s (3…19) holds King Wen's pair for slot s or s − 1"),
    "first_position_deviation": ("first slot differing from KW",
                                 "first slot differing: first pair slot (1-based) not King Wen's; 33 = none"),
    "mean_transition_hamming": ("mean lines changed per step",
                                "mean lines changed: mean Hamming distance over the 63 transitions"),
    "max_transition_hamming": ("most lines changed in a step",
                               "most lines changed: largest Hamming distance among the 63 transitions"),
    "position_2_pair": ("pair in slot 2", "pair in slot 2: the pair index (0–31) placed in pair slot 2"),
}


def _expect_inventory(path, col, got, want, why):
    """Refuse (TsvShapeError) unless the observed value list `got` of index column `col` is exactly
    `want`, the inventory the spec states (Q-892). Names what is missing and what is unexpected."""
    got, want = list(got), list(want)
    if got != want:
        miss = sorted(set(want) - set(got))
        extra = sorted(set(got) - set(want))
        raise TsvShapeError(f"{path}: column {col!r} is not the expected inventory ({why}) -- "
                            f"missing {miss[:8]}{'...' if len(miss) > 8 else ''}, "
                            f"unexpected {extra[:8]}{'...' if len(extra) > 8 else ''}")


def _expect_layers(path, ks, n):
    """k = 0..n-1 when the universe size n is known, else k must at least start at 0 (Q-892)."""
    if n is None:
        _expect_inventory(path, "k", ks, range(len(ks)), "layers start at k = 0")
    else:
        _expect_inventory(path, "k", ks, range(n), "layers k = 0..n-1 at n = %d" % n)


# Tolerances for _expect_probabilities (lane VR4, Codex VIZ A4-04). Measured on the committed n=31 tables: the largest
# |p - mass/sum(mass)| is 5.6e-17 (V2), and the largest |sum_k p - 1| is 4.4e-16 (V1).
_P_CELL_TOL = 1e-12
_P_SUM_TOL = 1e-9


def _expect_probabilities(path, rows, pcol):
    """Refuse (TsvShapeError) a probability column that is not a probability (lane VR4, Codex VIZ A4-04).

    `pcol` is the column drawn (V1 `p`, V2 `p`, V5 `p_cond`); `mass` is the exact integer beside it.
    In order, each a named refusal: every cell of `pcol` parses as a FINITE number (float() reads
    "nan" and "inf") in [0, 1]; every mass is >= 0 and each layer's mass total is > 0; every layer's
    `pcol` sums to 1 within _P_SUM_TOL (the column sums the colour-bar label promises); and each cell
    equals mass / (its layer's mass total) within _P_CELL_TOL, which binds the drawn number to the
    exact count printed beside it -- a swap of two cells inside one layer keeps the sum and fails here.
    These checks are domain checks on the table as written, not a recomputation of the atlas."""
    from fractions import Fraction
    tot, psum = {}, {}
    for r in rows:
        k = _tsv_cell_int(r, "k")
        try:
            p = float(r[pcol])
        except ValueError:
            raise TsvShapeError(f"{path}: k={k}: {pcol} = {r[pcol]!r} is not a number")
        if not math.isfinite(p):
            raise TsvShapeError(f"{path}: k={k}: {pcol} = {r[pcol]!r} is not finite")
        if not 0.0 <= p <= 1.0:
            raise TsvShapeError(f"{path}: k={k}: {pcol} = {r[pcol]!r} is outside [0, 1]")
        m = _tsv_cell_int(r, "mass")
        if m < 0:
            raise TsvShapeError(f"{path}: k={k}: mass = {m} is negative")
        tot[k] = tot.get(k, 0) + m
        psum[k] = psum.get(k, 0.0) + p
    for k in sorted(tot):
        if tot[k] <= 0:
            raise TsvShapeError(f"{path}: k={k}: the layer's mass total is {tot[k]}, not positive")
        if abs(psum[k] - 1.0) > _P_SUM_TOL:
            raise TsvShapeError(f"{path}: k={k}: {pcol} column sums to {psum[k]!r}, not 1 "
                                f"(tolerance {_P_SUM_TOL})")
    for r in rows:
        k = _tsv_cell_int(r, "k")
        want = float(Fraction(_tsv_cell_int(r, "mass"), tot[k]))
        if abs(float(r[pcol]) - want) > _P_CELL_TOL:
            raise TsvShapeError(f"{path}: k={k}: {pcol} = {r[pcol]} but mass / layer total = {want!r} "
                                f"(tolerance {_P_CELL_TOL}) -- the drawn value is not its own count's share")


def _prov(*paths):
    """Provenance string for the figure margin: basename@sha256[:12] per source.

    No timestamp, no hostname, no absolute path -- see save().  A source that is
    absent renders as `<name>@ABSENT`, which is information rather than a crash,
    because an optional panel legitimately may not be there.

    Q-890 (2026-09-28): the digest is the one the reader recorded for the bytes it PARSED
    (_SOURCE_SHA256, consumed here), not a hash of a second read of the file."""
    import hashlib
    out = []
    for p in paths:
        if p is None:
            continue
        b = os.path.basename(p)
        h = _SOURCE_SHA256.pop(os.path.abspath(p), None)
        if h is None and not os.path.exists(p):
            out.append(f"{b}@ABSENT")
            continue
        if h is None:
            with open(p, "rb") as fh:
                h = hashlib.sha256(fh.read()).hexdigest()
        out.append(f"{b}@{h[:12]}")
    return "source: " + "  ".join(out) + "   (viz/report_figures.py)"


def _log10_bigint(s):
    """log10 of an exact decimal-integer STRING, for a log axis.

    192-bit integers are not exactly representable in float64 (Q-890: this said they
    "overflow" it; 2**192 is ~6.3e57, well inside float64's range -- the issue is precision),
    so the exponent comes from the digit count and only the leading digits are floated.  Axis placement
    only -- the exact value is the TSV column, never this.
    """
    s = str(_tsv_cell_int({"count": s}, "count"))   # was s.strip(): " 5", "+5", "05" refused
    head = s[:15]
    return (len(s) - 1) + math.log10(float(head) / 10 ** (len(head) - 1))


def _missing(path, what, how="python3 solve.py --atlas-queries ATLAS.json --atlas-out DIR"):
    print(f"SKIP {what}: {path} not found (produce it with `{how}`)")
    return False


def _shape_guarded(label):
    """Turn a TsvShapeError into a LOUD refusal instead of a plausible figure.

    Q-307.  The defect this closes is not that the reader crashed -- it is that
    it did not.  A generator that renders whatever it was given cannot tell a
    reader that the table was short, so the refusal has to be the visible event:
    the figure is NOT written, `FIGURE_SHAPE=FAIL` names the file and the reason,
    and the caller gets False.  Distinct from the `SKIP` path, which means the
    TSV is absent and is a legitimate state."""
    def deco(fn):
        def wrapped(*a, **kw):
            try:
                return fn(*a, **kw)
            except TsvShapeError as e:
                print(f"FIGURE_SHAPE=FAIL {label}: {e}")
                return False
        wrapped.__name__ = fn.__name__
        wrapped.__doc__ = fn.__doc__
        return wrapped
    return deco


# --- V1 -- the positional-marginal field (viz/viz_kc_field.md) -------------
@_shape_guarded("V1 field")
def fig_tr12_kc_field(tsv, n=None):
    if not os.path.exists(tsv):
        return _missing(tsv, "V1 field")
    # required columns and the (k, pair) grid are viz/viz_kc_field.md's own spec
    rows = _read_tsv(tsv, required=_V_SCHEMA["V1"])
    ks, ps = _check_grid(rows, ("k", "pair"), tsv)
    _expect_layers(tsv, ks, n)                                                  # Q-892
    _expect_inventory(tsv, "pair", ps, _V_PAIRS, "the 32 global pair indices, at every n")
    _expect_probabilities(tsv, rows, "p")                                       # lane VR4 (A4-04)
    bad_kw = [r["kw"] for r in rows if r["kw"] not in ("0", "1")]
    if bad_kw:
        raise TsvShapeError(f"{tsv}: kw = {bad_kw[0]!r} is not 0 or 1")
    M = np.zeros((len(ps), len(ks)))
    mass = {}
    kw = []
    for r in rows:
        i, j = ps.index(_tsv_cell_int(r, "pair")), ks.index(_tsv_cell_int(r, "k"))
        M[i, j] = float(r["p"])
        mass[(i, j)] = _tsv_cell_int(r, "mass")
        if r["kw"] == "1":
            kw.append((i, j))
    # Q-899 (Codex VIZ H04, 2026-09-28): THE ROWS REPEAT BY SYMMETRY, AND THE FIGURE NOW SAYS SO.
    # SUPER is closed under the order-24 group, so two pairs in one orbit have EQUAL rows at every
    # slot (viz_kc_field.md, "SEVEN distinct non-pinned rows"). Counted here from the exact integer
    # masses, not from the rounded p: the 31 free pairs of the full n = 31 field fall into seven
    # distinct profiles and pair 0's row is zero. The seven-profile sentence is drawn only when the
    # table shows exactly that; any other table (a reduced n, say) gets the general sentence.
    prof = {tuple(mass.get((i, j), 0) for j in range(len(ks))) for i in range(1, len(ps))}
    zero_rows = [ps[i] for i in range(len(ps)) if not any(mass.get((i, j), 0) for j in range(len(ks)))]
    seven = len(ks) == 31 and zero_rows == [0] and len(prof) == 7
    # VIZ1 F18 (2026-09-26): 10 in wide (was 13) and no text under 10 pt -- see INLINE_PX.
    fig, ax = plt.subplots(figsize=(10, 9.2), dpi=150)
    im = ax.imshow(M, aspect="auto", origin="lower", cmap="magma",
                   interpolation="nearest")
    # Q-899 (Codex VIZ H05): the cyan outline measured 1.9:1 on the brightest magma cell. It is now
    # drawn over a wider black under-stroke, so on ANY cell one of the two contrasts by at least
    # _two_tone_floor(cyan, black) = 3.2:1 (WCAG's 3:1 for a graphical mark); the key is the same
    # two-tone stroke.
    KW_FG, KW_UNDER = "#4fc3f7", "#000000"
    assert _two_tone_floor(KW_FG, KW_UNDER) >= MIN_MARK_CONTRAST, "V1 King Wen outline contrast"
    for i, j in kw:          # every under-stroke first, so no cell's black
        ax.add_patch(plt.Rectangle((j - 0.5, i - 0.5), 1, 1, fill=False,    # covers a neighbour's core
                                   edgecolor=KW_UNDER, lw=3.6))
    for i, j in kw:
        ax.add_patch(plt.Rectangle((j - 0.5, i - 0.5), 1, 1, fill=False,
                                   edgecolor=KW_FG, lw=1.6))
    # The overlay is named in a LEGEND as well as the subtitle. The subtitle carries the
    # caveat (diagonal by construction); the legend carries the key, and a reader who scans
    # figures before prose needs the key. Placed BELOW the axes on purpose: this is a dense
    # heat matrix and an in-axes legend would cover cells that are themselves the result.
    if kw:
        from matplotlib.lines import Line2D
        from matplotlib.legend_handler import HandlerTuple
        ax.legend(handles=[(Line2D([], [], color=KW_UNDER, lw=3.6), Line2D([], [], color=KW_FG, lw=1.6))],
                  labels=["King Wen's own placement: pair j in slot j+1 (one cell per slot)"],
                  handler_map={tuple: HandlerTuple(ndivide=1)},
                  fontsize=10.5, loc="upper center", bbox_to_anchor=(0.5, -0.085),
                  frameon=False)
    if seven:
        ax.text(0.5, -0.155, "The 31 free pairs share SEVEN distinct rows (their symmetry orbits): equal rows are\n"
                             "forced by symmetry, not discovered. Pair 0 is pinned to slot 1 by C4, so its row is 0.",
                transform=ax.transAxes, ha="center", va="top", fontsize=10.5, color="#222222")
    else:
        ax.text(0.5, -0.155, "Pairs in one symmetry orbit have equal rows, so rows repeat by construction; a zero row\n"
                             "is pair 0 (pinned to slot 1 by C4) or a pair this table does not place.",
                transform=ax.transAxes, ha="center", va="top", fontsize=10.5, color="#222222")
    ax.set_xticks(range(len(ks)))
    ax.set_xticklabels([str(k + 2) for k in ks], fontsize=10)
    ax.set_yticks(range(0, len(ps), 2))
    ax.set_yticklabels([str(ps[i]) for i in range(0, len(ps), 2)], fontsize=10)
    # Q-899 (Codex VIZ H03): one letter named both the slot and the layer ("pair j at slot k" over
    # an axis reading "layer k fills slot k+2"), and "global pair index" left no way to find a
    # row's hexagrams. s is the slot, k stays the layer, and the row axis says which hexagrams j is.
    ax.set_xlabel("pair-slot s (layer k fills slot s = k+2)", fontsize=11)
    ax.set_ylabel("pair j = King Wen hexagrams 2j+1 and 2j+2", fontsize=11)
    # Q-900 follow-up (lane VR4, 2026-09-28): the title promised an outline on every table, but a table
    # with no kw = 1 row (a reduced n, or a non-King-Wen consumer run) draws none and gets no legend.
    if kw:
        ax.set_title("V1 — positional-marginal field P(pair j in slot s), exact over\n"
                     "C1C2C4C5-SUPERSPACE; C3 not imposed\n"
                     "outlined: King Wen's own placements (diagonal by construction —\n"
                     "the value, not the shape, is the content)",
                     fontsize=12)
    else:
        ax.set_title("V1 — positional-marginal field P(pair j in slot s), exact over\n"
                     "C1C2C4C5-SUPERSPACE; C3 not imposed\n"
                     "no King Wen placement is marked in this table (kw = 0 on every row)",
                     fontsize=12)
    cb = fig.colorbar(im, ax=ax)
    cb.set_label("P(pair j in slot s) — column sums = 1", fontsize=11)
    cb.ax.tick_params(labelsize=10)
    fig.tight_layout()
    save(fig, "fig_tr12_kc_field", _prov(tsv))
    return True


# --- V2 -- the mass river + branch panel (viz/viz_kc_river.md) -------------
def _river_steps(ks, series):
    """Unit-width bins for the V2 stack (VIZ1 F03, 2026-09-26). -> (edges, stepped series).

    Layer k is drawn as the bin [k - 0.5, k + 0.5], and each series gets its last value appended
    so that a `step="post"` fill closes the final bin. The area of each band is then EXACTLY the
    sum of its 31 layer shares -- the class budget (2, 8, 13, 7, 1 at n=31) the title calls fixed.
    The stack used to be a linear interpolation between the layer points over k = 0..30: its
    trapezoid areas were 1.939, 7.731, 12.588, 6.758, 0.984 and summed to 30, not 31, so the
    drawn AREAS were not the budgets the title said they were."""
    ks = list(ks)
    edges = [k - 0.5 for k in ks] + [ks[-1] + 0.5]
    return edges, [list(v) + [v[-1]] for v in series]


@_shape_guarded("V2 river")
def fig_tr12_kc_river(river_tsv, branches_tsv, n=None):
    if not os.path.exists(river_tsv):
        return _missing(river_tsv, "V2 river")
    # viz/viz_kc_river.md: tidy (k, d) grid.  d runs over {1,2,3,4,6}, which is
    # NOT contiguous, so the grid check is applied on the row index rather than
    # on d's absolute values -- see the remap below, which is why d is passed as
    # its own rank and not as its label.
    rows = _read_tsv(river_tsv, required=_V_SCHEMA["V2"])
    _dr = {v: i for i, v in enumerate(sorted({_tsv_cell_int(r, "d") for r in rows}))}
    for r in rows:
        r["_drank"] = str(_dr[_tsv_cell_int(r, "d")])
    _check_grid(rows, ("k", "_drank"), river_tsv)
    ks = sorted({_tsv_cell_int(r, "k") for r in rows})
    ds = sorted({_tsv_cell_int(r, "d") for r in rows})
    _expect_layers(river_tsv, ks, n)                                            # Q-892
    _expect_inventory(river_tsv, "d", ds, _V_D, "the five distance classes {1,2,3,4,6}")
    _expect_probabilities(river_tsv, rows, "p")                                 # lane VR4 (A4-04)
    band = {d: [0.0] * len(ks) for d in ds}
    kw_d = [None] * len(ks)
    for r in rows:
        band[_tsv_cell_int(r, "d")][ks.index(_tsv_cell_int(r, "k"))] = float(r["p"])
        kw_d[ks.index(_tsv_cell_int(r, "k"))] = _tsv_cell_int(r, "kw_d")
    have_b = os.path.exists(branches_tsv)
    if not have_b and n == 31:
        # Q-894 (2026-09-28): the publication figure silently lost its branch panel (and its
        # footer then read `v2_branches.tsv@ABSENT`) when the table was missing. At n = 31 the
        # branch table is part of the figure; below 31 it stays optional.
        raise TsvShapeError(f"{branches_tsv}: absent, and at n = 31 the branch panel is part of "
                            f"the figure -- produce it with the atlas consumer")
    # VIZ1 F18: 10 in wide (was 13) and no text under 10 pt -- see INLINE_PX.
    fig, axes = plt.subplots(2 if have_b else 1, 1, figsize=(10, 11 if have_b else 5.5),
                             dpi=150, gridspec_kw={"height_ratios": [3, 2.4]} if have_b else None)
    ax = axes[0] if have_b else axes
    colors = ["#1f77b4", "#66bb6a", "#e8a33d", "#d32f2f", "#8e24aa", "#00838f"]
    edges, stepped = _river_steps(ks, [band[d] for d in ds])
    # Q-899 (Codex VIZ H08, 2026-09-28): thin dark rules between the stacked bands, so a band's
    # thickness can be traced where two neighbouring fills are close in lightness (d = 2 and d = 3
    # differ by a hue greyscale and colour-blind readers do not see).
    ax.stackplot(edges, *stepped, step="post", colors=colors[:len(ds)], alpha=0.9,
                 edgecolor="#333333", linewidth=0.6)
    # VIZ1 F19 (2026-09-26): each band is LABELLED, not only coloured. The labels sit in the
    # right margin at the band's own height in the last layer, with a leader to the band, because
    # the d = 6 and d = 1 bands are too thin to hold text; labels closer than MIN_GAP are pushed
    # apart (upwards) so that no two collide, and the leader still points at the band.
    MIN_GAP = 0.075
    tops = np.cumsum([band[d][-1] for d in ds])
    mids = [t - band[d][-1] / 2.0 for t, d in zip(tops, ds)]
    ys, last = [], -1.0
    for m in mids:
        last = max(m, last + MIN_GAP)
        ys.append(last)
    # Q-899 (Codex VIZ H08): the labels were set in their band's colour, which put d = 2 at 2.4:1 and
    # d = 3 at 2.2:1 on white. The text is now near-black (15.9:1); the leader and a swatch keep the
    # colour, so the label still points at, and matches, its band.
    LABEL_INK = "#222222"
    assert _wcag_contrast(LABEL_INK, "#ffffff") >= MIN_TEXT_CONTRAST, "V2 band-label contrast"
    for d, m, yl, c in zip(ds, mids, ys, colors):
        ax.annotate(f"d={d}", xy=(ks[-1] + 0.5, m), xytext=(ks[-1] + 2.1, yl),
                    fontsize=11, fontweight="bold", color=LABEL_INK, va="center", ha="left",
                    annotation_clip=False,
                    arrowprops=dict(arrowstyle="-", color=c, lw=1.6, shrinkA=0, shrinkB=0))
        ax.plot([ks[-1] + 1.75], [yl], marker="s", ms=8, color=c, markeredgecolor="#333333",
                markeredgewidth=0.6, clip_on=False, zorder=8)
    if any(v is not None and v >= 0 for v in kw_d):
        y = []
        for j, k in enumerate(ks):
            acc = 0.0
            for d in ds:
                if d == kw_d[j]:
                    y.append(acc + band[d][j] / 2.0)
                    break
                acc += band[d][j]
            else:
                y.append(np.nan)
        # Same unit bins as the stack: the step spans [k - 0.5, k + 0.5] at every layer,
        # including the two end layers, which where="mid" over ks used to draw half-width.
        ax.step(edges, y + [y[-1]], where="post", color="white", lw=2.0, zorder=6)
        ax.step(edges, y + [y[-1]], where="post", color="#111111", lw=1.0, zorder=7,
                label="King Wen's own class")
    ax.set_xlim(edges[0], edges[-1])
    # 2026-09-24: headroom ABOVE 1.0 for the legend.  With ylim (0, 1) the upper-right legend
    # sat on the d = 6 band and hid King Wen's step at k = 18 -- the one layer where King Wen
    # stands in d = 6, i.e. the "9th six" the page tells the reader to look for.
    ax.set_ylim(0, 1.10)
    ax.set_yticks([0, 0.2, 0.4, 0.6, 0.8, 1.0])
    ax.tick_params(labelsize=10)
    ax.set_xlabel("layer k (fills pair-slot k+2); each layer is a unit-width bin", fontsize=11)
    ax.set_ylabel("share of C1C2C4C5-SUPERSPACE", fontsize=11)
    ax.set_title("V2 — mass river: exact per-layer boundary-distance class mass over\n"
                 "C1C2C4C5-SUPERSPACE; C3 not imposed. Each layer is a unit-width bin, so a band's\n"
                 "AREA is its class total, fixed by the C1+C5 theorem; only the shape across k is informative",
                 fontsize=12)
    if ax.get_legend_handles_labels()[0]: ax.legend(fontsize=10.5, loc="upper center", frameon=False)  # only KW's step is labelled (bands: F19); none at n=9, where a bare legend() warns into the golden
    if have_b:
        br = _read_tsv(branches_tsv, required=_V_SCHEMA["V2b"])
        bs = _check_grid(br, ("branch",), branches_tsv)[0]   # one contiguous row per branch
        _expect_inventory(branches_tsv, "branch", bs, range(len(bs)), "branches start at 0")
        br = sorted(br, key=lambda r: float(r["share"]), reverse=True)
        ax2 = axes[1]
        x = range(len(br))
        ax2.bar(x, [float(r["share"]) for r in br], color="#1f77b4",
                label="solutions(b) / N")
        ax2.set_xticks(list(x))
        ax2.set_xticklabels([f"{r['pair']}:{r['entry']}" for r in br],
                            fontsize=10, rotation=90)
        ax2.set_xlim(-0.6, len(br) - 0.4)
        ax2.tick_params(axis="y", labelsize=10)
        ax2.set_ylabel("branch share of N", fontsize=11)
        ax2.set_xlabel("branch = pair j : entry hexagram code (0–63), sorted by mass", fontsize=11)
        tvals = [r["prefixes_t_units"] for r in br]
        # Q-894 (2026-09-28): a cost that was not all digits dropped the line with no word while the
        # title still promised it. Now: every cell a decimal integer -> the line; every cell the
        # documented pending sentinel PENDING_T_LADDER(...) -> a stated "unavailable" note; any
        # other value, or a mixture -> refused.
        pend = [t.startswith("PENDING_T_LADDER(") and t.endswith(")") for t in tvals]
        digits = [t.isascii() and t.isdigit() for t in tvals]
        if not (all(pend) or all(digits)):
            odd = [t for t, a, b in zip(tvals, pend, digits) if not (a or b)]
            raise TsvShapeError(f"{branches_tsv}: prefixes_t_units must be a decimal integer on every "
                                f"row, or PENDING_T_LADDER(...) on every row; "
                                + (f"got {odd[0]!r}" if odd else "got a mixture of the two"))
        if all(pend):
            ax2.text(0.99, 0.95, "exhaustion cost unavailable: every prefixes_t_units\n"
                     "cell reads PENDING_T_LADDER (no t-ladder was given)",
                     transform=ax2.transAxes, ha="right", va="top", fontsize=10, color="#d32f2f")
        if all(digits):
            ax3 = ax2.twinx()
            ax3.plot(list(x), [_log10_bigint(t) for t in tvals],
                     color="#d32f2f", marker="o", ms=3, lw=1.2,
                     label="log10 prefixes_t_units")
            ax3.set_ylabel("log10 exhaustion cost (t-units = valid prefixes)", fontsize=11, color="#d32f2f")
            ax3.tick_params(axis="y", labelcolor="#d32f2f", labelsize=10)
        # 🔴 2026-09-24: this title read "a small-but-expensive branch is the atlas's point",
        # and the panel it titles shows NO such branch.  Measured on the committed n=31
        # reports/tr12/scan/v2_branches.tsv: 0 of 1,540 branch pairs are discordant (a smaller mass
        # with a larger cost); the 56 branches fall into 7 mass levels mapping one-to-one onto
        # 7 cost levels; cost/mass spans 7.65-8.20.  The title now states what is drawn.
        ax2.set_title("branch panel — solution mass (bars) vs exhaustion cost (line);\n"
                      "measured at n=31 the two are CO-MONOTONE: no branch is small-but-expensive",
                      fontsize=11.5)
    fig.tight_layout()
    # Q-899 (Codex VIZ H07): the figure used d, "t-units" and "entry hexagram" without defining any of
    # them, and did not say how to read King Wen's line against the stack. The key is placed under
    # everything else drawn (save() then sets the footer beneath it).
    r = fig.canvas.get_renderer()
    bb = fig.get_tightbbox(r)
    fig.text(bb.x0 / fig.get_figwidth(), (bb.y0 - 0.08) / fig.get_figheight(),
             "KEY — d = number of lines that differ across a pair boundary (the exit hexagram of one pair\n"
             "against the entry hexagram of the next). King Wen's line marks which class it is in at each\n"
             "layer; its height inside the band is not a probability. A branch is one first free placement:\n"
             "a pair j and its orientation, named pair : entry, the entry hexagram's six-bit code (0–63).\n"
             "One t-unit is one valid oriented prefix, not one production-DFS node.",
             ha="left", va="top", fontsize=10.5, color="#222222")
    save(fig, "fig_tr12_kc_river", _prov(river_tsv, branches_tsv))
    return True


# --- V5 -- the transition grammar (viz/viz_kc_grammar.md) ------------------
@_shape_guarded("V5 grammar")
def fig_tr12_kc_grammar(tsv, n=None):
    if not os.path.exists(tsv):
        return _missing(tsv, "V5 grammar")
    # viz/viz_kc_grammar.md: tidy (k, class) grid, class = (d, w).  d and w are
    # both non-contiguous label sets, so the grid is checked on the CLASS RANK.
    rows = _read_tsv(tsv, required=_V_SCHEMA["V5"])
    _cr = {v: i for i, v in enumerate(sorted({(_tsv_cell_int(r, "d"), _tsv_cell_int(r, "w")) for r in rows}))}
    for r in rows:
        r["_crank"] = str(_cr[(_tsv_cell_int(r, "d"), _tsv_cell_int(r, "w"))])
    _check_grid(rows, ("k", "_crank"), tsv)
    # 🔴 Q-316 item (4).  A table WITHOUT the `w` axis (an atlas with no kernel -- the emitter
    # then writes the honest placeholder w=-1 on every row; the committed full-31 table HAS
    # the axis since 2026-09-23, w in {2,4,6}) must still get its King Wen overlay.  The
    # King Wen overlay matched on (kw_d == d AND kw_w == w), and at full-31 kw_w is a real
    # within-pair distance in {2,4,6}, so `kw_w == -1` is FALSE on every row and the outline
    # the caption promised COULD NEVER BE DRAWN.  A caption describing a mark the figure
    # cannot contain is worse than no caption: the reader concludes King Wen's class is
    # absent from the plot.  When the axis is absent the rows ARE the classes, so the match
    # is on d alone, and the caption below says which of the two happened.
    reduced = all(_tsv_cell_int(r, "w") < 0 for r in rows)
    ks = sorted({_tsv_cell_int(r, "k") for r in rows})
    cls = sorted({(_tsv_cell_int(r, "d"), _tsv_cell_int(r, "w")) for r in rows})
    _expect_layers(tsv, ks, n)                                                  # Q-892
    _expect_inventory(tsv, "(d, w)", cls, [(d, w) for d in _V_D for w in ((-1,) if reduced else _V_W)],
                      "every class d in {1,2,3,4,6} x w in {2,4,6} (reduced form: w = -1)")
    _expect_probabilities(tsv, rows, "p_cond")                                  # lane VR4 (A4-04)
    M = np.zeros((len(cls), len(ks)))
    marks = []
    for r in rows:
        i, j = cls.index((_tsv_cell_int(r, "d"), _tsv_cell_int(r, "w"))), ks.index(_tsv_cell_int(r, "k"))
        M[i, j] = float(r["p_cond"])
        if _tsv_cell_int(r, "kw_d") == _tsv_cell_int(r, "d") and (reduced or _tsv_cell_int(r, "kw_w") == _tsv_cell_int(r, "w")):
            marks.append((i, j))
    # VIZ1 F18 (2026-09-26): 10 in wide (was 13) and no text under 10 pt -- see INLINE_PX.
    fig, ax = plt.subplots(figsize=(10, 4.4 + 0.3 * len(cls)), dpi=150)
    im = ax.imshow(M, aspect="auto", origin="lower", cmap="viridis",
                   interpolation="nearest")
    # Q-899 (Codex VIZ H05, 2026-09-28): the white outline measured 2.2:1 on the green viridis cells.
    # It is drawn over a wider black under-stroke, so one of the two contrasts with ANY cell by at
    # least _two_tone_floor(white, black) = 4.6:1.
    KW_FG, KW_UNDER = "#ffffff", "#000000"
    assert _two_tone_floor(KW_FG, KW_UNDER) >= MIN_MARK_CONTRAST, "V5 King Wen outline contrast"
    for i, j in marks:          # every under-stroke first, so no cell's black
        ax.add_patch(plt.Rectangle((j - 0.5, i - 0.5), 1, 1, fill=False,    # covers a neighbour's core
                                   edgecolor=KW_UNDER, lw=3.8))
    for i, j in marks:
        ax.add_patch(plt.Rectangle((j - 0.5, i - 0.5), 1, 1, fill=False,
                                   edgecolor=KW_FG, lw=1.8))
    # Same convention as V1 and V2: the King Wen overlay gets a LEGEND KEY, not only a
    # subtitle sentence. Below the axes, because every cell here is a published number.
    # Q-899: the key used to be a white line on a dark patch that imitated the map, because a white
    # swatch on the white page was invisible. With the black under-stroke the key is the mark
    # itself, two-tone, and reads on the page as it reads on the map.
    if marks:
        from matplotlib.lines import Line2D
        from matplotlib.legend_handler import HandlerTuple
        ax.legend(handles=[(Line2D([], [], color=KW_UNDER, lw=3.8), Line2D([], [], color=KW_FG, lw=1.8))],
                  labels=[("King Wen's own distance class d at this layer" if reduced else
                           "King Wen's own (d, w) cell at this layer")],
                  handler_map={tuple: HandlerTuple(ndivide=1)},
                  fontsize=10.5, loc="upper center", bbox_to_anchor=(0.5, -0.12), frameon=False)
    # Q-899 (Codex VIZ H14): a column is a layer marginal over the whole space, not a law
    # conditioned on the walk so far (viz_kc_grammar.md: "This is not a Markov model, and the
    # columns do not compose"); the figure did not say so.
    ax.text(0.5, -0.2 if marks else -0.12,
            "Each column averages over the whole superspace: it is not conditioned on King Wen's\n"
            "(or any walk's) earlier choices, and the columns do not compose into a chain.",
            transform=ax.transAxes, ha="center", va="top", fontsize=10.5, color="#222222")
    ax.set_yticks(range(len(cls)))
    ax.set_yticklabels([f"d={d}" + ("" if w < 0 else f", w={w}") for d, w in cls], fontsize=10)
    ax.set_xticks(range(len(ks)))
    ax.set_xticklabels([str(k) for k in ks], fontsize=10)
    ax.set_xlabel("layer k (places the new pair in pair-slot k+2)", fontsize=11)
    # 🔴 THE TITLE IS STATIC, BRANCH BY BRANCH (2026-09-24).  It used to be composed at
    # runtime (a conditional `_kwnote` concatenated into set_title), which made the orbit
    # caveat below text no gate could read -- see the FIGURE_LABEL_MANIFEST note.  Each branch
    # now passes ONE literal, so all three are manifested.  It was also ONE subtitle line of
    # ~230 characters, which bbox_inches="tight" honoured by widening the canvas to ~3100 px
    # with the heat map stranded in the middle; it is now wrapped.
    #
    # VIZ1 F06 (2026-09-26): the full-form subtitle's orbit caveat overstated what one row
    # resolves. The seven free-pair orbits split by w as {2: 3, 4: 2, 6: 2},
    # and a row fixes ONE (d, w) combination. The caveat now says exactly that, in the wording
    # the reviewers settled on, and the titles are wrapped for the 10-in canvas.
    if not marks:
        ax.set_title("V5 — transition grammar P(class | layer k), exact over\n"
                     "C1C2C4C5-SUPERSPACE; C3 not imposed; read DOWN each column (every column sums to 1)\n"
                     "no King Wen overlay in this table — kw_d/kw_w match no plotted class\n"
                     "at any layer (n != 31?)", fontsize=12)
    elif reduced:
        ax.set_title("V5 — transition grammar P(class | layer k), exact over\n"
                     "C1C2C4C5-SUPERSPACE; C3 not imposed; read DOWN each column (every column sums to 1)\n"
                     "REDUCED FORM: this table carries no w axis (w = -1), so a row is a\n"
                     "distance class d and the white outline is King Wen's own d", fontsize=12)
    else:
        ax.set_title("V5 — transition grammar P(d, w | layer k), exact over\n"
                     "C1C2C4C5-SUPERSPACE; C3 not imposed; read DOWN each column (every column sums to 1)\n"
                     "d = lines differing across the boundary into the new pair, w = lines differing\n"
                     "between the new pair's two hexagrams.\n"
                     "The seven pair-orbits are grouped into three within-pair-distance categories;\n"
                     "each row fixes one (d,w) combination and does not identify an individual pair.",
                     fontsize=12)
    cb = fig.colorbar(im, ax=ax)
    cb.set_label("P(class | layer k)", fontsize=11)
    cb.ax.tick_params(labelsize=10)
    fig.tight_layout()
    save(fig, "fig_tr12_kc_grammar", _prov(tsv))
    return True


# --- V4 -- King Wen's neighbourhood shells (viz/viz_kc_shells.md) ----------
# The ALTERNATIVES BAND (viz/viz_kc_shells.md, "The alternatives band"). At each of King Wen's steps
# the band spans the least and greatest g over every admissible oriented successor with g > 0 --
# King Wen's own choice among them -- i.e. g_alt_min / g_alt_max of `solve --kc-profile ... --kc-tsv FILE --kc-alts`.
# At n = 31 those rows exist only as the ATTESTED receipts of the 2026-09-22 battery (the f/g ladders
# are not distributed), published at the path below. The band is read WHERE IT IS PUBLISHED, not
# copied into reports/tr12/: a copy would be a second file whose agreement with the receipt nothing checks,
# and routing it through the consumer would rewrite reports/tr12/q3_profile_kw.tsv (a --kc-profile source
# carries no mass_below). The footer names this file and its sha beside the curve's own table.
Q3_ALTS_BANKED = os.path.join(_REPO_ROOT, "reports", "evidence", "tr12", "banked_n31_20260922",
                              "q3_profile_exact.tsv")
# Columns on which the band's rows must agree EXACTLY with the curve's rows before the band is drawn:
# the band belongs to King Wen's walk only if every placement and every shell size is the same one.
_Q3_ALT_JOIN = ("step", "pair", "entry", "exit", "orient", "alts", "g", "g_parent")


def _read_q3_alts(path):
    """A `--kc-profile --kc-tsv` table -> (n, rows).  Engine layout, not the consumer's: line 1 is the
    `order=... n=... N=...` banner, line 2 the header, then exactly n step rows, then the engine's
    verdict lines, one of which must be KC_PROFILE=OK.  Any other shape is a TsvShapeError.
    Read once, as bytes; the digest of those bytes goes to the footer (Q-890, as _read_tsv)."""
    import hashlib
    import io
    with open(path, "rb") as raw:
        data = raw.read()
    lines = io.TextIOWrapper(io.BytesIO(data), encoding="utf-8").read().split("\n")
    if lines and lines[-1] == "":
        lines.pop()
    if len(lines) < 3 or not lines[0].startswith("order="):
        raise TsvShapeError(f"{path}: line 1 is not the engine's `order=` banner; "
                            f"not a --kc-profile table")
    meta = dict(kv.split("=", 1) for kv in lines[0].split("\t") if "=" in kv)
    try:
        n = _tsv_int(meta.get("n", ""), "banner n")
    except ValueError as e:
        raise TsvShapeError(f"{path}: {e}")
    head = lines[1].split("\t")
    if len(set(head)) != len(head):         # Q-891: dict(zip()) kept the LAST of two same-named columns
        raise TsvShapeError(f"{path}: header repeats column(s) "
                            f"{sorted({c for c in head if head.count(c) > 1})}")
    missing = [c for c in _Q3_ALT_JOIN + ("g_alt_min", "g_alt_max") if c not in head]
    if missing:
        raise TsvShapeError(f"{path}: header is missing required column(s) {missing}")
    body, tail = lines[2:2 + n], lines[2 + n:]
    rows = []
    for lineno, line in enumerate(body, start=3):
        f = line.split("\t")
        if len(f) != len(head):
            raise TsvShapeError(f"{path}:{lineno}: {len(f)} field(s) against a {len(head)}-column "
                                f"header -- fewer step rows than the banner's n={n}, or a torn row")
        rows.append(dict(zip(head, f)))
    # Q-891: "KC_PROFILE=OK is in the tail" also accepted a tail that ALSO said KC_PROFILE=FAIL. The
    # verdict must be exactly one KC_PROFILE= line, it must read OK, and no tail line may say FAIL.
    if ([t for t in tail if t.startswith("KC_PROFILE=")] != ["KC_PROFILE=OK"]
            or any("FAIL" in t for t in tail) or any("\t" in t for t in tail)):
        raise TsvShapeError(f"{path}: the {n} step rows are not followed by the engine's "
                            f"KC_PROFILE=OK verdict and nothing else")
    _check_grid(rows, ("step",), path)
    _SOURCE_SHA256[os.path.abspath(path)] = hashlib.sha256(data).hexdigest()
    return n, rows


def _v4_band(rows, alts_path, curve_path=None):
    """(lo, hi, source) for V4's alternatives band, or None when there is no band to draw.

    Two sources, in this order. (1) The curve's own table, when it carries g_alt_min / g_alt_max (a
    consumer run fed a --kc-profile table): source None, the footer already names the table.
    (2) The published attested receipt `alts_path` (Q3_ALTS_BANKED), joined to the curve row by row.

    SILENT when `alts_path` is None (the caller asked for no band) or when the receipt describes
    another universe (its n differs from the curve's row count): that is the n=9 reproduction
    battery, whose c_viz output is golden-diffed, and a band from n=31 has no meaning there. LOUD (one
    `V4 band omitted:` line, figure still drawn without the band) when the receipt is the same n but
    disagrees with the curve, or is malformed: that is a band that would be drawn around a walk it
    does not belong to.

    Q-891 (2026-09-28), four fail-open paths closed. (a) A receipt path that does not exist was
    silent too, and the footer then named only the curve; it is now one `V4 band omitted: receipt
    absent` line, and fig_tr12_kc_shells puts `<receipt>@ABSENT` in the footer. (b) The range check
    was `0 < g_alt_min <= g <= g_alt_max`; it now also requires `g_alt_max <= g_parent` (g_parent
    is the SUM of g over the alternatives, so no alternative exceeds it) and, at a step with one
    alternative, `g_alt_min == g_alt_max == g`. (c) Bounds carried in the curve's OWN table used to
    be drawn as "this table's", which stripped the ATTESTED status the receipt path keys; they are
    now drawn only when the table's sidecar (`<table>.provenance.txt`) says
    `q3_alts_status=REPRODUCED` (computed by this run from ladders it has; NO EMITTER WRITES THAT KEY YET -- solve.py atlas_emit_q3 does not -- so today this branch always omits, noted by lane VR4, not built), and are otherwise
    omitted, loudly -- an attested band is drawn only from the published receipt, joined step by
    step (viz_kc_shells.md). (d) duplicate headers and a FAIL verdict in the receipt: _read_q3_alts."""
    by_step = {_tsv_cell_int(r, "step"): r for r in rows}
    if "g_alt_min" in rows[0] and "g_alt_max" in rows[0]:
        status = None
        side = None if curve_path is None else curve_path + ".provenance.txt"
        if side is not None and os.path.exists(side):
            with open(side, encoding="utf-8") as fh:
                for line in fh:
                    k, sep, v = line.rstrip("\n").partition("=")
                    if sep and k == "q3_alts_status":
                        status = v
        if status != "REPRODUCED":
            print(f"V4 band omitted: the curve's table carries its own g_alt_min / g_alt_max, and "
                  f"its sidecar reads q3_alts_status={status} -- only REPRODUCED bounds are drawn "
                  f"from the table itself; attested bounds come from the published receipt")
            return None
        src, source = by_step, None
    else:
        if alts_path is None:
            return None
        if not os.path.exists(alts_path):
            print(f"V4 band omitted: receipt absent {alts_path}")
            return None
        try:
            n, arows = _read_q3_alts(alts_path)
        except TsvShapeError as e:
            print(f"V4 band omitted: {e}")
            return None
        if n != len(rows):
            return None
        src = {_tsv_cell_int(a, "step"): a for a in arows}
        if sorted(src) != sorted(by_step):
            print(f"V4 band omitted: {os.path.basename(alts_path)} covers steps "
                  f"{min(src)}..{max(src)}, the curve {min(by_step)}..{max(by_step)}")
            return None
        for s in sorted(by_step):
            for c in _Q3_ALT_JOIN:
                if c not in by_step[s]:
                    print(f"V4 band omitted: the curve's table has no {c!r} column to join on")
                    return None
                if _tsv_cell_int(src[s], c) != _tsv_cell_int(by_step[s], c):
                    print(f"V4 band omitted: {os.path.basename(alts_path)} disagrees with the "
                          f"curve at step {s}, column {c!r} -- it is not this walk's profile")
                    return None
        source = alts_path
    lo, hi = [], []
    for s in sorted(by_step):
        g, gp = _tsv_cell_int(by_step[s], "g"), _tsv_cell_int(by_step[s], "g_parent")
        mn, mx = _tsv_cell_int(src[s], "g_alt_min"), _tsv_cell_int(src[s], "g_alt_max")
        one = _tsv_cell_int(by_step[s], "alts") == 1
        if not 0 < mn <= g <= mx <= gp or (one and not mn == mx == g):
            why = (f"step {s}: g_alt_min={mn}, g={g}, g_alt_max={mx}, g_parent={gp}"
                   + (", one alternative" if one else "")
                   + " -- King Wen's own choice is one of the alternatives and g_parent is the sum "
                     "of their g, so 0 < g_alt_min <= g <= g_alt_max <= g_parent must hold (and "
                     "g_alt_min == g_alt_max == g where there is one alternative)")
            if source is None:
                raise TsvShapeError(why)
            print(f"V4 band omitted: {os.path.basename(alts_path)} {why}")
            return None
        lo.append(_log10_bigint(str(mn)))
        hi.append(_log10_bigint(str(mx)))
    return lo, hi, source


@_shape_guarded("V4 shells")
def fig_tr12_kc_shells(tsv, alts=Q3_ALTS_BANKED, n=None):
    if not os.path.exists(tsv):
        return _missing(tsv, "V4 shells", how="python3 solve.py --atlas-queries ATLAS.json --atlas-out DIR --atlas-q3-trace TRACE, where TRACE is solve --kc-o3-rank FDIR GDIR WALK --kc-trace text or a solve --kc-profile FDIR GDIR WALK --kc-tsv table; the published n=31 trace is reports/tr12/q3_trace_kw.txt")
    # viz/viz_kc_shells.md: one row per free placement, `step` a contiguous run
    rows = _read_tsv(tsv, required=_V_SCHEMA["V4"])
    _check_grid(rows, ("step",), tsv)
    rows = sorted(rows, key=lambda r: _tsv_cell_int(r, "step"))
    steps = [_tsv_cell_int(r, "step") for r in rows]
    # Q-892 (2026-09-28): steps 1..n and a COMPLETE walk, checked BEFORE the band decides whether the
    # receipt is "another universe" -- a table that lost step 31 used to render under the "31 free
    # placements" title and drop the band silently as if it were the n = 30 universe.
    _expect_inventory(tsv, "step", steps, range(1, (len(steps) if n is None else n) + 1),
                      "steps 1..n" + ("" if n is None else " at n = %d" % n))
    if _tsv_cell_int(rows[-1], "g") != 1:
        raise TsvShapeError(f"{tsv}: the last step (step {steps[-1]}) leaves g = {rows[-1]['g']}, not "
                            f"1 -- a complete walk has exactly one completion left; the table is "
                            f"truncated or is not a whole walk")
    # g is a 192-bit decimal string: plotted on a log axis via its digit count,
    # never by float()-ing the exact value.
    logg = [_log10_bigint(r["g"]) for r in rows]
    # Q-891 (2026-09-28): `bits` was plotted as read. It must be -log2(p_num / p_den), the exact
    # rational beside it, to the engine's 6-decimal print (the atlas reader's own tolerance).
    bits = []
    for r in rows:
        pn, pd = _tsv_cell_int(r, "p_num"), _tsv_cell_int(r, "p_den")
        try:
            b = float(r["bits"])
        except ValueError:
            b = float("nan")
        if not (0 < pn <= pd) or not math.isfinite(b) or abs(b - (math.log2(pd) - math.log2(pn))) > 5e-7 + 1e-9:
            raise TsvShapeError(f"{tsv}: step {r['step']}: bits = {r['bits']!r}, but -log2(p_num/p_den) "
                                f"= {math.log2(pd) - math.log2(pn) if 0 < pn <= pd else 'undefined'} "
                                f"(p_num = {r['p_num']}, p_den = {r['p_den']}) -- the plotted bar "
                                f"would not be the step's probability")
        bits.append(b)
    alts_n = [_tsv_cell_int(r, "alts") for r in rows]
    # Q-891 (2026-09-28): the titles said "King Wen's 31 free placements" for ANY table, including the
    # n = 9 battery's (whose sidecar reads q3_is_king_wen=SKIP:n=9) and a full-31 trace the consumer
    # marked NOT-KW. King Wen's wording is used only when the table is the _kw name, its sidecar (if
    # any) says q3_is_king_wen=PASS, and its rows ARE King Wen's shape: 31 steps, pair i at step i.
    kw_walk = os.path.basename(tsv) == "q3_profile_kw.tsv" and len(rows) == 31 and all(
        _tsv_cell_int(r, "pair") == _tsv_cell_int(r, "step") for r in rows)
    if kw_walk and os.path.exists(tsv + ".provenance.txt"):
        with open(tsv + ".provenance.txt", encoding="utf-8") as fh:
            kw_walk = "q3_is_king_wen=PASS" in fh.read().splitlines()
    band = _v4_band(rows, alts, tsv)
    # VIZ1 F18 (2026-09-26): 10 in wide (was 12) and no text under 10 pt -- see INLINE_PX.
    fig, (ax, ax2) = plt.subplots(2, 1, figsize=(10, 10.4), dpi=150, sharex=True,
                                  gridspec_kw={"height_ratios": [3, 2.5]})
    if band is not None:
        # The key is an ax.text, not a legend label, so its wording is a static literal that
        # FIGURE_LABEL_MANIFEST (and so every text gate) can read -- a legend label is not.
        lo, hi, source = band
        # One bar per step, not a step-filled area: the alternatives at step i exist only at step i,
        # and a filled band between steps would draw values no alternative has. On a 37-decade axis
        # the widest range is about 1.4 decades, so the bars are drawn thick enough to be seen.
        ax.vlines(steps, lo, hi, colors="#1f77b4", alpha=0.35, lw=9, zorder=1)
        key = dict(transform=ax.transAxes, ha="right", va="top", fontsize=10,
                   bbox=dict(boxstyle="square,pad=0.4", facecolor=(0.12, 0.47, 0.71, 0.18),
                             edgecolor="#1f77b4", lw=0.8))
        if source is None and not kw_walk:
            ax.text(0.985, 0.975, "shaded bars: least to greatest g over ALL admissible\n"
                    "alternatives at each step, the walk's own choice included\n"
                    "(this table's g_alt_min / g_alt_max)", **key)
        elif source is None:
            ax.text(0.985, 0.975, "shaded bars: least to greatest g over ALL admissible\n"
                    "alternatives at each step, King Wen's own choice included\n"
                    "(this table's g_alt_min / g_alt_max)", **key)
        else:
            ax.text(0.985, 0.975, "shaded bars: least to greatest g over ALL admissible\n"
                    "alternatives at each step, King Wen's own choice included.\n"
                    "ATTESTED: 2026-09-22 n=31 battery receipts (q3_profile_exact.tsv);\n"
                    "not reproducible without the f/g ladders", **key)
    ax.step(steps, logg, where="mid", color="#1f77b4", lw=2.0, marker="o", ms=4, zorder=2)
    for s, y, a in zip(steps, logg, alts_n):
        ax.annotate(str(a), (s, y), textcoords="offset points", xytext=(0, 7),
                    ha="center", fontsize=10, color="#444444")
    ax.tick_params(labelsize=10)
    if kw_walk:
        ax.set_ylabel("log10 g(King Wen's prefix) — completions remaining", fontsize=11)
    else:
        ax.set_ylabel("log10 g(the walk's prefix) — completions remaining", fontsize=11)
    # 🔴 The title used to read "exact completions remaining after each placement" and the
    # y-label "log10 g(prefix)" — NEITHER said King Wen. V1, V2 and V5 plot a population with
    # King Wen overlaid, so a reader arriving from those figures reasonably reads this one the
    # same way. It is not: every point here is ONE walk, King Wen's own. Saying so is worth
    # more than any marker, because the thing a marker would distinguish does not exist here.
    # VIZ1 F21 (2026-09-26): the title names the space (C1C2C4C5-SUPERSPACE; C3 not imposed) that
    # g counts completions in and that N is the size of; it named neither.
    # Lane VF (2026-09-27): "this figure plots ONE walk" became "the line plots ONE walk" -- the
    # alternatives band is not King Wen's walk, and the title must stay true with or without it.
    if kw_walk:
        ax.set_title("V4 — King Wen's neighbourhood shells in C1C2C4C5-SUPERSPACE; C3 not imposed\n"
                     "exact completions remaining after each of King Wen's 31 free placements\n"
                     "EVERY point is King Wen's own trajectory — the line plots ONE walk, not a\n"
                     "population (annotation = # admissible alternatives)", fontsize=12)
    else:
        ax.set_title("V4 — neighbourhood shells of the traced walk in C1C2C4C5-SUPERSPACE; C3 not imposed\n"
                     "exact completions remaining after each of the walk's free placements\n"
                     "NOT identified as King Wen's walk — every point is this ONE walk's own\n"
                     "trajectory, not a population (annotation = # admissible alternatives)", fontsize=12)
    ax.grid(True, ls=":", alpha=0.4)
    ax2.bar(steps, bits, color="#e8a33d")
    # Q-899 (Codex VIZ H12 / H13, 2026-09-28). p_i was never defined on the figure, and the reference
    # the spec says to read each bar against (bits_i - log2 alts_i, viz_kc_shells.md) needed 31
    # logarithms of the counts printed on the OTHER panel. p_i is now defined in the subtitle, and
    # each step carries a short black tick at log2 a_i: the bits the step would cost if all a_i
    # admissible alternatives had equal completion counts. A bar above its tick means the walk's
    # choice has fewer completions than the average alternative. Per-step ticks, not a line: an
    # alternative count exists only at its own step.
    ref = [math.log2(a) if a > 0 else float("nan") for a in alts_n]
    ax2.hlines(ref, [s - 0.42 for s in steps], [s + 0.42 for s in steps], colors="#111111", lw=2.2,
               zorder=3)
    ax2.set_ylim(0, 1.55 * max([b for b in bits] + [r for r in ref if r == r] + [1.0]))
    ax2.tick_params(labelsize=10)
    ax2.set_ylabel("−log2 p_i (bits)", fontsize=11)
    ax2.set_xlabel("step (free placement i)", fontsize=11)
    ax2.grid(True, axis="y", ls=":", alpha=0.4)
    if kw_walk:
        ax2.set_title("surprisal of King Wen's next choice: −log2 p_i bits, p_i = g_i / g_(i−1), the share of\n"
                      "the previous shell that makes King Wen's choice. The bars sum to log2 N, N = |C1∩C2∩C4∩C5|\n"
                      "(EW-1). A step with ONE admissible alternative costs 0 bits.",
                      fontsize=11)
        ax2.text(0.985, 0.96, "black tick: log2 a_i, the bits if all a_i admissible alternatives\n"
                 "had equal completion counts (a_i = the count printed above the curve).\n"
                 "A bar above its tick: King Wen's choice has fewer completions\n"
                 "than the average alternative.",
                 transform=ax2.transAxes, ha="right", va="top", fontsize=10, color="#222222",
                 bbox=dict(boxstyle="square,pad=0.35", facecolor="#ffffff", edgecolor="#9e9e9e", lw=0.8))
    else:
        ax2.set_title("surprisal of the walk's next choice: −log2 p_i bits, p_i = g_i / g_(i−1), the share of\n"
                      "the previous shell that makes the walk's choice. The bars sum to log2 N, N = |C1∩C2∩C4∩C5|\n"
                      "(EW-1). A step with ONE admissible alternative costs 0 bits.",
                      fontsize=11)
        ax2.text(0.985, 0.96, "black tick: log2 a_i, the bits if all a_i admissible alternatives\n"
                 "had equal completion counts (a_i = the count printed above the curve).\n"
                 "A bar above its tick: the walk's choice has fewer completions\n"
                 "than the average alternative.",
                 transform=ax2.transAxes, ha="right", va="top", fontsize=10, color="#222222",
                 bbox=dict(boxstyle="square,pad=0.35", facecolor="#ffffff", edgecolor="#9e9e9e", lw=0.8))
    fig.tight_layout()
    # Q-891: a receipt that was asked for and is absent is named in the footer as `<name>@ABSENT`.
    absent = alts if (band is None and alts is not None and "g_alt_min" not in rows[0]
                      and not os.path.exists(alts)) else None
    save(fig, "fig_tr12_kc_shells", _prov(tsv, band[2] if band is not None else absent))
    return True


# --- V3 -- the rank spectrum (viz/viz_kc_spectrum.md) ----------------------
@_shape_guarded("V3 spectrum")
def fig_tr12_kc_spectrum(tsv):
    if not os.path.exists(tsv):
        # V3 does NOT ride the atlas: its rows come from a rank grid (the
        # solve --kc-unrank K-loop, row a1_v3 -> v3_rel_grid.tsv) joined to the
        # frozen --compute-stats battery by `solve.py --v3-spectrum`, which
        # scripts/tr12_repro.sh runs at n=31 only (row c_v3_join).  Q-808: this
        # message named the battery as the route; the join is --v3-spectrum.
        # See viz/viz_kc_spectrum.md.
        return _missing(tsv, "V3 spectrum",
                        how="python3 solve.py --v3-spectrum GRID_TSV OUT_TSV, where GRID_TSV "
                            "is the rank grid of row a1_v3 (v3_rel_grid.tsv); "
                            "see viz/viz_kc_spectrum.md")
    # viz/viz_kc_spectrum.md: `order` is mandatory and never dropped; `i` is the
    # contiguous grid index.
    rows = _read_tsv(tsv, required=_V_SCHEMA["V3"])
    _check_grid(rows, ("i",), tsv)
    skip = {"i", "rank", "x", "order", "walk"}
    # Q-893 (2026-09-28): the axis is labelled "x = rank / N" and the panels are numbers, and none of
    # that was checked: `x` was plotted as read (1 - x rendered under the same label), `order` could
    # be any string, a rank could be anything, a row lost from the END of the grid left a smaller
    # grid that passed, and constancy was decided on SPELLINGS ("3.3492064" and "3.349206400" were two
    # values). The grid is now checked as the spec defines it (viz_kc_spectrum.md: i = 0..K-1,
    # r_i = i * floor(N/K), x = r_i / N in [0,1)): N is not in the table, but floor(N/K) = rank[1]
    # and N lies in [K*rank[1], K*rank[1] + K - 1], so x must equal rank / (K * rank[1]) to within
    # x / rank[1] (plus float slack). A table missing its last rows has the wrong K and fails that
    # by about 1/K, which is many orders above the tolerance at any grid this renderer draws.
    K = len(rows)
    idx = [_tsv_cell_int(r, "i") for r in rows]
    _expect_inventory(tsv, "i", sorted(idx), range(K), "grid index i = 0..K-1")
    rows = sorted(rows, key=lambda r: _tsv_cell_int(r, "i"))
    bad_order = sorted({r["order"] for r in rows} - {"REL", "O3"})
    if bad_order:
        raise TsvShapeError(f"{tsv}: order {bad_order} -- the rank refers to O3 or REL, nothing else")
    ranks = [_tsv_cell_int(r, "rank") for r in rows]
    step = ranks[1] if K > 1 else 0
    if K < 2 or step <= 0 or any(ranks[i] != i * step for i in range(K)):
        raise TsvShapeError(f"{tsv}: rank is not the lattice r_i = i * floor(N/K) (r_0 = 0, r_i = i * r_1, "
                            f"r_1 > 0) over K = {K} rows")

    def _num(r, c):
        try:
            v = float(r[c])
        except ValueError:
            v = float("nan")
        if not math.isfinite(v):
            raise TsvShapeError(f"{tsv}: row i={r['i']}: column {c!r} = {r[c]!r} is not a finite number")
        return v
    for i, r in enumerate(rows):
        xv, want = _num(r, "x"), ranks[i] / (K * step)
        if not (0.0 <= xv < 1.0) or abs(xv - want) > want / step + 1e-15:
            raise TsvShapeError(f"{tsv}: row i={i}: x = {r['x']} but rank / N = {want!r} for this K = {K} "
                                f"grid (N in [K*r_1, K*r_1 + K - 1]) -- the abscissa is not rank / N, "
                                f"or the grid lost rows")
    # `kw_<observable>` carries King Wen's value for that observable and is a
    # REFERENCE LINE, not a panel of its own.  viz/ holds no analysis: the value
    # arrives in the TSV from the emitter, and where the column is absent the
    # panel simply has no reference line -- it is never invented here.
    obs = [c for c in rows[0] if c not in skip and not c.startswith("kw_")]
    vals = {c: [_num(r, c) for r in rows] for c in rows[0] if c not in skip}   # Q-893: numbers, then constancy
    orders = sorted({r["order"] for r in rows})
    if len(orders) > 1:
        print(f"SKIP V3 spectrum: {tsv} mixes orders {orders} — one TSV per order "
              f"(viz_kc_spectrum.md); a mixed panel is a labelling error")
        return False
    # viz_kc_spectrum.md rule 1, verbatim: "An observable with one value carries
    # no spectrum; drop it or label it CONSTANT rather than plotting a flat line."
    # A flat panel for a C5-forced observable such as `linechanges` reads as
    # evidence that the rank index is arbitrary, when it is only evidence that the
    # observable is constant on the whole space -- the exact misreading that page
    # is written to prevent.  Constant columns are therefore DROPPED and named.
    const = [c for c in obs if len(set(vals[c])) == 1]
    if const:
        print(f"V3 spectrum: dropped CONSTANT observable(s) "
              f"{', '.join(f'{c}={rows[0][c]}' for c in const)} "
              f"(viz_kc_spectrum.md rule 1 -- a flat panel would be read as a "
              f"statement about the rank index, and it is not one)")
        obs = [c for c in obs if c not in const]
    if not obs:
        print(f"SKIP V3 spectrum: {tsv} carries no VARYING observable "
              f"({len(const)} constant column(s)) -- nothing to plot")
        return False
    x = [float(r["x"]) for r in rows]
    ncol = 3
    # Q-899 (Codex VIZ H10): the reading key goes in the grid's empty cells (two of them, at seven
    # panels); when the panels fill every row, one more row is added to hold it.
    nrow = (len(obs) + ncol - 1) // ncol + (1 if len(obs) % ncol == 0 else 0)
    # VIZ1 F18 (2026-09-26): 10 in wide (was 13) and no text under 10 pt -- see INLINE_PX.
    fig, axes = plt.subplots(nrow, ncol, figsize=(10, 3.1 * nrow + 0.9), dpi=150, squeeze=False)
    from matplotlib.ticker import MaxNLocator
    marked = 0
    for idx, name in enumerate(obs):
        a = axes[idx // ncol][idx % ncol]
        a.plot(x, [float(r[name]) for r in rows], ".", ms=2, color="#1f77b4")
        # viz_kc_spectrum.md: King Wen's value for the observable, drawn as a
        # horizontal reference line WHERE THE TSV SUPPLIES ONE (`kw_<name>`).
        ref = "kw_" + name
        if ref in rows[0]:
            kv = set(vals[ref])
            if len(kv) != 1:
                print(f"SKIP V3 spectrum: {tsv} column {ref} is King Wen's value for "
                      f"{name} and must be constant down the grid; got {len(kv)} "
                      f"distinct values -- that is a labelling error, not a spectrum")
                plt.close(fig)
                return False
            a.axhline(float(rows[0][ref]), color="#d62728", ls="--", lw=1.0)
            marked += 1
        # Q-899 (Codex VIZ H09): display label over schema name; integer-valued panels get integer
        # ticks (a 0/1/2 count was ticked at 0.2 steps).
        a.set_title(_V3_DISPLAY.get(name, (name,))[0] + "\n" + name
                    + ("  · dashed: King Wen" if ref in rows[0] else ""), fontsize=10.5)
        if all(float(v).is_integer() for v in vals[name]):
            a.yaxis.set_major_locator(MaxNLocator(integer=True))
        a.grid(True, ls=":", alpha=0.4)
        a.tick_params(labelsize=10)
        # 2026-09-24: the x axis carried NO label on any panel -- "x = rank / N" lived only
        # in the suptitle.  Label the bottom panel of every column.
        if idx + ncol >= len(obs):
            a.set_xlabel("x = rank / N", fontsize=10.5)
    for idx in range(len(obs), nrow * ncol):
        axes[idx // ncol][idx % ncol].axis("off")
    # 2026-09-24: the dropped constants are NAMED (TR-12 §2's caption says they are "named in
    # the subtitle"; the subtitle gave only a count), and the panels WITHOUT a line are named
    # too, so a missing line cannot be read as a missing value.  Wrapped onto lines: one line
    # of all of this widened the canvas.
    unmarked = [c for c in obs if "kw_" + c not in rows[0]]
    # Q-893 (2026-09-28): the clause below said EVERY unmarked panel measures similarity TO King Wen.
    # That is true of the four KW-anchored observables solve.py --v3-spectrum deliberately writes no
    # kw_* column for (viz_kc_spectrum.md, "Four panels carry no King Wen line, on purpose") and false
    # of any other panel whose kw_* column is simply absent. Only those four get the clause; any other
    # unmarked panel is named as having no reference supplied. With only the four unmarked -- the
    # committed table -- the sentence is unchanged, word for word.
    anchored = [c for c in unmarked if c in _V3_KW_ANCHORED]
    other = [c for c in unmarked if c not in _V3_KW_ANCHORED]
    # Q-899 (Codex VIZ H10, 2026-09-28): THE HEADING ASKS THE QUESTION; THE KEY HOLDS THE REST. The
    # suptitle was eight lines and 85 words -- reference-line exclusions and dropped constants
    # ahead of the question the figure answers -- while two panel cells stood empty. The heading is
    # now the question, the lattice, the space and N (VIZ1 F21's space label kept); the Q-893
    # reference-line sentence (unchanged, word for word), the dropped constants, and a definition of
    # every drawn observable move into the empty cells as a reading key.
    _rel = " (REL = reverse-exit lexicographic order)" if orders[0] == "REL" else ""
    _sup = [f"V3 — does {orders[0]} rank track these observables?",
            f"{len(rows):,}-point {orders[0]} lattice{_rel}; index over C1C2C4C5-SUPERSPACE; C3 not imposed; "
            f"x = rank / N, N = |C1∩C2∩C4∩C5|"]
    _key = [(f"dashed red = King Wen's value, on {marked}/{len(obs)} panels; no line on "
             f"{', '.join(unmarked)}; the TSV supplies no King Wen value for those: they "
             f"measure similarity TO King Wen, so its value is extreme by construction "
             f"(viz_kc_spectrum.md)"
             if marked and unmarked and not other else
             f"dashed red = King Wen's value, on {marked}/{len(obs)} panels; no line on "
             f"{', '.join(unmarked)}; "
             + (f"{', '.join(anchored)} measure similarity TO King Wen, so its value is extreme "
                f"by construction (viz_kc_spectrum.md); " if anchored else "")
             + f"no King Wen reference supplied for {', '.join(other)}"
             if marked and other else
             f"dashed red = King Wen's value, on all {marked} panels" if marked else
             "no kw_* reference values in this TSV — no King Wen line drawn")]
    if const:
        _key.append(f"dropped as CONSTANT on the whole grid (no spectrum to draw): "
                    f"{', '.join(f'{c} = {rows[0][c]}' for c in const)}")
    _key += [_V3_DISPLAY[c][1] for c in obs if c in _V3_DISPLAY]
    fig.suptitle("\n".join(textwrap.fill(t, 88, break_on_hyphens=False) for t in _sup),
                 fontsize=12)
    fig.tight_layout()
    # The key spans the empty cells of the last row, from the first empty one to the right edge.
    first = len(obs) % ncol if len(obs) % ncol else 0
    ka = axes[nrow - 1][first]
    kx0 = ka.get_position().x0
    kx1 = axes[nrow - 1][ncol - 1].get_position().x1
    wrap = max(30, int((kx1 - kx0) * fig.get_figwidth() * 72.0 / (0.55 * 10)))
    ka.text(0.0, 1.0, "\n".join(textwrap.fill(t, wrap, break_on_hyphens=False,
                                              subsequent_indent="   ") for t in ["KEY"] + _key),
            transform=ka.transAxes, ha="left", va="top", fontsize=10, color="#222222",
            linespacing=1.25, clip_on=False)
    save(fig, "fig_tr12_kc_spectrum", _prov(tsv))
    return True


# ---------------------------------------------------------------------------
# N-2 — THE f·g MECHANISM (spec: viz/archive/viz_narrative.md §"Figure N-2"), §§4-5.
#
# Job: show how the forward and backward ladders meet — that a count at layer k
# is a product of what ARRIVES from one end and what DEPARTS from the other,
# and that this is why an exact count is possible without enumeration.
#
# 🔴 THE SPEC'S STATED FAILURE MODE: "the figure must not imply the ladders are
# SAMPLED. The mechanism is exact; a drawing that suggests estimation would
# undercut the very claim it is illustrating." Three things are done about that,
# none of them decorative: (i) the identity is drawn as a SUM OVER EVERY STATE
# in the layer, with the words "every" and "exact" carried in the panel itself;
# (ii) the evidence cited is reports/KC_G_CHECK_n31.txt, which checks the
# identity at all 32 layers with 0 failing layers, so the claim is a receipt
# rather than an assertion; (iii) the lower panel plots PUBLISHED EXACT
# INTEGERS from reports/tr12/q3_profile_kw.tsv -- no fit, no smoothing, no error band,
# because there is no error to band.
#
# TWO INDEX CONVENTIONS EXIST AND ARE DELIBERATELY NOT MIXED. The ladder
# convention (documentation/GT_LADDER_FORMAT.md) has layers k = 0..31, layer k
# holding states with popcount(mask) = k -- that is the top panel. The walk
# convention (reports/tr12/q3_profile_kw.tsv, viz/viz_kc_shells.md) indexes the 31 FREE
# placements as step 1..31 -- that is the bottom panel. The bottom panel's
# caption says which it is using.
# ---------------------------------------------------------------------------
@_shape_guarded("N-2 f·g mechanism")
def fig_viz_narrative_n2_fg_mechanism(tsv=None):
    if tsv is None:
        tsv = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..",
                           "reports", "tr12", "q3_profile_kw.tsv")
    if not os.path.exists(tsv):
        return _missing(tsv, "N-2 f·g mechanism",
                        how="python3 solve.py --atlas-queries ATLAS.json --atlas-out DIR --atlas-q3-trace TRACE; "
                            "the published copy is reports/tr12/q3_profile_kw.tsv")
    # f and g are exact 192-bit decimal STRINGS; they are never float()-ed, only
    # placed on a log axis by digit count (_log10_bigint), as in V4.
    rows = _read_tsv(tsv, required=("step", "f", "g"))
    _check_grid(rows, ("step",), tsv)
    steps = [_tsv_cell_int(r, "step") for r in rows]
    lf = [_log10_bigint(r["f"]) for r in rows]
    lg = [_log10_bigint(r["g"]) for r in rows]

    # VIZ1 F18 (2026-09-26): 10 in wide (was 13.5) and no text under 10 pt -- see INLINE_PX.
    fig, (ax, ax2) = plt.subplots(2, 1, figsize=(10, 12.5), dpi=150,
                                  gridspec_kw={"height_ratios": [3.6, 4]})

    # ---- panel A: the mechanism ------------------------------------------
    ax.set_xlim(0, 31)
    ax.set_ylim(0.2, 9.5)
    ax.axis("off")
    KCUT = 17
    for k in range(32):                      # the 32 layers, k = 0..31
        ax.plot([k, k], [3.9, 4.9], color="#d0d0d0", lw=1.0, zorder=1)
    ax.plot([0, 31], [4.4, 4.4], color="#bdbdbd", lw=1.2, zorder=1)
    ax.plot([KCUT, KCUT], [3.1, 5.7], color="#6a1b9a", lw=2.4, zorder=4)
    # Below the axis on purpose: above it this label lands on the identity's
    # second line, and a caption that overprints the equation it explains is
    # worse than no caption (measured -- the first render did exactly that).
    ax.text(KCUT, 2.95, "one layer k —\na cut across every walk", ha="center", va="top",
            fontsize=10.5, color="#4a148c")

    ax.annotate("", xy=(KCUT - 0.35, 4.4), xytext=(0.3, 4.4),
                arrowprops=dict(arrowstyle="-|>", color="#1f77b4", lw=3.0, alpha=0.85))
    ax.annotate("", xy=(KCUT + 0.35, 4.4), xytext=(30.7, 4.4),
                arrowprops=dict(arrowstyle="-|>", color="#e07b00", lw=3.0, alpha=0.85))
    ax.text(KCUT / 2, 4.85, "f — the FORWARD ladder,\nbuilt k = 0 → 31", ha="center",
            fontsize=11, color="#14567f")
    ax.text(KCUT / 2, 3.75, "f(s) = the exact number of valid\nPREFIXES that reach state s",
            ha="center", va="top", fontsize=10.5, color="#14567f")
    ax.text((KCUT + 31) / 2, 4.85, "g — the BACKWARD ladder,\nbuilt k = 31 → 0", ha="center",
            fontsize=11, color="#9a5500")
    ax.text((KCUT + 31) / 2, 3.75, "g(s) = the exact number of\nCOMPLETIONS from state s",
            ha="center", va="top", fontsize=10.5, color="#9a5500")
    ax.text(0.2, 2.2, "k = 0\n(empty prefix)", ha="left", fontsize=10, color="#555555")
    ax.text(30.8, 2.2, "k = 31\n(a complete walk)", ha="right", fontsize=10, color="#555555")

    ax.text(15.5, 9.35,
            "Every complete walk crosses every layer EXACTLY ONCE. So a walk through state s is a\n"
            "prefix that reaches s paired with a completion that leaves it — and the number of\n"
            "walks through s is the PRODUCT f(s)·g(s). Summing that product over every state in\n"
            "the layer counts every walk in the space, once:",
            ha="center", va="top", fontsize=10.5, color="#333333")
    ax.text(15.5, 7.05,
            "Σ over EVERY state s in layer k:   orbit(mask(s)) · f(s) · g(s)   =   N",
            ha="center", va="top", fontsize=12.5, color="#4a148c", family="monospace")
    ax.text(15.5, 6.4, "— and this holds at every one of the 32 layers, k = 0 … 31",
            ha="center", va="top", fontsize=10.5, color="#4a148c")
    ax.text(15.5, 1.2,
            "NOTHING HERE IS SAMPLED, ESTIMATED OR FITTED. The sum runs over every state in the\n"
            "layer, the values are exact 192-bit integers, and the identity is CHECKED:\n"
            "reports/KC_G_CHECK_n31.txt evaluates it at all 32 layers and reports 0 failing layers.\n"
            "This is why N can be COMPUTED from a completed ladder in seconds rather than counted\n"
            "— the enumerator never has to visit the walks in order to count them.",
            ha="center", va="top", fontsize=10.5, color="#333333")

    # ---- panel B: the two ladders as published exact integers -------------
    ax2.plot(steps, lf, "-o", ms=4, lw=1.8, color="#1f77b4",
             label="f — valid prefixes reaching King Wen's state (exact)")
    ax2.plot(steps, lg, "-o", ms=4, lw=1.8, color="#e07b00",
             label="g — completions remaining from it (exact)")
    ax2.set_xlim(0.5, 31.5)
    ax2.set_xticks(range(1, 32))
    ax2.tick_params(axis="x", labelsize=10)
    ax2.tick_params(axis="y", labelsize=10)
    ax2.set_xlabel("step i — King Wen's 31 free placements (C4 pins the first pair-slot);\n"
                   "step i arrives at ladder layer k = i", fontsize=11)
    ax2.set_ylabel("log10 of the exact count", fontsize=10.5)
    ax2.set_title("the same two quantities as PUBLISHED EXACT INTEGERS, along King Wen's own\n"
                  "walk — f rises as prefixes accumulate, g falls as freedom is spent",
                  fontsize=11.5)
    ax2.grid(True, ls=":", alpha=0.45)
    ax2.legend(fontsize=10.5, loc="center left")
    ax2.set_facecolor("#f8f8f8")
    ax2.text(8.5, 28.5,
             "⚠ This panel is ONE walk. For a single state, f(s)·g(s)\nis the number of walks "
             "THROUGH THAT STATE — it is not N.\nOnly the sum over the whole layer, in the panel "
             "above,\nequals N.",
             ha="left", fontsize=10.5, color="#8b1a1a")

    fig.suptitle("N-2 — the f·g mechanism: how an exact count is COMPUTED rather than\n"
                 "counted, over the C1C2C4C5-SUPERSPACE\n"
                 "N = |C1∩C2∩C4∩C5| = 1,097,051,278,789,181,790,036,112,071,176,579,186,688\n"
                 "— C3 is not among its constraints, and neither are C6/C7",
                 fontsize=13)
    fig.tight_layout(rect=(0, 0, 1, 0.93))
    save(fig, "viz_narrative_n2_fg_mechanism",
         _prov(tsv) + "  identity: reports/KC_G_CHECK_n31.txt  "
         "semantics: documentation/GT_LADDER_FORMAT.md  spec: viz/archive/viz_narrative.md §N-2")
    return True


def _tr12_q3_table(root):
    """The Q3 profile V4 should draw from `root`, chosen by its SIDECAR. -> (path | None, why).

    🔴 Q-766 (RCQ02 F5, CONFIRMED 2026-09-09, fixed 2026-09-24). This used to be
    `q3_profile_kw.tsv if it exists else q3_profile.tsv` -- selection by EXISTENCE. A reused
    output directory that had held a King Wen full-31 run kept that run's q3_profile_kw.tsv after
    a later n=9 run wrote q3_profile.tsv beside it, and the old KW profile was drawn as the new
    run's. The name is a claim; the sidecar `solve.py` writes beside it
    (`q3_is_king_wen=`, `q3_table=`) is the evidence for the claim, so the KW table is taken only
    when its own sidecar says q3_is_king_wen=PASS for that table. The emitter now removes the
    other name (solve.py atlas_emit_q3), so both names present at once means a directory written
    by an older emitter: that is refused, never guessed.

    One exception, stated rather than hidden: a directory with NO sidecar at all -- neither name's
    -- was not written by an atlas consumer that emits them. The committed `reports/tr12/` tree is such a
    directory (it ships q3_profile_kw.tsv and no sidecar), so there the KW name is still taken as
    written. Any consumer run writes a sidecar, so a reused --atlas-out never reaches this branch.

    BOUND TO THE BYTES (lane VR4, 2026-09-28; Codex VIZ A4-01). A PASS sidecar named its table but
    not its content, so a KW table edited or replaced after the consumer wrote it kept its PASS. The
    emitter now writes `q3_table_sha256=` (solve.py atlas_emit_q3), and the KW table is taken only
    when that digest equals the sha256 of the table's bytes: a PASS sidecar without the digest (an
    older emitter) or with another one is refused. A plain table's sidecar that carries a digest must
    match it too; one without a digest is accepted, since the plain name claims nothing.
    """
    import hashlib

    def _unbound(table, fields):
        want = fields.get("q3_table_sha256")
        with open(table, "rb") as fh:
            have = hashlib.sha256(fh.read()).hexdigest()
        if want == have:
            return None
        return ("carries no q3_table_sha256" if want is None else
                "records q3_table_sha256=%s but the table's sha256 is %s" % (want, have))

    def _fields(side):
        out = {}
        with open(side, encoding="utf-8") as fh:
            for line in fh:
                k, sep, v = line.rstrip("\n").partition("=")
                if sep:
                    out[k] = v
        return out
    kw = os.path.join(root, "q3_profile_kw.tsv")
    plain = os.path.join(root, "q3_profile.tsv")
    have_kw, have_plain = os.path.exists(kw), os.path.exists(plain)
    if have_kw and have_plain:
        return None, ("both q3_profile_kw.tsv and q3_profile.tsv are in %s: a reused output "
                      "directory, and which one is current cannot be told from the names -- "
                      "re-run the consumer into a clean directory" % root)
    if not have_kw:
        # Q-810 (2026-09-25): this returned `plain` whether or not it existed, so a directory
        # with neither table got a path to a nonexistent file and an empty reason.
        if not have_plain:
            return None, ("neither q3_profile_kw.tsv nor q3_profile.tsv is in %s: there is no "
                          "Q3 profile to draw -- produce it with `solve.py --atlas-queries "
                          "ATLAS.json --atlas-out DIR --atlas-q3-trace TRACE`, where TRACE is `solve --kc-o3-rank FDIR GDIR WALK --kc-trace` text or a `solve --kc-profile FDIR GDIR WALK --kc-tsv` table; the published n=31 trace is reports/tr12/q3_trace_kw.txt" % root)
        pside = plain + ".provenance.txt"
        if os.path.exists(pside):
            pf = _fields(pside)
            if "q3_table_sha256" in pf and _unbound(plain, pf):
                return None, ("%s: its sidecar %s -- the sidecar is not this table's; re-run the "
                              "consumer into a clean directory" % (plain, _unbound(plain, pf)))
        return plain, ""
    side = kw + ".provenance.txt"
    if os.path.exists(side):
        fields = _fields(side)
        if fields.get("q3_is_king_wen") == "PASS" and fields.get("q3_table") == "q3_profile_kw.tsv":
            why = _unbound(kw, fields)
            if why is None:
                return kw, ""
            return None, ("%s: its sidecar reads q3_is_king_wen=PASS but %s -- the King Wen claim "
                          "is not bound to these bytes; re-run the consumer into a clean directory"
                          % (kw, why))
        return None, ("%s is present but its sidecar reads q3_is_king_wen=%s, q3_table=%s -- "
                      "the King Wen name is not backed by its own provenance"
                      % (kw, fields.get("q3_is_king_wen"), fields.get("q3_table")))
    if os.path.exists(plain + ".provenance.txt"):
        return None, ("%s has no sidecar, but q3_profile.tsv's sidecar is in the same directory: "
                      "the KW table is a leftover of an earlier run" % kw)
    return kw, ""


def tr12_figures(root=None):
    """Render V1..V5 from the atlas-consumer TSVs rooted at `root`.

    `root` defaults to the repository's own reports/tr12/ directory, resolved from this file's location
    (VIZ1 F20, 2026-09-26: it defaulted to the CWD-relative "tr12", which from the documented
    working directory reports/figures/ named a directory that does not exist).

    Returns True when every REQUIRED figure rendered, False otherwise, and raises
    RuntimeError so a caller taking only the process exit status still fails.

    CODEX KCP1 FINDING 6/7 (2026-09-11).  This function called each renderer and
    DISCARDED ITS RETURN VALUE.  The shape guards added for Q-307 do their job --
    they return False on malformed input -- and nothing read the answer, so the
    battery's `python3 -c "...tr12_figures(...)"` exited 0 and row c_viz recorded
    TR12_VIZ=PASS over a figure that had explicitly refused to render.  Measured by
    the reviewer with a header-only V1 input: FIGURE_SHAPE=FAIL printed, return
    None, no exception, rc 0.  At n=31 that publishes a missing figure as a present
    one -- and a re-used output directory keeps the PREVIOUS run's image beside the
    new run's PASS, which is worse than an absent figure because it looks answered.

    V3 (spectrum) stays OPTIONAL WHEN ABSENT (Q-893, 2026-09-28: a PRESENT V3 table that the
    renderer refuses now fails the run like a required figure): its input is a rank
    grid joined to per-walk functionals by `solve.py --v3-spectrum` (2026-09-23),
    which scripts/tr12_repro.sh runs at n=31 only (row c_v3_join, Q-430, 2026-09-25)
    and the atlas consumer never runs -- so at n<31 the input is absent by design and
    TR12_V3_FIG=SKIP:reduced-universe.  Making it required here would be a gate
    that cannot be satisfied.

    PATH (2026-09-24).  The spec path is <root>/spectrum/v3_spectrum.tsv, but the
    COMMITTED table is reports/tr12/v3_spectrum.tsv (no spectrum/ level), so
    tr12_figures("tr12") silently skipped the one V3 input the repo ships.  The
    flat path is now a FALLBACK, taken only when the spec path is absent and the
    flat file exists -- when neither exists the message still names the spec path,
    so the battery's c_viz output is unchanged.
    """
    if root is None:
        root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "reports", "tr12")
    scan = os.path.join(root, "scan")
    q3, q3_why = _tr12_q3_table(root)
    # Q-892 (2026-09-28): the universe size n every layer inventory is checked against -- the Q3
    # sidecar's atlas_n when the consumer wrote one, else the Q3 table's own step count (V4 refuses
    # that table unless its last step leaves g = 1, so a truncated one cannot set a smaller n).
    # None when there is no Q3 table: the renderers then check what they can without it.
    n = None
    if q3 is not None:
        try:
            with open(q3 + ".provenance.txt", encoding="utf-8") as fh:
                n = int(dict(l.rstrip("\n").partition("=")[::2] for l in fh).get("atlas_n", ""))
        except (OSError, ValueError):
            try:
                with open(q3, encoding="utf-8") as fh:
                    n = sum(1 for l in fh if l.strip()) - 1
            except OSError:
                n = None

    def _v4():
        if q3 is None:
            print("[tr12_figures] V4 refused: %s" % q3_why)
            return False
        return fig_tr12_kc_shells(q3, n=n)
    required = [
        ("V1", lambda: fig_tr12_kc_field(os.path.join(scan, "v1_field.tsv"), n=n)),
        ("V2", lambda: fig_tr12_kc_river(os.path.join(scan, "v2_river.tsv"),
                                         os.path.join(scan, "v2_branches.tsv"), n=n)),
        ("V5", lambda: fig_tr12_kc_grammar(os.path.join(scan, "v5_grammar.tsv"), n=n)),
        ("V4", _v4),
    ]
    failed = []
    for name, call in required:
        got = call()
        # A renderer that returns None has not been converted to the guarded form;
        # treat only an explicit False as refusal, so this cannot silently demand
        # a contract the renderers do not yet have.
        if got is False:
            failed.append(name)
    v3 = os.path.join(root, "spectrum", "v3_spectrum.tsv")
    if not os.path.exists(v3) and os.path.exists(os.path.join(root, "v3_spectrum.tsv")):
        v3 = os.path.join(root, "v3_spectrum.tsv")
    opt = fig_tr12_kc_spectrum(v3)
    if opt is False and os.path.exists(v3):
        # Q-893 (2026-09-28): a V3 table that is PRESENT and refused was discarded here like an
        # absent one, so the run returned True over a FIGURE_SHAPE=FAIL (and could leave an older
        # spectrum image in place). Present-and-refused is now a failure of the run. ABSENT stays
        # optional and silent: the battery's own TR12_V3_FIG row reports it, and a line here would
        # move the n=9 golden c_viz.txt.
        failed.append("V3")
    # 🔴 SILENT ON SUCCESS. The first version of this fix printed TR12_FIGURES=OK, which moved
    # the n=9 golden c_viz.txt and turned TR12_VIZ into FAIL:output-mismatch -- caught by the
    # stamp, not by me. Every content guard in this battery prints NOTHING when it passes, for
    # exactly this reason: a check that changes the output it guards cannot be added without
    # re-minting the thing it is supposed to protect. Failure is loud; success is invisible.
    if failed:
        print("TR12_FIGURES=FAIL required=%s" % ",".join(failed))
        raise RuntimeError("required figure(s) refused to render: %s" % ",".join(failed))
    return True


def _selftest():
    """`python3 viz/report_figures.py --selftest` -- prove the Q-307 guards FIRE.

    A shape check that has never been shown to refuse anything is indistinguishable
    from no shape check.  Every arm below builds a synthetic TSV in a temp dir,
    renders into that dir, and asserts the verdict; the GREEN arm proves the guards
    do not fire on a well-formed table, which is the half that keeps this from
    becoming the always-fails check the project has had to delete before.

    Emits VIZ_SHAPE_SELFTEST=PASS or =FAIL.  Gate on that whole line, never on
    output shape."""
    import tempfile, itertools, io as _io, contextlib, hashlib
    KS, PS = range(0, 6), range(0, 32)      # Q-892: all 32 global pair rows, as the spec requires

    def field_rows(pairs):
        out = ["k\tslot\tpair\tmass\tp\tkw"]
        for k, j in pairs:
            out.append(f"{k}\t{k+2}\t{j}\t1000\t{1.0/len(PS):.6f}\t{1 if j == k else 0}")
        return "\n".join(out) + "\n"

    full = list(itertools.product(KS, PS))
    cases = []            # (name, tsv text, want_ok, want_substr)
    cases.append(("GREEN complete 6x32 grid", field_rows(full), True, "Saved"))
    cases.append(("RED  truncated write (last 3 cells lost)",
                  field_rows(full[:-3]), False, "the table is incomplete"))
    cases.append(("RED  duplicated append",
                  field_rows(full + full[:2]), False, "duplicate index tuple"))
    cases.append(("RED  torn final line",
                  field_rows(full)[:-14], False, "torn or mis-delimited"))
    cases.append(("RED  required column absent",
                  field_rows(full).replace("\tkw\n", "\tkwx\n", 1),
                  False, "missing required column"))
    cases.append(("RED  hole punched in k (rectangular but not contiguous)",
                  field_rows([c for c in full if c[0] != 3]), False, "not contiguous"))
    cases.append(("RED  header only", "k\tslot\tpair\tmass\tp\tkw\n",
                  False, "0 data rows"))
    cases.append(("RED  empty file", "", False, "file is empty"))
    # Q-894 (2026-09-28): arms for the guards this self-test did not exercise.
    cases.append(("RED  duplicate header column",
                  field_rows(full).replace("\tkw\n", "\tp\n", 1), False, "header repeats column"))
    _ft = field_rows(full)
    _cut = _ft.index("\n", len(_ft) // 2) + 1          # a row of five tabs: the header's width, no data
    cases.append(("RED  whitespace-only row inside the table",
                  _ft[:_cut] + "\t" * 5 + "\n" + _ft[_cut:], False, "whitespace-only row"))
    cases.append(("RED  lowest layer removed whole (k = 0)",
                  field_rows([c for c in full if c[0] != 0]), False, "not the expected inventory"))
    cases.append(("RED  one pair row removed whole (pair 31)",
                  field_rows([c for c in full if c[1] != 31]), False, "not the expected inventory"))
    # lane VR4 (Codex VIZ A4-04): a probability that is not one is refused, not drawn.
    cases.append(("RED  p = nan in one cell",
                  field_rows(full).replace("\t0.031250\t", "\tnan\t", 1), False, "is not finite"))

    fails = []
    d = tempfile.mkdtemp(prefix="viz_selftest_")
    cwd = os.getcwd()
    try:
        os.chdir(d)
        for name, text, want_ok, want in cases:
            open("t.tsv", "w").write(text)
            buf = _io.StringIO()
            with contextlib.redirect_stdout(buf):
                got_ok = fig_tr12_kc_field("t.tsv")
            out = buf.getvalue()
            ok = (bool(got_ok) == want_ok) and (want in out)
            print(f"  [{'ok' if ok else 'FAIL'}] {name}")
            if not ok:
                fails.append(name)
                print(f"        returned {got_ok!r}, wanted {want_ok!r}; "
                      f"looked for {want!r} in:\n        {out.strip()[:400]}")
        # PROVENANCE: the footer must be a FUNCTION OF THE BYTES, and must not
        # move when the bytes do not.  A stamp that is constant across sources
        # binds nothing; a stamp that changes on a re-read of the same file
        # destroys byte-comparability.  Both directions are checked.
        open("a.tsv", "w").write(field_rows(full))
        open("b.tsv", "w").write(field_rows(full).replace("\t1000\t", "\t1001\t", 1))
        pa, pa2, pb = _prov("a.tsv"), _prov("a.tsv"), _prov("b.tsv")
        # Q-894 (2026-09-28): the "moves" arm compared a.tsv with b.tsv, so a digest replaced by a
        # constant still passed (the basenames differ). Same pathname, one byte changed, and the
        # stamp must be the expected sha256 prefix of the bytes on BOTH sides.
        one = field_rows(full).encode()
        two = one.replace(b"\t1000\t", b"\t1001\t", 1)
        open("c.tsv", "wb").write(one)
        pc1 = _prov("c.tsv")
        open("c.tsv", "wb").write(two)
        pc2 = _prov("c.tsv")
        want1, want2 = (hashlib.sha256(b).hexdigest()[:12] for b in (one, two))
        for cond, name in ((pa == pa2, "provenance is stable across re-reads"),
                           (pa != pb, "provenance moves when one byte moves"),
                           (one != two and want1 != want2
                            and pc1 == f"source: c.tsv@{want1}   (viz/report_figures.py)"
                            and pc2 == f"source: c.tsv@{want2}   (viz/report_figures.py)",
                            "same pathname: the stamp is the sha256 prefix of the bytes, before and after"),
                           ("ABSENT" in _prov("nope.tsv"), "absent source says ABSENT"),
                           (":" not in pa.split("@")[1][:12], "stamp is a bare hex digest")):
            print(f"  [{'ok' if cond else 'FAIL'}] {name}")
            if not cond:
                fails.append(name)
        # V3 CONSTANT-OBSERVABLE arm (viz_kc_spectrum.md rule 1).
        head = "i\trank\tx\torder\twalk\tvarying\tlinechanges"
        rowsv = [f"{i}\t{i*7}\t{i/8.0}\tO3\t0,1\t{i}\t20" for i in range(8)]
        open("v3.tsv", "w").write(head + "\n" + "\n".join(rowsv) + "\n")
        buf = _io.StringIO()
        with contextlib.redirect_stdout(buf):
            r = fig_tr12_kc_spectrum("v3.tsv")
        out = buf.getvalue()
        cond = bool(r) and "dropped CONSTANT observable(s) linechanges=20" in out
        print(f"  [{'ok' if cond else 'FAIL'}] V3 drops a constant observable and names it")
        if not cond:
            fails.append("V3 constant drop")
            print(f"        {out.strip()[:400]}")
        rowsc = [f"{i}\t{i*7}\t{i/8.0}\tO3\t0,1\t20\t20" for i in range(8)]
        open("v3c.tsv", "w").write(head + "\n" + "\n".join(rowsc) + "\n")
        buf = _io.StringIO()
        with contextlib.redirect_stdout(buf):
            r = fig_tr12_kc_spectrum("v3c.tsv")
        out = buf.getvalue()
        cond = (r is False) and "no VARYING observable" in out
        print(f"  [{'ok' if cond else 'FAIL'}] V3 refuses a table with nothing but constants")
        if not cond:
            fails.append("V3 all-constant refusal")
            print(f"        {out.strip()[:400]}")
    finally:
        os.chdir(cwd)
    print(f"VIZ_SHAPE_SELFTEST={'FAIL' if fails else 'PASS'}")
    return 1 if fails else 0



def _tsv_cell_int(r, c):
    """One integer cell of an atlas-consumer TSV, read with solve.py's strict `_tsv_int`.

    int() also read "+5", " 5", "5\\n", "1_0" (= 10), "05" and non-ASCII digits as the number
    they respell, so a hand-edited or corrupted table drew a plausible figure.  A cell that is
    not an integer as the writer spells one is a TsvShapeError: the figure is refused with
    FIGURE_SHAPE=FAIL (`_shape_guarded`), not drawn.  Follow-up to CX-159 (lane EI, 2026-09-26)."""
    try:
        return _tsv_int(r[c], "column %r" % c)
    except ValueError as e:
        raise TsvShapeError(str(e))


# Q-862 (2026-09-27). The matplotlib version the committed figures were rendered with. Every
# reports/figures/*.svg records it (`Matplotlib v3.11.0` in its metadata), and a test in tests.py
# holds this constant equal to that stamp, so the pin cannot drift from the artefacts. Under
# 3.11.0 a re-render reproduced all ten committed PNGs byte-identically; under 3.6.3 none matched  (note 2026-09-27: "all ten" was every PNG the generator drew on that date; it now draws twelve, TR-5 and TR-7 added by Q-858 -- viz/README.md records the twelve-of-twelve re-render)
# (CX-192). A mismatch is REPORTED, never fatal, and only by the command-line entry point, on
# stderr: tr12_figures() and save() stay silent about it, because the n=9 reproduction battery
# (scripts/tr12_repro.sh row c_viz) calls tr12_figures() directly with stdout AND stderr captured
# into a golden-diffed file, and runs under whatever matplotlib the host has.
EXPECTED_MATPLOTLIB = "3.11.0"


def _mpl_version_note(have):
    """None when `have` is EXPECTED_MATPLOTLIB, else the one stderr line the CLI prints."""
    if have == EXPECTED_MATPLOTLIB:
        return None
    return ("MPL_VERSION=MISMATCH have=%s expected=%s -- PNG bytes will not match the "
            "committed figures" % (have, EXPECTED_MATPLOTLIB))


USAGE = "usage: report_figures.py [--selftest] [--narrative] [TR12_ARTIFACT_ROOT]"


def _usage_error(why):
    print("%s\n%s" % (USAGE, why), file=sys.stderr)
    raise SystemExit(2)


def _parse_cli(argv):
    """(selftest, narrative, root) from argv[1:]. An unknown --option is a usage error (exit 2),
    not a TR-12 root: a mistyped --narrative used to be read as the artifact directory."""
    selftest = narrative = False
    pos = []
    for a in argv:
        if a == "--selftest":
            selftest = True
        elif a == "--narrative":
            narrative = True
        elif a.startswith("--"):
            _usage_error("unknown option %r" % a)
        else:
            pos.append(a)
    if len(pos) > 1:
        _usage_error("at most one TR12_ARTIFACT_ROOT, got %d" % len(pos))
    return selftest, narrative, (pos[0] if pos else None)


def main(argv):
    selftest, narrative, root = _parse_cli(argv)
    if selftest:
        return _selftest()
    # Q-862: stderr only, once, and only here -- see EXPECTED_MATPLOTLIB.
    note = _mpl_version_note(matplotlib.__version__)
    if note:
        print(note, file=sys.stderr)
    fig_tr6_parity_alternations()
    fig_tr7_circular_cycle()
    fig_tr5_orbit_collapse()
    fig_tr4_boundary_information()
    fig_tr1_rules_tradeoff()
    fig_tr3_campaign_timeline()
    # The scale figure (viz/viz_scale.md) needs no data file at all.
    fig_viz_scale()
    # The narrative document's two figures (viz/archive/viz_narrative.md) are HELD and not
    # committed, so they are opt-in (Q-862). N-1 needs no data file; N-2 reads the published
    # King Wen walk profile and SKIPs cleanly when that TSV is absent.
    # lane VR4 (2026-09-28; Codex VIZ A4-05): --narrative REQUESTS both figures, so a refusal of either
    # (N-2's SKIP when its table is absent, or FIGURE_SHAPE=FAIL) fails the run: it was discarded,
    # and the command exited 0 having drawn one of the two figures it was asked for.
    refused = []
    if narrative:
        if fig_viz_narrative_n1_object() is False:
            refused.append("N-1")
        if fig_viz_narrative_n2_fg_mechanism() is False:
            refused.append("N-2")
    # TR-12 V1..V5: rendered from the atlas-consumer TSVs when they are present.
    # Root defaults to the repository's reports/tr12/ (resolved from this file, not the CWD -- VIZ1 F20);
    # override with the positional argument.
    tr12_figures(root)
    if refused:
        print("ERROR: --narrative was given and %s did not render (see the SKIP / FIGURE_SHAPE "
              "line above)" % " and ".join(refused), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
