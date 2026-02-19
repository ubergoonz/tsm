# Changelog

All notable changes to the Tmux Session Manager (TSM) project will be documented in this file.

## [Unreleased]

### Added
- **Ctrl+C Safety Handler**: Trap Ctrl+C interrupts and prompt user for confirmation before quitting ([PR #1](https://github.com/ubergoonz/tsm/pull/1))
- **View Sessions Menu**: New [s] option to browse and manage all sessions from a dedicated interface ([PR #1](https://github.com/ubergoonz/tsm/pull/1))
- **Session Counter**: Display active session count next to "Current tmux sessions" label ([PR #1](https://github.com/ubergoonz/tsm/pull/1))
- **Easy Cancellation**: Users can type 'q', 'cancel', or 'back' to exit input prompts without completing actions ([PR #1](https://github.com/ubergoonz/tsm/pull/1))
- **Enhanced Error Handling**: Better return value handling to prevent `set -e` from causing unintended exits ([PR #1](https://github.com/ubergoonz/tsm/pull/1))

### Changed
- Main menu now includes [s] View Sessions option in addition to existing options ([PR #1](https://github.com/ubergoonz/tsm/pull/1))
- Improved user feedback with clearer "Cancelled" messages and visual hints ([PR #1](https://github.com/ubergoonz/tsm/pull/1))
- Updated menu hints and instructions to reflect new functionality ([PR #1](https://github.com/ubergoonz/tsm/pull/1))

### Fixed
- Fixed issue where 'q' in session selection would quit the entire TUI instead of returning to main menu ([PR #1](https://github.com/ubergoonz/tsm/pull/1))
- Improved input handling for all read operations using `/dev/tty` consistently ([PR #1](https://github.com/ubergoonz/tsm/pull/1))

## [1.0.0] - 2026-02-19

### Initial Release

First release of the Tmux Session Manager (TSM).

#### Features
- **Interactive Terminal UI** - Beautiful ASCII-based interface with color-coded actions
- **Session Management** - Create, attach, rename, and kill tmux sessions
- **Smart Session Naming** - Auto-generates unused session names with numbered defaults
- **Menu Navigation** - Arrow key support with letter shortcuts for quick access
- **Session Listing** - View all active tmux sessions with window counts
- **Safety Confirmations** - Confirmation prompts before potentially destructive operations
- **Tmux Tips System** - Display categorized tmux tips including:
  - Session management tips
  - Window and pane operations
  - Copy mode and scrolling
  - Configuration and customization
  - Productivity tips and advanced features
  - Key concepts
- **Multiple Input Methods** - Support for arrow keys, letter shortcuts, and Enter for menu selection
- **Optional Directory Support** - Create sessions with custom starting directories
- **Attach Options** - Choose whether to attach to newly created sessions

#### Menu Options
- [c] Create new session
- [a] Attach to session  
- [r] Rename session
- [k] Kill session
- [x] Kill all sessions
- [f] Refresh
- [q] Quit

#### Technical Details
- Pure bash implementation (Bash 4.0+)
- Dependency: tmux must be installed
- Cross-platform: macOS and Linux support
- Clean codebase with organized functions and clear comments
- Proper use of ANSI color codes for visual enhancement
- Unicode box drawing characters for professional appearance

#### Known Limitations
- Requires interactive terminal (non-interactive environments detected and handled)
- Escape sequence handling depends on terminal capabilities

---

## Format Notes

This changelog follows the [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) format.

Version categories:
- **[Unreleased]** - Changes that are not yet released
- **[X.Y.Z]** - Released versions with dates in YYYY-MM-DD format

Change types:
- **Added** - New features
- **Changed** - Changes in existing functionality
- **Deprecated** - Features that will be removed soon
- **Removed** - Features that have been deleted
- **Fixed** - Bug fixes
- **Security** - Security vulnerability fixes
