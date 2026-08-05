---
name: pmc-literature-finder
description: Search for genuinely full-text PubMed Central articles on a health topic, then hand confirmed picks to Minowa's add_reference to preserve in the user's Library. Use whenever the user wants to find research, papers, literature, or studies about a condition or topic — including "find papers on X", "search for research about X", "look for literature on my condition", "find full-text articles about X", or "search PMC for X". Also use to check whether a pasted PubMed/PMC link (or bare PMID) is actually hosted on PMC before trying add_reference on it. Companion to — not a replacement for — Minowa's built-in suggest_references and add_reference: this skill searches Europe PMC directly and filters to confirmed full-text availability before presenting any candidate, then still uses add_reference to do the actual saving.
---

# PMC Literature Finder

Finds candidate journal articles that are (a) genuinely hosted on PubMed Central with (b) full text actually available — not just an abstract stub — then lets the user pick which ones to preserve via Minowa's `add_reference`. This skill adds no new persistence mechanism; `add_reference` already works well. What it adds is *sourcing*: a search path that checks full-text availability up front, before a candidate is ever shown.

## Why this exists

`add_reference` already saves a PMC article well once it has a URL — full text when available, abstract-only with a clear `fetch_status` otherwise. What this skill adds is upfront the two things a plain topic search doesn't check on its own: that a candidate is genuinely deposited on PMC at all, and that its full text is available right now rather than under embargo. Searching Europe PMC directly with an explicit `OPEN_ACCESS:Y` filter gets both checks done before a single candidate is ever presented.

## Core principles (do not violate)

1. **Full text only, verified before presenting.** The user wants articles they can actually read, not abstract-only stubs. `add_reference`'s own description warns that even a valid PMCID can come back abstract-only if the article is embargoed. Filter candidates to `OPEN_ACCESS:Y` in Europe PMC's index (see below) before ever showing them as a candidate — that flag specifically means the full text is immediately available, not just deposited-but-embargoed. Do not rely on "has a PMCID" alone as a proxy for full text.

2. **Never call `add_reference` without the user picking the article first.** This skill produces a shortlist; the user chooses what to save, same as `add_reference`'s own "never proactively" rule. Present title, journal, year, and PMCID/link for each candidate and wait for a pick.

3. **Check the existing Library before presenting.** Call `minowa:list_references` and mark any candidate whose PMCID is already saved, so the user isn't asked to re-confirm something they already have.

4. **Treat `suggest_references` as a supplementary pass, not the primary source.** Run it alongside the Europe PMC search and fold in anything genuinely on-topic that isn't already found (dedup by PMCID). Verify relevance yourself before including any of its hits — a keyword match in the title doesn't guarantee genuine relevance.

5. **After saving, confirm `fetch_status` came back `full_text`.** If `add_reference` reports anything else (e.g. abstract-only) despite the `OPEN_ACCESS:Y` pre-filter, say so plainly rather than reporting it as a clean save — the pre-filter is a strong signal, not a guarantee.

## Workflow

### 1. Search Europe PMC directly (primary source)
Europe PMC (EMBL-EBI) mirrors PubMed/PMC and exposes a free, no-auth REST API with relevance ranking and an explicit open-access filter. Query it with the web-fetch tool:

```
https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=<TOPIC> AND SRC:PMC AND OPEN_ACCESS:Y&format=json&resultType=core&pageSize=15
```

- `SRC:PMC` restricts to records that have a PMCID at all.
- `OPEN_ACCESS:Y` restricts further to immediately-available full text (not embargoed NIH-mandate deposits).
- Ask for, per result: `title`, `journal`/`journalTitle`, `pubYear`, `pmcid`, `doi`.
- For a narrow or clinical topic, try 2–3 phrasings (the exact term; the term plus "diagnosis treatment"; the term plus any narrower sub-topic the user mentioned) and merge, deduping by PMCID — the same way a real literature search spans multiple query angles rather than trusting one phrasing's ranking.

### 2. Optionally run `suggest_references` too
Run it in parallel with the same topic. Fold in any hit that's genuinely on-topic and not already found via Europe PMC; skip the rest without comment.

### 3. Check what's already saved
Call `minowa:list_references`. Mark any candidate PMCID that's already in the Library so it's clearly labeled rather than re-offered as new.

### 4. Present the shortlist
Title, journal, year, PMCID, and the `pmc.ncbi.nlm.nih.gov/articles/PMCxxxxx/` link for each candidate — newest-first or most-relevant-first, whichever better serves the topic (a fast-moving diagnostic-criteria question favors newest; a mechanism question favors the most-relevant). Say plainly which are already saved. Wait for the user to pick.

### 5. Save the picks
For each one the user chooses, call `minowa:add_reference` with its PMC URL. Report the result, including `fetch_status`. If it's anything other than `full_text`, say so — a technically-successful save should never read as "got the full article" if it wasn't.

## Checking a single pasted link (PMID-only or PMC)

Sometimes the user pastes a `pubmed.ncbi.nlm.nih.gov/<PMID>/` link rather than a PMC one, or asks whether a link of unknown PMC status is already saved or savable. To check whether a given PMID is on PMC at all:

```
https://www.ebi.ac.uk/europepmc/webservices/rest/search?query=EXT_ID:<PMID> AND SRC:MED&format=json&resultType=core
```

Read `pmcid`, `isOpenAccess`, and `inPMC` from the result. If there's no `pmcid`, the article isn't on PMC and `add_reference` cannot preserve it — say so plainly (this is a common, real outcome for clinical-journal literature that was never deposited, not a bug) rather than treating it as something to route around. Do not attempt to scrape the publisher's page as a workaround — full-text redistribution rights are exactly what PMC's own scoping exists to respect, and there is no Minowa tool designed for storing arbitrary non-PMC full text; a genuine fix there is a server-side capability request, not something to patch around locally.

**Known-bad approach — do not check a single PMID this way.** Fetching `pmc.ncbi.nlm.nih.gov/tools/idconv/api/v1/articles/` through a generic web-fetch tool has, in practice, returned a stale cached result for the *previous* PMID checked — even after the query string changed, and even after retrying with the URL restructured. The Europe PMC `EXT_ID` lookup above does not have this problem and has been reliable on every check performed. Use it instead of the NCBI ID-converter endpoint for this purpose.

## Known issues

- The web-fetch tool hitting Europe PMC has returned a `429` rate limit at least once. Back off roughly a minute and retry once; don't loop on it.
- **Direct fetches of a PMC article page (`pmc.ncbi.nlm.nih.gov/articles/PMCxxxxx/`) can come back as a Google reCAPTCHA/bot-check page instead of the article**, with no clean error to signal it — the fetch "succeeds" but the content is a browser-check page, not the citation. This is separate from the `429` above and from the sandbox-level connection rejections some environments impose on these hosts entirely. Prefer Europe PMC's REST API (the `search` and `EXT_ID` endpoints already used elsewhere in this skill) over fetching a PMC article page directly when the goal is to confirm a citation — the REST API has not shown this failure mode in practice, while direct article pages have. If a fetch to any of these hosts fails outright (a connection-level rejection rather than a normal HTTP response, or a captcha page where a citation should be), report that plainly as a fetch problem rather than treating it as evidence the article doesn't exist or silently substituting an unconfirmed citation.
- There is no Minowa tool to preserve full text for an article that exists but isn't on PMC — confirmed in practice for real clinical-journal papers with no PMCID at all. This is a genuine gap, not something this skill can work around; the actual fix is a new or extended server-side save tool (e.g. DOI/URL ingestion via an open-access lookup service, respecting the same license constraints PMC itself observes) — a `minowa:send_feedback` feature request, not a local patch.
