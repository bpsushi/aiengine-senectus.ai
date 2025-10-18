#!/bin/bash

# Test script for MCP Cart Management Tools
# Make sure your Medusa server is running on http://localhost:9000

BASE_URL="https://senectus-ai.medusajs.app/mcp/mcp"

# Helper function to parse MCP responses
parse_mcp_response() {
  local response="$1"
  local json_data=$(echo "$response" | grep "^data:" | sed 's/^data: //')

  if echo "$json_data" | jq . > /dev/null 2>&1; then
    local is_error=$(echo "$json_data" | jq -r '.result.isError // false')
    if [ "$is_error" = "true" ]; then
      echo "ERROR: $(echo "$json_data" | jq -r '.result.content[0].text')"
      return 1
    else
      echo "$json_data" | jq -r '.result.content[0].text' | jq .
      return 0
    fi
  else
    echo "ERROR: Invalid JSON response"
    echo "$response"
    return 1
  fi
}

echo "=== MCP Cart Management Tests ==="
echo ""

# 1. List available tools
echo "1. Listing available tools..."
TOOLS_RESPONSE=$(curl -s -X POST $BASE_URL \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/list"
  }')

# Debug: Print the raw response
echo "Raw response for tools:"
echo "$TOOLS_RESPONSE"
echo ""

# Extract the JSON payload from the `data:` field if present
TOOLS_JSON=$(echo "$TOOLS_RESPONSE" | grep "^data:" | sed 's/^data: //' || echo "$TOOLS_RESPONSE")

if echo "$TOOLS_JSON" | jq . > /dev/null 2>&1; then
  echo "$TOOLS_JSON" | jq '.result.tools[] | {name: .name, title: .title}'
else
  echo "Error: Invalid JSON response for tools list"
  echo "$TOOLS_JSON"
fi
echo ""
echo ""

# 2. List regions (needed for cart creation)
echo "2. Listing regions..."
REGIONS_RESPONSE=$(curl -s -X POST $BASE_URL \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{
    "jsonrpc": "2.0",
    "id": 2,
    "method": "tools/call",
    "params": {
      "name": "list_regions",
      "arguments": {}
    }
  }')

# Debug: Print the raw response
echo "Raw response for regions:"
echo "$REGIONS_RESPONSE"
echo ""

# Extract the JSON payload from the `data:` field
REGIONS_JSON=$(echo "$REGIONS_RESPONSE" | grep "^data:" | sed 's/^data: //')

if echo "$REGIONS_JSON" | jq . > /dev/null 2>&1; then
  # Extract the `text` field and parse it as JSON
  REGIONS_DATA=$(echo "$REGIONS_JSON" | jq -r '.result.content[0].text' | jq .)

  if [ -n "$REGIONS_DATA" ] && echo "$REGIONS_DATA" | jq . > /dev/null 2>&1; then
    echo "Regions found:"
    echo "$REGIONS_DATA" | jq '.regions[] | {id, name, currency_code}'
    REGION_ID=$(echo "$REGIONS_DATA" | jq -r '.regions[0].id')
    echo "Using region_id: $REGION_ID"
  else
    echo "Error: Failed to parse regions JSON data"
  fi
else
  echo "Error: Invalid JSON payload for regions list"
  echo "$REGIONS_JSON"
fi
echo ""
echo ""

# 3. List products to get variant IDs
echo "3. Listing products to get variant IDs..."
PRODUCTS_RESPONSE=$(curl -s -X POST $BASE_URL \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "list_products",
      "arguments": {
        "limit": 5
      }
    }
  }')

# Extract the JSON payload and parse it
PRODUCTS_DATA=$(parse_mcp_response "$PRODUCTS_RESPONSE")
if [ $? -eq 0 ]; then
  echo "Available products:"
  echo "$PRODUCTS_DATA" | jq '.products[] | {id, title}'
  PRODUCT_ID=$(echo "$PRODUCTS_DATA" | jq -r '.products[0].id')
  echo "Using product_id: $PRODUCT_ID"
else
  echo "$PRODUCTS_DATA"
fi
echo ""
echo ""

# 4. Get product details to find variant ID
echo "4. Getting product details..."
PRODUCT_DETAILS_RESPONSE=$(curl -s -X POST $BASE_URL \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d "{
    \"jsonrpc\": \"2.0\",
    \"id\": 4,
    \"method\": \"tools/call\",
    \"params\": {
      \"name\": \"get_product\",
      \"arguments\": {
        \"id\": \"$PRODUCT_ID\"
      }
    }
  }")

# Extract and parse product details
PRODUCT_DETAILS_JSON=$(echo "$PRODUCT_DETAILS_RESPONSE" | grep "^data:" | sed 's/^data: //')
if echo "$PRODUCT_DETAILS_JSON" | jq . > /dev/null 2>&1; then
  PRODUCT_DETAILS_DATA=$(echo "$PRODUCT_DETAILS_JSON" | jq -r '.result.content[0].text' | jq .)
  echo "$PRODUCT_DETAILS_DATA" | jq '{title, variants: .variants[0:2]}'
  VARIANT_ID=$(echo "$PRODUCT_DETAILS_DATA" | jq -r '.variants[0].id')
  echo "Using variant_id: $VARIANT_ID"
else
  echo "Error: Invalid JSON payload for product details"
fi
echo ""
echo ""

# 5. Create a cart with an item (pricing should now be configured)
echo "5. Creating cart with item..."
CART_RESPONSE=$(curl -s -X POST $BASE_URL \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d "{
    \"jsonrpc\": \"2.0\",
    \"id\": 5,
    \"method\": \"tools/call\",
    \"params\": {
      \"name\": \"create_cart\",
      \"arguments\": {
        \"region_id\": \"$REGION_ID\",
        \"email\": \"test@example.com\",
        \"items\": [
          {
            \"variant_id\": \"$VARIANT_ID\",
            \"quantity\": 2
          }
        ]
      }
    }
  }")

CART_DATA=$(parse_mcp_response "$CART_RESPONSE")
if [ $? -eq 0 ]; then
  echo "$CART_DATA" | jq '.'
  CART_ID=$(echo "$CART_DATA" | jq -r '.cart_id')
  echo "Created cart_id: $CART_ID"
else
  echo "Cart creation with items failed, trying empty cart..."
  echo "$CART_DATA"

  # Fallback to empty cart
  EMPTY_CART_RESPONSE=$(curl -s -X POST $BASE_URL \
    -H "Content-Type: application/json" \
    -H "Accept: application/json, text/event-stream" \
    -d "{
      \"jsonrpc\": \"2.0\",
      \"id\": 5.1,
      \"method\": \"tools/call\",
      \"params\": {
        \"name\": \"create_cart\",
        \"arguments\": {
          \"region_id\": \"$REGION_ID\",
          \"email\": \"test@example.com\"
        }
      }
    }")

  EMPTY_CART_DATA=$(parse_mcp_response "$EMPTY_CART_RESPONSE")
  if [ $? -eq 0 ]; then
    echo "$EMPTY_CART_DATA" | jq '.'
    CART_ID=$(echo "$EMPTY_CART_DATA" | jq -r '.cart_id')
    echo "Created empty cart_id: $CART_ID"
  else
    echo "$EMPTY_CART_DATA"
  fi
fi
echo ""
echo ""

# 6. Get cart details
echo "6. Getting cart details..."
if [ -n "$CART_ID" ]; then
  GET_CART_RESPONSE=$(curl -s -X POST $BASE_URL \
    -H "Content-Type: application/json" \
    -H "Accept: application/json, text/event-stream" \
    -d "{
      \"jsonrpc\": \"2.0\",
      \"id\": 6,
      \"method\": \"tools/call\",
      \"params\": {
        \"name\": \"get_cart\",
        \"arguments\": {
          \"id\": \"$CART_ID\"
        }
      }
    }")

  GET_CART_DATA=$(parse_mcp_response "$GET_CART_RESPONSE")
  if [ $? -eq 0 ]; then
    echo "$GET_CART_DATA" | jq '{id, email, items: .items | length}'
  else
    echo "$GET_CART_DATA"
  fi
else
  echo "Skipping get cart test (no cart_id available)"
fi
echo ""
echo ""

# 7. Add another item to cart
echo "7. Adding another item to cart..."
if [ -n "$VARIANT_ID" ] && [ -n "$CART_ID" ]; then
  ADD_TO_CART_RESPONSE=$(curl -s -X POST $BASE_URL \
    -H "Content-Type: application/json" \
    -H "Accept: application/json, text/event-stream" \
    -d "{
      \"jsonrpc\": \"2.0\",
      \"id\": 7,
      \"method\": \"tools/call\",
      \"params\": {
        \"name\": \"add_to_cart\",
        \"arguments\": {
          \"cart_id\": \"$CART_ID\",
          \"items\": [
            {
              \"variant_id\": \"$VARIANT_ID\",
              \"quantity\": 1
            }
          ]
        }
      }
    }")

  ADD_TO_CART_DATA=$(parse_mcp_response "$ADD_TO_CART_RESPONSE")
  if [ $? -eq 0 ]; then
    echo "$ADD_TO_CART_DATA" | jq '{message, items: .cart.items | length}'
  else
    echo "$ADD_TO_CART_DATA"
  fi
else
  echo "Skipping add to cart (missing variant_id or cart_id)"
fi
echo ""
echo ""

# 8. Get updated cart
echo "8. Getting updated cart with item details..."
if [ -n "$CART_ID" ]; then
  CART_ITEMS_RESPONSE=$(curl -s -X POST $BASE_URL \
    -H "Content-Type: application/json" \
    -H "Accept: application/json, text/event-stream" \
    -d "{
      \"jsonrpc\": \"2.0\",
      \"id\": 8,
      \"method\": \"tools/call\",
      \"params\": {
        \"name\": \"get_cart\",
        \"arguments\": {
          \"id\": \"$CART_ID\"
        }
      }
    }")

  CART_ITEMS_DATA=$(parse_mcp_response "$CART_ITEMS_RESPONSE")
  if [ $? -eq 0 ]; then
    echo "$CART_ITEMS_DATA" | jq '{id, email, items: [.items[] | {id, quantity, product_title: .product.title}]}'
    ITEM_ID=$(echo "$CART_ITEMS_DATA" | jq -r '.items[0].id // empty')
    if [ -n "$ITEM_ID" ]; then
      echo "Using item_id for update: $ITEM_ID"
    else
      echo "No items found in cart"
    fi
  else
    echo "$CART_ITEMS_DATA"
  fi
else
  echo "Skipping get cart items (no cart_id)"
fi
echo ""
echo ""

# 9. Update cart item quantity
echo "9. Updating cart item quantity to 5..."
if [ ! -z "$ITEM_ID" ]; then
  UPDATE_CART_RESPONSE=$(curl -s -X POST $BASE_URL \
    -H "Content-Type: application/json" \
    -H "Accept: application/json, text/event-stream" \
    -d "{
      \"jsonrpc\": \"2.0\",
      \"id\": 9,
      \"method\": \"tools/call\",
      \"params\": {
        \"name\": \"update_cart_item\",
        \"arguments\": {
          \"cart_id\": \"$CART_ID\",
          \"item_id\": \"$ITEM_ID\",
          \"quantity\": 5
        }
      }
    }")

  # Extract and parse update cart response
  UPDATE_CART_JSON=$(echo "$UPDATE_CART_RESPONSE" | grep "^data:" | sed 's/^data: //')
  if echo "$UPDATE_CART_JSON" | jq . > /dev/null 2>&1; then
    UPDATE_CART_DATA=$(echo "$UPDATE_CART_JSON" | jq -r '.result.content[0].text' | jq .)
    echo "$UPDATE_CART_DATA" | jq '{message, items: [.cart.items[] | {quantity, product_title: .product.title}]}'
  else
    echo "Error: Invalid JSON payload for update cart"
  fi
fi
echo ""
echo ""

# 10. List user carts by email
echo "10. Listing carts by email (test@example.com)..."
LIST_CARTS_RESPONSE=$(curl -s -X POST $BASE_URL \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{
    "jsonrpc": "2.0",
    "id": 10,
    "method": "tools/call",
    "params": {
      "name": "list_user_carts",
      "arguments": {
        "email": "test@example.com",
        "limit": 10
      }
    }
  }')

# Extract and parse list carts response
LIST_CARTS_JSON=$(echo "$LIST_CARTS_RESPONSE" | grep "^data:" | sed 's/^data: //')
if echo "$LIST_CARTS_JSON" | jq . > /dev/null 2>&1; then
  LIST_CARTS_DATA=$(echo "$LIST_CARTS_JSON" | jq -r '.result.content[0].text' | jq .)
  echo "$LIST_CARTS_DATA" | jq '{count, filters, carts: [.carts[] | {id, email, items_count: (.items | length), created_at}]}'
else
  echo "Error: Invalid JSON payload for list carts"
fi
echo ""
echo ""

# 11. Create a second empty cart with the same email for testing
echo "11. Creating a second empty cart with same email..."
CART_RESPONSE_2=$(curl -s -X POST $BASE_URL \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d "{
    \"jsonrpc\": \"2.0\",
    \"id\": 11,
    \"method\": \"tools/call\",
    \"params\": {
      \"name\": \"create_cart\",
      \"arguments\": {
        \"region_id\": \"$REGION_ID\",
        \"email\": \"test@example.com\"
      }
    }
  }")

CART_DATA_2=$(parse_mcp_response "$CART_RESPONSE_2")
if [ $? -eq 0 ]; then
  echo "$CART_DATA_2" | jq '{cart_id, email: .cart.email}'
  CART_ID_2=$(echo "$CART_DATA_2" | jq -r '.cart_id')
  echo "Created second cart_id: $CART_ID_2"
else
  echo "$CART_DATA_2"
fi
echo ""
echo ""

# 12. List user carts again (should show 2 carts now)
echo "12. Listing carts by email again (should show 2 carts)..."
LIST_CARTS_2_RESPONSE=$(curl -s -X POST $BASE_URL \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{
    "jsonrpc": "2.0",
    "id": 12,
    "method": "tools/call",
    "params": {
      "name": "list_user_carts",
      "arguments": {
        "email": "test@example.com"
      }
    }
  }')

# Extract and parse second list carts response
LIST_CARTS_2_JSON=$(echo "$LIST_CARTS_2_RESPONSE" | grep "^data:" | sed 's/^data: //')
if echo "$LIST_CARTS_2_JSON" | jq . > /dev/null 2>&1; then
  LIST_CARTS_2_DATA=$(echo "$LIST_CARTS_2_JSON" | jq -r '.result.content[0].text' | jq .)
  echo "$LIST_CARTS_2_DATA" | jq '{count, filters, carts: [.carts[] | {id, email, items_count: (.items | length)}]}'
else
  echo "Error: Invalid JSON payload for second list carts"
fi
echo ""
echo ""

# 13. Test list_user_carts with customer_id (if available)
echo "13. Getting cart with customer_id info..."
CART_WITH_CUSTOMER_RESPONSE=$(curl -s -X POST $BASE_URL \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d "{
    \"jsonrpc\": \"2.0\",
    \"id\": 13,
    \"method\": \"tools/call\",
    \"params\": {
      \"name\": \"get_cart\",
      \"arguments\": {
        \"id\": \"$CART_ID\"
      }
    }
  }")

# Extract and parse cart with customer response
CART_WITH_CUSTOMER_JSON=$(echo "$CART_WITH_CUSTOMER_RESPONSE" | grep "^data:" | sed 's/^data: //')
if echo "$CART_WITH_CUSTOMER_JSON" | jq . > /dev/null 2>&1; then
  CART_WITH_CUSTOMER_DATA=$(echo "$CART_WITH_CUSTOMER_JSON" | jq -r '.result.content[0].text' | jq .)
  CUSTOMER_ID=$(echo "$CART_WITH_CUSTOMER_DATA" | jq -r '.customer_id')
  echo "$CART_WITH_CUSTOMER_DATA" | jq '{id, email, customer_id}'
  echo "Customer ID: $CUSTOMER_ID"
else
  echo "Error: Invalid JSON payload for cart with customer"
fi
echo ""
echo ""

# 14. If customer_id exists, test filtering by customer_id
if [ ! -z "$CUSTOMER_ID" ] && [ "$CUSTOMER_ID" != "null" ]; then
  echo "14. Listing carts by customer_id..."
  LIST_BY_CUSTOMER_RESPONSE=$(curl -s -X POST $BASE_URL \
    -H "Content-Type: application/json" \
    -H "Accept: application/json, text/event-stream" \
    -d "{
      \"jsonrpc\": \"2.0\",
      \"id\": 14,
      \"method\": \"tools/call\",
      \"params\": {
        \"name\": \"list_user_carts\",
        \"arguments\": {
          \"customer_id\": \"$CUSTOMER_ID\"
        }
      }
    }")

  # Extract and parse list by customer response
  LIST_BY_CUSTOMER_JSON=$(echo "$LIST_BY_CUSTOMER_RESPONSE" | grep "^data:" | sed 's/^data: //')
  if echo "$LIST_BY_CUSTOMER_JSON" | jq . > /dev/null 2>&1; then
    LIST_BY_CUSTOMER_DATA=$(echo "$LIST_BY_CUSTOMER_JSON" | jq -r '.result.content[0].text' | jq .)
    echo "$LIST_BY_CUSTOMER_DATA" | jq '{count, filters, carts: [.carts[] | {id, customer_id, items_count: (.items | length)}]}'
  else
    echo "Error: Invalid JSON payload for list by customer"
  fi
  echo ""
  echo ""
else
  echo "14. Skipping customer_id test (no customer_id available)"
  echo ""
  echo ""
fi

# 15. Test error handling - no filter provided
echo "15. Testing error handling (no filter provided)..."
ERROR_TEST_RESPONSE=$(curl -s -X POST $BASE_URL \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{
    "jsonrpc": "2.0",
    "id": 15,
    "method": "tools/call",
    "params": {
      "name": "list_user_carts",
      "arguments": {}
    }
  }')

# Extract and parse error test response
ERROR_TEST_JSON=$(echo "$ERROR_TEST_RESPONSE" | grep "^data:" | sed 's/^data: //')
if echo "$ERROR_TEST_JSON" | jq . > /dev/null 2>&1; then
  echo "$ERROR_TEST_JSON" | jq '.result'
else
  echo "Error: Invalid JSON payload for error test"
  echo "$ERROR_TEST_RESPONSE"
fi
echo ""
echo ""

# 16. Create order from cart
echo "16. Creating order from cart..."
ORDER_RESPONSE=$(curl -s -X POST $BASE_URL \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d "{\
    \"jsonrpc\": \"2.0\",\
    \"id\": 16,\
    \"method\": \"tools/call\",\
    \"params\": {\
      \"name\": \"create_order\",\
      \"arguments\": {\
        \"cart_id\": \"$CART_ID\",\
        \"email\": \"buyer@example.com\",\
        \"shipping_address\": {\
          \"first_name\": \"Buyer\",\
          \"last_name\": \"McBuy\",\
          \"address_1\": \"1 Market St\",\
          \"city\": \"San Francisco\",\
          \"country_code\": \"us\",\
          \"postal_code\": \"94105\"\
        }\
      }\
    }\
  }")

# Extract and parse order response
ORDER_JSON=$(echo "$ORDER_RESPONSE" | grep "^data:" | sed 's/^data: //')
if echo "$ORDER_JSON" | jq . > /dev/null 2>&1; then
  ORDER_DATA=$(echo "$ORDER_JSON" | jq -r '.result.content[0].text' | jq .)
  echo "$ORDER_DATA" | jq '.'
  ORDER_ID=$(echo "$ORDER_DATA" | jq -r '.order_id')
  echo "Created order_id: $ORDER_ID"
else
  echo "Error: Invalid JSON payload for order creation"
fi
echo ""

echo "=== Tests Complete ==="
