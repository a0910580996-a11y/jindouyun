[CmdletBinding()]
param(
    [Parameter(Mandatory)]
    [string]$AutoHotkeyPath
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$source = Join-Path $root 'windows'
$sandbox = Join-Path ([System.IO.Path]::GetTempPath()) ('jindouyun-installer-' + [guid]::NewGuid().ToString('N'))

try {
    Copy-Item -Recurse -LiteralPath $source -Destination $sandbox
    $installer = Join-Path $sandbox '安装筋斗云.ps1'
    $copiedConfig = Join-Path $sandbox '配置.ahk'
    if (Test-Path -LiteralPath $copiedConfig) {
        Remove-Item -Force -LiteralPath $copiedConfig
    }
    & $installer -SkipStartup -AutoHotkeyPath $AutoHotkeyPath
    $config = Join-Path $sandbox '配置.ahk'
    $before = (Get-FileHash -Algorithm SHA256 -LiteralPath $config).Hash
    & $installer -SkipStartup -AutoHotkeyPath $AutoHotkeyPath
    $after = (Get-FileHash -Algorithm SHA256 -LiteralPath $config).Hash
    if ($before -ne $after) {
        throw 'Installer changed an existing local config'
    }
    Write-Output 'Windows installer integration: PASS'
}
finally {
    if (Test-Path -LiteralPath $sandbox) {
        for ($attempt = 1; $attempt -le 5; $attempt++) {
            try {
                Remove-Item -Recurse -Force -LiteralPath $sandbox
                break
            }
            catch {
                if ($attempt -eq 5) { throw }
                Start-Sleep -Milliseconds 250
            }
        }
    }
}
