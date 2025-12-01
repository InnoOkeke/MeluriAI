# MeluriAI Project Setup Script for Windows

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "MeluriAI Project Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan

# Check prerequisites
Write-Host "`nChecking prerequisites..." -ForegroundColor Yellow

# Check Node.js
try {
    $nodeVersion = node --version
    Write-Host "✅ Node.js $nodeVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Node.js is not installed. Please install Node.js 20+" -ForegroundColor Red
    exit 1
}

# Check Python
try {
    $pythonVersion = python --version
    Write-Host "✅ Python $pythonVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Python is not installed. Please install Python 3.11+" -ForegroundColor Red
    exit 1
}

# Check Docker
try {
    $dockerVersion = docker --version
    Write-Host "✅ Docker $dockerVersion" -ForegroundColor Green
} catch {
    Write-Host "❌ Docker is not installed. Please install Docker" -ForegroundColor Red
    exit 1
}

# Check Foundry
try {
    $forgeVersion = forge --version | Select-Object -First 1
    Write-Host "✅ Foundry $forgeVersion" -ForegroundColor Green
} catch {
    Write-Host "⚠️  Foundry is not installed. Please install from https://book.getfoundry.sh/getting-started/installation" -ForegroundColor Yellow
}

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "Setting up Smart Contracts" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Set-Location contracts
forge install foundry-rs/forge-std --no-commit
forge install OpenZeppelin/openzeppelin-contracts --no-commit
forge build
Set-Location ..

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "Setting up Backend" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Set-Location backend
python -m venv venv
.\venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
Copy-Item .env.example .env -ErrorAction SilentlyContinue
Set-Location ..

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "Setting up Frontend" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Set-Location frontend
npm install
Copy-Item .env.example .env -ErrorAction SilentlyContinue
Set-Location ..

Write-Host "`n==========================================" -ForegroundColor Cyan
Write-Host "Setting up ML" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Set-Location ml
python -m venv venv
.\venv\Scripts\Activate.ps1
python -m pip install --upgrade pip
pip install -r requirements.txt
Copy-Item .env.example .env -ErrorAction SilentlyContinue
Set-Location ..

Write-Host "`n==========================================" -ForegroundColor Green
Write-Host "Setup Complete!" -ForegroundColor Green
Write-Host "==========================================" -ForegroundColor Green
Write-Host "`nNext steps:" -ForegroundColor Yellow
Write-Host "1. Edit .env files in backend/, frontend/, and ml/ directories"
Write-Host "2. Start Docker services: docker-compose up -d"
Write-Host "3. Access the application:"
Write-Host "   - Frontend: http://localhost:3000"
Write-Host "   - Backend API: http://localhost:8000"
Write-Host "   - API Docs: http://localhost:8000/docs"
Write-Host "   - MLflow: http://localhost:5000"
Write-Host "`nFor more information, see README.md" -ForegroundColor Cyan
