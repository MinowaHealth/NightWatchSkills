#!/usr/bin/env bash
# Build dist/*.skill archives from source.
#
# The memory files (HealthMonitoringNorms.md, SleepSignatureLog.md) hold personal
# health records and are gitignored. This script NEVER reads them. Where a skill
# expects one, the committed *.example.md template is packaged under the live
# filename, so a fresh install gets the structure and the generic norms and none
# of anyone's records.
set -euo pipefail

cd "$(dirname "$0")/.."
ROOT=$(pwd)
DIST="$ROOT/dist"
mkdir -p "$DIST"

# Refuse to package a tree that is not publishable in the first place.
SKIP_DIST=1 "$ROOT/tools/check-public-safe.sh" >/dev/null || {
  echo "build aborted — run ./tools/check-public-safe.sh to see what is wrong" >&2
  exit 1
}

build() {
  local skill="$1"; shift
  local src="$ROOT/skills/$skill"
  local stage; stage=$(mktemp -d)
  local out="$DIST/$skill.skill"

  mkdir -p "$stage/$skill"
  cp "$src/SKILL.md" "$stage/$skill/"
  [ -d "$src/references" ] && cp -R "$src/references" "$stage/$skill/"
  [ -d "$src/assets" ]     && cp -R "$src/assets"     "$stage/$skill/"

  # each remaining arg is "example-file:packaged-name"
  local pair example packaged
  for pair in "$@"; do
    example="${pair%%:*}"; packaged="${pair##*:}"
    cp "$src/$example" "$stage/$skill/$packaged"
  done

  rm -f "$out"
  ( cd "$stage" && zip -qr "$out" "$skill" -x '*.DS_Store' )
  rm -rf "$stage"
  printf '  built %-28s %s\n' "$skill.skill" "$(unzip -l "$out" | tail -1 | awk '{print $2" files"}')"
}

echo "Building skill archives from source (templates only, no personal data)..."
build health-episode-report  "HealthMonitoringNorms.example.md:HealthMonitoringNorms.md"
build scored-sleep-signature "SleepSignatureLog.example.md:SleepSignatureLog.md"
build intake-interview

echo
# Single source of truth for what "safe to publish" means. Same script the
# pre-commit hook and CI run, so all three can never drift apart.
exec "$ROOT/tools/check-public-safe.sh"
