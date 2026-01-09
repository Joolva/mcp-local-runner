#!/bin/bash
# MCP Server Manager - Shell Configuration Snippet
# 
# Add this to your shell RC file (~/.bashrc or ~/.zshrc) to enable the 'mcp' command
# 
# Installation:
# 1. Copy this entire section to the end of your shell RC file
# 2. Update MCP_SCRIPT_PATH to point to your mcp-manager.sh location
# 3. Run: source ~/.bashrc (or source ~/.zshrc)
#
# Or run this one-liner to append automatically:
# Bash: cat /path/to/shell-snippet.sh >> ~/.bashrc && source ~/.bashrc
# Zsh:  cat /path/to/shell-snippet.sh >> ~/.zshrc && source ~/.zshrc

# ========== MCP Server Manager ==========

# Set the path to your mcp-manager.sh script
# Update this path to match your installation
export MCP_SCRIPT_PATH="/mnt/c/Users/joakim.valand/projects/mcp/scripts/mcp-manager.sh"

# MCP command function
mcp() {
    if [[ -f "$MCP_SCRIPT_PATH" ]]; then
        bash "$MCP_SCRIPT_PATH" "$@"
    else
        echo "Error: MCP manager script not found at: $MCP_SCRIPT_PATH"
        echo "Please update MCP_SCRIPT_PATH in your shell RC file (~/.bashrc or ~/.zshrc)"
        return 1
    fi
}

# Optional: Add tab completion for mcp commands (zsh style)
_mcp_zsh_completion() {
    local -a commands
    commands=(
        '--help:Show help message'
        '-h:Show help message'
        '--list:List all servers'
        '-l:List all servers'
        'run:Start a server'
        'stop:Stop a server'
        'restart:Restart a server'
        'status:Check server status'
        'logs:View server logs'
    )
    _describe 'mcp command' commands
}

compdef _mcp_zsh_completion mcp

# ========== End MCP Server Manager ==========
