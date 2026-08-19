#!/bin/bash
#
# ci_scripts/ci_post_clone.sh — Xcode Cloud post-clone hook for Savely.
#
# WHY IT EXISTS
#   A fresh clone of this repo is missing exactly one file xcodebuild insists
#   on: Savely/Config.plist. It is gitignored (it carries the OpenAI key for
#   the Tips feature) but the Xcode project lists it as a Resources build
#   input, so on a clean checkout xcodebuild stops with "Build input file
#   cannot be found". .github/workflows/ci.yml solves this on GitHub Actions
#   by writing a placeholder; this script is the same idea for Xcode Cloud,
#   plus one honesty gate for archives (see section 2).
#
#   Unlike Fave (docs/xcode-cloud.md over there is the origin of this file),
#   Savely commits its .xcodeproj and its shared scheme, so there is no
#   project generation step here. Everything about XcodeGen was dropped.
#
# APPLE'S CONTRACT — the parts this script leans on, from
#   developer.apple.com/documentation/xcode/writing-custom-build-scripts and
#   developer.apple.com/documentation/xcode/environment-variable-reference:
#     · The file must be at ci_scripts/ci_post_clone.sh, in the same directory
#       as the Xcode project, executable, with a shebang on line 1. Without
#       the shebang or the +x bit, Xcode Cloud falls back to `zsh <file>`.
#     · "Xcode Cloud runs your custom build scripts with this directory as the
#       root directory" — the working directory is ci_scripts/, NOT the repo
#       root. Nothing below assumes otherwise.
#     · The clone is at $CI_PRIMARY_REPOSITORY_PATH.
#     · A nonzero exit fails the build, which is what every failure path here
#       does, loudly, instead of letting xcodebuild fail later.
#     · Writes into the clone survive into the xcodebuild step.
#
# SECRET DISCIPLINE (house rule: env var only, never committed, never logged)
#   If a real key is provided it arrives as the SECRET workflow environment
#   variable named in $SECRET_ENV_VAR. It is never expanded into a command
#   argument, an assignment, or an echo: `printenv` writes it straight down a
#   pipe, so even under `set -x` the trace shows the word "printenv" and not
#   the value. Every check on the resulting file uses `grep -c`/`grep -q`,
#   never a form that could print the line.
#
set -euo pipefail
set +x

# ---------------------------------------------------------------- constants --

# The workflow environment variable that carries the OpenAI key. Must be
# marked SECRET in the Xcode Cloud workflow's Environment section.
readonly SECRET_ENV_VAR="OPENAI_API_KEY"
readonly PLIST_REL="Savely/Config.plist"
readonly FLAGS_REL="Savely/Utilities/FeatureFlags.swift"

# ------------------------------------------------------------------ helpers --

log()  { printf 'ci_post_clone: %s\n' "$*"; }
fail() { printf 'ci_post_clone: ERROR: %s\n' "$*" >&2; exit 1; }

# ------------------------------------------------- 1. locate the repository --
# CI_PRIMARY_REPOSITORY_PATH is the documented location of the clone. The
# script-relative fallback is what makes this runnable by hand outside Xcode
# Cloud; whichever candidate actually holds the project wins.

repo_root=""
for candidate in "${CI_PRIMARY_REPOSITORY_PATH:-}" "$(cd "$(dirname "$0")/.." && pwd)"; do
  if [ -n "$candidate" ] && [ -f "$candidate/Savely.xcodeproj/project.pbxproj" ]; then
    repo_root="$candidate"
    break
  fi
done
[ -n "$repo_root" ] \
  || fail "could not find a repo root containing Savely.xcodeproj (tried CI_PRIMARY_REPOSITORY_PATH='${CI_PRIMARY_REPOSITORY_PATH:-<unset>}' and '$(cd "$(dirname "$0")/.." && pwd)')"

cd "$repo_root"
log "repo root: $repo_root"
[ -f "$FLAGS_REL" ] || fail "$FLAGS_REL missing; the archive gate below reads it"

# --------------------------------------------- 2. materialise Config.plist --
# Three states, all of them valid:
#   a) variable set and non-empty  -> write the real key
#   b) variable set but empty      -> write the placeholder
#   c) variable not set at all     -> write the placeholder
# The placeholder is what a fresh local clone and GitHub Actions build with:
# the app runs, OpenAIClient.init? finds a string that is not a key, and the
# Tips call answers nothing. That is fine while the Tips feature is OFF.

key_state="absent"
if printenv "$SECRET_ENV_VAR" >/dev/null 2>&1; then
  key_state="empty"
  key_chars="$(printenv "$SECRET_ENV_VAR" | tr -d '[:space:]' | wc -c | tr -d '[:space:]')"
  if [ "${key_chars:-0}" -gt 0 ]; then
    key_state="present"
  fi
fi

# The Tips feature is gated by FeatureFlags.tipsEnabled. While it is `false`
# the shipped app never touches OpenAI and a placeholder key is not merely
# acceptable, it is preferable: a real key inside a plist in the bundle can be
# lifted out of the IPA. The moment someone flips the flag on, an ARCHIVE
# without a real key would ship a Tips card that silently never loads, with a
# green checkmark on the workflow. Refuse that combination and nothing else.
tips_enabled="unknown"
if grep -Eq '^\s*static let tipsEnabled\s*=\s*true\b' "$FLAGS_REL"; then
  tips_enabled="true"
elif grep -Eq '^\s*static let tipsEnabled\s*=\s*false\b' "$FLAGS_REL"; then
  tips_enabled="false"
fi
[ "$tips_enabled" != "unknown" ] \
  || fail "could not read FeatureFlags.tipsEnabled from $FLAGS_REL; the line changed shape, update the grep here"

if [ "${CI_XCODEBUILD_ACTION:-}" = "archive" ] && [ "$tips_enabled" = "true" ] && [ "$key_state" != "present" ]; then
  fail "\$$SECRET_ENV_VAR is $key_state, CI_XCODEBUILD_ACTION=archive and FeatureFlags.tipsEnabled is true.
         Refusing to ship a release with the Tips feature on and no OpenAI key: the
         card would never load and nothing would say so.
         Either add $SECRET_ENV_VAR as a SECRET environment variable on the workflow
         (Xcode 26/27: Integrate > Manage Workflows > Environment) or turn the flag off."
fi

mkdir -p "$(dirname "$PLIST_REL")"
umask 077
{
  printf '<?xml version="1.0" encoding="UTF-8"?>\n'
  printf '<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">\n'
  printf '<plist version="1.0">\n<dict>\n'
  printf '\t<key>%s</key>\n' "$SECRET_ENV_VAR"
  printf '\t<string>'
  if [ "$key_state" = "present" ]; then
    # Whitespace stripped (a stray CR pasted into the App Store Connect field
    # would otherwise become part of the key), then XML-escaped. The value
    # never binds to a shell variable on the way.
    printenv "$SECRET_ENV_VAR" | tr -d '[:space:]' | sed -e 's/&/\&amp;/g' -e 's/</\&lt;/g' -e 's/>/\&gt;/g'
  else
    printf 'xcode-cloud-placeholder-not-a-real-key'
  fi
  printf '</string>\n</dict>\n</plist>\n'
} > "$PLIST_REL"
chmod 600 "$PLIST_REL"

if [ "$key_state" = "present" ]; then
  log "$PLIST_REL written from \$$SECRET_ENV_VAR (value not logged)"
else
  log "\$$SECRET_ENV_VAR is $key_state; $PLIST_REL written with a placeholder (tipsEnabled=$tips_enabled, action=${CI_XCODEBUILD_ACTION:-<unset>})"
fi

# ------------------------------------------------------------- 3. verify it --
# plutil -lint prints only OK / the error, never the values.
plutil -lint "$PLIST_REL" >/dev/null || fail "$PLIST_REL is not a valid plist"
[ "$(grep -c "<key>${SECRET_ENV_VAR}</key>" "$PLIST_REL")" -eq 1 ] \
  || fail "$PLIST_REL does not contain exactly one ${SECRET_ENV_VAR} entry"

if [ -n "${CI_PROJECT_FILE_PATH:-}" ] && [ ! -e "$CI_PROJECT_FILE_PATH" ]; then
  fail "Xcode Cloud expects the project at CI_PROJECT_FILE_PATH='$CI_PROJECT_FILE_PATH', which does not exist.
         Recreate the workflow against Savely.xcodeproj at the repo root."
fi

log "done — $PLIST_REL in place."
exit 0
