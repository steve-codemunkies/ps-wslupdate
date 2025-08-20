# PS-WslUpdate.ps1
# Script to update all WSL distributions except those in the exclusion list.
# Logs actions and output, manages log retention, and handles encoding issues.

function Get-DateString {
    return (Get-Date -Format 'yyyyMMddHHmmss')
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

# Set output encoding workaround (see StackOverflow link)
$env:WSL_UTF8=1
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

    foreach ($distro in $distros) {
        $dateStr = Get-DateString
        if ($skipDist -contains $distro) {
            # Log skipped distribution
            $skipLog = Join-Path $logFolder "Wsl update $dateStr.log"
            "Skipped: $distro" | Out-File -FilePath $skipLog -Encoding UTF8 -Append
            # Manage log retention for skipped logs
            $skipLogs = Get-ChildItem -Path $logFolder -Filter 'Wsl update *.log' | Sort-Object Name
            if ($skipLogs.Count -gt 10) {
                $toDelete = $skipLogs | Select-Object -First ($skipLogs.Count - 10)
                $toDelete | Remove-Item -Force
            }
            continue
        }
        # Run update command in WSL as root
        $logFile = Join-Path $logFolder "$distro $dateStr.log"
        $updateCmd = "wsl.exe -d '$distro' -u root -- bash -c 'apt update && echo && apt upgrade -y'"
        $output = Invoke-Expression $updateCmd 2>&1
        $output | Out-File -FilePath $logFile -Encoding UTF8
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
}