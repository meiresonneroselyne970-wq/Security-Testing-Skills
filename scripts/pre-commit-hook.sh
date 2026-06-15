#!/bin/bash
# ============================================================
# Skill Security Pre-commit Hook
# Version: 1.0.0
# Purpose: 本地提交前自动扫描 skill 文件，阻止危险 skill 提交
#
# 安装方式：
#   cp scripts/pre-commit-hook.sh .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit
#
# 或使用符号链接：
#   ln -sf ../../scripts/pre-commit-hook.sh .git/hooks/pre-commit
# ============================================================

set -e

# ---------- 颜色输出 ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# ---------- 配置 ----------
SCAN_SCRIPT="scripts/ci-scan.sh"
WHITELIST_FILE=".security-whitelist.yml"

echo ""
echo -e "${CYAN}============================================="
echo "  🔒 Skill 安全扫描 — Pre-commit Hook"
echo -e "=============================================${NC}"
echo ""

# ---------- 检测是否有 skill 文件被暂存 ----------
STAGED_SKILL_FILES=$(git diff --cached --name-only --diff-filter=ACM | grep -E '^(skills/|\.claude/skills/).*\.md$' || true)

if [[ -z "$STAGED_SKILL_FILES" ]]; then
  echo -e "${GREEN}✅ 没有暂存的 skill 文件变更，跳过扫描${NC}"
  echo ""
  exit 0
fi

echo "📋 检测到暂存的 skill 文件："
echo "$STAGED_SKILL_FILES" | while read -r f; do
  echo "   - $f"
done
echo ""

# ---------- 运行扫描脚本 ----------
if [[ ! -f "$SCAN_SCRIPT" ]]; then
  echo -e "${RED}❌ 错误：找不到扫描脚本 $SCAN_SCRIPT${NC}"
  echo "   请确保在项目根目录下执行 git commit"
  exit 1
fi

# 确保脚本可执行
chmod +x "$SCAN_SCRIPT" 2>/dev/null || true

echo "🔍 正在扫描 skill 文件..."
echo ""

# 运行扫描（使用 strict 模式：中危及以上阻止提交）
SCAN_OUTPUT=$(bash "$SCAN_SCRIPT" \
  --scope skills \
  --scope .claude/skills \
  --fail-on-high \
  --whitelist "$WHITELIST_FILE" \
  2>&1) || SCAN_EXIT=$?

echo "$SCAN_OUTPUT"
echo ""

# ---------- 解析结果 ----------
if [[ ${SCAN_EXIT:-0} -ne 0 ]]; then
  echo ""
  echo -e "${RED}============================================="
  echo "  🚫 提交被阻止！"
  echo "=============================================${NC}"
  echo ""
  echo -e "${RED}检测到危险的 skill 文件变更。${NC}"
  echo ""
  echo "修复方式："
  echo "  1. 检查上方扫描结果，定位威胁来源"
  echo "  2. 移除恶意代码、硬编码凭据、安全绕过指令等"
  echo "  3. 如果是测试文件，将其加入 $WHITELIST_FILE 白名单"
  echo "  4. 重新 git add && git commit"
  echo ""
  echo -e "${YELLOW}如果确认安全但仍被阻止，可使用：${NC}"
  echo "  git commit --no-verify"
  echo "  ⚠️  注意：这也会跳过 CI 流水线中的安全扫描"
  echo ""

  exit 1
fi

echo -e "${GREEN}============================================="
echo "  ✅ 安全扫描通过"
echo -e "=============================================${NC}"
echo ""
exit 0
