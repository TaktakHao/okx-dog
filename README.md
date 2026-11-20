# OKX-Dog 个人量化交易与投研系统

OKX-Dog 是一套面向个人交易者的加密衍生品量化投研、高精度影子盘与 7x24h 自动执行系统，围绕 **OKX v5 REST/WebSocket 协议**、**三位一体策略同构底座（回测 / 影子盘 / 实盘共享同一套代码）** 与 **不可绕过的金融级硬风控中枢** 构建。

---

## 核心架构与能力

### 1. 交易执行与安全底座
- **零裸仓发单与安全改损**：开仓附带止损（`attachAlgoOrds`）校验失败时直接拒单，严禁降级提交无止损裸单；实盘移动止损/保本采用 **先挂新止损并校验 `algoId` 回执 → 再撤旧条件单** 协议，消除裸仓真空期。
- **外部手动持仓物理隔离**：默认关闭开机自动切实盘（`AUTO_BOOT_LIVE_MODE=False`）与外部仓位静默接管（`AUTO_TAKEOVER_EXTERNAL_POSITIONS=False`）；60 秒常驻对账中枢以 OKX 交易所为唯一事实源（SSOT），遇到外部手动持仓仅告警隔离，不自动干预。
- **金融级硬风控中枢**：单笔金额上限、杠杆上限、单日亏损硬熔断（默认 `300 USDT / 3%`，SQLite 持久化且按 UTC 00:00 自动重置，手动解除强制校验 `MASTER_PASSWORD`）、全局权益回撤停机底线（默认 `82%`，即最大回撤 `18%` 自动停机）与两阶段 Panic Button 紧急全撤全平。
- **凭证安全隔离**：API Key / Secret / Passphrase 经 AES-256-GCM 本地密盒加密存储，全程脱敏，物理阻断提现/转账权限。
- **Smart Pegging 被动做市执行**：优先以 `POST_ONLY` 贴盘买一/卖一档挂单，显著压降手续费与滑点摩擦。

### 2. 双引擎量化组合、数据湖与样本外验证
- **60/30/10 双引擎资金隔离**：主引擎 B（`60%`，拆分为 `30%` 4H 凯尔特纳通道突破 + `30%` 1D 双均线吊灯止损，覆盖 Top 5 对称多空）+ 底座引擎 A（`30%` Delta 中性期现资金费率套利，低费率熊市自动休眠切 USDT 活期，支持 `SEMI_AUTO` Telegram 确认与 `FULL_AUTO` 切换）+ `10%` USDT 安全缓冲。
- **本地多维时序数据湖**：支持从 OKX 实盘公共历史接口批量同步 Top 5 核心标的（`BTC` / `ETH` / `SOL` / `BNB` / `DOGE`）永续与现货多年历史 K 线及真实 8h 资金费率，落盘 SQLite / DuckDB。
- **同构策略基类（`BaseStrategy`）**：回测、冻结参数影子盘与实盘共用同一套策略代码与内部指标计算，支持 K 线收盘门控与宽幅 ATR 吊灯移动止损，杜绝双轨制逻辑漂移。
- **高保真事件驱动回测与 Walk-Forward 门禁**：Next-Bar 开盘撮合（零前瞻偏差）、真实 8h 资金费率结算、日频年化夏普（`sqrt(365)`）、滚动样本外 Walk-Forward 检验，以及 Top-3 剔除衰减、手续费/毛利红线、40 bps 滑点压测与 ±20% 参数平原稳定性校验。
- **高精度实盘公共行情影子盘**：模拟盘公共行情与资金费率流直连 OKX 实盘公共接口，全口径扣除双边手续费、市价滑点与 8h 资金费，如实按真实跳空价撮合止损，确保现金流变动与单笔净盈亏严格对齐。

### 3. AI 离线投研与暗黑交易终端
- **AI 离线复盘与防守定位**：线上默认冻结自动调参（`EVOLUTION_AUTO_MUTATE_ENABLED=False`），防止样本内过拟合；LLM 聚焦于离线策略研发、每日归因复盘与低频黑天鹅事件防守告警。
- **暗黑交易与监控终端（React 18 + Lightweight Charts）**：集成多周期 K 线图表、全景多维收益曲线、资金流雷达、全量真实标的检索（`Ctrl+P`）、运维健康胶囊与 Telegram 移动端强告警。

---

## 工程模块结构

| 模块 | 目录 | 技术栈 | 核心职责 |
| :--- | :--- | :--- | :--- |
| **前端终端** | `okx-dog-frontend` | React 18 + Vite 5 + TypeScript + Lightweight Charts + Tailwind | 暗黑交易终端、K 线与收益曲线可视化、标的管理与风控交互 |
| **后端服务** | `okx-dog-backend` | FastAPI + OKX v5 REST/WS + SQLite (WAL) + 异步协程 | 7x24h 操盘引擎、硬风控拦截层、对账中枢、数据湖与同构回测引擎 |
| **AI 与投研** | `okx-dog-ai` | Antigravity CLI / OpenAI 协议 + 参数平原校验器 | Token 压缩、离线反思复盘、结构化契约解析与抗过拟合生死线检验 |
| **契约事实源** | `contracts` | JSON Schema / OpenAPI / AsyncAPI | 前后端与 AI 共享的唯一权威接口、模型与风控契约 |
| **脚本工具** | `scripts` | Python 3 | 契约防漂移门禁校验、3 年数据湖同步与 Walk-Forward 一键投研 |
| **产品文档** | `okx-dog-product` | Markdown | PRD 需求规范、架构文档与 WBS 任务分解 |

---

## 快速启动与常用命令

### 1. 初始化与启动服务

```bash
# 初始化运行环境
bash bootstrap.sh

# 方式 A：单机前后台一键启动 (FastAPI 8000 + React 3000)
bash start.sh

# 方式 B：后台守护集群管理 (含状态巡检与平滑启停)
./company.sh start
./company.sh status
./company.sh stop
```

> 启动后访问暗黑操盘终端：`http://localhost:3000`

### 2. 数据湖同步与 Walk-Forward 样本外验证

```bash
# 同步 Top 5 核心标的近 3 年真实 4H/1D 永续+现货 K 线与资金费率，并执行 Walk-Forward 门禁校验
.agents/auditor_r2/venv/bin/python3 scripts/run_stage1_research.py --sync --wf

# 仅基于本地数据湖重跑 Walk-Forward 校验
.agents/auditor_r2/venv/bin/python3 scripts/run_stage1_research.py --wf
```

### 3. 契约门禁与工程校验

```bash
# 全栈契约严格一致性检查
python3 scripts/verify_contracts.py --strict

# 前端生产构建与类型校验
cd okx-dog-frontend && npm run build
```
