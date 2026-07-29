---
name: health-episode-report
description: Build a single-page HTML health episode report from Minowa MCP data for a specified timeframe. The report has a Chart.js graph (heart rate, stress, blood pressure, event markers) at top and a short clinical narrative, data table, verbatim observations, and caveats below. Use this whenever the user wants to analyze, chart, write up, or produce a report on a health episode, sleep period, or any specified time window of their Minowa/Garmin data — including phrasings like "make a report on last night", "chart this afternoon's episode", "write up the window from 2 to 5 PM", "let's analyze the episode around X". The skill self-fetches all data from Minowa given a timeframe. Always consult the norms file before writing the narrative.
---

# Health Episode Report

Produces the single-page HTML episode report the user has refined across prior sessions. The skill self-fetches data from the Minowa MCP server for a user-specified timeframe, applies accumulated inference norms, and renders a polished one-pager.

## Core principles (do not violate)

1. **The user specifies the timeframe. Never infer it from Garmin sleep staging.** Wake time can be read off the heart-rate rise, but sleep-prep measures happen *before* the HR climb, so a naive "wake = HR rise" anchor clips them. The user gives an explicit start and end; if they haven't, ask for it. Sleep staging is a *supporting* layer inside the window, never the thing that defines it.

2. **±15-minute presentational padding.** The analyzed timeframe is the user's specified `[start, end]`. Fetch minute data across `[start − 15 min, end + 15 min]` and set the chart's x-axis min/max to those padded bounds, so events don't crowd the edges of the graph. This padding is purely for presentation — the analysis is still about `[start, end]`.

3. **Observations are mandatory and verbatim.** Anything worth analyzing has notes attached. Always fetch the full observation log across the window and (a) render it verbatim in its own section and (b) plot each note as an event marker on the chart. Never optional, never summarized away.

4. **Keep the narrative small. Do not guess at implications.** Call `minowa:get_health_norms` *before* writing a single sentence of narrative, and apply what it returns. The norms live in versioned server storage now, not in a file in this folder — `HealthMonitoringNorms.example.md` here is only a shape template for someone setting the skill up fresh. State known sequences plainly from the norms rather than re-deriving them; do not speculate on the meaning of events beyond what the norms and data support. When the user corrects an inference or states a new norm, add it with `minowa:update_health_norms` (see "Updating the norms").

5. **Two uncalibrated BP meters.** An upper-arm meter sits on the desk; a wrist cuff sits by the bed. They are not calibrated against each other and the wrist unit reads consistently higher — this is fine and expected, because within a sleep period the wrist series is tracked *relative* to itself for comparison against HR and stress, not as absolute clinical values. Tag every BP reading by source (arm vs wrist). Discard a reading only when it is BOTH anomalously high within that night's own set AND symptom-inconsistent (e.g. a 150+ systolic the user would have felt as a headache but logged no headache) — that pattern is a wrist-positioning/technique artifact. Do not discard readings merely for being high.

## Workflow

### 1. Establish the timeframe
Confirm the explicit start and end, in the user's local time. If the user gave a fuzzy anchor ("last night", "the afternoon episode"), pin it down to concrete clock times with them before fetching. All timestamps to Minowa must be timezone-aware ISO 8601 carrying the user's local UTC offset, e.g. `YYYY-MM-DDT14:15:00-07:00`; get the timezone from `minowa:get_current_time`. Delegate any date math to `minowa:get_current_time` / `minowa:date_math` rather than computing inline.

### 2. Fetch the data (self-fetch — see `references/minowa-data.md` for exact calls and quirks)
Fetch across the padded window `[start − 15 min, end + 15 min]`:
- **HR + stress**: `minowa:get_garmin_minute_detail` with `from`/`to`. HR and stress arrive on offset clocks — treat as two separate sparse series (`parsing:false`), not paired points. **Stress is suppressed whenever the user is moving** — documented Garmin behavior, not a gap; let the stress line break there and explain it in one short caveat sentence (see `references/minowa-data.md`). Ignore `respiratory_rate` entirely — the device has no respiration sensor.
- **Observations**: `minowa:get_observations_detail` with `from`/`to` — it accepts explicit bounds up to 24h, so one call covers the padded window. No anchor stitching.
- **Sleep staging (supporting)**: `minowa:get_sleep_events_detail`. Short daytime naps are not scored — absence there is normal, infer rest from the HR decline instead.
- **Blood pressure**: `minowa:get_vitals_timeline` with `include:['bp']`. Read the per-reading source metadata (wrist vs upper arm, posture) and the `untrusted` flag. Tag by source; apply the discard rule from principle 5.
- **Doses**: `minowa:get_recent_activity` with `kind:"medication"` for supplement/dose markers.

The first Garmin call after a sync can time out — retry once. If last night's data hasn't synced, queue `minowa:sync_garmin_data`, ping `get_current_time`, wait ~90s, re-query.

### 3. Apply the norms
Call `minowa:get_health_norms` now. Use what it returns to write known sequences plainly and to avoid re-guessing corrected inferences.

### 4. Render the report
Copy `assets/report_template.html` and fill it in. See `references/report-format.md` for the section-by-section spec and how to populate the chart data, event array, BP scatter, table, observations, and caveats. Keep the established look: single-page card, chart at top with a hypnogram ribbon when the window is scored and a rest band when it is not, events as icons in a dedicated lane below the traces with their text on hover only (never labelled on the plot), short clinical narrative in the user's own first-person voice, data table, verbatim observations, caveats block noting the uncalibrated meters and any discarded readings.

Save to `/mnt/user-data/outputs/YYYY-MM-DD_Description_vN.html` and present it. On edits, bump the version number in the filename (cache-busting) so the user always opens the corrected file.

## Updating the norms

When the user corrects an inference, states a rule ("BM will typically follow eating"), or tells you an event's implication, add it with `minowa:update_health_norms` — **only after the user has explicitly confirmed the change**, never proactively. That tool takes the COMPLETE document as a full replacement, so fetch the current version first, apply the change, and save the whole thing back with a `change_note`. The server assigns the version number and preserves history, so nothing is lost: retire a rule to the **Retired** section with a reason rather than deleting it, and amend in place when a rule was incomplete rather than wrong.

Because the norms live on the server, they persist across sessions on their own — do NOT re-package the skill just to carry a norm forward, and never write personal norms into a file inside this folder or into `dist/`. Keep the document to genuine repeated-correction inferences, not one-off facts.

## Voice and style
Clinical precision, no hedging language. Write in the user's own first-person voice — this is the user presenting how they use Minowa, not an anonymized write-up. Short narrative. Claims must be evidence-backed, not asserted.
