# Sub/Auto Agent 消息通知系统架构

## 📐 系统架构图

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           用户 (User)                                    │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┼───────────────┐
                    │               │               │
                    ▼               ▼               ▼
        ┌───────────────┐  ┌───────────────┐  ┌──────────────┐
        │  启动 Sub 任务   │  │  启动 Auto 任务 │  │  查看通知    │
        │  (sub 命令)     │  │  (auto 命令)    │  │  (状态文件)  │
        └───────────────┘  └───────────────┘  └──────────────┘
                │                   │                   │
                ▼                   ▼                   │
    ┌───────────────────────────────────────────┐       │
    │      tmux-sub-agent.sh /                  │       │
    │      tmux-auto-agent.sh                   │       │
    └───────────────────────────────────────────┘       │
                │                                       │
                ▼                                       │
    ┌───────────────────────────────────────────────────┤
    │              tmux Session Manager                 │
    │  ┌─────────────────┐   ┌─────────────────┐       │
    │  │ qwen-sub-*      │   │ qwen-auto-*     │       │
    │  │ (后台子进程)     │   │ (自主进程)       │       │
    │  └─────────────────┘   └─────────────────┘       │
    └───────────────────────────────────────────────────┤
                │                   │                   │
                ▼                   ▼                   │
    ┌───────────────────────────────────────────────────┤
    │              日志文件 (logs/)                     │
    │  - qwen-sub-*.log                                 │
    │  - qwen-auto-*.log                                │
    └───────────────────────────────────────────────────┤
                            │                           │
                            ▼                           │
                ┌───────────────────────┐               │
                │  auto-watch-sub.sh    │               │
                │  (监视器，每 5 秒检查)   │◄──────────────┘
                └───────────────────────┘
                            │
                ┌───────────┼───────────┐
                │           │           │
                ▼           ▼           ▼
    ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
    │ 检测逻辑     │ │ 状态更新     │ │ 通知发送     │
    │              │ │              │ │              │
    │ • 运行中     │ │ sub_state.   │ │ tmux display │
    │ • 等待输入   │ │ json         │ │ -message     │
    │ • 已完成     │ │ sub_alerts.  │ │ (3 秒黄色)    │
    └──────────────┘ └──────────────┘ └──────────────┘
```

---

## 🔄 数据流

### 1. 任务启动流程
```
用户命令
    │
    ▼
tmux-sub-agent.sh
    │
    ├─► 创建 tmux 会话 (qwen-sub-*)
    │
    ├─► 启动 qwen 进程 (YOLO 模式)
    │
    ├─► 初始化日志文件
    │
    ├─► 初始化进展文件
    │
    └─► 启动监视器 (auto-watch-sub.sh)
            │
            └─► 后台循环 (每 5 秒)
                    │
                    ▼
                检查所有 qwen 会话
```

### 2. 状态检测流程
```
监视器循环
    │
    ▼
读取会话日志最后 10 行
    │
    ├─ 有 "esc to cancel"?
    │       │
    │       YES ──► 任务进行中 ──► 跳过
    │       NO
    │       │
    ▼
    ├─ 有 "Type your message" / "YOLO mode"?
    │       │
    │       NO ──► 不在等待输入 ──► 跳过
    │       YES
    │       │
    ▼
    └─ 任务完成且等待输入 ──► 发送通知
```

### 3. 通知发送流程
```
检测到任务完成
    │
    ▼
检查 sub_state.json
    │
    ├─ 已标记为 true?
    │       │
    │       YES ──► 已通知过 ──► 跳过
    │       NO
    │       │
    ▼
写入 sub_alerts.txt
    │
    ▼
更新 sub_state.json (标记为 true)
    │
    ▼
发送 tmux 状态行消息
    │
    ├─ 目标：非 qwen 会话
    ├─ 格式：#[fg=yellow,bold]⚠️ {session} 任务完成，等待输入!
    └─ 持续时间：3000ms
    │
    ▼
记录到 watcher.log
```

---

## 📁 文件系统

```
/home/wuyangcheng/.qwen/
│
├── settings.json                 # 全局配置（包含 subAgentNotification）
├── SUB_AUTO_QUICK_REFERENCE.md   # 快速参考文档
│
├── skills/
│   └── sub_agent.md              # Sub/Auto Agent 技能文档
│
├── scripts/
│   ├── tmux-sub-agent.sh         # Sub Agent 启动脚本
│   ├── tmux-auto-agent.sh        # Auto Agent 启动脚本
│   ├── auto-watch-sub.sh         # 子进程监视器（核心）
│   ├── check-sub-status.sh       # 状态检查脚本
│   ├── send-notification.sh      # 通知发送脚本
│   └── ...
│
├── logs/
│   ├── qwen-sub-*.log            # Sub Agent 日志
│   ├── qwen-auto-*.log           # Auto Agent 日志
│   └── watcher.log               # 监视器运行日志
│
├── progress/
│   ├── qwen-sub-*.txt            # Sub Agent 进展文件
│   └── qwen-auto-*.txt           # Auto Agent 进展文件
│
├── sub_status.txt                # 实时子进程状态（由 check-sub-status.sh 生成）
├── sub_alerts.txt                # 通知历史记录
└── sub_state.json                # 已通知会话跟踪
```

---

## 🔧 核心组件

### 1. tmux-sub-agent.sh
**功能**: 启动 Sub Agent 子进程
- 创建 tmux 会话
- 启动 qwen 进程（YOLO 模式）
- 初始化日志和进展文件
- 自动启动监视器

**关键参数**:
- `SESSION_NAME`: 会话名称（如 qwen-sub-task）
- `TASK`: 任务描述
- `LOG_FILE`: 日志文件路径
- `PROGRESS_FILE`: 进展文件路径

### 2. auto-watch-sub.sh
**功能**: 后台监督所有子进程
- 每 5 秒检查一次所有 qwen 会话
- 检测任务状态（进行中/等待输入/已完成）
- 发送 tmux 状态行通知
- 更新状态跟踪文件

**检测逻辑**:
```bash
# 任务进行中
tail -10 $LOG_FILE | grep -q "esc to cancel"

# 等待输入
tail -10 $LOG_FILE | grep -qE "Type your message|YOLO mode|shift \+ tab"

# 任务完成
! 进行中 && 等待输入
```

### 3. check-sub-status.sh
**功能**: 检查并显示子进程状态
- 扫描所有 tmux qwen 会话
- 分析每个会话的日志
- 生成状态报告到 sub_status.txt

**输出格式**:
```
═══════════════════════════════════════════════════
  子进程状态
═══════════════════════════════════════════════════
  qwen-sub-task:                    ⏳ 等待输入
  qwen-auto-analysis:               🔄 运行中
───────────────────────────────────────────────────
  统计：1 运行中 | 1 等待输入 | 0 已完成
═══════════════════════════════════════════════════
```

---

## ⚙️ 配置参数

### settings.json - subAgentNotification
```json
{
  "enabled": true,                    // 启用通知系统
  "watcherScript": "...",             // 监视器脚本路径
  "statusFile": "...",                // 状态文件路径
  "alertsFile": "...",                // 警报文件路径
  "stateFile": "...",                 // 状态跟踪文件路径
  "logDir": "...",                    // 日志目录
  "progressDir": "...",               // 进展文件目录
  "refreshInterval": 5,               // 刷新间隔（秒）
  "notificationDuration": 3000,       // 通知持续时间（毫秒）
  "detectionLogic": {                 // 检测逻辑
    "taskInProgress": "最后 10 行包含 'esc to cancel'",
    "waitingForInput": "最后 10 行包含 'Type your message' 或 'YOLO mode'",
    "taskCompleted": "不在进行中 且 在等待输入"
  },
  "notificationMethod": "tmux display-message 状态行消息（黄色，持续 3 秒）",
  "notificationFormat": "⚠️  {session} 任务完成，等待输入!"
}
```

---

## 🎯 状态码说明

### 子进程状态
| 图标 | 状态 | 说明 | 检测条件 |
|------|------|------|----------|
| 🔄 | 运行中 | 任务正在执行 | 最后 10 行包含 `esc to cancel` |
| ⏳ | 等待输入 | 等待用户输入 | 最后 10 行包含 `Type your message` 等 |
| ✅ | 已完成 | 任务完成且已通知 | sub_state.json 中标记为 `true` |

### 通知类型
| 类型 | 格式 | 持续时间 | 目标 |
|------|------|----------|------|
| tmux 状态行 | `#[fg=yellow,bold]⚠️ {session} 任务完成，等待输入!` | 3 秒 | 非 qwen 会话 |
| 警报文件 | `[{timestamp}] ⚠️  会话 '{session}' 任务完成，等待输入中...` | 持久 | - |

---

## 📊 性能指标

| 指标 | 值 | 说明 |
|------|-----|------|
| 监视器刷新间隔 | 5 秒 | 每 5 秒检查一次所有子进程 |
| 通知延迟 | < 5 秒 | 任务完成后最多 5 秒内发送通知 |
| 通知持续时间 | 3 秒 | tmux 状态行消息显示 3 秒 |
| 日志检测行数 | 10 行 | 只检查最后 10 行日志 |
| 内存占用 | < 5MB | 监视器进程内存占用 |

---

## 🔐 安全限制

- ❌ 禁止使用 `rm`、`rmdir` 等删除命令
- ❌ 禁止安装包（需用户确认）
- ✅ 允许文件操作（创建、修改、移动、复制）
- ✅ 允许代码执行
- ✅ 允许网络访问（搜索、抓取）

---

*文档版本：v1.0*
*最后更新：2026-04-01*
