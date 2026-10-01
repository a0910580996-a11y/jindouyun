# 筋斗云

**把这个仓库链接交给你的智能体，它就能帮你部署一套属于你的快捷键系统。**

筋斗云是一套面向 Windows 与 macOS 的个人效率快捷键系统。它把应用启动、窗口控制、网页入口、媒体控制和常用文本集中在一套可修改的本地配置中。公共代码保持通用，你的路径、密钥、日志与私人锦囊只留在自己的电脑上。

官方仓库：<https://github.com/a0910580996-a11y/jindouyun>

## 交给智能体部署

复制下面这段话，并把官方仓库链接一起发给支持本机操作的编码智能体：

> 请克隆 <https://github.com/a0910580996-a11y/jindouyun>，先完整阅读仓库根目录的 AGENTS.md，再在我的电脑上部署筋斗云。请先识别 Windows 或 macOS，检测现有软件和快捷键冲突，根据我的实际需求生成本地配置。不要覆盖已有配置，不要上传我的路径、密钥、日志或私人锦囊，也不要安装无关软件。完成后运行仓库规定的验证，并分别告诉我哪些功能已自动确认、哪些还需要我实际试按。

智能体应当只在无法可靠判断个性化选择时询问你。缺少某个可选应用时，它会禁用对应入口，不会阻止其他功能使用。

## 平台支持

| 能力 | Windows | macOS |
| --- | --- | --- |
| 运行基础 | AutoHotkey v2 | Hammerspoon |
| 应用与网页启动 | 支持 | 支持 |
| 窗口控制 | 支持 | 支持，采用 macOS 原生行为 |
| 媒体控制 | 支持 | 支持 |
| 文本锦囊 | 支持 | 支持 |
| 本地个性化配置 | `配置.ahk` | `配置.lua` |
| 当前验证状态 | 已在 Windows 完成静态与安装器验证 | 源码契约已验证，仍需 Mac 真机确认权限与按键体验 |

两端遵循“功能语义一致、平台原生键位优先”。完整对照见 [功能与快捷键](shared/功能与快捷键.md)。Windows 的详细快捷键还可查看 [快捷键总表](windows/文档/筋斗云-快捷键总表.html)。

## 人工安装

### Windows

1. 安装 [AutoHotkey v2](https://www.autohotkey.com/)。
2. 进入 `windows` 目录。
3. 将 `配置示例.ahk` 复制为 `配置.ahk`，填写需要覆盖的应用路径。
4. 在 PowerShell 中运行：

   ```powershell
   powershell -NoProfile -ExecutionPolicy Bypass -File .\安装筋斗云.ps1
   ```

安装器不会覆盖已有 `配置.ahk`。AI 笔记功能还需要 Python、`requests`、`pyperclip`，以及环境变量 `JINDOUYUN_DEEPSEEK_API_KEY` 或 `DEEPSEEK_API_KEY`；它们不是核心快捷键运行的前置条件。

### macOS

1. 安装 [Hammerspoon](https://www.hammerspoon.org/)。
2. 在终端进入 `macos` 目录并运行：

   ```bash
   chmod +x ./安装筋斗云.sh
   ./安装筋斗云.sh
   ```

3. 在“系统设置 → 隐私与安全性 → 辅助功能”中允许 Hammerspoon。
4. 按需修改 `~/.hammerspoon/筋斗云/配置.lua`，然后在 Hammerspoon 菜单中选择 Reload Config。

安装器会备份已有筋斗云代码，并保留已有 `配置.lua`。

## 个性化与隐私

- Windows 本地配置：`windows/配置.ahk`
- macOS 本地配置：`~/.hammerspoon/筋斗云/配置.lua`
- 两种本地配置均被 Git 忽略。
- API 密钥只从环境变量读取。
- 日志、报告、缓存、私人锦囊和本机路径不会进入仓库。
- 更新时先备份或合并本地配置，不直接覆盖。

## 验证

在 Windows 上运行仓库检查：

```powershell
pwsh -NoProfile -File scripts/Test-Repository.ps1
pwsh -NoProfile -File scripts/Test-Windows.ps1
pwsh -NoProfile -File scripts/Test-MacOS.ps1
```

静态验证、安装器成功和进程启动不能替代真实按键体验。部署结束后，请分别试按应用启动、窗口控制、网页入口、媒体控制和文本锦囊。

## 贡献

欢迎提交问题与改进。修改应保持平台差异清晰，不应提交个人配置、密钥、日志、缓存或私人内容。新增快捷键前请检查系统保留组合与现有映射冲突。

## 许可证与品牌

代码使用 [MIT License](LICENSE)，允许使用、修改、分发和商用，但必须保留版权与许可证声明。

“筋斗云”名称、Logo 与官方视觉标识不包含在 MIT 授权中。修改版可以如实说明“基于筋斗云开发”，但不得冒充官方版本或暗示获得官方认可。详情见 [品牌政策](TRADEMARKS.md)。
