# Orion-LD API Gateway

A secure API gateway solution for protecting FIWARE Orion-LD context brokers with JWT-based authentication and IP-based access control.

## Overview

The Orion-LD API Gateway provides a robust security layer in front of your FIWARE Orion-LD context broker, ensuring that only authorized clients can interact with your NGSI-LD APIs. Built on OpenResty (Nginx + Lua), it offers high-performance request processing with sophisticated access control mechanisms.

## Key Features

- **🔒 JWT Authentication** - HS256-based token verification for API access control
- **🌐 IP Whitelisting** - Configure trusted IP addresses for unrestricted access
- **🚫 Method-Level Restrictions** - Fine-grained control over HTTP methods (POST, GET, DELETE, PATCH, PUT)
- **🔄 Reverse Proxy** - Seamless proxying to Orion-LD backend
- **🐳 Docker Deployment** - Complete stack with MongoDB replica set and Orion-LD
- **⚡ High Performance** - Built on OpenResty for minimal latency

## Quick Start

Get started in 3 easy steps:

```bash
# 1. Clone the repository
git clone https://github.com/CTU-SematX/Orion-Nginx.git
cd Orion-Nginx

# 2. Setup environment configuration
make setup
# Edit .env file to update JWT_SECRET and TRUSTED_IP

# 3. Start the services
make start
```

The gateway will be available at `http://localhost:8080`

### Makefile Commands

The project includes a Makefile for easy deployment:

```bash
make help      # View all available commands
make setup     # Create .env file with defaults
make start     # Start all services
make stop      # Stop all services
make restart   # Restart all services
make logs      # View logs from all services
make status    # Show service status
make clean     # Remove all data (WARNING: deletes volumes)
```

## Architecture

```text
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
       ▼
┌─────────────────────┐
│  Gateway (Port 8080)│
│  - IP Check         │
│  - JWT Verify       │
│  - Method Control   │
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  Orion-LD (Port 1026)│
└──────┬──────────────┘
       │
       ▼
┌─────────────────────┐
│  MongoDB Replica Set│
└─────────────────────┘
```

## Access Control

The gateway implements a two-tier security model:

| HTTP Method | Trusted IP | Non-Trusted IP (JWT) |
|-------------|------------|----------------------|
| GET         | ✅ Allowed | ❌ Forbidden         |
| POST        | ✅ Allowed | ❌ Forbidden         |
| PATCH       | ✅ Allowed | ✅ Allowed           |
| PUT         | ✅ Allowed | ✅ Allowed           |
| DELETE      | ✅ Allowed | ❌ Forbidden         |

### Trusted Clients

Clients originating from the configured `TRUSTED_IP` have full access to all operations without authentication. This is ideal for internal data ingestion services.

### Non-Trusted Clients

All other clients must provide a valid JWT token and are restricted to PATCH and PUT operations only. This ensures external clients can update data but cannot create or delete entities.

## Use Cases

### Data Ingestion Pipeline

Use the trusted IP feature for your internal ETL processes:

```bash
curl -X POST "http://localhost:8080/ngsi-ld/v1/entities" \
  -H "Content-Type: application/ld+json" \
  -d '{"id":"urn:ngsi-ld:Sensor:001","type":"Sensor","temperature":{"type":"Property","value":23.5}}'
```

### External API Access

Provide controlled access to external partners with JWT tokens:

```bash
curl -X PATCH "http://localhost:8080/ngsi-ld/v1/entities/urn:ngsi-ld:Sensor:001/attrs" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/ld+json" \
  -d '{"temperature":{"type":"Property","value":24.2}}'
```

## Documentation

- [README](https://github.com/CTU-SematX/Orion-Nginx#readme) - Complete project documentation
- [Security](https://github.com/CTU-SematX/Orion-Nginx/blob/main/SECURITY.md) - Security policy
- [Contributing](https://github.com/CTU-SematX/Orion-Nginx/blob/main/CONTRIBUTING.md) - Contribution guidelines
- [Open Source Checklist](Open_Source_Checklist.md) - Project compliance checklist

## Support

If you encounter issues or have questions:

- 📋 [GitHub Issues](https://github.com/CTU-SematX/Orion-Nginx/issues) - Bug reports and feature requests
- 🔒 [Security Policy](https://github.com/CTU-SematX/Orion-Nginx/blob/main/SECURITY.md) - Report security vulnerabilities
- 💬 [Discussions](https://github.com/CTU-SematX/Orion-Nginx/discussions) - Community support

## License

This project is licensed under the Creative Commons Attribution 4.0 International License.

---

For complete installation instructions, usage examples, and configuration options, see the [main README](https://github.com/CTU-SematX/Orion-Nginx#readme).
