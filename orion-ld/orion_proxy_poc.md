# Orion-LD + Auth Proxy 

## 1. Overview

The system exists to protect Orion-LD from direct external access. It ensures that only one trusted IP can perform unrestricted writes, while all other clients must authenticate using JWT. This prevents incorrect data ingestion, unauthorized requests, and reduces security risks when exposing Orion-LD to broader environments.

This proof of concept (PoC) demonstrates a secure ingestion and query layer in front of an Orion-LD context broker.

Core ideas:

- Orion-LD stores and serves JSON-LD entities.
- All traffic to Orion-LD passes through an HTTP proxy.
- One trusted IP is allowed to bypass authentication and perform all operations (including POST).
- All other clients:
  - Must present a valid JWT for write operations.
  - Are explicitly forbidden from using POST; they must use other methods (e.g. PATCH/PUT) for updates.
  - Reads (GET) require JWT unless rules are relaxed.

## 2. Components

### 2.1 Orion-LD
- Internal NGSI-LD context broker.
- Handles create/update/query of entities.

### 2.2 Auth Proxy
- Entry point for all client traffic.
- Enforces:
  - Trusted IP whitelist.
  - JWT verification.
  - Method restrictions.

### 2.3 Clients
- **Trusted client:** full permissions, no JWT required.
- **Non‑trusted clients:** need JWT, cannot POST.

## 3. Security Model

### 3.1 Trust Model
- `TRUSTED_IP` defines the only IP allowed full access.
- If request originates from trusted IP: bypass authentication.
- Otherwise:
  - POST is always forbidden.
  - Other methods require JWT.

### 3.2 JWT Model
- HS256 tokens.
- Token expected in `Authorization: Bearer <token>`.

## 4. Request Rules

| Method | Trusted IP | Non‑trusted IP |
|--------|------------|----------------|
| GET | allowed | forbidden |
| POST | allowed | forbidden |
| PATCH | allowed | JWT required |
| PUT | allowed | JWT required |
| DELETE | allowed | forbidden |

## 5. Configuration

Environment variables:
- `TRUSTED_IP`
- `ORION_LD_BASE_URL`
- `JWT_SECRET`

Nginx example included in design document.

## 6. Flows

### Trusted IP
- Can POST, PATCH, PUT, DELETE without JWT.

### Non‑trusted client
- Can GET/PATCH/PUT/DELETE with valid JWT.
- POST always blocked.

## 7. Example cURL

### Trusted IP create entity
```
curl -X POST "http://proxy/ngsi-ld/v1/entities"   -H "Content-Type: application/ld+json"   -d '{"id":"urn:ngsi-ld:Weather:1","type":"WeatherObserved"}'
```

### Non‑trusted client update entity
```
curl -X PATCH "http://proxy/ngsi-ld/v1/entities/urn:ngsi-ld:Weather:1/attrs"   -H "Authorization: Bearer $JWT"   -H "Content-Type: application/ld+json"   -d '{"temperature":{"type":"Property","value":31}}'
```

## 8. Limitations & Next Steps
- Only one trusted IP.
- No RBAC.
- No rate limiting.
- No per‑entity authorization.

