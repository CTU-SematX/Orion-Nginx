# Authentication Testing Guide

## Overview

Orion-LD Gateway implements IP-based and JWT-based authentication với các quy tắc sau:

### Access Control Rules

| HTTP Method | Trusted IP | Non-Trusted IP | Authentication Required |
|-------------|-----------|----------------|------------------------|
| **GET** | ✅ Allowed | ✅ Allowed | ❌ No |
| **POST** | ✅ Allowed | ❌ Denied | N/A (IP-based only) |
| **DELETE** | ✅ Allowed | ❌ Denied | N/A (IP-based only) |
| **PATCH** | ✅ Allowed | ✅ With JWT | ✅ Yes (for non-trusted) |
| **PUT** | ✅ Allowed | ✅ With JWT | ✅ Yes (for non-trusted) |

## Configuration

### Environment Variables

File: `docker/.env`

```bash
JWT_SECRET=my-super-secret-key-2024
TRUSTED_IPS=172.18.0.1,127.0.0.1
AUTHENTICATION_ENABLED=true
```

### Update Configuration

```bash
# Edit .env file
nano docker/.env

# Restart gateway
cd docker
docker compose restart gateway
```

## Generate JWT Token

### Method 1: Using Python Script

```bash
# Generate token with default settings (24h validity)
python3 generate-jwt.py

# Generate token for specific user
python3 generate-jwt.py --user john.doe

# Generate token with custom validity (48 hours)
python3 generate-jwt.py --user admin --hours 48

# Use custom secret
python3 generate-jwt.py --secret your-secret-key --user test
```

### Method 2: Using Python Directly

```python
import jwt
import datetime

secret = "my-super-secret-key-2024"
payload = {
    "sub": "admin",
    "name": "Admin User",
    "iat": datetime.datetime.now(datetime.UTC),
    "exp": datetime.datetime.now(datetime.UTC) + datetime.timedelta(hours=24)
}
token = jwt.encode(payload, secret, algorithm="HS256")
print(token)
```

### Method 3: Using Online Tool

Visit: https://jwt.io/

**Header:**
```json
{
  "alg": "HS256",
  "typ": "JWT"
}
```

**Payload:**
```json
{
  "sub": "admin",
  "name": "Admin User",
  "iat": 1702214400,
  "exp": 1702300800
}
```

**Secret:** `my-super-secret-key-2024`

## Testing Authentication

### Run Automated Tests

```bash
cd /home/ubuntu/Orion-Nginx
./test-auth.sh
```

### Manual Tests

#### Test 1: GET Request (No Auth)

```bash
curl -X GET "http://localhost:8080/ngsi-ld/v1/entities?type=TemperatureSensor"
# Expected: 200 OK
```

#### Test 2: POST Request (Non-Trusted IP)

```bash
curl -X POST "http://localhost:8080/ngsi-ld/v1/entities" \
  -H "Content-Type: application/ld+json" \
  -d '{
    "@context": "https://uri.etsi.org/ngsi-ld/v1/ngsi-ld-core-context.jsonld",
    "id": "urn:ngsi-ld:Test:001",
    "type": "TestEntity"
  }'
# Expected: 403 Forbidden
```

#### Test 3: PATCH Request with JWT

```bash
# Generate token
TOKEN=$(python3 generate-jwt.py | grep "eyJ" | tr -d ' ')

# Make PATCH request
curl -X PATCH "http://localhost:8080/ngsi-ld/v1/entities/urn:ngsi-ld:TemperatureSensor:001/attrs" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "temperature": {
      "type": "Property",
      "value": 30.5
    }
  }'
# Expected: 204 No Content or 207 Multi-Status
```

#### Test 4: PATCH Request without JWT

```bash
curl -X PATCH "http://localhost:8080/ngsi-ld/v1/entities/urn:ngsi-ld:TemperatureSensor:001/attrs" \
  -H "Content-Type: application/json" \
  -d '{
    "temperature": {
      "type": "Property",
      "value": 31.0
    }
  }'
# Expected: 401 Unauthorized
```

## Integration with Grafana

### Option 1: Update Datasource with JWT

1. Generate JWT token:
```bash
python3 generate-jwt.py --hours 8760  # 1 year validity
```

2. In Grafana datasource configuration:
   - Enable "Custom HTTP Headers"
   - Add header: `Authorization: Bearer YOUR_TOKEN_HERE`

### Option 2: Add Grafana IP to Trusted IPs

1. Find Grafana container IP:
```bash
docker inspect grafana | grep IPAddress
```

2. Add to `docker/.env`:
```bash
TRUSTED_IPS=172.18.0.1,127.0.0.1,172.18.0.7
```

3. Restart gateway:
```bash
cd docker && docker compose restart gateway
```

## Troubleshooting

### Check Gateway Logs

```bash
docker logs gateway 2>&1 | tail -50
```

### Verify Environment Variables

```bash
docker exec gateway printenv | grep -E "JWT_SECRET|TRUSTED_IPS|AUTHENTICATION"
```

### Test JWT Token Validity

```python
import jwt

token = "YOUR_TOKEN_HERE"
secret = "my-super-secret-key-2024"

try:
    payload = jwt.decode(token, secret, algorithms=["HS256"])
    print("Valid token:", payload)
except jwt.ExpiredSignatureError:
    print("Token expired")
except jwt.InvalidTokenError as e:
    print("Invalid token:", e)
```

### Common Errors

**Error: "http: no Host in request URL"**
- Solution: Ensure datasource `url` field is set in Grafana

**Error: "JWT verification failed"**
- Check JWT_SECRET matches in both generator and gateway
- Verify token hasn't expired
- Ensure Authorization header format: `Bearer TOKEN`

**Error: "POST/DELETE denied - not trusted IP"**
- Add your IP to TRUSTED_IPS in docker/.env
- Restart gateway container

## Security Best Practices

1. **Change default JWT_SECRET** in production
2. **Use HTTPS** in production environments
3. **Rotate JWT secrets** periodically
4. **Set short token expiration** for sensitive operations
5. **Monitor access logs** regularly
6. **Restrict trusted IPs** to known addresses only
7. **Use environment variables** for secrets (never hardcode)

## Examples

### Create Entity with JWT

```bash
TOKEN=$(python3 generate-jwt.py | grep "eyJ" | tr -d ' ')

curl -X POST "http://localhost:8080/ngsi-ld/v1/entities" \
  -H "Content-Type: application/ld+json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "@context": "https://uri.etsi.org/ngsi-ld/v1/ngsi-ld-core-context.jsonld",
    "id": "urn:ngsi-ld:Sensor:002",
    "type": "Sensor",
    "value": {
      "type": "Property",
      "value": 42
    }
  }'
```

### Update Entity Attribute

```bash
TOKEN=$(python3 generate-jwt.py | grep "eyJ" | tr -d ' ')

curl -X PATCH "http://localhost:8080/ngsi-ld/v1/entities/urn:ngsi-ld:Sensor:002/attrs" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "value": {
      "type": "Property",
      "value": 100
    }
  }'
```

### Query Entities (No Auth Required)

```bash
curl "http://localhost:8080/ngsi-ld/v1/entities?type=Sensor" \
  -H "Accept: application/json"
```
