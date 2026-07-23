"""
AI DevSecOps Pipeline — Prompt Injection Audit Script
=====================================================
独立脚本，从 GitHub Actions 内联代码提取，供 Gitee Go 流水线调用。
检测提示词注入、越狱攻击、恶意指令等威胁模式。

用法:
    python3 .gitee/scripts/audit_prompts.py

退出码:
    0 — 所有文件通过检查
    1 — 检测到安全威胁
"""
import os
import re
import sys

# ---------- 威胁检测模式 ----------
SUSPICIOUS_PATTERNS = [
    # English prompt injection / jailbreak
    r"(?i)ignore\s*(all\s*)?previous\s*instructions",
    r"(?i)system\s*prompt\s*bypass",
    r"(?i)you\s*are\s*now\s*a\s*bypass",
    r"(?i)developer\s*mode\s*enabled",
    r"(?i)dump\s*(all\s*)?(previous\s*)?instructions",
    r"(?i)reveal\s*your\s*system\s*prompt",
    r"(?i)act\s*as\s*DAN\b",
    r"(?i)jailbreak",
    r"(?i)ignore\s+.*warning",
    r"(?i)skip\s+.*check",
    r"(?i)bypass\s+.*security",
    r"(?i)disable\s+.*security",
    # Chinese prompt injection / jailbreak
    r"忽略之前的指令",
    r"忽略所有安全",
    r"忽略.*限制",
    r"忽略.*警告.*安全",
    r"跳过.*安全.*检查",
    r"忽略.*审核",
    r"绕过.*安全",
    r"跳过.*检测",
    r"忽略.*警告",
    # Command injection
    r"\bsudo\s+",
    r"curl\s+.*http",
    r"wget\s+.*http",
    r"eval\s*\(.*\)",
    r"exec\s*\(.*\)",
    r"__import__\s*\(.*\)",
    r"subprocess\.",
    r"os\.system\s*\(",
    r"child_process\.",
]

# ---------- 配置 ----------
WHITELIST_FILE = ".security-whitelist.yml"
TARGET_DIRS = [".claude/skills", "scripts"]
TEXT_EXTS = {".md", ".txt", ".json", ".yaml", ".yml", ".py", ".js", ".ts"}


def load_whitelist(whitelist_path: str):
    """解析 .security-whitelist.yml 白名单配置"""
    file_whitelist: list[str] = []
    pattern_whitelist: list[str] = []

    if not os.path.exists(whitelist_path):
        return file_whitelist, pattern_whitelist

    with open(whitelist_path, "r", encoding="utf-8", errors="ignore") as wf:
        content = wf.read()

    in_files = False
    in_patterns = False
    for line in content.split("\n"):
        stripped = line.strip()
        if stripped.startswith("file_whitelist:"):
            in_files, in_patterns = True, False
            continue
        if stripped.startswith("pattern_whitelist:"):
            in_patterns, in_files = True, False
            continue
        if stripped.startswith("#") or stripped == "":
            continue
        if in_files and stripped.startswith("- "):
            file_whitelist.append(stripped[2:].strip().strip('"').strip("'"))
        if in_patterns and stripped.startswith("- "):
            pattern_whitelist.append(stripped[2:].strip().strip('"').strip("'"))

    return file_whitelist, pattern_whitelist


def scan_directory(
    directory: str,
    file_whitelist: list[str],
    pattern_whitelist: list[str],
) -> bool:
    """扫描目录中所有文本文件，返回 True 表示发现威胁"""
    has_error = False

    if not os.path.exists(directory):
        print(f"  📂 Directory '{directory}' not found, skipping.")
        return False

    for root, _, files in os.walk(directory):
        for file in files:
            ext = os.path.splitext(file)[1].lower()
            if ext not in TEXT_EXTS:
                continue

            file_path = os.path.join(root, file)
            rel_path = file_path.replace("\\", "/")

            # 跳过白名单文件
            if any(
                rel_path == fw or rel_path.endswith("/" + fw)
                for fw in file_whitelist
            ):
                print(f"  ⏭️  Skipped (whitelist): {rel_path}")
                continue

            try:
                with open(file_path, "r", encoding="utf-8", errors="ignore") as f:
                    content = f.read()
            except Exception as e:
                print(f"  ⚠️  Could not read {file_path}: {e}")
                continue

            for suspect in SUSPICIOUS_PATTERNS:
                for m in re.finditer(suspect, content):
                    # 提取匹配行上下文（前后 50 字符）
                    matched_line = (
                        content[max(0, m.start() - 50) : m.end() + 50]
                        .split("\n")[0]
                    )
                    # 跳过匹配行中含白名单模式的情况
                    if any(
                        pw.lower() in matched_line.lower()
                        for pw in pattern_whitelist
                    ):
                        continue
                    print(
                        f"  ❌ ALERT: Pattern '{m.group()}' found in {file_path}"
                    )
                    has_error = True

    return has_error


def main():
    file_whitelist, pattern_whitelist = load_whitelist(WHITELIST_FILE)

    print(
        f"📋 Whitelist: {len(file_whitelist)} files, "
        f"{len(pattern_whitelist)} patterns"
    )
    for fw in file_whitelist:
        print(f"  📄 skip: {fw}")

    print("🔍 Starting Prompt Injection audit...")
    has_any_error = False

    for directory in TARGET_DIRS:
        if scan_directory(directory, file_whitelist, pattern_whitelist):
            has_any_error = True

    if has_any_error:
        print("\n🚨 Build blocked: Prompt injection or malicious payload detected!")
        sys.exit(1)
    else:
        print("\n✅ All prompt templates passed integrity checks.")
        sys.exit(0)


if __name__ == "__main__":
    main()
