# Qwen Code Sub/Auto Agent 技能文档

> Sub Agent 和 Auto Agent 完整配置指南

## 📋 概述

Sub/Auto Agent 系统允许主进程在 tmux 中启动后台子进程执行任务，同时主进程可以继续与用户交流其他话题。监视器会自动监督子进程状态，并在任务完成时发送通知。

---

## 🎯 核心特性

| 特性 | 说明 |
|------|------|
| **tmux 后台运行** | 子进程在 tmux 会话中运行，不阻塞主进程 |
| **YOLO 模式** | 自动批准所有操作，无需确认 |
| **进展汇报** | 关键节点自动写入进展文件 |
| **安全限制** | 严格禁止使用 rm 等删除命令 |
| **Compress 总结** | 自动加载主进程会话总结 |
| **工作计划** | 自动查看最新工作计划文件 |
| **禁止后台命令** | 子进程中不要使用 'in the background' 方式运行命令 |
| **Scorer-Searcher 约定** | scorer 相关任务保存到 /home/wuyangcheng/code/scorer-searcher/ |

---

## 🚀 推荐工作流程（重要！）

### 完整启动流程

**步骤 1: 准备并启动子进程**（推荐）

使用 `prepare-sub-agent.sh` 脚本，自动完成：
1. 保存主进程 compress 总结
2. 生成最新工作计划
3. 启动子进程并加载上述文档

```bash
# Auto Agent 示例
bash /home/wuyangcheng/.qwen/scripts/prepare-sub-agent.sh auto qwen-auto-task "任务描述"

# Sub Agent 示例
bash /home/wuyangcheng/.qwen/scripts/prepare-sub-agent.sh sub qwen-sub-task "任务描述"
```

**步骤 2: 子进程自动加载上下文**

子进程启动时会自动读取：
- `/home/wuyangcheng/.qwen/compress_summary.txt` - 主进程总结
- `/home/wuyangcheng/code/QWEN_workPlan_<session>*.md` - 工作计划

**步骤 3: 监控和交互**

```bash
# 查看进展
bash /home/wuyangcheng/.qwen/scripts/check-progress.sh <session-name>

# 发送指令
bash /home/wuyangcheng/.qwen/scripts/send-to-sub.sh <session-name> "新指令"
```

---

## 🔧 配置位置

**全局设置**: `~/.qwen/settings.json`

```json
{
  "agent": {
    "autonomousMode": {
      "enabled": true,
      "triggerCommand": "auto",
      "tmuxMode": {
        "enabled": true,
        "sessionPrefix": "qwen-auto",
        "script": "/home/wuyangcheng/.qwen/scripts/tmux-auto-agent.sh",
        "systemPromptTemplate": "请先加载你的全局设置（~/.qwen/settings.json），工作目录在 ~/code，请查看你最新的工作计划。⚠️ 安全限制：禁止使用 rm、rmdir 等删除命令。📊 进展汇报：关键进展请写入 /home/wuyangcheng/.qwen/progress/{session_name}.txt",
        "includeCompressSummary": true,
        "compressSummaryFile": "/home/wuyangcheng/.qwen/compress_summary.txt"
      }
    },
    "subAgent": {
      "triggerCommand": "sub",
      "tmuxMode": {
        "enabled": true,
        "sessionPrefix": "qwen-sub",
        "script": "/home/wuyangcheng/.qwen/scripts/tmux-sub-agent.sh",
        "systemPromptTemplate": "请先加载你的全局设置（~/.qwen/settings.json），工作目录在 ~/code，请查看你最新的工作计划。⚠️ 安全限制：禁止使用 rm、rmdir 等删除命令。📊 进展汇报：关键进展请写入 /home/wuyangcheng/.qwen/progress/{session_name}.txt",
        "includeCompressSummary": true,
        "compressSummaryFile": "/home/wuyangcheng/.qwen/compress_summary.txt"
      }
    }
  }
}
```

---

## 📂 脚本文件

| 脚本 | 路径 | 功能 |
|------|------|------|
| **prepare-sub-agent.sh** | `/home/wuyangcheng/.qwen/scripts/prepare-sub-agent.sh` | 📋 准备并启动子进程（独立运行） |
| **tmux-sub-agent.sh** | `/home/wuyangcheng/.qwen/scripts/tmux-sub-agent.sh` | 🔄 启动 Sub Agent（自动先执行 prepare） |
| **tmux-auto-agent.sh** | `/home/wuyangcheng/.qwen/scripts/tmux-auto-agent.sh` | 🔄 启动 Auto Agent（自动先执行 prepare） |
| **check-progress.sh** | `/home/wuyangcheng/.qwen/scripts/check-progress.sh` | 查看进展汇报 |
| **monitor-sub-agents.sh** | `/home/wuyangcheng/.qwen/scripts/monitor-sub-agents.sh` | 监控子进程 |
| **send-to-sub.sh** | `/home/wuyangcheng/.qwen/scripts/send-to-sub.sh` | 发送命令到子进程 |
| **control-sub.sh** | `/home/wuyangcheng/.qwen/scripts/control-sub.sh` | 交互式控制器 |
| **save-compress-summary.sh** | `/home/wuyangcheng/.qwen/scripts/save-compress-summary.sh` | 保存 compress 总结 | |

---

## 🚀 快速启动

### 方式 1: 使用 prepare-sub-agent.sh（独立运行）

```bash
# Auto Agent - 完整流程
bash /home/wuyangcheng/.qwen/scripts/prepare-sub-agent.sh auto qwen-auto-mytask "任务描述"

# Sub Agent - 完整流程
bash /home/wuyangcheng/.qwen/scripts/prepare-sub-agent.sh sub qwen-sub-mytask "任务描述"
```

此方式会自动：
1. 保存主进程 compress 总结到 `/home/wuyangcheng/.qwen/compress_summary.txt`
2. 生成工作计划到 `/home/wuyangcheng/code/QWEN_workPlan_<session>*.md`
3. 启动子进程并自动加载上述文档

### 方式 2: 直接使用 sub/auto 命令（推荐）

```bash
# Auto Agent - 自动先执行 prepare 流程
bash /home/wuyangcheng/.qwen/scripts/tmux-auto-agent.sh qwen-auto-mytask "任务描述"

# Sub Agent - 自动先执行 prepare 流程
bash /home/wuyangcheng/.qwen/scripts/tmux-sub-agent.sh qwen-sub-mytask "任务描述"
```

**说明**: `tmux-auto-agent.sh` 和 `tmux-sub-agent.sh` 已更新为：
1. **首先** 调用 prepare 流程保存主进程总结和工作计划
2. **然后** 继续原来的流程，加载这些文档到子进程 prompt 中
3. 子进程执行任务并定期汇报进展

### 方式 3: 自然语言触发（最方便）

在主进程中直接使用自然语言：

```
auto 使用参数 n=50, k=4, p=0.01 生成 100 种子数据集并训练 scorer
```

或

```
sub 分析当前项目的代码结构
```

**注意**: 这需要主进程配置支持自然语言触发子进程。

### 查看进展

```bash
# 查看所有子进程进展
~/.qwen/scripts/check-progress.sh

# 查看特定会话进展
~/.qwen/scripts/check-progress.sh qwen-sub

# 持续监控（每 10 秒更新）
~/.qwen/scripts/monitor-sub-agents.sh --watch

# 直接查看文件
tail -f /home/wuyangcheng/.qwen/progress/qwen-sub.txt
```

### 发送命令到子进程

**唯一方式**：使用 `send-to-sub.sh` 发送 prompt

```bash
# 语法
~/.qwen/scripts/send-to-sub.sh <session-name> <prompt-text>

# 示例
# 发送分析指令
~/.qwen/scripts/send-to-sub.sh qwen-sub 请分析刚才生成的代码

# 发送总结指令
~/.qwen/scripts/send-to-sub.sh qwen-sub 请总结一下当前的发现

# 发送停止指令
~/.qwen/scripts/send-to-sub.sh qwen-sub 请停止当前操作，打印'任务完成'
```

**原理**：使用 tmux paste-buffer 方法可靠地发送文本到 TUI 界面

```bash
# 内部实现（3 步）
tmux set-buffer "$PROMPT_TEXT"           # 1. 设置缓冲区
tmux paste-buffer -t "$SESSION_NAME"     # 2. 粘贴到会话
sleep 0.5
tmux send-keys -t "$SESSION_NAME" C-m    # 3. 发送 Enter 提交
```

**⚠️ 重要**：向 Qwen Code TUI 发送消息必须使用 paste-buffer 方式！

直接使用 `tmux send-keys "$TEXT" Enter` 或 `tmux send-keys "$TEXT" C-m` 对 Qwen Code TUI 不工作，
因为 Qwen Code 使用的是交互式 TUI 界面，不是普通 shell。

**启动脚本中的正确做法**（tmux-auto-agent.sh 和 tmux-sub-agent.sh）：

```bash
# 1. 空白启动 qwen（不传递 system prompt，避免截断问题）
tmux send-keys -t "$SESSION_NAME" "qwen -y" Enter
sleep 3

# 2. 构建任务指令
TASK_INSTRUCTION="请执行以下任务：

$TASK

相关文档：
- 工作计划：$WORKPLAN_FILE
- 主进程总结：$COMPRESS_FILE

请先阅读上述文档，然后开始执行任务。"

# 3. 使用 paste-buffer 方法可靠地发送 prompt（3 步）
tmux set-buffer "$TASK_INSTRUCTION"        # 1. 设置缓冲区
tmux paste-buffer -t "$SESSION_NAME"       # 2. 粘贴到会话
sleep 0.5
tmux send-keys -t "$SESSION_NAME" C-m      # 3. 发送 Enter 提交
```

### 监督子进程状态

**智能监督器**（推荐）：

```bash
# 启动智能监督器
~/.qwen/scripts/smart-watch-sub.sh

# 自动继续模式（检测到等待时自动发送"继续执行"）
~/.qwen/scripts/smart-watch-sub.sh --auto-continue

# 自定义继续 prompt
~/.qwen/scripts/smart-watch-sub.sh --auto-continue --prompt "请继续"

# 自定义刷新间隔
~/.qwen/scripts/smart-watch-sub.sh --interval 5
```

**自动监督器**（后台运行）：

```bash
# 后台监督，提醒写入文件
~/.qwen/scripts/auto-watch-sub.sh 10

# 查看提醒
cat /home/wuyangcheng/.qwen/sub_alerts.txt
```

**完整监督器**（交互式）：

```bash
# 启动完整监督器
~/.qwen/scripts/watch-sub-agents.sh
```

### 监督器功能

| 功能 | 说明 |
|------|------|
| **自动检测** | 检测子进程是否等待输入（输入框为空） |
| **提醒通知** | 发现等待时显示提醒和最后输出 |
| **自动继续** | 可选择自动发送"继续执行"prompt |
| **快速连接** | 一键连接到等待的会话 |
| **避免重复** | 同一会话只提醒一次 |

---

## 📊 System Prompt 结构

子进程启动时，system prompt 包含以下内容：

```
请先加载你的全局设置（~/.qwen/settings.json），工作目录在 ~/code。

⚠️ 安全限制：禁止使用 rm、rmdir 等删除命令。

🚫 重要：不要启动子进程
- 不要使用 'launch a sub-agent' 或类似委托方式
- 不要调用其他 agent 来执行任务
- 请直接执行任务，使用 shell 命令、Python 脚本等方式
- 所有操作在当前会话中直接完成

📊 进展汇报要求：
关键进展请写入 /home/wuyangcheng/.qwen/progress/{session_name}.txt（覆盖模式，不是追加）

写入时机：
- 任务开始：说明理解和计划
- 完成关键步骤：总结当前进展
- 遇到问题：记录问题和解决方案
- 任务完成：总结成果和输出文件

写入格式（覆盖写入，使用 > 重定向）：
  echo "# {session_name} 进展汇报" > /home/wuyangcheng/.qwen/progress/{session_name}.txt
  echo "更新时间：$(date '+%Y-%m-%d %H:%M:%S')" >> ...
  echo "状态：🔄 执行中 / ⏳ 等待输入 / ✅ 已完成" >> ...
  echo "---" >> ...
  echo "## 当前进展" >> ...
  echo "已完成：..." >> ...
  echo "进行中：..." >> ...
  echo "下一步：..." >> ...

📋 最新工作计划：
[完整的 QWEN_workPlan_*.md 内容，如果存在]

📝 主进程会话总结（compress summary）：
[完整的 compress_summary.txt 内容，如果存在]
```

### 工作计划文件命名约定

为便于子进程自动加载，工作计划文件使用以下命名格式：

```
/home/wuyangcheng/code/QWEN_workPlan_<session-name>_<timestamp>.md
```

例如：
- `QWEN_workPlan_qwen-auto-scorer-100_20260401_054500.md`
- `QWEN_workPlan_qwen-sub-analysis_20260401_120000.md`

子进程会优先加载与 session 名称匹配的工作计划文件。

### ⚠️ 重要说明

**子进程内禁止再启动子进程**：
- sub/auto agent 被设计为**直接执行任务**
- 使用 shell 命令、Python 脚本等方式直接运行
- 不要委托给其他 agent 或启动新的子进程
- 这样便于统一管理和监控

---

## ⚠️ 安全限制

### 禁止的命令

| 命令 | 说明 | 风险等级 |
|------|------|----------|
| `rm` | 删除文件 | 🔴 严禁 |
| `rm -f` | 强制删除 | 🔴 严禁 |
| `rm -r` | 递归删除目录 | 🔴 严禁 |
| `rm -rf` | 强制递归删除 | 🔴 严禁 |
| `rmdir` | 删除空目录 | 🔴 严禁 |
| `unlink` | 删除文件/链接 | 🔴 严禁 |
| `shred` | 安全删除文件 | 🔴 严禁 |

### 替代方案

| 需求 | 安全替代方案 |
|------|-------------|
| 清理临时文件 | `mv file.txt /tmp/old/` |
| 整理文件 | `mv file.txt archive/` |
| 重命名文件 | `mv old.txt new.txt` |
| 备份后替换 | `cp file.txt file.txt.bak` |

---

## 📝 进展汇报机制

### 汇报文件位置

```
/home/wuyangcheng/.qwen/progress/<session-name>.txt
```

### 文件输出责任分工

| 文件 | 路径 | 写入者 | 更新方式 | 内容 |
|------|------|--------|----------|------|
| **日志文件** | `logs/{session}_{timestamp}.log` | **监视器** | 每 5 秒**覆盖** | 最新 100 行 tmux 输出 |
| **进展文件** | `progress/{session}.txt` | **子进程** | 关键节点**覆盖** | 结构化进展汇报 |
| **通知记录** | `sub_alerts.txt` | **监视器** | 追加 | 任务完成通知 |
| **状态跟踪** | `sub_state.json` | **监视器** | 更新 | 已通知会话标记 |

### 子进程进展汇报

**写入时机**：
- ✅ **任务开始**：说明理解和计划
- ✅ **完成关键步骤**：总结当前进展
- ✅ **遇到问题**：记录问题和解决方案
- ✅ **任务完成**：总结成果和输出文件

**写入格式**（覆盖写入，使用 `>` 重定向）：
```bash
echo "# ${SESSION_NAME} 进展汇报" > /home/wuyangcheng/.qwen/progress/${SESSION_NAME}.txt
echo "更新时间：$(date '+%Y-%m-%d %H:%M:%S')" >> /home/wuyangcheng/.qwen/progress/${SESSION_NAME}.txt
echo "状态：🔄 执行中 / ⏳ 等待输入 / ✅ 已完成" >> /home/wuyangcheng/.qwen/progress/${SESSION_NAME}.txt
echo "---" >> /home/wuyangcheng/.qwen/progress/${SESSION_NAME}.txt
echo "## 当前进展" >> /home/wuyangcheng/.qwen/progress/${SESSION_NAME}.txt
echo "已完成：..." >> /home/wuyangcheng/.qwen/progress/${SESSION_NAME}.txt
echo "进行中：..." >> /home/wuyangcheng/.qwen/progress/${SESSION_NAME}.txt
echo "下一步：..." >> /home/wuyangcheng/.qwen/progress/${SESSION_NAME}.txt
```

**示例进展文件**：
```markdown
# qwen-auto-f1full 进展汇报
更新时间：2026-04-01 05:00:00
状态：🔄 执行中
---
## 当前进展
已完成：
- F1 全范围数据生成器实现
- 20 种子数据集生成（F1 0-1 全范围）

进行中：
- Scorer V2 模型训练

下一步：
- 验证集评估
- 测试集测试
- 生成完整报告
```

### 监视器日志更新

**日志文件** (`logs/{session}_{timestamp}.log`) 由监视器每 5 秒**覆盖更新**：

```bash
# 监视器内部逻辑
latest_output=$(tmux capture-pane -p -t "$session" -S -100 | tail -100)
{
    echo "# ${session} 日志"
    echo "更新时间：${timestamp}"
    echo "---"
    echo "$latest_output"
} > "$log_file"  # 覆盖写入
```

**特点**：
- 只保留最新 100 行输出
- 文件大小保持 ~5-10KB
- 不会无限增长

### 关键进展节点

| 节点 | 说明 | 示例 |
|------|------|------|
| `task_start` | 任务开始，说明理解和计划 | "已开始任务，将搜索 GAN 架构资料" |
| `search_complete` | 搜索/资料收集完成 | "已收集 10 篇 GAN 相关论文" |
| `analysis_complete` | 分析完成 | "已完成核心架构分析" |
| `code_complete` | 代码生成完成 | "已生成 20 个 PyTorch 代码示例" |
| `task_complete` | 任务完成，总结成果 | "任务完成，报告已保存" |

---

## 🔌 Compress 总结集成

### 保存主进程总结

**方式 1: 使用准备脚本（推荐）**

```bash
bash /home/wuyangcheng/.qwen/scripts/prepare-sub-agent.sh auto qwen-auto-task "任务描述"
```

此脚本会自动保存主进程总结并生成工作计划。

**方式 2: 手动保存**

```bash
# 方法 1: 直接传入文本
~/.qwen/scripts/save-compress-summary.sh "这是 compress 总结内容"

# 方法 2: 从管道读取
echo "总结内容" | ~/.qwen/scripts/save-compress-summary.sh

# 方法 3: 手动保存到文件
cat > /home/wuyangcheng/.qwen/compress_summary.txt << 'EOF'
# 主进程会话总结
生成时间：2026-04-01 12:00:00

## 当前上下文
- 工作目录：/home/wuyangcheng/code
- 会话模式：auto
- 子进程会话：qwen-auto-task

## 最近活动
- 用户请求：任务描述
- 启动时间：2026-04-01 12:00:00

## 注意事项
- 子进程将继承此上下文继续执行任务
- 所有生成的文件应保存到 ~/code/ 目录
EOF
```

### 自动加载

子进程启动时自动读取 `/home/wuyangcheng/.qwen/compress_summary.txt` 全部内容，并添加到 system prompt 中。

### 工作计划生成

工作计划文件由 `prepare-sub-agent.sh` 自动生成，包含：
- 任务目标和执行要求
- 参数设置说明
- 文件组织规范
- 进展汇报要求
- 安全限制
- 输出要求（代码、报告、可视化）

---

## 📡 消息通知系统

### 通知配置
| 配置项 | 值 | 说明 |
|--------|-----|------|
| 监视器脚本 | `/home/wuyangcheng/.qwen/scripts/auto-watch-sub.sh` | 后台监督子进程 |
| 刷新间隔 | 5 秒 | 检查子进程状态的频率 |
| 通知持续时间 | 3000ms (3 秒) | tmux 状态行消息显示时长 |
| 状态文件 | `/home/wuyangcheng/.qwen/sub_status.txt` | 实时子进程状态 |
| 警报文件 | `/home/wuyangcheng/.qwen/sub_alerts.txt` | 通知记录 |
| 状态跟踪 | `/home/wuyangcheng/.qwen/sub_state.json` | 已通知会话跟踪 |

### 子进程状态

| 状态 | 说明 | 检测条件 |
|------|------|----------|
| 🔄 **运行中** | 任务正在执行 | 最后 15 行包含 `esc to cancel` |
| ⏳ **等待用户选择** | 等待用户选择选项 | 最后 30 行有数字选项（`1. ` `2. ` `3. `），且无 `esc to cancel` |
| ❓ **未知** | 其他状态 | 不满足以上条件 |

### 通知触发条件

**检测逻辑**：

```bash
# 1. 检查任务是否进行中（最后 15 行）
if tail -15 "$log_file" | grep -q "esc to cancel"; then
    status="🔄 运行中"
# 2. 检查是否等待用户选择（最后 30 行有数字选项）
elif tail -30 "$log_file" | grep -qE "^[[:space:]]*[0-9]+[.、] "; then
    status="⏳ 等待用户选择"
    # 发送通知
else
    status="❓ 未知"
fi
```

**通知时机**：
- 当状态从 **🔄 运行中** 变为 **⏳ 等待用户选择** 时
- 每个会话只通知一次（避免重复）

### 通知格式
```
tmux 状态行消息（黄色，加粗，持续 3 秒）：
⚠️  {session_name} 任务完成，等待输入!
```

### 查看通知
```bash
# 查看警报历史
cat /home/wuyangcheng/.qwen/sub_alerts.txt

# 查看实时状态
bash /home/wuyangcheng/.qwen/scripts/check-sub-status.sh

# 查看状态跟踪
cat /home/wuyangcheng/.qwen/sub_state.json
```

---

## 🛠️ 管理命令

### 状态检查
```bash
# 查看所有子进程状态
bash /home/wuyangcheng/.qwen/scripts/check-sub-status.sh

# 查看特定会话状态
bash /home/wuyangcheng/.qwen/scripts/check-sub-status.sh qwen-sub-task
```

### 会话管理
```bash
# 连接到子进程会话
tmux attach -t qwen-sub-task

# 查看子进程日志
tail -f /home/wuyangcheng/.qwen/logs/qwen-sub-task_20260401_120000.log

# 查看进展文件
cat /home/wuyangcheng/.qwen/progress/qwen-sub-task.txt

# 删除会话
tmux kill-session -t qwen-sub-task
```

### 监视器管理
```bash
# 启动监视器
nohup bash /home/wuyangcheng/.qwen/scripts/auto-watch-sub.sh 5 >> /home/wuyangcheng/.qwen/logs/watcher.log 2>&1 &

# 停止监视器
pkill -f "auto-watch-sub.sh"

# 查看监视器状态
ps aux | grep "auto-watch-sub"

# 查看监视器日志
tail -f /home/wuyangcheng/.qwen/logs/watcher.log
```

### 清理命令
```bash
# 清理所有已完成的子进程会话
for session in $(cat /home/wuyangcheng/.qwen/sub_state.json | grep -o '"qwen-sub[^"]*"' | tr -d '"'); do
    tmux kill-session -t "$session" 2>/dev/null
done

# 重置状态文件
echo "{}" > /home/wuyangcheng/.qwen/sub_state.json

# 清空警报文件
> /home/wuyangcheng/.qwen/sub_alerts.txt
```

---

## 📂 文件结构

```
/home/wuyangcheng/.qwen/
├── scripts/
│   ├── tmux-sub-agent.sh          # Sub Agent 启动脚本
│   ├── tmux-auto-agent.sh         # Auto Agent 启动脚本
│   ├── auto-watch-sub.sh          # 子进程监视器
│   ├── check-sub-status.sh        # 状态检查脚本
│   ├── send-notification.sh       # 通知发送脚本
│   └── ...
├── logs/
│   ├── qwen-sub-*.log             # Sub Agent 日志
│   ├── qwen-auto-*.log            # Auto Agent 日志
│   └── watcher.log                # 监视器日志
├── progress/
│   ├── qwen-sub-*.txt             # Sub Agent 进展文件
│   └── qwen-auto-*.txt            # Auto Agent 进展文件
├── sub_status.txt                 # 实时状态文件
├── sub_alerts.txt                 # 警报通知记录
├── sub_state.json                 # 状态跟踪（已通知会话）
└── settings.json                  # 全局配置
```

---

## ⚙️ 全局设置

### settings.json 配置
```json
{
  "agent": {
    "subAgentNotification": {
      "enabled": true,
      "watcherScript": "/home/wuyangcheng/.qwen/scripts/auto-watch-sub.sh",
      "statusFile": "/home/wuyangcheng/.qwen/sub_status.txt",
      "alertsFile": "/home/wuyangcheng/.qwen/sub_alerts.txt",
      "stateFile": "/home/wuyangcheng/.qwen/sub_state.json",
      "logDir": "/home/wuyangcheng/.qwen/logs",
      "progressDir": "/home/wuyangcheng/.qwen/progress",
      "refreshInterval": 5,
      "notificationDuration": 3000,
      "detectionLogic": {
        "taskInProgress": "最后 10 行包含 'esc to cancel'",
        "waitingForInput": "最后 10 行包含 'Type your message' 或 'YOLO mode'",
        "taskCompleted": "不在进行中 且 在等待输入"
      },
      "notificationMethod": "tmux display-message 状态行消息（黄色，持续 3 秒）",
      "notificationFormat": "⚠️  {session} 任务完成，等待输入!"
    },
    "subAgent": {
      "triggerCommand": "sub",
      "inheritFullPermissions": true,
      "backgroundMode": true,
      "silentBackgroundMode": false,
      "progressReporting": {
        "enabled": true,
        "method": "file",
        "progressDir": "/home/wuyangcheng/.qwen/progress",
        "reportOnMilestone": false,
        "notifyMainProcessOnComplete": true
      }
    },
    "autonomousMode": {
      "triggerCommand": "auto",
      "backgroundMode": true,
      "progressReporting": {
        "notifyMainProcessOnComplete": true
      }
    }
  }
}
```

---

## 🔄 工作流程

```
用户启动任务
    ↓
主进程执行启动脚本 (tmux-sub-agent.sh)
    ↓
创建 tmux 会话并启动子进程
    ↓
启动监视器 (auto-watch-sub.sh) 后台运行
    ↓
主进程继续与用户交流其他话题 ←→ 监视器每 5 秒检查状态
    ↓                                    ↓
子进程执行任务                    检测到最后 10 行无 "esc to cancel"
    ↓                               且最后 10 行有 "Type your message"
任务完成，等待输入                        ↓
    ↓                            发送 tmux 状态行通知
状态保持等待输入                       (黄色，持续 3 秒)
    ↓                            写入警报文件
主进程收到通知                        更新状态跟踪文件
    ↓
用户查看结果或继续新任务
```

---

## 📊 状态说明

### 子进程状态
| 状态 | 说明 | 检测条件 |
|------|------|----------|
| 🔄 运行中 | 任务正在执行 | 最后 10 行包含 `esc to cancel` |
| ⏳ 等待输入 | 等待用户输入 | 最后 10 行包含 `Type your message` 等 |
| ✅ 已完成 | 任务完成且已通知 | 状态文件中标记为 `true` |

### 通知状态
| 文件 | 内容 | 更新时机 |
|------|------|----------|
| `sub_alerts.txt` | 通知历史记录 | 每次检测到任务完成 |
| `sub_state.json` | 已通知会话跟踪 | 发送通知后标记 |
| `watcher.log` | 监视器运行日志 | 每次循环 |

---

## ⚠️ 注意事项

1. **安全限制**: 子进程禁止使用 `rm`、`rmdir` 等删除命令
2. **会话命名**: 建议使用 `qwen-sub-<任务>` 或 `qwen-auto-<任务>` 格式
3. **日志管理**: 定期清理旧的日志文件避免占用过多空间
4. **监视器**: 确保监视器在后台运行，否则不会收到通知
5. **状态重置**: 清理会话后记得重置状态文件和警报文件

---

## 🐛 故障排除

### 问题：收不到通知
**检查步骤：**
1. 确认监视器在运行：`ps aux | grep "auto-watch-sub"`
2. 检查日志文件是否有内容
3. 确认状态文件未被锁定
4. 检查 tmux 会话名称是否正确

### 问题：通知重复发送
**解决方案：**
- 检查 `sub_state.json` 是否正确更新
- 重置状态文件：`echo "{}" > /home/wuyangcheng/.qwen/sub_state.json`

### 问题：子进程卡住
**解决方案：**
1. 查看日志：`tail -f /home/wuyangcheng/.qwen/logs/qwen-sub-*.log`
2. 连接会话：`tmux attach -t qwen-sub-task`
3. 必要时删除会话：`tmux kill-session -t qwen-sub-task`

---

## 📝 使用示例

### 示例 0: 完整流程（推荐）

```bash
# 步骤 1: 准备并启动 auto agent（带参数说明）
bash /home/wuyangcheng/.qwen/scripts/prepare-sub-agent.sh auto qwen-auto-scorer-100 \
  "使用参数 n=50, k=4, p=0.01 生成 100 种子数据集并训练 scorer"

# 步骤 2: 查看生成的文档
cat /home/wuyangcheng/.qwen/compress_summary.txt
cat /home/wuyangcheng/code/QWEN_workPlan_qwen-auto-scorer-100_*.md

# 步骤 3: 监控进展
bash /home/wuyangcheng/.qwen/scripts/check-progress.sh qwen-auto-scorer-100

# 步骤 4: 任务完成后查看结果
ls -la /home/wuyangcheng/code/result/
```

### 示例 1：查找质数
```bash
# 启动任务
bash /home/wuyangcheng/.qwen/scripts/tmux-sub-agent.sh qwen-sub-prime "找到 1000 以内的所有质数"

# 等待通知（约 5-10 秒）
# 收到通知：⚠️  qwen-sub-prime 任务完成，等待输入!

# 查看结果
cat /home/wuyangcheng/primes_under_1000.txt

# 清理会话
tmux kill-session -t qwen-sub-prime
```

### 示例 2：搜索 AI 新闻
```bash
# 启动任务
bash /home/wuyangcheng/.qwen/scripts/tmux-sub-agent.sh qwen-sub-ainews "搜索最新的 AI 新闻，整理成报告"

# 主进程继续其他工作...

# 等待通知
# 收到通知后查看报告
cat /home/wuyangcheng/ai_news_report.md
```

---

## 🎯 使用场景

### 场景 1: 代码分析任务

```bash
# 启动子进程分析代码
~/.qwen/scripts/tmux-sub-agent.sh qwen-sub "分析 MultiReconstruct_support2.py 模块的功能和依赖"

# 查看进展
~/.qwen/scripts/check-progress.sh qwen-sub

# 发送新指令
~/.qwen/scripts/control-sub.sh qwen-sub
[qwen-sub] > 请生成一份详细的使用文档
[qwen-sub] > x
```

### 场景 2: 长时间运行任务

```bash
# 启动 auto agent 进行优化
~/.qwen/scripts/tmux-auto-agent.sh qwen-auto "优化 diffusion 实验参数配置"

# 持续监控
~/.qwen/scripts/monitor-sub-agents.sh --watch

# 暂停并给出新指令
~/.qwen/scripts/send-to-sub.sh qwen-auto pause
~/.qwen/scripts/send-to-sub.sh qwen-auto prompt 请同时测试不同的学习率
```

### 场景 3: 多任务并行

```bash
# 同时运行多个独立任务
~/.qwen/scripts/tmux-sub-agent.sh qwen-sub-1 "测试模块 A"
~/.qwen/scripts/tmux-sub-agent.sh qwen-sub-2 "测试模块 B"
~/.qwen/scripts/tmux-auto-agent.sh qwen-auto-1 "优化实验流程"

# 查看所有任务状态
tmux list-sessions | grep qwen

# 切换到特定任务
tmux attach -t qwen-sub-1
```

---

## ✅ 检查清单

### 启动子进程前确认

**使用准备脚本时**（推荐）：
- [ ] 确认任务描述清晰完整
- [ ] 如有参数要求，在任务描述中明确说明（如 n=50, k=4, p=0.01）
- [ ] 了解安全限制（禁止 rm 等命令）

**直接启动时**：
- [ ] 已保存主进程 compress 总结（如需要）
- [ ] 已生成最新工作计划（如需要）
- [ ] 已确认工作目录和最新工作计划
- [ ] 了解安全限制（禁止 rm 等命令）

### 任务完成后确认

- [ ] 任务目标已达成
- [ ] 代码/报告已保存到 ~/code/
- [ ] 进展文件已更新最终状态
- [ ] 已告知用户生成的文件路径（使用绝对路径）
- [ ] 可视化和文档中明确说明了参数设置（如适用）

---

## 🧪 测试验证

### 简单测试任务

使用简单任务验证子进程是否正常工作：

```bash
# 启动测试
~/.qwen/scripts/tmux-sub-agent.sh qwen-sub-test "给我打印 1~10"

# 等待 15 秒后检查日志
sleep 15 && tail -100 /home/wuyangcheng/.qwen/logs/qwen-sub-test_*.log

# 预期输出应包含：
# 1
# 2
# 3
# ...
# 10
```

### 验证输入是否成功发送

**关键判断标准**：

| 现象 | 说明 | 状态 |
|------|------|------|
| 输入框显示任务文本 | 输入已发送但**未提交** | ❌ 失败 |
| 输入框清空，显示 "Type your message" | 输入已成功提交 | ✅ 成功 |
| 日志显示 "Initializing..." | qwen 正在处理任务 | ✅ 成功 |
| 日志显示任务执行输出 | 任务正在执行 | ✅ 成功 |

**检查方法**：
```bash
# 查看最新日志末尾
tail -50 /home/wuyangcheng/.qwen/logs/qwen-sub-*.log

# 如果看到输入框中有文字（如 "* 给我打印 1~10"），说明 Enter 没有正确发送
# 如果看到 "Type your message" 或任务输出，说明成功
```

### 测试 send-to-sub.sh 发送 prompt

```bash
# 1. 启动子进程
~/.qwen/scripts/tmux-sub-agent.sh qwen-sub-test2 "请用 Python 写一个循环，每秒打印一个数字"

# 2. 等待 30 秒
sleep 30

# 3. 发送新指令
~/.qwen/scripts/send-to-sub.sh qwen-sub-test2 "请停止循环并打印'任务完成'"

# 4. 检查日志
sleep 15 && tail -200 /home/wuyangcheng/.qwen/logs/qwen-sub-test2_*.log | tail -100

# 预期：看到新指令被处理，输出"任务完成"
```

### 常见故障及解决

**问题 1：任务输入框有文字但未执行**

现象：日志显示 `* 给我打印 1~10`（文字在输入框中）

原因：Enter 键未正确发送，`C-m` 在某些 TUI 界面中也不可靠

解决：使用 **paste-buffer 方法**（最可靠）

```bash
# ✅ 正确方法：paste-buffer（推荐）
tmux set-buffer "$TASK"
tmux paste-buffer -t "$SESSION_NAME"
sleep 0.5
tmux send-keys -t "$SESSION_NAME" C-m

# ❌ 可能失败的方法
tmux send-keys -t "$SESSION_NAME" "$TASK" C-m  # 对某些 TUI 不可靠
tmux send-keys -t "$SESSION_NAME" "$TASK" Enter  # 通常不工作
```

**问题 2：发送 prompt 后无响应**

现象：发送 prompt 后，日志显示指令在输入框中但未执行

原因：`send-keys` 直接发送文本对 Node.js TUI 不可靠

解决：`send-to-sub.sh` 已更新为使用 paste-buffer 方法：

```bash
# send-to-sub.sh 中的实现（自动使用 paste-buffer）
tmux set-buffer "$PROMPT_TEXT"         # 设置缓冲区
tmux paste-buffer -t "$SESSION_NAME"   # 粘贴到会话
sleep 0.5
tmux send-keys -t "$SESSION_NAME" C-m  # 发送 Enter 提交
```

**问题 3：后台进程不受控制**

现象：发送停止 prompt 后，Python 后台脚本继续运行

原因：prompt 只影响 qwen 前台操作，不影响后台子进程

解决：直接使用 kill 命令停止后台进程

```bash
# 查找进程 PID
ps aux | grep python

# 停止进程
kill <PID>
```

### 测试验证结果

| 方法 | 命令 | 状态 |
|------|------|------|
| **paste-buffer** | `tmux set-buffer + paste-buffer + C-m` | ✅ 成功 |
| send-keys 直接发送 | `tmux send-keys "text" C-m` | ❌ 失败 |
| send-keys Enter | `tmux send-keys "text" Enter` | ❌ 失败 |

**结论**：向 Qwen Code TUI 发送输入，必须使用 **paste-buffer 方法**！

---

## 🚫 重要：禁止使用 "in the background" 方式

### 问题说明

在子进程中执行长时间任务时，**不要**使用以下方式将命令放到后台：

**❌ 避免使用**:
```bash
# 不要用 & 后台运行
python3 train.py &

# 不要用 nohup 后台运行
nohup python3 train.py &

# 不要用 disown 将进程放到后台
python3 train.py &
disown
```

**原因**:
- 后台进程难以监控和管理
- 进程输出可能丢失
- 错误难以及时发现
- 与 qwen TUI 交互可能冲突

### 推荐做法

**✅ 正确方式**:

1. **使用 tmux 新会话运行后台任务**
```bash
# 创建新的 tmux 会话运行任务
tmux new-session -d -s data-generation "python3 data_generator.py"

# 定期检查进度
tmux capture-pane -p -t data-generation | tail -20
```

2. **前台运行并等待完成**
```bash
# 直接前台运行，等待完成
python3 data_generator.py

# 完成后继续下一步
python3 scorer_trainer.py
```

3. **使用 Python 脚本内部管理并发**
```python
# 在 Python 脚本内部使用 multiprocessing 或 concurrent.futures
from concurrent.futures import ProcessPoolExecutor

with ProcessPoolExecutor(max_workers=4) as executor:
    results = list(executor.map(process_data, data_items))
```

### 长时间任务的正确处理方式

**示例：数据生成任务**

```bash
# ✅ 方式 1：直接前台运行（推荐）
python3 data_generator_direct.py --n-seeds 100

# 等待完成后再执行下一步
# 进展汇报中说明"数据生成进行中"

# ✅ 方式 2：使用 tmux 新会话
tmux new-session -d -s data-gen "python3 data_generator_direct.py --n-seeds 100"

# 定期检查进度
tmux capture-pane -p -t data-gen | tail -30

# 等待完成后清理会话
tmux kill-session -t data-gen
```

**在进展文件中汇报进度**:
```markdown
# qwen-auto-scorer-100 进展汇报

更新时间：2026-04-01 14:30:00
状态：🔄 执行中

---

## 当前进展

### 进行中：数据生成
- 命令：python3 data_generator_direct.py --n-seeds 100
- 开始时间：14:19:08
- 预计完成：14:35:00
- 当前状态：正在生成种子 45/100

### 下一步
1. 等待数据生成完成
2. F1 分布可视化分析
3. Scorer 模型训练
```

---

## 📁 Scorer-Searcher 项目约定

### 保存位置

所有 scorer-searcher 相关任务的代码和总结报告都必须保存到 `/home/wuyangcheng/code/scorer-searcher/` 目录中。

**详细文档**: `/home/wuyangcheng/.qwen/SCORER_SEARCHER_PROJECT.md`

### 目录结构

```
/home/wuyangcheng/code/scorer-searcher/
├── src/                    # 源代码文件
├── docs/                   # 文档和报告
├── results/                # 结果文件
├── configs/                # 配置文件
├── scripts/                # 脚本文件
└── TASK_SUMMARY_*.md       # 任务总结报告
```

### 工作流程

**详细流程文档**: `/home/wuyangcheng/code/scorer-searcher/docs/WORKFLOW_DATA_GENERATION_TRAINING.md`

```
1. 数据生成（优先使用 data_generator_direct）
   ↓
2. F1 分布可视化分析（必须执行）
   ↓
3. 确认 F1 分布合理
   ↓
4. Scorer 模型训练
   ↓
5. 结果保存和文档
```

### 启动脚本自动注入

`tmux-sub-agent.sh` 和 `tmux-auto-agent.sh` 已更新为：
- 检测任务是否涉及 scorer
- 自动注入 Scorer-Searcher 项目约定到 system prompt
- 提示保存到正确的目录

---

## ✅ 任务完成后操作（重要！）

### Sub/Auto Agent 任务完成后的标准操作流程

当子进程任务完成后，**必须**执行以下操作：

#### 1. 保存任务总结报告到各自对应的位置

**目的**: 确保任务成果被完整记录并易于查找，每个任务保存到其专用的结果目录

**保存位置**:
- 位置 1: `/home/wuyangcheng/code/result/{task_specific_dir}/TASK_SUMMARY_{task_name}_{date}.md`
- 位置 2: `/home/wuyangcheng/code/{project_name}/TASK_SUMMARY_{task_name}_{date}.md`

**重要**: 不同子进程的任务总结应保存到各自对应的结果目录，不要混在一起！

**示例 1: qwen-auto-n50k4p01-100 任务**
```bash
# 创建总结报告到 n50k4p01 专用目录
cat > /home/wuyangcheng/code/result/scorer_n50k4p01/n50_k4_p01_100seeds/TASK_SUMMARY_n50k4p01_20260401.md << 'EOF'
# qwen-auto-n50k4p01-100 任务总结报告

## 任务概述
- 任务名称：qwen-auto-n50k4p01-100
- 完成时间：2026-04-01 08:00:00

## 输出文件清单
- 数据集路径：/home/wuyangcheng/code/dataset/multi_seed_swsw_n50_k4_p01_20260401_065549.pt
- 模型路径：/home/wuyangcheng/code/result/scorer_training_100seeds/run_20260401_071726/scorer_best.pt

## 参数设置
- n=50: 节点数
- k=4: Watts-Strogatz 邻域大小
- p=0.01: 重连概率
EOF

# 复制到项目目录
cp /home/wuyangcheng/code/result/scorer_n50k4p01/n50_k4_p01_100seeds/TASK_SUMMARY_n50k4p01_20260401.md \
   /home/wuyangcheng/code/scorer-searcher/TASK_SUMMARY_n50k4p01_20260401.md
```

**示例 2: qwen-auto-scorer-100 任务**
```bash
# 创建总结报告到 scorer-100 专用目录
cat > /home/wuyangcheng/code/result/scorer_training_100seeds/TASK_SUMMARY_scorer-100_20260401.md << 'EOF'
# qwen-auto-scorer-100 任务总结报告

## 任务概述
- 任务名称：qwen-auto-scorer-100
- 完成时间：2026-04-01 07:52:00

## 输出文件清单
- 数据集路径：/home/wuyangcheng/code/dataset/multi_seed_swsw_100seeds_20260401.pt
- 模型路径：/home/wuyangcheng/code/result/scorer_training_100seeds/run_20260401_071726/scorer_best.pt

## 关键指标
- Test MSE: 0.0039
- Test Pearson: 0.7443
EOF

# 复制到项目目录
cp /home/wuyangcheng/code/result/scorer_training_100seeds/TASK_SUMMARY_scorer-100_20260401.md \
   /home/wuyangcheng/code/scorer-searcher/TASK_SUMMARY_scorer-100_20260401.md
```

#### 2. 更新进展文件为"已完成"状态

**文件路径**: `/home/wuyangcheng/.qwen/progress/{session_name}.txt`

**示例**:
```markdown
# qwen-auto-scorer-100 进展汇报

更新时间：2026-04-01 08:00:00
状态：✅ 已完成

---

## 任务完成总结

### 已完成工作
- 工作 1: 描述
- 工作 2: 描述

### 输出文件清单
- 文件路径：/home/wuyangcheng/code/...

### 关键指标
- 指标 1: 值
- 指标 2: 值
```

#### 3. 清理 tmux 会话（可选）

```bash
# 查看会话
tmux list-sessions | grep qwen

# 删除已完成的会话
tmux kill-session -t qwen-auto-scorer-100
```

#### 4. 更新 sub_state.json（如果使用监视器）

```bash
# 标记为已通知，避免重复通知
cat /home/wuyangcheng/.qwen/sub_state.json
```



## 🔧 故障排查

### 问题 1: 子进程没有执行任务

**检查**:
```bash
# 查看 tmux 会话
tmux list-sessions | grep qwen

# 查看日志
tail -100 /home/wuyangcheng/.qwen/logs/qwen-sub-*.log

# 检查进程
ps aux | grep "qwen -y -i"
```

**解决**: 确保使用 `qwen -y -i '$TASK'` 格式启动

### 问题 2: 进展文件没有更新

**检查**:
```bash
cat /home/wuyangcheng/.qwen/progress/qwen-sub.txt
```

**解决**: 在 system prompt 中明确汇报文件路径

### 问题 3: Compress 总结没有加载

**检查**:
```bash
cat /home/wuyangcheng/.qwen/compress_summary.txt
```

**解决**: 确保文件存在且有内容

---

## 📖 相关文档

- [prepare-sub-agent.sh](../scripts/prepare-sub-agent.sh) - 📋 准备并启动子进程（推荐）
- [tmux-sub-agent.sh](../scripts/tmux-sub-agent.sh) - Sub Agent 启动脚本
- [tmux-auto-agent.sh](../scripts/tmux-auto-agent.sh) - Auto Agent 启动脚本
- [auto-watch-sub.sh](../scripts/auto-watch-sub.sh) - 子进程监视器
- [check-sub-status.sh](../scripts/check-sub-status.sh) - 状态检查脚本
- [settings.json](../settings.json) - 全局配置文件
- [AGENT_CONFIG.md](./AGENT_CONFIG.md) - Agent 配置规范
- [tmux.md](../tmux.md) - tmux 使用指南
- [WORKFLOW_DATA_GENERATION_TRAINING.md](../../code/scorer-searcher/docs/WORKFLOW_DATA_GENERATION_TRAINING.md) - 📊 Scorer 数据生成和训练工作流程（优先 data_generator_direct → F1 分布可视化 → scorer 训练）
- [SCORER_SEARCHER_PROJECT.md](../SCORER_SEARCHER_PROJECT.md) - Scorer-Searcher 项目目录约定

---

*此文档由 Qwen Code 生成并维护*
*最后更新：2026-04-01*
*版本：v1.7 - 禁止使用"in the background"方式，新增 Scorer-Searcher 项目约定自动注入*
