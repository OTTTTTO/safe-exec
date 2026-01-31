# SafeExec - 安全命令执行 Skill

为 OpenClaw Agent 提供安全的命令执行能力，自动拦截危险操作并要求用户批准。

## 功能

- 🔍 自动检测危险命令模式
- 🚨 拦截高风险操作
- 📱 通过 Feishu 通知用户
- ✅ 等待用户批准后执行
- 📊 完整的审计日志

## 使用方法

在 Agent 中调用：

```
请使用 safe_exec 执行命令：rm -rf /tmp/test
```

Agent 会自动使用此 Skill 来执行命令，并在检测到危险操作时请求批准。
