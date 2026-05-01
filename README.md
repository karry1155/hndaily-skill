# hndaily

给 AI 智能体（OpenClaw）使用的海南日报助手技能。克隆后直接放到 `~/.openclaw/skills/hndaily` 即可。

---

## 安装

```bash
# 克隆到 OpenClaw skills 目录
git clone https://github.com/karry1155/hndaily-skill.git ~/.openclaw/skills/hndaily

# 配置
cp config.example.json config.json
# 编辑 config.json，填入飞书 open_id 和 mmx 音色配置
```

## 配置（config.json）

```json
{
  "feishu_target": "user:ou_xxxxxxxx",
  "tts_voice": "my_voice_kai",
  "tts_model": "speech-2.8-hd",
  "tts_region": "cn"
}
```

| 字段 | 说明 |
|---|---|
| `feishu_target` | 飞书 open_id，格式 `user:ou_xxx` |
| `tts_voice` | mmx 音色名 |
| `tts_model` | mmx 模型，默认 `speech-2.8-hd` |
| `tts_region` | mmx 区域，默认 `cn` |

## 使用（触发词）

- "日报" / "今天日报" → 全流程（抓数据+简报+语音+推送飞书）
- "爬今天" / "hndaily" → 只抓数据
- "列出全部标题" → 查看所有文章标题
- "生成简报" → 生成 Markdown 简报
- "日报转语音" → 合成 mp3
- "下载第 X 版 PDF" → 下载指定版面 PDF

## 文件清单

```
SKILL.md           # 技能定义（AI 读这个）
crawler.py         # 爬虫脚本
rules.md           # 简报生成规则
config.example.json  # 配置模板
migrate_data.sh   # 换机器时迁移数据用
.gitignore        # 已忽略 config.json 和 _data/
```

## 数据产物

运行时自动创建 `_data/` 目录（已 ignore，不会推送到 Git）：
- `{date}.json` - 原始版面数据
- `{date}.brief.md` - Markdown 简报
- `{date}.mp3` - 语音文件

## 换机器迁移

把整个 `hndaily/` 文件夹（包括 `_data/`）一起拷过去即可。