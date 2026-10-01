# Figure — TR-3, the first 560T campaign's timeline (`fig_tr3_campaign_timeline`)

← [The capstone's visual showcase](README.md#how-the-computation-was-run) · Report: [TR-3 §Figure](../reports/TR3_REPRODUCIBLE_ENUMERATION.md#figure)

[![Timeline of the first 560T campaign, 2026-05-31 to 2026-06-08: green enumeration segments interrupted by five red eviction marks on weekday mornings, each followed by a deferred-downtime block until the evening relaunch, then an eviction-free weekend through completion.](../reports/figures/fig_tr3_campaign_timeline.png)](../reports/figures/fig_tr3_campaign_timeline.svg)

*The figure as committed. Click the image for the SVG. The authoritative caption is in [TR-3 §Figure](../reports/TR3_REPRODUCIBLE_ENUMERATION.md#figure).*

## In plain terms

This timeline shows the first run of the project's deepest search, from 31 May to 8 June 2026, on
rented cloud machines that the provider may take back at short notice (an "eviction"). On each
weekday morning the machine was taken back (red marks), and the run waited until the evening to
restart (purple blocks). Over the weekend there were no interruptions, and the run finished. The
picture records how the search was run; it is not a mathematical result.

## What it shows

Time runs left to right in Pacific Time. Green segments are enumeration running. Each of the five red
marks is an eviction, Monday to Friday, all inside a 37-minute morning window (07:12–07:49 PT). Each
purple block is the downtime a defer policy imposed after a weekday-daytime eviction, ending at the
18:01 PT relaunch. The weekend is shaded. The run's enumeration ended at 171.5 h wall-clock time,
50.5 h after the Friday relaunch, with no further eviction.

## What it establishes, and what it does not

- **Establishes.** The operational record TR-3 §4 describes: on this campaign every eviction landed
  on a weekday morning inside that window, and both weekend days had none (the "scheduled-reclamation
  observation", [TR-3 §Figure](../reports/TR3_REPRODUCIBLE_ENUMERATION.md#figure)). The run survived
  five preemptions and completed; TR-3 is about why an interrupted run still reproduces the same
  bytes.
- **Does not establish.** A general law of when a cloud provider reclaims machines: this is one
  campaign's record. The 2026-06-30 re-run had a different pattern of seven evictions; its
  per-eviction times are not in the public documents, so it is not drawn here, and its telemetry
  panels are in the [historical 560T run page](../runs/20260608_560T_9a968fa2/viz/index.html).

## Provenance

- **Data.** No table. The launch time, the five eviction times, the 18:01 PT relaunch policy and the
  171.5 h wall time are the campaign record in
  [CAMPAIGN_METHODOLOGY.md](../documentation/CAMPAIGN_METHODOLOGY.md), typed into the generator with a
  source comment. The weekend note's 50.5 h is asserted from the two plotted datetimes before drawing.
- **Generator.** `fig_tr3_campaign_timeline()` in [`viz/report_figures.py`](report_figures.py).
- **Regenerate.** The whole set:

  ```bash
  cd reports/figures && python3 ../../viz/report_figures.py
  ```

  or this figure alone:

  ```bash
  cd reports/figures && python3 -c "import sys; sys.path.insert(0, '../../viz'); import report_figures as r; r.fig_tr3_campaign_timeline()"
  ```

- **Toolchain.** matplotlib 3.11.0 and numpy 2.4.4. Under that pin the documented command reproduced
  the committed PNG byte for byte on 2026-09-29, with all twelve report figures (CX-233). See
  [Reproduce the figures](README.md#reproduce-the-figures) for how SVGs are compared.
- **Tokens.** None; this is a record of a run, not a measured claim.

## Review history

- **2026-09-26, Codex figure review VIZ1, checked by Fable.** Text below the 12-px floor at a 900-px
  display on every generator figure (F18); the timeline was narrowed to 10 in.
  [CORRECTIONS.md](../documentation/CORRECTIONS.md) CX-192.
- **2026-09-28, Codex visualization review, triaged by Fable.** The weekend note read "~54 h clean Spot
  runway", an interval that matched nothing plotted. It now states the plotted 50.5 h, asserted from
  the datetimes, and the note was moved so it overlaps no other text (Q-895, Q-889). CX-225 (TR-3
  revision row v1.17).
- **2026-09-29.** This page added, as part of the capstone's visual showcase (CX-233).

---

*Part of the [capstone's visual showcase](README.md), the companion to
[TR-12](../reports/TR12_QUERY_PROGRAM.md). A timeline of a published campaign record; nothing is
claimed novel. Developed with AI assistance (Claude, Anthropic); corrections invited.*
