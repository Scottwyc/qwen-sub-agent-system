# Sub/Auto Agent 快速参考

## 🚀 一键启动

```bash
# Sub Agent
bash /home/wuyangcheng/.qwen/scripts/tmux-sub-agent.sh qwen-sub-<name> "<任务>"

# Auto Agent
bash /home/wuyangcheng/.qwen/scripts/tmux-auto-agent.sh qwen-auto-<name> "<任务>"
```

## 📡 查看通知

```bash
# 查看警报
cat /home/wuyangcheng/.qwen/sub_alerts.txt

# 查看状态
bash /home/wuyangcheng/.qwen/scripts/check-sub-status.sh

# 查看状态跟踪
cat /home/wuyangcheng/.qwen/sub_state.json
```

## 🔍 管理会话

```bash
# 列出所有 qwen 会话
tmux list-sessions | grep "qwen-"

# 连接会话
tmux attach -t qwen-sub-<name>

# 查看日志
tail -f /home/wuyangcheng/.qwen/logs/qwen-sub-<name>_*.log

# 删除会话
tmux kill-session -t qwen-sub-<name>
```

## 🛠️ 管理监视器

```bash
# 启动监视器
nohup bash /home/wuyangcheng/.qwen/scripts/auto-watch-sub.sh 5 >> /home/wuyangcheng/.qwen/logs/watcher.log 2>&1 &

# 检查状态
ps aux | grep "auto-watch-sub"

# 停止监视器
pkill -f "auto-watch-sub.sh"

# 查看日志
tail -f /home/wuyangcheng/.qwen/logs/watcher.log
```

## 🧹 清理命令

```bash
# 清理所有已完成的子进程
for session in $(cat /home/wuyangcheng/.qwen/sub_state.json | grep -o '"qwen-sub[^"]*"' | tr -d '"'); do
    tmux kill-session -t "$session" 2>/dev/null
done
echo "{}" > /home/wuyangcheng/.qwen/sub_state.json
> /home/wuyangcheng/.qwen/sub_alerts.txt
```

## 📊 检测逻辑

| 状态 | 检测条件 |
|------|----------|
| 🔄 运行中 | 最后 10 行包含 `esc to cancel` |
| ⏳ 等待输入 | 最后 10 行包含 `Type your message` / `YOLO mode` |
| ✅ 已完成 | 不在进行中 且 在等待输入 → 发送通知 |

## 📁 关键文件

| 文件 | 用途 |
|------|------|
| `/home/wuyangcheng/.qwen/sub_alerts.txt` | 通知记录 |
| `/home/wuyangcheng/.qwen/sub_state.json` | 已通知会话跟踪 |
| `/home/wuyangcheng/.qwen/sub_status.txt` | 实时状态 |
| `/home/wuyangcheng/.qwen/logs/watcher.log` | 监视器日志 |

## ⚙️ 配置参数

- 刷新间隔：5 秒
- 通知持续时间：3 秒
- 通知格式：`⚠️  {session} 任务完成，等待输入!`
