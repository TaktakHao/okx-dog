# OKX-Dog v6.0 家用 Mac mini 7x24h 混合部署与常驻运维实战指南

> 适用硬件：Mac mini (Apple Silicon M1 / M2 / M4，8GB / 16GB / 24GB 统一内存)  
> 运行理念：低功耗静音常驻、宿主机原生高保真 CLI、容器隔离控制中枢、Tailscale 外网安全穿透

---

## 1. 为什么采用“宿主机 + 轻量容器”混合拓扑？

| 方案 | 内存占用 | CLI 调用复杂度 | 网络延迟 | 推荐指数 |
| :--- | :--- | :--- | :--- | :--- |
| **混合架构 (推荐)** | **~600MB - 800MB** | **原生极速调用 (直接调用系统 `agy`)** | **毫秒级 (Native)** | ⭐⭐⭐⭐⭐ |
| 全容器化 (全部打包) | ~1.5GB - 2.5GB | 需将 CLI 密钥挂载进容器，易鉴权失效 | 有 Docker 网络桥接损耗 | ⭐⭐⭐ |
| 全宿主机 (纯手动) | ~500MB | 原生调用 | 毫秒级 | 维护繁琐 (需本地配 Postgres) | ⭐⭐⭐ |

* **宿主机原生层**：运行 `OKX-Dog Backend` (FastAPI) 与 `Antigravity CLI (agy)`。享受原生 Python 与系统的进程调用速度，无需处理复杂的容器内证书与终端凭证挂载。
* **轻量容器层**：运行 `Paperclip` 与 `PostgreSQL 17`。享受容器带来的数据库沙盒隔离与 Web 控制台开箱即用体验。

---

## 2. 准备工作：容器环境安装 (强烈推荐 OrbStack)

在 macOS 上，传统的 Docker Desktop 往往占用 2GB~4GB 内存且发热明显。  
**强烈推荐使用专为 macOS 原生打造的 [OrbStack](https://orbstack.dev/)**：

1. **一键安装 OrbStack**：
   ```bash
   brew install --cask orbstack
   ```
2. **启动 OrbStack**：
   - 打开 OrbStack 应用，在菜单栏常驻；
   - 它的空载内存占用不到 100MB，并且原生支持 `docker` 和 `docker compose` 命令行，完全无缝兼容。

---

## 3. 一键启动、一键关闭与全自动接入 Paperclip

项目已深度集成统一的运维中枢脚本 `company.sh`（以及对应的独立快捷脚本 `start_company_macmini.sh` 和 `stop_company_macmini.sh`）。

### 3.1 一键全面启动并自动接入 (One-Click Start & Auto-Bootstrap)

在终端只需执行一行命令：

```bash
./company.sh start
# 或者: ./start_company_macmini.sh
```

**底层执行的全自动流水线**：
1. **环境探检**：自动验证本地 Python 3.9+、Node.js 与 `agy` (Antigravity CLI) 包月环境；
2. **拉起 Paperclip**：自动通过 Docker/OrbStack 后台启动 Paperclip 组织中枢与 PostgreSQL 17 容器（端口 `3100`）；
3. **拉起 AI 大脑**：在宿主机启动 AI 决策网关与 CFO 战绩激励引擎（端口 `8001`）；
4. **拉起交易核心**：在宿主机启动 7x24h 毫秒级交易与 5 重不可绕过硬风控底座（端口 `8000`）；
5. **拉起操盘大屏**：在宿主机后台启动金融暗黑交易大屏（端口 `3000`）；
6. **🤖 全自动接入 Paperclip (Auto Bootstrap)**：
   - 自动执行 `python3 scripts/bootstrap_paperclip_company.py`；
   - 自动将 `contracts/paperclip/company_org_contract.json` 契约中的 **6 大 AI 虚拟员工**（诸葛仲裁、冲锋多头、铁血风控、全球眼、盘口狙击、公道伯）登记入册；
   - 自动绑定每个岗位的核心 KPI、话语权权重与回调 Webhook（`http://host.docker.internal:8001/api/v1/paperclip/task/anomaly`）；
   - 生成本地注册凭据 `.paperclip_bootstrapped.json`，**用户完全无需手动在网页上逐一配置智能体，开箱即用！**

启动完成后，即可打开浏览器直接访问：
* **暗黑操盘大屏 (投资人工作台)**: `http://localhost:3000`
* **Paperclip 虚拟公司组织与任务看板**: `http://localhost:3100`
* **AI 网关与 CFO 战绩配额 API**: `http://localhost:8001/api/v1/paperclip/org`
* **交易核心与硬风控 Swagger Docs**: `http://localhost:8000/docs`

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
4. 暂停 Paperclip 与 PostgreSQL 容器集群；
5. 彻底回收 PID 存证与清理端口占用，实现 0 残留退出。

---

### 3.3 运行状态全息巡检与日志追踪

```bash
# 全息巡检系统状态、端口连通性与 CFO 战绩奖金池概况
./company.sh status

# 实时追踪运行日志
./company.sh logs          # 查看后端与AI综合最近日志
./company.sh logs ai       # 实时追踪 AI 决策网关日志
./company.sh logs backend  # 实时追踪 后端交易与风控日志
./company.sh logs frontend # 实时追踪 前端大屏日志
./company.sh logs docker   # 实时追踪 Paperclip 容器日志

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
   - 在手机浏览器中直接输入：
     * `http://100.88.99.12:3100`（查看 Paperclip 6 大员工与工单）
     * `http://100.88.99.12:3000`（查看 OKX-Dog 实时持仓与资产曲线）
   - **全程端到端加密，无需公网 IP，不开放任何公网危险端口**！

---

## 5. 7x24h 防断电与系统自愈配置

1. **设置断电自动重启**：
   - 打开 macOS `系统设置 -> 节能`；
   - 勾选 **「断电后自动重新启动」**。
2. **容器与后端保活**：
   - `docker-compose.paperclip.yml` 中已配置 `restart: always`，系统开机后容器将自动拉起；
   - 如需让宿主机 Python 脚本也在开机时全自动拉起，可将 `start_company_macmini.sh` 注册到用户登录项，或使用系统原生 `launchd` plist 守护。

---

## 6. 运维与资源监控

在终端中输入：
```bash
top -o mem
```
你将看到：
* `okx-dog-backend`: ~180MB
* `okx-dog-ai`: ~120MB
* `orbstack (包含 paperclip + postgres)`: ~350MB
* **整机总常驻内存仅 ~650MB，CPU 长期占用 < 3%，机身温凉，运行平稳！**
