#!/usr/bin/env bash
# Build dist/*.skill archives from source.
#
# The skills hold no data. Norms and every other personal record live on the Minowa
# server and are fetched at runtime, so an archive is source files only — no norms
# file, no log file, and no template standing in for either. If something needs to
# persist and has no server call, that is a server requirement, not a packaged file.
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

  rm -f "$out"
  ( cd "$stage" && zip -qr "$out" "$skill" -x '*.DS_Store' )
  rm -rf "$stage"
  printf '  built %-28s %s\n' "$skill.skill" "$(unzip -l "$out" | tail -1 | awk '{print $2" files"}')"
}

echo "Building skill archives from source (source files only, no data of any kind)..."
build health-episode-report
build scored-sleep-signature
build intake-interview
build match-my-symptoms
build inputs-matrix
build pmc-literature-finder
build minowa-guide

echo
# Single source of truth for what "safe to publish" means. Same script the
# pre-commit hook and CI run, so all three can never drift apart.
exec "$ROOT/tools/check-public-safe.sh"
