$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$mainPath = Join-Path $root 'windows/筋斗云.ahk'
$examplePath = Join-Path $root 'windows/配置示例.ahk'
$installerPath = Join-Path $root 'windows/安装筋斗云.ps1'

foreach ($path in @($mainPath, $examplePath, $installerPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Windows release file: $path"
    }
}

$main = Get-Content -Raw -LiteralPath $mainPath
if ($main -notmatch '#Include \*i 配置\.ahk') {
    throw 'Windows local config include missing'
}
if ($main -notmatch 'IsSet\(JINDOUYUN_USER_CONFIG\)') {
    throw 'Windows config fallback missing'
}
if ($main -notmatch 'config\[key\] != ""') {
    throw 'Blank config values do not fall back to portable defaults'
}
if ($main -match '(?m)^EnsureStartupShortcut\(PATH_STARTUP_SHORTCUT\)$') {
    throw 'Windows release changes startup outside the installer'
}
if ($main -match '(?i)[A-Z]:\\Users\\Administrator|D:\\Desktop\\|E:\\LenovoSoftstore\\') {
    throw 'Windows release contains a personal absolute path'
}

foreach ($relativePath in @('windows/文档/筋斗云-快捷键总表.html', 'windows/辅助脚本/agent_note.py')) {
    $content = Get-Content -Raw -LiteralPath (Join-Path $root $relativePath)
    if ($content -match '(?i)[A-Z]:\\Users\\Administrator|D:\\Desktop\\|E:\\LenovoSoftstore\\') {
        throw "Windows support file contains a personal absolute path: $relativePath"
    }
}

$installer = Get-Content -Raw -LiteralPath $installerPath
if ($installer -notmatch 'PRESERVED') {
    throw 'Installer does not document config preservation'
}
if ($installer -notmatch 'SkipStartup') {
    throw 'Installer cannot be safely tested without changing startup'
}

Write-Output 'Windows contract: PASS'
