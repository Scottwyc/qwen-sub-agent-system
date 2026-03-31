# GitHub 推送指南

## 📤 推送到 GitHub 的步骤

### 步骤 1：在 GitHub 上创建新仓库

1. 访问 [GitHub New Repository](https://github.com/new)
2. 填写以下信息：
   - **Repository name**: `qwen-sub-agent-system`
   - **Description**: `Qwen Code Sub/Auto Agent 消息通知系统 - 在 tmux 中后台运行子进程，主进程继续与用户交流`
   - **Visibility**: ✅ Public (公开)
   - **Initialize this repository with**: 
     - ❌ 不要勾选 "Add a README file"
     - ❌ 不要勾选 "Add .gitignore"
     - ❌ 不要勾选 "Choose a license"
3. 点击 **Create repository**

### 步骤 2：添加远程仓库

在终端中运行以下命令（**替换 `YOUR_USERNAME` 为你的 GitHub 用户名**）：

```bash
cd /home/wuyangcheng/qwen-sub-agent-system
git remote add origin git@github.com:YOUR_USERNAME/qwen-sub-agent-system.git
```

**或者使用 HTTPS**（如果你没有配置 SSH 密钥）：

```bash
cd /home/wuyangcheng/qwen-sub-agent-system
git remote add origin https://github.com/YOUR_USERNAME/qwen-sub-agent-system.git
```

### 步骤 3：推送到 GitHub

```bash
git push -u origin main
```

如果是第一次推送，可能需要输入 GitHub 用户名和密码（或 Personal Access Token）。

### 步骤 4：验证推送

访问你的仓库页面：
```
https://github.com/YOUR_USERNAME/qwen-sub-agent-system
```

确认所有文件都已成功推送。

---

## 🔧 常见问题

### 问题 1：Permission denied (publickey)

**原因**: 未配置 SSH 密钥

**解决方案**:

1. 生成 SSH 密钥（如果还没有）：
   ```bash
   ssh-keygen -t ed25519 -C "your_email@example.com"
   ```

2. 将公钥添加到 GitHub：
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
   复制输出内容，然后访问：https://github.com/settings/keys → New SSH key

3. 测试连接：
   ```bash
   ssh -T git@github.com
   ```

### 问题 2：remote: Repository not found

**原因**: 仓库不存在或用户名错误

**解决方案**:
- 确认已在 GitHub 上创建仓库
- 检查用户名是否正确
- 确认仓库可见性设置为 Public

### 问题 3：Authentication failed

**原因**: 认证失败

**解决方案**:

1. 使用 Personal Access Token（推荐）：
   - 访问：https://github.com/settings/tokens
   - 生成新 token（勾选 `repo` 权限）
   - 推送时使用 token 作为密码

2. 或者配置 SSH（见问题 1）

---

## 📊 仓库结构

推送后的仓库结构应该如下：

```
qwen-sub-agent-system/
├── README.md                     # 项目说明文档
├── LICENSE                       # MIT 许可证
├── .gitignore                    # Git 忽略文件
├── scripts/                      # 核心脚本
│   ├── tmux-sub-agent.sh         # Sub Agent 启动
│   ├── tmux-auto-agent.sh        # Auto Agent 启动
│   ├── auto-watch-sub.sh         # 监视器（核心）
│   ├── check-sub-status.sh       # 状态检查
│   └── send-notification.sh      # 通知发送
├── docs/                         # 文档
│   ├── sub_agent.md              # 完整技能文档
│   ├── SUB_AUTO_QUICK_REFERENCE.md # 快速参考
│   └── SUB_AUTO_ARCHITECTURE.md  # 系统架构
├── config/                       # 配置
│   ├── settings.json             # 配置模板
│   └── install.sh                # 安装脚本
└── examples/                     # 示例
    └── examples.md               # 使用示例
```

---

## 🚀 后续步骤

### 1. 更新 README

在 GitHub 仓库页面编辑 README.md，添加：

- 你的 GitHub 用户名
- 正确的仓库 URL
- 安装说明中的路径

### 2. 添加主题标签

在 GitHub 仓库设置中添加以下 topics：
- `qwen-code`
- `tmux`
- `subprocess`
- `notification`
- `bash`
- `cli-tool`

### 3. 分享你的项目

- 在 Qwen Code 社区分享
- 发布到 Twitter/LinkedIn
- 添加到相关 Awesome 列表

---

## 📝 快速推送命令

```bash
# 完整推送流程（替换 YOUR_USERNAME）
cd /home/wuyangcheng/qwen-sub-agent-system
git remote add origin git@github.com:YOUR_USERNAME/qwen-sub-agent-system.git
git push -u origin main

# 查看推送状态
git remote -v
git branch -a
```

---

## 🔗 相关资源

- [GitHub Docs: Creating a new repository](https://docs.github.com/en/repositories/creating-and-managing-repositories/creating-a-new-repository)
- [GitHub Docs: Pushing to a remote repository](https://docs.github.com/en/get-started/using-git/pushing-commits-to-a-remote-repository)
- [GitHub Docs: Managing remote repositories](https://docs.github.com/en/desktop/contributing-and-collaborating-using-github-desktop/managing-remotes)

---

*最后更新：2026-04-01*
