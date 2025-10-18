import { query } from "@anthropic-ai/claude-agent-sdk";
import fs from "fs/promises";
import path from "path";
import { fileURLToPath } from "url";
import dotenv from "dotenv";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Load environment variables from .env file
dotenv.config({ path: path.join(__dirname, ".env") });

// Configuration
const MEDUSA_MCP_URL = process.env.MEDUSA_MCP_URL || "http://localhost:9000/mcp/mcp";
const ANTHROPIC_API_KEY = process.env.ANTHROPIC_API_KEY;

if (!ANTHROPIC_API_KEY) {
  console.error("Error: ANTHROPIC_API_KEY environment variable is required");
  process.exit(1);
}

// Main function
async function main() {
  try {
    console.log("🛒 Shopping Agent Starting...\n");

    // Load shopping list
    const shoppingListPath = path.join(__dirname, "initial_products.json");
    const shoppingListContent = await fs.readFile(shoppingListPath, "utf-8");
    const shoppingList = JSON.parse(shoppingListContent);

    console.log("📋 Shopping List:");
    console.log(JSON.stringify(shoppingList, null, 2));
    console.log();

    // Create the system prompt
    const systemPrompt = {
      type: "preset",
      preset: "claude_code",
      append: `

You are a shopping agent that helps place orders on a Medusa e-commerce store using the MCP tools available.

Your task:
1. Search for available products in the store using list_products tool
2. Match requested items from the shopping list to available products
3. Use fuzzy matching if exact match not found (e.g., "oranges" → "apples", "pork" → "beef")
4. Create a cart using create_cart tool (first get a region_id using list_regions)
5. Add matching products to the cart using add_to_cart tool
6. Create an order using create_order tool with the following customer information:

Customer Information:
- Email: customer@example.com
- Name: John Doe
- Address: 123 Main St, New York, NY 10001, US
- Phone: +1234567890

Matching rules:
- Try to find exact product name matches first
- If no exact match, look for similar products in the same category
- Prefer available products over missing ones
- Use the quantities specified in the shopping list

Be thorough and complete the entire order process step by step.`,
    };

    // Create the initial prompt
    const initialPrompt = `Please create an order for the following shopping list:

${JSON.stringify(shoppingList, null, 2)}

Use the available MCP tools from the "medusa" server to complete this task. Work through it step by step:
1. First, list regions to get a region_id
2. Then, list products to see what's available
3. Match the shopping list items to available products
4. Create a cart with the region_id
5. Add the matched items to the cart
6. Complete the order with the customer information provided

Please proceed with these steps now.`;

    console.log("🚀 Starting agent with MCP server integration...\n");

    // Configure the agent to use the Medusa MCP server
    const options = {
      systemPrompt,
      mcpServers: {
        medusa: {
          type: "http",
          url: MEDUSA_MCP_URL,
        },
      },
      permissionMode: "bypassPermissions", // Auto-approve all tool uses for automation
      maxTurns: 20, // Maximum number of conversation turns
    };

    // Run the agent
    const stream = query({
      prompt: initialPrompt,
      options,
    });

    // Process the stream of messages
    let lastResult = null;
    for await (const message of stream) {
      if (message.type === "system" && message.subtype === "init") {
        console.log("✅ Agent initialized");
        console.log(`   Model: ${message.model}`);
        console.log(`   Tools: ${message.tools.length} available`);
        console.log(`   MCP Servers: ${message.mcp_servers.map((s) => s.name).join(", ")}`);
        console.log();
      } else if (message.type === "assistant") {
        // Process assistant messages
        for (const content of message.message.content) {
          if (content.type === "text") {
            console.log(`💬 Claude: ${content.text.substring(0, 200)}${content.text.length > 200 ? "..." : ""}`);
          } else if (content.type === "tool_use") {
            console.log(`\n🔧 Using tool: ${content.name}`);
            console.log(`   Input: ${JSON.stringify(content.input).substring(0, 150)}...`);
          }
        }
      } else if (message.type === "user") {
        // Tool results
        for (const content of message.message.content) {
          if (content.type === "tool_result") {
            const resultText = typeof content.content === "string" ? content.content : JSON.stringify(content.content);
            console.log(`   ✅ Result: ${resultText.substring(0, 150)}${resultText.length > 150 ? "..." : ""}`);
          }
        }
      } else if (message.type === "result") {
        lastResult = message;
        console.log("\n" + "=".repeat(60));
        console.log("🎉 Agent completed!");
        console.log("=".repeat(60));

        if (message.subtype === "success") {
          console.log(`\n📝 Final Result:\n${message.result}`);
          console.log(`\n📊 Statistics:`);
          console.log(`   Turns: ${message.num_turns}`);
          console.log(`   Duration: ${(message.duration_ms / 1000).toFixed(2)}s`);
          console.log(`   Cost: $${message.total_cost_usd.toFixed(4)}`);
          console.log(`   Input tokens: ${message.usage.input_tokens}`);
          console.log(`   Output tokens: ${message.usage.output_tokens}`);
          if (message.usage.cache_read_input_tokens) {
            console.log(`   Cache read tokens: ${message.usage.cache_read_input_tokens}`);
          }
        } else if (message.subtype === "error_max_turns") {
          console.log("\n⚠️  Reached maximum turns");
          console.log(`   Turns: ${message.num_turns}`);
        } else {
          console.log("\n❌ Error during execution");
        }

        if (message.permission_denials && message.permission_denials.length > 0) {
          console.log(`\n⚠️  Permission denials: ${message.permission_denials.length}`);
        }
      }
    }

    console.log("\n✨ Shopping agent finished!");

  } catch (error) {
    console.error("\n❌ Fatal error:", error);
    process.exit(1);
  }
}

// Run the agent
main();
