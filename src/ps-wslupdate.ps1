# PS-WslUpdate.ps1
# Script to update all WSL distributions except those in the exclusion list.
# Logs actions and output, manages log retention, and handles encoding issues.

Import-Module "$PSScriptRoot\..\shared\envvars.ps1"

function Get-DateString {
    return (Get-Date -Format 'yyyyMMddHHmmss')
}

function Output-DateString {
    return (Get-Date -Format 'yyyy-MM-dd HH:mm:ss')
}

function Output-LogAndHost {
    param (
        [string]$Message,
        [string]$ProcessLog
    )
    $Message | Out-File -FilePath $ProcessLog -Encoding UTF8 -Append
    Write-Host $Message
}

# Get exclusion list from environment variable
$skipDistRaw = [Environment]::GetEnvironmentVariable('WSL_SKIP_DIST')
$skipDist = if ([string]::IsNullOrWhiteSpace($skipDistRaw)) { @() } else { $skipDistRaw -split ':' }

# Get log folder from environment variable
$logFolder = [Environment]::GetEnvironmentVariable('WSL_UPDATE_LOG')
if ([string]::IsNullOrWhiteSpace($logFolder)) {
    Write-Error 'WSL_UPDATE_LOG environment variable is not set.'
    exit 1
}
if (!(Test-Path $logFolder)) {
    Write-Error "Log folder '$logFolder' does not exist."
    exit 1
}

# Backup and set WSL_UTF8
$oldWslUtf8 = Replace-EnvVar -Name 'WSL_UTF8' -NewValue 1

# Set output encoding workaround (see StackOverflow link)
$oldOutputEncoding = [Console]::OutputEncoding
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

try {
    # Get list of installed distributions
    $wslList = wsl.exe -l -v | Out-String
    $lines = $wslList -split "`r?`n" | Where-Object { $_.Trim() -ne '' }
    $distros = $lines[1..($lines.Count-1)] | ForEach-Object {
        $line = $_.TrimStart()
        if ($line.StartsWith('*')) {
            $line = $line.Substring(1).TrimStart()
        }
        $parts = $line -split '\s{2,}'
        $parts[0].Trim()
    }

    $dateStr = Get-DateString
    $processLog = Join-Path $logFolder "Wsl update $dateStr.log"

    foreach ($distro in $distros) {
        if ($skipDist -contains $distro) {
            # Log skipped distribution
            Output-LogAndHost -Message "$(Output-DateString) Skipped: $distro" -ProcessLog $processLog
            
            # Manage log retention for skipped logs
            $skipLogs = Get-ChildItem -Path $logFolder -Filter 'Wsl update *.log' | Sort-Object Name
            if ($skipLogs.Count -gt 10) {
                $toDelete = $skipLogs | Select-Object -First ($skipLogs.Count - 10)
                $toDelete | Remove-Item -Force
            }
            continue
        }

        # Log updated distribution
        Output-LogAndHost -Message "$(Output-DateString) Updating: $distro" -ProcessLog $processLog

        # Run update command in WSL as root
        $logFile = Join-Path $logFolder "$distro $dateStr.log"
        $updateCmd = "wsl.exe -d '$distro' -u root -- bash -c 'apt update && echo && apt upgrade -y'"
        $executionData = Measure-Command {
            $output = Invoke-Expression $updateCmd 2>&1
            $output | Out-File -FilePath $logFile -Encoding UTF8
        }

        # Output data on the execution time
        Output-LogAndHost -Message "$(Output-DateString) Updated: $distro (Execution Time: $($executionData.TotalSeconds) seconds)" -ProcessLog $processLog

        # Manage log retention for distro logs
        $distroLogs = Get-ChildItem -Path $logFolder -Filter "$distro *.log" | Sort-Object Name
        if ($distroLogs.Count -gt 10) {
            $toDelete = $distroLogs | Select-Object -First ($distroLogs.Count - 10)
            $toDelete | Remove-Item -Force
        }
    }
}
finally {
    # Restore output encoding
    [Console]::OutputEncoding = $oldOutputEncoding
    # Restore the old value of WSL_UTF8
    Restore-EnvVar -Name 'WSL_UTF8' -OldValue $oldWslUtf8
}