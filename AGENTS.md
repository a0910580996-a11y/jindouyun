# 筋斗云智能体部署协议

本仓库的目标是让智能体安全地完成本机部署与个性化。修改前先读取 README、对应平台目录和 `shared/功能与快捷键.md`。

## 1. 识别平台

- Windows：使用 `windows/筋斗云.ahk`、`windows/配置示例.ahk` 和 `windows/安装筋斗云.ps1`。
- macOS：使用 `macos/init.lua`、`macos/配置示例.lua` 和 `macos/安装筋斗云.sh`。
- 不要尝试在 macOS 运行 AutoHotkey，也不要在 Windows 伪装 Hammerspoon 真机验证。

## 2. 先检测，再配置

1. 检测必需运行时：Windows 为 AutoHotkey v2，macOS 为 Hammerspoon。
2. 检测用户实际使用的应用、安装位置和系统保留快捷键。
3. 向用户确认无法从环境可靠推断的选择。
4. 只启用用户需要且本机可用的功能。
5. 不要求用户安装全部可选应用。

## 3. 保护本地数据

- Windows 从 `windows/配置示例.ahk` 生成 `windows/配置.ahk`。
- macOS 从 `macos/配置示例.lua` 生成 `~/.hammerspoon/筋斗云/配置.lua`。
- 已有配置不得覆盖。需要更新时先读取、合并并创建可恢复备份。
- 不得上传配置、API 密钥、日志、报告、缓存、私人锦囊或本机绝对路径。
- DeepSeek 密钥只使用 `JINDOUYUN_DEEPSEEK_API_KEY` 或 `DEEPSEEK_API_KEY` 环境变量。
- 每次实际写入后，从同一路径回读并确认关键字段。

## 4. 最小部署

### Windows

1. 执行 `windows/安装筋斗云.ps1`，必要时用 `-AutoHotkeyPath` 指定 AutoHotkey v2。
2. 安装器必须保留已有 `配置.ahk`。
3. 运行 AutoHotkey `/Validate`。
4. 启动正式实例并读取 `windows/日志/筋斗云.log`。

### macOS

1. 确认 `/Applications/Hammerspoon.app` 存在。
2. 执行 `macos/安装筋斗云.sh`。
3. 安装器必须保留已有 `配置.lua`，并在修改根 `init.lua` 前备份。
4. 提醒用户授予 Hammerspoon 辅助功能权限并 Reload Config。
5. 检查 Hammerspoon Console 是否有加载错误。

## 5. 验证边界

运行可用的仓库与平台检查：

```powershell
pwsh -NoProfile -File scripts/Test-Repository.ps1
pwsh -NoProfile -File scripts/Test-Windows.ps1
pwsh -NoProfile -File scripts/Test-MacOS.ps1
```

然后请用户实际试按以下类别：

- 应用启动
- 窗口控制
- 网页入口
- 媒体控制
- 文本锦囊

报告必须分开说明：自动检查通过、正式实例成功启动、用户实际试按已确认。前两项不能被描述为第三项。

## 6. 变更边界

- 只修改完成当前部署所需的配置和平台文件。
- 不重排无关快捷键，不重写用户的私人锦囊。
- 不把 Windows 特有行为宣称为 macOS 完全等价。
- 不将仓库之外的“交换图”“数学图形实验室”“归去来兮”等独立产品纳入部署。
