/*
 * Copyright 2024 Aspect Build Systems, Inc.
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package sarif

import (
	"bytes"
	"encoding/json"
	"fmt"
	"log"
	"regexp"
	"strings"

	"github.com/reviewdog/errorformat"
	"github.com/reviewdog/errorformat/fmts"
	"github.com/reviewdog/errorformat/writer"
	"github.com/reviewdog/reviewdog/parser"
)

func mnemonicPrettyName(mnemonic string) string {
	return strings.Replace(mnemonic, "AspectRulesLint", "", 1)
}

func ToSarifJsonString(label string, mnemonic string, report string) (sarifJsonString string, err error) {
	regex := regexp.MustCompile(`^{\s+"\$schema":.+sarif`)
	// If it's already in SARIF format, normalize paths before returning it.
	if regex.Match([]byte(report)) {
		return normalizeSarifUris(label, report)
	}

	if len(mnemonic) == 0 {
		return "", fmt.Errorf("Undefined linter mnemonic for target %s\n", label)
	}

	var fm []string

	// NB: Switch is on the MNEMONIC declared in rules_lint
	// Helpful link for building custom fm strings: https://vimdoc.sourceforge.net/htmldoc/quickfix.html#errorformat
	switch mnemonic {
	case "AspectRulesLintBuildifier":
		fm = []string{
			`%f:%l:%c: %m`,
			`%f:%l: %m`,
		}
	case "AspectRulesLintESLint":
		fm = fmts.DefinedFmts()["eslint-compact"].Errorformat
	case "AspectRulesLintFlake8":
		fm = fmts.DefinedFmts()["flake8"].Errorformat
	case "AspectRulesLintPMD":
		// TODO: upstream to https://github.com/reviewdog/errorformat/issues/62
		fm = []string{`%f:%l:\\t%m`}
	case "AspectRulesLintPylint":
		fm = []string{`%f:%l:%c: %m`}
	case "AspectRulesLintPydoclint":
		fm = []string{`%f:%l: %m`}
	case "AspectRulesLintRuff":
		fm = []string{
			// %E forces a multiline error severity message. There is no forced single line error message
			`%E%f:%l:%c: %m`,
			// End the multiline error message on the next line and ignore said line
			`%-Z%r`,
		}
	case "AspectRulesLintBuf":
		fm = []string{
			`%E--buf-plugin_out: %f:%l:%c:%m`,
			`%-Z%r`,
		}
	case "AspectRulesLintVale":
		fm = []string{`%f:%l:%c:%m`}
	case "AspectRulesLintCppCheck":
		fm = []string{
			`%f:%l:%c: %trror: %m`,
			`%f:%l:%c: %tarning: %m`,
			`%f:%l:%c: %tyle: %m`,
			`%f:%l:%c: %terformance: %m`,
			`%f:%l:%c: %tortability: %m`,
			`%f:%l:%c: %tnformation: %m`,
			`%-G%.%#`,
		}
	case "AspectRulesLintClangTidy":
		fm = []string{
			`%f:%l:%c: %trror: %m`,
			`%f:%l:%c: %tarning: %m`,
			`%-G%m`, // this will ignore any lines that do not match the above 2 lines
			// TODO: Do the other fm's need this ^
		}
	case "AspectRulesLintShellCheck":
		fm = []string{
			`%AIn\ %f\ line\ %l:`,
			`%C%.%#(%trror):\ %m%Z`,
			`%C%.%#(%tarning):\ %m%Z`,
			`%C%.%#(%tnfo):\ %m%Z`,
			`%C%.%#`,
		}
	case "AspectRulesLintStylelint":
		fm = []string{
			`%f: line %l\, col %c\, %trror - %m`,
			`%f: line %l\, col %c\, %tarning - %m`,
		}
	case "AspectRulesLintYamllint":
		fm = []string{
			`%E%f:%l:%c: [error] %m`,
			`%W%f:%l:%c: [warning] %m`,
			`%I%f:%l:%c: [info] %m`,
		}
	case "AspectRulesLintQmllint":
		fm = []string{
			`%EError: %f:%l:%c: %m`,
			`%WWarning: %f:%l:%c: %m`,
			`%IInfo: %f:%l:%c: %m`,
			`%-G%.%#`,
		}
	case "AspectRulesLintKeepSorted":
		fm = []string{`%f:%l:%e:%m`}
	case "AspectRulesLintTy":
		fm = []string{
			`%Eerror%m`,
			`%C\\ %#-->\\ %f:%l:%c`,
			`%-G%.%#`,
		}
	case "AspectRulesLintRuboCop", "AspectRulesLintStandardRB":
		return rubocopJsonToSarif(label, mnemonic, report)
	default:
		return "", fmt.Errorf("No format string for linter mnemonic %s from target %s\n", mnemonic, label)
	}

	if len(fm) == 0 {
		return "", nil
	}
	efm, err := errorformat.NewErrorformat(fm)
	if err != nil {
		return "", err
	}

	var jsonBuffer bytes.Buffer
	var jsonWriter writer.Writer

	var sarifOpt writer.SarifOption
	sarifOpt.ToolName = mnemonicPrettyName(mnemonic)
	jsonWriter, err = writer.NewSarif(&jsonBuffer, sarifOpt)
	if err != nil {
		return "", err
	}

	if jsonWriter, ok := jsonWriter.(writer.BufWriter); ok {
		defer func() {
			if err := jsonWriter.Flush(); err != nil {
				log.Println(err)
			}

			sarifJsonString = jsonBuffer.String()
		}()
	}

	s := efm.NewScanner(strings.NewReader(report))
	for s.Scan() {
		entry := s.Entry()
		if entry.Filename != "" && entry.Text != "" {
			entry.Filename = determineRelativePath(entry.Filename, label)
			if err := jsonWriter.Write(entry); err != nil {
				return "", err
			}
		}
	}

	return sarifJsonString, nil
}

// rubocopJsonToSarif converts a RuboCop/StandardRB JSON report (--format json) to SARIF.
// Both linters share the same JSON schema.
func rubocopJsonToSarif(label, mnemonic, report string) (sarifJsonString string, err error) {
	var rb struct {
		Files []struct {
			Path     string `json:"path"`
			Offenses []struct {
				Severity string `json:"severity"`
				Message  string `json:"message"`
				CopName  string `json:"cop_name"`
				Location struct {
					Line   int `json:"line"`
					Column int `json:"column"`
				} `json:"location"`
			} `json:"offenses"`
		} `json:"files"`
	}
	if err = json.Unmarshal([]byte(report), &rb); err != nil {
		return "", fmt.Errorf("failed to parse RuboCop JSON: %w", err)
	}

	var buf bytes.Buffer
	var jw writer.Writer
	jw, err = writer.NewSarif(&buf, writer.SarifOption{ToolName: mnemonicPrettyName(mnemonic)})
	if err != nil {
		return "", err
	}

	if bw, ok := jw.(writer.BufWriter); ok {
		defer func() {
			if fErr := bw.Flush(); fErr != nil {
				log.Println(fErr)
			}
			sarifJsonString = buf.String()
		}()
	}

	for _, f := range rb.Files {
		for _, o := range f.Offenses {
			t := rune('W')
			switch o.Severity {
			case "error", "fatal":
				t = 'E'
			case "convention", "refactor", "info":
				t = 'I'
			}
			entry := &errorformat.Entry{
				Filename: determineRelativePath(f.Path, label),
				Lnum:     o.Location.Line,
				Col:      o.Location.Column,
				Type:     t,
				Text:     o.CopName + ": " + o.Message,
			}
			if err = jw.Write(entry); err != nil {
				return "", err
			}
		}
	}

	return sarifJsonString, nil
}

func normalizeSarifUris(label, report string) (string, error) {
	var sarif map[string]any
	if err := json.Unmarshal([]byte(report), &sarif); err != nil {
		return "", err
	}
	normalizeSarifValueUris(label, sarif)
	normalized, err := json.Marshal(sarif)
	if err != nil {
		return "", err
	}
	return string(normalized), nil
}

func normalizeSarifValueUris(label string, value any) {
	switch v := value.(type) {
	case map[string]any:
		for key, child := range v {
			if key == "uri" {
				if uri, ok := child.(string); ok {
					v[key] = determineRelativePath(uri, label)
				}
				continue
			}
			normalizeSarifValueUris(label, child)
		}
	case []any:
		for _, child := range v {
			normalizeSarifValueUris(label, child)
		}
	}
}

// We expect relative paths when processing lint output and therefore need to convert any absolute paths.
// Assumptions we make when determining the relative paths:
//   - The linter is running on the host, so the path will have an 'execroot' segment
//   - We only lint source files, so there is no 'bazel-bin/<platform>/bin' segment
func determineRelativePath(path string, label string) string {
	if !strings.HasPrefix(path, "/") || !strings.HasPrefix(label, "//") {
		return path
	}

	bazel_package := strings.Split(label[2:], ":")[0]

	// https://regex101.com/r/uMbVHP/1
	re := regexp.MustCompile(`\/execroot\/[^\/]+\/(.*)$`)
	if bazel_package != "" {
		re = regexp.MustCompile(`\/execroot\/[^\/]+\/(` + bazel_package + `\/.*)$`)
	}

	binRe := regexp.MustCompile(`\/execroot\/[^\/]+\/bazel-out\/[^\/]+\/bin\/(.*)$`)
	if bazel_package != "" {
		binRe = regexp.MustCompile(`\/execroot\/[^\/]+\/bazel-out\/[^\/]+\/bin\/(` + bazel_package + `\/.*)$`)
	}
	binRelativePath := binRe.FindSubmatch([]byte(path))
	if len(binRelativePath) == 2 {
		return string(binRelativePath[1])
	}

	relative_path := re.FindSubmatch([]byte(path))

	if len(relative_path) == 2 {
		return string(relative_path[1])
	}

	return path
}

func toSarifJson(sarifJsonString string) (sarifJson parser.SarifJson, err error) {
	if sarifJsonString == "" {
		return parser.SarifJson{}, nil
	}

	err = json.Unmarshal([]byte(sarifJsonString), &sarifJson)

	return sarifJson, err
}
