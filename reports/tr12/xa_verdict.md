# XA -- the exhaustion atlas (n=31)

Source: `atlas_n31.json` (`roae-kc-scan-atlas`), space `C1C2C4C5-SUPERSPACE`.
Semantics: certificate, not proof. Every count below is exact.

## Gates

| gate | expected | got | verdict |
|---|---|---|---|
| `sum_b solutions(b) == N` | 1097051278789181790036112071176579186688 | 1097051278789181790036112071176579186688 | PASS |
| every branch `t_source` reads `t-ladder` (pre-registered) | t-ladder | t-ladder | PASS |
| `1 + sum_b prefixes_t_units(b) == t(root)` | 8690552978660778147480075615137911218123 | 8690552978660778147480075615137911218123 | PASS |
| `N mod 24 == 0` (XA-24, free order-24 action, TR-5) | 0 | 0 | PASS |
| every layer flow mod 24 == 0 (XA-24) | none | none | PASS |

The t-unit accounting convention (a t-unit is one valid oriented prefix; the
empty prefix counts; dead ends count) is certified separately and exhaustively
at n=9 by `solve --kc-t-cert` (TR-12 XA(iii) / `xa_node_convention.json`,
written into this same artifact root by that command).
This consumer does NOT re-derive it and does not claim it.

## Branch extremes (t-units; NOT production-DFS nodes -- the map is uncertified)

- cheapest branch: index 4 (pair 3, entry 16, exit 2) -- 87155100935215576872931188231839917370 t-units, 11219431412719560131422562488388943872 solutions
- costliest branch: index 6 (pair 5, entry 56, exit 7) -- 187645339616071075480274232127228606585 t-units, 23230913249322620342098471098452017152 solutions

## Exhaustibility (XA-c/d)

**PENDING** -- pricing t-units as production-DFS nodes needs a W0-D t-unit ->
`SOLVE_NODE_LIMIT` mapping certificate, supplied with `--xa-node-mapping-cert`.
A t-unit is one valid oriented SUPER prefix; `SOLVE_NODE_LIMIT` counts
production-DFS nodes, and that DFS prunes on one combined kw_dist budget and
applies C3 only as a filter at the full-walk leaf. Nothing here certifies the
map, so no EXHAUSTIBLE/INFEASIBLE call is made. The t-unit column above is
exact and stands on its own.
