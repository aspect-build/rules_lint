#!/usr/bin/env bash
#
# Shows an end-to-end workflow for linting without failing the build.
# This is meant to mimic the behavior of the `bazel lint` command that you'd have
# by using the Aspect CLI [lint command](https://docs.aspect.build/cli/commands/aspect_lint).
#
# To make the build fail when a linter warning is present, run with `--fail-on-violation`.
# To auto-fix violations, run with `--fix` (or `--fix --dry-run` to just print the patches)
#
# NB: this is an example of code you could paste into your repo, meaning it's userland
# and not a supported public API of rules_lint. It may be broken and we don't make any
# promises to fix issues with using it.
# We recommend using Aspect CLI instead!
set -o errexit -o pipefail -o nounset

if [ "$#" -eq 0 ]; then
	echo "usage: lint.sh [target pattern...]"
	exit 1
fi

fix=""
buildevents=$(mktemp)
filter='.namedSetOfFiles | values | .files[] | ((.pathPrefix | join("/")) + "/" + .name)'

# NB: perhaps --remote_download_toplevel is needed as well with remote execution?
args=(
	"--aspects=$(echo //tools/lint:linters.bzl%{buf,eslint,flake8,pmd,ruff,shellcheck,golangci_lint,vale} | tr ' ' ',')"
	"--build_event_json_file=$buildevents"
)
report_args=(
	"--output_groups=rules_lint_report"
	"--remote_download_regex='.*aspect_rules_lint.report'"
)

# This is a rudimentary flag parser.
if [ $1 == "--fail-on-violation" ]; then
	args+=(
		"--@aspect_rules_lint//lint:fail_on_violation"
		"--keep_going"
	)
	shift
fi
if [ $1 == "--fix" ]; then
	fix="patch"
	# override this flag
	patch_args=(
		"--output_groups=rules_lint_patch"
		"--remote_download_regex='.*aspect_rules_lint.patch'"
	)
	shift
fi
# NB: the --dry-run flag must immediately follow the --fix flag
if [ $1 == "--dry-run" ]; then
	fix="print"
	shift
fi

# Produce report files
bazel build ${args[@]} ${report_args[@]} $@

# TODO: Maybe this could be hermetic with bazel run @aspect_bazel_lib//tools:jq or sth
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

# This happens to make output of the linter such as ruff's
# [*] 1 fixable with the `--fix` option.
# so that the naive thing of pasting that flag to lint.sh will do what the user expects.
if [ -n "$fix" ]; then
	# redo the build with this new requested output
	bazel build ${args[@]} ${patch_args[@]} $@
	valid_patches=$(jq --raw-output "$filter" "$buildevents")
	while IFS= read -r patch; do
		# Exclude coverage reports, and check if the report is empty.
		if [[ "$patch" == *coverage.dat ]] || [[ ! -s "$patch" ]]; then
			# Report is empty. No linting errors.
			continue
		fi

		case "$fix" in
		"print")
			echo "From ${patch}:"
			cat "${patch}"
			echo
			;;
		"patch")
			patch -p1 <${patch}
			;;
		*)
			echo >2 "ERROR: unknown fix type $fix"
			exit 1
			;;
		esac

	done <<<"$valid_patches"
fi
