#!/bin/bash

# Test script for MCP Cart Management Tools
# Make sure your Medusa server is running on http://localhost:9000

BASE_URL="http://localhost:9000/mcp/mcp"
HEADERS='-H "Content-Type: application/json" -H "Accept: application/json, text/event-stream"'

# Helper function to extract JSON from SSE response
extract_json() {
  grep "^data: " | sed 's/^data: //'
}

echo "=== MCP Cart Management Tests ==="
echo ""

# 1. List available tools
echo "1. Listing available tools..."
curl -s -X POST $BASE_URL \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{
    "jsonrpc": "2.0",
    "id": 1,
    "method": "tools/list"
  }' | extract_json | jq '.result.tools[] | {name: .name, title: .title}'
echo ""
echo ""

# 2. List regions (needed for cart creation)
echo "2. Listing regions..."
REGIONS=$(curl -s -X POST $BASE_URL \
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
  }' | extract_json)
echo "$REGIONS" | jq '.'
REGION_ID=$(echo "$REGIONS" | jq -r '.result.content[0].text | fromjson | .regions[0].id')
echo "Using region_id: $REGION_ID"
echo ""
echo ""

# 3. List products to get variant IDs
echo "3. Listing products to get variant IDs..."
PRODUCTS=$(curl -s -X POST $BASE_URL \
  -H "Content-Type: application/json" \
  -H "Accept: application/json, text/event-stream" \
  -d '{
    "jsonrpc": "2.0",
    "id": 3,
    "method": "tools/call",
    "params": {
      "name": "list_products",
      "arguments": {
        "limit": 1
      }
    }
  }' | extract_json)
echo "$PRODUCTS" | jq '.result.content[0].text | fromjson | .products[0] | {id, title}'
PRODUCT_ID=$(echo "$PRODUCTS" | jq -r '.result.content[0].text | fromjson | .products[0].id')
echo "Using product_id: $PRODUCT_ID"
echo ""
echo ""

# 4. Get product details to find variant ID
echo "4. Getting product details..."
PRODUCT_DETAILS=$(curl -s -X POST $BASE_URL \
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
  }" | extract_json)
echo "$PRODUCT_DETAILS" | jq '.result.content[0].text | fromjson | {title, variants: .variants[0:2]}'
VARIANT_ID=$(echo "$PRODUCT_DETAILS" | jq -r '.result.content[0].text | fromjson | .variants[0].id')
echo "Using variant_id: $VARIANT_ID"
echo ""
echo ""

# 5. Create a cart with an item
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
  }" | extract_json)
echo "$CART_RESPONSE" | jq '.result.content[0].text | fromjson'
CART_ID=$(echo "$CART_RESPONSE" | jq -r '.result.content[0].text | fromjson | .cart_id')
echo "Created cart_id: $CART_ID"
echo ""
echo ""

# 6. Get cart details
echo "6. Getting cart details..."
curl -s -X POST $BASE_URL \
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
  }" | extract_json | jq '.result.content[0].text | fromjson | {id, email, items: .items | length}'
echo ""
echo ""

# 7. Add another item to cart
echo "7. Adding another item to cart..."
if [ ! -z "$VARIANT_ID" ]; then
  curl -s -X POST $BASE_URL \
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
    }" | extract_json | jq '.result.content[0].text | fromjson | {message, items: .cart.items | length}'
fi
echo ""
echo ""

# 8. Get updated cart
echo "8. Getting updated cart with item details..."
CART_ITEMS=$(curl -s -X POST $BASE_URL \
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
  }" | extract_json)
echo "$CART_ITEMS" | jq '.result.content[0].text | fromjson | {id, email, items: [.items[] | {id, quantity, product_title: .product.title}]}'
ITEM_ID=$(echo "$CART_ITEMS" | jq -r '.result.content[0].text | fromjson | .items[0].id')
echo "Using item_id for update: $ITEM_ID"
echo ""
echo ""

# 9. Update cart item quantity
echo "9. Updating cart item quantity to 5..."
if [ ! -z "$ITEM_ID" ]; then
  curl -s -X POST $BASE_URL \
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
    }" | extract_json | jq '.result.content[0].text | fromjson | {message, items: [.cart.items[] | {quantity, product_title: .product.title}]}'
fi
echo ""
echo ""

# # 10. Remove item from cart (set quantity to 0)
# echo "10. Removing item from cart..."
# if [ ! -z "$ITEM_ID" ]; then
#   curl -s -X POST $BASE_URL \
#     -H "Content-Type: application/json" \
#     -H "Accept: application/json, text/event-stream" \
#     -d "{
#       \"jsonrpc\": \"2.0\",
#       \"id\": 10,
#       \"method\": \"tools/call\",
#       \"params\": {
#         \"name\": \"update_cart_item\",
#         \"arguments\": {
#           \"cart_id\": \"$CART_ID\",
#           \"item_id\": \"$ITEM_ID\",
#           \"quantity\": 0
#         }
#       }
#     }" | extract_json | jq '.result.content[0].text | fromjson | {message, items: .cart.items | length}'
# fi
# echo ""
# echo ""

# 10. List user carts by email
echo "10. Listing carts by email (test@example.com)..."
curl -s -X POST $BASE_URL \
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
  }' | extract_json | jq '.result.content[0].text | fromjson | {count, filters, carts: [.carts[] | {id, email, items_count: (.items | length), created_at}]}'
echo ""
echo ""

# 11. Create a second cart with the same email for testing
echo "11. Creating a second cart with same email..."
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
        \"email\": \"test@example.com\",
        \"items\": [
          {
            \"variant_id\": \"$VARIANT_ID\",
            \"quantity\": 1
          }
        ]
      }
    }
  }" | extract_json)
echo "$CART_RESPONSE_2" | jq '.result.content[0].text | fromjson | {cart_id, email: .cart.email}'
CART_ID_2=$(echo "$CART_RESPONSE_2" | jq -r '.result.content[0].text | fromjson | .cart_id')
echo "Created second cart_id: $CART_ID_2"
echo ""
echo ""

# 12. List user carts again (should show 2 carts now)
echo "12. Listing carts by email again (should show 2 carts)..."
curl -s -X POST $BASE_URL \
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
  }' | extract_json | jq '.result.content[0].text | fromjson | {count, filters, carts: [.carts[] | {id, email, items_count: (.items | length)}]}'
echo ""
echo ""

# 13. Test list_user_carts with customer_id (if available)
echo "13. Getting cart with customer_id info..."
CART_WITH_CUSTOMER=$(curl -s -X POST $BASE_URL \
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
  }" | extract_json)
CUSTOMER_ID=$(echo "$CART_WITH_CUSTOMER" | jq -r '.result.content[0].text | fromjson | .customer_id')
echo "$CART_WITH_CUSTOMER" | jq '.result.content[0].text | fromjson | {id, email, customer_id}'
echo "Customer ID: $CUSTOMER_ID"
echo ""
echo ""

# 14. If customer_id exists, test filtering by customer_id
if [ ! -z "$CUSTOMER_ID" ] && [ "$CUSTOMER_ID" != "null" ]; then
  echo "14. Listing carts by customer_id..."
  curl -s -X POST $BASE_URL \
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
    }" | extract_json | jq '.result.content[0].text | fromjson | {count, filters, carts: [.carts[] | {id, customer_id, items_count: (.items | length)}]}'
  echo ""
  echo ""
else
  echo "14. Skipping customer_id test (no customer_id available)"
  echo ""
  echo ""
fi

# 15. Test error handling - no filter provided
echo "15. Testing error handling (no filter provided)..."
curl -s -X POST $BASE_URL \
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
  }' | extract_json | jq '.result'
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
  }" | extract_json)

echo "$ORDER_RESPONSE" | jq '.result.content[0].text | fromjson'
ORDER_ID=$(echo "$ORDER_RESPONSE" | jq -r '.result.content[0].text | fromjson | .order_id')
echo "Created order_id: $ORDER_ID"
echo ""

echo "=== Tests Complete ==="
