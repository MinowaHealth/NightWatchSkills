# Commit path

Where intake's two artifacts go. **This file is expected to change** — the server-side write
surface is being built. Everything else in the skill is stable; only this step swaps.

## Current state of the tool surface

As of this writing, every Minowa tool touching profile, conditions, allergies, medications,
observations, or vitals is **read-only**. There are write paths — `save_chat_summary`,
`save_episode_report`, `save_scored_sleep_signature`, `update_scored_sleep_signature_segment`,
`update_health_norms`, `add_reference`, `sync_garmin_data`, `set_input_components`, `send_feedback`
(see `minowa-guide/references/mcp-tool-reference.md` for the complete, current list) — but none of
them write a structured clinical record.

So intake cannot commit structured clinical records yet.

## v1 — available today

Commit both artifacts as documents via `save_chat_summary`:

1. **Health baseline** — the confirmed summary as markdown: setup facts, conditions, allergies,
   regimen with doses and schedules, bundles, recent discontinuations.
2. **HealthMonitoringNorms** — `assets/norms_seed.md` with the seeded quirks retained and the
   elicited personal norms filled in under their headings, empty sections left as-is.

Nothing is structured, but the information is durable and readable by every other skill. Tell the
person plainly that this is a written record rather than filled-in fields, and that the fields
come later.

## Norms storage (shipped)

Norms live in versioned document storage on the server. The storage model is **dated documents, not
database rows**: each correction writes a new dated `HealthMonitoringNorms` document, earlier versions
remain retrievable, and the most recent one is what gets supplied for reading. Retirement is therefore
just absence from the newest version — but see the taxonomy: retired rules are moved to a `Retired`
section rather than dropped, so the reasoning stays legible in the current document.

- **Reading**: fetch the current version with `minowa:get_health_norms`. Both analysis skills do this
  every run; neither reads a file, and no skill reaches into another skill's folder by path. Historical
  versions are available with `list_health_norms_history` when a rule's provenance is in question, but
  the current version is the working document.
- **Writing**: intake creates version one and stamps it with the intake date. It does not extend an
  existing document — if one already exists, this is a re-run, and the person should be asked whether
  to build on it or start over.
- **Structured clinical records**: once profile / condition / allergy / medication endpoints exist,
  Stage 6 writes those directly and the baseline document becomes a human-readable companion rather
  than the storage.

### Open

- Exact tool names and signatures for reading current, reading historical, and writing a new version.
- **Same-day collisions.** Two corrections in one day produce two documents with the same date stamp.
  Needs either a time component or a sequence suffix, or the second write shadows the first.
- Whether the current version arrives in context automatically or must be fetched explicitly. This
  changes one line in each consuming skill: "the norms are already present, apply them" versus
  "fetch the norms before writing narrative."

## Invariant

Whatever the path: **nothing is written before the person has read the summary and confirmed it.**
That does not change when the endpoints do.
