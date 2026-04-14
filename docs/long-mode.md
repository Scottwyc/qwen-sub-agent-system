# Qwen Code Long Agent 技能文档

> Long 模式 - 长时间自主运行模式完整配置指南

## 📋 概述

Long 模式是在 Sub/Auto Agent 基础上扩展的**长时间自主运行模式**，适用于需要持续运行较长时间才能完成的复杂任务。

**核心特性**：
- 在新的 tmux 中启动，后台自主运行
- 在 YOLO 模式基础上拥有**最高权限**（但仍禁止 rm 等删除命令）
- 自动启动**定时监督脚本**，定期追踪进度并汇报
- 自动启动**上下文监督脚本**，监控上下文使用情况并在需要时自动压缩
- 关键技术进展时自动更新**中文技术报告**
- 脚本更新时自动**备份旧版本**

---

## 🎯 使用场景

| 场景 | 说明 | 示例 |
|------|------|------|
| **长时间训练任务** | 模型训练需要数小时甚至数天 | scorer 训练、diffusion 模型训练 |
| **大规模数据生成** | 生成大量种子数据集 | 100+ 种子数据集生成 |
| **复杂实验流程** | 多步骤实验，需要持续监控和调整 | 超参数搜索、消融实验 |
| **代码重构 + 测试** | 大规模代码重构并运行完整测试套件 | 模块重构 + 全量测试 |
| **自动化工作流** | 完整的数据处理到报告生成工作流 | 数据分析 → 可视化 → 报告 |

---

## 🚀 快速启动

### 方式 1: 自然语言触发（推荐）

```
long [任务描述]
```

**示例：**
```
long 使用参数 n=50, k=4, p=0.01 生成 100 种子数据集并训练 scorer，生成完整报告
```

---

### 方式 2: 使用 tmux-long-agent.sh 脚本

```bash
# 正确格式
bash /home/wuyangcheng/.qwen/scripts/tmux-long-agent.sh <session-name> "<任务描述>"

# 示例
bash /home/wuyangcheng/.qwen/scripts/tmux-long-agent.sh qwen-long-scorer100 "使用参数 n=50, k=4, p=0.01 生成 100 种子数据集并训练 scorer"
```

**参数说明：**
| 参数 | 说明 | 示例 |
|------|------|------|
| `<session-name>` | **第 1 个参数** - tmux 会话名称（英文简写） | `qwen-long-scorer100` |
| `<任务描述>` | **第 2 个参数** - 任务指令（用引号包裹） | `"生成 100 种子数据集并训练 scorer"` |

**Session Name 命名规范：**
- 必须以 `qwen-long-` 开头
- 使用**英文**简写，方便后续监控和发送命令
- 示例：`qwen-long-scorer100`, `qwen-long-data-gen`, `qwen-long-refactor`

---

## 🔧 核心脚本

### 1. tmux-long-agent.sh - Long 模式启动脚本

**路径**: `/home/wuyangcheng/.qwen/scripts/tmux-long-agent.sh`

**功能**:
- 创建 tmux 会话并启动 qwen YOLO 模式
- 生成工作计划和技术报告模板
- 自动启动定时监督脚本和上下文监督脚本
- 加载主进程总结和工作计划到子进程

**工作流程**:
```
用户启动 Long 模式
    ↓
准备上下文（主进程总结、工作计划、技术报告模板）
    ↓
创建 tmux 会话并启动 qwen
    ↓
发送任务指令（使用 paste-buffer 方式）
    ↓
启动定时监督脚本（long-mode-supervisor.sh）
    ↓
启动上下文监督脚本（long-context-monitor.sh）
    ↓
启动状态监控（后台定期检查状态）
    ↓
Long 模式开始自主运行任务
```

---

### 2. long-mode-supervisor.sh - 定时监督脚本

**路径**: `/home/wuyangcheng/.qwen/scripts/long-mode-supervisor.sh`

**功能**:
- 定时向 Long 模式 tmux 会话发送进展查询指令
- 使用 paste-buffer 方式可靠地发送指令
- 自动捕获最新进展并记录到进展文件
- **关键**：监督完成后自动发送"继续"指令，让 Long 窗口回到之前的任务

**用法**:
```bash
# 手动启动（通常由 tmux-long-agent.sh 自动启动）
bash /home/wuyangcheng/.qwen/scripts/long-mode-supervisor.sh <session-name> [interval-seconds]

# 示例：每 300 秒（5 分钟）查询一次进展
bash /home/wuyangcheng/.qwen/scripts/long-mode-supervisor.sh qwen-long-scorer100 300
```

**参数说明**:
| 参数 | 说明 | 默认值 |
|------|------|--------|
| `<session-name>` | tmux 会话名称 | 必需 |
| `[interval-seconds]` | 监督间隔（秒） | 300（5 分钟） |

**监督流程**（每次循环）:
```
1. 发送进展查询指令
   "请简要汇报当前进展（1-2句话说明当前状态和已完成的工作），不要展开新操作。"
    ↓
2. 等待 45 秒让 qwen 响应
    ↓
3. 捕获 tmux 最新输出，追加到进展文件
    ↓
4. ⚠️ 关键：发送"继续"指令
   "好的，请继续之前的任务。"
    ↓
5. 等待指定间隔（默认 300 秒）后下次监督
```

**为什么需要"继续"指令？**
- 监督脚本发送的进展查询会打断 Long 窗口的当前任务
- qwen 回答进展问题后，会等待进一步指示
- 如果不发送"继续"指令，Long 窗口会卡住等待用户输入
- 发送"继续"后，qwen 会回到之前被中断的任务

**记录内容**:
- 时间戳
- 当前状态
- 最新输出摘要（从 tmux 捕获）
- "继续"指令发送记录

---

### 3. long-context-monitor.sh - 上下文监督脚本

**路径**: `/home/wuyangcheng/.qwen/scripts/long-context-monitor.sh`

**功能**:
- 监控 qwen 上下文使用情况（通过 ccusage 或 tmux 输出）
- 当达到阈值（默认 18% used）且当前已完成一个阶段性结果时
- 自动向 Long 模式 tmux 发送上下文压缩指令
- 压缩完成后自动恢复 Long 模式运行

**用法**:
```bash
# 手动启动（通常由 tmux-long-agent.sh 自动启动）
bash /home/wuyangcheng/.qwen/scripts/long-context-monitor.sh <session-name> [threshold-percent]

# 示例：上下文使用达到 18% 时触发压缩
bash /home/wuyangcheng/.qwen/scripts/long-context-monitor.sh qwen-long-scorer100 18
```

**参数说明**:
| 参数 | 说明 | 默认值 |
|------|------|--------|
| `<session-name>` | tmux 会话名称 | 必需 |
| `[threshold-percent]` | 上下文使用阈值（%） | 18 |

**压缩流程**:
```
1. 检测到上下文使用达到阈值（如 18% used）
    ↓
2. 检查是否已完成一个阶段性结果
    ↓
3. 如果已完成阶段性结果：
   a. 发送 "Esc" 暂停当前操作
   b. 等待 2 秒
   c. 发送 "/compress" 执行上下文压缩
   d. 等待 30 秒让压缩完成
   e. 发送 "继续long模式" 恢复运行
    ↓
4. 记录压缩事件到日志
```

**冷却机制**:
- 压缩冷却时间：600 秒（10 分钟）
- 避免频繁触发压缩影响任务执行

---

## 📊 文件结构

### 生成的文件

| 文件类型 | 路径 | 更新方式 | 内容 |
|----------|------|----------|------|
| **工作计划** | `{project}/workPlan/QWEN_workPlan_{session}_{timestamp}.md` | 启动时生成 | 任务目标、执行要求、安全限制 |
| **技术报告** | `{project}/LONG_MODE_TECH_REPORT_{session}_{date}.md` | Long 模式运行时更新 | 任务概述、关键进展、测试结果、输出文件 |
| **进展文件** | `/home/wuyangcheng/.qwen/progress/{session}.txt` | Long 模式 + 监督脚本更新 | 结构化进展汇报 |
| **日志文件** | `/home/wuyangcheng/.qwen/logs/{session}_{timestamp}.log` | 监视器定期更新 | tmux 会话最新输出 |
| **上下文日志** | `/home/wuyangcheng/.qwen/logs/{session}_context_usage.log` | 上下文监督脚本追加 | 上下文使用记录和压缩事件 |
| **监督日志** | `/home/wuyangcheng/.qwen/logs/long-supervisor.log` | 定时监督脚本追加 | 监督脚本运行日志 |

### 相关脚本

| 脚本 | 路径 | 功能 |
|------|------|------|
| **tmux-long-agent.sh** | `/home/wuyangcheng/.qwen/scripts/tmux-long-agent.sh` | 🚀 Long 模式启动 |
| **long-mode-supervisor.sh** | `/home/wuyangcheng/.qwen/scripts/long-mode-supervisor.sh` | ⏰ 定时进展监督 |
| **long-context-monitor.sh** | `/home/wuyangcheng/.qwen/scripts/long-context-monitor.sh` | 🧠 上下文监控 |
| **send-to-sub.sh** | `/home/wuyangcheng/.qwen/scripts/send-to-sub.sh` | 📮 发送指令到子进程 |
| **check-progress.sh** | `/home/wuyangcheng/.qwen/scripts/check-progress.sh` | 📊 查看进展 |

---

## 🔑 Long 模式权限

### 最高权限自主运行

Long 模式在 YOLO 模式基础上拥有**最高权限**：
- 可以自主决定运行长时间任务
- 可以自主启动后台进程（使用 nohup 等方式）
- 可以自主管理后台进程生命周期

### 但仍然禁止的命令

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
| 备份后替换 | `cp file.txt file.txt.bak && mv new.txt file.txt` |

---

## 📝 Long 模式运行规则

### 1. 后台进程管理

如果需要跟踪长时间运行的程序：

```bash
# ✅ 正确方式：使用 nohup 后台运行
nohup python train.py > train.log 2>&1 &

# ❌ 错误方式：直接运行（shell 关闭会杀掉进程）
python train.py

# ❌ 错误方式：使用 & 但不重定向输出
python train.py &
```

**监督后台进程**:
```bash
# 查看后台进程
ps aux | grep python

# 查看进程日志
tail -f train.log

# 停止进程
kill <PID>
```

---

### 2. 技术报告更新

**技术报告路径**: `{project}/LONG_MODE_TECH_REPORT_{session}_{date}.md`

**更新时机**:
- ✅ **关键技术进展时** - 如模型训练完成、测试通过
- ✅ **阶段任务完成时** - 如数据生成完成、分析完成
- ✅ **遇到问题并解决时** - 记录问题和解决方案
- ✅ **任务完成时** - 总结成果和输出文件清单

**报告格式**（中文）:
```markdown
# Long 模式技术报告 - {session-name}

**生成时间**: {timestamp}
**任务**: {task}
**项目**: {project}

---

## 任务概述

{task description}

---

## 关键进展

### 1. {进展标题}
- 时间：{timestamp}
- 描述：{详细描述}
- 数据：{测试数据、指标等}

### 2. {进展标题}
...

---

## 测试结果

| 测试项 | 结果 | 说明 |
|--------|------|------|
| {test 1} | {result} | {description} |
| {test 2} | {result} | {description} |

---

## 输出文件清单

- {file 1 path}
- {file 2 path}
- ...

---

## 总结与建议

{总结当前成果和下一步建议}

---

**状态**: 🔄 执行中 / ✅ 已完成
**最后更新**: {timestamp}
```

---

### 3. 脚本更新规范

**如果对之前的脚本有较大更新**:

```bash
# 步骤 1: 备份原脚本
mv original_script.py original_script.py.bak

# 步骤 2: 创建新版本脚本
# （使用新文件名或覆盖，但已有备份）
```

**备份命名规范**:
- `{original_script}.py.bak`
- 示例：`data_generator.py.bak`, `train_scorer.py.bak`

---

## 📊 进展汇报机制

### 进展文件位置

```
/home/wuyangcheng/.qwen/progress/<session-name>.txt
```

### 写入格式（覆盖写入）

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

### 写入时机

| 时机 | 说明 | 示例 |
|------|------|------|
| **任务开始** | 说明理解和计划 | "已开始任务，将生成 100 种子数据集" |
| **完成关键步骤** | 总结当前进展 | "已完成 50 种子数据集生成" |
| **遇到问题** | 记录问题和解决方案 | "遇到内存不足问题，已调整批处理大小" |
| **任务完成** | 总结成果和输出文件 | "任务完成，模型已训练，报告已保存" |

---

## 📡 监控和管理

### 查看进展

```bash
# 查看进展文件
cat /home/wuyangcheng/.qwen/progress/qwen-long-scorer100.txt

# 使用 check-progress.sh 脚本
bash /home/wuyangcheng/.qwen/scripts/check-progress.sh qwen-long-scorer100
```

### 发送指令

```bash
# 使用 send-to-sub.sh 发送指令
bash /home/wuyangcheng/.qwen/scripts/send-to-sub.sh qwen-long-scorer100 "请暂停当前操作，打印进展总结"

# 示例指令
bash /home/wuyangcheng/.qwen/scripts/send-to-sub.sh qwen-long-scorer100 "当前进展，并总结报告"
bash /home/wuyangcheng/.qwen/scripts/send-to-sub.sh qwen-long-scorer100 "请停止训练，保存当前模型"
bash /home/wuyangcheng/.qwen/scripts/send-to-sub.sh qwen-long-scorer100 "继续long模式"
```

### 连接会话

```bash
# 连接到 Long 模式会话
tmux attach -t qwen-long-scorer100

# 分离会话
# Ctrl+B, 然后按 D
```

### 查看日志

```bash
# 查看 tmux 会话日志
tail -f /home/wuyangcheng/.qwen/logs/qwen-long-scorer100_*.log

# 查看上下文使用日志
tail -f /home/wuyangcheng/.qwen/logs/qwen-long-scorer100_context_usage.log

# 查看监督脚本日志
tail -f /home/wuyangcheng/.qwen/logs/long-supervisor.log
tail -f /home/wuyangcheng/.qwen/logs/long-ctx-monitor.log
```

### 查看技术报告

```bash
# 查看最新技术报告
cat /home/wuyangcheng/code/scorer-searcher/LONG_MODE_TECH_REPORT_qwen-long-scorer100_*.md
```

### 停止/中断 Long 模式

**重要**: Long 模式窗口在运行中，不能直接发送新指令（会被当作普通文本输入到正在运行的程序中）。正确的中断流程是：

```bash
# ⚠️ 正确的中断流程（2 步）：

# 步骤 1: 先发送 Esc 键暂停当前操作
tmux send-keys -t qwen-long-scorer100 Escape
sleep 2

# 步骤 2: 再发送新的提示词
bash /home/wuyangcheng/.qwen/scripts/send-to-sub.sh qwen-long-scorer100 "请停止当前操作，保存当前进展并打印'任务已停止'"
```

**为什么需要 Esc？**
- Long 模式窗口在运行 Python 脚本或其他程序时，输入焦点在程序上
- 直接发送指令会被当作程序的标准输入，而非 qwen 的提示词
- 发送 `Esc` 键可以中断/暂停当前程序，让输入焦点回到 qwen
- 之后再发送的新指令才能被 qwen 正确接收

**其他停止方式**：

```bash
# 方式 A: 删除 tmux 会话（强制终止，不推荐）
tmux kill-session -t qwen-long-scorer100

# 方式 B: 停止监督脚本（不终止任务，仅停止监控）
pkill -f "long-mode-supervisor.sh"
pkill -f "long-context-monitor.sh"
```

**常见场景处理**：

| 场景 | 操作 |
|------|------|
| 程序运行中，想发新指令 | `Esc` → 等待 2 秒 → `send-to-sub.sh` |
| 模型训练中，想暂停保存 | `Esc` → 等待 2 秒 → 发送"请暂停并保存当前模型" |
| 任务卡住/死循环 | `Esc` → 等待 2 秒 → 发送"请报告当前状态" |
| 完全终止任务 | `tmux kill-session`（最后手段） |

---

## 🔄 完整工作流程

```
用户启动 Long 模式任务
    ↓
主进程执行 tmux-long-agent.sh
    ↓
生成工作计划、技术报告模板、主进程总结
    ↓
创建 tmux 会话并启动 qwen (YOLO 模式)
    ↓
发送任务指令（paste-buffer 方式）
    ↓
启动定时监督脚本（每 5 分钟查询进展）
    ↓
启动上下文监督脚本（每 60 秒检查上下文）
    ↓
启动状态监控（每 60 秒检查状态）
    ↓
═══════════════════════════════════
  Long 模式开始自主运行
═══════════════════════════════════
    ↓
[运行中]
├── 定时监督脚本每 5 分钟发送进展查询
│       ↓
│   发送："请简要汇报当前进展...不要展开新操作。"
│       ↓
│   等待 45 秒让 qwen 响应
│       ↓
│   捕获最新输出并记录到进展文件
│       ↓
│   ⚠️ 发送："好的，请继续之前的任务。"
│       ↓
│   Long 窗口回到之前的任务继续执行
│       ↓
│   等待 5 分钟后下次监督
│
├── 上下文监督脚本每 60 秒检查
│       ↓
│   检测到上下文使用达到 18% used
│       ↓
│   检查是否已完成阶段性结果
│       ↓
│   如果已完成 → 触发压缩流程：
│       ├── 发送 Esc 暂停
│       ├── 发送 /compress 压缩上下文
│       ├── 等待压缩完成
│       └── 发送"继续long模式"恢复运行
│
├── Long 模式自主执行任务
│       ↓
│   如需长时间运行 → 使用 nohup 后台运行
│       ↓
│   关键技术进展 → 更新技术报告
│       ↓
│   更新脚本 → 先备份旧版本
│
└── 定期更新进展文件和技术报告
    ↓
═══════════════════════════════════
  任务完成
═══════════════════════════════════
    ↓
Long 模式更新进展文件为"✅ 已完成"
    ↓
更新技术报告（总结成果和输出文件清单）
    ↓
状态监控检测到会话结束，显示最终状态
    ↓
主进程收到通知（如配置了通知）
    ↓
用户查看结果
├── 查看技术报告
├── 查看进展文件
├── 查看输出文件
└── 清理 tmux 会话
```

---

## 📋 使用示例

### 示例 1: Scorer 训练任务

```bash
# 启动 Long 模式
bash /home/wuyangcheng/.qwen/scripts/tmux-long-agent.sh qwen-long-scorer100 \
  "使用参数 n=50, k=4, p=0.01 生成 100 种子数据集并训练 scorer，生成完整报告"

# 等待任务执行...

# 查看进展
bash /home/wuyangcheng/.qwen/scripts/check-progress.sh qwen-long-scorer100

# 查看技术报告
cat /home/wuyangcheng/code/scorer-searcher/LONG_MODE_TECH_REPORT_qwen-long-scorer100_*.md

# 发送新指令（如需要）
bash /home/wuyangcheng/.qwen/scripts/send-to-sub.sh qwen-long-scorer100 "请暂停训练，保存当前模型"
```

### 示例 2: 大规模数据生成

```bash
# 启动 Long 模式
bash /home/wuyangcheng/.qwen/scripts/tmux-long-agent.sh qwen-long-datagen \
  "生成 500 种子数据集，进行 F1 分布可视化分析，保存所有结果"

# 监控进展
tail -f /home/wuyangcheng/.qwen/progress/qwen-long-datagen.txt

# 查看技术报告
cat /home/wuyangcheng/code/scorer-searcher/LONG_MODE_TECH_REPORT_qwen-long-datagen_*.md
```

### 示例 3: 代码重构 + 测试

```bash
# 启动 Long 模式
bash /home/wuyangcheng/.qwen/scripts/tmux-long-agent.sh qwen-long-refactor \
  "重构 scorer_trainer.py 模块，提高代码可读性，运行完整测试套件"

# 查看进展
tmux attach -t qwen-long-refactor

# 发送指令
bash /home/wuyangcheng/.qwen/scripts/send-to-sub.sh qwen-long-refactor "请总结当前重构进展"
```

---

## ⚙️ settings.json 配置

Long 模式配置（添加到 settings.json 的 `agent` 部分）：

```json
{
  "agent": {
    "longMode": {
      "enabled": true,
      "triggerCommand": "long",
      "inheritFullPermissions": true,
      "backgroundMode": true,
      "tmuxMode": {
        "enabled": true,
        "sessionPrefix": "qwen-long",
        "script": "/home/wuyangcheng/.qwen/scripts/tmux-long-agent.sh",
        "systemPromptTemplate": "请先加载你的全局设置（~/.qwen/settings.json），工作目录在 ~/code。🔑 Long 模式：最高权限自主运行（仍禁止 rm 等删除命令）。📊 进展汇报：关键进展写入 /home/wuyangcheng/.qwen/progress/{session_name}.txt。📝 技术报告：关键技术进展更新到项目目录下的 LONG_MODE_TECH_REPORT 文件。"
      },
      "supervisor": {
        "progressInterval": 300,
        "contextCheckInterval": 60,
        "contextThreshold": 18,
        "compressCooldown": 600,
        "progressScript": "/home/wuyangcheng/.qwen/scripts/long-mode-supervisor.sh",
        "contextMonitor": "/home/wuyangcheng/.qwen/scripts/long-context-monitor.sh"
      },
      "progressReporting": {
        "enabled": true,
        "method": "file",
        "progressDir": "/home/wuyangcheng/.qwen/progress",
        "techReportDir": "{project}/",
        "reportOnMilestone": true,
        "notifyMainProcessOnComplete": true
      },
      "safetyRules": {
        "noDeleteCommands": true,
        "forbiddenCommands": [
          "rm",
          "rmdir",
          "rm -rf",
          "rm -r",
          "rm -f"
        ],
        "description": "⚠️ Long 模式下也严格禁止使用任何删除命令"
      }
    }
  }
}
```

---

## ✅ 检查清单

### 启动 Long 模式前确认

- [ ] 任务描述清晰完整，包含所有参数要求
- [ ] 了解安全限制（禁止 rm 等命令）
- [ ] 确认项目目录正确
- [ ] 确认有足够的磁盘空间（长时间任务可能生成大量数据）

### 运行中监控

- [ ] 定期检查进展文件
- [ ] 定期查看技术报告
- [ ] 监督脚本日志正常（无错误）
- [ ] 上下文监督正常（无频繁压缩）

### 任务完成后确认

- [ ] 任务目标已达成
- [ ] 技术报告已更新最终状态
- [ ] 代码/报告已保存到项目目录
- [ ] 进展文件已更新为"✅ 已完成"
- [ ] 已告知用户生成的文件路径（使用绝对路径）
- [ ] 清理 tmux 会话和监督脚本

---

## 🐛 故障排除

### 问题：收不到进展更新
**检查步骤：**
1. 确认 Long 模式会话在运行：`tmux list-sessions | grep qwen-long`
2. 检查进展文件是否有更新：`cat /home/wuyangcheng/.qwen/progress/qwen-long-*.txt`
3. 查看 tmux 日志：`tail -f /home/wuyangcheng/.qwen/logs/qwen-long-*.log`
4. 检查监督脚本是否在运行：`ps aux | grep long-mode-supervisor`

### 问题：上下文频繁压缩
**解决方案：**
- 增加压缩冷却时间：修改 `long-context-monitor.sh` 中的 `COMPRESS_COOLDOWN` 变量
- 增加上下文阈值：启动时指定更高的阈值 `long-context-monitor.sh qwen-long 25`

### 问题：Long 模式卡住
**解决方案：**
1. 查看日志：`tail -f /home/wuyangcheng/.qwen/logs/qwen-long-*.log`
2. 连接会话：`tmux attach -t qwen-long-task`
3. 发送指令：`bash /home/wuyangcheng/.qwen/scripts/send-to-sub.sh qwen-long-task "请打印当前状态"`
4. 必要时删除会话：`tmux kill-session -t qwen-long-task`

### 问题：监督脚本未启动
**检查步骤：**
1. 检查脚本是否存在：`ls -la /home/wuyangcheng/.qwen/scripts/long-mode-supervisor.sh`
2. 检查脚本权限：`chmod +x /home/wuyangcheng/.qwen/scripts/long-mode-supervisor.sh`
3. 查看启动日志：`cat /home/wuyangcheng/.qwen/logs/long-supervisor.log`

---

## 📝 与 Sub/Auto 模式的区别

| 特性 | Sub 模式 | Auto 模式 | Long 模式 |
|------|----------|-----------|-----------|
| **运行时间** | 短-中等 | 中等 | **长时间** |
| **权限级别** | 标准 | 标准 | **最高权限** |
| **后台进程** | 禁止 | 禁止 | **允许（nohup）** |
| **定时监督** | ✅ | ✅ | ✅（默认 5 分钟） |
| **上下文监督** | ❌ | ❌ | ✅（自动压缩） |
| **技术报告** | ❌ | ❌ | ✅（自动更新） |
| **脚本备份** | ❌ | ❌ | ✅（自动备份） |
| **适用场景** | 代码分析、文档生成 | 优化实验、搜索 | 长时间训练、大规模数据生成 |

---

## 📚 相关文档

- **Sub/Auto Agent 文档**: `/home/wuyangcheng/.qwen/skills/sub_agent.md`
- **QWEN 全局配置**: `/home/wuyangcheng/.qwen/QWEN.md`
- **技能索引**: `/home/wuyangcheng/.qwen/skills/content.md`

---

*此文档应定期更新以反映最新的 Long 模式配置*

**最后更新**: 2026-04-14
