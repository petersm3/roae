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
  fig_tr4_boundary_information  — the S(k) log-decay curve + uniqueness extrapolation band (TR-4 §5)
  fig_tr1_rules_tradeoff        — KW vs the grand unified precursor on the four conflicting rules
                                  (TR-1 §5 / TR-2; the conflict theorem's trade-off)
  fig_tr3_campaign_timeline     — first 560T run timeline with the 5 Spot-eviction marks
                                  (CAMPAIGN_METHODOLOGY.md eviction table)
  fig_tr12_kc_field             — V1 positional-marginal field   (viz/viz_kc_field.md)
  fig_tr12_kc_river             — V2 mass river + branch panel   (viz/viz_kc_river.md)
  fig_tr12_kc_spectrum          — V3 rank spectrum               (viz/viz_kc_spectrum.md)
  fig_tr12_kc_shells            — V4 King Wen's shells           (viz/viz_kc_shells.md)
  fig_tr12_kc_grammar           — V5 transition grammar          (viz/viz_kc_grammar.md)

The five TR-12 figures are TSV-in/figure-out over the tables written by
`python3 solve.py --atlas-queries ATLAS.json --atlas-out DIR` — no analysis
logic lives here. Each is skipped with a message if its TSV is absent.

Requires: matplotlib, numpy (external — not a dependency of roae.py / solve.c).

Usage:
    cd reports/figures/ && python3 ../../viz/report_figures.py [TR12_ARTIFACT_ROOT]
"""
import math
import os
import sys
from datetime import datetime, timedelta

import numpy as np
import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt
import matplotlib.dates as mdates

# Import solve.py (repo root) for the King Wen sequence — single source of truth.
sys.path.insert(0, os.path.join(os.path.dirname(os.path.abspath(__file__)), ".."))
from solve import binary_hexagrams  # noqa: E402


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
    property the atlas half of TR-12 exists to have.  Same input bytes in, same
    figure out.

    The footer is also the thing GATE 6 polices: that gate greps the GENERATOR's
    annotation strings because matplotlib renders text to glyph paths and the
    rendered figure is unreadable to grep.  Text that reaches a figure only
    through this function is text GATE 6 can see."""
    if provenance:
        fig.text(0.995, 0.004, provenance, ha="right", va="bottom",
                 fontsize=5.0, color="#8a8a8a", family="monospace")
    fig.savefig(f"{stem}.png", dpi=150, bbox_inches="tight")
    fig.savefig(f"{stem}.svg", bbox_inches="tight")
    plt.close(fig)
    print(f"Saved {stem}.png and {stem}.svg")


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
    fig, ax = plt.subplots(figsize=(16, 2.8), dpi=150)
    for i, c in enumerate(classes):
        ax.add_patch(plt.Rectangle((i, 0), 0.92, 1, facecolor=col[c],
                                   edgecolor="white", linewidth=1.2))
        ax.text(i + 0.46, 0.5, c, ha="center", va="center",
                fontsize=12, fontweight="bold", color="white")
        ax.text(i + 0.46, -0.22, str(i + 1), ha="center", va="center", fontsize=7.5,
                color="#555555")
    # alternation marks between consecutive pairs of different class
    for i in range(31):
        if classes[i] != classes[i + 1]:
            ax.plot([i + 0.96, i + 0.96], [-0.05, 1.05], color="#d32f2f", lw=2.2, zorder=5)
            ax.plot(i + 0.96, 1.13, marker="v", color="#d32f2f", ms=6, zorder=5)
    ax.text(16, 1.42,
            f"King Wen's parity-class string: 16 E / 16 O, exactly {n_alt} alternations "
            "(red marks) — forced by C1–C5, not a design choice",
            ha="center", va="center", fontsize=12)
    ax.text(16, -0.52, "pair position 1–32 (pair p = King Wen sequence positions 2p−1, 2p; "
                       "class = popcount parity, E = even, O = odd; first pair {63, 0} is even — pinned by C4)",
            ha="center", va="center", fontsize=9, color="#555555")
    ax.set_xlim(-0.3, 32.3)
    ax.set_ylim(-0.75, 1.65)
    ax.axis("off")
    fig.tight_layout()
    save(fig, "fig_tr6_parity_alternations")


# ---------------------------------------------------------------------------
# TR-4 §5 — boundary-information curve S(k) with the extrapolation-to-uniqueness band
# ---------------------------------------------------------------------------
def fig_tr4_boundary_information():
    # Data: TR4_SIZE_OF_THE_SPACE.md §5 (pinned Knuth walks, 2e9 probes/prefix, rel. err <= 10%):
    #   k=1: 7.49e-4 (9.95e34 survivors); k=2: 9.39e-7 (1.25e32);
    #   k=3: 4.27e-10 (5.68e28); k=4: 6.34e-13 (8.42e25).
    # Full-space size 1.3287e38 (TR-4 §3); greedy per-boundary cut ~1e3; weakest-boundary
    # bracket (k=5-8) reported at x15-17 per boundary but ILLUSTRATIVE, not measured — its
    # chain outputs are not archived and it is not reproducible from published material
    # (restated 2026-09-02, TR-4 v1.25); extrapolated uniqueness at ~15-20
    # boundaries (current; supersedes an earlier ~13-14 estimate; heuristic floor k>=12).
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
    k = np.array([1, 2, 3, 4])
    S = np.array([7.49e-4, 9.39e-7, 4.27e-10, 6.34e-13])
    survivors = ["9.95×10³⁴", "1.25×10³²", "5.68×10²⁸", "8.42×10²⁵"]
    N_total = 1.3287e38
    S_unique = 1.0 / N_total  # S at which exactly one ordering (KW) survives

    fig, ax = plt.subplots(figsize=(10, 7), dpi=150)
    ax.set_yscale("log")

    # measured greedy points
    ax.plot(k, S, "-", color="#1f77b4", lw=1.5, alpha=0.7, zorder=4)
    ax.scatter(k, S, s=90, color="#d32f2f", zorder=5,
               label="measured S(k), greedy 560T identifying order {4, 27, 25, 21, 1}")
    for ki, Si, sv in zip(k, S, survivors):
        ax.annotate(f"S({ki}) = {Si:.2e}\n{sv} survivors", (ki, Si),
                    textcoords="offset points", xytext=(10, 4), fontsize=9)

    # greedy extrapolation at the roughly constant ~x1e3 per-boundary cut (TR-4 §5)
    k_ext = np.arange(4, 21)
    ax.plot(k_ext, S[-1] * (1e-3) ** (k_ext - 4), "--", color="#1f77b4", lw=1.3, alpha=0.8,
            label="extrapolation at the ~×10³/boundary greedy cut (NOT measured)")

    # weakest-remaining-boundary bracket: k=5-8 reported at x15-17 per boundary.
    # ILLUSTRATIVE, not measured: the only archived S(k) outputs (reports/evidence/sk/)
    # are greedy chains, so these two literals are the one thing on this figure with no
    # file under reports/evidence/ behind it. Labelled as such since 2026-09-02.
    k_br = np.arange(4, 9)
    ax.fill_between(k_br, S[-1] * (1 / 17.0) ** (k_br - 4), S[-1] * (1 / 15.0) ** (k_br - 4),
                    color="#e8a33d", alpha=0.35,
                    label="weakest-remaining-boundary bracket, ×15–17/boundary (illustrative, k = 5–8)")

    # the uniqueness level and the extrapolated-uniqueness band
    ax.axhline(S_unique, color="#388e3c", lw=1.3, ls="-.")
    ax.text(0.7, S_unique * 3, "uniqueness: S(k) = 1/1.3287×10³⁸ (one surviving ordering)",
            fontsize=9, color="#2e7d32", va="bottom")
    ax.axvspan(15, 20, color="#388e3c", alpha=0.12)
    ax.text(16.5, 1e-8, "extrapolated full-space\nuniqueness range:\n~15–20 boundaries (current;\n"
                        "supersedes earlier ~13–14 est.;\nheuristic floor k ≥ 12)",
            fontsize=9, color="#2e7d32", ha="center")

    ax.set_xlim(0.5, 20.5)
    ax.set_ylim(1e-42, 1e-1)
    ax.set_xticks(range(1, 21))
    ax.set_xlabel("k = number of King Wen boundary constraints imposed", fontsize=12)
    ax.set_ylabel("S(k) = fraction of the full C1–C5 population agreeing with KW (log scale)", fontsize=11)
    ax.set_title("The boundary-information curve S(k) — slice-uniqueness vs space-uniqueness\n"
                 "(the first 4 of the 5 boundaries that identify KW in the 560T slice still admit "
                 "≈8.4×10²⁵ full-space orderings)", fontsize=12)
    ax.grid(True, which="both", ls=":", alpha=0.4)
    ax.legend(fontsize=9, loc="lower left")
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
    y = np.arange(4)[::-1]
    h = 0.34
    c_kw, c_gp = "#d32f2f", "#388e3c"

    fig, ax = plt.subplots(figsize=(10, 6.4), dpi=150)
    ax.barh(y[:3] + h / 2, kw, height=h, color=c_kw, label="King Wen (received order)")
    ax.barh(y[:3] - h / 2, gp, height=h, color=c_gp,
            label="grand unified precursor (3 slot-edits from KW)")
    # graded-rule value labels (including the zero-length precursor bars)
    for yi, v in zip(y[:3], kw):
        ax.text(v + 0.05, yi + h / 2, f"{v}", va="center", fontsize=10, color=c_kw)
    for yi, v in zip(y[:3], gp):
        ax.text(v + 0.05, yi - h / 2, "0 — perfect", va="center", fontsize=10, color=c_gp)
    # binary trigram rule: categorical, not a count
    ax.text(0.05, y[3] + h / 2, "✓ satisfied exactly", va="center",
            fontsize=11, color=c_kw, fontweight="bold")
    ax.barh(y[3] - h / 2, 2.6, height=h, color="none", edgecolor=c_gp, hatch="///", lw=1.2)
    ax.text(0.05, y[3] - h / 2, "✗ violated (binary rule — no graded miss count)",
            va="center", fontsize=10, color=c_gp)

    ax.set_yticks(y)
    ax.set_yticklabels(rules, fontsize=9.5)
    ax.set_xlim(0, 3.4)
    ax.set_ylim(-1.35, 3.65)
    ax.set_xticks([0, 1, 2, 3])
    ax.set_xlabel("misses (lower is better; 0 = the rule is satisfied perfectly)", fontsize=11)
    ax.set_title("THE CONFLICT THEOREM's trade-off: the four rules cannot all be satisfied\n"
                 "(jointly UNSAT under C1+C2+C4+C5, drat-trim-verified) — any ordering must choose",
                 fontsize=12)
    # The superlative ("the minimal measured margins") was WITHDRAWN 2026-08-28: f11_runA.out
    # carries `f11_hist 1 1 0` (4.13e-09) and `f11_hist 2 1 1` (2.93e-08), both nonzero and
    # componentwise no worse than KW's `2 2 2`, and that histogram is not CC-N4-conditioned, so
    # no extremal check exists. The prose and captions were corrected then and on 2026-09-01;
    # this rendered string was the last live copy (fixed 2026-09-02, prose batch P73).
    ax.text(1.7, -1.0,
            "KW keeps the trigram configuration exactly and misses the other three by two each\n"
            "(no extremal check excludes a smaller miss); the 3-edit grand precursor perfects\n"
            "those three and breaks the trigram configuration. Both cannot be had.",
            ha="center", va="center", fontsize=9, color="#555555")
    ax.grid(True, axis="x", ls=":", alpha=0.4)
    ax.legend(fontsize=9, loc="upper right")
    ax.set_facecolor("#f8f8f8")
    fig.tight_layout()
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

    fig, ax = plt.subplots(figsize=(13, 3.6), dpi=150)
    # weekend shading (Sat 06-06 00:00 -> Mon 06-08 00:00 PT)
    ax.axvspan(datetime(2026, 6, 6), datetime(2026, 6, 8), color="#bbdefb", alpha=0.5, zorder=0)
    ax.text(datetime(2026, 6, 7, 0, 0), 1.62, "weekend: 0 evictions\n(~54 h clean Spot runway)",
            ha="center", fontsize=9, color="#1565c0")

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
        ax.text(e, y0 + hh + 0.28, e.strftime("%a\n%H:%M PT"), ha="center", fontsize=8,
                color="#b71c1c")
    ax.plot(launch, y0 + hh / 2, marker=">", color="#1b5e20", ms=10, zorder=5)
    ax.text(launch, y0 - 0.28, "launch\nSun 17:03 PT", ha="center", fontsize=8, color="#1b5e20")
    ax.plot(enum_end, y0 + hh / 2, marker="*", color="#d32f2f", ms=16, zorder=5)
    ax.text(enum_end, y0 + hh + 0.28, "enum complete\n171.5 h wall", ha="center", fontsize=8,
            color="#b71c1c")

    # legend proxies
    from matplotlib.patches import Patch
    from matplotlib.lines import Line2D
    ax.legend(handles=[
        Patch(color="#66bb6a", label="enumerating on Spot D128"),
        Patch(color="#9575cd", label="deferred downtime (M-F daytime eviction → resume 18:01 PT)"),
        Line2D([], [], marker="v", color="#d32f2f", ls="none", label="Spot eviction"),
        Patch(color="#bbdefb", label="weekend (PT)"),
    ], fontsize=8.5, loc="lower right", ncol=2)

    ax.set_ylim(0, 2.05)
    ax.set_yticks([])
    ax.set_xlim(datetime(2026, 5, 31, 12), datetime(2026, 6, 8, 6))
    ax.xaxis.set_major_locator(mdates.DayLocator())
    ax.xaxis.set_major_formatter(mdates.DateFormatter("%a %m-%d"))
    ax.set_xlabel("2026, Pacific Time", fontsize=10)
    ax.set_title("First 560T campaign timeline — 5 Spot evictions, all M-F in a 37-min window "
                 "(07:12–07:49 PT), 0 on the weekend", fontsize=12)
    ax.grid(True, axis="x", ls=":", alpha=0.4)
    ax.set_facecolor("#f8f8f8")
    fig.tight_layout()
    save(fig, "fig_tr3_campaign_timeline")




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
                v.append(int(r[c]))
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
    s = s.strip()
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
        i, j = ps.index(int(r["pair"])), ks.index(int(r["k"]))
        M[i, j] = float(r["p"])
        if r["kw"] == "1":
            kw.append((i, j))
    fig, ax = plt.subplots(figsize=(13, 8), dpi=150)
    im = ax.imshow(M, aspect="auto", origin="lower", cmap="magma",
                   interpolation="nearest")
    for i, j in kw:
        ax.add_patch(plt.Rectangle((j - 0.5, i - 0.5), 1, 1, fill=False,
                                   edgecolor="#4fc3f7", lw=1.6))
    ax.set_xticks(range(len(ks)))
    ax.set_xticklabels([str(k + 2) for k in ks], fontsize=7)
    ax.set_yticks(range(0, len(ps), 2))
    ax.set_yticklabels([str(ps[i]) for i in range(0, len(ps), 2)], fontsize=7)
    ax.set_xlabel("pair-slot (layer k fills slot k+2)", fontsize=10)
    ax.set_ylabel("global pair index", fontsize=10)
    ax.set_title("V1 — positional-marginal field P(pair j at slot k), exact over "
                 "C1C2C4C5-SUPERSPACE\nblue cells: King Wen's own placements "
                 "(diagonal by construction — the value, not the shape, is the content)",
                 fontsize=11)
    fig.colorbar(im, ax=ax, label="P(pair at slot) — column sums = 1")
    fig.tight_layout()
    save(fig, "fig_tr12_kc_field", _prov(tsv))
    return True


# --- V2 -- the mass river + branch panel (viz/viz_kc_river.md) -------------
@_shape_guarded("V2 river")
def fig_tr12_kc_river(river_tsv, branches_tsv):
    if not os.path.exists(river_tsv):
        return _missing(river_tsv, "V2 river")
    # viz/viz_kc_river.md: tidy (k, d) grid.  d runs over {1,2,3,4,6}, which is
    # NOT contiguous, so the grid check is applied on the row index rather than
    # on d's absolute values -- see the remap below, which is why d is passed as
    # its own rank and not as its label.
    rows = _read_tsv(river_tsv, required=("k", "d", "p", "kw_d"))
    _dr = {v: i for i, v in enumerate(sorted({int(r["d"]) for r in rows}))}
    for r in rows:
        r["_drank"] = str(_dr[int(r["d"])])
    _check_grid(rows, ("k", "_drank"), river_tsv)
    ks = sorted({int(r["k"]) for r in rows})
    ds = sorted({int(r["d"]) for r in rows})
    band = {d: [0.0] * len(ks) for d in ds}
    kw_d = [None] * len(ks)
    for r in rows:
        band[int(r["d"])][ks.index(int(r["k"]))] = float(r["p"])
        kw_d[ks.index(int(r["k"]))] = int(r["kw_d"])
    have_b = os.path.exists(branches_tsv)
    fig, axes = plt.subplots(2 if have_b else 1, 1, figsize=(13, 9 if have_b else 5),
                             dpi=150, gridspec_kw={"height_ratios": [3, 2]} if have_b else None)
    ax = axes[0] if have_b else axes
    colors = ["#1f77b4", "#66bb6a", "#e8a33d", "#d32f2f", "#8e24aa", "#00838f"]
    ax.stackplot(ks, *[band[d] for d in ds],
                 labels=[f"d = {d}" for d in ds], colors=colors[:len(ds)], alpha=0.9)
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
        ax.step(ks, y, where="mid", color="white", lw=2.0, zorder=6)
        ax.step(ks, y, where="mid", color="#111111", lw=1.0, zorder=7,
                label="King Wen's own class")
    ax.set_xlim(min(ks), max(ks))
    ax.set_ylim(0, 1)
    ax.set_xlabel("layer k (fills pair-slot k+2)", fontsize=10)
    ax.set_ylabel("share of C1C2C4C5-SUPERSPACE", fontsize=10)
    ax.set_title("V2 — mass river: exact per-layer boundary-distance class mass "
                 "(band AREAS are fixed by the C1+C5 theorem; only the shape across k "
                 "is informative)", fontsize=11)
    ax.legend(fontsize=8.5, loc="upper right", ncol=len(ds) + 1)
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
                            fontsize=6, rotation=90)
        ax2.set_ylabel("branch share of N", fontsize=9)
        ax2.set_xlabel("branch (pair : entry hexagram), sorted by mass", fontsize=9)
        tvals = [r["prefixes_t_units"] for r in br]
        if all(t.isdigit() for t in tvals):
            ax3 = ax2.twinx()
            ax3.plot(list(x), [_log10_bigint(t) for t in tvals],
                     color="#d32f2f", marker="o", ms=3, lw=1.2,
                     label="log10 prefixes_t_units")
            ax3.set_ylabel("log10 exhaustion cost (t-units)", fontsize=9, color="#d32f2f")
            ax3.tick_params(axis="y", labelcolor="#d32f2f")
        ax2.set_title("branch panel — solution mass (bars) vs exhaustion cost "
                      "(line); a small-but-expensive branch is the atlas's point",
                      fontsize=10)
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
    _cr = {v: i for i, v in enumerate(sorted({(int(r["d"]), int(r["w"])) for r in rows}))}
    for r in rows:
        r["_crank"] = str(_cr[(int(r["d"]), int(r["w"]))])
    _check_grid(rows, ("k", "_crank"), tsv)
    ks = sorted({int(r["k"]) for r in rows})
    cls = sorted({(int(r["d"]), int(r["w"])) for r in rows})
    M = np.zeros((len(cls), len(ks)))
    marks = []
    for r in rows:
        i, j = cls.index((int(r["d"]), int(r["w"]))), ks.index(int(r["k"]))
        M[i, j] = float(r["p_cond"])
        if int(r["kw_d"]) == int(r["d"]) and int(r["kw_w"]) == int(r["w"]):
            marks.append((i, j))
    fig, ax = plt.subplots(figsize=(13, 3.6 + 0.25 * len(cls)), dpi=150)
    im = ax.imshow(M, aspect="auto", origin="lower", cmap="viridis",
                   interpolation="nearest")
    for i, j in marks:
        ax.add_patch(plt.Rectangle((j - 0.5, i - 0.5), 1, 1, fill=False,
                                   edgecolor="#ffffff", lw=1.8))
    ax.set_yticks(range(len(cls)))
    ax.set_yticklabels([f"d={d}" + ("" if w < 0 else f", w={w}") for d, w in cls], fontsize=8)
    ax.set_xticks(range(len(ks)))
    ax.set_xticklabels([str(k) for k in ks], fontsize=7)
    ax.set_xlabel("layer k", fontsize=10)
    ax.set_title("V5 — transition grammar P(class | layer k), exact over "
                 "C1C2C4C5-SUPERSPACE\nread DOWN each column (every column sums to 1); "
                 "white outline = King Wen's own class",
                 fontsize=11)
    fig.colorbar(im, ax=ax, label="P(class | layer k)")
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
    steps = [int(r["step"]) for r in rows]
    # g is a 192-bit decimal string: plotted on a log axis via its digit count,
    # never by float()-ing the exact value.
    logg = [_log10_bigint(r["g"]) for r in rows]
    bits = [float(r["bits"]) for r in rows]
    alts = [int(r["alts"]) for r in rows]
    fig, (ax, ax2) = plt.subplots(2, 1, figsize=(12, 8), dpi=150, sharex=True,
                                  gridspec_kw={"height_ratios": [3, 2]})
    # optional band: min/max g over the ALTERNATIVES at each step, present only
    # when the TSV came from `--kc-profile` (viz_kc_shells.md, the optional band)
    if "g_alt_min" in rows[0] and "g_alt_max" in rows[0]:
        ax.fill_between(steps,
                        [_log10_bigint(r["g_alt_min"]) for r in rows],
                        [_log10_bigint(r["g_alt_max"]) for r in rows],
                        color="#1f77b4", alpha=0.18, step="mid",
                        label="min/max g over the admissible alternatives")
        ax.legend(fontsize=8.5, loc="upper right")
    ax.step(steps, logg, where="mid", color="#1f77b4", lw=2.0, marker="o", ms=4)
    for s, y, a in zip(steps, logg, alts):
        ax.annotate(str(a), (s, y), textcoords="offset points", xytext=(0, 7),
                    ha="center", fontsize=6.5, color="#555555")
    ax.set_ylabel("log10 g(prefix) — completions remaining", fontsize=10)
    ax.set_title("V4 — neighbourhood shells: exact completions remaining after each "
                 "placement (annotation = # admissible alternatives)", fontsize=11)
    ax.grid(True, ls=":", alpha=0.4)
    ax2.bar(steps, bits, color="#e8a33d")
    ax2.set_ylabel("−log2 p_i (bits)", fontsize=10)
    ax2.set_xlabel("step (free placement i)", fontsize=10)
    ax2.grid(True, axis="y", ls=":", alpha=0.4)
    ax2.set_title("the surprise spectrum — the bars sum to log2 N (EW-1)", fontsize=10)
    fig.tight_layout()
    save(fig, "fig_tr12_kc_shells", _prov(tsv))
    return True


# --- V3 -- the rank spectrum (viz/viz_kc_spectrum.md) ----------------------
@_shape_guarded("V3 spectrum")
def fig_tr12_kc_spectrum(tsv):
    if not os.path.exists(tsv):
        # V3 does NOT ride the atlas: its rows come from a rank grid
        # (--kc-unrank / PENDING --kc-unrank-grid) joined to the frozen
        # --compute-stats battery.  See viz/viz_kc_spectrum.md.
        return _missing(tsv, "V3 spectrum",
                        how="a rank grid joined to python3 solve.py --compute-stats; "
                            "see viz/viz_kc_spectrum.md")
    # viz/viz_kc_spectrum.md: `order` is mandatory and never dropped; `i` is the
    # contiguous grid index.
    rows = _read_tsv(tsv, required=("i", "rank", "x", "order"))
    _check_grid(rows, ("i",), tsv)
    skip = {"i", "rank", "x", "order", "walk"}
    obs = [c for c in rows[0] if c not in skip]
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
    fig, axes = plt.subplots(nrow, ncol, figsize=(13, 2.6 * nrow), dpi=150, squeeze=False)
    for idx, name in enumerate(obs):
        a = axes[idx // ncol][idx % ncol]
        a.plot(x, [float(r[name]) for r in rows], ".", ms=2, color="#1f77b4")
        a.set_title(name, fontsize=9)
        a.grid(True, ls=":", alpha=0.4)
        a.tick_params(labelsize=7)
    for idx in range(len(obs), nrow * ncol):
        axes[idx // ncol][idx % ncol].axis("off")
    fig.suptitle(f"V3 — rank spectrum in {orders[0]} order: observable drift across the "
                 f"index (x = rank / N)"
                 + (f"   [{len(const)} constant observable(s) dropped]" if const else ""),
                 fontsize=12)
    fig.tight_layout()
    save(fig, "fig_tr12_kc_spectrum", _prov(tsv))
    return True


def tr12_figures(root="tr12"):
    """Render V1..V5 from the atlas-consumer TSVs rooted at `root`."""
    scan = os.path.join(root, "scan")
    fig_tr12_kc_field(os.path.join(scan, "v1_field.tsv"))
    fig_tr12_kc_river(os.path.join(scan, "v2_river.tsv"),
                      os.path.join(scan, "v2_branches.tsv"))
    fig_tr12_kc_grammar(os.path.join(scan, "v5_grammar.tsv"))
    q3 = os.path.join(root, "q3_profile_kw.tsv")
    fig_tr12_kc_shells(q3 if os.path.exists(q3) else os.path.join(root, "q3_profile.tsv"))
    fig_tr12_kc_spectrum(os.path.join(root, "spectrum", "v3_spectrum.tsv"))


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


if __name__ == "__main__":
    if "--selftest" in sys.argv[1:]:
        sys.exit(_selftest())
    fig_tr6_parity_alternations()
    fig_tr4_boundary_information()
    fig_tr1_rules_tradeoff()
    fig_tr3_campaign_timeline()
    # TR-12 V1..V5: rendered from the atlas-consumer TSVs when they are present.
    # Root defaults to ./tr12 (the TR-12 artifact root); override with argv[1].
    tr12_figures(sys.argv[1] if len(sys.argv) > 1 else "tr12")
