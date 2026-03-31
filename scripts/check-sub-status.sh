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
    
    # 检查最后 50 行
    local last_lines=$(tail -50 "$log_file" 2>/dev/null)
    
    # 检测等待输入的特征
    if echo "$last_lines" | grep -q "Type your message"; then
        echo "⏳ 等待输入"
        return
    fi
    
    if echo "$last_lines" | grep -q "shift + tab to cycle"; then
        echo "⏳ 等待输入"
        return
    fi
    
    if echo "$last_lines" | grep -q "AskUserQuestion"; then
        echo "⏳ 等待输入"
        return
    fi
    
    if echo "$last_lines" | grep -q "YOLO mode"; then
        echo "⏳ 等待输入"
        return
    fi
    
    # 检查是否正在运行（有活动进程）
    if ps aux | grep -q "qwen.*$session" 2>/dev/null; then
        echo "🔄 运行中"
        return
    fi
    
    # 检查是否完成
    if echo "$last_lines" | grep -qi "done\|完成\|finished"; then
        echo "✅ 已完成"
        return
    fi
    
    echo "🔄 运行中"
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
        waiting=0
        completed=0
        
        for session in $sessions; do
            status=$(check_session_status "$session")
            printf "  %-35s %s\n" "$session:" "$status"
            
            case "$status" in
                *"运行中"*) running=$((running + 1)) ;;
                *"等待输入"*) waiting=$((waiting + 1)) ;;
                *"已完成"*) completed=$((completed + 1)) ;;
            esac
        done
        
        echo "───────────────────────────────────────────────────"
        echo "  统计：$running 运行中 | $waiting 等待输入 | $completed 已完成"
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
