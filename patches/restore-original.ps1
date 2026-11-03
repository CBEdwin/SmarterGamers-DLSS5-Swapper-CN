# DLSS 5 Swapper 2.3.0 — 还原到官方原版
#
# 只做一件事：把 app.asar.original-2.3.0 复制回 app.asar。
# 不删除备份、不动其他任何文件，所以可以反复运行。

$ErrorActionPreference = 'Stop'

function Get-Sha256([string]$path) {
    (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLower()
}

$candidates = @(
    'D:\DeskBox\CBEdwin\软件\DLSS5-Swapper-2.3.0-zh-CN-portable',
    (Join-Path $env:LOCALAPPDATA 'Programs\smartergamers-dlss5-swapper')
)

$found = @()
foreach ($dir in $candidates) {
    $backup = Join-Path $dir 'resources\app.asar.original-2.3.0'
    if (Test-Path -LiteralPath $backup) { $found += $dir }
}

if ($found.Count -eq 0) {
    Write-Host ''
    Write-Host '没有找到带原版备份的安装。' -ForegroundColor Yellow
    Write-Host '（备份文件名应为 resources\app.asar.original-2.3.0）'
    $custom = Read-Host '请粘贴安装目录，或直接回车退出'
    if ([string]::IsNullOrWhiteSpace($custom)) { exit 1 }
    $custom = $custom.Trim().Trim('"')
    if (-not (Test-Path -LiteralPath (Join-Path $custom 'resources\app.asar.original-2.3.0'))) {
        Write-Host '这个目录下没有原版备份。' -ForegroundColor Red
        exit 1
    }
    $found = @($custom)
}

Write-Host ''
Write-Host '找到以下可还原的安装：'
for ($i = 0; $i -lt $found.Count; $i++) {
    Write-Host ("  [{0}] {1}" -f ($i + 1), $found[$i])
}

if ($found.Count -eq 1) {
    $target = $found[0]
    $answer = Read-Host "确认还原 $target ？(Y/n)"
    if ($answer -and $answer.Trim().ToLower() -ne 'y') { Write-Host '已取消。'; exit 0 }
} else {
    $target = $null
    while (-not $target) {
        $pick = Read-Host '输入编号选择（直接回车取消）'
        if ([string]::IsNullOrWhiteSpace($pick)) { Write-Host '已取消。'; exit 0 }
        $index = 0
        if ([int]::TryParse($pick.Trim(), [ref]$index) -and $index -ge 1 -and $index -le $found.Count) {
            $target = $found[$index - 1]
        } else {
            Write-Host '编号无效，请重新输入。' -ForegroundColor Yellow
        }
    }
}

$asarPath = Join-Path $target 'resources\app.asar'
$backupPath = Join-Path $target 'resources\app.asar.original-2.3.0'
$expected = Get-Sha256 $backupPath

Copy-Item -LiteralPath $backupPath -Destination $asarPath -Force
$now = Get-Sha256 $asarPath

if ($now -ne $expected) {
    Write-Host '还原后校验失败！' -ForegroundColor Red
    Write-Host "  期望：$expected"
    Write-Host "  实际：$now"
    exit 1
}

Write-Host ''
Write-Host '已还原为官方原版，校验通过。' -ForegroundColor Green
Write-Host "  SHA-256：$now"
Write-Host ''
Write-Host '备份文件仍然保留，需要时可再次安装汉化。'
