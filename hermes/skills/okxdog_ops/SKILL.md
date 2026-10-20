---
name: okxdog_ops
description: OKX-Dog 虚拟量化对冲基金本地安全运维与风控治理技能包。提供系统健康查询、紧急停机、调参提案生成、提案生效及版本回滚等白名单操作。
version: 1.0.0
author: OKX-Dog System Architect
license: MIT
---

# OKX-Dog 量化对冲基金本地安全运维与风控管理技能 (okxdog_ops)

本技能包专为 Hermes Agent 及多角色虚拟量化团队（陈守拙、周铁山、钱公道、张大炮、赵小刀、林望远）提供经过严格硬风控校验的本地运维操作接口。

> **安全铁律**：所有操作均通过沙箱脚本 `scripts/okxdog_ops_cli.py` 执行，严禁绕过本技能直接调用底层未受控命令或访问私钥密盒。

---

## 可用工具指令库 (Tool Commands)

### 1. 查询当前系统状态与风控健康度 (status)
- **适用角色**：所有 6 名员工
- **使用时机**：日常巡检、回答用户咨询、例程自检
- **命令语法**：
  ```bash
  python3 scripts/okxdog_ops_cli.py status
  ```
- **输出内容**：自动操盘模式 (`MANUAL`/`SEMI_AUTO`/`FULL_AUTO`)、持仓盈亏、保证金使用率、系统健康度与风控指标。

---

### 2. 身份与权限自省 (whoami)
- **适用角色**：所有 6 名员工
- **使用时机**：验证当前执行环境的角色 Token 与权限边界
- **命令语法**：
  ```bash
  python3 scripts/okxdog_ops_cli.py whoami
  ```

---

### 3. 紧急红队停机 (stop-autopilot)
- **适用角色**：周铁山 (`BEAR_CRITIC`)、陈守拙 (`CHIEF_ARBITER`)
- **使用时机**：发现单日回撤异常、市场剧烈闪崩、收到用户明确停机避险指令
- **命令语法**：
  ```bash
  python3 scripts/okxdog_ops_cli.py stop-autopilot --reason "<停机原因详细说明>"
  ```
- **安全说明**：该操作具备幂等性（同原因重复调用不抛错），会立即阻断一切新开仓发单。

---

### 4. 提交参数变更提案 (create-proposal)
- **适用角色**：张大炮 (`BULL_SPECIALIST`)、赵小刀 (`MICROSTRUCTURE`)、周铁山 (`BEAR_CRITIC`)
- **使用时机**：通过样本外网格搜索或盘口特征发现更优参数组合时
- **命令语法**：
  ```bash
  python3 scripts/okxdog_ops_cli.py create-proposal \
    --target AUTO_PILOT_CONFIG \
    --patch '{"min_confidence": 0.88}' \
    --summary "顺势多头置信度阈值调优"
  ```
- **安全限制**：单次调整步长受限（置信度步长 ≤ 0.1，杠杆步长 ≤ 2.0x）。

---

### 5. 审批并通过提案 (apply-proposal)
- **适用角色**：陈守拙 (`CHIEF_ARBITER`)
- **使用时机**：在 `SEMI_AUTO` 模式下收到用户明确的“确认/Approve”指令后，或在 `FULL_AUTO` 模式下达标自动生效
- **命令语法**：
  ```bash
  python3 scripts/okxdog_ops_cli.py apply-proposal --proposal-id "<PROPOSAL_ID>"
  ```
- **执行效果**：原子热更新底层配置，自动保存快照版本并生成历史版本号。

---

### 6. 一键回滚参数到历史版本 (rollback-version)
- **适用角色**：陈守拙 (`CHIEF_ARBITER`)、周铁山 (`BEAR_CRITIC`)
- **使用时机**：新参数上线后表现不佳、发生意外滑点或用户要求撤回配置
- **命令语法**：
  ```bash
  python3 scripts/okxdog_ops_cli.py rollback-version --version-id "<VERSION_ID>"
  ```
