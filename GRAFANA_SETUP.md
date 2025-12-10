# Grafana + NGSI-LD Datasource Setup

Hướng dẫn sử dụng Grafana để hiển thị dữ liệu từ Orion-LD một cách trực quan.

## Tổng quan kiến trúc

```
┌─────────────────────────────────────────────────────────────────────┐
│                          Grafana (port 3000)                        │
│                    NGSI-LD Datasource Plugin                        │
└───────────────────────────┬─────────────────────────────────────────┘
                            │
         ┌──────────────────┼──────────────────┐
         │                  │                  │
         ▼                  ▼                  ▼
┌─────────────┐    ┌─────────────┐    ┌─────────────────┐
│  Orion-LD   │    │   Mintaka   │    │     Gateway     │
│  (port 1026)│    │  (port 8083)│    │   (port 8080)   │
└──────┬──────┘    └──────┬──────┘    └────────┬────────┘
       │                  │                    │
       ▼                  ▼                    │
┌─────────────┐    ┌─────────────┐             │
│   MongoDB   │    │ TimescaleDB │             │
│ (port 27017)│    │ (port 5432) │             │
└─────────────┘    └─────────────┘             │
                                               │
                                    (JWT Authentication)
```

## Khởi động

### Cách 1: Sử dụng script

```bash
cd docker
chmod +x start-with-grafana.sh
./start-with-grafana.sh
```

### Cách 2: Docker Compose thủ công

```bash
cd docker

# Khởi động MongoDB trước
docker compose up -d mongo
sleep 5

# Khởi tạo replica set
docker exec mongo mongosh --quiet --eval "rs.initiate({_id: 'rs', members: [{_id: 0, host: 'mongo:27017'}]})"

# Khởi động tất cả services
docker compose up -d
```

## Truy cập Grafana

- **URL**: http://localhost:3000
- **Không cần đăng nhập** (Anonymous access đã được bật)
- Datasource NGSI-LD đã được cấu hình sẵn

## Cấu hình Datasource

Datasource đã được tự động cấu hình với:

| Thuộc tính | Giá trị |
|------------|---------|
| Context Broker URL | http://orion-ld:1026 |
| Temporal API URL | http://mintaka:8080 |
| Context URL | https://uri.etsi.org/ngsi-ld/v1/ngsi-ld-core-context.jsonld |

### Thay đổi cấu hình

Chỉnh sửa file `grafana/provisioning/datasources/ngsild.yaml`:

```yaml
datasources:
  - name: NGSI-LD
    type: ngsild-grafana-datasource
    jsonData:
      brokerUrl: http://orion-ld:1026
      timeseriesUrl: http://mintaka:8080
      contextUrl: https://your-custom-context.jsonld
```

## Các loại Query hỗ trợ

### 1. Temporal/Timeseries Query
Hiển thị dữ liệu theo thời gian - cần Mintaka endpoint.

**Ví dụ use case**: 
- Biểu đồ nhiệt độ sensor theo thời gian
- Lịch sử vị trí của thiết bị

### 2. Current Value Query
Lấy giá trị hiện tại của entity attribute.

**Ví dụ use case**:
- Dashboard hiển thị trạng thái thiết bị hiện tại
- Gauge/Stat panel cho các metric realtime

### 3. Geo Query (Map Visualization)
Hiển thị vị trí entities trên bản đồ.

**Ví dụ use case**:
- Bản đồ vị trí các sensor/device
- Tracking vị trí realtime

### 4. Node Graph Query
Hiển thị quan hệ giữa các entities.

**Ví dụ use case**:
- Topology mạng lưới thiết bị
- Quan hệ giữa các đối tượng

## Tạo Dashboard

### Bước 1: Tạo Panel mới
1. Click **+ → Dashboard → Add new panel**

### Bước 2: Chọn Datasource
1. Ở phần Query, chọn datasource **NGSI-LD**

### Bước 3: Cấu hình Query
1. **Entity Type**: Chọn loại entity (ví dụ: `Device`, `Sensor`)
2. **Entity ID** (optional): ID cụ thể của entity
3. **Attribute**: Thuộc tính cần hiển thị

### Bước 4: Chọn Visualization
- **Time Series**: Cho temporal data
- **Stat/Gauge**: Cho current values
- **Geomap**: Cho location data
- **Node Graph**: Cho relationships

## Ví dụ: Tạo dữ liệu test

```bash
# Tạo entity với location
curl -X POST 'http://localhost:1026/ngsi-ld/v1/entities' \
  -H 'Content-Type: application/ld+json' \
  -d '{
    "@context": "https://uri.etsi.org/ngsi-ld/v1/ngsi-ld-core-context.jsonld",
    "id": "urn:ngsi-ld:Device:001",
    "type": "Device",
    "temperature": {
      "type": "Property",
      "value": 25.5,
      "observedAt": "2025-12-10T10:00:00Z"
    },
    "location": {
      "type": "GeoProperty",
      "value": {
        "type": "Point",
        "coordinates": [106.6297, 10.8231]
      }
    }
  }'

# Update temperature (sẽ được lưu vào Mintaka)
curl -X PATCH 'http://localhost:1026/ngsi-ld/v1/entities/urn:ngsi-ld:Device:001/attrs' \
  -H 'Content-Type: application/json' \
  -d '{
    "temperature": {
      "type": "Property",
      "value": 26.3,
      "observedAt": "2025-12-10T10:30:00Z"
    }
  }'
```

## Dừng services

```bash
cd docker
docker compose down

# Xóa cả volumes (dữ liệu)
docker compose down -v
```

## Troubleshooting

### Plugin không load được
```bash
docker logs grafana
```

Kiểm tra xem plugin đã được cài đặt chưa:
```bash
docker exec grafana ls -la /var/lib/grafana/plugins/
```

### Không kết nối được Orion-LD
Đảm bảo các container đang chạy:
```bash
docker compose ps
```

### Temporal queries không hoạt động
- Kiểm tra Mintaka đang chạy: `curl http://localhost:8083/health`
- Kiểm tra TimescaleDB: `docker logs timescale`

## Tài liệu tham khảo

- [NGSI-LD Grafana Datasource](https://github.com/bfi-de/ngsild-grafana-datasource)
- [Orion-LD Documentation](https://github.com/FIWARE/context.Orion-LD)
- [Mintaka](https://github.com/FIWARE/mintaka)
- [NGSI-LD Specification](https://www.etsi.org/deliver/etsi_gs/CIM/001_099/009/01.06.01_60/gs_CIM009v010601p.pdf)
