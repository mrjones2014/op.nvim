package main

import (
	"encoding/json"
	"errors"
	"fmt"
)

type LineDiagnostic struct {
	Line       int    `json:"line"`
	ColStart   int    `json:"col_start"`
	ColEnd     int    `json:"col_end"`
	SecretType string `json:"secret_type"`
}

type LineDiagnosticRequest struct {
	LineNr int    `json:"linenr"`
	Text   string `json:"text"`
}

// these types create too many false positives
var ignoredSecretTypes = []string{
	"username",
	"url",
}

func isIgnoredPattern(pattern FieldPattern) bool {
	for _, patternType := range ignoredSecretTypes {
		if pattern.FieldTitle == patternType {
			return true
		}
	}

	return false
}

func formatSecretType(pattern FieldPattern) string {
	if &pattern.ItemTitle != nil && len(pattern.ItemTitle) > 0 {
		return fmt.Sprintf("%s %s", pattern.ItemTitle, pattern.FieldTitle)
	}

	return pattern.FieldTitle
}

func analyzeBuffer(lineRequests []LineDiagnosticRequest) []LineDiagnostic {
	results := []LineDiagnostic{}
	for _, req := range lineRequests {
		linenr := req.LineNr
		line := req.Text
		if &line == nil || len(line) == 0 {
			continue
		}

		for _, pattern := range FIELD_PATTERNS {
			if isIgnoredPattern(pattern) {
				continue
			}

			matches := pattern.Pattern.FindAllStringIndex(line, -1)
			secretType := formatSecretType(pattern)
			for _, match := range matches {
				results = append(results, LineDiagnostic{
					Line:       linenr,
					ColStart:   match[0],
					ColEnd:     match[1],
					SecretType: secretType,
				})
			}
		}
	}

	return results
}

func analyzeBufferJson(lineRequests []LineDiagnosticRequest) (*string, error) {
	results := analyzeBuffer(lineRequests)
	result, err := json.Marshal(results)

	if err != nil {
		return nil, err
	}

	asString := string(result)
	return &asString, nil
}

func OpAnalyzeBufferAsync(args []string) error {
	if len(args) != 2 {
		return errors.New("Need exactly 2 arguments (request ID, then buffer line requests)")
	}

	var lineRequests []LineDiagnosticRequest
	jsonParseErr := json.Unmarshal([]byte(args[1]), &lineRequests)
	if jsonParseErr != nil {
		return jsonParseErr
	}

	go func(requestId string, lineRequests []LineDiagnosticRequest) {
		result, err := analyzeBufferJson(lineRequests)
		AsyncCallback(requestId, result, err)
	}(args[0], lineRequests)

	return nil
}
