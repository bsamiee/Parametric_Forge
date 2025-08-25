# Title         : shell_integration.zsh
# Author        : Bardia Samiee
# Project       : Parametric Forge
# License       : MIT
# Path          : configs/darwin/iterm2/shell_integration.zsh
# ----------------------------------------------------------------------------
# iTerm2 shell integration for zsh (macOS)

# This file provides iTerm2 shell integration features:
# - Shell prompt marks for navigation
# - Command status reporting
# - Current directory reporting
# - Shell integration utilities

# Only load if running in iTerm2
if [[ "$TERM_PROGRAM" == "iTerm.app" ]]; then
    
    # iTerm2 shell integration functions
    iterm2_print_state_data() {
        printf "\033]1337;RemoteHost=%s@%s\007" "$USER" "$HOSTNAME"
        printf "\033]1337;CurrentDir=%s\007" "$PWD"
    }
    
    iterm2_prompt_mark() {
        printf "\033]133;A\007"
    }
    
    iterm2_prompt_end() {
        printf "\033]133;B\007"
    }
    
    iterm2_preexec() {
        printf "\033]133;C;\007"
    }
    
    iterm2_precmd() {
        local STATUS="$?"
        if [ $STATUS -ne 0 ]; then
            printf "\033]133;D;%s\007" $STATUS
        else
            printf "\033]133;D;0\007"
        fi
        iterm2_print_state_data
    }
    
    # Set up hooks
    autoload -Uz add-zsh-hook
    add-zsh-hook precmd iterm2_precmd
    add-zsh-hook preexec iterm2_preexec
    
    # Modify prompt to include marks
    if [[ -z "$ITERM2_PROMPT_MARK_SET" ]]; then
        export ITERM2_PROMPT_MARK_SET=1
        
        # Add prompt mark to PS1
        if [[ -n "$PS1" ]]; then
            PS1="%{$(iterm2_prompt_mark)%}$PS1%{$(iterm2_prompt_end)%}"
        fi
    fi
    
    # iTerm2 utilities
    it2attention() {
        printf "\033]1337;RequestAttention=1\007"
    }
    
    it2copy() {
        if [[ $# -eq 0 ]]; then
            cat | base64 | printf "\033]1337;Copy=:%s\007" "$(cat)"
        else
            printf "%s" "$*" | base64 | printf "\033]1337;Copy=:%s\007" "$(cat)"
        fi
    }
    
    it2paste() {
        printf "\033]1337;Paste\007"
    }
    
    it2setcolor() {
        case $1 in
            tab)
                printf "\033]6;1;bg;red;brightness;%s\007\033]6;1;bg;green;brightness;%s\007\033]6;1;bg;blue;brightness;%s\007" "$2" "$3" "$4"
                ;;
            *)
                echo "Usage: it2setcolor tab <red> <green> <blue>"
                echo "Values should be between 0-255"
                ;;
        esac
    }
    
    it2badge() {
        printf "\033]1337;SetBadgeFormat=%s\007" "$(echo -n "$1" | base64)"
    }
    
    it2profile() {
        if [[ $# -eq 0 ]]; then
            printf "\033]1337;ReportProfile\007"
        else
            printf "\033]1337;SetProfile=%s\007" "$1"
        fi
    }
    
    # Directory navigation integration
    it2cd() {
        cd "$@" && iterm2_print_state_data
    }
    
    # Aliases for convenience
    alias imgcat='printf "\033]1337;File=inline=1:%s\007" "$(base64 < "$1")"'
    alias imgls='for f in *.{jpg,jpeg,png,gif,bmp,tiff,webp}; do [[ -f "$f" ]] && echo "$f" && imgcat "$f"; done'
    
    # Set initial state
    iterm2_print_state_data
    
    # iTerm2 specific key bindings
    bindkey '^[[1;9C' forward-word      # Option+Right
    bindkey '^[[1;9D' backward-word     # Option+Left
    bindkey '^[[1;5C' forward-word      # Ctrl+Right
    bindkey '^[[1;5D' backward-word     # Ctrl+Left
    
    # iTerm2 specific environment variables
    export ITERM_ENABLE_SHELL_INTEGRATION_WITH_TMUX=YES
    export ITERM2_SHOULD_DECORATE_PROMPT="1"
    
    # Status line integration
    it2status() {
        if [[ $# -eq 0 ]]; then
            printf "\033]1337;SetUserVar=status=\007"
        else
            printf "\033]1337;SetUserVar=status=%s\007" "$(echo -n "$1" | base64)"
        fi
    }
    
    # Git integration
    it2git() {
        if git rev-parse --git-dir > /dev/null 2>&1; then
            local branch=$(git branch --show-current 2>/dev/null)
            local status=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
            it2badge "⎇ $branch ($status)"
        else
            it2badge ""
        fi
    }
    
    # Auto-update git status in badge
    if command -v git >/dev/null 2>&1; then
        add-zsh-hook precmd it2git
    fi
    
    # Session restoration
    it2save() {
        local session_file="${HOME}/.iterm2_session_$(date +%Y%m%d_%H%M%S).txt"
        printf "\033]1337;StealFocus\007"
        printf "\033]1337;CopyToClipboard\007"
        echo "Session saved to: $session_file"
        echo "Current directory: $PWD" > "$session_file"
        echo "Current command: $BUFFER" >> "$session_file"
        history -10 >> "$session_file"
    }
    
    # Notification integration
    it2notify() {
        local message="${1:-Command completed}"
        local title="${2:-iTerm2}"
        printf "\033]9;%s\007" "$message"
        if command -v terminal-notifier >/dev/null 2>&1; then
            terminal-notifier -message "$message" -title "$title"
        fi
    }
    
    # Long-running command notification
    it2watch() {
        local start_time=$(date +%s)
        "$@"
        local exit_code=$?
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        
        if [[ $duration -gt 10 ]]; then
            if [[ $exit_code -eq 0 ]]; then
                it2notify "Command completed successfully (${duration}s)" "iTerm2"
            else
                it2notify "Command failed with exit code $exit_code (${duration}s)" "iTerm2"
            fi
        fi
        
        return $exit_code
    }
    
    echo "iTerm2 shell integration loaded"
fi