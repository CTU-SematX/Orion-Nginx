#!/bin/bash

# Test Authentication Features for Orion-LD Gateway
# This script tests JWT authentication and IP-based access control

set -e

GATEWAY_URL="http://localhost:8080"
JWT_SECRET="my-super-secret-key-2024"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "========================================="
echo "Testing Orion-LD Gateway Authentication"
echo "========================================="
echo ""

# Function to generate JWT token
generate_jwt() {
    # Using Python to generate JWT (HS256)
    python3 << EOF
import jwt
import datetime

secret = "$JWT_SECRET"
payload = {
    "sub": "test-user",
    "name": "Test User",
    "iat": datetime.datetime.utcnow(),
    "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=1)
}
token = jwt.encode(payload, secret, algorithm="HS256")
print(token)
EOF
}

# Test 1: GET request (should work without authentication)
echo -e "${YELLOW}Test 1: GET request (no auth required)${NC}"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" "$GATEWAY_URL/ngsi-ld/v1/entities?type=TemperatureSensor")
if [ "$RESPONSE" = "200" ]; then
    echo -e "${GREEN}✓ PASSED${NC} - GET request allowed without authentication"
else
    echo -e "${RED}✗ FAILED${NC} - Expected 200, got $RESPONSE"
fi
echo ""

# Test 2: POST request without trusted IP (should fail)
echo -e "${YELLOW}Test 2: POST request from non-trusted IP${NC}"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X POST "$GATEWAY_URL/ngsi-ld/v1/entities" \
    -H "Content-Type: application/ld+json" \
    -d '{
        "@context": "https://uri.etsi.org/ngsi-ld/v1/ngsi-ld-core-context.jsonld",
        "id": "urn:ngsi-ld:Test:001",
        "type": "TestEntity"
    }')
if [ "$RESPONSE" = "403" ]; then
    echo -e "${GREEN}✓ PASSED${NC} - POST request blocked for non-trusted IP"
else
    echo -e "${RED}✗ FAILED${NC} - Expected 403, got $RESPONSE"
fi
echo ""

# Test 3: Generate JWT token
echo -e "${YELLOW}Test 3: Generate JWT token${NC}"
if command -v python3 &> /dev/null; then
    # Check if PyJWT is installed
    if python3 -c "import jwt" 2>/dev/null; then
        JWT_TOKEN=$(generate_jwt)
        echo -e "${GREEN}✓ PASSED${NC} - JWT token generated"
        echo "Token: ${JWT_TOKEN:0:50}..."
        echo ""
        
        # Test 4: PATCH request with valid JWT
        echo -e "${YELLOW}Test 4: PATCH request with valid JWT${NC}"
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "$GATEWAY_URL/ngsi-ld/v1/entities/urn:ngsi-ld:TemperatureSensor:001/attrs" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $JWT_TOKEN" \
            -d '{
                "temperature": {
                    "type": "Property",
                    "value": 27.5
                }
            }')
        if [ "$RESPONSE" = "204" ] || [ "$RESPONSE" = "207" ]; then
            echo -e "${GREEN}✓ PASSED${NC} - PATCH request allowed with valid JWT"
        else
            echo -e "${RED}✗ FAILED${NC} - Expected 204/207, got $RESPONSE"
        fi
        echo ""
        
        # Test 5: PATCH request without JWT
        echo -e "${YELLOW}Test 5: PATCH request without JWT${NC}"
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "$GATEWAY_URL/ngsi-ld/v1/entities/urn:ngsi-ld:TemperatureSensor:001/attrs" \
            -H "Content-Type: application/json" \
            -d '{
                "temperature": {
                    "type": "Property",
                    "value": 28.0
                }
            }')
        if [ "$RESPONSE" = "401" ]; then
            echo -e "${GREEN}✓ PASSED${NC} - PATCH request blocked without JWT"
        else
            echo -e "${RED}✗ FAILED${NC} - Expected 401, got $RESPONSE"
        fi
        echo ""
        
        # Test 6: PATCH request with invalid JWT
        echo -e "${YELLOW}Test 6: PATCH request with invalid JWT${NC}"
        INVALID_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.invalid.signature"
        RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X PATCH "$GATEWAY_URL/ngsi-ld/v1/entities/urn:ngsi-ld:TemperatureSensor:001/attrs" \
            -H "Content-Type: application/json" \
            -H "Authorization: Bearer $INVALID_TOKEN" \
            -d '{
                "temperature": {
                    "type": "Property",
                    "value": 29.0
                }
            }')
        if [ "$RESPONSE" = "401" ]; then
            echo -e "${GREEN}✓ PASSED${NC} - PATCH request blocked with invalid JWT"
        else
            echo -e "${RED}✗ FAILED${NC} - Expected 401, got $RESPONSE"
        fi
        echo ""
        
    else
        echo -e "${YELLOW}⚠ SKIPPED${NC} - PyJWT not installed. Install with: pip3 install PyJWT"
        echo ""
    fi
else
    echo -e "${YELLOW}⚠ SKIPPED${NC} - Python3 not found"
    echo ""
fi

# Test 7: DELETE request from non-trusted IP
echo -e "${YELLOW}Test 7: DELETE request from non-trusted IP${NC}"
RESPONSE=$(curl -s -o /dev/null -w "%{http_code}" -X DELETE "$GATEWAY_URL/ngsi-ld/v1/entities/urn:ngsi-ld:Test:001")
if [ "$RESPONSE" = "403" ]; then
    echo -e "${GREEN}✓ PASSED${NC} - DELETE request blocked for non-trusted IP"
else
    echo -e "${RED}✗ FAILED${NC} - Expected 403, got $RESPONSE"
fi
echo ""

# Summary
echo "========================================="
echo "Test Summary"
echo "========================================="
echo ""
echo "Gateway URL: $GATEWAY_URL"
echo "JWT Secret: $JWT_SECRET"
echo "Trusted IPs: 172.18.0.1, 127.0.0.1"
echo ""
echo "Access Rules:"
echo "  - GET: ✓ Allowed for everyone"
echo "  - POST/DELETE: ✓ Allowed only for trusted IPs"
echo "  - PATCH/PUT: ✓ Allowed for trusted IPs or with valid JWT"
echo ""
