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

Requires: matplotlib, numpy (external — not a dependency of roae.py / solve.c).

Usage:
    cd reports/figures/ && python3 ../../viz/report_figures.py
"""
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


def save(fig, stem):
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
    # bracket (k=5-8) still cut x15-17 per boundary; extrapolated uniqueness at ~15-20
    # boundaries (current; supersedes an earlier ~13-14 estimate; heuristic floor k>=12).
    # NOTE 2026-08-01: the former "hard"-floor-of-13 wording was WITHDRAWN (the exact
    # retracted string is deliberately not repeated here — doc_gates.sh GATE 6 scans this
    # file for registered retracted phrasings and cannot distinguish narration from
    # assertion). The divisor 10.38 is only the
    # unconditional maximum gain, and the same data shows 11.10 at step 3, giving 12; and no
    # necessity bound follows from the argument at all (TR-4 v1.15). The old wording was still
    # RENDERED in the committed SVG, where matplotlib had turned it into glyph paths — invisible
    # to the markdown retraction gate. Regenerate the figure after changing this text.
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

    # weakest-remaining-boundary bracket: k=5-8 still cut x15-17 per boundary
    k_br = np.arange(4, 9)
    ax.fill_between(k_br, S[-1] * (1 / 17.0) ** (k_br - 4), S[-1] * (1 / 15.0) ** (k_br - 4),
                    color="#e8a33d", alpha=0.35,
                    label="weakest-remaining-boundary bracket, ×15–17/boundary (measured, k = 5–8)")

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
                 "(the 4 boundaries that uniquely identify KW in the 560T slice still admit ≈8.4×10²⁵ "
                 "full-space orderings)", fontsize=12)
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
    ax.text(1.7, -0.95,
            "KW keeps the trigram configuration exactly and misses the other three by the minimal "
            "measured margins;\nthe 3-edit grand precursor perfects those three and breaks the trigram "
            "configuration. Both cannot be had.",
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


if __name__ == "__main__":
    fig_tr6_parity_alternations()
    fig_tr4_boundary_information()
    fig_tr1_rules_tradeoff()
    fig_tr3_campaign_timeline()
