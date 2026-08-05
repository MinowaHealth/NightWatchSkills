# Web-interface reference

What Minowa Web handles — the browser app, and the mobile app that talks to the same backend. Organized by task. MCP has no tool for any of this except where a task explicitly says otherwise; see `mcp-tool-reference.md` for the short write list.

## Account & security
- Signing up, logging in, changing a password, enabling or disabling two-factor auth, generating backup codes.
- **Home Edition has no self-service signup and no email-based password reset** — there are no outbound email flows on the appliance. Accounts are created and managed by whoever administers the appliance, not by the end user or by chat.
- **Onboarding a new person today:** an administrator provisions the account directly on the appliance (create the account, set the initial email/password, disable/enable/delete an account, reset a password on the account holder's behalf). This is an administrative action outside both Minowa Web's normal user-facing screens and the MCP tool surface — there is no in-chat or self-service path for it today.
- **Open decision, not yet built:** if onboarding should be able to create an account, set its email/password, or reset a password *from chat*, that requires a new privileged capability — either exposing account provisioning through the API for an MCP tool to call, or some other guarded path. That is a deliberate security decision (anything that can create accounts or set passwords for someone else is high-privilege) and should be scoped and reviewed on its own, not added quietly as a side effect of a documentation skill. Whatever is built, the assistant side of it should never see or handle a raw password in plain text — a generated one-time link or a human-entered field are the usual patterns; a chat tool that accepts a plaintext password as an argument is the pattern to avoid.
- Creating, listing, and revoking the long-lived API keys used to connect Claude Desktop (or any other MCP client) to this account. This is the bridge between the two systems: the key is created in Minowa Web and pasted into the MCP client's own configuration.

## Connecting wearables
- Establishing the Garmin connection in the first place, and the same for Apple HealthKit. MCP can only trigger a re-sync of an *already-connected* Garmin account and read the resulting summary — it cannot create either connection and has no HealthKit tool of any kind.
- Apple HealthKit data arrives through the mobile app (or a HealthKit export), not by pasting anything into the browser. If wearable data looks stale or missing, check the connection here before assuming it's an MCP or analysis problem.

## Logging intake, food & vitals
- Logging a medication or supplement dose (scheduled or as-needed), logging a meal or a single food item, entering a blood-pressure/weight/temperature/blood-glucose reading, recording a free-text observation.
- MCP reads all of this back (activity feed, vitals timeline, observation detail, nutrition report) but creates none of it.

## Managing the regimen
- Creating, editing, or deleting a medication/supplement entry, its dose and schedule (timeframes), and stacks (named bundles taken together).
- The one exception: MCP can update the ingredient breakdown of an existing combination product (a multivitamin's per-tablet amounts) once the item itself exists — see `set combination-product components` in `mcp-tool-reference.md`. It cannot create the item.

## Clinical record
- Adding or editing conditions, allergies, family history, and lab/blood-work results.
- MCP only reads this (clinical history, lab history) to ground analysis and flag medication/allergy conflicts.

## Documents & fax
- Uploading a document, sending or receiving a fax.
- MCP can search, open, and cite documents once they exist, and can save a small set of its own generated documents (chat summaries, episode reports, scored sleep signature reports, saved literature) — but it cannot upload an arbitrary file or send a fax.

## Provider contacts
- Adding, editing, or removing entries in the personal address book of the user's own healthcare providers.

## Dietary settings & reminders
- Setting dietary restrictions/preferences, and creating, editing, completing, or snoozing reminders.
- MCP reads dietary settings only as context for the nutrition report; it has no reminder tool at all.

## Dashboards
- The at-a-glance heatmaps and weekly/aggregate dashboard views live only in Minowa Web. MCP answers the same underlying questions on demand (through the analysis skills) but does not render a persistent dashboard.

## When something seems missing from chat
Before concluding an MCP tool or an analysis skill is broken, check whether the task is actually one of the above — connecting a source, logging an entry, editing the regimen, uploading a document. If so, the answer is "do that in Minowa Web," not a workaround through chat.
