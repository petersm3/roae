#!/usr/bin/env python3
# https://github.com/petersm3/roae
# Developed with AI assistance (Claude, Anthropic)
"""
Records-vs-budget growth curve across the canonical scales (11.2T -> 100T -> 560T).

Visualizes the headline scaling finding: the count of canonical (pair-identity-deduped,
C1-C5-satisfying) orderings grows SUBLINEARLY in the per-cell node budget — a power law
records ~ budget^alpha with alpha < 1 — and the canonical record sets are strictly nested
(each larger budget is a superset). The space is not yet saturated, so each scale is a
reproducible slice rather than a final count.

Data points are the published canonical record counts, read from the committed table
viz/viz_scale_inputs.tsv through report_figures._scale_inputs, which asserts every row against
documentation/CANONICAL_HASHES.md (Q-901 follow-up to Q-890, 2026-09-28: this file kept its own
copy of the three rows as literals, a second drift point beside the scale figure's table). The
labels -- the fit's growth class, the endpoint names, the budget and record ratios, the recent leg
-- are derived from the rows read (growth_labels), so a changed table cannot leave a label behind
(Codex VIZ A4-23: an appended superlinear row still printed "alpha < 1 => sublinear" and
"100T->560T"). "strictly nested" is printed only for scales CANONICAL_HASHES.md attests nested.

Requires: matplotlib, numpy (external — not a dependency of roae.py / solve.c).

Usage:
    python3 growth_curve.py            # writes viz_growth_curve.png/.svg to CWD

Output:
    viz_growth_curve.png/.svg
"""
import os
import sys

import numpy as np

# The scales CANONICAL_HASHES.md §"Power-law fit" attests strictly nested under pair-identity keying
# (11.2T ⊆ 100T ⊆ 560T, 0 monotonicity violations, the 2026-06-14 three-point analysis). A scale not
# in this set has no nesting evidence, and the title then does not claim it.
NESTED_ATTESTED = ("11.2T", "100T", "560T")
# Hypothetical 1120T projection anchor; the extension is not planned (CANONICAL_HASHES.md) (per-cell budget only; records unknown).
EXT_LABEL = "1120T"


def load_scales():
    """[(per_cell_budget, records, label, sha8)] in rising budget order, from viz/viz_scale_inputs.tsv,
    each row asserted against CANONICAL_HASHES.md by report_figures._scale_inputs (a table that
    disagrees with the registry raises TsvShapeError; nothing is drawn)."""
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import report_figures as R
    scales, _n = R._scale_inputs(R.SCALE_INPUTS, R.SCALE_REGISTRY, R.SCALE_N_SOURCE)
    return scales


def growth_labels(budgets, records, labels, alpha, alpha_local):
    """(legend label, title, recent-leg name) derived from the plotted rows -- never typed.

    alpha < 1 is sublinear, alpha > 1 superlinear; exactly 1 is linear. The endpoint names are the
    first and last rows' labels, the recent leg is the last two rows', and the ratios are computed
    from the rows. "strictly nested" appears only when every label is in NESTED_ATTESTED."""
    if alpha < 1:
        cls, rel = "sublinear", "< 1"
    elif alpha > 1:
        cls, rel = "superlinear", "> 1"
    else:
        cls, rel = "linear", "= 1"
    legend = f"power-law fit: records ∝ budget$^{{{alpha:.3f}}}$ (α≈{alpha:.2f} {rel} ⇒ {cls})"
    nested = ", strictly nested" if all(l in NESTED_ATTESTED for l in labels) else ""
    title = (f"King Wen solution count vs enumeration budget — {cls}{nested}\n"
             f"(×{budgets[-1] / budgets[0]:.0f} budget {labels[0]}→{labels[-1]} → "
             f"×{records[-1] / records[0]:.2f} records; "
             f"global α≈{alpha:.2f}, recent-leg α≈{alpha_local:.2f})")
    return legend, title, f"{labels[-2]}→{labels[-1]}"


def main():
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    SCALES = load_scales()
    budgets = np.array([s[0] for s in SCALES], dtype=float)
    records = np.array([s[1] for s in SCALES], dtype=float)
    labels = [s[2] for s in SCALES]
    shas = [s[3] for s in SCALES]
    EXT_BUDGET = 2 * SCALES[-1][0]   # 1120T = 2 x the 560T per-cell budget; a dashed projection, not data

    # Log-log power-law fit: records = k * budget^alpha  =>  log r = log k + alpha log b
    lb, lr = np.log(budgets), np.log(records)
    alpha, logk = np.polyfit(lb, lr, 1)
    k = np.exp(logk)
    # local exponent over the most recent leg (the last two rows)
    alpha_local = (lr[-1] - lr[-2]) / (lb[-1] - lb[-2])
    proj_records = k * (EXT_BUDGET ** alpha)  # power-law projection at the 1120T budget
    legend, title, leg = growth_labels(budgets, records, labels, alpha, alpha_local)

    fig, ax = plt.subplots(figsize=(10, 7), dpi=150)
    # fitted line across the data + projection span
    xs = np.linspace(budgets.min() * 0.8, EXT_BUDGET * 1.1, 200)
    ax.plot(xs, k * xs ** alpha, "-", color="#1f77b4", lw=1.5, alpha=0.7,
            label=legend)
    # data points
    ax.scatter(budgets, records, s=90, color="#d32f2f", zorder=5, label="canonical scales (measured)")
    for b, r, lab, sh in zip(budgets, records, labels, shas):
        ax.annotate(f"{lab}\n{r/1e9:.3f} B\n`{sh}`", (b, r),
                    textcoords="offset points", xytext=(8, -28), fontsize=9)
    # 1120T projection (dashed, explicitly NOT measured)
    ax.scatter([EXT_BUDGET], [proj_records], s=90, facecolors="none",
               edgecolors="#388e3c", linewidths=1.8, zorder=5,
               label=f"{EXT_LABEL} power-law projection ≈ {proj_records/1e9:.1f} B (NOT measured)")
    ax.annotate(f"{EXT_LABEL}\n≈{proj_records/1e9:.1f} B (proj.)", (EXT_BUDGET, proj_records),
                textcoords="offset points", xytext=(-10, 12), fontsize=9, color="#2e7d32")

    ax.set_xscale("log"); ax.set_yscale("log")
    ax.set_xlabel("per-cell node budget (log scale)", fontsize=12)
    ax.set_ylabel("canonical orderings (log scale)", fontsize=12)
    ax.set_title(title, fontsize=12)
    ax.grid(True, which="both", ls=":", alpha=0.4)
    ax.legend(fontsize=9, loc="upper left")
    ax.set_facecolor("#f8f8f8")
    fig.tight_layout()
    fig.savefig("viz_growth_curve.png", dpi=150, bbox_inches="tight")
    fig.savefig("viz_growth_curve.svg", bbox_inches="tight")
    plt.close(fig)
    print(f"alpha(global)={alpha:.4f}  alpha({leg})={alpha_local:.4f}  "
          f"1120T projection={proj_records:,.0f}")
    print("Saved viz_growth_curve.png and viz_growth_curve.svg")


if __name__ == "__main__":
    main()
