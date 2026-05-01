#!/usr/bin/env bash
# 把旧数据从 ~/Documents/日报/output/ 迁移到新数据目录（_data/hndaily/）。
# 旧版本（2026-05-01 之前）所有产物在 ~/Documents/日报/output/，
# 新版本统一到 <skills 根>/_data/hndaily/，便于跨机器迁移。
#
# 用法：
#   bash ~/.openclaw/skills/hndaily/migrate_data.sh           # dry-run，列出要迁移的文件
#   bash ~/.openclaw/skills/hndaily/migrate_data.sh --execute # 真的搬
#
# 迁移完成后旧目录原样保留，需要清理自行删除。

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
NEW_DIR="$SCRIPT_DIR/_data"
OLD_DIR="$HOME/Documents/日报/output"
# 兼容历史：拆分版的数据目录（如果用过的话）
OLD_DIR_V2="$(dirname "$SCRIPT_DIR")/_data/hndaily"

echo "==========================================="
echo "海南日报数据迁移"
echo "  从: $OLD_DIR"
echo "  到: $NEW_DIR"
echo "==========================================="

FILES=""
if [ -d "$OLD_DIR" ]; then
  FILES_A=$(find "$OLD_DIR" -maxdepth 1 -type f \
    \( -name "*.json" -o -name "*.brief.md" -o -name "*.mp3" \) | sort)
  FILES="$FILES_A"
fi
if [ -d "$OLD_DIR_V2" ]; then
  FILES_B=$(find "$OLD_DIR_V2" -maxdepth 1 -type f \
    \( -name "*.json" -o -name "*.brief.md" -o -name "*.mp3" \) | sort)
  FILES="$FILES${FILES:+$'\n'}$FILES_B"
fi

if [ -z "$FILES" ]; then
  echo "  ✓ 没有找到旧数据，无需迁移。"
  exit 0
fi

mkdir -p "$NEW_DIR"

if [ -z "$FILES" ]; then
  echo "  ✓ 旧目录里没有日报相关文件。"
  exit 0
fi

COUNT=$(echo "$FILES" | wc -l | xargs)
echo "  发现 $COUNT 个文件可迁移："
echo "$FILES" | sed 's|^|    |'
echo ""

if [ "${1:-}" != "--execute" ]; then
  echo "  这是 dry-run。要真正迁移请加 --execute："
  echo "    bash $0 --execute"
  exit 0
fi

# 执行迁移：copy 而非 mv，旧文件保留作为备份
COPIED=0
SKIPPED=0
echo "  开始复制（旧文件保留）..."
while IFS= read -r f; do
  base=$(basename "$f")
  dest="$NEW_DIR/$base"
  if [ -e "$dest" ]; then
    echo "    跳过（目标已存在）: $base"
    SKIPPED=$((SKIPPED + 1))
  else
    cp -p "$f" "$dest"
    echo "    复制: $base"
    COPIED=$((COPIED + 1))
  fi
done <<< "$FILES"

echo ""
echo "  完成。新增 $COPIED 个，跳过 $SKIPPED 个。"
echo ""
echo "  下一步建议："
echo "    1. 验证：ls $NEW_DIR"
echo "    2. 跑一次 crawler 确认默认目录工作："
echo "       python3 $SCRIPT_DIR/crawler.py 2>&1 | head -3"
echo "    3. 确认无误后旧目录可手动删除："
echo "       rm -rf '$OLD_DIR'"
