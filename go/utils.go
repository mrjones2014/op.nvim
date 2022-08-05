package main

import (
	"errors"
	"fmt"
)

// Validate that the args []string contains only
// one argument and return it, or an error otherwise.
func ValidateOnlyOneArg(args []string) (*string, error) {
	arglen := len(args)
	if arglen > 1 {
		return nil, errors.New(fmt.Sprintf("Too many arguments, expected 1 got %d", arglen))
	}

	if arglen == 0 {
		return nil, errors.New("Not enough arguments, expected 1 got 0")
	}

	return &args[0], nil
}
