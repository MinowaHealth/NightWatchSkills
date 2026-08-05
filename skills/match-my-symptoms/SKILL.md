---
name: match-my-symptoms
description: Find PubMed Central literature that actually matches an unclear symptom picture — grounded in the user's own logged data, existing clinical history, and the peer-reviewed Library saved in Minowa — and hand confirmed candidates to add_reference so they're kept. Use when someone has no name yet for what they're experiencing and wants literature that might explain it — including phrasings like "find papers that match my symptoms", "what does the research say about what I'm feeling", "I don't know what's wrong with me", "check my diagnosis", "does this match anything", or a new user onboarding who describes symptoms without a name for them. Never diagnoses, rules out a condition, or recommends treatment — every candidate pattern is either cited from a saved or newly found source, with a link, or explicitly labeled unsourced general background. Do NOT use to analyze data that already has a name and a plan (health-episode-report) or to onboard someone who already knows their conditions (intake-interview).
---

# Match My Symptoms

Takes a symptom picture with no name yet and finds the PubMed Central literature that actually
matches it — first checking what's already in the user's Minowa Library, then searching PMC
directly for what isn't there yet — grounded throughout in the user's own logged data and
existing clinical history. It never names a diagnosis. It surfaces literature, cites it with a
link the user can go read, and hands over something concrete for a clinician conversation.

## Why this exists

A new user often arrives not with an established condition but with a cluster of symptoms and no
name for them. General-purpose models carry a great deal of knowledge about any given condition,
but general recall is not the same as a citation, and it can drift from current consensus in ways
a peer-reviewed article does not. This skill's job is to actually go find the matching literature
— not recall it — and keep it visibly separate from anything that is general background instead.

## Core principles (do not violate)

1. **Never diagnose.** State plainly, at the start and wherever a pattern is named, that this
   finds and cites literature — it does not diagnose, rule out, or recommend treatment. Every
   candidate pattern is framed as "worth asking your clinician about," never as a conclusion. See
   `references/non-diagnostic-framing.md`.

2. **Match against the saved Library first, then search PMC directly for what's missing.** For
   every symptom cluster, search the user's saved Library first (`minowa:search_my_data`,
   `scope: "documents"`) with the cluster as the query. Cite anything on point — title, PMCID, and
   its link. For a cluster with no Library coverage, don't stop there: search PMC directly (the
   same Europe PMC workflow `pmc-literature-finder` uses, full-text-verified) so the user actually
   gets literature that matches, not just a report that nothing was found. See
   `references/literature-workflow.md`.

3. **General background gets an explicit, separate label.** If, after checking the Library and
   searching PMC, the user still wants what general background exists, give it — but prefixed
   unmistakably ("general background, not from a saved or found source — verify independently")
   and never folded into the same sentence as a citation. A reader must always be able to tell
   which is which.

4. **Every citation carries a link.** Title and PMCID alone aren't enough to call something a
   citation — always include `https://pmc.ncbi.nlm.nih.gov/articles/<PMCID>/` (or the `url` a tool
   call already returned) so the user can go read the actual article, not just its name.

5. **Existing clinical history is the starting context.** Call `minowa:get_my_clinical_history`
   before anything else. A pattern the history already accounts for is not a gap to investigate —
   say so. A pattern it doesn't touch is the actual work of this skill.

6. **Use the user's own data before asking them to repeat themselves.** Search logged
   observations, conditions, and notes (`minowa:search_my_data`) for the symptoms already
   described somewhere. Ask directly only for what isn't already on file.

7. **Nothing is saved without confirmation.** New literature found along the way goes through
   `add_reference` only on the user's explicit pick, same as `pmc-literature-finder`. A chat
   summary of the session is offered, never saved silently.

8. **Escalation outranks the workflow.** If what comes up looks like it needs urgent care, or the
   person is in distress, stop the workflow and respond to that directly — see "When something
   serious comes up," the same standard `intake-interview` uses.

## Workflow

### 1. Orient
Say plainly, in the first message: this finds and cites literature, it does not diagnose. Ask
what's going on, in their own words — don't ask for a differential up front.

### 2. Gather context already on file
`minowa:get_my_clinical_history` (existing conditions/allergies — what's already known),
`minowa:get_health_norms` (how this person's data reads), and `minowa:search_my_data` across
`notes`/`observations`/`conditions` for anything matching what they described. Note what's
already logged versus what they're describing fresh.

### 3. Pull the relevant window, if there is one
If they point to a specific episode ("this keeps happening after I eat," "it was worst last
week"), fetch the relevant data the way `health-episode-report` would — but this skill's job is
the symptom-to-literature match, not the chart; hand off to that skill if a full report is what's
actually wanted.

### 4. Match against the Library
For each distinct symptom cluster, search the Library (`search_my_data`, `scope: "documents"`)
for saved articles that speak to it. Read the actual passage with `get_document` before citing —
a keyword match in a title is not the same as the article supporting the pattern.

### 5. Search PMC directly for what the Library doesn't cover
For a cluster with no Library coverage, don't just report the gap — go find the matching
literature. Use the `pmc-literature-finder` workflow (Europe PMC direct search, full-text-verified
candidates) or `minowa:suggest_references` as a supplementary pass. Present candidates — title,
journal, year, PMCID, link — and let the user pick what to save via `add_reference`. Keep the
search step and the pick-to-save step separate, the same discipline `pmc-literature-finder` uses.

### 6. Synthesize
For each candidate pattern: what was observed (the user's own data/words), the literature that
matches it — saved or newly found — cited with a link, and, only if asked for and clearly
labeled, what general background exists beyond that. Close with explicit next-step framing —
questions to bring to a clinician, not conclusions to act on.

### 7. Offer to save the summary
Ask if they want this kept as a chat summary (`minowa:save_chat_summary`) so it's available
context next time. Only on confirmation.

## When something serious comes up

Same standard as `intake-interview`: a possible emergency, self-harm or suicidal ideation, or
signs that the inquiry itself has become the problem all stop the workflow. Respond to that
directly, as a person — not with a structured summary — and do not resume the workflow in the
same breath.

## Voice
Plain, unhurried, no false reassurance and no alarm. Every pattern is a citation plus a question
to ask a clinician, never a verdict. Say "nothing matches this yet, even after searching PMC" as
often as it's true — an honest gap beats a confident guess.

## Reference files
- `references/non-diagnostic-framing.md` — the exact line between "finds and cites" and
  "diagnoses," with example language, including how to decline a direct "just tell me what you
  think this is."
- `references/literature-workflow.md` — the Library-first, then-PMC-direct search mechanics,
  citation format (always with a link), and how this hands off to `pmc-literature-finder`.
