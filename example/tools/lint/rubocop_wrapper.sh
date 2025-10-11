#!/usr/bin/env bash
set -o errexit -o nounset -o pipefail

# Simple wrapper for RuboCop
# This assumes RuboCop is installed and available in PATH
# In a real project, this would likely use `bundle exec rubocop`

if ! command -v rubocop &>/dev/null; then
  echo "Error: rubocop not found in PATH" >&2
  echo "Please install rubocop: gem install rubocop" >&2
  exit 1
fi

exec rubocop "$@"
