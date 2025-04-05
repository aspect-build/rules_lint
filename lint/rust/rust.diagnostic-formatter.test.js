#!/usr/bin/env node

const fs = require("fs");

/**
 * Test script for the Rust diagnostics converter
 * Compares the output of the converter with a golden file
 */
function runTest() {
  const wantFile = process.env["WANT"];
  const gotFile = process.env["GOT"];

  console.log("Running Rust diagnostics converter test...");

  try {
    // Ensure the input and golden files exist
    if (!fs.existsSync(wantFile)) {
      throw new Error(`WANT not found: ${wantFile}`);
    }
    if (!fs.existsSync(gotFile)) {
      throw new Error(`GOT not found: ${gotFile}`);
    }

    const wantContent = fs.readFileSync(wantFile, "utf8");
    const gotContent = fs.readFileSync(gotFile, "utf8");

    const wantJson = JSON.parse(wantContent);
    const gotJson = JSON.parse(gotContent);

    // Compare the parsed JSON objects
    const equal = deepEqual(wantJson, gotJson);

    if (equal) {
      console.log("\n✅ Test PASSED: Output matches golden file!");
    } else {
      console.log("\n❌ Test FAILED: Output does not match golden file");
      console.log("\nDifferences:");
      reportDifferences(goldenJson, outputJson);
    }

    return equal;
  } catch (err) {
    console.error(`\n❌ Test error: ${err.message}`);
    return false;
  }
}

/**
 * Deep equality comparison of objects
 */
function deepEqual(want, got) {
  if (want === got) return true;

  if (
    typeof want !== "object" ||
    want === null ||
    typeof got !== "object" ||
    got === null
  ) {
    return false;
  }

  const keys1 = Object.keys(want);
  const keys2 = Object.keys(got);

  if (keys1.length !== keys2.length) return false;

  for (const key of keys1) {
    if (!keys2.includes(key)) return false;
    if (!deepEqual(want[key], got[key])) return false;
  }

  return true;
}

/**
 * Reports differences between two objects
 */
function reportDifferences(want, got, path = "") {
  if (
    typeof want !== "object" ||
    want === null ||
    typeof got !== "object" ||
    got === null
  ) {
    if (want !== got) {
      console.log(
        `${path}: \n
            WANT: ${JSON.stringify(want)}
            GOT:  ${JSON.stringify(got)}`
      );
    }
    return;
  }

  const keys1 = Object.keys(want);
  const keys2 = Object.keys(got);

  // Report keys in want but not in got
  for (const key of keys1) {
    if (!keys2.includes(key)) {
      console.log(`${path}${path ? "." : ""}${key}: missing in output`);
    }
  }

  // Report keys in got but not in want
  for (const key of keys2) {
    if (!keys1.includes(key)) {
      console.log(`${path}${path ? "." : ""}${key}: unexpected in output`);
    }
  }

  // Report differences in values for common keys
  for (const key of keys1) {
    if (keys2.includes(key)) {
      reportDifferences(want[key], got[key], `${path}${path ? "." : ""}${key}`);
    }
  }
}

// Run the test
const success = runTest();
process.exit(success ? 0 : 1);
