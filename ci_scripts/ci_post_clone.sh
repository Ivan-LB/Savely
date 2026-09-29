#!/bin/bash
#
# ci_scripts/ci_post_clone.sh — Xcode Cloud post-clone hook for Savely.
#
# WHY IT EXISTS
#   Until 1.1 this script wrote Savely/Config.plist (the OpenAI key for the
#   Tips feature), because the Xcode project listed it as a Resources build
#   input and a clean checkout would not build without it. That entry was the
#   bug: anything in Resources ships inside the IPA, and a key in a bundled
#   plist can be lifted out by anyone (docs/plans/drop-bundled-config-plist.md).
#   Config.plist is no longer a build input, so nothing needs materialising.
#
#   What is left is one honesty gate for archives: the Tips feature has no
#   safe way to get a key today, so an archive with FeatureFlags.tipsEnabled
#   set to true would ship a Tips card that silently never loads. Refuse it.
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
#
set -euo pipefail
set +x

# ---------------------------------------------------------------- constants --

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

# ------------------------------------------------ 2. the Tips archive gate --

tips_enabled="unknown"
if grep -Eq '^\s*static let tipsEnabled\s*=\s*true\b' "$FLAGS_REL"; then
  tips_enabled="true"
elif grep -Eq '^\s*static let tipsEnabled\s*=\s*false\b' "$FLAGS_REL"; then
  tips_enabled="false"
fi
[ "$tips_enabled" != "unknown" ] \
  || fail "could not read FeatureFlags.tipsEnabled from $FLAGS_REL; the line changed shape, update the grep here"

if [ "${CI_XCODEBUILD_ACTION:-}" = "archive" ] && [ "$tips_enabled" = "true" ]; then
  fail "CI_XCODEBUILD_ACTION=archive and FeatureFlags.tipsEnabled is true.
         Refusing to ship the Tips feature: it has no safe key source. A bundled
         Config.plist is equivalent to publishing the key; serve it from a proxy
         you control first (docs/plans/drop-bundled-config-plist.md, step 3),
         then update this gate."
fi

# ------------------------------------------------------------ 3. sanity check --

if [ -n "${CI_PROJECT_FILE_PATH:-}" ] && [ ! -e "$CI_PROJECT_FILE_PATH" ]; then
  fail "Xcode Cloud expects the project at CI_PROJECT_FILE_PATH='$CI_PROJECT_FILE_PATH', which does not exist.
         Recreate the workflow against Savely.xcodeproj at the repo root."
fi

log "done (tipsEnabled=$tips_enabled, action=${CI_XCODEBUILD_ACTION:-<unset>})."
exit 0
