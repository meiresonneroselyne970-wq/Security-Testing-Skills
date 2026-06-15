#!/bin/bash
# ============================================================
# Skill Security Scanner — Bash / CI Version
# Version: 2.0.0
# Purpose: Automated security scanning of skill files in CI/CD
# Compatible: Gitee Go, GitHub Actions, GitLab CI, local Linux/macOS
# ============================================================
set -o pipefail

# Force UTF-8 locale
export LC_ALL=C.UTF-8 2>/dev/null || export LC_ALL=en_US.UTF-8 2>/dev/null || true

# Auto-detect CI: disable color if not a real terminal
if [[ ! -t 1 ]] || [[ -n "$CI" ]] || [[ -n "$GITEE_PIPELINE_BUILD_NUMBER" ]]; then
  NO_COLOR=true
fi

# ---------- Configurable Defaults ----------
SCOPE_DIRS=()
OUTPUT_FORMAT="text"
OUTPUT_FILE=""
FAIL_ON_MEDIUM=false
FAIL_ON_HIGH=false
STRICT_MODE=false
QUIET_MODE=false
WHITELIST_FILE=".security-whitelist.yml"

# ---------- Scoring ----------
declare -i CRITICAL_WEIGHT=10
declare -i HIGH_WEIGHT=7
declare -i MEDIUM_WEIGHT=4
declare -i LOW_WEIGHT=1
declare -i REJECT_THRESHOLD=12
declare -i HIGH_THRESHOLD=8
declare -i MEDIUM_THRESHOLD=4

# ---------- State ----------
declare -i THREAT_SCORE=0
declare -i TOTAL_FILES=0
declare -i CRITICAL_COUNT=0
declare -i HIGH_COUNT=0
declare -i MEDIUM_COUNT=0
declare -i LOW_COUNT=0
declare -a THREATS_JSON=()
declare -a FILE_WHITELIST=()
declare -a SKIP_PATTERNS=()

# ---------- Help ----------
usage() {
  cat <<EOF
Usage: $0 [OPTIONS]
Options:
  --scope <dir>         Scan directory (repeatable)
  --output <file>       Write JSON report to file
  --format json|text    Output format (default: text)
  --fail-on-high        Exit 1 if High+ threats found
  --strict              Exit 1 on Medium+ threats
  --quiet               Suppress non-error output
  --whitelist <file>    Whitelist config path
  -h, --help            Show this help
EOF
  exit 2
}

# ---------- Color helpers (auto-disabled in CI) ----------
if [[ -n "$NO_COLOR" ]]; then
  C_RESET=""; C_CYAN=""; C_GREEN=""; C_YELLOW=""; C_RED=""; C_MAGENTA=""; C_BOLD_RED=""
else
  C_RESET="\033[0m"; C_CYAN="\033[36m"; C_GREEN="\033[32m"
  C_YELLOW="\033[33m"; C_RED="\033[31m"; C_MAGENTA="\033[35m"; C_BOLD_RED="\033[1;31m"
fi

# ---------- Logging ----------
log_info()  { $QUIET_MODE || echo -e "${C_CYAN}[INFO]${C_RESET} $*"; }
log_pass()  { $QUIET_MODE || echo -e "${C_GREEN}[PASS]${C_RESET} $*"; }
log_warn()  { echo -e "${C_YELLOW}[WARN]${C_RESET} $*"; }
log_error() { echo -e "${C_RED}[ERROR]${C_RESET} $*" >&2; }

# ---------- Parse Arguments ----------
parse_args() {
  while [[ $# -gt 0 ]]; do
    case "$1" in
      --scope)  SCOPE_DIRS+=("$2"); shift 2 ;;
      --output) OUTPUT_FILE="$2"; OUTPUT_FORMAT="json"; shift 2 ;;
      --format) OUTPUT_FORMAT="$2"; shift 2 ;;
      --fail-on-high) FAIL_ON_HIGH=true; shift ;;
      --strict) STRICT_MODE=true; shift ;;
      --quiet)  QUIET_MODE=true; shift ;;
      --whitelist) WHITELIST_FILE="$2"; shift 2 ;;
      -h|--help) usage ;;
      *) log_error "Unknown option: $1"; usage ;;
    esac
  done
}

# ---------- Load Whitelist ----------
load_whitelist() {
  if [[ ! -f "$WHITELIST_FILE" ]]; then
    log_info "No whitelist file at $WHITELIST_FILE"
    return
  fi
  log_info "Loading whitelist from $WHITELIST_FILE"

  local in_section=false
  while IFS= read -r line; do
    if $in_section && [[ "$line" =~ ^[[:space:]]*-[[:space:]]*\"(.+)\"$ ]]; then
      FILE_WHITELIST+=("${BASH_REMATCH[1]}")
    elif [[ "$line" == "file_whitelist:" ]]; then
      in_section=true
    elif [[ "$line" =~ ^[a-z] ]]; then
      in_section=false
    fi
  done < "$WHITELIST_FILE"

  if [[ ${#FILE_WHITELIST[@]} -gt 0 ]]; then
    log_info "Whitelisted: ${FILE_WHITELIST[*]}"
  fi

  local in_patterns=false
  while IFS= read -r line; do
    if $in_patterns && [[ "$line" =~ ^[[:space:]]*-[[:space:]]*\"(.+)\"$ ]]; then
      SKIP_PATTERNS+=("${BASH_REMATCH[1]}")
    elif [[ "$line" == "pattern_whitelist:" ]]; then
      in_patterns=true
    elif [[ "$line" =~ ^[a-z] ]] && $in_patterns; then
      in_patterns=false
    fi
  done < "$WHITELIST_FILE"
}

# ---------- Whitelist Check ----------
is_whitelisted() {
  local file="$1"
  for wf in "${FILE_WHITELIST[@]}"; do
    [[ "$file" == $wf ]] && return 0
  done
  return 1
}

should_skip_line() {
  local line_lower
  line_lower=$(echo "$1" | tr '[:upper:]' '[:lower:]')
  for pattern in "${SKIP_PATTERNS[@]}"; do
    if [[ "$line_lower" =~ $pattern ]]; then
      return 0
    fi
  done
  return 1
}

# ---------- Record Threat ----------
record_threat() {
  local rule_id="$1" category="$2" severity="$3" file="$4" line_num="$5"
  local match="$6" description="$7" recommendation="$8"

  local weight=0
  case "$severity" in
    Critical) weight=$CRITICAL_WEIGHT; CRITICAL_COUNT=$((CRITICAL_COUNT + 1)) ;;
    High)     weight=$HIGH_WEIGHT;     HIGH_COUNT=$((HIGH_COUNT + 1)) ;;
    Medium)   weight=$MEDIUM_WEIGHT;   MEDIUM_COUNT=$((MEDIUM_COUNT + 1)) ;;
    Low)      weight=$LOW_WEIGHT;      LOW_COUNT=$((LOW_COUNT + 1)) ;;
  esac
  THREAT_SCORE=$((THREAT_SCORE + weight))

  local safe_match
  safe_match=$(echo "$match" | sed 's/"/\\"/g' | cut -c1-80)

  local sev_disp
  case "$severity" in
    Critical) sev_disp="${C_BOLD_RED}[CRITICAL]${C_RESET}" ;;
    High)     sev_disp="${C_MAGENTA}[HIGH]${C_RESET}" ;;
    Medium)   sev_disp="${C_YELLOW}[MEDIUM]${C_RESET}" ;;
    Low)      sev_disp="${C_GREEN}[LOW]${C_RESET}" ;;
  esac

  if ! $QUIET_MODE; then
    echo -e "  ${sev_disp} ${rule_id} — ${file}:${line_num}"
    echo -e "    ${description}"
  fi

  if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    THREATS_JSON+=("{ \"RuleId\": \"${rule_id}\", \"Category\": \"${category}\", \"Severity\": \"${severity}\", \"File\": \"${file}\", \"Line\": ${line_num}, \"Match\": \"${safe_match}\", \"Description\": \"${description}\", \"Recommendation\": \"${recommendation}\" }")
  fi
}

# ---------- Scan Single File (fast: uses bash built-in [[ =~ ]]) ----------
scan_file() {
  local file="$1"

  if is_whitelisted "$file"; then
    log_info "Skipping whitelisted: $file"
    return
  fi

  [[ ! -f "$file" || ! -r "$file" || ! -s "$file" ]] && return

  TOTAL_FILES=$((TOTAL_FILES + 1))
  log_info "Scanning: $file"

  local line_num=0 found=false line line_lower

  while IFS= read -r line || [[ -n "$line" ]]; do
    line_num=$((line_num + 1))
    [[ -z "$line" ]] && continue

    # Skip documentation patterns (check once)
    line_lower=$(echo "$line" | tr '[:upper:]' '[:lower:]')
    should_skip_line "$line_lower" && continue

    # === T1: Malicious Command Injection ===

    # T1.1: System command execution
    if [[ "$line_lower" =~ exec\(|system\(|popen\(|subprocess\.call|subprocess\.run|os\.system|child_process\.exec|child_process\.spawn|eval\(|shell_exec|passthru ]]; then
      record_threat "T1.1" "Malicious Command" "Critical" "$file" "$line_num" "${line:0:80}" \
        "检测到系统命令执行函数" "移除系统命令执行函数，使用安全的替代方案"
      found=true
    fi

    # T1.2: File system destruction
    if [[ "$line_lower" =~ rm\ -rf|rm\ -r\ /|rmdir\ /s|del\ /f|unlink|rmdir|shutil\.rmtree|fs\.rmdir|fs\.unlink ]]; then
      record_threat "T1.2" "Malicious Command" "Critical" "$file" "$line_num" "${line:0:80}" \
        "检测到文件系统破坏命令" "移除文件系统破坏命令，使用安全的文件操作"
      found=true
    fi

    # T1.3: Network data exfiltration
    if [[ "$line_lower" =~ curl.*POST|wget.*POST|fetch\(.*POST|XMLHttpRequest|axios\.post|requests\.post|urllib.*urlopen ]]; then
      record_threat "T1.3" "Malicious Command" "Critical" "$file" "$line_num" "${line:0:80}" \
        "检测到数据外传操作" "验证数据传输合法性，移除非必要的网络请求"
      found=true
    fi

    # T1.4: Reverse shell
    if [[ "$line_lower" =~ bash\ -i|nc\ -e|ncat|socat|/dev/tcp|mkfifo|reverse.*shell ]]; then
      record_threat "T1.4" "Malicious Command" "Critical" "$file" "$line_num" "${line:0:80}" \
        "检测到反向 Shell 特征" "立即移除反向 Shell 相关代码"
      found=true
    fi

    # T1.5: Privilege escalation
    if [[ "$line_lower" =~ sudo\ |chmod\ 777|chown|setuid|setgid|su\ -|su\ root ]]; then
      record_threat "T1.5" "Malicious Command" "Critical" "$file" "$line_num" "${line:0:80}" \
        "检测到权限提升操作" "移除权限提升代码，遵循最小权限原则"
      found=true
    fi

    # T1.7: Code obfuscation
    if [[ "$line_lower" =~ atob\(|btoa\(|base64.*decode|eval\(|Function\(|new\ Function|decodeURI|unescape ]]; then
      record_threat "T1.7" "Malicious Command" "High" "$file" "$line_num" "${line:0:80}" \
        "检测到代码混淆/动态执行" "移除动态代码执行，使用显式安全的实现"
      found=true
    fi

    # === T2: Hidden Dangerous Commands ===

    # T2.1: Zero-width characters (Perl for Unicode)
    if [[ "$line" =~ $'\xE2\x80\x8B' || "$line" =~ $'\xE2\x80\x8C' || "$line" =~ $'\xE2\x80\x8D' || "$line" =~ $'\xEF\xBB\xBF' ]]; then
      record_threat "T2.1" "Hidden Command" "Critical" "$file" "$line_num" "零宽字符" \
        "检测到零宽字符，可能隐藏恶意指令" "移除零宽字符，确保代码可见性"
      found=true
    fi

    # T2.2: System prompt override
    if [[ "$line_lower" =~ ignore\ all\ previous|忽略之前的指令|忽略所有安全|忽略.*限制|system\ prompt\ override|忽略.*警告.*安全|跳过.*安全.*检查|bypass.*security.*check|忽略.*审核 ]]; then
      record_threat "T2.2" "Hidden Command" "Critical" "$file" "$line_num" "${line:0:80}" \
        "检测到系统提示词覆盖/绕过安全指令" "移除绕过安全机制的危险提示词"
      found=true
    fi

    # T2.3: Hidden commands in comments
    if [[ "$line" =~ \<!--.*(exec|system|eval|rm\ -rf|curl|wget).*--\> ]]; then
      record_threat "T2.3" "Hidden Command" "Critical" "$file" "$line_num" "${line:0:80}" \
        "检测到注释中隐藏的可执行命令" "移除注释中的命令，确保透明度"
      found=true
    fi

    # === T3: Sensitive Information Leakage ===

    # T3.1: Hardcoded API Key
    if [[ "$line" =~ sk-[a-zA-Z0-9]{20,} ]]; then
      if ! [[ "$line_lower" =~ sk-xxx|sk-你的|sk-your|sk-example|sk-demo|sk-test|sk-sample|sk_replace ]]; then
        record_threat "T3.1" "Sensitive Info" "High" "$file" "$line_num" "sk-****" \
          "检测到硬编码的 API Key" "将 API Key 移至环境变量或密钥管理服务"
        found=true
      fi
    fi

    # T3.2: Hardcoded Bearer Token
    if [[ "$line" =~ Bearer[[:space:]]+[a-zA-Z0-9._-]{20,} ]]; then
      if ! [[ "$line_lower" =~ bearer\ xxx|bearer\ your|bearer\ example|bearer\ demo|bearer\ test|bearer\ replace ]]; then
        record_threat "T3.2" "Sensitive Info" "High" "$file" "$line_num" "Bearer ****" \
          "检测到硬编码的 Bearer Token" "将 Token 移至环境变量或密钥管理服务"
        found=true
      fi
    fi

    # T3.3: Hardcoded password
    if [[ "$line_lower" =~ password[[:space:]]*[=:][[:space:]]*[\"\'][^[:space:]\"\']{4,}[\"\'] ]]; then
      if ! [[ "$line_lower" =~ placeholder|替换|示例|example|demo|test|replace ]]; then
        record_threat "T3.3" "Sensitive Info" "High" "$file" "$line_num" "password=****" \
          "检测到硬编码的密码" "将密码移至环境变量或密钥管理服务"
        found=true
      fi
    fi

    # T3.4: Private key
    if [[ "$line" =~ -----BEGIN[[:space:]]+(RSA[[:space:]]+)?PRIVATE[[:space:]]+KEY ]]; then
      record_threat "T3.4" "Sensitive Info" "High" "$file" "$line_num" "PRIVATE KEY" \
        "检测到硬编码的私钥" "私钥必须存储在安全的密钥管理服务中"
      found=true
    fi

    # === T5: Social Engineering Attacks ===

    # T5.1: Credential solicitation
    if [[ "$line_lower" =~ enter.*password|provide.*token|input.*api.*key|请.*输入.*密码|输入.*token|提供.*密钥|请输入.*API ]]; then
      record_threat "T5.1" "Social Engineering" "Critical" "$file" "$line_num" "${line:0:80}" \
        "检测到凭据诱导语句（社会工程攻击）" "移除凭据诱导语句，使用安全的认证流程"
      found=true
    fi

    # T5.2: Urgency inducement
    if [[ "$line_lower" =~ 立即.*执行|马上.*运行|urgent|immediately|asap|紧急.*处理|不.*执行.*将会|马上.*否则 ]]; then
      record_threat "T5.2" "Social Engineering" "Medium" "$file" "$line_num" "${line:0:80}" \
        "检测到紧急诱导语句" "移除紧急诱导措辞，避免用户仓促操作"
      found=true
    fi

    # T5.4: Security bypass inducement
    if [[ "$line_lower" =~ ignore.*warning|skip.*check|bypass.*security|忽略.*警告|跳过.*检测|绕过.*安全|disable.*security ]]; then
      record_threat "T5.4" "Social Engineering" "Critical" "$file" "$line_num" "${line:0:80}" \
        "检测到安全绕过诱导语句" "移除安全绕过语句，尊重安全机制"
      found=true
    fi

    # === T6: Dependency & Supply Chain Risks ===

    # T6.1: External script reference (only flag http/https URLs, not local paths)
    if [[ "$line" =~ \<script[[:space:]]+src=[\"\']https?:// ]]; then
      record_threat "T6.1" "Dependency Risk" "Medium" "$file" "$line_num" "${line:0:80}" \
        "检测到外部脚本引用" "验证外部脚本来源可信，优先使用官方 CDN"
      found=true
    fi

    # T6.2: Non-whitelist CDN reference
    if [[ "$line_lower" =~ cdn\.|unpkg\.|jsdelivr\. ]]; then
      if ! [[ "$line_lower" =~ cdnjs\.cloudflare\.com|unpkg\.com|jsdelivr\.net|cdn\.jsdelivr\.net|cdn\.bootcdn\.net|lib\.baomitu\.com ]]; then
        record_threat "T6.2" "Dependency Risk" "Medium" "$file" "$line_num" "${line:0:80}" \
          "检测到非白名单 CDN 引用" "使用受信任的 CDN 来源，或将此来源加入白名单"
        found=true
      fi
    fi

  done < "$file"

  $found || log_pass "$file — 安全"
}

# ---------- Scan Directory ----------
scan_directory() {
  local dir="$1"
  [[ ! -d "$dir" ]] && return
  while IFS= read -r -d '' file; do
    scan_file "$file"
  done < <(find "$dir" -type f -name "*.md" -print0 2>/dev/null || true)
}

# ---------- Status Helpers ----------
get_review_status() {
  if [[ $THREAT_SCORE -ge $REJECT_THRESHOLD ]]; then echo "Reject"
  elif [[ $THREAT_SCORE -ge $HIGH_THRESHOLD ]]; then echo "Manual Review"
  elif [[ $THREAT_SCORE -ge $MEDIUM_THRESHOLD ]]; then echo "Manual Review"
  elif [[ $THREAT_SCORE -ge 1 ]]; then echo "Pass"
  else echo "Pass"; fi
}

get_risk_level() {
  if [[ $THREAT_SCORE -ge $REJECT_THRESHOLD ]]; then echo "Critical"
  elif [[ $THREAT_SCORE -ge $HIGH_THRESHOLD ]]; then echo "High"
  elif [[ $THREAT_SCORE -ge $MEDIUM_THRESHOLD ]]; then echo "Medium"
  elif [[ $THREAT_SCORE -ge 1 ]]; then echo "Low"
  else echo "Safe"; fi
}

# ---------- Generate JSON Report ----------
generate_json_report() {
  local report_id="SSS-$(date +%Y%m%d)-$((RANDOM % 9000 + 1000))"
  local scan_time risk_level review_status scope_str
  scan_time=$(date '+%Y-%m-%d %H:%M:%S')
  review_status=$(get_review_status)
  risk_level=$(get_risk_level)
  scope_str=$(IFS=,; echo "${SCOPE_DIRS[*]}")

  printf '{\n'
  printf '  "ReportId": "%s",\n' "$report_id"
  printf '  "ScanTime": "%s",\n' "$scan_time"
  printf '  "ScanScope": "%s",\n' "$scope_str"
  printf '  "ScanFileCount": %d,\n' "$TOTAL_FILES"
  printf '  "ReviewStatus": "%s",\n' "$review_status"
  printf '  "ThreatScore": %d,\n' "$THREAT_SCORE"
  printf '  "RiskLevel": "%s",\n' "$risk_level"
  printf '  "Threats": [\n'
  local first=true
  for t in "${THREATS_JSON[@]}"; do
    $first && printf '    %s' "$t" || printf ',\n    %s' "$t"
    first=false
  done
  printf '\n  ],\n'
  printf '  "Summary": {\n'
  printf '    "Critical": %d,\n' "$CRITICAL_COUNT"
  printf '    "High": %d,\n' "$HIGH_COUNT"
  printf '    "Medium": %d,\n' "$MEDIUM_COUNT"
  printf '    "Low": %d\n' "$LOW_COUNT"
  printf '  }\n'
  printf '}\n'
}

# ---------- Print Text Report ----------
print_text_report() {
  $QUIET_MODE && return
  echo ""
  echo "================================================="
  echo "    Skill Security Scan Report"
  echo "================================================="
  echo "  Scan Time   : $(date '+%Y-%m-%d %H:%M:%S')"
  echo "  Scan Scope  : ${SCOPE_DIRS[*]}"
  echo "  Files       : ${TOTAL_FILES}"
  echo "  Threat Score: ${THREAT_SCORE}"
  echo "  Risk Level  : $(get_risk_level)"
  echo "  Review      : $(get_review_status)"
  echo "-------------------------------------------------"
  echo "  Critical : ${CRITICAL_COUNT}"
  echo "  High     : ${HIGH_COUNT}"
  echo "  Medium   : ${MEDIUM_COUNT}"
  echo "  Low      : ${LOW_COUNT}"
  echo "================================================="
  echo ""
}

# ---------- Determine Exit Code ----------
determine_exit() {
  local review_status risk_level
  review_status=$(get_review_status)
  risk_level=$(get_risk_level)

  if $STRICT_MODE && [[ $THREAT_SCORE -ge $MEDIUM_THRESHOLD ]]; then
    log_error "严格模式：检测到中危以上威胁（分数 ${THREAT_SCORE}），流水线失败"
    return 1
  fi

  if $FAIL_ON_HIGH; then
    if [[ "$risk_level" == "High" || "$risk_level" == "Critical" ]]; then
      log_error "高危扫描失败：检测到高危或严重威胁（分数 ${THREAT_SCORE}）"
      return 1
    fi
    return 0
  fi

  if [[ "$review_status" == "Reject" ]]; then
    log_error "扫描失败：检测到严重威胁（分数 ${THREAT_SCORE}），自动拒绝"
    return 1
  fi

  if [[ "$review_status" == "Manual Review" && "$risk_level" == "High" ]]; then
    log_warn "检测到高危威胁（分数 ${THREAT_SCORE}），需要人工审核"
    return 1
  fi

  return 0
}

# ============================================================
# Main
# ============================================================
main() {
  parse_args "$@"

  # Default scope if none specified
  if [[ ${#SCOPE_DIRS[@]} -eq 0 ]]; then
    SCOPE_DIRS=("skills" ".claude/skills")
  fi

  load_whitelist

  log_info "=============================================="
  log_info "  Skill Security Scanner v2.0.0"
  log_info "  Scope: ${SCOPE_DIRS[*]}"
  log_info "=============================================="
  echo ""

  for dir in "${SCOPE_DIRS[@]}"; do
    scan_directory "$dir"
  done

  print_text_report

  if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    local json_report
    json_report=$(generate_json_report)
    if [[ -n "$OUTPUT_FILE" ]]; then
      echo "$json_report" > "$OUTPUT_FILE"
      log_info "JSON 报告已保存至: $OUTPUT_FILE"
    else
      echo "$json_report"
    fi
  fi

  local exit_code=0
  determine_exit || exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    log_pass "安全扫描通过"
  fi

  exit $exit_code
}

main "$@"
