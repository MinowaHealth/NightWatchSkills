# NightWatch

[Claude Skills](https://docs.claude.com) for turning personal wearable + health-tracking
data (via the **Minowa MCP server** — Garmin sleep/HR/stress, blood pressure, medications,
observations) into precise, honest analysis.

| Skill | Question it answers | Role |
|-------|--------------------|------|
| **health-episode-report** | *What happened during this window?* | Charts and narrates any timeframe (a night, an episode, a nap) — HR/stress trace, scored hypnogram or inferred rest, BP, doses, verbatim observations. |
| **intake-interview** | *Who is this person and how should their data be read?* | Onboards a new user: captures the health baseline and elicits their personal monitoring norms, seeding the first dated `HealthMonitoringNorms` document. |
| **scored-sleep-signature** | *How did I get into this (scored) night?* | Reconstructs the pre-sleep **run-up** of a Garmin-**scored** night, extracts its "signature," and logs it so good- vs poorer-scored approaches accumulate and become comparable. |

**intake-interview** runs once, at the start: it establishes who the person is and seeds the
`HealthMonitoringNorms` document that both analysis skills read before writing a word. The two
analysis skills then divide the ongoing work cleanly:

> **Scored Sleep Signature finds what works. Episode Analysis surfaces what doesn't.**

Signature deliberately looks only at **scored** nights (approaches that led to a real, measured
outcome) to isolate the ingredients of a good night. The genuinely bad nights — too short or
fragmented for Garmin to score — are surfaced by Episode Analysis instead, which handles inferred
rest. Restricting Signature to scored nights is a feature, not a gap: it keeps every entry anchored
to a measured outcome.

## Repository layout

```
NightWatch/
├── README.md
├── LICENSE
├── .gitignore
├── skills/
│   ├── health-episode-report/          # analysis: the window (see its README)
│   │   ├── SKILL.md
│   │   ├── HealthMonitoringNorms.example.md   # committed template
│   │   ├── HealthMonitoringNorms.md     # LOCAL ONLY — gitignored (personal)
│   │   ├── assets/report_template.html  # the single-page report template
│   │   └── references/                  # data-fetch quirks + report-format spec
│   ├── intake-interview/                # onboarding: seeds the norms (see its README)
│   │   ├── SKILL.md
│   │   ├── assets/norms_seed.md         # starting norms document for a new user
│   │   └── references/                  # interview guide, norms taxonomy, commit path
│   └── scored-sleep-signature/          # analysis: the run-up (see its README)
│       ├── SKILL.md
│       ├── SleepSignatureLog.example.md # committed template
│       ├── SleepSignatureLog.md         # LOCAL ONLY — gitignored (personal)
│       └── references/signature-axes.md
├── dist/                                # packaged .skill files for one-click install
│   ├── health-episode-report.skill      # built from the *.example.md templates only
│   ├── intake-interview.skill
│   └── scored-sleep-signature.skill
└── examples/                            # how to generate example outputs (see README)
```

## Requirements

- The **Minowa MCP server** connected in Claude (provides `get_garmin_minute_detail`,
  `get_sleep_events_detail`, `get_observations_detail`, `get_vitals_timeline`,
  `get_recent_activity`, `get_current_time`, `date_math`, etc.).
- A **Garmin** device syncing sleep/HR/stress, plus manually logged BP, medications, and
  observations in Minowa.
- A Claude surface that supports Skills and file creation (Claude.ai, Claude Code, or Cowork).

## Install

**Option A — packaged (`dist/*.skill`):** open the `.skill` file in a Claude surface that supports
skills and click **Save skill**.

Packaged skills ship the `*.example.md` templates under the live filenames, so a fresh install starts
with the structure and the generic norms and none of anyone's records. Your own accumulated norms
stay in your working copy.

**Option B — from source:** point Claude Code (or your skills directory) at
`skills/health-episode-report/`, `skills/intake-interview/`, and `skills/scored-sleep-signature/`.
Each skill is self-contained under its own folder, with one dependency: `scored-sleep-signature`
expects `health-episode-report` to be installed alongside it (it reuses that skill's Minowa fetch
conventions and shares its norms). `intake-interview` stands alone and is what produces the norms
document the other two consume.

## The "memory" files

`intake-interview` creates the first of these; the two analysis skills accumulate corrections and
observations into them over time. This is what makes them sharpen with use rather than repeating
mistakes:

- `health-episode-report/HealthMonitoringNorms.md` — inference rules that only get appended to when a
  reading is corrected (e.g. how two different BP meters diverge, how an input → physiology → outcome chain
  reads, that cold feet is a symptom).
- `scored-sleep-signature/SleepSignatureLog.md` — one dated paragraph per scored night, plus an
  "emerging associations" section that stays explicitly non-causal.

When the model is corrected, it appends to these files and re-saves the skill, so the fix persists.

## Personal health data

`HealthMonitoringNorms.md` and `SleepSignatureLog.md` hold **personal health information** — dated
sleep records, medications and doses, symptoms, blood pressure. They are **gitignored and stay
local.** The committed versions are the `*.example.md` templates, which carry the structure and the
generic, non-personal norms.

This is not a setting to decide about at publish time. The ignore rules are active by default and
should stay that way; do not uncomment or remove them to "just get everything in." If you need the
live files somewhere else, move them by hand outside the repo.

The same applies to generated output — episode reports, intake summaries, and dated norms versions
all contain health data, and `.gitignore` covers their filename patterns too.

**A `.gitignore` cannot see inside an archive.** `dist/*.skill` files are zips, and they are
committed. If one is built from the working copy while the live `HealthMonitoringNorms.md` or
`SleepSignatureLog.md` is present, the personal file is sealed inside the archive and rides straight
past every ignore rule and every filename-based check. Build `dist/` with `tools/build-skills.sh`,
which packages the `*.example.md` templates under the live filenames and never reads the live files.

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
