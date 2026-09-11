#!/usr/bin/env python3
"""Statistical detector for whole-row class-mass mis-attribution in the KC atlas.

WHAT THIS IS
------------
The conservation family in the atlas consumer cannot see a permutation of
whole interior class rows: a row swap preserves every row sum, every column
sum and every divisibility test, so no conservation test can distinguish
``by_class[k]`` from ``by_class[k']`` after the two rows have traded places.
The only exact detector is the brute-force recount, which is feasible at n=9
and permanently infeasible at n=31.

This script is a *statistical* detector that does not need the recount.  It
reads walks drawn walk-uniformly from the f ladder (``solve --kc-sample``),
classifies each of the n transitions of each walk by

    d(k) = popcount(exit_{k-1} XOR entry_k),     exit_{-1} := 0

-- the identical rule used by ``_atlas_brute_recount`` in ``solve.py`` -- and
compares the empirical per-layer class frequencies against the atlas's own
``by_class[k][d] / N_total``.  If a row has been mis-attributed, the atlas
predicts layer k's masses at layer k', the sample does not, and the two
disagree by the size of the gap between the two rows.

The sample path is independent of the material this detector is checking: it
uses f-based unranking and touches neither the g ladder nor the atlas
extractor.  The empirical counts are therefore a witness produced outside the
closure of the artifact under test.

WHAT THIS IS NOT -- READ THIS BEFORE QUOTING THE VERDICT
--------------------------------------------------------
*This is a GROSS-MIS-ATTRIBUTION detector, not cell-by-cell verification.*

  * Its resolution is the simultaneous Hoeffding bound ``eps`` printed with
    every verdict.  At the production draw of M = 10^6 over the 155 cells of
    an n=31 atlas, eps is about +/-0.0025 of total mass.  It can only see a
    mis-attribution whose induced shift in cell mass exceeds that.  Whether
    adjacent interior layers at n=31 differ by more than 0.0025 is not known
    until the atlas exists.
  * It says nothing at all about small errors, single-cell errors, or any
    error whose mass shift is below eps.
  * CLEAN means "no cell deviated from the atlas by more than eps at this
    sample size".  It is NOT a proof that the atlas is correct, and it is not
    a substitute for the brute-force recount where the recount is feasible.
  * SUSPECT means the sample and the atlas disagree.  It does NOT say which
    of the two is wrong: a defective sampler would produce the same verdict.
  * The verdict covers ONLY the ``by_class`` table.  Nothing else in the
    atlas is examined.

MEASURED POWER -- THE QUALIFICATION THAT MATTERS MOST
-----------------------------------------------------
Detecting a row swap requires the two rows to differ by more than eps.  How
often they do was measured, not assumed, by swapping every layer pair of the
real n=9 and n=13 atlases and scoring the real M=10^6 draw:

    n=9   35 of 35 distinct-row pairs detected (eps = 0.002388)
    n=13  23 of 78 distinct-row pairs detected (eps = 0.002426)
          -- the 23 are exactly the pairs involving layer 0 or layer 1;
             ALL 55 pairs among the interior layers 2..12 were MISSED

The reason is structural: away from the anchor the per-layer class marginals
converge.  At n=13 the largest gap between any two of layers 2..12 is
0.0017549 of total mass -- already below eps at M=10^6 -- and the median gap
is 0.000103, which would need about 5.5x10^8 draws to resolve.  The layer
1 <-> 2 swap that motivated this detector is caught because layer 1 is the
anchor transient, not because interior swaps are caught.

So, plainly: on the evidence available this detector is expected to catch
mis-attribution involving the first layers, and is NOT expected to catch a
swap between two deep interior layers at n=31 -- which is the case the
inventory's "undetectable" sentence is about.  That expectation rests on two
universes (n=9, n=13) and a convergence argument; it is a hypothesis about
n=31, not a measurement of it, and the n=31 atlas will settle it.

POPULATION REQUIREMENT
----------------------
The input must be the raw walk-uniform ``--kc-sample`` draw over SUPER (the
Q4AC draw, retained by the production driver's ``--keep``).  It must NOT be a
C3-filtered draw (``--kc-c3-max``) or a class-uniform draw
(``--kc-class-uniform``), whose walks are not distributed as the atlas's
denominator.  Class-uniform input is rejected outright; a C3-filtered draw
cannot be detected from the file alone, so the operator is responsible for
supplying the right file.

ATTRIBUTION
-----------
Detector proposed in the R5 adjudication round (2026-09-11) and implemented
here.  The classifier rule is taken verbatim from ``_atlas_brute_recount``
(``solve.py``).  Any error in this file is mine, not that review's; the
framing above deliberately claims less than the round's summary did, and
corrections are welcome.
"""

import argparse
import json
import math
import os
import sys

TOKEN = "KC_CLASS_SWAP_DETECT"
DEFAULT_ALPHA = 0.001          # 99.9% simultaneous confidence

# Resolution of the production configuration, quoted in --help and in the
# emitted output so the verdict never travels without its limit.
PROD_DRAWS = 10 ** 6
PROD_CELLS = 155               # n=31: 31 layers x 5 distance classes


class DetectorError(Exception):
    """Any condition that makes a verdict impossible to compute."""


def hoeffding_eps(draws, cells, alpha):
    """Simultaneous two-sided Hoeffding bound over `cells` frequencies.

    Each cell frequency is a mean of `draws` i.i.d. indicators in [0, 1]
    (one draw contributes one indicator per layer), so Hoeffding gives
    P(|f - p| > eps) <= 2 exp(-2 m eps^2) per cell; a union bound over
    `cells` cells gives the simultaneous statement.  The union bound needs
    no independence between cells, which matters here because the n
    transitions of a single walk are dependent.
    """
    if draws <= 0:
        raise DetectorError("cannot bound a sample of %d draws" % draws)
    if cells <= 0:
        raise DetectorError("atlas declares no class cells")
    return math.sqrt(math.log(2.0 * cells / alpha) / (2.0 * draws))


def load_atlas(path):
    """Return (n, N_total, {k: {d: mass}}) from an atlas.json."""
    try:
        with open(path) as fh:
            a = json.load(fh)
    except (OSError, ValueError) as exc:
        raise DetectorError("cannot read atlas %s: %s" % (path, exc))
    try:
        n = int(a["n"])
        total = int(a["N_total"])
        layers = a["layers"]
    except (KeyError, TypeError, ValueError) as exc:
        raise DetectorError("atlas %s missing n / N_total / layers (%s)"
                            % (path, exc))
    if total <= 0:
        raise DetectorError("atlas %s has N_total=%d" % (path, total))
    table = {}
    for layer in layers:
        try:
            k = int(layer["k"])
            by = layer["by_class"]
        except (KeyError, TypeError, ValueError) as exc:
            raise DetectorError("atlas %s: malformed layer (%s)" % (path, exc))
        row = {}
        for key, val in by.items():
            if not (isinstance(key, str) and key.startswith("d")):
                raise DetectorError("atlas %s layer %d: bad class key %r"
                                    % (path, k, key))
            try:
                row[int(key[1:])] = int(val)
            except ValueError:
                raise DetectorError("atlas %s layer %d: bad class key/value "
                                    "%r=%r" % (path, k, key, val))
        if k in table:
            raise DetectorError("atlas %s: duplicate layer k=%d" % (path, k))
        table[k] = row
    missing = [k for k in range(n) if k not in table]
    if missing:
        raise DetectorError("atlas %s: no by_class row for layer(s) %s"
                            % (path, missing))
    # Input sanity only -- NOT part of the detection.  A row swap preserves
    # row sums exactly, so this check can never mask the target; it is here
    # so a truncated or hand-edited atlas errors instead of being scored.
    for k in range(n):
        s = sum(table[k].values())
        if s != total:
            raise DetectorError("atlas %s layer %d: by_class sums to %d, "
                                "N_total=%d" % (path, k, s, total))
    return n, total, table


def _walk_field(line):
    """Return the walk CSV field of one --kc-sample / --kc-enum line.

    --kc-sample emits  "<rank>\\t cd=<c>\\t <walk>".
    --kc-enum emits the bare walk.
    --kc-record appends separate "record\\t m=<m>\\t <repr>" lines, which are
    class representatives, not draws, and must not be counted.
    --kc-class-uniform emits "<rank>\\t cd=<c>\\t m=<m>\\t record\\t <repr>",
    the wrong population entirely -- rejected by the caller.
    """
    fields = line.split("\t")
    if fields[0] == "record":
        return None                      # representative, not a draw
    if len(fields) >= 4 and fields[3] == "record":
        raise DetectorError(
            "input looks like --kc-class-uniform output (field 4 == "
            "'record'); this detector requires the RAW walk-uniform "
            "--kc-sample draw over SUPER")
    return fields[-1]


def tally(paths, n):
    """Empirical class counts: {k: {d: count}}, plus the number of draws."""
    counts = [dict() for _ in range(n)]
    draws = 0
    records = 0
    for path in paths:
        try:
            fh = open(path)
        except OSError as exc:
            raise DetectorError("cannot read sample %s: %s" % (path, exc))
        with fh:
            for lineno, raw in enumerate(fh, 1):
                line = raw.strip()
                if not line or line[0] == "[" or line[0] == "#":
                    continue             # solve banners / provenance trailer
                field = _walk_field(line)
                if field is None:
                    records += 1
                    continue
                try:
                    w = [int(x) for x in field.split(",")]
                except ValueError:
                    raise DetectorError("%s:%d: not a walk CSV: %r"
                                        % (path, lineno, field[:60]))
                if len(w) != 2 * n:
                    raise DetectorError(
                        "%s:%d: walk of %d hexagrams, atlas expects %d "
                        "(n=%d) -- atlas and sample are from different "
                        "universes" % (path, lineno, len(w), 2 * n, n))
                draws += 1
                prev = 0                 # C4 pins the anchor pair's exit to 0
                for k in range(n):
                    d = bin(prev ^ w[2 * k]).count("1")
                    counts[k][d] = counts[k].get(d, 0) + 1
                    prev = w[2 * k + 1]
    if draws == 0:
        raise DetectorError("no walks found in %s" % ", ".join(paths))
    return counts, draws, records


def compare(table, counts, n, total, draws, alpha, exact):
    """Score the empirical counts against the atlas table."""
    cell_keys = []
    for k in range(n):
        ds = set(table[k]) | set(counts[k])
        for d in sorted(ds):
            cell_keys.append((k, d))
    cells = len(cell_keys)

    if exact:
        # The input is asserted to be the COMPLETE enumeration: the counts
        # must equal the atlas masses identically, with no bound involved.
        if draws != total:
            raise DetectorError(
                "--exact given but the input has %d walks and the atlas "
                "declares N_total=%d; --exact requires the complete "
                "enumeration" % (draws, total))
        bad = [(k, d, counts[k].get(d, 0), table[k].get(d, 0))
               for (k, d) in cell_keys
               if counts[k].get(d, 0) != table[k].get(d, 0)]
        return {"mode": "exact", "cells": cells, "eps": 0.0,
                "stat": float(len(bad)), "bad": bad,
                "worst": (bad[0][0], bad[0][1]) if bad else None,
                "suspect": bool(bad)}

    eps = hoeffding_eps(draws, cells, alpha)
    worst = None
    worst_diff = 0.0
    over = []
    for (k, d) in cell_keys:
        emp = counts[k].get(d, 0) / float(draws)
        ref = table[k].get(d, 0) / float(total)
        diff = abs(emp - ref)
        if diff > worst_diff:
            worst_diff, worst = diff, (k, d)
        if diff > eps:
            over.append((k, d, emp, ref, diff))
    over.sort(key=lambda r: -r[4])
    return {"mode": "sample", "cells": cells, "eps": eps,
            "stat": worst_diff, "bad": over, "worst": worst,
            "suspect": worst_diff > eps}


LIMITS = (
    "LIMITS: resolution is the printed eps (simultaneous Hoeffding, "
    "alpha=%g); at the production draw M=%d over %d cells (n=31) eps is "
    "about +/-0.0025 of total mass. This is a GROSS-MIS-ATTRIBUTION "
    "detector over by_class ONLY, not cell-by-cell verification. CLEAN "
    "means no cell deviated by more than eps at this sample size -- it is "
    "not a proof that the atlas is correct, and it says nothing about "
    "errors smaller than eps. SUSPECT means the sample and the atlas "
    "disagree; it does not say which one is wrong."
)

POWER = (
    "POWER (measured, not assumed): swapping every layer pair of the real "
    "n=13 atlas against the real M=10^6 draw detected 23 of 78 pairs -- "
    "exactly those involving layer 0 or layer 1. ALL 55 pairs among the "
    "interior layers 2..12 were MISSED, because their rows differ by at "
    "most 0.0017549 of total mass (median 0.000103), below eps. A CLEAN "
    "verdict is therefore weak evidence about DEEP INTERIOR layers and "
    "should not be read as covering them. See --help."
)


class _TokenArgParser(argparse.ArgumentParser):
    """argparse exits 2 with a bare usage message; emit the token too, so a
    mis-invocation is never distinguishable from success by output shape."""

    def error(self, message):
        print("%s=ERROR" % TOKEN)
        print("kc_class_swap_detector: bad invocation: %s" % message)
        self.print_usage(sys.stderr)
        sys.exit(2)


def main(argv=None):
    p = _TokenArgParser(
        prog="kc_class_swap_detector.py",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        description=__doc__)
    p.add_argument("--atlas", required=True, metavar="ATLAS.json",
                   help="the atlas under test (its by_class table is the "
                        "reference distribution)")
    p.add_argument("sample", nargs="+", metavar="SAMPLE",
                   help="one or more files of walks: the raw walk-uniform "
                        "'solve --kc-sample DIR M SEED' draw over SUPER "
                        "(the Q4AC draw the driver retains with --keep), or "
                        "a complete 'solve --kc-enum DIR' enumeration with "
                        "--exact. Multiple files are pooled.")
    p.add_argument("--alpha", type=float, default=DEFAULT_ALPHA,
                   metavar="A",
                   help="simultaneous error probability for the Hoeffding "
                        "bound (default %(default)g, i.e. 99.9%%)")
    p.add_argument("--exact", action="store_true",
                   help="the input is the COMPLETE enumeration (draws == "
                        "N_total): require identical counts instead of a "
                        "statistical bound. Feasible at n=9; permanently "
                        "infeasible at n=31.")
    p.add_argument("--show", type=int, default=6, metavar="K",
                   help="how many offending cells to print (default "
                        "%(default)d)")
    p.add_argument("--json", metavar="OUT",
                   help="also write the full result as JSON to OUT")
    args = p.parse_args(argv)

    try:
        if not (0.0 < args.alpha < 1.0):
            raise DetectorError("--alpha must be in (0,1), got %r"
                                % args.alpha)
        n, total, table = load_atlas(args.atlas)
        counts, draws, records = tally(args.sample, n)
        res = compare(table, counts, n, total, draws, args.alpha, args.exact)
    except DetectorError as exc:
        print("%s=ERROR" % TOKEN)
        print("kc_class_swap_detector: %s" % exc)
        print("kc_class_swap_detector: " + LIMITS
              % (args.alpha, PROD_DRAWS, PROD_CELLS))
        print("kc_class_swap_detector: " + POWER)
        return 2

    verdict = "SUSPECT" if res["suspect"] else "CLEAN"
    print("%s=%s" % (TOKEN, verdict))
    if res["mode"] == "exact":
        print("kc_class_swap_detector: mode=exact n=%d walks=%d "
              "N_total=%d cells=%d differing_cells=%d" %
              (n, draws, total, res["cells"], int(res["stat"])))
    else:
        print("kc_class_swap_detector: mode=sample n=%d draws=%d "
              "N_total=%d cells=%d max_abs_diff=%.6f eps=%.6f alpha=%g "
              "cells_over_eps=%d" %
              (n, draws, total, res["cells"], res["stat"], res["eps"],
               args.alpha, len(res["bad"])))
    if res["worst"] is not None:
        print("kc_class_swap_detector: worst_cell k=%d d=%d"
              % res["worst"])
    for row in res["bad"][:max(0, args.show)]:
        if res["mode"] == "exact":
            print("kc_class_swap_detector:   k=%d d=%d observed=%d "
                  "atlas=%d" % row)
        else:
            print("kc_class_swap_detector:   k=%d d=%d empirical=%.6f "
                  "atlas=%.6f diff=%.6f" % row)
    if len(res["bad"]) > max(0, args.show):
        print("kc_class_swap_detector:   ... %d more"
              % (len(res["bad"]) - max(0, args.show)))
    if records:
        print("kc_class_swap_detector: skipped %d --kc-record "
              "representative line(s); they are not draws" % records)
    print("kc_class_swap_detector: atlas=%s sample=%s"
          % (args.atlas, ",".join(args.sample)))
    print("kc_class_swap_detector: " + LIMITS
          % (args.alpha, PROD_DRAWS, PROD_CELLS))
    print("kc_class_swap_detector: " + POWER)

    if args.json:
        try:
            with open(args.json, "w") as fh:
                json.dump({"token": TOKEN, "verdict": verdict, "n": n,
                           "mode": res["mode"], "draws": draws,
                           "N_total": total, "cells": res["cells"],
                           "statistic": res["stat"], "eps": res["eps"],
                           "alpha": args.alpha,
                           "atlas": os.path.abspath(args.atlas),
                           "samples": [os.path.abspath(s)
                                       for s in args.sample],
                           "offenders": res["bad"][:200],
                           "limits": LIMITS % (args.alpha, PROD_DRAWS,
                                               PROD_CELLS),
                           "power": POWER},
                          fh, indent=1, sort_keys=True)
        except OSError as exc:
            print("%s=ERROR" % TOKEN)
            print("kc_class_swap_detector: cannot write --json %s: %s"
                  % (args.json, exc))
            return 2

    return 1 if res["suspect"] else 0


if __name__ == "__main__":
    sys.exit(main())
