# hndaily - 海南日报全功能助手

一个 skill 完成：抓数据、列出全部标题、生成精简简报、合成语音 mp3、推送飞书。

## 目录结构

```
hndaily-skill/
├── skill/
│   ├── SKILL.md          # 技能主文件
│   ├── crawler.py        # 爬虫脚本
│   ├── rules.md         # 简报生成规则
│   ├── config.example.json  # 配置示例
│   ├── migrate_data.sh  # 数据迁移脚本
│   └── .gitignore       # Git 忽略规则
└── README.md
```

## 快速开始

1. **克隆仓库**
   ```bash
   git clone https://github.com/karry1155/hndaily-skill.git
   cd hndaily-skill/skill
   ```

2. **复制配置文件**
   ```bash
   cp config.example.json config.json
   ```

3. **编辑 config.json**，填入你的飞书 open_id 等配置：
   ```json
   {
     "feishu_target": "user:ou_xxx",
     "tts_voice": "my_voice_kai",
     "tts_model": "speech-2.8-hd",
     "tts_region": "cn"
   }
   ```

4. **运行**
   ```bash
   python3 crawler.py [YYYY-MM-DD] [--force]
   ```

## 功能一览

| 功能 | 命令示例 |
|---|---|
| 爬取当天日报 | `python3 crawler.py` |
| 爬取指定日期 | `python3 crawler.py 2026-05-01` |
| 查看完整标题列表 | 读 JSON 里的所有文章标题 |
| 生成简报 | 读取 JSON + rules.md 生成 |
| 语音合成 | mmx speech synthesize ... |
| 推送飞书 | message 工具发送到用户 |

## 配置说明

- `feishu_target`：飞书用户 open_id（格式 `user:ou_xxx`）
- `tts_voice`：你的 mmx 语音音色名
- `tts_model`：mmx 模型名，默认 speech-2.8-hd
- `tts_region`：mmx 区域，默认 cn

## 数据目录

运行时会自动创建 `_data/` 目录存放：
- `{date}.json` - 原始版面数据
- `{date}.brief.md` - 简报
- `{date}.mp3` - 语音文件

**注意**：不要把 config.json 和 _data/ 目录提交到 Git！已通过 .gitignore 忽略。

## License

MIT