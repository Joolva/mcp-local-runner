# MCP Mermaid Docker Setup

This is a sandboxed Docker setup for running the [mcp-mermaid](https://github.com/hustcc/mcp-mermaid) MCP server.

## Security Features

✅ **Complete Isolation**: Container runs with:
- Network isolation (bridge mode, only exposed port accessible)
- No host filesystem access (read-only root filesystem)
- Non-root user execution
- `no-new-privileges` security option
- Resource limits (CPU and memory)
- Temporary filesystems only in `/tmp` and `.cache`

✅ **Controlled Access**: 
- Only port 3033 is exposed to localhost
- No arbitrary internet access from container
- No access to your computer's files or resources

## Quick Start

### 1. Build and start the container:
```bash
sudo docker compose up -d
```

### 2. Check if it's running:
```bash
sudo docker compose ps
sudo docker compose logs
```

### 3. Access the MCP server:
The server is available at: `http://localhost:3033/sse`

### 4. Stop the container:
```bash
sudo docker compose down
```

## Usage

### Start the service:
```bash
sudo docker compose up -d
```

### View logs:
```bash
sudo docker compose logs -f
```

### Stop the service:
```bash
sudo docker compose stop
```

### Restart the service:
```bash
sudo docker compose restart
```

### Remove the container:
```bash
sudo docker compose down
```

### Rebuild after changes:
```bash
sudo docker compose down
sudo docker compose build --no-cache
sudo docker compose up -d
```

## Configuration

To change the port, edit the `docker-compose.yml` file and modify:
- The `ports` section: `"YOUR_PORT:3033"`
- The `PORT` environment variable (if you want to change internal port too)

## MCP Server Details

- **Transport**: SSE (Server-Sent Events)
- **Endpoint**: `/sse`
- **Port**: 3033 (localhost only)
- **Default URL**: `http://localhost:3033/sse`

## Connecting to MCP Clients

Add this configuration to your MCP client (e.g., Claude Desktop, VS Code):

```json
{
  "mcpServers": {
    "mcp-mermaid": {
      "transport": "sse",
      "url": "http://localhost:3033/sse"
    }
  }
}
```

## Health Check

Check if the service is healthy:
```bash
sudo docker compose exec mcp-mermaid wget -O- http://localhost:3033/sse
```

Or check the health status:
```bash
sudo docker inspect mcp-mermaid-server --format='{{.State.Health.Status}}'
```
