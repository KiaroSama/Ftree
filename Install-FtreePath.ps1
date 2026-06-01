<#
Adds this Ftree folder to the Windows PATH.

Default scope is the current user. Use -Scope Machine from an elevated
PowerShell session if you need the PATH entry for all users.
#>

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [ValidateSet("User", "Machine")]
    [string]$Scope = "User",

    [switch]$Remove
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]::new($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function ConvertTo-NormalizedPathEntry {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return ""
    }

    try {
        $expanded = [Environment]::ExpandEnvironmentVariables($Value.Trim('"').Trim())
        return ([System.IO.Path]::GetFullPath($expanded).TrimEnd("\")).ToUpperInvariant()
    } catch {
        return $Value.Trim('"').Trim().TrimEnd("\").ToUpperInvariant()
    }
}

function Split-PathVariable {
    param([string]$Value)

    if ([string]::IsNullOrWhiteSpace($Value)) {
        return @()
    }

    return @($Value -split ";" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
}

function Get-PathRegistryLocation {
    param([string]$Scope)

    if ($Scope -eq "Machine") {
        return [pscustomobject]@{
            Hive = [Microsoft.Win32.Registry]::LocalMachine
            SubKey = "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"
        }
    }

    return [pscustomobject]@{
        Hive = [Microsoft.Win32.Registry]::CurrentUser
        SubKey = "Environment"
    }
}

function Get-PathRegistryValue {
    param([string]$Scope)

    $location = Get-PathRegistryLocation -Scope $Scope
    $key = $location.Hive.OpenSubKey($location.SubKey, $false)
    if ($null -eq $key) {
        return [pscustomobject]@{
            Value = ""
            Kind = [Microsoft.Win32.RegistryValueKind]::String
        }
    }

    try {
        $value = $key.GetValue("Path", "", [Microsoft.Win32.RegistryValueOptions]::DoNotExpandEnvironmentNames)
        $kind = [Microsoft.Win32.RegistryValueKind]::String
        try {
            $kind = $key.GetValueKind("Path")
        } catch {
            $kind = if ($value -match "%[^%]+%") { [Microsoft.Win32.RegistryValueKind]::ExpandString } else { [Microsoft.Win32.RegistryValueKind]::String }
        }

        return [pscustomobject]@{
            Value = [string]$value
            Kind = $kind
        }
    } finally {
        $key.Close()
    }
}

function Set-PathRegistryValue {
    param(
        [string]$Scope,
        [string]$Value,
        [Microsoft.Win32.RegistryValueKind]$Kind
    )

    $location = Get-PathRegistryLocation -Scope $Scope
    $key = $location.Hive.OpenSubKey($location.SubKey, $true)
    if ($null -eq $key) {
        $key = $location.Hive.CreateSubKey($location.SubKey)
    }

    try {
        $key.SetValue("Path", $Value, $Kind)
    } finally {
        $key.Close()
    }
}

if ($Scope -eq "Machine" -and -not (Test-IsAdministrator)) {
    throw "Machine PATH requires an elevated PowerShell session. Run as Administrator or use -Scope User."
}

$installPath = (Resolve-Path -LiteralPath $PSScriptRoot).Path
$pathRegistryValue = Get-PathRegistryValue -Scope $Scope
$currentPath = $pathRegistryValue.Value
$entries = @(Split-PathVariable -Value $currentPath)
$installKey = ConvertTo-NormalizedPathEntry -Value $installPath
$matchingEntries = @($entries | Where-Object { (ConvertTo-NormalizedPathEntry -Value $_) -eq $installKey })
$exists = ($matchingEntries.Count -gt 0)

if ($Remove) {
    if (-not $exists) {
        Write-Host "Ftree is not present in the $Scope PATH:" -ForegroundColor Yellow
        Write-Host $installPath
        exit 0
    }

    $updatedEntries = @($entries | Where-Object { (ConvertTo-NormalizedPathEntry -Value $_) -ne $installKey })
    $updatedPath = $updatedEntries -join ";"

    $changed = $false
    if ($PSCmdlet.ShouldProcess("$Scope PATH", "Remove $installPath")) {
        Set-PathRegistryValue -Scope $Scope -Value $updatedPath -Kind $pathRegistryValue.Kind
        $env:Path = (@(Split-PathVariable -Value $env:Path) |
            Where-Object { (ConvertTo-NormalizedPathEntry -Value $_) -ne $installKey }) -join ";"
        $changed = $true
    }

    if ($changed) {
        Write-Host "Removed Ftree from the $Scope PATH:" -ForegroundColor Green
        Write-Host $installPath
    } else {
        Write-Host "No PATH changes were made." -ForegroundColor Yellow
    }
    exit 0
}

if ($exists) {
    Write-Host "Ftree is already present in the $Scope PATH:" -ForegroundColor Green
    Write-Host $installPath
    exit 0
}

$updatedPath = (@($entries) + $installPath) -join ";"

$changed = $false
if ($PSCmdlet.ShouldProcess("$Scope PATH", "Add $installPath")) {
    Set-PathRegistryValue -Scope $Scope -Value $updatedPath -Kind $pathRegistryValue.Kind

    $processEntries = @(Split-PathVariable -Value $env:Path)
    $processExists = @( $processEntries | Where-Object { (ConvertTo-NormalizedPathEntry -Value $_) -eq $installKey } ).Count -gt 0
    if (-not $processExists) {
        $env:Path = (@($processEntries) + $installPath) -join ";"
    }
    $changed = $true
}

if ($changed) {
    Write-Host "Added Ftree to the $Scope PATH:" -ForegroundColor Green
    Write-Host $installPath
    Write-Host "Open a new terminal before running Ftree from PATH." -ForegroundColor Yellow
} else {
    Write-Host "No PATH changes were made." -ForegroundColor Yellow
}
