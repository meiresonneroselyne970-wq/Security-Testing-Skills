#!/usr/bin/env python3
"""
analyze-skills.py — 分析本地 skill 文件，输出 JSON

扫描 3 类 skill：
  1. skills/*.md              — 扁平 skill 文件（通用卡片生成技能）
  2. cards/*/skill.md         — 文件夹型技能（卡片模板，整个文件夹打包）
  3. cards/services/*/skill.md — 文件夹型技能（服务模块，整个文件夹打包）

解析 YAML frontmatter 和 markdown 元数据，输出结构化 JSON。

用法:
  python .claude/skills/analyze-skills.py              # 格式化输出到 stdout
  python .claude/skills/analyze-skills.py --compact    # 紧凑 JSON
  python .claude/skills/analyze-skills.py -o result.json  # 写入文件
"""

import argparse
import json
import os
import re
import sys
from datetime import datetime, timezone
from pathlib import Path

# ========== 配置 ==========

SKILL_DIRS = ["skills"]                      # 扁平 .md 文件
CARD_SKILL_GLOBS = [                         # 文件夹型 skill（含 skill.md）
    "cards/*/skill.md",
    "cards/services/*/skill.md",
]
REPO_ROOT = Path(__file__).resolve().parent.parent.parent


# ========== YAML frontmatter 解析 ==========

def parse_frontmatter(content: str) -> tuple[dict, int]:
    """解析简单的 YAML frontmatter（仅支持顶层 key: value 字符串），不依赖第三方库。

    返回 (meta_dict, body_start_index)。
    body_start_index 是 frontmatter 结束后的字符偏移量。
    """
    # 匹配开头的 --- 块：^---\n ... \n---\s*
    match = re.match(r"^---\s*\r?\n(.*?)\r?\n---\s*", content, re.DOTALL)
    if not match:
        return {}, 0

    meta = {}
    for line in match.group(1).splitlines():
        # 解析 "key: value" 行，key 为字母/数字/连字符，value 为任意字符串
        kv = re.match(r"^(\w[\w-]*):\s*(.*?)\s*$", line)
        if kv:
            key = kv.group(1)
            value = kv.group(2).strip()
            value = value.strip("'\"`")  # 去除可能的引号包裹
            meta[key] = value

    return meta, match.end()  # match.end() 是 body 起始位置


# ========== Markdown 内容解析 ==========

def parse_markdown_meta(content: str) -> dict:
    """从 markdown 提取版本号、适用场景等元信息。

    使用正则匹配 **字段名**：值 格式的 markdown 元数据行。
    """
    info = {}

    # 版本号: **版本**: x.y.z
    m = re.search(r"\*\*版本\*\*[：:]\s*([^\n*]+)", content)
    if m:
        info["version"] = m.group(1).strip()

    # 一级标题: # skill-name — description
    # 格式如 "# english-scoring — 英语打分服务"
    m = re.search(r"^#\s+(.+)$", content, re.MULTILINE)
    if m:
        title = m.group(1).strip()
        info["display_name"] = title
        # 从标题中分离名称和描述（用 — / - / — 分隔）
        dm = re.match(r"^[\w-]+\s*[—\-—]\s*(.+)", title)
        info["title_description"] = dm.group(1).strip() if dm else title

    # 适用场景
    m = re.search(r"\*\*适用场景\*\*[：:]\s*([^\n*]+)", content)
    if m:
        info["scenarios"] = m.group(1).strip()

    # 最后更新日期
    m = re.search(r"\*\*最后更新\*\*[：:]\s*([^\n*]+)", content)
    if m:
        info["last_updated_doc"] = m.group(1).strip()

    # 维护者
    m = re.search(r"\*\*维护者\*\*[：:]\s*([^\n*]+)", content)
    if m:
        info["maintainer"] = m.group(1).strip()

    return info


# ========== 分类与标签推断 ==========

def infer_category(file_path: str, frontmatter_name: str, is_folder_skill: bool = False) -> str:
    """从文件路径和名称自动推断分类。

    分类策略（按优先级）：
      1. cards/ 下的文件夹型 skill → 按子目录和关键词细分
      2. .claude/skills/ 下的系统 skills → security / repository / system
      3. skills/ 下的扁平 skills → generator / engine / media / tool
      4. 以上都不匹配 → unknown
    """
    name = (frontmatter_name or "").lower()
    p = file_path.replace("\\", "/")  # 统一路径分隔符

    # --- 卡片模板 & 服务模块 (cards/*) ---
    if is_folder_skill and p.startswith("cards/"):
        if "services" in p:
            return "scoring" if "english" in name or "scoring" in name else "service"
        if any(k in name for k in ("english", "word", "sentence", "input")):
            return "english-learning"
        if "comic" in name:
            return "media"
        if "answer" in name:
            return "qa"
        if "homework" in name:
            return "education"
        if "media" in name:
            return "media"
        if "text" in name:
            return "entry"
        return "card-template"  # 兜底：通用卡片模板

    # --- 系统工具 skills (.claude/skills/) ---
    if p.startswith(".claude/skills/"):
        if any(k in name for k in ("security", "audit", "scanner")):
            return "security"
        if any(k in name for k in ("gitee", "repo", "git")):
            return "repository"
        if name == "skill-manager":
            return "tool"
        return "system"

    # --- 通用 skills (skills/) ---
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
    """自动打标签。

    基础标签始终包含 category 和 directory。
    根据文件名中的关键词追加领域标签（如 security, english, comic 等）。
    使用 dict.fromkeys 去重同时保留插入顺序。
    """
    tags = [f"category:{category}", f"directory:{directory}"]
    name = (frontmatter_name or "").lower()

    # 安全相关
    if any(k in name for k in ("security", "audit", "scanner")):
        tags.extend(("security", "audit"))
    # 卡片系统
    if any(k in name for k in ("card", "render", "resource")):
        tags.append("card-system")
    # 英语学习 / AI
    if "english" in name or "scoring" in name:
        tags.extend(("english", "ai"))
    # 图像生成 / AI
    if "image" in name or "generator" in name:
        tags.extend(("image", "ai"))
    # 漫画
    if "comic" in name:
        tags.append("comic")
    # Gitee 仓库
    if "gitee" in name:
        tags.extend(("gitee", "git"))

    return list(dict.fromkeys(tags))  # 去重保序：dict 在 Python 3.7+ 保证插入顺序


def folder_stats(folder_path: Path) -> dict:
    """统计整个文件夹的大小和文件数（用于文件夹型 skill）。"""
    total_size = 0
    file_count = 0
    for f in folder_path.rglob("*"):  # 递归遍历所有文件和目录
        if f.is_file():
            total_size += f.stat().st_size  # 累加文件字节数
            file_count += 1
    return {
        "folder_size_bytes": total_size,
        "folder_file_count": file_count,
    }


# ========== 主逻辑 ==========

def analyze_skill(file_path: str, is_folder_skill: bool = False) -> dict:
    """分析单个 skill 文件，返回结构化数据。

    对扁平 skill（单 .md）读取文件并解析。
    对文件夹型 skill，额外统计整个文件夹的文件列表和大小。
    """
    full_path = REPO_ROOT / file_path
    content = full_path.read_text(encoding="utf-8")
    stat = full_path.stat()

    # 解析 frontmatter YAML 头部
    meta, body_start = parse_frontmatter(content)
    # body 是 frontmatter 之后的内容
    body = content[body_start:] if body_start else content
    md_meta = parse_markdown_meta(body)

    # 名称优先从 frontmatter 取，回退到文件名（不含扩展名）
    name = meta.get("name") or Path(file_path).stem
    directory = Path(file_path).parent.as_posix()
    category = infer_category(file_path, name, is_folder_skill)

    result = {
        # 基础标识
        "id": f"@local/{name}",  # 本地 skill 统一使用 @local/ 前缀
        "name": name,
        "display_name": md_meta.get("display_name", name),
        "title_description": md_meta.get("title_description") or meta.get("description", ""),
        "description": meta.get("description", ""),

        # 位置信息
        "directory": directory,
        "file_path": file_path.replace("\\", "/"),  # Windows 兼容
        "file_name": Path(file_path).name,

        # 打包方式：区分扁平文件 vs 整个文件夹
        "is_folder_skill": is_folder_skill,
    }

    if is_folder_skill:
        # 文件夹型 skill：整个文件夹作为打包单元
        folder_path = full_path.parent
        result["folder_path"] = folder_path.relative_to(REPO_ROOT).as_posix()
        # 列出文件夹内所有文件（用于打包时精确包含），排除 .git 目录
        result["folder_files"] = sorted(
            f.relative_to(folder_path).as_posix()
            for f in folder_path.rglob("*")
            if f.is_file() and ".git" not in f.parts  # 排除版本控制目录
        )
        stats = folder_stats(folder_path)
        result.update(stats)
        # 文件夹大小作为 size_bytes
        result["size_bytes"] = stats["folder_size_bytes"]

    result.update({
        # 元信息
        "version": md_meta.get("version"),
        "category": category,
        "tags": infer_tags(name, category, directory),
        "scenarios": md_meta.get("scenarios"),
        "maintainer": md_meta.get("maintainer"),
        "last_updated_doc": md_meta.get("last_updated_doc"),

        # 文件统计（扁平 skill 仅 .md 自身）
        "line_count": len(content.splitlines()),
        "has_frontmatter": len(meta) > 0,
        "has_body": body.strip() != "",

        # 时间
        "file_last_modified": datetime.fromtimestamp(stat.st_mtime, tz=timezone.utc).isoformat(),
        "file_created": datetime.fromtimestamp(stat.st_ctime, tz=timezone.utc).isoformat(),
    })

    if not is_folder_skill:
        result["size_bytes"] = stat.st_size

    return result


def main():
    """主入口：解析命令行参数，扫描所有 skill，输出结构化 JSON。"""
    parser = argparse.ArgumentParser(
        description="分析本地 skill 文件，输出结构化的 JSON"
    )
    parser.add_argument(
        "-c", "--compact", action="store_true",
        help="紧凑 JSON 输出（无缩进）"
    )
    parser.add_argument(
        "-o", "--output", type=str, default=None,
        help="写入文件而非 stdout"
    )
    args = parser.parse_args()

    all_skills = []
    seen_names = set()  # 防止同名 skill 被重复收录

    # ── 1. 扫描扁平 skill 文件 (skills/*.md) ──
    for dir_name in SKILL_DIRS:
        dir_path = REPO_ROOT / dir_name
        if not dir_path.is_dir():
            print(f"⚠ 目录不存在: {dir_name}", file=sys.stderr)
            continue

        for f in sorted(dir_path.glob("*.md")):
            rel_path = f.relative_to(REPO_ROOT).as_posix()
            try:
                skill = analyze_skill(rel_path, is_folder_skill=False)
                if skill["name"] not in seen_names:
                    all_skills.append(skill)
                    seen_names.add(skill["name"])
            except Exception as err:
                print(f"✗ 解析失败: {rel_path} — {err}", file=sys.stderr)

    # ── 2. 扫描文件夹型 skill (cards/*/skill.md) ──
    for glob_pattern in CARD_SKILL_GLOBS:
        for f in sorted(REPO_ROOT.glob(glob_pattern)):
            rel_path = f.relative_to(REPO_ROOT).as_posix()
            try:
                skill = analyze_skill(rel_path, is_folder_skill=True)
                if skill["name"] not in seen_names:
                    all_skills.append(skill)
                    seen_names.add(skill["name"])
            except Exception as err:
                print(f"✗ 解析失败: {rel_path} — {err}", file=sys.stderr)

    # ── 3. 排序 ──
    # 文件夹型 skill 排在前面，同类型按目录→名称字母序排列
    all_skills.sort(key=lambda s: (
        not s["is_folder_skill"],  # False(0)=文件夹型排前面, True(1)=扁平排后面
        s["directory"],
        s["name"],
    ))

    # ── 4. 构建输出 ──
    output = {
        "skills": all_skills,
        "total": len(all_skills),
        "flat_dirs": SKILL_DIRS,
        "folder_globs": CARD_SKILL_GLOBS,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "generator": "analyze-skills.py",
    }

    # ── 5. 写入文件或输出到 stdout ──
    if args.output:
        out_path = Path(args.output).resolve()
        out_path.write_text(json.dumps(output, ensure_ascii=False, indent=None if args.compact else 2), encoding="utf-8")
        print(f"[OK] written to {out_path} ({len(all_skills)} skills)")
    else:
        print(json.dumps(output, ensure_ascii=False, indent=None if args.compact else 2))


if __name__ == "__main__":
    main()
