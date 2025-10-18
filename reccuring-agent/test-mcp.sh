#!/bin/bash

# Quick test to verify MCP server is accessible
echo "🔍 Testing MCP Server Connection..."
echo ""

MCP_URL="${MEDUSA_MCP_URL:-http://localhost:9000/mcp/mcp}"

echo "Testing endpoint: $MCP_URL"
echo ""

# Test tools/list
echo "📋 Fetching available tools..."
RESPONSE=$(curl -s -X POST "$MCP_URL" \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/list"
  }')

# Extract JSON from SSE format
JSON=$(echo "$RESPONSE" | grep "^data: " | sed 's/^data: //' || echo "$RESPONSE")

if [ -z "$JSON" ]; then
  echo "❌ Failed to connect to MCP server"
  echo "   Make sure Medusa is running at $MCP_URL"
  exit 1
fi

# Count tools
TOOL_COUNT=$(echo "$JSON" | jq -r '.result.tools | length' 2>/dev/null)

if [ "$TOOL_COUNT" -gt 0 ]; then
  echo "✅ Successfully connected to MCP server"
  echo "   Found $TOOL_COUNT tools available"
  echo ""
  echo "Available tools:"
  echo "$JSON" | jq -r '.result.tools[] | "  - \(.name): \(.title)"'
  echo ""
  echo "🎉 MCP server is ready!"
  echo ""
  echo "To run the agent:"
  echo "  export ANTHROPIC_API_KEY='your-key-here'"
  echo "  npm start"
else
  echo "❌ MCP server responded but no tools found"
  echo "   Response:"
  echo "$JSON" | jq '.'
  exit 1
fi
