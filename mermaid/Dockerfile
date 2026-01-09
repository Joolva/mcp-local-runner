# Use official Node.js LTS Debian image (full version with git/tools pre-installed)
FROM node:20

# Set working directory
WORKDIR /app

# Set environment variable to use the installed Chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD=false \
    PLAYWRIGHT_SKIP_BROWSER_DOWNLOAD=0

# Clone the mcp-mermaid repository
RUN git clone https://github.com/hustcc/mcp-mermaid.git /tmp/mcp-mermaid && \
    mv /tmp/mcp-mermaid/* /app/ && \
    rm -rf /tmp/mcp-mermaid

# Install dependencies with Playwright browsers (postinstall will run)
RUN npm install

# Run the build
RUN npm run build

# Create a non-root user for security
RUN groupadd -g 1001 mcpuser && \
    useradd -r -u 1001 -g mcpuser mcpuser

# Copy Playwright browsers from root cache to user cache
RUN mkdir -p /home/mcpuser/.cache && \
    cp -r /root/.cache/ms-playwright /home/mcpuser/.cache/ && \
    chown -R mcpuser:mcpuser /home/mcpuser/.cache

# Change ownership of the app directory
RUN chown -R mcpuser:mcpuser /app

# Switch to non-root user
USER mcpuser

# Expose the default MCP port
EXPOSE 3033

# Set environment to bind to all interfaces
ENV HOST=0.0.0.0

# Default command - Streamable transport on port 3033 with /mcp endpoint
CMD ["node", "build/index.js", "--transport", "streamable", "--port", "3033", "--endpoint", "/mcp"]
