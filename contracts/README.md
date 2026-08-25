# OKX-Dog 统一契约中心 (Single Source of Truth)

## 1. 契约中心定位与核心原则 (SSOT)

本目录 (`contracts/`) 是 OKX-Dog 交易系统**唯一权威事实源 (Single Source of Truth, SSOT)**。所有前端 (TypeScript)、后端 (Python Pydantic / SQLite DDL)、AI 算法模块 (JSON Schema / Prompt Context) 以及风控模块均必须严格依从本目录下的契约定义。

### 核心铁律 (Contract Iron Rules)
1. **契约先行 (Contract-First)**：任何新需求或功能变更，必须**首先更新本目录下的契约文件**，经架构确认并经人类审批后，方可由各端开工实现。
2. **严禁私自漂移 (Zero Drift)**：禁止任何端（前端、后端、AI）私自新增、修改或删除字段。所有数据结构必须 100% 对齐。
3. **自动化强校验 (Automated Gate)**：每次版本提交与阶段验收，必须运行 `python scripts/verify_contracts.py` 确保 100% 契约合规。

---

## 2. 目录结构索引 (Contract Directory Structure)

```text
contracts/
├── README.md                      # 契约中心说明与使用规范
├── api/                           # REST 接口与全局错误码契约
│   ├── rest_endpoints.json        # REST API 路由契约、入参与响应体索引
│   └── error_codes.json           # 全局业务错误码、HTTP 状态与中英文提示
├── schemas/                       # 核心业务实体与数据模型契约
│   ├── common.json                # 全局基础枚举（Side, PosSide, Mode, Env等）
│   ├── market.json                # K线、深度行情、衍生品指标数据契约
│   ├── trade.json                 # 订单、持仓、成交明细与平仓数据契约
│   └── system.json                # 系统状态、凭据安全状态、健康检查契约
├── ai/                            # AI 算法与提示词契约
│   ├── ai_decision_contract.json  # 大模型多周期研判结构化输出契约 (JSON Schema)
│   └── prompt_variables.json      # Prompt 提示词上下文变量输入契约
├── events/                        # 实时长连接与事件流契约
│   └── ws_channels.json           # WebSocket / SSE 事件通道、订阅与 Payload 契约
└── risk/                          # 交易风控与硬熔断契约
    └── risk_rules.json            # 单笔限额、单日熔断、滑点与杠杆硬约束
```

---

## 3. 契约演进与变更流程 (Change Management Protocol)

1. **需求提出**：产品 Agent 根据业务需求撰写 PRD。
2. **契约拟定**：架构 Agent 在 `contracts/` 中新增或修改对应 JSON Schema / 接口定义。
3. **人类审批**：开发者确认定稿包无误后予以批准。
4. **代码同步**：
   - 后端更新 `okx-dog-backend/models.py`
   - 前端更新 `okx-dog-frontend/TYPES_CONTRACT.ts`
   - AI 更新 `okx-dog-ai/schemas.py` 与 `AI_SCHEMA.json`
5. **门禁校验**：运行 `python scripts/verify_contracts.py` 验证一致性。
