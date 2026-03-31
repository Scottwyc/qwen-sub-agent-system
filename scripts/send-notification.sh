#!/bin/bash
# Qwen Code 发送通知到主进程
# 用法：send-notification.sh "消息内容"

MESSAGE="$1"
if [ -z "$MESSAGE" ]; then
    echo "用法：$0 \"消息内容\""
    exit 1
fi

# 获取当前会话
CURRENT_SESSION=$(tmux display-message -p '#S' 2>/dev/null)

# 方法 1: 发送到当前会话的状态行（持续 3 秒）
if [ -n "$CURRENT_SESSION" ]; then
    tmux -t "$CURRENT_SESSION" display-message -c "#[fg=yellow,bold,nounderscore]⚠️  $MESSAGE" -d 3000
fi

# 方法 2: 发送弹窗通知（持续 3 秒）
if [ -n "$CURRENT_SESSION" ]; then
    tmux display-popup -t "$CURRENT_SESSION" \
        -b "rounded" \
        -d 3000 \
        -s "fg=yellow,bg=black" \
        -E "" \
        "⚠️  $MESSAGE" 2>/dev/null || true
fi

# 方法 3: 终端 bell 声音
echo -ne '\a'

# 方法 4: 直接输出（如果是在前台运行）
echo ""
echo "=========================================="
echo "⚠️  $MESSAGE"
echo "=========================================="
echo ""
