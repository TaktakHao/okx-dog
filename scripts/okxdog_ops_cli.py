#!/usr/bin/env python3
"""
OKX-Dog v6.0 - Hermes Agent 多角色与自动化例程专用安全运维 CLI (Ops CLI)
文件: scripts/okxdog_ops_cli.py
角色: 后端架构师 (Backend Architect)

职责:
1. 员工与 Hermes 例程调用 OKX-Dog 后端的唯一下游入口
2. 内置白名单与凭据注入：自动读取环境变量中员工令牌 (X-OKX-Agent-Token / HERMES_AGENT_TOKEN)
3. 严格受控：员工无法绕过此 CLI 直接发起 OKX 实盘下单或提现
4. 自动附加幂等键 (Idempotency-Key) 防重试重发
5. 统一超时、重试退避与纯净 JSON 格式输出，便于 AI 员工解析

用法:
  python3 scripts/okxdog_ops_cli.py whoami
  python3 scripts/okxdog_ops_cli.py status
  python3 scripts/okxdog_ops_cli.py stop-autopilot --reason "回撤超限红队干预"
  python3 scripts/okxdog_ops_cli.py create-proposal --target AUTO_PILOT_CONFIG --patch '{"min_confidence": 0.88}' --summary "多头置信度收紧"
  python3 scripts/okxdog_ops_cli.py list-proposals
  python3 scripts/okxdog_ops_cli.py apply-proposal --proposal-id prop_123
  python3 scripts/okxdog_ops_cli.py list-versions
  python3 scripts/okxdog_ops_cli.py rollback-version --version-id ver_456
  python3 scripts/okxdog_ops_cli.py generate-review
  python3 scripts/okxdog_ops_cli.py tuning-policies
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import time
import urllib.error
import urllib.request
import uuid
from pathlib import Path
from typing import Any, Dict, Optional

ROOT_DIR = Path(__file__).resolve().parent.parent
HERMES_STATE_FILE = ROOT_DIR / ".hermes_state.json"
BACKEND_URL = os.environ.get("BACKEND_URL", "http://127.0.0.1:8000").rstrip("/")


def load_agent_token_from_env_or_file(role_hint: Optional[str] = None) -> Optional[str]:
    """优先从环境变量 X_OKX_AGENT_TOKEN / HERMES_AGENT_TOKEN 读取，其次查找本地凭证文件"""
    env_token = os.environ.get("X_OKX_AGENT_TOKEN") or os.environ.get("HERMES_AGENT_TOKEN")
    if env_token:
        return env_token.strip()

    if HERMES_STATE_FILE.exists():
        try:
            data = json.loads(HERMES_STATE_FILE.read_text(encoding="utf-8"))
            tokens = data.get("agent_tokens", {})
            if role_hint and role_hint in tokens:
                return str(tokens[role_hint])
            curr_role = os.environ.get("HERMES_AGENT_ROLE") or os.environ.get("AGENT_ROLE")
            if curr_role and curr_role in tokens:
                return str(tokens[curr_role])
            if tokens:
                return str(next(iter(tokens.values())))
        except Exception:
            pass
    return None


def request_backend(
    method: str,
    path: str,
    body: Optional[Dict[str, Any]] = None,
    agent_token: Optional[str] = None,
    idempotency_key: Optional[str] = None,
    timeout: float = 15.0,
    max_retries: int = 2
) -> Dict[str, Any]:
    """调用 OKX-Dog 后端接口，内置自动退避与幂等键"""
    url = f"{BACKEND_URL}{path}"
    headers = {
        "Accept": "application/json",
        "User-Agent": "OKX-Dog-OpsCLI/6.1",
    }
    if agent_token:
        headers["X-OKX-Agent-Token"] = agent_token
    if idempotency_key:
        headers["Idempotency-Key"] = idempotency_key

    data = None
    if body is not None:
        headers["Content-Type"] = "application/json"
        data = json.dumps(body, ensure_ascii=False).encode("utf-8")

    last_error = ""
    for attempt in range(max_retries + 1):
        try:
            req = urllib.request.Request(url, data=data, headers=headers, method=method)
            with urllib.request.urlopen(req, timeout=timeout) as resp:
                raw = resp.read().decode("utf-8")
                return json.loads(raw) if raw else {"status": "ok"}
        except urllib.error.HTTPError as exc:
            raw = exc.read().decode("utf-8", errors="replace")
            try:
                err_json = json.loads(raw)
            except Exception:
                err_json = {"detail": raw[:400]}
            print(json.dumps({"error": f"HTTP {exc.code}", "detail": err_json}, ensure_ascii=False, indent=2))
            sys.exit(1)
        except urllib.error.URLError as exc:
            last_error = str(exc.reason)
            if attempt < max_retries:
                time.sleep(1.0 * (attempt + 1))
                continue

    print(json.dumps({"error": "BACKEND_UNREACHABLE", "detail": last_error}, ensure_ascii=False, indent=2))
    sys.exit(1)


def main():
    parser = argparse.ArgumentParser(description="OKX-Dog v6.0 Hermes 安全运营 CLI")
    parser.add_argument("--role", help="指定调用员工 okxRole (用于读取对应令牌)")
    parser.add_argument("--token", help="显式指定 X-OKX-Agent-Token")

    subparsers = parser.add_subparsers(dest="command", required=True)

    # 1. whoami
    subparsers.add_parser("whoami", help="自省当前员工身份与权限白名单")

    # 2. status
    subparsers.add_parser("status", help="查询风控状态、自动操盘与运行健康度")

    # 3. stop-autopilot
    stop_p = subparsers.add_parser("stop-autopilot", help="紧急停止自动操盘")
    stop_p.add_argument("--reason", default="Hermes 员工巡检异常干预", help="停机原因")

    # 4. create-proposal
    prop_p = subparsers.add_parser("create-proposal", help="创建参数/规则变更提案")
    prop_p.add_argument("--target", required=True, choices=["AUTO_PILOT_CONFIG", "RISK_CONFIG", "SYSTEM_CONFIG", "KNOWLEDGE_RULE"], help="变更目标")
    prop_p.add_argument("--patch", required=True, help="变更字段 JSON 字典，如 '{\"min_confidence\": 0.88}'")
    prop_p.add_argument("--summary", required=True, help="提案摘要")
    prop_p.add_argument("--evidence-id", help="支持性证据引用ID (如回测实验ID或复盘ID)")
    prop_p.add_argument("--evidence-summary", help="证据论据总结")

    # 5. list-proposals
    list_p = subparsers.add_parser("list-proposals", help="查询变更提案列表")
    list_p.add_argument("--status", choices=["PENDING_APPROVAL", "APPROVED", "APPLIED", "REJECTED"], help="状态过滤")
    list_p.add_argument("--target", help="目标模块过滤")

    # 6. apply-proposal
    apply_p = subparsers.add_parser("apply-proposal", help="审批并通过提案 (仅 CEO 或董事会可用)")
    apply_p.add_argument("--proposal-id", required=True, help="待生效提案 ID")
    apply_p.add_argument("--approval-ref", help="关联审批流水号")

    # 7. reject-proposal
    rej_p = subparsers.add_parser("reject-proposal", help="拒绝提案")
    rej_p.add_argument("--proposal-id", required=True, help="待拒绝提案 ID")
    rej_p.add_argument("--reason", required=True, help="拒绝原因")

    # 8. list-versions
    ver_p = subparsers.add_parser("list-versions", help="查询配置快照历史版本")
    ver_p.add_argument("--target", default="AUTO_PILOT_CONFIG", help="目标配置模块")

    # 9. rollback-version
    rb_p = subparsers.add_parser("rollback-version", help="一键回滚参数配置")
    rb_p.add_argument("--version-id", required=True, help="目标版本快照 ID")

    # 10. generate-review
    subparsers.add_parser("generate-review", help="触发日复盘与战绩归因生成")

    # 11. tuning-policies
    subparsers.add_parser("tuning-policies", help="查询系统调参硬策略与最大步长约束")

    args = parser.parse_args()

    token = args.token or load_agent_token_from_env_or_file(args.role)
    idempotency_key = f"idem_{uuid.uuid4().hex}"

    if args.command == "whoami":
        res = request_backend("GET", "/api/v1/ops/agents/me", agent_token=token)
        print(json.dumps(res, ensure_ascii=False, indent=2))

    elif args.command == "status":
        risk_st = request_backend("GET", "/api/v1/risk/status", agent_token=token)
        ap_st = request_backend("GET", "/api/v1/auto-pilot/status", agent_token=token)
        health_st = request_backend("GET", "/api/v1/health", agent_token=token)
        print(json.dumps({
            "risk_status": risk_st,
            "auto_pilot": ap_st,
            "health": health_st,
        }, ensure_ascii=False, indent=2))

    elif args.command == "stop-autopilot":
        res = request_backend(
            "POST",
            "/api/v1/auto-pilot/stop",
            body={"reason": args.reason},
            agent_token=token,
            idempotency_key=idempotency_key
        )
        print(json.dumps(res, ensure_ascii=False, indent=2))

    elif args.command == "create-proposal":
        try:
            patch_dict = json.loads(args.patch)
        except Exception as e:
            print(json.dumps({"error": f"patch 必须是合法的 JSON 字典: {e}"}))
            sys.exit(1)

        evidence = []
        if args.evidence_id and args.evidence_summary:
            evidence.append({
                "kind": "BACKTEST_EXPERIMENT",
                "ref_id": args.evidence_id,
                "summary": args.evidence_summary,
                "metrics": {}
            })

        payload = {
            "target": args.target,
            "patch": patch_dict,
            "summary": args.summary,
            "evidence": evidence
        }
        res = request_backend(
            "POST",
            "/api/v1/ops/proposals",
            body=payload,
            agent_token=token,
            idempotency_key=idempotency_key
        )
        print(json.dumps(res, ensure_ascii=False, indent=2))

    elif args.command == "list-proposals":
        path = "/api/v1/ops/proposals?"
        if args.status:
            path += f"status={args.status}&"
        if args.target:
            path += f"target={args.target}&"
        res = request_backend("GET", path.rstrip("&?"), agent_token=token)
        print(json.dumps(res, ensure_ascii=False, indent=2))

    elif args.command == "apply-proposal":
        res = request_backend(
            "POST",
            f"/api/v1/ops/proposals/{args.proposal_id}/apply",
            body={"approval_ref": args.approval_ref},
            agent_token=token,
            idempotency_key=idempotency_key
        )
        print(json.dumps(res, ensure_ascii=False, indent=2))

    elif args.command == "reject-proposal":
        res = request_backend(
            "POST",
            f"/api/v1/ops/proposals/{args.proposal_id}/reject",
            body={"reason": args.reason},
            agent_token=token,
            idempotency_key=idempotency_key
        )
        print(json.dumps(res, ensure_ascii=False, indent=2))

    elif args.command == "list-versions":
        res = request_backend("GET", f"/api/v1/ops/config-versions?target={args.target}", agent_token=token)
        print(json.dumps(res, ensure_ascii=False, indent=2))

    elif args.command == "rollback-version":
        res = request_backend(
            "POST",
            f"/api/v1/ops/config-versions/{args.version_id}/rollback",
            agent_token=token,
            idempotency_key=idempotency_key
        )
        print(json.dumps(res, ensure_ascii=False, indent=2))

    elif args.command == "generate-review":
        res = request_backend(
            "POST",
            "/api/v1/reviews/generate",
            body={"date": time.strftime("%Y-%m-%d")},
            agent_token=token,
            idempotency_key=idempotency_key
        )
        print(json.dumps(res, ensure_ascii=False, indent=2))

    elif args.command == "tuning-policies":
        res = request_backend("GET", "/api/v1/ops/tuning-policies", agent_token=token)
        print(json.dumps(res, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
