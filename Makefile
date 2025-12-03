.PHONY: help setup start stop restart logs status clean

# Default target
.DEFAULT_GOAL := help

# Docker compose file location
DOCKER_DIR := docker
COMPOSE := docker compose -f $(DOCKER_DIR)/docker-compose.yml

# Colors for output
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
NC := \033[0m # No Color

help: ## Display this help message
	@echo "$(GREEN)Orion-LD API Gateway - Available Commands$(NC)"
	@echo ""
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_-]+:.*?##/ { printf "  $(GREEN)%-12s$(NC) %s\n", $$1, $$2 }' $(MAKEFILE_LIST)

setup: ## Create .env file with default values
	@if [ ! -f $(DOCKER_DIR)/.env ]; then \
		echo "JWT_SECRET=your-secret-key-here" > $(DOCKER_DIR)/.env; \
		echo "TRUSTED_IP=172.18.0.1" >> $(DOCKER_DIR)/.env; \
		echo "$(GREEN).env file created at $(DOCKER_DIR)/.env. Please update JWT_SECRET and TRUSTED_IP$(NC)"; \
	else \
		echo "$(YELLOW).env file already exists$(NC)"; \
	fi

start: ## Start all services
	@echo "$(GREEN)Starting MongoDB...$(NC)"
	@$(COMPOSE) up -d mongo
	@sleep 2
	@echo "$(GREEN)Initializing MongoDB replica set...$(NC)"
	@docker exec -it mongo mongosh --eval 'rs.initiate({ "_id": "rs", "members": [{"_id": 0, "host": "mongo:27017"}] })' || true
	@sleep 2
	@echo "$(GREEN)Starting Orion-LD...$(NC)"
	@$(COMPOSE) up -d orion-ld
	@sleep 2
	@echo "$(GREEN)Starting Gateway...$(NC)"
	@$(COMPOSE) up -d gateway
	@echo "$(GREEN)✓ All services started! Gateway: http://localhost:8080$(NC)"

stop: ## Stop all services
	@$(COMPOSE) down

restart: ## Restart all services
	@$(COMPOSE) restart
	@echo "$(GREEN)✓ Services restarted$(NC)"

logs: ## Show logs from all services
	@$(COMPOSE) logs -f

status: ## Show status of all services
	@$(COMPOSE) ps

clean: ## Stop services and remove all data (volumes)
	@echo "$(RED)WARNING: This will delete all data!$(NC)"
	@read -p "Press Enter to continue or Ctrl+C to cancel..." dummy
	@$(COMPOSE) down -v
	@echo "$(GREEN)✓ Cleanup complete$(NC)"
