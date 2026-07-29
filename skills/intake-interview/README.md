# intake-interview

Onboards a new Minowa user. Runs a structured interview that captures their health baseline
(conditions, allergies, medications and supplements, devices and where they physically live) and
elicits their personal **monitoring norms**, then produces a reviewable summary and seeds the first
dated version of their `HealthMonitoringNorms` document.

**Use it for:** "I just installed this," "help me get started," "set me up," "what do you need to
know about me," or a first health question from someone with an empty record. Also for re-running or
extending an existing baseline.

**Not for:** analyzing data that already exists (`health-episode-report`) or explaining the web
interface (documentation skill, pending).

## Files

- `SKILL.md` — the six stages, the core principles (interview not form; never ask for norms
  directly; separate knowledge from belief; nothing commits before review; a partial intake is a
  success), and the escalation rules.
- `references/interview-guide.md` — question banks per stage, and the six elicitation moves for
  getting norms out of someone who has never heard the word. **Raw material, not a script.**
- `references/norms-taxonomy.md` — the six categories of norm with worked examples, what is *not* a
  norm, how entries are written and dated, and how a stale rule is retired.
- `references/minowa-write.md` — the commit path. v1 writes documents via `save_chat_summary`;
  v2 writes structured records and dated norms versions once the server endpoints land. **This file
  is expected to change.**
- `assets/norms_seed.md` — the starting norms document. Pre-loaded with the universal data-source
  quirks (Garmin scoring lag, absent respiratory rate, offset HR/stress clocks) so a new user's
  document is useful on day one and the interview only spends time on what is personal.

## Output

Two artifacts, both shown to the person for correction before anything is written:

1. A health baseline summary.
2. Version one of their `HealthMonitoringNorms` document, dated, with each rule carrying its
   inception date.

## Notes

- The norms half is the point. Clinical facts can be re-entered any time; norms are what make later
  analysis worth reading, and they cannot be requested directly.
- Escalation outranks the interview. Possible emergency, self-harm, and tracking that is itself the
  problem each stop it — the summary-and-see-your-doctor default does not cover them.
- Built for someone who wants to work on themselves, not on software. Early users are technical;
  the target user is not.
