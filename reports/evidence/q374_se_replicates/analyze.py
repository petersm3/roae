#!/usr/bin/env python3
"""Q-374 SE validation: printed delta-method SE vs replicate SD across 12 seeds.

Usage: python3 analyze.py <dir-with-repNN_seedK.out>
Ratio definition (stated in the README): for each mass m in {below, at, above} of each
Davis candidate, ratio = mean over replicates of the PRINTED se / sample SD (n-1) of the
12 replicate estimates. Chi-square band: if the printed SE is correct, SD/SE ~ sqrt(chi2_11/11),
so a two-sided 95% band on SE/SD is [sqrt(11/chi2_.975,11), sqrt(11/chi2_.025,11)].
"""
import glob, math, re, statistics, sys
try:
    from scipy.stats import chi2
    _q=(chi2.ppf(0.975,11),chi2.ppf(0.025,11))
except ImportError:  # chi-square(11) 0.975/0.025 quantiles, standard table
    _q=(21.920,3.8157)

d = sys.argv[1]
files = sorted(glob.glob(d + "/rep*_seed*.out"))
rx = re.compile(r"\[dav (\d+) (\S+)\s*\] mean=(\S+) min=\S+ max=\S+ kw=\S+ below=(\S+) at=(\S+) above=(\S+) se=(\S+)/(\S+)/(\S+)")
data = {}  # name -> list of (below, at, above, se_b, se_a, se_ab)
seeds = []
leaves = []
for f in files:
    t = open(f).read()
    m = re.search(r"KNUTH-PROVENANCE seed_base=(0x[0-9a-f]+)", t)
    seeds.append(m.group(1))
    p = re.search(r"KNUTH-ESTIMATE probes=(\d+) threads=(\d+)", t)
    assert p.group(1) == "10000000" and p.group(2) == "2", (f, p.group(0))
    lc = re.search(r"leaves_canonical_C1C5 : est=(\S+)\s+95%CI=\[(\S+), (\S+)\]\s+relerr=(\S+)%", t)
    leaves.append((float(lc.group(1)), float(lc.group(4))))
    for mm in rx.finditer(t):
        data.setdefault(mm.group(2), []).append(tuple(float(x) for x in mm.groups()[3:]))
n = len(files)
assert n == 12 and len(set(seeds)) == 12, (n, seeds)
print("REPLICATES=%d SEEDS=%s" % (n, ",".join(seeds)))
assert n == 12
lo = math.sqrt((n - 1) / _q[0]); hi = math.sqrt((n - 1) / _q[1])
print("CHI2_BAND_SE_OVER_SD_95=[%.3f, %.3f] (dof=%d)" % (lo, hi, n - 1))
est = [x[0] for x in leaves]; rel = [x[1] for x in leaves]
sd = statistics.stdev(est); mean = statistics.fmean(est)
# The binary's `leaves_canonical_C1C5` field is an ORIENTED (raw) total under a misleading name
# (documentation/CORRECTIONS.md, Q-321/Q-330); its absolute value is a withdrawn figure and is NOT
# printed here -- only its relative scatter, which is all the SE check uses.
print("ESTIMATOR_TOTAL leaves_canonical_C1C5(field; oriented count) replicate_relSD=%.2f%% mean_printed_relerr=%.2f%% ratio_SE/SD=%.3f" % (100 * sd / mean, statistics.fmean(rel), statistics.fmean(rel) / (100 * sd / mean)))
print("%-13s %-6s %12s %12s %10s %8s %s" % ("candidate", "mass", "mean_est", "replicateSD", "mean_se", "SE/SD", "verdict"))
for name, rows in data.items():
    assert len(rows) == n, (name, len(rows))
    for j, lab in enumerate(("below", "at", "above")):
        vals = [r[j] for r in rows]; ses = [r[3 + j] for r in rows]
        sdv = statistics.stdev(vals); mse = statistics.fmean(ses); mv = statistics.fmean(vals)
        if sdv == 0 and mse == 0:
            print("%-13s %-6s %12.6e %12s %10s %8s %s" % (name, lab, mv, "0", "0", "n/a", "DEGENERATE (zero sampled mass in every replicate)"))
            continue
        r = mse / sdv if sdv > 0 else float("inf")
        v = "in-band" if lo <= r <= hi else "OUT-OF-BAND"
        print("%-13s %-6s %12.6e %12.3e %10.3e %8.3f %s" % (name, lab, mv, sdv, mse, r, v))
