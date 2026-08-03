---
name: health-episode-report
description: Build a single-page HTML health episode report from Minowa MCP data for a specified timeframe. The report has a Chart.js graph (heart rate, stress, blood pressure, event markers) at top and a short clinical narrative, data table, verbatim observations, and caveats below. Use this whenever the user wants to analyze, chart, write up, or produce a report on a health episode, sleep period, or any specified time window of their Minowa/Garmin data — including phrasings like "make a report on last night", "chart this afternoon's episode", "write up the window from 2 to 5 PM", "let's analyze the episode around X". The skill self-fetches all data from Minowa given a timeframe. Always consult the norms file before writing the narrative.
---

# Health Episode Report

Produces the single-page HTML episode report the user has refined across prior sessions. The skill self-fetches data from the Minowa MCP server for a user-specified timeframe, applies accumulated inference norms, and renders a polished one-pager.

## Core principles (do not violate)

1. **The user specifies the timeframe. Never infer it from Garmin sleep staging.** Wake time can be read off the heart-rate rise, but sleep-prep measures happen *before* the HR climb, so a naive "wake = HR rise" anchor clips them. The user gives an explicit start and end; if they haven't, ask for it. Sleep staging is a *supporting* layer inside the window, never the thing that defines it.

2. **±15-minute presentational padding.** The analyzed timeframe is the user's specified `[start, end]`. Fetch minute data across `[start − 15 min, end + 15 min]` and set the chart's x-axis min/max to those padded bounds, so events don't crowd the edges of the graph. This padding is purely for presentation — the analysis is still about `[start, end]`.

3. **Pull every stream the window contains. The fetch is a sweep, not a shopping list.** An episode report is worth exactly what its coverage is worth, and one that silently drops a logged input is worse than no report — it reads as complete. So every timeframe-scoped Minowa stream is queried for every window, always, with the widest filter the call allows: `kind:"all"`, `include` omitted. Never narrow a call to the streams that seem likely to matter; which stream carries the finding is not knowable before fetching. Two calls have defaults that quietly hide data — `get_recent_activity` returns only the one `kind` passed to it, and `get_vitals_timeline` returns only what `include` names — so pass `kind:"all"` and omit `include`. Then account for every stream in the output: each one either appears in the report or earns a caveat line saying it was empty. Absence is a finding to be stated, never a gap left for the reader to notice.

4. **Observations are mandatory and verbatim.** Anything worth analyzing has notes attached. Always fetch the full observation log across the window and (a) render it verbatim in its own section and (b) plot each note as an event marker on the chart. Never optional, never summarized away.

5. **Keep the narrative small. Do not guess at implications.** Call `minowa:get_health_norms` *before* writing a single sentence of narrative, and apply what it returns. The norms live in versioned server storage and are fetched at runtime. There is no norms file in this package and there must never be one — this skill stores nothing on disk. State known sequences plainly from the norms rather than re-deriving them; do not speculate on the meaning of events beyond what the norms and data support. When the user corrects an inference or states a new norm, add it with `minowa:update_health_norms` (see "Updating the norms").

6. **Two uncalibrated BP meters.** An upper-arm meter sits on the desk; a wrist cuff sits by the bed. They are not calibrated against each other and the wrist unit reads consistently higher — this is fine and expected, because within a sleep period the wrist series is tracked *relative* to itself for comparison against HR and stress, not as absolute clinical values. Tag every BP reading by source (arm vs wrist). Discard a reading only when it is BOTH anomalously high within that night's own set AND symptom-inconsistent (e.g. a 150+ systolic the user would have felt as a headache but logged no headache) — that pattern is a wrist-positioning/technique artifact. Do not discard readings merely for being high.

## Workflow

### 1. Establish the timeframe
Confirm the explicit start and end, in the user's local time. If the user gave a fuzzy anchor ("last night", "the afternoon episode"), pin it down to concrete clock times with them before fetching. All timestamps to Minowa must be timezone-aware ISO 8601 carrying the user's local UTC offset, e.g. `YYYY-MM-DDT14:15:00-07:00`; get the timezone from `minowa:get_current_time`. Delegate any date math to `minowa:get_current_time` / `minowa:date_math` rather than computing inline.

### 2. Sweep every stream (self-fetch — see `references/minowa-data.md` for exact calls and quirks)
Fetch across the padded window `[start − 15 min, end + 15 min]`. **All of these, every window, no exceptions** — this list is the minimum, not a menu:

| Stream | Call | Filter |
|---|---|---|
| HR, stress, steps | `get_garmin_minute_detail` | `from`/`to` |
| Observations | `get_observations_detail` | `from`/`to` |
| Sleep staging (supporting) | `get_sleep_events_detail` | `from`/`to` |
| Vitals — BP, weight, temperature, glucose | `get_vitals_timeline` | **omit `include`** |
| Inputs — medication, food, observation, sync, document, acquisition | `get_recent_activity` | **`kind:"all"`** |
| Nutrition rollup — when any food entry lands in the window | `get_nutrition_report` | the window's day |
| Prior analyses overlapping the window | `list_day_reports`, `list_episode_reports` | `from`/`to` |

Per-stream handling:
- **HR + stress** arrive on offset clocks — treat as two separate sparse series (`parsing:false`), not paired points. **Stress is suppressed whenever the user is moving** — documented Garmin behavior, not a gap; let the stress line break there and explain it in one short caveat sentence. Ignore `respiratory_rate` entirely — the device has no respiration sensor.
- **Sleep staging**: short daytime naps are not scored — absence there is normal, infer rest from the HR decline instead.
- **Vitals**: read the per-reading source metadata (wrist vs upper arm, posture) and the `untrusted` flag. Tag by source; apply the discard rule from principle 6. Weight, temperature and glucose rarely land inside an episode window, which is exactly why they must be asked for rather than assumed absent.
- **Inputs**: `kind:"all"` returns six kinds through one call. Doses and food both become event markers; a `sync` entry explains a data boundary; a `document` or `acquisition` entry can explain an input that has no dose log yet. Eating may appear as a structured food entry, as a written observation, or as both — neither implies the other, so carry both and label the source.
- **Observations arrive twice** — from `get_observations_detail` and again inside `kind:"all"`. Dedupe on timestamp plus text and plot each note once.
- **Prior analyses**: if a saved report already covers this window, read it before writing a new one so the two do not contradict each other.

The first Garmin call after a sync can time out — retry once. If the window hasn't synced, queue `minowa:sync_garmin_data`, ping `get_current_time`, wait ~90s, re-query.

### 3. Close the coverage checklist before writing anything
List every stream from the table with its row count. Then resolve each zero, because two very different things look identical in the data:

- a **real** zero — nothing was logged, nothing was measured. This becomes a caveat line ("no BP readings from either meter in this window").
- an **unsynced** zero — the data exists on the device and has not landed. Check each source's `last_sync` against the window end before calling any Garmin zero real; a window analyzed live will routinely sit past the last upload. Sync and re-query rather than reporting an empty window.

A stream may not leave this step unaccounted for. If the checklist is not closed, the report is not finished — no matter how good the chart looks.

### 4. Apply the norms
Call `minowa:get_health_norms` now. Use what it returns to write known sequences plainly and to avoid re-guessing corrected inferences.

### 5. Render the report
Copy `assets/report_template.html` and fill it in. See `references/report-format.md` for the section-by-section spec and how to populate the chart data, event array, BP scatter, table, observations, and caveats. Keep the established look: single-page card, chart at top with a hypnogram ribbon when the window is scored and a rest band when it is not, events as icons in a dedicated lane below the traces with their text on hover only (never labelled on the plot), short clinical narrative in the user's own first-person voice, data table, verbatim observations, caveats block noting the uncalibrated meters, any discarded readings, and **every stream that came back empty**.

Each stream that carried rows must be visible in the rendered output, not merely fetched: events on the chart, a row in the readings table, and a Source column naming which log it came from. A value that was fetched and then left out of the report is the same failure as never fetching it.

Save to `/mnt/user-data/outputs/YYYY-MM-DD_Description_vN.html` and present it. On edits, bump the version number in the filename (cache-busting) so the user always opens the corrected file.

## Updating the norms

When the user corrects an inference, states a rule ("BM will typically follow eating"), or tells you an event's implication, add it with `minowa:update_health_norms` — **only after the user has explicitly confirmed the change**, never proactively. That tool takes the COMPLETE document as a full replacement, so fetch the current version first, apply the change, and save the whole thing back with a `change_note`. The server assigns the version number and preserves history, so nothing is lost: retire a rule to the **Retired** section with a reason rather than deleting it, and amend in place when a rule was incomplete rather than wrong.

Because the norms live on the server, they persist across sessions on their own — do NOT re-package the skill just to carry a norm forward, and never write a norm into a file inside this folder, into `dist/`, or anywhere else on disk. Keep the document to genuine repeated-correction inferences, not one-off facts.

## Voice and style
Clinical precision, no hedging language. Write in the user's own first-person voice — this is the user presenting how they use Minowa, not an anonymized write-up. Short narrative. Claims must be evidence-backed, not asserted.
