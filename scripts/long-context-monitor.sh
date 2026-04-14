#!/bin/bash
# Long 模式上下文监督脚本
# 用法：long-context-monitor.sh <session-name> [threshold-percent]
#
# 功能：
# - 监控 qwen 上下文使用情况（通过 ccusage 或类似工具）
# - 当达到阈值（默认 18% used）且当前已完成一个阶段性结果时
# - 自动向 Long 模式 tmux 发送上下文压缩指令
# - 压缩完成后自动恢复 Long 模式运行

SESSION_NAME="$1"
THRESHOLD="${2:-18}"  # 默认 18% used

if [ -z "$SESSION_NAME" ]; then
    echo "用法：$0 <session-name> [threshold-percent]"
    echo "示例：$0 qwen-long 18"
    exit 1
fi

echo "═══════════════════════════════════════════════════"
echo "  Long 模式上下文监督脚本启动"
echo "═══════════════════════════════════════════════════"
echo "会话：$SESSION_NAME"
echo "阈值：${THRESHOLD}% used"
echo "开始时间：$(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 上下文使用记录文件
CTX_LOG="/home/wuyangcheng/.qwen/logs/${SESSION_NAME}_context_usage.log"

# 检查 ccusage 或类似工具是否可用
check_context_usage() {
    # 尝试使用 ccusage 获取上下文使用情况
    # 如果 ccusage 不可用，尝试其他方式
    
    if command -v ccusage &> /dev/null; then
        # ccusage 可用，直接调用
        CC_OUTPUT=$(ccusage 2>&1)
        # 解析使用百分比（假设格式包含 "XX% used"）
        USAGE_PERCENT=$(echo "$CC_OUTPUT" | grep -oP '\d+(?=% used)' | head -1)
        if [ -n "$USAGE_PERCENT" ]; then
            echo "$USAGE_PERCENT"
            return 0
        fi
    fi
    
    # 如果 ccusage 不可用，尝试从 tmux 输出中估计
    # 这是一个简化的启发式方法
    if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        TMUX_OUTPUT=$(tmux capture-pane -p -t "$SESSION_NAME" -S -200 2>/dev/null)
        
        # 查找上下文使用信息（假设 qwen 会显示类似 "18% used" 的信息）
        USAGE_PERCENT=$(echo "$TMUX_OUTPUT" | grep -oP '\d+(?=% used)' | tail -1)
        if [ -n "$USAGE_PERCENT" ]; then
            echo "$USAGE_PERCENT"
            return 0
        fi
    fi
    
    # 无法获取，返回 -1
    echo "-1"
    return 1
}

# 检查是否已完成一个阶段性结果
check_stage_complete() {
    PROGRESS_FILE="/home/wuyangcheng/.qwen/progress/${SESSION_NAME}.txt"
    
    if [ ! -f "$PROGRESS_FILE" ]; then
        return 1
    fi
    
    # 检查进展文件中是否有阶段性完成的标记
    if grep -q "已完成\|完成关键步骤\|阶段性完成\|阶段完成" "$PROGRESS_FILE" 2>/dev/null; then
        return 0
    fi
    
    # 检查技术报告是否有更新
    TECH_REPORT=$(find /home/wuyangcheng/code -name "LONG_MODE_TECH_REPORT_${SESSION_NAME}_*.md" 2>/dev/null | head -1)
    if [ -n "$TECH_REPORT" ] && [ -f "$TECH_REPORT" ]; then
        # 检查技术报告是否有实质性内容（不只是模板）
        if grep -q "关键技术进展\|测试完成\|阶段成果" "$TECH_REPORT" 2>/dev/null; then
            return 0
        fi
    fi
    
    return 1
}

# 发送上下文压缩指令
send_compress_command() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🧠 发送上下文压缩指令到 $SESSION_NAME..."
    
    # 记录到日志
    {
        echo ""
        echo "--- 上下文压缩触发 ---"
        echo "触发时间：$(date '+%Y-%m-%d %H:%M:%S')"
        echo "上下文使用：${CTX_USAGE}% used"
        echo "触发原因：达到阈值 ${THRESHOLD}% 且阶段性任务完成"
    } >> "$CTX_LOG"
    
    # 步骤 1: 发送 Esc 暂停当前操作
    tmux set-buffer "Esc"
    tmux paste-buffer -t "$SESSION_NAME"
    sleep 1
    tmux send-keys -t "$SESSION_NAME" C-m
    sleep 2
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⏸️  已发送 Esc 暂停"
    
    # 步骤 2: 发送 /compress 指令
    tmux set-buffer "/compress"
    tmux paste-buffer -t "$SESSION_NAME"
    sleep 0.5
    tmux send-keys -t "$SESSION_NAME" C-m
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] 🗜️  已发送 /compress 指令"
    
    # 等待压缩完成（给 qwen 一些时间处理）
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⏳ 等待上下文压缩完成..."
    sleep 30
    
    # 步骤 3: 发送继续 Long 模式指令
    CONTINUE_PROMPT="继续long模式"
    tmux set-buffer "$CONTINUE_PROMPT"
    tmux paste-buffer -t "$SESSION_NAME"
    sleep 0.5
    tmux send-keys -t "$SESSION_NAME" C-m
    
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ▶️  已发送继续 Long 模式指令"
    
    # 记录压缩完成
    {
        echo "压缩完成时间：$(date '+%Y-%m-%d %H:%M:%S')"
        echo "状态：✅ 上下文压缩成功，Long 模式已恢复"
        echo ""
    } >> "$CTX_LOG"
}

# 主监督循环
LAST_COMPRESS_TIME=0
COMPRESS_COOLDOWN=600  # 压缩冷却时间 600 秒（10 分钟），避免频繁压缩

while true; do
    # 检查会话是否存在
    if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ❌ 会话 $SESSION_NAME 已结束，上下文监督脚本退出"
        echo ""
        echo "上下文监督脚本退出时间：$(date '+%Y-%m-%d %H:%M:%S')" >> "$CTX_LOG"
        break
    fi
    
    # 检查上下文使用情况
    CTX_USAGE=$(check_context_usage)
    
    if [ "$CTX_USAGE" != "-1" ] && [ "$CTX_USAGE" -ge "$THRESHOLD" ] 2>/dev/null; then
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⚠️  上下文使用达到阈值：${CTX_USAGE}% used（阈值：${THRESHOLD}%）"
        
        # 检查是否在冷却时间内
        CURRENT_TIME=$(date +%s)
        TIME_SINCE_LAST_COMPRESS=$((CURRENT_TIME - LAST_COMPRESS_TIME))
        
        if [ "$TIME_SINCE_LAST_COMPRESS" -lt "$COMPRESS_COOLDOWN" ] && [ "$LAST_COMPRESS_TIME" -ne 0 ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⏰ 距离上次压缩仅过去 ${TIME_SINCE_LAST_COMPRESS} 秒，冷却期内（${COMPRESS_COOLDOWN} 秒），跳过"
        else
            # 检查是否已完成一个阶段性结果
            if check_stage_complete; then
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ 阶段性任务已完成，触发上下文压缩"
                send_compress_command
                LAST_COMPRESS_TIME=$(date +%s)
            else
                echo "[$(date '+%Y-%m-%d %H:%M:%S')] ⏳ 阶段性任务未完成，等待合适时机再压缩"
            fi
        fi
    else
        if [ "$CTX_USAGE" != "-1" ]; then
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 📊 上下文使用：${CTX_USAGE}% used（阈值：${THRESHOLD}%）"
        else
            echo "[$(date '+%Y-%m-%d %H:%M:%S')] 📊 上下文使用：无法获取"
        fi
    fi
    
    # 记录到日志
    {
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] 上下文使用：${CTX_USAGE}% used"
    } >> "$CTX_LOG"
    
    # 等待 60 秒后再次检查
    sleep 60
done

echo "═══════════════════════════════════════════════════"
echo "  Long 模式上下文监督脚本结束"
echo "═══════════════════════════════════════════════════"
