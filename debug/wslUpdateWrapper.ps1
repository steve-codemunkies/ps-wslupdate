param(
    [Parameter(Mandatory=$true)]
    [string]$ScriptPath,
    [string]$WSLSkipDist,
    [string]$WSLUpdateLog
)

function Backup-EnvVar {
    param([string]$Name)
    $old = [Environment]::GetEnvironmentVariable($Name, 'Process')
    return $old
}

function Set-EnvVar {
    param([string]$Name, [string]$Value)
    [Environment]::SetEnvironmentVariable($Name, $Value, 'Process')
}

function Remove-EnvVar {
    param([string]$Name)
    [Environment]::SetEnvironmentVariable($Name, $null, 'Process')
}

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
$oldSkipDist = Backup-EnvVar 'WSL_SKIP_DIST'
if ($PSBoundParameters.ContainsKey('WSLSkipDist')) {
    Set-EnvVar 'WSL_SKIP_DIST' $WSLSkipDist
} else {
    if ($oldSkipDist) {
        Remove-EnvVar 'WSL_SKIP_DIST'
    }
}

# Backup and set WSL_UPDATE_LOG
$oldUpdateLog = Backup-EnvVar 'WSL_UPDATE_LOG'
if ($PSBoundParameters.ContainsKey('WSLUpdateLog')) {
    Set-EnvVar 'WSL_UPDATE_LOG' $WSLUpdateLog
} else {
    if ($oldUpdateLog) {
        Remove-EnvVar 'WSL_UPDATE_LOG'
    }
}

try {
    & $ScriptPath
    $exitCode = $LASTEXITCODE
} catch {
    Write-Error $_
    $exitCode = 1
}
finally {
    # Restore WSL_SKIP_DIST
    if ($PSBoundParameters.ContainsKey('WSLSkipDist')) {
        if ($oldSkipDist) {
            Set-EnvVar 'WSL_SKIP_DIST' $oldSkipDist
        } else {
            Remove-EnvVar 'WSL_SKIP_DIST'
        }
    } elseif ($oldSkipDist) {
        Set-EnvVar 'WSL_SKIP_DIST' $oldSkipDist
    }

    # Restore WSL_UPDATE_LOG
    if ($PSBoundParameters.ContainsKey('WSLUpdateLog')) {
        if ($oldUpdateLog) {
            Set-EnvVar 'WSL_UPDATE_LOG' $oldUpdateLog
        } else {
            Remove-EnvVar 'WSL_UPDATE_LOG'
        }
    } elseif ($oldUpdateLog) {
        Set-EnvVar 'WSL_UPDATE_LOG' $oldUpdateLog
    }
}

exit $exitCode
