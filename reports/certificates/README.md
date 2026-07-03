# UNSAT certificates (DRAT)

Each certificate pairs with a deterministic CNF regeneration command; regenerated CNF + archived proof
must check with drat-trim (`drat-trim <cnf> <proof>` -> `s VERIFIED`). See reports/METHODS.md.

| Certificate | Regenerate CNF | Establishes |
|---|---|---|
| alt-le-14.drat.gz | `python3 sat.py --emit-cnf alt-le-14 f.cnf` | ≤14 alternations impossible |
| alt-ge-16.drat.gz | `python3 sat.py --emit-cnf alt-ge-16 f.cnf` | ≥16 alternations impossible |
| moore-strict-near-2.drat.gz | `python3 sat.py --emit-cnf moore-strict-near-2 f.cnf` | Moore repair ≥3 edits |
| rc4_near2_unsat.drat.gz | `python3 sat.py --emit-cnf rc4-strict-near-2 f.cnf` | gender-rule repair ≥3 edits |
| grand_ccn4_unsat.drat.gz | `python3 sat.py --emit-cnf grand-ccn4 f.cnf` | THE CONFLICT THEOREM |
