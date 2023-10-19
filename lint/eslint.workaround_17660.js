// Workaround for https://github.com/eslint/eslint/issues/17660
// Use as a --require script so that this script is evaluated before the eslint entry point.
// Creates an empty report file just in case eslint doesn't try to write one.
const fs = require("fs");
for (let i = 0; i < process.argv.length; i++) {
  if (process.argv[i] == "--output-file") {
    fs.closeSync(fs.openSync(process.argv[i + 1], "w"));
  }
}
