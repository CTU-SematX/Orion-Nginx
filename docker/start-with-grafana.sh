#!/bin/bash

# Script to start all services including Grafana for NGSI-LD visualization
# This script must be run from the docker directory

set -e

echo "🚀 Starting Orion-LD with Grafana visualization..."

# Check if docker compose is available
if command -v docker-compose &> /dev/null; then
    COMPOSE_CMD="docker-compose"
elif docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    echo "❌ Docker Compose is not installed. Please install it first."
    exit 1
fi

# Initialize MongoDB replica set
echo "📦 Starting MongoDB..."
$COMPOSE_CMD up -d mongo
echo "⏳ Waiting for MongoDB to be ready..."
sleep 5

# Initialize replica set
echo "🔧 Initializing MongoDB replica set..."
docker exec mongo mongosh --quiet --eval "
try {
  rs.initiate({_id: 'rs', members: [{_id: 0, host: 'mongo:27017'}]});
  print('Replica set initiated');
} catch (e) {
  if (e.codeName === 'AlreadyInitialized') {
    print('Replica set already initialized');
  } else {
    throw e;
  }
}
"

# Start TimescaleDB for Mintaka
echo "📊 Starting TimescaleDB..."
$COMPOSE_CMD up -d timescale
echo "⏳ Waiting for TimescaleDB to be ready..."
sleep 10

# Start all remaining services
echo "🌐 Starting Orion-LD, Mintaka, Gateway, and Grafana..."
$COMPOSE_CMD up -d

echo ""
echo "✅ All services are starting up!"
echo ""
echo "📌 Service URLs:"
echo "   - Orion-LD Context Broker: http://localhost:1026"
echo "   - Gateway (with JWT auth):  http://localhost:8080"
echo "   - Mintaka Temporal API:     http://localhost:8083"
echo "   - Grafana Dashboard:        http://localhost:3000"
echo ""
echo "📊 Grafana Access:"
echo "   - URL: http://localhost:3000"
echo "   - No login required (anonymous access enabled)"
echo "   - NGSI-LD datasource is pre-configured"
echo ""
echo "🔍 To check logs: $COMPOSE_CMD logs -f"
echo "🛑 To stop all:   $COMPOSE_CMD down"
