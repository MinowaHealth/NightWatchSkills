# Minowa data-fetching reference

All timestamps must be timezone-aware ISO 8601 carrying the user's local UTC offset, e.g. `YYYY-MM-DDT14:15:00-07:00`. Take the timezone from `minowa:get_current_time`, which reads it from their Minowa profile — never assume one. Delegate date math to `minowa:get_current_time` or `minowa:date_math`; never compute dates inline.

Fetch everything across the **padded** window `[start − 15 min, end + 15 min]`.

**"Everything" is literal.** Every call below runs on every window, at its widest filter. The two calls whose defaults hide data are `get_recent_activity` (returns only the `kind` passed — use `kind:"all"`) and `get_vitals_timeline` (returns only what `include` names — omit it). Then close the coverage checklist: one line per stream with its row count, and every zero resolved as either a real zero or an unsynced one.

**Beware the local clock.** The session environment's own date can be UTC-based and disagree with the user's local calendar day by one. Resolve "today" and "now" from `get_current_time`'s `local` field only, and build every ISO timestamp with the `utc_offset` it returns. A window built on the wrong calendar day returns zero rows and looks exactly like a quiet afternoon.

## Heart rate + stress — `minowa:get_garmin_minute_detail`
- Pass `from`/`to` for the padded window (the tool accepts explicit bounds up to 24h, or `at` + `window_minutes` up to ±720).
- HR and stress sample on **offset clocks** — their timestamps do not line up. Treat them as two separate sparse datasets, not paired x/y points. In Chart.js use `parsing:false` and feed each as `{x, y}` arrays. HR uses `spanGaps:true`; stress uses `spanGaps:12` (see the stress rule below).
- **Stress is suppressed while the user is moving. This is documented Garmin behavior, not missing data.** Garmin's own manuals: the watch samples HRV "while you are sitting or inactive"; "if you are too active for the watch to determine your stress level, a message appears instead of a stress level number"; and its own stress graph uses **gray bars for "times when you were too active to determine your stress level"**, distinct from blue rest and yellow stress. It also does not resume the moment movement stops — "check your stress level again after several minutes of inactivity" — so a short still stretch right after activity stays blank too. Therefore: never report these as a data gap, and never queue a re-sync to chase them (a re-sync will return more HR and zero new stress). Detect by intersecting stress gaps with non-zero step buckets — you need to know where they are so you don't misread them, and so the caveat is accurate. On the chart, the only marker they get is the stress line breaking (`spanGaps:12`); do not shade or band them as well. Explain it once, briefly, in the caveats — one short sentence, not a paragraph. Confirm the exact wording for the device in use — Garmin documents this per-model under "Using the Stress Level Glance" or "My stress level does not appear".
- **Do not query, check for, or mention `respiratory_rate`.** The device has no respiration sensor; the field is permanently null. Never treat it as a gap or a caveat. (Norms v4 retired the old "frequently absent" framing.)
- The **first call after a Garmin sync can time out**. Retry once — it succeeds reliably.

## Observations — `minowa:get_observations_detail`
- Now accepts explicit `from`/`to` bounds (up to 24h), so fetch the whole padded window in one call — no more ±60-min anchor stitching. (`at` + `window_minutes` still works if needed.)
- These are mandatory: render verbatim AND plot each as an event marker.

## Sleep staging (supporting only) — `minowa:get_sleep_events_detail`
- Returns Garmin-scored stages (deep/light/rem/awake). Use to draw a rest band when present.
- **Scoring lags the upload, sometimes by hours**, and short episodes may never be scored. Do not treat unscored stretches as "no sleep" — especially in a window analyzed right after a morning sync, which will routinely have long unscored real sleep. When staging is missing or partial, infer rest from the HR decline plus the observation notes and draw the band from those; add a caveat that scoring may not have caught up (re-running later may fill it in).

## Vitals — `minowa:get_vitals_timeline`
- **Omit `include`.** The parameter accepts `bp`, `weight`, `temperature`, `glucose`, and omitting it returns all four. Narrowing to `include:['bp']` was the old instruction and it is wrong: it hides three streams to save nothing, and the ones it hides are precisely the ones nobody thinks to check. `days` defaults to 30 and caps at 90; pass `from`/`to` as the window's local day.
- Each BP reading carries a **named source** and posture/arm, e.g. `arm` (desk upper-arm cuff, seated/standing), `cuff meter` (wrist, supine/in bed), `desk meter`, `manual`. `blood_pressure.available_sources` lists every source with counts; `bp_sources` filters to a subset.
- Treat the desk arm cuff and the bed wrist cuff as **two separate datasets — never merge them** (they diverge widely). The wrist cuff is used only when lying still, so wrist readings belong to rest/supine periods; arm readings are the desk meter. Plot each as its own series with distinct markers.
- Readings may carry an `untrusted` flag with a reason string (e.g. `"supine cuff import"`). Apply the discard rule from the norms **within each meter separately** — never compare across meters to decide. Note any discards in the caveats block.

## Inputs — `minowa:get_recent_activity`
- **Call with `kind:"all"`.** One call returns six kinds: `medication`, `food`, `observation`, `sync`, `document`, `acquisition`. Passing `kind:"medication"` — the old instruction — returns doses and *silently* drops the other five; there is no gap, no warning, and no way to tell from the response that anything was withheld. That is how a logged food entry went missing from a report whose whole subject was a reaction after eating. `days` defaults to 14 and caps at 90; pass `from`/`to` for the window's day and raise `limit` above the default 50 if the day is busy.
- What each kind is for:
  - `medication` — supplement/dose logs with timing, quantity, substance. Green ◆ event markers.
  - `food` — structured entries with servings and, sometimes, macros. Plot as event markers and label the source as the food log. Macros are frequently null; say so rather than implying the entry was quantified.
  - `observation` — the same notes `get_observations_detail` returns. **Dedupe on timestamp plus text** and plot each once.
  - `sync` — device upload events. These explain where a trace starts and stops; a stream that ends mid-window usually ends at a sync boundary, not at a physiological one.
  - `document` — uploads, faxes, saved session summaries landing in the window.
  - `acquisition` — a supplement or medication arriving. An input can appear here before it has any dose log at all.
- Written observations about eating and structured food entries are **separate streams**. Either can exist without the other, so never treat one as covering the other, and label which log each fact came from.

## Nutrition rollup — `minowa:get_nutrition_report`
- Run it for the window's day whenever any food entry appears. Returns daily calorie/macro rollups, meal count, and entries flagged against the user's current dietary settings. It is the only place a dietary-setting violation surfaces — the raw food log will not show one.

## Prior analyses — `minowa:list_scored_sleep_signatures`, `minowa:list_episode_reports`
- Both take `from`/`to` and return reports whose analyzed window *overlaps* the range. Check before writing: an existing saved report over the same window is either the thing to update or the thing not to contradict. Fetch its narrative with `get_document` when one exists.

## If data hasn't synced
If the target window is recent and Garmin data is missing: queue `minowa:sync_garmin_data` (returns a job id; syncs the past week), ping `minowa:get_current_time` to confirm responsiveness, wait ~90s, then re-query. The device itself must have uploaded to Garmin first — check `device_last_sync` in the sync response.
