#@ scripts/doc_gates.d/99_retract_derived.sh -- sourced by scripts/doc_gates.sh; not runnable on its own.
#@ GATE 94 (ADVISORY, REPORT-ONLY): withdrawn phrasings quoted in CORRECTIONS.md that the hand-kept
#@ registry does not name. Run it through the entry: bash scripts/doc_gates.sh retract-derived
# ---------------------------------------------------------------------------
# GATE 94 — derived withdrawn-phrase candidates (`retract-derived`). Q-884 GAP-1, 2026-10-01.
#
# WHY. GATE 3 enforces withdrawn phrasings only against documentation/RETRACTED_PHRASES.tsv, and
# registration is by hand, so a phrase withdrawn in a CORRECTIONS.md entry but never registered is
# checked by nothing (Fable E4 Part 2, GAP-1). This leg DERIVES the candidates: every quoted string of
# 14 to 240 characters that follows "read", "said", "was", "stated", "claimed", "named" or "printed"
# (optionally with a colon) in CORRECTIONS.md, the ledger's own "this read ..." / "was ..." forms.
# A candidate counts as REGISTERED when, after folding case, whitespace, `**` and backticks, a
# registry needle is a substring of it or it is a substring of a needle, or its sha256 equals a
# digest-registered needle's.
#
# ADVISORY, NOT BLOCKING, AND THAT IS DELIBERATE. The 09-24 hand pass of this method found most
# survivors to be narration or the corrected wording itself, so a blocking leg would need a waiver
# convention that does not exist yet. The leg prints, and it never changes doc_gates' exit status.
# Receipts: RETRACT_DERIVED_CANDIDATES=N (quotes extracted), RETRACT_DERIVED_LIVE=M (unregistered
# candidates still present in a tracked .md outside the ledgers), and the verdict line
#   RETRACT_DERIVED=PASS            every candidate is registered
#   RETRACT_DERIVED=ADVISORY n=<k>  k candidates are not registered (listed, with their ledger line)
#   RETRACT_DERIVED=UNMEASURED      an input could not be read (a [WARN] says which)
# A candidate population below the floor (40, against 66 measured 2026-10-01) prints a [WARN]: a
# collapsed extraction is a broken scan, not a clean ledger. The floor binds the real ledger only.
# Fixture overrides for tests.py: DOC_GATE_RD_CORR (the ledger), DOC_GATE_RD_REG (the registry),
# DOC_GATE_RD_CORPUS (a directory whose *.md files are the live corpus; default: git ls-files).
# ---------------------------------------------------------------------------
gate_retract_derived() {
  echo "== GATE 94 (ADVISORY): withdrawn phrasings quoted in CORRECTIONS.md but not registered =="
  DOC_GATE_RD_CORR="${DOC_GATE_RD_CORR:-}" DOC_GATE_RD_REG="${DOC_GATE_RD_REG:-}" \
  DOC_GATE_RD_CORPUS="${DOC_GATE_RD_CORPUS:-}" python3 - <<'RD_PY'
import hashlib, os, re, subprocess, sys
corr = os.environ.get("DOC_GATE_RD_CORR") or "documentation/CORRECTIONS.md"
reg = os.environ.get("DOC_GATE_RD_REG") or "documentation/RETRACTED_PHRASES.tsv"
corpus_dir = os.environ.get("DOC_GATE_RD_CORPUS") or ""
real = not os.environ.get("DOC_GATE_RD_CORR")
FLOOR = 40
LEDGERS = {"documentation/CORRECTIONS.md", "documentation/HISTORY.md", "documentation/HISTORY_INDEX.md"}
PAT = re.compile(r'\b(?:read|reads|said|says|was|were|stated|claimed|named|printed)\s*:?\s*["“]([^"”\n]{14,240})["”]')
def norm(s):
    return re.sub(r"\s+", " ", s.replace("**", "").replace("`", "")).strip().lower()
try:
    lines = open(corr, encoding="utf-8").read().splitlines()
    needles, digests = [], set()
    for ln in open(reg, encoding="utf-8"):
        if ln.startswith("#") or not ln.strip():
            continue
        n = ln.rstrip("\n").split("\t")[0]
        if n.startswith("sha256:"):
            digests.add(n[7:].split("/")[0])
        elif norm(n):
            needles.append(norm(n))
except OSError as e:
    print("  [WARN] could not read an input (%s) -- nothing was derived" % e)
    print("RETRACT_DERIVED=UNMEASURED")
    sys.exit(0)
cands = {}
for i, ln in enumerate(lines, 1):
    for m in PAT.finditer(ln):
        cands.setdefault(m.group(1), i)
unreg = []
for c, i in cands.items():
    n = norm(c)
    if any(r in n or n in r for r in needles):
        continue
    if hashlib.sha256(c.encode("utf-8")).hexdigest() in digests:
        continue
    unreg.append((i, c))
if corpus_dir:
    files = [os.path.join(dp, f) for dp, _, fs in os.walk(corpus_dir) for f in fs if f.endswith(".md")]
else:
    r = subprocess.run(["git", "ls-files", "-z", "*.md"], capture_output=True)
    files = [f for f in r.stdout.decode("utf-8", "replace").split("\0") if f and f not in LEDGERS]
blob = {}
for f in files:
    try:
        blob[f] = norm(open(f, encoding="utf-8", errors="replace").read())
    except OSError:
        pass
live = 0
print("RETRACT_DERIVED_CANDIDATES=%d" % len(cands))
if real and len(cands) < FLOOR:
    print("  [WARN] only %d candidate quote(s) extracted from %s, below the floor %d -- a collapsed"
          " extraction is a broken scan, not a clean ledger" % (len(cands), corr, FLOOR))
for i, c in unreg:
    where = [f for f, t in blob.items() if norm(c) in t]
    if where:
        live += 1
    print("  [note] %s:%d unregistered: \"%s\"%s" % (corr, i, c[:120],
          ("  -- LIVE in " + ", ".join(sorted(where)[:3])) if where else ""))
print("RETRACT_DERIVED_LIVE=%d" % live)
print("RETRACT_DERIVED=PASS" if not unreg else "RETRACT_DERIVED=ADVISORY n=%d" % len(unreg))
sys.exit(0)
RD_PY
  return 0
}
