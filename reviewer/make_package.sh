#!/usr/bin/env bash
# reviewer/make_package.sh — bundle the ROAE reviewer package (reviewer/README.md) into one file.
#
# It copies exactly the package's input files into roae-reviewer-package-<VERSION>/, adds
# reviewer/MANIFEST.sha256 (the sha256 of every bundled file, required and checked by
# reviewer/selfcheck.sh before its first step) and reviewer/PACKAGE_VERSION (the version and the
# source commit), and writes a reproducible tar.gz: names sorted, owner and timestamps fixed,
# gzip -9 -n. The list of files is not kept here: it is PKG_FILES in reviewer/selfcheck.sh, read
# with `selfcheck.sh --files`, so the bundle and the self-check's manifest and scratch checks use
# one list. Run from a git checkout it records the commit, and refuses a file that git does not
# track; outside one it records "source: not a git checkout".
#
# It refuses while the page's "Measured times" table still says PENDING or re-measure: a package
# must not ship times nobody measured. It also refuses unless the bundled files are exactly a
# commit (no uncommitted changes, and a git checkout), so the version file names the bytes it
# ships. ROAE_PKG_DRAFT=1 lifts both refusals for the measurement run itself, and marks the version
# file DRAFT.
#
# Usage: bash reviewer/make_package.sh [OUTDIR]        (default: the current directory)
# Tokens: PACKAGE_FILE=<path> PACKAGE_BYTES=<n> PACKAGE_SHA256=<hex> PACKAGE_FILES=<n>
#         PACKAGE=OK|ERROR
#
# Developed with AI assistance (Claude, Anthropic).
set -uo pipefail

VERSION=v1

ORIG_PWD=$PWD
OUT=${1:-$ORIG_PWD}
case "$OUT" in /*) ;; *) OUT="$ORIG_PWD/$OUT" ;; esac
ROOT=$(cd "$(dirname "$0")/.." && pwd) || { echo "PACKAGE=ERROR"; exit 2; }
cd "$ROOT" || { echo "PACKAGE=ERROR"; exit 2; }
die(){ echo "  [ERROR] $*"; echo "PACKAGE=ERROR"; exit 2; }
# The list is read into a variable first: `mapfile < <(cmd)` succeeds whatever cmd exits with, so
# a --files run that crashed after printing part of the list would have bundled that part (the
# Q-951 class, batch 39).
FLIST=$(bash reviewer/selfcheck.sh --files) || die "reviewer/selfcheck.sh --files exited $?; no file list"
mapfile -t FILES <<<"$FLIST"
[ -n "$FLIST" ] || FILES=()
[ "${#FILES[@]}" -gt 0 ] || die "reviewer/selfcheck.sh --files printed no files"

if [ "${ROAE_PKG_DRAFT:-0}" != 1 ] && \
   grep -qiE 'PENDING|re-measure' <<<"$(sed -n '/<!-- TIMES:BEGIN -->/,/<!-- TIMES:END -->/p' reviewer/README.md)"; then
  die "reviewer/README.md's measured-times table still says PENDING or re-measure; run the measured run first"
fi

src="source: not a git checkout"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  for f in "${FILES[@]}"; do
    git ls-files --error-unmatch -- "$f" >/dev/null 2>&1 || die "$f is not tracked by git"
  done
  src="source: commit $(git rev-parse HEAD)"
  git diff --quiet HEAD -- "${FILES[@]}" 2>/dev/null || src="$src, with uncommitted changes to the bundled files"
fi
for f in "${FILES[@]}"; do [ -f "$f" ] || die "missing: $f"; done
# A release names exactly the source it was built from: a clean commit. (Codex PKG-V3 finding 11:
# "commit X, with uncommitted changes" does not identify the bundled bytes.) Drafts may say so.
if [ "${ROAE_PKG_DRAFT:-0}" != 1 ]; then
  case "$src" in
    *uncommitted*) die "the bundled files differ from commit $(git rev-parse HEAD); commit them first (or set ROAE_PKG_DRAFT=1 for a draft)" ;;
    "source: not a git checkout") die "not a git checkout, so no commit identifies the bundled files (set ROAE_PKG_DRAFT=1 for a draft)" ;;
  esac
fi

NAME="roae-reviewer-package-$VERSION"
ST=$(mktemp -d "${TMPDIR:-/tmp}/roae_pkg.XXXXXX") || die "no scratch"
trap '[ -n "${ST:-}" ] && [ -d "$ST" ] && rm -rf -- "$ST"' EXIT
for f in "${FILES[@]}"; do
  mkdir -p "$ST/$NAME/$(dirname "$f")" && cp -p "$f" "$ST/$NAME/$f" || die "copy failed: $f"
done
draft=""
[ "${ROAE_PKG_DRAFT:-0}" = 1 ] && draft=" (DRAFT: not a release; times or source may not be final)"
printf 'ROAE reviewer package %s%s\n%s\n' "$VERSION" "$draft" "$src" > "$ST/$NAME/reviewer/PACKAGE_VERSION"
(cd "$ST/$NAME" && printf '%s\n' "${FILES[@]}" reviewer/PACKAGE_VERSION | LC_ALL=C sort | xargs sha256sum) \
  > "$ST/$NAME/reviewer/MANIFEST.sha256" || die "manifest failed"

mkdir -p "$OUT" || die "cannot create $OUT"
TGZ="$OUT/$NAME.tar.gz"
(cd "$ST" && tar --sort=name --mtime='2026-10-01 00:00:00Z' --owner=0 --group=0 --numeric-owner \
     -cf - "$NAME") | gzip -9 -n > "$TGZ" || die "tar/gzip failed"
echo "  $(sed -n 1p "$ST/$NAME/reviewer/PACKAGE_VERSION")"
echo "  $(sed -n 2p "$ST/$NAME/reviewer/PACKAGE_VERSION")"
echo "PACKAGE_FILE=$TGZ"
echo "PACKAGE_BYTES=$(stat -c %s "$TGZ")"
echo "PACKAGE_SHA256=$(sha256sum "$TGZ" | cut -d' ' -f1)"
echo "PACKAGE_FILES=$(( ${#FILES[@]} + 2 ))"
echo "PACKAGE=OK"
