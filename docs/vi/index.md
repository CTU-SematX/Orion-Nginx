# Orion-LD API Gateway

[![en](https://img.shields.io/badge/lang-en-blue.svg)](../)
[![vi](https://img.shields.io/badge/lang-vi-red.svg)](./)

**Mô tả**: Giải pháp API gateway bảo mật để bảo vệ FIWARE Orion-LD context brokers với xác thực dựa trên JWT và kiểm soát truy cập dựa trên IP. Dự án này cung cấp một lớp proxy đảm bảo chỉ các client được ủy quyền mới có thể tương tác với Orion-LD instance của bạn, ngăn chặn việc nhập dữ liệu trái phép và giảm rủi ro bảo mật khi expose NGSI-LD APIs ra môi trường bên ngoài.

**Tính năng chính**:

- 🔒 Xác thực dựa trên JWT để kiểm soát truy cập API
- 🌐 Whitelist IP cho các client đáng tin cậy
- 🚫 Hạn chế truy cập theo phương thức HTTP (Kiểm soát POST, GET, DELETE)
- 🔄 Reverse proxy liền mạch đến Orion-LD
- 🐳 Triển khai dựa trên Docker với MongoDB replica set
- ⚡ Xây dựng trên OpenResty (Nginx + Lua) cho hiệu năng cao

## Mục lục

- [Cài đặt và Yêu cầu](#cài-đặt-và-yêu-cầu)
- [Hướng dẫn Bắt đầu Nhanh](#hướng-dẫn-bắt-đầu-nhanh)
- [Sử dụng](#sử-dụng)
- [Các Vấn đề Đã Biết](#các-vấn-đề-đã-biết)
- [Hỗ trợ](#hỗ-trợ)
- [Đóng góp](#đóng-góp)
- [Phát triển](#phát-triển)
- [Giấy phép](#giấy-phép)
- [Người duy trì](#người-duy-trì)
- [Tín chỉ và Tham khảo](#tín-chỉ-và-tham-khảo)

## Cài đặt và Yêu cầu

### Điều kiện tiên quyết

- Docker Engine 20.10 trở lên
- Docker Compose V2
- Tối thiểu 4GB RAM (khuyến nghị 8GB)
- Các cổng 8080, 1026 và 27017 phải khả dụng

### Yêu cầu Hệ thống

Gateway bao gồm ba thành phần chính:

1. **MongoDB 5.0.26** - Database backend với replica set
2. **Orion-LD** - FIWARE NGSI-LD context broker
3. **Gateway** - Proxy dựa trên OpenResty với xác thực JWT

## Hướng dẫn Bắt đầu Nhanh

1. **Clone repository**

   ```bash
   git clone https://github.com/CTU-SematX/Orion-Nginx.git
   cd Orion-Nginx
   ```

2. **Thiết lập biến môi trường**

   Sử dụng Makefile để tạo file `.env`:

   ```bash
   make setup
   ```

   Sau đó chỉnh sửa file `.env` để cập nhật các giá trị:

   ```bash
   JWT_SECRET=your-secret-key-here
   TRUSTED_IP=172.18.0.1
   ```

   > Thay thế `your-secret-key-here` bằng một secret key mạnh để ký JWT
   > Thay thế `TRUSTED_IP` bằng địa chỉ IP của client đáng tin cậy

3. **Khởi động các dịch vụ**

   ```bash
   make start
   ```

   Lệnh này sẽ:
   - Khởi động MongoDB và khởi tạo replica set
   - Khởi động Orion-LD context broker
   - Build và khởi động gateway proxy

Gateway sẽ khả dụng tại `http://localhost:8080`

### Quản lý Dịch vụ

Sử dụng các lệnh Makefile để quản lý triển khai của bạn:

```bash
# Xem tất cả các lệnh khả dụng
make help

# Khởi động tất cả dịch vụ
make start

# Dừng tất cả dịch vụ
make stop

# Khởi động lại tất cả dịch vụ
make restart

# Xem logs từ tất cả dịch vụ
make logs

# Kiểm tra trạng thái dịch vụ
make status

# Xóa tất cả dữ liệu (CẢNH BÁO: xóa mọi thứ)
make clean
```

## Sử dụng

Gateway triển khai hệ thống kiểm soát truy cập hai cấp dựa trên địa chỉ IP của client và xác thực JWT.

### Quy tắc Kiểm soát Truy cập

| Phương thức HTTP | IP Đáng tin cậy | IP Không đáng tin cậy (với JWT) |
|------------------|-----------------|----------------------------------|
| GET              | ✅ Cho phép     | ❌ Cấm                           |
| POST             | ✅ Cho phép     | ❌ Cấm                           |
| PATCH            | ✅ Cho phép     | ✅ Cho phép                      |
| PUT              | ✅ Cho phép     | ✅ Cho phép                      |
| DELETE           | ✅ Cho phép     | ❌ Cấm                           |

### Dành cho Client Đáng tin cậy

Nếu request của bạn xuất phát từ `TRUSTED_IP` đã cấu hình, tất cả các thao tác được cho phép mà không cần xác thực:

```bash
# Tạo một entity (POST)
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

# Truy vấn entities (GET)
curl -X GET "http://localhost:8080/ngsi-ld/v1/entities/urn:ngsi-ld:WeatherObserved:001"

# Xóa một entity (DELETE)
curl -X DELETE "http://localhost:8080/ngsi-ld/v1/entities/urn:ngsi-ld:WeatherObserved:001"
```

### Dành cho Client Không đáng tin cậy

Client không đáng tin cậy phải cung cấp JWT token hợp lệ và chỉ có thể sử dụng các thao tác PATCH và PUT:

```bash
# Tạo JWT token (ví dụ sử dụng tool hoặc script)
export JWT_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."

# Cập nhật thuộc tính entity (PATCH) - Được phép với JWT
curl -X PATCH "http://localhost:8080/ngsi-ld/v1/entities/urn:ngsi-ld:WeatherObserved:001/attrs" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/ld+json" \
  -d '{
    "temperature": {
      "type": "Property",
      "value": 31.0
    }
  }'

# Thay thế entity (PUT) - Được phép với JWT
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

# Thao tác POST bị cấm - Sẽ trả về 403 Forbidden
curl -X POST "http://localhost:8080/ngsi-ld/v1/entities" \
  -H "Authorization: Bearer $JWT_TOKEN" \
  -H "Content-Type: application/ld+json" \
  -d '...'
# Trả về: {"error":"forbidden","reason":"POST not allowed from this IP"}
```

### Tạo JWT Tokens

JWT tokens phải được ký bằng `JWT_SECRET` sử dụng thuật toán HS256. Đây là ví dụ sử dụng Python:

```python
import jwt
import datetime

secret = "your-secret-key-here"  # Phải khớp với JWT_SECRET trong .env

payload = {
    "sub": "client-001",
    "iat": datetime.datetime.utcnow(),
    "exp": datetime.datetime.utcnow() + datetime.timedelta(hours=24)
}

token = jwt.encode(payload, secret, algorithm="HS256")
print(token)
```

Hoặc sử dụng Node.js:

```javascript
const jwt = require('jsonwebtoken');

const secret = 'your-secret-key-here';  // Phải khớp với JWT_SECRET trong .env

const payload = {
    sub: 'client-001',
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + (24 * 60 * 60)
};

const token = jwt.sign(payload, secret, { algorithm: 'HS256' });
console.log(token);
```

## Kiến trúc

### Tổng quan Thành phần

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
│  │   Kiểm soát Truy cập theo IP   │     │
│  │   + Xác thực JWT (Lua)         │     │
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
            │  (Cổng 1026) │
            └──────┬───────┘
                   │
                   ▼
            ┌──────────────┐
            │   MongoDB    │
            │  Replica Set │
            └──────────────┘
```

### Luồng Bảo mật

1. **Nhận Request**: Client gửi HTTP request đến gateway (cổng 8080)
2. **Xác minh IP**: Gateway kiểm tra xem request có xuất phát từ `TRUSTED_IP` không
   - Nếu có: Cho phép tất cả thao tác → Chuyển tiếp đến Orion-LD
   - Nếu không: Tiếp tục kiểm tra phương thức và JWT
3. **Xác minh Phương thức**: Đối với IP không đáng tin cậy:
   - POST, GET, DELETE → Từ chối ngay lập tức (403 Forbidden)
   - PATCH, PUT → Yêu cầu xác thực JWT
4. **Xác thực JWT**: Xác thực JWT token trong header `Authorization: Bearer`
   - Token hợp lệ → Chuyển tiếp request đến Orion-LD
   - Token không hợp lệ/thiếu → Từ chối (401 Unauthorized)
5. **Proxy đến Orion-LD**: Các request được ủy quyền được proxy đến Orion-LD backend
6. **Phản hồi**: Phản hồi từ Orion-LD được trả về cho client

## Mô hình Bảo mật

### Mô hình Tin cậy

Gateway triển khai mô hình bảo mật hai cấp:

1. **Client Đáng tin cậy** (IP trong Whitelist)
   - Được xác định bằng địa chỉ IP khớp với `TRUSTED_IP`
   - Truy cập đầy đủ vào tất cả phương thức HTTP (GET, POST, PATCH, PUT, DELETE)
   - Không yêu cầu xác thực
   - Dành cho các dịch vụ nhập dữ liệu nội bộ

2. **Client Không đáng tin cậy** (Bên ngoài)
   - Tất cả các địa chỉ IP khác
   - Phải cung cấp JWT hợp lệ cho các thao tác PATCH và PUT
   - Các thao tác POST, GET và DELETE bị chặn
   - Dành cho người tiêu dùng API bên ngoài với quyền ghi hạn chế

### Thực hành Tốt nhất về Bảo mật

1. **Quản lý JWT Secret**
   - Sử dụng secret mạnh, được tạo ngẫu nhiên (tối thiểu 32 ký tự)
   - Lưu trữ `JWT_SECRET` trong biến môi trường, không bao giờ trong code
   - Xoay vòng secrets định kỳ
   - Sử dụng secrets khác nhau cho development và production

2. **Bảo mật Mạng**
   - Chạy gateway phía sau reverse proxy với SSL/TLS termination
   - Sử dụng firewall rules để hạn chế truy cập vào cổng MongoDB và Orion-LD
   - Chỉ expose cổng 8080 (gateway) ra mạng bên ngoài
   - Cân nhắc sử dụng Docker networks để cô lập các dịch vụ

3. **Quản lý Token**
   - Triển khai token expiration (khuyến nghị: 1-24 giờ)
   - Sử dụng token tồn tại ngắn và triển khai cơ chế refresh token
   - Bao gồm các claims phù hợp (sub, iat, exp) trong JWT payload
   - Giám sát và log các nỗ lực xác thực

4. **Triển khai Production**
   - Sử dụng HTTPS cho tất cả giao tiếp bên ngoài
   - Triển khai rate limiting ở cấp reverse proxy
   - Bật audit logging cho yêu cầu tuân thủ
   - Cập nhật bảo mật thường xuyên cho tất cả container images

## Cấu hình

### Biến Môi trường

| Biến | Mô tả | Ví dụ | Bắt buộc |
|------|-------|-------|----------|
| `JWT_SECRET` | Secret key để ký và xác thực JWT | `my-super-secret-key-2024` | Có |
| `TRUSTED_IP` | Địa chỉ IP được phép truy cập đầy đủ mà không cần xác thực | `172.18.0.1` | Có |

### Tìm Docker Network IP của bạn

Để xác định `TRUSTED_IP` chính xác cho các client đáng tin cậy dựa trên Docker:

```bash
# Tìm Docker bridge network IP của bạn
docker network inspect bridge | grep Gateway

# Hoặc kiểm tra IP của container client
docker inspect <container-name> | grep IPAddress
```

### Tùy chỉnh Cấu hình Nginx

Cấu hình gateway nằm ở:

- Cấu hình chính: `docker/nginx/nginx.conf`
- Quy tắc gateway: `docker/nginx/conf.d/gateway.conf`
- Xác thực JWT: `docker/lualib/jwt_verify.lua`

Để sửa đổi quy tắc truy cập, chỉnh sửa `gateway.conf` và rebuild gateway container:

```bash
docker compose -f docker/docker-compose.yml build gateway
docker compose -f docker/docker-compose.yml up -d gateway
```

## Các Vấn đề Đã Biết

**Giới hạn Hiện tại**:

- Chỉ hỗ trợ một IP đáng tin cậy (không có whitelist nhiều IP)
- Không có hệ thống Role-Based Access Control (RBAC)
- Không có rate limiting hoặc throttling
- Không có ủy quyền theo entity hoặc attribute
- JWT tokens không có cơ chế thu hồi tích hợp
- Không có audit logging của các nỗ lực truy cập

## Xử lý Sự cố

### Các Vấn đề Thường gặp

#### Gateway trả về 401 Unauthorized

- Xác minh JWT token được định dạng đúng: `Authorization: Bearer <token>`
- Kiểm tra `JWT_SECRET` khớp giữa việc tạo token và gateway
- Đảm bảo JWT token chưa hết hạn
- Xác thực thuật toán JWT là HS256

#### Gateway trả về 403 Forbidden

- Xác minh client IP không cố gắng sử dụng các thao tác POST, GET hoặc DELETE
- Nếu sử dụng trusted IP, kiểm tra `TRUSTED_IP` khớp với IP thực tế của client
- Kiểm tra gateway logs: `docker logs gateway`

#### Không thể kết nối đến gateway

```bash
# Kiểm tra xem tất cả dịch vụ có đang chạy không
docker compose ps

# Kiểm tra gateway logs
docker logs gateway

# Kiểm tra xem cổng 8080 có thể truy cập không
curl -v http://localhost:8080/version
```

#### Vấn đề MongoDB replica set

```bash
# Xác minh trạng thái replica set
docker exec -it mongo mongosh --eval "rs.status()"

# Khởi tạo lại nếu cần
./start.sh
```

#### Xem logs chi tiết

```bash
# Gateway logs (bao gồm Lua debug output)
docker logs -f gateway

# Orion-LD logs
docker logs -f orion-ld

# MongoDB logs
docker logs -f mongo
```

## Hỗ trợ

Nếu bạn có câu hỏi, quan ngại, báo cáo lỗi hoặc yêu cầu tính năng, vui lòng tạo một issue trong Issue Tracker của repository này.

Đối với các lỗ hổng bảo mật, vui lòng xem [SECURITY.md](https://github.com/CTU-SematX/Orion-Nginx/blob/main/SECURITY.md) để biết quy trình công bố có trách nhiệm.

## Đóng góp

Phần này nên chi tiết lý do mọi người nên tham gia và mô tả các lĩnh vực chính mà bạn
hiện đang tập trung vào; ví dụ: cố gắng nhận phản hồi về tính năng, sửa một số lỗi nhất định, xây dựng
các phần quan trọng, v.v.

Hướng dẫn chung về _cách_ đóng góp nên được nêu rõ với liên kết đến [CONTRIBUTING](https://github.com/CTU-SematX/Orion-Nginx/blob/main/CONTRIBUTING.md).

## Phát triển

### Cấu trúc Dự án

```text
Orion-Nginx/
├── Makefile                    # Các lệnh build và quản lý
├── README.md                   # Tài liệu chính
├── README.vi.md                # Tài liệu tiếng Việt
├── LICENSE                     # Giấy phép dự án
├── SECURITY.md                 # Hướng dẫn báo cáo bảo mật
├── CODE_OF_CONDUCT.md          # Quy tắc cộng đồng
├── CONTRIBUTING.md             # Hướng dẫn đóng góp
├── GOVERNANCE.md               # Quản trị dự án
├── docker/                     # Các file Docker
│   ├── docker-compose.yml      # Orchestration multi-container
│   ├── Dockerfile              # Gateway container build definition
│   ├── .env.example            # Template biến môi trường
│   ├── lualib/
│   │   └── jwt_verify.lua      # Logic xác thực JWT
│   └── nginx/
│       ├── nginx.conf          # Cấu hình Nginx chính
│       └── conf.d/
│           └── gateway.conf    # Gateway routing và kiểm soát truy cập
├── docs/                       # Tài liệu MkDocs
│   ├── en/                     # Tài liệu tiếng Anh
│   └── vi/                     # Tài liệu tiếng Việt
├── mkdocs.yml                  # Cấu hình MkDocs
└── requirements.txt            # Dependencies Python cho docs
```

### Sửa đổi Logic Kiểm soát Truy cập

Logic kiểm soát truy cập chính nằm trong `docker/nginx/conf.d/gateway.conf`:

```lua
-- Ví dụ: Thêm phương thức được phép mới cho IP không đáng tin cậy
if method == "POST" or method == "GET" or method == "DELETE" then
    -- Sửa đổi điều kiện này để thay đổi các phương thức bị chặn
    ngx.status = ngx.HTTP_FORBIDDEN
    -- ...
end
```

### Build Custom Gateway Image

```bash
cd docker

# Build gateway với custom tag
docker compose build gateway --build-arg CUSTOM_ARG=value

# Test thay đổi
docker compose up -d gateway

# Xem logs
docker logs -f gateway
```

### Chạy Tests

```bash
# Test xác thực JWT
docker exec -it gateway /usr/local/openresty/bin/resty /usr/local/openresty/site/lualib/jwt_verify.lua

# Test với curl
./test-endpoints.sh  # Tạo test script dựa trên các ví dụ Sử dụng
```

### Thêm Dependencies Mới

Để thêm thư viện Lua mới:

1. Cập nhật `docker/Dockerfile`:

   ```dockerfile
   RUN /usr/local/openresty/bin/opm get <package-name>
   ```

2. Rebuild container:

   ```bash
   docker compose -f docker/docker-compose.yml build gateway
   ```

Để biết hướng dẫn phát triển chi tiết hơn, xem [CONTRIBUTING.md](https://github.com/CTU-SematX/Orion-Nginx/blob/main/CONTRIBUTING.md).

---

## Giấy phép

Dự án này được cấp phép theo Giấy phép Apache License 2.0 - xem file [LICENSE](https://github.com/CTU-SematX/Orion-Nginx/blob/main/LICENSE) để biết chi tiết.

---

## Người duy trì

Tên và git-account cho người duy trì chính:

Ví dụ:
_Người_duy_trì_

## Tín chỉ và Tham khảo

### Dự án Liên quan

- [FIWARE Orion-LD](https://github.com/FIWARE/context.Orion-LD) - NGSI-LD Context Broker
- [OpenResty](https://openresty.org/) - Nền tảng web hiệu năng cao dựa trên Nginx và Lua
- [lua-resty-jwt](https://github.com/SkyLothar/lua-resty-jwt) - Thư viện xác thực JWT cho OpenResty

### Tiêu chuẩn và Đặc tả

- [NGSI-LD API](https://www.etsi.org/deliver/etsi_gs/CIM/001_099/009/01.08.01_60/gs_CIM009v010801p.pdf) - ETSI GS CIM 009 V1.8.1
- [JSON Web Token (JWT) - RFC 7519](https://datatracker.ietf.org/doc/html/rfc7519)
- [Tài liệu FIWARE](https://fiware-tutorials.readthedocs.io/)

### Lời cảm ơn

Xin gửi lời cảm ơn đặc biệt đến:

- FIWARE Foundation cho Orion-LD context broker
- Cộng đồng OpenResty cho nền tảng web mạnh mẽ
- [IEEE Open Source Maintainers Manual](https://opensource.ieee.org/community/manual/)
