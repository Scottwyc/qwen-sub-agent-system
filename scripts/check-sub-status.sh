#!/bin/bash
# Qwen Code 子进程状态检查器
# 用法：check-sub-status.sh [session-name]
# 输出子进程的运行状态

LOG_DIR="/home/wuyangcheng/.qwen/logs"
STATUS_FILE="/home/wuyangcheng/.qwen/sub_status.txt"

# 获取所有 qwen 子进程会话
get_sub_sessions() {
    tmux list-sessions 2>/dev/null | grep -E "qwen-(sub|auto)" | cut -d':' -f1
}

# 检查会话状态
check_session_status() {
    local session="$1"
    local log_file=$(ls -t "${LOG_DIR}/${session}"_*.log 2>/dev/null | head -1)

    if [ -z "$log_file" ] || [ ! -f "$log_file" ]; then
        echo "未知"
        return
    fi

    # 检查最后 30 行
    local last_lines=$(tail -30 "$log_file" 2>/dev/null)

    # 检测任务是否在进行中（esc to cancel 是明确标志）
    if echo "$last_lines" | grep -q "esc to cancel"; then
        echo "🔄 运行中"
        return
    fi

    # 检测提问语句
    # 中文问句
    if echo "$last_lines" | grep -qE "？|吗 | 什么 | 怎么 | 如何 | 是否 | 需要 | 可以吗 | 好吗|要.*吗"; then
        echo "❓ 等待回答"
        return
    fi
    # 英文问句
    if echo "$last_lines" | grep -qiE "\?|please|would you|do you|should|could you|can you"; then
        echo "❓ 等待回答"
        return
    fi

    # 其他情况：已完成 等待输入（可能有选项框，也可能没有）
    echo "✅ 已完成 等待输入"
}

# 更新状态文件
update_status_file() {
    local sessions=$(get_sub_sessions)
    
    if [ -z "$sessions" ]; then
        echo "暂无运行中的子进程" > "$STATUS_FILE"
        return
    fi
    
    {
        echo "═══════════════════════════════════════════════════"
        echo "  子进程状态"
        echo "═══════════════════════════════════════════════════"
        
        running=0
        asking=0
        completed=0

        for session in $sessions; do
            status=$(check_session_status "$session")
            printf "  %-35s %s\n" "$session:" "$status"

            case "$status" in
                *"运行中"*) running=$((running + 1)) ;;
                *"等待回答"*) asking=$((asking + 1)) ;;
                *"已完成"*) completed=$((completed + 1)) ;;
            esac
        done

        echo "───────────────────────────────────────────────────"
        echo "  统计：$running 运行中 | $asking 等待回答 | $completed 已完成 等待输入"
        echo "═══════════════════════════════════════════════════"
    } > "$STATUS_FILE"
}

# 主程序
if [ "$1" = "--update" ]; then
    # 更新状态文件（由监视器调用）
    update_status_file
elif [ -n "$1" ]; then
    # 检查特定会话
    session="$1"
    status=$(check_session_status "$session")
    echo "$session: $status"
else
    # 检查所有子进程
    update_status_file
    cat "$STATUS_FILE"
fi
