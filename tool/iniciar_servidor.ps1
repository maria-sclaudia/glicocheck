# ============================================================
#  GlicoBolus — Servidor Local para Instalação no Celular
# ============================================================

Write-Host ""
Write-Host "  ╔════════════════════════════════════════╗" -ForegroundColor Cyan
Write-Host "  ║         GlicoBolus — Servidor          ║" -ForegroundColor Cyan
Write-Host "  ╚════════════════════════════════════════╝" -ForegroundColor Cyan
Write-Host ""

# Verifica se o build existe
$buildPath = Join-Path $PSScriptRoot "..\build\web"
if (-not (Test-Path $buildPath)) {
    Write-Host "  [ERRO] Pasta de build não encontrada!" -ForegroundColor Red
    Write-Host "  Execute primeiro: flutter build web --release" -ForegroundColor Yellow
    Write-Host ""
    Read-Host "  Pressione Enter para sair"
    exit 1
}

# Detecta o IP local da máquina
$ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
    $_.IPAddress -notlike "127.*" -and
    $_.IPAddress -notlike "169.*" -and
    $_.PrefixOrigin -eq "Dhcp"
} | Select-Object -First 1).IPAddress

if (-not $ip) {
    $ip = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {
        $_.IPAddress -notlike "127.*" -and $_.IPAddress -notlike "169.*"
    } | Select-Object -First 1).IPAddress
}

$port = 8080
$url  = "http://${ip}:${port}"

Write-Host "  ✅ Pasta de build encontrada." -ForegroundColor Green
Write-Host ""
Write-Host "  📱 Acesse no seu celular (mesma rede Wi-Fi):" -ForegroundColor Yellow
Write-Host ""
Write-Host "      $url" -ForegroundColor White -BackgroundColor DarkBlue
Write-Host ""
Write-Host "  💡 Dica: Após abrir no celular, toque em" -ForegroundColor Gray
Write-Host "     'Adicionar à Tela de Início' para instalar como app." -ForegroundColor Gray
Write-Host ""
Write-Host "  ⏹  Pressione Ctrl+C para encerrar o servidor." -ForegroundColor Gray
Write-Host ""

# Navega para a pasta de build e inicia o servidor Python
Set-Location $buildPath

# Verifica se Python está disponível
$python = $null
foreach ($cmd in @("python", "python3", "py")) {
    try {
        $ver = & $cmd --version 2>&1
        if ($ver -match "Python") {
            $python = $cmd
            break
        }
    } catch { }
}

if ($python) {
    Write-Host "  🚀 Iniciando servidor com Python ($python)..." -ForegroundColor Green
    Write-Host ""
    & $python -m http.server $port --bind 0.0.0.0
} else {
    Write-Host "  [AVISO] Python não encontrado. Tentando com npx serve..." -ForegroundColor Yellow
    npx --yes serve -l $port -s .
}
