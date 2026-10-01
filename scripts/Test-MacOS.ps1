$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$mainPath = Join-Path $root 'macos/init.lua'
$examplePath = Join-Path $root 'macos/配置示例.lua'
$installerPath = Join-Path $root 'macos/安装筋斗云.sh'

foreach ($path in @($mainPath, $examplePath, $installerPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing macOS release file: $path"
    }
}

$main = Get-Content -Raw -LiteralPath $mainPath
foreach ($name in @('loadUserConfig', 'openApplication', 'toggleWindow', 'openUrl', 'mediaAction', 'openPouch')) {
    if ($main -notmatch "function $name") {
        throw "Missing macOS function: $name"
    }
}
if ($main -notmatch '配置\.lua') { throw 'macOS local config is not loaded' }
if ($main -notmatch 'hs\.hotkey\.bind') { throw 'macOS hotkeys are not registered' }

$installer = Get-Content -Raw -LiteralPath $installerPath
if ($installer -notmatch 'PRESERVED') { throw 'macOS installer does not preserve local config' }
if ($installer -notmatch 'Hammerspoon\.app') { throw 'macOS installer does not check Hammerspoon' }

$attributesPath = Join-Path $root '.gitattributes'
if (-not (Test-Path -LiteralPath $attributesPath)) { throw 'Missing .gitattributes' }
git -C $root ls-files --error-unmatch .gitattributes 2>$null | Out-Null
if ($LASTEXITCODE -ne 0) { throw '.gitattributes is not tracked' }
$attributes = Get-Content -Raw -LiteralPath $attributesPath
if ($attributes -notmatch '\*\.sh text eol=lf') { throw 'Shell scripts are not forced to LF' }
if ($attributes -notmatch '\*\.lua text eol=lf') { throw 'Lua files are not forced to LF' }

Write-Output 'macOS source contract: PASS'
