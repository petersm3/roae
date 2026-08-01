# DEPRECATED — 10T depth-3 partial enumeration (2026-04-18)

**Status: the `solutions.bin` this directory documents is a DEPRECATED canonical.**
Added 2026-08-01; the 2026-05-13 deprecation had reached
[`runs/20260419_10T_d3_d128westus3/README.md`](../20260419_10T_d3_d128westus3/README.md)
but not these two directories, which are where the sidecars actually live.

| | |
|---|---|
| sha in `solutions.sha256` | `f7b8c4fbf2980a169a203b17a6a92c3d175515b00ee74de661d80e949aa6187e` — **DEPRECATED** |
| count in `solutions.meta.json` | 706,422,987 — **an UNDERCOUNT** |
| current d3 10T canonical | `b85c887128ce9881229741380a799c4e1608335df438cedc3da9e087fd94dbbc` |
| current d3 10T count | 706,427,594 |

**Why deprecated.** The run predates the 2026-04-30 resume fixes. It is incomplete by
4,607 records lost through imperfect mid-walk resume — see
[`documentation/CANONICAL_HASHES.md`](../../documentation/CANONICAL_HASHES.md) §Deprecated
and [`documentation/HISTORY.md`](../../documentation/HISTORY.md).

Do **not** cite the sha or the count above as a current canonical. The logs and checkpoints
here are retained for the historical record and for eviction/resume forensics; they remain
accurate accounts of what that run did.
