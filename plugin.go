// This is a plugin for Aspect CLI to add a 'lint' command
package main

import (
	"bytes"
	"context"
	"fmt"
	"log"
	"os"
	"os/exec"
	"strings"

	goplugin "github.com/hashicorp/go-plugin"
	"gopkg.in/yaml.v2"

	"aspect.build/cli/bazel/command_line"
	"aspect.build/cli/pkg/aspecterrors"
	"aspect.build/cli/pkg/bazel"
	"aspect.build/cli/pkg/ioutils"
	"aspect.build/cli/pkg/plugin/sdk/v1alpha4/config"
	aspectplugin "aspect.build/cli/pkg/plugin/sdk/v1alpha4/plugin"
)

var Log = log.Default()

var QUIET_BZL_ARGS = []string{"--output_filter", "DONT_MATCH_ANYTHING", "--noshow_progress", "--show_loading_progress"}

// main starts up the plugin as a child process of the CLI and connects the gRPC communication.
func main() {
	goplugin.Serve(config.NewConfigFor(&LintPlugin{
		yamlUnmarshalStrict: yaml.UnmarshalStrict,
	}))
}

// LintPlugin declares the fields on an instance of the plugin.
type LintPlugin struct {
	// Base gives default implementations of the plugin methods, so implementing them below is optional.
	// See the definition of aspectplugin.Base for more methods that can be implemented by the plugin.
	aspectplugin.Base
	// This plugin will store some state from the Build Events for use at the end of the build.
	command_line.CommandLine
	// Helper to parse our config section
	yamlUnmarshalStrict    func(in []byte, out interface{}) (err error)
	LintAspects []string `yaml:"aspects"`
}

func (plugin *LintPlugin) Setup(config *aspectplugin.SetupConfig) error {
	if err := plugin.yamlUnmarshalStrict(config.Properties, &plugin); err != nil {
		return fmt.Errorf("failed to setup: failed to parse properties: %w", err)
	}

	return nil
}

// CustomCommands contributes a new 'lint' command alongside the built-in ones like 'build' and 'test'.
func (plugin *LintPlugin) CustomCommands() ([]*aspectplugin.Command, error) {
	// TODO: streams within the aspectplugin.Command are no longer std out/err and become logging.
	streams := ioutils.Streams{
		Stdin:  os.Stdin,
		Stdout: os.Stdout,
		Stderr: os.Stderr,
	}

	return []*aspectplugin.Command{
		aspectplugin.NewCommand(
			"lint",
			"Run configured linters over the dependency graph.",
			"Run linters and collect the reports they produce. TODO: more usage docs",
			func(ctx context.Context, args []string, bazelStartupArgs []string) error {
				// Build with the linter aspect collecting the 'report' output group.
				// TODO: list of linter aspects should come from config
				bazelCmd := bazelStartupArgs
				bazelCmd = append(bazelStartupArgs, "build", "--aspects", plugin.LintAspects[0], "--output_groups=report")
				bazelCmd = append(bazelCmd, QUIET_BZL_ARGS...)
				bazelCmd = append(bazelCmd, args...)

				if exitCode, err := bazel.WorkspaceFromWd.RunCommand(streams, nil, bazelCmd...); exitCode != 0 {
					Log.Printf("Error running lint aspect: %v\n", err)

					err = &aspecterrors.ExitError{
						Err:      err,
						ExitCode: exitCode,
					}
					return err
				}

				// Find the lint result files.
				lintFiles, err := plugin.findLintResultFiles(streams, bazelStartupArgs)
				if err != nil {
					Log.Printf("Error collecting lint results: %v\n", err)

					err = &aspecterrors.ExitError{
						Err:      err,
						ExitCode: 1,
					}
					return err
				}

				if len(lintFiles) == 0 {
					return nil
				}

				// Output the lint results.
				for _, f := range lintFiles {
					lintResultBuf, err := os.ReadFile(f)
					if err != nil {
						Log.Printf("Error reading lint results file %q: %v\n", f, err)

						err = &aspecterrors.ExitError{
							Err:      err,
							ExitCode: 1,
						}
						return err
					}

					lineResult := strings.TrimSpace(string(lintResultBuf))
					if len(lineResult) > 0 {
						fmt.Fprintln(streams.Stdout, lineResult)
					}
				}

				return nil
			},
		),
	}, nil
}

func (plugin *LintPlugin) findLintResultFiles(streams ioutils.Streams, bazelStartupArgs []string) ([]string, error) {
	// TODO: use bazel query

	var infoOutBuf bytes.Buffer
	infoStreams := ioutils.Streams{
		Stdin:  streams.Stdin,
		Stdout: &infoOutBuf,
		Stderr: streams.Stderr,
	}

	infoCmd := bazelStartupArgs
	infoCmd = append(infoCmd, "info", "bazel-bin")
	if exitCode, err := bazel.WorkspaceFromWd.RunCommand(infoStreams, nil, infoCmd...); exitCode != 0 {
		return nil, err
	}

	binDir := strings.TrimSpace(infoOutBuf.String())

	var findOutBuf bytes.Buffer
	findCmd := exec.Command("find", binDir, "-type", "f", "-name", "*eslint-report.txt")
	findCmd.Stdout = &findOutBuf
	findCmd.Stderr = streams.Stderr
	findCmd.Stdin = streams.Stdin

	if err := findCmd.Run(); err != nil {
		return nil, err
	}

	lintFiles := strings.TrimSpace(findOutBuf.String())
	if len(lintFiles) == 0 {
		return []string{}, nil
	}

	return strings.Split(lintFiles, "\n"), nil
}
