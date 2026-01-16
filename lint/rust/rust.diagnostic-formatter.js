/**
 * Extracts all rendered diagnostics from a list of Rust compiler diagnostics
 * and joins them into a newline-delimited string.
 *
 * @param diagnostics An array of Rust compiler output diagnostics
 * @returns A string containing all rendered diagnostics separated by newlines
 */
function diagnosticsToHumanReadable(diagnostics) {
  // Filter for compiler-message type items and extract their rendered diagnostic
  const renderedDiagnostics = diagnostics
    .filter(
      (message) => message.rendered
    )
    .map((message) => message.rendered);

  // Join all rendered diagnostics with newlines
  return renderedDiagnostics.join("\n");
}

/**
 * Converts Rust diagnostics to a SARIF patch file format that matches
 * the Rust implementation.
 *
 * @param diagnostics An array of Rust compiler output diagnostics
 * @returns A SARIF-compatible JSON object
 */
function diagnosticsToSarifPatchFile(diagnostics) {
  // Track rule IDs with a map to assign indices
  const ruleMap = new Map();
  const rules = [];
  const results = [];

  diagnostics
    .forEach((diagnostic) => {
      // Skip diagnostics without spans
      if (!diagnostic.spans || diagnostic.spans.length === 0) {
        return;
      }

      diagnostic.spans.forEach((span) => {
        // Get or create the rule entry
        const diagnosticCode = diagnostic.code ? diagnostic.code.code : "";
        if (!ruleMap.has(diagnosticCode)) {
          // Build global message for rule description
          const globalMessage = buildGlobalMessage(diagnostic);

          // Look for help URI in child diagnostics
          const helpUri = findHelpUri(diagnostic);

          const rule = {
            id: diagnosticCode,
            fullDescription: {
              text: globalMessage,
            },
          };

          if (helpUri) {
            rule.helpUri = helpUri;
          }

          const ruleIndex = rules.length;
          ruleMap.set(diagnosticCode, ruleIndex);
          rules.push(rule);
        }

        const ruleIndex = ruleMap.get(diagnosticCode);

        // Map diagnostic level to SARIF level
        const level = mapDiagnosticLevel(diagnostic.level);

        // Create result
        const result = {
          ruleId: diagnosticCode,
          ruleIndex: ruleIndex,
          level: level,
          message: {
            text: diagnostic.message,
          },
          locations: [createLocationFromSpan(span)],
          relatedLocations: getRelatedLocations(diagnostic),
        };

        results.push(result);
      });
    });

  // Construct the full SARIF document
  return {
    $schema:
      "https://schemastore.azurewebsites.net/schemas/json/sarif-2.1.0.json",
    version: "2.1.0",
    runs: [
      {
        tool: {
          driver: {
            name: "clippy",
            informationUri: "https://rust-lang.github.io/rust-clippy/",
            rules: rules,
          },
        },
        results: results,
      },
    ],
  };
}

/**
 * Maps Rust diagnostic levels to SARIF result levels
 *
 * @param level The Rust diagnostic level
 * @returns The corresponding SARIF level
 */
function mapDiagnosticLevel(level) {
  switch (level) {
    case "help":
    case "note":
      return "note";
    case "warning":
      return "warning";
    case "error":
      return "error";
    default:
      return "none";
  }
}

/**
 * Creates a SARIF location from a diagnostic span
 *
 * @param span The diagnostic span
 * @returns A SARIF location object
 */
function createLocationFromSpan(span) {
  return {
    physicalLocation: {
      artifactLocation: {
        uri: span.file_name,
      },
      region: {
        byteOffset: span.byte_start,
        byteLength: span.byte_end - span.byte_start,
        startLine: span.line_start,
        startColumn: span.column_start,
        endLine: span.line_end,
        endColumn: span.column_end,
      },
    },
    message: span.label ? { text: span.label } : undefined,
  };
}

/**
 * Recursively builds a global message from diagnostic and children
 *
 * @param diagnostic The diagnostic object
 * @returns A string containing the global message
 */
function buildGlobalMessage(diagnostic) {
  let message = "";

  // If no spans, add the message (it's a global message)
  if (!diagnostic.spans || diagnostic.spans.length === 0) {
    message += diagnostic.message + "\n";
  }

  // Process children recursively
  if (diagnostic.children && diagnostic.children.length > 0) {
    for (const child of diagnostic.children) {
      message += buildGlobalMessage(child);
    }
  }

  return message;
}

/**
 * Extracts help URI from a diagnostic's children
 *
 * @param diagnostic The diagnostic object
 * @returns The help URI if found, otherwise undefined
 */
function findHelpUri(diagnostic) {
  if (!diagnostic.children) {
    return undefined;
  }

  for (const child of diagnostic.children) {
    if (child.level === "help") {
      // Match URI pattern using regex similar to Rust implementation
      const match = /^for further information visit (\S+)/.exec(child.message);
      if (match && match[1]) {
        return match[1];
      }
    }
  }

  return undefined;
}

/**
 * Collects related locations from a diagnostic's children
 *
 * @param diagnostic The diagnostic object
 * @returns An array of related locations
 */
function getRelatedLocations(diagnostic) {
  if (!diagnostic.children) {
    return [];
  }

  const relatedLocations = [];

  for (const child of diagnostic.children) {
    if (!child.spans || child.spans.length === 0) {
      continue;
    }

    for (const childSpan of child.spans) {
      let message = child.message;

      // Append suggested replacement to message if available
      if (childSpan.suggested_replacement) {
        message += ` "${childSpan.suggested_replacement}"`;
      }

      const location = createLocationFromSpan(childSpan);
      location.message = { text: message };

      relatedLocations.push(location);
    }
  }

  return relatedLocations;
}

module.exports = {
  diagnosticsToHumanReadable,
  diagnosticsToSarifPatchFile,
};
