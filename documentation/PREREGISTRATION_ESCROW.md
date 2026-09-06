# Pre-registration escrow — sha256 of the frozen pre-registration files

**Published 2026-08-22 (operator decision, Q28 option (b)). Amended 2026-09-02 — see
§"Amendment log".**

> **Every published value on this page is append-only.** The ten hashes, byte counts and dates below
> are exactly as published on 2026-08-22 and have never been edited; `git log --follow` on this file
> shows one commit before the amendment. An escrow page that can be revised invisibly is not an
> escrow page, so every change to it is dated and itemized at the foot of this page, and no
> previously published hash, byte count or date is ever altered or removed — only annotated.

## What this is, and what it is not

The ROAE project pre-registers a test **before** its result is computed: the observable, the family
size, and the decision rule are fixed in a file, and that file is frozen. Until now, the claim that a
pre-registration was frozen *before* the measurement rested on **operator attestation** — the files
live in a private repository and an outside reader had to take our word for the timing. For the ten
files listed here **it still does**, for the reason given two paragraphs below; what this page adds
for them is a check on their *content*, and a mechanism that will convert freeze timing for
pre-registrations escrowed from now on.

This page publishes the sha256 of **ten** frozen pre-registration files. It does not publish the
files, and — corrected 2026-09-02 — **ten is a selected subset, not the whole population.** At least
six further frozen pre-registrations are named in the shipped `solve.c`, `solve.py` and evidence
bundles and are **not escrowed here**; they are itemized in §"Pre-registrations that are NOT escrowed
here" below, so that a reader auditing the 91-observable Bonferroni ledger in
[METHODS.md](../reports/METHODS.md) §"Global observable ledger" can see which of its families have a
hash on this page and which do not.

**What it establishes:** if any of these files is later disclosed, anyone can hash it and check it
against the value below. A file whose hash matches was **byte-identical on 2026-08-22**. That
converts **content identity from 2026-08-22 onward** from *attested* to *checkable*.

**What it does not establish, and for this table cannot — corrected 2026-09-02.** Escrow converts
freeze *timing* only when the hash is published **before** the measurement runs. **Not one row below
is of that kind.** Every one of the ten was first committed between 2026-07-17 and 2026-08-18 — the
date column says so, and every date in it precedes this page's 2026-08-22 publication. For several,
the result was already recorded by then, and for one it was already public in this repository:
[`reports/evidence/f11halfb/RESULTS.md`](../reports/evidence/f11halfb/RESULTS.md) §"EXTENSION RESULT
— n=1000 estimation" carries the completed Half-B extension run, committed **2026-08-04**, eighteen
days before this page existed. So **pre-measurement freeze timing remains *attested*, not checkable,
for all ten rows**, exactly as the bullet below beginning "It does not prove a file was frozen"
says; the sentence above buys content identity and nothing more. For any *future* pre-registration, publishing its hash here before the run does
convert freeze timing to checkable — that is what this page is for going forward, and it is a promise
about future rows, not a description of the present ten.

**What it does NOT establish:**
- ❌ It does not prove the content is *correct*, only that it has not changed.
- ❌ It does not prove a file was frozen before some *earlier* date — only that this is its state as
  published here.
- ❌ It discloses **nothing** about the contents. A hash is not a summary.
- ⚠ The "first committed" dates come from the **private** repository's history, which is itself
  operator-held and not publicly auditable. **They are a claim, not a proof** — the sha256 is the
  part a reader can check independently. Do not read the date column as escrowed.
- ⚠ For three of the ten rows the escrowed hash is **not** the file's state at its freeze commit —
  the file was amended afterwards, in two cases after the result was recorded. The date column and
  the hash column therefore describe **different versions** of those three files. This was not
  disclosed on 2026-08-22 and is corrected in §"The escrowed hash is the file's state on 2026-08-22,
  not necessarily its state at the freeze".

## The hashes

| file | sha256 | bytes | first committed (private) |
|---|---|--:|---|
| `PREREG_F_CATALOG_T1_T4_2026_08_06.md` | `f5ee78bc6b477843ddbfa1b8b236ae20b935744edbd37d04b1dd39647d106f7d` | 15,019 | 2026-08-06 |
| `PREREG_F_CATALOG_T1_T9_2026_08_06.md` | `8dd2290995043eda417533dfb95c8b325a341018eaa464184573cfc84fa008b8` | 11,596 | 2026-08-06 |
| `PREREG_H1_H3_TEST_2026_07_26.md` | `ab09648ce5adc8bcd86255e23fc8eb58004730e7a2998b69469df130c7da3687` | 29,896 | 2026-07-28 |
| `PREREG_HALFB_EXTENDED_2026_08_03.md` | `09d711c344ec673252ee2e7d451815a9455bb504814190bcd982855a86b6db94` | 3,965 | 2026-08-03 |
| `PREREG_KNUTH_CLEANROOM_2026_08_08.md` | `e4d4720f29255b335fe10a79dfe3b383d802a70e7ec6ae9bee5811c3283d2571` | 7,117 | 2026-08-08 |
| `PREREG_P3_SEEDS_2026_08_11_FROZEN.md` | `64deb88fbecebdd89e477740d38f01fd3dda0e5812532be3c4e1c3b76e977f03` | 5,984 | 2026-08-12 |
| `PREREG_REPR_COST_VS_T_2026_08_18.md` | `d1c64db72140f672a08e1a4d64285f1e2b8abcbd34798d07ea6b63abddcd42fb` | 8,359 | 2026-08-18 |
| `PREREG_SAMPLING_CAMPAIGN_2026_07_17.md` | `a7d34ca6c34dd3937c4de2f4dd1d089c8eb9172605deb0b190cc2683c92b84c3` | 3,672 | 2026-07-17 |
| `PREREG_TR8_DOF_MATCHED_SAMPLER_20260811.md` | `4b307f07767199b746e770cfa595a3153519a57cdc2043843d9019f71683d2f5` | 66,659 | 2026-08-11 |
| `PREREG_VMATCHED_GATE_2026_08_04.md` | `37ee9eee6dfd57c7e47985b00ab005ebd8f58e6e1b16df43db55f591b6ef4d82` | 5,336 | 2026-08-04 |

Verify any disclosed file with:

```bash
sha256sum <file>          # compare to the table above
```

## ⚠ One published pre-registration is NOT YET FROZEN, and its digest is here in prose for that reason

**`PREREG_CLASSA_QUERY_SET.md` — digest `2f592d2e084e75b098501bd5a0ece173f1dcdf5ead52144f74adc89eb2407b03`, 48,948 bytes,
published 2026-09-06; digest updated 2026-09-06 after a FIFTH revision — an internal clarification,
not an external finding.**

*(Digest history: `6e21a148bfbb1ad57f7770f75cfdfd21f4f5c606258adec55231bc3066bfe2d9`, 41,881 bytes → `6b83cf4e0652dfe472e37c58f0cda4831a0300260cb8862e499b8a3ceb6f5dcb`, 45,882 bytes, when the QSET-3 pass's eight findings were applied → `fc0e40a6eac1c2ee9f159e599be02a8c69b42bc66fbf4f777cb801702230aca7`, 47,066 bytes, when QSET-4's four findings were applied. **QSET-4 attacked the QSET-3 repairs rather than the document**, and upheld all four: two of the eight repairs had been recorded as applied and were not, two left the corrected phrasing standing at a second site. Its adjudication then found three more the reviewer had missed, including an overclaim the QSET-3 repair itself introduced — that a 10-free-pair cell is a "sub-minute" brute force, disproved by executing it (475 s). This is the digest changing exactly as this entry said it would, which is why the entry exists: an escrow row that could not move would have had to be wrong here. → `2f592d2e084e75b098501bd5a0ece173f1dcdf5ead52144f74adc89eb2407b03`, 48,948 bytes. The first three supersessions were accepted EXTERNAL findings; the fourth is not — it is an internal clarification separating "needs the atlas file" from "is expensive" in the dependency table, which are different claims and were being read as one. The distinction is recorded because "caused by an external finding" was the original framing of this line and it would now be false for the latest entry.)*

**This digest is deliberately NOT in the table above, and it does not verify against an escrowed
row, because the file it describes is not frozen.** It was published *before* its freeze so that an
external reviewer could attack it while corrections are still possible — the adjacent query
specification had two external reviews return eighteen findings with none rejected, three of them
questions this repository had already answered, and every one of those had been cleared by an
internal reader first.

**What that means for a reader, stated exactly:**

- **The digest above will change**, and is expected to, if the review lands anything. Hash the file
  today and you learn what is public today — nothing more. It is a *state marker*, not an
  attestation.
- **The freeze is the third-party timestamp**, not the publication commit. When it lands, the file
  gets a real escrowed row in the table above, and *that* digest is the one that binds.
- **This entry exists because a published pre-registration whose digest is unpublished is one a
  reader can hash and learn nothing from.** That is this repository's own rule, enforced by a gate,
  and it is the gate that caught the omission when the file was first published — the disclosure is
  here because the check failed, not because anyone remembered.

*Added 2026-09-06.*

---

## The escrowed hash is the file's state on 2026-08-22, not necessarily its state at the freeze

Added 2026-09-02. Seven of the ten rows have a single commit in the private history: for those, the
escrowed hash **is** the file as first frozen. **Three do not.** Those three were amended after their
first commit, and the table above pairs the *first-committed* date with the *amended* hash — so a
reader who later obtains a disclosed file, finds it matches, and concludes "this is what was frozen
on the date in the table" would be wrong for these three. The freeze-state digests are published here
so that both states are checkable:

| file | first committed | sha256 **at the freeze commit** | bytes | what the later amendment did |
|---|---|---|--:|---|
| `PREREG_F_CATALOG_T1_T4_2026_08_06.md` | 2026-08-06 | `0e16a457885154b609517d310605666cd3a448d3d99c89445a3b203737466086` | 13,479 | same-day dated annotations (probe-seed offsets; a T3 truncation with a measured rate), recorded in the private commit message as made **before the first recorded T3 draw** — pre-measurement, but not the frozen bytes |
| `PREREG_KNUTH_CLEANROOM_2026_08_08.md` | 2026-08-08 | `c99c12dbb954437660ec084c5b00c96047f748bed0a767aad5317fe86ba37d52` | 4,254 | a **2026-08-09** commit appended the gate's **result**. The escrowed 7,117-byte digest is therefore of a document that contains its own outcome; the 4,254-byte digest is the pre-registration as frozen before the prober was written |
| `PREREG_REPR_COST_VS_T_2026_08_18.md` | 2026-08-18 | `73f3ae55dda849ddca98e31b13f36eb7944000a09919ef88e5890bb7db7cf4ff` | 5,298 | a same-day gating change, then a **2026-08-19** commit appending metrics and conclusions. As above, the escrowed 8,359-byte digest is post-result; the 5,298-byte digest is the state frozen before the correlation was computed |

The other seven — `PREREG_F_CATALOG_T1_T9_2026_08_06.md`, `PREREG_H1_H3_TEST_2026_07_26.md`,
`PREREG_HALFB_EXTENDED_2026_08_03.md`, `PREREG_P3_SEEDS_2026_08_11_FROZEN.md`,
`PREREG_SAMPLING_CAMPAIGN_2026_07_17.md`, `PREREG_TR8_DOF_MATCHED_SAMPLER_20260811.md` and
`PREREG_VMATCHED_GATE_2026_08_04.md` — have one commit each, so for them the escrowed hash and the
freeze-state hash are the same value.

These freeze-state digests carry **the same caveat as the date column**: they are derived from the
operator-held private history and are a claim, not a proof. What a reader gains is that a disclosed
file can now be checked against *either* state, and that the two states are no longer conflated.

## Pre-registrations that are NOT escrowed here

Added 2026-09-02, correcting the earlier claim that this page escrowed every frozen file. The
following frozen pre-registrations are named in the shipped code and evidence bundles and have **no
row above**. Each is described in public source as fixed before measurement, with a Bonferroni
denominator attached, and each feeds the observable ledger in
[METHODS.md](../reports/METHODS.md) §"Global observable ledger":

| file (in `roae-private`) | named at | frozen, per the public source | family size |
|---|---|---|--:|
| `F4PRIME_PREREGISTRATION.md` | `solve.c`, `solve.py` | 2026-07-04, "axes and look-elsewhere gates fixed BEFORE any population measurement" | 13 |
| `F5_ORIENTATION_PREREGISTRATION_2026_07_FROZEN.md` | `solve.c`, `reports/evidence/f5/f5_ground_truth.py`, `reports/evidence/f5/f5_modec_fiber.py` | 2026-07-05, "BEFORE any population measurement" | 11 |
| `F6_BOOKS_PREREGISTRATION_2026_07_FROZEN.md` | `solve.c`, `solve.py` | 2026-07-05, "before any population measurement" | 7 |
| `R3_PERMUTATION_OBSERVABLE_PREREG_2026_07_09.md` | `solve.c`, `solve.py` | 2026-07-09, "before any C1–C5 population measurement" | 13 |
| `R8_DAVIS_PREREG_2026_07_10.md` | `solve.c`, `solve.py`, `documentation/SOLVE_C_CLI.md` | 2026-07-10, "BEFORE any population measurement" | 2 (§3.1/§3.2) |
| `F11_BAYES_PREREGISTRATION_2026_07.md` | `reports/evidence/f11/f11_events.py` | "Model (frozen, …)" | — |

Two further names appear in the public tree and are **not** frozen pre-registrations of this kind, so
they are listed for completeness rather than as omissions: `F5_ORIENTATION_PREREGISTRATION_DRAFT.md`
(a draft superseded by the FROZEN file above, cited once in a `solve.py` docstring for its addendum),
and `PREREG_TWO_CLASS_F11_CALIBRATION.md`, named as "the frozen pre-registration" at
[`reports/evidence/f11halfb/RESULTS.md`](../reports/evidence/f11halfb/RESULTS.md) — **no file of that
name exists in the private repository today**, so that citation is unresolved and is recorded as such
rather than escrowed. Adding hashes for the six above is an operator action (`sha256sum` on files the
operator already holds) and has not been done; until it is, this page covers ten files and says so.

> ⚠ **Superseded 2026-09-04, annotated rather than rewritten.** The operator authorized it and all
> six are now escrowed — see §"The six, escrowed 2026-09-04". This page now covers **sixteen**
> files. The sentence above stands as published; the table above it stands unaltered and remains
> the correct record of what was *not* escrowed between 2026-09-02 and 2026-09-04.

## The six, escrowed 2026-09-04 — and why each carries a FREEZE digest

Added 2026-09-04 on operator authorization. The six files itemized in the section above now have
hashes. **Nothing above this section is altered**; that table and its ten rows stand exactly as
published.

🔴 **These rows are built differently from the ten above, and the difference is the point.** The ten
escrow *the file's state on 2026-08-22*. These six escrow **the state at the commit that froze the
file**, named and dated, so the digest attests the thing a pre-registration is supposed to attest.
Where the file has changed since, the current digest is published **alongside** it, with what changed.

| file (in `roae-private`) | freeze commit | frozen | sha256 **at freeze** | bytes | current state |
|---|---|---|---|--:|---|
| `F4PRIME_PREREGISTRATION.md` | `1041283a` | 2026-07-04 | `13d2722b961241a13040d80c2af24bed8d802952cdb1aad6578c4a90bc46d017` | 3,619 | **identical** |
| `F5_ORIENTATION_PREREGISTRATION_2026_07_FROZEN.md` | `30ae65a8` | 2026-07-05 | `af622f1ad9312e38441facf8a5e2b3ffe6ac6632b1f271f4c3ba0eb6070b76bf` | 24,010 | **differs — 2 lines** |
| `F6_BOOKS_PREREGISTRATION_2026_07_FROZEN.md` | `6917467f` | 2026-07-05 | `e35744b6bb91a15dea3ff6a07f6d8946ca88cfd9c4f74c5a09bbc1dfd20c6420` | 12,870 | **identical** |
| `R3_PERMUTATION_OBSERVABLE_PREREG_2026_07_09.md` | `1c2d8fcb` | 2026-07-10 | `7104e6546309bf89592eb04d82209c41a7c4342e6f3d48b246fb5e27fdfb0564` | 23,745 | **identical** |
| `R8_DAVIS_PREREG_2026_07_10.md` | `25444f5f` | 2026-07-10 | `9d788f479b12ffdcff6ea91febea773badbe77c2ced033fedf694ff8331ec762` | 26,717 | **differs — erratum** |
| `F11_BAYES_PREREGISTRATION_2026_07.md` | `0e153637` | 2026-07-04 | `4e2eb0a2d5cfed76ee1e60fae7ae677b584f2e3d18de849b266f015c1869093e` | 2,635 | **identical** |

**Four of the six are byte-identical today to their freeze commit**, so for those the freeze digest
and the current digest are the same value and one hash checks both states.

**The two that differ, with the difference stated rather than summarised:**

- **`F5_ORIENTATION…FROZEN.md`** — current sha256
  `d7149328df9b8bf54b6203512ccb208a0765814c34b2511f23bf41b0f15f5f7f`, **24,010 bytes, unchanged in
  length**. The entire diff from the freeze is **two lines**, both `SOLVE-SUMMARY` → `SOLVE_SUMMARY`,
  from the 2026-07-16 commit that applied that public filename rename across 39 files. **No content,
  no observable, no threshold and no family size changed.**
- **`R8_DAVIS_PREREG_2026_07_10.md`** — current sha256
  `a58ca29275d9c3ca627f5c32f6368072d8cce1fc852c1cadc83b11f285623d5e`, **32,344 bytes**. The diff is
  **74 added lines** under a single heading, `### Erratum (2026-07-12, recorded at the wave-2
  landing)`, correcting §3.3/§3.1's "C2-compliant" to C1 (pair-structured). **It is an erratum, dated
  in place and disclosed at the landing — not a result.**

🔴 **What was checked before publishing, and what it found.** Each of the six was tested for the
defect recorded against two of the ten above — a result appended to the file after its freeze, which
makes the escrowed digest attest a document containing its own outcome. **None of the six has one.**
The two changes are a cosmetic rename and a dated erratum. That check is the reason these rows name a
freeze commit at all: publishing a single current-state digest for `R8` would have escrowed a
post-erratum file as though it were the frozen one, and for `F5` would have escrowed a state that
postdates the freeze by eleven days for no reason a reader could see.

**What these six establish, stated as narrowly as the ten above are:** anyone later given one of these
files can hash it and check it against the freeze value, and — because the freeze **commit** is named
— the private history can be shown to produce that exact digest at that exact commit. **This still
does not convert freeze timing for an outside reader**, who cannot see the private repository; it
converts *content identity at a named commit* from attested to checkable, and it makes any later
change to the file visible as a hash mismatch rather than invisible.

## Rule adopted 2026-09-04 — a result may never be appended to a pre-registration

Two of the ten rows above escrow a digest that covers the commit which appended the file's own result
(`PREREG_KNUTH_CLEANROOM_2026_08_08.md`, `PREREG_REPR_COST_VS_T_2026_08_18.md`). Both are disclosed
in §"The escrowed hash is the file's state on 2026-08-22" and both now also carry a freeze-commit
digest, so nothing is misrepresented. The defect is structural, not clerical:

> **A pre-registration file is closed at its freeze. A result belongs in a separate RESULTS artifact
> that cites the pre-registration; it is never appended to it.**

**And the enforcing corollary, which is what makes the rule hold without depending on discipline:**

> **Escrow the FREEZE-COMMIT digest, not the file's current state.** Then appending anything —
> a result, an erratum, a rename — cannot corrupt the escrow. It becomes a visible mismatch instead.

The six rows above are the first written under both. The ten above them are annotated, not rewritten.

## Why publish hashes rather than the files

The files reference operator-held infrastructure and, in some cases, quote in-copyright material.
Publishing them would require redaction, and redaction breaks the byte-identity this page exists to
establish. Hashing is the one operation that gives an outside reader a real check while leaving the
disclosure decision open. Selective publication of individual pre-registrations remains possible
later.

**A file published *unredacted* will verify against its hash here. A file published *redacted* will
not, and cannot** — corrected 2026-09-02, replacing an unconditional promise that this page's own
redaction argument two sentences earlier already refutes. Byte-identity is not partially preserved by
a partial edit; one changed character is a different digest. Both outcomes have already occurred, and
both are recorded in the next section rather than left for a reader to discover by hashing.

## Which of these files are already public

Added 2026-09-02. The 2026-08-22 text said the pre-registration files are held privately and are not
publicly fetchable. **That was already false when it was written**, in two different ways, and a
third frozen pre-registration outside this table is public in full:

- ✅ **Published unredacted, and it verifies.** `PREREG_VMATCHED_GATE_2026_08_04.md` is shipped in
  this repository as
  [`reports/evidence/f11halfb/PREREGISTRATION_VMATCHED.md`](../reports/evidence/f11halfb/PREREGISTRATION_VMATCHED.md).
  It is 5,336 bytes and hashes to `37ee9eee…82` — **byte-identical to its row above.** This is the
  only row of the ten that a reader can check end to end today, and it is the page's working example:
  `sha256sum reports/evidence/f11halfb/PREREGISTRATION_VMATCHED.md` reproduces the escrowed value.
- ❌ **Published redacted, and it does not verify.** `PREREG_HALFB_EXTENDED_2026_08_03.md` is shipped
  as [`reports/evidence/f11halfb/PREREGISTRATION_EXTENDED.md`](../reports/evidence/f11halfb/PREREGISTRATION_EXTENDED.md)
  — same title, same "Written 2026-08-03, BEFORE the extended run is launched" line, and named in
  `RESULTS.md` as the spec the run followed. It is **3,986 bytes**, hashing to
  `1dedbda1ca251d4c41ea6da207c6bf34dd0aeae26b6dc48a58c061463c8a4614`, against the escrowed
  **3,965 bytes** / `09d711c3…94`. The two copies are the **same document**: they are
  81 lines each and differ in **exactly one line, the last**, where a name identifying operator-held
  infrastructure was replaced with a generic description before publication. That is a redaction of
  the kind this section's first paragraph describes, it is the whole of the difference, and it is
  sufficient to break the check. **Readers must not treat the public file as the escrowed artifact;**
  the escrowed digest is of the unredacted private original. Note that the public copy was committed
  **2026-08-04**, eighteen days *before* this page was published — the mismatch was not introduced by
  a later edit to either file, and neither has been modified since.
- ➕ **A frozen pre-registration published in full, outside this table.**
  [`reports/evidence/f11/PREREGISTRATION.md`](../reports/evidence/f11/PREREGISTRATION.md) is headed
  "FROZEN 2026-07-04 by operator approval", is 3,901 bytes, hashes to
  `51b78890e8fe9ef87ee651832470c69d7499118ed2e8752bed2b4cb99a7376c5`, and has no row above. It needs no escrow — it has been public since before this page existed — but it is a direct
  counterexample to the claim that the pre-registration files are not publicly fetchable.

*Access boundary, restated: **eight** of the ten files above are held in a private repository
(`roae-private`) and are not published; one is published in full and verifies, and one is published
in redacted form and does not. For the eight, this page is the public, checkable artifact — and what
it makes checkable is content identity from 2026-08-22 onward, not freeze timing.*

## Amendment log

### 2026-09-04 — the six named as not-escrowed are escrowed, and a rule is adopted

1. **Six rows added** in §"The six, escrowed 2026-09-04". They carry a **freeze-commit** digest, not a
   current-state digest, and where the file has changed since, the current digest is published beside it
   with the diff characterised. Every one of the six freeze digests was independently recomputed from the
   named commit and checked against this page before publication: **6/6**.
2. **Nothing above was altered.** The ten rows, their hashes, byte counts and dates are as published on
   2026-08-22. The closing sentence of §"Pre-registrations that are NOT escrowed here" is **annotated**
   with a superseded-note; its table stands and remains the correct record of the 2026-09-02 → 2026-09-04
   state.
3. **A rule was adopted** — §"Rule adopted 2026-09-04": a result is never appended to a pre-registration,
   and escrow takes the freeze-commit digest so that appending cannot corrupt the escrow.
4. **Checked before publishing:** each of the six was tested for the defect recorded against two of the
   ten (a digest covering the commit that appended the file's own result). **None of the six has one.**
   Two differ from their freeze state — one by a two-line cosmetic filename rename, one by a dated
   erratum — and both differences are stated in full rather than summarised.

**2026-08-22 — published.** The ten rows, their hashes, byte counts and dates. Single commit; no
edit until the entry below.

**2026-09-02 — amended (prose lane, batch P41), no published value changed.** Four corrections, all
narrowing claims the original text made too broadly:

1. The claim that escrow converts freeze timing was made without a date direction. It converts
   content identity from the publication date forward; freeze timing is converted only for hashes
   published *before* their measurement, and **no row in this table is of that kind**. Restated in
   §"What this is, and what it is not", with the retrospective status of all ten stated there rather
   than as a per-row column, so that no published cell is rewritten.
2. The opening sentence claimed a complete population of frozen files (retired as `RP-be8e188a`).
   Ten is a subset; six further frozen pre-registrations named in the shipped code now have their
   own section.
3. The undisclosed gap between the date column and the hash column for three rows — the file was
   amended after its freeze commit, twice after the result was recorded — is now stated, with the
   freeze-state digests published so both states are checkable.
4. "Not publicly fetchable" and the unconditional verify-on-disclosure promise are both replaced;
   the actual public status of every listed file is enumerated above, including the one that does
   not verify and why.

Nothing in this amendment adds, removes or alters a hash, byte count or date published on
2026-08-22. The corrections ledger entry is
[CORRECTIONS.md](CORRECTIONS.md) §"2026-09-02 — PREREGISTRATION_ESCROW.md".
