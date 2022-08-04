package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"github.com/neovim/go-client/nvim/plugin"
	"os/exec"
	"strings"
)

type CliOutput struct {
	Outupt     string `json:"output"`
	ReturnCode int    `json:"return_code"`
}

var opCliPath string = "op"

func opcmd(args []string) (string, error) {
	cmd := exec.Command("op", args...)
	out, err := cmd.CombinedOutput()
	if err != nil && !strings.HasPrefix(err.Error(), "exit status") {
		return "", err
	}

	returnCode := cmd.ProcessState.ExitCode()
	output := CliOutput{
		Outupt:     string(out),
		ReturnCode: returnCode,
	}
	value, jsonErr := json.Marshal(output)
	if jsonErr != nil {
		return "", jsonErr
	}

	return string(value), nil
}

func setup(args []string) (string, error) {
	arglen := len(args)
	if arglen > 1 {
		return "", errors.New(fmt.Sprintf("Too many arguments, expected 1 got %d", arglen))
	}

	if arglen == 0 {
		return "", errors.New("Not enough arguments, expected 1 got 0")
	}

	opCliPath = args[0]
	return opCliPath, nil
}

func main() {
	plugin.Main(func(p *plugin.Plugin) error {
		p.HandleFunction(&plugin.FunctionOptions{Name: "Opcmd"}, opcmd)
		p.HandleFunction(&plugin.FunctionOptions{Name: "OpSetup"}, setup)
		return nil
	})
}
