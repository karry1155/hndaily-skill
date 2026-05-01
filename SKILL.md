---
name: hndaily
description: 海南日报全功能助手。一个 skill 完成：抓数据、列出全部标题、生成精简简报、合成语音 mp3、推送飞书。触发词包括"日报""今天日报""看看海南日报""读报""生成日报""帮我读海南日报""日报送飞书""完整呈现日报""列出全部标题""生成简报""日报转语音""下载第 X 版 PDF""hndaily"等。可选参数：YYYY-MM-DD 日期。所有产物落盘到 skill 自带的 _data/ 目录，跨机器迁移整个 hndaily/ 文件夹即可。
user-invocable: true
allowed-tools:
  - Bash(python3 *)
  - Bash(curl *)
  - Bash(mmx *)
  - Read
  - Write
---

# 海南日报全功能助手

整套日报相关能力都在这一个 skill 里。**根据用户怎么说话，决定走哪个流程**。

## 配置文件（每台机器自己改一次）

启动前必须能读到 `<hndaily 目录>/config.json`：

```jsonc
{
  "feishu_target": "user:ou_xxx",   // 自己的飞书 open_id
  "tts_voice": "my_voice_kai",
  "tts_model": "speech-2.8-hd",
  "tts_region": "cn"
}
```

不存在时告诉用户："请复制 config.example.json 为 config.json，填上你自己的飞书 open_id"。

**永远不要把 open_id、音色名等机器相关配置写进本 SKILL.md。**

## 数据目录（DATA_DIR）

由 `crawler.py` 自动决定：
1. 优先 `HNDAILY_DATA_DIR` 环境变量
2. 否则 `<crawler.py 父目录>/_data/`，即 `<hndaily skill 目录>/_data/`

**获取真实路径的方法**：跑一次 crawler，stdout 第一行是 JSON 绝对路径，`dirname` 即 DATA_DIR。本文档所有 `<DATA_DIR>` 占位符都按这个方法解析。

## 全部产物（落盘后才算完）

| 文件 | 产生步骤 | 用途 |
|---|---|---|
| `<DATA_DIR>/{date}.json` | 步骤 A | 原始版面数据（含 brief_path / audio_url 反向引用） |
| `<DATA_DIR>/{date}.brief.md` | 步骤 C | 给用户看的 markdown 简报 |
| `<DATA_DIR>/{date}.mp3` | 步骤 D | 朗读音频 |

每个产物都有幂等检查，重复触发不重做。

---

## 用户场景 → 走哪条路

| 用户怎么说 | 跑哪些步骤 |
|---|---|
| "日报" / "今天日报" / "读报" / "生成日报" / "帮我读海南日报" | **全流程**：A → B → C → D → E |
| "把今天日报爬一下" / "拉日报 JSON" / "hndaily" | 只 **A** |
| "完整呈现 5月1日" / "列出全部标题" / "今天日报所有文章" | A → **B** |
| "生成简报" / "整理日报" / "今天日报精读" | A → **C** |
| "把简报转语音" / "日报转语音" / "朗读简报" | C 已落盘 → **D** |
| "把第 X 版 PDF 给我" / "下载头版 PDF" | A → **PDF 下载子流程** |
| "今天有几版" / "今天版面概况" | A → 简短版面汇报（步骤 A 的"常规汇报"） |

判断歧义时优先选**全流程**——因为这是最常见的使用场景。

---

## 步骤 A：抓数据（爬虫）

```bash
python3 <hndaily skill 目录>/crawler.py [YYYY-MM-DD] [--force]
```

参数解析：
- 空 → 自动定位最新一期（处理午夜尚未发刊的情况）
- `YYYY-MM-DD` → 显式日期
- 自然语言（"昨天" / "五一"）→ 先在脑内换算成 ISO 日期再传

约定：
- stdout 第 1 行 = JSON 绝对路径
- stderr 末行 = `date=... pages=... articles=...` 或 `date=... cached=yes age_min=...`
- 退出码 0 = 成功；2 = 头版抓不到（日期不存在 / 网络故障）；1 = 参数错

幂等：30 分钟内已经爬过的当天 JSON，crawler 直接返回缓存路径。强制重爬：加 `--force`。

### JSON 关键字段

```jsonc
{
  "source": "海南日报",
  "date": "2026-04-30",
  "front_page_url": "...",
  "pdf_url_template": "http://news.hndaily.cn/resfile/{date}/{NNN}/hnrb{yyyymmdd}{NNN}.pdf",
  "fetched_at": "2026-04-30T07:12:33+08:00",
  "page_count": 12,
  "article_count": 53,
  "pages": [
    {
      "page": "001",                  // 可能跳号
      "page_name": "头版",
      "page_url": "...",
      "pdf_url": "...",                // 已预拼好，直接用
      "article_count": 10,
      "articles": [
        {"seq": 1, "title": "...", "url": "...", "author": "", "content": "..."}
      ]
    }
  ]
  // 后续步骤会追加：brief_path, brief_built_at, audio_url, audio_built_at
}
```

### "常规汇报"（用户只说"爬今天"或"今天版面概况"时）

1. 第一行：`海南日报 {date} - 共 {page_count} 个版面、{article_count} 篇文章`
2. 按版面列出，每个版面一行：`第{page}版 {page_name}（{article_count} 篇）`
3. 不要默认列出所有文章标题（一天可能 100+ 篇，太长）
4. 末行：`完整数据：[file](<JSON 绝对路径>)`

如果用户问"头版有什么"或"第 5 版讲了啥"，再展开对应版面的标题列表。

---

## 步骤 B：列全部标题

按版面顺序，每篇 `[标题](url)` 编号输出。**只列标题，不带正文摘要**。

### 输出格式

```
海南日报 {date} — 共 {page_count} 个版面、{article_count} 篇文章

第{page}版 {page_name}（{article_count}篇）

1. [文章标题](url)
2. [文章标题](url)
...

数据来源：<JSON 绝对路径>
附[原文链接](http://news.hndaily.cn/html/{date}/node_1.htm)
```

### 分段策略

满足以下任一条件时自动分段：
- 总文章数 > 40
- 预估单条消息长度 > 8000 字符（按每篇平均 120 字符估算）

分段规则：
- 每段包含 **2 个完整版面**（不切版面）
- 最后一段不足 2 版独立成段
- 每段开头标注：`「第X段（共Y段）」`
- 第一段开头加总览
- 最后一段末尾加完整数据文件链接

### 完整性审查（输出前必过）

逐版逐篇核对，任一不符就报错不输出：

1. **篇数匹配**：输出文章总数 == JSON 的 `article_count`
2. **URL 完整性**：每条 URL 都来自 JSON，不臆造、不补、不漏
3. **标题一致性**：与 JSON 的 `title` 字段一致

参考验证逻辑：
```python
json_urls = [a['url'] for page in data['pages'] for a in page['articles']]
output_urls = [从已构建的 Markdown 中提取出的所有 url]
assert set(json_urls) == set(output_urls), "URL 不一致"
assert len(json_urls) == len(output_urls), "篇数不一致"
```

发现问题**抛出明确错误并列出缺失/多余条目**，不要自行填补或编造。

### 跳过广告版

`article_count == 0` 的版面跳过不输出，但计入版面总数。

---

## 步骤 C：生成简报

读 JSON、按 `<hndaily 目录>/rules.md` 规则提取，生成 400-600 字 markdown。**必须落盘**。

### 流程

1. **读 JSON**：用 Read 工具，offset 跳过过大正文部分
2. **必读 `rules.md` 真源**：里面有 9 节硬规则，不要凭记忆来
3. **按规则提取事实**，丢弃官样套话（"深入贯彻""高度重视""扎实推进"）
4. **重写自查**（rules.md 第 9 节 7 条 checklist），不通过则重写
5. **落盘**：用 Write 工具写到 `<DATA_DIR>/{date}.brief.md`
6. **写回 JSON**：顶层追加 `brief_path` / `brief_built_at`（ISO 时间）
7. **聊天里完整展示** brief.md 内容

### 幂等检查

如果 `<DATA_DIR>/{date}.brief.md` 已存在 **且** mtime 晚于 JSON 的 `fetched_at`，
直接读出来展示，不重新生成。除非用户明确说"重新生成简报"。

### 数字 / 时间换算

- "明起" → 具体日期
- 所有原文具体数字、日期原样保留

### 重大事件判定（严格——一年后用户回头看是否还会被想起）

- ✅ 破纪录、首次/末次、引发后续连锁政策、伤亡或重大事故、世界级赛事开闭幕
- ❌ 开馆、剪彩、签约、会见、参观、调研、慰问、表彰、颁奖、揭牌、研讨会
（更详细的判定例子见 rules.md 第 5 节）

---

## 步骤 D：合成语音

把 brief.md 转成 mp3。**只做语音合成，不再做摘要**。

### 输入来源（按优先级）

1. JSON 的 `brief_path` 字段
2. 回退看 `<DATA_DIR>/{date}.brief.md`
3. 都没有 → 提示用户"请先生成简报（步骤 C）"，**不要自己拼摘要**

### 幂等检查

`<DATA_DIR>/{date}.mp3` 已存在 **且** mtime 晚于 brief.md → 直接复用，不重新合成。除非用户明确说"重新合成语音"。

### 文字处理（喂给 mmx 之前）

1. 去除所有标点：句号、逗号、顿号、分号、冒号、感叹号、问号、引号、括号
2. 去除 markdown 标记：`#`、`*`、`-`、`>`、`【】`、emoji
3. 保留板块标题文字（如"近期生效政策""经济数据""重大事件""简讯"），段落分隔
4. 首行保留"海南日报 X年X月X日"，**不要**追加"（X 版 / X 篇精读）"等括注

### 命令

```bash
mmx speech synthesize \
  --model <config.tts_model> \
  --text "{清洗后的纯文字}" \
  --voice <config.tts_voice> \
  --region <config.tts_region> \
  --out <DATA_DIR>/{date}.mp3
```

### 后置

合成成功后在 JSON 顶层追加 `audio_url` / `audio_built_at`。向用户简报：mp3 路径、文件大小或时长。

---

## 步骤 E：发飞书

发送内容：
1. 文字：brief.md 全文
2. 音频：mp3 文件

调 message 工具：
- channel: `feishu`
- action: `send`
- target: **从 config.json 读** `feishu_target`（绝对不要硬编码！）
- msg_type: `audio`
- media: 步骤 D 产生的 mp3 绝对路径

---

## PDF 下载子流程

URL 规律：

```
http://news.hndaily.cn/resfile/{YYYY-MM-DD}/{NNN}/hnrb{YYYYMMDD}{NNN}.pdf
```

JSON 里每个版面已经预拼好 `pdf_url`，直接用，不要自己拼。

### 用户说"把 XX 文章/XX 版的 PDF 给我"

1. 从 JSON 定位文章 → 找到所在 `pages[i]` → 拿 `pdf_url` / `page` / `page_name`
2. 下载到 `~/Downloads/`，文件名：`海南日报{date}-第{NNN}版-{page_name}.pdf`
   ```bash
   curl -fsSL "$PDF_URL" -o "$HOME/Downloads/海南日报{date}-第{NNN}版-{page_name}.pdf"
   ```
3. 汇报：版面、文章标题、本地路径

注意：PDF 按**版面**发布（不是按文章），同一版面多篇文章共享一个 PDF。

---

## 全流程聊天输出顺序

走全流程（用户说"日报"等总入口词）时：

1. 先在聊天里输出**步骤 C 的 markdown 简报**（用户最关心的内容立即可见）
2. 再发飞书私信（文字 + 音频）
3. 简短一行汇报本次状态（哪些是新生成、哪些是复用缓存），方便排错

如果某步失败：
- crawler 退出码 2（日报未发布） → 提示后结束
- brief 失败 → 飞书发文字 placeholder + 失败原因
- TTS 失败 → 发文字摘要 + "音频生成失败"
- 飞书失败 → 至少产物已落盘 + "推送失败但本地有文件"

---

## 不要做的事

- 不要在用户没要 PDF 时主动下载 PDF
- 不要默认列出所有文章标题（除非走步骤 B）
- 不要重写 `pdf_url`、不要爬"往期/翻页"按钮（脚本一次抓完整期）
- 不要把简报内容塞到 JSON 字段里（简报是独立文件，JSON 只存路径引用）
- 不要在 SKILL.md / crawler.py / config 之外的地方写死 `~/Documents/...` 之类的用户家目录路径
- 不要把 open_id、音色名、模型名硬编码到 SKILL.md——所有"机器相关配置"走 config.json
- 不要在没有 brief.md 时自己拼简报喂 TTS——劣质摘要绕过了 rules.md 的硬约束
- 不要忽略幂等检查盲目重做——TTS 和爬虫都有外部成本
