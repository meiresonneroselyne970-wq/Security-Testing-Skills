---
name: skill-manager
description: Skill 管理器，分析、提取、分类和打包本地 skill 文件。基于 analyze-skills.py 脚本生成结构化 JSON，支持按分类/标签/目录筛选，导出 JSON 包和 ZIP 压缩包。
---

# skill-manager — Skill 分析·提取·分类·打包

**版本**: 1.3.0
**依赖**: `.claude/skills/analyze-skills.py`（Python 3，无第三方库依赖）
**适用场景**: 分析本地 skill 文件、按条件筛选 skill、分类汇总、打包分发

---

## Trigger

当用户提到以下任何一种情况时触发此 skill：

- 分析 skill / skill 分析 / 扫描 skill
- 提取 skill / 筛选 skill / 查找 skill
- skill 分类 / skill 汇总 / skill 清单
- 打包 skill / 导出 skill / skill 分发 / ZIP 打包
- 生成 skill 报告 / skill JSON
- skill manager / manage skills
- 列出所有 skill / 查看 skill 列表

---

## 操作指南

### 1. 分析 — 扫描所有 skill 并生成 JSON

```bash
cd card-template
python .claude/skills/analyze-skills.py              # 格式化输出到 stdout
python .claude/skills/analyze-skills.py --compact    # 紧凑 JSON
python .claude/skills/analyze-skills.py -o result.json  # 写入文件
```

**Python 路径**：`C:/Users/Pc/AppData/Roaming/uv/python/cpython-3.14.5-windows-x86_64-none/python`

**扫描范围**：`skills/`（5 个扁平 skill）+ `cards/*/skill.md`（9 个文件夹型 skill）= 14 个

**输出字段**：
| 字段 | 说明 |
|------|------|
| `id` | 唯一标识 `@local/{name}` |
| `name` | skill 名称 |
| `display_name` | 标题行（含中文描述） |
| `title_description` | 纯中文描述 |
| `description` | frontmatter 描述 |
| `directory` | 所属目录 |
| `file_path` | 相对路径 |
| `version` | 版本号（从 `**版本**` 字段提取） |
| `category` | 分类（security/repository/system/tool/generator/engine/media/scoring/index） |
| `tags` | 自动标签（含 `category:XX`、`directory:XX`） |
| `scenarios` | 适用场景 |
| `maintainer` | 维护者 |
| `size_bytes` / `line_count` | 文件统计 |
| `file_last_modified` / `file_created` | 文件时间（ISO8601 UTC） |

---

### 2. 提取 — 按条件筛选 skill

分析完成后，用 `--output` 写入 JSON 文件，然后根据需要对结果进行筛选：

**按分类筛选：**
```bash
# 从 JSON 中提取指定分类的 skill
python -c "
import json
data = json.load(open('result.json', encoding='utf-8'))
cats = ['security', 'generator']  # 目标分类
result = [s for s in data['skills'] if s['category'] in cats]
print(json.dumps(result, ensure_ascii=False, indent=2))
"
```

**按标签筛选：**
```bash
python -c "
import json
data = json.load(open('result.json', encoding='utf-8'))
result = [s for s in data['skills'] if 'ai' in s['tags']]
print(json.dumps(result, ensure_ascii=False, indent=2))
"
```

**按目录筛选：**
```bash
python -c "
import json
data = json.load(open('result.json', encoding='utf-8'))
result = [s for s in data['skills'] if s['directory'] == 'skills']
print(json.dumps(result, ensure_ascii=False, indent=2))
"
```

**按名称模糊匹配：**
```bash
python -c "
import json
data = json.load(open('result.json', encoding='utf-8'))
keyword = 'security'
result = [s for s in data['skills'] if keyword in s['name']]
print(json.dumps(result, ensure_ascii=False, indent=2))
"
```

---

### 3. 分类 — 汇总统计

```bash
# 按分类统计 skill 数量
python -c "
import json
from collections import Counter
data = json.load(open('result.json', encoding='utf-8'))
cats = Counter(s['category'] for s in data['skills'])
for c, n in cats.most_common():
    print(f'  {c}: {n}')
print(f'  total: {len(data[\"skills\"])}')
"

# 按目录统计
python -c "
import json
from collections import Counter
data = json.load(open('result.json', encoding='utf-8'))
dirs = Counter(s['directory'] for s in data['skills'])
for d, n in dirs.most_common():
    print(f'  {d}: {n}')
"

# 生成分类汇总表
python -c "
import json
data = json.load(open('result.json', encoding='utf-8'))
print('| 分类 | 数量 | Skill |')
print('|------|------|-------|')
from collections import defaultdict
groups = defaultdict(list)
for s in data['skills']:
    groups[s['category']].append(s['name'])
for cat, names in sorted(groups.items()):
    print(f'| {cat} | {len(names)} | {', '.join(names)} |')
"
```

---

### 4. 打包为 JSON — 导出结构化数据包

#### 4.1 生成完整清单文件（含文件内容）

```bash
python -c "
import json
from pathlib import Path

data = json.load(open('result.json', encoding='utf-8'))
repo = Path('.')

TEXT_EXTS = {'.md', '.json', '.html', '.js', '.css', '.py', '.txt', '.yml', '.yaml', '.xml', '.svg'}

pkg = {'version': '1.0', 'skills': []}
for s in data['skills']:
    item = {
        'id': s['id'], 'name': s['name'], 'version': s['version'],
        'category': s['category'], 'tags': s['tags'],
        'description': s['description'], 'scenarios': s['scenarios'],
        'is_folder_skill': s['is_folder_skill'],
    }
    if s['is_folder_skill']:
        item['folder_path'] = s['folder_path']
        item['folder_files'] = s['folder_files']
        item['folder_size_bytes'] = s['folder_size_bytes']
        item['folder_file_count'] = s['folder_file_count']
    else:
        fpath = repo / s['file_path']
        item['content'] = fpath.read_text(encoding='utf-8') if fpath.exists() else None
    pkg['skills'].append(item)

out = 'skills-package.json'
json.dump(pkg, open(out, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
print(f'[OK] {out} ({len(pkg[\"skills\"])} skills)')
"
```

#### 4.2 按分类分包

```bash
python -c "
import json
from pathlib import Path
from collections import defaultdict

data = json.load(open('result.json', encoding='utf-8'))
repo = Path('.')

groups = defaultdict(list)
for s in data['skills']:
    item = {
        'id': s['id'], 'name': s['name'], 'version': s['version'],
        'category': s['category'], 'tags': s['tags'],
        'description': s['description'], 'scenarios': s['scenarios'],
        'is_folder_skill': s['is_folder_skill'],
    }
    if s['is_folder_skill']:
        item['folder_path'] = s['folder_path']
        item['folder_files'] = s['folder_files']
        item['folder_size_bytes'] = s['folder_size_bytes']
    else:
        fpath = repo / s['file_path']
        item['content'] = fpath.read_text(encoding='utf-8') if fpath.exists() else None
    groups[s['category']].append(item)

import os
os.makedirs('packages', exist_ok=True)
for cat, skills in groups.items():
    out = f'packages/skills-{cat}.json'
    json.dump({'version': '1.0', 'category': cat, 'skills': skills}, open(out, 'w', encoding='utf-8'), ensure_ascii=False, indent=2)
    print(f'[OK] {out} ({len(skills)} skills)')
"
```

#### 4.3 生成轻量索引文件（不含内容，用于列表展示）

```bash
python .claude/skills/analyze-skills.py -o skills-index.json
```

---

### 5. 打包为 ZIP — 导出 skill 压缩包

**文件夹型 skill**（`cards/*/`）打包整个目录（HTML + CSS + JS + JSON + 资源），**扁平型 skill**（`skills/*.md`）仅打包 `.md` 文件。所有 skill 保留原始目录结构，附带分析索引。

#### 5.1 打包全部 skill（推荐分发用）

```bash
python -c "
import json, zipfile
from pathlib import Path
from datetime import datetime
import subprocess

py = r'C:/Users/Pc/AppData/Roaming/uv/python/cpython-3.14.5-windows-x86_64-none/python'
subprocess.run([py, '.claude/skills/analyze-skills.py', '-o', 'skills-index.json'], check=True)

data = json.load(open('skills-index.json', encoding='utf-8'))
repo = Path('.')

ts = datetime.now().strftime('%Y%m%d-%H%M%S')
zip_name = f'skills-{ts}.zip'
folder_count = flat_count = 0
with zipfile.ZipFile(zip_name, 'w', zipfile.ZIP_DEFLATED) as zf:
    # 写入分析索引
    zf.writestr('skills-index.json', json.dumps(data, ensure_ascii=False, indent=2))
    for s in data['skills']:
        if s['is_folder_skill']:
            # 文件夹型：打包整个文件夹所有文件
            folder = repo / s['folder_path']
            for rf in s['folder_files']:
                fpath = folder / rf
                if fpath.exists():
                    arcname = f'{s[\"folder_path\"]}/{rf}'
                    zf.write(fpath, arcname)
            folder_count += 1
        else:
            # 扁平型：仅打包 .md 文件
            fpath = repo / s['file_path']
            if fpath.exists():
                zf.write(fpath, s['file_path'])
            flat_count += 1
    print(f'[OK] {zip_name}')
    print(f'     {folder_count} folder skills + {flat_count} flat skills = {len(data[\"skills\"])} total')

# 预览 ZIP 内容
with zipfile.ZipFile(zip_name, 'r') as zf:
    for info in zf.infolist():
        print(f'  {info.filename:60s} {info.file_size:>10,} bytes')
"
```

#### 5.2 按分类打包为独立 ZIP

```bash
python -c "
import json, zipfile
from pathlib import Path
from datetime import datetime
from collections import defaultdict
import os, subprocess

py = r'C:/Users/Pc/AppData/Roaming/uv/python/cpython-3.14.5-windows-x86_64-none/python'
subprocess.run([py, '.claude/skills/analyze-skills.py', '-o', 'skills-index.json'], check=True)

data = json.load(open('skills-index.json', encoding='utf-8'))
repo = Path('.')

groups = defaultdict(list)
for s in data['skills']:
    groups[s['category']].append(s)

ts = datetime.now().strftime('%Y%m%d-%H%M%S')
os.makedirs('packages', exist_ok=True)

for cat, items in sorted(groups.items()):
    zip_name = f'packages/skills-{cat}-{ts}.zip'
    with zipfile.ZipFile(zip_name, 'w', zipfile.ZIP_DEFLATED) as zf:
        # 写入该分类的轻量索引
        cat_index = {'category': cat, 'skills': items, 'total': len(items)}
        zf.writestr('index.json', json.dumps(cat_index, ensure_ascii=False, indent=2))
        for s in items:
            if s['is_folder_skill']:
                folder = repo / s['folder_path']
                for rf in s['folder_files']:
                    fpath = folder / rf
                    if fpath.exists():
                        zf.write(fpath, f'{s[\"folder_path\"]}/{rf}')
            else:
                fpath = repo / s['file_path']
                if fpath.exists():
                    zf.write(fpath, s['file_path'])
    print(f'[OK] {zip_name} ({len(items)} skills)')
"
```

---

### 6. 分发到 Gitee — 与 gitee-repo 联动

打包完成后，借助 [gitee-repo](gitee-repo.md) 将分发包推送到 Gitee 远程仓库，供其他项目/团队成员拉取使用。

#### 6.1 完整发布流程

```
skill-manager 分析打包 ──→ gitee-repo 提交推送
       │                        │
       │  [1] analyze            │  [4] git add packages/
       │  [2] ZIP/JSON 打包      │  [5] git commit
       │  [3] 生成分发包          │  [6] git push
       └────────────────────────┘
```

```bash
# Step 1-3: skill-manager 打包（生成 packages/ 目录下的 ZIP/JSON）
C:/Users/Pc/AppData/Roaming/uv/python/cpython-3.14.5-windows-x86_64-none/python .claude/skills/analyze-skills.py -o skills-index.json
# ... 执行 ZIP 打包命令（见 §5.1）...

# Step 4-6: gitee-repo 推送到远程
git add packages/ skills-index.json
git commit -m "release: skill 分发包 $(date +%Y%m%d)"
git push origin byl-v1.0.0
```

#### 6.2 拉取后刷新索引（反向联动）

从 Gitee 拉取最新代码（可能含新增/更新的 skill）后，重新分析：

```bash
git pull   # gitee-repo 负责
C:/Users/Pc/AppData/Roaming/uv/python/cpython-3.14.5-windows-x86_64-none/python .claude/skills/analyze-skills.py  # skill-manager 刷新索引
```

---

## 执行流程

```
[1] 分析阶段: 运行 analyze-skills.py 生成 JSON
     ├── skills/*.md (5 个扁平 skill)
     └── cards/*/skill.md + cards/services/*/skill.md (9 个文件夹型 skill)
     ↓
[2] 提取阶段 (可选): 按分类/标签/目录/名称筛选
     ↓
[3] 分类阶段 (可选): 按维度汇总统计，生成 Markdown 表格
     ↓
[4] JSON 打包 (可选): 生成含内容的完整包 / 按分类分包 / 轻量索引
     ↓
[5] ZIP 打包 (可选): 压缩所有 skill 文件 + 索引，保留目录结构
     ├── 5.1 全部打包（分发用）
     └── 5.2 按分类独立 ZIP
     ↓
[6] 输出: 打印结果摘要，列出 ZIP 内容清单
```

---

## 执行原则

- **分析优先**：任何操作都从 `analyze-skills.py` 开始，确保数据一致
- **Python 路径**：使用 uv 管理的 Python（`C:/Users/Pc/AppData/Roaming/uv/python/cpython-3.14.5-windows-x86_64-none/python`），不依赖系统 PATH
- **无第三方依赖**：所有脚本仅使用 Python 标准库（`json`, `pathlib`, `collections`, `zipfile`, `subprocess`, `os`, `datetime`）
- **编码安全**：读写文件统一 `utf-8`，兼容 Windows CRLF
- **幂等操作**：多次运行 produce 相同结果
- **ZIP 保留目录结构**：`skills/xxx.md` 在 ZIP 内保持原有路径
- **ZIP 使用 DEFLATED 压缩**：文本文件压缩率高（通常 50-70%）
- **仅扫描 `skills/`**：`.claude/skills/` 为系统级 skill 不纳入分析
- **时间戳命名**：ZIP 文件名含 `YYYYMMDD-HHMMSS` 时间戳，避免覆盖

---

## 当前 Skill 清单（14 个）

### 文件夹型（9 个）— `cards/*/`

| Skill | 分类 | 文件数 | 大小 |
|-------|------|--------|------|
| `text-card` | entry | 11 | 23 KB |
| `homework-card` | education | 7 | 18 KB |
| `media-card` | media | 5 | 18 KB |
| `english-word-card` | english-learning | 9 | 103 KB |
| `english-sentence-card` | english-learning | 9 | 103 KB |
| `english-input-card` | english-learning | 9 | 105 KB |
| `comic-card` | media | 51 | 107 MB |
| `answer-card` | qa | 4 | 26 KB |
| `english-scoring` | scoring | 11 | 69 KB |

### 扁平型（5 个）— `skills/*.md`

| Skill | 分类 | 用途 |
|-------|------|------|
| `selector` | index | 卡片选择器/索引 |
| `card` | generator | AI 卡片生成器（8 种模板） |
| `card_render` | engine | 卡片渲染引擎 |
| `resource_lookup` | engine | 资源查找引擎 |
| `image-generator` | media | 图片生成器 |

---

## 常见问题

### Q1: `python` 命令找不到

使用完整路径：
```
C:/Users/Pc/AppData/Roaming/uv/python/cpython-3.14.5-windows-x86_64-none/python .claude/skills/analyze-skills.py
```

### Q2: 新增 skill 文件未被扫描

确认文件在 `skills/` 目录下，且为 `.md` 扩展名。脚本自动发现，无需手动注册。

### Q3: 打包后内容乱码

所有读写均使用 `utf-8` 编码。若在其他工具中查看，确保以 UTF-8 打开 JSON 文件。

### Q4: JSON 中中文显示为 `\uXXXX`

`analyze-skills.py` 默认使用 `ensure_ascii=False`，中文直接输出。若需要 ASCII 转义，使用 `--compact` 以外的自定义脚本。

### Q5: 为什么 `.claude/skills/` 下的文件不在分析范围内

`.claude/skills/` 下为系统级 skill（安全策略、扫描器等），不参与业务 skill 的分析和打包。如需扩展扫描范围，修改 `analyze-skills.py` 中的 `SKILL_DIRS` 列表。

---

## 版本历史

| 版本 | 日期 | 变更 |
|------|------|------|
| 1.0.0 | 2026-07-02 | 初始版本：分析、提取、分类、JSON 打包四大功能 |
| 1.1.0 | 2026-07-02 | 分类修正（skill-manager 改为 tool）；新增 ZIP 压缩包打包；重构 skill 清单按分类排列 |
| 1.2.0 | 2026-07-02 | 移除 `.claude/skills/` 扫描范围，仅扫描 `skills/`；精简 ZIP 打包模式 |
| 1.3.0 | 2026-07-03 | 新增与 gitee-repo 联动；扫描 cards/*/skill.md 文件夹型 skill；ZIP 打包整个文件夹 |

---

**维护者**: 炎图科技
**最后更新**: 2026-07-03
