# OKX-Dog 契约驱动多智能体研发流程标准作业指南 (Contract-Driven SOP)

> **适用场景**：个人全栈开发者通过 AI 多角色智能体高效管理与迭代 OKX-Dog 项目。  
> **核心哲学**：**契约先行 (Contract-First)**、**单一门禁 (Single Approval Gate)**、**自适应编排 (Adaptive DAG)** 与 **自动化防漂移 (Zero Drift)**。

---

## 1. 全景研发流水线 (End-to-End Pipeline)

整个需求从构想到交付遵循 4 阶段闭环流程：

```
[用户提出需求]
       ↓
【阶段 1: 产品定义】 Product Agent 编写标准化 PRD (业务旅程、边界、契约诉求)
       ↓
【阶段 2: 架构契约】 Architect Agent 更新 contracts/、输出技术方案与 WBS 依赖图
       ↓
【💎 单一审批门禁】 开发者审阅「需求与契约定稿包」，一次确认后各端自主开工
       ↓
【阶段 3: 多端开工】 根据 WBS 依赖自适应调度：
                      ├─ AI Quant Agent (算法/特征/Prompt/Schema)
                      ├─ Backend Agent  (models.py/API/风控/数据库)
                      └─ Frontend Agent (TYPES_CONTRACT.ts/UI/图表)
       ↓
【阶段 4: 质量验收】 运行 python scripts/verify_contracts.py + 风控审计 Agent 审查
       ↓
[交付闭环并记录 Walkthrough]
```

---

## 2. 常用操作指令与提示词规范 (Interactive Trigger Prompts)

作为个人管理者，你可以在对话框中通过以下自然语言或指令快速调度不同阶段：

### 🎯 场景 A: 启动新功能开发 (从 0 到 1 完整流程)
> **开发者输入**：  
> `「新需求：[需求描述，例如：新增波动率挤压自动平仓策略]，请按照契约驱动流程，首先让产品 Agent 和架构 Agent 输出 PRD 与契约定稿包。」`
>
> **AI 响应行为**：
> 1. 自动切换角色为 **Product & System Architect** 生成 PRD。
> 2. 自动更新 `contracts/` 下的接口/Schema 契约。
> 3. 生成 WBS 任务依赖树，并在最后提示用户进行单一门禁审批（Human Gate）。

---

### 🎯 场景 B: 审批通过，指示多端开工
> **开发者输入**：  
> `「定稿包已确认，请按照 WBS 依赖图推进各端代码实现与联调。」`
>
> **AI 响应行为**：
> 1. 按依赖顺序自动切换为 **AI & Quant Engineer**、**Backend Architect**、**Senior Frontend Developer** 依次/并行交付代码。
> 2. 后端同步更新 `okx-dog-backend/models.py`。
> 3. 前端同步更新 `okx-dog-frontend/TYPES_CONTRACT.ts`。
> 4. AI 同步更新 `okx-dog-ai/schemas.py` 与 `AI_SCHEMA.json`。

---

### 🎯 场景 C: 阶段交付验收与防漂移检测
> **开发者输入**：  
> `「各端已实现完毕，请执行契约自动化校验与风控审计验收。」`
>
> **AI 响应行为**：
> 1. 执行 `python3 scripts/verify_contracts.py` 自动化检测前后端与 AI 字段对齐情况。
> 2. 切换为 **Blockchain & Trading Security Auditor** 角色进行硬风控与边界审查。
> 3. 输出完整的 `walkthrough.md` 验收总结。

---

## 3. 契约中心 (SSOT) 维护规范

所有的真实接口与数据模型定义存放在系统根目录 `contracts/`：

| 契约目录 | 规范文件 | 对应代码镜像同步路径 |
| :--- | :--- | :--- |
| **基础枚举与数据模型** | `contracts/schemas/` | `okx-dog-backend/models.py`<br>`okx-dog-frontend/TYPES_CONTRACT.ts` |
| **REST API 规范** | `contracts/api/rest_endpoints.json`<br>`contracts/api/error_codes.json` | `okx-dog-backend/routers/*`<br>`okx-dog-frontend/src/api/*` |
| **实时事件通道** | `contracts/events/ws_channels.json` | `okx-dog-backend/okx_ws.py`<br>`okx-dog-frontend/src/hooks/useWebSocket.ts` |
| **AI 决策与 Prompt** | `contracts/ai/ai_decision_contract.json`<br>`contracts/ai/prompt_variables.json` | `okx-dog-ai/schemas.py`<br>`okx-dog-ai/AI_SCHEMA.json` |
| **硬风控规则契约** | `contracts/risk/risk_rules.json` | `okx-dog-backend/risk_controller.py` |

---

## 4. 自动化防漂移门禁使用说明

在任何模块修改或交付前后，可直接运行：

```bash
# 标准校验模式
python3 scripts/verify_contracts.py

# 严格模式 (任何告警均视为失败)
python3 scripts/verify_contracts.py --strict
```

### 校验范围与红线：
- [x] `contracts/` 所有 JSON 文件符合标准 JSON Schema 规范。
- [x] AI 决策输出字段、必填项与动作枚举 100% 同步。
- [x] 后端 Python Pydantic 枚举与核心数据模型 100% 对齐。
- [x] 前端 TypeScript Type/Interface 100% 对齐。
- [x] 提现权限物理隔离 (`block_withdraw_permission = True`) 强制合规。
