# MeluriAI - AI-Powered Cross-Chain Yield Aggregator

MeluriAI is a sophisticated cross-chain yield optimization platform that combines AI-powered decision making, machine learning-based risk assessment, and natural language processing to maximize DeFi yields while minimizing risks.

## 🌐 Supported Networks

- **BNB Chain** - Fast, low-cost DeFi hub
- **Ethereum** - Most established DeFi ecosystem
- **Base** - Coinbase L2
- **Solana** - High-performance native protocols
- **Polygon** - High-throughput L2
- **Arbitrum** - Leading Ethereum L2
- **Optimism** - Optimistic rollup
- **Linea** - zkEVM L2
- **SUI** - Move-based smart contracts

## 🏦 Integrated DeFi Protocols

### Lending & Borrowing
- Aave (multi-chain)
- Compound (multi-chain)
- Radiant Capital (BNB, Arbitrum, Base)
- Venus Protocol (BNB Chain)

### DEX & AMM
- Curve Finance (multi-chain)
- Uniswap V3 (multi-chain)
- PancakeSwap (multi-chain)
- Balancer (multi-chain)

### Liquid Staking
- Lido (Ethereum, Polygon)
- Rocket Pool (Ethereum)
- Ankr (multi-chain)
- Marinade Finance (Solana)

### Yield Aggregators
- Beefy Finance (multi-chain)
- Yearn Finance (multi-chain)
- Autofarm (BNB, Polygon)

### Solana Native
- Kamino Finance
- Marinade Finance
- Drift Protocol

### SUI Native
- Cetus Protocol
- Turbos Finance
- Aftermath Finance

## ✨ Key Features

- **Natural Language Interface**: Control your investments with simple commands via web dashboard or Telegram
- **AI-Powered Optimization**: Automatically finds and allocates funds to highest yield opportunities
- **ML Risk Monitoring**: Continuous risk assessment using IsolationForest, RandomForest, and Autoencoder models
- **Cross-Chain Operations**: Seamless fund routing across 9 blockchain networks
- **Transaction Simulation**: Preview outcomes before execution
- **Automated Protection**: Set conditional rules for automatic risk mitigation
- **WalletConnect Integration**: Unified authentication for all supported chains
- **Real-time Notifications**: WebSocket and Telegram alerts for important events

## 🏗️ Architecture

```
Frontend (Next.js + React)
    ↓
API Gateway (FastAPI)
    ↓
Backend Microservices
├── Yield Optimization Engine
├── Risk Engine (ML Models)
├── NLP Intent Parser
├── Transaction Simulator
├── Notification Service
└── Portfolio Manager
    ↓
Smart Contracts
├── Smart Vault
├── Smart Router
└── Strategy Adapters
    ↓
DeFi Protocols (20+)
```

## 🛠️ Technology Stack

### Smart Contracts
- Solidity 0.8.x
- Foundry for testing and deployment
- OpenZeppelin contracts
- LayerZero/Wormhole/Axelar for cross-chain

### Backend
- Python 3.11+ with FastAPI
- Node.js 20+ for real-time services
- PostgreSQL 15+
- Redis 7+
- The Graph for blockchain indexing

### ML/AI
- Python with scikit-learn
- PyTorch for deep learning
- Transformers for NLP
- MLflow for model management

### Frontend
- React 18+ with Next.js 14+
- TypeScript
- TailwindCSS
- WalletConnect (Reown)
- wagmi/viem for EVM chains
- @solana/wallet-adapter for Solana
- @mysten/wallet-adapter for SUI

## 📋 Project Structure

```
MeluriAI/
├── .kiro/
│   └── specs/
│       └── meluri-ai-yield-aggregator/
│           ├── requirements.md    # 15 requirements, 75 acceptance criteria
│           ├── design.md          # Architecture & 64 correctness properties
│           └── tasks.md           # 30 major tasks, 23 phases
├── contracts/                     # Smart contracts (Solidity)
├── backend/                       # Backend services (Python/Node.js)
├── frontend/                      # Web dashboard (Next.js)
├── ml/                           # ML models and training
└── docs/                         # Documentation

```

## 🚀 Getting Started

### Prerequisites
- Node.js 20+
- Python 3.11+
- Foundry
- Docker & Docker Compose
- PostgreSQL 15+
- Redis 7+

### Installation

1. Clone the repository:
```bash
git clone https://github.com/InnoOkeke/MeluriAI.git
cd MeluriAI
```

2. Follow the implementation plan in `.kiro/specs/meluri-ai-yield-aggregator/tasks.md`

3. Start with Phase 1: Foundation and Infrastructure

## 📖 Documentation

- **Requirements**: See `.kiro/specs/meluri-ai-yield-aggregator/requirements.md`
- **Design**: See `.kiro/specs/meluri-ai-yield-aggregator/design.md`
- **Implementation Plan**: See `.kiro/specs/meluri-ai-yield-aggregator/tasks.md`

## 🧪 Testing Strategy

- **Unit Tests**: Test individual components and functions
- **Property-Based Tests**: Verify universal properties across all inputs (100+ iterations)
- **Integration Tests**: Test complete user flows
- **Load Tests**: Performance testing under high load

## 🔒 Security

- Smart contract audits from reputable firms
- Bug bounty program
- Emergency pause functionality
- Multi-signature governance
- Encrypted credentials (AES-256)
- HTTPS/TLS for all communications

## 🤝 Contributing

Contributions are welcome! Please read our contributing guidelines before submitting PRs.

## 📄 License

[Add your license here]

## 🔗 Links

- Website: [Coming Soon]
- Documentation: [Coming Soon]
- Twitter: [Add your Twitter]
- Discord: [Add your Discord]
- Telegram: [Add your Telegram]

## 👥 Team

Built by the MeluriAI team

---

**Note**: This project is under active development. The specification is complete and implementation is in progress.
