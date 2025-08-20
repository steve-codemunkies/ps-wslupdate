# PS-WslUpdate

A script to update all WSL distributions from the Windows Task Scheduler.

## Core script

The core script is [`ps-wslupdate.ps1`](./src/ps-wslupdate.ps1). This does not expect parameters, but does require environment variables to be configured:

| EnvVar Name | Description |
|-------------|-------------|
| `WSL_SKIP_DIST` | A colon (`:`) seperated list of names of distributions that _should not_ be updated. A list of names can be obtained by executing `wsl -l -v`. If the variable is not present or is empty all distributions will be updated. |
| `WSL_UPDATE_LOG` | An absolute path to a folder that log can be written to. |

## Development and debugging

This mini-project has been configured for use in [VS Code](https://code.visualstudio.com/).

VS Code [does not support setting environment varibales via `launch.json`](https://github.com/PowerShell/vscode-powershell/issues/4998) it is necessary to work around this. This is achieved using the [`wslUpdateWrapper.ps1`](./debug/wslUpdateWrapper.ps1). This script takes three parameters (the script path and two values representing the environment variables to be set). The [`launch.json`](./.vscode/launch.json) demonstrates how to use this script.

## Useful stuff

* [Basic commands for WSL](https://learn.microsoft.com/en-us/windows/wsl/basic-commands)
* [Powershell Gallery - Wsl 2.1.0](https://www.powershellgallery.com/packages/Wsl/2.1.0)
* [Powershell - Strange WSL output string encoding - StackOverflow](https://stackoverflow.com/q/64104790)
* [Feature Request: Support the "env" key in launch.json for debugging Environment Variable setup -  #4998 - PowerShell/vscode-powershell](https://github.com/PowerShell/vscode-powershell/issues/4998)