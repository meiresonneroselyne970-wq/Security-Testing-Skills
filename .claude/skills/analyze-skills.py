#!/usr/bin/env python3
"""
analyze-skills.py — 分析本地 skill 文件，输出 JSON

扫描 .claude/skills/ 和 skills/ 目录下的 .md 文件，
解析 YAML frontmatter 和 markdown 元数据，
输出 ModelScope 风格的 skill JSON。

用法:
  python scripts/analyze-skills.py              # 格式化输出到 stdout
  python scripts/analyze-skills.py --compact    # 紧凑 JSON
  python scripts/analyze-skills.py --output result.json  # 写入文件
"""

import argparse
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

# ========== 配置 ==========

SKILL_DIRS = ["skills"]
REPO_ROOT = Path(__file__).resolve().parent.parent


# ========== YAML frontmatter 解析 ==========

def parse_frontmatter(content: str) -> tuple[dict, int]:
    """解析简单的 YAML frontmatter（仅支持顶层 key: value 字符串），不依赖第三方库。"""
    match = re.match(r"^---\s*\r?\n(.*?)\r?\n---\s*", content, re.DOTALL)
    if not match:
        return {}, 0

    meta = {}
    for line in match.group(1).splitlines():
        kv = re.match(r"^(\w[\w-]*):\s*(.*?)\s*$", line)
        if kv:
            key = kv.group(1)
            value = kv.group(2).strip()
            value = value.strip("'\"`")
            meta[key] = value

    return meta, match.end()


# ========== Markdown 内容解析 ==========

def parse_markdown_meta(content: str) -> dict:
    """从 markdown 提取版本号、适用场景等元信息。"""
    info = {}

    # 版本号: **版本**: x.y.z
    m = re.search(r"\*\*版本\*\*[：:]\s*([^\n*]+)", content)
    if m:
        info["version"] = m.group(1).strip()

    # 标题: # skill-name — description
    m = re.search(r"^#\s+(.+)$", content, re.MULTILINE)
    if m:
        title = m.group(1).strip()
        info["display_name"] = title
        # 去掉 name 前缀，提取纯中文描述
        dm = re.match(r"^[\w-]+\s*[—\-—]\s*(.+)", title)
        info["title_description"] = dm.group(1).strip() if dm else title

    # 适用场景
    m = re.search(r"\*\*适用场景\*\*[：:]\s*([^\n*]+)", content)
    if m:
        info["scenarios"] = m.group(1).strip()

    # 最后更新
    m = re.search(r"\*\*最后更新\*\*[：:]\s*([^\n*]+)", content)
    if m:
        info["last_updated_doc"] = m.group(1).strip()

    # 维护者
    m = re.search(r"\*\*维护者\*\*[：:]\s*([^\n*]+)", content)
    if m:
        info["maintainer"] = m.group(1).strip()

    return info


# ========== 分类与标签推断 ==========

def infer_category(file_path: str, frontmatter_name: str) -> str:
    """从文件路径和名称自动推断分类。"""
    name = (frontmatter_name or "").lower()
    p = file_path.replace("\\", "/")

    if p.startswith(".claude/skills/"):
        if any(k in name for k in ("security", "audit", "scanner")):
            return "security"
        if any(k in name for k in ("gitee", "repo", "git")):
            return "repository"
        if name == "skill-manager":
            return "tool"
        return "system"

    if p.startswith("skills/"):
        if name == "card":
            return "generator"
        if name == "selector":
            return "index"
        if name in ("card_render", "resource_lookup"):
            return "engine"
        if name == "image-generator":
            return "media"
        if name == "comic":
            return "generator"
        if name == "english-scoring":
            return "scoring"
        return "tool"

    return "unknown"


def infer_tags(frontmatter_name: str, category: str, directory: str) -> list[str]:
    """自动打标签。"""
    tags = [f"category:{category}", f"directory:{directory}"]
    name = (frontmatter_name or "").lower()

    if any(k in name for k in ("security", "audit", "scanner")):
        tags.extend(("security", "audit"))
    if any(k in name for k in ("card", "render", "resource")):
        tags.append("card-system")
    if "english" in name or "scoring" in name:
        tags.extend(("english", "ai"))
    if "image" in name or "generator" in name:
        tags.extend(("image", "ai"))
    if "comic" in name:
        tags.append("comic")
    if "gitee" in name:
        tags.extend(("gitee", "git"))

    return list(dict.fromkeys(tags))  # 去重保序


# ========== 主逻辑 ==========

def analyze_skill(file_path: str) -> dict:
    """分析单个 skill 文件，返回结构化数据。"""
    full_path = REPO_ROOT / file_path
    content = full_path.read_text(encoding="utf-8")
    stat = full_path.stat()

    # 解析 frontmatter
    meta, body_start = parse_frontmatter(content)
    body = content[body_start:] if body_start else content
    md_meta = parse_markdown_meta(body)

    name = meta.get("name") or Path(file_path).stem
    directory = Path(file_path).parent.as_posix()
    category = infer_category(file_path, name)

    return {
        # 基础标识
        "id": f"@local/{name}",
        "name": name,
        "display_name": md_meta.get("display_name", name),
        "title_description": md_meta.get("title_description") or meta.get("description", ""),
        "description": meta.get("description", ""),

        # 位置信息
        "directory": directory,
        "file_path": file_path.replace("\\", "/"),
        "file_name": Path(file_path).name,

        # 元信息
        "version": md_meta.get("version"),
        "category": category,
        "tags": infer_tags(name, category, directory),
        "scenarios": md_meta.get("scenarios"),
        "maintainer": md_meta.get("maintainer"),
        "last_updated_doc": md_meta.get("last_updated_doc"),

        # 文件统计
        "size_bytes": stat.st_size,
        "line_count": len(content.splitlines()),
        "has_frontmatter": len(meta) > 0,
        "has_body": body.strip() != "",

        # 时间
        "file_last_modified": datetime.fromtimestamp(stat.st_mtime, tz=timezone.utc).isoformat(),
        "file_created": datetime.fromtimestamp(stat.st_ctime, tz=timezone.utc).isoformat(),
    }


def main():
    parser = argparse.ArgumentParser(
        description="分析本地 skill 文件，输出 ModelScope 风格的 JSON"
    )
    parser.add_argument(
        "-c", "--compact", action="store_true",
        help="紧凑 JSON 输出"
    )
    parser.add_argument(
        "-o", "--output", type=str, default=None,
        help="写入文件而非 stdout"
    )
    args = parser.parse_args()

    all_skills = []

    for dir_name in SKILL_DIRS:
        dir_path = REPO_ROOT / dir_name
        if not dir_path.is_dir():
            print(f"⚠ 目录不存在: {dir_name}", file=sys.stderr)
            continue

        for f in sorted(dir_path.glob("*.md")):
            rel_path = f.relative_to(REPO_ROOT).as_posix()
            try:
                skill = analyze_skill(rel_path)
                all_skills.append(skill)
            except Exception as err:
                print(f"✗ 解析失败: {rel_path} — {err}", file=sys.stderr)

    # 排序: 先按目录，再按名称
    all_skills.sort(key=lambda s: (s["directory"], s["name"]))

    output = {
        "skills": all_skills,
        "total": len(all_skills),
        "directories": SKILL_DIRS,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "generator": "analyze-skills.py",
    }

    if args.output:
        out_path = Path(args.output).resolve()
        out_path.write_text(json.dumps(output, ensure_ascii=False, indent=None if args.compact else 2), encoding="utf-8")
        print(f"[OK] written to {out_path} ({len(all_skills)} skills)")
    else:
        print(json.dumps(output, ensure_ascii=False, indent=None if args.compact else 2))


if __name__ == "__main__":
    main()
