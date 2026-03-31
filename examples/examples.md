# 使用示例

本文档提供了一些常见的使用示例，帮助你快速上手 Qwen Code Sub/Auto Agent 系统。

---

## 📐 基础示例

### 1. 打印数字

```bash
# 打印 1 到 100
bash scripts/tmux-sub-agent.sh qwen-sub-print "用 Python 打印 1 到 100"

# 查看结果
cat ~/print_1_to_100.py
python ~/print_1_to_100.py
```

### 2. 数学计算

```bash
# 查找质数
bash scripts/tmux-sub-agent.sh qwen-sub-prime "找到 1000 以内的所有质数，统计总数"

# 查看结果
cat ~/primes_under_1000.txt

# 查找最大质数
bash scripts/tmux-sub-agent.sh qwen-sub-maxprime "找到 10000 以内的最大质数"

# 查看结果
cat ~/max_prime_under_10000.txt
```

### 3. 文件操作

```bash
# 创建文件
bash scripts/tmux-sub-agent.sh qwen-sub-create "创建一个包含 1 到 20 的文本文件"

# 查看结果
cat ~/numbers_1_to_20.txt
```

---

## 🔍 搜索和研究

### 4. 搜索 AI 新闻

```bash
# 搜索最新 AI 新闻
bash scripts/tmux-sub-agent.sh qwen-sub-ainews "搜索最新的 AI 新闻，整理成报告"

# 等待通知后查看报告
cat ~/ai_news_report.md
```

### 5. 技术调研

```bash
# 调研 GNN（图神经网络）
bash scripts/tmux-sub-agent.sh qwen-sub-gnn "查找 GNN 的介绍和应用，整理成 Markdown 报告"

# 查看报告
cat ~/gnn_introduction.md
```

### 6. 代码文档生成

```bash
# 为项目生成文档
bash scripts/tmux-sub-agent.sh qwen-sub-docs "分析当前项目的代码结构，生成技术文档"

# 查看文档
cat ~/project_documentation.md
```

---

## 💻 代码相关

### 7. 代码分析

```bash
# 分析代码复杂度
bash scripts/tmux-sub-agent.sh qwen-sub-analyze "分析 src/ 目录下所有 Python 文件的复杂度"

# 查看分析报告
cat ~/code_analysis_report.md
```

### 8. 代码重构

```bash
# 重构代码
bash scripts/tmux-sub-agent.sh qwen-sub-refactor "重构 utils.py 文件，优化代码结构"

# 查看重构后的代码
cat ~/utils_refactored.py
```

### 9. 测试生成

```bash
# 生成单元测试
bash scripts/tmux-sub-agent.sh qwen-sub-test "为 calculator.py 生成单元测试"

# 查看测试文件
cat ~/test_calculator.py
```

---

## 📊 数据处理

### 10. 数据转换

```bash
# CSV 转 JSON
bash scripts/tmux-sub-agent.sh qwen-sub-convert "将 data.csv 转换为 data.json"

# 查看结果
cat ~/data.json
```

### 11. 数据统计

```bash
# 统计数据
bash scripts/tmux-sub-agent.sh qwen-sub-stats "分析 sales_data.csv 并生成统计报告"

# 查看报告
cat ~/sales_statistics.md
```

---

## 🤖 Auto Agent 示例（完全自主模式）

### 12. 项目分析

```bash
# 完全自主分析项目
bash scripts/tmux-auto-agent.sh qwen-auto-analysis "完全自主分析当前项目的架构和依赖关系"

# 等待通知后查看报告
cat ~/project_analysis.md
```

### 13. 代码优化

```bash
# 自主优化代码
bash scripts/tmux-auto-agent.sh qwen-auto-optimize "自主优化项目性能，找出瓶颈并提供改进建议"

# 查看优化报告
cat ~/optimization_report.md
```

---

## 🎯 高级用法

### 14. 多任务并行

```bash
# 同时启动多个子进程
bash scripts/tmux-sub-agent.sh qwen-sub-task1 "任务 1 描述" &
bash scripts/tmux-sub-agent.sh qwen-sub-task2 "任务 2 描述" &
bash scripts/tmux-sub-agent.sh qwen-sub-task3 "任务 3 描述" &

# 查看所有任务状态
bash scripts/check-sub-status.sh

# 等待所有任务完成后查看结果
```

### 15. 链式任务

```bash
# 任务 1：获取数据
bash scripts/tmux-sub-agent.sh qwen-sub-fetch "获取 API 数据并保存"

# 等待完成后...

# 任务 2：处理数据
bash scripts/tmux-sub-agent.sh qwen-sub-process "处理获取的数据并生成报告"

# 等待完成后...

# 任务 3：可视化
bash scripts/tmux-sub-agent.sh qwen-sub-viz "为处理后的数据生成可视化图表"
```

---

## 📋 管理命令示例

### 查看状态

```bash
# 查看所有子进程状态
bash scripts/check-sub-status.sh

# 查看警报通知
cat ~/.qwen/sub_alerts.txt

# 查看状态跟踪
cat ~/.qwen/sub_state.json
```

### 会话管理

```bash
# 列出所有 tmux 会话
tmux list-sessions | grep "qwen-"

# 连接特定会话
tmux attach -t qwen-sub-task1

# 查看日志
tail -f ~/.qwen/logs/qwen-sub-task1_*.log

# 删除会话
tmux kill-session -t qwen-sub-task1
```

### 监视器管理

```bash
# 启动监视器
nohup bash scripts/auto-watch-sub.sh 5 >> ~/.qwen/logs/watcher.log 2>&1 &

# 检查监视器状态
ps aux | grep "auto-watch-sub"

# 查看监视器日志
tail -f ~/.qwen/logs/watcher.log

# 停止监视器
pkill -f "auto-watch-sub.sh"
```

### 清理命令

```bash
# 清理所有已完成的子进程
for session in $(cat ~/.qwen/sub_state.json | grep -o '"qwen-sub[^"]*"' | tr -d '"'); do
    tmux kill-session -t "$session" 2>/dev/null
done

# 重置状态
echo "{}" > ~/.qwen/sub_state.json
> ~/.qwen/sub_alerts.txt
```

---

## 💡 最佳实践

1. **命名规范**: 使用有意义的会话名称，如 `qwen-sub-prime` 而不是 `qwen-sub-1`

2. **任务分解**: 将大任务分解为多个小任务，并行执行

3. **定期检查**: 使用 `check-sub-status.sh` 定期检查任务状态

4. **日志管理**: 定期清理旧的日志文件

5. **资源监控**: 注意系统资源使用，避免同时运行过多子进程

---

## 🐛 故障排除示例

### 问题：收不到通知

```bash
# 1. 检查监视器是否运行
ps aux | grep "auto-watch-sub"

# 2. 查看监视器日志
tail -f ~/.qwen/logs/watcher.log

# 3. 重启监视器
pkill -f "auto-watch-sub.sh"
nohup bash scripts/auto-watch-sub.sh 5 >> ~/.qwen/logs/watcher.log 2>&1 &
```

### 问题：子进程卡住

```bash
# 1. 查看日志
tail -100 ~/.qwen/logs/qwen-sub-task_*.log

# 2. 连接会话查看
tmux attach -t qwen-sub-task

# 3. 必要时删除会话
tmux kill-session -t qwen-sub-task
```

---

*最后更新：2026-04-01*
