# inputs-matrix

A date-by-substance intake table built from Minowa medication and supplement logs. Dates run down the side, newest first; drugs and supplements run across the top, clustered by what the user takes them for. Each cell is that day's total.

Produces two artifacts from one matrix: a spreadsheet for working with, and a single-page HTML view for reading.

## Why it exists

No single Minowa call returns intake laid out by date and substance. `get_adherence_report` answers a different question — whether scheduled doses were met — and collapses the as-needed intake that this table is largely about. The episode report covers one window in depth; this covers many days shallowly.

## Shape of the answer

- One row per calendar date in the window, descending, including days with nothing logged.
- One column per substance, exactly once, grouped by purpose.
- Scheduled and as-needed intake of the same substance sum into one cell.
- Each column carries its own unit, because the catalogue has no single one. Columns whose substances have no recorded strength show a count of forms instead, and are marked as such.
- Footers give each column's total and its days-used count.

## What it will ask for

Scope, if not given: the window (default 30 days), and any limit on how many substances to show — a number, a set of groups, or an explicit list. A numeric limit ranks by days used, and every dropped substance is named rather than summarised.

## What it does not hold

The purpose grouping. Which substance serves which purpose is personal, so it lives in the norms document on the server and is fetched at runtime. If none exists, the skill drafts one from the active regimen, asks the user to correct it, and saves only what they confirm. See `references/grouping.md`.

## Files

- `SKILL.md` — principles and workflow
- `references/matrix-format.md` — the cell rule, row and column layout, spreadsheet and HTML specs
- `references/grouping.md` — where the purpose grouping lives, how it is created and edited
