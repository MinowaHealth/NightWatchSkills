# health-episode-report

Builds a single-page HTML report for any user-specified timeframe from Minowa MCP data: a Chart.js
graph (heart rate, stress, blood-pressure dots, event/dose markers, and a scored hypnogram or an
inferred rest band) above a short clinical narrative, a readings table, verbatim observations, and a
caveats block.

**Use it for:** "make a report on last night," "chart this afternoon's episode," "write up the window
from 2 to 5 PM," or any request to analyze/visualize a slice of Garmin/Minowa data.

## Files

- `SKILL.md` — workflow and the core principles (the user sets the timeframe; ±15-min chart padding;
  observations are mandatory and verbatim; two uncalibrated BP meters; keep the narrative small).
- `HealthMonitoringNorms.md` — accumulated inference corrections. **Read before writing any narrative.**
  Only grows. *(Personal data — see repo README.)*
- `assets/report_template.html` — the report template with `{{PLACEHOLDER}}` slots and the Chart.js
  overlay plugin (rest band, event-label packing, BP scatter, hypnogram ribbon).
- `references/minowa-data.md` — exact Minowa calls and their quirks (offset HR/stress clocks, absent
  respiratory rate, wrist-vs-arm BP, sync-lag handling).
- `references/report-format.md` — section-by-section spec for filling the template, the
  minutes-since-midnight coordinate system, and common pitfalls.

## Output

An artifact at `YYYY-MM-DD_Description_vN.html`. Version bumps on every edit so the corrected file is
always the one opened.

## Notes

Scored sleep staging **lags** the upload, so a night analyzed right after a morning sync may be
unscored; the skill infers rest from the HR decline and notes that a re-run will fill in the
hypnogram. Companion skill: **scored-sleep-signature**, which analyzes the *run-up* to a scored night.
