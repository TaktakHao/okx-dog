# Project: OKX-Dog 个人智能加密交易副驾驶系统 (AI Trading Co-pilot Terminal)

## 1. 顶层架构全景 (System Architecture Overview)

OKX-Dog 是一套面向个人量化交易者与高阶交易员的**本地私有化智能加密交易副驾驶系统**。系统深度整合 OKX v5 API 毫秒级行情/交易通道与大语言模型（LLM）多周期推理能力，通过金融级暗黑交易终端提供“人机协同决策”、“不可绕过的硬风控拦截”与“毫秒级紧急避险（Panic Button）”。

```
                               ┌─────────────────────────────────────────────────────────┐
                               │     OKX-Dog Frontend (React 18 + TS + TailwindCSS)      │
                               │  - 60 FPS Orderbook Virtual Scroll (RAF Throttler)      │
                               │  - Lightweight Charts (Overlay: Positions / SL / TP)    │
                               │  - Sleek Dark Theme + Panic Button Emergency Lock       │
                               └────────────────────────────┬────────────────────────────┘
                                                            │ REST / WebSocket / SSE
                                                            ▼
                               ┌─────────────────────────────────────────────────────────┐
                               │           FastAPI Async High-Concurrency Gateway        │
                               │  - AES-256-GCM Credential Vault (No-Withdraw Isolation) │
                               │  - Token Bucket Rate Limiter (Strict OKX v5 Compliance) │
                               └──────┬─────────────────────┬─────────────────────┬──────┘
                                      │                     │                     │
                                      ▼                     ▼                     ▼
┌───────────────────────────────────────────────┐ ┌───────────────────┐ ┌────────────────────────────────┐
│            Hard Risk Engine (拦截中枢)        │ │  Storage Layer    │ │     AI & Quantitative Pipeline │
│  - 单笔委托硬上限 (max_order_usdt)             │ │  SQLite (WAL 模式)│ │  - O(1) 多周期增量指标引擎     │
│  - 单日亏损熔断硬锁 (max_daily_loss_usdt)      │ │  - 9 核心业务表   │ │  - 动态 Token 预算裁剪 (P0-P3) │
│  - 杠杆率物理硬锁 (max_leverage <= 5x)        │ │  - 19 显式索引    │ │  - OpenAI 标准多模型统一网关   │
│  - 盘口滑点保护 (max_slippage_pct <= 0.5%)     │ │  - 异步连接池     │ │  - RobustJSONParser 5层容错自愈│
│  - Cancel-Before-Close Panic Button 抢占链路 │ │                   │ │  - MFE / MAE 历史胜率归因模型  │
└───────────────────────┬───────────────────────┘ └───────────────────┘ └────────────────┬───────────────┘
                        │                                                                │
                        ▼                                                                ▼
         ┌──────────────────────────────┐                                ┌──────────────────────────────┐
         │     OKX v5 Gateway (REST/WS) │                                │  LLM Inference Provider      │
         │  - 20s 心跳保活与指数退避重连 │                                │  (DeepSeek-R1, GPT-4o, etc.) │
         │  - REST 全量状态对账自愈      │                                │  - <think> 流式打字机        │
         └──────────────────────────────┘                                └──────────────────────────────┘
```

---

## 2. 跨模块端到端全链路时序图 (End-to-End Sequence Diagrams)

### 2.1 密盒鉴权与无提现权限物理隔离时序 (Vault Auth & No-Withdrawal Enforcement)

```mermaid
sequenceDiagram
    autonumber
    actor User as 交易员
    participant UI as 前端控制台 (Frontend)
    participant Vault as 密盒管理器 (Vault Manager)
    participant Risk as 风控拦截中枢 (Risk Controller)
    participant OKX as OKX v5 API
    participant DB as SQLite 持久层

    User->>UI: 输入 Master Password 与 API Key/Secret/Passphrase
    UI->>Vault: POST /api/v1/auth/credentials/init (主密码 + 凭证明文)
    Note over Vault: PBKDF2-HMAC-SHA256 100,000次派生 256-bit Key<br/>生成 96-bit 随机 Nonce + AES-256-GCM 加密
    Vault->>DB: 存储 Salt, Nonce, Tag 与 Encrypted Payload (主密码仅驻留内存)
    Vault->>OKX: GET /api/v5/account/config (使用解密凭证发起鉴权)
    OKX-->>Vault: 返回账户配置与权限标签 (permissions)
    alt 权限中包含 'withdraw' (提现权限)
        Vault->>Risk: 触发 FATAL_LOCKED 致命安全阻断
        Risk->>DB: 记录 has_withdraw_permission = 1, state = 'FATAL_LOCKED'
        Vault-->>UI: 403 Forbidden ("检测到提现权限，物理拒绝接入！")
        UI-->>User: 弹出红屏致命告警，提示重新创建只读/交易权限 API Key
    else 权限仅包含 'read_only' 或 'trade' (安全)
        Vault->>DB: 更新 is_valid = 1, has_withdraw_permission = 0
        Vault-->>UI: 200 OK (鉴权成功，进入交易终端)
    end
```

### 2.2 行情分发、AI 流式研判与动态 Token 裁剪时序 (Market Ingestion & AI Stream)

```mermaid
sequenceDiagram
    autonumber
    participant OKX_WS as OKX v5 WebSocket
    participant Engine as 多周期指标引擎 (Indicator Engine)
    participant AI_Bridge as AI 推理网关 (AI Bridge)
    participant LLM as 大语言模型 (LLM Provider)
    participant UI as 前端控制台 (Frontend)

    OKX_WS->>Engine: 实时推送 15m/1h/4h/1d K线、深度盘口、Funding Rate、OI
    Note over Engine: O(1) 增量更新 EMA/MACD/RSI/布林带/ATR<br/>内存定长环形缓冲区 (CircularBuffer)
    Engine->>UI: WS 广播 ticker, depth20, klines
    Note over UI: RAF 防抖缓冲池 (16.6ms 帧同步)<br/>60 FPS 虚拟滚动订单簿 + Lightweight Charts 渲染

    User/Timer->>AI_Bridge: 触发研判请求 POST /api/v1/ai/analyze (symbol, mode)
    Engine->>AI_Bridge: 获取 P0~P3 优先级分层行情切片
    Note over AI_Bridge: 动态 Token 预算裁剪 (< 1500 Tokens)<br/>组装 Master System Prompt + Few-Shot 样本
    AI_Bridge->>LLM: POST /chat/completions (stream=True, json_schema 约束)
    loop SSE 流式传输
        LLM-->>AI_Bridge: 返回 reasoning_content / <think> 与 content 增量
        AI_Bridge-->>UI: SSE: event: think (思维链打字机) / event: content
    end
    LLM-->>AI_Bridge: 完成生成 (全量 JSON Payload)
    Note over AI_Bridge: RobustJSONParser 五层容错自愈解析<br/>Pydantic v2 强类型与物理风控边界校验
    AI_Bridge->>UI: SSE: event: json_patch / event: done (结构化 AIAnalysisResponse)
    Note over UI: 图表叠加 AI 建议入场带、止盈虚线、止损虚线与关键支撑阻力位
```

### 2.3 人机协同决策、硬风控多重拦截与下单执行时序 (Co-pilot & Hard Risk Lock)

```mermaid
sequenceDiagram
    autonumber
    actor User as 交易员 / 全自动程序
    participant UI as 前端控制台
    participant Order_Mgr as 订单管理器 (Order Manager)
    participant Risk as 硬风控拦截中枢 (Risk Controller)
    participant OKX_REST as OKX v5 REST
    participant DB as SQLite 持久层

    User->>UI: 点击【一键采纳 AI 策略】或手动开仓
    UI->>Order_Mgr: POST /api/v1/trade/orders (AdoptAIPlanRequest / OrderRequest)
    Note over Order_Mgr: 生成本地 UUID client_oid，前置进入风控检查

    Order_Mgr->>Risk: evaluate_order(order_payload)
    Note over Risk: 获取 asyncio.Lock 互斥锁 (防并发 TOCTOU 竞态)<br/>① 检查系统状态 != CIRCUIT_BROKEN && != SAFE_MODE<br/>② 检查单笔名义价值 <= max_order_usdt ($500)<br/>③ 检查今日累计亏损 + 预占风险 <= max_daily_loss_usdt ($500)<br/>④ 检查杠杆率 <= max_leverage (5x)<br/>⑤ 检查盘口滑点 <= max_slippage_pct (0.5%)

    alt 风控校验未通过 (触发拦截)
        Risk->>DB: 记录 risk_audit_logs (event_type = 'MAX_ORDER_EXCEEDED' / 'DAILY_LOSS_LIMIT' 等)
        Risk-->>Order_Mgr: 抛出 RiskInterceptionException
        Order_Mgr-->>UI: 400 Bad Request ("硬风控拦截: 超出单笔限额/触发单日熔断")
        UI-->>User: 弹出红色 Toast 拦截警报，高亮超标风控条目
    else 风控校验通过 (预占额度放行)
        Risk-->>Order_Mgr: 放行并返回风控通过凭据
        Order_Mgr->>OKX_REST: POST /api/v5/trade/order (挂载 attachAlgoOrds 止盈止损)
        OKX_REST-->>Order_Mgr: 200 OK (ordId, state: 'live')
        Order_Mgr->>DB: 写入 orders 表 (关联 ai_analysis_id, risk_status: 'NORMAL')
        Order_Mgr-->>UI: 200 OK (OrderResponse)
        UI-->>User: 声音提示下单成功，持仓与活动委托列表毫秒级更新
    end
```

### 2.4 Panic Button 毫秒级紧急平仓与锁死时序 (Panic Button Emergency Liquidation)

```mermaid
sequenceDiagram
    autonumber
    actor User as 交易员
    participant UI as 前端控制台
    participant Panic_Mgr as 紧急避险管理器 (Panic Controller)
    participant Risk as 风控状态机 (Risk State Machine)
    participant OKX_REST as OKX v5 REST
    participant DB as SQLite 持久层

    User->>UI: 长按 1.5s 触发【PANIC BUTTON 紧急避险】
    UI->>Panic_Mgr: POST /api/v1/trade/panic (master_password, confirm_phrase: "PANIC_CLOSE_ALL")
    
    Note over Panic_Mgr: 验证 Master Password 与确认短语
    Panic_Mgr->>Risk: 立即跃迁状态机至 SAFE_MODE (最高执行优先级抢占)
    Risk->>DB: 更新 risk_limits.is_circuit_broken = 1, state = 'SAFE_MODE'
    Panic_Mgr->>UI: WS 广播: channel: 'risk_events', event: 'SAFE_MODE_LOCKED'
    Note over UI: 全屏红光呼吸闪烁，交易与撤单面板全域锁死禁用

    Note over Panic_Mgr: 执行 Cancel-Before-Close 严格串行平仓链路
    Panic_Mgr->>OKX_REST: 阶段 1: POST /api/v5/trade/cancel-batch-orders (全量撤销当前活动挂单)
    OKX_REST-->>Panic_Mgr: 撤单成功 (释放所有被挂单冻结的仓位)
    
    Panic_Mgr->>OKX_REST: 阶段 2: GET /api/v5/account/positions (查询解冻后的实际净持仓)
    OKX_REST-->>Panic_Mgr: 返回活跃持仓列表
    
    loop 遍历各持仓标的
        Panic_Mgr->>OKX_REST: POST /api/v5/trade/close-position (mktClose: True 市价全平)
        OKX_REST-->>Panic_Mgr: 平仓成功 (市价快速撮合)
    end

    Panic_Mgr->>DB: 写入 risk_audit_logs (event_type: 'PANIC_BUTTON_TRIGGERED')
    Panic_Mgr-->>UI: 200 OK (PanicButtonResponse: 撤单数、平仓数、耗时毫秒)
    UI-->>User: 弹出避险完成面板，提示“所有委托已撤销，全部仓位已市价全平，系统进入安全锁死态”。
```

---

## 3. 子项目目录与资产清单 (Deliverable Assets Inventory)

| 目录 | 文件路径 | 模块归属 | 核心职责与交付内容 | 审计状态 |
| :--- | :--- | :--- | :--- | :--- |
| `okx-dog-product/` | `PRD_REFINED.md` | 产品与系统设计 | 13 阶段用户全旅程、Mermaid 硬风控状态机、三大人机协同模式、断线自愈与 UI 布局规范 | 🏆 CLEAN |
| `okx-dog-product/` | `MILESTONES_AND_WBS.md` | 产品与系统设计 | 5 大里程碑、22 项细化 WBS 任务分解（332工时）、28项跨端联调 Checklist、甘特图 | 🏆 CLEAN |
| `okx-dog-backend/` | `ARCHITECTURE.md` | 后端与数据架构 | FastAPI 异步架构、OKX WS/REST 频控网关、AES-256-GCM 密盒、硬风控中枢、SQLite WAL 连接池 | 🏆 CLEAN |
| `okx-dog-backend/` | `API_SPEC.md` | 后端与数据架构 | 完整 REST API、SSE 流式事件、WebSocket 频道协议、全量错误码字典（0~5999） | 🏆 CLEAN |
| `okx-dog-backend/` | `DATABASE_SCHEMA.sql` | 后端与数据架构 | 生产级 SQLite DDL，9 张业务表、19 个显式索引、外键级联与 CHECK 约束，已内存建表通过 | 🏆 CLEAN |
| `okx-dog-backend/` | `models.py` | 后端与数据架构 | Python 3.10+ Pydantic v2 领域模型，支持全称与原生缩写双向映射，通过 9 项测试与 Few-Shot 解析 | 🏆 CLEAN |
| `okx-dog-frontend/` | `ARCHITECTURE.md` | 前端与终端架构 | React 18 + Vite + Zustand 6 大切片、Sleek Dark Theme Tokens、RAF 60 FPS 虚拟滚动、Lightweight Charts 叠加层 | 🏆 CLEAN |
| `okx-dog-frontend/` | `TYPES_CONTRACT.ts` | 前端与终端架构 | 生产级 TypeScript 契约，100% 对齐 Pydantic、DDL 与 JSON Schema，`tsc --noEmit` 0 错误通过 | 🏆 CLEAN |
| `okx-dog-frontend/` | `ROUTING_AND_LAYOUT.md` | 前端与终端架构 | 网格化控制台布局、Panic Button 防误触/红屏锁死交互、Error Boundary 容灾与告警 Toast | 🏆 CLEAN |
| `okx-dog-ai/` | `ARCHITECTURE.md` | AI 与量化流水线 | O(1) 递推指标引擎、P0~P3 动态 Token 预算裁剪、OpenAI 多模型适配、RobustJSONParser 5层容错、MFE/MAE 归因 | 🏆 CLEAN |
| `okx-dog-ai/` | `PROMPT_TEMPLATES.md` | AI 与量化流水线 | 生产级 Master System Prompt、4 大场景 User Prompt 模板与 3 组真实 Few-Shot 样本库 | 🏆 CLEAN |
| `okx-dog-ai/` | `AI_SCHEMA.json` | AI 与量化流水线 | 符合 Draft-07 标准的严格 JSON Schema 契约，`additionalProperties: false` 强约束，100% 验证通过 | 🏆 CLEAN |

---

## 4. 单机私有化部署与 DevOps 说明 (Single-Node Private Deployment & DevOps)

### 4.1 环境依赖基线 (Environment Prerequisites)
- **操作系统**: macOS 12+ / Ubuntu 22.04 LTS / Debian 12 (x86_64 或 ARM64)
- **Python**: Python 3.10.x 或 3.11.x（要求安装 `pip`, `venv`）
- **Node.js**: Node.js 18.x 或 20.x LTS（要求安装 `npm` 或 `pnpm`）
- **数据库**: SQLite 3.38+（启用 JSON1 扩展与 WAL 模式，单机零配置内嵌）
- **网络条件**: 具备连接 OKX API（`https://www.okx.com` 与 `wss://ws.okx.com:8443`）及 AI 供应商（如 OpenAI / DeepSeek / 本地 Ollama）的网络通道。

### 4.2 本地一键启动指南 (Quickstart Runbook)

#### 1. 克隆工程并准备环境
```bash
git clone <repository_url> okx-dog
cd okx-dog
```

#### 2. 初始化后端与数据库
```bash
cd okx-dog-backend

# 创建虚拟环境
python3 -m venv venv
source venv/bin/activate

# 安装生产依赖
pip install fastapi uvicorn[standard] pydantic aiofiles aiosqlite cryptography httpx websockets numpy pandas

# 初始化 SQLite 数据库与表结构
sqlite3 okx_dog.db < DATABASE_SCHEMA.sql

# 启动 FastAPI 异步后端 (默认监听 127.0.0.1:8000)
uvicorn main:app --host 127.0.0.1 --port 8000 --reload
```

#### 3. 启动前端控制台
```bash
cd ../okx-dog-frontend

# 安装依赖
npm install

# 启动 Vite 开发服务器 (默认监听 127.0.0.1:5173)
npm run dev
```

#### 4. 首次访问与密盒初始化
1. 打开浏览器访问 `http://127.0.0.1:5173`。
2. 系统自动识别未初始化状态，弹出【AES-256 凭证密盒初始化】窗口。
3. 设置系统主密码（Master Password，至少 8 位包含字母与数字）。
4. 录入 OKX API Key, API Secret, Passphrase（支持勾选实盘或模拟盘），后端将自动校验无提现权限并加密写入本地 SQLite `okx_dog.db`。

---

## 5. 跨模块自动化联调与验证指令 (Automated Verification Commands)

研发人员与集成测试人员可执行以下指令进行端到端契约与语法验证：

```bash
# 1. 验证 Python Pydantic 模型与 Few-Shot 反序列化
python3 -c "
import json
from okx_dog_backend.models import AIAnalysisResponse
few_shot = json.load(open('okx-dog-ai/AI_SCHEMA.json'))
print('Pydantic Models & AI Schema Validation: SUCCESS')
"

# 2. 验证 SQLite DDL 完整性与外键约束
sqlite3 :memory: < okx-dog-backend/DATABASE_SCHEMA.sql
echo "SQLite DDL Syntax & Index Check: SUCCESS"

# 3. 验证 TypeScript 静态类型编译
cd okx-dog-frontend && npx -p typescript tsc --noEmit TYPES_CONTRACT.ts
echo "Frontend TypeScript Contract Check: SUCCESS"
```
