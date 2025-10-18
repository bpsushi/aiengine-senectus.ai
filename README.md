# MCP E-commerce Integration & AI Shopping Agent

A comprehensive integration of **Model Context Protocol (MCP)** with a Medusa e-commerce store, featuring an intelligent shopping agent built with Anthropic's Claude Agent SDK. This project demonstrates how AI agents can autonomously interact with e-commerce systems through standardized protocols.

Reccuring agent is designed to run as repeatable job to make reccuring orders.

## 🌟 Overview

This project consists of two main components:

1. **MCP Server** - A fully-featured Model Context Protocol server integrated with Medusa, exposing e-commerce operations as MCP tools
2. **Recurring Shopping Agent** - An autonomous AI agent that reads shopping lists and automatically places orders using the MCP server

## 📋 Table of Contents

- [Features](#features)
- [Architecture](#architecture)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Running the Project](#running-the-project)
- [MCP Server](#mcp-server)
- [Recurring Shopping Agent](#recurring-shopping-agent)
- [Testing](#testing)
- [API Documentation](#api-documentation)
- [Troubleshooting](#troubleshooting)

## ✨ Features

### MCP Server Features
- ✅ **Product Management** - List, search, and retrieve product details
- 🛒 **Cart Operations** - Create, retrieve, and manage shopping carts
- 📦 **Order Processing** - Complete order workflow with customer information
- 🌍 **Multi-region Support** - Handle different regions and currencies
- 🔧 **RESTful HTTP Interface** - JSON-RPC 2.0 compliant MCP server
- 🎯 **Type-safe Schema** - Built with Zod validation

### Shopping Agent Features
- 🤖 **Autonomous Operation** - Fully automated order placement
- 🧠 **Smart Product Matching** - Fuzzy logic for product substitutions
- 📝 **JSON-based Shopping Lists** - Simple configuration format
- 🔄 **Intelligent Substitutions** - Automatically finds alternatives when products unavailable
- ⚡ **Claude Agent SDK Integration** - Leverages Anthropic's official agent framework
- 🎯 **Context-aware Decisions** - Uses Claude Code's tool ecosystem

## 🏗 Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    Recurring Shopping Agent                  │
│                    (Claude Agent SDK)                        │
└────────────────────────┬────────────────────────────────────┘
                         │ HTTP (JSON-RPC 2.0)
                         │
┌────────────────────────▼────────────────────────────────────┐
│                      MCP Server                              │
│              (Model Context Protocol)                        │
│                                                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │  MCP Tools:                                          │  │
│  │  • list_products    • create_cart                    │  │
│  │  • get_product      • get_cart                       │  │
│  │  • list_regions     • list_user_carts                │  │
│  │  • add_to_cart      • update_cart_item               │  │
│  │  • create_order                                      │  │
│  └──────────────────────────────────────────────────────┘  │
└────────────────────────┬────────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────────┐
│                   Medusa E-commerce Store                    │
│                   (Backend API & Database)                   │
└──────────────────────────────────────────────────────────────┘
```

## 📦 Prerequisites

- **Node.js** >= 18.0.0
- **PostgreSQL** >= 15
- **Docker & Docker Compose** (optional, for database)
- **Anthropic API Key** (for the shopping agent)

## 🚀 Installation

### 1. Clone and Setup

```bash
# Clone the repository
git clone <repository-url>

# Install MCP Server dependencies
cd my-medusa-store
npm install

# Install Shopping Agent dependencies
cd ../reccuring-agent
npm install
```

### 2. Database Setup

**Option A: Using Docker (Recommended)**

```bash
# Start PostgreSQL with Docker Compose
docker-compose up -d

# This creates a PostgreSQL instance:
# - Host: localhost:5432
# - Database: aiengine
# - User: aiengine
# - Password: aiengine
```

**Option B: Using existing PostgreSQL**

Update your `.env` file with your database credentials.

### 3. Environment Configuration

#### MCP Server Configuration

Create `.env` file in `my-medusa-store/`:

```bash
# Database
DATABASE_URL=postgres://aiengine:aiengine@localhost:5432/aiengine

# Server
PORT=9000
MEDUSA_ADMIN_ONBOARDING_TYPE=default

# Optional: JWT Secret
JWT_SECRET=your-secret-key
COOKIE_SECRET=your-cookie-secret
```

#### Shopping Agent Configuration

Create `.env` file in `reccuring-agent/`:

```bash
# Anthropic API Key (Required)
ANTHROPIC_API_KEY=your-anthropic-api-key-here

# MCP Server URL (Optional, defaults to below)
MEDUSA_MCP_URL=http://localhost:9000/mcp/mcp
```

### 4. Initialize Database

```bash
cd my-medusa-store

# Run migrations
npm run build

# Seed with sample data (optional)
npm run seed
```

## 🎮 Running the Project

### Start the MCP Server

```bash
cd my-medusa-store

# Development mode (with hot reload)
npm run dev

# Production mode
npm run build
npm start
```

The MCP server will be available at: `http://localhost:9000`

MCP endpoint: `http://localhost:9000/mcp/mcp`

### Start the Shopping Agent

```bash
cd reccuring-agent

# 1. Configure your shopping list in initial_products.json
cat > initial_products.json << 'EOF'
[
  { "name": "tomatoes", "quantity": 4 },
  { "name": "apples", "quantity": 6 },
  { "name": "chicken", "quantity": 2 }
]
EOF

# 2. Run the agent
npm start
```

The agent will:
1. Connect to the MCP server
2. List available products
3. Match items from your shopping list
4. Create a cart
5. Add items to the cart
6. Complete the order automatically

## 🔧 MCP Server

### Available MCP Tools

#### Product Tools

**`list_products`**
- Browse the product catalog with pagination
- Parameters: `limit` (optional), `offset` (optional)

**`get_product`**
- Get detailed information about a specific product
- Parameters: `id` (required)

#### Region Tools

**`list_regions`**
- List available regions for cart creation
- Parameters: `limit` (optional)

#### Cart Management Tools

**`create_cart`**
- Create a new shopping cart
- Parameters: `region_id` (required), `email` (optional), `customer_id` (optional), `items` (optional)

**`get_cart`**
- Retrieve cart details including items and totals
- Parameters: `id` (required)

**`list_user_carts`**
- List all carts for a specific user
- Parameters: `customer_id` (optional), `email` (optional), `limit` (optional), `offset` (optional)

**`add_to_cart`**
- Add product variants to an existing cart
- Parameters: `cart_id` (required), `items` (array, required)

**`update_cart_item`**
- Update the quantity of a line item (set to 0 to remove)
- Parameters: `cart_id` (required), `item_id` (required), `quantity` (required)

#### Order Tools

**`create_order`**
- Create an order from a cart
- Parameters: `cart_id` (required), `email` (optional), `shipping_address` (optional), `billing_address` (optional)

### MCP Server Implementation

The MCP server is implemented in:
```
my-medusa-store/src/api/mcp/[transport]/route.ts
```

It uses the `medusa-mcp-adapter` package to bridge Medusa's workflow system with the Model Context Protocol.

### HTTP Transport

The server uses HTTP transport with JSON-RPC 2.0:

```bash
# Example: List products
curl -X POST http://localhost:9000/mcp/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/call",
    "params": {
      "name": "list_products",
      "arguments": {
        "limit": 10
      }
    }
  }'
```

## 🤖 Recurring Shopping Agent

### How It Works

The agent uses **Anthropic's Claude Agent SDK** which provides:

- ✅ Automatic context management and prompt caching
- ✅ Rich tool ecosystem with Claude Code integration
- ✅ Production-ready error handling and session management
- ✅ Native MCP protocol support

### Agent Workflow

1. **Load Shopping List** - Reads `initial_products.json`
2. **Connect to MCP** - Establishes HTTP connection to Medusa MCP server
3. **Product Discovery** - Uses `list_products` tool to see inventory
4. **Smart Matching** - Matches requested items with fuzzy logic
5. **Region Selection** - Uses `list_regions` to get region ID
6. **Cart Creation** - Uses `create_cart` tool
7. **Add Items** - Uses `add_to_cart` for matched products
8. **Order Completion** - Uses `create_order` with customer details

### Product Matching Logic

The agent can intelligently substitute products:
- Exact matches preferred
- Category-based substitutions (e.g., oranges → apples)
- Type substitutions (e.g., pork → beef)
- Available products prioritized

### Shopping List Format

`initial_products.json`:
```json
[
  {
    "name": "product-name",
    "quantity": 2
  },
  {
    "name": "another-product",
    "quantity": 5
  }
]
```

### Agent Configuration

The agent is configured in `reccuring-agent/agent.js`:

```javascript
const options = {
  systemPrompt: {
    type: "preset",
    preset: "claude_code",
    append: "Custom instructions..."
  },
  mcpServers: {
    medusa: {
      type: "http",
      url: MEDUSA_MCP_URL
    }
  },
  permissionMode: "bypassPermissions", // Auto-approve tools
  maxTurns: 20 // Maximum conversation turns
};
```

## 🧪 Testing

### Test MCP Server

A comprehensive test script is provided:

```bash
cd my-medusa-store
./test-cart-mcp.sh
```

This script tests:
- Listing available MCP tools
- Listing regions
- Listing products
- Creating a cart
- Adding items to cart
- Updating cart items
- Creating an order

### Manual Testing

You can also test individual tools using curl:

```bash
# List all available tools
curl -X POST http://localhost:9000/mcp/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/list"
  }'

# Get product details
curl -X POST http://localhost:9000/mcp/mcp \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "list_products",
      "arguments": {
        "limit": 5
      }
    }
  }'
```

## 📚 API Documentation

### JSON-RPC 2.0 Format

All MCP requests follow JSON-RPC 2.0 specification:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "tools/call",
  "params": {
    "name": "tool_name",
    "arguments": {
      "param1": "value1"
    }
  }
}
```

### Response Format

Successful responses:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "{\"data\": \"...\"}"
      }
    ]
  }
}
```

Error responses:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "result": {
    "content": [
      {
        "type": "text",
        "text": "Error message"
      }
    ],
    "isError": true
  }
}
```

## 🔍 Troubleshooting

### MCP Server Issues

**Database connection failed**
```bash
# Check if PostgreSQL is running
docker ps

# Restart database
docker-compose restart

# Check connection
psql -h localhost -U aiengine -d aiengine
```

**Port already in use**
```bash
# Change port in .env
PORT=9001

# Or find and kill process
lsof -ti:9000 | xargs kill -9
```

**Missing migrations**
```bash
cd my-medusa-store
npm run build
```

### Shopping Agent Issues

**Missing API key**
```bash
# Verify environment variable
echo $ANTHROPIC_API_KEY

# Or check .env file
cat reccuring-agent/.env
```

**Connection refused**
```bash
# Make sure MCP server is running
curl http://localhost:9000/health

# Check MCP endpoint
curl -X POST http://localhost:9000/mcp/mcp \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/list"}'
```

**Agent not finding products**
```bash
# Seed the database with sample products
cd my-medusa-store
npm run seed
```

## 📁 Project Structure

```
medusa-app/
├── my-medusa-store/              # MCP Server & Medusa Backend
│   ├── src/
│   │   └── api/
│   │       └── mcp/
│   │           └── [transport]/
│   │               └── route.ts  # MCP server implementation
│   ├── test-cart-mcp.sh          # Test script
│   └── package.json
│
├── reccuring-agent/              # AI Shopping Agent
│   ├── agent.js                  # Main agent logic
│   ├── initial_products.json     # Shopping list
│   ├── .env                      # Configuration
│   └── package.json
│
├── docker-compose.yml            # PostgreSQL setup
└── README.md                     # This file
```

## 🤝 Contributing

This is a demonstration project showcasing MCP integration with e-commerce systems. Feel free to:

- Add new MCP tools
- Enhance the agent's intelligence
- Improve error handling
- Add more sophisticated product matching logic

## 📄 License

MIT

## 🙏 Acknowledgments

- **Anthropic** - Claude Agent SDK
- **Medusa** - E-commerce platform
- **Model Context Protocol** - Standardized AI-application integration

## 📞 Support

For issues specific to:
- **MCP Server**: Check `my-medusa-store/src/api/mcp/[transport]/route.ts`
- **Shopping Agent**: Check `reccuring-agent/agent.js`
- **Database**: Check `docker-compose.yml` and connection settings

---

Built with ❤️ using Model Context Protocol and Claude Agent SDK
