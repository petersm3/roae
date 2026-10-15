#!/usr/bin/env python3
"""PREREG_C8SCREEN_2026_10_11 §4-§5 / §7.4-§7.5: mechanical verdicts from the recorded Pilot A outputs.

DRAFT (2026-10-11, scorer lane P2b; AMENDMENT 1 applied 2026-10-11, Fable lane) -- the measurement lane
copies this file into its RECORDED directory as analyze.py. No threshold, null or rule here is chosen by
this script: each is transcribed from the frozen file and from PREREG_C8SCREEN_AMENDMENT_1_2026_10_11.md
(§9-A1..A4) and cited by section. Amendment 1: A1 the four P-CM ranges are (0, 496) and MEMBER_LIST_SHA256
is 529fb27a...; C8_CLAMPED_TOTAL keeps the literal reading (all five runs). A2 a control value may be NA
(a positional member whose set lacks its C1-forced cardinality on that non-C1 ordering); an NA control
never defeats §5.4(c). A3 c8_hcnt lines carry n_A/n_B; C8_UNDEFINED must be 0 (else VOID, a §7.2-class
failure). A4 INDEPENDENT_OF_C2_C5 requires p_op < bar as well (QOY precedent I2).

Inputs (one directory, default: this script's directory):
  N1_A.out N1_B.out      ./solve --estimate-knuth 1e10 (SOLVE_KNUTH_SCORE=1 SOLVE_KNUTH_SCORE_C8=1), §6 seeds
  N1P_A.out N1P_B.out    the same under SOLVE_KNUTH_C67=1, 5e9 each (annotation only, §4.3)
  N0.out                 ./solve --c8-null0 1e7 (§4.1)
  kw.out                 python3 solve.py --c8-kw --c8-pin '<§9 pin>'   (c8_kw <id> <value> lines)
  controls.out           python3 solve.py --c8-controls: c8_ctrl <JINGFANG|MAWANGDUI|FUXI> <id> <value|NA>
                         and C8_CONTROLS_NA_MAP=PASS (§4.4 under amendment 1 A2)
  gates.txt              the §7.2 KEY=value gate tokens
  members.tsv            ./solve --c8-list members  (id TAB stratum TAB lo TAB hi)
Prints KEY=value tokens (TOKENS.txt is stdout), writes SUMMARY.tsv beside the inputs, prints FAMILY= LAST.

Self-test (synthetic, never King Wen):  python3 c8screen_analyze.py --selftest
"""
import math, os, re, sys

ALPHA, ALPHA_C, ALPHA_S = 0.01, 0.005, 0.005                     # §5.2
K, K_C, K_S = 1349, 1300, 49
BAR = {"C": ALPHA_C / K_C, "S": ALPHA_S / K_S}                    # 3.846154e-06, 1.020408e-04
REF_N1, BAND_N1_HALF, BAND_N1_POOL = 1.3287e38, 0.005, 0.002     # §4.2
REF_N1P, BAND_N1P = 5.21e31, 0.01                                 # §4.3
N1_PROBES, N0_DRAWS = 20000000000, 10000000                       # §4.2, §4.1
UNINF_CAP = 67                                                     # §5.4: 5 % of 1,349
C67_BAR = 0.05                                                     # §5.4 survivor annotation
CONTROLS = ("JINGFANG", "MAWANGDUI", "FUXI")
# Amendment 1 A1: "C8_CLAMPED_TOTAL" keeps its literal reading, the sum over all five runs (N1, N1', N0);
# after A1 every declared range is a universal bound, so any clamp anywhere is an instrument bug.
CLAMP_RUNS = ("N1_A", "N1_B", "N1P_A", "N1P_B", "N0")
MEMBER_LIST_SHA256 = "529fb27a96ec9ebc422b64ef0f5d091319a85e859bb65fbc93f6f61aef6ff34a"   # amendment 1 A1 (frozen: 486cac40...)
SUBGROUP_LIST_SHA256 = "44e8a16bd08c4caf0edd1619ca598b891e5515836ca6feb67ae59fd605d40d52"
tok = []
def out(k, v): tok.append("%s=%s" % (k, v))


def kv(path):
    d = {}
    for ln in open(path, encoding="utf-8", errors="replace"):
        m = re.match(r"^([A-Z0-9_]+)=(.*)$", ln.rstrip("\n"))
        if m: d[m.group(1)] = m.group(2)
    return d


def parse_run(path):
    """One estimator or N0 output: raw sums, counters, per-member histograms and leaf counts."""
    r = {"hist": {}, "cnt": {}}
    txt = open(path, encoding="utf-8", errors="replace").read()
    g = lambda k: re.search(r"^%s=(\S+)$" % k, txt, re.M)
    for k in ("C8_RAW_SC", "C8_RAW_QC"): r[k] = float(g(k).group(1))
    for k in ("C8_MEMBERS", "C8_RAW_N", "C8_LEAVES_SCORED", "C8_CLAMPED", "C8_UNDEFINED"): r[k] = int(g(k).group(1))
    m = g("C8_NULL0_DRAWS"); r["null0"] = m is not None
    if r["null0"]:
        r["notc1"] = int(g("C8_NULL0_NOT_C1").group(1)); r["seed"] = g("C8_NULL0_SEED").group(1)
        r["probes_ok"] = True; r["c67"] = False; r["est"] = r["se_printed"] = None
    else:
        r["probes_ok"] = bool(re.search(r"^KNUTH_PROBES=EXECUTED-EQ-PLANNED$", txt, re.M))
        e = re.search(r"leaves_canonical_C1C5 : est=(\S+)\s+95%CI=\[(\S+), (\S+)\]", txt)
        r["est"] = float(e.group(1)); r["se_printed"] = (float(e.group(3)) - float(e.group(2))) / 3.92
        r["seed"] = re.search(r"seed_base=(\S+)", txt).group(1)
        r["c67"] = "C6/C7 pins ACTIVE" in txt
    for m in re.finditer(r"^c8_hist (\S+) (-?\d+) (\S+) (\S+)$", txt, re.M):
        r["hist"].setdefault(m.group(1), {})[int(m.group(2))] = (float(m.group(3)), float(m.group(4)))
    for m in re.finditer(r"^c8_hcnt (\S+) (-?\d+) (\d+)$", txt, re.M):
        r["cnt"].setdefault(m.group(1), {})[int(m.group(2))] = int(m.group(3))
    return r


def pool(runs):
    p = {"sC": sum(r["C8_RAW_SC"] for r in runs), "qC": sum(r["C8_RAW_QC"] for r in runs),
         "N": sum(r["C8_RAW_N"] for r in runs), "L": sum(r["C8_LEAVES_SCORED"] for r in runs), "hist": {}, "cnt": {}}
    for r in runs:
        for s, h in r["hist"].items():
            for b, (a, q) in h.items():
                x = p["hist"].setdefault(s, {}).get(b, (0.0, 0.0)); p["hist"][s][b] = (x[0] + a, x[1] + q)
        for s, h in r["cnt"].items():
            for b, c in h.items():
                p["cnt"].setdefault(s, {})[b] = p["cnt"].get(s, {}).get(b, 0) + c
    n = p["N"]; mean = p["sC"] / n
    p["est"] = mean
    p["se"] = math.sqrt(max(0.0, (p["qC"] - n * mean * mean) / (n - 1)) / n) if n > 1 else float("inf")   # knuth_emit_ci
    return p


def mass_se(sqi, m, B, Qb):                                       # solve.c KNUTH_MASS_SE (Q-374)
    return math.sqrt(max(0.0, sqi * (1 - 2 * m) + m * m * Qb)) / B if B > 0 else 0.0


def tail(p, s, v, side, binomial=False):
    """(mass, SE, operative, leaves) of the tail S<=v (le) or S>=v (ge). §5.1: operative = mass + 3 SE;
    an exactly-empty tail takes 3/L. N0 (binomial=True): sampled mass, binomial SE (§4.1/§5.1)."""
    h = p["hist"].get(s, {}); c = p["cnt"].get(s, {})
    keep = lambda b: b <= v if side == "le" else b >= v
    a = sum(x[0] for b, x in h.items() if keep(b)); q = sum(x[1] for b, x in h.items() if keep(b))
    n = sum(x for b, x in c.items() if keep(b))
    m = a / p["sC"]
    se = math.sqrt(m * (1 - m) / p["N"]) if binomial else mass_se(q, m, p["sC"], p["qC"])
    op = min(1.0, m + 3 * se) if a > 0 else 3.0 / p["L"]
    return m, se, op, n


def ptwo(p, s, v, binomial=False):
    le, ge = tail(p, s, v, "le", binomial), tail(p, s, v, "ge", binomial)
    side = "le" if le[2] <= ge[2] else "ge"
    return le, ge, min(1.0, 2 * min(le[2], ge[2])), side


def min_attainable(p, s, binomial=False):
    sup = [b for b, (a, _) in p["hist"].get(s, {}).items() if a > 0]
    return min(ptwo(p, s, v, binomial)[2] for v in sup) if sup else 1.0


def analyze(D):
    need = ["N1_A.out", "N1_B.out", "N1P_A.out", "N1P_B.out", "N0.out", "kw.out", "controls.out", "gates.txt", "members.tsv"]
    miss = [f for f in need if not os.path.exists(os.path.join(D, f))]
    if miss:
        print("ANALYZE_INPUT=MISSING:" + ",".join(miss)); return 2
    members = [ln.rstrip("\n").split("\t") for ln in open(os.path.join(D, "members.tsv")) if ln.strip()]
    ids = [m[0] for m in members]; strat = {m[0]: m[1] for m in members}
    g = kv(os.path.join(D, "gates.txt"))
    runs = {k: parse_run(os.path.join(D, k + ".out")) for k in ("N1_A", "N1_B", "N1P_A", "N1P_B", "N0")}
    kw = {}
    for ln in open(os.path.join(D, "kw.out")):
        m = re.match(r"^c8_kw (\S+) (-?\d+)$", ln.strip())
        if m: kw[m.group(1)] = int(m.group(2))
    kwpin = kv(os.path.join(D, "kw.out")).get("C8_KW_PIN", "MISSING")
    ctl = {c: {} for c in CONTROLS}                                  # amendment 1 A2: a value or "NA"
    for ln in open(os.path.join(D, "controls.out")):
        m = re.match(r"^c8_ctrl (\S+) (\S+) (-?\d+|NA)$", ln.strip())
        if m and m.group(1) in ctl: ctl[m.group(1)][m.group(2)] = "NA" if m.group(3) == "NA" else int(m.group(3))
    ctl_gate = kv(os.path.join(D, "controls.out"))

    # ---- family-level structure and VOID conditions (§5.4 first row) ----
    struct_ok = (len(ids) == K and sum(strat[i] == "C" for i in ids) == K_C and sum(strat[i] == "S" for i in ids) == K_S
                 and set(kw) == set(ids) and all(set(c) == set(ids) for c in ctl.values())
                 and all(r["C8_MEMBERS"] == K for r in runs.values()))
    for k in ("PREREG_SHA_VERIFIED", "DEFCHECK_SHA_VERIFIED", "DEFCHECK", "AMENDMENT_SHA_VERIFIED", "DEFCHECK_A1_SHA_VERIFIED",
              "FAMILY_K", "MEMBER_LIST_SHA256", "SUBGROUP_LIST_SHA256",
              "C8_VERIFY", "C8_VERIFY_MUTANT", "BINARY_FRESH", "SELFTEST", "INSTRUMENT_PIN", "VERIFY_PY_SHA256", "SOLVE_C_SHA256",
              "SOLVE_PY_SHA256", "TESTS_PY_SHA256", "SOLVE_BIN_SHA256", "PUBLIC_HEAD", "PRIVATE_HEAD", "SOLVE_THREADS", "BUILD"):
        out(k, g.get(k, "MISSING"))
    gates_ok = (g.get("PREREG_SHA_VERIFIED") == "PASS" and g.get("DEFCHECK_SHA_VERIFIED") == "PASS" and g.get("DEFCHECK") == "PASS"
                and g.get("AMENDMENT_SHA_VERIFIED") == "PASS" and g.get("DEFCHECK_A1_SHA_VERIFIED") == "PASS"   # amendment 1 §7.2 additions
                and g.get("FAMILY_K") == "1349"
                and g.get("MEMBER_LIST_SHA256", "") == MEMBER_LIST_SHA256 and g.get("SUBGROUP_LIST_SHA256", "") == SUBGROUP_LIST_SHA256
                and ctl_gate.get("C8_CONTROLS_NA_MAP") == "PASS"   # amendment 1 A2: the producer's NA pattern equals the pre-declared one
                and g.get("C8_VERIFY") == "PASS" and g.get("C8_VERIFY_MUTANT") == "FAIL"
                and g.get("BINARY_FRESH") in ("FRESH", "YES") and g.get("SELFTEST") == "PASS"
                and g.get("INSTRUMENT_PIN", "MISSING") not in ("", "MISSING") and kwpin == g.get("INSTRUMENT_PIN"))
    runs_ok = (all(r["probes_ok"] for r in runs.values()) and not runs["N1_A"]["c67"] and not runs["N1_B"]["c67"]
               and runs["N1P_A"]["c67"] and runs["N1P_B"]["c67"] and runs["N0"]["null0"] and runs["N0"]["notc1"] == 0
               and runs["N1_A"]["C8_RAW_N"] + runs["N1_B"]["C8_RAW_N"] == N1_PROBES and runs["N0"]["C8_RAW_N"] == N0_DRAWS
               and all(r["C8_UNDEFINED"] == 0 for r in runs.values()))
    clamped = sum(runs[k]["C8_CLAMPED"] for k in CLAMP_RUNS)
    out("C8_CLAMPED_RULE", "TOTAL_OVER_" + "+".join(CLAMP_RUNS))
    for k in CLAMP_RUNS: out("C8_CLAMPED_" + k, runs[k]["C8_CLAMPED"])
    out("C8_CLAMPED_TOTAL", clamped)
    out("STRUCTURE", "PASS" if struct_ok else "FAIL"); out("RUN_INTEGRITY", "PASS" if runs_ok else "FAIL")
    out("PRE_RUN_GATES_ALL", "PASS" if gates_ok else "FAIL")

    P, A, B = pool([runs["N1_A"], runs["N1_B"]]), pool([runs["N1_A"]]), pool([runs["N1_B"]])
    P1, A1, B1 = pool([runs["N1P_A"], runs["N1P_B"]]), pool([runs["N1P_A"]]), pool([runs["N1P_B"]])
    N0 = pool([runs["N0"]])

    def selfval(X, ref, band, se):
        return abs(X["est"] - ref) <= max(3 * se, band * ref)
    sv = {"A": selfval(A, REF_N1, BAND_N1_HALF, runs["N1_A"]["se_printed"]),
          "B": selfval(B, REF_N1, BAND_N1_HALF, runs["N1_B"]["se_printed"]),
          "POOLED": selfval(P, REF_N1, BAND_N1_POOL, P["se"])}
    sv1 = {"A": selfval(A1, REF_N1P, BAND_N1P, runs["N1P_A"]["se_printed"]),
           "B": selfval(B1, REF_N1P, BAND_N1P, runs["N1P_B"]["se_printed"]),
           "POOLED": selfval(P1, REF_N1P, BAND_N1P, P1["se"])}
    out("N1_SELFVALIDATION", "%s (A est=%.6e se=%.3e; B est=%.6e se=%.3e; pooled est=%.6e se=%.3e; ref %.4e)" % (
        "PASS" if all(sv.values()) else "FAIL", A["est"], runs["N1_A"]["se_printed"], B["est"], runs["N1_B"]["se_printed"], P["est"], P["se"], REF_N1))
    out("N1C67_SELFVALIDATION", "%s (A est=%.6e; B est=%.6e; pooled est=%.6e se=%.3e; ref %.4e)" % (
        "PASS" if all(sv1.values()) else "FAIL", A1["est"], B1["est"], P1["est"], P1["se"], REF_N1P))
    void = not (struct_ok and runs_ok and gates_ok and all(sv.values()) and clamped == 0)

    out("FAMILY_K", K); out("FAMILY_K_C", K_C); out("FAMILY_K_S", K_S); out("FAMILY_ALPHA", ALPHA)
    out("BAR_C", "%.6e" % BAR["C"]); out("BAR_S", "%.6e" % BAR["S"])
    out("N1_PROBES", runs["N1_A"]["C8_RAW_N"] + runs["N1_B"]["C8_RAW_N"])
    out("N1_SEEDS", "%s,%s" % (runs["N1_A"]["seed"], runs["N1_B"]["seed"])); out("N1C67_SEEDS", "%s,%s" % (runs["N1P_A"]["seed"], runs["N1P_B"]["seed"]))
    out("N0_DRAWS", runs["N0"]["C8_RAW_N"]); out("N0_SEED", runs["N0"]["seed"])
    out("N1_LEAVES_SCORED", P["L"]); out("N1C67_LEAVES_SCORED", P1["L"])
    # §5.3 as amended (amendment 1 A4): INDEPENDENT_OF_C2_C5 requires p_op < bar AND p_op,N0 < bar in the same
    # tail; C2_C5_CONDITIONAL: p_op < bar, p_op,N0 >= bar; EXPLAINED_BY_C2_C5: p_op >= bar, p_op,N0 < bar; NA
    # otherwise (both >= bar, or both < bar in opposite tails). Mutually exclusive and exhaustive.
    out("INDEPENDENCE_RULE", "AMENDMENT_1_A4")
    for c in CONTROLS: out("CONTROL_NA_" + c, sum(1 for v in ctl[c].values() if v == "NA"))

    rows, counts, smallest, survivors = [], {"SURVIVOR": 0, "NULL": 0, "UNINFORMATIVE": 0, "FORCED": 0}, None, []
    for mid in ids:
        beta = BAR[strat[mid]]; s = kw[mid]
        h = P["hist"].get(mid, {}); sup = sorted(b for b, (a, _) in h.items() if a > 0)
        le, ge, two, side = ptwo(P, mid, s)
        la, ga, twoA, _ = ptwo(A, mid, s); lb, gb, twoB, _ = ptwo(B, mid, s)
        nA = tail(A, mid, s, side)[3]; nB = tail(B, mid, s, side)[3]
        # half-wise operative p: the same two-sided rule within each half (§5.4 p_op,A / p_op,B)
        minatt = min_attainable(P, mid)
        n0le, n0ge, n0two, n0side = ptwo(N0, mid, s, binomial=True)
        n0minatt = min_attainable(N0, mid, binomial=True)
        c67two = ptwo(P1, mid, s)[2]
        cp = {c: (tail(P, mid, ctl[c][mid], side)[2] if ctl[c][mid] != "NA" else "NA") for c in CONTROLS}   # A2: NA never defeats
        nonspec = any(x != "NA" and x <= beta for x in cp.values())
        if not sup: verdict, reason = "FORCED", "EMPTY_SUPPORT"
        elif sup[0] == sup[-1]: verdict, reason = "FORCED", "-"
        elif minatt >= beta: verdict, reason = "UNINFORMATIVE", "ATTAIN"
        elif two < beta and (twoA >= 10 * beta or twoB >= 10 * beta): verdict, reason = "UNINFORMATIVE", "REPLICATION"
        elif two < beta and (nA < 10 or nB < 10): verdict, reason = "UNINFORMATIVE", "LEAVES"
        elif two < beta and nonspec: verdict, reason = "UNINFORMATIVE", "SPECIFICITY"
        elif two < beta: verdict, reason = "SURVIVOR", "-"
        else: verdict, reason = "NULL", "-"
        if two < beta and n0two < beta and n0side == side: ind = "INDEPENDENT_OF_C2_C5"
        elif two < beta and n0two >= beta: ind = "C2_C5_CONDITIONAL"
        elif n0two < beta and two >= beta: ind = "EXPLAINED_BY_C2_C5"
        else: ind = "NA"
        counts[verdict] += 1
        if verdict == "SURVIVOR": survivors.append(mid)
        if smallest is None or two < smallest[1]: smallest = (mid, two)
        E = sum(b * a for b, (a, _) in h.items()) / P["sC"]
        for tag, X in (("A", A), ("B", B), ("POOLED", P)):
            hh = X["hist"].get(mid, {})
            out(mid + "_N1_HIST_" + tag, ",".join("%d:%.6e" % (b, hh[b][0] / X["sC"]) for b in sorted(hh)))
        out(mid + "_KW", s); out(mid + "_N1_E", "%.6f" % E)
        out(mid + "_N1_MIN_MAX", "%s,%s" % (sup[0], sup[-1]) if sup else "NA")
        out(mid + "_N1_P_LE", "%.6e" % le[0]); out(mid + "_N1_P_GE", "%.6e" % ge[0])
        out(mid + "_N1_SE_LE", "%.3e" % le[1]); out(mid + "_N1_SE_GE", "%.3e" % ge[1])
        out(mid + "_N1_P_TWO_OPERATIVE", "%.6e" % two)
        out(mid + "_N1_P_TWO_OPERATIVE_A", "%.6e" % twoA); out(mid + "_N1_P_TWO_OPERATIVE_B", "%.6e" % twoB)
        out(mid + "_N1_TAIL_LEAVES_A", nA); out(mid + "_N1_TAIL_LEAVES_B", nB)
        out(mid + "_N1_SMALLER_TAIL", side.upper()); out(mid + "_N1_MIN_ATTAINABLE_P", "%.6e" % minatt)
        out(mid + "_N0_P_TWO", "%.6e" % n0two); out(mid + "_N0_MIN_ATTAINABLE_P", "%.6e" % n0minatt)
        out(mid + "_N1C67_P_TWO_OPERATIVE", "%.6e" % c67two)
        for c in CONTROLS:
            out("%s_CONTROL_%s" % (mid, c), ("value=NA same_tail(%s)_operative_p=NA" % side.upper()) if cp[c] == "NA"
                else "value=%d same_tail(%s)_operative_p=%.6e" % (ctl[c][mid], side.upper(), cp[c]))
        out(mid + "_INDEPENDENCE", ind)
        out(mid + "_VERDICT", verdict + ("" if reason == "-" else " " + reason))
        if verdict == "SURVIVOR":
            out(mid + "_C67_ANNOTATION", "C67_CONSISTENT" if c67two < C67_BAR else "C67_ABSORBS")
        rows.append((mid, strat[mid], s, "%.6e" % two, side.upper(), "%.6e" % twoA, "%.6e" % twoB, nA, nB,
                     "%.6e" % minatt, "%.6e" % n0two, "%.6e" % c67two, ind, verdict, reason))
    with open(os.path.join(D, "SUMMARY.tsv"), "w") as fh:
        fh.write("member\tstratum\tkw\tp_two_op\tsmaller_tail\tp_op_A\tp_op_B\tleaves_A\tleaves_B\tmin_attainable\tn0_p_two\tn1c67_p_two\tindependence\tverdict\treason\n")
        for r in rows: fh.write("\t".join(map(str, r)) + "\n")
    for k in ("SURVIVOR", "NULL", "UNINFORMATIVE", "FORCED"): out("COUNT_" + k, counts[k])
    out("SURVIVORS", ",".join(survivors) if survivors else "NONE")
    out("SMALLEST_P_OP", "%s,%.6e" % smallest)
    if void: fam = "VOID"
    elif survivors: fam = "SURVIVOR"
    elif counts["UNINFORMATIVE"] + counts["FORCED"] <= UNINF_CAP: fam = "NULL"
    else: fam = "UNINFORMATIVE"
    out("FAMILY", fam)                                            # §7.5: printed LAST
    print("\n".join(tok))
    return 0


def selftest():
    """Synthetic fixture (never King Wen): builds a toy output set for 1349 dummy members with known
    tails and checks the verdict rows. Prints C8_ANALYZE_SELFTEST=PASS|FAIL."""
    import tempfile, shutil, io, contextlib
    d = tempfile.mkdtemp(prefix="c8an_")
    try:
        ids = ["C-N[%03d]" % i for i in range(1300)] + ["S-%02d" % i for i in range(49)]
        st = {i: ("C" if i.startswith("C-") else "S") for i in ids}
        with open(os.path.join(d, "members.tsv"), "w") as fh:
            for i in ids: fh.write("%s\t%s\t0\t10\n" % (i, st[i]))
        def run(name, n, c67=False, null0=False, extreme=None):
            # every member: value 5 with almost all mass; value 0 with mass eps (a far tail); value 10 small
            L = 4000000; sc = float(n); lines = []
            if null0: lines += ["C8_NULL0_DRAWS=%d" % n, "C8_NULL0_SEED=1", "C8_NULL0_NOT_C1=0"]
            else:
                lines += ["KNUTH_PROBES=EXECUTED-EQ-PLANNED", "KNUTH-PROVENANCE seed_base=0x1 x", ("C6/C7 pins ACTIVE" if c67 else ""),
                          "  leaves_canonical_C1C5 : est=%.6e  95%%CI=[%.4e, %.4e]  relerr=0.01%%  hitrate=0.1" % (
                              (REF_N1P if c67 else REF_N1), (REF_N1P if c67 else REF_N1) * 0.999, (REF_N1P if c67 else REF_N1) * 1.001)]
                sc = (REF_N1P if c67 else REF_N1) * n
            lines += ["C8_MEMBERS=1349", "C8_RAW_SC=%.17g" % sc, "C8_RAW_QC=%.17g" % (sc * sc / L), "C8_RAW_N=%d" % n,
                      "C8_LEAVES_SCORED=%d" % L, "C8_CLAMPED=0", "C8_UNDEFINED=0"]
            for i in ids:
                eps = 1e-9                                  # every member can attain the bar (not ATTAIN)
                for v, f in ((0, eps), (5, 1 - eps - 1e-2), (10, 1e-2)):
                    lines.append("c8_hist %s %d %.17g %.17g" % (i, v, f * sc, f * sc * sc / L))
                for v, f in ((0, eps), (5, 1 - eps - 1e-2), (10, 1e-2)):
                    lines.append("c8_hcnt %s %d %d" % (i, v, max(12, int(f * L))))
            open(os.path.join(d, name + ".out"), "w").write("\n".join(lines) + "\n")
        ext = {"C-N[007]", "S-03"}
        run("N1_A", N1_PROBES // 2, extreme=ext); run("N1_B", N1_PROBES // 2, extreme=ext)
        run("N1P_A", 5000000000, c67=True); run("N1P_B", 5000000000, c67=True)
        run("N0", N0_DRAWS, null0=True)
        with open(os.path.join(d, "kw.out"), "w") as fh:
            fh.write("C8_KW_PIN=PIN\n" + "".join("c8_kw %s %d\n" % (i, 0 if i in ext else 5) for i in ids))
        with open(os.path.join(d, "controls.out"), "w") as fh:
            fh.write("C8_CONTROLS_NA_MAP=PASS\n")
            for c in CONTROLS: fh.write("".join("c8_ctrl %s %s 5\n" % (c, i) for i in ids))
        with open(os.path.join(d, "gates.txt"), "w") as fh:
            fh.write("PREREG_SHA_VERIFIED=PASS\nDEFCHECK_SHA_VERIFIED=PASS\nDEFCHECK=PASS\nFAMILY_K=1349\n"
                     "AMENDMENT_SHA_VERIFIED=PASS\nDEFCHECK_A1_SHA_VERIFIED=PASS\n"
                     "MEMBER_LIST_SHA256=529fb27a96ec9ebc422b64ef0f5d091319a85e859bb65fbc93f6f61aef6ff34a\n"
                     "SUBGROUP_LIST_SHA256=44e8a16bd08c4caf0edd1619ca598b891e5515836ca6feb67ae59fd605d40d52\n"
                     "C8_VERIFY=PASS\nC8_VERIFY_MUTANT=FAIL\nBINARY_FRESH=FRESH\nSELFTEST=PASS\nINSTRUMENT_PIN=PIN\n")
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf): rc = analyze(d)
        t = dict(l.split("=", 1) for l in buf.getvalue().splitlines() if "=" in l)
        last = buf.getvalue().strip().splitlines()[-1]
        ok = (rc == 0 and last == "FAMILY=SURVIVOR" and t["SURVIVORS"] == "C-N[007],S-03"
              and t["C-N[000]_VERDICT"] == "NULL" and t["COUNT_SURVIVOR"] == "2" and t["C8_CLAMPED_TOTAL"] == "0")
        ok = ok and t["INDEPENDENCE_RULE"] == "AMENDMENT_1_A4" and t["C-N[007]_INDEPENDENCE"] == "INDEPENDENT_OF_C2_C5"
        # amendment 1 A2 legs: an NA control on the survivor member must NOT defeat it (NA never defeats);
        # a DEFINED control in the tail -> SPECIFICITY; the NA-map gate FAIL -> VOID.  Then a clamp -> VOID.
        base = open(os.path.join(d, "controls.out")).read()
        open(os.path.join(d, "controls.out"), "w").write(base.replace("c8_ctrl FUXI S-03 5", "c8_ctrl FUXI S-03 NA"))
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf): analyze(d)
        t1 = dict(l.split("=", 1) for l in buf.getvalue().splitlines() if "=" in l)
        ok = ok and t1["SURVIVORS"] == "C-N[007],S-03" and t1["CONTROL_NA_FUXI"] == "1" and t1["S-03_CONTROL_FUXI"].startswith("value=NA")
        open(os.path.join(d, "controls.out"), "w").write(base.replace("c8_ctrl FUXI S-03 5", "c8_ctrl FUXI S-03 0"))
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf): analyze(d)
        t2 = dict(l.split("=", 1) for l in buf.getvalue().splitlines() if "=" in l)
        ok = ok and t2["S-03_VERDICT"] == "UNINFORMATIVE SPECIFICITY" and t2["SURVIVORS"] == "C-N[007]"
        open(os.path.join(d, "controls.out"), "w").write(base.replace("C8_CONTROLS_NA_MAP=PASS", "C8_CONTROLS_NA_MAP=FAIL"))
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf): analyze(d)
        ok = ok and buf.getvalue().strip().splitlines()[-1] == "FAMILY=VOID"
        open(os.path.join(d, "controls.out"), "w").write(base)
        n0 = open(os.path.join(d, "N0.out")).read().replace("C8_CLAMPED=0", "C8_CLAMPED=1")
        open(os.path.join(d, "N0.out"), "w").write(n0)
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf): analyze(d)
        ok = ok and buf.getvalue().strip().splitlines()[-1] == "FAMILY=VOID"
        print("C8_ANALYZE_SELFTEST=%s" % ("PASS" if ok else "FAIL"))
        return 0 if ok else 1
    finally:
        shutil.rmtree(d, ignore_errors=True)


if __name__ == "__main__":
    if sys.argv[1:] == ["--selftest"]: sys.exit(selftest())
    sys.exit(analyze(sys.argv[1] if len(sys.argv) > 1 else os.path.dirname(os.path.abspath(__file__))))
