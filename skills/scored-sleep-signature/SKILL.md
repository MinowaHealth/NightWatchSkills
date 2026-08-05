---
name: scored-sleep-signature
description: Analyze the pre-sleep RUN-UP of a Garmin-scored sleep night to extract its "signature" — subjective state, physiological wind-down (HR/stress trajectory), inputs (food, doses, supplements), and timing — then classify the night's quality from the scored architecture so good-approach and poor-approach nights become comparable. Use whenever the user wants to understand HOW they got into a night's sleep, what preceded a good or bad scored night, the "run-up" / "wind-down" / "approach" before sleep, why a night landed the way it did, or to compare the lead-in across nights — including "how did I get into that condition", "what did I do differently before the good night", "figure out the run-up", "sleep signature", or "compare the approach across nights". Companion to health-episode-report, which charts the sleep window itself while this characterizes the hours BEFORE onset.
---

# Scored Sleep Signature

Given a Garmin-scored sleep night, this skill reconstructs the **run-up** — the hours before sleep onset — and distills a *signature*: the repeatable combination of subjective state, physiological wind-down, inputs, and timing that led into that night. It then classifies the night's quality from the scored architecture and produces a signature card. The accumulating comparison this skill is named for — what the ingredients of a good approach look like across many nights — now runs for real: saved signatures are retrievable, so a run can state an honest n instead of always reporting n = 1. See **Persistence** below for the mechanics and what stays out of scope.

It is the companion to **health-episode-report**. That skill answers "what did the sleep look like?" (hypnogram, HR/stress inside the window). This skill answers "how did they get there?" (the approach). They share the Minowa fetch layer, the minutes-since-midnight coordinate system, and the norms. Read `health-episode-report/references/minowa-data.md` for the fetch quirks (offset HR/stress clocks, stress suppressed during movement, wrist-vs-arm BP) rather than re-deriving them.

## Core principles (do not violate)

1. **Scored intervals only.** A signature is extracted **only** for nights Garmin actually scored — i.e. `get_sleep_events_detail` returns real sleep stages (a hypnogram). Inferred or unscored rest never becomes a signature or a quality data point; those stay in health-episode-report, which handles inferred nights fine. The comparison's whole validity rests on tying an approach to a *scored* outcome — an inferred outcome would poison it. **Known bias to state every time:** the worst nights are often the ones Garmin cannot score (too short or too fragmented), so the scored set skews toward better-to-middling nights. The "poor" end of the comparison is *poorer-scored*, not the true blowouts — say so, and don't let a calm-looking scored "poor" night masquerade as a bad night.

2. **The signature is descriptive, never prescriptive.** Cross-night patterns are *observed associations*, not causes. Never assert that an input produced a good or bad night. A signature surfaces "these features co-occurred with good nights"; it never says "do X to sleep well." This restraint is the whole point — it keeps the comparison honest enough to be worth trusting.

3. **This skill stores nothing locally.** It reads from the Minowa server and writes back to the Minowa server, and only through the calls named in **Persistence**. No norms, no log, no record of any night is ever read from or written to a file in this package or anywhere else on disk. A saved signature lives in the user's Minowa document collection, never in this repo, and is written only after the user explicitly asks — the same rule as `update_health_norms` and `save_episode_report`, never proactively.

4. **Call `minowa:get_health_norms` before interpreting anything, and apply what it returns.** The user's norms live in versioned server storage, not in this package — they carry the per-input rules (which inputs may be read through a causal chain and which are plain logged facts with no linkage at all), how precisely symptom onset and offset times can be read, and how their BP meters behave. Do not interpret an input, a symptom time, or a reading until you have those rules in front of you, and do not carry a remembered rule forward from a previous session.

5. **The user sets the night and the run-up length — never infer them from staging alone.** Onset can be read from the scored block, but the run-up window is the user's call (default 6 h before onset). If the anchor is fuzzy ("the good night", "before that"), pin it to concrete clock times first.

6. **Subjective state is a first-class signal, captured verbatim.** Short phrases distinguishing a decisive wind-down from an ambivalent one are different signatures and must be quoted, not paraphrased — build that vocabulary from the user's own log. The felt approach often predicts the night better than any single number.

7. **The user's voice, clinical, no hedging on what the data shows** — but explicitly tentative about cross-night causation. State the wind-down numbers and the logged inputs plainly; hold the "why" loosely.

## Workflow

### 1. Establish the night and confirm it is scored
Confirm the scored night with the user (or take it from a just-run episode report). Pull `minowa:get_sleep_events_detail` around it. **Gate here:** if it returns no real sleep stages (empty, or only an `awake`/inferred stretch), STOP — there is no signature to extract. Tell the user the night is unscored, offer a health-episode-report instead, and record nothing. If it *is* scored, read **onset** = the start of the first sustained sleep stage after any settling-awake (not the brief pre-onset light). The run-up window is `[onset − N h, onset]`, default `N = 6`; honor an explicit user span. All timestamps timezone-aware ISO 8601 in the user's local offset; delegate date math to `minowa:get_current_time` / `date_math`.

### 2. Sweep the run-up (self-fetch)
Across `[onset − N h, onset]`. **Every stream, at its widest filter** — a signature built on a partial fetch describes an approach that did not happen. See `health-episode-report/references/minowa-data.md` for the per-call detail and close its coverage checklist here too.
- **HR + stress** — `minowa:get_garmin_minute_detail` (offset clocks: two sparse series, `parsing:false`; stress uses `spanGaps:12`). This is the spine of the signature.
- **Observations** — `minowa:get_observations_detail`, verbatim. The subjective-state notes live here.
- **All inputs** — `minowa:get_recent_activity` with **`kind:"all"`**, never a single kind. One call returns medication, food, observation, sync, document and acquisition; naming one kind silently drops the other five with no gap reported. From it: the night-stack composition and any sedating medications with timing, named from the log rather than an assumed stack; and the **last food before onset** with its gap to onset, plus any reaction logged against that meal. For inputs the user tracks deliberately, record absence as explicitly as presence. Dedupe the observation entries against `get_observations_detail`.
- **Nutrition** — `minowa:get_nutrition_report` for the day whenever food appears in the run-up; it is the only place a dietary-setting violation surfaces.
- **Vitals** — `minowa:get_vitals_timeline` with **`include` omitted**, so BP, weight, temperature and glucose all return. Tag BP arm vs wrist, apply the discard rule within-meter.

### 3. Read the norms
Call `minowa:get_health_norms` before writing, and apply what it returns.

### 4. Retrieve prior signatures for comparison
Ask the user how far back the comparison should reach if it isn't obvious (all saved signatures, the last several, a specific date range) — same rule as the run-up length in principle 5, the user's call, not an inferred default. Call `minowa:list_scored_sleep_signatures` with `from`/`to` covering that range and `latest_only:true`. For each hit, `minowa:get_document` the `document_id` to pull its `narrative_text` (the full HTML is presentation, not what you parse) and read off the `Quality:` line and the axis lines written in the format fixed in `references/signature-axes.md`. This is the accumulating comparison the skill is named for — build the n from what actually comes back, not from memory of a previous session. If nothing is returned, this is the first saved signature: say so plainly and proceed as n = 1, exactly as before.

### 5. Extract the signature along the fixed axes
See `references/signature-axes.md` for the schema and how to compute each axis (especially the wind-down HR/stress slope over the final 60–90 min). The axes: **subjective approach state**, **physiological wind-down**, **inputs & timing**, **onset timing**, and **night quality** (read from the scored architecture relative to the user's own baseline — GOOD / TYPICAL / POORER — using the scored totals, not re-derived). Where prior signatures were retrieved in step 4, note which axes separate this night from the comparison set and which do not — a null result narrows the search and belongs in the card as much as a positive one.

### 6. Produce the signature card
A short structured summary — the five axes, each one or two lines — plus a single "how they got here" sentence in the user's voice, and, when prior signatures were retrieved, the cross-night read with its n stated. Optionally render a run-up panel by reusing `health-episode-report/assets/report_template.html` over the run-up window with an onset marker (an `EVENTS` entry `{type:"obs", label:"onset"}`); embed it in the card's HTML if produced — this is presentation only and never changes the analysis.

### 7. Hand the card to the user
Present the card.

### 8. Save the signature, only if the user asks
`minowa:save_scored_sleep_signature` persists the finished card into the document library — call it only after the user has explicitly said to keep this one, never proactively, same rule as `update_health_norms` and `save_episode_report`. See **Persistence** for the field mapping and the pitfalls carried over from that tool's pattern.

## Persistence

Saving and retrieving signatures runs through three MCP tools: `save_scored_sleep_signature`, `list_scored_sleep_signatures`, and `update_scored_sleep_signature_segment`. They are shaped as a general day-scoped report store with optional episode-candidate segmentation (the same mechanism `health-episode-report` uses for `list_episode_reports`), not as a purpose-built five-axis record — so this skill maps its own concepts onto that shape deliberately, rather than using every field the tool offers:

- **`day`** is the calendar date the run-up *starts* on (the evening/bedtime date), not the date the user woke up. A run-up that crosses midnight is still "that night" by its start.
- **`window_start` / `window_end`** are the actual run-up window, `[onset − N h, onset]` — the same bounds used for the fetch in step 2, not the full calendar day. The tool's own example title ("Full day — …") describes a different caller's use of this same store; this skill's windows are run-up-length, not day-length.
- **`title`** names it as a signature, not a day report, e.g. a shape like `Sleep signature — <date> · run-up <H:MM PM> → <H:MM AM>`.
- **`report_html`** is the signature card itself (step 6), self-contained, optionally with the run-up panel embedded.
- **`narrative_text`** is the plain-text form of the five axes — this is what search and step 4's retrieval both depend on, so keep the format stable: one line per axis, and the quality axis written as exactly `Quality: GOOD`, `Quality: TYPICAL`, or `Quality: POORER` on its own line. Do not paraphrase that line between runs — retrieval greps for the exact word.
- **`segmentation`** is left empty (`[]` or omitted). It exists so a day-spanning report can flag candidate episodes from HR/stress excursions for later spin-off into an episode report — a run-up window is neither day-spanning nor the place that decides episode candidates, so this skill does not populate it. `update_scored_sleep_signature_segment` is correspondingly out of scope for this skill; leave it to whatever workflow does populate segmentation.
- **Pass the literal content, not a filename.** `report_html` and `narrative_text` take the actual HTML and text — the tool does not read a path off disk. A filename string passed by mistake still returns a document id, so the mistake looks like success.
- **Superseding a correction.** If the card changes after the first save, pass `supersedes_document_id` (the id the earlier save returned) and increment `version`, rather than creating an unrelated second document — otherwise step 4's retrieval double-counts the night.

None of this licenses working around the tool: no per-night record is ever appended to a file in this package, folded into the norms document, or otherwise kept on disk. If a future need doesn't fit this store, that is a server requirement to raise, not a reason to improvise local storage.

## What good output looks like
- The verbatim subjective note is present and quoted.
- The wind-down is quantified (HR level + slope, stress band) over the final hour, and contrasted with the earlier evening.
- Food and dose timing are stated as facts with gaps-to-onset; no causal claims beyond what the norms license.
- Night quality is tied to the scored numbers.
- When prior signatures exist, the card states its n and which axes did or didn't separate — never implying a history it didn't actually retrieve.
- The card is one tight, self-contained read.
- If the user wants the signature kept, it is saved through `save_scored_sleep_signature`, once, after they confirm — and they're told when it wasn't (they didn't ask).
