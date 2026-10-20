# OKX-Dog 个人量化智能交易系统 (AI Trading Co-pilot & 7x24h Auto-Pilot)

OKX-Dog 是一款为高频合约与 TradFi 衍生品量化交易员量身打造的个人智能交易副驾驶与 7x24h 脱机全自动操盘系统。系统深度集成了多周期技术指标共振、DeepSeek / Antigravity CLI 思维链推理、OKX 官方 WebSocket 毫秒级推流、5 维度硬风控拦截中枢、动态移动保本机制与全真模拟沙盒。

---

## 🌟 核心特性与架构亮点

1. **7x24h 后端脱机常驻自主操盘 (Independent Daemon Engine)**：
   - 彻底摆脱浏览器依赖！后端常驻守护协程全天候 15 秒自主轮巡多标的池、执行时段过滤、量化决策推导与自动开平仓。
2. **TradFi 多标的监控池与组合敞口控制 (Multi-Symbol Pool & Portfolio Limit)**：
   - 全面支持 TradFi 传统金融资产（黄金 `XAU`、白银 `XAG`、美股代币 `NVDA`/`TSLA`/`AAPL`、外汇 `EUR`/`GBP`、RWA 美债 `ONDO`/`PENDLE`）与主流加密资产（`BTC`/`ETH`）。
   - 组合级最大并发持仓上限控制 (`max_concurrent_positions`)，传统金融美股周末休市智能过滤。
3. **动态移动保本与跟踪止损 (Dynamic Breakeven & Trailing Stop)**：
   - 持仓浮盈达到目标位（$\ge 0.8\%$）自动无损上移止损线至开仓保本价（Breakeven Locked），杜绝盈利单变亏损。
4. **AI Prompt Token 高保真压缩中枢 (45%~60% Token Reduction)**：
   - 高信息密度 Master System Prompt 与行式紧凑序列化，自适应数值截断去噪，在保留 100% 量化指标的前提下显著压降 Token 开销。
5. **不可绕过的金融级硬风控拦截中枢 (Hard Risk Lock & Panic Button)**：
   - 单笔限额、单日亏损熔断、杠杆上限、滑点保护与 Panic Button 紧急两阶段全撤全平。
6. **人机协同清晰的前端双卡片终端 (React 18 + Lightweight Charts)**：
   - **AutoPilot 看板**：7x24h 脱机运行状态、多标的池管理、移动保本指示、最近巡检日志流与时序收益曲线。
   - **AICopilot 副驾驶**：交易员主观多周期深度研判、打字机思维链与一键采纳下单。
7. **v3.5 AI Quant Studio & Codex Harness 智能体沙箱操作系统**：
   - **AI 自主量化策略研发**：自然语言秒级生成无未来函数的高性能 Python 向量化代码。
   - **AST 静态安全白名单审查**：100% 阻断 `os/sys/socket/eval/exec` 等危险指令与系统外联。
   - **受限独立沙箱极速回测**：5 秒超时熔断看门狗，10,000 根 K 线回测耗时 $< 3$ 秒。
   - **3 轮报错自愈纠错闭环**：代码运行时异常自动捕获 Traceback 并反哺大模型自愈重写。
   - **模型升级防退化评测底座**：500+ 极端行情黄金基准数据集一键压测。
8. **v4.1 多智能体强化奖励自进化与通俗「AI 员工看板」**：
   - **复合强化奖励分解**：平仓后自动结合实现盈亏比 ($S_{rr}$)、MFE/MAE 精度与排雷避险贡献度打分。
   - **Softmax 动态加权门控**：带 $[8\%, 35\%]$ 上下限约束的动态话语权分配，避免单一角色垄断。
   - **极简通俗 AI 员工团队看板**：拟人化 6 大量化员工角色（张大炮·多头、周铁山·风控、林望远·宏观、链上巨鲸侦察员、赵小刀·盘口、陈守拙·仲裁），零金融门槛一目了然看懂话语权与战绩，并支持 Harness 防退化黄金基准守护与一键安全回滚。
9. **v5.0 企业级量化基础设施与高保真执行中枢 (Enterprise Grade Quant Architecture)**：
   - **自动化实时对账中枢 (Reconciliation)**：以 OKX 远端交易所为唯一真实事实源 (SSOT)，60 秒自动纠偏自愈外部成交与状态漂移，杜绝“幽灵持仓”；
   - **Smart Pegging 盘口动态做市**：买一/卖一档贴盘 `POST_ONLY` 挂单，自适应价差漂移与智能追单看门狗，提升成交率并节省 60%+ 交易成本；
   - **ATR 波动率自适应固定风险头寸模型**：单笔交易风险额度严格锁定在总资金的 1.0%，剧烈行情自动惩罚收缩仓位敞口；
   - **高保真事件驱动回测引擎**：UTC 00/08/16 跨越真实资金费率结算、Next-Bar 开盘撮合成交（彻底杜绝 Look-ahead 前瞻未来函数）；
   - **“三位一体”策略基类统一**：`BaseStrategy` 打通投研、回测与实盘 100% 同构复用；
   - **DuckDB 列式时序数据湖**：支持 Parquet 高速列式落盘、毫秒检索、OKX 真实历史资金费率与全网持仓量 (OI) 深度集成；
   - **全景运维监控看板**：前端集成 WS/API 延迟指示、Maker 成交比例、对账状态三胶囊与暗黑运维诊断弹窗。
10. **v5.5 融合顶级开源量化数理与决策硬核升级 (Advanced Quant Math & Anti-Overfitting)**：
    - **DCA 动态强平线穿透预判与前置硬拦截 (`dca_liquidation_calculator.py`)**：汲取实盘检验痛点经验，在每一档补仓挂单前前瞻递推计算持仓强平价与补仓挂单价的交汇击穿风险，若挂单价触达或击穿强平线则前置一票否决，彻底阻断“加仓单未触达便在途中提前爆仓”的未决暴毙现象；
    - **极端逆势 30% 承压隔离保证金精算**：模拟标的发生 30% 极端单边单边行情下的穿仓承压风险，精确推导所需隔离保证金厚度；
    - **两状态递归卡尔曼滤波协整配对与动态对冲 (`kalman_pair_engine.py`)**：实时动态追踪跨币种配对（如 BTC/ETH）的动态协整斜率 $\beta_t$ 与截距 $\alpha_t$，自适应价差 Z-Score 偏离触发均值回归套利与协方差发散自愈熔断；
    - **实盘抗过拟合“生死线”过滤与“参数平原”稳定性评估 (`strategy_plateau_validator.py`)**：Top-3 偶然暴利剔除保留率 $\ge 50\%$、手续费/毛利比 $< 40\%$、双边 40bps 强滑点抗压测试、核心参数 $\pm 20\%$ 扰动平原收益保留率 $\ge 70\%$，彻底淘汰刀锋式过拟合孤岛；
    - **端到端契约与金融终端一体化协同**：权威契约 SSOT 零漂移，前端 AutoPilot 卡片集成动态强平安全缓冲指示与卡尔曼协整雷达。
11. **v6.0 基于 Hermes Agent 的 AI 虚拟对冲基金多角色治理与 Mac mini 原生常驻部署 (Hermes Multi-Persona & Native Ops)**：
    - **移动即时通讯消息网关直连 (Hermes Gateway)**：全面接入 Nous Research 开源的 `hermes-agent`，原生支持 Telegram、Discord、Slack 以及微信/QQ（Claw/Webhook）双向消息互通，随时在手机聊天中查战绩、派工单、收警报；
    - **6 大虚拟量化员工多角色设定 (Multi-Persona)**：陈守拙（CEO / 首席投决仲裁）、周铁山（空头 / 铁血风控审计）、钱公道（CFO / 战绩审计总监）、张大炮（多头趋势研究员）、赵小刀（盘口微观结构与执行）、林望远（宏观与资讯分析师），各司其职，恪守权限边界；
    - **7x24h 自动化量化运营闭环 (Built-in Cron)**：周铁山 5 分钟风控巡检与熔断报警（盯盘）、钱公道每日 08:00 自动生成战绩卡片推送到手机（复盘）、陈守拙周度提炼避坑规则（学习）、张大炮周日夜间网格回测调优（调参）；
    - **聊天端参数变更提案-确认闭环 (`ChangeProposal` & `ConfigVersion`)**：员工改参必须发起提案并附回测收益证据；手机聊天中回复“确认”方可原子生效并留存快照版本，支持一键安全回滚；
    - **员工专用安全运维工具 (`scripts/okxdog_ops_cli.py`)**：内置白名单与权限鉴权，硬风控物理阻断任何下单、撤单、平仓及密盒越权操作；
    - **极轻量原生常驻**：无需 Docker，无需外部数据库，单个 Python/uv 原生进程托管，整机常驻内存仅约 350-500MB，Mac mini 长期运行机身温凉，支持 Tailscale 零配置外网加密穿透。

---

## 🏛️ 项目工程架构与独立仓库索引

本项目采用模块化微服务架构拆分：

| 模块名称 | 目录路径 | 技术栈 | 职责说明 |
| :--- | :--- | :--- | :--- |
| **前端终端** | `okx-dog-frontend` | React 18 + Vite 5 + TypeScript + Lightweight Charts + Tailwind | 暗黑金融交易终端、多周期图表、标的检索器(`Ctrl+P`)与双卡片操盘看板 |
| **后端服务** | `okx-dog-backend` | FastAPI + OKX v5 WebSocket/REST + SQLite (WAL) + 异步协程 | 7x24h 常驻巡检引擎、5重硬风控拦截层、AES-256凭证密盒与模拟撮合沙盒 |
| **AI 研判** | `okx-dog-ai` | Hermes Multi-Persona + Antigravity CLI (agy) + Token 压缩中枢 | 多周期指标计算、多角色共识对抗网络、CoT 思维链流式提取与结构化契约 |
| **产品文档** | `okx-dog-product` | Markdown 规范与状态机图解 | PRD 需求文档、系统架构设计、WBS 任务分解与用户手册 |

---

## 🚀 快速启动与运行指南

### 第 1 步：克隆主工程
```bash
git clone https://github.com/TaktakHao/okx-dog.git
cd okx-dog
```

### 第 2 步：一键初始化环境
```bash
bash bootstrap.sh
```

### 第 3 步：一键启动系统

* **模式 A：v6.0 虚拟量化公司全功能集群 (推荐，含 Hermes 6 大员工与通讯网关)**
  ```bash
  # 一键全面启动并就绪 Hermes 多角色体系
  ./company.sh start

  # 一键平滑彻底关闭所有服务 (前端+后端+AI+Hermes)
  ./company.sh stop

  # 全息巡检系统运行状态与 CFO 战绩奖金池
  ./company.sh status
  ```
  > 启动后访问：暗黑操盘大屏 `http://localhost:3000` ｜ 后端接口文档 `http://localhost:8000/docs` ｜ 多角色架构 `http://localhost:8001/api/v1/hermes/org`
  >
  > 详见 [`docs/MACMINI_DEPLOYMENT_GUIDE.md`](docs/MACMINI_DEPLOYMENT_GUIDE.md) 与 [`docs/HERMES_SETUP.md`](docs/HERMES_SETUP.md)。

* **模式 B：本地极简单机前台运行 (快速调试)**
  ```bash
  bash start.sh
  ```
  > 系统将拉起后端 FastAPI (8000端口) 与前端 React (3000端口)，按 Ctrl+C 退出。

---

## 🔄 日常运维与代码更新

- **一键更新所有子模块最新代码**：
  ```bash
  bash update_all.sh
  ```
- **核心测试验证**：
  ```bash
  # 后端全量测试 (含 7x24h 巡检、移动保本与 Token 压缩)
  cd okx-dog-backend && pytest test_backend_core.py -o asyncio_mode=auto
  # 前端生产构建编译
  cd okx-dog-frontend && npm run build
  ```
