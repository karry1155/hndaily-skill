# hndaily - 海南日报 AI 技能

给 AI 智能体（OpenClaw）使用的海南日报助手技能。一条指令即可抓数据、生成简报、合成语音、推送飞书。

---

## 安装（复制到目标机器后执行）

```bash
# 克隆到 OpenClaw skills 目录
git clone https://github.com/karry1155/hndaily-skill.git ~/.openclaw/skills/hndaily

# 进入目录
cd ~/.openclaw/skills/hndaily

# 配置（复制模板 + 编辑）
cp config.example.json config.json
# 编辑 config.json，填入你的飞书 open_id 和 mmx 音色配置
```

## 配置项（config.json）

| 字段 | 说明 | 示例 |
|---|---|---|
| `feishu_target` | 飞书用户 open_id | `user:ou_xxxxxxxx` |
| `tts_voice` | mmx 语音音色名 | `my_voice_kai` |
| `tts_model` | mmx 模型 | `speech-2.8-hd` |
| `tts_region` | mmx 区域 | `cn` |

## 使用方式

在 OpenClaw 对话中触发即可：

- "日报" / "今天日报" / "读报" → 全流程（抓数据+简报+语音+飞书）
- "爬今天" / "hndaily" → 只抓数据
- "列出全部标题" → 查看所有文章
- "生成简报" → 生成 Markdown 简报
- "日报转语音" → 合成 mp3
- "把第 X 版 PDF 给我" → 下载 PDF

## 文件说明

```
skill/
├── SKILL.md           # 技能主文件（AI 读这个）
├── crawler.py         # 爬虫脚本
├── rules.md          # 简报生成规则
├── config.example.json  # 配置模板
├── migrate_data.sh   # 数据迁移脚本（换机器时用）
└── .gitignore        # 忽略 config.json 和 _data/
```

## 数据产物

运行时自动创建 `_data/` 目录（已 gitignore，不会推送）：
- `{date}.json` - 原始版面数据
- `{date}.brief.md` - Markdown 简报
- `{date}.mp3` - 语音文件

## 换机器迁移

把整个 `hndaily/` 文件夹复制过去即可，包括 `_data/`（历史数据）。

---

如需修改技能行为，编辑 `SKILL.md` 或 `crawler.py` 后 push 即可。