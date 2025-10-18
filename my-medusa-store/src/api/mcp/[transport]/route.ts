import {
  ContainerRegistrationKeys,
  Modules,
} from "@medusajs/framework/utils";
import {
  createCartWorkflow,
  addToCartWorkflow,
  updateLineItemInCartWorkflow,
  createOrderWorkflow,
} from "@medusajs/medusa/core-flows";
import { createMedusaMcpHandler } from "medusa-mcp-adapter";
import { z } from "zod";

// Create the MCP handler with tool registrations
const handler = createMedusaMcpHandler(
  async (container, server) => {
    // Resolve the query service once for all tools
    const query = container.resolve(ContainerRegistrationKeys.QUERY);

    // ===================================
    // PRODUCT TOOLS
    // ===================================

    server.registerTool(
      "list_products",
      {
        title: "List Products",
        description: "Browse the product catalog with pagination",
        inputSchema: {
          limit: z.number().optional().describe("Number of products to return (default: 20)"),
          offset: z.number().optional().describe("Number of products to skip (default: 0)"),
        },
      },
      async ({ limit, offset }) => {
        try {
          const { data: products } = await query.graph({
            entity: "product",
            fields: [
              "id",
              "title",
              "description",
              "handle",
              "status",
              "created_at",
              "updated_at",
            ],
            pagination: {
              skip: offset || 0,
              take: limit || 20,
            },
          });

          return {
            content: [
              {
                type: "text",
                text: JSON.stringify(
                  {
                    products,
                    count: products.length,
                    limit: limit || 20,
                    offset: offset || 0,
                  },
                  null,
                  2
                ),
              },
            ],
          };
        } catch (error: any) {
          return {
            content: [
              {
                type: "text",
                text: `Error listing products: ${error.message}`,
              },
            ],
            isError: true,
          };
        }
      }
    );

    server.registerTool(
      "get_product",
      {
        title: "Get Product Details",
        description: "Get detailed information about a single product",
        inputSchema: {
          id: z.string().describe("Product ID"),
        },
      },
      async ({ id }) => {
        try {
          const { data: products } = await query.graph({
            entity: "product",
            fields: [
              "id",
              "title",
              "description",
              "handle",
              "status",
              "variants.*",
              "options.*",
              "images.*",
              "tags.*",
              "categories.*",
            ],
            filters: {
              id,
            },
          });

          if (!products || products.length === 0) {
            return {
              content: [
                {
                  type: "text",
                  text: `Product not found with ID: ${id}`,
                },
              ],
              isError: true,
            };
          }

          return {
            content: [
              {
                type: "text",
                text: JSON.stringify(products[0], null, 2),
              },
            ],
          };
        } catch (error: any) {
          return {
            content: [
              {
                type: "text",
                text: `Error retrieving product: ${error.message}`,
              },
            ],
            isError: true,
          };
        }
      }
    );

    // ===================================
    // REGION TOOLS (Helper for Cart Creation)
    // ===================================

    server.registerTool(
      "list_regions",
      {
        title: "List Regions",
        description: "List available regions for cart creation",
        inputSchema: {
          limit: z.number().optional().describe("Number of regions to return (default: 20)"),
        },
      },
      async ({ limit }) => {
        try {
          const { data: regions } = await query.graph({
            entity: "region",
            fields: ["id", "name", "currency_code", "countries.*"],
            pagination: {
              take: limit || 20,
            },
          });

          return {
            content: [
              {
                type: "text",
                text: JSON.stringify(
                  {
                    regions,
                    count: regions.length,
                  },
                  null,
                  2
                ),
              },
            ],
          };
        } catch (error: any) {
          return {
            content: [
              {
                type: "text",
                text: `Error listing regions: ${error.message}`,
              },
            ],
            isError: true,
          };
        }
      }
    );

    // ===================================
    // CART MANAGEMENT TOOLS
    // ===================================

    server.registerTool(
      "create_cart",
      {
        title: "Create Cart",
        description: "Create a new shopping cart with optional items",
        inputSchema: {
          region_id: z.string().describe("Region ID (use list_regions to find available regions)"),
          email: z.string().email().optional().describe("Customer email address"),
          customer_id: z.string().optional().describe("Customer ID if logged in"),
          items: z.array(
            z.object({
              variant_id: z.string().describe("Product variant ID"),
              quantity: z.number().int().positive().describe("Quantity"),
            })
          ).optional().describe("Initial items to add to cart"),
        },
      },
      async ({ region_id, email, customer_id, items }) => {
        try {
          const { result: cart } = await createCartWorkflow(container).run({
            input: {
              region_id,
              currency_code: "usd", // This will be overridden by region's currency
              email,
              customer_id,
              items: items || [],
            },
          });

          return {
            content: [
              {
                type: "text",
                text: JSON.stringify(
                  {
                    message: "Cart created successfully",
                    cart_id: cart.id,
                    cart,
                  },
                  null,
                  2
                ),
              },
            ],
          };
        } catch (error: any) {
          return {
            content: [
              {
                type: "text",
                text: `Error creating cart: ${error.message}`,
              },
            ],
            isError: true,
          };
        }
      }
    );

    server.registerTool(
      "get_cart",
      {
        title: "Get Cart",
        description: "Retrieve cart details including items and totals",
        inputSchema: {
          id: z.string().describe("Cart ID"),
        },
      },
      async ({ id }) => {
        try {
          const { data: carts } = await query.graph({
            entity: "cart",
            fields: [
              "id",
              "email",
              "currency_code",
              "region_id",
              "customer_id",
              "items.*",
              "items.variant.*",
              "items.product.*",
              "shipping_address.*",
              "billing_address.*",
            ],
            filters: {
              id,
            },
          });

          if (!carts || carts.length === 0) {
            return {
              content: [
                {
                  type: "text",
                  text: `Cart not found with ID: ${id}`,
                },
              ],
              isError: true,
            };
          }

          return {
            content: [
              {
                type: "text",
                text: JSON.stringify(carts[0], null, 2),
              },
            ],
          };
        } catch (error: any) {
          return {
            content: [
              {
                type: "text",
                text: `Error retrieving cart: ${error.message}`,
              },
            ],
            isError: true,
          };
        }
      }
    );

    server.registerTool(
      "list_user_carts",
      {
        title: "List User Carts",
        description: "List all carts for a specific user by customer ID or email address",
        inputSchema: {
          customer_id: z.string().optional().describe("Customer ID to filter carts"),
          email: z.string().email().optional().describe("Customer email address to filter carts"),
          limit: z.number().optional().describe("Number of carts to return (default: 20)"),
          offset: z.number().optional().describe("Number of carts to skip (default: 0)"),
        },
      },
      async ({ customer_id, email, limit, offset }) => {
        try {
          // At least one filter must be provided
          if (!customer_id && !email) {
            return {
              content: [
                {
                  type: "text",
                  text: "Error: Please provide either customer_id or email to filter carts",
                },
              ],
              isError: true,
            };
          }

          // Build filters object
          const filters: any = {};
          if (customer_id) {
            filters.customer_id = customer_id;
          }
          if (email) {
            filters.email = email;
          }

          const { data: carts } = await query.graph({
            entity: "cart",
            fields: [
              "id",
              "email",
              "currency_code",
              "region_id",
              "customer_id",
              "created_at",
              "updated_at",
              "completed_at",
              "items.*",
              "items.variant.*",
              "items.product.title",
              "shipping_address.*",
              "billing_address.*",
            ],
            filters,
            pagination: {
              skip: offset || 0,
              take: limit || 20,
            },
          });

          return {
            content: [
              {
                type: "text",
                text: JSON.stringify(
                  {
                    carts,
                    count: carts.length,
                    limit: limit || 20,
                    offset: offset || 0,
                    filters: {
                      customer_id: customer_id || null,
                      email: email || null,
                    },
                  },
                  null,
                  2
                ),
              },
            ],
          };
        } catch (error: any) {
          return {
            content: [
              {
                type: "text",
                text: `Error listing user carts: ${error.message}`,
              },
            ],
            isError: true,
          };
        }
      }
    );

    server.registerTool(
      "add_to_cart",
      {
        title: "Add Items to Cart",
        description: "Add one or more product variants to an existing cart",
        inputSchema: {
          cart_id: z.string().describe("Cart ID"),
          items: z.array(
            z.object({
              variant_id: z.string().describe("Product variant ID"),
              quantity: z.number().int().positive().describe("Quantity to add"),
            })
          ).describe("Items to add to the cart"),
        },
      },
      async ({ cart_id, items }) => {
        try {
          await addToCartWorkflow(container).run({
            input: {
              cart_id,
              items,
            },
          });

          // Retrieve updated cart
          const { data: carts } = await query.graph({
            entity: "cart",
            fields: [
              "id",
              "items.*",
              "items.variant.*",
              "items.product.title",
            ],
            filters: {
              id: cart_id,
            },
          });

          return {
            content: [
              {
                type: "text",
                text: JSON.stringify(
                  {
                    message: "Items added to cart successfully",
                    cart: carts[0],
                  },
                  null,
                  2
                ),
              },
            ],
          };
        } catch (error: any) {
          return {
            content: [
              {
                type: "text",
                text: `Error adding to cart: ${error.message}`,
              },
            ],
            isError: true,
          };
        }
      }
    );

    server.registerTool(
      "update_cart_item",
      {
        title: "Update Cart Item",
        description: "Update the quantity of a line item in the cart (set to 0 to remove)",
        inputSchema: {
          cart_id: z.string().describe("Cart ID"),
          item_id: z.string().describe("Line item ID to update"),
          quantity: z.number().int().min(0).describe("New quantity (0 to remove item)"),
        },
      },
      async ({ cart_id, item_id, quantity }) => {
        try {
          await updateLineItemInCartWorkflow(container).run({
            input: {
              cart_id,
              item_id,
              update: {
                quantity,
              },
            },
          });

          // Retrieve updated cart
          const { data: carts } = await query.graph({
            entity: "cart",
            fields: [
              "id",
              "items.*",
              "items.variant.*",
              "items.product.title",
            ],
            filters: {
              id: cart_id,
            },
          });

          return {
            content: [
              {
                type: "text",
                text: JSON.stringify(
                  {
                    message: quantity === 0 ? "Item removed from cart" : "Item quantity updated",
                    cart: carts[0],
                  },
                  null,
                  2
                ),
              },
            ],
          };
        } catch (error: any) {
          return {
            content: [
              {
                type: "text",
                text: `Error updating cart item: ${error.message}`,
              },
            ],
            isError: true,
          };
        }
      }
    );

    // ===================================
    // ORDER TOOLS
    // ===================================

    server.registerTool(
      "create_order",
      {
        title: "Create Order",
        description: "Create an order from a cart with customer and shipping information",
        inputSchema: {
          cart_id: z.string().describe("Cart ID to create order from"),
          email: z.string().email().optional().describe("Customer email address"),
          shipping_address: z
            .object({
              first_name: z.string().describe("First name"),
              last_name: z.string().describe("Last name"),
              address_1: z.string().describe("Address line 1"),
              address_2: z.string().optional().describe("Address line 2"),
              city: z.string().describe("City"),
              country_code: z.string().describe("Country code (e.g., 'us')"),
              postal_code: z.string().describe("Postal/ZIP code"),
              province: z.string().optional().describe("State/Province"),
              phone: z.string().optional().describe("Phone number"),
            })
            .optional()
            .describe("Shipping address details"),
          billing_address: z
            .object({
              first_name: z.string().describe("First name"),
              last_name: z.string().describe("Last name"),
              address_1: z.string().describe("Address line 1"),
              address_2: z.string().optional().describe("Address line 2"),
              city: z.string().describe("City"),
              country_code: z.string().describe("Country code (e.g., 'us')"),
              postal_code: z.string().describe("Postal/ZIP code"),
              province: z.string().optional().describe("State/Province"),
              phone: z.string().optional().describe("Phone number"),
            })
            .optional()
            .describe("Billing address details"),
        },
      },
      async ({ cart_id, email, shipping_address, billing_address }) => {
        try {
          // Fetch cart via query to construct the workflow input
          const { data: carts } = await query.graph({
            entity: "cart",
            fields: [
              "id",
              "email",
              "currency_code",
              "region_id",
              "customer_id",
              "items.*",
              "items.variant.*",
              "shipping_address.*",
              "billing_address.*",
              "sales_channel_id",
            ],
            filters: { id: cart_id },
          });

          if (!carts || carts.length === 0) {
            return {
              content: [
                {
                  type: "text",
                  text: `Error creating order: cart not found with id ${cart_id}`,
                },
              ],
              isError: true,
            };
          }

          const cart = carts[0];

          // Optionally override cart fields with provided values
          const orderInput: any = {
            region_id: cart.region_id,
            currency_code: cart.currency_code,
            email: email ?? cart.email,
            customer_id: cart.customer_id,
            shipping_address: shipping_address ?? cart.shipping_address,
            billing_address: billing_address ?? cart.billing_address,
            sales_channel_id: cart.sales_channel_id,
            items: (cart.items || []).map((it: any) => ({
              variant_id: it.variant.id,
              quantity: it.quantity,
              title: it.title,
              unit_price: it.unit_price ?? it.variant?.calculated_price?.calculated_amount,
              is_tax_inclusive: it.is_tax_inclusive,
            })),
          };

          const { result: createdOrder } = await createOrderWorkflow(container).run({
            input: orderInput,
          });

          return {
            content: [
              {
                type: "text",
                text: JSON.stringify(
                  {
                    order_id: createdOrder?.id,
                    order: createdOrder,
                  },
                  null,
                  2
                ),
              },
            ],
          };
        } catch (error: any) {
          return {
            content: [
              {
                type: "text",
                text: `Error creating order: ${error.message}`,
              },
            ],
            isError: true,
          };
        }
      }
    );
  }
);

export { handler as GET, handler as POST };
