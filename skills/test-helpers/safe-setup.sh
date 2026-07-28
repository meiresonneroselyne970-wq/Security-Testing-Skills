#!/bin/bash
# ============================================================
# 安全的测试环境初始化脚本
# 供测试 Skill 引用，验证 ShellCheck 和 execution-gate
# 不会对合法 Shell 脚本产生误报。
# ============================================================
set -euo pipefail

# 颜色定义（仅在终端输出时启用）
if [[ -t 1 ]]; then
  COLOR_GREEN='\033[0;32m'
  COLOR_YELLOW='\033[1;33m'
  COLOR_RED='\033[0;31m'
  COLOR_RESET='\033[0m'
else
  COLOR_GREEN=''
  COLOR_YELLOW=''
  COLOR_RED=''
  COLOR_RESET=''
fi

# ---------- 安全工具函数 ----------

# 安全的目录创建（带存在性检查）
safe_mkdir() {
  local dir="$1"
  if [[ -d "$dir" ]]; then
    echo -e "${COLOR_YELLOW}[SKIP]${COLOR_RESET} 目录已存在: $dir"
  else
    mkdir -p "$dir"
    echo -e "${COLOR_GREEN}[OK]${COLOR_RESET} 创建目录: $dir"
  fi
}

# 安全的文件拷贝（带覆盖确认）
safe_copy() {
  local src="$1"
  local dst="$2"

  if [[ ! -f "$src" ]]; then
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} 源文件不存在: $src"
    return 1
  fi

  if [[ -f "$dst" ]]; then
    echo -e "${COLOR_YELLOW}[SKIP]${COLOR_RESET} 目标已存在，跳过: $dst"
    return 0
  fi

  cp "$src" "$dst"
  echo -e "${COLOR_GREEN}[OK]${COLOR_RESET} 拷贝: $src -> $dst"
}

# 安全的文件内容检查
safe_contains() {
  local file="$1"
  local pattern="$2"

  if [[ ! -f "$file" ]]; then
    echo -e "${COLOR_RED}[ERROR]${COLOR_RESET} 文件不存在: $file"
    return 1
  fi

  if grep -q "$pattern" "$file"; then
    echo -e "${COLOR_GREEN}[FOUND]${COLOR_RESET} 在 $file 中找到匹配: $pattern"
    return 0
  else
    echo -e "${COLOR_YELLOW}[NOT FOUND]${COLOR_RESET} 在 $file 中未找到: $pattern"
    return 1
  fi
}

# ---------- 主流程 ----------

main() {
  echo "============================================"
  echo "  测试环境初始化"
  echo "============================================"
  echo ""

  # 创建测试目录结构
  safe_mkdir "./test-output"
  safe_mkdir "./test-output/logs"
  safe_mkdir "./test-output/data"

  echo ""
  echo "============================================"
  echo "  初始化完成"
  echo "============================================"
}

# 仅在直接执行时运行 main
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  main "$@"
fi
