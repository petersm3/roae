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

Data points are the published canonical record counts (see documentation/CANONICAL_HASHES.md;
these are the byte-dispositive counts, NOT re-derived here). To add a future scale (e.g. 1120T)
append one (per_cell_budget, records, label, sha_prefix) row to SCALES.

Requires: matplotlib, numpy (external — not a dependency of roae.py / solve.c).

Usage:
    python3 growth_curve.py            # writes viz_growth_curve.png/.svg to CWD

Output:
    viz_growth_curve.png/.svg
"""
import numpy as np

# (per-cell node budget, canonical records, label, sha prefix) — sourced from
# documentation/CANONICAL_HASHES.md (the authoritative, byte-dispositive counts).
SCALES = [
    (70_723_196,    759_608_573,    "11.2T", "0c0fe37c"),
    (631_456_644,   3_432_399_298,  "100T",  "915abf30"),
    (3_536_157_207, 10_525_271_997, "560T",  "9a968fa2"),
]
# Projection anchor for the planned extension (per-cell budget only; records unknown).
EXT_BUDGET = 7_072_314_414  # 1120T (= 2 x 560T); shown as a dashed projection, not data.
EXT_LABEL = "1120T"


def main():
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt

    budgets = np.array([s[0] for s in SCALES], dtype=float)
    records = np.array([s[1] for s in SCALES], dtype=float)
    labels = [s[2] for s in SCALES]
    shas = [s[3] for s in SCALES]

    # Log-log power-law fit: records = k * budget^alpha  =>  log r = log k + alpha log b
    lb, lr = np.log(budgets), np.log(records)
    alpha, logk = np.polyfit(lb, lr, 1)
    k = np.exp(logk)
    # local exponent over the most recent leg (100T -> 560T)
    alpha_local = (lr[-1] - lr[-2]) / (lb[-1] - lb[-2])
    proj_records = k * (EXT_BUDGET ** alpha)  # power-law projection at the 1120T budget

    fig, ax = plt.subplots(figsize=(10, 7), dpi=150)
    # fitted line across the data + projection span
    xs = np.linspace(budgets.min() * 0.8, EXT_BUDGET * 1.1, 200)
    ax.plot(xs, k * xs ** alpha, "-", color="#1f77b4", lw=1.5, alpha=0.7,
            label=f"power-law fit: records ∝ budget$^{{{alpha:.3f}}}$ (α≈{alpha:.2f} < 1 ⇒ sublinear)")
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
    ax.set_title("King Wen solution count vs enumeration budget — sublinear, strictly nested\n"
                 f"(×50 budget 11.2T→560T → ×{records[-1]/records[0]:.2f} records; "
                 f"global α≈{alpha:.2f}, recent-leg α≈{alpha_local:.2f})", fontsize=12)
    ax.grid(True, which="both", ls=":", alpha=0.4)
    ax.legend(fontsize=9, loc="upper left")
    ax.set_facecolor("#f8f8f8")
    fig.tight_layout()
    fig.savefig("viz_growth_curve.png", dpi=150, bbox_inches="tight")
    fig.savefig("viz_growth_curve.svg", bbox_inches="tight")
    plt.close(fig)
    print(f"alpha(global)={alpha:.4f}  alpha(100T→560T)={alpha_local:.4f}  "
          f"1120T projection={proj_records:,.0f}")
    print("Saved viz_growth_curve.png and viz_growth_curve.svg")


if __name__ == "__main__":
    main()
