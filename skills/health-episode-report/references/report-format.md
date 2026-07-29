# Report format reference

Copy `assets/report_template.html` to the output path and replace each `{{PLACEHOLDER}}`. The x-axis uses **minutes-since-local-midnight** as a linear scale (e.g. 2:15 PM → 875), which keeps the offset HR/stress clocks and the event/BP markers all on one coordinate system. The `fmt()` helper turns those minutes back into clock labels.

**Overnight / cross-midnight windows**: use *continuous* minutes measured from the window's starting midnight, so times after midnight keep counting up past 1440 (e.g. 6:56 PM → 1136, 4:08 AM next day → 1688). All series, events, REST, and SPANS must use this same continuous coordinate. `fmt()` already wraps by 1440 for display. `REST` may carry a `label` (e.g. "rest / unscored sleep"); it defaults to "rest / unscored".

## Placeholders

- `{{TITLE}}` / `{{HEADING}}` — e.g. `Overnight — YYYY-MM-DD · 1:21–4:52 AM`.
- `{{DATE_LONG}}` — human date, e.g. `Saturday, January 4, YYYY`.
- `{{WINDOW_LABEL}}` — the analyzed window in clock time (unpadded), e.g. `1:21–4:52 AM`.
- `{{XMIN}}` / `{{XMAX}}` — padded bounds in minutes-since-midnight: `start − 15` and `end + 15`.
- `{{HR_POINTS}}` / `{{STRESS_POINTS}}` — JS arrays of `{x:minutes, y:value}`, one per sample. Keep them separate (offset clocks). Omit stress if no samples. **The stress dataset uses `spanGaps:12`, not `true`** — normal cadence is ~3 min, so 12 bridges sampling jitter but breaks the line wherever Garmin stopped scoring stress because the user was moving (see `minowa-data.md`). That break is the only visual marker those stretches get: do NOT also shade them, band them, or annotate them on the plot — one signal, not two. Explain the break once in the caveats instead.
- `{{ARM_BP}}` / `{{WRIST_BP}}` — desk arm-cuff and bed wrist-cuff readings as `[{x, sys, dia}, ...]`. Each becomes one dot at its **systolic** value on the right axis, labeled with the full `sys/dia`. `[]` if none in window. Never merge the two meters (they diverge widely); wrist appears only in rest/still periods; discard within each meter separately (discards go in caveats).
- `{{STAGES}}` — Garmin-scored sleep as `[{from, to, stage:"deep|light|rem|awake"}, ...]`, or `[]`. When present, the template draws a hypnogram ribbon along the bottom (deep `#2c3e70`, light `#9aa4d4`, rem `#59b0a8`, awake `#e0b774`) plus a faint full-height "sleep (scored)" band, and the `{{REST_BAND}}` is ignored. Scoring lags the upload, so this is often `[]` on a first morning-after run and fills in on a re-run — re-fetch `get_sleep_events_detail` before assuming a night is unscored.
- `{{REST_BAND}}` — fallback only, used when `{{STAGES}}` is `[]`: `{from:minutes, to:minutes, label?}` for the inferred rest span (from the HR-decline bracket + observations), or `null`. Default label "rest / unscored".
- `{{SPANS}}` — annotated period markers drawn as a labeled bracket along the bottom of the plot: `[{from, to, label, color}, ...]`, or `[]` for none. Use for felt or observed episodes that occupy a stretch of time rather than a point — a symptom spell, a stretch of exertion, and so on. Label each with the user's own word for it, taken from the norms. These are distinct from the rest band and from point events. A felt episode often won't show much on the HR trace (the sensation outruns the signal), so the span plus the narrative carry it.
- `{{EVENTS}}` — array of `{x:minutes, label:"...", type:"obs"|"dose"}`. Every logged observation becomes one; doses use `type:"dose"`. **Events are not labelled on the plot.** Each becomes an icon in a **dedicated lane just above the hypnogram** — a near-black circle (`#14171c`) for an observation, a deep-green diamond (`#0c7a41`) for a dose, both `r≈7–8` with a 2.5px white ring — and its text appears only on hover, with the clock time as the tooltip title. The `eventLane` plugin rewrites each icon's pixel y after layout: the lane clears the hypnogram ribbon and the span brackets, and any icon that would overlap its neighbour steps up a row, so a sparse window reads as one clean line and only a genuine cluster stacks. Supply no `y` and no `tier`. Keep labels short.

  Hovering an event also drops a **full-height dashed rule** at its minute and rings where that rule crosses the HR and stress traces (`eventCrosshair`), and the tooltip adds the two values. Both use `valAt()`, which interpolates between neighbouring samples but returns `null` — rendering "stress — not scored" and drawing no ring — when the neighbours are further apart than the gap allowance (`HR_GAP` 8 min, `STRESS_GAP` 12 min). That is deliberate: it stops a movement gap in the stress series from being silently invented at the one moment the reader is looking hardest.
- `{{LEAD}}` — one-sentence lead, in the user's voice.
- `{{NARRATIVE_PARAGRAPHS}}` — a few short `<p>` paragraphs. Apply the norms; do not speculate on implications.
- `{{TABLE_ROWS}}` — `<tr>` rows: `<td>time</td><td>metric</td><td class="n">value</td><td>source</td><td class="flag">note</td>`. Include BP (with wrist/arm source), notable HR/stress points, doses.
- `{{OBSERVATIONS}}` — verbatim logged notes, each `<div><span class="t">h:MM</span>note text</div>`. Mandatory — never omit or paraphrase.
- `{{CAVEAT_ITEMS}}` — extra `<li>` items beyond the standing BP-meter caveat already in the template: any discarded readings (with reason), respiratory-rate gaps, unscored naps, etc.

## Populating from the fetched data

- **Minutes conversion**: `minutes = hour*60 + minute` in the user's local time. Delegate any date math to Minowa's date tools; only the minute-of-day arithmetic is done inline.
- **Padding**: fetch data across `[start−15, end+15]` so the HR/stress lines reach the chart edges; set `XMIN=start−15`, `XMAX=end+15`.
- **BP source tags**: from the vitals per-reading metadata — label `wrist` or `arm` in the table Source column. Apply the discard rule (anomalous within the night's set AND symptom-inconsistent); list any drop in caveats.
- **Rest band**: prefer Garmin sleep staging; if the nap was too short to be scored, bracket the rest from the HR decline and label it "rest / unscored nap" (the template already does).

## Common pitfalls (do not repeat)

- **Never pass `var(--x)` to Chart.js.** Canvas cannot resolve CSS custom properties; `borderColor:"var(--hr)"` silently renders black. Use literal hex in all dataset colors, axis ticks, titles, and grid. CSS variables are fine in HTML/CSS (legend swatches, page styling) — only the canvas/JS side needs literals.
- **Pin the color scheme.** The report is a light design; without `<meta name="color-scheme" content="light only">` and `color-scheme:light only` on `:root`, browsers with auto-dark-mode force-darken the white card and invert text. Keep both in the template.

## Persistent layout rules (baked into the template — keep them)

- **X-axis**: time-of-day across the bottom, 30-min ticks, padded ±15 min. Do not change.
- **Left axis = BPM / stress (one shared scale)**: heart rate and stress both ride the left axis; fixed base of 0 (so stress graphs from zero), top = peak heart rate + 10 (computed as `YTOP`). Because they share one axis, HR and stress necessarily share this 0 floor.
- **Right axis = systolic**: fixed 60–140. Every BP reading is a single dot at its systolic value here, labeled with the full `sys/dia` (diastolic is not its own dot). Arm/desk = orange circle, wrist/bed = violet triangle.
- **Line contrast**: heart rate bold red (`#d1495b`, width ~2.4), stress cool blue (`#1f6fb2`, width ~1.5). Never make both warm — they blend.
- **Events are icons on the HR line, never text on the plot.** A stacked lane of labels above the chart becomes unreadable as soon as a window carries more than a few events, and an overnight window carries a dozen. The icon marks *when*; the tooltip carries *what*; the table and the observations section carry the full record. Do not reintroduce on-plot event text, connector lines, or a reserved top lane — `layout.padding.top` is 14 and should stay there.
- **Nothing about events is drawn at rest except the icons.** The rule, the crossing rings and the values are all hover-only. Do not promote any of them to always-on.
- **Events belong in their own lane, not on the trace.** Riding the HR line was tried and failed twice: the line's shape decides where each icon lands, so events minutes apart on a multi-hour axis pile up illegibly no matter how they are sized. A constant-height row gives the eye one place to scan and makes collisions resolvable.
- **Event icons must stay high-contrast and large.** They sit against a busy plot; a mid-gray dot at `r=4.5` is invisible against it — that was tried and failed. Keep the near-black/deep-green fills, the white ring, and `r≈7–8`. Do not shrink them for tidiness.
- **Only real points answer the hover.** The HR and stress datasets set `pointHitRadius:0`, so a tooltip is always an event, a dose, or a BP reading — never a stray point on a line.

## Versioning
Save as `/mnt/user-data/outputs/YYYY-MM-DD_Description_vN.html`. On every edit, bump `N` and present the new file so the user always opens the corrected version (cache-busting).
