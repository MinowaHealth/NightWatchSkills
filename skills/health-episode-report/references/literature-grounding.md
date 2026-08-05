# Literature grounding

## What this is for

The narrative sometimes needs to say *why* — why stress suppresses during movement, why a
medication might raise heart rate, why two symptoms in the data might share a mechanism. Those
sentences read as authoritative, so back them with something real: an article the user chose to
preserve, not whatever general knowledge a language model happens to carry about the topic.

## The check

Before writing a sentence that asserts a mechanism, a drug effect, or a causal link between two
things in the data, call `minowa:search_my_data` with `scope: "documents"` and the mechanism or
topic as the query (`q`). This searches only what the user has actually preserved in their
Library via `add_reference` — real, peer-reviewed, resolvable articles, not open recall.

- **Found something on point?** Read the actual passage with `minowa:get_document` before citing
  it — a title or abstract match is not the same as the article supporting the specific sentence
  about to be written. Once confirmed, cite it: article title, PMCID, **and its link**, next to
  the claim it supports — `https://pmc.ncbi.nlm.nih.gov/articles/<PMCID>/` if the tool response
  didn't already hand back a `url`. A citation with no link is not yet a citation someone can go
  check.
- **Found nothing on point?** Say so in one line ("nothing in the saved Library speaks to this
  directly") rather than silently reaching for general knowledge. If the point matters enough to
  state anyway, offer to search PMC for a candidate — the `pmc-literature-finder` skill's workflow,
  or `minowa:suggest_references` — rather than asserting the mechanism unsourced.
- **General background used anyway?** Label it explicitly and distinctly from cited claims — for
  example a sentence prefixed "general background, not from a saved source:" — never blended into
  the same sentence as a citation, so the two stay distinguishable to the reader.

## What this does not change

Reading and reporting the user's own logged data (HR, stress, BP, doses, observations) is
unaffected — this only governs sentences that explain *mechanism*, not sentences that report *what
was measured*. A caveat like "stress is suppressed during movement — documented Garmin device
behavior" is a device-behavior fact, not a claim that needs literature grounding.

## Do not

- Invent a PMCID, title, or journal. `search_my_data` and `get_document` return only real saved
  documents — if nothing comes back, nothing was found, full stop.
- Cite a saved article for a claim it doesn't actually support just because it matched the query.
- Silently mix "from the Library" and "general knowledge" claims in the same sentence.
