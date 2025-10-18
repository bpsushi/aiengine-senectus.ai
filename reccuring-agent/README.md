# Recurring Shopping Agent

An intelligent shopping agent built with Anthropic's Claude Agent SDK that reads a shopping list and automatically places orders on a Medusa e-commerce store using the MCP (Model Context Protocol) server.

## Features

- 🤖 Built with official **Anthropic Claude Agent SDK**
- 🛒 Reads shopping list from `initial_products.json`
- 🔍 Smart product matching with fuzzy logic
- 📦 Automatically creates cart and places orders via Medusa MCP server
- 🔄 Substitutes similar products when exact matches aren't available (e.g., oranges → apples, pork → beef)
- ⚡ Leverages Claude Code's powerful tool ecosystem
- 🎯 Automatic context management and prompt caching

## Prerequisites

1. Running Medusa store with MCP server enabled (default: http://localhost:9000)
2. Anthropic API key

## Setup

1. Install dependencies:
```bash
cd reccuring-agent
npm install
```

2. Configure environment variables:

**Option A: Using .env file (Recommended)**
```bash
# Copy the example file
cp .env.example .env

# Edit .env and add your API key
# ANTHROPIC_API_KEY=your-anthropic-api-key
# MEDUSA_MCP_URL=http://localhost:9000/mcp/mcp
```

**Option B: Using export**
```bash
export ANTHROPIC_API_KEY="your-anthropic-api-key"
export MEDUSA_MCP_URL="http://localhost:9000/mcp/mcp"  # optional, defaults to this
```

3. Edit `initial_products.json` with your desired shopping list:
```json
[
  { "name": "tomatoes", "quantity": 4 },
  { "name": "oranges", "quantity": 6 },
  { "name": "pork", "quantity": 2 }
]
```

## Usage

Run the agent:
```bash
npm start
```

The agent will:
1. Load the shopping list from `initial_products.json`
2. Connect to the Medusa MCP server via HTTP
3. List available products in the store
4. Match requested products to available inventory (with smart substitutions)
5. Create a shopping cart
6. Add matched products to the cart
7. Complete the order with default shipping information

## How It Works

The agent uses Anthropic's Claude Agent SDK which provides:

- **Automatic Context Management**: Handles prompt caching and context optimization
- **Rich Tool Ecosystem**: Access to Claude Code's built-in tools plus MCP extensions
- **Production-Ready Features**: Built-in error handling, session management, and monitoring
- **MCP Integration**: Seamless connection to external tools via Model Context Protocol

### Agent Architecture

```
Shopping Agent (agent.js)
    ↓
Claude Agent SDK (query function)
    ↓
Claude Code System Prompt + Custom Instructions
    ↓
MCP Server (Medusa HTTP)
    ↓
Medusa Store (Products, Cart, Orders)
```

### MCP Tools Available

The agent has access to these Medusa MCP tools:
- `list_products` - Browse product catalog
- `get_product` - Get detailed product information
- `list_regions` - Get available regions
- `create_cart` - Create shopping cart
- `add_to_cart` - Add items to cart
- `create_order` - Complete order

## Configuration

### Default Customer Information

The agent uses these default values (can be modified in `agent.js`):
- Email: customer@example.com
- Name: John Doe
- Address: 123 Main St, New York, NY 10001, US
- Phone: +1234567890

### Agent Options

The agent is configured with:
- `systemPrompt`: Uses Claude Code preset + custom shopping instructions
- `mcpServers`: HTTP connection to Medusa MCP server
- `permissionMode`: "bypassPermissions" for full automation
- `maxTurns`: 20 conversation turns maximum

## Example Output

```
🛒 Shopping Agent Starting...

�� Shopping List:
[
  { "name": "tomatoes", "quantity": 4 },
  { "name": "oranges", "quantity": 6 },
  { "name": "pork", "quantity": 2 }
]

🚀 Starting agent with MCP server integration...

✅ Agent initialized
   Model: claude-3-5-sonnet-20241022
   Tools: 15 available
   MCP Servers: medusa

💬 Claude: I'll help you place an order for these items...

🔧 Using tool: list_regions
   ✅ Result: {"regions":[{"id":"reg_01...","name":"US",...}]}

🔧 Using tool: list_products
   ✅ Result: {"products":[...],"count":10}

... (continues with cart creation, adding items, placing order)

============================================================
🎉 Agent completed!
============================================================

📝 Final Result:
I've successfully created an order with the following items:
- Tomatoes (4)
- Apples (6) - substituted for oranges
- Beef (2) - substituted for pork

Order ID: order_01JXXX...

📊 Statistics:
   Turns: 8
   Duration: 12.34s
   Cost: $0.0245
   Input tokens: 1234
   Output tokens: 567
   Cache read tokens: 890

✨ Shopping agent finished!
```

## Advanced Usage

### Custom System Prompt

Modify the `systemPrompt` in `agent.js` to change agent behavior:

```javascript
const systemPrompt = {
  type: "preset",
  preset: "claude_code",
  append: `Your custom instructions here...`,
};
```

### Different MCP Transport

The agent supports any MCP transport type:

```javascript
// HTTP (default)
mcpServers: {
  medusa: { type: "http", url: "http://localhost:9000/mcp/mcp" }
}

// SSE (deprecated but supported)
mcpServers: {
  medusa: { type: "sse", url: "http://localhost:9000/mcp/sse" }
}

// Stdio (for local processes)
mcpServers: {
  medusa: { type: "stdio", command: "medusa-mcp-server" }
}
```

## Why Claude Agent SDK?

The Agent SDK provides:

1. **Production-Ready**: Built on the same harness that powers Claude Code
2. **Automatic Optimization**: Prompt caching and context management
3. **Rich Tooling**: Access to Claude Code's full tool ecosystem
4. **MCP Native**: First-class support for Model Context Protocol
5. **Best Practices**: Error handling, permissions, and monitoring built-in

## Troubleshooting

**"Failed to connect to MCP server"**
- Ensure Medusa is running: check http://localhost:9000
- Verify MCP endpoint: `curl http://localhost:9000/mcp/mcp`

**"ANTHROPIC_API_KEY environment variable is required"**
- Set your API key: `export ANTHROPIC_API_KEY="sk-ant-..."`

**"No products found"**
- Ensure your Medusa store has products seeded
- Check with: `./test-mcp.sh`

**Agent reaches max turns**
- Increase `maxTurns` in options
- Simplify shopping list
- Check Medusa server responses

## Resources

- [Anthropic Agent SDK Documentation](https://docs.claude.com/en/api/agent-sdk/overview)
- [Model Context Protocol](https://modelcontextprotocol.io/)
- [Medusa Documentation](https://docs.medusajs.com/)

## License

MIT
