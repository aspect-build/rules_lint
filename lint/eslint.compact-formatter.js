// Fork of 'compact' plugin that prints relative paths.
// This allows an editor to navigate to the location of the lint warning even though we present
// eslint with paths underneath a bazel sandbox folder.
// from https://github.com/eslint/eslint/blob/331cf62024b6c7ad4067c14c593f116576c3c861/lib/cli-engine/formatters/compact.js
const path = require("node:path");

/**
 * Returns the severity of warning or error
 * @param {Object} message message object to examine
 * @returns {string} severity level
 * @private
 */
function getMessageType(message) {
  if (message.fatal || message.severity === 2) {
    return "Error";
  }
  return "Warning";
}

module.exports = function (results, context) {
  let output = "",
    total = 0;

  results.forEach((result) => {
    const messages = result.messages;

    total += messages.length;

    messages.forEach((message) => {
      // LOCAL MODIFICATION: print path relative to the working directory
      output += `${path.relative(context.cwd, result.filePath)}: `;
      output += `line ${message.line || 0}`;
      output += `, col ${message.column || 0}`;
      output += `, ${getMessageType(message)}`;
      output += ` - ${message.message}`;
      output += message.ruleId ? ` (${message.ruleId})` : "";
      output += "\n";
    });
  });

  if (total > 0) {
    output += `\n${total} problem${total !== 1 ? "s" : ""}`;
  }

  return output;
};
