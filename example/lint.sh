#!/usr/bin/env bash
#
# Shows an end-to-end workflow for linting without failing the build.
# This is meant to mimic the behavior of the `bazel lint` command that you'd have
# by using the Aspect CLI.
#
# To make the build fail when a linter warning is present, run with --fail-on-violation
#
# We recommend using Aspect CLI instead!
set -o errexit -o pipefail -o nounset

if [ "$#" -eq 0 ]; then
	echo "usage: lint.sh [target pattern...]"
	exit 1
fi

buildevents=$(mktemp)
filter='.namedSetOfFiles | values | .files[] | ((.pathPrefix | join("/")) + "/" + .name)'

# NB: perhaps --remote_download_toplevel is needed as well with remote execution?
args=(
	"--aspects=$(echo //tools:lint.bzl%{buf,eslint,flake8,pmd,ruff,shellcheck} | tr ' ' ',')"
	"--build_event_json_file=$buildevents"
	"--output_groups=rules_lint_report"
	"--remote_download_regex='.*aspect_rules_lint.report'"
)
if [ $1 == "--fail-on-violation" ]; then
	args+=(
		"--aspects_parameters=fail_on_violation=true"
		"--keep_going"
	)
	shift
fi

# Produce report files
bazel build ${args[@]} $@

valid_reports=$(jq --raw-output "$filter" "$buildevents")

# Show the results.
while IFS= read -r report; do
	# Exclude coverage reports, and check if the report is empty.
	if [[ "$report" == *coverage.dat ]] || [[ ! -s "$report" ]]; then
		# Report is empty. No linting errors.
		continue
	fi
	echo "From ${report}:"
	cat "${report}"
	echo
done <<<"$valid_reports"
