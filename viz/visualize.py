#!/usr/bin/env python3
# https://github.com/petersm3/roae
# Developed with AI assistance (Claude, Anthropic)
"""
Visualization of the King Wen sequence solution space.

Reads solutions.bin (output of solve.c) and generates 2D projections
using PCA, with multiple color schemes highlighting different properties.

Handles millions of solutions efficiently:
  - Feature computation is vectorized with numpy
  - PCA runs on full dataset (32x32 covariance — always fast)
  - Plots subsample to MAX_PLOT_POINTS for readability

Requires: matplotlib, numpy (external dependencies — not required by roae.py or solve.py)

Usage:
    python3 visualize.py [solutions.bin]

Output:
    viz_edit_distance.png/.svg   — colored by edit distance from King Wen
    viz_complement_dist.png/.svg — colored by complement distance
    viz_position2_cluster.png/.svg — colored by which pair is at position 2
    viz_adjacency.png/.svg       — colored by C6/C7 adjacency satisfaction
"""
import sys
import numpy as np

MAX_PLOT_POINTS = 200_000      # subsample for plotting; PCA uses MAX_RECORDS
MAX_RECORDS = 1_000_000        # cap records loaded+analyzed — keeps RAM bounded at 100T+ scale
                                # (at N=1M, PCA is <2 sec and shows all structural clusters;
                                # raising above 10M requires >64 GB RAM)

# King Wen sequence
KW = [
    63,  0, 17, 34, 23, 58,  2, 16,
    55, 59,  7, 56, 61, 47,  4,  8,
    25, 38,  3, 48, 41, 37, 32,  1,
    57, 39, 33, 30, 18, 45, 28, 14,
    60, 15, 40,  5, 53, 43, 20, 10,
    35, 49, 31, 62, 24,  6, 26, 22,
    29, 46,  9, 36, 52, 11, 13, 44,
    54, 27, 50, 19, 51, 12, 21, 42
]

TOTAL_RECORDS_IN_FILE = None   # populated by load_solutions() — used for plot titles

def load_solutions(filename):
    """Load solutions.bin. Auto-detects format via magic-byte check (format v1)
    or file-size modulo (legacy formats):
    - Format v1: 32-byte header (magic "ROAE" + u32 version + u64 record_count
      + 16 reserved) followed by N × 32-byte packed records
      (byte i = (pair_index<<2)|(orient<<1)). PRIMARY format.
    - 68-byte records: legacy 64 canonical + 4 orientation bitmask (no header)
    - 64-byte records: oldest legacy, 64 canonical hexagram values, no header
    - 32-byte records, no header: pre-v1 packed format

    At 100T+ scale (100 GB+ files), uses memory-mapped access + uniform
    subsampling to MAX_RECORDS so only O(MAX_RECORDS × 32) bytes land in RAM.

    Returns canonical 64-byte representation (lo, hi per pair) for all formats."""
    import os
    import struct
    file_size = os.path.getsize(filename)

    kw_pairs = [(KW[i], KW[i+1]) for i in range(0, 64, 2)]

    # Peek at magic bytes without loading full file
    with open(filename, 'rb') as f:
        magic = f.read(4)

    # Check for format v1 magic ('ROAE' at offset 0)
    if file_size >= 32 and magic == b'ROAE':
        # Format v1: 32-byte header + N × 32-byte records
        # Header: magic (4) + version u32 LE (4) + record_count u64 LE (8) + reserved (16)
        with open(filename, 'rb') as f:
            f.seek(4)
            version = struct.unpack('<I', f.read(4))[0]
            record_count = struct.unpack('<Q', f.read(8))[0]
        record_bytes = file_size - 32
        if record_bytes % 32 != 0:
            raise ValueError(f"Format v1 record stream {record_bytes} bytes after header is not a multiple of 32")
        actual_records = record_bytes // 32
        if actual_records != record_count:
            raise ValueError(f"Format v1 header claims {record_count} records but file has {actual_records}")
        # Record total count for downstream labeling
        global TOTAL_RECORDS_IN_FILE
        TOTAL_RECORDS_IN_FILE = actual_records
        # Subsample to MAX_RECORDS via reservoir sampling over sequential read.
        # Sequential access gets full disk bandwidth (~60 MB/s Standard HDD,
        # >500 MB/s Premium SSD) vs random mmap-index which hits HDD seek
        # latency (~5 ms/seek * 1M seeks = 80+ min). With 102 GB file the
        # sequential read takes ~28 min on Standard HDD, ~3 min on Premium.
        # Deterministic with fixed seed=42.
        if actual_records > MAX_RECORDS:
            rng = np.random.default_rng(seed=42)
            # Algorithm R (Waterman/Knuth): one-pass reservoir sampling.
            # Fill reservoir with first k records, then for i>=k, with
            # probability k/(i+1) replace reservoir[j] where j = rng.integers(i+1).
            # Produces a uniformly random k-subset of the N records.
            k = MAX_RECORDS
            reservoir = np.zeros((k, 32), dtype=np.uint8)
            # Read sequentially in chunks (avoids loading full 102 GB)
            CHUNK_RECORDS = 1_000_000  # ~32 MB per chunk
            records_seen = 0
            last_progress = 0
            import time as _time
            t0 = _time.time()
            with open(filename, 'rb') as f:
                f.seek(32)  # skip header
                while True:
                    chunk_bytes = f.read(CHUNK_RECORDS * 32)
                    if not chunk_bytes:
                        break
                    chunk = np.frombuffer(chunk_bytes, dtype=np.uint8).reshape(-1, 32)
                    n_chunk = chunk.shape[0]
                    # Vectorized Algorithm R reservoir update:
                    # For each record at absolute position i, draw j ~ Uniform{0..i},
                    # if j < k replace reservoir[j] <- chunk[record]. Equivalent to
                    # sampling u~U(0,1) then j = floor(u * (i+1)). We do this for
                    # all records in the chunk at once via numpy.
                    i_abs = records_seen + np.arange(n_chunk, dtype=np.int64)
                    # Warmup: fill slots 0..k-1 with the first k records seen
                    warmup_end = min(k, records_seen + n_chunk)
                    if records_seen < k:
                        warmup_n = warmup_end - records_seen
                        reservoir[records_seen:warmup_end] = chunk[:warmup_n]
                        remaining_start = warmup_n
                    else:
                        remaining_start = 0
                    # For remaining chunk records (those with i_abs >= k), do probabilistic replace
                    if remaining_start < n_chunk:
                        remaining = chunk[remaining_start:]
                        remaining_i = i_abs[remaining_start:]
                        # Sample j for each remaining record: j ~ U{0..i}
                        u = rng.random(size=remaining.shape[0])
                        js = np.floor(u * (remaining_i + 1)).astype(np.int64)
                        mask = js < k
                        if mask.any():
                            # reservoir[js[mask]] = remaining[mask]; numpy last-write-wins
                            # on duplicate indices — correct for Algorithm R (record with
                            # highest i targeting a slot is the one that "stays", and the
                            # chunk is in ascending i order)
                            reservoir[js[mask]] = remaining[mask]
                    records_seen += n_chunk
                    # Progress every ~1 GB of reading
                    if records_seen - last_progress >= 32_000_000:
                        elapsed = _time.time() - t0
                        pct = 100.0 * records_seen / actual_records
                        mb_per_s = (records_seen * 32) / (elapsed * 1e6) if elapsed > 0 else 0
                        eta_sec = (elapsed / records_seen) * (actual_records - records_seen) if records_seen > 0 else 0
                        print(f"    reservoir-sample progress: {records_seen:,} / {actual_records:,} "
                              f"({pct:.1f}%) {mb_per_s:.0f} MB/s ETA {eta_sec:.0f}s",
                              flush=True)
                        last_progress = records_seen
            raw = reservoir
            n_solutions = k
            print(f"  Loaded {actual_records:,} solutions from {filename} (format v{version}); "
                  f"uniformly subsampled to {n_solutions:,} via one-pass reservoir sampling (seed=42)")
            print(f"  ⚠️  Subsampling rate: 1 in {actual_records // MAX_RECORDS} records kept. "
                  f"Rare structural outliers (e.g., C3-extremal records) may be missing from the sample.")
            # Always inject King Wen so plots can mark it as a reference point,
            # regardless of whether random sampling caught it (probability
            # 1 - (1 - 1/N)^k which for N=3.43B, k=1M is ~0.003%). KW's raw
            # record is bytes [0, 4, 8, ..., 124] — (pair_index << 2) with
            # orient=0. Overwrites the last reservoir slot; one uniform sample
            # is displaced but the statistical distribution is unchanged at k>>1.
            kw_raw = np.arange(32, dtype=np.uint8) << 2
            already_present = bool(np.all(raw == kw_raw, axis=1).any())
            if not already_present:
                raw[-1] = kw_raw  # displace one random sample; 1/k effect on distribution
                print(f"  King Wen not in sample (expected at 1/{actual_records // MAX_RECORDS} rate); "
                      f"injected as the last record so plots can mark it as the reference star. "
                      f"(One random sample displaced; statistical distribution preserved at k>>1.)")
            else:
                print(f"  King Wen present in the random sample (rare event).")
        else:
            # Small file — fully load into memory
            mm = np.memmap(filename, dtype=np.uint8, mode='r', offset=32,
                           shape=(actual_records, 32))
            raw = np.array(mm)
            n_solutions = actual_records
            print(f"  Loaded {n_solutions:,} solutions from {filename} (format v{version} — 32-byte header + 32-byte records)")
            del mm
        # Decode: pair_index = byte >> 2, expand to (lo, hi) canonical pairs
        solutions = np.zeros((n_solutions, 64), dtype=np.uint8)
        for i in range(32):
            pidx = raw[:, i] >> 2  # pair indices for all solutions at position i
            for pi in range(32):
                mask = pidx == pi
                a, b = kw_pairs[pi]
                lo, hi = min(a, b), max(a, b)
                solutions[mask, i*2] = lo
                solutions[mask, i*2+1] = hi
    elif len(data) % 32 == 0 and len(data) % 64 != 0 and len(data) % 68 != 0:
        # Pre-v1 packed 32-byte records, no header
        n_solutions = len(data) // 32
        raw = np.frombuffer(data, dtype=np.uint8).reshape(n_solutions, 32)
        solutions = np.zeros((n_solutions, 64), dtype=np.uint8)
        for i in range(32):
            pidx = raw[:, i] >> 2
            for pi in range(32):
                mask = pidx == pi
                a, b = kw_pairs[pi]
                lo, hi = min(a, b), max(a, b)
                solutions[mask, i*2] = lo
                solutions[mask, i*2+1] = hi
        print(f"  Loaded {n_solutions:,} solutions from {filename} (pre-v1 32-byte packed records, no header)")
    elif len(data) % 68 == 0 and (len(data) // 68) * 68 == len(data) and len(data) % 64 != 0:
        # 68-byte format
        n_solutions = len(data) // 68
        raw = np.frombuffer(data, dtype=np.uint8).reshape(n_solutions, 68)
        solutions = raw[:, :64].copy()
        print(f"  Loaded {n_solutions:,} solutions from {filename} (68-byte legacy records)")
    elif len(data) % 64 == 0:
        # 64-byte format
        n_solutions = len(data) // 64
        solutions = np.frombuffer(data, dtype=np.uint8).reshape(n_solutions, 64)
        print(f"  Loaded {n_solutions:,} solutions from {filename} (64-byte legacy records)")
    else:
        raise ValueError(f"File size {len(data)} does not match any known format (no ROAE magic; not divisible by 32, 68, or 64)")
    return solutions

def compute_features(solutions):
    """Convert each solution to a 32-element feature vector (pair index at each position).
    Vectorized: builds a 64x64 lookup table, then indexes into it."""
    kw_pairs = [(KW[i], KW[i+1]) for i in range(0, 64, 2)]

    # Build lookup: pair_lookup[lo][hi] = pair_index
    pair_lookup = np.full((64, 64), -1, dtype=np.int8)
    for i, (a, b) in enumerate(kw_pairs):
        lo, hi = min(a, b), max(a, b)
        pair_lookup[lo, hi] = i

    # Extract lo/hi pairs for all solutions at once
    even = solutions[:, 0::2]  # shape: (n, 32) — first element of each pair
    odd = solutions[:, 1::2]   # shape: (n, 32) — second element of each pair
    lo = np.minimum(even, odd)
    hi = np.maximum(even, odd)

    # Vectorized lookup
    features = pair_lookup[lo, hi]
    return features

def compute_edit_distances(features, kw_features):
    """Edit distance = number of positions where pair differs from King Wen."""
    return np.sum(features != kw_features, axis=1)

def compute_complement_distances(solutions):
    """Complement distance (x64) for each solution. Vectorized."""
    n = len(solutions)
    # Build position arrays: pos[i, v] = position of hexagram v in solution i
    # Solutions are canonical pairs (lo, hi), so we work with the 64-byte representation
    # Each byte is a hexagram value (0-63), positions 0-63
    pos = np.zeros((n, 64), dtype=np.int32)
    for j in range(64):
        vals = solutions[:, j].astype(np.int32)
        # For each solution, pos[val] = j
        np.put_along_axis(pos, vals.reshape(-1, 1), j, axis=1)

    # Compute sum of |pos[v] - pos[v^63]| for all v where v != v^63
    total = np.zeros(n, dtype=np.int64)
    for v in range(64):
        comp = v ^ 63
        if comp > v:  # count each pair once, multiply by 2
            total += np.abs(pos[:, v] - pos[:, comp])
    total *= 2  # symmetric: |pos[v]-pos[comp]| counted once, need both directions
    return total

def compute_position2_pairs(features):
    """Which pair is at position 2 (first variable position)."""
    return features[:, 1]  # 0-indexed

def compute_adjacency_satisfaction(features):
    """Check C6/C7 adjacency constraints. Vectorized."""
    kw_pairs = [(KW[i], KW[i+1]) for i in range(0, 64, 2)]
    def pidx(x, y):
        lo, hi = min(x, y), max(x, y)
        for i, (a, b) in enumerate(kw_pairs):
            if min(a, b) == lo and max(a, b) == hi:
                return i
        return -1

    c6a = pidx(KW[52], KW[53])
    c6b = pidx(KW[54], KW[55])
    c7a = pidx(KW[48], KW[49])
    c7b = pidx(KW[50], KW[51])

    c6 = (features[:, 26] == c6a) & (features[:, 27] == c6b)
    c7 = (features[:, 24] == c7a) & (features[:, 25] == c7b)
    return c6.astype(np.int8) + c7.astype(np.int8)

def find_king_wen(features):
    """Find King Wen's index in the solution set. Vectorized."""
    kw_features = np.arange(32, dtype=np.int8)
    matches = np.all(features == kw_features, axis=1)
    indices = np.where(matches)[0]
    return int(indices[0]) if len(indices) > 0 else -1

def project_pca(features, n_components=2):
    """PCA projection to 2D. Covariance matrix is 32x32 regardless of how many
    solutions exist, so this runs in seconds even on 100M+ solutions. The projection
    (matrix multiply) is O(n) but numpy-vectorized. PCA uses ALL data to capture the
    true variance structure; only plotting subsamples afterward (see MAX_PLOT_POINTS)."""
    mean = np.mean(features.astype(np.float64), axis=0)
    centered = features.astype(np.float64) - mean
    cov = np.cov(centered.T)
    eigenvalues, eigenvectors = np.linalg.eigh(cov)
    idx = np.argsort(eigenvalues)[::-1]
    sel = idx[:n_components]
    eigenvectors = eigenvectors[:, sel]
    projected = centered @ eigenvectors
    total_var = float(np.sum(eigenvalues))
    var_explained = (eigenvalues[sel] / total_var) if total_var else np.zeros(n_components)
    return projected, var_explained

def subsample_indices(n, max_points, kw_idx=-1):
    """Generate subsample indices, always including King Wen if present."""
    if n <= max_points:
        return np.arange(n)
    rng = np.random.default_rng(42)  # reproducible
    idx = rng.choice(n, size=max_points, replace=False)
    if kw_idx >= 0 and kw_idx not in idx:
        idx[0] = kw_idx  # ensure KW is included
    return np.sort(idx)

def generate_plots(solutions, features, projected, kw_idx, var_explained=None):
    """Generate all four visualization PNGs and SVGs."""
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt

    # Axis labels carry the % of total variance each principal component captures,
    # so a reader can see how much structure the 2D projection actually preserves.
    pc1lab = f'PC1 ({var_explained[0]*100:.1f}% of variance)' if var_explained is not None else 'PC1'
    pc2lab = f'PC2 ({var_explained[1]*100:.1f}% of variance)' if var_explained is not None else 'PC2'

    n = len(features)
    sub_idx = subsample_indices(n, MAX_PLOT_POINTS, kw_idx)
    sub_kw_idx = -1
    if kw_idx >= 0:
        sub_kw_idx = int(np.searchsorted(sub_idx, kw_idx))
        if sub_kw_idx >= len(sub_idx) or sub_idx[sub_kw_idx] != kw_idx:
            sub_kw_idx = -1

    x = projected[sub_idx, 0]
    y = projected[sub_idx, 1]
    n_plotted = len(sub_idx)

    if n > MAX_PLOT_POINTS:
        print(f"  Subsampling {n:,} -> {n_plotted:,} points for plots (PCA used all {n:,})")

    def save_plot(colors, cmap, title, filename, colorbar_label=None,
                  categorical=False, alpha=0.3, size=1):
        fig, ax = plt.subplots(figsize=(12, 10), dpi=150)
        scatter = ax.scatter(x, y, c=colors, cmap=cmap, s=size, alpha=alpha,
                           edgecolors='none', rasterized=True)
        if sub_kw_idx >= 0:
            ax.scatter([x[sub_kw_idx]], [y[sub_kw_idx]], c='gold', s=100,
                      edgecolors='black', linewidths=2, zorder=10, marker='*',
                      label='King Wen')
            ax.legend(fontsize=12, loc='upper right')
        if colorbar_label and not categorical:
            cb = plt.colorbar(scatter, ax=ax, shrink=0.8)
            cb.set_label(colorbar_label, fontsize=12)
        if TOTAL_RECORDS_IN_FILE is not None and TOTAL_RECORDS_IN_FILE > n:
            subtitle = (f"({n:,} solutions subsampled from {TOTAL_RECORDS_IN_FILE:,} "
                        f"canonical records, seed=42"
                        + (f"; {n_plotted:,} plotted" if n > MAX_PLOT_POINTS else "")
                        + ")")
        else:
            subtitle = f"({n:,} solutions" + (f", {n_plotted:,} plotted" if n > MAX_PLOT_POINTS else "") + ")"
        ax.set_title(f"{title}\n{subtitle}", fontsize=14)
        ax.set_xlabel(pc1lab, fontsize=12)
        ax.set_ylabel(pc2lab, fontsize=12)
        ax.set_facecolor('#f8f8f8')
        fig.tight_layout()
        fig.savefig(filename + '.png', dpi=150, bbox_inches='tight')
        fig.savefig(filename + '.svg', bbox_inches='tight')
        plt.close(fig)
        print(f"  Saved {filename}.png and {filename}.svg")

    print("\nGenerating visualizations...")

    # 1. Edit distance from King Wen
    kw_features = np.arange(32, dtype=np.int8)
    edit_dists = compute_edit_distances(features[sub_idx], kw_features)
    save_plot(edit_dists, 'RdYlBu_r',
              'King Wen Solution Space — Edit Distance',
              'viz_edit_distance',
              colorbar_label='Pair positions different from King Wen')

    # 2. Complement distance
    print("  Computing complement distances...")
    comp_dists = compute_complement_distances(solutions[sub_idx])
    save_plot(comp_dists, 'viridis',
              'King Wen Solution Space — Complement Distance',
              'viz_complement_dist',
              colorbar_label='Complement distance (x64)')

    # 3. Position 2 clusters
    pos2 = compute_position2_pairs(features[sub_idx])
    n_unique = len(np.unique(pos2))
    save_plot(pos2, 'tab20' if n_unique <= 20 else 'hsv',
              f'King Wen Solution Space — Pair at Position 2 ({n_unique} clusters)',
              'viz_position2_cluster',
              categorical=True)

    # 4. C6/C7 adjacency satisfaction
    # Build legend with proxy artists so legend markers are readable —
    # plot dots use s=1/alpha=0.3 which renders as invisible legend swatches.
    from matplotlib.lines import Line2D
    adj = compute_adjacency_satisfaction(features[sub_idx])
    fig, ax = plt.subplots(figsize=(12, 10), dpi=150)
    legend_handles = []
    for val, color, label in [(0, '#d32f2f', 'Neither C6 nor C7'),
                               (1, '#fbc02d', 'One of C6/C7'),
                               (2, '#388e3c', 'Both C6 + C7')]:
        mask = adj == val
        ax.scatter(x[mask], y[mask], c=color, s=1, alpha=0.3,
                  edgecolors='none', rasterized=True)
        legend_handles.append(Line2D([0], [0], marker='o', linestyle='none',
                                     markerfacecolor=color, markeredgecolor='none',
                                     markersize=10, label=f'{label} ({mask.sum():,})'))
    if sub_kw_idx >= 0:
        ax.scatter([x[sub_kw_idx]], [y[sub_kw_idx]], c='gold', s=100,
                  edgecolors='black', linewidths=2, zorder=10, marker='*')
        legend_handles.append(Line2D([0], [0], marker='*', linestyle='none',
                                     markerfacecolor='gold', markeredgecolor='black',
                                     markeredgewidth=1, markersize=14, label='King Wen'))
    ax.legend(handles=legend_handles, fontsize=10, loc='upper right')
    subtitle = f"({n:,} solutions" + (f", {n_plotted:,} plotted" if n > MAX_PLOT_POINTS else "") + ")"
    ax.set_title(f'King Wen Solution Space — Adjacency Constraint Satisfaction\n{subtitle}', fontsize=14)
    ax.set_xlabel(pc1lab, fontsize=12)
    ax.set_ylabel(pc2lab, fontsize=12)
    ax.set_facecolor('#f8f8f8')
    fig.tight_layout()
    fig.savefig('viz_adjacency.png', dpi=150, bbox_inches='tight')
    fig.savefig('viz_adjacency.svg', bbox_inches='tight')
    plt.close(fig)
    print("  Saved viz_adjacency.png and viz_adjacency.svg")

def plot_telemetry(csv_path, outdir='.'):
    """Operational campaign-telemetry plots from campaign_telemetry_sampler.sh CSV.

    Produces (1) a time-course multi-panel (throughput / cpu-freq / cells / compute-progress /
    IOPS / disk-util+iowait) with eviction-resume boundaries marked, and (2) per-resume whisker
    (box) plots of throughput and cpu-freq. Intended for the 560T re-run (and future canonical
    campaigns). PNGs are written to outdir — point that OUTSIDE the git repo for transient
    operator review; at archive time it can target the run's committed viz/ dir.

    This is infra/operational plotting (not solution-space science); it shares this file only
    because matplotlib already lives here and the single-file rule sanctions viz/visualize.py
    as the project's plotting home. It does not touch solve.c / the canonical (sha-neutral)."""
    import os
    import csv as _csv
    from datetime import datetime, timezone, timedelta
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt

    with open(csv_path) as f:
        rows = list(_csv.DictReader(f))
    if not rows:
        print("plot_telemetry: no rows in", csv_path); return

    def num(r, k):
        try: return float(r.get(k, 'NA'))
        except (ValueError, TypeError): return float('nan')
    def tparse(s):
        return datetime.strptime(s, '%Y-%m-%dT%H:%M:%SZ').replace(tzinfo=timezone.utc)

    def col(k): return [num(r, k) for r in rows]
    t0 = tparse(rows[0]['utc'])
    secs = [(tparse(r['utc']) - t0).total_seconds() for r in rows]
    hrs = [s / 3600.0 for s in secs]
    resume = [int(num(r, 'resume_seq')) if num(r, 'resume_seq') == num(r, 'resume_seq') else 0 for r in rows]
    bnds = [hrs[i] for i in range(1, len(rows)) if resume[i] != resume[i - 1]]  # eviction/resume points
    segs = sorted(set(resume))
    os.makedirs(outdir, exist_ok=True)
    host0 = rows[0].get('host', '?')

    # Downtime gaps: consecutive samples separated by >> the 5-min sample cadence mean the VM was
    # OFF (Spot eviction / deallocation) — there is NO data in that interval. We must NOT connect a
    # straight line across it. Rate/activity metrics are drawn dropping to 0 (no work happened);
    # cumulative/level metrics hold their last value flat (progress paused, not lost). The interval
    # is shaded. Gap detection is purely time-based so it catches downtime even without a boot flip.
    GAP_SEC = 900.0   # 3× the 300s cadence
    gaps_h = [(secs[i - 1] / 3600.0, secs[i] / 3600.0)
              for i in range(1, len(secs)) if secs[i] - secs[i - 1] > GAP_SEC]
    RATE_KEYS = {'throughput_M_s', 'cpu_freq_avg_mhz', 'cpu_freq_min_mhz', 'iops_read', 'iops_write',
                 'rd_mbps', 'wr_mbps', 'disk_util_pct', 'disk_util_peak_pct', 'iowait_pct',
                 'avg_queue', 'load1'}

    def series(k):
        """(X, Y) in hours with downtime rendered honestly: rate metrics drop to 0 across each gap,
        cumulative/level metrics hold the last pre-gap value flat. No straight interpolation."""
        y = col(k); rate = k in RATE_KEYS; X = []; Y = []
        eps = 1e-6
        for i in range(len(rows)):
            if i > 0 and (secs[i] - secs[i - 1] > GAP_SEC):
                fill = 0.0 if rate else y[i - 1]
                X.append(hrs[i - 1] + eps); Y.append(fill)   # drop/hold at gap start
                X.append(hrs[i] - eps);     Y.append(fill)   # …across the downtime…
            X.append(hrs[i]); Y.append(y[i])                 # real sample
        return X, Y

    def shade_gaps(ax):
        # Shade every downtime span; do NOT put it in the per-panel legend (it's explained once in
        # the figure title, so it appears consistently on ALL panels, not just multi-series ones).
        for a, b in gaps_h:
            ax.axvspan(a, b, color='0.82', alpha=0.6, zorder=0, label='_nolegend_')
    gap_note = '; grey = VM off (eviction)' if gaps_h else ''

    # Derived reference levels + a thousands-separator y-formatter (commas for big values, keep
    # small decimals readable).
    from matplotlib.ticker import FuncFormatter
    def _yfmt(x, _):
        return f'{x:,.0f}' if abs(x) >= 100 else f'{x:,.3g}'
    YFMT = FuncFormatter(_yfmt)
    TOTAL = 158364                                          # depth-3 cell count (target)
    _pc = col('pct_complete'); _ct = col('compute_T')
    _tt = [c / p * 100.0 for c, p in zip(_ct, _pc) if p == p and c == c and p > 0]
    target_T = float(np.median(_tt)) if _tt else None       # node budget in ×10¹² (≈560 for 560T)
    _tp = [v for v in col('throughput_M_s') if v == v and v > 0]
    mean_tp = float(np.mean(_tp)) if _tp else None
    # active-enum hours = elapsed minus cumulative downtime (so an eviction's flat-hold can't deflate
    # the rate fit). Built once; used by the ETA projection.
    _cum = 0.0; active_h = []
    for i in range(len(hrs)):
        if i > 0 and (secs[i] - secs[i - 1] > GAP_SEC):
            _cum += (secs[i] - secs[i - 1]) / 3600.0
        active_h.append(hrs[i] - _cum)
    downtime_h = _cum

    manifest = []  # (filename, title, description) for index.html

    def timecourse(fname, title, desc, panels):
        n = len(panels)
        fig, axes = plt.subplots(n, 1, figsize=(13, 2.5 * n), sharex=True)
        if n == 1: axes = [axes]
        for ax, p in zip(axes, panels):
            keys, ylabel, labels = p[0], p[1], p[2]
            refs = p[3] if len(p) > 3 else []   # optional [(value, label), …] dotted reference lines
            shade_gaps(ax)
            for k, lab in zip(keys, labels):
                X, Y = series(k)
                ax.plot(X, Y, lw=1.2, label=lab)
            for rv, rl in refs:
                if rv is not None: ax.axhline(rv, color='0.45', ls=':', lw=1.0, label=rl)
            if len(keys) > 1 or refs: ax.legend(loc='upper left', fontsize=8)
            ax.set_ylabel(ylabel, fontsize=9); ax.grid(alpha=0.3)
            ax.yaxis.set_major_formatter(YFMT)
            for b in bnds: ax.axvline(b, color='tab:red', ls='--', lw=0.8, alpha=0.6)
        axes[-1].set_xlabel('elapsed hours since launch')
        axes[0].set_title(f'{title} — {host0} — {len(rows)} samples — red dashed = eviction/resume{gap_note}',
                          fontsize=11)
        fig.savefig(os.path.join(outdir, fname), dpi=140, bbox_inches='tight'); plt.close(fig)
        manifest.append((fname, title, desc))

    # (1) compute & progress time-course
    timecourse('tc_compute.png', 'Compute & progress',
        'Throughput (M nodes/s), CPU freq avg/min, cells scanned + cells-with-solutions, progress '
        '(% of the target node budget), and compute-T (×10¹² nodes) vs elapsed hours.',
        [(('throughput_M_s',), 'Throughput (M/s)', ('throughput',),
            [(mean_tp, f'mean {mean_tp:,.0f}')] if mean_tp else []),
         (('cpu_freq_avg_mhz', 'cpu_freq_min_mhz'), 'CPU freq (MHz)', ('avg', 'min')),
         (('cells_scanned', 'cells_with_solutions'), 'Cells', ('scanned', 'with-solns'),
            [(TOTAL, f'target {TOTAL:,}')]),
         (('pct_complete',), 'Progress (% target)', ('pct',), [(100, 'target 100%')]),
         (('compute_T',), 'compute-T (×10¹²)', ('compute_T',),
            [(target_T, f'target {target_T:,.0f}T')] if target_T else [])])

    # (2) disk I/O & system-health time-course (the previously-unplotted columns)
    timecourse('tc_io_system.png', 'Disk I/O & system health',
        'IOPS read/write, disk bandwidth MB/s read/write, disk utilisation avg + in-tick peak, '
        'iowait %, disk average queue depth, 1-min load average, and available memory (GB) vs elapsed hours.',
        [(('iops_read', 'iops_write'), 'IOPS', ('read', 'write')),
         (('rd_mbps', 'wr_mbps'), 'Disk MB/s', ('read', 'write')),
         (('disk_util_pct', 'disk_util_peak_pct'), 'Disk util %', ('avg', 'peak')),
         (('iowait_pct',), 'iowait %', ('iowait',)),
         (('avg_queue',), 'Disk avg queue', ('queue',)),
         (('load1',), 'Load avg (1m)', ('load1',)),
         (('mem_avail_gb',), 'Mem avail (GB)', ('mem',))])

    # (3) per-resume whiskers — 5 metrics
    wkeys = [('throughput_M_s', 'Throughput (M/s)'), ('cpu_freq_avg_mhz', 'CPU freq avg (MHz)'),
             ('iops_read', 'IOPS read'), ('iowait_pct', 'iowait %'), ('disk_util_pct', 'disk util %')]
    figw, axsw = plt.subplots(1, len(wkeys), figsize=(3.6 * len(wkeys), 5))
    if len(wkeys) == 1: axsw = [axsw]
    for ax, (key, ttl) in zip(axsw, wkeys):
        data = []
        for s in segs:
            vals = [num(r, key) for r, rs in zip(rows, resume) if rs == s and num(r, key) == num(r, key)]
            data.append(vals if vals else [float('nan')])
        ax.boxplot(data, showmeans=True)
        _cnt = [sum(1 for rs in resume if rs == s) for s in segs]
        ax.set_xticks(range(1, len(segs) + 1))
        ax.set_xticklabels([f'r{s}\n(n={c})' for s, c in zip(segs, _cnt)], fontsize=8)
        ax.set_title(ttl, fontsize=10); ax.set_xlabel('resume seg'); ax.grid(alpha=0.3)
    figw.suptitle(f'Per-resume distributions ({len(segs)} segment(s); each Spot resume = a segment)',
                  fontsize=11)
    figw.savefig(os.path.join(outdir, 'per_resume_whiskers.png'), dpi=140, bbox_inches='tight'); plt.close(figw)
    manifest.append(('per_resume_whiskers.png', 'Per-resume distributions',
        'Box-and-whisker of throughput, CPU-freq, IOPS-read, iowait, and disk-util grouped by resume '
        'segment (boot-id keyed; each Spot eviction-resume opens a segment). Reveals warmup/throttle per resume.'))

    # (4) ETA projection: cells_scanned vs time, rate fit over ACTIVE-ENUM hours (downtime excluded)
    # so an eviction's flat-hold doesn't deflate the rate. Projection drawn from the last sample
    # forward at the true rate (assuming no further downtime).
    cs = col('cells_scanned')
    fit = [(a, c) for a, c in zip(active_h, cs) if c == c and c > 0]
    fige, axe = plt.subplots(figsize=(12, 6))
    shade_gaps(axe)
    Xc, Yc = series('cells_scanned')                       # holds flat across downtime (cumulative)
    axe.plot(Xc, Yc, '-', lw=1, color='tab:blue', label='cells scanned')
    axe.plot(hrs, cs, 'o', ms=3, color='tab:blue')         # markers on real samples only
    axe.axhline(TOTAL, color='gray', ls=':', label=f'target {TOTAL:,}')
    eta_txt = 'insufficient data for ETA'
    if len(fit) >= 2:
        xa = np.array([p[0] for p in fit]); ya = np.array([p[1] for p in fit])
        k = max(2, len(fit) // 2)                          # fit recent half on ACTIVE hours
        m, b = np.polyfit(xa[-k:], ya[-k:], 1)             # cells per ACTIVE hour
        if m > 0:
            x_last, y_last = hrs[-1], cs[-1]
            rem = (TOTAL - y_last) / m                      # active hours remaining (≈ wall, continuous from now)
            x_eta = x_last + rem
            axe.plot([x_last, x_eta], [y_last, TOTAL], '--', color='tab:green', lw=1.4,
                     label=f'active rate {m:,.0f} cells/h')
            axe.plot([x_eta], [TOTAL], '*', color='tab:red', ms=16)
            eta_dt = t0 + timedelta(hours=x_eta)
            eta_txt = (f'~{rem:.1f}h active remaining (~{rem/24:.1f}d), ETA {eta_dt:%Y-%m-%d %H:%MZ} '
                       f'· {downtime_h:.1f}h downtime so far (excluded from rate; future evictions push ETA right)')
    for b in bnds: axe.axvline(b, color='tab:red', ls='--', lw=0.8, alpha=0.5)
    axe.set_xlabel('elapsed hours'); axe.set_ylabel('cells scanned'); axe.grid(alpha=0.3)
    axe.yaxis.set_major_formatter(YFMT)
    axe.legend(loc='upper left', fontsize=9); axe.set_title(f'ETA projection — {eta_txt}{gap_note}', fontsize=10)
    fige.savefig(os.path.join(outdir, 'eta_projection.png'), dpi=140, bbox_inches='tight'); plt.close(fige)
    manifest.append(('eta_projection.png', 'ETA projection',
        'Cells scanned vs elapsed hours. The rate is fit over ACTIVE-ENUM hours (eviction downtime '
        'excluded) so a flat-held gap cannot deflate it; the green line projects from the latest sample '
        'to the 158,364-cell target (red star). Grey = downtime; ETA assumes no further evictions.'))

    # (5) throughput vs cpu-freq scatter (color = elapsed time) — throttle impact
    tp = col('throughput_M_s'); cf = col('cpu_freq_avg_mhz')
    xs = [c for c, t in zip(cf, tp) if c == c and t == t]
    ys = [t for c, t in zip(cf, tp) if c == c and t == t]
    cz = [h for h, c, t in zip(hrs, cf, tp) if c == c and t == t]
    figs2, axsc = plt.subplots(figsize=(9, 7))
    corr_txt = ''
    if xs:
        sc = axsc.scatter(xs, ys, c=cz, cmap='viridis', s=22)
        figs2.colorbar(sc, ax=axsc, label='elapsed hours')
        if len(xs) >= 3:
            ax_ = np.array(xs); ay_ = np.array(ys)
            mm, bb = np.polyfit(ax_, ay_, 1)
            xr = np.array([ax_.min(), ax_.max()])
            axsc.plot(xr, mm * xr + bb, '--', color='tab:red', lw=1.3,
                      label=f'fit {mm:.2f} (M/s)/MHz')
            r = float(np.corrcoef(ax_, ay_)[0, 1]); corr_txt = f' · r={r:.2f}'
            axsc.legend(loc='lower right', fontsize=9)
            imin = int(ax_.argmin())                        # lowest cpu-freq = the cold-start sample
            axsc.annotate('post-resume cold start', (ax_[imin], ay_[imin]),
                          textcoords='offset points', xytext=(12, -4), fontsize=8,
                          arrowprops=dict(arrowstyle='->', lw=0.7, color='0.4'))
    axsc.set_xlabel('CPU freq avg (MHz)'); axsc.set_ylabel('Throughput (M/s)'); axsc.grid(alpha=0.3)
    axsc.set_title(f'Throughput vs CPU-freq (color = time){corr_txt}', fontsize=11)
    figs2.savefig(os.path.join(outdir, 'throughput_vs_cpufreq.png'), dpi=140, bbox_inches='tight'); plt.close(figs2)
    manifest.append(('throughput_vs_cpufreq.png', 'Throughput vs CPU-freq',
        'Scatter of throughput against CPU-freq, colored by elapsed time. A positive slope quantifies how '
        'host throttling (lower MHz) depresses throughput; clusters reveal per-host/per-resume regimes.'))

    # (6) per-eviction recovery: minutes from resume until throughput returns to ≥95% of steady,
    # AND the downtime per resume — the two distinct costs of an eviction. Only once evictions exist.
    if bnds:
        steady = float(np.median(_tp)) if _tp else float('nan')
        thr = 0.95 * steady
        rec_labels, rec_recov, rec_down = [], [], []
        for s in segs:
            if s == segs[0]:
                continue                                    # r0 = initial launch, not a resume
            idxs = [i for i in range(len(rows)) if resume[i] == s]
            if not idxs:
                continue
            seg_start = secs[idxs[0]]
            recov = float('nan')
            for i in idxs:
                v = num(rows[i], 'throughput_M_s')
                if v == v and v >= thr:
                    recov = (secs[i] - seg_start) / 60.0; break
            down = (secs[idxs[0]] - secs[idxs[0] - 1]) / 60.0   # deallocate→resume gap
            rec_labels.append(f'r{s}'); rec_recov.append(recov); rec_down.append(down)
        if rec_labels:
            import numpy as _np
            x = _np.arange(len(rec_labels)); w = 0.38
            figr, axr = plt.subplots(figsize=(max(5, 1.8 * len(rec_labels) + 3), 5))
            b1 = axr.bar(x - w / 2, rec_down, w, color='tab:gray', label='downtime (deallocate→resume)')
            b2 = axr.bar(x + w / 2, [0 if v != v else v for v in rec_recov], w,
                         color='tab:orange', label='throughput recovery (→95% steady)')
            for xi, v in zip(x, rec_down):
                axr.text(xi - w / 2, v, f'{v:.0f}m', ha='center', va='bottom', fontsize=8)
            for xi, v in zip(x, rec_recov):
                axr.text(xi + w / 2, 0 if v != v else v, 'n/a' if v != v else f'{v:.0f}m',
                         ha='center', va='bottom', fontsize=8)
            axr.set_xticks(x); axr.set_xticklabels(rec_labels)
            axr.set_ylabel('minutes'); axr.set_xlabel('resume segment')
            axr.set_title(f'Per-eviction cost — downtime vs throughput-recovery '
                          f'(steady≈{steady:,.0f} M/s, 95%≈{thr:,.0f})', fontsize=11)
            axr.legend(fontsize=9); axr.grid(alpha=0.3, axis='y')
            figr.savefig(os.path.join(outdir, 'eviction_recovery.png'), dpi=140, bbox_inches='tight'); plt.close(figr)
            manifest.append(('eviction_recovery.png', 'Eviction cost',
                'Per resume: grey = deallocate→resume downtime (wall lost); orange = minutes after resume '
                'until throughput returns to ≥95% of steady (cold-cache/warmup cost). Distinguishes the two '
                'separate costs of a Spot eviction. Appears only once evictions have occurred.'))

    # index.html — loads every figure in the manifest with its description; scp the whole outdir to view.
    last = rows[-1]
    gen = datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%SZ')
    cards = "\n".join(
        f'<section><h2>{t}</h2><p>{d}</p><img src="{f}" alt="{t}"></section>'
        for f, t, d in manifest)
    html = f"""<!doctype html><html><head><meta charset="utf-8">
<title>560T re-run telemetry — {host0}</title><style>
body{{font-family:system-ui,sans-serif;max-width:1200px;margin:24px auto;padding:0 16px;color:#222}}
img{{max-width:100%;border:1px solid #ccc;border-radius:4px}}
section{{margin:28px 0}} h1{{margin-bottom:4px}} .meta{{color:#666;font-size:14px}}
code{{background:#f4f4f4;padding:1px 4px;border-radius:3px}}</style></head><body>
<h1>560T re-run telemetry</h1>
<p class="meta">host {host0} &middot; {len(rows)} samples &middot; {len(segs)} resume segment(s) &middot;
{len(bnds)} eviction(s) &middot; latest: compute_T={last.get('compute_T','?')} pct={last.get('pct_complete','?')}%
throughput={last.get('throughput_M_s','?')}M/s cpu_freq={last.get('cpu_freq_avg_mhz','?')}MHz
&middot; generated {gen}</p>
{cards}
<p class="meta">Generated by <code>visualize.py --telemetry</code>. Transient — regenerated each run; not in git.</p>
</body></html>"""
    with open(os.path.join(outdir, 'index.html'), 'w') as f:
        f.write(html)

    print("wrote %d figures + index.html to %s (%d samples, %d resume segment(s), %d eviction(s))"
          % (len(manifest), outdir, len(rows), len(segs), len(bnds)))


def main():
    args = sys.argv[1:]
    if args and args[0] == '--telemetry':
        csv_path = args[1] if len(args) > 1 else 'telemetry.csv'
        outdir = args[2] if len(args) > 2 else '.'
        plot_telemetry(csv_path, outdir)
        return
    filename = args[0] if args else 'solutions.bin'

    print("Loading solutions...")
    solutions = load_solutions(filename)

    print("Computing features (pair index at each position)...")
    features = compute_features(solutions)

    print("Finding King Wen...")
    kw_idx = find_king_wen(features)
    if kw_idx >= 0:
        print(f"  King Wen found at index {kw_idx}")
    else:
        print("  King Wen not found in solution set")

    print("Running PCA projection to 2D...")
    projected, var_explained = project_pca(features)
    print(f"  Projected {len(features):,} solutions to 2D "
          f"(PC1 {var_explained[0]*100:.1f}% / PC2 {var_explained[1]*100:.1f}% of variance)")

    generate_plots(solutions, features, projected, kw_idx, var_explained)

    print(f"\nDone. Generated 8 files (4 PNG + 4 SVG).")

if __name__ == "__main__":
    main()
