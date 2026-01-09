#!/bin/bash

# MCP Server Manager Script
# Manages multiple MCP servers with start/stop functionality

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_FILE="${SCRIPT_DIR}/mcp-servers.conf"
MCP_BASE_DIR="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to show help
show_help() {
    echo -e "${BLUE}MCP Server Manager${NC}"
    echo ""
    echo "Usage: mcp <command> [options]"
    echo ""
    echo "Commands:"
    echo "  -l, --list [-c|--config]  List all registered MCP servers"
    echo "                            Add -c or --config for VS Code JSON format"
    echo "  -h, --help                Show this help message"
    echo "  run <name|index>        Start an MCP server"
    echo "  stop <name|index>       Stop an MCP server"
    echo "  restart <name|index>    Restart an MCP server"
    echo "  status <name|index>     Check status of an MCP server"
    echo "  logs <name|index>       View logs of an MCP server"
    echo "  config <name|index>     Print VS Code connection config"
    echo "  <name|index> --config   Print VS Code connection config (alternative)"
    echo ""
    echo "Examples:"
    echo "  mcp -l                  # List all servers (short form)"
    echo "  mcp --list              # List all servers (long form)"
    echo "  mcp -l -c               # List all servers as VS Code JSON config"
    echo "  mcp -l --config         # Same as above (long form)"
    echo "  mcp run mermaid         # Start mermaid server by name"
    echo "  mcp run 1               # Start server at index 1"
    echo "  mcp stop mermaid        # Stop mermaid server"
    echo "  mcp logs 1              # View logs for server 1"
    echo "  mcp config 1            # Print VS Code config for server 1"
    echo "  mcp 1 --config          # Same as above (alternative syntax)"
    echo ""
}

# Function to read servers from config file
read_servers() {
    local servers=()
    if [[ ! -f "$CONFIG_FILE" ]]; then
        echo -e "${RED}Error: Config file not found: $CONFIG_FILE${NC}" >&2
        return 1
    fi
    
    while IFS= read -r line; do
        # Skip comments, empty lines, and lines with only whitespace
        [[ "$line" =~ ^[[:space:]]*# || -z "${line// }" ]] && continue
        # Skip lines that don't have the pipe separator
        [[ ! "$line" =~ \| ]] && continue
        servers+=("$line")
    done < "$CONFIG_FILE"
    
    # Print each server on a new line for safer parsing
    printf '%s\n' "${servers[@]}"
}

# Function to parse a server entry
parse_server_entry() {
    local entry="$1"
    IFS='|' read -r name dir port <<< "$entry"
    echo "$name|$dir|$port"
}

# Function to list all servers
list_servers() {
    echo -e "${BLUE}Registered MCP Servers:${NC}"
    echo ""
    
    local servers=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && servers+=("$line")
    done < <(read_servers)
    
    if [[ ${#servers[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No servers registered${NC}"
        return
    fi
    
    local index=1
    for server in "${servers[@]}"; do
        IFS='|' read -r name dir port endpoint type <<< "$server"
        endpoint="${endpoint:-/mcp}"
        type="${type:-http}"
        local status=$(check_container_status "$dir")
        local status_color="${RED}"
        [[ "$status" == "running" ]] && status_color="${GREEN}"
        
        echo -e "${YELLOW}[$index]${NC} ${BLUE}$name${NC}"
        echo -e "    Directory: $dir"
        echo -e "    Port: ${GREEN}$port${NC}"
        echo -e "    Endpoint: $endpoint"
        echo -e "    Type: $type"
        echo -e "    URL: ${GREEN}http://localhost:$port$endpoint${NC}"
        echo -e "    Status: ${status_color}${status}${NC}"
        echo ""
        ((index++))
    done
}

# Function to list all servers as VS Code JSON config
list_servers_json() {
    local servers=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && servers+=("$line")
    done < <(read_servers)
    
    if [[ ${#servers[@]} -eq 0 ]]; then
        echo -e "${YELLOW}No servers registered${NC}"
        return
    fi
    
    echo '{'
    echo '    "servers": {'
    
    local index=1
    local total=${#servers[@]}
    for server in "${servers[@]}"; do
        IFS='|' read -r name dir port endpoint type <<< "$server"
        endpoint="${endpoint:-/mcp}"
        type="${type:-http}"
        
        echo -n '        "'"$name"'": {'
        echo ''
        echo '            "url": "http://localhost:'"$port$endpoint"'",'
        echo -n '            "type": "'"$type"'"'
        echo ''
        echo -n '        }'
        
        # Add comma if not the last item
        if [[ $index -lt $total ]]; then
            echo ','
        else
            echo ''
        fi
        
        ((index++))
    done
    
    echo '    }'
    echo '}'
}

# Function to print VS Code connection config
print_vscode_config() {
    local server_entry="$1"
    IFS='|' read -r name dir port endpoint type <<< "$server_entry"
    
    # Default endpoint to /mcp if not specified
    endpoint="${endpoint:-/mcp}"
    # Default type to http if not specified
    type="${type:-http}"
    
    echo ""
    echo -e "${BLUE}VS Code Connection Config:${NC}"
    echo '"'"$name"'": {'
    echo '    "url": "http://localhost:'"$port$endpoint"'",'
    echo '    "type": "'"$type"'"'
    echo '}'
}

# Function to get server by name or index
get_server() {
    local identifier="$1"
    local servers=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && servers+=("$line")
    done < <(read_servers)
    
    # Check if identifier is a number (index)
    if [[ "$identifier" =~ ^[0-9]+$ ]]; then
        local index=$((identifier - 1))
        if [[ $index -ge 0 && $index -lt ${#servers[@]} ]]; then
            echo "${servers[$index]}"
            return 0
        else
            echo -e "${RED}Error: Invalid index $identifier${NC}" >&2
            return 1
        fi
    else
        # Search by name
        for server in "${servers[@]}"; do
            IFS='|' read -r name dir port endpoint type <<< "$server"
            if [[ "$name" == "$identifier" ]]; then
                echo "$server"
                return 0
            fi
        done
        echo -e "${RED}Error: Server '$identifier' not found${NC}" >&2
        return 1
    fi
}

# Function to check container status
check_container_status() {
    local dir="$1"
    local full_path="${MCP_BASE_DIR}/${dir}"
    
    if [[ ! -d "$full_path" ]]; then
        echo "not found"
        return
    fi
    
    cd "$full_path" || return
    local status=$(sudo docker compose ps -q 2>/dev/null)
    
    if [[ -z "$status" ]]; then
        echo "stopped"
    else
        local running=$(sudo docker inspect -f '{{.State.Running}}' $(sudo docker compose ps -q) 2>/dev/null)
        if [[ "$running" == "true" ]]; then
            echo "running"
        else
            echo "stopped"
        fi
    fi
}

# Function to run a server
run_server() {
    local identifier="$1"
    local server=$(get_server "$identifier")
    [[ $? -ne 0 ]] && return 1
    
    IFS='|' read -r name dir port endpoint type <<< "$server"
    endpoint="${endpoint:-/mcp}"
    type="${type:-http}"
    local full_path="${MCP_BASE_DIR}/${dir}"
    
    echo -e "${BLUE}Starting MCP server: ${GREEN}$name${NC}"
    echo -e "Directory: $full_path"
    echo -e "Port: ${GREEN}$port${NC}"
    echo ""
    
    if [[ ! -d "$full_path" ]]; then
        echo -e "${RED}Error: Directory not found: $full_path${NC}"
        return 1
    fi
    
    cd "$full_path" || return 1
    
    # Check if already running
    local status=$(check_container_status "$dir")
    if [[ "$status" == "running" ]]; then
        echo -e "${YELLOW}Server is already running${NC}"
        echo -e "Access at: ${GREEN}http://localhost:$port$endpoint${NC}"
        print_vscode_config "$server"
        return 0
    fi
    
    echo -e "${BLUE}Building and starting container...${NC}"
    sudo docker compose up -d
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✓ Server started successfully${NC}"
        echo -e "Access at: ${GREEN}http://localhost:$port$endpoint${NC}"
        print_vscode_config "$server"
    else
        echo -e "${RED}✗ Failed to start server${NC}"
        return 1
    fi
}

# Function to stop a server
stop_server() {
    local identifier="$1"
    local server=$(get_server "$identifier")
    [[ $? -ne 0 ]] && return 1
    
    IFS='|' read -r name dir port <<< "$server"
    local full_path="${MCP_BASE_DIR}/${dir}"
    
    echo -e "${BLUE}Stopping MCP server: ${YELLOW}$name${NC}"
    
    if [[ ! -d "$full_path" ]]; then
        echo -e "${RED}Error: Directory not found: $full_path${NC}"
        return 1
    fi
    
    cd "$full_path" || return 1
    
    # Check if running
    local status=$(check_container_status "$dir")
    if [[ "$status" != "running" ]]; then
        echo -e "${YELLOW}Server is not running${NC}"
        return 0
    fi
    
    sudo docker compose down
    
    if [[ $? -eq 0 ]]; then
        echo -e "${GREEN}✓ Server stopped successfully${NC}"
    else
        echo -e "${RED}✗ Failed to stop server${NC}"
        return 1
    fi
}

# Function to restart a server
restart_server() {
    local identifier="$1"
    echo -e "${BLUE}Restarting server...${NC}"
    stop_server "$identifier"
    sleep 2
    run_server "$identifier"
}

# Function to check status
status_server() {
    local identifier="$1"
    local server=$(get_server "$identifier")
    [[ $? -ne 0 ]] && return 1
    
    IFS='|' read -r name dir port <<< "$server"
    local full_path="${MCP_BASE_DIR}/${dir}"
    
    echo -e "${BLUE}Status for: ${GREEN}$name${NC}"
    
    cd "$full_path" || return 1
    sudo docker compose ps
}

# Function to view logs
logs_server() {
    local identifier="$1"
    local server=$(get_server "$identifier")
    [[ $? -ne 0 ]] && return 1
    
    IFS='|' read -r name dir port endpoint type <<< "$server"
    local full_path="${MCP_BASE_DIR}/${dir}"
    
    echo -e "${BLUE}Logs for: ${GREEN}$name${NC}"
    echo -e "Press Ctrl+C to exit"
    echo ""
    
    cd "$full_path" || return 1
    sudo docker compose logs -f
}

# Function to show config only
show_config() {
    local identifier="$1"
    local server=$(get_server "$identifier")
    [[ $? -ne 0 ]] && return 1
    
    IFS='|' read -r name dir port endpoint type <<< "$server"
    endpoint="${endpoint:-/mcp}"
    type="${type:-http}"
    local status=$(check_container_status "$dir")
    local status_color="${RED}"
    [[ "$status" == "running" ]] && status_color="${GREEN}"
    
    echo -e "${YELLOW}Server:${NC} ${BLUE}$name${NC}"
    echo -e "${YELLOW}Status:${NC} ${status_color}${status}${NC}"
    echo -e "${YELLOW}URL:${NC} ${GREEN}http://localhost:$port$endpoint${NC}"
    print_vscode_config "$server"
}

# Main command handler
main() {
    if [[ $# -eq 0 ]]; then
        show_help
        return 0
    fi
    
    case "$1" in
        --help|-h)
            show_help
            ;;
        --list|-l)
            if [[ "$2" == "--config" || "$2" == "-c" ]]; then
                list_servers_json
            else
                list_servers
            fi
            ;;
        run)
            if [[ -z "$2" ]]; then
                echo -e "${RED}Error: Please specify a server name or index${NC}"
                echo "Usage: mcp run <name|index>"
                return 1
            fi
            run_server "$2"
            ;;
        stop)
            if [[ -z "$2" ]]; then
                echo -e "${RED}Error: Please specify a server name or index${NC}"
                echo "Usage: mcp stop <name|index>"
                return 1
            fi
            stop_server "$2"
            ;;
        restart)
            if [[ -z "$2" ]]; then
                echo -e "${RED}Error: Please specify a server name or index${NC}"
                echo "Usage: mcp restart <name|index>"
                return 1
            fi
            restart_server "$2"
            ;;
        status)
            if [[ -z "$2" ]]; then
                echo -e "${RED}Error: Please specify a server name or index${NC}"
                echo "Usage: mcp status <name|index>"
                return 1
            fi
            status_server "$2"
            ;;
        logs)
            if [[ -z "$2" ]]; then
                echo -e "${RED}Error: Please specify a server name or index${NC}"
                echo "Usage: mcp logs <name|index>"
                return 1
            fi
            logs_server "$2"
            ;;
        config)
            if [[ -z "$2" ]]; then
                echo -e "${RED}Error: Please specify a server name or index${NC}"
                echo "Usage: mcp config <name|index>"
                return 1
            fi
            show_config "$2"
            ;;
        --config)
            echo -e "${RED}Error: Use 'mcp <name|index> --config' or 'mcp config <name|index>' instead${NC}"
            return 1
            ;;
        *)
            # Check if second argument is --config (e.g., mcp 1 --config)
            if [[ "$2" == "--config" ]]; then
                show_config "$1"
            else
                echo -e "${RED}Error: Unknown command '$1'${NC}"
                echo ""
                show_help
                return 1
            fi
            ;;
    esac
}

# Run main function with all arguments
main "$@"
