# SafeExec 技术实现说明

**版本:** 0.3.3
**日期:** 2026-02-27
**目的:** 回应ClawHub安全审查，澄清实际的技术实现

---

## 1. 命令拦截机制

### ✅ SafeExec是一个Wrapper，不是Shell Hook

**SafeExec不是系统级拦截器，不会：**
- ❌ 修改 `~/.bashrc`
- ❌ 修改 `~/.profile`
- ❌ 修改 `/etc` 文件
- ❌ 安装 `PROMPT_COMMAND` 钩子
- ❌ 安装 `DEBUG` trap
- ❌ 创建daemon或后台进程
- ❌ 修改shell启动文件

**SafeExec实际工作方式：**

1. **Agent主动调用** - Agent或用户必须显式调用：
   ```bash
   safe-exec.sh "要执行的命令"
   ```

2. **风险检测** - 脚本分析命令字符串，使用正则表达式检测危险模式：
   ```bash
   # 示例：检测 rm -rf
   if echo "$command" | grep -qE "rm\s+-rf?\s+/?"; then
       risk="critical"
   fi
   ```

3. **决策流程**：
   - **LOW风险** → 直接执行（记录审计日志）
   - **MEDIUM/HIGH/CRITICAL** → 创建批准请求，等待用户确认

4. **执行或等待**：
   - **非Agent模式**：显示终端提示，等待用户运行 `safe-exec-approve <id>`
   - **Agent模式**（检测到`OPENCLAW_AGENT_CALL`）：
     - LOW/MEDIUM：直接执行（记录为`agent_auto`）
     - HIGH/CRITICAL：仍然请求批准（Agent无法自动确认）

### 证据：无Hook安装

```bash
# 验证：grep脚本中无hook相关代码
$ grep -i "hook\|\.bashrc\|\.profile\|PROMPT_COMMAND\|DEBUG trap" \
    ~/.openclaw/skills/safe-exec/safe-exec.sh
# (无输出 = 无hook)
```

---

## 2. Agent模式自动批准

### 环境变量控制

| 环境变量 | 设置者 | 作用 | 风险级别 |
|---------|--------|------|----------|
| `OPENCLAW_AGENT_CALL` | OpenClaw框架 | 标识Agent调用 | ⚠️ 中等 |
| `SAFE_EXEC_AUTO_CONFIRM` | 用户手动设置 | 允许LOW/MEDIUM自动执行 | ⚠️ 中等 |

### ⚠️ 安全建议

**仅对可信Agent启用自动确认：**

1. **审查Agent配置** - 确保Agent不会意外执行危险命令
2. **定期检查审计日志** - 查看哪些命令被标记为`agent_auto`
3. **测试环境优先** - 在非生产系统上测试新Agent

**查看审计日志：**
```bash
# 查看所有Agent自动执行的命令
grep "agent_auto" ~/.openclaw/safe-exec-audit.log

# 查看最近的高风险命令
grep '"risk":"high"' ~/.openclaw/safe-exec-audit.log | tail -20
```

---

## 3. Eval使用分析

### ✅ Eval仅用于批准后的命令执行

**在 `safe-exec-approve.sh` 中：**
```bash
command=$(jq -r '.command' "$request_file")
eval "$command"  # 执行用户批准的命令
```

**风险评估：**
- ✅ **预期用途** - 执行用户已经审查并明确批准的命令
- ✅ **输入来源** - 从pending文件读取，这些文件由safe-exec.sh创建
- ⚠️ **潜在风险** - 如果pending文件被篡改，可能执行恶意命令

**缓解措施：**
1. **文件权限** - 确保 `~/.openclaw/safe-exec/` 目录权限正确：
   ```bash
   chmod 700 ~/.openclaw/safe-exec/
   chmod 600 ~/.openclaw/safe-exec/pending/*.json
   ```

2. **审计日志** - 所有执行的命令都会记录，包括请求ID

3. **短期文件** - Pending请求在5分钟后过期（`REQUEST_TIMEOUT=300`）

---

## 4. jq依赖验证

### 验证jq是否已安装

```bash
# 检查jq是否在PATH中
which jq

# 如果未安装，安装jq
sudo apt-get install jq  # Debian/Ubuntu
brew install jq          # macOS
```

### 为什么需要jq？

SafeExec使用jq进行：
- JSON配置文件解析（`~/.openclaw/safe-exec-rules.json`）
- Pending请求文件解析
- 审计日志JSON格式化

**无jq时行为：**
- 大部分功能仍可工作（风险检测、命令执行）
- 自定义规则功能受限（无法解析JSON配置）

---

## 5. 审计日志内容

### 日志位置
```bash
~/.openclaw/safe-exec-audit.log
```

### 日志格式
```json
{
  "timestamp": "2026-02-27T12:00:00+08:00",
  "event": "allowed",
  "data": {
    "command": "rm -rf /tmp/test",
    "risk": "high",
    "mode": "user_approved",
    "requestId": "req_1769938492_9730"
  }
}
```

### ⚠️ 隐私说明

**审计日志包含：**
- ✅ 命令字符串
- ✅ 风险等级
- ✅ 执行模式（user_approved / agent_auto）
- ✅ 时间戳
- ✅ 请求ID

**审计日志不包含：**
- ❌ 用户聊天内容
- ❌ 会话历史
- ❌ 环境变量值（除非在USER_CONTEXT中显式传递）

**注意：** 如果使用 `SAFEXEC_CONTEXT` 传递用户聊天上下文，该上下文会被记录在审计日志的"reason"字段中。

---

## 6. 实际使用示例

### 场景1：用户手动执行

```bash
# 用户请求Agent删除文件
User: "删除 /tmp/test 下的所有文件"

# Agent调用safe-exec
Agent: safe-exec.sh "rm -rf /tmp/test"

# SafeExec检测到HIGH风险，创建pending请求
# 显示终端提示
🚨 **Dangerous Operation Detected**
**Risk Level:** HIGH
**Command:** `rm -rf /tmp/test`
**Request ID:** req_1769938492_9730

# 用户批准
$ safe-exec-approve req_1769938492_9730
✅ 执行命令: rm -rf /tmp/test

# 记录审计日志
{"timestamp":"...","event":"executed","data":{"requestId":"req_1769938492_9730"}}
```

### 场景2：Agent自动执行（LOW/MEDIUM风险）

```bash
# Agent设置（由OpenClaw自动设置）
export OPENCLAW_AGENT_CALL=1

# Agent执行LOW风险命令
Agent: safe-exec.sh "ls -la /tmp"

# SafeExec检测到LOW风险，直接执行
# 记录审计日志
{"timestamp":"...","event":"allowed","data":{"command":"ls -la /tmp","risk":"low","mode":"agent_auto"}}
```

### 场景3：Agent尝试HIGH/CRITICAL风险（仍需批准）

```bash
# Agent设置
export OPENCLAW_AGENT_CALL=1

# Agent尝试HIGH风险命令
Agent: safe-exec.sh "rm -rf /important/data"

# SafeExec检测到HIGH风险，即使Agent模式也请求批准
# 创建pending请求，等待用户手动批准
```

---

## 7. 安装和卸载

### 安装

```bash
# 方法1：通过ClawHub（推荐）
Help me install SafeExec from ClawHub

# 方法2：手动克隆
git clone https://github.com/OTTTTTO/safe-exec.git ~/.openclaw/skills/safe-exec
chmod +x ~/.openclaw/skills/safe-exec/safe-exec*.sh
```

### 完全卸载

```bash
# 停用SafeExec
safe-exec.sh --disable

# 删除文件
rm -rf ~/.openclaw/skills/safe-exec
rm -f ~/.local/bin/safe-exec*
rm -f ~/.openclaw/safe-exec-rules.json
rm -f ~/.openclaw/safe-exec-audit.log
rm -rf ~/.openclaw/safe-exec/
```

**验证卸载：**
```bash
# 确认无残留hook
grep -r "safe-exec" ~/.bashrc ~/.profile ~/.zshrc 2>/dev/null
# (应该无输出)
```

---

## 8. Metadata一致性声明

### 当前SKILL.md Metadata (v0.3.3)

```yaml
metadata:
  openclaw:
    env:
      - SAFE_EXEC_DISABLE        # 全局禁用开关
      - OPENCLAW_AGENT_CALL      # Agent模式标识（OpenClaw设置）
      - SAFEXEC_CONTEXT          # 用户上下文（可选）
      - SAFE_EXEC_AUTO_CONFIRM   # 自动确认LOW/MEDIUM（用户设置）
    writes:
      - ~/.openclaw/safe-exec/           # Pending请求目录
      - ~/.openclaw/safe-exec-audit.log  # 审计日志
    network: false              # 无网络调用（除git clone安装时）
    monitoring: false           # 无监控功能
    credentials: []             # 无需凭证
  requires:
    bins:
      - jq                      # JSON解析工具
  install:
    - id: git
      kind: git
      url: https://github.com/OTTTTTO/safe-exec.git
      label: Clone from GitHub
```

### ✅ 与实际实现一致

| 声明 | 实际 | 验证 |
|------|------|------|
| `env: [SAFE_EXEC_DISABLE, ...]` | ✅ 脚本读取这些变量 | `grep "SAFE_EXEC_DISABLE" safe-exec.sh` |
| `writes: [~/.openclaw/safe-exec/]` | ✅ 创建pending目录 | `ls ~/.openclaw/safe-exec/` |
| `network: false` | ✅ 无curl/wget调用 | `grep -E "curl|wget|http" safe-exec.sh` (仅注释中) |
| `monitoring: false` | ✅ 无监控代码 | 已移除unified-monitor组件 |
| `credentials: []` | ✅ 无API密钥使用 | 无Feishu/GitHub token使用 |
| `requires.bins: [jq]` | ✅ 使用jq解析JSON | `jq -r '.command'` 等 |

---

## 9. 安全检查清单

### 安装前检查 ✅

- [x] **验证Git仓库** - https://github.com/OTTTTTO/safe-exec
- [x] **检查commit历史** - 无可疑提交
- [x] **审查主脚本** - `safe-exec.sh` 无恶意代码
- [x] **确认无hook安装** - 不修改shell启动文件
- [x] **理解Agent模式** - `OPENCLAW_AGENT_CALL` 风险和用法
- [x] **验证jq依赖** - 已安装或在PATH中
- [x] **测试环境** - 先在VM或非生产系统测试

### 运行时检查 ✅

- [x] **审查审计日志** - 定期检查 `~/.openclaw/safe-exec-audit.log`
- [x] **监控pending请求** - 确认无异常积压
- [x] **文件权限** - 确保 `~/.openclaw/safe-exec/` 权限为700
- [x] **Agent行为** - 仅对可信Agent启用自动确认

---

## 10. 常见问题

### Q1: SafeExec会拦截所有命令吗？

**A:** 不会。只有显式调用 `safe-exec.sh "command"` 的命令才会被检查。它不会自动拦截系统中的所有命令。

### Q2: Agent可以绕过SafeExec吗？

**A:** 是的。如果Agent直接调用 `exec` 或 `bash -c` 而不使用 `safe-exec.sh`，命令不会被检查。SafeExec是一个**自愿使用的安全层**，不是强制性的系统级拦截器。

### Q3: 如果我不设置 `SAFE_EXEC_AUTO_CONFIRM`，Agent会挂起吗？

**A:** 不会。对于LOW/MEDIUM风险命令，Agent模式会自动执行（记录为`agent_auto`）。对于HIGH/CRITICAL风险，会创建pending请求，Agent继续运行（不会挂起），用户稍后可以批准或拒绝。

### Q4: 审计日志会记录我的聊天内容吗？

**A:** 默认不会。除非您显式设置 `SAFEXEC_CONTEXT` 环境变量来传递聊天上下文，审计日志只记录命令本身，不记录会话历史。

### Q5: SafeExec需要网络连接吗？

**A:** 不需要。除了安装时的 `git clone`，运行时完全离线，无任何网络调用。

---

## 11. 技术支持

**问题报告:** https://github.com/OTTTTTO/safe-exec/issues
**文档:** https://github.com/OTTTTTO/safe-exec/blob/master/README.md
**安全审查回应:** `CLAWDHUB_SECURITY_RESPONSE.md`

---

**总结：** SafeExec是一个透明、可控的命令安全包装器，不是隐蔽的监控系统。所有行为都有文档说明，源代码完全开放，审计日志完整可追溯。
