$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$required = @(
    'README.md',
    'AGENTS.md',
    'LICENSE',
    'TRADEMARKS.md',
    'windows/筋斗云.ahk',
    'macos/init.lua'
)

foreach ($relativePath in $required) {
    $fullPath = Join-Path $root $relativePath
    if (-not (Test-Path -LiteralPath $fullPath)) {
        throw "Missing required file: $relativePath"
    }
}

$tracked = @(git -C $root ls-files)
$forbiddenPrefixes = @(
    '交换图/',
    '数学图形实验室/',
    '归去来兮/',
    'math game/',
    '日志/',
    '报告/',
    '备份/',
    'jindouyun-brand-v2/',
    'jindouyun-brand-v3/',
    'jindouyun-promo/'
)

foreach ($path in $tracked) {
    foreach ($prefix in $forbiddenPrefixes) {
        if ($path.StartsWith($prefix)) {
            throw "Forbidden tracked path: $path"
        }
    }
    if ($path -match '(^|/)node_modules/') {
        throw "Tracked dependency directory: $path"
    }
    if ($path -match '配置\.(ahk|lua)$') {
        throw "Tracked local config: $path"
    }
}

$publicFiles = @(
    'windows/筋斗云.ahk',
    'windows/配置示例.ahk',
    'macos/init.lua',
    'macos/配置示例.lua',
    'windows/辅助脚本/agent_note.py'
)

foreach ($relativePath in $publicFiles) {
    $fullPath = Join-Path $root $relativePath
    if (-not (Test-Path -LiteralPath $fullPath)) {
        continue
    }

    $content = Get-Content -Raw -LiteralPath $fullPath
    if ($content -match '(?i)(api[_-]?key|secret|token|password)\s*[:=]\s*["''][^"'']+["'']') {
        throw "Possible embedded secret: $relativePath"
    }
    if ($content -match '(?i)[A-Z]:\\Users\\Administrator|D:\\Desktop\\|E:\\LenovoSoftstore\\') {
        throw "Personal absolute path: $relativePath"
    }
}

$readme = Get-Content -Raw -LiteralPath (Join-Path $root 'README.md')
foreach ($term in @('交给智能体', 'Windows', 'macOS', 'MIT')) {
    if ($readme -notmatch [regex]::Escape($term)) {
        throw "README missing term: $term"
    }
}

$agents = Get-Content -Raw -LiteralPath (Join-Path $root 'AGENTS.md')
foreach ($term in @('配置.ahk', '配置.lua', '不得覆盖', '实际试按')) {
    if ($agents -notmatch [regex]::Escape($term)) {
        throw "AGENTS missing term: $term"
    }
}

$license = Get-Content -Raw -LiteralPath (Join-Path $root 'LICENSE')
foreach ($term in @('MIT License', 'Copyright (c) 2026 筋斗云')) {
    if ($license -notmatch [regex]::Escape($term)) {
        throw "LICENSE missing term: $term"
    }
}

$trademarks = Get-Content -Raw -LiteralPath (Join-Path $root 'TRADEMARKS.md')
foreach ($term in @('基于筋斗云开发', '不得冒充官方版本', '官方仓库')) {
    if ($trademarks -notmatch [regex]::Escape($term)) {
        throw "TRADEMARKS missing term: $term"
    }
}

Write-Output 'Repository contract: PASS'
