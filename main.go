package main

import (
        "encoding/json"
        "os/exec"
        "strings"
	"github.com/neovim/go-client/nvim/plugin"
)

type CliOutput struct {
    Outupt string `json:"output"`
    ReturnCode int `json:"return_code"`
}


func opcmd(args []string) (string, error) {
    cmd := exec.Command(args[0], args[1:]...)
    out, err := cmd.CombinedOutput()
    if err != nil && !strings.HasPrefix(err.Error(), "exit status") {
        return "", err
    }

    returnCode := cmd.ProcessState.ExitCode()
    output := CliOutput{
        Outupt: string(out),
        ReturnCode: returnCode,
    }
    value, jsonErr := json.Marshal(output)
    if jsonErr != nil {
        return "", jsonErr
    }

    return string(value), nil
}

func main() {
    plugin.Main(func(p *plugin.Plugin) (error) {
        p.HandleFunction(&plugin.FunctionOptions{Name: "Opcmd"}, opcmd)
        return nil
    })
}
