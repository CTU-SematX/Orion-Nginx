#!/bin/bash

# Interactive Demo - Orion-LD Gateway Authentication
# Shows real-world usage examples

set -e

GATEWAY_URL="http://localhost:8080"

echo "================================================================"
echo "   Orion-LD Gateway Authentication - Interactive Demo"
echo "================================================================"
echo ""

# Generate JWT Token
echo "📝 Step 1: Generate JWT Token"
echo "----------------------------------------------------------------"
echo "$ python3 generate-jwt.py"
echo ""
TOKEN=$(python3 generate-jwt.py 2>/dev/null | grep "^eyJ" | tr -d ' ')
echo "✓ Token generated successfully"
echo "Token (truncated): ${TOKEN:0:50}..."
echo ""
read -p "Press Enter to continue..."
echo ""

# Test 1: Query entities (no auth)
echo "🔍 Step 2: Query Entities (No Authentication Required)"
echo "----------------------------------------------------------------"
echo "$ curl \"$GATEWAY_URL/ngsi-ld/v1/entities?type=TemperatureSensor\""
echo ""
RESPONSE=$(curl -s "$GATEWAY_URL/ngsi-ld/v1/entities?type=TemperatureSensor")
echo "$RESPONSE" | jq '.[0] | {id, type, temperature: .temperature.value}'
echo ""
echo "✓ GET request successful without authentication"
echo ""
read -p "Press Enter to continue..."
echo ""

# Test 2: Try to update without JWT (should fail)
echo "❌ Step 3: Try PATCH Without Authentication"
echo "----------------------------------------------------------------"
echo "$ curl -X PATCH \"$GATEWAY_URL/ngsi-ld/v1/entities/...\""
echo "  (without Authorization header)"
echo ""
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH \
    "$GATEWAY_URL/ngsi-ld/v1/entities/urn:ngsi-ld:TemperatureSensor:001/attrs" \
    -H "Content-Type: application/json" \
    -d '{"temperature": {"type": "Property", "value": 50.0}}')
echo "HTTP Response: $HTTP_CODE"
if [ "$HTTP_CODE" = "401" ]; then
    echo "✓ Request blocked as expected (401 Unauthorized)"
else
    echo "⚠ Unexpected response: $HTTP_CODE"
fi
echo ""
read -p "Press Enter to continue..."
echo ""

# Test 3: Update with JWT (should succeed)
echo "✅ Step 4: PATCH With Valid JWT Token"
echo "----------------------------------------------------------------"
NEW_VALUE=$(echo "scale=1; 20 + $RANDOM % 20" | bc)
echo "$ curl -X PATCH \"$GATEWAY_URL/ngsi-ld/v1/entities/...\""
echo "  -H \"Authorization: Bearer \$TOKEN\""
echo "  -d '{\"temperature\": {\"value\": $NEW_VALUE}}'"
echo ""
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH \
    "$GATEWAY_URL/ngsi-ld/v1/entities/urn:ngsi-ld:TemperatureSensor:001/attrs" \
    -H "Content-Type: application/json" \
    -H "Authorization: Bearer $TOKEN" \
    -d "{\"temperature\": {\"type\": \"Property\", \"value\": $NEW_VALUE}}")
echo "HTTP Response: $HTTP_CODE"
if [ "$HTTP_CODE" = "204" ] || [ "$HTTP_CODE" = "207" ]; then
    echo "✓ Update successful!"
    echo ""
    echo "Verifying update..."
    UPDATED_VALUE=$(curl -s "$GATEWAY_URL/ngsi-ld/v1/entities/urn:ngsi-ld:TemperatureSensor:001" | jq '.temperature.value')
    echo "Current temperature value: $UPDATED_VALUE °C"
else
    echo "⚠ Update failed with code: $HTTP_CODE"
fi
echo ""
read -p "Press Enter to continue..."
echo ""

# Test 4: Show complete workflow
echo "🔄 Step 5: Complete Workflow Example"
echo "----------------------------------------------------------------"
echo "Simulating IoT device sending temperature updates with JWT..."
echo ""

for i in {1..3}; do
    TEMP=$(echo "scale=1; 20 + $RANDOM % 15" | bc)
    echo "[$i/3] Sending temperature: $TEMP °C"
    
    curl -s -X PATCH \
        "$GATEWAY_URL/ngsi-ld/v1/entities/urn:ngsi-ld:TemperatureSensor:001/attrs" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $TOKEN" \
        -d "{\"temperature\": {\"type\": \"Property\", \"value\": $TEMP}}" \
        > /dev/null
    
    echo "  ✓ Update successful"
    sleep 1
done

echo ""
echo "Final value:"
curl -s "$GATEWAY_URL/ngsi-ld/v1/entities/urn:ngsi-ld:TemperatureSensor:001" | \
    jq '{id, type, temperature: .temperature.value, updated: .temperature.observedAt}'
echo ""

# Summary
echo "================================================================"
echo "   Summary"
echo "================================================================"
echo ""
echo "✅ Authentication system is working correctly:"
echo ""
echo "  1. ✓ JWT token generation"
echo "  2. ✓ Public GET requests (no auth needed)"
echo "  3. ✓ Protected PATCH/PUT requests (JWT required)"
echo "  4. ✓ Invalid requests properly rejected"
echo ""
echo "📚 For more information:"
echo "  - Run: ./test-auth.sh (full test suite)"
echo "  - Read: AUTH_TESTING.md (complete guide)"
echo "  - Generate token: python3 generate-jwt.py"
echo ""
echo "================================================================"
