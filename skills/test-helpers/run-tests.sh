#!/bin/bash
# ============================================================
# Skill 安全扫描 — 测试套件运行器
# 用于快速运行扫描器，验证安全测试 Skill 的检测/豁免效果
# ============================================================
set -euo pipefail

SCANNER="scripts/security/ci-scan.sh"
SKILLS_DIR="skills"

# 颜色
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
BOLD='\033[1m'
RESET='\033[0m'

pass()  { echo -e "${GREEN}[PASS]${RESET} $*"; }
fail()  { echo -e "${RED}[FAIL]${RESET} $*"; }
info()  { echo -e "${CYAN}[INFO]${RESET} $*"; }
warn()  { echo -e "${YELLOW}[WARN]${RESET} $*"; }

# 对指定目录运行扫描并返回完整输出
run_scan() {
  local scope="$1"
  shift
  bash "$SCANNER" --scope "$scope" "$@" 2>&1 || true
}

# ---------- 测试 1: 合法 Skill 应通过扫描 ----------
test_safe_skill() {
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${BOLD}  测试 1: 安全 Skill — 应完全通过${RESET}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo ""

  local output
  output=$(run_scan "$SKILLS_DIR")

  # 检查 safe-skill.md 是否有任何告警
  local safe_alerts
  safe_alerts=$(echo "$output" | grep "safe-skill.md" | grep -E "\[CRITICAL\]|\[HIGH\]|\[MEDIUM\]" || true)

  if [[ -z "$safe_alerts" ]]; then
    pass "safe-skill.md 通过扫描 — 0 个威胁告警（无 False Positive）"
    return 0
  else
    echo "$safe_alerts"
    fail "safe-skill.md 产生误报！"
    return 1
  fi
}

# ---------- 测试 2: 检测测试应触发告警 ----------
test_detection() {
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${BOLD}  测试 2: 威胁检测 — 应触发 T1-T6 各类告警${RESET}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo ""

  local output
  output=$(run_scan "$SKILLS_DIR")

  # 统计 detection-test.md 的各类告警
  local critical_count high_count medium_count
  critical_count=$(echo "$output" | grep "detection-test.md" | grep -c "\[CRITICAL\]" || true)
  high_count=$(echo "$output" | grep "detection-test.md" | grep -c "\[HIGH\]" || true)
  medium_count=$(echo "$output" | grep "detection-test.md" | grep -c "\[MEDIUM\]" || true)
  local total=$((critical_count + high_count + medium_count))

  info "detection-test.md 告警分布: Critical=$critical_count, High=$high_count, Medium=$medium_count (总计=$total)"

  # 检查是否覆盖了多种威胁类型
  local t1_count t2_count t3_count t5_count t6_count
  t1_count=$(echo "$output" | grep "detection-test.md" | grep -c "T1\." || true)
  t2_count=$(echo "$output" | grep "detection-test.md" | grep -c "T2\." || true)
  t3_count=$(echo "$output" | grep "detection-test.md" | grep -c "T3\." || true)
  t5_count=$(echo "$output" | grep "detection-test.md" | grep -c "T5\." || true)
  t6_count=$(echo "$output" | grep "detection-test.md" | grep -c "T6\." || true)

  info "威胁类别覆盖: T1=$t1_count, T2=$t2_count, T3=$t3_count, T5=$t5_count, T6=$t6_count"

  local categories_covered=0
  [[ $t1_count -gt 0 ]] && categories_covered=$((categories_covered + 1))
  [[ $t2_count -gt 0 ]] && categories_covered=$((categories_covered + 1))
  [[ $t3_count -gt 0 ]] && categories_covered=$((categories_covered + 1))
  [[ $t5_count -gt 0 ]] && categories_covered=$((categories_covered + 1))
  [[ $t6_count -gt 0 ]] && categories_covered=$((categories_covered + 1))

  if [[ $total -ge 10 && $categories_covered -ge 3 ]]; then
    pass "detection-test.md: $total 个告警, 覆盖 $categories_covered/5 类威胁 — 检测能力正常"
    return 0
  elif [[ $total -ge 5 ]]; then
    warn "detection-test.md: $total 个告警 — 告警数达标但覆盖类别较少"
    return 0
  else
    fail "detection-test.md: 仅 $total 个告警（预期 ≥10）— 检测能力可能不足"
    return 1
  fi
}

# ---------- 测试 3: sec-ignore 应豁免标记的行 ----------
test_sec_ignore() {
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${BOLD}  测试 3: sec-ignore 内联豁免${RESET}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo ""

  local output
  output=$(run_scan "$SKILLS_DIR")

  # 统计 SUPPRESSED (被豁免的)
  local suppressed_count
  suppressed_count=$(echo "$output" | grep "sec-ignore-demo.md" | grep -c "SUPPRESSED" || true)

  # 统计 CRITICAL (未被豁免的告警 — 即故意不加豁免的那些行)
  local unsuppressed_count
  unsuppressed_count=$(echo "$output" | grep "sec-ignore-demo.md" | grep -c "\[CRITICAL\]" || true)

  info "sec-ignore-demo.md: 豁免 $suppressed_count 条, 未豁免(应检测) $unsuppressed_count 条"

  if [[ $suppressed_count -ge 3 && $unsuppressed_count -ge 1 ]]; then
    pass "sec-ignore-demo.md: $suppressed_count 条被豁免, $unsuppressed_count 条被检测 — sec-ignore 机制正常"
    return 0
  elif [[ $suppressed_count -ge 1 ]]; then
    warn "sec-ignore-demo.md: $suppressed_count 条豁免 — 部分工作但数据偏少"
    return 0
  else
    fail "sec-ignore-demo.md: 0 条被豁免 — sec-ignore 机制可能失效"
    return 1
  fi
}

# ---------- 测试 4: 全量扫描总览 ----------
test_full_scan() {
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${BOLD}  测试 4: 全量扫描总览${RESET}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo ""

  local output
  output=$(run_scan "$SKILLS_DIR" --format json)

  # 提取威胁分数
  local threat_score files_scanned risk_level
  threat_score=$(echo "$output" | grep -o '"ThreatScore": [0-9]*' | grep -o '[0-9]*' | head -1 || echo "0")
  files_scanned=$(echo "$output" | grep -o '"ScanFileCount": [0-9]*' | grep -o '[0-9]*' | head -1 || echo "0")
  risk_level=$(echo "$output" | grep -o '"RiskLevel": "[^"]*"' | sed 's/"RiskLevel": "//;s/"//' | head -1 || echo "Unknown")

  info "扫描文件数: $files_scanned"
  info "威胁总分: $threat_score"
  info "风险等级: $risk_level"

  if [[ $files_scanned -ge 3 && $threat_score -gt 0 ]]; then
    pass "全量扫描: $files_scanned 个文件, 威胁分数 $threat_score ($risk_level) — 正常"
    return 0
  elif [[ $files_scanned -ge 3 ]]; then
    pass "全量扫描: $files_scanned 个文件 — 扫描正常"
    return 0
  else
    fail "全量扫描: 仅扫描 $files_scanned 个文件 — 可能未正确扫描"
    return 1
  fi
}

# ---------- 主流程 ----------
main() {
  echo ""
  echo -e "${BOLD}╔══════════════════════════════════════════════════════╗${RESET}"
  echo -e "${BOLD}║     Skill 安全扫描 — 测试套件                        ║${RESET}"
  echo -e "${BOLD}║     测试版本: v2.2.0                                  ║${RESET}"
  echo -e "${BOLD}╚══════════════════════════════════════════════════════╝${RESET}"

  if [[ ! -f "$SCANNER" ]]; then
    fail "扫描器不存在: $SCANNER"
    exit 1
  fi

  info "扫描器: $SCANNER"
  info "扫描目标: $SKILLS_DIR/"
  info ""

  local passed=0 failed=0

  # 运行所有测试
  test_safe_skill    && passed=$((passed + 1)) || failed=$((failed + 1))
  test_detection     && passed=$((passed + 1)) || failed=$((failed + 1))
  test_sec_ignore    && passed=$((passed + 1)) || failed=$((failed + 1))
  test_full_scan     && passed=$((passed + 1)) || failed=$((failed + 1))

  # 汇总
  echo ""
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${BOLD}  测试结果汇总${RESET}"
  echo -e "${BOLD}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "  ${GREEN}通过: $passed${RESET}"
  echo -e "  ${RED}失败: $failed${RESET}"
  echo ""

  if [[ $failed -eq 0 ]]; then
    echo -e "${GREEN}✅ 所有测试通过！安全扫描器工作正常。${RESET}"
    return 0
  else
    echo -e "${RED}❌ $failed 个测试失败，请检查扫描器配置。${RESET}"
    return 1
  fi
}

main "$@"
