# AI 卡片结构化消息与桶存储方案

## 1. 背景说明

当前项目已经支持聊天室成员体系，AI 助手可以作为 `_collaboration_nodes.node_type = AI_AGENT` 的协作节点，通过 `INVITE_MEMBER` 加入聊天室。根据现有《聊天室成员与邀请》文档，聊天室成员可以是普通用户，也可以是协作节点；其中 `node_type=AI_AGENT` 表示 AI 助手，邀请后默认角色为 `assistant`。:contentReference[oaicite:0]{index=0}

目前前端已经实现了“添加 AI 助手”的基础流程：

1. 手机端点击“添加助手”；
2. 前端调用 `INVITE_MEMBER` 把 AI 助手加入聊天室；
3. 前端本地生成一张 AI 卡片；
4. 该卡片目前是 `localOnly=true` 的本地模拟消息；
5. 因为没有经过后端广播，所以只有当前手机端能看到，TV 端看不到，也无法进入历史消息。

因此，我们希望将 AI 卡片升级为**真正经过后端的聊天室消息**，让手机端、TV 端和后续其他终端都能统一收到、展示和补拉。

## 2. 核心想法

AI 卡片的数据可以由 AI 服务、运营配置工具或后端任务生成，然后存放到对象存储桶中。

但是，桶只负责保存“卡片内容”，不能替代聊天室消息系统。

正确链路应该是：

```text
卡片数据生成方
→ 生成结构化 card_json
→ 上传到对象存储桶
→ 将 card_key / card_version / card_hash 提交给后端
→ 后端校验卡片归属、权限和 URL 安全
→ 后端生成一条聊天室卡片消息
→ 后端将消息落库
→ 后端通过 222 广播给当前聊天室所有在线端
→ 手机端和 TV 端收到 ai_card_ref 消息
→ 前端通过后端接口获取桶中的 card_json
→ 手机端和 TV 端分别用原生组件渲染卡片
```

---

简言之：

```text
桶 = 内容存储层
后端 = 消息权威层 + 鉴权层 + 广播层
前端 = 拉取结构化数据 + 原生渲染层
```

---

## 3. 为什么不能让前端直接从桶中找卡片？

不建议让手机端和 TV 端直接根据桶路径查找卡片，原因如下：

1. 无法证明这张卡片属于哪个聊天室；
2. 无法保证只有房间成员可以查看；
3. 无法保证消息顺序；
4. 无法和聊天室消息历史统一；
5. 无法做 ACK、seq、去重和补拉；
6. 无法保证 TV 和手机端同步看到同一条卡片消息；
7. 桶地址或签名 URL 管理复杂，容易出现权限和安全风险。

所以前端不应该直接依赖桶作为消息来源。

桶应该只保存卡片结构化数据，真正的聊天室消息必须由后端产生和广播。

---

## 4. 推荐整体架构

### 4.1 第一层：卡片内容生成

卡片数据可以由以下来源生成：

```text
1. AI 服务；
2. 后端定时任务；
3. 运营配置后台；
```

生成的数据是结构化 JSON，不是 HTML 字符串。

示例：

```json
{
  "schema_version": "1.0",
  "card_type": "h5_entry",
  "title": "炎图 AI 助手",
  "subtitle": "我已加入当前聊天室",
  "description": "可以为你提供智能协同服务，点击查看推荐内容。",
  "button_text": "打开页面",
  "target_url": "https://www.baidu.com",
  "theme": "general",
  "layout": {
    "variant": "assistant_welcome",
    "icon": "ai"
  }
}
```

---

### 4.2 第二层：对象存储桶

后端或生成方将 card_json 上传到桶中。

示例路径：

```text
chat-cards/room1/msg_10001/card.json
```

桶中的内容仍然是结构化 JSON：

```json
{
  "schema_version": "1.0",
  "card_type": "h5_entry",
  "title": "炎图 AI 助手",
  "subtitle": "我已加入当前聊天室",
  "description": "可以为你提供智能协同服务，点击查看推荐内容。",
  "button_text": "打开页面",
  "target_url": "https://www.baidu.com",
  "theme": "general"
}
```

---

### 4.3 第三层：后端生成聊天室消息

后端不应该只把 card_json 放桶里就结束，而应该生成一条真正的聊天室消息。

推荐消息格式：

```json
{
  "event": "PRIVMSG",
  "channel": "#room1",
  "message_type": "ai_card_ref",
  "sender_type": "ai",
  "sender_id": "15",
  "sender_name": "炎图 AI 助手",
  "server_msg_id": "msg_10001",
  "seq": 128,
  "created_at": "2026-05-20T17:00:00Z",
  "card_key": "chat-cards/room1/msg_10001/card.json",
  "card_version": "1.0",
  "card_hash": "sha256_xxx",
  "fallback": {
    "title": "炎图 AI 助手",
    "description": "点击查看助手推荐内容"
  }
}
```

说明：

| 字段              | 说明                             |
| --------------- | ------------------------------ |
| `message_type`  | `ai_card_ref` 表示这是引用桶中结构化卡片的消息 |
| `sender_type`   | `ai`                           |
| `sender_id`     | AI 助手对应的 `node_id`，例如当前为 `15`  |
| `server_msg_id` | 后端生成的消息 ID                     |
| `seq`           | 房间内递增序号，用于排序、去重和历史补拉           |
| `card_key`      | 桶中的卡片 JSON 路径                  |
| `card_hash`     | 用于校验卡片内容完整性                    |
| `fallback`      | 卡片加载失败时用于前端兜底展示                |

---

### 4.4 第四层：后端广播消息

后端通过现有 222 聊天通道，将该消息广播给当前聊天室内所有在线端。

例如：

```json
{
  "event": "PRIVMSG",
  "channel": "#room1",
  "message_type": "ai_card_ref",
  "from": "AI:15",
  "sender_type": "ai",
  "sender_id": "15",
  "sender_name": "炎图 AI 助手",
  "server_msg_id": "msg_10001",
  "seq": 128,
  "card_key": "chat-cards/room1/msg_10001/card.json",
  "card_version": "1.0",
  "card_hash": "sha256_xxx",
  "fallback": {
    "title": "炎图 AI 助手",
    "description": "点击查看助手推荐内容"
  }
}
```

手机端和 TV 端收到这条消息后，不会把它当普通文本，而是识别：

```text
message_type = ai_card_ref
```

然后进入卡片加载与渲染流程。

---

### 4.5 第五层：前端通过后端接口获取卡片数据

前端不要直接访问桶，也不要持有桶密钥。

推荐由后端提供接口：

```http
GET /api/v1/chat/cards?card_key=chat-cards/room1/msg_10001/card.json
```

后端需要校验：

```text
1. 当前用户或设备是否有权访问该 room；
2. card_key 是否属于该 room；
3. 当前 session 是否有效；
4. TV 设备会话是否未 revoked；
5. 卡片是否未过期；
6. card_hash 是否匹配。
```

校验通过后，后端返回 card_json：

```json
{
  "schema_version": "1.0",
  "card_type": "h5_entry",
  "title": "炎图 AI 助手",
  "subtitle": "我已加入当前聊天室",
  "description": "可以为你提供智能协同服务，点击查看推荐内容。",
  "button_text": "打开页面",
  "target_url": "https://www.baidu.com",
  "theme": "general"
}
```

---

## 5. 前端渲染方式

前端收到 card_json 后，不直接渲染 HTML，而是用原生组件渲染。

### 手机端

手机端渲染为蓝白风格 AI 卡片：

```text
炎图 AI 助手（AI）

我已加入当前聊天室
可以为你提供智能协同服务，点击查看推荐内容。

[打开页面]
```

点击后打开：

```text
ChatH5Page
```

加载 `target_url`。

---

### TV 端

TV 端渲染为适配大屏的 AI 卡片：

```text
炎图 AI 助手（AI）

我已加入当前聊天室
可以为你提供智能协同服务，点击查看推荐内容。

[打开页面]
```

点击后打开：

```text
TvChatH5Page
```

或复用现有 TV WebView 页面。

如果 TV 端 H5 能力暂时不稳定，也可以第一版只展示卡片，不打开页面。

---

## 6. 安全要求

### 6.1 URL 安全

后端和前端都应该校验 `target_url`。

允许：

```text
http://
https://
```

禁止：

```text
javascript:
file:
data:
intent:
ftp:
```

---

### 6.2 不允许传 HTML 字符串

不建议后端传：

```html
<div>...</div>
```

原因：

```text
1. 手机和 TV 渲染不一致；
2. TV 遥控器焦点难控制；
3. 容易产生 XSS 风险；
4. 聊天列表中嵌 WebView 成本高；
5. 后续历史和消息兼容复杂。
```

正确方式是传结构化 JSON：

```json
{
  "card_type": "h5_entry",
  "title": "...",
  "description": "...",
  "button_text": "...",
  "target_url": "..."
}
```

---

### 6.3 不在 URL 中拼接敏感信息

`target_url` 中不要拼接：

```text
session_id
chat_session_id
JWT
bind_token
COS_SECRET_ID
COS_SECRET_KEY
```

如需鉴权，应使用后端短期授权、业务 token 或后端代理，不应暴露主 session。

---

### 6.4 桶权限

前端不要持有：

```text
COS_SECRET_ID
COS_SECRET_KEY
```

推荐两种方式：

#### 方案 A：后端代理读取

前端请求：

```http
GET /api/v1/chat/cards?card_key=xxx
```

后端读取桶并返回 JSON。

优点：

```text
权限好控制
前端无密钥
后续可更换对象存储服务
```

#### 方案 B：后端签发短期 URL

后端返回短期签名 URL：

```json
{
  "card_signed_url": "https://xxx?expires=300"
}
```

前端使用该 URL 拉取 card_json。

优点是减轻后端流量，但需要处理 URL 过期和重试。

当前更推荐方案 A。

---

## 7. 建议后端落库字段

建议后端消息表至少支持：

```text
chat_messages
- id
- room_id / conversation_id
- message_type
- sender_type
- sender_id
- sender_name
- content
- card_key
- card_version
- card_hash
- fallback_json
- server_msg_id
- seq
- created_at
```

其中：

```text
message_type = ai_card_ref
card_key = 桶中 card_json 路径
fallback_json = 加载失败时的简要兜底内容
```

---

## 8. 历史消息返回

未来历史消息接口返回时，也应该包含这条卡片消息：

```json
{
  "server_msg_id": "msg_10001",
  "seq": 128,
  "room_id": "#room1",
  "message_type": "ai_card_ref",
  "sender_type": "ai",
  "sender_id": "15",
  "sender_name": "炎图 AI 助手",
  "card_key": "chat-cards/room1/msg_10001/card.json",
  "card_version": "1.0",
  "card_hash": "sha256_xxx",
  "fallback": {
    "title": "炎图 AI 助手",
    "description": "点击查看助手推荐内容"
  },
  "created_at": "2026-05-20T17:00:00Z"
}
```

前端根据 `server_msg_id` 或 `seq` 去重。

---

## 9. 推荐分阶段实现

### 第一阶段：最小闭环

先不强依赖桶，直接在 222 消息中携带完整 card 对象。

```json
{
  "event": "PRIVMSG",
  "channel": "#room1",
  "message_type": "ai_card",
  "sender_type": "ai",
  "sender_id": "15",
  "sender_name": "炎图 AI 助手",
  "card": {
    "card_type": "h5_entry",
    "title": "炎图 AI 助手",
    "subtitle": "我已加入当前聊天室",
    "description": "点击查看助手推荐内容",
    "button_text": "打开页面",
    "target_url": "https://www.baidu.com"
  }
}
```

目标：

```text
手机和 TV 都能收到并渲染 AI 卡片。
```

---

### 第二阶段：消息落库与历史补拉

将 AI 卡片作为普通聊天室消息落库。

支持历史接口返回：

```text
message_type = ai_card
```

目标：

```text
断线重连后仍能看到 AI 卡片。
```

---

### 第三阶段：桶存储 card_json

当卡片变复杂后，将 card_json 放桶，消息中只放：

```text
card_key
card_version
card_hash
fallback
```

目标：

```text
支持复杂卡片、多端复用、长期存储、缓存优化。
```

---

### 第四阶段：真实 AI 服务

由 AI 服务根据上下文生成不同类型卡片：

```text
1. 助手欢迎卡片；
2. 健康建议卡片；
3. 内容推荐卡片；
4. H5 工具入口卡片；
5. 任务提醒卡片。
```

---

## 10. 后端需要确认的问题

请后端确认：

1. 是否可以在 `INVITE_MEMBER` 成功添加 `AI_AGENT` 后，生成一条 `ai_card` 或 `ai_card_ref` 消息？
2. 这条消息是否可以通过现有 222 `PRIVMSG` 广播给 room 内所有在线端？
3. 是否可以为该消息生成 `server_msg_id` 和 `seq`？
4. 是否可以将该消息落库，供历史接口返回？
5. 如果使用桶，后端是否提供 `GET /api/v1/chat/cards?card_key=xxx` 代理接口？
6. 桶中的 card_json 是否由后端统一校验并绑定到 room_id？
7. 是否需要避免重复发送 AI 欢迎卡片？
8. 如果同一个房间已经有 AI 欢迎卡片，再次添加助手时返回什么？
9. TV 设备 session 是否有权限拉取该房间的 card_json？
10. `target_url` 的安全校验由后端做，还是前后端都做？

---

## 11. 前端配合规划

后端实现后，前端会做：

1. 手机端和 TV 端支持 `message_type=ai_card`；
2. 手机端和 TV 端支持 `message_type=ai_card_ref`；
3. 收到 `ai_card` 时直接渲染；
4. 收到 `ai_card_ref` 时通过后端接口拉取 card_json；
5. 手机和 TV 均使用原生卡片组件渲染；
6. 点击卡片打开 H5 页面；
7. 不直接渲染 HTML；
8. 不直接持有桶密钥；
9. 不将 card_json 当作普通文本消息。

---

## 12. 验收标准

第一阶段验收：

```text
1. 手机点击添加助手；
2. 后端 INVITE_MEMBER 成功；
3. 后端广播 AI 卡片消息；
4. 手机端收到并显示卡片；
5. TV 端收到并显示卡片；
6. 普通文本聊天不受影响。
```

第二阶段验收：

```text
1. AI 卡片消息进入历史；
2. 手机重进聊天室能补拉；
3. TV 重进聊天室能补拉；
4. 不重复显示卡片。
```

第三阶段验收：

```text
1. card_json 存桶；
2. 消息中只包含 card_key / fallback；
3. 手机端和 TV 端能通过后端接口获取 card_json；
4. 无权限用户无法获取 card_json；
5. target_url 安全校验生效。
```

---

## 13. 总结

最终推荐方案是：

```text
AI 卡片数据可以放桶；
但聊天室中的“AI 卡片消息”必须由后端生成、落库、广播；
前端收到消息后，再通过后端接口获取桶中的结构化 card_json；
手机端和 TV 端分别使用原生 UI 渲染卡片。
```

这样可以同时保证：

```text
1. 手机和 TV 同步显示；
2. 权限可控；
3. 消息可排序；
4. 历史可补拉；
5. 桶数据可复用；
6. 后续可扩展真实 AI 服务。
```

```

这份就是比较完整的后端说明文档。  
你可以先让后端按**第一阶段：直接广播 `ai_card` 结构化消息**做，等稳定后再升级到**第三阶段：桶存储 `card_json` + 后端接口拉取**。
​```xxxxxxxxxx 卡片数据生成方→ 生成结构化 card_json→ 上传到对象存储桶→ 将 card_key / card_version / card_hash 提交给后端→ 后端校验卡片归属、权限和 URL 安全→ 后端生成一条聊天室卡片消息→ 后端将消息落库→ 后端通过 222 广播给当前聊天室所有在线端→ 手机端和 TV 端收到 ai_card_ref 消息→ 前端通过后端接口获取桶中的 card_json→ 手机端和 TV 端分别用原生组件渲染卡片text
```

## 14.补充说明

### \1. 消息类型定义

#### 聊天消息类型 message_type

聊天室消息统一通过 `PRIVMSG` 广播，但根据 `message_type` 决定前端如何渲染。

第一阶段支持：

| message_type | 含义                                                         | 前端渲染方式 |
| ------------ | ------------------------------------------------------------ | ------------ |
| text         | 普通文本消息                                                 | 文本气泡     |
| ai_card      | AI 结构化卡片，消息体内直接包含 card JSON                    | 原生 AI 卡片 |
| ai_card_ref  | AI 卡片引用，消息体内只包含 card_key，前端再通过后端接口获取 card_json | 原生 AI 卡片 |
| system       | 系统提示，可选                                               | 系统提示文本 |

说明：

- `message_type=text`：和普通聊天一样。
- `message_type=ai_card`：后端直接把完整 card 对象放在消息里。
- `message_type=ai_card_ref`：后端只传 card_key / fallback，前端通过后端接口获取 card_json。
- 前端不会把 HTML 字符串直接渲染到聊天列表中。



### \2. 卡片模板类型定义

### AI 卡片模板类型 card_type

`message_type=ai_card` 或 `ai_card_ref` 只说明这条消息是卡片消息。

卡片内部还需要通过 `card_type` 区分具体模板。

第一阶段建议只支持一种：

| card_type         | 含义                                       | 使用场景                |
| ----------------- | ------------------------------------------ | ----------------------- |
| h5_entry          | H5 入口卡片                                | 点击打开一个 H5 页面    |
| assistant_welcome | AI 助手欢迎卡片，可选，也可以归入 h5_entry | AI 助手加入聊天室后发送 |

后续可扩展：

| card_type         | 含义                |
| ----------------- | ------------------- |
| homework_reminder | 作业提醒卡片        |
| recommendation    | 推荐内容卡片        |
| task              | 任务卡片            |
| health_advice     | 健康建议卡片        |
| media_preview     | 音视频/文件预览卡片 |

第一阶段不需要做很多模板，先把 `h5_entry` 跑通即可。





### \3. 什么时候生成卡片消息

### AI 卡片消息生成时机

AI 卡片不是用户点击后才生成，而是由后端在业务事件发生时生成，并作为聊天室消息广播。

常见触发场景：

1. **AI 助手加入房间**
   - 手机端调用 `INVITE_MEMBER` 邀请 AI_AGENT。
   - 后端确认 AI_AGENT 加入成功。
   - 后端生成一条 `message_type=ai_card` 的欢迎卡片。
   - 后端广播给房间内所有在线端。

2. **用户在聊天室中发送问题**
   - 用户发送普通文本，比如“今天课本多少页的作业？”
   - 后端或 AI 服务识别该消息需要卡片回复。
   - 后端生成一条 `message_type=ai_card` 或 `ai_card_ref` 消息。
   - 后端广播给房间内所有在线端。

3. **定时任务或 AI 服务主动生成**
   - 例如提醒、推荐、任务通知。
   - 后端生成卡片消息并广播。

总结：

```text
业务事件触发
→ 后端生成卡片消息
→ 后端广播
→ 前端渲染卡片
→ 用户点击卡片打开 H5
```