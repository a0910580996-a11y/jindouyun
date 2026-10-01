[CmdletBinding()]
param(
    [switch]$SkipStartup,
    [string]$AutoHotkeyPath
)

$ErrorActionPreference = 'Stop'
$releaseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$mainScript = Join-Path $releaseDir '筋斗云.ahk'
$configPath = Join-Path $releaseDir '配置.ahk'
$configExample = Join-Path $releaseDir '配置示例.ahk'

if (-not (Test-Path -LiteralPath $configPath)) {
    Copy-Item -LiteralPath $configExample -Destination $configPath
    Write-Output '配置.ahk: CREATED'
} else {
    Write-Output '配置.ahk: PRESERVED'
}

@('日志', '报告', '袖里乾坤\锦囊') | ForEach-Object {
    New-Item -ItemType Directory -Force -Path (Join-Path $releaseDir $_) | Out-Null
}

if ([string]::IsNullOrWhiteSpace($AutoHotkeyPath)) {
    $commands = @('AutoHotkeyUX.exe', 'AutoHotkey.exe')
    foreach ($commandName in $commands) {
        $command = Get-Command $commandName -ErrorAction SilentlyContinue
        if ($command) {
            $AutoHotkeyPath = $command.Source
            break
        }
    }
}

if ([string]::IsNullOrWhiteSpace($AutoHotkeyPath) -or -not (Test-Path -LiteralPath $AutoHotkeyPath)) {
    throw '未找到 AutoHotkey v2。请安装后重试，或通过 -AutoHotkeyPath 指定 AutoHotkeyUX.exe。'
}

$validation = Start-Process -FilePath $AutoHotkeyPath -ArgumentList @('/Validate', $mainScript) -Wait -PassThru
if ($validation.ExitCode -ne 0) {
    throw "AutoHotkey 静态验证失败，退出码：$($validation.ExitCode)"
}
Write-Output 'AutoHotkey validation: PASS'

if (-not $SkipStartup) {
    $startup = [Environment]::GetFolderPath('Startup')
    $shortcutPath = Join-Path $startup '筋斗云.lnk'
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $AutoHotkeyPath
    $shortcut.Arguments = '"' + $mainScript + '"'
    $shortcut.WorkingDirectory = $releaseDir
    $shortcut.Save()
    Write-Output "Startup shortcut: $shortcutPath"
}

Write-Output 'Windows install: PASS'
