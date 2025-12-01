# Contributing to MeluriAI

Thank you for your interest in contributing to MeluriAI! This document provides guidelines and instructions for contributing.

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for all contributors.

## Getting Started

1. Fork the repository
2. Clone your fork: `git clone https://github.com/your-username/meluri-ai.git`
3. Create a new branch: `git checkout -b feature/your-feature-name`
4. Make your changes
5. Run tests to ensure everything works
6. Commit your changes: `git commit -m "Add your feature"`
7. Push to your fork: `git push origin feature/your-feature-name`
8. Create a Pull Request

## Development Setup

See the [README.md](README.md) for detailed setup instructions.

Quick start:
```bash
# Run the setup script
./setup.sh  # On Linux/Mac
# or
.\setup.ps1  # On Windows

# Start development environment
docker-compose up -d
```

## Project Structure

```
meluri-ai/
├── contracts/      # Smart contracts (Solidity)
│   ├── src/       # Contract source files
│   ├── test/      # Contract tests
│   └── script/    # Deployment scripts
├── backend/       # Backend services (Python/FastAPI)
│   ├── src/       # Application code
│   ├── tests/     # Backend tests
│   └── alembic/   # Database migrations
├── frontend/      # Web dashboard (Next.js/React)
│   └── src/       # Frontend source code
└── ml/           # ML models and training
    ├── models/    # Trained models
    └── data/      # Training data
```

## Coding Standards

### Smart Contracts (Solidity)

- Follow the [Solidity Style Guide](https://docs.soliditylang.org/en/latest/style-guide.html)
- Use NatSpec comments for all public functions
- Write comprehensive tests for all contracts
- Run `forge fmt` before committing
- Ensure all tests pass: `forge test`

### Backend (Python)

- Follow PEP 8 style guide
- Use type hints for all functions
- Write docstrings for all modules, classes, and functions
- Format code with Black: `black .`
- Sort imports with isort: `isort .`
- Run tests: `pytest`
- Maintain test coverage above 80%

### Frontend (TypeScript/React)

- Follow the [Airbnb JavaScript Style Guide](https://github.com/airbnb/javascript)
- Use TypeScript for type safety
- Write functional components with hooks
- Run linter: `npm run lint`
- Run tests: `npm test`

## Testing

All contributions must include appropriate tests:

### Smart Contracts
```bash
cd contracts
forge test
```

### Backend
```bash
cd backend
pytest --cov=src
```

### Frontend
```bash
cd frontend
npm test
```

## Pull Request Process

1. Update the README.md with details of changes if applicable
2. Update documentation for any API changes
3. Ensure all tests pass
4. Request review from maintainers
5. Address any feedback from reviewers
6. Once approved, your PR will be merged

## Commit Message Guidelines

Use clear and descriptive commit messages:

- `feat: Add new feature`
- `fix: Fix bug in component`
- `docs: Update documentation`
- `test: Add tests for feature`
- `refactor: Refactor code`
- `style: Format code`
- `chore: Update dependencies`

## Reporting Bugs

When reporting bugs, please include:

1. Description of the bug
2. Steps to reproduce
3. Expected behavior
4. Actual behavior
5. Environment details (OS, versions, etc.)
6. Screenshots if applicable

## Feature Requests

We welcome feature requests! Please:

1. Check if the feature has already been requested
2. Provide a clear description of the feature
3. Explain the use case and benefits
4. Include any relevant examples or mockups

## Security

If you discover a security vulnerability, please email security@meluriai.com instead of creating a public issue.

## License

By contributing to MeluriAI, you agree that your contributions will be licensed under the MIT License.

## Questions?

Feel free to reach out:
- Discord: [discord.gg/meluriai](https://discord.gg/meluriai)
- Twitter: [@MeluriAI](https://twitter.com/MeluriAI)
- Email: dev@meluriai.com

Thank you for contributing to MeluriAI! 🚀
