package main

import (
	"encoding/json"
	"fmt"
	"os/exec"
	"strings"
)

var opCliPath string = "op"
var opCliPathValid = false

// Set the path to the 1Password CLI.
// Returns the configured path.
func OpSetup(args []string) (*string, error) {
	arg, validationErr := ValidateOnlyOneArg(args)
	if validationErr != nil {
		return nil, validationErr
	}

	if *arg != opCliPath {
		opCliPath = *arg
		opCliPathValid = false // revalidate on next call
	}
	return &opCliPath, nil
}

// Execute a subcommand of the 1Password CLI.
// Returns the output and exit code serialized to a JSON string.
func OpCmd(args []string) (*string, error) {
	if !opCliPathValid {
		if err := exec.Command(opCliPath, "--version").Run(); err != nil {
			output := CliOutput{
				Output:     fmt.Sprintf("[ERROR] Configured 1Password CLI path (\"%s\") is not executable!", opCliPath),
				ReturnCode: 1,
			}
			jsonBytes, err := json.Marshal(output)
			if err != nil {
				return nil, err
			}

			json := string(jsonBytes)
			return &json, nil
		} else {
			opCliPathValid = true
		}
	}

	cmd := exec.Command(opCliPath, args...)
	out, err := cmd.CombinedOutput()
	if err != nil && !strings.HasPrefix(err.Error(), "exit status") {
		return nil, err
	}

	returnCode := cmd.ProcessState.ExitCode()
	output := CliOutput{
		Output:     string(out),
		ReturnCode: returnCode,
	}
	value, jsonErr := json.Marshal(output)
	if jsonErr != nil {
		return nil, jsonErr
	}

	json := string(value)
	return &json, nil
}
