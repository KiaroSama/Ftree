# FileTreeReporter (Ftree) v1.0.0

Version tag suggestion: `v1.0.0`

Repository description:

A lightweight PowerShell tool that prints colorful folder trees and exports plain-text and dark HTML reports.

## Summary

This release updates FileTreeReporter with interactive prompt looping, full-path tree output, color-matched dark HTML reports, safer output naming, improved launcher behavior, and stronger documentation/repository hygiene.

## Added

- Dark-theme HTML reports generated beside the plain-text reports.
- Full-path display for tree items in terminal output, TXT reports, and HTML reports.
- Interactive prompt looping after each completed report.
- `{quit=exit}` prompt hint with support for `Q`, `quit`, and `exit`.
- Separate colors for branches, folder levels, file names, file extensions, paths, headers, and summary lines.
- A 50-level folder-depth color palette.
- Startup banner with the active log file path.
- Fallback report and log output under `%LOCALAPPDATA%\FileTreeReporter` when the project folder is not writable.

## Changed Behavior

- Tree items now use `name.ext | "full\path\name.ext"` formatting.
- Report and log filenames now include milliseconds and process ID to reduce name collisions.
- Direct path mode generates one report and exits; prompt mode stays open for more paths.
- Launchers prefer PowerShell 7 (`pwsh.exe`) when available and fall back to Windows PowerShell.
- The PATH installer preserves the existing Windows PATH registry value type.
- Console completion output now shows TXT and HTML report paths without repeating the log path footer.

## Fixed Issues

- Fixed the interactive launcher closing immediately after a completed report.
- Fixed repeated blank redirected input so closed input does not hang forever.
- Fixed quoted or whitespace-padded paths during input resolution.
- Fixed symlink/junction totals so they are not double-counted as regular folders or files.
- Fixed child enumeration handling so readable siblings are still included when one item cannot be read.
- Fixed encoding setup so an input encoding failure does not prevent output encoding setup.

## Removed Items

- Removed the final console-only `Log saved to:` footer.
- Removed the terminal-only `FileTreeReporter (Ftree) Report` title line while keeping it in saved reports.

## Breaking Changes

- No breaking changes are known.

## Requirements

- Windows.
- Windows PowerShell 5.1 or PowerShell 7+.
- No external PowerShell modules are required.

## Safety Notes

- Symlinks and junctions are listed but not expanded.
- Read errors are logged and counted in the summary where possible.
- Generated reports, logs, caches, temporary files, local command/comment folders, tokens, cookies, sessions, and credentials are covered by `.gitignore`.

## Upgrade Notes

- Open a new terminal after installing or updating the PATH entry.
- Existing generated reports and logs do not need migration.
- Review `.gitignore` before committing if your local workspace contains private helper folders or generated artifacts.

## License and Attribution

FileTreeReporter is released under the MIT License.

Copyright (c) 2026 Kiaro Sama.

Anyone copying, modifying, redistributing, republishing, or including substantial portions of this project must preserve the original MIT License notice and attribution to Kiaro Sama.
