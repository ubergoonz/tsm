# TSM - Tmux Session Manager

```
  ████████╗███████╗███╗   ███╗
  ╚══██╔══╝██╔════╝████╗ ████║
     ██║   ███████╗██╔████╔██║
     ██║   ╚════██║██║╚██╔╝██║
     ██║   ███████║██║ ╚═╝ ██║
     ╚═╝   ╚══════╝╚═╝     ╚═╝
                                
   ┌─────────────────────────────┐
   │  Tmux Session Manager       │
   │  Terminal UI for tmux       │
   └─────────────────────────────┘
```

![Shell Script](https://img.shields.io/badge/shell_script-%23121011.svg?style=for-the-badge&logo=gnu-bash&logoColor=white)
![Bash](https://img.shields.io/badge/bash-4EAA25?style=for-the-badge&logo=gnubash&logoColor=white)
![License](https://img.shields.io/badge/license-MIT-blue.svg?style=for-the-badge)
![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux-lightgrey?style=for-the-badge)

A beautiful and intuitive Terminal User Interface (TUI) for managing tmux sessions. Navigate with arrow keys, create sessions, attach/detach, rename, and kill sessions with ease.

## ✨ Features

- **Interactive TUI** - Beautiful terminal interface with arrow key navigation
- **Session Management** - Create, attach, rename, and kill tmux sessions
- **Visual Feedback** - Color-coded actions and clear status indicators
- **Smart Defaults** - Auto-generates session names and provides helpful hints
- **Keyboard Shortcuts** - Quick access via single-key commands (c, a, r, k, x, f, q)
- **Tmux Tips** - Learn tmux while you work with random tips displayed in the interface
- **Safety Checks** - Confirmation prompts before destructive actions
- **Session Listing** - View all active tmux sessions at a glance

## 🎯 How It Works

TSM is a bash script that provides a user-friendly wrapper around tmux commands. Here's what happens when you run it:

1. **Initialization**: Checks if tmux is installed and validates the environment
2. **Main Menu**: Displays an interactive menu with all available options
3. **Arrow Navigation**: Use ↑/↓ keys or keyboard shortcuts to select actions
4. **Interactive Prompts**: Guides you through each action with clear prompts
5. **Tmux Integration**: Seamlessly switches between sessions or attaches to them
6. **Continuous Loop**: Returns to the main menu after each action for easy workflow

### Core Functionality

- **Create Session**: Prompts for session name (with smart defaults) and optional starting directory
- **Attach to Session**: Shows a list of sessions to choose from with arrow key navigation
- **Rename Session**: Select a session and provide a new name
- **Kill Session**: Safely terminate individual sessions with confirmation
- **Kill All**: Clear all sessions (useful for cleanup)
- **Refresh**: Reload the session list
- **Tips System**: Displays categorized tmux tips organized by sessions, windows, panes, copy mode, config, and productivity

## 📦 Installation

### Quick Install

```bash
# Clone the repository
git clone https://github.com/ubergoonz/tsm.git

# Navigate to the directory
cd tsm

# Make the script executable
chmod +x tsm.sh

# Optional: Create a symbolic link for easy access
sudo ln -s "$(pwd)/tsm.sh" /usr/local/bin/tsm
```

### Prerequisites

- **tmux** must be installed on your system
- **bash** 4.0 or higher

#### Install tmux

**macOS:**
```bash
brew install tmux
```

**Ubuntu/Debian:**
```bash
sudo apt-get install tmux
```

**Fedora/RHEL:**
```bash
sudo dnf install tmux
```

## 🚀 Usage

### Basic Usage

```bash
# Run the script
./tsm.sh

# Or if you created a symlink
tsm
```

### Command Line Options

```bash
# Show version
./tsm.sh --version

# Show help
./tsm.sh --help
```

### Main Menu Options

Once launched, you'll see an interactive menu with these options:

- **[c] Create new session** - Create a new tmux session with optional custom name and directory
- **[a] Attach to session** - Switch to or attach to an existing session
- **[r] Rename session** - Change the name of an existing session
- **[k] Kill session** - Terminate a specific session
- **[x] Kill all sessions** - Terminate all active sessions (with confirmation)
- **[f] Refresh** - Reload the session list
- **[q] Quit** - Exit the manager

### Navigation

- Use **↑/↓ arrow keys** to move between menu options
- Press **Enter** to select the highlighted option
- Or press the **letter shortcut** (c, a, r, k, x, f, q) directly

## 🎨 Screenshots

The interface features:
- Clean ASCII box drawing characters
- Color-coded actions (green for create, blue for attach, red for delete, etc.)
- Organized session listing
- Real-time tmux tips at the bottom of each screen
- Visual selection indicators (►)

## 🛠️ Technical Details

### Script Architecture

```
tsm.sh
├── Environment Detection (non-interactive check, version/help flags)
├── Color Definitions (ANSI color codes)
├── Header Display (ASCII art box)
├── Tmux Installation Check
├── Session Management Functions
│   ├── list_sessions()
│   ├── create_session()
│   ├── attach_session()
│   ├── kill_session()
│   ├── kill_all_sessions()
│   └── rename_session()
├── Selection Interface (arrow key navigation)
├── Tips System (categorized tmux tips)
└── Main Loop (continuous menu display)
```

### Key Components

- **Arrow Key Detection**: Reads escape sequences for interactive navigation
- **Global Variables**: Uses `SELECTED_SESSION` for cross-function communication
- **Color System**: ANSI escape codes for visual feedback
- **Input Validation**: Checks for existing sessions and valid directories
- **tmux Integration**: Direct integration with tmux server commands

## 🤝 Contributing

Contributions are welcome! Feel free to:
- Report bugs
- Suggest new features
- Submit pull requests
- Improve documentation

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- Built for the tmux community
- Inspired by the need for easier session management
- Unicode box drawing characters for clean UI

## 📚 Resources

- [tmux documentation](https://github.com/tmux/tmux/wiki)
- [tmux cheat sheet](https://tmuxcheatsheet.com/)

---

**Made with ❤️ for tmux users**
