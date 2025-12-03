 

🌐 English | [Tiếng Việt](./README.vi.md)
# Orion-Nginx

**Description**: A secure API gateway solution for protecting FIWARE Orion-LD context brokers with JWT-based authentication and IP-based access control. This project provides a proxy layer that ensures only authorized clients can interact with your Orion-LD instance, preventing unauthorized data ingestion and reducing security risks when exposing NGSI-LD APIs to external environments.

**Key Features**:

- 🔒 JWT-based authentication for API access control
- 🌐 IP whitelisting for trusted clients
- 🚫 Method-level access restrictions (POST, GET, DELETE control)
- 🔄 Seamless reverse proxy to Orion-LD
- 🐳 Docker-based deployment with MongoDB replica set
- ⚡ Built on OpenResty (Nginx + Lua) for high performance

## Table of Contents

- [Installation and Requirements](#installation-and-requirements)
- [Quickstart Instructions](#quick-start-instructions)
- [Usage](#usage)
- [Known Issues](#known-issues)
- [Support](#support)
- [Contributing](#contributing)
- [Development](#development)
- [License](#license)
- [Maintainers](#maintainers)
- [Credits and References](#credits-and-references)

## Installation and Requirements

### Prerequisites

- Docker Engine 20.10 or higher
- Docker Compose V2
- 4GB RAM minimum (8GB recommended)
- Ports 8080, 1026, and 27017 available

### System Requirements

The gateway consists of three main components:

1. **MongoDB 5.0.26** - Database backend with replica set
2. **Orion-LD** - FIWARE NGSI-LD context broker
3. **Gateway** - OpenResty-based proxy with JWT authentication

## Quick start instructions

1. **Clone the repository**

   ```bash
   git clone https://github.com/CTU-SematX/Orion-Nginx.git
   cd Orion-Nginx
   ```

2. **Set up environment variables**

   Use the Makefile to create the `.env` file:

   ```bash
   make setup
   ```

   Then edit the `.env` file to update the values:

   ```bash
   JWT_SECRET=your-secret-key-here
   TRUSTED_IP=172.18.0.1
   ```

   > Replace `your-secret-key-here` with a strong secret for JWT signing
   > Replace `TRUSTED_IP` with the IP address of your trusted client

3. **Start the services**

   ```bash
   make start
   ```

   This command will:
   - Start MongoDB and initialize the replica set
   - Start Orion-LD context broker
   - Build and start the gateway proxy

The gateway will be available at `http://localhost:8080`

### Managing Services

Use these Makefile commands to manage your deployment:

```bash
# View all available commands
make help

# Start all services
make start

# Stop all services
make stop

# Restart all services
make restart

# View logs from all services
make logs

# Check service status
make status

# Remove all data (WARNING: deletes everything)
make clean
```

## Usage

The gateway implements a two-tier access control system based on client IP addresses and JWT authentication.

### Access Control Rules

| HTTP Method | Trusted IP | Non-Trusted IP (with JWT) |
|-------------|------------|---------------------------|
| GET         | ✅ Allowed | ❌ Forbidden              |
| POST        | ✅ Allowed | ❌ Forbidden              |
| PATCH       | ✅ Allowed | ✅ Allowed                |
| PUT         | ✅ Allowed | ✅ Allowed                |
| DELETE      | ✅ Allowed | ❌ Forbidden              |

### For Trusted Clients

If your request originates from the configured `TRUSTED_IP`, all operations are allowed without authentication:

```bash
# Create an entity (POST)
curl -X POST "http://localhost:8080/ngsi-ld/v1/entities" \
  -H "Content-Type: application/ld+json" \
  -d '{
    "id": "urn:ngsi-ld:WeatherObserved:001",
    "type": "WeatherObserved",
    "temperature": {
      "type": "Property",
      "value": 25.0
    },
    "@context": [
      "https://uri.etsi.org/ngsi-ld/v1/ngsi-ld-core-context.jsonld"
    ]
  }'

# Query entities (GET)
curl -X GET "http://localhost:8080/ngsi-ld/v1/entities/urn:ngsi-ld:WeatherObserved:001"

# Delete an entity (DELETE)
curl -X DELETE "http://localhost:8080/ngsi-ld/v1/entities/urn:ngsi-ld:WeatherObserved:001"
```

### For Non-Trusted Clients

Non-trusted clients must provide a valid JWT token and can only use PATCH and PUT operations:

```bash
# Generate a JWT token (example using a tool or script)
export JWT_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Update entity attributes (PATCH) - Allowed with JWT
curl -X PATCH "http://localhost:8080/ngsi-ld/v1/entities/urn:ngsi-ld:WeatherObserved:001/attrs" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/ld+json" \
  -d '{
    "@context": [
      "https://uri.etsi.org/ngsi-ld/v1/ngsi-ld-core-context.jsonld"
    ],
    "temperature": {
      "type": "Property",
      "value": 31.0
    }
  }'

# Replace entity (PUT) - Allowed with JWT
curl -X PUT "http://localhost:8080/ngsi-ld/v1/entities/urn:ngsi-ld:WeatherObserved:001" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/ld+json" \
  -d '{
    "id": "urn:ngsi-ld:WeatherObserved:001",
    "type": "WeatherObserved",
    "temperature": {
      "type": "Property",
      "value": 28.0
    },
    "@context": [
      "https://uri.etsi.org/ngsi-ld/v1/ngsi-ld-core-context.jsonld"
    ]
  }'

# POST operations are forbidden - Will return 403 Forbidden
curl -X POST "http://localhost:8080/ngsi-ld/v1/entities" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/ld+json" \
  -d '...'
# Returns: {"error":"forbidden","reason":"POST not allowed from this IP"}
```

### Generating JWT Tokens

JWT tokens must be signed with the `JWT_SECRET` using the HS256 algorithm. Here's an example using Python:

```python
import jwt
import datetime

secret = "your-secret-key-here"  # Must match JWT_SECRET in .env

payload = {
    "sub": "client-001",
    "iat": datetime.datetime.utcnow(),
    "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=24)
}

token = jwt.encode(payload, secret, algorithm="HS256")
print(token)
```

Or using Node.js:

```javascript
const jwt = require('jsonwebtoken');

const secret = 'your-secret-key-here';  // Must match JWT_SECRET in .env

const payload = {
    sub: 'client-001',
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + (24 * 60 * 60)
};

const token = jwt.sign(payload, secret, { algorithm: 'HS256' });
console.log(token);
```

## Architecture

### Component Overview

```text
            ┌─────────────┐
            │   Client    │
            └──────┬──────┘
                   │
                   │ HTTP Request
                   ▼
┌─────────────────────────────────────────┐
│         Gateway (OpenResty)             │
│  ┌────────────────────────────────┐     │
│  │   IP-based Access Control      │     │
│  │   + JWT Verification (Lua)     │     │
│  └────────────────────────────────┘     │
│               ▼                         │
│  ┌────────────────────────────────┐     │
│  │      Reverse Proxy             │     │
│  └────────────────────────────────┘     │
└──────────────────┬──────────────────────┘
                   │
                   ▼
            ┌──────────────┐
            │  Orion-LD    │
            │  (Port 1026) │
            └──────┬───────┘
                   │
                   ▼
            ┌──────────────┐
            │   MongoDB    │
            │  Replica Set │
            └──────────────┘
```

### Security Flow

1. **Request Reception**: Client sends HTTP request to gateway (port 8080)
2. **IP Verification**: Gateway checks if request originates from `TRUSTED_IP`
   - If yes: Allow all operations → Forward to Orion-LD
   - If no: Proceed to method and JWT checks
3. **Method Verification**: For non-trusted IPs:
   - POST, GET, DELETE → Immediately reject (403 Forbidden)
   - PATCH, PUT → Require JWT verification
4. **JWT Verification**: Validate JWT token in `Authorization: Bearer` header
   - Valid token → Forward request to Orion-LD
   - Invalid/missing token → Reject (401 Unauthorized)
5. **Proxy to Orion-LD**: Authorized requests are proxied to Orion-LD backend
6. **Response**: Orion-LD response is returned to client

## Security Model

### Trust Model

The gateway implements a two-tier security model:

1. **Trusted Clients** (Whitelisted IP)
   - Identified by IP address matching `TRUSTED_IP`
   - Full access to all HTTP methods (GET, POST, PATCH, PUT, DELETE)
   - No authentication required
   - Intended for internal data ingestion services

2. **Non-Trusted Clients** (External)
   - All other IP addresses
   - Must provide valid JWT for PATCH and PUT operations
   - POST, GET, and DELETE operations are blocked
   - Intended for external API consumers with limited write access

### Security Best Practices

1. **JWT Secret Management**
   - Use a strong, randomly generated secret (minimum 32 characters)
   - Store `JWT_SECRET` in environment variables, never in code
   - Rotate secrets periodically
   - Use different secrets for development and production

2. **Network Security**
   - Run the gateway behind a reverse proxy with SSL/TLS termination
   - Use firewall rules to restrict access to MongoDB and Orion-LD ports
   - Only expose port 8080 (gateway) to external networks
   - Consider using Docker networks to isolate services

3. **Token Management**
   - Implement token expiration (recommended: 1-24 hours)
   - Use short-lived tokens and implement refresh token mechanism
   - Include appropriate claims (sub, iat, exp) in JWT payload
   - Monitor and log authentication attempts

4. **Production Deployment**
   - Use HTTPS for all external communications
   - Implement rate limiting at the reverse proxy level
   - Enable audit logging for compliance requirements
   - Regular security updates for all container images

## Configuration

### Environment Variables

| Variable | Description | Example | Required |
|----------|-------------|---------|----------|
| `JWT_SECRET` | Secret key for JWT signing and verification | `my-super-secret-key-2024` | Yes |
| `TRUSTED_IP` | IP address allowed full access without authentication | `172.18.0.1` | Yes |

### Finding Your Docker Network IP

To determine the correct `TRUSTED_IP` for Docker-based trusted clients:

```bash
# Find your Docker bridge network IP
docker network inspect bridge | grep Gateway

# Or check your client container's IP
docker inspect <container-name> | grep IPAddress
```

### Customizing Nginx Configuration

The gateway configuration is located in:

- Main config: `docker/nginx/nginx.conf`
- Gateway rules: `docker/nginx/conf.d/gateway.conf`
- JWT verification: `docker/lualib/jwt_verify.lua`

To modify access rules, edit `gateway.conf` and rebuild the gateway container:

```bash
docker compose -f docker/docker-compose.yml build gateway
docker compose -f docker/docker-compose.yml up -d gateway
```

## Known issues

**Current Limitations**:

- Single trusted IP support only (no multiple IP whitelisting)
- No Role-Based Access Control (RBAC) system
- No rate limiting or throttling
- No per-entity or per-attribute authorization
- JWT tokens have no built-in revocation mechanism
- No audit logging of access attempts

## Troubleshooting

### Common Issues

#### Gateway returns 401 Unauthorized

- Verify JWT token is properly formatted: `Authorization: Bearer <token>`
- Check that `JWT_SECRET` matches between token generation and gateway
- Ensure JWT token hasn't expired
- Validate JWT algorithm is HS256

#### Gateway returns 403 Forbidden

- Verify client IP is not trying to use POST, GET, or DELETE operations
- If using trusted IP, check that `TRUSTED_IP` matches client's actual IP
- Check gateway logs: `docker logs gateway`

#### Cannot connect to gateway

```bash
# Check if all services are running
docker compose ps

# Check gateway logs
docker logs gateway

# Check if port 8080 is accessible
curl -v http://localhost:8080/version
```

#### MongoDB replica set issues

```bash
# Verify replica set status
docker exec -it mongo mongosh --eval "rs.status()"

# Reinitialize if needed
./start.sh
```

#### View detailed logs

```bash
# Gateway logs (includes Lua debug output)
docker logs -f gateway

# Orion-LD logs
docker logs -f orion-ld

# MongoDB logs
docker logs -f mongo
```

## Support

If you have questions, concerns, bug reports, or feature requests, please file an issue in this repository's Issue Tracker.

For security vulnerabilities, please see [SECURITY.md](SECURITY.md) for responsible disclosure procedures.

## Contributing

This section should detail why people should get involved and describe key areas you are
currently focusing on; e.g., trying to get feedback on features, fixing certain bugs, building
important pieces, etc.

General instructions on _how_ to contribute should be stated with a link to [CONTRIBUTING](CONTRIBUTING.md).

## Development

### Project Structure

```text
Orion-Nginx/
├── Makefile                    # Build and management commands
├── README.md                   # Main documentation
├── README.vi.md                # Vietnamese documentation
├── LICENSE                     # Project license
├── SECURITY.md                 # Security reporting guidelines
├── CODE_OF_CONDUCT.md          # Community guidelines
├── CONTRIBUTING.md             # Contribution guidelines
├── GOVERNANCE.md               # Project governance
├── docker/                     # Docker-related files
│   ├── docker-compose.yml      # Multi-container orchestration
│   ├── Dockerfile              # Gateway container build definition
│   ├── .env.example            # Environment variables template
│   ├── lualib/
│   │   └── jwt_verify.lua      # JWT verification logic
│   └── nginx/
│       ├── nginx.conf          # Main Nginx configuration
│       └── conf.d/
│           └── gateway.conf    # Gateway routing and access control
├── docs/                       # MkDocs documentation
│   ├── en/                     # English documentation
│   └── vi/                     # Vietnamese documentation
├── mkdocs.yml                  # MkDocs configuration
└── requirements.txt            # Python dependencies for docs
```

### Modifying Access Control Logic

The main access control logic is in `docker/nginx/conf.d/gateway.conf`:

```lua
-- Example: Adding a new allowed method for non-trusted IPs
if method == "POST" or method == "GET" or method == "DELETE" then
    -- Modify this condition to change blocked methods
    ngx.status = ngx.HTTP_FORBIDDEN
    -- ...
end
```

### Building Custom Gateway Image

```bash
cd docker

# Build gateway with custom tag
docker compose build gateway --build-arg CUSTOM_ARG=value

# Test changes
docker compose up -d gateway

# View logs
docker logs -f gateway
```

### Running Tests

```bash
# Test JWT verification
docker exec -it gateway /usr/local/openresty/bin/resty /usr/local/openresty/site/lualib/jwt_verify.lua

# Test with curl
./test-endpoints.sh  # Create test script based on Usage examples
```

### Adding New Dependencies

To add new Lua libraries:

1. Update `docker/Dockerfile`:

   ```dockerfile
   RUN /usr/local/openresty/bin/opm get <package-name>
   ```

2. Rebuild container:

   ```bash
   docker compose -f docker/docker-compose.yml build gateway
   ```

For more detailed development guidelines, see [CONTRIBUTING.md](CONTRIBUTING.md).

---

## License

This project is licensed under the Apache License 2.0 - see the [LICENSE](LICENSE) file for details.

---

## Maintainers

Name and git-account for primary maintainer/s:

Example:
_The_maintainers_

## Credits and References

### Related Projects

- [FIWARE Orion-LD](https://github.com/FIWARE/context.Orion-LD) - NGSI-LD Context Broker
- [OpenResty](https://openresty.org/) - High-performance web platform based on Nginx and Lua
- [lua-resty-jwt](https://github.com/SkyLothar/lua-resty-jwt) - JWT authentication library for OpenResty

### Standards and Specifications

- [NGSI-LD API](https://www.etsi.org/deliver/etsi_gs/CIM/001_099/009/01.08.01_60/gs_CIM009v010801p.pdf) - ETSI GS CIM 009 V1.8.1
- [JSON Web Token (JWT) - RFC 7519](https://datatracker.ietf.org/doc/html/rfc7519)
- [FIWARE Documentation](https://fiware-tutorials.readthedocs.io/)

### Acknowledgments

Special thanks to:

- The FIWARE Foundation for the Orion-LD context broker
- The OpenResty community for the powerful web platform
- [IEEE Open Source Maintainers Manual](https://opensource.ieee.org/community/manual/)
