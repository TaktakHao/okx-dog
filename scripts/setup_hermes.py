#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
OKX-Dog v6.0 - Hermes Agent 初始化与多角色环境自检脚本
用于自动化校验 Hermes 6 大员工角色、专属技能包以及本地运维 CLI 连通性。
"""

import os
import sys
import json
import shutil
import subprocess
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent
HERMES_DIR = REPO_ROOT / "hermes"
CONTRACTS_DIR = REPO_ROOT / "contracts" / "hermes"


def print_banner():
    print("=" * 68)
    print("   OKX-Dog v6.0 - Hermes Agent 多角色环境初始化与自检工具")
    print("=" * 68)


def check_personas():
    print("\n[1/4] 检查 6 大虚拟员工多角色配置 (Personas)...")
    contract_file = CONTRACTS_DIR / "personas_contract.json"
    if not contract_file.exists():
        print(f"  ✘ 契约文件缺失: {contract_file}")
        return False

    with open(contract_file, "r", encoding="utf-8") as f:
        contract = json.load(f)

    all_passed = True
    personas_dir = HERMES_DIR / "personas"
    for role_info in contract.get("roles", []):
        persona_id = role_info["hermes_persona_id"]
        persona_file = personas_dir / f"{persona_id}.md"
        if persona_file.exists():
            print(f"  ✔ [OK] 角色已就绪: {role_info['name']} ({role_info['title']}) -> {persona_file.name}")
        else:
            print(f"  ✘ [MISSING] 角色文件缺失: {persona_file}")
            all_passed = False

    return all_passed


def check_skill():
    print("\n[2/4] 检查 Hermes 专属量化运维技能包 (agentskills.io)...")
    skill_file = HERMES_DIR / "skills" / "okxdog_ops" / "SKILL.md"
    if skill_file.exists():
        print(f"  ✔ [OK] 技能包规范有效: {skill_file} ({skill_file.stat().st_size} 字节)")
        return True
    else:
        print(f"  ✘ [MISSING] 技能包缺失: {skill_file}")
        return False


def check_local_ops_cli():
    print("\n[3/4] 校验本地安全运维脚手架 (scripts/okxdog_ops_cli.py)...")
    cli_path = REPO_ROOT / "scripts" / "okxdog_ops_cli.py"
    if not cli_path.exists():
        print(f"  ✘ 运维脚手架缺失: {cli_path}")
        return False

    # 1. 语法与参数解析自检
    try:
        res_help = subprocess.run(
            [sys.executable, str(cli_path), "--help"],
            capture_output=True,
            text=True,
            timeout=5
        )
        if res_help.returncode != 0:
            print(f"  ✘ 本地 CLI 参数解析异常: {res_help.stderr.strip()}")
            return False
    except Exception as e:
        print(f"  ✘ 本地 CLI 执行失败: {e}")
        return False

    # 2. 尝试探测后端服务连通性
    try:
        res_who = subprocess.run(
            [sys.executable, str(cli_path), "whoami"],
            capture_output=True,
            text=True,
            timeout=3
        )
        if res_who.returncode == 0:
            print(f"  ✔ [OK] 本地 CLI 运行正常且后端在线，自省响应: {res_who.stdout.strip()}")
        else:
            print("  ✔ [OK] 本地 CLI 脚本与依赖完备（当前后端服务未启动，待 ./company.sh start 唤醒连通）")
        return True
    except Exception:
        print("  ✔ [OK] 本地 CLI 脚本与依赖完备（后端当前处于离线状态）")
        return True


def check_hermes_cli():
    print("\n[4/4] 探检系统 Hermes CLI 运行时与原生 Agent Profiles...")
    hermes_bin = shutil.which("hermes") or str(Path.home() / ".local" / "bin" / "hermes")
    if Path(hermes_bin).exists():
        print(f"  ✔ [OK] 检测到全局 Hermes CLI: {hermes_bin}")
        # 触发 6 大员工 Profiles 固化与别名自检
        bootstrap_script = REPO_ROOT / "scripts" / "bootstrap_hermes_personas.py"
        if bootstrap_script.exists():
            try:
                subprocess.run([sys.executable, str(bootstrap_script)], check=True, capture_output=True)
                print("  ✔ [OK] Hermes 6 大员工原生 Agent Profiles 与极简短别名 (chen/zhou/zhang/...) 已全量就绪！")
            except Exception as e:
                print(f"  ⚠ 员工 Profiles 同步异常: {e}")
    else:
        print("  ℹ 当前 PATH 未检测到 hermes 全局命令。")
        print("    如需安装 Hermes Agent 原生运行时，可随时执行:")
        print("    curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash")
    return True


def main():
    print_banner()
    c1 = check_personas()
    c2 = check_skill()
    c3 = check_local_ops_cli()
    c4 = check_hermes_cli()

    print("\n" + "=" * 68)
    if c1 and c2 and c3:
        print("🎉 恭喜！OKX-Dog v6.0 Hermes Agent 多角色运营体系已全部初始化完毕！")
        print("可执行 ./company.sh start 一键拉起全套服务。")
        print("=" * 68)
        return 0
    else:
        print("❌ 自检发现异常，请修复上述缺失项。")
        print("=" * 68)
        return 1


if __name__ == "__main__":
    sys.exit(main())
