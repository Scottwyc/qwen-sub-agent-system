#!/bin/bash
# Qwen Code 子进程自动监督器
# 用法：auto-watch-sub.sh [interval_seconds]
#
# 功能：
# - 后台监视所有 qwen 子进程
# - 检测任务完成且等待输入时发送状态行通知到主进程
# - 不发送弹窗，只发送简洁的状态行消息

INTERVAL=${1:-5}
LOG_DIR="/home/wuyangcheng/.qwen/logs"
ALERT_FILE="/home/wuyangcheng/.qwen/sub_alerts.txt"
STATE_FILE="/home/wuyangcheng/.qwen/sub_state.json"

# 初始化状态文件（记录已通知的会话）
if [ ! -f "$STATE_FILE" ]; then
    echo "{}" > "$STATE_FILE"
fi

# 清空之前的提醒
> "$ALERT_FILE"

echo "=========================================="
echo "  Qwen Code 子进程自动监督器"
echo "=========================================="
echo "刷新间隔：${INTERVAL}秒"
echo "提醒文件：${ALERT_FILE}"
echo "按 Ctrl+C 停止"
echo "=========================================="
echo ""

# 检查任务是否已完成
# 逻辑：如果不在进行中（没有 esc to cancel）且在等待输入，说明任务已完成
check_task_completed() {
    local log_file="$1"
    
    # 如果任务还在进行中，返回未完成
    if check_task_in_progress "$log_file"; then
        return 1
    fi
    
    # 如果在等待输入，说明任务已完成
    if check_waiting_for_input "$log_file"; then
        return 0
    fi
    
    return 1
}

# 检查任务是否仍在进行中（检测 esc to cancel）
check_task_in_progress() {
    local log_file="$1"
    # 只检查最后 10 行
    local last_lines=$(tail -10 "$log_file" 2>/dev/null)
    
    # 检测 esc to cancel - 这是任务进行中的明确标志
    if echo "$last_lines" | grep -q "esc to cancel"; then
        return 0  # 任务进行中
    fi
    
    return 1  # 未检测到进行中的标志
}

# 检查是否处于等待输入状态
check_waiting_for_input() {
    local log_file="$1"
    # 只检查最后 10 行
    local last_lines=$(tail -10 "$log_file" 2>/dev/null)
    
    # 检测标准输入框
    if echo "$last_lines" | grep -q "Type your message"; then
        return 0
    fi
    
    # 检测选项框（shift + tab 循环）
    if echo "$last_lines" | grep -q "shift + tab to cycle"; then
        return 0
    fi
    
    # 检测 YOLO mode 循环提示
    if echo "$last_lines" | grep -q "YOLO mode"; then
        return 0
    fi
    
    return 1
}

while true; do
    # 更新状态文件
    ~/.qwen/scripts/check-sub-status.sh --update

    # 获取所有 qwen 会话
    sessions=$(tmux list-sessions 2>/dev/null | grep -E "qwen-(sub|auto)" | cut -d':' -f1)

    if [ -z "$sessions" ]; then
        sleep "$INTERVAL"
        continue
    fi

    for session in $sessions; do
        log_file=$(ls -t "${LOG_DIR}/${session}"_*.log 2>/dev/null | head -1)

        if [ -z "$log_file" ] || [ ! -f "$log_file" ]; then
            continue
        fi

        # 检查是否已经通知过
        if grep -q "\"$session\": *true" "$STATE_FILE" 2>/dev/null; then
            continue
        fi

        # 检查任务是否完成且等待输入
        if ! check_task_completed "$log_file"; then
            continue  # 任务未完成或不在等待输入
        fi

        # 发送通知
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')
        alert_msg="[$timestamp] ⚠️  会话 '$session' 任务完成，等待输入中..."
        echo "$alert_msg" >> "$ALERT_FILE"

        # 更新状态文件，标记已通知
        if [ -f "$STATE_FILE" ]; then
            if grep -q "\"$session\"" "$STATE_FILE" 2>/dev/null; then
                sed -i "s/\"$session\": *false/\"$session\": true/" "$STATE_FILE"
            else
                if [ "$(cat "$STATE_FILE")" = "{}" ]; then
                    echo "{\"$session\": true}" > "$STATE_FILE"
                else
                    sed -i "s/}$/, \"$session\": true}/" "$STATE_FILE"
                fi
            fi
        fi

        # 获取所有非 qwen 会话作为目标
        TARGET_SESSION=$(tmux list-sessions 2>/dev/null | grep -v "^qwen-" | head -1 | cut -d':' -f1)
        if [ -z "$TARGET_SESSION" ]; then
            TARGET_SESSION=$(tmux list-sessions 2>/dev/null | head -1 | cut -d':' -f1)
        fi

        # 只发送状态行消息（持续显示 3 秒）
        if [ -n "$TARGET_SESSION" ]; then
            tmux display-message -t "$TARGET_SESSION" -d 3000 "#[fg=yellow,bold,nounderscore]⚠️  $session 任务完成，等待输入!" 2>/dev/null || true
        fi

        # 记录到日志
        echo "[$timestamp] 发送通知：$session 任务完成，等待输入" >> "$LOG_DIR/watcher.log"
    done

    sleep "$INTERVAL"
done
