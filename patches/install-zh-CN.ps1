# DLSS 5 Swapper 2.3.0 简体中文汉化 — 安装脚本
#
# 做三件事：
#   1. 找到目标安装（便携版或正式安装版）
#   2. 把现有的 app.asar 备份成 app.asar.original-2.3.0（只在备份不存在时创建，绝不覆盖已有备份）
#   3. 把汉化包复制进去，并用 SHA-256 校验复制结果
#
# 不删除、不移动任何已有文件。想撤销就运行同目录的 restore-original.ps1。

$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$source = Join-Path $here 'resources\app.asar'

if (-not (Test-Path -LiteralPath $source)) {
    Write-Host "找不到汉化包：$source" -ForegroundColor Red
    exit 1
}

# 复制前后各算一次，确认不是半截文件
function Get-Sha256([string]$path) {
    (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLower()
}

# The asar carries package.json, so the version can be read without unpacking it.
# Without this check the patch could be dropped onto another release, pairing a
# 2.3.0 interface with binaries from a different build.
function Get-AsarVersion([string]$asarPath) {
    $fs = [System.IO.File]::OpenRead($asarPath)
    try {
        $head = New-Object byte[] 16
        $fs.Read($head, 0, 16) | Out-Null
        $jsonLen = [BitConverter]::ToInt32($head, 12)
        $jsonBuf = New-Object byte[] $jsonLen
        $fs.Position = 16
        $fs.Read($jsonBuf, 0, $jsonLen) | Out-Null
        $header = [System.Text.Encoding]::UTF8.GetString($jsonBuf) | ConvertFrom-Json
        $entry = $header.files.'package.json'
        if (-not $entry) { return $null }
        $dataStart = 16 + [int]([Math]::Ceiling($jsonLen / 4) * 4)
        $size = [int64]$entry.size
        $pkgBuf = New-Object byte[] $size
        $fs.Position = $dataStart + [int64]$entry.offset
        $fs.Read($pkgBuf, 0, $size) | Out-Null
        $pkg = [System.Text.Encoding]::UTF8.GetString($pkgBuf) | ConvertFrom-Json
        return $pkg.version
    } catch {
        return $null
    } finally {
        $fs.Dispose()
    }
}

$sourceHash = Get-Sha256 $source
Write-Host "汉化包 SHA-256: $sourceHash"

# 候选目标：先看常见的安装位置，找不到再往下扫一层目录，最后才要求手动输入。
# Join-Path 在基路径为 $null 时会抛异常，所以统一包一层，空值直接返回 $null。
function Join-Safe([string]$base, [string]$child) {
    if ([string]::IsNullOrWhiteSpace($base)) { return $null }
    return (Join-Path $base $child)
}

$candidates = @(
    (Join-Safe (Join-Path $env:LOCALAPPDATA 'Programs') 'smartergamers-dlss5-swapper'),
    (Join-Safe $env:LOCALAPPDATA 'smartergamers-dlss5-swapper'),
    (Join-Safe $env:ProgramFiles 'SmarterGamers DLSS 5 Swapper'),
    (Join-Safe ${env:ProgramFiles(x86)} 'SmarterGamers DLSS 5 Swapper'),
    (Join-Safe (Join-Path $env:USERPROFILE 'Desktop') 'DLSS5-Swapper-2.3.0-zh-CN-portable'),
    (Join-Safe (Join-Path $env:USERPROFILE 'Downloads') 'DLSS5-Swapper-2.3.0-zh-CN-portable')
) | Where-Object { $_ }

$found = @()
foreach ($dir in $candidates) {
    $asar = Join-Path $dir 'resources\app.asar'
    if (Test-Path -LiteralPath $asar) { $found += $dir }
}

# 常见位置都没有：在这些根目录下各扫一层子目录，看谁的 resources\app.asar 存在。
# 只扫一层，不做全盘递归——全盘搜既慢又容易撞上权限问题。
if ($found.Count -eq 0) {
    $roots = @(
        (Join-Path $env:LOCALAPPDATA 'Programs'),
        $env:ProgramFiles,
        ${env:ProgramFiles(x86)},
        (Join-Path $env:USERPROFILE 'Desktop'),
        (Join-Path $env:USERPROFILE 'Downloads')
    ) | Where-Object { $_ -and (Test-Path -LiteralPath $_) }

    foreach ($root in $roots) {
        Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            $asar = Join-Path $_.FullName 'resources\app.asar'
            if ((Test-Path -LiteralPath $asar) -and ($found -notcontains $_.FullName)) {
                $found += $_.FullName
            }
        }
    }
}

if ($found.Count -eq 0) {
    Write-Host ''
    Write-Host '没有在默认位置找到 DLSS 5 Swapper 2.3.0。' -ForegroundColor Yellow
    $custom = Read-Host '请粘贴安装目录（包含 resources 文件夹的那一层），或直接回车退出'
    if ([string]::IsNullOrWhiteSpace($custom)) { exit 1 }
    $custom = $custom.Trim().Trim('"')
    if (-not (Test-Path -LiteralPath (Join-Path $custom 'resources\app.asar'))) {
        Write-Host "这个目录下没有 resources\app.asar：$custom" -ForegroundColor Red
        exit 1
    }
    $found = @($custom)
}

Write-Host ''
Write-Host '找到以下安装：'
for ($i = 0; $i -lt $found.Count; $i++) {
    Write-Host ("  [{0}] {1}" -f ($i + 1), $found[$i])
}

if ($found.Count -eq 1) {
    $target = $found[0]
    Write-Host ''
    Write-Host "目标：$target"
    $answer = Read-Host '确认打到这个安装上？(Y/n)'
    if ($answer -and $answer.Trim().ToLower() -ne 'y') { Write-Host '已取消。'; exit 0 }
} else {
    $target = $null
    while (-not $target) {
        $pick = Read-Host '输入编号选择目标（直接回车取消）'
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
$currentHash = Get-Sha256 $asarPath

Write-Host ''
Write-Host "当前 app.asar SHA-256: $currentHash"

# Version guard. Refuse by default rather than silently mixing releases.
$version = Get-AsarVersion $asarPath
Write-Host "当前版本：$(if ($version) { $version } else { '无法识别' })"

if ($version -and $version -ne '2.3.0') {
    Write-Host ''
    Write-Host ("这个汉化包只对应 2.3.0，而目标安装是 {0}。" -f $version) -ForegroundColor Red
    Write-Host '强行覆盖会让新界面对上旧的可执行文件，可能直接起不来。' -ForegroundColor Red
    $force = Read-Host '确实要继续吗？(y/N)'
    if (-not $force -or $force.Trim().ToLower() -ne 'y') { Write-Host '已取消，未改动任何文件。'; exit 0 }
} elseif (-not $version) {
    Write-Host '读不出目标版本，安装前请自行确认它是 2.3.0。' -ForegroundColor Yellow
    $go = Read-Host '继续？(y/N)'
    if (-not $go -or $go.Trim().ToLower() -ne 'y') { Write-Host '已取消，未改动任何文件。'; exit 0 }
}

if ($currentHash -eq $sourceHash) {
    Write-Host '这个安装已经是汉化版，无需重复安装。' -ForegroundColor Green
    exit 0
}

# 备份：已存在就保留，绝不覆盖
if (Test-Path -LiteralPath $backupPath) {
    Write-Host "原版备份已存在，保留不动：$backupPath" -ForegroundColor Cyan
} else {
    Copy-Item -LiteralPath $asarPath -Destination $backupPath -Force
    $backupHash = Get-Sha256 $backupPath
    if ($backupHash -ne $currentHash) {
        Write-Host '备份校验失败，已中止，未改动任何文件。' -ForegroundColor Red
        exit 1
    }
    Write-Host "已备份原版：$backupPath" -ForegroundColor Green
}

# 复制 + 校验
Copy-Item -LiteralPath $source -Destination $asarPath -Force
$installedHash = Get-Sha256 $asarPath

if ($installedHash -ne $sourceHash) {
    Write-Host '复制后校验失败！正在回滚…' -ForegroundColor Red
    if (Test-Path -LiteralPath $backupPath) {
        Copy-Item -LiteralPath $backupPath -Destination $asarPath -Force
        Write-Host '已回滚到原版。' -ForegroundColor Yellow
    }
    exit 1
}

Write-Host ''
Write-Host '汉化安装完成，校验通过。' -ForegroundColor Green
Write-Host "  安装位置：$target"
Write-Host "  原版备份：$backupPath"
Write-Host ''
Write-Host '下次启动应用即为中文界面。'
Write-Host '如果界面仍是英文：设置页里把语言切到「中文」。'
Write-Host '还原：运行同目录的 restore-original.ps1'
