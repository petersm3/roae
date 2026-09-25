#!/usr/bin/env bash
# TR-7 circular census: pool 20 seeded 1e9-probe chunks per wrap class (README.md in this directory).
#
# Run from anywhere: `bash pool.sh` reads ./out/ next to this file and prints KEY=value lines (pool.out).
# Shell + awk only (the repo's single-file rule keeps Python in solve.py).
#
# Term per multiset = the absolute wrap-bin estimate of the one bin that restores King Wen's circular
# multiset (M2: d2, M4: d4, M': d1). Pooled estimate = mean of the chunk estimates (equal probes per
# chunk); pooled SE = sqrt(sum se_i^2)/k. Replication check: (k-1) * sample variance of the chunk
# estimates / mean se_i^2, which is chi-squared with k-1 df when the printed SE is right.
# Parity control: the bins of the other parity must be exactly 0 in every chunk.
#
# The chunk outputs were produced before the print was landed in solve.c, under the scratch label
# `WRAPBIN-SCRATCH`; solve.c prints the same numbers under `wrap-bin`. Both labels are read.
#
# Every check is fatal: a failed assertion prints `ASSERT_FAIL ...` to stderr and exits non-zero.
# A parity violation prints `PARITY_VIOLATION ...`, finishes, prints Q741_PARITY=FAIL and exits 1.
set -euo pipefail
export LC_ALL=C
cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")"

files=()
for m in M2 M4 Mp; do
    shopt -s nullglob
    mf=(out/"${m}"_c*.out)
    shopt -u nullglob
    if [ "${#mf[@]}" -ne 20 ]; then
        echo "ASSERT_FAIL $m: ${#mf[@]} chunk files, want 20" >&2
        exit 1
    fi
    files+=("${mf[@]}")
done
# The check is for "\nRC=0\n": the awk below matches a whole RC=0 line, so require a final newline.
for f in "${files[@]}"; do
    if [ -n "$(tail -c1 "$f")" ]; then
        echo "ASSERT_FAIL $f: no final newline" >&2
        exit 1
    fi
done

awk '
function fail(msg) { print "ASSERT_FAIL " msg > "/dev/stderr"; failed = 1; exit 1 }
function hex(s,   i, v, c) {
    s = tolower(substr(s, 3)); v = 0
    for (i = 1; i <= length(s); i++) { c = index("0123456789abcdef", substr(s, i, 1)); v = v * 16 + c - 1 }
    return v
}
# Per-chunk checks, run when a file has been fully read.
function finish_file(   d, nb) {
    if (!rc0) fail(cur ": no RC=0 line")
    if (!knuth) fail(cur ": not 1e9 probes at 64 threads")
    if (!budget) fail(cur ": wrong multiset")
    if (!seen_seed || seed != want) fail(cur ": seed " (seen_seed ? seedtxt : "missing") " != " want)
    nb = 0
    for (d in bins) nb++
    for (d = 0; d <= 6; d++) if (!(d in bins)) nb = -1
    if (nb != 7) fail(cur ": wrap bins parsed are not exactly d0..d6")
    for (d = 0; d <= 6; d++)
        if ((d % 2) != (B[m] % 2) && ab[d] + 0 != 0) {
            print "PARITY_VIOLATION " cur " d" d "=" ab[d]
            ok = 0
        }
    k[m]++; est[m, k[m]] = ab[B[m]] + 0; se[m, k[m]] = abse[B[m]] + 0
    if (k[m] == 20) report(m)
}
function report(m,   i, n, s, ss, mean, var, chi2, sem) {
    n = k[m]; s = 0; ss = 0
    for (i = 1; i <= n; i++) { s += est[m, i]; ss += se[m, i] * se[m, i] }
    mean = s / n
    sem = sqrt(ss) / n
    var = 0
    for (i = 1; i <= n; i++) var += (est[m, i] - mean) * (est[m, i] - mean)
    var = var / (n - 1)
    chi2 = (n - 1) * var / (ss / n)
    MEAN[m] = mean; SE[m] = sem
    printf "Q741_%s_CHUNKS=%d\n", m, n
    printf "Q741_%s_TERM=%.6e\n", m, mean
    printf "Q741_%s_SE=%.3e\n", m, sem
    printf "Q741_%s_RELERR=%.4f%%\n", m, 100 * sem / mean
    printf "Q741_%s_CHI2_DF%d=%.2f\n", m, n - 1, chi2
}
BEGIN {
    B["M2"] = 2; B["M4"] = 4; B["Mp"] = 1
    MIDX["M2"] = 0; MIDX["M4"] = 1; MIDX["Mp"] = 2      # seed S = 2026100000 + 100*m + c
    # The budget line solve.c echoes (d6 is printed after the pure-pair decrement, so 9 -> 8).
    BUDGET["M2"] = "d0=0 d1=2 d2=19 d3=14 d4=19 d6=8"
    BUDGET["M4"] = "d0=0 d1=2 d2=20 d3=14 d4=18 d6=8"
    BUDGET["Mp"] = "d0=0 d1=1 d2=20 d3=14 d4=19 d6=8"
    ok = 1; cur = ""
    num = "[0-9.e+-]+"
    binre = "\\[score\\] (WRAPBIN-SCRATCH|wrap-bin) d[0-9] : frac=[0-9.]+ se=" num " \\| abs est=" num " se=" num
}
FNR == 1 {
    if (cur != "") finish_file()
    cur = FILENAME
    if (!match(cur, /_c[0-9]+\.out$/)) fail(cur ": no chunk index in name")
    c = substr(cur, RSTART + 2, RLENGTH - 6) + 0
    m = cur; sub(/^.*\//, "", m); sub(/_c[0-9]+\.out$/, "", m)
    if (!(m in B)) fail(cur ": unknown class " m)
    want = 2026100000 + 100 * MIDX[m] + c
    rc0 = knuth = budget = seen_seed = 0; split("", bins); split("", ab); split("", abse)
}
# "\nRC=0\n": a whole line, not the first one (every chunk file ends in a newline; checked in bash).
FNR > 1 && $0 == "RC=0" { rc0 = 1 }
index($0, "KNUTH-ESTIMATE probes=1000000000 threads=64 ") { knuth = 1 }
index($0, "C5 BUDGET OVERRIDE ACTIVE (R6): " BUDGET[m] " ") { budget = 1 }
!seen_seed && match($0, /SEED OVERRIDE ACTIVE: base=0x[0-9a-fA-F]+/) {
    seedtxt = substr($0, RSTART + 27, RLENGTH - 27); seed = hex(seedtxt); seen_seed = 1
}
{
    line = $0
    while (match(line, binre)) {
        rec = substr(line, RSTART, RLENGTH); line = substr(line, RSTART + RLENGTH)
        n = split(rec, t, / +/)       # [score] LABEL dN : frac=.. se=.. | abs est=.. se=..
        d = substr(t[3], 2) + 0
        bins[d] = 1
        ab[d] = substr(t[9], 5); abse[d] = substr(t[10], 4)
    }
}
END {
    if (failed) exit 1
    if (cur != "") finish_file()
    if (failed) exit 1
    # T3 = f3 * N_lin from the TR-7 published seed-distinct 2e10 pair (../wrap_mass_reseed/):
    # f3 = 0.651504 +/- 0.000096, N_lin = mean of the two leaves_canonical_C1C5 lines = 1.32889e38.
    # Its SE is propagated in quadrature from those two SEs; that is an approximation, because f3 and
    # N_lin come from the same runs. T1 was published as 0.175 * 6.507e37 = 1.1388e37 with no SE;
    # the Mp term above is a fresh, seed-distinct re-measurement of it.
    Nlin = 1.32889e38
    seN = ((1.3295e38 - 1.3280e38) + (1.3298e38 - 1.3283e38)) / 2 / 2 / 1.96 / sqrt(2)
    f3 = 0.651504; sef3 = 0.000096
    T3 = f3 * Nlin
    seT3 = T3 * sqrt((seN / Nlin) * (seN / Nlin) + (sef3 / f3) * (sef3 / f3))
    M2 = MEAN["M2"]; M4 = MEAN["M4"]; Mp = MEAN["Mp"]
    s = sqrt(SE["M2"] * SE["M2"] + SE["M4"] * SE["M4"] + SE["Mp"] * SE["Mp"])
    C = T3 + Mp + M2 + M4
    printf "Q741_T3_PUBLISHED=%.6e\n", T3
    printf "Q741_T3_SE_APPROX=%.3e\n", seT3
    printf "Q741_CCIRC=%.6e\n", C
    printf "Q741_CCIRC_SE_EXCL_T3=%.3e\n", s
    printf "Q741_CCIRC_SE_INCL_T3_APPROX=%.3e\n", sqrt(s * s + seT3 * seT3)
    printf "Q741_CCIRC_OVER_NLIN=%.4f\n", C / Nlin
    printf "Q741_OMITTED_SHARE=%.4f\n", (M2 + M4) / C
    printf "Q741_TWO_TERM_OVER_NLIN=%.4f\n", (T3 + Mp) / Nlin
    printf "Q741_T1_VS_PUBLISHED_PCT=%+.3f\n", 100 * (Mp - 1.1388e37) / 1.1388e37
    print "Q741_PARITY=" (ok ? "PASS" : "FAIL")
    if (!ok) exit 1
}
' "${files[@]}"
