// Fork of 'stylish' plugin that prints relative paths.
// This allows an editor to navigate to the location of the lint warning even though we present
// eslint with paths underneath a bazel sandbox folder.
// from https://github.com/eslint/eslint/blob/331cf62024b6c7ad4067c14c593f116576c3c861/lib/cli-engine/formatters/stylish.js
const path = require("node:path");

/**
 * Given a word and a count, append an s if count is not one.
 * @param {string} word A word in its singular form.
 * @param {int} count A number controlling whether word should be pluralized.
 * @returns {string} The original word with an s on the end if count is not one.
 */
function pluralize(word, count) {
  return count === 1 ? word : `${word}s`;
}

module.exports = function (results, context) {
  let output = "",
    errorCount = 0,
    warningCount = 0,
    fixableErrorCount = 0,
    fixableWarningCount = 0;

  results.forEach((result) => {
    const messages = result.messages;

    if (messages.length === 0) {
      return;
    }

    errorCount += result.errorCount;
    warningCount += result.warningCount;
    fixableErrorCount += result.fixableErrorCount;
    fixableWarningCount += result.fixableWarningCount;

    const relpath = path.relative(context.cwd, result.filePath);

    messages.forEach((message) => {
      const msgtext = message.message.replace(/([^ ])\.$/u, "$1");
      const severity =
        message.fatal || message.severity === 2 ? "error" : "warning";
      const location = [relpath, message.line, message.column].join(":");
      output += `${location}: ${msgtext}  [${severity} from ${
        message.ruleId || ""
      }]\n`;
    });
  });

  const total = errorCount + warningCount;
  if (total > 0) {
    output += [
      "\n",
      "\u2716 ",
      total,
      pluralize(" problem", total),
      " (",
      errorCount,
      pluralize(" error", errorCount),
      ", ",
      warningCount,
      pluralize(" warning", warningCount),
      ")\n",
    ].join("");

    if (fixableErrorCount > 0 || fixableWarningCount > 0) {
      output += [
        "  ",
        fixableErrorCount,
        pluralize(" error", fixableErrorCount),
        " and ",
        fixableWarningCount,
        pluralize(" warning", fixableWarningCount),
        " potentially fixable with the `--fix` option.\n",
      ].join("");
    }
  }
  return output;
};
