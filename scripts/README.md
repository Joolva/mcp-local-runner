# MCP Server Manager

A bash script to manage multiple MCP (Model Context Protocol) servers running in Docker containers.

## Quick Overview

![MCP Manager Overview](../overview-diagram.svg)

This repository provides a CLI tool to run and manage MCP servers in sandboxed Docker containers.

## Features

- ✅ List all registered MCP servers with their status
- ✅ Start/stop servers by name or index number
- ✅ View real-time logs
- ✅ Check server status
- ✅ Restart servers
- ✅ Color-coded output for better visibility
- ✅ Tab completion support

## Installation

### Step 1: Make the script executable

```bash
chmod +x /mnt/c/Users/joakim.valand/projects/mcp/scripts/mcp-manager.sh
```

### Step 2: Add to your shell config

**For ZSH (most common in WSL/Ubuntu):**

```bash
cat /mnt/c/Users/joakim.valand/projects/mcp/scripts/shell-snippet.sh >> ~/.zshrc
```

**For BASH:**

```bash
cat /mnt/c/Users/joakim.valand/projects/mcp/scripts/shell-snippet.sh >> ~/.bashrc
```

**Not sure which shell?** Check with: `echo $SHELL`

### Step 3: Update the path (if needed)

If your MCP project is in a different location, edit the `MCP_SCRIPT_PATH` variable in your shell config file:

```bash
export MCP_SCRIPT_PATH="/path/to/your/mcp/scripts/mcp-manager.sh"
```

### Step 4: Reload your shell config

**For ZSH:**
```bash
source ~/.zshrc
```

**For BASH:**
```bash
source ~/.bashrc
```

## Configuration

Edit `scripts/mcp-servers.conf` to register your MCP servers.

Format: `name|directory|port`

```
# Example:
mermaid|mermaid|3033
myserver|myserver|3034
```

- **name**: Unique identifier for the server
- **directory**: Relative path from the `mcp/` base directory
- **port**: Localhost port where the server is accessible

## Usage

### Show help

```bash
mcp --help
```

### List all servers

```bash
mcp --list
# or
mcp -l
```

Example output:
```
[1] mermaid
    Directory: mermaid
    Port: 3033
    Status: running

[2] another-server
    Directory: another-server
    Port: 3034
    Status: stopped
```

### Start a server

By name:
```bash
mcp run mermaid
```

By index:
```bash
mcp run 1
```

### Stop a server

By name:
```bash
mcp stop mermaid
```

By index:
```bash
mcp stop 1
```

### Restart a server

```bash
mcp restart mermaid
mcp restart 1
```

### Check status

```bash
mcp status mermaid
mcp status 1
```

### View logs

```bash
mcp logs mermaid
mcp logs 1
```

Press `Ctrl+C` to exit logs view.

## Commands Summary

| Command | Description | Example |
|---------|-------------|---------|
| `--help`, `-h` | Show help message | `mcp --help` |
| `--list`, `-l` | List all servers | `mcp -l` |
| `run <name\|index>` | Start a server | `mcp run mermaid` |
| `stop <name\|index>` | Stop a server | `mcp stop 1` |
| `restart <name\|index>` | Restart a server | `mcp restart mermaid` |
| `status <name\|index>` | Check server status | `mcp status 1` |
| `logs <name\|index>` | View server logs | `mcp logs mermaid` |

## Adding New Servers

1. Create a new directory with a `docker-compose.yml` file in the `mcp/` folder
2. Add an entry to `scripts/mcp-servers.conf`:
   ```
   myserver|myserver|3035
   ```
3. Run `mcp -l` to verify it's registered

## Troubleshooting

### "Script not found" error

Make sure the path in your shell config is correct:
```bash
echo $MCP_SCRIPT_PATH
ls -la $MCP_SCRIPT_PATH
```

### Server won't start

Check Docker is running:
```bash
sudo docker ps
```

View detailed logs:
```bash
cd /mnt/c/Users/joakim.valand/projects/mcp/mermaid
sudo docker compose logs
```

### Permission denied

Make the script executable:
```bash
chmod +x /mnt/c/Users/joakim.valand/projects/mcp/scripts/mcp-manager.sh
```

## WSL Path Note

In WSL, Windows paths are mounted under `/mnt/`. For example:
- Windows: `C:\Users\joakim.valand\projects\mcp`
- WSL: `/mnt/c/Users/joakim.valand/projects/mcp`

The script automatically handles path conversions.

## Tab Completion

Tab completion is automatically enabled after installation. Try:

```bash
mcp <TAB>
```

This will show available commands: `--help -h --list -l run stop restart status logs`
