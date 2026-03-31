#!/bin/bash
# Qwen Code Auto Agent tmux 后台运行脚本
# 用法：tmux-auto-agent.sh <session-name> <task>
#
# ⚠️ 安全限制：严格禁止使用 rm、rmdir 等删除命令
#
# 📋 工作流程:
# 1. 先调用 prepare-sub-agent.sh 保存主进程总结并生成工作计划
# 2. 然后继续执行原来的流程，加载这些文档到子进程 prompt 中
# 3. 子进程执行任务并定期汇报进展

SESSION_NAME="${1:-qwen-auto}"
shift
TASK="$*"

if [ -z "$TASK" ]; then
    echo "用法：$0 <session-name> <task>"
    echo "示例：$0 qwen-auto '优化当前项目的构建流程'"
    exit 1
fi

# 检查 tmux 会话是否已存在
if tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    echo "⚠️  会话 '$SESSION_NAME' 已存在"
    echo "   连接到会话：tmux attach -t $SESSION_NAME"
    echo "   删除会话：tmux kill-session -t $SESSION_NAME"
    exit 1
fi

echo "═══════════════════════════════════════════════════"
echo "  Qwen Code Auto Agent 启动"
echo "═══════════════════════════════════════════════════"
echo ""

# ============================================================================
# 步骤 1: 调用 prepare-sub-agent.sh 准备上下文
# ============================================================================
echo "📋 步骤 1: 准备主进程总结和工作计划..."

# 准备临时文件存储 prepare 脚本生成的文件名
PREPRESS_FILE="/home/wuyangcheng/.qwen/compress_summary.txt"
WORKPLAN_DIR="/home/wuyangcheng/code"

# 生成工作计划文件名
WORKPLAN_FILE="${WORKPLAN_DIR}/QWEN_workPlan_${SESSION_NAME}_$(date +%Y%m%d_%H%M%S).md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 保存主进程 compress 总结
cat > "$PREPRESS_FILE" << EOF
# 主进程会话总结
生成时间：${TIMESTAMP}
任务：${TASK}

## 当前上下文
- 工作目录：/home/wuyangcheng/code
- 会话模式：auto
- 子进程会话：${SESSION_NAME}

## 最近活动
- 用户请求：${TASK}
- 启动时间：${TIMESTAMP}

## 注意事项
- 子进程将继承此上下文继续执行任务
- 所有生成的文件应保存到 ~/code/ 目录
- 进展汇报写入：/home/wuyangcheng/.qwen/progress/${SESSION_NAME}.txt
EOF

echo "   ✅ 主进程总结已保存：${PREPRESS_FILE}"

# 生成工作计划
cat > "$WORKPLAN_FILE" << EOF
# ${SESSION_NAME} 工作计划

**生成时间**: ${TIMESTAMP}
**任务**: ${TASK}

---

## 任务目标

${TASK}

---

## 执行要求

### 1. 参数设置
- 如任务涉及参数配置，请在所有代码、可视化和文档中明确说明参数值

### 2. 文件组织
- 代码文件：\`/home/wuyangcheng/code/\`
- 数据集：\`/home/wuyangcheng/code/dataset*/\`
- 模型结果：\`/home/wuyangcheng/code/result/\`
- 报告文档：\`/home/wuyangcheng/code/\` (使用 \`<task>_report.md\` 命名)
- 可视化：\`/home/wuyangcheng/code/result/\` (PNG 格式)

### 3. 进展汇报
关键进展写入：\`/home/wuyangcheng/.qwen/progress/${SESSION_NAME}.txt\`

写入时机：
- ✅ 任务开始：说明理解和计划
- ✅ 完成关键步骤：总结当前进展
- ✅ 遇到问题：记录问题和解决方案
- ✅ 任务完成：总结成果和输出文件

---

## 安全限制

⚠️ **严格禁止使用以下命令**：
- \`rm\`, \`rm -f\`, \`rm -r\`, \`rm -rf\`
- \`rmdir\`, \`unlink\`, \`shred\`

替代方案：使用 \`mv\` 移动文件到临时目录

---

## 输出要求

### 代码文件
- 完整的 docstring 和注释
- 函数说明和参数说明
- 复杂逻辑的详细注释

### 报告文档
- 使用中文（专业术语可用英文）
- 包含参数设置说明
- 包含实验结果和数据
- 包含可视化图表路径（使用绝对路径）

### 可视化
- 清晰的图表标题
- 坐标轴标签
- 图例说明
- 参数设置标注

---

**状态**: 🔄 等待执行
**最后更新**: ${TIMESTAMP}
EOF

echo "   ✅ 工作计划已保存：${WORKPLAN_FILE}"
echo ""

# ============================================================================
# 步骤 2: 继续原来的流程 - 创建 tmux 会话并启动子进程
# ============================================================================
echo "📋 步骤 2: 创建 tmux 会话并启动子进程..."

# 生成任务缩写（取前 15 个字符，避免截断问题）
TASK_SHORT=$(echo "$TASK" | tr -d ' \t\n' | head -c 45)
WINDOW_NAME="auto-${TASK_SHORT}"

# 创建日志文件（带时间戳，覆盖模式）
LOG_FILE="/home/wuyangcheng/.qwen/logs/${SESSION_NAME}_$(date +%Y%m%d_%H%M%S).log"
mkdir -p /home/wuyangcheng/.qwen/logs

# 创建进展汇报文件
PROGRESS_FILE="/home/wuyangcheng/.qwen/progress/${SESSION_NAME}.txt"
mkdir -p /home/wuyangcheng/.qwen/progress

# 初始化进展文件（覆盖模式）
{
    echo "# $SESSION_NAME 进展汇报"
    echo "任务：$TASK"
    echo "启动时间：$(date '+%Y-%m-%d %H:%M:%S')"
    echo "---"
} > "$PROGRESS_FILE"

# 初始化日志文件（覆盖模式，带时间戳）
{
    echo "# $SESSION_NAME 日志"
    echo "任务：$TASK"
    echo "启动时间：$(date '+%Y-%m-%d %H:%M:%S')"
    echo "---"
} > "$LOG_FILE"

# 创建新的 tmux 会话
tmux new-session -d -s "$SESSION_NAME" -n "$WINDOW_NAME"

# 不自动追加日志（改为监视器定期覆盖更新，只保留最新 100 行）
# tmux pipe-pane -o -t "$SESSION_NAME" "cat >> '$LOG_FILE'"

# 切换到工作目录
tmux send-keys -t "$SESSION_NAME" "cd /home/wuyangcheng/code" Enter
sleep 0.5

# ============================================================================
# 📋 加载主进程总结和工作计划（核心改进）
# ============================================================================

# 获取主进程的 compress 总结（如果存在，加载全部内容）
COMPRESS_SUMMARY=""
COMPRESS_FILE="/home/wuyangcheng/.qwen/compress_summary.txt"
if [ -f "$COMPRESS_FILE" ]; then
    COMPRESS_SUMMARY=$(cat "$COMPRESS_FILE")
    echo "📋 已加载主进程总结：${COMPRESS_FILE}"
fi

# 获取最新的工作计划文件（优先查找包含 session 名称的计划）
WORKPLAN_FILE=""
WORKPLAN_CONTENT=""

# 1. 优先查找包含 session 名称的工作计划
WORKPLAN_FILE=$(ls -t /home/wuyangcheng/code/QWEN_workPlan_${SESSION_NAME}*.md 2>/dev/null | head -1)

# 2. 如果没找到，查找最新的工作计划
if [ -z "$WORKPLAN_FILE" ]; then
    WORKPLAN_FILE=$(ls -t /home/wuyangcheng/code/QWEN_workPlan*.md 2>/dev/null | head -1)
fi

# 3. 如果还是没找到，查找任何 .md 文件
if [ -z "$WORKPLAN_FILE" ]; then
    WORKPLAN_FILE=$(ls -t /home/wuyangcheng/code/*.md 2>/dev/null | head -1)
fi

# 读取工作计划内容
if [ -n "$WORKPLAN_FILE" ] && [ -f "$WORKPLAN_FILE" ]; then
    WORKPLAN_CONTENT=$(cat "$WORKPLAN_FILE")
    echo "📝 已加载工作计划：${WORKPLAN_FILE}"
fi

# ============================================================================
# 构建完整的 system prompt
# ============================================================================

SYSTEM_PROMPT="请先加载你的全局设置（~/.qwen/settings.json），工作目录在 ~/code。

⚠️ 安全限制：禁止使用 rm、rmdir 等删除命令。

🚫 重要：不要启动子进程
- 不要使用 'launch a sub-agent' 或类似委托方式
- 不要调用其他 agent 来执行任务
- 请直接执行任务，使用 shell 命令、Python 脚本等方式
- 所有操作在当前会话中直接完成

📊 进展汇报要求：
关键进展请写入 /home/wuyangcheng/.qwen/progress/${SESSION_NAME}.txt（覆盖模式，不是追加）

写入时机：
- 任务开始：说明理解和计划
- 完成关键步骤：总结当前进展
- 遇到问题：记录问题和解决方案
- 任务完成：总结成果和输出文件

写入格式（覆盖写入，使用 > 重定向）：
  echo \"# \${SESSION_NAME} 进展汇报\" > /home/wuyangcheng/.qwen/progress/\${SESSION_NAME}.txt
  echo \"更新时间：\\\$(date '+%Y-%m-%d %H:%M:%S')\" >> /home/wuyangcheng/.qwen/progress/\${SESSION_NAME}.txt
  echo \"状态：🔄 执行中 / ⏳ 等待输入 / ✅ 已完成\" >> /home/wuyangcheng/.qwen/progress/\${SESSION_NAME}.txt
  echo \"---\" >> /home/wuyangcheng/.qwen/progress/\${SESSION_NAME}.txt
  echo \"## 当前进展\" >> /home/wuyangcheng/.qwen/progress/\${SESSION_NAME}.txt
  echo \"已完成：...\" >> /home/wuyangcheng/.qwen/progress/\${SESSION_NAME}.txt
  echo \"进行中：...\" >> /home/wuyangcheng/.qwen/progress/\${SESSION_NAME}.txt
  echo \"下一步：...\" >> /home/wuyangcheng/.qwen/progress/\${SESSION_NAME}.txt"

# 添加工作计划到 prompt
if [ -n "$WORKPLAN_CONTENT" ]; then
    SYSTEM_PROMPT="${SYSTEM_PROMPT}

📋 最新工作计划：
${WORKPLAN_CONTENT}"
fi

# 添加 compress 总结到 prompt
if [ -n "$COMPRESS_SUMMARY" ]; then
    SYSTEM_PROMPT="${SYSTEM_PROMPT}

📝 主进程会话总结（compress summary）：
${COMPRESS_SUMMARY}"
fi

# 启动 qwen 并使用 -i 选项直接执行任务
tmux send-keys -t "$SESSION_NAME" "qwen -y -i '$TASK' --system-prompt '$SYSTEM_PROMPT'" Enter

echo ""
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

# 自动启动监视器（后台运行，使用 disown 确保不被终止）
echo "🔍 自动启动子进程监视器..."
( /home/wuyangcheng/.qwen/scripts/auto-watch-sub.sh 5 >> /home/wuyangcheng/.qwen/logs/watcher.log 2>&1 ) &
WATCHER_PID=$!
disown $WATCHER_PID
echo "   监视器 PID: $WATCHER_PID"
echo "   提醒文件：/home/wuyangcheng/.qwen/sub_alerts.txt"
echo "   查看提醒：cat /home/wuyangcheng/.qwen/sub_alerts.txt"
echo "   停止监视：~/.qwen/scripts/stop-watcher.sh"
echo ""

# 启动状态监控（在后台定期检查并显示状态）
echo "📊 启动子进程状态监控..."
(
    while true; do
        # 检查子进程是否还在运行
        if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
            # 会话已结束，显示最终状态
            echo ""
            echo "═══════════════════════════════════════════════════"
            echo "  子进程 $SESSION_NAME 已结束"
            echo "═══════════════════════════════════════════════════"
            echo ""
            ~/.qwen/scripts/check-sub-status.sh
            echo ""
            break
        fi

        # 每 30 秒显示一次状态
        sleep 30
        echo ""
        ~/.qwen/scripts/check-sub-status.sh "$SESSION_NAME"
        echo ""
    done
) &
STATUS_PID=$!
disown $STATUS_PID
echo "   状态监控 PID: $STATUS_PID"
echo ""
