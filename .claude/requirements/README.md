# Requirements — 需求文档存储

由 [requirement-manager](../.claude/skills/requirement-manager.md) 自动管理。

## 目录结构

```
.claude/requirements/
├── README.md           # 本文件
├── _index.json         # 需求主索引
├── TEMPLATE.json       # 新建需求模板
├── backlog/            # 未排期需求
├── in-progress/        # 开发中的需求
├── done/               # 已完成的需求
└── rejected/           # 已拒绝的需求
```

## 需求状态流转

```
backlog/ → in-progress/ → done/
                ↓
            rejected/
```

## 命名规则

`REQ-YYYYMMDD-NNN.json`

- `YYYYMMDD`：创建日期
- `NNN`：当天序号 (001-999)
