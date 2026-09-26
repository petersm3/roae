#@ scripts/doc_gates.d/99_claim_ledger.sh -- sourced by scripts/doc_gates.sh; not runnable on its own.
#@ GATE 92: the typed claim ledger documentation/CLAIMS.tsv holds against the published text and
#@ the committed artifacts (Q-296, first tranche, 2026-09-26). Added after the Q-797 split, so it has
#@ no pre-split line range; `#@` lines are split commentary. Run it through the entry:
#@ bash scripts/doc_gates.sh claim-ledger
# ---------------------------------------------------------------------------
# GATE 92 — every row of documentation/CLAIMS.tsv is TRUE (`claim-ledger`). Q-296, 2026-09-26.
#
# WHY. A published figure was checked, where it was checked at all, by a gate written for that one
# figure. The ledger types each figure (set, equivalence, unit, scope, status) and ties it to its
# published line and to a command that re-derives it from committed files, so one gate covers every
# row and a new row needs no new gate. The first tranche is TR-12's headline figures: its executive
# summary, its abstract and its five figure captions (66 rows, measured 2026-09-26).
#
# WHAT IT RUNS. `scripts/claim_ledger.sh --check --selftest` (one process, so the evidence commands
# run once; ~15 s on the worker, 2026-09-26). --check gives every row CLAIM_<id>=TRUE|FALSE and
# the ledger CLAIM_LEDGER=PASS|FAIL|ERROR. A row is TRUE only if its figure is on its cited line,
# its evidence re-derives it, a conditional-on figure has its premise in the same sentence, every
# solve.py flag its evidence names exists, and its artifacts exist. --selftest re-runs the check on
# in-memory mutants (a wrong value in the ledger, a changed published line, a premise deleted from
# its sentence, a premise one sentence away, a shifted line, a missing key, a missing flag, a figure
# only inside a longer number, four schema faults, a missing artifact, and a consistent wrong figure
# planted in the ledger AND the text for EVERY row) and each must give its stated verdict:
# CLAIM_LEDGER_SELFTEST=PASS or this gate fails.
#
# WHAT IT DOES NOT CHECK. Figures the ledger has no row for. The ledger does not yet generate
# documentation/CLAIM_TO_ARTIFACT.md, and it has no retracted-status rows; see CLAIMS.tsv's header.
# ---------------------------------------------------------------------------
gate_claim_ledger() {
  echo "== GATE 92: documentation/CLAIMS.tsv -- every typed claim holds against its published line and its evidence =="
  local out rc=0
  out=$(bash scripts/claim_ledger.sh --check --selftest 2>&1)
  printf '%s\n' "$out"
  grep -qx 'CLAIM_LEDGER=PASS' <<<"$out" || rc=1
  grep -qx 'CLAIM_LEDGER_SELFTEST=PASS' <<<"$out" || rc=1
  return $rc
}
