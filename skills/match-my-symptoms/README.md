# match-my-symptoms

Takes a symptom picture with no name yet and finds the PubMed Central literature that actually
matches it — first checking the user's saved Minowa Library, then searching PMC directly for what
isn't there yet — grounded throughout in the user's own logged data and existing clinical
history. It never names a diagnosis; it finds literature, cites it with a link, and hands over
something concrete for a clinician conversation.

> **Why this exists.** A general-purpose model carries a great deal of general knowledge about
> any given condition, and that recall is easy to mistake for something more authoritative than
> it is. This skill actually goes and finds the matching literature instead of recalling it, and
> keeps "matched by a real search, with a link" and "general background" visibly separate.

**Use it for:** "find papers that match my symptoms," "what does the research say about what I'm
feeling," "I don't know what's wrong with me," "check my diagnosis," "does this match anything" —
and for a new user during onboarding who describes symptoms without a name for them.

**Not for:** analyzing data that already has a name and a plan (`health-episode-report`), or
running first-time onboarding for someone who already knows their conditions
(`intake-interview`).

## Files

- `SKILL.md` — the workflow and core principles (never diagnose; Library first, then search PMC
  directly for what's missing; every citation carries a link; general background explicitly
  labeled; existing clinical history as starting context; nothing saved without confirmation) and
  the escalation rules.
- `references/non-diagnostic-framing.md` — the exact line between "finds and cites" and
  "diagnoses," with example language, including how to decline a direct "just tell me what you
  think this is."
- `references/literature-workflow.md` — the Library-first, then-PMC-direct search mechanics, the
  always-include-a-link citation format, and the hand-off to `pmc-literature-finder`.

## Depends on

`pmc-literature-finder`, for the actual PMC search mechanics when the Library has nothing on a
pattern — this skill calls into that workflow rather than duplicating it. Otherwise uses Minowa's
own `get_my_clinical_history`, `get_health_norms`, `search_my_data`, `get_document`,
`suggest_references`, `add_reference`, and `save_chat_summary`.

## Output

A structured summary: per candidate pattern, what was observed, and the literature that matches
it — saved or newly found — cited by title, PMCID, and link, plus explicit next-step framing as
questions for a clinician, never a conclusion. Offered, not forced, as a saved chat summary at the
end.

## Notes

- Same escalation standard as `intake-interview`: possible emergency, self-harm risk, or the
  inquiry itself becoming the problem all stop the workflow immediately.
- Holds no data of its own. Everything it reads comes from Minowa at runtime; nothing is written
  except through Minowa's own save calls, and only on explicit confirmation.
- Renamed from an earlier working name, `check-my-diagnosis` — the new name reflects the actual
  deliverable: literature that matches the symptoms, not just an organized summary of them.
