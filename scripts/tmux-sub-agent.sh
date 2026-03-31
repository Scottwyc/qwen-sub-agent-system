#!/bin/bash
# Qwen Code Sub Agent tmux 后台运行脚本
# 用法：tmux-sub-agent.sh <session-name> <task>
#
# ⚠️ 安全限制：严格禁止使用 rm、rmdir 等删除命令

SESSION_NAME="${1:-qwen-sub}"
shift
TASK="$*"

if [ -z "$TASK" ]; then
    echo "用法：$0 <session-name> <task>"
    echo "示例：$0 qwen-sub '分析当前项目的代码结构'"
    exit 1
fi

# 检查 tmux 会话是否已存在
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "⚠️  会话 '$SESSION_NAME' 已存在"
    echo "   连接到会话：tmux attach -t $SESSION_NAME"
    echo "   删除会话：tmux kill-session -t $SESSION_NAME"
    exit 1
fi

# 生成任务缩写（取前 15 个字符，避免截断问题）
TASK_SHORT=$(echo "$TASK" | tr -d ' \t\n' | head -c 45)
WINDOW_NAME="sub-${TASK_SHORT}"

# 创建日志文件
LOG_FILE="/home/wuyangcheng/.qwen/logs/${SESSION_NAME}_$(date +%Y%m%d_%H%M%S).log"
mkdir -p /home/wuyangcheng/.qwen/logs

# 创建进展汇报文件
PROGRESS_FILE="/home/wuyangcheng/.qwen/progress/${SESSION_NAME}.txt"
mkdir -p /home/wuyangcheng/.qwen/progress

# 初始化进展文件
echo "# $SESSION_NAME 进展汇报" > "$PROGRESS_FILE"
echo "任务：$TASK" >> "$PROGRESS_FILE"
echo "启动时间：$(date '+%Y-%m-%d %H:%M:%S')" >> "$PROGRESS_FILE"
echo "---" >> "$PROGRESS_FILE"

# 创建新的 tmux 会话
tmux new-session -d -s "$SESSION_NAME" -n "$WINDOW_NAME"

# 启动日志记录
tmux pipe-pane -o -t "$SESSION_NAME" "cat >> '$LOG_FILE'"

# 切换到工作目录
tmux send-keys -t "$SESSION_NAME" "cd /home/wuyangcheng/code" Enter
sleep 0.5

# 获取主进程的 compress 总结（如果存在，加载全部内容）
COMPRESS_SUMMARY=""
COMPRESS_FILE="/home/wuyangcheng/.qwen/compress_summary.txt"
if [ -f "$COMPRESS_FILE" ]; then
    COMPRESS_SUMMARY=$(cat "$COMPRESS_FILE")
fi

# 获取最新的工作计划文件
WORKPLAN_FILE=$(ls -t /home/wuyangcheng/code/*.md 2>/dev/null | grep -i "workplan\|plan\|work" | head -1)
if [ -z "$WORKPLAN_FILE" ]; then
    WORKPLAN_FILE=$(ls -t /home/wuyangcheng/code/*.md 2>/dev/null | head -1)
fi

# 构建完整的 system prompt
SYSTEM_PROMPT="请先加载你的全局设置（~/.qwen/settings.json），工作目录在 ~/code，请查看你最新的工作计划（${WORKPLAN_FILE:-~/code/*.md}）。

⚠️ 安全限制：禁止使用 rm、rmdir 等删除命令。
📊 进展汇报：关键进展请写入 /home/wuyangcheng/.qwen/progress/${SESSION_NAME}.txt"

# 如果有 compress 总结，添加到 prompt 中
if [ -n "$COMPRESS_SUMMARY" ]; then
    SYSTEM_PROMPT="${SYSTEM_PROMPT}

📋 主进程会话总结（compress summary）：
${COMPRESS_SUMMARY}"
fi

# 启动 qwen 并使用 -i 选项直接执行任务
tmux send-keys -t "$SESSION_NAME" "qwen -y -i '$TASK' --system-prompt '$SYSTEM_PROMPT'" Enter

echo "✅ Qwen (YOLO 模式) 已在后台启动"
echo "   会话名称：$SESSION_NAME"
echo "   窗口名称：$WINDOW_NAME"
echo "   任务：$TASK"
echo "   日志文件：$LOG_FILE"
echo "   进展文件：$PROGRESS_FILE"
echo ""
echo "⚠️  安全限制：禁止使用 rm、rmdir 等删除命令"
echo ""
echo "📋 常用命令:"
echo "   查看进度：tmux attach -t $SESSION_NAME"
echo "   查看日志：tail -f $LOG_FILE"
echo "   查看进展：/home/wuyangcheng/.qwen/scripts/check-progress.sh $SESSION_NAME"
echo "   分离会话：Ctrl+B, 然后按 D"
echo "   删除会话：tmux kill-session -t $SESSION_NAME"
echo ""

# 自动启动监视器（后台运行，监督子进程但不主动通知主进程）
echo "🔍 自动启动子进程监视器（后台监督模式）..."
( /home/wuyangcheng/.qwen/scripts/auto-watch-sub.sh 5 >> /home/wuyangcheng/.qwen/logs/watcher.log 2>&1 ) &
WATCHER_PID=$!
disown $WATCHER_PID
echo "   监视器 PID: $WATCHER_PID"
echo "   提醒文件：/home/wuyangcheng/.qwen/sub_alerts.txt"
echo "   查看提醒：cat /home/wuyangcheng/.qwen/sub_alerts.txt"
echo "   停止监视：~/.qwen/scripts/stop-watcher.sh"
echo ""
echo "💡 子进程已在后台运行，监视器正在监督中。"
echo "   主进程可继续与其他任务，如需查看进度可手动检查。"
