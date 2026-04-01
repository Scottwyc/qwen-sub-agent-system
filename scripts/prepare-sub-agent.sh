#!/bin/bash
# Qwen Code Sub/Auto Agent 准备脚本
# 功能：保存主进程总结并生成最新工作计划，然后启动子进程
# 用法：prepare-sub-agent.sh <sub|auto> <session-name> <task>

MODE="${1:-auto}"  # sub 或 auto
SESSION_NAME="${2:-qwen-${MODE}-task}"
shift 2
TASK="$*"

if [ -z "$TASK" ]; then
    echo "用法：$0 <sub|auto> <session-name> <task>"
    echo "示例：$0 auto qwen-auto-task '使用参数 n=50, k=4, p=0.01 生成 100 种子数据集并训练 scorer'"
    exit 1
fi

echo "═══════════════════════════════════════════════════"
echo "  Qwen Code ${MODE^^} Agent 启动准备"
echo "═══════════════════════════════════════════════════"
echo ""

# 步骤 1: 保存主进程 compress 总结
echo "📋 步骤 1: 保存主进程会话总结..."
COMPRESS_FILE="/home/wuyangcheng/.qwen/compress_summary.txt"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

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
fi

cat > "$COMPRESS_FILE" << EOF
# 主进程会话总结
生成时间：${TIMESTAMP}
任务：${TASK}

## 当前上下文
- 工作目录：$PROJECT_DIR
- 项目名称：$PROJECT_NAME
- 会话模式：${MODE}
- 子进程会话：${SESSION_NAME}

## 最近活动
- 用户请求：${TASK}
- 启动时间：${TIMESTAMP}

## 注意事项
- 子进程将继承此上下文继续执行任务
- 所有生成的文件应保存到 $PROJECT_DIR 目录
- 进展汇报写入：/home/wuyangcheng/.qwen/progress/${SESSION_NAME}.txt
EOF

echo "   ✅ 总结已保存：${COMPRESS_FILE}"
echo ""

# 步骤 2: 生成最新工作计划
echo "📝 步骤 2: 生成工作计划..."

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
fi

# 工作计划目录
WORKPLAN_DIR="$PROJECT_DIR/workPlan"
WORKPLAN_FILE="${WORKPLAN_DIR}/QWEN_workPlan_${SESSION_NAME}_$(date +%Y%m%d_%H%M%S).md"

# 创建工作计划目录
mkdir -p "$WORKPLAN_DIR"

cat > "$WORKPLAN_FILE" << EOF
# ${SESSION_NAME} 工作计划

**生成时间**: ${TIMESTAMP}
**任务**: ${TASK}
**项目**: $PROJECT_NAME ($PROJECT_DIR)

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

# 步骤 3: 启动对应的子进程
echo "🚀 步骤 3: 启动 ${MODE} agent..."

if [ "$MODE" == "auto" ]; then
    SCRIPT="/home/wuyangcheng/.qwen/scripts/tmux-auto-agent.sh"
else
    SCRIPT="/home/wuyangcheng/.qwen/scripts/tmux-sub-agent.sh"
fi

# 构建完整的任务描述（包含工作计划路径）
FULL_TASK="${TASK}

📋 相关文档:
- 工作计划：${WORKPLAN_FILE}
- 主进程总结：${COMPRESS_FILE}

请先阅读上述文档，然后开始执行任务。"

bash "$SCRIPT" "$SESSION_NAME" "$FULL_TASK"

echo ""
echo "═══════════════════════════════════════════════════"
echo "  启动完成"
echo "═══════════════════════════════════════════════════"
echo ""
echo "📊 会话信息:"
echo "   会话名称：${SESSION_NAME}"
echo "   任务：${TASK}"
echo "   工作计划：${WORKPLAN_FILE}"
echo "   主进程总结：${COMPRESS_FILE}"
echo ""
echo "📋 常用命令:"
echo "   查看进度：tmux attach -t ${SESSION_NAME}"
echo "   查看日志：tail -f /home/wuyangcheng/.qwen/logs/${SESSION_NAME}_*.log"
echo "   查看进展：bash /home/wuyangcheng/.qwen/scripts/check-progress.sh ${SESSION_NAME}"
echo "   发送指令：bash /home/wuyangcheng/.qwen/scripts/send-to-sub.sh ${SESSION_NAME} '<prompt>'"
echo ""
