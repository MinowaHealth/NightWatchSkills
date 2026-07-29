# Norms taxonomy

What belongs in a `HealthMonitoringNorms` document, what does not, and how entries are written.

A norm is **a standing instruction about how to read this person's data.** It is not a health fact. "Has asthma" is a clinical record. "Wheezing on waking is baseline for this person and not an event" is a norm.

The test: *would getting this wrong cause a bad inference later?* If yes, it is a norm.

## The six categories

### 1. Sequences and causation

Orderings the person already knows about their own body.

> A bowel movement will typically follow eating. Do not present this as a notable finding.

Includes the negative form — things that look linked and are not, and things that must not be given a causal reading. These are as valuable as the positive ones and much harder to elicit.

### 2. Vocabulary

The person's own words for their own experiences.

> "<their word>" is their term for <the sensation it names>.

Without this, their language is unintelligible to the tool, or worse, quietly mistranslated.

### 3. Symptoms and remedies

What counts as a symptom rather than a neutral state, and the treatment escalation.

> <Symptom> is a symptom, not a neutral state. The remedy is a two-step escalation: <step one> first, <step two> only if step one fails. "Skipped <step two>" therefore means step one worked — it is not itself therapeutic.

Note the shape: the norm exists because the obvious reading was wrong and had to be corrected. Most good norms look like this.

### 4. Instruments and their quirks

How this person's equipment behaves and how to read it.

> Two BP meters — an upper-arm cuff at the desk, a wrist cuff by the bed. Separate datasets, never pooled. The wrist reads much higher and is used only lying still.

Anything with more than one instrument for the same measurement needs a norm, or the two series will be averaged and both ruined.

### 5. Baselines

What is ordinary for this person, so deviation means something.

> Resting heart rate runs 80–85. Readings in that band are not elevated for this person.

### 6. Beliefs under test

What the person thinks is true, recorded as belief.

> They believe <input> triggers <symptom>. Unconfirmed — watch for it, do not assert it.

Always marked. The value is in flagging what to watch, and in being able to retire it cleanly if the data disagrees.

## What is not a norm

- **Clinical facts.** Conditions, allergies, medications belong in the health record.
- **One-off events.** A bad night in March is not a rule. Norms are things that recur.
- **Universal product quirks.** Garmin's scoring lag applies to every user — it ships in the seed document (`assets/norms_seed.md`) rather than being elicited from each person.
- **Anything the person has said once, in passing, without conviction.** Norms are expensive to unlearn. Let a pattern earn its place.

## How entries are written

One line, plain, imperative where it is an instruction. Written so that someone reading it cold applies it correctly without the backstory.

Every rule carries the date it entered the file, as a trailing marker:

> The wrist cuff is used only when lying still, so wrist readings appear only during rest periods. *(YYYY-MM-DD)*

Rules seeded with the product are marked *(seeded)* rather than dated — they did not come from this person.

The document itself is stored as a dated version, and earlier versions remain retrievable, so a rule's history is recoverable by diffing. The per-rule date exists because nobody will do that mid-narrative: the version handed to you is the current one, and anything you need at inference time has to be legible in that document alone. A rule written at intake and never revisited is a weaker claim than one that has survived three corrections, and the date is what makes that difference visible.

## Retiring a rule

Rules go stale — a regimen changes, a drug is discontinued, a suspected pattern is checked and fails. Do not silently drop them out of the next version. Move the rule to the **Retired** section with its original date, the date it was retired, and one line on why:

> ~~&lt;rule as originally written&gt;~~ *(YYYY-MM-DD → retired YYYY-MM-DD: &lt;why&gt;)*

Retired rules are not applied. They live in the current document so the reasoning is visible without pulling old versions, and so the same wrong inference does not get re-derived and re-added a year later.

Good:

> The wrist cuff is used only when lying still, so wrist readings appear only during rest periods.

Bad:

> The user mentioned during intake that they sometimes use a different blood pressure monitor depending on where they are, which may affect readings.

The second one is hedged, vague, and gives the reader nothing to act on.

Where an entry came from a correction — someone saying "no, that's wrong" — say what the wrong inference was. The norm is more durable when it carries the error it prevents.

## Intake-specific note

Intake is writing **version one**. It will be thin, and that is correct. Three or four accurate norms are a good intake. The document is designed to grow — every later session appends to it — and a sparse honest first version is far better than a padded one full of guesses that later work has to unpick.

Do not invent norms to fill categories. An empty category is fine.
