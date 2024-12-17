// Fork of 'compactFormatter' plugin, changed so that it prints relative paths.
// 3 files have been combined into 1
// https://github.com/stylelint/stylelint/blob/b2c99cef764643f3bd9539b34cdec58af882db88/lib/formatters/compactFormatter.mjs
// https://github.com/stylelint/stylelint/blob/b2c99cef764643f3bd9539b34cdec58af882db88/lib/formatters/preprocessWarnings.mjs
// https://github.com/stylelint/stylelint/blob/b2c99cef764643f3bd9539b34cdec58af882db88/lib/constants.mjs


/***************************************************************************************************************
 * The following is vendored from:
 * https://github.com/stylelint/stylelint/blob/b2c99cef764643f3bd9539b34cdec58af882db88/lib/constants.mjs
 ***************************************************************************************************************/
import { relative, sep } from 'node:path';

export const DEFAULT_CACHE_LOCATION = './.stylelintcache';
export const CACHE_STRATEGY_METADATA = 'metadata';
export const CACHE_STRATEGY_CONTENT = 'content';
export const DEFAULT_CACHE_STRATEGY = CACHE_STRATEGY_METADATA;

export const DEFAULT_IGNORE_FILENAME = '.stylelintignore';

export const DEFAULT_FORMATTER = 'string';

// NOTE: Partially based on `sysexits.h`.
export const EXIT_CODE_SUCCESS = 0;
export const EXIT_CODE_FATAL_ERROR = 1;
export const EXIT_CODE_LINT_PROBLEM = 2;
export const EXIT_CODE_INVALID_USAGE = 64;
export const EXIT_CODE_INVALID_CONFIG = 78;

export const RULE_NAME_ALL = 'all';

export const SEVERITY_ERROR = 'error';
export const SEVERITY_WARNING = 'warning';
export const DEFAULT_SEVERITY = SEVERITY_ERROR;

/***************************************************************************************************************
 * The following is vendored from:
 * https://github.com/stylelint/stylelint/blob/b2c99cef764643f3bd9539b34cdec58af882db88/lib/formatters/preprocessWarnings.mjs
 ***************************************************************************************************************/
/** @import {LintResult} from 'stylelint' */
/** @typedef {LintResult['parseErrors'][0]} ParseError */
/** @typedef {LintResult['warnings'][0]} Warning */
/** @typedef {Warning['severity']} Severity */

/**
 * Preprocess warnings in a given lint result.
 * Note that this function has a side-effect.
 *
 * @param {LintResult} result
 * @returns {LintResult}
 */
export function preprocessWarnings(result) {
	for (const error of result.parseErrors || []) {
		result.warnings.push(parseErrorToWarning(error));
	}

	for (const warning of result.warnings) {
		warning.severity = normalizeSeverity(warning);
	}

	result.warnings.sort(byLocationOrder);

	return result;
}

/**
 * @param {ParseError} error
 * @returns {Warning}
 */
function parseErrorToWarning(error) {
	return {
		line: error.line,
		column: error.column,
		rule: error.stylelintType,
		severity: SEVERITY_ERROR,
		text: `${error.text} (${error.stylelintType})`,
	};
}

/**
 * @param {Warning} warning
 * @returns {Severity}
 */
function normalizeSeverity(warning) {
	// NOTE: Plugins may add a warning without severity, for example,
	// by directly using the PostCSS `Result#warn()` API.
	return warning.severity || DEFAULT_SEVERITY;
}

/**
 * @param {Warning} a
 * @param {Warning} b
 * @returns {number}
 */
function byLocationOrder(a, b) {
	// positionless first
	if (!a.line && b.line) return -1;

	// positionless first
	if (a.line && !b.line) return 1;

	if (a.line < b.line) return -1;

	if (a.line > b.line) return 1;

	if (a.column < b.column) return -1;

	if (a.column > b.column) return 1;

	return 0;
}

/***************************************************************************************************************
 * The following is vendored from:
 * https://github.com/stylelint/stylelint/blob/b2c99cef764643f3bd9539b34cdec58af882db88/lib/formatters/compactFormatter.mjs
 ***************************************************************************************************************/
/**
 * @type {import('stylelint').Formatter}
 * @param {import('stylelint').Warning[]} messages
 * @param {string} source
 * @param {string} cwd
 */
export default function compactFormatter(results, returnValue) {
	return results
		.flatMap((result) => {
			const { warnings } = preprocessWarnings(result);

			return warnings.map(
				(warning) =>
					`${relative((returnValue && returnValue.cwd) || process.cwd(), result.source).split(sep).join('/')}: ` +
					`line ${warning.line}, ` +
					`col ${warning.column}, ` +
					`${warning.severity} - ` +
					`${warning.text}`,
			);
		})
		.join('\n');
}