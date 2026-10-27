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
6. **全自动量化操盘与全景交互式多维收益终端 (React 18 + Lightweight Charts)**：
   - **AutoPilot 看板**：7x24h 脱机运行状态、多标的池管理、移动保本指示与自动平仓战绩流。
   - **EquityCurvePanel 全景多维时序收益面板**：基于 `lightweight-charts` Canvas 引擎，支持鼠标左键拖拽平移、滚轮无级缩放、全屏沉浸放大，同屏叠加展示**总净盈亏**、**已实现盈亏**、**持仓浮动盈亏**、**账户总权益 + 历史最高净值水线 (High-Water Mark)** 与**累计收益率 (%)**，并在曲线上实时打点标记历次自动平仓战绩。
7. **v3.5 AI Quant Studio & Codex Harness 智能体沙箱操作系统**：
   - **AI 自主量化策略研发**：自然语言秒级生成无未来函数的高性能 Python 向量化代码。
   - **AST 静态安全白名单审查**：100% 阻断 `os/sys/socket/eval/exec` 等危险指令与系统外联。
   - **受限独立沙箱极速回测**：5 秒超时熔断看门狗，10,000 根 K 线回测耗时 $< 3$ 秒。
   - **3 轮报错自愈纠错闭环**：代码运行时异常自动捕获 Traceback 并反哺大模型自愈重写。
   - **模型升级防退化评测底座**：500+ 极端行情黄金基准数据集一键压测。
8. **v4.1 多智能体强化奖励自进化与通俗「AI 员工看板」**：
   - **复合强化奖励分解**：平仓后自动结合实现盈亏比 ($S_{rr}$)、MFE/MAE 精度与排雷避险贡献度打分。
   - **Softmax 动态加权门控**：带 $[8\%, 35\%]$ 上下限约束的动态话语权分配，避免单一角色垄断。
   - **极简通俗 AI 员工团队看板**：拟人化 6 大量化员工角色（冲锋多头、铁血风控、全球情报、链上巨鲸、盘口狙击、量化仲裁），零金融门槛一目了然看懂话语权与战绩，并支持 Harness 防退化黄金基准守护与一键安全回滚。
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
11. **v6.0 基于 Paperclip 的 AI 虚拟对冲基金治理与 Mac mini 混合轻量常驻部署 (Paperclip Orchestration & Mac mini Hybrid)**：
    - **本地 CLI 套餐包月机制驱动**：依托系统原生 Antigravity CLI (agy)，享受免单日零钱扣费的确定性算力，日常由 0 Token Python 哨兵前哨巡检，仅在形态共振时调用 CLI；
    - **长期主义与战绩分红奖励机制 (Performance-Based Bonus Quota)**：建立 7 天滚动收益考核，实盘平仓盈利自动向立功员工派发算力与深度思考奖励 Tokens（每 +10 USDT 奖励 10,000 Tokens），空头专家成功排雷避险亦可获嘉奖；
    - **特权解锁与动态话语权赋能**：高战绩额度员工自动解锁 DeepSeek-R1 等 `<think>` 深度思考长链模式，并在投决会中享有更高的加权投票权；
    - **Mac mini 宿主原生 + 极轻容器混合运行架构**：OKX-Dog FastAPI 与本地 agy 跑在 macOS 宿主机，Paperclip 与 Postgres 跑在轻量 Docker 容器（OrbStack），整机常驻内存仅约 650MB，CPU 长期均值 < 3%，机身温凉，支持 Tailscale 外网加密穿透。
12. **v6.1 实盘交易全链路穿透修复与正数学期望值量化引擎重构 (Live Execution & Positive-Expectancy Quant Upgrade)**：
    - **OKX v5 统一账户可用保证金精准解析 (`okx_rest.py`)**：彻底解决统一账户返回空字符串 `""` 导致 `availMgn` 回退失效、实盘可用保证金被误判为 `0.0 USDT` 的问题，全面兼容单币种/跨币种/组合保证金模式；
    - **753 个真实合约规格精度对齐与小数张数支持 (`okx_rest.py`, `instrument_service.py`)**：对接 `okx_instruments_cache.json` 全量真实 `ctVal`、`lotSz`、`minSz`、`tickSz`，支持 `0.01` 张小数合约精度与小资金实盘建仓，消除合约张数与基础币数量换算偏差；
    - **实盘与模拟沙盒风控物理隔离 (`risk_controller.py`, `routers/paper.py`)**：切换实盘/模拟环境时自动隔离单日累计盈亏与回撤计数器，支持手动/AI 市价单滑点保护与回撤降级杠杆自适应收敛，消除模拟盘磨损锁死实盘下单的问题；
    - **多周期共振与 ATR 吊灯分批止盈正期望值模型 (`services/ai_service.py`, `auto_pilot.py`)**：引入 1h EMA20/50 纠缠度震荡过滤与 10 分钟反手保护期，持久化阶段 1 减半止盈状态 (`tp_stage1_done`)，采用 $2.0 \times \text{ATR}$ / $3.4 \times \text{ATR}$ 分批止盈与 $1.5 \times \text{ATR}$ 宽幅吊灯移动止损，将净盈亏比提升至 $1.6:1 \sim 2.0:1$。

---


## 🏛️ 项目工程架构与独立仓库索引

本项目采用模块化微服务架构拆分：

| 模块名称 | 目录路径 | 技术栈 | 职责说明 |
| :--- | :--- | :--- | :--- |
| **前端终端** | `okx-dog-frontend` | React 18 + Vite 5 + TypeScript + Lightweight Charts + Tailwind | 暗黑金融交易终端、多周期图表、标的检索器(`Ctrl+P`)与双卡片操盘看板 |
| **后端服务** | `okx-dog-backend` | FastAPI + OKX v5 WebSocket/REST + SQLite (WAL) + 异步协程 | 7x24h 常驻巡检引擎、5重硬风控拦截层、AES-256凭证密盒与模拟撮合沙盒 |
| **AI 研判** | `okx-dog-ai` | Antigravity CLI (agy) + OpenAI 兼容协议 + Token 压缩中枢 | 多周期指标计算、高密度 Prompt 组装、CoT 思维链流式提取与结构化契约 |
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

* **模式 A：v6.0 虚拟量化公司全功能集群 (推荐，含 Paperclip 6大员工与自动接入)**
  ```bash
  # 一键全面启动并自动接入 Paperclip
  ./company.sh start

  # 一键平滑彻底关闭所有服务 (前端+后端+AI+Docker)
  ./company.sh stop

  # 全息巡检系统运行状态与 CFO 战绩奖金池
  ./company.sh status
  ```
  > 启动后访问：暗黑操盘大屏 `http://localhost:3000` ｜ Paperclip 看板 `http://localhost:3100`

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
