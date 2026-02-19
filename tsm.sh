#!/usr/bin/env bash

# Tmux Session Manager - Terminal User Interface
# A simple TUI for managing tmux sessions

set -e

# Get program name from $0
PROG_NAME=$(basename "$0")

# Handle version flag and non-interactive mode
if [[ "${1:-}" == "--version" ]] || [[ "${1:-}" == "-v" ]]; then
    echo "tmux-manager 1.0.0"
    exit 0
fi

if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
    cat << EOF
Tmux Session Manager - Terminal User Interface

Usage: $PROG_NAME [OPTIONS]

Options:
  -v, --version    Show version information
  -h, --help       Show this help message

Interactive TUI for managing tmux sessions:
  - Create new sessions
  - Attach to existing sessions
  - Rename sessions
  - Kill sessions
  - View random tmux tips

Repository: https://github.com/ubergoonz/tsm
EOF
    exit 0
fi

# Detect non-interactive environment (for CI/testing)
if [[ ! -t 0 ]] && [[ -z "${TMUX_MANAGER_FORCE_INTERACTIVE:-}" ]]; then
    echo "tmux-manager: Non-interactive environment detected"
    echo "Use TMUX_MANAGER_FORCE_INTERACTIVE=1 to override"
    exit 0
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Clear screen and show header
show_header() {
    clear
    local title="TMUX SESSION MANAGER"
    local box_width=60
    local title_length=${#title}
    local padding=$(( (box_width - title_length) / 2 ))
    local right_padding=$(( box_width - title_length - padding ))
    
    # Top border
    echo -e "${CYAN}╔════════════════════════════════════════════════════════════╗${NC}"
    
    # Title line - properly centered
    printf "${CYAN}║${BOLD}%*s%s%*s${CYAN}║${NC}\n" $padding "" "$title" $right_padding ""
    
    # Bottom border
    echo -e "${CYAN}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

# Check if tmux is installed
check_tmux() {
    if ! command -v tmux &> /dev/null; then
        echo -e "${RED}Error: tmux is not installed${NC}"
        echo "Please install tmux first:"
        echo "  macOS: brew install tmux"
        echo "  Ubuntu/Debian: sudo apt-get install tmux"
        exit 1
    fi
}

# List all tmux sessions
list_sessions() {
    # Count current sessions
    local session_count=0
    if tmux list-sessions &>/dev/null; then
        session_count=$(tmux list-sessions 2>/dev/null | wc -l)
    fi
    
    # Display header with session count
    if [ $session_count -eq 0 ]; then
        echo -e "${BOLD}Current tmux sessions:${NC}"
    else
        local session_label=$([ $session_count -eq 1 ] && echo "session" || echo "sessions")
        echo -e "${BOLD}Current tmux sessions (${CYAN}$session_count${NC}${BOLD} active $session_label):${NC}"
    fi
    echo ""
    
    if tmux list-sessions 2>/dev/null; then
        echo ""
    else
        echo -e "${YELLOW}No active tmux sessions${NC}"
        echo ""
    fi
}

# Generate a default unused session name
generate_default_session_name() {
    local counter=1
    local default_name="session-$counter"
    
    while tmux has-session -t "$default_name" 2>/dev/null; do
        ((counter++))
        default_name="session-$counter"
    done
    
    echo "$default_name"
}

# Create a new session
create_session() {
    show_header
    echo -e "${GREEN}Create New Session${NC}"
    echo ""
    
    # Generate default name
    local default_name
    default_name=$(generate_default_session_name)
    
    # Display prompt with colors
    echo -ne "Enter session name [${CYAN}$default_name${NC}]: "
    read session_name
    
    # Use default if empty
    if [ -z "$session_name" ]; then
        session_name="$default_name"
        echo -e "${YELLOW}Using default name: $session_name${NC}"
    fi
    
    if tmux has-session -t "$session_name" 2>/dev/null; then
        echo -e "${RED}Session '$session_name' already exists${NC}"
        sleep 2
        return
    fi
    
    read -p "Enter starting directory (leave empty for current): " start_dir
    
    if [ -z "$start_dir" ]; then
        tmux new-session -d -s "$session_name"
    else
        if [ -d "$start_dir" ]; then
            tmux new-session -d -s "$session_name" -c "$start_dir"
        else
            echo -e "${RED}Directory '$start_dir' does not exist${NC}"
            sleep 2
            return
        fi
    fi
    
    echo -e "${GREEN}✓ Session '$session_name' created successfully${NC}"
    echo ""
    read -p "Attach to this session now? (Y/n): " attach_choice
    
    if [[ "$attach_choice" =~ ^[Nn]$ ]]; then
        sleep 1
        return
    fi
    
    # Attach to the session
    if [ -n "$TMUX" ]; then
        # Already inside tmux, switch to the new session
        tmux switch-client -t "$session_name"
    else
        # Not inside tmux, attach to the new session
        tmux attach-session -t "$session_name"
    fi
}

# Select a session using arrow keys
# Returns selected session name via global variable SELECTED_SESSION
select_session() {
    local prompt_text="$1"
    local prompt_color="$2"
    
    # Reset the global variable
    SELECTED_SESSION=""
    
    # Get list of sessions
    local sessions=()
    while IFS= read -r line; do
        # Extract session name (first field before colon)
        local session_name
        session_name=$(echo "$line" | cut -d: -f1)
        sessions+=("$session_name")
    done < <(tmux list-sessions 2>/dev/null)
    
    if [ ${#sessions[@]} -eq 0 ]; then
        return 1
    fi
    
    local selected=0
    local num_sessions=${#sessions[@]}
    
    while true; do
        clear
        show_header
        echo -e "${prompt_color}${prompt_text}${NC}"
        echo -e "${CYAN}(Use ↑/↓ arrows and Enter to select, or 'q' to cancel)${NC}"
        echo ""
        
        # Display sessions
        for i in "${!sessions[@]}"; do
            if [ $i -eq $selected ]; then
                echo -e "  ${BOLD}${prompt_color}► ${sessions[$i]}${NC}"
            else
                echo -e "    ${sessions[$i]}"
            fi
        done
        echo ""
        
        # Read input - redirect from terminal
        read -rsn1 key </dev/tty
        
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 key </dev/tty
            case $key in
                '[A') # Up arrow
                    ((selected--))
                    if [ $selected -lt 0 ]; then
                        selected=$((num_sessions - 1))
                    fi
                    ;;
                '[B') # Down arrow
                    ((selected++))
                    if [ $selected -ge $num_sessions ]; then
                        selected=0
                    fi
                    ;;
            esac
        elif [[ $key == "" ]]; then
            # Enter pressed - set global and return success
            SELECTED_SESSION="${sessions[$selected]}"
            return 0
        elif [[ $key == "q" ]] || [[ $key == "Q" ]]; then
            # Cancelled
            return 1
        fi
    done
}

# Attach to a session
attach_session() {
    show_header
    list_sessions
    
    if ! tmux list-sessions &>/dev/null; then
        echo -e "${YELLOW}No sessions to attach to${NC}"
        sleep 2
        return
    fi
    
    select_session "Select Session to Attach" "$GREEN"
    
    if [ -z "$SELECTED_SESSION" ]; then
        echo -e "${YELLOW}Cancelled${NC}"
        sleep 1
        return
    fi
    
    # Attach to the selected session
    if [ -n "$TMUX" ]; then
        # Already inside tmux, switch to session
        tmux switch-client -t "$SELECTED_SESSION"
    else
        # Not inside tmux, attach to session
        tmux attach-session -t "$SELECTED_SESSION"
    fi
}

# Kill a session
kill_session() {
    show_header
    list_sessions
    
    if ! tmux list-sessions &>/dev/null; then
        echo -e "${YELLOW}No sessions to kill${NC}"
        sleep 2
        return
    fi
    
    select_session "Select Session to Kill" "$RED"
    
    if [ -z "$SELECTED_SESSION" ]; then
        echo -e "${YELLOW}Cancelled${NC}"
        sleep 1
        return
    fi
    
    # Confirm before killing
    clear
    show_header
    echo -e "${RED}Kill Session${NC}"
    echo ""
    read -p "Are you sure you want to kill session '$SELECTED_SESSION'? (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        tmux kill-session -t "$SELECTED_SESSION"
        echo -e "${GREEN}✓ Session '$SELECTED_SESSION' killed${NC}"
        sleep 1
    else
        echo -e "${YELLOW}Cancelled${NC}"
        sleep 1
    fi
}

# Kill all sessions
kill_all_sessions() {
    show_header
    
    if ! tmux list-sessions &>/dev/null; then
        echo -e "${YELLOW}No sessions to kill${NC}"
        sleep 2
        return
    fi
    
    list_sessions
    
    echo -e "${RED}${BOLD}Kill All Sessions${NC}"
    echo ""
    read -p "Are you sure you want to kill ALL sessions? (y/N): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        tmux kill-server
        echo -e "${GREEN}✓ All sessions killed${NC}"
        sleep 1
    else
        echo -e "${YELLOW}Cancelled${NC}"
        sleep 1
    fi
}

# Rename a session
rename_session() {
    show_header
    list_sessions
    
    if ! tmux list-sessions &>/dev/null; then
        echo -e "${YELLOW}No sessions to rename${NC}"
        sleep 2
        return
    fi
    
    select_session "Select Session to Rename" "$BLUE"
    
    if [ -z "$SELECTED_SESSION" ]; then
        echo -e "${YELLOW}Cancelled${NC}"
        sleep 1
        return
    fi
    
    local old_name="$SELECTED_SESSION"
    
    # Ask for new name
    clear
    show_header
    echo -e "${BLUE}Rename Session${NC}"
    echo ""
    echo -e "Current name: ${CYAN}$old_name${NC}"
    echo ""
    read -p "Enter new session name: " new_name
    
    if [ -z "$new_name" ]; then
        echo -e "${RED}New session name cannot be empty${NC}"
        sleep 2
        return
    fi
    
    if tmux has-session -t "$new_name" 2>/dev/null; then
        echo -e "${RED}Session '$new_name' already exists${NC}"
        sleep 2
        return
    fi
    
    tmux rename-session -t "$old_name" "$new_name"
    echo -e "${GREEN}✓ Session renamed from '$old_name' to '$new_name'${NC}"
    sleep 1
}

# Display a random tmux tip organized by category
show_random_tip() {
    # SESSION MANAGEMENT TIPS
    local session_tips=(
        "🔷 Sessions: Detach from session with ${CYAN}Ctrl+b${NC} then ${CYAN}d${NC}"
        "🔷 Sessions: List all sessions with ${CYAN}Ctrl+b${NC} then ${CYAN}s${NC}"
        "🔷 Sessions: Independent workspaces that persist after terminal closes"
        "🔷 Sessions: Rename session with ${CYAN}Ctrl+b${NC} then ${CYAN}\$${NC}"
        "🔷 Sessions: Create named session with ${CYAN}tmux new -s <name>${NC}"
        "🔷 Sessions: Switch between sessions with ${CYAN}Ctrl+b${NC} then ${CYAN}(${NC}/${CYAN})${NC}"
        "🔷 Sessions: Last active session with ${CYAN}Ctrl+b${NC} then ${CYAN}L${NC}"
        "🔷 Sessions: Attach to last session with ${CYAN}tmux a${NC}"
    )
    
    # WINDOW MANAGEMENT TIPS
    local window_tips=(
        "🪟 Windows: Create new window with ${CYAN}Ctrl+b${NC} then ${CYAN}c${NC}"
        "🪟 Windows: Switch windows with ${CYAN}Ctrl+b${NC} then ${CYAN}0-9${NC} or ${CYAN}n${NC}/${CYAN}p${NC}"
        "🪟 Windows: Rename current window with ${CYAN}Ctrl+b${NC} then ${CYAN},${NC}"
        "🪟 Windows: Kill current window with ${CYAN}Ctrl+b${NC} then ${CYAN}&${NC}"
        "🪟 Windows: Windows are tabs within a session"
        "🪟 Windows: Find window by name with ${CYAN}Ctrl+b${NC} then ${CYAN}f${NC}"
        "🪟 Windows: Last active window with ${CYAN}Ctrl+b${NC} then ${CYAN}l${NC}"
        "🪟 Windows: Move window to another session with ${CYAN}:move-window -t target${NC}"
        "🪟 Windows: Reorder window with ${CYAN}:move-window -t <index>${NC}"
        "🪟 Windows: List all windows with ${CYAN}Ctrl+b${NC} then ${CYAN}w${NC}"
    )
    
    # PANE MANAGEMENT TIPS
    local pane_tips=(
        "📐 Panes: Create horizontal split with ${CYAN}Ctrl+b${NC} then ${CYAN}\"${NC}"
        "📐 Panes: Create vertical split with ${CYAN}Ctrl+b${NC} then ${CYAN}%${NC}"
        "📐 Panes: Navigate between panes with ${CYAN}Ctrl+b${NC} then arrow keys"
        "📐 Panes: Zoom/unzoom pane with ${CYAN}Ctrl+b${NC} then ${CYAN}z${NC}"
        "📐 Panes: Close current pane with ${CYAN}Ctrl+b${NC} then ${CYAN}x${NC}"
        "📐 Panes: Toggle pane layouts with ${CYAN}Ctrl+b${NC} then ${CYAN}Space${NC}"
        "📐 Panes: Show pane numbers with ${CYAN}Ctrl+b${NC} then ${CYAN}q${NC}"
        "📐 Panes: Resize panes with ${CYAN}Ctrl+b${NC} then ${CYAN}Ctrl+arrow${NC}"
        "📐 Panes: Panes are subdivisions of windows"
        "📐 Panes: Swap panes with ${CYAN}Ctrl+b${NC} then ${CYAN}o${NC}"
        "📐 Panes: Break pane into window with ${CYAN}Ctrl+b${NC} then ${CYAN}!${NC}"
        "📐 Panes: Join pane from another window with ${CYAN}:join-pane -s <src>${NC}"
        "📐 Panes: Rotate panes with ${CYAN}Ctrl+b${NC} then ${CYAN}Ctrl+o${NC}"
        "📐 Panes: Toggle pane/window fullscreen with ${CYAN}Ctrl+b${NC} then ${CYAN}z${NC}"
    )
    
    # COPY MODE & SCROLLING TIPS
    local copy_tips=(
        "📋 Copy Mode: Enter copy mode with ${CYAN}Ctrl+b${NC} then ${CYAN}[${NC}"
        "📋 Copy Mode: Navigate with arrow keys, page up/down in copy mode"
        "📋 Copy Mode: Start selection with ${CYAN}Space${NC}, copy with ${CYAN}Enter${NC}"
        "📋 Copy Mode: Paste buffer with ${CYAN}Ctrl+b${NC} then ${CYAN}]${NC}"
        "📋 Copy Mode: Search up with ${CYAN}?${NC}, search down with ${CYAN}/${NC}"
        "📋 Copy Mode: Exit copy mode with ${CYAN}q${NC} or ${CYAN}Esc${NC}"
        "📋 Copy Mode: List paste buffers with ${CYAN}Ctrl+b${NC} then ${CYAN}=#${NC}"
        "📋 Copy Mode: Enable mouse scrolling with ${CYAN}:set -g mouse on${NC}"
    )
    
    # CONFIGURATION & CUSTOMIZATION TIPS
    local config_tips=(
        "⚙️ Config: Display key bindings with ${CYAN}Ctrl+b${NC} then ${CYAN}?${NC}"
        "⚙️ Config: Reload config file with ${CYAN}Ctrl+b${NC} then ${CYAN}:source ~/.tmux.conf${NC}"
        "⚙️ Config: Enable mouse support with ${CYAN}set -g mouse on${NC}"
        "⚙️ Config: Change prefix key from Ctrl+b to Ctrl+a in ${CYAN}~/.tmux.conf${NC}"
        "⚙️ Config: Set pane border colors with ${CYAN}set -g pane-border-style${NC}"
        "⚙️ Config: Customize status bar in ${CYAN}~/.tmux.conf${NC}"
        "⚙️ Config: Start window numbering at 1: ${CYAN}set -g base-index 1${NC}"
        "⚙️ Config: Enable vi keys with ${CYAN}setw -g mode-keys vi${NC}"
    )
    
    # PRODUCTIVITY & ADVANCED TIPS
    local productivity_tips=(
        "⚡ Pro: Synchronize panes with ${CYAN}:setw synchronize-panes${NC}"
        "⚡ Pro: Show clock in pane with ${CYAN}Ctrl+b${NC} then ${CYAN}t${NC}"
        "⚡ Pro: Choose session from tree view with ${CYAN}Ctrl+b${NC} then ${CYAN}s${NC}"
        "⚡ Pro: Command prompt with ${CYAN}Ctrl+b${NC} then ${CYAN}:${NC}"
        "⚡ Pro: Mark pane with ${CYAN}Ctrl+b${NC} then ${CYAN}m${NC}, unmark with ${CYAN}M${NC}"
        "⚡ Pro: Respawn pane (restart) with ${CYAN}Ctrl+b${NC} then ${CYAN}:respawn-pane${NC}"
        "⚡ Pro: Pipe pane output to file with ${CYAN}:pipe-pane -o 'cat >>output.txt'${NC}"
        "⚡ Pro: Create session in background with ${CYAN}tmux new -d -s <name>${NC}"
        "⚡ Pro: Run command in new window with ${CYAN}tmux neww 'command'${NC}"
        "⚡ Pro: Send keys to pane with ${CYAN}tmux send-keys -t <target> 'command' Enter${NC}"
    )
    
    # KEY CONCEPTS TIPS
    local concept_tips=(
        "💭 Concept: Hierarchy is Session > Window > Pane"
        "💭 Concept: Tmux server manages all sessions independently"
        "💭 Concept: Prefix key (Ctrl+b) activates tmux commands"
        "💭 Concept: Sessions survive SSH disconnections and terminal crashes"
        "💭 Concept: Multiple clients can attach to same session"
        "💭 Concept: Pane layouts: even-horizontal, even-vertical, main-horizontal, main-vertical, tiled"
        "💭 Concept: Status bar shows windows, active pane, and session info"
    )
    
    # Combine all tips
    local all_tips=(
        "${session_tips[@]}"
        "${window_tips[@]}"
        "${pane_tips[@]}"
        "${copy_tips[@]}"
        "${config_tips[@]}"
        "${productivity_tips[@]}"
        "${concept_tips[@]}"
    )
    
    # Select a random tip
    local random_index=$((RANDOM % ${#all_tips[@]}))
    echo -e "${YELLOW}${all_tips[$random_index]}${NC}"
}

# Draw menu options
draw_menu_options() {
    local selected=$1
    local has_sessions=$2
    local options=(
        "[c] Create new session"
        "[a] Attach to session"
        "[r] Rename session"
        "[k] Kill session"
        "[x] Kill all sessions"
        "[f] Refresh"
        "[q] Quit"
    )
    local hints=(
        "tmux new-session -s <name>"
        "tmux attach-session -t <name>"
        "tmux rename-session -t <old> <new>"
        "tmux kill-session -t <name>"
        "tmux kill-server"
        "Reload session list"
        "Exit this manager"
    )
    local colors=(
        "$GREEN"
        "$BLUE"
        "$YELLOW"
        "$RED"
        "$RED"
        "$CYAN"
        "$MAGENTA"
    )
    # Options that require active sessions (indices 1-4)
    local requires_session=(0 1 1 1 1 0 0)
    
    # Dimmed gray for hints and disabled options
    local DIM='\033[2;37m'
    local DISABLED='\033[0;90m'
    
    echo -e "${BOLD}Options:${NC} ${CYAN}(Use ↑/↓ arrows and Enter, or press the key shortcut)${NC}"
    echo ""
    
    for i in "${!options[@]}"; do
        # Check if option is disabled
        local is_disabled=0
        if [ ${requires_session[$i]} -eq 1 ] && [ $has_sessions -eq 0 ]; then
            is_disabled=1
        fi
        
        if [ $is_disabled -eq 1 ]; then
            # Disabled option - show in grey
            printf "    ${DISABLED}%-25s %s${NC}\n" "${options[$i]}" "(no active sessions)"
        elif [ $i -eq $selected ]; then
            # Highlight selected option
            printf "  ${BOLD}${colors[$i]}► %-25s${NC} ${DIM}%s${NC}\n" "${options[$i]}" "${hints[$i]}"
        else
            printf "    %-25s ${DIM}%s${NC}\n" "${options[$i]}" "${hints[$i]}"
        fi
    done
    echo ""
    
    # Display a random tip at the bottom
    echo -e "${CYAN}────────────────────────────────────────────────────────────${NC}"
    show_random_tip
    echo ""
}

# Main menu with arrow key navigation
show_menu() {
    local selected=0
    local num_options=7
    local redraw=true
    
    while true; do
        # Only redraw if needed
        if [ "$redraw" = true ]; then
            show_header
            list_sessions
            
            # Check if there are active sessions
            local has_sessions=0
            if tmux list-sessions &>/dev/null; then
                has_sessions=1
            fi
            
            draw_menu_options $selected $has_sessions
            redraw=false
        fi
        
        # Read a single character
        read -rsn1 key
        
        # Handle arrow keys (escape sequences)
        if [[ $key == $'\x1b' ]]; then
            read -rsn2 key
            case $key in
                '[A') # Up arrow
                    ((selected--))
                    if [ $selected -lt 0 ]; then
                        selected=$((num_options - 1))
                    fi
                    redraw=true
                    ;;
                '[B') # Down arrow
                    ((selected++))
                    if [ $selected -ge $num_options ]; then
                        selected=0
                    fi
                    redraw=true
                    ;;
            esac
        elif [[ $key == "" ]]; then
            # Enter key pressed
            case $selected in
                0) create_session ; redraw=true ;;
                1) 
                    if [ $has_sessions -eq 1 ]; then
                        attach_session ; redraw=true
                    fi
                    ;;
                2) 
                    if [ $has_sessions -eq 1 ]; then
                        rename_session ; redraw=true
                    fi
                    ;;
                3) 
                    if [ $has_sessions -eq 1 ]; then
                        kill_session ; redraw=true
                    fi
                    ;;
                4) 
                    if [ $has_sessions -eq 1 ]; then
                        kill_all_sessions ; redraw=true
                    fi
                    ;;
                5) return ;;
                6) exit 0 ;;
            esac
        elif [[ $key == "q" ]] || [[ $key == "Q" ]]; then
            # Quick quit with 'q' key
            exit 0
        elif [[ $key =~ ^[1-7]$ ]]; then
            # Allow direct number selection
            selected=$((key - 1))
            case $selected in
                0) create_session ; redraw=true ;;
                1) 
                    if [ $has_sessions -eq 1 ]; then
                        attach_session ; redraw=true
                    fi
                    ;;
                2) 
                    if [ $has_sessions -eq 1 ]; then
                        rename_session ; redraw=true
                    fi
                    ;;
                3) 
                    if [ $has_sessions -eq 1 ]; then
                        kill_session ; redraw=true
                    fi
                    ;;
                4) 
                    if [ $has_sessions -eq 1 ]; then
                        kill_all_sessions ; redraw=true
                    fi
                    ;;
                5) return ;;
                6) exit 0 ;;
            esac
        elif [[ $key == "c" ]] || [[ $key == "C" ]]; then
            # Create session
            create_session
            redraw=true
        elif [[ $key == "a" ]] || [[ $key == "A" ]]; then
            # Attach to session
            if [ $has_sessions -eq 1 ]; then
                attach_session
                redraw=true
            fi
        elif [[ $key == "r" ]] || [[ $key == "R" ]]; then
            # Rename session
            if [ $has_sessions -eq 1 ]; then
                rename_session
                redraw=true
            fi
        elif [[ $key == "k" ]] || [[ $key == "K" ]]; then
            # Kill session
            if [ $has_sessions -eq 1 ]; then
                kill_session
                redraw=true
            fi
        elif [[ $key == "x" ]] || [[ $key == "X" ]]; then
            # Kill all sessions
            if [ $has_sessions -eq 1 ]; then
                kill_all_sessions
                redraw=true
            fi
        elif [[ $key == "f" ]] || [[ $key == "F" ]]; then
            # Refresh
            return
        fi
    done
}

# Main program
main() {
    check_tmux
    
    # Main loop
    while true; do
        show_menu
    done
}

# Run the program
main
