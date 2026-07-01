# Visualization — growth curve & campaign telemetry (how the space behaves and how the run executed)

This page collects the **non-PCA** graphs: the solution-count-vs-budget growth curve
(how the canonical set scales with enumeration depth) and, going forward, the campaign
telemetry plots (throughput, CPU frequency, eviction timeline, cells-scanned).

← Back to [README.md](README.md) (index) · See also [viz_pca.md](viz_pca.md) (the 4 PCA scatters)

## Growth-curve plot (`viz_growth_curve.png/.svg`)

![Log-log growth curve of canonical solution count versus per-cell enumeration node budget across the 11.2T, 100T and 560T canonicals, with a sublinear power-law fit (exponent α ≈ 0.67) and a projected — explicitly NOT measured — 1120T point; ×50 budget yields only ×13.86 records.](../runs/20260608_560T_9a968fa2/viz/viz_growth_curve.png)

A non-PCA plot: **canonical solution count vs per-cell enumeration node budget**, log-log,
across the three canonical depths (11.2T → 100T → 560T), with a power-law fit and the projected
1120T point (clearly marked **NOT measured**).

**What it shows:**

- Records grow **sublinearly** with budget: ×50 budget (11.2T→560T) yields only ×13.86 records
  (global power-law exponent α ≈ 0.67; recent-leg α ≈ 0.65). The three measured points
  (11.2T = 759,608,573; 100T = 3,432,399,298; 560T = 10,525,271,997) lie close to the fit line.
- The enumeration is **strictly nested** (11.2T ⊆ 100T ⊆ 560T, 0 monotonicity violations) and
  **deepening, not broadening** — growth is existing productive cells yielding more, not new cells
  opening. None of the sampled sub-branches are exhausted at 560T, so the curve is the growth of a
  fixed-budget *slice*, not an approach to a total. This reframes the 1120T extension as a
  **discriminating test of the growth asymptote**, not merely more data.

See [`../documentation/HISTORY.md`](../documentation/HISTORY.md) §"3-point per-cell scaling
trajectory" for the full analysis, and [`../documentation/CANONICAL_HASHES.md`](../documentation/CANONICAL_HASHES.md) §"d3 560T" for the canonical record.

## Campaign telemetry — 560T re-run (2026-06-22 → 06-29)

Sampled at a 5-minute cadence across the from-scratch 560T re-run (1,254 samples, **7 real Spot
evictions / 8 resume segments**). These are *how the run executed* — reproduced from the preserved
`telemetry.csv`. Grey bands mark VM-off (eviction) intervals; boot-id keys each resume segment.
Captions/axes carry **no cloud identifiers** — only physical quantities.

### Compute & progress
![Multi-panel time-course of throughput, CPU frequency, cells-scanned, and compute progress across the 560T re-run, eviction-resume boundaries marked.](../runs/20260608_560T_9a968fa2/viz/tc_compute.png)

**Throughput** = the depth-3 DFS **enumeration rate**: millions of search-tree nodes visited per second,
summed over all worker threads — this is *search speed, not solutions/sec* (most branches are pruned and
valid orderings are rare). **CPU freq** avg/min across cores. **Cells:** a "cell" is one depth-3 sub-branch
— the King Wen search space split by fixing the first three (pair, orientation) choices
(pair1,orient1,pair2,orient2,pair3,orient3); there are 158,364 such cells, each enumerated independently, and
"with-solutions" counts those that yielded ≥1 valid ordering (most yield none). **Progress** (% of the target
node budget) and **compute-T** (×10¹² nodes cumulative) vs elapsed hours.

### Disk I/O & system health
![Multi-panel time-course of IOPS, disk bandwidth, disk utilization, iowait, queue depth, load average, and available memory across the 560T re-run.](../runs/20260608_560T_9a968fa2/viz/tc_io_system.png)

IOPS read/write, disk bandwidth MB/s read/write, disk utilisation avg + in-tick peak, iowait %, disk average
queue depth, 1-min load average, and available memory (GB) vs elapsed hours.

### Per-resume distributions
![Box-and-whisker plots of throughput, CPU-freq, IOPS-read, iowait and disk-util grouped by resume segment.](../runs/20260608_560T_9a968fa2/viz/per_resume_whiskers.png)

Box-and-whisker of throughput, CPU-freq, IOPS-read, iowait, and disk-util grouped by resume segment (boot-id
keyed; each Spot eviction-resume opens a segment). Reveals warmup/throttle per resume.

### ETA projection
![Cells-scanned trajectory vs elapsed hours with a fitted rate line projecting to the 158,364-cell target.](../runs/20260608_560T_9a968fa2/viz/eta_projection.png)

Cells scanned vs elapsed hours. The rate is fit over **active-enum hours** (eviction downtime excluded) so a
flat-held gap cannot deflate it; the green line projects from the latest sample to the 158,364-cell target
(red star). Grey = downtime; ETA assumes no further evictions.

### Throughput vs CPU-frequency
![Scatter of throughput against CPU-frequency colored by elapsed time, showing the throttle-sensitivity slope.](../runs/20260608_560T_9a968fa2/viz/throughput_vs_cpufreq.png)

Scatter of throughput against CPU-freq, colored by elapsed time. A positive slope quantifies how host
throttling (lower MHz) depresses throughput; clusters reveal per-host/per-resume regimes.

### Eviction timeline
![Horizontal bars for each of the 7 Spot evictions on the elapsed-hours axis, colored by relaunch-policy regime, with weekend shading.](../runs/20260608_560T_9a968fa2/viz/eviction_recovery.png)

One horizontal bar per Spot eviction at its real time on the elapsed-hours axis, spanning the VM-off downtime
and **colored by relaunch-policy regime**: purple = weekday-daytime eviction deferred to 18:01 PT (long by
design), cyan = off-hours/weekend 75-min retry (short). Light-blue background marks weekends (PT). A green ▶
marks resume; the label gives downtime + minutes to recover to ≥95% steady throughput ("instant" = first
sample). Directly answers why some VM-off blocks are ~10 h and others ~75 min. Appears once evictions occur.

A rendered viewer with all six panels + these captions is committed alongside as
[`index.html`](../runs/20260608_560T_9a968fa2/viz/index.html). Future canonical campaigns
(1120T onward) emit the same panels from launch.

## Regeneration

- **Growth curve:** produced by `viz/growth_curve.py` (the dedicated growth-curve generator;
  consolidating it into `visualize.py` as a `--growth` mode is a tracked follow-up, kept separate
  for now).
- **Campaign telemetry (when present):** `python3 viz/visualize.py --telemetry <telemetry.csv>`
  renders the `tc_*` time-course + whisker/ETA panels.

Figures live under `runs/<run-id>/viz/` and are never inlined into `viz/` itself.
See [README.md](README.md) for the full recipe.
