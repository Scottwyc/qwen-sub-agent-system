# Qwen Code Sub/Auto Agent 消息通知系统

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Qwen Code](https://img.shields.io/badge/Qwen-Code-blue.svg)](https://github.com/anthropics/qwen-code)

> Qwen Code 子进程控制系统 - 在 tmux 中后台运行子进程，主进程继续与用户交流，任务完成时自动发送通知

## 📋 目录

- [功能特点](#-功能特点)
- [系统架构](#-系统架构)
- [快速开始](#-快速开始)
- [安装](#-安装)
- [使用方法](#-使用方法)
- [配置说明](#-配置说明)
- [文件结构](#-文件结构)
- [核心组件](#-核心组件)
- [使用示例](#-使用示例)
- [故障排除](#-故障排除)
- [贡献](#-贡献)
- [许可证](#-许可证)

---

## ✨ 功能特点

- 🚀 **后台运行**: 子进程在 tmux 后台独立运行，不阻塞主进程
- 💬 **主进程继续**: 主进程可继续与用户交流其他话题
- 🔍 **自动监督**: 监视器自动检测任务状态（每 5 秒）
- ⚡ **及时通知**: 任务完成后 5 秒内发送 tmux 状态行通知
- 📝 **简洁通知**: 只在完成时发送一次黄色状态行消息（持续 3 秒）
- 📊 **状态跟踪**: 记录已通知会话避免重复通知
- 🛡️ **安全限制**: 禁止使用删除命令，保护文件安全
- 🚫 **直接执行**: 子进程内禁止再启动子进程，直接执行任务

---

## 🏗️ 系统架构

```
用户命令 → tmux-sub-agent.sh → 创建 tmux 会话 → 启动子进程
                                                      ↓
                                              后台运行任务
                                                      ↓
auto-watch-sub.sh (监视器，每 5 秒检查) ← 日志文件
        ↓
    检测逻辑：
    - 运行中：最后 10 行包含 "esc to cancel"
    - 等待输入：最后 10 行包含 "Type your message"
    - 已完成：不在进行中 且 在等待输入
        ↓
    发送通知 → tmux 状态行消息（黄色，3 秒）
        ↓
    记录 → sub_alerts.txt + sub_state.json
```

---

## 🚀 快速开始

### 方式 1: 使用 prepare-sub-agent.sh（推荐）

```bash
# Auto Agent - 完整流程
bash scripts/prepare-sub-agent.sh auto qwen-auto-mytask "任务描述"

# Sub Agent - 完整流程
bash scripts/prepare-sub-agent.sh sub qwen-sub-mytask "任务描述"
```

此方式会自动：
1. 保存主进程 compress 总结
2. 生成工作计划
3. 启动子进程并自动加载上述文档

### 方式 2: 直接使用 sub/auto 命令

```bash
# Auto Agent - 自动先执行 prepare 流程
bash scripts/tmux-auto-agent.sh qwen-auto-mytask "任务描述"

# Sub Agent - 自动先执行 prepare 流程
bash scripts/tmux-sub-agent.sh qwen-sub-mytask "任务描述"
```

**说明**: `tmux-auto-agent.sh` 和 `tmux-sub-agent.sh` 已更新为：
1. **首先** 调用 prepare 流程保存主进程总结和工作计划
2. **然后** 继续原来的流程，加载这些文档到子进程 prompt 中
3. 子进程执行任务并定期汇报进展

### 查看通知

任务完成后会收到 tmux 状态行通知：
```
⚠️  qwen-sub-task 任务完成，等待输入!
```

### 查看结果

```bash
# 查看警报通知
cat sub_alerts.txt

# 查看实时状态
bash scripts/check-sub-status.sh

# 连接会话
tmux attach -t qwen-sub-task
```

---

## 📦 安装

### 前置要求

- Linux/macOS 操作系统
- tmux (>= 3.0)
- bash (>= 4.0)
- Qwen Code CLI

### 安装步骤

1. **克隆仓库**
```bash
git clone https://github.com/YOUR_USERNAME/qwen-sub-agent-system.git
cd qwen-sub-agent-system
```

2. **配置路径**

编辑 `config/install.sh`（如果需要自定义路径）

3. **运行安装脚本**
```bash
chmod +x config/install.sh
./config/install.sh
```

4. **验证安装**
```bash
bash scripts/check-sub-status.sh
```

---

## 💡 使用方法

### 启动子进程

#### Sub Agent 模式
```bash
# 基本用法
bash scripts/tmux-sub-agent.sh qwen-sub-<name> "<任务描述>"

# 示例：查找质数
bash scripts/tmux-sub-agent.sh qwen-sub-prime "找到 1000 以内的所有质数"

# 示例：搜索 AI 新闻
bash scripts/tmux-sub-agent.sh qwen-sub-ainews "搜索最新的 AI 新闻，整理成报告"
```

#### Auto Agent 模式（完全自主）
```bash
bash scripts/tmux-auto-agent.sh qwen-auto-<name> "<任务描述>"

# 示例：分析代码结构
bash scripts/tmux-auto-agent.sh qwen-auto-analysis "分析当前项目的代码结构"
```

### 管理命令

```bash
# 查看所有子进程状态
bash scripts/check-sub-status.sh

# 查看警报通知
cat ~/.qwen/sub_alerts.txt

# 连接会话
tmux attach -t qwen-sub-<name>

# 查看日志
tail -f ~/.qwen/logs/qwen-sub-<name>_*.log

# 删除会话
tmux kill-session -t qwen-sub-<name>
```

### 监视器管理

```bash
# 启动监视器
nohup bash scripts/auto-watch-sub.sh 5 >> ~/.qwen/logs/watcher.log 2>&1 &

# 检查状态
ps aux | grep "auto-watch-sub"

# 停止监视器
pkill -f "auto-watch-sub.sh"
```

---

## ⚙️ 配置说明

### 全局配置 (config/settings.json)

```json
{
  "subAgentNotification": {
    "enabled": true,
    "watcherScript": "~/.qwen/scripts/auto-watch-sub.sh",
    "statusFile": "~/.qwen/sub_status.txt",
    "alertsFile": "~/.qwen/sub_alerts.txt",
    "stateFile": "~/.qwen/sub_state.json",
    "refreshInterval": 5,
    "notificationDuration": 3000,
    "detectionLogic": {
      "taskInProgress": "最后 10 行包含 'esc to cancel'",
      "waitingForInput": "最后 10 行包含 'Type your message'",
      "taskCompleted": "不在进行中 且 在等待输入"
    }
  }
}
```

### 配置参数说明

| 参数 | 默认值 | 说明 |
|------|--------|------|
| `refreshInterval` | 5 | 监视器刷新间隔（秒） |
| `notificationDuration` | 3000 | 通知持续时间（毫秒） |
| `detectionLogic` | - | 任务状态检测逻辑 |

---

## 📁 文件结构

```
qwen-sub-agent-system/
├── scripts/
│   ├── tmux-sub-agent.sh         # Sub Agent 启动脚本 (v1.3)
│   ├── tmux-auto-agent.sh        # Auto Agent 启动脚本 (v1.3)
│   ├── prepare-sub-agent.sh      # 准备并启动子进程 (new)
│   ├── send-to-sub.sh            # 发送命令到子进程 (new)
│   ├── auto-watch-sub.sh         # 子进程监视器（核心）
│   └── check-sub-status.sh       # 状态检查脚本
├── docs/
│   ├── sub_agent.md              # 完整技能文档 (v1.3)
│   ├── SUB_AUTO_QUICK_REFERENCE.md # 快速参考
│   └── SUB_AUTO_ARCHITECTURE.md  # 系统架构文档
├── config/
│   ├── settings.json             # 全局配置模板
│   └── install.sh                # 安装脚本
├── examples/
│   └── examples.md               # 使用示例
├── README.md                     # 本文件 (v1.3)
└── LICENSE                       # MIT 许可证
```

---

## 🔧 核心组件

### 1. tmux-sub-agent.sh
启动 Sub Agent 子进程，创建 tmux 会话并自动启动监视器。

### 2. auto-watch-sub.sh
后台监视器，每 5 秒检查所有子进程状态，检测任务完成情况并发送通知。

### 3. check-sub-status.sh
检查并显示所有子进程的当前状态。

### 4. send-notification.sh
发送 tmux 状态行通知。

---

## 📊 使用示例

### 示例 1：查找质数

```bash
# 启动任务
bash scripts/tmux-sub-agent.sh qwen-sub-prime "找到 1000 以内的所有质数"

# 等待通知（约 5-10 秒）
# 收到：⚠️  qwen-sub-prime 任务完成，等待输入!

# 查看结果
cat ~/primes_under_1000.txt

# 清理
tmux kill-session -t qwen-sub-prime
```

### 示例 2：生成 Python 脚本

```bash
# 启动任务
bash scripts/tmux-sub-agent.sh qwen-sub-script "用 Python 打印 1 到 100"

# 等待通知
# 查看生成的脚本
cat ~/print_1_to_100.py
python ~/print_1_to_100.py
```

### 示例 3：搜索并整理报告

```bash
# 启动任务
bash scripts/tmux-sub-agent.sh qwen-sub-report "搜索 GNN 的介绍，整理成 Markdown 报告"

# 主进程继续其他工作...

# 等待通知后查看报告
cat ~/gnn_introduction.md
```

---

## 🐛 故障排除

### 问题：收不到通知

**检查步骤：**
1. 确认监视器在运行：`ps aux | grep "auto-watch-sub"`
2. 检查日志文件：`tail -f ~/.qwen/logs/watcher.log`
3. 确认状态文件未被锁定

### 问题：子进程卡住

**解决方案：**
1. 查看日志：`tail -f ~/.qwen/logs/qwen-sub-*.log`
2. 连接会话：`tmux attach -t qwen-sub-task`
3. 删除会话：`tmux kill-session -t qwen-sub-task`

### 问题：通知重复发送

**解决方案：**
```bash
# 重置状态文件
echo "{}" > ~/.qwen/sub_state.json
```

---

## 🤝 贡献

欢迎提交 Issue 和 Pull Request！

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feature/AmazingFeature`)
3. 提交更改 (`git commit -m 'Add some AmazingFeature'`)
4. 推送到分支 (`git push origin feature/AmazingFeature`)
5. 开启 Pull Request

---

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

---

## 📞 联系方式

- 作者：[scottwyc]
- 项目地址：[https://github.com/Scottwyc/qwen-sub-agent-system](https://github.com/Scottwyc/qwen-sub-agent-system)

---

## 🙏 致谢

- [Qwen Code](https://github.com/anthropics/qwen-code) - Qwen Code 项目
- [tmux](https://github.com/tmux/tmux) - tmux 终端复用器

---

*最后更新：2026-04-02*
*版本：v1.8 - 新增 Qwen 工具超时限制与 tmux 嵌套方案（长时间训练任务专用）*

---

## 📝 更新日志

### v1.8 (2026-04-02)

**新增功能:**
- ⚠️ **Qwen 工具超时限制解决方案** - 针对长时间运行任务（>5 分钟）的 tmux 嵌套方案
- 🔄 **嵌套 tmux 会话支持** - 允许子进程在自身 tmux 中再创建嵌套会话运行训练任务
- 📊 **长时间任务管理** - 数据生成、模型训练等任务的正确处理方式

**新增文档章节:**
- `docs/sub_agent.md` - 新增"Qwen 工具超时限制与 tmux 嵌套方案"完整说明
- 适用场景：数据生成（>5 分钟）、模型训练（>10 分钟）、大规模评估
- 进展汇报示例和注意事项

**背景说明:**
- Qwen Code 工具调用有时长限制（约 2-5 分钟）
- 长时间任务可能超时中断
- 通过嵌套 tmux 会话，任务在独立会话中运行，不受工具超时限制

**更新文件:**
- `docs/sub_agent.md` - 新增完整章节和示例

### v1.4 (2026-04-02)

**新增功能:**
- 🎯 **项目目录自动识别** - 根据任务关键词自动识别项目 (scorer-searcher, gan-decomposer, diffusion-model)
- 📁 **工作计划分类保存** - 工作计划保存到对应项目的 `workPlan/` 目录
- ❓ **提问语句检测** - 自动检测中文/英文问句，识别"等待回答"状态

**改进:**
- 🔄 **状态检测优化** - 使用 `esc to cancel` 作为运行中标志，更准确
- 📊 **状态分类细化** - 运行中 / 等待回答 / 已完成等待输入
- 📝 **文档更新** - 补充 paste-buffer 方式说明、禁止后台运行说明

**更新文件:**
- `scripts/tmux-auto-agent.sh` - 添加项目识别逻辑
- `scripts/tmux-sub-agent.sh` - 添加项目识别逻辑
- `scripts/prepare-sub-agent.sh` - 同步项目识别逻辑
- `scripts/auto-watch-sub.sh` - 新增提问检测函数
- `scripts/check-sub-status.sh` - 简化状态检测
- `docs/sub_agent.md` - 补充重要说明

### v1.3 (2026-04-01)

- 集成 prepare-sub-agent.sh 流程
- 禁止子进程内再启动子进程
- 添加完整技能文档

### v1.2 (2026-03-31)

- 添加 tmux 状态行通知
- 实现状态跟踪避免重复通知
- 改进任务完成检测逻辑
