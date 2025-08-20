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