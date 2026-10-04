#@ scripts/doc_gates.d/96_transcripts.sh -- sourced by scripts/doc_gates.sh; not runnable on its own.
#@ GATE 95: every shell transcript in a tracked *.md outside example/ is registered and classified.
#@ Run it through the entry: bash scripts/doc_gates.sh transcripts
# ---------------------------------------------------------------------------
# GATE 95 — transcripts outside example/ are registered (`transcripts`). Review-loop item Q29,
# leg I, 2026-10-02.
#
# WHY. GATE 8 compares command output byte for byte, but only for example/. A transcript elsewhere
# (a `$ ` prompt line followed by output, inside a fenced block) states what a command printed,
# and nothing classified or re-derived those blocks: GATE 25 checks that a documented flag exists,
# not what the command prints, and GATE 92 covers CLAIMS.tsv rows only. Measured 2026-10-02: five
# such blocks, three in documentation/CORRECTIONS.md and two in documentation/HISTORY.md.
#
# WHAT COUNTS AS A TRANSCRIPT. A fenced block -- as the shared normaliser (doc_gates.d/md_normalise.sh)
# delimits it: opened by ``` or ~~~ (3 or more), closed only by the same character at the same or a
# greater length, so a ``` line inside a ```` block is content (Q-965, A03#11; it used to close the
# block by parity) -- in a `git ls-files '*.md'` file outside example/, with a line
# matching `^\s*\$ \S` (the prompt) followed by at least one output line. After a prompt, a line
# that follows a line ending in `\`, or that starts with `|`, `&&` or `||`, is part of the command;
# a blank line or a `#` comment is not output. A block with prompts and no output is a recipe, not
# a transcript, and is not counted. Command-plus-output blocks with no `$ ` prompt (mostly CLI
# sample outputs) are OUT OF SCOPE: a looser detector finds about 47 of them, mainly recipes, and
# a gate whose findings are mostly noise gets ignored.
#
# THE REGISTRY, documentation/DOC_GATE_TRANSCRIPTS.tsv. Tab-separated `file cmd_sha12 class
# evidence`; `#` lines and blank lines are ignored. The key is (file, the first 12 hex digits of
# sha256 of the block's first prompt line, stripped), so a row does not move when lines above the
# block are added. `class` is one of:
#   historical   `evidence` is the ISO date (YYYY-MM-DD) the transcript was taken. The default for
#                the append-only ledgers, whose text records what ran then and is never reworded.
#   pinned-tree  the paragraph just before the fence names a commit (a 8-40 digit lowercase hex
#                word with at least one a-f letter, so an 8-digit date does not count) or a tag
#                that `git tag -l` lists. `evidence` is free text.
#   rerun        `evidence` names what re-derives the output: a tests.py class (`TestName`) that
#                exists in tests.py, or a tracked scripts/ path.
#
# IT FAILS when a fence is UNCLOSED (Q-965: its content runs to end of file as rendered, and a block
# this gate cannot delimit is one it cannot certify; it was silently not a block before), when a
# block is unregistered, when a registry row matches no block (an orphan; this is
# also how a row whose file is gone shows up), when a row is malformed or repeated, when a class is
# unknown, when a row's evidence does not satisfy its class, when the registry cannot be read, and
# when the population is 0 (a scan that finds nothing is a broken scan, not a clean tree).
# VERDICT (whole lines, read with `grep -qx`): TRANSCRIPTS_N=<k> (blocks found), then
# TRANSCRIPTS_GATE=PASS or TRANSCRIPTS_GATE=FAIL.
#
# WHAT IT DOES NOT DO. It does not re-run any transcript; a registered `historical` block can
# disagree with today's code and stay green, which is what append-only text is for. The opt-in
# re-run leg the review spec describes is not built.
# Fixture overrides for tests.py: DOC_GATE_TR_REG (the registry) and DOC_GATE_TR_CORPUS (a
# directory whose *.md files, by path relative to it, replace `git ls-files`).
# ---------------------------------------------------------------------------
gate_transcripts() {
  echo "== GATE 95: transcripts outside example/ are registered in documentation/DOC_GATE_TRANSCRIPTS.tsv =="
  local out orc
  out=$( { _md_norm_prelude; cat <<'TR_PY'
import hashlib, os, re, subprocess, sys
reg = os.environ.get("DOC_GATE_TR_REG") or "documentation/DOC_GATE_TRANSCRIPTS.tsv"
corpus = os.environ.get("DOC_GATE_TR_CORPUS") or ""
PROMPT = re.compile(r"^\s*\$ \S")
SHA = re.compile(r"\b(?=[0-9a-f]*[a-f])[0-9a-f]{8,40}\b")
DATE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
fail = []
if corpus:
    files = sorted(os.path.relpath(os.path.join(dp, f), corpus)
                   for dp, _, fs in os.walk(corpus) for f in fs if f.endswith(".md"))
    base = corpus
else:
    r = subprocess.run(["git", "ls-files", "-z", "*.md"], capture_output=True)
    files = sorted(f for f in r.stdout.decode("utf-8", "replace").split("\0") if f)
    base = "."
files = [f for f in files if not f.startswith("example/")]
blocks = {}   # (file, sha12) -> (line, preceding paragraph)
for f in files:
    try:
        L, _kind, _blocks, _unc = md_parse(md_read(os.path.join(base, f)))
    except OSError:
        continue
    for u in _unc:
        fail.append("%s:%d a code fence opens here and never closes, so its content to end of file "
                    "cannot be delimited as a block and was NOT checked" % (f, u))
    for _b in _blocks:
        if _b["kind"] != "code":
            continue
        start, blk = _b["start"], [x for _, x in _b["lines"]]
        out, cont, seen, first = 0, False, False, None
        for x in blk:
            if PROMPT.match(x):
                seen = True
                cont = x.rstrip().endswith("\\")
                first = first or x.strip()
                continue
            if not seen:
                continue
            if cont or x.lstrip().startswith(("|", "&&", "||")):
                cont = x.rstrip().endswith("\\")
                continue
            cont = False
            if x.strip() and not x.lstrip().startswith("#"):
                out += 1
        if seen and out:
            k = (f, hashlib.sha256(first.encode("utf-8")).hexdigest()[:12])
            j = start - 2
            while j >= 0 and not L[j].strip():
                j -= 1
            para = []
            while j >= 0 and L[j].strip() and not L[j].lstrip().startswith("```"):
                para.insert(0, L[j])
                j -= 1
            if k in blocks:
                fail.append("%s:%d repeats the first prompt line of the block at line %d, so the "
                            "two cannot be told apart by key" % (f, start, blocks[k][0]))
            blocks[k] = (start, "\n".join(para))
print("TRANSCRIPTS_N=%d" % len(blocks))
rows = {}
try:
    tags = set()
    if not corpus:
        tags = set(subprocess.run(["git", "tag", "-l"], capture_output=True, text=True).stdout.split())
    tests_src = open("tests.py", encoding="utf-8").read() if os.path.exists("tests.py") else ""
    for n, ln in enumerate(open(reg, encoding="utf-8"), 1):
        ln = ln.rstrip("\n")
        if not ln.strip() or ln.startswith("#"):
            continue
        c = ln.split("\t")
        if len(c) != 4 or not all(x.strip() for x in c):
            fail.append("%s:%d malformed row (need 4 non-empty tab-separated cells): %r" % (reg, n, ln[:120]))
            continue
        f, sha, cls, ev = c
        if (f, sha) in rows:
            fail.append("%s:%d repeats the row for %s %s" % (reg, n, f, sha))
            continue
        rows[(f, sha)] = (n, cls, ev)
except OSError as e:
    fail.append("the registry could not be read (%s)" % e)
for k, (line, para) in sorted(blocks.items(), key=lambda kv: (kv[0][0], kv[1][0])):
    if k not in rows:
        fail.append("%s:%d unregistered transcript, cmd_sha12=%s" % (k[0], line, k[1]))
        continue
    n, cls, ev = rows[k]
    if cls == "historical":
        if not DATE.match(ev):
            fail.append("%s:%d class historical needs an ISO date as evidence, got %r" % (reg, n, ev))
    elif cls == "pinned-tree":
        words = set(re.findall(r"[A-Za-z0-9._/-]+", para))
        if not SHA.search(para) and not (words & tags):
            fail.append("%s:%d class pinned-tree, but the paragraph before %s:%d names no commit or tag"
                        % (reg, n, k[0], line))
    elif cls == "rerun":
        ok = False
        if re.fullmatch(r"Test[A-Za-z0-9_]+", ev):
            ok = re.search(r"^class %s\(" % re.escape(ev), tests_src, re.M) is not None
        elif ev.startswith("scripts/"):
            ok = os.path.isfile(ev)
        if not ok:
            fail.append("%s:%d class rerun, but its evidence %r is not a tests.py class or a scripts/ path"
                        " that exists" % (reg, n, ev))
    else:
        fail.append("%s:%d unknown class %r (historical | pinned-tree | rerun)" % (reg, n, cls))
    print("  [ok]   %s:%d %s %s (%s)" % (k[0], line, k[1], cls, ev))
for k, (n, cls, ev) in sorted(rows.items(), key=lambda kv: kv[1][0]):
    if k not in blocks:
        fail.append("%s:%d orphan row: no transcript in %s has cmd_sha12=%s" % (reg, n, k[0], k[1]))
if not blocks:
    fail.append("no transcript found: a scan that finds nothing is a broken scan, not a clean tree")
for m in fail:
    print("  [FAIL] " + m)
print("TRANSCRIPTS_GATE=%s" % ("FAIL" if fail else "PASS"))
TR_PY
} | DOC_GATE_TR_REG="${DOC_GATE_TR_REG:-}" DOC_GATE_TR_CORPUS="${DOC_GATE_TR_CORPUS:-}" python3 - 2>&1 ); orc=$?
  printf '%s\n' "$out"
  # The verdict line AND python's exit status decide (Q-952): a scan that printed PASS and then
  # crashed, or printed a second, conflicting verdict, is not a PASS. require_pass_token: doc_gates.sh.
  require_pass_token TRANSCRIPTS_GATE PASS "$out" "$orc"
}
