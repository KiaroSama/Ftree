<# 
FileTreeReporter (Ftree)
Creates a colored terminal tree view and saves a plain-text report under ./Reports.

Compatibility:
- Windows PowerShell 5.1+
- PowerShell 7+
- No external dependencies
#>

[CmdletBinding()]
param(
    [string]$Path
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$utf8NoBom = [System.Text.UTF8Encoding]::new($false)
try {
    [Console]::InputEncoding = $utf8NoBom
} catch {
    # Keep default input encoding if the host does not allow changing it.
}
try {
    [Console]::OutputEncoding = $utf8NoBom
} catch {
    # Keep default output encoding if the host does not allow changing it.
}
try {
    $OutputEncoding = $utf8NoBom
} catch {
    # Keep default pipeline encoding if the host does not allow changing it.
}

$Script:ProjectName = "FileTreeReporter (Ftree)"
$Script:LogPath = $null
$Script:UseAnsi = $true
$Script:TreeLast = "$([char]0x2514)$([char]0x2500)$([char]0x2500) "
$Script:TreeMiddle = "$([char]0x251C)$([char]0x2500)$([char]0x2500) "
$Script:TreePipe = [char]0x2502
$Script:AnsiRose = "$([char]27)[38;2;255;50;115m"
$Script:AnsiGold = "$([char]27)[38;2;255;240;74m"
$Script:AnsiExitHint = "$([char]27)[38;5;32m"
$Script:AnsiBranch = "$([char]27)[38;2;126;178;214m"
$Script:AnsiPath = "$([char]27)[38;2;255;240;74m"
$Script:AnsiHeader = "$([char]27)[38;2;95;232;220m"
$Script:AnsiGenerated = "$([char]27)[38;2;74;226;150m"
$Script:AnsiRootLabel = "$([char]27)[38;2;198;140;255m"
$Script:AnsiRoot = "$([char]27)[38;2;198;140;255m"
$Script:AnsiFileName = "$([char]27)[38;2;70;210;255m"
$Script:AnsiFileExtension = "$([char]27)[38;2;0;168;132m"
$Script:AnsiLinkName = "$([char]27)[38;2;255;174;120m"
$Script:AnsiSummary = "$([char]27)[38;2;74;226;150m"
$Script:AnsiReset = "$([char]27)[0m"

$Script:TotalFiles = 0
$Script:TotalFolders = 0
$Script:TotalErrors = 0
$Script:TotalLinks = 0

# Bright folder colors for folder depths 1 through 50.
$Script:FolderPalette = @(
    "$([char]27)[38;2;255;96;96m",
    "$([char]27)[38;2;255;142;96m",
    "$([char]27)[38;2;255;184;96m",
    "$([char]27)[38;2;255;224;96m",
    "$([char]27)[38;2;216;244;102m",
    "$([char]27)[38;2;176;236;92m",
    "$([char]27)[38;2;126;226;112m",
    "$([char]27)[38;2;74;226;150m",
    "$([char]27)[38;2;83;220;188m",
    "$([char]27)[38;2;95;232;220m",
    "$([char]27)[38;2;83;210;242m",
    "$([char]27)[38;2;70;190;255m",
    "$([char]27)[38;2;111;176;255m",
    "$([char]27)[38;2;148;162;255m",
    "$([char]27)[38;2;180;148;255m",
    "$([char]27)[38;2;198;140;255m",
    "$([char]27)[38;2;224;132;255m",
    "$([char]27)[38;2;255;130;242m",
    "$([char]27)[38;2;255;148;214m",
    "$([char]27)[38;2;255;118;170m",
    "$([char]27)[38;2;255;50;115m",
    "$([char]27)[38;2;255;118;118m",
    "$([char]27)[38;2;255;154;132m",
    "$([char]27)[38;2;255;188;128m",
    "$([char]27)[38;2;255;211;77m",
    "$([char]27)[38;2;235;236;92m",
    "$([char]27)[38;2;198;238;110m",
    "$([char]27)[38;2;158;236;126m",
    "$([char]27)[38;2;130;210;172m",
    "$([char]27)[38;2;119;224;201m",
    "$([char]27)[38;2;144;238;238m",
    "$([char]27)[38;2;184;232;255m",
    "$([char]27)[38;2;154;211;255m",
    "$([char]27)[38;2;130;190;255m",
    "$([char]27)[38;2;158;181;255m",
    "$([char]27)[38;2;188;170;255m",
    "$([char]27)[38;2;214;158;255m",
    "$([char]27)[38;2;236;152;255m",
    "$([char]27)[38;2;255;156;236m",
    "$([char]27)[38;2;255;171;210m",
    "$([char]27)[38;2;255;154;180m",
    "$([char]27)[38;2;255;170;150m",
    "$([char]27)[38;2;246;197;139m",
    "$([char]27)[38;2;222;222;132m",
    "$([char]27)[38;2;190;226;145m",
    "$([char]27)[38;2;160;220;170m",
    "$([char]27)[38;2;145;220;205m",
    "$([char]27)[38;2;158;225;232m",
    "$([char]27)[38;2;180;220;250m",
    "$([char]27)[38;2;210;205;255m"
)

function Get-DepthColor {
    param([int]$Depth, [string]$Kind)

    if ($Kind -eq "Header") { return $Script:AnsiHeader }
    if ($Kind -eq "HeaderGenerated") { return $Script:AnsiGenerated }
    if ($Kind -eq "HeaderRoot") { return $Script:AnsiRootLabel }
    if ($Kind -eq "Root") { return $Script:AnsiRoot }
    if ($Kind -eq "Summary") { return $Script:AnsiSummary }
    if ($Kind -eq "SummaryFolders") { return "$([char]27)[38;2;176;236;92m" }
    if ($Kind -eq "SummaryFiles") { return "$([char]27)[38;2;70;190;255m" }
    if ($Kind -eq "SummaryLinks") { return "$([char]27)[38;2;255;211;77m" }
    if ($Kind -eq "SummaryErrors") { return "$([char]27)[38;2;255;90;90m" }
    if ($Kind -eq "Error") { return "$([char]27)[38;2;255;90;90m" }
    if ($Kind -eq "Link") { return $Script:AnsiLinkName }
    if ($Kind -eq "File") { return $Script:AnsiFileName }

    $paletteIndex = [Math]::Min([Math]::Max(0, $Depth - 1), $Script:FolderPalette.Count - 1)
    return $Script:FolderPalette[$paletteIndex]
}

function Enable-VirtualTerminalOutput {
    try {
        if ([Console]::IsOutputRedirected) {
            return $false
        }

        if (-not ("NativeConsole" -as [type])) {
            Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

public static class NativeConsole {
    [DllImport("kernel32.dll")]
    public static extern IntPtr GetStdHandle(int nStdHandle);

    [DllImport("kernel32.dll")]
    public static extern bool GetConsoleMode(IntPtr hConsoleHandle, out int lpMode);

    [DllImport("kernel32.dll")]
    public static extern bool SetConsoleMode(IntPtr hConsoleHandle, int dwMode);
}
"@ -ErrorAction Stop
        }

        $handle = [NativeConsole]::GetStdHandle(-11)
        $mode = 0
        if (-not [NativeConsole]::GetConsoleMode($handle, [ref]$mode)) {
            return $false
        }

        return [NativeConsole]::SetConsoleMode($handle, ($mode -bor 0x0004))
    } catch {
        return $false
    }
}

function Test-AnsiSupported {
    if ($env:NO_COLOR) {
        return $false
    }

    try {
        if ([Console]::IsOutputRedirected) {
            return $false
        }
    } catch {
        # Continue with environment-based detection.
    }

    if ($env:WT_SESSION -or $env:ANSICON -or $env:ConEmuANSI -eq "ON" -or $env:TERM_PROGRAM -or ($env:TERM -match "xterm|ansi|vt100|screen|tmux|cygwin")) {
        return $true
    }

    return (Enable-VirtualTerminalOutput)
}

function Write-ColorLine {
    param(
        [string]$Text,
        [int]$Depth = 0,
        [string]$Kind = "Folder"
    )

    $color = Get-DepthColor -Depth $Depth -Kind $Kind
    Write-AnsiLine -Text $Text -ColorCode $color
}

function Write-TreeRow {
    param(
        [object]$Row
    )

    if ($Row.PSObject.Properties.Name -notcontains "BranchText") {
        Write-ColorLine -Text $Row.Text -Depth $Row.Depth -Kind $Row.Kind
        return
    }

    $nameColor = Get-DepthColor -Depth $Row.Depth -Kind $Row.Kind
    $pathText = '"{0}"' -f $Row.PathText

    if (-not $Script:UseAnsi) {
        Write-Host $Row.Text
        return
    }

    if ($Row.PSObject.Properties.Name -contains "ExtensionText") {
        Write-Host "$($Script:AnsiBranch)$($Row.BranchText)$($Script:AnsiReset)$($Script:AnsiFileName)$($Row.NameBaseText)$($Script:AnsiReset)$($Script:AnsiFileExtension)$($Row.ExtensionText)$($Script:AnsiReset) | $($Script:AnsiPath)$pathText$($Script:AnsiReset)"
        return
    }

    Write-Host "$($Script:AnsiBranch)$($Row.BranchText)$($Script:AnsiReset)$nameColor$($Row.NameText)$($Script:AnsiReset) | $($Script:AnsiPath)$pathText$($Script:AnsiReset)"
}

function Write-AnsiLine {
    param(
        [string]$Text,
        [string]$ColorCode
    )

    if ($Script:UseAnsi) {
        Write-Host "$ColorCode$Text$($Script:AnsiReset)"
    } else {
        Write-Host $Text
    }
}

function Convert-AnsiToCssColor {
    param([string]$AnsiCode)

    $trueColorMatch = [regex]::Match($AnsiCode, "\[38;2;(\d{1,3});(\d{1,3});(\d{1,3})m")
    if ($trueColorMatch.Success) {
        return "rgb($($trueColorMatch.Groups[1].Value), $($trueColorMatch.Groups[2].Value), $($trueColorMatch.Groups[3].Value))"
    }

    return "inherit"
}

function ConvertTo-HtmlText {
    param([string]$Text)

    return [System.Net.WebUtility]::HtmlEncode($Text)
}

function New-HtmlSpan {
    param(
        [string]$Text,
        [string]$ColorCode
    )

    $color = Convert-AnsiToCssColor -AnsiCode $ColorCode
    $encodedText = ConvertTo-HtmlText -Text $Text
    return '<span style="color: {0}">{1}</span>' -f $color, $encodedText
}

function Convert-RowToHtml {
    param([object]$Row)

    if ($Row.PSObject.Properties.Name -notcontains "BranchText") {
        return New-HtmlSpan -Text $Row.Text -ColorCode (Get-DepthColor -Depth $Row.Depth -Kind $Row.Kind)
    }

    $branch = New-HtmlSpan -Text $Row.BranchText -ColorCode $Script:AnsiBranch
    if ($Row.PSObject.Properties.Name -contains "ExtensionText") {
        $nameBase = New-HtmlSpan -Text $Row.NameBaseText -ColorCode $Script:AnsiFileName
        $extension = New-HtmlSpan -Text $Row.ExtensionText -ColorCode $Script:AnsiFileExtension
        $name = "$nameBase$extension"
    } else {
        $name = New-HtmlSpan -Text $Row.NameText -ColorCode (Get-DepthColor -Depth $Row.Depth -Kind $Row.Kind)
    }
    $separator = ConvertTo-HtmlText -Text " | "
    $path = New-HtmlSpan -Text ('"{0}"' -f $Row.PathText) -ColorCode $Script:AnsiPath

    return "$branch$name$separator$path"
}

function New-HtmlReport {
    param(
        [System.Collections.Generic.List[object]]$Rows,
        [string]$Title
    )

    $encodedTitle = ConvertTo-HtmlText -Text $Title
    $bodyLines = $Rows | ForEach-Object { Convert-RowToHtml -Row $_ }
    $body = $bodyLines -join [Environment]::NewLine

    return @"
<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>$encodedTitle</title>
<style>
:root {
    color-scheme: dark;
    background: #070b10;
    color: #dce6f2;
}
html,
body {
    margin: 0;
    min-height: 100%;
    background: #070b10;
}
body {
    padding: 24px;
    font-family: Consolas, "Cascadia Mono", "JetBrains Mono", "Courier New", monospace;
    font-size: 15px;
    line-height: 1.35;
}
main {
    max-width: none;
}
pre {
    margin: 0;
    padding: 18px 20px;
    overflow: auto;
    white-space: pre-wrap;
    word-break: break-word;
    background: #0b1118;
    border: 1px solid #1d2a38;
    border-radius: 8px;
    box-shadow: 0 18px 45px rgba(0, 0, 0, 0.32);
}
::selection {
    background: #294461;
    color: #ffffff;
}
</style>
</head>
<body>
<main>
<pre>$body</pre>
</main>
</body>
</html>
"@
}

function Write-Log {
    param(
        [string]$Message,
        [ValidateSet("INFO", "WARN", "ERROR")]
        [string]$Level = "INFO"
    )

    if ([string]::IsNullOrWhiteSpace($Script:LogPath)) {
        return
    }

    try {
        $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss.fff"
        $line = "[{0}] [{1}] {2}{3}" -f $timestamp, $Level, $Message, [Environment]::NewLine
        [System.IO.File]::AppendAllText($Script:LogPath, $line, [System.Text.UTF8Encoding]::new($false))
    } catch {
        # Logging must never stop report generation.
    }
}

function Get-ConsoleWidth {
    try {
        $width = [Console]::WindowWidth
        if ($width -ge 40) {
            return [Math]::Min($width, 120)
        }
    } catch {
        # Use the default width below when the host does not expose a console.
    }

    return 120
}

function Write-StartupBanner {
    $width = Get-ConsoleWidth
    $title = $Script:ProjectName
    $leftPadding = [Math]::Max(0, [int](($width - $title.Length) / 2))
    $separator = "=" * $width

    Write-Host ""
    Write-AnsiLine -Text (" " * $leftPadding + $title) -ColorCode $Script:AnsiRose
    Write-AnsiLine -Text $separator -ColorCode $Script:AnsiRose

    if ([string]::IsNullOrWhiteSpace($Script:LogPath)) {
        Write-AnsiLine -Text "Logging disabled" -ColorCode $Script:AnsiGold
    } else {
        Write-AnsiLine -Text "Logging to: $($Script:LogPath)" -ColorCode $Script:AnsiGold
    }

    Write-Host ""
}

function Get-FallbackOutputRoot {
    if (-not [string]::IsNullOrWhiteSpace($env:LOCALAPPDATA)) {
        return (Join-Path $env:LOCALAPPDATA "FileTreeReporter")
    }

    return (Join-Path ([System.IO.Path]::GetTempPath()) "FileTreeReporter")
}

function Test-WritableDirectory {
    param([string]$Directory)

    try {
        New-Item -ItemType Directory -Path $Directory -Force -ErrorAction Stop | Out-Null
        $probePath = Join-Path $Directory ".ftree-write-test-$([Guid]::NewGuid().ToString('N')).tmp"
        [System.IO.File]::WriteAllText($probePath, "ok", [System.Text.UTF8Encoding]::new($false))
        Remove-Item -LiteralPath $probePath -Force -ErrorAction SilentlyContinue
        return $true
    } catch {
        return $false
    }
}

function Resolve-OutputDirectory {
    param(
        [string]$ProjectRoot,
        [string]$LeafName
    )

    $primary = Join-Path $ProjectRoot $LeafName
    if (Test-WritableDirectory -Directory $primary) {
        return $primary
    }

    $fallback = Join-Path (Get-FallbackOutputRoot) $LeafName
    if (Test-WritableDirectory -Directory $fallback) {
        return $fallback
    }

    throw "Cannot write to '$primary' or fallback '$fallback'."
}

function Get-UniqueBasePath {
    param(
        [string]$Directory,
        [string]$BaseName,
        [string[]]$Extensions
    )

    $basePath = Join-Path $Directory $BaseName
    $candidate = $basePath
    $counter = 2

    while (@($Extensions | Where-Object { Test-Path -LiteralPath "$candidate$_" }).Count -gt 0) {
        $candidate = "$basePath-$counter"
        $counter++
    }

    return $candidate
}

function Initialize-Logging {
    param([string]$ProjectRoot)

    try {
        $logsDir = Resolve-OutputDirectory -ProjectRoot $ProjectRoot -LeafName "Logs"
        $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss-fff"
        $logBasePath = Get-UniqueBasePath -Directory $logsDir -BaseName "ftree_${timestamp}_p$PID" -Extensions @(".log")
        $Script:LogPath = "$logBasePath.log"
        Write-Log -Message "$($Script:ProjectName) started."
    } catch {
        $Script:LogPath = $null
        Write-Host "WARNING: Logging is disabled: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

function Reset-RunCounters {
    $Script:TotalFiles = 0
    $Script:TotalFolders = 0
    $Script:TotalErrors = 0
    $Script:TotalLinks = 0
}

function Get-SafeFileName {
    param([string]$Name)

    $invalid = [System.IO.Path]::GetInvalidFileNameChars()
    $safe = $Name
    foreach ($char in $invalid) {
        $safe = $safe.Replace($char, "_")
    }
    $safe = $safe.Trim()
    if ([string]::IsNullOrWhiteSpace($safe)) {
        return "Root"
    }
    return $safe
}

function Test-ReparsePoint {
    param([System.IO.FileSystemInfo]$Item)

    return (($Item.Attributes -band [System.IO.FileAttributes]::ReparsePoint) -ne 0)
}

function Format-ItemName {
    param([System.IO.FileSystemInfo]$Item)

    if ($Item.PSIsContainer) {
        if (Test-ReparsePoint -Item $Item) {
            return "$($Item.Name)/ [link/junction - not expanded]"
        }
        return "$($Item.Name)/"
    }

    if (Test-ReparsePoint -Item $Item) {
        return "$($Item.Name) [link]"
    }

    return $Item.Name
}

function Get-ChildrenSafe {
    param([string]$LiteralPath)

    try {
        $childErrors = @()
        $items = @(Get-ChildItem -LiteralPath $LiteralPath -Force -ErrorAction SilentlyContinue -ErrorVariable childErrors |
            Sort-Object @{ Expression = { -not $_.PSIsContainer } }, Name)

        $errorRows = @()
        foreach ($childError in $childErrors) {
            $Script:TotalErrors++
            Write-Log -Level "WARN" -Message "Failed while reading '$LiteralPath': $($childError.Exception.Message)"
            $errorRows += [pscustomobject]@{
                IsError = $true
                Message = "ACCESS ERROR: $($childError.Exception.Message)"
            }
        }

        return @($items + $errorRows)
    } catch {
        $Script:TotalErrors++
        Write-Log -Level "WARN" -Message "Failed to read '$LiteralPath': $($_.Exception.Message)"
        return @([pscustomobject]@{
            IsError = $true
            Message = "ACCESS ERROR: $($_.Exception.Message)"
        })
    }
}

function Add-Tree {
    param(
        [string]$LiteralPath,
        [string]$Prefix,
        [int]$Depth,
        [System.Collections.Generic.List[object]]$Rows
    )

    $children = @(Get-ChildrenSafe -LiteralPath $LiteralPath)

    for ($i = 0; $i -lt $children.Count; $i++) {
        $child = $children[$i]
        $isLast = ($i -eq $children.Count - 1)
        $branch = if ($isLast) { $Script:TreeLast } else { $Script:TreeMiddle }
        $nextPrefix = if ($isLast) { "$Prefix    " } else { "$Prefix$($Script:TreePipe)   " }

        if ($child.PSObject.Properties.Name -contains "IsError") {
            $line = "$Prefix$branch$($child.Message)"
            $Rows.Add([pscustomobject]@{
                Text = $line
                Depth = $Depth
                Kind = "Error"
            }) | Out-Null
            continue
        }

        $isLink = Test-ReparsePoint -Item $child
        $kind = if ($isLink) { "Link" } elseif ($child.PSIsContainer) { "Folder" } else { "File" }

        if ($isLink) {
            $Script:TotalLinks++
        } elseif ($child.PSIsContainer) {
            $Script:TotalFolders++
        } else {
            $Script:TotalFiles++
        }

        $branchText = "$Prefix$branch"
        $nameText = Format-ItemName -Item $child
        $pathText = $child.FullName
        $line = '{0}{1} | "{2}"' -f $branchText, $nameText, $pathText
        $row = [ordered]@{
            Text = $line
            Depth = $Depth
            Kind = $kind
            BranchText = $branchText
            NameText = $nameText
            PathText = $pathText
        }

        if (($kind -eq "File") -and (-not [string]::IsNullOrEmpty($child.Extension)) -and ($child.Name.Length -gt $child.Extension.Length)) {
            $row.NameBaseText = $child.Name.Substring(0, $child.Name.Length - $child.Extension.Length)
            $row.ExtensionText = $child.Extension
        }

        $Rows.Add([pscustomobject]$row) | Out-Null

        if ($child.PSIsContainer -and -not $isLink) {
            Add-Tree -LiteralPath $child.FullName -Prefix $nextPrefix -Depth ($Depth + 1) -Rows $Rows
        }
    }
}

function Resolve-TargetPath {
    param([string]$InputPath)

    if ([string]::IsNullOrWhiteSpace($InputPath)) {
        throw "No folder path was provided."
    }

    Write-Log -Message "Resolving input path: $InputPath"
    $cleanInput = $InputPath.Trim().Trim('"').Trim()
    $expanded = [Environment]::ExpandEnvironmentVariables($cleanInput)
    $resolved = @(Resolve-Path -LiteralPath $expanded -ErrorAction Stop)

    $item = Get-Item -LiteralPath $resolved[0].Path -Force -ErrorAction Stop
    if (-not $item.PSIsContainer) {
        throw "The provided path is not a folder: $($item.FullName)"
    }

    Write-Log -Message "Target path resolved: $($item.FullName)"
    return $item.FullName
}

function Show-ReporterError {
    param([string]$Message)

    Write-Log -Level "ERROR" -Message "Error: $Message"
    Write-Host ""
    Write-Host "ERROR: $Message" -ForegroundColor Red
    Write-Host ""
}

function Invoke-Report {
    param(
        [string]$InputPath,
        [string]$ProjectRoot
    )

    Reset-RunCounters

    $target = Resolve-TargetPath -InputPath $InputPath
    $root = Get-Item -LiteralPath $target -Force

    $reportsDir = Resolve-OutputDirectory -ProjectRoot $ProjectRoot -LeafName "Reports"

    $timestamp = Get-Date -Format "yyyy-MM-dd_HH-mm-ss-fff"
    $safeRootName = Get-SafeFileName -Name $root.Name
    $reportBaseName = "tree-report_${safeRootName}_${timestamp}_p$PID"
    $reportBasePath = Get-UniqueBasePath -Directory $reportsDir -BaseName $reportBaseName -Extensions @(".txt", ".html")
    $reportPath = "$reportBasePath.txt"
    $htmlReportPath = "$reportBasePath.html"

    $rows = [System.Collections.Generic.List[object]]::new()

    $header = @(
        [pscustomobject]@{ Text = "$($Script:ProjectName) Report"; Kind = "Header"; PrintToConsole = $false },
        [pscustomobject]@{ Text = "Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')"; Kind = "HeaderGenerated"; PrintToConsole = $true },
        [pscustomobject]@{ Text = "Root: $($root.FullName)"; Kind = "HeaderRoot"; PrintToConsole = $true },
        [pscustomobject]@{ Text = ""; Kind = "Header"; PrintToConsole = $true },
        [pscustomobject]@{ Text = "$($root.FullName)"; Kind = "Root"; PrintToConsole = $true }
    )

    foreach ($row in $header) {
        $rows.Add([pscustomobject]@{
            Text = $row.Text
            Depth = 0
            Kind = $row.Kind
            PrintToConsole = $row.PrintToConsole
        }) | Out-Null
    }

    Add-Tree -LiteralPath $root.FullName -Prefix "" -Depth 1 -Rows $rows

    $summary = @(
        [pscustomobject]@{ Text = ""; Kind = "Summary" },
        [pscustomobject]@{ Text = "Summary:"; Kind = "Summary" },
        [pscustomobject]@{ Text = "Folders: $Script:TotalFolders"; Kind = "SummaryFolders" },
        [pscustomobject]@{ Text = "Files: $Script:TotalFiles"; Kind = "SummaryFiles" },
        [pscustomobject]@{ Text = "Links/Junctions: $Script:TotalLinks"; Kind = "SummaryLinks" },
        [pscustomobject]@{ Text = "Errors: $Script:TotalErrors"; Kind = "SummaryErrors" }
    )

    foreach ($row in $summary) {
        $rows.Add([pscustomobject]@{
            Text = $row.Text
            Depth = 0
            Kind = $row.Kind
        }) | Out-Null
    }

    foreach ($row in $rows) {
        if (($row.PSObject.Properties.Name -contains "PrintToConsole") -and (-not $row.PrintToConsole)) {
            continue
        }

        Write-TreeRow -Row $row
    }

    $plainText = ($rows | ForEach-Object { $_.Text }) -join [Environment]::NewLine
    [System.IO.File]::WriteAllText($reportPath, $plainText, [System.Text.UTF8Encoding]::new($false))
    $htmlText = New-HtmlReport -Rows $rows -Title "$($Script:ProjectName) Report - $($root.FullName)"
    [System.IO.File]::WriteAllText($htmlReportPath, $htmlText, [System.Text.UTF8Encoding]::new($false))
    Write-Log -Message "Report saved: $reportPath"
    Write-Log -Message "HTML report saved: $htmlReportPath"
    Write-Log -Message "Summary: folders=$Script:TotalFolders files=$Script:TotalFiles links=$Script:TotalLinks errors=$Script:TotalErrors"

    Write-Host ""
    Write-Host "TXT report saved to:" -ForegroundColor Green
    Write-Host $reportPath -ForegroundColor Yellow
    Write-Host ""
    Write-Host "HTML report saved to:" -ForegroundColor Green
    Write-Host $htmlReportPath -ForegroundColor Yellow
    Write-Host ""
}

function Test-QuitCommand {
    param([string]$Value)

    if ($null -eq $Value) {
        return $true
    }

    $trimmed = $Value.Trim()
    return ($trimmed -in @("q", "quit", "exit"))
}

function Read-TargetPath {
    param([string]$Prompt)

    try {
        if ([Console]::IsInputRedirected) {
            $line = [Console]::In.ReadLine()
            if ($null -eq $line) {
                return $null
            }

            return $line
        }
    } catch {
        # Fall back to Read-Host when redirection cannot be detected.
    }

    return (Read-Host $Prompt)
}

function Start-Reporter {
    param([string]$InitialPath)

    try {
        Clear-Host
    } catch {
        # Some hosts do not expose an interactive console buffer.
    }

    $Script:UseAnsi = Test-AnsiSupported
    $projectRoot = Split-Path -Parent $PSScriptRoot
    Initialize-Logging -ProjectRoot $projectRoot
    Write-StartupBanner

    if (-not [string]::IsNullOrWhiteSpace($InitialPath)) {
        Invoke-Report -InputPath $InitialPath -ProjectRoot $projectRoot
        return
    }

    $blankInputCount = 0
    while ($true) {
        $exitHint = "$($Script:AnsiExitHint){quit=exit}$($Script:AnsiReset)"
        $prompt = if ($Script:UseAnsi) { "Enter the target folder path $exitHint" } else { "Enter the target folder path {quit=exit}" }
        $inputPath = Read-TargetPath -Prompt $prompt

        if (Test-QuitCommand -Value $inputPath) {
            Write-Log -Message "$($Script:ProjectName) closed by user."
            break
        }

        if ([string]::IsNullOrWhiteSpace($inputPath)) {
            $blankInputCount++
            if ($blankInputCount -ge 5) {
                Write-Log -Message "$($Script:ProjectName) closed after repeated empty input."
                Write-Host "Empty input repeated; closing to avoid waiting on closed input." -ForegroundColor Yellow
                Write-Host ""
                break
            }

            Write-Host "Please enter a folder path, or type Q to quit." -ForegroundColor Yellow
            Write-Host ""
            continue
        }

        $blankInputCount = 0
        try {
            Invoke-Report -InputPath $inputPath -ProjectRoot $projectRoot
            Write-Host "Ready for the next folder." -ForegroundColor Cyan
            Write-Host ""
        } catch {
            Show-ReporterError -Message $_.Exception.Message
        }
    }
}

try {
    Start-Reporter -InitialPath $Path
} catch {
    Show-ReporterError -Message $_.Exception.Message
    exit 1
}
