param(
    [Parameter(Mandatory=$true)]
    [string]$ScriptPath,
    [string]$WSLSkipDist,
    [string]$WSLUpdateLog
)

Import-Module "$PSScriptRoot\..\shared\envvars.ps1"

# Validate mandatory parameter
if (-not $ScriptPath) {
    Write-Error 'ScriptPath is required.'
    exit 1
}
if (!(Test-Path $ScriptPath)) {
    Write-Error "ScriptPath '$ScriptPath' does not exist."
    exit 1
}


# Backup and set WSL_SKIP_DIST
$oldSkipDist = Replace-EnvVar -Name 'WSL_SKIP_DIST' -NewValue $WSLSkipDist

# Backup and set WSL_UPDATE_LOG
$oldUpdateLog = Replace-EnvVar -Name 'WSL_UPDATE_LOG' -NewValue $WSLUpdateLog

try {
    & $ScriptPath
    $exitCode = $LASTEXITCODE
} catch {
    Write-Error $_
    $exitCode = 1
} finally {
    # Restore WSL_SKIP_DIST
    if ($PSBoundParameters.ContainsKey('WSLSkipDist')) {
        Restore-EnvVar -Name 'WSL_SKIP_DIST' -OldValue $oldSkipDist
    } elseif ($oldSkipDist) {
        Set-EnvVar 'WSL_SKIP_DIST' $oldSkipDist
    }

    # Restore WSL_UPDATE_LOG
    if ($PSBoundParameters.ContainsKey('WSLUpdateLog')) {
        Restore-EnvVar -Name 'WSL_UPDATE_LOG' -OldValue $oldUpdateLog
    } elseif ($oldUpdateLog) {
        Set-EnvVar 'WSL_UPDATE_LOG' $oldUpdateLog
    }
}

exit $exitCode
