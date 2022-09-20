package main

import (
	"encoding/json"
	"errors"
	"fmt"
)

type LineDiagnostic struct {
	BufNr      int    `json:"bufnr"`
	Line       int    `json:"line"`
	ColStart   int    `json:"col_start"`
	ColEnd     int    `json:"col_end"`
	SecretType string `json:"secret_type"`
}

type LineDiagnosticRequest struct {
	BufNr  int    `json:"bufnr"`
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

func lineMatches(pattern FieldPattern, line string) [][]int {
	if isIgnoredPattern(pattern) {
		return nil
	}

	return pattern.Pattern.FindAllStringIndex(line, -1)
}

func validLineRequests(lineRequests []LineDiagnosticRequest) []LineDiagnosticRequest {
	validRequests := make([]LineDiagnosticRequest, len(lineRequests))
	for _, req := range lineRequests {
		if &req.Text != nil && len(req.Text) > 0 {
			validRequests = append(validRequests, req)
		}
	}

	return validRequests
}

func generateDiagnostics(req LineDiagnosticRequest) []LineDiagnostic {
	diagnostics := []LineDiagnostic{}
	linenr := req.LineNr
	line := req.Text
	if &line == nil || len(line) == 0 {
		return diagnostics
	}

	for _, pattern := range FIELD_PATTERNS {
		secretType := formatSecretType(pattern)
		for _, match := range lineMatches(pattern, line) {
			diagnostics = append(diagnostics, LineDiagnostic{
				BufNr:      req.BufNr,
				Line:       linenr,
				ColStart:   match[0],
				ColEnd:     match[1],
				SecretType: secretType,
			})
		}
	}

	return diagnostics
}

func analyzeBuffer(lineRequests []LineDiagnosticRequest) []LineDiagnostic {
	results := []LineDiagnostic{}
	for _, req := range lineRequests {
		results = append(results, generateDiagnostics(req)...)
	}

	return results
}

func analyzeBufferJson(requestId string, lineRequests []LineDiagnosticRequest) {
	results := analyzeBuffer(lineRequests)
	result, err := json.Marshal(results)

	if err != nil {
		Async.Err(requestId, err)
	} else {
		json := string(result)
		Async.Success(requestId, json)
	}
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

	analyzeBufferJson(args[0], lineRequests)

	return nil
}
