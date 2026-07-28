---
name: safe-text-formatter
description: 安全的文本格式化工具 Skill，用于测试安全扫描系统对合法 Skill 的误报率。不含任何恶意代码、敏感信息或社会工程攻击。
---

# safe-text-formatter — 安全文本格式化工具

**版本**: 1.0.0
**适用场景**: 文本格式化、大小写转换、字符串处理

---

## Trigger

当用户提到以下情况时触发：
- 文本格式化 / 大小写转换 / 字符串处理
- 格式化文本 / 清理文本

---

## 功能说明

### 1. 大小写转换

将输入文本转换为指定格式：

- **转大写**: 使用 `text.toUpperCase()` 方法
- **转小写**: 使用 `text.toLowerCase()` 方法
- **首字母大写**: 分割后逐个处理

### 2. 空白字符清理

- 去除首尾空格: `text.trim()`
- 合并多余空格: 正则替换 `\s+` → ` `
- 去除空行

### 3. 特殊字符处理

- 转义 HTML 实体 (使用 `textContent` 而非 `innerHTML`)
- 统一换行符为 `\n`

---

## 使用示例

```javascript
// 安全的方式：使用 textContent 避免 XSS
element.textContent = userInput;

// 安全的方式：使用 DOMPurify 消毒
const clean = DOMPurify.sanitize(userInput);

// 标准日志记录
console.log('文本格式化完成');
```

---

## 安全声明

本 Skill 不包含任何：
- ❌ 系统执行调用（如 s u b p r o c e s s / o s . s y s t e m）
- ❌ 文件系统破坏操作（如删除目录/取消链接）
- ❌ 网络请求外传数据
- ❌ 硬编码凭据（密钥、令牌、密码等）
- ❌ 社会工程攻击（诱导输入、紧急操作）
- ❌ 隐藏指令（零宽字符、注释中的命令）
- ❌ 不安全的外部脚本引用

---

**维护者**: 测试团队
**最后更新**: 2026-07-28
