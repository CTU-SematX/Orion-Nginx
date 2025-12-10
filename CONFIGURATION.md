# Orion-Nginx - Cấu hình Access Control Mới

## Tổng quan Logic Bảo mật

Hệ thống đã được cấu hình lại với logic access control như sau:

### 📋 Bảng phân quyền

| HTTP Method | Mọi người | Trusted IPs | Non-Trusted + JWT |
|-------------|-----------|-------------|-------------------|
| **GET**     | ✅ Cho phép | ✅ Cho phép | ✅ Cho phép |
| **POST**    | ❌ Cấm    | ✅ Cho phép | ❌ Cấm |
| **DELETE**  | ❌ Cấm    | ✅ Cho phép | ❌ Cấm |
| **PATCH**   | ❌ Cấm    | ✅ Cho phép | ✅ Cho phép (nếu `AUTHENTICATION_ENABLED=true`) |
| **PUT**     | ❌ Cấm    | ✅ Cho phép | ✅ Cho phép (nếu `AUTHENTICATION_ENABLED=true`) |

### 🔑 Chi tiết Logic

1. **GET**: Mở cho tất cả mọi người, không cần xác thực
   - Mục đích: Cho phép đọc dữ liệu công khai

2. **POST/DELETE**: Chỉ Trusted IPs
   - Mục đích: Bảo vệ việc tạo mới và xóa dữ liệu
   - Chỉ internal services (data ingestion) mới được phép

3. **PATCH/PUT**: Trusted IPs hoặc JWT-authenticated servers
   - Trusted IPs: Toàn quyền cập nhật
   - Non-Trusted IPs: 
     - Nếu `AUTHENTICATION_ENABLED=false` → Cho phép (development mode)
     - Nếu `AUTHENTICATION_ENABLED=true` → Yêu cầu JWT token hợp lệ

## ⚙️ Cấu hình

### File `.env`

```bash
# Bật/tắt JWT authentication cho non-trusted IPs
AUTHENTICATION_ENABLED=false

# JWT secret (bắt buộc nếu AUTHENTICATION_ENABLED=true)
JWT_SECRET=your-secret-key-here

# Danh sách Trusted IPs (phân cách bằng dấu phẩy)
TRUSTED_IPS=127.0.0.1,172.18.0.1,10.0.0.5
```

### Hỗ trợ Multiple Trusted IPs

Hệ thống giờ hỗ trợ nhiều trusted IPs:

```bash
# Localhost + Docker bridge + Internal server
TRUSTED_IPS=127.0.0.1,172.18.0.1,10.0.0.5,192.168.1.100
```

Các IPs này có **toàn quyền** (GET, POST, PUT, PATCH, DELETE) mà không cần JWT.

## 🚀 Sử dụng

### 1. Setup và Start

```bash
# Tạo file .env với cấu hình mặc định
make setup

# Chỉnh sửa docker/.env theo nhu cầu
nano docker/.env

# Khởi động services
make start
```

### 2. Kiểm tra IP của Docker

```bash
# Tìm Docker bridge IP
docker network inspect bridge | grep Gateway

# Hoặc check IP của container
docker inspect gateway | grep IPAddress
```

### 3. Test các scenarios

#### Scenario 1: GET từ bất kỳ đâu (không cần auth)

```bash
# Từ bất kỳ IP nào
curl -X GET http://localhost:8080/ngsi-ld/v1/entities
# ✅ Thành công
```

#### Scenario 2: POST từ Trusted IP

```bash
# Từ localhost (trong TRUSTED_IPS)
curl -X POST http://localhost:8080/ngsi-ld/v1/entities \
  -H "Content-Type: application/ld+json" \
  -d '{
    "id": "urn:ngsi-ld:Device:001",
    "type": "Device",
    "temperature": {"type": "Property", "value": 25.0},
    "@context": ["https://uri.etsi.org/ngsi-ld/v1/ngsi-ld-core-context.jsonld"]
  }'
# ✅ Thành công (vì localhost trong TRUSTED_IPS)
```

#### Scenario 3: POST từ Non-Trusted IP

```bash
# Từ external IP (không trong TRUSTED_IPS)
curl -X POST http://external-server:8080/ngsi-ld/v1/entities \
  -H "Content-Type: application/ld+json" \
  -d '{...}'
# ❌ 403 Forbidden: "POST/DELETE only allowed for trusted IPs"
```

#### Scenario 4: PATCH từ Non-Trusted IP với AUTHENTICATION_ENABLED=false

```bash
# Từ external IP, authentication disabled
curl -X PATCH http://localhost:8080/ngsi-ld/v1/entities/urn:ngsi-ld:Device:001/attrs \
  -H "Content-Type: application/ld+json" \
  -d '{
    "temperature": {"type": "Property", "value": 30.0},
    "@context": ["https://uri.etsi.org/ngsi-ld/v1/ngsi-ld-core-context.jsonld"]
  }'
# ✅ Thành công (vì AUTHENTICATION_ENABLED=false)
```

#### Scenario 5: PATCH từ Non-Trusted IP với AUTHENTICATION_ENABLED=true

```bash
# Set trong .env: AUTHENTICATION_ENABLED=true
# Restart: make restart

# Không có JWT token
curl -X PATCH http://localhost:8080/ngsi-ld/v1/entities/urn:ngsi-ld:Device:001/attrs \
  -H "Content-Type: application/ld+json" \
  -d '{...}'
# ❌ 401 Unauthorized: "missing Authorization header"

# Với JWT token hợp lệ
curl -X PATCH http://localhost:8080/ngsi-ld/v1/entities/urn:ngsi-ld:Device:001/attrs \
  -H "Authorization: Bearer eyJhbGc..." \
  -H "Content-Type: application/ld+json" \
  -d '{...}'
# ✅ Thành công
```

## 🔐 JWT Token Generation

Khi `AUTHENTICATION_ENABLED=true`, servers cần JWT để PATCH/PUT:

### Python

```python
import jwt
import datetime

secret = "your-secret-key-here"  # Phải giống JWT_SECRET trong .env

payload = {
    "sub": "external-server-001",
    "iat": datetime.datetime.utcnow(),
    "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=24)
}

token = jwt.encode(payload, secret, algorithm="HS256")
print(f"Bearer {token}")
```

### Node.js

```javascript
const jwt = require('jsonwebtoken');

const secret = 'your-secret-key-here';  // Phải giống JWT_SECRET trong .env

const payload = {
    sub: 'external-server-001',
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + (24 * 60 * 60)
};

const token = jwt.sign(payload, secret, { algorithm: 'HS256' });
console.log(`Bearer ${token}`);
```

## 📊 Use Cases

### Use Case 1: Development Environment

```bash
AUTHENTICATION_ENABLED=false
TRUSTED_IPS=127.0.0.1,172.18.0.1
```

- Localhost có toàn quyền (POST/DELETE/PATCH/PUT/GET)
- External servers có thể PATCH/PUT mà không cần JWT (tiện cho dev)
- GET mở cho mọi người

### Use Case 2: Production Environment

```bash
AUTHENTICATION_ENABLED=true
TRUSTED_IPS=10.0.0.5,10.0.0.6  # Internal data ingestion servers
JWT_SECRET=super-strong-secret-key-2024-abcdef123456789
```

- Internal servers (10.0.0.5, 10.0.0.6) có toàn quyền
- External servers phải có JWT để PATCH/PUT
- GET mở cho mọi người (public read)
- POST/DELETE chỉ internal servers

### Use Case 3: Fully Restricted

```bash
AUTHENTICATION_ENABLED=true
TRUSTED_IPS=10.0.0.5  # Chỉ 1 internal server
```

- Chỉ 10.0.0.5 mới POST/DELETE được
- Servers khác phải JWT để PATCH/PUT
- GET vẫn public

## 🔍 Logging

Logs chi tiết trong gateway container:

```bash
# Xem logs real-time
make logs

# Hoặc chỉ gateway
docker logs -f gateway
```

Log format:
```
[INFO] [ACCESS] remote_ip=127.0.0.1 method=POST auth_enabled=false
[INFO] [ACCESS] is_trusted=true
[INFO] [ACCESS] POST/DELETE allowed for trusted IP
```

```
[INFO] [ACCESS] remote_ip=192.168.1.50 method=PATCH auth_enabled=true
[INFO] [ACCESS] is_trusted=false
[INFO] [ACCESS] PATCH/PUT requires JWT for non-trusted IP
[INFO] [ACCESS] PATCH/PUT allowed with valid JWT
```

## ⚠️ Lưu ý quan trọng

1. **Restart sau khi đổi .env**:
   ```bash
   make restart
   ```

2. **Whitespace trong TRUSTED_IPS**: Hệ thống tự động trim, nên các format sau đều OK:
   ```bash
   TRUSTED_IPS=127.0.0.1,172.18.0.1
   TRUSTED_IPS=127.0.0.1, 172.18.0.1
   TRUSTED_IPS= 127.0.0.1 , 172.18.0.1 
   ```

3. **JWT_SECRET bảo mật**: 
   - Dùng secret mạnh (32+ ký tự)
   - Không commit vào git
   - Khác nhau giữa dev/production

4. **AUTHENTICATION_ENABLED**:
   - `false` → Dev mode, tiện test
   - `true` → Production, bắt buộc JWT

## 📝 Migration từ config cũ

Nếu bạn có file `.env` cũ:

```bash
# Cũ
TRUSTED_IP=172.18.0.1

# Mới (thêm AUTHENTICATION_ENABLED và đổi sang TRUSTED_IPS)
AUTHENTICATION_ENABLED=false
TRUSTED_IPS=127.0.0.1,172.18.0.1
```

Chạy:
```bash
make restart
```

## 🎯 Kết luận

Logic mới linh hoạt hơn:
- ✅ GET public (dễ integration)
- ✅ POST/DELETE chỉ trusted (bảo vệ data)
- ✅ PATCH/PUT cho servers (với/không JWT tùy mode)
- ✅ Multiple trusted IPs (scale được)
- ✅ Toggle JWT auth dễ dàng (dev/prod)
