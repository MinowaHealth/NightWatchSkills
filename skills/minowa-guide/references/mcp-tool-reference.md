# MCP tool reference

Every tool the Minowa MCP server exposes to this chat surface, grouped by what it answers. Almost all of them are read-only — they fetch something that already exists in Minowa Web or the mobile app. The write list at the bottom is short and complete; if a task isn't on it, it belongs in Minowa Web.

## Time (server-authoritative — never compute dates yourself)
- **current time** — UTC instant, home timezone, local date/time, weekday, ready-made 7/30/90-day windows.
- **date math** — add/subtract days, weeks, or months from a date; difference between two dates; weekday lookup.

## Identity & regimen (read)
- **profile** — display name, timezone, dietary settings, authorized providers/delegates.
- **active regimen** — current medications/supplements and the timeframes/reminders governing them. Inactive entries excluded.
- **stacks** — named bundles of medications/supplements taken together, with contents and schedule.
- **clinical history** — conditions, allergies, family and surgical history, vaccinations, plus alerts where an active medication matches a known allergy.

## Vitals, labs & wearables (read, with one narrow write)
- **vitals timeline** — blood pressure, weight, temperature, blood glucose over a window, in the user's display units.
- **lab history** — latest lab results grouped by test, with reference range and interpretation.
- **wearable summary** — Garmin and HealthKit daily aggregates (steps, sleep, stress, resting heart rate, SpO2) and each source's connection status.
- **minute-level Garmin detail** — heart rate, respiratory rate, stress, and steps around a specific point in time.
- **sleep-stage detail** — Garmin sleep-stage events (deep/light/REM/awake) around a point in time.
- **observation detail** — free-text notes and logged events around a point in time.
- **trigger a Garmin re-sync** *(write)* — queues a background pull of the past week of Garmin data. This does not create the Garmin connection itself, only refreshes an existing one. There is no equivalent for HealthKit — HealthKit has no MCP tool of any kind, read or write, beyond appearing inside the wearable summary and activity feed.

## Activity & adherence (read)
- **recent activity feed** — medication/supplement logs, food logs, observations, data-source sync events, document arrivals, and supply acquisitions, in one chronological stream, filterable by kind or date.
- **adherence report** — scheduled vs. logged doses per active medication/supplement over a window, with a percentage and days-short list. As-needed items are excluded from the percentage and listed separately.
- **acquisition history** — dated arrivals of medications/supplements with quantity, cost, brand, vendor.

## Food & nutrition (read)
- **nutrition report** — daily calorie/macro rollups, meal count, and entries that appear to violate the user's dietary settings.

## Search & documents (read, with one write)
- **search** — full-text/semantic search across observations, medications, conditions, allergies, food, and documents (including saved AI session summaries and saved literature).
- **get a document** — one document's metadata, extracted text, annotations, and a link to open it in a logged-in browser.
- **save a chat summary** *(write)* — saves a markdown summary of the current conversation as a document, only after the user explicitly asks for it and has reviewed the text.

## Reports — episode and scored sleep signature (write)
- **save an episode report** — saves a generated HTML episode analysis as a document.
- **list episode reports** — titles, analyzed windows, and versions of saved episode reports. Can filter to episodes spun off from one scored sleep signature report.
- **save a scored sleep signature report** — saves a generated HTML report as a document, with candidate episodes optionally flagged from HR/stress excursions or the user's notes. Despite the name, the window it covers is whatever the caller analyzed (a full day, or a narrower span) — it is a general day-scoped report store, not scored-sleep-specific by mechanism.
- **list scored sleep signature reports** — titles, calendar days, analyzed windows, versions, and a per-report count of segmentation candidates by status.
- **update a scored sleep signature segment** — records the user's confirm/adjust/reject decision on one detected candidate, or links the episode report generated from it. Only on an explicit user decision. Never anchor a candidate on Garmin sleep staging — that basis does not exist by design.

## Library — saved literature (write)
- **add a reference** — preserves a PubMed Central article by URL.
- **list references** — the saved literature library with citation metadata.
- **suggest references** — searches PubMed Central for candidates to save; nothing is saved until confirmed.

## Health norms — personal baselines and interpretation rules (write)
- **get health norms** — the current version of the user's monitoring norms document.
- **update health norms** — saves a new version (full replacement); only after the user explicitly confirms the change.
- **list norms history** — every saved version with its change note.

## Regimen correction (write)
- **set combination-product components** — replaces the ingredient breakdown of a combination medication/supplement (a multivitamin, a fish-oil blend) when the user supplies a product label. This edits catalogue metadata, not a log entry.

## Feedback (write)
- **send feedback** — submits feedback about the MCP server's own behavior (bad data, missing info, a feature request) to the Minowa team. Not for anything about the user's health.

## The complete write list

Trigger a Garmin re-sync, save a chat summary, save an episode report, save a scored sleep signature report, update a scored sleep signature segment, add a reference, update health norms, set combination-product components, send feedback. That's all of it. Logging a dose, connecting a device, creating a stack, adding an observation, entering a vital, uploading a document, changing an account setting — none of these have an MCP tool. They happen in Minowa Web. See `web-interface-reference.md`.
