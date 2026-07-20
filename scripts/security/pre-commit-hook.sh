#!/bin/bash
# ============================================================
# Skill Security Pre-commit Hook
# Version: 2.3.0 (Added protected-files gate)
# Part of AI DevSecOps Pipeline (skill-security-scan.yml)
# Purpose: 本地提交前自动扫描 skill 文件，阻止危险 skill 提交，
#          并锁定安全策略文件防止未授权修改。
#
# 安装方式：
#   cp scripts/security/pre-commit-hook.sh .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit
#
# 或使用符号链接：
#   ln -sf ../../scripts/security/pre-commit-hook.sh .git/hooks/pre-commit
# ============================================================

set -e

# ---------- 颜色输出 ----------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# ---------- 配置 ----------
SCAN_SCRIPT="scripts/security/ci-scan.sh"
WHITELIST_FILE=".security-whitelist.yml"

# ============================================================
#  受保护文件列表 — 修改这些文件需显式确认
# ============================================================
PROTECTED_FILES=(
  ".github/workflows/skill-security-scan.yml"
  ".security-whitelist.yml"
  ".github/CODEOWNERS"
  "scripts/security/pre-commit-hook.sh"
  "scripts/security/ci-scan.sh"
  "scripts/security/skill-security-scan.ps1"
  "scripts/security/skill-security-scan.bat"
  "scripts/security/sandbox_sdk.py"
  ".claude/skills/security-audit.md"
  ".claude/skills/skill-security-policy.md"
  ".claude/skills/skill-security-scanner.md"
)

echo ""
echo -e "${CYAN}============================================="
echo "  🔒 Skill 安全扫描 — Pre-commit Hook v2.3.0"
echo -e "=============================================${NC}"
echo ""

# ============================================================
# Gate 1: 受保护文件变更检测
# ============================================================
STAGED_ALL=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true)
PROTECTED_CHANGED=()

for pf in "${PROTECTED_FILES[@]}"; do
  if echo "$STAGED_ALL" | grep -Fxq "$pf"; then
    PROTECTED_CHANGED+=("$pf")
  fi
done

if [[ ${#PROTECTED_CHANGED[@]} -gt 0 ]]; then
  echo -e "${YELLOW}╔══════════════════════════════════════════════════╗"
  echo -e "║  ⚠️  检测到受保护文件变更                           ║"
  echo -e "╚══════════════════════════════════════════════════╝${NC}"
  echo ""
  echo -e "  以下安全策略文件已被修改："
  for f in "${PROTECTED_CHANGED[@]}"; do
    echo -e "    ${RED}🔒 $f${NC}"
  done
  echo ""
  echo -e "  这些文件的修改会影响安全扫描管道的完整性。"
  echo -e "  GitHub 端需通过 CODEOWNERS 审批才能合入。"
  echo ""

  if [[ "${ALLOW_PROTECTED:-0}" == "1" ]]; then
    echo -e "${YELLOW}  ⚡ ALLOW_PROTECTED=1 已设置，放行。${NC}"
  else
    echo -e "${YELLOW}  如果确认修改是安全的，重新提交时设置：${NC}"
    echo ""
    echo -e "    ${BOLD}ALLOW_PROTECTED=1 git commit${NC}"
    echo ""
    echo -e "${YELLOW}  或跳过本地钩子（不推荐）：${NC}"
    echo -e "    ${BOLD}git commit --no-verify${NC}"
    echo -e "    ⚠️  --no-verify 仅跳过本地钩子，CI 管道仍会独立扫描"
    echo ""
    exit 1
  fi

  echo -e "${GREEN}  ✅ 受保护文件变更已显式授权${NC}"
fi

# Gate 1 通过，继续 Gate 2
echo ""

# ============================================================
# Gate 2: Skill 文件安全扫描
# ============================================================
STAGED_SKILL_FILES=$(echo "$STAGED_ALL" | grep -E '^(skills/|\.claude/skills/).*\.md$' || true)

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
  echo "  ⚠️  注意：--no-verify 仅跳过本地 pre-commit hook，推送后 AI DevSecOps 管道仍会独立扫描"
  echo ""

  exit 1
fi

echo -e "${GREEN}============================================="
echo "  ✅ 安全扫描通过"
echo -e "=============================================${NC}"
echo ""
exit 0
