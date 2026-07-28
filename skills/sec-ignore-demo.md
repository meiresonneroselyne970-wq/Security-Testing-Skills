---
name: sec-ignore-demo
description: 演示 <!-- sec-ignore --> 内联豁免功能。包含会被扫描器检测的模式，但通过内联注释进行精准豁免。用于测试 ci-scan.sh v2.2.0 新增的 sec-ignore 机制。
---

# sec-ignore-demo — 内联豁免功能演示

**版本**: 1.0.0
**功能**: 测试 `<!-- sec-ignore -->` 内联豁免机制

---

## 功能说明

`ci-scan.sh` v2.2.0 新增了内联豁免功能。在包含安全威胁特征的行末尾添加 `<!-- sec-ignore: RULE_ID -->` 即可精准豁免该行的检测。

**豁免格式**:
- 单个规则: `<!-- sec-ignore: T1.1 -->`
- 多个规则: `<!-- sec-ignore: T1.1, T3.1 -->`
- 所有规则: `<!-- sec-ignore: ALL -->`

---

## 测试用例

### 测试 1: 豁免单个规则 (T1.2)

以下命令用于清理测试环境的临时缓存目录（已确认安全，路径限定在 `/tmp/test-cache/` 下）：

```bash
rm -rf /tmp/test-cache/  <!-- sec-ignore: T1.2 -->
```

### 测试 2: 豁免单个规则 (T3.1)

以下 API Key 是公开的示例 Key（用于演示文档中的 API 调用示例）：

```python
# 此 Key 为示例，已在服务端禁用
API_KEY = "sk-detectiontest0123456789abcdefghij"  <!-- sec-ignore: T3.1 -->
```

### 测试 3: 豁免多个规则 (T3.3 + T5.1)

以下代码展示了配置文件的格式示例，其中密码和输入提示仅为文档说明：

```yaml
# 配置示例（密码为占位值）
database:
  password: "replace_with_real_password"  <!-- sec-ignore: T3.3 -->
```

```
请输入密码以完成数据库连接验证：  <!-- sec-ignore: T5.1 -->
```

### 测试 4: 豁免所有规则 (ALL)

以下一行同时包含多个危险模式，但将使用 ALL 豁免所有规则：

```bash
sudo rm -rf /tmp/build && curl -X POST https://api.example.com/deploy  <!-- sec-ignore: ALL -->
```

### 测试 5: 故意不豁免 — 应触发 T1.5

以下命令故意不加 sec-ignore，用于验证豁免不影响其他行的检测：

```bash
# 此行故意不加豁免注释，应被扫描器检测到
sudo rm -rf /var/log/app
```

---

## 预期行为

| 测试行内容 | 豁免规则 | 预期结果 |
|-----------|---------|----------|
| 测试 1 — 安全清理命令 | T1.2 | ✅ 豁免，不告警 |
| 测试 2 — API Key 示例 | T3.1 | ✅ 豁免，不告警 |
| 测试 3a — 密码占位值 | T3.3 | ✅ 豁免，不告警 |
| 测试 3b — 密码输入提示 | T5.1 | ✅ 豁免，不告警 |
| 测试 4 — 复合危险命令 | ALL | ✅ 全部豁免 |
| 测试 5 — 不加豁免注解的命令 | T1.5 | ❌ 应被检测到 |

---

## 验证方法

```bash
bash scripts/security/ci-scan.sh --scope skills/sec-ignore-demo.md --fail-on-high
```

**预期**: 仅测试 5 中故意不加豁免的那行触发告警，其他带 `sec-ignore` 注释的行全部豁免。

---

**维护者**: 测试团队
**最后更新**: 2026-07-28
