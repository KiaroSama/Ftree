# Changelog

## [v1.0.0] - 2026-06-01

### Added

- Added a dark-theme HTML report alongside the plain-text report.
- Added full-path display for tree items in terminal output and reports.
- Added interactive prompt looping so another target folder can be entered after each completed report.
- Added colored terminal output for branches, folder-depth levels, file names, file extensions, paths, headers, and summary lines.
- Added a 50-level folder-depth color palette.
- Added startup banner output that shows the active log file path.
- Added fallback report and log directories under `%LOCALAPPDATA%\FileTreeReporter` when the project folder is not writable.

### Changed

- Changed report and log filenames to include milliseconds and process ID for safer unique names.
- Changed tree item formatting to use `name.ext | "full\path\name.ext"` for easier path separation.
- Changed direct path mode to generate one report and exit, while prompt mode stays interactive.
- Changed launchers to prefer `pwsh.exe` when available and fall back to `powershell.exe`.
- Changed the PATH installer to preserve the existing Windows PATH registry value type.
- Changed console completion output to show the generated TXT and HTML report paths.

### Fixed

- Fixed accidental launcher closure after an interactive report by returning to the prompt.
- Fixed repeated blank redirected input so closed input does not hang forever.
- Fixed quoted or padded input paths by trimming surrounding whitespace and quotes.
- Fixed symlink and junction counting so they are not double-counted as regular folders or files.
- Fixed child enumeration error handling so readable sibling items are still reported when one item fails.
- Fixed console encoding setup so one encoding failure does not block the remaining encoding settings.

### Removed

- Removed the final console-only `Log saved to:` footer.
- Removed the terminal-only report title line while keeping it in saved reports.

### Security

- Expanded `.gitignore` coverage for generated output, local command/comment folders, caches, temporary files, credentials, sessions, cookies, tokens, and editor metadata.
