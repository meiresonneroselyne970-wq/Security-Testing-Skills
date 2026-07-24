#!/bin/bash
# ============================================================
# Skill Security Scanner — Bash / CI Version
# Version: 2.2.0 (Added Incremental Scan & Inline Ignore)
# Part of AI DevSecOps Pipeline (skill-security-scan.yml)
# ============================================================
set -o pipefail  # 管道中任一命令失败都视为整体失败

# 设置 UTF-8 编码，确保中英文字符正确匹配（兼容不同发行版）
export LC_ALL=C.UTF-8 2>/dev/null || export LC_ALL=en_US.UTF-8 2>/dev/null || true

# 非交互式终端（CI / Gitee 流水线）自动关闭颜色输出
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
# Fallback: also check .workflow/ directory (Gitee Go convention)
if [[ ! -f "$WHITELIST_FILE" ]]; then
  [[ -f ".workflow/.security-whitelist.yml" ]] && WHITELIST_FILE=".workflow/.security-whitelist.yml"
fi

# 增量扫描参数
INCREMENTAL_MODE=false
BASE_BRANCH=""

# ---------- Scoring ----------
# 威胁评分权重：不同严重级别的分数加成
declare -i CRITICAL_WEIGHT=10
declare -i HIGH_WEIGHT=7
declare -i MEDIUM_WEIGHT=4
declare -i LOW_WEIGHT=1
# 评审阈值：总分达到对应值触发相应动作
declare -i REJECT_THRESHOLD=12   # ≥12 自动拒绝
declare -i HIGH_THRESHOLD=8      # ≥8 需要人工审核
declare -i MEDIUM_THRESHOLD=4     # ≥4 中度风险

# ---------- State ----------
# 运行时状态变量：扫描过程中动态累加
declare -i THREAT_SCORE=0      # 威胁总分
declare -i TOTAL_FILES=0       # 已扫描文件数
declare -i CRITICAL_COUNT=0    # Critical 级威胁计数
declare -i HIGH_COUNT=0        # High 级威胁计数
declare -i MEDIUM_COUNT=0      # Medium 级威胁计数
declare -i LOW_COUNT=0         # Low 级威胁计数
declare -a THREATS_JSON=()     # JSON 格式的威胁详情数组
declare -a FILE_WHITELIST=()   # 白名单文件列表（从 YAML 加载）
declare -a SKIP_PATTERNS=()    # 跳过的匹配模式
declare -a TARGET_FILES=()     # 待扫描的目标文件列表

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
  --incremental         Enable git-based incremental scan (PR-friendly)
  --base <branch>       Base branch for diff (default: origin/main)
  -h, --help            Show this help
EOF
  exit 2
}

# ---------- Color helpers ----------
# ANSI 转义码，在 CI 环境或输出重定向时自动禁用
if [[ -n "$NO_COLOR" ]]; then
  C_RESET=""; C_CYAN=""; C_GREEN=""; C_YELLOW=""; C_RED=""; C_MAGENTA=""; C_BOLD_RED=""
else
  C_RESET="\033[0m"; C_CYAN="\033[36m"; C_GREEN="\033[32m"
  C_YELLOW="\033[33m"; C_RED="\033[31m"; C_MAGENTA="\033[35m"; C_BOLD_RED="\033[1;31m"
fi

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
      --incremental) INCREMENTAL_MODE=true; shift ;;
      --base) BASE_BRANCH="$2"; shift 2 ;;
      -h|--help) usage ;;
      *) log_error "Unknown option: $1"; usage ;;
    esac
  done
}

# ---------- Load Whitelist ----------
# 从 .security-whitelist.yml 解析文件白名单：
#   file_whitelist:
#     - "skills/safe-skill.md"
#     - ".claude/skills/test-skill.md"
load_whitelist() {
  if [[ ! -f "$WHITELIST_FILE" ]]; then return; fi
  log_info "Loading whitelist from $WHITELIST_FILE"

  local in_section=false  # 标记当前是否在 file_whitelist 段落中
  while IFS= read -r line; do
    line="${line%$'\r'}"  # 剥离 Windows 换行符 CR
    # 匹配 YAML 列表项: - "file-path"
    if $in_section && [[ "$line" =~ ^[[:space:]]*-[[:space:]]*\"(.+)\"$ ]]; then
      FILE_WHITELIST+=("${BASH_REMATCH[1]}")
    elif [[ "$line" == "file_whitelist:" ]]; then
      in_section=true
    elif [[ "$line" =~ ^[a-z] ]]; then
      in_section=false  # 遇到下一个顶层 key，退出当前段落
    fi
  done < "$WHITELIST_FILE"

  if [[ ${#FILE_WHITELIST[@]} -gt 0 ]]; then
    log_info "Whitelisted files: ${FILE_WHITELIST[*]}"
  fi
}

# 检查文件是否在白名单中（支持 glob 通配符匹配）
is_whitelisted() {
  local file="$1"
  for wf in "${FILE_WHITELIST[@]}"; do
    [[ "$file" == $wf ]] && return 0  # bash 的 == 在 [[ ]] 中支持通配符
  done
  return 1
}

# ---------- Record Threat (with Inline Ignore support) ----------
# 记录一条安全威胁发现，累加评分，并输出格式化的告警信息。
# 支持内联豁免注释 <!-- sec-ignore: T1.1, T3.1 --> 和 <!-- sec-ignore: ALL -->
record_threat() {
  local rule_id="$1" category="$2" severity="$3" file="$4" line_num="$5"
  local match="$6" description="$7" recommendation="$8"
  local inline_ignore="$9"

  # 内联豁免: <!-- sec-ignore: T1.1, T3.1 --> 或 <!-- sec-ignore: ALL -->
  # 当行中存在 sec-ignore 指令且匹配当前规则 ID 或 ALL 时，跳过此条威胁
  if [[ -n "$inline_ignore" ]]; then
    if [[ "$inline_ignore" == *"ALL"* || "$inline_ignore" == *"$rule_id"* ]]; then
      log_info "  ⏭️  Line ${line_num} in ${file} bypassed ${rule_id} via sec-ignore"
      return 0
    fi
  fi

  # 根据严重级别计算权重并累加计数
  local weight=0
  case "$severity" in
    Critical) weight=$CRITICAL_WEIGHT; CRITICAL_COUNT=$((CRITICAL_COUNT + 1)) ;;
    High)     weight=$HIGH_WEIGHT;     HIGH_COUNT=$((HIGH_COUNT + 1)) ;;
    Medium)   weight=$MEDIUM_WEIGHT;   MEDIUM_COUNT=$((MEDIUM_COUNT + 1)) ;;
    Low)      weight=$LOW_WEIGHT;      LOW_COUNT=$((LOW_COUNT + 1)) ;;
  esac
  THREAT_SCORE=$((THREAT_SCORE + weight))  # 累加威胁总分

  # 对匹配内容进行安全转义（防止 JSON 中双引号破坏结构），并截断至 80 字符
  local safe_match
  safe_match=$(echo "$match" | sed 's/"/\\"/g' | cut -c1-80)

  # 严重级别对应的彩色显示标签
  local sev_disp
  case "$severity" in
    Critical) sev_disp="${C_BOLD_RED}[CRITICAL]${C_RESET}" ;;
    High)     sev_disp="${C_MAGENTA}[HIGH]${C_RESET}" ;;
    Medium)   sev_disp="${C_YELLOW}[MEDIUM]${C_RESET}" ;;
    Low)      sev_disp="${C_GREEN}[LOW]${C_RESET}" ;;
  esac

  # 终端输出：彩色告警信息
  if ! $QUIET_MODE; then
    echo -e "  ${sev_disp} ${rule_id} — ${file}:${line_num}"
    echo -e "    ${description}"
  fi

  # JSON 模式下将威胁详情追加到数组（用于最终报告生成）
  if [[ "$OUTPUT_FORMAT" == "json" ]]; then
    THREATS_JSON+=("{ \"RuleId\": \"${rule_id}\", \"Category\": \"${category}\", \"Severity\": \"${severity}\", \"File\": \"${file}\", \"Line\": ${line_num}, \"Match\": \"${safe_match}\", \"Description\": \"${description}\", \"Recommendation\": \"${recommendation}\" }")
  fi
}

# ---------- Scan Single File ----------
# 逐行扫描单个文件，使用正则匹配已知威胁模式。
# 规则编号体系：
#   T1.x — 恶意命令注入（exec, rm -rf, curl POST, reverse shell, 提权, 混淆）
#   T2.x — 隐藏危险命令（零宽字符, 提示词越狱, HTML 注释中的命令）
#   T3.x — 敏感信息泄露（API Key, Bearer Token, 硬编码密码, 私钥）
#   T5.x — 社会工程攻击（凭据诱导, 紧急诱导, 安全绕过诱导）
#   T6.x — 依赖与供应链风险（外部脚本引用, 非白名单 CDN）
scan_file() {
  local file="$1"

  # 跳过白名单文件
  if is_whitelisted "$file"; then
    log_info "⏭️  Skipping whitelisted: $file"
    return
  fi
  # 跳过不存在、不可读或空文件
  [[ ! -f "$file" || ! -r "$file" || ! -s "$file" ]] && return

  TOTAL_FILES=$((TOTAL_FILES + 1))
  log_info "Scanning: $file"

  local line_num=0 found=false line line_lower inline_ignore

  # 逐行读取文件内容（使用 || [[ -n "$line" ]] 处理末行无换行的情况）
  while IFS= read -r line || [[ -n "$line" ]]; do
    line_num=$((line_num + 1))
    [[ -z "$line" ]] && continue
    # 转换为小写以实现大小写不敏感匹配
    line_lower=$(echo "$line" | tr '[:upper:]' '[:lower:]')

    # 提取行级内联豁免: <!-- sec-ignore: T1.1, T3.1 --> 或 <!-- sec-ignore: ALL -->
    # 允许多个规则 ID 用逗号分隔，匹配 ALL 则豁免所有规则
    inline_ignore=""
    if [[ "$line" =~ \<!--[[:space:]]*sec-ignore:[[:space:]]*([A-Za-z0-9.,_[:space:]-]+)--\> ]]; then
      inline_ignore="${BASH_REMATCH[1]}"
    fi

    # === T1: Malicious Command Injection ===

    # T1.1: System command execution
    if [[ "$line_lower" =~ exec\(|system\(|popen\(|subprocess\.call|subprocess\.run|os\.system|child_process\.exec|child_process\.spawn|eval\(|shell_exec|passthru ]]; then
      record_threat "T1.1" "Malicious Command" "Critical" "$file" "$line_num" "${line:0:80}" \
        "检测到系统命令执行函数" "移除系统命令执行函数，使用 SandboxSDK" "$inline_ignore"
      found=true
    fi

    # T1.2: File system destruction
    if [[ "$line_lower" =~ rm\ -rf|rm\ -r\ /|rmdir\ /s|del\ /f|unlink|rmdir|shutil\.rmtree|fs\.rmdir|fs\.unlink ]]; then
      record_threat "T1.2" "Malicious Command" "Critical" "$file" "$line_num" "${line:0:80}" \
        "检测到文件系统破坏命令" "移除文件系统破坏命令" "$inline_ignore"
      found=true
    fi

    # T1.3: Network data exfiltration
    if [[ "$line_lower" =~ curl.*POST|wget.*POST|fetch\(.*POST|XMLHttpRequest|axios\.post|requests\.post|urllib.*urlopen ]]; then
      record_threat "T1.3" "Malicious Command" "Critical" "$file" "$line_num" "${line:0:80}" \
        "检测到数据外传操作" "验证数据传输合法性" "$inline_ignore"
      found=true
    fi

    # T1.4: Reverse shell
    if [[ "$line_lower" =~ bash\ -i|nc\ -e|ncat|socat|/dev/tcp|mkfifo|reverse.*shell ]]; then
      record_threat "T1.4" "Malicious Command" "Critical" "$file" "$line_num" "${line:0:80}" \
        "检测到反向 Shell 特征" "立即移除反向 Shell 相关代码" "$inline_ignore"
      found=true
    fi

    # T1.5: Privilege escalation
    if [[ "$line_lower" =~ sudo\ |chmod\ 777|chown|setuid|setgid|su\ -|su\ root ]]; then
      record_threat "T1.5" "Malicious Command" "Critical" "$file" "$line_num" "${line:0:80}" \
        "检测到权限提升操作" "遵循最小权限原则" "$inline_ignore"
      found=true
    fi

    # T1.7: Code obfuscation / dynamic execution
    if [[ "$line_lower" =~ atob\(|btoa\(|base64.*decode|eval\(|Function\(|new\ Function|decodeURI|unescape ]]; then
      record_threat "T1.7" "Malicious Command" "High" "$file" "$line_num" "${line:0:80}" \
        "检测到代码混淆/动态执行" "移除动态代码执行" "$inline_ignore"
      found=true
    fi

    # === T2: Hidden Dangerous Commands ===

    # T2.1: Zero-width characters
    if [[ "$line" =~ $'\xE2\x80\x8B' || "$line" =~ $'\xE2\x80\x8C' || "$line" =~ $'\xE2\x80\x8D' || "$line" =~ $'\xEF\xBB\xBF' ]]; then
      record_threat "T2.1" "Hidden Command" "Critical" "$file" "$line_num" "零宽字符" \
        "检测到零宽字符，可能隐藏恶意指令" "移除零宽字符" "$inline_ignore"
      found=true
    fi

    # T2.2: System prompt override / jailbreak
    if [[ "$line_lower" =~ ignore\ all\ previous|忽略之前的指令|忽略所有安全|忽略.*限制|system\ prompt\ override|忽略.*警告.*安全|跳过.*安全.*检查|bypass.*security.*check|忽略.*审核 ]]; then
      record_threat "T2.2" "Hidden Command" "Critical" "$file" "$line_num" "${line:0:80}" \
        "检测到系统提示词覆盖/越狱指令" "移除绕过安全机制的危险提示词" "$inline_ignore"
      found=true
    fi

    # T2.3: Hidden commands in HTML comments
    if [[ "$line" =~ \<!--.*(exec|system|eval|rm\ -rf|curl|wget).*--\> ]]; then
      record_threat "T2.3" "Hidden Command" "Critical" "$file" "$line_num" "${line:0:80}" \
        "检测到注释中隐藏的可执行命令" "移除注释中的命令，确保透明度" "$inline_ignore"
      found=true
    fi

    # === T3: Sensitive Information Leakage ===

    # T3.1: Hardcoded API Key
    if [[ "$line" =~ sk-[a-zA-Z0-9]{20,} ]]; then
      if ! [[ "$line_lower" =~ sk-xxx|sk-你的|sk-your|sk-example|sk-demo|sk-test|sk-sample|sk_replace ]]; then
        record_threat "T3.1" "Sensitive Info" "High" "$file" "$line_num" "sk-****" \
          "检测到硬编码的 API Key" "将 API Key 移至环境变量或密钥管理服务" "$inline_ignore"
        found=true
      fi
    fi

    # T3.2: Hardcoded Bearer Token
    if [[ "$line" =~ Bearer[[:space:]]+[a-zA-Z0-9._-]{20,} ]]; then
      if ! [[ "$line_lower" =~ bearer\ xxx|bearer\ your|bearer\ example|bearer\ demo|bearer\ test|bearer\ replace ]]; then
        record_threat "T3.2" "Sensitive Info" "High" "$file" "$line_num" "Bearer ****" \
          "检测到硬编码的 Bearer Token" "将 Token 移至环境变量或密钥管理服务" "$inline_ignore"
        found=true
      fi
    fi

    # T3.3: Hardcoded password
    if [[ "$line_lower" =~ password[[:space:]]*[=:][[:space:]]*[\"\'][^[:space:]\"\']{4,}[\"\'] ]]; then
      if ! [[ "$line_lower" =~ placeholder|替换|示例|example|demo|test|replace ]]; then
        record_threat "T3.3" "Sensitive Info" "High" "$file" "$line_num" "password=****" \
          "检测到硬编码的密码" "将密码移至环境变量或密钥管理服务" "$inline_ignore"
        found=true
      fi
    fi

    # T3.4: Private key
    if [[ "$line" =~ -----BEGIN[[:space:]]+(RSA[[:space:]]+)?PRIVATE[[:space:]]+KEY ]]; then
      record_threat "T3.4" "Sensitive Info" "High" "$file" "$line_num" "PRIVATE KEY" \
        "检测到硬编码的私钥" "私钥必须存储在安全的密钥管理服务中" "$inline_ignore"
      found=true
    fi

    # === T5: Social Engineering Attacks ===

    # T5.1: Credential solicitation
    if [[ "$line_lower" =~ enter.*password|provide.*token|input.*api.*key|请.*输入.*密码|输入.*token|提供.*密钥|请输入.*API ]]; then
      record_threat "T5.1" "Social Engineering" "Critical" "$file" "$line_num" "${line:0:80}" \
        "检测到凭据诱导语句（社会工程攻击）" "移除凭据诱导语句" "$inline_ignore"
      found=true
    fi

    # T5.2: Urgency inducement
    if [[ "$line_lower" =~ 立即.*执行|马上.*运行|urgent|immediately|asap|紧急.*处理|不.*执行.*将会|马上.*否则 ]]; then
      record_threat "T5.2" "Social Engineering" "Medium" "$file" "$line_num" "${line:0:80}" \
        "检测到紧急诱导语句" "移除紧急诱导措辞" "$inline_ignore"
      found=true
    fi

    # T5.4: Security bypass inducement
    if [[ "$line_lower" =~ ignore.*warning|skip.*check|bypass.*security|忽略.*警告|跳过.*检测|绕过.*安全|disable.*security ]]; then
      record_threat "T5.4" "Social Engineering" "Critical" "$file" "$line_num" "${line:0:80}" \
        "检测到安全绕过诱导语句" "移除安全绕过语句" "$inline_ignore"
      found=true
    fi

    # === T6: Dependency & Supply Chain Risks ===

    # T6.1: External script reference
    if [[ "$line" =~ \<script[[:space:]]+src=[\"\']https?:// ]]; then
      record_threat "T6.1" "Dependency Risk" "Medium" "$file" "$line_num" "${line:0:80}" \
        "检测到外部脚本引用" "验证外部脚本来源可信，优先使用官方 CDN" "$inline_ignore"
      found=true
    fi

    # T6.2: Non-whitelist CDN
    if [[ "$line_lower" =~ cdn\.|unpkg\.|jsdelivr\. ]]; then
      if ! [[ "$line_lower" =~ cdnjs\.cloudflare\.com|unpkg\.com|jsdelivr\.net|cdn\.jsdelivr\.net|cdn\.bootcdn\.net|lib\.baomitu\.com ]]; then
        record_threat "T6.2" "Dependency Risk" "Medium" "$file" "$line_num" "${line:0:80}" \
          "检测到非白名单 CDN 引用" "使用受信任的 CDN 来源" "$inline_ignore"
        found=true
      fi
    fi

  done < "$file"  # 重定向输入：从此文件逐行读取

  # 如果整个文件未触发任何告警，输出通过信息
  $found || log_pass "$file — 安全"
}

# ---------- File Gathering (Incremental or Full) ----------
# 收集待扫描的文件列表。支持两种模式：
#   增量模式（--incremental）：仅扫描当前分支相对于基准分支变更的 .md 文件
#   全量模式（默认）：递归扫描指定目录下所有 .md 文件
gather_files() {
  if $INCREMENTAL_MODE; then
    BASE_BRANCH="${BASE_BRANCH:-origin/main}"
    log_info "运行模式: Git 增量扫描 (比对基准: $BASE_BRANCH)"

    # 拉取远程基准分支（浅克隆 50 条提交，加速 CI 环境）
    git fetch origin "$(echo "$BASE_BRANCH" | sed 's|origin/||')" --depth=50 2>/dev/null || true

    local diff_files
    # 使用三点语法 .. 比对当前分支与基准分支的差异
    # --diff-filter=AMR: 只包含新增(A)、修改(M)、重命名(R)的文件
    mapfile -t diff_files < <(git diff --name-only --diff-filter=AMR "$BASE_BRANCH"...HEAD 2>/dev/null || echo "")

    for file in "${diff_files[@]}"; do
      # 仅扫描 .md 文件且位于指定扫描目录内
      if [[ -n "$file" && "$file" == *.md ]]; then
        for dir in "${SCOPE_DIRS[@]}"; do
          if [[ "$file" == "$dir"* ]]; then
            TARGET_FILES+=("$file")
            break
          fi
        done
      fi
    done

    if [[ ${#TARGET_FILES[@]} -eq 0 ]]; then
      log_info "✅ 本次变更中没有需要扫描的 Skill 文件 (.md)，跳过扫描"
    else
      log_info "增量扫描文件列表: ${TARGET_FILES[*]}"
    fi
  else
    log_info "运行模式: 目录全量扫描"
    for dir in "${SCOPE_DIRS[@]}"; do
      [[ ! -d "$dir" ]] && continue
      # 使用 find -print0 配合 null 分隔符读取，安全处理含空格的文件名
      while IFS= read -r -d '' file; do
        TARGET_FILES+=("$file")
      done < <(find "$dir" -type f -name "*.md" -print0 2>/dev/null || true)
    done
  fi
}

# ---------- Status Helpers ----------
# 根据威胁总分返回评审结论（Reject / Manual Review / Pass）
get_review_status() {
  if [[ $THREAT_SCORE -ge $REJECT_THRESHOLD ]]; then echo "Reject"
  elif [[ $THREAT_SCORE -ge $HIGH_THRESHOLD ]]; then echo "Manual Review"
  elif [[ $THREAT_SCORE -ge $MEDIUM_THRESHOLD ]]; then echo "Manual Review"
  elif [[ $THREAT_SCORE -ge 1 ]]; then echo "Pass"
  else echo "Pass"; fi
}

# 根据威胁总分返回风险等级（Critical / High / Medium / Low / Safe）
get_risk_level() {
  if [[ $THREAT_SCORE -ge $REJECT_THRESHOLD ]]; then echo "Critical"
  elif [[ $THREAT_SCORE -ge $HIGH_THRESHOLD ]]; then echo "High"
  elif [[ $THREAT_SCORE -ge $MEDIUM_THRESHOLD ]]; then echo "Medium"
  elif [[ $THREAT_SCORE -ge 1 ]]; then echo "Low"
  else echo "Safe"; fi
}

# ---------- Generate JSON Report ----------
# 生成结构化的 JSON 安全扫描报告（适用于 CI 管道解析）
generate_json_report() {
  # 报告 ID 格式: SSS-YYYYMMDD-XXXX (Skill Security Scan + 日期 + 随机数)
  local report_id="SSS-$(date +%Y%m%d)-$((RANDOM % 9000 + 1000))"
  local scan_time risk_level review_status scope_str
  scan_time=$(date '+%Y-%m-%d %H:%M:%S')
  review_status=$(get_review_status)
  risk_level=$(get_risk_level)
  scope_str=$(IFS=,; echo "${SCOPE_DIRS[*]}")

  # 使用 printf 逐行构建 JSON（避免 jq 依赖，兼容最小化 CI 环境）
  printf '{\n'
  printf '  "ReportId": "%s",\n' "$report_id"
  printf '  "ScanTime": "%s",\n' "$scan_time"
  printf '  "ScanScope": "%s",\n' "$scope_str"
  printf '  "ScanMode": "%s",\n' "$($INCREMENTAL_MODE && echo 'incremental' || echo 'full')"
  printf '  "ScanFileCount": %d,\n' "$TOTAL_FILES"
  printf '  "ReviewStatus": "%s",\n' "$review_status"
  printf '  "ThreatScore": %d,\n' "$THREAT_SCORE"
  printf '  "RiskLevel": "%s",\n' "$risk_level"
  printf '  "Threats": [\n'
  # 拼接威胁数组，用 first 标记控制逗号分隔
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
  echo "  Scan Mode   : $($INCREMENTAL_MODE && echo 'Incremental' || echo 'Full')"
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
# 根据扫描配置和结果决定脚本退出码。
# 退出码 1 = 阻止流水线继续，退出码 0 = 通过。
determine_exit() {
  local review_status risk_level
  review_status=$(get_review_status)
  risk_level=$(get_risk_level)

  # --strict 模式：只要 ≥ Medium 就阻止
  if $STRICT_MODE && [[ $THREAT_SCORE -ge $MEDIUM_THRESHOLD ]]; then
    log_error "严格模式：检测到中危以上威胁（分数 ${THREAT_SCORE}），流水线失败"
    return 1
  fi

  # --fail-on-high 模式：仅 High/Critical 阻止
  if $FAIL_ON_HIGH; then
    if [[ "$risk_level" == "High" || "$risk_level" == "Critical" ]]; then
      log_error "高危扫描失败：检测到高危或严重威胁（分数 ${THREAT_SCORE}）"
      return 1
    fi
    return 0
  fi

  # 默认模式：Reject 或 High+ManualReview 阻止
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
# ============================================================
# Main — 主控制流程
# ============================================================
main() {
  # 1. 解析命令行参数
  parse_args "$@"

  # 2. 设置默认扫描目录（未通过 --scope 指定时）
  if [[ ${#SCOPE_DIRS[@]} -eq 0 ]]; then
    SCOPE_DIRS=("skills" ".claude/skills")
  fi

  # 3. 加载白名单配置
  load_whitelist

  log_info "=============================================="
  log_info "  Skill Security Scanner v2.2.0"
  log_info "  Scope: ${SCOPE_DIRS[*]}"
  $INCREMENTAL_MODE && log_info "  Mode: Incremental (base: ${BASE_BRANCH:-origin/main})"
  log_info "=============================================="
  echo ""

  # 4. 收集待扫描文件（增量或全量）
  gather_files

  # 5. 逐个扫描文件
  for file in "${TARGET_FILES[@]}"; do
    scan_file "$file"
  done

  # 6. 输出文本/JSON 报告
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

  # 7. 根据威胁评分和配置决定退出码
  local exit_code=0
  determine_exit || exit_code=$?

  if [[ $exit_code -eq 0 ]]; then
    log_pass "安全扫描通过"
  fi

  exit $exit_code
}

main "$@"
