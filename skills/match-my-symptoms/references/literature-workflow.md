# Literature workflow

## Step 1 — search what's already saved

For a symptom cluster, query `minowa:search_my_data` with `scope: "documents"` and the cluster's
plain-language description or candidate term as `q`. This searches only what's already saved via
`add_reference` — real, peer-reviewed, resolvable articles the user (or a prior run of this
skill, with their approval) chose to keep.

Before citing a hit, call `minowa:get_document` and read the actual passage. A title or abstract
matching the query is not the same as the article supporting the specific pattern under
discussion — confirm it says what you're about to attribute to it.

## Step 2 — when the Library has nothing, go find it

This skill's whole point is matching literature to symptoms, so an empty Library result is a
prompt to search, not a stopping point. Say so in the same breath as the pattern ("nothing saved
yet on this — searching PMC directly"), then:

- run the full `pmc-literature-finder` workflow (Europe PMC direct search with
  `SRC:PMC AND OPEN_ACCESS:Y`, full-text-verified, deduped against what's already saved), or
- fall back to `minowa:suggest_references` as a supplementary pass.

Present candidates exactly the way `pmc-literature-finder` does — title, journal, year,
PMCID/link, already-saved status — and wait for the user to pick. Save picks with
`minowa:add_reference`, same tool, same confirm-then-save discipline. This skill does not
duplicate the PMC-search mechanics; it calls into `pmc-literature-finder`'s workflow so there's
one place they live.

## Citation format — always with a link

Inline, next to the claim: *article title* (PMCID) — `https://pmc.ncbi.nlm.nih.gov/articles/<PMCID>/`,
or the `url` a tool call already returned. A title and PMCID with no link is not a usable
citation — the whole reason to prefer a matched article over general recall is that the user can
go read it themselves, and that requires the link every time, not just on request. Group multiple
citations for one pattern together rather than scattering them across a paragraph.

## General background, if it's used at all

Only after the Library check and the PMC search have both happened, and only if the user still
wants what general background exists. Prefix it, every time, distinctly from cited material:

> General background, not from a saved or found source — verify independently: ...

Never merge this into the same sentence as a citation. A reader skimming should be able to tell
which sentences are sourced and which aren't without re-reading closely.

## What this does not do

This skill doesn't invent a PMCID, a citation, or a link, doesn't treat a keyword match as
confirmation, and doesn't stop at "nothing saved" without also searching PMC directly — the whole
point is to actually find literature that matches, preferring what's already saved and vetted,
then a fresh search, and only unsourced recall as a clearly labeled last resort.
