# Purpose groups

## Where the grouping lives

On the Minowa server, inside the norms document, under a heading `## Intake matrix — purpose groups`. Fetch it with `minowa:get_health_norms` and parse that section; write it back with `minowa:update_health_norms` as a full-document replacement.

It does **not** live in this package. A list of which substances a person takes for which purpose is a health record, and everything under `skills/` is a public artifact. There is no separate document-write call for structured config, so the norms document is the store.

Expected shape — one group per line, group name then its members:

```
## Intake matrix — purpose groups

- Group Name: substance, substance, substance
- Another Group: substance, substance
```

Order of the lines is the column order in the report. Match member names case-insensitively against `input_name` from the regimen.

## When no grouping exists yet

Do not invent one silently and do not fall back to grouping by stack.

1. Read the active regimen and draft a proposed grouping from what the entries plainly are.
2. Show the user the whole draft and ask them to correct it. Assigning purpose is theirs — a substance can serve two purposes and only they know which one they organise by.
3. On explicit confirmation, save it into the norms with a `change_note` naming it as the grouping for this report.
4. Build the report from the saved version, not from the draft in conversation.

Until it is confirmed, a report can still be produced with every substance under `Unassigned`; say clearly that the grouping is not set.

## Rules for the grouping itself

- **Every substance sits in exactly one group.** Overlaps are real — one drug can plausibly sit under two purposes — but a substance in two groups gets two columns and its totals get read twice. Ask which group the user reaches for it under, and put it there. Note the secondary purpose in the column note instead.
- **A substance with no group goes to `Unassigned`, and `Unassigned` being non-empty is reported**, so the mapping gets finished rather than quietly drifting.
- **Groups are about purpose, not timing.** Timing is what stacks and timeframes already encode. If a proposed group name is a time of day, it belongs in the stack view, not here.
- **Adding a new substance does not require re-confirming the whole grouping** — propose the one line, confirm, save.

## Editing later

When the user moves a substance between groups, renames a group, or reorders them, apply it the same way: fetch the current norms, change that section only, save the whole document back with a `change_note`. Never rewrite unrelated sections in the same save, and never drop a rule from another section while editing this one.
