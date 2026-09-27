#!/usr/bin/env python3
# https://github.com/petersm3/roae
# Developed with AI assistance (Claude, Anthropic)
"""
Figures for the technical-report suite (reports/TR*.md) — the "Planned improvements" figures.

Every number here is sourced from the public reports/documentation (data-source comments inline);
nothing is re-derived from enumeration data except the TR-6 parity-class string, which is computed
directly from solve.py's King Wen sequence (binary_hexagrams) exactly as TR-6/PARITY_ALTERNATION.md
define it (pair parity = popcount of the pair's hexagrams mod 2; pairs are parity-homogeneous, so the
first member suffices).

Figures produced (PNG + SVG, written to CWD — run from reports/figures/):
  fig_tr6_parity_alternations   — KW's 32-pair E/O class string with its 15 alternations marked (TR-6)
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
    cd reports/figures/ && python3 ../../viz/report_figures.py [--narrative] [TR12_ARTIFACT_ROOT]   (--narrative: also the two HELD, uncommitted narrative figures -- Q-862)

TR12_ARTIFACT_ROOT defaults to the repository's own tr12/ directory, resolved from THIS FILE's
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
    bytes that will be published, not from the artists that were asked for."""
    m = re.search(r'<svg\b[^>]*\swidth="([0-9.]+)pt"', svg)
    if not m:
        raise FigureTextFloorError("SVG carries no width in pt; the text floor cannot be measured")
    sizes = []
    for chunk in svg.split('<g id="text_')[1:]:
        s = re.search(r'scale\(([0-9.]+) -\1\)', chunk)
        if s:
            sizes.append(round(100.0 * float(s.group(1)), 4))
    return float(m.group(1)), sizes


def _text_floor_violations(width_pt, sizes):
    """The sizes that render below MIN_TEXT_PX when width_pt is displayed at INLINE_PX."""
    floor = MIN_TEXT_PX * width_pt / INLINE_PX
    return floor, sorted({s for s in sizes if s < floor - 1e-6})


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
        "V1 — positional-marginal field P(pair j at slot k), exact over C1C2C4C5-SUPERSPACE\nblue cells: King Wen's own placements (diagonal by construction —\nthe value, not the shape, is the content)",
        'global pair index',
        'pair-slot (layer k fills slot k+2)',
    ),
    'fig_tr12_kc_grammar': (
        # 2026-09-24: the title is now STATIC per branch (it was composed at runtime, which
        # left the orbit caveat as text no gate could read).  All three branch literals are
        # pinned; FIGURE_LABEL_UNCOVERED for this stem drops 1 -> 0.  2026-09-26 (VIZ1 F06): the
        # caveat's wording is corrected -- see the note at the titles in fig_tr12_kc_grammar.
        "V5 — transition grammar P(class | layer k), exact over C1C2C4C5-SUPERSPACE\nread DOWN each column (every column sums to 1)\nREDUCED FORM: this table carries no w axis (w = -1), so a row is a\ndistance class d and the white outline is King Wen's own d",
        'V5 — transition grammar P(class | layer k), exact over C1C2C4C5-SUPERSPACE\nread DOWN each column (every column sums to 1)\nno King Wen overlay in this table — kw_d/kw_w match no plotted class\nat any layer (n != 31?)',
        'V5 — transition grammar P(d, w | layer k), exact over C1C2C4C5-SUPERSPACE\nd = boundary distance to the new pair, w = within-pair distance of the new pair;\nread DOWN each column (every column sums to 1)\nThe seven pair-orbits are grouped into three within-pair-distance categories;\neach row fixes one (d,w) combination and does not identify an individual pair.',
        'layer k',
    ),
    'fig_tr12_kc_river': (
        "V2 — mass river: exact per-layer boundary-distance class mass\neach layer is a unit-width bin, so a band's AREA is its class total, fixed by\nthe C1+C5 theorem; only the shape across k is informative",
        'branch (pair : entry hexagram), sorted by mass',
        'branch panel — solution mass (bars) vs exhaustion cost (line);\nmeasured at n=31 the two are CO-MONOTONE: no branch is small-but-expensive',
        'branch share of N',
        'layer k (fills pair-slot k+2); each layer is a unit-width bin',
        'log10 exhaustion cost (t-units)',
        'share of C1C2C4C5-SUPERSPACE',
    ),
    'fig_tr12_kc_shells': (
        "V4 — King Wen's neighbourhood shells in C1C2C4C5-SUPERSPACE; C3 not imposed\nexact completions remaining after each of King Wen's 31 free placements\nEVERY point is King Wen's own trajectory — this figure plots ONE walk, not a\npopulation (annotation = # admissible alternatives)",
        "log10 g(King Wen's prefix) — completions remaining",
        'step (free placement i)',
        "the surprise spectrum — King Wen's own per-step −log2 p_i; the bars sum to\nlog2 N, N = |C1∩C2∩C4∩C5| (EW-1). A step with ONE admissible alternative costs 0 bits.",
        '−log2 p_i (bits)',
    ),
    'fig_tr12_kc_spectrum': (
        'x = rank / N',
    ),
    'fig_tr1_rules_tradeoff': (
        '0 — perfect',
        'KW keeps the trigram configuration exactly and misses the other three by two each\n(no extremal check excludes a smaller miss); the 3-edit grand precursor perfects\nthose three and breaks the trigram configuration. Both cannot be had.',
        'KW: satisfied / precursor: violated',
        "THE CONFLICT THEOREM's trade-off: the four rules cannot all be satisfied\n(jointly UNSAT under C1+C2+C4+C5, drat-trim-verified) — any ordering must choose",
        'binary rule — no graded miss count, so it is not placed on the misses scale',
        'misses (lower is better; 0 = the rule is satisfied perfectly)',
    ),
    'fig_tr3_campaign_timeline': (
        '2026, Pacific Time',
        'First 560T campaign timeline — 5 Spot evictions, all M-F\nin a 37-min window (07:12–07:49 PT), 0 on the weekend',
        'enum complete\n171.5 h wall',
        'launch\nSun 17:03 PT',
        'weekend: 0 evictions\n(~54 h clean Spot runway)',
    ),
    'fig_tr4_boundary_information': (
        'S(k) = fraction of the full C1–C5 population (orientation-explicit)\nagreeing with KW (log scale)',
        'The boundary-information curve S(k) — slice-uniqueness vs space-uniqueness\n(the first 4 of the 5 boundaries that identify KW in the 560T slice still admit ≈8.4×10²⁵ full-space orderings)',
        'k = number of King Wen boundary constraints imposed',
        'k ≈ 14: the earliest the pair-ordering\nfloor is reached IF no later boundary\ngains more than the 8th measured\none (6.14 bits). A scale marker,\nnot a bound; no far end set by the data.',
        'one ORIENTED ordering:\n1/1.3287×10³⁸ = 7.53×10⁻³⁹,\n20.71 bits lower. Pins fix pair\nidentity, not orientation, so\nno k reaches this level.',
        'reachable floor: S = 1,720,320/1.3287×10³⁸ = 1.29×10⁻³² (one surviving pair-ordering class)',
    ),
    'fig_tr6_parity_alternations': (
        'pair position 1–32, pairs 1–16 on the top row and 17–32 below (pair p = King Wen\nsequence positions 2p−1, 2p; class = popcount parity, E = even, O = odd;\nfirst pair {63, 0} is even — pinned by C4)',
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
        'N = 1,097,051,278,789,181,790,036,112,071,176,579,186,688   (exact, two-instrument; 24 | N)',
        'POINTS — d3 canonical record counts: the orderings satisfying C1–C5 that the enumerator FOUND WITHIN\nITS PER-CELL NODE BUDGET. Each canonical is an exactly-reproducible BUDGETED SLICE of C1–C5, and its\nrecord count is a LOWER BOUND on the C1–C5 population — not that population\'s size\n(documentation/SOLUTIONS_FORMAT.md).\nLINE — N = |C1∩C2∩C4∩C5|, the EXACT cardinality of the C1C2C4C5-SUPERSPACE, computed by the\nknowledge compiler from a completed ladder. C3 is NOT among its constraints, and neither are C6/C7,\nso N is not a count of C1–C5 either.\nUNITS — Points count canonical pair orderings with orientation masked; N counts orientation-explicit\nsequences. The plotted ratio is 29.0 decades; comparing pair orderings with pair orderings gives a gap\nof 19.7–23.9 decades.\nTHE GAP is between a BUDGETED SLICE and a COMPILED SUPERSPACE. It is NOT "how much of the space we\nfound": the two series do not count the same set, and no record count on this figure is a fraction\nof N. If the power law fitted to these three runs continues, reaching even the like-unit bracket would\nrequire approximately 6.4×10³⁸–1.1×10⁴⁵ nodes per cell, making enumeration infeasible under that\nextrapolation.',
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
    'fig_tr12_kc_spectrum': 2,
    'fig_tr1_rules_tradeoff': 1,
    'fig_tr3_campaign_timeline': 1,
    'fig_tr4_boundary_information': 1,
    'fig_tr6_parity_alternations': 3,
    'viz_narrative_n1_object': 3,
    'viz_narrative_n2_fg_mechanism': 0,
    'viz_scale': 2,
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
    # VIZ1 F18 (2026-09-26): TWO ROWS OF 16, not one strip of 32. As one 16-inch strip the pair
    # positions rendered at 5.9 px on a 900-px display; no font size fixes that on a canvas that
    # wide, because the viewer shrinks the whole image. Pairs 1-16 are the top row, 17-32 the
    # bottom; an alternation between pair 16 and pair 17 is marked at the END of the top row.
    ROW = 16
    RY = (1.95, 0.0)                         # bottom edge of the cells in row 0 and row 1
    fig, ax = plt.subplots(figsize=(9.2, 4.3), dpi=150)
    for i, c in enumerate(classes):
        x, y = i % ROW, RY[i // ROW]
        ax.add_patch(plt.Rectangle((x, y), 0.92, 1, facecolor=col[c],
                                   edgecolor="white", linewidth=1.2))
        ax.text(x + 0.46, y + 0.5, c, ha="center", va="center",
                fontsize=13, fontweight="bold", color="white")
        ax.text(x + 0.46, y - 0.24, str(i + 1), ha="center", va="center", fontsize=10.5,
                color="#444444")
    # alternation marks between consecutive pairs of different class
    for i in range(31):
        if classes[i] != classes[i + 1]:
            x, y = i % ROW, RY[i // ROW]
            ax.plot([x + 0.96, x + 0.96], [y - 0.05, y + 1.05], color="#d32f2f", lw=2.2, zorder=5)
            ax.plot(x + 0.96, y + 1.15, marker="v", color="#d32f2f", ms=6, zorder=5)
    ax.text(8, 3.55,
            f"King Wen's parity-class string: 16 E / 16 O, exactly {n_alt} alternations\n"
            "(red marks) — forced by C1–C5, not a design choice",
            ha="center", va="center", fontsize=12.5)
    ax.text(8, -0.78, "pair position 1–32, pairs 1–16 on the top row and 17–32 below (pair p = King Wen\n"
                      "sequence positions 2p−1, 2p; class = popcount parity, E = even, O = odd;\n"
                      "first pair {63, 0} is even — pinned by C4)",
            ha="center", va="center", fontsize=10.5, color="#444444")
    ax.set_xlim(-0.3, 16.3)
    ax.set_ylim(-1.15, 3.95)
    ax.axis("off")
    fig.tight_layout()
    save(fig, "fig_tr6_parity_alternations")


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
    # 1-31 (solve.c:41804) — so pinning is blind to the orientation layer by construction. Pin all
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

    fig, ax = plt.subplots(figsize=(10, 7), dpi=150)
    ax.set_yscale("log")

    # measured greedy points
    ax.plot(k, S, "-", color="#1f77b4", lw=1.5, alpha=0.7, zorder=4)
    ax.scatter(k, S, s=90, color="#d32f2f", zorder=5,
               label="measured S(k), greedy 560T identifying order {4, 27, 25, 21, 1}")
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
    ax.text(14.25, 1e-8, "k ≈ 14: the earliest the pair-ordering\nfloor is reached IF no later boundary\n"
                         "gains more than the 8th measured\none (6.14 bits). A scale marker,\n"
                         "not a bound; no far end set by the data.",
            fontsize=10, color="#2e7d32", ha="left")

    ax.set_xlim(0.5, 20.5)
    ax.set_ylim(1e-42, 1e-1)
    ax.set_xticks(range(1, 21))
    ax.set_xlabel("k = number of King Wen boundary constraints imposed", fontsize=12)
    ax.set_ylabel("S(k) = fraction of the full C1–C5 population (orientation-explicit)\n"
                  "agreeing with KW (log scale)", fontsize=11)
    ax.set_title("The boundary-information curve S(k) — slice-uniqueness vs space-uniqueness\n"
                 "(the first 4 of the 5 boundaries that identify KW in the 560T slice still admit "
                 "≈8.4×10²⁵ full-space orderings)", fontsize=12)
    ax.grid(True, which="both", ls=":", alpha=0.4)
    ax.legend(fontsize=10, loc="lower left")
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
    rules = [
        "Moore 2005\npair-positioning parity\n(misses of 18 testable)",
        "Moore 1989\nrising/falling rhythm\n(breaks)",
        "Schulz 1990\ngender rule\n(violations)",
        "Schulz 2011/2016\nS25–28 trigram config.\n(binary: satisfied / violated)",
    ]
    kw = [2, 2, 2]      # numeric misses on the three graded rules
    gp = [0, 0, 0]
    y = np.arange(3)[::-1]
    h = 0.34
    c_kw, c_gp = "#d32f2f", "#388e3c"

    # VIZ1 F13 (2026-09-26). Two defects, both visible in the PNG. (1) The legend sat INSIDE the
    # data axes and covered King Wen's first "2". (2) The binary trigram rule was drawn as a
    # hatched 2.6-unit bar ON THE MISSES AXIS -- a length with no count behind it, reading as
    # "2.6 misses" -- and its label ran through the hatch. The binary rule now has its OWN row
    # below the quantitative panel: an unhatched categorical text row with no bar and no scale,
    # and the legend sits outside the data axes, beneath the explanatory note.
    fig, (ax, axb) = plt.subplots(2, 1, figsize=(9.6, 6.6), dpi=150,
                                  gridspec_kw={"height_ratios": [3.0, 0.8], "hspace": 0.36})
    ax.barh(y + h / 2, kw, height=h, color=c_kw, label="King Wen (received order)")
    ax.barh(y - h / 2, gp, height=h, color=c_gp,
            label="grand unified precursor (3 slot-edits from KW)")
    # graded-rule value labels (including the zero-length precursor bars)
    for yi, v in zip(y, kw):
        ax.text(v + 0.05, yi + h / 2, f"{v}", va="center", fontsize=11, color=c_kw)
    for yi, v in zip(y, gp):
        ax.text(v + 0.05, yi - h / 2, "0 — perfect", va="center", fontsize=11, color=c_gp)

    ax.set_yticks(y)
    ax.set_yticklabels(rules[:3], fontsize=10.5)
    ax.set_xlim(0, 3.4)
    ax.set_ylim(-0.6, 2.6)
    ax.set_xticks([0, 1, 2, 3])
    ax.set_xlabel("misses (lower is better; 0 = the rule is satisfied perfectly)", fontsize=11)
    ax.set_title("THE CONFLICT THEOREM's trade-off: the four rules cannot all be satisfied\n"
                 "(jointly UNSAT under C1+C2+C4+C5, drat-trim-verified) — any ordering must choose",
                 fontsize=12, pad=30)

    # binary trigram rule: categorical, not a count -- no bar, no misses scale
    axb.set_xlim(0, 3.4)
    axb.set_ylim(-0.5, 0.5)
    axb.set_yticks([0])
    axb.set_yticklabels(rules[3:], fontsize=10.5)
    axb.set_xticks([])
    for s in ("top", "right", "bottom"):
        axb.spines[s].set_visible(False)
    axb.text(0.05, 0.12, "KW: satisfied / precursor: violated", va="center",
             fontsize=12, fontweight="bold", color="#333333")
    axb.text(0.05, -0.28, "binary rule — no graded miss count, so it is not placed on the misses scale",
             va="center", fontsize=10.5, color="#555555")
    # The superlative ("the minimal measured margins") was WITHDRAWN 2026-08-28: f11_runA.out
    # carries `f11_hist 1 1 0` (4.13e-09) and `f11_hist 2 1 1` (2.93e-08), both nonzero and
    # componentwise no worse than KW's `2 2 2`, and that histogram is not CC-N4-conditioned, so
    # no extremal check exists. The prose and captions were corrected then and on 2026-09-01;
    # this rendered string was the last live copy (fixed 2026-09-02, prose batch P73).
    axb.text(1.7, -0.72,
             "KW keeps the trigram configuration exactly and misses the other three by two each\n"
             "(no extremal check excludes a smaller miss); the 3-edit grand precursor perfects\n"
             "those three and breaks the trigram configuration. Both cannot be had.",
             ha="center", va="top", fontsize=10.5, color="#444444", clip_on=False)
    ax.grid(True, axis="x", ls=":", alpha=0.4)
    # Outside the data axes: between the title and the top of the plot area.
    ax.legend(fontsize=10.5, loc="lower center", bbox_to_anchor=(0.5, 1.0), ncol=2,
              frameon=False, borderaxespad=0.2)
    ax.set_facecolor("#f8f8f8")
    axb.set_facecolor("#ffffff")
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

    # VIZ1 F18 (2026-09-26): 10 in wide, not 13, and no text under 10 pt -- see INLINE_PX.
    fig, ax = plt.subplots(figsize=(10, 3.9), dpi=150)
    # weekend shading (Sat 06-06 00:00 -> Mon 06-08 00:00 PT)
    ax.axvspan(datetime(2026, 6, 6), datetime(2026, 6, 8), color="#bbdefb", alpha=0.5, zorder=0)
    ax.text(datetime(2026, 6, 6, 8, 0), 1.62, "weekend: 0 evictions\n(~54 h clean Spot runway)",
            ha="center", fontsize=10, color="#1565c0")

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
        Patch(color="#9575cd", label="deferred downtime (M-F daytime eviction → resume 18:01 PT)"),
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
def fig_viz_scale():
    # x — per-cell node budget (SOLVE_PER_SUB_BRANCH_LIMIT, the only budget the
    #     DFS enforces): documentation/CANONICAL_HASHES.md §"Reproducibility
    #     parameters", the d3 11.2T / 100T / 560T recipe rows.
    # y — canonical record counts + sha prefixes: CANONICAL_HASHES.md registry.
    #     ⚠ The 100T count here is 3,432,399,297. viz/growth_curve.py still
    #     carries 3,432,399,298, which CANONICAL_HASHES.md §"d3 100T" explicitly
    #     corrects (2026-07-04): the retired value divided the file size by 32
    #     without subtracting the 32-byte header. The published count is used.
    SCALES = [
        (70_723_196,    759_608_573,    "11.2T", "0c0fe37c"),
        (631_456_644,   3_432_399_297,  "100T",  "915abf30"),
        (3_536_157_207, 10_525_271_997, "560T",  "9a968fa2"),
    ]
    # N = |C1 ∩ C2 ∩ C4 ∩ C5|, EXACT (two-instrument, mod-24 gated) — from
    # reports/METHODS.md §"Canonical quantities", TR-11 §9, and the n=31 row of
    # documentation/VERIFY.md (`solve --kc-count` against a completed Stage F
    # ladder, 10.3 s). The digits are copied from the published sources, never
    # retyped; the mod-24 assert below is the reader's one-line check.
    N = 1097051278789181790036112071176579186688
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
    ax.scatter(budgets, records, s=110, color="#d32f2f", zorder=6,
               label="d3 canonical record counts — a BUDGETED SLICE of C1–C5 (each a LOWER BOUND)")
    ax.plot([], [], "-", color="#1f77b4", lw=1.4, alpha=0.75,
            label=f"power-law fit over the three measured points (α ≈ {alpha:.2f} < 1 ⇒ sublinear)")
    for b, r, lab, sh in zip(budgets, records, [s[2] for s in SCALES], [s[3] for s in SCALES]):
        # ABOVE-right, not below. At (13, -30) the label is thrown downward into the x-axis
        # tick labels: measured on the first render, `0c0f687c` crossed the 10^9 tick and
        # `915abf30` was struck through by the axis line. The band between the points and the
        # N line is empty, so upward is free.
        ax.annotate(f"{lab}\n{r:,.0f}\nsha {sh}…", (b, r), textcoords="offset points",
                    xytext=(11, 15), fontsize=10, color="#8b1a1a")

    # N — the one horizontal line this figure adds to the existing growth curve.
    ax.axhline(N, color="#6a1b9a", lw=2.0, zorder=5,
               label="N = |C1∩C2∩C4∩C5| — the EXACT count of the C1C2C4C5-SUPERSPACE (C3 not applied)")
    ax.text(budgets.min() * 0.5, N * 2.2,
            "N = 1,097,051,278,789,181,790,036,112,071,176,579,186,688   "
            "(exact, two-instrument; 24 | N)",
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

    fig.text(0.02, -0.045,
             "POINTS — d3 canonical record counts: the orderings satisfying C1–C5 that the enumerator FOUND WITHIN\n"
             "ITS PER-CELL NODE BUDGET. Each canonical is an exactly-reproducible BUDGETED SLICE of C1–C5, and its\n"
             "record count is a LOWER BOUND on the C1–C5 population — not that population's size\n"
             "(documentation/SOLUTIONS_FORMAT.md).\n"
             "LINE — N = |C1∩C2∩C4∩C5|, the EXACT cardinality of the C1C2C4C5-SUPERSPACE, computed by the\n"
             "knowledge compiler from a completed ladder. C3 is NOT among its constraints, and neither are C6/C7,\n"
             "so N is not a count of C1–C5 either.\n"
             "UNITS — Points count canonical pair orderings with orientation masked; N counts orientation-explicit\n"
             "sequences. The plotted ratio is 29.0 decades; comparing pair orderings with pair orderings gives a gap\n"
             "of 19.7–23.9 decades.\n"
             "THE GAP is between a BUDGETED SLICE and a COMPILED SUPERSPACE. It is NOT \"how much of the space we\n"
             "found\": the two series do not count the same set, and no record count on this figure is a fraction\n"
             "of N. If the power law fitted to these three runs continues, reaching even the like-unit bracket would\n"
             "require approximately 6.4×10³⁸–1.1×10⁴⁵ nodes per cell, making enumeration infeasible under that\n"
             "extrapolation.",
             ha="left", va="top", fontsize=10, color="#333333")

    fig.tight_layout()
    save(fig, "viz_scale",
         "source: documentation/CANONICAL_HASHES.md (budgets, record counts, shas)  "
         "reports/METHODS.md §Canonical quantities + TR-11 §9 (N)  "
         "spec: viz/viz_scale.md   (viz/report_figures.py)")


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


def _read_tsv(path, required=()):
    """Tab-separated reader -> list of dicts.  No type coercion, but STRICT shape.

    Raises TsvShapeError on: an empty file, a missing header, a duplicated header
    column, any data row whose field count differs from the header's, or a
    missing `required` column.  `required` is the column list the format's own
    spec document (viz/viz_kc_*.md) states -- structure, not analysis."""
    with open(path) as fh:
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
                continue
            f = line.rstrip("\n").split("\t")
            if len(f) != len(head):
                raise TsvShapeError(
                    f"{path}:{lineno}: {len(f)} field(s) against a {len(head)}-column "
                    f"header -- the table is torn or mis-delimited, not merely short")
            rows.append(dict(zip(head, f)))
    if not rows:
        raise TsvShapeError(f"{path}: header only, 0 data rows")
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
    made from even when the shape alone cannot."""
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


def _prov(*paths):
    """Provenance string for the figure margin: basename@sha256[:12] per source.

    No timestamp, no hostname, no absolute path -- see save().  A source that is
    absent renders as `<name>@ABSENT`, which is information rather than a crash,
    because an optional panel legitimately may not be there."""
    import hashlib
    out = []
    for p in paths:
        if p is None:
            continue
        b = os.path.basename(p)
        if not os.path.exists(p):
            out.append(f"{b}@ABSENT")
            continue
        h = hashlib.sha256(open(p, "rb").read()).hexdigest()[:12]
        out.append(f"{b}@{h}")
    return "source: " + "  ".join(out) + "   (viz/report_figures.py)"


def _log10_bigint(s):
    """log10 of an exact decimal-integer STRING, for a log axis.

    The 192-bit counts overflow float64 at full-31, so the exponent comes from
    the digit count and only the leading digits are floated.  Axis placement
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
def fig_tr12_kc_field(tsv):
    if not os.path.exists(tsv):
        return _missing(tsv, "V1 field")
    # required columns and the (k, pair) grid are viz/viz_kc_field.md's own spec
    rows = _read_tsv(tsv, required=("k", "pair", "p", "kw"))
    ks, ps = _check_grid(rows, ("k", "pair"), tsv)
    M = np.zeros((len(ps), len(ks)))
    kw = []
    for r in rows:
        i, j = ps.index(_tsv_cell_int(r, "pair")), ks.index(_tsv_cell_int(r, "k"))
        M[i, j] = float(r["p"])
        if r["kw"] == "1":
            kw.append((i, j))
    # VIZ1 F18 (2026-09-26): 10 in wide (was 13) and no text under 10 pt -- see INLINE_PX.
    fig, ax = plt.subplots(figsize=(10, 8.6), dpi=150)
    im = ax.imshow(M, aspect="auto", origin="lower", cmap="magma",
                   interpolation="nearest")
    for i, j in kw:
        ax.add_patch(plt.Rectangle((j - 0.5, i - 0.5), 1, 1, fill=False,
                                   edgecolor="#4fc3f7", lw=1.6))
    # The overlay is named in a LEGEND as well as the subtitle. The subtitle carries the
    # caveat (diagonal by construction); the legend carries the key, and a reader who scans
    # figures before prose needs the key. Placed BELOW the axes on purpose: this is a dense
    # heat matrix and an in-axes legend would cover cells that are themselves the result.
    if kw:
        from matplotlib.lines import Line2D
        ax.legend(handles=[Line2D([], [], color="#4fc3f7", lw=1.6,
                                  label="King Wen's own placement (one cell per slot)")],
                  fontsize=10.5, loc="upper center", bbox_to_anchor=(0.5, -0.09),
                  frameon=False)
    ax.set_xticks(range(len(ks)))
    ax.set_xticklabels([str(k + 2) for k in ks], fontsize=10)
    ax.set_yticks(range(0, len(ps), 2))
    ax.set_yticklabels([str(ps[i]) for i in range(0, len(ps), 2)], fontsize=10)
    ax.set_xlabel("pair-slot (layer k fills slot k+2)", fontsize=11)
    ax.set_ylabel("global pair index", fontsize=11)
    ax.set_title("V1 — positional-marginal field P(pair j at slot k), exact over "
                 "C1C2C4C5-SUPERSPACE\nblue cells: King Wen's own placements (diagonal by "
                 "construction —\nthe value, not the shape, is the content)",
                 fontsize=12)
    cb = fig.colorbar(im, ax=ax)
    cb.set_label("P(pair at slot) — column sums = 1", fontsize=11)
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
def fig_tr12_kc_river(river_tsv, branches_tsv):
    if not os.path.exists(river_tsv):
        return _missing(river_tsv, "V2 river")
    # viz/viz_kc_river.md: tidy (k, d) grid.  d runs over {1,2,3,4,6}, which is
    # NOT contiguous, so the grid check is applied on the row index rather than
    # on d's absolute values -- see the remap below, which is why d is passed as
    # its own rank and not as its label.
    rows = _read_tsv(river_tsv, required=("k", "d", "p", "kw_d"))
    _dr = {v: i for i, v in enumerate(sorted({_tsv_cell_int(r, "d") for r in rows}))}
    for r in rows:
        r["_drank"] = str(_dr[_tsv_cell_int(r, "d")])
    _check_grid(rows, ("k", "_drank"), river_tsv)
    ks = sorted({_tsv_cell_int(r, "k") for r in rows})
    ds = sorted({_tsv_cell_int(r, "d") for r in rows})
    band = {d: [0.0] * len(ks) for d in ds}
    kw_d = [None] * len(ks)
    for r in rows:
        band[_tsv_cell_int(r, "d")][ks.index(_tsv_cell_int(r, "k"))] = float(r["p"])
        kw_d[ks.index(_tsv_cell_int(r, "k"))] = _tsv_cell_int(r, "kw_d")
    have_b = os.path.exists(branches_tsv)
    # VIZ1 F18: 10 in wide (was 13) and no text under 10 pt -- see INLINE_PX.
    fig, axes = plt.subplots(2 if have_b else 1, 1, figsize=(10, 11 if have_b else 5.5),
                             dpi=150, gridspec_kw={"height_ratios": [3, 2.4]} if have_b else None)
    ax = axes[0] if have_b else axes
    colors = ["#1f77b4", "#66bb6a", "#e8a33d", "#d32f2f", "#8e24aa", "#00838f"]
    edges, stepped = _river_steps(ks, [band[d] for d in ds])
    ax.stackplot(edges, *stepped, step="post", colors=colors[:len(ds)], alpha=0.9)
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
    for d, m, yl, c in zip(ds, mids, ys, colors):
        ax.annotate(f"d={d}", xy=(ks[-1] + 0.5, m), xytext=(ks[-1] + 1.6, yl),
                    fontsize=11, fontweight="bold", color=c, va="center", ha="left",
                    annotation_clip=False,
                    arrowprops=dict(arrowstyle="-", color=c, lw=1.2, shrinkA=0, shrinkB=0))
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
    ax.set_title("V2 — mass river: exact per-layer boundary-distance class mass\n"
                 "each layer is a unit-width bin, so a band's AREA is its class total, fixed by\n"
                 "the C1+C5 theorem; only the shape across k is informative", fontsize=12)
    if ax.get_legend_handles_labels()[0]: ax.legend(fontsize=10.5, loc="upper center", frameon=False)  # only KW's step is labelled (bands: F19); none at n=9, where a bare legend() warns into the golden
    if have_b:
        br = _read_tsv(branches_tsv,
                       required=("branch", "pair", "entry", "share", "prefixes_t_units"))
        _check_grid(br, ("branch",), branches_tsv)   # one contiguous row per branch
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
        ax2.set_xlabel("branch (pair : entry hexagram), sorted by mass", fontsize=11)
        tvals = [r["prefixes_t_units"] for r in br]
        if all(t.isascii() and t.isdigit() for t in tvals):
            ax3 = ax2.twinx()
            ax3.plot(list(x), [_log10_bigint(t) for t in tvals],
                     color="#d32f2f", marker="o", ms=3, lw=1.2,
                     label="log10 prefixes_t_units")
            ax3.set_ylabel("log10 exhaustion cost (t-units)", fontsize=11, color="#d32f2f")
            ax3.tick_params(axis="y", labelcolor="#d32f2f", labelsize=10)
        # 🔴 2026-09-24: this title read "a small-but-expensive branch is the atlas's point",
        # and the panel it titles shows NO such branch.  Measured on the committed n=31
        # tr12/scan/v2_branches.tsv: 0 of 1,540 branch pairs are discordant (a smaller mass
        # with a larger cost); the 56 branches fall into 7 mass levels mapping one-to-one onto
        # 7 cost levels; cost/mass spans 7.65-8.20.  The title now states what is drawn.
        ax2.set_title("branch panel — solution mass (bars) vs exhaustion cost (line);\n"
                      "measured at n=31 the two are CO-MONOTONE: no branch is small-but-expensive",
                      fontsize=11.5)
    fig.tight_layout()
    save(fig, "fig_tr12_kc_river", _prov(river_tsv, branches_tsv))
    return True


# --- V5 -- the transition grammar (viz/viz_kc_grammar.md) ------------------
@_shape_guarded("V5 grammar")
def fig_tr12_kc_grammar(tsv):
    if not os.path.exists(tsv):
        return _missing(tsv, "V5 grammar")
    # viz/viz_kc_grammar.md: tidy (k, class) grid, class = (d, w).  d and w are
    # both non-contiguous label sets, so the grid is checked on the CLASS RANK.
    rows = _read_tsv(tsv, required=("k", "d", "w", "p_cond", "kw_d", "kw_w"))
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
    for i, j in marks:
        ax.add_patch(plt.Rectangle((j - 0.5, i - 0.5), 1, 1, fill=False,
                                   edgecolor="#ffffff", lw=1.8))
    # Same convention as V1 and V2: the King Wen overlay gets a LEGEND KEY, not only a
    # subtitle sentence. Below the axes, because every cell here is a published number.
    if marks:
        from matplotlib.lines import Line2D
        # 🔴 The frame is NOT decoration. This key is WHITE, because on the plot it outlines
        # cells of a dark viridis map. Drawn frameless on the page's white ground the swatch
        # is invisible and the entry degrades to orphaned text beside nothing — worse than no
        # legend, since a reader sees a caption with no key. The dark patch reproduces the
        # background the marker actually sits on, so the key looks like what it labels.
        _lg = ax.legend(handles=[Line2D([], [], color="#ffffff", lw=1.8,
                                        label=("King Wen's own distance class d at this layer"
                                               if reduced else
                                               "King Wen's own (d, w) cell at this layer"))],
                        fontsize=10.5, loc="upper center", bbox_to_anchor=(0.5, -0.11),
                        frameon=True, facecolor="#33324a", edgecolor="#33324a",
                        labelcolor="#ffffff")
        _lg.get_frame().set_alpha(1.0)
    ax.set_yticks(range(len(cls)))
    ax.set_yticklabels([f"d={d}" + ("" if w < 0 else f", w={w}") for d, w in cls], fontsize=10)
    ax.set_xticks(range(len(ks)))
    ax.set_xticklabels([str(k) for k in ks], fontsize=10)
    ax.set_xlabel("layer k", fontsize=11)
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
        ax.set_title("V5 — transition grammar P(class | layer k), exact over C1C2C4C5-SUPERSPACE\n"
                     "read DOWN each column (every column sums to 1)\n"
                     "no King Wen overlay in this table — kw_d/kw_w match no plotted class\n"
                     "at any layer (n != 31?)", fontsize=12)
    elif reduced:
        ax.set_title("V5 — transition grammar P(class | layer k), exact over C1C2C4C5-SUPERSPACE\n"
                     "read DOWN each column (every column sums to 1)\n"
                     "REDUCED FORM: this table carries no w axis (w = -1), so a row is a\n"
                     "distance class d and the white outline is King Wen's own d", fontsize=12)
    else:
        ax.set_title("V5 — transition grammar P(d, w | layer k), exact over C1C2C4C5-SUPERSPACE\n"
                     "d = boundary distance to the new pair, w = within-pair distance of the new pair;\n"
                     "read DOWN each column (every column sums to 1)\n"
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
@_shape_guarded("V4 shells")
def fig_tr12_kc_shells(tsv):
    if not os.path.exists(tsv):
        return _missing(tsv, "V4 shells")
    # viz/viz_kc_shells.md: one row per free placement, `step` a contiguous run
    rows = _read_tsv(tsv, required=("step", "g", "bits", "alts"))
    _check_grid(rows, ("step",), tsv)
    steps = [_tsv_cell_int(r, "step") for r in rows]
    # g is a 192-bit decimal string: plotted on a log axis via its digit count,
    # never by float()-ing the exact value.
    logg = [_log10_bigint(r["g"]) for r in rows]
    bits = [float(r["bits"]) for r in rows]
    alts = [_tsv_cell_int(r, "alts") for r in rows]
    # VIZ1 F18 (2026-09-26): 10 in wide (was 12) and no text under 10 pt -- see INLINE_PX.
    fig, (ax, ax2) = plt.subplots(2, 1, figsize=(10, 9), dpi=150, sharex=True,
                                  gridspec_kw={"height_ratios": [3, 2]})
    # optional band: min/max g over the ALTERNATIVES at each step, present only
    # when the TSV came from `--kc-profile` (viz_kc_shells.md, the optional band)
    if "g_alt_min" in rows[0] and "g_alt_max" in rows[0]:
        ax.fill_between(steps,
                        [_log10_bigint(r["g_alt_min"]) for r in rows],
                        [_log10_bigint(r["g_alt_max"]) for r in rows],
                        color="#1f77b4", alpha=0.18, step="mid",
                        label="min/max g over the admissible alternatives")
        ax.legend(fontsize=10.5, loc="upper right")
    ax.step(steps, logg, where="mid", color="#1f77b4", lw=2.0, marker="o", ms=4)
    for s, y, a in zip(steps, logg, alts):
        ax.annotate(str(a), (s, y), textcoords="offset points", xytext=(0, 7),
                    ha="center", fontsize=10, color="#444444")
    ax.tick_params(labelsize=10)
    ax.set_ylabel("log10 g(King Wen's prefix) — completions remaining", fontsize=11)
    # 🔴 The title used to read "exact completions remaining after each placement" and the
    # y-label "log10 g(prefix)" — NEITHER said King Wen. V1, V2 and V5 plot a population with
    # King Wen overlaid, so a reader arriving from those figures reasonably reads this one the
    # same way. It is not: every point here is ONE walk, King Wen's own. Saying so is worth
    # more than any marker, because the thing a marker would distinguish does not exist here.
    # VIZ1 F21 (2026-09-26): the title names the space (C1C2C4C5-SUPERSPACE; C3 not imposed) that
    # g counts completions in and that N is the size of; it named neither.
    ax.set_title("V4 — King Wen's neighbourhood shells in C1C2C4C5-SUPERSPACE; C3 not imposed\n"
                 "exact completions remaining after each of King Wen's 31 free placements\n"
                 "EVERY point is King Wen's own trajectory — this figure plots ONE walk, not a\n"
                 "population (annotation = # admissible alternatives)", fontsize=12)
    ax.grid(True, ls=":", alpha=0.4)
    ax2.bar(steps, bits, color="#e8a33d")
    ax2.tick_params(labelsize=10)
    ax2.set_ylabel("−log2 p_i (bits)", fontsize=11)
    ax2.set_xlabel("step (free placement i)", fontsize=11)
    ax2.grid(True, axis="y", ls=":", alpha=0.4)
    ax2.set_title("the surprise spectrum — King Wen's own per-step −log2 p_i; the bars sum to\n"
                  "log2 N, N = |C1∩C2∩C4∩C5| (EW-1). A step with ONE admissible alternative costs 0 bits.",
                  fontsize=11)
    fig.tight_layout()
    save(fig, "fig_tr12_kc_shells", _prov(tsv))
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
    rows = _read_tsv(tsv, required=("i", "rank", "x", "order"))
    _check_grid(rows, ("i",), tsv)
    skip = {"i", "rank", "x", "order", "walk"}
    # `kw_<observable>` carries King Wen's value for that observable and is a
    # REFERENCE LINE, not a panel of its own.  viz/ holds no analysis: the value
    # arrives in the TSV from the emitter, and where the column is absent the
    # panel simply has no reference line -- it is never invented here.
    obs = [c for c in rows[0] if c not in skip and not c.startswith("kw_")]
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
    const = [c for c in obs if len({r[c] for r in rows}) == 1]
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
    nrow = (len(obs) + ncol - 1) // ncol
    # VIZ1 F18 (2026-09-26): 10 in wide (was 13) and no text under 10 pt -- see INLINE_PX.
    fig, axes = plt.subplots(nrow, ncol, figsize=(10, 2.9 * nrow + 1.2), dpi=150, squeeze=False)
    marked = 0
    for idx, name in enumerate(obs):
        a = axes[idx // ncol][idx % ncol]
        a.plot(x, [float(r[name]) for r in rows], ".", ms=2, color="#1f77b4")
        # viz_kc_spectrum.md: King Wen's value for the observable, drawn as a
        # horizontal reference line WHERE THE TSV SUPPLIES ONE (`kw_<name>`).
        ref = "kw_" + name
        if ref in rows[0]:
            vals = {r[ref] for r in rows}
            if len(vals) != 1:
                print(f"SKIP V3 spectrum: {tsv} column {ref} is King Wen's value for "
                      f"{name} and must be constant down the grid; got {len(vals)} "
                      f"distinct values -- that is a labelling error, not a spectrum")
                return False
            a.axhline(float(vals.pop()), color="#d62728", ls="--", lw=1.0)
            marked += 1
        a.set_title(name + (" (— King Wen)" if ref in rows[0] else ""), fontsize=10.5)
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
    # VIZ1 F21 (2026-09-26): the suptitle names the space the index runs over and defines N; it
    # named neither. Each logical line is wrapped to the 10-in canvas (VIZ1 F18) -- one unwrapped
    # line of this widened the canvas, and a wider canvas raises the text floor with it.
    _sup = [f"V3 — rank spectrum in {orders[0]} order: observable drift across the index "
            f"(x = rank / N)",
            f"{len(rows):,} grid points; index over C1C2C4C5-SUPERSPACE; C3 not imposed; "
            f"N = |C1∩C2∩C4∩C5|",
            (f"dashed red = King Wen's value, on {marked}/{len(obs)} panels; no line on "
             f"{', '.join(unmarked)}; the TSV supplies no King Wen value for those: they "
             f"measure similarity TO King Wen, so its value is extreme by construction "
             f"(viz_kc_spectrum.md)"
             if marked and unmarked else
             f"dashed red = King Wen's value, on all {marked} panels" if marked else
             "no kw_* reference values in this TSV — no King Wen line drawn")]
    if const:
        _sup.append(f"dropped as CONSTANT on the whole grid (no spectrum to draw): "
                    f"{', '.join(f'{c} = {rows[0][c]}' for c in const)}")
    fig.suptitle("\n".join(textwrap.fill(t, 88, break_on_hyphens=False) for t in _sup),
                 fontsize=12)
    fig.tight_layout()
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
# INTEGERS from tr12/q3_profile_kw.tsv -- no fit, no smoothing, no error band,
# because there is no error to band.
#
# TWO INDEX CONVENTIONS EXIST AND ARE DELIBERATELY NOT MIXED. The ladder
# convention (documentation/GT_LADDER_FORMAT.md) has layers k = 0..31, layer k
# holding states with popcount(mask) = k -- that is the top panel. The walk
# convention (tr12/q3_profile_kw.tsv, viz/viz_kc_shells.md) indexes the 31 FREE
# placements as step 1..31 -- that is the bottom panel. The bottom panel's
# caption says which it is using.
# ---------------------------------------------------------------------------
@_shape_guarded("N-2 f·g mechanism")
def fig_viz_narrative_n2_fg_mechanism(tsv=None):
    if tsv is None:
        tsv = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..",
                           "tr12", "q3_profile_kw.tsv")
    if not os.path.exists(tsv):
        return _missing(tsv, "N-2 f·g mechanism",
                        how="python3 solve.py --kc-profile against a completed ladder; "
                            "the published copy is tr12/q3_profile_kw.tsv")
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
    -- was not written by an atlas consumer that emits them. The committed `tr12/` tree is such a
    directory (it ships q3_profile_kw.tsv and no sidecar), so there the KW name is still taken as
    written. Any consumer run writes a sidecar, so a reused --atlas-out never reaches this branch.
    """
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
                          "ATLAS.json --atlas-out DIR --atlas-q3-trace TRACE`" % root)
        return plain, ""
    side = kw + ".provenance.txt"
    if os.path.exists(side):
        fields = {}
        with open(side, encoding="utf-8") as fh:
            for line in fh:
                k, sep, v = line.rstrip("\n").partition("=")
                if sep:
                    fields[k] = v
        if fields.get("q3_is_king_wen") == "PASS" and fields.get("q3_table") == "q3_profile_kw.tsv":
            return kw, ""
        return None, ("%s is present but its sidecar reads q3_is_king_wen=%s, q3_table=%s -- "
                      "the King Wen name is not backed by its own provenance"
                      % (kw, fields.get("q3_is_king_wen"), fields.get("q3_table")))
    if os.path.exists(plain + ".provenance.txt"):
        return None, ("%s has no sidecar, but q3_profile.tsv's sidecar is in the same directory: "
                      "the KW table is a leftover of an earlier run" % kw)
    return kw, ""


def tr12_figures(root=None):
    """Render V1..V5 from the atlas-consumer TSVs rooted at `root`.

    `root` defaults to the repository's own tr12/ directory, resolved from this file's location
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

    V3 (spectrum) stays OPTIONAL and is reported, never fatal: its input is a rank
    grid joined to per-walk functionals by `solve.py --v3-spectrum` (2026-09-23),
    which scripts/tr12_repro.sh runs at n=31 only (row c_v3_join, Q-430, 2026-09-25)
    and the atlas consumer never runs -- so at n<31 the input is absent by design and
    TR12_V3_FIG=SKIP:reduced-universe.  Making it required here would be a gate
    that cannot be satisfied.

    PATH (2026-09-24).  The spec path is <root>/spectrum/v3_spectrum.tsv, but the
    COMMITTED table is tr12/v3_spectrum.tsv (no spectrum/ level), so
    tr12_figures("tr12") silently skipped the one V3 input the repo ships.  The
    flat path is now a FALLBACK, taken only when the spec path is absent and the
    flat file exists -- when neither exists the message still names the spec path,
    so the battery's c_viz output is unchanged.
    """
    if root is None:
        root = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "tr12")
    scan = os.path.join(root, "scan")
    q3, q3_why = _tr12_q3_table(root)

    def _v4():
        if q3 is None:
            print("[tr12_figures] V4 refused: %s" % q3_why)
            return False
        return fig_tr12_kc_shells(q3)
    required = [
        ("V1", lambda: fig_tr12_kc_field(os.path.join(scan, "v1_field.tsv"))),
        ("V2", lambda: fig_tr12_kc_river(os.path.join(scan, "v2_river.tsv"),
                                         os.path.join(scan, "v2_branches.tsv"))),
        ("V5", lambda: fig_tr12_kc_grammar(os.path.join(scan, "v5_grammar.tsv"))),
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
    if opt is False:
        # V3's absence is already reported by the battery's own TR12_V3_FIG skip row; printing
        # here too would add a line to c_viz.txt and move that golden as well.
        pass
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
    import tempfile, itertools, io as _io, contextlib
    KS, PS = range(0, 6), range(0, 4)

    def field_rows(pairs):
        out = ["k\tslot\tpair\tmass\tp\tkw"]
        for k, j in pairs:
            out.append(f"{k}\t{k+2}\t{j}\t1000\t{1.0/len(PS):.6f}\t{1 if j == k else 0}")
        return "\n".join(out) + "\n"

    full = list(itertools.product(KS, PS))
    cases = []            # (name, tsv text, want_ok, want_substr)
    cases.append(("GREEN complete 6x4 grid", field_rows(full), True, "Saved"))
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
        for cond, name in ((pa == pa2, "provenance is stable across re-reads"),
                           (pa != pb, "provenance moves when one byte moves"),
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
# 3.11.0 a re-render reproduced all ten committed PNGs byte-identically; under 3.6.3 none matched
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
    fig_tr4_boundary_information()
    fig_tr1_rules_tradeoff()
    fig_tr3_campaign_timeline()
    # The scale figure (viz/viz_scale.md) needs no data file at all.
    fig_viz_scale()
    # The narrative document's two figures (viz/archive/viz_narrative.md) are HELD and not
    # committed, so they are opt-in (Q-862). N-1 needs no data file; N-2 reads the published
    # King Wen walk profile and SKIPs cleanly when that TSV is absent.
    if narrative:
        fig_viz_narrative_n1_object()
        fig_viz_narrative_n2_fg_mechanism()
    # TR-12 V1..V5: rendered from the atlas-consumer TSVs when they are present.
    # Root defaults to the repository's tr12/ (resolved from this file, not the CWD -- VIZ1 F20);
    # override with the positional argument.
    tr12_figures(root)
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
