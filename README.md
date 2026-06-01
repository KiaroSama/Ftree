# FileTreeReporter (Ftree)

A lightweight PowerShell tool that prints a colored folder/file tree in the terminal and saves clean `.txt` and dark-theme `.html` reports.

## Features

- Prompts for a target folder path.
- In interactive mode, returns to the folder prompt after each completed report.
- Accepts `Q`, `quit`, or `exit` to close from the prompt.
- Prints a readable, colored tree in the terminal with separate colors for branches, folder levels, file names, file extensions, and full paths.
- Shows each tree item with its full path using the format `name.ext | "C:\Full\Path\name.ext"`.
- Saves the same tree as a plain UTF-8 `.txt` report.
- Saves a matching dark-theme `.html` report using the same color groups as the terminal output.
- Writes a per-run execution log and shows the active log path in the startup banner.
- Includes files, folders, hidden items, and system items.
- Lists symlinks/junctions without expanding them to avoid recursive loops.
- Uses semantic colors plus a 50-level folder-depth palette for cleaner visual output.
- Uses unique report and log names with timestamp, milliseconds, and process ID.
- No external dependencies.
- GitHub-friendly repository structure.

## Requirements

- Windows.
- Windows PowerShell 5.1 or PowerShell 7+.
- No external PowerShell modules are required.

The launchers prefer `pwsh.exe` when it is available and fall back to `powershell.exe`.

## Installation

Download or clone the project, then run it from the project folder.

To add Ftree to your Windows PATH for the current user:

```powershell
.\Install-FtreePath.ps1
```

Open a new terminal after installing, then run:

```powershell
Ftree "C:\Your\Folder"
```

The PATH installer supports `-Scope User` by default, `-Scope Machine` from an elevated PowerShell session, `-Remove`, and PowerShell's standard `-WhatIf` behavior.

## Usage

### Double-click mode

Double-click:

```text
Run-FileTreeReporter.cmd
```

Then paste or type the folder path when prompted.
After a report is generated, enter another folder path or type `Q`, `quit`, or `exit` to quit.

### PowerShell mode

```powershell
.\Run.ps1
```

Or pass the folder path directly:

```powershell
.\Run.ps1 -Path "C:\Your\Folder"
```

### PATH mode

After installing the project folder into PATH:

```powershell
Ftree "C:\Your\Folder"
```

When a path is passed directly with `-Path` or `Ftree "C:\Your\Folder"`, Ftree generates one report and exits. When no path is passed, it stays in interactive prompt mode.

## Output and Logs

TXT and HTML reports are saved here when the install folder is writable:

```text
Reports\
```

Execution logs are saved here when the install folder is writable:

```text
Logs\
```

If those folders are not writable, Ftree falls back to `%LOCALAPPDATA%\FileTreeReporter\Reports` and `%LOCALAPPDATA%\FileTreeReporter\Logs`.

The startup banner prints the actual log file path being used. The final console output prints the generated TXT and HTML report paths.

Example output file name:

```text
tree-report_Project_2026-06-01_04-05-19-096_p24028.txt
tree-report_Project_2026-06-01_04-05-19-096_p24028.html
```

## Safety Notes

- Symlinks and junctions are listed but not expanded.
- Read errors are logged and included in the summary where possible.
- Empty redirected input exits after repeated blank reads to avoid waiting forever on closed input.
- The PATH installer updates the selected Windows PATH registry value and preserves its existing registry value type.

## Repository Files

- `src/FileTreeReporter.ps1` - main reporter script.
- `Run.ps1` - PowerShell launcher.
- `Run-FileTreeReporter.cmd` - double-click launcher.
- `Ftree.cmd` - PATH-friendly command launcher.
- `Install-FtreePath.ps1` - optional Windows PATH installer/remover.
- `Reports/.gitkeep` - keeps the report folder in the repository while generated reports stay ignored.

## Troubleshooting

- If `Ftree` is not found after installing to PATH, open a new terminal.
- If terminal colors are missing, the current host may not support ANSI colors or output may be redirected.
- If the install folder is not writable, reports and logs are written under `%LOCALAPPDATA%\FileTreeReporter`.
- If PowerShell blocks direct script execution, use `Run.ps1` or the `.cmd` launchers, which run the script with `-ExecutionPolicy Bypass` for that process only.

## Notes

- The terminal output is colored when ANSI output is supported.
- The `.txt` report is plain text so it remains readable in Notepad, VS Code, GitHub, and other editors.
- The `.html` report keeps the terminal-style colors on a dark background for browser viewing.
- The `Reports` folder is kept in the repository with `.gitkeep`, but generated `.txt` and `.html` reports are ignored by Git.

## Author

Created by Kiaro Sama.

GitHub: [KiaroSama](https://github.com/KiaroSama)

## License and Attribution

This project is released under the MIT License.

Copyright (c) 2026 Kiaro Sama.

You may use, copy, modify, publish, distribute, sublicense, and sell copies of this project under the MIT License, as long as the original copyright notice and permission notice are preserved in all copies or substantial portions of the software.
