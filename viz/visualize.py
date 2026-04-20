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
    eigenvectors = eigenvectors[:, idx[:n_components]]
    projected = centered @ eigenvectors
    return projected

def subsample_indices(n, max_points, kw_idx=-1):
    """Generate subsample indices, always including King Wen if present."""
    if n <= max_points:
        return np.arange(n)
    rng = np.random.default_rng(42)  # reproducible
    idx = rng.choice(n, size=max_points, replace=False)
    if kw_idx >= 0 and kw_idx not in idx:
        idx[0] = kw_idx  # ensure KW is included
    return np.sort(idx)

def generate_plots(solutions, features, projected, kw_idx):
    """Generate all four visualization PNGs and SVGs."""
    import matplotlib
    matplotlib.use('Agg')
    import matplotlib.pyplot as plt

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
        ax.set_xlabel('PC1', fontsize=12)
        ax.set_ylabel('PC2', fontsize=12)
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
    ax.set_xlabel('PC1', fontsize=12)
    ax.set_ylabel('PC2', fontsize=12)
    ax.set_facecolor('#f8f8f8')
    fig.tight_layout()
    fig.savefig('viz_adjacency.png', dpi=150, bbox_inches='tight')
    fig.savefig('viz_adjacency.svg', bbox_inches='tight')
    plt.close(fig)
    print("  Saved viz_adjacency.png and viz_adjacency.svg")

def main():
    filename = sys.argv[1] if len(sys.argv) > 1 else 'solutions.bin'

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
    projected = project_pca(features)
    print(f"  Projected {len(features):,} solutions to 2D")

    generate_plots(solutions, features, projected, kw_idx)

    print(f"\nDone. Generated 8 files (4 PNG + 4 SVG).")

if __name__ == "__main__":
    main()
