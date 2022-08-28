package main

import (
	"encoding/json"
	"fmt"
	"os/exec"
)

var opAccountNameUpdatedAtLeastOnce = false
var statuslineEnabled = false

func getAccountName() *string {
	if !opCliPathValid {
		return nil
	}

	cmd := exec.Command(opCliPath, "account", "get", "--format", "json")
	out, err := cmd.Output()
	if err != nil {
		return nil
	}

	var account OpAccount
	parseErr := json.Unmarshal(out, &account)
	if parseErr != nil {
		return nil
	}

	return &account.Name
}

func OpEnableStatusline() {
	statuslineEnabled = true
}

func UpdateStatusline(opCliPath string, lastCmd []string, lastCmdOutput string, lastCmdReturnCode int) {
	if !statuslineEnabled ||
		lastCmdReturnCode != 0 ||
		len(lastCmd) == 0 ||
		// if command is `op account list` we haven't necessarily signed into a specific account yet
		(len(lastCmd) > 2 && lastCmd[0] == "account" && lastCmd[1] == "list") ||
		// if command is `op whoami` we haven't necessarily signed in,
		// and if we are signed in, we haven't switched accounts
		lastCmd[0] == "whoami" ||
		lastCmd[0] == "update" {
		return
	}

	// if it's not a command that switches accounts, and we've already got
	// the account name, no need to update it
	if lastCmd[0] != "signin" && lastCmd[0] != "signout" && opAccountNameUpdatedAtLeastOnce {
		return
	}

	if lastCmd[0] == "signout" {
		PluginInstance.Nvim.ExecLua("require('op.statusline').update(nil)", nil)
		return
	}

	if accountName := getAccountName(); accountName != nil {
		PluginInstance.Nvim.ExecLua(fmt.Sprintf("require('op.statusline').update(\"%s\")", *accountName), nil)
		opAccountNameUpdatedAtLeastOnce = true
		return
	}
}
