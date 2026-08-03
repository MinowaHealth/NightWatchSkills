# NightWatch

[Claude Skills](https://docs.claude.com) for turning personal wearable + health-tracking
data (via the **Minowa MCP server** — Garmin sleep/HR/stress, blood pressure, medications,
observations) into precise, honest analysis.

| Skill | Question it answers | Role |
|-------|--------------------|------|
| **health-episode-report** | *What happened during this window?* | Charts and narrates any timeframe (a night, an episode, a nap) — HR/stress trace, scored hypnogram or inferred rest, BP, doses, verbatim observations. |
| **intake-interview** | *Who is this person and how should their data be read?* | Onboards a new user: captures the health baseline and elicits their personal monitoring norms, seeding the first dated `HealthMonitoringNorms` document. |
| **inputs-matrix** | *What have I been taking, day by day?* | Builds a date-by-substance intake table from medication/supplement logs — one row per calendar date, one column per substance, clustered by purpose. Produces a spreadsheet and a single-page HTML view. |
| **pmc-literature-finder** | *Is there real literature on this, and can I keep it?* | Searches Europe PMC directly for articles that are confirmed full-text-available, then hands confirmed picks to `add_reference` to save. |
| **scored-sleep-signature** | *How did I get into this (scored) night?* | Reconstructs the pre-sleep **run-up** of a Garmin-**scored** night, extracts its "signature." Accumulating those signatures across nights is blocked on server support — see the skill's README. |

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

**inputs-matrix** and **pmc-literature-finder** are utilities rather than part of that core
analysis loop: the first turns the medication/supplement log sideways (by date instead of by
episode), the second adds a literature-search step — Minowa's `add_reference` already saves a PMC
article well, this is what feeds it candidates.

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
│   │   └── references/                  # data-fetch quirks + report-format spec
│   ├── intake-interview/                # onboarding: seeds the norms (see its README)
│   │   ├── SKILL.md
│   │   ├── assets/norms_seed.md         # starting norms document for a new user
│   │   └── references/                  # interview guide, norms taxonomy, commit path
│   ├── inputs-matrix/                   # utility: intake by day (see its README)
│   │   ├── SKILL.md
│   │   └── references/                  # matrix-format.md, grouping.md
│   ├── pmc-literature-finder/           # utility: literature search + save (see its README)
│   │   └── SKILL.md
│   └── scored-sleep-signature/          # analysis: the run-up (see its README)
│       ├── SKILL.md
│       └── references/signature-axes.md
├── dist/                                # packaged .skill files for one-click install
│   ├── health-episode-report.skill      # built from source; contains no records of any kind
│   ├── intake-interview.skill
│   ├── inputs-matrix.skill
│   ├── pmc-literature-finder.skill
│   └── scored-sleep-signature.skill
└── examples/                            # how to generate example outputs (see README)
```

## Requirements

- The **Minowa MCP server** connected in Claude (provides `get_garmin_minute_detail`,
  `get_sleep_events_detail`, `get_observations_detail`, `get_vitals_timeline`,
  `get_recent_activity`, `get_current_time`, `date_math`, `add_reference`, `list_references`, etc.).
- A **Garmin** device syncing sleep/HR/stress, plus manually logged BP, medications, and
  observations in Minowa.
- A Claude surface that supports Skills and file creation (Claude.ai, Claude Code, or Cowork).
- **pmc-literature-finder** additionally needs general web-fetch access, to query Europe PMC's
  public REST API.

## Install

**Option A — packaged (`dist/*.skill`):** open the `.skill` file in a Claude surface that supports
skills and click **Save skill**.

A packaged skill is source files only — no norms file, no log file, no template standing in for
either. Your norms live on your Minowa server and are fetched at runtime, so a fresh install carries
nobody's records and needs no local setup.

**Option B — from source:** point Claude Code (or your skills directory) at
`skills/health-episode-report/`, `skills/intake-interview/`, `skills/inputs-matrix/`,
`skills/pmc-literature-finder/`, and `skills/scored-sleep-signature/`.
Each skill is self-contained under its own folder, with one dependency: `scored-sleep-signature`
expects `health-episode-report` to be installed alongside it (it reuses that skill's Minowa fetch
conventions and shares its norms). `intake-interview`, `inputs-matrix`, and `pmc-literature-finder`
each stand alone — `intake-interview` is what produces the norms document the analysis skills consume.

## Where memory lives

Nothing accumulates in this repository. The norms document — the inference rules that make the analysis
sharpen with use rather than repeat mistakes — lives in versioned storage on the Minowa server.
`intake-interview` creates version one; the analysis skills fetch the current version with
`minowa:get_health_norms` before writing a word, and corrections go back with
`minowa:update_health_norms`, which assigns the version and preserves history. `inputs-matrix`'s
purpose grouping (which substance serves which purpose) lives in that same server-side document,
drafted from the active regimen and saved only once the user confirms it.

`scored-sleep-signature` has no equivalent store yet. Its per-night signatures cannot be persisted at
all until the server exposes a call for them; the skill says so plainly and writes nothing. See that
skill's "Persistence" section for the calls required. `pmc-literature-finder` needs no store of its
own — it only searches and shortlists; saving already goes through Minowa's existing `add_reference`.

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
