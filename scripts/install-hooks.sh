#!/usr/bin/env bash
# Activate the project's git hooks.
# Run this once after cloning the repo.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

# Make hook scripts executable
chmod +x .githooks/pre-commit
chmod +x .githooks/commit-msg

# Point git at our hooks dir
git config core.hooksPath .githooks

echo "✅ Git hooks activated."
echo ""
echo "Hooks installed:"
echo "  pre-commit  — runs SwiftLint on staged .swift files"
echo "  commit-msg  — enforces Conventional Commits format"
echo ""
echo "If you don't have SwiftLint yet:"
echo "  brew install swiftlint"
