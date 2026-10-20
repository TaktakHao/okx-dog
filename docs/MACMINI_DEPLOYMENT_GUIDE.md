# OKX-Dog v6.0 家用 Mac mini 7x24h 原生常驻与 Hermes 多角色部署实战指南

> 适用硬件：Mac mini (Apple Silicon M1 / M2 / M4，8GB / 16GB / 24GB 统一内存)  
> 运行理念：低功耗静音常驻、宿主机原生高保真 CLI、Hermes Agent 多角色消息网关（零 Docker、零外部数据库依赖）、Tailscale 外网安全穿透

---

## 1. 为什么采用“Hermes 宿主机原生”拓扑？

| 方案 | 内存占用 | CLI 调用与响应 | 移动端交互体验 | 推荐指数 |
| :--- | :--- | :--- | :--- | :--- |
| **Hermes 原生常驻 (v6.0 默认推荐)** | **~350MB - 500MB** | **毫秒级 (Native)** | **微信 / QQ / Telegram 消息直达** | ⭐⭐⭐⭐⭐ |
| 原 Paperclip 原生进程方案 | ~600MB - 800MB | 毫秒级 | 需打开内网 Web 网页查看 | ⭐⭐⭐ (已废弃) |
| 全容器化 Docker 方案 | ~1.5GB - 2.5GB | 容器桥接，易鉴权失效 | 需额外做容器端口映射与代理 | ⭐⭐ (已废弃) |

* **交易执行内核**：运行 `OKX-Dog Backend` (FastAPI 端口 8000) 与 `AI 决策网关` (端口 8001)。享受原生 Python 极速行情与 5 重不可绕过硬风控拦截；
* **Hermes 运营层**：运行 `hermes-agent`，自带统一通讯网关（Gateway 端口 8088）与多角色设定。手机发消息即下达指令，08:00 定时推送战绩日报，突发风险秒级振动报警；
* **前端操盘大屏**：运行 Vite React 金融暗黑操盘大屏（端口 3000），供电脑大屏看盘。

---

## 2. 准备工作：Python 环境与 Hermes CLI

1. **Python 环境**：确保 Python 3.9+ 已就绪。
2. **安装 Hermes Agent CLI**（可选，开箱即用）：
   ```bash
   curl -fsSL https://hermes-agent.nousresearch.com/install.sh | bash
   source ~/.zshrc
   ```

---

## 3. 一键启动、一键关闭与全息巡检

项目深度集成了统一的运维中枢脚本 `company.sh`（以及对应的独立快捷脚本 `start_company_macmini.sh` 和 `stop_company_macmini.sh`）。

### 3.1 一键全面启动并就绪 (One-Click Start)

在终端只需执行一行命令：

```bash
./company.sh start
# 或者: ./start_company_macmini.sh
```

**底层执行的全自动流水线**：
1. **环境与多角色自检**：自动执行 `python3 scripts/setup_hermes.py`，校验 6 大员工 Persona（陈守拙、张大炮、周铁山、林望远、赵小刀、钱公道）与 `okxdog_ops` 技能包；
2. **拉起 AI 大脑**：在宿主机后台启动 AI 决策网关与 CFO 战绩激励引擎（端口 `8001`）；
3. **拉起交易核心**：在宿主机后台启动 7x24h 毫秒级交易与 5 重不可绕过硬风控底座（端口 `8000`）；
4. **拉起操盘大屏**：在宿主机后台启动金融暗黑交易大屏（端口 `3000`）；
5. **拉起 Hermes 网关**：启动 Hermes Gateway（端口 `8088`），打通移动即时通讯通道。

启动完成后：
* **暗黑操盘大屏 (投资人工作台)**: `http://localhost:3000`
* **交易核心与硬风控 Swagger Docs**: `http://localhost:8000/docs`
* **AI 网关与多角色 API**: `http://localhost:8001/api/v1/hermes/org`

---

### 3.2 一键安全平滑关闭 (One-Click Graceful Stop)

当你需要维护系统或重启硬件时，只需执行：

```bash
./company.sh stop
# 或者: ./stop_company_macmini.sh
```

**关闭动作将自动执行**：
1. 平滑停止前端 React/Vite 服务（释放端口 `3000`）；
2. 优雅停止后端交易中枢，确保无挂单与内存状态泄漏（释放端口 `8000`）；
3. 停止 AI 决策网关与 CFO 审计进程（释放端口 `8001`）；
4. 优雅停止 Hermes Gateway（释放端口 `8088`）；
5. 彻底回收 PID 存证与清理端口占用，实现 0 残留退出。

---

### 3.3 运行状态全息巡检与日志追踪

```bash
# 全息巡检系统状态、端口连通性、6 大员工角色与 CFO 战绩奖金池
./company.sh status

# 实时追踪运行日志
./company.sh logs          # 查看后端与AI综合最近日志
./company.sh logs ai       # 实时追踪 AI 决策网关日志
./company.sh logs backend  # 实时追踪 后端交易与风控日志
./company.sh logs frontend # 实时追踪 前端大屏日志
./company.sh logs hermes   # 实时追踪 Hermes 通讯网关日志

# 平滑重启
./company.sh restart
```

---

## 4. 远程随时随地安全访问：Tailscale 零配置穿透

在上班路上、公司或度假时，通过手机随时查看家里的量化系统与战绩：

1. **Mac mini 安装 Tailscale**：
   ```bash
   brew install --cask tailscale
   ```
2. **手机端下载 Tailscale App**，登录同一账号；
3. **安全连接**：
   - Tailscale 会为你的 Mac mini 分配一个安全私网 IP（例如 `100.88.99.12`）；
   - 在手机浏览器中输入 `http://100.88.99.12:3000`（查看 OKX-Dog 实时持仓与资产曲线）；
   - 配合 Telegram/微信 Bot，**无需打开浏览器即可收到每日战绩与风控通知**！
   - **全程端到端加密，无需公网 IP，不开放任何公网危险端口**！

---

## 5. 7x24h 防断电与系统自愈配置

1. **设置断电自动重启**：
   - 打开 macOS `系统设置 -> 节能`；
   - 勾选 **「断电后自动重新启动」**。
2. **全套服务开机自启**：
   - 可将 `start_company_macmini.sh` 注册到用户登录项，开机即可自动全盘拉起。
