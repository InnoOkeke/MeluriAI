.PHONY: help install build test clean docker-up docker-down

help:
	@echo "MeluriAI Development Commands"
	@echo "=============================="
	@echo "install        - Install all dependencies"
	@echo "build          - Build all components"
	@echo "test           - Run all tests"
	@echo "clean          - Clean build artifacts"
	@echo "docker-up      - Start Docker services"
	@echo "docker-down    - Stop Docker services"
	@echo "contracts-test - Run smart contract tests"
	@echo "backend-test   - Run backend tests"
	@echo "frontend-test  - Run frontend tests"

install:
	@echo "Installing dependencies..."
	cd contracts && forge install
	cd backend && pip install -r requirements.txt
	cd frontend && npm install
	cd ml && pip install -r requirements.txt

build:
	@echo "Building all components..."
	cd contracts && forge build
	cd frontend && npm run build

test: contracts-test backend-test frontend-test

contracts-test:
	@echo "Running smart contract tests..."
	cd contracts && forge test

backend-test:
	@echo "Running backend tests..."
	cd backend && pytest

frontend-test:
	@echo "Running frontend tests..."
	cd frontend && npm test

clean:
	@echo "Cleaning build artifacts..."
	cd contracts && forge clean
	cd frontend && rm -rf .next node_modules
	cd backend && rm -rf __pycache__ .pytest_cache
	cd ml && rm -rf __pycache__

docker-up:
	@echo "Starting Docker services..."
	docker-compose up -d

docker-down:
	@echo "Stopping Docker services..."
	docker-compose down

docker-logs:
	docker-compose logs -f
