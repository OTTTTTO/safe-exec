#!/bin/bash
# SafeExec - 持续优化脚本 v0.1.1
# 改进：添加超时清理功能

SAFE_EXEC_DIR="$HOME/.openclaw/safe-exec"
AUDIT_LOG="$HOME/.openclaw/safe-exec-audit.log"
PENDING_DIR="$SAFE_EXEC_DIR/pending"
REQUEST_TIMEOUT=300  # 5分钟超时

mkdir -p "$PENDING_DIR"

# 清理过期的请求
cleanup_expired_requests() {
    local now=$(date +%s)
    local count=0
    
    for request_file in "$PENDING_DIR"/*.json; do
        if [[ -f "$request_file" ]]; then
            local timestamp=$(jq -r '.timestamp' "$request_file" 2>/dev/null)
            if [[ -n "$timestamp" ]]; then
                local age=$((now - timestamp))
                if [[ $age -gt $REQUEST_TIMEOUT ]]; then
                    local request_id=$(basename "$request_file" .json)
                    jq '.status = "expired"' "$request_file" > "$request_file.tmp" && mv "$request_file.tmp" "$request_file"
                    echo "{\"timestamp\":\"$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")\",\"event\":\"expired\",\"requestId\":\"$request_id\",\"age\":$age}" >> "$AUDIT_LOG"
                    rm -f "$request_file"
                    count=$((count + 1))
                fi
            fi
        fi
    done
    
    return $count
}

log_audit() {
    local event="$1"
    local data="$2"
    local timestamp=$(date -u +"%Y-%m-%dT%H:%M:%S.%3NZ")
    echo "{\"timestamp\":\"$timestamp\",\"event\":\"$event\",$data}" >> "$AUDIT_LOG"
}

assess_risk() {
    local cmd="$1"
    local risk="low"
    local reason=""
    
    if [[ "$cmd" == *":(){:|:&};:"* ]] || [[ "$cmd" == *":(){ :|:& };:"* ]]; then
        risk="critical"
        reason="Fork炸弹"
    elif echo "$cmd" | grep -qE 'rm[[:space:]]+-rf[[:space:]]+[\/~]'; then
        risk="critical"
        reason="删除根目录或家目录文件"
    elif echo "$cmd" | grep -qE 'dd[[:space:]]+if='; then
        risk="critical"
        reason="磁盘破坏命令"
    elif echo "$cmd" | grep -qE 'mkfs\.'; then
        risk="critical"
        reason="格式化文件系统"
    elif echo "$cmd" | grep -qE '>[[:space:]]*/dev/sd[a-z]'; then
        risk="critical"
        reason="直接写入磁盘"
    elif echo "$cmd" | grep -qE 'chmod[[:space:]]+777'; then
        risk="high"
        reason="设置文件为全局可写"
    elif echo "$cmd" | grep -qE '>[[:space:]]*/(etc|boot|sys|root)/'; then
        risk="high"
        reason="写入系统目录"
    elif echo "$cmd" | grep -qE '(curl|wget).*|[[:space:]]*(bash|sh|python)'; then
        risk="high"
        reason="管道下载到shell"
    elif echo "$cmd" | grep -qE 'sudo[[:space:]]+'; then
        risk="medium"
        reason="使用特权执行"
    elif echo "$cmd" | grep -qE 'iptables|firewall-cmd|ufw'; then
        risk="medium"
        reason="修改防火墙规则"
    fi
    
    echo "{\"risk\":\"$risk\",\"reason\":\"$reason\"}"
}

request_approval() {
    local command="$1"
    local risk="$2"
    local reason="$3"
    local request_id="req_$(date +%s)_$(shuf -i 1000-9999 -n 1)"
    
    echo "{\"id\":\"$request_id\",\"command\":$(echo "$command" | jq -Rs .),\"risk\":\"$risk\",\"reason\":\"$reason\",\"timestamp\":$(date +%s),\"status\":\"pending\"}" > "$PENDING_DIR/$request_id.json"
    
    log_audit "approval_requested" "{\"requestId\":\"$request_id\",\"command\":$(echo "$command" | jq -Rs .),\"risk\":\"$risk\",\"reason\":\"$reason\"}"
    
    cat <<EOF

🚨 **危险操作检测 - 命令已拦截**

**风险等级:** ${risk^^}
**命令:** \`$command\`
**原因:** $reason

**请求 ID:** \`$request_id\`

ℹ️  此命令需要用户批准才能执行。

**批准方法:**
1. 在终端运行: \`safe-exec-approve $request_id\`
2. 或者: \`safe-exec-list\` 查看所有待处理请求

**拒绝方法:**
 \`safe-exec-reject $request_id\`

⏰ 请求将在 5 分钟后过期

EOF
    return 0
}

main() {
    local command="$*"
    
    if [[ -z "$command" ]]; then
        echo "用法: safe-exec \"<命令>\""
        exit 1
    fi
    
    # 自动清理过期请求
    cleanup_expired_requests
    
    local assessment
    assessment=$(assess_risk "$command")
    local risk
    local reason
    risk=$(echo "$assessment" | jq -r '.risk')
    reason=$(echo "$assessment" | jq -r '.reason')
    
    if [[ "$risk" == "low" ]]; then
        log_audit "allowed" "{\"command\":$(echo "$command" | jq -Rs .),\"risk\":\"low\"}"
        eval "$command"
        exit $?
    fi
    
    request_approval "$command" "$risk" "$reason"
    exit 0
}

case "$1" in
    --approve)
        request_file="$PENDING_DIR/$2.json"
        if [[ -f "$request_file" ]]; then
            command=$(jq -r '.command' "$request_file")
            echo "✅ 执行命令: $command"
            log_audit "executed" "{\"requestId\":\"$2\"}"
            eval "$command"
            exit_code=$?
            rm -f "$request_file"
            exit $exit_code
        fi
        echo "❌ 请求不存在: $2"
        exit 1
        ;;
    --reject)
        request_file="$PENDING_DIR/$2.json"
        if [[ -f "$request_file" ]]; then
            command=$(jq -r '.command' "$request_file")
            log_audit "rejected" "{\"requestId\":\"$2\"}"
            rm -f "$request_file"
            echo "❌ 请求已拒绝"
            exit 0
        fi
        echo "❌ 请求不存在: $2"
        exit 1
        ;;
    --list)
        echo "📋 **待处理的批准请求:**"
        echo ""
        count=0
        for f in "$PENDING_DIR"/*.json; do
            if [[ -f "$f" ]]; then
                count=$((count + 1))
                id=$(basename "$f" .json)
                cmd=$(jq -r '.command' "$f")
                rsk=$(jq -r '.risk' "$f")
                reason=$(jq -r '.reason' "$f")
                printf "📌 **请求 %d**\n" "$count"
                printf "   **ID:** \`%s\`\n" "$id"
                printf "   **风险:** %s\n" "${rsk^^}"
                printf "   **命令:** \`%s\`\n" "$cmd"
                printf "   **原因:** %s\n" "$reason"
                echo ""
                printf "   批准: \`safe-exec-approve %s\`\n" "$id"
                printf "   拒绝: \`safe-exec-reject %s\`\n" "$id"
                echo ""
            fi
        done
        
        if [[ $count -eq 0 ]]; then
            echo "✅ 没有待处理的请求"
        fi
        exit 0
        ;;
    --cleanup)
        cleanup_expired_requests
        echo "✅ 清理完成"
        exit 0
        ;;
esac

main "$@"
