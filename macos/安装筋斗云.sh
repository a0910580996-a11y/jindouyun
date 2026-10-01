#!/usr/bin/env bash
set -euo pipefail

if [[ ! -d '/Applications/Hammerspoon.app' ]]; then
  echo '未找到 Hammerspoon.app。请先安装 Hammerspoon，再重新运行此脚本。' >&2
  exit 1
fi

source_dir="$(cd "$(dirname "$0")" && pwd)"
hammerspoon_dir="$HOME/.hammerspoon"
target_dir="$hammerspoon_dir/筋斗云"
root_init="$hammerspoon_dir/init.lua"
timestamp="$(date +%Y%m%d-%H%M%S)"

mkdir -p "$hammerspoon_dir"

if [[ -d "$target_dir" ]]; then
  cp -R "$target_dir" "$target_dir.backup-$timestamp"
fi

mkdir -p "$target_dir"
cp "$source_dir/init.lua" "$target_dir/init.lua"
cp "$source_dir/配置示例.lua" "$target_dir/配置示例.lua"
mkdir -p "$target_dir/袖里乾坤/锦囊"

if [[ ! -f "$target_dir/配置.lua" ]]; then
  cp "$source_dir/配置示例.lua" "$target_dir/配置.lua"
  echo '配置.lua: CREATED'
else
  echo '配置.lua: PRESERVED'
fi

loader="dofile(hs.configdir .. '/筋斗云/init.lua')"
if [[ ! -f "$root_init" ]]; then
  printf '%s\n' "$loader" > "$root_init"
elif ! grep -Fq "$loader" "$root_init"; then
  cp "$root_init" "$root_init.backup-$timestamp"
  printf '\n%s\n' "$loader" >> "$root_init"
fi

open -a Hammerspoon
echo 'macOS install: PASS'
echo '请在系统设置中授予 Hammerspoon 辅助功能权限，然后从菜单栏选择 Reload Config。'
