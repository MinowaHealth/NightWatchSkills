# NightWatch — working rules

## The hard rule

**Everything under `skills/` is a public artifact. No personal data, ever.**

Personal data means: medication and supplement names from a real stack, condition or
symptom names, a user's private vocabulary for a sensation, dated records, verbatim
quotes from observations, clock times attached to doses, device models, place names,
timezones, absolute paths, IPs, email addresses, and third-person references to a
specific person ("his baseline", "her stack").

All of it lives in the Minowa document store and is fetched at runtime with
`minowa:get_health_norms`. The skills describe *method*; the server supplies the
*person*. If a rule feels necessary to state in a skill file, that is the signal it
belongs in the norms document instead.

## How this is enforced

There is no hook that fires on an agent editing a file, so enforcement is a script
that several things call, plus one rule for the agent:

1. **`tools/check-public-safe.sh`** — the single source of truth. Two jobs.

   *Privacy:* structural detectors (dates, dose-log shapes, paths, IPs, emails,
   gendered possessives) plus a term denylist read from `tools/.pii-terms`. That term
   file is **gitignored on purpose** — a list of someone's medications *is* the data we
   are keeping out. Commit only `.pii-terms.example`.

   *Packaging:* `name:` must be a lowercase slug matching its directory, and
   `description:` must be **≤ 1024 characters**. Over that, the skill silently fails to
   install — and it is easy to cross by one character while editing prose, so it is
   checked here rather than discovered at install time.
2. **`tools/build-skills.sh`** gates on it before packaging and again after, so a dirty
   tree cannot produce an archive.
3. **`tools/githooks/pre-commit`** runs it. Enable once per clone:
   `git config core.hooksPath tools/githooks`. Versioned, unlike `.git/hooks`, so it
   survives a fresh clone.
4. **`.github/workflows/public-safe.yml`** runs it on every push and PR, and also
   rebuilds the archives and diffs them against the committed ones. This is the layer
   that cannot be bypassed — `--no-verify` skips the hook, not CI.

### Rule for the agent (this is layer zero)

**Run `./tools/check-public-safe.sh` and see it PASS before writing any file into this
repo.** Do not write first and check after. If it fails, fix the finding — do not
weaken the check to make it pass. If a genuine false positive appears, narrow the
pattern and say so explicitly in the response.

Corollary: when the user states a norm during a session, the reflex is
`minowa:update_health_norms`, never editing a skill file to record it.

## Other standing rules

- **Never run `git` through `device_bash`.** It strands `.git/index.lock` and blocks
  the user's own commits. Write files; let the user stage and commit.
- **Never hand-build `dist/`.** Use `tools/build-skills.sh`.
- Live memory files (`HealthMonitoringNorms.md`, `SleepSignatureLog.md`) are gitignored
  and must never appear in the source tree or inside an archive. The committed
  artifacts are the `.example.md` templates.
