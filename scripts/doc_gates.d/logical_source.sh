#!/usr/bin/env bash
# logical_source.sh — print scripts/doc_gates.sh as ONE file: its LOGICAL SOURCE.
#
# WHY (Q-797, 2026-09-25). doc_gates.sh passed 1 MB, so its gate functions were moved into the
# sourced modules next to this file. Several gates, and most of the --selftest fire-proofs, read
# doc_gates.sh's OWN TEXT: GATE 15 and GATE 16 parse the --selftest region, the dispatch and every
# gate body; GATE 47 counts its registered phrases per file; GATE 83 matches usage, dispatch and
# gate functions; GATE 89 reads its verdict tokens; and the GATE 15/16/17 fire-proofs mutate a
# copy of it. After the split, a read of the entry file alone would see a fraction of the suite
# and report smaller, still-plausible numbers. That is a false clear, not an error.
#
# WHAT IT PRINTS. The entry file with every `# DG-MODULE` line replaced by the module it sources,
# and every line that starts with `#@` (split commentary) dropped. The split keeps every edit to
# the pre-split text on its own line, so the result has the pre-split file's line count and line
# numbering: a `scripts/doc_gates.sh:N` that a gate prints is line N of this output.
#
# A MODULE THAT CANNOT BE READ, OR READS AS EMPTY, IS AN ERROR (exit 2, message on stderr). A
# partial logical source would let every reader above count less and still pass.
#
# Not sourced by anything. Run it: bash scripts/doc_gates.d/logical_source.sh
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 2
LC_ALL=C awk '
  /^#@/ { next }
  / # DG-MODULE$/ {
    f = $2; n = 0
    while ((r = (getline l < f)) > 0) { if (l !~ /^#@/) { print l; n++ } }
    if (r < 0 || n == 0) { printf "logical_source.sh: cannot read module %s\n", f > "/dev/stderr"; exit 2 }
    close(f); next
  }
  { print }' scripts/doc_gates.sh
