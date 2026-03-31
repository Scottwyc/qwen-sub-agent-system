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
    # 检查最后 15 行
    local last_lines=$(tail -15 "$log_file" 2>/dev/null)

    # 检测 esc to cancel - 这是任务进行中的明确标志
    if echo "$last_lines" | grep -q "esc to cancel"; then
        return 0  # 任务进行中
    fi

    return 1  # 未检测到进行中的标志
}

# 检查是否处于等待输入状态（检测选项框）
check_waiting_for_input() {
    local log_file="$1"
    # 检查最后 30 行
    local last_lines=$(tail -30 "$log_file" 2>/dev/null)

    # 检测选项框：数字打头的选项行（如 "1. "、"2. "、"3. " 等）
    # 匹配模式：行首是数字 + 点 + 空格 或 数字 + 顿号 + 空格
    if echo "$last_lines" | grep -qE "^[[:space:]]*[0-9]+[.、] "; then
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
        # 查找带时间戳的日志文件（最新的一个）
        log_file=$(ls -t ${LOG_DIR}/${session}_*.log 2>/dev/null | head -1)

        if [ -z "$log_file" ] || [ ! -f "$log_file" ]; then
            # 如果日志文件不存在，创建一个（带时间戳，覆盖模式）
            log_file="${LOG_DIR}/${session}_$(date +%Y%m%d_%H%M%S).log"
            echo "# ${session} 日志" > "$log_file"
            echo "启动时间：$(date '+%Y-%m-%d %H:%M:%S')" >> "$log_file"
            echo "---" >> "$log_file"
        fi

        # 从 tmux 捕获最新输出（100 行）
        latest_output=$(tmux capture-pane -p -t "$session" -S -100 2>/dev/null | tail -100)
        timestamp=$(date '+%Y-%m-%d %H:%M:%S')

        # 覆盖写入日志文件（只保留最新 100 行）
        {
            echo "# ${session} 日志"
            echo "更新时间：${timestamp}"
            echo "---"
            echo "$latest_output"
        } > "$log_file"

        # 检查任务状态（仅用于通知检测）
        if check_task_in_progress "$log_file"; then
            status="🔄 运行中"
        elif check_waiting_for_input "$log_file"; then
            status="⏳ 等待输入"
        else
            status="❓ 未知状态"
        fi

        # 检查是否已经通知过
        if grep -q "\"$session\": *true" "$STATE_FILE" 2>/dev/null; then
            sleep "$INTERVAL"
            continue
        fi

        # 检查任务是否完成且等待输入
        if ! check_task_completed "$log_file"; then
            sleep "$INTERVAL"
            continue  # 任务未完成或不在等待输入
        fi

        # 发送通知
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

        # 记录到日志（覆盖模式，只保留最新状态）
        {
            echo "最后更新：$timestamp"
            echo "会话：$session"
            echo "状态：任务完成，等待输入"
            echo ""
            echo "所有会话状态:"
            tmux list-sessions 2>/dev/null | grep -E "qwen-(sub|auto)" | while read line; do
                sess_name=$(echo "$line" | cut -d':' -f1)
                sess_log=$(ls -t "${LOG_DIR}/${sess_name}"_*.log 2>/dev/null | head -1)
                if [ -n "$sess_log" ]; then
                    if check_task_in_progress "$sess_log"; then
                        sess_status="🔄 运行中"
                    elif check_waiting_for_input "$sess_log"; then
                        sess_status="⏳ 等待输入"
                    else
                        sess_status="❓ 未知"
                    fi
                    echo "  $sess_name: $sess_status"
                fi
            done
        } > "$LOG_DIR/watcher.log"
    done

    sleep "$INTERVAL"
done
