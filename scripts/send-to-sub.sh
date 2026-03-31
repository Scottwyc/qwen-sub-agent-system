#!/bin/bash
# Qwen Code 向 tmux 子进程发送 prompt 指令
# 用法：send-to-sub.sh <session-name> <prompt-text>
#
# 说明：使用 paste-buffer 方式可靠地发送 prompt 到子进程

SESSION_NAME="$1"
PROMPT_TEXT="$*"

if [ -z "$SESSION_NAME" ] || [ -z "$PROMPT_TEXT" ]; then
    echo "用法：$0 <session-name> <prompt-text>"
    echo ""
    echo "示例:"
    echo "  $0 qwen-sub 请分析刚才生成的代码"
    echo "  $0 qwen-sub 请总结一下当前的发现"
    echo "  $0 qwen-sub 请停止当前操作，打印'任务完成'"
    exit 1
fi

# 检查会话是否存在
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "❌ 会话 '$SESSION_NAME' 不存在"
    echo "使用 'tmux list-sessions' 查看可用会话"
    exit 1
fi

echo "📮 向 '$SESSION_NAME' 发送 prompt："
echo "   $PROMPT_TEXT"
echo ""

# 使用 paste-buffer 方法可靠地发送 prompt（3 步）
# 1. 设置缓冲区
tmux set-buffer "$PROMPT_TEXT"

# 2. 粘贴到会话
tmux paste-buffer -t "$SESSION_NAME"

# 3. 发送 Enter 提交
sleep 0.5
tmux send-keys -t "$SESSION_NAME" C-m

echo "✅ Prompt 已发送"
echo "💡 提示：使用 'tmux attach -t $SESSION_NAME' 查看效果"
echo "   或查看日志：tail -f /home/wuyangcheng/.qwen/logs/${SESSION_NAME}_*.log"
