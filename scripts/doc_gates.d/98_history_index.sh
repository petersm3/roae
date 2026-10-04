#@ scripts/doc_gates.d/98_history_index.sh -- sourced by scripts/doc_gates.sh; not runnable on its own.
#@ GATE 91: documentation/HISTORY_INDEX.md is current (Q-686, 2026-09-26). Added after the Q-797
#@ split, so it has no pre-split line range; `#@` lines are split commentary. Run it through the
#@ entry: bash scripts/doc_gates.sh history-index
# ---------------------------------------------------------------------------
# GATE 91 — documentation/HISTORY_INDEX.md is a fresh output of scripts/history_index.sh
# (`history-index`). Q-686, 2026-09-26.
#
# WHY. documentation/HISTORY.md is append-only, and some of its sections were written after
# later-dated ones, so its file order is not date order everywhere. Measured 2026-09-26: three
# places, at the sections starting on lines 2666, 5643 and 9555. Moving them would break
# append-only, so HISTORY_INDEX.md lists the dated sections in date order instead. An index that
# is not regenerated when HISTORY.md grows is a second, quieter version of the same problem, so
# this gate fails until it is regenerated.
#
# WHAT IT RUNS. `scripts/history_index.sh --check` regenerates the index in memory and compares it
# byte for byte with the committed file (HISTORY_INDEX=CURRENT, else STALE, or ERROR when nothing
# could be compared). The script reads its ISO heading grammar out of
# scripts/history_currency_gate.sh, so the two cannot parse a heading differently; it ERRORs if it
# cannot find that grammar. Then `--selftest` runs the same check on mutated temporary copies (a
# section appended without regenerating, a row deleted, two rows swapped, the grammar removed, no
# headings, an out-of-order section) and each must give its stated verdict: a comparison that
# cannot see those edits would print CURRENT over any file.
#
# THIRD RUN (2026-09-26): `scripts/history_currency_gate.sh --selftest`. The index takes its ISO
# grammar from that script, so a change to the grammar changes this index; its self-test fixes
# what the grammar must and must not read (a symbol-led `## 🛑 <date>` heading yes, a word-led
# one no) and kills three mutants of it. HISTORY_CURRENCY_SELFTEST=PASS or this gate fails.
#
# GATE 4 (`links`) checks every anchor the index writes; this gate does not repeat that.
# ---------------------------------------------------------------------------
gate_history_index() {
  echo "== GATE 91: documentation/HISTORY_INDEX.md is a fresh output of scripts/history_index.sh =="
  # Q-952: each run is judged by require_pass_token (doc_gates.sh): rc 0, exactly one token, PASS.
  local out orc rc=0
  out=$(bash scripts/history_index.sh --check 2>&1); orc=$?
  printf '%s\n' "$out"
  require_pass_token HISTORY_INDEX CURRENT "$out" "$orc" || rc=1
  out=$(bash scripts/history_index.sh --selftest 2>&1); orc=$?
  printf '%s\n' "$out"
  require_pass_token HISTORY_INDEX_SELFTEST PASS "$out" "$orc" || rc=1
  out=$(bash scripts/history_currency_gate.sh --selftest 2>&1); orc=$?
  printf '%s\n' "$out"
  require_pass_token HISTORY_CURRENCY_SELFTEST PASS "$out" "$orc" || rc=1
  return $rc
}
