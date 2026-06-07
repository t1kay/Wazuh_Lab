# ============================================================
# Wazuh SIEM Lab — Setup Windows Agent (Host)
# Chạy script này trên Host Windows (Run as Administrator)
# ============================================================

$WAZUH_SERVER_IP = "192.168.56.10"
$WAZUH_VERSION = "4.9.2"
$MSI_URL = "https://packages.wazuh.com/4.x/windows/wazuh-agent-${WAZUH_VERSION}-1.msi"
$MSI_PATH = "$env:TEMP\wazuh-agent.msi"

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  🖥️  Windows Agent Setup" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# --- Kiểm tra quyền Admin ---
$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
if (-not $isAdmin) {
    Write-Host "❌ Script cần chạy với quyền Administrator!" -ForegroundColor Red
    Write-Host "   Chuột phải PowerShell > Run as Administrator" -ForegroundColor Yellow
    exit 1
}

# --- Bước 1: Tải Wazuh Agent ---
Write-Host "[1/3] Tải Wazuh Agent v${WAZUH_VERSION}..." -ForegroundColor Yellow
if (Test-Path $MSI_PATH) {
    Write-Host "  → File đã tồn tại, bỏ qua download." -ForegroundColor Gray
} else {
    try {
        Invoke-WebRequest -Uri $MSI_URL -OutFile $MSI_PATH -UseBasicParsing
        Write-Host "  → Tải thành công." -ForegroundColor Green
    } catch {
        Write-Host "❌ Không tải được. Kiểm tra kết nối internet." -ForegroundColor Red
        Write-Host "   Hoặc vào Dashboard > Endpoints Summary > Deploy new agent" -ForegroundColor Yellow
        exit 1
    }
}
Write-Host ""

# --- Bước 2: Cài đặt Agent ---
Write-Host "[2/3] Cài đặt Wazuh Agent..." -ForegroundColor Yellow
$installArgs = "/i `"$MSI_PATH`" /q WAZUH_MANAGER=`"$WAZUH_SERVER_IP`" WAZUH_REGISTRATION_SERVER=`"$WAZUH_SERVER_IP`""
Start-Process msiexec.exe -ArgumentList $installArgs -Wait -NoNewWindow
Write-Host "  → Cài đặt hoàn tất." -ForegroundColor Green
Write-Host ""

# --- Bước 3: Khởi động service ---
Write-Host "[3/3] Khởi động Wazuh service..." -ForegroundColor Yellow
NET START Wazuh 2>$null
Start-Sleep -Seconds 3

$service = Get-Service -Name Wazuh -ErrorAction SilentlyContinue
if ($service -and $service.Status -eq "Running") {
    Write-Host "  → Wazuh Agent đang chạy!" -ForegroundColor Green
} else {
    Write-Host "  ⚠️ Service chưa start. Thử: NET START Wazuh" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  ✅  Windows Agent setup hoàn tất!" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "  Server: $WAZUH_SERVER_IP" -ForegroundColor White
Write-Host "  Config: C:\Program Files (x86)\ossec-agent\ossec.conf" -ForegroundColor White
Write-Host ""
Write-Host "  Kiểm tra Dashboard: https://$WAZUH_SERVER_IP" -ForegroundColor White
Write-Host "  Agent phải hiển thị Active trong vài phút." -ForegroundColor White
Write-Host ""
