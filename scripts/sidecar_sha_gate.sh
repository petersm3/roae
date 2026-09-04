#!/usr/bin/env bash
# sidecar_sha_gate.sh — Q-324. Every solutions.sha256 writer must record the LOGICAL sha.
#
# WHY. Until 2026-08-28 solve.c had TWO sidecar writers that disagreed. The enumeration path used
# write_sha256_with_metadata() -> sha256_of_logical(), which decompresses by magic and hashes the
# canonical byte stream. The standalone --merge path ran, via system():
#
#     sha256sum <outname> > solutions.sha256
#
# which hashes the file AS IT SITS ON DISK. Since #169 the default framing is gz, so on every
# gz-framed merge the sidecar held the sha of the COMPRESSED CONTAINER. Measured that day by
# running the binary on two shard fixtures: 13,320 records, sidecar `2d6411e6...` = the container,
# while the same bytes hash to `6ce4eea1...` under `gzip -dc | sha256sum`. solutions.meta.json
# inherited the same wrong value, because it is parsed back out of the sidecar.
#
# Two public documents promised the logical value outright (SOLUTIONS_FORMAT.md "File integrity",
# CANONICAL_HASHES.md "the solutions.sha256 sidecar already holds the logical sha"). Both were
# false for anything that path produced.
#
# 🔴 WHY IT MATTERS MORE THAN A WRONG FIELD. gzip framing is NOT canonical content: it varies with
# zlib version and compression level. A container sha therefore false-mismatches an artifact that is
# byte-identical where it counts. That direction manufactures PHANTOM DRIFT, and this project has
# already spent real time bisecting drift that turned out to be host-level rather than content-level.
#
# LEG 1 (always runs, source-level). No sidecar may be written by shelling out to a sha tool: every
# writer must route through sha256_of_logical(). This is the regression that actually happened, it
# is checkable on any clone with no artifacts present, and it is what a future edit would trip.
#
# LEG 2 (conditional, artifact-level). Where a solutions.bin + solutions.sha256 pair exists, the
# sidecar's first field must equal an INDEPENDENTLY computed logical sha — coreutils `gzip -dc |
# sha256sum`, never solve.c's own helper, or the gate would be checking the implementation against
# itself. Artifacts are untracked, so a fresh clone has none; LEG 2 then says plainly that it
# checked nothing rather than reporting clean.
#
# Emits SIDECAR_SHA_GATE=OK|FAIL. Gate with `grep -qx`, never on output shape.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1
rc=0

echo "== LEG 1: no sidecar is written by shelling out to a sha tool =="
if [ ! -r solve.c ]; then
  echo "  [FAIL] solve.c is missing or unreadable — NOTHING was checked."
  echo "SIDECAR_SHA_GATE=FAIL"; exit 1
fi
# A sha tool invoked with redirection into a .sha256 target is the exact shape of the defect.
# 🔴 COMMENT LINES ARE EXCLUDED, and that is not a convenience. The first run of this gate went
# red on the very comment that DOCUMENTS the defect it forbids — the fix's own explanation quotes
# `sha256sum <outname> > solutions.sha256` verbatim. A gate that cannot tell code from prose about
# code punishes writing the explanation down, which is the one habit this repo most depends on.
# Same class as the ledger proof satisfied by a sentence quoting its own token (Q-278).
hits=$(grep -vE '^[[:space:]]*(\*|/\*|//)' solve.c | grep -nE '"%s %s > %s|sha256sum[^"]*>[^"]*sha256' \
       | grep -viE 'sha256_of_logical' || true)
if [ -n "$hits" ]; then
  printf '%s\n' "$hits" | sed 's/^/  [FAIL] /'
  echo "         A sidecar written from the on-disk file records the gz CONTAINER sha."
  echo "         Route it through sha256_of_logical(), as write_sha256_with_metadata() does."
  rc=1
else
  n=$(grep -c 'sha256_of_logical(' solve.c)
  echo "  [ok] no shell-invoked sha redirection into a sidecar; $n call(s) to sha256_of_logical()"
fi

echo "== LEG 2: where an artifact exists, its sidecar equals the INDEPENDENT logical sha =="
checked=0
for bin in solutions.bin ${SIDECAR_EXTRA_BINS:-}; do
  side="${bin%.bin}.sha256"
  [ -f "$bin" ] && [ -f "$side" ] || continue
  checked=$((checked+1))
  want=$(if [ "$(head -c2 "$bin" | xxd -p)" = "1f8b" ]; then gzip -dc "$bin" | sha256sum; else sha256sum "$bin"; fi | cut -d' ' -f1)
  got=$(head -1 "$side" | awk '{print $1}')
  if [ "$want" = "$got" ]; then
    echo "  [ok] $side matches the independent logical sha (${got:0:12}…)"
  else
    echo "  [FAIL] $side records ${got:0:12}… but the logical sha is ${want:0:12}…"
    echo "         If ${got:0:12}… equals \`sha256sum $bin\`, this is the container-sha defect."
    rc=1
  fi
done
[ "$checked" -eq 0 ] && echo "  [none] no solutions.bin/.sha256 pair present — LEG 2 CHECKED NOTHING (artifacts are untracked)"

[ "$rc" -eq 0 ] && { echo "SIDECAR_SHA_GATE=OK"; exit 0; }
echo "SIDECAR_SHA_GATE=FAIL"; exit 1
