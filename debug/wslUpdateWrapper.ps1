param(
    [Parameter(Mandatory=$true)]
    [string]$ScriptPath,
    [string]$WSLSkipDist,
    [string]$WSLUpdateLog
)


function Backup-EnvVar {
    param([string]$Name)
    return [Environment]::GetEnvironmentVariable($Name, 'Process')
}

function Set-EnvVar {
    param([string]$Name, [string]$Value)
    [Environment]::SetEnvironmentVariable($Name, $Value, 'Process')
}

function Remove-EnvVar {
    param([string]$Name)
    [Environment]::SetEnvironmentVariable($Name, $null, 'Process')
}

function Replace-EnvVar {
    param(
        [string]$Name,
        [string]$NewValue
    )
    $old = Backup-EnvVar $Name
    if ($PSBoundParameters.ContainsKey('NewValue')) {
        Set-EnvVar $Name $NewValue
    } else {
        if ($old) {
            Remove-EnvVar $Name
        }
    }
    return $old
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
$oldSkipDist = Replace-EnvVar -Name 'WSL_SKIP_DIST' -NewValue $WSLSkipDist

# Backup and set WSL_UPDATE_LOG
$oldUpdateLog = Replace-EnvVar -Name 'WSL_UPDATE_LOG' -NewValue $WSLUpdateLog

try {
    & $ScriptPath
    $exitCode = $LASTEXITCODE
} catch {
    Write-Error $_
    $exitCode = 1
}

function Restore-EnvVar {
    param(
        [string]$Name,
        [string]$OldValue
    )
    if ($OldValue) {
        Set-EnvVar $Name $OldValue
    } else {
        Remove-EnvVar $Name
    }
}

finally {
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
