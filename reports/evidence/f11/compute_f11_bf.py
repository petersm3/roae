# F11 pre-registered Bayes-factor computation (frozen spec: PREREGISTRATION.md in this
# directory, FROZEN 2026-07-04).
# Inputs: archived measurement outputs in this directory (f11_runA/B/C/C2.out from the
# c222-f11 Spot worker, f11_events.json from the exact edit-event enumeration RUN D).
# Pure numerical integration over the declared prior grids — trivial CPU, no sampling here.
#
# Parsing note (2026-07-04, computation time): the delivered RUN C / RUN C2 outputs carry
# the scoreboard only — no f11_hist lines and no in-walk gender-strict prune/cross-check
# line (the planned SOLVE_KNUTH_GENDER_STRICT instrument output did not ship). N_gs is
# therefore DERIVED: N_gs = (Moore-joint canonical size) x (gender-0-violation fraction
# within the Moore-joint walk), available from two independent runs (C primary, B cross),
# which disagree by ~3.5x (rare-cell weighted-estimator noise); BOTH are carried through
# the sensitivity table. Ingredient 9 ((v1,v2,0) plane from C2) is absent; the 'aug' Z
# uses the RUN B plane + the N_gs cell only. All disclosed in RESULTS.md.
#
# Strictest-reading choices (frozen-doc ambiguity -> conservative for the favored model):
#  - conditioning denominator D extends the geometric tail k>6 with validity fraction
#    vf_6 (an upper bound, since vf_k is decreasing) -> D larger -> L_corr smaller;
#  - the numerator is truncated at k<=6 (exhaustive enumeration bound) -> L_corr smaller;
#  - primary N_gs is the LARGER of the two independent estimates (RUN C) -> L_corr smaller.
#
# Developed with AI assistance (Claude, Anthropic). Model/rule attribution: Moore 1989/2005,
# Schulz 1990 (exception: Zhu Yuansheng 13th c.), Rutt 1996 mechanism via Hacker & Moore 2003.
import json, math, os, re, sys

D = os.path.dirname(os.path.abspath(__file__))

# ---------- declared prior grids (see RESULTS.md section 0) ----------
PC_GRID = [0.05, 0.1, 0.2, 0.3, 0.5, 0.7, 0.9]          # geometric(p_c), k >= 0, uniform prior
LAM_GRID = [0.1, 0.2, 0.5, 1.0, 2.0, 5.0, 10.0]         # Gibbs strength, uniform prior
V_KW = 6                                                  # 2+2+2, asserted in f11_events.py
KMAX = 6                                                  # exhaustive event-enumeration bound

def geom(k, p): return (1.0 - p) ** k * p                 # P(k) for k = 0,1,2,...

# ---------- parse estimator outputs ----------
def parse_run(path):
    probes = None; est = {}; hist = {}; gender0 = None; gender_le2 = None
    moore_strict_walk = False
    for ln in open(path):
        m = re.match(r"KNUTH-ESTIMATE probes=(\d+)", ln)
        if m: probes = int(m.group(1))
        m = re.match(r"\s+leaves_canonical_C1C5 : est=([0-9.e+-]+)\s+95%CI=\[([0-9.e+-]+), ([0-9.e+-]+)\]", ln)
        if m: est["canonical"], est["lo"], est["hi"] = (float(m.group(i)) for i in (1, 2, 3))
        m = re.match(r"f11_hist (\d+) (\d+) (\d+) ([0-9.e+-]+)", ln)
        if m: hist[(int(m.group(1)), int(m.group(2)), int(m.group(3)))] = float(m.group(4))
        m = re.search(r"R-C4 gender/valence <=2 viol : ([0-9.]+) \| 0 viol: ([0-9.]+)", ln)
        if m: gender_le2, gender0 = float(m.group(1)), float(m.group(2))
        if re.search(r"R-M1 Moore-parity strict : 1\.000000", ln): moore_strict_walk = True
    return dict(probes=probes, est=est, hist=hist, gender0=gender0,
                gender_le2=gender_le2, moore_strict_walk=moore_strict_walk)

A  = parse_run(os.path.join(D, "f11_runA.out"))
B  = parse_run(os.path.join(D, "f11_runB.out"))
C  = parse_run(os.path.join(D, "f11_runC.out"))
C2 = parse_run(os.path.join(D, "f11_runC2.out"))
events = json.load(open(os.path.join(D, "f11_events.json")))

# ---------- sanity gates (fail loudly) ----------
assert A["probes"] == 20_000_000_000, "RUN A probe count != declared 2e10"
assert B["probes"] == 5_000_000_000,  "RUN B probe count != declared 5e9"
assert C["probes"] == 5_000_000_000,  "RUN C probe count != declared 5e9"
assert C2["probes"] == 2_000_000_000, "RUN C2 probe count != declared 2e9"
assert abs(sum(A["hist"].values()) - 1.0) < 1e-3, "RUN A histogram does not sum to 1"
assert abs(sum(B["hist"].values()) - 1.0) < 1e-3, "RUN B histogram does not sum to 1"
assert all(k[0] == 0 and k[1] == 0 for k in B["hist"]), "RUN B produced non-Moore-strict cells"
assert not any(k[0] == 0 and k[1] == 0 for k in A["hist"]), \
    "RUN A saw the Moore-strict plane (double-count risk in 'aug')"
assert B["moore_strict_walk"] and C["moore_strict_walk"], "RUN B/C are not Moore-joint-strict walks"
assert not A["moore_strict_walk"] and not C2["moore_strict_walk"], "RUN A/C2 unexpectedly pruned"
assert (2, 2, 2) in A["hist"], "KW's own (2,2,2) cell unobserved in RUN A"
# events: exact-enumeration invariants (event space is base-independent; minimal repair = 3)
for k in range(1, KMAX + 1):
    assert events["KW"][str(k)]["events"] == events["GRAND"][str(k)]["events"]
assert len(events["KW"]["1"]["hits"]) == 0 and len(events["KW"]["2"]["hits"]) == 0, \
    "k<=2 KW-repair event found — contradicts SAT minimal repair = 3"
assert len(events["KW"]["3"]["hits"]) == 2, "k=3 KW-repair event count changed"

N_CAN = A["est"]["canonical"]            # |C1-C5| canonical  (1.328702e38, relerr 0.03%)
N_MJ  = B["est"]["canonical"]            # Moore-joint strict (1.16583e29, relerr 2.98%)
# cross-checks against prior anchors
assert abs(N_CAN / 1.3287e38 - 1) < 0.003, "RUN A canonical drifted off the c208/c211 anchor"
assert abs(C2["est"]["canonical"] / N_CAN - 1) < 0.01, "RUN C2 canonical inconsistent with RUN A"
assert abs(N_MJ / 1.1266e29 - 1) < 0.047 and abs(C["est"]["canonical"] / 1.1266e29 - 1) < 0.047, \
    "Moore-joint size outside the +/-4.7% anchor band"

# grand-strict (triple-strict) size: DERIVED (see header note); two independent estimates
N_GS_C = C["est"]["canonical"] * C["gender0"]      # primary (larger => conservative)
N_GS_B = N_MJ * B["hist"][(0, 0, 0)]               # cross (RUN B (0,0,0) cell)
assert N_GS_C >= N_GS_B, "primary N_gs is no longer the conservative (larger) estimate"
N_GO = C2["est"]["canonical"] * C2["gender0"]      # gender-strict-only (info; 1 s.f. scoreboard)

# ---------- M_tend: Z(lambda) = sum_cells mass(cell) * exp(-lambda*V) ----------
def z_cells(variant, n_gs):
    """cell -> absolute count (units of orderings)."""
    cells = {c: f * N_CAN for c, f in A["hist"].items()}
    if variant in ("aug", "bridge"):
        for c, f in B["hist"].items():               # (0,0,v3) plane, v3 = 0..24 complete
            cells[c] = f * N_MJ
        cells[(0, 0, 0)] = n_gs
        # ingredient 9 ((v1,v2,0) plane from RUN C2) was not delivered — disclosed
    return cells

def mass_by_V(cells):
    m = {}
    for (v1, v2, v3), n in cells.items():
        m[v1 + v2 + v3] = m.get(v1 + v2 + v3, 0.0) + n
    return m

def bridged(mV):
    """Upper-Z sensitivity: log-linear bridge across unobserved interior total-V levels."""
    m = dict(mV); ks = sorted(m); filled = 0
    for a, b in zip(ks, ks[1:]):
        if b - a > 1 and m[a] > 0 and m[b] > 0:
            la, lb = math.log(m[a]), math.log(m[b])
            for v in range(a + 1, b):
                m[v] = math.exp(la + (lb - la) * (v - a) / (b - a)); filled += 1
    return m, filled

def Z(lam, mV): return sum(n * math.exp(-lam * v) for v, n in mV.items())

def L_tend(lam, mV):
    """P(exact received sequence | M_tend, lambda) = e^{-lam*V_KW} / Z(lam)."""
    return math.exp(-lam * V_KW) / Z(lam, mV)

def tend_table(zvar, n_gs):
    mV = mass_by_V(z_cells(zvar, n_gs))
    filled = 0
    if zvar == "bridge":
        mV, filled = bridged(mV)
    return {lam: L_tend(lam, mV) for lam in LAM_GRID}, filled

# ---------- M_corr: exact edit-event geometry ----------
def w_num(k, variant):
    r = events["KW"][str(k)]
    return (r["zA_hits"] / r["zA"]) if variant == "A" else (len(r["hits"]) / r["events"])

def vf(k, variant):
    r = events["GRAND"][str(k)]
    return (r["zA_valid"] / r["zA"]) if variant == "A" else (r["valid"] / r["events"])

def L_corr(p, variant, conditioned, n_gs):
    """P(exact received sequence | M_corr, p_c) = [sum_k P(k) sum_{E:|E|=k,E(KW) in GS}
    P(E|k,variant)] / (N_gs * D). Events are involutions (each KW-hit event <-> exactly one
    grand-strict precursor). D = P(C1-C5-valid outcome | model), witness-based proxy;
    geometric tail k>KMAX bounded above by vf(KMAX) (strictest reading)."""
    num = sum(geom(k, p) * w_num(k, variant) for k in range(1, KMAX + 1))
    den = 1.0
    if conditioned:
        den = geom(0, p) + sum(geom(k, p) * vf(k, variant) for k in range(1, KMAX + 1))
        den += (1.0 - p) ** (KMAX + 1) * vf(KMAX, variant)   # tail: sum_{k>KMAX} geom = (1-p)^(KMAX+1)
    return num / (n_gs * den)

# ---------- v1.12 re-measurement path (OPT-IN: `--ngs-measured`) ----------
# The frozen record above DERIVES N_gs (header note). It was later measured DIRECTLY in the
# r11 bundle (../r11/, four independent equal-probe seeds, 2026-07-13), and TR-2 v1.12
# restated the headline under that value. Before this flag existed the v1.12 figures had
# methods prose but no single-command reproduction, while this script's own README promised
# one; the flag closes that gap. It changes NOTHING on the default path: the frozen
# 2026-07-04 output is byte-identical with the flag absent, and these files are not even
# opened. Same integration, same grids, same strictest-reading choices — only n_gs moves.
R11_SEEDS = ("seed1_1001.out", "seed2_2003.out", "seed3_3011.out", "seed4_4013.out")
R11_NGS_RE = re.compile(r"R-C4 0-viol DERIVED-N_gs abs\s*:\s*est=([0-9.eE+-]+)")

def ngs_measured():
    """Pooled N_gs from ../r11/: unweighted mean of the four equal-probe seeds."""
    vals = []
    for fn in R11_SEEDS:
        with open(os.path.join(D, "..", "r11", fn)) as fh:
            m = R11_NGS_RE.search(fh.read())
        assert m, "no 'R-C4 0-viol DERIVED-N_gs abs' scoreboard line in ../r11/%s" % fn
        vals.append(float(m.group(1)))
    assert len(vals) == len(R11_SEEDS), "seed count changed"
    pooled = sum(vals) / len(vals)
    assert pooled > N_GS_C, "measured N_gs no longer exceeds the derived primary — check ../r11/"
    return pooled, vals

# ---------- marginal likelihoods + BF ----------
def report(sources=None):
    rows = []
    for gs_src, n_gs in (sources or (("C", N_GS_C), ("B", N_GS_B))):
        for zvar in ("hist", "aug", "bridge"):
            lt, filled = tend_table(zvar, n_gs)
            ml_tend = sum(lt.values()) / len(lt)
            for variant in ("U", "A"):
                for cond in (True, False):
                    lc = {p: L_corr(p, variant, cond, n_gs) for p in PC_GRID}
                    ml_corr = sum(lc.values()) / len(lc)
                    rows.append(dict(gs=gs_src, z=zvar, var=variant, cond=cond,
                                     mlc=ml_corr, mlt=ml_tend, bf=ml_corr / ml_tend,
                                     lc=lc, lt=lt, filled=filled))
    return rows

if __name__ == "__main__":
    print("N_can=%.6e  N_mooreJoint=%.6e  N_gs(C,primary)=%.4e  N_gs(B,cross)=%.4e  N_genderOnly~%.2e"
          % (N_CAN, N_MJ, N_GS_C, N_GS_B, N_GO))
    print("RUN A cells=%d sum=%.6f minV=%d; KW cell (2,2,2) frac=%.4e (~%.3e orderings)"
          % (len(A["hist"]), sum(A["hist"].values()),
             min(sum(c) for c in A["hist"]), A["hist"][(2, 2, 2)],
             A["hist"][(2, 2, 2)] * N_CAN))
    # numerator contribution by k (truncation-error visibility), variant U, mid-grid p=0.3
    for p in (0.05, 0.3):
        cs = [geom(k, p) * w_num(k, "U") for k in range(1, KMAX + 1)]
        print("num-by-k (U, p_c=%.2f):" % p,
              " ".join("k%d=%.3e" % (k + 1, c) for k, c in enumerate(cs)),
              " k6-share=%.2f%%" % (100 * cs[-1] / sum(cs)))
    hdr = "%-3s %-7s %-4s %-5s  %-11s %-11s %-11s %s"
    print(hdr % ("gs", "Z", "loc", "cond", "L(corr)", "L(tend)", "BF", "log10BF"))
    for r in report():
        print(hdr % (r["gs"], r["z"], r["var"], r["cond"],
                     "%.4e" % r["mlc"], "%.4e" % r["mlt"],
                     "%.4g" % r["bf"], "%.2f" % math.log10(r["bf"])))
        if r["gs"] == "C" and r["z"] == "aug" and r["cond"]:
            print("   per-gridpoint L_corr:", {p: "%.3e" % v for p, v in r["lc"].items()})
            print("   per-gridpoint L_tend:", {l: "%.3e" % v for l, v in r["lt"].items()})
    # 7x7 BF(p_c, lambda) matrix for the primary configuration (gs=C, Z=aug, U, conditioned)
    lt, _ = tend_table("aug", N_GS_C)
    print("\nBF(p_c, lambda) matrix — primary config (gs=C, Z=aug, variant U, conditioned):")
    print("p_c\\lam  " + "  ".join("%8g" % l for l in LAM_GRID))
    for p in PC_GRID:
        lc = L_corr(p, "U", True, N_GS_C)
        print("%7g  " % p + "  ".join("%8.2g" % (lc / lt[l]) for l in LAM_GRID))

    # OPT-IN v1.12 path. Absent this flag nothing above or below changes.
    if "--ngs-measured" in sys.argv[1:]:
        n_gs_m, seed_vals = ngs_measured()
        print("\n== v1.12 re-measurement path (--ngs-measured) ==")
        print("N_gs(measured, ../r11/ pooled over %d seeds)=%.4e   seeds: %s"
              % (len(seed_vals), n_gs_m, " ".join("%.6e" % v for v in seed_vals)))
        print("rescale vs derived primary: N_gs(C)/N_gs(measured) = %.4f" % (N_GS_C / n_gs_m))
        print(hdr % ("gs", "Z", "loc", "cond", "L(corr)", "L(tend)", "BF", "log10BF"))
        for r in report(sources=(("M", n_gs_m),)):
            print(hdr % (r["gs"], r["z"], r["var"], r["cond"],
                         "%.4e" % r["mlc"], "%.4e" % r["mlt"],
                         "%.4g" % r["bf"], "%.2f" % math.log10(r["bf"])))
