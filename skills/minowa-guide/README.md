# minowa-guide

A reference skill, not an analysis skill. It answers "how do I do this in Minowa" and "which system handles this" rather than anything about what a user's health data shows.

## Why it exists

The other skills in this repository all assume the user already knows how to get data *into* Minowa — a Garmin connection, a logged medication, a saved observation — and focus on reading it back out through MCP. Nothing in the repository previously said where those things actually get created, or drew the line between what the chat surface can do (read, plus a short list of specific writes) and what requires the web or mobile app (everything else). This skill is that line.

## Shape of the answer

Two references, organized by task rather than by implementation:

- `references/mcp-tool-reference.md` — the full MCP tool surface available to this chat, grouped by what each tool answers. Calls out the small write list explicitly, since assuming MCP can create or log something it can't is the most common mistake this skill exists to prevent.
- `references/web-interface-reference.md` — what Minowa Web (and the mobile app, which shares its backend) handles: accounts and security, connecting wearables, logging intake and vitals, managing the regimen, the clinical record, documents, provider contacts, dashboards, and API keys.

## What it does not hold

No personal data, by the same rule as every other skill here — see the repository's `CLAUDE.md`. It also holds no opinions about the user's health; it is purely a map of capability to system.

## Files

- `SKILL.md` — the decision rule and pointers to both references
- `references/mcp-tool-reference.md` — MCP tool inventory, read vs. write
- `references/web-interface-reference.md` — web/mobile app capability map
