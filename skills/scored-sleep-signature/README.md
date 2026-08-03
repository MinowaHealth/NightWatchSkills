# scored-sleep-signature

Reconstructs the pre-sleep **run-up** of a Garmin-**scored** night and distills its *signature* — the
subjective state, physiological wind-down (HR/stress trajectory), inputs (food, doses, supplements), and
timing that led into the night — then classifies the night's quality from the scored architecture.

> **Status: partially blocked.** The per-night card works today. The accumulating comparison does not:
> there is no MCP tool that stores a sleep signature, and this skill stores nothing locally. See
> "Persistence" in `SKILL.md` for the server calls required.

Companion to **health-episode-report**: that skill characterizes the sleep window itself; this one
characterizes the hours **before** onset.

**Use it for:** "how did I get into that condition," "what did I do differently before the good
night," "figure out the run-up," "sleep signature," "compare the approach across nights."

## Files

- `SKILL.md` — workflow and core principles. **Principle 1 is scored-only:** a signature is extracted
  only for nights Garmin actually scored; unscored/inferred rest never becomes a signature
  (those stay in health-episode-report). Also encodes the known selection bias — the worst nights go
  unscored, so the scored set skews toward better nights, and "poorer-scored" ≠ blowout.
- `references/signature-axes.md` — the five extraction axes (subjective approach state; wind-down;
  inputs & timing; onset timing; scored quality) and how to compute each.

There are no data files here, and there will not be. Norms come from `minowa:get_health_norms`;
anything else that needs to persist is a server requirement.

## Depends on

`health-episode-report` installed alongside it — it reuses that skill's Minowa fetch conventions
(`references/minowa-data.md`), its minutes-since-midnight coordinate system and report template (for
an optional run-up panel). Norms are fetched from the server by both skills, not shared through the
filesystem.

## Design note

The comparison is descriptive, not prescriptive: it surfaces features that co-occur with good scored
nights, never "do X to sleep well." Restricting to scored nights is what keeps every entry anchored to
a measured outcome — and it has already changed the picture (a calm wind-down separated a good night
from a *wired, unscored* one, but did **not** separate two scored nights; commitment at lay-down did).
