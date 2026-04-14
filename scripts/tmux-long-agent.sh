#!/bin/bash
# Qwen Code Long Agent tmux 后台运行脚本
# 用法：tmux-long-agent.sh <session-name> <task>
#
# Long 模式特性：
# - 在 YOLO 模式基础上，拥有最高权限（但仍然禁止 rm 等删除命令）
# - 能够进行长时间自主运行，直到完成指定任务
# - 自动后台运行定时监督脚本，定期追踪进度并汇报
# - 自动后台运行上下文监督脚本，监控上下文使用情况并在需要时自动压缩
# - 关键进展自动更新中文技术报告
#
# ⚠️ 安全限制：严格禁止使用 rm、rmdir 等删除命令

SESSION_NAME="${1:-qwen-long}"
shift
TASK="$*"

if [ -z "$TASK" ]; then
    echo "用法：$0 <session-name> <task>"
    echo "示例：$0 qwen-long '优化 scorer 训练流程并生成完整报告'"
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
echo "  Qwen Code Long Agent 启动"
echo "═══════════════════════════════════════════════════"
echo ""

# ============================================================================
# 步骤 1: 准备上下文和技术文档
# ============================================================================
echo "📋 步骤 1: 准备主进程总结、工作计划和技术报告模板..."

# 准备临时文件存储 prepare 脚本生成的文件名
PREPRESS_FILE="/home/wuyangcheng/.qwen/compress_summary.txt"

# ============================================================================
# 根据任务内容自动识别项目目录
# ============================================================================

# 默认项目目录
PROJECT_BASE="/home/wuyangcheng/code"
PROJECT_NAME="current-project"
PROJECT_DIR="$PROJECT_BASE"

# 检测任务中是否包含项目名称关键词
if [[ "$TASK" == *"scorer"* ]] || [[ "$TASK" == *"Scorer"* ]] || [[ "$SESSION_NAME" == *"scorer"* ]]; then
    PROJECT_NAME="scorer-searcher"
    PROJECT_DIR="$PROJECT_BASE/scorer-searcher"
elif [[ "$TASK" == *"gan"* ]] || [[ "$TASK" == *"GAN"* ]] || [[ "$SESSION_NAME" == *"gan"* ]]; then
    PROJECT_NAME="gan-decomposer"
    PROJECT_DIR="$PROJECT_BASE/gan-decomposer"
elif [[ "$TASK" == *"diffusion"* ]] || [[ "$TASK" == *"Diffusion"* ]] || [[ "$SESSION_NAME" == *"diffusion"* ]]; then
    PROJECT_NAME="diffusion-model"
    PROJECT_DIR="$PROJECT_BASE/diffusion-model"
elif [[ "$TASK" == *"signlanguage"* ]] || [[ "$TASK" == *"sign"* ]] || [[ "$SESSION_NAME" == *"sign"* ]]; then
    PROJECT_NAME="sign-language"
    PROJECT_DIR="$PROJECT_BASE/sign-language"
elif [[ "$TASK" == *"chat"* ]] || [[ "$TASK" == *"Chat"* ]] || [[ "$SESSION_NAME" == *"chat"* ]]; then
    PROJECT_NAME="chat-app"
    PROJECT_DIR="$PROJECT_BASE/chat-app"
else
    # 尝试从任务描述中提取项目名（取第一个单词作为项目名）
    FIRST_WORD=$(echo "$TASK" | awk '{print $1}' | tr '[:upper:]' '[:lower:]' | tr -cd '[:alnum:]')
    if [ -n "$FIRST_WORD" ]; then
        # 检查是否存在对应的项目目录
        if [ -d "$PROJECT_BASE/$FIRST_WORD" ]; then
            PROJECT_NAME="$FIRST_WORD"
            PROJECT_DIR="$PROJECT_BASE/$FIRST_WORD"
        fi
    fi
fi

# 工作计划目录
WORKPLAN_DIR="$PROJECT_DIR/workPlan"

# 生成工作计划文件名
WORKPLAN_FILE="${WORKPLAN_DIR}/QWEN_workPlan_${SESSION_NAME}_$(date +%Y%m%d_%H%M%S).md"
# 技术报告文件名
TECH_REPORT_FILE="${PROJECT_DIR}/LONG_MODE_TECH_REPORT_${SESSION_NAME}_$(date +%Y%m%d).md"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 创建工作计划目录
mkdir -p "$WORKPLAN_DIR"

# 保存主进程 compress 总结
cat > "$PREPRESS_FILE" << EOF
# 主进程会话总结
生成时间：${TIMESTAMP}
任务：${TASK}

## 当前上下文
- 工作目录：$PROJECT_DIR
- 项目名称：$PROJECT_NAME
- 会话模式：long（长时间自主运行模式）
- 子进程会话：${SESSION_NAME}

## 最近活动
- 用户请求：${TASK}
- 启动时间：${TIMESTAMP}

## Long 模式特性
- 长时间自主运行，直到任务完成
- 自动定时监督脚本追踪进度
- 自动上下文监控并在需要时压缩
- 关键进展自动更新技术报告

## 注意事项
- 子进程将继承此上下文继续执行任务
- 所有生成的文件应保存到 $PROJECT_DIR 目录
- 进展汇报写入：/home/wuyangcheng/.qwen/progress/${SESSION_NAME}.txt
- 技术报告写入：$TECH_REPORT_FILE
EOF

echo "   ✅ 主进程总结已保存：${PREPRESS_FILE}"

# 生成工作计划
cat > "$WORKPLAN_FILE" << EOF
# ${SESSION_NAME} Long 模式工作计划

**生成时间**: ${TIMESTAMP}
**任务**: ${TASK}
**项目**: $PROJECT_NAME ($PROJECT_DIR)
**模式**: Long（长时间自主运行）

---

## 任务目标

${TASK}

---

## 执行要求

### 1. 参数设置
- 如任务涉及参数配置，请在所有代码、可视化和文档中明确说明参数值

### 2. 文件组织

#### 项目目录：$PROJECT_DIR

| 文件类型 | 保存位置 | 示例 |
|----------|----------|------|
| 代码文件 | \`$PROJECT_DIR/src/\` | \`src/model.py\` |
| 报告文档 | \`$PROJECT_DIR/docs/\` | \`docs/report.md\` |
| 结果文件 | \`$PROJECT_DIR/results/\` | \`results/model.pt\` |
| 配置文件 | \`$PROJECT_DIR/configs/\` | \`configs/config.yaml\` |
| 脚本文件 | \`$PROJECT_DIR/scripts/\` | \`scripts/train.sh\` |
| 任务总结 | \`$PROJECT_DIR/\` (根目录) | \`TASK_SUMMARY_*.md\` |
| 技术报告 | \`$PROJECT_DIR/\` (根目录) | \`LONG_MODE_TECH_REPORT_*.md\` |

### 3. Long 模式特殊要求

#### 3.1 后台进程管理
- 如果需要跟踪长时间运行的程序，首先使用 nohup 方式挂在后台运行
- 避免 shell 关闭导致进程被杀掉
- 示例：\`nohup python train.py > train.log 2>&1 &\`

#### 3.2 技术报告更新
- 有关键技术进展或测试结果时，必须更新技术报告
- 技术报告路径：$TECH_REPORT_FILE
- 使用中文撰写（专业术语可用英文）
- 包含：任务概述、关键进展、测试结果、下一步计划

#### 3.3 脚本更新规范
- 如果对之前的脚本有较大更新，先备份原脚本
- 备份命名：\`original_script.py.bak\`
- 然后补充新版本脚本，避免直接覆盖

### 4. 进展汇报
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

# 初始化技术报告
cat > "$TECH_REPORT_FILE" << EOF
# Long 模式技术报告 - ${SESSION_NAME}

**生成时间**: ${TIMESTAMP}
**任务**: ${TASK}
**项目**: $PROJECT_NAME
**会话**: ${SESSION_NAME}

---

## 任务概述

${TASK}

---

## 执行计划

（待 Long 模式启动后更新）

---

## 关键进展

（待 Long 模式运行过程中更新）

---

## 测试结果

（待 Long 模式运行过程中更新）

---

## 输出文件清单

（待任务完成后更新）

---

## 总结与建议

（待任务完成后更新）

---

**状态**: 🔄 等待执行
**最后更新**: ${TIMESTAMP}
EOF

echo "   ✅ 技术报告模板已保存：${TECH_REPORT_FILE}"
echo ""

# ============================================================================
# 步骤 2: 创建 tmux 会话并启动子进程
# ============================================================================
echo "📋 步骤 2: 创建 tmux 会话并启动 Long 模式..."

# 生成任务缩写（取前 45 个字符，避免截断问题）
TASK_SHORT=$(echo "$TASK" | tr -d ' \t\n' | head -c 45)
WINDOW_NAME="long-${TASK_SHORT}"

# 创建日志文件（带时间戳，覆盖模式）
LOG_FILE="/home/wuyangcheng/.qwen/logs/${SESSION_NAME}_$(date +%Y%m%d_%H%M%S).log"
mkdir -p /home/wuyangcheng/.qwen/logs

# 创建进展汇报文件
PROGRESS_FILE="/home/wuyangcheng/.qwen/progress/${SESSION_NAME}.txt"
mkdir -p /home/wuyangcheng/.qwen/progress

# 初始化进展文件（覆盖模式）
{
    echo "# $SESSION_NAME Long 模式进展汇报"
    echo "任务：$TASK"
    echo "启动时间：$(date '+%Y-%m-%d %H:%M:%S')"
    echo "模式：Long（长时间自主运行）"
    echo "---"
} > "$PROGRESS_FILE"

# 初始化日志文件（覆盖模式，带时间戳）
{
    echo "# $SESSION_NAME Long 模式日志"
    echo "任务：$TASK"
    echo "启动时间：$(date '+%Y-%m-%d %H:%M:%S')"
    echo "---"
} > "$LOG_FILE"

# 创建新的 tmux 会话
tmux new-session -d -s "$SESSION_NAME" -n "$WINDOW_NAME"

# 切换到工作目录
tmux send-keys -t "$SESSION_NAME" "cd /home/wuyangcheng/code" Enter
sleep 0.5

# ============================================================================
# 📋 加载主进程总结和工作计划
# ============================================================================

# 获取主进程的 compress 总结（如果存在，加载全部内容）
COMPRESS_SUMMARY=""
COMPRESS_FILE="/home/wuyangcheng/.qwen/compress_summary.txt"
if [ -f "$COMPRESS_FILE" ]; then
    COMPRESS_SUMMARY=$(cat "$COMPRESS_FILE")
    echo "📋 已加载主进程总结：${COMPRESS_FILE}"
fi

# 获取最新的工作计划文件（优先查找包含 session 名称的计划）
WORKPLAN_CONTENT=""
LOADED_WORKPLAN_FILE=""

# 1. 优先查找包含 session 名称的工作计划
WORKPLAN_SEARCH=$(ls -t /home/wuyangcheng/code/*/workPlan/QWEN_workPlan_${SESSION_NAME}*.md 2>/dev/null | head -1)
if [ -z "$WORKPLAN_SEARCH" ]; then
    WORKPLAN_SEARCH=$(ls -t /home/wuyangcheng/code/QWEN_workPlan_${SESSION_NAME}*.md 2>/dev/null | head -1)
fi

# 读取工作计划内容
if [ -n "$WORKPLAN_SEARCH" ] && [ -f "$WORKPLAN_SEARCH" ]; then
    LOADED_WORKPLAN_FILE="$WORKPLAN_SEARCH"
    WORKPLAN_CONTENT=$(cat "$WORKPLAN_SEARCH")
    echo "📝 已加载工作计划：${LOADED_WORKPLAN_FILE}"
fi

# ============================================================================
# 构建完整的 system prompt
# ============================================================================

SYSTEM_PROMPT="【Long 模式 - 长时间自主运行】

请先加载你的全局设置（~/.qwen/settings.json），工作目录在 ~/code。

🔑 Long 模式权限：
- 你拥有最高权限，可以自主执行所有操作
- 在 YOLO 模式基础上，你可以自主决定运行长时间任务
- ⚠️ 但仍然严格禁止使用 rm、rmdir 等删除命令

🚫 重要：不要启动子进程
- 不要使用 'launch a sub-agent' 或类似委托方式
- 不要调用其他 agent 来执行任务
- 请直接执行任务，使用 shell 命令、Python 脚本等方式
- 所有操作在当前会话中直接完成

🔄 Long 模式自主运行规则：
1. 长时间任务使用 nohup 后台运行
   - 格式：nohup command > output.log 2>&1 &
   - 避免 shell 关闭导致进程被杀掉
2. 定期更新技术报告（使用中文）
   - 技术报告路径：$TECH_REPORT_FILE
   - 关键技术进展时必须立即更新
   - 包含：进展描述、测试数据、下一步计划
3. 脚本更新规范
   - 如果对之前脚本有较大更新，先备份原脚本
   - 备份命名：mv original.py original.py.bak
   - 然后创建新版本脚本，避免直接覆盖

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

# 创建临时文件存储 system prompt
SYSTEM_PROMPT_FILE="/home/wuyangcheng/.qwen/tmp_system_prompt_${SESSION_NAME}.txt"

# 直接写入已构造好的 SYSTEM_PROMPT 变量
echo "$SYSTEM_PROMPT" > "$SYSTEM_PROMPT_FILE"

# 添加项目信息和 Long 模式说明到 prompt 文件
cat >> "$SYSTEM_PROMPT_FILE" << EOF

📁 项目目录：$PROJECT_DIR
所有生成的文件应保存到该项目目录中。

📖 Long 模式技术报告：$TECH_REPORT_FILE
- 关键技术进展时必须更新此报告
- 使用中文撰写
- 包含：任务概述、关键进展、测试结果、输出文件清单、总结建议

#### 项目目录结构：
\`$PROJECT_DIR/\`
├── src/                    # 源代码文件
├── docs/                   # 文档和报告
├── results/                # 结果文件
├── configs/                # 配置文件
├── scripts/                # 脚本文件
├── workPlan/               # 工作计划
├── *.py.bak                # 备份的旧脚本
└── LONG_MODE_TECH_REPORT_*.md  # 技术报告

保存规则：
- 代码文件：\`$PROJECT_DIR/src/{task_name}.py\`
- 报告文档：\`$PROJECT_DIR/docs/{task_name}_report.md\`
- 结果文件：\`$PROJECT_DIR/results/{task_name}/\`
- 技术报告：\`$PROJECT_DIR/LONG_MODE_TECH_REPORT_{session_name}_{date}.md\`
- 备份脚本：\`$PROJECT_DIR/{original_script}.py.bak\`
EOF

echo "📝 System prompt 已保存到：$SYSTEM_PROMPT_FILE"

# ============================================================================
# 启动 qwen（空白启动，不传递 system prompt）
# ============================================================================

# 启动 qwen YOLO 模式，不传递 system prompt（避免截断问题）
tmux send-keys -t "$SESSION_NAME" "qwen -y" Enter

# 等待 qwen 完全启动
# qwen 需要加载模型、显示界面等，通常需要 5-10 秒
echo "   等待 qwen 启动..."
sleep 8

# 检查 qwen 是否已启动成功（通过捕获 pane 内容判断）
PANE_CONTENT=$(tmux capture-pane -t "$SESSION_NAME" -p -S -20 2>/dev/null)
if echo "$PANE_CONTENT" | grep -q "qwen\|YOLO\|Qwen Code"; then
    echo "   ✅ qwen 已启动成功"
else
    echo "   ⚠️  qwen 可能还未完全启动，再等待 5 秒..."
    sleep 5
fi

# ============================================================================
# 使用 tmux paste-buffer 方式可靠地发送任务指令
# ============================================================================

# 构建简短的任务指令，让模型读取准备好的文件
TASK_INSTRUCTION="请执行以下任务：$TASK

请先阅读以下文档然后开始执行：
- 工作计划：$WORKPLAN_FILE
- 主进程总结：$COMPRESS_FILE
- System Prompt：$SYSTEM_PROMPT_FILE
- 技术报告模板：$TECH_REPORT_FILE

开始执行任务。"

# 使用 paste-buffer 方法可靠地发送 prompt（3 步）
# 1. 设置缓冲区
tmux set-buffer "$TASK_INSTRUCTION"

# 2. 粘贴到会话
tmux paste-buffer -t "$SESSION_NAME"

# 3. 发送 Enter 提交
sleep 0.5
tmux send-keys -t "$SESSION_NAME" Enter

echo ""
echo "✅ Qwen (Long 模式 - YOLO) 已在后台启动"
echo "   会话名称：$SESSION_NAME"
echo "   窗口名称：$WINDOW_NAME"
echo "   任务：$TASK"
echo "   日志文件：$LOG_FILE"
echo "   进展文件：$PROGRESS_FILE"
echo "   技术报告：$TECH_REPORT_FILE"
echo ""
echo "🔑 Long 模式权限：最高权限自主运行（仍禁止 rm 等删除命令）"
echo ""
echo "📋 常用命令:"
echo "   查看进度：tmux attach -t $SESSION_NAME"
echo "   查看日志：tail -f $LOG_FILE"
echo "   查看进展：/home/wuyangcheng/.qwen/scripts/check-progress.sh $SESSION_NAME"
echo "   发送指令：/home/wuyangcheng/.qwen/scripts/send-to-sub.sh $SESSION_NAME \"新指令\""
echo "   分离会话：Ctrl+B, 然后按 D"
echo "   删除会话：tmux kill-session -t $SESSION_NAME"
echo ""

# ============================================================================
# 步骤 3: 启动后台监督脚本
# ============================================================================
echo "🔍 步骤 3: 启动 Long 模式监督脚本..."

# 3.1 启动定时监督脚本（定时汇报进展）
echo "   📊 启动定时进展监督脚本..."
LONG_SUPERVISOR="/home/wuyangcheng/.qwen/scripts/long-mode-supervisor.sh"
if [ -f "$LONG_SUPERVISOR" ]; then
    nohup bash "$LONG_SUPERVISOR" "$SESSION_NAME" 300 >> /home/wuyangcheng/.qwen/logs/long-supervisor.log 2>&1 &
    SUPERVISOR_PID=$!
    disown $SUPERVISOR_PID
    echo "      ✅ 定时监督脚本已启动（每 300 秒汇报一次）"
    echo "      监督 PID: $SUPERVISOR_PID"
    echo "      日志：/home/wuyangcheng/.qwen/logs/long-supervisor.log"
else
    echo "      ⚠️  监督脚本不存在：$LONG_SUPERVISOR"
fi

# 3.2 启动上下文监督脚本（监控上下文使用情况）
echo "   🧠 启动上下文监督脚本..."
LONG_CTX_MONITOR="/home/wuyangcheng/.qwen/scripts/long-context-monitor.sh"
if [ -f "$LONG_CTX_MONITOR" ]; then
    nohup bash "$LONG_CTX_MONITOR" "$SESSION_NAME" >> /home/wuyangcheng/.qwen/logs/long-ctx-monitor.log 2>&1 &
    CTX_MONITOR_PID=$!
    disown $CTX_MONITOR_PID
    echo "      ✅ 上下文监督脚本已启动"
    echo "      监控 PID: $CTX_MONITOR_PID"
    echo "      日志：/home/wuyangcheng/.qwen/logs/long-ctx-monitor.log"
else
    echo "      ⚠️  上下文监督脚本不存在：$LONG_CTX_MONITOR"
fi

# 启动状态监控（在后台定期检查并显示状态）
echo "📊 启动 Long 模式状态监控..."
(
    while true; do
        # 检查子进程是否还在运行
        if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
            # 会话已结束，显示最终状态
            echo ""
            echo "═══════════════════════════════════════════════════"
            echo "  Long 模式 $SESSION_NAME 已结束"
            echo "═══════════════════════════════════════════════════"
            echo ""
            /home/wuyangcheng/.qwen/scripts/check-sub-status.sh 2>/dev/null
            echo ""
            
            # 更新进展文件为最终状态
            if [ -f "$PROGRESS_FILE" ]; then
                {
                    echo ""
                    echo "## 任务完成"
                    echo "结束时间：$(date '+%Y-%m-%d %H:%M:%S')"
                    echo "状态：✅ 已完成"
                } >> "$PROGRESS_FILE"
            fi
            
            break
        fi

        # 每 60 秒显示一次状态
        sleep 60
        /home/wuyangcheng/.qwen/scripts/check-sub-status.sh "$SESSION_NAME" 2>/dev/null
    done
) &
STATUS_PID=$!
disown $STATUS_PID
echo "   状态监控 PID: $STATUS_PID"
echo ""

echo "═══════════════════════════════════════════════════"
echo "  Long 模式启动完成"
echo "═══════════════════════════════════════════════════"
echo ""
echo "📋 运行中的后台进程："
echo "   - Qwen Long 模式会话：$SESSION_NAME"
echo "   - 定时监督脚本：PID $SUPERVISOR_PID（每 300 秒汇报进展）"
echo "   - 上下文监督脚本：PID $CTX_MONITOR_PID（监控上下文使用）"
echo "   - 状态监控：PID $STATUS_PID（每 60 秒检查状态）"
echo ""
echo "📄 关键文件："
echo "   技术报告：$TECH_REPORT_FILE"
echo "   进展文件：$PROGRESS_FILE"
echo "   日志文件：$LOG_FILE"
echo "   工作计划：$WORKPLAN_FILE"
echo ""
echo "🔧 管理命令："
echo "   连接会话：tmux attach -t $SESSION_NAME"
echo "   发送指令：/home/wuyangcheng/.qwen/scripts/send-to-sub.sh $SESSION_NAME \"新指令\""
echo "   查看报告：cat $TECH_REPORT_FILE"
echo "   查看进展：cat $PROGRESS_FILE"
echo ""
