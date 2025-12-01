#!/bin/bash

echo "=========================================="
echo "MeluriAI Project Setup"
echo "=========================================="

# Check prerequisites
echo "Checking prerequisites..."

# Check Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed. Please install Node.js 20+"
    exit 1
fi
echo "✅ Node.js $(node --version)"

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python is not installed. Please install Python 3.11+"
    exit 1
fi
echo "✅ Python $(python3 --version)"

# Check Docker
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed. Please install Docker"
    exit 1
fi
echo "✅ Docker $(docker --version)"

# Check Foundry
if ! command -v forge &> /dev/null; then
    echo "⚠️  Foundry is not installed. Installing Foundry..."
    curl -L https://foundry.paradigm.xyz | bash
    foundryup
fi
echo "✅ Foundry $(forge --version | head -n 1)"

echo ""
echo "=========================================="
echo "Setting up Smart Contracts"
echo "=========================================="
cd contracts
forge install foundry-rs/forge-std --no-commit
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge build
cd ..

echo ""
echo "=========================================="
echo "Setting up Backend"
echo "=========================================="
cd backend
python3 -m venv venv
source venv/bin/activate 2>/dev/null || . venv/Scripts/activate 2>/dev/null
pip install --upgrade pip
pip install -r requirements.txt
cp .env.example .env
cd ..

echo ""
echo "=========================================="
echo "Setting up Frontend"
echo "=========================================="
cd frontend
npm install
cp .env.example .env
cd ..

echo ""
echo "=========================================="
echo "Setting up ML"
echo "=========================================="
cd ml
python3 -m venv venv
source venv/bin/activate 2>/dev/null || . venv/Scripts/activate 2>/dev/null
pip install --upgrade pip
pip install -r requirements.txt
cp .env.example .env
cd ..

echo ""
echo "=========================================="
echo "Setup Complete!"
echo "=========================================="
echo ""
echo "Next steps:"
echo "1. Edit .env files in backend/, frontend/, and ml/ directories"
echo "2. Start Docker services: docker-compose up -d"
echo "3. Access the application:"
echo "   - Frontend: http://localhost:3000"
echo "   - Backend API: http://localhost:8000"
echo "   - API Docs: http://localhost:8000/docs"
echo "   - MLflow: http://localhost:5000"
echo ""
echo "For more information, see README.md"
