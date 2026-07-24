#!/bin/bash
# ============================================================
# Skill Security Pre-commit Hook
# Version: 2.4.0 (CI protected-files gate reference)
# Part of AI DevSecOps Pipeline (skill-security-scan.yml)
# Purpose: 本地提交前自动扫描 skill 文件，阻止危险 skill 提交，
#          并锁定安全策略文件防止未授权修改。
#
# ⚠️  CI 管道现在也会独立校验受保护文件：
#    即使使用 --no-verify 绕过本地 hook，推送/PR 后
#    CI 的 🔒 Protected Files Integrity 门禁仍会拦截未授权的修改。
#    放行方式：仅 PR 的 security-approved 标签（需 maintainer/triage 权限）。
#    commit message 中的 [SECURITY-APPROVED] 标记不再有效。
#
# 安装方式：
#   cp scripts/security/pre-commit-hook.sh .git/hooks/pre-commit
#   chmod +x .git/hooks/pre-commit
#
# 或使用符号链接：
#   ln -sf ../../scripts/security/pre-commit-hook.sh .git/hooks/pre-commit
# ============================================================

set -e  # 任何命令非零退出立即终止脚本

# ---------- 颜色输出 ----------
# ANSI 转义码，用于终端彩色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color — 重置所有格式

# ---------- 配置 ----------
SCAN_SCRIPT="scripts/security/ci-scan.sh"       # 安全扫描脚本路径
WHITELIST_FILE=".security-whitelist.yml"          # 扫描白名单配置文件

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
echo "  🔒 Skill 安全扫描 — Pre-commit Hook v2.4.0"
echo -e "=============================================${NC}"
echo ""

# ============================================================
# Gate 1: 受保护文件变更检测
# 检测暂存区中是否包含安全策略关键文件的修改。
# 这些文件定义了安全扫描规则、白名单和 CI 管道，随意修改可能
# 削弱安全防护能力，因此需要显式授权。
# ============================================================
# 获取所有暂存的文件（新增 A、复制 C、修改 M）
STAGED_ALL=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null || true)
PROTECTED_CHANGED=()

# 比对暂存文件与受保护文件列表，精确匹配（-Fx 表示固定字符串整行匹配）
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

  # 显式授权：ALLOW_PROTECTED=1 环境变量可绕过 Gate 1
  if [[ "${ALLOW_PROTECTED:-0}" == "1" ]]; then
    echo -e "${YELLOW}  ⚡ ALLOW_PROTECTED=1 已设置，放行。${NC}"
  else
    echo -e "${YELLOW}  如果确认修改是安全的，重新提交时设置：${NC}"
    echo ""
    echo -e "    ${BOLD}ALLOW_PROTECTED=1 git commit${NC}"
    echo ""
    echo -e "${YELLOW}  或跳过本地钩子（不推荐）：${NC}"
    echo -e "    ${BOLD}git commit --no-verify${NC}"
    echo -e "    ⚠️  --no-verify 仅跳过本地钩子。"
    echo -e "    ⚠️  推送/PR 后，CI 的 🔒 Protected Files Integrity 门禁仍会拦截！"
    echo -e "    ⚠️  放行需 PR 打 security-approved 标签（需 maintainer/triage 权限）。"
    echo ""
    exit 1
  fi

  echo -e "${GREEN}  ✅ 受保护文件变更已显式授权${NC}"
fi

# Gate 1 通过，继续 Gate 2
echo ""

# ============================================================
# Gate 2: Skill 文件安全扫描
# 对暂存的 skill markdown 文件运行 ci-scan.sh 安全扫描。
# 使用 --fail-on-high 模式：检测到 High/Critical 威胁则阻止提交。
# ============================================================
# 从暂存文件中筛选出 skills/ 和 .claude/skills/ 目录下的 .md 文件
STAGED_SKILL_FILES=$(echo "$STAGED_ALL" | grep -E '^(skills/|\.claude/skills/).*\.md$' || true)

# 无 skill 文件变更则提前退出
if [[ -z "$STAGED_SKILL_FILES" ]]; then
  echo -e "${GREEN}✅ 没有暂存的 skill 文件变更，跳过扫描${NC}"
  echo ""
  exit 0
fi

# 列出待扫描的 skill 文件供用户确认
echo "📋 检测到暂存的 skill 文件："
echo "$STAGED_SKILL_FILES" | while read -r f; do
  echo "   - $f"
done
echo ""

# ---------- 运行扫描脚本 ----------
# 检查扫描脚本是否存在（确保在项目根目录运行）
if [[ ! -f "$SCAN_SCRIPT" ]]; then
  echo -e "${RED}❌ 错误：找不到扫描脚本 $SCAN_SCRIPT${NC}"
  echo "   请确保在项目根目录下执行 git commit"
  exit 1
fi

# 确保脚本有执行权限
chmod +x "$SCAN_SCRIPT" 2>/dev/null || true

echo "🔍 正在扫描 skill 文件..."
echo ""

# 运行扫描（使用 fail-on-high 模式：High 及以上威胁阻止提交）
# 2>&1 合并 stderr 到 stdout，捕获所有输出供展示
SCAN_OUTPUT=$(bash "$SCAN_SCRIPT" \
  --scope skills \
  --scope .claude/skills \
  --fail-on-high \
  --whitelist "$WHITELIST_FILE" \
  2>&1) || SCAN_EXIT=$?  # || 防止 set -e 在扫描失败时中断脚本

echo "$SCAN_OUTPUT"
echo ""

# ---------- 解析结果 ----------
# SCAN_EXIT 未定义（扫描通过）时默认为 0
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
  echo "  ⚠️  注意：--no-verify 仅跳过本地 pre-commit hook。"
  echo "  ⚠️  推送/PR 后，CI 的 🔒 Protected Files Integrity 门禁仍会独立拦截！"
  echo "  ⚠️  放行需 PR 打 security-approved 标签（需 maintainer/triage 权限）。"
  echo ""

  exit 1
fi

echo -e "${GREEN}============================================="
echo "  ✅ 安全扫描通过"
echo -e "=============================================${NC}"
echo ""
exit 0
