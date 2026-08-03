# Matrix format

## The cell rule

The user asked for totals by amount, and their catalogue does not support one universal unit. So **each column declares its own unit in the header** and the cell is a bare number under it. Three cases, decided per substance from the active regimen:

1. **`strength_amount` and `strength_unit` present** — cell = Σ(`quantity` × `strength_amount`) over that date's log rows. Header unit = `strength_unit`. A half-form logged as `quantity: 0.5` contributes half.
2. **`components` array present** (combination products) — cell = Σ(`quantity` × Σ component amounts), when every component shares one unit. Header unit = that unit, with the component breakdown named in the column note. If components disagree on unit, fall back to case 3.
3. **No strength at all** — no amount can be computed. Cell = Σ(`quantity`), and the header unit is the **form** (tablet, capsule, scoop, spray, patch, application). Never leave these blank and never coerce them to zero: a blank reads as "not taken", which is the opposite of what happened.

**Never convert between units to make columns line up.** A microgram column stays micrograms. Conversion would make two columns look comparable when the underlying doses differ by a thousandfold, and the comparison this table supports is *down* a column across dates, never *across* columns.

Mark case-3 columns visually (a distinct header tint) so the reader can see at a glance which numbers are amounts and which are counts.

## Rows

- One row per calendar date in the window, **descending** (newest first).
- Include dates with zero logged intake — an empty row is information. Leave its cells blank, not `0`, and tint the row so it reads as absent rather than measured-as-none.
- Dates are the user's local days from `minowa:get_current_time`.

## Columns and groups

- Ordered by group, groups in the user's stated order, `Unassigned` last.
- Within a group, order by days used descending — the same ranking the limit uses, so a limited table is a prefix of the unlimited one.
- Each column header carries: substance name, unit, and (on hover in HTML, as a cell note in the spreadsheet) its type, its stack memberships if any, and whether it is PRN-only.

## Footers

Two summary rows beneath the matrix, per column:

- **Total** — the column summed over the window, in the column's unit.
- **Days used** — count of dates with any intake. This is the honest cross-substance comparator, and the value the limit ranks on.

No row totals. Summing across columns would add milligrams to micrograms to capsules.

## Spreadsheet

- One sheet, `Intake by date`.
- Row 1: group names as merged headers spanning their columns. Row 2: substance names. Row 3: units.
- Column A: date. Freeze panes at `B4` so dates and headers stay visible; autofilter on row 2.
- Number format matched to the unit; case-3 columns formatted as plain counts.
- A second sheet, `Notes`, carrying the coverage report from step 5, the dropped-substance list, and the group definitions used for this run.

## HTML

Same card styling as the other reports in this package — white card, light color scheme pinned, `<meta name="color-scheme" content="light only">`.

- Sticky first column (the date) and sticky header rows; the table scrolls horizontally inside the card.
- Group headers as tinted bands spanning their columns, one tint per group, repeated in a legend.
- Case-3 (count, not amount) columns marked with the distinct tint from the cell rule.
- Under the table: the coverage report, then the notes — that scheduled and PRN intake are summed, that units differ per column, and any regimen/norms conflict.
- Keep the notes short. The table is the deliverable.

## Limits — what to say when substances are dropped

Whenever the column set is smaller than the substances with intake in the window, state in **both** outputs:

> Showing N of M substances with logged intake, ranked by days used. Not shown: *(full list of names)*.

Never abbreviate that list with "and others". The point of naming them is that the reader can see whether something they care about fell off the edge.
