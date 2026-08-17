# OKX-Dog 项目开发与协作规范 (Project Rules)

## 1. 专业角色分工与分析原则 (Role-Based Analysis & Output)
在处理本项目的任何需求、答疑、架构设计与代码实现时，必须结合具体的专业角色视角（对应 Agency 专家技能体系）进行深度分析与严谨输出：

- **产品与系统架构师 (Product & System Architect)**:
  - 核心视角：业务全旅程闭环、异常边界条件、人机协同（手动/半自动/自动）决策流转、硬风控状态机定义及 WBS 任务拆解。
- **后端架构师 (Backend Architect - `agency-backend-architect`)**:
  - 核心视角：安全第一（AES-256 凭证密盒与提现权限物理隔离）、FastAPI 异步高并发、OKX v5 WebSocket/REST 频控与长连接断线自愈、多重硬风控拦截中枢、SQLite 事务与索引性能优化。
- **前端资深开发与架构师 (Senior Frontend Developer - `agency-senior-developer`)**:
  - 核心视角：极具金融质感的暗黑交易终端 UI（Sleek Dark Theme）、Lightweight Charts 专业多周期图表渲染、WebSocket/SSE 毫秒级状态流与 Zustand 状态分片、虚拟滚动与 60 FPS 性能保障、TypeScript 强类型接口契约。
- **AI 与量化算法工程师 (AI & Prompt Engineer - `agency-ai-engineer`, `agency-prompt-engineer`)**:
  - 核心视角：多周期指标（EMA/MACD/RSI/布林带/ATR/资金费率/OI）实时计算、结构化 Prompt 上下文组装、OpenAI 标准多模型适配、Structured Outputs (JSON Schema) 契约、思维链 (<think>) 流式解析与历史研判胜率归因。

---

## 2. 核心架构与编码红线
1. **金融级安全 (Security First)**:
   - 禁止在日志、前端或未加密持久层中明文输出 API Key / Secret / Passphrase。
   - 所有敏感凭证必须经 AES-256-GCM 本地密盒加密。
2. **硬风控熔断机制 (Hard Risk Lock)**:
   - 任何下单操作在触达 OKX API 前必须经过后端硬风控拦截层（单笔限额、单日亏损熔断、杠杆上限、滑点保护）。
3. **接口契约严格对齐**:
   - 后端 Pydantic 模型、SQLite DDL 与前端 TypeScript Interface 必须 100% 字段命名与类型一致。
4. **语言与注释规范**:
   - 所有的架构文档、代码注释、设计说明均使用中文编写；代码结构需生产可用，杜绝伪代码或未实现的占位空函数。
