#!/usr/bin/env bash
# Fail the build if anything in skills/, dist/ or the docs looks like a personal
# record, or if a skill would not install.
#
# The skills are public artifacts. All personal data — norms, baselines, thresholds,
# a user's own vocabulary — lives in the Minowa document store and is fetched at
# runtime with get_health_norms. Nothing personal belongs in this repo.
#
# Run directly, or via tools/build-skills.sh, the pre-commit hook, or CI.
#   ./tools/check-public-safe.sh          # scan the working tree and dist/
#   STRICT=1 ./tools/check-public-safe.sh # also fail if the term list is absent
#   SKIP_DIST=1 ./tools/check-public-safe.sh  # source only (dist/ about to be rebuilt)
set -uo pipefail

cd "$(dirname "$0")/.."
ROOT=$(pwd)
fail=0
note() { printf '  %-9s %s\n' "$1" "$2"; }
hit()  { fail=1; note "BLOCK" "$1"; }

# Everything published: skill sources, the built archives, and the docs that ship with them.
SCAN_DIRS=(skills)
SCAN_FILES=(README.md)

echo "Checking public-release safety..."

# ── 1. No records file of any kind may sit in the source tree ─────────────────
# The skills hold no data: norms and signatures live on the Minowa server and are
# fetched at runtime. That makes this stricter than it used to be — the .example
# templates are banned too, because a template under a records filename is exactly
# what gets mistaken for the live document once it is installed.
records=$(find "${SCAN_DIRS[@]}" \( -name 'HealthMonitoringNorms*' -o -name 'SleepSignatureLog*' \) 2>/dev/null || true)
if [ -n "$records" ]; then
  hit "records file in the source tree — norms and signatures belong on the server"
  printf '%s\n' "$records" | sed 's/^/            /'
fi

# ── 2. Built archives must carry no records file at all ───────────────────────
# A .gitignore cannot see inside a zip, so archive members are inspected directly.
# SKIP_DIST=1 is used by the pre-build gate in build-skills.sh, where dist/ is
# about to be regenerated and a stale archive is not yet a finding.
if [ "${SKIP_DIST:-0}" != "1" ] && compgen -G "dist/*.skill" > /dev/null; then
  for z in dist/*.skill; do
    while read -r member; do
      case "$member" in
        */HealthMonitoringNorms*|*/SleepSignatureLog*)
          hit "$z: contains a records file ($member) — skills carry no data" ;;
      esac
    done < <(unzip -Z1 "$z")
    # and no dated record files smuggled in
    unzip -Z1 "$z" | grep -qE '20[0-9]{2}-[0-9]{2}-[0-9]{2}' \
      && hit "$z: contains a dated file"
  done
fi

# ── 3. Structural tells — no wordlist needed, safe to keep in a public repo ───
# A calendar date inside a skill almost always means a real logged day.
# Compute once, so what is reported and what fails the build cannot diverge.
# No --exclude here: there are no template files left to exempt, and an exemption
# by filename would be a hole the moment one reappeared.
dated=$(grep -rnE '20[0-9]{2}-[0-9]{2}-[0-9]{2}' "${SCAN_DIRS[@]}" 2>/dev/null || true)
if [ -n "$dated" ]; then
  hit "dated record (a real logged day) in a skill"
  printf '%s\n' "$dated" | head -8 | cut -c1-130 | sed 's/^/            /'
fi

# Machine-local and identity leakage.
for pat in '/Users/[a-z]' '/home/[a-z]' \
           '[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}' \
           '[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'; do
  if grep -rqE "$pat" "${SCAN_DIRS[@]}" "${SCAN_FILES[@]}" 2>/dev/null; then
    hit "machine-local or identifying string matching /$pat/"
    grep -rnE "$pat" "${SCAN_DIRS[@]}" "${SCAN_FILES[@]}" 2>/dev/null | head -5 | sed 's/^/            /'
  fi
done

# A clock time next to a quantity is the shape of a dose log.
if grep -rqiE '@ *[0-9]{1,2}:[0-9]{2} *(am|pm)' "${SCAN_DIRS[@]}" 2>/dev/null; then
  hit "dose-log shape (quantity @ clock time)"
  grep -rniE '@ *[0-9]{1,2}:[0-9]{2} *(am|pm)' "${SCAN_DIRS[@]}" | head -5 | sed 's/^/            /'
fi

# Third-person singular about a specific person, rather than "the user" / "they".
# Widened: the old pattern required a noun after his/her ("his baseline"), so prose
# like "whenever he is moving" passed. Skill files describe method for anyone, so ANY
# gendered pronoun under skills/ is a finding. Compute once, so what is reported and
# what fails the build cannot diverge. README.md is deliberately outside this scan —
# it quotes "his baseline" as the example of what this very rule blocks.
gendered=$(grep -rnE '\b([Hh]e|[Hh]im|[Hh]is|[Ss]he|[Hh]er|[Hh]ers)\b' "${SCAN_DIRS[@]}" 2>/dev/null || true)
if [ -n "$gendered" ]; then
  hit "written about a specific person — use \"the user\" / \"they\""
  printf '%s\n' "$gendered" | head -5 | cut -c1-130 | sed 's/^/            /'
fi

# ── 4. Term denylist — the list itself is personal, so it is NOT committed ────
# Keep one term per line in tools/.pii-terms (gitignored). See .pii-terms.example.
TERMS="$ROOT/tools/.pii-terms"
if [ -f "$TERMS" ]; then
  n=0
  while IFS= read -r term; do
    [ -z "$term" ] && continue
    case "$term" in \#*) continue ;; esac
    if grep -rqiF "$term" "${SCAN_DIRS[@]}" "${SCAN_FILES[@]}" 2>/dev/null; then
      hit "denylisted term present (see tools/.pii-terms)"
      grep -rniF "$term" "${SCAN_DIRS[@]}" "${SCAN_FILES[@]}" 2>/dev/null | head -3 | sed 's/^/            /'
      n=$((n+1))
    fi
  done < "$TERMS"
  note "checked" "$(grep -cvE '^\s*(#|$)' "$TERMS") denylisted terms, $n present"
else
  if [ "${STRICT:-0}" = "1" ]; then
    hit "tools/.pii-terms missing and STRICT=1"
  else
    note "SKIP" "tools/.pii-terms not found — term scan skipped (copy .pii-terms.example)"
  fi
fi

# ── 5. Skill packaging validity ───────────────────────────────────────────────
# A SKILL.md whose frontmatter is invalid cannot be installed. The description
# field has a hard 1024-character ceiling, and it is easy to cross by one while
# editing prose — so it is checked here rather than discovered at install time.
DESC_MAX=1024
for sk in skills/*/SKILL.md; do
  [ -f "$sk" ] || continue
  dir=$(basename "$(dirname "$sk")")

  # Pull `name:` and `description:` out of the YAML frontmatter. description may
  # wrap across lines: it runs until the next `key:` or the closing ---.
  read -r nm dlen <<EOF
$(awk '
  NR==1 && $0=="---" { fm=1; next }
  fm && $0=="---"    { fm=0 }
  fm {
    if ($0 ~ /^name:[[:space:]]*/)        { n=$0; sub(/^name:[[:space:]]*/,"",n) }
    else if ($0 ~ /^description:[[:space:]]*/) { d=$0; sub(/^description:[[:space:]]*/,"",d); ind=1 }
    else if ($0 ~ /^[A-Za-z_-]+:/)        { ind=0 }
    else if (ind)                         { line=$0; gsub(/^[[:space:]]+/,"",line); d = d " " line }
  }
  END { gsub(/[[:space:]]+/," ",d); gsub(/^ | $/,"",d); print n, length(d) }
' "$sk")
EOF

  [ -n "$nm" ] || hit "$sk: frontmatter has no name:"
  [ "$nm" = "$dir" ] || hit "$sk: name: '$nm' does not match directory '$dir'"
  case "$nm" in
    *[!a-z0-9-]*) hit "$sk: name: '$nm' is not a lowercase slug" ;;
  esac
  if [ "${dlen:-0}" -eq 0 ]; then
    hit "$sk: frontmatter has no description:"
  elif [ "$dlen" -gt "$DESC_MAX" ]; then
    hit "$sk: description is $dlen chars, limit is $DESC_MAX — it will fail to install"
  else
    note "ok" "$dir description $dlen/$DESC_MAX chars"
  fi
done

echo
if [ "$fail" -eq 0 ]; then
  echo "  PASS — nothing personal found. Safe to build/commit/publish."
else
  echo "  FAIL — not safe to publish. For personal data: move it to the Minowa"
  echo "         norms document (minowa:update_health_norms) and generalize the"
  echo "         text here. For packaging errors: fix the frontmatter."
fi
exit "$fail"
