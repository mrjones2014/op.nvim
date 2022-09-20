package main

import (
	"reflect"
	"strings"
	"testing"
)

func (a AsyncManager) MockExecutor(exe Executor) {
	a.execLua = exe
}

func TestFormatSecretType_WithItemTitle(t *testing.T) {
	pattern := FieldPattern{
		ItemTitle:  "Item Title",
		FieldTitle: "Field Title",
	}
	formatted := formatSecretType(pattern)
	expected := "Item Title Field Title"
	if formatted != expected {
		t.Errorf("Expected '%s', got '%s'", expected, formatted)
	}
}

func TestFormatSecretType_WithoutItemTitle(t *testing.T) {
	pattern := FieldPattern{
		FieldTitle: "Field Title",
	}
	formatted := formatSecretType(pattern)
	expected := "Field Title"
	if formatted != expected {
		t.Errorf("Expected '%s', '%s'", expected, formatted)
	}
}

func lineDiagnosticRequestsFromStr(text string) []LineDiagnosticRequest {
	lines := strings.Split(text, "\n")
	requests := make([]LineDiagnosticRequest, len(lines))
	for linenr, line := range lines {
		requests = append(requests, LineDiagnosticRequest{
			LineNr: linenr,
			Text:   line,
		})
	}
	return requests
}

func TestAnalyzeBuffer(t *testing.T) {
	requests := lineDiagnosticRequestsFromStr(`
Some text

Some more text

A fake GitHub token is ghr_aU73Wj7Jow3qAuQfuOaU73Wj7Jow3qAuQfuOaU73Wj7Jow3qAuQfuOaU73Wj7Jow3qAuQfuOa7wQ

A fake credit card number is 4222222222222

Emails are ignored because they create too many false positives: test@example.com

Regular URLs are also ignored because they aren't necessarily sensitive: https://github.com

A fake Slack webhook URL is https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXXXXXX

Two secrets on the same line: 4222222222222 ghr_aU73Wj7Jow3qAuQfuOaU73Wj7Jow3qAuQfuOaU73Wj7Jow3qAuQfuOaU73Wj7Jow3qAuQfuOa7wQ
	`)

	results := analyzeBuffer(requests)
	expected := []LineDiagnostic{
		{
			Line:       5,
			ColStart:   23,
			ColEnd:     103,
			SecretType: "GitHub token",
		},
		{
			Line:       7,
			ColStart:   29,
			ColEnd:     42,
			SecretType: "credit card",
		},
		{
			Line:       13,
			ColStart:   28,
			ColEnd:     105,
			SecretType: "Slack webhook",
		},
		{
			Line:       15,
			ColStart:   30,
			ColEnd:     43,
			SecretType: "credit card",
		},
		{
			Line:       15,
			ColStart:   44,
			ColEnd:     124,
			SecretType: "GitHub token",
		},
	}

	if !reflect.DeepEqual(expected, results) {
		t.Errorf("Expected:\n  %+v \nGot:\n  %+v", expected, results)
	}
}
