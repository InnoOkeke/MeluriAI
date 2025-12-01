# MeluriAI - AI-Powered Cross-Chain Yield Aggregator

MeluriAI is an AI-powered cross-chain yield aggregator and risk monitoring agent that enables users to optimize yield farming across multiple blockchain networks through natural language commands.

## Features

- 🌐 **Multi-Chain Support**: BNB Chain, Ethereum, Base, Solana, Polygon, Arbitrum, Optimism, Linea, and SUI
- 🤖 **AI-Powered Optimization**: Automatic yield optimization using ML-based risk assessment
- 💬 **Natural Language Interface**: Control your investments through simple commands
- 🔒 **Risk Monitoring**: Continuous ML-based risk analysis and automated protective actions
- 🔗 **Cross-Chain Routing**: Seamless fund movement across chains
- 📊 **Real-Time Dashboard**: Monitor portfolio performance and risk metrics

## Project Structure

```
meluri-ai/
├── contracts/          # Smart contracts (Solidity)
├── backend/           # Backend services (Python/FastAPI)
├── frontend/          # Web dashboard (Next.js/React)
├── ml/               # ML models and training
└── docker-compose.yml # Local development environment
```

## Prerequisites

- Node.js 20+
- Python 3.11+
- Foundry (for smart contracts)
- Docker and Docker Compose
- PostgreSQL 15+
- Redis 7+

## Quick Start

### 1. Clone the repository

```bash
git clone <repository-url>
cd meluri-ai
```

### 2. Set up environment variables

```bash
# Backend
cp backend/.env.example backend/.env
# Edit backend/.env with your configuration

# Frontend
cp frontend/.env.example frontend/.env
# Edit frontend/.env with your configuration

# ML
cp ml/.env.example ml/.env
# Edit ml/.env with your configuration
```

### 3. Start with Docker Compose

```bash
docker-compose up -d
```

This will start:
- PostgreSQL database (port 5432)
- Redis cache (port 6379)
- FastAPI backend (port 8000)
- Next.js frontend (port 3000)
- MLflow tracking server (port 5000)

### 4. Access the application

- Frontend: http://localhost:3000
- Backend API: http://localhost:8000
- API Docs: http://localhost:8000/docs
- MLflow: http://localhost:5000

## Development Setup

### Smart Contracts

```bash
cd contracts

# Install Foundry dependencies
forge install OpenZeppelin/openzeppelin-contracts
forge install foundry-rs/forge-std

# Build contracts
forge build

# Run tests
forge test
```

### Backend

```bash
cd backend

# Create virtual environment
python -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Run database migrations
alembic upgrade head

# Start development server
uvicorn src.main:app --reload
```

### Frontend

```bash
cd frontend

# Install dependencies
npm install

# Start development server
npm run dev
```

### ML Models

```bash
cd ml

# Create virtual environment
python -m venv venv
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Train models
python train.py
```

## Testing

### Smart Contracts
```bash
cd contracts
forge test
```

### Backend
```bash
cd backend
pytest
```

### Frontend
```bash
cd frontend
npm test
```

## Supported Protocols

### Multi-Chain Protocols
- Aave (Ethereum, Polygon, Arbitrum, Optimism, Base)
- Curve Finance (Ethereum, Polygon, Arbitrum, Optimism, Base)
- Uniswap V3 (Ethereum, Polygon, Arbitrum, Optimism, Base, BNB)
- Beefy Finance (BNB, Polygon, Arbitrum, Optimism, Base, Linea)
- Yearn Finance (Ethereum, Polygon, Arbitrum, Optimism)

### Chain-Specific Protocols
- **BNB Chain**: Venus Protocol, PancakeSwap
- **Ethereum**: Lido, Rocket Pool, Compound
- **Solana**: Kamino Finance, Marinade Finance, Drift Protocol
- **SUI**: Cetus Protocol, Turbos Finance, Aftermath Finance

## Architecture

MeluriAI follows a microservices architecture:

1. **Smart Contracts**: On-chain vault and routing logic
2. **Yield Optimization Engine**: Calculates optimal allocations
3. **Risk Engine**: ML-based risk monitoring
4. **NLP Intent Parser**: Natural language command processing
5. **Transaction Simulator**: Pre-execution validation
6. **Notification Service**: Multi-channel alerts
7. **Portfolio Manager**: Position tracking and analytics

## Security

- Smart contracts audited by reputable firms
- Multi-signature governance
- Emergency pause mechanisms
- Encrypted credential storage
- HTTPS/TLS for all communications

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
