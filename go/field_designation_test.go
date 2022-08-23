package main

import "testing"

func TestFieldDesignation(t *testing.T) {
	var githubToken = "ghr_a8Jy3SuY7Aws9iShaiXa8Jy3SuY7Aws9iShaiXa8Jy3SuY7Aws9iShaiXa8Jy3SuY7Aws9iShaiX"
	var designation = getFieldDesignation(githubToken)
	if designation == nil || designation.ItemTitle != "GitHub" {
		t.Logf("Designation should be detected as a GitHub token, got: %s", designation)
		t.Fail()
	}
}
