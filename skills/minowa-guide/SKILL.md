---
name: minowa-guide
description: Answer questions about how to use Minowa itself, not what a user's data shows. Use for "how do I connect Garmin or HealthKit", "where do I log a medication or create a stack", "how do I get an API key for Claude Desktop", "can I do this from chat or need the web app", "what MCP tools exist", "how do I revoke an API key", "why isn't my data showing up" — Minowa's features/screens/accounts/setup, not the substance of logged health data. Minowa Web (and the mobile app, same backend) handles everything editable: accounts, 2FA, API keys, connecting Garmin/HealthKit, logging meds/food/vitals, stacks, clinical history, documents, dietary settings, reminders, provider contacts. The MCP surface here is read-mostly plus a short write list (health norms, saved reports, chat summaries, lit refs, combination-product components). Not for analyzing fetched data — that's health-episode-report, inputs-matrix, scored-sleep-signature, match-my-symptoms, or pmc-literature-finder. This is about which system a task belongs to.
---

# Minowa Guide

Minowa is two systems for an end user, and they are not interchangeable.

**Minowa Web** — the browser app (and the mobile app, which talks to the same backend). This is where anything gets *created, connected, or configured*: the account itself, two-factor auth, API keys, Garmin and Apple HealthKit connections, medications and supplements, stacks, food and meals, vitals entries, clinical history, dietary settings, reminders, provider contacts, document and fax uploads.

**Claude, through the Minowa MCP tools** — what this chat surface calls. It is read-mostly: every analysis skill in this repository (health-episode-report, inputs-matrix, scored-sleep-signature, match-my-symptoms, pmc-literature-finder) fetches through it. Only a handful of MCP tools write anything, and each writes a specific document-like object — never a raw log entry, never a new connection, never an account setting.

## Decision rule

- "Show me / analyze / summarize / chart / compare my ___" → MCP, via the relevant analysis skill. Don't reach for this skill's references for that — hand off instead.
- "Connect / create / log / change / delete / set up ___" → Minowa Web (or the mobile app). Say so plainly. Do not try to satisfy it with an MCP write tool that doesn't exist for that purpose — see `references/mcp-tool-reference.md` for the full, short list of what MCP can actually write.
- Ambiguous cases ("why isn't my sleep data updating", "where did my supplement go") are very often a Web-side connection or logging problem, not an MCP or analysis problem. Check `references/web-interface-reference.md` first.

## Reference files

- `references/mcp-tool-reference.md` — every MCP tool available to this chat, grouped by what it answers, with the (short) write list called out explicitly.
- `references/web-interface-reference.md` — what only Minowa Web can do, organized by task, and why MCP has no equivalent for it.

## What this skill does not do

It does not interpret health data. Once the user's question is actually about their data rather than about the system, hand off to health-episode-report, inputs-matrix, scored-sleep-signature, match-my-symptoms, or pmc-literature-finder.
