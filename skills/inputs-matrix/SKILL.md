---
name: inputs-matrix
description: Build a date-by-substance intake matrix from Minowa medication and supplement logs — one row per calendar date in descending order, one column per drug or supplement, columns clustered into user-defined purpose groups, each cell the total taken that day. Produces both a spreadsheet and a single-page HTML view. Use whenever the user wants to see what they took across a stretch of days rather than inside one episode — including "show me my intake by day", "what have I been taking this month", "build the supplement matrix", "intake table", "usage per date", "which supplements am I actually taking", or a request to compare intake across dates. The user may cap how many substances appear and may restrict to specific groups. Not for a single episode window (that is health-episode-report) and not for schedule adherence percentages (that is get_adherence_report).
---

# Inputs Matrix

A wide table: dates down the side, substances across the top, clustered by what the user takes them **for**. It answers "what have I been taking, and how much, day by day" — a shape no single Minowa call returns.

## Core principles (do not violate)

1. **Purpose groups are the user's, and they live on the server.** Which substance serves which purpose is personal data and must never be written into this package. Fetch the grouping at runtime (see `references/grouping.md`). If no grouping exists yet, propose one from the regimen, have the user correct it, and only then save it with `minowa:update_health_norms` — never proactively, and never a version they have not seen.

2. **Do not group by stack.** Stacks overlap: the same substance commonly belongs to several, so a stack-clustered table either repeats columns or double-counts. Purpose grouping is the user's stated preference and sidesteps it. Read stacks for context if useful, but they do not define the columns.

3. **One column per substance, exactly once.** A substance appearing in several stacks, several timeframes, or arguably several purposes still gets one column under one group. Scheduled and PRN intake of the same substance sum into the same cell — that is intended at this resolution and should be stated once in the notes, not per row.

4. **Never mix units inside a column, and never convert silently.** Each column carries its own unit in the header. See `references/matrix-format.md` for the cell rule, including the substances that have no strength recorded and the combination products.

5. **No silent truncation.** When a limit drops substances, the report must say how many were dropped, name them, and state the ranking rule that dropped them. A trimmed table that looks complete is the failure mode this rule exists to prevent — the same applies to a date range that clips logged intake.

## Workflow

### 1. Establish scope
Confirm with the user, or apply the defaults:

- **Window** — default the last 30 days. Anchor "today" on `minowa:get_current_time`'s `local` field; the session environment's date can be UTC and off by one.
- **Limit** — the maximum number of substance columns. Default is no limit. The user may give a number ("top 15"), a set of groups ("only the ones in these two groups"), or an explicit list of substances. A group restriction and a number compose: the number applies within the chosen groups.
- **Ranking** used by a numeric limit: **days used** in the window, descending, tie-broken by dose-event count. Never rank by the cell value — column units differ, so comparing totals across substances is meaningless.

### 2. Fetch
- `minowa:get_my_active_regimen` — the substance catalogue: name, type, form, `strength_amount`/`strength_unit`, and `components` for combination products. This is what the units in step 3 come from.
- `minowa:get_recent_activity` with **`kind:"all"`** across the window, `limit` raised well above the expected row count — the intake rows are `type:"health_input"`. Do not pass `kind:"medication"`: it silently drops every other stream, and the sync rows in particular explain any date with no data.
- `minowa:get_health_norms` — carries the purpose grouping and the interpretation rules.
- `minowa:get_stacks` — optional, for context only.

A substance may be logged that is not in the active regimen (discontinued, or logged freeform). Include it, mark it, and give it a unit from its own log rows.

### 3. Build the matrix
Rows are every calendar date in the window, **descending**, including dates with no intake — a blank day is a finding. Columns are substances, ordered by group, groups in the user's stated order with `Unassigned` last. Cell = the day's total for that substance, computed per `references/matrix-format.md`.

Reconcile the regimen against the norms before writing: a substance marked active that the norms record as discontinued is a conflict. Surface it; change neither.

### 4. Emit both outputs
A spreadsheet and a single-page HTML view of the same matrix — see `references/matrix-format.md` for the layout of each. Save to `/mnt/user-data/outputs/` and deliver both. On edits, bump a version number in the filename.

Read the `xlsx` skill's SKILL.md before building the spreadsheet.

### 5. Report coverage
Close with: window and row count, substances shown of total, any dropped by the limit named in full, any date with no logged intake, and any regimen/norms conflict found in step 3.

## Voice and style
The user's own first-person voice, clinical, no hedging. The notes under the table stay short — the table carries the content.
