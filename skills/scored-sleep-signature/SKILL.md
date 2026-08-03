---
name: scored-sleep-signature
description: Analyze the pre-sleep RUN-UP of a Garmin-scored sleep night to extract its "signature" — subjective state, physiological wind-down (HR/stress trajectory), inputs (food, doses, supplements), and timing — then classify the night's quality from the scored architecture so good-approach and poor-approach nights become comparable. Use whenever the user wants to understand HOW they got into a night's sleep, what preceded a good or bad scored night, the "run-up" / "wind-down" / "approach" before sleep, why a night landed the way it did, or to compare the lead-in across nights — including "how did I get into that condition", "what did I do differently before the good night", "figure out the run-up", "sleep signature", or "compare the approach across nights". Companion to health-episode-report, which charts the sleep window itself while this characterizes the hours BEFORE onset.
---

# Scored Sleep Signature

Given a Garmin-scored sleep night, this skill reconstructs the **run-up** — the hours before sleep onset — and distills a *signature*: the repeatable combination of subjective state, physiological wind-down, inputs, and timing that led into that night. It then classifies the night's quality from the scored architecture and produces a signature card. Accumulating signatures across nights — which is what would make the ingredients of a good approach visible — requires server-side storage that does not exist yet; see **Persistence** below.

It is the companion to **health-episode-report**. That skill answers "what did the sleep look like?" (hypnogram, HR/stress inside the window). This skill answers "how did they get there?" (the approach). They share the Minowa fetch layer, the minutes-since-midnight coordinate system, and the norms. Read `health-episode-report/references/minowa-data.md` for the fetch quirks (offset HR/stress clocks, stress suppressed during movement, wrist-vs-arm BP) rather than re-deriving them.

## Core principles (do not violate)

1. **Scored intervals only.** A signature is extracted **only** for nights Garmin actually scored — i.e. `get_sleep_events_detail` returns real sleep stages (a hypnogram). Inferred or unscored rest never becomes a signature or a quality data point; those stay in health-episode-report, which handles inferred nights fine. The comparison's whole validity rests on tying an approach to a *scored* outcome — an inferred outcome would poison it. **Known bias to state every time:** the worst nights are often the ones Garmin cannot score (too short or too fragmented), so the scored set skews toward better-to-middling nights. The "poor" end of the comparison is *poorer-scored*, not the true blowouts — say so, and don't let a calm-looking scored "poor" night masquerade as a bad night.

2. **The signature is descriptive, never prescriptive.** Cross-night patterns are *observed associations*, not causes. Never assert that an input produced a good or bad night. A signature surfaces "these features co-occurred with good nights"; it never says "do X to sleep well." This restraint is the whole point — it keeps the comparison honest enough to be worth trusting.

3. **This skill stores nothing.** It reads from the Minowa server and writes back to the Minowa server. No norms, no log, no record of any night is ever read from or written to a file in this package or anywhere else on disk. If something needs to persist and has no server tool, that is a server requirement — see **Persistence** — never a local file.

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
Call `minowa:get_health_norms` before writing. Prior signatures are **not** retrievable — there is no server store for them yet (see **Persistence**). Treat each run as n = 1: do not assert a cross-night pattern you have no way to re-read, and say so rather than implying a history you do not have.

### 4. Extract the signature along the fixed axes
See `references/signature-axes.md` for the schema and how to compute each axis (especially the wind-down HR/stress slope over the final 60–90 min). The axes: **subjective approach state**, **physiological wind-down**, **inputs & timing**, **onset timing**, and **night quality** (read from the scored architecture relative to the user's own baseline — GOOD / TYPICAL / POORER — using the scored totals, not re-derived).

### 5. Produce the signature card
A short structured summary — the five axes, each one or two lines — plus a single "how they got here" sentence in the user's voice. Optionally render a run-up panel by reusing `health-episode-report/assets/report_template.html` over the run-up window with an onset marker (an `EVENTS` entry `{type:"obs", label:"onset"}`); this is presentation only and never changes the analysis.

### 6. Hand the card to the user
Present the card. Do not write it anywhere — see **Persistence**.

## Persistence — blocked on server support

The accumulating comparison this skill is named for **cannot run yet.** There is no MCP tool that stores a sleep signature: `add_reference` takes PubMed URLs only, `save_chat_summary` is for session summaries, and `save_episode_report` is shaped for episode reports over an analyzed window, not for a per-night signature record with quality buckets and a cross-night associations section.

What the server needs to expose before this skill is whole:

- a **write** call that stores one signature — night date, run-up window, the five axes, quality bucket, and the verbatim subjective note;
- a **read/list** call that returns prior signatures filtered by quality bucket, so a run can state its n;
- somewhere durable for the **emerging associations** synthesis, which is derived across nights rather than belonging to any one of them.

Until those exist: produce the card, tell the user it is not being retained, and write nothing to disk. Do **not** work around this by appending to a file in the skill folder, by folding per-night records into the norms document, or by re-saving the package — the skills hold no data, and a workaround here would put health records into a public artifact.

## What good output looks like
- The verbatim subjective note is present and quoted.
- The wind-down is quantified (HR level + slope, stress band) over the final hour, and contrasted with the earlier evening.
- Food and dose timing are stated as facts with gaps-to-onset; no causal claims beyond what the norms license.
- Night quality is tied to the scored numbers.
- The card is one tight, self-contained read — it does not lean on nights it cannot retrieve.
- If the user expects the signature to be saved, they are told plainly that it is not, and why.
