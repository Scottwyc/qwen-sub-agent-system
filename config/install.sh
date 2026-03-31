#!/bin/bash
# Qwen Code Sub/Auto Agent 系统安装脚本
# 用法：./install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
QWEN_DIR="$HOME/.qwen"

echo "═══════════════════════════════════════════════════════════"
echo "  Qwen Code Sub/Auto Agent 系统安装"
echo "═══════════════════════════════════════════════════════════"
echo ""

# 检查 tmux
if ! command -v tmux &> /dev/null; then
    echo "❌ 错误：未找到 tmux"
    echo "   请先安装 tmux: sudo apt-get install tmux (Ubuntu/Debian)"
    echo "                或：brew install tmux (macOS)"
    exit 1
fi
echo "✅ tmux 已安装：$(tmux -V)"

# 检查 bash 版本
BASH_VERSION=$(bash --version | head -n1 | cut -d' ' -f4 | cut -d'(' -f1)
echo "✅ bash 版本：$BASH_VERSION"

# 创建 .qwen 目录（如果不存在）
if [ ! -d "$QWEN_DIR" ]; then
    echo "📁 创建 .qwen 目录..."
    mkdir -p "$QWEN_DIR"/{scripts,logs,progress}
fi

# 复制脚本文件
echo ""
echo "📋 复制脚本文件到 $QWEN_DIR/scripts/..."
cp "$PROJECT_ROOT/scripts/"*.sh "$QWEN_DIR/scripts/"
chmod +x "$QWEN_DIR/scripts/"*.sh
echo "✅ 脚本文件已复制"

# 复制配置文件
echo ""
echo "📋 复制配置文件..."
if [ -f "$QWEN_DIR/settings.json" ]; then
    echo "⚠️  settings.json 已存在，创建备份..."
    cp "$QWEN_DIR/settings.json" "$QWEN_DIR/settings.json.bak.$(date +%Y%m%d_%H%M%S)"
fi

# 合并配置（保留用户的 API 密钥等个人配置）
if [ -f "$PROJECT_ROOT/config/settings.json" ]; then
    echo "📝 更新配置..."
    # 这里可以添加更复杂的配置合并逻辑
    # 简单起见，我们只复制 subAgentNotification 部分
    cp "$PROJECT_ROOT/config/settings.json" "$QWEN_DIR/settings.json.sub_agent_template"
    echo "✅ 配置模板已保存：$QWEN_DIR/settings.json.sub_agent_template"
    echo "   请手动将此文件中的 subAgentNotification 部分合并到您的 settings.json"
fi

# 创建必要的文件
echo ""
echo "📋 创建必要的文件..."
touch "$QWEN_DIR/sub_alerts.txt"
echo "{}" > "$QWEN_DIR/sub_state.json"
echo "✅ 文件已创建"

# 启动监视器
echo ""
echo "🚀 启动子进程监视器..."
pkill -f "auto-watch-sub.sh" 2>/dev/null || true
nohup bash "$QWEN_DIR/scripts/auto-watch-sub.sh" 5 >> "$QWEN_DIR/logs/watcher.log" 2>&1 &
WATCHER_PID=$!
sleep 2

if ps -p $WATCHER_PID > /dev/null; then
    echo "✅ 监视器已启动 (PID: $WATCHER_PID)"
else
    echo "❌ 警告：监视器启动失败"
fi

# 验证安装
echo ""
echo "🔍 验证安装..."
bash "$QWEN_DIR/scripts/check-sub-status.sh"

echo ""
echo "═══════════════════════════════════════════════════════════"
echo "  ✅ 安装完成！"
echo "═══════════════════════════════════════════════════════════"
echo ""
echo "📚 使用说明："
echo "  1. 启动 Sub Agent:"
echo "     bash $QWEN_DIR/scripts/tmux-sub-agent.sh qwen-sub-task \"你的任务\""
echo ""
echo "  2. 查看通知:"
echo "     cat $QWEN_DIR/sub_alerts.txt"
echo ""
echo "  3. 查看状态:"
echo "     bash $QWEN_DIR/scripts/check-sub-status.sh"
echo ""
echo "  4. 查看完整文档:"
echo "     cat $PROJECT_ROOT/docs/sub_agent.md"
echo ""
echo "═══════════════════════════════════════════════════════════"
