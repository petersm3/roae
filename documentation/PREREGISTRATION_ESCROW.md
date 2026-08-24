# Pre-registration escrow — sha256 of the frozen pre-registration files

**Published 2026-08-22 (operator decision, Q28 option (b)).**

## What this is, and what it is not

The ROAE project pre-registers a test **before** its result is computed: the observable, the family
size, and the decision rule are fixed in a file, and that file is frozen. Until now, the claim that a
pre-registration was frozen *before* the measurement rested on **operator attestation** — the files
live in a private repository and an outside reader had to take our word for the timing.

This page publishes the **sha256 of each frozen file**. It does not publish the files.

**What it establishes:** if any of these files is later disclosed, anyone can hash it and check it
against the value below. A file whose hash matches was **byte-identical on this date**. That converts
freeze-timing from *attested* to *checkable*.

**What it does NOT establish:**
- ❌ It does not prove the content is *correct*, only that it has not changed.
- ❌ It does not prove a file was frozen before some *earlier* date — only that this is its state as
  published here.
- ❌ It discloses **nothing** about the contents. A hash is not a summary.
- ⚠ The "first committed" dates come from the **private** repository's history, which is itself
  operator-held and not publicly auditable. **They are a claim, not a proof** — the sha256 is the
  part a reader can check independently. Do not read the date column as escrowed.

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

## Why publish hashes rather than the files

The files reference operator-held infrastructure and, in some cases, quote in-copyright material.
Publishing them would require redaction, and redaction breaks the byte-identity this page exists to
establish. Hashing is the one operation that gives an outside reader a real check while leaving the
disclosure decision open. Selective publication of individual pre-registrations remains possible
later, and each published file will then verify against its hash here.

*Access boundary: the pre-registration files themselves are held in a private repository
(`roae-private`) and are **not publicly fetchable**. This page is the public, checkable artifact.*
