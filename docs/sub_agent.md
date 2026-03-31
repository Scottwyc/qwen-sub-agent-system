# Qwen Code Sub/Auto Agent 技能文档

## 📋 概述

Sub/Auto Agent 系统允许主进程在 tmux 中启动后台子进程执行任务，同时主进程可以继续与用户交流其他话题。监视器会自动监督子进程状态，并在任务完成时发送通知。

---

## 🚀 快速启动

### 启动 Sub Agent
```bash
# 使用启动脚本
bash /home/wuyangcheng/.qwen/scripts/tmux-sub-agent.sh <会话名称> "<任务描述>"

# 示例
bash /home/wuyangcheng/.qwen/scripts/tmux-sub-agent.sh qwen-sub-task "查找 1000 以内的所有质数"
```

### 启动 Auto Agent（完全自主模式）
```bash
# 使用启动脚本
bash /home/wuyangcheng/.qwen/scripts/tmux-auto-agent.sh <会话名称> "<任务描述>"

# 示例
bash /home/wuyangcheng/.qwen/scripts/tmux-auto-agent.sh qwen-auto-analysis "分析当前项目的代码结构"
```

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

### 通知触发条件
**任务完成检测逻辑：**
1. **任务进行中** = 最后 10 行日志包含 `esc to cancel`
2. **等待输入** = 最后 10 行日志包含 `Type your message` 或 `YOLO mode` 或 `shift + tab to cycle`
3. **任务完成** = 不在进行中 **且** 在等待输入

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

## 📖 相关文档

- [tmux-sub-agent.sh](../scripts/tmux-sub-agent.sh) - Sub Agent 启动脚本
- [tmux-auto-agent.sh](../scripts/tmux-auto-agent.sh) - Auto Agent 启动脚本
- [auto-watch-sub.sh](../scripts/auto-watch-sub.sh) - 子进程监视器
- [check-sub-status.sh](../scripts/check-sub-status.sh) - 状态检查脚本
- [settings.json](../settings.json) - 全局配置文件

---

*最后更新：2026-04-01*
*版本：v1.0*
