package main

import (
	"flag"
	"fmt"
	"os"

	"github.com/aspect-build/rules_lint/tools/sarif"
)

func main() {
	label := flag.String("label", "", "The Bazel label of the target being linted")
	mnemonic := flag.String("mnemonic", "", "The mnemonic identifier for the linter being used")
	outFile := flag.String("out", "", "Output file path for the SARIF JSON")
	inFile := flag.String("in", "", "Input file path containing the linter output")
	flag.Parse()

	// Validate required flags
	if *label == "" || *mnemonic == "" || *outFile == "" || *inFile == "" {
		fmt.Fprintf(os.Stderr, "Error: all flags are required: --label, --mnemonic, --in, --out\n")
		flag.Usage()
		os.Exit(1)
	}

	// Read the lint report
	report, err := os.ReadFile(*inFile)
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error reading input file: %v\n", err)
		os.Exit(1)
	}

	// Convert to SARIF format
	sarifJsonString, err := sarif.ToSarifJsonString(*label, *mnemonic, string(report))
	if err != nil {
		fmt.Fprintf(os.Stderr, "Error converting to SARIF: %v\n", err)
		os.Exit(1)
	}

	// Write the SARIF JSON to output file
	if err := os.WriteFile(*outFile, []byte(sarifJsonString), 0644); err != nil {
		fmt.Fprintf(os.Stderr, "Error writing output file: %v\n", err)
		os.Exit(1)
	}
}
