#!/usr/bin/env bash

# Stopgap for `aspect setup workspace-data` (aspect-build/aspect-cli#1465).
#
# Emits the build metadata `aspect <task>` sends as `--build_metadata`, in the
# `KEY value` form Bazel's --workspace_status_command expects, so a vanilla
# `bazel` invocation is attributed in the Aspect Web UI instead of arriving
# anonymous. Once #1465 ships, delete this file and pass the CLI directly:
#
#   --workspace_status_command="aspect setup workspace-data"
#
# Two constraints shape what follows. Bazel fails the build outright when the
# status command exits non-zero, so every lookup here is best-effort and the
# script always exits 0. And a value is the rest of its line, so newlines are
# collapsed rather than quoted.
#
# Keys are unprefixed so they land in volatile-status.txt; a STABLE_ key would
# invalidate every stamped action whenever the commit moves.

set -u

emit() {
  [ -n "${2:-}" ] || return 0
  printf '%s %s\n' "$1" "$(printf '%s' "$2" | tr '\r\n' '  ')"
}

git_field() {
  git log -1 --pretty=format:"$1" 2>/dev/null || true
}

if [ -n "${GITHUB_ACTIONS:-}" ]; then
  server="${GITHUB_SERVER_URL:-https://github.com}"
  repo="${GITHUB_REPOSITORY:-}"

  emit CI_HOST GITHUB_ACTIONS
  emit VCS GITHUB
  emit REPO_OWNER "${repo%%/*}"
  emit REPO_NAME "${repo##*/}"
  emit REPO_URL "$server/$repo"
  emit BUILD_URL "$server/$repo/actions/runs/${GITHUB_RUN_ID:-}"
  emit USER "${GITHUB_ACTOR:-}"

  case "${GITHUB_EVENT_NAME:-}" in
    pull_request | pull_request_target)
      pr="${GITHUB_REF:-}"
      pr="${pr#refs/pull/}"
      pr="${pr%%/*}"
      emit RUN_TYPE PULL_REQUEST
      emit BRANCH_NAME "${GITHUB_HEAD_REF:-}"
      emit PR_SOURCE_BRANCH_NAME "${GITHUB_HEAD_REF:-}"
      emit PR_TARGET_BRANCH_NAME "${GITHUB_BASE_REF:-}"
      emit PR_NUMBER "$pr"
      emit PR_ID "$pr"
      ;;
    *)
      emit RUN_TYPE BRANCH
      emit BRANCH_NAME "${GITHUB_REF_NAME:-}"
      ;;
  esac
fi

# On a pull_request run this describes the forge's merge commit, which is what
# `aspect <task>` reports today too; aspect-build/aspect-cli#1459 changes both
# to the PR head.
emit COMMIT_SHA "$(git_field %H)"
emit COMMIT_AUTHOR_NAME "$(git_field %an)"
emit COMMIT_AUTHOR_EMAIL "$(git_field %ae)"
emit COMMIT_AUTHOR "$(git_field '%an <%ae>')"
emit COMMIT_MESSAGE "$(git_field %s)"
emit COMMIT_TIMESTAMP "$(git_field %cI)"

exit 0
