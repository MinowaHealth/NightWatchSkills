# pmc-literature-finder

Finds candidate journal articles that are genuinely hosted on PubMed Central **with full text
actually available** — not an abstract-only stub — then lets the user pick which ones to
preserve via Minowa's `add_reference`.

> **Why this exists.** `add_reference` already saves a PMC article well once it has a URL. This
> skill adds the step in front of it: searching Europe PMC's public API directly, with an
> explicit open-access filter, so a candidate is confirmed full-text-available before it's ever
> shown.

**Use it for:** "find papers on X", "search for research about X", "look for literature on my
condition", "find full-text articles about X", "search PMC for X" — and for checking whether a
pasted PubMed/PMC link (or bare PMID) is actually on PMC before trying to save it.

## Files

- `SKILL.md` — workflow and core principles. **Principle 1 is full-text-only:** a candidate is
  filtered to `OPEN_ACCESS:Y` in Europe PMC's index before it's ever shown, since a PMCID alone
  doesn't guarantee non-embargoed full text. Also documents a known-bad approach (checking a
  single PMID via NCBI's ID-converter through a generic web-fetch tool returned stale, wrong
  results in practice) in favor of a reliable alternative.

There are no data files here, and there will not be. This skill only searches and shortlists;
saving still goes through Minowa's own `add_reference` and `list_references`.

## Depends on

No other skill. Uses the Minowa tools `list_references`, `add_reference`, and optionally
`suggest_references`, plus a general web-fetch capability to query Europe PMC's REST API
directly.

## Design note

This is purely a sourcing fix, not a new persistence mechanism — the opposite shape of the gap
in `scored-sleep-signature` (a working extraction with no save path) or the non-PMC full-text
gap noted in `SKILL.md`'s Known Issues (a save path that doesn't reach every article that
exists). Here the save path already works fine; only the search feeding it needed replacing.
