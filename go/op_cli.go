package main

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os/exec"
	"strconv"
	"strings"
	"time"
)

// Output and return code from CLI along with the return code
type CliOutput struct {
	Output     string `json:"output"`
	ReturnCode int    `json:"return_code"`
}

type OpAccount struct {
	Name string `json:"name"`
}

var opCliPath string = "op"
var opCliPathValid = false
var opCmdTimeout = 30 * time.Second

func opCmdAsync(requestId string, args []string) {
	json, err := OpCmd(args)
	if err != nil {
		Async.Err(requestId, err)
	} else {
		Async.Success(requestId, *json)
	}
}

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
		versionCtx, versionCancel := context.WithTimeout(context.Background(), opCmdTimeout)
		defer versionCancel()
		if err := exec.CommandContext(versionCtx, opCliPath, "--version").Run(); err != nil {
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

	ctx, cancel := context.WithTimeout(context.Background(), opCmdTimeout)
	defer cancel()
	cmd := exec.CommandContext(ctx, opCliPath, args...)
	out, err := cmd.CombinedOutput()
	if err != nil && !strings.HasPrefix(err.Error(), "exit status") {
		return nil, err
	}

	outStr := string(out)
	returnCode := cmd.ProcessState.ExitCode()

	go UpdateStatusline(opCliPath, args, outStr, returnCode)

	output := CliOutput{
		Output:     outStr,
		ReturnCode: returnCode,
	}

	value, jsonErr := json.Marshal(output)
	if jsonErr != nil {
		return nil, jsonErr
	}

	json := string(value)
	return &json, nil
}

// Set the command timeout in milliseconds.
func OpSetTimeout(args []string) error {
	arg, validationErr := ValidateOnlyOneArg(args)
	if validationErr != nil {
		return validationErr
	}

	ms, err := strconv.Atoi(*arg)
	if err != nil {
		return fmt.Errorf("invalid timeout value: %s", *arg)
	}

	opCmdTimeout = time.Duration(ms) * time.Millisecond
	return nil
}

func OpCmdAsync(args []string) error {
	if len(args) < 2 {
		return errors.New("Need at least 2 arguments (request ID, then `op` cmd).")
	}

	go opCmdAsync(args[0], args[1:])

	return nil
}
