# Signature axes

Extract every scored night along these five fixed axes. Keep each to one or two lines in the card.

**Thresholds are not in this file.** What counts as a settled heart rate, a low stress band, an early lay-down, or a good night is personal, and it sharpens as nights accumulate. Fetch it at runtime with `minowa:get_health_norms`. Never hardcode a value here — treat anything numeric below as a placeholder shape.

## 1. Subjective approach state (verbatim)
Quote the bedtime-adjacent note rather than paraphrasing it — the user's own wording is the signal, and short phrases distinguishing a decisive wind-down from an ambivalent one tend to recur. Build that vocabulary from their log, not from assumption.

Also record, where the user tracks them: any reaction flagged near the last meal, and whether symptoms were present at bedtime. A symptom that occurred earlier in the day and had resolved by bedtime does not count against the approach — record when it cleared. Symptom onset and offset times are usually soft markers; check the norms for how precisely they can be read.

## 2. Physiological wind-down (final 60–90 min before onset)
The spine of the signature. Compute:

- **HR level + slope**: mean HR over the last 60 min, and whether it is descending, flat, or climbing versus the 3–4 h earlier evening.
- **Stress band**: the range stress occupies over the last 60 min. Stress is suppressed while the user is moving, so a wind-down spent on their feet will carry little or no stress data — a measurement condition, not a finding (see `health-episode-report/references/minowa-data.md`).

Compare both against the bands in the norms. Note evening HR spikes (moving, eating, taking a reading) separately — a good approach can still have earlier spikes as long as the **final** hour settles. What matters is the last-hour floor, not a monotonic descent.

## 3. Inputs & timing
- **Last food → onset gap**, and any reaction logged against that meal.
- **Inputs the user tracks deliberately** — note presence, absence, and timing. Absence is data: record it explicitly. Read each input only through whatever chain the norms establish for it, and assert nothing beyond that. Some inputs are, per the norms, to be logged as plain facts with no causal linkage at all — check before writing a sentence that implies one.
- **Night-stack composition** and any sedating medications, with clock times. Name them from the log, never from an assumed stack.

## 4. Onset timing
Lay-down and onset clock times versus the user's own habitual range, and total time in bed.

## 5. Night quality (from scored architecture, relative to their own norm)
Read straight from the scored totals — do NOT re-derive from HR:

- efficiency (asleep ÷ in-bed), deep minutes, REM minutes, number of awakenings, total in-bed.
- Label **GOOD / TYPICAL / POORER** relative to the user's own baseline, which the norms describe. Judge against that baseline, not textbook population norms. Use "poorer-scored," not "poor" — the genuinely bad nights are often unscored and therefore absent from this set (see SKILL principle 1).
- **If the night is unscored, there is no signature.** Do not extract one from an unscored night — stop and offer a health-episode-report instead.
- **If the card is saved (SKILL.md Persistence),** write this axis into `narrative_text` as its own line reading exactly `Quality: GOOD`, `Quality: TYPICAL`, or `Quality: POORER` — no other wording on that line. Cross-night retrieval greps for that exact string, so a paraphrase here silently drops the night from every future comparison.

## What separates scored nights

This is the question the comparison exists to answer, and the answer is per-user and provisional. It belongs in the user's server-side record — retrieved fresh each run via `list_scored_sleep_signatures` (SKILL.md step 4) — never hardcoded in this file.

Two framing rules generalize:

- **Compare scored against scored.** Setting a good scored night against an *unscored* one is misleading: nearly every axis appears to separate, because the real difference is "did they sleep at all." The honest question is what separates a **good scored** night from a **poorer scored** one.
- **State the n.** A separation is co-occurrence across a handful of nights, not a cause. Say how many scored nights the claim rests on, and report axes that fail to separate as such — a null result narrows the search. The n is whatever `list_scored_sleep_signatures` actually returns for the range the user chose — 1 when nothing prior comes back (including the first time this skill's persistence is ever used), more once signatures accumulate. Never state an n you did not just retrieve.

## Worked example (illustrative — invented, not anyone's record)

Shape only. Every value below is a placeholder; never treat one as a baseline.

1. Subjective: "&lt;verbatim bedtime note&gt;" (H:MM PM). Bedtime symptoms: none. Earlier symptom cleared by &lt;time&gt;.
2. Wind-down: after evening spikes to &lt;bpm range&gt;, HR settled to &lt;range&gt; and stress to &lt;band&gt; across the final hour.
3. Inputs: last food &lt;description&gt; ~&lt;n&gt; h before lay-down, no reaction logged; &lt;tracked input&gt; absent; &lt;other logged inputs as plain facts, with times&gt;.
4. Onset: lay-down ~H:MM PM / asleep ~H:MM PM — &lt;earlier / later&gt; than their habitual range; &lt;total&gt; in bed.
5. Quality: &lt;GOOD / TYPICAL / POORER&gt; for them — &lt;consolidation&gt;, &lt;deep&gt; deep, &lt;rem&gt; REM, &lt;n&gt; awakenings.
