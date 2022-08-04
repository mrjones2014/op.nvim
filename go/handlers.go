package main

import (
	"encoding/json"
	"errors"
	"fmt"
	"os/exec"
	"strings"
)

var opCliPath string = "op"

func validateOnlyOne(args []string) (string, error) {
	arglen := len(args)
	if arglen > 1 {
		return "", errors.New(fmt.Sprintf("Too many arguments, expected 1 got %d", arglen))
	}

	if arglen == 0 {
		return "", errors.New("Not enough arguments, expected 1 got 0")
	}

	return args[0], nil
}

func OpCmd(args []string) (string, error) {
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

func DesignateField(args []string) (string, error) {
	arg, validationErr := validateOnlyOne(args)
	if validationErr != nil {
		return "", validationErr
	}
	fieldDesignation, err := GetFieldDesignation(arg)
	if err != nil {
		return "null", nil
	}

	result, jsonErr := json.Marshal(fieldDesignation)
	if jsonErr != nil {
		return "", jsonErr
	}

	return string(result), nil
}

func Setup(args []string) (string, error) {
	arg, validationErr := validateOnlyOne(args)
	if validationErr != nil {
		return "", validationErr
	}

	opCliPath = arg
	return opCliPath, nil
}
