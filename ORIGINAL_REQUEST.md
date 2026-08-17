# Original User Request

## 2026-08-14T17:13:22Z

根据当前工程根目录下的 `PRD.md` 和 `AGENTS.md` 规范，调用团队中各领域的专业角色 Skill（产品架构师、`agency-backend-architect` 后端架构师、`agency-senior-developer` 前端资深架构师、`agency-ai-engineer` & `agency-prompt-engineer` AI量化工程师），在当前工作区分别创建独立的子项目工程目录（`okx-dog-product/`、`okx-dog-backend/`、`okx-dog-frontend/`、`okx-dog-ai/`），输出各角色详尽、生产级的架构设计技术文档、代码级接口与数据契约、产品细化规格及联调排期计划。

Working directory: /Users/wesson/OKX-dog
Integrity mode: development

## Requirements

### R1. 产品需求完善与业务状态机规格 (Product & System Architect)
由产品与系统架构师在 `okx-dog-product/` 目录下输出：
1. `PRD_REFINED.md`：详细的产品需求规格细化说明。涵盖用户全旅程交互设计、异常边界与断网重连处理、多级风控拦截与熔断状态机（状态转移 Mermaid 图）、三种人机协同模式（手动一键采纳、半自动提醒、小额全自动）的判定与流转规则、暗黑专业金融 UI 原型布局与信息层级定义。
2. `MILESTONES_AND_WBS.md`：详细的项目工作分解结构 (WBS)、里程碑阶段划分、前后端联调检查清单与开发排期表。

### R2. 后端核心网关与硬风控架构设计 (Backend Architect: agency-backend-architect)
由后端架构师结合 `agency-backend-architect` 规范，在 `okx-dog-backend/` 目录下输出：
1. `ARCHITECTURE.md`：基于 Python 3.10+ (FastAPI + Asyncio + Uvicorn) 的后端架构设计技术文档。包含系统分层架构图（Mermaid）、OKX v5 WebSocket/REST 异步长连接管理与频控退避机制、AES-256-GCM 凭证密盒密钥派生与本地隔离、多重硬风控拦截中枢（单笔限额/单日亏损熔断/杠杆硬锁/滑点保护）、Panic Button 紧急全平实现逻辑、SQLite + SQLAlchemy 架构与连接池管理。
2. `API_SPEC.md`：完整的 REST API 路由与 WebSocket 协议契约（包含全量请求/响应结构体、错误码字典、订阅主题与消息分发格式）。
3. `DATABASE_SCHEMA.sql`：包含凭证配置、持仓快照、委托订单、风控审计日志、AI研判归因等全量业务表的 SQLite DDL 定义与索引设计。
4. `models.py`：提供与 API / DB 对应的生产级 Python Pydantic 数据模型代码骨架。

### R3. 前端交易控制台架构设计与类型规范 (Frontend Architect: agency-senior-developer)
由前端资深开发与架构师结合 `agency-senior-developer` 规范，在 `okx-dog-frontend/` 目录下输出：
1. `ARCHITECTURE.md`：基于 React 18 + Vite + TypeScript + Zustand + TailwindCSS + Lightweight Charts 的前端架构设计技术文档。包含组件树与分层架构、暗黑专业交易主题设计系统（Design Tokens）、WebSocket/SSE 实时数据流消费与 Zustand 切片管理、Lightweight Charts K线图与持仓均价/止盈止损/AI支撑阻力叠加渲染机制、虚拟滚动与高频订单簿 60 FPS 性能优化策略。
2. `TYPES_CONTRACT.ts`：完整的 TypeScript 类型声明文件，与后端 REST API、WebSocket 推送及 AI 响应格式严格对齐。
3. `ROUTING_AND_LAYOUT.md`：控制台网格化布局设计、多设备/全屏交互规范、错误边界 (Error Boundary) 与全局告警交互方案。

### R4. 量化指标引擎与大模型决策中枢设计 (AI & Prompt Engineer: agency-ai-engineer & agency-prompt-engineer)
由 AI 与量化算法工程师结合 `agency-ai-engineer` 与 `agency-prompt-engineer` 规范，在 `okx-dog-ai/` 目录下输出：
1. `ARCHITECTURE.md`：量化指标计算引擎与 OpenAI 规范大模型适配架构文档。包含多周期（15m/1h/4h/1d）技术指标（EMA/MACD/RSI/布林带/ATR/成交量）与衍生品指标（资金费率/持仓量OI）实时计算流水线、结构化 Prompt 组装算法与上下文动态裁剪、OpenAI 标准接口兼容桥接（支持 BaseURL/Key/Model 自由切换）、Structured Outputs (JSON Schema) 强制校验、思维链 (`<think>` 标签) 与 SSE 流式解析、历史研判与盈亏比胜率归因模型。
2. `PROMPT_TEMPLATES.md`：生产级 System Prompt 与行情上下文组装模板规范。
3. `AI_SCHEMA.json`：AI 结构化研判输出的严格 JSON Schema 契约定义。

### R5. 系统级端到端时序与联调部署架构 (System Integration & DevOps)
输出系统级跨模块端到端时序图与联调部署指南（包含安全密盒鉴权、行情分发、AI研判生成、硬风控拦截及紧急一键平仓完整链路 Mermaid 序列图），以及单机私有化部署、环境依赖与联调验证说明。

## Acceptance Criteria

### 目录与代码文件结构完整性
- [ ] 根目录下正确创建 `okx-dog-product/`、`okx-dog-backend/`、`okx-dog-frontend/`、`okx-dog-ai/` 四个独立子项目目录
- [ ] 各子项目均包含结构完整、具备生产可落地方案的 `ARCHITECTURE.md` 或设计说明文档

### 协议与代码级契约完备性
- [ ] 后端输出完整可直接执行的 `DATABASE_SCHEMA.sql`、`API_SPEC.md` 与 `models.py`
- [ ] 前端输出与后端完全对齐的 `TYPES_CONTRACT.ts` 契约定义
- [ ] AI 模块输出严格的 `AI_SCHEMA.json` 与标准 Prompt 模板

### 架构设计深度与风控保障
- [ ] 包含至少 4 组以上高质量 Mermaid 图（系统整体架构图、风控状态机转移图、AI 研判与一键下单时序图、紧急熔断流程图）
- [ ] 硬风控拦截中枢与本地 AES-256 密盒安全隔离有详尽的技术实现方案与异常兜底策略
- [ ] 包含详细的开发排期、WBS 任务拆解与前后端联调测试步骤

## 2026-08-14T17:47:08Z

根据当前工程根目录下的 `PRD.md`、`AGENTS.md` 规范及 Milestone 1 落地成果，调用团队中各领域的专业角色 Skill（`agency-backend-architect` 后端架构师、`agency-senior-developer` 前端资深架构师、`agency-ai-engineer` & `agency-prompt-engineer` AI量化工程师），全面推进并落地各子项目的核心业务代码：

Working directory: /Users/wesson/OKX-dog
Integrity mode: development

## Requirements

### R1. 后端 OKX v5 异步长连接池与硬风控拦截中枢 (Backend: okx-dog-backend)
由后端架构师结合 `agency-backend-architect` 规范，在 `okx-dog-backend/` 目录下完成：
1. `okx_ws.py`：实现 OKX v5 WebSocket 异步长连接管理类（公有行情通道与私有账户通道），支持 20s 心跳保活（ping/pong）与指数退避自动重连自愈机制（1s, 2s, 4s, 8s, 16s, 30s）。
2. `okx_rest.py`：实现 OKX v5 REST 客户端，支持毫秒级 HMAC-SHA256 签名计算、令牌桶限频控制与 429 自动退避。
3. `risk_controller.py`：实现不可绕过的硬风控拦截中枢（单笔下单限额、单日已实现+浮动亏损熔断、最大杠杆限制、滑点保护）与 Panic Button 紧急撤单全平（Cancel-Before-Close）。
4. 更新 `main.py` 注册 WebSocket 广播端点（`/ws/v5/stream`）与交易/风控/行情 API 路由。

### R2. 量化指标引擎与大模型决策流水线 (AI: okx-dog-ai)
由 AI 与量化算法工程师结合 `agency-ai-engineer` 与 `agency-prompt-engineer` 规范，在 `okx-dog-ai/` 目录下完成：
1. `indicator_engine.py`：基于 $O(1)$ 递推计算 15m/1h/4h/1d 多周期技术指标（EMA 20/50/200, MACD 12/26/9, RSI 14, Bollinger Bands 20/2, ATR 14）及资金费率、OI。
2. `prompt_builder.py`：实现行情结构化上下文组装器，支持 P0~P3 优先级 Token 预算动态裁剪。
3. `llm_client.py`：实现兼容 OpenAI 协议的多模型适配器（支持 DeepSeek-R1 / GPT-4o），提供 30s 超时降级与重试机制。
4. `parser.py`：实现 `RobustJSONParser` 5 层容错自愈解析，支持 SSE `<think>` 思维链提取与 Structured Outputs 严格校验。

### R3. 前端暗黑交易终端图表与高频数据渲染 (Frontend: okx-dog-frontend)
由前端资深开发与架构师结合 `agency-senior-developer` 规范，在 `okx-dog-frontend/` 目录下完成：
1. `src/components/TradingChart.tsx`：集成 TradingView Lightweight Charts，支持 15m/1h/4h/1d 多周期 K 线切换，支持在图表上实时叠加持仓均价线、止盈止损线与 AI 支撑/阻力线。
2. `src/components/OrderBook.tsx` & `src/components/TradeList.tsx`：基于 requestAnimationFrame 缓冲分发与虚拟滚动，实现 60 FPS 流畅度的 Level-2 订单簿（买卖各20档）与实时成交流水。
3. `src/components/AICopilotCard.tsx`：实现 AI 智能研判卡片展示、`<think>` 思维链折叠打字机流式渲染与“一键采纳下单”交互弹窗。
4. `src/components/OrderForm.tsx` & `src/components/PositionList.tsx`：专业交易下单面板（现货/永续、市价/限价、快捷仓位比例、附带 TP/SL）与活跃持仓管理列表。

## Acceptance Criteria

### 代码完整性与生产就绪
- [ ] 所有新创建或扩展的 Python / TypeScript 代码均为生产级可用代码，杜绝 `TODO`、`FIXME` 或占位空函数
- [ ] 后端通过真实的异步 WebSocket 心跳保活与硬风控拦截逻辑
- [ ] 前端图表具备完整的 TradingView 手感、暗黑金融质感与 60 FPS 渲染能力
- [ ] AI 模块能正常根据多周期指标组装 Prompt 并返回符合 `AI_SCHEMA.json` 契约的标准化结构化决策
