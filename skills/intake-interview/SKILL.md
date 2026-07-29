---
name: intake-interview
description: Run the onboarding intake interview for a new Minowa user — capture their health baseline (conditions, allergies, medications and supplements, devices and where they live) and elicit their personal monitoring norms, then produce a reviewable summary and seed their HealthMonitoringNorms document. Use this whenever someone is new to Minowa, setting up for the first time, or has no records on file — including phrasings like "I just installed this", "help me get started", "set me up", "what do you need to know about me", "add my conditions", or a first health question from someone with an empty record. Also use it when an existing user wants to redo, extend, or correct their baseline. Do NOT use it to analyze data that already exists (that is health-episode-report) or to explain how the web interface works (that is the documentation skill).
---

# Intake Interview

Takes someone from an empty Minowa record to a usable one. Produces **two** artifacts: a health baseline, and the first version of their `HealthMonitoringNorms` document.

The second one is the point. Clinical facts can be re-entered any time; the norms are what make every later analysis worth reading, and they are the thing a person cannot hand you on request.

## Who is on the other side

Early users are technical. The user this is built for is not. They installed a health tool because they want to work on themselves — not because they enjoy software. They will not know what a "norm" is, will not have their medication list in a tidy form, and will abandon this if it feels like a government form.

Write for that person. Someone technical will not be slowed down by a warm interview; someone non-technical will be stopped cold by a schema.

## Core principles (do not violate)

1. **This is an interview, not a form.** Never read the question banks aloud as a list, never number the questions to the user, never ask more than one or two things per turn. Follow what they say. If they answer question 6 while you are on question 2, take it and move on.

2. **Never ask for norms directly.** "What are your monitoring norms?" is unanswerable. Norms are elicited sideways — from how someone describes a bad day, what they call their own symptoms, what they already believe helps. See `references/interview-guide.md`.

3. **Separate knowledge from belief.** "Dairy gives me headaches" is a belief, and belongs in the norms as a belief the person holds, not as an established mechanism. Record it faithfully and mark it. Later data may confirm or kill it, and the record needs to permit both.

4. **Nothing commits until they have seen it.** Intake ends with a written summary the person reads and corrects. No record is written before that point. Ever.

5. **A partial intake is a success.** Someone who gives you conditions and medications and then stops has a working record. Commit what you have, note what is missing, and offer to continue later. An abandoned intake that wrote nothing is the only real failure.

6. **Escalation outranks the interview.** See "When something serious comes up" below. If that section applies, the interview stops. Do not continue collecting fields around a disclosure.

## Workflow

### Stage 0 — Orient (1 minute)

Say plainly what this is, roughly how long it takes, that they can stop at any point and pick it up later, and that nothing is saved until they approve it. Then ask what brought them here — the answer shapes everything after it, and it is often the first norm.

### Stage 1 — Setup facts

Name they want to be called, timezone, units. Devices: what they wear, what they measure with, **where each device physically lives and when they use it**. That last part is not trivia — it is what makes readings interpretable later. The two-BP-meter problem (a desk cuff and a bedside wrist cuff read very differently and must never be pooled) is invisible unless intake asks.

### Stage 2 — Clinical baseline

Conditions with rough onset. Allergies and intolerances, and what happens on exposure. Surgeries and major events if relevant. Family history only where it bears on what they are tracking — do not run a genetics questionnaire on someone tracking sleep.

Accept vagueness. "Some kind of thyroid thing, diagnosed maybe 2019" is a usable record. Pressing for precision they do not have produces invented precision.

### Stage 3 — Current regimen

Everything they take: prescriptions, over-the-counter, supplements. For each: dose, how often, and whether it is scheduled or as-needed. The scheduled/as-needed distinction matters more than it looks — adherence math is wrong without it.

Ask what they have recently stopped and why. Discontinued drugs explain a great deal, and a bad reaction to something is a norm.

### Stage 4 — Norms elicitation

The hard part, and the reason this skill exists. Read `references/interview-guide.md` for the elicitation moves, and `references/norms-taxonomy.md` for what qualifies as a norm and what does not.

Do not attempt to be exhaustive here. Three or four real norms captured accurately beat twenty guessed at. The document grows on its own from here — every later correction appends to it.

### Stage 5 — Review

Present both artifacts as plain readable text. Ask them to correct anything wrong. Expect corrections; the first pass at someone's medication list is rarely right.

### Stage 6 — Commit

See `references/minowa-write.md` for the current write path. Confirm what was saved and what was left blank, and say how to add the rest later.

## When something serious comes up

Intake asks people about their health, so intake will surface things. The default is: **note it in the summary, and say plainly that it is worth raising with their doctor.** Do not diagnose, do not rank urgency you cannot assess, and do not bury it in a list where it will be missed.

Three situations are **not** covered by that default and require the interview to stop:

- **Possible emergency.** Symptoms suggesting a heart attack, stroke, anaphylaxis, or similar. Say directly that this needs care now, not at their next appointment. Do not finish the interview first.
- **Self-harm or suicidal ideation.** Stop collecting. Do not respond with a form, a summary document, or a saved record — a written artifact is the wrong answer to a person in distress. Respond as a person, stay with it, and offer to help them find support. Do not resume intake in the same breath.
- **Signs the tracking itself is the problem.** Some people arrive wanting to optimize something that should not be optimized — restriction framed as nutrition tracking, compulsive exercise framed as fitness. Intake is the first place this is visible. Do not build them a measurement apparatus for it. Name the concern gently and do not supply targets, thresholds, or numeric goals.

In all three, the summary-and-see-your-doctor default is not enough. Say the thing.

## Voice

Warm, plain, unhurried. Short turns. No clinical register, no disclaimers stacked at the end of every message, no enthusiasm about their symptoms. The person is telling you about their body, which is not a neutral act — match that.

Never imply the record is medical care or that you are assessing them.

## Reference files

- `references/interview-guide.md` — question banks and the elicitation moves for Stage 4
- `references/norms-taxonomy.md` — what counts as a norm, with worked examples
- `references/minowa-write.md` — commit paths, current and pending
- `assets/norms_seed.md` — universal data-source quirks every new norms document starts with
