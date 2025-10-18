# Quick Start Guide - Anthropic Agent SDK

## Prerequisites
- ✅ Medusa store running on http://localhost:9000
- ✅ Anthropic API key

## Setup (1 minute)

```bash
# 1. Navigate to agent directory
cd reccuring-agent

# 2. Dependencies already installed
# (If not: npm install)

# 3. Set your Anthropic API key
export ANTHROPIC_API_KEY="sk-ant-your-key-here"

# 4. Test MCP connection (optional)
./test-mcp.sh

# 5. Run the agent!
npm start
```

## What Happens

The **Anthropic Agent SDK** powers the agent with:

1. 🎯 **Claude Code System Prompt** - Professional agent capabilities
2. 🔧 **MCP Integration** - Direct HTTP connection to Medusa
3. ⚡ **Automatic Caching** - Optimized performance
4. 📊 **Built-in Monitoring** - Token usage and cost tracking
5. 🛡️ **Production Features** - Error handling and permissions

## Agent Workflow

```
1. Load shopping list → initial_products.json
2. Initialize Agent SDK → Connect to MCP server
3. Claude analyzes task → Plans tool calls
4. Execute MCP tools → list_regions, list_products, create_cart, etc.
5. Complete order → Return results with statistics
```

## Customize Shopping List

Edit `initial_products.json`:

```json
[
  { "name": "apples", "quantity": 5 },
  { "name": "bread", "quantity": 2 },
  { "name": "milk", "quantity": 1 }
]
```

## Agent SDK Benefits

✨ **Automatic Features:**
- Context management and compaction
- Prompt caching for efficiency
- Session management
- Error recovery
- Token tracking

🔧 **MCP Native:**
- HTTP/SSE/Stdio transports
- Tool discovery
- Permission handling
- Multiple servers support

## Example Output

```
🛒 Shopping Agent Starting...

📋 Shopping List:
[
  { "name": "tomatoes", "quantity": 4 },
  { "name": "oranges", "quantity": 6 }
]

🚀 Starting agent with MCP server integration...

✅ Agent initialized
   Model: claude-3-5-sonnet-20241022
   Tools: 15 available
   MCP Servers: medusa

💬 Claude: I'll help you place an order...

🔧 Using tool: list_regions
   ✅ Result: {"regions":[...]}

🔧 Using tool: list_products
   ✅ Result: {"products":[...]}

�� Using tool: create_cart
   ✅ Result: {"cart_id":"cart_01..."}

🔧 Using tool: add_to_cart
   ✅ Result: {"message":"Items added successfully"}

🔧 Using tool: create_order
   ✅ Result: {"order_id":"order_01..."}

============================================================
🎉 Agent completed!
============================================================

📝 Final Result:
Order placed successfully!
- Tomatoes x4
- Apples x6 (substituted for oranges)

Order ID: order_01JXXX...

📊 Statistics:
   Turns: 6
   Duration: 8.45s
   Cost: $0.0156
   Input tokens: 892
   Output tokens: 423
   Cache read tokens: 1245

✨ Shopping agent finished!
```

## Troubleshooting

**MCP Connection Failed**
```bash
# Check Medusa is running
curl http://localhost:9000/mcp/mcp

# Test with script
./test-mcp.sh
```

**API Key Issues**
```bash
# Verify key is set
echo $ANTHROPIC_API_KEY

# Should start with sk-ant-
```

**No Products**
```bash
# Seed Medusa database
cd ../my-medusa-store
npm run seed
```

## Advanced Configuration

### Custom Agent Behavior

Edit `agent.js` to customize:

```javascript
const options = {
  systemPrompt: { /* custom prompt */ },
  mcpServers: { /* MCP config */ },
  permissionMode: "bypassPermissions",
  maxTurns: 20,
  model: "claude-3-5-sonnet-20241022", // Change model
};
```

### Multiple MCP Servers

```javascript
mcpServers: {
  medusa: {
    type: "http",
    url: "http://localhost:9000/mcp/mcp"
  },
  inventory: {
    type: "http",
    url: "http://localhost:8000/mcp"
  }
}
```

## Files Overview

- `agent.js` - **Main agent using Claude Agent SDK**
- `initial_products.json` - Shopping list
- `package.json` - Dependencies (@anthropic-ai/claude-agent-sdk)
- `test-mcp.sh` - Test MCP connection
- `README.md` - Full documentation
- `IMPLEMENTATION.md` - Technical details

## Resources

📚 **Documentation:**
- [Anthropic Agent SDK](https://docs.claude.com/en/api/agent-sdk/overview)
- [TypeScript SDK Reference](https://docs.claude.com/en/api/agent-sdk/typescript)
- [Model Context Protocol](https://modelcontextprotocol.io/)

🎓 **Learn More:**
- [MCP Server Guide](https://docs.claude.com/en/docs/claude-code/mcp)
- [Agent SDK Examples](https://github.com/anthropics/claude-agent-sdk-typescript)

## Next Steps

1. ✅ Run the agent: `npm start`
2. 🔧 Customize shopping list
3. 🎨 Modify agent prompt
4. 🚀 Deploy to production

**Ready to shop? Just run `npm start`!** 🛒
