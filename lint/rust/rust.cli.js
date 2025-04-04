#!/usr/bin/env node

const fs = require("fs");
const {
  diagnosticsToSarifPatchFile,
  diagnosticsToHumanReadable,
} = require("./rust.diagnostic-formatter");

/**
 * Main function that processes command line arguments and executes the appropriate function
 */
function main() {
  // Check if we have the correct number of arguments
  if (process.argv.length !== 5) {
    console.error(
      "Usage: node rust.cli.js <command> <input-file> <output-file>"
    );
    console.error('  command: "human-readable" or "patch"');
    process.exit(1);
  }

  const outputType = process.argv[2];
  const inputFile = process.argv[3];
  const outputFile = process.argv[4];

  // Validate output type
  if (outputType !== "human-readable" && outputType !== "patch") {
    console.error(
      'Error: output-type must be either "human-readable" or "patch"'
    );
    process.exit(1);
  }

  try {
    // Read and parse the input file
    const fileContent = fs.readFileSync(inputFile, "utf8");

    const diagnostics = fileContent
      .split("\n")
      .filter((line) => line.trim() !== "")
      .filter((line) => line.startsWith("{"))
      .map((line) => {
        try {
          return JSON.parse(line);
        } catch (err) {
          console.error(`Error parsing JSON line: ${line}`);
          console.error(err);
          return null;
        }
      })
      .filter((item) => item !== null);

    // Process the diagnostics based on output type
    let outputContent;
    if (outputType === "human-readable") {
      outputContent = diagnosticsToHumanReadable(diagnostics);
    } else {
      // outputType is 'patch'
      const sarif = diagnosticsToSarifPatchFile(diagnostics);
      outputContent = JSON.stringify(sarif, null, 2);
    }

    // Write the output
    fs.writeFileSync(outputFile, outputContent);
    console.log(`Successfully wrote output to ${outputFile}`);
  } catch (err) {
    console.error(`Error processing files: ${err.message}`);
    process.exit(1);
  }
}

// Execute the main function
main();
