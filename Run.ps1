<# 
PowerShell launcher for FileTreeReporter (Ftree).
Runs the main script without requiring a permanent execution-policy change.
#>

[CmdletBinding()]
param(
    [string]$Path
)

$scriptPath = Join-Path $PSScriptRoot "src\FileTreeReporter.ps1"

if (-not (Test-Path -LiteralPath $scriptPath -PathType Leaf)) {
    Write-Host "ERROR: Main script was not found: $scriptPath" -ForegroundColor Red
    exit 1
}

$arguments = @(
    "-NoProfile",
    "-ExecutionPolicy",
    "Bypass",
    "-File",
    $scriptPath
)

if (-not [string]::IsNullOrWhiteSpace($Path)) {
    $arguments += @("-Path", $Path)
}

$pwshCommand = Get-Command pwsh.exe -ErrorAction SilentlyContinue
$powerShellExe = if ($pwshCommand) { $pwshCommand.Source } else { "powershell.exe" }

& $powerShellExe @arguments
exit $LASTEXITCODE
