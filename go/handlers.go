package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"os/exec"
	"strings"
)

var opCliPath string = "op"

func validateOnlyOne(args []string) (*string, error) {
	arglen := len(args)
	if arglen > 1 {
		return nil, errors.New(fmt.Sprintf("Too many arguments, expected 1 got %d", arglen))
	}

	if arglen == 0 {
		return nil, errors.New("Not enough arguments, expected 1 got 0")
	}

	return &args[0], nil
}

func OpCmd(args []string) (*string, error) {
	cmd := exec.Command(opCliPath, args...)
	out, err := cmd.CombinedOutput()
	if err != nil && !strings.HasPrefix(err.Error(), "exit status") {
		return nil, err
	}

	returnCode := cmd.ProcessState.ExitCode()
	output := CliOutput{
		Outupt:     string(out),
		ReturnCode: returnCode,
	}
	value, jsonErr := json.Marshal(output)
	if jsonErr != nil {
		return nil, jsonErr
	}

	json := string(value)
	return &json, nil
}

func DesignateField(args []string) (*string, error) {
	arg, validationErr := validateOnlyOne(args)
	if validationErr != nil {
		return nil, validationErr
	}

	fieldDesignation := GetFieldDesignation(*arg)
	result, jsonErr := json.Marshal(&fieldDesignation)
	if jsonErr != nil {
		return nil, jsonErr
	}

	json := string(result)
	return &json, nil
}

func Setup(args []string) (*string, error) {
	arg, validationErr := validateOnlyOne(args)
	if validationErr != nil {
		return nil, validationErr
	}

	opCliPath = *arg
	return &opCliPath, nil
}
