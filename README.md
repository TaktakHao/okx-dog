# OKX-Dog 个人量化智能交易系统 (AI Trading Co-pilot)

OKX-Dog 是一款为高频合约量化交易员量身打造的个人智能交易副驾驶系统。系统集成了多周期技术指标共振、DeepSeek 思维链推理研判、毫秒级 OKX 官方 WebSocket 行情推流、5 维度硬风控熔断中枢与全真模拟撮合沙盒。

## 🏛️ 项目工程架构与独立仓库索引

本项目采用微服务化架构拆分，各模块均托管在独立的 GitHub 私有仓库中：

| 模块名称 | 仓库地址 | 技术栈 | 职责说明 |
| :--- | :--- | :--- | :--- |
| **前端终端** | [`okx-dog-frontend`](https://github.com/TaktakHao/okx-dog-frontend) | React 18 + Vite 5 + TypeScript + Lightweight Charts + Tailwind | 极客暗黑金融交易终端、多周期图表与 AI 决策卡片 |
| **后端服务** | [`okx-dog-backend`](https://github.com/TaktakHao/okx-dog-backend) | FastAPI + OKX v5 WebSocket/REST + SQLite (WAL) | 高并发交易中枢、5重硬风控拦截层与模拟撮合引擎 |
| **AI 研判** | [`okx-dog-ai`](https://github.com/TaktakHao/okx-dog-ai) | OpenAI 兼容接口 + CoT 思维链流式提取 + 指标引擎 | 多周期指标计算、结构化决策契约与量化自愈 |
| **产品文档** | [`okx-dog-product`](https://github.com/TaktakHao/okx-dog-product) | Markdown 规范与状态机图解 | PRD 需求文档、系统架构设计、WBS 任务分解与用户手册 |

---

## 🚀 新电脑快速拉取与一键启动（3 步极速上手）

在任何全新的电脑上（Mac / Linux / Windows WSL），只需 3 步即可完整运行整个系统：

### 第 1 步：克隆主工程
```bash
git clone https://github.com/TaktakHao/okx-dog.git
cd okx-dog
```

### 第 2 步：一键拉取所有子模块与配置环境
```bash
bash bootstrap.sh
```
> `bootstrap.sh` 脚本将自动为您：
> 1. 并发克隆所有 4 个子仓库（前端、后端、AI、产品）。
> 2. 自动创建 Python 虚拟环境并一键安装所有 pip 依赖。
> 3. 自动安装前端 npm 依赖。

### 第 3 步：一键启动系统
```bash
bash start.sh
```
> 系统将自动启动后端 FastAPI (8000端口) 与前端 React (3000端口)，并在浏览器中自动打开控制台！

---

## 🔄 日常运维与代码更新

- **一键更新所有子模块最新代码**：
  ```bash
  bash update_all.sh
  ```
