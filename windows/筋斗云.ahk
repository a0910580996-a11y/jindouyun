#Requires AutoHotkey v2.0
#SingleInstance Force
#Include *i 配置.ahk

; --- 筋斗云 (Windrider v12.5 - Cockpit Edition) ---

GetUserConfig()
{
    global JINDOUYUN_USER_CONFIG
    return IsSet(JINDOUYUN_USER_CONFIG) ? JINDOUYUN_USER_CONFIG : Map()
}

ConfigValue(config, key, fallback := "")
{
    return config.Has(key) && config[key] != "" ? config[key] : fallback
}

USER_CONFIG := GetUserConfig()

; ========================================================
; [配置区] 全局常量
; ========================================================
CFG_RELOAD_CHECK_MS := 1500
CFG_RELOAD_STABLE_MS := 500
CFG_DEFAULT_LAUNCH_WAIT_SEC := 4
CFG_MEDIA_ACTIVATE_WAIT_SEC := 1
CFG_MEDIA_FOCUS_SETTLE_MS := 30
CFG_MEDIA_RESTORE_SETTLE_MS := 10
CFG_MEDIA_INTER_STEP_MS := 40
CFG_MEDIA_FORWARD_BACK_COMPENSATION := 2
CFG_MEDIA_PROCESS_EXE := "Microsoft.Media.Player.exe"
CFG_LOG_MAX_LINES := 80
CFG_LAUNCH_DEBOUNCE_MS := 1500
CFG_PASTE_RESTORE_DELAY_MS := 80
CFG_CHROME_PROFILE_DIR_NAME := ConfigValue(USER_CONFIG, "chromeProfileName", "Default")

PATH_STARTUP_SHORTCUT := A_Startup . "\筋斗云.lnk"
PATH_AHK_EXE := A_AhkPath
PATH_SCRIPT := A_ScriptFullPath
PATH_LOG := A_ScriptDir . "\日志\筋斗云.log"
PATH_AUDIT_REPORT := A_ScriptDir . "\报告\筋斗云-体检报告.txt"
PATH_HOTKEY_GUIDE := A_ScriptDir . "\文档\筋斗云-快捷键总表.html"
PATH_CHROME_EXE := ConfigValue(USER_CONFIG, "chromeExe", EnvGet("ProgramFiles") . "\Google\Chrome\Application\chrome.exe")
PATH_CHROME_PROXY_EXE := ConfigValue(USER_CONFIG, "chromeProxyExe", EnvGet("ProgramFiles") . "\Google\Chrome\Application\chrome_proxy.exe")
PATH_CHROME_PROFILE := EnvGet("LOCALAPPDATA") . "\Google\Chrome\User Data\" . CFG_CHROME_PROFILE_DIR_NAME
PATH_FEISHU_EXE := EnvGet("LOCALAPPDATA") . "\Feishu\app\Feishu.exe"
PATH_FEISHU_WORKDIR := EnvGet("LOCALAPPDATA") . "\Feishu\app"
PATH_CLOUDMUSIC_EXE := ConfigValue(USER_CONFIG, "cloudMusicExe")
PATH_CODEX_PACKAGE_FAMILY := "OpenAI.Codex_2p2nqsd0c76g0"
PATH_CODEX_APP_ID := PATH_CODEX_PACKAGE_FAMILY . "!App"
PATH_OBSIDIAN_APP_ID := "md.obsidian"
PATH_READER_SHORTCUT := ConfigValue(USER_CONFIG, "readerShortcut")
PATH_WORD_BREAKTHROUGH_SHORTCUT := EnvGet("APPDATA") . "\Microsoft\Windows\Start Menu\Programs\单词突围.lnk"
PATH_HIDDIFY_EXE := ConfigValue(USER_CONFIG, "hiddifyExe")
PATH_HIDDIFY_WORKDIR := ConfigValue(USER_CONFIG, "hiddifyWorkDir")
PATH_GW_EXE := ConfigValue(USER_CONFIG, "gwExe")
PATH_GW_WORKDIR := ConfigValue(USER_CONFIG, "gwWorkDir")
PATH_OBSIDIAN_EXE := ConfigValue(USER_CONFIG, "obsidianExe", EnvGet("LOCALAPPDATA") . "\Programs\Obsidian\Obsidian.exe")
PATH_WEIXIN_EXE := ConfigValue(USER_CONFIG, "weixinExe", EnvGet("ProgramFiles") . "\Tencent\Weixin\Weixin.exe")
PATH_AGENT_NOTE_PY := A_ScriptDir . "\辅助脚本\agent_note.py"
PATH_POUCH_DIR := A_ScriptDir . "\袖里乾坤\锦囊"

SCRIPT_WATCH := Map(
    "lastStableModTime", FileGetTime(PATH_SCRIPT, "M"),
    "pendingModTime", "",
    "pendingSinceTick", 0
)

MEDIA_RUNTIME := Map(
    "lastHwnd", 0
)

APP_RUNTIME := Map(
    "launching", Map()
)

POUCH_RUNTIME := Map(
    "gui", 0,
    "search", 0,
    "targetHwnd", 0,
    "all", [],
    "visible", [],
    "rows", [],
    "headers", [],
    "selected", 1,
    "lastClickIndex", 0,
    "lastClickTick", 0
)

GAME_MODE := false

APPS := BuildAppTable()

; ========================================================
; [启动区]
; ========================================================
EnsureManagedDirs()
EnsurePouchSeed()
SetTitleMatchMode(2)
SetupTrayMenu()
LogEvent("INFO", "script.start", "筋斗云已加载")
SetTimer(WatchScriptUpdate, CFG_RELOAD_CHECK_MS)

; ========================================================
; [配置构建]
; ========================================================
BuildAppTable()
{
    global PATH_READER_SHORTCUT, PATH_WORD_BREAKTHROUGH_SHORTCUT, PATH_HIDDIFY_EXE, PATH_HIDDIFY_WORKDIR, PATH_GW_EXE, PATH_GW_WORKDIR, PATH_CODEX_APP_ID
    global PATH_OBSIDIAN_EXE, PATH_WEIXIN_EXE
    global PATH_OBSIDIAN_APP_ID
    global PATH_CHROME_EXE, PATH_CLOUDMUSIC_EXE, PATH_FEISHU_EXE, PATH_FEISHU_WORKDIR

    return Map(
        "reader", Map(
            "type", "chromeApp",
            "name", "Reader - 英语阅读助手",
            "winTitle", "Reader - 英语阅读助手",
            "runCmd", ChromeDesktopApp("mbgkcofofegohighnlbocknadciflkjf"),
            "fallbackCmd", PATH_READER_SHORTCUT,
            "waitSec", 4
        ),
        "wordBreakthrough", Map(
            "type", "exe",
            "name", "单词突围",
            "winTitle", "单词突围 ahk_exe 单词突围.exe",
            "runCmd", QuotePath(PATH_WORD_BREAKTHROUGH_SHORTCUT),
            "waitSec", 6
        ),
        "hiddify", Map(
            "type", "exe",
            "name", "Hiddify",
            "winTitle", "Hiddify ahk_exe Hiddify.exe",
            "runCmd", PATH_HIDDIFY_EXE,
            "workDir", PATH_HIDDIFY_WORKDIR,
            "runAs", true,
            "waitSec", 6
        ),
        "gw", Map(
            "type", "exe",
            "name", "GW",
            "winTitle", "GW ahk_exe GW.exe",
            "runCmd", PATH_GW_EXE,
            "workDir", PATH_GW_WORKDIR,
            "waitSec", 6
        ),
        "weixin", Map(
            "type", "exe",
            "name", "微信",
            "winTitle", "ahk_exe Weixin.exe",
            "runCmd", PATH_WEIXIN_EXE,
            "waitSec", 5
        ),
        "obsidian", Map(
            "type", "appx",
            "name", "Obsidian",
            "winTitle", "ahk_exe Obsidian.exe",
            "runCmd", AppxApp(PATH_OBSIDIAN_APP_ID),
            "fallbackCmd", PATH_OBSIDIAN_EXE,
            "waitSec", 5
        ),
        "cloudmusic", Map(
            "type", "exe",
            "name", "网易云音乐",
            "winTitle", "ahk_exe cloudmusic.exe",
            "runCmd", PATH_CLOUDMUSIC_EXE,
            "waitSec", 5
        ),
        "chrome", Map(
            "type", "exe",
            "name", "Google Chrome",
            "winTitle", "Google Chrome",
            "runCmd", PATH_CHROME_EXE,
            "waitSec", 5
        ),
        "codex", Map(
            "type", "appx",
            "name", "Codex",
            "winTitle", "ahk_exe ChatGPT.exe",
            "runCmd", AppxApp(PATH_CODEX_APP_ID),
            "waitSec", 12
        ),
        "chatgpt", Map(
            "type", "chromeApp",
            "name", "ChatGPT",
            "winTitle", "ChatGPT ahk_exe chrome.exe",
            "runCmd", ChromeDesktopApp("omiebclofhdigmlgddbkbbbaoegknbcf"),
            "waitSec", 5
        ),
        "gemini", Map(
            "type", "chromeWeb",
            "name", "Gemini",
            "winTitle", "Gemini ahk_exe chrome.exe",
            "runCmd", ChromeWebApp("https://gemini.google.com/"),
            "waitSec", 5
        ),
        "deepseek", Map(
            "type", "chromeWeb",
            "name", "DeepSeek",
            "winTitle", "DeepSeek ahk_exe chrome.exe",
            "runCmd", ChromeWebApp("https://chat.deepseek.com/"),
            "waitSec", 5
        ),
        "notebooklm", Map(
            "type", "chromeWeb",
            "name", "NotebookLM",
            "winTitle", "NotebookLM ahk_exe chrome.exe",
            "runCmd", ChromeWebApp("https://notebooklm.google.com/"),
            "waitSec", 5
        ),
        "tasks", Map(
            "type", "chromeWeb",
            "name", "Google Tasks",
            "winTitle", "Google Tasks ahk_exe chrome.exe",
            "runCmd", ChromeWebApp("https://tasks.google.com/embed/list/~default"),
            "waitSec", 5
        ),
        "keep", Map(
            "type", "chromeWeb",
            "name", "Google Keep",
            "winTitle", "Google Keep ahk_exe chrome.exe",
            "runCmd", ChromeWebApp("https://keep.google.com/"),
            "waitSec", 5
        ),
        "weread", Map(
            "type", "chromeWeb",
            "name", "微信读书",
            "winTitle", "微信读书 ahk_exe chrome.exe",
            "runCmd", ChromeWebApp("https://weread.qq.com/"),
            "waitSec", 5
        ),
        "feishu", Map(
            "type", "exe",
            "name", "飞书",
            "winTitle", "飞书 ahk_exe Feishu.exe",
            "runCmd", PATH_FEISHU_EXE,
            "workDir", PATH_FEISHU_WORKDIR,
            "waitSec", 8
        ),
        "calendar", Map(
            "type", "chromeWeb",
            "name", "Google Calendar",
            "winTitle", "Google Calendar ahk_exe chrome.exe",
            "runCmd", ChromeWebApp("https://calendar.google.com/"),
            "waitSec", 5
        ),
        "bilibili", Map(
            "type", "chromeWeb",
            "name", "哔哩哔哩",
            "winTitle", "哔哩哔哩 ahk_exe chrome.exe",
            "runCmd", ChromeWebApp("https://www.bilibili.com/"),
            "waitSec", 5
        ),
        "mediaPlayer", Map(
            "type", "appx",
            "name", "媒体播放器",
            "winTitle", "ahk_exe Microsoft.Media.Player.exe",
            "runCmd", "explorer.exe shell:AppsFolder\Microsoft.ZuneMusic_8wekyb3d8bbwe!Microsoft.ZuneMusic",
            "waitSec", 6
        )
    )
}

ChromeDesktopApp(appId)
{
    global PATH_CHROME_PROXY_EXE, CFG_CHROME_PROFILE_DIR_NAME
    return QuotePath(PATH_CHROME_PROXY_EXE) . ' --profile-directory="' . CFG_CHROME_PROFILE_DIR_NAME . '" --app-id=' . appId
}

ChromeWebApp(url)
{
    global PATH_CHROME_EXE
    return QuotePath(PATH_CHROME_EXE) . " --app=" . url
}

AppxApp(appId)
{
    return "explorer.exe shell:AppsFolder\" . appId
}

FileUrl(path)
{
    return "file:///" . StrReplace(path, "\", "/")
}

QuotePath(path)
{
    return '"' . path . '"'
}

SetupTrayMenu()
{
    global GAME_MODE

    A_TrayMenu.Delete()
    A_TrayMenu.Add("快捷键总表", ShowHotkeyHelp)
    A_TrayMenu.Add("游戏模式（释放数字区）", ToggleGameMode)
    if GAME_MODE
        A_TrayMenu.Check("游戏模式（释放数字区）")
    A_TrayMenu.Add("运行体检", RunDoctorFromTray)
    A_TrayMenu.Add("打开日志", OpenLaunchLog)
    A_TrayMenu.Add("打开体检报告", OpenAuditReport)
    A_TrayMenu.Add("打开脚本", OpenScriptFile)
    A_TrayMenu.Add()
    A_TrayMenu.Add("重载脚本", SafeReload)
    A_TrayMenu.Add("退出筋斗云", ExitJindouyun)
    A_TrayMenu.Default := "快捷键总表"
}

ShowHotkeyHelp(*)
{
    global PATH_HOTKEY_GUIDE

    if FileExist(PATH_HOTKEY_GUIDE)
        Run(QuotePath(PATH_HOTKEY_GUIDE))
    else
        ShowStatusNotice("快捷键总表缺失，请检查文档目录。")
}

ShowCockpitMenu(*)
{
    CoordMode("Mouse", "Screen")
    MouseGetPos(&mouseX, &mouseY)
    A_TrayMenu.Show(mouseX, mouseY)
}

RunDoctorFromTray(*)
{
    DoctorLaunchConfig(true)
}

ToggleGameMode(*)
{
    global GAME_MODE

    GAME_MODE := !GAME_MODE
    if GAME_MODE
        A_TrayMenu.Check("游戏模式（释放数字区）")
    else
        A_TrayMenu.Uncheck("游戏模式（释放数字区）")

    LogEvent("INFO", "game_mode.toggle", GAME_MODE ? "on" : "off")
    ShowStatusNotice(GAME_MODE ? "游戏模式已开启，数字区已释放。" : "游戏模式已关闭，数字区热键已恢复。", 1800)
}

OpenLaunchLog(*)
{
    global PATH_LOG

    if !FileExist(PATH_LOG)
        FileAppend("", PATH_LOG, "UTF-8")
    Run("notepad.exe " . QuotePath(PATH_LOG))
}

OpenAuditReport(*)
{
    global PATH_AUDIT_REPORT

    DoctorLaunchConfig(false)
    Run("notepad.exe " . QuotePath(PATH_AUDIT_REPORT))
}

OpenScriptFile(*)
{
    global PATH_SCRIPT
    Run("notepad.exe " . QuotePath(PATH_SCRIPT))
}

ExitJindouyun(*)
{
    LogEvent("INFO", "script.exit", "用户从托盘退出")
    ExitApp()
}

SafeReload(*)
{
    global PATH_LOG

    if ValidateScript()
    {
        LogEvent("INFO", "script.reload", "基础检查通过，开始重载")
        Reload()
        return
    }

    LogEvent("ERROR", "script.reload_blocked", "基础检查失败，已取消重载")
    ShowStatusNotice("重载已取消，请查看日志。")
}

ValidateScript()
{
    global PATH_SCRIPT

    if !FileExist(PATH_SCRIPT)
        return false

    try scriptText := FileRead(PATH_SCRIPT, "UTF-8")
    catch
        return false

    if !InStr(scriptText, "#Requires AutoHotkey v2.0")
        return false
    if !InStr(scriptText, "#SingleInstance Force")
        return false
    return true
}

LogEvent(level, eventName, detail := "")
{
    global PATH_LOG, CFG_LOG_MAX_LINES

    line := FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . "`t" . level . "`t" . eventName . "`t" . SanitizeLogText(detail) . "`n"
    try FileAppend(line, PATH_LOG, "UTF-8")
    try TrimLogFile(PATH_LOG, CFG_LOG_MAX_LINES)
}

SanitizeLogText(text)
{
    text := StrReplace(text, "`r", " ")
    text := StrReplace(text, "`n", " ")
    text := StrReplace(text, "`t", " ")
    return SubStr(text, 1, 500)
}

TrimLogFile(path, maxLines)
{
    if !FileExist(path)
        return

    text := FileRead(path, "UTF-8")
    lines := StrSplit(RTrim(text, "`r`n"), "`n", "`r")
    if (lines.Length <= maxLines)
        return

    startIndex := lines.Length - maxLines + 1
    output := ""
    Loop maxLines
        output .= lines[startIndex + A_Index - 1] . "`n"

    FileDelete(path)
    FileAppend(output, path, "UTF-8")
}

DoctorLaunchConfig(showMessage := true)
{
    global APPS, PATH_AUDIT_REPORT, PATH_CHROME_EXE, PATH_CHROME_PROXY_EXE, PATH_CHROME_PROFILE
    global PATH_STARTUP_SHORTCUT, PATH_AHK_EXE, PATH_SCRIPT, PATH_CODEX_APP_ID

    issues := []
    report := "筋斗云体检报告`r`n生成时间：" . FormatTime(A_Now, "yyyy-MM-dd HH:mm:ss") . "`r`n`r`n"
    report .= "核心入口`r`n"
    report .= DoctorPathLine("AHK 运行时", PATH_AHK_EXE, issues)
    report .= DoctorPathLine("脚本文件", PATH_SCRIPT, issues)
    report .= DoctorShortcutLine("开机快捷方式", PATH_STARTUP_SHORTCUT, issues)
    report .= DoctorPathLine("Chrome", PATH_CHROME_EXE, issues)
    report .= DoctorPathLine("Chrome Proxy", PATH_CHROME_PROXY_EXE, issues)
    report .= DoctorPathLine("Chrome Profile 7", PATH_CHROME_PROFILE, issues)
    report .= "Codex AUMID： " . PATH_CODEX_APP_ID . "`r`n"
    report .= "`r`n应用入口`r`n"

    for appKey, app in APPS
    {
        appName := app["name"]
        appType := GetMapValue(app, "type", "command")
        winTitle := app["winTitle"]
        runCmd := app["runCmd"]
        fallbackCmd := GetMapValue(app, "fallbackCmd", "")
        report .= appKey . " / " . appName . " / " . appType . "`r`n"
        report .= "  窗口：" . winTitle . "`r`n"
        report .= DoctorCommandLine("  主入口", appKey, runCmd, appType, issues)
        if (fallbackCmd != "")
            report .= DoctorCommandLine("  备用入口", appKey, fallbackCmd, "fallback", issues)
        if (appType = "chromeWeb")
            AddDoctorIssue(issues, appKey, "Chrome 网页标题可能随页面语言或文档名漂移")
        report .= "`r`n"
    }

    report .= "风险汇总`r`n"
    if (issues.Length = 0)
        report .= "未发现明显入口风险。`r`n"
    else
    {
        for _, issue in issues
            report .= "- " . issue . "`r`n"
    }

    try
    {
        if FileExist(PATH_AUDIT_REPORT)
            FileDelete(PATH_AUDIT_REPORT)
        FileAppend(report, PATH_AUDIT_REPORT, "UTF-8")
    }
    catch as err
    {
        LogEvent("ERROR", "doctor.report_write_failed", err.Message)
        if showMessage
            MsgBox("体检报告写入失败：" . err.Message, "筋斗云体检")
        return
    }

    LogEvent("INFO", "doctor.run", "issues=" . issues.Length)
    if showMessage
        MsgBox("体检完成。发现风险：" . issues.Length . " 项。`n`n报告：" . PATH_AUDIT_REPORT, "筋斗云体检")
}

DoctorPathLine(label, path, issues)
{
    exists := FileExist(path) ? "OK" : "MISSING"
    if (exists = "MISSING")
        AddDoctorIssue(issues, label, "路径不存在：" . path)
    return label . "： " . exists . " | " . path . "`r`n"
}

DoctorShortcutLine(label, path, issues)
{
    if !FileExist(path)
    {
        AddDoctorIssue(issues, label, "快捷方式不存在：" . path)
        return label . "： MISSING | " . path . "`r`n"
    }

    target := ""
    workDir := ""
    args := ""
    try FileGetShortcut(path, &target, &workDir, &args)
    catch
    {
        AddDoctorIssue(issues, label, "快捷方式无法解析：" . path)
        return label . "： INVALID | " . path . "`r`n"
    }

    if (target != "" && !FileExist(target))
        AddDoctorIssue(issues, label, "快捷方式目标不存在：" . target)
    return label . "： OK | " . path . " -> " . target . "`r`n"
}

DoctorCommandLine(label, appKey, command, appType, issues)
{
    path := ExtractCommandPath(command)
    status := "OK"

    if (appType = "appx")
    {
        appId := ExtractAppxId(command)
        if (appId = "")
        {
            status := "INVALID"
            AddDoctorIssue(issues, appKey, label . " 无法解析 AUMID：" . command)
        }
        else if IsAppxRegistered(appId)
            status := "AUMID"
        else
        {
            status := "AUMID_MISSING"
            AddDoctorIssue(issues, appKey, label . " AUMID 未注册：" . appId)
        }
    }
    else if (path != "" && !FileExist(path))
    {
        status := "MISSING"
        AddDoctorIssue(issues, appKey, label . " 路径不存在：" . path)
    }
    else if (path != "" && InStr(path, ".lnk"))
    {
        target := ""
        workDir := ""
        args := ""
        try FileGetShortcut(path, &target, &workDir, &args)
        catch
        {
            status := "INVALID_LNK"
            AddDoctorIssue(issues, appKey, label . " 快捷方式无法解析：" . path)
        }
        if (status = "OK" && target != "" && !FileExist(target))
        {
            status := "BROKEN_LNK"
            AddDoctorIssue(issues, appKey, label . " 快捷方式目标不存在：" . target)
        }
    }
    else if (appType = "command" && path = "")
    {
        commandName := ExtractCommandName(command)
        if CommandExists(commandName)
            status := "PATH"
        else
        {
            status := "PATH_MISSING"
            AddDoctorIssue(issues, appKey, label . " 命令无法从 PATH 解析：" . commandName)
        }
    }

    return label . "： " . status . " | " . command . "`r`n"
}

ExtractCommandPath(command)
{
    command := Trim(command)
    if (command = "")
        return ""

    if (SubStr(command, 1, 1) = '"')
    {
        endPos := InStr(command, '"', , 2)
        return endPos ? SubStr(command, 2, endPos - 2) : ""
    }

    if RegExMatch(command, "i)^([A-Z]:\\.*?\.(exe|lnk|py))", &match)
        return match[1]

    return ""
}

ExtractCommandName(command)
{
    command := Trim(command)
    if (command = "")
        return ""

    spacePos := InStr(command, " ")
    return spacePos ? SubStr(command, 1, spacePos - 1) : command
}

CommandExists(commandName)
{
    if (commandName = "")
        return false

    tempPath := A_Temp . "\jindouyun-where.txt"
    try
    {
        exitCode := RunWait(A_ComSpec . " /c where.exe " . QuotePath(commandName) . " > " . QuotePath(tempPath) . " 2>nul", , "Hide")
        return exitCode = 0
    }
    catch
        return false
}

ExtractAppxId(command)
{
    marker := "shell:AppsFolder\"
    pos := InStr(command, marker)
    return pos ? SubStr(command, pos + StrLen(marker)) : ""
}

IsAppxRegistered(appId)
{
    static cache := ""

    if (cache = "")
    {
        tempPath := A_Temp . "\jindouyun-startapps.txt"
        psCommand := "Get-StartApps | Select-Object -ExpandProperty AppID | Set-Content -LiteralPath '" . tempPath . "' -Encoding UTF8"
        try RunWait("powershell.exe -NoProfile -ExecutionPolicy Bypass -Command " . QuotePath(psCommand), , "Hide")
        catch
            return false

        try cache := FileRead(tempPath, "UTF-8")
        catch
            cache := "`n"
        cache := StrReplace(cache, "`r`n", "`n")
        cache := StrReplace(cache, "`r", "`n")
    }

    return InStr("`n" . cache . "`n", "`n" . appId . "`n") ? true : false
}

AddDoctorIssue(issues, scope, message)
{
    issues.Push(scope . "：" . message)
}

; ========================================================
; [启动与稳态]
; ========================================================
EnsureAdminPrivileges()
{
    global PATH_SCRIPT

    if A_IsAdmin
        return

    try Run("*RunAs " . QuotePath(PATH_SCRIPT))
    catch
        MsgBox("必须以管理员权限运行。")
    ExitApp()
}

EnsureStartupShortcut(shortcutPath)
{
    global PATH_AHK_EXE, PATH_SCRIPT

    expectedTarget := PATH_AHK_EXE
    expectedArgs := QuotePath(PATH_SCRIPT)
    expectedWorkDir := A_ScriptDir

    needsRepair := !FileExist(shortcutPath)
    if !needsRepair
    {
        currentTarget := ""
        currentWorkDir := ""
        currentArgs := ""
        try FileGetShortcut(shortcutPath, &currentTarget, &currentWorkDir, &currentArgs)
        catch
            needsRepair := true

        if (!needsRepair && (currentTarget != expectedTarget || currentArgs != expectedArgs || currentWorkDir != expectedWorkDir))
            needsRepair := true
    }

    if !needsRepair
        return

    try
    {
        if FileExist(shortcutPath)
            FileDelete(shortcutPath)
        FileCreateShortcut(expectedTarget, shortcutPath, expectedWorkDir, expectedArgs)
    }
    catch
        MsgBox("创建开机自启快捷方式失败：" . shortcutPath)
}

EnsureManagedDirs()
{
    global PATH_LOG, PATH_AUDIT_REPORT, PATH_AGENT_NOTE_PY, PATH_HOTKEY_GUIDE, PATH_POUCH_DIR

    dirList := [
        DirFromFilePath(PATH_LOG),
        DirFromFilePath(PATH_AUDIT_REPORT),
        DirFromFilePath(PATH_AGENT_NOTE_PY),
        DirFromFilePath(PATH_HOTKEY_GUIDE),
        PATH_POUCH_DIR
    ]

    for _, dirPath in dirList
    {
        if (dirPath != "" && !DirExist(dirPath))
            DirCreate(dirPath)
    }
}

EnsurePouchSeed()
{
    global PATH_POUCH_DIR

    seedPath := PATH_POUCH_DIR . "\第一性原理.md"
    if !FileExist(seedPath)
        return
}

ShowPouchPalette(*)
{
    global POUCH_RUNTIME

    if (POUCH_RUNTIME["gui"] && WinExist("ahk_id " . POUCH_RUNTIME["gui"].Hwnd))
    {
        HidePouchPalette()
        return
    }

    POUCH_RUNTIME["targetHwnd"] := WinGetID("A")
    if !POUCH_RUNTIME["gui"]
        BuildPouchPalette()

    LoadPouchItems()
    POUCH_RUNTIME["search"].Value := ""
    UpdatePouchList()
    POUCH_RUNTIME["gui"].Show("AutoSize Center")
    POUCH_RUNTIME["search"].Focus()
}

BuildPouchPalette()
{
    global POUCH_RUNTIME

    pouchGui := Gui("+AlwaysOnTop -Caption +Border", "袖里乾坤")
    pouchGui.BackColor := "F5F0E8"
    pouchGui.MarginX := 28
    pouchGui.MarginY := 22
    pouchGui.SetFont("s18", "KaiTi")
    pouchGui.AddText("xm c2C2925", "袖里乾坤")
    pouchGui.SetFont("s9", "Microsoft YaHei UI")
    pouchGui.AddText("xm y+5 c7A7065", "把方法带回眼前，把问题交给行动")
    pouchGui.AddText("xm y+18 w44 h28 c8B8175", "寻囊")
    search := pouchGui.AddEdit("x+8 yp-3 w500 h32 vPouchSearch +BackgroundFBF8F2 c3C3934", "")
    hint := pouchGui.AddText("xm y+16 w548 c8B8175", "↑↓ 择囊    Enter 取用    Esc 收袖")

    search.OnEvent("Change", UpdatePouchList)
    pouchGui.OnEvent("Escape", HidePouchPalette)
    pouchGui.OnEvent("Close", HidePouchPalette)

    POUCH_RUNTIME["gui"] := pouchGui
    POUCH_RUNTIME["search"] := search
}

LoadPouchItems()
{
    global PATH_POUCH_DIR, POUCH_RUNTIME

    items := []
    Loop Files, PATH_POUCH_DIR . "\*.md", "FR"
    {
        try content := FileRead(A_LoopFileFullPath, "UTF-8")
        catch
            continue

        if (content = "")
            continue
        category := StrReplace(A_LoopFileDir, PATH_POUCH_DIR)
        category := StrReplace(category, "\", "")
        items.Push(Map(
            "name", StrReplace(A_LoopFileName, ".md"),
            "category", category,
            "path", A_LoopFileFullPath,
            "content", content
        ))
    }

    POUCH_RUNTIME["all"] := items
}

UpdatePouchList(*)
{
    global POUCH_RUNTIME

    if !POUCH_RUNTIME["gui"]
        return

    keyword := Trim(POUCH_RUNTIME["search"].Value)
    visible := []
    for _, item in POUCH_RUNTIME["all"]
    {
        if (keyword = "" || InStr(item["name"], keyword) || InStr(item["category"], keyword))
            visible.Push(item)
    }

    POUCH_RUNTIME["visible"] := visible
    POUCH_RUNTIME["selected"] := visible.Length ? 1 : 0
    ClearPouchRows()

    if (keyword = "")
        BuildGroupedPouchRows(visible)
    else
        BuildSearchPouchRows(visible)

    UpdatePouchSelection()
}

BuildGroupedPouchRows(items)
{
    global POUCH_RUNTIME

    currentCategory := ""
    for index, item in items
    {
        category := item["category"]
        if (category != currentCategory)
        {
            AddPouchHeader(StageLabel(category))
            currentCategory := category
        }
        AddPouchRow(item, index)
    }
}

BuildSearchPouchRows(items)
{
    for index, item in items
        AddPouchRow(item, index)
}

AddPouchHeader(text)
{
    global POUCH_RUNTIME

    y := PouchNextY()
    header := POUCH_RUNTIME["gui"].AddText("x28 y" . y . " w548 h24 c8B8175", text)
    POUCH_RUNTIME["headers"].Push(header)
}

AddPouchRow(item, index)
{
    global POUCH_RUNTIME

    y := PouchNextY()
    marker := POUCH_RUNTIME["gui"].AddText("x28 y" . y . " w3 h24 +BackgroundB35C4A", "")
    name := POUCH_RUNTIME["gui"].AddText("x45 y" . y . " w390 h24 c2C2925", DisplayPouchName(item["name"]))
    category := POUCH_RUNTIME["gui"].AddText("x435 y" . y . " w140 h24 Right c9A9186", DisplayPouchCategory(item["category"]))
    name.OnEvent("Click", PouchClickRow.Bind(index))
    category.OnEvent("Click", PouchClickRow.Bind(index))
    POUCH_RUNTIME["rows"].Push(Map("marker", marker, "name", name, "category", category, "index", index))
}

PouchNextY()
{
    global POUCH_RUNTIME

    rowCount := POUCH_RUNTIME["rows"].Length
    headerCount := POUCH_RUNTIME["headers"].Length
    return 145 + (rowCount * 27) + (headerCount * 32)
}

ClearPouchRows()
{
    global POUCH_RUNTIME

    for _, row in POUCH_RUNTIME["rows"]
    {
        DestroyPouchControl(row["marker"])
        DestroyPouchControl(row["name"])
        DestroyPouchControl(row["category"])
    }
    for _, header in POUCH_RUNTIME["headers"]
        DestroyPouchControl(header)
    POUCH_RUNTIME["rows"] := []
    POUCH_RUNTIME["headers"] := []
}

DestroyPouchControl(control)
{
    if control && control.Hwnd
        DllCall("DestroyWindow", "ptr", control.Hwnd)
}

PouchClickRow(index, *)
{
    global POUCH_RUNTIME

    nowTick := A_TickCount
    if (POUCH_RUNTIME["lastClickIndex"] = index && nowTick - POUCH_RUNTIME["lastClickTick"] <= 400)
    {
        POUCH_RUNTIME["lastClickIndex"] := 0
        POUCH_RUNTIME["lastClickTick"] := 0
        POUCH_RUNTIME["selected"] := index
        PouchInject()
        return
    }

    POUCH_RUNTIME["lastClickIndex"] := index
    POUCH_RUNTIME["lastClickTick"] := nowTick
    POUCH_RUNTIME["selected"] := index
    UpdatePouchSelection()
}

UpdatePouchSelection()
{
    global POUCH_RUNTIME

    for _, row in POUCH_RUNTIME["rows"]
    {
        if (row["index"] = POUCH_RUNTIME["selected"])
        {
            row["name"].Opt("+BackgroundE7DED2 c2C2925")
            row["category"].Opt("+BackgroundE7DED2 c9A9186")
            row["marker"].Opt("+BackgroundB35C4A")
        }
        else
        {
            row["name"].Opt("+BackgroundF5F0E8 c2C2925")
            row["category"].Opt("+BackgroundF5F0E8 c9A9186")
            row["marker"].Opt("+BackgroundF5F0E8")
        }
    }
}

PouchMoveSelection(delta)
{
    global POUCH_RUNTIME

    count := POUCH_RUNTIME["visible"].Length
    if !count
        return
    selected := POUCH_RUNTIME["selected"] + delta
    if (selected < 1)
        selected := count
    else if (selected > count)
        selected := 1
    POUCH_RUNTIME["selected"] := selected
    UpdatePouchSelection()
}

PouchInject(*)
{
    global POUCH_RUNTIME

    index := POUCH_RUNTIME["selected"]
    visible := POUCH_RUNTIME["visible"]
    if !index || index > visible.Length
    {
        ShowStatusNotice("没有可注入的锦囊。", 1500)
        return
    }

    item := visible[index]
    targetHwnd := POUCH_RUNTIME["targetHwnd"]
    HidePouchPalette()
    if !targetHwnd || !WinExist("ahk_id " . targetHwnd)
    {
        LogEvent("WARN", "pouch.target_missing", item["name"])
        ShowStatusNotice("原输入窗口已不存在，未注入。", 1800)
        return
    }

    WinRestore("ahk_id " . targetHwnd)
    WinActivate("ahk_id " . targetHwnd)
    if !WinWaitActive("ahk_id " . targetHwnd, , 1)
    {
        LogEvent("WARN", "pouch.target_not_active", item["name"] . " | hwnd=" . targetHwnd)
        ShowStatusNotice("原输入窗口未就绪，未注入。", 1800)
        return
    }
    Sleep(80)

    if !PasteTextKeepingClipboard(item["content"], false)
    {
        LogEvent("WARN", "pouch.clipboard_not_ready", item["name"])
        ShowStatusNotice("剪贴板未就绪，未注入。", 1800)
        return
    }
    LogEvent("INFO", "pouch.inject", item["name"] . " | " . item["path"])
    ShowStatusNotice("已注入：" . item["name"], 1200)
}

DisplayPouchName(name)
{
    return RegExReplace(name, "^\d+\s*")
}

DisplayPouchCategory(category)
{
    return RegExReplace(category, "^\d+\s*")
}

StageLabel(category)
{
    displayCategory := DisplayPouchCategory(category)
    number := RegExReplace(category, "^.*?(\d+).*?$", "$1")
    numerals := ["一", "二", "三", "四", "五"]
    return (number >= 1 && number <= numerals.Length ? numerals[number] : "") . " · " . displayCategory
}

HidePouchPalette(*)
{
    global POUCH_RUNTIME

    if POUCH_RUNTIME["gui"]
        POUCH_RUNTIME["gui"].Hide()
}

DirFromFilePath(path)
{
    splitPath := StrSplit(path, "\")
    splitPath.Pop()
    return splitPath.Length ? JoinPathParts(splitPath) : ""
}

JoinPathParts(parts)
{
    output := ""
    for idx, part in parts
        output .= (idx = 1 ? part : "\" . part)
    return output
}

WatchScriptUpdate()
{
    global SCRIPT_WATCH, PATH_SCRIPT, CFG_RELOAD_STABLE_MS

    currentModTime := FileGetTime(PATH_SCRIPT, "M")
    if (currentModTime = SCRIPT_WATCH["lastStableModTime"])
    {
        SCRIPT_WATCH["pendingModTime"] := ""
        return
    }

    nowTick := A_TickCount
    if (SCRIPT_WATCH["pendingModTime"] != currentModTime)
    {
        SCRIPT_WATCH["pendingModTime"] := currentModTime
        SCRIPT_WATCH["pendingSinceTick"] := nowTick
        return
    }

    if (nowTick - SCRIPT_WATCH["pendingSinceTick"] < CFG_RELOAD_STABLE_MS)
        return

    SCRIPT_WATCH["lastStableModTime"] := currentModTime
    SCRIPT_WATCH["pendingModTime"] := ""
    SafeReload()
}

; ========================================================
; [通用引擎]
; ========================================================
ToggleApp(appKey)
{
    app := GetAppConfig(appKey)
    winTitle := app["winTitle"]

    if WinActive(winTitle)
        WinMinimize(winTitle)
    else if WinExist(winTitle)
    {
        ActivateWindow(winTitle)
    }
    else if LaunchApp(appKey, app)
        ActivateWindow(winTitle)
}

EnsureAppActive(appKey)
{
    app := GetAppConfig(appKey)
    winTitle := app["winTitle"]

    if WinExist(winTitle)
    {
        return ActivateWindow(winTitle)
    }

    if LaunchApp(appKey, app)
        return true

    ShowLaunchError(app["name"], "窗口未就绪，请稍后再试。")
    return false
}

LaunchApp(appKey, app)
{
    global CFG_DEFAULT_LAUNCH_WAIT_SEC, CFG_LAUNCH_DEBOUNCE_MS, APP_RUNTIME

    appName := app["name"]
    winTitle := app["winTitle"]
    runCmd := app["runCmd"]
    workDir := GetMapValue(app, "workDir", "")
    runAs := GetMapValue(app, "runAs", false)
    waitSec := GetMapValue(app, "waitSec", CFG_DEFAULT_LAUNCH_WAIT_SEC)

    fallbackCmd := GetMapValue(app, "fallbackCmd", "")
    hasFallback := (fallbackCmd != "" && fallbackCmd != runCmd)

    launching := APP_RUNTIME["launching"]
    nowTick := A_TickCount
    if (launching.Has(appKey) && nowTick - launching[appKey] < CFG_LAUNCH_DEBOUNCE_MS)
    {
        LogEvent("INFO", "launch.debounced", appKey . " | " . appName)
        return WaitReadyWindow(winTitle, 1)
    }

    launching[appKey] := nowTick
    try
    {
        if TryRunAndWait(winTitle, runCmd, workDir, runAs, waitSec, appName, appKey, "primary", !hasFallback)
            return true

        if (hasFallback && TryRunAndWait(winTitle, fallbackCmd, workDir, runAs, waitSec, appName, appKey, "fallback"))
            return true

        ShowLaunchError(appName, "启动后未检测到窗口。")
        return false
    }
    finally
    {
        if launching.Has(appKey)
            launching.Delete(appKey)
    }
}

TryRunAndWait(winTitle, runCmd, workDir, runAs, waitSec, appName, appKey, phase, showErrors := true)
{
    LogEvent("INFO", "launch.try", appKey . " | " . phase . " | wait=" . waitSec . "s")
    try
    {
        if runAs
            Run("*RunAs " . runCmd, workDir)
        else
            Run(runCmd, workDir)
    }
    catch as err
    {
        LogEvent("ERROR", "launch.run_failed", appKey . " | " . phase . " | " . err.Message)
        if showErrors
            ShowLaunchError(appName, "无法启动：" . err.Message)
        return false
    }

    if WaitReadyWindow(winTitle, waitSec)
    {
        LogEvent("INFO", "launch.ready", appKey . " | " . phase)
        return true
    }

    LogEvent("WARN", "launch.timeout", appKey . " | " . phase . " | winTitle=" . winTitle)
    return false
}

ActivateWindow(winTitle, waitSec := 1)
{
    if !WinExist(winTitle)
        return false

    try WinRestore(winTitle)
    try WinActivate(winTitle)
    return WinWaitActive(winTitle, , waitSec) ? true : false
}

WaitReadyWindow(winTitle, waitSec)
{
    deadlineTick := A_TickCount + (waitSec * 1000)
    while (A_TickCount < deadlineTick)
    {
        hwnd := WinExist(winTitle)
        if (hwnd && ActivateWindow("ahk_id " . hwnd, 0.3))
            return true
        Sleep(100)
    }

    return false
}

ShowLaunchError(appName, message)
{
    LogEvent("WARN", "launch.notice", appName . " | " . message)
    ShowStatusNotice(appName . " 未就绪")
}

ShowStatusNotice(text, timeoutMs := 1600)
{
    ToolTip(text)
    SetTimer(ClearStatusNotice, -timeoutMs)
}

ClearStatusNotice()
{
    ToolTip()
}

IsGameMode()
{
    global GAME_MODE
    return GAME_MODE
}

CloseActiveTopWindow()
{
    hwnd := WinGetID("A")
    if !CanControlWindow(hwnd, "window.close")
        return

    try
    {
        title := WinGetTitle("ahk_id " . hwnd)
        WinClose("ahk_id " . hwnd)
        LogEvent("INFO", "window.close", title . " | hwnd=" . hwnd)
    }
    catch as err
    {
        LogEvent("WARN", "window.close_failed", "hwnd=" . hwnd . " | " . err.Message)
        ShowStatusNotice("关闭失败，请查看日志。", 1600)
    }
}

ToggleActiveWindowFullscreen()
{
    hwnd := WinGetID("A")
    if !CanControlWindow(hwnd, "window.fullscreen_toggle")
        return

    try
    {
        title := WinGetTitle("ahk_id " . hwnd)
        if (WinGetMinMax("ahk_id " . hwnd) = 1)
        {
            WinRestore("ahk_id " . hwnd)
            LogEvent("INFO", "window.restore", title . " | hwnd=" . hwnd)
        }
        else
        {
            WinMaximize("ahk_id " . hwnd)
            LogEvent("INFO", "window.maximize", title . " | hwnd=" . hwnd)
        }
    }
    catch as err
    {
        LogEvent("WARN", "window.fullscreen_toggle_failed", "hwnd=" . hwnd . " | " . err.Message)
        ShowStatusNotice("全屏切换失败，请查看日志。", 1600)
    }
}

CanControlWindow(hwnd, eventName)
{
    if !hwnd
    {
        LogEvent("WARN", eventName . "_skipped", "no active window")
        ShowStatusNotice("没有可操作的当前窗口。", 1200)
        return false
    }

    className := WinGetClass("ahk_id " . hwnd)
    if (className = "Progman" || className = "WorkerW" || className = "Shell_TrayWnd" || className = "Shell_SecondaryTrayWnd")
    {
        LogEvent("WARN", eventName . "_skipped", "protected class=" . className . " | hwnd=" . hwnd)
        ShowStatusNotice("已保护桌面/任务栏。", 1200)
        return false
    }

    return true
}

GetMapValue(mapObj, key, defaultValue := "")
{
    return mapObj.Has(key) ? mapObj[key] : defaultValue
}

GetAppConfig(appKey)
{
    global APPS

    if !APPS.Has(appKey)
        throw Error("未注册应用：" . appKey)
    return APPS[appKey]
}

; ========================================================
; [媒体播放器模块]
; ========================================================
ResolveMediaPlayerHwnd()
{
    global MEDIA_RUNTIME, CFG_MEDIA_PROCESS_EXE

    lastHwnd := MEDIA_RUNTIME["lastHwnd"]
    if (lastHwnd && WinExist("ahk_id " . lastHwnd))
        return lastHwnd

    hwnd := WinExist("ahk_exe " . CFG_MEDIA_PROCESS_EXE)
    if hwnd
    {
        MEDIA_RUNTIME["lastHwnd"] := hwnd
        return hwnd
    }

    hwnd := WinExist("媒体播放器 ahk_exe ApplicationFrameHost.exe")
    if !hwnd
        hwnd := WinExist("Media Player ahk_exe ApplicationFrameHost.exe")
    if hwnd
    {
        MEDIA_RUNTIME["lastHwnd"] := hwnd
        return hwnd
    }

    pid := ProcessExist(CFG_MEDIA_PROCESS_EXE)
    if pid
    {
        oldHidden := A_DetectHiddenWindows
        DetectHiddenWindows(true)
        hwnd := WinExist("ahk_pid " . pid)
        DetectHiddenWindows(oldHidden)
        if hwnd
        {
            MEDIA_RUNTIME["lastHwnd"] := hwnd
            return hwnd
        }
    }

    return 0
}

IsMediaPlayerRunning()
{
    global CFG_MEDIA_PROCESS_EXE
    return ProcessExist(CFG_MEDIA_PROCESS_EXE) || ResolveMediaPlayerHwnd()
}

IsMediaPlayerActive()
{
    hwnd := ResolveMediaPlayerHwnd()
    return hwnd && WinActive("ahk_id " . hwnd)
}

SendMediaSequenceToPlayer(keys, interDelayMs := 0)
{
    global CFG_MEDIA_ACTIVATE_WAIT_SEC, CFG_MEDIA_FOCUS_SETTLE_MS, CFG_MEDIA_RESTORE_SETTLE_MS

    targetHwnd := ResolveMediaPlayerHwnd()
    if !targetHwnd
        return

    wasActive := WinActive("ahk_id " . targetHwnd)
    prevHwnd := wasActive ? 0 : WinGetID("A")

    if !wasActive
    {
        WinActivate("ahk_id " . targetHwnd)
        if !WinWaitActive("ahk_id " . targetHwnd, , CFG_MEDIA_ACTIVATE_WAIT_SEC)
            return
        Sleep(CFG_MEDIA_FOCUS_SETTLE_MS)
    }

    for idx, key in keys
    {
        Send(key)
        if (interDelayMs > 0 && idx < keys.Length)
            Sleep(interDelayMs)
    }

    if (!wasActive && prevHwnd && WinExist("ahk_id " . prevHwnd))
    {
        Sleep(CFG_MEDIA_RESTORE_SETTLE_MS)
        WinActivate("ahk_id " . prevHwnd)
    }
}

SendToMediaPlayer(keys)
{
    SendMediaSequenceToPlayer([keys])
}

PlayPauseMedia()
{
    if IsMediaPlayerRunning()
        SendToMediaPlayer("{Space}")
}

SeekBack()
{
    SendToMediaPlayer("^{Left}")
}

SeekForward()
{
    global CFG_MEDIA_INTER_STEP_MS, CFG_MEDIA_FORWARD_BACK_COMPENSATION

    keys := ["^{Right}"]
    Loop CFG_MEDIA_FORWARD_BACK_COMPENSATION
        keys.Push("^{Left}")

    SendMediaSequenceToPlayer(keys, CFG_MEDIA_INTER_STEP_MS)
}

; ========================================================
; [剪贴板工具]
; ========================================================
CopySelectionText(timeoutSec := 0.5)
{
    clipSaved := ClipboardAll()
    try
    {
        A_Clipboard := ""
        Send("^c")

        text := ""
        if ClipWait(timeoutSec)
            text := A_Clipboard
        return text
    }
    finally
        A_Clipboard := clipSaved
}

PasteTextKeepingClipboard(text, replaceExisting := true)
{
    global CFG_PASTE_RESTORE_DELAY_MS

    if (text = "")
        return false

    clipSaved := ClipboardAll()
    pasted := false
    try
    {
        A_Clipboard := text
        if ClipWait(2)
        {
            if replaceExisting
                Send("^a{Backspace}^v")
            else
                Send("^v")
            Sleep(CFG_PASTE_RESTORE_DELAY_MS)
            pasted := true
        }
    }
    finally
        A_Clipboard := clipSaved

    return pasted
}

; ========================================================
; [媒体全局热键]
; ========================================================
#HotIf IsMediaPlayerActive()
$Space::PlayPauseMedia()
$^Left::SeekBack()
$^Right::SeekForward()
#HotIf

#HotIf IsMediaPlayerRunning()
$!+Space::PlayPauseMedia()
$!+Left::SeekBack()
$!+Right::SeekForward()
#HotIf

; ========================================================
; [第一区] 全局系统控制
; ========================================================
!q::CloseActiveTopWindow()     ; 关闭当前最顶层窗口
!Enter::ToggleActiveWindowFullscreen() ; 最大化 / 还原当前最顶层窗口
!r::ToggleApp("reader")
!j::ShowCockpitMenu()          ; 呼出筋斗云菜单
!+h::WinMinimizeAllUndo()      ; 还原一键桌面
!+r::SafeReload()              ; 基础检查重载脚本
!+u::DoctorLaunchConfig(true)  ; 运行体检

; ========================================================
; [第二区] 右手战术数字区
; ========================================================
#HotIf !IsGameMode()
Numpad7::Send("#+s")           ; 截图
NumpadHome::Send("#+s")        ; 截图（NumLock 关闭）
Numpad8::Send("#!r")           ; 录屏
NumpadUp::Send("#!r")          ; 录屏（NumLock 关闭）
Numpad9::
NumpadPgUp::
{
    selectedText := CopySelectionText(0.3)
    transTitle := "Google 翻译 ahk_exe chrome.exe"

    if (selectedText = "")
        ShowStatusNotice("未选中文本，已只打开翻译页。")

    if WinExist(transTitle)
        WinActivate(transTitle)
    else
        Run(ChromeWebApp("https://translate.google.com/?sl=auto&tl=zh-CN&op=translate"))

    WinWait(transTitle, , 3)
    if WinExist(transTitle)
    {
        WinActivate(transTitle)
        WinMove((A_ScreenWidth - 500) / 2, (A_ScreenHeight - 600) / 2, 500, 600, transTitle)
        if (selectedText != "")
        {
            Sleep(200)
            PasteTextKeepingClipboard(selectedText)
        }
    }
}

NumpadAdd::
{
    if WinActive("ahk_exe chrome.exe")
    {
        Send("+{F10}")
        Sleep(200)
        Send("t")
    }
}
#HotIf

; ========================================================
; [第三区] 本地应用
; ========================================================
!w::ToggleApp("weixin")
!o::ToggleApp("obsidian")
!y::ToggleApp("cloudmusic")
!i::ToggleApp("chrome")
!m::ToggleApp("mediaPlayer")
!+v::ToggleApp("gw")

; ========================================================
; [第四区] AI 矩阵
; ========================================================
#HotIf WinActive("袖里乾坤")
$Up::PouchMoveSelection(-1)
$Down::PouchMoveSelection(1)
$Enter::PouchInject()
$Escape::HidePouchPalette()
#HotIf

!+x::ShowPouchPalette()          ; 袖里乾坤：呼出锦囊命令面板
!x::ToggleApp("codex")
!a::ToggleApp("chatgpt")
!g::ToggleApp("gemini")
!d::ToggleApp("wordBreakthrough")
!+d::ToggleApp("deepseek")
!n::ToggleApp("notebooklm")

; ========================================================
; [第五区] Agent 自动化
; ========================================================
!+n::
{
    global PATH_AGENT_NOTE_PY

    ShowStatusNotice("正在存入 LifeOS/AI精华汇总...", 2000)
    try
    {
        if !FileExist(PATH_AGENT_NOTE_PY)
            throw Error("未找到 " . PATH_AGENT_NOTE_PY)
        RunWait('python.exe "' . PATH_AGENT_NOTE_PY . '"')
    }
    catch as err
    {
        LogEvent("ERROR", "agent.note_failed", err.Message)
        ShowStatusNotice("存入失败，请查看日志。", 2000)
        return
    }

    ShowStatusNotice("已执行存入流程。", 1500)
}

; ========================================================
; [第六区] Google 办公套件
; ========================================================
!t::ToggleApp("tasks")
!k::ToggleApp("keep")
!s::ToggleApp("weread")
!f::ToggleApp("feishu")
!c::ToggleApp("calendar")
!b::ToggleApp("bilibili")

; 彻底退出
!+q::ExitJindouyun()
