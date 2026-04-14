#!/bin/bash
# Long 模式定时监督脚本
# 用法：long-mode-supervisor.sh <session-name> [interval-seconds]
#
# 功能：
# - 定时向 Long 模式 tmux 会话发送进展查询指令
# - 使用 paste-buffer 方式可靠地发送指令
# - 自动捕获并记录最新进展到报告文档

SESSION_NAME="$1"
INTERVAL="${2:-300}"  # 默认 300 秒（5 分钟）

if [ -z "$SESSION_NAME" ]; then
    echo "用法：$0 <session-name> [interval-seconds]"
    echo "示例：$0 qwen-long 300"
    exit 1
fi

echo "═══════════════════════════════════════════════════"
echo "  Long 模式定时监督脚本启动"
echo "═══════════════════════════════════════════════════"
echo "会话：$SESSION_NAME"
echo "间隔：${INTERVAL} 秒"
echo "开始时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 进展文件路径
PROGRESS_FILE="/home/wuyangcheng/.qwen/progress/${SESSION_NAME}.txt"

# 监督循环
while true; do
    # 检查会话是否存在
    if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ 会话 $SESSION_NAME 已结束，监督脚本退出"
        echo ""
        echo "监督脚本退出时间：$(date '+%Y-%m-%d %H:%M:%S')" >> "$PROGRESS_FILE"
        break
    fi

    # 发送进展查询指令
    PROMPT="请简要汇报当前进展（1-2句话说明当前状态和已完成的工作），不要展开新操作。"

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 📮 向 $SESSION_NAME 发送进展查询..."

    # 使用 paste-buffer 方法可靠地发送 prompt（3 步）
    tmux set-buffer "$PROMPT"
    tmux paste-buffer -t "$SESSION_NAME"
    sleep 0.5
    tmux send-keys -t "$SESSION_NAME" C-m

    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ 进展查询已发送"

    # 等待 qwen 响应
    sleep 45

    # 捕获最新进展并更新到进展文件
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        # 捕获 tmux 最新输出
        LATEST_OUTPUT=$(tmux capture-pane -p -t "$SESSION_NAME" -S -50 2>/dev/null | tail -30)

        # 更新进展文件（追加模式，保留历史）
        {
            echo ""
            echo "--- 自动监督记录 ---"
            echo "时间：$(date '+%Y-%m-%d %H:%M:%S')"
            echo "状态：🔄 Long 模式运行中"
            echo ""
            echo "最新输出摘要："
            echo "$LATEST_OUTPUT" | head -20
            echo ""
        } >> "$PROGRESS_FILE"

        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 📝 进展已记录到：$PROGRESS_FILE"
        
        # ⚠️ 关键：发送"继续"指令，让 Long 窗口回到之前的任务
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🔄 发送'继续'指令..."
        
        CONTINUE_PROMPT="好的，请继续之前的任务。"
        
        tmux set-buffer "$CONTINUE_PROMPT"
        tmux paste-buffer -t "$SESSION_NAME"
        sleep 0.5
        tmux send-keys -t "$SESSION_NAME" C-m
        
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ '继续'指令已发送，Long 窗口将回到之前的任务"
    fi
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⏰ 等待 ${INTERVAL} 秒后下次监督..."
    echo ""
    
    # 等待指定间隔
    sleep "$INTERVAL"
done

echo "═══════════════════════════════════════════════════"
echo "  Long 模式定时监督脚本结束"
echo "═══════════════════════════════════════════════════"
