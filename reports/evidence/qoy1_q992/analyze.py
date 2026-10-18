#!/usr/bin/env python3
"""PREREG_QOY1_Q992_2026_10_09 §4.2-§5.4 / §7.5: mechanical verdicts from the recorded outputs.
Reads n0_exact.out, gates.txt and the four estimator outputs in this directory; prints KEY=value
tokens (TOKENS.txt is this script's stdout). No threshold, null or rule here is chosen by this
script: each is transcribed from the frozen file, cited by section."""
import math, os, re, sys
from fractions import Fraction as F
D = os.path.dirname(os.path.abspath(__file__))
BAR, CAND = 0.005, 1e-4                       # §5.2
REF_N1, BAND_N1_HALF, BAND_N1_POOL = 1.3287e38, 0.005, 0.002   # §4.2
REF_N1P, BAND_N1P = 5.21e31, 0.01             # §4.3 (SEARCH_SPACE_SIZE.md C1-C7 row: 5.21e31)
STAT = {"Q992": "X", "QOY1": "D"}
tok = []
def out(k, v): tok.append("%s=%s" % (k, v))

def kv(path):
    d = {}
    for ln in open(path, encoding="utf-8", errors="replace"):
        m = re.match(r"^([A-Z0-9_]+)=(.*)$", ln.rstrip("\n"))
        if m: d[m.group(1)] = m.group(2)
    return d

def parse_run(path):
    r = {"hist": {}, "occ": {}}
    txt = open(path, encoding="utf-8", errors="replace").read()
    for k in ("QOY_RAW_SC", "QOY_RAW_QC"): r[k] = float(re.search(r"^%s=(\S+)$" % k, txt, re.M).group(1))
    for k in ("QOY_RAW_N", "QOY_LEAVES_SCORED", "QOY_W_NOT6_LEAVES", "QOY_INCONSISTENT_LEAVES", "QOY_CLAMPED", "QOY_KW_X", "QOY_KW_D"):
        r[k] = int(re.search(r"^%s=(\S+)$" % k, txt, re.M).group(1))
    r["probes_ok"] = bool(re.search(r"^KNUTH_PROBES=EXECUTED-EQ-PLANNED$", txt, re.M))
    r["est"] = float(re.search(r"leaves_canonical_C1C5 : est=(\S+)", txt).group(1))
    r["seed"] = re.search(r"seed_base=(\S+)", txt).group(1)
    r["c67"] = "C6/C7 pins ACTIVE" in txt
    for m in re.finditer(r"^qoy_hist (\S+) (\d+) (\S+) (\S+)$", txt, re.M):
        r["hist"].setdefault(m.group(1), {})[int(m.group(2))] = (float(m.group(3)), float(m.group(4)))
    for m in re.finditer(r"^qoy_occ (\d+) (\S+) (\S+)$", txt, re.M):
        r["occ"][int(m.group(1))] = (float(m.group(2)), float(m.group(3)))
    return r

def pool(runs):
    p = {"sC": sum(r["QOY_RAW_SC"] for r in runs), "qC": sum(r["QOY_RAW_QC"] for r in runs),
         "N": sum(r["QOY_RAW_N"] for r in runs), "L": sum(r["QOY_LEAVES_SCORED"] for r in runs),
         "wnot6": sum(r["QOY_W_NOT6_LEAVES"] for r in runs), "incons": sum(r["QOY_INCONSISTENT_LEAVES"] for r in runs),
         "clamped": sum(r["QOY_CLAMPED"] for r in runs), "hist": {}, "occ": {}}
    for r in runs:
        for s, h in r["hist"].items():
            for b, (a, q) in h.items():
                x = p["hist"].setdefault(s, {}).get(b, (0.0, 0.0)); p["hist"][s][b] = (x[0] + a, x[1] + q)
        for k, (a, q) in r["occ"].items():
            x = p["occ"].get(k, (0.0, 0.0)); p["occ"][k] = (x[0] + a, x[1] + q)
    p["est"] = p["sC"] / p["N"]
    return p

def mass_se(sqi, m, B, Qb):                   # solve.c KNUTH_MASS_SE (Q-374)
    return math.sqrt(max(0.0, sqi * (1 - 2 * m) + m * m * Qb)) / B if B > 0 else 0.0

def tail(p, s, v, side):
    h = p["hist"].get(s, {})
    sel = [(a, q) for b, (a, q) in h.items() if (b <= v if side == "le" else b >= v)]
    a = math.fsum(x[0] for x in sel); q = math.fsum(x[1] for x in sel)   # fsum: version-independent (F02-002#10)
    m = a / p["sC"]; se = mass_se(q, m, p["sC"], p["qC"])
    op = m + 3 * se if a > 0 else 3.0 / p["L"]          # §5.1, rule of three on an empty tail
    return m, se, min(1.0, op)

def ptwo(p, s, v):
    le, ge = tail(p, s, v, "le"), tail(p, s, v, "ge")
    two = min(1.0, 2 * min(le[2], ge[2]))
    side = "le" if le[2] <= ge[2] else "ge"
    return le, ge, two, side

def n0_tails(n0, q):
    def f(k): return float(n0[k].split("|")[1])
    return f(q + "_N0_P_LE"), f(q + "_N0_P_GE"), f(q + "_N0_P_TWO")

def controls(n0):
    c = {}
    for nm in ("JINGFANG", "MAWANGDUI", "FUXI"):
        ln = n0["CONTROL_%s" % nm] if ("CONTROL_%s" % nm) in n0 else None
        c[nm] = ln
    return c

def ctrl_vals(path):
    c = {}
    for ln in open(path, encoding="utf-8"):
        m = re.match(r"^CONTROL_(\S+) qoy X=(\d+) W=(\d+) T=\d+ A=\d+ D=(\S+) NSAME=\d+ CONSISTENT=(\S+)", ln)
        if m: c[m.group(1)] = {"X": int(m.group(2)), "W": int(m.group(3)), "D": None if m.group(4) == "NA" else int(m.group(4)), "cons": m.group(5)}
    return c

def classify(p, q, kwv, n0two, n0side, ctl):
    s = STAT[q]
    h = p["hist"].get(s, {}); bins = [b for b, (a, _) in h.items() if a > 0]
    le, ge, two, side = ptwo(p, s, kwv)
    spec, ctlp = "NA", {}
    for nm, cv in ctl.items():
        v = cv[s]
        ctlp[nm] = (v, None if v is None else tail(p, s, v, side)[2])
    if two < CAND:
        spec = "FAIL" if any(x is not None and x <= BAR for _, x in ctlp.values()) else "PASS"
    if min(bins) == max(bins): cls = "FORCED"
    elif two < CAND and spec == "PASS": cls = "CANDIDATE_C8"
    elif two < BAR: cls = "NOTABLE"
    elif n0two < BAR: cls = "EXPLAINED_BY_EXISTING"
    else: cls = "UNINFORMATIVE"
    if two < BAR and n0two < BAR and n0side == side: ind = "INDEPENDENT_OF_C2_C5"
    elif two < BAR and n0two >= BAR: ind = "C2_C5_CONDITIONAL"
    elif n0two < BAR and two >= BAR: ind = "EXPLAINED_BY_C2_C5"
    else: ind = "NA"
    E = sum(b * a for b, (a, _) in h.items()) / p["sC"]
    return dict(le=le, ge=ge, two=two, side=side, spec=spec, ctlp=ctlp, cls=cls, ind=ind, E=E, mn=min(bins), mx=max(bins))

def main():
    n0 = kv(os.path.join(D, "n0_exact.out")); g = kv(os.path.join(D, "gates.txt"))
    ctl = ctrl_vals(os.path.join(D, "n0_exact.out"))
    runs = {k: parse_run(os.path.join(D, k + ".out")) for k in ("N1_A", "N1_B", "N1P_A", "N1P_B")}
    for k, r in runs.items():
        assert r["probes_ok"], k
        assert r["c67"] == k.startswith("N1P"), k
    for k in ("PREREG_SHA_VERIFIED", "DEFCHECK", "QOY_VERIFY", "QOY_VERIFY_MUTANT", "BINARY_FRESH", "Q992_KW_W",
              "QOY1_KW_COSETS_CONSISTENT", "INSTRUMENT_PIN", "VERIFY_PY_SHA256", "SOLVE_C_SHA256", "SOLVE_PY_SHA256",
              "TESTS_PY_SHA256", "SOLVE_BIN_SHA256", "PUBLIC_HEAD", "PRIVATE_HEAD", "SOLVE_THREADS", "SELFTEST"):
        out(k, g.get(k, "MISSING"))
    for k in ("Q992_N0_LAW", "Q992_N0_E", "QOY1_N0_LAW", "QOY1_N0_E", "QOY1_N0_C32_8_AGREES", "N0_SAMPLER_CROSSCHECK",
              "Q992_KW_T", "Q992_KW_A", "QOY1_KW_NSAME", "QOY1_KW_COSET_STRING", "QOY1_COSET_STRING_MATCHES_FINDING",
              "Q992_W_UNIFORM64_HIST"):
        out(k, n0[k])
    for k in ("Q992", "QOY1"):
        for t in ("P_LE", "P_GE", "P_TWO"): out("%s_N0_%s" % (k, t), n0["%s_N0_%s" % (k, t)])
    out("FAMILY_K", 2); out("FAMILY_ALPHA", 0.01); out("PER_QUERY_BAR", BAR); out("CANDIDATE_BAR", CAND)

    pools = {"N1": (pool([runs["N1_A"], runs["N1_B"]]), pool([runs["N1_A"]]), pool([runs["N1_B"]]), REF_N1, BAND_N1_HALF, BAND_N1_POOL),
             "N1C67": (pool([runs["N1P_A"], runs["N1P_B"]]), pool([runs["N1P_A"]]), pool([runs["N1P_B"]]), REF_N1P, BAND_N1P, BAND_N1P)}
    kw = {"Q992": int(n0["Q992_KW_VALUE"]), "QOY1": int(n0["QOY1_KW_VALUE"])}
    for r in runs.values():
        assert r["QOY_KW_X"] == kw["Q992"] and r["QOY_KW_D"] == kw["QOY1"]
    wconst = all(r["QOY_W_NOT6_LEAVES"] == 0 for r in runs.values())
    out("Q992_W_CONST", "YES" if wconst else "NO")
    out("QOY1_LEAF_COSET_CONSISTENT_ALL", "YES" if all(r["QOY_INCONSISTENT_LEAVES"] == 0 for r in runs.values()) else "NO")
    out("QOY_CLAMPED_TOTAL", sum(r["QOY_CLAMPED"] for r in runs.values()))
    gates_ok = (g.get("PREREG_SHA_VERIFIED") == "PASS" and g.get("DEFCHECK") == "PASS" and g.get("QOY_VERIFY") == "PASS"
                and g.get("QOY_VERIFY_MUTANT") == "FAIL" and g.get("BINARY_FRESH") == "FRESH" and g.get("Q992_KW_W") == "6"
                and g.get("QOY1_KW_COSETS_CONSISTENT") == "YES" and g.get("INSTRUMENT_PIN", "MISSING") != "MISSING"
                and n0["N0_SAMPLER_CROSSCHECK"] == "PASS")
    out("PRE_RUN_GATES_ALL", "PASS" if gates_ok else "FAIL")
    res = {}
    for pop, (P, A, B, ref, bh, bp) in pools.items():
        devA, devB, devP = A["est"] / ref - 1, B["est"] / ref - 1, P["est"] / ref - 1
        sv = abs(devA) <= bh and abs(devB) <= bh and abs(devP) <= bp
        for q in ("Q992", "QOY1"):
            n0le, n0ge, n0two = n0_tails(n0, q); n0side = "le" if n0le <= n0ge else "ge"
            cP = classify(P, q, kw[q], n0two, n0side, ctl); cA = classify(A, q, kw[q], n0two, n0side, ctl); cB = classify(B, q, kw[q], n0two, n0side, ctl)
            rep = cA["cls"] == cB["cls"]
            pre = "%s_%s" % (q, pop)
            if q == "Q992": out("Q992_KW_VALUE", kw[q]) if pop == "N1" else None
            if q == "QOY1": out("QOY1_KW_VALUE", kw[q]) if pop == "N1" else None
            out(pre + "_PROBES", A["N"] + B["N"])
            out(pre + "_SEEDS", "%s,%s" % (runs["N1_A" if pop == "N1" else "N1P_A"]["seed"], runs["N1_B" if pop == "N1" else "N1P_B"]["seed"]))
            for tag, X in (("A", A), ("B", B), ("POOLED", P)):
                h = X["hist"].get(STAT[q], {})
                out(pre + "_HIST_" + tag, ",".join("%d:%.6e" % (b, h[b][0] / X["sC"]) for b in sorted(h)))
            out(pre + "_E", "%.6f" % cP["E"]); out(pre + "_MIN_MAX", "%d,%d" % (cP["mn"], cP["mx"]))
            out(pre + "_P_LE", "%.6e" % cP["le"][0]); out(pre + "_P_GE", "%.6e" % cP["ge"][0])
            out(pre + "_SE_LE", "%.3e" % cP["le"][1]); out(pre + "_SE_GE", "%.3e" % cP["ge"][1])
            out(pre + "_P_LE_OPERATIVE", "%.6e" % cP["le"][2]); out(pre + "_P_GE_OPERATIVE", "%.6e" % cP["ge"][2])
            out(pre + "_P_TWO_OPERATIVE", "%.6e" % cP["two"]); out(pre + "_SMALLER_TAIL", cP["side"].upper())
            out(pre + "_SELFVALIDATION", "%s (est A=%.6e dev=%+.4f%%, B=%.6e dev=%+.4f%%, pooled=%.6e dev=%+.4f%%; ref %.4e, bands %.1f%%/%.1f%%)"
                % ("PASS" if sv else "FAIL", A["est"], 100 * devA, B["est"], 100 * devB, P["est"], 100 * devP, ref, 100 * bh, 100 * bp))
            out(pre + "_REPLICATION", "%s (A=%s p_two=%.3e, B=%s p_two=%.3e)" % ("PASS" if rep else "FAIL", cA["cls"], cA["two"], cB["cls"], cB["two"]))
            out(pre + "_CLASS_POOLED", cP["cls"])
            if pop == "N1":
                for nm, (v, pp) in cP["ctlp"].items():
                    out("%s_CONTROL_%s" % (q, nm), "value=%s same_tail(%s)_operative_p=%s cosets_consistent=%s" % (
                        "NA" if v is None else v, cP["side"].upper(), "NA" if pp is None else "%.6e" % pp, ctl[nm]["cons"]))
                out(q + "_SPECIFICITY", cP["spec"])
                out(q + "_INDEPENDENCE", cP["ind"])
            res[(q, pop)] = (cP, sv, rep)
    for q in ("Q992", "QOY1"):
        cP, sv, rep = res[(q, "N1")]
        if not (gates_ok and sv and rep): v = "VOID"
        else: v = cP["cls"]
        out(q + "_VERDICT", v)
        cP2, sv2, rep2 = res[(q, "N1C67")]
        out(q + "_N1C67_ANNOTATION", "%s%s" % (cP2["cls"], "" if (sv2 and rep2) else " (N1' gates: selfvalidation=%s replication=%s)" % ("PASS" if sv2 else "FAIL", "PASS" if rep2 else "FAIL")))
        out(q + "_N1C67_CHANGES_CLASS", "YES" if cP2["cls"] != cP["cls"] else "NO")
    P = pools["N1"][0]
    out("QOY1_N1_NSAME_HIST", ",".join("%d:%.6e" % (b, a / P["sC"]) for b, (a, _) in sorted(P["hist"].get("NSAME", {}).items())))
    out("QOY1_N1_OCCUPANCY", ",".join("%d:%.6f" % (k, P["occ"][k][0] / P["sC"]) for k in sorted(P["occ"])))
    out("Q992_N1_W_HIST", ",".join("%d:%.6e" % (b, a / P["sC"]) for b, (a, _) in sorted(P["hist"].get("W", {}).items())))
    out("Q992_N1_A_HIST", ",".join("%d:%.6e" % (b, a / P["sC"]) for b, (a, _) in sorted(P["hist"].get("A", {}).items())))
    out("N1_LEAVES_SCORED", P["L"]); out("N1C67_LEAVES_SCORED", pools["N1C67"][0]["L"])
    print("\n".join(tok))

main()
