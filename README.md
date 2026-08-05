# NightWatch

[Claude Skills](https://docs.claude.com) for turning personal wearable + health-tracking
data (via the **Minowa MCP server** — Garmin sleep/HR/stress, blood pressure, medications,
observations, a saved literature Library) into precise, honest analysis.

| Skill | Question it answers | Role |
|-------|--------------------|------|
| **health-episode-report** | *What happened during this window?* | Charts and narrates any timeframe (a night, an episode, a nap) — HR/stress trace, scored hypnogram or inferred rest, BP, doses, verbatim observations. Mechanism claims are grounded in the saved literature Library before they're written. |
| **intake-interview** | *Who is this person and how should their data be read?* | Onboards a new user: captures the health baseline and elicits their personal monitoring norms, seeding the first dated `HealthMonitoringNorms` document. |
| **match-my-symptoms** | *Is there literature that matches what I'm experiencing?* | For someone with no name yet for what they're experiencing: finds PMC literature that matches their symptoms, checking the saved Library first and searching PMC directly for what isn't there — grounded in logged data and clinical history, never a diagnosis. |
| **inputs-matrix** | *What have I been taking, day by day?* | Builds a date-by-substance intake table from medication/supplement logs — one row per calendar date, one column per substance, clustered by purpose. Produces a spreadsheet and a single-page HTML view. |
| **pmc-literature-finder** | *Is there real literature on this, and can I keep it?* | Searches Europe PMC directly for articles that are confirmed full-text-available, then hands confirmed picks to `add_reference` to save. |
| **scored-sleep-signature** | *How did I get into this (scored) night?* | Reconstructs the pre-sleep **run-up** of a Garmin-**scored** night, extracts its "signature," and — on request — saves it so later runs can compare across nights. See the skill's README. |
| **minowa-guide** | *How do I do this in Minowa, and where?* | Not an analysis skill — a reference for which system a task belongs to. Minowa Web (and the mobile app) handles everything editable: accounts, API keys, connecting Garmin/HealthKit, logging, the regimen, documents. The MCP surface the other skills use is read-mostly, with a short, explicit write list. |

**intake-interview** runs once, at the start: it establishes who the person is and seeds version one of the
`HealthMonitoringNorms` document **on the Minowa server**, which both analysis skills fetch with
`get_health_norms` before writing a word. The two
analysis skills then divide the ongoing work cleanly:

> **Scored Sleep Signature finds what works. Episode Analysis surfaces what doesn't.**

Signature deliberately looks only at **scored** nights (approaches that led to a real, measured
outcome) to isolate the ingredients of a good night. The genuinely bad nights — too short or
fragmented for Garmin to score — are surfaced by Episode Analysis instead, which handles inferred
rest. Restricting Signature to scored nights is a feature, not a gap: it keeps every entry anchored
to a measured outcome.

**match-my-symptoms** sits earlier than either analysis skill: it's for someone who hasn't yet
turned their experience into logged, structured data because they don't have a name for what's
happening. It never diagnoses — every candidate pattern is either cited (with a link) from the
saved Library or a fresh PMC search, or explicitly labeled as unsourced general background — and
it hands off to `health-episode-report` once there's a specific episode worth charting, and to
`intake-interview` once there's an actual baseline to record.

**inputs-matrix** and **pmc-literature-finder** are utilities rather than part of that core
analysis loop: the first turns the medication/supplement log sideways (by date instead of by
episode), the second adds a literature-search step — Minowa's `add_reference` already saves a PMC
article well, this is what feeds it candidates. **match-my-symptoms** calls directly into
`pmc-literature-finder`'s search workflow rather than duplicating it, and both it and
**health-episode-report** consume whatever's already been put in the Library.

## Repository layout

```
NightWatch/
├── README.md
├── LICENSE
├── .gitignore
├── skills/
│   ├── health-episode-report/          # analysis: the window (see its README)
│   │   ├── SKILL.md
│   │   ├── assets/report_template.html  # the single-page report template
│   │   └── references/                  # data-fetch quirks, report-format spec, literature grounding
│   ├── intake-interview/                # onboarding: seeds the norms (see its README)
│   │   ├── SKILL.md
│   │   ├── assets/norms_seed.md         # starting norms document for a new user
│   │   └── references/                  # interview guide, norms taxonomy, commit path
│   ├── match-my-symptoms/               # pre-onboarding: unsure what the problem is (see its README)
│   │   ├── SKILL.md
│   │   └── references/                  # non-diagnostic framing, literature workflow
│   ├── inputs-matrix/                   # utility: intake by day (see its README)
│   │   ├── SKILL.md
│   │   └── references/                  # matrix-format.md, grouping.md
│   ├── pmc-literature-finder/           # utility: literature search + save (see its README)
│   │   └── SKILL.md
│   ├── scored-sleep-signature/          # analysis: the run-up (see its README)
│   │   ├── SKILL.md
│   │   └── references/signature-axes.md
│   └── minowa-guide/                    # reference: web app vs. MCP, not analysis (see its README)
│       ├── SKILL.md
│       └── references/                  # mcp-tool-reference.md, web-interface-reference.md
├── dist/                                # packaged .skill files for one-click install
│   ├── health-episode-report.skill      # built from source; contains no records of any kind
│   ├── intake-interview.skill
│   ├── match-my-symptoms.skill
│   ├── inputs-matrix.skill
│   ├── pmc-literature-finder.skill
│   ├── scored-sleep-signature.skill
│   └── minowa-guide.skill
└── examples/                            # how to generate example outputs (see README)
```

## Requirements

- The **Minowa MCP server** connected in Claude (provides `get_garmin_minute_detail`,
  `get_sleep_events_detail`, `get_observations_detail`, `get_vitals_timeline`,
  `get_recent_activity`, `get_current_time`, `date_math`, `add_reference`, `list_references`,
  `search_my_data`, `get_document`, `get_my_clinical_history`, etc.).
- A **Garmin** device syncing sleep/HR/stress, plus manually logged BP, medications, and
  observations in Minowa.
- A Claude surface that supports Skills and file creation (Claude.ai, Claude Code, or Cowork).
- **pmc-literature-finder** and **match-my-symptoms** additionally need general web-fetch access,
  to query Europe PMC's public REST API when the saved Library doesn't already cover a topic.

## Install

**Option A — packaged (`dist/*.skill`):** open the `.skill` file in a Claude surface that supports
skills and click **Save skill**.

A packaged skill is source files only — no norms file, no log file, no template standing in for
either. Your norms live on your Minowa server and are fetched at runtime, so a fresh install carries
nobody's records and needs no local setup.

**Option B — from source:** point Claude Code (or your skills directory) at
`skills/health-episode-report/`, `skills/intake-interview/`, `skills/match-my-symptoms/`,
`skills/inputs-matrix/`, `skills/pmc-literature-finder/`, and `skills/scored-sleep-signature/`.
Each skill is self-contained under its own folder, with one dependency: `scored-sleep-signature`
expects `health-episode-report` to be installed alongside it (it reuses that skill's Minowa fetch
conventions and shares its norms). `intake-interview`, `inputs-matrix`, and `pmc-literature-finder`
each stand alone. `match-my-symptoms` calls into `pmc-literature-finder`'s workflow for its PMC
search step rather than duplicating it, so install the two together.

## Where memory lives

Nothing accumulates in this repository. The norms document — the inference rules that make the analysis
sharpen with use rather than repeat mistakes — lives in versioned storage on the Minowa server.
`intake-interview` creates version one; the analysis skills fetch the current version with
`minowa:get_health_norms` before writing a word, and corrections go back with
`minowa:update_health_norms`, which assigns the version and preserves history. `inputs-matrix`'s
purpose grouping (which substance serves which purpose) lives in that same server-side document,
drafted from the active regimen and saved only once the user confirms it.

`scored-sleep-signature` has its own store now: `minowa:save_scored_sleep_signature` persists a
signature card, on explicit user request only, and `minowa:list_scored_sleep_signatures` retrieves
prior nights for the cross-night comparison the skill is named for. See that skill's "Persistence"
section for how its five-axis concept maps onto that store. `pmc-literature-finder` needs no store of its
own — it only searches and shortlists; saving already goes through Minowa's existing `add_reference`.
`match-my-symptoms` is the same: it reads the Library and the clinical record, and writes nothing
except through Minowa's own `add_reference` and `save_chat_summary`, both on explicit confirmation.

## Personal health data

**The skills hold none, by construction.** There is no norms file, no log file, and no template
standing in for either. Every personal fact — norms, baselines, records, a user's own vocabulary for a
sensation — is fetched from the server at runtime and written back to it. If something needs to persist
and has no server call, that is a server requirement, not a file.

Generated output is a separate matter and does contain health data — episode reports, intake summaries,
dated norms versions. `.gitignore` covers their filename patterns; keep those rules active, and if you
need such a file elsewhere, move it by hand outside the repo.

**A `.gitignore` cannot see inside an archive.** `dist/*.skill` files are zips and they are committed,
so `tools/check-public-safe.sh` inspects archive members directly and fails on anything shaped like a
records file — a stray one cannot ride into a release sealed inside a zip. Build `dist/` only with
`tools/build-skills.sh`.

### Enforcement

Manual pre-push checklists depend on remembering them, and they only ever looked at
filenames. The check is now a script, and three things call it:

```bash
./tools/check-public-safe.sh          # scan source + dist
STRICT=1 ./tools/check-public-safe.sh # also fail if the term list is missing
```

It looks for structural tells that need no wordlist — calendar dates inside a skill,
`quantity @ H:MM PM` dose shapes, absolute paths, IPs, email addresses, possessives
like "his baseline" — and for terms listed in `tools/.pii-terms`. It also validates
that each skill will actually install: `name:` a lowercase slug matching its directory,
`description:` within its 1024-character ceiling.

**That term file is gitignored on purpose.** A list of someone's medications and
symptoms is itself the personal data this repo is trying to exclude, so it must never
be committed. Copy `tools/.pii-terms.example` to `tools/.pii-terms` and fill it in;
without it the term scan is skipped with a warning (or fails, under `STRICT=1`).

Wired in three places so it cannot quietly drift:

| Layer | Covers | Bypassable |
|---|---|---|
| `tools/build-skills.sh` | Gates before packaging and re-checks after | Only by hand-building `dist/` — don't |
| `tools/githooks/pre-commit` | Every commit. Enable once: `git config core.hooksPath tools/githooks` | Yes, `--no-verify` |
| `.github/workflows/public-safe.yml` | Every push and PR; also rebuilds archives and diffs them against the committed ones | No |

Use `core.hooksPath` rather than dropping a file in `.git/hooks` — the latter is not
versioned and does not survive a fresh clone.

Agents editing this repo get no hook at all, so the same rule is written into
`CLAUDE.md`: run the check and see it PASS *before* writing files, and never weaken
the check to make it pass.

Nothing here is medical advice; the skills state this in their own output too.

## License

[MIT](LICENSE). Set the copyright holder (the `<YOUR NAME>` placeholder) before publishing.
