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
```bash
bash start.sh
```
> 系统将自动拉起后端 FastAPI (8000端口) 与前端 React (3000端口)，并在浏览器中自动打开控制台！

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
